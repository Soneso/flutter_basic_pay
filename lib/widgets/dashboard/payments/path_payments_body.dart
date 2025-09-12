// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/payment_data_and_pin_form.dart';
import 'package:flutter_basic_pay/widgets/common/dialogs.dart';
import 'package:flutter_basic_pay/widgets/common/dropdowns.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';
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
  String? _recipientAddress;
  PathData? _pathData;
  PathPaymentsBodyState _state = PathPaymentsBodyState.initial;
  String? _submitError;
  static const _otherContact = 'Other';
  List<ContactInfo> _contacts = List<ContactInfo>.empty(growable: true);
  List<AssetInfo> _destinationAssets = List<AssetInfo>.empty(growable: true);
  
  String _truncateMiddle(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final startLength = (maxLength - 3) ~/ 2;
    final endLength = maxLength - 3 - startLength;
    return '${text.substring(0, startLength)}...${text.substring(text.length - endLength)}';
  }

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
        // Title Section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.route,
                color: Colors.purple.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Path Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Send one asset and receive another',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        
        if (_state == PathPaymentsBodyState.sending)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: LoadingWidget(
                    size: 48,
                    showCard: false,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sending Path Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Converting and sending your assets...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.route,
                        size: 16,
                        color: Colors.purple.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Cross-asset transfer',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipient Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipient',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StringItemsDropdown(
                      title: "Select Contact",
                      items: contactsDropdownItems,
                      onItemSelected: (String item) async {
                        await _handleContactSelected(item, dashboardState);
                      },
                      initialSelectedItem: _selectedContact,
                    ),
                    if (_recipientAddress != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Tooltip(
                                message: _recipientAddress!,
                                child: Text(
                                  _truncateMiddle(_recipientAddress!, 20),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _copyToClipboard(_recipientAddress!),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: Colors.purple.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Loading Contact Assets
              if (_state == PathPaymentsBodyState.loadingContactAssets)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: CircularProgress(
                            size: 24,
                            strokeWidth: 2.5,
                            color: Colors.purple.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading Assets',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fetching recipient\'s available assets...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Path Payment Switcher
              if (_state == PathPaymentsBodyState.contactAssetsLoaded ||
                  _state == PathPaymentsBodyState.pathSelected)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  child: PathPaymentsSwitcher(
                    destinationAddress: _recipientAddress!,
                    destinationAssets: _destinationAssets,
                    onPathSelected: (pathData) => _handlePathSelected(pathData),
                    key: ObjectKey(_recipientAddress),
                  ),
                ),
              
              // Error Message
              if (_submitError != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 20,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submitError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Payment Form
              if (_state == PathPaymentsBodyState.pathSelected)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: PaymentDataAndPinForm(
                    onDataSet: (PaymentDataAndPin data) async {
                      await _handlePinSet(data, dashboardState);
                    },
                    onCancel: _onPinCancel,
                    hintText: 'Enter pin to send the payment',
                    requestAmount: false,
                  ),
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
      _recipientAddress = null;
      _state = PathPaymentsBodyState.initial;
    });
  }

  Future<void> _handleContactSelected(
      String item, DashboardState dashboardState) async {
    String? newSelectedContact = item;
    String? address;
    if (item == _otherContact) {
      address = await Dialogs.insertAddressDialog(
          NavigationService.navigatorKey.currentContext!);
      if (address == null) {
        newSelectedContact = null;
      }
    } else {
      var contact = _contacts.firstWhere((element) => element.name == item);
      address = contact.address;
    }

    if (address == null) {
      return;
    }

    setState(() {
      _submitError = null;
      _selectedContact = newSelectedContact;
      _state = PathPaymentsBodyState.loadingContactAssets;
      _recipientAddress = address;
    });

    var destinationAssets = await StellarService.loadAssetsForAddress(address);
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
      var userKeyPair = await dashboardState.authService.userKeyPair(data.pin);

      var pathData = _pathData!;
      final ok = pathData.type == PathPaymentType.strictSend
          ? await dashboardState.data.strictSendPayment(
              sendAssetId: pathData.path.sourceAsset,
              sendAmount: pathData.path.sourceAmount,
              destinationAddress: _recipientAddress!,
              destinationAssetId: pathData.path.destinationAsset,
              destinationMinAmount: pathData.path.destinationAmount,
              path: pathData.path.path,
              userKeyPair: userKeyPair)
          : await dashboardState.data.strictReceivePayment(
              sendAssetId: pathData.path.sourceAsset,
              sendMaxAmount: pathData.path.sourceAmount,
              destinationAddress: _recipientAddress!,
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
      if (e is InvalidPin) {
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
                // Payment Mode Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purple.shade100,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strictSend ? 'Strict Send Mode' : 'Strict Receive Mode',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                strictSend
                                    ? 'Specify exact amount to send'
                                    : 'Specify exact amount to receive',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: strictSend,
                            activeColor: Colors.purple.shade600,
                            onChanged: (value) {
                              setState(() {
                                strictSend = value;
                                _pathData = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                strictSend
                    ? PathPaymentSection(
                        type: PathPaymentType.strictSend,
                        destinationAddress: widget.destinationAddress,
                        destinationAssets: widget.destinationAssets,
                        onPathSelected: (pathData) =>
                            _handlePathSelected(pathData),
                        key: const Key('strict send'),
                      )
                    : PathPaymentSection(
                        type: PathPaymentType.strictReceive,
                        destinationAddress: widget.destinationAddress,
                        destinationAssets: widget.destinationAssets,
                        onPathSelected: (pathData) =>
                            _handlePathSelected(pathData),
                        key: const Key('strict receive'),
                      ),
              ],
            ),
          if (_pathData != null) getPathDataColumn(_pathData!),
        ]);
  }

  Column getPathDataColumn(PathData pathData) {
    final sourceAssetCode = pathData.path.sourceAsset.id == 'native' 
        ? 'XLM' 
        : (pathData.path.sourceAsset as wallet_sdk.IssuedAssetId).code;
    final destAssetCode = pathData.path.destinationAsset.id == 'native' 
        ? 'XLM' 
        : (pathData.path.destinationAsset as wallet_sdk.IssuedAssetId).code;
    
    final sourceAmount = Util.removeTrailingZerosFormAmount(pathData.path.sourceAmount);
    final destAmount = Util.removeTrailingZerosFormAmount(pathData.path.destinationAmount);
    
    final isSourceEstimated = pathData.type != PathPaymentType.strictSend;
    final isDestEstimated = pathData.type == PathPaymentType.strictSend;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade50,
                  Colors.green.shade100.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Path Found',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Send Amount
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        color: Colors.red.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You Send',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '$sourceAmount $sourceAssetCode',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isSourceEstimated)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'estimated',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Receive Amount
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: Colors.green.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recipient Receives',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '$destAmount $destAssetCode',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (isDestEstimated)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'estimated',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          // Asset Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.type == PathPaymentType.strictSend
                          ? Icons.upload
                          : Icons.download,
                      size: 18,
                      color: widget.type == PathPaymentType.strictSend
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.type == PathPaymentType.strictSend
                          ? 'Asset to Send'
                          : 'Asset to Receive',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StringItemsDropdown(
                  title: "Select Asset",
                  items: assetsDropdownItems,
                  onItemSelected: (String item) {
                    _handleAssetSelected(item);
                  },
                  initialSelectedItem: _selectedAsset,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_state == SectionState.initial) getAmountForm(dashboardState),
          if (_state == SectionState.searchingPaths)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purple.shade100,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            shape: BoxShape.circle,
                          ),
                        ),
                        CircularProgress(
                          size: 32,
                          strokeWidth: 3,
                          color: Colors.purple.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Finding Best Path',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Analyzing available routes...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ]);
  }

  Form getAmountForm(DashboardState dashboardState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: widget.type == PathPaymentType.strictSend
                    ? 'Amount to send (max: ${Util.removeTrailingZerosFormAmount(_maxAmount(_selectedAsset).toString())})'
                    : 'Amount to receive',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.all(16),
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
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
                    return 'Amount must be ${Util.removeTrailingZerosFormAmount(maxAmount.toString())} or less';
                  }
                }
                return null;
              },
              controller: amountTextController,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_errorText != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 20,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String amount = amountTextController.text;
                  await _handleFindPaymentPath(amount, dashboardState);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Find Payment Path',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
      paths = await StellarService.findStrictSendPaymentPath(
          sourceAsset: asset,
          sourceAmount: amount,
          destinationAddress: widget.destinationAddress);
    } else {
      paths = await StellarService.findStrictReceivePaymentPath(
          sourceAddress: dashboardState.data.userAddress,
          destinationAsset: asset,
          destinationAmount: amount);
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
