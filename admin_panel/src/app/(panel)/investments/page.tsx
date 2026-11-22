import { Topbar } from "@/components/shell/Topbar";
import { Kpi } from "@/components/ui/bits";
import { bnDigits, money } from "@/lib/format";
import { activeCapital, draftBatch, inStock, investors } from "@/lib/investors";
import { InvestmentsView } from "./InvestmentsView";

export const metadata = { title: "বিনিয়োগ ও পুঁজি" };

export default function InvestmentsPage() {
  const active = investors.filter((i) => i.status !== "suspended");
  const capital = active.reduce((s, i) => s + activeCapital(i), 0);
  const stock = active.reduce((s, i) => s + inStock(i), 0);
  const idle = active.reduce((s, i) => s + i.uninvested, 0);
  return (
    <>
      <Topbar title="বিনিয়োগ ও পুঁজি" />
      <main className="ct">
        <div className="kpis">
          <Kpi label="মোট সক্রিয় পুঁজি" value={money(capital)} />
          <Kpi label="স্টকে খাটছে" value={money(stock)} />
          <Kpi label="খাটেনি" value={money(idle)} tone="warn" note={`${bnDigits(active.length)} জনের`} />
        </div>
        <InvestmentsView
          investors={active.map((i) => ({ id: i.id, name: i.name, code: i.code, uninvested: i.uninvested, blocked: i.status === "withdrawing" }))}
          batch={draftBatch}
        />
      </main>
    </>
  );
}
