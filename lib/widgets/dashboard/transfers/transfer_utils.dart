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
      formFields.add(const SizedBox(height: 10));
      String fieldName = entry.key;
      bool optional = false;
      if (entry.value.optional != null && entry.value.optional!) {
        optional = true;
        fieldName += ' (optional)';
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
              : null,
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
              widget.collectedFields[entry.key] = value;
            });
          },
          validator: (String? value) {
            if (!optional && (value == null || value.isEmpty)) {
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
            if (!optional && (value == null || value.isEmpty)) {
              widget.collectedFields[entry.key] = null;
              return 'Please enter the ${entry.key}';
            }
            widget.collectedFields[entry.key] = value;
            return null;
          },
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

    formFields.add(AutoSizeText(
      'Amount',
      style: Theme.of(context).textTheme.titleSmall,
      textAlign: TextAlign.left,
    ));

    // amount is always needed
    formFields.add(TextFormField(
      decoration: InputDecoration(
        hintText: 'Enter amount',
        hintStyle: Theme.of(context).textTheme.bodyMedium,
      ),
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
    ));

    String amountDescription =
        'min. ${widget.minAmount != null ? widget.minAmount.toString() : '0'}';
    if (widget.maxAmount != null) {
      amountDescription += ', max. ${widget.maxAmount!.toString()}';
    }
    formFields.add(AutoSizeText(
      amountDescription,
      style: Theme.of(context).textTheme.bodyMedium,
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
    List<Widget> children = List<Widget>.empty(growable: true);
    children.add(const Divider(color: Colors.blue));
    if (response is Sep6Pending) {
      children.addAll(_pendingInfo(context, response as Sep6Pending));
    } else if (response is Sep6MissingKYC) {
      children.addAll(_missingKycInfo(context, response as Sep6MissingKYC));
    } else if (response is Sep6DepositSuccess) {
      children.addAll(_depositSuccess(context, response as Sep6DepositSuccess));
    } else if (response is Sep6WithdrawSuccess) {
      children
          .addAll(_withdrawSuccess(context, response as Sep6WithdrawSuccess));
    } else {
      children.add(_text(
          context,
          'We have submitted your transfer to the anchor, '
          'but the anchor returned an unknown response.'));
      children.add(const Divider(color: Colors.blue));
    }

    return Column(
      key: ObjectKey(response),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<Widget> _depositSuccess(
      BuildContext context, Sep6DepositSuccess success) {
    List<Widget> result = List<Widget>.empty(growable: true);

    result.add(_text(
        context,
        'You may not be finished yet. We have submitted your transfer to the anchor,'
        ' and any further details and/or instructions are listed below. '
        'You may need to initiate a transfer to/from your bank.'));

    result.add(const Divider(color: Colors.blue));

    if (success.id != null) {
      result.add(const SizedBox(height: 10));
      result.add(_copyRow(context, 'Transfer id', success.id!));
    }

    if (success.how != null) {
      result.add(const SizedBox(height: 10));
      result.add(_text(context, 'How: ${success.how}'));
    }

    if (success.eta != null) {
      result.add(const SizedBox(height: 10));
      result.add(_text(context, 'Eta : ${success.eta} sec.'));
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

    result.add(_text(
        context,
        'You may not be finished yet. We have submitted your transfer to the anchor,'
        ' and any further details and/or instructions are listed below. '
        'You may need to initiate a stellar payment.'));

    result.add(const Divider(color: Colors.blue));
    if (success.id != null) {
      result.add(const SizedBox(height: 10));
      result.add(_copyRow(context, 'Transfer id', success.id!));
    }

    if (success.accountId != null) {
      result.add(const SizedBox(height: 10));
      result.add(_copyRow(context, 'Send your tokens to', success.accountId!));
    }
    if (success.memo != null) {
      result.add(const SizedBox(height: 10));
      result.add(_copyRow(context, 'Memo', success.memo!));
    }
    if (success.memoType != null) {
      result.add(const SizedBox(height: 10));
      result.add(_text(context, 'Memo type : ${success.memoType}'));
    }

    if (success.eta != null) {
      result.add(const SizedBox(height: 10));
      result.add(_text(context, 'Eta : ${success.eta} sec.'));
    }

    if (success.extraInfo != null) {
      result.add(const SizedBox(height: 10));
      result.add(_text(context, 'Extra info: ${success.extraInfo!.message}'));
    }
    return result;
  }

  List<Widget> _missingKycInfo(
      BuildContext context, Sep6MissingKYC missingKyc) {
    List<Widget> result = List<Widget>.empty(growable: true);
    result.add(_text(
        context,
        'We have submitted your transfer to the anchor, but the anchor '
        'needs more KYC data from you.'));

    result.add(const Divider(color: Colors.blue));

    if (missingKyc.fields.isNotEmpty) {
      result.add(const SizedBox(height: 10));
      result.add(
          _text(context, 'Required fields: ${missingKyc.fields.join(', ')}'));
    }
    return result;
  }

  List<Widget> _pendingInfo(BuildContext context, Sep6Pending pending) {
    List<Widget> result = List<Widget>.empty(growable: true);
    result.add(_text(
        context,
        'We have submitted your transfer to the anchor,  '
        'and the anchor responded with the status: "pending".'));

    result.add(const Divider(color: Colors.blue));

    if (pending.eta != null) {
      result.add(const SizedBox(height: 10));
      result.add(_text(context, 'Eta: ${pending.eta} sec.'));
    }

    if (pending.moreInfoUrl != null) {
      result.add(_copyRow(context, 'More Info URL', pending.moreInfoUrl!));
    }

    return result;
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
