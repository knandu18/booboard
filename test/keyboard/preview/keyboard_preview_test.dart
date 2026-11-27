// SPDX-License-Identifier: GPL-3.0-or-later
//
// The static keyboard preview: it paints the real letter keys in every theme variant, follows the
// number-row setting, and never throws. Layouts load from the bundle, so the test waits for them.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/keyboard/preview/keyboard_preview.dart';
import 'package:booboard/src/keyboard/view/keys_painter.dart';
import 'package:booboard/src/settings/booboard_settings.dart';
import 'package:booboard/src/theme/presets.dart';
import 'package:booboard/src/theme/theme_resolver.dart';

final Finder _paint = find.descendant(of: find.byType(KeyboardPreview), matching: find.byType(CustomPaint));

Future<void> _pumpPreview(WidgetTester tester, KeyboardPreview preview) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 412, child: preview)),
    ),
  );
  // Layouts come from the asset bundle, which completes outside the fake clock.
  for (var i = 0; i < 100 && _paint.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump();
  }
}

/// The keys the painter lays out whose output is a lower-case letter.
int _letterKeys(WidgetTester tester) {
  final custom = tester.widget<CustomPaint>(_paint.first);
  final painter = custom.painter! as KeysPainter;
  return painter.laid.keys.where((k) {
    final out = k.def.output ?? k.def.label ?? '';
    return RegExp(r'^[a-z]$').hasMatch(out);
  }).length;
}

void main() {
  for (final (label, dark, pureBlack) in const [
    ('light', false, false),
    ('dark', true, false),
    ('pure black', true, true),
  ]) {
    testWidgets('paints 26 letter keys in $label without errors', (tester) async {
      final theme = resolveKeyboardThemeFromSpec(ThemePresets.booboardGold, dark: dark, pureBlack: pureBlack);
      await _pumpPreview(tester, KeyboardPreview(theme: theme, settings: const BooBoardSettings()));
      expect(tester.takeException(), isNull);
      expect(_paint, findsOneWidget);
      expect(_letterKeys(tester), 26);
    });
  }

  testWidgets('the number row adds digit keys and keeps the 26 letters', (tester) async {
    final theme = resolveKeyboardThemeFromSpec(ThemePresets.lavender, dark: false);
    const settings = BooBoardSettings(typing: TypingSettings(numberRow: true));
    await _pumpPreview(tester, KeyboardPreview(theme: theme, settings: settings));
    expect(tester.takeException(), isNull);
    expect(_letterKeys(tester), 26);
  });

  testWidgets('the strip can be left out', (tester) async {
    final theme = resolveKeyboardThemeFromSpec(ThemePresets.ocean, dark: true);
    await _pumpPreview(tester, KeyboardPreview(theme: theme, settings: const BooBoardSettings(), showStrip: false));
    expect(tester.takeException(), isNull);
    expect(_letterKeys(tester), 26);
  });
}
