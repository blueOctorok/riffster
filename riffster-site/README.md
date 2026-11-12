# Riffster site

The download page. The Windows app stays in the folder above this one.

```bash
npm run dev
```

The download file is `public/Riffster-windows.zip`. It is committed so a push updates the download. Rebuild it from the project root:

```bash
flutter build windows --release
tar -a -cf riffster-site/public/Riffster-windows.zip -C build/windows/x64/runner/Release .
```

A push to `main` deploys it. The Vercel project root is `riffster-site`.
