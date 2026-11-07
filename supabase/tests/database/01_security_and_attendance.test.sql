-- =====================================================================
-- Gym Pro — database integration test: security, attendance, QR, booking.
--
-- Runs against a database where all migrations are applied (CI: `supabase
-- start`). Everything happens inside a transaction that is ALWAYS rolled
-- back, so it is safe on any database. Any failed assertion aborts psql with
-- a non-zero exit code:
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/database/01_security_and_attendance.test.sql
-- =====================================================================
begin;

-- Helpers (live only for this transaction) ------------------------------
create function pg_temp.as_user(p_uid uuid, p_app_role text) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'role', 'authenticated', 'app_role', p_app_role)::text, true);
  execute 'set local role authenticated';
end $$;

create function pg_temp.as_postgres() returns void
language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claims', '', true);
end $$;

-- Runs a statement as the given user and returns the error text ('' when it succeeded).
create function pg_temp.error_of(p_uid uuid, p_app_role text, p_sql text) returns text
language plpgsql as $$
declare v text := '';
begin
  perform pg_temp.as_user(p_uid, p_app_role);
  begin
    execute p_sql;
  exception when others then
    v := sqlstate || ': ' || sqlerrm;
  end;
  perform pg_temp.as_postgres();
  return v;
end $$;

do $test$
declare
  u_admin uuid := gen_random_uuid();
  u_rec   uuid := gen_random_uuid();
  u_ok    uuid := gen_random_uuid();   -- active membership
  u_ok2   uuid := gen_random_uuid();   -- active membership (QR flow)
  u_noms  uuid := gen_random_uuid();   -- no membership
  u_inact uuid := gen_random_uuid();   -- deactivated
  u_meta  uuid := gen_random_uuid();   -- tries to self-assign admin at sign-up
  u_app   uuid := gen_random_uuid();   -- admin through app_metadata
  v_hall int; v_sess1 int; v_sess2 int;
  n int; err text; tok text; j jsonb; r text;
