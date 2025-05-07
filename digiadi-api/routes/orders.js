// routes/orders.js
const express = require('express');
const router = express.Router();
const db = require('../db');

// Sipariş oluştur (bir masaya)
router.post('/', async (req, res) => {
  const { table_id } = req.body;

  if (!table_id) {
    return res.status(400).json({ error: 'table_id zorunlu' });
  }

  try {
    // 1. Masayı aktif hale getir
    await db.query(`
      INSERT INTO tables (id, is_active, is_ready, created_at)
      VALUES (?, TRUE, FALSE, NOW())
      ON DUPLICATE KEY UPDATE 
        is_active = TRUE, 
        is_ready = FALSE, 
        created_at = NOW(),
        completed_at = NULL
    `, [table_id]);

    // 2. Sipariş oluştur
    const [result] = await db.query(`
      INSERT INTO orders (table_id, is_ready, is_active, created_at)
      VALUES (?, FALSE, TRUE, NOW())
    `, [table_id]);

    res.status(201).json({ message: 'Sipariş oluşturuldu', order_id: result.insertId });

  } catch (error) {
    console.error('Sipariş oluşturma hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Siparişe ürün ekle
router.put('/:order_id/items', async (req, res) => {
  const orderId = req.params.order_id;
  const item = req.body;

  const requiredFields = ['name', 'price', 'quantity', 'category_id', 'waiter_id', 'waiter_name'];
  const missing = requiredFields.filter(f => item[f] === undefined);

  if (missing.length > 0) {
    return res.status(400).json({ error: `Eksik alanlar: ${missing.join(', ')}` });
  }

  try {
    await db.query(`
      INSERT INTO order_items (order_id, name, price, quantity, category_id, waiter_id, waiter_name)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [
      orderId,
      item.name,
      item.price,
      item.quantity,
      item.category_id,
      item.waiter_id,
      item.waiter_name
    ]);

    res.status(201).json({ message: 'Ürün eklendi' });

  } catch (error) {
    console.error('Ürün ekleme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Belirli siparişi ve ürünlerini getir
router.get('/:order_id', async (req, res) => {
  const orderId = req.params.order_id;

  try {
    // 1. Siparişi çek
    const [orders] = await db.query(
      `SELECT * FROM orders WHERE id = ?`,
      [orderId]
    );

    if (orders.length === 0) {
      return res.status(404).json({ error: 'Sipariş bulunamadı' });
    }

    const order = orders[0];

    // 2. Ürünleri çek
    const [items] = await db.query(
      `SELECT * FROM order_items WHERE order_id = ?`,
      [orderId]
    );

    // 3. Cevabı birleştir
    res.json({
      order,
      items
    });

  } catch (error) {
    console.error('Sipariş getirme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Siparişi hazır olarak işaretle
router.put('/:order_id/ready', async (req, res) => {
  const orderId = req.params.order_id;

  try {
    const [result] = await db.query(
      `UPDATE orders SET is_ready = TRUE WHERE id = ?`,
      [orderId]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Sipariş bulunamadı' });
    }

    res.json({ message: 'Sipariş hazır olarak işaretlendi' });

  } catch (error) {
    console.error('Hazır işaretleme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Siparişi tamamla (kapat)
router.put('/:order_id/complete', async (req, res) => {
  const orderId = req.params.order_id;

  try {
    // 1. Siparişi kapat
    const [result] = await db.query(`
      UPDATE orders
      SET is_active = FALSE, completed_at = NOW()
      WHERE id = ?
    `, [orderId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Sipariş bulunamadı' });
    }

    // 2. Masayı da kapat (ilgili table_id'yi çekmek gerekebilir)
    const [tableResult] = await db.query(`
      SELECT table_id FROM orders WHERE id = ?
    `, [orderId]);

    if (tableResult.length > 0) {
      const tableId = tableResult[0].table_id;
      await db.query(`
        UPDATE tables
        SET is_active = FALSE, is_ready = FALSE, completed_at = NOW()
        WHERE id = ?
      `, [tableId]);
    }

    res.json({ message: 'Sipariş tamamlandı ve masa kapatıldı' });

  } catch (error) {
    console.error('Sipariş tamamlama hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});


module.exports = router;
