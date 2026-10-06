# Gym Pro

Gym management system built with **Flutter** and **Supabase**, split into four role-based applications: **Admin**, **Reception**, **Trainer**, and **Trainee**.

| | |
|---|---|
| **Platforms** | Android · iOS · Web · Windows · macOS |
| **Language** | Dart `^3.5.4` · Flutter `3.24.x` |
| **UI** | Arabic, full RTL, responsive from phone to desktop |
| **Backend** | Supabase (PostgreSQL + Row Level Security + Realtime) |
| **Size** | 222 Dart source files · 144 tests |

---

## Contents

1. [Tech Stack](#1-tech-stack)
2. [Repository Layout](#2-repository-layout)
3. [Architecture](#3-architecture)
4. [Entry Points & Role Guard](#4-entry-points--role-guard)
5. [Routing](#5-routing)
6. [Domain Layer](#6-domain-layer)
7. [Data Layer](#7-data-layer)
8. [Presentation Layer](#8-presentation-layer)
9. [Core Layer](#9-core-layer)
10. [Database](#10-database)
11. [Notifications](#11-notifications)
12. [Design System](#12-design-system)
13. [Code Generation & Analysis](#13-code-generation--analysis)
14. [Testing](#14-testing)
15. [Commands](#15-commands)

---

## 1. Tech Stack

| Concern | Package |
|---|---|
| State management | `flutter_riverpod` · `riverpod_annotation` · `riverpod_lint` |
| Backend | `supabase_flutter` 2.x |
| Navigation | `go_router` 14.x (`GoRoute` trees, one per role) |
| Code generation | `freezed` · `json_serializable` · `build_runner` |
| Serialization | `json_annotation` · `freezed_annotation` |
| Responsive UI | `flutter_screenutil` · custom `ResponsiveLayout` |
| Charts | `fl_chart` |
| PDF export | `pdf` · `printing` |
| QR | `qr_flutter` (generate) · `mobile_scanner` (scan) |
| Local notifications | `flutter_local_notifications` 19.5 · `timezone` 0.10 |
| Styling | `google_fonts` · `flutter_svg` · `cached_network_image` |
| Functional helpers | `dartz` (`Either`) · `equatable` |
| Env loading | `flutter_dotenv` |
| Testing | `flutter_test` · `mocktail` |
| Linting | `flutter_lints` · `custom_lint` · `riverpod_lint` |

---

## 2. Repository Layout

```
gym_pro/
├── lib/
│   ├── main_admin.dart              # entry point — Admin (web-first)
│   ├── main_reception.dart          # entry point — Reception (web-first)
│   ├── main_mobile.dart             # entry point — Trainer + Trainee (mobile-first)
│   │
│   ├── core/                        # 23 files — cross-cutting, no business rules
│   │   ├── auth/                    # role_guard · session_role · auth_refresh
│   │   ├── bootstrap/               # bootstrap() shared by all 3 entry points
│   │   ├── constants/               # app_colors · app_dimensions · app_strings · enums
│   │   ├── errors/                  # exceptions · failures · supabase_error
│   │   ├── network/                 # supabase_client
│   │   ├── notifications/           # local_notifications_service
│   │   ├── theme/                   # app_theme · web_theme · mobile_theme
│   │   └── utils/                   # formatters · validators · extensions ·
│   │                                # pdf_report_generator · time_slot_generator …
│   │
│   ├── domain/                      # 49 files — pure Dart, framework-free
│   │   ├── entities/                # 19 entities
│   │   ├── repositories/            # i_*_repository.dart interfaces
│   │   └── usecases/                # 18 use cases, grouped by feature folder
│   │
│   ├── data/                        # 44 files — Supabase implementation
│   │   ├── models/                  # *_model.dart with fromJson / toJson
│   │   ├── datasources/             # 12 supabase_*_datasource.dart
│   │   ├── repositories_impl/       # classes implementing domain interfaces
│   │   └── providers.dart           # central Riverpod wiring
│   │
│   └── presentation/                # 103 files
│       ├── admin/       (16)        # dashboard · users · halls · sessions · finance
│       ├── reception/   (19)        # checkin · memberships · bookings · payments
│       ├── trainee/     (21)        # qr_code · bookings · my_program · my_diet
│       ├── trainer/     (18)        # program_builder · diet_builder · trainees
│       ├── shared/      (28)        # auth · notifications · schedule · settings · widgets
│       └── mobile/      (1)         # mobile_router (trainer + trainee)
│
├── test/                            # 14 files · 144 tests
├── supabase_migrations/             # 007 · 008 · 009
├── assets/                          # fonts · images · icons · illustrations
├── android/ ios/ web/ macos/ windows/
├── analysis_options.yaml            # flutter_lints + riverpod_lint + custom_lint
└── pubspec.yaml
```

---

## 3. Architecture

Clean architecture with three layers and a strictly unidirectional dependency flow:

```
        ┌──────────────────────────────────────────────┐
        │  presentation/                              │
        │  screens · Riverpod controllers · routers   │
        └───────────────┬──────────────────────────────┘
                        │ depends on
                        ▼
        ┌──────────────────────────────────────────────┐
        │  domain/                                    │
        │  entities · repository interfaces · use     │
        │  cases          (zero Flutter/Supabase)     │
        └───────────────┬──────────────────────────────┘
                        │ implemented by
                        ▼
        ┌──────────────────────────────────────────────┐
        │  data/                                      │
        │  models · datasources · repository          │
        │  implementations                            │
        └───────────────┬──────────────────────────────┘
                        │ talks to
                        ▼
                  Supabase / PostgreSQL (+ RLS)

   core/ is imported by every layer but imports nothing from them.
```

### Rules enforced in this codebase

- **`domain/` is pure Dart.** No `import 'package:flutter/...'`, no Supabase types.
  Entities are plain classes; repositories are abstract interfaces; use cases are
  small classes with a single `call()` method.
- **`data/` owns all conversion.** Every model extends its entity and exposes
  `fromJson` / `toJson`. Only `datasources/` may reference `SupabaseQueryBuilder`.
- **Errors flow left.** Data sources throw typed `Failure`s; repositories wrap
  results in `Either<Failure, T>` via `dartz`; screens render the message instead
  of crashing.
- **Dependencies are injected through Riverpod.** Every bindable dependency lives
  in `lib/data/providers.dart`. Repositories are declared as
  `Provider<ISomeRepository>` (the interface, not the class) so tests can override
  them without losing static typing.
- **Use cases are the only callable verbs.** Screens never call a repository
  directly — they go through a use case such as `BookSessionUc`, `RecordPaymentUc`,
  or `GenerateReportUc`.

---

## 4. Entry Points & Role Guard

There is **no `main.dart`**. Each platform bundle launches one of three files, and
each file calls the shared `bootstrap()` before starting its router.

| File | `AppEntry` | Allowed roles | Target |
|---|---|---|---|
| `lib/main_admin.dart` | `admin` | `admin` only | Wide screens / web |
| `lib/main_reception.dart` | `reception` | `reception` only | Wide screens / web |
| `lib/main_mobile.dart` | `mobile` | `trainer`, `trainee` | Phones / tablets |

Role enforcement lives in `lib/core/auth/role_guard.dart`:

```dart
enum AppEntry { admin, reception, mobile }

class RoleGuard {
  static List<UserRole> allowedRoles(AppEntry entry) {
    switch (entry) {
      case AppEntry.admin:     return [UserRole.admin];
      case AppEntry.reception: return [UserRole.reception];
      case AppEntry.mobile:    return [UserRole.trainer, UserRole.trainee];
    }
  }

  static bool isAllowed(UserRole role, AppEntry entry) =>
      allowedRoles(entry).contains(role);
}
```

A user who signs in with a non-matching role receives
`RoleGuard.errorMessage(...)` instead of a router redirect.

`bootstrap()` (`lib/core/bootstrap/bootstrap.dart`) is the single initialization
point shared by all three entry points:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Load `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY` / `SUPABASE_PUBLISHABLE_KEY`)
3. `Supabase.initialize(...)`
4. Initialize local notifications (guarded by `try/catch`)
5. Install a global `FlutterError.onError` handler

---

## 5. Routing

Navigation uses `go_router`, with one `GoRoute` tree per entry point and a shell
screen that renders a role-specific navigation rail.

### `admin_router.dart`

| Path | Screen |
|---|---|
| `/admin/dashboard` | Dashboard |
| `/admin/users`, `new`, `:id` | User management |
| `/admin/halls`, `:id/periods` | Halls and access periods |
| `/admin/sessions`, `new` | Group sessions |
| `/admin/finance/reports` | Financial reports |
| `/admin/schedule` | Weekly schedule |
| `/admin/notifications` | Notifications |

### `reception_router.dart`

| Path | Screen |
|---|---|
| `/reception/dashboard` | Dashboard |
| `/reception/checkin`, `checkin/qr` | Attendance / QR scan |
| `/reception/memberships` | Memberships |
| `/reception/bookings/group`, `bookings/private` | Bookings |
| `/reception/trainer-assignment` | Trainer assignment |
| `/reception/payments/record` | Payment entry |
| `/reception/schedule` | Daily schedule |
| `/reception/trainees/new` | New trainee |
| `/reception/notifications` | Notifications |

### `mobile_router.dart` (Trainer + Trainee)

| Path | Screen |
|---|---|
| `/mobile`, `/mobile/settings`, `/mobile/notifications` | Shell, settings, notifications |
| `/trainer/dashboard` | Trainer dashboard |
| `/trainer/trainees`, `/trainer/trainees/:id` | Trainee list and detail |
| `/trainer/programs/new`, `:id/days`, `days/:dayId/exercises` | Program builder |
| `/trainer/diets/new`, `:id/days`, `days/:dayId/meals` | Diet builder |
| `/trainer/attendance`, `/trainer/schedule`, `/trainer/all-schedule` | Attendance and schedule |
| `/trainee/dashboard`, `/trainee/qr` | Trainee dashboard, personal QR |
| `/trainee/bookings`, `/trainee/membership`, `/trainee/schedule` | Booking and membership |
| `/trainee/program`, `/trainee/diet`, `/trainee/trainer` | My program / diet / trainer |
| `/trainee/attendance`, `/trainee/private-sessions` | History and private sessions |

### Active-section state

Each role has a `*_nav_controller.dart` holding a `StateProvider` over an enum of
sections, and a resolver that derives the active section from the current
`location`:

```
lib/presentation/admin/controllers/admin_nav_controller.dart
lib/presentation/reception/controllers/reception_nav_controller.dart
lib/presentation/trainer/controllers/trainer_nav_controller.dart
lib/presentation/trainee/controllers/trainee_nav_controller.dart
```

The enums carry display metadata — for example:

```dart
enum AdminSection {
  dashboard('لوحة التحكم', 'dashboard', 'لوحة التحكم'),
  users('المستخدمين', 'users', 'الأعضاء'),
  halls('القاعات', 'halls', 'القاعات'),
  sessions('الحصص', 'sessions', 'الحصص'),
  finance('التقارير المالية', 'finance', 'المالية'),
  schedule('الجدول الأسبوعي', 'schedule', 'الجدول');
  // label · routeSegment · shortLabel (shown when the rail collapses)
}
```

---

## 6. Domain Layer

### Entities (`lib/domain/entities/` — 19)

```
User  Hall  AccessPeriod  Session  Booking  Attendance  Membership
TrainingProgram  ProgramDay  ProgramExercise
Diet  DietDay  DietMeal
PrivateTrainingSession  PrivateTrainingSchedule
TrainerTrainee  PaymentCost  Report  NotificationItem
```

### Use cases (`lib/domain/usecases/` — 18)

| Folder | Use cases |
|---|---|
| `auth/` | `LoginUc` · `LogoutUc` · `GetCurrentUserUc` |
| `membership/` | `CreateMembershipUc` · `RenewMembershipUc` · `CheckMembershipStatusUc` |
| `session/` | `CreateSessionUc` · `BookSessionUc` · `CancelBookingUc` |
| `attendance/` | `RecordAttendanceUc` · `GetAttendanceHistoryUc` |
| `program/` | `CreateTrainingProgramUc` · `GetTraineeProgramsUc` |
| `diet/` | `CreateDietPlanUc` · `GetTraineeDietsUc` |
| `payment/` | `RecordPaymentUc` · `GetPaymentsUc` |
| `report/` | `GenerateReportUc` |

### Repository interfaces (`lib/domain/repositories/`)

One `i_*_repository.dart` per aggregate. `data/repositories_impl/` contains the
single concrete implementation of each. The notification interface, for example:

```dart
abstract interface class INotificationRepository {
  Future<List<AppNotification>> fetchAll();
  Future<List<AppNotification>> fetchUnread();
  Future<int> fetchUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> delete(String id);
}
```

---

## 7. Data Layer

### Datasources (`lib/data/datasources/` — 12)

```
supabase_auth_datasource          supabase_user_datasource
supabase_hall_datasource          supabase_session_datasource
supabase_booking_datasource       supabase_membership_datasource
supabase_attendance_datasource    supabase_program_datasource
supabase_diet_datasource          supabase_payment_datasource
supabase_report_datasource        supabase_notification_datasource
```

Each datasource is the only place that issues `.from('table')` queries for its
aggregate and translates rows into `Model` instances.

### Models (`lib/data/models/`)

`*_model.dart` files subclass the corresponding entity and provide
`fromJson` / `toJson` / `copyWith`. `json_serializable` output (where enabled) is
generated into `*.g.dart`.

### Central wiring (`lib/data/providers.dart`)

```dart
final notificationDatasourceProvider =
    Provider((ref) => SupabaseNotificationDatasource(ref.watch(supabaseClientProvider)));

// Declared against the INTERFACE so tests can override it.
final notificationRepositoryProvider = Provider<INotificationRepository>(
    (ref) => NotificationRepositoryImpl(ref.watch(notificationDatasourceProvider)));
```

---

## 8. Presentation Layer

### Modules

| Module | Files | Contents |
|---|---|---|
| `admin/` | 16 | `dashboard` · `users` · `halls` · `sessions` · `finance` + `router` + `controllers` |
| `reception/` | 19 | `dashboard` · `checkin` · `memberships` · `bookings` · `assignment` · `payments` + `router` |
| `trainer/` | 18 | `dashboard` · `trainees` · `program_builder` · `diet_builder` · `attendance` · `schedule` |
| `trainee/` | 21 | `dashboard` · `qr_code` · `bookings` · `membership` · `my_program` · `my_diet` · `my_trainer` · `private_sessions` · `attendance` |
| `shared/` | 28 | `auth/` · `notifications/` · `schedule/` · `settings/` · `widgets/` |
| `mobile/` | 1 | `mobile_router` shared by trainer and trainee |

### State management pattern

- `*_controller.dart` next to each screen declares `StateProvider`,
  `FutureProvider`, or `AsyncNotifier`-style providers.
- Screens read state with `ref.watch` and mutate through controller functions.
- Async rendering goes through `AsyncValue.when(...)`, using **`valueOrNull`**
  rather than `.value` (`.value` throws when `hasValue == false`).

### Shared widgets (`lib/presentation/shared/widgets/` — 20)

```
app_button            app_card              app_text_field
app_dropdown           app_date_picker       app_table
app_toast              async_error_view      loading_indicator
status_badge           stat_card             section_header
responsive_layout      adaptive_nav_scaffold notification_bell
reception_slide_drawer finance_charts        user_search_field
membership_expired_dialog  athletic_scaffold
```

`ResponsiveLayout` and `adaptive_nav_scaffold` handle the phone ↔ tablet ↔
desktop switch: a navigation rail on wide layouts collapses into a drawer or a
bottom bar on narrow ones.

### Shared feature folders (`lib/presentation/shared/`)

| Folder | Contents |
|---|---|
| `auth/` | `login_screen`, `auth_controller` — sign-in shared by all three entry points |
| `notifications/` | `notifications_screen`, `notifications_controller` |
| `schedule/` | `daily_schedule_screen`, `schedule_data_provider`, `period_bottom_sheet` |
| `settings/` | `settings_screen` |

---

## 9. Core Layer

| Folder | Files | Responsibility |
|---|---|---|
| `auth/` | `role_guard.dart` · `session_role.dart` · `auth_refresh.dart` | Role-based entry gating and token refresh |
| `bootstrap/` | `bootstrap.dart` | Shared initialization for all entry points |
| `constants/` | `enums.dart` · `app_colors.dart` · `app_dimensions.dart` · `app_strings.dart` | Domain enums and design tokens |
| `errors/` | `exceptions.dart` · `failures.dart` · `supabase_error.dart` | Error taxonomy and Supabase error translation |
| `network/` | `supabase_client.dart` | Supabase client provider |
| `notifications/` | `local_notifications_service.dart` | Local notification scheduling |
| `theme/` | `app_theme.dart` · `web_theme.dart` · `mobile_theme.dart` | Three Material 3 themes |
| `utils/` | `formatters` · `validators` · `extensions` · `day_of_week_helper` · `time_slot_generator` · `permission_helper` · `pdf_report_generator` | Reusable pure helpers |

### Domain enums (`lib/core/constants/enums.dart`)

```dart
enum UserRole { admin, reception, trainer, trainee }
enum Gender { male, female }
enum MembershipStatus { active, expired, suspended }
enum SessionStatus { scheduled, cancelled, completed }
enum BookingStatus { confirmed, cancelled }
enum PrivateSessionStatus { scheduled, cancelled, completed }
enum TrainerTraineeStatus { active, inactive }
enum AttendanceMethod { qr, manual }
enum AccessType { mixed, women, maintenance, courseReserved }
enum PaymentType { income, expense }
enum NotificationType { /* + NotificationTypeX label/color extension */ }
enum PaymentCategory { /* + PaymentCategoryX extension */ }
```

Display labels, colors, and Arabic strings are attached through companion
`XxxTypeX` extensions, so screens never switch on raw enum values.

---

## 10. Database

### Tables (20)

```
profiles · halls · access_periods · session_periods · sessions · bookings ·
attendance · memberships · training_programs · program_days · program_exercises ·
diets · diet_days · diet_meals · private_training_sessions ·
private_training_schedule · trainer_trainees · payment_costs · reports ·
notifications
```



### Security

- Row Level Security on all tables; `profiles.is_staff()` distinguishes staff from
  trainees.
- Newer functions use `SECURITY DEFINER SET search_path = public` with explicit
  `GRANT` / `REVOKE` statements.
- Private sessions and hall payments have their own scoped policies (see `007`).

---

## 11. Notifications

Two layers, both free of paid push infrastructure (no FCM, no OneSignal).

### Layer 1 — in-app notifications

- `notifications` table streamed over Supabase **Realtime**.
- `SupabaseNotificationDatasource` → `NotificationRepositoryImpl` →
  `INotificationRepository`.
- `notificationsProvider` and `unreadNotificationsCountProvider` in
  `notifications_controller.dart`.
- `NotificationBell` widget (`shared/widgets/notification_bell.dart`) renders a
  live unread badge and pushes to the notifications route. It is mounted in the
  admin shell, reception shell, trainee dashboard, and trainer dashboard.
- `NotificationsScreen` lists items with relative timestamps via
  `Formatters.timeAgo`.

### Layer 2 — local scheduled notifications

`lib/core/notifications/local_notifications_service.dart`:

```dart
class LocalNotificationsService {
  static final instance = LocalNotificationsService._();
  Future<void> init();
  Future<void> requestPermission();
  Future<void> showNow({required String title, String? body, ...});
  Future<void> scheduleAt(DateTime when, {...});
  Future<void> cancel(int id);
  Future<void> cancelAll();

  // pure, unit-testable helpers
  static TZDateTime toTz(DateTime time);
  static bool isSchedulable(DateTime when, [DateTime? now]);
  static int idFor(String key);
}
```

Implementation notes:

- Singleton initialized inside `bootstrap()`; every public call is wrapped in
  `try/catch` so an unsupported platform never takes the app down.
- Scheduling is deterministic in the device timezone via `timezone`, and survives
  reboot (boot receivers are registered in the manifest).
- `isSchedulable` rejects timestamps strictly before `now ?? DateTime.now()`.

**Android configuration** (verified present in the merged manifest after build):

| Item | Value |
|---|---|
| Permissions | `POST_NOTIFICATIONS` · `RECEIVE_BOOT_COMPLETED` · `VIBRATE` |
| Receivers | `ScheduledNotificationReceiver` · `ScheduledNotificationBootReceiver` |
| Gradle | `coreLibraryDesugaringEnabled true` + `desugar_jdk_libs:2.1.4` · `multiDexEnabled true` |

Core-library desugaring is a hard requirement of `flutter_local_notifications` and
is configured in `android/app/build.gradle`.

---

## 12. Design System

- **Themes** — `core/theme/app_theme.dart` (base Material 3),
  `web_theme.dart` (wide screens), `mobile_theme.dart` (phones). Dark
  "athletic" palette defined in `core/constants/app_colors.dart`.
- **RTL** — the whole app is Arabic; every scaffold is wrapped in the correct
  `Directionality`, and text alignment/mirroring is handled by Flutter's RTL
  support.
- **Responsive** — `flutter_screenutil` for scaled dimensions plus
  `ResponsiveLayout`, which switches between grid and column arrangements and
  changes breakpoints per layout class.
- **Design tokens** — `app_dimensions.dart` (spacing/radius),
  `app_strings.dart` (copy), `enums` extensions (labels/colors).
- **Charts** — `fl_chart`, wrapped in `finance_charts` and `stat_card`.
- **PDF** — `core/utils/pdf_report_generator.dart` builds documents with `pdf`
  and renders them through `printing`.

---

## 13. Code Generation & Analysis

### Generate

```bash
dart run build_runner build --delete-conflicting-outputs
```

Produces `*.g.dart` (JSON) and `*.freezed.dart` (immutable models) for every
annotated type in `domain/` and `data/`.

### Analyze

```bash
flutter analyze --no-pub        # static analysis
dart run custom_lint            # riverpod_lint + custom rules
```

`analysis_options.yaml` enables `flutter_lints`, `riverpod_lint`, and
`custom_lint`.

> `flutter analyze` exits non-zero whenever any `info` is reported, even with zero
> errors — do not chain it with `&&`.

---

## 14. Testing

```bash
flutter test                            # full suite
flutter test test/core/                 # one folder
flutter test --reporter expanded        # verbose
```

**144 tests across 14 files:**

| Area | File | Tests |
|---|---|---|
| Local notifications | `test/core/local_notifications_service_test.dart` | 27 |
| Models | `test/models/private_training_test.dart` · `notification_model_test.dart` · `membership_model_test.dart` | 42 |
| Repositories | `test/repositories/notification_repository_test.dart` | 15 |
| Screens | `test/screens/` — notifications, bell, daily schedule, reports, private sessions | 44 |
| Utilities | `test/utils/schedule_utils_test.dart` | 13 |
| App-level | `widget_test` · `drawer_hit_test` · `drawer_nav_test` | 3 |

### Testing conventions

- **`mocktail`** for doubles. Because fallback values only cover primitives, any
  non-primitive argument passed to a mocked method needs an explicit
  `registerFallbackValue(...)` — required here for `InitializationSettings`,
  `NotificationDetails`, `TZDateTime`, and `AndroidScheduleMode`.
- **Repository providers are declared against interfaces**
  (`Provider<INotificationRepository>`), so tests override them with fakes without
  losing type safety.
- **Pure logic is unit-tested directly** — `isSchedulable`, `toTz`, `idFor`,
  formatters, and time-slot generation have no widget dependency.
- **Never use `AsyncValue.value`** in code under test; it throws when
  `hasValue == false`. Use `valueOrNull`.

---

## 15. Commands

Because the project has **no `main.dart`**, every run and build command needs an
explicit `--target`.

```bash
# ---------------------------------------------------------------
# Setup
# ---------------------------------------------------------------
flutter pub get

# ---------------------------------------------------------------
# Run
# ---------------------------------------------------------------
flutter run -t lib/main_admin.dart     -d chrome
flutter run -t lib/main_reception.dart -d chrome
flutter run -t lib/main_mobile.dart    -d <device-id>

# ---------------------------------------------------------------
# Generate / analyze / test
# ---------------------------------------------------------------
dart run build_runner build --delete-conflicting-outputs
flutter analyze --no-pub
dart run custom_lint
flutter test

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
flutter build apk --release --target=lib/main_mobile.dart
flutter build apk --debug   --target=lib/main_admin.dart
flutter build web  --release --target=lib/main_admin.dart
flutter build web  --release --target=lib/main_reception.dart
```

### Environment

Create `.env` in the project root (it is bundled as a Flutter asset and is listed
in `.gitignore`):

```env
SUPABASE_URL=https://YOUR-PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_OR_PUBLISHABLE_KEY
```

`bootstrap()` also accepts `SUPABASE_PUBLISHABLE_KEY` / `SUPABASE_PUBLISHABLE`.
If the file or keys are missing the app falls back to an offline/mock mode instead
of crashing.

### Build outputs

| Artifact | Path |
|---|---|
| Android APK | `build/app/outputs/flutter-apk/app-*.apk` |
| Merged manifest (verify permissions/receivers) | `build/app/intermediates/packaged_manifests/<variant>/AndroidManifest.xml` |
| Web bundle | `build/web/` |
