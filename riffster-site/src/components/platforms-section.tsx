import Image from "next/image";
import type { ReactNode } from "react";

import { DownloadButton } from "@/components/download-button";
import { LoopVideo } from "@/components/loop-video";
import { Reveal } from "@/components/reveal";
import { SectionHeading } from "@/components/section-heading";
import { windowsBuild } from "@/lib/release";

const phones = [
  { name: "iPhone", clip: "neck-ebony" },
  { name: "Android", clip: "neck-maple" },
];

export function PlatformsSection() {
  return (
    <section id="platforms" className="scroll-mt-24 bg-room-deep py-24 sm:py-32">
      <div className="mx-auto w-full max-w-6xl px-6">
        <Reveal>
          <SectionHeading eyebrow="Platforms" title="On Windows today. In your pocket next." centered>
            Riffster is one app, made to run on all three. Windows is out
            first, and iPhone and Android are in the works.
          </SectionHeading>
        </Reveal>
        <div className="mt-14 grid gap-5 lg:grid-cols-3">
          <Reveal className="h-full">
            <PlatformCard name="Windows" status="Out now" live>
              <div className="glass w-full overflow-hidden rounded-xl">
                <Image
                  src="/media/app-run.jpg"
                  width={1896}
                  height={874}
                  alt="The Riffster app on Windows, part way through a bass warm-up."
                  className="h-auto w-full"
                />
              </div>
              <div className="mt-6">
                <DownloadButton size="small" />
                <p className="mt-3 text-sm text-quiet">
                  Build from {windowsBuild.builtOn}
                </p>
              </div>
            </PlatformCard>
          </Reveal>
          {phones.map((phone, index) => (
            <Reveal key={phone.name} delayMs={(index + 1) * 100} className="h-full">
              <PlatformCard name={phone.name} status="In the works">
                <PhoneFrame>
                  <LoopVideo
                    name={phone.clip}
                    width={1812}
                    height={504}
                    label={`The Riffster play area shown on a phone, as planned for ${phone.name}.`}
                    // The clip is wider than a phone. This keeps the nut
                    // and the playhead and lets the right side run off.
                    className="absolute inset-0 size-full object-cover object-left"
                  />
                </PhoneFrame>
                <p className="mt-6 text-sm leading-6 text-quiet">
                  The same stage, the same scoring. No release date yet.
                </p>
              </PlatformCard>
            </Reveal>
          ))}
        </div>
        <p className="mt-8 text-center text-sm text-quiet">
          The phones show the play area from the Windows app. The phone
          screens themselves are still being built.
        </p>
      </div>
    </section>
  );
}

type PlatformCardProps = {
  name: string;
  status: string;
  /** True for a platform you can download today. */
  live?: boolean;
  children: ReactNode;
};

function PlatformCard({ name, status, live = false, children }: PlatformCardProps) {
  return (
    <article className="glass flex h-full flex-col rounded-3xl p-6">
      <div className="flex items-center justify-between">
        <h3 className="font-serif text-3xl text-cream">{name}</h3>
        <span
          className={`inline-flex items-center gap-2 rounded-full border px-3 py-1 text-xs font-semibold ${live ? "border-hit/40 text-hit" : "border-gold/40 text-gold"}`}
        >
          <span className={`size-1.5 rounded-full ${live ? "bg-hit" : "bg-gold"}`} />
          {status}
        </span>
      </div>
      <div className="mt-6 flex flex-1 flex-col items-center justify-center text-center">
        {children}
      </div>
    </article>
  );
}

/** A phone on its side, the way you would hold it to play along. */
function PhoneFrame({ children }: { children: ReactNode }) {
  return (
    <div className="glass w-full rounded-[1.75rem] p-2">
      <div className="relative aspect-[19.5/9] overflow-hidden rounded-[1.25rem] bg-room">
        {children}
        <span
          aria-hidden
          className="absolute top-1/2 right-2 size-2 -translate-y-1/2 rounded-full bg-black ring-1 ring-white/10"
        />
      </div>
    </div>
  );
}
