-- =====================================================================
-- Gym Pro — 06: security hardening + atomic attendance + booking capacity
--
-- Applies cleanly on:
--   (a) the live project after the history repair described in
--       the README section "Existing project: aligning migration history", and
--   (b) a fresh project after migrations 01..04.
-- Every statement is idempotent or guarded, and was checked against the
-- live data (no duplicate attendance rows, no over-capacity sessions).
--
-- DEPLOY ORDER: deploy the updated `create-user` Edge Function BEFORE
-- applying this migration (section 2 stops trusting client-supplied roles).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. The auth hook reads profiles as supabase_auth_admin. The live project
--    has this privilege; a fresh project does not unless it is granted.
-- ---------------------------------------------------------------------
grant usage  on schema public          to supabase_auth_admin;
grant select on public.profiles        to supabase_auth_admin;

-- ---------------------------------------------------------------------
-- 1. profiles: users must not be able to edit authorization fields.
--    The app never updates a profile as its owner (only the admin screen
--    does, via profiles_update_admin), so the self-update policy is removed.
--    The trigger is defense in depth for any future policy.
-- ---------------------------------------------------------------------
drop policy if exists profiles_update_self on public.profiles;

create or replace function public.guard_profile_protected_columns()
returns trigger
language plpgsql
set search_path to 'public', 'pg_temp'
as $$
begin
  -- auth.uid() is null for service_role / SQL editor / postgres: allowed.
  if auth.uid() is not null and not public.is_admin() then
    if new.id        is distinct from old.id
    or new.role      is distinct from old.role
    or new.is_active is distinct from old.is_active
    or new.email     is distinct from old.email then
      raise exception 'PROFILE_FIELD_PROTECTED: role, is_active and email can only be changed by an administrator'
        using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_profile_protected_columns on public.profiles;
create trigger guard_profile_protected_columns
  before update on public.profiles
  for each row execute function public.guard_profile_protected_columns();

-- ---------------------------------------------------------------------
-- 2. handle_new_user: the role must come from raw_app_meta_data, which only
--    the service role / Admin API can set. raw_user_meta_data is writable by
--    anyone who can call /auth/v1/signup, so it can no longer decide the role.
--    (Also disable public sign-ups in Dashboard > Authentication.)
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path to 'public'
as $$
declare
  v_role public.user_role;
begin
  v_role := case
    when new.raw_app_meta_data->>'role' in ('admin','reception','trainer','trainee')
      then (new.raw_app_meta_data->>'role')::public.user_role
    else 'trainee'::public.user_role
  end;

  insert into public.profiles (id, name, phone, email, role, gender)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'بدون اسم'),
    new.raw_user_meta_data->>'phone',
    new.email,
    v_role,
    coalesce((new.raw_user_meta_data->>'gender')::public.gender_type, 'male')
  );
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 3. Function privileges (least privilege)
-- ---------------------------------------------------------------------
-- Role helpers: needed by RLS for signed-in users only.
revoke execute on function public.is_admin(), public.is_staff(),
                           public.is_trainer(), public.is_reception()
  from public, anon;
grant  execute on function public.is_admin(), public.is_staff(),
                           public.is_trainer(), public.is_reception()
  to authenticated, service_role;

-- Trigger functions are never meant to be called as RPC (triggers still fire).
revoke execute on function public.trg_notify_booking_created(),
                           public.trg_notify_membership_created(),
                           public.trg_notify_private_schedule_created(),
                           public.trg_notify_trainer_assigned()
  from public, anon, authenticated;

-- QR RPCs: signed-in users only (anon kept an explicit grant on the live DB).
revoke all on function public.issue_trainee_qr_token()        from public, anon;
revoke all on function public.resolve_trainee_qr_token(text)  from public, anon;
grant execute on function public.issue_trainee_qr_token()       to authenticated;
grant execute on function public.resolve_trainee_qr_token(text) to authenticated;

-- Anonymous callers have no business touching any table or sequence.
-- RLS stays the authority; this removes the grant as a second layer.
revoke all on all tables    in schema public from anon;
revoke all on all sequences in schema public from anon;
alter default privileges for role postgres in schema public revoke all on tables    from anon;
alter default privileges for role postgres in schema public revoke all on sequences from anon;

