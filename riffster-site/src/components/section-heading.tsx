import type { ReactNode } from "react";

type SectionHeadingProps = {
  /** The small gold capitals over the title. */
  eyebrow: string;
  title: ReactNode;
  children: ReactNode;
  centered?: boolean;
};

/** The label, title, and opening lines every section starts with. */
export function SectionHeading({
  eyebrow,
  title,
  children,
  centered = false,
}: SectionHeadingProps) {
  return (
    <div className={centered ? "mx-auto max-w-2xl text-center" : "max-w-xl"}>
      <p className="text-xs font-semibold tracking-[0.22em] text-gold uppercase">
        {eyebrow}
      </p>
      <h2 className="mt-4 font-serif text-4xl leading-[1.05] text-balance text-cream sm:text-5xl">
        {title}
      </h2>
      <p className="mt-5 text-lg leading-8 text-pretty text-soft">{children}</p>
    </div>
  );
}
