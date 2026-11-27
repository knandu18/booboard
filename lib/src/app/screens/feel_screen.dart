// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A. Feel: haptics, sounds, keyboard height per orientation, and the one-handed
// and floating modes. Writes `feedback`, `appearance` and `modes` (values only; the keyboard owns
// the behaviour).
import 'package:material_ui/material_ui.dart';

import '../../settings/booboard_settings.dart';
import '../common/settings_widgets.dart';
import '../shell/settings_actions.dart';

import 'package:booboard/src/app/l10n.dart';

String _percent(double v) => '${(v * 100).round()}%';

class FeelScreen extends StatelessWidget {
  const FeelScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveSettings(
    builder: (context, settings) {
      final f = settings.feedback;
      final a = settings.appearance;
      final m = settings.modes;
      // -1 means "system default volume".
      final systemVolume = f.soundVolume < 0;

      return SettingsPage(
        title: context.l10n.settingsFeel,
        children: [
          SettingsGroup(
            title: context.l10n.feelHaptics,
            children: [
              SettingsSwitchTile(
                icon: Icons.vibration,
                title: context.l10n.feelHapticFeedback,
                subtitle: context.l10n.feelHapticFeedbackBody,
                value: f.haptics,
                onChanged: (v) => writeSettings(
                  context,
                  SettingsSection.feedback,
                  (s) => s.copyWith(feedback: s.feedback.copyWith(haptics: v)),
                ),
              ),
              SettingsSliderTile(
                icon: Icons.graphic_eq,
                title: context.l10n.feelHapticStrength,
                value: f.hapticStrength,
                min: 0,
                max: 1,
                divisions: 10,
                valueLabel: _percent,
                onChanged: (v) => writeSettings(
                  context,
                  SettingsSection.feedback,
                  (s) => s.copyWith(feedback: s.feedback.copyWith(hapticStrength: v)),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.feelSounds,
            children: [
              SettingsSwitchTile(
                icon: Icons.volume_up_outlined,
                title: context.l10n.feelKeySounds,
                subtitle: context.l10n.feelKeySoundsBody,
                value: f.sounds,
                onChanged: (v) => writeSettings(
                  context,
                  SettingsSection.feedback,
                  (s) => s.copyWith(feedback: s.feedback.copyWith(sounds: v)),
                ),
              ),
              SettingsSwitchTile(
                icon: Icons.settings_suggest_outlined,
                title: context.l10n.feelUseSystemVolume,
                value: systemVolume,
                onChanged: f.sounds
                    ? (v) => writeSettings(
                        context,
                        SettingsSection.feedback,
                        (s) => s.copyWith(feedback: s.feedback.copyWith(soundVolume: v ? -1 : 0.5)),
                      )
                    : null,
              ),
              if (!systemVolume)
                SettingsSliderTile(
                  icon: Icons.equalizer,
                  title: context.l10n.feelKeySoundVolume,
                  value: f.soundVolume,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  valueLabel: _percent,
                  onChanged: (v) => writeSettings(
                    context,
                    SettingsSection.feedback,
                    (s) => s.copyWith(feedback: s.feedback.copyWith(soundVolume: v)),
                  ),
                ),
            ],
          ),
          SettingsGroup(
            title: context.l10n.feelHeight,
            children: [
              SettingsSliderTile(
                icon: Icons.stay_current_portrait,
                title: context.l10n.feelPortraitHeight,
                value: a.heightScale,
                min: 0.7,
                max: 1.5,
                divisions: 16,
                valueLabel: _percent,
                onChanged: (v) => writeSettings(
                  context,
                  SettingsSection.appearance,
                  (s) => s.copyWith(appearance: s.appearance.copyWith(heightScale: v)),
                ),
              ),
              SettingsSliderTile(
                icon: Icons.stay_current_landscape,
                title: context.l10n.feelLandscapeHeight,
                value: a.landscapeHeightScale,
                min: 0.6,
                max: 1.5,
                divisions: 18,
                valueLabel: _percent,
                onChanged: (v) => writeSettings(
                  context,
                  SettingsSection.appearance,
                  (s) => s.copyWith(appearance: s.appearance.copyWith(landscapeHeightScale: v)),
                ),
              ),
            ],
          ),
          SettingsPanel(
            title: context.l10n.feelOneHandedFloating,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.l10n.feelOneHandedSide, style: Theme.of(context).textTheme.bodyLarge),
                SizedBox(height: 12),
                SegmentedButton<OneHandedMode>(
                  segments: [
                    ButtonSegment<OneHandedMode>(value: OneHandedMode.off, label: Text(context.l10n.off)),
                    ButtonSegment<OneHandedMode>(value: OneHandedMode.left, label: Text(context.l10n.left)),
                    ButtonSegment<OneHandedMode>(value: OneHandedMode.right, label: Text(context.l10n.right)),
                  ],
                  selected: {m.oneHanded},
                  onSelectionChanged: (sides) => writeSettings(
                    context,
                    SettingsSection.modes,
                    (s) => s.copyWith(modes: s.modes.copyWith(oneHanded: sides.first)),
                  ),
                ),
                const SizedBox(height: 8),
                SettingsSwitchTile(
                  icon: Icons.open_with,
                  title: context.l10n.feelFloatingKeyboard,
                  subtitle: context.l10n.feelFloatingBody,
                  value: m.floating,
                  onChanged: (v) => writeSettings(
                    context,
                    SettingsSection.modes,
                    (s) => s.copyWith(modes: s.modes.copyWith(floating: v)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
