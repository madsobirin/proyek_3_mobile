class ArtikelModel {
  final int id;
  final String judul;
  final String slug;
  final String kategori;
  final String penulis;
  final String isi;
  final String gambar;
  final bool isFeatured;
  final int dibaca;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ArtikelModel({
    required this.id,
    required this.judul,
    required this.slug,
    required this.kategori,
    required this.penulis,
    required this.isi,
    required this.gambar,
    this.isFeatured = false,
    this.dibaca = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ArtikelModel.fromJson(Map<String, dynamic> json) {
    return ArtikelModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      judul: json['judul']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? '',
      penulis: json['penulis']?.toString() ?? 'Admin',
      isi: json['isi']?.toString() ?? '',
      gambar: json['gambar']?.toString() ?? '',
      isFeatured: json['is_featured'] == true,
      dibaca: json['dibaca'] is int
          ? json['dibaca']
          : int.tryParse(json['dibaca']?.toString() ?? '') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'slug': slug,
      'kategori': kategori,
      'penulis': penulis,
      'isi': isi,
      'gambar': gambar,
      'is_featured': isFeatured,
      'dibaca': dibaca,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ArtikelModel copyWith({
    int? id,
    String? judul,
    String? slug,
    String? kategori,
    String? penulis,
    String? isi,
    String? gambar,
    bool? isFeatured,
    int? dibaca,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtikelModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      slug: slug ?? this.slug,
      kategori: kategori ?? this.kategori,
      penulis: penulis ?? this.penulis,
      isi: isi ?? this.isi,
      gambar: gambar ?? this.gambar,
      isFeatured: isFeatured ?? this.isFeatured,
      dibaca: dibaca ?? this.dibaca,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
