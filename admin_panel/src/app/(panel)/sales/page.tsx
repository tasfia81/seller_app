import { Topbar } from "@/components/shell/Topbar";
import { sales } from "@/lib/demo-data";
import { SalesMonitor } from "./SalesMonitor";

export const metadata = { title: "বিক্রি মনিটর" };

export default function SalesPage() {
  return (
    <>
      <Topbar title="বিক্রি মনিটর">
        <span className="ch ok" style={{ gap: 6 }}><i style={{ width: 8, height: 8, borderRadius: "50%", background: "#168447", display: "block" }} />লাইভ</span>
      </Topbar>
      <main className="ct">
        <SalesMonitor items={sales} />
      </main>
    </>
  );
}
