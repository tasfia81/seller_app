import { Topbar } from "@/components/shell/Topbar";
import { CorrectionsView } from "./CorrectionsView";

export const metadata = { title: "সংশোধনের অনুরোধ" };

export default function CorrectionsPage() {
  return (
    <>
      <Topbar title="বিক্রি সংশোধনের অনুরোধ" />
      <main className="ct">
        <CorrectionsView />
      </main>
    </>
  );
}
