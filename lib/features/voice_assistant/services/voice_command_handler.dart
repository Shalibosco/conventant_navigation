// lib/features/voice_assistant/services/voice_command_handler.dart

import '../../../data/models/location_model.dart';
import '../../../data/repositories/location_repository.dart';

enum VoiceCommandType {
  navigate,
  whereAmI,
  listCategory,
  search,
  help,
  unknown,
}

class VoiceCommand {
  final VoiceCommandType type;
  final String? query;
  final String? category;
  final LocationModel? resolvedLocation;
  final int? matchCount;
  const VoiceCommand({
    required this.type,
    this.query,
    this.category,
    this.resolvedLocation,
    this.matchCount,
  });
}

class VoiceCommandHandler {
  final LocationRepository _repo;
  VoiceCommandHandler(this._repo);

  static const _navKeywords = {
    'en': [
      'go to',
      'take me to',
      'navigate to',
      'show me',
      'where is',
      'find',
      'route to',
      'directions to',
      'how do i get to',
    ],
    'yo': ['mu mi lo', 'fi han mi', 'wa', 'lo si'],
    'ig': ['were m gaa', 'chota', 'gaa', 'gosi m'],
    'pidgin': [
      'take me go',
      'wia dey',
      'how i go reach',
      'find',
      'carry me go',
    ],
  };
  static const _whereAmIKeywords = {
    'en': ['where am i', 'my location', 'current location', 'locate me'],
    'yo': ['ibo ni mo wa', 'ibi mi', 'wa ni ibo'],
    'ig': ['ebe no m', 'ebe m no', 'ebe nolu m'],
    'pidgin': ['wia i dey', 'my location', 'wia i dey now'],
  };
  static const _helpKeywords = {
    'en': ['help', 'what can you do', 'commands', 'how to use'],
    'yo': ['iranlowo', 'bawo', 'se o le'],
    'ig': ['enyemaka', 'otu esi'],
    'pidgin': ['help me', 'wetin you fit do', 'how you take use'],
  };
  static const _categoryKeywords = {
    'en': ['show all', 'list all', 'all the', 'nearby'],
    'yo': ['gbogbo', 'fihan gbogbo'],
    'ig': ['gosi ihe nile', 'ihe nile'],
    'pidgin': ['show all', 'all di', 'show me all'],
  };
  static const _catMap = {
    'hostel': 'hostel',
    'hall': 'hostel',
    'dormitory': 'hostel',
    'accommodation': 'hostel',
    'class': 'academic',
    'lecture': 'academic',
    'building': 'academic',
    'faculty': 'academic',
    'department': 'academic',
    'lab': 'academic',
    'library': 'academic',
    'cst': 'academic',
    'food': 'food',
    'eat': 'food',
    'cafeteria': 'food',
    'restaurant': 'food',
    'canteen': 'food',
    'chapel': 'worship',
    'church': 'worship',
    'worship': 'worship',
    'pray': 'worship',
    'sport': 'sports',
    'gym': 'sports',
    'field': 'sports',
    'stadium': 'sports',
    'hospital': 'medical',
    'clinic': 'medical',
    'medical': 'medical',
    'health': 'medical',
    'admin': 'admin',
    'office': 'admin',
    'senate': 'admin',
    'gate': 'admin',
    'park': 'recreation',
    'square': 'recreation',
    'relax': 'recreation',
    'eagle': 'recreation',
  };

