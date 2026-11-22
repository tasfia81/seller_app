"use client";

import { Icon } from "@/components/ui/Icon";
import { bnDigits } from "@/lib/format";
import { useNavCounts } from "./useNavCounts";

/** Live count chip for the mobile "আরও" menu; a chevron when nothing is waiting. */
export function NavCount({ href }: { href: string }) {
  const n = useNavCounts()[href];
  return n ? <span className="ch wa">{bnDigits(n > 99 ? "99+" : n)}</span> : <Icon name="chev" size={18} color="#8A968F" />;
}
