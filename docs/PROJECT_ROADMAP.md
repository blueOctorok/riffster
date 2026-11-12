# Riffster roadmap

A new chat can start here. The product decisions below are settled.

## What it is

A calm practice tool that is also a songwriter, built for a 4-string bass first and then guitar. A tab scrolls sideways into a playhead. The player imports a file they already have, asks for an original riff, or builds one by hand. The app scores pitch and timing from a cable. There is no song catalog. Practice scores stay in a file on the machine.

The aim, in the user's words: the most fun bass app you can play, very accurate, light, and not full of things people do not want to do. Playing a song's melody on bass is what should set it apart. The full plan is in `c:\Users\blaha\.cursor\plans\riffster_bass_first_8ef7d682.plan.md`.

Every feature has to clear four bars. Fun: playing within two clicks, and a hit is felt the moment it lands. Accurate: measured on a real bass, not judged by feel. Premium: depth, gloss, and motion, never at the cost of a dropped frame. Light: no account or internet for anything free, and one screen per area.

## Build order

One play area, the Stage, and four ways to put notes on it. Everything becomes the same note list.

1. The play area: look, motion, countdown, speed, loop, end-of-run card. Built. The look is waiting on approval.
2. The bass is heard: a new pluck detector with the instrument's range, tested on clips of the user's own bass, and a timing check that measures the input delay with a click.
3. The shell: a side rail (Home, Songs, Practice, Build, Create, Library), the input panel, and a tuner.
4. Songs, melody on bass, and Library, plus the originals that ship with the app.
5. Practice: scales, arpeggios, drills, Find the note, Trouble spots, and a drum groove.
6. Build for bass: a clickable neck, pattern cards, and a lane with tempo.
7. Create, on a private test key that only a debug build reads from the user's machine.
8. Paid: `riffster.xyz` holds the key, sign-in, and payment.
9. Guitar gets the same areas.

Not in the plan: 5-string, time signatures other than 4/4, hearing a file's other tracks, bend or slide scoring, phones, sharing, and turning a recording into notes.

The name is Riffster. `riffster.xyz` is registered at Namecheap (bought 2026-11-03). That site is a small Next.js page on Vercel with a download button. It is not the Flutter app. `riffster.com` is taken. The same site is also the door for the paid song generator: the Anthropic key lives in a server-only setting there, and the Windows app calls the site. The key never ships in the page or in the `.exe`.

## Stack

- Flutter, Windows first. Android and iPhone come from this same project later.
- The download page is Next.js in `riffster-site/`, App Router, TypeScript, Tailwind CSS v4. Vercel builds that folder only. The page is a landing page: headline, a drawn picture of the play area, three points, three steps, and the download. The Windows zip in its `public/` folder is committed and is not part of the Flutter app.
- alphaTab (JavaScript, inside a hidden web view) will turn a Guitar Pro file into a note list. The screen never parses `.gp` itself.
- A Flutter audio plugin will listen to the iRig. A short pitch check compares that frequency to the note at the playhead.
- Songs and scores stay in files on the machine.

## Settled, do not reopen unless asked

