// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/api/api.dart';
import 'package:flutter_basic_pay/auth/auth.dart';
import 'package:flutter_basic_pay/util/util.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
          minHeight: 80, minWidth: double.infinity, maxHeight: 400),
      child: Card(
        color: widget.asset.asset is wallet_sdk.NativeAssetId
            ? Colors.blue[200]
            : Colors.lightGreen[200],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: widget.asset.asset is wallet_sdk.NativeAssetId
              ? _getXLMBalanceWidget()
              : widget.asset.asset is wallet_sdk.IssuedAssetId
                  ? _getIssuedAssetBalanceWidget()
                  : const SizedBox(height: 10),
        ),
      ),
    );
  }

  Widget _getXLMBalanceWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: AutoSizeText(
              "XML Balance: ${Util.removeTrailingZerosFormAmount(widget.asset.balance)}",
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _getIssuedAssetBalanceWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: AutoSizeText(
                  "${(widget.asset.asset as wallet_sdk.IssuedAssetId).code} Balance: ${Util.removeTrailingZerosFormAmount(widget.asset.balance)}",
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (double.parse(widget.asset.balance) == 0.0)
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Remove asset',
                onPressed: _state == CardState.initial
                    ? () => _handleRemoveAsset(widget.asset)
                    : null,
              ),
          ],
        ),
        if (_submitError != null)
          Text(
            _submitError!,
            style: const TextStyle(color: Colors.red),
          ),
        if (_state == CardState.sending) _getRemovingAssetProgressWidget(),
        if (_state == CardState.enterPin)
          PinForm(
            onPinSet: (String pin) async {
              await _handlePinSet(pin, widget);
            },
            onCancel: _onPinCancel,
            hintText: 'Enter pin to remove asset',
          ),
      ],
    );
  }

  Widget _getRemovingAssetProgressWidget() {
    return Row(
      children: [
        const SizedBox(
          height: 10.0,
          width: 10.0,
          child: Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(width: 10),
        Text(
          'Removing asset ...',
          style: Theme.of(context)
              .textTheme
              .apply(bodyColor: Colors.pink)
              .bodyMedium,
        ),
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
      if (e is RetrieveSeedException) {
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
