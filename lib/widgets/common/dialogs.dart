// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/storage/storage.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;

enum DialogAction { ok, cancel }

class Dialogs {
  static Future<DialogAction> confirmPinDialog(
      BuildContext context, String pinToCheck) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final action = await AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      reverseBtnOrder: true,
      buttonsBorderRadius: const BorderRadius.all(
        Radius.circular(2),
      ),
      animType: AnimType.rightSlide,
      desc: 'Please re-type your 6-digit pin code to encrypt the secret key.',
      showCloseIcon: false,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              Text(
                'Confirm Pin code',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'Please re-type your 6-digit pin code to encrypt the secret key.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: 10,
              ),
              Material(
                elevation: 0,
                color: Colors.blueGrey.withAlpha(40),
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Confirm pin code',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  obscureText: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                  validator: (String? value) {
                    if (value == null || value.isEmpty || value.length != 6) {
                      return 'Please enter 6 digits';
                    } else if (value != pinToCheck) {
                      return 'Mismatch, try again';
                    }
                    return null;
                  },
                ),
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
    return (action != null) ? action : DialogAction.cancel;
  }

  static Future<wallet_sdk.IssuedAssetId?> customAssetDialog(
      BuildContext context) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final issuerController = TextEditingController();
    final action = await AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      reverseBtnOrder: false,
      buttonsBorderRadius: const BorderRadius.all(
        Radius.circular(2),
      ),
      animType: AnimType.rightSlide,
      desc: 'Record custom asset',
      showCloseIcon: false,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              Text(
                'Custom Asset',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'Please enter the asset code and asset issuer.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Asset code',
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  LengthLimitingTextInputFormatter(12),
                ],
                style: Theme.of(context).textTheme.bodyMedium,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the asset code';
                  }
                  return null;
                },
                controller: codeController,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Asset issuer',
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                  LengthLimitingTextInputFormatter(56),
                ],
                style: Theme.of(context).textTheme.bodyMedium,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the asset issuer address';
                  } else if (value.length < 56) {
                    return 'Asset issuer address must have 56 characters';
                  } else if (!value.startsWith('G')) {
                    return 'Issuer address must start with the letter G';
                  } else if (!wallet_sdk.AccountService.validateAddress(
                      value)) {
                    return 'Invalid issuer address';
                  }
                  return null;
                },
                controller: issuerController,
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
    wallet_sdk.IssuedAssetId? asset;
    if (action != null && action == DialogAction.ok) {
      var assetCode = codeController.text;
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
      desc: 'Record custom asset',
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
}
