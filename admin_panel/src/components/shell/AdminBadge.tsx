import { logoutAction } from "@/app/(auth)/login/actions";
import { Icon } from "@/components/ui/Icon";
import { api, ApiError } from "@/lib/api/server";
import { initials } from "@/lib/format";

/** Signed-in admin at the bottom of the sidebar, with logout. Reads the session, so it streams in. */
export async function AdminBadge() {
  let me: { name: string; role: string } | null = null;
  try {
    me = await api.get<{ name: string; role: string }>("/auth/me");
  } catch (e) {
    if (!(e instanceof ApiError)) throw e; // keep login redirects working
  }
  return (
    <div className="sb-user">
      <span className="av" style={{ width: 34, height: 34 }}>{me ? initials(me.name) : "?"}</span>
      <div style={{ minWidth: 0, flex: 1 }}>
        <div style={{ fontSize: 13, color: "#fff", fontWeight: 600 }}>{me?.name ?? "সার্ভার সংযোগ নেই"}</div>
        <div style={{ fontSize: 11.5, color: "#9cc9ae" }}>অ্যাডমিন</div>
      </div>
      <form action={logoutAction}>
        <button type="submit" className="ib" aria-label="লগআউট" title="লগআউট" style={{ color: "#c9e0d3", width: 36, height: 36 }}>
          <Icon name="logout" size={18} />
        </button>
      </form>
    </div>
  );
}

export function AdminBadgeFallback() {
  return <div className="sb-user" style={{ minHeight: 48 }} />;
}
