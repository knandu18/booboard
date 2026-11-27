// SPDX-License-Identifier: GPL-3.0-or-later
//
// Personal shortcuts ("omw" -> "on my way") in the suggestion strip. keyboard_main.dart calls
// createShortcutsFeature(); keep that signature.
//
// When the composing word equals a trigger (case-insensitive), the expansion goes first and the
// predictor's best words follow. Multi-word expansions are never learned (the input controller
// already handles that). PRIVACY: shortcut text is never logged.
import 'dart:async';

import '../../core/data_sections.dart';
import '../../core/log.dart';
import '../../engine/contracts.dart';
import '../../keyboard/keyboard_app.dart';
import '../../keyboard/keyboard_session.dart';
import '../../security/shortcuts_store.dart';

KeyboardFeature createShortcutsFeature() => _ShortcutsFeature();

/// Lookup table from the lower-cased trigger to its expansion. A map read per key press.
class ShortcutIndex {
  const ShortcutIndex._(this._byTrigger);

  factory ShortcutIndex.of(List<PersonalShortcut> shortcuts) =>
      ShortcutIndex._({for (final s in shortcuts) s.trigger.toLowerCase(): s.expansion});

  static const ShortcutIndex empty = ShortcutIndex._({});

  final Map<String, String> _byTrigger;

  int get length => _byTrigger.length;

  /// The expansion for a composing word, or null when it is not a trigger.
  String? expansionFor(String composing) => composing.isEmpty ? null : _byTrigger[composing.toLowerCase()];
}

/// Puts [index]'s expansion first when [composing] is a trigger, then the best of [base].
List<Suggestion> applyShortcut(List<Suggestion> base, String composing, ShortcutIndex index) {
  final expansion = index.expansionFor(composing);
  if (expansion == null) return base;
  return [
    Suggestion(expansion, kind: SuggestionKind.completion, display: expansion),
    ...base.where((s) => s.text != expansion).take(2),
  ];
}

class _ShortcutsFeature extends KeyboardFeature {
  KeyboardSession? _session;
  StreamSubscription<List<String>>? _changes;
  ShortcutIndex _index = ShortcutIndex.empty;

  @override
  KeyboardHooks attach(KeyboardSession session) {
    _session = session;
    final store = ShortcutsStore(session.services.secureStore);
    session.input.decorators.add(_decorate);
    _changes = session.services.events.settingsChanged.listen((sections) {
      if (DataSections.affects(sections, DataSections.shortcuts)) unawaited(_reload(store));
    });
    unawaited(_reload(store));
    return const KeyboardHooks();
  }

  @override
  void detach() {
    unawaited(_changes?.cancel());
    _changes = null;
    _session?.input.decorators.remove(_decorate);
    _session = null;
  }

  Future<void> _reload(ShortcutsStore store) async {
    try {
      store.invalidate();
      _index = ShortcutIndex.of(await store.list());
    } on Object catch (e) {
      BooBoardLog.w('Shortcuts', 'load failed', e.runtimeType);
    }
  }

  List<Suggestion> _decorate(List<Suggestion> base, SuggestionQuery query) {
    if (_index.length == 0) return base;
    final session = _session;
    if (session == null || !session.services.settings.value.privacy.personalShortcuts) return base;
    return applyShortcut(base, query.composing, _index);
  }
}
