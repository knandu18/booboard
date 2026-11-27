// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-B. Indic languages (hi, mr, bn, ta, te): their info and rules.
// The orchestrator seeded the entries; refine them as you build. The first layout of each is
// "English letters" (transliteration), so a new user can type right away.
import '../contracts.dart';
import 'indic/indic_rules.dart';
import 'language_info.dart';

const List<LanguageInfo> indicLanguages = [
  LanguageInfo(
    id: 'hi',
    englishName: 'Hindi',
    nativeName: 'हिन्दी',
    script: 'Deva',
    hasCase: false,
    layouts: [
      LayoutChoice('translit_hi', 'English letters', script: 'Latn', transliterates: true),
      LayoutChoice('phonetic_hi', 'Phonetic', script: 'Deva'),
      LayoutChoice('inscript_hi', 'InScript', script: 'Deva'),
    ],
    currency: '₹',
    domains: ['.in', '.co.in', '.भारत'],
    nativeDigits: '०१२३४५६७८९',
  ),
  LanguageInfo(
    id: 'mr',
    englishName: 'Marathi',
    nativeName: 'मराठी',
    script: 'Deva',
    hasCase: false,
    layouts: [
      LayoutChoice('translit_mr', 'English letters', script: 'Latn', transliterates: true),
      LayoutChoice('phonetic_mr', 'Phonetic', script: 'Deva'),
      LayoutChoice('inscript_mr', 'InScript', script: 'Deva'),
    ],
    currency: '₹',
    domains: ['.in', '.co.in'],
    nativeDigits: '०१२३४५६७८९',
  ),
  LanguageInfo(
    id: 'bn',
    englishName: 'Bengali',
    nativeName: 'বাংলা',
    script: 'Beng',
    hasCase: false,
    layouts: [
      LayoutChoice('translit_bn', 'English letters', script: 'Latn', transliterates: true),
      LayoutChoice('phonetic_bn', 'Phonetic', script: 'Beng'),
      LayoutChoice('inscript_bn', 'InScript', script: 'Beng'),
    ],
    currency: '₹',
    domains: ['.in', '.com.bd'],
    nativeDigits: '০১২৩৪৫৬৭৮৯',
  ),
  LanguageInfo(
    id: 'ta',
    englishName: 'Tamil',
    nativeName: 'தமிழ்',
    script: 'Taml',
    hasCase: false,
    layouts: [
      LayoutChoice('translit_ta', 'English letters', script: 'Latn', transliterates: true),
      LayoutChoice('phonetic_ta', 'Phonetic', script: 'Taml'),
      LayoutChoice('inscript_ta', 'InScript', script: 'Taml'),
    ],
    currency: '₹',
    domains: ['.in', '.lk'],
    nativeDigits: '௦௧௨௩௪௫௬௭௮௯',
  ),
  LanguageInfo(
    id: 'te',
    englishName: 'Telugu',
    nativeName: 'తెలుగు',
    script: 'Telu',
    hasCase: false,
    layouts: [
      LayoutChoice('translit_te', 'English letters', script: 'Latn', transliterates: true),
      LayoutChoice('phonetic_te', 'Phonetic', script: 'Telu'),
      LayoutChoice('inscript_te', 'InScript', script: 'Telu'),
    ],
    currency: '₹',
    domains: ['.in'],
    nativeDigits: '౦౧౨౩౪౫౬౭౮౯',
  ),
];

/// Rules for the languages above; null for any other language.
LanguageRules? indicRules(LanguageId language) => switch (language) {
  'hi' || 'mr' || 'bn' => IndicRules(language, danda: true),
  'ta' || 'te' => IndicRules(language),
  _ => null,
};
