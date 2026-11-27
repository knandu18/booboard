// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-A. The language step of onboarding: pick one or more languages, with search. The
// system locale is pre-selected when BooBoard supports it. Writes the `languages` section.
import 'dart:ui' show PlatformDispatcher;

import 'package:material_ui/material_ui.dart';

import '../../settings/booboard_settings.dart';
import '../app_services.dart';
import '../shell/language_catalog.dart';
import '../shell/settings_actions.dart';
import 'onboarding_style.dart';

import 'package:booboard/src/app/l10n.dart';

class OnboardingLanguagePicker extends StatefulWidget {
  const OnboardingLanguagePicker({super.key});

  @override
  State<OnboardingLanguagePicker> createState() => _OnboardingLanguagePickerState();
}

class _OnboardingLanguagePickerState extends State<OnboardingLanguagePicker> {
  final TextEditingController _search = TextEditingController();
  bool _preselected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _preselectLocale(AppScope.of(context).settings.value.languages);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// First run only: add the system locale's language to the front, unless it is already enabled.
  void _preselectLocale(LanguageSettings languages) {
    if (_preselected) return;
    _preselected = true;
    if (languages.onboardingDone) return;
    final locale = supportedLocaleLanguage(PlatformDispatcher.instance.locale);
    if (locale == null || languages.enabled.contains(locale)) return;
    _write((l) => l.copyWith(enabled: [locale, ...l.enabled], active: locale));
  }

  void _write(LanguageSettings Function(LanguageSettings current) change) {
    writeSettings(context, SettingsSection.languages, (s) {
      final next = change(s.languages);
      final enabled = next.enabled.isEmpty ? const ['en'] : next.enabled;
      return s.copyWith(
        languages: next.copyWith(enabled: enabled, active: enabled.contains(next.active) ? next.active : enabled.first),
      );
    });
  }

  void _toggle(LanguageSettings languages, String id) {
    if (languages.enabled.contains(id)) {
      if (languages.enabled.length == 1) return; // at least one language stays on
      _write((l) => l.copyWith(enabled: [...l.enabled]..remove(id)));
    } else {
      _write((l) => l.copyWith(enabled: [...l.enabled, id], active: l.active));
    }
  }

  @override
  Widget build(BuildContext context) => LiveSettings(
    builder: (context, settings) {
      final languages = settings.languages;
      final results = searchLanguages(_search.text);
      final palette = OnboardingPalette.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: context.l10n.onboardingSearchLanguages,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: palette.field,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(60),
                borderSide: BorderSide(color: palette.rule),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(60),
                borderSide: BorderSide(color: palette.rule),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingSelected([for (final id in languages.enabled) languageLabel(id)].join(', ')),
            style: TextStyle(fontSize: 13, color: palette.secondary),
          ),
          const SizedBox(height: 6),
          if (results.isNotEmpty)
            // Its own scroll, so the buttons below stay on screen.
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final info in results)
                    _LanguageRow(
                      name: info.nativeName,
                      english: info.englishName,
                      on: languages.enabled.contains(info.id),
                      onTap: () => _toggle(languages, info.id),
                    ),
                ],
              ),
            ),
          if (results.isEmpty)
            Padding(padding: EdgeInsets.all(16), child: Text(context.l10n.onboardingNoLanguageMatch)),
        ],
      );
    },
  );
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.name, required this.english, required this.on, required this.onTap});

  final String name;
  final String english;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = OnboardingPalette.of(context);
    return Semantics(
      checked: on,
      button: true,
      label: name == english ? name : '$name, $english',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.rule)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: name,
                      style: TextStyle(fontSize: 16, color: palette.ink),
                      children: [
                        if (english != name)
                          TextSpan(
                            text: '  $english',
                            style: TextStyle(fontSize: 13, color: palette.secondary),
                          ),
                      ],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? palette.button : Colors.transparent,
                    border: Border.all(color: on ? palette.button : palette.ink, width: 1.5),
                  ),
                  child: on ? Icon(Icons.check, size: 15, color: palette.onButton) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
