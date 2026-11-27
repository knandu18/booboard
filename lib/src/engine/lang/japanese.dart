// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-B (Japanese). Seeded by the orchestrator: the language entry and its rules. Keep the
// names `japaneseLanguages` and `japaneseRules`; registry.dart reads them.
import '../contracts.dart';
import 'cjk_rules.dart';
import 'language_info.dart';

const List<LanguageInfo> japaneseLanguages = [
  LanguageInfo(
    id: 'ja',
    englishName: 'Japanese',
    nativeName: '日本語',
    script: 'Jpan',
    layouts: [
      LayoutChoice('kana12_ja', '12-key (flick)', script: 'Hira', composes: true),
      LayoutChoice('romaji_ja', 'Romaji (QWERTY)', script: 'Latn', composes: true),
    ],
    spaceLabel: '日本語',
    hasCase: false,
    currency: '¥',
    domains: ['.jp', '.co.jp'],
  ),
];

/// Rules for the languages above; null for any other language.
LanguageRules? japaneseRules(LanguageId language) => language == 'ja' ? const CjkRules('ja', quotes: ('「', '」')) : null;
