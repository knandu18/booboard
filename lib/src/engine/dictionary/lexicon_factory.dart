// SPDX-License-Identifier: GPL-3.0-or-later
//
// Loads dictionaries (`dict/<lang>.mdict`) through the [PackRepository] and
// keeps the recently used ones warm.
import 'dart:isolate';
import 'dart:typed_data';

import '../../core/log.dart';
import '../../packs/pack_repository.dart';
import '../contracts.dart';
import '../in_memory_lexicon.dart';
import 'mdict_lexicon.dart';

/// [maxLoaded] bounds memory: the least recently used lexicon beyond it is
/// evicted (a language is never evicted in the call that just loaded it).
LexiconSource createLexiconSource({required PackRepository packs, int maxLoaded = 4}) =>
    MdictLexiconSource(packs: packs, maxLoaded: maxLoaded);

class MdictLexiconSource implements LexiconSource {
  MdictLexiconSource({required this.packs, this.maxLoaded = 4});

  final PackRepository packs;
  final int maxLoaded;

  /// Insertion order = least recently used first.
  final Map<LanguageId, Lexicon> _loaded = {};
  final Map<LanguageId, Future<Lexicon>> _loading = {};

  @override
  bool isLoaded(LanguageId language) => _loaded.containsKey(language);

  @override
  Future<Lexicon> load(LanguageId language) {
    final cached = _loaded.remove(language);
    if (cached != null) {
      _loaded[language] = cached; // mark as most recently used
      return Future.value(cached);
    }
    return _loading[language] ??= _read(language).whenComplete(() {
      _loading.remove(language);
    });
  }

  Future<Lexicon> _read(LanguageId language) async {
    final stopwatch = Stopwatch()..start();
    Lexicon lexicon;
    final path = 'dict/$language.mdict';
    if (await packs.exists(path)) {
      final data = await packs.load(path);
      final bytes = Uint8List.fromList(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      Uint8List raw;
      try {
        // Inflate off the UI isolate so the first keyboard show does not hitch.
        raw = await Isolate.run(() => inflateMdict(bytes));
      } on Object {
        raw = inflateMdict(bytes);
      }
      lexicon = MdictLexicon.fromBytes(raw);
    } else if (language == 'en') {
      // Keeps the keyboard usable if the asset is missing from a build.
      BooBoardLog.w('dict', 'en.mdict missing, using the starter word list');
      lexicon = InMemoryLexicon('en', kStarterEnglishWords);
    } else {
      throw StateError('No dictionary for $language');
    }
    BooBoardLog.d('dict', 'loaded $language: ${lexicon.size} words in ${stopwatch.elapsedMilliseconds} ms');
    _loaded[language] = lexicon;
    while (_loaded.length > maxLoaded) {
      final oldest = _loaded.keys.firstWhere((l) => l != language);
      evict(oldest);
    }
    return lexicon;
  }

  @override
  void evict(LanguageId language) {
    _loaded.remove(language);
  }
}
