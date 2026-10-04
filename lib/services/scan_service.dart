import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlife/models/scan_makanan_model.dart';
import 'package:fitlife/services/api_service.dart';

class ScanService {
  static final ScanService _instance = ScanService._internal();
  factory ScanService() => _instance;
  ScanService._internal();

  final ApiService _apiService = ApiService();

  /// Menyimpan hasil scan sementara untuk pengguna guest yang dialihkan ke halaman login
  static ScanMakananResult? pendingScanResult;

  static const String _offlineQueueKey = 'offline_scan_queue';

  /// Validasi format barcode (3-64 digit angka)
  static bool isValidBarcode(String barcode) {
    final cleaned = barcode.trim();
    return RegExp(r'^\d{3,64}$').hasMatch(cleaned);
  }

  /// Mencari informasi nutrisi produk dari barcode via API backend
  /// (Dapat diakses tanpa login)
  Future<ScanMakananResult> lookupBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (!isValidBarcode(cleanBarcode)) {
      throw Exception('Barcode harus berisi 3 sampai 64 digit angka.');
    }

    final response = await _apiService.post('/scan-makanan/lookup', {
      'barcode': cleanBarcode,
    });

    final statusCode = response.statusCode;
    final xCache = response.headers['x-cache']?.toUpperCase();
    final isFromCache = xCache == 'HIT';
    final dataSource =
        response.headers['x-data-source'] ??
        (isFromCache ? 'Redis Cache' : 'Open Food Facts');

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (statusCode == 200) {
      if (data is Map<String, dynamic>) {
        final productData = data['data'] ?? data['product'] ?? data;
        return ScanMakananResult.fromJson(
          Map<String, dynamic>.from(productData),
          isFromCache: isFromCache,
          dataSource: dataSource,
        );
      }
      throw Exception('Format data produk tidak sesuai.');
    } else if (statusCode == 400) {
      throw Exception(data?['message'] ?? 'Format barcode tidak valid.');
    } else if (statusCode == 404) {
      throw Exception(
        data?['message'] ?? 'Produk dengan barcode tersebut tidak ditemukan.',
      );
    } else if (statusCode == 422) {
      throw Exception(
        data?['message'] ??
            'Produk ditemukan, tetapi nama produk atau informasi nutrisi tidak tersedia.',
      );
    } else if (statusCode == 502) {
      throw Exception(
        data?['message'] ??
            'Layanan pencarian produk sedang tidak tersedia. Coba lagi nanti.',
      );
    } else {
      throw Exception(
        data?['message'] ?? 'Gagal memindai produk (Kode: $statusCode).',
      );
    }
  }

  /// Menyimpan hasil scan ke riwayat akun pengguna
  /// (Membutuhkan Bearer JWT token)
  Future<ScanMakananResult> saveScanResult(ScanMakananResult result) async {
    final response = await _apiService.post(
      '/scan-makanan/save',
      result.toJson(),
    );

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic> && data['data'] != null) {
        return ScanMakananResult.fromJson(
          Map<String, dynamic>.from(data['data']),
        );
      }
      return result;
    }

    if (response.statusCode == 401) {
      throw Exception('Sesi login telah berakhir. Silakan login kembali.');
    }

    throw Exception(
      data?['message'] ??
          'Gagal menyimpan riwayat makanan (${response.statusCode}).',
    );
  }

  /// Mengambil daftar riwayat scan makanan pengguna
  Future<List<ScanMakananResult>> getScanHistory() async {
    final response = await _apiService.get('/scan-makanan');

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = data is List
          ? data
          : (data is Map && data['data'] is List ? data['data'] : []);

      return list
          .map(
            (item) =>
                ScanMakananResult.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Silakan login untuk melihat riwayat scan makanan.');
    } else {
      throw Exception(data?['message'] ?? 'Gagal memuat riwayat scan makanan.');
    }
  }

  /// Menghapus item riwayat scan makanan berdasarkan ID
  Future<void> deleteScanHistory(String id) async {
    final response = await _apiService.delete('/scan-makanan?id=$id');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = null;
    }

    if (response.statusCode == 401) {
      throw Exception('Silakan login untuk menghapus riwayat scan.');
    }

    throw Exception(data?['message'] ?? 'Gagal menghapus riwayat scan.');
  }

  /// Mengunggah foto makanan kemasan ke server (mengembalikan URL publik gambar)
  Future<String?> uploadFoodImage(String filePath) async {
    try {
      final response = await _apiService.postMultipart(
        '/scan-makanan/upload',
        'image',
        filePath,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data['url']?.toString() ??
              data['image_url']?.toString() ??
              data['data']?['url']?.toString() ??
              data['data']?['image_url']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Menyimpan hasil scan makanan secara offline di local storage saat sinyal lemah
  Future<void> saveOfflineScan(ScanMakananResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getOfflineScans();
    currentList.removeWhere((item) => item.barcode == result.barcode);
    currentList.insert(0, result);

    final rawJsonList = currentList.map((e) => e.toStorageJson()).toList();
    await prefs.setString(_offlineQueueKey, jsonEncode(rawJsonList));
  }

  /// Mengambil antrean scan yang tersimpan secara offline
  Future<List<ScanMakananResult>> getOfflineScans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_offlineQueueKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map(
            (item) =>
                ScanMakananResult.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Menghapus scan dari antrean offline
  Future<void> removeOfflineScan(String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getOfflineScans();
    currentList.removeWhere((item) => item.barcode == barcode);
    final rawJsonList = currentList.map((e) => e.toStorageJson()).toList();
    await prefs.setString(_offlineQueueKey, jsonEncode(rawJsonList));
  }

  /// Melakukan sinkronisasi otomatis seluruh scan offline ke cloud database
  Future<int> syncOfflineScans() async {
    final offlineList = await getOfflineScans();
    if (offlineList.isEmpty) return 0;

    int syncedCount = 0;
    final List<ScanMakananResult> remaining = [];

    for (final item in offlineList) {
      try {
        await saveScanResult(item);
        syncedCount++;
      } catch (_) {
        remaining.add(item);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    if (remaining.isEmpty) {
      await prefs.remove(_offlineQueueKey);
    } else {
      final raw = remaining.map((e) => e.toStorageJson()).toList();
      await prefs.setString(_offlineQueueKey, jsonEncode(raw));
    }

    return syncedCount;
  }
}
