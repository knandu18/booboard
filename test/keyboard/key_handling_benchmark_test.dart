// SPDX-License-Identifier: GPL-3.0-or-later
//
// Benchmark-style tests: they print timings (run `flutter test -r expanded
// test/keyboard/key_handling_benchmark_test.dart` to see them) and assert
// generous ceilings, far below the 30 ms "tap to text committed" budget.
// These run in the Dart VM in JIT mode, so a phone in release mode is faster.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/in_memory_lexicon.dart';
import 'package:booboard/src/engine/suggest/predictor_factory.dart';
import 'package:booboard/src/keyboard/input/input_controller.dart';
import 'package:booboard/src/keyboard/layout/layout_engine.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/engine/language_rules.dart';
import 'package:booboard/src/packs/pack_repository.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import 'dart:ui';

import '../support/fake_editor.dart';
import 'support/app_harness.dart';
import 'support/fakes.dart';

double _p95(List<int> micros) {
  final sorted = [...micros]..sort();
  return sorted[(sorted.length * 0.95).floor()] / 1000;
}

void main() {
  test('InputController: key handling time with the real predictor stub', () async {
    final lexicons = InMemoryLexiconSource({'en': InMemoryLexicon('en', kStarterEnglishWords)});
    final predictor = createTextPredictor(
      packs: BundledPackRepository(),
      lexicons: lexicons,
      store: InMemorySecureBlobStore(),
    );
    await predictor.setActiveLanguages(['en']);
    final editor = FakeEditor();
    const settings = BooBoardSettings();
    final c = InputController(
      input: editor,
      predictor: predictor,
      gestureDecoder: FakeGestureDecoder(),
      settings: () => settings,
      rulesFor: languageRulesFor,
    );
    editor.onSelectionChanged = c.onSelectionChanged;
    await c.startInput(InputFieldInfo.plainText);

    const text = 'the quick brown fox jumps over the lazy dog and then people think about what time it is ';
    final micros = <int>[];
    final sw = Stopwatch();
    for (var round = 0; round < 25; round++) {
      for (final ch in text.split('')) {
        sw.reset();
        sw.start();
        if (ch == ' ') {
          c.onSpace();
        } else {
          c.onText(ch);
        }
        sw.stop();
        micros.add(sw.elapsedMicroseconds);
        await Future<void>.delayed(Duration.zero);
      }
    }
    final avg = micros.reduce((a, b) => a + b) / micros.length / 1000;
    final p95 = _p95(micros);
    debugPrint(
      'BENCH InputController key handling: ${micros.length} keys, avg ${avg.toStringAsFixed(3)} ms, '
      'p95 ${p95.toStringAsFixed(3)} ms',
    );
    expect(avg, lessThan(3));
    expect(p95, lessThan(10));
  });

  test('Layout engine and hit-testing speed', () {
    final qwerty = loadLayoutSync('qwerty');
    final sw = Stopwatch()..start();
    late LaidOutKeyboard laid;
    for (var i = 0; i < 200; i++) {
      laid = KeyboardLayoutEngine.layout(qwerty, Size(360.0 + i % 3, 224), keyGap: 6);
    }
    final layoutMs = sw.elapsedMicroseconds / 200 / 1000;
    sw
      ..reset()
      ..start();
    var hits = 0;
    for (var i = 0; i < 20000; i++) {
      if (laid.hitTest(Offset((i * 7) % 360, (i * 13) % 224.0)) != null) hits++;
    }
    final hitUs = sw.elapsedMicroseconds / 20000;
    final geoSw = Stopwatch()..start();
    for (var i = 0; i < 200; i++) {
      laid.toGeometry();
    }
    final geoMs = geoSw.elapsedMicroseconds / 200 / 1000;
    debugPrint(
      'BENCH layout ${layoutMs.toStringAsFixed(3)} ms, hit-test ${hitUs.toStringAsFixed(2)} us, '
      'geometry ${geoMs.toStringAsFixed(3)} ms',
    );
    expect(hits, 20000);
    expect(layoutMs, lessThan(2));
    expect(hitUs, lessThan(50));
  });

  testWidgets('Tap handling through the full widget tree (pointer events to text committed)', (tester) async {
    final h = AppHarness();
    await h.pump(tester);
    await h.focus(tester);
    final k = KeyFinder(tester, loadLayoutSync('qwerty'));
    final keys = 'abcdefghijklmnopqrstuvwxyz'.split('');
    final points = {for (final ch in keys) ch: k.output(ch)};
    final micros = <int>[];
    final sw = Stopwatch();
    for (var i = 0; i < 200; i++) {
      final p = points[keys[i % keys.length]]!;
      sw
        ..reset()
        ..start();
      await tester.tapAt(p);
      sw.stop();
      micros.add(sw.elapsedMicroseconds);
      await tester.pump(const Duration(milliseconds: 16));
    }
    final avg = micros.reduce((a, b) => a + b) / micros.length / 1000;
    debugPrint(
      'BENCH tap (down+up dispatch, JIT test VM): avg ${avg.toStringAsFixed(3)} ms, '
      'p95 ${_p95(micros).toStringAsFixed(3)} ms',
    );
    expect(h.editor.text.length, 200);
    expect(avg, lessThan(10));
  });
}
