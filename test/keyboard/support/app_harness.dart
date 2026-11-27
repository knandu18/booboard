// SPDX-License-Identifier: GPL-3.0-or-later
//
// Builds a KeyboardApp with fake services for widget tests.
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/bridge/ime_events.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/core/keyboard_services.dart';
import 'package:booboard/src/core/secure_blob_store.dart';
import 'package:booboard/src/engine/in_memory_lexicon.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/layout/layout_engine.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/keyboard/layout/layout_repository.dart';
import 'package:booboard/src/keyboard/view/keyboard_view.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:booboard/src/settings/settings_store.dart';

import '../../support/fake_editor.dart';
import 'fakes.dart';

class MockImeHost extends Mock implements ImeHostApi {}

class MockPlatformHost extends Mock implements PlatformHostApi {}

void registerKeyboardFallbacks() {
  registerFallbackValue(WindowLayoutMessage(mode: WindowMode.docked, heightDp: 0));
  registerFallbackValue(
    FeedbackConfigMessage(hapticsEnabled: true, hapticStrength: 0.5, soundsEnabled: false, soundVolume: -1),
  );
  registerFallbackValue(HapticKind.keyTap);
  registerFallbackValue(KeySoundKind.standard);
}

EditorInfoMessage editorInfo({
  int inputType = AndroidInputType.classText,
  int imeOptions = 0,
  String? packageName,
  int initialCapsMode = 0,
}) => EditorInfoMessage(
  inputType: inputType,
  imeOptions: imeOptions,
  actionId: 0,
  fieldId: 1,
  initialSelStart: 0,
  initialSelEnd: 0,
  initialCapsMode: initialCapsMode,
  packageName: packageName,
);

class AppHarness {
  AppHarness({BooBoardSettings settings = const BooBoardSettings(), String text = ''}) {
    registerKeyboardFallbacks();
    editor = FakeEditor(text: text);
    host = MockImeHost();
    platform = MockPlatformHost();
    when(() => host.performHaptic(any())).thenAnswer((_) async {});
    when(() => host.playKeySound(any())).thenAnswer((_) async {});
    when(() => host.setWindowLayout(any())).thenAnswer((_) async {});
    when(() => host.setFeedbackConfig(any())).thenAnswer((_) async {});
    when(() => host.setSecureWindow(any())).thenAnswer((_) async {});
    when(() => host.showInputMethodPicker()).thenAnswer((_) async {});
    when(() => host.openSettings(any())).thenAnswer((_) async {});
    when(() => host.switchToNextInputMethod(any())).thenAnswer((_) async => true);
    when(() => host.setNavigationBarStyle(any())).thenAnswer((_) async {});
    when(() => host.getAppLabel(any())).thenAnswer((_) async => null);
    when(() => platform.getSystemColors()).thenAnswer((_) async => null);
    when(() => platform.getAppInfo()).thenAnswer(
      (_) async => AppInfoMessage(
        packageName: 'app.booboard.keyboard',
        versionName: '0',
        versionCode: 0,
        sdkInt: 37,
        isDebugBuild: true,
      ),
    );
    events = ImeEvents();
    editor.onSelectionChanged = (m) => unawaited(events.onUpdateSelection(m));
    store = SettingsStore.memory(settings);
    services = KeyboardServices(
      input: editor,
      host: host,
      platform: platform,
      events: events,
      settings: store,
      secureStore: InMemorySecureBlobStore(),
      packs: DiskPackRepository(),
      lexicons: InMemoryLexiconSource({}),
      predictor: predictor,
      gestureDecoder: decoder,
    );
  }

  late final FakeEditor editor;
  late final MockImeHost host;
  late final MockPlatformHost platform;
  late final ImeEvents events;
  late final SettingsStore store;
  late final KeyboardServices services;
  final predictor = FakePredictor();
  final decoder = FakeGestureDecoder();

  /// Size of the test window in dp.
  static const Size window = Size(360, 700);

  Future<void> pump(
    WidgetTester tester, {
    KeyboardHooks hooks = const KeyboardHooks(),
    List<KeyboardFeature> features = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = window;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(KeyboardApp(services: services, hooks: hooks, features: features));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
  }

  /// Focus a field (like onStartInputView) and settle.
  Future<void> focus(WidgetTester tester, [EditorInfoMessage? info]) async {
    await events.onStartInputView(info ?? editorInfo(), false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Reads and parses `assets/layouts/<id>.json` synchronously.
KeyboardLayoutDef loadLayoutSync(String id) => LayoutVariants.parse(File('assets/layouts/$id.json').readAsStringSync());

/// Computes where keys are on screen, using the same engine as the app.
class KeyFinder {
  KeyFinder(this.tester, this.layout, {this.gap = 6});

  final WidgetTester tester;
  final KeyboardLayoutDef layout;
  final double gap;

  Rect get area => tester.getRect(find.byType(KeyboardKeysArea));

  LaidOutKeyboard get laid => KeyboardLayoutEngine.layout(layout, area.size, keyGap: gap);

  PlacedKey byOutput(String output) => laid.keys.firstWhere((k) => k.def.output == output && k.def.isCharacter);

  PlacedKey byType(KeyType type) => laid.keys.firstWhere((k) => k.def.type == type);

  Offset at(PlacedKey k) => area.topLeft + k.rect.center;

  Offset output(String o) => at(byOutput(o));

  Offset type(KeyType t) => at(byType(t));

  /// Keyboard-view coordinates (strip included) of a key's rect.
  Rect viewRect(PlacedKey k) => k.rect.shift(Offset(0, area.top));
}

LayoutRepository layoutRepo() => LayoutRepository(DiskPackRepository());
