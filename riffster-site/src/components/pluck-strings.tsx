"use client";

import { useEffect, useRef } from "react";

import { useReducedMotion } from "@/hooks/use-reduced-motion";

/**
 * The four strings, top to bottom as the app draws them. A low string is
 * thicker, swings slower, and rings longer, as on a real bass. The swing
 * speeds are far below the real ones (the low E is 41 times a second),
 * slow enough for an eye to follow.
 */
const strings = [
  { name: "G", thickness: 3.2, swingsPerSecond: 13, ringSeconds: 1.1 },
  { name: "D", thickness: 4.4, swingsPerSecond: 11, ringSeconds: 1.4 },
  { name: "A", thickness: 5.6, swingsPerSecond: 9.5, ringSeconds: 1.7 },
  { name: "E", thickness: 6.8, swingsPerSecond: 8, ringSeconds: 2.1 },
];

/** Where string number `index` sits, as a share of the board's height. */
const stringHeight = (index: number) => (index + 1) / (strings.length + 1);

/** The order the strings pluck themselves in while nobody is touching them. */
const idlePattern = [3, 2, 1, 0, 1, 2];
const idleEveryMs = 1500;

/** Below this many pixels of swing, a string is drawn as still. */
const stillBelow = 0.2;

type Pluck = { atMs: number; reach: number };

/**
 * A bass neck whose strings can be plucked by running the pointer across them.
 *
 * Nothing here is stored per frame. A pluck is two numbers: when it happened
 * and how far the string was pulled. Each frame works the shape out from
 * "now minus then", which is the same trick the app uses for its own effects.
 */
