// SPDX-License-Identifier: GPL-3.0-or-later
//
// OWNER: Wave 2-A. Helpers shared by the settings screens: a rebuild when settings change
// (from this engine or from the keyboard) and one place that writes a settings section.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../settings/booboard_settings.dart';
import '../app_services.dart';

/// Rebuilds [builder] whenever the settings change, whichever engine changed them.
class LiveSettings extends StatelessWidget {
  const LiveSettings({super.key, required this.builder});

  final Widget Function(BuildContext context, BooBoardSettings settings) builder;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).settings;
    return ListenableBuilder(listenable: store, builder: (context, _) => builder(context, store.value));
  }
}

/// Applies [change] and writes the result. [section] is the [SettingsSection] that changed, so the
/// keyboard reloads it. Fire and forget: the store notifies listeners at once.
void writeSettings(BuildContext context, String section, BooBoardSettings Function(BooBoardSettings current) change) {
  unawaited(AppScope.of(context).settings.update(change, sections: [section]));
}
