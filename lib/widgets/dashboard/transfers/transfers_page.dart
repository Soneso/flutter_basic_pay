// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/dropdowns.dart';
import 'package:flutter_basic_pay/widgets/common/pin_form.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/sep24_new_transfer_widget.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/sep24_transfer_history.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/sep6_new_transfer_widget.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/sep6_transfer_history.dart';
import 'package:provider/provider.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';

class TransfersPage extends StatelessWidget {
  const TransfersPage({super.key});

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
          builder: (context, assetsSnapshot) {
            if (assetsSnapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return FutureBuilder<List<AnchoredAssetInfo>>(
              future: StellarService.getAnchoredAssets(assetsSnapshot.data!),
              builder: (context, futureSnapshot) {
                if (!futureSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                var key = List<Object>.empty(growable: true);
                key.addAll(assetsSnapshot.data!);
                key.addAll(futureSnapshot.data!);
                return TransfersPageBody(
                    anchoredAssets: futureSnapshot.data!, key: ObjectKey(key));
              },
            );
          },
        );
      },
    );
  }
}

enum TransfersPageState {
  initial,
  loadingAssetSep10Info,
  sep10AuthPinRequired,
  sep10Authenticating,
  loadingSep6Info,
  loadingSep24Info,
  loadingSep38Info,
  transferInfoLoaded
}

class TransfersPageBody extends StatefulWidget {
  final List<AnchoredAssetInfo> anchoredAssets;

  const TransfersPageBody({required this.anchoredAssets, super.key});

  @override
  State<TransfersPageBody> createState() => _TransfersPageBodyState();
}

class _TransfersPageBodyState extends State<TransfersPageBody> {
  String? _selectedAsset;
  String? _errorText;
  var _state = TransfersPageState.initial;
  AuthToken? _sep10AuthToken;
  Sep6Info? _sep6Info;
  QuotesInfoResponse? _sep38Info;
  AnchorServiceInfo? _sep24Info;
  List<Sep6Transaction>? _sep6HistoryTransactions;
  List<Sep24Transaction>? _sep24HistoryTransactions;

