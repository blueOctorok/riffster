import type { Metadata } from "next";

import { EarlyPage } from "@/components/early-page";

export const metadata: Metadata = {
  title: "Riffster — in development",
  description:
    "Riffster is a practice app for bass and guitar, still in development. Download the early Windows build and try it.",
};

export default function Home() {
  return <EarlyPage />;
}
