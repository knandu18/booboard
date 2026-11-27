// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B (Japanese). Kana-kanji conversion: a lattice of dictionary words over the reading,
// a Viterbi pass that minimises word costs plus connection costs, and the candidates of each segment.
// Pure Dart; the dictionary is read in place (see japanese_dictionary.dart).
//
// PRIVACY: nothing here logs, and the text is kept only for the lifetime of the returned segments.
import 'kana.dart';
import 'japanese_dictionary.dart';
import 'japanese_learning.dart';

/// One converted piece: the reading characters [start, end) and the candidates for them.
/// `candidates[0]` is what the segment starts with (the Viterbi choice); the rest follow, dictionary
/// surfaces before kana forms (hiragana, katakana, widths).
class JapaneseSegment {
  JapaneseSegment({
    required this.start,
    required this.end,
    required this.reading,
    required this.candidates,
    required this.dictionarySurfaces,
  });

  final int start;
  final int end;

  /// The reading of this piece (hiragana, or raw letters).
  final String reading;
  final List<String> candidates;

  /// The candidates that are dictionary words (only these are learned).
  final Set<String> dictionarySurfaces;

  /// The candidate the segment shows.
  int chosen = 0;

  String get surface => candidates[chosen];

  /// True when the chosen candidate is a dictionary word.
  bool get choseDictionary => dictionarySurfaces.contains(surface);
}

/// A dictionary word that starts with the typed reading.
typedef JapanesePrediction = ({String surface, int cost, String reading});

class JapaneseConverter {
  JapaneseConverter({this.dictionary, this.learning});

  /// Null until the pack is loaded: then conversion offers kana forms only.
  final JapaneseDictionary? dictionary;

  /// Learned picks (may be null for none).
  final JapaneseLearning? learning;

  static const int _maxCandidates = 30;
  static const int _maxPredictionReadings = 400;
  static const int _unreachable = 1 << 40;

  /// Converts [reading] (hiragana, possibly with raw ASCII letters) into segments: the Viterbi path
  /// through the lattice. Without a dictionary the whole reading is one segment with kana forms.
  List<JapaneseSegment> convert(String reading) {
    final n = reading.length;
    if (n == 0) return const [];
    final dict = dictionary;
    if (dict == null) return [_kanaOnly(reading, 0, n)];

    final byStart = List<List<_Node>>.generate(n, (_) => []);
    final byEnd = List<List<_Node>>.generate(n + 1, (_) => []);
    for (final node in _buildLattice(dict, reading)) {
      byStart[node.start].add(node);
      byEnd[node.end].add(node);
    }

    // Forward pass. Nodes are visited by start position, so every predecessor is final before use.
    for (var s = 0; s < n; s++) {
      for (final node in byStart[s]) {
        if (s == 0) {
          node.best = dict.connection(0, node.lid) + node.cost;
          node.back = null;
          continue;
        }
        var bestCost = _unreachable;
        _Node? bestPrev;
        for (final prev in byEnd[s]) {
          if (prev.best >= _unreachable) continue;
          final c = prev.best + dict.connection(prev.rid, node.lid);
          if (c < bestCost) {
            bestCost = c;
            bestPrev = prev;
          }
        }
        if (bestPrev == null) {
          node.best = _unreachable;
        } else {
          node.best = bestCost + node.cost;
          node.back = bestPrev;
        }
      }
    }

    _Node? last;
    var lastCost = _unreachable;
    for (final node in byEnd[n]) {
      if (node.best >= _unreachable) continue;
      final c = node.best + dict.connection(node.rid, 0);
      if (c < lastCost) {
        last = node;
        lastCost = c;
      }
    }
    if (last == null) return [_kanaOnly(reading, 0, n)];

    final path = <_Node>[];
    for (_Node? node = last; node != null; node = node.back) {
      path.add(node);
    }
    return [for (final node in path.reversed) _segmentFor(dict, reading, node)];
  }

  /// The candidates for the exact span [start, end) of [reading], best first. Used when a segment's
  /// boundaries change and when the reading has no path.
  JapaneseSegment span(String reading, int start, int end) {
    final sub = reading.substring(start, end);
    final dict = dictionary;
    final surfaces = <String>[];
    final dictionarySurfaces = <String>{};
    if (dict != null) {
      final learned = learning;
      if (learned != null && learned.hasReading(sub)) {
        surfaces.addAll(learned.surfacesFor(sub));
      }
      final r = dict.readingIndex(sub);
      if (r != null) {
        final entries = <({String surface, int cost})>[
          for (var e = dict.entryStart(r); e < dict.entryEnd(r); e++) (surface: dict.surface(e), cost: dict.cost(e)),
        ]..sort((a, b) => a.cost.compareTo(b.cost));
        for (final e in entries) {
          if (surfaces.length >= _maxCandidates) break;
          if (!surfaces.contains(e.surface)) surfaces.add(e.surface);
        }
      }
      dictionarySurfaces.addAll(surfaces);
    }
    for (final k in formsOf(sub)) {
      if (!surfaces.contains(k)) surfaces.add(k);
    }
    return JapaneseSegment(
      start: start,
      end: end,
      reading: sub,
      candidates: surfaces,
      dictionarySurfaces: dictionarySurfaces,
    );
  }

