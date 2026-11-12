import { windowsBuild } from "@/lib/release";

const sizes = {
  large: "h-13 gap-3 px-7 text-base",
  small: "h-9 gap-2 px-4 text-sm",
};

export function DownloadButton({ size = "large" }: { size?: keyof typeof sizes }) {
  return (
    <a
      href={windowsBuild.href}
      download
      className={`button-gold inline-flex items-center rounded-full font-semibold ${sizes[size]}`}
    >
      <svg
        aria-hidden
        viewBox="0 0 16 16"
        className="size-4"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M8 2v8m0 0 3-3m-3 3L5 7M3 13h10" />
      </svg>
      Download for Windows
    </a>
  );
}
