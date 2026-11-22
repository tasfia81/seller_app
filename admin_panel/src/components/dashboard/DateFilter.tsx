"use client";

import { useState } from "react";
import { Icon } from "@/components/ui/Icon";

const RANGES = ["আজ", "গতকাল", "৭ দিন", "এই মাস"] as const;

export function DateFilter() {
  const [range, setRange] = useState<string>("আজ");
  const [custom, setCustom] = useState(false);

  return (
    <div className="pills" role="group" aria-label="সময় বাছুন">
      {RANGES.map((r) => (
        <button
          key={r}
          type="button"
          className={`pill${!custom && range === r ? " on" : ""}`}
          aria-pressed={!custom && range === r}
          onClick={() => {
            setRange(r);
            setCustom(false);
          }}
        >
          {r}
        </button>
      ))}
      <label className={`pill${custom ? " on" : ""}`} style={{ cursor: "pointer" }}>
        <Icon name="cal" size={16} />
        <span>তারিখ বাছুন</span>
        <input
          type="date"
          aria-label="নির্দিষ্ট তারিখ"
          onChange={() => setCustom(true)}
          style={{ width: 0, height: 0, opacity: 0, position: "absolute" }}
        />
      </label>
    </div>
  );
}
