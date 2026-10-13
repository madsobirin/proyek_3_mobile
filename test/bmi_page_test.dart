import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/pages/dashboard/bmi_page.dart';

void main() {
  testWidgets('BmiPage renders form inputs and calculates 3 sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BmiPage(onBack: () {})),
      ),
    );

    // Verifikasi header
    expect(find.text('Kalkulator Kesehatan'), findsOneWidget);
    expect(find.text('Parameter Fisik'), findsOneWidget);
    expect(find.text('Jenis Kelamin'), findsOneWidget);
    expect(find.text('Tinggi Badan'), findsOneWidget);
    expect(find.text('Berat Badan'), findsOneWidget);
    expect(find.text('Usia'), findsOneWidget);
    expect(find.text('Tingkat Aktivitas Harian'), findsOneWidget);

    // Verifikasi opsi aktivitas ada
    expect(find.text('Sedentary'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Moderate'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '170');
    await tester.enterText(find.byType(TextField).at(1), '65');
    await tester.enterText(find.byType(TextField).at(2), '25');
    await tester.ensureVisible(find.text('Moderate'));
    await tester.tap(find.text('Moderate'));
    await tester.pump();

    // Verifikasi tombol hitung
    final hitungBtn = find.text('Hitung Analisis Kesehatan');
    expect(hitungBtn, findsOneWidget);

    // Scroll tombol ke tampilan dan tekan tombol hitung
    await tester.ensureVisible(hitungBtn);
    await tester.tap(hitungBtn);
    // Pump frame synchronous tanpa menunggu async network call
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verifikasi hasil kalkulasi dan konten nutrisi yang aktif
    expect(find.text('Distribusi Makronutrien Harian'), findsOneWidget);
    expect(find.text('Alokasi Kalori per Waktu Makan'), findsOneWidget);

    // Verifikasi metrik utama muncul
    expect(find.text('Kisaran Sehat: 53.5 – 72.0 kg'), findsOneWidget);
    expect(find.text('BMR (Istirahat)'), findsOneWidget);
    expect(find.text('TDEE (Kebutuhan)'), findsOneWidget);
    expect(find.text('PROTEIN'), findsOneWidget);
    expect(find.text('LEMAK'), findsOneWidget);
    expect(find.text('KARBOHIDRAT'), findsOneWidget);

    // Verifikasi nilai kalkulasi tepat sesuai PRD
    expect(find.text('22.5'), findsOneWidget);
    expect(find.text('≈ 1593'), findsOneWidget);
    expect(find.text('≈ 2468'), findsOneWidget);
    expect(find.text('≈ 91g'), findsOneWidget);
    expect(find.text('≈ 82g'), findsOneWidget);
    expect(find.text('≈ 341g'), findsOneWidget);

    // Verifikasi 3 summary card (25% / 40% / 35% dari 2468)
    // 2468 * 0.25 = 617, 2468 * 0.40 = 987, 2468 * 0.35 = 864
    expect(find.text('🌅 Sarapan (25%)'), findsOneWidget);
    expect(find.text('~617 kkal'), findsOneWidget);

    expect(find.text('☀️ Siang (40%)'), findsOneWidget);
    expect(find.text('~987 kkal'), findsOneWidget);

    expect(find.text('🌙 Malam (35%)'), findsOneWidget);
    expect(find.text('~864 kkal'), findsOneWidget);

    // Verifikasi rekomendasi menu dan filter waktu makan
    final recommendationTab = find.text('🥗 Rekomendasi Menu');
    await tester.ensureVisible(recommendationTab);
    await tester.tap(recommendationTab);
    await tester.pump();

    expect(find.text('Menu Diet: Normal'), findsOneWidget);
    expect(find.text('Semua Menu'), findsOneWidget);
    expect(find.text('🌅 Sarapan (~617 kkal)'), findsOneWidget);
    expect(find.text('☀️ Siang (~987 kkal)'), findsOneWidget);
    expect(find.text('🌙 Malam (~864 kkal)'), findsOneWidget);

    // Test interaksi tap filter tab
    final sarapanTab = find.text('🌅 Sarapan (~617 kkal)');
    await tester.ensureVisible(sarapanTab);
    await tester.tap(sarapanTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets(
    'BmiPage recommendation section does not overflow on small screens (320x568)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BmiPage(onBack: () {})),
        ),
      );

      final hitungBtn = find.text('Hitung Analisis Kesehatan');
      await tester.enterText(find.byType(TextField).at(0), '170');
      await tester.enterText(find.byType(TextField).at(1), '65');
      await tester.enterText(find.byType(TextField).at(2), '25');
      await tester.ensureVisible(find.text('Moderate'));
      await tester.tap(find.text('Moderate'));
      await tester.pump();
      await tester.ensureVisible(hitungBtn);
      await tester.tap(hitungBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('22.5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
