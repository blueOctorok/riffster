import 'dart:ui';

import '../../models/instrument.dart';
import '../../music/song_timeline.dart';

/// Where everything on the stage sits, for one instrument at one size.
///
/// The painters ask this instead of doing their own arithmetic, so the
/// board, the strings, and the notes cannot disagree about where a
/// string is.
class StageMetrics {
  const StageMetrics({
    required this.instrument,
    required this.size,
    required this.pixelsPerSecond,
  });

  /// The layout for [timeline]'s instrument, scrolling at a speed that
  /// suits how tightly its notes are packed.
  factory StageMetrics.forSong(SongTimeline timeline, Size size) {
    final instrument = timeline.song.instrument;
    return StageMetrics(
      instrument: instrument,
      size: size,
      pixelsPerSecond: scrollSpeedFor(
        timeline,
        noteDiameter: _noteRadiusOf(instrument) * 2,
      ),
    );
  }

  /// The stage is a fixed band. Stretching it to the window spread the
  /// strings far apart, which is the opposite of a tab you can read.
  static const height = 336.0;
  static const cornerRadius = 18.0;

  /// The strip at the left that carries the string names.
  static const nutWidth = 54.0;

  /// Room above the top string for a chord name.
  static const _headSpace = 48.0;

  /// Room below the bottom string for a bar number.
  static const _footSpace = 34.0;

  final Instrument instrument;
  final Size size;

  /// How far a note travels in one second of song time.
  final double pixelsPerSecond;

  bool get _isBass => instrument == Instrument.bass;

  /// A bass has fewer, fatter strings, so they sit farther apart and
  /// the notes on them are larger.
  double get stringGap => _isBass ? 62 : 44;
  double get noteRadius => _noteRadiusOf(instrument);

  static double _noteRadiusOf(Instrument instrument) {
    return instrument == Instrument.bass ? 20 : 16;
  }

  /// About a fifth of the way in. A note you just played stays in view
  /// to the left of the line long enough to read its result.
  double get playheadX => size.width * 0.2;

  double get topStringY {
    final strings = stringGap * (instrument.stringCount - 1);
    return _headSpace + (size.height - _headSpace - _footSpace - strings) / 2;
  }

  double get bottomStringY => stringY(instrument.stringCount);

  /// Staff string 1 is the top line.
  double stringY(int string) => topStringY + stringGap * (string - 1);

  /// Time becomes distance from the playhead. Future notes sit to the
  /// right. Once the clock passes a note, it slips off to the left.
  double xAt(num timeMs, double positionMs) {
    return playheadX + (timeMs - positionMs) / 1000 * pixelsPerSecond;
  }

  /// How much song time [pixels] of the stage covers.
  double msAcross(double pixels) => pixels / pixelsPerSecond * 1000;

  /// How thick a string is drawn. Thicker toward the low string, the
  /// way a set of strings is.
  double stringWidth(int string) {
    const guitar = [1.3, 1.6, 2.0, 2.6, 3.2, 3.9];
    const bass = [3.8, 4.8, 5.8, 6.8];
    return (_isBass ? bass : guitar)[string - 1];
  }

  /// A wound string is a core with wire wrapped around it, which is why
  /// it looks ridged. Every bass string is wound. On a guitar the three
  /// lowest are.
  bool isWound(int string) => _isBass || string >= 4;

  @override
  bool operator ==(Object other) {
    return other is StageMetrics &&
        other.instrument == instrument &&
        other.size == size &&
        other.pixelsPerSecond == pixelsPerSecond;
  }

  @override
  int get hashCode => Object.hash(instrument, size, pixelsPerSecond);
}

/// How fast this song should scroll so its notes do not pile up.
///
/// A slow song can crawl. A fast one has to move quicker, or two notes a
/// sixteenth apart are drawn on top of each other. The speed is set so
/// the song's tighter gaps still leave a sliver of board between two
/// notes, and is held between a calm floor and a readable ceiling.
double scrollSpeedFor(SongTimeline timeline, {required double noteDiameter}) {
  const slowest = 170.0;
  const fastest = 420.0;
  final gapMs = timeline.tightGapMs;
  if (gapMs == null || gapMs <= 0) return slowest;
  final wanted = (noteDiameter + 4) / (gapMs / 1000);
  return wanted.clamp(slowest, fastest).toDouble();
}
