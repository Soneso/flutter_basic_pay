// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/auth.dart';
import 'dart:async';

import 'package:flutter_basic_pay/main.dart';

class SplashScreen extends StatefulWidget {
  final AuthService authService;
  final ValueChanged<UserState> onKnownUserState;

  const SplashScreen(
      {required this.authService, required this.onKnownUserState, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUserState());
  }

  void _checkUserState() async {
    Future.delayed(
      const Duration(seconds: 2),
      () async {
        var authService = widget.authService;
        var userState = UserState.unknown;
        if (await authService.userIsSignedUp) {
          userState = authService.userIsSignedIn ? UserState.signedIn : UserState.signedOut;
        } else {
          userState = UserState.needsSignup;
        }
        widget.onKnownUserState(userState);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlutterLogo(
              size: 100.0,
            ),
            SizedBox(height: 16.0),
            Text('Flutter Basic Pay'),
          ],
        ),
      ),
    );
  }
}
