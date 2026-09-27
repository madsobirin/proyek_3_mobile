import '../models/analisis_kesehatan_model.dart';

/// Service kalkulator kesehatan dan analisis nutrisi FitLife.
/// Menjalankan kalkulasi matematis sesuai web PRD FitLife dengan presisi penuh.
class KalkulatorService {
  /// Daftar opsi aktivitas yang didukung
  static const List<OpsiAktivitas> daftarAktivitas = [
    OpsiAktivitas(
      id: 'rebahan',
      label: 'Sedentary',
      deskripsi: 'Jarang / tidak pernah olahraga (1.2)',
      faktor: 1.2,
    ),
    OpsiAktivitas(
      id: 'ringan',
      label: 'Light',
      deskripsi: 'Olahraga 1–3 hari/minggu (1.375)',
      faktor: 1.375,
    ),
    OpsiAktivitas(
      id: 'sedang',
      label: 'Moderate',
      deskripsi: 'Olahraga 3–5 hari/minggu (1.55)',
      faktor: 1.55,
    ),
    OpsiAktivitas(
      id: 'berat',
      label: 'Active',
      deskripsi: 'Olahraga 6–7 hari/minggu (1.725)',
      faktor: 1.725,
    ),
  ];

  /// Mengambil faktor pengali aktivitas berdasarkan ID
  static double getFaktorAktivitas(String aktivitas) {
    final key = aktivitas.toLowerCase().trim();
    switch (key) {
      case 'sedentary':
      case 'rebahan':
        return 1.2;
      case 'light':
      case 'ringan':
        return 1.375;
      case 'moderate':
      case 'sedang':
        return 1.55;
      case 'active':
      case 'berat':
        return 1.725;
      default:
        return 1.55; // Default moderate/sedang
    }
  }

  /// Validasi input kalkulator
  static String? validasi({
    required double tinggi,
    required double berat,
    required int usia,
    required String gender,
    required String aktivitas,
  }) {
    if (tinggi <= 0) {
      return 'Tinggi badan harus lebih besar dari 0 cm.';
    }
    if (tinggi < 50 || tinggi > 250) {
      return 'Tinggi badan harus di antara 50 dan 250 cm.';
    }
    if (berat <= 0) {
      return 'Berat badan harus lebih besar dari 0 kg.';
    }
    if (berat < 20 || berat > 300) {
      return 'Berat badan harus di antara 20 dan 300 kg.';
    }
    if (usia <= 0) {
      return 'Usia harus lebih besar dari 0 tahun.';
    }
    if (usia < 10 || usia > 120) {
      return 'Usia harus di antara 10 dan 120 tahun.';
    }
    final g = gender.toLowerCase().trim();
    if (g != 'pria' && g != 'wanita' && g != 'laki-laki' && g != 'perempuan') {
      return 'Pilih jenis kelamin yang valid.';
    }
    return null;
  }

  /// Menghitung analisis kesehatan & nutrisi lengkap (full precision)
  static AnalisisKesehatan hitung({
    required double tinggi, // cm
    required double berat, // kg
    required int usia, // tahun
    required String gender, // 'Pria' | 'Wanita'
    required String aktivitas, // 'rebahan' | 'ringan' | 'sedang' | 'berat'
  }) {
    // 1. Tinggi dalam meter
    final double tinggiM = tinggi / 100.0;
    final double tinggiM2 = tinggiM * tinggiM;

    // 2. BMI = berat / (tinggi_m)^2
    final double bmi = berat / tinggiM2;

    // 3. Status BMI & Label
    // Perbandingan float aman untuk boundary IEEE-754
    final double bmiCheck = (bmi * 1e6).round() / 1e6;
    final String status;
    final String statusLabel;

    if (bmiCheck < 18.5) {
      status = 'Kurus';
      statusLabel = 'Kekurangan Berat';
    } else if (bmiCheck < 25.0) {
      status = 'Normal';
      statusLabel = 'Normal';
    } else if (bmiCheck < 30.0) {
      status = 'Berlebih';
      statusLabel = 'Kelebihan Berat';
    } else {
      status = 'Obesitas';
      statusLabel = 'Obesitas';
    }

    // 4. BMR Mifflin-St Jeor (full precision)
    final bool isFemale =
        gender.toLowerCase() == 'wanita' || gender.toLowerCase() == 'perempuan';
    final double bmr = isFemale
        ? (10.0 * berat) + (6.25 * tinggi) - (5.0 * usia) - 161.0
        : (10.0 * berat) + (6.25 * tinggi) - (5.0 * usia) + 5.0;

    // 5. TDEE = BMR × faktor aktivitas
    final double faktor = getFaktorAktivitas(aktivitas);
    final double tdee = bmr * faktor;

    // 6. Kisaran berat berdasarkan BMI: 18.5 × (tinggi_m)^2 s/d 24.9 × (tinggi_m)^2
    final double beratMin = 18.5 * tinggiM2;
    final double beratMax = 24.9 * tinggiM2;

    // 7. Protein = BB × 1.4 g/hari
    final double protein = berat * 1.4;

    // 8. Lemak = (TDEE × 30%) / 9
    final double lemak = (tdee * 0.3) / 9.0;

    // 9. Karbohidrat = (TDEE - (Protein × 4) - (Lemak × 9)) / 4 (dari sisa kalori)
    final double karbohidrat = (tdee - (protein * 4.0) - (lemak * 9.0)) / 4.0;

    return AnalisisKesehatan(
      bmi: bmi,
      status: status,
      statusLabel: statusLabel,
      bmr: bmr,
      tdee: tdee,
      beratMin: beratMin,
      beratMax: beratMax,
      protein: protein,
      lemak: lemak,
      karbohidrat: karbohidrat,
      tinggiBadan: tinggi,
      beratBadan: berat,
      usia: usia,
      gender: gender,
      aktivitas: aktivitas,
    );
  }
}
