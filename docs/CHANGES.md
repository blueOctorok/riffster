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
