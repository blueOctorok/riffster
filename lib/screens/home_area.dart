import 'package:flutter/material.dart';

import '../models/instrument.dart';
import '../models/tab_song.dart';
import '../theme/riffster_theme.dart';
import '../widgets/lift_card.dart';
import '../widgets/shell/app_area.dart';

/// Where the app opens: what is on the stage, and the four doors.
class HomeArea extends StatelessWidget {
  const HomeArea({
    super.key,
    required this.song,
    required this.onStage,
    required this.onOpenFile,
    required this.onArea,
  });

  /// The song waiting on the stage.
  final TabSong song;

  /// Goes to the stage with [song] on it.
  final VoidCallback onStage;

  /// Asks for a Guitar Pro file. Null while one is already being read.
  final VoidCallback? onOpenFile;
  final ValueChanged<AppArea> onArea;

  static const _doors = [
    AppArea.songs,
    AppArea.practice,
    AppArea.build,
    AppArea.create,
  ];

  /// One line under each door's name.
  static String _blurb(AppArea area, Instrument instrument) {
    return switch (area) {
      AppArea.songs => 'Open a Guitar Pro file and play along with it.',
      AppArea.practice => 'Scales, arpeggios, and drills, scored as you play.',
      AppArea.build =>
        instrument == Instrument.guitar
            ? 'Drop chords into a lane and play through them.'
            : 'Lay out a line of your own on the neck.',
      AppArea.create => 'Describe a riff and get an original one to learn.',
      AppArea.home || AppArea.library => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final instrument = song.instrument;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 44, 40, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are we playing today?',
            style: RiffText.title.copyWith(fontSize: 46),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick up where you left off, or start something new.',
            style: RiffText.label,
          ),
          const SizedBox(height: 30),
          LiftCard(
            key: const Key('home-stage'),
            onTap: onStage,
            padding: const EdgeInsets.fromLTRB(28, 24, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ON THE STAGE', style: RiffText.caption),
                      const SizedBox(height: 10),
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RiffText.title,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${song.tempoBpm} bpm · ${instrument.label}',
                        style: RiffText.label,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: RiffColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: RiffShadows.goldGlow,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 30,
                      color: RiffColors.onGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // IntrinsicHeight makes the four cards as tall as the tallest,
          // however many lines each blurb wraps to.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final door in _doors) ...[
                  if (door != _doors.first) const SizedBox(width: 16),
                  Expanded(
                    child: _Door(
                      area: door,
                      blurb: _blurb(door, instrument),
                      ready: door.readyFor(instrument),
                      // The song on the stage is one press away above,
                      // so this door goes straight to choosing a file.
                      onTap: door == AppArea.songs
                          ? onOpenFile
                          : () => onArea(door),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the four ways in. A door that is not built yet is dim, says
/// so, and does not lift.
class _Door extends StatelessWidget {
  const _Door({
    required this.area,
    required this.blurb,
    required this.ready,
    required this.onTap,
  });

  final AppArea area;
  final String blurb;
  final bool ready;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LiftCard(
      key: Key('door-${area.name}'),
      onTap: ready ? onTap : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                area.icon,
                size: 24,
                color: ready ? RiffColors.gold : RiffColors.faint,
              ),
              const Spacer(),
              if (!ready)
                Text(
                  'SOON',
                  style: RiffText.caption.copyWith(color: RiffColors.faint),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            area.label,
            style: RiffText.title.copyWith(
              fontSize: 28,
              color: ready ? RiffColors.cream : RiffColors.quiet,
            ),
          ),
          const SizedBox(height: 6),
          Text(blurb, style: RiffText.label),
        ],
      ),
    );
  }
}
