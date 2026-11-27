// SPDX-License-Identifier: GPL-3.0-or-later
//
// The BooBoard ghost: every pose builds at the sizes it is used at, in light and dark, at font scale 1.3,
// with its TalkBack label, and springs between poses without overflowing.
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/app/l10n.dart';
import 'package:booboard/src/app/onboarding/booboard_mascot.dart';
import 'package:booboard/src/app/shell/booboard_theme.dart';
import 'package:material_ui/material_ui.dart';

Widget _host({required Brightness brightness, required Widget child, bool disableAnimations = false}) {
  return MaterialApp(
    localizationsDelegates: booboardLocalizationsDelegates,
    theme: booboardThemeData(booboardBrandScheme(Brightness.light)),
    darkTheme: booboardThemeData(booboardBrandScheme(Brightness.dark)),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: const TextScaler.linear(1.3), disableAnimations: disableAnimations),
      child: app!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final pose in BooBoardPose.values) {
      for (final size in [24.0, 48.0, 96.0, 160.0]) {
        testWidgets('${pose.name} at ${size.toInt()} dp builds in ${brightness.name} at font scale 1.3', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            _host(
              brightness: brightness,
              child: BooBoardMascot(size: size, pose: pose, label: 'BooBoard ghost'),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(BooBoardMascot)), Size(size, size));
          // The painter itself must have room: a zero-sized CustomPaint draws nothing.
          expect(
            tester.getSize(find.descendant(of: find.byType(BooBoardMascot), matching: find.byType(CustomPaint))),
            Size(size, size),
          );
          expect(find.bySemanticsLabel('BooBoard ghost'), findsOneWidget);
          semantics.dispose();
        });
      }
    }
  }

  testWidgets('the default pose is open and the default label is spoken', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(brightness: Brightness.light, child: const BooBoardMascot()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(const BooBoardMascot().pose, BooBoardPose.open);
    expect(find.bySemanticsLabel('BooBoard mascot'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('switching poses springs without exceptions and ends on the new pose', (tester) async {
    Widget ghost(BooBoardPose pose) => _host(
      brightness: Brightness.light,
      child: BooBoardMascot(size: 96, pose: pose),
    );
    await tester.pumpWidget(ghost(BooBoardPose.open));
    await tester.pumpAndSettle();
    for (final pose in [BooBoardPose.locked, BooBoardPose.glowing, BooBoardPose.quiet, BooBoardPose.open]) {
      await tester.pumpWidget(ghost(pose));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('reduced motion switches poses at once', (tester) async {
    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        disableAnimations: true,
        child: const BooBoardMascot(size: 96, pose: BooBoardPose.open),
      ),
    );
    await tester.pumpWidget(
      _host(
        brightness: Brightness.dark,
        disableAnimations: true,
        child: const BooBoardMascot(size: 96, pose: BooBoardPose.glowing),
      ),
    );
    // No transition is running, so a single frame is the final state.
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration, Duration.zero);
    expect(find.byKey(const ValueKey<BooBoardPose>(BooBoardPose.open)), findsNothing);
    expect(find.byKey(const ValueKey<BooBoardPose>(BooBoardPose.glowing)), findsOneWidget);
  });
}
