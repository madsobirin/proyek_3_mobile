import 'dart:math' as math;
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

  String get bmiLabel {
    switch (category) {
      case 'gym':
        return 'Underweight (Kurus)';
      case 'lapangan':
        return 'Normal';
      case 'low_impact':
        return 'Overweight / Obesitas';
      default:
        return 'Semua BMI';
    }
  }

  Map<String, dynamic> toDisplayMap({double? userLat, double? userLng}) {
    String distanceStr = 'Belum diketahui';
    double? distMeters;

    if (userLat != null && userLng != null && latitude != 0 && longitude != 0) {
      // Hitung jarak Haversine (dalam meter)
      const double earthRadius = 6371000; // meter
      final dLat = (latitude - userLat) * (3.141592653589793 / 180.0);
      final dLng = (longitude - userLng) * (3.141592653589793 / 180.0);
      final sinLat = math.sin(dLat / 2);
      final sinLng = math.sin(dLng / 2);
      final a = sinLat * sinLat +
          math.cos(userLat * 3.141592653589793 / 180.0) *
              math.cos(latitude * 3.141592653589793 / 180.0) *
              sinLng *
              sinLng;
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      distMeters = earthRadius * c;

      if (distMeters < 1000) {
        distanceStr = '${distMeters.round()} m';
      } else {
        distanceStr = '${(distMeters / 1000).toStringAsFixed(1)} km';
      }
    }

    return {
      'id': id,
      'name': name,
      'category': categoryLabel,
      'rawCategory': category,
      'bmiLabel': bmiLabel,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distanceStr,
      'distanceMeters': distMeters,
      'rating': null,
      'reviews': null,
      'open': null,
      'hours': 'Jam operasional fleksibel',
      'icon': icon,
      'color': color,
      'mapQuery': '$latitude,$longitude',
    };
  }
}

