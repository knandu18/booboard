import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/design/design.dart';

void main() {
  group('contrast helpers', () {
    test('black on white is 21:1 and symmetric', () {
      const w = Color(0xFFFFFFFF);
      const b = Color(0xFF000000);
      expect(contrastRatio(b, w), closeTo(21, 1e-6));
      expect(contrastRatio(w, b), closeTo(21, 1e-6));
      expect(contrastRatio(w, w), closeTo(1, 1e-9));
    });

    test('known mid-grey value', () {
      // #767676 on white is the classic 4.54:1 AA threshold grey.
      expect(contrastRatio(const Color(0xFF767676), const Color(0xFFFFFFFF)), closeTo(4.54, 0.01));
    });

    test('ensureContrast leaves good pairs alone and fixes bad ones', () {
      const bg = Color(0xFFFFFFFF);
      const ok = Color(0xFF000000);
      expect(ensureContrast(ok, bg, 7), ok);
      const bad = Color(0xFFAAAAAA);
      final fixed = ensureContrast(bad, bg, 4.5);
      expect(contrastRatio(fixed, bg), greaterThanOrEqualTo(4.5));
      // Minimal change: not overshooting to black.
      expect(relativeLuminance(fixed), greaterThan(0.1));
      // On a dark background it goes lighter instead.
      final onDark = ensureContrast(const Color(0xFF555555), const Color(0xFF000000), 7);
      expect(contrastRatio(onDark, const Color(0xFF000000)), greaterThanOrEqualTo(7));
      expect(relativeLuminance(onDark), greaterThan(relativeLuminance(const Color(0xFF555555))));
    });

    test('fitLabelsToFill nudges a mid-tone fill when labels cannot reach the ratio', () {
      const fill = Color(0xFF808080); // neither black nor white reaches 7:1
      final r = fitLabelsToFill(fill, const [Color(0xFFFFFFFF)], 7, stateLayerAlpha: 0.14);
      expect(contrastRatio(r.labels.first, r.fill), greaterThanOrEqualTo(7));
      final pressed = blend(r.labels.first.withValues(alpha: 0.14), r.fill);
      expect(contrastRatio(r.labels.first, pressed), greaterThanOrEqualTo(7));
    });

    test('fitLabelsToFill keeps a fill that already works', () {
      const fill = Color(0xFF202020);
      final r = fitLabelsToFill(fill, const [Color(0xFFFFFFFF)], 4.5, stateLayerAlpha: 0.14);
      expect(r.fill, fill);
      expect(r.labels.first, const Color(0xFFFFFFFF));
    });
  });

  group('shape tokens', () {
    test('scale is ascending and full is a pill', () {
      for (var i = 1; i < BooBoardShape.scale.length; i++) {
        expect(BooBoardShape.scale[i], greaterThan(BooBoardShape.scale[i - 1]));
      }
      expect(BooBoardShape.full, greaterThan(BooBoardShape.scale.last));
    });

    test('keyRadius clamps the factor', () {
      expect(BooBoardShape.keyRadius(0.5, 40), 20);
      expect(BooBoardShape.keyRadius(0, 40), 0);
      expect(BooBoardShape.keyRadius(2, 40), 20);
      expect(BooBoardShape.keyRadius(-1, 40), 0);
    });
  });

  group('motion tokens', () {
    test('fast spatial matches the Material 3 Expressive spec', () {
      expect(BooBoardMotion.fastSpatial, const SpringToken(800, 0.6));
    });

    test('spatial springs overshoot, effects springs do not', () {
      for (final s in [BooBoardMotion.fastSpatial, BooBoardMotion.defaultSpatial, BooBoardMotion.slowSpatial]) {
        expect(s.dampingRatio, lessThan(1));
      }
      for (final s in [BooBoardMotion.fastEffects, BooBoardMotion.defaultEffects, BooBoardMotion.slowEffects]) {
        expect(s.dampingRatio, 1);
      }
    });

    test('speeds are ordered', () {
      expect(BooBoardMotion.fastSpatial.stiffness, greaterThan(BooBoardMotion.defaultSpatial.stiffness));
      expect(BooBoardMotion.defaultSpatial.stiffness, greaterThan(BooBoardMotion.slowSpatial.stiffness));
      expect(BooBoardMotion.fastEffects.stiffness, greaterThan(BooBoardMotion.defaultEffects.stiffness));
      expect(BooBoardMotion.defaultEffects.stiffness, greaterThan(BooBoardMotion.slowEffects.stiffness));
    });

    test('scaled keeps damping', () {
      final s = BooBoardMotion.fastSpatial.scaled(2);
      expect(s.stiffness, 1600);
      expect(s.dampingRatio, 0.6);
    });
  });

  group('type tokens', () {
    test('variations clamp to the font axes', () {
      final v = BooBoardType.variations(weight: 5000, roundness: -5);
      expect(v[0].axis, 'wght');
      expect(v[0].value, 1000);
      expect(v[1].axis, 'ROND');
      expect(v[1].value, 0);
    });
  });

  test('android tone list has 13 stops', () {
    expect(androidTones.length, 13);
    expect(androidTones.first, 0);
    expect(androidTones.last, 1000);
  });
}
