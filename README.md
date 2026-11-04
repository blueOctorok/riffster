# Riffster

A sideways guitar tab. You bring a song you already have, and the app scrolls it so you can play along.

This first slice scrolls a short built-in phrase. Guitar Pro import and iRig scoring are next.

## Run the Windows app

This PC already has Visual Studio Build Tools 2022 with the C++ workload, and Flutter is on the user PATH. On a new machine, install the [Desktop development with C++](https://docs.flutter.dev/platform-integration/windows/setup) workload first. Windows Developer Mode also has to be on, because the Guitar Pro reader is a plugin and Flutter links plugins with a symlink.

```bash
flutter run -d windows
```

The Flutter SDK for this machine is at `C:\Users\blaha\flutter`.
