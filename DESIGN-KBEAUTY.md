# Panduan Estetika Desain & Standardisasi Responsif (K-Beauty System)

Dokumen ini merupakan acuan utama untuk seluruh standar UI/UX, tata letak responsif (mobile & tablet), tema warna, dan perilaku interaktif pada sistem K-Beauty (Web Dashboard & Mobile App).

---

## 1. Tema Warna & Estetika (UI/UX)

Sistem K-Beauty dirancang dengan estetika premium yang bersih, modern, dan feminin untuk menyelaraskan dengan industri kecantikan/salon.

- **Warna Utama (Primary Color)**: Menggunakan palet bernuansa **Pink-primary** (seperti soft pink, rose, atau pastel pink pekat untuk tombol aksi utama).
- **Tipografi**: Menggunakan font modern tanpa kaki (sans-serif) yang bersih, dengan hierarki ukuran yang jelas untuk membedakan judul, subjudul, dan isi teks.
- **Visual State**:
  - **Elemen Non-Aktif**: Produk atau item master data yang dinonaktifkan (`is_active: false`) wajib ditampilkan buram (*dimmed*) dengan opacity berkurang (misal: 50%-60%) dan dilengkapi label/badge **"NON-AKTIF"** agar staf dapat langsung mengidentifikasinya di katalog/browser produk.
  - **Visual Komisi**: Layanan ritel/jasa harus menampilkan informasi staf penanggung jawab secara visual agar memudahkan pelacakan komisi secara transparan.

---

## 2. Standardisasi Responsif (Tablet vs Mobile)

Aplikasi mobile Flutter dirancang untuk berjalan optimal baik pada ponsel pintar berlayar kecil (Mobile Phone) maupun tablet/PC (Layar Lebar).

```mermaid
graph TD
    Screen[Deteksi Lebar Layar]
    Screen -->|Lebar >= 600dp (Tablet/PC)| SplitPane[AdaptiveSplitLayout: 2-Pane Layout]
    Screen -->|Lebar < 600dp (Mobile)| SinglePane[Layout Scroll Tunggal / Vertikal]
    
    SplitPane --> LeftPane[Panel Kiri: Master List / Form Input]
    SplitPane --> RightPane[Panel Kanan: Detail Panel / Preview / Live List]
    
    SinglePane --> Stacking[Fold Horizontal ke Vertikal]
    SinglePane --> TabScrolling[Scrollable TabBar]
    SinglePane --> GridCols[Kurangi Kolom Grid: POS & Staf]
```

### 2.1. Standardisasi Layar Lebar (Tablet/PC - 2-Pane Split Layout)
Ketika aplikasi mendeteksi layar lebar (lebar $\ge 600\text{dp}$), tampilan secara otomatis bertransformasi menjadi **2-pane layout** menggunakan `AdaptiveSplitLayout`:
1. **Panel Kiri (Master Pane)**: Digunakan untuk menampilkan daftar data (master list), katalog produk, pencarian filter, atau formulir input utama.
2. **Panel Kanan (Detail Pane)**: Digunakan untuk menampilkan pratonton (*preview*) data yang dipilih, ringkasan transaksi, detail kartu stok, atau form input kuantitas terperinci.
3. **Optimasi Respon Gestur**: Pembaruan state UI akibat tap/pilihan item pada panel kiri harus dilakukan secara sinkron dalam handler gestur pengguna (`onTap`, `onSelected`, `onPressed`) untuk menghindari lag/jeda visual pada layar tablet, alih-alih membungkusnya dalam callback pasca-frame (*post-frame callback*).

### 2.2. Standardisasi Layar Kecil (Mobile Phone)
Pada perangkat handphone dengan layar sempit, tata letak melipat secara dinamis menjadi satu panel vertikal:
1. **Penyusunan Vertikal (Stacking)**: Baris input horizontal yang membutuhkan ruang lebar (misalnya baris unit sekunder dan rasio konversi pada detail produk) wajib disusun secara vertikal agar input tidak saling tumpang tindih.
2. **Tab Bar Scrollable**: Label kategori pada `TabBar` yang panjang wajib diset sebagai scrollable (`isScrollable: true`) agar label teks tidak terpotong atau mengecil secara ekstrem.
3. **Penyusutan Grid (Reduced Columns)**: 
   - Grid tombol pembayaran pada layar POS Checkout disusutkan menjadi **2 kolom** (di tablet bisa 4 kolom) untuk memastikan teks label (seperti "Debit Card") muat dengan sempurna.
   - Grid pemilihan staf/karyawan disusutkan menjadi **2 kolom** (di tablet bisa 3-4 kolom) agar nama staf tidak terpotong.

