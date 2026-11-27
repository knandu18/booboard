import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/design/design.dart';
import 'package:booboard/src/theme/theme.dart';

import 'theme_test_support.dart';

/// Android tone [tone] of palette [p] (0..4) in the synthetic set.
Color tone(List<int> pal, int p, int androidTone) => Color(pal[p * 13 + androidTones.indexOf(androidTone)]);

void main() {
  final pal = syntheticPalettes();

  group('baseline role mapping', () {
    test('light', () {
      final s = materialYouScheme(pal, Brightness.light)!;
      expect(s.brightness, Brightness.light);
      expect(s.primary, tone(pal, 0, 600));
      expect(s.onPrimary, tone(pal, 0, 0));
      expect(s.primaryContainer, tone(pal, 0, 100));
      expect(s.onPrimaryContainer, tone(pal, 0, 900));
      expect(s.secondary, tone(pal, 1, 600));
      expect(s.onSecondary, tone(pal, 1, 0));
      expect(s.secondaryContainer, tone(pal, 1, 100));
      expect(s.onSecondaryContainer, tone(pal, 1, 900));
      expect(s.tertiary, tone(pal, 2, 600));
      expect(s.tertiaryContainer, tone(pal, 2, 100));
      expect(s.onSurface, tone(pal, 3, 900));
      expect(s.surfaceContainerLowest, tone(pal, 3, 0));
      expect(s.surfaceContainerHighest, tone(pal, 3, 100));
      expect(s.onSurfaceVariant, tone(pal, 4, 700));
      expect(s.outline, tone(pal, 4, 500));
      expect(s.outlineVariant, tone(pal, 4, 200));
    });

    test('dark', () {
      final s = materialYouScheme(pal, Brightness.dark)!;
      expect(s.brightness, Brightness.dark);
      expect(s.primary, tone(pal, 0, 200));
      expect(s.onPrimary, tone(pal, 0, 800));
      expect(s.primaryContainer, tone(pal, 0, 700));
      expect(s.onPrimaryContainer, tone(pal, 0, 100));
      expect(s.secondary, tone(pal, 1, 200));
      expect(s.secondaryContainer, tone(pal, 1, 700));
      expect(s.tertiary, tone(pal, 2, 200));
      expect(s.tertiaryContainer, tone(pal, 2, 700));
      expect(s.onSurface, tone(pal, 3, 100));
      expect(s.onSurfaceVariant, tone(pal, 4, 200));
      expect(s.outline, tone(pal, 4, 400));
      expect(s.outlineVariant, tone(pal, 4, 700));
    });

    test('surface ladder is ordered by lightness in both modes', () {
      for (final b in Brightness.values) {
        final s = materialYouScheme(pal, b)!;
        final ladder = [
          s.surfaceContainerLowest,
          s.surfaceContainerLow,
          s.surfaceContainer,
          s.surfaceContainerHigh,
          s.surfaceContainerHighest,
        ].map(relativeLuminance).toList();
        for (var i = 1; i < ladder.length; i++) {
          if (b == Brightness.dark) {
            expect(ladder[i], greaterThan(ladder[i - 1]), reason: 'dark step $i');
          } else {
            expect(ladder[i], lessThan(ladder[i - 1]), reason: 'light step $i');
          }
        }
      }
    });

    test('surfaces come from neutral1, outlines from neutral2 (hue check)', () {
      final s = materialYouScheme(pal, Brightness.light)!;
      expect(HSLColor.fromColor(s.surfaceContainer).hue, closeTo(200, 6));
      expect(HSLColor.fromColor(s.outline).hue, closeTo(250, 6));
      expect(HSLColor.fromColor(s.primary).hue, closeTo(210, 6));
      expect(HSLColor.fromColor(s.secondary).hue, closeTo(260, 6));
      expect(HSLColor.fromColor(s.tertiary).hue, closeTo(330, 6));
    });

    test('higher contrast moves accents and outlines further from the surface', () {
      for (final b in Brightness.values) {
        final std = materialYouScheme(pal, b)!;
        final high = materialYouScheme(pal, b, contrastLevel: 1)!;
        expect(contrastRatio(high.primary, high.surface), greaterThan(contrastRatio(std.primary, std.surface)));
        expect(contrastRatio(high.outline, high.surface), greaterThan(contrastRatio(std.outline, std.surface)));
      }
    });
  });

  group('tone helpers', () {
    test('systemToneM3 matches android tones on the stops and interpolates between', () {
      expect(systemToneM3(pal, SystemPalette.accent1, 40), tone(pal, 0, 600));
      expect(systemToneM3(pal, SystemPalette.neutral1, 100), tone(pal, 3, 0));
      expect(systemToneM3(pal, SystemPalette.neutral1, 0), tone(pal, 3, 1000));
      final mid = systemToneM3(pal, SystemPalette.accent1, 85);
      expect(
        relativeLuminance(mid),
        inInclusiveRange(relativeLuminance(tone(pal, 0, 200)), relativeLuminance(tone(pal, 0, 100))),
      );
    });

    test('systemTone rejects unknown tones', () {
      expect(() => systemTone(pal, SystemPalette.accent1, 123), throwsArgumentError);
    });
  });

  group('validation', () {
    test('wrong length or non-opaque colours give null', () {
      expect(materialYouScheme(const [], Brightness.light), isNull);
      expect(materialYouScheme(pal.take(64).toList(), Brightness.light), isNull);
      expect(materialYouScheme([...pal, 0xFF000000], Brightness.light), isNull);
      expect(materialYouScheme(List.filled(65, 0), Brightness.light), isNull);
    });

    test('signed ints from the platform (negative ARGB) are accepted', () {
      final signed = [for (final c in pal) c.toSigned(32)];
      expect(signed.any((c) => c < 0), isTrue);
      expect(materialYouScheme(signed, Brightness.light), isNotNull);
    });
  });
}
