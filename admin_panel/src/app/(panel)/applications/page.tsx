import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { api, load } from "@/lib/api/server";
import type { ApiApplication, ApiApplicationStatus, ApiApplicationSummary } from "@/lib/api/types";
import { ApplicationsView } from "./ApplicationsView";

export const metadata = { title: "সেলার আবেদন" };

const STATUSES: ApiApplicationStatus[] = ["submitted", "under_review", "more_info", "approved", "rejected"];

export default function ApplicationsPage(props: PageProps<"/applications">) {
  return (
    <>
      <Topbar title="সেলার আবেদন" />
      <main className="ct">
        <Suspense fallback={<Skeleton rows={6} />}>
          <ApplicationsData searchParams={props.searchParams} />
        </Suspense>
      </main>
    </>
  );
}

async function ApplicationsData({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const tab = STATUSES.includes(sp.status as ApiApplicationStatus) ? (sp.status as ApiApplicationStatus) : "submitted";
  const r = await load(async () => {
    const all = await api.get<ApiApplicationSummary[]>("/admin/applications");
    const list = all.filter((a) => a.status === tab);
    const id = typeof sp.id === "string" && list.some((a) => a.id === sp.id) ? sp.id : list[0]?.id;
    const selected = id ? await api.get<ApiApplication>(`/admin/applications/${encodeURIComponent(id)}`) : null;
    return { all, selected };
  });
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/applications" />;
  return <ApplicationsView all={r.data.all} tab={tab} selected={r.data.selected} key={r.data.selected?.id ?? tab} />;
}
