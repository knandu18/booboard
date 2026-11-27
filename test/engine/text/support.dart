// SPDX-License-Identifier: GPL-3.0-or-later
//
// Shared helpers for the text engine tests.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/packs/pack_repository.dart';

/// Reads packs straight from the `assets/` folder (tests run from the project root).
class FilePackRepository implements PackRepository {
  @override
  Future<ByteData> load(String path) async => ByteData.sublistView(File('assets/$path').readAsBytesSync());

  @override
  Future<String> loadString(String path) async => File('assets/$path').readAsStringSync();

  @override
  Future<bool> exists(String path) async => File('assets/$path').existsSync();
}

/// A phone-sized QWERTY: 36 x 48 dp keys with 2 dp gaps.
KeyboardGeometry qwertyGeometry() {
  const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
  const offsets = [0.0, 0.5, 1.5];
  const w = 36.0;
  const h = 48.0;
  final keys = <String, Rect>{};
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      keys[rows[r][c]] = Rect.fromLTWH((offsets[r] + c) * w + 1, r * h + 2, w - 2, h - 4);
    }
  }
  return KeyboardGeometry(layoutId: 'test-qwerty', size: const Size(360, 3 * h), keys: keys);
}

/// Taps at the centre of each letter of [word], optionally nudged per index.
/// Characters without a key (apostrophes, digits) get a tap without a point.
List<KeyTap> centreTaps(KeyboardGeometry geometry, String word, {Map<int, Offset> nudge = const {}}) {
  return [
    for (var i = 0; i < word.length; i++)
      () {
        final rect = geometry.keys[word[i].toLowerCase()];
        if (rect == null) return KeyTap(word[i]);
        final p = rect.center + (nudge[i] ?? Offset.zero);
        return KeyTap(word[i], TouchPoint(p.dx, p.dy, i * 100));
      }(),
  ];
}

TypingContext typing(
  String composing, {
  List<KeyTap> taps = const [],
  List<String> previous = const [],
  bool startOfSentence = false,
  InputFieldInfo field = InputFieldInfo.plainText,
}) => TypingContext(
  composing: composing,
  taps: taps,
  previousWords: previous,
  isStartOfSentence: startOfSentence,
  field: field,
);
