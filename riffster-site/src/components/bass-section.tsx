import { PluckStrings } from "@/components/pluck-strings";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";

const points = [
  {
    title: "Drawn for four strings",
    body: "Wider spacing and bigger notes than the guitar view, on strings that get fatter toward the low E.",
  },
  {
    title: "Hears the low end",
    body: "The listener reaches below the open E and up to the 24th fret of the G string.",
  },
  {
    title: "The line is the tune",
    body: "The warm-up that ships with the app is an original bass line, written to be played on its own.",
  },
];

export function BassSection() {
  return (
    <section id="bass" className="scroll-mt-24 bg-room-deep py-24 sm:py-32">
      <div className="mx-auto w-full max-w-6xl px-6">
        <Reveal>
          <SectionHeading eyebrow="Bass first" title="Built from the low E up." centered>
            Riffster starts with the bass and treats it as its own instrument.
            Go on, pluck a string.
          </SectionHeading>
        </Reveal>
      </div>
      <Reveal className="mt-14">
        <PluckStrings />
      </Reveal>
      <div className="mx-auto mt-14 grid w-full max-w-6xl gap-10 px-6 sm:grid-cols-3">
        {points.map((point, index) => (
          <Reveal key={point.title} delayMs={index * 100}>
            <h3 className="font-serif text-2xl text-cream">{point.title}</h3>
            <p className="mt-3 leading-7 text-soft">{point.body}</p>
          </Reveal>
        ))}
      </div>
    </section>
  );
}
