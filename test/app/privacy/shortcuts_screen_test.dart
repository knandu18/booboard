// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:booboard/src/app/privacy/shortcuts_screen.dart';
import 'package:booboard/src/core/data_sections.dart';
import 'package:booboard/src/security/shortcuts_store.dart';

import 'privacy_harness.dart';

void main() {
  late PrivacyHarness h;

  setUp(() => h = PrivacyHarness());

  tearDown(() => h.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(h.host(const ShortcutsScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty list explains shortcuts with examples', (tester) async {
    await pumpScreen(tester);
    expect(find.text('No shortcuts yet'), findsOneWidget);
    expect(find.textContaining('omw'), findsOneWidget);
    expect(find.textContaining('addr'), findsOneWidget);
  });

  testWidgets('adding a shortcut saves it and tells the keyboard', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Add shortcut'));
    await tester.pumpAndSettle();

    await tester.enterText(dialogField(0), 'omw');
    await tester.enterText(dialogField(1), 'on my way');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('omw'), findsOneWidget);
    expect(find.text('on my way'), findsOneWidget);
    final saved = ShortcutsStore.decode(h.store.blobs[DataBlobs.shortcuts]);
    expect(saved.single.trigger, 'omw');
    expect(saved.single.expansion, 'on my way');
    verify(() => h.platform.notifySettingsChanged(any(that: equals([DataSections.shortcuts])))).called(1);
  });

  testWidgets('an invalid short form shows its reason and keeps Save off', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Add shortcut'));
    await tester.pumpAndSettle();

    await tester.enterText(dialogField(0), 'a b');
    await tester.enterText(dialogField(1), 'x');
    await tester.pumpAndSettle();

    expect(find.textContaining('Use only letters, digits and apostrophes'), findsOneWidget);
    final save = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
    expect(save.onPressed, isNull);
    expect(h.store.blobs.containsKey(DataBlobs.shortcuts), isFalse);
  });

  testWidgets('a duplicate of an existing short form, in any case, is refused', (tester) async {
    h.store.blobs[DataBlobs.shortcuts] = ShortcutsStore.encode(const [
      PersonalShortcut(trigger: 'omw', expansion: 'on my way'),
    ]);
    await pumpScreen(tester);
    await tester.tap(find.text('Add shortcut'));
    await tester.pumpAndSettle();

    await tester.enterText(dialogField(0), 'OMW');
    await tester.enterText(dialogField(1), 'other');
    await tester.pumpAndSettle();

    expect(find.text('You already have a shortcut with this short form.'), findsOneWidget);
  });
}

/// The n-th text field inside the open dialog (the list behind it has a search field too).
Finder dialogField(int index) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).at(index);
