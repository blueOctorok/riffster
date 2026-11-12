import type { Metadata } from "next";
import { Instrument_Sans, Instrument_Serif } from "next/font/google";

import "./globals.css";

const sans = Instrument_Sans({
  subsets: ["latin"],
  variable: "--font-instrument-sans",
});

const serif = Instrument_Serif({
  subsets: ["latin"],
  weight: "400",
  style: ["normal", "italic"],
  variable: "--font-instrument-serif",
});

export const metadata: Metadata = {
  title: "Riffster — play the line, the app hears it",
  description:
    "A practice app for a real bass. Notes slide along the neck, you play them, and each one is marked for pitch and timing. Out now for Windows, with iPhone and Android on the way.",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${sans.variable} ${serif.variable} h-full motion-safe:scroll-smooth`}
    >
      <body className="flex min-h-full flex-col bg-room font-sans text-cream antialiased">
        {children}
      </body>
    </html>
  );
}
