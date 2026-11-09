# Changes

## 2026-11-09 — The chord book is grouped

Chords still opens a grid of cards you drag onto the lane. The book is no longer one pile. Open, Barre, Sevenths, Sus, Power, and More are chips, and the grid shows that group. Barre has a second row for the shape (E or A) and a third for the quality (major, minor, 7, m7, maj7), twelve roots at a time. Sevenths split into 7, m7, and maj7. Power splits into the low E string and the A string. A barre that shares a name with an open chord keeps the shape in the label, so the lane can show Bm and Bm E-shape. Every card was checked against the chord's notes before it shipped. There is still no Next button.

## 2026-11-09 — Chord cards instead of fret numbers

Chords opens every grip at once, as a grid of charts. There is no Next button and no shelf that hides the rest. Low E is the left string. O is an open string, X is muted, and the number in the dot is the finger, in the same colors as the staff. A shape that fits in four frets is drawn from the nut. A higher shape, such as the barre Bm, starts at its lowest fret so the dots stay large. The note letters sit under the strings. Open cards are warm paper, the barre card is blue, and the sevenths are green. Drag a card onto the lane under the grid. The wood picker hides on this screen.

## 2026-11-09 — Build a chord lane on the practice screen

Build sits next to the chord course. Open, Barre, and Sevenths are shelves of the same chord book. A block shows the name and the fret numbers from the low E. Dropping it on the lane or the staff adds that grip as ordinary notes. Dropping it on a chord already in the lane puts it in front. Dragging a name moves that chord. Dragging the gold edge changes how long it rings, and the next chord starts when this one ends. Loop plays the lane again. A finger that is already on the fret the next shape needs is marked "stays". A clickable neck, and marks for a bend or a vibrato, are not in this slice.

## 2026-11-06 — A volume slider for the monitor

The practice screen has a gold slider beside the level bar. Full is the four-times speaker copy. Dragging it down scales only what the speakers play. Pitch and the level bar stay on the raw cable. The choice lasts for this window. Speaker on and off is still the separate button.

## 2026-11-06 — The monitor is four times louder

Exclusive mode copies the cable straight to the speakers and skips the Windows recording level, so a strum that filled the green bar was only about a fifth of full scale on the way out. The speaker copy is now multiplied by four. Anything past full scale is flattened, so a hard hit does not wrap into fuzz. Pitch and the level bar still hear the raw cable.

## 2026-11-06 — Exclusive mode for the guitar cable

The cable is opened so Windows steps out of the way, and each short buffer is copied straight to the speakers on an audio thread. Dart hears a copy only for the pitch and the level bar, so scoring is not part of the delay. The speakers are taken over too when they accept it, which quiets other apps while the cable is the input. Speaker off writes silence and keeps the cable. If Windows refuses exclusive mode, the app falls back to the shared recorder. The status line says "exclusive" when the short path is the one open. The first build took the cable and scored the note, then never gave the speakers a second buffer, so the guitar was silent. Exclusive playback now submits the next whole buffer when the device asks, instead of waiting for the previous one to look empty. A 3 ms buffer then crackled, because the speaker asked before the cable had a full buffer. The buffer is 10 ms, and a buffer is submitted only when the speaker asks for one. That still stayed silent: the cable's signal and the speaker's request were ready together, and the wait always served the cable, so the speaker never got its turn. The speaker is now served first, and it is started with guitar already in the first buffer. The scoring guess on that path is 20 ms when the speakers were taken too, and 35 ms when playback stayed shared. The shared path stays at 50 ms. Both guesses still need a real strum.

## 2026-11-06 — Shorter delay from the string to the speaker

The gap was a queue. Windows' recorder holds a chunk of the guitar before it hands the bytes over, and the speaker holds another chunk so a gap does not click. The published recorder does not offer a short capture buffer, so `third_party/record_windows` is that package with one change: Media Foundation is asked for low latency, which keeps about one device period instead of a long pile. The speaker mix is 256 frames (about 5 ms at 48 kHz), it waits 5 ms before the first sound, and a pile past about 40 ms is dropped. A hardware jack or the Gibson app can still be shorter, because those talk to the device more directly. The 50 ms scoring guess is unchanged until a real strum shows whether notes land early. After this change the delay was smaller and still audible. The cable was plugged into a USB dock on the laptop. A dock adds a hub hop of a couple of milliseconds, not the remaining gap. The rest is still the shared Windows path: one device period in, the trip through the app, and one period back out the speakers. A port on the laptop itself is the check. Going shorter than that means taking the cable over in exclusive mode, which is not built yet.

## 2026-11-06 — The Rocksmith cable is a guitar input

The Real Tone cable shows up in Windows as Rocksmith USB Guitar Adapter. The app listens to that recording device and plays it out the PC speakers, because the cable has no headphone jack. A cable plugged in after the window opens is noticed within a couple of seconds. The first device list is taken at startup and does not update on its own. A room mic is still never played back. An iRig input is used only when that cable is absent. Rocksmith's song files stay closed.

## 2026-11-06 — Songwriting, written down only

Decided, not built. Riffster stays a practice app and also becomes a songwriter. Generator mode asks for a feel, chords that must appear, and beginner, intermediate, or advanced. Claude returns an original note list, not a copy of the named song. Builder mode is local: drag chords into order, set the time signature, and drop single notes or a riff. Both practice on the same staff, with a hit streak in the local score file. Neither is built ahead of a fair iRig score.

