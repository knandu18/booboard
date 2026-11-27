// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/keyboard/view/keyboard_metrics.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

WindowMetricsMessage _metrics({required bool landscape, required int smallestDp}) => WindowMetricsMessage(
  screenWidthPx: 2400,
  screenHeightPx: 1080,
  density: 2.625,
  navigationBarInsetPx: 0,
  isLandscape: landscape,
  smallestScreenWidthDp: smallestDp,
  fontScale: 1,
  isNightMode: false,
);

void main() {
  test('compact only for landscape phones', () {
    expect(KeyboardMetrics.isCompact(_metrics(landscape: true, smallestDp: 411)), isTrue);
    expect(KeyboardMetrics.isCompact(_metrics(landscape: false, smallestDp: 411)), isFalse);
    expect(KeyboardMetrics.isCompact(_metrics(landscape: true, smallestDp: 800)), isFalse);
    expect(KeyboardMetrics.isCompact(null), isFalse);
  });

  test('split needs a tablet, a 600 dp keyboard and the setting', () {
    const s = BooBoardSettings();
    final tablet = _metrics(landscape: true, smallestDp: 800);
    expect(KeyboardMetrics.isSplit(s, 900, tablet), isTrue);
    expect(KeyboardMetrics.isSplit(s, 599, tablet), isFalse);
    expect(KeyboardMetrics.isSplit(s, 900, _metrics(landscape: true, smallestDp: 411)), isFalse, reason: 'phone');
    expect(KeyboardMetrics.isSplit(s, 900, null), isFalse);
    final off = s.copyWith(modes: s.modes.copyWith(splitOnWideScreens: false));
    expect(KeyboardMetrics.isSplit(off, 900, tablet), isFalse);
  });

  test('compact caps each row at 44 dp, so the window is 4 x 44 dp of keys', () {
    const s = BooBoardSettings();
    expect(KeyboardMetrics.rowsHeight(s, landscape: true), 4 * 56);
    expect(KeyboardMetrics.rowsHeight(s, landscape: true, compact: true), 4 * 44);
  });
}
