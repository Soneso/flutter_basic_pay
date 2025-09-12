// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/payment_data_and_pin_form.dart';
import 'package:flutter_basic_pay/widgets/common/dialogs.dart';
import 'package:flutter_basic_pay/widgets/common/dropdowns.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';
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
  
  String _truncateMiddle(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final startLength = (maxLength - 3) ~/ 2;
    final endLength = maxLength - 3 - startLength;
    return '${text.substring(0, startLength)}...${text.substring(text.length - endLength)}';
  }

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
        // Title Section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.send,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Send Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        if (_state == SimplePaymentsPageState.sending)
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
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: LoadingWidget(
                    size: 48,
                    showCard: false,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sending Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Processing your transaction...',
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
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Secure transaction',
                        style: TextStyle(
                          color: Colors.blue.shade700,
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
                    Text(
                      'Asset to Send',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        await _handleContactSelected(item);
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
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
              if (_state != SimplePaymentsPageState.initial)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: PaymentDataAndPinForm(
                    onDataSet: (PaymentDataAndPin data) async {
                      await _handleAmountAndPinSet(data, dashboardState);
                    },
                    onCancel: _onPinCancel,
                    hintText: 'Enter pin to send the payment',
                    requestAmount: true,
                    maxAmount: _maxAmount(_selectedAsset),
                  ),
                ),
            ],
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
    var initialState = _state;
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

      // if the destination account does not exist on the testnet, let's fund it!
      // alternatively we can use the create account operation.
      var destinationExists =
          await StellarService.accountExists(destinationAddress);
      if (!destinationExists) {
        await StellarService.fundTestNetAccount(destinationAddress);
      }

      // find out if the recipient can receive the asset that
      // the user wants to send
      if (asset is wallet_sdk.IssuedAssetId) {
        var recipientAssets =
            await StellarService.loadAssetsForAddress(destinationAddress);
        if (!recipientAssets.any((item) => item.asset.id == asset.id)) {
          setState(() {
            _submitError = 'Recipient can not receive ${asset.id}';
            _state = initialState;
          });
          return;
        }
      }

      // send payment
      bool ok = await dashboardState.data.sendPayment(
          destinationAddress: destinationAddress,
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
        _state = initialState;
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
