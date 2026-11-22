"use client";

import { useState } from "react";
import { Note } from "@/components/ui/bits";

const STEPS = ["অ্যাকাউন্ট", "কোড যাচাই", "নতুন পাসওয়ার্ড"];

/** Recovery steps. OTP is never simulated — each step only previews the UI. */
export function ForgotFlow() {
  const [step, setStep] = useState(0);
  const [otp, setOtp] = useState(["", "", "", "", "", ""]);

  return (
    <>
      <div className="steps" aria-label="ধাপ">
        {STEPS.map((s, i) => (
          <span key={s} className={`step${i < step ? " d" : i === step ? " c" : ""}`}>
            <b>{i < step ? "✓" : ["১", "২", "৩"][i]}</b>
            {s}
          </span>
        ))}
      </div>

      {step === 0 ? (
        <>
          <div>
            <h1 style={{ margin: "0 0 6px", fontSize: 24, fontWeight: 700 }}>অ্যাকাউন্ট খুঁজুন</h1>
            <p className="mu" style={{ margin: 0, fontSize: 14 }}>আপনার মোবাইল নম্বরে একটি ৬ সংখ্যার কোড পাঠানো হবে।</p>
          </div>
          <div className="f">
            <label htmlFor="acc">মোবাইল নম্বর বা ইমেইল</label>
            <input id="acc" className="in" placeholder="01XXXXXXXXX" />
          </div>
          <button type="button" className="btn full" style={{ height: 50 }} onClick={() => setStep(1)}>কোড পাঠান</button>
        </>
      ) : step === 1 ? (
        <>
          <div>
            <h1 style={{ margin: "0 0 6px", fontSize: 24, fontWeight: 700 }}>কোডটি দিন</h1>
            <p className="mu" style={{ margin: 0, fontSize: 14 }}>আপনার মোবাইলে পাঠানো ৬ সংখ্যার কোড লিখুন।</p>
          </div>
          <div className="otp" role="group" aria-label="৬ সংখ্যার কোড">
            {otp.map((v, i) => (
              <input
                key={i}
                aria-label={`${i + 1} নম্বর সংখ্যা`}
                inputMode="numeric"
                maxLength={1}
                value={v}
                onChange={(e) => setOtp(otp.map((x, j) => (j === i ? e.target.value.slice(-1) : x)))}
              />
            ))}
          </div>
          <div className="sh mu">
            <span>আবার পাঠানো যাবে <b style={{ color: "#17251D" }}>০০:৪৫</b> পরে</span>
            <button type="button" className="btn g sm" onClick={() => setStep(0)}>নম্বর বদলান</button>
          </div>
          <button type="button" className="btn full" style={{ height: 50 }} onClick={() => setStep(2)}>যাচাই করুন</button>
        </>
      ) : (
        <>
          <h1 style={{ margin: 0, fontSize: 24, fontWeight: 700 }}>নতুন পাসওয়ার্ড দিন</h1>
          <div className="f">
            <label htmlFor="np">নতুন পাসওয়ার্ড</label>
            <input id="np" className="in" type="password" />
            <span className="hint">কমপক্ষে ৮টি অক্ষর ও একটি সংখ্যা</span>
          </div>
          <div className="f">
            <label htmlFor="cp">পাসওয়ার্ড আবার লিখুন</label>
            <input id="cp" className="in" type="password" />
          </div>
          <button type="button" className="btn full dis" style={{ height: 50 }} disabled>পাসওয়ার্ড সংরক্ষণ</button>
        </>
      )}
      <Note kind="warn">সার্ভার চালু না হওয়া পর্যন্ত কোড আসলে পাঠানো বা যাচাই করা হবে না — এখানে শুধু স্ক্রিনগুলো দেখা যাচ্ছে।</Note>
    </>
  );
}
