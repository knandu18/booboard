// SPDX-License-Identifier: GPL-3.0-or-later
//
// Right-to-left (Wave 3-C): with Arabic active the strip and the panels mirror, the Arabic layout
// reads right to left on screen, and the editing panel's directional pad stays physical.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';
import 'package:booboard/src/features/features.dart';
import 'package:booboard/src/features/emoji/emoji_repository.dart';
import 'package:booboard/src/keyboard/input/keyboard_page.dart';
import 'package:booboard/src/keyboard/keyboard_app.dart';
import 'package:booboard/src/keyboard/keyboard_session.dart';
import 'package:booboard/src/keyboard/layout/layout_model.dart';
import 'package:booboard/src/settings/booboard_settings.dart';

import '../../keyboard/support/app_harness.dart';

class _Probe extends KeyboardFeature {
  KeyboardSession? session;

  @override
  KeyboardHooks attach(KeyboardSession s) {
    session = s;
    return const KeyboardHooks();
  }
}

/// Arabic active. The strip shows next-word predictions unless [predictions] is off (then the toolbar).
BooBoardSettings _arabic({required bool predictions}) => BooBoardSettings(
  languages: const LanguageSettings(enabled: ['ar'], active: 'ar'),
  typing: TypingSettings(nextWordPrediction: predictions),
);

Future<(AppHarness, _Probe, KeyboardLayoutDef)> boot(WidgetTester tester, {bool predictions = true}) async {
  final h = AppHarness(settings: _arabic(predictions: predictions));
  // The best suggestion is 'نعم', the second 'لا', the third 'هذا'.
  h.predictor.next = const ['نعم', 'لا', 'هذا'];
  final probe = _Probe();
  final panels = createPanelsFeature(emojiRepository: EmojiRepository.fromDirectory('assets/emoji'));
  await h.pump(tester, features: [probe, panels]);
  await h.focus(tester);
  final layout = probe.session!.layoutFor(KeyboardPage.letters, InputFieldInfo.plainText, h.store.value)!;
  return (h, probe, layout);
}

/// Lets the emoji index and the panels' async loads finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

double centreX(WidgetTester tester, String label) => tester.getCenter(find.bySemanticsLabel(label)).dx;

void main() {
  group('keys', () {
    testWidgets('the Arabic letters run right to left on screen, with the first letter at the right', (tester) async {
      final (_, _, layout) = await boot(tester);
      final keys = KeyFinder(tester, layout);
      final row = keys.laid.keys.where((k) => k.row == 0 && k.def.isCharacter).toList()
        ..sort((a, b) => a.rect.left.compareTo(b.rect.left));
      // The file lists the keys left to right as they look on screen: ج is the leftmost, ض the rightmost.
      expect(row.first.def.output, 'ج');
      expect(row.last.def.output, 'ض');
      expect(keys.byOutput('ا').rect.center.dx, lessThan(keys.byOutput('ي').rect.center.dx));
    });
  });

  group('strip', () {
    testWidgets('best suggestion in the centre, the second on the right, in right-to-left text', (tester) async {
      await boot(tester);
      final best = centreX(tester, 'Suggestion نعم');
      final second = centreX(tester, 'Suggestion لا');
      final third = centreX(tester, 'Suggestion هذا');
      expect(second, greaterThan(best), reason: 'the second suggestion is on the right');
      expect(third, lessThan(best), reason: 'the third suggestion is on the left');
    });

    testWidgets('the suggestion text is laid out right to left', (tester) async {
      await boot(tester);
      final text = tester.widget<Text>(find.text('نعم').first);
      expect(Directionality.of(tester.element(find.text('نعم').first)), TextDirection.rtl);
      expect(text.textAlign, anyOf(isNull, TextAlign.start), reason: 'start is the right edge in RTL');
    });
  });

  group('panels', () {
    testWidgets('the editing panel: the directional pad stays physical, Start of line sits on the right', (
      tester,
    ) async {
      await boot(tester, predictions: false);
      await tester.longPress(find.bySemanticsLabel('Settings'));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(find.bySemanticsLabel('Text editing'));
      await settle(tester);
      expect(centreX(tester, 'Move left'), lessThan(centreX(tester, 'Move right')));
      expect(centreX(tester, 'Start of line'), greaterThan(centreX(tester, 'Move left')));
      expect(centreX(tester, 'Undo'), lessThan(centreX(tester, 'Move left')));
    });

    testWidgets('the emoji panel: Back to letters mirrors to the other side of Delete', (tester) async {
      await boot(tester, predictions: false);
      await tester.tap(find.bySemanticsLabel('Emoji'));
      await settle(tester);
      final back = centreX(tester, 'Back to letters');
      final delete = centreX(tester, 'Delete');
      expect(back, greaterThan(delete), reason: 'the bottom row mirrors in right-to-left text');
    });
  });

  test('emoji, clipboard and shared panels hard-code no left-to-right text direction', () {
    // The editing panel forces LTR on its directional pad on purpose, so it is not checked here.
    for (final folder in ['emoji', 'clipboard', 'shared']) {
      for (final file in Directory('lib/src/features/$folder').listSync(recursive: true).whereType<File>()) {
        expect(file.readAsStringSync(), isNot(contains('TextDirection.ltr')), reason: file.path);
      }
    }
  });
}
