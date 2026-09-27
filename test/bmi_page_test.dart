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
  });
}
