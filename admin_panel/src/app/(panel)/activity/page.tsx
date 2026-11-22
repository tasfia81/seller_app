import { Topbar } from "@/components/shell/Topbar";
import { ActivityView } from "./ActivityView";

export const metadata = { title: "নোটিফিকেশন ও অডিট লগ" };

export default function ActivityPage() {
  return (
    <>
      <Topbar title="নোটিফিকেশন ও অডিট লগ" />
      <main className="ct">
        <ActivityView />
      </main>
    </>
  );
}
