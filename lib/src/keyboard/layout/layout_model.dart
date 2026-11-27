// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0) for the layout JSON format; implementation owned by
// Wave 1-A. New fields must be optional so existing layout files keep working.
//
// JSON format (assets/layouts/<id>.json):
// {
//   "id": "qwerty", "name": "QWERTY", "script": "Latn", "direction": "ltr",
//   "rows": [
//     {"keys": ["q", "w", {"output": "e", "popup": ["é","è","ê","ë"], "hint": "3"}, ...]},
//     {"padding": 0.5, "keys": [...]},
//     {"keys": [{"type": "shift", "width": 1.5}, "z", ..., {"type": "backspace", "width": 1.5}]},
//     {"keys": [{"type": "symbols", "width": 1.5}, {"type": "comma"}, {"type": "space", "width": 5},
//               {"type": "period"}, {"type": "enter", "width": 1.5}]}
//   ]
// }
// A bare string is a character key whose output is that string.
// "flick": {"up": "...", "down": "...", "left": "...", "right": "..."} for 12-key layouts.
import 'dart:convert';

import 'package:flutter/painting.dart' show TextDirection;
import 'package:meta/meta.dart';

import '../../packs/pack_repository.dart';

enum KeyType {
  character,
  shift,
  backspace,
  enter,
  space,

  /// Switch to the first symbols page.
  symbols,

  /// Switch to the second symbols page.
  moreSymbols,

  /// Back to letters.
  alphabet,
  numbers,
  globe,
  emoji,
  voice,
  clipboard,
  settings,
  comma,
  period,
  tab,
  cursorLeft,
  cursorRight,

  /// Behaviour defined by [KeyDef.code].
  custom,
}

@immutable
class KeyDef {
  const KeyDef({
    required this.type,
    this.output,
    this.label,
    this.shiftedOutput,
    this.shiftedLabel,
    this.hint,
    this.popup = const [],
    this.width = 1.0,
    this.flick,
    this.code,
    this.id,
    this.spoken,
  });

  factory KeyDef.character(String output) => KeyDef(type: KeyType.character, output: output);

  factory KeyDef.fromJson(Object json) {
    if (json is String) return KeyDef.character(json);
    final map = json as Map<String, Object?>;
    final typeName = map['type'] as String? ?? 'character';
    final type = KeyType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => throw FormatException('Unknown key type "$typeName"'),
    );
    return KeyDef(
      type: type,
      output: map['output'] as String?,
      label: map['label'] as String?,
      shiftedOutput: map['shiftedOutput'] as String?,
      shiftedLabel: map['shiftedLabel'] as String?,
      hint: map['hint'] as String?,
      popup: (map['popup'] as List<Object?>?)?.cast<String>() ?? const [],
      width: (map['width'] as num?)?.toDouble() ?? 1.0,
      flick: (map['flick'] as Map<String, Object?>?)?.map((k, v) => MapEntry(k, v! as String)),
      code: map['code'] as String?,
      id: map['id'] as String?,
      spoken: map['spoken'] as String?,
    );
  }

  final KeyType type;

  /// Text committed by a character key.
  final String? output;

  /// Label shown; defaults to [output].
  final String? label;
  final String? shiftedOutput;
  final String? shiftedLabel;

  /// Small corner label (e.g. digit on the top row).
  final String? hint;

  /// Long-press alternatives.
  final List<String> popup;

  /// Width in key units (1.0 = a standard letter key).
  final double width;

  /// 12-key flick outputs by direction: up/down/left/right.
  final Map<String, String>? flick;

  /// For [KeyType.custom].
  final String? code;
  final String? id;

  /// What TalkBack says for the key, in English (Wave 4; "Dakuten and small kana"). Defaults to
  /// the output or label.
  final String? spoken;

  bool get isCharacter => type == KeyType.character;

  /// Copy with some fields replaced (Wave 1-A helper; does not change the JSON format).
  KeyDef copyWith({
    KeyType? type,
    String? output,
    String? label,
    String? shiftedOutput,
    String? shiftedLabel,
    String? hint,
    bool clearHint = false,
    List<String>? popup,
    double? width,
    Map<String, String>? flick,
    String? code,
    String? id,
    String? spoken,
  }) => KeyDef(
    type: type ?? this.type,
    output: output ?? this.output,
    label: label ?? this.label,
    shiftedOutput: shiftedOutput ?? this.shiftedOutput,
    shiftedLabel: shiftedLabel ?? this.shiftedLabel,
    hint: clearHint ? null : (hint ?? this.hint),
    popup: popup ?? this.popup,
    width: width ?? this.width,
    flick: flick ?? this.flick,
    code: code ?? this.code,
    id: id ?? this.id,
    spoken: spoken ?? this.spoken,
  );

  String? outputFor({required bool shifted}) {
    if (!shifted) return output;
    return shiftedOutput ?? output?.toUpperCase();
  }

  String? labelFor({required bool shifted}) {
    if (!shifted) return label ?? output;
    return shiftedLabel ?? shiftedOutput ?? (label ?? output)?.toUpperCase();
  }
}

@immutable
class KeyRowDef {
  const KeyRowDef({required this.keys, this.height = 1.0, this.padding = 0.0});

  factory KeyRowDef.fromJson(Map<String, Object?> json) => KeyRowDef(
    keys: [for (final k in json['keys']! as List<Object?>) KeyDef.fromJson(k!)],
    height: (json['height'] as num?)?.toDouble() ?? 1.0,
    padding: (json['padding'] as num?)?.toDouble() ?? 0.0,
  );

  final List<KeyDef> keys;

  /// Relative row height (1.0 = standard).
  final double height;

  /// Empty space (key units) before the first and after the last key.
  final double padding;

  double get totalUnits => keys.fold<double>(0, (sum, k) => sum + k.width) + padding * 2;

  KeyRowDef copyWith({List<KeyDef>? keys, double? height, double? padding}) =>
      KeyRowDef(keys: keys ?? this.keys, height: height ?? this.height, padding: padding ?? this.padding);
}

@immutable
class KeyboardLayoutDef {
  const KeyboardLayoutDef({
    required this.id,
    required this.name,
    required this.rows,
    this.script = 'Latn',
    this.direction = TextDirection.ltr,
  });

  factory KeyboardLayoutDef.fromJson(Map<String, Object?> json) => KeyboardLayoutDef(
    id: json['id']! as String,
    name: json['name'] as String? ?? json['id']! as String,
    script: json['script'] as String? ?? 'Latn',
    direction: json['direction'] == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
    rows: [for (final r in json['rows']! as List<Object?>) KeyRowDef.fromJson(r! as Map<String, Object?>)],
  );

  static Future<KeyboardLayoutDef> load(PackRepository packs, String id) async {
    final text = await packs.loadString('layouts/$id.json');
    return KeyboardLayoutDef.fromJson(jsonDecode(text) as Map<String, Object?>);
  }

  final String id;
  final String name;

  /// ISO 15924 script code (Latn, Cyrl, Deva, Beng, Taml, Telu, Arab, Hani, Jpan).
  final String script;
  final TextDirection direction;
  final List<KeyRowDef> rows;

  Iterable<KeyDef> get keys => rows.expand((r) => r.keys);

  KeyboardLayoutDef copyWith({
    String? id,
    String? name,
    List<KeyRowDef>? rows,
    String? script,
    TextDirection? direction,
  }) => KeyboardLayoutDef(
    id: id ?? this.id,
    name: name ?? this.name,
    rows: rows ?? this.rows,
    script: script ?? this.script,
    direction: direction ?? this.direction,
  );
}
