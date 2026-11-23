"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { Icon } from "@/components/ui/Icon";
import { bnDigits } from "@/lib/format";
import { bottomNav, sidebar, sidebarBottom, sidebarTop, type NavItem } from "@/lib/nav";
import { useNavCounts } from "./useNavCounts";

const isActive = (pathname: string, href: string) => pathname === href || pathname.startsWith(`${href}/`);
const groupOf = (pathname: string) => sidebar.find((g) => g.items.some((i) => isActive(pathname, i.href)))?.id ?? null;
const badge = (n: number | undefined) => (n ? bnDigits(n > 99 ? "99+" : n) : null);

function NavLink({ item, pathname, count, sub }: { item: NavItem; pathname: string; count?: number; sub?: boolean }) {
  const on = isActive(pathname, item.href);
  return (
    <Link href={item.href} className={`sb-link${sub ? " sub" : ""}${on ? " on" : ""}`} aria-current={on ? "page" : undefined}>
      <Icon name={item.icon} size={sub ? 17 : 18} />
      <span>{item.label}</span>
      {count ? <span className="sb-badge">{badge(count)}</span> : null}
    </Link>
  );
}

/**
 * Desktop menu: a few always-visible links plus collapsible categories. Only one
 * category is open at a time (the one holding the current page opens itself), so
 * the menu stays short. A collapsed category shows the total of its badges.
 */
export function Sidebar({ footer }: { footer?: React.ReactNode }) {
  const pathname = usePathname();
  const counts = useNavCounts();
  const [query, setQuery] = useState("");
  // Follow navigation: when the page changes, open the category it belongs to.
  const [state, setState] = useState(() => ({ path: pathname, open: groupOf(pathname) }));
  if (state.path !== pathname) {
    const g = groupOf(pathname);
    setState({ path: pathname, open: g ?? state.open });
  }
  const toggle = (id: string) => setState((s) => ({ ...s, open: s.open === id ? null : id }));

  const q = query.trim().toLowerCase();
  const all = [...sidebarTop, ...sidebar.flatMap((g) => g.items), ...sidebarBottom];
  const results = q ? all.filter((i) => i.label.toLowerCase().includes(q)) : [];

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

      <div className="sb-search">
        <Icon name="search" size={16} />
        <label htmlFor="sb-q" style={{ position: "absolute", left: -9999 }}>মেনু খুঁজুন</label>
        <input id="sb-q" type="search" placeholder="মেনু খুঁজুন…" value={query} onChange={(e) => setQuery(e.target.value)} onKeyDown={(e) => e.key === "Escape" && setQuery("")} />
      </div>

      {q ? (
        <div className="sb-list">
          {results.length ? results.map((i) => <NavLink key={i.href} item={i} pathname={pathname} count={counts[i.href]} />) : <div className="sb-empty">কিছু পাওয়া যায়নি</div>}
        </div>
      ) : (
        <div className="sb-list">
          {sidebarTop.map((i) => <NavLink key={i.href} item={i} pathname={pathname} count={counts[i.href]} />)}
          {sidebar.map((g) => {
            const open = state.open === g.id;
            const total = g.items.reduce((a, i) => a + (counts[i.href] ?? 0), 0);
            const here = g.items.some((i) => isActive(pathname, i.href));
            return (
              <div key={g.id} className={`sb-cat${open ? " open" : ""}`}>
                <button type="button" className={`sb-gh${here ? " here" : ""}`} aria-expanded={open} aria-controls={`sb-g-${g.id}`} onClick={() => toggle(g.id)}>
                  <Icon name={g.icon} size={18} />
                  <span>{g.title}</span>
                  {!open && total ? <span className="sb-badge">{badge(total)}</span> : null}
                  <span className="sb-chev" aria-hidden="true"><Icon name="chev" size={15} /></span>
                </button>
                <div id={`sb-g-${g.id}`} className="sb-gbody" inert={!open}>
                  <div>
                    {g.items.map((i) => <NavLink key={i.href} item={i} pathname={pathname} count={counts[i.href]} sub />)}
                  </div>
                </div>
              </div>
            );
          })}
          <div className="sb-sep" />
          {sidebarBottom.map((i) => <NavLink key={i.href} item={i} pathname={pathname} count={counts[i.href]} />)}
        </div>
      )}
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