## 2026-11-04 — The iRig speaker is not the guitar input

Windows can start Speakers (iRig USB) while the recording side of that same device stays off. The app only listens to recording devices, so it used to say the iRig was missing. It now says the speaker is connected and the guitar input never started. That input needs IK's iRig USB ASIO driver for Windows. The same iRig works on an iPad, so the hardware is fine. The serial for registration was only on the card in the box, not on the device and not in the USB id. IK support gives that driver without the card. The firmware updater is a different tool and does not see this device. The generic USB audio driver on this PC did not start the guitar input.

## 2026-11-04 — The PC mic is not played back

Playing the laptop microphone out the speakers made it hear itself. The playback buffer was allowed to fill, so the voice returned later and later, then the loop howled. The speaker now opens only when the input is an iRig. If that guitar buffer starts to pile up, the old audio is dropped and the newest chunk is kept.

## 2026-11-04 — The guitar comes out the speaker, and misses show on the staff

The iRig jack plays audio the computer sends to that device. Listening alone never moved the speaker. The same guitar bytes are now played back there, with voice effects still off. A level bar jumps when a string sends a signal. If Windows has no live device named iRig, the line says the iRig is not connected and lists the inputs it did find. Look again rescans after the cable is plugged in. On this machine the remembered iRig USB was present in Windows but not connected.

A pluck still judges the nearest written notes. The result is drawn on the note: a green ring is a hit, gold is early or late, and a rose ring with a slash is a miss. Silence has no pitch, so a note that passes the playhead by more than 250 ms with no pluck is marked missed by the clock. A late right note can still replace that miss. Speaker can be turned off if the iRig is already monitoring and the two copies slap.

## 2026-11-04 — The app listens to the guitar

The input stream is 16-bit mono. Echo cancel, noise suppression, and auto gain stay off, because those are voice effects and they bend a fretted note. A window of samples is turned into a MIDI note by finding the first repeating period, so a loud octave overtone does not replace the note that was fretted. The pitch is shown under the finger colors. While Play is running, that pitch is scored against the nearest written notes. The buffer arrives late, so the score looks 50 ms earlier than the playhead. That guess needs a real guitar before it is trusted. The iRig headphone jack is still how the player hears themselves.

## 2026-11-04 — Scoring rules, before the iRig

The playhead can judge one sound. A single note hits when the MIDI pitch matches and the attack is within 80 ms. The same pitch on another string counts, because the mic cannot see the fret. Early and late stay inside 250 ms. Farther away is a miss. Two or more notes at the same moment are a chord, and only the strum time is checked. No audio input is wired, so the practice screen does not show a score yet.

## 2026-11-04 — Paid song generator, written down only

Decided, not built. A player will pick parameters and describe a feel ("now make a song that sounds like this song"). Claude returns an original note list, and the staff plays it. The named song is inspiration, not a chart to copy. `riffster.xyz` will hold the Anthropic key in a server-only setting. The Windows app calls the site. The key does not go in the page or the `.exe`. Parameter list, price, and accounts wait. This stays behind the iRig scorer.

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
- An open D is index on the G string, middle on the high e, and ring on the B string. The two 2nd-fret notes no longer share the index finger. A chord like the repeated 3-2-3 shape gives the low E the middle finger and the high e the ring finger, because one finger cannot hold both. A wide lowest fret is still an index barre.
- A chord book now supplies those fingers, and the name, when a stack matches a known grip. The written 3-2-3 shape is named G even though the tab left the open strings out. A grip with only two fretted notes, such as Em, still has to have its open strings written down, so a fragment is not labeled as the whole chord. A finger stored in the file still wins.
- Chords on the practice screen walks that same book, one grip at a time, starting at Em. Song returns to the loaded file at the spot you left. The last step is an original change, G D Em C. Nothing in the course is someone else's song. Hearing a strum still waits for the iRig.
- The staff can look like a neck. Ebony is the dark board it already had. Rosewood is a red-brown board with cream strings. Maple is blonde, so the strings, open notes, and string names flip to dark ink. The finger colors stay the same on every neck. The choice lasts until the window closes.
- A slider under the staff moves to any moment in the song. Play starts from wherever the slider is. A named chord is drawn as a gold chip so it reads as the chord, not as another fret. An index-finger barre is a blue outline around that finger and the notes inside its reach. The other fingers in the chord keep their own colors.
- Unnamed Guitar Pro parts are no longer listed as Track 1, Track 2, and so on. A name written in the file is kept. A part called Track 1 is described from its notes: single notes, chords, two notes at a time, or a harmony (the same timing as another part, different pitches). An unnamed part that copies another part exactly is left out. The other parts stay, because any of them might be the one the player wants.
- Files that leave fingers blank now get a hand position. A chord still counts one finger per fret from the lowest, and the same fret is shared only as a barre. A melody packs the frets that are actually played, so an empty fret is a small reach for the next finger instead of pushing the pinky onto the note above the middle finger. A fast hop across strings on one fret gives each string its own finger. A stored finger is kept. A shape wider than the hand stays hollow. Notes that sound together are named only when their pitches match a chord exactly, including a slash when the lowest note is not the root. Anything else stays unlabeled. The warm-up is not run through this.
