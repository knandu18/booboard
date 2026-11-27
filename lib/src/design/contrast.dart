// SPDX-License-Identifier: GPL-3.0-or-later
//
// WCAG 2.x contrast helpers.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

const Color _white = Color(0xFFFFFFFF);
const Color _black = Color(0xFF000000);

/// WCAG relative luminance of an opaque color.
double relativeLuminance(Color c) {
  double lin(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

/// WCAG contrast ratio between two colors (1..21). Alpha is ignored.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Returns [foreground] if it already reaches [minRatio] against [background];
/// otherwise the nearest tint of it (moved toward black or white, whichever
/// contrasts more with the background, or the one chosen by [lighten]) that
/// does. Keeps the hue where possible.
Color ensureContrast(Color foreground, Color background, double minRatio, {bool? lighten}) {
  if (contrastRatio(foreground, background) >= minRatio) return foreground;
  final light = lighten ?? contrastRatio(_white, background) >= contrastRatio(_black, background);
  final target = light ? _white : _black;
  var lo = 0.0;
  var hi = 1.0;
  for (var i = 0; i < 20; i++) {
    final mid = (lo + hi) / 2;
    if (contrastRatio(Color.lerp(foreground, target, mid)!, background) >= minRatio) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  final result = Color.lerp(foreground, target, hi)!;
  return contrastRatio(result, background) >= minRatio ? result : target;
}

/// Opaque blend of [top] (with its alpha) over [bottom].
Color blend(Color top, Color bottom) => Color.alphaBlend(top, bottom);

/// Fits [labels] (the first is the main label) onto [fill] so every label
/// reaches [minRatio] against it. Labels are moved toward black or white first;
/// if even pure black/white cannot reach the ratio (a mid-tone fill), the fill
/// itself is nudged away from the labels, as little as possible.
///
/// With [stateLayerAlpha] > 0 the labels must also reach [minRatio] on the
/// pressed fill: the main label blended over the fill at that alpha.
({Color fill, List<Color> labels}) fitLabelsToFill(
  Color fill,
  List<Color> labels,
  double minRatio, {
  double stateLayerAlpha = 0,
}) {
  var f = fill;
  var out = labels;
  for (var i = 0; i < 40; i++) {
    // One direction per fill, so labels never flip between light and dark
    // while the pressed state is being fitted.
    final lighten = contrastRatio(_white, f) >= contrastRatio(_black, f);
    out = [for (final l in labels) ensureContrast(l, f, minRatio, lighten: lighten)];
    // The pressed fill depends on the label, and moving the label changes it:
    // iterate a few times until both settle.
    for (var j = 0; j < 8 && stateLayerAlpha > 0; j++) {
      final pressed = blend(out.first.withValues(alpha: stateLayerAlpha), f);
      final next = [for (final l in out) ensureContrast(l, pressed, minRatio, lighten: lighten)];
      final settled = next.indexed.every((e) => e.$2 == out[e.$1]);
      out = next;
      if (settled) break;
    }
    final pressed = stateLayerAlpha > 0 ? blend(out.first.withValues(alpha: stateLayerAlpha), f) : f;
    final ok = out.every((l) => contrastRatio(l, f) >= minRatio && contrastRatio(l, pressed) >= minRatio);
    if (ok) return (fill: f, labels: out);
    f = Color.lerp(f, lighten ? _black : _white, 0.04)!;
  }
  return (fill: f, labels: out);
}
