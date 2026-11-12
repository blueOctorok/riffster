# Riffster site

The public page says the app is still in development and offers the Windows download. The full marketing page is kept at `/preview` and is not linked from the homepage. The Windows app stays in the folder above this one.

```bash
npm run dev
```

If a change to `src/app/globals.css` does not show up, stop the dev server and start it again. It has served an old copy of the styles before.

## The download

The download file is `public/Riffster-windows.zip`. It is committed so a push updates the download. A change to the app is not in that download until this zip is rebuilt and pushed. Rebuild it from the project root, then change the date and size in `src/lib/release.ts`:

```bash
flutter build windows --release
python - << 'PY'
import os, zipfile
root = "build/windows/x64/runner/Release"
out = "riffster-site/public/Riffster-windows.zip"
with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for folder, _, names in os.walk(root):
        for name in names:
            full = os.path.join(folder, name)
            archive.write(full, os.path.relpath(full, root).replace(os.sep, "/"))
PY
```

Pack it with Python. `tar -a` writes a tar archive and only borrows the `.zip` name, and Windows will not open that.

## The clips

The videos in `public/media` are the real app, filmed by `tool/site_clips_test.dart` in the project above. Film them again when the app's look changes. It needs an ffmpeg program, and takes about six minutes:

```bash
npm install --prefix build/ffmpeg ffmpeg-static
FFMPEG=build/ffmpeg/node_modules/ffmpeg-static/ffmpeg.exe flutter test tool/site_clips_test.dart
```

## Going live

A push to `main` deploys it. The Vercel project root is `riffster-site`.
