// SPDX-License-Identifier: GPL-3.0-or-later
//
// Images in the keyboard (2026-11-26): the toolbar's Images button. Until the offline image model ships
// this is a small "coming soon" panel over the key rows (Boo, a serif title, one line, a status pill);
// the same message as the app's Images page. "ABC" goes back to the keys.
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

import '../../app/onboarding/booboard_mascot.dart';
import '../../keyboard/panels/keyboard_panel.dart';
import 'images_debug_view.dart';

class ImagesPanel extends KeyboardPanel {
  /// [debugTools] shows the "Make test picture" button (debug builds only; phase 2 replaces it). Release builds
  /// show the coming-soon view exactly as before. Tests pass the flag instead of relying on [kDebugMode].
  ImagesPanel({bool? debugTools}) : debugTools = debugTools ?? kDebugMode;

  final bool debugTools;

  @override
  String get id => 'images';

  @override
  PanelPlacement get placement => PanelPlacement.keys;

  @override
  Widget build(BuildContext context, PanelContext panel) =>
      debugTools ? ImagesDebugView(panel: panel) : _ImagesSoonView(panel: panel);
}

class _ImagesSoonView extends StatelessWidget {
  const _ImagesSoonView({required this.panel});

  final PanelContext panel;

  @override
  Widget build(BuildContext context) {
    final theme = panel.theme;
    const serif = [FontVariation('wght', 400), FontVariation('SOFT', 100), FontVariation('opsz', 144)];
    final title = TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 28,
      height: 1,
      letterSpacing: -0.6,
      color: theme.letterKey.label,
      fontVariations: serif,
      decoration: TextDecoration.none,
    );
    final body = TextStyle(
      fontFamily: theme.fontFamily,
      fontSize: 14.5,
      height: 1.35,
      color: theme.letterKey.label.withValues(alpha: 0.75),
      decoration: TextDecoration.none,
    );
    final small = body.copyWith(fontSize: 13, color: theme.letterKey.label, fontWeight: FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.letterKey.fillTop ?? theme.letterKey.fill, theme.letterKey.fill],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.letterKey.border ?? theme.suggestionDivider),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              const BooBoardMascot(size: 76, backdrop: false, label: 'Boo'),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      label: 'Images are coming',
                      excludeSemantics: true,
                      child: Text.rich(
                        TextSpan(
                          text: 'Images are ',
                          style: title,
                          children: [
                            TextSpan(
                              text: 'coming',
                              style: title.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.trailStart,
                                fontVariations: const [...serif, FontVariation('WONK', 1)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Make pictures from your words, right on this phone, offline.', style: body),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.suggestionDivider,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8913A)),
                                ),
                                const SizedBox(width: 7),
                                Flexible(child: Text('Coming in a later update', style: small, maxLines: 1)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Semantics(
                          button: true,
                          label: 'Back to the keys',
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: panel.session.closePanel,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 56, minHeight: 40),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.actionKey.fill,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('ABC', style: small.copyWith(color: theme.actionKey.label)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
