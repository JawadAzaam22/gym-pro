# Gym Pro — Verification Report (English)

Branch: `docs/final-review` · Date: 2026-10-21 · Scope: **client code only**
(no SQL, no network calls, no Supabase connection — per review charter).

---

## 1. Facts (measured, not copied)

| # | Fact | Value | Command / evidence |
|---|---|---|---|
| F1 | Flutter | 3.24.5 stable (Dart 3.5.4) | `flutter --version` |
| F2 | `flutter pub get` | OK (127 packages have newer incompatible versions) | pub get output |
| F3 | `build_runner` | **0 outputs** (nothing to generate) | `dart run build_runner build` → "Succeeded … with 0 outputs" |
| F4 | `flutter analyze --no-pub` | **0 errors · 0 warnings · 36 infos** (after fixes; was 0/8/35) | `flutter analyze --no-pub` |
| F5 | `dart run custom_lint` | **No issues found** | `dart run custom_lint` |
| F6 | `flutter test` (all files except hanging `drawer_nav_test.dart`) | **147 passed · 19 failed** in 43 s | `flutter test --reporter compact` |
| F6b | `drawer_nav_test.dart` | 1 test **hangs → 10-min timeout** (pre-existing) | full-suite run, `TimeoutException after 0:10:00` |
| F7 | `flutter build web --release --target=lib/main_admin.dart` | **OK** (~188 s, `build/web`) | build log |
| F8 | `flutter build apk --debug --target=lib/main_mobile.dart` | **OK** (~207 s) | build log |
| F9 | Merged manifest (debug) | `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` present | `build/app/intermediates/merged_manifest/debug/.../AndroidManifest.xml` |
| F10 | Dart files | **222 in `lib/`**: core 23 · domain 49 · data 44 · presentation 103 · 3 mains; **0 generated** (`*.g.dart`/`*.freezed.dart` = none) | file count |
| F11 | Tests | **17 files · 166 cases** (was 14 files / 144 before this review added 22 Tier-B tests) | file/case count |
| F12 | Domain artifacts | 19 entities · 18 use cases · 12 repo interfaces; data: 12 datasources · 19 models · 12 impls | directory counts |
| F13 | Git | `main` = **1 commit**; all refs include this branch's 3 commits | `git log --oneline` |
| F14 | Secrets | `.env` **not tracked**; contains only `SUPABASE_URL`, `SUPABASE_ANON_KEY`; **no `service_role` value anywhere** (one Arabic comment mentions the term in `supabase_user_datasource.dart`) | `git ls-files .env` empty; repo-wide grep |
| F15 | `flutter pub outdated` | Major gaps only: `analyzer` 6.7→14.x (dev-chain), `freezed` 2→4, `flutter_lints` 4→6, `riverpod` 2→3 — all dev/constraint-bound | pub output |

---

## 2. Findings by area (Critical → Info)

Severity key: **C**ritical · **H**igh · **M**edium · **L**ow · **I**nfo.
"F" = found pre-review unless marked FIXED.

### A. Clean Architecture conformance

