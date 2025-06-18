const crypto = require('crypto');

class EncryptionHelper {
  static generateRandomAESKey() {
    return crypto.randomBytes(32).toString('base64url'); // 32 bytes for AES-256
  }

  // GCM Encryption method
  static encryptTextGCM(plainText, base64Key, firebaseUid) {
    const key = Buffer.from(base64Key, 'base64url');
    const iv = crypto.randomBytes(12); // GCM typically uses 12-byte IVs
    const salt = Buffer.from(firebaseUid, 'utf8');
    const derivedKey = crypto.pbkdf2Sync(key, salt, 100000, 32, 'sha256');

    // Additional authenticated data (AAD)
    const aad = Buffer.from(firebaseUid, 'utf8');

    const cipher = crypto.createCipheriv('aes-256-gcm', derivedKey, iv);
    cipher.setAAD(aad); // Set AAD
    let encrypted = cipher.update(plainText, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    const authTag = cipher.getAuthTag(); // Get the authentication tag

    // Return IV + ciphertext + authTag
    return iv.toString('hex') + ':' + encrypted + ':' + authTag.toString('hex');
  }

  // GCM Decryption method
  static decryptTextGCM(encryptedText, base64Key, firebaseUid) {
    const key = Buffer.from(base64Key, 'base64url');
    const parts = encryptedText.split(':');
    const iv = Buffer.from(parts[0], 'hex');
    const ciphertext = parts[1];
    const authTag = Buffer.from(parts[2], 'hex');
    const salt = Buffer.from(firebaseUid, 'utf8');
    const derivedKey = crypto.pbkdf2Sync(key, salt, 100000, 32, 'sha256');

    // Additional authenticated data (AAD)
    const aad = Buffer.from(firebaseUid, 'utf8');

    try {
      const decipher = crypto.createDecipheriv('aes-256-gcm', derivedKey, iv);
      decipher.setAAD(aad); // Set AAD
      decipher.setAuthTag(authTag); // Set the authentication tag
      let decrypted = decipher.update(ciphertext, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      return decrypted;
    } catch (error) {
      // This error will be thrown if the data has been tampered with or auth tag is invalid
      console.error('Decryption/Auth Tag Mismatch Error:', error.message);
      throw new Error('Invalid or tampered data.'); // Re-throw a custom error
    }
  }
}

module.exports = EncryptionHelper;