import Link from "next/link";
import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { Avatar, Chip, EmptyState } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import type { ApiAssignment, ApiAssignmentStatus } from "@/lib/api/types";
import { bnDateTime, bnDigits } from "@/lib/format";

export const metadata = { title: "স্টক বরাদ্দ" };

const ASSIGNMENT_TONE: Record<ApiAssignmentStatus, "ok" | "wa" | "inf" | "nu" | "er"> = {
  pending_handover: "wa",
  active: "ok",
  partially_returned: "inf",
  closed: "nu",
  cancelled: "er",
};

export default function AssignmentsPage() {
  return (
    <>
      <Topbar title="স্টক বরাদ্দ">
        <Link className="btn" href="/assignments/new"><Icon name="plus" size={18} />নতুন বরাদ্দ</Link>
      </Topbar>
      <main className="ct">
        <Suspense fallback={<Skeleton rows={5} />}>
          <AssignmentsData />
        </Suspense>
        <div className="mu">সেলার অ্যাপে “পেয়েছি” চাপার পরই বরাদ্দ “চালু” হয় — তার আগে স্টক সেলারের নামে যায় না।</div>
      </main>
    </>
  );
}

async function AssignmentsData() {
  const r = await load(() => api.get<ApiAssignment[]>("/admin/assignments"));
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/assignments" />;
  if (!r.data.length) return <div className="cd"><EmptyState icon="truck" title="এখনো কোনো বরাদ্দ নেই" text="“নতুন বরাদ্দ” দিয়ে সেলারকে স্টক দিন।" /></div>;
  return (
    <div className="tw">
      <table style={{ minWidth: 680 }}>
        <thead><tr><th>বরাদ্দ</th><th>সেলার</th><th>তারিখ</th><th>পণ্য</th><th>অবস্থা</th><th /></tr></thead>
        <tbody>
          {r.data.map((a) => (
            <tr key={a.id}>
              <td><b style={{ fontWeight: 600 }}>#{a.id.slice(-6).toUpperCase()}</b></td>
              <td><div className="sl"><Avatar name={a.seller_name} /><b>{a.seller_name}</b></div></td>
              <td>{bnDateTime(a.created_at)}</td>
              <td>{bnDigits(a.totals.quantity)} ইউনিট · {bnDigits(a.items.length)} পণ্য</td>
              <td><Chip tone={ASSIGNMENT_TONE[a.status]}>{a.status_label}</Chip></td>
              <td className="n"><Link className="btn g sm" href={`/assignments/${a.id}`}>বিস্তারিত</Link></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
