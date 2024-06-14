import 'package:auto_size_text/auto_size_text.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/api/api.dart';
import 'package:flutter_basic_pay/auth/auth.dart';
import 'package:flutter_basic_pay/storage/storage.dart';
import 'package:flutter_basic_pay/util/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/payment_data_and_pin_form.dart';
import 'package:flutter_basic_pay/widgets/common/dialogs.dart';
import 'package:flutter_basic_pay/widgets/common/dropdowns.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:provider/provider.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;

class PathPaymentsBodyContent extends StatefulWidget {
  const PathPaymentsBodyContent({
    super.key,
  });

  @override
  State<PathPaymentsBodyContent> createState() =>
      _PathPaymentsBodyContentState();
}

enum PathPaymentsBodyState {
  initial,
  contactSelected,
  otherContactSelected,
  loadingContactAssets,
  contactNotValid,
  contactAssetsLoaded,
  pathSelected,
  sending
}

class _PathPaymentsBodyContentState extends State<PathPaymentsBodyContent> {
  String? _selectedContact;
  String? _recipientAccountId;
  PathData? _pathData;
  PathPaymentsBodyState _state = PathPaymentsBodyState.initial;
  String? _submitError;
  static const _otherContact = 'Other';
  List<ContactInfo> _contacts = List<ContactInfo>.empty(growable: true);
  List<AssetInfo> _destinationAssets = List<AssetInfo>.empty(growable: true);

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    _contacts = dashboardState.data.contacts;
    List<String> contactsDropdownItems =
        _contacts.map((contact) => contact.name).toList().reversed.toList();
    contactsDropdownItems.add(_otherContact);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_state != PathPaymentsBodyState.sending)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send path payment',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              AutoSizeText(
                "Recipient:",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 10),
              StringItemsDropdown(
                title: "Select Contact",
                items: contactsDropdownItems,
                onItemSelected: (String item) async {
                  await _handleContactSelected(item, dashboardState);
                },
                initialSelectedItem: _selectedContact,
              ),
              const SizedBox(height: 10),
              if (_recipientAccountId != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: AutoSizeText(
                          _recipientAccountId!,
                          style: Theme.of(context)
                              .textTheme
                              .apply(bodyColor: Colors.blue)
                              .bodyMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy_outlined,
                          size: 20,
                        ),
                        onPressed: () => _copyToClipboard(_recipientAccountId!),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              if (_state == PathPaymentsBodyState.loadingContactAssets)
                getLoadingColumn('loading contact assets ...'),
              if (_state == PathPaymentsBodyState.contactAssetsLoaded ||
                  _state == PathPaymentsBodyState.pathSelected)
                PathPaymentsSwitcher(
                    destinationAddress: _recipientAccountId!,
                    destinationAssets: _destinationAssets,
                    onPathSelected: (pathData) => _handlePathSelected(pathData),
                    key: ObjectKey(_recipientAccountId)),
              if (_submitError != null)
                AutoSizeText(
                  _submitError!,
                  style: Theme.of(context)
                      .textTheme
                      .apply(bodyColor: Colors.red)
                      .bodyMedium,
                ),
              if (_state == PathPaymentsBodyState.pathSelected)
                Column(
                  children: [
                    PaymentDataAndPinForm(
                      onDataSet: (PaymentDataAndPin data) async {
                        await _handlePinSet(data, dashboardState);
                      },
                      onCancel: _onPinCancel,
                      hintText: 'Enter pin to send the payment',
                      requestAmount: false,
                    ),
                  ],
                ),
            ],
          ),
        if (_state == PathPaymentsBodyState.sending)
          getLoadingColumn('sending payment ...'),
        const Divider(
          color: Colors.blue,
        ),
      ],
    );
  }

  Column getLoadingColumn(String text) {
    return Column(
      key: ObjectKey(text),
      children: [
        const Divider(
          color: Colors.blue,
        ),
        Row(
          children: [
            const SizedBox(
              height: 10.0,
              width: 10.0,
              child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  void _handlePathSelected(PathData pathData) {
    setState(() {
      _pathData = pathData;
      _state = PathPaymentsBodyState.pathSelected;
    });
  }

  void _resetState() {
    setState(() {
      _submitError = null;
      _selectedContact = null;
      _recipientAccountId = null;
      _state = PathPaymentsBodyState.initial;
    });
  }

  Future<void> _handleContactSelected(
      String item, DashboardState dashboardState) async {
    String? newSelectedContact = item;
    String? accountId;
    if (item == _otherContact) {
      accountId = await Dialogs.insertAccountIdDialog(
          NavigationService.navigatorKey.currentContext!);
      if (accountId == null) {
        newSelectedContact = null;
      }
    } else {
      var contact = _contacts.firstWhere((element) => element.name == item);
      accountId = contact.accountId;
    }

    if (accountId == null) {
      return;
    }

    setState(() {
      _submitError = null;
      _selectedContact = newSelectedContact;
      _state = PathPaymentsBodyState.loadingContactAssets;
      _recipientAccountId = accountId;
    });

    var destinationAssets =
        await dashboardState.data.loadAssetsForAddress(accountId);
    if (destinationAssets.isEmpty) {
      setState(() {
        _submitError =
            'The recipient account was not found on the Stellar Network. It needs to be funded first.';
        _state = PathPaymentsBodyState.contactNotValid;
      });
    } else {
      setState(() {
        _submitError = null;
        _destinationAssets = destinationAssets;
        _state = PathPaymentsBodyState.contactAssetsLoaded;
      });
    }
  }

  Future<void> _handlePinSet(
      PaymentDataAndPin data, DashboardState dashboardState) async {
    var nextState = _state;
    setState(() {
      _submitError = null;
      _state = PathPaymentsBodyState.sending;
    });
    try {
      // load secret seed and check if pin is valid.
      var userKeyPair = await dashboardState.auth.userKeyPair(data.pin);

      var pathData = _pathData!;
      final ok = pathData.type == PathPaymentType.strictSend
          ? await dashboardState.data.strictSendPayment(
              sendAssetId: pathData.path.sourceAsset,
              sendAmount: pathData.path.sourceAmount,
              destinationAddress: _recipientAccountId!,
              destinationAssetId: pathData.path.destinationAsset,
              destinationMinAmount: pathData.path.destinationAmount,
              path: pathData.path.path,
              userKeyPair: userKeyPair)
          : await dashboardState.data.strictReceivePayment(
              sendAssetId: pathData.path.sourceAsset,
              sendMaxAmount: pathData.path.sourceAmount,
              destinationAddress: _recipientAccountId!,
              destinationAssetId: pathData.path.destinationAsset,
              destinationAmount: pathData.path.destinationAmount,
              path: pathData.path.path,
              userKeyPair: userKeyPair);

      if (ok) {
        ScaffoldMessenger.of(NavigationService.navigatorKey.currentContext!)
            .showSnackBar(
          const SnackBar(
            content: Text('Payment sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      var errorText = "error: could not send payment";
      if (e is RetrieveSeedException) {
        errorText = "error: invalid pin";
      }
      setState(() {
        _submitError = errorText;
        _state = nextState;
      });
    }
  }

  void _onPinCancel() {
    _resetState();
  }

  void _copyToClipboard(String text) async {
    await FlutterClipboard.copy(text);
    _showCopied();
  }

  void _showCopied() {
    ScaffoldMessenger.of(NavigationService.navigatorKey.currentContext!)
        .showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class PathPaymentsSwitcher extends StatefulWidget {
  final String destinationAddress;
  final List<AssetInfo> destinationAssets;
  final ValueChanged<PathData> onPathSelected;

  const PathPaymentsSwitcher({
    required this.destinationAddress,
    required this.destinationAssets,
    required this.onPathSelected,
    super.key,
  });

  @override
  State<PathPaymentsSwitcher> createState() => _PathPaymentsSwitcherState();
}

class _PathPaymentsSwitcherState extends State<PathPaymentsSwitcher> {
  bool strictSend = true;
  PathData? _pathData;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_pathData == null)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Strict send"),
                    Switch(
                      value: strictSend,
                      onChanged: (value) {
                        setState(() {
                          strictSend = value;
                          _pathData = null;
                        });
                      },
                    )
                  ],
                ),
                const SizedBox(height: 10),
                strictSend
                    ? PathPaymentSection(
                        type: PathPaymentType.strictSend,
                        destinationAddress: widget.destinationAddress,
                        destinationAssets: widget.destinationAssets,
                        onPathSelected: (pathData) =>
                            _handlePathSelected(pathData),
                      )
                    : PathPaymentSection(
                        type: PathPaymentType.strictReceive,
                        destinationAddress: widget.destinationAddress,
                        destinationAssets: widget.destinationAssets,
                        onPathSelected: (pathData) =>
                            _handlePathSelected(pathData),
                      ),
              ],
            ),
          if (_pathData != null) getPathDataColumn(_pathData!),
        ]);
  }

  Column getPathDataColumn(PathData pathData) {
    var text =
        'You send ${Util.removeTrailingZerosFormAmount(pathData.path.sourceAmount)} ${pathData.path.sourceAsset.id == 'native' ? 'XLM' : (pathData.path.sourceAsset as wallet_sdk.IssuedAssetId).code} '
        '${pathData.type == PathPaymentType.strictSend ? '' : '(estimated)'} and the recipient receives '
        '${Util.removeTrailingZerosFormAmount(pathData.path.destinationAmount)} ${pathData.path.destinationAsset.id == 'native' ? 'XLM' : (pathData.path.destinationAsset as wallet_sdk.IssuedAssetId).code} '
        '${pathData.type == PathPaymentType.strictSend ? '(estimated)' : ''}.';

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          AutoSizeText(
            text,
            style: Theme.of(context)
                .textTheme
                .apply(bodyColor: Colors.green)
                .bodyMedium,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 10),
        ]);
  }

  void _handlePathSelected(PathData pathData) {
    setState(() {
      _pathData = pathData;
    });
    widget.onPathSelected(pathData);
  }
}

class PathPaymentSection extends StatefulWidget {
  final PathPaymentType type;
  final String destinationAddress;
  final List<AssetInfo> destinationAssets;
  final ValueChanged<PathData> onPathSelected;

  const PathPaymentSection({
    required this.type,
    required this.destinationAddress,
    required this.destinationAssets,
    required this.onPathSelected,
    super.key,
  });

  @override
  State<PathPaymentSection> createState() => _PathPaymentSectionState();
}

enum SectionState { initial, searchingPaths, pathSelection }

class _PathPaymentSectionState extends State<PathPaymentSection> {
  static const xlmAsset = 'XLM';
  static const native = 'native';
  String _selectedAsset = xlmAsset;
  List<AssetInfo> _assets = List<AssetInfo>.empty(growable: true);
  final amountTextController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();
  String? _errorText;
  SectionState _state = SectionState.initial;

  @override
  void dispose() {
    amountTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);

    if (widget.type == PathPaymentType.strictSend) {
      _assets = dashboardState.data.assets;
      // remove assets with amount == 0
      _assets.removeWhere((element) => double.parse(element.balance) == 0);
    } else {
      _assets = widget.destinationAssets;
    }

    // prepare assets to select from
    List<String> assetsDropdownItems =
        _assets.map((asset) => asset.asset.id).toList().reversed.toList();
    final index = assetsDropdownItems.indexWhere((asset) => asset == native);
    assetsDropdownItems[index] = xlmAsset;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AutoSizeText(
            widget.type == PathPaymentType.strictSend ? 'Send:' : 'Receive:',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 10),
          StringItemsDropdown(
            title: "Select Asset",
            items: assetsDropdownItems,
            onItemSelected: (String item) {
              _handleAssetSelected(item);
            },
            initialSelectedItem: _selectedAsset,
          ),
          const SizedBox(height: 10),
          if (_state == SectionState.initial) getAmountForm(dashboardState),
          if (_state == SectionState.searchingPaths)
            getLoadingColumn('Searching best payment path')
        ]);
  }

  Form getAmountForm(DashboardState dashboardState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: widget.type == PathPaymentType.strictSend
                    ? 'Enter amount (max. ${Util.removeTrailingZerosFormAmount(_maxAmount(_selectedAsset).toString())})'
                    : 'Enter amount',
                hintStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)')),
              ],
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                double? amount = double.tryParse(value);
                if (amount == null) {
                  return 'Invalid amount';
                }
                if (widget.type == PathPaymentType.strictSend) {
                  var maxAmount = _maxAmount(_selectedAsset);
                  if (amount > maxAmount) {
                    return 'Amount must be lower or equal ${Util.removeTrailingZerosFormAmount(maxAmount.toString())}';
                  }
                }
                return null;
              },
              controller: amountTextController,
            ),
          ),
          if (_errorText != null)
            AutoSizeText(
              _errorText!,
              style: Theme.of(context)
                  .textTheme
                  .apply(bodyColor: Colors.red)
                  .bodyMedium,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String amount = amountTextController.text;
                  await _handleFindPaymentPath(amount, dashboardState);
                }
              },
              child: const Text(
                'Find payment path',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFindPaymentPath(
      String amount, DashboardState dashboardState) async {
    setState(() {
      _state = SectionState.searchingPaths;
    });

    var asset = _selectedAsset == xlmAsset
        ? wallet_sdk.NativeAssetId()
        : (_assets.firstWhere((a) => a.asset.id == _selectedAsset)).asset;

    var paths = List<wallet_sdk.PaymentPath>.empty(growable: true);
    if (widget.type == PathPaymentType.strictSend) {
      paths = await dashboardState.data.findStrictSendPaymentPath(
          sourceAsset: asset,
          sourceAmount: amount,
          destinationAddress: widget.destinationAddress);
    } else {
      paths = await dashboardState.data.findStrictReceivePaymentPath(
          destinationAsset: asset, destinationAmount: amount);
    }
    if (paths.isEmpty) {
      setState(() {
        _errorText = 'No payment path found for the given data';
        _state = SectionState.initial;
      });
    } else {
      setState(() {
        _errorText = null;
        _state = SectionState.initial;
      });

      // in a real app you would let the user select the path
      // for now, we just take the first.
      widget.onPathSelected(PathData(type: widget.type, path: paths.first));
    }
  }

  void _handleAssetSelected(String item) {
    setState(() {
      _selectedAsset = item;
      _errorText = null;
      _state = SectionState.initial;
    });
  }

  double _maxAmount(String assetId) {
    var isXlm = assetId == xlmAsset;
    var id = isXlm ? native : assetId;
    var found = _assets.where((element) => element.asset.id == id);
    if (found.isNotEmpty) {
      if (isXlm) {
        // leave at least 2 xml
        var max = double.parse(found.first.balance) - 2.0;
        if (max > 0) {
          return max;
        }
      } else {
        return double.parse(found.first.balance);
      }
    }
    return 0;
  }

  Column getLoadingColumn(String text) {
    return Column(
      key: ObjectKey(text),
      children: [
        const Divider(
          color: Colors.blue,
        ),
        Row(
          children: [
            const SizedBox(
              height: 10.0,
              width: 10.0,
              child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}

enum PathPaymentType {
  strictSend,
  strictReceive,
}

class PathData {
  PathPaymentType type;
  wallet_sdk.PaymentPath path;

  PathData({required this.type, required this.path});
}
