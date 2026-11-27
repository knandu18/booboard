// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-C. Arabic-script languages (ar, ur): their info and rules.
// The orchestrator seeded the entries; refine them as you build.
import '../contracts.dart';
import 'language_info.dart';

const List<LanguageInfo> arabicLanguages = [
  LanguageInfo(
    id: 'ar',
    englishName: 'Arabic',
    nativeName: 'العربية',
    script: 'Arab',
    hasCase: false,
    layouts: [LayoutChoice('arabic', 'Arabic', script: 'Arab')],
    currency: 'ر.س',
    domains: ['.sa', '.ae', '.eg'],
    nativeDigits: '٠١٢٣٤٥٦٧٨٩',
  ),
  LanguageInfo(
    id: 'ur',
    englishName: 'Urdu',
    nativeName: 'اردو',
    script: 'Arab',
    hasCase: false,
    layouts: [LayoutChoice('urdu_phonetic', 'Phonetic', script: 'Arab')],
    currency: 'Rs',
    domains: ['.pk', '.com.pk'],
    nativeDigits: '۰۱۲۳۴۵۶۷۸۹',
  ),
];

/// Rules for the languages above; null for any other language.
LanguageRules? arabicRules(LanguageId language) => switch (language) {
  'ar' => ArabicRules('ar', quotes: ('«', '»')),
  'ur' => ArabicRules('ur', quotes: ('“', '”')),
  _ => null,
};

/// Arabic-script rules: no case, Arabic letters and marks are word characters, and the Arabic
/// punctuation marks (، ؛ ؟ ۔) behave like their Latin counterparts.
class ArabicRules implements LanguageRules {
  const ArabicRules(this.language, {required this.quotes});

  @override
  final LanguageId language;

  @override
  final (String, String) quotes;

  /// Letters, harakat, tatweel, and ZWNJ (Urdu joins words with it).
  static final RegExp _wordChar = RegExp(r'[\p{L}\p{M}ـ‌]', unicode: true);

  /// Sentence-ending marks: Latin . ! ? and the Arabic question mark, Arabic semicolon and Urdu full stop.
  static const Set<String> _sentenceEnds = {'.', '!', '?', '؟', '۔'};

  /// Punctuation that swallows a preceding auto-space: Latin marks plus the Arabic ones.
  static const Set<String> _closers = {'.', ',', '!', '?', ':', ';', ')', ']', '}', '%', '،', '؛', '؟', '۔'};

  /// Punctuation after which a space is inserted automatically.
  static const Set<String> _spaceAfter = {'.', ',', '!', '?', ':', ';', '،', '؛', '؟', '۔'};

  @override
  bool get hasCase => false;

  @override
  bool isWordChar(String char) => _wordChar.hasMatch(char);

  @override
  bool removesSpaceBefore(String punctuation) => _closers.contains(punctuation);

  @override
  String? spaceBefore(String punctuation) => null;

  @override
  bool addsSpaceAfter(String punctuation) => _spaceAfter.contains(punctuation);

  @override
  bool endsSentence(String punctuation) => _sentenceEnds.contains(punctuation);
}