-- QR tokens are reachable only through the SECURITY DEFINER RPCs.
revoke all on public.trainee_qr_tokens from anon, authenticated;
drop policy if exists trainee_qr_tokens_no_direct_access on public.trainee_qr_tokens;
create policy trainee_qr_tokens_no_direct_access on public.trainee_qr_tokens
  as restrictive for all to anon, authenticated using (false) with check (false);
comment on table public.trainee_qr_tokens is
  'Hashed short-lived QR tokens. No direct access: use issue_trainee_qr_token / check_in_by_qr.';

-- ---------------------------------------------------------------------
-- 4. Inactive users must not be able to write as trainees
-- ---------------------------------------------------------------------
create or replace function public.is_active_user()
returns boolean
language sql stable security definer
set search_path to 'public', 'pg_temp'
as $$
  select coalesce((select is_active from public.profiles where id = auth.uid()), false);
$$;
revoke execute on function public.is_active_user() from public, anon;
grant  execute on function public.is_active_user() to authenticated, service_role;

drop policy if exists bookings_write on public.bookings;
create policy bookings_write on public.bookings
  as permissive for all to authenticated
  using      (is_staff() or (trainee_id = (select auth.uid()) and public.is_active_user()))
  with check (is_staff() or (trainee_id = (select auth.uid()) and public.is_active_user()));

-- ---------------------------------------------------------------------
-- 5. Booking capacity enforced by the database (was: client count-then-insert)
--    FOR UPDATE on the session row serializes concurrent bookings.
-- ---------------------------------------------------------------------
create or replace function public.enforce_booking_capacity()
returns trigger
language plpgsql security definer
set search_path to 'public', 'pg_temp'
as $$
declare
  v_capacity integer;
  v_status   public.session_status;
  v_count    integer;
begin
  if new.status <> 'confirmed' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status = 'confirmed' and old.session_id = new.session_id then
    return new;
  end if;

  select capacity, status into v_capacity, v_status
  from public.sessions where id = new.session_id for update;

  if not found then
    raise exception 'SESSION_NOT_FOUND' using errcode = 'P0002';
  end if;
  if v_status <> 'scheduled' then
    raise exception 'SESSION_NOT_BOOKABLE' using errcode = 'P0001';
  end if;

  select count(*) into v_count
  from public.bookings
  where session_id = new.session_id and status = 'confirmed'
    and id is distinct from new.id;

  if v_count >= v_capacity then
    raise exception 'SESSION_FULL' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
revoke execute on function public.enforce_booking_capacity() from public, anon, authenticated;

drop trigger if exists enforce_booking_capacity on public.bookings;
create trigger enforce_booking_capacity
  before insert or update of status, session_id on public.bookings
  for each row execute function public.enforce_booking_capacity();

-- ---------------------------------------------------------------------
-- 6. Attendance: one check-in per trainee / day / session-or-gym (gym time
--    zone), enforced by the database, plus atomic RPCs.
--    Change the zone below if the gym is not on Damascus time.
-- ---------------------------------------------------------------------
create unique index if not exists uq_attendance_trainee_day_session
  on public.attendance (
    trainee_id,
    ((check_in_time at time zone 'Asia/Damascus')::date),
    (coalesce(session_id, 0))
  );

create or replace function public.record_attendance(
  p_trainee_id uuid,
  p_method     public.attendance_method,
  p_session_id integer default null
)
returns public.attendance
language plpgsql security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare
  v_end_date date;
  v_status   public.membership_status;
  v_row      public.attendance;
begin
  if not public.is_staff() then
    raise exception 'PERMISSION_DENIED' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = p_trainee_id and role = 'trainee' and is_active
  ) then
    raise exception 'TRAINEE_NOT_FOUND_OR_INACTIVE' using errcode = 'P0002';
  end if;

  -- same rule as the app: latest membership must be active and not ended
  select m.status, m.end_date into v_status, v_end_date
  from public.memberships m
  where m.trainee_id = p_trainee_id
  order by m.end_date desc
  limit 1;

  if v_status is null
     or v_status <> 'active'
     or v_end_date < (now() at time zone 'Asia/Damascus')::date then
    raise exception 'MEMBERSHIP_EXPIRED' using errcode = 'P0001',
      detail = coalesce(v_end_date::text, '');
  end if;

  begin
    insert into public.attendance (trainee_id, session_id, method)
    values (p_trainee_id, p_session_id, p_method)
    returning * into v_row;
  exception when unique_violation then
    raise exception 'ALREADY_CHECKED_IN' using errcode = 'P0001';
  end;

  return v_row;
