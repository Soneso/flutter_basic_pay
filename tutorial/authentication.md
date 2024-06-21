# Authentication

The Flutter Basic pay App handles user authentication by using the [`AuthService`](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/auth/auth.dart) class.
The class provides methods to sign up a user, sign in, sign out and also to retrieve their Stellar secret key from the [secure storage](secure_data_storage.md).
Furthermore, the class holds the current authentication state of the user (signed up, signed in or signed out).


# Code implementation

The user authentication state is covered by following class members:

```dart
/// Returns true if a user is signed up.
Future<bool> get userIsSignedUp async => SecureStorage.hasUser();

/// The user's Stellar address if the user is signed in. Otherwise null.
String? signedInUserAddress;

/// Returns true if the user is signed in.
bool get userIsSignedIn => signedInUserAddress != null;
```

Now let's have a look how a user is signed up:

```dart
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
```

To register the user, the service requires the user's signing keypair and pin. `SigningKeyPair` is a class provided by the wallet sdk, 
that holds the user's Stellar address and their secret key. By using this class, we can make sure that the secret key and user address are valid and match together.

The user data is stored in the secure storage, whereby the secret key is encrypted with the user's pin. See [secure data storage](secure_data_storage.md). 
By encrypting the secret key with the pin, we can ensure that only the user themselves have access to it by entering their pin code. The pin code is not saved by the app.

After the secret key has been securely stored, we assign the user's stellar address to the `signedInUserAddress` member variable. This means that the user is logged in immediately after registering and the status of our service is `signed in`.

**Sign out:**

```dart
/// Signs out the user.
Future signOut() async {
    signedInUserAddress = null;
}
```

The member variable `signedInUserAddress` is set to null. This means that the current status is now `signed out`.

**Sign in:**

The `signIn` method is provided to log in the user:

```dart
/// If the user is registered, this method is used to sign in the user
/// by using their pin code.
/// Throws [UserNotFound] if the user is not signed up.
/// Throws [InvalidPin] if the pin is invalid.
/// Returns the user's Stellar address on success.
Future<String> signIn(String pin) async {
    var userKeyPair = await SecureStorage.getUserKeyPair(pin);
    signedInUserAddress = userKeyPair.address;
    return signedInUserAddress!;
}   
```

To log the user in, an attempt is made to load their signing keypair from the secure storage. The user's pin code is required for this. 
It must be requested from the user when logging in. On success, we assign the user's stellar address to the `signedInUserAddress` member variable. This means that the user is signed in and the status of our service is `signed in`. If an error occurs, the `SecureStorage.getUserKeyPair` method throws either a `UserNotFound` or `InvalidPin` exception.
See [secure data storage](secure_data_storage.md). 


**Retreive the users's signing key pair:**

Transactions that are sent to the Stellar Network, such as a payment transaction, must be signed with the user's signing key before sending them to the network. With the method `getUserKeypair` we can get the signing key of the user. To do this, however, we need the user's pin code and must ask the user to provide it.

```dart
/// If the user is signed up, this method is used to retrieve the user's
/// signing keypair including the Stellar secret key. The [pin] must
/// be provided by the user so that the secret key can be decrypted.
/// Throws [UserNotFound] if the user is not signed up.
/// Throws [InvalidPin] if the pin is invalid.
/// Returns the user's Stellar signing key pair on success.
Future<wallet_sdk.SigningKeyPair> userKeyPair(String pin) async {
    return await SecureStorage.getUserKeyPair(pin);
}
```

The user's signing keypair is retrieved from the [secure data storage](secure_data_storage.md).


## Next

Continue with [Sign up and login](signup_and_sign_in.md).



