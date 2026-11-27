// SPDX-License-Identifier: GPL-3.0-or-later
//
// Layout engine: turns a [KeyboardLayoutDef] plus a size into key rectangles.
// Coordinates are keyboard-local logical pixels, origin at the top-left of the
// key area (the suggestion strip is not part of it).
//
// Two optional shapes (Wave 2-E):
//  * split: wide screens. Each row is divided at its middle with a central gap
//    of [kSplitGapFraction] of the width. The space bar becomes two halves that
//    both type a space.
//  * compact: landscape on phones. Key rows are capped at [kCompactKeyHeight] dp.
//    Spare height goes to the last row, so the keys never leave a dead strip.
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:meta/meta.dart';

import '../../engine/contracts.dart';
import 'layout_model.dart';

/// Tallest key row in compact layouts, in dp.
const double kCompactKeyHeight = 44;

/// Share of the width given to the central gap in split layouts.
const double kSplitGapFraction = 0.2;

/// One key with its geometry.
@immutable
class PlacedKey {
  const PlacedKey({
    required this.def,
    required this.index,
    required this.row,
    required this.column,
    required this.cell,
    required this.rect,
  });

  final KeyDef def;

  /// Position in [LaidOutKeyboard.keys].
  final int index;
  final int row;
  final int column;

  /// Full cell including the half gap on every side. Cells tile the keyboard,
  /// so hit-testing has no dead zones.
  final Rect cell;

  /// Visible key rect (gaps excluded).
  final Rect rect;
}

/// Vertical band of one row.
@immutable
class RowBand {
  const RowBand({required this.top, required this.bottom, required this.keys});

  final double top;
  final double bottom;
  final List<PlacedKey> keys;
}

class LaidOutKeyboard {
  LaidOutKeyboard({
    required this.layout,
    required this.size,
    required this.keyGap,
    required this.keys,
    required this.rows,
  });

  final KeyboardLayoutDef layout;
  final Size size;
  final double keyGap;
  final List<PlacedKey> keys;
  final List<RowBand> rows;

  /// The key under [p]: the row band is chosen by y (clamped to the first and
  /// last row), then the cell containing x, else the nearest key centre.
  /// Never returns null unless the layout is empty.
  PlacedKey? hitTest(Offset p) {
    if (rows.isEmpty) return null;
    var band = rows.last;
    if (p.dy < rows.first.bottom) {
      band = rows.first;
    } else {
      for (final r in rows) {
        if (p.dy < r.bottom) {
          band = r;
          break;
        }
      }
    }
    if (band.keys.isEmpty) return null;
    PlacedKey? best;
    var bestDist = double.infinity;
    for (final k in band.keys) {
      if (p.dx >= k.cell.left && p.dx < k.cell.right) return k;
      final d = (p.dx - k.cell.center.dx).abs();
      if (d < bestDist) {
        bestDist = d;
        best = k;
      }
    }
    return best;
  }

  /// Character keys whose lower-case output is a letter, for spatial
  /// autocorrect and gesture typing. Keyed by lower-case output.
  KeyboardGeometry toGeometry({String? layoutId}) {
    final map = <String, Rect>{};
    for (final k in keys) {
      final out = k.def.output;
      if (!k.def.isCharacter || out == null) continue;
      final lower = out.toLowerCase();
      if (!_letter.hasMatch(lower)) continue;
      map.putIfAbsent(lower, () => k.rect);
    }
    return KeyboardGeometry(layoutId: layoutId ?? layout.id, size: size, keys: map);
  }

  /// Median width of the character keys (used for the swipe-start threshold).
  double get keyWidth {
    final widths = [
      for (final k in keys)
        if (k.def.isCharacter) k.rect.width,
    ]..sort();
    return widths.isEmpty ? 1 : widths[widths.length ~/ 2];
  }

  static final RegExp _letter = RegExp(r'^\p{L}$', unicode: true);
}

/// A key (or half of a split space bar) with the width it takes in its group.
class _Piece {
  const _Piece(this.def, this.width);

  final KeyDef def;
  final double width;
}

/// The two halves of one row in split layouts.
class _SplitRow {
  const _SplitRow(this.left, this.right);

  final List<_Piece> left;
  final List<_Piece> right;

  double get leftWidth => left.fold(0, (s, p) => s + p.width);
  double get rightWidth => right.fold(0, (s, p) => s + p.width);
}

