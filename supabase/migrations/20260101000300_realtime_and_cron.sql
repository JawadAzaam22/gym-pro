-- =====================================================================
-- Gym Pro — 04: realtime + scheduled jobs
-- =====================================================================

-- Realtime for the notification bell
alter publication supabase_realtime add table public.notifications;

-- Daily jobs (pg_cron; times are UTC)
select cron.schedule('expire-memberships',          '0 0 * * *', $$SELECT public.expire_due_memberships()$$);
select cron.schedule('notify-expiring-memberships', '0 8 * * *', $$select public.notify_expiring_memberships()$$);