| ID | Sev | Finding | Evidence | Impact | Fix |
|---|---|---|---|---|---|
| A1 | I | `lib/domain` is pure Dart — 0 `flutter`/`supabase`/`riverpod` imports | grep over `lib/domain` = 0 hits | — | none needed |
| A2 | H | Presentation imports `data/` in 43 files (53 lines), incl. **model imports in 8 files** | e.g. `program_days_screen.dart:11`, `auth_controller.dart:2` | screens bypass domain | Tier C refactor |
| A3 | H | Presentation uses datasources directly in 15 files (6 of them screens) | `meals_screen.dart:33,58,99,147`, `exercises_screen.dart:33…`, `trainees_attendance_screen.dart:17` | untestable screens, no Failure mapping | Tier C |
| A4 | H | `Supabase.instance` used in presentation in 5 files (3 routers + 2 shells) | `admin_router.dart:32,39`, `reception_shell_screen.dart:98` (FIXED: shell logout), `mobile_router.dart:139,153` | layering leak | shell logout FIXED; router redirects remain (Tier C) |
| A5 | C | **Use-case layer is dead**: 0 imports of `domain/usecases` outside `domain/` | grep | 18 `Either`-returning use cases never called; screens call repos and `throw Exception` (**48 occurrences in 25 files**, 32 are `fold((l) => throw …)`) | Tier C |
| A6 | H | Raw exceptions reach UI: `async_error_view.dart:23` prints `'$error'` (50 uses); 18 `catch (e)` show `$e` | `daily_schedule_screen.dart:555`, `qr_scan_screen.dart:90` | untranslated stack-ish text for users | Tier C |
| A7 | M | `providers.dart`: 11 of 12 repos bound to **concrete impls**; only notification repo uses interface | `providers.dart:44-55` | weaker test override story | Tier C |
| A8 | H | `AsyncValue.value` at **40 sites** vs `valueOrNull` 5; README claimed the convention | `.value` throws when `hasValue==false`; e.g. `auth_controller.dart:130` (**FIXED**), `settings_screen.dart:22` | potential StateError on error/loading | FIXED where fatal; rest Tier C |
| A9 | M | 0 `autoDispose`, 0 `ref.listen`; 33 `FutureProvider` + 7 `AsyncNotifierProvider` all cache for app lifetime | grep counts | memory/stale-state growth | Tier C |
| A10 | H | Logout invalidated only 29 of 76 providers; **2 of 3 logout buttons bypassed AuthController** | `admin_shell_screen.dart:64`, `reception_shell_screen.dart:98` raw `signOut()` | cross-account data leak on shared devices | **FIXED** (both shells → AuthController; notifications providers added to invalidation) |
| A11 | C | `CircularDependencyError` in debug when AuthController invalidated `traineeQrProvider`/`traineesControllerProvider` (both watch auth) — logout/login in debug could crash | reproduced by new test `notifications_state_test.dart` → `element.dart:662` | **FIXED** (currentUserIdProvider indirection; self-rebuilding providers removed from list) |

### B. Entry points, roles, routing

| ID | Sev | Finding | Evidence | Impact | Fix |
|---|---|---|---|---|---|
| B1 | I | 3 mains each `await bootstrap()`; no `main.dart` | `main_admin.dart:9`, `main_reception.dart:8`, `main_mobile.dart:9` | — | none |
| B2 | M | Role read from `profiles` table (not metadata), 60-s client cache; **no lifecycle resume refresh** (`WidgetsBindingObserver`=0 hits); `refreshSession()` never called | `session_role.dart:57,14`; grep | role/status changes stale up to 60 s + until navigation | Tier C |
| B3 | I | Wrong-role access → `signOut` + redirect in all 3 router redirects; `RoleGuard` blocks at login | `admin_router.dart:36-43`, `mobile_router.dart:163-164` | — | none |
| B4 | M | **8 dead routes** (defined, never navigated): `/mobile/settings`, `/trainee/qr`, `/trainee/dashboard`, `/trainee/schedule`, `/trainer/dashboard`, `/trainer/all-schedule`, 2 unused day-exercise variants (shell uses `IndexedStack`) | `mobile_router.dart:173,274,272,285,181,269,239,251` | dead weight/confusing | Tier C report |
| B5 | M | **2 dead router files** (`trainer/router`, `trainee/router`) + 2 unused nav controllers (`trainer_nav_controller`, `trainee_nav_controller`) — README claimed all four wired | 0 imports of each | README corrected | Tier C |
| B6 | M | `reception_slide_drawer.dart` never imported; pushes `/reception/memberships/new|renew` which **don't exist** (would hit errorBuilder) | `reception_slide_drawer.dart:134,139` | broken if ever mounted | Tier C |
| B7 | I | `errorBuilder` present in all 3 active routers; all 43 screens reachable (0 orphan screens) | per-router files | — | none |

