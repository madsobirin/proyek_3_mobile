class ScanMakananResult {
  final String? id;
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

  ScanMakananResult({
    this.id,
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
  });

  factory ScanMakananResult.fromJson(Map<String, dynamic> json) {
    double? parseNum(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    return ScanMakananResult(
      id: json['id']?.toString(),
      barcode: json['barcode']?.toString() ?? '',
      namaMakanan: json['nama_makanan']?.toString() ??
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'nama_makanan': namaMakanan,
      if (brand != null) 'brand': brand,
      if (imageUrl != null) 'image_url': imageUrl,
      if (kalori != null) 'kalori': kalori,
      if (protein != null) 'protein': protein,
      if (lemak != null) 'lemak': lemak,
      if (karbohidrat != null) 'karbohidrat': karbohidrat,
      if (gula != null) 'gula': gula,
    };
  }
}
