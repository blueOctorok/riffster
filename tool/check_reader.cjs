// Runs the file reader outside the app and checks what it sends.
//
//   node tool/check_reader.cjs
//
// The app loads reader.js inside a hidden browser page, where a Dart test
// cannot reach it. alphaTab also runs under Node, so this script gives the
// reader a small score written in alphaTab's own text format and looks at
// the numbers that come out. No Guitar Pro file is needed.

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const readerFolder = path.join(__dirname, "..", "assets", "gp_reader");
globalThis.alphaTab = require(path.join(readerFolder, "alphaTab.min.js"));
// reader.js is a plain browser script with no exports. Running its text
// here and handing back the one function is the same thing the page does.
const riffsterReadScore = new Function(
  `${fs.readFileSync(path.join(readerFolder, "reader.js"), "utf8")}
  return riffsterReadScore;`,
)();

// String.raw keeps the backslashes alphaTex commands start with.
const tex = String.raw`
\title "Reader check"
\tempo 100
\track "Lead"
\tuning (E4 B3 G3 D3 A2 E2)
3.3.4 5.3.4 (0.1 0.2).4 r.4 | 3.3.2 -.3.2 |
\track "Bass"
\tuning (G2 D2 A1 E1)
0.4.4 3.4.4 0.3.4 2.3.4 | r.1 |
\track "Five"
\tuning (G2 D2 A1 E1 B0)
0.5.4 3.4.4 0.3.4 2.1.4 | r.1 |
\track "Seven"
\tuning (E4 B3 G3 D3 A2 E2 B1)
0.7.4 3.6.4 0.3.4 2.1.4 | r.1 |
\track "Keys"
\tuning (piano)
C4.4 D4.4 E4.2 | E4{t}.2 r.2 |
`;

const importer = new alphaTab.importer.AlphaTexImporter();
importer.initFromString(tex, new alphaTab.Settings());
const read = riffsterReadScore(importer.readScore());
if (process.argv.includes("--print")) console.log(JSON.stringify(read, null, 1));

const part = (name) => read.tracks.find((track) => track.name === name);
const pitches = (name) => part(name).notes.map((note) => note.midi);

assert.equal(read.tempoBpm, 100);
assert.deepEqual(read.bars, [
  { startMs: 0, endMs: 2400, beats: 4 },
  { startMs: 2400, endMs: 4800, beats: 4 },
]);

// Tunings run from the top line of the staff down, like the note strings.
assert.deepEqual(part("Lead").tuning, [64, 59, 55, 50, 45, 40]);
assert.deepEqual(part("Bass").tuning, [43, 38, 33, 28]);
assert.deepEqual(part("Five").tuning, [43, 38, 33, 28, 23]);
assert.deepEqual(part("Seven").tuning, [64, 59, 55, 50, 45, 40, 35]);
// A keyboard has no strings.
assert.deepEqual(part("Keys").tuning, []);

assert.deepEqual(pitches("Bass"), [28, 31, 33, 35]);
assert.deepEqual(
  part("Bass").notes.map((note) => [note.string, note.fret]),
  [[4, 0], [4, 3], [3, 0], [3, 2]],
);

// The low B of a five-string and of a seven-string used to be dropped,
// because the staff has nowhere to draw it. Its pitch is still wanted.
assert.deepEqual(pitches("Five"), [23, 31, 33, 45]);
assert.deepEqual(pitches("Seven"), [35, 43, 55, 66]);

// A part with no strings sends pitch and time, and string 0.
assert.deepEqual(pitches("Keys"), [60, 62, 64]);
assert.ok(part("Keys").notes.every((note) => note.string === 0));

// A tie is one longer note, on a string or off one.
assert.equal(part("Lead").notes.at(-1).durationMs, 2400);
assert.equal(part("Keys").notes.at(-1).durationMs, 2400);
assert.equal(part("Keys").notes.length, 3);

console.log("The reader sends what the app expects.");
