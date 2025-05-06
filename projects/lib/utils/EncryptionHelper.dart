import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  // Generate a 32-byte AES key from user password
  static encrypt.Key generateKeyFromPassword(String password, String salt) {
    final keyBytes = sha256.convert(utf8.encode(password + salt)).bytes;
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  static String encryptText(String plainText, encrypt.Key key) {
    final iv = encrypt.IV.fromLength(16); // Use random IVs in production and store them too
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return base64.encode(iv.bytes + encrypted.bytes); // Store IV + encrypted
  }

  static String decryptText(String encryptedText, encrypt.Key key) {
    final raw = base64.decode(encryptedText);
    final iv = encrypt.IV(Uint8List.fromList(raw.sublist(0, 16)));
    final encryptedBytes = raw.sublist(16);
    final encrypted = encrypt.Encrypted(Uint8List.fromList(encryptedBytes));
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
