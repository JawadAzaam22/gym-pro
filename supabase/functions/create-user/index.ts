import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Optional: comma-separated list of allowed browser origins, e.g.
//   supabase secrets set ALLOWED_ORIGINS=https://admin.example.com,https://reception.example.com
// When unset the function answers "*" (JWT verification still applies).
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",").map((o) => o.trim()).filter(Boolean);

const ROLES = ["admin", "reception", "trainer", "trainee"] as const;
const GENDERS = ["male", "female"] as const;
type Role = typeof ROLES[number];

function corsFor(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") ?? "";
  const allow = ALLOWED_ORIGINS.length === 0
    ? "*"
    : ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

const reply = (req: Request, body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsFor(req), "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  // Browsers (Flutter Web) send an OPTIONS preflight before the real POST.
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsFor(req) });
  }

  try {
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // 1) Authenticate the caller from the bearer token.
    const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    const { data: { user: caller }, error: callerErr } = await admin.auth.getUser(token);
    if (callerErr || !caller) {
      return reply(req, { error: "غير مصرح - سجّل الدخول أولاً" }, 401);
    }

    // 2) Authorize from the profiles table (source of truth): active admin/reception only.
    const { data: callerProfile } = await admin
      .from("profiles").select("role, is_active").eq("id", caller.id).single();
    if (
      !callerProfile || !callerProfile.is_active ||
      !["admin", "reception"].includes(callerProfile.role)
    ) {
      return reply(req, { error: "ممنوع - هذه العملية لأدمن/استقبال فقط" }, 403);
    }

    // 3) Validate input.
    const body = await req.json();
    const name = String(body.name ?? "").trim();
    const email = String(body.email ?? "").trim().toLowerCase();
    const phone = body.phone ? String(body.phone).trim() : null;
    const password = String(body.password ?? "");
    const role = body.role as Role;
    const gender = body.gender;

    if (!name || !email || !password || !role || !gender) {
      return reply(req, { error: "بيانات ناقصة" }, 400);
    }
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      return reply(req, { error: "بريد إلكتروني غير صالح" }, 400);
    }
    if (password.length < 6) {
      return reply(req, { error: "كلمة المرور يجب ألا تقل عن 6 أحرف" }, 400);
    }
    if (!ROLES.includes(role)) {
      return reply(req, { error: "دور غير صالح" }, 400);
    }
    if (!GENDERS.includes(gender)) {
      return reply(req, { error: "قيمة الجنس غير صالحة" }, 400);
    }
    if (callerProfile.role === "reception" && role === "admin") {
      return reply(req, { error: "الاستقبال لا يمكنه إنشاء حساب أدمن" }, 403);
    }

    // 4) Create the auth user. The role goes into app_metadata (server-controlled);
    //    handle_new_user() reads it from there. user_metadata.role is still sent
    //    only so the function keeps working before the hardening migration is applied.
    const { data: created, error: createErr } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      app_metadata: { role },
      user_metadata: { name, phone, gender, role },
    });
    if (createErr || !created.user) {
      return reply(req, { error: createErr?.message ?? "فشل إنشاء الحساب" }, 400);
    }

    // 5) Return the profile row created by the trigger.
    const { data: profile } = await admin
      .from("profiles").select("*").eq("id", created.user.id).single();
    return reply(req, profile, 200);
  } catch (_e) {
    // Do not leak internals to the client.
    return reply(req, { error: "حدث خطأ غير متوقع" }, 500);
  }
});
