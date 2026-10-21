# Screenshots

Capture the following screens for the portfolio README. All shots should be
in the app's native Arabic RTL dark theme. Suggested viewport: 1440×900 for
web roles, 390×844 for the mobile app.

Save each file under `docs/screenshots/` with exactly these names, then
replace the `<!-- TODO(author) -->` placeholders in the root `README.md`.

## Admin (`main_admin.dart`, web)

| File | Screen | How to reach |
|---|---|---|
| `admin.png` | Dashboard with stat cards and charts | `/admin/dashboard` |
| `admin_users.png` | User management table | `/admin/users` |
| `admin_reports.png` | Financial reports + fl_chart | `/admin/finance/reports` |

## Reception (`main_reception.dart`, web)

| File | Screen | How to reach |
|---|---|---|
| `reception.png` | Dashboard with stats | `/reception/dashboard` |
| `reception_checkin.png` | Check-in search screen | `/reception/checkin` |
| `reception_membership.png` | Memberships list | `/reception/memberships` |

## Trainer + Trainee (`main_mobile.dart`, device/emulator)

| File | Screen | How to reach |
|---|---|---|
| `trainee.png` | Trainee dashboard | login as trainee |
| `trainee_qr.png` | Personal QR code | `/trainee/qr` tab |
| `trainer.png` | Trainer trainees list | login as trainer |
| `notifications.png` | Notifications screen with unread badge | bell icon → notifications |

## Notes

- Log in with real demo accounts against your Supabase project; do not leave
  personal data visible in the shots.
- Take one extra shot of the notification deep-link flow (tap a booking
  confirmation → lands on "My Bookings") as `notification_deeplink.png` if
  possible.
