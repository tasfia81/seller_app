"use client";

import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

let last: Record<string, number> = {};

/** Live badge counts by route; refetched on every navigation and every 30 seconds. */
export function useNavCounts() {
  const pathname = usePathname();
  const [counts, setCounts] = useState(last);
  useEffect(() => {
    let alive = true;
    const load = () =>
      fetch("/api/nav-counts", { cache: "no-store" })
        .then((r) => (r.ok ? r.json() : null))
        .then((c: Record<string, number> | null) => {
          if (alive && c) {
            last = c;
            setCounts(c);
          }
        })
        .catch(() => {});
    load();
    window.addEventListener("admin-live-update", load);
    const timer = setInterval(load, 30_000);
    return () => {
      alive = false;
      clearInterval(timer);
      window.removeEventListener("admin-live-update", load);
    };
  }, [pathname]);
  return counts;
}
