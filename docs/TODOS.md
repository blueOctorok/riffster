# Riffster end to end

Check these off in order. The product decisions live in `PROJECT_ROADMAP.md`. Do not pull in Proven or `resume-wallet`.

## Done

- [x] Flutter Windows app scaffold.
- [x] Note list: time, string, fret, duration, MIDI pitch, fretting finger.
- [x] Sideways staff with a fixed height, playhead, and the warm-up phrase.
- [x] Finger colors: index blue, middle green, ring gold, pinky rose. Open strings stay hollow.
- [x] Chrome preview so the screen can be seen before Visual Studio is installed.

## 1. Run it as a Windows app

- [ ] Add `C:\Users\blaha\flutter\bin` to PATH.
- [ ] Install Visual Studio with the Desktop development with C++ workload.
- [ ] `flutter run -d windows` opens the warm-up on the desktop.

## 2. Import a Guitar Pro file

- [ ] A hidden web view runs alphaTab only long enough to read the file.
- [ ] The file becomes a `TabSong`: time, string, fret, duration, MIDI pitch.
- [ ] If the file names a finger, use it. If it does not, leave the dot hollow. Do not guess the finger from the fret.
- [ ] The player picks which track is theirs when the file has more than one guitar part.
- [ ] Tempo comes from the file.
- [ ] The practice screen scrolls that song instead of the warm-up.
- [ ] One real `.gp` file plays through from the first note to the last.

## 3. Score the iRig

- [ ] The USB-C iRig is the input. The app can also play a click or the tab's other tracks.
- [ ] Listening and playback happen at the same time. A tuner-style "recording only" session is not enough.
- [ ] Each snippet of guitar becomes one pitch.
- [ ] A single note at the playhead is hit, miss, early, or late.
- [ ] The same pitch on another string still counts. The mic cannot see the fret.
- [ ] A chord counts when the strum lands on time. Checking every string waits.

## 4. The reason to keep playing

- [ ] The guitar is quiet in the mix until the note is the right pitch and on time.
- [ ] A hit drops the real guitar into the song. A miss leaves a hole.
- [ ] This waits until single notes score fairly. A late detector makes the trick feel broken.

## 5. Remember the last good take

- [ ] A personal best for each song is saved in a file next to the app.
- [ ] No account, no database, no server.

## 6. Phones, after the PC version feels fair

- [ ] Android build from this same Flutter project, tested with the iRig.
- [ ] iPhone build. That needs a Mac or a cloud Mac, plus the $99 Apple developer account.
- [ ] Google Play, if we publish Android, is a one-time $25 fee.

## Later, only if we still want them

- [ ] Ask Lava whether an outside app can ship in the Studio Appcenter and hear the guitar jack. Not a build target until they say yes.
- [ ] A second importer for a Rocksmith package that is already on the computer. Do not connect to CustomsForge.
- [ ] A backing track made from an audio file the player already has the right to use. Not from Apple Music.

## Not in this app

- A song catalog, including Beatles or Led Zeppelin files shipped by us.
- Blockchain, a token, or an NFT.
- Lessons, trophies, or a game highway.
- Accounts and a hosted database.
