// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class VoiceSettings {
  const VoiceSettings({this.enabled = true, this.modelId = ''});

  factory VoiceSettings.fromJson(Json j) =>
      VoiceSettings(enabled: jBool(j, 'enabled', true), modelId: _packId(jString(j, 'modelId', '')));

  /// Before Wave 3 the setting held a model size ('base', 'small') for a bundled model; models are packs
  /// now, so those old values mean "automatic".
  static String _packId(String v) => v == 'base' || v == 'small' ? '' : v;

  final bool enabled;

  /// Id of the installed voice pack to use ('voice-parakeet-en', ...); empty = the first installed
  /// English voice pack. Voice typing works in English only. Models ship only as packs (Wave 3 decision).
  final String modelId;

  Json toJson() => {'enabled': enabled, 'modelId': modelId};

  VoiceSettings copyWith({bool? enabled, String? modelId}) =>
      VoiceSettings(enabled: enabled ?? this.enabled, modelId: modelId ?? this.modelId);
}
