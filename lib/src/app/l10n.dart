// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned, Wave 4): localisation of the settings app. Strings live in
// lib/l10n/app_<locale>.arb (template: app_en.arb); `flutter pub get` regenerates
// lib/l10n/app_localizations*.dart (l10n.yaml). Screens read them with `context.l10n.someKey`.
// Every MaterialApp in the app and in widget tests uses [booboardLocalizationsDelegates].
//
// The generated `AppLocalizations.localizationsDelegates` list is not used: it names
// flutter_localizations' Material delegate, while this app's Material comes from material_ui.
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

// material_ui's MaterialApp always appends English-only Default*Localizations, so every other locale
// needs the global Cupertino delegate (material_ui's own, matching that type) as well as Material and
// Widgets. Adding only flutter_localizations' Cupertino delegate does not satisfy the check.
const List<LocalizationsDelegate<dynamic>> booboardLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

const List<Locale> booboardSupportedLocales = AppLocalizations.supportedLocales;

extension BooBoardL10n on BuildContext {
  /// The settings app's strings in the current locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
