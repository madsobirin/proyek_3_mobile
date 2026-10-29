import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/models/food_compatibility_model.dart';
import 'package:fitlife/models/perhitungan_model.dart';
import 'package:fitlife/models/scan_makanan_model.dart';
import 'package:fitlife/services/food_compatibility_service.dart';

void main() {
  group('FoodCompatibilityService Unit Tests', () {
    test('Pengguna Obesitas dengan makanan tinggi gula menghasilkan kurangCocok', () {
      final user = PerhitunganModel(
        tinggiBadan: 170,
        beratBadan: 95,
        bmi: 32.9,
        status: 'Obesitas',
        bmr: 1800,
        tdee: 2200,
        targetKalori: 1800,
        beratMin: 53.5,
        beratMax: 72.0,
        protein: 133,
        karbohidrat: 200,
        lemak: 60,
      );

      final sweetFood = ScanMakananResult(
        barcode: '8991234567890',
        namaMakanan: 'Minuman Boba Manis',
        kalori: 320,
        protein: 2,
        lemak: 8,
        karbohidrat: 60,
        gula: 28,
      );

      final result = FoodCompatibilityService.evaluasi(
        food: sweetFood,
        userHealth: user,
      );

      expect(result.level, CompatibilityLevel.kurangCocok);
      expect(result.title, 'Kurang Dianjurkan');
      expect(result.isGuestFallback, isFalse);
      expect(result.userStatus, 'Obesitas');
      expect(result.warnings.isNotEmpty, isTrue);
    });

    test('Pengguna Obesitas dengan makanan padat kalori (>35% TDEE) menghasilkan perluPerhatian', () {
      final user = PerhitunganModel(
        tinggiBadan: 165,
        beratBadan: 80,
        bmi: 29.4,
        status: 'Berlebih',
        bmr: 1600,
        tdee: 2000,
        targetKalori: 1700,
        beratMin: 50.4,
        beratMax: 67.8,
        protein: 112,
        karbohidrat: 180,
        lemak: 55,
      );

      final heavyFood = ScanMakananResult(
        barcode: '8999999999999',
        namaMakanan: 'Burger Keju Komplit',
        kalori: 700, // 700 / 1700 = 41%
        protein: 25,
        lemak: 35,
        karbohidrat: 70,
        gula: 8,
      );

      final result = FoodCompatibilityService.evaluasi(
        food: heavyFood,
        userHealth: user,
      );

      expect(result.level, CompatibilityLevel.perluPerhatian);
      expect(result.title, 'Perlu Kontrol Porsi');
      expect(result.kaloriPercent, greaterThan(35.0));
    });

    test('Pengguna Kurus dengan makanan tinggi kalori & protein menghasilkan cocok (Sangat Cocok)', () {
      final user = PerhitunganModel(
        tinggiBadan: 175,
        beratBadan: 50,
        bmi: 16.3,
        status: 'Kurus',
        bmr: 1450,
        tdee: 2000,
        targetKalori: 2300, // Surplus kalori
        beratMin: 56.7,
        beratMax: 76.3,
        protein: 70,
        karbohidrat: 350,
        lemak: 70,
      );

      final cleanBulkFood = ScanMakananResult(
        barcode: '8991112223334',
        namaMakanan: 'Susu Kedelai Protein Tinggi',
        kalori: 280,
        protein: 14,
        lemak: 6,
        karbohidrat: 42,
        gula: 6,
      );

      final result = FoodCompatibilityService.evaluasi(
        food: cleanBulkFood,
        userHealth: user,
      );

      expect(result.level, CompatibilityLevel.cocok);
      expect(result.title, 'Sangat Cocok');
      expect(result.highlights.any((h) => h.contains('protein')), isTrue);
    });

    test('Pengguna Kurus dengan kalori kosong (tinggi gula minim protein) menghasilkan perluPerhatian', () {
      final user = PerhitunganModel(
        tinggiBadan: 170,
        beratBadan: 48,
        bmi: 16.6,
        status: 'Kurus',
        bmr: 1400,
        tdee: 1900,
        targetKalori: 2200,
        beratMin: 53.5,
        beratMax: 72.0,
        protein: 67,
        karbohidrat: 320,
        lemak: 65,
      );

      final emptyCalorieFood = ScanMakananResult(
        barcode: '8994445556667',
        namaMakanan: 'Permen Jelly Manis',
        kalori: 220,
        protein: 0.5,
        lemak: 0,
        karbohidrat: 55,
        gula: 35,
      );

      final result = FoodCompatibilityService.evaluasi(
        food: emptyCalorieFood,
        userHealth: user,
      );

      expect(result.level, CompatibilityLevel.perluPerhatian);
      expect(result.title, 'Perlu Perhatian');
      expect(result.summary.contains('kalori kosong'), isTrue);
    });

    test('Pengguna Normal dengan menu seimbang menghasilkan cocok', () {
      final user = PerhitunganModel(
        tinggiBadan: 170,
        beratBadan: 63,
        bmi: 21.8,
        status: 'Normal',
        bmr: 1550,
        tdee: 2200,
        targetKalori: 2200,
        beratMin: 53.5,
        beratMax: 72.0,
        protein: 88,
        karbohidrat: 300,
        lemak: 70,
      );

      final balancedFood = ScanMakananResult(
        barcode: '8997778889990',
        namaMakanan: 'Oatmeal Almond Rendah Gula',
        kalori: 260,
        protein: 10,
        lemak: 7,
        karbohidrat: 38,
        gula: 4,
      );

      final result = FoodCompatibilityService.evaluasi(
        food: balancedFood,
        userHealth: user,
      );

      expect(result.level, CompatibilityLevel.cocok);
      expect(result.title, 'Cocok Dikonsumsi');
    });

    test('Fallback pengguna guest / belum isi kalkulator menggunakan standar AKG', () {
      final food = ScanMakananResult(
        barcode: '8990001112223',
        namaMakanan: 'Roti Gandum',
        kalori: 215, // 10% dari 2150 kkal
        protein: 8,
        lemak: 3,
        karbohidrat: 40,
        gula: 3,
      );

      final result = FoodCompatibilityService.evaluasi(
        food: food,
        userHealth: null,
      );

      expect(result.isGuestFallback, isTrue);
      expect(result.userStatus, isNull);
      expect(result.userTargetKalori, 2150.0);
      expect(result.kaloriPercent, closeTo(10.0, 0.1));
      expect(result.level, CompatibilityLevel.cocok);
    });
  });
}
