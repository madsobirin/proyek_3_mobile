import 'dart:convert';
import '../models/news_article_model.dart';
import 'api_service.dart';

class NewsService {
  final ApiService _api = ApiService();

  Future<NewsResponseModel> getNews({
    int page = 1,
    int pageSize = 10,
    String? q,
  }) async {
    try {
      final queryParams = <String>[
        'page=$page',
        'pageSize=$pageSize',
      ];
      if (q != null && q.trim().isNotEmpty) {
        queryParams.add('q=${Uri.encodeComponent(q.trim())}');
      }

      final endpoint = '/news?${queryParams.join('&')}';
      final response = await _api.get(endpoint);
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          return NewsResponseModel.fromJson(body);
        } else if (body is Map) {
          return NewsResponseModel.fromJson(Map<String, dynamic>.from(body));
        }
        throw Exception('Format response berita tidak valid');
      } else {
        throw Exception(body['message'] ?? 'Gagal mengambil data berita');
      }
    } catch (e) {
      throw Exception('Gagal mengambil data berita: $e');
    }
  }
}
