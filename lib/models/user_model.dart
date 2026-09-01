class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? token;
  final String? username;
  final String? phone;
  final String? birthdate;
  final int? weight;
  final int? height;
  final String? photo;
  final String? googleAvatar;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
    this.username,
    this.phone,
    this.birthdate,
    this.weight,
    this.height,
    this.photo,
    this.googleAvatar,
    this.isActive = true,
  });

  static String _toString(dynamic value, [String fallback = '']) {
    if (value is List) {
      return value.isNotEmpty ? value.first.toString() : fallback;
    }
    return value?.toString() ?? fallback;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: _toString(json['name']),
      email: _toString(json['email']),
      role: _toString(json['role']),
      token: json['token']?.toString(),
      username: json['username']?.toString(),
      phone: json['phone']?.toString(),
      birthdate: json['birthdate']?.toString(),
      weight: json['weight'] is int
          ? json['weight']
          : int.tryParse(json['weight']?.toString() ?? ''),
      height: json['height'] is int
          ? json['height']
          : int.tryParse(json['height']?.toString() ?? ''),
      photo: json['photo']?.toString(),
      googleAvatar: json['google_avatar']?.toString(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'token': token,
      'username': username,
      'phone': phone,
      'birthdate': birthdate,
      'weight': weight,
      'height': height,
      'photo': photo,
      'google_avatar': googleAvatar,
      'is_active': isActive,
    };
  }
}
