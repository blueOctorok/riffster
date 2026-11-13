# Riffster end to end

Check these off in order. The product decisions live in `PROJECT_ROADMAP.md`. Do not pull in Proven or `resume-wallet`.

## Bass first: the nine stages

Since 2026-11-11 this section is the order of work. The numbered sections further down are the earlier guitar-first list. They are kept for their history, and their open items are picked up by the stage named here.

### Stage 1: The play area

- [x] Bass or Guitar chooser on first launch, saved, with a switch at the top (on the rail since Stage 3). A bass warm-up on four strings.
- [x] One theme file for colors, type, and timings. Instrument Serif and Instrument Sans ship in the app.
- [x] The stage is its own widget. Only the notes layer repaints each frame.
- [x] The song rests one bar before its first note, and Play counts one bar in. Pause, the slider, and a loop each have a rule for the count.
- [x] Fretboard look: wood grain, nut, metal strings by thickness, glass notes with tails, fret-wire bar lines, gold playhead with the on-time band.
- [x] Motion: a note swells as it arrives, a hit bursts and shakes the string, early or late shows the word, a miss dims, the streak warms the playhead.
- [x] Feedback strip: note heard, how it was judged, notes in a row, share on time.
- [x] Dock: Restart, Play, Loop over a range of bars, speed 50 to 100 percent, slider, clock. Keys: Space, R, L, minus, plus.
- [x] End-of-run card with counts, early or late tendency, and the bars that held misses.
- [x] Every earlier control and the chord book still work. Tests cover them.
- [x] The user approved the look on 2026-11-11. It can spread to the other screens.
- [x] Hits are seen with a real instrument plugged in. The user played the bass warm-up on 2026-11-12: sound works and notes are detected well.
- [x] On time widened from 80 to 120 ms after that session, so a note touching the gold line at full speed is on time.
- [x] The Heard box no longer says "Miss" for a sound that matched no note. It changes only when a note counts.
- [x] A wrong sound no longer puts the rose X on the note it is near. The X appears when that note's window closes with nothing having saved it, which is after the circle has left the line.
- [x] A ring on every string at the playhead, the size of a note when it is due. The line before Play says "play each note as it fills its ring". Approved as an idea on 2026-11-12.
- [x] The user played the 120 ms window. It felt fair and still strict: 82% on time, no misses, about 88 ms early.
- [x] Easy, Medium, and Hard were tried and removed the same day. One window remains: the circle, 120 ms of song time.
- [x] The on-time window is song time, decided 2026-11-12. Slowing the song no longer shrinks the target. Medium is the circle: a strike as the line touches it is on time, and so is a strike anywhere on the circle. The end-of-run line only calls a run early or late once the average is outside that circle.
- [ ] Find where the extra sounds come from (likely a ringing string read again an octave up), using recorded clips. Until then, decide whether the end-of-run line about wrong or extra notes should stay.
- [ ] Smoothness is checked with Flutter's performance overlay while a fast line plays.

### Stage 2: The bass is heard

Built on 2026-11-11. The boxes still open need a bass plugged in.

- [x] New pluck detector: range from the instrument (bass about 35 to 420 Hz), pluck time split from pitch, a pitch change with no silence is a new note.
- [x] Tests with made-up waves: low E reads E1 under a louder overtone, two back-to-back notes give two plucks, pluck time within 10 ms.
- [x] A debug-only Record clip button saves what the cable heard, with the notes on the stage as its written answer. A test scores the detector against every clip and fails if one is heard worse than before.
- [x] Record the clips on the user's bass, 2026-11-13, one clip each: open strings `E1 A1 D2 G2` (`bass-1794546404`), 12th fret `E2 A2 D3 G3` (`bass-1794546420`), the warm-up slowly (`bass-1794546454`), the warm-up fast (`bass-1794546493`). The first two answers were rewritten, because the recorder had copied the warm-up off the stage. The D string was about 60 cents flat on all four takes, measured outside the app, so its notes are written in the answers as what sounded: `C#2`, `C#3`, and `D#2`. Scores kept in `test/clips/best.json`: 1, 3, 2, and 18 mistakes. What is left is the listener's: a ringing note on the fast line is counted again, and the 12th-fret E is counted twice.
- [ ] Tune the D string up with the tuner in the input panel. After that, four fresh takes would test the listener better than these, which have notes sitting on the border between two names. Not urgent.
- [x] An open input that sends no sound is reopened every four seconds until it does, and the status line says no sound is arriving. Found on 2026-11-12 when a whole take was recorded with nothing heard.
- [ ] Find what refused exclusive mode when that window opened, and why the shared fallback then gave no sound. Neither is known.
- [x] The download zip was rebuilt on 2026-11-13 with the silent-input fix and Stage 3. The page says 13 November 2026, 15 MB.
- [ ] Tune the two detector thresholds (`_floor`, `_jump` in `pluck_detector.dart`) against those clips.
- [ ] The detector runs off the screen thread. Left on the main thread on purpose: it measured 1 to 20 ms of work per second of sound. Move it only if the performance overlay shows dropped frames. Waiting on the user's OK for this change of plan.
- [ ] On the bass, once the D string is tuned: open E, A, D, G and fret 12 on each show the right name. In the clips E, A, and G already do.
- [x] Timing check: eight notes along with a click, and the measured delay is stored per input. Scoring uses it in place of the guessed 20, 35, and 50 ms. The countdown gets the same click.
- [ ] The click is heard on the exclusive path and on the shared path. So far it has only compiled.
- [ ] The timing check is run on the real bass, and a note played on the click then reads "On the beat".
- [x] A small gauge in the feedback strip shows how many milliseconds early or late the last pluck was. Approved 2026-11-11.
- [ ] Decide whether the count-in click needs an off switch.

