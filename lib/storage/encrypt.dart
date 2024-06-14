import 'dart:convert';
import 'dart:typed_data';
import "package:pointycastle/export.dart";

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
    KeyDerivator keyDerivator =
    PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
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