// SPDX-License-Identifier: GPL-3.0-or-later
//
// Shared building blocks for every settings screen (Wave 2-A, B and C).
// OWNER: Wave 2-A, who may restyle them but must keep these constructors and
// parameters working, because every settings screen builds on them.
// Lime look (2026-11-26, matching Home): a lime header with a back button and the page title in
// Fraunces, then rounded cards on warm paper (dark in dark mode), each row with a lime icon circle.
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:booboard/src/app/l10n.dart';

import '../onboarding/booboard_mascot.dart';
import '../onboarding/onboarding_style.dart';
import '../shell/booboard_theme.dart';

/// A screen with a large collapsing header and a scrolling body.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title, required this.children, this.actions, this.header});

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  /// Optional illustration or summary shown under the header (for example the BooBoard mascot).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayOnLime(darkPage: dark),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _LimeHeader(title: title, actions: actions, header: header),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 32 + MediaQuery.paddingOf(context).bottom),
              sliver: SliverList.list(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

/// The lime top of a settings page: back button and actions, the title in Fraunces, and an optional
/// header (for example the mascot). It always uses the light colours, since it is lime in both modes.
class _LimeHeader extends StatelessWidget {
  const _LimeHeader({required this.title, this.actions, this.header});

  final String title;
  final List<Widget>? actions;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final onLime = booboardThemeData(booboardBrandScheme(Brightness.light));
    return Theme(
      data: onLime,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: BooColors.lime,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 4, 20),
          child: IconTheme(
            data: const IconThemeData(color: BooColors.ink),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      if (canPop) const BackButton(color: BooColors.ink),
                      const Spacer(),
                      ...?actions,
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: OnboardingTitle(title, fontSize: 40)),
                if (header != null) Padding(padding: const EdgeInsets.only(top: 12), child: header),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row's icon: the lime circle used on Home, with the icon in ink.
class SettingsIconCircle extends StatelessWidget {
  const SettingsIconCircle(this.icon, {super.key, this.enabled = true});

  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.5,
    child: Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: BooColors.lime),
      child: Icon(icon, size: 19, color: BooColors.ink),
    ),
  );
}

/// A large illustration with a title and a short line, shown under a [SettingsPage] header.
class SettingsHero extends StatelessWidget {
  const SettingsHero({super.key, required this.mascot, required this.title, this.subtitle});

  /// Usually a `BooBoardMascot`.
  final Widget mascot;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            mascot,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleLarge?.copyWith(color: BooColors.ink, fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(subtitle!, style: text.bodyMedium?.copyWith(color: const Color(0xFF2E2A24))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled group of tiles drawn as one rounded container with thin gaps between the tiles.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                title!,
                style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
            ),
          for (var i = 0; i < children.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == children.length - 1 ? 0 : 2),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(i == 0 ? 22 : 6),
                  bottom: Radius.circular(i == children.length - 1 ? 22 : 6),
                ),
                child: Material(color: scheme.surfaceContainer, child: children[i]),
              ),
            ),
        ],
      ),
    );
  }
}

/// A group whose body is a free-form widget (chips, segmented buttons, text) instead of tiles.
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SettingsGroup(
    title: title,
    children: [Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), child: child)],
  );
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: enabled,
    leading: icon == null ? null : SettingsIconCircle(icon!, enabled: enabled),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right)),
    onTap: onTap,
    minTileHeight: 56,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: icon == null ? null : SettingsIconCircle(icon!, enabled: onChanged != null),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

class SettingsSliderTile extends StatelessWidget {
  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.valueLabel,
    this.icon,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;

  /// Called when the user lets go (settings writes should not happen on every drag frame).
  final ValueChanged<double> onChanged;
  final String Function(double value)? valueLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => _SliderTile(widget: this);
}

class _SliderTile extends StatefulWidget {
  const _SliderTile({required this.widget});

  final SettingsSliderTile widget;

  @override
  State<_SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<_SliderTile> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final w = widget.widget;
    final v = (_dragging ?? w.value).clamp(w.min, w.max);
    return ListTile(
      leading: w.icon == null ? null : SettingsIconCircle(w.icon!),
      title: Text(w.title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: w.valueLabel == null ? null : Text(w.valueLabel!(v)),
      subtitle: Slider(
        value: v,
        min: w.min,
        max: w.max,
        divisions: w.divisions,
        label: w.valueLabel?.call(v),
        semanticFormatterCallback: w.valueLabel == null ? null : (x) => w.valueLabel!(x),
        onChanged: (x) => setState(() => _dragging = x),
        onChangeEnd: (x) {
          setState(() => _dragging = null);
          w.onChanged(x);
        },
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// One choice for [SettingsChoiceChips].
class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label, {this.enabled = true});

  final T value;
  final String label;
  final bool enabled;
}

/// A wrap of single-choice chips, for short option lists (languages, expiry, themes).
class SettingsChoiceChips<T> extends StatelessWidget {
  const SettingsChoiceChips({super.key, required this.options, required this.selected, required this.onSelected});

  final List<ChoiceOption<T>> options;
  final T? selected;

  /// Not called for disabled options or for the option already selected.
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final o in options)
        ChoiceChip(
          label: Text(o.label),
          selected: o.value == selected,
          onSelected: o.enabled && o.value != selected ? (_) => onSelected(o.value) : null,
          tooltip: o.enabled ? null : context.l10n.settingsComingLater,
        ),
    ],
  );
}
