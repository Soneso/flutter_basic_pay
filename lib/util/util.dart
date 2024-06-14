import 'package:flutter_basic_pay/api/api.dart';

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
