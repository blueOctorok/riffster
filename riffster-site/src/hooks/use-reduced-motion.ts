"use client";

import { useSyncExternalStore } from "react";

const reducedMotion = "(prefers-reduced-motion: reduce)";

function subscribe(onChange: () => void) {
  const query = window.matchMedia(reducedMotion);
  query.addEventListener("change", onChange);
  return () => query.removeEventListener("change", onChange);
}

/**
 * True when the visitor has asked their device for less movement.
 *
 * The setting lives in the browser, outside React. useSyncExternalStore is
 * React's way to read such a thing: one function to listen for changes, one
 * to read the value now, and one for the server, which cannot know and
 * answers "no".
 */
export function useReducedMotion(): boolean {
  return useSyncExternalStore(
    subscribe,
    () => window.matchMedia(reducedMotion).matches,
    () => false,
  );
}
