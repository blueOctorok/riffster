import { NeckPicker } from "@/components/neck-picker";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";

export function NecksSection() {
  return (
    <section id="necks" className="scroll-mt-24 py-24 sm:py-32">
      <div className="mx-auto w-full max-w-6xl px-6">
        <Reveal>
          <SectionHeading eyebrow="The board" title="Pick your wood." centered>
            The play area is a fretboard seen from above, with wound strings
            and a bone nut. It comes in three woods. Try them.
          </SectionHeading>
        </Reveal>
        <Reveal className="mt-14">
          <NeckPicker />
        </Reveal>
      </div>
    </section>
  );
}
