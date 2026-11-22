"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Icon } from "@/components/ui/Icon";
import { bottomNav, sidebar } from "@/lib/nav";

const isActive = (pathname: string, href: string) => pathname === href || pathname.startsWith(`${href}/`);

export function Sidebar({ footer }: { footer?: React.ReactNode }) {
  const pathname = usePathname();
  return (
    <nav className="sb" aria-label="অ্যাডমিন মেনু">
      <div className="sb-brand">
        <span className="sb-logo">
          <Icon name="bag" />
        </span>
        <div>
          <div style={{ fontSize: 15, fontWeight: 700, color: "#fff" }}>স্ট্রিট সেলস</div>
          <div style={{ fontSize: 11.5, color: "#9cc9ae" }}>অ্যাডমিন প্যানেল</div>
        </div>
      </div>
      {sidebar.map((group) => (
        <div key={group.title}>
          <div className="sb-group">{group.title}</div>
          {group.items.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`sb-link${isActive(pathname, item.href) ? " on" : ""}`}
              aria-current={isActive(pathname, item.href) ? "page" : undefined}
            >
              <Icon name={item.icon} size={18} />
              <span>{item.label}</span>
              {item.badge ? <span className="sb-badge">{item.badge}</span> : null}
            </Link>
          ))}
        </div>
      ))}
      {footer}
    </nav>
  );
}

export function BottomNav() {
  const pathname = usePathname();
  return (
    <nav className="bn" aria-label="প্রধান মেনু">
      {bottomNav.map((item) => {
        const on = isActive(pathname, item.href);
        return (
          <Link key={item.href} href={item.href} className={on ? "on" : undefined} aria-current={on ? "page" : undefined}>
            <span>
              <Icon name={item.icon} size={22} />
            </span>
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
