-- Schedul-ER: securely expose only the total number of registered Supabase Auth users.
-- Run this once in Supabase SQL Editor for the Schedul-ER project.

create or replace function public.get_registered_user_count()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::bigint
  from auth.users;
$$;

-- The function returns only one aggregate number; it never exposes user records.
revoke all on function public.get_registered_user_count() from public;
grant execute on function public.get_registered_user_count() to anon, authenticated;

comment on function public.get_registered_user_count() is
  'Returns the total number of registered Supabase Auth accounts without exposing user data.';
