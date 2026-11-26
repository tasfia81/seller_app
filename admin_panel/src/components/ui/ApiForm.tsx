"use client";

import { useActionState, type ReactNode } from "react";

export type FormResult = { ok: boolean; message: string };

export function ApiForm({ action, children, label, confirm }: {
  action: (previous: FormResult | null, form: FormData) => Promise<FormResult>;
  children?: ReactNode;
  label: string;
  confirm?: string;
}) {
  const [state, submit, busy] = useActionState(action, null);
  return (
    <form action={submit} className="f" onSubmit={(event) => {
      if (confirm && !window.confirm(confirm)) event.preventDefault();
    }}>
      {children}
      <button type="submit" className="btn o" disabled={busy}>{busy ? "সংরক্ষণ হচ্ছে…" : label}</button>
      {state ? <p role="status" className={state.ok ? "mu" : "err"}>{state.message}</p> : null}
    </form>
  );
}
