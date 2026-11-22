import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Kpi } from "@/components/ui/bits";
import { Tabs } from "@/components/ui/feedback";
import { products } from "@/lib/demo-data";
import { bnDigits, money } from "@/lib/format";
import { StockReceiptForm } from "./StockReceiptForm";

export const metadata = { title: "মূল স্টক" };

const MOVES = [
  ["আজ ১১:০৫", "পোলো টি-শার্ট", "wa", "সেলারের ফেরত", "+২", "রাকিব → গুদাম", "ফে-০৩১", "অপেক্ষমাণ"],
  ["আজ ১০:৪৮", "জার্সি (L)", "nu", "বিক্রি", "−২", "রাকিব → কাস্টমার", "বি-১০৪৮২", "সিস্টেম"],
  ["আজ ০৮:১০", "জার্সি", "inf", "সেলারকে বরাদ্দ", "−২০", "গুদাম → রাকিব", "বর-২১০৪", "তানভীর"],
  ["গতকাল ১৬:৩০", "বেসিক টি-শার্ট", "ok", "স্টক গ্রহণ", "+১০০", "সরবরাহকারী → গুদাম", "ব্যাচ-৮৮", "তানভীর"],
  ["গতকাল ১৪:০০", "জগার প্যান্ট", "er", "ক্ষতি", "−১", "সাকিব → ক্ষতিগ্রস্ত", "ক্ষ-০০৭", "তানভীর"],
];

export default function InventoryPage() {
  const warehouse = products.reduce((a, p) => a + p.warehouse, 0);
  const withSellers = products.reduce((a, p) => a + p.withSellers, 0);
  const pending = products.reduce((a, p) => a + p.pendingTransfer, 0);
  const damaged = products.reduce((a, p) => a + p.damaged, 0);
  const low = products.filter((p) => p.warehouse <= p.lowStockAt).length;

  return (
    <>
      <Topbar title="মূল স্টক">
        <Link className="btn o hide-m" href="/assignments/new">সেলারকে দিন</Link>
      </Topbar>
      <main className="ct">
        <div className="kpis">
          <Kpi label="মোট স্টক" value={bnDigits(warehouse + withSellers)} note="গুদাম + সেলারদের কাছে" />
          <Kpi label="সেলারদের কাছে" value={bnDigits(withSellers)} />
          <Kpi label="গুদামে বরাদ্দযোগ্য" value={bnDigits(warehouse)} tone="good" />
          <Kpi label="হস্তান্তর বাকি" value={bnDigits(pending)} tone="info" />
          <Kpi label="ক্ষতিগ্রস্ত" value={bnDigits(damaged)} tone="bad" />
          <Kpi label="কম বা শেষ স্টকের পণ্য" value={bnDigits(low)} tone="warn" />
        </div>
        <div className="two">
          <div className="a">
            <Tabs label="স্টক দেখুন" tabs={[{ id: "p", label: "পণ্যভিত্তিক স্টক" }, { id: "m", label: "আসা-যাওয়ার ইতিহাস" }]} />
            <div className="tw">
              <table style={{ minWidth: 720 }}>
                <thead><tr><th>পণ্য</th><th className="n">গুদামে</th><th className="n">সেলারদের কাছে</th><th className="n">হস্তান্তর বাকি</th><th className="n">ক্ষতিগ্রস্ত</th><th className="n">স্টকের মূল্য (ক্রয়)</th></tr></thead>
                <tbody>
                  {products.map((p) => (
                    <tr key={p.id}>
                      <td><b style={{ fontWeight: 600 }}>{p.name}</b> {p.warehouse === 0 ? <span className="ch er">শেষ</span> : p.warehouse <= p.lowStockAt ? <span className="ch wa">কম স্টক</span> : null}</td>
                      <td className="n" style={p.warehouse <= p.lowStockAt ? { color: "#85560C", fontWeight: 600 } : undefined}>{bnDigits(p.warehouse)}</td>
                      <td className="n">{bnDigits(p.withSellers)}</td>
                      <td className="n">{bnDigits(p.pendingTransfer)}</td>
                      <td className="n">{bnDigits(p.damaged)}</td>
                      <td className="n">{money((p.warehouse + p.withSellers) * p.cost)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <section>
              <h2 className="h2" style={{ marginBottom: 10 }}>সাম্প্রতিক আসা-যাওয়া</h2>
              <div className="tw">
                <table style={{ minWidth: 820 }}>
                  <thead><tr><th>সময়</th><th>পণ্য</th><th>ধরন</th><th className="n">পরিমাণ</th><th>কোথা থেকে → কোথায়</th><th>রেফারেন্স</th><th>করেছেন</th></tr></thead>
                  <tbody>
                    {MOVES.map((m) => (
                      <tr key={m[0] + m[6]}>
                        <td>{m[0]}</td><td>{m[1]}</td><td><span className={`ch ${m[2]}`}>{m[3]}</span></td><td className="n">{m[4]}</td><td>{m[5]}</td><td className="mu">{m[6]}</td><td>{m[7]}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          </div>
          <div className="b">
            <StockReceiptForm />
          </div>
        </div>
      </main>
    </>
  );
}
