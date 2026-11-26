import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { KV, Note } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import { bnDate, money } from "@/lib/format";
import { CompensationForm, type CompensationSeller } from "./CompensationForm";

export const metadata = { title: "কমিশন ও আয়" };

type History = { previous: string | null; new: string; effective_from: string; changed_by: string; reason: string; at: string };
type EarningsRow = { seller_id: string; approved: number; earned: number; paid: number; outstanding: number };

export default async function CompensationPage({ searchParams }: { searchParams: Promise<{ seller?: string }> }) {
  const { seller } = await searchParams;
  const loaded = await load(async () => {
    const sellers = (await api.get<CompensationSeller[]>("/admin/sellers")).filter((row) => row.status !== "inactive");
    const selected = sellers.find((row) => row.id === seller) ?? sellers[0];
    if (!selected) return { sellers, selected, history: [], earnings: undefined };
    const id = encodeURIComponent(selected.id);
    const [history, overview] = await Promise.all([
      api.get<History[]>(`/admin/sellers/${id}/compensation/history`),
      api.get<{ sellers: EarningsRow[] }>("/admin/payouts"),
    ]);
    return { sellers, selected, history, earnings: overview.sellers.find((row) => row.seller_id === selected.id) };
  });
  const data = loaded.data;
  return (
    <>
      <Topbar title="কমিশন ও আয়" back="/sellers" />
      <main className="ct">
        {!data ? <Note kind="warn">{loaded.error}</Note> : !data.selected ? <Note>কোনো সেলার পাওয়া যায়নি।</Note> : (
          <div className="two">
            <div className="a"><CompensationForm sellers={data.sellers} selected={data.selected.id} /></div>
            <div className="b">
              <section className="cd">
                <h2 className="h2">আয়ের হিসাব · {data.selected.name}</h2>
                {data.earnings ? <>
                  <KV label="অনুমোদনের অপেক্ষায়">{money(data.earnings.earned - data.earnings.approved)}</KV>
                  <KV label="অনুমোদিত">{money(data.earnings.approved)}</KV>
                  <KV label="পরিশোধিত">{money(data.earnings.paid)}</KV>
                  <KV label="বাকি পাওনা" total>{money(data.earnings.outstanding)}</KV>
                </> : <Note>এই সেলারের আয়ের তথ্য পাওয়া যায়নি।</Note>}
                <Link className="btn o full" href="/payouts">পেমেন্ট দেখুন</Link>
              </section>
              <section className="cd">
                <h2 className="h2">নিয়মের ইতিহাস</h2>
                {data.history.map((entry) => (
                  <div key={`${entry.at}-${entry.effective_from}`} className="tl"><i /><div>
                    <div className="t1">{[entry.previous, entry.new].filter(Boolean).join(" → ")}</div>
                    <div className="mu">{bnDate(entry.effective_from, true)} · {entry.changed_by}</div>
                    <div className="mu">{entry.reason}</div>
                  </div></div>
                ))}
              </section>
            </div>
          </div>
        )}
      </main>
    </>
  );
}
