// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-T. Which BooBoard languages translate, and which packs a pair needs.
// Every pack is English with one language, one direction each. A pair between two other languages goes
// through English (2026-11-26, user decision): Spanish → French uses the Spanish → English and the
// English → French packs, one after the other.
import '../../bridge/messages.g.dart';
import '../../engine/lang/registry.dart';
import '../../packs/pack_catalog.dart';

/// Every keyboard language, in the keyboard's order. The From/To lists show all of them and mark the ones
/// without a pack.
List<String> get translateLanguages => [for (final l in allLanguages) l.id];

/// Pack languages whose models are chosen and pinned (`tool/packs/translate/models.json`), both directions.
/// A language here without a published pack is "coming soon"; any other language has "no pack yet".
const Set<String> plannedPackLanguages = {'es', 'fr', 'de', 'pt', 'hi', 'ru'};

/// The pack language for a BooBoard language id ('pt-BR' and 'pt-PT' are 'pt').
String packLanguage(String id) => (id == 'pt-BR' || id == 'pt-PT') ? 'pt' : id;

/// True when [id] is English or has packs planned.
bool hasPlannedPacks(String id) => id == 'en' || plannedPackLanguages.contains(packLanguage(id));

/// True when a pair can translate once its packs are installed: two different languages, each English or
/// with packs planned. Pairs without English go through English.
bool isSupportedPair(String from, String to) =>
    packLanguage(from) != packLanguage(to) && hasPlannedPacks(from) && hasPlannedPacks(to);

/// True when the pair goes through English (neither side is English).
bool goesThroughEnglish(String from, String to) => from != 'en' && to != 'en';

/// Pair key of one pack, as `from>to` with pack language ids.
String pairKey(String from, String to) => '${packLanguage(from)}>${packLanguage(to)}';

/// The pack keys a pair needs, in order: one, or two through English.
List<String> packsForPair(String from, String to) =>
    goesThroughEnglish(from, to) ? [pairKey(from, 'en'), pairKey('en', to)] : [pairKey(from, to)];

/// The pack keys of the installed translation packs.
Set<String> installedPairKeys(Iterable<PackInfoMessage> packs) => {
  for (final p in packs)
    if (p.kind == PackKind.translation && p.languages.length == 2) pairKey(p.languages[0], p.languages[1]),
};

/// Where a pair stands, for the lists and the bar's notice.
enum PairStatus {
  /// Every pack it needs is installed.
  installed,

  /// Some pack is missing, and every missing one is published (Get leads somewhere).
  published,

  /// Packs are planned but not all published yet.
  comingSoon,

  /// A language has no pack at all (or the two sides are the same language).
  noPack,
}

/// The status of [from] → [to] given the installed pack keys.
PairStatus pairStatus(String from, String to, Set<String> installed) {
  if (!isSupportedPair(from, to)) return PairStatus.noPack;
  final missing = packsForPair(from, to).where((k) => !installed.contains(k)).toList();
  if (missing.isEmpty) return PairStatus.installed;
  if (missing.every((k) => catalogTranslation(k) != null)) return PairStatus.published;
  return PairStatus.comingSoon;
}

/// Translates [text] with [call], going through English when neither side is English. The English middle
/// step stays in memory only, like the source and the result.
Future<String> translateMaybeThroughEnglish(
  Future<String> Function(String text, String from, String to) call,
  String text,
  String from,
  String to,
) async {
  if (!goesThroughEnglish(from, to)) return call(text, from, to);
  final english = await call(text, from, 'en');
  if (english.trim().isEmpty) return english;
  return call(english, 'en', to);
}

/// Short code for pair labels ('EN', 'PT-BR').
String shortCode(String id) => id.toUpperCase();
