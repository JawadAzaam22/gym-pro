-- =====================================================================
-- Gym Pro — complete setup for a NEW Supabase project (all migrations in order).
-- Do NOT run this on the existing project: it already has this schema.
-- Prefer `supabase db push`; use this file only with the SQL editor.
-- =====================================================================


-- >>>>>>>>>> 20260101000000_initial_schema.sql <<<<<<<<<<
-- =====================================================================
-- Gym Pro — 01: schema (extensions, enums, tables, indexes)
-- Baseline snapshot of the live project's public schema (column lengths,
-- defaults, constraints and indexes verified against the live database).
-- =====================================================================

create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pgcrypto    with schema extensions;
create extension if not exists pg_cron;

-- ---------- Enums ----------
create type public.user_role              as enum ('admin','reception','trainer','trainee');
create type public.gender_type            as enum ('male','female');
create type public.access_type            as enum ('mixed','women','maintenance','course_reserved');
create type public.attendance_method      as enum ('qr','manual');
create type public.booking_status         as enum ('confirmed','cancelled');
create type public.membership_status      as enum ('active','expired','suspended');
create type public.payment_category       as enum ('membership','salary','purchase','maintenance','private_session','other');
create type public.payment_type           as enum ('income','expense');
create type public.private_session_status as enum ('scheduled','cancelled','completed');
create type public.session_status         as enum ('scheduled','cancelled','completed');
create type public.trainer_trainee_status as enum ('active','inactive');

-- ---------- Tables ----------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        varchar(150) not null,
  phone       varchar(20) unique,
  email       varchar(150) unique,
  role        public.user_role   not null default 'trainee',
  gender      public.gender_type not null,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

create table public.halls (
  id                   serial primary key,
  name                 varchar(100) not null,
  capacity             integer not null check (capacity > 0),
  is_active            boolean not null default true,
  open_time            text not null default '08:00:00',
  close_time           text not null default '22:00:00',
  default_slot_minutes integer not null default 60
);

create table public.access_periods (
  id               serial primary key,
  hall_id          integer not null references public.halls(id) on delete cascade,
  day_of_week      smallint not null check (day_of_week between 0 and 6),
  start_time       time not null,
  end_time         time not null,
  access_type      public.access_type not null default 'mixed',
  trainer_id       uuid references public.profiles(id),
  title_or_reason  varchar(200),
  is_active        boolean not null default true,
  check (end_time > start_time)
);

create table public.sessions (
  id                serial primary key,
  name              varchar(150) not null,
  description       text,
  hall_id           integer not null references public.halls(id),
  trainer_id        uuid references public.profiles(id),
  access_period_id  integer references public.access_periods(id),
  start_date        date not null,
  end_date          date not null,
  capacity          integer not null check (capacity > 0),
  status            public.session_status not null default 'scheduled',
  created_by        uuid references public.profiles(id),
  created_at        timestamptz default now(),
  check (end_date >= start_date)
);

create table public.session_periods (
  id                bigserial primary key,
  session_id        integer not null references public.sessions(id) on delete cascade,
  access_period_id  integer not null references public.access_periods(id) on delete cascade,
  unique (session_id, access_period_id)
);

create table public.bookings (
  id          serial primary key,
  trainee_id  uuid not null references public.profiles(id),
  session_id  integer not null references public.sessions(id) on delete cascade,
  status      public.booking_status not null default 'confirmed',
  created_at  timestamptz default now()
);

create table public.memberships (
  id           serial primary key,
  trainee_id   uuid not null references public.profiles(id),
  start_date   date not null,
  end_date     date not null,
  status       public.membership_status not null default 'active',
  recorded_by  uuid references public.profiles(id),
  created_at   timestamptz default now(),
  check (end_date > start_date)
);

create table public.payment_costs (
  id            serial primary key,
  user_id       uuid references public.profiles(id),
  type          public.payment_type not null,
  category      public.payment_category not null,
  amount        numeric not null check (amount >= 0),
  payment_date  date not null,
  description   text,
  recorded_by   uuid references public.profiles(id),
  created_at    timestamptz default now()
);

