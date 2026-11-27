// SPDX-License-Identifier: GPL-3.0-or-later
//
// One card of the theme gallery: a real rendered mini keyboard in the theme, its name, and a
// selected mark. Custom themes add a menu. Cards are plain widgets, so they are cheap to rebuild.
import 'package:material_ui/material_ui.dart';

import '../../keyboard/preview/keyboard_preview.dart';
import '../../settings/booboard_settings.dart';
import '../../theme/keyboard_theme_data.dart';

import 'package:booboard/src/app/l10n.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    super.key,
    required this.theme,
    required this.settings,
    required this.name,
    required this.selected,
    required this.onTap,
    this.menu,
    this.demoPress = false,
  });

  final KeyboardThemeData theme;
  final BooBoardSettings settings;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  /// Optional menu for custom themes (edit, duplicate, rename, delete).
  final Widget? menu;

  /// The gallery's hero card presses a key now and then.
  final bool demoPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? context.l10n.themeSelectedLabel(name) : name,
      child: Material(
        color: selected ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  // Carousels narrow the cards near their edges: keep the preview at the full card width
                  // and let the card crop it, so the keys never look squashed.
                  child: OverflowBox(
                    minWidth: kThemeCardWidth,
                    maxWidth: kThemeCardWidth,
                    child: KeyboardPreview(theme: theme, settings: settings, height: 150, demoPress: demoPress),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                child: Row(
                  children: [
                    if (selected) ...[
                      Icon(Icons.check_circle, size: 18, color: scheme.onSecondaryContainer),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
                        ),
                      ),
                    ),
                    ?menu,
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

/// Width of a theme card in the gallery carousels ([CarouselView.itemExtent]).
const double kThemeCardWidth = 232;

/// The "Create theme" card at the end of My themes.
class CreateThemeCard extends StatelessWidget {
  const CreateThemeCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: context.l10n.themeCreate,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.add, color: scheme.onPrimaryContainer, size: 28),
                ),
                const SizedBox(height: 12),
                Text(context.l10n.themeCreate, style: text.titleSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
