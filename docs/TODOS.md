# Riffster end to end

Check these off in order. The product decisions live in `PROJECT_ROADMAP.md`. Do not pull in Proven or `resume-wallet`.

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

The domain `riffster.xyz` is already registered at Namecheap. Build the page only after a Windows build exists to link to.

- [ ] A short Next.js page on Vercel: what Riffster is, and a download button. The site is not the Flutter app. The paid generator will later use a server-only route on this same site. The Anthropic key stays in that server setting and is never sent to the browser or the `.exe`.
- [ ] The `.exe` lives on a GitHub release. The page links to that file. Do not commit the build into the repo.
- [ ] Point the Namecheap DNS for `riffster.xyz` at Vercel when the page is ready.

## Songwriting

Practice is the screen. Songwriting is how a new note list gets onto that screen. Two modes, neither started. Both wait behind a fair iRig score. A generated song and a hand-built song practice the same way: hit, miss, early, late, and a hit streak in the local score file.

### Generator mode

Paid. The only online piece. Price and accounts come later, after `riffster.xyz` is up.

- [ ] The player describes the feel ("a song that sounds like this song"), names chords that must be in it, and picks beginner, intermediate, or advanced.
- [ ] Claude returns an original note list in that feel. The staff plays it with the same chord names and finger colors as an imported song. The result is not a copy of the named song.
- [ ] The Windows app calls `riffster.xyz`. That site holds the Anthropic key and checks the purchase. The key is not in the app.

### Builder mode

Local. No Claude and no account.

- [ ] Drag chords from the book into an order. The name and the fingers come from that same grip.
- [ ] Set the time signature, then drop single notes or a riff. A 12th-fret note is one dot. The player chooses how long it rings.
- [ ] Name the song and practice it. A run of hits is a streak. The streak stays in the local score file.

## Later, only if we still want them

- [ ] Ask Lava whether an outside app can ship in the Studio Appcenter and hear the guitar jack. Not a build target until they say yes.
- [ ] A second importer for a Rocksmith package that is already on the computer. Do not connect to CustomsForge.
- [ ] A backing track made from an audio file the player already has the right to use. Not from Apple Music.

## Not in this app

- A song catalog, including Beatles or Led Zeppelin files shipped by us.
- Blockchain, a token, or an NFT.
- Trophies or a game highway. Original chord practice is included. A course built from someone else's songs is not.
- An account or a hosted database for practice scores. Those stay in a file on the machine. The paid generator is the one online feature, and it lives on `riffster.xyz`.
