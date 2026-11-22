import Link from "next/link";
import { Icon } from "@/components/ui/Icon";

/** Shown when the backend refuses or can't be reached. Never shows stale/demo numbers instead. */
export function LoadError({ message, retryHref }: { message: string; retryHref?: string }) {
  return (
    <div className="cd" role="alert" style={{ display: "flex", flexDirection: "column", gap: 10, alignItems: "flex-start" }}>
      <div className="danger" style={{ width: "100%" }}>
        <Icon name="alert" size={18} />
        <span>{message}</span>
      </div>
      {retryHref ? <Link className="btn o sm" href={retryHref}>আবার চেষ্টা করুন</Link> : null}
    </div>
  );
}

/** Grey placeholder blocks while data streams in. */
export function Skeleton({ rows = 3 }: { rows?: number }) {
  return (
    <div className="cd" aria-busy="true" aria-label="লোড হচ্ছে" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} style={{ height: 14, width: `${[45, 75, 60, 85, 50][i % 5]}%`, borderRadius: 7, background: "#E7ECE9" }} />
      ))}
    </div>
  );
}
