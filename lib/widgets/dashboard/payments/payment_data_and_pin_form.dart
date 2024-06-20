// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';

class PaymentDataAndPinForm extends StatefulWidget {
  final ValueChanged<PaymentDataAndPin> onDataSet;
  final VoidCallback onCancel;
  final String hintText;
  final bool requestAmount;
  final double? maxAmount;

  const PaymentDataAndPinForm({
    required this.onDataSet,
    required this.onCancel,
    this.requestAmount = false,
    this.maxAmount,
    this.hintText = "Enter data and pin",
    super.key,
  });

  @override
  State<PaymentDataAndPinForm> createState() => _PaymentDataAndPinFormState();
}

class _PaymentDataAndPinFormState extends State<PaymentDataAndPinForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final pinTextController = TextEditingController();
  final amountTextController = TextEditingController();
  final memoTextController = TextEditingController();

  @override
  void dispose() {
    pinTextController.dispose();
    amountTextController.dispose();
    memoTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.requestAmount)
            TextFormField(
              decoration: InputDecoration(
                hintText:
                    'Enter amount (max. ${Util.removeTrailingZerosFormAmount(widget.maxAmount.toString())})',
                hintStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)')),
              ],
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                double? amount = double.tryParse(value);
                if (amount == null) {
                  return 'Invalid amount';
                }
                var maxAmount = widget.maxAmount;
                if (maxAmount != null && amount > maxAmount) {
                  return 'Amount must be lower or equal ${Util.removeTrailingZerosFormAmount(maxAmount.toString())}';
                }
                return null;
              },
              controller: amountTextController,
            ),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Enter text memo (optional)',
              hintStyle: Theme.of(context).textTheme.bodyMedium,
            ),
            keyboardType: TextInputType.text,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(28),
            ],
            validator: (String? value) {
              if (value != null) {
                final bytes = utf8.encode(value);
                if (bytes.length > 28) {
                  return 'Memo is to long';
                }
              }
              return null;
            },
            controller: memoTextController,
          ),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Enter your pin',
              hintStyle: Theme.of(context).textTheme.bodyMedium,
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
            controller: pinTextController,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    // Validate will return true if the form is valid, or false if
                    // the form is invalid.
                    if (_formKey.currentState!.validate()) {
                      String? amount = widget.requestAmount
                          ? amountTextController.text
                          : null;
                      String pin = pinTextController.text;
                      String? memo = memoTextController.text == ''
                          ? null
                          : memoTextController.text;
                      widget.onDataSet(PaymentDataAndPin(
                          amount: amount, pin: pin, memo: memo));
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    widget.onCancel();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentDataAndPin {
  String? amount;
  String pin;
  String? memo;

  PaymentDataAndPin({required this.amount, required this.pin, this.memo});
}
