// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-T. Plain words for model packs: error codes from the import, and the one-line
// description of an installed pack.
import '../../bridge/messages.g.dart';
import '../../engine/lang/registry.dart';
import '../../packs/pack_maintenance.dart';
import '../privacy/privacy_format.dart';

import 'package:booboard/src/app/l10n.dart';

/// The message for an import that failed with [code] (the codes of `AppHostApi.importPack`).
String importErrorText(String code, AppLocalizations l10n) => switch (code) {
  'bad_signature' => l10n.packErrorBadSignature,
  'bad_format' => l10n.packErrorBadFormat,
  'too_large' => l10n.packErrorTooLarge,
  'unsupported_version' => l10n.packErrorVersion,
  'no_space' => l10n.packErrorNoSpace,
  _ => l10n.packErrorGeneric,
};

/// A language name for a pack's language id ('pt' is the Portuguese that both Portuguese variants use).
String packLanguageName(String id, AppLocalizations l10n) =>
    id == 'pt' ? l10n.languagePortuguese : languageInfo(id).englishName;

/// The state of a pack the store delivers, in words.
String offerStatusText(PackOfferStatus status, AppLocalizations l10n) => switch (status) {
  PackOfferStatus.notRequested => l10n.packsStatusNotRequested,
  PackOfferStatus.waitingForNetwork => l10n.packsStatusWaiting,
  PackOfferStatus.downloading => l10n.packsStatusDownloading,
  PackOfferStatus.installing || PackOfferStatus.ready => l10n.packsStatusInstalling,
  PackOfferStatus.failed => l10n.packsStatusFailed,
};

/// "English → Spanish" for a translation pack, "English, Hindi" for a voice pack.
String packLanguages(PackInfoMessage pack, AppLocalizations l10n) {
  final names = pack.languages.map((id) => packLanguageName(id, l10n));
  return pack.kind == PackKind.translation && pack.languages.length == 2 ? names.join(' → ') : names.join(', ');
}

/// "English → Spanish · 110 MB · Apache-2.0".
String packDescription(PackInfoMessage pack, AppLocalizations l10n) =>
    l10n.packMeta(packLanguages(pack, l10n), formatBytes(pack.sizeBytes), pack.license);
