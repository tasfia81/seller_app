import { Topbar } from "@/components/shell/Topbar";
import { LoadError } from "@/components/shell/LoadState";
import { api, load } from "@/lib/api/server";
import { ActivityView, type Audit, type Notice } from "./ActivityView";

export const metadata = { title: "নোটিফিকেশন ও অডিট লগ" };

export default async function ActivityPage() {
  const result = await load(() => Promise.all([
    api.get<Notice[]>("/admin/notifications"),
    api.get<Audit[]>("/admin/audit-log"),
  ]));
  return (
    <>
      <Topbar title="নোটিফিকেশন ও অডিট লগ" />
      <main className="ct">
        {result.data ? <ActivityView notices={result.data[0]} audit={result.data[1]} /> : <LoadError message={result.error} retryHref="/activity" />}
      </main>
    </>
  );
}
