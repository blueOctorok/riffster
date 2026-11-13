// Turns an alphaTab score into the note list the Flutter staff already draws.
// This file never draws notation. alphaTab is only the file reader.

const quarterTicks = 960;

function riffsterRead(base64File) {
  try {
    const binary = atob(base64File);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    const settings = new alphaTab.Settings();
    const score = alphaTab.importer.ScoreLoader.loadScoreFromBytes(bytes, settings);
    return riffsterReadScore(score);
  } catch (error) {
    const message = error && error.message ? error.message : String(error);
    return { error: message };
  }
}

function riffsterReadScore(score) {
  const firstTempo = score.masterBars[0] && score.masterBars[0].tempoAutomations[0];
  const tempoBpm = Math.round(
    firstTempo && firstTempo.value > 0 ? firstTempo.value : score.tempo || 120,
  );

  const tracks = [];
  for (const track of score.tracks) {
    if (track.isPercussion) continue;
    const notes = notesForTrack(score, track);
    if (notes.length === 0) continue;
    tracks.push({
      name: track.name || "Guitar",
      // The pitch of each open string, from the top line of the staff
      // down. Its length is the string count, and its lowest pitch tells
      // a bass from a ukulele. Empty for a voice or a keyboard.
      tuning: tuningOf(track.staves[0]),
      notes,
    });
  }

  return {
    title: score.title || "",
    tempoBpm,
    bars: barsOf(score),
    tracks,
  };
}

function tuningOf(staff) {
  return staff && staff.tuning ? Array.from(staff.tuning) : [];
}

// Where each bar starts and ends in milliseconds, and how many beats it
// holds. The stage draws its bar lines from this, and a loop snaps to it.
function barsOf(score) {
  return score.masterBars.map((bar) => ({
    startMs: millisUntil(score, bar.start),
    endMs: millisUntil(score, bar.start + barSpanTicks(bar)),
    beats: bar.timeSignatureNumerator || 4,
  }));
}

function notesForTrack(score, track) {
  const staff = track.staves[0];
  if (!staff) return [];

  // alphaTab numbers 1 as the lowest string. The staff numbers 1 as the
  // top line, which is the highest string. A 6-string guitar flips 1 <-> 6.
  const stringCount = tuningOf(staff).length;
  const pending = [];
  // The entry each written note became, so a tie can find the note it
  // lengthens. A tie onto a tie reaches the same entry.
  const sounding = new Map();

  for (const bar of staff.bars) {
    for (const voice of bar.voices) {
      for (const beat of voice.beats) {
        if (beat.isRest) continue;
        for (const note of beat.notes) {
          if (note.isTieDestination) {
            // A tie is the same note still ringing, not a second pluck.
            const held = sounding.get(note.tieOrigin);
            if (held) {
              held.durationTicks += beat.playbackDuration;
              sounding.set(note, held);
            }
            continue;
          }
          // Every note is sent, whatever it was written for. A voice or
          // a keyboard has no strings, so its notes sit on string 0. The
          // app only draws a part whose strings it has a staff for. The
          // rest are wanted for their pitch and their time.
          const onString = note.isStringed;
          const entry = {
            tick: beat.absolutePlaybackStart,
            durationTicks: beat.playbackDuration,
            string: onString ? stringCount - note.string + 1 : 0,
            fret: onString ? Math.round(note.fret) : 0,
            midi: Math.round(note.realValue),
            finger: onString ? frettingFinger(note) : null,
          };
          sounding.set(note, entry);
          pending.push(entry);
        }
      }
    }
  }

  pending.sort((a, b) => a.tick - b.tick || a.string - b.string);

  return pending.map((note) => {
    const timeMs = millisUntil(score, note.tick);
    const endMs = millisUntil(score, note.tick + note.durationTicks);
    return {
      timeMs,
      durationMs: Math.max(1, endMs - timeMs),
      string: note.string,
      fret: note.fret,
      midi: note.midi,
      finger: note.finger,
    };
  });
}

// Index 1, middle 2, ring 3, pinky 4. Thumb and "unknown" stay hollow.
// An open string is hollow even if the file names a finger.
function frettingFinger(note) {
  if (note.fret === 0 || !note.isFingering) return null;
  const finger = note.leftHandFinger;
  if (finger >= 1 && finger <= 4) return finger;
  return null;
}

// alphaTab stores time as MIDI ticks (960 ticks is one quarter note), not
// milliseconds. Walk the tempo marks and convert. One bpm number is not
// enough: a song can change speed at a bar line.
function millisUntil(score, tick) {
  let millis = 0;
  let bpm = score.tempo > 0 ? score.tempo : 120;
  let covered = 0;

  for (const bar of score.masterBars) {
    const barStart = bar.start;
    const barEnd = barStart + barSpanTicks(bar);
    if (tick <= barStart) break;

    const automations = bar.tempoAutomations || [];
    const points = automations.length === 0
      ? [{ value: bpm, ratioPosition: 0 }]
      : automations.slice().sort((a, b) => a.ratioPosition - b.ratioPosition);
    const span = barEnd - barStart;

    for (let i = 0; i < points.length; i++) {
      if (points[i].value > 0) bpm = points[i].value;
      const from = barStart + points[i].ratioPosition * span;
      const to = i + 1 < points.length
        ? barStart + points[i + 1].ratioPosition * span
        : barEnd;
      if (tick <= from) return Math.round(millis);

      const segmentEnd = Math.min(tick, to);
      const segmentStart = Math.max(covered, from);
      if (segmentEnd > segmentStart) {
        millis += ((segmentEnd - segmentStart) * 60000) / (bpm * quarterTicks);
        covered = segmentEnd;
      }
      if (tick <= to) return Math.round(millis);
    }
  }

  if (tick > covered) {
    millis += ((tick - covered) * 60000) / (bpm * quarterTicks);
  }
  return Math.round(millis);
}

function barSpanTicks(bar) {
  if (bar.nextMasterBar) return bar.nextMasterBar.start - bar.start;
  const numerator = bar.timeSignatureNumerator || 4;
  const denominator = bar.timeSignatureDenominator || 4;
  return numerator * ((quarterTicks * 4) / denominator);
}
