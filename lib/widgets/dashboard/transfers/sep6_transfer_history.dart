// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/dashboard/kyc/kyc_collector.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/transfer_utils.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Sep6TransferHistoryWidget extends StatefulWidget {
  final List<Sep6Transaction> transactions;
  final String assetCode;
  final AuthToken? authToken;
  final AnchoredAssetInfo? anchoredAsset;
  final VoidCallback? onTransactionsNeedReload;

  const Sep6TransferHistoryWidget(
      {required this.assetCode, 
       required this.transactions, 
       this.authToken,
       this.anchoredAsset,
       this.onTransactionsNeedReload,
       super.key});

  @override
  State<Sep6TransferHistoryWidget> createState() =>
      _Sep6TransferHistoryWidgetState();
}

class _Sep6TransferHistoryWidgetState extends State<Sep6TransferHistoryWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No Transfer History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your SEP-06 transfer history will appear here.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Transaction list
        ...widget.transactions.map((Sep6Transaction item) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(20),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status.toString()).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getStatusIcon(item.status.toString()),
                          color: _getStatusColor(item.status.toString()),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTitle(item),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.status.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(item.status.toString()),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    ...getDetails(item),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  String getTitle(Sep6Transaction item) {
    String title = item.kind;
    if (item.kind == 'deposit' && item.amountIn != null) {
      title += ' ${item.amountIn!}';
    } else if (item.kind == 'withdrawal' && item.amountOut != null) {
      title += ' ${item.amountOut!}';
    }
    title += ' ${widget.assetCode}';
    return title;
  }

  List<Widget> getDetails(Sep6Transaction item) {
    List<Widget> details = List<Widget>.empty(growable: true);

    details.add(getRow('Id: ${item.id}'));
    details.add(getRow('Kind: ${item.kind}'));
    if (item.message != null) {
      details.add(getRow('Msg.: ${item.message}'));
    }
    if (item.statusEta != null) {
      details.add(getRow('Status Eta.: ${item.statusEta}'));
    }
    if (item.amountIn != null) {
      details.add(getRow('Amount in: ${item.amountIn}'));
    }
    if (item.amountInAsset != null) {
      details.add(getRow('Amount in asset: ${item.amountInAsset}'));
    }
    if (item.amountOut != null) {
      details.add(getRow('Amount out: ${item.amountOut}'));
    }
    if (item.amountOutAsset != null) {
      details.add(getRow('Amount out asset: ${item.amountOutAsset}'));
    }
    if (item.amountFee != null) {
      details.add(getRow('Amount fee: ${item.amountFee}'));
    }
    if (item.amountFeeAsset != null) {
      details.add(getRow('Amount fee asset: ${item.amountFeeAsset}'));
    }
    if (item.chargedFeeInfo != null) {
      details.addAll(getChargedFeeDetails(item.chargedFeeInfo!));
    }
    if (item.quoteId != null) {
      details.add(getRow('Quote id: ${item.quoteId}'));
    }
    if (item.from != null) {
      details.add(getRow('From: ${item.from}'));
    }
    if (item.to != null) {
      details.add(getRow('To: ${item.to}'));
    }
    if (item.externalExtra != null) {
      details.add(getRow('External extra: ${item.externalExtra}'));
    }
    if (item.externalExtraText != null) {
      details.add(getRow('External extra text: ${item.externalExtraText}'));
    }
    if (item.depositMemo != null) {
      details.add(getRow('Deposit memo: ${item.depositMemo}'));
    }
    if (item.depositMemoType != null) {
      details.add(getRow('Deposit memo type: ${item.depositMemoType}'));
    }
    if (item.withdrawAnchorAccount != null) {
      details.add(
          getRow('Withdraw anchor account: ${item.withdrawAnchorAccount}'));
    }
    if (item.startedAt != null) {
      details.add(getRow('Started at: ${item.startedAt}'));
    }
    if (item.updatedAt != null) {
      details.add(getRow('Updated at: ${item.updatedAt}'));
    }
    if (item.completedAt != null) {
      details.add(getRow('Completed at: ${item.completedAt}'));
    }
    if (item.stellarTransactionId != null) {
      details
          .add(getRow('Stellar transaction id: ${item.stellarTransactionId}'));
    }
    if (item.externalTransactionId != null) {
      details.add(
          getRow('External transaction id: ${item.externalTransactionId}'));
    }
    if (item.refunded != null) {
      details.add(getRow('Refunded: ${item.refunded}'));
    }
    if (item.refunds != null) {
      details.addAll(getRefundsDetails(item.refunds!));
    }
    if (item.requiredInfoMessage != null) {
      details.add(getRow('Required info message: ${item.requiredInfoMessage}'));
    }
    if (item.claimableBalanceId != null) {
      details.add(getRow('Claimable balance id: ${item.requiredInfoMessage}'));
    }
    
    // Add Update KYC info button for pending_customer_info_update status
    if (item.status == TransactionStatus.pendingCustomerInfoUpdate) {
      details.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _handleUpdateKYC(item);
            },
            icon: const Icon(Icons.edit_document, size: 16),
            label: const Text(
              'Update KYC info',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      );
    }
    
    if (item.moreInfoUrl != null) {
      //details.add(getRow('More info url: ${item.moreInfoUrl}'));
      details.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              var controller = WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..loadRequest(Uri.parse(item.moreInfoUrl!));
              showModalBottomSheet(
                  context: NavigationService.navigatorKey.currentContext!,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) {
                    return WebViewContainer(
                        title: "SEP-06 More info", controller: controller);
                  });
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text(
              'View More Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      );
    }

    // ... add more details here.
    // Map<String, Sep6FieldInfo>? requiredInfoUpdates;
    // Map<String, Sep6DepositInstruction>? instructions;

    return details;
  }

  Color _getStatusColor(String status) {
    // Check for TransactionStatus enum values (e.g., TransactionStatus.completed)
    String statusStr = status.toLowerCase();
    if (status.contains('.')) {
      // Handle enum format like "TransactionStatus.completed"
      statusStr = status.split('.').last.toLowerCase();
    }
    
    switch (statusStr) {
      case 'completed':
        return const Color(0xFF10B981); // Green
      case 'pending':
      case 'pending_external':
      case 'pending_anchor':
      case 'pending_stellar':
      case 'pending_trust':
      case 'pending_user':
      case 'pending_user_transfer_start':
      case 'pending_user_transfer_complete':
      case 'pending_customer_info_update':
        return const Color(0xFF3B82F6); // Blue
      case 'error':
      case 'failed':
      case 'no_market':
      case 'too_small':
      case 'too_large':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFFF59E0B); // Yellow/Orange for other statuses
    }
  }

  IconData _getStatusIcon(String status) {
    // Check for TransactionStatus enum values (e.g., TransactionStatus.completed)
    String statusStr = status.toLowerCase();
    if (status.contains('.')) {
      // Handle enum format like "TransactionStatus.completed"
      statusStr = status.split('.').last.toLowerCase();
    }
    
    switch (statusStr) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
      case 'pending_external':
      case 'pending_anchor':
      case 'pending_stellar':
      case 'pending_trust':
      case 'pending_user':
      case 'pending_user_transfer_start':
      case 'pending_user_transfer_complete':
      case 'pending_customer_info_update':
        return Icons.schedule;
      case 'error':
      case 'failed':
      case 'no_market':
      case 'too_small':
      case 'too_large':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Widget getRow(String text) {
    // Parse the text to extract label and value
    final parts = text.split(': ');
    if (parts.length >= 2) {
      final label = parts[0];
      final value = parts.sublist(1).join(': ');
      
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Widget> getChargedFeeDetails(Sep6ChargedFee chargedFee) {
    List<Widget> details = List<Widget>.empty(growable: true);
    details.add(getRow('Charged fee - total: ${chargedFee.total}'));
    details.add(getRow('Charged fee - asset: ${chargedFee.asset}'));
    chargedFee.details?.map((Sep6ChargedFeeDetail item) {
      details.add(getRow('Charged fee - detail name: ${item.name}'));
      details.add(getRow('Charged fee - detail amount: ${item.amount}'));
      if (item.description != null) {
        details.add(getRow('Charged fee - detail desc.: ${item.description}'));
      }
    });
    return details;
  }

  List<Widget> getRefundsDetails(Sep6Refunds refunds) {
    List<Widget> details = List<Widget>.empty(growable: true);
    details.add(getRow('Refunds - amount refunded: ${refunds.amountRefunded}'));
    details.add(getRow('Refunds - amount fee: ${refunds.amountFee}'));
    refunds.payments.map((Sep6Payment item) {
      details.add(getRow('Refunds - payment id: ${item.id}'));
      details.add(getRow('Refunds - payment id type: ${item.idType}'));
      details
          .add(getRow('Refunds - payment ${item.id} amount: ${item.amount}'));
      details.add(getRow('Refunds - payment ${item.id} fee: ${item.fee}'));
    });
    return details;
  }
  
  // Handle KYC update for a transaction
  void _handleUpdateKYC(Sep6Transaction transaction) {
    if (widget.authToken == null || widget.anchoredAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing authentication. Please reload the page.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show the KYC update dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _KycUpdateDialog(
          transaction: transaction,
          authToken: widget.authToken!,
          anchoredAsset: widget.anchoredAsset!,
          onComplete: () async {
            // Close the dialog
            Navigator.of(dialogContext).pop();
            
            // Wait for the anchor to process the KYC data
            await Future.delayed(const Duration(seconds: 3));
            
            // Trigger reload of transactions
            widget.onTransactionsNeedReload?.call();
          },
        );
      },
    );
  }
}

// KYC Update Dialog Widget
class _KycUpdateDialog extends StatefulWidget {
  final Sep6Transaction transaction;
  final AuthToken authToken;
  final AnchoredAssetInfo anchoredAsset;
  final VoidCallback? onComplete;

  const _KycUpdateDialog({
    required this.transaction,
    required this.authToken,
    required this.anchoredAsset,
    this.onComplete,
  });

  @override
  State<_KycUpdateDialog> createState() => _KycUpdateDialogState();
}

class _KycUpdateDialogState extends State<_KycUpdateDialog> {
  bool _isLoadingKycFields = false;
  bool _isSubmittingKyc = false;
  String? _errorMessage;
  String? _customerId;
  Map<String, Field>? _requiredFields;
  KycCollectorForm? _kycForm;
  Map<String, String> _storedKycData = {};

  @override
  void initState() {
    super.initState();
    _loadRequiredKycFields();
  }

  Future<void> _loadRequiredKycFields() async {
    setState(() {
      _isLoadingKycFields = true;
      _errorMessage = null;
    });

    try {
      // Load stored KYC data
      _storedKycData = await SecureStorage.getKycData();

      // Get SEP-12 service
      var sep12 = await widget.anchoredAsset.anchor.sep12(widget.authToken);
      
      // Get required fields for this transaction
      var response = await sep12.get(transactionId: widget.transaction.id);
      
      // Filter to only required fields
      Map<String, Field> requiredFields = {};
      if (response.fields != null) {
        for (var entry in response.fields!.entries) {
          bool isOptional = entry.value.optional ?? false;
          if (!isOptional) {
            requiredFields[entry.key] = entry.value;
          }
        }
      }

      setState(() {
        _customerId = response.id;
        _requiredFields = requiredFields;
        _isLoadingKycFields = false;
        
        if (requiredFields.isEmpty) {
          _errorMessage = 'No KYC information required for this transaction.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading KYC requirements: ${e.toString()}';
        _isLoadingKycFields = false;
      });
    }
  }

  Future<void> _submitKycData() async {
    if (_kycForm == null || !_kycForm!.validateAndCollect()) {
      return;
    }

    setState(() {
      _isSubmittingKyc = true;
      _errorMessage = null;
    });

    try {
      // Get SEP-12 service
      var sep12 = await widget.anchoredAsset.anchor.sep12(widget.authToken);
      
      // Prepare the data
      Map<String, String> kycData = Map.from(_kycForm!.collectedFields);
      
      // Submit the KYC data
      if (_customerId != null) {
        await sep12.update(kycData, _customerId!, transactionId: widget.transaction.id);
      } else {
        await sep12.add(kycData, transactionId: widget.transaction.id);
      }

      // Save KYC data locally for future use
      await SecureStorage.setKycData(kycData);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC information updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Trigger the completion callback
        widget.onComplete?.call();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting KYC data: ${e.toString()}';
        _isSubmittingKyc = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_document,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Update KYC Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSubmittingKyc
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildBody(),
              ),
            ),
            // Footer buttons
            if (!_isLoadingKycFields && _requiredFields != null && _requiredFields!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmittingKyc
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmittingKyc ? null : _submitKycData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmittingKyc
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingKycFields) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: LoadingWidget(
            message: 'Loading KYC requirements...',
            showCard: false,
          ),
        ),
      );
    }

    if (_errorMessage != null && _requiredFields == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blue[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_requiredFields == null || _requiredFields!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No additional KYC information required.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Build KYC form
    _kycForm ??= KycCollectorForm(
      sep12Fields: _requiredFields!,
      initialValues: _storedKycData,
      key: ObjectKey([_requiredFields, _storedKycData]),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction ID: ${widget.transaction.id}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Please provide the required information below:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
        _kycForm!,
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
