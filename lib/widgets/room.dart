import 'package:flutter/material.dart';

import '../theme/riffster_theme.dart';

/// The room every screen sits in: warm in the middle, where the lamp
/// is, and falling off to near black in the corners.
class Room extends StatelessWidget {
  const Room({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Fills the window even when its child is shorter, so the light
    // does not stop where the content does.
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.35),
            radius: 1.15,
            colors: [Color(0xFF29241D), RiffColors.room, RiffColors.roomDeep],
            stops: [0, 0.55, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A raised strip that looks like smoked glass: lighter along its top
/// edge, where the room's light lands, with a soft shadow underneath.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Flutter cannot draw a rounded border whose color changes from top
    // to bottom. So the "border" is a whole rounded box filled with a
    // light-to-dark gradient, and the panel sits on it one pixel in.
    // That one pixel showing around the edge is the hairline.
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: RiffShadows.panel,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5A5046), Color(0xFF39322B), Color(0xFF16130F)],
          stops: [0, 0.3, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF342D27), RiffColors.panel, Color(0xFF1F1B16)],
              stops: [0, 0.45, 1],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
