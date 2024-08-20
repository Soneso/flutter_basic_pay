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

    return Column(children: [
      const SizedBox(height: 10),
      const Divider(color: Colors.blue),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("SEP-06 Transfers",
                style: Theme.of(context).textTheme.titleMedium),
            if (_depositInfo == null && _withdrawalInfo == null)
              Text("not supported",
                  style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_depositInfo != null)
            ElevatedButton(
              onPressed: () async {
                showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return Sep6DepositStepper(
                          anchoredAsset: anchoredAsset,
                          depositInfo: _depositInfo!,
                          anchorHasEnabledFeeEndpoint: anchorHasEnabledFeeEndpoint,
                          authToken: authToken);
                    });
              },
              child:
                  const Text('Deposit', style: TextStyle(color: Colors.green)),
            ),
          if (_withdrawalInfo != null)
            ElevatedButton(
              onPressed: () async {
                showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
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
              child:
                  const Text('Withdraw', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    ]);
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
