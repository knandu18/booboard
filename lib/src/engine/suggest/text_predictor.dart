// SPDX-License-Identifier: GPL-3.0-or-later
// ignore_for_file: prefer_initializing_formals
//
// Tap-typing engine: suggestions, autocorrect, next-word prediction and
// on-device learning.
//
// PRIVACY: learned data lives only in memory and in the SecureBlobStore
// (encrypted). Nothing typed is ever logged.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import '../../core/log.dart';
import '../../core/secure_blob_store.dart';
import '../contracts.dart';
import '../dictionary/english_contractions.dart';
import '../dictionary/mdict_format.dart';
import '../dictionary/mdict_lexicon.dart';
import '../dictionary/text_fold.dart';
import '../learn/learn_filter.dart';
import '../learn/learned_data.dart';
import 'spatial_model.dart';
import 'trie_search.dart';

/// Weight of the language model against the spatial cost.
const double kLanguageWeight = 0.6;

/// Log probability assumed for a typed word that no dictionary knows.
const double kUnknownLogProb = -21;

final double _kBackoff = math.log(0.4);

class _Active {
  _Active(this.id, this.source, this.lex) : searcher = TrieSearcher(lex);

  final LanguageId id;
  final Lexicon source;
  final MdictLexicon lex;
  final TrieSearcher searcher;
}

class _Entry {
  _Entry({
    required this.key,
    required this.text,
    required this.score,
    required this.kind,
    required this.language,
    required this.cost,
    required this.edits,
    required this.extraChars,
    required this.lm,
    this.learned = false,
  });

  final String key;
  final String text;
  double score;
  SuggestionKind kind;
  final LanguageId language;
  final double cost;
  final int edits;
  final int extraChars;
  final double lm;
  final bool learned;

  bool get isCompletion => kind == SuggestionKind.completion;
}

class BooBoardTextPredictor implements TextPredictor {
  BooBoardTextPredictor({
    required LexiconSource lexicons,
    required SecureBlobStore store,
    DateTime Function()? clock,
    Duration saveDelay = const Duration(seconds: 8),
    this.blockOffensive = true,
  }) : _lexicons = lexicons,
       _store = store,
       _clock = clock ?? DateTime.now,
       _saveDelay = saveDelay;

  final LexiconSource _lexicons;
  final SecureBlobStore _store;
  final DateTime Function() _clock;
  final Duration _saveDelay;

  /// Never suggest words flagged as possibly offensive unless typed in full.
  bool blockOffensive;

  List<_Active> _active = const [];
  final Map<LanguageId, LearnedData> _learned = {};
  final Set<String> _sessionNoCorrect = {};
  final Map<Lexicon, MdictLexicon> _packedCache = {};
  SpatialModel _spatial = SpatialModel.qwerty();
  Timer? _saveTimer;
  int _generation = 0;

  int _today() => dayNumber(_clock());

  // ---------------------------------------------------------------- setup

  @override
  Future<void> setActiveLanguages(List<LanguageId> languages) async {
    final wanted = <LanguageId>[];
    for (final l in languages) {
      if (!wanted.contains(l)) wanted.add(l);
      if (wanted.length == 3) break;
    }
    final generation = ++_generation;
    final next = <_Active>[];
    for (final language in wanted) {
      final Lexicon source;
      try {
        source = await _lexicons.load(language);
      } on Object catch (e) {
        // A language without a dictionary is skipped; the rest of the blend still works.
        BooBoardLog.w('predictor', 'no dictionary for a language, skipped', e.runtimeType);
        continue;
      }
      next.add(_activeFor(language, source));
      await _ensureLearned(language);
    }
    if (generation != _generation) return; // a newer call won
    if (next.isEmpty && !wanted.contains('en')) {
      // Nothing usable was asked for: fall back to English so suggestions keep working.
      final english = await _lexicons.load('en');
      if (generation != _generation) return;
      next.add(_activeFor('en', english));
      await _ensureLearned('en');
    }
    _active = next;
  }

