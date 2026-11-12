"use client";

import { type RefObject, useEffect, useState } from "react";

type InViewOptions = {
  /** Stay true after the first sighting. For things that appear once. */
  once?: boolean;
  /** How much of the element must show, from 0 to 1. */
  threshold?: number;
};

/**
 * Says whether the element in [ref] is on screen.
 *
 * The browser does the watching (IntersectionObserver) and calls back only
 * when the answer changes, so nothing here runs while the page scrolls.
 */
export function useInView(
  ref: RefObject<Element | null>,
  { once = false, threshold = 0.2 }: InViewOptions = {},
): boolean {
  const [inView, setInView] = useState(false);

  useEffect(() => {
    const element = ref.current;
    if (!element) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        setInView(entry.isIntersecting);
        if (entry.isIntersecting && once) observer.disconnect();
      },
      { threshold },
    );
    observer.observe(element);
    return () => observer.disconnect();
  }, [ref, once, threshold]);

  return inView;
}
