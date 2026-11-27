// SPDX-License-Identifier: GPL-3.0-or-later
//
// Tonal surface levels and elevation tokens.

/// Elevation levels in dp (Material 3).
abstract final class BooBoardElevation {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
  static const double level5 = 12;
}

/// Tonal-surface ladder, lowest to highest container role, as named in
/// `ColorScheme`.
enum TonalLevel { lowest, low, base, high, highest }

/// Android system palette tone numbers, in the order delivered by the platform.
const List<int> androidTones = [0, 10, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];
