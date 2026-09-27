import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/models/analisis_kesehatan_model.dart';
import 'package:fitlife/models/perhitungan_model.dart';
import 'package:fitlife/pages/dashboard/bmi_page.dart';

void main() {
  group('PerhitunganModel Tests', () {
    test('fromJson parses full JSON correctly', () {
      final json = {
        'id': 1,
        'user_id': 10,
        'tinggi_badan': 170.0,
        'berat_badan': 65.0,
        'bmi': 22.5,
        'status': 'Normal',
        'gender': 'pria',
        'usia': 25,
        'aktivitas': 'sedang',
        'bmr': 1593.0,
        'tdee': 2468.0,
        'target_kalori': 2468.0,
        'berat_min': 53.5,
        'berat_max': 72.0,
        'protein': 91.0,
        'karbohidrat': 341.0,
        'lemak': 82.0,
        'created_at': '2026-09-27T10:00:00.000Z',
      };

      final model = PerhitunganModel.fromJson(json);

      expect(model.id, 1);
      expect(model.userId, 10);
      expect(model.tinggiBadan, 170.0);
      expect(model.beratBadan, 65.0);
      expect(model.bmi, 22.5);
      expect(model.status, 'Normal');
      expect(model.bmr, 1593.0);
      expect(model.tdee, 2468.0);
      expect(model.protein, 91.0);
      expect(model.karbohidrat, 341.0);
      expect(model.lemak, 82.0);
      expect(model.bmiDisplay, '22.5');
      expect(model.bmrDisplay, 1593);
      expect(model.tdeeDisplay, 2468);
      expect(model.proteinDisplay, 91);
      expect(model.karbohidratDisplay, 341);
      expect(model.lemakDisplay, 82);
      expect(model.kisaranBeratDisplay, '53.5 – 72.0 kg');
    });

    test(
      'fromJson handles minimal backend JSON and computes fallback metrics',
      () {
        // Skenario: backend lama/minimal yang hanya menyimpan id, tinggi, berat, bmi, status
        final json = {
          'id': 2,
          'user_id': 10,
          'tinggi_badan': 170,
          'berat_badan': 65,
          'bmi': 22.5,
          'status': 'Normal',
          'created_at': '2026-09-27T10:00:00.000Z',
        };

        final model = PerhitunganModel.fromJson(json);

        expect(model.id, 2);
        expect(model.tinggiBadan, 170.0);
        expect(model.beratBadan, 65.0);
        expect(model.bmi, 22.5);
        expect(model.status, 'Normal');
        // Fallback BMR & TDEE dihitung otomatis
        expect(model.bmr, greaterThan(1000));
        expect(model.tdee, greaterThan(1500));
        expect(model.protein, greaterThan(0));
        expect(model.karbohidrat, greaterThan(0));
        expect(model.lemak, greaterThan(0));
        expect(model.beratMin, closeTo(53.46, 0.1));
        expect(model.beratMax, closeTo(71.96, 0.1));
      },
    );

    test('toJson generates all 15 fields for API compatibility', () {
      final model = PerhitunganModel(
        id: 5,
        userId: 12,
        tinggiBadan: 175.0,
        beratBadan: 70.0,
        bmi: 22.9,
        status: 'Normal',
        gender: 'pria',
        usia: 28,
        aktivitas: 'sedang',
        bmr: 1650.0,
        tdee: 2557.0,
        targetKalori: 2557.0,
        beratMin: 56.6,
        beratMax: 76.2,
        protein: 98.0,
        karbohidrat: 350.0,
        lemak: 85.0,
      );

      final json = model.toJson();

      expect(json['id'], 5);
      expect(json['user_id'], 12);
      expect(json['tinggi_badan'], 175.0);
      expect(json['berat_badan'], 70.0);
      expect(json['bmi'], 22.9);
      expect(json['status'], 'Normal');
      expect(json['gender'], 'pria');
      expect(json['usia'], 28);
      expect(json['aktivitas'], 'sedang');
      expect(json['bmr'], 1650);
      expect(json['tdee'], 2557);
      expect(json['target_kalori'], 2557);
      expect(json['berat_min'], 56.6);
      expect(json['berat_max'], 76.2);
      expect(json['protein'], 98);
      expect(json['karbohidrat'], 350);
      expect(json['lemak'], 85);
    });
  });

  group('AnalisisKesehatan Payload Tests', () {
    test('toApiPayload includes all 15 Perhitungan resource fields', () {
      const analisis = AnalisisKesehatan(
        bmi: 22.49,
        status: 'Normal',
        statusLabel: 'Normal',
        bmr: 1592.5,
        tdee: 2468.375,
        beratMin: 53.465,
        beratMax: 71.961,
        protein: 91.0,
        lemak: 82.279,
        karbohidrat: 340.941,
        tinggiBadan: 170.0,
        beratBadan: 65.0,
        usia: 25,
        gender: 'Pria',
        aktivitas: 'sedang',
      );

      final payload = analisis.toApiPayload();

      expect(payload['tinggi_badan'], 170);
      expect(payload['berat_badan'], 65);
      expect(payload['bmi'], 22.5);
      expect(payload['status'], 'Normal');
      expect(payload['gender'], 'pria');
      expect(payload['usia'], 25);
      expect(payload['aktivitas'], 'sedang');
      expect(payload['bmr'], 1593);
      expect(payload['tdee'], 2468);
      expect(payload['target_kalori'], 2468);
      expect(payload['berat_min'], 53.5);
      expect(payload['berat_max'], 72.0);
      expect(payload['protein'], 91);
      expect(payload['karbohidrat'], 341);
      expect(payload['lemak'], 82);
    });
  });

  group('BmiPage History Widget Tests', () {
    testWidgets('BmiPage displays history section and guest card', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BmiPage(onBack: () {})),
        ),
      );

      // Verifikasi riwayat section muncul di halaman
      expect(find.text('Riwayat Perhitungan'), findsOneWidget);
      expect(
        find.text('Catatan analisis kesehatan personal Anda'),
        findsOneWidget,
      );

      // Verifikasi guest mode card muncul secara default jika belum login
      expect(find.text('Mode Tamu (Belum Masuk)'), findsOneWidget);
      expect(find.text('Masuk ke Akun FitLife'), findsOneWidget);
    });
  });
}
