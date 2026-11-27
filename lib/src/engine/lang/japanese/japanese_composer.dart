// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B (Japanese). The Japanese TextComposer: romaji (QWERTY) or 12-key kana input, then
// kana-kanji conversion with segments. One composer serves both layouts; the active layout id says
// whether letters are romaji (`romaji_ja`) or kana (`kana12_ja`).
//
// Typing: the preedit is kana. Candidates while typing are dictionary words that start with the
// reading (best first), then the hiragana and katakana forms.
// Converting (space): the reading is split by a Viterbi pass into segments. Space steps the focused
// segment through its candidates; the cursor keys move the focus; segment shorter/longer resize it;
// enter commits every segment. Backspace goes back to the reading.
// Learning: a dictionary word picked for a segment ranks higher next time (only when allowed).
//
// PRIVACY: never logs the buffer, the preedit, the readings or the candidates.
import 'package:flutter/foundation.dart';

import '../../../settings/booboard_settings.dart';
import '../../../keyboard/input/composer.dart';
import 'japanese_dictionary.dart';
import 'japanese_learning.dart';
import 'kana.dart';
import 'lattice.dart';
import 'romaji.dart';

class JapaneseComposer extends TextComposer {
  JapaneseComposer({
    required this.layoutId,
    required this.settings,
    required this.learningAllowed,
    required this.clockMs,
    JapaneseLearning? learning,
    this.onLearned,
    this.onNeedsDictionary,
  }) : learning = learning ?? JapaneseLearning();

  /// The active layout id: `romaji_ja` for letters, anything else for kana keys.
  final String Function() layoutId;

  /// The settings read on each key (flick only, half-width space).
  final BooBoardSettings Function() settings;

  /// True when picks may be learned (see InputController.learningAllowed).
  final bool Function() learningAllowed;

  /// A millisecond clock for the multi-tap window.
  final int Function() clockMs;

  /// The learned picks. The feature loads and saves them.
  final JapaneseLearning learning;

  /// Called after learned picks changed (the feature saves them).
  final VoidCallback? onLearned;

  /// Called when conversion is asked for without a dictionary pack (the feature shows a chip).
  final VoidCallback? onNeedsDictionary;

  static const int tapWindowMs = 1000;

  JapaneseDictionary? _dictionary;
  bool _loading = false;
  final ValueNotifier<int> _changes = ValueNotifier(0);

  /// The typing buffer: the kana typed so far, and (romaji) the letters still waiting for a kana.
  final RomajiInput _buffer = RomajiInput();

  /// Non-null while converting: the segments of the reading.
  List<JapaneseSegment>? _segments;
  int _focus = 0;

  // Multi-tap and undo for the 12-key layout.
  String? _lastTapKey;
  int _lastTapAt = -1000000;
  String? _undoFrom;
  String? _undoTo;
  int _undoLength = -1;

  ComposerState? _cache;

  bool get _romajiMode => layoutId() == 'romaji_ja';
  bool get _converting => _segments != null;

  /// The dictionary is set when the pack is opened, and cleared when it is removed.
  bool get hasDictionary => _dictionary != null;

  void setDictionary(JapaneseDictionary? dictionary) {
    _dictionary = dictionary;
    _loading = false;
    _invalidate();
    _changes.value++;
  }

  /// True while the pack is opening (the strip shows a small progress mark).
  void setLoading(bool loading) {
    if (_loading == loading) return;
    _loading = loading;
    _invalidate();
    _changes.value++;
  }

  @override
  Listenable get changes => _changes;

  @override
  ComposerState get state => _cache ??= _compute();

  ComposerState _compute() {
    final segments = _segments;
    if (segments != null) {
      final seg = segments[_focus];
      return ComposerState(
        preedit: segments.map((s) => s.surface).join(),
        reading: seg.reading,
        candidates: [for (final c in seg.candidates) ComposerCandidate(c, consumes: seg.reading.length)],
        highlighted: seg.chosen,
        loading: _loading,
      );
    }
    final typed = _buffer.text;
    if (typed.isEmpty) return ComposerState(loading: _loading);
    return ComposerState(preedit: typed, candidates: _typingCandidates(typed), highlighted: -1, loading: _loading);
  }

