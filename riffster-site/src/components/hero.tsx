import { AppWindow } from "@/components/app-window";
import { DownloadButton } from "@/components/download-button";
import { LoopVideo } from "@/components/loop-video";
import { windowsBuild } from "@/lib/release";

export function Hero() {
  return (
    <section id="top" className="relative overflow-hidden">
      {/* The lamp over the bench: warm in the middle, gone by the corners. */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 top-0 h-[46rem] bg-[radial-gradient(ellipse_60%_55%_at_50%_0%,rgba(228,177,90,0.2),transparent_70%)]"
      />
      <div className="relative mx-auto w-full max-w-6xl px-6 pt-16 text-center sm:pt-24">
        {/* Two lines on a phone, one pill from a tablet up. */}
        <p className="glass inline-flex animate-rise flex-col items-center gap-x-2.5 gap-y-0.5 rounded-3xl px-5 py-2 text-sm text-soft sm:flex-row sm:rounded-full sm:px-4 sm:py-1.5">
          <span className="inline-flex items-center gap-2.5">
            <span className="size-2 rounded-full bg-hit shadow-[0_0_10px] shadow-hit" />
            Out now for Windows
          </span>
          <span className="hidden text-faint sm:inline">·</span>
          <a href="#platforms" className="text-quiet hover:text-cream">
            iPhone and Android on the way
          </a>
        </p>
        <h1 className="mt-8 animate-rise font-serif text-5xl leading-[0.95] text-cream [animation-delay:90ms] sm:text-8xl">
          Play the line.
          <span className="mt-1 block pb-2 text-gold-foil italic">
            The app hears it.
          </span>
        </h1>
        <p className="mx-auto mt-6 max-w-2xl animate-rise text-lg leading-8 text-pretty text-soft [animation-delay:180ms] sm:text-xl sm:leading-9">
          Riffster is a practice app for a real bass. Notes slide along the
          neck toward a gold line, you play them on your own instrument, and
          each one is marked the moment it lands.
        </p>
        <div className="mt-10 flex animate-rise flex-wrap items-center justify-center gap-4 [animation-delay:270ms]">
          <DownloadButton />
          <a
            href="#scoring"
            className="inline-flex h-13 items-center rounded-full border border-line-strong px-7 text-cream transition-colors hover:border-gold hover:text-gold-lit"
          >
            See how it scores
          </a>
        </div>
        <p className="mt-5 animate-rise text-sm text-quiet [animation-delay:360ms]">
          Early build · {windowsBuild.size} · No account
        </p>
      </div>
      {/* Perspective lives on the parent. It is what makes the window's tilt look deep. */}
      <div className="relative mx-auto mt-14 w-full max-w-6xl animate-rise px-4 pb-16 perspective-[1800px] [animation-delay:450ms] sm:px-6">
        <div className="stand-up-on-scroll">
          <AppWindow>
            <LoopVideo
              name="app-run"
              width={1896}
              height={874}
              label="The Riffster app counting in and playing a bass warm-up, with each note marked as it is played."
              eager
              className="block h-auto w-full"
            />
          </AppWindow>
        </div>
      </div>
    </section>
  );
}
