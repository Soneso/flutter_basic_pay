// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_basic_pay/auth/auth.dart';
import 'package:flutter_basic_pay/storage/storage.dart';
import 'package:flutter_basic_pay/util/util.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as core_sdk;

/// Manipulates app data,
class DashboardData {
  /// The logged in user.
  User user;

  /// [wallet_sdk.Wallet] used to communicate with the Stellar Test Network.
  final wallet_sdk.Wallet _wallet = wallet_sdk.Wallet.testNet;

  /// The assets currently hold by the user.
  List<AssetInfo> assets = List<AssetInfo>.empty(growable: true);

  /// A list of "known assets" on the Stellar Test Network used to make
  /// testing easier.
  List<wallet_sdk.IssuedAssetId> knownAssets =
      List<wallet_sdk.IssuedAssetId>.empty(growable: true);

  /// Stream controller that broadcasts updates within the list of
  /// assets owned by the user. Such as asset added, asset removed,
  /// asset balance changed.
  final StreamController<List<AssetInfo>> _assetsInfoStreamController =
      StreamController<List<AssetInfo>>.broadcast();

  /// A list of recent payments that the user received or sent.
  List<PaymentInfo> recentPayments = List<PaymentInfo>.empty(growable: true);

  /// Stream controller that broadcasts updates within the list of
  /// the users recent payments.
  final StreamController<List<PaymentInfo>> _recentPaymentsStreamController =
      StreamController<List<PaymentInfo>>.broadcast();

  /// The list of contacts that the user stored.
  List<ContactInfo> contacts = List<ContactInfo>.empty(growable: true);

  /// Stream controller that broadcasts updates within the list of
  /// the users contacts. E.g. contact added.
  final StreamController<List<ContactInfo>> _contactsStreamController =
      StreamController<List<ContactInfo>>.broadcast();

  /// Constructor. Creates a new (empty) object for the given user.
  DashboardData(this.user) {
    // add known stellar test anchor assets which are great for testing
    knownAssets.add(wallet_sdk.IssuedAssetId(
        code: 'SRT',
        issuer: 'GCDNJUBQSX7AJWLJACMJ7I4BC3Z47BQUTMHEICZLE6MU4KQBRYG5JY6B'));
    knownAssets.add(wallet_sdk.IssuedAssetId(
        code: 'USDC',
        issuer: 'GBBD47IF6LWK7P7MDEVSCWR7DPUWV3NY3DTQEVFL4NAT4AQH3ZLLFLA5'));
  }

  /// Funds the user account on the Stellar Test Network by using Friendbot.
  Future<bool> fundUserAccount() async {
    // fund account
    var funded = await fundTestNetAccount(user.address);
    if (!funded) {
      return false;
    }

    // reload assets so that our data is updated.
    await loadAssets();
    await loadRecentPayments();

    return true;
  }