  List<ComposerCandidate> _typingCandidates(String reading) {
    final out = <ComposerCandidate>[];
    final seen = <String>{};
    for (final p in _converter().predict(reading)) {
      if (seen.add(p.surface)) out.add(ComposerCandidate(p.surface, consumes: reading.length));
    }
    for (final form in JapaneseConverter.formsOf(reading)) {
      if (seen.add(form)) out.add(ComposerCandidate(form, consumes: reading.length));
    }
    return out;
  }

  JapaneseConverter _converter() => JapaneseConverter(dictionary: _dictionary, learning: learning);

  void _invalidate() => _cache = null;

  // ---- Keys ---------------------------------------------------------------

  @override
  ComposerStep onText(String text) {
    if (text.isEmpty) return ComposerStep.notHandled;
    final code = text.length == 1 ? text.codeUnitAt(0) : -1;
    final isLetter = code >= 0x41 && code <= 0x5A || code >= 0x61 && code <= 0x7A;
    if (_romajiMode && (isLetter || text == '-' || text == "'")) {
      final commit = _converting ? _takeText() : '';
      _buffer.add(isLetter ? text.toLowerCase() : text);
      _lastTapKey = null;
      _invalidate();
      return ComposerStep(commit: commit);
    }
    if (code >= 0 && isKanaInput(code)) {
      final commit = _converting ? _takeText() : '';
      _appendKana(text);
      return ComposerStep(commit: commit);
    }
    // A mark, a digit, a symbol or a katakana: it ends the reading and is typed after it.
    if (_buffer.isEmpty && !_converting) return ComposerStep.notHandled;
    final commit = _takeText();
    _lastTapKey = null;
    return ComposerStep(commit: '$commit$text');
  }

  void _appendKana(String ch) {
    _buffer.flush();
    final kana = _buffer.kana;
    final now = clockMs();
    if (!settings().japanese.flickOnly && kana.isNotEmpty && _lastTapKey == ch && now - _lastTapAt <= tapWindowMs) {
      final cycle = tapCycleFor(ch);
      final last = kana[kana.length - 1];
      if (cycle != null && cycle.contains(last)) {
        final next = cycle[(cycle.indexOf(last) + 1) % cycle.length];
        _undoFrom = last;
        _undoTo = next;
        _undoLength = kana.length;
        _buffer.kana = '${kana.substring(0, kana.length - 1)}$next';
        _lastTapAt = now;
        _invalidate();
        return;
      }
    }
    _buffer.kana = kana + ch;
    _lastTapKey = tapCycleFor(ch) != null ? ch : null;
    _lastTapAt = now;
    _undoFrom = null;
    _invalidate();
  }

  @override
  ComposerStep onSpace() {
    if (_converting) {
      final seg = _segments![_focus];
      seg.chosen = (seg.chosen + 1) % seg.candidates.length;
      _invalidate();
      return ComposerStep.consumed;
    }
    if (_buffer.isEmpty) {
      return settings().japanese.halfWidthSpace ? ComposerStep.notHandled : const ComposerStep(commit: '　');
    }
    _buffer.flush();
    final reading = _buffer.kana;
    if (_dictionary == null) onNeedsDictionary?.call();
    _segments = _converter().convert(reading);
    _focus = 0;
    _buffer.clear();
    _lastTapKey = null;
    _invalidate();
    return ComposerStep.consumed;
  }

  @override
  ComposerStep onEnter() {
    if (!_converting && _buffer.isEmpty) return ComposerStep.notHandled;
    return ComposerStep(commit: _takeText());
  }

  @override
  ComposerStep onBackspace() {
    if (_converting) {
      _revert();
      return ComposerStep.consumed;
    }
    if (_buffer.isEmpty) return ComposerStep.notHandled;
    _buffer.backspace();
    _lastTapKey = null;
    _invalidate();
    return ComposerStep.consumed;
  }

