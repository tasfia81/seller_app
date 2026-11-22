"use client";

import { useState } from "react";
import { Note } from "@/components/ui/bits";
import { ActionButton } from "@/components/ui/feedback";

const CHECKS = [
  "সব সেলারের দিনের হিসাব বন্ধ",
  "খোলা সংশোধনের অনুরোধ নেই",
  "নষ্ট পণ্যের তদন্ত শেষ (জার্সি ৬ পিস)",
];

export function ProfitApproval({ closed, closesOn }: { closed: boolean; closesOn: string }) {
  const [checks, setChecks] = useState([true, true, false]);
  const ready = closed && checks.every(Boolean);
  return (
    <section className="drawer">
      <h2 className="h2">অনুমোদনের আগে দেখুন</h2>
      {CHECKS.map((c, i) => (
        <label key={c} className="ck">
          <input type="checkbox" checked={checks[i]} onChange={() => setChecks(checks.map((v, k) => (k === i ? !v : v)))} /> {c}
        </label>
      ))}
      {!checks[2] ? <Note kind="warn" icon="alert">নষ্ট ৬ পিসের ক্ষতি (৳২,১০০) এই খসড়ায় ধরা হয়নি। তদন্ত শেষ না হলে পরের মাসে সমন্বয় হবে।</Note> : null}
      <ActionButton
        className={`btn full${ready ? "" : " dis"}`}
        disabled={!ready}
        confirm={{ title: "লাভ বিতরণ অনুমোদন করবেন?", message: "অনুমোদনের পর সংখ্যা আর বদলাবে না; প্রত্যেক বিনিয়োগকারীর অ্যাপে মাসিক রিপোর্ট যাবে।", label: "অনুমোদন করুন" }}
      >
        {closed ? "লাভ বিতরণ অনুমোদন করুন" : `${closesOn}-এর পর অনুমোদন করা যাবে`}
      </ActionButton>
      <div className="mu">অনুমোদনের পর সংখ্যা আর বদলাবে না; প্রত্যেক বিনিয়োগকারীর অ্যাপে মাসিক রিপোর্ট যাবে।</div>
    </section>
  );
}
