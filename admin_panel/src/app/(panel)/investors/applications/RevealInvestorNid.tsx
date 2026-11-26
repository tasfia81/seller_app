"use client";

import { useState } from "react";
import { revealInvestorNid } from "./actions";

export function RevealInvestorNid({ id }: { id: string }) {
  const [text, setText] = useState("");
  const [busy, setBusy] = useState(false);
  async function reveal() {
    if (text) {
      setText("");
      return;
    }
    if (!window.confirm("পুরো NID দেখার বিষয়টি অডিট লগে রেকর্ড হবে। দেখবেন?")) return;
    setBusy(true);
    try {
      const result = await revealInvestorNid(id);
      setText(result.ok ? result.data.nid_number : result.message);
    } finally {
      setBusy(false);
    }
  }
  return <div><button className="btn o" type="button" onClick={reveal} disabled={busy}>{text ? "লুকান" : "পুরো NID দেখুন"}</button>
    {text ? <p role="status">{text}</p> : null}</div>;
}
