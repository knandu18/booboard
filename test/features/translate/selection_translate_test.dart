// SPDX-License-Identifier: GPL-3.0-or-later
//
// Translate for selected text: the strip chip, Replace, Insert after, and the field rules.
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/features/translate/selection_translate.dart';
import 'package:booboard/src/features/translate/translate_feature.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../../keyboard/support/app_harness.dart';

class _Probe extends KeyboardFeature {
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return const KeyboardHooks();
  }
}

BooBoardSettings _settings({bool enabled = true}) => BooBoardSettings(
  typing: const TypingSettings(nextWordPrediction: false),
  translate: TranslateSettings(enabled: enabled, from: 'en', to: 'es'),
);

Future<(AppHarness, _Probe)> boot(
  WidgetTester tester, {
  String text = 'hello world',
  BooBoardSettings? settings,
  EditorInfoMessage? field,
  bool packInstalled = true,
}) async {
  final h = AppHarness(settings: settings ?? _settings(), text: text);
  when(() => h.platform.listPacks()).thenAnswer(
    (_) async => [
      if (packInstalled)
        PackInfoMessage(
          id: 'translate-en-es',
          kind: PackKind.translation,
          name: 'English → Spanish',
          version: 1,
          languages: const ['en', 'es'],
          sizeBytes: 100,
          engine: 'opus-mt-onnx',
          license: 'Apache-2.0',
        ),
    ],
  );
  final probe = _Probe();
  await h.pump(tester, features: [probe, createTranslateFeature()]);
  await h.focus(tester, field);
  return (h, probe);
}

/// Selects [start]..[end] in the fake editor, as the app would.
Future<void> select(AppHarness h, int start, int end) async {
  await h.editor.setSelection(start, end);
}

bool hasChip(KeyboardSession session, String id) => session.stripChips.value.any((c) => c.id == id);

Future<void> runChip(WidgetTester tester, KeyboardSession session, String id) async {
  final chip = session.stripChips.value.firstWhere((c) => c.id == id);
  chip.onTap();
  await tester.pump();
  await tester.pump();
}

void main() {
  group('translate selection', () {
    testWidgets('no translation pack installed: no Translate chip, so Select all keeps its slot', (tester) async {
      final (h, probe) = await boot(tester, packInstalled: false);
      await select(h, 0, 5);
      await tester.pump();
      expect(hasChip(probe.session!, translateSelectionChipId), isFalse);
    });

    testWidgets('a selection in a normal field offers Translate; a collapsed cursor does not', (tester) async {
      final (h, probe) = await boot(tester);
      when(() => h.host.translate(any(), any(), any())).thenAnswer((_) async => 'Hola');
      await select(h, 0, 5);
      await tester.pump();
      expect(hasChip(probe.session!, translateSelectionChipId), isTrue);
      await select(h, 3, 3);
      await tester.pump();
      expect(hasChip(probe.session!, translateSelectionChipId), isFalse);
    });

    testWidgets('Translate offers Replace and Insert after, and Replace swaps the selection', (tester) async {
      final (h, probe) = await boot(tester);
      when(() => h.host.translate(any(), any(), any())).thenAnswer((_) async => 'Hola');
      await select(h, 0, 5);
      await tester.pump();
      await runChip(tester, probe.session!, translateSelectionChipId);

      verify(() => h.host.translate('hello', 'en', 'es')).called(1);
      final labels = probe.session!.stripChips.value.map((c) => c.label).toList();
      expect(labels, containsAll(['Replace: Hola', 'Insert after: Hola']));

      await runChip(tester, probe.session!, translateReplaceChipId);
      expect(h.editor.text, 'Hola world');
      expect(hasChip(probe.session!, translateReplaceChipId), isFalse, reason: 'the chips go after use');
    });

    testWidgets('Insert after puts a space and the translation after the selection', (tester) async {
      final (h, probe) = await boot(tester);
      when(() => h.host.translate(any(), any(), any())).thenAnswer((_) async => 'Hola');
      await select(h, 0, 5);
      await tester.pump();
      await runChip(tester, probe.session!, translateSelectionChipId);
      await runChip(tester, probe.session!, translateInsertAfterChipId);
      expect(h.editor.text, 'hello Hola world');
    });

    testWidgets('the pair goes the other way when the active language is the target', (tester) async {
      final (h, probe) = await boot(tester);
      when(() => h.host.translate(any(), any(), any())).thenAnswer((_) async => 'Hello');
      // The keyboard is typing Spanish, so the target (Spanish) becomes the source.
      probe.session!.activeLanguage.value = 'es';
      await select(h, 0, 5);
      await tester.pump();
      await runChip(tester, probe.session!, translateSelectionChipId);
      verify(() => h.host.translate('hello', 'es', 'en')).called(1);
    });

    testWidgets('never in a password field', (tester) async {
      final (h, probe) = await boot(
        tester,
        field: editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword),
      );
      await select(h, 0, 5);
      await tester.pump();
      expect(hasChip(probe.session!, translateSelectionChipId), isFalse);
    });

    testWidgets('nothing is offered while translation is off', (tester) async {
      final (h, probe) = await boot(tester, settings: _settings(enabled: false));
      await select(h, 0, 5);
      await tester.pump();
      expect(hasChip(probe.session!, translateSelectionChipId), isFalse);
    });

    testWidgets('a missing pack offers Get the pack, which opens the Model packs screen', (tester) async {
      final (h, probe) = await boot(tester);
      when(() => h.host.translate(any(), any(), any())).thenThrow(PlatformException(code: 'no_pack'));
      await select(h, 0, 5);
      await tester.pump();
      await runChip(tester, probe.session!, translateSelectionChipId);
      expect(hasChip(probe.session!, translateGetPackChipId), isTrue);
      await runChip(tester, probe.session!, translateGetPackChipId);
      verify(() => h.host.openSettings('packs')).called(1);
    });
  });

  group('chip labels', () {
    test('a preview fits in 24 characters', () {
      final label = SelectionTranslator.chipLabel('Insert after', 'A very long translated sentence indeed');
      expect(label.length, lessThanOrEqualTo(24));
      expect(label, startsWith('Insert after: A very'));
      expect(SelectionTranslator.chipLabel('Replace', 'Hola'), 'Replace: Hola');
    });
  });
}
