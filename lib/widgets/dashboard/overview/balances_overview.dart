// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:provider/provider.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';

class BalancesOverview extends StatelessWidget {
  const BalancesOverview({super.key});

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    return FutureBuilder<List<AssetInfo>>(
      future: dashboardState.data.loadAssets(),
      builder: (context, futureSnapshot) {
        if (!futureSnapshot.hasData) {
          return const Center(
            child: LoadingWidget(
              message: 'Loading balances...',
              showCard: false,
            ),
          );
        }
        return StreamBuilder<List<AssetInfo>>(
          initialData: futureSnapshot.data,
          stream: dashboardState.data.subscribeForAssetsInfo(),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: LoadingWidget(
                  message: 'Loading balances...',
                  showCard: false,
                ),
              );
            }
            return BalancesOverviewBody(
                assets: snapshot.data!.reversed.toList(),
                onFundAccount: () async =>
                    dashboardState.data.fundUserAccount());
          },
        );
      },
    );
  }
}

class BalancesOverviewBody extends StatefulWidget {
  final List<AssetInfo> assets;
  final VoidCallback onFundAccount;

  const BalancesOverviewBody(
      {required this.assets, required this.onFundAccount, super.key});

  @override
  State<BalancesOverviewBody> createState() => _BalancesOverviewBodyState();
}

class _BalancesOverviewBodyState extends State<BalancesOverviewBody> {
  bool waitForAccountFunding = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.08),
                  const Color(0xFF3B82F6).withOpacity(0.03),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Asset Balances",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: widget.assets.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Account Not Funded",
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your account needs to be funded on the Stellar Test Network to start using it.",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF78350F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: waitForAccountFunding
                              ? null
                              : () async {
                                  setState(() {
                                    waitForAccountFunding = true;
                                  });
                                  widget.onFundAccount();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: waitForAccountFunding
                              ? SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgress(
                                    size: 16,
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.rocket_launch, size: 18),
                          label: Text(
                            waitForAccountFunding ? 'Funding Account...' : 'Fund on Testnet',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Balances(widget.assets),
          ),
        ],
      ),
    );
  }
}

class Balances extends StatelessWidget {
  final List<AssetInfo> assets;

  const Balances(this.assets, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...assets.map(
          (asset) => BalanceCard(asset),
        ),
      ],
    );
  }
}

class BalanceCard extends StatelessWidget {
  final AssetInfo asset;

  const BalanceCard(this.asset, {super.key});

  @override
  Widget build(BuildContext context) {
    final isNative = asset.asset is NativeAssetId;
    final assetCode = isNative
        ? "XLM"
        : asset.asset is IssuedAssetId
            ? (asset.asset as IssuedAssetId).code
            : "";
    String balance = Util.removeTrailingZerosFormAmount(asset.balance);
    
    // Format large numbers
    if (balance.length > 12) {
      final parts = balance.split('.');
      if (parts[0].length > 9) {
        // Convert to millions/billions
        final num = double.tryParse(parts[0]) ?? 0;
        if (num >= 1e9) {
          balance = '${(num / 1e9).toStringAsFixed(2)}B';
        } else if (num >= 1e6) {
          balance = '${(num / 1e6).toStringAsFixed(2)}M';
        } else {
          balance = '${parts[0].substring(0, 9)}...';
        }
      } else if (parts.length > 1) {
        balance = '${parts[0]}.${parts[1].substring(0, 2.clamp(0, parts[1].length))}';
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isNative 
            ? const Color(0xFF3B82F6).withOpacity(0.05)
            : const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNative
              ? const Color(0xFF3B82F6).withOpacity(0.2)
              : const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isNative
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isNative ? Icons.star : Icons.token,
              color: isNative
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetCode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balance,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
