// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 4-B owns this section (add optional fields with defaults only).
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class JapaneseSettings {
  const JapaneseSettings({this.flickOnly = false, this.halfWidthSpace = false});

  factory JapaneseSettings.fromJson(Json j) =>
      JapaneseSettings(flickOnly: jBool(j, 'flickOnly', false), halfWidthSpace: jBool(j, 'halfWidthSpace', false));

  /// 12-key: flick only, no multi-tap cycling (tapping あ twice types ああ, not い).
  final bool flickOnly;

  /// Space types a half-width space when nothing is composing (the default is a full-width one).
  final bool halfWidthSpace;

  Json toJson() => {'flickOnly': flickOnly, 'halfWidthSpace': halfWidthSpace};

  JapaneseSettings copyWith({bool? flickOnly, bool? halfWidthSpace}) =>
      JapaneseSettings(flickOnly: flickOnly ?? this.flickOnly, halfWidthSpace: halfWidthSpace ?? this.halfWidthSpace);
}
