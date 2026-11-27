// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:booboard/src/engine/contracts.dart';
import 'package:booboard/src/keyboard/gesture_layer/gesture_trail.dart';
import 'package:booboard/src/theme/keyboard_theme_data.dart';

void main() {
  group('GestureTrailController', () {
    test('records a path and exposes a read-only live view', () {
      final c = GestureTrailController();
      var notified = 0;
      c.addListener(() => notified++);
      c.begin(const TouchPoint(10, 10, 0));
      c.add(const TouchPoint(20, 10, 8));
      expect(c.isActive, isTrue);
      expect(c.points.length, 2);
      expect(() => c.points.add(const TouchPoint(0, 0, 0)), throwsUnsupportedError);
      expect(identical(c.points, c.points), isTrue, reason: 'no copy per access');
      c.preview = 'hi';
      c.preview = 'hi'; // unchanged: no notification
      expect(c.preview, 'hi');
      expect(notified, 3);
      c.end();
      expect(c.isActive, isFalse);
      c.add(const TouchPoint(30, 10, 16)); // ignored after end
      expect(c.points.length, 2);
      expect(c.path.points.length, 2);
      c.clear();
      expect(c.points, isEmpty);
      expect(c.preview, isNull);
    });

    test('path is a snapshot that survives clear()', () {
      final c = GestureTrailController()
        ..begin(const TouchPoint(1, 1, 0))
        ..add(const TouchPoint(2, 2, 5));
      final snapshot = c.path;
      c.clear();
      expect(snapshot.points.length, 2);
    });

    test('begin resets the preview and the old path', () {
      final c = GestureTrailController()
        ..begin(const TouchPoint(1, 1, 0))
        ..preview = 'old'
        ..end()
        ..begin(const TouchPoint(5, 5, 100));
      expect(c.preview, isNull);
      expect(c.points.length, 1);
    });
  });

  group('GestureTrailLayer', () {
    final theme = KeyboardThemeData.fallback(Brightness.light);

    Widget host(GestureTrailController c, {bool showTrail = true, bool showPreview = true, int fadeMs = 300}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 400,
          height: 300,
          child: GestureTrailLayer(
            controller: c,
            theme: theme,
            trailWidth: 8,
            fadeMs: fadeMs,
            showTrail: showTrail,
            showPreview: showPreview,
          ),
        ),
      );
    }

    RenderBox paintBox(WidgetTester tester) => tester.renderObject<RenderBox>(
      find.descendant(of: find.byType(GestureTrailLayer), matching: find.byType(CustomPaint)),
    );

    Future<GestureTrailController> swipe(WidgetTester tester, {bool trail = true, bool preview = true}) async {
      final c = GestureTrailController();
      await tester.pumpWidget(host(c, showTrail: trail, showPreview: preview));
      c.begin(const TouchPoint(40, 200, 1000));
      for (var i = 1; i <= 12; i++) {
        c.add(TouchPoint(40 + i * 20.0, 200 - i * 6.0, 1000 + i * 10));
      }
      await tester.pump();
      return c;
    }

    testWidgets('draws nothing before a swipe and ignores pointers', (tester) async {
      final c = GestureTrailController();
      await tester.pumpWidget(host(c));
      expect(paintBox(tester), isNot(paints..path()));
      expect(find.descendant(of: find.byType(GestureTrailLayer), matching: find.byType(IgnorePointer)), findsWidgets);
    });

    testWidgets('paints a smoothed trail while the finger moves', (tester) async {
      await swipe(tester);
      expect(paintBox(tester), paints..path());
    });

    testWidgets('the tail fades by TouchPoint age: old points are not drawn', (tester) async {
      final c = GestureTrailController();
      await tester.pumpWidget(host(c, fadeMs: 300));
      c.begin(const TouchPoint(40, 200, 0));
      c.add(const TouchPoint(100, 180, 50));
      await tester.pump();
      expect(paintBox(tester), paints..path());
      // Much later the old points are older than fadeMs; only the newest remains.
      c.add(const TouchPoint(300, 100, 5000));
      await tester.pump();
      expect(paintBox(tester), isNot(paints..path()));
      expect(paintBox(tester), paints..circle());
    });

    testWidgets('after end() the trail fades out quickly and then disappears', (tester) async {
      final c = await swipe(tester, preview: false);
      c.end();
      await tester.pump();
      expect(paintBox(tester), paints..path());
      await tester.pump(const Duration(milliseconds: 80));
      expect(paintBox(tester), paints..path());
      await tester.pump(const Duration(milliseconds: 200));
      expect(paintBox(tester), isNot(paints..path()));
      expect(paintBox(tester), isNot(paints..circle()));
    });

    testWidgets('a new swipe after a fade starts fully visible again', (tester) async {
      final c = await swipe(tester);
      c.end();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(paintBox(tester), isNot(paints..path()));
      c.begin(const TouchPoint(60, 220, 9000));
      c.add(const TouchPoint(160, 200, 9020));
      c.add(const TouchPoint(260, 180, 9040));
      await tester.pump();
      expect(paintBox(tester), paints..path());
    });

    testWidgets('showPreview draws the pill bubble only while swiping', (tester) async {
      final c = await swipe(tester, trail: false);
      expect(paintBox(tester), isNot(paints..rrect()), reason: 'no preview text yet');
      c.preview = 'hello';
      await tester.pump();
      expect(
        paintBox(tester),
        paints
          ..rrect()
          ..rrect(),
      );
      // showTrail is off: no trail path at all.
      expect(paintBox(tester), isNot(paints..path()));
      c.end();
      await tester.pump();
      expect(paintBox(tester), isNot(paints..rrect()));
    });

    testWidgets('showPreview off hides the bubble but keeps the trail', (tester) async {
      final c = await swipe(tester, preview: false);
      c.preview = 'hello';
      await tester.pump();
      expect(paintBox(tester), paints..path());
      expect(paintBox(tester), isNot(paints..rrect()));
    });

    testWidgets('a finished swipe is not redrawn when the layer is rebuilt (emoji panel and back)', (tester) async {
      final c = await swipe(tester, preview: false);
      c.end();
      await tester.pump();
      // The emoji panel replaces the keys: the layer goes away while the trail still holds the old points.
      await tester.pumpWidget(const SizedBox());
      // Back to the keys: a new layer with the same controller.
      await tester.pumpWidget(host(c));
      expect(paintBox(tester), isNot(paints..path()));
      expect(paintBox(tester), isNot(paints..circle()));
      // The next swipe still draws normally.
      c.begin(const TouchPoint(60, 220, 9000));
      c.add(const TouchPoint(160, 200, 9020));
      c.add(const TouchPoint(260, 180, 9040));
      await tester.pump();
      expect(paintBox(tester), paints..path());
    });

    testWidgets('changing the controller rewires repaints without leaking listeners', (tester) async {
      final a = GestureTrailController();
      final b = GestureTrailController();
      await tester.pumpWidget(host(a));
      await tester.pumpWidget(host(b));
      b.begin(const TouchPoint(40, 200, 0));
      b.add(const TouchPoint(140, 160, 20));
      b.add(const TouchPoint(240, 120, 40));
      await tester.pump();
      expect(paintBox(tester), paints..path());
      // Disposing the tree removes the listener; later events must not throw.
      await tester.pumpWidget(const SizedBox());
      b.add(const TouchPoint(300, 100, 60));
      b.end();
      expect(tester.takeException(), isNull);
    });
  });
}
