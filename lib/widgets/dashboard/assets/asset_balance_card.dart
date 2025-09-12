// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:flutter_basic_pay/widgets/common/pin_form.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;

class AssetBalanceCard extends StatefulWidget {
  final AssetInfo asset;
  final Future<wallet_sdk.SigningKeyPair> Function(String) getUserKeyPair;
  final Future<bool> Function(
      wallet_sdk.IssuedAssetId, wallet_sdk.SigningKeyPair) removeAssetSupport;
  const AssetBalanceCard(
      this.asset, this.getUserKeyPair, this.removeAssetSupport,
      {super.key});

  @override
  State<AssetBalanceCard> createState() => _AssetBalanceCardState();
}

enum CardState { initial, enterPin, sending }

class _AssetBalanceCardState extends State<AssetBalanceCard> {
  CardState _state = CardState.initial;
  String? _submitError;
  
  String _truncateMiddle(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final startLength = (maxLength - 3) ~/ 2;
    final endLength = maxLength - 3 - startLength;
    return '${text.substring(0, startLength)}...${text.substring(text.length - endLength)}';
  }

  @override
  Widget build(BuildContext context) {
    final isNative = widget.asset.asset is wallet_sdk.NativeAssetId;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNative ? Colors.blue.shade200 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.asset.asset is wallet_sdk.NativeAssetId
            ? _getXLMBalanceWidget()
            : widget.asset.asset is wallet_sdk.IssuedAssetId
                ? _getIssuedAssetBalanceWidget()
                : const SizedBox(height: 10),
      ),
    );
  }

  Widget _getXLMBalanceWidget() {
    final balance = Util.removeTrailingZerosFormAmount(widget.asset.balance);
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade500, Colors.blue.shade600],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'XLM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stellar Lumens',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Native Asset',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              balance,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'XLM',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getIssuedAssetBalanceWidget() {
    final assetId = widget.asset.asset as wallet_sdk.IssuedAssetId;
    final balance = Util.removeTrailingZerosFormAmount(widget.asset.balance);
    final hasZeroBalance = double.parse(widget.asset.balance) == 0.0;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  assetId.code.substring(0, min(3, assetId.code.length)),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assetId.code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _truncateMiddle(assetId.issuer, 12),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balance,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  assetId.code,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (hasZeroBalance && _state == CardState.initial) ...[  
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: Colors.red.shade400,
                ),
                tooltip: 'Remove asset',
                onPressed: () => _handleRemoveAsset(widget.asset),
              ),
            ],
          ],
        ),
        if (_submitError != null) ...[  
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _submitError!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_state == CardState.sending) ...[  
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Removing asset...',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_state == CardState.enterPin) ...[  
          const SizedBox(height: 12),
          PinForm(
            onPinSet: (String pin) async {
              await _handlePinSet(pin, widget);
            },
            onCancel: _onPinCancel,
            hintText: 'Enter PIN to remove asset',
          ),
        ],
      ],
    );
  }


  void _handleRemoveAsset(AssetInfo asset) {
    if (_state != CardState.initial) {
      return;
    }

    setState(() {
      _state = CardState.enterPin;
    });
  }

  Future<void> _handlePinSet(String pin, AssetBalanceCard widget) async {
    var beforeSendingState = _state;
    setState(() {
      _submitError = null;
      _state = CardState.sending;
    });
    try {
      // load secret seed and check if pin is valid.
      var userKeyPair = await widget.getUserKeyPair(pin);

      bool ok = await widget.removeAssetSupport(
          widget.asset.asset as wallet_sdk.IssuedAssetId, userKeyPair);
      if (!ok) {
        throw Exception("failed to submit");
      }
    } catch (e) {
      var errorText = "error: could not remove asset";
      if (e is InvalidPin) {
        errorText = "error: invalid pin";
      }
      setState(() {
        _submitError = errorText;
        _state = beforeSendingState;
      });
    }
  }

  void _onPinCancel() {
    setState(() {
      _state = CardState.initial;
    });
  }
}
