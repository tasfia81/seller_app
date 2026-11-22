import { Topbar } from "@/components/shell/Topbar";
import { applications } from "@/lib/demo-data";
import { ApplicationsView } from "./ApplicationsView";

export const metadata = { title: "সেলার আবেদন" };

export default function ApplicationsPage() {
  return (
    <>
      <Topbar title="সেলার আবেদন" />
      <main className="ct">
        <ApplicationsView items={applications} />
      </main>
    </>
  );
}
