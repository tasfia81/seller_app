import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Kpi } from "@/components/ui/bits";
import { sellers } from "@/lib/demo-data";
import { bnDigits, money } from "@/lib/format";
import { SellersTable } from "./SellersTable";

export const metadata = { title: "সেলার" };

export default function SellersPage() {
  const active = sellers.filter((s) => s.status === "active").length;
  const suspended = sellers.filter((s) => s.status === "suspended").length;
  const due = sellers.reduce((a, s) => a + s.cashDue, 0);
  return (
    <>
      <Topbar title="সেলার">
        <Link className="btn o" href="/applications">আবেদন <span className="ch wa">৪</span></Link>
      </Topbar>
      <main className="ct">
        <div className="kpis">
          <Kpi label="মোট সেলার" value={bnDigits(sellers.length)} />
          <Kpi label="সক্রিয়" value={bnDigits(active)} tone="good" />
          <Kpi label="স্থগিত" value={bnDigits(suspended)} tone="bad" />
          <Kpi label="সেলারদের হাতে বাকি ক্যাশ" value={money(due)} tone="warn" />
        </div>
        <SellersTable items={sellers} />
      </main>
    </>
  );
}
