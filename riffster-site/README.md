# Riffster site

The download page. The Windows app stays in the folder above this one.

```bash
npm run dev
```

The download file is `public/Riffster-windows.zip`. It is not committed. Rebuild it from the project root:

```bash
flutter build windows --release
tar -a -cf riffster-site/public/Riffster-windows.zip -C build/windows/x64/runner/Release .
```

Deploy from this folder with `npx vercel`. Set the Vercel project's root directory to `riffster-site` if the repo is connected. Do not point the domain until that is asked for.
