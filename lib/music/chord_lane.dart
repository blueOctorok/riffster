import '../models/tab_note.dart';
import '../models/tab_song.dart';
import 'chord_book.dart';

/// A family in the chord book. The screen shows one family at a time.
enum ChordGroup { open, barre, seventh, sus, power, more }

extension ChordGroupLabel on ChordGroup {
  String get label => switch (this) {
    ChordGroup.open => 'Open',
    ChordGroup.barre => 'Barre',
    ChordGroup.seventh => 'Sevenths',
    ChordGroup.sus => 'Sus',
    ChordGroup.power => 'Power',
    ChordGroup.more => 'More',
  };

  /// One line under the chips, so the group says what you are looking at.
  String get blurb => switch (this) {
    ChordGroup.open => 'First position. No full barre.',
    ChordGroup.barre =>
      'One shape, moved up the neck. F is the first E-shape major.',
    ChordGroup.seventh => 'The chord plus its 7th. Dominant, minor, or major.',
    ChordGroup.sus =>
      'The 3rd steps aside. sus2 is a whole step up, sus4 is the 4th.',
    ChordGroup.power => 'Root and fifth. Move it to any fret.',
    ChordGroup.more => 'Diminished, augmented, and add9.',
  };
}

/// One card in the book. [label] is what the lane and the title show.
///
/// A barre that shares a name with an open chord gets the shape in the
/// label, so a dropped lane can say "Bm · Bm E-shape" and you can tell
/// the two grips apart.
class ChordBlock {
  const ChordBlock({
    required this.group,
    required this.grip,
    required this.label,
    this.section = '',
  });

  final ChordGroup group;
  final ChordGrip grip;
  final String label;

  /// Empty when the group is one grid. Barre, sevenths, and power
  /// split into a second row of chips, and this is which chip.
  final String section;
}

/// A chord sitting in the lane. How long it rings is the gap before the
/// next attack, so dragging the edge moves every chord after it.
class LaneChord {
  LaneChord(this.block, {this.durationMs = chordHoldMs});

  final ChordBlock block;
  int durationMs;
}

/// What a drag is carrying. A block is new. An index is a chip already
/// in the lane, and dropping it inserts it in front of the target.
class LaneDrag {
  const LaneDrag.block(this.block) : from = null;
  const LaneDrag.move(this.from) : block = null;

  final ChordBlock? block;
  final int? from;
}

/// The shortest and longest a dropped chord is allowed to ring.
const laneMinMs = 400;
const laneMaxMs = 6000;

/// True when one finger is already on the fret the next shape needs.
bool fingerStays(ChordGrip from, ChordGrip to) {
  for (var string = 0; string < 6; string++) {
    final fret = from.frets[string];
    final finger = from.fingers[string];
    if (fret == null || fret == 0 || finger == null) continue;
    if (to.frets[string] == fret && to.fingers[string] == finger) return true;
  }
  return false;
}

/// The lane as a song. Chords sit end to end, after a short lead so the
/// first shape is visible before the playhead reaches it. The gap before
/// the next attack is this chord's duration, so a longer ring pushes the
/// chords after it later. The result is an ordinary note list.
TabSong songFromLane(List<LaneChord> lane) {
  final notes = <TabNote>[];
  var time = chordLeadMs;
  for (final placed in lane) {
    notes.addAll(notesForGrip(placed.block.grip, time, placed.durationMs));
    time += placed.durationMs;
  }
  return TabSong(
    title: lane.isEmpty
        ? 'Changes'
        : lane.map((placed) => placed.block.label).join(' · '),
    tempoBpm: 60,
    notes: notes,
  );
}
