import Link from "next/link";
import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { EmptyState, Kpi } from "@/components/ui/bits";
import { EXPENSE_CATEGORY_LABELS } from "@/lib/api/labels";
import { api, load } from "@/lib/api/server";
import type { ApiExpenseList, ApiProduct, ApiSellerRow } from "@/lib/api/types";
import { bnDate, money } from "@/lib/format";
import { ExpenseForm } from "./ExpenseForm";

export const metadata = { title: "খরচ" };

const PERIODS = [
  { id: "today", label: "আজ" },
  { id: "last7", label: "৭ দিন" },
  { id: "month", label: "এই মাস" },
] as const;
type P = (typeof PERIODS)[number]["id"];

export default function ExpensesPage(props: PageProps<"/expenses">) {
  return (
    <>
      <Topbar title="খরচ" />
      <main className="ct">
        <Suspense fallback={<Skeleton rows={6} />}>
          <ExpensesData searchParams={props.searchParams} />
        </Suspense>
      </main>
    </>
  );
}

async function ExpensesData({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const period: P = PERIODS.some((p) => p.id === sp.period) ? (sp.period as P) : "month";
  const cat = typeof sp.category === "string" && sp.category in EXPENSE_CATEGORY_LABELS ? sp.category : "";
  const q = new URLSearchParams({ period });
  if (cat) q.set("category", cat);
  const r = await load(() => Promise.all([api.get<ApiExpenseList>(`/admin/expenses?${q}`), api.get<ApiSellerRow[]>("/admin/sellers"), api.get<ApiProduct[]>("/admin/products")]));
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/expenses" />;
  const [ex, sellers, products] = r.data;
  const sellerName = Object.fromEntries(sellers.map((s) => [s.id, s.name]));
  const productName = Object.fromEntries(products.map((p) => [p.id, p.name]));
  const top = Object.entries(ex.by_category).sort((a, b) => b[1] - a[1]).slice(0, 4);
  const link = (p: string, c: string) => `/expenses?period=${p}${c ? `&category=${c}` : ""}`;

  return (
    <>
      <div className="sh">
        <div className="pills" role="group" aria-label="সময়">
          {PERIODS.map((p) => <Link key={p.id} href={link(p.id, cat)} className={`pill${period === p.id ? " on" : ""}`} style={{ textDecoration: "none" }}>{p.label}</Link>)}
        </div>
        <div className="pills" role="group" aria-label="ক্যাটাগরি">
          <Link href={link(period, "")} className={`pill${!cat ? " on" : ""}`} style={{ textDecoration: "none" }}>সব</Link>
          {Object.entries(EXPENSE_CATEGORY_LABELS).map(([id, l]) => <Link key={id} href={link(period, id)} className={`pill${cat === id ? " on" : ""}`} style={{ textDecoration: "none" }}>{l}</Link>)}
        </div>
      </div>
      <div className="kpis">
        <Kpi label="মোট খরচ" value={money(ex.total)} />
        {top.map(([c, v]) => <Kpi key={c} label={EXPENSE_CATEGORY_LABELS[c] ?? c} value={money(v)} />)}
      </div>
      <div className="two">
        <div className="a">
          <div className="tw">
            {ex.items.length === 0 ? (
              <EmptyState icon="receipt" title="এই সময়ে কোনো খরচ নেই" text="ডান পাশের ফর্ম থেকে খরচ যোগ করুন।" />
            ) : (
              <table style={{ minWidth: 720 }}>
                <thead><tr><th>তারিখ</th><th>ক্যাটাগরি</th><th>বিবরণ</th><th>যার জন্য</th><th className="n">টাকা</th><th>রেকর্ড করেছেন</th></tr></thead>
                <tbody>
                  {ex.items.map((e) => (
                    <tr key={e.id}>
                      <td>{bnDate(e.date)}</td>
                      <td><span className="ch nu">{EXPENSE_CATEGORY_LABELS[e.category] ?? e.category}</span></td>
                      <td>{e.description}</td>
                      <td>{[e.seller_id && sellerName[e.seller_id], e.product_id && productName[e.product_id]].filter(Boolean).join(" · ") || "—"}</td>
                      <td className="n"><b>{money(e.amount)}</b></td>
                      <td>{e.recorded_by}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
        <div className="b">
          <ExpenseForm sellers={sellers} products={products} />
        </div>
      </div>
    </>
  );
}
