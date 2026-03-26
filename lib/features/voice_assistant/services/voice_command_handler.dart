// lib/features/voice_assistant/services/voice_command_handler.dart

import '../../../data/models/location_model.dart';
import '../../../data/repositories/location_repository.dart';

enum VoiceCommandType { navigate, whereAmI, listCategory, search, help, unknown }

class VoiceCommand {
  final VoiceCommandType type;
  final String? query;
  final String? category;
  final LocationModel? resolvedLocation;
  const VoiceCommand({required this.type, this.query, this.category, this.resolvedLocation});
}

class VoiceCommandHandler {
  final LocationRepository _repo;
  VoiceCommandHandler(this._repo);

  static const _navKeywords = {
    'en':     ['go to','take me to','navigate to','show me','where is','find','directions to','how do i get to'],
    'yo':     ['mu mi lo','fi han mi','wa','lo si'],
    'ig':     ['were m gaa','chota','gaa','gosi m'],
    'pidgin': ['take me go','wia dey','how i go reach','find','carry me go'],
  };
  static const _whereAmIKeywords = {
    'en':     ['where am i','my location','current location','locate me'],
    'yo':     ['ibo ni mo wa','ibi mi','wa ni ibo'],
    'ig':     ['ebe no m','ebe m no','ebe nolu m'],
    'pidgin': ['wia i dey','my location','wia i dey now'],
  };
  static const _helpKeywords = {
    'en':     ['help','what can you do','commands','how to use'],
    'yo':     ['iranlowo','bawo','se o le'],
    'ig':     ['enyemaka','otu esi'],
    'pidgin': ['help me','wetin you fit do','how you take use'],
  };
  static const _categoryKeywords = {
    'en':     ['show all','list all','all the','nearby'],
    'yo':     ['gbogbo','fihan gbogbo'],
    'ig':     ['gosi ihe nile','ihe nile'],
    'pidgin': ['show all','all di','show me all'],
  };
  static const _catMap = {
    'hostel':'hostel','hall':'hostel','dormitory':'hostel','accommodation':'hostel',
    'class':'academic','lecture':'academic','building':'academic','faculty':'academic',
    'department':'academic','lab':'academic','library':'academic','cst':'academic',
    'food':'food','eat':'food','cafeteria':'food','restaurant':'food','canteen':'food',
    'chapel':'worship','church':'worship','worship':'worship','pray':'worship',
    'sport':'sports','gym':'sports','field':'sports','stadium':'sports',
    'hospital':'medical','clinic':'medical','medical':'medical','health':'medical',
    'admin':'admin','office':'admin','senate':'admin','gate':'admin',
    'park':'recreation','square':'recreation','relax':'recreation','eagle':'recreation',
  };

  Future<VoiceCommand> process(String text, String lang) async {
    final t = text.toLowerCase().trim();

    if (_matches(t, _whereAmIKeywords[lang] ?? _whereAmIKeywords['en']!))
      return const VoiceCommand(type: VoiceCommandType.whereAmI);

    if (_matches(t, _helpKeywords[lang] ?? _helpKeywords['en']!))
      return const VoiceCommand(type: VoiceCommandType.help);

    if (_matches(t, _categoryKeywords[lang] ?? _categoryKeywords['en']!)) {
      final cat = _extractCat(t);
      if (cat != null) return VoiceCommand(type: VoiceCommandType.listCategory, category: cat);
    }

    final navKeys = _navKeywords[lang] ?? _navKeywords['en']!;
    String query = t;
    for (final kw in navKeys) {
      if (t.contains(kw)) { query = t.replaceFirst(kw, '').trim(); break; }
    }

    if (query.isNotEmpty) {
      final (locs, _) = await _repo.searchLocations(query);
      if (locs != null && locs.isNotEmpty) {
        return VoiceCommand(
            type: VoiceCommandType.navigate, query: query, resolvedLocation: locs.first);
      }
      final cat = _extractCat(query);
      if (cat != null) return VoiceCommand(type: VoiceCommandType.listCategory, query: query, category: cat);
      return VoiceCommand(type: VoiceCommandType.search, query: query);
    }

    return const VoiceCommand(type: VoiceCommandType.unknown);
  }

  bool _matches(String t, List<String> kws) => kws.any((k) => t.contains(k));
  String? _extractCat(String t) {
    for (final e in _catMap.entries) { if (t.contains(e.key)) return e.value; }
    return null;
  }

  // ── Spoken responses in all 4 languages ──────────────────
  String buildResponse(VoiceCommand cmd, String lang) {
    final name = cmd.resolvedLocation?.getLocalizedName(lang) ?? cmd.query ?? '';
    switch (cmd.type) {
      case VoiceCommandType.navigate:
        return _r(lang,
            en: 'Navigating to $name. Follow the blue route on the map.',
            yo: 'Mo ń lọ sí $name. Tẹle ipa-ọna bulu lórí maapu.',
            ig: 'Ana m agagharị gaa $name. Soro ụzọ ọcha n\'ime maapụ.',
            pid: 'I dey take you go $name. Follow di blue line for map.');
      case VoiceCommandType.whereAmI:
        return _r(lang,
            en: 'Showing your current location on the map.',
            yo: 'Mo ń fihàn ibi tí o wà lórí maapu.',
            ig: 'Ana m egosi ebe i nọ ugbu a n\'ime maapụ.',
            pid: 'I dey show your current location for map.');
      case VoiceCommandType.listCategory:
        return _r(lang,
            en: 'Showing all ${cmd.category} locations.',
            yo: 'Mo ń fihàn gbogbo àwọn ibi ${cmd.category}.',
            ig: 'Ana m egosi ụlọ ${cmd.category} nile.',
            pid: 'I dey show all ${cmd.category} places for map.');
      case VoiceCommandType.search:
        return _r(lang,
            en: 'Searching for ${cmd.query}.',
            yo: 'Mo ń wá ${cmd.query}.',
            ig: 'Ana m achọ ${cmd.query}.',
            pid: 'I dey search for ${cmd.query}.');
      case VoiceCommandType.help:
        return _r(lang,
            en: 'Say: Go to Chapel, Where am I, Show all hostels, or Find cafeteria.',
            yo: 'Sọ: Lọ sí Chapel, Ibo ni mo wà, Fihàn gbogbo hostels.',
            ig: 'Kwuo: Gaa Chapel, Ebe nọ m, Gosi hostel nile.',
            pid: 'Talk: Take me go Chapel, Wia I dey, Show all hostels.');
      default:
        return _r(lang,
            en: 'Sorry, I did not understand. Try saying Go to Library.',
            yo: 'Ẹ jọwọ, mi ò gbọ. Gbiyanju sọ Lọ sí Library.',
            ig: 'Ndo, Anọghị m nụ. Nwaa ikwu Gaa Library.',
            pid: 'Sorry, I no hear well. Try talk: Take me go Library.');
    }
  }

  String _r(String lang,{required String en,required String yo,required String ig,required String pid}){
    switch(lang){ case 'yo': return yo; case 'ig': return ig; case 'pidgin': return pid; default: return en; }
  }
}