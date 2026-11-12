# Riffster

A practice app for bass and guitar. A tab scrolls sideways along a fretboard into a playhead, and the app listens through a cable and marks each note on time, early, late, or missed.

It opens on a short warm-up. You can also open a Guitar Pro file you already have, or build a chord progression on the guitar side. The plan and what is built so far are in `docs/PROJECT_ROADMAP.md` and `docs/TODOS.md`.

## Run the Windows app

This PC already has Visual Studio Build Tools 2022 with the C++ workload, and Flutter is on the user PATH. On a new machine, install the [Desktop development with C++](https://docs.flutter.dev/platform-integration/windows/setup) workload first. Windows Developer Mode also has to be on, because the Guitar Pro reader is a plugin and Flutter links plugins with a symlink.

```bash
flutter run -d windows
```

The Flutter SDK for this machine is at `C:\Users\blaha\flutter`.
