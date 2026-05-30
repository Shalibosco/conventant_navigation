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
    final rawCategory = (json['category'] as String? ?? 'facility').toLowerCase();
    final normalizedCategory = _normalizeCategory(rawCategory);

    final localizedTitlesRaw = json['localizedTitles'] ?? json['localizedNames'];
    final localizedContentRaw = json['localizedContent'] ?? json['localizedDescriptions'];

    return InfoModel(
      id: json['id'] as String,
      title: (json['title'] ?? json['name'] ?? 'Untitled').toString(),
      content: (json['content'] ?? json['description'] ?? '').toString(),
      category: normalizedCategory,
      iconName: (json['iconName'] as String?) ?? _defaultIconForCategory(normalizedCategory),

      localizedTitles: localizedTitlesRaw != null
          ? Map<String, String>.from(localizedTitlesRaw as Map)
          : null,

      localizedContent: localizedContentRaw != null
          ? Map<String, String>.from(localizedContentRaw as Map)
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

  static String _normalizeCategory(String category) {
    switch (category) {
      case 'rule':
      case 'facility':
      case 'contact':
      case 'event':
        return category;
      case 'admin':
        return 'contact';
      default:
        return 'facility';
    }
  }

  static String _defaultIconForCategory(String category) {
    switch (category) {
      case 'rule':
        return 'rule';
      case 'contact':
        return 'admin';
      case 'event':
        return 'event';
      default:
        return 'academic';
    }
  }

  @override
  List<Object?> get props => [id, title, category];
}
