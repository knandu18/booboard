// SPDX-License-Identifier: GPL-3.0-or-later
//
// The packs published with each GitHub release (the "Get packs" list in the foss build). BooBoard has no
// internet permission: "Download" hands the release link to the user's browser (AppHostApi.openPackDownload,
// which builds the URL itself), and the user imports the file afterwards. Keep this list in step with the
// files attached to the release (docs/release/RELEASING.md).
import '../bridge/messages.g.dart' show PackKind;

class CatalogPack {
  const CatalogPack({
    required this.id,
    required this.kind,
    required this.name,
    required this.fileName,
    required this.sizeBytes,
    this.translationPair,
    this.dictionaryLanguage,
  });

  /// The pack id inside the file (matches PackInfoMessage.id once installed).
  final String id;
  final PackKind kind;

  /// English display name (the settings app shows it next to localized text).
  final String name;

  /// The asset name in the GitHub release.
  final String fileName;
  final int sizeBytes;

  /// For translation packs: the 'en>es' pair key (translate_languages.dart pairKey).
  final String? translationPair;

  /// For dictionary packs: the BooBoard language id it serves.
  final String? dictionaryLanguage;
}

const List<CatalogPack> kPackCatalog = [
  // Voice typing works in English only. The model needs about 700 MB of memory while dictating.
  CatalogPack(
    id: 'voice-parakeet-en',
    kind: PackKind.voice,
    name: 'Voice typing in English (Parakeet; needs about 700 MB of memory while you dictate)',
    fileName: 'voice-parakeet-en.boopack',
    sizeBytes: 661933244,
  ),
  CatalogPack(
    id: 'translate-en-es',
    kind: PackKind.translation,
    name: 'English → Spanish',
    fileName: 'translate-en-es.boopack',
    sizeBytes: 115635262,
    translationPair: 'en>es',
  ),
  CatalogPack(
    id: 'dict-zh-rime-ice',
    kind: PackKind.dictionary,
    name: 'Chinese (Simplified) dictionary',
    fileName: 'dict-zh-rime-ice.boopack',
    sizeBytes: 38052532,
    dictionaryLanguage: 'zh',
  ),
  CatalogPack(
    id: 'dict-ja-mozc',
    kind: PackKind.dictionary,
    name: 'Japanese dictionary (Mozc)',
    fileName: 'dict-ja-mozc.boopack',
    sizeBytes: 20267770,
    dictionaryLanguage: 'ja',
  ),
];

/// The published translation pack for [pairKey] ('en>es'), or null when none is published yet.
CatalogPack? catalogTranslation(String pairKey) {
  for (final p in kPackCatalog) {
    if (p.translationPair == pairKey) return p;
  }
  return null;
}
