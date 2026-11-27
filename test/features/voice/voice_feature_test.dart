// SPDX-License-Identifier: GPL-3.0-or-later
//
// The voice feature inside the keyboard: the mic button opens the panel (password fields too), incognito never
// does, the mic shows only with an English voice pack and an English keyboard language, and the panel's messages
// and text flow work end to end with a mocked ImeHostApi.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/features/voice/voice_feature.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../../keyboard/support/app_harness.dart';

void main() {
  setUpAll(() {
    registerKeyboardFallbacks();
    registerFallbackValue(VoiceRequestMessage(packId: ''));
  });

  final parakeet = PackInfoMessage(
    id: 'voice-parakeet-en',
    kind: PackKind.voice,
    name: 'Parakeet English',
    version: 1,
    languages: const ['en'],
    sizeBytes: 1,
    engine: 'sherpa-onnx-nemo-transducer',
    license: 'CC-BY-4.0',
  );

  void installPacks(AppHarness h, List<PackInfoMessage> packs) {
    when(() => h.platform.listPacks()).thenAnswer((_) async => packs);
  }

  void allowMic(AppHarness h) {
    installPacks(h, [parakeet]);
    when(() => h.host.hasMicPermission()).thenAnswer((_) async => true);
    when(() => h.host.requestMicPermission()).thenAnswer((_) async => true);
    when(() => h.host.stopVoice()).thenAnswer((_) async {});
    when(() => h.host.cancelVoice()).thenAnswer((_) async {});
  }

  Future<void> tapMic(WidgetTester tester) async {
    // Predictions fill the strip after focus; the toolbar (with the mic button) sits behind a toggle.
    // Incognito labels the toggle 'Incognito mode on. Show toolbar'.
    final toggle = find.bySemanticsLabel(RegExp('Show toolbar'));
    if (toggle.evaluate().isNotEmpty) {
      await tester.tap(toggle);
      await tester.pump();
    }
    await tester.tap(find.bySemanticsLabel('Voice typing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
  }

  testWidgets('the mic button opens the panel and a missing voice pack says so', (tester) async {
    final h = AppHarness();
    allowMic(h);
    when(() => h.host.startVoice(any())).thenAnswer((_) async => VoiceStartStatus.noModel);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester);

    await tapMic(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('needs the voice pack'), findsOneWidget);
    expect(find.textContaining('BooBoard never goes online'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Get the voice pack'));
    await tester.pump();
    verify(() => h.host.openSettings('packs')).called(1);
  });

  testWidgets('permission denied shows the permission message and never records', (tester) async {
    final h = AppHarness();
    installPacks(h, [parakeet]);
    when(() => h.host.hasMicPermission()).thenAnswer((_) async => false);
    when(() => h.host.requestMicPermission()).thenAnswer((_) async => false);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester);

    await tapMic(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('needs the microphone'), findsOneWidget);
    verifyNever(() => h.host.startVoice(any()));
  });

  testWidgets('partial text shows, final text is committed, and stop closes the panel', (tester) async {
    final h = AppHarness(text: 'Hi');
    allowMic(h);
    when(() => h.host.startVoice(any())).thenAnswer((_) async => VoiceStartStatus.started);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester);

    await tapMic(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Listening. Speak now.'), findsOneWidget);

    await h.events.onVoiceEvent(VoiceEventMessage(kind: VoiceEventKind.partial, level: 0, text: 'there'));
    await tester.pump();
    expect(find.text('there'), findsOneWidget);
    expect(h.editor.composing, ' there');

    await h.events.onVoiceEvent(VoiceEventMessage(kind: VoiceEventKind.finalText, level: 0, text: 'there friend'));
    await h.events.onVoiceEvent(VoiceEventMessage(kind: VoiceEventKind.stopped, level: 0));
    await tester.pump(const Duration(milliseconds: 300));

    expect(h.editor.text, 'Hi there friend');
    expect(find.bySemanticsLabel('Stop and keep the text'), findsNothing);
  });

  testWidgets('cancel discards the partial text', (tester) async {
    final h = AppHarness(text: 'Hi');
    allowMic(h);
    when(() => h.host.startVoice(any())).thenAnswer((_) async => VoiceStartStatus.started);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester);

    await tapMic(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await h.events.onVoiceEvent(VoiceEventMessage(kind: VoiceEventKind.partial, level: 0, text: 'maybe'));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Cancel voice typing'));
    await tester.pump();
    verify(() => h.host.cancelVoice()).called(1);
    await h.events.onVoiceEvent(VoiceEventMessage(kind: VoiceEventKind.stopped, level: 0));
    await tester.pump(const Duration(milliseconds: 300));

    expect(h.editor.text, 'Hi');
  });

  testWidgets('password fields show the mic and open the panel (2026-11-26)', (tester) async {
    final h = AppHarness();
    allowMic(h);
    when(() => h.host.startVoice(any())).thenAnswer((_) async => VoiceStartStatus.started);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester, editorInfo(inputType: AndroidInputType.classText | AndroidInputType.textVariationPassword));

    // Private fields show the usual toolbar, mic included.
    expect(find.bySemanticsLabel('Voice typing'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Voice typing'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('Cancel voice typing'), findsOneWidget);
  });

  testWidgets('incognito never opens the panel', (tester) async {
    final h = AppHarness(settings: const BooBoardSettings(privacy: PrivacySettings(incognito: true)));
    allowMic(h);
    when(() => h.host.startVoice(any())).thenAnswer((_) async => VoiceStartStatus.started);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester);

    await tapMic(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.bySemanticsLabel('Cancel voice typing'), findsNothing);
    verifyNever(() => h.host.startVoice(any()));
  });

  testWidgets('voice switched off in settings explains it and offers the voice settings', (tester) async {
    final h = AppHarness(settings: BooBoardSettings(voice: const VoiceSettings(enabled: false)));
    allowMic(h);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester);

    await tapMic(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Voice typing is off. Turn it on in Voice settings.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Open voice settings'));
    await tester.pump();
    verify(() => h.host.openSettings('voice')).called(1);
    verifyNever(() => h.host.startVoice(any()));
  });
  Future<void> showToolbar(WidgetTester tester) async {
    final toggle = find.bySemanticsLabel(RegExp('Show toolbar'));
    if (toggle.evaluate().isNotEmpty) {
      await tester.tap(toggle);
      await tester.pump();
    }
  }

  testWidgets('English keyboard with the English voice pack shows the mic', (tester) async {
    final h = AppHarness();
    allowMic(h);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester);
    await showToolbar(tester);

    expect(find.bySemanticsLabel('Voice typing'), findsOneWidget);
  });

  testWidgets('without an English voice pack the mic is hidden', (tester) async {
    final h = AppHarness();
    allowMic(h);
    installPacks(h, [
      PackInfoMessage(
        id: 'translate-en-es',
        kind: PackKind.translation,
        name: 'English to Spanish',
        version: 1,
        languages: const ['en', 'es'],
        sizeBytes: 1,
        engine: 'opus-mt-onnx',
        license: 'CC-BY-4.0',
      ),
    ]);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester);
    await showToolbar(tester);

    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    expect(find.bySemanticsLabel('Voice typing'), findsNothing);
  });

  testWidgets('a non-English keyboard language hides the mic even with the English pack', (tester) async {
    final h = AppHarness(
      settings: const BooBoardSettings(
        languages: LanguageSettings(enabled: ['es'], active: 'es'),
      ),
    );
    allowMic(h);
    await h.pump(tester, features: [createVoiceFeature()]);
    await h.focus(tester);
    await showToolbar(tester);

    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    expect(find.bySemanticsLabel('Voice typing'), findsNothing);
  });
}
