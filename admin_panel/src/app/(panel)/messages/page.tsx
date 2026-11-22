import { Topbar } from "@/components/shell/Topbar";
import { sellers } from "@/lib/demo-data";
import { investors } from "@/lib/investors";
import { MessagesView } from "./MessagesView";

export const metadata = { title: "বার্তা পাঠান" };

export default function MessagesPage() {
  return (
    <>
      <Topbar title="বার্তা পাঠান" />
      <main className="ct">
        <MessagesView
          sellers={sellers.map((s) => ({ id: s.id, name: s.name, active: s.status === "active" }))}
          investors={investors.map((i) => ({ id: i.id, name: i.name, active: i.status !== "suspended" }))}
        />
      </main>
    </>
  );
}
