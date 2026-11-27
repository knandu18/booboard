// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/keyboard/modes/modes_plan.dart';
import 'package:booboard/src/keyboard/panels/keyboard_panel.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:booboard/src/theme/theme_resolver.dart';

FrameInfo infoFor({
  BooBoardSettings settings = const BooBoardSettings(),
  Size screen = const Size(360, 700),
  bool landscape = false,
  double inset = 0,
}) {
  final theme = resolveKeyboardTheme(
    appearance: settings.appearance,
    systemColors: null,
    systemDark: false,
    disableAnimations: true,
  );
  return FrameInfo(
    settings: settings,
    theme: theme,
    screenSize: screen,
    landscape: landscape,
    bottomInset: inset,
    contentHeight: 44 + 4 * 56,
  );
}

ModesPlan plan(
  FrameInfo info, {
  ModeSettings modes = const ModeSettings(),
  bool resizing = false,
  double? previewScale,
  Rect? previewRect,
}) => planModes(info: info, modes: modes, resizing: resizing, previewScale: previewScale, previewRect: previewRect);

void main() {
  test('the default plan is the docked full-width keyboard the app had before modes', () {
    final p = plan(infoFor(inset: 24));
    expect(p.layout, ModeLayout.docked);
    expect(p.isPlainDocked, isTrue);
    expect(p.keyboardW, 360);
    expect(p.windowH, 268 + 24, reason: 'content plus the bottom inset');
    expect(p.message.mode, WindowMode.docked);
    expect(p.message.heightDp, 292);
    expect(p.message.floatingRect, isNull);
  });

  test('the height bar adds a 48 dp row above the keyboard', () {
    final p = plan(infoFor(inset: 24), resizing: true);
    expect(p.topBar, isTrue);
    expect(p.isPlainDocked, isFalse);
    expect(p.windowH, 268 + 48 + 24);
  });

  test('one-handed: 80% wide on the chosen side, docked window of the same height', () {
    final info = infoFor(
      settings: const BooBoardSettings(modes: ModeSettings(oneHanded: OneHandedMode.left)),
    );
    final p = plan(info, modes: const ModeSettings(oneHanded: OneHandedMode.left));
    expect(p.layout, ModeLayout.oneHanded);
    expect(p.keyboardW, closeTo(288, 1e-9));
    expect(p.windowH, 268);
    expect(p.message.mode, WindowMode.docked);
    expect(p.isPlainDocked, isFalse);
  });

  test('tablets: split by default keeps the full width; without split the keyboard is centred at 600 dp', () {
    final split = plan(infoFor(screen: const Size(800, 280)));
    expect(split.keyboardW, 800);
    expect(split.isPlainDocked, isTrue);

    const noSplit = ModeSettings(splitOnWideScreens: false);
    final centred = plan(infoFor(screen: const Size(800, 280)), modes: noSplit);
    expect(centred.keyboardW, 600);
    expect(centred.wide, isTrue);
    expect(centred.isPlainDocked, isFalse);
  });

  test('floating: the window is 85% of the screen and the rect is placed by the free-space fractions', () {
    const modes = ModeSettings(floating: true, floatingX: 0.5, floatingY: 0.5, floatingWidth: 0.8);
    final p = plan(
      infoFor(settings: const BooBoardSettings(modes: modes)),
      modes: modes,
    );
    expect(p.layout, ModeLayout.floating);
    expect(p.windowH, closeTo(595, 1e-9));
    final r = p.floating!;
    expect(r.width, closeTo(288, 1e-9));
    expect(r.height, closeTo(268 * 0.8 + 48, 1e-9), reason: 'keys keep their aspect; the bar adds 48 dp');
    expect(r.left, closeTo(36, 1e-9));
    expect(r.top, closeTo((595 - r.height) / 2, 1e-9));
    expect(p.message.mode, WindowMode.floating);
    expect(p.message.heightDp, closeTo(595, 1e-9));
    expect(p.message.floatingRect!.width, closeTo(288, 1e-9));
  });

  test('floating keeps the card above the navigation bar, even at the bottom edge', () {
    const modes = ModeSettings(floating: true, floatingY: 1, floatingWidth: 0.8);
    final p = plan(
      infoFor(settings: const BooBoardSettings(modes: modes), inset: 48),
      modes: modes,
    );
    expect(p.windowH, closeTo(595, 1e-9));
    expect(p.bottomInset, 48);
    expect(p.floatAreaH, closeTo(595 - 48, 1e-9));
    expect(p.floating!.bottom, closeTo(595 - 48, 1e-9), reason: 'the bottom row must not sit under the system buttons');
    final dragged = plan(
      infoFor(settings: const BooBoardSettings(modes: modes), inset: 48),
      modes: modes,
      previewRect: const Rect.fromLTWH(0, 900, 288, 0),
    );
    expect(dragged.floating!.bottom, closeTo(595 - 48, 1e-9));
  });

  test('a previewed height changes the keyboard and the window together', () {
    final p = plan(infoFor(inset: 10), previewScale: 1.5);
    expect(p.keyboardH, closeTo(380, 1e-9));
    expect(p.windowH, closeTo(390, 1e-9));
    expect(p.scale, 1.5);
  });

  test('a previewed floating rect is clamped to the window and keeps its keys aspect', () {
    const modes = ModeSettings(floating: true);
    final info = infoFor(settings: const BooBoardSettings(modes: modes));
    final p = plan(info, modes: modes, previewRect: const Rect.fromLTWH(400, -30, 216, 0));
    final r = p.floating!;
    expect(r.width, closeTo(216, 1e-9));
    expect(r.left, closeTo(360 - 216, 1e-9));
    expect(r.top, 0);
    expect(r.height, closeTo(268 * 0.6 + 48, 1e-9));
  });

  test('landscape uses its own row scale', () {
    final info = infoFor(
      settings: const BooBoardSettings(appearance: AppearanceSettings(landscapeHeightScale: 0.6)),
      landscape: true,
    );
    expect(currentScaleOf(info), 0.6);
    final p = plan(info);
    expect(p.scale, 0.6);
  });

  test('the window message for a docked plan matches what the keyboard app would send', () {
    final p = plan(infoFor(inset: 0));
    expect(p.message.heightDp, 268);
  });
}
