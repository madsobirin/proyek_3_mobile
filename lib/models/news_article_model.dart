class NewsArticleModel {
  final String title;
  final String description;
  final String url;
  final String? image;
  final String source;
  final String? author;
  final DateTime? publishedAt;

  const NewsArticleModel({
    required this.title,
    required this.description,
    required this.url,
    this.image,
    required this.source,
    this.author,
    this.publishedAt,
  });

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['publishedAt'] != null) {
      parsedDate = DateTime.tryParse(json['publishedAt'].toString())?.toLocal();
    }

    return NewsArticleModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      image: json['image'] as String?,
      source: json['source'] ?? 'Berita',
      author: json['author'] as String?,
      publishedAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'image': image,
      'source': source,
      'author': author,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}

class NewsResponseModel {
  final String status;
  final int totalResults;
  final List<NewsArticleModel> articles;

  const NewsResponseModel({
    required this.status,
    required this.totalResults,
    required this.articles,
  });

  factory NewsResponseModel.fromJson(Map<String, dynamic> json) {
    final rawArticles = json['articles'];
    final List<NewsArticleModel> parsedArticles = [];

    if (rawArticles is List) {
      for (final item in rawArticles) {
        if (item is Map<String, dynamic>) {
          parsedArticles.add(NewsArticleModel.fromJson(item));
        } else if (item is Map) {
          parsedArticles.add(
            NewsArticleModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return NewsResponseModel(
      status: json['status']?.toString() ?? 'ok',
      totalResults: json['totalResults'] is int
          ? json['totalResults'] as int
          : int.tryParse(json['totalResults']?.toString() ?? '0') ?? parsedArticles.length,
      articles: parsedArticles,
    );
  }
}