  /// Reuses the live entry for [language] when its lexicon has not changed.
  _Active _activeFor(LanguageId language, Lexicon source) {
    final existing = _active.where((a) => a.id == language && identical(a.source, source));
    if (existing.isNotEmpty) return existing.first;
    final packed = source is MdictLexicon
        ? source
        : (_packedCache[source] ??= MdictLexicon.fromLexicon(
            source,
            corrections: language.startsWith('en') ? kEnglishContractions : const {},
          ));
    return _Active(language, source, packed);
  }

  /// Reads the learned data of [language] once. Learning must never start from an empty
  /// in-memory copy, or the next save would overwrite what the user taught the keyboard.
  Future<void> _ensureLearned(LanguageId language) async {
    if (_learned.containsKey(language)) return;
    _learned[language] = LearnedData.decode(language, await _store.read(_blobName(language)));
  }

  static String _blobName(LanguageId language) => 'learned_$language';

  @override
  void setGeometry(KeyboardGeometry geometry) {
    if (geometry.keys.isEmpty) return;
    if (_spatial.geometry.cacheKey == geometry.cacheKey) return;
    _spatial = SpatialModel.fromGeometry(geometry);
  }

  // -------------------------------------------------------------- suggest

  static const String _kProtectedChars = '@#/.:_\\+=&%\$';

  static bool _isProtected(String raw) {
    var prevLower = false;
    for (final r in raw.runes) {
      final ch = String.fromCharCode(r);
      if (r >= 0x30 && r <= 0x39) return true;
      if (_kProtectedChars.contains(ch)) return true;
      final isUpper = ch != ch.toLowerCase();
      if (isUpper && prevLower) return true; // camelCase
      prevLower = ch != ch.toUpperCase();
    }
    return false;
  }

