// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 4-A owns this section (add optional fields with defaults only).
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class ChineseSettings {
  const ChineseSettings({this.traditional = false, this.fuzzyPinyin = true});

  factory ChineseSettings.fromJson(Json j) =>
      ChineseSettings(traditional: jBool(j, 'traditional', false), fuzzyPinyin: jBool(j, 'fuzzyPinyin', true));

  /// Output Traditional characters (OpenCC conversion of the Simplified candidates).
  final bool traditional;

  /// Accept common pinyin confusions (z/zh, c/ch, s/sh, n/l, an/ang, en/eng, in/ing).
  final bool fuzzyPinyin;

  Json toJson() => {'traditional': traditional, 'fuzzyPinyin': fuzzyPinyin};

  ChineseSettings copyWith({bool? traditional, bool? fuzzyPinyin}) =>
      ChineseSettings(traditional: traditional ?? this.traditional, fuzzyPinyin: fuzzyPinyin ?? this.fuzzyPinyin);
}
