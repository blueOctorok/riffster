"use client";

import { useEffect, useRef, useState } from "react";

import { useInView } from "@/hooks/use-in-view";
import { useReducedMotion } from "@/hooks/use-reduced-motion";

/** The app's three boards. `wood` is the same color the app paints each one. */
const necks = [
  { id: "ebony", name: "Ebony", wood: "#241f1a", note: "Dark and quiet. The app opens on it." },
  { id: "rosewood", name: "Rosewood", wood: "#5c3329", note: "Red-brown, with the grain turned up." },
  { id: "maple", name: "Maple", wood: "#e4c48a", note: "Blonde. The note rings turn dark so they still show." },
];

/** The three woods as buttons, over a clip of the same run on whichever is chosen. */
export function NeckPicker() {
  const [chosen, setChosen] = useState(0);
  const videos = useRef<(HTMLVideoElement | null)[]>([]);
  const stage = useRef<HTMLDivElement>(null);
  const inView = useInView(stage);
  const reducedMotion = useReducedMotion();

  // Only the chosen board plays, and only while it is on screen. With
  // less movement asked for, none play and each wood shows as a still.
  useEffect(() => {
    videos.current.forEach((video, index) => {
      if (!video) return;
      if (index !== chosen || !inView || reducedMotion) {
        video.pause();
        return;
      }
      video.muted = true;
      // Fails only when paused again before it starts. Nothing to recover.
      video.play().catch(() => {});
    });
  }, [chosen, inView, reducedMotion]);

  function choose(index: number) {
    const from = videos.current[chosen];
    const to = videos.current[index];
    // All three clips are the same take. Carrying the time across makes
    // the wood change under the notes without the phrase starting over.
    if (from && to) to.currentTime = from.currentTime;
    setChosen(index);
  }

  return (
    <div>
      <div
        ref={stage}
        // The clips are 1812 by 504, and their corners match the app's stage.
        className="relative aspect-[1812/504] overflow-hidden rounded-[1.5%/5.4%] shadow-[0_40px_100px_rgba(0,0,0,0.6)]"
      >
        {necks.map((neck, index) => (
          <video
            key={neck.id}
            ref={(element) => {
              videos.current[index] = element;
            }}
            aria-hidden={index !== chosen}
            aria-label={`A bass warm-up scrolling along the ${neck.name.toLowerCase()} board.`}
            className={`absolute inset-0 size-full transition-opacity duration-500 ${index === chosen ? "opacity-100" : "opacity-0"}`}
            poster={`/media/neck-${neck.id}.jpg`}
            // The two hidden boards start loading once the section is
            // reached, so a switch does not wait on the network.
            preload={inView ? "auto" : "none"}
            muted
            loop
            playsInline
          >
            <source src={`/media/neck-${neck.id}.mp4`} type="video/mp4" />
          </video>
        ))}
      </div>
      <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
        {necks.map((neck, index) => (
          <button
            key={neck.id}
            type="button"
            aria-pressed={index === chosen}
            onClick={() => choose(index)}
            className="inline-flex h-11 cursor-pointer items-center gap-2.5 rounded-xl border border-transparent px-4 text-sm font-medium text-quiet transition-colors hover:text-cream aria-pressed:border-gold aria-pressed:bg-panel-lit aria-pressed:text-cream"
          >
            <span
              aria-hidden
              className="size-3.5 rounded-full border border-line-strong"
              style={{ backgroundColor: neck.wood }}
            />
            {neck.name}
          </button>
        ))}
      </div>
      <p className="mt-4 text-center text-sm text-quiet">{necks[chosen].note}</p>
    </div>
  );
}
