import { StagePreview } from "@/components/stage-preview";

const windowsBuild = {
  href: "/Riffster-windows.zip",
  builtOn: "12 November 2026",
};

const points = [
  {
    title: "The note is heard",
    body: "Plug in a cable. Pitch and timing are marked as you play: on time, early, or late.",
  },
  {
    title: "Bass first",
    body: "Four strings, an octave under the guitar. The line you play is the melody.",
  },
  {
    title: "Your own file",
    body: "Open a Guitar Pro file you already have, or start on the warm-up that ships with the app.",
  },
];

const steps = [
  {
    title: "Download",
    body: "Unzip the folder and run riffster.exe. The files beside it are part of the app.",
  },
  {
    title: "Plug in",
    body: "The Rocksmith cable or an iRig. One input at a time. The room mic never plays out the speakers.",
  },
  {
    title: "Play",
    body: "Space counts one bar, then the notes meet the playhead. Slow it down if you want.",
  },
];

function DownloadButton({ quiet = false }: { quiet?: boolean }) {
  return (
    <a
      href={windowsBuild.href}
      className={
        quiet
          ? "inline-flex h-12 items-center rounded-full border border-line px-6 text-sm text-cream"
          : "inline-flex h-12 items-center rounded-full bg-gold px-6 font-medium text-ink shadow-[0_8px_30px_rgba(228,177,90,0.25)]"
      }
    >
      Download for Windows
    </a>
  );
}

export function DownloadPage() {
  return (
    <div className="relative">
      <div className="pointer-events-none absolute inset-x-0 top-0 h-80 bg-[radial-gradient(ellipse_at_top,rgba(228,177,90,0.16),transparent_60%)]" />
      <header className="relative mx-auto flex w-full max-w-5xl items-center justify-between px-6 py-5">
        <span className="font-serif text-2xl">Riffster</span>
        <a href={windowsBuild.href} className="text-sm text-quiet">
          Download
        </a>
      </header>
      <main className="relative mx-auto w-full max-w-5xl px-6 pb-20">
        <section className="mx-auto max-w-3xl pt-10 text-center sm:pt-16">
          <p className="text-xs tracking-[0.22em] text-gold uppercase">
            Bass, for Windows
          </p>
          <h1 className="mt-5 font-serif text-5xl leading-none text-cream sm:text-7xl">
            Play the line.
            <span className="mt-2 block text-gold italic">The app hears it.</span>
          </h1>
          <p className="mx-auto mt-6 max-w-xl text-lg leading-8 text-quiet">
            A practice app for a real bass. The notes come to the playhead,
            you play them, and each one is marked. No account.
          </p>
          <div className="mt-8">
            <DownloadButton />
          </div>
          <p className="mt-4 text-sm text-faint">
            Build from {windowsBuild.builtOn}
          </p>
        </section>
        <div className="mt-12">
          <StagePreview />
        </div>
        <section className="mt-20 grid gap-4 sm:grid-cols-3">
          {points.map((point) => (
            <article
              key={point.title}
              className="rounded-2xl border border-line bg-panel px-5 py-6"
            >
              <h2 className="font-serif text-2xl text-cream">{point.title}</h2>
              <p className="mt-3 text-sm leading-6 text-quiet">{point.body}</p>
            </article>
          ))}
        </section>
        <section className="mt-20">
          <h2 className="text-center font-serif text-4xl text-cream">
            Three steps, then you play
          </h2>
          <div className="mt-8 grid gap-4 sm:grid-cols-3">
            {steps.map((step, index) => (
              <article
                key={step.title}
                className="rounded-2xl border border-line bg-room-deep px-5 py-6"
              >
                <p className="text-sm text-gold">{index + 1}</p>
                <h3 className="mt-3 font-serif text-2xl">{step.title}</h3>
                <p className="mt-3 text-sm leading-6 text-quiet">{step.body}</p>
              </article>
            ))}
          </div>
        </section>
        <section className="mt-20 rounded-3xl border border-line bg-panel px-6 py-10 text-center">
          <h2 className="font-serif text-4xl">Get the current build</h2>
          <p className="mx-auto mt-4 max-w-lg text-sm leading-6 text-quiet">
            This is an early build. Windows may say it does not know the
            publisher, because the build is not signed. Choose More info, then
            Run anyway. If it does not open, install the Visual C++ 2015–2022
            redistributable and try once more.
          </p>
          <div className="mt-8">
            <DownloadButton quiet />
          </div>
        </section>
      </main>
    </div>
  );
}