begin
  -- ---- fixtures ------------------------------------------------------
  insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data) values
    (u_admin, 't-admin@test.local', '{"role":"admin"}',     '{"name":"Admin"}'),
    (u_rec,   't-rec@test.local',   '{"role":"reception"}', '{"name":"Reception"}'),
    (u_ok,    't-ok@test.local',    '{"role":"trainee"}',   '{"name":"Trainee OK"}'),
    (u_ok2,   't-ok2@test.local',   '{"role":"trainee"}',   '{"name":"Trainee OK2"}'),
    (u_noms,  't-noms@test.local',  '{"role":"trainee"}',   '{"name":"Trainee No Membership"}'),
    (u_inact, 't-inact@test.local', '{"role":"trainee"}',   '{"name":"Trainee Inactive"}'),
    (u_meta,  't-meta@test.local',  '{}', '{"name":"Sneaky","role":"admin"}'),
    (u_app,   't-app@test.local',   '{"role":"admin"}',     '{"name":"App Admin"}');

  update public.profiles set is_active = false where id = u_inact;
  insert into public.memberships (trainee_id, start_date, end_date) values
    (u_ok,  current_date - 5, current_date + 30),
    (u_ok2, current_date - 5, current_date + 30);
  insert into public.halls (name, capacity) values ('Test hall', 50) returning id into v_hall;
  insert into public.sessions (name, hall_id, start_date, end_date, capacity)
    values ('Capacity 2', v_hall, current_date, current_date + 7, 2) returning id into v_sess1;
  insert into public.sessions (name, hall_id, start_date, end_date, capacity)
    values ('Capacity 10', v_hall, current_date, current_date + 7, 10) returning id into v_sess2;

  -- ---- A. new-user trigger never trusts user_metadata ----------------
  select role::text into r from public.profiles where id = u_meta;
  assert r = 'trainee', 'A1 role from user_metadata must be ignored, got ' || coalesce(r, 'null');
  select role::text into r from public.profiles where id = u_app;
  assert r = 'admin', 'A2 role from app_metadata must be used, got ' || coalesce(r, 'null');

  -- ---- B. profiles: protected columns --------------------------------
  perform pg_temp.as_user(u_inact, 'trainee');
  update public.profiles set is_active = true where id = u_inact;
  get diagnostics n = row_count;
  perform pg_temp.as_postgres();
  assert n = 0, 'B1 a deactivated user must not re-activate himself (rows=' || n || ')';

  perform pg_temp.as_user(u_noms, 'trainee');
  update public.profiles set role = 'admin' where id = u_noms;
  get diagnostics n = row_count;
  perform pg_temp.as_postgres();
  assert n = 0, 'B2 a trainee must not promote himself (rows=' || n || ')';

  -- guard trigger on its own: bypass RLS (postgres) but keep a non-admin identity
  perform set_config('request.jwt.claims',
    json_build_object('sub', u_noms, 'role', 'authenticated', 'app_role', 'trainee')::text, true);
  begin
    update public.profiles set role = 'trainer' where id = u_noms;
    raise exception 'B3 guard trigger did not block a role change';
  exception when others then
    assert sqlerrm like 'PROFILE_FIELD_PROTECTED%', 'B3 unexpected error: ' || sqlerrm;
  end;
  perform pg_temp.as_postgres();

  perform pg_temp.as_user(u_admin, 'admin');
  update public.profiles set role = 'trainer' where id = u_noms;
  get diagnostics n = row_count;
  perform pg_temp.as_postgres();
  assert n = 1, 'B4 an admin must be able to change a role (rows=' || n || ')';
  update public.profiles set role = 'trainee' where id = u_noms;

  -- ---- C. anonymous access -------------------------------------------
  execute 'set local role anon';
  begin
    perform count(*) from public.profiles;
    raise exception 'C1 anon could read profiles';
  exception when insufficient_privilege then null;
  end;
  perform pg_temp.as_postgres();

  err := pg_temp.error_of(u_noms, 'trainee', 'select count(*) from public.trainee_qr_tokens');
  assert err like '42501%', 'C2 signed-in users must not read QR tokens directly: ' || err;

  assert not has_function_privilege('anon', 'public.is_admin()', 'execute'), 'C3 anon can execute is_admin()';
  assert not has_function_privilege('anon', 'public.record_attendance(uuid, public.attendance_method, integer)', 'execute'), 'C4 anon can execute record_attendance';
  assert not has_function_privilege('authenticated', 'public.trg_notify_booking_created()', 'execute'), 'C5 trigger function callable as RPC';

  -- ---- D. manual attendance ------------------------------------------
  err := pg_temp.error_of(u_ok, 'trainee', format('select public.record_attendance(%L, ''manual'')', u_ok));
  assert err like '%PERMISSION_DENIED%', 'D1 trainee must not record attendance: ' || err;

  err := pg_temp.error_of(u_rec, 'reception', format('select public.record_attendance(%L, ''manual'')', u_inact));
  assert err like '%TRAINEE_NOT_FOUND_OR_INACTIVE%', 'D2 inactive trainee: ' || err;

  err := pg_temp.error_of(u_rec, 'reception', format('select public.record_attendance(%L, ''manual'')', u_noms));
  assert err like '%MEMBERSHIP_EXPIRED%', 'D3 no membership: ' || err;

  err := pg_temp.error_of(u_rec, 'reception', format('select public.record_attendance(%L, ''manual'')', u_ok));
  assert err = '', 'D4 valid check-in failed: ' || err;
  select count(*) into n from public.attendance where trainee_id = u_ok;
  assert n = 1, 'D4 expected one attendance row, got ' || n;

  err := pg_temp.error_of(u_rec, 'reception', format('select public.record_attendance(%L, ''manual'')', u_ok));
  assert err like '%ALREADY_CHECKED_IN%', 'D5 duplicate check-in: ' || err;

  -- the unique index also protects direct inserts
  begin
    insert into public.attendance (trainee_id, method) values (u_ok, 'manual');
    raise exception 'D6 unique index did not stop a duplicate insert';
  exception when unique_violation then null;
  end;

  -- ---- E. single-use QR ------------------------------------------------
  perform pg_temp.as_user(u_ok2, 'trainee');
  tok := public.issue_trainee_qr_token();
  perform pg_temp.as_postgres();
  assert tok like 'gympro_qr_v1:%', 'E1 unexpected token format';

  perform pg_temp.as_user(u_rec, 'reception');
  j := public.check_in_by_qr(tok);
  perform pg_temp.as_postgres();
  assert j ? 'trainee_name' and j->>'method' = 'qr', 'E2 QR check-in result: ' || j::text;

  err := pg_temp.error_of(u_rec, 'reception', format('select public.check_in_by_qr(%L)', tok));
  assert err like '%INVALID_OR_EXPIRED_QR%', 'E3 token reuse must fail: ' || err;

  -- a failed check-in must not burn the token
  perform pg_temp.as_user(u_noms, 'trainee');
  tok := public.issue_trainee_qr_token();
  perform pg_temp.as_postgres();
  err := pg_temp.error_of(u_rec, 'reception', format('select public.check_in_by_qr(%L)', tok));
  assert err like '%MEMBERSHIP_EXPIRED%', 'E4 expired membership via QR: ' || err;
  select count(*) into n from public.trainee_qr_tokens where trainee_id = u_noms;
  assert n = 1, 'E5 token must survive a failed check-in, count=' || n;

  -- ---- F. booking rules ----------------------------------------------
  insert into public.bookings (trainee_id, session_id, status) values (u_ok, v_sess1, 'confirmed');
  insert into public.bookings (trainee_id, session_id, status) values (u_ok2, v_sess1, 'confirmed');
  begin
    insert into public.bookings (trainee_id, session_id, status) values (u_noms, v_sess1, 'confirmed');
    raise exception 'F1 booking over capacity was accepted';
  exception when others then
    assert sqlerrm like '%SESSION_FULL%', 'F1 unexpected error: ' || sqlerrm;
  end;

  err := pg_temp.error_of(u_inact, 'trainee',
    format('insert into public.bookings (trainee_id, session_id, status) values (%L, %s, ''confirmed'')', u_inact, v_sess2));
  assert err like '42501%', 'F2 deactivated trainee must not book: ' || err;

  err := pg_temp.error_of(u_noms, 'trainee',
    format('insert into public.bookings (trainee_id, session_id, status) values (%L, %s, ''confirmed'')', u_noms, v_sess2));
  assert err = '', 'F3 active trainee must be able to book: ' || err;

  raise notice 'ALL DATABASE TESTS PASSED';
end
$test$;

rollback;
