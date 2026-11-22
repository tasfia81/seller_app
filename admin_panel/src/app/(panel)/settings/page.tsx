import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Icon } from "@/components/ui/Icon";
import { ActionButton, Toggle } from "@/components/ui/feedback";

export const metadata = { title: "সেটিংস" };

const METHODS = [
  ["ক্যাশ", "", "seller", true],
  ["বিকাশ", "মার্চেন্ট ০১৭১১-০০০০০০", "business", true],
  ["নগদ", "মার্চেন্ট ০১৭১১-০০০০০০", "business", true],
  ["ব্যাংক ট্রান্সফার", "", "business", false],
  ["অন্যান্য", "", "seller", false],
] as const;

export default function SettingsPage() {
  return (
    <>
      <Topbar title="সেটিংস">
        <ActionButton>সংরক্ষণ</ActionButton>
      </Topbar>
      <main className="ct">
        <div className="tabs">
          <span className="tab on">ব্যবসা ও পেমেন্ট</span>
          <Link className="tab" href="/account">ভূমিকা, প্রোফাইল ও নিরাপত্তা</Link>
        </div>
        <div className="two">
          <div className="a">
            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
              <h2 className="h2">ব্যবসার প্রোফাইল</h2>
              <div style={{ display: "flex", gap: 14, alignItems: "center", flexWrap: "wrap" }}>
                <span style={{ width: 72, height: 72, borderRadius: 16, background: "#0B3D2E", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center" }}><Icon name="bag" size={32} /></span>
                <div><label className="btn o sm" style={{ cursor: "pointer" }}>লোগো বদলান<input type="file" accept="image/png" style={{ display: "none" }} /></label><div className="mu" style={{ marginTop: 4 }}>PNG, বর্গাকার, সর্বোচ্চ ১MB</div></div>
              </div>
              <div className="fg">
                <div className="f"><label htmlFor="bn">ব্যবসার নাম</label><input id="bn" className="in" defaultValue="স্ট্রিট সেলস" /></div>
                <div className="f"><label htmlFor="ph">যোগাযোগের নম্বর</label><input id="ph" className="in" defaultValue="01711000000" /></div>
                <div className="f"><label htmlFor="cu">মুদ্রা</label><select id="cu" className="in"><option>বাংলাদেশি টাকা (৳)</option></select></div>
                <div className="f"><label htmlFor="tz">সময় অঞ্চল</label><select id="tz" className="in"><option>ঢাকা (GMT+6)</option></select></div>
              </div>
              <div className="f"><label htmlFor="ad">ঠিকানা</label><input id="ad" className="in" defaultValue="গুদাম: বাড়ি ৪, রোড ১০, মিরপুর ১০, ঢাকা" /></div>
            </section>
            <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              <h2 className="h2">পেমেন্টের মাধ্যম</h2>
              <div className="mu">কোন মাধ্যমে টাকা সেলারের হাতে যায় আর কোনটায় সরাসরি ব্যবসার অ্যাকাউন্টে আসে — এটা ঠিক থাকলে ক্যাশের হিসাব নির্ভুল হয়।</div>
              <div className="tw">
                <table style={{ minWidth: 520 }}>
                  <thead><tr><th>মাধ্যম</th><th>টাকা কোথায় যায়</th><th>চালু</th></tr></thead>
                  <tbody>
                    {METHODS.map(([name, sub, dest, on]) => (
                      <tr key={name}>
                        <td><b style={{ fontWeight: 600 }}>{name}</b>{sub ? <div className="mu">{sub}</div> : null}</td>
                        <td>{dest === "seller" ? <span className="ch wa">সেলারের হাতে — জমা দিতে হবে</span> : <span className="ch ok">সরাসরি ব্যবসার অ্যাকাউন্টে</span>}</td>
                        <td><Toggle label={`${name} চালু`} defaultOn={on} /></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          </div>
          <div className="b">
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 4 }}>স্টক ও দিন বন্ধের নিয়ম</h2>
              <div className="f" style={{ margin: "8px 0" }}><label htmlFor="dp">ডিফল্ট স্টকের নিয়ম</label><select id="dp" className="in"><option>প্রতিদিন ফেরত</option><option>পরের দিনে চলবে</option></select><span className="hint">কোনো সেলারের আলাদা নিয়ম দিলে সেটাই চলবে</span></div>
              <div className="f" style={{ marginBottom: 8 }}><label htmlFor="lt">কম স্টকের ডিফল্ট সীমা</label><input id="lt" className="in" defaultValue="১০ ইউনিট" /></div>
              {[
                ["স্টক দেওয়ার পর সেলারকে বুঝে নিতে হবে", "সেলার অ্যাপে “পেয়েছি” চাপলে তবেই চালু"],
                ["ফেরত গুদামে হাতে পেয়ে নিশ্চিত করতে হবে", ""],
                ["দিন বন্ধের আগে সব ক্যাশ জমা লাগবে", ""],
                ["দিন বন্ধের আগে সব ফেরত লাগবে", "শুধু “প্রতিদিন ফেরত” সেলারদের জন্য"],
              ].map(([t, s]) => (
                <div key={t} className="tg"><span>{t}{s ? <small>{s}</small> : null}</span><Toggle label={t} defaultOn /></div>
              ))}
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
