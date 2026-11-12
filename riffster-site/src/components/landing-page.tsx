import { BassSection } from "@/components/bass-section";
import { DownloadSection } from "@/components/download-section";
import { GuitarSection } from "@/components/guitar-section";
import { Hero } from "@/components/hero";
import { NecksSection } from "@/components/necks-section";
import { PlatformsSection } from "@/components/platforms-section";
import { PracticeSection } from "@/components/practice-section";
import { ScoringSection } from "@/components/scoring-section";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";

/** The whole page, top to bottom. Each section is its own file. */
export function LandingPage() {
  return (
    <>
      <SiteHeader />
      <main>
        <Hero />
        <ScoringSection />
        <BassSection />
        <NecksSection />
        <PracticeSection />
        <GuitarSection />
        <PlatformsSection />
        <DownloadSection />
      </main>
      <SiteFooter />
    </>
  );
}
