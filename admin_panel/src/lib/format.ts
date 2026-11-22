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