  @override
  SuggestionResult suggest(TypingContext context) {
    final raw = context.composing;
    if (raw.isEmpty || _active.isEmpty || !context.field.allowsSuggestions) return SuggestionResult.empty;
    final runes = raw.runes.toList();
    if (_isProtected(raw) || runes.length > 32) {
      return SuggestionResult(
        suggestions: [Suggestion(raw, kind: SuggestionKind.typed, language: _active.first.id)],
      );
    }

    final today = _today();
    final primary = _active.first;
    final typedKey = foldKey(raw);
    final previous = context.previousWords.isEmpty ? null : context.previousWords.last;
    final previousKey = previous == null ? null : foldKey(previous);
    final pattern = casePatternOf(raw);

    final points = <Offset?>[];
    if (context.taps.length == runes.length) {
      for (final t in context.taps) {
        points.add(t.point?.offset);
      }
    }
    final positionCache = <String, List<PositionCandidates>>{};
    final typedArrays = <String, Int32List>{};
    List<PositionCandidates> positionsFor(String fold) {
      final key = fold;
      return positionCache[key] ??= _spatial.positions(
        typedArrays[key] ??= Int32List.fromList(fold.codeUnits),
        fold.length == runes.length ? points : const [],
      );
    }

    final entries = <String, _Entry>{};

    // Whether the typed word is known, and how likely.
    var typedKnown = false;
    var typedLm = kUnknownLogProb;
    var typedLanguage = primary.id;
    for (var li = 0; li < _active.length; li++) {
      final a = _active[li];
      final id = a.lex.idOf(raw);
      if (id < 0) continue;
      typedKnown = true;
      final lm = _lmOf(a, _prevIdOf(a, previous), previous, id) - (li > 0 ? 0.4 : 0);
      if (lm > typedLm || typedLm == kUnknownLogProb) {
        typedLm = lm;
        typedLanguage = a.id;
      }
    }
    // A word that any active dictionary has ("die" in German and English) is never auto-corrected.
    final inDictionary = typedKnown;
    if (!typedKnown && _isLearnedKnown(typedKey)) {
      typedKnown = true;
      typedLm = _learnedLm(typedKey, today);
    }
    final typedBoost = _learnedBoost(typedKey, previousKey, today);
    final ownCost = positionsFor(primary.lex.fold(raw)).fold<double>(0, (sum, p) => sum + p.ownCost);
    final typedScore = -ownCost + kLanguageWeight * typedLm + typedBoost;

    // Dictionary candidates from every active language.
    for (var li = 0; li < _active.length; li++) {
      final a = _active[li];
      final fold = a.lex.fold(raw);
      final found = a.searcher.search(typedArrays[fold] ??= Int32List.fromList(fold.codeUnits), positionsFor(fold));
      final prevId = _prevIdOf(a, previous);
      for (final cand in found.values) {
        final surface = a.lex.wordOf(cand.id);
        final key = foldKey(surface);
        // Same letters, other accents or case ("cafe" -> "café"): offered, never the typed text itself.
        if (key == typedKey && foldKey(surface, stripAccents: false) == foldKey(raw, stripAccents: false)) continue;
        if (_isBlocked(key)) continue;
        if (blockOffensive && a.lex.isOffensiveId(cand.id)) continue;
        final lm = _lmOf(a, prevId, previous, cand.id);
        final score = -cand.cost + kLanguageWeight * lm + _learnedBoost(key, previousKey, today) - (li > 0 ? 0.4 : 0);
        final old = entries[key];
        if (old != null && old.score >= score) continue;
        entries[key] = _Entry(
          key: key,
          text: applyCasePattern(raw, surface),
          score: score,
          kind: cand.isCompletion ? SuggestionKind.completion : SuggestionKind.correction,
          language: a.id,
          cost: cand.cost,
          edits: cand.edits,
          extraChars: cand.extraChars,
          lm: lm,
          learned: _learnedFor(a.id)?.isConfirmed(key) ?? false,
        );
      }
    }

    _addLearnedCandidates(entries, raw, typedKey, previousKey, pattern, today);

    // Always-applied corrections ("dont" -> "don't", "i" -> "I").
    String? forced;
    for (final a in _active) {
      final target = a.lex.corrections[typedKey];
      if (target != null) {
        forced = applyCasePattern(raw, target);
        if (forced == raw) forced = null;
        break;
      }
    }

    // ---- autocorrect decision
    Suggestion? auto;
    final allowAuto =
        context.field.allowsAutoCorrect && !_sessionNoCorrect.contains(typedKey) && !_isOnlyLearnedKnown(typedKey);
    if (allowAuto && forced != null) {
      auto = Suggestion(forced, kind: SuggestionKind.correction, score: typedScore + 10, language: primary.id);
    } else if (allowAuto && runes.length >= 2 && !inDictionary) {
      auto = _pickAutoCorrection(
        entries.values,
        typedKnown: typedKnown,
        typedScore: typedScore,
        typedLm: typedLm,
        typedLength: runes.length,
        skipBecauseProperNoun:
            (pattern == CasePattern.capitalized && !context.isStartOfSentence) || pattern == CasePattern.mixed,
        shouting: pattern == CasePattern.upper,
      );
    }

    // ---- assemble: [typed or correction first, ...best first]
    final sorted = entries.values.toList()..sort((a, b) => b.score.compareTo(a.score));
    final out = <Suggestion>[];
    // The typed word itself is never a candidate (filtered above), so only other candidates are de-duplicated.
    final seen = <String>{};
    final typedSuggestion = Suggestion(
      raw,
      kind: SuggestionKind.typed,
      score: typedScore,
      language: typedLanguage,
      isLearned: _isLearnedKnown(typedKey),
    );
    if (auto != null) {
      out.add(auto);
      seen.add(foldKey(auto.text));
    }
    out.add(typedSuggestion);
    final floor = sorted.isEmpty ? 0.0 : sorted.first.score - 14;
    for (final e in sorted) {
      if (out.length >= 8) break;
      if (e.score < floor || !seen.add(e.key)) continue;
      out.add(Suggestion(e.text, kind: e.kind, score: e.score, language: e.language, isLearned: e.learned));
    }
    if (forced != null && auto == null) {
      // Not applied automatically (user reverted it, or autocorrect is off) but still offered.
      if (seen.add(foldKey(forced))) {
        out.insert(
          1,
          Suggestion(forced, kind: SuggestionKind.correction, score: typedScore + 10, language: primary.id),
        );
      }
    }
    return SuggestionResult(suggestions: out, autoCorrection: auto);
  }

