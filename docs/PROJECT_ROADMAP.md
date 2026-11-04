# Riffster roadmap

A new chat can start here. The product decisions below are settled.

## What it is

A calm practice tool. A guitar tab scrolls sideways into a playhead, the way the Gibson app does. The player imports a file they already have. The app scores pitch and timing from a USB-C iRig. There is no song catalog, no account, and no server.

The name is Riffster. `riffster.xyz` is registered at Namecheap (bought 2026-11-03). That site is a small Next.js page on Vercel with a download button. It is not the Flutter app. `riffster.com` is taken.

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

## Done

- Flutter app scaffold for Windows (`flutter create --platforms windows`).
- Note list model: time, string, fret, duration, MIDI pitch, and fretting finger.
- Sideways six-string scroll with a fixed playhead, finger-colored dots, and a short original warm-up phrase.
- Web preview added so the screen can be opened in Chrome before Visual Studio is installed. The product target is still the Windows app.
- Visual Studio Build Tools 2022 with the C++ workload. `flutter run -d windows` opens the warm-up as a desktop window.
- Guitar Pro import. Open reads a `.gp` file with alphaTab in a hidden web view and scrolls that part. A file with more than one guitar part asks which one to play.
- A slider seeks anywhere in the song. Named chords are gold chips. An index barre is outlined in blue around the barre and the notes inside it.
- Missing fingers are filled from the hand. A stack that matches the chord book uses that grip's name and fingers, so a tab that only wrote the fretted notes of an open G still reads as G. A stored finger wins. Anything the book does not know is guessed: a melody packs the frets that are played, a fast hop on one fret uses a new finger per string, and a shape wider than the hand stays hollow. A chord name from pitches appears only when they match a shape exactly.

The checklists are in `TODOS.md`. Work top to bottom.

## Pickup notes

- Flutter SDK: `C:\Users\blaha\flutter` (stable 3.47.9). `C:\Users\blaha\flutter\bin` is on the user PATH. A terminal that was already open may still need a restart before `flutter` is found.
- Windows Developer Mode is on. Flutter needs it to link plugins. The Guitar Pro reader was the first one.
- String 1 is the top line of the tab (high E). String 6 is low E.
- The scroll maps time to pixels: `x = playhead + (noteTime - now) * 120`.
- Chord names and position fingers are local arithmetic on the imported note list. The chord book in `lib/music/chord_book.dart` is the shared list: import uses it, and the chord practice screen (not built yet) will show the same grips. The warm-up is not passed through that step. Claude is not wired in.
- The fingering trust check is the user's Hotel California file at `C:\Users\blaha\Documents\guitar_tabs\the-eagles-hotel_california.gp3`. A wrong finger color on that song is a failed build. Do not copy the file into the repo. The passage around frets 7, 9, 10, and 11 was checked on 2026-11-03: 9 is the middle finger, 10 is the ring, 11 is the pinky, and a fast hop on fret 7 changes finger per string. The file's six guitar parts are unnamed. The picker describes them from the notes instead of dropping a real part.
- Proven / Provven / `resume-wallet` is a different project. Do not mix it into this folder.
