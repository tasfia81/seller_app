const PATHS = {
  back: "M15 6l-6 6 6 6",
  bell: "M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z M10 21h4",
  chat: "M20 12a8 8 0 0 1-11.6 7.1L4 20l1-4.4A8 8 0 1 1 20 12z M8.5 10.5h7 M8.5 13.5h4",
  send: "M21 3L10 14 M21 3l-6.5 18-4.5-7-7-4.5z",
  search: "M11 4a7 7 0 1 1 0 14a7 7 0 1 1 0-14 M20 20l-4-4",
  plus: "M12 5v14M5 12h14",
  check: "M5 12l5 5 9-10",
  x: "M6 6l12 12M18 6L6 18",
  chev: "M9 6l6 6-6 6",
  box: "M4 8l8-4 8 4v8l-8 4-8-4z M4 8l8 4 8-4 M12 12v8",
  users: "M9 5a3.5 3.5 0 1 1 0 7a3.5 3.5 0 1 1 0-7 M2.5 20c.8-3.5 3.3-5 6.5-5s5.7 1.5 6.5 5 M16 5.5a3 3 0 0 1 0 6 M17.5 15c2 .5 3.5 2 4 5",
  cash: "M3 6h18v12H3z M12 9a3 3 0 1 1 0 6a3 3 0 1 1 0-6",
  receipt: "M6 3h12v18l-3-2-3 2-3-2-3 2z M9 8h6 M9 12h6",
  chart: "M4 20V11 M10 20V5 M16 20v-6 M22 20H2",
  trend: "M3 17l6-6 4 4 8-8 M15 7h6v6",
  alert: "M12 3l10 18H2z M12 10v4 M12 17v.5",
  shield: "M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z",
  cal: "M3 5h18v16H3z M3 10h18 M8 3v4 M16 3v4",
  doc: "M6 3h9l4 4v14H6z M9 12h7 M9 16h5",
  img: "M3 4h18v16H3z M3 16l5-5 5 5 3-3 5 5",
  truck: "M2 6h12v10H2z M14 10h4l3 3v3h-7 M6 17.5a1.5 1.5 0 1 1 0 3a1.5 1.5 0 1 1 0-3 M17 17.5a1.5 1.5 0 1 1 0 3a1.5 1.5 0 1 1 0-3",
  ret: "M9 14l-5-5 5-5 M4 9h10a6 6 0 0 1 0 12h-3",
  gear: "M12 9a3 3 0 1 1 0 6a3 3 0 1 1 0-6 M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9L7 7M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1",
  lock: "M5 10h14v11H5z M8 10V7a4 4 0 0 1 8 0v3",
  eye: "M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z M12 9a3 3 0 1 1 0 6a3 3 0 1 1 0-6",
  edit: "M4 20h4L19 9l-4-4L4 16z",
  clock: "M12 3a9 9 0 1 1 0 18a9 9 0 1 1 0-18 M12 7v5l3 2",
  tag: "M3 12l9-9h8v8l-9 9z M16 7v.5",
  zoom: "M11 4a7 7 0 1 1 0 14a7 7 0 1 1 0-14 M20 20l-4-4 M11 8v6M8 11h6",
  shirt: "M8 4l-4 3 2 4 2-1v10h8V10l2 1 2-4-4-3a4 4 0 0 1-8 0z",
  grid: "M4 4h7v7H4z M13 4h7v7h-7z M4 13h7v7H4z M13 13h7v7h-7z",
  dash: "M4 4h7v9H4z M13 4h7v5h-7z M13 11h7v9h-7z M4 15h7v5H4z",
  logout: "M14 4h5v16h-5 M10 8l-4 4 4 4 M6 12h10",
  phone: "M5 4h4l2 5-3 2a11 11 0 0 0 5 5l2-3 5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z",
  download: "M12 4v11 M7 10l5 5 5-5 M4 20h16",
  info: "M12 3a9 9 0 1 1 0 18a9 9 0 1 1 0-18 M12 11v5 M12 8v.5",
  wallet: "M3 7h16a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H3z M3 7l12-4v4 M16 13h2",
  history: "M3 12a9 9 0 1 0 3-6.7 M3 4v5h5 M12 8v4l3 2",
  key: "M8 11a4 4 0 1 1 0 8a4 4 0 1 1 0-8 M11 13l9-9 M17 7l3 3",
  flag: "M5 21V4 M5 4h11l-2 4 2 4H5",
  pkg: "M3 7l9-4 9 4-9 4z M3 7v10l9 4 9-4V7 M12 11v10",
  bag: "M5 8h14l-1 12H6z M9 8V6a3 3 0 0 1 6 0v2",
  menu: "M4 6h16M4 12h16M4 18h16",
} as const;

export type IconName = keyof typeof PATHS;

export function Icon({ name, size = 20, color = "currentColor", className }: { name: IconName; size?: number; color?: string; className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      aria-hidden="true"
      className={className}
      style={{ flex: "none" }}
      fill="none"
      stroke={color}
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <path d={PATHS[name]} />
    </svg>
  );
}
