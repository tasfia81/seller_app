import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { Avatar } from "@/components/ui/bits";
import { ActionButton, Toggle } from "@/components/ui/feedback";

export const metadata = { title: "ভূমিকা, প্রোফাইল ও নিরাপত্তা" };

const ROLES = ["মালিক", "অ্যাডমিন", "ম্যানেজার", "হিসাবরক্ষক", "স্টক দেখাশোনা"];
const PERMS: [string, boolean[]][] = [
  ["সেলার আবেদন অনুমোদন", [true, true, true, false, false]],
  ["পরিচয়পত্রের ছবি দেখা", [true, true, false, false, false]],
  ["পণ্য, দাম ও ক্রয়মূল্য", [true, true, false, false, true]],
  ["স্টক গ্রহণ ও বরাদ্দ", [true, true, true, false, true]],
  ["ক্যাশ যাচাই ও পেমেন্ট", [true, true, false, true, false]],
  ["কমিশনের নিয়ম বদলানো", [true, false, false, false, false]],
  ["লাভ ও আর্থিক রিপোর্ট", [true, true, false, true, false]],
];

export default function AccountPage() {
  return (
    <>
      <Topbar title="ভূমিকা, প্রোফাইল ও নিরাপত্তা" back="/settings" />
      <main className="ct">
        <div className="two">
          <div className="a">
            <section>
              <div className="sh" style={{ marginBottom: 10 }}>
                <h2 className="h2">ভূমিকা ও অনুমতি</h2>
                <ActionButton className="btn o sm"><Icon name="plus" size={16} />নতুন অ্যাডমিন যোগ</ActionButton>
              </div>
              <div className="tw">
                <table style={{ minWidth: 680 }}>
                  <thead><tr><th>কাজ</th>{ROLES.map((r) => <th key={r} style={{ textAlign: "center" }}>{r}</th>)}</tr></thead>
                  <tbody>
                    {PERMS.map(([p, v]) => (
                      <tr key={p}>
                        <td>{p}</td>
                        {v.map((ok, i) => (
                          <td key={i} style={{ textAlign: "center", color: ok ? "#0F6A38" : "#9AA79F", fontWeight: 700 }} aria-label={ok ? "অনুমতি আছে" : "অনুমতি নেই"}>{ok ? "✓" : "—"}</td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <div className="mu" style={{ marginTop: 8 }}>প্রথম ধাপে শুধু “মালিক” ও “অ্যাডমিন” চালু থাকবে; বাকি ভূমিকাগুলো পরে চালু করা যাবে।</div>
            </section>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>অ্যাডমিন অ্যাকাউন্ট</h2>
              <div className="li"><Avatar name="তানভীর আহমেদ" /><span className="fx"><b className="t1">তানভীর আহমেদ</b><div className="mu">০১৭১১-০০০০০০</div></span><span className="ch ok">মালিক</span></div>
              <div className="li"><Avatar name="সুমাইয়া ইসলাম" /><span className="fx"><b className="t1">সুমাইয়া ইসলাম</b><div className="mu">০১৮১১-২২২২২২</div></span><span className="ch inf">অ্যাডমিন</span><ActionButton className="btn g sm">সম্পাদনা</ActionButton></div>
            </section>
          </div>
          <div className="b">
            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <div className="sl"><Avatar name="তানভীর আহমেদ" size={56} /><div><b style={{ fontSize: 17 }}>তানভীর আহমেদ</b><span className="mu">মালিক · tanvir@example.com</span></div></div>
              <div className="f"><label htmlFor="nm">নাম</label><input id="nm" className="in" defaultValue="তানভীর আহমেদ" /></div>
              <ActionButton className="btn g"><Icon name="key" size={18} />পাসওয়ার্ড বদলান</ActionButton>
            </section>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>চালু থাকা লগইন</h2>
              <div className="li"><span className="ic" style={{ background: "#E3F3EA", color: "#168447" }}><Icon name="dash" size={18} /></span><span className="fx"><b className="t1">Chrome · Windows</b><div className="mu">এই ডিভাইস · ঢাকা</div></span><span className="ch ok">এখন</span></div>
              <div className="li"><span className="ic" style={{ background: "#ECEFED", color: "#45524A" }}><Icon name="phone" size={18} /></span><span className="fx"><b className="t1">Chrome · Android</b><div className="mu">২ ঘণ্টা আগে</div></span><ActionButton className="btn r sm" confirm={{ title: "এই ডিভাইস থেকে বের করবেন?", message: "ওই ডিভাইসে আবার লগইন করতে হবে।", label: "বের করুন", danger: true }}>বের করুন</ActionButton></div>
            </section>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 4 }}>নোটিফিকেশন</h2>
              <div className="tg"><span>নতুন সেলার আবেদন</span><Toggle label="নতুন সেলার আবেদন" defaultOn /></div>
              <div className="tg"><span>ক্যাশ জমা</span><Toggle label="ক্যাশ জমা" defaultOn /></div>
              <div className="tg"><span>প্রতিটি নতুন বিক্রি</span><Toggle label="প্রতিটি নতুন বিক্রি" /></div>
            </section>
            <Link className="btn r" href="/login"><Icon name="logout" size={18} />লগআউট</Link>
          </div>
        </div>
      </main>
    </>
  );
}
