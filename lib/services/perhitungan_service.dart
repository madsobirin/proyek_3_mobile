import 'dart:convert';
import 'package:flutter/foundation.dart';
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

    final response = await _apiService.delete('/perhitungan/$id');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else if (response.statusCode == 404 || response.statusCode == 405) {
      throw Exception(
        'Fitur hapus riwayat belum didukung oleh server backend.',
      );
    } else if (response.statusCode == 401) {
      throw Exception('Sesi login telah berakhir. Silakan login kembali.');
    } else {
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}
      throw Exception(
        data?['message'] ?? 'Gagal menghapus item riwayat ($id).',
      );
    }
  }
}
