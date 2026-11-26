import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { KV, Kpi, Note } from "@/components/ui/bits";
import { Icon } from "@/components/ui/Icon";
import { api, load } from "@/lib/api/server";
import { bnDate, money } from "@/lib/format";

export const metadata = { title: "রিপোর্ট" };

const links = [
  ["বিক্রি", "/sales"], ["সেলার ও পণ্যের পারফরম্যান্স", "/reports/performance"],
  ["স্টকের মূল্য", "/inventory"], ["ক্যাশ সংগ্রহ", "/cash"],
  ["সেলারের আয়", "/payouts"], ["ব্যবসার খরচ", "/expenses"],
];

type Financial = {
  from: string; to: string; revenue: number; refunds_adjustments: number; net_sales: number;
  cost_of_goods_sold: number; gross_profit: number; seller_compensation: number;
  operating_expenses: number; net_profit: number; cash_received: number;
};
type ProductReport = { product_id: string; gross_profit: number };
type Product = { id: string; category_name: string | null };

export default async function ReportsPage({ searchParams }: {
  searchParams: Promise<{ from?: string; to?: string }>;
}) {
  const { from, to } = await searchParams;
  const range = from && to
    ? new URLSearchParams({ period: "custom", date_from: from, date_to: to }).toString()
    : "period=month";
  const result = await load(async () => {
    const [financial, performance, products] = await Promise.all([
      api.get<Financial>(`/admin/reports/financial?${range}`),
      api.get<ProductReport[]>(`/admin/reports/products?${range}`),
      api.get<Product[]>("/admin/products"),
    ]);
    const categories = new Map(products.map((p) => [p.id, p.category_name ?? "অন্যান্য"]));
    const totals = new Map<string, number>();
    for (const product of performance) {
      const category = categories.get(product.product_id) ?? "অন্যান্য";
      totals.set(category, (totals.get(category) ?? 0) + product.gross_profit);
    }
    return { financial, categories: Array.from(totals).sort((a, b) => b[1] - a[1]) };
  });
  const f = result.data?.financial;
  const metrics: [string, number][] = f ? [
    ["মোট বিক্রি", f.revenue], ["রিফান্ড / সমন্বয়", f.refunds_adjustments],
    ["নিট বিক্রি", f.net_sales], ["বিক্রিত পণ্যের ক্রয়মূল্য", f.cost_of_goods_sold],
    ["মোট লাভ", f.gross_profit], ["সেলারদের আয়", f.seller_compensation],
    ["ব্যবসার খরচ", f.operating_expenses], ["নিট লাভ", f.net_profit],
    ["ক্যাশ হাতে এসেছে", f.cash_received],
  ] : [];
  const csv = f ? "\uFEFF" + [["তারিখ থেকে", "তারিখ পর্যন্ত", "হিসাব", "টাকা"],
    ...metrics.map(([label, amount]) => [f.from, f.to, label, amount])].map((row) => row.join(",")).join("\r\n") : "";
  return (
    <>
      <Topbar title="রিপোর্ট">
        {f ? <a className="btn o" download={`financial-${f.from}-${f.to}.csv`}
          href={`data:text/csv;charset=utf-8,${encodeURIComponent(csv)}`}>
          <Icon name="download" size={18} /> CSV
        </a> : null}
      </Topbar>
      <main className="ct">
        <form className="fg" method="get">
          <label>শুরুর তারিখ <input className="in" type="date" name="from" required defaultValue={from ?? f?.from} /></label>
          <label>শেষ তারিখ <input className="in" type="date" name="to" required defaultValue={to ?? f?.to} /></label>
          <button className="btn" type="submit">রিপোর্ট দেখুন</button>
        </form>
        <nav className="fg" aria-label="রিপোর্টের ধরন">
          {links.map(([label, href]) => <Link className="btn o" key={href} href={href}>{label}</Link>)}
        </nav>
        {!f ? <Note kind="warn">{result.error}</Note> : <>
          <div className="kpis">
            <Kpi label="নিট বিক্রি" value={money(f.net_sales)} />
            <Kpi label="মোট লাভ" value={money(f.gross_profit)} />
            <Kpi label="নিট লাভ" value={money(f.net_profit)} tone="good" />
            <Kpi label="ক্যাশ হাতে এসেছে" value={money(f.cash_received)} />
          </div>
          <div className="two">
            <section className="cd a">
              <h2 className="h2">ক্যাটাগরি অনুযায়ী মোট লাভ</h2>
              {result.data?.categories.map(([name, amount]) => <KV key={name} label={name}>{money(amount)}</KV>)}
            </section>
            <section className="cd b">
              <h2 className="h2">আর্থিক সারাংশ</h2>
              <p className="mu">{bnDate(f.from, true)} – {bnDate(f.to, true)}</p>
              {metrics.map(([label, amount]) => <KV key={label} label={label}>{money(amount)}</KV>)}
            </section>
          </div>
        </>}
      </main>
    </>
  );
}
