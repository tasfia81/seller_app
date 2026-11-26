import { randomUUID } from "node:crypto";
import { Topbar } from "@/components/shell/Topbar";
import { KV, Kpi, Note } from "@/components/ui/bits";
import { ApiForm } from "@/components/ui/ApiForm";
import { api, load } from "@/lib/api/server";
import { money } from "@/lib/format";
import { submitOperation } from "../operational-actions";

export const metadata = { title: "বিনিয়োগ ও পুঁজি" };

type Capital = {
  totals: { active_capital: number; in_stock: number; uninvested: number };
  investors: { investor_id: string; name: string; code: string; uninvested: number; blocked: boolean }[];
};
type Product = { id: string; name: string; variants: string[] };
type Batch = { id: string; ref: string; product_name: string; qty: number; unit_cost: number };

export default async function InvestmentsPage() {
  const result = await load(() => Promise.all([
    api.get<Capital>("/admin/investor-capital"),
    api.get<Product[]>("/admin/products?status=active"),
    api.get<Batch[]>("/admin/fundings"),
  ]));
  const [capital, products, batches] = result.data ?? [];
  const eligible = capital?.investors.filter((row) => !row.blocked) ?? [];
  return <>
    <Topbar title="বিনিয়োগ ও পুঁজি" />
    <main className="ct">{!capital ? <Note kind="warn">{result.error}</Note> : <>
      <div className="kpis">
        <Kpi label="সক্রিয় পুঁজি" value={money(capital.totals.active_capital)} />
        <Kpi label="স্টকে খাটছে" value={money(capital.totals.in_stock)} />
        <Kpi label="খাটেনি" value={money(capital.totals.uninvested)} />
      </div>
      <div className="two">
        <section className="cd a"><h2 className="h2">বিনিয়োগের টাকা রেকর্ড</h2>
          {eligible.length ? <ApiForm label="বিনিয়োগ রেকর্ড করুন" confirm="স্টেটমেন্টে টাকা পাওয়া নিশ্চিত করেছেন?"
            action={submitOperation.bind(null, "investment", "")}>
            <input type="hidden" name="request_id" value={randomUUID()} />
            <label>বিনিয়োগকারী<select className="in" name="investor_id" required>
              {eligible.map((row) => <option key={row.investor_id} value={row.investor_id}>{row.name} · {row.code}</option>)}
            </select></label>
            <label>পরিমাণ<input className="in" type="number" min="0.01" step="0.01" name="amount" required /></label>
            <label>মাধ্যম<select className="in" name="method"><option value="bank">ব্যাংক</option><option value="cheque">চেক</option>
              <option value="bkash">বিকাশ</option><option value="nagad">নগদ</option></select></label>
            <label>রেফারেন্স<input className="in" name="reference" minLength={3} maxLength={60} required /></label>
            <label>পাওয়ার তারিখ<input className="in" name="received_on" type="date" required /></label>
            <label className="ck"><input type="checkbox" name="seen_in_statement" required />স্টেটমেন্টে টাকা দেখেছি</label>
          </ApiForm> : <Note>যোগ্য বিনিয়োগকারী পাওয়া যায়নি।</Note>}
        </section>
        <section className="cd b"><h2 className="h2">অর্থায়িত ব্যাচ স্টকে তুলুন</h2>
          {products?.length ? <ApiForm label="ব্যাচ সংরক্ষণ" confirm="এই অর্থায়ন ও স্টক রেকর্ড করবেন?"
            action={submitOperation.bind(null, "funding", "")}>
            <label>পণ্য<select className="in" name="product_id" required>
              {products.map((p) => <option key={p.id} value={p.id}>{p.name}{p.variants?.length ? ` · ${p.variants.join(", ")}` : ""}</option>)}
            </select></label>
            <label>ভ্যারিয়েন্ট থাকলে লিখুন<input className="in" name="variant" /></label>
            <label>পরিমাণ<input className="in" name="quantity" type="number" min="0.01" step="0.01" required /></label>
            <label>প্রতি ইউনিটের দাম<input className="in" name="unit_cost" type="number" min="0.01" step="0.01" required /></label>
            <label>ব্যাচ নম্বর<input className="in" name="batch_ref" minLength={2} maxLength={40} required /></label>
            <label>সরবরাহকারী<input className="in" name="supplier" /></label>
            {eligible.map((row) => <label key={row.investor_id}>{row.name} · উপলব্ধ {money(row.uninvested)}
              <input className="in" name={`part:${row.investor_id}`} type="number" min={0} step="0.01" defaultValue={0} />
            </label>)}
            <label>কোম্পানির অংশ<input className="in" name="company_amount" type="number" min={0} step="0.01" defaultValue={0} /></label>
          </ApiForm> : <Note>আগে একটি পণ্য যোগ করুন।</Note>}
        </section>
      </div>
      <section className="cd"><h2 className="h2">অর্থায়িত ব্যাচ</h2>{batches?.map((row) =>
        <KV key={row.id} label={`${row.product_name} · ${row.ref}`}>{money(row.qty * row.unit_cost)}</KV>)}</section>
    </>}</main>
  </>;
}
