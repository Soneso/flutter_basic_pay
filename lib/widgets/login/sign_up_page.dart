// Copyright 2024 The Stellar Wallet Flutter SDK Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

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
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SignUpCard(authService: authService, onSuccess: onSuccess),
        ),
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
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1F36),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Set up your secure Stellar wallet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  'Your Stellar Address',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText(
                        _userKeyPair.address,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: const Color(0xFF374151),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () => _copyToClipboard(_userKeyPair.address),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          icon: const Icon(
                            Icons.copy,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          label: const Text(
                            'Copy Address',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _generateNewUserKeyPair,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Generate New Address'),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _showSecretKey = !_showSecretKey;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              _showSecretKey ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _showSecretKey ? 'Hide Secret Key' : 'Show Secret Key',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF92400E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: _showSecretKey,
                              onChanged: (bool? value) {
                                setState(() {
                                  _showSecretKey = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showSecretKey) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Secret Key',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SelectableText(
                          _userKeyPair.secretKey,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: const Color(0xFF991B1B),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 20,
                                color: Color(0xFF991B1B),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Keep this secret key safe! Anyone with access to it can control your funds.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF991B1B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: () => _copyToClipboard(_userKeyPair.secretKey),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              backgroundColor: Colors.white,
                            ),
                            icon: const Icon(
                              Icons.copy,
                              size: 16,
                              color: Color(0xFF991B1B),
                            ),
                            label: const Text(
                              'Copy Secret Key',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Create PIN',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: '••••••',
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 18,
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            obscureText: true,
            style: const TextStyle(
              fontSize: 18,
              letterSpacing: 8,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            validator: (String? value) {
              if (value == null || value.isEmpty || value.length != 6) {
                return 'PIN must be exactly 6 digits';
              }
              return null;
            },
            controller: myPinController,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                var action = await Dialogs.confirmPinDialog(
                    context, myPinController.text);
                if (action == DialogAction.ok) {
                  widget.onPinSet(myPinController.text);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
