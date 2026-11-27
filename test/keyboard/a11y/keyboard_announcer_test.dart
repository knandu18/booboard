// SPDX-License-Identifier: GPL-3.0-or-later
//
// Announcements follow page, shift and language changes, panels and swipe typing. They never carry
// typed text: every message is one of the fixed event names below.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/keyboard/a11y/candidate_labels.dart';
import 'package:booboard/src/keyboard/a11y/keyboard_announcer.dart';
import 'package:booboard/src/keyboard/input/input_controller.dart';
import 'package:booboard/src/keyboard/input/keyboard_page.dart';

void main() {
  late List<String> sent;
  late KeyboardAnnouncer announcer;
  late ValueNotifier<KeyboardPage> page;
  late ValueNotifier<ShiftState> shift;
  late ValueNotifier<String?> language;

  setUp(() {
    sent = [];
    announcer = KeyboardAnnouncer((message) async => sent.add(message));
    page = ValueNotifier(KeyboardPage.letters);
    shift = ValueNotifier(ShiftState.off);
    language = ValueNotifier('English');
    announcer.bind(page: page, shift: shift, language: language);
  });

  tearDown(() {
    announcer.dispose();
    page.dispose();
    shift.dispose();
    language.dispose();
  });

  test('binding is silent: the current values are the baseline', () {
    expect(sent, isEmpty);
  });

  test('a page change announces the page name', () {
    page.value = KeyboardPage.symbols;
    page.value = KeyboardPage.symbols2;
    page.value = KeyboardPage.letters;
    expect(sent, ['Symbols', 'More symbols', 'Letters']);
  });

  test('field pages are not announced', () {
    page.value = KeyboardPage.numpad;
    page.value = KeyboardPage.phone;
    expect(sent, isEmpty);
  });

  test('a language switch announces the language name', () {
    language.value = 'Deutsch';
    language.value = null;
    expect(sent, ['Deutsch']);
  });

  test('caps lock on and off are announced; shift once is not', () {
    shift.value = ShiftState.once;
    expect(sent, isEmpty);
    shift.value = ShiftState.caps;
    shift.value = ShiftState.off;
    expect(sent, ['Caps lock on', 'Caps lock off']);
  });

  test('a swipe-typed word announces the event, not the word', () {
    announcer.swipeTyped();
    expect(sent, ['Swipe typed']);
  });

  test('panels announce open and closed by name', () {
    announcer.panelOpened('Emoji');
    announcer.panelClosed('Emoji');
    expect(sent, ['Emoji open', 'Emoji closed']);
  });

  test('a failed send never breaks the keyboard', () async {
    final failing = KeyboardAnnouncer((_) => Future<void>.error(StateError('no view')));
    failing.swipeTyped();
    // The error is absorbed: no uncaught async error reaches the zone.
    await Future<void>.delayed(Duration.zero);
    failing.dispose();
  });

  test('no announcement carries typed text', () {
    page.value = KeyboardPage.symbols;
    shift.value = ShiftState.caps;
    language.value = 'Hindi';
    announcer.swipeTyped();
    announcer.panelOpened('Clipboard');
    const allowed = {'Symbols', 'Caps lock on', 'Hindi', 'Swipe typed', 'Clipboard open'};
    expect(sent.every(allowed.contains), isTrue, reason: '$sent');
  });

  test('candidates are labelled with their position', () {
    const candidates = [ComposerCandidate('你好', annotation: 'ni hao'), ComposerCandidate('泥')];
    expect(candidateSemanticsLabel(candidates[0], index: 0, total: 12), 'Candidate 你好, ni hao, 1 of 12');
    expect(candidateSemanticsLabel(candidates[1], index: 1, total: 2), 'Candidate 泥, 2 of 2');
  });
}
