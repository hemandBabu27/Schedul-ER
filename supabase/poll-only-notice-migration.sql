-- Schedul-ER: allow poll-only noticeboard posts without a separate title or message.
-- Run once in Supabase SQL Editor after the existing noticeboard migrations.

alter table public.notices
  alter column title drop not null,
  alter column body drop not null;

-- Keep normal notice validation, while allowing either field to be NULL for poll-only posts.
alter table public.notices drop constraint if exists notices_title_check;
alter table public.notices drop constraint if exists notices_body_check;

alter table public.notices
  add constraint notices_title_check
    check (title is null or char_length(trim(title)) between 1 and 120),
  add constraint notices_body_check
    check (body is null or char_length(trim(body)) between 1 and 2000);

-- Require each post to contain a normal notice or a valid poll.
alter table public.notices drop constraint if exists notices_notice_or_poll_check;
alter table public.notices
  add constraint notices_notice_or_poll_check
  check (
    (title is not null and body is not null)
    or
    (poll_question is not null and char_length(trim(poll_question)) between 1 and 160
      and poll_options is not null
      and jsonb_typeof(poll_options) = 'array'
      and jsonb_array_length(poll_options) between 2 and 4)
  );
