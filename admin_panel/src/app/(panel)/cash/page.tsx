import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { Kpi, Note } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import type { ApiCashOverview, ApiHandover, ApiHandoverStatus } from "@/lib/api/types";
import { money } from "@/lib/format";
import { CashView } from "./CashView";

export const metadata = { title: "ক্যাশ জমা" };

const TABS: ApiHandoverStatus[] = ["pending", "verified", "rejected"];

export default function CashPage(props: PageProps<"/cash">) {
  return (
    <>
      <Topbar title="ক্যাশ জমা" />
      <main className="ct">
        <Suspense fallback={<Skeleton rows={6} />}>
          <CashData searchParams={props.searchParams} />
        </Suspense>
      </main>
    </>
  );
}

async function CashData({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const tab = TABS.includes(sp.tab as ApiHandoverStatus) ? (sp.tab as ApiHandoverStatus) : "pending";
  const r = await load(() => Promise.all([api.get<ApiCashOverview>("/admin/cash"), api.get<ApiHandover[]>("/admin/cash/handovers")]));
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/cash" />;
  const [ov, handovers] = r.data;
  const t = ov.totals;
  return (
    <>
      <div className="kpis">
        <Kpi label="সেলারদের সংগ্রহ করা ক্যাশ" value={money(t.collected)} />
        <Kpi label="যাচাইয়ের অপেক্ষায়" value={money(t.pending_verification)} tone="info" />
        <Kpi label="যাচাই হয়েছে" value={money(t.verified)} tone="good" />
        <Kpi label="সেলারদের কাছে বাকি" value={money(t.due)} tone="warn" />
        <Kpi label="এখনো জমা দেননি" value={money(t.to_submit)} />
      </div>
      <Note>বিকাশ/নগদে কাস্টমার সরাসরি ব্যবসার অ্যাকাউন্টে যে টাকা দিয়েছেন (আজ {money(ov.business_direct_today)}), তা এই হিসাবে নেই — সেটা সেলারের দায় নয়।</Note>
      <CashView items={handovers} sellers={ov.sellers} tab={tab} selectedId={typeof sp.id === "string" ? sp.id : undefined} key={`${tab}-${String(sp.id ?? "")}`} />
    </>
  );
}
