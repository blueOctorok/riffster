# Riffster site

The marketing page, with the Windows download. The Windows app stays in the folder above this one.

```bash
npm run dev
```

If a change to `src/app/globals.css` does not show up, stop the dev server and start it again. It has served an old copy of the styles before.

## The download

The download file is `public/Riffster-windows.zip`. It is committed so a push updates the download. Rebuild it from the project root, then change the date in `src/lib/release.ts`:

```bash
flutter build windows --release
tar -a -cf riffster-site/public/Riffster-windows.zip -C build/windows/x64/runner/Release .
```

## The clips

The videos in `public/media` are the real app, filmed by `tool/site_clips_test.dart` in the project above. Film them again when the app's look changes. It needs an ffmpeg program, and takes about six minutes:

```bash
npm install --prefix build/ffmpeg ffmpeg-static
FFMPEG=build/ffmpeg/node_modules/ffmpeg-static/ffmpeg.exe flutter test tool/site_clips_test.dart
```

## Going live

A push to `main` deploys it. The Vercel project root is `riffster-site`.