abstract final class KeyboardLayoutEngine {
  /// Computes key rects for [layout] inside [size].
  ///
  /// Row heights are relative (`row.height`); key widths are in units. The unit
  /// width comes from the widest row; narrower rows are centred, so rows that
  /// declare `padding` and rows that don't both look right.
  ///
  /// [split] lays each row out as two halves around a central gap; [compact]
  /// caps the key height (landscape on phones).
  static LaidOutKeyboard layout(
    KeyboardLayoutDef layout,
    Size size, {
    double keyGap = 6,
    bool split = false,
    bool compact = false,
  }) {
    final rows = layout.rows;
    final totalHeight = rows.fold<double>(0, (s, r) => s + r.height);
    final maxUnits = rows.fold<double>(0, (m, r) => math.max(m, r.totalUnits));
    final keys = <PlacedKey>[];
    final bands = <RowBand>[];
    if (rows.isEmpty || totalHeight <= 0 || maxUnits <= 0) {
      return LaidOutKeyboard(layout: layout, size: size, keyGap: keyGap, keys: keys, rows: bands);
    }
    final half = keyGap / 2;
    final tops = _rowTops(rows, size.height, totalHeight, compact: compact);
    if (split) {
      final plans = [for (final r in rows) _splitRow(r, r.padding)];
      // Widest row fills 80% of the width (a 20% centre gap); no half may pass the centre line.
      var rowUnits = 0.0;
      var halfUnits = 0.0;
      for (var r = 0; r < rows.length; r++) {
        final p = rows[r].padding;
        rowUnits = math.max(rowUnits, rows[r].totalUnits);
        halfUnits = math.max(halfUnits, math.max(p + plans[r].leftWidth, p + plans[r].rightWidth));
      }
      final unit = math.min(size.width * (1 - kSplitGapFraction) / rowUnits, size.width / 2 / halfUnits);
      for (var r = 0; r < rows.length; r++) {
        final top = tops[r].$1;
        final bottom = tops[r].$2;
        final rowKeys = <PlacedKey>[];
        _placeSplitRow(
          plan: plans[r],
          row: r,
          pad: rows[r].padding * unit,
          unit: unit,
          top: top,
          bottom: bottom,
          size: size,
          half: half,
          keys: keys,
          rowKeys: rowKeys,
        );
        bands.add(RowBand(top: top, bottom: bottom, keys: rowKeys));
      }
      return LaidOutKeyboard(layout: layout, size: size, keyGap: keyGap, keys: keys, rows: bands);
    }

    final unitWidth = size.width / maxUnits;
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      final top = tops[r].$1;
      final bottom = tops[r].$2;
      // Centre narrower rows.
      var x = (size.width - row.totalUnits * unitWidth) / 2 + row.padding * unitWidth;
      final rowKeys = <PlacedKey>[];
      for (var c = 0; c < row.keys.length; c++) {
        final def = row.keys[c];
        final w = def.width * unitWidth;
        final visual = Rect.fromLTRB(x, top, x + w, bottom);
        final inset = math.min(half, math.min(visual.width, visual.height) / 4);
        // The outer cells stretch over the row padding so edge touches still hit a key.
        final cell = Rect.fromLTRB(c == 0 ? 0 : x, top, c == row.keys.length - 1 ? size.width : x + w, bottom);
        final placed = PlacedKey(
          def: def,
          index: keys.length,
          row: r,
          column: c,
          cell: cell,
          rect: visual.deflate(inset),
        );
        keys.add(placed);
        rowKeys.add(placed);
        x += w;
      }
      bands.add(RowBand(top: top, bottom: bottom, keys: rowKeys));
    }
    return LaidOutKeyboard(layout: layout, size: size, keyGap: keyGap, keys: keys, rows: bands);
  }

  /// Top and bottom of every row. Compact layouts cap the unit height; the last row
  /// takes whatever height is left so the keyboard has no empty strip underneath.
  static List<(double, double)> _rowTops(
    List<KeyRowDef> rows,
    double height,
    double totalHeight, {
    required bool compact,
  }) {
    final unit = compact ? math.min(height / totalHeight, kCompactKeyHeight) : height / totalHeight;
    final out = <(double, double)>[];
    var y = 0.0;
    for (var r = 0; r < rows.length; r++) {
      final rowHeight = unit * rows[r].height;
      final bottom = r == rows.length - 1 ? height : y + rowHeight;
      out.add((y, bottom));
      y += rowHeight;
    }
    return out;
  }

  /// Splits one row at its middle. A key whose centre is at or left of the middle goes left;
  /// a space bar that spans the middle is cut into two halves, one on each side.
  static _SplitRow _splitRow(KeyRowDef row, double padding) {
    final sum = row.keys.fold<double>(0, (s, k) => s + k.width);
    final mid = padding + sum / 2;
    final left = <_Piece>[];
    final right = <_Piece>[];
    var pos = padding;
    for (final k in row.keys) {
      final start = pos;
      final end = pos + k.width;
      pos = end;
      if (k.type == KeyType.space && start < mid && end > mid) {
        left.add(_Piece(k.copyWith(width: k.width / 2), k.width / 2));
        right.add(_Piece(k.copyWith(width: k.width / 2), k.width / 2));
      } else {
        ((start + end) / 2 <= mid ? left : right).add(_Piece(k, k.width));
      }
    }
    return _SplitRow(left, right);
  }

  /// Places one split row: the left group hugs the left edge, the right group the right edge.
  /// Each group's outer cell reaches the centre line, so touches in the gap pick a neighbour.
  static void _placeSplitRow({
    required _SplitRow plan,
    required int row,
    required double pad,
    required double unit,
    required double top,
    required double bottom,
    required Size size,
    required double half,
    required List<PlacedKey> keys,
    required List<PlacedKey> rowKeys,
  }) {
    final mid = size.width / 2;
    void add(_Piece p, Rect cell, Rect visual) {
      final inset = math.min(half, math.min(visual.width, visual.height) / 4);
      final placed = PlacedKey(
        def: p.def,
        index: keys.length,
        row: row,
        column: rowKeys.length,
        cell: cell,
        rect: visual.deflate(inset),
      );
      keys.add(placed);
      rowKeys.add(placed);
    }

    var x = pad;
    for (var i = 0; i < plan.left.length; i++) {
      final p = plan.left[i];
      final w = p.width * unit;
      final cell = Rect.fromLTRB(i == 0 ? 0 : x, top, i == plan.left.length - 1 ? mid : x + w, bottom);
      add(p, cell, Rect.fromLTRB(x, top, x + w, bottom));
      x += w;
    }
    var xr = size.width - pad - plan.rightWidth * unit;
    for (var i = 0; i < plan.right.length; i++) {
      final p = plan.right[i];
      final w = p.width * unit;
      final cell = Rect.fromLTRB(i == 0 ? mid : xr, top, i == plan.right.length - 1 ? size.width : xr + w, bottom);
      add(p, cell, Rect.fromLTRB(xr, top, xr + w, bottom));
      xr += w;
    }
  }
}
