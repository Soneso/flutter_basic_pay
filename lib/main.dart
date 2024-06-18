// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/auth/auth.dart';
import 'package:flutter_basic_pay/auth/local_auth.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:flutter_basic_pay/widgets/login/sign_in.dart';
import 'package:flutter_basic_pay/widgets/login/sign_up.dart';
import 'package:flutter_basic_pay/widgets/login/splash_screen.dart';

void main() {
  runApp(BasicPayApp(LocalAuthService()));
}

class BasicPayApp extends StatelessWidget {
  final Auth auth;
  const BasicPayApp(this.auth, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      navigatorKey: NavigationService.navigatorKey,
      home: SignInSwitcher(auth),
    );
  }
}

class SignInSwitcher extends StatefulWidget {
  final Auth auth;

  const SignInSwitcher(this.auth, {super.key});

  @override
  State<SignInSwitcher> createState() => _SignInSwitcherState();
}

enum UserState { unknown, needsSignup, signedIn, signedOut }

class _SignInSwitcherState extends State<SignInSwitcher> {
  UserState _userState = UserState.unknown;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        duration: const Duration(milliseconds: 200),
        child: switch (_userState) {
          UserState.unknown => SplashScreen(
              auth: widget.auth, onUserStateKnown: _handleUpdateUserState),
          UserState.needsSignup =>
            SignUpPage(auth: widget.auth, onSuccess: _handleSignIn),
          UserState.signedOut =>
            SignInPage(auth: widget.auth, onSuccess: _handleSignIn),
          UserState.signedIn =>
            DashboardHomePage(auth: widget.auth, onSignOut: _handleSignOut),
        });
  }

  void _handleUpdateUserState(UserState newUserState) {
    setState(() {
      _userState = newUserState;
    });
  }

  void _handleSignIn(User user) {
    setState(() {
      _userState = UserState.signedIn;
    });
  }

  Future<void> _handleSignOut() async {
    await widget.auth.signOut();
    setState(() {
      _userState = UserState.signedOut;
    });
  }
}
