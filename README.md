# Gym Pro

**A role-based gym management platform built with Flutter and Supabase** —
memberships, payments, scheduling, bookings, attendance with single-use QR
check-in, training programs, diet plans and real-time notifications, for four
roles across three apps.

[![CI](https://github.com/JawadAzaam22/gym-pro/actions/workflows/ci.yml/badge.svg)](https://github.com/JawadAzaam22/gym-pro/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.24.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.5-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase)
![State](https://img.shields.io/badge/State-Riverpod-00B8D4)
![Platforms](https://img.shields.io/badge/Platforms-Web%20%7C%20Android-4285F4)

> The user interface is Arabic and right-to-left. Identifiers, documentation
> and this README are in English; many inline code comments are in Arabic.

## Contents

[Screenshots](#screenshots) ·
[What it does](#what-it-does) ·
[Architecture](#architecture) ·
[Tech stack](#tech-stack) ·
[Database](#database) ·
[Security model](#security-model) ·
[QR check-in](#qr-check-in) ·
[Notifications](#notifications-and-realtime) ·
[Getting started](#getting-started) ·
[Existing projects](#applying-the-migrations-to-an-existing-project) ·
[Testing](#testing) ·
[CI/CD](#cicd) ·
[Repository layout](#repository-layout) ·
[License](#license)

## Screenshots

### Administration (web)

| Dashboard | Users | Weekly program | Reports |
|---|---|---|---|
| ![Admin dashboard](screenshots/admin_dashboard.png) | ![User management](screenshots/admin_user.png) | ![Weekly program](screenshots/admin_program_weekly.png) | ![Reports](screenshots/admin_report.png) |

### Reception (web)

| Dashboard | Memberships | QR check-in | Financial records |
|---|---|---|---|
| ![Reception dashboard](screenshots/reception_dashboard.png) | ![Memberships](screenshots/reception_membership.png) | ![QR check-in](screenshots/reception_qrcode.png) | ![Financial records](screenshots/reception_record_financial.png) |

### Mobile — trainee

| Home and personal QR | Notifications | Settings |
|---|---|---|
| ![Trainee home and personal QR](screenshots/mobile_trainee_home_qrcode.png) | ![Trainee notifications](screenshots/mobile_trainee_notification.png) | ![Trainee settings](screenshots/mobile_trainee_setting.png) |

### Mobile — trainer

| Home | Manage trainees | Schedule |
|---|---|---|
| ![Trainer home](screenshots/mobile_trainer_home.png) | ![Manage trainees](screenshots/mobile_trainer_mange_trainee.png) | ![Trainer schedule](screenshots/mobile_trainer_time.png) |

### Mobile — shared

| Weekly program |
|---|
| ![Weekly program](screenshots/mobile_weekly_program.png) |

## What it does

| Role | App | Main capabilities |
|---|---|---|
| **Admin** | Web (`lib/main_admin.dart`) | Create/disable users, halls and opening periods, group sessions, financial reports with PDF export |
| **Reception** | Web (`lib/main_reception.dart`) | Memberships and renewals, payments, bookings, trainer assignment, manual and QR check-in |
| **Trainer** | Mobile (`lib/main_mobile.dart`) | Assigned trainees, training programs (days → exercises), diet plans (days → meals), private-session schedule |
| **Trainee** | Mobile (`lib/main_mobile.dart`) | Membership status, bookings, attendance history, trainer, programs, diet, private sessions, personal QR |

Rules the database enforces (not only the UI):

- one check-in per trainee per day (and per session) — unique index;
- check-in is rejected when the latest membership is inactive or ended;
- a session cannot be booked beyond its capacity (row-locked trigger);
- a QR token works once and expires after 90 seconds;
- authorization fields on a profile can only be changed by an administrator.

Notifications (booking, membership, trainer assignment, private session,
expiring membership) arrive in-app through Supabase Realtime; local reminders
use `flutter_local_notifications`.

## Architecture

Clean-architecture-style layering with a one-way dependency direction:

```mermaid
flowchart TD
  P[Presentation<br/>screens · controllers · routers] --> U[Use cases]
  U --> D[Domain<br/>entities · repository contracts · failures]
  R[Repository implementations] --> D
  R --> S[Data sources]
  S --> B[(Supabase<br/>PostgreSQL · Auth · Realtime · Edge Functions)]
  P -. providers .-> R
```

- `lib/domain` — entities, repository interfaces, failures, use cases. It
  imports no Supabase code.
- `lib/data` — Supabase data sources, JSON models, repository
  implementations, and the Riverpod wiring in `lib/data/providers.dart`.
  Operations return `Either<Failure, T>` (`dartz`).
- `lib/presentation` — 43 screens grouped by role, Riverpod controllers and
  `go_router` route files per app.
- `lib/core` — bootstrap and `.env` loading, theme, errors, constants,
  notification service.

Three entry points share this code, so each deployed app contains only the
screens its roles need.

## Tech stack

| Area | Choice |
|---|---|
| UI / platforms | Flutter 3.24, Dart 3.5, Material, Google Fonts, `fl_chart` |
| State & DI | `flutter_riverpod` |
| Navigation | `go_router` (role-aware redirects) |
| Backend | Supabase: PostgreSQL + RLS, Auth with a custom access-token hook, Realtime, Edge Functions (Deno), `pg_cron` |
| QR | `qr_flutter` (display), `mobile_scanner` (scan) |
| Reports | `pdf` + `printing` |
| Errors | `dartz` `Either`, `equatable` |
| Quality | `flutter_lints`, `custom_lint` + `riverpod_lint`, `mocktail` |

## Database

22 tables, all with Row Level Security. Migrations live in
`supabase/migrations` and must be applied in order:

| Migration | Responsibility |
|---|---|
| `20260101000000_initial_schema.sql` | Extensions, enums, tables, indexes, RLS enablement |
| `20260101000100_functions_and_triggers.sql` | Role helpers, auth hook, new-user trigger, notification triggers, delete-user cascade |
| `20260101000200_rls_policies.sql` | 50 RLS policies |
| `20260101000300_realtime_and_cron.sql` | Realtime publication (`notifications`) and cron jobs |
| `20260101000400_secure_qr_tokens.sql` | Hashed, short-lived QR tokens and RPCs |
| `20261101000000_security_hardening.sql` | Security hardening, atomic attendance/QR RPCs, booking-capacity trigger |

Table groups: identity (`profiles`, `trainer_trainees`, `deleted_users_archive`),
facilities (`halls`, `access_periods`, `session_periods`), scheduling
(`sessions`, `bookings`, `private_training_schedule`, `private_training_sessions`),
membership and money (`memberships`, `payment_costs`, `reports`),
attendance (`attendance`, `trainee_qr_tokens`), training content
(`training_programs`, `program_days`, `program_exercises`, `diets`,
`diet_days`, `diet_meals`) and `notifications`.

Edge Functions (`supabase/functions`, JWT verification on):

- `create-user` — active admin or reception only (reception cannot create admins);
  validates email, password (6+ characters), role and gender; the role is stored
  in `app_metadata`, which only the server can write.
- `delete-user` — active admin only; cannot delete itself; archives a snapshot
  before deleting.

## Security model

- **Authentication & roles.** Supabase Auth. A custom access-token hook copies
  the profile role into the `app_role` claim; SQL helpers (`is_admin()`,
  `is_staff()`, …) also check `is_active` live.
- **Authorization lives in PostgreSQL.** The client's filters are never trusted;
  RLS decides. Trainees and trainers see only their own rows.
- **No self-registration.** Sign-in is email and password; accounts are created
  only by admin or reception through
  `create-user`; public sign-up is disabled (`supabase/config.toml`), and the
  new-user trigger takes the role from server-only `raw_app_meta_data`.
- **Protected columns.** Non-admins cannot change `role`, `is_active` or `email`
  on a profile (guard trigger).
- **Least privilege.** `anon` has no table or helper-function access; trigger
  functions are not callable as RPC; QR tokens are reachable only through
  `SECURITY DEFINER` RPCs.
- **Secrets.** Only the public anon/publishable key is in the app. The
  `service_role` key exists only inside Edge Functions.

## QR check-in

1. The trainee opens the QR screen; `issue_trainee_qr_token()` verifies the
   caller is an active trainee, creates a random token, stores **only its
   SHA-256 digest**, replaces any previous token, and returns
   `gympro_qr_v1:<token>`. It expires after 90 seconds.
2. Reception scans it; `check_in_by_qr()` verifies the caller is active staff,
   **deletes** the token, checks the membership and writes the attendance row —
   in a single transaction with the server clock.
3. A failure (expired membership, duplicate check-in) rolls everything back, so a
   token is consumed only by a successful check-in, and can never be accepted
   twice.

The QR value contains no user id or personal data.

## Notifications and Realtime

- **In-app:** a Riverpod stream backed by Supabase Postgres Changes. The initial
  query is authoritative; later row changes update the list. On logout or
  account switch the provider is invalidated so the previous user's stream is
  not kept.
- **Local reminders:** `flutter_local_notifications`; no push server required.
- **Security:** the client filters by `user_id`, but RLS is what protects the
  data — both select policies require `user_id = auth.uid()`. Owners can update
  only `is_read`.
- **Scope:** the `supabase_realtime` publication contains only
  `public.notifications`, so payments, bookings and memberships are never
  broadcast.
- **Producers:** database triggers (booking, membership, trainer assignment,
  private session) and two pg_cron jobs (`expire-memberships` daily at 00:00,
  `notify-expiring-memberships` daily at 08:00, database time).

## Getting started

### Prerequisites

Flutter 3.24.x (Dart 3.5), Chrome for the web apps, Android Studio for the
mobile app, the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)
and a Supabase project.

### 1. Configure the app

```bash
cp .env.example .env      # then fill in your project values
flutter pub get
```

```env
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_OR_PUBLISHABLE_KEY
```

`.env` is bundled as a Flutter asset, so it must exist before you run or
build. Never put a `service_role` key in it. (`SUPABASE_PUBLISHABLE_KEY` is
also accepted.)

### 2. Set up Supabase

**New project**

```bash
supabase login
supabase link --project-ref <project-ref>
supabase db push
supabase functions deploy create-user
supabase functions deploy delete-user
```

Optional: `supabase secrets set ALLOWED_ORIGINS=https://admin.example.com,https://reception.example.com`
to restrict browser origins for `create-user`.

Then, in the dashboard, enable the **Custom Access Token hook**
(`public.custom_access_token_hook`) if it is not already enabled by
`config.toml`, and turn on leaked-password protection.

**Existing project whose migration history differs:** follow
[Applying the migrations to an existing project](#applying-the-migrations-to-an-existing-project)
*before* `db push`. Do not run `supabase db reset` against production.

### 3. Create the first administrator

`create-user` needs an existing admin, so promote the first one by hand: create
the user in **Authentication → Users**, then in the SQL editor:

```sql
update public.profiles set role = 'admin' where email = 'you@example.com';
update auth.users
   set raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}'::jsonb
 where email = 'you@example.com';
```

Sign out and in again so the role claim refreshes. Every other account is
created from the admin or reception app.

### 4. Run

```bash
flutter run -t lib/main_admin.dart     -d chrome
flutter run -t lib/main_reception.dart -d chrome
flutter run -t lib/main_mobile.dart    -d <device-id>
```

Release builds:

```bash
flutter build web --release -t lib/main_admin.dart
flutter build web --release -t lib/main_reception.dart
flutter build apk --release -t lib/main_mobile.dart
```


## Applying the migrations to an existing project

If your hosted project already contains this schema but its migration history
differs from `supabase/migrations`, align the history before pushing —
`supabase db push` refuses to run while the remote history contains versions the
repository does not have.

1. **Back up:** `supabase db dump --linked -f backup_schema.sql` and
   `supabase db dump --linked --data-only -f backup_data.sql`.
2. **Compare:** dump the hosted `public` schema, apply the migrations to a scratch
   stack, dump that schema and diff the two.
3. **Re-label the history** (executes no SQL):
   ```bash
   supabase link --project-ref <project-ref>
   supabase migration list                                    # note the remote-only versions
   supabase migration repair --status reverted <remote-only versions…>
   supabase migration repair --status applied 20260101000000 20260101000100 \
     20260101000200 20260101000300 20260101000400
   ```
4. **Deploy the Edge Functions first** (`supabase functions deploy create-user`,
   `… delete-user`) — the hardening migration reads roles from `app_metadata`,
   which the current `create-user` sets.
5. **Apply the hardening migration** on a disposable project, then
   `supabase db push` on the real one.
6. **Dashboard settings** that SQL cannot express: disable "Allow new users to
   sign up", enable leaked-password protection, and point the Custom Access Token
   hook at `public.custom_access_token_hook`.
7. **Ship the matching app build** after steps 4–5.

`supabase/setup/full_setup_new_project.sql` contains all migrations in one file
for creating a **new** project from the SQL editor. Never run it on an existing
project.

## Testing

```bash
flutter analyze --no-pub
dart run custom_lint
flutter test test/domain      # fast, no widgets
flutter test                  # full suite
```

The suite has 176 test cases in 22 files covering use cases, models, providers
and widgets.

Database behaviour is verified against a Supabase project rather than with
Flutter tests:

- an RLS role matrix (admin, reception, trainer, trainee, deactivated user, anon);
- `record_attendance` → `ALREADY_CHECKED_IN`, `MEMBERSHIP_EXPIRED`;
- `check_in_by_qr` → a second use of the same token fails;
- booking the last seat twice concurrently → `SESSION_FULL`;
- a non-admin updating their own `role`, `is_active` or `email` is rejected.

## CI/CD

Everything runs on GitHub Actions and uses free tiers only.

| Workflow | Trigger | What it does |
|---|---|---|
| **CI** (`ci.yml`) | every pull request and push to `main` | secret scan (gitleaks) · format, analyze and custom lint · unit and widget tests with coverage · release builds of both web apps · Android debug build · applies **all migrations to an empty Supabase stack** and runs the SQL integration tests · type-checks the Edge Functions · reports one status, **CI passed** |
| **Deploy web apps** (`deploy-web.yml`) | push to `main` that touches the app, or manual | builds the admin and reception apps and publishes them to GitHub Pages under `/admin/` and `/reception/` |
| **Deploy backend** (`deploy-backend.yml`) | manual, from `main`, requires typing `DEPLOY` | `supabase db push --dry-run`, `db push`, then deploys `create-user` and `delete-user` to the chosen environment (`staging` or `production`) |
| **Release Android APK** (`release-android.yml`) | tag `v*` or manual | builds a signed release APK and attaches it, with its SHA-256, to a GitHub Release |
| **iOS compile check** (`ios-compile-check.yml`) | tag `v*` or manual | verifies the iOS target compiles without code signing |

**Database tests.** `supabase/tests/database/` holds SQL integration tests that
run inside a transaction that is always rolled back. They cover the new-user
trigger, protected profile columns, anonymous access, manual and QR attendance
(including single-use tokens), booking capacity and deactivated users. Run them
locally with:

```bash
supabase start
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
  -v ON_ERROR_STOP=1 -f supabase/tests/database/01_security_and_attendance.test.sql
```

**Configuration.**

| Where | Name | Purpose |
|---|---|---|
| Repository variables | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | public values written to `.env` for web and Android builds |
| Environment `production` / `staging` — secrets | `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD` | backend deployment |
| Environment `production` / `staging` — variable | `SUPABASE_PROJECT_REF` | target Supabase project |
| Repository secrets | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | Android release signing |

**Releasing.** Merge to `main` (web apps deploy automatically), run
**Deploy backend** if the change includes migrations or Edge Functions, then tag:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

The Android APK is distributed through GitHub Releases for direct installation.
iOS builds are compiled in CI but not distributed, because installing on devices
requires an Apple Developer Program membership.

Dependencies and Actions versions are kept current by Dependabot
(`.github/dependabot.yml`); pull requests use `.github/PULL_REQUEST_TEMPLATE.md`.

## Repository layout

```text
.github/          workflows, Dependabot, pull-request template
lib/
  core/            bootstrap, theme, errors, constants, notifications
  domain/          entities, repository contracts, use cases
  data/            data sources, models, repository implementations, providers.dart
  presentation/    admin · reception · trainer · trainee · mobile · shared
  main_admin.dart  main_reception.dart  main_mobile.dart
supabase/
  migrations/      6 ordered SQL files
  functions/       create-user, delete-user
  setup/           full_setup_new_project.sql (SQL-editor setup for a NEW project only)
  tests/database/  SQL integration tests (run in CI)
  config.toml
screenshots/       PNG files used by this README
test/              domain, models, providers, screens
.env.example
```

Private notes and unreleased configuration belong in the git-ignored
`privateConfig/` directory.

## License

Copyright © 2026 Jawad Azzam. All rights reserved. See [LICENSE](LICENSE).
This is a portfolio project: contact the author before reusing,
redistributing or deploying it commercially.

## Author

**Jawad Azzam** — Software Engineer (Flutter, Spring Boot)
· GitHub [@JawadAzaam22](https://github.com/JawadAzaam22)
· LinkedIn [jawad-azzam-dev](https://www.linkedin.com/in/jawad-azzam-dev)
