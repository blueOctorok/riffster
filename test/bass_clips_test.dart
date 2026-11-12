import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/audio/clip_recorder.dart';
import 'package:riffster/audio/wav.dart';
import 'package:riffster/models/instrument.dart';

import 'support/clips.dart';

/// The fewest mistakes each clip has ever scored. A change to the
/// detector may lower a number here and may never raise one.
final _bestFile = File('${ClipRecorder.folder}/best.json');

void main() {
  test('the score lines up what was played with what was heard', () {
    const played = [28, 33, 38, 43];
    expect(clipScore(played: played, heard: played), (missing: 0, extra: 0));
    // The A was not heard, and an octave ghost followed the last note.
    expect(
      clipScore(played: played, heard: [28, 38, 43, 55]),
      (missing: 1, extra: 1),
    );
    // A strum has no one pitch, so any sound answers it.
    expect(
      clipScore(played: [28, null, 33], heard: [28, 52, 33]),
      (missing: 0, extra: 0),
    );
  });

  test('note names read back as the notes they name', () {
    expect(['E1', 'A#2', 'C4', '?'].map(midiOfName), [28, 46, 60, null]);
  });

  test('a saved clip reads back as the note that went into it', () {
    // Two tenths of a second of nothing, then an A string: 55 hertz
    // with a quieter octave on top, as 16-bit samples.
    const rate = 48000;
    final sound = ByteData(rate * 2);
    for (var i = rate ~/ 5; i < rate; i++) {
      final turn = 2 * math.pi * 55 * i / rate;
      final sample = 0.3 * (math.sin(turn) + 0.5 * math.sin(2 * turn));
      sound.setInt16(i * 2, (sample * 32767).round(), Endian.little);
    }
    final folder = Directory.systemTemp.createTempSync('riffster-clip');
    addTearDown(() => folder.deleteSync(recursive: true));
    final file = File('${folder.path}/bass-1.wav')
      ..writeAsBytesSync(
        wavBytes(sound.buffer.asUint8List(), sampleRate: rate),
      );

    final wav = readWav(file);

    expect(wav.sampleRate, rate);
    expect(wav.samples.length, rate);
    expect(
      heardNotes(
        wav.samples,
        sampleRate: wav.sampleRate,
        instrument: Instrument.bass,
      ),
      [midiOfName('A1')],
    );
  });

  final folder = Directory(ClipRecorder.folder);
  final clips = folder.existsSync()
      ? [
          for (final file in folder.listSync().whereType<File>())
            if (file.path.endsWith('.wav')) file,
        ]
      : <File>[];

  test(
    'a real instrument is heard no worse than it has ever been',
    skip: clips.isEmpty ? 'No clips recorded yet.' : null,
    () {
      final best = _bestFile.existsSync()
          ? (jsonDecode(_bestFile.readAsStringSync()) as Map<String, dynamic>)
          : <String, dynamic>{};
      final worse = <String>[];

      for (final clip in clips) {
        final name = clip.uri.pathSegments.last.replaceAll('.wav', '');
        final answer = File(clip.path.replaceAll('.wav', '.txt'))
            .readAsLinesSync()
            .where((line) => !line.startsWith('#'))
            .join(' ');
        final played = [
          for (final note in answer.split(' '))
            if (note.isNotEmpty) midiOfName(note),
        ];
        final wav = readWav(clip);
        final score = clipScore(
          played: played,
          heard: heardNotes(
            wav.samples,
            sampleRate: wav.sampleRate,
            // A clip is named for its instrument: bass-1700000000.
            instrument: Instrument.values.byName(name.split('-').first),
          ),
        );
        final mistakes = score.missing + score.extra;
        final line =
            '$name: ${played.length} played, ${score.missing} missed, '
            '${score.extra} extra';
        printOnFailure(line);

        final before = best[name] as int?;
        if (before != null && mistakes > before) {
          worse.add('$line (best was $before mistakes)');
        } else {
          best[name] = mistakes;
        }
      }

      expect(worse, isEmpty);
      // Only a run with nothing worse moves the bar, so a bad change
      // cannot quietly become the new best.
      _bestFile.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(best)}\n',
      );
    },
  );
}
