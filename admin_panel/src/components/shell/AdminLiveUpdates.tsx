"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { openSupportLive } from "@/app/(panel)/support/actions";

type ConnectionStatus = "connecting" | "connected" | "disconnected";

export function AdminLiveUpdates() {
  const router = useRouter();
  const [status, setStatus] = useState<ConnectionStatus>("connecting");

  useEffect(() => {
    let stopped = false;
    let connecting = false;
    let socket: WebSocket | undefined;
    let retry: ReturnType<typeof setTimeout> | undefined;
    let heartbeat: ReturnType<typeof setTimeout> | undefined;
    let backoff = 1000;

    function reconnect() {
      clearTimeout(heartbeat);
      if (stopped) return;
      setStatus("disconnected");
      if (!navigator.onLine || retry !== undefined) return;
      retry = setTimeout(() => {
        retry = undefined;
        void connect();
      }, backoff);
      backoff = Math.min(backoff * 2, 15_000);
    }

    async function connect() {
      if (stopped || connecting || socket) return;
      if (!navigator.onLine) {
        reconnect();
        return;
      }
      connecting = true;
      try {
        const grant = await openSupportLive();
        if (stopped) return;
        if (!grant.ok || !navigator.onLine) {
          reconnect();
          return;
        }
        const connection = new WebSocket(grant.url);
        socket = connection;
        function watchHeartbeat() {
          clearTimeout(heartbeat);
          heartbeat = setTimeout(() => connection.close(), 35_000);
        }
        watchHeartbeat();
        connection.onopen = () => connection.send(grant.ticket);
        connection.onmessage = (event) => {
          if (stopped || socket !== connection) return;
          watchHeartbeat();
          if (event.data === "ready") {
            backoff = 1000;
            setStatus("connected");
          }
          // The server sends ready after subscribing, so the first refresh
          // also retrieves notifications saved while this browser was away.
          if (event.data === "ready" || event.data === "changed") {
            window.dispatchEvent(new Event("admin-live-update"));
            if (["/activity", "/support", "/sales", "/dashboard", "/sellers", "/cash"].includes(window.location.pathname)) {
              router.refresh();
            }
          }
        };
        connection.onerror = () => connection.close();
        connection.onclose = () => {
          if (socket !== connection) return;
          socket = undefined;
          reconnect();
        };
      } catch {
        reconnect();
      } finally {
        connecting = false;
      }
    }

    function onOffline() {
      clearTimeout(retry);
      retry = undefined;
      reconnect();
      socket?.close();
    }

    function onOnline() {
      clearTimeout(retry);
      retry = undefined;
      backoff = 1000;
      void connect();
    }

    window.addEventListener("offline", onOffline);
    window.addEventListener("online", onOnline);
    void connect();
    return () => {
      stopped = true;
      clearTimeout(retry);
      clearTimeout(heartbeat);
      window.removeEventListener("offline", onOffline);
      window.removeEventListener("online", onOnline);
      socket?.close();
    };
  }, [router]);

  return (
    <div role="status" className={`live-status live-status--${status}`}>
      <span className="live-status-dot" aria-hidden="true" />
      {status === "connected" && "লাইভ নোটিফিকেশন চালু"}
      {status === "connecting" && "লাইভ নোটিফিকেশনে সংযোগ হচ্ছে…"}
      {status === "disconnected" && (
        <span>
          <strong>লাইভ নোটিফিকেশনের সংযোগ বিচ্ছিন্ন।</strong>{" "}
          সংযোগ ফিরলে মিস হওয়া নোটিফিকেশন নিজে থেকেই দেখা যাবে।
        </span>
      )}
    </div>
  );
}
