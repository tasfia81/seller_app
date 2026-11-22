import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { KV, Kpi, Note } from "@/components/ui/bits";
import { ActionButton } from "@/components/ui/feedback";
import { Icon } from "@/components/ui/Icon";
import { dashboard, financialSummary as f } from "@/lib/demo-data";
import { money } from "@/lib/format";

export const metadata = { title: "রিপোর্ট" };

const TYPES: [string, string][] = [
  ["দৈনিক বিক্রি", "/sales"], ["সাপ্তাহিক বিক্রি", "/sales"], ["মাসিক বিক্রি", "/sales"],
  ["সেলারের পারফরম্যান্স", "/reports/performance"], ["পণ্যের পারফরম্যান্স", "/reports/performance"], ["ক্যাটাগরির পারফরম্যান্স", "/reports/performance"],
  ["মোট লাভ", "/reports"], ["আর্থিক সারাংশ", "/reports"], ["স্টকের মূল্য", "/inventory"],
  ["ক্যাশ সংগ্রহ", "/cash"], ["সেলারের আয়", "/payouts"], ["ব্যবসার খরচ", "/expenses"],
];
const MONTHS = [["জুন", 52], ["জুলাই", 60], ["আগস্ট", 66], ["সেপ্টেম্বর", 78], ["অক্টোবর", 90], ["নভেম্বর", 100]] as const;
const CATS = [["জার্সি", 98400], ["টি-শার্ট", 82600], ["প্যান্ট", 39200], ["অ্যাক্সেসরিজ", 12900]] as const;

export default function ReportsPage() {
  const netSales = f.revenue - f.refunds;
  const gross = netSales - f.cogs;
  const net = gross - f.sellerCompensation - f.expenses;
  return (
    <>
      <Topbar title="রিপোর্ট">
        <ActionButton className="btn o" message="ডেমো: সার্ভার চালু হলে Excel বা PDF ফাইল ডাউনলোড হবে।"><Icon name="download" size={18} />এক্সপোর্ট</ActionButton>
      </Topbar>
      <main className="ct">
        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          {["নভেম্বর ২০২৬", "সব সেলার", "সব ক্যাটাগরি", "সব পণ্য"].map((o) => (
            <select key={o} className="in" aria-label={o} style={{ width: "auto", minWidth: 150, height: 38 }}><option>{o}</option></select>
          ))}
        </div>
        <nav style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(170px, 1fr))", gap: 10 }} aria-label="রিপোর্টের ধরন">
          {TYPES.map(([t, href]) => (
            <Link key={t} href={href} className={`card-btn${t === "আর্থিক সারাংশ" ? " on" : ""}`} style={{ textDecoration: "none", fontWeight: 600, fontSize: 13.5, minHeight: 50, justifyContent: "center" }}>{t}</Link>
          ))}
        </nav>
        <div className="kpis">
          <Kpi label="নিট বিক্রি" value={money(netSales)} note={<span style={{ color: "#0F6A38" }}>অক্টোবরের চেয়ে ৮% বেশি</span>} />
          <Kpi label="মোট লাভ" value={money(gross)} note="মার্জিন ২৪%" />
          <Kpi label="নিট লাভ" value={money(net)} note="সব খরচ বাদে" tone="good" />
          <Kpi label="ক্যাশ হাতে এসেছে" value={money(f.cashReceived)} note="এটা লাভ নয়" />
        </div>
        <div className="two">
          <div className="a">
            <section className="cd">
              <div className="sh"><h2 className="h2">মাসভিত্তিক নিট বিক্রি</h2><span className="mu">জুন–নভেম্বর</span></div>
              <div className="chart" role="img" aria-label="ছয় মাসের নিট বিক্রির চার্ট, নভেম্বরে সর্বোচ্চ">
                {MONTHS.map(([m, v]) => <i key={m} className={v === 100 ? "hi" : undefined} style={{ height: `${v}%` }} />)}
              </div>
              <div className="chart-x">{MONTHS.map(([m]) => <span key={m}>{m}</span>)}</div>
            </section>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 8 }}>ক্যাটাগরি অনুযায়ী মোট লাভ</h2>
              <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                {CATS.map(([c, v]) => (
                  <div key={c}>
                    <div className="sh" style={{ fontSize: 13.5 }}><span>{c}</span><b>{money(v)}</b></div>
                    <div className="bar"><i style={{ width: `${(v / CATS[0][1]) * 100}%` }} /></div>
                  </div>
                ))}
              </div>
            </section>
          </div>
          <div className="b">
            <section className="cd">
              <div className="sh" style={{ marginBottom: 6 }}><h2 className="h2">আর্থিক সারাংশ</h2><span className="mu">নভেম্বর ২০২৬</span></div>
              <KV label="মোট বিক্রি">{money(f.revenue)}</KV>
              <div className="kv sub"><span>− রিফান্ড / সমন্বয়</span><span>{money(f.refunds)}</span></div>
              <KV label="নিট বিক্রি" total>{money(netSales)}</KV>
              <div className="kv sub"><span>− বিক্রিত পণ্যের ক্রয়মূল্য</span><span>{money(f.cogs)}</span></div>
              <KV label="মোট লাভ" total>{money(gross)}</KV>
              <div className="kv sub"><span>− সেলারদের আয়</span><span>{money(f.sellerCompensation)}</span></div>
              <div className="kv sub"><span>− ব্যবসার খরচ</span><span>{money(f.expenses)}</span></div>
              <KV label="নিট লাভ" total><span style={{ color: "#0F6A38", fontSize: 18 }}>{money(net)}</span></KV>
              <div style={{ marginTop: 10 }}><Note>হাতে পাওয়া ক্যাশ আর বিক্রি বা লাভ এক নয় — সেলারদের কাছে এখনো {money(dashboard.cashOutstanding)} বাকি।</Note></div>
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
