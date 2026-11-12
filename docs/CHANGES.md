# Changes

## 2026-11-12 — Easy, Medium, and Hard timing

A real run on the new build was 82% on time, with the misses at zero and the early notes about 88 ms ahead. That is fair, and it still felt strict. Timing now has three settings, saved with the wood and the instrument. They sit at the bottom of the practice screen, next to the woods.

- Easy is 200 ms each side of the beat. A loose pluck still counts.
- Medium is 120 ms. This is the default, and it is the ring on the playhead: a note touching the gold line at full speed is a hit.
- Hard is 70 ms. The note has to be near the middle of the ring.

The gold band around the playhead and the green part of the timing gauge both use the chosen window, so the picture and the score stay the same thing. A note past 250 ms is still a miss on every setting, because that sound belongs to a different beat. Changing the setting marks the notes that follow. Notes already marked stay as they were.

## 2026-11-12 — The download includes the rings

The Windows zip on the site was still the build from before the timing change, so downloading it again showed the old playhead. `riffster-site/public/Riffster-windows.zip` is now the current build: 120 ms on time, the Heard box only reports a note that counted, and a gold ring on each string at the playhead.

From here, a change to the app goes into that zip in the same push. A push of the source alone updates the site and leaves the download on the old program.

## 2026-11-12 — Fairer timing, and a Heard box that only reports notes

First report from a real bass: sound works and the notes are detected well. Two things were off.

**Timing was too strict on early.** On time was 80 ms each side of the beat. A bass note is drawn 40 pixels wide and the warm-up scrolls at 170 pixels a second, so the circle first touches the gold line 118 ms before the beat. A pluck on that leading edge looked right and was marked early. On time is now 120 ms each side (`onTimeMs` in `lib/music/score_note.dart`). At full speed, a note that is touching the gold line is on time, on bass and on guitar, for any song. A test holds the note size, the scroll speed, and the window together. The band drawn around the playhead and the green part of the timing gauge follow the same number, so both are wider. Early and late still run out to 250 ms.

**The Heard box said "Miss" on a run with no missed notes.** The box reported every sound, and called any sound that matched no note a miss. An extra sound is not a missed note. During a run the box, its pill, and the timing gauge now change only when a note counts: on time, early, or late. While paused the box still names whatever it hears, with no verdict, so the cable can be checked.

**When to pluck was a guess.** Every string now has a ring where it crosses the gold line. The ring is the size of a note at the moment the note is due, so the rule can be read off the screen: play the note as it fills its ring. The line shown before Play says the same thing. The playhead and its band were made a little taller so the outer rings sit inside them. It is drawn in `_paintTargets` in `lib/widgets/stage/stage_painter.dart`.

Not changed, and worth knowing:

- None of this had been played on the bass when it was written. The user then played the older download: about 89 ms early on average, no misses, and 33 extra sounds. The timing check had not been run, so the cable delay was still a guess.
- Where the extra sounds come from is not confirmed. The likely source is a ringing bass string being read a second time, an octave up. That would also fit the box showing a name like G2. It needs recorded clips from the bass to prove and fix (Stage 2).
- Extra sounds are still counted for the end-of-run card ("sounds were wrong or extra notes"). That line may overstate for the same reason.
- At a slowed speed the window is still 120 real milliseconds, while the note crosses the line more slowly. At 50% a pluck on the leading edge is still early.
- The clips on the shelved marketing page were filmed with the 80 ms rule. One note in them is marked late at 118 ms, which is now on time. The filming script is updated, and the clips are not filmed again yet.
- The Windows download was updated later the same day. See the entry above.

## 2026-11-12 — The download is a real zip

The file at `riffster-site/public/Riffster-windows.zip` was a tar archive with a `.zip` name. `tar -a` does not write the zip format Windows Explorer opens, so the download from the site would not unzip. It is the same Windows build, repacked as a zip. The page now says 15 MB.

## 2026-11-12 — The marketing page is shelved

