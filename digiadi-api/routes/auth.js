const express = require('express');
const router = express.Router();
const db = require('../db');
const bcrypt = require('bcrypt');

// Giriş yap (şifresiz sürüm)
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email ve şifre zorunludur' });
  }

  try {
    const [users] = await db.query(
      'SELECT * FROM users WHERE email = ? AND password = ?',
      [email, password]
    );

    if (users.length === 0) {
      return res.status(401).json({ error: 'E-posta veya şifre yanlış' });
    }

    const user = users[0];

    res.json({
      message: 'Giriş başarılı',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });

  } catch (err) {
    console.error('Giriş hatası:', err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});

// Yeni kullanıcı ekle (admin tarafından)
router.post('/register', async (req, res) => {
  const { name, email, password, role } = req.body;

  if (!name || !email || !password || !role) {
    return res.status(400).json({ error: 'Tüm alanlar zorunludur' });
  }

  try {
    // Email benzersiz mi kontrol et
    const [existing] = await db.query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (existing.length > 0) {
      return res.status(409).json({ error: 'Bu email zaten kayıtlı' });
    }

    // Kullanıcıyı ekle
    const [result] = await db.query(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
      [name, email, password, role]
    );

    res.status(201).json({
      message: 'Kullanıcı başarıyla oluşturuldu',
      user_id: result.insertId
    });

  } catch (err) {
    console.error('Kayıt hatası:', err);
    res.status(500).json({ error: 'Sunucu hatası' });
  }
});


module.exports = router;
