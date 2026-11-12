import { DownloadButton } from "@/components/download-button";

const links = [
  { href: "#scoring", label: "Scoring" },
  { href: "#bass", label: "Bass" },
  { href: "#practice", label: "Practice" },
  { href: "#platforms", label: "Platforms" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-white/5 bg-room/85 backdrop-blur-xl">
      <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between px-6">
        <a href="#top" className="font-serif text-[1.7rem] leading-none text-cream">
          Riffster
        </a>
        <nav aria-label="Sections" className="hidden items-center gap-8 md:flex">
          {links.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm text-quiet transition-colors hover:text-cream"
            >
              {link.label}
            </a>
          ))}
        </nav>
        <DownloadButton size="small" />
      </div>
    </header>
  );
}
