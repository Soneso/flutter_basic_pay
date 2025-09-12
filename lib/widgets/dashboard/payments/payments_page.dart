// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/path_payments_body.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/simple_payments_body.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';
import 'package:provider/provider.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

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
              showCard: false,
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
                  showCard: false,
                ),
              );
            }
            return FutureBuilder<List<ContactInfo>>(
              future: dashboardState.data.loadContacts(),
              builder: (context, futureSnapshot) {
                if (!futureSnapshot.hasData) {
                  return const Center(
                    child: LoadingWidget(
                      message: 'Loading contacts...',
                      showCard: false,
                    ),
                  );
                }
                return StreamBuilder<List<ContactInfo>>(
                  initialData: futureSnapshot.data,
                  stream: dashboardState.data.subscribeForContacts(),
                  builder: (context, contactsSnapshot) {
                    if (contactsSnapshot.data == null) {
                      return const Center(
                        child: LoadingWidget(
                          message: 'Loading contacts...',
                          showCard: false,
                        ),
                      );
                    }
                    var key = List<Object>.empty(growable: true);
                    key.addAll(assetsSnapshot.data!);
                    key.addAll(contactsSnapshot.data!);
                    return PaymentsPageBody(key: ObjectKey(key));
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class PaymentsPageBody extends StatefulWidget {
  const PaymentsPageBody({
    super.key,
  });

  @override
  State<PaymentsPageBody> createState() => _PaymentsPageBodyState();
}

class _PaymentsPageBodyState extends State<PaymentsPageBody> {
  bool waitForAccountFunding = false;
  bool pathPayment = false;
  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    return Column(
      children: [
        // Header with gradient background
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade600,
                Colors.blue.shade400,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Payments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Send and receive Stellar assets',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: dashboardState.data.assets.isEmpty
              ? // Account needs funding
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: Colors.orange.shade600,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Account Not Funded',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your account needs to be funded on the Stellar Test Network to start making payments.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: waitForAccountFunding
                                  ? null
                                  : () async {
                                      setState(() {
                                        waitForAccountFunding = true;
                                      });
                                      await dashboardState.data.fundUserAccount();
                                      setState(() {
                                        waitForAccountFunding = false;
                                      });
                                    },
                              child: waitForAccountFunding
                                  ? const CircularProgress(
                                      size: 20,
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Fund Account on Testnet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Payment Type Toggle Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Payment Type',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          pathPayment
                                              ? 'Path Payment (Cross-asset)'
                                              : 'Simple Payment',
                                          style: TextStyle(
                                            color: pathPayment
                                                ? Colors.blue.shade600
                                                : Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch.adaptive(
                                      value: pathPayment,
                                      activeColor: Colors.blue.shade600,
                                      onChanged: (value) {
                                        setState(() {
                                          pathPayment = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (pathPayment)
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Send one asset and receive another',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontSize: 12,
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
                        const SizedBox(height: 16),
                        // Payment Form Card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: pathPayment
                                ? const PathPaymentsBodyContent()
                                : const SimplePaymentsPageBodyContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
