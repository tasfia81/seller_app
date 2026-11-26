import { Topbar } from "@/components/shell/Topbar";
import { Note } from "@/components/ui/bits";
import { api, load } from "@/lib/api/server";
import { MessagesView, type MessageHistory } from "./MessagesView";

export const metadata = { title: "বার্তা পাঠান" };

type Recipient = { id: string; name: string; status: string };

export default async function MessagesPage() {
  const result = await load(() => Promise.all([
    api.get<Recipient[]>("/admin/sellers"),
    api.get<Recipient[]>("/admin/investors"),
    api.get<MessageHistory[]>("/admin/messages"),
  ]));
  return (
    <>
      <Topbar title="বার্তা পাঠান" />
      <main className="ct">
        {result.data ? (
          <MessagesView
            sellers={result.data[0].map((s) => ({ id: s.id, name: s.name, active: s.status === "active" }))}
            investors={result.data[1].map((i) => ({ id: i.id, name: i.name, active: i.status === "active" }))}
            history={result.data[2]}
          />
        ) : <Note kind="warn">{result.error}</Note>}
      </main>
    </>
  );
}
