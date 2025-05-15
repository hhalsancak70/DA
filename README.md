# Restoran Yönetim Sistemi

> ⚠️ **ÖNEMLİ NOT**: Bu proje özel bir projedir ve tüm hakları saklıdır. İzinsiz kullanımı, dağıtımı veya kopyalanması yasaktır.

Bu proje, restoranlar için geliştirilmiş kapsamlı bir yönetim sistemidir. Flutter kullanılarak geliştirilmiş olan bu uygulama, restoran yöneticilerine, garsonlara ve mutfak personeline özel arayüzler sunmaktadır.

## 🚀 Özellikler

### Admin Paneli
- Kullanıcı yönetimi (Garson, Mutfak, Admin ekleme/düzenleme/silme)
- Sipariş takibi ve yönetimi
- Masa yönetimi
- Profil düzenleme
- Detaylı raporlama

### Garson Arayüzü
- Masa yönetimi
- Sipariş alma
- Sipariş durumu takibi
- Müşteri hizmetleri

### Mutfak Arayüzü
- Sipariş görüntüleme
- Sipariş durumu güncelleme
- Hazırlanan siparişleri işaretleme

## 🛠️ Teknolojiler

- **Frontend**: Flutter
- **Backend**: Node.js
- **Veritabanı**: MySQL
- **State Management**: Provider
- **HTTP Client**: http package
- **Local Storage**: SharedPreferences

## 📱 Ekran Görüntüleri

### Giriş ve Kayıt
<img src="./assets/screenshots/loginscreen.png" width="300" alt="Giriş Ekranı">
*Kullanıcı giriş ekranı*

<img src="./assets/screenshots/register%20secreen.png" width="300" alt="Kayıt Ekranı">
*Yeni kullanıcı kayıt ekranı*

### Admin Paneli
<img src="./assets/screenshots/admin-panel.png" width="300" alt="Admin Paneli">
*Admin paneli ana ekranı - Kullanıcı yönetimi ve sipariş takibi*

### Personel Arayüzü
<img src="./assets/screenshots/mainscreenforstaff.png" width="300" alt="Personel Ana Ekranı">
*Personel ana ekranı - Masa ve sipariş yönetimi*

<img src="./assets/screenshots/orderscreen.png" width="300" alt="Sipariş Ekranı">
*Sipariş alma ve düzenleme ekranı*

### Menü ve Profil
<img src="./assets/screenshots/menuscreen.png" width="300" alt="Menü Ekranı">
*Menü görüntüleme ekranı*

<img src="./assets/screenshots/edituserinfo.png" width="300" alt="Profil Düzenleme">
*Kullanıcı profil düzenleme ekranı*

## 🚀 Kurulum

### 1. Veritabanı Kurulumu

1. MySQL veritabanı sunucunuzu başlatın
2. Yeni bir veritabanı oluşturun:
```sql
CREATE DATABASE restoran_yonetim;
```
3. Proje dizinindeki SQL dosyalarını sırasıyla çalıştırın:
```bash
mysql -u root -p restoran_yonetim < digiadi.sql
mysql -u root -p restoran_yonetim < add_kitchen_role.sql
```

### 2. Backend Kurulumu

1. Backend klasörüne gidin:
```bash
cd backend
```

2. Bağımlılıkları yükleyin:
```bash
npm install
```

3. `.env` dosyasını oluşturun ve veritabanı bağlantı bilgilerinizi ekleyin:
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=restoran_yonetim
JWT_SECRET=your_jwt_secret
```

4. Backend sunucusunu başlatın:
```bash
npm start
```

### 3. Frontend Kurulumu

1. Projeyi klonlayın:
```bash
git clone [proje-url]
```

2. Proje dizinine gidin:
```bash
cd restoran-yonetim
```

3. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

4. `lib/config/api_config.dart` dosyasını düzenleyin ve backend API URL'sini ayarlayın:
```dart
const String baseUrl = 'http://your-backend-url:3000';
```

5. Uygulamayı çalıştırın:
```bash
flutter run
```

## 🔧 Gereksinimler

### Backend Gereksinimleri
- Node.js (v14 veya üzeri)
- MySQL (v8.0 veya üzeri)
- npm veya yarn

### Frontend Gereksinimleri
- Flutter SDK (2.0.0 veya üzeri)
- Dart SDK (2.12.0 veya üzeri)
- Android Studio / VS Code
- Android SDK veya iOS geliştirme araçları

## 👥 Kullanıcı Rolleri

### Admin
- Tüm kullanıcıları yönetebilir
- Siparişleri görüntüleyebilir ve yönetebilir
- Masaları kapatabilir
- Sistem ayarlarını yapabilir

### Garson
- Masa yönetimi yapabilir
- Sipariş alabilir
- Sipariş durumlarını takip edebilir

### Mutfak
- Siparişleri görüntüleyebilir
- Sipariş durumlarını güncelleyebilir
- Hazırlanan siparişleri işaretleyebilir

## 🔐 Güvenlik

- JWT tabanlı kimlik doğrulama
- Rol tabanlı yetkilendirme
- Şifreli veri iletişimi
- Güvenli oturum yönetimi

## 📝 Lisans

Bu proje, Abdullah Gül Üniversitesi Bilgisayar Mühendisliği Bölümü öğrencileri tarafından geliştirilmiştir. Tüm hakları saklıdır.

- Projenin kaynak kodları, tasarımı ve içeriği telif hakkı ile korunmaktadır
- İzinsiz kullanım, dağıtım veya kopyalama yasaktır
- Proje sadece portfolyo ve CV amaçlı paylaşılabilir
- Ticari kullanım için yazarlardan yazılı izin alınması gerekmektedir

## 👨‍💻 Geliştirici Ekibi

Bu proje, Abdullah Gül Üniversitesi Bilgisayar Mühendisliği Bölümü öğrencileri tarafından geliştirilmiştir:

- Ahmet Karauz
- Ekin Tekin
- Hüseyin Alsancak
- Dilhan Deniz
- Selahattin Eyyup Yağmur

## 📞 İletişim ve İzin

Projeyi görüntülemek, incelemek veya kullanmak için lütfen aşağıdaki e-posta adreslerinden biriyle iletişime geçin:

- Ahmet Karauz: ahmet.karauz@agu.edu.tr
- Ekin Tekin: ekin.tekin@agu.edu.tr
- Hüseyin Alsancak: huseyin.alsancak@agu.edu.tr
- Dilhan Deniz: dilhan.deniz@agu.edu.tr
- Selahattin Eyyup Yağmur: selahattin.eyyup.yagmur@agu.edu.tr

## 🔒 Güvenlik ve Erişim

Bu proje private bir repository'de tutulmaktadır. Erişim izni olmayan kişilerin projeyi görüntülemesi, indirmesi veya kullanması yasaktır. İzinsiz erişim girişimleri yasal işlemlere tabi tutulacaktır.
