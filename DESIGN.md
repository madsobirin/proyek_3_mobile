# DESIGN.md — FitLife.id Design System

## 1. Identity & Philosophy: Mindful Botanical
FitLife.id adalah asisten gaya hidup sehat, nutrisi, dan pemantau kebugaran harian. 

* **Filosofi:** Kesehatan yang berkelanjutan (*sustainable wellness*), tenang, berbasis bukti (*evidence over claims*), dan inklusif untuk seluruh keluarga.
* **Anti-Slop Directives:** 
  - Tidak ada gradien neon hijau silau (`#00FF66`) dan lingkaran bola melayang dekoratif tanpa fungsi.
  - Tidak ada jargon SaaS/AI generik (*"NEXT GEN PERFORMANCE"*, *"Athlete"*, *"Revolutionary"*). Seluruh copy menggunakan Bahasa Indonesia yang ramah, hangat, dan manusiawi.
  - Setiap tombol dan kontrol interaktif harus berfungsi nyata (*no dead controls*).

---

## 2. Palet Warna (Color System)

### Light Theme
* **Primary (Forest Sage):** `#20603D` — Hijau daun hutan yang matang, berakar, dan memiliki kontras tinggi (> 7:1) terhadap putih.
* **On Primary:** `#FFFFFF`
* **Primary Container:** `#E3EDE5` — Sage lembut untuk aksen latar belakang komponen aktif/terpilih.
* **On Primary Container:** `#103E25`
* **Secondary / Accent (Warm Amber):** `#D97706` — Aksen hangat untuk energi, kalori, dan api kebugaran (bukan neon orange).
* **Surface (Warm Alabaster):** `#FAF9F6` — Latar belakang utama bernuansa organik hangat, tidak menyilaukan mata.
* **Surface Container (Pure White):** `#FFFFFF` — Permukaan kartu dan lembar dialog.
* **Outline / Border:** `#E4E9E5` — Border netral yang sangat halus.
* **On Surface (Dark Slate Moss):** `#1B231D` — Teks judul & pembacaan utama.
* **On Surface Variant (Muted Text):** `#607064` — Teks sekunder, caption, dan icon non-aktif (lolos WCAG AA 4.5:1).

### Dark Theme
* **Primary:** `#86EFAC` — Hijau mint botanical yang teduh dan nyaman untuk kontras gelap.
* **On Primary:** `#052E16`
* **Primary Container:** `#164E2E`
* **On Primary Container:** `#D1FAE5`
* **Surface:** `#121814` — Charcoal lumut gelap (bukan hitam pekat OLED mentah).
* **Surface Container:** `#1B241E` — Kartu elevasi gelap bernuansa botanical.
* **Outline:** `#2E3B32`
* **On Surface:** `#F1F5F2`
* **On Surface Variant:** `#9CAFA3`

---

## 3. Tipografi (Typography System)

* **Font Family Utama:** **Plus Jakarta Sans** (`GoogleFonts.plusJakartaSans`)
* **Skala Tipografi Tunggal (5 Tingkatan):**
  1. **Headline / Display (26sp, Bold/ExtraBold w800):** Judul utama halaman atau hero banner.
  2. **Title / Section Header (20sp, SemiBold w700):** Judul section, header kartu, atau subjudul layar.
  3. **Subtitle / Button / Label (16sp, SemiBold w600):** Label tombol aksi, judul item menu/artikel, tab terpilih.
  4. **Body Text (14sp, Regular w400 / Medium w500):** Teks paragraf, deskripsi nutrisi, dan isi artikel.
  5. **Caption / Micro (12sp, Medium w500):** Tag kategori, pembacaan waktu, metadata kalori, dan helper text.

---

## 4. Spasi & Geometri (Spacing & Radius)

### Skala Radius (Maksimal 3 Nilai)
* **Small (`AppRadius.sm = 8.0`):** Badge, chip status, tag nutrisi, tooltip.
* **Medium (`AppRadius.md = 14.0`):** Tombol utama (`FilledButton`, `ElevatedButton`), input textfield, thumbnail gambar kecil.
* **Large (`AppRadius.lg = 20.0`):** Kartu data (`Card`), container modul utama, sheet dialog, floating banner.

### Skala Spasi (`AppSpacing`)
* `xxs = 4.0`
* `xs = 8.0`
* `sm = 12.0`
* `md = 16.0` (Padding standar layar mobile)
* `lg = 24.0`
* `xl = 32.0`

---

## 5. Standar Komponen Flutter

* **Card:** Elevasi 0 dp, batas garis tipis `1 dp` warna `outlineVariant`, sudut melengkung `20 dp`.
* **Button:** Tinggi standar `52 dp`, tap target minimal `48 dp`, sudut `14 dp`, teks tebal `16 sp`.
* **Input Fields:** Latar belakang bersih, border netral dengan fokus aksen `primary` `1.5 dp`, sudut `14 dp`.
* **Bottom Navigation:** Fixed docked bar dengan warna latar `surfaceContainer`, ikon dengan touch-target nyaman, tanpa menutupi konten utama (*reserved safe area*).
