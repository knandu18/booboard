// SPDX-License-Identifier: GPL-3.0-or-later
//
// Shared helpers for the gesture tests: a QWERTY test geometry, the English
// word-list fixture and a synthetic swipe generator.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Rect, Size;

import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/gesture/gesture_engine.dart';
import 'package:booboard/src/engine/gesture/template_index.dart';
import 'package:booboard/src/engine/in_memory_lexicon.dart';

/// QWERTY letter rows of 10, 9 and 7 keys on a 1080 px wide keyboard.
KeyboardGeometry qwertyGeometry({double width = 1080, double rowHeight = 150}) {
  const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
  final pitch = width / 10;
  final keyW = pitch - 8;
  final keyH = rowHeight - 12;
  final keys = <String, Rect>{};
  for (var r = 0; r < rows.length; r++) {
    final offset = [0.0, pitch * 0.5, pitch * 1.5][r];
    for (var i = 0; i < rows[r].length; i++) {
      final left = offset + i * pitch + 4;
      final top = r * rowHeight + 6;
      keys[rows[r][i]] = Rect.fromLTWH(left, top, keyW, keyH);
    }
  }
  return KeyboardGeometry(layoutId: 'qwerty-test', size: Size(width, rowHeight * 3), keys: keys);
}

class WordFreq {
  WordFreq(this.word, this.f);

  final String word;

  /// AOSP LatinIME frequency byte (0..255, roughly logarithmic).
  final int f;
}

/// The 50k most frequent English words of the AOSP LatinIME en_US list.
List<WordFreq> loadEnglishFixture() {
  final bytes = File('test/engine/gesture/fixtures/en_words.tsv.gz').readAsBytesSync();
  final text = utf8.decode(gzip.decode(bytes));
  final out = <WordFreq>[];
  for (final line in text.split('\n')) {
    if (line.isEmpty) continue;
    final tab = line.indexOf('\t');
    out.add(WordFreq(line.substring(0, tab), int.parse(line.substring(tab + 1))));
  }
  return out;
}

/// A lexicon built from the fixture. The frequency byte is roughly
/// 12.7 steps per nat, which gives realistic unigram probabilities.
InMemoryLexicon fixtureLexicon(List<WordFreq> words, {LanguageId language = 'en'}) {
  final counts = [for (final w in words) math.max(1, (math.exp((w.f - 64) / 12.7) * 1000).round())];
  return InMemoryLexicon(language, [for (final w in words) w.word], counts: counts);
}

double _gauss(math.Random rnd) {
  final u = 1 - rnd.nextDouble();
  final v = rnd.nextDouble();
  return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v);
}

/// Generates swipes through key centres with human-like imperfection.
class SwipeSynth {
  SwipeSynth(this.geometry, {int seed = 7, this.noise = 0.25}) : _rnd = math.Random(seed);

  final KeyboardGeometry geometry;
  final math.Random _rnd;

  /// Waypoint noise in key widths (std dev).
  final double noise;

  /// null when the word has a character that is not a plain a-z key.
  GesturePath? generate(String word) {
    final kw = geometry.keyWidth;
    final seq = <String>[];
    for (final ch in word.toLowerCase().split('')) {
      if (ch == "'") continue;
      if (geometry.keys[ch] == null) return null;
      if (seq.isNotEmpty && seq.last == ch) continue;
      seq.add(ch);
    }
    if (seq.length < 2) return null;

    // Waypoints with per-key landing error; ends are a little sloppier.
    final wx = <double>[], wy = <double>[];
    for (var i = 0; i < seq.length; i++) {
      final c = geometry.centerOf(seq[i])!;
      final ends = (i == 0 || i == seq.length - 1) ? 1.25 : 1.0;
      wx.add(c.dx + _gauss(_rnd) * noise * kw * ends);
      wy.add(c.dy + _gauss(_rnd) * noise * kw * ends * 0.8);
    }

    // Sample each segment with its own speed; smooth correlated jitter on top.
    final points = <TouchPoint>[];
    var t = 0.0;
    var jx = 0.0, jy = 0.0;
    final spacingBase = kw * (0.06 + _rnd.nextDouble() * 0.18); // sampling density per frame
    for (var i = 0; i + 1 < seq.length; i++) {
      final dx = wx[i + 1] - wx[i], dy = wy[i + 1] - wy[i];
      final dist = math.sqrt(dx * dx + dy * dy);
      final speed = (0.6 + _rnd.nextDouble() * 1.4) * kw / 80.0; // px per ms
      final n = math.max(2, (dist / (spacingBase * (0.7 + _rnd.nextDouble() * 0.6))).round());
      for (var s = (i == 0 ? 0 : 1); s <= n; s++) {
        final f = s / n;
        jx = 0.8 * jx + _gauss(_rnd) * 0.03 * kw;
        jy = 0.8 * jy + _gauss(_rnd) * 0.03 * kw;
        points.add(TouchPoint(wx[i] + dx * f + jx, wy[i] + dy * f + jy, t.round() + (dist * f / speed).round()));
      }
      t += dist / speed;
    }
    return GesturePath(points);
  }
}

/// Builds a synchronous engine over the given lexicons (no isolate), for
/// accuracy and speed measurements of the core.
GestureEngine buildEngine(
  KeyboardGeometry geometry,
  List<Lexicon> lexicons, {
  GestureTuning tuning = const GestureTuning(),
  int perLanguage = 60000,
}) {
  final engine = GestureEngine(tuning: tuning);
  final chars = <String>[];
  final rects = <double>[];
  geometry.keys.forEach((c, r) {
    chars.add(c);
    rects
      ..add(r.left)
      ..add(r.top)
      ..add(r.right)
      ..add(r.bottom);
  });
  engine.setKeys(GestureKeys(chars: chars, rects: Float64List.fromList(rects), keyWidth: geometry.keyWidth));
  final lists = <WordList>[];
  for (var i = 0; i < lexicons.length; i++) {
    final entries = lexicons[i].entries(limit: perLanguage).toList();
    lists.add(
      WordList(
        language: i,
        words: [for (final e in entries) e.word],
        logProbs: Float64List.fromList([for (final e in entries) e.logProb]),
      ),
    );
  }
  engine.buildBase(lists);
  return engine;
}

Float64List toXy(GesturePath path) {
  final xy = Float64List(path.points.length * 2);
  for (var i = 0; i < path.points.length; i++) {
    xy[i * 2] = path.points[i].x;
    xy[i * 2 + 1] = path.points[i].y;
  }
  return xy;
}

/// Deterministic sample of [count] plain-letter words (length >= 3) from the
/// top [pool] words of the fixture.
List<String> sampleWords(List<WordFreq> all, {int count = 300, int pool = 2500, int seed = 11}) {
  final candidates = [
    for (final w in all.take(pool))
      if (RegExp(r'^[a-z]{3,}$').hasMatch(w.word)) w.word,
  ];
  candidates.shuffle(math.Random(seed));
  return candidates.take(count).toList();
}

double percentile(List<double> values, double p) {
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * p).round()];
}
