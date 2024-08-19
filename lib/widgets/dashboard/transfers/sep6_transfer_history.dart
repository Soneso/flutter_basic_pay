// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart';

class Sep6TransferHistoryWidget extends StatefulWidget {
  final List<Sep6Transaction> transactions;
  final String assetCode;

  const Sep6TransferHistoryWidget(
      {required this.assetCode, required this.transactions, super.key});

  @override
  State<Sep6TransferHistoryWidget> createState() =>
      _Sep6TransferHistoryWidgetState();
}

class _Sep6TransferHistoryWidgetState extends State<Sep6TransferHistoryWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.transactions.map((Sep6Transaction item) {
        return ExpansionTile(
          subtitle: Text('${item.status}'),
          title: Text(getTitle(item)),
          children: getDetails(item),
        );
      }).toList(),
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
    if (item.moreInfoUrl != null) {
      details.add(getRow('More info url: ${item.moreInfoUrl}'));
    }

    // ... add more details here.
    // Map<String, Sep6FieldInfo>? requiredInfoUpdates;
    // Map<String, Sep6DepositInstruction>? instructions;

    return details;
  }

  Widget getRow(String text) {
    return ListTile(title: Text(text));
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
}
