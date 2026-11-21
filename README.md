# Schedul-ER

A separate calendar and event scheduler, copied from DFC-Calendar as a starting point.

## Features
- Public, read-only calendar view
- Sign-in required only to add, edit, or delete events
- Monthly calendar grid, upcoming 14-day reminders, and selected-day event list
- Responsive layout and Source Sans 3 typography
- Event color categories and Supabase realtime updates

## Independent setup

This repository intentionally **does not reuse DFC-Calendar's database credentials**. Configure a separate Supabase project:

1. Create a Supabase project for Schedul-ER.
2. Create a public table named `events` with columns:
   - `id`: bigint identity primary key
   - `title`: text not null
   - `date`: date not null
   - `time`: text (nullable/empty allowed)
   - `notes`: text (nullable)
   - `color`: text (nullable)
   - `created_at`: timestamptz default now()
   - `updated_at`: timestamptz (nullable)
3. In `index.html`, configure this project's Supabase URL and publishable key.
4. Enable email/password authentication and create accounts for the shared/team email addresses. Users who share one team email and password will see the same calendar; signing in with a different email opens a separate calendar.
5. Run the SQL migration in `supabase/calendar-email-migration.sql` in Supabase SQL Editor. It adds `calendar_email` and restricts read/write access to the authenticated user's email. If you have existing events, assign their `calendar_email` values before enabling the migration policies.
6. Deploy to Vercel or GitHub Pages. Supabase Auth persists the session in the browser by default, so users stay signed in after reloads until they sign out or the session expires.

This version is private per email, not public-read. Realtime updates are filtered to the signed-in email calendar.

> Do not put a Supabase service-role key in frontend code.

## Source

Based on [DFC-Calendar](https://github.com/hemandBabu27/DFC-Calendar), maintained separately in this repository.
