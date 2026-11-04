-- =====================================================================
-- Gym Pro — 02: functions, triggers, grants
-- =====================================================================

-- ---------- JWT role helpers ----------
create or replace function public.app_role()
returns text
language sql
stable
set search_path to 'public', 'pg_temp'
as $$ select auth.jwt() ->> 'app_role'; $$;

create or replace function public.is_staff()
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select public.app_role() in ('admin','reception')
    and coalesce((select is_active from public.profiles where id = auth.uid()), false);
$$;

create or replace function public.is_trainer()
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select public.app_role() = 'trainer'
    and coalesce((select is_active from public.profiles where id = auth.uid()), false);
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select public.app_role() = 'admin'
    and coalesce((select is_active from public.profiles where id = auth.uid()), false);
$$;

create or replace function public.is_reception()
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select public.app_role() = 'reception'
    and coalesce((select is_active from public.profiles where id = auth.uid()), false);
$$;

-- ---------- Custom access token hook (adds app_role claim) ----------
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
set search_path to 'public', 'pg_temp'
as $$
declare
  claims jsonb;
  user_role public.user_role;
begin
  select role into user_role from public.profiles where id = (event->>'user_id')::uuid;
  claims := event->'claims';
  claims := jsonb_set(claims, '{app_role}', to_jsonb(coalesce(user_role::text, 'trainee')));
  event := jsonb_set(event, '{claims}', claims);
  return event;
end;
$$;

-- ---------- New auth user -> profile ----------
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path to 'public'
as $$
begin
  insert into public.profiles (id, name, phone, email, role, gender)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'بدون اسم'),
    new.raw_user_meta_data->>'phone',
    new.email,
    coalesce((new.raw_user_meta_data->>'role')::public.user_role, 'trainee'),
    coalesce((new.raw_user_meta_data->>'gender')::public.gender_type, 'male')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Memberships ----------
create or replace function public.expire_due_memberships()
returns integer
language plpgsql security definer
set search_path to 'public'
as $$
declare
  affected integer;
begin
  update memberships
     set status = 'expired'
   where status = 'active'
     and end_date < current_date;

  get diagnostics affected = row_count;
  return affected;
end;
$$;

-- ---------- Admin delete user (cascade + archive snapshot) ----------
create or replace function public.admin_delete_user_cascade(target_id uuid, actor_id uuid)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  target_name text;
  target_email text;
  target_role text;
  snap jsonb;
