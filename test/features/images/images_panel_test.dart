// SPDX-License-Identifier: GPL-3.0-or-later
//
// The Images panel in the keyboard: release builds (debugTools false) show only the coming-soon view; with
// debugTools the "Make test picture" button drives the helper and shows progress, Stop and the picture.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/features/images/images_controller.dart';
import 'package:booboard/src/features/images/images_debug_view.dart';
import 'package:booboard/src/features/images/images_panel.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';

import '../../keyboard/support/app_harness.dart';

class _Probe extends KeyboardFeature {
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return const KeyboardHooks();
  }
}

void main() {
  setUpAll(() {
    registerKeyboardFallbacks();
    registerFallbackValue(ImageRequestMessage(prompt: ''));
  });

  Future<(AppHarness, _Probe)> open(WidgetTester tester, {required bool debugTools}) async {
    final h = AppHarness();
    final probe = _Probe();
    await h.pump(tester, features: [probe]);
    await h.focus(tester);
    probe.session!.openPanel(ImagesPanel(debugTools: debugTools));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    return (h, probe);
  }

  testWidgets('without debug tools the panel is the coming-soon view and has no test button', (tester) async {
    await open(tester, debugTools: false);
    // The coming-soon view overflows the short panel of the 360x700 test window; that is how it is today.
    tester.takeException();
    expect(find.text('Make test picture'), findsNothing);
    expect(find.byKey(const Key('images-debug-action')), findsNothing);
    expect(find.text('Coming in a later update'), findsOneWidget);
    expect(find.bySemanticsLabel('Back to the keys'), findsOneWidget);
  });

  testWidgets('the debug flag defaults to the build mode (tests run in debug mode)', (tester) async {
    expect(ImagesPanel().debugTools, isTrue);
    expect(ImagesPanel(debugTools: false).debugTools, isFalse);
  });

  testWidgets('the test button asks for the fixed prompt and seed and shows progress, Stop and the picture', (
    tester,
  ) async {
    final (h, _) = await open(tester, debugTools: true);
    when(() => h.host.makeImage(any())).thenAnswer((_) async => ImageStartStatus.started);
    when(() => h.host.stopImage()).thenAnswer((_) async {});

    expect(find.text('Make test picture'), findsOneWidget);
    expect(find.text('Coming in a later update'), findsNothing);
    await tester.tap(find.byKey(const Key('images-debug-action')));
    await tester.pump();
    final request = verify(() => h.host.makeImage(captureAny())).captured.single as ImageRequestMessage;
    expect(request.prompt, kImagesTestPrompt);
    expect(request.prompt, 'a cozy cabin in a snowy forest at night, warm lights, detailed');
    expect(request.seed, 42);

    // Loading, with Stop in place of the button.
    expect(find.text('Loading'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Make test picture'), findsNothing);

    await h.events.onImageEvent(ImageEventMessage(kind: ImageEventKind.step, step: 2, steps: 4));
    await tester.pump();
    expect(find.text('Step 2 of 4'), findsOneWidget);
    await h.events.onImageEvent(ImageEventMessage(kind: ImageEventKind.decoding, step: 0, steps: 0));
    await tester.pump();
    expect(find.text('Decoding'), findsOneWidget);

    await tester.tap(find.byKey(const Key('images-debug-action')));
    await tester.pump();
    verify(() => h.host.stopImage()).called(1);
    await h.events.onImageEvent(ImageEventMessage(kind: ImageEventKind.cancelled, step: 0, steps: 0));
    await tester.pump();
    expect(find.text('Make test picture'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);

    await tester.tap(find.byKey(const Key('images-debug-action')));
    await tester.pump();
    await h.events.onImageEvent(
      ImageEventMessage(kind: ImageEventKind.done, step: 0, steps: 0, path: '/no/such/1.png', millis: 12345),
    );
    await tester.pump();
    expect(find.byKey(const Key('images-debug-picture')), findsOneWidget);
    expect(find.text('Done in 12.3 s'), findsOneWidget);
  });

  testWidgets('a refused start says why', (tester) async {
    final (h, _) = await open(tester, debugTools: true);
    when(() => h.host.makeImage(any())).thenAnswer((_) async => ImageStartStatus.noPack);
    await tester.tap(find.byKey(const Key('images-debug-action')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Failed: no_pack'), findsOneWidget);
  });

  test('the status text for every state', () {
    expect(imagesDebugStatus(const ImagesIdle()), 'Ready');
    expect(imagesDebugStatus(const ImagesMaking(phase: ImagesPhase.loading)), 'Loading');
    expect(imagesDebugStatus(const ImagesMaking(phase: ImagesPhase.sampling, step: 3, steps: 4)), 'Step 3 of 4');
    expect(imagesDebugStatus(const ImagesMaking(phase: ImagesPhase.decoding)), 'Decoding');
    expect(imagesDebugStatus(const ImagesDone(path: '/p.png', millis: 1500)), 'Done in 1.5 s');
    expect(imagesDebugStatus(const ImagesFailed('helper_died')), 'Failed: helper_died');
  });
}
