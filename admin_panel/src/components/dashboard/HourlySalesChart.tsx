"use client";

import styles from "./HourlySalesChart.module.css";
import { useState } from "react";
import { EmptyState } from "@/components/ui/bits";
import type { ApiDashboard } from "@/lib/api/types";
import { bnDigits, money } from "@/lib/format";

type Hour = ApiDashboard["hourly_sales"][number];

function clock(hour: number) {
  return bnDigits(hour % 12 || 12);
}

function timeOfDay(hour: number) {
  const localHour = hour % 24;
  if (localHour < 5 || localHour >= 20) return "রাত";
  if (localHour < 12) return "সকাল";
  if (localHour < 15) return "দুপুর";
  if (localHour < 18) return "বিকাল";
  return "সন্ধ্যা";
}

function range(hour: number) {
  const start = timeOfDay(hour);
  const end = timeOfDay(hour + 1);
  return `${start} ${clock(hour)}:০০–${start === end ? "" : `${end} `}${clock(hour + 1)}:০০`;
}

function axisStep(value: number) {
  const raw = Math.max(value / 4, 1);
  const magnitude = 10 ** Math.floor(Math.log10(raw));
  return ([1, 1.25, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10].find((step) => step * magnitude >= raw) ?? 10) * magnitude;
}

export function HourlySalesChart({ hours, periodLabel }: { hours: Hour[]; periodLabel: string }) {
  const [selectedHour, setSelectedHour] = useState<number>();
  const [previewHour, setPreviewHour] = useState<number>();
  const peak = hours.reduce<Hour | undefined>((best, hour) => !best || hour.total > best.total ? hour : best, undefined);
  const active = hours.find(({ hour }) => hour === (previewHour ?? selectedHour)) ?? peak;
  const step = axisStep(peak?.total ?? 0);
  const ticks = [4, 3, 2, 1, 0].map((n) => n * step);

  return (
    <section className={`cd ${styles["hourly-sales"]}`} aria-labelledby="hourly-sales-title">
      <div className={`sh ${styles["hourly-sales-header"]}`}>
        <div>
          <h2 className="h2" id="hourly-sales-title">ঘণ্টাভিত্তিক বিক্রি</h2>
          <div className="mu">বাংলাদেশ সময়</div>
        </div>
        <span className={styles["hourly-period"]}>{periodLabel}</span>
      </div>
      {active && hours.some((hour) => hour.count > 0) ? (
        <div className={styles["hourly-body"]}>
          <div className={styles["hourly-scroll"]}>
            <div className={styles["hourly-chart"]}>
              <div className={styles["hourly-axis"]} aria-hidden="true">
                {ticks.map((tick) => <span key={tick}>{money(tick)}</span>)}
              </div>
              <div className={styles["hourly-plot"]} role="group" aria-label="প্রতি ঘণ্টার বিক্রি">
                <div className={styles["hourly-grid"]} aria-hidden="true">
                  {ticks.map((tick) => <span key={tick} />)}
                </div>
                <div className={styles["hourly-bars"]}>
                  {hours.map((hour) => (
                    <button
                      key={hour.hour}
                      type="button"
                      className={styles["hourly-bar"]}
                      data-peak={hour.hour === peak?.hour}
                      aria-label={`${range(hour.hour)}, ${money(hour.total)}, ${bnDigits(hour.count)}টি বিক্রি`}
                      aria-pressed={hour.hour === (selectedHour ?? peak?.hour)}
                      data-active={hour.hour === active.hour}
                      onMouseEnter={() => setPreviewHour(hour.count > 0 ? hour.hour : undefined)}
                      onMouseLeave={() => setPreviewHour(undefined)}
                      onFocus={() => setPreviewHour(hour.hour)}
                      onBlur={() => setPreviewHour(undefined)}
                      onClick={() => setSelectedHour(hour.hour)}
                    >
                      <span style={{ height: `${(hour.total / ticks[0]) * 100}%` }} />
                    </button>
                  ))}
                </div>
              </div>
              <div className={styles["hourly-labels"]} aria-hidden="true">
                {hours.map(({ hour }) => <span key={hour}>{hour % 3 === 0 ? `${timeOfDay(hour)} ${clock(hour)}টা` : ""}</span>)}
              </div>
            </div>
          </div>
          <div className={styles["hourly-summary"]}>
            <div className={styles["hourly-selection"]}>
              <span>{active.hour === peak?.hour ? "সর্বোচ্চ বিক্রির ঘণ্টা" : "নির্বাচিত ঘণ্টা"}</span>
              <strong>{range(active.hour)}</strong>
            </div>
            <dl className={styles["hourly-metrics"]}>
              <div><dt>মোট বিক্রি</dt><dd>{money(active.total)}</dd></div>
              <div><dt>বিক্রির সংখ্যা</dt><dd>{bnDigits(active.count)}</dd></div>
            </dl>
          </div>
        </div>
      ) : (
        <EmptyState icon="chart" title="এই সময়ে কোনো বিক্রি হয়নি" />
      )}
    </section>
  );
}
