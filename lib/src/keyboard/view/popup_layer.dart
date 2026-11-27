// SPDX-License-Identifier: GPL-3.0-or-later
//
// Key preview bubble and long-press alternatives. Both stay inside the
// keyboard view: the IME window has no room above it, so popups for the top
// row overlap the suggestion strip instead.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../theme/keyboard_theme_data.dart';
import 'key_visuals.dart';

sealed class PopupState {
  const PopupState();
}

/// The bubble that shows the pressed key.
class KeyPreviewState extends PopupState {
  const KeyPreviewState({required this.keyRect, required this.label});

  /// In view coordinates (strip included).
  final Rect keyRect;
  final String label;
}

/// The long-press row of alternatives.
class AlternativesState extends PopupState {
  const AlternativesState({required this.keyRect, required this.items, required this.layout, required this.selected});

  final Rect keyRect;
  final List<String> items;
  final AlternativesLayout layout;
  final int selected;

  AlternativesState withSelected(int index) =>
      AlternativesState(keyRect: keyRect, items: items, layout: layout, selected: index);
}

/// Directions of a 12-key flick (Wave 4). `KeyDef.flick` uses the same names.
enum FlickDirection { center, up, down, left, right }

/// The cross shown while a flick key is held: the key's output in the centre and its flick
/// outputs around it, with [selected] highlighted.
class FlickGuideState extends PopupState {
  const FlickGuideState({required this.keyRect, required this.labels, required this.selected});

  final Rect keyRect;

  /// Only directions that type something.
  final Map<FlickDirection, String> labels;
  final FlickDirection selected;

  FlickGuideState withSelected(FlickDirection d) => FlickGuideState(keyRect: keyRect, labels: labels, selected: d);

  /// The cell of [d], in view coordinates: the key itself for the centre, one key away otherwise.
  Rect cellOf(FlickDirection d) => switch (d) {
    FlickDirection.center => keyRect,
    FlickDirection.up => keyRect.shift(Offset(0, -keyRect.height)),
    FlickDirection.down => keyRect.shift(Offset(0, keyRect.height)),
    FlickDirection.left => keyRect.shift(Offset(-keyRect.width, 0)),
    FlickDirection.right => keyRect.shift(Offset(keyRect.width, 0)),
  };
}

/// The flick direction for a finger moved by [delta] from where it landed, on a key [keyWidth]
/// wide: the centre until the finger moves a third of a key, then the dominant axis.
FlickDirection flickDirectionFor(Offset delta, double keyWidth) {
  if (delta.distance < keyWidth * 0.33) return FlickDirection.center;
  if (delta.dx.abs() >= delta.dy.abs()) return delta.dx < 0 ? FlickDirection.left : FlickDirection.right;
  return delta.dy < 0 ? FlickDirection.up : FlickDirection.down;
}

/// Where the alternatives go.
class AlternativesLayout {
  const AlternativesLayout({required this.bounds, required this.cells});

  final Rect bounds;

  /// One rect per item (view coordinates); item 0 is nearest the key.
  final List<Rect> cells;

  /// The item under [p]. A finger below or beside the popup picks the nearest
  /// item, so sliding is forgiving.
  int selectAt(Offset p) {
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      if (c.contains(p)) return i;
      final dx = p.dx - c.center.dx;
      final dy = (p.dy - c.center.dy) * 0.35;
      final d = dx * dx + dy * dy;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  static const double itemHeight = 52;
  static const double margin = 4;

  static AlternativesLayout compute({required Rect keyRect, required int count, required Size view}) {
    if (count <= 0) return AlternativesLayout(bounds: Rect.fromLTWH(keyRect.left, keyRect.top, 0, 0), cells: const []);
    final perRow = count <= 8 ? count : (count / 2).ceil();
    final rows = (count / perRow).ceil();
    var itemW = math.max(38.0, math.min(keyRect.width, 52.0));
    final maxW = view.width - margin * 2;
    if (itemW * perRow > maxW) itemW = maxW / perRow;
    final blockW = itemW * perRow;
    final blockH = itemHeight * rows;

    // The first item sits over the key; mirror to the left when it would overflow on the right.
    final mirror = keyRect.center.dx - itemW / 2 + blockW > view.width - margin;
    var left = mirror ? keyRect.center.dx + itemW / 2 - blockW : keyRect.center.dx - itemW / 2;
    left = left.clamp(margin, math.max(margin, view.width - margin - blockW)).toDouble();
    var top = keyRect.top - 6 - blockH;
    if (top < margin) top = margin;
    final bounds = Rect.fromLTWH(left, top, blockW, blockH);
    final bottom = bounds.bottom;
    final cells = <Rect>[];
    for (var i = 0; i < count; i++) {
      final row = i ~/ perRow;
      final col = i % perRow;
      final x = mirror ? bounds.right - (col + 1) * itemW : bounds.left + col * itemW;
      final y = bottom - (row + 1) * itemHeight;
      cells.add(Rect.fromLTWH(x, y, itemW, itemHeight));
    }
    return AlternativesLayout(bounds: bounds, cells: cells);
  }
}

Rect previewBubbleRect(Rect keyRect, Size view) {
  final w = math.max(keyRect.width * 1.3, 52.0);
  final h = math.max(keyRect.height * 1.15, 56.0);
  final left = (keyRect.center.dx - w / 2).clamp(2.0, math.max(2.0, view.width - 2 - w)).toDouble();
  final top = math.max(2.0, keyRect.top + 6 - h);
  return Rect.fromLTWH(left, top, w, h);
}

class PopupPainter extends CustomPainter {
  PopupPainter({required this.state, required this.theme}) : super(repaint: state);

