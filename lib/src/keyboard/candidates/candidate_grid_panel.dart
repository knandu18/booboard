// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: orchestrator (Wave 4 seam). Every composer candidate in a scrolling grid over the keys
// (the strip stays). A tap commits through InputController.selectCandidate; the grid closes after
// a pick, and by itself when the composer has nothing left to show.
import 'package:flutter/widgets.dart';

import '../a11y/candidate_labels.dart';
import '../input/composer.dart';
import '../panels/keyboard_panel.dart';

class CandidateGridPanel extends KeyboardPanel {
  static const String panelId = 'candidates';

  @override
  String get id => panelId;

  @override
  PanelPlacement get placement => PanelPlacement.keys;

  @override
  Widget build(BuildContext context, PanelContext panel) => _CandidateGrid(panel: panel);
}

class _CandidateGrid extends StatefulWidget {
  const _CandidateGrid({required this.panel});

  final PanelContext panel;

  @override
  State<_CandidateGrid> createState() => _CandidateGridState();
}

class _CandidateGridState extends State<_CandidateGrid> {
  ValueNotifier<ComposerState> get _state => widget.panel.input.composerState;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onState);
  }

  @override
  void dispose() {
    _state.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (_state.value.candidates.isEmpty) widget.panel.close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.panel.theme;
    return ColoredBox(
      color: theme.background,
      child: ValueListenableBuilder<ComposerState>(
        valueListenable: _state,
        builder: (context, state, _) => GridView.builder(
          padding: const EdgeInsets.all(6),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 96,
            mainAxisExtent: 52,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: state.candidates.length,
          itemBuilder: (context, i) {
            final c = state.candidates[i];
            final highlighted = i == state.highlighted;
            return Semantics(
              button: true,
              label: candidateSemanticsLabel(c, index: i, total: state.candidates.length),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.panel.input.selectCandidate(i);
                  widget.panel.close();
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: highlighted ? theme.suggestionHighlightFill : theme.letterKey.fill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: highlighted ? theme.suggestionHighlightText : theme.letterKey.label,
                          fontSize: 20 * theme.labelScale,
                          fontFamily: theme.fontFamily,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (c.annotation != null)
                        Text(
                          c.annotation!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.letterKey.hint,
                            fontSize: 11 * theme.labelScale,
                            fontFamily: theme.fontFamily,
                            decoration: TextDecoration.none,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
