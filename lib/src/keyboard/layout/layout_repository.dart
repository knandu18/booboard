// SPDX-License-Identifier: GPL-3.0-or-later
//
// Loads layout files, caches them, and derives field-aware variants
// (email, URL, number row).
import 'dart:async';
import 'dart:convert';

import 'package:characters/characters.dart';

import '../../core/input_field_info.dart';
import '../../core/log.dart';
import '../../packs/pack_repository.dart';
import '../input/keyboard_page.dart';
import 'layout_model.dart';

/// Popup offered on the ".com" key in email and URL fields.
const List<String> kDomainPopup = [
  '.net',
  '.org',
  '.in',
  '.co.id',
  '.de',
  '.fr',
  '.es',
  '.com.br',
  '.ru',
  '.ua',
  '.jp',
  '.cn',
];

/// Loads `assets/layouts/<id>.json` once and keeps it.
class LayoutRepository {
  LayoutRepository(this._packs);

  final PackRepository _packs;
  final Map<String, KeyboardLayoutDef> _cache = {};
  final Map<String, Future<KeyboardLayoutDef>> _loading = {};

  /// null until [load] finished for [id].
  KeyboardLayoutDef? peek(String id) => _cache[id];

  Future<KeyboardLayoutDef> load(String id) {
    final cached = _cache[id];
    if (cached != null) return Future.value(cached);
    return _loading[id] ??= _loadFresh(id);
  }

  Future<KeyboardLayoutDef> _loadFresh(String id) async {
    try {
      final layout = await KeyboardLayoutDef.load(_packs, id);
      _cache[id] = layout;
      return layout;
    } on Object catch (e) {
      BooBoardLog.w('Layout', 'layout "$id" unreadable, using the built-in one', e.runtimeType);
      final fallback = id == 'qwerty' ? builtInQwerty() : (_cache['qwerty'] ?? builtInQwerty());
      _cache[id] = fallback;
      return fallback;
    } finally {
      unawaited(_loading.remove(id));
    }
  }

  /// Loads every layout the keyboard may need, so page switches never wait.
  Future<void> preload(Iterable<String> ids) async {
    await Future.wait([for (final id in ids) load(id)]);
  }

  /// Minimal compiled-in QWERTY, used only if the asset cannot be read.
  static KeyboardLayoutDef builtInQwerty() {
    KeyDef c(String s) => KeyDef.character(s);
    return KeyboardLayoutDef(
      id: 'qwerty',
      name: 'QWERTY',
      rows: [
        KeyRowDef(keys: [for (final ch in 'qwertyuiop'.split('')) c(ch)]),
        KeyRowDef(padding: 0.5, keys: [for (final ch in 'asdfghjkl'.split('')) c(ch)]),
        KeyRowDef(
          keys: [
            const KeyDef(type: KeyType.shift, width: 1.5),
            for (final ch in 'zxcvbnm'.split('')) c(ch),
            const KeyDef(type: KeyType.backspace, width: 1.5),
          ],
        ),
        const KeyRowDef(
          keys: [
            KeyDef(type: KeyType.symbols, label: '?123', width: 1.5),
            KeyDef(type: KeyType.comma, output: ','),
            KeyDef(type: KeyType.space, width: 5),
            KeyDef(type: KeyType.period, output: '.'),
            KeyDef(type: KeyType.enter, width: 1.5),
          ],
        ),
      ],
    );
  }
}

/// Layout ids for the pages the keyboard can show.
String layoutIdForPage(KeyboardPage page, {required String letters}) => switch (page) {
  KeyboardPage.letters => letters,
  KeyboardPage.symbols => 'symbols',
  KeyboardPage.symbols2 => 'symbols2',
  KeyboardPage.numpad => 'numpad',
  KeyboardPage.phone => 'phone',
  KeyboardPage.datetime => 'datetime',
};

/// All the non-letter layout ids.
const List<String> kAuxiliaryLayoutIds = ['symbols', 'symbols2', 'numpad', 'phone', 'datetime'];

abstract final class LayoutVariants {
  /// Email fields: @ instead of the comma, plus a .com key.
  /// URL fields: / instead of the comma, plus a .com key.
  /// Other preferred pages return [base] unchanged.
  /// [domains] (the active language's country domains) come first in the .com key's popup.
  static KeyboardLayoutDef forField(KeyboardLayoutDef base, PreferredPage page, {List<String> domains = const []}) {
    if (page != PreferredPage.email && page != PreferredPage.url) return base;
    final popup = <String>{
      for (final d in [...domains, ...kDomainPopup])
        if (d != '.com') d,
    }.toList();
    final replacement = page == PreferredPage.email ? '@' : '/';
    final rows = [...base.rows];
    final rowIndex = rows.indexWhere((r) => r.keys.any((k) => k.type == KeyType.space));
    if (rowIndex < 0) return base;
    final row = rows[rowIndex];
    final keys = <KeyDef>[];
    var spaceWidth = 0.0;
    for (final k in row.keys) {
      if (k.type == KeyType.comma) {
        keys.add(KeyDef(type: KeyType.character, output: replacement, width: k.width));
      } else if (k.type == KeyType.space) {
        spaceWidth = k.width;
        keys.add(k);
      } else if (k.type == KeyType.period) {
        keys.add(KeyDef(type: KeyType.character, output: '.com', popup: popup, width: 1.4, id: 'dotcom'));
        keys.add(k);
      } else {
        keys.add(k);
      }
    }
    if (spaceWidth <= 1.4) return base.copyWith(rows: rows..[rowIndex] = row.copyWith(keys: keys));
    // Keep the row total unchanged: the .com key takes its width from the space bar.
    final shrunk = [for (final k in keys) k.type == KeyType.space ? k.copyWith(width: k.width - 1.4) : k];
    rows[rowIndex] = row.copyWith(keys: shrunk);
    return base.copyWith(id: '${base.id}+${page.name}', rows: rows);
  }

