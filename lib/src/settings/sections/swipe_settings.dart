// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class SwipeSettings {
  const SwipeSettings({
    this.enabled = true,
    this.showTrail = true,
    this.trailWidth = 6.0,
    this.trailFadeMs = 300,
    this.livePreview = true,
    this.spaceCursorControl = true,
    this.backspaceSwipeDelete = true,
  });

  factory SwipeSettings.fromJson(Json j) => SwipeSettings(
    enabled: jBool(j, 'enabled', true),
    showTrail: jBool(j, 'showTrail', true),
    trailWidth: jDouble(j, 'trailWidth', 6.0).clamp(2.0, 16.0),
    trailFadeMs: jInt(j, 'trailFadeMs', 300).clamp(0, 2000),
    livePreview: jBool(j, 'livePreview', true),
    spaceCursorControl: jBool(j, 'spaceCursorControl', true),
    backspaceSwipeDelete: jBool(j, 'backspaceSwipeDelete', true),
  );

  final bool enabled;
  final bool showTrail;
  final double trailWidth;
  final int trailFadeMs;
  final bool livePreview;
  final bool spaceCursorControl;
  final bool backspaceSwipeDelete;

  Json toJson() => {
    'enabled': enabled,
    'showTrail': showTrail,
    'trailWidth': trailWidth,
    'trailFadeMs': trailFadeMs,
    'livePreview': livePreview,
    'spaceCursorControl': spaceCursorControl,
    'backspaceSwipeDelete': backspaceSwipeDelete,
  };

  SwipeSettings copyWith({
    bool? enabled,
    bool? showTrail,
    double? trailWidth,
    int? trailFadeMs,
    bool? livePreview,
    bool? spaceCursorControl,
    bool? backspaceSwipeDelete,
  }) => SwipeSettings(
    enabled: enabled ?? this.enabled,
    showTrail: showTrail ?? this.showTrail,
    trailWidth: trailWidth ?? this.trailWidth,
    trailFadeMs: trailFadeMs ?? this.trailFadeMs,
    livePreview: livePreview ?? this.livePreview,
    spaceCursorControl: spaceCursorControl ?? this.spaceCursorControl,
    backspaceSwipeDelete: backspaceSwipeDelete ?? this.backspaceSwipeDelete,
  );
}