  Suggestion? _pickAutoCorrection(
    Iterable<_Entry> entries, {
    required bool typedKnown,
    required double typedScore,
    required double typedLm,
    required int typedLength,
    required bool skipBecauseProperNoun,
    required bool shouting,
  }) {
    if (skipBecauseProperNoun) return null;
    // Whole-word fixes (one edit, or two cheap ones for unknown words), plus a
    // single missing final letter for unknown words.
    final pool = <_Entry>[
      for (final e in entries)
        if (!e.isCompletion
            ? (e.edits <= 1 || (!typedKnown && e.edits == 2 && e.cost <= 4.6))
            : (!typedKnown && typedLength >= 4 && e.edits == 0 && e.extraChars == 1))
          e,
    ]..sort((a, b) => b.score.compareTo(a.score));
    if (pool.isEmpty) return null;
    final top = pool.first;
    final gap = pool.length > 1 ? top.score - pool[1].score : double.infinity;
    final margin = top.score - typedScore;
    final ok = typedKnown
        ? top.lm - typedLm >= 6.0 && top.cost <= 2.4 && margin >= 3.6 && gap >= 0.6 && !top.isCompletion
        : margin >= (top.isCompletion ? 3.0 : 2.0) + (shouting ? 1.5 : 0) && gap >= 0.3;
    if (!ok) return null;
    return Suggestion(top.text, kind: SuggestionKind.correction, score: top.score, language: top.language);
  }

  /// Language-model log probability of word [id] after [previous].
  double _lmOf(_Active a, int previousId, String? previous, int id) {
    final unigram = dequantize(a.lex.qOfId(id));
    if (previous == null) return unigram;
    if (a.lex.hasDelegate) return a.lex.bigramLogProb(previous, a.lex.wordOf(id));
    if (previousId < 0) return unigram;
    return a.lex.bigramBetween(previousId, id) ?? unigram + _kBackoff;
  }

  int _prevIdOf(_Active a, String? previous) => previous == null || a.lex.hasDelegate ? -1 : a.lex.idOf(previous);

  // ------------------------------------------------------------- learning

  LearnedData? _learnedFor(LanguageId language) => _learned[language];

  bool _isBlocked(String key) {
    for (final a in _active) {
      if (_learned[a.id]?.blocked.contains(key) ?? false) return true;
    }
    return false;
  }

  bool _isLearnedKnown(String key) {
    for (final a in _active) {
      if (_learned[a.id]?.isConfirmed(key) ?? false) return true;
    }
    return false;
  }

  /// Known only because the user taught it (no dictionary has it).
  bool _isOnlyLearnedKnown(String key) => _isLearnedKnown(key) && _active.every((a) => a.lex.idOf(key) < 0);

  double _learnedLm(String key, int today) {
    var best = -9.0;
    for (final a in _active) {
      final w = _learned[a.id]?.words[key];
      if (w == null || w.commits < kCommitsToKnow) continue;
      best = math.max(best, -9.0 + 0.8 * math.log(math.max(1.0, w.scoreAt(today))));
    }
    return math.min(best, -2.0);
  }

  /// Extra score for words (and pairs) the user has used.
  double _learnedBoost(String key, String? previousKey, int today) {
    var boost = 0.0;
    for (final a in _active) {
      final d = _learned[a.id];
      if (d == null) continue;
      final w = d.words[key];
      if (w != null && w.commits >= 2) boost = math.max(boost, math.min(2.4, 0.7 * math.log(1 + w.scoreAt(today))));
      if (previousKey != null) {
        final b = d.bigramScore(previousKey, key, today);
        if (b > 0) boost += math.min(2.4, 1.0 * math.log(1 + b));
      }
    }
    return boost;
  }

