// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A. The pinyin TextComposer (composer.dart's contract). Letters build a buffer; the
// candidates are the words and characters the buffer can spell, whole buffer first, then prefixes.
//
// Candidate order: whole-buffer phrases (best segmentation and whole-key entries, learned picks
// boosted), then abbreviations (initials, "nh" for 你好), then prefixes (a candidate converts the
// letters it names and leaves the rest composing), then the letters as typed.
//
// Keys: letters a-z; an apostrophe forces a syllable break. Space commits the first candidate, enter
// commits the letters, backspace removes a letter. Punctuation commits the best candidate first when
// the buffer holds text. Settings are read on each call, so a change takes effect on the next key.
//
// PRIVACY: never logs the buffer, the candidates or the picks.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../keyboard/input/composer.dart';
import 's2twp.dart';
import 'learned_phrases.dart';
import 'pinyin_segmenter.dart';
import 'zh_dictionary.dart';
import 'zh_lexicon.dart';

/// Settings the composer reads on each call.
class PinyinOptions {
  const PinyinOptions({this.fuzzy = true, this.traditional = false});

  final bool fuzzy;
  final bool traditional;
}

/// Candidates are capped: the grid shows a page at a time, and nobody scrolls past this.
const int maxCandidates = 60;

class _Cand {
  const _Cand(this.simplified, this.text, this.consumed, this.score, this.syllables);

  /// Simplified text: what learning stores.
  final String simplified;

  /// What is committed (Traditional when the option is on).
  final String text;

  /// Raw buffer characters this candidate converts.
  final int consumed;
  final double score;

  /// Segmented pinyin for the grid (empty for the letters as typed).
  final String syllables;
}

class _Result {
  const _Result(this.candidates, this.reading);

  static const _Result empty = _Result([], '');

  final List<_Cand> candidates;
  final String reading;
}

class _Pick {
  const _Pick(this.text, this.letters);

  final String text;
  final String letters;
}

const Map<String, String> _fullWidth = {',': '，', '.': '。', '?': '？', '!': '！', ':': '：', ';': '；', '(': '（', ')': '）'};

class PinyinComposer extends TextComposer {
  PinyinComposer({
    required this.lexicon,
    required this.options,
    required this.learned,
    required this.learningAllowed,
    this.onLearned,
  });

  /// The dictionary pack. Until it loads, letters are kept and nothing is offered.
  final ZhLexicon lexicon;

  /// Current settings (fuzzy pinyin, Traditional output).
  final PinyinOptions Function() options;

  /// The learned picks (in memory; the feature saves them).
  final LearnedPhrases learned;

  /// False in password fields, incognito and when learning is off; nothing is learned then.
  final bool Function() learningAllowed;

  /// Called after a pick changed the learned phrases.
  final void Function()? onLearned;

  String _raw = '';
  final List<_Pick> _run = [];
  bool _quoteOpen = false;
  int _learnVersion = 0;

  // Cache of the last computation (see _result).
  _Result? _cache;
  String _cacheRaw = '';
  int _cacheLearn = -1;
  PinyinOptions? _cacheOptions;
  Object? _cacheDictionary;

  String get _letters => _raw.replaceAll("'", '');

  @override
  Listenable get changes => lexicon;

  @override
  ComposerState get state {
    if (_raw.isEmpty) return ComposerState.empty;
    final r = _result();
    if (r == null) return ComposerState(preedit: _raw, loading: true);
    return ComposerState(
      preedit: _raw,
      reading: r.reading,
      candidates: [
        for (final c in r.candidates)
          ComposerCandidate(c.text, annotation: c.syllables.isEmpty ? null : c.syllables, consumes: c.consumed),
      ],
      highlighted: r.candidates.isEmpty ? -1 : 0,
    );
  }

  /// The computed candidates for the current buffer; null while the dictionary is not loaded.
  _Result? _result() {
    if (_raw.isEmpty) return _Result.empty;
    final dict = lexicon.dictionary;
    if (dict == null) return null;
    final opts = options();
    final cached = _cache;
    if (cached != null &&
        _cacheRaw == _raw &&
        _cacheLearn == _learnVersion &&
        _cacheOptions?.fuzzy == opts.fuzzy &&
        _cacheOptions?.traditional == opts.traditional &&
        identical(_cacheDictionary, dict)) {
      return cached;
    }
    final r = _compute(dict, lexicon.converter, opts);
    _cache = r;
    _cacheRaw = _raw;
    _cacheLearn = _learnVersion;
    _cacheOptions = opts;
    _cacheDictionary = dict;
    return r;
  }

