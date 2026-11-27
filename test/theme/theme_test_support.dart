import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/design/design.dart';
import 'package:booboard/src/theme/keyboard_theme_data.dart';

/// Synthetic Material You palettes: 5 palettes x 13 tones, tinted greys with a
/// distinct hue per palette. Android tone N has lightness 100 - N/10.
List<int> syntheticPalettes({List<double> hues = const [210, 260, 330, 200, 250]}) {
  final out = <int>[];
  for (var p = 0; p < 5; p++) {
    final sat = p < 3 ? 0.55 : 0.08;
    for (final tone in androidTones) {
      final lightness = (100 - tone / 10) / 100;
      final c = HSLColor.fromAHSL(1, hues[p], sat, lightness).toColor();
      out.add(c.toARGB32());
    }
  }
  return out;
}

SystemColorsMessage syntheticSystemColors({bool night = false}) =>
    SystemColorsMessage(palettes: syntheticPalettes(), isNightMode: night);

/// The colours text is actually painted on: each stop of a gradient background, otherwise the solid background,
/// and each of those under the strongest part of every glow layer. A gradient paints over `background`, so
/// checking text only against `background` would test the wrong colour.
List<Color> paintedBackdrops(KeyboardThemeData t) {
  final g = t.backgroundGradient;
  final stops = g is LinearGradient ? g.colors : [t.background];
  return [
    ...stops,
    for (final layer in t.backgroundLayers)
      for (final s in stops) Color.alphaBlend(layer.colors.first, s),
  ];
}

/// Every (label, fill) pair the keyboard paints, with a description. See-through fills (glass keys) are blended
/// over every backdrop, and see-through labels over the blended fill, so the ratio is the one on screen.
List<(String, Color, Color)> labelFillPairs(KeyboardThemeData t) {
  final out = <(String, Color, Color)>[];
  void add(String name, Color label, Color fill) {
    for (final b in paintedBackdrops(t)) {
      final f = Color.alphaBlend(fill, b);
      out.add((name, Color.alphaBlend(label, f), f));
    }
  }

  void key(String name, KeyStyle k) {
    add('$name label', k.label, k.fill);
    add('$name hint', k.hint, k.fill);
    add('$name label pressed', k.label, k.pressedFill);
    if (k.fillTop case final top?) add('$name label (top of key)', k.label, top);
  }

  for (final b in paintedBackdrops(t)) {
    out
      ..add(('suggestion text', Color.alphaBlend(t.suggestionText, b), b))
      ..add(('toolbar icon', Color.alphaBlend(t.toolbarIcon, b), b));
  }
  key('letter', t.letterKey);
  key('function', t.functionKey);
  key('action', t.actionKey);
  key('space', t.spaceKey);
  add('popup', t.popupLabel, t.popupFill);
  add('popup selected', t.popupSelectedLabel, t.popupSelectedFill);
  add('suggestion highlight', t.suggestionHighlightText, t.suggestionHighlightFill);
  return out;
}
