// SPDX-License-Identifier: GPL-3.0-or-later
//
// Voice settings: the switch (voice typing works in English only), the voice pack choice (Automatic or an
// installed voice pack) and the privacy line. Writes go through SettingsStore.update with the 'voice' section.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/screens/voice_screen.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../support/app_fakes.dart';

PackInfoMessage _pack(String id, PackKind kind, String name) => PackInfoMessage(
  id: id,
  kind: kind,
  name: name,
  version: 1,
  languages: const ['en'],
  sizeBytes: 60 * 1024 * 1024,
  engine: 'sherpa-onnx-nemo-transducer',
  license: 'CC-BY-4.0',
);

/// The settings a write produced: applies the captured change to [base].
BooBoardSettings _applied(AppFakes fakes, {BooBoardSettings base = const BooBoardSettings()}) {
  final change =
      verify(() => fakes.store.update(captureAny(), sections: any(named: 'sections'))).captured.last
          as BooBoardSettings Function(BooBoardSettings);
  return change(base);
}

void main() {
  setUpAll(() {
    registerFallbackValue((BooBoardSettings s) => s);
    registerFallbackValue(<String>[]);
  });

  late AppFakes fakes;

  setUp(() {
    fakes = AppFakes();
    when(() => fakes.platform.listPacks()).thenAnswer(
      (_) async => [
        _pack('voice-parakeet-en', PackKind.voice, 'Parakeet English'),
        _pack('voice-english-alt', PackKind.voice, 'English alternative'),
        _pack('translate-en-es', PackKind.translation, 'English to Spanish'),
      ],
    );
  });

  Future<void> pump(WidgetTester tester, BooBoardSettings settings) async {
    fakes = AppFakes(settings: settings);
    when(() => fakes.platform.listPacks()).thenAnswer(
      (_) async => [
        _pack('voice-parakeet-en', PackKind.voice, 'Parakeet English'),
        _pack('voice-english-alt', PackKind.voice, 'English alternative'),
        _pack('translate-en-es', PackKind.translation, 'English to Spanish'),
      ],
    );
    await pumpWithServices(
      tester,
      fakes.services,
      const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: VoiceScreen()),
    );
  }

  testWidgets('shows the switch, English only, the Automatic pack and the privacy line', (tester) async {
    await pump(tester, const BooBoardSettings());

    expect(find.text('Voice typing'), findsOneWidget);
    expect(find.text('Voice pack'), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Speak to type in English. Recognition runs on this phone.'), findsOneWidget);
    expect(find.text('Detect language automatically'), findsNothing);
    expect(find.text('Audio stays on this phone and is never saved.'), findsOneWidget);
  });

  testWidgets('turning voice typing off writes the voice section', (tester) async {
    await pump(tester, const BooBoardSettings());

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final written = _applied(fakes);
    expect(written.voice.enabled, isFalse);
  });

  testWidgets('a selected pack shows its name', (tester) async {
    await pump(tester, const BooBoardSettings(voice: VoiceSettings(modelId: 'voice-english-alt')));

    expect(find.text('English alternative'), findsOneWidget);
    expect(find.text('Automatic'), findsNothing);
  });

  testWidgets('choosing a voice pack lists only voice packs and writes the id', (tester) async {
    await pump(tester, const BooBoardSettings());

    await tester.tap(find.text('Voice pack'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Parakeet English'), findsOneWidget);
    expect(find.textContaining('English alternative'), findsOneWidget);
    expect(find.textContaining('English to Spanish'), findsNothing);

    await tester.tap(find.textContaining('English alternative'));
    await tester.pumpAndSettle();

    expect(_applied(fakes).voice.modelId, 'voice-english-alt');
  });

  testWidgets('a pack imported after the screen opened is offered', (tester) async {
    await pump(tester, const BooBoardSettings());
    when(() => fakes.platform.listPacks()).thenAnswer(
      (_) async => [
        _pack('voice-parakeet-en', PackKind.voice, 'Parakeet English'),
        _pack('voice-english-new', PackKind.voice, 'English new'),
      ],
    );

    await tester.tap(find.text('Voice pack'));
    await tester.pumpAndSettle();

    expect(find.textContaining('English new'), findsOneWidget);
    expect(find.textContaining('English alternative'), findsNothing);
  });
}