  void _invalidate() {
    _cache = null;
  }

  _Result _compute(ZhDictionary dict, S2twpConverter? converter, PinyinOptions opts) {
    final letters = _letters;
    if (letters.isEmpty) return _Result.empty;
    final seg = PinyinSegmenter(dict, fuzzy: opts.fuzzy);
    String show(String simplified) =>
        opts.traditional && converter != null ? converter.convert(simplified) : simplified;

    // Raw index just after the k-th letter, for "consumes".
    final rawEnd = <int>[];
    for (var i = 0; i < _raw.length; i++) {
      if (_raw[i] != "'") rawEnd.add(i + 1);
    }
    // Letter counts at which the user forced a break.
    final cuts = <int>[];
    var seen = 0;
    for (var i = 0; i < _raw.length; i++) {
      if (_raw[i] == "'") {
        if (seen > 0 && (cuts.isEmpty || cuts.last != seen)) cuts.add(seen);
      } else {
        seen++;
      }
    }

    final full = <_Cand>[];
    final abbrev = <_Cand>[];
    final prefixes = <_Cand>[];
    String reading;
    final rawLen = _raw.length;

    if (cuts.isEmpty) {
      final learnedHere = learned.wordsFor(letters);
      final whole = seg.wholeMatches(letters);
      for (final u in whole) {
        full.add(
          _Cand(u.entry.text, show(u.entry.text), rawLen, u.score + _boost(letters, u.entry.text), u.entry.syllables),
        );
      }
      final best = seg.segment(letters);
      reading = best.reading;
      if (!best.hasUnknown && best.units.length > 1) {
        final t = best.text;
        full.add(_Cand(t, show(t), rawLen, best.score + _boost(letters, t), best.reading));
      }
      for (final (text, _) in learnedHere) {
        if (full.any((c) => c.simplified == text)) continue;
        full.add(_Cand(text, show(text), rawLen, -3.0 + _boost(letters, text), ''));
      }
      if (letters.length >= 2) {
        for (final e in seg.abbreviations(letters)) {
          abbrev.add(_Cand(e.text, show(e.text), rawLen, e.logP - 1.5, e.syllables));
        }
      }
    } else {
      var text = '';
      var score = 0.0;
      var unknown = false;
      final parts = <String>[];
      var from = 0;
      for (final to in [...cuts, letters.length]) {
        final s = seg.segment(letters.substring(from, to));
        text += s.text;
        score += s.score;
        parts.add(s.reading);
        if (s.hasUnknown) unknown = true;
        from = to;
      }
      reading = parts.join("'");
      if (!unknown) full.add(_Cand(text, show(text), rawLen, score, reading));
    }
    full.sort((a, b) => b.score.compareTo(a.score));

    // Prefixes: each converts the letters before it. With a break, only the first segment and its
    // prefixes are offered, so a pick never swallows the forced break.
    final limit = cuts.isEmpty ? letters.length - 1 : cuts.first;
    for (var k = limit; k >= 1 && prefixes.length < maxCandidates; k--) {
      final prefix = letters.substring(0, k);
      final consumed = rawEnd[k - 1];
      final s = seg.segment(prefix);
      if (!s.hasUnknown && s.units.length > 1) {
        prefixes.add(_Cand(s.text, show(s.text), consumed, s.score, s.reading));
      }
      for (final u in seg.wholeMatches(prefix).take(3)) {
        prefixes.add(_Cand(u.entry.text, show(u.entry.text), consumed, u.score, u.entry.syllables));
      }
    }

    // The letters as typed always come last, so any buffer can be committed as it is.
    final typed = _Cand(letters, letters, rawLen, -30, '');
    final out = <_Cand>[];
    final keys = <String>{};
    for (final c in [...full, ...abbrev, ...prefixes, typed]) {
      if (out.length >= maxCandidates) break;
      if (keys.add('${c.text}\u0000${c.consumed}')) out.add(c);
    }
    return _Result(out, reading);
  }

  /// Ranking boost for a text the user picked before for these letters (up to +2 log10).
  double _boost(String letters, String text) {
    final n = learned.countFor(letters, text);
    if (n == 0) return 0;
    final b = 0.6 * math.log(1 + n) / math.ln10;
    return b > 2.0 ? 2.0 : b;
  }

