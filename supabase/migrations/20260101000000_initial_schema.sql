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
