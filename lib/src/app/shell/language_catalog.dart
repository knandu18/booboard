// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A, Wave 3-A. Language names and layouts for the settings app. Everything reads the
// language registry (engine/lang/registry.dart), so a language or layout added there shows up here.
import 'dart:ui' show Locale;

import '../../engine/lang/registry.dart';
import '../../settings/booboard_settings.dart';

const String englishId = 'en';

/// The language's own name ("Deutsch", "हिन्दी"); the id when unknown.
String languageLabel(String id) => languageInfo(id).nativeName;

/// Layout name for a layout id ("QWERTZ", "ЙЦУКЕН"), searched across every language; the id when unknown.
String layoutLabel(String id) {
  for (final info in allLanguages) {
    for (final layout in info.layouts) {
      if (layout.id == id) return layout.name;
    }
  }
  return id;
}

/// The layout id [language] uses with these settings.
String layoutFor(LanguageSettings languages, String language) => layoutChoiceFor(languages, language).id;

/// Languages the Languages screen and onboarding list, in registry order (English first).
List<LanguageInfo> get selectableLanguages => allLanguages;

/// Case- and accent-insensitive search over English and native names.
List<LanguageInfo> searchLanguages(String query) {
  final q = _fold(query.trim());
  if (q.isEmpty) return selectableLanguages;
  return [
    for (final info in selectableLanguages)
      if (_fold(info.englishName).contains(q) || _fold(info.nativeName).contains(q) || info.id.toLowerCase() == q) info,
  ];
}

/// The language the system locale asks for, when BooBoard supports it: "pt" becomes pt-BR or pt-PT by
/// region. Null for unsupported locales.
String? supportedLocaleLanguage(Locale locale) {
  final code = locale.languageCode.toLowerCase();
  if (code == 'pt') return locale.countryCode?.toUpperCase() == 'PT' ? 'pt-PT' : 'pt-BR';
  for (final info in selectableLanguages) {
    if (info.id.toLowerCase() == code) return info.id;
  }
  return null;
}

String _fold(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[áàâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[íìîï]'), 'i')
    .replaceAll(RegExp('[óòôö]'), 'o')
    .replaceAll(RegExp('[úùûü]'), 'u')
    .replaceAll('ñ', 'n')
    .replaceAll('ç', 'c');
