// SPDX-License-Identifier: GPL-3.0-or-later
//
// Icons that point along the reading direction (back arrows, undo, backspace) flip in
// right-to-left text. The material_ui icons carry no direction flag, so the flip is explicit.
import 'package:flutter/widgets.dart';

class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(this.icon, {super.key, required this.size, required this.color});

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: size, color: color);
    return Directionality.of(context) == TextDirection.rtl ? Transform.flip(flipX: true, child: glyph) : glyph;
  }
}
