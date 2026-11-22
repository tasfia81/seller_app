import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { Kpi } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import type { ApiPayoutsOverview } from "@/lib/api/types";
import { money } from "@/lib/format";
import { PayoutsView } from "./PayoutsView";

export const metadata = { title: "সেলার পেমেন্ট" };

export default function PayoutsPage() {
  return (
    <>
      <Topbar title="সেলার পেমেন্ট" />
      <main className="ct">
        <Suspense fallback={<Skeleton rows={6} />}>
          <PayoutsData />
        </Suspense>
      </main>
    </>
  );
}

async function PayoutsData() {
  const r = await load(() => api.get<ApiPayoutsOverview>("/admin/payouts"));
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/payouts" />;
  const t = r.data.totals;
  return (
    <>
      <div className="kpis">
        <Kpi label="সেলারদের মোট অর্জিত আয়" value={money(t.earned)} />
        <Kpi label="অনুমোদিত" value={money(t.approved)} />
        <Kpi label="পরিশোধিত" value={money(t.paid)} tone="good" />
        <Kpi label="বাকি পেমেন্ট" value={money(t.outstanding)} tone="warn" />
      </div>
      <PayoutsView data={r.data} />
    </>
  );
}
