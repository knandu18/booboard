// SPDX-License-Identifier: GPL-3.0-or-later
//
// Spatial model: how likely a finger that landed at a point meant each key.
// A 2-D Gaussian around every key centre, sigma = 0.45 of the key's size.
// Costs are negative log-likelihoods up to a constant: (dx^2 + dy^2) / (2 s^2)
// with dx, dy measured in key widths/heights.
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import '../contracts.dart';
import '../dictionary/text_fold.dart';

/// Gaussian sigma as a fraction of the key size.
const double kSpatialSigma = 0.45;
const double _kTwoSigmaSq = 2 * kSpatialSigma * kSpatialSigma;

/// Keys whose cost exceeds this are not considered possible intended keys.
const double kNeighbourCostLimit = 6.0;

class _Key {
  _Key(this.char, Rect rect) : center = rect.center, width = rect.width, height = rect.height;

  final int char;
  final Offset center;
  final double width;
  final double height;

  double costFrom(Offset p) {
    final dx = (p.dx - center.dx) / width;
    final dy = (p.dy - center.dy) / height;
    return (dx * dx + dy * dy) / _kTwoSigmaSq;
  }
}

/// Possible intended characters for one typed position, cheapest first is not
/// guaranteed. Always contains the typed character itself.
class PositionCandidates {
  PositionCandidates(this.chars, this.costs, this.ownCost);

  final Int32List chars;
  final Float64List costs;

  /// Cost of the typed character itself at this position.
  final double ownCost;
}

class SpatialModel {
  SpatialModel(this._keys, this.geometry);

  /// Used before the real geometry is known: a standard QWERTY grid.
  factory SpatialModel.qwerty() => SpatialModel.fromGeometry(_qwertyGeometry());

  factory SpatialModel.fromGeometry(KeyboardGeometry geometry) {
    final keys = <int, _Key>{};
    geometry.keys.forEach((label, rect) {
      if (label.runes.length != 1 || rect.isEmpty) return;
      final lower = label.toLowerCase();
      if (lower.runes.length != 1) return;
      final cp = lower.runes.first;
      if (!_isKeyChar(cp)) return;
      keys[cp] = _Key(cp, rect);
    });
    return SpatialModel(keys, geometry);
  }

  final Map<int, _Key> _keys;
  final KeyboardGeometry geometry;

  bool get isEmpty => _keys.isEmpty;

  static bool _isKeyChar(int cp) {
    if (cp == 0x27 || cp == 0x2d) return true;
    final ch = String.fromCharCode(cp);
    return ch.toLowerCase() != ch.toUpperCase();
  }

  /// Key position of [char] (folded), if it is on the layout.
  Offset? centerOf(int char) => _keys[char]?.center ?? _keys[baseRune(char)]?.center;

  /// Cost of typing at [tap] when [char] was meant (large when far / unknown).
  double costAt(Offset tap, int char) {
    final key = _keys[char] ?? _keys[baseRune(char)];
    if (key == null) return 99;
    return key.costFrom(tap);
  }

  /// Candidate intended keys for each typed char. [taps] holds a point per
  /// character when known (null entries fall back to the key centre).
  List<PositionCandidates> positions(List<int> typed, List<Offset?> taps) {
    final out = <PositionCandidates>[];
    for (var i = 0; i < typed.length; i++) {
      final c = typed[i];
      final ownKey = _keys[c] ?? _keys[baseRune(c)];
      final point = taps.length > i ? taps[i] : null;
      final origin = point ?? ownKey?.center;
      if (origin == null || ownKey == null) {
        // Off-layout character (digit, symbol, other script): exact only.
        out.add(PositionCandidates(Int32List.fromList([c]), Float64List.fromList([0]), 0));
        continue;
      }
      final chars = <int>[];
      final costs = <double>[];
      var own = ownKey.costFrom(origin);
      for (final key in _keys.values) {
        final cost = key.char == ownKey.char ? own : key.costFrom(origin);
        if (key.char == ownKey.char || cost <= kNeighbourCostLimit) {
          chars.add(key.char);
          costs.add(cost);
        }
      }
      // The typed char itself may be an accented/other form of the key char.
      if (ownKey.char != c) {
        chars.add(c);
        costs.add(own);
      }
      own = own < 0 ? 0 : own;
      out.add(PositionCandidates(Int32List.fromList(chars), Float64List.fromList(costs), own));
    }
    return out;
  }
}

KeyboardGeometry _qwertyGeometry() {
  const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
  const offsets = [0.0, 0.5, 1.5];
  const w = 36.0;
  const h = 48.0;
  final keys = <String, Rect>{};
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      keys[rows[r][c]] = Rect.fromLTWH((offsets[r] + c) * w, r * h, w - 2, h - 4);
    }
  }
  return KeyboardGeometry(layoutId: 'default-qwerty', size: const Size(360, 3 * h), keys: keys);
}
