// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-B. Encrypted backup: choose sections, set a passphrase, save a .boobackup file;
// or open one, check the counts, then merge or replace. Shown with FLAG_SECURE.
//
// PRIVACY: passphrases, contents and file names are never logged or shown outside this screen.
import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart' show PlatformException;
import 'package:material_ui/material_ui.dart';

import '../../security/app_auth.dart';
import '../../security/backup/backup_collect.dart';
import '../../security/backup/backup_payload.dart';
import '../../security/backup/backup_restore.dart';
import '../../security/backup/privacy_changes.dart';
import '../../settings/booboard_settings.dart';
import '../app_services.dart';
import '../common/settings_widgets.dart';
import 'privacy_deps.dart';
import 'privacy_format.dart';
import 'privacy_widgets.dart';

import 'package:booboard/src/app/l10n.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  AppServices? _services;
  PrivacyDeps? _deps;
  Future<BackupSummary?>? _summary;
  final Set<BackupSection> _include = {
    BackupSection.settings,
    BackupSection.learned,
    BackupSection.shortcuts,
    BackupSection.emoji,
    BackupSection.themes,
  };
  bool _themeImages = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SecureScreenGuard.instance.acquire();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    final services = _services = AppScope.of(context);
    _summary = _loadSummary(services);
  }

  @override
  void dispose() {
    SecureScreenGuard.instance.release();
    super.dispose();
  }

  /// Counts for the export checkboxes. Null when something is locked right now.
  Future<BackupSummary?> _loadSummary(AppServices services) async {
    try {
      final deps = _deps ??= await PrivacyDeps.load(services);
      final contents = await deps.collector.collect(include: BackupSection.values.toSet());
      return contents.summary();
    } on BackupLockedException {
      return null;
    } on Object {
      return null;
    }
  }

  void _setBusy(bool busy) {
    if (mounted) setState(() => _busy = busy);
  }

  void _message(String text) {
    if (mounted) showPrivacyMessage(context, text);
  }

  // ---- export -------------------------------------------------------------------

  Future<void> _export() async {
    final l10n = context.l10n;
    final services = _services!;
    final deps = _deps ??= await PrivacyDeps.load(services);
    _setBusy(true);
    try {
      final contents = await deps.collector.collect(include: _include, includeThemeImages: _themeImages);
      final info = await services.platform.getAppInfo();
      final plain = BackupPayload(
        createdAt: DateTime.now().toUtc(),
        appVersion: '${info.versionName}+${info.versionCode}',
        contents: contents,
      ).encode();

      if (!mounted) return;
      final passphrase = await _askPassphrase(create: true);
      if (passphrase == null) return;

      final sealed = await services.app.sealBackup(plain, passphrase);
      final uri = await services.app.createDocument(_fileName(), 'application/octet-stream');
      if (uri == null) return; // The user cancelled the save dialog.
      await services.app.writeDocument(uri, sealed);
      // SEC-08: the chosen file is replaced, so read it back. A write that failed half way must not be
      // reported as a saved backup.
      final check = await services.app.readDocument(uri, kMaxBackupBytes);
      if (!listEquals(check, sealed)) {
        _message(l10n.backupCheckFailed);
        return;
      }
      _message(l10n.backupSaved(formatBytes(sealed.length)));
    } on BackupLockedException {
      _message(l10n.backupUnlockRetrySaved);
    } on PlatformException {
      _message(l10n.backupSaveFailed);
    } finally {
      _setBusy(false);
    }
  }

  String _fileName() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    // Date and time, so the suggested name is a new file and an older backup is not replaced by default.
    return 'booboard-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}.boobackup';
  }

  // ---- import -------------------------------------------------------------------

  Future<void> _import() async {
    final l10n = context.l10n;
    final services = _services!;
    final deps = _deps ??= await PrivacyDeps.load(services);
    _setBusy(true);
    try {
      final uri = await services.app.openDocument(const ['application/octet-stream', 'application/x-boobackup']);
      if (uri == null) return;
      final bytes = await services.app.readDocument(uri, kMaxBackupBytes);
      if (!mounted) return;
      final passphrase = await _askPassphrase(create: false);
      if (passphrase == null) return;

      final plain = await services.app.openBackup(bytes, passphrase);
      if (plain == null) {
        _message(l10n.backupWrongPassphrase);
        return;
      }
      final BackupPayload payload;
      try {
        payload = BackupPayload.decode(plain);
      } on BackupFormatException {
        _message(l10n.backupInvalidFile);
        return;
      }
      if (!mounted) return;
      await _previewAndRestore(payload, deps);
    } on PlatformException catch (e) {
      _message(switch (e.code) {
        'too_large' => l10n.backupTooLarge,
        'unsupported_version' => l10n.backupNewerVersion,
        'busy' => l10n.backupBusy,
        _ => l10n.backupOpenFailed,
      });
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _previewAndRestore(BackupPayload payload, PrivacyDeps deps) async {
    final l10n = context.l10n;
    final contents = payload.contents;
    final present = contents.present.toList()..sort((a, b) => a.index.compareTo(b.index));
    if (present.isEmpty) {
      _message(l10n.backupEmpty);
      return;
    }
    final chosen = {...present};
    var mode = RestoreMode.merge;
    final summary = contents.summary();
    final result = await showDialog<({Set<BackupSection> include, RestoreMode mode})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(l10n.backupRestoreTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.backupMadeBy(_date(payload.createdAt), payload.appVersion)),
                const SizedBox(height: 12),
                for (final section in present)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: chosen.contains(section),
                    title: Text(section.label),
                    subtitle: Text(_countText(section, summary, restoring: true)),
                    onChanged: (v) => setDialog(() {
                      if (v ?? false) {
                        chosen.add(section);
                      } else {
                        chosen.remove(section);
                      }
                    }),
                  ),
                const Divider(),
                RadioGroup<RestoreMode>(
                  groupValue: mode,
                  onChanged: (v) => setDialog(() => mode = v ?? RestoreMode.merge),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<RestoreMode>(
                        contentPadding: EdgeInsets.zero,
                        value: RestoreMode.merge,
                        title: Text(l10n.backupMerge),
                        subtitle: Text(l10n.backupMergeBody),
                      ),
                      RadioListTile<RestoreMode>(
                        contentPadding: EdgeInsets.zero,
                        value: RestoreMode.replace,
                        title: Text(l10n.backupReplace),
                        subtitle: Text(l10n.backupReplaceBody),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: chosen.isEmpty ? null : () => Navigator.of(context).pop((include: {...chosen}, mode: mode)),
              child: Text(l10n.commonContinue),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (result.mode == RestoreMode.replace) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.backupReplaceTitle),
          content: Text(l10n.backupReplaceConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.backupReplace)),
          ],
        ),
      );
      if (sure != true) return;
    }
    if (!await _confirmPrivacyChanges(contents, result.include, deps)) return;
    try {
      final report = await deps.restorer.apply(contents, include: result.include, mode: result.mode);
      _message(_reportText(report));
      if (mounted) {
        setState(() {
          _summary = _loadSummary(_services!);
        });
      }
    } on RestoreLockedException {
      _message(l10n.backupUnlockRetryChanged);
    } on PlatformException {
      _message(l10n.backupRestoreFailed);
    }
  }

  /// D2 (SEC-17): a restore of the settings section also replaces the privacy settings. When that would change
  /// any of them, name each one and ask first. True to go ahead (also when nothing changes).
  Future<bool> _confirmPrivacyChanges(BackupContents contents, Set<BackupSection> include, PrivacyDeps deps) async {
    final incomingJson = contents.settings;
    if (!include.contains(BackupSection.settings) || incomingJson == null) return true;
    final List<PrivacyChange> changes;
    try {
      changes = privacyChanges(deps.settings.value.privacy, BooBoardSettings.fromJson(incomingJson).privacy);
    } on FormatException {
      return true; // apply() rejects a malformed settings section before it writes anything.
    }
    if (changes.isEmpty || !mounted) return true;
    final l10n = context.l10n;
    String name(PrivacySetting s) => switch (s) {
      PrivacySetting.learning => l10n.privacyLearnNewWords,
      PrivacySetting.incognito => l10n.privacyIncognito,
      PrivacySetting.incognitoApps => l10n.privacyAlwaysIncognitoApps,
      PrivacySetting.hideFromScreenshots => l10n.privacyHideScreenshots,
      PrivacySetting.appLock => l10n.privacyLockBooBoard,
    };
    String value(Object v) => switch (v) {
      true => l10n.backupStateOn,
      false => l10n.off,
      final int n => l10n.backupAppsCount(n),
      _ => '$v',
    };
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupPrivacyChangesTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.backupPrivacyChangesBody),
              const SizedBox(height: 12),
              for (final c in changes) Text(l10n.backupPrivacyChangeLine(name(c.setting), value(c.from), value(c.to))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.backupRestoreAndChange)),
        ],
      ),
    );
    return sure == true;
  }

  String _reportText(RestoreReport r) {
    final parts = <String>[
      if (r.learnedLanguages > 0) context.l10n.restoreLearnedFor(r.learnedLanguages),
      if (r.shortcutsAdded > 0) context.l10n.countShortcuts(r.shortcutsAdded),
      if (r.clipboardAdded > 0) context.l10n.countClipboardItems(r.clipboardAdded),
      if (r.themesAdded > 0) context.l10n.countThemeFiles(r.themesAdded),
      if (r.settingsApplied) context.l10n.backupSettingsApplied,
    ];
    final skipped = <String>[
      if (r.shortcutsSkipped > 0) context.l10n.backupAlreadyHere(r.shortcutsSkipped),
      if (r.themesSkipped > 0) context.l10n.backupThemesAlreadyHere(r.themesSkipped),
      if (r.clipboardSkipped) context.l10n.backupClipboardKept,
      if (r.emojiKept) context.l10n.backupEmojiKept,
    ];
    final added = parts.isEmpty ? context.l10n.restoreNothingNew : context.l10n.restoreSummary(parts.join(', '));
    return skipped.isEmpty ? added : context.l10n.restoreSummarySkipped(added, skipped.join(', '));
  }

  String _date(DateTime t) {
    final local = t.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  /// [restoring]: the restore dialog ticks every section the file holds, so the export-only note on
  /// the clipboard (off by default) does not apply there.
  String _countText(BackupSection section, BackupSummary? s, {bool restoring = false}) {
    if (s == null) return context.l10n.backupUnlockToSeeCount;
    return switch (section) {
      BackupSection.settings => context.l10n.backupSettingsSummary,
      BackupSection.learned => context.l10n.backupLearnedSummary(
        context.l10n.countWords(s.learnedWords),
        context.l10n.countLanguages(s.learnedLanguages),
      ),
      BackupSection.shortcuts => context.l10n.countShortcuts(s.shortcuts),
      BackupSection.clipboard =>
        restoring
            ? context.l10n.countPinnedItems(s.clipboardItems)
            : context.l10n.backupPinnedOff(context.l10n.countPinnedItems(s.clipboardItems)),
      BackupSection.emoji => s.emojiBytes == 0 ? context.l10n.backupNothingYet : formatBytes(s.emojiBytes),
      BackupSection.themes => context.l10n.privacyThemesSize(s.themes, formatBytes(s.themeBytes)),
    };
  }

  Future<String?> _askPassphrase({required bool create}) => showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _PassphraseDialog(create: create),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyBackupRestore)),
      body: FutureBuilder<BackupSummary?>(
        future: _summary,
        builder: (context, snapshot) {
          final summary = snapshot.data;
          final waiting = snapshot.connectionState != ConnectionState.done;
          return ScreenBody(
            children: [
              PrivacyStatusCard(icon: Icons.lock_outline, text: context.l10n.backupExplainer),
              const SizedBox(height: 20),
              if (waiting)
                const Center(
                  child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                ),
              SettingsGroup(
                title: context.l10n.backupMakeTitle,
                children: [
                  for (final section in BackupSection.values)
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(section.label),
                      subtitle: Text(_countText(section, summary)),
                      value: _include.contains(section),
                      onChanged: _busy
                          ? null
                          : (v) => setState(() {
                              if (v) {
                                _include.add(section);
                              } else {
                                _include.remove(section);
                              }
                            }),
                    ),
                  if (_include.contains(BackupSection.themes))
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(context.l10n.backupIncludeImages),
                      subtitle: Text(context.l10n.backupPhotosLarger),
                      value: _themeImages,
                      onChanged: _busy ? null : (v) => setState(() => _themeImages = v),
                    ),
                ],
              ),
              FilledButton.icon(
                onPressed: _busy || _include.isEmpty ? null : () => unawaited(_export()),
                icon: const Icon(Icons.save_alt),
                label: Text(context.l10n.backupCreateButton),
              ),
              const SizedBox(height: 28),
              SettingsGroup(
                title: context.l10n.backupRestoreSection,
                children: [
                  SettingsTile(
                    icon: Icons.restore,
                    title: context.l10n.backupRestoreFromFile,
                    subtitle: context.l10n.backupRestoreFromFileBody,
                    onTap: _busy ? null : () => unawaited(_import()),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Asks for a passphrase. With [create], it asks twice and shows a strength meter.
class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.create});

  final bool create;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _pass = TextEditingController();
  final _again = TextEditingController();

  @override
  void dispose() {
    _pass.dispose();
    _again.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (!widget.create) return _pass.text.isNotEmpty;
    return PassphraseRules.strength(_pass.text) != PassphraseStrength.tooShort && _pass.text == _again.text;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.create ? context.l10n.backupChoosePassphrase : context.l10n.backupEnterPassphrase),
      content: ListenableBuilder(
        listenable: Listenable.merge([_pass, _again]),
        builder: (context, _) {
          final strength = PassphraseRules.strength(_pass.text);
          final mismatch = widget.create && _again.text.isNotEmpty && _again.text != _pass.text;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.create) Text(context.l10n.backupWriteItDown),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  autofocus: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: context.l10n.backupPassphrase, border: OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                ),
                if (widget.create) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _again,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: context.l10n.backupTypeAgain,
                      border: const OutlineInputBorder(),
                      errorText: mismatch ? context.l10n.backupMismatch : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: context.l10n.backupStrength(strength.label(context.l10n)),
                    child: LinearProgressIndicator(value: strength.fraction, color: scheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(strength.label(context.l10n), style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.cancel)),
        ListenableBuilder(
          listenable: Listenable.merge([_pass, _again]),
          builder: (context, _) => FilledButton(
            onPressed: _canSave ? () => Navigator.of(context).pop(_pass.text) : null,
            child: Text(widget.create ? context.l10n.commonContinue : context.l10n.backupOpen),
          ),
        ),
      ],
    );
  }
}
