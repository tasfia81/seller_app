import { Topbar } from "@/components/shell/Topbar";
import { Chip, Kpi, Note } from "@/components/ui/bits";
import { bnDigits, money } from "@/lib/format";
import { investors, profitRun } from "@/lib/investors";
import { ProfitApproval } from "./ProfitApproval";

export const metadata = { title: "মাসিক লাভ বিতরণ" };

export default function InvestorProfitPage() {
  const rows = investors.filter((i) => i.status !== "suspended");
  const p = profitRun.byProduct.map((r) => ({ ...r, net: r.revenue - r.cost - r.commission - r.other }));
  const revenue = p.reduce((s, r) => s + r.revenue, 0);
  const gross = p.reduce((s, r) => s + r.revenue - r.cost, 0);
  const net = p.reduce((s, r) => s + r.net, 0);
  const investorShare = rows.reduce((s, i) => s + i.profitThisMonth, 0);
  const cash = rows.filter((i) => i.preference === "cash");
  const reinvest = rows.filter((i) => i.preference === "reinvest");

  return (
    <>
      <Topbar title="মাসিক লাভ বিতরণ">
        <select className="in hide-m" aria-label="মাস" style={{ width: 170, height: 38 }}><option>{profitRun.month}</option><option>অক্টোবর ২০২৬</option></select>
      </Topbar>
      <main className="ct">
        <div className="steps">
          <span className="step d"><b>✓</b>বিক্রি চলছে</span>
          <span className="step c"><b>২</b>খসড়া যাচাই</span>
          <span className="step"><b>৩</b>মাস বন্ধ ও অনুমোদন</span>
          <span className="step"><b>৪</b>পেমেন্ট ও রসিদ</span>
        </div>
        {!profitRun.closed ? (
          <Note>{profitRun.month.split(" ")[0]} এখনো চলছে — এটা খসড়া। {profitRun.closesOn} সব সেলারের দিনের হিসাব বন্ধ হলে অনুমোদন চালু হবে। পেমেন্টের দিন {profitRun.payOn}।</Note>
        ) : null}
        <div className="kpis">
          <Kpi label="বিনিয়োগকারীদের স্টক থেকে বিক্রি" value={money(revenue)} />
          <Kpi label="মোট লাভ" value={money(gross)} note="বিক্রি − কেনা দাম" />
          <Kpi label="নিট লাভ" value={money(net)} note="কমিশন ও খরচ বাদে" />
          <Kpi label="বিনিয়োগকারীদের ভাগ" value={money(investorShare)} note={`কোম্পানির ${money(net - investorShare)}`} tone="good" />
        </div>
        <div className="two">
          <div className="a">
            <div className="tw">
              <table>
                <thead><tr><th>বিনিয়োগকারী</th><th className="n">ওনার স্টকের নিট লাভ</th><th className="n">ভাগ</th><th className="n">দেয়</th><th>যেভাবে নেবেন</th><th>মাধ্যম</th><th>অবস্থা</th></tr></thead>
                <tbody>
                  {rows.map((i) => (
                    <tr key={i.id}>
                      <td><b>{i.name}</b></td>
                      <td className="n">{money(i.netThisMonth)}</td>
                      <td className="n">{bnDigits(i.sharePercent)}%</td>
                      <td className="n"><b>{money(i.profitThisMonth)}</b></td>
                      <td>{i.preference === "cash" ? "টাকা নেবেন" : <Chip tone="inf">আবার বিনিয়োগ</Chip>}</td>
                      <td>{i.preference === "cash" ? i.profitVia : "—"}</td>
                      <td><Chip>খসড়া</Chip></td>
                    </tr>
                  ))}
                  <tr>
                    <td><b>মোট</b></td>
                    <td className="n"><b>{money(rows.reduce((s, i) => s + i.netThisMonth, 0))}</b></td>
                    <td />
                    <td className="n"><b>{money(investorShare)}</b></td>
                    <td colSpan={3} className="mu">টাকায় {money(cash.reduce((s, i) => s + i.profitThisMonth, 0))} · আবার বিনিয়োগে {money(reinvest.reduce((s, i) => s + i.profitThisMonth, 0))}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>হিসাব কোথা থেকে এলো (প্রোডাক্টভিত্তিক)</h2>
              <div className="tw" style={{ border: 0 }}>
                <table style={{ minWidth: 600 }}>
                  <thead><tr><th>প্রোডাক্ট</th><th className="n">বিক্রি</th><th className="n">কেনা দাম</th><th className="n">সেলার কমিশন</th><th className="n">খরচ</th><th className="n">নিট</th></tr></thead>
                  <tbody>
                    {p.map((r) => (
                      <tr key={r.product}><td>{r.product}</td><td className="n">{money(r.revenue)}</td><td className="n">{money(r.cost)}</td><td className="n">{money(r.commission)}</td><td className="n">{money(r.other)}</td><td className="n"><b>{money(r.net)}</b></td></tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          </div>
          <div className="b">
            <ProfitApproval closed={profitRun.closed} closesOn={profitRun.closesOn} />
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>পেমেন্টের দিন ({profitRun.payOn})</h2>
              <div className="kv"><span>পাঠাতে হবে</span><span>{bnDigits(cash.length)} জনকে · {money(cash.reduce((s, i) => s + i.profitThisMonth, 0))}</span></div>
              <div className="kv"><span>আবার বিনিয়োগ</span><span>{bnDigits(reinvest.length)} জন · {money(reinvest.reduce((s, i) => s + i.profitThisMonth, 0))}</span></div>
              <div className="mu" style={{ marginTop: 6 }}>প্রতিটি পেমেন্টে রেফারেন্স দিলে রসিদ তৈরি হবে। একই পেমেন্ট দুবার রেকর্ড করা যাবে না।</div>
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
