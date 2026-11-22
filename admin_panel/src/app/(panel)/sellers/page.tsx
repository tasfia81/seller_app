import Link from "next/link";
import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { Kpi } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import type { ApiSellerRow } from "@/lib/api/types";
import { bnDigits, money } from "@/lib/format";
import { SellersTable } from "./SellersTable";

export const metadata = { title: "সেলার" };

export default function SellersPage() {
  return (
    <>
      <Topbar title="সেলার">
        <Link className="btn o" href="/applications">আবেদন</Link>
      </Topbar>
      <main className="ct">
        <Suspense fallback={<Skeleton rows={6} />}>
          <SellersData />
        </Suspense>
      </main>
    </>
  );
}

async function SellersData() {
  const r = await load(() => api.get<ApiSellerRow[]>("/admin/sellers"));
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/sellers" />;
  const sellers = r.data;
  return (
    <>
      <div className="kpis">
        <Kpi label="মোট সেলার" value={bnDigits(sellers.length)} />
        <Kpi label="সক্রিয়" value={bnDigits(sellers.filter((s) => s.status === "active").length)} tone="good" />
        <Kpi label="স্থগিত" value={bnDigits(sellers.filter((s) => s.status === "suspended").length)} tone="bad" />
        <Kpi label="সেলারদের হাতে বাকি ক্যাশ" value={money(sellers.reduce((a, s) => a + s.cash_due, 0))} tone="warn" />
      </div>
      <SellersTable items={sellers} />
    </>
  );
}
