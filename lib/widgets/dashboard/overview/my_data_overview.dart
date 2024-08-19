// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:flutter_basic_pay/widgets/common/navigation_service.dart';
import 'package:flutter_basic_pay/widgets/common/pin_form.dart';
import 'package:flutter_basic_pay/widgets/common/util.dart';
import 'package:flutter_basic_pay/widgets/dashboard/home_page.dart';
import 'package:provider/provider.dart';

class MyDataOverview extends StatefulWidget {
  const MyDataOverview({super.key});

  @override
  State<MyDataOverview> createState() => _MyDataOverviewState();
}

enum _ViewState { data, pinForm }

class _MyDataOverviewState extends State<MyDataOverview> {
  bool _showSecretKey = false;
  String? _secretKey;
  String? _error;
  _ViewState _state = _ViewState.data;

  @override
  Widget build(BuildContext context) {
    var dashboardState = Provider.of<DashboardState>(context);
    return Scrollbar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("My data", style: Theme.of(context).textTheme.titleMedium),
                _getSwitchSecretKeyRow()
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_state == _ViewState.data)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Address: ",
                            style: Theme.of(context).textTheme.bodySmall),
                        _getCopyRow(dashboardState.data.userAddress),
                        if (_secretKey != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Secret key: ",
                                  style: Theme.of(context).textTheme.bodySmall),
                              _getCopyRow(_secretKey!),
                            ],
                          ),
                      ],
                    ),
                  if (_state == _ViewState.pinForm)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null)
                          Util.getErrorTextWidget(context, _error!),
                        PinForm(
                          onPinSet: (String pin) async {
                            await _handlePinSet(pin, dashboardState);
                          },
                          onCancel: _onPinCancel,
                          hintText: 'Enter pin to show secret key',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePinSet(String pin, DashboardState dashboardState) async {
    try {
      // load secret seed and check if pin is valid.
      var userKeyPair = await dashboardState.authService.userKeyPair(pin);
      setState(() {
        _error = null;
        _secretKey = userKeyPair.secretKey;
        _state = _ViewState.data;
      });
    } catch (e) {
      var errorText = "error: could not retrieve secret key";
      if (e is InvalidPin) {
        errorText = "error: invalid pin";
      }
      setState(() {
        _error = errorText;
      });
    }
  }

  void _onPinCancel() {
    setState(() {
      _error = null;
      _secretKey = null;
      _showSecretKey = false;
      _state = _ViewState.data;
    });
  }

  Row _getSwitchSecretKeyRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Show secret key?', style: Theme.of(context).textTheme.bodySmall),
        Switch(
          value: _showSecretKey,
          onChanged: (bool? value) {
            setState(() {
              _showSecretKey = value ?? false;
              if (_showSecretKey == false) {
                _secretKey = null;
                _state = _ViewState.data;
              } else {
                _state = _ViewState.pinForm;
              }
            });
          },
        ),
      ],
    );
  }

  Row _getCopyRow(String text) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: AutoSizeText(
            text,
            style: Theme.of(context)
                .textTheme
                .apply(bodyColor: Colors.blue)
                .bodySmall,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.copy_outlined,
            size: 20,
          ),
          onPressed: () => _copyToClipboard(text),
        ),
      ],
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
