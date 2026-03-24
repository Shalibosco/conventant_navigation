// lib/features/voice_assistant/services/voice_command_handler.dart

import '../../../data/models/location_model.dart';
import '../../../data/repositories/location_repository.dart';

enum VoiceCommandType {
  navigate,
  search,
  whereAmI,
  listCategory,
  help,
  unknown,
}

class VoiceCommand {
  final VoiceCommandType type;
  final String? query;
  final String? category;
  final LocationModel? resolvedLocation;

  const VoiceCommand({
    required this.type,
    this.query,
    this.category,
    this.resolvedLocation,
  });
}

class VoiceCommandHandler {
  final LocationRepository _locationRepo;

  VoiceCommandHandler(this._locationRepo);

  // ── Keyword maps per language ─────────────────────────────
  static const Map<String, List<String>> _navigateKeywords = {
    'en': ['go to', 'take me to', 'navigate to', 'show me', 'find', 'where is', 'directions to', 'how do i get to'],
    'yo': ['mu mi lo', 'fi han mi', 'wa'],
    'ig': ['were m gaa', 'chọta', 'gaa'],
    'pidgin': ['take me go', 'wia dey', 'how i go reach', 'find'],
  };

  static const Map<String, List<String>> _whereAmIKeywords = {
    'en': ['where am i', 'my location', 'current location', 'locate me'],
    'yo': ['ibo ni mo wa', 'ibi mi'],
    'ig': ['ebe nọ m', 'ebe m nọ'],
    'pidgin': ['wia i dey', 'my location'],
  };

  static const Map<String, List<String>> _categoryKeywords = {
    'en': ['show all', 'list all', 'all the', 'nearby'],
    'yo': ['gbogbo', 'fihan gbogbo'],
    'ig': ['gosi ihe nile', 'ihe nile'],
    'pidgin': ['show all', 'all di'],
  };

  static const Map<String, List<String>> _helpKeywords = {
    'en': ['help', 'what can you do', 'commands', 'how to use'],
    'yo': ['iranlowo', 'bawo'],
    'ig': ['enyemaka', 'otu esi'],
    'pidgin': ['help me', 'wetin you fit do'],
  };

  static const Map<String, String> _categoryMap = {
    'hostel': 'hostel', 'hall': 'hostel', 'dormitory': 'hostel',
    'accommodation': 'hostel', 'room': 'hostel',
    'class': 'academic', 'lecture': 'academic', 'building': 'academic',
    'faculty': 'academic', 'department': 'academic', 'lab': 'academic',
    'library': 'academic',
    'food': 'food', 'eat': 'food', 'cafeteria': 'food',
    'restaurant': 'food', 'eatery': 'food', 'canteen': 'food',
    'chapel': 'worship', 'church': 'worship', 'mosque': 'worship',
    'pray': 'worship', 'worship': 'worship',
    'sport': 'sports', 'gym': 'sports', 'field': 'sports',
    'pitch': 'sports', 'court': 'sports',
    'hospital': 'medical', 'clinic': 'medical', 'sick': 'medical',
    'medical': 'medical', 'pharmacy': 'medical', 'health': 'medical',
    'admin': 'admin', 'office': 'admin', 'management': 'admin',
    'senate': 'admin', 'registry': 'admin',
    'park': 'recreation', 'garden': 'recreation', 'relax': 'recreation',
  };

  Future<VoiceCommand> process(String text, String langCode) async {
    final normalized = text.toLowerCase().trim();

    // ── Where Am I ────────────────────────────────────────
    if (_matchesKeywords(normalized, _whereAmIKeywords[langCode] ?? _whereAmIKeywords['en']!)) {
      return const VoiceCommand(type: VoiceCommandType.whereAmI);
    }

    // ── Help ─────────────────────────────────────────────
    if (_matchesKeywords(normalized, _helpKeywords[langCode] ?? _helpKeywords['en']!)) {
      return const VoiceCommand(type: VoiceCommandType.help);
    }

    // ── Category listing ──────────────────────────────────
    if (_matchesKeywords(normalized, _categoryKeywords[langCode] ?? _categoryKeywords['en']!)) {
      final category = _extractCategory(normalized);
      if (category != null) {
        return VoiceCommand(type: VoiceCommandType.listCategory, category: category);
      }
    }

    // ── Navigation / Search ───────────────────────────────
    final navKeywords = _navigateKeywords[langCode] ?? _navigateKeywords['en']!;
    String? searchQuery;

    for (final keyword in navKeywords) {
      if (normalized.contains(keyword)) {
        searchQuery = normalized.replaceFirst(keyword, '').trim();
        break;
      }
    }
    searchQuery ??= normalized;

    if (searchQuery.isNotEmpty) {
      // Try to resolve to a known location
      final (locations, _) = await _locationRepo.searchLocations(searchQuery);
      if (locations != null && locations.isNotEmpty) {
        return VoiceCommand(
          type: VoiceCommandType.navigate,
          query: searchQuery,
          resolvedLocation: locations.first,
        );
      }

      // Check if it's a category search
      final category = _extractCategory(searchQuery);
      if (category != null) {
        return VoiceCommand(
          type: VoiceCommandType.listCategory,
          query: searchQuery,
          category: category,
        );
      }

      return VoiceCommand(
        type: VoiceCommandType.search,
        query: searchQuery,
      );
    }

    return const VoiceCommand(type: VoiceCommandType.unknown);
  }

