// SPDX-License-Identifier: GPL-3.0-or-later
//
// The "Keyboard modes" bar: a strip panel with one-handed left and right, floating, resize and close.
// The keys stay usable under it (no key redirect). Each button shows its selected state.
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../settings/booboard_settings.dart';
import '../../theme/keyboard_theme_data.dart';
import '../panels/keyboard_panel.dart';

enum ModesBarAction { oneHandedLeft, oneHandedRight, floating, resize, close }

class ModesBarPanel extends KeyboardPanel {
  ModesBarPanel(this.onAction);

  final void Function(ModesBarAction action) onAction;

  @override
  String get id => 'modes';

  @override
  PanelPlacement get placement => PanelPlacement.strip;

  @override
  Widget build(BuildContext context, PanelContext panel) =>
      ModesBar(modes: panel.settings.modes, theme: panel.theme, onAction: onAction);
}

class ModesBar extends StatelessWidget {
  const ModesBar({super.key, required this.modes, required this.theme, required this.onAction});

  final ModeSettings modes;
  final KeyboardThemeData theme;
  final void Function(ModesBarAction action) onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ModeButton(
        icon: Icons.align_horizontal_left,
        label: 'One-handed, left',
        selected: modes.oneHanded == OneHandedMode.left,
        theme: theme,
        onTap: () => onAction(ModesBarAction.oneHandedLeft),
      ),
      _ModeButton(
        icon: Icons.align_horizontal_right,
        label: 'One-handed, right',
        selected: modes.oneHanded == OneHandedMode.right,
        theme: theme,
        onTap: () => onAction(ModesBarAction.oneHandedRight),
      ),
      _ModeButton(
        icon: Icons.picture_in_picture_alt,
        label: 'Floating keyboard',
        selected: modes.floating,
        theme: theme,
        onTap: () => onAction(ModesBarAction.floating),
      ),
      _ModeButton(
        icon: Icons.height,
        label: 'Resize keyboard height',
        selected: false,
        theme: theme,
        onTap: () => onAction(ModesBarAction.resize),
      ),
      _ModeButton(
        icon: Icons.close,
        label: 'Close keyboard modes',
        selected: false,
        theme: theme,
        onTap: () => onAction(ModesBarAction.close),
      ),
    ],
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final KeyboardThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Container(
            width: 48,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? theme.suggestionHighlightFill : const Color(0x00000000),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 22, color: selected ? theme.suggestionHighlightText : theme.toolbarIcon),
          ),
        ),
      ),
    ),
  );
}
