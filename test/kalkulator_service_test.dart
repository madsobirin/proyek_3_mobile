import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/services/kalkulator_service.dart';

void main() {
  group('KalkulatorService Tests', () {
    test('Kalkulasi Pria - Sedang (Mifflin-St Jeor & Makronutrien)', () {
      final hasil = KalkulatorService.hitung(
        tinggi: 170,
        berat: 65,
        usia: 25,
        gender: 'Pria',
        aktivitas: 'sedang',
      );

      // BMI
      expect(hasil.bmi, closeTo(22.49, 0.05));
      expect(hasil.bmiDisplay, equals('22.5'));
      expect(hasil.status, equals('Normal'));
      expect(hasil.statusLabel, equals('Normal'));

      // BMR = 10*65 + 6.25*170 - 5*25 + 5 = 1592.5
      expect(hasil.bmr, equals(1592.5));
      expect(hasil.bmrDisplay, equals(1593));

      // TDEE = 1592.5 * 1.55 = 2468.375
      expect(hasil.tdee, equals(2468.375));
      expect(hasil.tdeeDisplay, equals(2468));

      // Rentang berat sehat (18.5 - 24.9 * 2.89)
      expect(hasil.beratMin, closeTo(53.46, 0.05));
      expect(hasil.beratMax, closeTo(71.96, 0.05));
      expect(hasil.kisaranBeratDisplay, equals('53.5 – 72.0 kg'));

      // Makronutrien
      // Protein: 65 * 1.4 = 91.0 g
      expect(hasil.protein, equals(91.0));
      expect(hasil.proteinDisplay, equals(91));

      // Lemak: (2468.375 * 0.3) / 9 = 82.279 g
      expect(hasil.lemak, closeTo(82.28, 0.05));
      expect(hasil.lemakDisplay, equals(82));

      // Karbohidrat: (2468.375 - 364 - 740.5125) / 4 = 340.965 g
      expect(hasil.karbohidrat, closeTo(340.97, 0.05));
      expect(hasil.karbohidratDisplay, equals(341));
    });

    test('Kalkulasi Wanita - Ringan (Mifflin-St Jeor & Makronutrien)', () {
      final hasil = KalkulatorService.hitung(
        tinggi: 160,
        berat: 50,
        usia: 30,
        gender: 'Wanita',
        aktivitas: 'ringan',
      );

      // BMI = 50 / (1.6)^2 = 19.53125
      expect(hasil.bmi, closeTo(19.53, 0.05));
      expect(hasil.bmiDisplay, equals('19.5'));
      expect(hasil.status, equals('Normal'));

      // BMR Wanita = 10*50 + 6.25*160 - 5*30 - 161 = 1189.0
      expect(hasil.bmr, equals(1189.0));
      expect(hasil.bmrDisplay, equals(1189));

      // TDEE = 1189 * 1.375 = 1634.875
      expect(hasil.tdee, equals(1634.875));
      expect(hasil.tdeeDisplay, equals(1635));

      // Protein = 50 * 1.4 = 70 g
      expect(hasil.protein, equals(70.0));
      expect(hasil.proteinDisplay, equals(70));
    });

    test('Validasi Kategori BMI Batas Ambang', () {
      // Kurus: < 18.5
      final kurus = KalkulatorService.hitung(
        tinggi: 170,
        berat: 50,
        usia: 20,
        gender: 'Pria',
        aktivitas: 'rebahan',
      );
      expect(kurus.status, equals('Kurus'));
      expect(kurus.statusLabel, equals('Kekurangan Berat'));

      // Overweight / Berlebih: 25.0 <= BMI < 30.0
      final berlebih = KalkulatorService.hitung(
        tinggi: 170,
        berat: 75,
        usia: 20,
        gender: 'Pria',
        aktivitas: 'rebahan',
      );
      expect(berlebih.status, equals('Berlebih'));
      expect(berlebih.statusLabel, equals('Kelebihan Berat'));

      // Obesitas: >= 30.0
      final obesitas = KalkulatorService.hitung(
        tinggi: 170,
        berat: 90,
        usia: 20,
        gender: 'Pria',
        aktivitas: 'rebahan',
      );
      expect(obesitas.status, equals('Obesitas'));
      expect(obesitas.statusLabel, equals('Obesitas'));
    });

    test('Faktor Aktivitas Sesuai PRD', () {
      expect(KalkulatorService.getFaktorAktivitas('rebahan'), equals(1.2));
      expect(KalkulatorService.getFaktorAktivitas('sedentary'), equals(1.2));
      expect(KalkulatorService.getFaktorAktivitas('ringan'), equals(1.375));
      expect(KalkulatorService.getFaktorAktivitas('light'), equals(1.375));
      expect(KalkulatorService.getFaktorAktivitas('sedang'), equals(1.55));
      expect(KalkulatorService.getFaktorAktivitas('moderate'), equals(1.55));
      expect(KalkulatorService.getFaktorAktivitas('berat'), equals(1.725));
      expect(KalkulatorService.getFaktorAktivitas('active'), equals(1.725));
    });

    test('Validasi Input Input Tidak Valid', () {
      expect(
        KalkulatorService.validasi(
          tinggi: 0,
          berat: 60,
          usia: 25,
          gender: 'Pria',
          aktivitas: 'sedang',
        ),
        isNotNull,
      );

      expect(
        KalkulatorService.validasi(
          tinggi: 170,
          berat: -5,
          usia: 25,
          gender: 'Pria',
          aktivitas: 'sedang',
        ),
        isNotNull,
      );

      expect(
        KalkulatorService.validasi(
          tinggi: 170,
          berat: 60,
          usia: 0,
          gender: 'Pria',
          aktivitas: 'sedang',
        ),
        isNotNull,
      );

      expect(
        KalkulatorService.validasi(
          tinggi: 170,
          berat: 60,
          usia: 25,
          gender: 'Invalid',
          aktivitas: 'sedang',
        ),
        isNotNull,
      );

      expect(
        KalkulatorService.validasi(
          tinggi: 170,
          berat: 60,
          usia: 25,
          gender: 'Pria',
          aktivitas: 'sedang',
        ),
        isNull,
      );
    });
  });
}
