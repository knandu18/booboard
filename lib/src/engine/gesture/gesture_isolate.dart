// SPDX-License-Identifier: GPL-3.0-or-later
//
// The long-lived background isolate that owns the word templates.
//
// Protocol (all messages are plain lists keyed by a request id):
//   request:  [type, id, ...payload]
//   response: [id, ok, payload]
// Bulk data (word lists, probabilities, key rects) travels as
// TransferableTypedData so it is moved, not copied.
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'gesture_engine.dart';
import 'template_index.dart';

abstract final class GestureMsg {
  static const int prepare = 0;
  static const int decode = 1;
  static const int preview = 2;
  static const int clear = 3;
}

/// Sent to the isolate as the first message.
class GestureIsolateInit {
  GestureIsolateInit(this.replyTo, this.tuning);

  final SendPort replyTo;
  final GestureTuning tuning;
}

/// Packs a [WordList] for transfer.
List<Object?> packWordList(int language, List<String> words, Float64List logProbs) => [
  language,
  TransferableTypedData.fromList([Uint8List.fromList(utf8.encode(words.join('\n')))]),
  TransferableTypedData.fromList([logProbs]),
];

WordList _unpackWordList(List<Object?> packed) {
  final text = utf8.decode((packed[1] as TransferableTypedData).materialize().asUint8List());
  final lp = (packed[2] as TransferableTypedData).materialize().asFloat64List();
  return WordList(language: packed[0] as int, words: text.isEmpty ? const [] : text.split('\n'), logProbs: lp);
}

void gestureIsolateMain(GestureIsolateInit init) {
  final port = ReceivePort();
  init.replyTo.send(port.sendPort);
  final engine = GestureEngine(tuning: init.tuning);

  port.listen((Object? message) {
    final msg = message as List<Object?>;
    final type = msg[0] as int;
    final id = msg[1] as int;
    try {
      switch (type) {
        case GestureMsg.prepare:
          // [type, id, keysOrNull, baseOrNull, extrasOrNull]
          final keysPacked = msg[2] as List<Object?>?;
          if (keysPacked != null) {
            engine.setKeys(
              GestureKeys(
                chars: List<String>.from(keysPacked[0] as List<Object?>),
                rects: (keysPacked[1] as TransferableTypedData).materialize().asFloat64List(),
                keyWidth: keysPacked[2] as double,
              ),
            );
          }
          final base = msg[3] as List<Object?>?;
          if (base != null) {
            engine.buildBase([for (final l in base) _unpackWordList(l! as List<Object?>)]);
          }
          final extras = msg[4] as List<Object?>?;
          if (extras != null) {
            engine.buildExtras([for (final l in extras) _unpackWordList(l! as List<Object?>)]);
          }
          init.replyTo.send([id, true, engine.templateCount]);
        case GestureMsg.decode:
          // [type, id, Float64List xy, maxResults]
          final result = engine.decode(msg[2] as Float64List, maxResults: msg[3] as int);
          init.replyTo.send([id, true, _packCandidates(result)]);
        case GestureMsg.preview:
          final result = engine.decode(msg[2] as Float64List, preview: true);
          init.replyTo.send([id, true, result.isEmpty ? null : result.first.word]);
        case GestureMsg.clear:
          engine.clear();
          init.replyTo.send([id, true, null]);
      }
    } catch (e) {
      // Never include data in the message: it may be derived from typing.
      init.replyTo.send([id, false, e.runtimeType.toString()]);
    }
  });
}

/// Flat list: word, language, geo, logProb, learned (repeated).
List<Object?> _packCandidates(List<RawCandidate> list) => [
  for (final c in list) ...[c.word, c.language, c.geo, c.logProb, c.learned],
];
