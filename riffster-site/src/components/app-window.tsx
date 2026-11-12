import type { ReactNode } from "react";

/** A Windows window around a clip of the app, lit from above like the app's panels. */
export function AppWindow({ children }: { children: ReactNode }) {
  return (
    <div className="relative">
      {/* The glow the gold playhead would throw on the desk under the window. */}
      <div
        aria-hidden
        className="absolute inset-x-[12%] top-1/2 -bottom-10 -z-10 rounded-[50%] bg-gold/25 blur-3xl"
      />
      <div className="glass relative overflow-hidden rounded-2xl shadow-[0_60px_140px_rgba(0,0,0,0.65)]">
        <div className="flex h-7 items-center justify-between border-b border-black/50 pr-1 pl-3 sm:h-9 sm:pl-4">
          <span className="text-xs text-quiet">Riffster</span>
          <WindowButtons />
        </div>
        {children}
        {/* A slant of light across the glass. It sits over the clip and takes no clicks. */}
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 bg-linear-115 from-white/7 via-transparent via-35% to-transparent"
        />
      </div>
    </div>
  );
}

function WindowButtons() {
  return (
    <svg
      aria-hidden
      viewBox="0 0 108 36"
      className="h-7 w-21 text-quiet sm:h-9 sm:w-27"
      fill="none"
      stroke="currentColor"
      strokeWidth="1"
    >
      <path d="M13 18h10" />
      <rect x="49.5" y="13.5" width="9" height="9" />
      <path d="m85 13 10 10m0-10L85 23" />
    </svg>
  );
}