### C. Contract check vs reference snapshot

| ID | Sev | Finding | Evidence | Impact | Fix |
|---|---|---|---|---|---|
| C1 | — | `docs/db-snapshot/` **absent** → column/enum-level contract check **[NOT RUN]**; table-level check done against the charter's contract | section 6 contract + README 20-table list | column typos undetectable here | none (charter) |
| C2 | I | All **20** `.from('table')` names used by code exist in the 20-table contract (exact match, no typos) | grep of `lib/data/datasources/*.dart` | — | none |
| C3 | C→FIXED | Client `NotificationType` had **legacy types only** (`membership_expiry`, `session_reminder`, `booking`, `payment`, `attendance`) — all 6 real server types fell back to `system` | `enums.dart:93-135` (before fix) | server notifications misclassified, chip «عام» | **FIXED** `10731a9`: all 6 server types added + round-trip tested |
| C4 | C→FIXED | Model parsed `entity_id` (**not in server schema**) and ignored `data` jsonb → `screen`/`membership_id` discarded | `notification_model.dart:23` | deep-link payload lost at parse | **FIXED**: `data` parsed, `toInsertJson` no longer sends `entity_id` |
| C5 | I | RPCs/functions recorded: `rpc('expire_due_memberships')` (`supabase_membership_datasource.dart:14`); `functions.invoke('create-user'/'delete-user')` (`supabase_user_datasource.dart:69,118`) — Edge Function code **not in repo** (doc gap) | grep | deployment doc gap | noted in README §6 |
| C6 | I | Client never inserts into `notifications` in production (contract: server-only creation). `createNotification` exists but is dead code | grep callers = interface+impl only | — | documented |

### D. Business logic (client)

