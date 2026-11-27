// SPDX-License-Identifier: GPL-3.0-or-later
//
// The tools menu (2026-11-26): long-pressing the Settings gear in the toolbar shows a small card with the
// tools that left the toolbar (text editing, one-handed and floating) and BooBoard settings. It covers the
// key rows; tapping outside the card closes it.
import 'package:flutter/widgets.dart';

import '../view/keyboard_hooks.dart' show ToolMenuItem;
import 'keyboard_panel.dart';

class ToolsMenuPanel extends KeyboardPanel {
  ToolsMenuPanel(this.items);

  final List<ToolMenuItem> items;

  @override
  String get id => 'tools_menu';

  @override
  PanelPlacement get placement => PanelPlacement.keys;

  @override
  Widget build(BuildContext context, PanelContext panel) => _ToolsMenuView(items: items, panel: panel);
}

class _ToolsMenuView extends StatelessWidget {
  const _ToolsMenuView({required this.items, required this.panel});

  final List<ToolMenuItem> items;
  final PanelContext panel;

  @override
  Widget build(BuildContext context) {
    final theme = panel.theme;
    final label = TextStyle(
      fontFamily: theme.fontFamily,
      fontSize: 16,
      color: theme.popupLabel,
      fontWeight: theme.labelWeight,
      decoration: TextDecoration.none,
    );
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: panel.session.closePanel,
        child: Align(
          alignment: AlignmentDirectional.topEnd,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Container(
              width: 290,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.popupFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.suggestionDivider),
                boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in items)
                    Semantics(
                      button: true,
                      label: item.label,
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          panel.session.closePanel();
                          item.onTap();
                        },
                        child: SizedBox(
                          height: 52,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(item.icon, size: 20, color: theme.trailStart),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(item.label, style: label, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
