import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { Kpi } from "@/components/ui/bits";
import { activeCapital, inStock, investorApplications, investors, withdrawals } from "@/lib/investors";
import { bnDigits, money } from "@/lib/format";
import { InvestorsView } from "./InvestorsView";

export const metadata = { title: "বিনিয়োগকারী" };

export default function InvestorsPage() {
  const active = investors.filter((i) => i.status !== "suspended");
  const capital = active.reduce((s, i) => s + activeCapital(i), 0);
  const stock = active.reduce((s, i) => s + inStock(i), 0);
  const idle = active.reduce((s, i) => s + i.uninvested, 0);
  const due = active.reduce((s, i) => s + i.profitThisMonth, 0);
  const open = withdrawals.filter((w) => w.status === "pending" || w.status === "approved");
  const waiting = investorApplications.filter((a) => a.status !== "approved" && a.status !== "rejected");

  return (
    <>
      <Topbar title="বিনিয়োগকারী">
        <Link className="btn o sm hide-m" href="/investments"><Icon name="plus" size={18} />নতুন বিনিয়োগ রেকর্ড</Link>
      </Topbar>
      <main className="ct">
        <div className="kpis">
          <Kpi label="সক্রিয় বিনিয়োগকারী" value={`${bnDigits(active.length)} জন`} note={`আবেদন অপেক্ষমাণ ${bnDigits(waiting.length)}`} />
          <Kpi label="মোট সক্রিয় মূলধন" value={money(capital)} note={`স্টকে খাটছে ${money(stock)}`} />
          <Kpi label="এখনো খাটেনি" value={money(idle)} note="পরের কেনাকাটায় লাগান" tone="warn" />
          <Kpi label="এ মাসে দেয় লাভ (খসড়া)" value={money(due)} note="৩০ নভেম্বর হিসাব বন্ধ" />
          <Kpi label="মূলধন ফেরতের অনুরোধ" value={`${bnDigits(open.length)}টি`} note={money(open.reduce((s, w) => s + w.amount, 0))} />
        </div>
        <InvestorsView investors={investors} applications={waiting} idle={idle} />
      </main>
    </>
  );
}
