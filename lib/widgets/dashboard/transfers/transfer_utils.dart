// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TransferDetailsForm extends StatefulWidget {
  static const transferAmountKey = 'transfer_amount';
  final Map<String, Sep6FieldInfo> sep6FieldInfo;
  final double? minAmount;
  final double? maxAmount;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<String, String?> collectedFields = {};

  TransferDetailsForm({
    required this.sep6FieldInfo,
    this.minAmount,
    this.maxAmount,
    super.key,
  });

  bool validateAndCollect() {
    if (formKey.currentState != null) {
      return formKey.currentState!.validate();
    }
    return true;
  }

  @override
  State<TransferDetailsForm> createState() => _TransferDetailsFormState();
}

class _TransferDetailsFormState extends State<TransferDetailsForm> {
  @override
  Widget build(BuildContext context) {
    return getTransferFieldsForm();
  }

  Form getTransferFieldsForm() {
    List<Widget> formFields = [];
    for (var entry in widget.sep6FieldInfo.entries) {
      formFields.add(const SizedBox(height: 16));
      String fieldName = entry.key;
      bool optional = false;
      if (entry.value.optional != null && entry.value.optional!
          && fieldName != "type") { // patch: the test anchor returns optional for the field "type", but it is required.
        optional = true;
        fieldName += ' (optional)';
      }

      formFields.add(Text(
        fieldName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ));

      formFields.add(const SizedBox(height: 8));

      var choices = entry.value.choices;
      if (choices != null && choices.isEmpty) {
        choices = null;
      }
      if (choices != null) {
        formFields.add(Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonFormField<String>(
            key: ObjectKey(entry),
            value: widget.collectedFields.containsKey(entry.key)
                ? widget.collectedFields[entry.key]
                : null,
            hint: Text(
              'Select one',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: choices.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                widget.collectedFields[entry.key] = value;
              });
            },
            validator: (String? value) {
              if (!optional && (value == null || value.isEmpty)) {
                return 'Please select an option';
              }
              return null;
            },
          ),
        ));
      } else {
        formFields.add(Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            key: ObjectKey(entry),
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (String? value) {
              if (!optional && (value == null || value.isEmpty)) {
                widget.collectedFields[entry.key] = null;
                return 'Please enter the ${entry.key}';
              }
              widget.collectedFields[entry.key] = value;
              return null;
            },
          ),
        ));
      }
      if (entry.value.description != null) {
        formFields.add(const SizedBox(height: 4));
        formFields.add(Text(
          entry.value.description!,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ));
      }
    }

    formFields.add(const SizedBox(height: 20));

    formFields.add(Text(
      'Amount',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    ));

    formFields.add(const SizedBox(height: 8));

    // amount is always needed
    formFields.add(Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: 'Enter amount',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: Icon(
            Icons.attach_money,
            color: Colors.grey[500],
            size: 20,
          ),
        ),
        style: const TextStyle(fontSize: 16),
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'(^\d*\.?\d*)')),
        ],
        validator: (String? value) {
          widget.collectedFields[TransferDetailsForm.transferAmountKey] = null;
          if (value == null || value.isEmpty) {
            return 'Please enter an amount';
          }
          double? amount = double.tryParse(value);
          if (amount == null) {
            return 'Invalid amount';
          }
          var maxAmount = widget.maxAmount;
          if (maxAmount != null && amount > maxAmount) {
            return 'Amount must be lower or equal ${maxAmount.toString()}';
          }
          var minAmount = widget.minAmount ?? 0;
          if (amount < minAmount) {
            return 'Amount must be higher or equal ${minAmount.toString()}';
          }
          widget.collectedFields[TransferDetailsForm.transferAmountKey] =
              amount.toString();
          return null;
        },
      ),
    ));

    String amountDescription =
        'min. ${widget.minAmount != null ? widget.minAmount.toString() : '0'}';
    if (widget.maxAmount != null) {
      amountDescription += ', max. ${widget.maxAmount!.toString()}';
    }
    formFields.add(const SizedBox(height: 4));
    formFields.add(Text(
      amountDescription,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    ));

    return Form(
      key: widget.formKey,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: formFields),
    );
  }
}

class Sep6TransferResponseView extends StatelessWidget {
  final Sep6TransferResponse response;

