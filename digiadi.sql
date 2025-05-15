CREATE DATABASE digiadi CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE digiadi;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  role ENUM('admin', 'garson') NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tables (
  id INT PRIMARY KEY, -- masa numarası (1-15 gibi)
  is_active BOOLEAN DEFAULT FALSE,
  is_ready BOOLEAN DEFAULT FALSE,
  created_at DATETIME,
  completed_at DATETIME
);

CREATE TABLE orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  table_id INT,
  is_ready BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME,
  FOREIGN KEY (table_id) REFERENCES tables(id)
);

CREATE TABLE order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT,
  name VARCHAR(100),
  price DECIMAL(10,2),
  quantity INT,
  category_id VARCHAR(50),
  waiter_id INT,
  waiter_name VARCHAR(100),
  FOREIGN KEY (order_id) REFERENCES orders(id),
  FOREIGN KEY (waiter_id) REFERENCES users(id)
);

CREATE TABLE categories (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE products (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  image_path VARCHAR(255),
  category_id VARCHAR(50),
  FOREIGN KEY (category_id) REFERENCES categories(id)
);

INSERT INTO categories (id, name) VALUES
(1, 'Kahvaltilar'),
(2, 'Tavalar'),
(3, 'Yoresel Yemekler'),
(4, 'Borekler'),
(5, 'Tostlar'),
(6, 'Menuler'),
(7, 'Gozlemeler'),
(8, 'Icecekler');

INSERT INTO products (id, name, price, image_path, category_id) VALUES
(1, 'Sucuklu Yumurta', 180, 'assets/images/pacanga.png', 2),
(2, 'Pastirmali Yumurta', 210, 'assets/images/pacanga.png', 2),
(3, 'Menemen', 180, 'assets/images/pacanga.png', 2),
(4, 'Kavurmali Yumurta', 210, 'assets/images/pacanga.png', 2),
(5, 'Pacanga Boregi', 165, 'assets/images/pacanga.png', 4),
(6, 'Kalem Boregi', 145, 'assets/images/pacanga.png', 4),
(7, 'Bazlama Tost', 125, 'assets/images/pacanga.png', 6),
(8, 'Gozleme', 155, 'assets/images/pacanga.png', 7),
(9, 'Tepsi Kahvalti', 600, 'assets/images/pacanga.png', 1),
(10, 'Kahvalti Tabagi', 250, 'assets/images/pacanga.png', 1),
(11, 'Serpme Kahvalti', 350, 'assets/images/pacanga.png', 1),
(12, 'Pacanga Pide Tost', 155, 'assets/images/pacanga.png', 5),
(13, 'Aglayan Tost', 165, 'assets/images/pacanga.png', 5);

INSERT INTO users (id, name, email, password, role)
VALUES (1, 'Ahmet', 'ahmet@example.com', 'dummyhash', 'garson');

INSERT INTO users (name, email, password, role)
VALUES ('Yusuf', 'yusuf@example.com', '123456', 'admin');
