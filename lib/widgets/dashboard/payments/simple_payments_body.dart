// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/data.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/payment_data_and_pin_form.dart';
import 'package:flutter_basic_pay/widgets/common/dialogs.dart';
import 'package:flutter_basic_pay/widgets/common/dropdowns.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:provider/provider.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;

class SimplePaymentsPageBodyContent extends StatefulWidget {
  const SimplePaymentsPageBodyContent({
    super.key,
  });

  @override
  State<SimplePaymentsPageBodyContent> createState() =>
      _SimplePaymentsBodyContentState();
}

enum SimplePaymentsPageState {
  initial,
  contactSelected,
  otherContactSelected,
  sending
}

class _SimplePaymentsBodyContentState
    extends State<SimplePaymentsPageBodyContent> {
  static const xlmAsset = 'XLM';
  static const native = 'native';
  String _selectedAsset = xlmAsset;
  String? _selectedContact;
  String? _recipientAddress;
  SimplePaymentsPageState _state = SimplePaymentsPageState.initial;
  String? _submitError;
  static const otherContact = 'Other';
  List<ContactInfo> contacts = List<ContactInfo>.empty(growable: true);
  List<AssetInfo> assets = List<AssetInfo>.empty(growable: true);

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    contacts = dashboardState.data.contacts;
    assets = dashboardState.data.assets;

    // remove assets with amount == 0
    assets.removeWhere((element) => double.parse(element.balance) == 0);

    // prepare assets to select from
    List<String> assetsDropdownItems =
        assets.map((asset) => asset.asset.id).toList().reversed.toList();
    final index = assetsDropdownItems.indexWhere((asset) => asset == native);
    assetsDropdownItems[index] = xlmAsset;

    List<String> contactsDropdownItems =
        contacts.map((contact) => contact.name).toList().reversed.toList();
    contactsDropdownItems.add(otherContact);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Send payment',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (_state != SimplePaymentsPageState.sending)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(
                "Asset to send:",
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
                  await _handleContactSelected(item);
                },
                initialSelectedItem: _selectedContact,
              ),
              if (_recipientAddress != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: AutoSizeText(
                          _recipientAddress!,
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
                        onPressed: () => _copyToClipboard(_recipientAddress!),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              if (_submitError != null)
                Text(
                  _submitError!,
                  style: Theme.of(context)
                      .textTheme
                      .apply(bodyColor: Colors.red)
                      .bodyMedium,
                ),
              if (_state != SimplePaymentsPageState.initial)
                PaymentDataAndPinForm(
                  onDataSet: (PaymentDataAndPin data) async {
                    await _handleAmountAndPinSet(data, dashboardState);
                  },
                  onCancel: _onPinCancel,
                  hintText: 'Enter pin to send the payment',
                  requestAmount: true,
                  maxAmount: _maxAmount(_selectedAsset),
                ),
            ],
          ),
        if (_state == SimplePaymentsPageState.sending)
          Column(
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
                    'sending payment ...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        const Divider(
          color: Colors.blue,
        ),
      ],
    );
  }

  double _maxAmount(String assetId) {
    var isXlm = assetId == xlmAsset;
    var id = isXlm ? native : assetId;
    var found = assets.where((element) => element.asset.id == id);
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

  void _handleAssetSelected(String item) {
    _resetState(item);
  }

  void _resetState(String selectedAsset) {
    setState(() {
      _submitError = null;
      _selectedContact = null;
      _recipientAddress = null;
      _state = SimplePaymentsPageState.initial;
      _selectedAsset = selectedAsset;
    });
  }

  Future<void> _handleContactSelected(String item) async {
    var newState = SimplePaymentsPageState.contactSelected;
    String? newSelectedContact = item;
    String? address;
    if (item == otherContact) {
      newState = SimplePaymentsPageState.otherContactSelected;
      address = await Dialogs.insertAddressDialog(
          NavigationService.navigatorKey.currentContext!);
      if (address == null) {
        newState = SimplePaymentsPageState.initial;
        newSelectedContact = null;
      }
    } else {
      var contact = contacts.firstWhere((element) => element.name == item);
      address = contact.address;
    }

    setState(() {
      _submitError = null;
      _selectedContact = newSelectedContact;
      _state = newState;
      _recipientAddress = address;
    });
  }

  Future<void> _handleAmountAndPinSet(
      PaymentDataAndPin data, DashboardState dashboardState) async {
    var nextState = _state;
    setState(() {
      _submitError = null;
      _state = SimplePaymentsPageState.sending;
    });
    try {
      // load secret seed and check if pin is valid.
      var userKeyPair = await dashboardState.authService.userKeyPair(data.pin);

      // compose the asset
      var asset = _selectedAsset == xlmAsset
          ? wallet_sdk.NativeAssetId()
          : (assets.firstWhere((a) => a.asset.id == _selectedAsset)).asset;

      var destinationAddress = _recipientAddress!;

      // if the destination account dose not exist on the testnet, let's fund it!
      // alternatively we can use the create account operation.
      var destinationExists =
          await StellarService.accountExists(destinationAddress);
      if (!destinationExists) {
        await StellarService.fundTestNetAccount(destinationAddress);
      }

      // send payment
      bool ok = await dashboardState.data.sendPayment(
          destinationAddress: _recipientAddress!,
          assetId: asset,
          amount: data.amount!,
          memo: data.memo,
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
    _resetState(xlmAsset);
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
