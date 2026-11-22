import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { KV } from "@/components/ui/bits";
import { CompensationForm } from "./CompensationForm";

export const metadata = { title: "কমিশন ও আয়" };

const HISTORY = [
  { change: "লাভের ২০% → লাভের ৪০%", when: "১ জুন ২০২৬ থেকে", reason: "প্রশিক্ষণ শেষ", color: "#168447" },
  { change: "দৈনিক ৳৪০০ → লাভের ২০%", when: "৩ মার্চ ২০২৬ থেকে", reason: "প্রথম মাস শেষ", color: "#A9D6BB" },
  { change: "শুরু: দৈনিক মজুরি ৳৪০০", when: "৩ মার্চ ২০২৬ · যোগদান", reason: "", color: "#DCE4DF" },
];

export default function CompensationPage() {
  return (
    <>
      <Topbar title="কমিশন ও আয়" back="/sellers" />
      <main className="ct">
        <div className="two">
          <div className="a">
            <CompensationForm />
          </div>
          <div className="b">
            <section className="cd">
              <div className="sh" style={{ marginBottom: 4 }}><h2 className="h2">আয়ের হিসাব</h2><span className="mu">নভেম্বর ২০২৬ · রাকিব হাসান</span></div>
              <KV label="মোট অর্জিত">৳১২,৪৮০</KV>
              <KV label="অনুমোদনের অপেক্ষায়"><span style={{ color: "#85560C" }}>৳১,৮৬০</span></KV>
              <KV label="অনুমোদিত (দিতে হবে)">৳১০,৬২০</KV>
              <KV label="পরিশোধিত">৳৮,০০০</KV>
              <KV label="বাকি পাওনা" total><span style={{ color: "#0F6A38" }}>৳২,৬২০</span></KV>
              <Link className="btn o full" href="/payouts" style={{ marginTop: 10 }}>পেমেন্ট দিন</Link>
            </section>
            <section className="cd">
              <h2 className="h2" style={{ marginBottom: 6 }}>নিয়মের ইতিহাস</h2>
              {HISTORY.map((h) => (
                <div key={h.change} className="tl">
                  <i style={{ background: h.color }} />
                  <div>
                    <div className="t1">{h.change}</div>
                    <div className="mu">{h.when} · তানভীর আহমেদ</div>
                    {h.reason ? <div className="mu">কারণ: {h.reason}</div> : null}
                  </div>
                </div>
              ))}
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
