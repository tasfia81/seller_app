import { Topbar } from "@/components/shell/Topbar";
import { KV, Note } from "@/components/ui/bits";
import { ApiForm } from "@/components/ui/ApiForm";
import { api, load } from "@/lib/api/server";
import { bnDate, bnDigits } from "@/lib/format";
import { submitOperation } from "../operational-actions";

export const metadata = { title: "ফেরত ও ক্ষতি" };

type StockReturn = { id: string; seller_name: string; product_name: string; quantity: number;
  reason: string; photo: string | null; note: string | null; status: string; status_label: string; created_at: string };

const reasons: Record<string, string> = { end_of_day: "দিন শেষে ফেরত", damaged: "ক্ষতিগ্রস্ত", expired: "মেয়াদ শেষ", other: "অন্যান্য" };

export default async function ReturnsPage() {
  const result = await load(() => api.get<StockReturn[]>("/admin/returns"));
  return <>
    <Topbar title="ফেরত ও ক্ষতি" />
    <main className="ct">{result.error ? <Note kind="warn">{result.error}</Note> : result.data?.length ? result.data.map((row) => (
      <section className="cd" key={row.id}>
        <h2 className="h2">{row.product_name} · {row.status_label}</h2>
        <KV label="সেলার">{row.seller_name}</KV><KV label="পরিমাণ">{bnDigits(row.quantity)}</KV>
        <KV label="কারণ">{reasons[row.reason] ?? row.reason}</KV><KV label="তারিখ">{bnDate(row.created_at, true)}</KV>
        {row.note ? <KV label="নোট">{row.note}</KV> : null}
        {row.photo ? <a href={`/api/files/returns/${encodeURIComponent(row.id)}`} target="_blank" rel="noreferrer">ফেরতের ছবি দেখুন</a> : null}
        {row.status === "pending" ? <div className="fg">
          <ApiForm label="ফেরত অনুমোদন" action={submitOperation.bind(null, "return-approve", row.id)}>
            <label>গন্তব্য<select className="in" name="destination"><option value="warehouse">গুদাম</option><option value="damaged">ক্ষতিগ্রস্ত স্টক</option></select></label>
          </ApiForm>
          <ApiForm label="ফেরত বাতিল" confirm="ফেরতের অনুরোধ বাতিল করবেন?" action={submitOperation.bind(null, "return-reject", row.id)}>
            <label>নোট<input className="in" name="note" /></label>
          </ApiForm>
        </div> : null}
        {row.status === "approved" ? <ApiForm label="পণ্য হাতে পেয়েছি" confirm="পণ্য হাতে পেয়েছেন?" action={submitOperation.bind(null, "return-receive", row.id)} /> : null}
      </section>
    )) : <Note>ফেরতের কোনো অনুরোধ নেই।</Note>}</main>
  </>;
}
