// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/transfer_utils.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Sep24NewTransferWidget extends StatefulWidget {
  final AnchoredAssetInfo anchoredAsset;
  final AnchorServiceInfo sep24Info;
  final AuthToken authToken;

  const Sep24NewTransferWidget({
    required this.anchoredAsset,
    required this.sep24Info,
    required this.authToken,
    super.key,
  });

  @override
  State<Sep24NewTransferWidget> createState() => _Sep24NewTransferWidgetState();
}

enum Sep24WidgetState { initial, loading }

class _Sep24NewTransferWidgetState extends State<Sep24NewTransferWidget> {
  var _state = Sep24WidgetState.initial;
  AnchorServiceAsset? _depositInfo;
  AnchorServiceAsset? _withdrawalInfo;
  String? _errorText;
  final _controller = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
  @override
  Widget build(BuildContext context) {
    var anchoredAsset = widget.anchoredAsset;
    var sep24Info = widget.sep24Info;
    _depositInfo = getDepositInfoIfEnabled(sep24Info, anchoredAsset.asset.code);
    _withdrawalInfo = getWithdrawalInfoIfEnabled(sep24Info, anchoredAsset.asset.code);

    return Column(children: [
      const SizedBox(height: 10),
      const Divider(
        color: Colors.blue,
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("SEP-24 Transfers",
                style: Theme.of(context).textTheme.titleMedium),
            if (_depositInfo == null && _withdrawalInfo == null)
              Text("not supported",
                  style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      const SizedBox(width: 10),
      getButtons(),
      if (_state == Sep24WidgetState.loading)
        Util.getLoadingColumn(context, 'Loading ...', showDivider: false),
      if (_errorText != null) getErrorTextWidget(context, _errorText!),
    ]);
  }

  Row getButtons() {
    if (_state == Sep24WidgetState.loading) {
      return const Row(children: []);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_depositInfo != null)
          ElevatedButton(
            onPressed: deposit,
            child: const Text('Deposit', style: TextStyle(color: Colors.green)),
          ),
        if (_withdrawalInfo != null)
          ElevatedButton(
            onPressed: withdraw,
            child: const Text('Withdraw', style: TextStyle(color: Colors.red)),
          ),
        if (_depositInfo != null && _withdrawalInfo == null)
          Text("asset not supported",
              style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Future<void> deposit() async {
    setState(() {
      _state = Sep24WidgetState.loading;
    });

    var anchoredAsset = widget.anchoredAsset;
    var authToken = widget.authToken;
    try {
      var sep24 = anchoredAsset.anchor.sep24();
      var interactiveResponse = await sep24.deposit(anchoredAsset.asset, authToken);
      var url = interactiveResponse.url;
      _controller.loadRequest(Uri.parse(url));
    } catch (e) {
      _errorText = 'An error occurred: ${e.toString()}.';
    }

    showModalBottomSheet(
        context: NavigationService.navigatorKey.currentContext!,
        isScrollControlled: true,
        builder: (context) {
          return WebViewContainer(
              title: "SEP-24 Deposit", controller: _controller);
        });

    setState(() {
      _state = Sep24WidgetState.initial;
    });
  }

  Future<void> withdraw() async {
    setState(() {
      _state = Sep24WidgetState.loading;
    });

    var anchoredAsset = widget.anchoredAsset;
    var authToken = widget.authToken;

    try {
      var sep24 = anchoredAsset.anchor.sep24();
      var interactiveResponse =
          await sep24.withdraw(anchoredAsset.asset, authToken);
      var url = interactiveResponse.url;
      _controller.loadRequest(Uri.parse(url));
    } catch (e) {
      _errorText = 'An error occurred: ${e.toString()}.';
    }

    showModalBottomSheet(
        context: NavigationService.navigatorKey.currentContext!,
        isScrollControlled: true,
        builder: (context) {
          return WebViewContainer(
              title: "SEP-24 Withdrawal", controller: _controller);
        });

    setState(() {
      _state = Sep24WidgetState.initial;
    });
  }

  AnchorServiceAsset? getDepositInfoIfEnabled(AnchorServiceInfo sep24Info, String assetCode) {
    if (sep24Info.deposit.containsKey(assetCode)) {
      var depositInfo = sep24Info.deposit[assetCode]!;
      if (depositInfo.enabled) {
        return depositInfo;
      }
    }
    return null;
  }

  AnchorServiceAsset? getWithdrawalInfoIfEnabled(AnchorServiceInfo sep24Info, String assetCode) {
    if (sep24Info.withdraw.containsKey(assetCode)) {
      var withdrawInfo = sep24Info.withdraw[assetCode]!;
      if (withdrawInfo.enabled) {
        return withdrawInfo;
      }
    }
    return null;
  }

  static AutoSizeText getErrorTextWidget(BuildContext context, String text,
      {Key? key}) {
    return AutoSizeText(
      text,
      key: key ?? ObjectKey(text),
      style:
          Theme.of(context).textTheme.apply(bodyColor: Colors.red).bodyMedium,
    );
  }
}
