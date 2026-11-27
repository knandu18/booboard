// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-D. Voice settings: voice typing on or off (English only), the voice pack (Automatic or one of
// the installed voice packs), a link to the model packs, and the privacy line.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../bridge/messages.g.dart';
import '../../settings/booboard_settings.dart';
import '../common/settings_widgets.dart';
import '../app_services.dart';
import '../routes.dart';
import '../shell/settings_actions.dart';

import 'package:booboard/src/app/l10n.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveSettings(
    builder: (context, settings) {
      final v = settings.voice;
      return SettingsPage(
        title: context.l10n.settingsVoice,
        children: [
          SettingsGroup(
            children: [
              SettingsSwitchTile(
                icon: Icons.mic_none_outlined,
                title: context.l10n.voiceTyping,
                subtitle: context.l10n.voiceTypingBody,
                value: v.enabled,
                onChanged: (on) => writeSettings(
                  context,
                  SettingsSection.voice,
                  (s) => s.copyWith(voice: s.voice.copyWith(enabled: on)),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.voiceRecognition,
            children: [
              _VoicePackTile(selectedId: v.modelId),
              SettingsTile(
                icon: Icons.inventory_2_outlined,
                title: context.l10n.settingsModelPacks,
                subtitle: context.l10n.voiceModelPacksBody,
                onTap: () => unawaited(Navigator.of(context).pushNamed(BooBoardRoutes.packs)),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Text(context.l10n.voiceAudioStays, textAlign: TextAlign.center),
          ),
        ],
      );
    },
  );
}

/// The voice pack to use: Automatic (the first installed English voice pack) or one pack.
class _VoicePackTile extends StatefulWidget {
  const _VoicePackTile({required this.selectedId});

  final String selectedId;

  @override
  State<_VoicePackTile> createState() => _VoicePackTileState();
}

class _VoicePackTileState extends State<_VoicePackTile> {
  Future<List<PackInfoMessage>>? _packs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _packs ??= _loadVoicePacks(AppScope.of(context));
  }

  /// The installed voice packs. A failed read shows no packs rather than an error.
  static Future<List<PackInfoMessage>> _loadVoicePacks(AppServices services) async {
    try {
      final all = await services.platform.listPacks();
      return all.where((p) => p.kind == PackKind.voice).toList();
    } on Object {
      return <PackInfoMessage>[];
    }
  }

  String _label(List<PackInfoMessage> packs) {
    if (widget.selectedId.isEmpty) return context.l10n.voicePackAutomatic;
    for (final p in packs) {
      if (p.id == widget.selectedId) return p.name;
    }
    return widget.selectedId;
  }

  Future<void> _choose() async {
    // Read the list again: a pack may have been imported or deleted under Model packs since this screen opened.
    final fresh = _loadVoicePacks(AppScope.of(context));
    setState(() {
      _packs = fresh;
    });
    final packs = await fresh;
    if (!mounted) return;
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.voicePack),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(
              widget.selectedId.isEmpty ? context.l10n.voicePackAutomaticSelected : context.l10n.voicePackAutomatic,
            ),
          ),
          for (final p in packs)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(p.id),
              child: Text(
                p.id == widget.selectedId
                    ? context.l10n.voicePackItemSelected(p.name, _mb(p.sizeBytes))
                    : context.l10n.voicePackItem(p.name, _mb(p.sizeBytes)),
              ),
            ),
          if (packs.isEmpty)
            Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 16), child: Text(context.l10n.voiceNoPack)),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    writeSettings(context, SettingsSection.voice, (s) => s.copyWith(voice: s.voice.copyWith(modelId: chosen)));
  }

  static String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PackInfoMessage>>(
    future: _packs,
    builder: (context, snap) {
      final packs = snap.data ?? const <PackInfoMessage>[];
      final loading = snap.connectionState != ConnectionState.done;
      return SettingsTile(
        icon: Icons.settings_voice_outlined,
        title: context.l10n.voicePack,
        subtitle: loading ? context.l10n.voiceLooking : null,
        trailing: Text(loading ? '' : _label(packs)),
        onTap: loading ? null : () => unawaited(_choose()),
      );
    },
  );
}