The product is not ready to be sold that way, so the public homepage is a short note: the app is still in development, with the Windows download under it. None of the marketing page was deleted. It lives at `/preview`, which search engines are told to skip, and it is not linked from the homepage. Putting it back is one change in `src/app/page.tsx`: import `LandingPage` again.

## 2026-11-12 — The site is a marketing page, with the app on film

The site now sells the app. It has the app's own finish: the smoked-glass panels, the gold with a lit top edge, the lamp-lit room, the two typefaces.

What is on the page, top to bottom:

- A headline and the download, over a clip of the whole app counting in, playing the bass warm-up, and showing its result card. The window leans back and stands up as you scroll.
- Scoring: a close clip of the playhead showing a hit, an early, a late, and a miss, with the timing gauge moving beside it.
- Bass first: a neck across the whole page whose four strings can be plucked with the pointer. They swing and die away, and pluck themselves quietly when left alone. There is no sound.
- The three woods: buttons for ebony, rosewood, and maple that swap the board under the same run without the phrase starting over.
- Practice tools: the count-in, speed, bar loop, Guitar Pro files, the timing check, and the result card, with the five keys under them.
- Guitar: a clip of chord changes on rosewood, and the first row of the chord book.
- Platforms: Windows is out now. iPhone and Android are marked "In the works", with no date. The phones show the Windows play area, and the page says so.
- The download again, with the three first-run steps.

The clips are the real app. `tool/site_clips_test.dart` runs the app's own widgets one frame at a time, 60 frames a second, with the notes played by a script, and pipes each frame to ffmpeg. So the film cannot drift from the app: film it again and it matches. Nothing was plugged in. The script tells the run "this note was played, 12 ms early", which is the same call the listener makes.

Sections fade up as they are scrolled to, and a clip plays only while it is on screen. Someone who has asked their device for less movement gets stills with a play button, still strings, and no fades.

`riffster-site/public/media` holds six clips and their stills, about 7.5 MB together.

Not done, and worth knowing:

- The clips show notes being scored. That part of the app has still not been heard on a real bass (see Stage 2 below).
- The phone layouts do not exist yet. The page promises iPhone and Android without a date.

## 2026-11-12 — The download page looks like a product

The page is no longer one centered column. It now has a headline, a still picture of the play area, three short points, three steps, and the download. The picture is drawn in CSS with the app's own finger colors (cream for an open string, green for the middle finger, gold for the ring). It is not a screenshot and not another product's board.

The shape is borrowed from a practice-app site: one claim, the product under it, then a few cards. The colors, the type, and the words stay Riffster's. Nothing on the page promises a feature the app does not have yet.

## 2026-11-12 — A download page, in its own folder

`riffster-site/` is a Next.js app for the download page. It does not change the Flutter app. Flutter never reads that folder.

The page says what Riffster is, and offers a Windows download. The file is `riffster-site/public/Riffster-windows.zip`, a release build of the whole app (the program plus the files that have to sit beside it). It is about 35 MB. The zip is committed, so a push carries the download. `.vercelignore` leaves it out of the ignore list on purpose, so a Vercel upload from that folder still carries it too.

It is live at https://riffster-site.vercel.app, on the Pace Projects team (the Vercel name for that team is `storm-chain`). `riffster.xyz` is attached to that project, and Namecheap now points the name at Vercel. The GitHub repo is connected, and Vercel's root directory is `riffster-site`, so a push builds the site and leaves the Flutter app alone. The first connection built the repo root, which is the Flutter app, and that deploy failed. The Windows zip is in the site folder, so a push carries the download too.

## 2026-11-11 — Stage 2: the bass is heard (built, not yet played on a real bass)

The code for Stage 2 is in. None of it has been heard with a real instrument yet, so the stage is not finished. The list of what is unchecked is at the bottom of this entry.

What you see:

