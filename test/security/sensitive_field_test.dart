// SPDX-License-Identifier: GPL-3.0-or-later
//
// Sensitive-field rules. Password variations are sensitive: no suggestions, no learning, no popups, no swipe,
// no emoji, no voice, no translation and FLAG_SECURE. TYPE_TEXT_FLAG_NO_SUGGESTIONS fields are sensitive too
// (no suggestions, no learning, no popups, no voice, no translation, FLAG_SECURE) but keep swipe and emoji
// (decision 2026-11-25).
//
// IME_FLAG_NO_PERSONALIZED_LEARNING (private browsing) is not sensitive since 2026-11-25: only learning is
// off there, everything else works. It still gets FLAG_SECURE (`shouldSecureWindow`).
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/core/input_field_info.dart';

InputFieldInfo _field({int variation = 0, int flags = 0, int ime = 0}) =>
    InputFieldInfo(inputType: AndroidInputType.classText | variation | flags, imeOptions: ime);

void main() {
  test('a password field is sensitive and gets no suggestions or learning', () {
    final f = _field(variation: AndroidInputType.textVariationPassword);
    expect(f.isSensitive, isTrue);
    expect(f.allowsSuggestions, isFalse);
    expect(f.allowsLearning, isFalse);
  });

  test('a plain text field is not sensitive', () {
    final f = _field();
    expect(f.isSensitive, isFalse);
    expect(f.allowsSuggestions, isTrue);
    expect(f.allowsLearning, isTrue);
  });

  test('IME_FLAG_NO_PERSONALIZED_LEARNING turns learning off and nothing else', () {
    final f = _field(ime: AndroidImeOptions.flagNoPersonalizedLearning);
    expect(f.allowsLearning, isFalse);
    expect(f.isSensitive, isFalse);
    expect(f.allowsSuggestions, isTrue);
    expect(f.allowsAutoCorrect, isTrue);
  });

  test('TYPE_TEXT_FLAG_NO_SUGGESTIONS turns suggestions and learning off, but keeps swipe', () {
    final f = _field(flags: AndroidInputType.textFlagNoSuggestions);
    expect(f.allowsSuggestions, isFalse);
    expect(f.allowsLearning, isFalse);
    expect(f.allowsSwipe, isTrue);
  });

  test('swipe is off only in password fields', () {
    expect(_field(variation: AndroidInputType.textVariationPassword).allowsSwipe, isFalse);
    expect(_field().allowsSwipe, isTrue);
  });

  test('no-suggestions fields are sensitive; no-personalised-learning fields are not', () {
    expect(_field(flags: AndroidInputType.textFlagNoSuggestions).isSensitive, isTrue);
    expect(_field(ime: AndroidImeOptions.flagNoPersonalizedLearning).isSensitive, isFalse);
  });
}
