import '../audio/pitch.dart';
import '../models/instrument.dart';
import 'imported_score.dart';

/// What can be done with one part of a file.
enum PartUse {
  /// Played as the file has it, on the staff of the instrument in hand.
  written,

  /// Not written for the bass, so its melody is moved onto one.
  melody,

  /// Listed so it does not vanish without a word, and cannot be chosen.
  unavailable,
}

class PartChoice {
  const PartChoice(this.track, this.use, this.detail);

  final ImportedTrack track;
  final PartUse use;

  /// The line under the part's name: how many notes it has, or why it
  /// cannot be played.
  final String detail;
}

/// Sorts the parts of a file by what [playing] can do with them. Every
/// part comes back, in the file's order.
List<PartChoice> partChoicesFor(
  Instrument playing,
  List<ImportedTrack> tracks,
) {
  return [for (final track in tracks) _choiceFor(playing, track)];
}

PartChoice _choiceFor(Instrument playing, ImportedTrack track) {
  final count = track.notes.length;
  final notes = count == 1 ? '1 note' : '$count notes';
  final written = track.instrument;
  if (written == playing) {
    return PartChoice(track, PartUse.written, _withTuning(notes, track));
  }
  // As low as the instrument in hand, with the wrong number of strings:
  // a bass with a fifth string, or a guitar with a seventh.
  if (track.isAsLowAs(playing)) {
    return PartChoice(
      track,
      PartUse.unavailable,
      '${track.tuning.length} strings · not supported yet',
    );
  }
  if (playing == Instrument.bass) {
    return PartChoice(track, PartUse.melody, notes);
  }
  return PartChoice(
    track,
    PartUse.unavailable,
    written == null
        ? 'Not a guitar part'
        : 'A ${written.label.toLowerCase()} part · '
              'switch to ${written.label} to play it',
  );
}

/// Adds the tuning when it is not the standard one. The frets in the
/// file are only right on an instrument tuned the same way.
String _withTuning(String notes, ImportedTrack track) {
  final standard = track.instrument!.openStringMidi;
  for (var i = 0; i < standard.length; i++) {
    if (track.tuning[i] != standard[i]) {
      // Low string first, the way a tuning is said out loud.
      final names = track.tuning.reversed.map(pitchName).join(' ');
      return '$notes · tuned $names';
    }
  }
  return notes;
}
