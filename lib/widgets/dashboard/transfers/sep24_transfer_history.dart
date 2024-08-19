// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/dashboard/transfers/transfer_utils.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Sep24TransferHistoryWidget extends StatefulWidget {
  final List<Sep24Transaction> transactions;
  final String assetCode;

  const Sep24TransferHistoryWidget(
      {required this.assetCode, required this.transactions, super.key});

  @override
  State<Sep24TransferHistoryWidget> createState() =>
      _Sep24TransferHistoryWidgetState();
}

class _Sep24TransferHistoryWidgetState
    extends State<Sep24TransferHistoryWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.transactions.map((Sep24Transaction item) {
        return ExpansionTile(
          subtitle: Text('${item.status}'),
          title: Text(getTitle(item)),
          children: getDetails(item),
        );
      }).toList(),
    );
  }

  String getTitle(Sep24Transaction item) {
    String title = item.id;
    if (item is DepositTransaction) {
      return 'Deposit';
    }
    if (item is WithdrawalTransaction) {
      return 'Withdrawal';
    }
    if (item is IncompleteDepositTransaction) {
      return ('Deposit (incomplete)');
    }
    if (item is IncompleteWithdrawalTransaction) {
      return ('Withdrawal (incomplete)');
    }
    if (item is ErrorTransaction) {
      return ('Error');
    }
    return title;
  }

  List<Widget> getDetails(Sep24Transaction item) {
    List<Widget> details = List<Widget>.empty(growable: true);

    if (item is ProcessingAnchorTransaction) {
      if (item is DepositTransaction) {
        if (item.from != null) {
          details.add(getRow('From: ${item.from}'));
        }
        if (item.to != null) {
          details.add(getRow('To: ${item.to}'));
        }
        if (item.depositMemo != null) {
          details.add(getRow('Deposit memo: ${item.depositMemo}'));
        }
        if (item.depositMemoType != null) {
          details.add(getRow('Deposit memo type: ${item.depositMemoType}'));
        }
        if (item.claimableBalanceId != null) {
          details
              .add(getRow('Claimable balance id: ${item.claimableBalanceId}'));
        }
      } else if (item is WithdrawalTransaction) {
        if (item.from != null) {
          details.add(getRow('From: ${item.from}'));
        }
        if (item.to != null) {
          details.add(getRow('To: ${item.to}'));
        }
        if (item.withdrawalMemo != null) {
          details.add(getRow('Withdrawal memo: ${item.withdrawalMemo}'));
        }
        if (item.withdrawalMemoType != null) {
          details
              .add(getRow('Withdrawal memo type: ${item.withdrawalMemoType}'));
        }
        if (item.withdrawAnchorAccount != null) {
          details.add(getRow(
              'Withdrawal anchor account: ${item.withdrawAnchorAccount}'));
        }
      }

      if (item.statusEta != null) {
        details.add(getRow('Status Eta.: ${item.statusEta}'));
      }
      if (item.kycVerified != null) {
        details.add(getRow('Kyc verified: ${item.kycVerified}'));
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
      if (item.completedAt != null) {
        details.add(getRow('Completed at: ${item.completedAt}'));
      }
      if (item.updatedAt != null) {
        details.add(getRow('Updated at: ${item.updatedAt}'));
      }
      if (item.stellarTransactionId != null) {
        details.add(
            getRow('Stellar transaction id: ${item.stellarTransactionId}'));
      }
      if (item.externalTransactionId != null) {
        details.add(
            getRow('External transaction id: ${item.externalTransactionId}'));
      }
      if (item.refunds != null) {
        details.addAll(getRefundsDetails(item.refunds!));
      }
    } else if (item is IncompleteAnchorTransaction) {
      if (item is IncompleteDepositTransaction) {
        if (item.to != null) {
          details.add(getRow('To: ${item.to}'));
        }
      } else if (item is IncompleteWithdrawalTransaction) {
        if (item.from != null) {
          details.add(getRow('From: ${item.from}'));
        }
      }
    } else if (item is ErrorTransaction) {
      if (item.statusEta != null) {
        details.add(getRow('Status Eta.: ${item.statusEta}'));
      }
      if (item.kycVerified != null) {
        details.add(getRow('Kyc verified: ${item.kycVerified}'));
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
      if (item.quoteId != null) {
        details.add(getRow('Quote id: ${item.quoteId}'));
      }
      if (item.completedAt != null) {
        details.add(getRow('Completed at: ${item.completedAt}'));
      }
      if (item.updatedAt != null) {
        details.add(getRow('Updated at: ${item.updatedAt}'));
      }
      if (item.stellarTransactionId != null) {
        details.add(
            getRow('Stellar transaction id: ${item.stellarTransactionId}'));
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
      if (item.from != null) {
        details.add(getRow('From: ${item.from}'));
      }
      if (item.to != null) {
        details.add(getRow('To: ${item.to}'));
      }
      if (item.depositMemo != null) {
        details.add(getRow('Deposit memo: ${item.depositMemo}'));
      }
      if (item.depositMemoType != null) {
        details.add(getRow('Deposit memo type: ${item.depositMemoType}'));
      }
      if (item.claimableBalanceId != null) {
        details.add(getRow('Claimable balance id: ${item.claimableBalanceId}'));
      }
      if (item.withdrawalMemo != null) {
        details.add(getRow('Withdrawal memo: ${item.withdrawalMemo}'));
      }
      if (item.withdrawalMemoType != null) {
        details.add(getRow('Withdrawal memo type: ${item.withdrawalMemoType}'));
      }
      if (item.withdrawAnchorAccount != null) {
        details.add(
            getRow('Withdrawal anchor account: ${item.withdrawAnchorAccount}'));
      }
    }

    details.add(getRow('Started at: ${item.startedAt}'));
    if (item.message != null) {
      details.add(getRow('Msg.: ${item.message}'));
    }

    //details.add(getRow('More info url: ${item.moreInfoUrl}'));
    details.add(
      ElevatedButton(
        onPressed: () {
          var controller = WebViewController();
          controller.loadRequest(Uri.parse(item.moreInfoUrl));
          showModalBottomSheet(
              context: NavigationService.navigatorKey.currentContext!,
              isScrollControlled: true,
              builder: (context) {
                return WebViewContainer(
                    title: "SEP-24 More info", controller: controller);
              });
        },
        child: const Text('More info', style: TextStyle(color: Colors.green)),
      ),
    );
    details.add(const SizedBox(
      height: 10,
    ));

    return details;
  }

  Widget getRow(String text) {
    return ListTile(title: Text(text));
  }

  List<Widget> getRefundsDetails(Refunds refunds) {
    List<Widget> details = List<Widget>.empty(growable: true);
    details.add(getRow('Refunds - amount refunded: ${refunds.amountRefunded}'));
    details.add(getRow('Refunds - amount fee: ${refunds.amountFee}'));
    refunds.payments.map((Payment item) {
      details.add(getRow('Refunds - payment id: ${item.id}'));
      details.add(getRow('Refunds - payment id type: ${item.idType}'));
      details
          .add(getRow('Refunds - payment ${item.id} amount: ${item.amount}'));
      details.add(getRow('Refunds - payment ${item.id} fee: ${item.fee}'));
    });
    return details;
  }
}
