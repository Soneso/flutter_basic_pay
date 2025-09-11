// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';

class KycCollectorForm extends StatefulWidget {
  final Map<String, Field> sep12Fields;
  final Map<String, String> initialValues;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, String> collectedFields = {};

  KycCollectorForm({
    required this.sep12Fields,
    required this.initialValues,
    super.key,
  });

  bool validateAndCollect() {
    if (formKey.currentState != null) {
      return formKey.currentState!.validate();
    }
    return true;
  }

  bool containsNonOptionalSep12Fields() {
    for (var entry in sep12Fields.entries) {
      bool optional = entry.value.optional ?? false;
      if (!optional) {
        return true;
      }
    }
    return false;
  }

  @override
  State<KycCollectorForm> createState() => _KycCollectorFormState();
}

class _KycCollectorFormState extends State<KycCollectorForm> {
  @override
  Widget build(BuildContext context) {
    return getKycFieldsForm();
  }

  Form getKycFieldsForm() {
    var initialValues = widget.initialValues;
    List<Widget> formFields = [];
    for (var entry in widget.sep12Fields.entries) {
      if (entry.value.type == FieldType.binary) {
        // TODO...
        continue;
      }
      
      // Skip optional fields - only show required fields
      bool optional = entry.value.optional ?? false;
      if (optional) {
        continue;
      }
      
      formFields.add(const SizedBox(height: 10));
      String fieldName = entry.key;
      String? initialValue;
      if (initialValues.containsKey(entry.key)) {
        initialValue = initialValues[entry.key];
      }

      formFields.add(AutoSizeText(
        fieldName,
        style: Theme.of(context).textTheme.titleSmall,
        textAlign: TextAlign.left,
      ));

      var choices = entry.value.choices;
      if (choices != null && choices.isEmpty) {
        choices = null;
      }
      if (choices != null) {
        formFields.add(DropdownButtonFormField(
          key: ObjectKey(entry),
          value: widget.collectedFields.containsKey(entry.key)
              ? widget.collectedFields[entry.key]
              : (initialValue != null && choices.contains(initialValue)
                  ? initialValue
                  : null),
          hint: Text(
            'Select one',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          items: choices.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              if (value != null) {
                widget.collectedFields[entry.key] = value;
              } else {
                widget.collectedFields.remove(entry.key);
              }
            });
          },
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return 'Please select an option';
            }
            return null;
          },
        ));
      } else {
        formFields.add(TextFormField(
          key: ObjectKey(entry),
          style: Theme.of(context).textTheme.bodyMedium,
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              widget.collectedFields.remove(entry.key);
              return 'Please enter the ${entry.key}';
            }
            widget.collectedFields[entry.key] = value;
            return null;
          },
          initialValue: initialValue,
        ));
      }
      if (entry.value.description != null) {
        formFields.add(AutoSizeText(
          entry.value.description!,
          style: Theme.of(context).textTheme.bodyMedium,
        ));
      }
    }

    formFields.add(const SizedBox(height: 10));

    return Form(
      key: widget.formKey,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: formFields),
    );
  }
}
