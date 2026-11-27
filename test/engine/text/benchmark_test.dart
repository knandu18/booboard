// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/engine/dictionary/lexicon_factory.dart';
import 'package:booboard/src/engine/suggest/text_predictor.dart';

import 'support.dart';

void main() {
  test('suggest() latency with the full English dictionary', () async {
    final geometry = qwertyGeometry();
    final predictor = BooBoardTextPredictor(
      lexicons: createLexiconSource(packs: FilePackRepository()),
      store: InMemorySecureBlobStore(),
    );
    await predictor.setActiveLanguages(['en']);
    predictor.setGeometry(geometry);

    // Every prefix of realistic words, typed correctly and with typos.
    const words = [
      'hello',
      'thanks',
      'tomorrow',
      'wednesday',
      'beautiful',
      'everything',
      'because',
      'recieve',
      'adress',
      'teh',
      'helo',
      'thnaks',
      'definately',
      'seperate',
      'restaurant',
      'international',
      'understanding',
      'kaun',
      'whatsapp',
      'meeting',
      'tonight',
      'weekend',
      'important',
      'something',
      'wonderful',
      'unfortunately',
      'appointment',
    ];
    final contexts = <List<String>>[
      const [],
      const ['thank'],
      const ['i', 'will'],
    ];
    final inputs = <(String, List<String>)>[];
    for (final w in words) {
      for (var n = 1; n <= w.length; n++) {
        for (final c in contexts) {
          inputs.add((w.substring(0, n), c));
        }
      }
    }

    // Warm-up for the JIT.
    for (var i = 0; i < 300; i++) {
      final (w, c) = inputs[i % inputs.length];
      predictor.suggest(typing(w, taps: centreTaps(geometry, w), previous: c));
    }

    final micros = <int>[];
    final stopwatch = Stopwatch();
    for (final (w, c) in inputs) {
      final context = typing(w, taps: centreTaps(geometry, w), previous: c);
      stopwatch
        ..reset()
        ..start();
      predictor.suggest(context);
      stopwatch.stop();
      micros.add(stopwatch.elapsedMicroseconds);
    }
    micros.sort();
    double ms(double q) => micros[((micros.length - 1) * q).round()] / 1000;
    // ignore: avoid_print
    print(
      'suggest(): ${micros.length} calls, p50 ${ms(0.5).toStringAsFixed(2)} ms, '
      'p95 ${ms(0.95).toStringAsFixed(2)} ms, p99 ${ms(0.99).toStringAsFixed(2)} ms, '
      'max ${(micros.last / 1000).toStringAsFixed(2)} ms',
    );
    // The desktop target is 3 ms p95 (8 ms on phones).
    expect(ms(0.95), lessThan(3));
  });
}
