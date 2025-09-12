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

class PaymentsOverview extends StatelessWidget {
  const PaymentsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    return FutureBuilder<List<PaymentInfo>>(
      future: dashboardState.data.loadRecentPayments(),
      builder: (context, futureSnapshot) {
        if (!futureSnapshot.hasData) {
          return const Center(
            child: LoadingWidget(
              message: 'Loading payments...',
              showCard: false,
            ),
          );
        }
        return StreamBuilder<List<PaymentInfo>>(
          initialData: futureSnapshot.data,
          stream: dashboardState.data.subscribeForRecentPayments(),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: LoadingWidget(
                  message: 'Loading payments...',
                  showCard: false,
                ),
              );
            }
            return PaymentsBody(snapshot.data!);
          },
        );
      },
    );
  }
}

class PaymentsBody extends StatelessWidget {
  final List<PaymentInfo> payments;

  const PaymentsBody(this.payments, {super.key});

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
                  const Color(0xFF8B5CF6).withOpacity(0.08),
                  const Color(0xFF8B5CF6).withOpacity(0.03),
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
                        color: const Color(0xFF8B5CF6).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Recent Payments",
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
            child: payments.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "No recent payments",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: payments
                        .take(5)
                        .map((payment) => PaymentCard(payment))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class PaymentCard extends StatelessWidget {
  final PaymentInfo payment;

  const PaymentCard(this.payment, {super.key});

  @override
  Widget build(BuildContext context) {
    final isSent = payment.direction == PaymentDirection.sent;
    final assetCode = payment.asset.id == 'native' 
        ? 'XLM' 
        : payment.asset is IssuedAssetId 
            ? (payment.asset as IssuedAssetId).code 
            : '';
    String amount = Util.removeTrailingZerosFormAmount(payment.amount);
    final displayAddress = payment.contactName ?? Util.shortAddress(payment.address);
    
    // Format large numbers
    if (amount.length > 12) {
      final parts = amount.split('.');
      if (parts[0].length > 9) {
        final num = double.tryParse(parts[0]) ?? 0;
        if (num >= 1e9) {
          amount = '${(num / 1e9).toStringAsFixed(2)}B';
        } else if (num >= 1e6) {
          amount = '${(num / 1e6).toStringAsFixed(2)}M';
        } else {
          amount = '${parts[0].substring(0, 9)}...';
        }
      } else if (parts.length > 1) {
        amount = '${parts[0]}.${parts[1].substring(0, 2.clamp(0, parts[1].length))}';
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSent
            ? const Color(0xFFEF4444).withOpacity(0.03)
            : const Color(0xFF10B981).withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSent
              ? const Color(0xFFEF4444).withOpacity(0.15)
              : const Color(0xFF10B981).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSent
                  ? const Color(0xFFEF4444).withOpacity(0.1)
                  : const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSent ? Icons.arrow_upward : Icons.arrow_downward,
              color: isSent
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isSent ? "Sent" : "Received",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSent
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: TextStyle(
                        color: const Color(0xFF9CA3AF),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${isSent ? "to" : "from"} $displayAddress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$amount $assetCode',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
