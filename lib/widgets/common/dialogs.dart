// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;

enum DialogAction { ok, cancel }

class Dialogs {
  static Future<DialogAction> confirmPinDialog(
      BuildContext context, String pinToCheck) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final pinController = TextEditingController();
    
    final action = await showDialog<DialogAction>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Confirm PIN',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1F36),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please re-enter your PIN to secure your wallet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: pinController,
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
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 2,
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF6B7280),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                    autofocus: true,
                    validator: (String? value) {
                      if (value == null || value.isEmpty || value.length != 6) {
                        return 'PIN must be exactly 6 digits';
                      } else if (value != pinToCheck) {
                        return 'PINs do not match. Please try again';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(DialogAction.cancel);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.of(context).pop(DialogAction.ok);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    return action ?? DialogAction.cancel;
  }

  static Future<wallet_sdk.IssuedAssetId?> customAssetDialog(
      BuildContext context) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final issuerController = TextEditingController();
    
    final action = await showDialog<DialogAction>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade100, Colors.blue.shade50],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.token,
                      size: 36,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add Custom Asset',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1F36),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the asset code and issuer address',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asset Code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: codeController,
                        decoration: InputDecoration(
                          hintText: 'e.g., USDC',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
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
                            borderSide: BorderSide(
                              color: Colors.blue.shade400,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.code,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                          LengthLimitingTextInputFormatter(12),
                        ],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the asset code';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Issuer Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: issuerController,
                        decoration: InputDecoration(
                          hintText: 'G...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
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
                            borderSide: BorderSide(
                              color: Colors.blue.shade400,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                          LengthLimitingTextInputFormatter(56),
                        ],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the issuer address';
                          } else if (value.length < 56) {
                            return 'Address must be 56 characters';
                          } else if (!value.startsWith('G')) {
                            return 'Address must start with G';
                          } else if (!wallet_sdk.AccountService.validateAddress(value)) {
                            return 'Invalid issuer address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(DialogAction.cancel);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade600, Colors.blue.shade500],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                Navigator.of(context).pop(DialogAction.ok);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Add Asset',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    wallet_sdk.IssuedAssetId? asset;
    if (action != null && action == DialogAction.ok) {
      var assetCode = codeController.text.toUpperCase();
      var address = issuerController.text;
      asset = wallet_sdk.IssuedAssetId(code: assetCode, issuer: address);
    }
    return asset;
  }

  static Future<ContactInfo?> addContactDialog(BuildContext context) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final action = await AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      reverseBtnOrder: false,
      buttonsBorderRadius: const BorderRadius.all(
        Radius.circular(2),
      ),
      animType: AnimType.rightSlide,
      desc: 'Add contact',
      showCloseIcon: false,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              Text(
                'Contact name',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'Please enter the contact name and Stellar address.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Contact name',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the contact name';
                  }
                  return null;
                },
                controller: nameController,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Contact Stellar address',
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  LengthLimitingTextInputFormatter(56),
                ],
                style: Theme.of(context).textTheme.bodyMedium,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the contact address';
                  } else if (value.length < 56) {
                    return 'Contact address must have 56 characters';
                  } else if (!value.startsWith('G')) {
                    return 'Contact address must start with the letter G';
                  } else if (!wallet_sdk.AccountService.validateAddress(
                      value)) {
                    return 'Invalid contact address';
                  }
                  return null;
                },
                controller: addressController,
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
      btnCancelOnPress: () {
        Navigator.of(context).pop(DialogAction.cancel);
      },
      btnOkOnPress: () {
        if (formKey.currentState!.validate()) {
          Navigator.of(context).pop(DialogAction.ok);
        }
      },
      autoDismiss: false,
      onDismissCallback: (type) {},
      barrierColor: Colors.purple[900]?.withOpacity(0.54),
    ).show();
    ContactInfo? contact;
    if (action != null && action == DialogAction.ok) {
      var name = nameController.text;
      var address = addressController.text;
      contact = ContactInfo(name, address);
    }
    return contact;
  }

  static Future<String?> insertAddressDialog(BuildContext context) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final addressController = TextEditingController();
    final action = await AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      reverseBtnOrder: false,
      buttonsBorderRadius: const BorderRadius.all(
        Radius.circular(2),
      ),
      animType: AnimType.rightSlide,
      desc: 'Record a Stellar address',
      showCloseIcon: false,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              Text(
                'Address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'Please enter the address',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'G...',
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  LengthLimitingTextInputFormatter(56),
                ],
                style: Theme.of(context).textTheme.bodyMedium,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the address';
                  } else if (value.length < 56) {
                    return 'Address must have 56 characters';
                  } else if (!value.startsWith('G')) {
                    return 'Address must start with the letter G';
                  } else if (!wallet_sdk.AccountService.validateAddress(
                      value)) {
                    return 'Invalid address';
                  }
                  return null;
                },
                controller: addressController,
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
      btnCancelOnPress: () {
        Navigator.of(context).pop(DialogAction.cancel);
      },
      btnOkOnPress: () {
        if (formKey.currentState!.validate()) {
          Navigator.of(context).pop(DialogAction.ok);
        }
      },
      autoDismiss: false,
      onDismissCallback: (type) {},
      barrierColor: Colors.purple[900]?.withOpacity(0.54),
    ).show();

    if (action != null && action == DialogAction.ok) {
      return addressController.text;
    }
    return null;
  }

  static Future<String?> editValueDialog(
      String key, String value, BuildContext context) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final valueController = TextEditingController();
    final action = await AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      reverseBtnOrder: false,
      buttonsBorderRadius: const BorderRadius.all(
        Radius.circular(2),
      ),
      animType: AnimType.rightSlide,
      desc: 'Edit value',
      showCloseIcon: false,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              Text(
                key,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                value.isNotEmpty
                    ? "Your current $key is '$value'. Please enter your new $key:"
                    : "Your current $key is not set. Please enter your $key:",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: '',
                ),
                textCapitalization: TextCapitalization.characters,
                style: Theme.of(context).textTheme.bodyMedium,
                validator: (String? value) {
                  return null;
                },
                controller: valueController,
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
      btnCancelOnPress: () {
        Navigator.of(context).pop(DialogAction.cancel);
      },
      btnOkOnPress: () {
        if (formKey.currentState!.validate()) {
          Navigator.of(context).pop(DialogAction.ok);
        }
      },
      autoDismiss: false,
      onDismissCallback: (type) {},
      barrierColor: Colors.purple[900]?.withOpacity(0.54),
    ).show();

    if (action != null && action == DialogAction.ok) {
      return valueController.text;
    }
    return null;
  }
}
