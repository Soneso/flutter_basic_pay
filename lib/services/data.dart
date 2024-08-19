// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_basic_pay/services/stellar.dart';
import 'package:flutter_basic_pay/services/storage.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;

/// Manipulates app data.
class DashboardData {
  /// The logged in user's stellar address.
  String userAddress;

  /// The assets currently hold by the user.
  List<AssetInfo> assets = List<AssetInfo>.empty(growable: true);

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

  /// KYC Information that the user stored
  Map<String, String> kycData = <String, String>{};

  /// Stream controller that broadcasts updates of the user's kyc data.
  final StreamController<Map<String, String>> _kycDataStreamController =
      StreamController<Map<String, String>>.broadcast();

  /// Constructor. Creates a new (empty) object for the given user.
  DashboardData(this.userAddress);

  /// Funds the user account on the Stellar Test Network by using Friendbot.
  Future<bool> fundUserAccount() async {
    // fund account
    var funded = await StellarService.fundTestNetAccount(userAddress);
    if (!funded) {
      return false;
    }

    // Wait for the ledger to close.
    await Future.delayed(const Duration(seconds: 5));

    // reload assets so that our data is updated.
    await loadAssets();
    await loadRecentPayments();

    return true;
  }

  /// Loads the users assets from the Stellar Network
  Future<List<AssetInfo>> loadAssets() async {
    assets = await StellarService.loadAssetsForAddress(userAddress);
    _emitAssetsInfo();
    return assets;
  }

  /// Loads the list of the 5 most recent payments for the user.
  /// After loading, it emits an event, so that the UI can be updated.
  Future<List<PaymentInfo>> loadRecentPayments() async {
    recentPayments = await StellarService.loadRecentPayments(userAddress);

    // lets see if we can assign some payments to friends
    if (contacts.isEmpty) {
      contacts = await SecureStorage.getContacts();
    }
    for (var payment in recentPayments) {
      for (var contact in contacts) {
        if (payment.address == contact.address) {
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

  /// Loads the user's kyc data from secure storage.
  Future<Map<String, String>> loadKycData() async {
    kycData = await SecureStorage.getKycData();
    _emitKycDataInfo();
    return kycData;
  }

  /// Adds a new contact.
  Future<Map<String, String>> updateKycDataEntry(
      String key, String value) async {
    kycData = await SecureStorage.updateKycDataEntry(key, value);
    _emitKycDataInfo();
    return kycData;
  }

  /// Adds a trust line by using the wallet sdk, so that the user can hold the
  /// given [asset]. Requires the user's signing [userKeyPair] to
  /// sign the transaction before sending it to the Stellar Network.
  /// Returns true on success.
  Future<bool> addAssetSupport(wallet_sdk.IssuedAssetId asset,
      wallet_sdk.SigningKeyPair userKeyPair) async {
    var success = await StellarService.addAssetSupport(asset, userKeyPair);

    // Wait for the ledger to close.
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
    var success = await StellarService.removeAssetSupport(asset, userKeyPair);

    // Wait for the ledger to close.
    await Future.delayed(const Duration(seconds: 5));

    // reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  /// Submits a payment to the Stellar Network by using the wallet sdk.
  /// It requires the [destinationAddress] of the recipient, the [assetId]
  /// representing the asset to be send, [amount], optional [memo] and [memoType] and
  /// the signing [userKeyPair] needed to sign the transaction before submission.
  /// Returns true on success.
  Future<bool> sendPayment(
      {required String destinationAddress,
      required wallet_sdk.StellarAssetId assetId,
      required String amount,
      String? memo,
      String? memoType,
      required wallet_sdk.SigningKeyPair userKeyPair}) async {
    var success = StellarService.sendPayment(
        destinationAddress: destinationAddress,
        assetId: assetId,
        amount: amount,
        memo: memo,
        memoType: memoType,
        userKeyPair: userKeyPair);

    // Wait for the ledger to close.
    await Future.delayed(const Duration(seconds: 5));

    // Reload assets so that our data is updated.
    await loadAssets();

    return success;
  }

  /// Sends a strict send path payment by using the wallet sdk.
  /// Requires the [sendAssetId] representing the asset to send,
  /// strict [sendAmount] and the [destinationAddress] of the
  /// recipient. [destinationAssetId] representing the destination asset,
  /// the [destinationMinAmount] to be received and the assets [path] from the
  /// payment path previously obtained by [findStrictSendPaymentPath]. Optional
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
    bool success = await StellarService.strictSendPayment(
        sendAssetId: sendAssetId,
        sendAmount: sendAmount,
        destinationAddress: destinationAddress,
        destinationAssetId: destinationAssetId,
        destinationMinAmount: destinationMinAmount,
        path: path,
        userKeyPair: userKeyPair);

    // Wait for the ledger to close
    await Future.delayed(const Duration(seconds: 5));

    // Reload assets and recent payments, so that our data is updated.
    await loadAssets();
    await loadRecentPayments();

    return success;
  }

  ///Sends a strict receive path payment by using the wallet sdk.
  /// Requires the [sendAssetId] representing the asset to send,
  /// [sendMaxAmount] and the [destinationAddress] of the
  /// recipient. [destinationAssetId] representing the destination asset,
  /// the strict [destinationAmount] to be received and the assets [path] from the
  /// payment path previously obtained by [findStrictSendPaymentPath]. Optional
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
    bool success = await StellarService.strictReceivePayment(
        sendAssetId: sendAssetId,
        sendMaxAmount: sendMaxAmount,
        destinationAddress: destinationAddress,
        destinationAssetId: destinationAssetId,
        destinationAmount: destinationAmount,
        path: path,
        userKeyPair: userKeyPair);

    // Wait for the ledger to close.
    await Future.delayed(const Duration(seconds: 5));

    // Reload assets and recent payments, so that our data is updated.
    await loadAssets();
    await loadRecentPayments();

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

  /// Subscribe for updates on the user's kyc data.
  Stream<Map<String, String>> subscribeForKycData() =>
      _kycDataStreamController.stream;

  /// Emit updates on the user's kyc data
  void _emitKycDataInfo() {
    _kycDataStreamController.add(kycData);
  }
}
