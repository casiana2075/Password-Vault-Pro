import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:math';

class EncryptionHelper {
  // Generate random AES 256-bit key (32 bytes)
  static String generateRandomAESKey() {
    final rand = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => rand.nextInt(256));
    return base64UrlEncode(keyBytes);
  }

  static String encryptText(String plainText, String base64Key) {
    final key = encrypt.Key(base64Url.decode(base64Key));
    final iv = encrypt.IV.fromSecureRandom(16); // random IV
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // combine IV + ciphertext
    final combined = iv.bytes + encrypted.bytes;

    return base64Encode(combined);
  }

  static String decryptText(String encryptedText, String base64Key) {
    final key = encrypt.Key(base64Url.decode(base64Key));
    final combinedBytes = base64Decode(encryptedText);

    // extract IV (first 16 bytes)
    final iv = encrypt.IV(combinedBytes.sublist(0, 16));
    final ciphertext = combinedBytes.sublist(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypt.Encrypted(ciphertext);

    return encrypter.decrypt(encrypted, iv: iv);
  }

}
