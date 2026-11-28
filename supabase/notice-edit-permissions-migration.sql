-- Schedul-ER: allow class members to edit their own noticeboard posts and polls.
-- Class admins can continue editing any notice in their own class.

drop policy if exists "class members can edit own notices" on public.notices;
create policy "class members can edit own notices"
on public.notices for update to authenticated
using (
  class_id = public.schedul_er_class_for_email(auth.jwt() ->> 'email')
  and (
    public.schedul_er_is_class_admin(class_id)
    or lower(author_email) = lower(auth.jwt() ->> 'email')
  )
)
with check (
  class_id = public.schedul_er_class_for_email(auth.jwt() ->> 'email')
  and (
    public.schedul_er_is_class_admin(class_id)
    or lower(author_email) = lower(auth.jwt() ->> 'email')
  )
);

grant update on public.notices to authenticated;
notify pgrst, 'reload schema';
