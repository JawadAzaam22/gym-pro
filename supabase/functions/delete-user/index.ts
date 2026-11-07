import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

// وضع الحذف:
// - mode = "safe" (الافتراضي): حذف عادي عبر auth.admin.deleteUser مباشرة.
//   ينجح فقط إذا لم توجد سجلات مرتبطة بالمستخدم إطلاقًا (يحفظ التاريخ كاملًا).
// - mode = "cascade": يستدعي أولاً admin_delete_user_cascade التي تأخذ لقطة JSON كاملة
//   لكل شيء يخص المستخدم في جدول deleted_users_archive (دائمًا للتقارير)،
//   ثم تحذف سجلاته الشخصية (عضويات، حضور، حجوزات...) وتُفرغ إسناد
//   العمليات التي تخص أشخاصًا آخرين (مثل تقرير أو دفعة لشخص آخر) بدل
//   حذفها، ثم تحذف حساب auth.users في النهاية (يحذف صف profiles تلقائيًا).
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const callerClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user: caller }, error: callerErr } = await callerClient.auth.getUser();
    if (callerErr || !caller) return json({ error: "غير مصرح - سجّل الدخول أولاً" }, 401);

    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data: callerProfile } = await adminClient
      .from("profiles").select("role").eq("id", caller.id).single();
    if (!callerProfile || callerProfile.role !== "admin") {
      return json({ error: "ممنوع - هذه العملية للأدمن فقط" }, 403);
    }

    const { id, mode } = await req.json();
    if (!id) return json({ error: "معرف المستخدم مطلوب" }, 400);
    if (id === caller.id) return json({ error: "لا يمكنك حذف حسابك الخاص" }, 400);

    if (mode === "cascade") {
      const { error: cascadeErr } = await adminClient.rpc("admin_delete_user_cascade", {
        target_id: id,
        actor_id: caller.id,
      });
      if (cascadeErr) {
        return json({ error: `فشل حذف السجلات المرتبطة: ${cascadeErr.message}` }, 400);
      }
    }

    const { error: deleteErr } = await adminClient.auth.admin.deleteUser(id);
    if (deleteErr) {
      const msg = String(deleteErr.message ?? "");
      if (/foreign key|23503|Database error deleting user/i.test(msg)) {
        return json({
          error: "لا يمكن حذف هذا المستخدم نهائيًا لوجود سجلات مرتبطة به. استخدم خيار الحذف الشامل (cascade) أو زر الإيقاف (حظر) بدلًا.",
          code: "HAS_RELATED_RECORDS",
        }, 409);
      }
      return json({ error: msg || "فشل حذف المستخدم" }, 400);
    }

    return json({ success: true, mode: mode === "cascade" ? "cascade" : "safe" });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