create table public.trainer_trainees (
  id           serial primary key,
  trainer_id   uuid not null references public.profiles(id),
  trainee_id   uuid not null references public.profiles(id),
  status       public.trainer_trainee_status not null default 'active',
  assigned_at  timestamptz default now(),
  assigned_by  uuid references public.profiles(id),
  unique (trainer_id, trainee_id)
);

create table public.private_training_sessions (
  id                  serial primary key,
  slot_id             integer references public.access_periods(id),
  trainer_trainee_id  integer not null references public.trainer_trainees(id),
  session_date        date not null,
  status              public.private_session_status not null default 'scheduled',
  recorded_by         uuid references public.profiles(id),
  created_at          timestamptz default now()
);

create table public.private_training_schedule (
  id                  serial primary key,
  trainer_trainee_id  integer not null references public.trainer_trainees(id) on delete cascade,
  day_of_week         smallint not null,
  start_time          time not null,
  end_time            time not null,
  is_active           boolean not null default true,
  created_by          uuid not null,
  created_at          timestamptz not null default now(),
  unique (trainer_trainee_id, day_of_week, start_time)
);

create table public.attendance (
  id             serial primary key,
  trainee_id     uuid not null references public.profiles(id),
  session_id     integer references public.sessions(id),
  check_in_time  timestamptz not null default now(),
  method         public.attendance_method not null
);

create table public.training_programs (
  id          serial primary key,
  trainer_id  uuid not null references public.profiles(id),
  trainee_id  uuid not null references public.profiles(id),
  name        varchar(150) not null,
  description text,
  is_active   boolean not null default true,
  created_at  timestamptz default now(),
  end_date    date,
  start_date  date
);

create table public.program_days (
  id           serial primary key,
  program_id   integer not null references public.training_programs(id) on delete cascade,
  day_of_week  smallint not null check (day_of_week between 0 and 6),
  muscle_group varchar(100),
  order_index  integer not null default 0
);

create table public.program_exercises (
  id             serial primary key,
  day_id         integer not null references public.program_days(id) on delete cascade,
  exercise_name  varchar(150) not null,
  sets           integer,
  reps           varchar(50),
  notes          text,
  order_index    integer not null default 0
);

create table public.diets (
  id          serial primary key,
  trainer_id  uuid not null references public.profiles(id),
  trainee_id  uuid not null references public.profiles(id),
  name        varchar(150) not null,
  description text,
  start_date  date not null,
  end_date    date,
  is_active   boolean not null default true,
  created_at  timestamptz default now(),
  check (end_date is null or end_date > start_date)
);

create table public.diet_days (
  id           serial primary key,
  diet_id      integer not null references public.diets(id) on delete cascade,
  day_of_week  smallint not null check (day_of_week between 0 and 6),
  order_index  integer not null default 0
);

create table public.diet_meals (
  id           serial primary key,
  day_id       integer not null references public.diet_days(id) on delete cascade,
  meal_type    varchar(50) not null,
  description  text not null,
  calories     integer,
  order_index  integer not null default 0
);

create table public.reports (
  id            serial primary key,
  type          varchar(50) not null,
  title         varchar(200) not null,
  description   text,
  generated_by  uuid references public.profiles(id),
  created_at    timestamptz default now(),
  data          jsonb
);

create table public.deleted_users_archive (
  id                 bigserial primary key,
  deleted_user_id    uuid not null,
  deleted_user_name  text,
  deleted_user_email text,
  deleted_user_role  text,
  deleted_by         uuid references public.profiles(id) on delete set null,
  deleted_at         timestamptz not null default now(),
  snapshot           jsonb not null
);

create table public.notifications (
  id          bigserial primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  type        text not null,
  title       text not null,
  body        text not null,
  data        jsonb,
  is_read     boolean not null default false,
  created_at  timestamptz not null default now()
);

-- ---------- Indexes ----------
create index idx_profiles_role on public.profiles (role);

create index idx_access_periods_hall    on public.access_periods (hall_id);
create index idx_access_periods_trainer on public.access_periods (trainer_id);

