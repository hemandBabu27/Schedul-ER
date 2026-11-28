-- Schedul-ER event categories
-- Run once in Supabase SQL Editor. Existing events default to the Custom category.

alter table public.events
  add column if not exists category text not null default 'Custom';

alter table public.events
  drop constraint if exists events_category_length_check;

alter table public.events
  add constraint events_category_length_check
  check (char_length(trim(category)) between 1 and 32);

create index if not exists events_class_category_date_idx
  on public.events (class_id, category, date);
