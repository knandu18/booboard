// SPDX-License-Identifier: GPL-3.0-or-later
//
// CONTRACT (Wave 0) for the swipe trail; implementation owned by Wave 1-C.
// The keyboard view (Wave 1-A) feeds points into [GestureTrailController]
// and stacks [GestureTrailLayer] above the keys. Keep these constructor and
// method signatures stable.
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../engine/contracts.dart';
import '../../theme/keyboard_theme_data.dart';

class GestureTrailController extends ChangeNotifier {
  final List<TouchPoint> _points = [];
  late final UnmodifiableListView<TouchPoint> _view = UnmodifiableListView(_points);
  String? _preview;
  bool _active = false;

  /// Read-only live view of the points (no copy; do not keep it across
  /// [begin] or [clear]).
  List<TouchPoint> get points => _view;
  bool get isActive => _active;

  /// Live top candidate shown while swiping (set by the gesture engine).
  String? get preview => _preview;

  void begin(TouchPoint p) {
    _points
      ..clear()
      ..add(p);
    _active = true;
    _preview = null;
    notifyListeners();
  }

  void add(TouchPoint p) {
    if (!_active) return;
    _points.add(p);
    notifyListeners();
  }

  set preview(String? value) {
    if (value == _preview) return;
    _preview = value;
    notifyListeners();
  }

  /// Finger lifted: the trail fades out (painter decides how).
  void end() {
    _active = false;
    notifyListeners();
  }

  void clear() {
    _points.clear();
    _active = false;
    _preview = null;
    notifyListeners();
  }

  /// A snapshot of the path (safe to keep after [clear]).
  GesturePath get path => GesturePath(List.unmodifiable(_points));
}

/// How long the whole trail takes to disappear after the finger lifts.
const Duration _kLiftFade = Duration(milliseconds: 160);

/// Paints the swipe trail: a smoothed, gradient stroke whose tail fades with
/// age, plus a floating pill that previews the word being swiped.
class GestureTrailLayer extends StatefulWidget {
  const GestureTrailLayer({
    super.key,
    required this.controller,
    required this.theme,
    this.trailWidth = 6,
    this.fadeMs = 300,
    this.showTrail = true,
    this.showPreview = true,
  });

  final GestureTrailController controller;
  final KeyboardThemeData theme;

  /// From SwipeSettings.
  final double trailWidth;
  final int fadeMs;
  final bool showTrail;
  final bool showPreview;

  @override
  State<GestureTrailLayer> createState() => _GestureTrailLayerState();
}

