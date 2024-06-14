import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/auth/auth.dart';
import 'dart:async';

import 'package:flutter_basic_pay/main.dart';

class SplashScreen extends StatefulWidget {
  final Auth auth;
  final ValueChanged<UserState> onUserStateKnown;

  const SplashScreen(
      {required this.auth, required this.onUserStateKnown, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkUserState());
  }

  void _checkUserState() async {
    Future.delayed(
      const Duration(seconds: 2),
          () async {
            var userState = UserState.unknown;
            var isSignedUp = await widget.auth.isSignedUp;
            if (isSignedUp) {
              var isSignedIn = widget.auth.signedInUser != null;
              userState = isSignedIn ? UserState.signedIn : UserState.signedOut;
            } else {
              userState = UserState.needsSignup;
            }
            widget.onUserStateKnown(userState);
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
