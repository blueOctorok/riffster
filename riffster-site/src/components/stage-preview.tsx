const strings = [
  { name: "G", top: "22%", thickness: "1px" },
  { name: "D", top: "40%", thickness: "1.5px" },
  { name: "A", top: "58%", thickness: "2px" },
  { name: "E", top: "76%", thickness: "2.5px" },
];

const notes = [
  { fret: "0", top: "76%", left: "28%", color: "bg-cream", ink: "text-ink" },
  { fret: "3", top: "76%", left: "46%", color: "bg-[#f0c43a]", ink: "text-ink" },
  { fret: "0", top: "58%", left: "58%", color: "bg-cream", ink: "text-ink" },
  { fret: "2", top: "58%", left: "72%", color: "bg-[#3ddc6e]", ink: "text-ink" },
  { fret: "0", top: "40%", left: "78%", color: "bg-cream", ink: "text-ink" },
  { fret: "2", top: "40%", left: "88%", color: "bg-[#3ddc6e]", ink: "text-ink" },
];

/** A still picture of the play area, drawn with the app's own colors. */
export function StagePreview() {
  return (
    <div
      aria-hidden
      className="relative h-72 overflow-hidden rounded-3xl border border-line shadow-[0_40px_90px_rgba(0,0,0,0.45)] sm:h-80"
    >
      <div className="absolute inset-0 bg-[linear-gradient(180deg,#3a2e24_0%,#241c16_45%,#1c1612_100%)]" />
      <div className="absolute inset-0 opacity-40 bg-[repeating-linear-gradient(90deg,transparent_0_18px,rgba(255,255,255,0.025)_18px_19px)]" />
      <div className="absolute top-0 bottom-0 left-[7%] w-3 bg-[linear-gradient(90deg,#f3eee6,#d9d0c3)]" />
      <div className="absolute top-0 bottom-0 left-[18%] w-px bg-gold shadow-[0_0_18px_rgba(228,177,90,0.8)]" />
      {["1", "2", "3"].map((bar, index) => (
        <div
          key={bar}
          className="absolute top-0 bottom-0 w-px bg-white/15"
          style={{ left: `${36 + index * 22}%` }}
        >
          <span className="absolute bottom-3 left-2 text-[10px] text-white/30">
            {bar}
          </span>
        </div>
      ))}
      {strings.map((string) => (
        <div key={string.name}>
          <span
            className="absolute left-2 -translate-y-1/2 text-[11px] text-cream/70"
            style={{ top: string.top }}
          >
            {string.name}
          </span>
          <div
            className="absolute right-0 left-[7%] -translate-y-1/2 bg-[linear-gradient(180deg,#d7d2cc,#8d8880)]"
            style={{ top: string.top, height: string.thickness }}
          />
        </div>
      ))}
      {notes.map((note) => (
        <span
          key={`${note.top}-${note.left}`}
          className={`absolute flex size-8 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full text-xs font-medium shadow-[0_6px_16px_rgba(0,0,0,0.35)] ${note.color} ${note.ink}`}
          style={{ top: note.top, left: note.left }}
        >
          {note.fret}
        </span>
      ))}
    </div>
  );
}
