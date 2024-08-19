// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/kyc/kyc_collector.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/transfer_utils.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';
import 'package:flutter/foundation.dart';

class Sep6DepositStepper extends StatefulWidget {
  final AnchoredAssetInfo asset;
  final Sep6DepositInfo depositInfo;
  final Sep6EndpointInfo? feeEndpointInfo;

  final AuthToken authToken;

  const Sep6DepositStepper({
    required this.asset,
    required this.depositInfo,
    required this.authToken,
    this.feeEndpointInfo,
    super.key,
  });

  @override
  State<Sep6DepositStepper> createState() => _Sep6DepositStepperState();
}

class _Sep6DepositStepperState extends State<Sep6DepositStepper> {
  int _currentStep = 0;
  TransferDetailsForm? _sep6TransferFieldsForm;
  double? _amount;
  KycCollectorForm? _sep12KycCollectorForm;
  bool _kycDataLoaded = false;
  GetCustomerResponse? _sep12Info;
  Map<String, String> _storedKycData = {};
  bool _feeDetermined = false;
  double? _fee;
  bool _isSubmittingTransfer = false;
  Sep6TransferResponse? _submissionResult;
  String? _submissionError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEP-06 Deposit'),
      ),
      body: Stepper(
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Container(
              margin: const EdgeInsets.only(top: 50),
              child: buttonsForStep(_currentStep, details));
        },
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () async {
          await onStepContinue();
        },
        onStepCancel: () async {
          await onStepBack();
        },
        steps: <Step>[
          Step(
            title: const Text('Transfer details'),
            content: getTransferDetailsColumn(context),
            isActive: _currentStep >= 0,
            state: _currentStep >= 0 ? StepState.complete : StepState.disabled,
          ),
          Step(
            title: const Text('KYC Data'),
            content: getKycColumn(context),
            isActive: _currentStep >= 0,
            state: _currentStep >= 1 ? StepState.complete : StepState.disabled,
          ),
          Step(
            title: const Text('Fee'),
            content: getFeeColumn(context),
            isActive: _currentStep >= 0,
            state: _currentStep >= 2 ? StepState.complete : StepState.disabled,
          ),
          Step(
            title: const Text('Summary'),
            content: getSendColumn(context),
            isActive: _currentStep >= 0,
            state: _currentStep >= 3 ? StepState.complete : StepState.disabled,
          ),
        ],
      ),
    );
  }

  Row buttonsForStep(int step, ControlsDetails details) {
    var nextButton = ElevatedButton(
        onPressed: details.onStepContinue, child: const Text('Next'));
    var backButton = ElevatedButton(
        onPressed: details.onStepCancel, child: const Text('Back'));
    var spacer = const SizedBox(width: 10);

    if (step == 0) {
      // transfer details
      return Row(children: [nextButton]);
    }
    if ((step == 1 && _kycDataLoaded) || (step == 2 && _feeDetermined)) {
      // kyc or fee
      return Row(children: [backButton, spacer, nextButton]);
    } else if (step == 3 && !_isSubmittingTransfer) {
      // summary
      if (_submissionResult == null && _submissionError == null) {
        // not submitted yet
        var submitButton = ElevatedButton(
            onPressed: onSubmitTransfer, child: const Text('Submit'));
        return Row(children: [backButton, spacer, submitButton]);
      } else {
        // showing submission result
        var closeButton = ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'));
        return Row(children: [closeButton]);
      }
    }
    return const Row(children: []);
  }

  Future<void> onStepContinue() async {
    if (_currentStep >= 3) {
      // out of range
      return;
    }

    if (_currentStep == 0) {
      // Step: Transfer details
      var detailsForm = getTransferDetailsForm();
      if (!detailsForm.validateAndCollect()) {
        // not completely filled.
        return;
      }

      // extract amount
      if (detailsForm.collectedFields
          .containsKey(TransferDetailsForm.transferAmountKey)) {
        _amount = double.tryParse(detailsForm
                .collectedFields[TransferDetailsForm.transferAmountKey] ??
            "");
      }

      // load kyc data to be shown in the kyc step.
      setState(() {
        _currentStep += 1;
        _kycDataLoaded = false;
      });
      await loadKycData();
      setState(() {
        _kycDataLoaded = true;
      });
    } else if (_currentStep == 1) {
      // Step: KYC
      var kycForm = getKycCollectorForm();
      if (kycForm.containsNonOptionalSep12Fields()) {
        if (!kycForm.validateAndCollect()) {
          // not completely filled
          return;
        }
        // send the kyc data to the anchor and reload
        setState(() {
          _kycDataLoaded = false;
        });
        await sendAndReloadKycData();
        setState(() {
          _kycDataLoaded = true;
        });
        return;
      }

      // load the fee to be shown in the Fee step
      setState(() {
        _currentStep += 1;
        _feeDetermined = false;
      });
      // load data
      var detailsForm = getTransferDetailsForm();
      await loadFee(detailsForm.collectedFields);
      setState(() {
        _feeDetermined = true;
      });
    } else if (_currentStep == 2) {
      // Step: Fee
      setState(() {
        _currentStep += 1;
      });
    }
  }

  Future<void> onStepBack() async {
    if (_currentStep <= 0) {
      // out of range
      return;
    }
    if (_currentStep == 2) {
      // Step: Fee
      setState(() {
        _currentStep -= 1;
        _kycDataLoaded = false;
      });
      // load kyc data in preparation for the KYC step.
      await loadKycData();
      setState(() {
        _kycDataLoaded = true;
      });
    } else {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  TransferDetailsForm getTransferDetailsForm() {
    if (_sep6TransferFieldsForm == null) {
      Map<String, Sep6FieldInfo> fieldsInfo = {...getTransferFields()};
      _sep6TransferFieldsForm = TransferDetailsForm(
          sep6FieldInfo: fieldsInfo,
          minAmount: widget.depositInfo.minAmount,
          maxAmount: widget.depositInfo.maxAmount,
          key: ObjectKey(widget.depositInfo));
    }
    return _sep6TransferFieldsForm!;
  }

  KycCollectorForm getKycCollectorForm() {
    _sep12KycCollectorForm ??= KycCollectorForm(
        sep12Fields: _sep12Info?.fields ?? {},
        initialValues: _storedKycData,
        key: ObjectKey([_sep12Info?.fields ?? {}, _storedKycData]));
    return _sep12KycCollectorForm!;
  }

  Future<void> onSubmitTransfer() async {
    setState(() {
      _isSubmittingTransfer = true;
    });
    try {
      var destinationAsset = widget.asset.asset;
      var sep06 = widget.asset.anchor.sep6();
      Map<String, String> extraFields = {};
      var transferDetailsForm = getTransferDetailsForm();
      for (var entry in transferDetailsForm.collectedFields.entries) {
        if (entry.key != TransferDetailsForm.transferAmountKey &&
            entry.value != null) {
          extraFields[entry.key] = entry.value!;
        }
      }
      var sep6DepositParams = Sep6DepositParams(
          assetCode: destinationAsset.code,
          account: widget.authToken.account,
          amount: _amount!.toString(),
          extraFields: extraFields);

      _submissionResult =
          await sep06.deposit(sep6DepositParams, widget.authToken);
    } catch (e) {
      _submissionError = 'Your request has been submitted to the Anchor '
          'but following error occurred: ${e.toString()}. Please close this '
          'window and try again.';
    }

    setState(() {
      _isSubmittingTransfer = false;
    });
  }

  String getAssetCode() {
    return widget.asset.asset.code;
  }

  Map<String, Sep6FieldInfo> getTransferFields() {
    return widget.depositInfo.fieldsInfo ?? {};
  }

  Column getTransferDetailsColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        text(context, 'Asset: ${getAssetCode()}'),
        const SizedBox(height: 10),
        AutoSizeText(
          'Transfer fields',
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 10),
        text(context,
            'The anchor requested following information about your transfer:'),
        getTransferDetailsForm(),
      ],
    );
  }

  Future<void> loadKycData() async {
    try {
      var sep12 = await widget.asset.anchor.sep12(widget.authToken);
      _sep12Info = await sep12.getByAuthTokenOnly();
    } catch (e) {
      if (kDebugMode) {
        print('error loading SEP-12 info: ${e.toString()}');
      }
    }

    try {
      _storedKycData = await SecureStorage.getKycData();
    } catch (e) {
      if (kDebugMode) {
        print('error loading stored kyc data: ${e.toString()}');
      }
    }

    // clear the form after loading the new data
    _sep12KycCollectorForm = null;
  }

  Future<void> sendAndReloadKycData() async {
    try {
      var sep12 = await widget.asset.anchor.sep12(widget.authToken);
      var customerId = _sep12Info?.id;
      var kycForm = getKycCollectorForm();
      if (customerId == null) {
        await sep12.add(kycForm.collectedFields);
      } else {
        await sep12.update(kycForm.collectedFields, customerId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('error sending SEP-12 data: ${e.toString()}');
      }
    }
    await Future.delayed(const Duration(seconds: 5));
    await loadKycData();
  }

  Future<void> deleteAnchorKycData() async {
    setState(() {
      _kycDataLoaded = false;
    });
    try {
      var sep12 = await widget.asset.anchor.sep12(widget.authToken);
      sep12.delete(widget.authToken.account);
    } catch (e) {
      if (kDebugMode) {
        print('error deleting SEP-12 data: ${e.toString()}');
      }
    }
    await Future.delayed(const Duration(seconds: 5));
    await loadKycData();
    setState(() {
      _kycDataLoaded = true;
    });
  }

  Future<void> loadFee(Map<String, String?> transferDetails) async {
    double? feeFixed = widget.depositInfo.feeFixed;
    double? feePercent = widget.depositInfo.feePercent;
    Sep6EndpointInfo? feeEndpointInfo = widget.feeEndpointInfo;

    if (feeFixed != null) {
      _fee = feeFixed;
      return;
    }

    if (feePercent != null && _amount != null) {
      _fee = _amount! * feePercent / 100;
      return;
    }

    if (feeEndpointInfo != null && _amount != null) {
      String? type;
      if (transferDetails.containsKey('type')) {
        type = transferDetails['type'];
      }
      try {
        _fee = await widget.asset.anchor.sep6().fee(
              operation: 'deposit',
              assetCode: getAssetCode(),
              type: type,
              amount: _amount!,
              authToken: widget.authToken,
            );
      } catch (e) {
        _fee = null;
      }
    }
  }

  Column getKycColumn(BuildContext context) {
    if (!_kycDataLoaded) {
      return Util.getLoadingColumn(context, 'Loading ...', showDivider: false);
    } else if (_sep12Info == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(children: []),
          text(context, 'Could not load KYC data from Anchor.'),
        ],
      );
    }

    var sep12Info = _sep12Info!;
    var status = sep12Info.sep12Status;
    if (status == Sep12Status.accepted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(children: []),
          text(context, 'Your KYC data has been accepted by the anchor.'),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: deleteAnchorKycData, child: const Text('Delete')),
        ],
      );
    } else if (status == Sep12Status.processing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(children: []),
          text(context,
              'Your KYC data is currently being processed by the anchor.'),
        ],
      );
    } else if (status == Sep12Status.rejected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(children: []),
          text(context, 'Your KYC data has been rejected by the anchor.'),
        ],
      );
    } else if (status == Sep12Status.needsInfo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(children: []),
          text(context, 'The Anchor needs following of your KYC data:'),
          getKycCollectorForm(),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(children: []),
          text(context, 'Your KYC data status is unknown.'),
        ],
      );
    }
  }

  Column getFeeColumn(BuildContext context) {
    if (_feeDetermined) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(children: []),
          if (_fee != null)
            text(context,
                'The Anchor will charge a fee of: $_fee ${getAssetCode()}'),
          if (_fee == null)
            AutoSizeText(
              'The Anchor provides no fee info for the Asset ${getAssetCode()}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.left,
            ),
        ],
      );
    } else {
      return Util.getLoadingColumn(context, 'Loading ...', showDivider: false);
    }
  }

  Column getSendColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(children: []),
        text(context, 'Deposit: $_amount ${getAssetCode()}'),
        const SizedBox(height: 10),
        if (_fee != null) text(context, 'Fee: $_fee ${getAssetCode()}'),
        const SizedBox(height: 10),
        if (_isSubmittingTransfer)
          Util.getLoadingColumn(context, "Submitting ..."),
        if (_submissionResult != null)
          Sep6TransferResponseView(
            response: _submissionResult!,
            key: ObjectKey(_submissionResult!),
          ),
        if (_submissionError != null) text(context, _submissionError!),
      ],
    );
  }

  AutoSizeText text(BuildContext context, String content) {
    return AutoSizeText(
      content,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.left,
    );
  }
}