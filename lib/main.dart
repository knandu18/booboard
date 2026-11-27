// SPDX-License-Identifier: GPL-3.0-or-later
//
// Both Flutter entrypoints live in this library because the engine resolves
// entrypoint functions in the root library:
//   main()          -> the settings app (SettingsActivity)
//   keyboardMain()  -> the keyboard (BooBoardImeService)
import 'package:material_ui/material_ui.dart';

import 'keyboard_main.dart';
import 'src/app/app.dart';
import 'src/app/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.create();
  runApp(AppScope(services: services, child: const BooBoardSettingsApp()));
}

@pragma('vm:entry-point')
Future<void> keyboardMain() => runKeyboard();
