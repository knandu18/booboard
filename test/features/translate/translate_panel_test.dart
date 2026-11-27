// SPDX-License-Identifier: GPL-3.0-or-later
//
// The translate bar (2026-11-26: two rows, live output) and its language list inside the real keyboard
// view, with the fake editor and host.
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter/widgets.dart' show Scrollable, ScrollableState, Semantics;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/features/translate/translate_feature.dart';
import 'package:booboard/src/features/translate/translate_languages.dart';
import 'package:booboard/src/features/translate/translate_pair_panel.dart';
import 'package:booboard/src/features/translate/translate_panel.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/keyboard/view/keyboard_view.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../../keyboard/support/app_harness.dart';

/// Captures the session so tests can reach the input controller and the open panel.
class _Probe extends KeyboardFeature {
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return const KeyboardHooks();
  }
}

/// Settings that keep the strip on the toolbar, with translation on for en -> es.
BooBoardSettings _settings({bool enabled = true, String from = 'en', String to = 'es'}) => BooBoardSettings(
  typing: const TypingSettings(nextWordPrediction: false),
  translate: TranslateSettings(enabled: enabled, from: from, to: to),
);

Future<(AppHarness, _Probe)> boot(
  WidgetTester tester, {
  BooBoardSettings? settings,
  EditorInfoMessage? field,
  String text = '',
}) async {
  final h = AppHarness(settings: settings ?? _settings(), text: text);
  final probe = _Probe();
  await h.pump(tester, features: [probe, createTranslateFeature()]);
  when(() => h.platform.listPacks()).thenAnswer((_) async => const []);
  when(() => h.host.releaseTranslator()).thenAnswer((_) async {});
  when(() => h.host.translate(any(), any(), any()))
      .thenAnswer((inv) async => 'EN:${inv.positionalArguments[0] as String}');
  await h.focus(tester, field);
  return (h, probe);
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 20));
}

/// Scrolls the list until [finder] is on screen, then taps it.
Future<void> tapScrolling(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tap(tester, finder);
}