  final ValueListenable<PopupState?> state;
  final KeyboardThemeData theme;

  TextPainter _text(String s, double size, Color color) => TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: theme.fontFamily,
        fontWeight: theme.labelWeight,
        fontVariations: theme.labelFontVariations,
        fontSize: size * theme.labelScale,
        color: color,
        height: 1.1,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final s = state.value;
    if (s == null) return;
    final fill = Paint()..isAntiAlias = true;
    switch (s) {
      case KeyPreviewState():
        final r = previewBubbleRect(s.keyRect, size);
        final rrect = RRect.fromRectAndRadius(r, Radius.circular(math.min(r.width, r.height) * 0.3));
        canvas.drawShadow(Path()..addRRect(rrect), const Color(0xFF000000), 3, true);
        fill.color = theme.popupFill;
        canvas.drawRRect(rrect, fill);
        final tp = _text(s.label, s.label.length > 1 ? 22 : 30, theme.popupLabel);
        tp.paint(canvas, r.center - Offset(tp.width / 2, tp.height / 2));
        tp.dispose();
      case AlternativesState():
        final b = s.layout.bounds;
        final rrect = RRect.fromRectAndRadius(b.inflate(2), const Radius.circular(18));
        canvas.drawShadow(Path()..addRRect(rrect), const Color(0xFF000000), 4, true);
        fill.color = theme.popupFill;
        canvas.drawRRect(rrect, fill);
        for (var i = 0; i < s.items.length; i++) {
          final cell = s.layout.cells[i];
          final selected = i == s.selected;
          if (selected) {
            fill.color = theme.popupSelectedFill;
            canvas.drawRRect(
              RRect.fromRectAndRadius(cell.deflate(3), Radius.circular(math.min(cell.width, cell.height) * 0.35)),
              fill,
            );
          }
          final label = displayLabel(s.items[i]);
          final tp = _text(label, label.length > 1 ? 18 : 24, selected ? theme.popupSelectedLabel : theme.popupLabel);
          final scale = tp.width > cell.width - 4 ? (cell.width - 4) / tp.width : 1.0;
          canvas
            ..save()
            ..translate(cell.center.dx, cell.center.dy)
            ..scale(scale)
            ..translate(-tp.width / 2, -tp.height / 2);
          tp.paint(canvas, Offset.zero);
          canvas.restore();
          tp.dispose();
        }
      case FlickGuideState():
        for (final e in s.labels.entries) {
          final cell = s.cellOf(e.key).deflate(2);
          final selected = e.key == s.selected;
          final rrect = RRect.fromRectAndRadius(cell, Radius.circular(math.min(cell.width, cell.height) * 0.3));
          canvas.drawShadow(Path()..addRRect(rrect), const Color(0xFF000000), 3, true);
          fill.color = selected ? theme.popupSelectedFill : theme.popupFill;
          canvas.drawRRect(rrect, fill);
          final label = displayLabel(e.value);
          final tp = _text(label, label.length > 1 ? 18 : 24, selected ? theme.popupSelectedLabel : theme.popupLabel);
          final scale = tp.width > cell.width - 4 ? (cell.width - 4) / tp.width : 1.0;
          canvas
            ..save()
            ..translate(cell.center.dx, cell.center.dy)
            ..scale(scale)
            ..translate(-tp.width / 2, -tp.height / 2);
          tp.paint(canvas, Offset.zero);
          canvas.restore();
          tp.dispose();
        }
    }
  }

  @override
  bool shouldRepaint(covariant PopupPainter old) => old.theme != theme || old.state != state;
}
