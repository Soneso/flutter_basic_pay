// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/data.dart';
import 'package:flutter_basic_pay/services/auth.dart';
import 'package:flutter_basic_pay/widgets/common/adaptive_scaffold.dart';
import 'package:flutter_basic_pay/widgets/common/dialogs.dart';
import 'package:flutter_basic_pay/widgets/dashboard/assets/assets_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/contacts/contacts_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/overview/overview_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/payments_page.dart';
import 'package:provider/provider.dart';

class DashboardHomePage extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSignOutRequest;

  const DashboardHomePage(
      {required this.authService, required this.onSignOutRequest, super.key});

  @override
  State<DashboardHomePage> createState() => _DashboardHomePageState();
}

class DashboardState {
  final AuthService authService;
  late DashboardData data;

  DashboardState(this.authService) {
    data = DashboardData(authService.signedInUserAddress!);
  }
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  late final DashboardState _dashboardState;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboardState = DashboardState(widget.authService);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _dashboardState,
      child: AdaptiveScaffold(
        title: const Text('Flutter Basic Pay'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => _handleSignOut(),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          )
        ],
        currentIndex: _pageIndex,
        destinations: const [
          AdaptiveScaffoldDestination(title: 'Overview', icon: Icons.home),
          AdaptiveScaffoldDestination(title: 'Payments', icon: Icons.payments),
          AdaptiveScaffoldDestination(
              title: 'Assets', icon: Icons.currency_exchange),
          AdaptiveScaffoldDestination(title: 'Contacts', icon: Icons.person),
          AdaptiveScaffoldDestination(
              title: 'Transfers', icon: Icons.anchor_sharp),
        ],
        body: _pageAtIndex(_pageIndex),
        onNavigationIndexChange: (newIndex) {
          setState(() {
            _pageIndex = newIndex;
          });
        },
        floatingActionButton:
            _hasFloatingActionButton ? _buildFab(context) : null,
      ),
    );
  }

  bool get _hasFloatingActionButton {
    if (_pageIndex != 3) return false;
    return true;
  }

  FloatingActionButton _buildFab(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () => _handleFabPressed(context),
    );
  }

  void _handleFabPressed(BuildContext context) async {
    var contactInfo = await Dialogs.addContactDialog(context);
    if (contactInfo != null) {
      _dashboardState.data.addContact(contactInfo);
    }
  }

  Future<void> _handleSignOut() async {
    var shouldSignOut = await (showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    ));

    if (shouldSignOut == null || !shouldSignOut) {
      return;
    }

    widget.onSignOutRequest();
  }

  static Widget _pageAtIndex(int index) {
    switch (index) {
      case 0:
        return const DashboardOverview();
      case 1:
        return const PaymentsPage();
      case 2:
        return const AssetsPage();
      case 3:
        return const ContactsPage();
      default:
        return const Center(child: Text('not yet implemented'));
    }
  }
}
