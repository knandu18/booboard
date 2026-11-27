import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/design/design.dart';
import 'package:booboard/src/settings/sections/appearance_settings.dart';
import 'package:booboard/src/bridge/messages.g.dart';
import 'package:booboard/src/theme/theme.dart';

import 'theme_test_support.dart';

KeyboardThemeData _resolve({
  String themeId = 'booboard_oceanblue',
  DarkModePreference darkMode = DarkModePreference.light,
  bool pureBlack = false,
  ContrastPreference contrast = ContrastPreference.standard,
  SystemColorsMessage? colors,
  bool systemDark = false,
  bool disableAnimations = false,
}) => resolveKeyboardTheme(
  appearance: AppearanceSettings(themeId: themeId, darkMode: darkMode, pureBlack: pureBlack, contrast: contrast),
  systemColors: colors,
  systemDark: systemDark,
  disableAnimations: disableAnimations,
);

void main() {
  final systemColors = syntheticSystemColors();

  group('every preset resolves and passes contrast', () {
    for (final preset in [...ThemePresets.all, ...ThemePresets.legacy]) {
      for (final dark in [false, true]) {
        for (final pureBlack in dark ? [false, true] : [false]) {
          for (final contrast in ContrastPreference.values) {
            final label = '${preset.id} ${dark ? (pureBlack ? 'pureblack' : 'dark') : 'light'} ${contrast.name}';
            for (final withPalette in [false, true]) {
              test('$label ${withPalette ? 'palette' : 'no-palette'}', () {
                final t = _resolve(
                  themeId: preset.id,
                  darkMode: dark ? DarkModePreference.dark : DarkModePreference.light,
                  pureBlack: pureBlack,
                  contrast: contrast,
                  colors: withPalette ? systemColors : null,
                );
                expect(t.id, preset.id);
                // The glass keyboards are hand-made and keep their own brightness: Dark Glass is always dark,
                // and Auto follows the phone (light here, systemDark is false).
                final glass = glassThemeFor(preset.id, motion: const MotionSpec()) != null;
                final expected = glass
                    ? (preset.id == GlassThemeIds.dark ? Brightness.dark : Brightness.light)
                    : (dark ? Brightness.dark : Brightness.light);
                expect(t.brightness, expected);
                final min = contrast == ContrastPreference.high ? 7.0 : 4.5;
                for (final (name, fg, bg) in labelFillPairs(t)) {
                  expect(contrastRatio(fg, bg), greaterThanOrEqualTo(min), reason: '$label: $name');
                }
                // Swipe trail marks must stay visible against what is painted behind them (each gradient stop).
                for (final b in paintedBackdrops(t)) {
                  expect(contrastRatio(t.trailStart, b), greaterThanOrEqualTo(3.0), reason: '$label trail');
                  expect(contrastRatio(t.trailEnd, b), greaterThanOrEqualTo(3.0), reason: '$label trail');
                }
                if (pureBlack && !glass) {
                  expect(t.background, const Color(0xFF000000));
                  expect(relativeLuminance(t.letterKey.fill), lessThan(0.05), reason: '$label near-black keys');
                }
              });
            }
          }
        }
      }
    }
  });

  test('mapping follows the plan', () {
    final t = _resolve(themeId: 'lavender');
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF8F6FD8));
    expect(t.background, scheme.surfaceContainer);
    expect(t.letterKey.fill, scheme.surfaceContainerHighest);
    expect(t.functionKey.fill, scheme.secondaryContainer);
    expect(t.actionKey.fill, scheme.primary);
    expect(t.popupFill, scheme.primaryContainer);
    expect(t.trailStart, scheme.primary);
    expect(t.trailEnd, scheme.tertiary);
    expect(t.keyCornerRadius, 0.5);
    expect(t.keyGap, 6);
    expect(t.fontFamily, 'GoogleSansFlex');
    expect(t.labelFontVariations.map((v) => v.axis), ['wght', 'ROND']);
    expect(t.labelFontVariations[0].value, 500);
    expect(t.labelFontVariations[1].value, 100); // pill = fully round
    expect(t.spaceKey.fill, isNot(t.letterKey.fill));
  });

  test('font roundness follows the key shape', () {
    final square = ThemePresets.lavender.copyWith(keyRadius: 0);
    final t = resolveKeyboardThemeFromSpec(square, dark: false);
    expect(t.keyCornerRadius, 0);
    expect(t.labelFontVariations[1].value, 0);
    final half = resolveKeyboardThemeFromSpec(ThemePresets.lavender.copyWith(keyRadius: 0.25), dark: false);
    expect(half.labelFontVariations[1].value, 50);
  });

  group('darkMode preference', () {
    test('system follows night mode', () {
      expect(_resolve(darkMode: DarkModePreference.system, systemDark: true).brightness, Brightness.dark);
      expect(_resolve(darkMode: DarkModePreference.system, systemDark: false).brightness, Brightness.light);
    });
    test('explicit choice wins', () {
      expect(_resolve(darkMode: DarkModePreference.dark, systemDark: false).brightness, Brightness.dark);
      expect(_resolve(darkMode: DarkModePreference.light, systemDark: true).brightness, Brightness.light);
    });
    test('pure black is ignored in light mode', () {
      final t = _resolve(pureBlack: true, systemDark: true);
      expect(t.background, isNot(const Color(0xFF000000)));
    });
  });

  group('motion', () {
    test('disableAnimations turns motion off', () {
      expect(_resolve(themeId: 'booboard_gold', disableAnimations: true).motion.enabled, isFalse);
      expect(_resolve(themeId: 'booboard_gold').motion.enabled, isTrue);
    });
    test('defaults come from the fast spatial token', () {
      final m = _resolve(themeId: 'booboard_gold').motion;
      expect(m.stiffness, BooBoardMotion.fastSpatial.stiffness);
      expect(m.dampingRatio, BooBoardMotion.fastSpatial.dampingRatio);
      expect(m.pressScale, closeTo(0.92, 1e-9));
    });
    test('intensity 0 disables motion, 2 presses deeper and snappier', () {
      final off = resolveKeyboardThemeFromSpec(ThemePresets.mint.copyWith(motionIntensity: 0), dark: false);
      expect(off.motion.enabled, isFalse);
      final strong = resolveKeyboardThemeFromSpec(ThemePresets.mint.copyWith(motionIntensity: 2), dark: false);
      expect(strong.motion.pressScale, lessThan(0.92));
      expect(strong.motion.stiffness, greaterThan(BooBoardMotion.fastSpatial.stiffness));
    });
  });

  group('fallback and selection', () {
    test('Dark Glass stays dark and Lime Glass stays light, whatever the dark-mode setting', () {
      for (final mode in DarkModePreference.values) {
        for (final systemDark in [false, true]) {
          final darkGlass = _resolve(themeId: GlassThemeIds.dark, darkMode: mode, systemDark: systemDark);
          final limeGlass = _resolve(themeId: GlassThemeIds.lime, darkMode: mode, systemDark: systemDark);
          expect(darkGlass.brightness, Brightness.dark);
          expect(limeGlass.brightness, Brightness.light);
          expect(darkGlass.backgroundLayers, isNotEmpty);
          expect(darkGlass.letterKey.fillTop, isNotNull);
        }
      }
    });

    test('Light Glass stays light; Auto follows the phone, not the app dark-mode setting', () {
      for (final mode in DarkModePreference.values) {
        for (final systemDark in [false, true]) {
          final light = _resolve(themeId: GlassThemeIds.light, darkMode: mode, systemDark: systemDark);
          final auto = _resolve(themeId: GlassThemeIds.auto, darkMode: mode, systemDark: systemDark);
          expect(light.brightness, Brightness.light);
          expect(light.id, GlassThemeIds.light);
          expect(auto.id, GlassThemeIds.auto);
          expect(auto.brightness, systemDark ? Brightness.dark : Brightness.light);
        }
      }
    });

    test('unknown themeId falls back to Dark Glass', () {
      final unknown = _resolve(themeId: 'no_such_theme', colors: systemColors);
      final dyn = _resolve(themeId: 'booboard_glass_dark', colors: systemColors);
      expect(unknown.id, 'booboard_glass_dark');
      expect(unknown.background, dyn.background);
      expect(unknown.actionKey.fill, dyn.actionKey.fill);
    });

    test('legacy BooBoard Dynamic uses the system palettes', () {
      final t = _resolve(themeId: 'booboard_dynamic', colors: systemColors);
      final expected = materialYouScheme(systemColors.palettes, Brightness.light)!;
      // The accent may be nudged slightly to reach label contrast; it must stay close.
      expect((t.actionKey.fill.r - expected.primary.r).abs(), lessThan(0.08));
      expect((t.actionKey.fill.b - expected.primary.b).abs(), lessThan(0.08));
      expect(t.background, expected.surfaceContainer);
    });

    test('Oceanblue ignores system palettes and uses its own seed', () {
      final none = _resolve();
      final bad = _resolve(colors: SystemColorsMessage(palettes: [1, 2, 3], isNightMode: false));
      final withSystem = _resolve(colors: systemColors);
      expect(withSystem.actionKey.fill, none.actionKey.fill);
      expect(bad.actionKey.fill, none.actionKey.fill);
      expect(bad.background, none.background);
      expect(none.actionKey.fill, isNot(materialYouScheme(systemColors.palettes, Brightness.light)!.primary));
    });

    test('other presets ignore system palettes', () {
      expect(
        _resolve(themeId: 'ocean', colors: systemColors).actionKey.fill,
        _resolve(themeId: 'ocean').actionKey.fill,
      );
    });
  });

  group('BooBoard Gold brand colours', () {
    test('light and dark keep the yellow primary with brown on-colour', () {
      for (final dark in [false, true]) {
        final t = resolveKeyboardThemeFromSpec(ThemePresets.booboardGold, dark: dark);
        expect(t.actionKey.fill, const Color(0xFFEFB33A));
        expect(t.actionKey.label, const Color(0xFF3E2723));
      }
    });
  });

  group('background', () {
    test('gradient and image settings reach the theme', () {
      final grad = ThemePresets.ocean.copyWith(
        background: const ThemeBackgroundSpec(
          type: ThemeBackgroundType.gradient,
          gradientColors: [0xFF102030, 0xFF304050],
          gradientAngle: 90,
        ),
      );
      final t = resolveKeyboardThemeFromSpec(grad, dark: true);
      expect(t.backgroundGradient, isA<LinearGradient>());
      expect(contrastRatio(t.suggestionText, const Color(0xFF304050)), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(t.suggestionText, const Color(0xFF102030)), greaterThanOrEqualTo(4.5));
      final img = ThemePresets.ocean.copyWith(
        background: const ThemeBackgroundSpec(type: ThemeBackgroundType.image, imagePath: '/x/bg.png', dim: 0.4),
      );
      final ti = resolveKeyboardThemeFromSpec(img, dark: false);
      expect(ti.backgroundImagePath, '/x/bg.png');
      expect(ti.backgroundImageDim, 0.4);
      expect(ti.backgroundGradient, isNull);
    });
  });

  group('cache', () {
    test('identical inputs return the identical object', () {
      KeyboardThemeData r() => _resolve(themeId: 'rose', colors: syntheticSystemColors(), systemDark: true);
      expect(identical(r(), r()), isTrue);
    });

    test('cached resolution is negligible', () {
      final colors = syntheticSystemColors();
      final sw = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        _resolve(darkMode: DarkModePreference.dark, colors: colors);
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('uncached resolution is cheap', () {
      final sw = Stopwatch()..start();
      var n = 0;
      for (final p in ThemePresets.all) {
        for (final dark in [false, true]) {
          resolveKeyboardThemeFromSpec(p, dark: dark, palettes: systemColors.palettes);
          n++;
        }
      }
      sw.stop();
      // ignore: avoid_print
      print('uncached resolve: ${(sw.elapsedMicroseconds / n).round()} us each ($n resolutions)');
      expect(sw.elapsedMilliseconds / n, lessThan(20));
    });

    test('cache stays bounded', () {
      for (final p in ThemePresets.all) {
        for (final c in ContrastPreference.values) {
          for (final d in [true, false]) {
            _resolve(themeId: p.id, contrast: c, systemDark: d, darkMode: DarkModePreference.system);
          }
        }
      }
      expect(themeCacheSizeForTest, lessThanOrEqualTo(12));
    });
  });
}
