// SPDX-License-Identifier: GPL-3.0-or-later
//
// Host performance budgets (Wave 4-D). Run with `flutter test test/perf` (tagged 'perf'; the
// default run includes them). Every test prints a `BENCH` line with median and p95 that goes into
// docs/perf/budgets.md. The asserts are the budgets themselves, measured in the JIT test VM on a
// desktop, so a phone in release mode should do better. A failing assert means a regression to
// investigate, not a number to loosen silently.
//
// Budgets (plan, "Performance budgets"):
//   key tap -> text committed (InputController)  < 30 ms
//   suggest() with 1 and 3 languages              < 8 ms p95
//   swipe decode with 3 languages                  < 40 ms p95
//   keyboard frame while typing                    16 ms on a phone; loose ceiling here
//   memory: RSS deltas after loading dictionaries  a rough guide, printed only (guard: < 512 MB)
@Tags(['perf'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/engine/dictionary/lexicon_factory.dart';
import 'package:booboard/src/engine/gesture/isolate_gesture_decoder.dart';
import 'package:booboard/src/engine/suggest/predictor_factory.dart';
import 'package:booboard/src/keyboard/input/input_controller.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../engine/gesture/gesture_test_support.dart';
import '../keyboard/support/app_harness.dart';
import '../keyboard/support/fakes.dart';
import '../support/fake_editor.dart';

const double kTapBudgetMs = 30;
const double kSuggestBudgetMs = 8;
const double kSwipeBudgetMs = 40;
const double kPhoneFrameMs = 16;
const double kTestFrameCeilingMs = 50;
const int kMemoryGuardMb = 512;

/// Sorted-sample percentile (nearest rank).
double _pct(List<double> sorted, double p) => sorted[math.min(sorted.length - 1, (sorted.length * p).floor())];

({double median, double p95, double max}) _stats(List<double> ms) {
  final sorted = [...ms]..sort();
  return (median: _pct(sorted, 0.5), p95: _pct(sorted, 0.95), max: sorted.last);
}

String _fmt(double v) => v.toStringAsFixed(2);

double _us(Stopwatch sw) => sw.elapsedMicroseconds / 1000;

final _packs = DiskPackRepository();

void main() {
  group('typing latency', () {
    test('key tap -> text committed, real English dictionary', () async {
      final lexicons = createLexiconSource(packs: _packs);
      final predictor = createTextPredictor(packs: _packs, lexicons: lexicons, store: InMemorySecureBlobStore());
      await predictor.setActiveLanguages(['en']);
      final editor = FakeEditor();
      final c = InputController(
        input: editor,
        predictor: predictor,
        gestureDecoder: FakeGestureDecoder(),
        settings: () => const BooBoardSettings(),
      );
      editor.onSelectionChanged = c.onSelectionChanged;
      await c.startInput(InputFieldInfo.plainText);

      const text =
          'the quick brown fox jumps over the lazy dog and then people think about what time it is '
          'because they want to know where the day went ';
      final ms = <double>[];
      final sw = Stopwatch();
      for (var round = 0; round < 10; round++) {
        for (final ch in text.split('')) {
          sw
            ..reset()
            ..start();
          if (ch == ' ') {
            c.onSpace();
          } else {
            c.onText(ch);
          }
          sw.stop();
          ms.add(_us(sw));
          await Future<void>.delayed(Duration.zero);
        }
      }
      final s = _stats(ms);
      debugPrint(
        'BENCH key tap -> commit (en, ${ms.length} keys): median ${_fmt(s.median)} ms, '
        'p95 ${_fmt(s.p95)} ms, max ${_fmt(s.max)} ms (budget $kTapBudgetMs ms)',
      );
      expect(editor.text, isNotEmpty);
      expect(s.p95, lessThan(kTapBudgetMs));
    });

    test('suggest() with 1 and 3 blended languages', () async {
      final lexicons = createLexiconSource(packs: _packs);
      final predictor = createTextPredictor(packs: _packs, lexicons: lexicons, store: InMemorySecureBlobStore());
      const prefixes = ['th', 'wh', 'an', 'pro', 'sch', 'ein', 'ver', 'bon', 'de', 'la', 'ex', 'qu', 'st', 're', 'co'];

      Future<void> measure(String label, List<LanguageId> languages) async {
        await predictor.setActiveLanguages(languages);
        // Warm up the lexicons and the JIT before timing.
        for (final p in prefixes) {
          predictor.suggest(TypingContext(composing: p));
        }
        final ms = <double>[];
        final sw = Stopwatch();
        for (var i = 0; i < 400; i++) {
          final p = prefixes[i % prefixes.length];
          sw
            ..reset()
            ..start();
          predictor.suggest(TypingContext(composing: p));
          sw.stop();
          ms.add(_us(sw));
        }
        final s = _stats(ms);
        debugPrint(
          'BENCH suggest() $label: median ${_fmt(s.median)} ms, p95 ${_fmt(s.p95)} ms, '
          'max ${_fmt(s.max)} ms (budget p95 $kSuggestBudgetMs ms)',
        );
        expect(s.p95, lessThan(kSuggestBudgetMs), reason: label);
      }

      await measure('1 language (en)', ['en']);
      await measure('3 languages (en, de, fr)', ['en', 'de', 'fr']);
    });
  });

  test('swipe decode with 3 languages', () async {
    final lexicons = createLexiconSource(packs: _packs);
    final decoder = IsolateGestureDecoder(lexicons: lexicons);
    final geometry = qwertyGeometry();
    await decoder.prepare(geometry: geometry, languages: ['en', 'de', 'fr']);
    final synth = SwipeSynth(geometry);
    const words = ['the', 'and', 'hello', 'people', 'because', 'think', 'through', 'where', 'about', 'their'];
    final paths = [for (final w in words) synth.generate(w)].whereType<GesturePath>().toList();
    expect(paths.length, words.length);

    // Warm up the isolate and the template index.
    for (final p in paths.take(3)) {
      await decoder.decode(p);
    }
    final ms = <double>[];
    final sw = Stopwatch();
    for (var round = 0; round < 6; round++) {
      for (final p in paths) {
        sw
          ..reset()
          ..start();
        await decoder.decode(p);
        sw.stop();
        ms.add(_us(sw));
      }
    }
    // Sanity: the timed decodes must be real decodes, so count how many come back as the intended word.
    var top1 = 0;
    for (var i = 0; i < paths.length; i++) {
      final r = await decoder.decode(paths[i]);
      if (r.isNotEmpty && r.first.text == words[i]) top1++;
    }
    decoder.dispose();
    debugPrint('BENCH swipe decode top-1 on synthetic swipes: $top1 of ${words.length}');
    expect(top1, greaterThan(words.length ~/ 2));
    final s = _stats(ms);
    debugPrint(
      'BENCH swipe decode (en, de, fr; ${ms.length} swipes incl. isolate hop): median ${_fmt(s.median)} ms, '
      'p95 ${_fmt(s.p95)} ms, max ${_fmt(s.max)} ms (budget p95 $kSwipeBudgetMs ms)',
    );
    expect(s.p95, lessThan(kSwipeBudgetMs));
  });

  testWidgets('keyboard frame build time while typing', (tester) async {
    final h = AppHarness();
    await h.pump(tester);
    await h.focus(tester);
    final k = KeyFinder(tester, loadLayoutSync('qwerty'));
    const text = 'the quick brown fox jumps over the lazy dog';
    final ms = <double>[];
    final sw = Stopwatch();
    for (final ch in text.split('')) {
      if (ch == ' ') {
        await tester.tapAt(k.type(KeyType.space));
      } else {
        await tester.tapAt(k.output(ch));
      }
      sw
        ..reset()
        ..start();
      await tester.pump(const Duration(milliseconds: 16));
      sw.stop();
      ms.add(_us(sw));
    }
    final s = _stats(ms);
    debugPrint(
      'BENCH keyboard frame (JIT test VM, ${ms.length} frames while typing): median ${_fmt(s.median)} ms, '
      'p95 ${_fmt(s.p95)} ms, max ${_fmt(s.max)} ms (phone budget $kPhoneFrameMs ms; test ceiling '
      '$kTestFrameCeilingMs ms)',
    );
    expect(h.editor.text, isNotEmpty);
    expect(s.p95, lessThan(kTestFrameCeilingMs));
  });

  test('memory: RSS deltas after loading dictionaries (rough guide)', () async {
    double rssMb() => ProcessInfo.currentRss / (1024 * 1024);
    final kept = <Object>[];
    // Each step adds to the previous ones, so each delta is the incremental cost of that step.
    Future<void> load(String label, List<LanguageId> langs, {bool translit = false}) async {
      final before = rssMb();
      final source = createLexiconSource(packs: _packs, maxLoaded: 8);
      for (final l in langs) {
        kept.add(await source.load(l));
      }
      if (translit) kept.add(await _packs.load('translit/hi.bin'));
      final after = rssMb();
      debugPrint('BENCH RSS after $label: +${_fmt(after - before)} MB (now ${_fmt(after)} MB)');
      expect(after - before, lessThan(kMemoryGuardMb));
    }

    await load('en', ['en']);
    await load('+ de + hi (so en + de + hi)', ['de', 'hi']);
    await load('+ Indic transliteration hi.bin', [], translit: true);
    expect(kept, isNotEmpty);
  });
}
