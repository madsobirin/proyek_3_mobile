/// Model data untuk hasil analisis kesehatan dan kebutuhan nutrisi.
/// Mengikuti spesifikasi PRD FitLife.
class AnalisisKesehatan {
  final double bmi;
  final String status; // 'Kurus' | 'Normal' | 'Berlebih' | 'Obesitas'
  final String
  statusLabel; // 'Kekurangan Berat' | 'Normal' | 'Kelebihan Berat' | 'Obesitas'
  final double bmr;
  final double tdee;
  final double beratMin;
  final double beratMax;
  final double protein;
  final double lemak;
  final double karbohidrat;
  final double tinggiBadan;
  final double beratBadan;
  final int usia;
  final String gender;
  final String aktivitas;

  const AnalisisKesehatan({
    required this.bmi,
    required this.status,
    required this.statusLabel,
    required this.bmr,
    required this.tdee,
    required this.beratMin,
    required this.beratMax,
    required this.protein,
    required this.lemak,
    required this.karbohidrat,
    required this.tinggiBadan,
    required this.beratBadan,
    required this.usia,
    required this.gender,
    required this.aktivitas,
  });

  /// Format angka untuk penyajian di UI
  String get bmiDisplay => bmi.toStringAsFixed(1);
  int get bmrDisplay => bmr.round();
  int get tdeeDisplay => tdee.round();
  String get kisaranBeratDisplay =>
      '${beratMin.toStringAsFixed(1)} – ${beratMax.toStringAsFixed(1)} kg';
  int get proteinDisplay => protein.round();
  int get lemakDisplay => lemak.round();
  int get karbohidratDisplay => karbohidrat.round();

  Map<String, dynamic> toApiPayload() {
    return {
      'tinggi_badan': tinggiBadan.round(),
      'berat_badan': beratBadan.round(),
      'gender': gender.toLowerCase(),
      'usia': usia,
      'aktivitas': aktivitas.toLowerCase(),
    };
  }
}

/// Opsi tingkat aktivitas harian
class OpsiAktivitas {
  final String id;
  final String label;
  final String deskripsi;
  final double faktor;

  const OpsiAktivitas({
    required this.id,
    required this.label,
    required this.deskripsi,
    required this.faktor,
  });
}
