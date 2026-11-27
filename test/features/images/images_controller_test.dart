// SPDX-License-Identifier: GPL-3.0-or-later
//
// Picture making state: idle -> making (loading, step, decoding) -> done / failed / idle (stopped), driven by a
// mocked ImeHostApi and a stream of helper events.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/features/images/images_controller.dart';

import '../../keyboard/support/app_harness.dart';

Future<void> _settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ImageEventMessage _event(
  ImageEventKind kind, {
  int step = 0,
  int steps = 0,
  String? path,
  int? millis,
  String? error,
}) => ImageEventMessage(kind: kind, step: step, steps: steps, path: path, millis: millis, error: error);

void main() {
  setUpAll(() {
    registerKeyboardFallbacks();
    registerFallbackValue(ImageRequestMessage(prompt: ''));
  });

  late MockImeHost host;
  late StreamController<ImageEventMessage> events;
  late ImagesController controller;
  late List<ImagesState> seen;

  setUp(() {
    host = MockImeHost();
    events = StreamController<ImageEventMessage>.broadcast(sync: true);
    when(() => host.stopImage()).thenAnswer((_) async {});
    controller = ImagesController(host: host, events: events.stream);
    seen = [];
    controller.addListener(() => seen.add(controller.state));
  });

  tearDown(() async {
    controller.dispose();
    await events.close();
  });

  void started() => when(() => host.makeImage(any())).thenAnswer((_) async => ImageStartStatus.started);

  test('starts idle', () {
    expect(controller.state, isA<ImagesIdle>());
    expect(controller.isMaking, isFalse);
  });

  test('a picture goes loading, steps, decoding, done and carries the path and time', () async {
    started();
    await controller.make('a cabin', seed: 42);
    final request = verify(() => host.makeImage(captureAny())).captured.single as ImageRequestMessage;
    expect(request.prompt, 'a cabin');
    expect(request.seed, 42);

    events.add(_event(ImageEventKind.loading));
    events.add(_event(ImageEventKind.step, step: 1, steps: 4));
    events.add(_event(ImageEventKind.step, step: 2, steps: 4));
    events.add(_event(ImageEventKind.decoding));
    events.add(_event(ImageEventKind.done, path: '/cache/images/1.png', millis: 12345));

    expect(seen, [
      const ImagesMaking(phase: ImagesPhase.loading),
      const ImagesMaking(phase: ImagesPhase.sampling, step: 1, steps: 4),
      const ImagesMaking(phase: ImagesPhase.sampling, step: 2, steps: 4),
      const ImagesMaking(phase: ImagesPhase.decoding),
      const ImagesDone(path: '/cache/images/1.png', millis: 12345),
    ]);
    expect(controller.isMaking, isFalse);
  });

  test('the seed is optional (random)', () async {
    started();
    await controller.make('a cabin');
    final request = verify(() => host.makeImage(captureAny())).captured.single as ImageRequestMessage;
    expect(request.seed, isNull);
  });

  test('events that arrive before the start answer are kept', () async {
    final answer = Completer<ImageStartStatus>();
    when(() => host.makeImage(any())).thenAnswer((_) => answer.future);
    final future = controller.make('x');
    events.add(_event(ImageEventKind.step, step: 1, steps: 4));
    answer.complete(ImageStartStatus.started);
    await future;
    expect(controller.state, const ImagesMaking(phase: ImagesPhase.sampling, step: 1, steps: 4));
  });

  for (final (status, code) in [
    (ImageStartStatus.noPack, 'no_pack'),
    (ImageStartStatus.unsupported, 'unsupported'),
    (ImageStartStatus.busy, 'busy'),
  ]) {
    test('a refused start ($code) is a failure', () async {
      when(() => host.makeImage(any())).thenAnswer((_) async => status);
      await controller.make('x');
      expect(controller.state, ImagesFailed(code));
      expect(controller.isMaking, isFalse);
    });
  }

  test('a failing call is a failure, and the next try works', () async {
    when(() => host.makeImage(any())).thenThrow(Exception('channel'));
    await controller.make('x');
    expect(controller.state, const ImagesFailed('failed'));
    started();
    await controller.make('x');
    expect(controller.isMaking, isTrue);
  });

  test('an error event carries the helper code (helper_died, load_failed, ...)', () async {
    started();
    await controller.make('x');
    events.add(_event(ImageEventKind.error, error: 'helper_died'));
    expect(controller.state, const ImagesFailed('helper_died'));
  });

  test('an error event without a code still fails', () async {
    started();
    await controller.make('x');
    events.add(_event(ImageEventKind.error));
    expect(controller.state, const ImagesFailed('failed'));
  });

  test('a done event without a path is a failure', () async {
    started();
    await controller.make('x');
    events.add(_event(ImageEventKind.done));
    expect(controller.state, const ImagesFailed('failed'));
  });

  test('stop asks the host and a cancelled event returns to idle', () async {
    started();
    await controller.make('x');
    controller.stop();
    await _settle();
    verify(() => host.stopImage()).called(1);
    expect(controller.isMaking, isTrue);
    events.add(_event(ImageEventKind.cancelled));
    expect(controller.state, isA<ImagesIdle>());
  });

  test('stop while idle does nothing', () async {
    controller.stop();
    await _settle();
    verifyNever(() => host.stopImage());
  });

  test('a second make while one is running is ignored', () async {
    started();
    await controller.make('x');
    await controller.make('y');
    verify(() => host.makeImage(any())).called(1);
  });

  test('events when nothing is being made are ignored', () async {
    events.add(_event(ImageEventKind.step, step: 1, steps: 4));
    events.add(_event(ImageEventKind.done, path: '/p.png', millis: 1));
    expect(controller.state, isA<ImagesIdle>());
    expect(seen, isEmpty);
  });

  test('a finished picture can be followed by another', () async {
    started();
    await controller.make('x');
    events.add(_event(ImageEventKind.done, path: '/p.png', millis: 1));
    await controller.make('y');
    expect(controller.state, const ImagesMaking(phase: ImagesPhase.loading));
    verify(() => host.makeImage(any())).called(2);
  });

  test('closing the panel while a picture is being made stops it', () async {
    started();
    await controller.make('x');
    controller.dispose();
    await _settle();
    verify(() => host.stopImage()).called(1);
    // tearDown disposes again: that must be harmless.
  });
}
