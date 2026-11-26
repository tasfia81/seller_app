import { randomUUID } from "node:crypto";
import { Topbar } from "@/components/shell/Topbar";
import { KV, Kpi, Note } from "@/components/ui/bits";
import { ApiForm } from "@/components/ui/ApiForm";
import { api, load } from "@/lib/api/server";
import { money } from "@/lib/format";
import { submitOperation } from "../operational-actions";

export const metadata = { title: "মাসিক লাভ বিতরণ" };

type Run = { status: string; can_approve: boolean;
  totals: { net: number; investors_share: number; cash: number; reinvest: number; paid: number };
  products: { product_id: string; product_name: string; net: number }[];
  lines: { investor_id: string; name: string; amount: number; preference: string; paid: boolean }[];
};

export default async function InvestorProfitPage({ searchParams }: { searchParams: Promise<{ month?: string }> }) {
  const { month } = await searchParams;
  const current = new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Dhaka", year: "numeric", month: "2-digit" })
    .formatToParts(new Date());
  const selected = month && /^\d{4}-(0[1-9]|1[0-2])$/.test(month) ? month :
    `${current.find((part) => part.type === "year")?.value}-${current.find((part) => part.type === "month")?.value}`;
  const result = await load(() => api.get<Run>(`/admin/investor-profit/${selected}`));
  const run = result.data;
  return <>
    <Topbar title="মাসিক লাভ বিতরণ" />
    <main className="ct">
      <form method="get" className="fg"><input className="in" name="month" type="month" defaultValue={selected} required />
        <button className="btn o">মাসের হিসাব দেখুন</button></form>
      {!run ? <Note kind="warn">{result.error}</Note> : <>
        <div className="kpis"><Kpi label="নিট লাভ" value={money(run.totals.net)} />
          <Kpi label="বিনিয়োগকারীদের ভাগ" value={money(run.totals.investors_share)} />
          <Kpi label="পরিশোধিত" value={money(run.totals.paid)} /></div>
        {run.can_approve ? <ApiForm label="মাস অনুমোদন করুন" confirm="এই মাসের লাভের হিসাব অনুমোদন করবেন?"
          action={submitOperation.bind(null, "profit-approve", selected)} /> : null}
        <section className="cd"><h2 className="h2">পণ্যের লাভ</h2>{run.products.map((row) =>
          <KV key={row.product_id} label={row.product_name}>{money(row.net)}</KV>)}</section>
        {run.lines.map((row) => <section className="cd" key={row.investor_id}>
          <h2 className="h2">{row.name} · {money(row.amount)}</h2>
          <p>{row.paid ? "পরিশোধিত" : row.preference === "reinvest" ? "আবার বিনিয়োগ" : "টাকা পরিশোধ"}</p>
          {run.status === "approved" && !row.paid ? <ApiForm label="পরিশোধ রেকর্ড"
            confirm="এই বিনিয়োগকারীর লাভ রেকর্ড করবেন?" action={submitOperation.bind(null, "profit-pay", selected)}>
            <input type="hidden" name="request_id" value={randomUUID()} />
            <input type="hidden" name="investor_id" value={row.investor_id} />
            {row.preference === "cash" ? <label>পরিশোধের রেফারেন্স<input className="in" name="reference" required maxLength={60} /></label> : null}
          </ApiForm> : null}
        </section>)}
      </>}
    </main>
  </>;
}
