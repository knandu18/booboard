// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/foundation.dart';

/// BooBoard's logger.
///
/// PRIVACY RULE: never pass typed text, suggestions, clipboard content or
/// anything derived from user input. Log events, sizes and timings only.
/// Release builds print nothing.
abstract final class BooBoardLog {
  static void d(String tag, String message) {
    if (kReleaseMode) return;
    debugPrint('[$tag] $message');
  }

  static void w(String tag, String message, [Object? error]) {
    if (kReleaseMode) return;
    debugPrint('[$tag] WARN $message${error == null ? '' : ' ($error)'}');
  }
}
