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

app.listen(3000, () => console.log('API running at http://localhost:3000'));
