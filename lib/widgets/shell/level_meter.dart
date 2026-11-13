import 'package:flutter/material.dart';

import '../../theme/riffster_theme.dart';

/// A bar that jumps when the instrument sends a signal.
///
/// A real pluck is often only a fifth of full scale, so the bar treats
/// 0.2 as full. Quiet noise stays a sliver. A dead bar means this input
/// is not hearing the strings.
class LevelMeter extends StatelessWidget {
  const LevelMeter({super.key, required this.level, this.height = 8});

  final double level;
  final double height;

  @override
  Widget build(BuildContext context) {
    final filled = (level / 0.2).clamp(0.0, 1.0);
    final radius = BorderRadius.all(Radius.circular(height / 2));
    // No width of its own: it is as wide as whatever it is put in.
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: RiffColors.line, borderRadius: radius),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: filled,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: filled > 0.85 ? RiffColors.miss : RiffColors.hit,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
