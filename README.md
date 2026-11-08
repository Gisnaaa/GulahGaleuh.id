# GG.ID - Modern E-Commerce Application

Aplikasi toko online lintas platform berbasis **Flutter** dengan desain antarmuka pastel yang modern, terintegrasi dengan backend **PHP + MySQL** yang berjalan di dalam kontainer **Docker**.

**Pembuat:** Agisna Rizkia (240102008)
**Link :** https://youtu.be/9TgaYvaiaEg

---

## Fitur

**Pengguna**
- Daftar akun, login, dan logout dengan pemulihan sesi otomatis
- Katalog produk, pencarian, dan pengelolaan produk favorit
- Detail produk, keranjang belanja (*cart*), dan manajemen kuantiti
- Navigasi layar mulus menggunakan GoRouter dan struktur *Provider*


## Teknologi

| Bagian | Teknologi |
|---|---|
| Aplikasi Frontend | Flutter, Provider, go_router, shared_preferences, dio |
| Backend | PHP (REST API) |
| Database | MySQL |
| Infrastruktur | Docker & Docker Compose |

---

## Struktur Folder

App_Gis/
├── android/           # Konfigurasi native Android
├── ios/               # Konfigurasi native iOS
├── lib/
│   ├── models/        # Model data (Product, User, Cart, dll)
│   ├── navigation/    # MainShell dan navigasi bawah
│   ├── providers/     # State management (Auth, Product, Cart, Favorite)
│   ├── screens/       # Halaman aplikasi (Welcome, Login, Register, Home, Detail, dll)
│   ├── theme/         # Tema warna dan gaya tampilan (AppTheme)
│   └── main.dart      # Titik masuk utama aplikasi & GoRouter
├── backend/           # Layanan API PHP & skema database MySQL
└── pubspec.yaml       # Konfigurasi package & dependensi Flutter

---

## Cara Pasang & Menjalankan

### 1. Backend (Docker)
1. Salin folder backend Anda ke dalam direktori project `App_Gis/backend`.
2. Pastikan **Docker Desktop** di komputer Anda dalam keadaan aktif.
3. Masuk ke folder backend di terminal:
   cd backend
4. Jalankan container Docker:
   docker compose up -d
5. Pastikan layanan PHP dan database MySQL berjalan dengan normal melalui aplikasi Docker Desktop.

### 2. Flutter
1. Kembali ke folder utama project `App_Gis`.
2. Ambil seluruh dependensi package:
   flutter pub get
3. Jalankan aplikasi di perangkat Anda (Emulator, Chrome, atau Windows/HP Asli):
   flutter run

---

## Pemecahan Masalah

- **Aplikasi tidak terhubung ke server backend:** 
  Pastikan kontainer Docker di komputer Anda menyala dan alamat *Base URL* (API endpoint) di dalam konfigurasi Flutter sudah sesuai dengan alamat IP lokal atau port Docker yang aktif.
- **Error dependensi saat `flutter pub get`:**
  Pastikan versi Flutter Anda sudah kompatibel dengan daftar *package* yang ada di dalam `pubspec.yaml`.

---

## Catatan
Project ini dikembangkan untuk memenuhi kebutuhan pengembangan aplikasi lintas platform dengan arsitektur bersih (*clean architecture*).