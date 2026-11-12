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
  title: "Riffster — in development",
  description:
    "Riffster is a practice app for bass and guitar, still in development. Download the early Windows build and try it.",
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
