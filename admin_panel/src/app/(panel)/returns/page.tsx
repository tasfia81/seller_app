import { Topbar } from "@/components/shell/Topbar";
import { ReturnsView } from "./ReturnsView";

export const metadata = { title: "ফেরত ও ক্ষতি" };

export default function ReturnsPage() {
  return (
    <>
      <Topbar title="ফেরত ও ক্ষতি" />
      <main className="ct">
        <ReturnsView />
      </main>
    </>
  );
}