  /// Adds a digit row above the letters and drops the digit hints from the top row.
  static KeyboardLayoutDef withNumberRow(KeyboardLayoutDef base) {
    if (base.script != 'Latn' || base.rows.isEmpty) return base;
    final first = base.rows.first;
    final hasDigitHints = first.keys.any((k) => k.hint != null && RegExp(r'^\d$').hasMatch(k.hint!));
    final digits = [for (final d in '1234567890'.split('')) KeyDef(type: KeyType.character, output: d)];
    final top = first.copyWith(
      keys: [for (final k in first.keys) hasDigitHints && k.hint != null ? k.copyWith(clearHint: true) : k],
    );
    return base.copyWith(
      id: '${base.id}+nr',
      rows: [
        KeyRowDef(keys: digits, height: 0.8),
        top,
        ...base.rows.skip(1),
      ],
    );
  }

  /// The key with id 'currency' (symbols page) types [symbol]; '$' moves into its popup.
  static KeyboardLayoutDef withCurrency(KeyboardLayoutDef base, String symbol) {
    var changed = false;
    final rows = [
      for (final r in base.rows)
        r.copyWith(
          keys: [
            for (final k in r.keys)
              if (k.id == 'currency' && k.output != symbol)
                () {
                  changed = true;
                  final popup = [if (k.output != null) k.output!, ...k.popup].where((p) => p != symbol).toList();
                  return k.copyWith(output: symbol, label: symbol, popup: popup);
                }()
              else
                k,
          ],
        ),
    ];
    return changed ? base.copyWith(id: '${base.id}+cur', rows: rows) : base;
  }

  /// Adds a language (globe) key after the ?123 key of the space row; it takes its width from the
  /// space bar. Layouts that already have one are unchanged.
  static KeyboardLayoutDef withLanguageKey(KeyboardLayoutDef base) {
    if (base.rows.any((r) => r.keys.any((k) => k.type == KeyType.globe))) return base;
    final rowIndex = base.rows.indexWhere((r) => r.keys.any((k) => k.type == KeyType.space));
    if (rowIndex < 0) return base;
    final row = base.rows[rowIndex];
    final space = row.keys.firstWhere((k) => k.type == KeyType.space);
    if (space.width < 3) return base;
    final at = row.keys.indexWhere((k) => k.type == KeyType.symbols || k.type == KeyType.alphabet) + 1;
    final keys = [for (final k in row.keys) k.type == KeyType.space ? k.copyWith(width: k.width - 1) : k]
      ..insert(at, const KeyDef(type: KeyType.globe, id: 'language'));
    final rows = [...base.rows]..[rowIndex] = row.copyWith(keys: keys);
    return base.copyWith(id: '${base.id}+lang', rows: rows);
  }

  /// Keys that type an ASCII digit type the native digit from [digits] ('0'..'9' in order) instead;
  /// the ASCII digit moves into the popup. Hints follow.
  static KeyboardLayoutDef withDigits(KeyboardLayoutDef base, String digits) {
    final native = digits.characters.toList();
    if (native.length != 10) return base;
    String? map(String? s) {
      if (s == null || s.length != 1) return s;
      final d = s.codeUnitAt(0) - 0x30;
      return d >= 0 && d <= 9 ? native[d] : s;
    }

    final rows = [
      for (final r in base.rows)
        r.copyWith(
          keys: [
            for (final k in r.keys)
              if (map(k.output) != k.output)
                k.copyWith(output: map(k.output), label: map(k.label ?? k.output), popup: [k.output!, ...k.popup])
              else if (map(k.hint) != k.hint)
                k.copyWith(hint: map(k.hint), popup: [for (final p in k.popup) map(p)!])
              else
                k,
          ],
        ),
    ];
    return base.copyWith(id: '${base.id}+digits', rows: rows);
  }

  /// Decodes a layout JSON string (used by tests).
  static KeyboardLayoutDef parse(String json) => KeyboardLayoutDef.fromJson(jsonDecode(json) as Map<String, Object?>);
}
