// routes/categories.js
const express = require('express');
const router = express.Router();
const db = require('../db');

// Tüm kategorileri getir
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT id, name FROM categories ORDER BY id ASC
    `);
    res.json(rows);
  } catch (error) {
    console.error('Kategori hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

module.exports = router;
