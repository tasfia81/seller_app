const BN = ["০", "১", "২", "৩", "৪", "৫", "৬", "৭", "৮", "৯"];

/** English digits → Bangla digits. */
export function bnDigits(input: string | number): string {
  return String(input).replace(/[0-9]/g, (d) => BN[Number(d)]);
}

/** Bangla digits → English digits (for parsing user input). */
export function toAscii(input: string): string {
  return input.replace(/[০-৯]/g, (d) => String(BN.indexOf(d)));
}

/** 124500 → ১,২৪,৫০০ (South Asian grouping). */
export function bnNumber(value: number, decimals = 0): string {
  const negative = value < 0;
  const [intPart, decPart] = Math.abs(value).toFixed(decimals).split(".");
  let grouped = intPart;
  if (intPart.length > 3) {
    const last3 = intPart.slice(-3);
    let rest = intPart.slice(0, -3);
    const groups: string[] = [];
    while (rest.length > 2) {
      groups.unshift(rest.slice(-2));
      rest = rest.slice(0, -2);
    }
    if (rest) groups.unshift(rest);
    grouped = `${groups.join(",")},${last3}`;
  }
  const dec = decPart?.replace(/0+$/, "");
  return bnDigits(`${negative ? "-" : ""}${grouped}${dec ? `.${dec}` : ""}`);
}

export const money = (value: number) => `৳${bnNumber(value, 2)}`;

/** Parse "৳৩,০০০" or "3000" into a number. */
export function parseMoney(input: string): number | null {
  const n = Number(toAscii(input).replace(/[^0-9.]/g, ""));
  return input.trim() === "" || Number.isNaN(n) ? null : n;
}

export function maskNid(nid: string): string {
  const digits = toAscii(nid).replace(/\D/g, "");
  return `•••• •••• ${bnDigits(digits.slice(-4))}`;
}

export function initials(name: string): string {
  const chars = Array.from(name.trim());
  if (!chars.length) return "?";
  const second = chars[1];
  return second && /[া-ৌ]/.test(second) ? chars[0] + second : chars[0];
}

const DHAKA = "Asia/Dhaka";
const MONTHS = ["জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর"];

function dhakaParts(iso: string) {
  const parts = new Intl.DateTimeFormat("en-GB", { timeZone: DHAKA, year: "numeric", month: "numeric", day: "numeric", hour: "numeric", minute: "2-digit", hour12: false })
    .formatToParts(new Date(iso));
  const get = (t: string) => Number(parts.find((p) => p.type === t)?.value ?? 0);
  return { y: get("year"), m: get("month"), d: get("day"), h: get("hour") % 24, min: get("minute") };
}

/** ISO time → "সকাল ১০:১৫" (Asia/Dhaka). */
export function bnTime(iso: string): string {
  const { h, min } = dhakaParts(iso);
  const period = h < 5 ? "রাত" : h < 12 ? "সকাল" : h < 15 ? "দুপুর" : h < 18 ? "বিকাল" : h < 20 ? "সন্ধ্যা" : "রাত";
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return `${period} ${bnDigits(`${h12}:${String(min).padStart(2, "0")}`)}`;
}

/** ISO or YYYY-MM-DD → "২২ নভেম্বর" (with year when asked). */
export function bnDate(iso: string, withYear = false): string {
  const { y, m, d } = iso.length === 10 ? { y: +iso.slice(0, 4), m: +iso.slice(5, 7), d: +iso.slice(8, 10) } : dhakaParts(iso);
  return `${bnDigits(d)} ${MONTHS[m - 1]}${withYear ? ` ${bnDigits(y)}` : ""}`;
}

export const bnDateTime = (iso: string) => `${bnDate(iso)}, ${bnTime(iso)}`;

/** Current date in Dhaka as YYYY-MM-DD (for date inputs). */
export function dhakaToday(): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Dhaka" }).format(new Date());
}
