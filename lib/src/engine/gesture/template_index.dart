// SPDX-License-Identifier: GPL-3.0-or-later
//
// Word templates for the swipe decoder: every word becomes a key-centre
// polyline resampled to 64 points, stored compactly and indexed by
// (first key, last key). Runs in the background isolate.
import 'dart:math' as math;
import 'dart:typed_data';

import 'gesture_math.dart';

final RegExp _letterRe = RegExp(r'^\p{L}$', unicode: true);

/// The letter keys of the current layout, in primitive form so it can be sent
/// to the isolate.
class GestureKeys {
  GestureKeys({required this.chars, required Float64List rects, required this.keyWidth})
    : count = chars.length,
      centerX = Float64List(chars.length),
      centerY = Float64List(chars.length),
      _runeToIndex = <int, int>{} {
    var maxX = 0.0;
    var maxY = 0.0;
    for (var i = 0; i < count; i++) {
      final l = rects[i * 4], t = rects[i * 4 + 1], r = rects[i * 4 + 2], b = rects[i * 4 + 3];
      centerX[i] = (l + r) / 2;
      centerY[i] = (t + b) / 2;
      maxX = math.max(maxX, r);
      maxY = math.max(maxY, b);
      _runeToIndex[chars[i].runes.first] = i;
    }
    extent = math.max(1.0, math.max(maxX, maxY));
  }

  /// Whether a layout key output is a letter that a swipe can pass over.
  static bool isLetterKey(String char) => char.runes.length == 1 && _letterRe.hasMatch(char);

  final List<String> chars;
  final double keyWidth;
  final int count;
  final Float64List centerX;
  final Float64List centerY;
  late final double extent;
  final Map<int, int> _runeToIndex;

  int indexOfRune(int rune) => _runeToIndex[rune] ?? -1;

