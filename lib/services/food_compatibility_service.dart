import '../models/food_compatibility_model.dart';
import '../models/perhitungan_model.dart';
import '../models/scan_makanan_model.dart';

/// Service evaluator kecocokan makanan dengan profil kesehatan pengguna.
class FoodCompatibilityService {
  static const double standardAkgKalori = 2150.0;
  static const double standardAkgProtein = 60.0;
  static const double standardAkgLemak = 67.0;
  static const double standardAkgKarbo = 300.0;
  static const double batasGulaHarianKemenkes = 50.0; // gram per hari

  /// Mengevaluasi kecocokan makanan berdasarkan hasil scan dan data kalkulator pengguna.
  static FoodCompatibilityResult evaluasi({
    required ScanMakananResult food,
    PerhitunganModel? userHealth,
  }) {
    final bool isGuestFallback = userHealth == null;

    final double targetKalori = userHealth != null && userHealth.targetKalori > 0
        ? userHealth.targetKalori
        : (userHealth != null && userHealth.tdee > 0
              ? userHealth.tdee
              : standardAkgKalori);

    final double targetProtein = userHealth != null && userHealth.protein > 0
        ? userHealth.protein
        : standardAkgProtein;

    final double targetLemak = userHealth != null && userHealth.lemak > 0
        ? userHealth.lemak
        : standardAkgLemak;

    final double targetKarbo = userHealth != null && userHealth.karbohidrat > 0
        ? userHealth.karbohidrat
        : standardAkgKarbo;

    final double? kaloriPercent = food.kalori != null
        ? (food.kalori! / targetKalori) * 100.0
        : null;

    final double? proteinPercent = food.protein != null
        ? (food.protein! / targetProtein) * 100.0
        : null;

    final double? lemakPercent = food.lemak != null
        ? (food.lemak! / targetLemak) * 100.0
        : null;

    final double? karbohidratPercent = food.karbohidrat != null
        ? (food.karbohidrat! / targetKarbo) * 100.0
        : null;

    final double? gulaPercent = food.gula != null
        ? (food.gula! / batasGulaHarianKemenkes) * 100.0
        : null;

    final List<String> highlights = [];
    final List<String> warnings = [];

    // Deteksi highlight positif
    if (food.protein != null && food.protein! >= 10.0) {
      highlights.add(
        'Kaya protein (${food.protein!.toStringAsFixed(1)}g), baik untuk pemeliharaan otot.',
      );
    }
    if (food.gula != null && food.gula! <= 5.0 && food.gula! >= 0) {
      highlights.add(
        'Rendah gula (${food.gula!.toStringAsFixed(1)}g), aman dari lonjakan gula darah.',
      );
    }

    // Deteksi peringatan nutrisi
    if (food.gula != null && food.gula! >= 15.0) {
      warnings.add(
        'Tinggi gula (${food.gula!.toStringAsFixed(1)}g, setara ${gulaPercent?.round() ?? 0}% batas harian).',
      );
    }
    if (food.lemak != null && food.lemak! >= 18.0) {
      warnings.add(
        'Kandungan lemak cukup tinggi (${food.lemak!.toStringAsFixed(1)}g).',
      );
    }
    if (kaloriPercent != null && kaloriPercent >= 35.0) {
      warnings.add(
        'Menyerap ${kaloriPercent.round()}% kuota kalori harian sekali makan.',
      );
    }

    final String? rawStatus = userHealth?.status.trim().toLowerCase();

    // Logika rekomendasi berdasarkan status profil pengguna
    if (rawStatus == 'obesitas' ||
        rawStatus == 'berlebih' ||
        rawStatus == 'kelebihan berat') {
      if (food.gula != null && food.gula! >= 15.0) {
        return FoodCompatibilityResult(
          level: CompatibilityLevel.kurangCocok,
          title: 'Kurang Dianjurkan',
          summary: 'Kandungan gula tinggi untuk program penurunan berat badan.',
          detailAdvice:
              'Produk ini mengandung ${food.gula!.toStringAsFixed(1)}g gula. Untuk mencegah lonjakan insulin dan mendukung defisit kalori, batasi konsumsi atau pilih alternatif rendah gula.',
          kaloriPercent: kaloriPercent,
          proteinPercent: proteinPercent,
          lemakPercent: lemakPercent,
          karbohidratPercent: karbohidratPercent,
          gulaPercent: gulaPercent,
          userTargetKalori: targetKalori,
          userStatus: userHealth?.status,
          isGuestFallback: isGuestFallback,
          highlights: highlights,
          warnings: warnings,
        );
      }

      if (kaloriPercent != null && kaloriPercent >= 35.0) {
        return FoodCompatibilityResult(
          level: CompatibilityLevel.perluPerhatian,
          title: 'Perlu Kontrol Porsi',
          summary: 'Padat kalori (${kaloriPercent.round()}% dari kuota harian).',
          detailAdvice:
              'Satu porsi ini mengambil porsi kalori cukup besar. Sebaiknya konsumsi separuh porsi atau kurangi asupan karbohidrat pada jam makan berikutnya.',
          kaloriPercent: kaloriPercent,
          proteinPercent: proteinPercent,
          lemakPercent: lemakPercent,
          karbohidratPercent: karbohidratPercent,
          gulaPercent: gulaPercent,
          userTargetKalori: targetKalori,
          userStatus: userHealth?.status,
          isGuestFallback: isGuestFallback,
          highlights: highlights,
          warnings: warnings,
        );
      }

      if (food.lemak != null && food.lemak! >= 20.0) {
        return FoodCompatibilityResult(
          level: CompatibilityLevel.perluPerhatian,
          title: 'Perlu Kontrol Porsi',
          summary: 'Kandungan lemak relatif tinggi.',
          detailAdvice:
              'Konsumsi dalam jumlah secukupnya dan perbanyak asupan serat dari sayuran agar lemak harian tetap terkendali.',
          kaloriPercent: kaloriPercent,
          proteinPercent: proteinPercent,
          lemakPercent: lemakPercent,
          karbohidratPercent: karbohidratPercent,
          gulaPercent: gulaPercent,
          userTargetKalori: targetKalori,
          userStatus: userHealth?.status,
          isGuestFallback: isGuestFallback,
          highlights: highlights,
          warnings: warnings,
        );
      }

      return FoodCompatibilityResult(
        level: CompatibilityLevel.cocok,
        title: 'Cocok Dikonsumsi',
        summary: 'Aman untuk program defisit kalori dan berat badan.',
        detailAdvice:
            'Komposisi nutrisi makanan ini berada dalam batas aman dan tidak membebani target penurunan berat badan kamu.',
        kaloriPercent: kaloriPercent,
        proteinPercent: proteinPercent,
        lemakPercent: lemakPercent,
        karbohidratPercent: karbohidratPercent,
        gulaPercent: gulaPercent,
        userTargetKalori: targetKalori,
        userStatus: userHealth?.status,
        isGuestFallback: isGuestFallback,
        highlights: highlights,
        warnings: warnings,
      );
    }

    if (rawStatus == 'kurus' || rawStatus == 'kekurangan berat') {
      if (food.kalori != null &&
          food.kalori! >= 250.0 &&
          food.protein != null &&
          food.protein! >= 8.0) {
        return FoodCompatibilityResult(
          level: CompatibilityLevel.cocok,
          title: 'Sangat Cocok',
          summary: 'Padat kalori dan protein untuk menaikkan berat badan.',
          detailAdvice:
              'Pilihan yang ideal untuk surplus kalori bersih (clean surplus). Kombinasi kalori dan proteinnya membantu pembentukan massa tubuh yang sehat.',
          kaloriPercent: kaloriPercent,
          proteinPercent: proteinPercent,
          lemakPercent: lemakPercent,
          karbohidratPercent: karbohidratPercent,
          gulaPercent: gulaPercent,
          userTargetKalori: targetKalori,
          userStatus: userHealth?.status,
          isGuestFallback: isGuestFallback,
          highlights: highlights,
          warnings: warnings,
        );
      }

      if (food.gula != null &&
          food.gula! >= 20.0 &&
          (food.protein ?? 0) < 3.0) {
        return FoodCompatibilityResult(
          level: CompatibilityLevel.perluPerhatian,
          title: 'Perlu Perhatian',
          summary: 'Tinggi kalori tapi minim protein (kalori kosong).',
          detailAdvice:
              'Hindari menaikkan berat badan hanya dari gula sederhana. Padukan makanan ini dengan sumber protein seperti telur, susu, atau kacang.',
          kaloriPercent: kaloriPercent,
          proteinPercent: proteinPercent,
          lemakPercent: lemakPercent,
          karbohidratPercent: karbohidratPercent,
          gulaPercent: gulaPercent,
          userTargetKalori: targetKalori,
          userStatus: userHealth?.status,
          isGuestFallback: isGuestFallback,
          highlights: highlights,
          warnings: warnings,
        );
      }

      if (food.kalori != null && food.kalori! < 100.0) {
        return FoodCompatibilityResult(
          level: CompatibilityLevel.perluPerhatian,
          title: 'Rendah Kalori',
          summary: 'Kurang padat energi untuk target surplus kalori.',
          detailAdvice:
              'Makanan ini sangat ringan. Jika targetmu menambah berat badan, utamakan asupan yang lebih padat gizi dan berenergi.',
          kaloriPercent: kaloriPercent,
          proteinPercent: proteinPercent,
          lemakPercent: lemakPercent,
          karbohidratPercent: karbohidratPercent,
          gulaPercent: gulaPercent,
          userTargetKalori: targetKalori,
          userStatus: userHealth?.status,
          isGuestFallback: isGuestFallback,
          highlights: highlights,
          warnings: warnings,
        );
      }

      return FoodCompatibilityResult(
        level: CompatibilityLevel.cocok,
        title: 'Cocok Dikonsumsi',
        summary: 'Mendukung pemenuhan kalori harian kamu.',
        detailAdvice:
            'Bagus untuk variasi menu harian dalam mencapai target kenaikan berat badan secara bertahap.',
        kaloriPercent: kaloriPercent,
        proteinPercent: proteinPercent,
        lemakPercent: lemakPercent,
        karbohidratPercent: karbohidratPercent,
        gulaPercent: gulaPercent,
        userTargetKalori: targetKalori,
        userStatus: userHealth?.status,
        isGuestFallback: isGuestFallback,
        highlights: highlights,
        warnings: warnings,
      );
    }

    if (rawStatus == 'normal') {
      if (food.gula != null && food.gula! >= 22.0) {
        return FoodCompatibilityResult(
          level: CompatibilityLevel.perluPerhatian,
          title: 'Perhatikan Gula',
          summary: 'Gula cukup tinggi (${food.gula!.toStringAsFixed(1)}g per saji).',
          detailAdvice:
              'Kadar gula mendekati separuh batas anjuran harian (50g). Batasi minuman manis lainnya sepanjang hari ini.',
          kaloriPercent: kaloriPercent,
          proteinPercent: proteinPercent,
          lemakPercent: lemakPercent,
          karbohidratPercent: karbohidratPercent,
          gulaPercent: gulaPercent,
          userTargetKalori: targetKalori,
          userStatus: userHealth?.status,
          isGuestFallback: isGuestFallback,
          highlights: highlights,
          warnings: warnings,
        );
      }

      if (kaloriPercent != null && kaloriPercent >= 40.0) {
        return FoodCompatibilityResult(
          level: CompatibilityLevel.perluPerhatian,
          title: 'Porsi Cukup Besar',
          summary: 'Menyumbang ${kaloriPercent.round()}% total kalori harian.',
          detailAdvice:
              'Porsi kalori ini setara menu makanan utama. Sesuaikan porsi makan berikutnya agar berat badan tetap stabil.',
          kaloriPercent: kaloriPercent,
          proteinPercent: proteinPercent,
          lemakPercent: lemakPercent,
          karbohidratPercent: karbohidratPercent,
          gulaPercent: gulaPercent,
          userTargetKalori: targetKalori,
          userStatus: userHealth?.status,
          isGuestFallback: isGuestFallback,
          highlights: highlights,
          warnings: warnings,
        );
      }

      return FoodCompatibilityResult(
        level: CompatibilityLevel.cocok,
        title: 'Cocok Dikonsumsi',
        summary: 'Seimbang untuk menjaga berat badan ideal.',
        detailAdvice:
            'Kandungan nutrisi makanan ini selaras dengan kebutuhan pemeliharaan berat badan normal kamu.',
        kaloriPercent: kaloriPercent,
        proteinPercent: proteinPercent,
        lemakPercent: lemakPercent,
        karbohidratPercent: karbohidratPercent,
        gulaPercent: gulaPercent,
        userTargetKalori: targetKalori,
        userStatus: userHealth?.status,
        isGuestFallback: isGuestFallback,
        highlights: highlights,
        warnings: warnings,
      );
    }

    // Kasus fallback: profil belum diisi atau pengguna guest
    if (food.gula != null && food.gula! >= 20.0) {
      return FoodCompatibilityResult(
        level: CompatibilityLevel.perluPerhatian,
        title: 'Kandungan Gula Tinggi',
        summary:
            'Mencapai ${gulaPercent?.round() ?? 0}% batas anjuran konsumsi gula Kemenkes.',
        detailAdvice:
            'Kemenkes menganjurkan batas konsumsi gula maksimal 50 gram per hari. Batasi konsumsi makanan manis lainnya hari ini.',
        kaloriPercent: kaloriPercent,
        proteinPercent: proteinPercent,
        lemakPercent: lemakPercent,
        karbohidratPercent: karbohidratPercent,
        gulaPercent: gulaPercent,
        userTargetKalori: targetKalori,
        userStatus: null,
        isGuestFallback: isGuestFallback,
        highlights: highlights,
        warnings: warnings,
      );
    }

    if (kaloriPercent != null && kaloriPercent >= 35.0) {
      return FoodCompatibilityResult(
        level: CompatibilityLevel.perluPerhatian,
        title: 'Kalori Cukup Tinggi',
        summary:
            'Menyerap ${kaloriPercent.round()}% dari rata-rata kebutuhan harian (2.150 kkal).',
        detailAdvice:
            'Kalori tergolong padat. Imbangi dengan aktivitas harian dan konsumsi air putih yang cukup.',
        kaloriPercent: kaloriPercent,
        proteinPercent: proteinPercent,
        lemakPercent: lemakPercent,
        karbohidratPercent: karbohidratPercent,
        gulaPercent: gulaPercent,
        userTargetKalori: targetKalori,
        userStatus: null,
        isGuestFallback: isGuestFallback,
        highlights: highlights,
        warnings: warnings,
      );
    }

    return FoodCompatibilityResult(
      level: CompatibilityLevel.cocok,
      title: 'Nutrisi Tergolong Aman',
      summary: 'Sesuai dengan standar rata-rata kebutuhan harian.',
      detailAdvice:
          'Kandungan gizi berada dalam ambang batas harian standar. Hitung profil BMI kamu di Kalkulator FitLife untuk rekomendasi yang dipersonalisasi.',
      kaloriPercent: kaloriPercent,
      proteinPercent: proteinPercent,
      lemakPercent: lemakPercent,
      karbohidratPercent: karbohidratPercent,
      gulaPercent: gulaPercent,
      userTargetKalori: targetKalori,
      userStatus: null,
      isGuestFallback: isGuestFallback,
      highlights: highlights,
      warnings: warnings,
    );
  }
}