create index idx_memberships_trainee     on public.memberships (trainee_id);
create index idx_memberships_status      on public.memberships (status);
create index idx_memberships_dates       on public.memberships (start_date, end_date);
create index idx_memberships_recorded_by on public.memberships (recorded_by);

create index idx_sessions_hall          on public.sessions (hall_id);
create index idx_sessions_trainer       on public.sessions (trainer_id);
create index idx_sessions_access_period on public.sessions (access_period_id);
create index idx_sessions_created_by    on public.sessions (created_by);

create index idx_bookings_session on public.bookings (session_id);
create index idx_bookings_trainee on public.bookings (trainee_id);
create unique index uq_bookings_active on public.bookings (trainee_id, session_id) where status = 'confirmed';

create index idx_tt_trainer                  on public.trainer_trainees (trainer_id);
create index idx_tt_trainee                  on public.trainer_trainees (trainee_id);
create index idx_trainer_trainees_assigned_by on public.trainer_trainees (assigned_by);

create index idx_pts_slot                          on public.private_training_sessions (slot_id);
create index idx_pts_tt                            on public.private_training_sessions (trainer_trainee_id);
create index idx_private_training_sessions_recorded_by on public.private_training_sessions (recorded_by);

create index idx_attendance_trainee on public.attendance (trainee_id);
create index idx_attendance_time    on public.attendance (check_in_time);
create index idx_attendance_session on public.attendance (session_id);

create index idx_program_days_program   on public.program_days (program_id);
create index idx_program_exercises_day  on public.program_exercises (day_id);
create index idx_tp_trainer             on public.training_programs (trainer_id);
create index idx_tp_trainee             on public.training_programs (trainee_id);

create index idx_diets_trainer    on public.diets (trainer_id);
create index idx_diets_trainee    on public.diets (trainee_id);
create index idx_diet_days_diet   on public.diet_days (diet_id);
create index idx_diet_meals_day   on public.diet_meals (day_id);

create index idx_payments_user        on public.payment_costs (user_id);
create index idx_payments_date        on public.payment_costs (payment_date);
create index idx_payments_type        on public.payment_costs (type, category);
create index idx_payment_costs_recorded_by on public.payment_costs (recorded_by);

create index idx_reports_generated_by on public.reports (generated_by);

create index idx_session_periods_access_period_id on public.session_periods (access_period_id);
create index idx_private_training_schedule_trainer on public.private_training_schedule (trainer_trainee_id);

create index idx_notifications_user_unread  on public.notifications (user_id, is_read, created_at desc);
create index idx_notifications_user_created on public.notifications (user_id, created_at desc);

-- ---------- RLS on everywhere ----------
alter table public.profiles                  enable row level security;
alter table public.halls                     enable row level security;
alter table public.access_periods            enable row level security;
alter table public.sessions                  enable row level security;
alter table public.session_periods           enable row level security;
alter table public.bookings                  enable row level security;
alter table public.memberships               enable row level security;
alter table public.payment_costs             enable row level security;
alter table public.trainer_trainees          enable row level security;
alter table public.private_training_sessions enable row level security;
alter table public.private_training_schedule enable row level security;
alter table public.attendance                enable row level security;
alter table public.training_programs         enable row level security;
alter table public.program_days              enable row level security;
alter table public.program_exercises         enable row level security;
alter table public.diets                     enable row level security;
alter table public.diet_days                 enable row level security;
alter table public.diet_meals                enable row level security;
alter table public.reports                   enable row level security;
alter table public.deleted_users_archive     enable row level security;
alter table public.notifications             enable row level security;


-- >>>>>>>>>> 20260101000100_functions_and_triggers.sql <<<<<<<<<<
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


-- >>>>>>>>>> 20260101000200_rls_policies.sql <<<<<<<<<<
-- =====================================================================
-- Gym Pro — 03: Row Level Security policies (mirror of the live project)
-- =====================================================================

-- ---------- profiles ----------
create policy auth_admin_read_profiles_for_jwt on public.profiles
  as permissive for select to supabase_auth_admin using (true);

create policy profiles_select on public.profiles
  as permissive for select to authenticated
  using (is_staff() or id = (select auth.uid()));

