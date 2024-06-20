// Copyright 2024 The Stellar Wallet Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/services/auth.dart';
import 'package:flutter_basic_pay/services/storage.dart';


class SignInPage extends StatelessWidget {
  final AuthService auth;
  final ValueChanged<String> onSuccess;

  const SignInPage({
    required this.auth,
    required this.onSuccess,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SignInCard(auth: auth, onSuccess: onSuccess),
      ),
    );
  }
}

class SignInCard extends StatefulWidget {
  final AuthService auth;
  final ValueChanged<String> onSuccess;

  const SignInCard({
    required this.auth,
    required this.onSuccess,
    super.key,
  });

  @override
  State<SignInCard> createState() => _SignInCardState();
}

class _SignInCardState extends State<SignInCard> {
  void _signIn(String pin) async {
    try {
      var user = await widget.auth.signIn(pin);
      widget.onSuccess(user);
    } on UserNotFound {
      _showError('User is not registered');
    } on InvalidPin {
      _showError('Invalid pin');
    }
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
                      'Login now!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 15),
                    AutoSizeText(
                      "Provide your 6-digit pincode to access the dashboard. To reiterate, this pincode never leaves your device, and your secret key is encrypted on your device and is never shared anywhere else.",
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
                SignInForm(onPinEntered: _signIn),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class SignInForm extends StatefulWidget {
  final ValueChanged<String> onPinEntered;

  const SignInForm({
    required this.onPinEntered,
    super.key,
  });

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
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
              hintText: 'Enter your Pincode',
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
                  widget.onPinEntered(myPinController.text);
                }
              },
              child: const Text(
                'LOGIN',
                style: TextStyle(color: Colors.purple),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
