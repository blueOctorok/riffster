# Changes

## 2026-11-03 — Project start

Scaffolded the Windows Flutter app and the first sideways tab.

- Note list model (`TabNote`, `TabSong`) is what a Guitar Pro file will become.
- The practice screen scrolls a short original warm-up into a playhead. Checked in Chrome and with a widget test.
- The staff is a fixed short band. An earlier version stretched the six strings to the window height.
- Fretted notes are filled circles colored by finger: index blue, middle green, ring gold, pinky rose. Open strings stay hollow. The finger is stored on the note.
- A `web` folder exists so the same screen can be previewed in a browser. Shipping target is still Windows.
- Import, iRig scoring, and hearing yourself in the mix are not built yet.
- Flutter SDK installed at `C:\Users\blaha\flutter`. Visual Studio C++ is still required to launch the Windows window.
- End-to-end checklist added in `docs/TODOS.md`.
- `riffster.xyz` is registered at Namecheap. It is the future download page, not a hosted version of the practice app.
- The download page will be Next.js on Vercel. Flutter stays the desktop app.
- Added `C:\Users\blaha\flutter\bin` to the user PATH so new terminals can run `flutter`.
- Installed Visual Studio Build Tools 2022 with the C++ workload. `flutter run -d windows` builds `riffster.exe` and opens the warm-up. Android tooling is still missing, and that waits until the phone step.
- Guitar Pro import works in the Windows window. Open hands the file to alphaTab inside a hidden web view. The staff still only receives a note list. `test/fixtures/import_check.gp5` played through: two parts, 100 bpm, pinky and index colors, open strings hollow, the tie was not a second dot. Developer Mode is on so Flutter can link that plugin.
- Hotel California, Track 1, is the fingering trust check. The file stays in the user's Documents folder and is not a project fixture. The 7 / 9 / 10 / 11 passage was checked in the window after the hand stopped reserving a quiet fret.
- Files that leave fingers blank now get a hand position. A chord still counts one finger per fret from the lowest, and the same fret is shared only as a barre. A melody packs the frets that are actually played, so an empty fret is a small reach for the next finger instead of pushing the pinky onto the note above the middle finger. A fast hop across strings on one fret gives each string its own finger. A stored finger is kept. A shape wider than the hand stays hollow. Notes that sound together are named only when their pitches match a chord exactly, including a slash when the lowest note is not the root. Anything else stays unlabeled. The warm-up is not run through this.
