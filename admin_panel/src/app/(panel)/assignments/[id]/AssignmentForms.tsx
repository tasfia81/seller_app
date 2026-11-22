"use client";

import { useState, useTransition } from "react";
import { Note } from "@/components/ui/bits";
import { ConfirmDialog, useToast } from "@/components/ui/feedback";
import type { ActionResult } from "@/lib/api/server";
import type { ApiAssignment, ApiAssignmentStatus, ApiSellerRow } from "@/lib/api/types";
import { bnDigits, parseMoney } from "@/lib/format";
import { cancelAssignment, closeAssignment, moveSellerStock } from "../actions";

function useRun() {
  const toast = useToast();
  const [pending, start] = useTransition();
  const run = (fn: () => Promise<ActionResult>, after?: () => void) =>
    start(async () => {
      const r = await fn();
      toast(r.ok ? (r.message ?? "সম্পন্ন হয়েছে।") : r.message, !r.ok);
      if (r.ok) after?.();
    });
  return { pending, run, toast };
}

export function AssignmentActions({ id, status, remaining }: { id: string; status: ApiAssignmentStatus; remaining: number }) {
  const { pending, run } = useRun();
  const [confirm, setConfirm] = useState<null | "cancel" | "close">(null);
  if (status === "closed" || status === "cancelled") return null;
  return (
    <div className="actions">
      {status === "pending_handover" ? (
        <button type="button" className="btn r" disabled={pending} onClick={() => setConfirm("cancel")}>হস্তান্তরের আগে বাতিল করুন</button>
      ) : (
        <button type="button" className="btn r" disabled={pending || remaining > 0} onClick={() => setConfirm("close")} title={remaining > 0 ? "আগে সব পণ্য ফেরত বা হস্তান্তর করুন" : undefined}>বরাদ্দ বন্ধ করুন</button>
      )}
      <ConfirmDialog open={confirm === "cancel"} title="বরাদ্দ বাতিল করবেন?" message="সংরক্ষিত স্টক আবার গুদামে বরাদ্দযোগ্য হবে।" confirmLabel="বাতিল করুন" danger onConfirm={() => run(() => cancelAssignment(id))} onClose={() => setConfirm(null)} />
      <ConfirmDialog open={confirm === "close"} title="বরাদ্দ বন্ধ করবেন?" message="বন্ধ হলে এই বরাদ্দে আর বিক্রি হবে না।" confirmLabel="বন্ধ করুন" danger onConfirm={() => run(() => closeAssignment(id))} onClose={() => setConfirm(null)} />
    </div>
  );
}

const KINDS = [
  { id: "recall", label: "গুদামে ফেরত" },
  { id: "seller_to_seller", label: "অন্য সেলারকে" },
  { id: "damage", label: "ক্ষতি" },
] as const;

export function StockMoveForm({ sellerId, items, others }: { sellerId: string; items: ApiAssignment["items"]; others: ApiSellerRow[] }) {
  const { pending, run, toast } = useRun();
  const [kind, setKind] = useState<(typeof KINDS)[number]["id"]>("recall");
  const [line, setLine] = useState(0);
  const [qty, setQty] = useState("");
  const [to, setTo] = useState(others[0]?.id ?? "");
  const [reason, setReason] = useState("");
  const it = items[line];
  const q = parseMoney(qty) ?? 0;

  const submit = () => {
    if (!it) return;
    if (q <= 0 || q > it.remaining) return toast(`পরিমাণ ১ থেকে ${bnDigits(it.remaining)}-এর মধ্যে দিন।`, true);
    if (reason.trim().length < 3) return toast("কারণ লিখুন।", true);
    if (kind === "seller_to_seller" && !to) return toast("কাকে দেবেন বাছুন।", true);
    run(() => moveSellerStock(kind, { seller_id: sellerId, to_seller_id: to, product_id: it.product_id, variant: it.variant, quantity: q, reason: reason.trim() }), () => {
      setQty("");
      setReason("");
    });
  };

  return (
    <section className="drawer">
      <h2 className="h2">স্টক ফেরত, হস্তান্তর বা ক্ষতি</h2>
      <div className="pills" role="group" aria-label="ধরন">
        {KINDS.map((k) => (
          <button key={k.id} type="button" className={`pill${kind === k.id ? " sel" : ""}`} aria-pressed={kind === k.id} onClick={() => setKind(k.id)} disabled={k.id === "seller_to_seller" && !others.length}>{k.label}</button>
        ))}
      </div>
      <div className="f">
        <label htmlFor="mp">পণ্য</label>
        <select id="mp" className="in" value={line} onChange={(e) => setLine(Number(e.target.value))}>
          {items.map((i, k) => <option key={k} value={k}>{i.name}{i.variant ? ` (${i.variant})` : ""} · {bnDigits(i.remaining)} বাকি</option>)}
        </select>
      </div>
      {kind === "seller_to_seller" ? (
        <div className="f">
          <label htmlFor="mt">কাকে দেবেন</label>
          <select id="mt" className="in" value={to} onChange={(e) => setTo(e.target.value)}>{others.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}</select>
        </div>
      ) : null}
      <div className="f"><label htmlFor="mq">পরিমাণ</label><input id="mq" className="in" inputMode="decimal" value={qty} onChange={(e) => setQty(e.target.value)} /></div>
      <div className="f"><label htmlFor="mr">কারণ <i>*</i></label><input id="mr" className="in" value={reason} onChange={(e) => setReason(e.target.value)} placeholder="যেমন: দিন শেষের ফেরত" /></div>
      <Note>{kind === "damage" ? "ক্ষতি সেলারের হাত থেকে বাদ যাবে, তবে সেলারের কাছ থেকে আপনা-আপনি টাকা কাটা হবে না।" : "গুদামে হাতে পাওয়ার পর “পেয়েছি” নিশ্চিত করলে তবেই স্টক গুদামে যোগ হয়। প্রতিটি আসা-যাওয়া লগে থাকে।"}</Note>
      <button type="button" className="btn full" disabled={pending} onClick={submit}>{pending ? "হচ্ছে…" : kind === "damage" ? "ক্ষতি রেকর্ড করুন" : kind === "recall" ? "ফেরত ডাকুন" : "হস্তান্তর শুরু করুন"}</button>
    </section>
  );
}