  /// Funds the account given by [accountId] on the Stellar Test Network by using Friendbot.
  Future<bool> fundTestNetAccount(String accountId) async {
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

  /// Loads the users assets from the Stellar Network by using the wallet sdk.
  Future<List<AssetInfo>> loadAssets() async {
    assets = await loadAssetsForAddress(user.address);
    _emitAssetsInfo();
    return assets;
  }

  /// Loads the assets for a given account specified by [accountId] from the
  /// Stellar Network by using the wallet sdk.
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

  /// Check if an account for the given [accountId] exists on the Stellar Network.
  Future<bool> accountExists(String accountId) async {
    return await _wallet.stellar().account().accountExists(accountId);
  }

  /// Loads the list of the 5 most recent payments for the user by using the
  /// flutter core sdk.
  Future<List<PaymentInfo>> loadRecentPayments() async {
    recentPayments = List<PaymentInfo>.empty(growable: true);

    var accountExists = await this.accountExists(user.address);
    if (!accountExists) {
      return recentPayments;
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
      _emitRecentPaymentsInfo();
      return recentPayments;
    }

    for (var payment in paymentsPage.records!) {
      if (payment is core_sdk.PaymentOperationResponse) {
        var direction = payment.to!.accountId == user.address
            ? PaymentDirection.received
            : PaymentDirection.sent;
        recentPayments.add(PaymentInfo(
            asset: wallet_sdk.StellarAssetId.fromAsset(payment.asset),
            amount: payment.amount!,
            direction: direction,
            address: direction == PaymentDirection.received
                ? payment.from!.accountId
                : payment.to!.accountId));
      } else if (payment is core_sdk.CreateAccountOperationResponse) {
        recentPayments.add(PaymentInfo(
            asset: wallet_sdk.NativeAssetId(),
            amount: payment.startingBalance!,
            direction: PaymentDirection.received,
            address: payment.funder!));
      } else if (payment
          is core_sdk.PathPaymentStrictReceiveOperationResponse) {
        var direction = payment.to == user.address
            ? PaymentDirection.received
            : PaymentDirection.sent;
        recentPayments.add(PaymentInfo(
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
        recentPayments.add(PaymentInfo(
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
    for (var payment in recentPayments) {
      for (var contact in contacts) {
        if (payment.address == contact.accountId) {
          payment.contactName = contact.name;
          break;
        }
      }
    }

    _emitRecentPaymentsInfo();
    return recentPayments;
  }

  /// Loads the users contacts from the local storage.
  Future<List<ContactInfo>> loadContacts() async {
    contacts = await SecureStorage.getContacts();
    _emitContactsInfo();
    return contacts;
  }

  /// Adds a new contact.
  Future<List<ContactInfo>> addContact(ContactInfo contact) async {
    contacts = await SecureStorage.addContact(contact);
    _emitContactsInfo();
    return contacts;
  }

  /// Removes a contact by name.
  Future<List<ContactInfo>> removeContact(String name) async {
    contacts = await SecureStorage.removeContact(name);
    _emitContactsInfo();
    return contacts;
  }

  /// Adds a trust line by using the wallet sdk, so that the user can hold the
  /// given [asset]. Requires the user's signing [userKeyPair] to
  /// sign the transaction before sending it to the Stellar Network.
  /// Returns true on success.
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

  /// Removes a trust line by using the wallet sdk, so that the user can not hold the
  /// given [asset] any more. It only works if the user has a balance of 0
  /// for the given asset. Requires the user's signing [userKeyPair] to
  /// sign the transaction before sending it to the Stellar Network.
  /// Returns true on success.
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

  /// Submits a payment to the Stellar Network by using the wallet sdk.
  /// It requires the [destination] account id of the recipient, the [assetId]
  /// representing the asset to be send, [amount], optional text [memo] and
  /// the signing [userKeyPair] needed to sign the transaction before submission.
  /// Returns true on success.
  Future<bool> sendPayment(
      {required String destination,
      required wallet_sdk.StellarAssetId assetId,
      required String amount,
      String? memo,
      required wallet_sdk.SigningKeyPair userKeyPair}) async {
    // Build, sign and submit transaction to stellar.
    var stellar = _wallet.stellar();
    var txBuilder = await stellar.transaction(userKeyPair);
    txBuilder = txBuilder.transfer(destination, assetId, amount);
    if (memo != null) {
      txBuilder = txBuilder.setMemo(core_sdk.MemoText(memo));
    }
    var tx = txBuilder.build();
    stellar.sign(tx, userKeyPair);
    bool success = await stellar.submitTransaction(tx);

    // Wait for the ledger to close.
    await Future.delayed(const Duration(seconds: 5));

    // Reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  /// Searches for a strict send payment path by using the wallet sdk.
  /// Requires the [sourceAsset] + [sourceAmount] and the [destinationAddress]
  /// (account id) of the recipient.
  Future<List<wallet_sdk.PaymentPath>> findStrictSendPaymentPath(
      {required wallet_sdk.StellarAssetId sourceAsset,
      required String sourceAmount,
      required String destinationAddress}) async {
    var stellar = _wallet.stellar();
    return await stellar.findStrictSendPathForDestinationAddress(
        sourceAsset, sourceAmount, destinationAddress);
  }

  /// Searches for a strict receive payment path by using the wallet sdk.
  /// Requires the [destinationAsset] and [destinationAmount].
  /// It will search for all source assets hold by the user.
  Future<List<wallet_sdk.PaymentPath>> findStrictReceivePaymentPath(
      {required wallet_sdk.StellarAssetId destinationAsset,
      required String destinationAmount}) async {
    var stellar = _wallet.stellar();
    return await stellar.findStrictReceivePathForSourceAddress(
        destinationAsset, destinationAmount, user.address);
  }

  /// Sends a strict send path payment by using the wallet sdk.
  /// Requires the [sendAssetId] representing the asset to send,
  /// strict [sendAmount] and the [destinationAddress] (account id) of the
  /// recipient. [destinationAssetId] representing the destination asset,
  /// the [destinationMinAmount] to be received and the payment path
  /// previously obtained by [findStrictSendPaymentPath]. Optional
  /// text [memo] and and the signing [userKeyPair] needed to sign
  /// the transaction before submission.
  /// Returns true on success.
  Future<bool> strictSendPayment(
      {required wallet_sdk.StellarAssetId sendAssetId,
      required String sendAmount,
      required String destinationAddress,
      required wallet_sdk.StellarAssetId destinationAssetId,
      required String destinationMinAmount,
      required List<wallet_sdk.StellarAssetId> path,
      String? memo,
      required wallet_sdk.SigningKeyPair userKeyPair}) async {
    // Build, sign and submit transaction to stellar.
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

    // Wait for the ledger to close
    await Future.delayed(const Duration(seconds: 5));

    // Reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  ///Sends a strict receive path payment by using the wallet sdk.
  /// Requires the [sendAssetId] representing the asset to send,
  /// [sendMaxAmount] and the [destinationAddress] (account id) of the
  /// recipient. [destinationAssetId] representing the destination asset,
  /// the strict [destinationAmount] to be received and the payment path
  /// previously obtained by [findStrictReceivePaymentPath]. Optional
  /// text [memo] and and the signing [userKeyPair] needed to sign
  /// the transaction before submission.
  /// Returns true on success.
  Future<bool> strictReceivePayment(
      {required wallet_sdk.StellarAssetId sendAssetId,
      required String sendMaxAmount,
      required String destinationAddress,
      required wallet_sdk.StellarAssetId destinationAssetId,
      required String destinationAmount,
      required List<wallet_sdk.StellarAssetId> path,
      String? memo,
      required wallet_sdk.SigningKeyPair userKeyPair}) async {
    // Build, sign and submit transaction to stellar.
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

    // Wait for the ledger to close.
    await Future.delayed(const Duration(seconds: 5));

    // Reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  /// Subscribe for updates on the list of assets the user holds.
  /// E.g. asset added, balance changed.
  Stream<List<AssetInfo>> subscribeForAssetsInfo() =>
      _assetsInfoStreamController.stream;

  /// Emit updates on the list of assets the user holds.
  /// E.g. asset added, balance changed.
  void _emitAssetsInfo() {
    _assetsInfoStreamController.add(assets);
  }

  /// Subscribe for updates on the list of recent payments the user sent or received.
  Stream<List<PaymentInfo>> subscribeForRecentPayments() =>
      _recentPaymentsStreamController.stream;

  /// Emit updates on the list of recent payments the user sent or received.
  void _emitRecentPaymentsInfo() {
    _recentPaymentsStreamController.add(recentPayments);
  }

  /// Subscribe for updates on the list of contacts the user has.
  /// E.g. contact added or removed.
  Stream<List<ContactInfo>> subscribeForContacts() =>
      _contactsStreamController.stream;

  /// Emit updates on the list of contacts the user has.
  /// E.g. contact added or removed.
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
