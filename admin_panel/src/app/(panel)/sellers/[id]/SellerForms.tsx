"use client";

import { useState, useTransition } from "react";
import { Note } from "@/components/ui/bits";
import { ConfirmDialog, useToast } from "@/components/ui/feedback";
import type { ActionResult } from "@/lib/api/server";
import type { ApiPolicy, ApiSellerOverview, ApiSellerStatus } from "@/lib/api/types";
import { toAscii } from "@/lib/format";
import { revokeSessions, setSellerStatus, updateSeller } from "../actions";

function useRun() {
  const toast = useToast();
  const [pending, start] = useTransition();
  const run = (fn: () => Promise<ActionResult>) =>
    start(async () => {
      const r = await fn();
      toast(r.ok ? (r.message ?? "সম্পন্ন হয়েছে।") : r.message, !r.ok);
    });
  return { pending, run, toast };
}

export function SellerEditForm({ seller, presentAddress }: { seller: ApiSellerOverview["seller"]; presentAddress: string }) {
  const { pending, run, toast } = useRun();
  const [mobile, setMobile] = useState(seller.mobile);
  const [address, setAddress] = useState(presentAddress);
  const [policy, setPolicy] = useState<ApiPolicy>(seller.policy);
  const [perm, setPerm] = useState(seller.permissions);

  const save = () => {
    const m = toAscii(mobile).replace(/\D/g, "");
    if (!/^01[3-9]\d{8}$/.test(m)) return toast("সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন।", true);
    const changes: Parameters<typeof updateSeller>[1] = {};
    if (m !== seller.mobile) changes.mobile = m;
    if (address.trim() && address.trim() !== presentAddress) changes.present_address = address.trim();
    if (policy !== seller.policy) changes.policy = policy;
    (Object.keys(perm) as (keyof typeof perm)[]).forEach((k) => {
      if (perm[k] !== seller.permissions[k]) changes[k] = perm[k];
    });
    if (!Object.keys(changes).length) return toast("কিছু বদলানো হয়নি।");
    run(() => updateSeller(seller.id, changes));
  };

  return (
    <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 14 }}>
      <div className="sh"><h2 className="h2">তথ্য সম্পাদনা</h2><span className="mu">পরিবর্তন অডিট লগে থাকবে</span></div>
      <div className="fg">
        <div className="f"><label htmlFor="ph">মোবাইল নম্বর</label><input id="ph" className="in" inputMode="tel" value={mobile} onChange={(e) => setMobile(e.target.value)} /></div>
        <div className="f"><label htmlFor="ad">বর্তমান ঠিকানা</label><input id="ad" className="in" value={address} onChange={(e) => setAddress(e.target.value)} /></div>
        <div className="f">
          <label htmlFor="po">স্টকের নিয়ম</label>
          <select id="po" className="in" value={policy} onChange={(e) => setPolicy(e.target.value as ApiPolicy)}>
            <option value="daily_return">প্রতিদিন ফেরত</option>
            <option value="carry_forward">পরের দিনে চলবে</option>
          </select>
        </div>
      </div>
      <div>
        <div className="mu">কাজের অনুমতি</div>
        <label className="ck"><input type="checkbox" checked={perm.can_edit_price} onChange={() => setPerm({ ...perm, can_edit_price: !perm.can_edit_price })} /> অনুমোদিত সীমার মধ্যে দাম বদলাতে পারবেন</label>
        <label className="ck"><input type="checkbox" checked={perm.can_discount} onChange={() => setPerm({ ...perm, can_discount: !perm.can_discount })} /> ডিসকাউন্ট দিতে পারবেন</label>
        <label className="ck"><input type="checkbox" checked={perm.can_take_digital} onChange={() => setPerm({ ...perm, can_take_digital: !perm.can_take_digital })} /> বিকাশ/নগদে টাকা নিতে পারবেন</label>
      </div>
      <Note icon="shield">নাম, জন্মতারিখ বা পরিচয়পত্রের তথ্য এখানে বদলানো যায় না — সেগুলো বদলাতে আবার যাচাই করতে হবে।</Note>
      <div style={{ display: "flex", justifyContent: "flex-end" }}>
        <button type="button" className="btn" disabled={pending} onClick={save}>{pending ? "সংরক্ষণ হচ্ছে…" : "সংরক্ষণ করুন"}</button>
      </div>
    </section>
  );
}

export function SellerControls({ id, name, status }: { id: string; name: string; status: ApiSellerStatus }) {
  const { pending, run } = useRun();
  const [confirm, setConfirm] = useState<null | "suspend" | "activate" | "inactive" | "logout">(null);
  return (
    <section className="cd" style={{ display: "flex", flexDirection: "column", gap: 10 }}>
      <h2 className="h2">অ্যাকাউন্ট নিয়ন্ত্রণ</h2>
      {status === "active" ? (
        <>
          <button type="button" className="btn r" disabled={pending} onClick={() => setConfirm("suspend")}>সেলার স্থগিত করুন</button>
          <button type="button" className="btn g" disabled={pending} onClick={() => setConfirm("inactive")}>নিষ্ক্রিয় করুন</button>
        </>
      ) : (
        <button type="button" className="btn" disabled={pending} onClick={() => setConfirm("activate")}>আবার চালু করুন</button>
      )}
      <button type="button" className="btn g" disabled={pending} onClick={() => setConfirm("logout")}>সব ডিভাইস থেকে লগআউট করান</button>
      <div className="mu" style={{ lineHeight: 1.55 }}>লেনদেন আছে এমন সেলারকে মুছে ফেলা যায় না — শুধু নিষ্ক্রিয় বা স্থগিত করা যায়।</div>

      <ConfirmDialog open={confirm === "suspend"} title={`${name}-কে স্থগিত করবেন?`} message="স্থগিত থাকলে সেলার লগইন বা বিক্রি করতে পারবেন না। লেনদেনের ইতিহাস যেমন আছে তেমন থাকবে।" confirmLabel="স্থগিত করুন" danger onConfirm={() => run(() => setSellerStatus(id, "suspended"))} onClose={() => setConfirm(null)} />
      <ConfirmDialog open={confirm === "inactive"} title={`${name}-কে নিষ্ক্রিয় করবেন?`} message="নিষ্ক্রিয় সেলার লগইন বা বিক্রি করতে পারবেন না।" confirmLabel="নিষ্ক্রিয় করুন" onConfirm={() => run(() => setSellerStatus(id, "inactive"))} onClose={() => setConfirm(null)} />
      <ConfirmDialog open={confirm === "activate"} title={`${name}-কে আবার চালু করবেন?`} message="সেলার আবার লগইন করে বিক্রি করতে পারবেন।" confirmLabel="চালু করুন" onConfirm={() => run(() => setSellerStatus(id, "active"))} onClose={() => setConfirm(null)} />
      <ConfirmDialog open={confirm === "logout"} title="সব ডিভাইস থেকে লগআউট?" message="সেলারকে আবার লগইন করতে হবে।" confirmLabel="লগআউট করান" onConfirm={() => run(() => revokeSessions(id))} onClose={() => setConfirm(null)} />
    </section>
  );
}
