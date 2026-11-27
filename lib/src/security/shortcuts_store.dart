// SPDX-License-Identifier: GPL-3.0-or-later
//
// Personal shortcuts ("omw" -> "on my way"). Stored only through SecureBlobStore as JSON
// `[{"trigger": "omw", "expansion": "on my way"}]`. Triggers are unique case-insensitively.
//
// PRIVACY: shortcuts are typed by the user, so they are encrypted like learned words. Nothing here
// is logged.
import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../core/data_sections.dart';
import '../core/secure_blob_store.dart';

@immutable
class PersonalShortcut {
  const PersonalShortcut({required this.trigger, required this.expansion});

  final String trigger;
  final String expansion;

  Map<String, Object?> toJson() => {'trigger': trigger, 'expansion': expansion};

  @override
  bool operator ==(Object other) =>
      other is PersonalShortcut && other.trigger == trigger && other.expansion == expansion;

  @override
  int get hashCode => Object.hash(trigger, expansion);

  @override
  String toString() => 'PersonalShortcut(${trigger.length} chars)';
}

/// Why a shortcut was refused. The UI maps each value to a message.
enum ShortcutProblem {
  emptyTrigger,
  triggerTooLong,
  triggerCharacters,
  emptyExpansion,
  expansionTooLong,
  duplicateTrigger,
  tooManyShortcuts,
}

abstract final class ShortcutRules {
  static const int maxShortcuts = 500;
  static const int maxTriggerLength = 32;
  static const int maxExpansionLength = 500;

  /// Letters, combining marks (Indic vowel signs and viramas), digits and apostrophes (straight or
  /// curly), in any script.
  static final RegExp _triggerCharacters = RegExp(r"^[\p{L}\p{M}\p{N}'’]+$", unicode: true);

  /// Lengths count code points, which is what the keyboard's composing text is made of.
  static ShortcutProblem? checkTrigger(String trigger) {
    final t = trigger.trim();
    if (t.isEmpty) return ShortcutProblem.emptyTrigger;
    if (t.runes.length > maxTriggerLength) return ShortcutProblem.triggerTooLong;
    if (!_triggerCharacters.hasMatch(t)) return ShortcutProblem.triggerCharacters;
    return null;
  }

  static ShortcutProblem? checkExpansion(String expansion) {
    final e = expansion.trim();
    if (e.isEmpty) return ShortcutProblem.emptyExpansion;
    if (e.runes.length > maxExpansionLength) return ShortcutProblem.expansionTooLong;
    return null;
  }

  static String normalizeTrigger(String trigger) => trigger.trim();

  static String normalizeExpansion(String expansion) => expansion.trim();
}

/// Persists the shortcut list. Writes are serialized; every call re-validates its input.
class ShortcutsStore {
  ShortcutsStore(this._store);

  final SecureBlobStore _store;
  List<PersonalShortcut>? _cache;
  Future<void> _chain = Future.value();

  /// Shortcuts in the order they were added.
  Future<List<PersonalShortcut>> list() async => List.unmodifiable(await _load());

  Future<ShortcutProblem?> add(String trigger, String expansion) => _serial(() async {
    final current = await _load();
    final problem = _check(current, trigger, expansion, exceptIndex: -1);
    if (problem != null) return problem;
    final next = [
      ...current,
      PersonalShortcut(
        trigger: ShortcutRules.normalizeTrigger(trigger),
        expansion: ShortcutRules.normalizeExpansion(expansion),
      ),
    ];
    await _save(next);
    return null;
  });

  /// Replaces the shortcut whose trigger is [oldTrigger] (case-insensitive).
  Future<ShortcutProblem?> update(String oldTrigger, String trigger, String expansion) => _serial(() async {
    final current = await _load();
    final index = _indexOf(current, oldTrigger);
    if (index < 0) return null;
    final problem = _check(current, trigger, expansion, exceptIndex: index);
    if (problem != null) return problem;
    final next = [...current]
      ..[index] = PersonalShortcut(
        trigger: ShortcutRules.normalizeTrigger(trigger),
        expansion: ShortcutRules.normalizeExpansion(expansion),
      );
    await _save(next);
    return null;
  });

  Future<void> remove(String trigger) => _serial(() async {
    final current = await _load();
    final index = _indexOf(current, trigger);
    if (index < 0) return;
    await _save([...current]..removeAt(index));
  });

  /// Replaces the whole list (used by restore). Input must already be valid.
  Future<void> replaceAll(List<PersonalShortcut> shortcuts) => _serial(() => _save(List.of(shortcuts)));

  /// Deletes the stored list.
  Future<void> clear() => _serial(() async {
    _cache = const [];
    await _store.delete(DataBlobs.shortcuts);
  });

  /// Forgets the in-memory copy, after another engine changed the blob.
  void invalidate() => _cache = null;

  Future<List<PersonalShortcut>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final loaded = decode(await _store.read(DataBlobs.shortcuts));
    _cache = loaded;
    return loaded;
  }

  Future<void> _save(List<PersonalShortcut> shortcuts) async {
    await _store.write(DataBlobs.shortcuts, encode(shortcuts));
    _cache = List.unmodifiable(shortcuts);
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final run = _chain.then((_) => action());
    _chain = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  static int _indexOf(List<PersonalShortcut> list, String trigger) {
    final key = trigger.trim().toLowerCase();
    return list.indexWhere((s) => s.trigger.toLowerCase() == key);
  }

  static ShortcutProblem? _check(
    List<PersonalShortcut> current,
    String trigger,
    String expansion, {
    required int exceptIndex,
  }) {
    final triggerProblem = ShortcutRules.checkTrigger(trigger);
    if (triggerProblem != null) return triggerProblem;
    final expansionProblem = ShortcutRules.checkExpansion(expansion);
    if (expansionProblem != null) return expansionProblem;
    final index = _indexOf(current, trigger);
    if (index >= 0 && index != exceptIndex) return ShortcutProblem.duplicateTrigger;
    if (exceptIndex < 0 && current.length >= ShortcutRules.maxShortcuts) return ShortcutProblem.tooManyShortcuts;
    return null;
  }

  /// Decodes stored bytes. Corrupt or invalid entries are dropped, never fatal.
  static List<PersonalShortcut> decode(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return const [];
    final out = <PersonalShortcut>[];
    final seen = <String>{};
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! List) return const [];
      for (final item in json) {
        if (item is! Map) continue;
        final trigger = item['trigger'];
        final expansion = item['expansion'];
        if (trigger is! String || expansion is! String) continue;
        if (ShortcutRules.checkTrigger(trigger) != null) continue;
        if (ShortcutRules.checkExpansion(expansion) != null) continue;
        if (!seen.add(trigger.trim().toLowerCase())) continue;
        out.add(PersonalShortcut(trigger: trigger.trim(), expansion: expansion.trim()));
        if (out.length == ShortcutRules.maxShortcuts) break;
      }
    } on Object {
      return const [];
    }
    return out;
  }

  static Uint8List encode(List<PersonalShortcut> shortcuts) =>
      Uint8List.fromList(utf8.encode(jsonEncode([for (final s in shortcuts) s.toJson()])));
}
