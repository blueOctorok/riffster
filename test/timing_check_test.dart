import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/music/timing_check.dart';

final _clicks = [
  for (var beat = 0; beat < timingCheckClicks; beat++) beat * timingCheckBeatMs,
];

void main() {
  test('notes that all arrive 30 ms after the click measure 30 ms', () {
    final notes = [for (final click in _clicks) click + 30];
    expect(measuredDelayMs(clicksMs: _clicks, notesMs: notes), 30);
  });

  test('one fumbled note does not move the answer', () {
    final notes = [for (final click in _clicks) click + 30];
    notes[3] += 200;
    expect(measuredDelayMs(clicksMs: _clicks, notesMs: notes), 30);
  });

  test('a missed click or two is fine, and three notes are too few', () {
    final notes = [for (final click in _clicks.skip(2)) click + 42];
    expect(measuredDelayMs(clicksMs: _clicks, notesMs: notes), 42);
    expect(
      measuredDelayMs(clicksMs: _clicks, notesMs: notes.take(3).toList()),
      isNull,
    );
  });

  test('notes scattered around the click give no answer', () {
    const offsets = [-120.0, 90, -40, 150, 10, -90, 130, -150];
    final notes = [
      for (final (index, click) in _clicks.indexed) click + offsets[index],
    ];
    expect(measuredDelayMs(clicksMs: _clicks, notesMs: notes), isNull);
  });

  test('a player who leans ahead of the click measures below zero', () {
    final notes = [for (final click in _clicks) click - 15];
    expect(measuredDelayMs(clicksMs: _clicks, notesMs: notes), -15);
  });
}