create policy "Trainer and trainee can view each other via active assignment" on public.profiles
  as permissive for select to public
  using (
    (select auth.uid()) = id
    or exists (
      select 1 from trainer_trainees tt
      where tt.status = 'active'
        and (
          (tt.trainer_id = (select auth.uid()) and tt.trainee_id = profiles.id)
          or (tt.trainee_id = (select auth.uid()) and tt.trainer_id = profiles.id)
        )
    )
  );

create policy profiles_update_admin on public.profiles
  as permissive for update to authenticated
  using (is_admin()) with check (is_admin());

create policy profiles_update_self on public.profiles
  as permissive for update to public
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()) and (role)::text = app_role());

-- ---------- halls / access_periods / sessions / session_periods ----------
create policy halls_select_all on public.halls
  as permissive for select to authenticated using (true);
create policy halls_write_admin on public.halls
  as permissive for all to authenticated using (is_admin()) with check (is_admin());

create policy ap_select_all on public.access_periods
  as permissive for select to authenticated using (true);
create policy ap_write_admin on public.access_periods
  as permissive for all to authenticated using (is_admin()) with check (is_admin());

create policy sessions_select_all on public.sessions
  as permissive for select to authenticated using (true);
create policy sessions_write_admin on public.sessions
  as permissive for all to authenticated using (is_admin()) with check (is_admin());

create policy session_periods_select_all on public.session_periods
  as permissive for select to public using (true);
create policy session_periods_write_admin on public.session_periods
  as permissive for all to public using (is_admin());

-- ---------- bookings ----------
create policy bookings_select on public.bookings
  as permissive for select to authenticated
  using (is_staff() or trainee_id = (select auth.uid()));

create policy bookings_write on public.bookings
  as permissive for all to authenticated
  using (is_staff() or trainee_id = (select auth.uid()))
  with check (is_staff() or trainee_id = (select auth.uid()));

-- ---------- memberships ----------
create policy memberships_select on public.memberships
  as permissive for select to authenticated
  using (
    is_staff()
    or trainee_id = (select auth.uid())
    or exists (
      select 1 from trainer_trainees tt
      where tt.trainee_id = memberships.trainee_id
        and tt.trainer_id = (select auth.uid())
        and tt.status = 'active'
    )
  );
create policy memberships_write_reception on public.memberships
  as permissive for all to authenticated using (is_staff()) with check (is_staff());

-- ---------- attendance ----------
create policy attendance_select on public.attendance
  as permissive for select to authenticated
  using (
    is_staff()
    or trainee_id = (select auth.uid())
    or exists (
      select 1 from trainer_trainees tt
      where tt.trainee_id = attendance.trainee_id
        and tt.trainer_id = (select auth.uid())
        and tt.status = 'active'
    )
  );
create policy attendance_insert_reception on public.attendance
  as permissive for insert to authenticated with check (is_staff());

-- ---------- payment_costs / reports / archive ----------
create policy pc_all_staff on public.payment_costs
  as permissive for all to authenticated using (is_staff()) with check (is_staff());

create policy reports_all_admin on public.reports
  as permissive for all to authenticated using (is_admin()) with check (is_admin());

create policy archive_select_admin on public.deleted_users_archive
  as permissive for select to authenticated using (is_admin());

-- ---------- trainer_trainees ----------
create policy tt_select on public.trainer_trainees
  as permissive for select to authenticated
  using (is_staff() or trainer_id = (select auth.uid()) or trainee_id = (select auth.uid()));
create policy "Trainers can view their own assignments" on public.trainer_trainees
  as permissive for select to public
  using (trainer_id = (select auth.uid()) or trainee_id = (select auth.uid()));
create policy tt_write_reception on public.trainer_trainees
  as permissive for all to authenticated using (is_staff()) with check (is_staff());

-- ---------- private training ----------
create policy pts_select on public.private_training_sessions
  as permissive for select to authenticated
  using (
    is_staff()
    or trainer_trainee_id in (
      select id from trainer_trainees
      where trainer_id = (select auth.uid()) or trainee_id = (select auth.uid())
    )
  );
