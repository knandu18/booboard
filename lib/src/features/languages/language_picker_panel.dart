// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 3-A. The language picker that opens on a long press of the space bar: the enabled
// languages (tap to switch), the language settings, the system keyboard picker and, for a
// transliterating layout, the Hinglish switch. It replaces the keys and keeps the strip.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../engine/contracts.dart' show LanguageId;
import '../../engine/lang/registry.dart';
import '../../keyboard/keyboard_session.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import '../../settings/booboard_settings.dart';
import '../shared/panel_style.dart';

/// The space-bar language picker (opened with [KeyboardSession.openPanel]).
class LanguagePickerPanel extends KeyboardPanel {
  LanguagePickerPanel({required this.session});

  final KeyboardSession session;

  @override
  String get id => 'languages';

  @override
  PanelPlacement get placement => PanelPlacement.keys;

  @override
  Widget build(BuildContext context, PanelContext panel) => LanguagePickerView(session: session, panel: panel);
}

class LanguagePickerView extends StatelessWidget {
  const LanguagePickerView({super.key, required this.session, required this.panel});

  final KeyboardSession session;
  final PanelContext panel;

  void _switchTo(LanguageId id) {
    unawaited(session.switchLanguage(id));
    panel.close();
  }

  void _openLanguageSettings() {
    unawaited(session.services.host.openSettings('languages'));
    panel.close();
  }

  void _openSystemPicker() {
    unawaited(session.services.host.showInputMethodPicker());
    panel.close();
  }

  void _setHinglish(bool value) {
    unawaited(
      session.services.settings.update(
        (s) => s.copyWith(languages: s.languages.copyWith(hinglishOutput: value)),
        sections: [SettingsSection.languages],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = panel.theme;
    final style = PanelStyle(theme);
    final settings = session.services.settings.value;
    final languages = settings.languages;
    final active = languages.active;
    final activeLayout = session.activeLayout;
    final rowHeight = 52.0;

    Widget row({
      required String label,
      required String semantics,
      required Widget trailing,
      required VoidCallback onTap,
      required bool selected,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: PanelButton(
        semanticsLabel: semantics,
        height: rowHeight,
        radius: style.radius(rowHeight),
        fill: selected ? theme.actionKey.fill : theme.functionKey.fill,
        pressedFill: theme.suggestionHighlightFill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.text(
                    size: 15,
                    color: selected ? theme.actionKey.label : theme.functionKey.label,
                    weight: selected ? FontWeight.w600 : null,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );

    final children = <Widget>[
      for (final id in languages.enabled)
        () {
          final info = languageInfo(id);
          final layout = layoutChoiceFor(languages, id);
          final selected = id == active;
          return row(
            label: '${info.nativeName}  ·  ${layout.name}',
            semantics: '${info.englishName}, ${layout.name}${selected ? ', selected' : ''}',
            selected: selected,
            onTap: () => _switchTo(id),
            trailing: selected
                ? Icon(Icons.check, size: 20, color: theme.actionKey.label)
                : const SizedBox(width: 20, height: 20),
          );
        }(),
      if (activeLayout.transliterates)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 14, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Type in Hinglish (English letters)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style.text(size: 14, color: theme.suggestionText),
                ),
              ),
              PanelSwitch(
                value: languages.hinglishOutput,
                onChanged: _setHinglish,
                label: 'Type in Hinglish (English letters)',
                theme: theme,
              ),
            ],
          ),
        ),
      row(
        label: 'Language settings',
        semantics: 'Language settings',
        selected: false,
        onTap: _openLanguageSettings,
        trailing: Icon(Icons.chevron_right, size: 20, color: theme.toolbarIcon),
      ),
      row(
        label: 'Switch keyboard',
        semantics: 'Switch keyboard',
        selected: false,
        onTap: _openSystemPicker,
        trailing: Icon(Icons.keyboard_alt_outlined, size: 20, color: theme.toolbarIcon),
      ),
    ];

    return SizedBox(
      width: panel.size.width,
      height: panel.size.height,
      child: ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: children),
    );
  }
}
