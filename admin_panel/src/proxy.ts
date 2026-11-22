import { NextResponse, type NextRequest } from "next/server";
import { SESSION_COOKIE } from "@/lib/api/config";

/** Without a session cookie, every panel page goes to /login. (The backend still checks the token on each call.) */
export function proxy(request: NextRequest) {
  if (!request.cookies.has(SESSION_COOKIE)) {
    const url = new URL("/login", request.url);
    return NextResponse.redirect(url);
  }
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!login|forgot-password|_next/|favicon.ico|.*\\.(?:png|jpg|svg|ico|webp)$).*)"],
};