create policy pts_write_reception on public.private_training_sessions
  as permissive for all to authenticated using (is_staff()) with check (is_staff());

create policy pts_schedule_select on public.private_training_schedule
  as permissive for select to public
  using (
    is_staff()
    or exists (
      select 1 from trainer_trainees tt
      where tt.id = private_training_schedule.trainer_trainee_id
        and (tt.trainer_id = (select auth.uid()) or tt.trainee_id = (select auth.uid()))
    )
  );
create policy pts_schedule_write_reception on public.private_training_schedule
  as permissive for all to public using (is_staff());

-- ---------- training programs ----------
create policy tp_select on public.training_programs
  as permissive for select to authenticated
  using (is_staff() or trainer_id = (select auth.uid()) or trainee_id = (select auth.uid()));
create policy tp_write_trainer on public.training_programs
  as permissive for insert to authenticated
  with check (is_trainer() and trainer_id = (select auth.uid()));
create policy tp_update on public.training_programs
  as permissive for update to authenticated
  using (is_staff() or trainer_id = (select auth.uid()))
  with check (is_staff() or trainer_id = (select auth.uid()));
create policy tp_delete on public.training_programs
  as permissive for delete to authenticated
  using (is_staff() or trainer_id = (select auth.uid()));

create policy pd_select on public.program_days
  as permissive for select to authenticated
  using (
    is_staff()
    or program_id in (
      select id from training_programs
      where trainer_id = (select auth.uid()) or trainee_id = (select auth.uid())
    )
  );
create policy pd_write_trainer on public.program_days
  as permissive for all to authenticated
  using (is_staff() or program_id in (select id from training_programs where trainer_id = (select auth.uid())))
  with check (is_staff() or program_id in (select id from training_programs where trainer_id = (select auth.uid())));

create policy pe_select on public.program_exercises
  as permissive for select to authenticated
  using (
    is_staff()
    or day_id in (
      select pd.id from program_days pd
      join training_programs tp on tp.id = pd.program_id
      where tp.trainer_id = (select auth.uid()) or tp.trainee_id = (select auth.uid())
    )
  );
create policy pe_write_trainer on public.program_exercises
  as permissive for all to authenticated
  using (
    is_staff()
    or day_id in (
      select pd.id from program_days pd
      join training_programs tp on tp.id = pd.program_id
      where tp.trainer_id = (select auth.uid())
    )
  )
  with check (
    is_staff()
    or day_id in (
      select pd.id from program_days pd
      join training_programs tp on tp.id = pd.program_id
      where tp.trainer_id = (select auth.uid())
    )
  );

-- ---------- diets ----------
create policy diets_select on public.diets
  as permissive for select to authenticated
  using (is_staff() or trainer_id = (select auth.uid()) or trainee_id = (select auth.uid()));
create policy diets_write_trainer on public.diets
  as permissive for insert to authenticated
  with check (is_trainer() and trainer_id = (select auth.uid()));
create policy diets_update on public.diets
  as permissive for update to authenticated
  using (is_staff() or trainer_id = (select auth.uid()))
  with check (is_staff() or trainer_id = (select auth.uid()));
create policy diets_delete on public.diets
  as permissive for delete to authenticated
  using (is_staff() or trainer_id = (select auth.uid()));

create policy dd_select on public.diet_days
  as permissive for select to authenticated
  using (
    is_staff()
    or diet_id in (
      select id from diets
      where trainer_id = (select auth.uid()) or trainee_id = (select auth.uid())
    )
  );
create policy dd_write_trainer on public.diet_days
  as permissive for all to authenticated
  using (is_staff() or diet_id in (select id from diets where trainer_id = (select auth.uid())))
  with check (is_staff() or diet_id in (select id from diets where trainer_id = (select auth.uid())));

create policy dm_select on public.diet_meals
  as permissive for select to authenticated
  using (
    is_staff()
    or day_id in (
      select dd.id from diet_days dd
      join diets d on d.id = dd.diet_id
      where d.trainer_id = (select auth.uid()) or d.trainee_id = (select auth.uid())
    )
  );
