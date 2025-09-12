// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/dashboard/kyc/kyc_collector.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/transfer_utils.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';
import 'package:flutter/foundation.dart';

class Sep6DepositStepper extends StatefulWidget {
  final AnchoredAssetInfo anchoredAsset;
  final Sep6DepositInfo depositInfo;
  final bool anchorHasEnabledFeeEndpoint;
  final AuthToken authToken;

  const Sep6DepositStepper({
    required this.anchoredAsset,
    required this.depositInfo,
    required this.anchorHasEnabledFeeEndpoint,
    required this.authToken,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'SEP-06 Deposit',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Container(
        color: Colors.grey[50],
        child: Stepper(
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return Container(
              margin: const EdgeInsets.only(top: 24),
              child: buttonsForStep(_currentStep, details),
            );
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
      ),
    );
  }

  Widget buttonsForStep(int step, ControlsDetails details) {
    Widget nextButton = SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: details.onStepContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Next',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    Widget backButton = SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: details.onStepCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Back',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    var spacer = const SizedBox(width: 12);

    if (step == 0) {
      // transfer details
      return Row(children: [Expanded(child: nextButton)]);
    }
    if ((step == 1 && _kycDataLoaded) || (step == 2 && _feeDetermined)) {
      // kyc or fee
      return Row(children: [Expanded(child: backButton), spacer, Expanded(child: nextButton)]);
    } else if (step == 3 && !_isSubmittingTransfer) {
      // summary
      if (_submissionResult == null && _submissionError == null) {
        // not submitted yet
        Widget submitButton = SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onSubmitTransfer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Submit Transfer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        return Row(children: [Expanded(child: backButton), spacer, Expanded(child: submitButton)]);
      } else {
        // showing submission result
        Widget closeButton = SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        return Row(children: [Expanded(child: closeButton)]);
      }
    }
    return const SizedBox.shrink();
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
    var anchoredAsset = widget.anchoredAsset;
    var authToken = widget.authToken;

    try {
      var destinationAsset = anchoredAsset.asset;
      var sep06 = anchoredAsset.anchor.sep6();
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
          account: authToken.account,
          amount: _amount!.toString(),
          extraFields: extraFields);

      _submissionResult =
          await sep06.deposit(sep6DepositParams, authToken);
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
    return widget.anchoredAsset.asset.code;
  }

  Map<String, Sep6FieldInfo> getTransferFields() {
    return widget.depositInfo.fieldsInfo ?? {};
  }

  Widget getTransferDetailsColumn(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Asset: ${getAssetCode()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Transfer Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide the required information for your deposit:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          getTransferDetailsForm(),
        ],
      ),
    );
  }

  Future<void> loadKycData() async {
    var anchoredAsset = widget.anchoredAsset;
    var authToken = widget.authToken;

    try {
      var sep12 = await anchoredAsset.anchor.sep12(authToken);
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
    var anchoredAsset = widget.anchoredAsset;
    var authToken = widget.authToken;

    try {
      var sep12 = await anchoredAsset.anchor.sep12(authToken);
      var customerId = _sep12Info?.id;
      var kycForm = getKycCollectorForm();
      if (customerId == null) {
        // new anchor customer
        await sep12.add(kycForm.collectedFields);
      } else {
        // known anchor customer
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
      var sep12 = await widget.anchoredAsset.anchor.sep12(widget.authToken);
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

    if (feeFixed != null) {
      _fee = feeFixed;
      return;
    }

    if (feePercent != null && _amount != null) {
      _fee = _amount! * feePercent / 100;
      return;
    }

    if (widget.anchorHasEnabledFeeEndpoint && _amount != null) {
      String? type;
      if (transferDetails.containsKey('type')) {
        type = transferDetails['type'];
      }
      try {
        _fee = await widget.anchoredAsset.anchor.sep6().fee(
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

  Widget getKycColumn(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildKycContent(context),
    );
  }

  Widget _buildKycContent(BuildContext context) {
    if (!_kycDataLoaded) {
      return Row(
        children: [
          CircularProgress(
            size: 20,
            strokeWidth: 2,
          ),
          const SizedBox(width: 12),
          Text(
            'Loading KYC information...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    } else if (_sep12Info == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'KYC Data Unavailable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Could not load KYC data from anchor.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }

    var sep12Info = _sep12Info!;
    var status = sep12Info.sep12Status;
    
    if (status == Sep12Status.accepted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'KYC Approved',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your KYC data has been accepted by the anchor.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: deleteAnchorKycData,
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFFEF4444),
                side: BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete KYC Data',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      );
    } else if (status == Sep12Status.processing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'KYC Processing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your KYC data is currently being processed by the anchor.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    } else if (status == Sep12Status.rejected) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.cancel,
                  color: Color(0xFFEF4444),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'KYC Rejected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your KYC data has been rejected by the anchor.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    } else if (status == Sep12Status.needsInfo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFF59E0B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'KYC Information Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide the additional KYC information requested by the anchor:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          getKycCollectorForm(),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Unknown KYC Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your KYC data status is unknown.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      );
    }
  }

  Widget getFeeColumn(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _feeDetermined ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Fee Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_fee != null) ...
            [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fee: $_fee ${getAssetCode()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...
            [
              Text(
                'No fee information available for ${getAssetCode()}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
        ],
      ) : Row(
        children: [
          CircularProgress(
            size: 20,
            strokeWidth: 2,
          ),
          const SizedBox(width: 12),
          Text(
            'Loading fee information...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget getSendColumn(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.summarize,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Transfer Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deposit Amount:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$_amount ${getAssetCode()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                if (_fee != null) ...
                  [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fee:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$_fee ${getAssetCode()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
          if (_isSubmittingTransfer) ...
            [
              const SizedBox(height: 16),
              Row(
                children: [
                  CircularProgress(
                    size: 20,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Submitting transfer...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          if (_submissionResult != null) ...
            [
              const SizedBox(height: 16),
              Sep6TransferResponseView(
                response: _submissionResult!,
                key: ObjectKey(_submissionResult!),
              ),
            ],
          if (_submissionError != null) ...
            [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _submissionError!,
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
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
