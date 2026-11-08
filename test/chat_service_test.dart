import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/services/chat_service.dart';

void main() {
  group('ChatService formatPlainText Tests', () {
    test('Hapus tanda bintang ganda bold tanpa meninggalkan karakter bintang', () {
      const input = 'Ini adalah **kata penting** dan **nutrisi sehat**.';
      final result = ChatService.formatPlainText(input);

      expect(result, 'Ini adalah kata penting dan nutrisi sehat.');
      expect(result.contains('**'), isFalse);
    });

    test('Konversi heading tanda pagar menjadi huruf kapital tanpa pagar', () {
      const input = '# Panduan Diet\n## Sarapan Pagi\n### Menu Utama';
      final result = ChatService.formatPlainText(input);

      expect(result.contains('#'), isFalse);
      expect(result, 'PANDUAN DIET\nSARAPAN PAGI\nMENU UTAMA');
    });

    test('Konversi bullet bintang menjadi strip standar', () {
      const input =
          'Daftar menu:\n* Telur rebus\n* Dada ayam panggang\n* Sayur bayam';
      final result = ChatService.formatPlainText(input);

      expect(result.contains('*'), isFalse);
      expect(
        result,
        'Daftar menu:\n- Telur rebus\n- Dada ayam panggang\n- Sayur bayam',
      );
    });

    test('Pembersihan kombinasi lengkap markdown', () {
      const input =
          '### REKOMENDASI KESEHATAN\n\n'
          'Untuk menjaga berat badan **IDEAL**, lakukan:\n'
          '* Olahraga **30 menit** per hari\n'
          '* Minum air putih minimal **2 liter**\n'
          '* Kunjungi [FitLife](https://fitlife.id) untuk detail.';

      final result = ChatService.formatPlainText(input);

      expect(result.contains('###'), isFalse);
      expect(result.contains('**'), isFalse);
      expect(result.contains('*'), isFalse);
      expect(result.contains('- Olahraga 30 menit per hari'), isTrue);
      expect(result.contains('- Minum air putih minimal 2 liter'), isTrue);
      expect(result.contains('FitLife (https://fitlife.id)'), isTrue);
    });
  });
}
