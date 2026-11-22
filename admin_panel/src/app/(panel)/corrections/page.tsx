import { Suspense } from "react";
import { LoadError, Skeleton } from "@/components/shell/LoadState";
import { Topbar } from "@/components/shell/Topbar";
import { api, load } from "@/lib/api/server";
import type { ApiCorrection } from "@/lib/api/types";
import { CorrectionsView, type CorrectionTab } from "./CorrectionsView";

export const metadata = { title: "সংশোধনের অনুরোধ" };

const TABS: CorrectionTab[] = ["open", "approved", "rejected"];

export default function CorrectionsPage(props: PageProps<"/corrections">) {
  return (
    <>
      <Topbar title="বিক্রি সংশোধনের অনুরোধ" />
      <main className="ct">
        <Suspense fallback={<Skeleton rows={5} />}>
          <CorrectionsData searchParams={props.searchParams} />
        </Suspense>
      </main>
    </>
  );
}

async function CorrectionsData({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const tab = TABS.includes(sp.tab as CorrectionTab) ? (sp.tab as CorrectionTab) : "open";
  const r = await load(() => api.get<ApiCorrection[]>("/admin/corrections"));
  if (r.error !== undefined) return <LoadError message={r.error} retryHref="/corrections" />;
  const id = typeof sp.id === "string" ? sp.id : undefined;
  return <CorrectionsView all={r.data} tab={tab} selectedId={id} key={`${tab}-${id ?? ""}`} />;
}
