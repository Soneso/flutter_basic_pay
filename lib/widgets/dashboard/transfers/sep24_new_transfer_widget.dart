// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/transfer_utils.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';
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
                      Icons.web,
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
                          'SEP-24 Transfers',
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
                      'Interactive web-based transfers',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    if (_state == Sep24WidgetState.loading)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircularProgress(
                              size: 20,
                              strokeWidth: 2,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading transfer interface...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      getButtons(),
                    
                    if (_errorText != null)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'SEP-24 transfers are not available for this asset. Please check with the anchor provider for supported transfer methods.',
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

  Widget getButtons() {
    if (_state == Sep24WidgetState.loading) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (_depositInfo != null)
          Expanded(
            child: Container(
              height: 48,
              margin: EdgeInsets.only(right: _withdrawalInfo != null ? 6 : 0),
              child: ElevatedButton(
                onPressed: deposit,
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
                onPressed: withdraw,
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
        useSafeArea: true,
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
        useSafeArea: true,
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
