"use client";

import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from "react";
import { Icon } from "./Icon";

type Toast = { id: number; text: string; error?: boolean };
const ToastCtx = createContext<(text: string, error?: boolean) => void>(() => {});

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const show = useCallback((text: string, error?: boolean) => {
    const id = Date.now() + Math.random();
    setToasts((t) => [...t, { id, text, error }]);
    setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 3800);
  }, []);
  return (
    <ToastCtx.Provider value={show}>
      {children}
      <div className="toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`toast${t.error ? " err" : ""}`}>
            <Icon name={t.error ? "alert" : "info"} size={18} />
            <span>{t.text}</span>
          </div>
        ))}
      </div>
    </ToastCtx.Provider>
  );
}

export const useToast = () => useContext(ToastCtx);

/** Message shown for every action that needs the backend. Never fakes success. */
export const PENDING_MSG = "ডেমো: সার্ভার সংযোগ চালু হলে এই কাজটি সত্যিই হবে। এখন কিছু সংরক্ষণ হয়নি।";

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel,
  danger,
  onConfirm,
  onClose,
}: {
  open: boolean;
  title: string;
  message: ReactNode;
  confirmLabel: string;
  danger?: boolean;
  onConfirm: () => void;
  onClose: () => void;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);
  return (
    <dialog ref={ref} className="dlg" onClose={onClose} aria-labelledby="dlg-title">
      <div className="dlg-b">
        <h3 id="dlg-title">{title}</h3>
        <p>{message}</p>
        <div className="actions" style={{ marginTop: 6 }}>
          <button type="button" className="btn g" onClick={onClose}>বাতিল</button>
          <button
            type="button"
            className={`btn${danger ? " r" : ""}`}
            onClick={() => {
              onConfirm();
              onClose();
            }}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </dialog>
  );
}

/**
 * Button for an action that needs the server (approve, verify, pay…).
 * Optionally asks for confirmation, then shows the pending-integration notice.
 */
export function ActionButton({
  children,
  className = "btn",
  confirm,
  disabled,
  message = PENDING_MSG,
  onDone,
}: {
  children: ReactNode;
  className?: string;
  confirm?: { title: string; message: ReactNode; label: string; danger?: boolean };
  disabled?: boolean;
  message?: string;
  onDone?: () => void;
}) {
  const toast = useToast();
  const [open, setOpen] = useState(false);
  const run = () => {
    toast(message);
    onDone?.();
  };
  return (
    <>
      <button type="button" className={className} disabled={disabled} onClick={() => (confirm ? setOpen(true) : run())}>
        {children}
      </button>
      {confirm ? (
        <ConfirmDialog
          open={open}
          title={confirm.title}
          message={confirm.message}
          confirmLabel={confirm.label}
          danger={confirm.danger}
          onConfirm={run}
          onClose={() => setOpen(false)}
        />
      ) : null}
    </>
  );
}

export function Toggle({ label, defaultOn = false }: { label: string; defaultOn?: boolean }) {
  const [on, setOn] = useState(defaultOn);
  return <button type="button" className="sw" role="switch" aria-checked={on} aria-label={label} onClick={() => setOn(!on)} />;
}

export function Pills({ options, defaultValue, label, variant = "filter" }: { options: string[]; defaultValue?: string; label: string; variant?: "filter" | "select" }) {
  const [value, setValue] = useState(defaultValue ?? options[0]);
  const onClass = variant === "filter" ? " on" : " sel";
  return (
    <div className="pills" role="group" aria-label={label}>
      {options.map((o) => (
        <button key={o} type="button" className={`pill${value === o ? onClass : ""}`} aria-pressed={value === o} onClick={() => setValue(o)}>
          {o}
        </button>
      ))}
    </div>
  );
}

export function Tabs({ tabs, defaultValue, label }: { tabs: { id: string; label: ReactNode }[]; defaultValue?: string; label: string }) {
  const [value, setValue] = useState(defaultValue ?? tabs[0].id);
  return (
    <div className="tabs" role="tablist" aria-label={label}>
      {tabs.map((t) => (
        <button key={t.id} type="button" role="tab" aria-selected={value === t.id} className={`tab${value === t.id ? " on" : ""}`} onClick={() => setValue(t.id)}>
          {t.label}
        </button>
      ))}
    </div>
  );
}
