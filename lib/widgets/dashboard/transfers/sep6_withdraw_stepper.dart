// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/common/pin_form.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:flutter_basic_pay/widgets/dashboard/kyc/kyc_collector.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/transfer_utils.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';

class Sep6WithdrawStepper extends StatefulWidget {
  final AnchoredAssetInfo anchoredAsset;
  final Sep6WithdrawInfo withdrawInfo;
  final bool anchorHasEnabledFeeEndpoint;

  final AuthToken authToken;
  final DashboardState dashboardState;

  const Sep6WithdrawStepper({
    required this.anchoredAsset,
    required this.withdrawInfo,
    required this.anchorHasEnabledFeeEndpoint,
    required this.authToken,
    required this.dashboardState,
    super.key,
  });

  @override
  State<Sep6WithdrawStepper> createState() => _Sep6WithdrawStepperState();
}

class _Sep6WithdrawStepperState extends State<Sep6WithdrawStepper> {
  int _currentStep = 0;
  String _withdrawalType = '';
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
  String? _paymentError;
  bool _isSendingPayment = false;
  bool _paymentSent = false;

  @override
  Widget build(BuildContext context) {
    var types = getWithdrawalTypes();
    if (types.isNotEmpty) {
      // in a real app let the user choose the type.
      _withdrawalType = types.first;
    }
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
          'SEP-06 Withdraw',
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
            content: getSendColumn(context, widget.dashboardState),
            isActive: _currentStep >= 0,
            state: _currentStep >= 3 ? StepState.complete : StepState.disabled,
          ),
        ],
        ),
      ),
    );
  }

  Row buttonsForStep(int step, ControlsDetails details) {
    var nextButton = Container(
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
    
    var backButton = Container(
      height: 48,
      child: TextButton(
        onPressed: details.onStepCancel,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF6B7280),
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
      return Row(children: [
        Expanded(child: backButton),
        spacer,
        Expanded(child: nextButton),
      ]);
    } else if (step == 3 && !_isSubmittingTransfer) {
      // summary
      if (_submissionResult == null && _submissionError == null) {
        // not submitted yet
        var submitButton = Container(
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
        return Row(children: [
          Expanded(child: backButton),
          spacer,
          Expanded(child: submitButton),
        ]);
      } else {
        // showing submission result
        var closeButton = Container(
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
          minAmount: widget.withdrawInfo.minAmount,
          maxAmount: widget.withdrawInfo.maxAmount,
          key: ObjectKey(widget.withdrawInfo));
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
      var sep06 = widget.anchoredAsset.anchor.sep6();
      Map<String, String> extraFields = {};
      var transferDetailsForm = getTransferDetailsForm();
      for (var entry in transferDetailsForm.collectedFields.entries) {
        if (entry.key != TransferDetailsForm.transferAmountKey &&
            entry.value != null) {
          extraFields[entry.key] = entry.value!;
        }
      }
      var sep6WithdrawParams = Sep6WithdrawParams(
          assetCode: getAssetCode(),
          type: _withdrawalType,
          account: widget.authToken.account,
          amount: _amount!.toString(),
          extraFields: extraFields);

      _submissionResult =
          await sep06.withdraw(sep6WithdrawParams, widget.authToken);
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
    if (widget.withdrawInfo.types != null) {
      var typeEntries = widget.withdrawInfo.types!;
      if (typeEntries.containsKey(_withdrawalType)) {
        var fields = typeEntries[_withdrawalType];
        return fields ?? {};
      }
    }
    return {};
  }

  List<String> getWithdrawalTypes() {
    if (widget.withdrawInfo.types != null) {
      return widget.withdrawInfo.types!.keys.toList();
    }
    return [];
  }

  Column getTransferDetailsColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
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
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: const Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Asset: ${getAssetCode()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Transfer Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide the following information for your withdrawal:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              getTransferDetailsForm(),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> loadKycData() async {
    try {
      var sep12 = await widget.anchoredAsset.anchor.sep12(widget.authToken);
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
      var sep12 = await widget.anchoredAsset.anchor.sep12(widget.authToken);
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
    double? feeFixed = widget.withdrawInfo.feeFixed;
    double? feePercent = widget.withdrawInfo.feePercent;

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
              operation: 'withdraw',
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
      return Column(
        children: [
          Center(
            child: LoadingWidget(
              message: 'Loading KYC requirements...',
              showCard: false,
              size: 40,
            ),
          ),
        ],
      );
    } else if (_sep12Info == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFCA5A5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Could not load KYC data from Anchor.',
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    var sep12Info = _sep12Info!;
    var status = sep12Info.sep12Status;
    
    Widget statusCard;
    if (status == Sep12Status.accepted) {
      statusCard = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF86EFAC),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'KYC Approved',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Your KYC data has been accepted by the anchor.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF065F46),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: deleteAnchorKycData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete KYC Data'),
              ),
            ),
          ],
        ),
      );
    } else if (status == Sep12Status.processing) {
      statusCard = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFBBF24),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircularProgress(
              size: 20,
              strokeWidth: 2,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Your KYC data is currently being processed by the anchor.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (status == Sep12Status.rejected) {
      statusCard = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFCA5A5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cancel,
              color: Color(0xFFEF4444),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Your KYC data has been rejected by the anchor.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (status == Sep12Status.needsInfo) {
      statusCard = Container(
        padding: const EdgeInsets.all(20),
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
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'KYC Information Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Please provide the following information:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            getKycCollectorForm(),
          ],
        ),
      );
    } else {
      statusCard = Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.help_outline,
              color: Color(0xFF6B7280),
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Your KYC data status is unknown.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [statusCard],
    );
  }

  Column getFeeColumn(BuildContext context) {
    if (_feeDetermined) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: Color(0xFFF59E0B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Transaction Fee',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_fee != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Anchor Fee:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          '$_fee ${getAssetCode()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_fee == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF6B7280),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No fee information available for ${getAssetCode()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          Center(
            child: LoadingWidget(
              message: 'Calculating fees...',
              showCard: false,
              size: 40,
            ),
          ),
        ],
      );
    }
  }

  Column getSendColumn(BuildContext context, DashboardState dashboardState) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
                  const Text(
                    'Transfer Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Withdrawal Amount:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          '$_amount ${getAssetCode()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    if (_fee != null) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Fee:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            '$_fee ${getAssetCode()}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '${(_amount ?? 0) + (_fee ?? 0)} ${getAssetCode()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_isSubmittingTransfer) ...[
                const SizedBox(height: 20),
                Center(
                  child: LoadingWidget(
                    message: 'Submitting transfer...',
                    showCard: false,
                    size: 40,
                  ),
                ),
              ],
              if (_submissionResult != null) ...[
                const SizedBox(height: 20),
                getSubmissionResultWidget(
                    context, dashboardState, _submissionResult!),
              ],
              if (_submissionError != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFCA5A5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submissionError!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
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
        ),
      ],
    );
  }

  Widget getSubmissionResultWidget(BuildContext context,
      DashboardState dashboardState, Sep6TransferResponse response) {
    var responseView = Sep6TransferResponseView(
      response: _submissionResult!,
      key: ObjectKey(_submissionResult!),
    );

    if (response is Sep6WithdrawSuccess) {
      if (response.accountId != null) {
        var pinForm = PinForm(
          onPinSet: (String pin) async {
            await _handlePinSet(pin, dashboardState, response.accountId!,
                response.memo, response.memoType);
          },
          onCancel: () => Navigator.of(context).pop(),
          hintText: 'Enter pin to send the payment',
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            responseView,
            const SizedBox(height: 10),
            if (_paymentError != null) text(context, "Error: $_paymentError"),
            if (_isSendingPayment)
              Util.getLoadingColumn(context, "Sending ..."),
            if (!_isSendingPayment && !_paymentSent) pinForm,
            if (_paymentSent) text(context, "Payment successfully sent"),
          ],
        );
      }
    }

    return responseView;
  }

  AutoSizeText text(BuildContext context, String content) {
    return AutoSizeText(
      content,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.left,
    );
  }

  Future<void> _handlePinSet(String pin, DashboardState dashboardState,
      String receiverAccountId, String? memo, String? memoType) async {
    setState(() {
      _paymentError = null;
      _isSendingPayment = true;
    });

    try {
      // load secret seed and check if pin is valid.
      var userKeyPair = await dashboardState.authService.userKeyPair(pin);

      bool ok = await dashboardState.data.sendPayment(
          destinationAddress: receiverAccountId,
          assetId: widget.anchoredAsset.asset,
          amount: _amount!.toString(),
          memo: memo,
          memoType: memoType,
          userKeyPair: userKeyPair);
      if (ok) {
        ScaffoldMessenger.of(NavigationService.navigatorKey.currentContext!)
            .showSnackBar(
          const SnackBar(
            content: Text('Payment sent!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _paymentError = null;
          _isSendingPayment = false;
          _paymentSent = true;
        });
      } else {
        setState(() {
          _paymentError = 'An error occurred while sending the payment.';
          _isSendingPayment = false;
        });
      }
    } catch (e) {
      var errorText = "could not send payment : ${e.toString()}";
      if (e is InvalidPin) {
        errorText = "invalid pin";
      }
      setState(() {
        _paymentError = errorText;
        _isSendingPayment = false;
      });
    }
  }
}
