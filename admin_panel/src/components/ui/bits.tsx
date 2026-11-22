import type { ReactNode } from "react";
import type { Tone } from "@/lib/types";
import { initials } from "@/lib/format";
import { Icon, type IconName } from "./Icon";

export function Chip({ tone = "nu", children }: { tone?: Tone; children: ReactNode }) {
  return <span className={`ch ${tone}`}>{children}</span>;
}

export function StatusChip({ value }: { value: readonly [string, Tone] }) {
  return <Chip tone={value[1]}>{value[0]}</Chip>;
}

export function Kpi({ label, value, note, tone }: { label: string; value: ReactNode; note?: ReactNode; tone?: "warn" | "good" | "info" | "bad" }) {
  const color = tone === "good" ? "#0F6A38" : tone === "info" ? "#1D4FB8" : tone === "bad" ? "#A92F2F" : undefined;
  return (
    <div className={`mt${tone === "warn" ? " w" : ""}`}>
      <span>{label}</span>
      <b style={color ? { color } : undefined}>{value}</b>
      {note ? <small>{note}</small> : null}
    </div>
  );
}

export function Avatar({ name, size }: { name: string; size?: number }) {
  return (
    <span className="av" style={size ? { width: size, height: size, fontSize: size * 0.34 } : undefined} aria-hidden="true">
      {initials(name)}
    </span>
  );
}

export function KV({ label, children, total }: { label: string; children: ReactNode; total?: boolean }) {
  return (
    <div className={`kv${total ? " tot" : ""}`}>
      <span>{label}</span>
      <span>{children}</span>
    </div>
  );
}

export function Note({ kind = "info", icon = "info", children }: { kind?: "info" | "warn" | "danger"; icon?: IconName; children: ReactNode }) {
  return (
    <div className={kind}>
      <Icon name={icon} size={18} />
      <span>{children}</span>
    </div>
  );
}

export function SearchBox({ placeholder, label }: { placeholder: string; label?: string }) {
  return (
    <div className="srch">
      <input className="in" placeholder={placeholder} aria-label={label ?? placeholder} type="search" />
      <span>
        <Icon name="search" size={18} />
      </span>
    </div>
  );
}

export function EmptyState({ icon = "box", title, text }: { icon?: IconName; title: string; text?: string }) {
  return (
    <div className="empty">
      <span className="empty-ic">
        <Icon name={icon} size={26} />
      </span>
      <b>{title}</b>
      {text ? <p className="mu">{text}</p> : null}
    </div>
  );
}
