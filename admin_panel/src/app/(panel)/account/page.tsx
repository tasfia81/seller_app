import { Topbar } from "@/components/shell/Topbar";
import { Avatar, KV, Note } from "@/components/ui/bits";
import { ApiForm } from "@/components/ui/ApiForm";
import { api, load } from "@/lib/api/server";
import { logoutAction } from "@/app/(auth)/login/actions";
import { changePassword, revokeSessions } from "./actions";

export const metadata = { title: "প্রোফাইল ও নিরাপত্তা" };
type Account = { name: string; mobile: string; email: string | null };

export default async function AccountPage() {
  const result = await load(() => api.get<Account>("/auth/me"));
  const user = result.data;
  return <>
    <Topbar title="প্রোফাইল ও নিরাপত্তা" back="/settings" />
    <main className="ct">{!user ? <Note kind="warn">{result.error}</Note> : <div className="two">
      <section className="cd a">
        <div className="sl"><Avatar name={user.name} size={56} /><b>{user.name}</b></div>
        <KV label="ভূমিকা">অ্যাডমিন</KV><KV label="মোবাইল">{user.mobile}</KV>
        <KV label="ইমেইল">{user.email ?? "—"}</KV>
        <form action={logoutAction}><button className="btn o" type="submit">এই ডিভাইস থেকে লগআউট</button></form>
        <ApiForm label="সব ডিভাইস থেকে লগআউট" action={revokeSessions} confirm="সব সেশন বন্ধ করবেন?" />
      </section>
      <section className="cd b"><h2 className="h2">পাসওয়ার্ড বদলান</h2>
        <ApiForm label="পাসওয়ার্ড সংরক্ষণ" action={changePassword}>
          <label>বর্তমান পাসওয়ার্ড<input className="in" name="current_password" type="password" autoComplete="current-password" required /></label>
          <label>নতুন পাসওয়ার্ড<input className="in" name="new_password" type="password" autoComplete="new-password" minLength={8} required /></label>
          <label>আবার লিখুন<input className="in" name="confirm" type="password" autoComplete="new-password" minLength={8} required /></label>
        </ApiForm>
      </section>
    </div>}</main>
  </>;
}
