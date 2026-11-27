// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/app/privacy/learned_words_screen.dart';
import 'package:booboard/src/engine/learn/learned_data.dart';

import 'privacy_harness.dart';

void main() {
  late PrivacyHarness h;

  setUp(() {
    h = PrivacyHarness();
    final data = LearnedData('en')
      ..commitWord('hello', 'hello', 1000, novel: false)
      ..commitWord('world', 'world', 1000, novel: false)
      ..commitWord('world', 'world', 1000, novel: false);
    h.store.blobs['learned_en'] = data.encode();
  });

  tearDown(() => h.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(h.host(const LearnedWordsScreen(languageId: 'en')));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the learned words without the blocked list', (tester) async {
    await pumpScreen(tester);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('world'), findsOneWidget);
    expect(find.text('Learned words (English)'), findsOneWidget);
  });

  testWidgets('never suggest moves a word to the blocked list and removes it from the learned set', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Actions for hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Never suggest this word'));
    await tester.pumpAndSettle();

    final saved = LearnedData.decode('en', h.store.blobs['learned_en']);
    expect(saved.blocked, contains('hello'));
    expect(saved.words.containsKey('hello'), isFalse);
    expect(saved.words.containsKey('world'), isTrue);
    expect(find.text('hello'), findsNothing);
  });

  testWidgets('forget removes a word from the learned set', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Actions for world'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forget this word'));
    await tester.pumpAndSettle();

    final saved = LearnedData.decode('en', h.store.blobs['learned_en']);
    expect(saved.words.containsKey('world'), isFalse);
    expect(saved.blocked, isEmpty);
  });

  testWidgets('search filters the list', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'wor');
    await tester.pumpAndSettle();
    expect(find.text('world'), findsOneWidget);
    expect(find.text('hello'), findsNothing);
  });

  testWidgets('a locked phone shows a message instead of an empty list', (tester) async {
    h.store.locked.add('learned_en');
    await pumpScreen(tester);

    expect(find.textContaining('cannot read these words right now'), findsOneWidget);
  });

  testWidgets('a language with nothing stored says so', (tester) async {
    h.store.blobs.remove('learned_en');
    await pumpScreen(tester);
    expect(find.textContaining('No words learned in this language yet'), findsOneWidget);
  });

  testWidgets('the screen asks for FLAG_SECURE while it is open and clears it on leave', (tester) async {
    await pumpScreen(tester);
    verify(() => h.app.setSecureScreen(true)).called(1);

    await tester.pumpWidget(h.host(const SizedBox()));
    await tester.pumpAndSettle();
    verify(() => h.app.setSecureScreen(false)).called(1);
  });
}
