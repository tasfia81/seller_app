import { Topbar } from "@/components/shell/Topbar";
import { Kpi, Note } from "@/components/ui/bits";
import { handovers } from "@/lib/demo-data";
import { money } from "@/lib/format";
import { CashView } from "./CashView";

export const metadata = { title: "ক্যাশ জমা" };

export default function CashPage() {
  const collected = 28500;
  const submitted = handovers.filter((h) => h.status !== "rejected" && h.time.startsWith("আজ")).reduce((a, h) => a + h.amount, 0);
  const pending = handovers.filter((h) => h.status === "pending").reduce((a, h) => a + h.amount, 0);
  const verified = handovers.filter((h) => h.status === "verified").reduce((a, h) => a + h.amount, 0);
  return (
    <>
      <Topbar title="ক্যাশ জমা" />
      <main className="ct">
        <div className="kpis">
          <Kpi label="সেলারদের সংগ্রহ করা ক্যাশ" value={money(collected)} />
          <Kpi label="জমা দিয়েছেন" value={money(submitted)} />
          <Kpi label="যাচাইয়ের অপেক্ষায়" value={money(pending)} tone="info" />
          <Kpi label="যাচাই হয়েছে" value={money(verified)} tone="good" />
          <Kpi label="সেলারদের কাছে বাকি" value={money(collected - submitted)} tone="warn" />
        </div>
        <Note>বিকাশ/নগদে কাস্টমার সরাসরি ব্যবসার অ্যাকাউন্টে যে টাকা দিয়েছেন (আজ ৳৬,৪২০), তা এই হিসাবে নেই — সেটা সেলারের দায় নয়।</Note>
        <CashView items={handovers} />
      </main>
    </>
  );
}
