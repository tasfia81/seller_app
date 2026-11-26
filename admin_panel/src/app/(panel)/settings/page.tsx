import Link from "next/link";
import { Topbar } from "@/components/shell/Topbar";
import { Note } from "@/components/ui/bits";
import { ApiForm } from "@/components/ui/ApiForm";
import { api, load } from "@/lib/api/server";
import { submitOperation } from "../operational-actions";

export const metadata = { title: "সেটিংস" };

type Settings = { business: { name: string; phone: string; address: string }; inventory: {
  default_policy: string; low_stock_default: number; close_requires_cash: boolean; close_requires_returns: boolean };
  payments: Record<string, { enabled: boolean; destination: string }> };

const methods: Record<string, string> = { cash: "ক্যাশ", bkash: "বিকাশ", nagad: "নগদ", bank: "ব্যাংক", other: "অন্যান্য" };

export default async function SettingsPage() {
  const result = await load(() => api.get<Settings>("/admin/settings"));
  const settings = result.data;
  return <>
    <Topbar title="সেটিংস" />
    <main className="ct">
      <Link className="btn o" href="/account">প্রোফাইল ও নিরাপত্তা</Link>
      {!settings ? <Note kind="warn">{result.error}</Note> : <section className="cd">
        <ApiForm label="সেটিংস সংরক্ষণ" action={submitOperation.bind(null, "settings", "")}>
          <h2 className="h2">ব্যবসার প্রোফাইল</h2>
          <label>নাম<input className="in" name="name" defaultValue={settings.business.name} required /></label>
          <label>ফোন<input className="in" name="phone" defaultValue={settings.business.phone} /></label>
          <label>ঠিকানা<input className="in" name="address" defaultValue={settings.business.address} /></label>
          <h2 className="h2">স্টক ও দিন বন্ধ</h2>
          <label>ডিফল্ট স্টক নিয়ম<select className="in" name="default_policy" defaultValue={settings.inventory.default_policy}>
            <option value="daily_return">প্রতিদিন ফেরত</option><option value="carry_forward">পরের দিনে চলবে</option>
          </select></label>
          <label>কম স্টকের সীমা<input className="in" name="low_stock_default" type="number" min={0} defaultValue={settings.inventory.low_stock_default} required /></label>
          <label className="ck"><input type="checkbox" name="close_requires_cash" defaultChecked={settings.inventory.close_requires_cash} />দিন বন্ধের আগে ক্যাশ জমা ও যাচাই</label>
          <label className="ck"><input type="checkbox" name="close_requires_returns" defaultChecked={settings.inventory.close_requires_returns} />প্রযোজ্য হলে দিন বন্ধের আগে স্টক ফেরত</label>
          <h2 className="h2">পেমেন্টের মাধ্যম</h2>
          {Object.keys(methods).map((key) => <label className="ck" key={key}>
            <input type="checkbox" name={`payment:${key}`} defaultChecked={settings.payments[key]?.enabled} />{methods[key]}
          </label>)}
        </ApiForm>
      </section>}
    </main>
  </>;
}
