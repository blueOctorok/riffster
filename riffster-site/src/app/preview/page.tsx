import type { Metadata } from "next";

import { LandingPage } from "@/components/landing-page";

export const metadata: Metadata = {
  title: "Riffster — play the line, the app hears it",
  description:
    "A practice app for a real bass. Notes slide along the neck, you play them, and each one is marked for pitch and timing. Out now for Windows, with iPhone and Android on the way.",
  robots: { index: false, follow: false },
};

/** Shelved on purpose. The public homepage is the short early page until the product is ready. */
export default function Preview() {
  return <LandingPage />;
}