- No blockchain, token, or NFT.
- No CustomsForge connection. A local Rocksmith package could be a later importer. It is not the first format.
- No Apple Music stem splitter. A backing track from a file the player owns can wait.
- Lava Studio is a question for Lava, not a build target. Their USB-C port talks to a computer. It does not host an iRig.
- The fun layer, after scoring feels fair: the player's guitar is heard in the mix only when the note is right.
- Cable, iRig, and the room mic each have a switch, and only one is listened to. The mic starts off, and plugging in a guitar turns it off. Turning the mic on scores from it and does not play it through the speakers.
- Original practice we write, such as the chord course, ships in the app. Copyrighted songs do not.
- No tutorial videos, no on-screen teacher, and no music-theory lessons. Learning happens by building a song and playing it. The chord book is how a new player sees what is available: open a group and the cards are the chords they can hold. Dragging a card or a note onto the lane is writing. The song is saved in a file on the machine, so they do not have to remember it. A chord card shows the grip so the player can hold it. A song arrives four ways: import a file, build a change, ask for an original song, or ask for a suggestion inside a song already on the staff. A suggestion is another card or phrase they can drop in. It is not an explanation. Suggestions are not designed yet. They wait with the generator, behind a fair score.
- The generator still waits behind a fair score. It is paid and online. The player says what it should sound like, names chords that must appear, and picks beginner, intermediate, or advanced. Claude returns an original note list in that feel. The staff, the chord book, and the finger colors play it like any imported song. Naming a song is inspiration. The result must not be that song's melody, lyrics, or signature part. Price and accounts wait until we design them. The Windows app calls `riffster.xyz`. The key stays on that server.
- Bass comes first (decided 2026-11-11). It is the same note list and the same scorer. A bass staff has four strings, tuned an octave below the guitar's lowest four. The guitar chord book stays the guitar book and keeps working. Bass gets its own neck and pattern cards in Stage 6. It is not a copy of the guitar shapes.
- The app ships no one else's copyrighted music. What ships is material written for Riffster, plus a few very old copyright-free tunes arranged by us as bass melodies. A song the player wants is a file they bring.
- The look is a boutique instrument: a warm dark room, a wood fretboard with grain, metal strings, glass notes, and a gold playhead. Ebony, rosewood, and maple stay. Nothing copies Gibson's screens or branding.
- Adding a feature never removes one. Every control and the chord book survive each new layout.
- Builder mode is local and free of Claude. Chords on the practice screen drags grips from the same chord book onto a lane. The book is grouped: open, barre, sevenths, sus, power, and a small diminished, augmented, and add9 set. You open a group and see that group's cards. Barre, sevenths, and power have a second row of chips so one screen stays about a dozen cards. Charts show finger numbers and open or muted marks. There is no Next button through the grips. Drop adds a chord, drop on a chord puts the new one in front, dragging the name moves it, and dragging the edge sets how long it rings. Loop repeats the lane. A finger that stays on the same fret is marked. The lane is an ordinary note list, so the staff and the scorer read it like an imported song. A clickable neck and bend or vibrato marks are later. The hit streak and a saved name are later too. No account.

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
- Stage 1, the play area (2026-11-11). A first-launch chooser for bass or guitar, saved with the wood. A fretboard stage with grain, a nut, metal strings, glass notes with tails, bar lines, and a gold playhead with an on-time band. A one-bar count before the first note. Hit, early, late, and miss are animated. A feedback strip, a dock with speed and a bar loop, keyboard keys, and an end-of-run card. Details are in `CHANGES.md`.
- Stage 2, the bass is heard: built on 2026-11-11 and not yet played on a real bass. A new pluck detector for both instruments, a TIMING gauge, a click on the count-in, a timing check that measures each input's delay, and a debug-only clip recorder with a test that scores the detector against the clips. What is still unchecked is in `CHANGES.md` and `TODOS.md`.

The checklists are in `TODOS.md`. Work top to bottom.

## Pickup notes