/// Lets the debounce (300 ms) and the fake engine finish.
Future<void> waitForTranslation(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

KeyRedirect _redirectOf(_Probe probe) => probe.session!.input.redirect.value!;

void main() {
  group('translate bar', () {
    testWidgets('opens from the toolbar with two rows: the pair, then the text box', (tester) async {
      final (_, probe) = await boot(tester);
      final keysBefore = tester.getSize(find.byType(KeyboardKeysArea)).height;
      await tap(tester, find.bySemanticsLabel('Translate'));
      expect(probe.session!.panel.value, isA<TranslatePanel>());
      expect(find.bySemanticsLabel('Translate from English. Change language'), findsOneWidget);
      expect(find.bySemanticsLabel('Translate to Spanish. Change language'), findsOneWidget);
      expect(find.bySemanticsLabel('Swap languages'), findsOneWidget);
      expect(find.text('Type here to translate'), findsOneWidget);
      final keysAfter = tester.getSize(find.byType(KeyboardKeysArea)).height;
      expect(keysBefore - keysAfter, translateBoxRowHeight, reason: 'the box row comes from the keys');
    });

    testWidgets('the translation appears live in the app; the typed source never does', (tester) async {
      final (h, probe) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe)
        ..onText('w')
        ..onText('here');
      await waitForTranslation(tester);
      expect(find.text('where'), findsOneWidget, reason: 'the box shows what was typed');
      expect(h.editor.text, 'EN:where', reason: 'the app shows the translation, live');
      expect(h.editor.composing, 'EN:where', reason: 'still open to change while typing');

      _redirectOf(probe).onText('s');
      await waitForTranslation(tester);
      expect(h.editor.text, 'EN:wheres', reason: 'the app follows the new translation');
      expect(h.predictor.committed, isEmpty, reason: 'nothing is learned from the bar');
    });

    testWidgets('Enter keeps the translation and empties the box; backspace edits the source', (tester) async {
      final (h, probe) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe)
        ..onText('x')
        ..onText('yz')
        ..onBackspace();
      await waitForTranslation(tester);
      expect(h.editor.text, 'EN:xy');
      _redirectOf(probe).onEnter();
      await tester.pump();
      expect(h.editor.composing, isNull, reason: 'kept');
      expect(find.text('Type here to translate'), findsOneWidget, reason: 'the box is empty again');

      _redirectOf(probe).onText('hi');
      await waitForTranslation(tester);
      expect(h.editor.text, 'EN:xy EN:hi', reason: 'the next phrase gets a space');
    });

    testWidgets('a translation after existing text gets a space', (tester) async {
      final (h, probe) = await boot(tester, text: 'where is the station');
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe).onText('hi');
      await waitForTranslation(tester);
      expect(h.editor.text, 'where is the station EN:hi');
    });

    testWidgets('closing keeps the translation and gives the keys back to the app', (tester) async {
      final (h, probe) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe).onText('hi');
      await waitForTranslation(tester);
      await tap(tester, find.bySemanticsLabel('Close translation'));
      await tester.pump();
      expect(probe.session!.panel.value, isNull);
      expect(probe.session!.input.redirect.value, isNull, reason: 'keys type into the app again');
      expect(h.editor.text, 'EN:hi');
      expect(h.editor.composing, isNull);
      verify(() => h.host.releaseTranslator()).called(1);
    });

    testWidgets('the clear button empties the box and takes the translation back out', (tester) async {
      final (h, probe) = await boot(tester, text: 'ok');
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe).onText('hi');
      await waitForTranslation(tester);
      expect(h.editor.text, 'ok EN:hi');
      await tap(tester, find.bySemanticsLabel('Clear text'));
      await tester.pump();
      expect(h.editor.text, 'ok');
      expect(find.text('Type here to translate'), findsOneWidget);
    });

    testWidgets('a missing pack says which pack to get, privately, and Get opens Model packs', (tester) async {
      final (h, probe) = await boot(tester);
      when(() => h.host.translate(any(), any(), any()))
          .thenAnswer((_) async => throw PlatformException(code: 'no_pack'));
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe).onText('hi');
      await waitForTranslation(tester);
      expect(find.textContaining('No English → Spanish pack yet'), findsOneWidget);
      expect(find.textContaining('your browser downloads it'), findsOneWidget);
      expect(find.text('hi'), findsOneWidget, reason: 'what was typed stays in the box');
      expect(h.editor.text, '', reason: 'nothing reaches the app without a translation');
      await tap(tester, find.bySemanticsLabel('Get the translation pack'));
      verify(() => h.host.openSettings('packs')).called(1);
    });

    testWidgets('a pair whose pack is not published says so and offers no Get', (tester) async {
      final (h, probe) = await boot(tester, settings: _settings(to: 'de'));
      when(() => h.host.translate(any(), any(), any()))
          .thenAnswer((_) async => throw PlatformException(code: 'no_pack'));
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe).onText('hi');
      await waitForTranslation(tester);
      expect(find.textContaining('not published yet'), findsOneWidget);
      expect(find.text('hi'), findsOneWidget, reason: 'what was typed stays in the box');
      expect(find.bySemanticsLabel('Get the translation pack'), findsNothing);
    });

    testWidgets('swap turns the pair round, saves it, keeps the text, and replaces the live translation', (
      tester,
    ) async {
      final (h, probe) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe).onText('hola');
      await waitForTranslation(tester);
      expect(h.editor.text, 'EN:hola');
      await tap(tester, find.bySemanticsLabel('Swap languages'));
      await waitForTranslation(tester);
      expect(h.store.value.translate.from, 'es');
      expect(h.store.value.translate.to, 'en');
      expect(find.bySemanticsLabel('Translate from Spanish. Change language'), findsOneWidget);
      expect(find.text('hola'), findsOneWidget, reason: 'the typed text stays');
      expect(h.editor.text, 'EN:hola', reason: 'one live translation, not two');
      verify(() => h.host.translate('hola', 'es', 'en')).called(1);
    });

    testWidgets('nothing opens while translation is off', (tester) async {
      await boot(tester, settings: _settings(enabled: false));
      expect(find.bySemanticsLabel('Translate'), findsNothing);
    });

    testWidgets('the translate bar opens in a password field too (2026-11-26)', (tester) async {
      final (_, probe) = await boot(
        tester,
        field: editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword),
      );
      expect(probe.session!.input.currentField.isSensitive, isTrue);
      probe.session!.openPanel(
        TranslatePanel(session: probe.session!, from: 'en', to: 'es', installedPairs: () async => const {}),
      );
      expect(probe.session!.panel.value, isA<TranslatePanel>());
    });
  });

  group('language list', () {
    PackInfoMessage frenchPack() => PackInfoMessage(
      id: 'translate-en-fr',
      kind: PackKind.translation,
      name: 'English → French',
      version: 1,
      languages: const ['en', 'fr'],
      sizeBytes: 100,
      engine: 'opus-mt-onnx',
      license: 'Apache-2.0',
    );

    testWidgets('"Translate to": the current language first with a check, installed next; one tap saves', (
      tester,
    ) async {
      final (h, probe) = await boot(tester);
      when(() => h.platform.listPacks()).thenAnswer((_) async => [frenchPack()]);
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe).onText('hi');
      await waitForTranslation(tester);
      await tap(tester, find.bySemanticsLabel('Translate to Spanish. Change language'));
      await tester.pump();
      expect(find.text('Translate to'), findsOneWidget);
      expect(h.editor.text, '', reason: 'the live translation leaves the app while the list is open');
      final spanish = find.bySemanticsLabel('Spanish, English to Spanish, pack not installed, selected');
      final french = find.bySemanticsLabel('French, English to French, pack installed');
      expect(spanish, findsOneWidget);
      expect(french, findsOneWidget);
      expect(tester.getTopLeft(spanish).dy, lessThan(tester.getTopLeft(french).dy), reason: 'current first');
      expect(find.text('Français'), findsOneWidget, reason: 'rows use the language\'s own name');

      await tapScrolling(tester, french);
      await waitForTranslation(tester);
      expect(h.store.value.translate.from, 'en');
      expect(h.store.value.translate.to, 'fr');
      expect(probe.session!.panel.value, isA<TranslatePanel>());
      expect(find.bySemanticsLabel('Translate to French. Change language'), findsOneWidget);
      expect(h.editor.text, 'EN:hi', reason: 'the bar is back with the text and its translation');
    });

    testWidgets('"Translate from": a non-English choice keeps the other side and goes through English', (tester) async {
      final (h, _) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Translate'));
      await tap(tester, find.bySemanticsLabel('Translate from English. Change language'));
      await tester.pump();
      expect(find.text('Translate from'), findsOneWidget);
      expect(find.bySemanticsLabel('Get the German to Spanish packs'), findsNothing, reason: 'not published');
      await tapScrolling(tester, find.bySemanticsLabel('German, German to Spanish, pack coming soon, through English'));
      await tester.pump(const Duration(milliseconds: 20));
      expect(h.store.value.translate.from, 'de');
      expect(h.store.value.translate.to, 'es');
    });

    testWidgets('every keyboard language is listed; one without a pack is marked, and a tap only explains', (
      tester,
    ) async {
      final (h, probe) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Translate'));
      await tap(tester, find.bySemanticsLabel('Translate to Spanish. Change language'));
      await tester.pump();
      expect(find.text('Translate to'), findsOneWidget);
      // Step through the whole list and collect each row's spoken label, in order.
      final position = tester.state<ScrollableState>(find.byType(Scrollable).last).position;
      final labels = <String>[];
      for (var offset = 0.0; ; offset += 40) {
        position.jumpTo(offset.clamp(0, position.maxScrollExtent));
        await tester.pump();
        for (final e in find.byWidgetPredicate((w) => w is Semantics && w.properties.button == true).evaluate()) {
          final label = (e.widget as Semantics).properties.label ?? '';
          if (label.contains(', ') && !labels.contains(label)) labels.add(label);
        }
        if (offset >= position.maxScrollExtent) break;
      }
      expect(labels, hasLength(19), reason: 'every keyboard language, Portuguese twice');
      for (final name in ['Arabic', 'Urdu', 'Chinese', 'Japanese', 'Filipino', 'Tamil', 'Telugu']) {
        expect(labels.where((l) => l.startsWith(name) && l.endsWith('no translation pack yet')), hasLength(1));
      }
      final firstNoPack = labels.indexWhere((l) => l.endsWith('no translation pack yet'));
      expect(labels.skip(firstNoPack).every((l) => l.endsWith('no translation pack yet')), isTrue);

      final tamil = find.bySemanticsLabel(RegExp(r'^Tamil.*no translation pack yet$'));
      for (var offset = position.maxScrollExtent; tamil.evaluate().isEmpty && offset > 0; offset -= 40) {
        position.jumpTo(offset);
        await tester.pump();
      }
      await tester.ensureVisible(tamil);
      await tester.pump();
      await tap(tester, tamil);
      await tester.pump();
      expect(find.text('No translation pack for Tamil yet'), findsOneWidget);
      expect(h.store.value.translate.to, 'es', reason: 'the pair stays');
      expect(probe.session!.panel.value, isA<TranslatePairPanel>(), reason: 'the list stays open');
    });

    testWidgets('a pair without English translates through English in the bar', (tester) async {
      final (h, probe) = await boot(
        tester,
        settings: _settings(from: 'es', to: 'fr'),
      );
      when(() => h.host.translate(any(), any(), any())).thenAnswer(
        (inv) async => '${(inv.positionalArguments[2] as String).toUpperCase()}:${inv.positionalArguments[0]}',
      );
      await tap(tester, find.bySemanticsLabel('Translate'));
      expect(find.bySemanticsLabel('Swap languages'), findsOneWidget);
      _redirectOf(probe).onText('hola');
      await waitForTranslation(tester);
      verify(() => h.host.translate('hola', 'es', 'en')).called(1);
      verify(() => h.host.translate('EN:hola', 'en', 'fr')).called(1);
      expect(h.editor.text, 'FR:EN:hola');
    });

    testWidgets('a missing pack on a pair through English says so', (tester) async {
      final (h, probe) = await boot(
        tester,
        settings: _settings(from: 'es', to: 'fr'),
      );
      when(() => h.host.translate(any(), any(), any()))
          .thenAnswer((_) async => throw PlatformException(code: 'no_pack'));
      await tap(tester, find.bySemanticsLabel('Translate'));
      _redirectOf(probe).onText('hola');
      await waitForTranslation(tester);
      expect(find.textContaining('Spanish → French goes through English'), findsOneWidget);
      expect(find.bySemanticsLabel('Get the translation pack'), findsNothing, reason: 'English → French not out');
    });

    testWidgets('Get opens Model packs; back returns to the bar unchanged', (tester) async {
      final (h, probe) = await boot(tester);
      await tap(tester, find.bySemanticsLabel('Translate'));
      await tap(tester, find.bySemanticsLabel('Translate to Spanish. Change language'));
      await tester.pump();
      await tapScrolling(tester, find.bySemanticsLabel('Get the English to Spanish pack'));
      verify(() => h.host.openSettings('packs')).called(1);
      await tap(tester, find.bySemanticsLabel('Back to translation'));
      expect(probe.session!.panel.value, isA<TranslatePanel>());
      expect(h.store.value.translate.to, 'es');
    });

    test('rows: current first, then installed, published, coming soon, and no pack last', () {
      final status = {
        'en': PairStatus.installed,
        'es': PairStatus.published,
        'fr': PairStatus.installed,
        'de': PairStatus.comingSoon,
        'ta': PairStatus.noPack,
        'ar': PairStatus.noPack,
      };
      expect(orderPairLanguages('de', ['en', 'es', 'fr', 'de', 'ta', 'ar'], (id) => status[id]!), [
        'de',
        'en',
        'fr',
        'es',
        'ta',
        'ar',
      ]);
    });

    test('a choice keeps the other side; choosing the other side\'s language swaps', () {
      expect(pairAfterChoosing(TranslateSide.to, 'fr', from: 'en', to: 'es'), ('en', 'fr'));
      expect(pairAfterChoosing(TranslateSide.to, 'fr', from: 'es', to: 'en'), ('es', 'fr'));
      expect(pairAfterChoosing(TranslateSide.to, 'en', from: 'en', to: 'es'), ('es', 'en'));
      expect(pairAfterChoosing(TranslateSide.to, 'en', from: 'de', to: 'en'), ('de', 'en'));
      expect(pairAfterChoosing(TranslateSide.from, 'hi', from: 'en', to: 'es'), ('hi', 'es'));
      expect(pairAfterChoosing(TranslateSide.from, 'en', from: 'es', to: 'en'), ('en', 'es'));
      expect(pairAfterChoosing(TranslateSide.from, 'en', from: 'en', to: 'ru'), ('en', 'ru'));
      expect(pairAfterChoosing(TranslateSide.to, 'pt-PT', from: 'pt-BR', to: 'en'), ('en', 'pt-PT'));
    });
  });
}
