// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/sep6_deposit_stepper.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/sep6_withdraw_stepper.dart';
import 'package:provider/provider.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';

class Sep6NewTransferWidget extends StatefulWidget {
  final AnchoredAssetInfo anchoredAsset;
  final Sep6Info sep6Info;
  final AuthToken authToken;

  const Sep6NewTransferWidget({
    required this.anchoredAsset,
    required this.sep6Info,
    required this.authToken,
    super.key,
  });

  @override
  State<Sep6NewTransferWidget> createState() => _Sep6NewTransferWidgetState();
}

class _Sep6NewTransferWidgetState extends State<Sep6NewTransferWidget> {
  Sep6DepositInfo? _depositInfo;
  Sep6WithdrawInfo? _withdrawalInfo;

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    var sep6Info = widget.sep6Info;
    var anchoredAsset = widget.anchoredAsset;
    var authToken = widget.authToken;
    _depositInfo = getDepositInfoIfEnabled(sep6Info, anchoredAsset.asset.code);
    _withdrawalInfo = getWithdrawalInfoIfEnabled(sep6Info, anchoredAsset.asset.code);

    bool anchorHasEnabledFeeEndpoint = sep6Info.fee != null && sep6Info.fee!.enabled;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEP-06 Transfers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_depositInfo == null && _withdrawalInfo == null)
                          Text(
                            'Not supported for this asset',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            if (_depositInfo != null || _withdrawalInfo != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direct bank transfers via anchor services',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (_depositInfo != null)
                          Expanded(
                            child: Container(
                              height: 48,
                              margin: EdgeInsets.only(right: _withdrawalInfo != null ? 6 : 0),
                              child: ElevatedButton(
                                onPressed: () async {
                                  showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      builder: (context) {
                                        return Sep6DepositStepper(
                                            anchoredAsset: anchoredAsset,
                                            depositInfo: _depositInfo!,
                                            anchorHasEnabledFeeEndpoint: anchorHasEnabledFeeEndpoint,
                                            authToken: authToken);
                                      });
                                },
                                child: const Text(
                                  'Deposit',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        if (_withdrawalInfo != null)
                          Expanded(
                            child: Container(
                              height: 48,
                              margin: EdgeInsets.only(left: _depositInfo != null ? 6 : 0),
                              child: ElevatedButton(
                                onPressed: () async {
                                  showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      useSafeArea: true,
                                      builder: (context) {
                                        return Sep6WithdrawStepper(
                                          anchoredAsset: anchoredAsset,
                                          withdrawInfo: _withdrawalInfo!,
                                          anchorHasEnabledFeeEndpoint: anchorHasEnabledFeeEndpoint,
                                          authToken: authToken,
                                          dashboardState: dashboardState,
                                        );
                                      });
                                },
                                child: const Text(
                                  'Withdraw',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'SEP-06 transfers are not available for this asset. Please check with the anchor provider for supported transfer methods.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Sep6DepositInfo? getDepositInfoIfEnabled(
      Sep6Info sep6Info, String assetCode) {
    if (sep6Info.deposit != null && sep6Info.deposit!.containsKey(assetCode)) {
      var depositInfo = sep6Info.deposit![assetCode]!;
      if (depositInfo.enabled) {
        return depositInfo;
      }
    }
    return null;
  }

  Sep6WithdrawInfo? getWithdrawalInfoIfEnabled(
      Sep6Info sep6Info, String assetCode) {
    if (sep6Info.withdraw != null &&
        sep6Info.withdraw!.containsKey(assetCode)) {
      var withdrawInfo = sep6Info.withdraw![assetCode]!;
      if (withdrawInfo.enabled) {
        return withdrawInfo;
      }
    }
    return null;
  }
}