### Stage 3: The shell

Built on 2026-11-13. Not yet approved by the user.

- [x] Side rail: Home, Songs, Practice, Build, Create, Library, with the instrument switch and an input chip. Areas that are not built are dim and marked SOON.
- [x] Home: the song on the stage, and four doors that lift under the pointer.
- [x] Input panel: Cable, iRig, Mic, Look again, the timing check, the volume and speaker switch, and a tuner needle. It slides out from the chip and a click away closes it.
- [x] The tuner measures against the open strings, so a string far out still reads as that string.
- [x] Every area uses the Stage 1 look. The chord book keeps its layout and behaviour. Moving between areas is a short fade and rise.
- [ ] The user looks at the shell and approves it, or says what to change.
- [x] The tuner was used on the real bass, 2026-11-13: E, A, and G tuned fine. On D the needle did not move, because the dial stopped at 50 cents and the string was 57 flat. The dial now reaches a semitone each way and has no needle when nothing is heard.
- [ ] The user tunes the D string with the wider dial and says whether the needle moves.
- [ ] Decide whether the areas that are not built should show on the rail as SOON, or stay hidden until they are. Showing them follows the plan. Hiding them is one line.
- [ ] Days in a row and minutes played go on Home in Stage 5. Until then the lower half of Home is empty.

### Stage 4: Songs, melody on bass, Library

- [x] The file reader sends bar times and each part's string count. Done early, in Stage 1.
- [ ] The reader also sends tuning. The part picker filters by instrument. A 5-string part is shown as not supported yet. Today it opens on the six-line staff.
- [ ] Shared code that places a list of pitches on the neck with the least hand movement, with tests.
- [ ] Melody on bass from the user's own file: any part, moved by whole octaves, a chord becomes its top note, low or high on the neck.
- [ ] Library: one small file per item with the best score.
- [ ] Riffster originals: about a dozen bass riffs and a few bass melodies written for the app. The user judges them on the bass.
- [ ] A few very old copyright-free tunes arranged by us as bass melodies.

### Stage 5: Practice

- [ ] Scales and arpeggios by rule, as scored runs.
- [ ] Drills with knobs: key, length, note value, difficulty.
- [ ] Find the note.
- [ ] Trouble spots: one tap loops the bars with misses at 70 percent and steps the speed up after three clean passes.
- [ ] Days in a row and minutes played on Home. No trophies.
- [ ] Drum groove made in code and mixed in the native audio thread. Muted when the room mic is the source.

### Stage 6: Build for bass

- [ ] The lane accepts a grip, a single note, a pattern, or a rest. Guitar chord behaviour and tests do not change.
- [ ] Clickable bass neck, frets 0 to 12, with note names.
- [ ] Pattern cards drawn from the chosen root.
- [ ] Lane tempo, eighth-note snap, bar lines in 4/4.

### Stage 7: Create, on a private test key

- [ ] Request form: lick, riff, or exercise, key, tempo, difficulty, length, feel, optional "inspired by".
- [ ] The reply is pitches and rhythm. The app places and checks them.
- [ ] The key is read from an environment variable in a debug build only. It is never in a release build.
- [ ] Assists as droppable suggestions: continue, variation, easier, harder, a riff from the misses, a bass line under guitar chords.
- [ ] A legal check on "inspired by" before money changes hands.

### Stage 8: Paid

- [ ] `riffster.xyz` generate route holding the key, sign-in, payment. The app swaps the test key for the site.

