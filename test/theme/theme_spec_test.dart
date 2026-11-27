import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/settings/sections/appearance_settings.dart';
import 'package:booboard/src/theme/theme.dart';

void main() {
  group('JSON round trip', () {
    test('every preset survives encode/decode unchanged', () {
      for (final p in ThemePresets.all) {
        final text = jsonEncode(p.toJson());
        final back = ThemeSpec.fromJson(jsonDecode(text) as Map<String, Object?>);
        expect(back, p, reason: p.id);
        expect(back.hashCode, p.hashCode, reason: p.id);
      }
    });

    test('a fully customised spec survives', () {
      const spec = ThemeSpec(
        id: 'custom_1',
        name: 'My theme',
        colorSource: ThemeColorSource.custom,
        seedColor: 0xFF123456,
        variant: ThemeSchemeVariant.rainbow,
        customRoles: {'primary': 0xFF112233, 'onPrimary': 0xFFFFFFFF},
        customRolesDark: {'primary': 0xFF445566},
        keyRadius: 0.2,
        borderWidth: 1.5,
        keyGap: 3,
        fontFamily: null,
        labelWeight: 700,
        fontRoundness: 30,
        labelScale: 1.2,
        showHints: false,
        background: ThemeBackgroundSpec(
          type: ThemeBackgroundType.image,
          imagePath: '/data/bg.png',
          blur: 12,
          dim: 0.5,
          gradientColors: [0xFF000000, 0xFFFFFFFF],
          gradientAngle: 45,
        ),
        accents: ThemeAccentOverrides(popupFill: 0xFFAABBCC, trailStart: 0xFF010203, trailEnd: 0xFF040506),
        motionIntensity: 1.5,
      );
      final back = ThemeSpec.fromJson(jsonDecode(jsonEncode(spec.toJson())) as Map<String, Object?>);
      expect(back, spec);
      expect(back.fontFamily, isNull);
    });

    test('toJson stamps the current version', () {
      expect(ThemePresets.mint.toJson()['version'], ThemeSpec.currentVersion);
    });
  });

  group('tolerant parsing', () {
    test('empty and garbage JSON give defaults', () {
      final s = ThemeSpec.fromJson({});
      expect(s.keyRadius, 0.5);
      expect(s.fontFamily, 'GoogleSansFlex');
      final bad = ThemeSpec.fromJson({
        'keyRadius': 'wide',
        'colorSource': 'nonsense',
        'customRoles': {'primary': 'red', 'notARole': 1, 'onPrimary': 0xFF000000},
        'background': 'solid',
        'labelWeight': 'bold',
      });
      expect(bad.keyRadius, 0.5);
      expect(bad.colorSource, ThemeColorSource.seed);
      expect(bad.customRoles, {'onPrimary': 0xFF000000});
      expect(bad.background, const ThemeBackgroundSpec());
      expect(bad.labelWeight, 500);
    });

    test('numbers are clamped', () {
      final s = ThemeSpec.fromJson({
        'keyRadius': 3,
        'keyGap': -4,
        'labelWeight': 5000,
        'labelScale': 0.1,
        'motionIntensity': 99,
        'fontRoundness': 500,
        'background': {'dim': 7, 'blur': -1},
      });
      expect(s.keyRadius, 0.5);
      expect(s.keyGap, 0);
      expect(s.labelWeight, 900);
      expect(s.labelScale, 0.7);
      expect(s.motionIntensity, 2);
      expect(s.fontRoundness, 100);
      expect(s.background.dim, 1);
      expect(s.background.blur, 0);
    });

    test('a newer version is read leniently and ignores unknown keys', () {
      final s = ThemeSpec.fromJson({'version': 99, 'id': 'future', 'keyRadius': 0.1, 'holographic': true});
      expect(s.id, 'future');
      expect(s.keyRadius, 0.1);
    });

    test('signed ARGB ints from other platforms are normalised', () {
      final s = ThemeSpec.fromJson({'seedColor': 0xFF123456.toSigned(32)});
      expect(s.seedColor, 0xFF123456);
    });
  });

  group('migrations', () {
    test('v0 flat format upgrades to v1', () {
      final old = <String, Object?>{
        'id': 'legacy',
        'name': 'Legacy',
        'seed': 0xFF336699,
        'scheme': 'vibrant',
        'radius': 0.3,
        'gap': 4,
        'border': 1,
        'font': 'GoogleSansFlex',
        'weight': 600,
        'motion': 0.5,
        'bgColors': [0xFF000000, 0xFF111111],
        'bgDim': 0.2,
        'dynamic': true,
      };
      final s = ThemeSpec.fromJson(old);
      expect(s.colorSource, ThemeColorSource.dynamic);
      expect(s.seedColor, 0xFF336699);
      expect(s.variant, ThemeSchemeVariant.vibrant);
      expect(s.keyRadius, 0.3);
      expect(s.keyGap, 4);
      expect(s.borderWidth, 1);
      expect(s.labelWeight, 600);
      expect(s.motionIntensity, 0.5);
      expect(s.background.type, ThemeBackgroundType.gradient);
      expect(s.background.gradientColors, [0xFF000000, 0xFF111111]);
      expect(s.background.dim, 0.2);
    });

    test('v0 image background', () {
      final s = ThemeSpec.fromJson({'bgImage': '/p/a.png', 'bgBlur': 8});
      expect(s.background.type, ThemeBackgroundType.image);
      expect(s.background.imagePath, '/p/a.png');
      expect(s.background.blur, 8);
    });

    test('migrateThemeJson stamps the version and leaves current JSON alone', () {
      final m = migrateThemeJson({'radius': 0.1});
      expect(m['version'], ThemeSpec.currentVersion);
      expect(m['keyRadius'], 0.1);
      expect(m.containsKey('radius'), isFalse);
      final cur = ThemePresets.coral.toJson();
      expect(migrateThemeJson(cur), cur);
    });

    test('migration does not mutate its input', () {
      final input = <String, Object?>{'radius': 0.1};
      migrateThemeJson(input);
      expect(input, {'radius': 0.1});
    });
  });

  group('presets', () {
    test('the two glass themes are shown; the older presets stay resolvable for saved choices', () {
      expect(
        [for (final p in ThemePresets.all) p.id],
        ['booboard_glass_dark', 'booboard_glass_light', 'booboard_glass_auto', 'booboard_glass_lime'],
      );
      final legacy = [for (final p in ThemePresets.legacy) p.id];
      final ids = [...ThemePresets.all, ...ThemePresets.legacy].map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(legacy, containsAll(['booboard_oceanblue', 'booboard_dynamic', 'booboard_gold', 'lavender', 'graphite']));
      expect(defaultThemeId, 'booboard_glass_dark');
      expect(const AppearanceSettings().themeId, defaultThemeId);
    });

    test('byId resolves a legacy id to itself and falls back to Dark Glass', () {
      expect(ThemePresets.byId('ocean').id, 'ocean');
      expect(ThemePresets.byId('booboard_dynamic').id, 'booboard_dynamic');
      expect(ThemePresets.byId('booboard_oceanblue').id, 'booboard_oceanblue');
      expect(ThemePresets.byId('nope').id, 'booboard_glass_dark');
      expect(ThemePresets.isPresetId('nope'), isFalse);
      expect(ThemePresets.isPresetId('booboard_dynamic'), isTrue);
    });

    test('brand colours', () {
      expect(ThemePresets.booboardGold.customRoles['primary'], booboardYellow);
      expect(ThemePresets.booboardGold.customRoles['onPrimary'], booboardBrown);
      expect(ThemePresets.booboardDynamic.colorSource, ThemeColorSource.dynamic);
      expect(ThemePresets.graphite.variant, ThemeSchemeVariant.monochrome);
    });
  });
}
