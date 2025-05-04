const express = require('express');
const cors = require('cors');
const pool = require('./db');
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

const app = express();
app.use(cors());
app.use(express.json());

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// middleware - verify Firebase token + attach UID to request
app.use(async (req, res, next) => {
  const idToken = req.headers.authorization;

  if (!idToken) {
    return res.status(401).json({ error: 'Missing token' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.firebaseUid = decodedToken.uid;

    // ensure user exists in your own users table
    const result = await pool.query('SELECT * FROM users WHERE firebase_uid = $1', [req.firebaseUid]);
    if (result.rows.length === 0) {
      await pool.query('INSERT INTO users (firebase_uid, email) VALUES ($1, $2)', [
        decodedToken.uid,
        decodedToken.email || null,
      ]);
    }

    next();
  } catch (error) {
    console.error('Auth Middleware Error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
});

//fetch
app.get('/passwords', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM passwords WHERE firebase_uid = $1 ORDER BY id ASC', [req.firebaseUid]);
    res.json(result.rows);
  } catch (err) {
    console.error('DB Query Error:', err);
    res.status(500).json({ error: err.message });
  }
});

//delete
app.delete('/passwords/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      'DELETE FROM passwords WHERE id = $1 AND firebase_uid = $2',
      [id, req.firebaseUid]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Password not found or not owned by user' });
    }
    res.json({ message: 'Password deleted successfully' });
  } catch (err) {
    console.error('DB Delete Error:', err);
    res.status(500).json({ error: err.message });
  }
});

//create
app.post('/passwords', async (req, res) => {
  const { site, username, password, logoUrl } = req.body;
  try {
    const result = await pool.query(
      'INSERT INTO passwords (site, username, password, logourl, firebase_uid) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [site, username, password, logoUrl, req.firebaseUid]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('DB Insert Error:', err);
    res.status(500).json({ error: err.message });
  }
});

//update
app.put('/passwords/:id', async (req, res) => {
  const { id } = req.params;
  const { site, username, password, logoUrl } = req.body;
  try {
    const result = await pool.query(
      'UPDATE passwords SET site = $1, username = $2, password = $3, logourl = $4 WHERE id = $5 AND firebase_uid = $6 RETURNING *',
      [site, username, password, logoUrl, id, req.firebaseUid]
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

// GET/CREATE current user (Login handler)
app.get('/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users WHERE firebase_uid = $1', [req.firebaseUid]);

    if (result.rows.length === 0) {
      // Create user if doesn't exist
      const userInfo = await admin.auth().getUser(req.firebaseUid);
      const email = userInfo.email || null;

      const insertResult = await pool.query(
        'INSERT INTO users (firebase_uid, email) VALUES ($1, $2) RETURNING *',
        [req.firebaseUid, email]
      );
      return res.status(201).json(insertResult.rows[0]);
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('User Fetch/Create Error:', err);
    res.status(500).json({ error: err.message });
  }
});


//for the website_logos table
app.get('/logos', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM website_logos');
    res.json(result.rows);
  } catch (err) {
    console.error('DB Logos Fetch Error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.listen(3000, () => console.log('API running at http://localhost:3000'));
