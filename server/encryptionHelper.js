// utils/encryptionHelper.js
const crypto = require('crypto');

class EncryptionHelper {
  static generateRandomAESKey() {
    return crypto.randomBytes(32).toString('base64url'); // 32 bytes for AES-256
  }

  static encryptText(plainText, base64Key) {
    const key = Buffer.from(base64Key, 'base64url');
    const iv = crypto.randomBytes(16); // 16 bytes for AES-256 CBC

    const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
    let encrypted = cipher.update(plainText, 'utf8', 'base64');
    encrypted += cipher.final('base64');

    // Combine IV + ciphertext for storage/transmission
    return iv.toString('base64') + ':' + encrypted;
  }

  static decryptText(encryptedText, base64Key) {
    const key = Buffer.from(base64Key, 'base64url');
    const parts = encryptedText.split(':');
    const iv = Buffer.from(parts[0], 'base64');
    const ciphertext = parts[1];

    const decipher = crypto.createDecipheriv('aes-256-cbc', key, iv);
    let decrypted = decipher.update(ciphertext, 'base64', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  }
}

module.exports = EncryptionHelper;