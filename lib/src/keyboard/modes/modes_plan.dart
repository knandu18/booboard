// SPDX-License-Identifier: GPL-3.0-or-later
//
// One place that decides the window layout and the keyboard geometry for every mode, given the
// settings and any live preview (a drag in progress). The frame paints it and the controller sends
// the same layout to Kotlin during a drag, so the two never disagree.
import 'dart:ui' show Rect;

import 'package:meta/meta.dart';

import '../../bridge/messages.g.dart';
import '../../settings/booboard_settings.dart';
import '../panels/keyboard_panel.dart';
import '../view/keyboard_metrics.dart';
import 'mode_geometry.dart';

enum ModeLayout { docked, oneHanded, floating }

@immutable
class ModesPlan {
  const ModesPlan({
    required this.layout,
    required this.screenW,
    required this.keyboardW,
    required this.keyboardH,
    required this.naturalH,
    required this.topBar,
    required this.topH,
    required this.bottomInset,
    required this.windowH,
    required this.scale,
    required this.wide,
    this.floating,
  });

  final ModeLayout layout;

  /// IME window width and the keyboard width. Floating: the keyboard's rect width is [floating].
  final double screenW;
  final double keyboardW;

  /// Keyboard height at the effective scale (strip included), and the natural height it was laid out at.
  final double keyboardH;
  final double naturalH;

  /// Bar above the keyboard: the floating move bar, or the height bar while resizing.
  final bool topBar;
  final double topH;
  final double bottomInset;

  /// Total window height sent to Kotlin (docked: content plus inset; floating: the window H).
  final double windowH;

  /// Effective row scale (preview or settings), and whether the keyboard is centred on a tablet.
  final double scale;
  final bool wide;

  /// Floating only: the keyboard rect in window coordinates.
  final Rect? floating;

  /// Floating: the part of the window the card may use. The bottom inset (navigation bar) is left
  /// free, so the bottom row never sits under the system's buttons.
  double get floatAreaH => windowH - bottomInset;

  /// Whether this is the plain docked full-width layout the keyboard had before modes.
  bool get isPlainDocked => layout == ModeLayout.docked && !wide && !topBar && keyboardH == naturalH;

  WindowLayoutMessage get message {
    final r = floating;
    if (layout == ModeLayout.floating && r != null) {
      return WindowLayoutMessage(
        mode: WindowMode.floating,
        heightDp: windowH,
        floatingRect: RectMessage(left: r.left, top: r.top, width: r.width, height: r.height),
      );
    }
    return WindowLayoutMessage(mode: WindowMode.docked, heightDp: windowH);
  }
}

/// The row scale in use for [info]: landscape has its own.
double currentScaleOf(FrameInfo info) =>
    info.landscape ? info.settings.appearance.landscapeHeightScale : info.settings.appearance.heightScale;

/// Plans the layout. [previewScale] and [previewRect] come from a drag in progress; [resizing] is the
/// height bar. Without previews and modes this returns the docked layout the keyboard already has.
ModesPlan planModes({
  required FrameInfo info,
  required ModeSettings modes,
  required bool resizing,
  double? previewScale,
  Rect? previewRect,
}) {
  final screenW = info.screenSize.width;
  final screenH = info.screenSize.height;
  final s0 = currentScaleOf(info);
  final scale = previewScale ?? s0;
  final natural = info.contentHeight;
  final kbH = keyboardHeightFor(scale: scale, naturalH: natural, currentScale: s0, stripH: KeyboardMetrics.stripHeight);
  final floating = modes.floating;
  final topBar = resizing || floating;
  final topH = topBar ? kTopBarHeight : 0.0;

  if (floating) {
    final fw = previewRect != null
        ? floatingWidthFraction(previewRect.width / screenW)
        : floatingWidthFraction(modes.floatingWidth);
    final rectW = screenW * fw;
    final rectH = kbH * fw + topH;
    final inset = info.bottomInset;
    final windowH = floatingWindowHeight(screenH: screenH, contentH: kbH + topH + inset);
    final areaH = windowH - inset;
    final rect = previewRect == null
        ? floatingRect(
            windowW: screenW,
            windowH: areaH,
            width: rectW,
            height: rectH,
            x: modes.floatingX,
            y: modes.floatingY,
          )
        : clampRectToWindow(
            Rect.fromLTWH(previewRect.left, previewRect.top, rectW, rectH),
            windowW: screenW,
            windowH: areaH,
          );
    return ModesPlan(
      layout: ModeLayout.floating,
      screenW: screenW,
      keyboardW: screenW,
      keyboardH: kbH,
      naturalH: natural,
      topBar: topBar,
      topH: topH,
      bottomInset: inset,
      windowH: windowH,
      scale: scale,
      wide: false,
      floating: rect,
    );
  }

  final inset = info.bottomInset;
  final oneHanded = modes.oneHanded != OneHandedMode.off;
  final double keyboardW;
  if (oneHanded) {
    keyboardW = oneHandedWidth(screenW: screenW, fraction: modes.oneHandedWidth);
  } else if (screenW >= kWideScreenWidth && !modes.splitOnWideScreens) {
    keyboardW = kWideScreenWidth;
  } else {
    keyboardW = screenW;
  }
  return ModesPlan(
    layout: oneHanded ? ModeLayout.oneHanded : ModeLayout.docked,
    screenW: screenW,
    keyboardW: keyboardW,
    keyboardH: kbH,
    naturalH: natural,
    topBar: topBar,
    topH: topH,
    bottomInset: inset,
    windowH: kbH + topH + inset,
    scale: scale,
    wide: !oneHanded && keyboardW < screenW,
  );
}
