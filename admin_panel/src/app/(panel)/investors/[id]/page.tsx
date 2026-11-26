import { Topbar } from "@/components/shell/Topbar";
import { KV, Note } from "@/components/ui/bits";
import { ApiForm } from "@/components/ui/ApiForm";
import { api, load } from "@/lib/api/server";
import { bnDate, money } from "@/lib/format";
import { submitOperation } from "../../operational-actions";

type Investor = { id: string; name: string; code: string; mobile: string; nid_masked: string; status: string;
  status_label: string; preference: string; terms: { share_percent: number; payout_day: number; notice_days: number };
  payout: { method_label: string; account_masked: string }; nominee: { name: string; relation: string; mobile: string };
  position: { active_capital: number; in_stock: number; uninvested: number; profit_total: number };
  holdings: { lot_id: string; product_name: string; batch: string; invested: number; share: number }[];
  transactions: { id: string; label: string; amount: number; receipt: string; at: string }[];
  withdrawals: { id: string; amount: number; status_label: string }[];
};

export default async function InvestorProfilePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const result = await load(() => api.get<Investor>(`/admin/investors/${encodeURIComponent(id)}`));
  const row = result.data;
  return <>
    <Topbar title={row?.name ?? "বিনিয়োগকারী"} back="/investors" />
    <main className="ct">{!row ? <Note kind="warn">{result.error}</Note> : <>
      <div className="two">
        <section className="cd a">
          <h2 className="h2">প্রোফাইল · {row.code}</h2>
          <KV label="অবস্থা">{row.status_label}</KV><KV label="মোবাইল">{row.mobile}</KV><KV label="NID">{row.nid_masked}</KV>
          <KV label="পরিশোধের মাধ্যম">{row.payout.method_label} {row.payout.account_masked}</KV>
          <KV label="নমিনি">{row.nominee.name} · {row.nominee.relation} · {row.nominee.mobile}</KV>
          <KV label="সক্রিয় মূলধন">{money(row.position.active_capital)}</KV>
          <KV label="স্টকে খাটছে">{money(row.position.in_stock)}</KV>
          <KV label="খাটেনি">{money(row.position.uninvested)}</KV>
          <KV label="মোট লাভ">{money(row.position.profit_total)}</KV>
          <ApiForm label="অ্যাকাউন্টের অবস্থা বদলান" action={submitOperation.bind(null, "investor-status", id)} confirm="অ্যাকাউন্টের অবস্থা বদলাবেন?">
            <input type="hidden" name="status" value={row.status === "suspended" ? "active" : "suspended"} />
            <label>কারণ<input className="in" name="reason" minLength={3} required /></label>
          </ApiForm>
        </section>
        <section className="cd b">
          <h2 className="h2">চুক্তির শর্ত</h2>
          <ApiForm label="শর্ত সংরক্ষণ" action={submitOperation.bind(null, "investor-terms", id)}>
            <label>লাভের ভাগ (%)<input className="in" name="share_percent" type="number" min="0.01" max="99.99" step="0.01" required defaultValue={row.terms.share_percent} /></label>
            <label>পরিশোধের দিন<input className="in" name="payout_day" type="number" min={1} max={28} required defaultValue={row.terms.payout_day} /></label>
            <label>নোটিশের দিন<input className="in" name="notice_days" type="number" min={0} max={180} required defaultValue={row.terms.notice_days} /></label>
          </ApiForm>
        </section>
      </div>
      <section className="cd"><h2 className="h2">পণ্য ও ব্যাচ</h2>
        {row.holdings.map((holding) => <KV key={holding.lot_id} label={`${holding.product_name} · ${holding.batch}`}>{money(holding.invested)} · লাভ {money(holding.share)}</KV>)}
      </section>
      <section className="cd"><h2 className="h2">লেনদেন</h2>
        {row.transactions.map((tx) => <KV key={tx.id} label={`${tx.label} · ${tx.receipt} · ${bnDate(tx.at)}`}>{money(tx.amount)}</KV>)}
      </section>
      <section className="cd"><h2 className="h2">মূলধন ফেরত</h2>
        {row.withdrawals.map((wd) => <KV key={wd.id} label={wd.status_label}>{money(wd.amount)}</KV>)}
      </section>
    </>}</main>
  </>;
}
