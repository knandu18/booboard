// SPDX-License-Identifier: GPL-3.0-or-later
//
// Small widgets shared by the privacy screens.
import 'package:material_ui/material_ui.dart';

import '../onboarding/booboard_mascot.dart';

import 'package:booboard/src/app/l10n.dart';

/// The mascot at the top of the privacy screens.
class PrivacyMascotSlot extends StatelessWidget {
  const PrivacyMascotSlot({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) =>
      BooBoardMascot(size: size, label: context.l10n.privacyMascotLabel, pose: BooBoardPose.locked);
}

/// A status card: a green card for good news, an error card for problems, neutral otherwise.
class PrivacyStatusCard extends StatelessWidget {
  const PrivacyStatusCard({super.key, required this.icon, required this.text, this.tone = PrivacyTone.neutral});

  final IconData icon;
  final String text;
  final PrivacyTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final (background, foreground) = switch (tone) {
      PrivacyTone.good => (dark ? const Color(0xFF1E3A22) : const Color(0xFFD7F5DA), scheme.onSurface),
      PrivacyTone.bad => (scheme.errorContainer, scheme.onErrorContainer),
      PrivacyTone.neutral => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 16),
            Expanded(
              child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}

enum PrivacyTone { good, bad, neutral }

/// Wraps the content of a screen body with the standard horizontal gutter.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: children);
}

/// Shows a message for a failed operation, without its details.
void showPrivacyMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
}