  @override
  ComposerStep onText(String text) {
    if (text.isEmpty) return ComposerStep.notHandled;
    if (text.length == 1 && _isAsciiLetter(text.codeUnitAt(0))) {
      _raw += text.toLowerCase();
      _invalidate();
      return ComposerStep.consumed;
    }
    if (text == "'" || text == '’') {
      if (_letters.isEmpty) return ComposerStep.notHandled;
      if (_raw.endsWith("'")) return ComposerStep.consumed;
      _raw += "'";
      _invalidate();
      return ComposerStep.consumed;
    }
    final mark = _mark(text);
    if (_raw.isEmpty) {
      if (mark == null) return ComposerStep.notHandled;
      return ComposerStep(commit: mark);
    }
    final head = _commitBest();
    return ComposerStep(commit: '$head${mark ?? text}');
  }

  /// The full-width form of a punctuation key, alternating the double quotes; null for other text.
  String? _mark(String text) {
    if (text == '"') {
      final m = _quoteOpen ? '”' : '“';
      _quoteOpen = !_quoteOpen;
      return m;
    }
    return _fullWidth[text];
  }

  /// Commits the best whole-buffer candidate (or the letters) and clears the buffer.
  String _commitBest() {
    final r = _result();
    final letters = _letters;
    String out = letters;
    if (r != null) {
      for (final c in r.candidates) {
        if (c.consumed == _raw.length && c.text != letters) {
          out = c.text;
          _recordPick(c.simplified, letters);
          break;
        }
      }
    }
    _reset();
    return out;
  }

  @override
  ComposerStep onSpace() {
    if (_raw.isEmpty) return ComposerStep.notHandled;
    final r = _result();
    if (r == null || r.candidates.isEmpty) {
      final t = _letters;
      _reset();
      return ComposerStep(commit: '$t ');
    }
    return selectCandidate(0);
  }

  @override
  ComposerStep onEnter() {
    if (_raw.isEmpty) return ComposerStep.notHandled;
    final t = _letters;
    _reset();
    return ComposerStep(commit: t);
  }

  @override
  ComposerStep onBackspace() {
    if (_raw.isEmpty) return ComposerStep.notHandled;
    _raw = _raw.substring(0, _raw.length - 1);
    _invalidate();
    return ComposerStep.consumed;
  }

  @override
  ComposerStep selectCandidate(int index) {
    final r = _result();
    if (r == null || index < 0 || index >= r.candidates.length) return ComposerStep.notHandled;
    final c = r.candidates[index];
    final letters = _raw.substring(0, c.consumed).replaceAll("'", '');
    if (c.simplified != letters) _recordPick(c.simplified, letters);
    _raw = _raw.substring(c.consumed);
    while (_raw.startsWith("'")) {
      _raw = _raw.substring(1);
    }
    _invalidate();
    // The run of picks survives a finished composition: picks in a row make a new word. It ends at
    // any other commit or reset (see _reset).
    return ComposerStep(commit: c.text);
  }

  @override
  void reset() => _reset();

  void _reset() {
    _raw = '';
    _run.clear();
    _invalidate();
  }

  /// Learns from a pick: multi-character picks count; words built from two or three picks in a row
  /// that the dictionary lacks are added. Only when the field allows learning.
  void _recordPick(String text, String letters) {
    if (!learningAllowed()) {
      _run.clear();
      return;
    }
    if (letters.isEmpty || text.isEmpty) return;
    var changed = false;
    if (text.runes.length >= 2) {
      learned.add(letters, text);
      changed = true;
    }
    _run.add(_Pick(text, letters));
    if (_run.length > 3) _run.removeAt(0);
    final dict = lexicon.dictionary;
    for (var span = 2; span <= _run.length; span++) {
      final part = _run.sublist(_run.length - span);
      final joinedText = part.map((p) => p.text).join();
      final joinedLetters = part.map((p) => p.letters).join();
      final n = joinedText.runes.length;
      if (n < 2 || n > 4) continue;
      if (dict != null && dict.entriesFor(joinedLetters).any((e) => e.text == joinedText)) continue;
      learned.add(joinedLetters, joinedText);
      changed = true;
    }
    if (changed) {
      _learnVersion++;
      _invalidate();
      onLearned?.call();
    }
  }
}

bool _isAsciiLetter(int c) => (c >= 0x61 && c <= 0x7A) || (c >= 0x41 && c <= 0x5A);