  Future<VoiceCommand> process(String text, String lang) async {
    final t = _normalize(text);
    if (t.isEmpty) return const VoiceCommand(type: VoiceCommandType.unknown);

    if (_matches(t, _whereAmIKeywords[lang] ?? _whereAmIKeywords['en']!)) {
      return const VoiceCommand(type: VoiceCommandType.whereAmI);
    }

    if (_matches(t, _helpKeywords[lang] ?? _helpKeywords['en']!)) {
      return const VoiceCommand(type: VoiceCommandType.help);
    }

    final extractedCategory = _extractCat(t);
    if (_matches(t, _categoryKeywords[lang] ?? _categoryKeywords['en']!)) {
      if (extractedCategory != null) {
        return VoiceCommand(
          type: VoiceCommandType.listCategory,
          category: extractedCategory,
        );
      }
    }

    final navKeys = _navKeywords[lang] ?? _navKeywords['en']!;
    String query = t;
    var hasNavigationKeyword = false;
    for (final kw in navKeys) {
      if (t.contains(_normalize(kw))) {
        query = t.replaceFirst(_normalize(kw), '').trim();
        hasNavigationKeyword = true;
        break;
      }
    }
    query = _cleanNavigationQuery(query);

    if (query.isEmpty && extractedCategory != null) {
      return VoiceCommand(
        type: VoiceCommandType.listCategory,
        category: extractedCategory,
      );
    }

    if (query.isNotEmpty) {
      final (locs, _) = await _repo.searchLocations(query);
      if (locs != null && locs.isNotEmpty) {
        final exactMatches = locs
            .where((loc) => _isExactLocationMatch(loc, query))
            .toList();

        if (exactMatches.length == 1) {
          return VoiceCommand(
            type: VoiceCommandType.navigate,
            query: query,
            resolvedLocation: exactMatches.first,
            matchCount: 1,
          );
        }

        final wordCount = _wordCount(query);
        if (wordCount <= 1) {
          return VoiceCommand(
            type: VoiceCommandType.search,
            query: query,
            matchCount: locs.length,
          );
        }

        if (!hasNavigationKeyword) {
          return VoiceCommand(
            type: VoiceCommandType.search,
            query: query,
            matchCount: locs.length,
          );
        }

        final (bestMatch, bestScore) = _resolveBestLocationFromMatches(
          query,
          locs,
        );
        if (bestMatch != null && bestScore >= 120) {
          return VoiceCommand(
            type: VoiceCommandType.navigate,
            query: query,
            resolvedLocation: bestMatch,
            matchCount: locs.length,
          );
        }

        return VoiceCommand(
          type: VoiceCommandType.search,
          query: query,
          matchCount: locs.length,
        );
      }

      final cat = _extractCat(query);
      if (cat != null) {
        if (!hasNavigationKeyword) {
          return VoiceCommand(
            type: VoiceCommandType.listCategory,
            query: query,
            category: cat,
          );
        }
      }
      if (hasNavigationKeyword) {
        return VoiceCommand(type: VoiceCommandType.search, query: query);
      }
      return VoiceCommand(type: VoiceCommandType.search, query: query);
    }

    return const VoiceCommand(type: VoiceCommandType.unknown);
  }

  bool _matches(String t, List<String> kws) =>
      kws.any((k) => t.contains(_normalize(k)));

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanNavigationQuery(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return normalized;

    const fillerWords = {
      'a',
      'an',
      'can',
      'could',
      'kindly',
      'me',
      'now',
      'please',
      'the',
      'to',
      'would',
      'you',
    };

    final words = normalized
        .split(' ')
        .where((word) => word.isNotEmpty && !fillerWords.contains(word))
        .toList();
    return words.join(' ');
  }

  bool _isExactLocationMatch(LocationModel loc, String query) {
    final normalizedQuery = _normalize(query);
    return _locationSearchFields(
      loc,
    ).any((field) => _normalize(field) == normalizedQuery);
  }

  int _wordCount(String text) {
    final parts = _normalize(text).split(' ');
    return parts.where((part) => part.trim().isNotEmpty).length;
  }

  (LocationModel?, int) _resolveBestLocationFromMatches(
    String query,
    List<LocationModel> locs,
  ) {
    final normalizedQuery = _normalize(query);
    LocationModel? best;
    var bestScore = -1;

    for (final loc in locs) {
      final score = _scoreLocation(loc, normalizedQuery);
      if (score > bestScore) {
        bestScore = score;
        best = loc;
      }
    }

    return (best ?? locs.first, bestScore);
  }

  int _scoreLocation(LocationModel loc, String query) {
    var score = 0;
    final fields = _locationSearchFields(loc);

    for (final field in fields) {
      final normalized = _normalize(field);
      if (normalized == query) {
        score += 120;
      } else if (normalized.startsWith(query)) {
        score += 80;
      } else if (normalized.contains(query)) {
        score += 40;
      }
    }

    return score;
  }

  List<String> _locationSearchFields(LocationModel loc) {
    return <String>[
      loc.name,
      loc.description,
      loc.category,
      ...?loc.localizedNames?.values,
      ...?loc.localizedDescriptions?.values,
      ...?loc.tags,
    ];
  }

