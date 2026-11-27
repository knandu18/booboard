// SPDX-License-Identifier: GPL-3.0-or-later
//
// Live state of the modes: the height bar, drag previews for the floating keyboard and the height
// handle, and the settings writes that end a drag. The frame paints [plan]; during a drag the
// controller also sends the same layout to Kotlin, so the window follows the finger.
import 'dart:async';
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import '../../core/log.dart';
import '../../settings/booboard_settings.dart';
import '../keyboard_session.dart';
import '../panels/keyboard_panel.dart';
import 'mode_geometry.dart';
import 'modes_plan.dart';

class ModesController extends ChangeNotifier {
  KeyboardSession? _session;
  FrameInfo? _info;
  bool _resizing = false;
  double? _previewScale;
  Rect? _previewRect;

  /// Set when a drag was written to settings. The previews stay until the frame sees the new settings.
  bool _awaitingSettings = false;

  double? _heightDragStart;
  Rect? _rectDragStart;

  /// True while the height bar is open.
  bool get resizing => _resizing;

  /// The frame's latest inputs, or null before the first frame.
  FrameInfo? get info => _info;

  void attach(KeyboardSession session) => _session = session;

  /// Called from the frame's build. Drops the previews once the settings they wrote are in.
  void observe(FrameInfo info) {
    _info = info;
    if (_awaitingSettings) {
      _awaitingSettings = false;
      _previewScale = null;
      _previewRect = null;
    }
  }

  /// The layout for the current settings and previews.
  ModesPlan? get plan {
    final i = _info;
    if (i == null) return null;
    return planModes(
      info: i,
      modes: i.settings.modes,
      resizing: _resizing,
      previewScale: _previewScale,
      previewRect: _previewRect,
    );
  }

  double? get previewScale => _previewScale;

  // ---- Height bar -----------------------------------------------------------

  void startResize() {
    _resizing = true;
    _changed();
  }

  void endResize() {
    _resizing = false;
    _changed();
  }

  void heightDragStart() {
    _heightDragStart = plan?.keyboardH;
  }

  /// [dy] is the total vertical travel since the drag started; dragging up makes the keyboard taller.
  void heightDragUpdate(double dy) {
    final start = _heightDragStart;
    final i = _info;
    if (start == null || i == null) return;
    final scale = heightScaleFor(
      h: start - dy,
      naturalH: i.contentHeight,
      currentScale: currentScaleOf(i),
      stripH: _strip,
    );
    _previewScale = scale;
    _changed();
  }

  void heightDragEnd() {
    final start = _heightDragStart;
    _heightDragStart = null;
    if (start == null) return;
    final scale = _previewScale;
    if (scale != null) commitScale(scale);
  }

  /// Writes the row scale for the current orientation. Used by the height bar and Reset.
  void commitScale(double scale) {
    final session = _session;
    final i = _info;
    if (session == null || i == null) return;
    final landscape = i.landscape;
    _write(
      (s) => s.copyWith(
        appearance: landscape
            ? s.appearance.copyWith(landscapeHeightScale: scale)
            : s.appearance.copyWith(heightScale: scale),
      ),
      sections: [SettingsSection.appearance],
    );
    _previewScale = scale;
    _awaitingSettings = true;
    _changed();
  }

  void resetHeight() => commitScale(1.0);

  // ---- Floating keyboard ----------------------------------------------------

  void rectDragStart() {
    _rectDragStart = plan?.floating;
  }

  /// [dx], [dy]: total travel since the drag started. A move drag keeps the size; the width grip
  /// changes the width and the height follows the keys.
  void rectDragMove(double dx, double dy) {
    final start = _rectDragStart;
    final p = plan;
    if (start == null || p == null) return;
    final r = start.shift(Offset(dx, dy));
    _previewRect = snapFloatingRect(
      clampRectToWindow(r, windowW: p.screenW, windowH: p.floatAreaH),
      windowW: p.screenW,
      windowH: p.floatAreaH,
    );
    _changed();
  }

  void rectWidthDrag(double dx) {
    final start = _rectDragStart;
    final p = plan;
    if (start == null || p == null) return;
    final w = (start.width + dx).clamp(kMinFloatingWidth * p.screenW, p.screenW).toDouble();
    _previewRect = clampRectToWindow(
      Rect.fromLTWH(start.left, start.top, w, start.height),
      windowW: p.screenW,
      windowH: p.floatAreaH,
    );
    _changed();
  }

  /// Ends a floating drag: persists the position and width as fractions, so they survive rotation.
  void rectDragEnd() {
    final start = _rectDragStart;
    _rectDragStart = null;
    final r = _previewRect;
    final p = plan;
    if (start == null || r == null || p == null) return;
    final snapped = snapFloatingRect(r, windowW: p.screenW, windowH: p.floatAreaH);
    _write(
      (s) => s.copyWith(
        modes: s.modes.copyWith(
          floatingX: floatingXFraction(snapped, windowW: p.screenW),
          floatingY: floatingYFraction(snapped, windowH: p.floatAreaH),
          floatingWidth: floatingWidthFraction(snapped.width / p.screenW),
        ),
      ),
      sections: [SettingsSection.modes],
    );
    _previewRect = snapped;
    _awaitingSettings = true;
    _changed();
  }

  // ---- Mode settings --------------------------------------------------------

  void updateModes(ModeSettings Function(ModeSettings current) change) =>
      _write((s) => s.copyWith(modes: change(s.modes)), sections: [SettingsSection.modes]);

  // ---- Plumbing -------------------------------------------------------------

  static const double _strip = 44;

  void _write(BooBoardSettings Function(BooBoardSettings current) change, {required List<String> sections}) {
    final session = _session;
    if (session == null) return;
    try {
      unawaited(
        session.services.settings
            .update(change, sections: sections)
            .catchError((Object e) => BooBoardLog.w('Modes', 'settings write failed', e.runtimeType)),
      );
    } on Object catch (e) {
      BooBoardLog.w('Modes', 'settings write failed', e.runtimeType);
    }
  }

  void _changed() {
    notifyListeners();
    _pushWindow();
  }

  /// Sends the window layout straight away, for previews. The frame sends the same layout on rebuild.
  void _pushWindow() {
    final session = _session;
    final p = plan;
    if (session == null || p == null) return;
    try {
      unawaited(
        session.services.host
            .setWindowLayout(p.message)
            .catchError((Object e) => BooBoardLog.w('Modes', 'window layout failed', e.runtimeType)),
      );
    } on Object catch (e) {
      BooBoardLog.w('Modes', 'window layout failed', e.runtimeType);
    }
  }
}
