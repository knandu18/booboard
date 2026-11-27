// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/gesture/isolate_gesture_decoder.dart';
import 'package:booboard/src/engine/in_memory_lexicon.dart';

import 'gesture_test_support.dart';

void main() {
  late List<WordFreq> fixture;
  late InMemoryLexicon lexicon;
  late KeyboardGeometry geometry;
  late List<String> words;

  setUpAll(() {
    fixture = loadEnglishFixture();
    lexicon = fixtureLexicon(fixture);
    geometry = qwertyGeometry();
    words = sampleWords(fixture);
  });

  test('fixture is a realistic vocabulary', () {
    expect(fixture.length, 50000);
    expect(words.length, 300);
  });

  test('core engine: top-1 >= 75% and top-3 >= 90% on 300 noisy synthetic swipes', () {
    final engine = buildEngine(geometry, [lexicon]);
    expect(engine.templateCount, greaterThan(40000));
    final synth = SwipeSynth(geometry, seed: 5);
    var top1 = 0, top3 = 0, n = 0;
    final ms = <double>[];
    for (final w in words) {
      final path = synth.generate(w)!;
      final sw = Stopwatch()..start();
      final result = engine.decode(toXy(path), maxResults: 6);
      ms.add(sw.elapsedMicroseconds / 1000);
      final ranked = [for (final c in result) c.word.toLowerCase()];
      n++;
      if (ranked.isNotEmpty && ranked.first == w) top1++;
      if (ranked.take(3).contains(w)) top3++;
    }
    // ignore: avoid_print
    print(
      'core accuracy over $n swipes: top1=${(top1 / n * 100).toStringAsFixed(1)}% '
      'top3=${(top3 / n * 100).toStringAsFixed(1)}%  decode p50=${percentile(ms, 0.5).toStringAsFixed(2)} ms '
      'p95=${percentile(ms, 0.95).toStringAsFixed(2)} ms  templates=${engine.templateCount} '
      '(~${(engine.approxBytes / 1048576).toStringAsFixed(1)} MB)',
    );
    expect(top1 / n, greaterThanOrEqualTo(0.75));
    expect(top3 / n, greaterThanOrEqualTo(0.90));
    expect(percentile(ms, 0.95), lessThan(40));
  });

  test('accuracy degrades gracefully with sloppier swipes (noise 0.35 key widths)', () {
    final engine = buildEngine(geometry, [lexicon]);
    final synth = SwipeSynth(geometry, seed: 9, noise: 0.35);
    var top3 = 0;
    for (final w in words) {
      final ranked = [for (final c in engine.decode(toXy(synth.generate(w)!), maxResults: 6)) c.word.toLowerCase()];
      if (ranked.take(3).contains(w)) top3++;
    }
    expect(top3 / words.length, greaterThanOrEqualTo(0.80));
  });

  test('through the isolate: accuracy and p95 latency with 3 blended languages', () async {
    // Three lexicons of 50k words each (same vocabulary under different ids)
    // exercise the worst-case template count: 150k templates.
    final source = InMemoryLexiconSource({
      'en': fixtureLexicon(fixture, language: 'en'),
      'en-GB': fixtureLexicon(fixture, language: 'en-GB'),
      'en-AU': fixtureLexicon(fixture, language: 'en-AU'),
    });
    final decoder = IsolateGestureDecoder(lexicons: source);
    addTearDown(decoder.dispose);
    final prep = Stopwatch()..start();
    await decoder.prepare(geometry: geometry, languages: ['en', 'en-GB', 'en-AU']);
    prep.stop();
    expect(decoder.templateCount, greaterThan(120000));

    final synth = SwipeSynth(geometry, seed: 21);
    final sample = words.take(150).toList();
    var top1 = 0, top3 = 0;
    final ms = <double>[];
    for (final w in sample) {
      final sw = Stopwatch()..start();
      final result = await decoder.decode(synth.generate(w)!, maxResults: 6);
      ms.add(sw.elapsedMicroseconds / 1000);
      final ranked = [for (final s in result) s.text.toLowerCase()];
      if (ranked.isNotEmpty && ranked.first == w) top1++;
      if (ranked.take(3).contains(w)) top3++;
      expect(result.every((s) => s.kind == SuggestionKind.gesture), isTrue);
    }
    // ignore: avoid_print
    print(
      'isolate (3 languages, ${decoder.templateCount} templates): prepare=${prep.elapsedMilliseconds} ms '
      'top1=${(top1 / sample.length * 100).toStringAsFixed(1)}% top3=${(top3 / sample.length * 100).toStringAsFixed(1)}% '
      'decode round-trip p50=${percentile(ms, 0.5).toStringAsFixed(2)} ms p95=${percentile(ms, 0.95).toStringAsFixed(2)} ms',
    );
    expect(top1 / sample.length, greaterThanOrEqualTo(0.75));
    expect(top3 / sample.length, greaterThanOrEqualTo(0.90));
    expect(percentile(ms, 0.95), lessThan(40));
  });
}
