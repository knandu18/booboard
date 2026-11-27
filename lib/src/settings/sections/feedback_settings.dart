// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class FeedbackSettings {
  // Haptics are off until the user turns them on (user decision 2026-11-24).
  const FeedbackSettings({this.haptics = false, this.hapticStrength = 0.5, this.sounds = false, this.soundVolume = -1});

  factory FeedbackSettings.fromJson(Json j) => FeedbackSettings(
    haptics: jBool(j, 'haptics', false),
    hapticStrength: jDouble(j, 'hapticStrength', 0.5).clamp(0.0, 1.0),
    sounds: jBool(j, 'sounds', false),
    soundVolume: jDouble(j, 'soundVolume', -1).clamp(-1.0, 1.0),
  );

  final bool haptics;

  /// 0..1
  final double hapticStrength;
  final bool sounds;

  /// 0..1, or -1 = system default.
  final double soundVolume;

  Json toJson() => {'haptics': haptics, 'hapticStrength': hapticStrength, 'sounds': sounds, 'soundVolume': soundVolume};

  FeedbackSettings copyWith({bool? haptics, double? hapticStrength, bool? sounds, double? soundVolume}) =>
      FeedbackSettings(
        haptics: haptics ?? this.haptics,
        hapticStrength: hapticStrength ?? this.hapticStrength,
        sounds: sounds ?? this.sounds,
        soundVolume: soundVolume ?? this.soundVolume,
      );
}
