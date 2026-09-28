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

    // Verifikasi tombol hitung
    final hitungBtn = find.text('Hitung Analisis Kesehatan Saya');
    expect(hitungBtn, findsOneWidget);

    // Scroll tombol ke tampilan dan tekan tombol hitung
    await tester.ensureVisible(hitungBtn);
    await tester.tap(hitungBtn);
    // Pump frame synchronous tanpa menunggu async network call
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verifikasi 3 bagian hasil muncul
    expect(find.text('1. Analisis Tubuh'), findsOneWidget);
    expect(find.text('2. Kebutuhan Energi Harian'), findsOneWidget);
    expect(find.text('3. Rekomendasi Nutrisi Harian'), findsOneWidget);

    // Verifikasi metrik utama muncul
    expect(find.text('Kisaran Berat Sehat'), findsOneWidget);
    expect(find.text('BMR'), findsOneWidget);
    expect(find.text('Energi Harian (TDEE)'), findsOneWidget);
    expect(find.text('PROTEIN'), findsOneWidget);
    expect(find.text('LEMAK'), findsOneWidget);
    expect(find.text('KARBOHIDRAT'), findsOneWidget);

    // Verifikasi nilai kalkulasi tepat sesuai PRD
    expect(find.text('≈ 22.5'), findsOneWidget);
    expect(find.text('≈ 53.5 – 72.0 kg'), findsOneWidget);
    expect(find.text('≈ 1593'), findsOneWidget);
    expect(find.text('≈ 2468'), findsOneWidget);
    expect(find.text('≈ 91g'), findsOneWidget);
    expect(find.text('≈ 82g'), findsOneWidget);
    expect(find.text('≈ 341g'), findsOneWidget);

    // ── Verifikasi Rekomendasi Menu & Pembagian Kalori Harian ──
    expect(find.text('Rekomendasi Menu Diet: Normal'), findsOneWidget);
    expect(
      find.text(
        'Nutrisi seimbang untuk mendukung kebutuhan energi harian Anda (2468 kcal/hari).',
      ),
      findsOneWidget,
    );
    expect(find.text('Lihat Semua'), findsOneWidget);

    // Verifikasi 3 summary card (25% / 40% / 35% dari 2468)
    // 2468 * 0.25 = 617, 2468 * 0.40 = 987, 2468 * 0.35 = 864
    expect(find.text('🌅 Sarapan (25%)'), findsOneWidget);
    expect(find.text('~617 kkal'), findsOneWidget);

    expect(find.text('☀️ Makan Siang (40%)'), findsOneWidget);
    expect(find.text('~987 kkal'), findsOneWidget);

    expect(find.text('🌙 Makan Malam (35%)'), findsOneWidget);
    expect(find.text('~864 kkal'), findsOneWidget);

    // Verifikasi filter tabs
    expect(find.text('Semua Menu'), findsOneWidget);
    expect(find.text('🌅 Sarapan (~617 kkal)'), findsOneWidget);
    expect(find.text('☀️ Makan Siang (~987 kkal)'), findsOneWidget);
    expect(find.text('🌙 Makan Malam (~864 kkal)'), findsOneWidget);

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

      final hitungBtn = find.text('Hitung Analisis Kesehatan Saya');
      await tester.ensureVisible(hitungBtn);
      await tester.tap(hitungBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Rekomendasi Menu Diet: Normal'), findsOneWidget);
      expect(find.text('🌅 Sarapan (25%)'), findsOneWidget);
      expect(find.text('☀️ Makan Siang (40%)'), findsOneWidget);
      expect(find.text('🌙 Makan Malam (35%)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
