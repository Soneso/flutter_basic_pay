// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_basic_pay/storage/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as core_sdk;


/// Used to store secret user data in the local storage.
class SecureStorage {
  static const _userAddressKey = 'address';
  static const _userSecretKey = 'secret';
  static const _contactsKey = 'contacts';

  /// Stores the signing [userKeyPair] to secure storage. Uses the [pin] to
  /// cryptographically encode the secret seed before storing it, so that
  /// it can only be retrieved by the user that knows the pin.
  static setUser(wallet_sdk.SigningKeyPair userKeyPair, String pin) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.write(key: _userAddressKey, value: userKeyPair.address);

    // encrypt the seed before saving it, so that only the user can decrypt it.
    var encryptedSeed = AesHelper.encrypt(pin, userKeyPair.secretKey);
    await storage.write(key: _userSecretKey, value: encryptedSeed);
  }

  /// Returns true if secure user data is stored in the storage.
  static Future<bool> hasUser() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    var secret = await storage.read(key: _userSecretKey);
    return secret == null ? false : true;
  }

  /// Returns the signing user keypair from the storage. Requires the
  /// user's [pin] to decode the stored secret seed stored. It can only construct
  /// the keypair if there is user data in the storage (see [hasUser]) and
  /// if the given [pin] is valid. Throws [ArgumentError] otherwise.
  static Future<wallet_sdk.SigningKeyPair> getUserKeyPair(String pin) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    var encryptedSeed = await storage.read(key: _userSecretKey);
    if (encryptedSeed == null) {
      throw ArgumentError('no user found in storage');
    }
    // decrypt seed with pin
    try {
      var secretSeed = AesHelper.decrypt(pin, encryptedSeed);
      var kp = core_sdk.KeyPair.fromSecretSeed(secretSeed);
      return wallet_sdk.SigningKeyPair(kp);
    } catch (e) {
      throw ArgumentError('invalid pin');
    }
  }

  /// Loads the user contacts from secure storage.
  static Future<List<ContactInfo>> getContacts() async {
    List<ContactInfo> contacts = List<ContactInfo>.empty(growable: true);
    const FlutterSecureStorage storage = FlutterSecureStorage();
    var contactsJson = await storage.read(key: _contactsKey);
    if (contactsJson != null) {
      var data = json.decode(contactsJson);
      contacts = List<ContactInfo>.from(
          data['contacts'].map((e) => ContactInfo.fromJson(e)));
    }
    return contacts;
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

  /// Checks is the user has a contact with the given [name].
  static Future<bool> hasContact(String name) async {
    var contacts = await getContacts();
    return contacts.any((item) => item.name == name);
  }

  /// Removes a user contact from storage for the given [name].
  static Future<List<ContactInfo>> removeContact(String name) async {
    var contacts = await getContacts();
    contacts.removeWhere((item) => item.name == name);
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
    await storage.write(key: _contactsKey, value: data);
  }
}

class ContactInfo {
  String name;
  String accountId;

  ContactInfo(this.name, this.accountId);

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        json['name'],
        json['accountId'],
      );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'accountId': accountId,
    };
  }
}