  /// Dictionary words that start with [reading], best first. A tap on one replaces the whole reading.
  List<JapanesePrediction> predict(String reading, {int limit = 20}) {
    final dict = dictionary;
    if (dict == null || reading.isEmpty) return const [];
    final learned = learning;
    final rows = <JapanesePrediction>[];
    var scanned = 0;
    for (var r = dict.firstReadingWithPrefix(reading); r < dict.readingCount; r++) {
      if (scanned++ >= _maxPredictionReadings || !dict.readingStartsWith(r, reading)) break;
      final text = dict.readingAt(r);
      for (var e = dict.entryStart(r); e < dict.entryEnd(r); e++) {
        rows.add((surface: dict.surface(e), cost: dict.cost(e), reading: text));
      }
    }
    rows.sort((a, b) {
      final la = learned?.count(a.reading, a.surface) ?? 0;
      final lb = learned?.count(b.reading, b.surface) ?? 0;
      if (la != lb) return lb.compareTo(la);
      return a.cost.compareTo(b.cost);
    });
    final seen = <String>{};
    final out = <JapanesePrediction>[];
    for (final row in rows) {
      if (out.length >= limit) break;
      if (seen.add(row.surface)) out.add(row);
    }
    return out;
  }

  JapaneseSegment _kanaOnly(String reading, int start, int end) {
    final sub = reading.substring(start, end);
    return JapaneseSegment(
      start: start,
      end: end,
      reading: sub,
      candidates: formsOf(sub),
      dictionarySurfaces: const {},
    );
  }

  JapaneseSegment _segmentFor(JapaneseDictionary dict, String reading, _Node node) {
    final span = this.span(reading, node.start, node.end);
    final pick = node.surface(dict);
    final pickIsDictionary = node.entry >= 0;
    final candidates = [
      pick,
      for (final c in span.candidates)
        if (c != pick) c,
    ];
    final dictionarySurfaces = {if (pickIsDictionary) pick, ...span.dictionarySurfaces};
    return JapaneseSegment(
      start: node.start,
      end: node.end,
      reading: span.reading,
      candidates: candidates,
      dictionarySurfaces: dictionarySurfaces,
    );
  }

  /// Hiragana, katakana and, for ASCII, the full-width form, without duplicates.
  static List<String> formsOf(String sub) {
    final forms = <String>[sub];
    final katakana = toKatakana(sub);
    if (katakana != sub) forms.add(katakana);
    if (sub.isNotEmpty && sub.codeUnits.every((c) => c < 0x80)) {
      final full = toFullWidthAscii(sub);
      if (!forms.contains(full)) forms.add(full);
    }
    return forms;
  }

  List<_Node> _buildLattice(JapaneseDictionary dict, String reading) {
    final n = reading.length;
    final nodes = <_Node>[];
    final learned = learning;
    for (var s = 0; s < n; s++) {
      final maxEnd = s + JapaneseLexiconFormat.maxReadingLength < n ? s + JapaneseLexiconFormat.maxReadingLength : n;
      for (var e = s + 1; e <= maxEnd; e++) {
        final sub = reading.substring(s, e);
        final r = dict.readingIndex(sub);
        if (r == null) continue;
        for (var entry = dict.entryStart(r); entry < dict.entryEnd(r); entry++) {
          var cost = dict.cost(entry);
          if (learned != null && learned.hasReading(sub)) {
            cost -= JapaneseLearning.bonusFor(learned.count(sub, dict.surface(entry)));
          }
          nodes.add(_Node(start: s, end: e, lid: dict.lid(entry), rid: dict.rid(entry), cost: cost, entry: entry));
        }
      }
      // One unknown node per character, so every position can always be crossed.
      nodes.add(
        _Node(
          start: s,
          end: s + 1,
          lid: dict.unknownId,
          rid: dict.unknownId,
          cost: JapaneseLexiconFormat.unknownCost,
          entry: -1,
          unknownText: reading[s],
        ),
      );
    }
    return nodes;
  }
}

class _Node {
  _Node({
    required this.start,
    required this.end,
    required this.lid,
    required this.rid,
    required this.cost,
    required this.entry,
    this.unknownText,
  });

  final int start;
  final int end;
  final int lid;
  final int rid;

  /// Word cost, with any learned bonus applied.
  final int cost;

  /// Index into the dictionary entries, or -1 for an unknown character.
  final int entry;
  final String? unknownText;

  int best = 0;
  _Node? back;

  String surface(JapaneseDictionary dict) => unknownText ?? dict.surface(entry);
}
