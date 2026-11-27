// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:meta/meta.dart';

import '../json_util.dart';

@immutable
class ClipboardSettings {
  const ClipboardSettings({this.history = true, this.expiryMinutes = 60, this.maxItems = 30, this.recentChip = true});

  factory ClipboardSettings.fromJson(Json j) => ClipboardSettings(
    history: jBool(j, 'history', true),
    expiryMinutes: jInt(j, 'expiryMinutes', 60).clamp(1, 7 * 24 * 60),
    maxItems: jInt(j, 'maxItems', 30).clamp(5, 100),
    recentChip: jBool(j, 'recentChip', true),
  );

  final bool history;

  /// Unpinned items are deleted after this long.
  final int expiryMinutes;
  final int maxItems;

  /// Show a "paste recent copy" chip in the suggestion bar for 60 s.
  final bool recentChip;

  Json toJson() => {'history': history, 'expiryMinutes': expiryMinutes, 'maxItems': maxItems, 'recentChip': recentChip};

  ClipboardSettings copyWith({bool? history, int? expiryMinutes, int? maxItems, bool? recentChip}) => ClipboardSettings(
    history: history ?? this.history,
    expiryMinutes: expiryMinutes ?? this.expiryMinutes,
    maxItems: maxItems ?? this.maxItems,
    recentChip: recentChip ?? this.recentChip,
  );
}
