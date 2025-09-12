// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/dropdowns.dart';
import 'package:flutter_basic_pay/widgets/common/pin_form.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';
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
            child: LoadingWidget(
              message: 'Loading assets...',
            ),
          );
        }
        return StreamBuilder<List<AssetInfo>>(
          initialData: futureSnapshot.data,
          stream: dashboardState.data.subscribeForAssetsInfo(),
          builder: (context, assetsSnapshot) {
            if (assetsSnapshot.data == null) {
              return const Center(
                child: LoadingWidget(
                  message: 'Loading assets...',
                ),
              );
            }
            return FutureBuilder<List<AnchoredAssetInfo>>(
              future: StellarService.getAnchoredAssets(assetsSnapshot.data!),
              builder: (context, futureSnapshot) {
                if (!futureSnapshot.hasData) {
                  return const Center(
                    child: LoadingWidget(
                      message: 'Loading anchor information...',
                    ),
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
  loading,
  sep10AuthPinRequired,
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
  String? _loadingText;
  var _state = TransfersPageState.initial;
  AuthToken? _sep10AuthToken;
  Sep6Info? _sep6Info;
  AnchorServiceInfo? _sep24Info;
  List<Sep6Transaction>? _sep6HistoryTransactions;
  List<Sep24Transaction>? _sep24HistoryTransactions;

  List<bool> _toggleSelections = [true, false];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Modern header with gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.swap_horiz,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Transfers",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Modern toggle buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            setState(() {
                              _toggleSelections = [true, false];
                              _errorText = null;
                              _state = TransfersPageState.initial;
                            });
                            // If an asset was selected, reload data for new transfer
                            if (_selectedAsset != null) {
                              await _handleAssetSelected(_selectedAsset!);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _toggleSelections[0]
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: _toggleSelections[0]
                                      ? Color(0xFF3B82F6)
                                      : Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "New Transfer",
                                  style: TextStyle(
                                    color: _toggleSelections[0]
                                        ? Color(0xFF3B82F6)
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            setState(() {
                              _toggleSelections = [false, true];
                              _errorText = null;
                              _state = TransfersPageState.initial;
                            });
                            // If an asset was selected, reload data for history
                            if (_selectedAsset != null) {
                              await _handleAssetSelected(_selectedAsset!);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _toggleSelections[1]
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  color: _toggleSelections[1]
                                      ? Color(0xFF3B82F6)
                                      : Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "History",
                                  style: TextStyle(
                                    color: _toggleSelections[1]
                                        ? Color(0xFF3B82F6)
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content area
        Expanded(
          child: Container(
            color: Color(0xFFF9FAFB),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: getBody(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget getBody(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    bool newTransfer = _toggleSelections[0];
    bool showHistory = !newTransfer;

    List<String> dropdownItems = widget.anchoredAssets
        .map((asset) => asset.asset.id)
        .toList(growable: true);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (newTransfer) ...[
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Initiate transfers with anchors for your supported assets",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
          widget.anchoredAssets.isEmpty
              ? Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFFFBBF24),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B),
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No Anchor Assets Available",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "You have no assets that support anchor transfers. For testing, add a trustline to SRT or UDSC on the Assets page.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF92400E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Modern dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: StringItemsDropdown(
                        title: "Select Asset",
                        items: dropdownItems,
                        onItemSelected: (String item) async {
                          await _handleAssetSelected(item);
                        },
                        initialSelectedItem: _selectedAsset,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_errorText != null)
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFFFCA5A5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_state == TransfersPageState.loading && _loadingText != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: LoadingWidget(
                          message: _loadingText,
                          showCard: false,
                        ),
                      ),
                  if (_state == TransfersPageState.sep10AuthPinRequired)
                    getSep10AuthPinForm(dashboardState),
                  if (newTransfer &&
                      _state == TransfersPageState.transferInfoLoaded &&
                      _sep6Info != null &&
                      _sep10AuthToken != null)
                    Sep6NewTransferWidget(
                      anchoredAsset: getSelectedAnchorAsset(),
                      sep6Info: _sep6Info!,
                      authToken: _sep10AuthToken!,
                      key: ObjectKey([_sep6Info, _sep10AuthToken]),
                    ),
                  if (newTransfer &&
                      _state == TransfersPageState.transferInfoLoaded &&
                      _sep24Info != null &&
                      _sep10AuthToken != null)
                    Sep24NewTransferWidget(
                        anchoredAsset: getSelectedAnchorAsset(),
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
      ),
    );
  }

  Column getSep6HistoryColumn(List<Sep6Transaction> transactions) {
    var anchorAsset = getSelectedAnchorAsset();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "SEP-06 Transfer History",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        Sep6TransferHistoryWidget(
            assetCode: anchorAsset.asset.code,
            transactions: transactions,
            key: ObjectKey(transactions)),
        SizedBox(height: 16),
      ],
    );
  }

  Column getSep24HistoryColumn(List<Sep24Transaction> transactions) {
    var anchorAsset = getSelectedAnchorAsset();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.language,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "SEP-24 Transfer History",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        Sep24TransferHistoryWidget(
            assetCode: anchorAsset.asset.code,
            transactions: transactions,
            key: ObjectKey(transactions)),
        SizedBox(height: 16),
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
      _loadingText = 'Loading SEP-10 info';
      _state = TransfersPageState.loading;
    });

    var anchoredAsset = getSelectedAnchorAsset();
    String? error;
    try {
      TomlInfo tomlInfo = await anchoredAsset.anchor.sep1();
      if (tomlInfo.webAuthEndpoint == null) {
        error = "the anchor does not provide an authentication service (SEP-10)";
      }
    } catch (e) {
      if (e is TomlNotFoundException) {
        error = "the anchor does not provide a stellar.toml file";
      } else {
        error = "could not load the asset's anchor toml data. ${e.toString()}";
      }
    }

    if (error != null) {
      setState(() {
        _errorText = error;
        _state = TransfersPageState.initial;
      });
    } else {
      setState(() {
        _selectedAsset = newSelectedAsset;
        _state = TransfersPageState.sep10AuthPinRequired;
      });
    }
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
      _loadingText = 'Authenticating with anchor.';
      _state = TransfersPageState.loading;
    });

    var anchoredAsset = getSelectedAnchorAsset();
    bool newTransfer = _toggleSelections[0];

    try {
      // load and decode the secret key by using the users pin
      var userKeyPair = await dashboardState.authService.userKeyPair(pin);

      // authenticate with anchor
      var sep10 = await anchoredAsset.anchor.sep10();
      _sep10AuthToken = await sep10.authenticate(userKeyPair);
    } catch (e) {
      var error = "could not authenticate with the asset's anchor.";
      if (e is InvalidPin) {
        error = "invalid pin";
      } else if (e is AnchorAuthException) {
        error += ' ${e.message}';
      } else if (e is AnchorAuthNotSupported) {
        error = "the anchor does not provide an authentication service (SEP-10)";
      }
      setState(() {
        _errorText = error;
        _state = TransfersPageState.sep10AuthPinRequired;
      });
      return;
    }

    // load sep-06 info

    setState(() {
      _sep6Info = null;
      _sep6HistoryTransactions = null;
      _loadingText = 'Loading SEP-6 data';
      _state = TransfersPageState.loading;
    });

    bool sep6Supported = false;
    TomlInfo tomlInfo = await anchoredAsset.anchor.sep1();
    if (tomlInfo.transferServer != null) {
      sep6Supported = true;
    }

    if (sep6Supported) {
      if (newTransfer) {
        // new transfer selected
        try {
          var sep6 = anchoredAsset.anchor.sep6();
          _sep6Info = await sep6.info();
        } catch (e) {
          _errorText = 'error loading SEP-06 info: ${e.toString()}';
        }
      } else {
        // history selected
        try {
          var sep6 = anchoredAsset.anchor.sep6();
          _sep6HistoryTransactions = await sep6.getTransactionsForAsset(
              authToken: _sep10AuthToken!, assetCode: anchoredAsset.asset.code);
        } catch (e) {
          _errorText = 'error loading SEP-06 history: ${e.toString()}';
        }
      }
    }

    // load sep-24 info
    setState(() {
      _sep24Info = null;
      _sep24HistoryTransactions = null;
      _loadingText = 'Loading SEP-24 data';
      _state = TransfersPageState.loading;
    });

    bool sep24Supported = false;
    if (tomlInfo.transferServerSep24 != null) {
      sep24Supported = true;
    }

    if (sep24Supported) {
      if (newTransfer) {
        // new transfer selected
        try {
          var sep24 = anchoredAsset.anchor.sep24();
          _sep24Info = await sep24.getServiceInfo();
        } catch (e) {
          _errorText = 'error loading SEP-24 info: ${e.toString()}';
        }
      } else {
        // history selected
        try {
          var sep24 = anchoredAsset.anchor.sep24();
          _sep24HistoryTransactions = await sep24.getTransactionsForAsset(
              anchoredAsset.asset, _sep10AuthToken!);
        } catch (e) {
          _errorText = 'error loading SEP-24 history: ${e.toString()}';
        }
      }
    }

    if (!sep6Supported && !sep24Supported) {
      _errorText = 'the anchor does not support SEP-06 & SEP-24 transfers.';
    }

    setState(() {
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
