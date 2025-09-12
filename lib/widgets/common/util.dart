// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_basic_pay/widgets/common/loading.dart';

class Util {
  static String removeTrailingZerosFormAmount(String amount) {
    RegExp regex = RegExp(r"([.]*0+)(?!.*\d)");
    return amount.replaceAll(regex, '');
  }

  /// Returns a shorter string representation of a given strellar address.
  /// E.g. GAT5...OU4R instead of GAT5UQJMYZ37UNW2RKTV7VPLKO2CZJORV6B2PAL3JIXNA6KCMQZPOU4R.
  static String shortAddress(String address) {
    if (address.length == 56) {
      return '${address.substring(0, 4)}...${address.substring(address.length - 4, address.length)}';
    }
    return address;
  }

  static Widget getLoadingColumn(BuildContext context, String text,
      {bool showDivider = true, Key? key}) {
    return Column(
      key: key ?? ObjectKey(text),
      children: [
        if (showDivider)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF3B82F6).withOpacity(0.3),
                  const Color(0xFF3B82F6).withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgress(
                size: 20,
                strokeWidth: 2.5,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget getErrorTextWidget(BuildContext context, String text,
      {Key? key}) {
    return Container(
      key: key ?? ObjectKey(text),
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
              text,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
