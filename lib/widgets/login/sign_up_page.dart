// Copyright 2024 The Stellar Wallet Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/services/auth.dart';
import 'package:flutter_basic_pay/widgets/common/dialogs.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;
import 'package:clipboard/clipboard.dart';


class SignUpPage extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onSuccess;

  const SignUpPage({
    required this.authService,
    required this.onSuccess,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SignUpCard(authService: authService, onSuccess: onSuccess),
      ),
    );
  }
}

class SignUpCard extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSuccess;

  const SignUpCard({
    required this.authService,
    required this.onSuccess,
    super.key,
  });

  @override
  State<SignUpCard> createState() => _SignUpCardState();
}

class _SignUpCardState extends State<SignUpCard> {
  var _userKeyPair = wallet_sdk.SigningKeyPair.random();
  bool _showSecretKey = false;

  void _signUp(String pin) async {
    try {
      await widget.authService.signUp(_userKeyPair, pin);
      widget.onSuccess();
    } on SignUpException {
      _showError();
    }
  }

  void _copyToClipboard(String text) async {
    await FlutterClipboard.copy(text);
    _showCopied();
  }

  void _generateNewUserKeyPair() {
    setState(() {
      _userKeyPair = wallet_sdk.SigningKeyPair.random();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.lightBlue,
              blurRadius: 50.0,
            ),
          ],
        ),
        child: Card(
          margin: const EdgeInsets.all(20.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Signup now!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 15),
                    AutoSizeText(
                      "Please provide a 6-digit pincode to sign up. This pincode will be used to encrypt the secret key for your Stellar address, before it is stored in your local storage. Your secret key to this address will be stored on your device. You will be the only one to ever have custody over this key.",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(
                  color: Colors.blue,
                ),
                const SizedBox(height: 10),
                Text(
                  'Public Key:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: AutoSizeText(
                        _userKeyPair.address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.copy_outlined,
                        size: 20,
                      ),
                      onPressed: () => _copyToClipboard(_userKeyPair.address),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(5.0),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    _generateNewUserKeyPair();
                  },
                  child: const Text('Generate new address?'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Switch(
                      value: _showSecretKey,
                      onChanged: (bool? value) {
                        setState(() {
                          _showSecretKey = value ?? false;
                        });
                      },
                    ),
                    Text('Show secret key?',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                if (_showSecretKey) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Secret Key:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                          flex: 7,
                          child: AutoSizeText(_userKeyPair.secretKey,
                              style: Theme.of(context).textTheme.bodyMedium)),
                      IconButton(
                        icon: const Icon(
                          Icons.copy_outlined,
                          size: 20,
                        ),
                        onPressed: () =>
                            _copyToClipboard(_userKeyPair.secretKey),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                SignUpForm(onPinSet: _signUp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to sign up.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showCopied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class SignUpForm extends StatefulWidget {
  final ValueChanged<String> onPinSet;

  const SignUpForm({
    required this.onPinSet,
    super.key,
  });

  @override
  State<SignUpForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignUpForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final myPinController = TextEditingController();

  @override
  void dispose() {
    myPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Enter a 6 digit Pin Code',
              hintStyle: Theme.of(context).textTheme.bodyLarge,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            obscureText: true,
            validator: (String? value) {
              if (value == null || value.isEmpty || value.length != 6) {
                return 'Please enter 6 digits';
              }
              return null;
            },
            controller: myPinController,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                // Validate will return true if the form is valid, or false if
                // the form is invalid.
                if (_formKey.currentState!.validate()) {
                  var action = await Dialogs.confirmPinDialog(
                      context, myPinController.text);
                  if (action == DialogAction.ok) {
                    widget.onPinSet(myPinController.text);
                  }
                }
              },
              child: const Text(
                'SIGNUP',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
