// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/data.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/dialogs.dart';
import 'package:flutter_basic_pay/widgets/common/dropdowns.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Assets", style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
              child: dashboardState.data.assets.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Your account does not exist on the Stellar Test Network and needs to be funded!",
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if (waitForAccountFunding) {
                              return;
                            }
                            setState(() {
                              waitForAccountFunding = true;
                            });
                            dashboardState.data.fundUserAccount();
                          },
                          child: waitForAccountFunding
                              ? const SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(),
                                )
                              : const Text('Fund on testnet',
                                  style: TextStyle(color: Colors.purple)),
                        ),
                      ],
                    )
                  : const AssetsPageBodyContent()),
        ),
      ],
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
    List<String> dropdownItems = dashboardState.data.knownAssets
        .map((asset) => asset.id)
        .toList(growable: true);

    // check if any of the assets are already trusted and if so, remove
    List<String> trustedAssets =
        dashboardState.data.assets.map((asset) => asset.asset.id).toList();
    dropdownItems.removeWhere((element) => trustedAssets.contains(element));

    // add custom item
    dropdownItems.add(addCustomAsset);

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.lightBlue,
              blurRadius: 50.0,
            ),
          ],
        ),
        child: Card(
          margin: const EdgeInsets.all(20.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AutoSizeText(
                  "Here you can manage the Stellar assets your account carries trustlines to. Select from pre-suggested assets, or specify your own asset to trust using an asset code and issuer public key. You can also remove trustlines that already exist on your account.",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Divider(
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                Text(
                  'Add Trusted Asset',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                AutoSizeText(
                  "Add a trustline on your account, allowing you to hold the specified asset.",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 10),
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
                      const SizedBox(height: 10),
                      if (_submitError != null)
                        Text(
                          _submitError!,
                          style: Theme.of(context)
                              .textTheme
                              .apply(bodyColor: Colors.red)
                              .bodyMedium,
                        ),
                      if (_customAsset != null)
                        Text(
                          _customAsset!.id,
                          style: Theme.of(context)
                              .textTheme
                              .apply(bodyColor: Colors.blue)
                              .bodyMedium,
                        ),
                      if (_state != AssetsPageState.initial)
                        PinForm(
                          onPinSet: (String pin) async {
                            await _handlePinSet(pin, dashboardState);
                          },
                          onCancel: _onPinCancel,
                          hintText: 'Enter pin to add asset',
                        ),
                    ],
                  ),
                if (_state == AssetsPageState.sending)
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
                            'Adding asset ...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                const Divider(
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                Text(
                  'Existing Balances',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                AutoSizeText(
                  "View or remove asset trustlines on your Stellar account.",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...dashboardState.data.assets.map(
                      (asset) => AssetBalanceCard(
                          asset,
                          dashboardState.auth.userKeyPair,
                          dashboardState.data.removeAssetSupport,
                          key: ObjectKey(asset)),
                    )
                  ],
                )
              ],
            ),
          ),
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
        asset = dashboardState.data.knownAssets
            .firstWhere((item) => item.id == _selectedAsset);
      }

      if (asset != null) {
        // check if the issuer account id exists on the stellar network
        var issuerExists =
            await StellarService.accountExists(asset.issuer);
        if (!issuerExists) {
          throw IssuerNotFound();
        }

        // load secret seed and check if pin is valid.
        var userKeyPair = await dashboardState.auth.userKeyPair(pin);

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
