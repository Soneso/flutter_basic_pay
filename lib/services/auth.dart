// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter_basic_pay/services/storage.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;

/// This class is used to handle user authentication.
/// It is used to signup, sign in and sign out the user by using their pincode.
/// It is also used to retrieve the users secret key from storage. The secret
/// key is needed to sign Stellar transactions.
/// The Flutter Basic Pay app uses local [SecureStorage] to store the data.
class AuthService {

  /// Returns true if a user is signed up.
  Future<bool> get userIsSignedUp async => SecureStorage.hasUser();

  /// The user's Stellar address if the user is signed in. Otherwise null.
  String? signedInUserAddress;

  /// Returns true if the user is signed in.
  bool get userIsSignedIn => signedInUserAddress != null;

  /// Sign up the user for the given Stellar Keypair and pincode.
  /// Throws [SignUpException] if signup fails. E.g. storage unavailable.
  /// Returns the user's Stellar address on success.
  Future<String> signUp(wallet_sdk.SigningKeyPair userKeyPair, String pin) async {
    try {
      await SecureStorage.storeUserKeyPair(userKeyPair, pin);
      signedInUserAddress = userKeyPair.address;
      return signedInUserAddress!;
    } catch (e) {
      throw SignUpException();
    }
  }

  /// If the user is signed up, this method is used to sign in the user
  /// by using their pincode.
  /// Throws [UserNotFound] if the user is not signed up.
  /// Throws [InvalidPin] if the pin is invalid.
  /// Returns the user's Stellar address on success.
  Future<String> signIn(String pin) async {
    var userKeyPair = await SecureStorage.getUserKeyPair(pin);
    signedInUserAddress = userKeyPair.address;
    return signedInUserAddress!;
  }

  /// If the user is signed up, this method is used to retrieve the user's
  /// signing keypair including the Stellar secret key. The [pin] must
  /// be provided by the user so that the secret key can be decrypted.
  /// Throws [UserNotFound] if the user is not signed up.
  /// Throws [InvalidPin] if the pin is invalid.
  /// Returns the user's Stellar signing key pair on success.
  Future<wallet_sdk.SigningKeyPair> userKeyPair(String pin) async {
    return await SecureStorage.getUserKeyPair(pin);
  }

  /// Signs out the user.
  void signOut() {
    signedInUserAddress = null;
  }
}

/// The [SignUpException] is thrown when the user could not be signed up with the
/// given pincode. E.g. storage is unavailable.
class SignUpException implements Exception {}
