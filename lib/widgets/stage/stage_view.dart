import 'package:flutter/material.dart';

import '../../music/practice_run.dart';
import '../../theme/neck_theme.dart';
import '../../theme/riffster_theme.dart';
import 'board_painter.dart';
import 'stage_ink.dart';
import 'stage_metrics.dart';
import 'stage_painter.dart';

/// The play area: a fretboard seen from above, with the song scrolling
/// along it toward the gold line.
///
/// It is two pictures stacked. The board underneath is painted once.
/// The notes on top are painted every frame. Each sits in its own
/// [RepaintBoundary], which tells Flutter "redrawing this does not mean
/// redrawing what is around it". So a frame costs one layer, and the
/// buttons and labels around the stage are not touched.
class StageView extends StatefulWidget {
  const StageView({
    super.key,
    required this.run,
    required this.neck,
    this.dropHighlighted = false,
  });

  final PracticeRun run;
  final NeckTheme neck;

  /// True while a chord is being dragged over the stage.
  final bool dropHighlighted;

  @override
  State<StageView> createState() => _StageViewState();
}

class _StageViewState extends State<StageView> {
  StageInk? _ink;

  /// The brushes depend on the note size and the wood. They are rebuilt
  /// only when one of those changes, never per frame.
  StageInk _inkFor(double noteRadius) {
    final ink = _ink;
    if (ink != null && ink.noteRadius == noteRadius && ink.neck == widget.neck) {
      return ink;
    }
    return _ink = StageInk(noteRadius: noteRadius, neck: widget.neck);
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(StageMetrics.cornerRadius));
    return Container(
      height: StageMetrics.height,
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: RiffShadows.board,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: widget.dropHighlighted
            ? Border.all(color: RiffColors.gold, width: 2)
            : null,
      ),
      // A new song can change the instrument and the scroll speed, so
      // the layout is worked out again whenever the run says it changed.
      child: ListenableBuilder(
        listenable: widget.run,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final metrics = StageMetrics.forSong(
              widget.run.timeline,
              Size(constraints.maxWidth, StageMetrics.height),
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    painter: BoardPainter(neck: widget.neck, metrics: metrics),
                  ),
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    painter: StagePainter(
                      run: widget.run,
                      metrics: metrics,
                      neck: widget.neck,
                      ink: _inkFor(metrics.noteRadius),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