  const Sep6TransferResponseView({required this.response, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            key: ObjectKey(response),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildResponseContent(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResponseContent(BuildContext context) {
    if (response is Sep6Pending) {
      return _pendingInfo(context, response as Sep6Pending);
    } else if (response is Sep6MissingKYC) {
      return _missingKycInfo(context, response as Sep6MissingKYC);
    } else if (response is Sep6DepositSuccess) {
      return _depositSuccess(context, response as Sep6DepositSuccess);
    } else if (response is Sep6WithdrawSuccess) {
      return _withdrawSuccess(context, response as Sep6WithdrawSuccess);
    } else {
      return [
        Row(
          children: [
            Icon(
              Icons.help_outline,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unknown Response',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'We have submitted your transfer to the anchor, but the anchor returned an unknown response.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ];
    }
  }

  List<Widget> _depositSuccess(
      BuildContext context, Sep6DepositSuccess success) {
    List<Widget> result = List<Widget>.empty(growable: true);

    // Header
    result.add(Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF10B981),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Deposit Submitted',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ),
      ],
    ));

    result.add(const SizedBox(height: 12));
    result.add(Text(
      'Your deposit request has been submitted to the anchor. Follow any additional instructions below to complete the transfer.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    ));

    result.add(const SizedBox(height: 16));

    if (success.id != null) {
      result.add(_infoCard(context, 'Transfer ID', success.id!, copyable: true));
      result.add(const SizedBox(height: 12));
    }

    if (success.how != null) {
      result.add(_infoCard(context, 'Instructions', success.how!));
      result.add(const SizedBox(height: 12));
    }

    if (success.eta != null) {
      result.add(_infoCard(context, 'Estimated Time', '${success.eta} seconds'));
      result.add(const SizedBox(height: 12));
    }

    if (success.instructions != null && success.instructions!.isNotEmpty) {
      result.add(const SizedBox(height: 10));
      for (var entry in success.instructions!.entries) {
        result.add(const Divider(color: Colors.blue));
        result.add(_text(context, '${entry.key} Instructions'));
        result.add(const SizedBox(height: 5));
        var value = entry.value;
        result.add(_text(context, 'Value: ${value.value}'));
        result.add(const SizedBox(height: 5));
        result.add(_text(context, 'Desc.: ${value.description}'));
      }
      result.add(const Divider(color: Colors.blue));
    }

    if (success.extraInfo != null) {
      result.add(const SizedBox(height: 10));
      result.add(_text(context, 'Extra info: ${success.extraInfo!.message}'));
    }
    return result;
  }

  List<Widget> _withdrawSuccess(
      BuildContext context, Sep6WithdrawSuccess success) {
    List<Widget> result = List<Widget>.empty(growable: true);

    // Header
    result.add(Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.arrow_upward,
            color: Color(0xFFEF4444),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Withdrawal Submitted',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
      ],
    ));

    result.add(const SizedBox(height: 12));
    result.add(Text(
      'Your withdrawal request has been submitted. You may need to send a Stellar payment to complete the transfer.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    ));

    result.add(const SizedBox(height: 16));

    if (success.id != null) {
      result.add(_infoCard(context, 'Transfer ID', success.id!, copyable: true));
      result.add(const SizedBox(height: 12));
    }

    if (success.accountId != null) {
      result.add(_infoCard(context, 'Send Tokens To', success.accountId!, copyable: true));
      result.add(const SizedBox(height: 12));
    }
    if (success.memo != null) {
      result.add(_infoCard(context, 'Memo', success.memo!, copyable: true));
      result.add(const SizedBox(height: 12));
    }
    if (success.memoType != null) {
      result.add(_infoCard(context, 'Memo Type', success.memoType!));
      result.add(const SizedBox(height: 12));
    }

    if (success.eta != null) {
      result.add(_infoCard(context, 'Estimated Time', '${success.eta} seconds'));
      result.add(const SizedBox(height: 12));
    }

    if (success.extraInfo != null && success.extraInfo!.message != null) {
      result.add(_infoCard(context, 'Extra Information', success.extraInfo!.message!));
      result.add(const SizedBox(height: 12));
    }
    return result;
  }

  List<Widget> _missingKycInfo(
      BuildContext context, Sep6MissingKYC missingKyc) {
    List<Widget> result = List<Widget>.empty(growable: true);
    
    // Header
    result.add(Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.info_outline,
            color: Color(0xFFF59E0B),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Additional KYC Required',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF59E0B),
            ),
          ),
        ),
      ],
    ));

    result.add(const SizedBox(height: 12));
    result.add(Text(
      'Your transfer has been submitted, but the anchor needs additional KYC information from you.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    ));

    if (missingKyc.fields.isNotEmpty) {
      result.add(const SizedBox(height: 16));
      result.add(_infoCard(context, 'Required Fields', missingKyc.fields.join(', ')));
    }
    return result;
  }

  List<Widget> _pendingInfo(BuildContext context, Sep6Pending pending) {
    List<Widget> result = List<Widget>.empty(growable: true);
    
    // Header
    result.add(Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.schedule,
            color: Color(0xFF3B82F6),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Transfer Pending',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
      ],
    ));

    result.add(const SizedBox(height: 12));
    result.add(Text(
      'Your transfer has been submitted and is currently pending with the anchor.',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    ));

    result.add(const SizedBox(height: 16));

    if (pending.eta != null) {
      result.add(_infoCard(context, 'Estimated Time', '${pending.eta} seconds'));
      result.add(const SizedBox(height: 12));
    }

    if (pending.moreInfoUrl != null) {
      result.add(_infoCard(context, 'More Info URL', pending.moreInfoUrl!, copyable: true));
    }

    return result;
  }

  Widget _infoCard(BuildContext context, String title, String value, {bool copyable = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (copyable)
                IconButton(
                  icon: Icon(
                    Icons.copy_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  onPressed: () => _copyToClipboard(value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Row _copyRow(BuildContext context, String title, String value) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: _text(context, '$title: $value'),
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined, size: 20),
          onPressed: () => _copyToClipboard(value),
        ),
      ],
    );
  }

  AutoSizeText _text(BuildContext context, String content) {
    return AutoSizeText(
      content,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.left,
    );
  }

  void _copyToClipboard(String text) async {
    await FlutterClipboard.copy(text);
    _showCopied();
  }

  void _showCopied() {
    ScaffoldMessenger.of(NavigationService.navigatorKey.currentContext!)
        .showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class WebViewContainer extends StatefulWidget {
  final WebViewController controller;
  final String title;

  const WebViewContainer({
    required this.title,
    required this.controller,
    super.key,
  });

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title),
      ),
      body: WebViewWidget(
        controller: widget.controller,
        gestureRecognizers: gestureRecognizers,
      ),
    );
  }
}