  @override
  ComposerStep onCustomKey(String code) {
    switch (code) {
      case ComposerKeys.kanaModifier:
        if (_buffer.isEmpty && !_converting) return ComposerStep.notHandled;
        if (_converting) _revert();
        _buffer.flush();
        final kana = _buffer.kana;
        if (kana.isEmpty) return ComposerStep.notHandled;
        final next = nextKanaModifier(kana[kana.length - 1]);
        if (next != null) _buffer.kana = '${kana.substring(0, kana.length - 1)}$next';
        _lastTapKey = null;
        _undoFrom = null;
        _invalidate();
        return ComposerStep.consumed;
      case ComposerKeys.undoCycle:
        final from = _undoFrom;
        final to = _undoTo;
        final kana = _buffer.kana;
        if (from == null || to == null || _converting || kana.length != _undoLength || !kana.endsWith(to)) {
          return ComposerStep.notHandled;
        }
        _buffer.kana = '${kana.substring(0, kana.length - 1)}$from';
        _undoFrom = null;
        _lastTapKey = null;
        _invalidate();
        return ComposerStep.consumed;
      case ComposerKeys.cursorLeft:
        if (!_converting) return ComposerStep.notHandled;
        if (_focus > 0) _focus--;
        _invalidate();
        return ComposerStep.consumed;
      case ComposerKeys.cursorRight:
        if (!_converting) return ComposerStep.notHandled;
        if (_focus < _segments!.length - 1) _focus++;
        _invalidate();
        return ComposerStep.consumed;
      case ComposerKeys.segmentShorter:
        if (!_converting) return ComposerStep.notHandled;
        _resize(-1);
        return ComposerStep.consumed;
      case ComposerKeys.segmentLonger:
        if (!_converting) return ComposerStep.notHandled;
        _resize(1);
        return ComposerStep.consumed;
      default:
        return ComposerStep.notHandled;
    }
  }

  @override
  ComposerStep selectCandidate(int index) {
    if (_converting) {
      final seg = _segments![_focus];
      if (index < 0 || index >= seg.candidates.length) return ComposerStep.notHandled;
      seg.chosen = index;
      _invalidate();
      return ComposerStep.consumed;
    }
    final candidates = state.candidates;
    if (index < 0 || index >= candidates.length) return ComposerStep.notHandled;
    final text = candidates[index].text;
    _clearAll();
    return ComposerStep(commit: text);
  }

  @override
  void reset() => _clearAll();

  // ---- Helpers ------------------------------------------------------------

  /// The text the buffer or the conversion stands for. Learns the picks, then clears everything.
  String _takeText() {
    final segments = _segments;
    if (segments != null) {
      final text = segments.map((s) => s.surface).join();
      _learn(segments);
      _clearAll();
      return text;
    }
    _buffer.flush();
    final text = _buffer.kana;
    _clearAll();
    return text;
  }

  void _learn(List<JapaneseSegment> segments) {
    if (!learningAllowed()) return;
    var changed = false;
    for (final seg in segments) {
      if (seg.choseDictionary) {
        learning.learn(seg.reading, seg.surface);
        changed = true;
      }
    }
    if (changed) onLearned?.call();
  }

  void _clearAll() {
    _buffer.clear();
    _segments = null;
    _focus = 0;
    _lastTapKey = null;
    _undoFrom = null;
    _undoTo = null;
    _undoLength = -1;
    _invalidate();
  }

  /// Back from conversion to the plain reading.
  void _revert() {
    final segments = _segments;
    if (segments == null) return;
    _buffer.clear();
    _buffer.kana = segments.map((s) => s.reading).join();
    _segments = null;
    _focus = 0;
    _invalidate();
  }

  /// Moves the focused segment's end one character left (-1) or right (+1). The segments on either
  /// side are re-converted for the new boundary.
  void _resize(int delta) {
    final segments = _segments!;
    final reading = segments.map((s) => s.reading).join();
    final i = _focus;
    final seg = segments[i];
    final converter = _converter();
    if (delta < 0) {
      if (seg.end - seg.start < 2) return;
      final newEnd = seg.end - 1;
      segments[i] = converter.span(reading, seg.start, newEnd);
      if (i + 1 < segments.length) {
        final next = segments[i + 1];
        segments[i + 1] = converter.span(reading, newEnd, next.end);
      } else {
        segments.insert(i + 1, converter.span(reading, newEnd, seg.end));
      }
    } else {
      if (seg.end >= reading.length) return;
      final newEnd = seg.end + 1;
      segments[i] = converter.span(reading, seg.start, newEnd);
      if (i + 1 < segments.length) {
        final next = segments[i + 1];
        if (next.end <= newEnd) {
          segments.removeAt(i + 1);
        } else {
          segments[i + 1] = converter.span(reading, newEnd, next.end);
        }
      }
    }
    _invalidate();
  }
}
