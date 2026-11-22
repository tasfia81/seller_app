import Link from "next/link";
import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { Chip, EmptyState, Kpi } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import type { ApiInventory, ApiMovement, ApiProduct, ApiSellerRow } from "@/lib/api/types";
import { bnDateTime, bnDigits, money } from "@/lib/format";
import { StockReceiptForm } from "./StockReceiptForm";

export const metadata = { title: "মূল স্টক" };

const KIND: Record<ApiMovement["kind"], [string, "ok" | "inf" | "nu" | "wa" | "er"]> = {
  receipt: ["স্টক গ্রহণ", "ok"],
  assignment: ["সেলারকে বরাদ্দ", "inf"],
  sale: ["বিক্রি", "nu"],
  return: ["সেলারের ফেরত", "wa"],
  damage: ["ক্ষতি", "er"],
  transfer_out: ["ফেরত ডাকা/হস্তান্তর", "wa"],
  adjustment: ["সংশোধন", "nu"],
};

export default function InventoryPage() {
  return (
    <>
      <Topbar title="মূল স্টক">
        <Link className="btn o hide-m" href="/assignments/new">সেলারকে দিন</Link>
      </Topbar>
      <main className="ct">
        <Suspense fallback={<Skeleton rows={6} />}>
          <InventoryData />
        </Suspense>
      </main>
    </>
  );
}

async function InventoryData() {
  const r = await load(() =>
    Promise.all([
      api.get<ApiInventory>("/admin/inventory"),
      api.get<ApiMovement[]>("/admin/inventory/movements?limit=30"),
      api.get<ApiProduct[]>("/admin/products"),
      api.get<ApiSellerRow[]>("/admin/sellers"),
    ]),
  );
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/inventory" />;
  const [inv, moves, products, sellers] = r.data;
  const names = new Map(sellers.map((s) => [s.id, s.name]));
  const place = (x: string) => {
    if (x === "warehouse") return "গুদাম";
    if (x === "customer") return "কাস্টমার";
    if (x === "damaged") return "ক্ষতিগ্রস্ত";
    if (x === "correction") return "সংশোধন";
    if (x.startsWith("transit→")) return `পথে → ${names.get(x.slice(8)) ?? "সেলার"}`;
    return names.get(x) ?? x;
  };
  const t = inv.totals;

  return (
    <>
      <div className="kpis">
        <Kpi label="মোট স্টক" value={bnDigits(t.total)} note="গুদাম + সেলারদের কাছে + হস্তান্তর বাকি" />
        <Kpi label="সেলারদের কাছে" value={bnDigits(t.with_sellers)} />
        <Kpi label="গুদামে বরাদ্দযোগ্য" value={bnDigits(t.warehouse)} tone="good" />
        <Kpi label="হস্তান্তর বাকি" value={bnDigits(t.reserved)} tone="info" />
        <Kpi label="ক্ষতিগ্রস্ত" value={bnDigits(t.damaged)} tone="bad" />
        <Kpi label="কম বা শেষ স্টকের পণ্য" value={bnDigits(t.low_stock_products)} tone="warn" />
      </div>
      <div className="two">
        <div className="a">
          <h2 className="h2">পণ্যভিত্তিক স্টক</h2>
          {inv.products.length ? (
            <div className="tw">
              <table style={{ minWidth: 720 }}>
                <thead><tr><th>পণ্য</th><th className="n">গুদামে</th><th className="n">সেলারদের কাছে</th><th className="n">হস্তান্তর বাকি</th><th className="n">ক্ষতিগ্রস্ত</th><th className="n">স্টকের মূল্য (ক্রয়)</th></tr></thead>
                <tbody>
                  {inv.products.map((p) => (
                    <tr key={p.product_id}>
                      <td>
                        <b style={{ fontWeight: 600 }}>{p.name}</b> {p.warehouse <= 0 ? <Chip tone="er">শেষ</Chip> : p.low ? <Chip tone="wa">কম স্টক</Chip> : null}
                        {p.by_variant.some((v) => v.variant) ? (
                          <div className="mu">{p.by_variant.filter((v) => v.variant).map((v) => `${v.variant}: ${bnDigits(v.warehouse)}`).join(" · ")}</div>
                        ) : null}
                      </td>
                      <td className="n" style={p.low ? { color: "#85560C", fontWeight: 600 } : undefined}>{bnDigits(p.warehouse)} {p.unit_label}</td>
                      <td className="n">{bnDigits(p.with_sellers)}</td>
                      <td className="n">{bnDigits(p.reserved)}</td>
                      <td className="n">{bnDigits(p.damaged)}</td>
                      <td className="n">{money(p.stock_value)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="cd"><EmptyState icon="box" title="এখনো কোনো পণ্য নেই" text="আগে পণ্য যোগ করুন, তারপর ডান পাশ থেকে স্টক গ্রহণ করুন।" /></div>
          )}
          <section>
            <h2 className="h2" style={{ marginBottom: 10 }}>সাম্প্রতিক আসা-যাওয়া</h2>
            {moves.length ? (
              <div className="tw">
                <table style={{ minWidth: 820 }}>
                  <thead><tr><th>সময়</th><th>পণ্য</th><th>ধরন</th><th className="n">পরিমাণ</th><th>কোথা থেকে → কোথায়</th><th>রেফারেন্স</th><th>করেছেন</th></tr></thead>
                  <tbody>
                    {moves.map((m) => (
                      <tr key={m.id}>
                        <td>{bnDateTime(m.at)}</td>
                        <td>{m.product_name}</td>
                        <td><Chip tone={KIND[m.kind]?.[1] ?? "nu"}>{KIND[m.kind]?.[0] ?? m.kind}</Chip></td>
                        <td className="n">{bnDigits(m.qty)}</td>
                        <td>{place(m.source)} → {place(m.destination)}</td>
                        <td className="mu">{m.ref}</td>
                        <td>{m.by}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="cd"><EmptyState icon="history" title="এখনো কোনো আসা-যাওয়া নেই" /></div>
            )}
          </section>
        </div>
        <div className="b">
          <StockReceiptForm products={products.filter((p) => p.active)} />
        </div>
      </div>
    </>
  );
}
