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

  /// Mencari informasi nutrisi produk dari barcode via API backend
  /// (Dapat diakses tanpa login)
  Future<ScanMakananResult> lookupBarcode(String barcode) async {
    final response = await _apiService.post(
      '/scan-makanan/lookup',
      {'barcode': barcode},
    );

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
            'Produk belum terdaftar di database Open Food Facts.',
      );
    } else if (statusCode == 422) {
      throw Exception(
        data?['message'] ??
            'Produk ditemukan, tetapi data nutrisi atau nama belum lengkap.',
      );
    } else if (statusCode == 502) {
      throw Exception(
        data?['message'] ??
            'Layanan Open Food Facts sedang tidak dapat dihubungi. Coba lagi nanti.',
      );
    } else {
      throw Exception(
        data?['message'] ?? 'Gagal memindai produk (Kode: $statusCode).',
      );
    }
  }

  /// Menyimpan hasil scan ke riwayat akun pengguna
  /// (Membutuhkan Bearer JWT token)
  Future<void> saveScanResult(ScanMakananResult result) async {
    final response = await _apiService.post(
      '/scan-makanan/save',
      result.toJson(),
    );

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
      throw Exception('Sesi login telah berakhir. Silakan login kembali.');
    }

    throw Exception(
      data?['message'] ?? 'Gagal menyimpan riwayat makanan (${response.statusCode}).',
    );
  }

  /// Mengambil daftar riwayat scan makanan pengguna
  Future<List<ScanMakananResult>> getScanHistory() async {
    final response = await _apiService.get('/scan-makanan');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic body = jsonDecode(response.body);
      final List<dynamic> list = body is List
          ? body
          : (body['data'] is List ? body['data'] : []);

      return list
          .map((item) =>
              ScanMakananResult.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Silakan login untuk melihat riwayat scan makanan.');
    } else {
      throw Exception('Gagal memuat riwayat scan makanan.');
    }
  }

  /// Menghapus item riwayat scan makanan berdasarkan ID
  Future<void> deleteScanHistory(String id) async {
    final response = await _apiService.delete('/scan-makanan?id=$id');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception('Gagal menghapus riwayat scan.');
  }
}