---

## 3. Standar & Alur Responsif Spesifik Fitur

### 3.1. Manajemen Inventaris (Stock Management)
| Fitur / Modul | Layout Tablet (Layar Lebar) | Layout Mobile (Layar Kecil) |
| :--- | :--- | :--- |
| **Stock In & Stock Out** | Panel Kiri: Form pilihan lokasi dan input data barang.<br>Panel Kanan: Daftar draft transaksi barang (*live items list*). | Form input dan daftar draft digabung secara berurutan dalam satu halaman scroll tunggal. |
| **Stock Movement** | Panel Kiri: Pilihan lokasi asal, tujuan, produk, dan jumlah.<br>Panel Kanan: Ringkasan visual aliran transfer barang (*planned movement summary card*). | Alur pengisian form dari atas ke bawah (sekuensial). Ringkasan divisualisasikan dalam dialog atau halaman tersendiri jika diperlukan. |
| **Stock Opname** | Panel Kiri: Daftar katalog produk per lokasi.<br>Panel Kanan: Kartu detail produk terpilih untuk memasukkan hasil hitung fisik (satuan utama & sekunder) tanpa mengganggu daftar pencarian produk. | Daftar produk ditampilkan penuh. Memilih produk akan membuka halaman input baru secara sekuensial. |

### 3.2. Katalog & Kasir POS
- **Pemilihan Designated Employee**: 
  - Form kasir wajib menyediakan pemilih staf penanggung jawab treatment.
  - Untuk efisiensi, aplikasi menginisialisasi kolom staf dengan pengguna yang sedang login secara default.
  - Daftar staf wajib memfilter karyawan aktif saja dan **menyaring/mengecualikan role `super_admin`** agar komisi tidak salah sasaran.
- **Pencarian Pelanggan**:
  - Menggunakan dialog popup pencarian pelanggan terintegrasi.
  - Wajib menampilkan nama dan nomor telepon pelanggan secara berdampingan di UI untuk mencegah salah klik pada pelanggan dengan nama yang mirip.
  - Pemilihan pelanggan bersifat wajib sebelum transaksi diselesaikan untuk menjamin integritas data CRM dan pengiriman nota digital.

---

## 4. Dialog & Popup Responsif

Seluruh dialog popup, konfirmasi, atau dialog pencarian wajib mengikuti aturan lebar dinamis berikut:
- **Rasio Lebar Dinamis**: Menggunakan `MediaQuery.of(context).size.width * 0.85` (atau rasio dinamis serupa) agar dialog menyesuaikan dengan lebar layar ponsel saat dibuka.
- **Lebar Maksimum (Max Width)**: Menetapkan batas lebar maksimum (misal: `constraints: BoxConstraints(maxWidth: 400)`) agar dialog tidak melar secara berlebihan saat dibuka di layar tablet atau PC.
- **Scrolling Content**: Konten di dalam dialog wajib dibungkus dengan `SingleChildScrollView` untuk mencegah kegagalan overflow tinggi (*vertical overflow*) jika papan ketik (*on-screen keyboard*) aktif.

---

## 5. Kepatuhan Safe Area

Untuk menjaga UI dari notch, sensor kamera, status bar, maupun navigasi bawaan sistem operasi (iOS/Android):
- Seluruh layar/screen di tingkat paling atas wajib menggunakan widget `SafeArea` sebagai pembungkus langsung dari `Scaffold`.
- Pada area terbawah yang sensitif terhadap tombol navigasi virtual (seperti tombol home bar iOS), beri bantalan (*padding*) atau gunakan `SafeArea(bottom: true)` agar tombol utama (misal: "Bayar", "Simpan") tidak terhimpit.
