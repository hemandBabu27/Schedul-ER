-- Schedul-ER: securely expose only the total number of registered Supabase Auth users.
-- Run this in the SAME Supabase project configured in index.html.

create or replace function public.get_registered_user_count()
returns bigint
language sql
stable
security definer
set search_path = ''
as $function$
  select count(*)::bigint
  from auth.users;
$function$;

revoke all on function public.get_registered_user_count() from public;
grant usage on schema public to anon, authenticated;
grant execute on function public.get_registered_user_count() to anon, authenticated;

comment on function public.get_registered_user_count() is
  'Returns only the total count of Supabase Auth accounts; it does not expose account records.';

-- Make the new/updated RPC visible to the Supabase Data API immediately.
notify pgrst, 'reload schema';
