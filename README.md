# Schedul-ER

A four-class calendar and class-specific noticeboard for TKMCE, built with Supabase Auth, Postgres Row Level Security, and realtime updates.

## Features
- Four separate class calendars displayed as ER-27, ER-28, ER-29, and ER-30 (internally mapped to classes 23, 24, 25, and 26)
- Students sign in with their TKMCE Google account and can view only their own class calendar
- Only the assigned class administrator can add, edit, bulk-delete, or delete calendar events
- Signed-in class members can post notices to their own class noticeboard
- Noticeboards are private to members of the matching class
- Categorized events with Assignment, Exam, Presentation, and custom tags\n- Realtime calendar and noticeboard updates, monthly view, 14-day reminders, and undo for event deletions
- Responsive Source Sans 3 interface

## Class and account mapping

| Class | Administrator email | Student email pattern |
|---|---|---|
| 23 | `er27@gmail.com` | `23XXXX@tkmce.ac.in` |
| 24 | `er28@gmail.com` | `24XXXX@tkmce.ac.in` |
| 25 | `er29@gmail.com` | `25XXXX@tkmce.ac.in` |
| 26 | `er30@gmail.com` | `26XXXX@tkmce.ac.in` |

The four administrator addresses are exact matches. Student addresses must start with the class number and end in `@tkmce.ac.in`. Each user must have an account in this Supabase project's Authentication system.

## Google sign-in setup

The login dialog provides **Continue with Google** through Supabase Auth. The production site is `https://schedul-er.vercel.app`.

### Google Cloud configuration

- OAuth app audience: **External**.
- While the app is in **Testing**, add every Google account you want to test under **Google Auth Platform → Audience → Test users**. This includes student TKMCE accounts and the four admin accounts.
- OAuth client type: **Web application**.
- Authorized JavaScript origins: left blank (Supabase handles the OAuth exchange).
- Authorized redirect URI:
  `https://begwxweywclyqmbxseih.supabase.co/auth/v1/callback`
- The consent-screen user-support email is the configured Google Group address. Developer contact information is managed separately by Google.

### Supabase configuration

- **Authentication → Sign In / Providers → Google**: enabled, with the Google OAuth Client ID and Client Secret saved in Supabase.
- **Authentication → URL Configuration → Site URL**: `https://schedul-er.vercel.app`.
- **Redirect URLs**: `https://schedul-er.vercel.app`.

Keep the Google OAuth Client Secret in Supabase's provider settings only. Never commit it, a downloaded credentials JSON file, or any secret to this repository or frontend code. The frontend uses the Supabase publishable/anon key and calls `signInWithOAuth({ provider: 'google' })`.

Students must use a Google account whose email starts with their class number (23, 24, 25, or 26) and ends in `@tkmce.ac.in`. The four administrator accounts are the exact addresses `er27@gmail.com`, `er28@gmail.com`, `er29@gmail.com`, and `er30@gmail.com`. Google sign-in does not grant access by itself: the app and Supabase Row Level Security still enforce this mapping. Other accounts are denied class access.


## Supabase setup

1. Use the Supabase project configured in `index.html`, or update `SUPABASE_URL` and the publishable/anon key there to your own project.
2. Enable Email/Password under Supabase Authentication.
3. Create/invite the four administrator accounts and create/invite student accounts using the email patterns above. The application does not create accounts or handle passwords.
4. Ensure `public.events` exists with the existing calendar columns: `id` (identity primary key), `title`, `date`, `time`, `notes`, `color`, `created_at`, and `updated_at`. Existing installations should already have this table.
5. Back up the events table, then run **`supabase/class-calendars-noticeboard-migration.sql`** in Supabase SQL Editor. This adds `class_id`, migrates existing events whose `calendar_email` matches one of the four administrator emails, replaces the old email-scoped policies with class/role policies, and creates the private `notices` table.
6. If existing events were assigned to other shared email addresses, manually set their `class_id` to `23`, `24`, `25`, or `26` in SQL Editor after checking which class owns them. Rows without a class remain inaccessible by design.
7. Run **`supabase/event-categories-migration.sql`** in Supabase SQL Editor. Existing events will receive the default `Custom` category.\n8. Deploy the repository to your hosting provider.

## Permissions enforced by Supabase