  /// Index of the key whose centre is nearest to the point, or -1.
  int nearest(double x, double y) {
    var best = -1;
    var bestD = double.infinity;
    for (var i = 0; i < count; i++) {
      final d = _sq(centerX[i] - x) + _sq(centerY[i] - y);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// Writes the keys whose centre is within [radius] of the point into [out]
  /// (always including the nearest key) and returns how many.
  int neighbours(double x, double y, double radius, Int32List out) {
    var n = 0;
    final r2 = radius * radius;
    for (var i = 0; i < count && n < out.length; i++) {
      if (_sq(centerX[i] - x) + _sq(centerY[i] - y) <= r2) out[n++] = i;
    }
    if (n == 0) {
      final nearestKey = nearest(x, y);
      if (nearestKey >= 0) out[n++] = nearestKey;
    }
    return n;
  }

  /// Folds [word] (lower case) to the sequence of key indices a swipe passes
  /// through: accents map to base keys, apostrophes vanish and repeated keys
  /// collapse. Writes into [out] and returns the length, or -1 when a
  /// character has no key (the word is not swipeable on this layout).
  int foldWord(String word, Int32List out) {
    var n = 0;
    var last = -1;
    for (final rune in word.runes) {
      var idx = indexOfRune(rune);
      if (idx < 0) {
        if (isPathIgnorable(rune)) continue;
        idx = indexOfRune(foldToBaseRune(rune));
        if (idx < 0) return -1;
      }
      if (idx == last) continue;
      if (n >= out.length) return -1;
      out[n++] = idx;
      last = idx;
    }
    return n;
  }
}

double _sq(double v) => v * v;

/// Words of one language (or the learned words) with natural-log
/// probabilities, most frequent first is not required.
class WordList {
  WordList({required this.language, required this.words, required this.logProbs});

  /// Index into the decoder's language table (-1 for learned words).
  final int language;
  final List<String> words;
  final Float64List logProbs;
}

/// A scored candidate straight out of the decoder, before bigram re-ranking.
class RawCandidate {
  RawCandidate(this.word, this.language, this.geo, this.logProb, this.learned);

  final String word;
  final int language;

  /// Gaussian log-likelihood of the geometry (location + shape), <= 0.
  final double geo;

  /// Unigram log-probability that was used while pruning.
  final double logProb;
  final bool learned;
}

/// Compact template storage. 64 points per word as Int16 (1/16 px steps).
class TemplateSet {
  TemplateSet._({
    required this.keys,
    required this.learned,
    required this.count,
    required this.words,
    required this.language,
    required this.logProb,
    required this.points,
    required this.quant,
    required this.length,
    required this.centroidX,
    required this.centroidY,
    required this.diag,
    required this.bounds,
    required this.bucketStart,
    required this.bucketItems,
  });

  final GestureKeys keys;
  final bool learned;
  final int count;
  final List<String> words;
  final Int16List language;
  final Float32List logProb;

  /// `count * 128` quantised coordinates: x0, y0, x1, y1, ...
  final Int16List points;

  /// Quantisation factor: coordinate = stored / quant.
  final double quant;
  final Float32List length;
  final Float32List centroidX;
  final Float32List centroidY;
  final Float32List diag;

  /// minX, minY, maxX, maxY per template.
  final Float32List bounds;

  /// CSR index: templates of bucket `first * keyCount + last` are
  /// `bucketItems[bucketStart[b] .. bucketStart[b + 1])`, most frequent first.
  final Int32List bucketStart;
  final Int32List bucketItems;

  int get approxBytes =>
      points.lengthInBytes +
      length.lengthInBytes * 4 +
      bounds.lengthInBytes +
      logProb.lengthInBytes +
      language.lengthInBytes +
      bucketItems.lengthInBytes +
      count * 24;

  static TemplateSet build(GestureKeys keys, List<WordList> lists, {required bool learned}) {
    final nKeys = keys.count;
    var total = 0;
    for (final l in lists) {
      total += l.words.length;
    }
    // Flatten and order by probability, most frequent first, so a bucket's
    // items are already in frequency order (also across languages).
    final allWords = List<String>.filled(total, '');
    final allLp = Float64List(total);
    final allLang = Int16List(total);
    var at = 0;
    for (final l in lists) {
      for (var i = 0; i < l.words.length; i++, at++) {
        allWords[at] = l.words[i];
        allLp[at] = l.logProbs[i];
        allLang[at] = l.language;
      }
    }
    final order = List<int>.generate(total, (i) => i)
      ..sort((a, b) {
        final c = allLp[b].compareTo(allLp[a]);
        return c != 0 ? c : a.compareTo(b);
      });

    final quant = math.min(16.0, 32000.0 / keys.extent);
    final words = <String>[];
    final language = Int16List(total);
    final logProb = Float32List(total);
    final points = Int16List(total * kGesturePoints * 2);
    final length = Float32List(total);
    final cxs = Float32List(total);
    final cys = Float32List(total);
    final diag = Float32List(total);
    final bounds = Float32List(total * 4);
    final bucketOf = Int32List(total);

    final seq = Int32List(48);
    final px = Float64List(48);
    final py = Float64List(48);
    final rx = Float64List(kGesturePoints);
    final ry = Float64List(kGesturePoints);
    final seen = <String>{};
    var m = 0;
    for (final g in order) {
      final word = allWords[g];
      if (word.isEmpty || word.length > 40) continue;
      final lower = word.toLowerCase();
      if (!seen.add('${allLang[g]}\u0000$lower')) continue;
      final n = keys.foldWord(lower, seq);
      if (n < 2) continue;
      for (var i = 0; i < n; i++) {
        px[i] = keys.centerX[seq[i]];
        py[i] = keys.centerY[seq[i]];
      }
      final len = resamplePolyline(px, py, n, kGesturePoints, rx, ry);
      var sx = 0.0, sy = 0.0;
      var minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
      final base = m * kGesturePoints * 2;
      for (var k = 0; k < kGesturePoints; k++) {
        final x = rx[k], y = ry[k];
        sx += x;
        sy += y;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        points[base + k * 2] = (x * quant).round();
        points[base + k * 2 + 1] = (y * quant).round();
      }
      words.add(word);
      language[m] = allLang[g];
      logProb[m] = allLp[g];
      length[m] = len;
      cxs[m] = sx / kGesturePoints;
      cys[m] = sy / kGesturePoints;
      diag[m] = math.max(1.0, math.sqrt(_sq(maxX - minX) + _sq(maxY - minY)));
      bounds[m * 4] = minX;
      bounds[m * 4 + 1] = minY;
      bounds[m * 4 + 2] = maxX;
      bounds[m * 4 + 3] = maxY;
      bucketOf[m] = seq[0] * nKeys + seq[n - 1];
      m++;
    }

    final bucketStart = Int32List(nKeys * nKeys + 1);
    for (var i = 0; i < m; i++) {
      bucketStart[bucketOf[i] + 1]++;
    }
    for (var b = 0; b < nKeys * nKeys; b++) {
      bucketStart[b + 1] += bucketStart[b];
    }
    final fill = Int32List.fromList(bucketStart);
    final bucketItems = Int32List(m);
    for (var i = 0; i < m; i++) {
      bucketItems[fill[bucketOf[i]]++] = i;
    }

    return TemplateSet._(
      keys: keys,
      learned: learned,
      count: m,
      words: words,
      language: _trim16(language, m),
      logProb: _trim32(logProb, m),
      points: _trim16(points, m * kGesturePoints * 2),
      quant: quant,
      length: _trim32(length, m),
      centroidX: _trim32(cxs, m),
      centroidY: _trim32(cys, m),
      diag: _trim32(diag, m),
      bounds: _trim32(bounds, m * 4),
      bucketStart: bucketStart,
      bucketItems: bucketItems,
    );
  }
}

Int16List _trim16(Int16List list, int used) => used == list.length ? list : list.sublist(0, used);

Float32List _trim32(Float32List list, int used) => used == list.length ? list : list.sublist(0, used);
