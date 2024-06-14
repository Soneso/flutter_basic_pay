import 'dart:convert';

import 'package:flutter_basic_pay/storage/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stellar_wallet_flutter_sdk/stellar_wallet_flutter_sdk.dart'
    as wallet_sdk;
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart' as core_sdk;

class SecureStorage {
  static const _userAddress = 'address';
  static const _userSecretKey = 'secret';
  static const _contactsKey = 'contacts';

  static setUser(wallet_sdk.SigningKeyPair userKeyPair, String pin) async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.write(key: _userAddress, value: userKeyPair.address);
    var encryptedSeed = AesHelper.encrypt(pin, userKeyPair.secretKey);
    await storage.write(key: _userSecretKey, value: encryptedSeed);
  }

  static Future<bool> hasUser() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    var secret = await storage.read(key: _userSecretKey);
    return secret == null ? false : true;
  }

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

  static deleteUserSeed() async {
    const FlutterSecureStorage storage = FlutterSecureStorage();
    await storage.delete(key: _userSecretKey);
  }

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

  static Future<List<ContactInfo>> addContact(ContactInfo contact) async {
    var contacts = await getContacts();
    contacts.removeWhere((item) => item.name == contact.name);
    contacts.add(contact);
    await _saveContacts(contacts);
    return contacts;
  }

  static Future<bool> hasContact(String name) async {
    var contacts = await getContacts();
    return contacts.any((item) => item.name == name);
  }

  static Future<List<ContactInfo>> removeContact(String name) async {
    var contacts = await getContacts();
    contacts.removeWhere((item) => item.name == name);
    await _saveContacts(contacts);
    return contacts;
  }

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
