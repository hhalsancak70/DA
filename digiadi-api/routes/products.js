// routes/products.js
const express = require('express');
const router = express.Router();
const db = require('../db');

// Tüm ürünleri getir
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query(`
      SELECT 
        p.id, p.name, p.price, p.image_path, c.name AS category_name
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      ORDER BY p.category_id ASC, p.name ASC
    `);

    res.json(rows);
  } catch (error) {
    console.error('Ürünler alınırken hata:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

module.exports = router;
