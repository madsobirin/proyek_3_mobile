import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlife/models/scan_makanan_model.dart';
import 'package:fitlife/services/scan_service.dart';

void main() {
  group('ScanMakananResult Model Tests', () {
    test('fromJson parses full product response correctly', () {
      final json = {
        'id': 42,
        'user_id': 7,
        'barcode': '8992761011111',
        'nama_makanan': 'Susu UHT Full Cream',
        'brand': 'Ultra Milk',
        'image_url':
            'https://images.openfoodfacts.org/images/products/front.jpg',
        'kalori': 150,
        'protein': 8,
        'lemak': 8,
        'karbohidrat': 12,
        'gula': 12,
        'created_at': '2026-10-03T14:26:00.000Z',
      };

      final item = ScanMakananResult.fromJson(
        json,
        isFromCache: true,
        dataSource: 'Redis Cache',
      );

      expect(item.id, '42');
      expect(item.userId, 7);
      expect(item.barcode, '8992761011111');
      expect(item.namaMakanan, 'Susu UHT Full Cream');
      expect(item.brand, 'Ultra Milk');
      expect(
        item.imageUrl,
        'https://images.openfoodfacts.org/images/products/front.jpg',
      );
      expect(item.kalori, 150.0);
      expect(item.protein, 8.0);
      expect(item.lemak, 8.0);
      expect(item.karbohidrat, 12.0);
      expect(item.gula, 12.0);
      expect(item.createdAt, isNotNull);
      expect(item.isFromCache, isTrue);
      expect(item.dataSource, 'Redis Cache');
    });

    test('fromJson handles null values and missing fields gracefully', () {
      final json = {'barcode': '8996001304218', 'nama_makanan': 'Oat Biscuits'};

      final item = ScanMakananResult.fromJson(json);

      expect(item.id, isNull);
      expect(item.userId, isNull);
      expect(item.barcode, '8996001304218');
      expect(item.namaMakanan, 'Oat Biscuits');
      expect(item.brand, isNull);
      expect(item.imageUrl, isNull);
      expect(item.kalori, isNull);
      expect(item.protein, isNull);
      expect(item.lemak, isNull);
      expect(item.karbohidrat, isNull);
      expect(item.gula, isNull);
      expect(item.createdAt, isNull);
      expect(item.isFromCache, isNull);
      expect(item.dataSource, isNull);
    });

    test('toJson generates correct map matching backend payload spec', () {
      final item = ScanMakananResult(
        barcode: '8992761011111',
        namaMakanan: 'Susu UHT Full Cream',
        brand: 'Ultra Milk',
        kalori: 150.0,
        protein: 8.0,
        lemak: 8.0,
        karbohidrat: 12.0,
        gula: 12.0,
      );

      final map = item.toJson();

      expect(map['barcode'], '8992761011111');
      expect(map['nama_makanan'], 'Susu UHT Full Cream');
      expect(map['brand'], 'Ultra Milk');
      expect(map['kalori'], 150.0);
      expect(map['protein'], 8.0);
      expect(map['lemak'], 8.0);
      expect(map['karbohidrat'], 12.0);
      expect(map['gula'], 12.0);
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('user_id'), isFalse);
    });

    test(
      'toStorageJson and fromJson preserve full model state for offline storage',
      () {
        final item = ScanMakananResult(
          id: '42',
          userId: 7,
          barcode: '8992761011111',
          namaMakanan: 'Susu UHT Full Cream',
          brand: 'Ultra Milk',
          kalori: 150.0,
          protein: 8.0,
          lemak: 8.0,
          karbohidrat: 12.0,
          gula: 12.0,
          createdAt: DateTime.parse('2026-10-03T14:26:00.000Z'),
          isFromCache: true,
          dataSource: 'Redis Cache',
        );

        final storageMap = item.toStorageJson();
        final restored = ScanMakananResult.fromJson(storageMap);

        expect(restored.id, '42');
        expect(restored.userId, 7);
        expect(restored.barcode, '8992761011111');
        expect(restored.namaMakanan, 'Susu UHT Full Cream');
        expect(restored.kalori, 150.0);
        expect(restored.isFromCache, isTrue);
        expect(restored.dataSource, 'Redis Cache');
      },
    );

    test('copyWith updates specified fields correctly', () {
      final original = ScanMakananResult(
        barcode: '123456',
        namaMakanan: 'Original Name',
      );

      final modified = original.copyWith(
        id: '99',
        userId: 10,
        namaMakanan: 'Modified Name',
        kalori: 250.0,
        isFromCache: false,
        dataSource: 'Open Food Facts',
      );

      expect(modified.id, '99');
      expect(modified.userId, 10);
      expect(modified.barcode, '123456');
      expect(modified.namaMakanan, 'Modified Name');
      expect(modified.kalori, 250.0);
      expect(modified.isFromCache, isFalse);
      expect(modified.dataSource, 'Open Food Facts');
    });
  });

  group('ScanService Barcode Validation Tests', () {
    test('validates standard EAN / UPC barcodes', () {
      expect(ScanService.isValidBarcode('8992761011111'), isTrue);
      expect(ScanService.isValidBarcode('123'), isTrue);
      expect(ScanService.isValidBarcode('8996001304218'), isTrue);
      expect(ScanService.isValidBarcode('  8992761011111  '), isTrue);
    });

    test('rejects invalid barcodes (letters, symbols, short, empty)', () {
      expect(ScanService.isValidBarcode(''), isFalse);
      expect(ScanService.isValidBarcode('12'), isFalse); // < 3 digits
      expect(ScanService.isValidBarcode('abc123456'), isFalse);
      expect(ScanService.isValidBarcode('https://example.com'), isFalse);
      expect(ScanService.isValidBarcode('899-276-101'), isFalse);
    });
  });

  group('ScanService Offline Queue Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves, retrieves, and removes offline scan items', () async {
      final scanService = ScanService();
      final item1 = ScanMakananResult(
        barcode: '8991234567890',
        namaMakanan: 'Roti Gandum',
        kalori: 200,
      );
      final item2 = ScanMakananResult(
        barcode: '8999876543210',
        namaMakanan: 'Susu Kedelai',
        kalori: 120,
      );

      // Save offline
      await scanService.saveOfflineScan(item1);
      await scanService.saveOfflineScan(item2);

      // Retrieve
      final list = await scanService.getOfflineScans();
      expect(list.length, 2);
      expect(list.any((e) => e.barcode == '8991234567890'), isTrue);
      expect(list.any((e) => e.barcode == '8999876543210'), isTrue);

      // Remove 1 item
      await scanService.removeOfflineScan('8991234567890');
      final updatedList = await scanService.getOfflineScans();
      expect(updatedList.length, 1);
      expect(updatedList.first.barcode, '8999876543210');
    });
  });
}