create policy dm_write_trainer on public.diet_meals
  as permissive for all to authenticated
  using (
    is_staff()
    or day_id in (
      select dd.id from diet_days dd
      join diets d on d.id = dd.diet_id
      where d.trainer_id = (select auth.uid())
    )
  )
  with check (
    is_staff()
    or day_id in (
      select dd.id from diet_days dd
      join diets d on d.id = dd.diet_id
      where d.trainer_id = (select auth.uid())
    )
  );

-- ---------- notifications ----------
create policy notifications_select on public.notifications
  as permissive for select to authenticated
  using (user_id = (select auth.uid()));
create policy notifications_select_own on public.notifications
  as permissive for select to public
  using (user_id = auth.uid());
create policy notifications_update_own on public.notifications
  as permissive for update to public
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
create policy notifications_delete_own on public.notifications
  as permissive for delete to public
  using (user_id = auth.uid());
create policy notifications_insert on public.notifications
  as permissive for insert to public
  with check (
    user_id = auth.uid()
    or exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = any (array['admin'::user_role, 'reception'::user_role])
    )
  );


-- >>>>>>>>>> 20260101000300_realtime_and_cron.sql <<<<<<<<<<
-- =====================================================================
-- Gym Pro — 04: realtime + scheduled jobs
-- =====================================================================

-- Realtime for the notification bell
alter publication supabase_realtime add table public.notifications;

-- Daily jobs (pg_cron; times are UTC)
select cron.schedule('expire-memberships',          '0 0 * * *', $$SELECT public.expire_due_memberships()$$);
select cron.schedule('notify-expiring-memberships', '0 8 * * *', $$select public.notify_expiring_memberships()$$);


-- >>>>>>>>>> 20260101000400_secure_qr_tokens.sql <<<<<<<<<<
-- Short-lived QR tokens. The raw token is returned only to the trainee
-- who requested it; the database stores a SHA-256 digest.

create table if not exists public.trainee_qr_tokens (
  id           uuid primary key default gen_random_uuid(),
  trainee_id   uuid not null references public.profiles(id) on delete cascade,
  token_hash   text not null unique,
  expires_at   timestamptz not null,
  created_at   timestamptz not null default now()
);

create index if not exists idx_trainee_qr_tokens_lookup
  on public.trainee_qr_tokens (token_hash, expires_at);

alter table public.trainee_qr_tokens enable row level security;

create or replace function public.issue_trainee_qr_token()
returns text
language plpgsql
security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare
  raw_token text;
begin
  if not exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'trainee'
      and is_active
  ) then
    raise exception 'Only an active trainee can issue a QR token';
  end if;

  delete from public.trainee_qr_tokens
  where trainee_id = auth.uid()
     or expires_at <= now();

  raw_token := encode(gen_random_bytes(24), 'hex');

  insert into public.trainee_qr_tokens (trainee_id, token_hash, expires_at)
  values (
    auth.uid(),
    encode(digest(raw_token, 'sha256'), 'hex'),
    now() + interval '90 seconds'
  );

  return 'gympro_qr_v1:' || raw_token;
end;
$$;

create or replace function public.resolve_trainee_qr_token(p_token text)
returns setof public.profiles
language plpgsql
security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare
  raw_token text;
begin
  if not public.is_staff() then
    raise exception 'Only active staff can resolve a QR token';
  end if;

  if p_token is null or p_token not like 'gympro_qr_v1:%' then
    return;
  end if;

  raw_token := substring(p_token from char_length('gympro_qr_v1:') + 1);

  return query
  select p.*
  from public.trainee_qr_tokens t
  join public.profiles p on p.id = t.trainee_id
  where t.token_hash = encode(digest(raw_token, 'sha256'), 'hex')
    and t.expires_at > now()
    and p.role = 'trainee'
    and p.is_active;
end;
$$;

revoke all on function public.issue_trainee_qr_token() from public;
revoke all on function public.resolve_trainee_qr_token(text) from public;
grant execute on function public.issue_trainee_qr_token() to authenticated;
grant execute on function public.resolve_trainee_qr_token(text) to authenticated;


-- >>>>>>>>>> 20261101000000_security_hardening.sql <<<<<<<<<<
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

