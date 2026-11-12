import Image from "next/image";

import { LoopVideo } from "@/components/loop-video";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";

/** The app colors each note by the finger that frets it. */
const fingers = [
  { name: "Index", color: "bg-finger-index" },
  { name: "Middle", color: "bg-finger-middle" },
  { name: "Ring", color: "bg-finger-ring" },
  { name: "Pinky", color: "bg-finger-pinky" },
];

export function GuitarSection() {
  return (
    <section id="guitar" className="scroll-mt-24 py-24 sm:py-32">
      <div className="mx-auto w-full max-w-6xl px-6">
        <Reveal>
          <SectionHeading eyebrow="Six strings too" title="Switch to guitar and build your own changes." centered>
            One switch at the top turns the stage into a guitar neck. Drag
            chord shapes from the chord book into a lane, then play the
            changes with every finger shown.
          </SectionHeading>
        </Reveal>
        <Reveal className="mt-14">
          <div className="overflow-hidden rounded-[1.5%/5.4%] shadow-[0_40px_100px_rgba(0,0,0,0.6)]">
            <LoopVideo
              name="guitar-changes"
              width={1812}
              height={504}
              label="Guitar chords scrolling along a rosewood neck toward the playhead, each chord named above its notes."
              className="block h-auto w-full"
            />
          </div>
        </Reveal>
        <Reveal className="mt-6">
          {/*
            The picture is the chord book as the app draws it, with the app's
            dark room behind the cards. `mix-blend-lighten` keeps whichever
            is lighter, the picture or the panel under it, so that dark
            backdrop drops out and only the paper cards show.
          */}
          <div className="rounded-3xl border border-line bg-[#1d1a16] p-[1.2%]">
            <Image
              src="/media/chord-book-row.png"
              width={2416}
              height={342}
              alt="Chord cards from the Riffster chord book: G, C, D, E, E minor, and A, each with its finger positions."
              className="h-auto w-full mix-blend-lighten"
            />
          </div>
        </Reveal>
        <Reveal className="mt-8">
          <ul className="flex flex-wrap items-center justify-center gap-x-7 gap-y-3 text-sm text-quiet">
            {fingers.map((finger) => (
              <li key={finger.name} className="flex items-center gap-2.5">
                <span aria-hidden className={`size-3 rounded-full ${finger.color}`} />
                {finger.name}
              </li>
            ))}
          </ul>
        </Reveal>
      </div>
    </section>
  );
}
