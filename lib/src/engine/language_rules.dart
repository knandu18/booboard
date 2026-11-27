// SPDX-License-Identifier: GPL-3.0-or-later
//
// Default (English) language rules. Wave 3 agents add per-language rules in
// lib/src/engine/lang/ (european.dart, indic.dart, arabic.dart); lang/registry.dart picks them.
import 'contracts.dart';
import 'lang/registry.dart' show rulesForLanguage;

class DefaultLanguageRules implements LanguageRules {
  const DefaultLanguageRules([this.language = 'en']);

  @override
  final LanguageId language;

  static final RegExp _letter = RegExp(r"[\p{L}\p{M}\p{Nd}'’\-]", unicode: true);

  @override
  bool get hasCase => true;

  @override
  bool isWordChar(String char) => _letter.hasMatch(char);

  @override
  bool removesSpaceBefore(String punctuation) =>
      const {'.', ',', '!', '?', ':', ';', ')', ']', '}', '%'}.contains(punctuation);

  @override
  String? spaceBefore(String punctuation) => null;

  @override
  bool addsSpaceAfter(String punctuation) => const {'.', ',', '!', '?', ':', ';'}.contains(punctuation);

  @override
  bool endsSentence(String punctuation) => const {'.', '!', '?'}.contains(punctuation);

  @override
  (String, String) get quotes => ('“', '”');
}

typedef LanguageRulesResolver = LanguageRules Function(LanguageId language);

/// Rules for [language]. Unknown languages get English-like rules.
LanguageRules languageRulesFor(LanguageId language) => rulesForLanguage(language);
