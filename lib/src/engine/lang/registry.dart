// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (orchestrator-owned, Wave 3): every language the keyboard knows, merged from the
// per-agent files, plus the rules for blending and choosing layouts.
import '../../settings/sections/language_settings.dart';
import '../contracts.dart';
import '../language_rules.dart' show DefaultLanguageRules;
import 'arabic.dart';
import 'chinese.dart';
import 'european.dart';
import 'indic.dart';
import 'japanese.dart';
import 'language_info.dart';

export 'language_info.dart';

const LanguageInfo englishInfo = LanguageInfo(
  id: 'en',
  englishName: 'English',
  nativeName: 'English',
  script: 'Latn',
  layouts: [LayoutChoice('qwerty', 'QWERTY', script: 'Latn')],
  domains: ['.com', '.net', '.org', '.in', '.co.uk'],
);

/// All languages in display order: English, then each agent's list.
final List<LanguageInfo> allLanguages = List.unmodifiable([
  englishInfo,
  ...europeanLanguages,
  ...indicLanguages,
  ...arabicLanguages,
  ...chineseLanguages,
  ...japaneseLanguages,
]);

final Map<LanguageId, LanguageInfo> _byId = {for (final l in allLanguages) l.id: l};

/// Info for [id]; unknown ids get English-like info so the keyboard never breaks.
LanguageInfo languageInfo(LanguageId id) =>
    _byId[id] ?? LanguageInfo(id: id, englishName: id, nativeName: id, script: 'Latn', layouts: englishInfo.layouts);

bool isKnownLanguage(LanguageId id) => _byId.containsKey(id);

/// The layout [language] uses with these settings.
LayoutChoice layoutChoiceFor(LanguageSettings settings, LanguageId language) {
  final info = languageInfo(language);
  return info.layout(settings.layouts[language]) ?? info.defaultLayout;
}

/// Languages the predictor and swipe decoder blend: the active one first, then (when multilingual
/// is on) other enabled languages whose words are in the script the active layout types, up to
/// [max] in total. With a transliterating layout (Hindi in English letters) that script is Latin,
/// so English joins the blend and the Indic feature adds the native-script candidates.
List<LanguageId> blendedLanguages(LanguageSettings settings, {int max = 3}) {
  final active = settings.active;
  final choice = layoutChoiceFor(settings, active);
  final script = choice.script;
  final out = [active];
  // A composing layout (Chinese, Japanese) turns every key into candidates itself.
  if (!settings.multilingual || choice.composes) return out;
  for (final id in settings.enabled) {
    if (out.length >= max) break;
    if (out.contains(id)) continue;
    final other = layoutChoiceFor(settings, id);
    if (!other.transliterates && !other.composes && other.script == script && languageInfo(id).script == script) {
      out.add(id);
    }
  }
  return out;
}

/// Language rules: the agent files first, English-like defaults otherwise.
LanguageRules rulesForLanguage(LanguageId language) =>
    europeanRules(language) ??
    indicRules(language) ??
    arabicRules(language) ??
    chineseRules(language) ??
    japaneseRules(language) ??
    DefaultLanguageRules(language);
