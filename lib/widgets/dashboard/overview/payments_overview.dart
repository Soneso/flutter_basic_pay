// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/data.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:provider/provider.dart';

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
            child: CircularProgressIndicator(),
          );
        }
        return StreamBuilder<List<PaymentInfo>>(
          initialData: futureSnapshot.data,
          stream: dashboardState.data.subscribeForRecentPayments(),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent payments",
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: Wrap(
            alignment: WrapAlignment.start,
            direction: Axis.horizontal,
            spacing: 10,
            children: [
              ...payments.map(
                (asset) => PaymentCard(asset),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class PaymentCard extends StatelessWidget {
  final PaymentInfo payment;

  const PaymentCard(this.payment, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: payment.direction == PaymentDirection.sent
          ? Colors.red[100]
          : Colors.green[200],
      child: Padding(
        padding:
            const EdgeInsets.only(left: 8.0, right: 8.0, top: 2.0, bottom: 2.0),
        child: AutoSizeText(payment.toString(),
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
