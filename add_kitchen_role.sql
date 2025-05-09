-- MySQL tablosundaki role ENUM değerini güncelleme scripti
USE digiadi;

-- Önce mevcut users tablosunun yapısını değiştirip ENUM'a 'mutfak' rolünü ekleyelim
ALTER TABLE users 
MODIFY COLUMN role ENUM('admin', 'garson', 'mutfak') NOT NULL;

-- Kontrol için tabloyu görüntüleyelim
SHOW CREATE TABLE users;

-- Örnek bir mutfak rolünde kullanıcı ekleyelim
INSERT INTO users (name, email, password, role)
VALUES ('Mehmet Aşçı', 'mutfak@example.com', '123456', 'mutfak'); 