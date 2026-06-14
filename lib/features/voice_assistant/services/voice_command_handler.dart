// lib/features/voice_assistant/services/voice_command_handler.dart

import '../../../data/models/location_model.dart';
import '../../../data/repositories/location_repository.dart';

// ── Command types ─────────────────────────────────────────────────────────────

enum VoiceCommandType { navigate, whereAmI, listCategory, search, help, unknown }

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

// ── Constants ─────────────────────────────────────────────────────────────────

/// All keyword maps keyed by language code.
/// Using Sets for O(1) membership checks on single-word keywords where
/// possible; multi-word phrases still require a substring scan.
class _Keywords {
  static const Map<String, List<String>> nav = {
    'en': [
      'go to', 'take me to', 'take me', 'navigate to', 'navigate me to',
      'show me', 'where is', 'find', 'route to', 'route me to',
      'direct me to', 'directions to', 'directions for',
      'how do i get to', 'lead me to',
    ],
    'yo': ['mu mi lo', 'fi han mi', 'wa', 'lo si'],
    'ig': ['were m gaa', 'chota', 'gaa', 'gosi m'],
    'pidgin': ['take me go', 'wia dey', 'how i go reach', 'find', 'carry me go'],
  };

  static const Map<String, List<String>> whereAmI = {
    'en': ['where am i', 'my location', 'current location', 'locate me'],
    'yo': ['ibo ni mo wa', 'ibi mi', 'wa ni ibo'],
    'ig': ['ebe no m', 'ebe m no', 'ebe nolu m'],
    'pidgin': ['wia i dey', 'my location', 'wia i dey now'],
  };

  static const Map<String, List<String>> help = {
    'en': ['help', 'what can you do', 'commands', 'how to use'],
    'yo': ['iranlowo', 'bawo', 'se o le'],
    'ig': ['enyemaka', 'otu esi'],
    'pidgin': ['help me', 'wetin you fit do', 'how you take use'],
  };

  static const Map<String, List<String>> category = {
    'en': ['show all', 'list all', 'all the', 'nearby'],
    'yo': ['gbogbo', 'fihan gbogbo'],
    'ig': ['gosi ihe nile', 'ihe nile'],
    'pidgin': ['show all', 'all di', 'show me all'],
  };
}

/// Maps surface words → canonical category slugs.
const Map<String, String> _catMap = {
  'hostel': 'hostel', 'hall': 'hostel', 'dormitory': 'hostel',
  'accommodation': 'hostel', 'class': 'academic', 'lecture': 'academic',
  'building': 'academic', 'faculty': 'academic', 'department': 'academic',
  'lab': 'academic', 'library': 'academic', 'cst': 'academic',
  'food': 'food', 'eat': 'food', 'cafeteria': 'food',
  'restaurant': 'food', 'canteen': 'food',
  'chapel': 'worship', 'church': 'worship', 'worship': 'worship',
  'pray': 'worship',
  'sport': 'sports', 'gym': 'sports', 'field': 'sports', 'stadium': 'sports',
  'hospital': 'medical', 'clinic': 'medical', 'medical': 'medical',
  'health': 'medical',
  'admin': 'admin', 'office': 'admin', 'senate': 'admin', 'gate': 'admin',
  'park': 'recreation', 'square': 'recreation', 'relax': 'recreation',
  'eagle': 'recreation',
};

/// Common phrasings → canonical query strings.
const Map<String, String> _queryAliases = {
  'chapel of light': 'chapel', 'university chapel': 'chapel',
  'church auditorium': 'chapel', 'main library': 'library',
  'school library': 'library', 'learning resource centre': 'library',
  'learning resource center': 'library',
  'centre for learning resources': 'library',
  'center for learning resources': 'library',
  'medical center': 'medical centre', 'health center': 'medical centre',
  'health centre': 'medical centre', 'clinic': 'medical centre',
  'main gate': 'gate', 'school gate': 'gate',
  'sports complex': 'stadium', 'football field': 'stadium',
  'lecture hall': 'lecture theatre', 'lecture theater': 'lecture theatre',
  'entrepreneurship building': 'ceds',
  'post graduate hall': 'postgraduate hall',
  'pg hall': 'postgraduate hall', 'pg hostel': 'postgraduate hall',
};

