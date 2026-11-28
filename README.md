# Schedul-ER

A four-class calendar and class-specific noticeboard for TKMCE, built with Supabase Auth, Postgres Row Level Security, and realtime updates.

## Features
- Four separate class calendars (23, 24, 25, 26) in one website and Supabase project
- Students sign in with their TKMCE email and can view only their own class calendar
- Only the assigned class administrator can add, edit, bulk-delete, or delete calendar events
- Signed-in class members can post notices to their own class noticeboard
- Noticeboards are private to members of the matching class
- Realtime calendar and noticeboard updates, monthly view, 14-day reminders, and undo for event deletions
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

The login dialog includes **Continue with Google**. Configure OAuth once before using it:

1. In [Google Cloud Console](https://console.cloud.google.com/), create/select a project and open **Google Auth Platform**.
2. Configure the OAuth consent screen. Choose **Internal** only if every allowed user (including the four admins) belongs to the same Google Workspace organisation. Otherwise choose **External**.
3. Create an OAuth client ID with application type **Web application**.
4. Add your deployed Schedul-ER website origin (for example, `https://your-site.vercel.app`) under **Authorized JavaScript origins**.
5. Under **Authorized redirect URIs**, add this exact Supabase callback:
   `https://begwxweywclyqmbxseih.supabase.co/auth/v1/callback`
6. Copy the Google **Client ID** and **Client Secret**.
7. In Supabase Dashboard → **Authentication → Sign In / Providers → Google**, enable Google and paste the Client ID and Client Secret. Save.
8. In Supabase Dashboard → **Authentication → URL Configuration**, set **Site URL** to your deployed Schedul-ER URL and add that exact URL to **Redirect URLs**. Add any preview or localhost URLs only if you use them.

Students must sign in with their `@tkmce.ac.in` Google account and the address must start with their class number (23, 24, 25, or 26). The four configured admin accounts remain the exact `er27@gmail.com` through `er30@gmail.com` addresses. Other Google accounts may complete Google's sign-in screen but receive no calendar or noticeboard access.

## Supabase setup

1. Use the Supabase project configured in `index.html`, or update `SUPABASE_URL` and the publishable/anon key there to your own project.
2. Enable Email/Password under Supabase Authentication.
3. Create/invite the four administrator accounts and create/invite student accounts using the email patterns above. The application does not create accounts or handle passwords.
4. Ensure `public.events` exists with the existing calendar columns: `id` (identity primary key), `title`, `date`, `time`, `notes`, `color`, `created_at`, and `updated_at`. Existing installations should already have this table.
5. Back up the events table, then run **`supabase/class-calendars-noticeboard-migration.sql`** in Supabase SQL Editor. This adds `class_id`, migrates existing events whose `calendar_email` matches one of the four administrator emails, replaces the old email-scoped policies with class/role policies, and creates the private `notices` table.
6. If existing events were assigned to other shared email addresses, manually set their `class_id` to `23`, `24`, `25`, or `26` in SQL Editor after checking which class owns them. Rows without a class remain inaccessible by design.
7. Deploy the repository to your hosting provider.

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
