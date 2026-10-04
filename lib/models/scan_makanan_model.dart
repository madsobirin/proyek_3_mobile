class ScanMakananResult {
  final String? id;
  final int? userId;
  final String barcode;
  final String namaMakanan;
  final String? brand;
  final String? imageUrl;
  final double? kalori;
  final double? protein;
  final double? lemak;
  final double? karbohidrat;
  final double? gula;
  final DateTime? createdAt;
  final bool? isFromCache;
  final String? dataSource;

  ScanMakananResult({
    this.id,
    this.userId,
    required this.barcode,
    required this.namaMakanan,
    this.brand,
    this.imageUrl,
    this.kalori,
    this.protein,
    this.lemak,
    this.karbohidrat,
    this.gula,
    this.createdAt,
    this.isFromCache,
    this.dataSource,
  });

  factory ScanMakananResult.fromJson(
    Map<String, dynamic> json, {
    bool? isFromCache,
    String? dataSource,
  }) {
    double? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    return ScanMakananResult(
      id: json['id']?.toString(),
      userId: parseInt(json['user_id'] ?? json['userId']),
      barcode: json['barcode']?.toString() ?? '',
      namaMakanan:
          json['nama_makanan']?.toString() ??
          json['namaMakanan']?.toString() ??
          'Produk Tanpa Nama',
      brand: json['brand']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      kalori: parseNum(json['kalori']),
      protein: parseNum(json['protein']),
      lemak: parseNum(json['lemak']),
      karbohidrat: parseNum(json['karbohidrat']),
      gula: parseNum(json['gula']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : (json['createdAt'] != null
                ? DateTime.tryParse(json['createdAt'].toString())
                : null),
      isFromCache:
          isFromCache ??
          (json['is_from_cache'] as bool? ?? json['isFromCache'] as bool?),
      dataSource: json['data_source']?.toString() ?? dataSource,
    );
  }

  /// Request body JSON untuk POST /api/scan-makanan/save
  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'nama_makanan': namaMakanan,
      if (brand != null && brand!.isNotEmpty) 'brand': brand,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
      if (kalori != null) 'kalori': kalori,
      if (protein != null) 'protein': protein,
      if (lemak != null) 'lemak': lemak,
      if (karbohidrat != null) 'karbohidrat': karbohidrat,
      if (gula != null) 'gula': gula,
    };
  }

  /// JSON lengkap untuk penyimpanan lokal (offline queue)
  Map<String, dynamic> toStorageJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'barcode': barcode,
      'nama_makanan': namaMakanan,
      if (brand != null) 'brand': brand,
      if (imageUrl != null) 'image_url': imageUrl,
      if (kalori != null) 'kalori': kalori,
      if (protein != null) 'protein': protein,
      if (lemak != null) 'lemak': lemak,
      if (karbohidrat != null) 'karbohidrat': karbohidrat,
      if (gula != null) 'gula': gula,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (isFromCache != null) 'is_from_cache': isFromCache,
      if (dataSource != null) 'data_source': dataSource,
    };
  }

  ScanMakananResult copyWith({
    String? id,
    int? userId,
    String? barcode,
    String? namaMakanan,
    String? brand,
    String? imageUrl,
    double? kalori,
    double? protein,
    double? lemak,
    double? karbohidrat,
    double? gula,
    DateTime? createdAt,
    bool? isFromCache,
    String? dataSource,
  }) {
    return ScanMakananResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      barcode: barcode ?? this.barcode,
      namaMakanan: namaMakanan ?? this.namaMakanan,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      kalori: kalori ?? this.kalori,
      protein: protein ?? this.protein,
      lemak: lemak ?? this.lemak,
      karbohidrat: karbohidrat ?? this.karbohidrat,
      gula: gula ?? this.gula,
      createdAt: createdAt ?? this.createdAt,
      isFromCache: isFromCache ?? this.isFromCache,
      dataSource: dataSource ?? this.dataSource,
    );
  }
}
