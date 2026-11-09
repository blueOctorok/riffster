import '../models/tab_song.dart';
import 'chord_book.dart';

/// Original chord practice. Every grip is the one the importer uses, so
/// a finger learned here is the finger a song will show. The last step is
/// a short change we wrote. No copyrighted song is included.
final chordCourse = <TabSong>[
  _one(openEm, 'Em'),
  _one(openE, 'E'),
  _one(openAm, 'Am'),
  _one(openC, 'C'),
  _one(openG, 'G'),
  _one(openD, 'D'),
  _one(openA, 'A'),
  _one(openDm, 'Dm'),
  _one(openEm7, 'Em7'),
  _one(fSharp7, 'F#7'),
  _one(openBm, 'Bm'),
  _one(barreBm, 'Bm barre'),
  _change('G · D · Em · C', [openG, openD, openEm, openC]),
];

TabSong _one(ChordGrip grip, String title) {
  return TabSong(
    title: title,
    tempoBpm: 60,
    notes: notesForGrip(grip, chordLeadMs, chordHoldMs),
  );
}

TabSong _change(String title, List<ChordGrip> grips) {
  return TabSong(
    title: title,
    tempoBpm: 60,
    notes: [
      for (var i = 0; i < grips.length; i++)
        ...notesForGrip(
          grips[i],
          chordLeadMs + i * chordHoldMs,
          chordHoldMs,
        ),
    ],
  );
}
