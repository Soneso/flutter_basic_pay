// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_basic_pay/services/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;

/// Used to store secret user data in the local storage.
class SecureStorage {
  static const _userSecretStorageKey = 'secret';
  static const _contactsStorageKey = 'contacts';

  /// Stores the signing [userSigningKeyPair] to secure storage. Uses the [pin] to
  /// cryptographically encode the secret seed before storing it, so that
  /// it can only be retrieved by the user that knows the pin.
  static storeUserKeyPair(wallet_sdk.SigningKeyPair userSigningKeyPair, String pin) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();

    // encrypt the secret key before saving it, so that only the user can decrypt it.
    var encryptedSecretKey = AesHelper.encrypt(pin, userSigningKeyPair.secretKey);
    await storage.write(key: _userSecretStorageKey, value: encryptedSecretKey);
  }

  /// Returns true if secure user data is stored in the storage.
  static Future<bool> hasUser() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    return await storage.containsKey(key: _userSecretStorageKey);
  }

  /// Returns the signing user keypair from the storage. Requires the
  /// user's [pin] to decode the stored user's secret key. It can only construct
  /// the keypair if there is user data in the storage (see [hasUser]) and
  /// if the given [pin] is valid. Throws [UserNotFound] if the user data could
  /// not be found in the secure storage. Throws [InvalidPin] if the pin
  /// is invalid and the data could not be decrypted.
  static Future<wallet_sdk.SigningKeyPair> getUserKeyPair(String pin) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    var encryptedUserSecret = await storage.read(key: _userSecretStorageKey);
    if (encryptedUserSecret == null) {
      throw UserNotFound();
    }
    // decrypt user secret key with pin
    try {
      var userSecretKey = AesHelper.decrypt(pin, encryptedUserSecret);
      return wallet_sdk.SigningKeyPair.fromSecret(userSecretKey);
    } catch (e) {
      throw InvalidPin();
    }
  }

  /// Stores a new user [contact]. If the contact (name) already exists,
  /// it will be overridden.
  static Future<List<ContactInfo>> addContact(ContactInfo contact) async {
    var contacts = await getContacts();
    contacts.removeWhere((item) => item.name == contact.name);
    contacts.add(contact);
    await _saveContacts(contacts);
    return contacts;
  }

  /// Loads the user contacts from secure storage.
  static Future<List<ContactInfo>> getContacts() async {
    List<ContactInfo> contacts = List<ContactInfo>.empty(growable: true);
    const FlutterSecureStorage storage = FlutterSecureStorage();
    var contactsJson = await storage.read(key: _contactsStorageKey);
    if (contactsJson != null) {
      var data = json.decode(contactsJson);
      contacts = List<ContactInfo>.from(
          data['contacts'].map((e) => ContactInfo.fromJson(e)));
    }
    return contacts;
  }

  /// Removes a user contact from storage for the given [contactName].
  static Future<List<ContactInfo>> removeContact(String contactName) async {
    var contacts = await getContacts();
    contacts.removeWhere((item) => item.name == contactName);
    await _saveContacts(contacts);
    return contacts;
  }

  /// Saves the list of contacts to storage as a json string.
  static Future<void> _saveContacts(List<ContactInfo> contacts) async {
    var valArr = List<Map<String, dynamic>>.empty(growable: true);
    for (var contract in contacts) {
      valArr.add(contract.toJson());
    }
    Map<String, dynamic> jsonContacts = {'contacts': valArr};
    var data = json.encode(jsonContacts);
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.write(key: _contactsStorageKey, value: data);
  }
}

class ContactInfo {
  String name;
  String address;

  ContactInfo(this.name, this.address);

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        json['name'],
        json['address'],
      );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
    };
  }
}

class UserNotFound implements Exception {}
class InvalidPin implements Exception {}