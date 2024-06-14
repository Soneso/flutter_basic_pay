
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
as wallet_sdk;

abstract class Auth {
  Future<bool> get isSignedUp;
  Future<User> signUp(wallet_sdk.SigningKeyPair userKeyPair, String pin);
  Future<User> signIn(String pin);
  Future<wallet_sdk.SigningKeyPair> userKeyPair(String pin);
  User? signedInUser;
  Future signOut();
}

class User {
  String address;
  User(this.address);
}

class SignInException implements Exception {}
class SignUpException implements Exception {}
class RetrieveSeedException implements Exception {}