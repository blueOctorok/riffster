import { DownloadButton } from "@/components/download-button";
import { Reveal } from "@/components/reveal";
import { windowsBuild } from "@/lib/release";

const firstRun = [
  {
    title: "Unzip the folder",
    body: "The download is a folder, and the files beside riffster.exe are part of the app. Keep them together.",
  },
  {
    title: "Run riffster.exe",
    body: "This early build is unsigned, so Windows may say it does not know the publisher. Choose More info, then Run anyway.",
  },
  {
    title: "Plug in and play",
    body: "A Rocksmith cable or an iRig gives the cleanest signal. Then press Space.",
  },
];

export function DownloadSection() {
  return (
    <section id="download" className="relative scroll-mt-24 overflow-hidden py-24 sm:py-32">
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_55%_60%_at_50%_100%,rgba(228,177,90,0.18),transparent_70%)]"
      />
      <div className="relative mx-auto w-full max-w-6xl px-6">
        <Reveal className="text-center">
          <h2 className="font-serif text-5xl leading-none text-balance text-cream sm:text-7xl">
            Your bass is right there.
            <span className="block pb-2 text-gold-foil italic">Pick it up.</span>
          </h2>
          <div className="mt-10">
            <DownloadButton />
          </div>
          <p className="mt-5 text-sm text-quiet">
            Windows 10 or 11 · {windowsBuild.size} · Build from {windowsBuild.builtOn}
          </p>
        </Reveal>
        <ol className="mt-20 grid gap-5 md:grid-cols-3">
          {firstRun.map((step, index) => (
            <Reveal key={step.title} delayMs={index * 100} className="h-full">
              <li className="glass h-full list-none rounded-3xl p-6">
                <span className="font-serif text-4xl leading-none text-gold-foil">
                  {index + 1}
                </span>
                <h3 className="mt-4 font-serif text-2xl text-cream">{step.title}</h3>
                <p className="mt-2 leading-7 text-soft">{step.body}</p>
              </li>
            </Reveal>
          ))}
        </ol>
        <p className="mt-8 text-center text-sm text-quiet">
          If the app does not open at all, install Microsoft&apos;s Visual C++
          2015–2022 redistributable and try once more.
        </p>
      </div>
    </section>
  );
}
