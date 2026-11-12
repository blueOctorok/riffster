const windowsBuild = {
  href: "/Riffster-windows.zip",
  builtOn: "12 November 2026",
};

export function DownloadPage() {
  return (
    <main className="mx-auto flex w-full max-w-xl flex-1 flex-col justify-center px-6 py-16">
      <p className="text-sm tracking-[0.18em] text-gold uppercase">Windows</p>
      <h1 className="mt-4 font-serif text-6xl leading-none text-cream">
        Riffster
      </h1>
      <p className="mt-6 text-lg leading-8 text-quiet">
        A practice app for bass. Plug in, play, and the app hears the note.
      </p>
      <a
        href={windowsBuild.href}
        className="mt-10 inline-flex h-12 w-fit items-center rounded-full bg-gold px-6 font-medium text-ink"
      >
        Download for Windows
      </a>
      <p className="mt-4 text-sm leading-6 text-faint">
        Build from {windowsBuild.builtOn}. The download is a folder, not a
        single program: unzip it and run riffster.exe. The other files beside
        it are part of the app.
      </p>
      <div className="mt-10 rounded-2xl border border-line bg-panel px-5 py-4 text-sm leading-6 text-quiet">
        <p>
          This is an early build, the app as it stands today. Windows may say
          it does not know the publisher, because the build is not signed.
          Choose More info, then Run anyway.
        </p>
        <p className="mt-3">
          If the app does not open at all, install Microsoft&apos;s Visual C++
          2015–2022 redistributable and try once more.
        </p>
      </div>
    </main>
  );
}
