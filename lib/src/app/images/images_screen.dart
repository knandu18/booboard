// SPDX-License-Identifier: GPL-3.0-or-later
//
// Images: making pictures from words with an offline image model. Until the model ships this is a
// short "coming soon" page in the lime look (lime paper in light and dark, like setup), opened from the
// Images card on Home.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n.dart';
import '../onboarding/booboard_mascot.dart';
import '../onboarding/onboarding_style.dart';

class ImagesScreen extends StatelessWidget {
  const ImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayOnLime(),
      child: Scaffold(
        backgroundColor: BooColors.lime,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    icon: const BackButtonIcon(),
                    color: BooColors.ink,
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => unawaited(Navigator.of(context).maybePop()),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: AnimatedBoo(size: 110)),
                      const SizedBox(height: 20),
                      OnboardingTitle(l10n.imagesSoonTitle),
                      const SizedBox(height: 12),
                      OnboardingLead(l10n.imagesSoonBody),
                      const SizedBox(height: 20),
                      OnboardingStatusPill(done: false, text: l10n.settingsComingLater),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
