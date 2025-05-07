// server.js
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const productRoutes = require('./routes/products');
const categoryRoutes = require('./routes/categories');
const orderRoutes = require('./routes/orders');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');

const app = express();

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use('/products', productRoutes);
app.use('/categories', categoryRoutes);
app.use('/orders', orderRoutes);
app.use('/auth', authRoutes);
app.use('/users', userRoutes);

// Basit test route
app.get('/', (req, res) => {
  res.send('DigiAdi API çalışıyor.');
});

// Dinleme
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Sunucu http://localhost:${PORT} adresinde çalışıyor`);
});
