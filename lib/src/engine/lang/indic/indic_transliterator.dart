// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-B. English-letter typing for one Indic language: the table gives the common words
// ("namaste" -> नमस्ते), the scheme converts anything else, so every typed word has a candidate.
import 'dart:isolate';
import 'dart:typed_data';

import '../../../packs/pack_repository.dart';
import '../../contracts.dart';
import 'scheme.dart';
import 'translit_table.dart';

class IndicTransliterator implements Transliterator {
  IndicTransliterator({required this.language, required this.packs});

  @override
  final LanguageId language;

  final PackRepository packs;
  TranslitTable? _table;

  /// The rule-based scheme for [language]; null for a language without one.
  IndicScheme? get scheme => schemeFor(language);

  bool get isLoaded => _table != null;

  /// Entries in the table, or 0 before [load].
  int get tableSize => _table?.length ?? 0;

  /// The table, for the swipe mapping. Null before [load].
  TranslitTable? get table => _table;

  @override
  Future<void> load() async {
    if (_table != null) return;
    final data = await packs.load('translit/$language.bin');
    final bytes = Uint8List.fromList(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    // Inflate and index off the UI isolate.
    _table = await Isolate.run(() => TranslitTable.fromGzip(bytes));
  }

  void unload() => _table = null;

  @override
  List<Suggestion> transliterate(String latin, {List<String> previousWords = const [], int max = 5}) {
    final key = latin.trim().toLowerCase();
    if (key.isEmpty || max <= 0) return const [];
    final table = _table;
    final out = <Suggestion>[];
    final seen = <String>{};

    void add(String native, double score) {
      if (native.isEmpty || out.length >= max || !seen.add(native)) return;
      out.add(Suggestion(native, kind: SuggestionKind.transliteration, score: score, language: language));
    }

    if (table != null) {
      final exact = table.exact(key, max: 3);
      for (var i = 0; i < exact.length; i++) {
        add(exact[i].native, 1.0 - i * 0.05 + exact[i].score / 255);
      }
    }
    // The rule-based conversion always exists, so any typed word converts.
    final converted = scheme?.convert(key);
    if (converted != null && converted != key) add(converted, 0.5);
    if (table != null) {
      for (final e in table.prefix(key, max: max)) {
        add(e.native, 0.2 + e.score / 255 * 0.2);
      }
    }
    return out;
  }
}
