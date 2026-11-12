import { BrandMark } from "@/components/brand-mark";
import { DownloadButton } from "@/components/download-button";
import { windowsBuild } from "@/lib/release";

/** The public page while the product is still early. The full marketing page stays at /preview. */
export function EarlyPage() {
  return (
    <main className="flex flex-1 flex-col items-center justify-center px-6 py-24 text-center">
      <BrandMark size={104} />
      <p className="mt-4 font-serif text-5xl text-cream">Riffster</p>
      <h1 className="mt-8 max-w-xl font-serif text-4xl leading-tight text-balance text-cream sm:text-5xl">
        This app is still in development.
      </h1>
      <p className="mt-5 max-w-md text-lg leading-8 text-soft">
        A practice app for bass and guitar. The Windows build is early, and you
        can download it and try it.
      </p>
      <div className="mt-10">
        <DownloadButton />
      </div>
      <p className="mt-5 text-sm text-quiet">
        Windows 10 or 11 · {windowsBuild.size} · Build from {windowsBuild.builtOn}
      </p>
      <p className="mt-3 max-w-sm text-sm leading-6 text-quiet">
        This build is unsigned. If Windows asks, choose More info, then Run
        anyway.
      </p>
    </main>
  );
}
