// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class TypingSettings {
  const TypingSettings({
    this.autoCorrect = true,
    this.autoCapitalize = true,
    this.doubleSpacePeriod = true,
    this.smartPunctuation = true,
    this.showSuggestions = true,
    this.nextWordPrediction = true,
    this.emojiSuggestions = true,
    this.blockOffensiveWords = true,
    this.keyPopups = true,
    this.longPressDelayMs = 300,
    this.numberRow = false,
    this.hintLabels = true,
    this.lowercaseLabels = false,
  });

  factory TypingSettings.fromJson(Json j) => TypingSettings(
    autoCorrect: jBool(j, 'autoCorrect', true),
    autoCapitalize: jBool(j, 'autoCapitalize', true),
    doubleSpacePeriod: jBool(j, 'doubleSpacePeriod', true),
    smartPunctuation: jBool(j, 'smartPunctuation', true),
    showSuggestions: jBool(j, 'showSuggestions', true),
    nextWordPrediction: jBool(j, 'nextWordPrediction', true),
    emojiSuggestions: jBool(j, 'emojiSuggestions', true),
    blockOffensiveWords: jBool(j, 'blockOffensiveWords', true),
    keyPopups: jBool(j, 'keyPopups', true),
    longPressDelayMs: jInt(j, 'longPressDelayMs', 300).clamp(150, 1000),
    numberRow: jBool(j, 'numberRow', false),
    hintLabels: jBool(j, 'hintLabels', true),
    lowercaseLabels: jBool(j, 'lowercaseLabels', false),
  );

  final bool autoCorrect;
  final bool autoCapitalize;
  final bool doubleSpacePeriod;
  final bool smartPunctuation;
  final bool showSuggestions;
  final bool nextWordPrediction;
  final bool emojiSuggestions;
  final bool blockOffensiveWords;
  final bool keyPopups;
  final int longPressDelayMs;
  final bool numberRow;
  final bool hintLabels;
  final bool lowercaseLabels;

  Json toJson() => {
    'autoCorrect': autoCorrect,
    'autoCapitalize': autoCapitalize,
    'doubleSpacePeriod': doubleSpacePeriod,
    'smartPunctuation': smartPunctuation,
    'showSuggestions': showSuggestions,
    'nextWordPrediction': nextWordPrediction,
    'emojiSuggestions': emojiSuggestions,
    'blockOffensiveWords': blockOffensiveWords,
    'keyPopups': keyPopups,
    'longPressDelayMs': longPressDelayMs,
    'numberRow': numberRow,
    'hintLabels': hintLabels,
    'lowercaseLabels': lowercaseLabels,
  };

  TypingSettings copyWith({
    bool? autoCorrect,
    bool? autoCapitalize,
    bool? doubleSpacePeriod,
    bool? smartPunctuation,
    bool? showSuggestions,
    bool? nextWordPrediction,
    bool? emojiSuggestions,
    bool? blockOffensiveWords,
    bool? keyPopups,
    int? longPressDelayMs,
    bool? numberRow,
    bool? hintLabels,
    bool? lowercaseLabels,
  }) => TypingSettings(
    autoCorrect: autoCorrect ?? this.autoCorrect,
    autoCapitalize: autoCapitalize ?? this.autoCapitalize,
    doubleSpacePeriod: doubleSpacePeriod ?? this.doubleSpacePeriod,
    smartPunctuation: smartPunctuation ?? this.smartPunctuation,
    showSuggestions: showSuggestions ?? this.showSuggestions,
    nextWordPrediction: nextWordPrediction ?? this.nextWordPrediction,
    emojiSuggestions: emojiSuggestions ?? this.emojiSuggestions,
    blockOffensiveWords: blockOffensiveWords ?? this.blockOffensiveWords,
    keyPopups: keyPopups ?? this.keyPopups,
    longPressDelayMs: longPressDelayMs ?? this.longPressDelayMs,
    numberRow: numberRow ?? this.numberRow,
    hintLabels: hintLabels ?? this.hintLabels,
    lowercaseLabels: lowercaseLabels ?? this.lowercaseLabels,
  );
}
