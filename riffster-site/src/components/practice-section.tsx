import type { ReactNode } from "react";

import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";

/** The small capitals the app puts over a figure. */
const caption = "text-[0.66rem] font-semibold tracking-[0.14em] text-quiet uppercase";

const fileEndings = [".gp", ".gp3", ".gp4", ".gp5", ".gpx"];

/** The timing check plays 4 clicks to get ready and 8 it measures. */
const timingClicks = { leadIn: 4, measured: 8 };

const tools: { title: string; body: string; visual: ReactNode }[] = [
  {
    title: "One bar to get ready",
    body: "Press Space and the app counts a full bar before the first note. Nothing in the count is judged.",
    visual: (
      <div className="flex items-center gap-5">
        <span className="font-serif text-6xl leading-none text-gold-foil">4</span>
        <span className="flex gap-2">
          {[0, 1, 2, 3].map((beat) => (
            <span
              key={beat}
              className="size-2.5 animate-count rounded-full bg-gold motion-reduce:animate-none"
              // Each dot runs the same 2.4 second loop, started one beat after the last.
              style={{ animationDelay: `${beat * 0.6}s` }}
            />
          ))}
        </span>
      </div>
    ),
  },
  {
    title: "Slow it down",
    body: "Drop the speed to half, ten percent at a time. On time still means on time: only your hands get longer to move.",
    visual: (
      <div className="flex items-center gap-5 text-quiet">
        <span className="text-2xl">−</span>
        <span className="text-center">
          <span className={`block ${caption}`}>Speed</span>
          <span className="mt-1 block text-2xl font-semibold text-cream">70%</span>
        </span>
        <span className="text-2xl">+</span>
      </div>
    ),
  },
  {
    title: "Loop the hard bar",
    body: "Choose the bars that trip you up and go round them. The loop wraps in time, with no count in between.",
    visual: (
      <div className="flex items-center gap-6">
        <svg
          aria-hidden
          viewBox="0 0 24 24"
          className="size-8 text-gold"
          fill="none"
          stroke="currentColor"
          strokeWidth="1.8"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="m17 2 4 4-4 4M3 11V9a3 3 0 0 1 3-3h15M7 22l-4-4 4-4m14-1v2a3 3 0 0 1-3 3H3" />
        </svg>
        {[
          ["From", "2"],
          ["To", "3"],
        ].map(([label, bar]) => (
          <span key={label} className="text-center">
            <span className={`block ${caption}`}>{label}</span>
            <span className="mt-1 block text-2xl font-semibold text-cream">{bar}</span>
          </span>
        ))}
      </div>
    ),
  },
  {
    title: "Bring your own tabs",
    body: "Open a Guitar Pro file you already have and it scrolls along the neck like the warm-up does.",
    visual: (
      <div className="flex flex-wrap justify-center gap-2">
        {fileEndings.map((ending) => (
          <span
            key={ending}
            className="rounded-lg border border-line-strong bg-room-deep px-2.5 py-1 font-mono text-sm text-soft"
          >
            {ending}
          </span>
        ))}
      </div>
    ),
  },
  {
    title: "Know your cable's delay",
    body: "A twelve-click timing check measures how late your cable delivers a note. Scoring then allows for it.",
    visual: (
      <div className="flex items-end gap-1.5">
        {Array.from({ length: timingClicks.leadIn + timingClicks.measured }, (_, click) => (
          <span
            key={click}
            className={`w-1.5 rounded-full ${click < timingClicks.leadIn ? "h-4 bg-line-strong" : "h-8 bg-gold"}`}
          />
        ))}
      </div>
    ),
  },
  {
    title: "A straight answer at the end",
    body: "Your share of notes on time, your best streak, how many ran early or late, and which bar the misses were in.",
    visual: (
      <div className="flex items-baseline gap-3">
        <span className="font-serif text-6xl leading-none text-gold-foil">91%</span>
        <span className="text-sm text-quiet">on time</span>
      </div>
    ),
  },
];

const keys = [
  { cap: "Space", does: "Play or pause" },
  { cap: "R", does: "Restart" },
  { cap: "L", does: "Loop" },
  { cap: "−", does: "Slower" },
  { cap: "+", does: "Faster" },
];

export function PracticeSection() {
  return (
    <section id="practice" className="scroll-mt-24 bg-room-deep py-24 sm:py-32">
      <div className="mx-auto w-full max-w-6xl px-6">
        <Reveal>
          <SectionHeading eyebrow="Practice" title="The tools that get a line under your fingers." centered>
            Everything is one key or one click from the stage, so the bass
            stays in your hands.
          </SectionHeading>
        </Reveal>
        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {tools.map((tool, index) => (
            <Reveal key={tool.title} delayMs={(index % 3) * 100} className="h-full">
              <article className="glass h-full rounded-3xl p-6">
                <div className="flex h-28 items-center justify-center rounded-2xl bg-room-deep/70 inset-shadow-sm inset-shadow-black/60">
                  {tool.visual}
                </div>
                <h3 className="mt-6 font-serif text-2xl text-cream">{tool.title}</h3>
                <p className="mt-2 leading-7 text-soft">{tool.body}</p>
              </article>
            </Reveal>
          ))}
        </div>
        <Reveal className="mt-12">
          <ul className="flex flex-wrap items-center justify-center gap-x-8 gap-y-4">
            {keys.map((key) => (
              <li key={key.cap} className="flex items-center gap-3 text-sm text-quiet">
                <kbd className="glass inline-flex h-9 min-w-9 items-center justify-center rounded-lg px-2.5 font-sans font-semibold text-cream">
                  {key.cap}
                </kbd>
                {key.does}
              </li>
            ))}
          </ul>
        </Reveal>
      </div>
    </section>
  );
}
