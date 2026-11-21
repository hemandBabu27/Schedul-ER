-- Schedul-ER: private email-scoped calendars
-- Run in Supabase SQL Editor. Back up your events first.
alter table public.events
  add column if not exists calendar_email text;

-- Existing events: assign them to the intended email before enabling access.
-- Example (edit the address): update public.events set calendar_email = 'team@example.com' where calendar_email is null;

alter table public.events enable row level security;

drop policy if exists "calendar email can read its events" on public.events;
create policy "calendar email can read its events"
on public.events for select
to authenticated
using (lower(calendar_email) = lower(auth.jwt() ->> 'email'));

drop policy if exists "calendar email can insert its events" on public.events;
create policy "calendar email can insert its events"
on public.events for insert
to authenticated
with check (lower(calendar_email) = lower(auth.jwt() ->> 'email'));

drop policy if exists "calendar email can update its events" on public.events;
create policy "calendar email can update its events"
on public.events for update
to authenticated
using (lower(calendar_email) = lower(auth.jwt() ->> 'email'))
with check (lower(calendar_email) = lower(auth.jwt() ->> 'email'));

drop policy if exists "calendar email can delete its events" on public.events;
create policy "calendar email can delete its events"
on public.events for delete
to authenticated
using (lower(calendar_email) = lower(auth.jwt() ->> 'email'));

-- Realtime: ensure events table is in the supabase_realtime publication if needed.
