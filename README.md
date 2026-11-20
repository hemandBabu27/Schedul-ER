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
3. In `index.html`, replace `YOUR-SUPABASE-PROJECT-URL` and `YOUR-SUPABASE-PUBLISHABLE-KEY` with the new project's URL and publishable key.
4. Enable email/password authentication and create the editors' accounts.
5. Configure RLS policies so anonymous users can `SELECT`, while authenticated users can `INSERT`, `UPDATE`, and `DELETE`. Keep write policies restricted to the intended editors.
6. Deploy the repository to Vercel or GitHub Pages.

> Do not put a Supabase service-role key in frontend code.

## Source

Based on [DFC-Calendar](https://github.com/hemandBabu27/DFC-Calendar), maintained separately in this repository.
