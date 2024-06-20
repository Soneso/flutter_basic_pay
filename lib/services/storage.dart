// Copyright 2024 The Flutter Basic Pay App Authors. All rights reserved.
// Use of this source code is governed by a license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import "package:pointycastle/export.dart";
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

// AES key size
const keySize = 32; // 32 byte key for AES-256
const iterationCount = 1000;

class AesHelper {
  static const cbcMode = 'CBC';
  static const cfbMode = 'CFB';

  static Uint8List deriveKey(dynamic password,
      {String salt = '',
      int iterationCount = iterationCount,
      int derivedKeyLength = keySize}) {
    if (password == null || password.isEmpty) {
      throw ArgumentError('password must not be empty');
    }

    if (password is String) {
      password = createUInt8ListFromString(password);
    }

    Uint8List saltBytes = createUInt8ListFromString(salt);
    Pbkdf2Parameters params =
        Pbkdf2Parameters(saltBytes, iterationCount, derivedKeyLength);
    KeyDerivator keyDerivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    keyDerivator.init(params);

    return keyDerivator.process(password);
  }

  static Uint8List pad(Uint8List src, int blockSize) {
    var pad = PKCS7Padding();
    pad.init(null);

    int padLength = blockSize - (src.length % blockSize);
    var out = Uint8List(src.length + padLength)..setAll(0, src);
    pad.addPadding(out, src.length);

    return out;
  }

  static Uint8List unpad(Uint8List src) {
    var pad = PKCS7Padding();
    pad.init(null);

    int padLength = pad.padCount(src);
    int len = src.length - padLength;

    return Uint8List(len)..setRange(0, len, src);
  }

  static String encrypt(String password, String plaintext,
      {String mode = cbcMode}) {
    Uint8List derivedKey = deriveKey(password);
    KeyParameter keyParam = KeyParameter(derivedKey);
    BlockCipher aes = AESEngine();

    var rnd = FortunaRandom();
    rnd.seed(keyParam);
    Uint8List iv = rnd.nextBytes(aes.blockSize);

    BlockCipher cipher;
    ParametersWithIV params = ParametersWithIV(keyParam, iv);
    switch (mode) {
      case cbcMode:
        cipher = CBCBlockCipher(aes);
        break;
      case cfbMode:
        cipher = CFBBlockCipher(aes, aes.blockSize);
        break;
      default:
        throw ArgumentError('incorrect value of the "mode" parameter');
    }
    cipher.init(true, params);

    Uint8List textBytes = createUInt8ListFromString(plaintext);
    Uint8List paddedText = pad(textBytes, aes.blockSize);
    Uint8List cipherBytes = _processBlocks(cipher, paddedText);
    Uint8List cipherIvBytes = Uint8List(cipherBytes.length + iv.length)
      ..setAll(0, iv)
      ..setAll(iv.length, cipherBytes);

    return base64.encode(cipherIvBytes);
  }

  static String decrypt(String password, String ciphertext,
      {String mode = cbcMode}) {
    Uint8List derivedKey = deriveKey(password);
    KeyParameter keyParam = KeyParameter(derivedKey);
    BlockCipher aes = AESEngine();

    Uint8List cipherIvBytes = base64.decode(ciphertext);
    Uint8List iv = Uint8List(aes.blockSize)
      ..setRange(0, aes.blockSize, cipherIvBytes);

    BlockCipher cipher;
    ParametersWithIV params = ParametersWithIV(keyParam, iv);
    switch (mode) {
      case cbcMode:
        cipher = CBCBlockCipher(aes);
        break;
      case cfbMode:
        cipher = CFBBlockCipher(aes, aes.blockSize);
        break;
      default:
        throw ArgumentError('incorrect value of the "mode" parameter');
    }
    cipher.init(false, params);

    int cipherLen = cipherIvBytes.length - aes.blockSize;
    Uint8List cipherBytes = Uint8List(cipherLen)
      ..setRange(0, cipherLen, cipherIvBytes, aes.blockSize);
    Uint8List paddedText = _processBlocks(cipher, cipherBytes);
    Uint8List textBytes = unpad(paddedText);

    return String.fromCharCodes(textBytes);
  }

  static Uint8List _processBlocks(BlockCipher cipher, Uint8List inp) {
    var out = Uint8List(inp.lengthInBytes);

    for (var offset = 0; offset < inp.lengthInBytes;) {
      var len = cipher.processBlock(inp, offset, out, offset);
      offset += len;
    }

    return out;
  }

  static Uint8List createUInt8ListFromString(String s) {
    var ret = Uint8List(s.length);
    for (var i = 0; i < s.length; i++) {
      ret[i] = s.codeUnitAt(i);
    }
    return ret;
  }
}