end;
$$;

-- Single-use QR check-in: the token is consumed and the attendance row is
-- written in ONE transaction. If anything fails (expired membership, duplicate)
-- the whole call rolls back and the token stays valid until its own expiry.
create or replace function public.check_in_by_qr(
  p_token      text,
  p_session_id integer default null
)
returns jsonb
language plpgsql security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare
  v_raw     text;
  v_trainee uuid;
  v_att     public.attendance;
  v_name    text;
begin
  if not public.is_staff() then
    raise exception 'PERMISSION_DENIED' using errcode = '42501';
  end if;

  if p_token is null or p_token not like 'gympro_qr_v1:%' then
    raise exception 'INVALID_QR' using errcode = 'P0001';
  end if;
  v_raw := substring(p_token from char_length('gympro_qr_v1:') + 1);

  delete from public.trainee_qr_tokens
  where token_hash = encode(digest(v_raw, 'sha256'), 'hex')
    and expires_at > now()
  returning trainee_id into v_trainee;

  if v_trainee is null then
    raise exception 'INVALID_OR_EXPIRED_QR' using errcode = 'P0001';
  end if;

  v_att := public.record_attendance(v_trainee, 'qr', p_session_id);
  select name into v_name from public.profiles where id = v_trainee;

  -- attendance row + the trainee's display name for the reception toast
  return to_jsonb(v_att) || jsonb_build_object('trainee_name', v_name);
end;
$$;

revoke all on function public.record_attendance(uuid, public.attendance_method, integer) from public, anon;
revoke all on function public.check_in_by_qr(text, integer)                              from public, anon;
grant execute on function public.record_attendance(uuid, public.attendance_method, integer) to authenticated;
grant execute on function public.check_in_by_qr(text, integer)                              to authenticated;

comment on function public.resolve_trainee_qr_token(text) is
  'DEPRECATED: not single-use and returns the full profile row. Use check_in_by_qr(). Drop once the app no longer calls it.';

-- ---------------------------------------------------------------------
-- 7. User deletion keeps financial history (payments are detached, not deleted)
--    and requires an ACTIVE admin as actor.
-- ---------------------------------------------------------------------
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
  if not exists (select 1 from public.profiles where id = actor_id and role = 'admin' and is_active) then
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
  -- financial history is kept: only the link to the deleted user is removed
  -- (the full row is still preserved in the archive snapshot above)
  update public.payment_costs set user_id = null where user_id = target_id;

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

revoke all on function public.admin_delete_user_cascade(uuid, uuid) from public, anon, authenticated;
grant execute on function public.admin_delete_user_cascade(uuid, uuid) to service_role;

-- ---------------------------------------------------------------------
-- 7b. Programs and diets can only be created for the trainer's own ACTIVE
--     trainees (was: any trainee id).
-- ---------------------------------------------------------------------
drop policy if exists tp_write_trainer on public.training_programs;
create policy tp_write_trainer on public.training_programs
  as permissive for insert to authenticated
  with check (
    is_trainer()
    and trainer_id = (select auth.uid())
    and exists (
      select 1 from public.trainer_trainees tt
      where tt.trainer_id = (select auth.uid())
        and tt.trainee_id = training_programs.trainee_id
        and tt.status = 'active'
    )
  );

drop policy if exists diets_write_trainer on public.diets;
create policy diets_write_trainer on public.diets
  as permissive for insert to authenticated
  with check (
    is_trainer()
    and trainer_id = (select auth.uid())
    and exists (
      select 1 from public.trainer_trainees tt
      where tt.trainer_id = (select auth.uid())
        and tt.trainee_id = diets.trainee_id
        and tt.status = 'active'
    )
  );

-- ---------------------------------------------------------------------
-- 7c. Notifications: the app only ever flips is_read, so only that column
--     is updatable (title/body/type can no longer be rewritten by the owner).
-- ---------------------------------------------------------------------
revoke update on public.notifications from authenticated;
grant  update (is_read) on public.notifications to authenticated;

-- ---------------------------------------------------------------------
-- 8. Housekeeping: unused duplicate enum left in the live project
--    (no column, function or default depends on it — verified).
-- ---------------------------------------------------------------------
drop type if exists public.gender;
