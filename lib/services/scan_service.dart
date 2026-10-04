import 'dart:convert';
import 'package:fitlife/models/scan_makanan_model.dart';
import 'package:fitlife/services/api_service.dart';

class ScanService {
  static final ScanService _instance = ScanService._internal();
  factory ScanService() => _instance;
  ScanService._internal();

  final ApiService _apiService = ApiService();

  /// Menyimpan hasil scan sementara untuk pengguna guest yang dialihkan ke halaman login
  static ScanMakananResult? pendingScanResult;

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
        );
      }
      throw Exception('Format data produk tidak sesuai.');
    } else if (statusCode == 400) {
      throw Exception(data?['message'] ?? 'Format barcode tidak valid.');
    } else if (statusCode == 404) {
      throw Exception(
        data?['message'] ??
            'Produk dengan barcode tersebut tidak ditemukan di database Open Food Facts.',
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
}
