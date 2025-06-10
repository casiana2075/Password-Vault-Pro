const express = require('express');
const cors = require('cors');
const pool = require('./db');
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const https = require('https');
const fs = require('fs');
const EncryptionHelper = require('./encryptionHelper'); // Import the helper

const app = express();
app.use(cors());
app.use(express.json());

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Get a Firestore instance
const db = admin.firestore();

// Middleware - verify Firebase token + attach UID to request
app.use(async (req, res, next) => {
  const idToken = req.headers.authorization;

  if (!idToken) {
    return res.status(401).json({ error: 'Missing token' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.firebaseUid = decodedToken.uid;
    next();
  } catch (error) {
    console.error('Auth Middleware Error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
});

// Helper function to get or create AES key for a user (now using Firestore)
async function getUserAESKey(firebaseUid) {
  const userDocRef = db.collection('users').doc(firebaseUid);
  const userDoc = await userDocRef.get();

  let aesKey;
  if (userDoc.exists && userDoc.data().aesKey) {
    aesKey = userDoc.data().aesKey;
  } else {
    aesKey = EncryptionHelper.generateRandomAESKey();
    // Use merge: true to avoid overwriting other potential user data
    await userDocRef.set({ aesKey: aesKey }, { merge: true });
  }
  return aesKey;
}

// Fetch passwords (decrypting on the backend using key from Firestore)
app.get('/passwords', async (req, res) => {
  try {
    const aesKey = await getUserAESKey(req.firebaseUid); // Get the user's AES key from Firestore
    const result = await pool.query('SELECT * FROM passwords WHERE firebase_uid = $1 ORDER BY id ASC', [req.firebaseUid]);

    // Decrypt passwords before sending to frontend
    const decryptedPasswords = result.rows.map(row => {
      let decryptedPw = '';
      if (row.password) {
        try {
          decryptedPw = EncryptionHelper.decryptText(row.password, aesKey, req.firebaseUid);
        } catch (e) {
          console.warn('Decryption failed, possible legacy format for row ID:', row.id, e.message);
          decryptedPw = ''; // Fallback to empty string or handle legacy differently
        }
      }
      return { ...row, password: decryptedPw }; // Replace encrypted with decrypted
    });

    res.json(decryptedPasswords);
  } catch (err) {
    console.error('DB Query Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Create password (encrypting on the backend using key from Firestore)
app.post('/passwords', async (req, res) => {
  const { site, username, password: rawPassword, logoUrl } = req.body;
  try {
    const aesKey = await getUserAESKey(req.firebaseUid); // Get the user's AES key from Firestore
    const encryptedPassword = EncryptionHelper.encryptText(rawPassword, aesKey, req.firebaseUid); // Encrypt on backend

    const result = await pool.query(
      'INSERT INTO passwords (site, username, password, logourl, firebase_uid) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [site, username, encryptedPassword, logoUrl, req.firebaseUid]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('DB Insert Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Update password (encrypting on the backend using key from Firestore)
app.put('/passwords/:id', async (req, res) => {
  const { id } = req.params;
  const { site, username, password: newRawPassword, logoUrl } = req.body;
  try {
    const aesKey = await getUserAESKey(req.firebaseUid); // Get the user's AES key from Firestore
    const encryptedPassword = EncryptionHelper.encryptText(newRawPassword, aesKey, req.firebaseUid); // Encrypt on backend

    const result = await pool.query(
      'UPDATE passwords SET site = $1, username = $2, password = $3, logourl = $4 WHERE id = $5 AND firebase_uid = $6 RETURNING *',
      [site, username, encryptedPassword, logoUrl, id, req.firebaseUid]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Password not found or not owned by user' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('DB Update Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// GET/CREATE current user (Login handler) - adjust this as the AES key is now in Firestore
app.get('/users', async (req, res) => {
  try {

    const result = await pool.query('SELECT * FROM users WHERE firebase_uid = $1', [req.firebaseUid]);

    if (result.rows.length === 0) {
      const userInfo = await admin.auth().getUser(req.firebaseUid);
      const email = userInfo.email || null;

      const insertResult = await pool.query(
        'INSERT INTO users (firebase_uid, email) VALUES ($1, $2) RETURNING *',
        [req.firebaseUid, email]
      );
      // Ensure AES key is generated/fetched on first login, which getUserAESKey already handles.
      await getUserAESKey(req.firebaseUid); // This ensures the key is set up in Firestore
      return res.status(201).json(insertResult.rows[0]);
    }

    // Ensure AES key is generated/fetched even for existing users, which getUserAESKey already handles.
    await getUserAESKey(req.firebaseUid); // This ensures the key is set up in Firestore
    res.json(result.rows[0]);
  } catch (err) {
    console.error('User Fetch/Create Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// DELETE user and their associated data
app.delete('/users/:uid', async (req, res) => {
  const firebaseUid = req.firebaseUid;
  const { uid } = req.params;

  // Only allow a user to delete their own account
  if (firebaseUid !== uid) {
    return res.status(403).json({ message: 'Forbidden: UID mismatch' });
  }

  try {
    // First delete all passwords
    await pool.query('DELETE FROM passwords WHERE firebase_uid = $1', [firebaseUid]);

    // Then delete the user
    const result = await pool.query('DELETE FROM users WHERE firebase_uid = $1', [firebaseUid]);

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ message: 'User and associated data deleted successfully' });
  } catch (err) {
    console.error('DB Delete Error:', err);
    res.status(500).json({ error: err.message });
  }
});


// Delete password
app.delete('/passwords/:id', async (req, res) => {
  const { id } = req.params;
  const firebaseUid = req.firebaseUid; // Get the UID from the authenticated request

  try {
    const result = await pool.query(
      'DELETE FROM passwords WHERE id = $1 AND firebase_uid = $2',
      [id, firebaseUid]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Password not found or not owned by user' });
    }
    res.status(200).json({ message: 'Password deleted successfully' });
  } catch (err) {
    console.error('DB Delete Error:', err);
    res.status(500).json({ error: err.message });
  }
});


// Fetch website logos
app.get('/logos', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM website_logos');
    res.json(result.rows);
  } catch (err) {
    console.error('DB Logos Fetch Error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Load SSL certificates
const privateKey = fs.readFileSync('./certs/key.pem', 'utf8');
const certificate = fs.readFileSync('./certs/cert.pem', 'utf8');
const credentials = { key: privateKey, cert: certificate };

// Create HTTPS server
const httpsServer = https.createServer(credentials, app);

httpsServer.listen(3001, () => {
  console.log('API running at https://localhost:3001');
});