### Stage 9: Guitar gets the same areas

- [ ] Practice, the neck in Build, and Create work for guitar.

## Done

- [x] Flutter Windows app scaffold.
- [x] Note list: time, string, fret, duration, MIDI pitch, fretting finger.
- [x] Sideways staff with a fixed height, playhead, and the warm-up phrase.
- [x] Finger colors: index blue, middle green, ring gold, pinky rose. Open strings stay hollow.
- [x] Chrome preview so the screen can be seen before Visual Studio is installed.

## 1. Run it as a Windows app

- [x] Add `C:\Users\blaha\flutter\bin` to PATH.
- [x] Install Visual Studio with the Desktop development with C++ workload. Build Tools 2022 is enough. The full Visual Studio editor is not required.
- [x] `flutter run -d windows` opens the warm-up on the desktop.

## 2. Import a Guitar Pro file

- [x] Turn on Windows Developer Mode (Settings, System, For developers). Flutter needs it before a plugin can be linked into the Windows app. The file reader is the first plugin.
- [x] A hidden web view runs alphaTab only long enough to read the file.
- [x] The file becomes a `TabSong`: time, string, fret, duration, MIDI pitch.
- [x] If the file names a finger, use it. A stack that matches a chord-book grip uses that grip's name and fingers. Open strings the tab left out still count when the grip has three or more fretted notes, which is how the written 3-2-3 shape is named G. Anything else fills a missing finger from the shape. A melody packs the frets that are played, and a fast hop across strings on one fret gets a new finger per string. A wider shape stays hollow. A chord name from pitches is used only when they match a shape exactly.
- [x] The player picks which track is theirs when the file has more than one guitar part. A name from the file is kept. "Track 1" is replaced from the notes: single notes, chords, two notes, or a harmony. An unnamed exact copy is left out.
- [x] Tempo comes from the file.
- [x] The practice screen scrolls that song instead of the warm-up.
- [x] One real `.gp` file plays through from the first note to the last. Sample: `test/fixtures/import_check.gp5`.

## Chord book

One list of grips: the name, the fret on each string, and the finger on each fret. Import reads it, and chord practice will read the same list. A finger learned in practice is the finger a song shows.

