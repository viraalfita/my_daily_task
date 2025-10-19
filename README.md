# Task Management App 

Aplikasi **manajemen tugas harian** dengan tampilan modern, ringan, dan berjalan **sepenuhnya offline** — tanpa koneksi internet atau server eksternal.

<img width="1600" height="1200" alt="dailytask" src="https://github.com/user-attachments/assets/ac7b1c27-a112-4599-a1a3-2c9213200cf4" />


---

## 🚀 Fitur Utama

* 📅 **Lihat Tugas Berdasarkan Tanggal**
  Navigasi mudah menggunakan *horizontal date picker* untuk menampilkan tugas sesuai hari yang dipilih.

* 🔍 **Pencarian Tugas**
  Cari tugas dengan cepat berdasarkan nama atau isi deskripsi.

* ✅ **Tandai Tugas Selesai**
  Gunakan *checkbox toggle* untuk menandai tugas yang sudah dikerjakan.

* ✏️ **Edit & Ubah Profil Pengguna**
  Ganti nama pengguna dan foto profil yang disimpan langsung di penyimpanan lokal perangkat.

* 🔔 **Notifikasi Pengingat Otomatis**
  Fitur *local notification* untuk mengingatkan kamu terhadap tugas mendatang — bahkan saat aplikasi tertutup.

* 💾 **Penyimpanan Offline Penuh**
  Semua data tugas dan profil disimpan menggunakan **local storage (SharedPreferences / Hive / SQLite)**, sehingga tetap aman dan tersedia tanpa koneksi internet.

* 🗑️ **Kelola Tugas dengan Mudah**
  Tambah, edit, dan hapus tugas langsung dari tampilan utama.

* 🎨 **Desain Responsif & Modern**
  Tampilan elegan dengan warna utama **amber**, ringan dan nyaman di semua ukuran layar.

* 📱 **Cross-Platform Support**
  Berjalan lancar di **Android** dan **iOS**.

---

## 🧩 Teknologi yang Digunakan

* **Framework:** Flutter (Dart)
* **Local Storage:** SharedPreferences
* **Date Formatting:** Intl
* **Notifications:** flutter_local_notifications
* **UI Framework:** Material Design

---

## 💾 Mode Operasi Offline

Tidak memerlukan backend atau koneksi internet.
Semua data tugas, status, dan profil pengguna tersimpan langsung di penyimpanan lokal perangkat.

Keuntungan:

* 🚀 Aplikasi cepat & ringan
* 🔒 Data tetap tersimpan walau aplikasi ditutup
* 🌍 Dapat digunakan di mana saja tanpa koneksi

---

## ⚙️ Instalasi

* Flutter SDK (versi stable terbaru)
* Dart SDK
* Android Studio / Xcode
* Emulator atau perangkat fisik

### Langkah-Langkah

1. Clone repository:

   ```bash
   git clone https://github.com/yourusername/task-app-flutter.git
   cd task-app-flutter
   ```

2. Install dependency:

   ```bash
   flutter pub get
   ```

3. Jalankan aplikasi:

   ```bash
   flutter run
   ```

---

## 🖥️ Komponen Utama

### 🏠 Home Screen

* Menampilkan daftar tugas berdasarkan tanggal
* Fitur pencarian dan tanda selesai
* Tombol tambah tugas baru

### 👤 Profile Screen 

* Ubah nama dan foto profil pengguna
* Disimpan langsung ke penyimpanan lokal

### 🔔 Notification Service 

* Menjadwalkan notifikasi tugas berdasarkan deadline
* Notifikasi tetap muncul meskipun aplikasi ditutup
