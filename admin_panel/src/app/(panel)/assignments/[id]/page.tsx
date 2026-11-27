import { Suspense } from "react";
import { LoadError } from "@/components/shell/LoadState";
import { PageLoading } from "@/components/shell/PageLoading";
import { Topbar } from "@/components/shell/Topbar";
import { Avatar, Chip, Kpi } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import type { ApiAssignment, ApiSellerRow } from "@/lib/api/types";
import { bnDateTime, bnDigits } from "@/lib/format";
import { AssignmentActions, StockMoveForm } from "./AssignmentForms";

export const metadata = { title: "বরাদ্দের বিস্তারিত" };

const TONE = { pending_handover: "wa", active: "ok", partially_returned: "inf", closed: "nu", cancelled: "er" } as const;

export default function AssignmentDetailPage(props: PageProps<"/assignments/[id]">) {
  return (
    <Suspense fallback={<PageLoading title="বরাদ্দ" />}>
      <AssignmentDetail params={props.params} />
    </Suspense>
  );
}

async function AssignmentDetail({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const r = await load(() => Promise.all([api.get<ApiAssignment>(`/admin/assignments/${encodeURIComponent(id)}`), api.get<ApiSellerRow[]>("/admin/sellers")]));
  if (r.error !== undefined) {
    return (
      <>
        <Topbar title="বরাদ্দ" back="/assignments" />
        <main className="ct"><LoadError message={r.error} retryHref={`/assignments/${id}`} /></main>
      </>
    );
  }
  const [a, sellers] = r.data;

  const live = a.status === "active" || a.status === "partially_returned";

  return (
    <>
      <Topbar title={`বরাদ্দ #${a.id.slice(-6).toUpperCase()}`} back="/assignments" crumb={{ href: "/assignments", label: "স্টক বরাদ্দ" }} />
      <main className="ct">
        <section className="cd" style={{ display: "flex", gap: 16, alignItems: "center", flexWrap: "wrap" }}>
          <div className="sl fx" style={{ minWidth: 220 }}>
            <Avatar name={a.seller_name} size={48} />
            <div><b style={{ fontSize: 17 }}>{a.seller_name}</b><span className="mu">দেওয়া হয়েছে: {bnDateTime(a.created_at)}{a.accepted_at ? ` · গ্রহণ: ${bnDateTime(a.accepted_at)}` : ""}</span></div>
          </div>
          <Chip tone={TONE[a.status]}>{a.status_label}</Chip>
          <Chip>{a.price_mode === "flexible" ? "দাম সীমার মধ্যে" : "নির্ধারিত দাম"}</Chip>
        </section>
        <div className="kpis">
          {[...new Set(a.items.map((item) => item.unit_label))].map((unit) => {
            const items = a.items.filter((item) => item.unit_label === unit);
            const sum = (key: "quantity" | "sold" | "returned" | "remaining") =>
              `${bnDigits(Number(items.reduce((total, item) => total + item[key], 0).toFixed(4)))} ${unit}`;
            return <Kpi key={unit}
              label={a.status === "pending_handover" ? "গ্রহণের অপেক্ষায়" : a.status === "cancelled" ? "বাতিল করা বরাদ্দ" : "সেলারের হাতে বাকি"}
              value={sum(a.status === "cancelled" ? "quantity" : "remaining")}
              note={a.accepted_at ? `বিক্রি ${sum("sold")} · ফেরত ${sum("returned")}` : undefined}
              tone={a.status === "pending_handover" ? "warn" : undefined} />;
          })}
        </div>
        <div className="two">
          <div className="a">
            <div className="tw">
              <table style={{ minWidth: 560 }}>
                <thead><tr><th>পণ্য</th><th>ধরন</th><th className="n">দেওয়া</th><th className="n">বিক্রি</th><th className="n">ফেরত</th><th className="n">বাকি</th></tr></thead>
                <tbody>
                  {a.items.map((i) => (
                    <tr key={i.product_id + (i.variant ?? "")}>
                      <td><b style={{ fontWeight: 600 }}>{i.name}</b></td>
                      <td>{i.variant ?? "—"}</td>
                      <td className="n">{bnDigits(i.quantity)} {i.unit_label}</td>
                      <td className="n">{bnDigits(i.sold)} {i.unit_label}</td>
                      <td className="n">{bnDigits(i.returned)} {i.unit_label}</td>
                      <td className="n"><b>{bnDigits(i.remaining)} {i.unit_label}</b></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 4 }}>এই বরাদ্দের ইতিহাস</h2>
              {[...a.history].reverse().map((h, k) => (
                <div key={k} className="tl"><i style={{ background: k === 0 ? "#168447" : "#A9D6BB" }} /><div><div className="t1">{h.title}</div><div className="mu">{bnDateTime(h.at)} · {h.by}</div></div></div>
              ))}
            </section>
            <AssignmentActions id={a.id} status={a.status} remaining={a.totals.remaining} />
          </div>
          <div className="b">
            {live && a.totals.remaining > 0 ? (
              <StockMoveForm sellerId={a.seller_id} items={a.items.filter((i) => i.remaining > 0)} others={sellers.filter((s) => s.status === "active" && s.id !== a.seller_id)} />
            ) : null}
          </div>
        </div>
      </main>
    </>
  );
}
