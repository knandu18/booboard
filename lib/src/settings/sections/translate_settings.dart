// SPDX-License-Identifier: GPL-3.0-or-later
//
// Wave 3-T owns this section (add optional fields with defaults only).
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class TranslateSettings {
  const TranslateSettings({this.enabled = true, this.from = 'en', this.to = 'es'});

  factory TranslateSettings.fromJson(Json j) =>
      TranslateSettings(enabled: jBool(j, 'enabled', true), from: jString(j, 'from', 'en'), to: jString(j, 'to', 'es'));

  /// Shows the Translate toolbar button and the "Translate" selection chip.
  final bool enabled;

  /// Last language pair used in the translate panel.
  final String from;
  final String to;

  Json toJson() => {'enabled': enabled, 'from': from, 'to': to};

  TranslateSettings copyWith({bool? enabled, String? from, String? to}) =>
      TranslateSettings(enabled: enabled ?? this.enabled, from: from ?? this.from, to: to ?? this.to);
}