  String? _extractCat(String t) {
    for (final e in _catMap.entries) {
      if (t.contains(_normalize(e.key))) return e.value;
    }
    return null;
  }

  // ── Spoken responses in all 4 languages ──────────────────
  String buildResponse(VoiceCommand cmd, String lang) {
    final name =
        cmd.resolvedLocation?.getLocalizedName(lang) ?? cmd.query ?? '';
    final info = _locationInfoSnippet(cmd.resolvedLocation, lang);
    final infoPart = info.isNotEmpty ? '$info ' : '';
    switch (cmd.type) {
      case VoiceCommandType.navigate:
        return _r(
          lang,
          en: 'Navigating to $name. ${infoPart}Follow the route on the map.',
          yo: 'Mo ń lọ sí $name. ${infoPart}Tẹle ipa-ọna lórí maapu.',
          ig: 'Ana m agagharị gaa $name. ${infoPart}Soro ụzọ ahụ n\'ime maapụ.',
          pid: 'I dey take you go $name. ${infoPart}Follow route for map.',
        );
      case VoiceCommandType.whereAmI:
        return _r(
          lang,
          en: 'Showing your current location on the map.',
          yo: 'Mo ń fihàn ibi tí o wà lórí maapu.',
          ig: 'Ana m egosi ebe i nọ ugbu a n\'ime maapụ.',
          pid: 'I dey show your current location for map.',
        );
      case VoiceCommandType.listCategory:
        return _r(
          lang,
          en: 'Showing all ${cmd.category} locations.',
          yo: 'Mo ń fihàn gbogbo àwọn ibi ${cmd.category}.',
          ig: 'Ana m egosi ụlọ ${cmd.category} nile.',
          pid: 'I dey show all ${cmd.category} places for map.',
        );
      case VoiceCommandType.search:
        final count = cmd.matchCount ?? 0;
        return _r(
          lang,
          en: count > 0
              ? 'I found $count matching locations for ${cmd.query}. Check the list on the map.'
              : 'Searching for ${cmd.query}.',
          yo: count > 0
              ? 'Mo rí ibi $count tó ba ${cmd.query} mu. Wo akojọ lori maapu.'
              : 'Mo ń wá ${cmd.query}.',
          ig: count > 0
              ? 'Achọtara m ebe $count dakọtara na ${cmd.query}. Lelee ndepụta na maapụ.'
              : 'Ana m achọ ${cmd.query}.',
          pid: count > 0
              ? 'I see $count places wey match ${cmd.query}. Check the list for map.'
              : 'I dey search for ${cmd.query}.',
        );
      case VoiceCommandType.help:
        return _r(
          lang,
          en: 'Say: Go to Chapel, Where am I, Show all hostels, or Find cafeteria.',
          yo: 'Sọ: Lọ sí Chapel, Ibo ni mo wà, Fihàn gbogbo hostels.',
          ig: 'Kwuo: Gaa Chapel, Ebe nọ m, Gosi hostel nile.',
          pid: 'Talk: Take me go Chapel, Wia I dey, Show all hostels.',
        );
      default:
        return _r(
          lang,
          en: 'Sorry, I did not understand. Try saying Go to Library.',
          yo: 'Ẹ jọwọ, mi ò gbọ. Gbiyanju sọ Lọ sí Library.',
          ig: 'Ndo, Anọghị m nụ. Nwaa ikwu Gaa Library.',
          pid: 'Sorry, I no hear well. Try talk: Take me go Library.',
        );
    }
  }

  String _locationInfoSnippet(LocationModel? loc, String lang) {
    if (loc == null) return '';
    final description = loc.getLocalizedDescription(lang).trim();
    if (description.isEmpty) return '';

    final firstSentence = description.split(RegExp(r'[.!?]')).first.trim();
    final compact = firstSentence.isEmpty ? description : firstSentence;
    final clipped = compact.length > 90
        ? '${compact.substring(0, 90)}...'
        : compact;
    return clipped;
  }

  String _r(
    String lang, {
    required String en,
    required String yo,
    required String ig,
    required String pid,
  }) {
    switch (lang) {
      case 'yo':
        return yo;
      case 'ig':
        return ig;
      case 'pidgin':
        return pid;
      default:
        return en;
    }
  }
}
