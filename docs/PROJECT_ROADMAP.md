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

The checklists are in `TODOS.md`. Work top to bottom.

## Pickup notes

- Flutter SDK: `C:\Users\blaha\flutter` (stable 3.47.9). `C:\Users\blaha\flutter\bin` is on the user PATH. A terminal that was already open may still need a restart before `flutter` is found.
- String 1 is the top line of the tab (high E). String 6 is low E.
- The scroll maps time to pixels: `x = playhead + (noteTime - now) * 120`.
- Proven / Provven / `resume-wallet` is a different project. Do not mix it into this folder.
