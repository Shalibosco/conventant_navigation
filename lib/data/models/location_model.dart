// lib/data/models/location_model.dart
import 'package:hive/hive.dart';

part 'location_model.g.dart';  // Add this line for Hive code generation

@HiveType(typeId: 1)  // Add Hive annotation
class LocationModel extends HiveObject {  // Extend HiveObject
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String type;

  @HiveField(6)
  final String? buildingCode;

  @HiveField(7)
  final String? floor;

  @HiveField(8)
  final List<String>? tags;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.type,
    this.buildingCode,
    this.floor,
    this.tags,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'building',
      buildingCode: json['buildingCode'] as String?,
      floor: json['floor'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List<dynamic>)
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'type': type,
      'buildingCode': buildingCode,
      'floor': floor,
      'tags': tags,
    };
  }
}