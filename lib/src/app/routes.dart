// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned): settings-app route names. The keyboard opens
// them with `ImeHostApi.openSettings(route)`; the app reads the launch route
// with `AppHostApi.takeLaunchRoute()` and later ones from
// `AppServices.routeRequests`. Wave 2-A's shell maps them to screens.
abstract final class BooBoardRoutes {
  static const String home = 'home';
  static const String onboarding = 'onboarding';
  static const String languages = 'languages';
  static const String typing = 'typing';
  static const String feel = 'feel';
  static const String panels = 'panels';
  static const String clipboard = 'clipboard';
  static const String themes = 'themes';
  static const String privacy = 'privacy';
  static const String about = 'about';

  /// Wave 3: voice typing settings (3-D), translation settings (3-T), model packs (3-T). The
  /// keyboard opens [packs] when voice or translation has no pack for the language.
  static const String voice = 'voice';
  static const String translate = 'translate';
  static const String packs = 'packs';

  /// Wave 4: Chinese (4-A) and Japanese (4-B) typing options, linked from Languages.
  static const String chinese = 'chinese';
  static const String japanese = 'japanese';

  /// Making pictures with the offline image model (a "coming soon" page until the model ships).
  static const String images = 'images';

  static const List<String> all = [
    home,
    onboarding,
    languages,
    typing,
    feel,
    panels,
    clipboard,
    themes,
    privacy,
    about,
    voice,
    translate,
    packs,
    chinese,
    japanese,
    images,
  ];
}