begin
  if not exists (select 1 from public.profiles where id = actor_id and role = 'admin') then
    raise exception 'PERMISSION_DENIED: العملية للأدمن فقط';
  end if;

  select name, email, role into target_name, target_email, target_role
  from public.profiles where id = target_id;

  if target_name is null then
    raise exception 'NOT_FOUND: المستخدم غير موجود';
  end if;

  -- لقطة كاملة (JSON) لكل شيء مرتبط بالمستخدم قبل أي حذف
  snap := jsonb_build_object(
    'profile', (select to_jsonb(p) from public.profiles p where p.id = target_id),
    'memberships', (select coalesce(jsonb_agg(to_jsonb(m)), '[]'::jsonb) from public.memberships m where m.trainee_id = target_id),
    'attendance', (select coalesce(jsonb_agg(to_jsonb(a)), '[]'::jsonb) from public.attendance a where a.trainee_id = target_id),
    'payment_costs', (select coalesce(jsonb_agg(to_jsonb(pc)), '[]'::jsonb) from public.payment_costs pc where pc.user_id = target_id or pc.recorded_by = target_id),
    'bookings', (select coalesce(jsonb_agg(to_jsonb(b)), '[]'::jsonb) from public.bookings b where b.trainee_id = target_id),
    'trainer_trainees', (select coalesce(jsonb_agg(to_jsonb(tt)), '[]'::jsonb) from public.trainer_trainees tt where tt.trainer_id = target_id or tt.trainee_id = target_id),
    'private_training_sessions', (select coalesce(jsonb_agg(to_jsonb(s)), '[]'::jsonb) from public.private_training_sessions s
        where s.recorded_by = target_id or s.trainer_trainee_id in (select id from public.trainer_trainees where trainer_id = target_id or trainee_id = target_id)),
    'private_training_schedule', (select coalesce(jsonb_agg(to_jsonb(s)), '[]'::jsonb) from public.private_training_schedule s
        where s.trainer_trainee_id in (select id from public.trainer_trainees where trainer_id = target_id or trainee_id = target_id)),
    'training_programs', (select coalesce(jsonb_agg(to_jsonb(tp)), '[]'::jsonb) from public.training_programs tp where tp.trainer_id = target_id or tp.trainee_id = target_id),
    'diets', (select coalesce(jsonb_agg(to_jsonb(d)), '[]'::jsonb) from public.diets d where d.trainer_id = target_id or d.trainee_id = target_id),
    'sessions_taught', (select coalesce(jsonb_agg(to_jsonb(s)), '[]'::jsonb) from public.sessions s where s.trainer_id = target_id or s.created_by = target_id),
    'reports_generated', (select coalesce(jsonb_agg(to_jsonb(r)), '[]'::jsonb) from public.reports r where r.generated_by = target_id),
    'access_periods', (select coalesce(jsonb_agg(to_jsonb(ap)), '[]'::jsonb) from public.access_periods ap where ap.trainer_id = target_id)
  );

  insert into public.deleted_users_archive
    (deleted_user_id, deleted_user_name, deleted_user_email, deleted_user_role, deleted_by, snapshot)
  values (target_id, target_name, target_email, target_role, actor_id, snap);

  -- حذف السجلات الشخصية للمستخدم فقط.
  -- private_training_sessions قبل trainer_trainees (علاقتها NO ACTION)،
  -- و private_training_schedule تُحذف تلقائيًا (CASCADE).
  delete from public.private_training_sessions
    where recorded_by = target_id
       or trainer_trainee_id in (select id from public.trainer_trainees where trainer_id = target_id or trainee_id = target_id);
  delete from public.training_programs where trainer_id = target_id or trainee_id = target_id;
  delete from public.diets where trainer_id = target_id or trainee_id = target_id;
  delete from public.trainer_trainees where trainer_id = target_id or trainee_id = target_id;
  delete from public.bookings where trainee_id = target_id;
  delete from public.attendance where trainee_id = target_id;
  delete from public.memberships where trainee_id = target_id;
  delete from public.payment_costs where user_id = target_id;

  -- تفريغ الإسناد فقط في السجلات المشتركة
  update public.memberships set recorded_by = null where recorded_by = target_id;
  update public.payment_costs set recorded_by = null where recorded_by = target_id;
  update public.trainer_trainees set assigned_by = null where assigned_by = target_id;
  update public.reports set generated_by = null where generated_by = target_id;
  update public.sessions set trainer_id = null where trainer_id = target_id;
  update public.sessions set created_by = null where created_by = target_id;
  update public.access_periods set trainer_id = null where trainer_id = target_id;

  return snap;
end;
$$;

-- ---------- Notifications ----------
create or replace function public.create_notification(
  p_user_id uuid, p_type text, p_title text, p_body text, p_data jsonb default null
)
returns void
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  insert into public.notifications (user_id, type, title, body, data)
  values (p_user_id, p_type, p_title, p_body, p_data);
end;
$$;

create or replace function public.trg_notify_membership_created()
returns trigger
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
begin
  perform public.create_notification(
    new.trainee_id, 'membership_created', 'تم تفعيل عضويتك',
    'عضويتك سارية حتى ' || to_char(new.end_date, 'YYYY-MM-DD'),
    jsonb_build_object('screen', 'membership')
  );
  return new;
end;
$$;

create or replace function public.trg_notify_trainer_assigned()
returns trigger
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  trainer_name text;
  trainee_name text;
begin
  if new.status = 'active' then
    select name into trainer_name from public.profiles where id = new.trainer_id;
    select name into trainee_name from public.profiles where id = new.trainee_id;
    perform public.create_notification(
      new.trainee_id, 'trainer_assigned', 'تم تعيين مدربك',
      'مدربك الآن: ' || coalesce(trainer_name, ''),
      jsonb_build_object('screen', 'my_trainer')
    );
    perform public.create_notification(
      new.trainer_id, 'trainee_assigned', 'متدرب جديد',
      'تم إسناد متدرب جديد إليك: ' || coalesce(trainee_name, ''),
      jsonb_build_object('screen', 'trainees')
    );
  end if;
  return new;
