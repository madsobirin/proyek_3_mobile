import 'dart:convert';
import '../models/artikel_model.dart';
import 'api_service.dart';

class ArtikelService {
  final ApiService _api = ApiService();

  /// Ambil semua artikel (tanpa pagination → response = array langsung)
  Future<List<ArtikelModel>> getArtikels() async {
    try {
      final response = await _api.get('/artikels');
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Backend returns raw array langsung (tanpa pagination)
        if (body is List) {
          return body.map((item) => ArtikelModel.fromJson(item)).toList();
        }
        // Jika pakai pagination, response = { data: [...], meta: {...} }
        if (body is Map && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => ArtikelModel.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception(body['message'] ?? 'Gagal mengambil data artikel');
      }
    } catch (e) {
      throw Exception('Gagal mengambil data artikel: $e');
    }
  }

  /// Ambil artikel berdasarkan slug (gunakan query parameter)
  Future<ArtikelModel> getArtikelBySlug(String slug) async {
    try {
      final response = await _api.get('/artikels?slug=$slug');
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Tanpa pagination → response = array, ambil item pertama
        if (body is List && body.isNotEmpty) {
          return ArtikelModel.fromJson(body[0]);
        }
        // Dengan pagination → response = { data: [...] }
        if (body is Map && body['data'] is List && (body['data'] as List).isNotEmpty) {
          return ArtikelModel.fromJson(body['data'][0]);
        }
        throw Exception('Artikel tidak ditemukan');
      } else {
        throw Exception(body['message'] ?? 'Gagal mengambil detail artikel');
      }
    } catch (e) {
      throw Exception('Gagal mengambil detail artikel: $e');
    }
  }

  /// Ambil artikel berdasarkan kategori
  Future<List<ArtikelModel>> getArtikelsByKategori(String kategori) async {
    try {
      final response = await _api.get('/artikels?kategori=$kategori');
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is List) {
          return body.map((item) => ArtikelModel.fromJson(item)).toList();
        }
        if (body is Map && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => ArtikelModel.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception(body['message'] ?? 'Gagal mengambil data artikel');
      }
    } catch (e) {
      throw Exception('Gagal mengambil data artikel: $e');
    }
  }

  /// Ambil artikel featured
  Future<List<ArtikelModel>> getFeaturedArtikels() async {
    try {
      final response = await _api.get('/artikels?featured=true');
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is List) {
          return body.map((item) => ArtikelModel.fromJson(item)).toList();
        }
        if (body is Map && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => ArtikelModel.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception(body['message'] ?? 'Gagal mengambil data artikel');
      }
    } catch (e) {
      throw Exception('Gagal mengambil data artikel: $e');
    }
  }
}
