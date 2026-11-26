import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { KV, Note } from "@/components/ui/bits";
import { ApiForm } from "@/components/ui/ApiForm";
import { api, load } from "@/lib/api/server";
import { bnDate, money } from "@/lib/format";
import { submitOperation } from "../../operational-actions";
import { RevealInvestorNid } from "./RevealInvestorNid";

export const metadata = { title: "বিনিয়োগকারীর আবেদন" };

const documents = { nid_front: "NID সামনের দিক", nid_back: "NID পেছনের দিক", selfie: "সেলফি" };

type Application = { id: string; full_name: string; status: string; status_label: string;
  mobile_masked: string; submitted_at: string; proposed_amount: number; nid_masked?: string;
  occupation?: string; funds_source?: string; documents: Record<keyof typeof documents, boolean>;
  admin_message: string | null; rejection_reason: string | null };

export default async function InvestorApplicationsPage({ searchParams }: { searchParams: Promise<{ id?: string }> }) {
  const { id } = await searchParams;
  const result = await load(async () => {
    const list = await api.get<Application[]>("/admin/investor-applications");
    const selected = id && list.some((row) => row.id === id) ? id : list[0]?.id;
    const detail = selected ? await api.get<Application>(`/admin/investor-applications/${encodeURIComponent(selected)}`) : null;
    return { list, detail };
  });
  const app = result.data?.detail;
  return <>
    <Topbar title="আবেদন যাচাই" back="/investors" />
    <main className="ct">{result.error ? <Note kind="warn">{result.error}</Note> : <>
      <div className="two">
        <section className="cd a"><h2 className="h2">আবেদন</h2>
          {result.data?.list.map((row) => <Link className="li" key={row.id} href={`?id=${encodeURIComponent(row.id)}`}>
            {row.full_name} · {row.status_label} · {bnDate(row.submitted_at, true)}
          </Link>)}
        </section>
        {app ? <section className="cd b"><h2 className="h2">{app.full_name} · {app.status_label}</h2>
          <KV label="মোবাইল">{app.mobile_masked}</KV><KV label="NID">{app.nid_masked}</KV>
          <KV label="পেশা">{app.occupation}</KV><KV label="অর্থের উৎস">{app.funds_source}</KV>
          <KV label="প্রস্তাবিত বিনিয়োগ">{money(app.proposed_amount)}</KV>
          <RevealInvestorNid id={app.id} />
          {Object.entries(documents).map(([kind, label]) => (
            <div key={kind}>{app.documents[kind as keyof typeof documents] ?
              <a href={`/api/files/investor-applications/${encodeURIComponent(app.id)}/${kind}`} target="_blank" rel="noreferrer">{label} দেখুন</a> : <span>{label} জমা হয়নি</span>}</div>
          ))}
          {app.admin_message ? <p>{app.admin_message}</p> : null}
          {app.rejection_reason ? <p>{app.rejection_reason}</p> : null}
          {app.status === "submitted" ? <ApiForm label="যাচাই শুরু" action={submitOperation.bind(null, "review-investor", app.id)} /> : null}
          {["submitted", "under_review"].includes(app.status) ? <>
            <ApiForm label="তথ্য চাইুন" action={submitOperation.bind(null, "investor-info", app.id)}>
              {Object.entries(documents).map(([key, label]) => <label className="ck" key={key}><input type="checkbox" name="fields" value={key} />{label}</label>)}
              <label>বার্তা<input className="in" name="message" minLength={3} required /></label>
            </ApiForm>
            <ApiForm label="অনুমোদন করুন" confirm="এই আবেদন অনুমোদন করবেন?" action={submitOperation.bind(null, "approve-investor", app.id)}>
              <label>লাভের ভাগ (%)<input className="in" name="share_percent" type="number" min="0.01" max="99.99" step="0.01" defaultValue={50} required /></label>
              <label>পরিশোধের দিন<input className="in" name="payout_day" type="number" min={1} max={28} defaultValue={5} required /></label>
              <label>নোটিশের দিন<input className="in" name="notice_days" type="number" min={0} max={180} defaultValue={30} required /></label>
            </ApiForm>
          </> : null}
          {["submitted", "under_review", "more_info"].includes(app.status) ? <ApiForm label="আবেদন বাতিল" confirm="আবেদনটি বাতিল করবেন?" action={submitOperation.bind(null, "reject-investor", app.id)}>
            <label>কারণ<input className="in" name="reason" minLength={3} required /></label>
          </ApiForm> : null}
        </section> : <Note>কোনো আবেদন পাওয়া যায়নি।</Note>}
      </div>
    </>}</main>
  </>;
}
