// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-A. Latin and Cyrillic alphabet languages (es, fr, de, pt-BR, pt-PT, id, fil, ru, uk): their
// info and rules.
import '../contracts.dart';
import 'language_info.dart';

const List<LanguageInfo> europeanLanguages = [
  LanguageInfo(
    id: 'es',
    englishName: 'Spanish',
    nativeName: 'Español',
    script: 'Latn',
    layouts: [
      LayoutChoice('qwerty_es', 'QWERTY (Ñ)', script: 'Latn'),
      LayoutChoice('qwerty', 'QWERTY', script: 'Latn'),
    ],
    currency: '€',
    domains: ['.es', '.com.mx', '.com.ar'],
  ),
  LanguageInfo(
    id: 'fr',
    englishName: 'French',
    nativeName: 'Français',
    script: 'Latn',
    layouts: [
      LayoutChoice('azerty', 'AZERTY', script: 'Latn'),
      LayoutChoice('qwerty', 'QWERTY', script: 'Latn'),
    ],
    currency: '€',
    domains: ['.fr', '.be', '.ca'],
  ),
  LanguageInfo(
    id: 'de',
    englishName: 'German',
    nativeName: 'Deutsch',
    script: 'Latn',
    layouts: [
      LayoutChoice('qwertz', 'QWERTZ', script: 'Latn'),
      LayoutChoice('qwertz_umlaut', 'QWERTZ (ÄÖÜ keys)', script: 'Latn'),
      LayoutChoice('qwerty', 'QWERTY', script: 'Latn'),
    ],
    currency: '€',
    domains: ['.de', '.at', '.ch'],
  ),
  LanguageInfo(
    id: 'pt-BR',
    englishName: 'Portuguese (Brazil)',
    nativeName: 'Português (Brasil)',
    spaceLabel: 'Português',
    script: 'Latn',
    layouts: [LayoutChoice('qwerty', 'QWERTY', script: 'Latn')],
    currency: r'R$',
    domains: ['.com.br', '.br'],
  ),
  LanguageInfo(
    id: 'pt-PT',
    englishName: 'Portuguese (Portugal)',
    nativeName: 'Português (Portugal)',
    spaceLabel: 'Português',
    script: 'Latn',
    layouts: [LayoutChoice('qwerty', 'QWERTY', script: 'Latn')],
    currency: '€',
    domains: ['.pt'],
  ),
  LanguageInfo(
    id: 'id',
    englishName: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
    spaceLabel: 'Indonesia',
    script: 'Latn',
    layouts: [LayoutChoice('qwerty', 'QWERTY', script: 'Latn')],
    currency: 'Rp',
    domains: ['.co.id', '.id'],
  ),
  // Filipino (added 2026-11-24): the Filipino alphabet has Ñ (and Ng, typed as two letters), so the Spanish
  // QWERTY with Ñ is the default. The dictionary is the Tagalog list (Taglish words included).
  LanguageInfo(
    id: 'fil',
    englishName: 'Filipino',
    nativeName: 'Filipino',
    script: 'Latn',
    layouts: [
      LayoutChoice('qwerty_es', 'QWERTY (Ñ)', script: 'Latn'),
      LayoutChoice('qwerty', 'QWERTY', script: 'Latn'),
    ],
    currency: '₱',
    domains: ['.ph', '.com.ph'],
  ),
  LanguageInfo(
    id: 'ru',
    englishName: 'Russian',
    nativeName: 'Русский',
    script: 'Cyrl',
    layouts: [LayoutChoice('jcuken_ru', 'ЙЦУКЕН', script: 'Cyrl')],
    currency: '₽',
    domains: ['.ru', '.рф'],
  ),
  LanguageInfo(
    id: 'uk',
    englishName: 'Ukrainian',
    nativeName: 'Українська',
    script: 'Cyrl',
    layouts: [LayoutChoice('jcuken_uk', 'ЙЦУКЕН', script: 'Cyrl')],
    currency: '₴',
    domains: ['.ua', '.com.ua'],
  ),
];

/// Punctuation that swallows a preceding auto-space.
const Set<String> _swallowsSpace = {'.', ',', '!', '?', ':', ';', ')', ']', '}', '%'};

/// Punctuation that takes a space after it.
const Set<String> _spaceAfter = {'.', ',', '!', '?', ':', ';'};

/// Rules for the European languages: punctuation spacing, quotes and sentence ends.
class EuropeanRules implements LanguageRules {
  const EuropeanRules(this.language, {required this.quotes, this.frenchSpacing = false, this.invertedMarks = false});

  @override
  final LanguageId language;

  @override
  final (String, String) quotes;

  /// French: a narrow no-break space before ; : ! ? (the previous auto-space is kept).
  final bool frenchSpacing;

  /// Spanish: ¿ and ¡ open a phrase, so no space follows them.
  final bool invertedMarks;

  static const Set<String> _frenchMarks = {';', ':', '!', '?'};

  // Letters, marks, digits, apostrophes (also Ukrainian ʼ) and hyphens.
  static final RegExp _wordChar = RegExp(r"[\p{L}\p{M}\p{Nd}'’ʼ\-]", unicode: true);

  @override
  bool get hasCase => true;

  @override
  bool isWordChar(String char) => _wordChar.hasMatch(char);

  @override
  bool removesSpaceBefore(String punctuation) {
    if (frenchSpacing && _frenchMarks.contains(punctuation)) return false;
    return _swallowsSpace.contains(punctuation);
  }

  @override
  String? spaceBefore(String punctuation) {
    if (frenchSpacing && _frenchMarks.contains(punctuation)) return ' ';
    return null;
  }

  @override
  bool addsSpaceAfter(String punctuation) {
    if (invertedMarks && (punctuation == '¿' || punctuation == '¡')) return false;
    return _spaceAfter.contains(punctuation);
  }

  @override
  bool endsSentence(String punctuation) => const {'.', '!', '?'}.contains(punctuation);
}

/// Rules for the languages above; null for any other language.
LanguageRules? europeanRules(LanguageId language) => switch (language) {
  'es' => EuropeanRules(language, quotes: ('“', '”'), invertedMarks: true),
  'fr' => EuropeanRules(language, quotes: ('« ', ' »'), frenchSpacing: true),
  'de' => EuropeanRules(language, quotes: ('„', '“')),
  'pt-BR' || 'pt-PT' => EuropeanRules(language, quotes: ('“', '”')),
  'id' || 'fil' => EuropeanRules(language, quotes: ('"', '"')),
  'ru' || 'uk' => EuropeanRules(language, quotes: ('«', '»')),
  _ => null,
};
