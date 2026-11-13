import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/riffster_theme.dart';

/// A rose line that counts up for as long as a clip is open.
///
/// Restart and Play only move the song, and the input panel can be
/// closed while a clip records. The count is what shows the tape is
/// still rolling through all of that.
class RecordingLine extends StatefulWidget {
  const RecordingLine({super.key, required this.started, this.short = false});

  final DateTime started;

  /// The chip on the rail has room for the count and little else.
  final bool short;

  @override
  State<RecordingLine> createState() => _RecordingLineState();
}

class _RecordingLineState extends State<RecordingLine> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = DateTime.now().difference(widget.started).inSeconds;
    return Row(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: RiffColors.miss,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.short
                ? 'Rec · ${seconds}s'
                : 'Recording · ${seconds}s. Restart does not stop this.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: RiffText.label.copyWith(
              color: RiffColors.miss,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
