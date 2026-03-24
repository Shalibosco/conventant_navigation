// lib/data/models/info_model.dart

import 'package:equatable/equatable.dart';

class InfoModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String category;       // e.g., 'rule', 'facility', 'contact', 'event'
  final String? iconName;
  final Map<String, String>? localizedTitles;
  final Map<String, String>? localizedContent;
  final String? lastUpdated;

  const InfoModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.iconName,
    this.localizedTitles,
    this.localizedContent,
    this.lastUpdated,
  });

  factory InfoModel.fromJson(Map<String, dynamic> json) {
    return InfoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      iconName: json['iconName'] as String?,

      // Fixed: Cast json['localizedTitles'] as Map to fix the 'dynamic' error 👇
      localizedTitles: json['localizedTitles'] != null
          ? Map<String, String>.from(json['localizedTitles'] as Map)
          : null,

      // Fixed: Same casting applied here 👇
      localizedContent: json['localizedContent'] != null
          ? Map<String, String>.from(json['localizedContent'] as Map)
          : null,

      lastUpdated: json['lastUpdated'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'iconName': iconName,
    'localizedTitles': localizedTitles,
    'localizedContent': localizedContent,
    'lastUpdated': lastUpdated,
  };

  String getLocalizedTitle(String langCode) =>
      localizedTitles?[langCode] ?? title;

  String getLocalizedContent(String langCode) =>
      localizedContent?[langCode] ?? content;

  @override
  List<Object?> get props => [id, title, category];
}