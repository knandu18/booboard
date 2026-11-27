// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 4-A (Chinese). Seeded by the orchestrator: the language entry and its rules. Keep the
// names `chineseLanguages` and `chineseRules`; registry.dart reads them.
import '../contracts.dart';
import 'cjk_rules.dart';
import 'language_info.dart';

const List<LanguageInfo> chineseLanguages = [
  LanguageInfo(
    id: 'zh',
    englishName: 'Chinese (Simplified)',
    nativeName: '中文（简体）',
    script: 'Hans',
    layouts: [LayoutChoice('pinyin_zh', 'Pinyin', script: 'Latn', composes: true)],
    spaceLabel: '中文',
    hasCase: false,
    currency: '¥',
    domains: ['.cn', '.com.cn'],
  ),
];

/// Rules for the languages above; null for any other language.
LanguageRules? chineseRules(LanguageId language) => language == 'zh' ? const CjkRules('zh') : null;
