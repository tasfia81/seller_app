import { randomUUID } from "node:crypto";
import { Topbar } from "@/components/shell/Topbar";
import { KV, Note } from "@/components/ui/bits";
import { ApiForm } from "@/components/ui/ApiForm";
import { api, load } from "@/lib/api/server";
import { bnDate, money } from "@/lib/format";
import { submitOperation } from "../operational-actions";

export const metadata = { title: "মূলধন ফেরত" };

type Withdrawal = { id: string; investor_name: string; amount: number; paid: number; remaining: number;
  reason: string; status: string; status_label: string; requested_at: string; deadline: string };

export default async function InvestorWithdrawalsPage() {
  const result = await load(() => api.get<Withdrawal[]>("/admin/investor-withdrawals"));
  return <>
    <Topbar title="মূলধন ফেরতের অনুরোধ" />
    <main className="ct">
      {result.error ? <Note kind="warn">{result.error}</Note> : result.data?.length ? result.data.map((row) => (
        <section className="cd" key={row.id}>
          <h2 className="h2">{row.investor_name} · {row.status_label}</h2>
          <KV label="অনুরোধ">{money(row.amount)} · {bnDate(row.requested_at, true)}</KV>
          <KV label="কারণ">{row.reason}</KV><KV label="সময়সীমা">{bnDate(row.deadline, true)}</KV>
          <KV label="দেওয়া হয়েছে">{money(row.paid)}</KV><KV label="বাকি">{money(row.remaining)}</KV>
          {row.status === "pending" ? <div className="fg">
            <ApiForm label="অনুমোদন" action={submitOperation.bind(null, "withdraw-approve", row.id)}>
              <label>নোট<input className="in" name="note" maxLength={200} /></label>
            </ApiForm>
            <ApiForm label="বাতিল" confirm="অনুরোধ বাতিল করবেন?" action={submitOperation.bind(null, "withdraw-reject", row.id)}>
              <label>কারণ<input className="in" name="reason" minLength={3} maxLength={200} required /></label>
            </ApiForm>
          </div> : null}
          {row.status === "approved" ? <ApiForm label="পরিশোধ রেকর্ড" confirm="পরিশোধের রেফারেন্স যাচাই করেছেন?"
            action={submitOperation.bind(null, "withdraw-pay", row.id)}>
            <input type="hidden" name="request_id" value={randomUUID()} />
            <label>পরিমাণ<input className="in" name="amount" type="number" min="0.01" max={row.remaining} step="0.01" required /></label>
            <label>রেফারেন্স<input className="in" name="reference" minLength={3} maxLength={60} required /></label>
          </ApiForm> : null}
        </section>
      )) : <Note>কোনো ফেরতের অনুরোধ নেই।</Note>}
    </main>
  </>;
}
