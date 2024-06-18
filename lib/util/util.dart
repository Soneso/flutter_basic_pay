// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

class Util {
  static String removeTrailingZerosFormAmount(String amount) {
    RegExp regex = RegExp(r"([.]*0+)(?!.*\d)");
    return amount.replaceAll(regex, '');
  }

  static String shortAccountId(String accountId) {
    if (accountId.length == 56) {
      return '${accountId.substring(0, 4)}...${accountId.substring(accountId.length - 4, accountId.length)}';
    }
    return accountId;
  }
}
