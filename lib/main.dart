// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/auth.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:flutter_basic_pay/widgets/login/sign_in_page.dart';
import 'package:flutter_basic_pay/widgets/login/sign_up_page.dart';
import 'package:flutter_basic_pay/widgets/login/splash_screen.dart';
import 'package:flutter_basic_pay/services/storage.dart';

void main() {
  runApp(FlutterBasicPayApp());
}

class FlutterBasicPayApp extends StatelessWidget {
  final AuthService authService = AuthService();
  FlutterBasicPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      navigatorKey: NavigationService.navigatorKey,
      home: SignInSwitcher(authService),
    );
  }
}

class SignInSwitcher extends StatefulWidget {
  final AuthService authService;

  const SignInSwitcher(this.authService, {super.key});

  @override
  State<SignInSwitcher> createState() => _SignInSwitcherState();
}

enum UserState { unknown, needsSignup, signedIn, signedOut }

class _SignInSwitcherState extends State<SignInSwitcher> {
  UserState _userState = UserState.unknown;

  @override
  Widget build(BuildContext context) {
    var authService = widget.authService;

    return AnimatedSwitcher(
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        duration: const Duration(milliseconds: 200),
        child: switch (_userState) {
          UserState.unknown => SplashScreen(
              authService: authService, onKnownUserState: _updateUserState),
          UserState.needsSignup => SignUpPage(
              authService: authService,
              onSuccess: () => _updateUserState(UserState.signedIn)),
          UserState.signedOut => SignInPage(
              authService: authService,
              onSuccess: () => _updateUserState(UserState.signedIn)),
          UserState.signedIn =>
            DashboardHomePage(authService: authService, onSignOutRequest: _signOut),
        });
  }

  void _updateUserState(UserState newUserState) {
    setState(() {
      _userState = newUserState;
    });
  }

  void _signOut() async {
    widget.authService.signOut();
    
    // Check if a user still exists in storage (they won't after a reset)
    bool hasUser = await SecureStorage.hasUser();
    
    setState(() {
      // If no user exists (after reset), show signup. Otherwise show signin.
      _userState = hasUser ? UserState.signedOut : UserState.needsSignup;
    });
  }
}
