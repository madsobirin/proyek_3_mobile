import 'package:intl/intl.dart';
import '../services/kalkulator_service.dart';

/// Model untuk riwayat perhitungan BMI & analisis kesehatan.
class PerhitunganModel {
  final int? id;
  final int? userId;
  final double tinggiBadan;
  final double beratBadan;
  final double bmi;
  final String status;
  final String? gender;
  final int? usia;
  final String? aktivitas;
  final double bmr;
  final double tdee;
  final double targetKalori;
  final double beratMin;
  final double beratMax;
  final double protein;
  final double karbohidrat;
  final double lemak;
  final DateTime? createdAt;

  PerhitunganModel({
    this.id,
    this.userId,
    required this.tinggiBadan,
    required this.beratBadan,
    required this.bmi,
    required this.status,
    this.gender,
    this.usia,
    this.aktivitas,
    required this.bmr,
    required this.tdee,
    required this.targetKalori,
    required this.beratMin,
    required this.beratMax,
    required this.protein,
    required this.karbohidrat,
    required this.lemak,
    this.createdAt,
  });

  factory PerhitunganModel.fromJson(Map<String, dynamic> json) {
    final int? id = json['id'] is int
        ? json['id']
        : int.tryParse(json['id']?.toString() ?? '');
    final int? userId = json['user_id'] is int
        ? json['user_id']
        : int.tryParse(json['user_id']?.toString() ?? '');

    final double tb = (json['tinggi_badan'] as num?)?.toDouble() ?? 0.0;
    final double bb = (json['berat_badan'] as num?)?.toDouble() ?? 0.0;
    final double rawBmi =
        (json['bmi'] as num?)?.toDouble() ??
        (tb > 0 ? bb / ((tb / 100) * (tb / 100)) : 0.0);

    final String status =
        json['status']?.toString() ??
        (rawBmi < 18.5
            ? 'Kurus'
            : rawBmi < 25.0
            ? 'Normal'
            : rawBmi < 30.0
            ? 'Berlebih'
            : 'Obesitas');

    final String? gender = json['gender']?.toString();
    final int? usia = json['usia'] != null
        ? (json['usia'] as num).toInt()
        : null;
    final String? aktivitas = json['aktivitas']?.toString();

    // Jika bmr/tdee/makro sudah ada di JSON, gunakan langsung.
    // Jika tidak ada (misal schema backend hanya menyimpan tb/bb/bmi/status),
    // hitung menggunakan KalkulatorService dengan fallback aman.
    final double? jsonBmr = (json['bmr'] as num?)?.toDouble();
    final double? jsonTdee = (json['tdee'] as num?)?.toDouble();
    final double? jsonTargetKalori = (json['target_kalori'] as num?)
        ?.toDouble();
    final double? jsonBeratMin = (json['berat_min'] as num?)?.toDouble();
    final double? jsonBeratMax = (json['berat_max'] as num?)?.toDouble();
    final double? jsonProtein = (json['protein'] as num?)?.toDouble();
    final double? jsonKarbo = (json['karbohidrat'] as num?)?.toDouble();
    final double? jsonLemak = (json['lemak'] as num?)?.toDouble();

    final DateTime? createdAt = json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null;

    if (jsonBmr != null &&
        jsonTdee != null &&
        jsonProtein != null &&
        jsonKarbo != null &&
        jsonLemak != null) {
      return PerhitunganModel(
        id: id,
        userId: userId,
        tinggiBadan: tb,
        beratBadan: bb,
        bmi: rawBmi,
        status: status,
        gender: gender,
        usia: usia,
        aktivitas: aktivitas,
        bmr: jsonBmr,
        tdee: jsonTdee,
        targetKalori: jsonTargetKalori ?? jsonTdee,
        beratMin: jsonBeratMin ?? (18.5 * (tb / 100) * (tb / 100)),
        beratMax: jsonBeratMax ?? (24.9 * (tb / 100) * (tb / 100)),
        protein: jsonProtein,
        karbohidrat: jsonKarbo,
        lemak: jsonLemak,
        createdAt: createdAt,
      );
    }

    // Kalkulasi fallback
    if (tb > 0 && bb > 0) {
      final calculated = KalkulatorService.hitung(
        tinggi: tb,
        berat: bb,
        usia: usia ?? 25,
        gender: gender ?? 'Pria',
        aktivitas: aktivitas ?? 'sedang',
      );

      return PerhitunganModel(
        id: id,
        userId: userId,
        tinggiBadan: tb,
        beratBadan: bb,
        bmi: rawBmi > 0 ? rawBmi : calculated.bmi,
        status: status,
        gender: gender,
        usia: usia,
        aktivitas: aktivitas,
        bmr: jsonBmr ?? calculated.bmr,
        tdee: jsonTdee ?? calculated.tdee,
        targetKalori: jsonTargetKalori ?? jsonTdee ?? calculated.tdee,
        beratMin: jsonBeratMin ?? calculated.beratMin,
        beratMax: jsonBeratMax ?? calculated.beratMax,
        protein: jsonProtein ?? calculated.protein,
        karbohidrat: jsonKarbo ?? calculated.karbohidrat,
        lemak: jsonLemak ?? calculated.lemak,
        createdAt: createdAt,
      );
    }

    return PerhitunganModel(
      id: id,
      userId: userId,
      tinggiBadan: tb,
      beratBadan: bb,
      bmi: rawBmi,
      status: status,
      gender: gender,
      usia: usia,
      aktivitas: aktivitas,
      bmr: jsonBmr ?? 0.0,
      tdee: jsonTdee ?? 0.0,
      targetKalori: jsonTargetKalori ?? 0.0,
      beratMin: jsonBeratMin ?? 0.0,
      beratMax: jsonBeratMax ?? 0.0,
      protein: jsonProtein ?? 0.0,
      karbohidrat: jsonKarbo ?? 0.0,
      lemak: jsonLemak ?? 0.0,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'tinggi_badan': tinggiBadan,
      'berat_badan': beratBadan,
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'status': status,
      if (gender != null) 'gender': gender,
      if (usia != null) 'usia': usia,
      if (aktivitas != null) 'aktivitas': aktivitas,
      'bmr': bmr.round(),
      'tdee': tdee.round(),
      'target_kalori': targetKalori.round(),
      'berat_min': double.parse(beratMin.toStringAsFixed(1)),
      'berat_max': double.parse(beratMax.toStringAsFixed(1)),
      'protein': protein.round(),
      'karbohidrat': karbohidrat.round(),
      'lemak': lemak.round(),
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }

  // Helper getters untuk UI
  String get bmiDisplay => bmi.toStringAsFixed(1);
  int get bmrDisplay => bmr.round();
  int get tdeeDisplay => tdee.round();
  int get proteinDisplay => protein.round();
  int get karbohidratDisplay => karbohidrat.round();
  int get lemakDisplay => lemak.round();
  String get kisaranBeratDisplay =>
      '${beratMin.toStringAsFixed(1)} – ${beratMax.toStringAsFixed(1)} kg';

  String get formattedDate {
    if (createdAt == null) return '-';
    try {
      final local = createdAt!.toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(local);
    } catch (_) {
      return '-';
    }
  }
}