  void _addLearnedCandidates(
    Map<String, _Entry> entries,
    String raw,
    String typedKey,
    String? previousKey,
    CasePattern pattern,
    int today,
  ) {
    for (final a in _active) {
      final d = _learned[a.id];
      if (d == null) continue;
      for (final e in d.words.entries) {
        final w = e.value;
        if (!w.novel || w.commits < kCommitsToKnow) continue;
        final key = e.key;
        if (key == typedKey || d.blocked.contains(key)) continue;
        double cost;
        var edits = 0;
        var extra = 0;
        var completion = false;
        if (key.length > typedKey.length && key.startsWith(typedKey)) {
          extra = key.length - typedKey.length;
          cost = extra * 0.2;
          completion = true;
        } else if ((key.length - typedKey.length).abs() <= 1 && _withinOneEdit(key, typedKey)) {
          cost = 3.2;
          edits = 1;
        } else {
          continue;
        }
        final lm = -9.0 + 0.8 * math.log(math.max(1.0, w.scoreAt(today)));
        final score = -cost + kLanguageWeight * math.min(lm, -2.0) + _learnedBoost(key, previousKey, today);
        final old = entries[key];
        if (old != null && old.score >= score) continue;
        entries[key] = _Entry(
          key: key,
          text: applyCasePattern(raw, w.surface),
          score: score,
          kind: completion ? SuggestionKind.completion : SuggestionKind.correction,
          language: a.id,
          cost: cost,
          edits: edits,
          extraChars: extra,
          lm: lm,
          learned: true,
        );
      }
    }
  }

  static bool _withinOneEdit(String a, String b) {
    if (a == b) return true;
    final la = a.length;
    final lb = b.length;
    if ((la - lb).abs() > 1) return false;
    var i = 0;
    while (i < la && i < lb && a.codeUnitAt(i) == b.codeUnitAt(i)) {
      i++;
    }
    if (i == la || i == lb) return true; // one insertion at the end
    if (la == lb) {
      if (a.substring(i + 1) == b.substring(i + 1)) return true; // substitution
      return i + 1 < la &&
          a.codeUnitAt(i) == b.codeUnitAt(i + 1) &&
          a.codeUnitAt(i + 1) == b.codeUnitAt(i) &&
          a.substring(i + 2) == b.substring(i + 2); // transposition
    }
    return la > lb ? a.substring(i + 1) == b.substring(i) : b.substring(i + 1) == a.substring(i);
  }

  @override
  void onWordCommitted(String word, {required List<String> previousWords, required bool allowLearning}) {
    if (!allowLearning || _active.isEmpty) return;
    final text = word.trim();
    if (text.isEmpty) return;
    final key = foldKey(text);
    if (_isBlocked(key)) return;
    _Active? home;
    for (final a in _active) {
      if (a.lex.idOf(text) >= 0) {
        home = a;
        break;
      }
    }
    final known = home != null;
    if (!known && !isLearnableWord(text)) return;
    if (text.runes.length < 2 && !known) return;
    final language = (home ?? _active.first).id;
    final data = _learned.putIfAbsent(language, () => LearnedData(language));
    final today = _today();
    data.commitWord(key, text, today, novel: !known);
    if (previousWords.isNotEmpty) {
      final prev = previousWords.last.trim();
      final prevKey = foldKey(prev);
      final prevKnown = _active.any((a) => a.lex.idOf(prev) >= 0);
      if (prev.isNotEmpty && (prevKnown || isLearnableWord(prev)) && !_isBlocked(prevKey)) {
        data.commitBigram(prevKey, key, today);
      }
    }
    _scheduleSave();
  }