end;
$$;

create or replace function public.trg_notify_booking_created()
returns trigger
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  session_name text;
begin
  if new.status = 'confirmed' then
    select name into session_name from public.sessions where id = new.session_id;
    perform public.create_notification(
      new.trainee_id, 'booking_confirmed', 'تم تأكيد حجزك',
      coalesce(session_name, 'حصة جماعية'),
      jsonb_build_object('screen', 'my_bookings')
    );
  end if;
  return new;
end;
$$;

create or replace function public.trg_notify_private_schedule_created()
returns trigger
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_trainer_id uuid;
  v_trainee_id uuid;
begin
  select trainer_id, trainee_id into v_trainer_id, v_trainee_id
  from public.trainer_trainees where id = new.trainer_trainee_id;
  perform public.create_notification(
    v_trainee_id, 'fixed_schedule_created', 'موعد ثابت جديد',
    'تمت إضافة موعد ثابت جديد لجلساتك الخاصة',
    jsonb_build_object('screen', 'fixed_schedule')
  );
  perform public.create_notification(
    v_trainer_id, 'fixed_schedule_created', 'موعد ثابت جديد',
    'تمت إضافة موعد ثابت جديد في جدولك',
    jsonb_build_object('screen', 'fixed_schedule')
  );
  return new;
end;
$$;

create or replace function public.notify_expiring_memberships()
returns integer
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  affected integer := 0;
  m record;
begin
  for m in
    select id, trainee_id, end_date from public.memberships
    where status = 'active'
      and end_date between current_date and current_date + 3
  loop
    if not exists (
      select 1 from public.notifications
      where user_id = m.trainee_id
        and type = 'membership_expiring_soon'
        and (data->>'membership_id')::int = m.id
        and created_at > now() - interval '24 hours'
    ) then
      perform public.create_notification(
        m.trainee_id, 'membership_expiring_soon', 'عضويتك توشك على الانتهاء',
        'تنتهي عضويتك بتاريخ ' || to_char(m.end_date, 'YYYY-MM-DD') || '، بادر بالتجديد',
        jsonb_build_object('screen', 'membership', 'membership_id', m.id)
      );
      affected := affected + 1;
    end if;
  end loop;
  return affected;
end;
$$;

drop trigger if exists on_membership_created on public.memberships;
create trigger on_membership_created
  after insert on public.memberships
  for each row execute function public.trg_notify_membership_created();

drop trigger if exists on_trainer_assigned on public.trainer_trainees;
create trigger on_trainer_assigned
  after insert on public.trainer_trainees
  for each row execute function public.trg_notify_trainer_assigned();

drop trigger if exists on_booking_created on public.bookings;
create trigger on_booking_created
  after insert on public.bookings
  for each row execute function public.trg_notify_booking_created();

drop trigger if exists on_private_schedule_created on public.private_training_schedule;
create trigger on_private_schedule_created
  after insert on public.private_training_schedule
  for each row execute function public.trg_notify_private_schedule_created();

-- ---------- Grants (mirrors the live project) ----------
-- Functions only the backend should call
revoke all on function public.admin_delete_user_cascade(uuid, uuid) from public, anon, authenticated;
grant execute on function public.admin_delete_user_cascade(uuid, uuid) to service_role;

revoke all on function public.handle_new_user() from public, anon, authenticated;
grant execute on function public.handle_new_user() to service_role;

-- Auth hook: only supabase_auth_admin may run it
revoke all on function public.custom_access_token_hook(jsonb) from public, anon, authenticated;
grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
grant usage on schema public to supabase_auth_admin;

-- expire_due_memberships: authenticated + service_role (as in the live project)
revoke all on function public.expire_due_memberships() from public, anon;
grant execute on function public.expire_due_memberships() to authenticated, service_role;

-- Notification functions: backend only (triggers/cron still work, they run as the owner)
revoke all on function public.create_notification(uuid, text, text, text, jsonb) from public, anon, authenticated;
grant execute on function public.create_notification(uuid, text, text, text, jsonb) to service_role;

revoke all on function public.notify_expiring_memberships() from public, anon, authenticated;
grant execute on function public.notify_expiring_memberships() to service_role;