- [x] The book holds the common open chords plus the grips this kind of file already uses (open G, D, F#7, Em7, and Bm, including the barre Bm). A matching stack takes that name and those fingers. A finger stored in the file still wins.
- [x] Chord practice shows one grip at a time on the staff, in teaching order, using the book fingers. The last step is an original change, G D Em C. Hearing the strum waits for the iRig.
- [x] The staff can wear a guitar neck: ebony, rosewood, or maple. Strings and open notes use whichever ink still shows on that wood. Finger colors stay put.

## 3. Score the iRig

- [x] A single note is hit, miss, early, or late from its MIDI pitch and the clock. The same pitch on another string still hits. A chord is scored from the strum only. The window is 80 ms on time, and 250 ms before it counts as a different beat.
- [x] The app listens to the guitar input. The Rocksmith Real Tone cable is chosen when Windows lists Rocksmith USB Guitar Adapter, including when it is plugged in after the app is open, and that signal plays out the PC speakers. An iRig recording device is the fallback. A PC microphone is never played back, because that loop howls. Speakers (iRig USB) alone is not the guitar input. Rocksmith's song files stay closed. A level bar shows the signal. Play draws the result on the note: green hit, gold early or late, rose slash for a miss. A note that scrolls past with no pluck is a miss. A click and the other tracks are not built.
- [x] Cable, iRig, and Mic are separate switches. One is on at a time. The mic starts off, and a guitar plug-in turns it off. The mic can be turned on for scoring and is still not played through the speakers.
- [ ] The USB-C iRig is confirmed on a real guitar. The app can also play a click or the tab's other tracks.
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
- [ ] No account and no database for those scores. The paid generator on `riffster.xyz` is separate.

## 6. Phones, after the PC version feels fair

- [ ] Android build from this same Flutter project, tested with the iRig.
- [ ] iPhone build. That needs a Mac or a cloud Mac, plus the $99 Apple developer account.
- [ ] Google Play, if we publish Android, is a one-time $25 fee.

## Download page

The domain `riffster.xyz` is already registered at Namecheap. The page lives in `riffster-site/` and does not touch the Flutter app.

- [x] A short Next.js page: what Riffster is, and a download button. Built 2026-11-12. The paid generator will later use a server-only route on this same site. The Anthropic key stays in that server setting and is never sent to the browser or the `.exe`.
- [x] Rebuilt the same day as a marketing page: clips of the real app, strings you can pluck, the three woods, the practice tools, guitar, and iPhone and Android marked as in the works.
- [x] Shelved that page the same day. The homepage is a short "still in development" note with the download. The marketing page is at `/preview` and is not linked.
- [ ] Put the marketing page back on the homepage when the product is ready. Change `src/app/page.tsx` to render `LandingPage`.
- [x] `tool/site_clips_test.dart` films the clips from the app's own widgets. Film them again whenever the app's look changes. It was changed for the rail on 2026-11-13 and has not been run since.
- [ ] Film the clips again before the marketing page goes back up. They were filmed with the 80 ms rule, and one note in them reads late at 118 ms, which is now on time. They also show the top bar that the rail replaced.
- [ ] Decide whether plucking the strings on the page should make a sound.
- [ ] Decide whether the page should take an email address for "tell me when the phone app is out". It needs somewhere to keep the addresses.
- [ ] A picture for link previews (the image a link shows when it is pasted into a message). The dog mark is ready to go on it.
- [x] The dog mark is the Windows icon, the browser tab icon, and sits with the name in the app and on the site (2026-11-12). `tool/brand/make_brand.py` rebuilds every icon file from the two drawings beside it.
- [x] The Windows build is a zip of the whole release folder, `riffster-site/public/Riffster-windows.zip`, dated 13 November 2026. Repacked on the 12th with the 120 ms timing and the rings, then the timing settings, then the dog icon, and on the 13th with the shell, the tuner, and the silent-input fix. An app change is not in the download until this zip is rebuilt and pushed.
- [x] Deployed to https://riffster-site.vercel.app on Pace Projects, 2026-11-12. The framework has to be Next.js. A new project was guessed as a plain file site, which served the zip and lost the page.
- [x] Namecheap DNS pointed at Vercel on 2026-11-12. A `@` `216.150.1.1`, A `@` `216.150.16.1`, and CNAME `www` `f9f16c33a1c708b9.vercel-dns-016.com`. `www` redirects to the bare domain. Public DNS already returns the site. A network that still shows the parking page is holding the old answer.

## Songwriting

Practice is the screen. Songwriting is how a new note list gets onto that screen. Two modes, neither started. Both wait behind a fair iRig score. A generated song and a hand-built song practice the same way: hit, miss, early, late, and a hit streak in the local score file.

### Generator mode

Paid. The only online piece. Price and accounts come later, after `riffster.xyz` is up.

- [ ] The player describes the feel ("a song that sounds like this song"), names chords that must be in it, and picks beginner, intermediate, or advanced.
- [ ] Claude returns an original note list in that feel. The staff plays it with the same chord names and finger colors as an imported song. The result is not a copy of the named song.
- [ ] The Windows app calls `riffster.xyz`. That site holds the Anthropic key and checks the purchase. The key is not in the app.

### Builder mode

Local. No Claude and no account. The first slice is the Build button on the practice screen. The course stays the guided walk. A dropped grip becomes the same note list an imported song uses.

- [x] Chords shows one group at a time, as chart cards you drag. Open, barre, sevenths, sus, power, and more. Barre picks an E or A shape and a quality, then shows the twelve roots. There is no Next button. Low E is on the left. A higher shape starts at its lowest fret.
- [x] Drop a block on the lane or the staff to add it. Drop it on a chord to put it in front. Drag a name to move it. Drag the gold edge to change how long it rings. The next chord starts when this one ends.
- [x] Loop plays the lane again. A finger that stays on the same string and fret is marked.
- [ ] A small neck drops one note on any string. A 12th-fret note is one dot.
- [ ] Vibrato, bend, slide, hammer, and pull are drawn on the note and not scored yet. The ear hears one pitch per pluck, so a bend would be marked wrong.
- [ ] Name the lane and keep a hit streak in the local score file.
- [ ] A time signature. The lane is 60 bpm for now, and the gap between chords is the duration.

## Later, only if we still want them

- [ ] Ask Lava whether an outside app can ship in the Studio Appcenter and hear the guitar jack. Not a build target until they say yes.
- [ ] A second importer for a Rocksmith package that is already on the computer. Do not connect to CustomsForge.
- [ ] A backing track made from an audio file the player already has the right to use. Not from Apple Music.

## Not in this app

- A song catalog, including Beatles or Led Zeppelin files shipped by us.
- Blockchain, a token, or an NFT.
- Trophies or a game highway. Original chord practice is included. A course built from someone else's songs is not.
- An account or a hosted database for practice scores. Those stay in a file on the machine. The paid generator is the one online feature, and it lives on `riffster.xyz`.
