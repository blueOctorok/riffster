import { LoopVideo } from "@/components/loop-video";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";

/** The app's own windows: 120 ms is on time, 250 ms is still the same beat. */
const marks = [
  {
    name: "Hit",
    color: "border-hit shadow-hit/60",
    meaning: "The right note, within 120 milliseconds of the beat.",
  },
  {
    name: "Early or late",
    color: "border-gold shadow-gold/60",
    meaning: "The right note, a little ahead of the beat or behind it.",
  },
  {
    name: "Miss",
    color: "border-miss shadow-miss/60",
    meaning: "The beat went by without its note.",
  },
];

export function ScoringSection() {
  return (
    <section id="scoring" className="scroll-mt-24 pt-16 pb-24 sm:pt-20 sm:pb-32">
      <div className="mx-auto grid w-full max-w-6xl items-center gap-14 px-6 lg:grid-cols-[1.1fr_1fr]">
        <Reveal>
          <div className="overflow-hidden rounded-3xl border border-line shadow-[0_40px_100px_rgba(0,0,0,0.6)]">
            <LoopVideo
              name="stage-marks"
              width={1120}
              height={672}
              label="A close view of the gold playhead. Notes reach it and are ringed green for a hit, gold for early or late, and dimmed for a miss."
              className="block h-auto w-full"
            />
          </div>
        </Reveal>
        <Reveal delayMs={120}>
          <SectionHeading
            eyebrow="Scoring"
            title="Every note gets a verdict."
          >
            Pitch and timing are judged together, the instant the string is
            plucked. You know how a note went before the next one arrives.
          </SectionHeading>
          <ul className="mt-9 space-y-5">
            {marks.map((mark) => (
              <li key={mark.name} className="flex items-start gap-4">
                <span
                  aria-hidden
                  className={`mt-0.5 size-7 shrink-0 rounded-full border-2 shadow-[0_0_14px] ${mark.color}`}
                />
                <p className="leading-7 text-soft">
                  <strong className="font-semibold text-cream">{mark.name}.</strong>{" "}
                  {mark.meaning}
                </p>
              </li>
            ))}
          </ul>
          <TimingGauge />
        </Reveal>
      </div>
    </section>
  );
}

/** The app's timing gauge: a dot on a track, with a green band as wide as "on time". */
function TimingGauge() {
  return (
    <div className="glass mt-10 rounded-2xl px-5 py-4">
      <p className="text-[0.66rem] font-semibold tracking-[0.14em] text-quiet uppercase">
        Timing
      </p>
      <div aria-hidden className="relative mt-4 h-1 rounded-full bg-line">
        <span className="absolute inset-y-0 left-1/2 w-[18%] -translate-x-1/2 rounded-full bg-hit/45" />
        <span className="absolute top-1/2 left-1/2 size-3 -translate-1/2 animate-gauge rounded-full bg-hit shadow-[0_0_10px] shadow-hit motion-reduce:animate-none" />
      </div>
      <p className="mt-4 text-sm leading-6 text-soft">
        The gauge shows how many milliseconds ahead or behind you were, so
        &ldquo;late&rdquo; comes with a number.
      </p>
    </div>
  );
}
