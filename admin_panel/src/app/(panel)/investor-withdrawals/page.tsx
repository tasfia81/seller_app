import { Topbar } from "@/components/shell/Topbar";
import { Kpi } from "@/components/ui/bits";
import { bnDigits, money } from "@/lib/format";
import { activeCapital, investors, withdrawals } from "@/lib/investors";
import { WithdrawalsView } from "./WithdrawalsView";

export const metadata = { title: "মূলধন ফেরত" };

export default function InvestorWithdrawalsPage() {
  const pending = withdrawals.filter((w) => w.status === "pending");
  const approved = withdrawals.filter((w) => w.status === "approved");
  const paid = withdrawals.filter((w) => w.status === "paid");
  const rows = withdrawals.map((w) => {
    const inv = investors.find((i) => i.id === w.investorId)!;
    return { ...w, name: inv.name, capital: activeCapital(inv), uninvested: inv.uninvested, via: inv.capitalVia };
  });
  return (
    <>
      <Topbar title="মূলধন ফেরতের অনুরোধ" />
      <main className="ct">
        <div className="kpis">
          <Kpi label="সিদ্ধান্ত বাকি" value={`${bnDigits(pending.length)}টি`} note={money(pending.reduce((s, w) => s + w.amount, 0))} tone="warn" />
          <Kpi label="অনুমোদিত, পেমেন্ট বাকি" value={`${bnDigits(approved.length)}টি`} note={money(approved.reduce((s, w) => s + w.amount, 0))} />
          <Kpi label="এ মাসে ফেরত দেওয়া" value={money(paid.reduce((s, w) => s + w.amount, 0))} note={`${bnDigits(paid.length)} জনকে`} />
        </div>
        <WithdrawalsView rows={rows} />
      </main>
    </>
  );
}