  List<bool> _toggleSelections = [true, false];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Transfers", style: Theme.of(context).textTheme.titleLarge),
              ToggleButtons(
                isSelected: _toggleSelections,
                selectedColor: Colors.blue,
                selectedBorderColor: Colors.blue,
                onPressed: (int index) {
                  setState(() {
                    if (index == 0) {
                      _toggleSelections = [true, false];
                    } else {
                      _toggleSelections = [false, true];
                    }
                    _selectedAsset = null;
                    _errorText = null;
                    _state = TransfersPageState.initial;
                  });
                },
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.add),
                      const SizedBox(height: 5.0),
                      Text(" New ",
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.history),
                      const SizedBox(height: 5.0),
                      Text(" History ",
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
        Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 2.0, right: 2.0, top: 8.0),
              child: SingleChildScrollView(
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
                        child: getBody(context)),
                  ),
                ),
              )),
        ),
      ],
    );
  }

  Widget getBody(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    bool showHistory = _toggleSelections[1];

    List<String> dropdownItems = widget.anchoredAssets
        .map((asset) => asset.asset.id)
        .toList(growable: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AutoSizeText(
          showHistory
              ? "History (testanchor.stellar.org): "
              : "Here you can initiate a transfer with an anchor for your assets which have the needed infrastructure available.",
          style: showHistory
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Divider(
          color: Colors.blue,
        ),
        widget.anchoredAssets.isEmpty
            ? AutoSizeText(
                "You have no assets that have the needed infrastructure for anchor transfers. For testing, "
                "add a trustline to one of the Stellar Test Anchor Assets (SRT or UDSC) "
                "on the Assets page.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              )
            : Column(
                children: [
                  const SizedBox(height: 10),
                  StringItemsDropdown(
                    title: "Select Asset",
                    items: dropdownItems,
                    onItemSelected: (String item) async {
                      await _handleAssetSelected(item);
                    },
                    initialSelectedItem: _selectedAsset,
                  ),
                  const SizedBox(height: 10),
                  if (_errorText != null)
                    Util.getErrorTextWidget(context, _errorText!),
                  if (_state == TransfersPageState.loadingAssetSep10Info)
                    Util.getLoadingColumn(context, 'Loading SEP-10 data.'),
                  if (_state == TransfersPageState.sep10AuthPinRequired)
                    getSep10AuthPinForm(dashboardState),
                  if (_state == TransfersPageState.sep10Authenticating)
                    Util.getLoadingColumn(
                        context, 'Authenticating with anchor.'),
                  if (_state == TransfersPageState.loadingSep6Info)
                    Util.getLoadingColumn(context, 'Loading SEP-06 data.'),
                  if (_state == TransfersPageState.loadingSep24Info)
                    Util.getLoadingColumn(context, 'Loading SEP-24 data.'),
                  if (_state == TransfersPageState.loadingSep38Info)
                    Util.getLoadingColumn(context, 'Loading SEP-38 data.'),
                  if (!showHistory &&
                      _state == TransfersPageState.transferInfoLoaded &&
                      _sep6Info != null &&
                      _sep10AuthToken != null)
                    Sep6NewTransferWidget(
                      asset: getSelectedAnchorAsset(),
                      sep6Info: _sep6Info!,
                      authToken: _sep10AuthToken!,
                      sep38Info: _sep38Info,
                      key: ObjectKey([_sep6Info, _sep10AuthToken]),
                    ),
                  if (!showHistory &&
                      _state == TransfersPageState.transferInfoLoaded &&
                      _sep24Info != null &&
                      _sep10AuthToken != null)
                    Sep24NewTransferWidget(
                        asset: getSelectedAnchorAsset(),
                        sep24Info: _sep24Info!,
                        authToken: _sep10AuthToken!,
                        key: ObjectKey([_sep24Info, _sep10AuthToken])),
                  if (showHistory &&
                      _state == TransfersPageState.transferInfoLoaded &&
                      _sep6HistoryTransactions != null &&
                      _sep6HistoryTransactions!.isNotEmpty)
                    getSep6HistoryColumn(_sep6HistoryTransactions!),
                  if (showHistory &&
                      _state == TransfersPageState.transferInfoLoaded &&
                      _sep24HistoryTransactions != null &&
                      _sep24HistoryTransactions!.isNotEmpty)
                    getSep24HistoryColumn(_sep24HistoryTransactions!),
                ],
              )
      ],
    );
  }

  Column getSep6HistoryColumn(List<Sep6Transaction> transactions) {
    var anchorAsset = getSelectedAnchorAsset();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.blue),
        Text("SEP-06 Transfers",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Sep6TransferHistoryWidget(
            assetCode: anchorAsset.asset.code,
            transactions: transactions,
            key: ObjectKey(transactions)),
        const Divider(color: Colors.blue),
      ],
    );
  }

  Column getSep24HistoryColumn(List<Sep24Transaction> transactions) {
    var anchorAsset = getSelectedAnchorAsset();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.blue),
        Text("SEP-24 Transfers",
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Sep24TransferHistoryWidget(
            assetCode: anchorAsset.asset.code,
            transactions: transactions,
            key: ObjectKey(transactions)),
        const Divider(color: Colors.blue),
      ],
    );
  }

  Future<void> _handleAssetSelected(String item) async {
    String? newSelectedAsset = item;

    setState(() {
      _selectedAsset = newSelectedAsset;
      _errorText = null;
      _sep6Info = null;
      _sep24Info = null;
      _sep38Info = null;
      _state = TransfersPageState.loadingAssetSep10Info;
    });

    var asset = getSelectedAnchorAsset();
    try {
      await asset.anchor.sep10();
    } catch (e, stacktrace) {
      var errorText =
          "error: could not load the asset's SEP-10 authentication service data. $stacktrace";
      if (e is AnchorAuthNotSupported) {
        errorText =
            "error: the anchor does not provide an SEP-10 authentication service";
      }
      setState(() {
        _errorText = errorText;
        _state = TransfersPageState.initial;
      });
      return;
    }

    setState(() {
      _selectedAsset = newSelectedAsset;
      _state = TransfersPageState.sep10AuthPinRequired;
    });
  }

  AnchoredAssetInfo getSelectedAnchorAsset() {
    return widget.anchoredAssets
        .firstWhere((element) => element.asset.id == _selectedAsset);
  }

  PinForm getSep10AuthPinForm(DashboardState dashboardState) {
    return PinForm(
      onPinSet: (String pin) async {
        await _handlePinSetForSep10Auth(pin, dashboardState);
      },
      onCancel: _onSep10AuthPinCancel,
      hintText: 'Enter pin to authenticate with the assets anchor.',
    );
  }

  Future<void> _handlePinSetForSep10Auth(
      String pin, DashboardState dashboardState) async {
    setState(() {
      _errorText = null;
      _state = TransfersPageState.sep10Authenticating;
    });

    var anchoredAsset = getSelectedAnchorAsset();
    bool isShowingHistory = _toggleSelections[1];

    try {
      // load secret seed and check if pin is valid.
      var userKeyPair = await dashboardState.authService.userKeyPair(pin);

      // authenticate with anchor
      var sep10 = await anchoredAsset.anchor.sep10();
      _sep10AuthToken = await sep10.authenticate(userKeyPair);
    } catch (e) {
      var errorText = "error: could not authenticate with the asset's anchor.";
      if (e is InvalidPin) {
        errorText = "error: invalid pin";
      } else if (e is AnchorAuthException) {
        errorText += ' ${e.message}';
      } else if (e is AnchorAuthNotSupported) {
        errorText =
            "error: the anchor does not provide an SEP-10 authentication service";
      }
      setState(() {
        _errorText = errorText;
        _state = TransfersPageState.sep10AuthPinRequired;
      });
      return;
    }

    // load sep-06 info

    setState(() {
      _sep6Info = null;
      _sep6HistoryTransactions = null;
      _state = TransfersPageState.loadingSep6Info;
    });

    var sep6 = anchoredAsset.anchor.sep6();

    if (isShowingHistory) {
      try {
        _sep6HistoryTransactions = await sep6.getTransactionsForAsset(
            authToken: _sep10AuthToken!, assetCode: anchoredAsset.asset.code);
      } catch (e) {
        setState(() {
          _errorText = 'error loading SEP-06 history: ${e.toString()}';
        });
      }
    } else {
      try {
        _sep6Info = await sep6.info(authToken: _sep10AuthToken);
      } catch (e) {
        if (e is! AnchorDepositAndWithdrawalAPINotSupported) {
          setState(() {
            _errorText = 'error loading SEP-06 info: ${e.toString()}';
          });
        }
      }
    }

    // load sep-24 info

    setState(() {
      _sep24Info = null;
      _sep24HistoryTransactions = null;
      _state = TransfersPageState.loadingSep24Info;
    });

    var sep24 = anchoredAsset.anchor.sep24();
    if (isShowingHistory) {
      try {
        _sep24HistoryTransactions = await sep24.getTransactionsForAsset(
            anchoredAsset.asset, _sep10AuthToken!);
      } catch (e) {
        setState(() {
          _errorText = 'error loading SEP-24 history: ${e.toString()}';
        });
      }
    } else {
      try {
        _sep24Info = await sep24.getServiceInfo();
      } catch (e) {
        if (e is! AnchorInteractiveFlowNotSupported) {
          setState(() {
            _errorText = 'error loading SEP-24 info: ${e.toString()}';
          });
        }
      }
    }

    if (!isShowingHistory && _sep6Info == null && _sep24Info == null) {
      setState(() {
        _errorText = 'anchor does not support SEP-06 & SEP-24 transfers.';
        _state = TransfersPageState.initial;
      });
      return;
    }

    /*

    // load sep-38 info for quotes.
    setState(() {
      _sep38Info = null;
      _state = TransfersPageState.loadingSep38Info;
    });

    try {
      var sep38 = await anchoredAsset.anchor.sep38(authToken: _sep10AuthToken!);
      // load only by auth token
      _sep38Info = await sep38.info();
    } catch (e) {
      // e.g. sep38 not supported by anchor.
      if (kDebugMode) {
        print('error loading SEP-38 info: ${e.toString()}');
      }
    } */

    setState(() {
      _errorText = null;
      _state = TransfersPageState.transferInfoLoaded;
    });
  }

  void _onSep10AuthPinCancel() {
    setState(() {
      _state = TransfersPageState.initial;
      _selectedAsset = null;
      _errorText = null;
    });
  }
}
