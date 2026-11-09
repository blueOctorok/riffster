# Riffster roadmap

A new chat can start here. The product decisions below are settled.

## What it is

A calm practice tool that is also a songwriter. A guitar tab scrolls sideways into a playhead, the way the Gibson app does. The player imports a file they already have, asks for an original song, or builds one by hand. The app scores pitch and timing from a USB-C iRig. There is no song catalog. Practice scores stay in a file on the machine.

The name is Riffster. `riffster.xyz` is registered at Namecheap (bought 2026-11-03). That site is a small Next.js page on Vercel with a download button. It is not the Flutter app. `riffster.com` is taken. The same site is also the door for the paid song generator: the Anthropic key lives in a server-only setting there, and the Windows app calls the site. The key never ships in the page or in the `.exe`.

## Stack

- Flutter, Windows first. Android and iPhone come from this same project later.
- alphaTab (JavaScript, inside a hidden web view) will turn a Guitar Pro file into a note list. The screen never parses `.gp` itself.
- A Flutter audio plugin will listen to the iRig. A short pitch check compares that frequency to the note at the playhead.
- Songs and scores stay in files on the machine.

## Settled, do not reopen unless asked

- No blockchain, token, or NFT.
- No CustomsForge connection. A local Rocksmith package could be a later importer. It is not the first format.
- No Apple Music stem splitter. A backing track from a file the player owns can wait.
- Lava Studio is a question for Lava, not a build target. Their USB-C port talks to a computer. It does not host an iRig.
- The fun layer, after scoring feels fair: the player's guitar is heard in the mix only when the note is right.
- Original practice we write, such as the chord course, ships in the app. Copyrighted songs do not.
- The generator still waits behind a fair score. It is paid and online. The player says what it should sound like, names chords that must appear, and picks beginner, intermediate, or advanced. Claude returns an original note list in that feel. The staff, the chord book, and the finger colors play it like any imported song. Naming a song is inspiration. The result must not be that song's melody, lyrics, or signature part. Price and accounts wait until we design them. The Windows app calls `riffster.xyz`. The key stays on that server.
- Builder mode is local and free of Claude. Build on the practice screen drags grips from the same chord book onto a lane. Open, barre, and sevenths are all on screen together, drawn as chord charts with finger numbers and open or muted marks. There is no Next button through the grips. Drop adds a chord, drop on a chord puts the new one in front, dragging the name moves it, and dragging the edge sets how long it rings. Loop repeats the lane. A finger that stays on the same fret is marked. The lane is an ordinary note list, so the staff and the scorer read it like an imported song. A clickable neck and bend or vibrato marks are later. The hit streak and a saved name are later too. No account.

## Done

- Flutter app scaffold for Windows (`flutter create --platforms windows`).
- Note list model: time, string, fret, duration, MIDI pitch, and fretting finger.
- Sideways six-string scroll with a fixed playhead, finger-colored dots, and a short original warm-up phrase.
- Web preview added so the screen can be opened in Chrome before Visual Studio is installed. The product target is still the Windows app.
- Visual Studio Build Tools 2022 with the C++ workload. `flutter run -d windows` opens the warm-up as a desktop window.
- Guitar Pro import. Open reads a `.gp` file with alphaTab in a hidden web view and scrolls that part. A file with more than one guitar part asks which one to play.
- A slider seeks anywhere in the song. Named chords are gold chips. An index barre is outlined in blue around the barre and the notes inside it.
- Missing fingers are filled from the hand. A stack that matches the chord book uses that grip's name and fingers, so a tab that only wrote the fretted notes of an open G still reads as G. A stored finger wins. Anything the book does not know is guessed: a melody packs the frets that are played, a fast hop on one fret uses a new finger per string, and a shape wider than the hand stays hollow. A chord name from pitches appears only when they match a shape exactly.
- Chord practice. Chords opens the book one grip at a time, easiest first, and ends on an original G D Em C change. Song returns to whatever was loaded. The fingers are the book, not a second guess.
- The staff wears a neck: ebony (the original dark board), rosewood, or maple. A light board uses dark strings. Finger colors do not change with the wood.

The checklists are in `TODOS.md`. Work top to bottom.

## Pickup notes

- Flutter SDK: `C:\Users\blaha\flutter` (stable 3.47.9). `C:\Users\blaha\flutter\bin` is on the user PATH. A terminal that was already open may still need a restart before `flutter` is found.
- Windows Developer Mode is on. Flutter needs it to link plugins. The Guitar Pro reader was the first one.
- String 1 is the top line of the tab (high E). String 6 is low E.
- The scroll maps time to pixels: `x = playhead + (noteTime - now) * 120`.
- Chord names and position fingers are local arithmetic on the imported note list. The chord book in `lib/music/chord_book.dart` is the shared list: import uses it, and Chords on the practice screen shows the same grips. The warm-up is not passed through that step. Claude is not wired in. The paid generator on `riffster.xyz` is the only planned use of it.
- Scoring rules live in `lib/music/score_note.dart`. A single note matches MIDI pitch, so the string does not matter. A chord matches the strum time only. On time is 80 ms. Past 250 ms is a miss. `lib/audio/guitar_ear.dart` listens on the input. It prefers the Rocksmith Real Tone cable, listed as Rocksmith USB Guitar Adapter, and plays that guitar out the PC speakers. An iRig recording device is the fallback and still uses the iRig jack. A PC microphone is never sent to a speaker. Rocksmith's song files stay closed. The iRig's own guitar input still needs IK's driver. The serial was only on the card in the box. A guitar buffer that starts to pile up is dropped so the sound cannot turn into a growing echo. The pitch and a level bar sit under the finger colors. Play draws a ring on each note: green hit, gold early or late, rose slash for a miss. A note that scrolls past with no pluck is missed by the clock, because silence has no pitch. Input latency is guessed at 50 ms until a real guitar checks it. The Windows recorder in `third_party/record_windows` asks Media Foundation for a short capture buffer. The speaker mix is about 5 ms, it waits 5 ms before the first sound, and a pile past about 40 ms is dropped. A small delay remained on the shared path. The dock was only a couple of milliseconds. Exclusive mode is in `windows/runner/guitar_monitor.cpp`: the cable buffer is copied to the speakers on an audio thread, and Dart only gets a copy for pitch. Other apps lose the cable, and the speakers too when exclusive playback opens. The status line says exclusive. The speaker copy is multiplied by up to four, because exclusive mode skips the Windows recording boost and the raw cable is quiet. A volume slider on the practice screen sets that, and full is the four-times level. Anything past full scale is flattened. Pitch still hears the raw cable. The slider lasts for the window. The speaker buffer is about 10 ms and is submitted when the device asks for the next one. The speaker request is served ahead of the cable, or the cable's signal keeps the turn and the speakers stay silent. A shorter buffer crackled. If Windows refuses, the shared recorder is the fallback. Scoring subtracts 20 ms on the exclusive path and 50 ms on the shared path. Both are still guesses.
- The fingering trust check is the user's Hotel California file at `C:\Users\blaha\Documents\guitar_tabs\the-eagles-hotel_california.gp3`. A wrong finger color on that song is a failed build. Do not copy the file into the repo. The passage around frets 7, 9, 10, and 11 was checked on 2026-11-03: 9 is the middle finger, 10 is the ring, 11 is the pinky, and a fast hop on fret 7 changes finger per string. The file's six guitar parts are unnamed. The picker describes them from the notes instead of dropping a real part.
- Proven / Provven / `resume-wallet` is a different project. Do not mix it into this folder.
