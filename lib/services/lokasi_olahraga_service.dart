import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lokasi_olahraga_model.dart';

class LokasiOlahragaService {
  LokasiOlahragaService._();

  static final LokasiOlahragaService instance = LokasiOlahragaService._();

  static const String _baseUrl = 'https://fitlife.my.id/api/lokasi-olahraga';
  List<LokasiOlahraga>? _cachedLocations;

  List<LokasiOlahraga>? get cachedLocations => _cachedLocations;

  Future<List<LokasiOlahraga>> fetchAll({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedLocations != null && _cachedLocations!.isNotEmpty) {
      return _cachedLocations!;
    }

    final response = await http
        .get(Uri.parse(_baseUrl), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gagal mengambil lokasi olahraga (HTTP ${response.statusCode})',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    // API saat ini mengembalikan array JSON langsung.
    if (decoded is! List) {
      throw const FormatException(
        'Format API lokasi olahraga bukan array JSON.',
      );
    }

    final list = decoded
        .whereType<Map<String, dynamic>>()
        .map(LokasiOlahraga.fromJson)
        .toList();
    _cachedLocations = list;
    return list;
  }

  Future<List<LokasiOlahraga>> fetchFiltered({
    String? category,
    String searchQuery = '',
  }) async {
    final all = await fetchAll();
    final query = searchQuery.trim().toLowerCase();

    return all.where((location) {
      final categoryMatch =
          category == null ||
          category == 'Semua' ||
          location.categoryLabel.toLowerCase() == category.toLowerCase();
      final searchMatch =
          query.isEmpty ||
          location.name.toLowerCase().contains(query) ||
          location.address.toLowerCase().contains(query);
      return categoryMatch && searchMatch;
    }).toList();
  }
}