  bool _matchesKeywords(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  String? _extractCategory(String text) {
    for (final entry in _categoryMap.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  // ── Response templates per language ──────────────────────
  String buildResponse(VoiceCommand command, String langCode) {
    switch (command.type) {
      case VoiceCommandType.navigate:
        final name = command.resolvedLocation?.getLocalizedName(langCode) ??
            command.query ?? '';
        return _localizedResponse(langCode,
          en: 'Navigating to $name. Follow the route on the map.',
          yo: 'Mo ń lọ sí $name. Tẹle ipa-ọna lórí maapu.',
          ig: 'Ana m agagharị gaa $name. Soro ụzọ n\'ime maapụ.',
          pidgin: 'I dey take you go $name. Follow di route for map.',
        );

      case VoiceCommandType.whereAmI:
        return _localizedResponse(langCode,
          en: 'Finding your current location on the map.',
          yo: 'Mo ń wa ibi tí o wà lórí maapu.',
          ig: 'Ana m achọta ebe i nọ ugbu a n\'ime maapụ.',
          pidgin: 'I dey find your current location for map.',
        );

      case VoiceCommandType.listCategory:
        final cat = command.category ?? '';
        return _localizedResponse(langCode,
          en: 'Showing all $cat locations on the map.',
          yo: 'Mo ń fihàn gbogbo àwọn ibi $cat lórí maapu.',
          ig: 'Ana m egosi ihe nile banyere $cat n\'ime maapụ.',
          pidgin: 'I dey show all $cat places for map.',
        );

      case VoiceCommandType.search:
        return _localizedResponse(langCode,
          en: 'Searching for ${command.query}.',
          yo: 'Mo ń wá ${command.query}.',
          ig: 'Ana m achọ ${command.query}.',
          pidgin: 'I dey search for ${command.query}.',
        );

      case VoiceCommandType.help:
        return _localizedResponse(langCode,
          en: 'You can say: Go to Library, Where am I, Show all hostels, or Find cafeteria.',
          yo: 'O lè sọ: Lọ sí Library, Ibo ni mo wà, Fihàn gbogbo hostels, tàbí Wá cafeteria.',
          ig: 'Ịnwere ike ikwu: Gaa Library, Ebe nọ m, Gosi ihe nile hostel, ma ọ bụ Chọta cafeteria.',
          pidgin: 'You fit talk: Take me go Library, Wia I dey, Show all hostels, or Find cafeteria.',
        );

      case VoiceCommandType.unknown:
        return _localizedResponse(langCode,
          en: 'Sorry, I did not understand. Try saying Go to Library or Find cafeteria.',
          yo: 'Ẹ jọ̀wọ́, mi ò gbọ́. Gbiyanju sọ Lọ sí Library tàbí Wá cafeteria.',
          ig: 'Ndo, Anọghị m nụ ihe ị kwuru. Nwaa ikwu Gaa Library ma ọ bụ Chọta cafeteria.',
          pidgin: 'Sorry, I no understand wetin you talk. Try talk: Take me go Library or Find cafeteria.',
        );
    }
  }

  String _localizedResponse(
      String langCode, {
        required String en,
        required String yo,
        required String ig,
        required String pidgin,
      }) {
    switch (langCode) {
      case 'yo': return yo;
      case 'ig': return ig;
      case 'pidgin': return pidgin;
      default: return en;
    }
  }
}