  @override
  void onAutoCorrectionReverted({required String original, required String correction}) {
    if (original.isEmpty) return;
    _sessionNoCorrect.add(foldKey(original));
  }

  @override
  void blockWord(String word) {
    final key = foldKey(word.trim());
    if (key.isEmpty || _active.isEmpty) return;
    var home = _active.first.id;
    for (final a in _active) {
      if (a.lex.idOf(word) >= 0) {
        home = a.id;
        break;
      }
    }
    final data = _learned.putIfAbsent(home, () => LearnedData(home));
    data.blocked.add(key);
    for (final d in _learned.values) {
      d.removeWord(key);
    }
    data.dirty = true;
    _scheduleSave();
  }

  @override
  void forgetWord(String word) {
    final key = foldKey(word.trim());
    if (key.isEmpty) return;
    for (final d in _learned.values) {
      d.removeWord(key);
      if (d.blocked.remove(key)) d.dirty = true;
    }
    _sessionNoCorrect.remove(key);
    _scheduleSave();
  }

  @override
  Iterable<LexiconEntry> learnedWords(LanguageId language) {
    final d = _learned[language];
    if (d == null) return const [];
    final today = _today();
    return [
      for (final w in d.words.values)
        if (w.novel && w.commits >= kCommitsToKnow)
          LexiconEntry(w.surface, math.min(-2.0, -9.0 + 0.8 * math.log(math.max(1.0, w.scoreAt(today))))),
    ];
  }

  // ----------------------------------------------------------- prediction

  @override
  List<Suggestion> predictNext(List<String> previousWords, {int max = 3}) {
    if (_active.isEmpty || max <= 0) return const [];
    final today = _today();
    final previous = previousWords.isEmpty ? null : previousWords.last;
    final previousKey = previous == null ? null : foldKey(previous);
    final scored = <String, _Entry>{};

    void offer(String key, String text, double score, LanguageId language, {bool learned = false}) {
      if (_isBlocked(key)) return;
      final old = scored[key];
      if (old != null && old.score >= score) return;
      scored[key] = _Entry(
        key: key,
        text: text,
        score: score,
        kind: SuggestionKind.prediction,
        language: language,
        cost: 0,
        edits: 0,
        extraChars: 0,
        lm: score,
        learned: learned,
      );
    }

    for (var li = 0; li < _active.length; li++) {
      final a = _active[li];
      final bonus = li > 0 ? -0.4 : 0.0;
      if (previous != null && !a.lex.hasDelegate) {
        final id = a.lex.idOf(previous);
        for (final s in a.lex.successors(id)) {
          if (blockOffensive && a.lex.isOffensiveId(s.$1)) continue;
          final text = a.lex.wordOf(s.$1);
          offer(foldKey(text), text, s.$2 + bonus, a.id);
        }
      } else if (previous != null) {
        // Generic lexicon: probe the most frequent words.
        final floor = _kBackoff;
        for (final e in a.source.entries(limit: 3000)) {
          if (blockOffensive && e.isOffensive) continue;
          final p = a.source.bigramLogProb(previous, e.word);
          if (p > e.logProb + floor + 0.01) offer(foldKey(e.word), e.word, p + bonus, a.id);
        }
      } else {
        for (final starter in _starters(a)) {
          offer(foldKey(starter.$1), starter.$1, starter.$2 + bonus, a.id);
        }
      }
      final d = _learned[a.id];
      if (d == null) continue;
      if (previousKey != null) {
        final inner = d.bigrams[previousKey];
        if (inner != null) {
          for (final e in inner.entries) {
            final eff = e.value.scoreAt(today);
            final p = math.min(0.9, 0.15 * (1 + eff));
            final surface = d.words[e.key]?.surface ?? _surfaceFor(e.key) ?? e.key;
            final existing = scored[e.key];
            final base = math.log(p);
            offer(
              e.key,
              existing?.text ?? surface,
              existing == null ? base : math.max(existing.score, base) + 0.5,
              a.id,
              learned: true,
            );
          }
        }
      } else {
        // Nothing to condition on: lean on what the user writes most.
        final top = d.words.entries.where((e) => e.value.commits >= kCommitsToKnow).toList()
          ..sort((x, y) => y.value.scoreAt(today).compareTo(x.value.scoreAt(today)));
        for (final e in top.take(max)) {
          offer(e.key, e.value.surface, -3.0 + 0.3 * math.log(1 + e.value.scoreAt(today)), a.id, learned: true);
        }
      }
    }
    final sorted = scored.values.toList()..sort((a, b) => b.score.compareTo(a.score));
    return [
      for (final e in sorted.take(max))
        Suggestion(e.text, kind: SuggestionKind.prediction, score: e.score, language: e.language, isLearned: e.learned),
    ];
  }

