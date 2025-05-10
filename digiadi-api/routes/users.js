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

// Kullanıcı güncelle
router.put('/:id', async (req, res) => {
  const userId = req.params.id;
  const { name, email, password } = req.body;

  if (!name || !email) {
    return res.status(400).json({ error: 'İsim ve email zorunludur' });
  }

  try {
    // Email benzersiz mi kontrol et (kendi email'i hariç)
    const [existing] = await db.query(
      'SELECT id FROM users WHERE email = ? AND id != ?',
      [email, userId]
    );

    if (existing.length > 0) {
      return res.status(409).json({ error: 'Bu email zaten başka bir kullanıcı tarafından kullanılıyor' });
    }

    // Güncelleme sorgusunu hazırla
    let query = 'UPDATE users SET name = ?, email = ?';
    let params = [name, email];

    // Eğer şifre varsa ekle
    if (password) {
      query += ', password = ?';
      params.push(password);
    }

    query += ' WHERE id = ?';
    params.push(userId);

    const [result] = await db.query(query, params);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }

    res.json({ message: 'Kullanıcı güncellendi' });

  } catch (err) {
    console.error('Kullanıcı güncelleme hatası:', err);
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
