"use client";

import { type ReactNode, useRef } from "react";

import { useInView } from "@/hooks/use-in-view";

type RevealProps = {
  children: ReactNode;
  className?: string;
  /** Holds this one back, so a row of cards arrives one after another. */
  delayMs?: number;
};

/** Drifts its children up into place the first time they are scrolled to. */
export function Reveal({ children, className = "", delayMs = 0 }: RevealProps) {
  const box = useRef<HTMLDivElement>(null);
  const shown = useInView(box, { once: true, threshold: 0.1 });
  return (
    <div
      ref={box}
      // The `reveal` class in globals.css fades in when this attribute is present.
      data-shown={shown ? "" : undefined}
      style={{ transitionDelay: `${delayMs}ms` }}
      className={`reveal ${className}`}
    >
      {children}
    </div>
  );
}
