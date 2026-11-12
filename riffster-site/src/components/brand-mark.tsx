import Image from "next/image";

/** The dog. It always sits with the name, so screen readers skip it. */
export function BrandMark({ size }: { size: number }) {
  return <Image src="/brand/riffster-mark.png" alt="" width={size} height={size} />;
}