class _GestureTrailLayerState extends State<GestureTrailLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _lift = AnimationController(vsync: this, duration: _kLiftFade);
  final _BubbleText _bubble = _BubbleText();
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    _adopt();
    widget.controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(GestureTrailLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
      _adopt();
    }
  }

  /// Takes over the controller's current state. A trail that already ended (for example when the keys come
  /// back after the emoji panel replaced them) counts as faded: this layer never saw the finger lift, so it
  /// would otherwise draw the old swipe until the next touch.
  void _adopt() {
    _wasActive = widget.controller.isActive;
    _lift.value = _wasActive ? 0 : 1;
  }

  void _onController() {
    final active = widget.controller.isActive;
    if (active && !_wasActive) {
      _lift.value = 0;
    } else if (!active && _wasActive) {
      if (widget.theme.motion.enabled) {
        _lift.forward(from: 0);
      } else {
        _lift.value = 1;
      }
    }
    _wasActive = active;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _lift.dispose();
    _bubble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _TrailPainter(
            controller: widget.controller,
            lift: _lift,
            theme: widget.theme,
            trailWidth: widget.trailWidth,
            fadeMs: widget.fadeMs,
            showTrail: widget.showTrail,
            showPreview: widget.showPreview,
            bubble: _bubble,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Caches the laid-out preview text so a frame only re-lays-out on change.
class _BubbleText {
  TextPainter? _painter;
  String? _text;
  TextStyle? _style;

  TextPainter layout(String text, TextStyle style) {
    final existing = _painter;
    if (existing != null && _text == text && _style == style) return existing;
    existing?.dispose();
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 600);
    _painter = painter;
    _text = text;
    _style = style;
    return painter;
  }

  void dispose() {
    _painter?.dispose();
    _painter = null;
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.controller,
    required this.lift,
    required this.theme,
    required this.trailWidth,
    required this.fadeMs,
    required this.showTrail,
    required this.showPreview,
    required this.bubble,
  }) : super(repaint: Listenable.merge([controller, lift]));

  final GestureTrailController controller;
  final Animation<double> lift;
  final KeyboardThemeData theme;
  final double trailWidth;
  final int fadeMs;
  final bool showTrail;
  final bool showPreview;
  final _BubbleText bubble;

  static const int _maxBuckets = 10;

  // Reused every frame.
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.butt
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
  final Paint _fill = Paint()..isAntiAlias = true;
  final Paint _shadow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  final Path _path = Path();

  @override
  void paint(Canvas canvas, Size size) {
    final pts = controller.points;
    final n = pts.length;
    if (n == 0) return;
    final active = controller.isActive;
    final liftT = active ? 0.0 : lift.value;
    if (liftT >= 1) return;
    final keep = 1 - liftT;
    final last = pts[n - 1];
    // After the finger lifts, time keeps moving so the tail dissolves too.
    final now = last.t + (active ? 0.0 : liftT * _kLiftFade.inMilliseconds);

    if (showTrail) _paintTrail(canvas, pts, n, now, keep);
    if (showPreview && active) {
      final text = controller.preview;
      if (text != null && text.isNotEmpty) _paintBubble(canvas, size, last, text);
    }
  }

  void _paintTrail(Canvas canvas, List<TouchPoint> pts, int n, double now, double keep) {
    final span = math.max(1, fadeMs);
    // First point still young enough to draw.
    var s = n - 1;
    while (s > 0 && now - pts[s - 1].t < span) {
      s--;
    }
    final head = pts[n - 1];
    final m = n - s;
    if (m < 2) {
      _fill.color = theme.trailEnd.withValues(alpha: keep);
      canvas.drawCircle(Offset(head.x, head.y), trailWidth / 2, _fill);
      return;
    }

    final buckets = math.min(_maxBuckets, m);
    for (var k = 0; k < buckets; k++) {
      final a = s + (m * k) ~/ buckets;
      final b = s + (m * (k + 1)) ~/ buckets - 1;
      if (b < a) continue;
      // Gradient position along the trail and age at the bucket's middle.
      final u = (k + 0.5) / buckets;
      final mid = pts[(a + b) ~/ 2];
      final fresh = (1 - (now - mid.t) / span).clamp(0.0, 1.0);
      final alpha = fresh * keep;
      if (alpha <= 0.01) continue;

      _path.reset();
      if (a == s) {
        _path.moveTo(pts[a].x, pts[a].y);
      } else {
        _path.moveTo((pts[a - 1].x + pts[a].x) / 2, (pts[a - 1].y + pts[a].y) / 2);
      }
      for (var i = a; i <= b; i++) {
        if (i == n - 1) {
          _path.lineTo(pts[i].x, pts[i].y);
        } else {
          _path.quadraticBezierTo(pts[i].x, pts[i].y, (pts[i].x + pts[i + 1].x) / 2, (pts[i].y + pts[i + 1].y) / 2);
        }
      }
      final color = Color.lerp(theme.trailStart, theme.trailEnd, u)!;
      _stroke
        ..color = color.withValues(alpha: color.a * alpha)
        ..strokeWidth = trailWidth * (0.45 + 0.55 * fresh);
      canvas.drawPath(_path, _stroke);
    }
    // Round head so the newest end is not squared off.
    _fill.color = theme.trailEnd.withValues(alpha: theme.trailEnd.a * keep);
    canvas.drawCircle(Offset(head.x, head.y), trailWidth / 2, _fill);
  }

  void _paintBubble(Canvas canvas, Size size, TouchPoint head, String text) {
    final scale = theme.labelScale;
    final style = TextStyle(
      color: theme.popupLabel,
      fontSize: 20 * scale,
      fontWeight: theme.labelWeight,
      fontFamily: theme.fontFamily,
      fontVariations: theme.labelFontVariations.isEmpty ? null : theme.labelFontVariations,
      height: 1.2,
    );
    final tp = bubble.layout(text, style);
    final w = math.max(tp.width + 32, 56.0);
    final h = tp.height + 16;
    // Above the fingertip, kept inside the keyboard area.
    final maxLeft = math.max(4.0, size.width - w - 4);
    final left = (head.x - w / 2).clamp(4.0, maxLeft);
    final top = math.max(2.0, head.y - 56 - h);
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), Radius.circular(h / 2));
    _shadow.color = const Color(0x33000000);
    canvas.drawRRect(rect.shift(const Offset(0, 2)), _shadow);
    _fill.color = theme.popupFill;
    canvas.drawRRect(rect, _fill);
    tp.paint(canvas, Offset(left + (w - tp.width) / 2, top + (h - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.theme != theme ||
      old.controller != controller ||
      old.trailWidth != trailWidth ||
      old.fadeMs != fadeMs ||
      old.showTrail != showTrail ||
      old.showPreview != showPreview;
}
