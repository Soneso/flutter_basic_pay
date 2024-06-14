import 'dart:async';
import 'package:flutter_basic_pay/auth/auth.dart';
import 'package:flutter_basic_pay/storage/storage.dart';
import 'package:flutter_basic_pay/util/util.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as core_sdk;

/// Manipulates app data,
class DashboardData {
  User user;
  final wallet_sdk.Wallet _wallet = wallet_sdk.Wallet.testNet;

  List<AssetInfo> assets = List<AssetInfo>.empty(growable: true);
  List<wallet_sdk.IssuedAssetId> knownAssets =
      List<wallet_sdk.IssuedAssetId>.empty(growable: true);
  final StreamController<List<AssetInfo>> _accountInfoStreamController =
      StreamController<List<AssetInfo>>.broadcast();

  List<PaymentInfo> payments = List<PaymentInfo>.empty(growable: true);
  final StreamController<List<PaymentInfo>> _paymentsStreamController =
      StreamController<List<PaymentInfo>>.broadcast();

  List<ContactInfo> contacts = List<ContactInfo>.empty(growable: true);
  final StreamController<List<ContactInfo>> _contactsStreamController =
      StreamController<List<ContactInfo>>.broadcast();

  DashboardData(this.user) {
    // add known stellar test anchor assets which are great for testing
    knownAssets.add(wallet_sdk.IssuedAssetId(
        code: 'SRT',
        issuer: 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B'));
    knownAssets.add(wallet_sdk.IssuedAssetId(
        code: 'USDC',
        issuer: 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
  }

  Future<List<AssetInfo>> loadAssets() async {
    assets = await loadAssetsForAddress(user.address);
    _emitAccountInfo();
    return assets;
  }

  Future<List<AssetInfo>> loadAssetsForAddress(String accountId) async {
    var loadedAssets = List<AssetInfo>.empty(growable: true);
    try {
      var stellarAccountInfo =
          await _wallet.stellar().account().getInfo(accountId);
      for (var balance in stellarAccountInfo.balances) {
        loadedAssets.add(AssetInfo(
          asset: wallet_sdk.StellarAssetId.fromAsset(balance.asset),
          balance: balance.balance,
        ));
      }
    } on wallet_sdk.ValidationException {
      // account dose not exist
      loadedAssets = List<AssetInfo>.empty(growable: true);
    }
    return loadedAssets;
  }

  /// check if an account for the given [accountId] exists on the stellar network.
  Future<bool> accountExists(String accountId) async {
    return await _wallet.stellar().account().accountExists(accountId);
  }

  Future<List<PaymentInfo>> loadRecentPayments() async {
    payments = List<PaymentInfo>.empty(growable: true);

    var accountExists = await this.accountExists(user.address);
    if (!accountExists) {
      return payments;
    }
    // fetch payments from stellar
    var server = _wallet.stellar().server;

    // loads the recent payments (max 5)
    var paymentsPage = await server.payments
        .forAccount(user.address)
        .order(core_sdk.RequestBuilderOrder.DESC)
        .limit(5)
        .execute();

    if (paymentsPage.records == null) {
      _emitPaymentsInfo();
      return payments;
    }

    for (var payment in paymentsPage.records!) {
      if (payment is core_sdk.PaymentOperationResponse) {
        var direction = payment.to!.accountId == user.address
            ? PaymentDirection.received
            : PaymentDirection.sent;
        payments.add(PaymentInfo(
            asset: wallet_sdk.StellarAssetId.fromAsset(payment.asset),
            amount: payment.amount!,
            direction: direction,
            address: direction == PaymentDirection.received
                ? payment.from!.accountId
                : payment.to!.accountId));
      } else if (payment is core_sdk.CreateAccountOperationResponse) {
        payments.add(PaymentInfo(
            asset: wallet_sdk.NativeAssetId(),
            amount: payment.startingBalance!,
            direction: PaymentDirection.received,
            address: payment.funder!));
      } else if (payment
          is core_sdk.PathPaymentStrictReceiveOperationResponse) {
        var direction = payment.to == user.address
            ? PaymentDirection.received
            : PaymentDirection.sent;
        payments.add(PaymentInfo(
            asset: wallet_sdk.StellarAssetId.fromAsset(payment.asset),
            amount: payment.amount!,
            direction: direction,
            address: direction == PaymentDirection.received
                ? payment.from!
                : payment.to!));
      } else if (payment is core_sdk.PathPaymentStrictSendOperationResponse) {
        var direction = payment.to == user.address
            ? PaymentDirection.received
            : PaymentDirection.sent;
        payments.add(PaymentInfo(
            asset: wallet_sdk.StellarAssetId.fromAsset(payment.asset),
            amount: payment.amount!,
            direction: direction,
            address: direction == PaymentDirection.received
                ? payment.from!
                : payment.to!));
      }
    }

    // lets see if we can assign some payments to friends
    if (contacts.isEmpty) {
      contacts = await SecureStorage.getContacts();
    }
    for (var payment in payments) {
      for (var contact in contacts) {
        if (payment.address == contact.accountId) {
          payment.contactName = contact.name;
          break;
        }
      }
    }

    _emitPaymentsInfo();
    return payments;
  }

  Future<List<ContactInfo>> loadContacts() async {
    contacts = await SecureStorage.getContacts();
    _emitContactsInfo();
    return contacts;
  }

  Future<List<ContactInfo>> addContact(ContactInfo contact) async {
    contacts = await SecureStorage.addContact(contact);
    _emitContactsInfo();
    return contacts;
  }

  Future<List<ContactInfo>> removeContact(String name) async {
    contacts = await SecureStorage.removeContact(name);
    _emitContactsInfo();
    return contacts;
  }

  Future<bool> fundUserAccount() async {
    // fund account
    var funded = await fundTestnetAccount(user.address);
    if (!funded) {
      return false;
    }

    // reload assets so that our data is updated.
    await loadAssets();
    await loadRecentPayments();

    return true;
  }

  Future<bool> fundTestnetAccount(String accountId) async {
    // fund account
    var funded =
        await _wallet.stellar().account().fundTestNetAccount(accountId);
    if (!funded) {
      return false;
    }

    // wait for the ledger to close
    await Future.delayed(const Duration(seconds: 5));
    return true;
  }

  Future<bool> sendPayment(
      {required String destination,
      required wallet_sdk.StellarAssetId assetId,
      required String amount,
      String? memo,
      required wallet_sdk.SigningKeyPair userKeyPair}) async {
    // build sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    txBuilder = txBuilder.transfer(destination, assetId, amount);
    if (memo != null) {
      txBuilder = txBuilder.setMemo(core_sdk.MemoText(memo));
    }
    var tx = txBuilder.build();
    stellar.sign(tx, userKeyPair);
    bool success = await stellar.submitTransaction(tx);

    // wait for the ledger to close
    await Future.delayed(const Duration(seconds: 5));

    // reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  Future<List<wallet_sdk.PaymentPath>> findStrictSendPaymentPath(
      {required wallet_sdk.StellarAssetId sourceAsset,
      required String sourceAmount,
      required String destinationAddress}) async {
    var stellar = _wallet.stellar();
    return await stellar.findStrictSendPathForDestinationAddress(
        sourceAsset, sourceAmount, destinationAddress);
  }

  Future<List<wallet_sdk.PaymentPath>> findStrictReceivePaymentPath(
      {required wallet_sdk.StellarAssetId destinationAsset,
      required String destinationAmount}) async {
    var stellar = _wallet.stellar();
    return await stellar.findStrictReceivePathForSourceAddress(
        destinationAsset, destinationAmount, user.address);
  }

  Future<bool> addAssetSupport(wallet_sdk.IssuedAssetId asset,
      wallet_sdk.SigningKeyPair userKeyPair) async {
    // build sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    var tx = txBuilder.addAssetSupport(asset).build();
    stellar.sign(tx, userKeyPair);
    bool success = await stellar.submitTransaction(tx);

    // wait for the ledger to close
    await Future.delayed(const Duration(seconds: 5));

    // reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  Future<bool> removeAssetSupport(wallet_sdk.IssuedAssetId asset,
      wallet_sdk.SigningKeyPair userKeyPair) async {
    // build sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    var tx = txBuilder.removeAssetSupport(asset).build();
    stellar.sign(tx, userKeyPair);
    bool success = await stellar.submitTransaction(tx);
    // wait for the ledger to close
    await Future.delayed(const Duration(seconds: 5));

    // reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  Future<bool> strictSendPayment(
      {required wallet_sdk.StellarAssetId sendAssetId,
      required String sendAmount,
      required String destinationAddress,
      required wallet_sdk.StellarAssetId destinationAssetId,
      required String destinationMinAmount,
      required List<wallet_sdk.StellarAssetId> path,
      String? memo,
      required wallet_sdk.SigningKeyPair userKeyPair}) async {
    // build sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    txBuilder = txBuilder.strictSend(
        sendAssetId: sendAssetId,
        sendAmount: sendAmount,
        destinationAddress: destinationAddress,
        destinationAssetId: destinationAssetId,
        destinationMinAmount: destinationMinAmount,
        path: path);
    if (memo != null) {
      txBuilder = txBuilder.setMemo(core_sdk.MemoText(memo));
    }
    var tx = txBuilder.build();
    stellar.sign(tx, userKeyPair);
    bool success = await stellar.submitTransaction(tx);

    // wait for the ledger to close
    await Future.delayed(const Duration(seconds: 5));

    // reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  Future<bool> strictReceivePayment(
      {required wallet_sdk.StellarAssetId sendAssetId,
        required String sendMaxAmount,
        required String destinationAddress,
        required wallet_sdk.StellarAssetId destinationAssetId,
        required String destinationAmount,
        required List<wallet_sdk.StellarAssetId> path,
        String? memo,
        required wallet_sdk.SigningKeyPair userKeyPair}) async {
    // build sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    txBuilder = txBuilder.strictReceive(
        sendAssetId: sendAssetId,
        sendMaxAmount: sendMaxAmount,
        destinationAddress: destinationAddress,
        destinationAssetId: destinationAssetId,
        destinationAmount: destinationAmount,
        path: path);
    if (memo != null) {
      txBuilder = txBuilder.setMemo(core_sdk.MemoText(memo));
    }
    var tx = txBuilder.build();
    stellar.sign(tx, userKeyPair);
    bool success = await stellar.submitTransaction(tx);

    // wait for the ledger to close
    await Future.delayed(const Duration(seconds: 5));

    // reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  Stream<List<AssetInfo>> subscribeForAccountInfo() =>
      _accountInfoStreamController.stream;

  void _emitAccountInfo() {
    _accountInfoStreamController.add(assets);
  }

  Stream<List<PaymentInfo>> subscribeForPayments() =>
      _paymentsStreamController.stream;

  void _emitPaymentsInfo() {
    _paymentsStreamController.add(payments);
  }

  Stream<List<ContactInfo>> subscribeForContacts() =>
      _contactsStreamController.stream;

  void _emitContactsInfo() {
    _contactsStreamController.add(contacts);
  }
}

class AssetInfo {
  wallet_sdk.StellarAssetId asset;
  String balance;

  AssetInfo({required this.asset, required this.balance});
}

enum PaymentDirection { sent, received }

class PaymentInfo {
  wallet_sdk.StellarAssetId asset;
  String amount;
  PaymentDirection direction;
  String address;
  String? contactName;

  PaymentInfo(
      {required this.asset,
      required this.amount,
      required this.direction,
      required this.address,
      this.contactName});

  @override
  String toString() {
    return '${Util.removeTrailingZerosFormAmount(amount)} ${asset.id == 'native' ? 'XLM' : (asset as wallet_sdk.IssuedAssetId).code}'
        '${direction == PaymentDirection.received ? ' received from' : ' sent to'} ${contactName ?? Util.shortAccountId(address)}';
  }
}