- Flutter SDK: `C:\Users\blaha\flutter` (stable 3.47.9). `C:\Users\blaha\flutter\bin` is on the user PATH. A terminal that was already open may still need a restart before `flutter` is found.
- The download page is `riffster-site/`, live at https://riffster-site.vercel.app on Pace Projects (Vercel scope `storm-chain`, project `riffster-site`). `npm run dev` there opens it locally. The page is composed in `src/components/download-page.tsx`; `src/app/page.tsx` only imports it. The play-area picture is `src/components/stage-preview.tsx`. The zip is rebuilt from the project root with `flutter build windows --release`, then `tar -a -cf riffster-site/public/Riffster-windows.zip -C build/windows/x64/runner/Release .`. Update the date in `src/components/download-page.tsx` when the zip changes, commit, and push. Vercel builds `riffster-site` only. `riffster.xyz` is attached and Namecheap DNS points at Vercel.
- Windows Developer Mode is on. Flutter needs it to link plugins. The Guitar Pro reader was the first one.
- String 1 is the top line of the tab (high E on guitar, G on bass). The last string is the low E. `lib/models/instrument.dart` holds each instrument's string names and open pitches.
- The scroll maps time to pixels: `x = playhead + (noteTime - now) / 1000 * pixelsPerSecond`. The speed is picked per song, between 170 and 420, so tight notes do not overlap. The playhead is a fifth of the way in. All of that is in `lib/widgets/stage/stage_metrics.dart`.
- Where things live after Stage 1. `lib/music/practice_run.dart` is one sitting with a song: clock, marks, loop, speed, streak. `lib/music/song_timeline.dart` is the sorted song. `lib/widgets/stage/` draws it: `board_painter.dart` once, `stage_painter.dart` every frame. `lib/widgets/practice/` holds the dock, the feedback strip, the input bar, and the end-of-run card. `lib/screens/practice_screen.dart` owns the two runs (song and chord lane), the frame timer, and the audio input. `lib/theme/riffster_theme.dart` holds colors, type, and timings.
- Animation is arithmetic, not objects. A hit is recorded as "this note, this mark, at this time", and the painter draws from "now minus then". The frame timer runs only while something moves.
- The clock sits below zero during the count-in. A song rests at its first note minus one bar.
- Settings are a JSON file in the app's data folder, read by `lib/data/settings_store.dart`. It holds the instrument, the wood, and the delay measured on each input route.
- How a note is heard, after Stage 2. `lib/audio/guitar_ear.dart` gets raw sound in chunks and hands each one to `lib/audio/pluck_detector.dart`. The detector thins the sound (a bass to 12,000 samples a second), watches the level in 2 ms steps, and has three states: silent, identifying, holding. A jump in level starts a note and fixes its time. The pitch is read from a window that grows after the jump and is trusted once two reads agree. While a note rings, the pitch is checked every half cycle, and a clean change of pitch is a new note whose start is found by a search for the exact sample where the old wave stops fitting and the new one starts. A sound that never settles on one pitch is reported with no pitch, for strums. `lib/audio/sample_clock.dart` turns a sample number into a time. `GuitarEar.onPluck(midi, agoMs)` reports the note and how long ago it was played, and `PracticeScreen._onPluck` adds the input's delay and takes off the time since the last frame.
- The two detector thresholds, `_floor` (0.03) and `_jump` (1.8), are first guesses. They are to be tuned against clips of the user's bass in `test/clips/`, recorded with the debug-only Record clip button (debug build, started from the project folder). `flutter test test/bass_clips_test.dart` scores every clip and keeps each clip's best score in `test/clips/best.json`.
- The detector runs on the main thread, not in an isolate. That is a change from the plan, made because it measured 1 to 20 ms of work per second of sound. It still needs the user's OK and a look with the performance overlay.
- The click. In exclusive mode Dart sets a request flag and the native audio thread in `windows/runner/guitar_monitor.cpp` makes the sound, since that thread owns the speakers. On the shared path it is a WAV built in memory (`lib/audio/wav.dart`) and played by the speaker engine. `GuitarEar.click` is silent unless a guitar cable input is open. The drum groove in Stage 5 is meant to reuse this route. The click has not been heard yet.
- The timing check (`lib/music/timing_check.dart`, dialog in `lib/widgets/practice/timing_check_dialog.dart`) measures click-to-note. That number holds the speaker's delay as well as the input's, which is right for someone playing to the click. Scoring uses the measured delay when the open route has one, and the guess when it does not.
- To see the look without playing: `flutter test tool/stage_previews_test.dart` writes pictures to `build/stage_previews/`. A test that measures layout must load the real fonts (`test/support/app_fonts.dart`) and run as Windows, because the test font is wider and a test pretends to be a phone with taller buttons.
- The window's inside is about 1264 by 683. The song screen has to fit that without scrolling, and a test checks it. The chords screen is taller and scrolls, as it did before.
- A 5-string bass part still opens on the six-line staff with guitar string names. Stage 4 marks it as not supported yet.
- Chord names and position fingers are local arithmetic on the imported note list. The chord book in `lib/music/chord_book.dart` is the shared list: import uses it, and Chords on the practice screen shows the same grips. The warm-up is not passed through that step. Claude is not wired in. The paid generator on `riffster.xyz` is the only planned use of it.
- Scoring rules live in `lib/music/score_note.dart`. A single note matches MIDI pitch, so the string does not matter. A chord matches the strum time only. On time is 80 ms. Past 250 ms is a miss. `lib/audio/guitar_ear.dart` listens on the input. It prefers the Rocksmith Real Tone cable, listed as Rocksmith USB Guitar Adapter, and plays that guitar out the PC speakers. An iRig recording device is the fallback and still uses the iRig jack. A PC microphone is never sent to a speaker. Rocksmith's song files stay closed. The iRig's own guitar input still needs IK's driver. The serial was only on the card in the box. A guitar buffer that starts to pile up is dropped so the sound cannot turn into a growing echo. The pitch and a level bar sit under the finger colors. Play draws a ring on each note: green hit, gold early or late, rose slash for a miss. A note that scrolls past with no pluck is missed by the clock, because silence has no pitch. Input latency is guessed at 50 ms until a real guitar checks it. The Windows recorder in `third_party/record_windows` asks Media Foundation for a short capture buffer. The speaker mix is about 5 ms, it waits 5 ms before the first sound, and a pile past about 40 ms is dropped. A small delay remained on the shared path. The dock was only a couple of milliseconds. Exclusive mode is in `windows/runner/guitar_monitor.cpp`: the cable buffer is copied to the speakers on an audio thread, and Dart only gets a copy for pitch. Other apps lose the cable, and the speakers too when exclusive playback opens. The status line says exclusive. The speaker copy is multiplied by up to four, because exclusive mode skips the Windows recording boost and the raw cable is quiet. A volume slider on the practice screen sets that, and full is the four-times level. Anything past full scale is flattened. Pitch still hears the raw cable. The slider lasts for the window. The speaker buffer is about 10 ms and is submitted when the device asks for the next one. The speaker request is served ahead of the cable, or the cable's signal keeps the turn and the speakers stay silent. A shorter buffer crackled. If Windows refuses, the shared recorder is the fallback. Scoring subtracts 20 ms on the exclusive path and 50 ms on the shared path. Both are still guesses.
- The fingering trust check is the user's Hotel California file at `C:\Users\blaha\Documents\guitar_tabs\the-eagles-hotel_california.gp3`. A wrong finger color on that song is a failed build. Do not copy the file into the repo. The passage around frets 7, 9, 10, and 11 was checked on 2026-11-03: 9 is the middle finger, 10 is the ring, 11 is the pinky, and a fast hop on fret 7 changes finger per string. The file's six guitar parts are unnamed. The picker describes them from the notes instead of dropping a real part.
- Proven / Provven / `resume-wallet` is a different project. Do not mix it into this folder.
