import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "POST required" }, 405);
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const publicKey = Deno.env.get("VAPID_PUBLIC_KEY");
  const privateKey = Deno.env.get("VAPID_PRIVATE_KEY");
  const subject = Deno.env.get("VAPID_SUBJECT");
  if (!url || !serviceKey || !publicKey || !privateKey || !subject) {
    return json({ error: "Missing Supabase or VAPID secrets" }, 500);
  }
  if (req.headers.get("authorization") !== "Bearer " + serviceKey) {
    return json({ error: "Unauthorized" }, 401);
  }

  webpush.setVapidDetails(subject, publicKey, privateKey);
  const db = createClient(url, serviceKey, { auth: { persistSession: false } });
  const today = new Date().toISOString().slice(0, 10);
  const specs = [
    { days: 14, type: "reminder_14" },
    { days: 1, type: "reminder_1" },
    { days: 0, type: "reminder_0" },
  ];

  for (const spec of specs) {
    const d = new Date(today + "T00:00:00Z");
    d.setUTCDate(d.getUTCDate() + spec.days);
    const date = d.toISOString().slice(0, 10);
    const { data: rows, error } = await db.from("events")
      .select("id,class_id,title,date,time,notes,category").eq("date", date);
    if (error) return json({ error: error.message }, 500);
    for (const e of rows || []) {
      const key = "reminder:" + e.id + ":" + spec.type + ":" + date;
      const { error: insertError } = await db.from("push_queue").upsert({
        dedupe_key: key, class_id: e.class_id, event_id: String(e.id),
        notification_type: spec.type, event_title: e.title, event_date: e.date,
        event_time: e.time, event_notes: e.notes, event_category: e.category,
      }, { onConflict: "dedupe_key", ignoreDuplicates: true });
      if (insertError) return json({ error: insertError.message }, 500);
    }
  }

  const { data: queue, error: qError } = await db.from("push_queue")
    .select("*").is("processed_at", null).order("created_at").limit(100);
  if (qError) return json({ error: qError.message }, 500);
  let sent = 0;
  let failed = 0;
  for (const item of queue || []) {
    const { data: subs, error: sError } = await db.from("push_subscriptions")
      .select("id,user_id,endpoint,p256dh,auth").eq("class_id", item.class_id);
    if (sError) { failed++; continue; }
    const headings: Record<string, string> = {
      new: "New class event", updated: "Event updated", deleted: "Event cancelled",
      reminder_14: "Event in 14 days", reminder_1: "Event tomorrow", reminder_0: "Event today",
    };
    const body = item.event_title + (item.event_date ? " · " + item.event_date : "") +
      (item.event_time ? " · " + item.event_time : "") +
      (item.event_category ? " · " + item.event_category : "") +
      (item.event_notes ? "\n" + item.event_notes : "");
    const payload = JSON.stringify({
      title: headings[item.notification_type] || "Schedul-ER update",
      body, tag: "schedul-er-" + item.event_id + "-" + item.notification_type, url: "/",
    });

    for (const sub of subs || []) {
      const { data: delivered } = await db.from("push_delivery_log")
        .select("id").eq("queue_id", item.id).eq("user_id", sub.user_id).maybeSingle();
      if (delivered) continue;
      try {
        await webpush.sendNotification({
          endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth },
        }, payload, { TTL: 86400 });
        const { error: logError } = await db.from("push_delivery_log")
          .insert({ queue_id: item.id, user_id: sub.user_id });
        if (logError && logError.code !== "23505") throw logError;
        sent++;
      } catch (err) {
        failed++;
        const status = (err as { statusCode?: number }).statusCode;
        if (status === 404 || status === 410) {
          await db.from("push_subscriptions").delete().eq("id", sub.id);
        }
      }
    }
    const { error: markError } = await db.from("push_queue")
      .update({ processed_at: new Date().toISOString() }).eq("id", item.id);
    if (markError) failed++;
  }
  return json({ ok: true, queued: queue?.length || 0, sent, failed });
});
