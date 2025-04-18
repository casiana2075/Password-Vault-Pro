const express = require('express');
const cors = require('cors');
const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/passwords', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM passwords ORDER BY id ASC');
    res.json(result.rows);
  } catch (err) {
    console.error('DB Query Error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.delete('/passwords/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('DELETE FROM passwords WHERE id = $1', [id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Password not found' });
    }
    res.json({ message: 'Password deleted successfully' });
  } catch (err) {
    console.error('DB Delete Error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.post('/passwords', async (req, res) => {
  const { site, username, password, logoUrl } = req.body;
  const finalLogoUrl = logoUrl;
  try {
    const result = await pool.query(
      'INSERT INTO passwords (site, username, password, logourl) VALUES ($1, $2, $3, $4) RETURNING *',
      [site, username, password, finalLogoUrl]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('DB Insert Error:', err);
    res.status(500).json({ error: err.message });
  }
});

app.put('/passwords/:id', async (req, res) => {
  const { id } = req.params;
  const { site, username, password } = req.body;
  try {
    const result = await pool.query(
      'UPDATE passwords SET site = $1, username = $2, password = $3 WHERE id = $4 RETURNING *',
      [site, username, password, id]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Password not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error('DB Update Error:', err);
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
