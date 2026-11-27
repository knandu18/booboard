// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-T, extended in Wave 5-C. Model packs (voice, translation, dictionaries): what is installed
// with sizes and licences, import of .boopack files (the system file picker), delete with a confirmation,
// a verify action that re-checks installed files, and free space. In the play flavour, the store delivers
// some packs ("Get"); in the foss flavour the screen explains how to get packs by hand. A pack is checked
// before it is installed, and it only ever holds data. Voice uses this screen too.
import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, ClipboardData, PlatformException;
import 'package:material_ui/material_ui.dart';

import '../../bridge/messages.g.dart';
import '../../core/data_sections.dart';
import '../../packs/pack_catalog.dart';
import '../../packs/pack_maintenance.dart';
import '../app_services.dart';
import '../common/settings_widgets.dart';
import '../privacy/privacy_format.dart';
import 'pack_text.dart';

import 'package:booboard/src/app/l10n.dart';

class PacksScreen extends StatefulWidget {
  const PacksScreen({super.key, this.maintenance});

  /// Store delivery, free space and verification. Null (the app) uses the platform through Pigeon; tests
  /// pass their own. When the platform cannot be reached the screen falls back to import-only, with those
  /// features reported as not available in this build.
  final PackMaintenance? maintenance;

  @override
  State<PacksScreen> createState() => _PacksScreenState();
}

/// Everything the page shows, read in one go so one failure shows one error state.
class _PackPage {
  const _PackPage(this.packs, this.offers, this.storage);

  final List<PackInfoMessage> packs;
  final List<PackOffer> offers;
  final PackStorage? storage;
}