  String? _surfaceFor(String key) {
    for (final a in _active) {
      final id = a.lex.idOf(key);
      if (id >= 0) return a.lex.wordOf(id);
    }
    return null;
  }

  List<(String, double)> _starters(_Active a) {
    final out = <(String, double)>[];
    if (a.id.startsWith('en')) {
      const english = ['I', 'The', 'Thanks', 'Hi', 'Hey', 'Yes', 'What', 'How'];
      var rank = 0;
      for (final w in english) {
        if (a.lex.idOf(w) >= 0 && !(blockOffensive && a.lex.isOffensiveId(a.lex.idOf(w)))) {
          out.add((w, -1.5 - 0.1 * rank++));
        }
      }
    } else {
      var rank = 0;
      for (final e in a.source.entries(limit: 12)) {
        if (e.word.runes.length < 2) continue;
        out.add((e.word, -2.0 - 0.1 * rank++));
        if (rank >= 6) break;
      }
    }
    return out;
  }

  @override
  bool isKnownWord(String word) {
    if (word.isEmpty) return false;
    for (final a in _active) {
      if (a.lex.idOf(word) >= 0) return true;
    }
    return _isLearnedKnown(foldKey(word));
  }

  // ------------------------------------------------------------ persistence

  void _scheduleSave() {
    if (_saveTimer?.isActive ?? false) return;
    _saveTimer = Timer(_saveDelay, () {
      unawaited(flush());
    });
  }

  @override
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    for (final entry in _learned.entries.toList()) {
      final data = entry.value;
      if (!data.dirty) continue;
      data.dirty = false;
      try {
        if (data.isEmpty) {
          await _store.delete(_blobName(entry.key));
        } else {
          await _store.write(_blobName(entry.key), data.encode());
        }
      } on Object catch (e) {
        data.dirty = true;
        BooBoardLog.w('learn', 'could not save learned data', e.runtimeType);
      }
    }
  }

  /// The settings app edited or wiped the learned blobs: drop unsaved in-memory changes and read
  /// them again for the active languages.
  @override
  Future<void> reloadLearnedData() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    _learned.clear();
    _sessionNoCorrect.clear();
    for (final a in _active.toList()) {
      try {
        _learned[a.id] = LearnedData.decode(a.id, await _store.read(_blobName(a.id)));
      } on Object catch (e) {
        _learned[a.id] = LearnedData(a.id);
        BooBoardLog.w('learn', 'could not reload learned data', e.runtimeType);
      }
    }
  }

  @override
  Future<void> clearLearnedData() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final languages = {..._learned.keys, for (final a in _active) a.id};
    for (final d in _learned.values) {
      d.clear();
      d.dirty = false;
    }
    _sessionNoCorrect.clear();
    for (final language in languages) {
      try {
        await _store.delete(_blobName(language));
      } on Object catch (e) {
        BooBoardLog.w('learn', 'could not delete learned data', e.runtimeType);
      }
    }
  }

  @override
  void trimMemory() {
    for (final a in _active) {
      a.lex.trimMemory();
    }
    for (final p in _packedCache.values) {
      p.trimMemory();
    }
  }
}
