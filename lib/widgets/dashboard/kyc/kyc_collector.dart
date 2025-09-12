// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

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
      
      if (formFields.isNotEmpty) {
        formFields.add(const SizedBox(height: 16));
      }
      
      String fieldName = entry.key;
      String displayName = fieldName
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word.isNotEmpty 
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '')
          .join(' ');
      
      String? initialValue;
      if (initialValues.containsKey(entry.key)) {
        initialValue = initialValues[entry.key];
      }

      // Field label
      formFields.add(Text(
        displayName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ));
      formFields.add(const SizedBox(height: 8));

      var choices = entry.value.choices;
      if (choices != null && choices.isEmpty) {
        choices = null;
      }
      
      if (choices != null) {
        // Dropdown field
        // Set initial value in collectedFields if it exists and not already set
        if (initialValue != null && 
            choices.contains(initialValue) && 
            !widget.collectedFields.containsKey(entry.key)) {
          widget.collectedFields[entry.key] = initialValue;
        }
        
        formFields.add(DropdownButtonFormField<String>(
          key: ObjectKey(entry),
          value: widget.collectedFields.containsKey(entry.key)
              ? widget.collectedFields[entry.key]
              : (initialValue != null && choices.contains(initialValue)
                  ? initialValue
                  : null),
          decoration: InputDecoration(
            hintText: 'Select $displayName',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade600,
          ),
          items: choices.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
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
              return 'Please select $displayName';
            }
            return null;
          },
        ));
      } else {
        // Text input field
        // Set initial value in collectedFields if it exists and not already set
        if (initialValue != null && 
            initialValue.isNotEmpty &&
            !widget.collectedFields.containsKey(entry.key)) {
          widget.collectedFields[entry.key] = initialValue;
        }
        
        formFields.add(TextFormField(
          key: ObjectKey(entry),
          decoration: InputDecoration(
            hintText: 'Enter $displayName',
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? value) {
            if (value != null && value.isNotEmpty) {
              widget.collectedFields[entry.key] = value;
            } else {
              widget.collectedFields.remove(entry.key);
            }
          },
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              widget.collectedFields.remove(entry.key);
              return 'Please enter $displayName';
            }
            widget.collectedFields[entry.key] = value;
            return null;
          },
          initialValue: initialValue,
        ));
      }
      
      // Description text if available
      if (entry.value.description != null) {
        formFields.add(const SizedBox(height: 6));
        formFields.add(Text(
          entry.value.description!,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ));
      }
    }

    if (formFields.isNotEmpty) {
      formFields.add(const SizedBox(height: 20));
    }

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: formFields,
      ),
    );
  }
}
