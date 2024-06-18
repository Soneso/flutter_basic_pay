// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_basic_pay/storage/storage.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;
import 'auth.dart';

class LocalAuthService implements Auth {
  @override
  Future<bool> get isSignedUp async => SecureStorage.hasUser();

  @override
  Future<User> signIn(String pin) async {
    try {
      var userKeyPair = await SecureStorage.getUserKeyPair(pin);
      signedInUser = User(userKeyPair.address);
      return signedInUser!;
    } catch (e) {
      throw SignInException();
    }
  }

  @override
  Future signOut() async {
    signedInUser = null;
  }

  @override
  Future<User> signUp(wallet_sdk.SigningKeyPair userKeyPair, String pin) async {
    try {
      await SecureStorage.setUser(userKeyPair, pin);
      signedInUser = User(userKeyPair.address);
      return signedInUser!;
    } catch (e) {
      throw SignUpException();
    }
  }

  @override
  User? signedInUser;

  @override
  Future<wallet_sdk.SigningKeyPair> userKeyPair(String pin) async {
    try {
      return await SecureStorage.getUserKeyPair(pin);
    } catch (e) {
      throw RetrieveSeedException();
    }
  }
}