- The low strings of a bass are now in range. The listener covers each instrument's own range: on bass, two semitones under the open E up to fret 24 on the G string.
- A TIMING gauge in the strip at the top right. A dot shows how many milliseconds early or late the last note was, with a green band as wide as "on time".
- The count-in clicks: a higher tick on beat one, then three lower ones. It sounds only when a guitar cable input is open. With the room mic there is no click, because the mic would hear it. There is no switch to turn the click off yet.
- A Timing check button appears in the input row once an input is open. It plays four clicks to get ready and eight to measure, you play one note on each, and it shows "Your notes arrive N ms after the click." Use it saves that number for that input, and the button then reads "Timing N ms". From then on scoring uses the measured number and not the guess of 20, 35, or 50 ms. With the room mic the button is greyed out.
- In a debug build started from the project folder, a Record clip button saves what the cable heard to `test/clips/` as a WAV, with a text file of the notes on the stage beside it. This is a tool for tuning the listener. It is not in a release build.

What changed underneath:

- `lib/audio/pluck_detector.dart` is the new listener, used by both instruments. It answers two questions apart. When was the string plucked: the moment the level jumps. What note was it: the pitch, read a few cycles later once the wave has settled. The score uses the pluck time, so a low note that takes longer to name is not called late. A pitch that changes with no silence (a hammer-on, or a fast line) is a new note, and the detector searches for the exact sample where the old note gave way. A strum with no single pitch is reported at once with no pitch, and counts only toward a chord.
- `lib/audio/pitch.dart` finds how long one cycle of the wave is (the YIN method) and returns nothing when the window is too short to be sure, where the old code guessed.
- `lib/audio/sample_clock.dart` turns "sample number 48,213" into a time on the app's clock. Chunks of sound reach the app late but never early, so the quickest recent arrival is the honest one.
- The exclusive cable path sends sound to the app every 5 ms (it was 20 ms).
- The click is made on the native audio thread in exclusive mode, in `windows/runner/guitar_monitor.cpp`, because that thread owns the speakers there. On the shared path it is a tiny sound loaded into the speaker engine.
- `lib/music/timing_check.dart` works out the delay: each click is paired with its nearest note, and the answer is the middle value, so one fumbled note does not move it. Too few notes, or notes spread too widely, give no answer.
- `lib/data/settings_store.dart` keeps the measured delay per input route (device name plus the way Windows opened it).
- `test/bass_clips_test.dart` scores the listener against every clip in `test/clips/` and keeps the best score each clip has had in `test/clips/best.json`. A change that hears a clip worse fails the test.

One thing done differently from the plan, on purpose:

- The plan said the detector would run off the screen thread. It runs on the main thread. Measured on made-up audio, it costs between 1 and 20 ms of work per second of sound, which is small next to the 16 ms a frame has 60 times a second. A second thread would add a hand-off delay to every note and more code to keep right. If the performance overlay shows dropped frames on a real bass, this is the first thing to move.

Checked:

- 106 automated tests pass, and the analyzer is clean. The listener's tests use made-up string sounds: every open bass string and its 12th fret, a low E under a louder overtone, two notes with no gap, the same note plucked three times, a fast line with no gaps, a hammer-on, a strummed chord, and the guitar's range. Pluck times land within 5 ms, hammer-ons within 10 ms.
- The Windows app builds with the new native click and runs. With the room mic on, real sound flowed through the new listener to the HEARD box with no errors.

Not checked yet, said plainly:

- No bass or guitar was plugged in. The right note names on a real bass, the pluck times, and the two thresholds (how loud counts as a note, how sharp a jump counts as a pluck) are first guesses until clips exist.
- The click has never been heard. It compiles and the code path is tested, and that is all. Neither the exclusive click nor the shared one has sounded out of a speaker.
- The timing check has only been run by test code with made-up notes. Its number includes the time the click takes to leave the speakers, so it is right for a player following the count-in click by ear. For a player following the screen alone it may over-correct by a few milliseconds in exclusive mode, and by more on the shared path.
- The clip test has no clips, so its real-instrument case is skipped.
- Smoothness with the performance overlay is still unmeasured.

## 2026-11-11 — Stage 1: the play area is rebuilt, and bass comes first

