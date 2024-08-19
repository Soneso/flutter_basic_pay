// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

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

  static Column getLoadingColumn(BuildContext context, String text,
      {bool showDivider = true, Key? key}) {
    return Column(
      key: key ?? ObjectKey(text),
      children: [
        if (showDivider)
          const Divider(
            color: Colors.blue,
          ),
        Row(
          children: [
            const SizedBox(
              height: 10.0,
              width: 10.0,
              child: Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  static AutoSizeText getErrorTextWidget(BuildContext context, String text,
      {Key? key}) {
    return AutoSizeText(
      text,
      key: key ?? ObjectKey(text),
      style:
          Theme.of(context).textTheme.apply(bodyColor: Colors.red).bodyMedium,
    );
  }
}
