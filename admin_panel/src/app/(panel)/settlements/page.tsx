import { Topbar } from "@/components/shell/Topbar";
import { SettlementsView } from "./SettlementsView";

export const metadata = { title: "দিনের হিসাব" };

export default function SettlementsPage() {
  return (
    <>
      <Topbar title="দিনের হিসাব">
        <input type="date" className="in hide-m" aria-label="তারিখ" defaultValue="2026-11-21" style={{ width: 170, height: 38 }} />
      </Topbar>
      <main className="ct">
        <SettlementsView />
      </main>
    </>
  );
}
