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
import 'package:flutter_basic_pay/widgets/dashboard/kyc/kyc_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/overview/overview_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/payments/payments_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/transfers_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/settings/settings_page.dart';
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
  final VoidCallback onSignOutRequest;
  late DashboardData data;

  DashboardState(this.authService, this.onSignOutRequest) {
    data = DashboardData(authService.signedInUserAddress!);
  }
}

class _DashboardHomePageState extends State<DashboardHomePage> {
  late final DashboardState _dashboardState;
  int _pageIndex = 0;
  
  // Track actual page index for More menu items
  int? _moreMenuPageIndex;

  @override
  void initState() {
    super.initState();
    _dashboardState = DashboardState(widget.authService, widget.onSignOutRequest);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: _dashboardState,
      child: AdaptiveScaffold(
        title: const Text(
          'Flutter Basic Pay',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: const [],
        currentIndex: _pageIndex <= 3 ? _pageIndex : 4,
        destinations: const [
          AdaptiveScaffoldDestination(title: 'Overview', icon: Icons.home),
          AdaptiveScaffoldDestination(title: 'Payments', icon: Icons.payments),
          AdaptiveScaffoldDestination(
              title: 'Assets', icon: Icons.currency_exchange),
          AdaptiveScaffoldDestination(
              title: 'Transfers', icon: Icons.anchor_sharp),
          AdaptiveScaffoldDestination(title: 'More', icon: Icons.menu),
        ],
        body: _pageAtIndex(_moreMenuPageIndex ?? _pageIndex),
        onNavigationIndexChange: (newIndex) {
          if (newIndex == 4) {
            // Show More menu
            _showMoreMenu();
          } else {
            setState(() {
              _pageIndex = newIndex;
              _moreMenuPageIndex = null;
            });
          }
        },
        floatingActionButton:
            _hasFloatingActionButton ? _buildFab(context) : null,
      ),
    );
  }

  bool get _hasFloatingActionButton {
    final actualIndex = _moreMenuPageIndex ?? _pageIndex;
    if (actualIndex == 5) return true;
    return false;
  }

  FloatingActionButton _buildFab(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add, size: 28),
      onPressed: () => _handleFabPressed(context),
    );
  }

  void _handleFabPressed(BuildContext context) async {
    final actualIndex = _moreMenuPageIndex ?? _pageIndex;
    if (actualIndex == 5) {
      var contactInfo = await Dialogs.addContactDialog(context);
      if (contactInfo != null) {
        _dashboardState.data.addContact(contactInfo);
      }
    }
  }
  
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'More Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.policy_outlined,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'KYC Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: const Text(
                    'Manage your verification status',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pageIndex = 4;
                      _moreMenuPageIndex = 4;
                    });
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: const Text(
                    'Manage your saved contacts',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pageIndex = 4;
                      _moreMenuPageIndex = 5;
                    });
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  title: const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: const Text(
                    'Account and app settings',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pageIndex = 4;
                      _moreMenuPageIndex = 6;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
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
        return const TransfersPage();
      case 4:
        return const KYCInformationPage();
      case 5:
        return const ContactsPage();
      case 6:
        return const SettingsPage();
      default:
        return const Center(child: Text('not yet implemented'));
    }
  }
}
