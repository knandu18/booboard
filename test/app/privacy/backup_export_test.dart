// SPDX-License-Identifier: GPL-3.0-or-later
//
// SEC-08: exporting replaces the chosen file, so the screen reads the file back and only reports a
// saved backup when it matches. The suggested name carries the time, so a new file is the default.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/app/app_services.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/privacy/backup_screen.dart';
import 'package:booboard/src/security/app_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_fakes.dart';

void main() {
  late AppFakes fakes;
  final sealed = Uint8List.fromList(List<int>.generate(64, (i) => i));

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    fakes = AppFakes();
    SecureScreenGuard.instance = SecureScreenGuard(fakes.app);
    when(() => fakes.app.setSecureScreen(any())).thenAnswer((_) async {});
    when(() => fakes.platform.secureList()).thenAnswer((_) async => []);
    when(() => fakes.app.sealBackup(any(), any())).thenAnswer((_) async => sealed);
    when(() => fakes.app.createDocument(any(), any())).thenAnswer((_) async => 'content://doc/1');
    when(() => fakes.app.writeDocument(any(), any())).thenAnswer((_) async {});
  });

  tearDown(() => SecureScreenGuard.instance = null);

  /// The screen reads real (missing) theme folders, so real time must pass for its futures to finish.
  Future<void> settleIo(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  Future<void> export(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AppScope(
        services: fakes.services,
        child: const MaterialApp(localizationsDelegates: booboardLocalizationsDelegates, home: BackupScreen()),
      ),
    );
    await settleIo(tester);
    final button = find.text('Create encrypted backup');
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await settleIo(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'correct horse battery staple');
    await tester.enterText(fields.at(1), 'correct horse battery staple');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await settleIo(tester);
  }

  testWidgets('a file that reads back the same is reported as saved; the name has date and time', (tester) async {
    when(() => fakes.app.readDocument(any(), any())).thenAnswer((_) async => sealed);
    await export(tester);

    final name = verify(() => fakes.app.createDocument(captureAny(), any())).captured.single as String;
    expect(name, matches(RegExp(r'^booboard-\d{8}-\d{4}\.boobackup$')));
    expect(find.textContaining('Backup saved'), findsOneWidget);
  });

  testWidgets('a file that reads back different is reported as possibly damaged', (tester) async {
    when(() => fakes.app.readDocument(any(), any())).thenAnswer((_) async => Uint8List(3));
    await export(tester);

    expect(find.textContaining('Backup saved'), findsNothing);
    expect(find.textContaining('could not be checked'), findsOneWidget);
  });
}
