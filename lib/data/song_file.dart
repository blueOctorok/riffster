import '../models/fretting_finger.dart';
import '../models/instrument.dart';
import '../models/tab_note.dart';
import '../models/tab_song.dart';

/// A song as it is written to a Library file.
///
/// A long song is thousands of notes, so a note is a short list and not
/// a named map: `[time, string, fret, length, pitch, finger]`. A bar is
/// `[start, end, beats]`. That keeps a file a fifth of the size.
Map<String, Object?> songToJson(TabSong song) {
  return {
    'title': song.title,
    'instrument': song.instrument.name,
    'tempoBpm': song.tempoBpm,
    'bars': [
      for (final bar in song.bars) [bar.startMs, bar.endMs, bar.beats],
    ],
    'notes': [
      for (final note in song.notes)
        [
          note.timeMs,
          note.string,
          note.fret,
          note.durationMs,
          note.midi,
          // By name, so the file still reads if the fingers are ever
          // listed in another order.
          note.finger?.name,
        ],
    ],
  };
}

/// Reads what [songToJson] wrote. Null for anything else, so one bad
/// file is skipped and the rest of the Library still opens.
TabSong? songFromJson(Object? json) {
  if (json is! Map) return null;
  final title = json['title'];
  final instrument = Instrument.values.asNameMap()[json['instrument']];
  final tempo = json['tempoBpm'];
  final bars = json['bars'];
  final notes = json['notes'];
  if (title is! String ||
      instrument == null ||
      tempo is! int ||
      bars is! List ||
      notes is! List) {
    return null;
  }
  final readBars = [for (final bar in bars) _barFrom(bar)];
  final readNotes = [for (final note in notes) _noteFrom(note)];
  // One row that does not read means the file was cut off, or was not
  // written by this app. Half a song is worse than none.
  if (readBars.contains(null) || readNotes.contains(null)) return null;
  return TabSong(
    title: title,
    instrument: instrument,
    tempoBpm: tempo,
    bars: readBars.nonNulls.toList(),
    notes: readNotes.nonNulls.toList(),
  );
}

// `row case [final int a, ...]` asks three things in one go: is this a
// list, is it exactly this long, and is each entry this type. Only when
// all are true do the names on the left exist.
SongBar? _barFrom(Object? row) {
  if (row case [final int startMs, final int endMs, final int beats]) {
    return SongBar(startMs: startMs, endMs: endMs, beats: beats);
  }
  return null;
}

TabNote? _noteFrom(Object? row) {
  if (row case [
    final int timeMs,
    final int string,
    final int fret,
    final int durationMs,
    final int midi,
    final Object? finger,
  ]) {
    return TabNote(
      timeMs: timeMs,
      string: string,
      fret: fret,
      durationMs: durationMs,
      midi: midi,
      finger: FrettingFinger.values.asNameMap()[finger],
    );
  }
  return null;
}
