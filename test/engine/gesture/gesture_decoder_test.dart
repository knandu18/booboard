// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/gesture/decoder_factory.dart';
import 'package:booboard/src/engine/gesture/isolate_gesture_decoder.dart';
import 'package:booboard/src/engine/in_memory_lexicon.dart';

import 'gesture_test_support.dart';

/// A path through the given points with `steps` interpolated samples per leg.
GesturePath pathThrough(List<Offset> waypoints, {int steps = 12}) {
  final pts = <TouchPoint>[];
  var t = 0;
  for (var i = 0; i + 1 < waypoints.length; i++) {
    for (var s = i == 0 ? 0 : 1; s <= steps; s++) {
      final f = s / steps;
      final a = waypoints[i], b = waypoints[i + 1];
      pts.add(TouchPoint(a.dx + (b.dx - a.dx) * f, a.dy + (b.dy - a.dy) * f, t));
      t += 8;
    }
  }
  return GesturePath(pts);
}

GesturePath swipeOf(KeyboardGeometry geo, String keys) =>
    pathThrough([for (final c in keys.split('')) geo.centerOf(c)!]);

void main() {
  late List<WordFreq> fixture;
  late KeyboardGeometry geometry;

  setUpAll(() {
    fixture = loadEnglishFixture();
    geometry = qwertyGeometry();
  });

  /// A decoder over a small, controlled lexicon: [words] in frequency order.
  IsolateGestureDecoder small(List<String> words, {Map<(String, String), int>? bigrams, List<int>? counts}) {
    final lexicon = InMemoryLexicon('en', words, counts: counts, bigrams: bigrams);
    final decoder = IsolateGestureDecoder(lexicons: InMemoryLexiconSource({'en': lexicon}));
    addTearDown(decoder.dispose);
    return decoder;
  }

  group('decoding', () {
    test('a clean swipe returns suggestions of kind gesture with the language', () async {
      final decoder = small(['hello', 'help', 'hell', 'held', 'jello', 'the', 'and']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final result = await decoder.decode(swipeOf(geometry, 'hello'));
      expect(result, isNotEmpty);
      expect(result.first.text, 'hello');
      expect(result.first.kind, SuggestionKind.gesture);
      expect(result.first.language, 'en');
      expect(result.first.isLearned, isFalse);
      // Best first.
      for (var i = 1; i < result.length; i++) {
        expect(result[i].score, lessThanOrEqualTo(result[i - 1].score));
      }
    });

    test('createGestureDecoder returns a working decoder', () async {
      final lexicon = InMemoryLexicon('en', ['the', 'then', 'there', 'they']);
      final decoder = createGestureDecoder(lexicons: InMemoryLexiconSource({'en': lexicon}));
      addTearDown(decoder.dispose);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final result = await decoder.decode(swipeOf(geometry, 'the'));
      expect(result.first.text, 'the');
    });

    test('maxResults is respected', () async {
      final decoder = IsolateGestureDecoder(
        lexicons: InMemoryLexiconSource({'en': fixtureLexicon(fixture.take(5000).toList())}),
      );
      addTearDown(decoder.dispose);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      expect((await decoder.decode(swipeOf(geometry, 'ghost'), maxResults: 2)).length, lessThanOrEqualTo(2));
    });

    test('taps and one-key wobbles decode to nothing', () async {
      final decoder = small(['the', 'a', 'and', 'to', 'in']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final c = geometry.centerOf('g')!;
      expect(await decoder.decode(const GesturePath([])), isEmpty);
      expect(await decoder.decode(GesturePath([TouchPoint(c.dx, c.dy, 0)])), isEmpty);
      // A tap with a little finger drift.
      final wobble = GesturePath([for (var i = 0; i < 6; i++) TouchPoint(c.dx + i * 2.0, c.dy - i * 1.5, i * 10)]);
      expect(await decoder.decode(wobble), isEmpty);
      // Wiggling inside one key.
      final loop = GesturePath([
        for (var i = 0; i < 12; i++) TouchPoint(c.dx + (i.isEven ? 12 : -12), c.dy + (i % 3) * 5.0, i * 10),
      ]);
      expect(await decoder.decode(loop), isEmpty);
    });

    test('decode before prepare returns nothing and does not throw', () async {
      final decoder = small(['the']);
      expect(await decoder.decode(swipeOf(geometry, 'the')), isEmpty);
      expect(await decoder.preview(swipeOf(geometry, 'the')), isNull);
    });

    test('a language without a lexicon is skipped, the others still work', () async {
      final decoder = small(['the', 'then', 'there']);
      await decoder.prepare(geometry: geometry, languages: ['xx', 'en']);
      expect((await decoder.decode(swipeOf(geometry, 'the'))).first.text, 'the');
    });
  });

  group('accents, apostrophes and learned words', () {
    test('accented words are reached through their base letters', () async {
      final decoder = small(['café', 'naïve', 'résumé', 'señor', 'straße', 'the', 'and']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      expect((await decoder.decode(swipeOf(geometry, 'cafe'))).first.text, 'café');
      expect((await decoder.decode(swipeOf(geometry, 'naive'))).first.text, 'naïve');
      expect((await decoder.decode(swipeOf(geometry, 'resume'))).first.text, 'résumé');
      expect((await decoder.decode(swipeOf(geometry, 'senor'))).first.text, 'señor');
      expect((await decoder.decode(swipeOf(geometry, 'strase'))).first.text, 'straße');
    });

    test('apostrophes are ignored on the path: "dont" yields "don\'t"', () async {
      final decoder = small(["don't", "can't", "it's", 'dot', 'font', 'the']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      expect((await decoder.decode(swipeOf(geometry, 'dont'))).first.text, "don't");
      expect((await decoder.decode(swipeOf(geometry, 'cant'))).first.text, "can't");
      expect((await decoder.decode(swipeOf(geometry, 'its'))).first.text, "it's");
    });

    test('repeated letters collapse: "hello" and "helo" share one path', () async {
      final decoder = small(['hello', 'help', 'the']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      expect((await decoder.decode(swipeOf(geometry, 'helo'))).first.text, 'hello');
    });

    test('words with characters that are not on the layout are skipped', () async {
      final decoder = small(['नमस्ते', '東京', 'the', 'then']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      expect(decoder.templateCount, 2);
    });

    test('learned extraWords can be decoded, and are flagged as learned', () async {
      final decoder = small(['the', 'then', 'there', 'hello']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final before = await decoder.decode(swipeOf(geometry, 'booboardboard'));
      expect(before.any((s) => s.text == 'booboardboard'), isFalse);

      await decoder.prepare(
        geometry: geometry,
        languages: ['en'],
        extraWords: const [LexiconEntry('booboardboard', -9), LexiconEntry('xylophone', -9)],
      );
      final after = await decoder.decode(swipeOf(geometry, 'booboardboard'));
      expect(after.first.text, 'booboardboard');
      expect(after.first.isLearned, isTrue);
      expect(after.first.language, isNull);
      expect((await decoder.decode(swipeOf(geometry, 'xylophone'))).first.text, 'xylophone');

      // Forgetting the word removes it again.
      await decoder.prepare(geometry: geometry, languages: ['en']);
      expect((await decoder.decode(swipeOf(geometry, 'booboardboard'))).any((s) => s.text == 'booboardboard'), isFalse);
    });

    test('changing only the learned words does not rebuild the base templates', () async {
      final decoder = small(['the', 'then', 'there', 'hello']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final base = decoder.templateCount;
      await decoder.prepare(geometry: geometry, languages: ['en'], extraWords: const [LexiconEntry('hello', -5)]);
      expect(decoder.templateCount, base + 1);
    });
  });

  group('language model', () {
    test('the bigram with the previous word re-ranks near-identical paths', () async {
      // "tin" and "ton" differ only in i/o: a swipe through the gap is a toss-up.
      final filler = ['the', 'of', 'and', 'to', 'in', 'is', 'it', 'you'];
      final decoder = small(
        [...filler, 'tin', 'ton'],
        counts: [for (var i = 0; i < filler.length; i++) 20000, 100, 100],
        bigrams: {('thin', 'ton'): 100, ('fat', 'tin'): 100},
      );
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final i = geometry.centerOf('i')!, o = geometry.centerOf('o')!;
      final mid = Offset((i.dx + o.dx) / 2, (i.dy + o.dy) / 2);
      final path = pathThrough([geometry.centerOf('t')!, mid, geometry.centerOf('n')!]);
      final afterThin = await decoder.decode(path, previousWords: ['thin']);
      final afterFat = await decoder.decode(path, previousWords: ['fat']);
      expect(afterThin.first.text, 'ton');
      expect(afterFat.first.text, 'tin');
    });

    test('word frequency breaks ties between equally good paths', () async {
      final decoder = small(['ton', 'tin'], counts: [1000, 10]);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final i = geometry.centerOf('i')!, o = geometry.centerOf('o')!;
      final mid = Offset((i.dx + o.dx) / 2, (i.dy + o.dy) / 2);
      final result = await decoder.decode(pathThrough([geometry.centerOf('t')!, mid, geometry.centerOf('n')!]));
      expect(result.first.text, 'ton');
    });
  });

  group('lifecycle', () {
    test('prepare twice with the same arguments is cheap, then dispose', () async {
      final decoder = IsolateGestureDecoder(lexicons: InMemoryLexiconSource({'en': fixtureLexicon(fixture)}));
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final count = decoder.templateCount;
      expect(count, greaterThan(40000));
      final sw = Stopwatch()..start();
      await decoder.prepare(geometry: geometry, languages: ['en']);
      expect(sw.elapsedMilliseconds, lessThan(60), reason: 'cached by geometry key and languages');
      expect(decoder.templateCount, count);
      expect((await decoder.decode(swipeOf(geometry, 'hello'))).first.text, 'hello');

      decoder.dispose();
      expect(decoder.isDisposed, isTrue);
      expect(await decoder.decode(swipeOf(geometry, 'hello')), isEmpty);
      expect(await decoder.preview(swipeOf(geometry, 'hel')), isNull);
      await decoder.prepare(geometry: geometry, languages: ['en']); // no-op, no throw
      decoder.dispose(); // idempotent
    });

    test('concurrent prepares and a decode queued behind them all complete', () async {
      final decoder = small(['the', 'then', 'there', 'hello']);
      final a = decoder.prepare(geometry: geometry, languages: ['en']);
      final b = decoder.prepare(geometry: geometry, languages: ['en']);
      final c = decoder.decode(swipeOf(geometry, 'the'));
      await Future.wait([a, b]);
      expect((await c).first.text, 'the');
    });

    test('a new geometry rebuilds the templates', () async {
      final decoder = small(['the', 'then', 'there', 'hello']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final wide = qwertyGeometry(width: 1440, rowHeight: 200);
      await decoder.prepare(geometry: wide, languages: ['en']);
      expect((await decoder.decode(swipeOf(wide, 'hello'))).first.text, 'hello');
      // The old geometry no longer matches the templates: swiping at the old
      // size must not crash and a back-switch works again.
      await decoder.prepare(geometry: geometry, languages: ['en']);
      expect((await decoder.decode(swipeOf(geometry, 'hello'))).first.text, 'hello');
    });

    test('trimMemory stops the isolate; the next decode rebuilds lazily', () async {
      final decoder = small(['the', 'then', 'there', 'hello']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      expect(decoder.templateCount, greaterThan(0));
      decoder.trimMemory();
      expect(decoder.templateCount, 0);
      final result = await decoder.decode(swipeOf(geometry, 'hello'));
      expect(result.first.text, 'hello');
      expect(decoder.templateCount, greaterThan(0));
    });

    test('dispose while requests are in flight completes them', () async {
      final decoder = IsolateGestureDecoder(lexicons: InMemoryLexiconSource({'en': fixtureLexicon(fixture)}));
      final prepare = decoder.prepare(geometry: geometry, languages: ['en']);
      final decode = decoder.decode(swipeOf(geometry, 'hello'));
      decoder.dispose();
      await prepare;
      expect(await decode, isEmpty);
    });
  });

  group('preview', () {
    test('returns a top-1 word quickly', () async {
      final decoder = IsolateGestureDecoder(lexicons: InMemoryLexiconSource({'en': fixtureLexicon(fixture)}));
      addTearDown(decoder.dispose);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final synth = SwipeSynth(geometry, seed: 4);
      final ms = <double>[];
      var hits = 0;
      final sample = sampleWords(fixture, count: 100, seed: 3);
      for (final w in sample) {
        final path = synth.generate(w)!;
        final sw = Stopwatch()..start();
        final word = await decoder.preview(path);
        ms.add(sw.elapsedMicroseconds / 1000);
        if (word != null && word.toLowerCase() == w) hits++;
      }
      // ignore: avoid_print
      print(
        'preview: p50=${percentile(ms, 0.5).toStringAsFixed(2)} ms p95=${percentile(ms, 0.95).toStringAsFixed(2)} ms '
        'top1 hits=$hits/${sample.length}',
      );
      expect(percentile(ms, 0.95), lessThan(25), reason: 'target is ~10 ms on a phone; desktop is far faster');
      expect(hits, greaterThan(sample.length * 0.6));
      expect(await decoder.preview(const GesturePath([])), isNull);
    });

    test('the latest request wins; superseded ones complete with null', () async {
      final decoder = small(['the', 'then', 'there', 'hello', 'help']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final futures = [for (var i = 0; i < 20; i++) decoder.preview(swipeOf(geometry, i == 19 ? 'hello' : 'the'))];
      final results = await Future.wait(futures);
      expect(results.first, isNotNull);
      expect(results.last, 'hello');
      expect(results.where((r) => r == null).length, greaterThanOrEqualTo(15));
    });

    test('a decode drops a queued preview instead of letting requests pile up', () async {
      final decoder = small(['the', 'then', 'there', 'hello']);
      await decoder.prepare(geometry: geometry, languages: ['en']);
      final first = decoder.preview(swipeOf(geometry, 'the'));
      final queued = decoder.preview(swipeOf(geometry, 'the'));
      final decoded = await decoder.decode(swipeOf(geometry, 'hello'));
      expect(decoded.first.text, 'hello');
      expect(await first, isNotNull);
      expect(await queued, isNull);
    });
  });

  test('keys that are not letters are not part of the swipe layout', () async {
    final keys = Map<String, Rect>.of(geometry.keys)
      ..[','] = const Rect.fromLTWH(0, 460, 100, 140)
      ..['1'] = const Rect.fromLTWH(200, 460, 100, 140);
    final geo = KeyboardGeometry(layoutId: 'with-punct', size: geometry.size, keys: keys);
    final decoder = small(['the', 'then', 'a,b', '1st']);
    await decoder.prepare(geometry: geo, languages: ['en']);
    expect(decoder.templateCount, 2);
  });
}
