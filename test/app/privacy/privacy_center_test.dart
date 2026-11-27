// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../security/support/fakes.dart';

import 'package:booboard/src/app/privacy/privacy_center_screen.dart';
import 'package:booboard/src/core/data_sections.dart';
import 'package:booboard/src/engine/learn/learned_data.dart';
import 'package:booboard/src/security/app_auth.dart';
import 'package:booboard/src/security/shortcuts_store.dart';

import 'privacy_harness.dart';

Uint8List _learnedEn() => (LearnedData('en')..commitWord('hello', 'hello', 1000, novel: false)).encode();

/// The settings list builds rows lazily, so scroll until a row is on screen.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder.first);
  await tester.pump();
}

void main() {
  late PrivacyHarness h;

  setUp(() {
    registerSecurityFallbacks();
    h = PrivacyHarness();
    h.store.blobs['learned_en'] = _learnedEn();
    h.store.blobs[DataBlobs.shortcuts] = ShortcutsStore.encode(const [
      PersonalShortcut(trigger: 'omw', expansion: 'on my way'),
    ]);
    h.store.blobs[DataBlobs.clipboard] = Uint8List.fromList(utf8.encode('[]'));
  });

  tearDown(() => h.dispose());

  Future<void> pumpCenter(WidgetTester tester, FakeAuth auth) async {
    await tester.pumpWidget(h.host(PrivacyCenterScreen(authenticator: auth)));
    await settleIo(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the no-internet proof and what is stored, by name and size only', (tester) async {
    await pumpCenter(tester, FakeAuth());

    expect(find.text('BooBoard has no internet permission. It cannot send anything.'), findsOneWidget);
    expect(find.text('Learned words (English)'), findsOneWidget);
    expect(find.text('Clipboard history'), findsOneWidget);
    expect(find.textContaining('hello'), findsNothing); // never shows contents
  });

  testWidgets('the always-incognito list offers a switch per app', (tester) async {
    await tester.runAsync(() async {
      await h.services.seenApps.record('com.bank.app');
      await h.services.seenApps.flush();
    });
    await pumpCenter(tester, FakeAuth());

    await reveal(tester, find.text('com.bank.app'));
    final row = find.widgetWithText(ListTile, 'com.bank.app');
    expect(row, findsOneWidget);
    await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    expect(h.services.settings.value.privacy.incognitoApps, contains('com.bank.app'));
  });

  testWidgets('turning app lock on needs one successful device check first', (tester) async {
    final auth = FakeAuth()..answers.add(AuthOutcome.success);
    await pumpCenter(tester, auth);

    final lock = find.widgetWithText(SwitchListTile, 'Lock BooBoard');
    await reveal(tester, lock);
    await tester.tap(lock);
    await tester.pumpAndSettle();

    expect(auth.calls, 1);
    expect(h.services.settings.value.privacy.appLock, isTrue);
  });

  testWidgets('a cancelled check leaves app lock off', (tester) async {
    final auth = FakeAuth()..answers.add(AuthOutcome.cancelled);
    await pumpCenter(tester, auth);

    final lock = find.widgetWithText(SwitchListTile, 'Lock BooBoard');
    await reveal(tester, lock);
    await tester.tap(lock);
    await tester.pumpAndSettle();

    expect(h.services.settings.value.privacy.appLock, isFalse);
  });

  testWidgets('without a device lock, app lock stays off and says why', (tester) async {
    final auth = FakeAuth(secure: false);
    await pumpCenter(tester, auth);

    final lock = find.widgetWithText(SwitchListTile, 'Lock BooBoard');
    await reveal(tester, lock);
    await tester.tap(lock);
    await tester.pumpAndSettle();

    expect(auth.calls, 0);
    expect(find.text('Set a screen lock first'), findsOneWidget);
    expect(h.services.settings.value.privacy.appLock, isFalse);
  });

  testWidgets('deleting learned words asks first, lists what goes, and then deletes', (tester) async {
    await pumpCenter(tester, FakeAuth());

    final tile = find.text('Learned words');
    await reveal(tester, tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('Delete learned words?'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    expect(h.store.blobs.containsKey('learned_en'), isTrue, reason: 'nothing deleted before confirming');

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleIo(tester);
    await tester.pumpAndSettle();

    expect(h.store.blobs.containsKey('learned_en'), isFalse);
    expect(h.store.blobs.containsKey(DataBlobs.shortcuts), isTrue, reason: 'other categories are untouched');
    verify(() => h.platform.notifySettingsChanged(any(that: equals([DataSections.learned])))).called(1);
  });

  testWidgets('cancelling the wipe changes nothing', (tester) async {
    await pumpCenter(tester, FakeAuth());

    // Scroll to the bottom row first: the wipe group is the last one, and the list builds rows lazily.
    await reveal(tester, find.text('Erase everything'));
    final tile = find.widgetWithText(ListTile, 'Personal shortcuts').last;
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('Delete personal shortcuts?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(h.store.blobs.containsKey(DataBlobs.shortcuts), isTrue);
  });
}