- Authenticated students and administrators can select events only when their JWT email maps to that event's `class_id`.
- Only the exact administrator email assigned to a class can insert, update, or delete that class's events.
- Authenticated class members can select and insert notices only for their mapped class. The notice author email must match the signed-in JWT email.
- Only the class administrator can update or delete notices.
- Anonymous users and accounts outside the four supported email patterns have no class calendar or noticeboard access.

Frontend checks only control what the interface displays. The Postgres RLS policies in the migration are the security boundary.

> Never place a Supabase service-role key in frontend code. The publishable/anon key is intended for browser use with correctly configured RLS.

## Legacy migration

`supabase/calendar-email-migration.sql` is the previous per-email calendar setup. For the new four-class configuration, run `supabase/class-calendars-noticeboard-migration.sql` instead. Do not rerun the legacy migration after applying the class migration.

## Source

Based on [DFC-Calendar](https://github.com/hemandBabu27/DFC-Calendar), maintained separately in this repository.


## Background Web Push notifications (all supported devices)

The site now includes the browser-side Web Push setup:
- manifest.json and sw.js register a service worker at the site root.
- Each signed-in browser/device can create its own push subscription using the **Enable background notifications on this device** button.
- supabase/push-notifications-migration.sql stores subscriptions, queues event create/update/delete notices, and records delivery separately for each device.
- supabase/functions/send-push/index.ts sends queued notifications and 14-day, 1-day, and event-day reminders.

### One-time owner setup (required before the button can work)

1. Run supabase/push-notifications-migration.sql in Supabase → SQL Editor.
2. On a computer with Node.js, run:
   npx web-push generate-vapid-keys
   Keep the private key secret. Do not commit it or put it in browser code.
3. In the repository's index.html, replace REPLACE_WITH_VAPID_PUBLIC_KEY in PUSH_VAPID_PUBLIC_KEY with the generated public key only.
4. Install the Supabase CLI and log in, then deploy:
   supabase functions deploy send-push --project-ref begwxweywclyqmbxseih
5. Add the generated values as Supabase Edge Function secrets (never GitHub files):
   supabase secrets set VAPID_PUBLIC_KEY=YOUR_PUBLIC_KEY VAPID_PRIVATE_KEY=YOUR_PRIVATE_KEY VAPID_SUBJECT=mailto:YOUR_REAL_CONTACT_EMAIL --project-ref begwxweywclyqmbxseih
   SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are supplied to Supabase Edge Functions by the platform.
6. In Supabase, enable the pg_cron and pg_net database extensions. In Vault, create a secret named service_role_key whose value is the project's service-role key. Do not paste that key into this repository or the frontend.
7. Run this once in SQL Editor to invoke delivery every five minutes:
   select cron.schedule('schedul-er-web-push','*/5 * * * *',$$ select net.http_post(url := 'https://begwxweywclyqmbxseih.supabase.co/functions/v1/send-push', headers := jsonb_build_object('Content-Type','application/json','Authorization','Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name='service_role_key')), body := '{}'::jsonb); $$);

### Enabling on each device

- Deploy the updated site to https://schedul-er.vercel.app.
- Sign in and press **Enable background notifications on this device** once on each browser/device. Accept the browser's notification prompt.
- Android: Chrome supports background push.
- Windows/macOS: current Chrome and Edge support background push; browser/OS notification settings must allow it.
- iPhone/iPad: open the site in Safari, use **Share → Add to Home Screen**, open the installed Home Screen version, then enable notifications there. iOS/iPadOS 16.4 or later is required for Web Push on Home Screen web apps.

The VAPID public key must match the private key configured in Supabase. If either key is changed later, users should re-enable notifications on their devices. Push notifications require network connectivity and a browser/OS push service; delivery cannot be guaranteed while a device is offline or has disabled background activity. Existing in-page Chrome notifications remain available as a fallback when push is not subscribed.

### Important implementation notes

- Subscriptions are stored per browser/device, so one user can receive the same class alert on multiple devices.
- Supabase RLS limits subscription registration to the signed-in user's mapped class.
- The Edge Function uses the service-role key only on the server and removes expired subscriptions when push services return 404/410.
- Notification delivery is processed every five minutes; reminders are queued on that schedule, not at an exact minute.