| ID | Sev | Finding | Evidence | Impact | Fix |
|---|---|---|---|---|---|
| D1 | H | Membership expiry **off-by-one**: datasource/model treat end date as active (date-only, inclusive), entity getter `endDate.isAfter(DateTime.now())` marks it expired on the final day | `membership.dart:23-24` vs `membership_model.dart:29-35` | wrong badge/status one day early | Tier C (business rule) |
| D2 | H | Booking pre-insert checks: capacity ✓, duplicate ✓; **missing** session `status`, membership validity, gender/access rules, past-date, authorization | `supabase_booking_datasource.dart:41-66` | overbooking of cancelled sessions etc., if server has no guard | Tier C (needs server confirmation) |
| D3 | M | QR content is static `trainee_<uuid>` — no signature/timestamp/expiry | `qr_controller.dart:7-12` ("refresh" doesn't change payload) | replay/forgery possible | Tier C |
| D4 | I | Check-in guards client-side: membership validity inclusive ✓, same-day duplicate probe ✓, in-flight set + 2-s scanner debounce ✓ | `supabase_attendance_datasource.dart:15-29,48-80`, `qr_scan_screen.dart:57-61` | — | none |
| D5 | M | Payments **manual only, no gateway** (0 hits for stripe/paypal/etc.); UI validates only non-empty then `double.parse` unguarded | `record_payment_screen.dart:60,63` | FormatException on bad input | Tier C |
| D6 | H | PDF: Cairo font embedded ✓, RTL ✓; **Arabic shaping OFF** (`pdf` defaults `useArabic=false` when `useBidi=true`; no `--dart-define=use_arabic` anywhere) | `pdf_report_generator.dart:11-16`; pdf 3.11.3 `options.dart` | disconnected letters in exported PDFs | Tier C (build-flag decision) |
| D7 | M | Week-start mismatch: helper says `0=Saturday` (`day_of_week_helper.dart:2,17-19`) but screens default `DateTime.now().weekday % 7` → Sunday=0 | `daily_schedule_screen.dart:32` | initial day off by one | Tier C |
| D8 | M | UTC/local: 70 `DateTime.now()` vs **0** `toLocal()` in `lib/` pre-fix; timestamptz parsed as UTC then displayed raw | `attendance_model.dart:10` etc. | shifted clock times (e.g. UTC+3) | partially FIXED (Formatters now `.toLocal()`); controllers remain Tier C |
| D9 | I | Client-only rules (no server artifacts in repo to confirm): capacity, duplicate booking, membership overlap, check-in validity/duplicate, payment sanity | §D refs | state honestly in interviews | documented |

### E. UI, design system, RTL

| ID | Sev | Finding | Evidence | Impact | Fix |
|---|---|---|---|---|---|
| E1 | I | Tokens exist: `app_colors.dart` 25 colors; `app_dimensions.dart` padding 4/8/16/24/32, radius 8/12/16, breakpoints 600/900/1200; dark-only theme; **Cairo** font | file reads | — | none |
| E2 | M | **`app_strings.dart` referenced by 0 files**; Arabic copy hard-coded in **81 of 103** presentation files (~1133 lines) | grep | no single source of copy; duplicates | Tier C |
| E3 | M | Hard-coded colors: `Colors.*` **934 occurrences in 64 files**; `Color(0x` outside tokens: 4 | grep | design-token bypass | Tier C |
| E4 | M | Magic numbers: `SizedBox` numeric 361, `fontSize` 239, numeric `EdgeInsets.symmetric` 28 (≈628 total) | grep | inconsistent spacing | Tier C |
| E5 | M | RTL global ✓ (all 3 mains force RTL + `Locale('ar')`); but `EdgeInsetsDirectional` **1 vs 151 `EdgeInsets.*`**; `qr_scan_screen.dart:37` uses `arrow_forward` as back button (wrong glyph in RTL); no `Semantics` anywhere | greps | misplaced paddings, a11y gap | Tier C |
| E6 | M | Breakpoints inconsistent: `AppDimensions` 600/900/1200, `ResponsiveLayout` 600/1100, `AdaptiveNavScaffold` 840, ad-hoc 900 in `daily_schedule_screen.dart:736` | file reads | layout drift at edges | Tier C |
| E7 | I | `flutter_screenutil` **declared but never initialized/used** (0 refs) — no possible clash; dead dependency | grep | unused dep | removed from README stack note |
| E8 | I | States mostly good: `AsyncValue.when` in 34/43 screens, `AsyncErrorView` 50 uses; gaps: `record_payment_screen` (no error state), `settings_screen.dart:22` | counts | minor | Tier C |
| E9 | M | `notifications_screen.dart:103` error branch **blanks the list even when prior data exists** (uses `async.when` error first) | file read | transient realtime error hides notifications | Tier C |

### F. Performance and lifecycle

| ID | Sev | Finding | Evidence | Impact | Fix |
|---|---|---|---|---|---|
| F1 | H | **80 bare `.select()` vs 5 `.limit(`**; unbounded: all sessions, all profiles, all payments, all reports, attendance w/o range | datasource greps | table scans grow with data | Tier C |
| F2 | M | Notifications stream capped `.limit(50)` → unread count **under-reports past 50** | `supabase_notification_datasource.dart:71` | badge wrong for heavy users | Tier C (count query) |
| F3 | I | Realtime: only 2 `.stream(` calls (attendance, notifications); no undisposed manual channels; `watchAttendance()` dead | greps | — | none |
| F4 | M | `bootstrap()` runs 4 sequential awaits before first frame; no timeout on `Supabase.initialize`; permission prompt blocks startup | `bootstrap.dart:12,26,43,44` | slow/offline start | Tier C |
| F5 | M | Screens fetch all users / all 90-day attendance then filter client-side | `trainees_attendance_screen.dart:41`, `checkin_controller.dart:62-76` | payload bloat | Tier C |
| F6 | I | Big lists: 9 non-builder `ListView(` all short; 24 `ListView.separated` | counts | — | none |

### G. Repository hygiene

| ID | Sev | Finding | Evidence | Impact | Fix |
|---|---|---|---|---|---|
| G1 | C→FIXED | `pubspec` references `assets/icons/` and `assets/illustrations/` but both were **empty & untracked** → fresh clone build fails | `pubspec.yaml:71-72`, `git status assets` | broken clone | **FIXED** `.gitkeep` added (`4d4fb35`) |
| G2 | H→FIXED | No `LICENSE`, no `.env.example`, no CI, old README referenced non-existent `supabase_migrations/` and phantom `*.g.dart` outputs | old README lines 97, 546-547 | misleading portfolio | **FIXED** `4d4fb35` (README rewritten, MIT LICENSE, `.env.example`, CI workflow, screenshots checklist) |
| G3 | I | `.env` git-ignored ✓ (`.gitignore:49-51`), untracked ✓, anon-only ✓; no `service_role` value in any tracked file | F14 | — | `.env.example` documents policy |
| G4 | M | `main` = 1 commit; no reviewable history; `.metadata`/`devtools_options.yaml` tracked (Flutter-standard, acceptable) | `git log` | hard to review | proposed plan below |
| G5 | L | Unexplained `dependency_overrides: app_links: 6.3.2`; `http` declared as "temporary diagnostic" but never imported; `gym_pro.iml` present | `pubspec.yaml:50,75-76` | reproducibility noise | documented (Tier C) |
| G6 | L | Largest binaries: `hall_a.png` 1.54 MB, `avatar_placeholder.png` 1.35 MB, `Cairo.ttf` 0.57 MB — none >2 MB | `git ls-files` sizes | acceptable | none |

---

## 3. Contract-check results

- **Snapshot files:** `docs/db-snapshot/` not present → column-level check **[NOT RUN]** (charter fallback used).
- **Table names:** 20/20 exact match vs contract (C2). **[VERIFIED]**
- **Notification types:** 6/6 server types now parsed to first-class enum values with round-trip tests; unknown → `system` (C3) **[FIXED, VERIFIED]**
- **`data` jsonb:** `screen` + `membership_id` parsed; deep-link mapping consumes `screen` (C4) **[FIXED, VERIFIED]**
- **RPC/functions:** `expire_due_memberships`, `create-user`, `delete-user` recorded (C5).
- **Never-used contract items:** cannot be listed without the snapshot **[NOT RUN]**.

---

## 4. Notification verdict

### 4.1 Scores (0–10, post-fix delivered state)

| # | Dimension | Score | Evidence |
|---|---|---|---|
| 1 | Model / parsing | **8** | 6 server types + legacy, `data` jsonb null-safe, unknown→system no crash; `entity_id` kept but inert (`notification_model.dart`) |
| 2 | Data source & lifecycle | **7** | uid filter+RLS, newest-first, limit 50, uid-less→empty stream; **disposal on logout now via provider invalidation**; churny screen invalidates |
| 3 | State management | **7** | derived count consistent + live, error→0; error branch blanks list; 50-cap under-count |
| 4 | Actions | **8** | only `is_read` ever written; delete safe; stream/invalidate-driven, no flicker |
| 5 | Deep links | **8** | all 6 `screen` values → real role-correct routes, unknown→no-op; was **0/6 pre-fix**; local-notification tap payloads still unhandled |
| 6 | Foreground cue | **5** | badge only — no snackbar/system notification on incoming INSERT |
| 7 | Local scheduling correctness | **4** | service is well-built and unit-tested, but **zero production call sites** (dead layer); `tz.local` = UTC (no `setLocalLocation`/device-tz package); inexact mode correct |
| 8 | Permissions & platform config | **8** | runtime `POST_NOTIFICATIONS` ✓, inexact → no exact-alarm perms needed ✓, manifest receivers ✓, desugaring ✓, try/catch platform guards ✓; permission asked at cold start pre-login (minor) |
| 9 | Tests | **8** | contract types, `data`, deep-links×roles, unread live logic, logout cleanup, `isSchedulable/toTz/idFor`, bell/screen/repo suites; missing: datasource stream-contract + tap→push widget test |
| 10 | Documentation honesty | **8** | README now states the no-push limitation plainly; pre-fix README overstated timezone behavior (removed) |
| | **Total** | **71/100** | **Grade B−** (pre-review state ≈ 48/100, grade C−) |

### 4.2 What works / what is missing

**Works:** server-contract parsing, RLS+uid-scoped realtime stream, live unread badge in all 4 shells, safe actions, role-correct deep links for all six screens, permission + manifest + desugaring configuration, broad test coverage of pure logic, honest docs.

**Missing:** push service (nothing reaches a closed app), no wired local-scheduling events, no foreground cue beyond the badge, device timezone never resolved, unread count capped at 50, transient-error blank screen, local-notification tap routing.

### 4.3 What would make this implementation excellent (max 8, by value)

1. Add push (FCM) or wire local scheduled reminders to real events (booking, fixed schedule, membership expiry) with a device-timezone package + `tz.setLocalLocation`.
2. Handle local-notification taps with the same `notificationRouteFor` mapping (`onDidReceiveNotificationResponse` + payload JSON).
3. Replace `.limit(50)`-derived unread count with a `count` head query (or paginate the list).
4. Foreground cue: `ref.listen` on the stream → `AppToast`/snackbar on new INSERT.
5. Keep stale data on stream error (list + inline retry instead of blanking).
6. Move permission request to first login/feature use; surface denial state in settings.
7. Add datasource stream-contract tests (filter/order/limit) + a widget test: tap notification → expect push.
8. Keep the new logout/deep-link tests green in CI (regression guard).

### 4.4 Honest limitation (plain words)

**There is no push service. If the app is not running, the user receives nothing for server-side events. In-app notifications arrive only while the app is open, and local reminders fire only if they were scheduled earlier on the same device — currently no local reminders are scheduled at all.**

### 4.5 Manual notification test checklist (for the author)

| # | Step | Expected result | Result |
|---|---|---|---|
| 1 | Android 13+: fresh install → accept permission prompt | Bell badge updates live on server INSERT | |
| 2 | Android 13+: deny permission, trigger a local `showNow` (when wired) | No system notification; in-app badge still works; app doesn't crash | |
| 3 | Android 12: schedule an inexact reminder (when wired) | Fires within minutes of target, no exact-alarm permission needed | |
| 4 | Reboot device | Previously scheduled reminders survive (boot receiver) | |
| 5 | Kill app (swipe away), server creates notification | **Nothing received** (documented limitation); badge correct on next open | |
| 6 | Battery saver / Doze, app backgrounded | In-app update on return; scheduled local reminder may be deferred (inexact) | |
| 7 | Two users on one device: login A → logout → login B | B sees 0 notifications, no A leftovers (new invalidation test covers logic) | |
| 8 | Deep link: `my_bookings` tap as trainee | Opens `/trainee/bookings` | |
| 9 | Deep link: `membership` + `membership_expiring_soon` tap | Opens `/trainee/membership` | |
| 10 | Deep link: `my_trainer` tap | Opens `/trainee/trainer` | |
| 11 | Deep link: `trainees` tap as trainer | Opens `/trainer/trainees` | |
| 12 | Deep link: `fixed_schedule` tap (trainer / trainee) | `/trainer/schedule` / `/trainee/private-sessions` | |
| 13 | Cold start from a notification tap (app killed) | Opens login if session valid → lands on mapped route; else login → route | |
| 14 | Arabic RTL in notification text + list | Correct RTL rendering, Arabic relative time wording | |
| 15 | Change device time zone, check displayed times | Formatters output local zone times | |
| 16 | iOS (if available): permission + display | Prompt appears; badge/list work | |
| 17 | Web: bell + list | Badge and list work; no local-scheduling UI offered | |

---

## 5. README claims table (old README at `6b9b1ab` vs evidence)

| Claim | Verdict | Evidence |
|---|---|---|
| "222 Dart source files" | **Verified** | 219 + 3 mains = 222 (`F10`) |
| "144 tests" | **Verified** (at the time) | 144 pre-fix; now 166 (`F11`) |
| "20 tables" | **Verified** | 20 `.from()` names = contract (`C2`) |
| "Platforms: Android · iOS · Web · Windows · macOS" | **Partial** | only Android-debug + Web-admin verified built (`F7/F8`); rest scaffolded → new platform table |
| "`supabase_migrations/` 007·008·009" | **Wrong** | folder does not exist; charter forbids SQL → removed |
| "build_runner produces `*.g.dart`/`*.freezed.dart`" | **Wrong** | 0 outputs; 0 generated files (`F3/F10`) → README corrected |
| "Screens never call a repository directly — they go through a use case" | **Wrong** | use-case layer has 0 external imports (`A5`) → replaced by honest note |
| "Only `datasources/` may reference `SupabaseQueryBuilder`" | **Wrong** | presentation: 15 files use datasources, 5 use `Supabase.instance` (`A3/A4`) |
| "Async rendering uses `valueOrNull` rather than `.value`" | **Wrong** | 40 `.value` vs 5 `valueOrNull` pre-fix (`A8`) |
| "NotificationBell mounted in admin shell, reception shell, trainee dashboard, trainer dashboard" | **Verified** | 4 call sites confirmed |
| "Scheduling is deterministic in the device timezone" | **Wrong** | no `setLocalLocation`; `tz.local`=UTC (§4.7) → removed from README |
| "Android config verified in merged manifest" | **Verified** | re-verified in this review (`F9`) |
| "RoleGuard snippet / 3 entry points / no main.dart" | **Verified** | `B1`, `role_guard.dart` |
| Test breakdown (27+42+15+44+13+3) | **Partial** | file-level counts plausible, but 19 of the screen tests fail → new Testing section states it |
| "144 tests across 14 files" table | **Verified then** | superseded by measured numbers |

---

## 6. Fix log (this branch)

| Commit | Contents |
|---|---|
| `843872b` | `.gitignore`: ignore `workspace/*` |
| `10731a9` | **fix(notifications)**: 6 server types + round trips; `data` jsonb parsing; `entity_id` removed from insert payload; role-aware deep-link mapping + screen wiring; `Formatters` `.toLocal()`; logout invalidates notification providers + `cancelAll`; shell logout via AuthController; `CircularDependencyError` fix (`currentUserIdProvider`); `valueOrNull` for role; +22 tests; −8 test warnings |
| `4d4fb35` | **docs**: truthful README (≤350 lines), `.env.example`, MIT `LICENSE`, CI workflow, `docs/screenshots/README.md`, `.gitkeep` for empty asset dirs |
| (this) | `docs/internal/` bilingual reports, `docs/PROJECT_GUIDE.md` |

Post-fix gates: `flutter analyze` = **0 errors / 0 warnings / 36 infos**; `custom_lint` = clean; `flutter test` = **147 pass / 19 pre-existing fail** (+1 hanging file excluded, unchanged); web + APK builds still green.

---

## 7. Open Tier C items (report only — not fixed)

1. Reintroduce the use-case layer in presentation or delete it (currently dead).
2. Presentation↔data decoupling (models/datasources out of screens; `Supabase.instance` out of routers).
3. Replace 40 `AsyncValue.value` sites; add `autoDispose`/`ref.listen` where per-screen.
4. Membership end-day off-by-one (entity vs model) — needs a product decision.
5. Booking: session-status/membership/gender pre-checks or confirmation that DB triggers cover them.
6. PDF Arabic shaping (`--dart-define=use_arabic=true` or shaping library).
7. Pagination/limits on 80 unbounded selects; unread count beyond 50.
8. Timezone: add device-tz package before enabling any local scheduling.
9. Week-start alignment (`weekday % 7` vs Saturday=0).
10. Dead code removal: `trainer_router`, `trainee_router`, 2 nav controllers, `reception_slide_drawer`, `AppStrings`/`WebTheme`/`MobileTheme`/`watchAttendance`, unused deps `flutter_screenutil`, `http`.
11. Permission request timing; error-branch blanking in notifications screen.
12. Git history: squash-rebase into reviewed conventional commits + tag `v1.0.0` before publishing (proposed, not run).
13. `.gitignore`-optional: author may ignore `docs/internal/` before publishing.

---

## 8. Readiness scorecard

| Area | Score | One-line evidence |
|---|---|---|
| Architecture | **6** | Clean layers verified in domain/data, but use cases dead & 43 presentation→data imports (`A1/A5/A2`) |
| Business logic (client) | **6** | capacity/duplicate/overlap/QR guards present; off-by-one, missing status checks, static QR (`D1-D4`) |
| Notifications | **7** | 71/100 post-fix; contract + deep links + logout fixed; no push, scheduling dead (§4) |
| UI & design system | **6** | tokens/themes exist but AppStrings unused, 934 hard-coded colors (`E1-E4`) |
| RTL & Arabic | **7** | global RTL + Cairo + Arabic copy everywhere; directional insets nearly unused, a11y absent (`E5`) |
| Responsiveness | **6** | rail/drawer/bottom nav adaptive; 4 conflicting breakpoint sets (`E6`) |
| Error handling & states | **6** | `Either` in data + AsyncErrorView 50 uses; 48 `throw Exception`, raw `$e` shown (`A5/A6/E8`) |
| Tests | **6** | 166 cases, notification suite strong; **19 stale failures + 1 hanging test** (`F6`) |
| Performance & lifecycle | **5** | 80 unbounded selects, 4 pre-frame awaits, count capped at 50 (`F1/F2/F4`) |
| Documentation | **8** | new README truthful + PROJECT_GUIDE + bilingual reports; git history still 1 commit (`G4`) |
| Repository hygiene | **7** | secrets clean, LICENSE/CI/.env.example added; single-commit history, dead deps (`G3-G5`) |
| **Average** | **6.3/10** | |

### Go / No-Go

**1. Publish on GitHub as a portfolio project — GO (conditional).**
Conditions met: no secrets, truthful README, LICENSE, CI, screenshots checklist. Remaining conditions for the author: squash history into a few reviewable commits (§7.12) and optionally ignore `docs/internal/`. Blockers: none technical.

**2. Demo to a recruiter (screen share) — GO.**
Verified web (admin) and Android builds; login → role routing → dashboards → notifications deep links work in code paths; demo accounts to be created by author (`TODO(author)`). Risk: 19 failing tests are irrelevant to a demo but must not be shown as "all tests green".

**3. Pilot in a real gym with real users — NO-GO.**
Blockers: (a) no push — closed-app users miss all server events; (b) client-only booking/check-in rules unconfirmed against the DB; (c) membership off-by-one + week-start bug affect daily operations; (d) unbounded queries will degrade with real data volume; (e) no release signing/error reporting. Reassess after: push/scheduling layer, DB-confirmation of server rules, pagination, crash reporting.

---

## 9. Accepted by the author (no action requested)

Recorded neutrally per the review charter — these are backend/database decisions the author reviewed in the live Supabase project and chose to keep; **not re-opened, not fixed, not re-verified here**:

1. Public sign-ups setting and role taken from sign-up metadata.
2. `create_notification` and a few `SECURITY DEFINER` helpers being callable through the API.
3. `profiles` self-update not column-restricted.
4. No database-level capacity/status rules on `bookings`.
5. Broad table grants to `anon`/`authenticated`.
6. Leaked-password protection disabled.
7. Edge Functions `create-user` and `delete-user` exist in the Supabase project and are **not in this repository** — recorded here as a documentation gap (now mentioned in README §6).
