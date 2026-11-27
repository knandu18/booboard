// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-B. Punctuation and word rules for the Indic languages. Indic scripts have no case.
// Typing in English letters (the composing word is Latin) is a word too, so Latin letters count.
import '../../contracts.dart';

class IndicRules implements LanguageRules {
  const IndicRules(this.language, {this.danda = false});

  @override
  final LanguageId language;

  /// Hindi, Marathi and Bengali end sentences with the danda (।). Tamil and Telugu use '.'.
  final bool danda;

  static final RegExp _word = RegExp(r"[A-Za-z\p{L}\p{M}\p{Nd}'’‌‍]", unicode: true);

  static const _removesBefore = {'.', ',', '!', '?', ':', ';', ')', ']', '}', '%', '।', '॥'};
  static const _addsAfter = {'.', ',', '!', '?', ':', ';', '।', '॥'};

  @override
  bool get hasCase => false;

  @override
  bool isWordChar(String char) => _word.hasMatch(char);

  @override
  bool removesSpaceBefore(String punctuation) => _removesBefore.contains(punctuation);

  @override
  String? spaceBefore(String punctuation) => null;

  @override
  bool addsSpaceAfter(String punctuation) => _addsAfter.contains(punctuation);

  @override
  bool endsSentence(String punctuation) =>
      punctuation == '.' ||
      punctuation == '!' ||
      punctuation == '?' ||
      (danda && (punctuation == '।' || punctuation == '॥'));

  @override
  (String, String) get quotes => ('“', '”');
}