The direction changed: Riffster is now built for a 4-string bass first, then guitar. The plan has nine stages and this is the first. The look is waiting on approval before it spreads to the rest of the app.

What you see:

- The first launch asks "What are you playing?", Bass or Guitar. The answer and the wood are saved, and a switch at the top changes instrument at any time. Bass opens on its own three-bar warm-up.
- The stage is a fretboard: wood with grain drawn in code, a bone nut with the string names, metal strings that get thicker toward the low string, and bar lines that look like fret wire with bar numbers. It is taller, and the strings and notes are larger. Ebony, Rosewood, and Maple are still the choices.
- Notes are glass discs in the finger colors, with a slim tail for how long to hold. Open strings are still rings. Chord chips and the barre outline are kept.
- A song no longer starts on its first note. The clock rests one bar early, and Play counts 4, 3, 2, 1 at the song's tempo. Pausing and playing again backs up one bar and counts in. A loop counts in only before its first pass.
- The playhead is gold, sits a fifth of the way in, and has a band around it exactly as wide as "on time" (80 ms each side).
- Playing a note: it swells as it arrives, a hit bursts a green ring and shakes the string, early or late shows the word in gold, and a miss dims. The count of notes in a row bounces, and the playhead glows warmer at 10, 25, and 50.
- A strip at the top right shows the note heard, how it was judged, notes in a row, and the share on time.
- The dock under the stage: Restart, Play, Loop with a range of bars, speed from 50 to 100 percent, the position slider, and the clock. Slow practice is still judged in real milliseconds.
- Keys: Space plays and pauses, R restarts, L loops, minus and plus change the speed.
- When a run ends, a card slides up: percent on time, counts of on time, early, late, and missed, wrong or extra notes counted apart from timing, whether you lean early or late, and which bars held the misses. Dragging the slider back after a run keeps the marks on the notes, so the run can be looked over. Play clears them from that spot forward.
- Every control that was on the screen is still there: Open, Chords, Song, Loop, Play, the slider, Cable, iRig, Mic, Look again, the level bar, volume, Speaker, and the wood. The chord book and lane work as before. Chords is hidden on bass, because the book is guitar shapes.

What changed underneath:

- `lib/music/practice_run.dart` owns the clock, the marks, the loop, the speed, and the streak. It has no timer of its own, so tests move the clock by hand.
- `lib/music/song_timeline.dart` sorts a song once and finds notes with a binary search, so a long file costs the same per frame as a short one.
- The stage is two layers in `lib/widgets/stage/`: the board, painted once, and the notes, painted every frame. A frame no longer rebuilds the screen. The level meter does not either.
- `lib/theme/riffster_theme.dart` holds every color, text style, and timing. Instrument Serif and Instrument Sans ship in the app under the SIL Open Font License.
- `lib/data/settings_store.dart` keeps the instrument and wood in a small JSON file in the app's data folder.
- The Guitar Pro reader now sends bar times and each part's string count. A four-string part opens as a bass. These two were pulled forward from Stage 4, because bar lines and the bar loop need them.
- `flutter test tool/stage_previews_test.dart` saves pictures of the stage and the whole screen into `build/stage_previews/`.

Not checked yet, said plainly:

- No instrument was plugged in for this stage. Hits, early, late, and the string shake were driven by test code, not by a real pluck.
- The low bass notes are still not heard. The pitch detector's floor is above them until Stage 2.
- Smoothness was not measured with the performance overlay.
- The Space key was tested in code. In the running app I only confirmed the Play button.

## 2026-11-09 — Cable, iRig, and mic are separate switches

The practice screen has three switches: Cable, iRig, and Mic. One of them is listened to at a time. The Rocksmith cable is chosen when it is plugged in, and an iRig is chosen when the cable is absent. The room mic starts off, and plugging a guitar in turns it off. Turning a switch off leaves it off until you turn it on or unplug it and plug it back in. The mic can be turned on for scoring, and it is still never played through the speakers.

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
