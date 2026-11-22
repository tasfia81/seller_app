import { Topbar } from "@/components/shell/Topbar";
import { Kpi } from "@/components/ui/bits";
import { PayoutsView } from "./PayoutsView";

export const metadata = { title: "সেলার পেমেন্ট" };

export default function PayoutsPage() {
  return (
    <>
      <Topbar title="সেলার পেমেন্ট">
        <select className="in hide-m" aria-label="মাস" style={{ width: 160, height: 38 }}><option>নভেম্বর ২০২৬</option><option>অক্টোবর ২০২৬</option></select>
      </Topbar>
      <main className="ct">
        <div className="kpis">
          <Kpi label="সেলারদের মোট অর্জিত আয়" value="৳৬৮,৪২০" />
          <Kpi label="অনুমোদিত (দিতে হবে)" value="৳৫৯,১০০" />
          <Kpi label="পরিশোধিত" value="৳৪৪,০০০" tone="good" />
          <Kpi label="বাকি পেমেন্ট" value="৳১৫,১০০" tone="warn" />
        </div>
        <PayoutsView />
      </main>
    </>
  );
}
