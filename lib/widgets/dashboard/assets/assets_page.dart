// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/dialogs.dart';
import 'package:flutter_basic_pay/widgets/common/dropdowns.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/assets/asset_balance_card.dart';
import 'package:flutter_basic_pay/widgets/common/pin_form.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:provider/provider.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;

class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    return FutureBuilder<List<AssetInfo>>(
      future: dashboardState.data.loadAssets(),
      builder: (context, futureSnapshot) {
        if (!futureSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return StreamBuilder<List<AssetInfo>>(
          initialData: futureSnapshot.data,
          stream: dashboardState.data.subscribeForAssetsInfo(),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return AssetsPageBody(
              key: ObjectKey(snapshot.data!),
            );
          },
        );
      },
    );
  }
}

class AssetsPageBody extends StatefulWidget {
  const AssetsPageBody({
    super.key,
  });

  @override
  State<AssetsPageBody> createState() => _AssetsPageBodyState();
}

class _AssetsPageBodyState extends State<AssetsPageBody> {
  bool waitForAccountFunding = false;
  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // Compact modern header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asset Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Manage your Stellar assets',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: dashboardState.data.assets.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      elevation: 8,
                      shadowColor: Colors.blue.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade600,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Account Not Funded',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your account needs to be funded on the Stellar Test Network to manage assets.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: waitForAccountFunding
                                    ? null
                                    : () async {
                                        setState(() {
                                          waitForAccountFunding = true;
                                        });
                                        await dashboardState.data.fundUserAccount();
                                        setState(() {
                                          waitForAccountFunding = false;
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: waitForAccountFunding
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Fund on Testnet',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const AssetsPageBodyContent(),
          ),
        ],
      ),
    );
  }
}

class AssetsPageBodyContent extends StatefulWidget {
  const AssetsPageBodyContent({super.key});

  @override
  State<AssetsPageBodyContent> createState() => _AssetsPageBodyContentState();
}

enum AssetsPageState { initial, assetSelected, customAssetSelected, sending }

class _AssetsPageBodyContentState extends State<AssetsPageBodyContent> {
  String? _selectedAsset;
  static const addCustomAsset = 'Add custom asset';
  AssetsPageState _state = AssetsPageState.initial;
  String? _submitError;
  wallet_sdk.IssuedAssetId? _customAsset;

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    // prepare assets to select from
    List<String> dropdownItems = StellarService.testAnchorAssets
        .map((asset) => asset.id)
        .toList(growable: true);

    // check if any of the assets are already trusted and if so, remove
    List<String> trustedAssets =
        dashboardState.data.assets.map((asset) => asset.asset.id).toList();
    dropdownItems.removeWhere((element) => trustedAssets.contains(element));

    // add custom item
    dropdownItems.add(addCustomAsset);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Add Asset Card
            Card(
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.add_circle_outline,
                            color: Colors.green.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Add Trusted Asset',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add a trustline to hold new assets in your account',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_state != AssetsPageState.sending)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StringItemsDropdown(
                            title: "Select Asset",
                            items: dropdownItems,
                            onItemSelected: (String item) async {
                              await _handleAssetSelected(item);
                            },
                            initialSelectedItem: _selectedAsset,
                          ),
                          const SizedBox(height: 12),
                          if (_submitError != null)
                            Container(
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
                                    color: Colors.red.shade600,
                                    size: 20,
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
                          if (_customAsset != null) ...[  
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _customAsset!.id,
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_state != AssetsPageState.initial) ...[  
                            const SizedBox(height: 16),
                            PinForm(
                              onPinSet: (String pin) async {
                                await _handlePinSet(pin, dashboardState);
                              },
                              onCancel: _onPinCancel,
                              hintText: 'Enter PIN to add asset',
                            ),
                          ],
                        ],
                      ),
                    if (_state == AssetsPageState.sending)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Adding asset...',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Existing Balances Card
            Card(
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Your Assets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'View balances and manage trustlines',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (dashboardState.data.assets.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No assets yet',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: dashboardState.data.assets.map(
                          (asset) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AssetBalanceCard(
                              asset,
                              dashboardState.authService.userKeyPair,
                              dashboardState.data.removeAssetSupport,
                              key: ObjectKey(asset),
                            ),
                          ),
                        ).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAssetSelected(String item) async {
    var newState = AssetsPageState.assetSelected;
    wallet_sdk.IssuedAssetId? customAsset;
    String? newSelectedAsset = item;
    if (item == addCustomAsset) {
      newState = AssetsPageState.customAssetSelected;
      customAsset = await Dialogs.customAssetDialog(
          NavigationService.navigatorKey.currentContext!);
      if (customAsset == null) {
        newState = AssetsPageState.initial;
        newSelectedAsset = null;
      }
    }

    setState(() {
      _submitError = null;
      _selectedAsset = newSelectedAsset;
      _state = newState;
      _customAsset = customAsset;
    });
  }

  Future<void> _handlePinSet(String pin, DashboardState dashboardState) async {
    var nextState = _state;
    setState(() {
      _submitError = null;
      _state = AssetsPageState.sending;
    });
    try {
      // compose the asset
      wallet_sdk.IssuedAssetId? asset;
      if (_selectedAsset == addCustomAsset && _customAsset != null) {
        asset = _customAsset;
      } else {
        asset = StellarService.testAnchorAssets
            .firstWhere((item) => item.id == _selectedAsset);
      }

      if (asset != null) {
        // check if the issuer account id exists on the stellar network
        var issuerExists = await StellarService.accountExists(asset.issuer);
        if (!issuerExists) {
          throw IssuerNotFound();
        }

        // load secret seed and check if pin is valid.
        var userKeyPair = await dashboardState.authService.userKeyPair(pin);

        // add trustline
        var added =
            await dashboardState.data.addAssetSupport(asset, userKeyPair);
        if (!added) {
          throw AssetNotAdded();
        }
      } else {
        throw InvalidAsset();
      }
    } catch (e) {
      var errorText = "error: could not add asset";
      if (e is InvalidPin) {
        errorText = "error: invalid pin";
      } else if (e is InvalidAsset) {
        errorText = "error: invalid asset";
      } else if (e is IssuerNotFound) {
        errorText = "error: issuer not found on stellar";
      }
      setState(() {
        _submitError = errorText;
        _state = nextState;
      });
    }
  }

  void _onPinCancel() {
    setState(() {
      _state = AssetsPageState.initial;
      _selectedAsset = null;
      _customAsset = null;
      _submitError = null;
    });
  }
}

class IssuerNotFound implements Exception {}

class InvalidAsset implements Exception {}

class AssetNotAdded implements Exception {}
