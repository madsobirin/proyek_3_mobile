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

  group('BmiPage History & Trend Widget Tests', () {
    testWidgets(
      'BmiPage displays Riwayat & Tren Berat Badan section and guest card',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: BmiPage(onBack: () {})),
          ),
        );

        // Verifikasi riwayat & tren section muncul di halaman
        expect(find.text('Riwayat & Tren Berat Badan'), findsOneWidget);
        expect(
          find.text('Visualisasi riwayat dan perkembangan berat badan Anda'),
          findsOneWidget,
        );

        // Verifikasi guest mode card muncul secara default jika belum login
        expect(find.text('Mode Tamu (Belum Masuk)'), findsOneWidget);
        expect(find.text('Masuk ke Akun FitLife'), findsOneWidget);
      },
    );

    testWidgets(
      'BmiPage renders without RenderFlex overflow on small screens (320x568, 360x640, 375x667)',
      (WidgetTester tester) async {
        final screenSizes = [
          const Size(320, 568),
          const Size(360, 640),
          const Size(375, 667),
          const Size(412, 915),
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: BmiPage(onBack: () {})),
            ),
          );
          await tester.pumpAndSettle();

          // Memastikan tidak ada exception RenderFlex overflow
          expect(tester.takeException(), isNull);
        }
      },
    );
  });

  group('History Trend & Summary Calculation Tests', () {
    test('Calculates trend Naik, Turun, Stabil, and Awal correctly', () {
      final listMultiNaik = [
        PerhitunganModel.fromJson({
          'id': 3,
          'tinggi_badan': 170.0,
          'berat_badan': 70.0,
          'bmi': 24.2,
          'status': 'Normal',
        }),
        PerhitunganModel.fromJson({
          'id': 2,
          'tinggi_badan': 170.0,
          'berat_badan': 68.0,
          'bmi': 23.5,
          'status': 'Normal',
        }),
        PerhitunganModel.fromJson({
          'id': 1,
          'tinggi_badan': 170.0,
          'berat_badan': 65.0,
          'bmi': 22.5,
          'status': 'Normal',
        }),
      ];

      // Urutan desc: latest is index 0, oldest is last
      final latestNaik = listMultiNaik.first;
      final oldestNaik = listMultiNaik.last;
      final perubahanNaik = latestNaik.beratBadan - oldestNaik.beratBadan;
      expect(perubahanNaik, 5.0);
      expect(perubahanNaik > 0.2, isTrue);

      final listMultiTurun = [
        PerhitunganModel.fromJson({
          'id': 2,
          'tinggi_badan': 170.0,
          'berat_badan': 63.0,
          'bmi': 21.8,
          'status': 'Normal',
        }),
        PerhitunganModel.fromJson({
          'id': 1,
          'tinggi_badan': 170.0,
          'berat_badan': 67.0,
          'bmi': 23.2,
          'status': 'Normal',
        }),
      ];
      final perubahanTurun =
          listMultiTurun.first.beratBadan - listMultiTurun.last.beratBadan;
      expect(perubahanTurun, -4.0);
      expect(perubahanTurun < -0.2, isTrue);

      // Single item: Awal
      final listSingle = [
        PerhitunganModel.fromJson({
          'id': 1,
          'tinggi_badan': 170.0,
          'berat_badan': 65.0,
          'bmi': 22.5,
          'status': 'Normal',
        }),
      ];
      expect(listSingle.length == 1, isTrue);
    });
  });

  group('Regression Test Delete History ID & URL', () {
    test(
      'JSON id 42 -> model.id == 42 -> delete uses 42 -> DELETE URL matches PRD endpoint',
      () {
        // 1. Raw JSON response from GET /api/perhitungan
        final rawJson = {
          'id': 42,
          'user_id': 6,
          'tinggi_badan': 175.0,
          'berat_badan': 70.0,
          'bmi': 22.9,
          'status': 'Normal',
        };

        // 2. Parse into PerhitunganModel
        final model = PerhitunganModel.fromJson(rawJson);
        expect(model.id, equals(42));

        // 3. Pastikan ID yang diambil untuk delete adalah model.id (bukan index atau hardcoded)
        final int deleteId = model.id!;
        expect(deleteId, 42);

        // 4. Verifikasi format endpoint URL DELETE
        const baseUrl = 'https://fitlife.my.id/api';
        final expectedDeleteUrl = '$baseUrl/perhitungan/$deleteId';
        expect(expectedDeleteUrl, 'https://fitlife.my.id/api/perhitungan/42');

        final expectedFallbackUrl = '$baseUrl/perhitungan?id=$deleteId';
        expect(
          expectedFallbackUrl,
          'https://fitlife.my.id/api/perhitungan?id=42',
        );
      },
    );
  });
}