class _PacksScreenState extends State<PacksScreen> {
  AppServices? _services;
  Future<_PackPage>? _page;
  PackMaintenance _maintenance = const UnavailablePackMaintenance();
  bool _busy = false;
  Timer? _poll;
  int _extraPolls = 0;
  final _failedInstalls = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = AppScope.of(context);
    _reload();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _page = _readPage();
    });
  }

  /// Store deliveries (play): while Play is working the page re-reads every two seconds, and a pack Play has
  /// finished is verified and installed by the keyboard itself. Only the real bridge does this: a screen given
  /// its own [PackMaintenance] (tests) stays still.
  void _followDeliveries(_PackPage page) {
    _poll?.cancel();
    if (widget.maintenance != null || !mounted) return;
    final installed = {for (final p in page.packs) p.id};
    final waiting = [
      for (final o in page.offers)
        if (!installed.contains(o.id) && !_failedInstalls.contains(o.id)) o,
    ];
    final ready = waiting.where((o) => o.status == PackOfferStatus.ready).toList();
    final settling = _extraPolls > 0 && waiting.isNotEmpty;
    if (settling) _extraPolls--;
    if (ready.isNotEmpty) {
      unawaited(_installDelivered(ready.first));
    } else if (settling ||
        waiting.any(
          (o) =>
              o.status == PackOfferStatus.downloading ||
              o.status == PackOfferStatus.installing ||
              o.status == PackOfferStatus.waitingForNetwork,
        )) {
      _poll = Timer(const Duration(seconds: 2), () {
        if (mounted) _reload();
      });
    }
  }

  Future<void> _installDelivered(PackOffer offer) async {
    final l10n = context.l10n;
    final services = _services!;
    setState(() => _busy = true);
    try {
      final name = await _maintenance.installDelivered(offer.id);
      await services.notifyDataChanged(const [DataSections.packs]);
      _show(l10n.packsInstalled(name));
    } on PlatformException catch (e) {
      _failedInstalls.add(offer.id);
      _show(importErrorText(e.code, l10n));
    } on Object {
      _failedInstalls.add(offer.id);
      _show(l10n.packsStatusFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
      _reload();
    }
  }

  /// Async, so a failure (or a missing answer) shows as an error state instead of throwing while building.
  /// Store and storage details are optional: when they fail, the page still shows the installed packs.
  Future<_PackPage> _readPage() async {
    final packs = await _services!.platform.listPacks();
    _maintenance =
        widget.maintenance ?? await _optional(() => BridgePackMaintenance.load(_services!.app), _maintenance);
    final offers = await _optional(_maintenance.offers, const <PackOffer>[]);
    final storage = await _optional(_maintenance.storage, null);
    final page = _PackPage(packs, offers, storage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _followDeliveries(page));
    return page;
  }

  static Future<T> _optional<T>(Future<T> Function() read, T fallback) async {
    try {
      return await read();
    } on Object {
      return fallback;
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _import() async {
    final l10n = context.l10n;
    final services = _services!;
    String? uri;
    try {
      uri = await services.app.openDocument(const ['application/octet-stream', 'application/x-boopack']);
    } on PlatformException {
      _show(l10n.packsOpenFailed);
      return;
    }
    if (uri == null) return; // The user cancelled.
    setState(() => _busy = true);
    try {
      final pack = await services.app.importPack(uri);
      await services.notifyDataChanged(const [DataSections.packs]);
      _show(l10n.packsInstalled(pack.name));
    } on PlatformException catch (e) {
      _show(importErrorText(e.code, l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
      _reload();
    }
  }

  /// Hands the pack's release link to the browser. BooBoard itself never connects.
  Future<void> _download(CatalogPack pack) async {
    final l10n = context.l10n;
    try {
      await _services!.app.openPackDownload(pack.fileName);
      _show(l10n.packsDownloadStarted(pack.name));
    } on PlatformException {
      _show(l10n.packsNoBrowser);
    }
  }

  Future<void> _copyLink() async {
    final l10n = context.l10n;
    await Clipboard.setData(const ClipboardData(text: kPackReleasePageUrl));
    _show(l10n.packsLinkCopied);
  }

  Future<void> _request(PackOffer offer) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await _maintenance.request(offer.id);
      _extraPolls = 6; // Play reports the new state a moment later: keep looking for a few seconds.
    } on Object {
      _show(l10n.packsStatusFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
      _reload();
    }
  }

  Future<void> _verify() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final checks = await _maintenance.verifyInstalled();
      final damaged = checks.where((c) => !c.ok).length;
      _show(damaged == 0 ? l10n.packsVerifyOk('${checks.length}') : l10n.packsVerifyDamaged('$damaged'));
    } on PackMaintenanceUnavailable {
      _show(l10n.packsVerifyUnavailable);
    } on Object {
      _show(l10n.packsVerifyFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(PackInfoMessage pack) async {
    final l10n = context.l10n;
    final services = _services!;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.packsDeleteTitle(pack.name)),
        content: Text(l10n.packsDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await services.app.deletePack(pack.id);
      await services.notifyDataChanged(const [DataSections.packs]);
      _show(l10n.packsDeleted(pack.name));
    } on PlatformException {
      _show(l10n.packsDeleteFailed(pack.name));
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PackPage>(
      future: _page,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SettingsPage(
            title: context.l10n.settingsModelPacks,
            children: [
              SettingsGroup(
                children: [SettingsTile(icon: Icons.error_outline, title: context.l10n.packsCouldNotRead)],
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final page = snapshot.requireData;
        final packs = page.packs;
        final voice = packs.where((p) => p.kind == PackKind.voice).toList();
        final translation = packs.where((p) => p.kind == PackKind.translation).toList();
        final dictionaries = packs.where((p) => p.kind == PackKind.dictionary).toList();
        final images = packs.where((p) => p.kind == PackKind.image).toList();
        final total = packs.fold<int>(0, (sum, p) => sum + p.sizeBytes);
        final installedIds = {for (final p in packs) p.id};
        final toGet = [
          for (final o in page.offers)
            if (!installedIds.contains(o.id)) o,
        ];
        final importOnly = _maintenance.delivery == PackDelivery.importOnly;
        final downloadable = [
          for (final p in kPackCatalog)
            if (!installedIds.contains(p.id)) p,
        ];
        final l10n = context.l10n;
        final free = page.storage?.freeBytes;
        return SettingsPage(
          title: l10n.settingsModelPacks,
          header: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Text(l10n.packsIntro)),
          children: [
            if (importOnly)
              SettingsGroup(
                title: l10n.packsGetTitle,
                children: [
                  SettingsTile(
                    icon: Icons.lock_outline,
                    title: l10n.packsPrivateTitle,
                    subtitle: l10n.packsPrivateBody,
                  ),
                  if (downloadable.isEmpty)
                    SettingsTile(icon: Icons.check_circle_outline, title: l10n.packsAllInstalled)
                  else
                    for (final p in downloadable)
                      SettingsTile(
                        icon: switch (p.kind) {
                          PackKind.voice => Icons.mic_none,
                          PackKind.translation => Icons.translate,
                          PackKind.dictionary => Icons.menu_book_outlined,
                          PackKind.image => Icons.image_outlined,
                        },
                        title: p.name,
                        subtitle: l10n.packsDownloadMeta(formatBytes(p.sizeBytes)),
                        trailing: TextButton(
                          onPressed: _busy ? null : () => unawaited(_download(p)),
                          child: Text(l10n.packsDownload),
                        ),
                      ),
                  SettingsTile(
                    icon: Icons.link,
                    title: l10n.packsCopyLink,
                    subtitle: kPackReleasePageUrl,
                    enabled: !_busy,
                    onTap: _busy ? null : () => unawaited(_copyLink()),
                  ),
                ],
              ),
            if (!importOnly && toGet.isNotEmpty)
              SettingsGroup(
                title: l10n.packsPlayTitle,
                children: [
                  SettingsTile(icon: Icons.shop_outlined, title: l10n.packsPlayNote),
                  for (final offer in toGet)
                    SettingsTile(
                      icon: Icons.download_outlined,
                      title: offer.name,
                      subtitle: l10n.packsOfferMeta(formatBytes(offer.sizeBytes), offerStatusText(offer.status, l10n)),
                      trailing: TextButton(
                        onPressed:
                            _busy ||
                                offer.status == PackOfferStatus.downloading ||
                                offer.status == PackOfferStatus.installing
                            ? null
                            : () => unawaited(_request(offer)),
                        child: Text(l10n.packsGet),
                      ),
                    ),
                ],
              ),
            SettingsGroup(
              title: l10n.packsImport,
              children: [
                SettingsTile(
                  icon: Icons.file_open_outlined,
                  title: l10n.packsImportTitle,
                  subtitle: _busy ? l10n.packsChecking : l10n.packsImportCheckedBody,
                  enabled: !_busy,
                  onTap: _busy ? null : () => unawaited(_import()),
                ),
                if (_busy) const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: LinearProgressIndicator()),
              ],
            ),
            SettingsGroup(
              title: l10n.settingsVoice,
              children: voice.isEmpty
                  ? [SettingsTile(icon: Icons.mic_none, title: l10n.packsNoVoice, subtitle: l10n.packsNoVoiceBody)]
                  : [for (final p in voice) _PackTile(pack: p, onDelete: () => _delete(p))],
            ),
            SettingsGroup(
              title: l10n.settingsTranslation,
              children: translation.isEmpty
                  ? [
                      SettingsTile(
                        icon: Icons.translate,
                        title: l10n.packsNoTranslation,
                        subtitle: l10n.packsNoTranslationBody,
                      ),
                    ]
                  : [for (final p in translation) _PackTile(pack: p, onDelete: () => _delete(p))],
            ),
            SettingsGroup(
              title: l10n.packsDictionaries,
              children: dictionaries.isEmpty
                  ? [
                      SettingsTile(
                        icon: Icons.menu_book_outlined,
                        title: l10n.packsNoDictionary,
                        subtitle: l10n.packsNoDictionaryBody,
                      ),
                    ]
                  : [for (final p in dictionaries) _PackTile(pack: p, onDelete: () => _delete(p))],
            ),
            // Only once an image pack is installed: until Images ships, the page looks as before.
            if (images.isNotEmpty)
              SettingsGroup(
                title: l10n.homeImages,
                children: [for (final p in images) _PackTile(pack: p, onDelete: () => _delete(p))],
              ),
            SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.verified_outlined,
                  title: l10n.packsVerifyTitle,
                  subtitle: l10n.packsVerifyBody,
                  enabled: !_busy && packs.isNotEmpty,
                  onTap: _busy || packs.isEmpty ? null : () => unawaited(_verify()),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                [
                  packs.isEmpty ? l10n.packsNothingStored : l10n.packsInstalledUse(formatBytes(total)),
                  if (free != null) l10n.packsFreeSpace(formatBytes(free)),
                ].join('\n'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack, required this.onDelete});

  final PackInfoMessage pack;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(switch (pack.kind) {
      PackKind.voice => Icons.mic_none,
      PackKind.translation => Icons.translate,
      PackKind.dictionary => Icons.menu_book_outlined,
      PackKind.image => Icons.image_outlined,
    }),
    title: Text(pack.name),
    subtitle: Text(packDescription(pack, context.l10n)),
    contentPadding: const EdgeInsets.only(left: 16, right: 8),
    minTileHeight: 56,
    trailing: IconButton(
      tooltip: context.l10n.packsDeleteTooltip(pack.name),
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline),
    ),
  );
}
