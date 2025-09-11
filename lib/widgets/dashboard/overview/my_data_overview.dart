// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.08),
                  const Color(0xFF10B981).withOpacity(0.03),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "My Data",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _state == _ViewState.data
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: _getCompactAddressRow(dashboardState.data.userAddress),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: _getSwitchSecretKeyRow(),
                      ),
                      if (_secretKey != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _getCompactSecretRow(_secretKey!),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 14,
                                      color: Color(0xFF991B1B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Keep secret - controls your funds',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF991B1B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 20,
                                  color: Color(0xFF991B1B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _error!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF991B1B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        PinForm(
                          onPinSet: (String pin) async {
                            await _handlePinSet(pin, dashboardState);
                          },
                          onCancel: _onPinCancel,
                          hintText: 'Enter PIN to reveal secret key',
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

  Widget _getSwitchSecretKeyRow() {
    return Row(
      children: [
        Icon(
          _showSecretKey ? Icons.visibility : Icons.visibility_off,
          size: 18,
          color: _showSecretKey
              ? const Color(0xFFF59E0B)
              : const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _showSecretKey ? 'Hide secret key' : 'Show secret key',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _showSecretKey
                ? const Color(0xFF92400E)
                : const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Transform.scale(
          scale: 0.9,
          child: Switch(
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
            activeColor: const Color(0xFFF59E0B),
            activeTrackColor: const Color(0xFFFDE68A),
          ),
        ),
      ],
    );
  }

  Widget _getCompactAddressRow(String address) {
    return Row(
      children: [
        const Icon(
          Icons.account_circle_outlined,
          color: Color(0xFF6B7280),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stellar Address',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Util.shortAddress(address),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => _copyToClipboard(address),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(
              Icons.copy,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getCompactSecretRow(String secret) {
    return Row(
      children: [
        const Icon(
          Icons.key,
          color: Color(0xFF991B1B),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Secret Key',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF991B1B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${secret.substring(0, 8)}...${secret.substring(secret.length - 6)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => _copyToClipboard(secret),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Icon(
              Icons.copy,
              size: 16,
              color: Color(0xFF991B1B),
            ),
          ),
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
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Copied to clipboard'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
