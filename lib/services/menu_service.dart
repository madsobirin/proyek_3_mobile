import 'dart:convert';
import '../models/menu_model.dart';
import 'api_service.dart';

class MenuService {
  final ApiService _api = ApiService();

  /// Ambil semua menu (tanpa pagination → response = array langsung)
  Future<List<MenuModel>> getMenus() async {
    try {
      final response = await _api.get('/menus');
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Backend returns raw array langsung (tanpa pagination)
        if (body is List) {
          return body.map((item) => MenuModel.fromJson(item)).toList();
        }
        // Jika pakai pagination, response = { data: [...], meta: {...} }
        if (body is Map && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => MenuModel.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception(body['message'] ?? 'Gagal mengambil data menu');
      }
    } catch (e) {
      throw Exception('Gagal mengambil data menu: $e');
    }
  }

  /// Ambil menu berdasarkan slug (response = single object langsung)
  Future<MenuModel> getMenuBySlug(String slug) async {
    try {
      final response = await _api.get('/menus/$slug');
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Backend returns single menu object langsung
        return MenuModel.fromJson(body);
      } else {
        throw Exception(body['message'] ?? 'Gagal mengambil detail menu');
      }
    } catch (e) {
      throw Exception('Gagal mengambil detail menu: $e');
    }
  }

  /// Ambil menu berdasarkan target status (Kurus/Normal/Berlebih/Obesitas)
  Future<List<MenuModel>> getMenusByTarget(String target) async {
    try {
      final response = await _api.get('/menus?target=$target');
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is List) {
          return body.map((item) => MenuModel.fromJson(item)).toList();
        }
        if (body is Map && body['data'] is List) {
          return (body['data'] as List)
              .map((item) => MenuModel.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception(body['message'] ?? 'Gagal mengambil data menu');
      }
    } catch (e) {
      throw Exception('Gagal mengambil data menu: $e');
    }
  }
}
