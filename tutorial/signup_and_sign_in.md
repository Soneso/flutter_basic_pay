# Sign up and sign in

Depending on whether a user is already registered or not, either the `SignUpPage` or the `SignInPage` widget is displayed when the application is started. 

This is done via the `SignInSwitcher` widget in [main.dart](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/main.dart).

```dart
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
```

It is important here that the `AuthService` is initialized when the app is started and then passed to the switcher. (see [authentication](authentication.md))

Now let's look at how the `SignInSwitcher` decides which widget to display next:

```dart
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
    setState(() {
      _userState = UserState.signedOut;
    });
  }
}
```

There are 4 possible user states for the switcher, which are taken into account: 

```dart
enum UserState { unknown, needsSignup, signedIn, signedOut }
```

Initially, the status is `unknown` and must first be determined. The determination takes place in the [`SplashScreen`](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/widgets/login/splash_screen.dart) widget, so this is displayed first. It uses the [authentication](authentication.md) service to determin the user state.

```dart
//...

var userState = UserState.unknown;

if (await authService.userIsSignedUp) {
    userState = authService.userIsSignedIn ? UserState.signedIn : UserState.signedOut;
} else {
    userState = UserState.needsSignup;
}

widget.onKnownUserState(userState);
```

## Sign up page

To start, we'll have our user create an account. Accounts are the central data structure in Stellar and can only exist with a valid keypair (a public and secret key) and the required minimum balance of XLM. Read more in the [Stellar docs: Accounts section](https://developers.stellar.org/docs/learn/fundamentals/stellar-data-structures/accounts).

In Flutter Basic Pay, the [SignUpPage](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/widgets/login/sign_up_page.dart) widget will display a randomized public and secret keypair that the user can select with the option to choose a new set if preferred.

![sign up public and secret keys](/img/signup-keys.png)

To generate a random user keypair, we use the wallet sdk:

```dart
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart' as wallet_sdk;

class _SignUpCardState extends State<SignUpCard> {

  var _userKeyPair = wallet_sdk.SigningKeyPair.random();
  bool _showSecretKey = false;

  // ...

  void _generateNewUserKeyPair() {
    setState(() {
      _userKeyPair = wallet_sdk.SigningKeyPair.random();
    });
  }
}
```

Next, we'll trigger the user to enter a pincode used to encrypt their secret key before it gets saved to their [secure local storage](secure_data_storage.md). The user will need to remember their pincode for future logins and to sign transactions before submitting them to the Stellar Network.

With Flutter Basic Pay, when the user clicks the “Signup” button, they will be asked to confirm their pincode.
Next we use our `AuthService` (see [authetication](authentication.md)) to sign up the user and securely store the users data.

```dart
class _SignUpCardState extends State<SignUpCard> {
  //...

  void _signUp(String pin) async {
    try {
      await widget.authService.signUp(_userKeyPair, pin);
      widget.onSuccess();
    } on SignUpException {
      _showError();
    }
  }
}
```

After signup, the user get's redirected to the dashboard home page by the `SignInSwitcher` widget.


## Sign in page

![sign in page](/img/sign_in_page.png)

If the user is already registered, the [`SignInPage`](https://github.com/Soneso/flutter_basic_pay/blob/main/lib/widgets/login/sign_in_page.dart) is displayed at app start. To sign in, the user must enter his pin code. The pin code is then verified and the user is signed in by using the [authentication service](authentication.md).


```dart
void _signIn(String pin) async {
    try {
        await widget.authService.signIn(pin);
        widget.onSuccess();
    } on UserNotFound {
        _showError('User is not registered');
    } on InvalidPin {
        _showError('Invalid pin');
    }
}
```

## Next

Continue with [Dashboard state](dashboard_state.md).