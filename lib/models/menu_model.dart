class MenuModel {
  final int id;
  final String namaMenu;
  final String slug;
  final String deskripsi;
  final num kalori;
  final String targetStatus;
  final int waktuMemasak;
  final int dibaca;
  final String gambar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuModel({
    required this.id,
    required this.namaMenu,
    required this.slug,
    required this.deskripsi,
    required this.kalori,
    required this.targetStatus,
    required this.waktuMemasak,
    this.dibaca = 0,
    required this.gambar,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      namaMenu: json['nama_menu']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString() ?? '',
      kalori: json['kalori'] is num
          ? json['kalori']
          : num.tryParse(json['kalori']?.toString() ?? '') ?? 0,
      targetStatus: json['target_status']?.toString() ?? '',
      waktuMemasak: json['waktu_memasak'] is int
          ? json['waktu_memasak']
          : int.tryParse(json['waktu_memasak']?.toString() ?? '') ?? 0,
      dibaca: json['dibaca'] is int
          ? json['dibaca']
          : int.tryParse(json['dibaca']?.toString() ?? '') ?? 0,
      gambar: json['gambar']?.toString() ?? '',
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
      'nama_menu': namaMenu,
      'slug': slug,
      'deskripsi': deskripsi,
      'kalori': kalori,
      'target_status': targetStatus,
      'waktu_memasak': waktuMemasak,
      'dibaca': dibaca,
      'gambar': gambar,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
