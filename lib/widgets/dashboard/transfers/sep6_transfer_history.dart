// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/transfer_utils.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Sep6TransferHistoryWidget extends StatefulWidget {
  final List<Sep6Transaction> transactions;
  final String assetCode;

  const Sep6TransferHistoryWidget(
      {required this.assetCode, required this.transactions, super.key});

  @override
  State<Sep6TransferHistoryWidget> createState() =>
      _Sep6TransferHistoryWidgetState();
}

class _Sep6TransferHistoryWidgetState extends State<Sep6TransferHistoryWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
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
          children: [
            Icon(
              Icons.history,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No Transfer History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your SEP-06 transfer history will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Transaction list
        ...widget.transactions.map((Sep6Transaction item) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(20),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status.toString()).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getStatusIcon(item.status.toString()),
                          color: _getStatusColor(item.status.toString()),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTitle(item),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.status.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(item.status.toString()),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    ...getDetails(item),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  String getTitle(Sep6Transaction item) {
    String title = item.kind;
    if (item.kind == 'deposit' && item.amountIn != null) {
      title += ' ${item.amountIn!}';
    } else if (item.kind == 'withdrawal' && item.amountOut != null) {
      title += ' ${item.amountOut!}';
    }
    title += ' ${widget.assetCode}';
    return title;
  }

  List<Widget> getDetails(Sep6Transaction item) {
    List<Widget> details = List<Widget>.empty(growable: true);

    details.add(getRow('Id: ${item.id}'));
    details.add(getRow('Kind: ${item.kind}'));
    if (item.message != null) {
      details.add(getRow('Msg.: ${item.message}'));
    }
    if (item.statusEta != null) {
      details.add(getRow('Status Eta.: ${item.statusEta}'));
    }
    if (item.amountIn != null) {
      details.add(getRow('Amount in: ${item.amountIn}'));
    }
    if (item.amountInAsset != null) {
      details.add(getRow('Amount in asset: ${item.amountInAsset}'));
    }
    if (item.amountOut != null) {
      details.add(getRow('Amount out: ${item.amountOut}'));
    }
    if (item.amountOutAsset != null) {
      details.add(getRow('Amount out asset: ${item.amountOutAsset}'));
    }
    if (item.amountFee != null) {
      details.add(getRow('Amount fee: ${item.amountFee}'));
    }
    if (item.amountFeeAsset != null) {
      details.add(getRow('Amount fee asset: ${item.amountFeeAsset}'));
    }
    if (item.chargedFeeInfo != null) {
      details.addAll(getChargedFeeDetails(item.chargedFeeInfo!));
    }
    if (item.quoteId != null) {
      details.add(getRow('Quote id: ${item.quoteId}'));
    }
    if (item.from != null) {
      details.add(getRow('From: ${item.from}'));
    }
    if (item.to != null) {
      details.add(getRow('To: ${item.to}'));
    }
    if (item.externalExtra != null) {
      details.add(getRow('External extra: ${item.externalExtra}'));
    }
    if (item.externalExtraText != null) {
      details.add(getRow('External extra text: ${item.externalExtraText}'));
    }
    if (item.depositMemo != null) {
      details.add(getRow('Deposit memo: ${item.depositMemo}'));
    }
    if (item.depositMemoType != null) {
      details.add(getRow('Deposit memo type: ${item.depositMemoType}'));
    }
    if (item.withdrawAnchorAccount != null) {
      details.add(
          getRow('Withdraw anchor account: ${item.withdrawAnchorAccount}'));
    }
    if (item.startedAt != null) {
      details.add(getRow('Started at: ${item.startedAt}'));
    }
    if (item.updatedAt != null) {
      details.add(getRow('Updated at: ${item.updatedAt}'));
    }
    if (item.completedAt != null) {
      details.add(getRow('Completed at: ${item.completedAt}'));
    }
    if (item.stellarTransactionId != null) {
      details
          .add(getRow('Stellar transaction id: ${item.stellarTransactionId}'));
    }
    if (item.externalTransactionId != null) {
      details.add(
          getRow('External transaction id: ${item.externalTransactionId}'));
    }
    if (item.refunded != null) {
      details.add(getRow('Refunded: ${item.refunded}'));
    }
    if (item.refunds != null) {
      details.addAll(getRefundsDetails(item.refunds!));
    }
    if (item.requiredInfoMessage != null) {
      details.add(getRow('Required info message: ${item.requiredInfoMessage}'));
    }
    if (item.claimableBalanceId != null) {
      details.add(getRow('Claimable balance id: ${item.requiredInfoMessage}'));
    }
    
    // Add Update KYC info button for pending_customer_info_update status
    if (item.status == TransactionStatus.pendingCustomerInfoUpdate) {
      details.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _handleUpdateKYC(item);
            },
            icon: const Icon(Icons.edit_document, size: 16),
            label: const Text(
              'Update KYC info',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      );
    }
    
    if (item.moreInfoUrl != null) {
      //details.add(getRow('More info url: ${item.moreInfoUrl}'));
      details.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              var controller = WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..loadRequest(Uri.parse(item.moreInfoUrl!));
              showModalBottomSheet(
                  context: NavigationService.navigatorKey.currentContext!,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) {
                    return WebViewContainer(
                        title: "SEP-06 More info", controller: controller);
                  });
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text(
              'View More Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      );
    }

    // ... add more details here.
    // Map<String, Sep6FieldInfo>? requiredInfoUpdates;
    // Map<String, Sep6DepositInstruction>? instructions;

    return details;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFF3B82F6);
      case 'error':
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'error':
      case 'failed':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Widget getRow(String text) {
    // Parse the text to extract label and value
    final parts = text.split(': ');
    if (parts.length >= 2) {
      final label = parts[0];
      final value = parts.sublist(1).join(': ');
      
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Widget> getChargedFeeDetails(Sep6ChargedFee chargedFee) {
    List<Widget> details = List<Widget>.empty(growable: true);
    details.add(getRow('Charged fee - total: ${chargedFee.total}'));
    details.add(getRow('Charged fee - asset: ${chargedFee.asset}'));
    chargedFee.details?.map((Sep6ChargedFeeDetail item) {
      details.add(getRow('Charged fee - detail name: ${item.name}'));
      details.add(getRow('Charged fee - detail amount: ${item.amount}'));
      if (item.description != null) {
        details.add(getRow('Charged fee - detail desc.: ${item.description}'));
      }
    });
    return details;
  }

  List<Widget> getRefundsDetails(Sep6Refunds refunds) {
    List<Widget> details = List<Widget>.empty(growable: true);
    details.add(getRow('Refunds - amount refunded: ${refunds.amountRefunded}'));
    details.add(getRow('Refunds - amount fee: ${refunds.amountFee}'));
    refunds.payments.map((Sep6Payment item) {
      details.add(getRow('Refunds - payment id: ${item.id}'));
      details.add(getRow('Refunds - payment id type: ${item.idType}'));
      details
          .add(getRow('Refunds - payment ${item.id} amount: ${item.amount}'));
      details.add(getRow('Refunds - payment ${item.id} fee: ${item.fee}'));
    });
    return details;
  }
  
  // Placeholder function for updating KYC info
  void _handleUpdateKYC(Sep6Transaction transaction) {
    // TODO: Implement KYC update functionality
    // This will be implemented later to handle KYC updates
    // For now, this is just a placeholder that will be connected
    // to the actual KYC update flow in a future implementation
  }
}
