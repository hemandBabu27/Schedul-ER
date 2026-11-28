-- Schedul-ER noticeboard: authors may delete their own notices; class admins may delete any notice.
-- Run in the Supabase SQL Editor for project begwxweywclyqmbxseih.
--
-- IMPORTANT: PostgreSQL permissive policies are combined with OR. Review existing
-- DELETE policies on public.notices and remove any broad authenticated-user DELETE
-- policy, otherwise it could allow users to delete notices they do not own.

alter table public.notices enable row level security;

drop policy if exists "notices_delete_author_or_admin" on public.notices;

create policy "notices_delete_author_or_admin"
on public.notices
for delete
to authenticated
using (
  lower(coalesce(author_email, '')) = lower(coalesce(auth.jwt() ->> 'email', ''))
  or lower(coalesce(auth.jwt() ->> 'email', '')) in (
    'er27@gmail.com',
    'er28@gmail.com',
    'er29@gmail.com',
    'er30@gmail.com'
  )
);
