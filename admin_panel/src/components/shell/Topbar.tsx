import Link from "next/link";
import type { ReactNode } from "react";
import { Icon } from "@/components/ui/Icon";

/** Page header: optional back link, title, breadcrumb and right-side actions. */
export function Topbar({ title, back, crumb, children }: { title: string; back?: string; crumb?: { href: string; label: string }; children?: ReactNode }) {
  return (
    <header className="tb">
      {back ? (
        <Link className="ib" href={back} aria-label="ফিরে যান">
          <Icon name="back" />
        </Link>
      ) : null}
      {crumb ? (
        <span className="mu hide-m" style={{ display: "flex", gap: 6 }}>
          <Link href={crumb.href} style={{ textDecoration: "none" }}>{crumb.label}</Link> /
        </span>
      ) : null}
      <h1>{title}</h1>
      <span className="grow" />
      {children}
    </header>
  );
}
