// routes/users.js
const express = require('express');
const router = express.Router();
const db = require('../db');

// Kullanıcıları role göre getir
router.get('/', async (req, res) => {
  const role = req.query.role;

  if (!role) {
    return res.status(400).json({ error: 'role parametresi gerekli' });
  }

  try {
    const [users] = await db.query(
      'SELECT id, name, email, role, created_at FROM users WHERE role = ?',
      [role]
    );

    res.json(users);

  } catch (err) {
    console.error('Kullanıcı listeleme hatası:', err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Kullanıcı sil
router.delete('/:id', async (req, res) => {
  const userId = req.params.id;

  try {
    const [result] = await db.query('DELETE FROM users WHERE id = ?', [userId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }

    res.json({ message: 'Kullanıcı silindi' });

  } catch (err) {
    console.error('Kullanıcı silme hatası:', err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});


module.exports = router;
