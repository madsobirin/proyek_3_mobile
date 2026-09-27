import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/config.dart';
import '../models/analisis_kesehatan_model.dart';
import '../models/perhitungan_model.dart';
import 'api_service.dart';
import 'auth_services.dart';

class PerhitunganService {
  static final PerhitunganService _instance = PerhitunganService._internal();
  factory PerhitunganService() => _instance;
  PerhitunganService._internal();

  final ApiService _apiService = ApiService();
  final AuthServices _authServices = AuthServices();

  /// Menyimpan hasil kalkulasi kesehatan ke backend
  /// Hanya dijalankan jika pengguna sudah login.
  Future<bool> savePerhitungan(AnalisisKesehatan hasil) async {
    final token = await _authServices.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('User belum login (guest). Lewati penyimpanan ke backend.');
      return false;
    }

    final response = await _apiService.post(
      '/perhitungan',
      hasil.toApiPayload(),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Sesi login telah berakhir. Silakan masuk kembali.');
    } else {
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}
      throw Exception(
        data?['message'] ??
            'Gagal menyimpan riwayat perhitungan (${response.statusCode}).',
      );
    }
  }

  /// Mengambil daftar riwayat perhitungan pengguna yang sedang login
  Future<List<PerhitunganModel>> getHistory() async {
    final token = await _authServices.getToken();
    if (token == null || token.isEmpty) {
      return [];
    }

    final response = await _apiService.get('/perhitungan');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic body = jsonDecode(response.body);
      final List<dynamic> list = body is List
          ? body
          : (body is Map && body['data'] is List ? body['data'] : []);

      return list
          .map(
            (item) =>
                PerhitunganModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Sesi login berakhir. Silakan login kembali.');
    } else {
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}
      throw Exception(data?['message'] ?? 'Gagal memuat riwayat perhitungan.');
    }
  }

  /// Menghapus item riwayat perhitungan berdasarkan ID
  Future<void> deleteHistory(int id) async {
    final token = await _authServices.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Silakan masuk terlebih dahulu.');
    }

    final deleteUrl = '${Config.baseUrl}/perhitungan/$id';
    debugPrint('[DEBUG DELETE] GET record id: $id');
    debugPrint('[DEBUG DELETE] Model id: $id');
    debugPrint('[DEBUG DELETE] Delete id: $id');
    debugPrint('[DEBUG DELETE] DELETE URL: $deleteUrl');

    var response = await _apiService.delete('/perhitungan/$id');
    debugPrint('[DEBUG DELETE] HTTP status: ${response.statusCode}');
    debugPrint('[DEBUG DELETE] Response body: ${response.body}');

    // Jika 404 (misal backend production menangani DELETE via query param ?id=...),
    // lakukan fallback ke query parameter untuk kompatibilitas penuh.
    if (response.statusCode == 404) {
      final fallbackUrl = '${Config.baseUrl}/perhitungan?id=$id';
      debugPrint(
        '[DEBUG DELETE] Fallback attempt to query param DELETE URL: $fallbackUrl',
      );
      final fallbackResponse = await _apiService.delete('/perhitungan?id=$id');
      debugPrint(
        '[DEBUG DELETE] Fallback HTTP status: ${fallbackResponse.statusCode}',
      );
      debugPrint(
        '[DEBUG DELETE] Fallback Response body: ${fallbackResponse.body}',
      );
      if (fallbackResponse.statusCode >= 200 &&
          fallbackResponse.statusCode < 300) {
        response = fallbackResponse;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else {
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      final serverMessage = (data is Map && data['message'] is String)
          ? data['message'] as String
          : null;

      if (response.statusCode == 401) {
        throw Exception(
          serverMessage ?? 'Sesi login telah berakhir. Silakan login kembali.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          serverMessage ?? 'Anda tidak memiliki izin untuk menghapus data ini.',
        );
      } else if (response.statusCode == 404) {
        throw Exception(
          serverMessage ??
              'Catatan riwayat tidak ditemukan atau sudah dihapus.',
        );
      } else if (response.statusCode == 405) {
        throw Exception(
          serverMessage ?? 'Metode permintaan tidak diizinkan oleh server.',
        );
      } else if (response.statusCode >= 500) {
        throw Exception(
          serverMessage ??
              'Terjadi kesalahan pada server (${response.statusCode}). Silakan coba lagi nanti.',
        );
      } else {
        throw Exception(
          serverMessage ??
              'Gagal menghapus riwayat perhitungan (kode ${response.statusCode}).',
        );
      }
    }
  }
}
