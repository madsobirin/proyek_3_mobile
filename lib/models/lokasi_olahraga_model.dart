import 'package:flutter/material.dart';

class LokasiOlahraga {
  final int id;
  final String name;
  final String category;
  final String address;
  final double latitude;
  final double longitude;

  const LokasiOlahraga({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory LokasiOlahraga.fromJson(Map<String, dynamic> json) {
    return LokasiOlahraga(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString().toLowerCase(),
      address: (json['address'] ?? '').toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  String get categoryLabel {
    switch (category) {
      case 'gym':
        return 'Gym';
      case 'lapangan':
        return 'Lapangan';
      case 'low_impact':
        return 'Aktivitas Ringan';
      default:
        return 'Lainnya';
    }
  }

  IconData get icon {
    switch (category) {
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'lapangan':
        return Icons.sports_soccer_rounded;
      case 'low_impact':
        final nameLower = name.toLowerCase();
        if (nameLower.contains('renang') || nameLower.contains('kolam')) {
          return Icons.pool_rounded;
        }
        return Icons.directions_run_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  Color get color {
    switch (category) {
      case 'gym':
        return Colors.deepOrange;
      case 'lapangan':
        return Colors.blue;
      case 'low_impact':
        return const Color(0xFF20603D);
      default:
        return Colors.grey;
    }
  }

  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'name': name,
      'category': categoryLabel,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': 'Belum diketahui',
      'rating': null,
      'reviews': null,
      'open': null,
      'hours': 'Jam buka belum tersedia',
      'icon': icon,
      'color': color,
      'mapQuery': '$latitude,$longitude',
    };
  }
}
