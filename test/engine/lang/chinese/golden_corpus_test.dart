// SPDX-License-Identifier: GPL-3.0-or-later
//
// Accuracy and speed of the pinyin composer on the real dict-zh-rime-ice pack. The pack is not in
// the repository: it is staged by tool/packs/chinese/stage_rime_ice.ps1 under
// %USERPROFILE%\.booboard\packs\staging\dict-zh-rime-ice. Without it this test is skipped.
//
// golden_zh.txt (300 lines, `pinyin<TAB>text`) was drawn from the same dictionary by
// tool/chinese/build_zh_dict.dart --golden, so it measures segmentation and ranking, not
// independent knowledge. Target: top-1 at least 85%, top-5 at least 95%.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/lang/chinese/learned_phrases.dart';
import 'package:booboard/src/engine/lang/chinese/pinyin_composer.dart';
import 'package:booboard/src/engine/lang/chinese/zh_lexicon.dart';

String? _stagedDir() {
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null) return null;
  final dir =
      '$home${Platform.pathSeparator}.booboard${Platform.pathSeparator}packs${Platform.pathSeparator}staging'
      '${Platform.pathSeparator}dict-zh-rime-ice';
  return File('$dir${Platform.pathSeparator}zh.kdict').existsSync() ? dir : null;
}

double _percentile(List<int> sorted, double p) =>
    sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * p).round()].toDouble();

void main() {
  final dir = _stagedDir();
  final skip = dir == null ? 'the dict-zh-rime-ice pack is not staged on this machine' : null;

  test('top-1 and top-5 accuracy, and per-key time, on the golden corpus', () {
    final lexicon = ZhLexicon()..install(_load(dir!));
    final lines = File('test/engine/lang/chinese/golden_zh.txt').readAsLinesSync();
    final composer = PinyinComposer(
      lexicon: lexicon,
      options: () => const PinyinOptions(),
      learned: LearnedPhrases(),
      learningAllowed: () => false,
    );

    var top1 = 0;
    var top5 = 0;
    final keyMicros = <int>[];
    final misses = <String>[];
    for (final line in lines) {
      final tab = line.indexOf('\t');
      // Typed as people type: letters only. The apostrophes in the corpus mark the syllables and would
      // force every break; the break rule has its own tests.
      final pinyin = line.substring(0, tab).replaceAll("'", '');
      final text = line.substring(tab + 1);
      composer.reset();
      var rank = -1;
      for (var i = 0; i < pinyin.length; i++) {
        // Each key is timed with the candidate list the controller would read after it.
        final sw = Stopwatch()..start();
        composer.onText(pinyin[i]);
        final cands = composer.state.candidates;
        sw.stop();
        keyMicros.add(sw.elapsedMicroseconds);
        if (i == pinyin.length - 1) rank = cands.indexWhere((c) => c.text == text);
      }
      if (rank == 0) top1++;
      if (rank >= 0 && rank < 5) top5++;
      if (rank != 0) misses.add(pinyin);
      composer.reset();
    }

    final n = lines.length;
    final sorted = [...keyMicros]..sort();
    final median = _percentile(sorted, 0.5) / 1000;
    final p95 = _percentile(sorted, 0.95) / 1000;
    stdout.writeln(
      'golden: $n phrases, top-1 ${(100 * top1 / n).toStringAsFixed(1)}%, '
      'top-5 ${(100 * top5 / n).toStringAsFixed(1)}%, per key median ${median.toStringAsFixed(3)} ms, '
      'p95 ${p95.toStringAsFixed(3)} ms',
    );
    if (misses.isNotEmpty) stdout.writeln('first misses (pinyin only): ${misses.take(12).join(', ')}');

    expect(top1 / n, greaterThanOrEqualTo(0.85));
    expect(top5 / n, greaterThanOrEqualTo(0.95));
    expect(p95, lessThan(30), reason: 'per-key budget, milliseconds');
  }, skip: skip);
}

ZhLoaded _load(String dir) =>
    readZhPackFiles(dir, const ZhPackInfo(id: 'dict-zh-rime-ice', name: 'rime-ice', sizeBytes: 0));
