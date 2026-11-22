import { Topbar } from "@/components/shell/Topbar";
import { Kpi } from "@/components/ui/bits";
import { Pills } from "@/components/ui/feedback";
import { money } from "@/lib/format";
import { ExpenseForm } from "./ExpenseForm";

export const metadata = { title: "খরচ" };

const ROWS = [
  ["২১ নভেম্বর", "যাতায়াত", "গুদাম থেকে মিরপুরে মাল নেওয়া", "রাকিব হাসান", 350],
  ["২০ নভেম্বর", "প্যাকেজিং", "পলিব্যাগ ৫০০টি", "—", 1200],
  ["১৮ নভেম্বর", "নষ্ট", "বৃষ্টিতে ভেজা টি-শার্ট", "পোলো টি-শার্ট", 520],
  ["১ নভেম্বর", "ভাড়া", "গুদামের মাসিক ভাড়া", "—", 15000],
  ["১ নভেম্বর", "মার্কেটিং", "ফেসবুক বিজ্ঞাপন", "—", 2000],
] as const;

export default function ExpensesPage() {
  return (
    <>
      <Topbar title="খরচ" />
      <main className="ct">
        <div className="sh">
          <Pills label="সময়" options={["আজ", "সপ্তাহ", "মাস"]} defaultValue="মাস" />
          <select className="in" aria-label="ক্যাটাগরি" style={{ width: 180, height: 36 }}><option>সব ক্যাটাগরি</option><option>যাতায়াত</option><option>প্যাকেজিং</option><option>ভাড়া</option></select>
        </div>
        <div className="kpis">
          <Kpi label="এই মাসের মোট খরচ" value={money(34860)} />
          <Kpi label="ভাড়া" value={money(15000)} />
          <Kpi label="যাতায়াত" value={money(8420)} />
          <Kpi label="প্যাকেজিং" value={money(5280)} />
          <Kpi label="অন্যান্য" value={money(6160)} />
        </div>
        <div className="two">
          <div className="a">
            <div className="tw">
              <table style={{ minWidth: 720 }}>
                <thead><tr><th>তারিখ</th><th>ক্যাটাগরি</th><th>বিবরণ</th><th>যার জন্য</th><th className="n">টাকা</th><th>রেকর্ড করেছেন</th></tr></thead>
                <tbody>
                  {ROWS.map((r) => (
                    <tr key={r[0] + r[2]}><td>{r[0]}</td><td><span className="ch nu">{r[1]}</span></td><td>{r[2]}</td><td>{r[3]}</td><td className="n"><b>{money(r[4])}</b></td><td>তানভীর</td></tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          <div className="b">
            <ExpenseForm />
          </div>
        </div>
      </main>
    </>
  );
}
