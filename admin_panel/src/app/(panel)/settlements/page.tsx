import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { KV, Note } from "@/components/ui/bits";
import { ApiForm } from "@/components/ui/ApiForm";
import { api, load } from "@/lib/api/server";
import { bnDigits, money } from "@/lib/format";
import { submitOperation } from "../operational-actions";

export const metadata = { title: "দিনের হিসাব" };

type Row = { seller_id: string; seller_name: string; date: string; total_sales: number; cash_due: number;
  stock_remaining: number; status: string; status_label: string };
type Detail = { requirements: { key: string; text: string; done: boolean }[];
  exception: { note: string } | null; history: { title: string; at: string; note?: string }[] };

export default async function SettlementsPage({ searchParams }: { searchParams: Promise<{ day?: string; seller?: string }> }) {
  const query = await searchParams;
  const day = query.day ?? new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Dhaka" }).format(new Date());
  const result = await load(async () => {
    const rows = await api.get<Row[]>(`/admin/settlements?day=${encodeURIComponent(day)}`);
    const seller = rows.find((row) => row.seller_id === query.seller) ?? rows[0];
    const detail = seller ? await api.get<Detail>(`/admin/settlements/${encodeURIComponent(seller.seller_id)}/${encodeURIComponent(day)}`) : null;
    return { rows, seller, detail };
  });
  const seller = result.data?.seller;
  const detail = result.data?.detail;
  return <>
    <Topbar title="দিনের হিসাব" />
    <main className="ct">
      <form method="get" className="fg"><input className="in" name="day" type="date" required defaultValue={day} />
        <button className="btn o">হিসাব দেখুন</button></form>
      {result.error ? <Note kind="warn">{result.error}</Note> : <div className="two">
        <section className="cd a"><h2 className="h2">সেলার</h2>
          {result.data?.rows.map((row) => <Link className="li" key={row.seller_id}
            href={`?day=${encodeURIComponent(day)}&seller=${encodeURIComponent(row.seller_id)}`}>{row.seller_name} · {row.status_label}</Link>)}
        </section>
        {seller && detail ? <section className="cd b"><h2 className="h2">{seller.seller_name} · {seller.status_label}</h2>
          <KV label="মোট বিক্রি">{money(seller.total_sales)}</KV><KV label="ক্যাশ বাকি">{money(seller.cash_due)}</KV>
          <KV label="স্টক হাতে">{bnDigits(seller.stock_remaining)}</KV>
          {detail.requirements.map((row) => <KV key={row.key} label={row.text}>{row.done ? "সম্পন্ন" : "বাকি"}</KV>)}
          {detail.exception ? <p>{detail.exception.note}</p> : null}
          {seller.status !== "closed" ? <>
            {seller.status !== "open" ? <>
              <ApiForm label="দিন বন্ধ করুন" confirm="আজকের হিসাব বন্ধ করবেন?" action={submitOperation.bind(null, "close-day", seller.seller_id)}>
                <input type="hidden" name="day" value={day} />
              </ApiForm>
              <ApiForm label="সংশোধন চান" action={submitOperation.bind(null, "day-correction", seller.seller_id)}>
                <input type="hidden" name="day" value={day} /><label>নোট<input className="in" name="note" minLength={5} required /></label>
              </ApiForm>
            </> : null}
            <ApiForm label="ব্যতিক্রম রেকর্ড" action={submitOperation.bind(null, "day-exception", seller.seller_id)}>
              <input type="hidden" name="day" value={day} /><label>কারণ<input className="in" name="note" minLength={5} required /></label>
            </ApiForm>
          </> : null}
          <h3>ইতিহাস</h3>{detail.history.map((entry, index) => <p key={`${entry.at}-${index}`}>{entry.title} {entry.note}</p>)}
        </section> : <Note>এই তারিখে কোনো হিসাব পাওয়া যায়নি।</Note>}
      </div>}
    </main>
  </>;
}
