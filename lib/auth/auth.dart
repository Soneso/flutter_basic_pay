// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
as wallet_sdk;

/// An abstract class defining the needed methods to authenticate the user.
/// It is used to signup, sign in and sign out the user by using their pincode.
/// It is also used to retrieve the users secret key from that storage that
/// is needed to sign Stellar transactions.
/// The Flutter Basic Pay app uses local storage to securely store the data.
/// The implementation can be found in [LocalAuthService] that implements this
/// abstract [Auth] class.
abstract class Auth {

  /// returns true if the user is signed up.
  Future<bool> get isSignedUp;

  /// Sign up the user for the given Stellar Keypair and pincode.
  /// Throws [SignUpException] if signup fails. E.g. storage unavailable.
  /// Returns the [User] object containing their stellar address on success.
  Future<User> signUp(wallet_sdk.SigningKeyPair userKeyPair, String pin);

  /// If the user is signed up, this method is used to sign in the user
  /// by using their pincode.
  /// Throws [SignInException] if the user could not be signed in with the given pin.
  /// E.g. pin is wrong.
  /// Returns the [User] object containing their stellar address on success.
  Future<User> signIn(String pin);

  /// If the user is signed up, this method is used to retrieve the users
  /// Keypair including the secret seed by using their pincode.
  Future<wallet_sdk.SigningKeyPair> userKeyPair(String pin);

  /// The signed in user if the user is signed in
  User? signedInUser;

  /// Signs out the user.
  Future signOut();
}

/// The [User] class holds the users address (account id) on the stellar network.
class User {
  /// The users address (account id) on the Stellar network.
  String address;

  /// Constructor. Takes the users Stellar network [address] (account id).
  User(this.address);
}

/// The [SignUpException] is thrown when the user could not be signed up with the
/// given pincode. E.g. storage is unavailable.
class SignUpException implements Exception {}

/// The [SignInException] is thrown when the user could not be signed in with the
/// given pincode. E.g. if the pincode is wrong.
class SignInException implements Exception {}

/// The [RetrieveSeedException] is thrown when the user's signing keypair could not be
/// retrieved by the [Auth.userKeyPair] method. E.g. pincode is wrong.
class RetrieveSeedException implements Exception {}