/// Words stripped from a query before searching.
const Set<String> _queryStopWords = {
  'a', 'an', 'at', 'building', 'center', 'centre', 'for',
  'hall', 'house', 'main', 'of', 'the', 'to', 'university',
};

/// Words stripped from raw transcript before intent detection.
const Set<String> _fillerWords = {
  'a', 'an', 'can', 'could', 'kindly', 'me', 'now',
  'please', 'the', 'to', 'would', 'you',
};

/// Safety cap: transcripts longer than this are truncated before processing.
const int _maxInputLength = 300;

/// Minimum fuzzy score to accept a best-match result.
const int _minSearchScore = 85;
const int _minFallbackScore = 70;

// ── Handler ───────────────────────────────────────────────────────────────────

class VoiceCommandHandler {
  final LocationRepository _repo;

  VoiceCommandHandler(this._repo);

  // ── Cache ───────────────────────────────────────────────────────────────────

  /// Full location list is fetched at most once and reused for fallback scoring.
  List<LocationModel>? _allLocationsCache;

  Future<List<LocationModel>> _getAllLocations() async {
    if (_allLocationsCache != null) return _allLocationsCache!;
    final (locs, _) = await _repo.getAllLocations();
    _allLocationsCache = locs ?? [];
    return _allLocationsCache!;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<VoiceCommand> process(String text, String lang) async {
    // Guard against empty or excessively long input.
    final raw = text.length > _maxInputLength
        ? text.substring(0, _maxInputLength)
        : text;
    final t = _normalize(raw);
    if (t.isEmpty) return const VoiceCommand(type: VoiceCommandType.unknown);

    return _tryWhereAmI(t, lang) ??
        _tryHelp(t, lang) ??
        _tryCategory(t, lang) ??
        await _tryNavigateOrSearch(t, lang) ??
        const VoiceCommand(type: VoiceCommandType.unknown);
  }

  // ── Intent resolvers ────────────────────────────────────────────────────────

  VoiceCommand? _tryWhereAmI(String t, String lang) {
    if (!_matchesAny(t, _Keywords.whereAmI[lang] ?? _Keywords.whereAmI['en']!)) {
      return null;
    }
    return const VoiceCommand(type: VoiceCommandType.whereAmI);
  }

  VoiceCommand? _tryHelp(String t, String lang) {
    if (!_matchesAny(t, _Keywords.help[lang] ?? _Keywords.help['en']!)) {
      return null;
    }
    return const VoiceCommand(type: VoiceCommandType.help);
  }

  VoiceCommand? _tryCategory(String t, String lang) {
    if (!_matchesAny(t, _Keywords.category[lang] ?? _Keywords.category['en']!)) {
      return null;
    }
    final cat = _extractCategory(t);
    if (cat == null) return null;
    return VoiceCommand(type: VoiceCommandType.listCategory, category: cat);
  }

  Future<VoiceCommand?> _tryNavigateOrSearch(String t, String lang) async {
    final navKeys = _Keywords.nav[lang] ?? _Keywords.nav['en']!;

    // Strip navigation keyword from the front, noting whether one was present.
    String query = t;
    bool hasNavKeyword = false;
    for (final kw in navKeys) {
      final normalized = _normalize(kw);
      if (t.contains(normalized)) {
        query = t.replaceFirst(normalized, '').trim();
        hasNavKeyword = true;
        break;
      }
    }

    query = _prepareQuery(query);

    // If no meaningful query remains, try resolving from category alone.
    if (query.isEmpty) {
      final cat = _extractCategory(t);
      if (cat != null) {
        return VoiceCommand(type: VoiceCommandType.listCategory, category: cat);
      }
      return null;
    }

    // ── Repository search ────────────────────────────────────────────────────
    final (locs, _) = await _repo.searchLocations(query);
    if (locs != null && locs.isNotEmpty) {
      return _resolveFromResults(
        query: query,
        locs: locs,
        hasNavKeyword: hasNavKeyword,
      );
    }

    // ── Fallback: full-corpus scan (result cached) ───────────────────────────
    if (hasNavKeyword) {
      final fallback = await _fallbackLocationSearch(query);
      if (fallback != null) {
        return VoiceCommand(
          type: VoiceCommandType.navigate,
          query: query,
          resolvedLocation: fallback,
          matchCount: 1,
        );
      }
    }

    // ── Category as last resort ──────────────────────────────────────────────
    final cat = _extractCategory(query);
    if (cat != null) {
      return VoiceCommand(
        type: hasNavKeyword
            ? VoiceCommandType.listCategory
            : VoiceCommandType.listCategory,
        query: query,
        category: cat,
      );
    }

    return VoiceCommand(type: VoiceCommandType.search, query: query);
  }

  // ── Match resolution ────────────────────────────────────────────────────────

  VoiceCommand _resolveFromResults({
    required String query,
    required List<LocationModel> locs,
    required bool hasNavKeyword,
  }) {
    // Single exact match → navigate directly.
    final exactMatches =
    locs.where((loc) => _isExactMatch(loc, query)).toList();
    if (exactMatches.length == 1) {
      return VoiceCommand(
        type: VoiceCommandType.navigate,
        query: query,
        resolvedLocation: exactMatches.first,
        matchCount: 1,
      );
    }

    // Single-word or no nav keyword → present search results for user to pick.
    if (_wordCount(query) <= 1 || !hasNavKeyword) {
      return VoiceCommand(
        type: VoiceCommandType.search,
        query: query,
        matchCount: locs.length,
      );
    }

    // Multi-word + nav keyword → score and pick the best match.
    final (bestMatch, bestScore) = _bestScoredMatch(query, locs);
    if (bestMatch != null && bestScore >= _minSearchScore) {
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

  Future<LocationModel?> _fallbackLocationSearch(String query) async {
    final all = await _getAllLocations();
    if (all.isEmpty) return null;

    final (best, score) = _bestScoredMatch(query, all);
    if (best == null || score < _minFallbackScore) return null;

    // Reject ambiguous matches where a competitor scores equally well.
    final hasCompetitor = all.any(
          (loc) => loc.id != best.id && _scoreLocation(loc, query) >= _minFallbackScore,
    );
    return hasCompetitor ? null : best;
  }

  // ── Scoring ─────────────────────────────────────────────────────────────────

  /// Returns the best-scored location and its score from [locs].
  (LocationModel?, int) _bestScoredMatch(
      String query,
      List<LocationModel> locs,
      ) {
    LocationModel? best;
    var bestScore = -1;

    for (final loc in locs) {
      final score = _scoreLocation(loc, query);
      if (score > bestScore) {
        bestScore = score;
        best = loc;
      }
    }
    return (best, bestScore);
  }

  /// Scores a location against [query].
  ///
  /// Scoring is additive across search fields, but uses an early-exit for
  /// exact field matches to avoid unnecessary token iteration.
  int _scoreLocation(LocationModel loc, String query) {
    var score = 0;
    final tokens = _meaningfulTokens(query); // computed once per call

    for (final field in _locationSearchFields(loc)) {
      final normalized = _normalize(field);

      if (normalized == query) {
        score += 120;
        continue; // exact match; skip token scan for this field
      }
      if (normalized.startsWith(query)) {
        score += 80;
      } else if (normalized.contains(query)) {
        score += 40;
      }

      final fieldWords = normalized.split(' ');
      for (final token in tokens) {
        if (fieldWords.contains(token)) {
          score += 30;
        } else if (normalized.contains(token)) {
          score += 12;
        }
      }
    }
    return score;
  }

  // ── Text helpers ─────────────────────────────────────────────────────────────

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'[^\w\s]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Strips fillers, canonicalizes aliases. Always call this on a raw query.
  String _prepareQuery(String text) {
    final cleaned = _normalize(text)
        .split(' ')
        .where((w) => w.isNotEmpty && !_fillerWords.contains(w))
        .join(' ');
    return _queryAliases[cleaned] ?? cleaned;
  }

  bool _matchesAny(String t, List<String> keywords) =>
      keywords.any((k) => t.contains(_normalize(k)));

  bool _isExactMatch(LocationModel loc, String query) =>
      _locationSearchFields(loc).any((f) => _normalize(f) == query);

  int _wordCount(String text) =>
      _normalize(text).split(' ').where((p) => p.isNotEmpty).length;

  List<String> _meaningfulTokens(String query) => _normalize(query)
      .split(' ')
      .where((t) => t.length > 1 && !_queryStopWords.contains(t))
      .toList();

  List<String> _locationSearchFields(LocationModel loc) => <String>[
    loc.name,
    loc.description,
    loc.category,
    ...?loc.localizedNames?.values,
    ...?loc.localizedDescriptions?.values,
    ...?loc.tags,
  ];

  String? _extractCategory(String t) {
    for (final entry in _catMap.entries) {
      if (t.contains(_normalize(entry.key))) return entry.value;
    }
    return null;
  }

  // ── Response builder ─────────────────────────────────────────────────────────

  String buildResponse(VoiceCommand cmd, String lang) {
    final name =
        cmd.resolvedLocation?.getLocalizedName(lang) ?? cmd.query ?? '';
    final info = _locationInfoSnippet(cmd.resolvedLocation, lang);
    final infoPart = info.isNotEmpty ? '$info ' : '';

    switch (cmd.type) {
      case VoiceCommandType.navigate:
        return _localize(
          lang,
          en: 'Navigating to $name. ${infoPart}Follow the route on the map.',
          yo: 'Mo ń lọ sí $name. ${infoPart}Tẹle ipa-ọna lórí maapu.',
          ig: 'Ana m agagharị gaa $name. ${infoPart}Soro ụzọ ahụ n\'ime maapụ.',
          pid: 'I dey take you go $name. ${infoPart}Follow route for map.',
        );
      case VoiceCommandType.whereAmI:
        return _localize(
          lang,
          en: 'Showing your current location on the map.',
          yo: 'Mo ń fihàn ibi tí o wà lórí maapu.',
          ig: 'Ana m egosi ebe i nọ ugbu a n\'ime maapụ.',
          pid: 'I dey show your current location for map.',
        );
      case VoiceCommandType.listCategory:
        return _localize(
          lang,
          en: 'Showing all ${cmd.category} locations.',
          yo: 'Mo ń fihàn gbogbo àwọn ibi ${cmd.category}.',
          ig: 'Ana m egosi ụlọ ${cmd.category} nile.',
          pid: 'I dey show all ${cmd.category} places for map.',
        );
      case VoiceCommandType.search:
        final count = cmd.matchCount ?? 0;
        return _localize(
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
        return _localize(
          lang,
          en: 'Say: Go to Chapel, Where am I, Show all hostels, or Find cafeteria.',
          yo: 'Sọ: Lọ sí Chapel, Ibo ni mo wà, Fihàn gbogbo hostels.',
          ig: 'Kwuo: Gaa Chapel, Ebe nọ m, Gosi hostel nile.',
          pid: 'Talk: Take me go Chapel, Wia I dey, Show all hostels.',
        );
      case VoiceCommandType.unknown:
        return _localize(
          lang,
          en: 'Sorry, I did not understand. Try saying: Go to Library.',
          yo: 'Ẹ jọwọ, mi ò gbọ. Gbiyanju sọ: Lọ sí Library.',
          ig: 'Ndo, Anọghị m nụ. Nwaa ikwu: Gaa Library.',
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
    return compact.length > 90 ? '${compact.substring(0, 90)}...' : compact;
  }

  /// Selects the right language string; defaults to English for unknown codes.
  String _localize(
      String lang, {
        required String en,
        required String yo,
        required String ig,
        required String pid,
      }) {
    switch (lang) {
      case 'yo': return yo;
      case 'ig': return ig;
      case 'pidgin': return pid;
      default: return en;
    }
  }

  // ── Cache management ─────────────────────────────────────────────────────────

  /// Call this when the location data changes so the fallback cache is refreshed.
  void invalidateCache() => _allLocationsCache = null;
}