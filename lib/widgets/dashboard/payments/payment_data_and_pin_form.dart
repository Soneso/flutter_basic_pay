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
          // Form Title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.hintText,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Amount Field
          if (widget.requestAmount)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Max: ${Util.removeTrailingZerosFormAmount(widget.maxAmount.toString())}',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
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
                        return 'Amount must be ${Util.removeTrailingZerosFormAmount(maxAmount.toString())} or less';
                      }
                      return null;
                    },
                    controller: amountTextController,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          
          // Memo Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Memo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Optional',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Add a note (max 28 characters)',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.note_alt_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(28),
                  ],
                  validator: (String? value) {
                    if (value != null) {
                      final bytes = utf8.encode(value);
                      if (bytes.length > 28) {
                        return 'Memo is too long';
                      }
                    }
                    return null;
                  },
                  controller: memoTextController,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          
          // PIN Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Security PIN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit PIN',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.password,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  obscureText: true,
                  validator: (String? value) {
                    if (value == null || value.isEmpty || value.length != 6) {
                      return 'Please enter your 6-digit PIN';
                    }
                    return null;
                  },
                  controller: pinTextController,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      widget.onCancel();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Send Payment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
