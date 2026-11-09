import '../models/tab_note.dart';
import '../models/tab_song.dart';
import 'chord_book.dart';

/// A shelf in the chord palette. A grip lives on one shelf.
enum ChordShelf { open, barre, seventh }

extension ChordShelfLabel on ChordShelf {
  String get label => switch (this) {
    ChordShelf.open => 'Open',
    ChordShelf.barre => 'Barre',
    ChordShelf.seventh => 'Sevenths',
  };
}

/// One block in the palette. [label] is what the lane and the title show.
/// The barre Bm is named apart from the open Bm, or the title would read
/// "Bm · Bm" and you could not tell which shape you dropped.
class ChordBlock {
  const ChordBlock(this.shelf, this.grip, this.label);

  final ChordShelf shelf;
  final ChordGrip grip;
  final String label;
}

const chordBlocks = <ChordBlock>[
  ChordBlock(ChordShelf.open, openG, 'G'),
  ChordBlock(ChordShelf.open, openC, 'C'),
  ChordBlock(ChordShelf.open, openD, 'D'),
  ChordBlock(ChordShelf.open, openE, 'E'),
  ChordBlock(ChordShelf.open, openEm, 'Em'),
  ChordBlock(ChordShelf.open, openA, 'A'),
  ChordBlock(ChordShelf.open, openAm, 'Am'),
  ChordBlock(ChordShelf.open, openDm, 'Dm'),
  ChordBlock(ChordShelf.open, openBm, 'Bm'),
  ChordBlock(ChordShelf.barre, barreBm, 'Bm barre'),
  ChordBlock(ChordShelf.seventh, openEm7, 'Em7'),
  ChordBlock(ChordShelf.seventh, fSharp7, 'F#7'),
];

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
