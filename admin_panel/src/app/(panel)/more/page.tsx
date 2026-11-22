import Link from "next/link";
import { Suspense } from "react";
import { NavCount } from "@/components/shell/NavCount";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { sidebar } from "@/lib/nav";

export const metadata = { title: "আরও" };

/** Mobile "আরও" tab: every module not in the bottom bar. */
export default function MorePage() {
  const inBottom = new Set(["/dashboard", "/sales", "/inventory", "/sellers"]);
  return (
    <>
      <Topbar title="আরও" />
      <main className="ct">
        {sidebar.map((g) => {
          const items = g.items.filter((i) => !inBottom.has(i.href));
          if (!items.length) return null;
          return (
            <div key={g.title}>
              <div className="mu" style={{ fontWeight: 600, padding: "2px 4px 6px" }}>{g.title}</div>
              <div className="mg">
                {items.map((i) => (
                  <Link key={i.href} className="mi" href={i.href}>
                    <span className="ic" style={{ background: "#E3F3EA", color: "#168447", width: 36, height: 36 }}><Icon name={i.icon} size={18} /></span>
                    <span className="fx">{i.label}</span>
                    <Suspense fallback={<Icon name="chev" size={18} color="#8A968F" />}><NavCount href={i.href} /></Suspense>
                  </Link>
                ))}
              </div>
            </div>
          );
        })}
        <div className="mg">
          <Link className="mi" href="/account"><span className="ic" style={{ background: "#ECEFED", color: "#45524A", width: 36, height: 36 }}><Icon name="key" size={18} /></span><span className="fx">প্রোফাইল ও নিরাপত্তা</span></Link>
          <Link className="mi" href="/login" style={{ color: "#A92F2F" }}><span className="ic" style={{ background: "#FBE5E5", color: "#A92F2F", width: 36, height: 36 }}><Icon name="logout" size={18} /></span><span className="fx">লগআউট</span></Link>
        </div>
      </main>
    </>
  );
}
