// SPDX-License-Identifier: GPL-3.0-or-later
//
// The mic panel's flow, with a mocked ImeHostApi and a fake editor: permission denied, no model, busy,
// partial then final text, stop, cancel, disposal, and the English-only mic rule.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/input_sink.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/features/voice/voice_controller.dart';

import '../../keyboard/support/app_harness.dart';
import '../../support/fake_editor.dart';

/// The text side of a session, backed by [editor] (the same fake the assertions read).
class _Sink implements VoiceTextSink {
  _Sink(this._editor);

  final FakeEditor _editor;

  @override
  InputSink get editor => _editor;

  @override
  void finishComposing() {}

  @override
  void resyncAfterExternalEdit() {}
}

Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUpAll(() {
    registerKeyboardFallbacks();
    registerFallbackValue(VoiceRequestMessage(packId: ''));
  });

  late MockImeHost host;
  late StreamController<VoiceEventMessage> events;
  late FakeEditor editor;
  late VoiceController controller;
  late List<VoiceRequestMessage> requests;
  var finished = 0;

  VoiceController make({bool enabled = true, String language = 'en', String packId = ''}) {
    final c = VoiceController(
      host: host,
      events: events.stream,
      text: _Sink(editor),
      packId: packId,
      enabled: enabled,
      language: language,
    );
    c.onFinished = () => finished++;
    return c;
  }

  setUp(() {
    host = MockImeHost();
    events = StreamController<VoiceEventMessage>.broadcast(sync: true);
    editor = FakeEditor(text: '');
    finished = 0;
    requests = [];
    when(() => host.hasMicPermission()).thenAnswer((_) async => true);
    when(() => host.requestMicPermission()).thenAnswer((_) async => true);
    when(() => host.stopVoice()).thenAnswer((_) async {});
    when(() => host.cancelVoice()).thenAnswer((_) async {});
    when(() => host.startVoice(any())).thenAnswer((invocation) async {
      requests.add(invocation.positionalArguments.first as VoiceRequestMessage);
      return VoiceStartStatus.started;
    });
    // A placeholder so that tearDown is safe before a test assigns its own controller. It is disposed at once,
    // so it does not also hear the events meant for the test's controller.
    controller = make()..dispose();
  });

  tearDown(() async {
    controller.dispose();
    await events.close();
  });

  test('text rules: a space before a new utterance, and capitals at a sentence start', () {
    expect(VoiceText.utteranceAt(null).prefix, '');
    expect(VoiceText.utteranceAt(null).capitalise, isTrue);
    expect(VoiceText.utteranceAt('').capitalise, isTrue);
    expect(VoiceText.utteranceAt('Hello').prefix, ' ');
    expect(VoiceText.utteranceAt('Hello').capitalise, isFalse);
    expect(VoiceText.utteranceAt('Hello. ').prefix, '');
    expect(VoiceText.utteranceAt('Hello.').prefix, ' ');
    expect(VoiceText.utteranceAt('Hello.').capitalise, isTrue);
    expect(VoiceText.utteranceAt('Done!  ').capitalise, isTrue);
    expect(VoiceText.format('  turn on the light ', capitalise: true), 'Turn on the light');
    expect(VoiceText.format('turn on', capitalise: false), 'turn on');
    expect(VoiceText.format('   ', capitalise: true), '');
  });

  test('permission denied: never starts voice and says so', () async {
    when(() => host.hasMicPermission()).thenAnswer((_) async => false);
    when(() => host.requestMicPermission()).thenAnswer((_) async => false);
    controller = make();
    await controller.begin();
    expect(controller.phase, VoicePhase.noPermission);
    expect(requests, isEmpty);
  });

  test('permission is asked for once and granted: starts listening', () async {
    when(() => host.hasMicPermission()).thenAnswer((_) async => false);
    controller = make();
    await controller.begin();
    verify(() => host.requestMicPermission()).called(1);
    expect(controller.phase, VoicePhase.listening);
  });

  test('no voice pack: the panel says so', () async {
    when(() => host.startVoice(any())).thenAnswer((_) async => VoiceStartStatus.noModel);
    controller = make();
    await controller.begin();
    expect(controller.phase, VoicePhase.noModel);
  });

  test('busy microphone and a failed start both leave a message on the panel', () async {
    when(() => host.startVoice(any())).thenAnswer((_) async => VoiceStartStatus.busy);
    controller = make();
    await controller.begin();
    expect(controller.phase, VoicePhase.busy);

    when(() => host.startVoice(any())).thenAnswer((_) async => VoiceStartStatus.failed);
    final again = make();
    await again.begin();
    expect(again.phase, VoicePhase.failed);
    again.dispose();
    controller = make();
  });

  test('a request names the keyboard language and the chosen pack', () async {
    controller = make(language: 'en-GB', packId: 'voice-parakeet-en');
    await controller.begin();
    expect(requests.single.language, 'en-GB');
    expect(requests.single.packId, 'voice-parakeet-en');
  });

  test('partial text is composing text; final text is committed with a space', () async {
    editor = FakeEditor(text: 'Hello');
    controller = make();
    await controller.begin();

    events.add(VoiceEventMessage(kind: VoiceEventKind.partial, level: 0, text: 'turn on'));
    await _settle();
    expect(editor.text, 'Hello turn on');
    expect(editor.composing, ' turn on');
    expect(controller.partial, 'turn on');

    events.add(VoiceEventMessage(kind: VoiceEventKind.finalText, level: 0, text: 'turn on the light'));
    await _settle();
    expect(editor.text, 'Hello turn on the light');
    expect(editor.composing, isNull);
    expect(controller.partial, '');
    expect(controller.phase, VoicePhase.listening);
  });

  test('a final at a sentence start is capitalised', () async {
    controller = make();
    await controller.begin();
    events.add(VoiceEventMessage(kind: VoiceEventKind.finalText, level: 0, text: 'good morning'));
    await _settle();
    expect(editor.text, 'Good morning');
  });

  test('level events update the level while listening', () async {
    controller = make();
    await controller.begin();
    events.add(VoiceEventMessage(kind: VoiceEventKind.level, level: 0.7));
    expect(controller.level, 0.7);
  });

  test('stop keeps the text, then finishes and closes the panel', () async {
    controller = make();
    await controller.begin();
    controller.stop();
    verify(() => host.stopVoice()).called(1);
    expect(controller.phase, VoicePhase.stopping);
    events.add(VoiceEventMessage(kind: VoiceEventKind.finalText, level: 0, text: 'ok'));
    events.add(VoiceEventMessage(kind: VoiceEventKind.stopped, level: 0));
    await _settle();
    expect(controller.phase, VoicePhase.finished);
    expect(finished, 1);
    expect(editor.text, 'Ok');
  });

  test('cancel removes the partial text and never commits it', () async {
    controller = make();
    await controller.begin();
    events.add(VoiceEventMessage(kind: VoiceEventKind.partial, level: 0, text: 'maybe this'));
    await _settle();
    expect(editor.text, 'Maybe this');

    controller.cancel();
    verify(() => host.cancelVoice()).called(1);
    events.add(VoiceEventMessage(kind: VoiceEventKind.stopped, level: 0));
    await _settle();
    expect(editor.text, '');
    expect(controller.phase, VoicePhase.finished);
    expect(finished, 1);
  });

  group('English-only mic rule', () {
    PackInfoMessage pack(String id, PackKind kind, List<String> languages) => PackInfoMessage(
      id: id,
      kind: kind,
      name: id,
      version: 1,
      languages: languages,
      engine: 'sherpa-onnx-nemo-transducer',
      license: 'CC-BY-4.0',
      sizeBytes: 1,
    );
    final parakeet = pack('voice-parakeet-en', PackKind.voice, ['en']);
    final translation = pack('translate-en-es', PackKind.translation, ['en', 'es']);
    final hindiVoice = pack('voice-hi', PackKind.voice, ['hi']);

    test('English and every en-* variant are voice languages; others are not', () {
      for (final id in ['en', 'en-GB', 'en-IN', 'EN-us']) {
        expect(isVoiceLanguage(id), isTrue, reason: id);
      }
      for (final id in ['', 'hi', 'pt-BR', 'es', 'fil', 'eng', 'ja']) {
        expect(isVoiceLanguage(id), isFalse, reason: id);
      }
    });

    test('the mic shows with an English voice pack and an English keyboard language', () {
      expect(voiceMicVisible(packs: [parakeet], language: 'en'), isTrue);
      expect(voiceMicVisible(packs: [translation, parakeet], language: 'en-GB'), isTrue);
    });

    test('the mic is hidden for other languages, even with the English pack', () {
      for (final language in ['hi', 'pt-BR', 'es', 'zh', 'ja', 'ar']) {
        expect(
          voiceMicVisible(packs: [parakeet], language: language),
          isFalse,
          reason: language,
        );
      }
    });

    test('the mic is hidden without an English voice pack', () {
      expect(voiceMicVisible(packs: const [], language: 'en'), isFalse);
      expect(voiceMicVisible(packs: [translation], language: 'en'), isFalse);
      expect(voiceMicVisible(packs: [hindiVoice], language: 'en'), isFalse);
    });
  });

  test('a disabled voice setting shows its message and never starts', () async {
    controller = make(enabled: false);
    await controller.begin();
    expect(controller.phase, VoicePhase.disabled);
    expect(requests, isEmpty);
  });

  test('dispose cancels an active session and ignores later events', () async {
    controller = make();
    await controller.begin();
    controller.dispose();
    verify(() => host.cancelVoice()).called(1);
    events.add(VoiceEventMessage(kind: VoiceEventKind.partial, level: 0, text: 'late'));
    await _settle();
    expect(editor.text, '');
    controller = make();
  });
}
