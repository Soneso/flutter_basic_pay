// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/widgets/dashboard/overview/balances_overview.dart';
import 'package:flutter_basic_pay/widgets/dashboard/overview/my_data_overview.dart';
import 'package:flutter_basic_pay/widgets/dashboard/overview/payments_overview.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BalancesOverview(),
            const SizedBox(height: 20),
            const PaymentsOverview(),
            const SizedBox(height: 20),
            const MyDataOverview(),
          ],
        ),
      ),
    );
  }
}