export function PluckStrings() {
  const canvas = useRef<HTMLCanvasElement>(null);
  const reducedMotion = useReducedMotion();

  useEffect(() => {
    const element = canvas.current;
    const pen = element?.getContext("2d");
    if (!element || !pen) return;

    const plucks: Pluck[] = strings.map(() => ({ atMs: 0, reach: 0 }));
    let width = 0;
    let height = 0;
    let frame = 0;
    let lastPointerY: number | null = null;
    let idleStep = 0;
    let onScreen = false;

    /** How far the middle of a string is from rest right now, before the wobble. */
    const swingOf = (index: number, nowMs: number) => {
      const ageSeconds = (nowMs - plucks[index].atMs) / 1000;
      // Three "time constants" in ringSeconds leaves about 5% of the swing.
      return plucks[index].reach * Math.exp((-3 * ageSeconds) / strings[index].ringSeconds);
    };

    /** Traces a string from the nut to the far edge, bowed by `bow` pixels at its middle. */
    const trace = (y: number, bow: number) => {
      pen.beginPath();
      pen.moveTo(0, y);
      for (let x = 12; x <= width; x += 12) {
        // Half a sine wave: zero at both ends, widest in the middle.
        pen.lineTo(x, y + bow * Math.sin((Math.PI * x) / width));
      }
    };

    const draw = (nowMs: number) => {
      pen.clearRect(0, 0, width, height);
      let moving = false;
      strings.forEach((string, index) => {
        const y = height * stringHeight(index);
        const swing = swingOf(index, nowMs);
        const still = Math.abs(swing) < stillBelow;
        const ageSeconds = (nowMs - plucks[index].atMs) / 1000;
        const bow = still
          ? 0
          : swing * Math.cos(2 * Math.PI * string.swingsPerSecond * ageSeconds);
        moving ||= !still;

        // The shadow the string throws on the board.
        trace(y + string.thickness + 3, bow * 0.85);
        pen.lineWidth = string.thickness;
        pen.strokeStyle = "rgb(0 0 0 / 0.45)";
        pen.stroke();

        // A swinging string is a blur between its two extremes.
        if (!still) {
          trace(y, swing);
          for (let x = width; x >= 0; x -= 12) {
            pen.lineTo(x, y - swing * Math.sin((Math.PI * x) / width));
          }
          pen.fillStyle = "rgb(217 211 202 / 0.1)";
          pen.fill();
        }

        trace(y, bow);
        pen.strokeStyle = "#a8a299";
        pen.stroke();
        // Dark dashes over the top read as the wire wound around a bass string.
        pen.setLineDash([1.5, 2]);
        pen.strokeStyle = "rgb(0 0 0 / 0.3)";
        pen.stroke();
        pen.setLineDash([]);
        // The line of light along its upper edge.
        trace(y - string.thickness * 0.22, bow);
        pen.lineWidth = string.thickness * 0.3;
        pen.strokeStyle = "rgb(243 238 230 / 0.85)";
        pen.stroke();
      });
      // The loop stops itself once every string is still, so a quiet
      // board costs nothing.
      frame = moving ? requestAnimationFrame(draw) : 0;
    };

    const pluck = (index: number, reach: number) => {
      plucks[index] = { atMs: performance.now(), reach };
      if (!frame) frame = requestAnimationFrame(draw);
    };

    /** Matches the canvas's pixels to its size on screen, so lines stay sharp. */
    const fit = () => {
      const box = element.getBoundingClientRect();
      const density = window.devicePixelRatio || 1;
      width = box.width;
      height = box.height;
      element.width = Math.round(width * density);
      element.height = Math.round(height * density);
      pen.setTransform(density, 0, 0, density, 0, 0);
      // Resizing wipes a canvas. A running loop redraws it on its next
      // frame, and a still board is redrawn here.
      if (!frame) draw(performance.now());
    };

    const resizeWatch = new ResizeObserver(fit);
    resizeWatch.observe(element);
    if (reducedMotion) {
      // The strings are drawn, and stay still.
      return () => resizeWatch.disconnect();
    }

    const onPointerMove = (event: PointerEvent) => {
      const y = event.clientY - element.getBoundingClientRect().top;
      const previousY = lastPointerY;
      lastPointerY = y;
      if (previousY === null) return;
      strings.forEach((_, index) => {
        const stringY = height * stringHeight(index);
        // The pointer was on one side of the string and is now on the
        // other: it went across. Multiplying the two distances gives a
        // negative number only when their signs differ.
        const crossed = (previousY - stringY) * (y - stringY) < 0;
        if (!crossed) return;
        // A faster pass pulls the string farther, in the pointer's direction.
        const travel = y - previousY;
        pluck(index, Math.sign(travel) * Math.min(18, 6 + Math.abs(travel) * 0.5));
      });
    };
    const onPointerLeave = () => {
      lastPointerY = null;
    };
    /** A tap or a click plucks whichever string is nearest. */
    const onPointerDown = (event: PointerEvent) => {
      const share = (event.clientY - element.getBoundingClientRect().top) / height;
      const nearest = Math.round(share * (strings.length + 1)) - 1;
      pluck(Math.min(strings.length - 1, Math.max(0, nearest)), 14);
    };

    element.addEventListener("pointermove", onPointerMove);
    element.addEventListener("pointerleave", onPointerLeave);
    element.addEventListener("pointerdown", onPointerDown);

    const screenWatch = new IntersectionObserver(([entry]) => {
      onScreen = entry.isIntersecting;
    });
    screenWatch.observe(element);
    // Left alone, the neck plays itself quietly, so it reads as playable.
    const idle = setInterval(() => {
      if (!onScreen || lastPointerY !== null) return;
      pluck(idlePattern[idleStep % idlePattern.length], 9);
      idleStep++;
    }, idleEveryMs);

    return () => {
      cancelAnimationFrame(frame);
      clearInterval(idle);
      resizeWatch.disconnect();
      screenWatch.disconnect();
      element.removeEventListener("pointermove", onPointerMove);
      element.removeEventListener("pointerleave", onPointerLeave);
      element.removeEventListener("pointerdown", onPointerDown);
    };
  }, [reducedMotion]);

  return (
    <div className="board-ebony relative h-72 overflow-hidden border-y border-black/60 shadow-[inset_0_24px_40px_rgba(0,0,0,0.45),inset_0_-24px_40px_rgba(0,0,0,0.45)] sm:h-80">
      <div aria-hidden className="nut-bone absolute inset-y-0 left-0 z-10 w-12 sm:w-16">
        {strings.map((string, index) => (
          <span
            key={string.name}
            className="absolute left-1/2 -translate-1/2 text-sm font-semibold text-ink/80"
            style={{ top: `${stringHeight(index) * 100}%` }}
          >
            {string.name}
          </span>
        ))}
      </div>
      <canvas
        ref={canvas}
        aria-label="Four bass strings. Move across them to pluck them."
        className="absolute inset-y-0 right-0 left-12 h-full w-[calc(100%-3rem)] cursor-crosshair sm:left-16 sm:w-[calc(100%-4rem)]"
      />
    </div>
  );
}
