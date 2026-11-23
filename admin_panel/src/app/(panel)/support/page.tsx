import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { api, load } from "@/lib/api/server";
import type { ApiSupportInbox, ApiSupportMessage, ApiSupportThread } from "@/lib/api/types";
import { SupportView, type SupportFilter } from "./SupportView";

export const metadata = { title: "সাপোর্ট চ্যাট" };

const STATUSES = ["open", "resolved"] as const;
const KINDS = ["all", "seller", "investor"] as const;

export default function SupportPage(props: PageProps<"/support">) {
  return (
    <>
      <Topbar title="সাপোর্ট চ্যাট" />
      <main className="ct">
        <Suspense fallback={<Skeleton rows={6} />}>
          <SupportData searchParams={props.searchParams} />
        </Suspense>
      </main>
    </>
  );
}

async function SupportData({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const pick = <T extends string>(v: unknown, list: readonly T[], fallback: T): T => (list.includes(v as T) ? (v as T) : fallback);
  const filter: SupportFilter = { status: pick(sp.status, STATUSES, "open"), kind: pick(sp.kind, KINDS, "all") };
  const q = new URLSearchParams({ status: filter.status });
  if (filter.kind !== "all") q.set("kind", filter.kind);

  const r = await load(async () => {
    const inbox = await api.get<ApiSupportInbox>(`/admin/support/threads?${q}`);
    const wanted = typeof sp.id === "string" ? sp.id : undefined;
    // A thread linked from a notification may sit in the other tab: open it anyway.
    const id = wanted ?? inbox.items[0]?.id;
    const thread = id ? await api.get<ApiSupportThread & { messages: ApiSupportMessage[] }>(`/admin/support/threads/${encodeURIComponent(id)}`) : null;
    return { inbox, thread };
  });
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/support" />;
  return <SupportView inbox={r.data.inbox} thread={r.data.thread} filter={filter} key={r.data.thread?.id ?? "none"} />;
}
