// SPDX-License-Identifier: GPL-3.0-or-later
//
// DEBUG ONLY (Images phase 1): a "Make test picture" button in the Images panel, to try the helper process,
// the progress events and the picture on a real phone. Shown only when ImagesPanel.debugTools is true (debug
// builds); phase 2 replaces it with the real panel. Hard-coded English on purpose: it never ships.
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../keyboard/panels/keyboard_panel.dart';
import 'images_controller.dart';

/// The fixed test prompt and seed: the same picture every time, so timings can be compared.
const String kImagesTestPrompt = 'a cozy cabin in a snowy forest at night, warm lights, detailed';
const int kImagesTestSeed = 42;

/// What the debug view says for [state].
String imagesDebugStatus(ImagesState state) => switch (state) {
  ImagesIdle() => 'Ready',
  ImagesMaking(phase: ImagesPhase.loading) => 'Loading',
  ImagesMaking(phase: ImagesPhase.sampling, :final step, :final steps) => 'Step $step of $steps',
  ImagesMaking(phase: ImagesPhase.decoding) => 'Decoding',
  ImagesDone(:final millis) => 'Done in ${(millis / 1000).toStringAsFixed(1)} s',
  ImagesFailed(:final code) => 'Failed: $code',
};

class ImagesDebugView extends StatefulWidget {
  const ImagesDebugView({super.key, required this.panel});

  final PanelContext panel;

  @override
  State<ImagesDebugView> createState() => _ImagesDebugViewState();
}

class _ImagesDebugViewState extends State<ImagesDebugView> {
  late final ImagesController _controller;

  @override
  void initState() {
    super.initState();
    final services = widget.panel.session.services;
    _controller = ImagesController(host: services.host, events: services.events.images)..addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.panel.theme;
    final state = _controller.state;
    final label = TextStyle(
      fontFamily: theme.fontFamily,
      fontSize: 14,
      color: theme.letterKey.label,
      decoration: TextDecoration.none,
    );
    final size = widget.panel.size;
    final side = (size.height - 24).clamp(80.0, (size.width - 40) * 0.45);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.letterKey.fill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.letterKey.border ?? theme.suggestionDivider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: side,
                height: side,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: theme.suggestionDivider,
                    child: switch (state) {
                      ImagesDone(:final path) => Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        key: const Key('images-debug-picture'),
                        errorBuilder: (context, error, stack) => Center(
                          child: Text('Could not read the picture', style: label, textAlign: TextAlign.center),
                        ),
                      ),
                      _ => const SizedBox.expand(),
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Images (debug test)', style: label.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(imagesDebugStatus(state), key: const Key('images-debug-status'), style: label),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Button(
                          key: const Key('images-debug-action'),
                          text: _controller.isMaking ? 'Stop' : 'Make test picture',
                          fill: theme.actionKey.fill,
                          style: label.copyWith(color: theme.actionKey.label),
                          onTap: _controller.isMaking
                              ? _controller.stop
                              : () => _controller.make(kImagesTestPrompt, seed: kImagesTestSeed),
                        ),
                        _Button(
                          text: 'ABC',
                          fill: theme.suggestionDivider,
                          style: label,
                          onTap: widget.panel.session.closePanel,
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

class _Button extends StatelessWidget {
  const _Button({super.key, required this.text, required this.fill, required this.style, required this.onTap});

  final String text;
  final Color fill;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: text,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 56, minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: style),
      ),
    ),
  );
}
