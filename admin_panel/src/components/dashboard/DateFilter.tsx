import Link from "next/link";

export const PERIODS = [
  { id: "today", label: "আজ" },
  { id: "yesterday", label: "গতকাল" },
  { id: "last7", label: "৭ দিন" },
  { id: "month", label: "এই মাস" },
] as const;

export type Period = (typeof PERIODS)[number]["id"];

export function parsePeriod(v: string | string[] | undefined): Period {
  return PERIODS.some((p) => p.id === v) ? (v as Period) : "today";
}

/** Period filter as links (?period=…), so the server renders the right numbers. */
export function DateFilter({ value, basePath }: { value: Period; basePath: string }) {
  return (
    <div className="pills" role="group" aria-label="সময় বাছুন">
      {PERIODS.map((p) => (
        <Link key={p.id} href={`${basePath}?period=${p.id}`} className={`pill${value === p.id ? " on" : ""}`} aria-current={value === p.id ? "true" : undefined} style={{ textDecoration: "none" }}>
          {p.label}
        </Link>
      ))}
    </div>
  );
}
