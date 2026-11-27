// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: orchestrator (Wave 4 seam). The strip shown instead of suggestions while a TextComposer
// (Chinese, Japanese) has something to show: the reading, a scrolling row of candidates with the
// highlighted one marked, and a button that opens every candidate in a grid over the keys.
//
// PRIVACY: candidates are never logged.
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;

import '../../theme/keyboard_theme_data.dart';
import '../a11y/candidate_labels.dart';
import '../input/composer.dart';
import '../view/keyboard_metrics.dart';

class CandidateStrip extends StatelessWidget {
  const CandidateStrip({
    super.key,
    required this.theme,
    required this.state,
    required this.expanded,
    required this.onSelect,
    required this.onToggleGrid,
  });

  final KeyboardThemeData theme;
  final ComposerState state;

  /// The grid is open (the button then closes it).
  final bool expanded;
  final ValueChanged<int> onSelect;
  final VoidCallback onToggleGrid;

  /// Width of the grid button at the trailing edge.
  static const double gridButtonWidth = 44;

  TextStyle _style(Color color, {double size = 18, bool bold = false}) => TextStyle(
    color: color,
    fontSize: size * theme.labelScale,
    fontFamily: theme.fontFamily,
    fontWeight: bold ? FontWeight.w600 : theme.labelWeight,
    fontVariations: theme.labelFontVariations,
    decoration: TextDecoration.none,
  );

  @override
  Widget build(BuildContext context) {
    final showReading = state.reading.isNotEmpty && state.reading != state.preedit;
    return SizedBox(
      height: KeyboardMetrics.stripHeight,
      child: Row(
        children: [
          if (showReading)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
              child: Semantics(
                label: 'Reading ${state.reading}',
                excludeSemantics: true,
                child: Text(state.reading, maxLines: 1, style: _style(theme.letterKey.hint, size: 14)),
              ),
            ),
          if (state.loading)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
              child: Semantics(
                label: 'Loading the dictionary',
                liveRegion: true,
                child: Icon(Icons.hourglass_empty, size: 16, color: theme.toolbarIcon),
              ),
            ),
          Expanded(
            child: ListView.builder(
              key: const ValueKey('candidate-row'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: state.candidates.length,
              itemBuilder: (context, i) => _candidate(i),
            ),
          ),
          if (state.candidates.length > 1)
            SizedBox(
              width: gridButtonWidth,
              child: Semantics(
                button: true,
                label: expanded ? 'Close all candidates' : 'Show all candidates',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleGrid,
                  child: Center(
                    child: Icon(
                      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 24,
                      color: theme.toolbarIcon,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _candidate(int i) {
    final c = state.candidates[i];
    final highlighted = i == state.highlighted;
    return Semantics(
      button: true,
      label: candidateSemanticsLabel(c, index: i, total: state.candidates.length),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelect(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: highlighted ? theme.suggestionHighlightFill : const Color(0x00000000),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    c.text,
                    maxLines: 1,
                    style: _style(
                      highlighted ? theme.suggestionHighlightText : theme.suggestionText,
                      bold: highlighted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
