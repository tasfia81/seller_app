import { Suspense } from "react";
import { Icon } from "@/components/ui/Icon";
import { LoginForm } from "./LoginForm";

export const metadata = { title: "লগইন" };

export default function LoginPage(props: PageProps<"/login">) {
  return (
    <div className="auth">
      <section className="auth-brand">
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <span className="sb-logo" style={{ width: 44, height: 44, borderRadius: 12 }}>
            <Icon name="bag" size={24} />
          </span>
          <div>
            <div style={{ fontSize: 18, fontWeight: 700 }}>স্ট্রিট সেলস</div>
            <div style={{ fontSize: 13, color: "#9cc9ae" }}>অ্যাডমিন প্যানেল</div>
          </div>
        </div>
        <div>
          <h2 style={{ margin: "0 0 10px", fontSize: 34, fontWeight: 800, lineHeight: 1.3 }}>
            পুরো ব্যবসা,
            <br />
            এক জায়গা থেকে
          </h2>
          <p style={{ margin: 0, fontSize: 16, lineHeight: 1.7, color: "#c9e0d3", maxWidth: 440 }}>
            সেলার, স্টক, বিক্রি, ক্যাশ আর লাভ — সব হিসাব প্রতিদিন পরিষ্কারভাবে দেখুন ও নিয়ন্ত্রণ করুন।
          </p>
        </div>
        <div className="auth-art" style={{ display: "flex", flexDirection: "column", gap: 14, maxWidth: 420, marginTop: 12 }}>
          <div className="auth-fc" style={{ transform: "rotate(-3deg)" }}>
            <span className="ic" style={{ background: "#eef5f0", color: "#168447", borderRadius: "50%", width: 44, height: 44 }}><Icon name="trend" /></span>
            <div className="fx"><div className="mu">আজকের মোট বিক্রি</div><div style={{ fontSize: 22, fontWeight: 700 }}>৳৪৮,৬৫০</div></div>
            <span className="ch ok">১২ জন সেলার</span>
          </div>
          <div className="auth-fc" style={{ transform: "rotate(2deg)", marginLeft: 40 }}>
            <span className="ic" style={{ background: "#fcf0da", color: "#85560c", borderRadius: "50%", width: 44, height: 44 }}><Icon name="cash" /></span>
            <div className="fx"><div className="mu">যাচাইয়ের অপেক্ষায় ক্যাশ</div><div style={{ fontSize: 22, fontWeight: 700 }}>৳১৮,২০০</div></div>
          </div>
        </div>
        <div style={{ marginTop: "auto", fontSize: 12.5, color: "#8db9a0" }}>
          শুধু অনুমোদিত অ্যাডমিনদের জন্য। নতুন অ্যাডমিন অ্যাকাউন্ট মালিক নিজে তৈরি করে দেন।
        </div>
      </section>
      <section className="auth-form">
        <Suspense fallback={<div className="auth-box" aria-busy="true" />}>
          <LoginWithNotice searchParams={props.searchParams} />
        </Suspense>
      </section>
    </div>
  );
}

async function LoginWithNotice({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  return <LoginForm expired={sp.expired === "1"} />;
}
