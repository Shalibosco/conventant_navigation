// lib/data/models/location_model.dart

import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'location_model.g.dart';

@HiveType(typeId: 0)
class LocationModel extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double latitude;

  @HiveField(4)
  final double longitude;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final String? imageAssetPath;

  @HiveField(7)
  final Map<String, String>? localizedNames;    // {yo: '...', ig: '...'}

  @HiveField(8)
  final Map<String, String>? localizedDescriptions;

  @HiveField(9)
  final List<String>? tags;

  @HiveField(10)
  final String? openingHours;

  @HiveField(11)
  final String? phoneNumber;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.imageAssetPath,
    this.localizedNames,
    this.localizedDescriptions,
    this.tags,
    this.openingHours,
    this.phoneNumber,
  });
// ── From JSON ─────────────────────────────────────────────
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String,
      imageAssetPath: json['imageAssetPath'] as String?,

      // Fixed: Cast json['localizedNames'] as Map to fix the 'dynamic' error 👇
      localizedNames: json['localizedNames'] != null
          ? Map<String, String>.from(json['localizedNames'] as Map)
          : null,

      // Fixed: Same casting applied here 👇
      localizedDescriptions: json['localizedDescriptions'] != null
          ? Map<String, String>.from(json['localizedDescriptions'] as Map)
          : null,

      // Fixed: Cast json['tags'] as List to fix the 'Iterable' error 👇
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,

      openingHours: json['openingHours'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  // ── To JSON ───────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
    'imageAssetPath': imageAssetPath,
    'localizedNames': localizedNames,
    'localizedDescriptions': localizedDescriptions,
    'tags': tags,
    'openingHours': openingHours,
    'phoneNumber': phoneNumber,
  };

  // ── Localized name getter ─────────────────────────────────
  String getLocalizedName(String langCode) {
    return localizedNames?[langCode] ?? name;
  }

  String getLocalizedDescription(String langCode) {
    return localizedDescriptions?[langCode] ?? description;
  }

  @override
  List<Object?> get props => [id, name, latitude, longitude, category];
}