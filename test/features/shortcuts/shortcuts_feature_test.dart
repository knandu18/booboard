// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/data_sections.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/features/shortcuts/shortcuts_feature.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/security/shortcuts_store.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../../keyboard/support/app_harness.dart';

/// Captures the session, then attaches the real shortcuts feature to it.
class _Probe extends KeyboardFeature {
  final KeyboardFeature _inner = createShortcutsFeature();
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return _inner.attach(s);
  }

  @override
  void detach() => _inner.detach();
}

SuggestionQuery _query(String composing) =>
    SuggestionQuery(composing: composing, previousWords: const [], field: InputFieldInfo.plainText);

const List<Suggestion> _base = [
  Suggestion('omw', kind: SuggestionKind.typed),
  Suggestion('on', kind: SuggestionKind.prediction),
  Suggestion('oh', kind: SuggestionKind.prediction),
  Suggestion('own', kind: SuggestionKind.prediction),
];

void main() {
  final shortcuts = ShortcutIndex.of(const [PersonalShortcut(trigger: 'omw', expansion: 'on my way')]);

  group('applyShortcut', () {
    test('an exact trigger puts the expansion first, then the two best of the base list', () {
      final out = applyShortcut(_base, 'omw', shortcuts);
      expect([for (final s in out) s.text], ['on my way', 'omw', 'on']);
      expect(out.first.kind, SuggestionKind.completion);
      expect(out.first.display, 'on my way');
    });

    test('matching ignores case', () {
      expect(applyShortcut(_base, 'OMW', shortcuts).first.text, 'on my way');
      expect(applyShortcut(_base, 'Omw', shortcuts).first.text, 'on my way');
    });

    test('anything else returns the base list unchanged', () {
      expect(identical(applyShortcut(_base, 'omg', shortcuts), _base), isTrue);
      expect(identical(applyShortcut(_base, '', shortcuts), _base), isTrue);
      expect(identical(applyShortcut(_base, 'omw', ShortcutIndex.empty), _base), isTrue);
    });

    test('an expansion already in the base list is not shown twice', () {
      final index = ShortcutIndex.of(const [PersonalShortcut(trigger: 'on', expansion: 'on')]);
      final out = applyShortcut(_base, 'on', index);
      expect(out.where((s) => s.text == 'on'), hasLength(1));
    });

    test('the index is case-insensitive on the trigger and keeps the expansion text', () {
      final index = ShortcutIndex.of(const [PersonalShortcut(trigger: 'Addr', expansion: '12 Main St')]);
      expect(index.expansionFor('addr'), '12 Main St');
      expect(index.expansionFor('ADDR'), '12 Main St');
      expect(index.length, 1);
    });
  });

  testWidgets('the registered decorator offers shortcuts, and the setting turns them off', (tester) async {
    final h = AppHarness();
    await h.services.secureStore.write(
      DataBlobs.shortcuts,
      ShortcutsStore.encode(const [PersonalShortcut(trigger: 'omw', expansion: 'on my way')]),
    );
    final probe = _Probe();
    await h.pump(tester, features: [probe]);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await h.focus(tester);

    final session = probe.session!;
    expect(session.input.decorators, hasLength(1));
    final decorate = session.input.decorators.single;
    expect([for (final s in decorate(_base, _query('omw'))) s.text].first, 'on my way');

    await h.store.update(
      (s) => s.copyWith(privacy: s.privacy.copyWith(personalShortcuts: false)),
      sections: const [SettingsSection.privacy],
    );
    expect(identical(decorate(_base, _query('omw')), _base), isTrue);
  });

  testWidgets('detaching removes the decorator from the session', (tester) async {
    final h = AppHarness();
    final probe = _Probe();
    await h.pump(tester, features: [probe]);
    await h.focus(tester);
    expect(probe.session!.input.decorators, hasLength(1));

    probe.detach();
    expect(probe.session!.input.decorators, isEmpty);
  });

  testWidgets('a shortcut edited in the settings app reloads the keyboard copy', (tester) async {
    final h = AppHarness();
    final probe = _Probe();
    await h.pump(tester, features: [probe]);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await h.focus(tester);
    final decorate = probe.session!.input.decorators.single;
    expect(identical(decorate(_base, _query('omw')), _base), isTrue);

    await h.services.secureStore.write(
      DataBlobs.shortcuts,
      ShortcutsStore.encode(const [PersonalShortcut(trigger: 'omw', expansion: 'on my way')]),
    );
    // Listeners registered in the test zone run when the test pumps, so pump after the event.
    await h.events.onSettingsChanged([DataSections.shortcuts]);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
    expect(decorate(_base, _query('omw')).first.text, 'on my way');
  });
}
