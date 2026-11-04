-- =====================================================================
-- Gym Pro — 03: Row Level Security policies (mirror of the live project)
-- =====================================================================

-- ---------- profiles ----------
create policy auth_admin_read_profiles_for_jwt on public.profiles
  as permissive for select to supabase_auth_admin using (true);

create policy profiles_select on public.profiles
  as permissive for select to authenticated
  using (is_staff() or id = (select auth.uid()));

create policy "Trainer and trainee can view each other via active assignment" on public.profiles
  as permissive for select to public
  using (
    (select auth.uid()) = id
    or exists (
      select 1 from trainer_trainees tt
      where tt.status = 'active'
        and (
          (tt.trainer_id = (select auth.uid()) and tt.trainee_id = profiles.id)
          or (tt.trainee_id = (select auth.uid()) and tt.trainer_id = profiles.id)
        )
    )
  );

create policy profiles_update_admin on public.profiles
  as permissive for update to authenticated
  using (is_admin()) with check (is_admin());

create policy profiles_update_self on public.profiles
  as permissive for update to public
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()) and (role)::text = app_role());

-- ---------- halls / access_periods / sessions / session_periods ----------
create policy halls_select_all on public.halls
  as permissive for select to authenticated using (true);
create policy halls_write_admin on public.halls
  as permissive for all to authenticated using (is_admin()) with check (is_admin());

create policy ap_select_all on public.access_periods
  as permissive for select to authenticated using (true);
create policy ap_write_admin on public.access_periods
  as permissive for all to authenticated using (is_admin()) with check (is_admin());

create policy sessions_select_all on public.sessions
  as permissive for select to authenticated using (true);
create policy sessions_write_admin on public.sessions
  as permissive for all to authenticated using (is_admin()) with check (is_admin());

create policy session_periods_select_all on public.session_periods
  as permissive for select to public using (true);
create policy session_periods_write_admin on public.session_periods
  as permissive for all to public using (is_admin());

-- ---------- bookings ----------
create policy bookings_select on public.bookings
  as permissive for select to authenticated
  using (is_staff() or trainee_id = (select auth.uid()));

create policy bookings_write on public.bookings
  as permissive for all to authenticated
  using (is_staff() or trainee_id = (select auth.uid()))
  with check (is_staff() or trainee_id = (select auth.uid()));

-- ---------- memberships ----------
create policy memberships_select on public.memberships
  as permissive for select to authenticated
  using (
    is_staff()
    or trainee_id = (select auth.uid())
    or exists (
      select 1 from trainer_trainees tt
      where tt.trainee_id = memberships.trainee_id
        and tt.trainer_id = (select auth.uid())
        and tt.status = 'active'
    )
  );
create policy memberships_write_reception on public.memberships
  as permissive for all to authenticated using (is_staff()) with check (is_staff());

-- ---------- attendance ----------
create policy attendance_select on public.attendance
  as permissive for select to authenticated
  using (
    is_staff()
    or trainee_id = (select auth.uid())
    or exists (
      select 1 from trainer_trainees tt
      where tt.trainee_id = attendance.trainee_id
        and tt.trainer_id = (select auth.uid())
        and tt.status = 'active'
    )
  );
create policy attendance_insert_reception on public.attendance
  as permissive for insert to authenticated with check (is_staff());

-- ---------- payment_costs / reports / archive ----------
create policy pc_all_staff on public.payment_costs
  as permissive for all to authenticated using (is_staff()) with check (is_staff());

create policy reports_all_admin on public.reports
  as permissive for all to authenticated using (is_admin()) with check (is_admin());

create policy archive_select_admin on public.deleted_users_archive
  as permissive for select to authenticated using (is_admin());

-- ---------- trainer_trainees ----------
create policy tt_select on public.trainer_trainees
  as permissive for select to authenticated
  using (is_staff() or trainer_id = (select auth.uid()) or trainee_id = (select auth.uid()));
create policy "Trainers can view their own assignments" on public.trainer_trainees
  as permissive for select to public
  using (trainer_id = (select auth.uid()) or trainee_id = (select auth.uid()));
create policy tt_write_reception on public.trainer_trainees
  as permissive for all to authenticated using (is_staff()) with check (is_staff());

-- ---------- private training ----------
create policy pts_select on public.private_training_sessions
  as permissive for select to authenticated
  using (
    is_staff()
    or trainer_trainee_id in (
      select id from trainer_trainees
      where trainer_id = (select auth.uid()) or trainee_id = (select auth.uid())
    )
  );
create policy pts_write_reception on public.private_training_sessions
  as permissive for all to authenticated using (is_staff()) with check (is_staff());

create policy pts_schedule_select on public.private_training_schedule
  as permissive for select to public
  using (
    is_staff()
    or exists (
      select 1 from trainer_trainees tt
      where tt.id = private_training_schedule.trainer_trainee_id
        and (tt.trainer_id = (select auth.uid()) or tt.trainee_id = (select auth.uid()))
    )
  );
create policy pts_schedule_write_reception on public.private_training_schedule
  as permissive for all to public using (is_staff());

-- ---------- training programs ----------
create policy tp_select on public.training_programs
  as permissive for select to authenticated
  using (is_staff() or trainer_id = (select auth.uid()) or trainee_id = (select auth.uid()));
create policy tp_write_trainer on public.training_programs
  as permissive for insert to authenticated
  with check (is_trainer() and trainer_id = (select auth.uid()));
create policy tp_update on public.training_programs
  as permissive for update to authenticated
  using (is_staff() or trainer_id = (select auth.uid()))
  with check (is_staff() or trainer_id = (select auth.uid()));
create policy tp_delete on public.training_programs
  as permissive for delete to authenticated
  using (is_staff() or trainer_id = (select auth.uid()));

create policy pd_select on public.program_days
  as permissive for select to authenticated
  using (
    is_staff()
    or program_id in (
      select id from training_programs
      where trainer_id = (select auth.uid()) or trainee_id = (select auth.uid())
    )
  );
create policy pd_write_trainer on public.program_days
  as permissive for all to authenticated
  using (is_staff() or program_id in (select id from training_programs where trainer_id = (select auth.uid())))
  with check (is_staff() or program_id in (select id from training_programs where trainer_id = (select auth.uid())));

create policy pe_select on public.program_exercises
  as permissive for select to authenticated
  using (
    is_staff()
    or day_id in (
      select pd.id from program_days pd
      join training_programs tp on tp.id = pd.program_id
      where tp.trainer_id = (select auth.uid()) or tp.trainee_id = (select auth.uid())
    )
  );
create policy pe_write_trainer on public.program_exercises
  as permissive for all to authenticated
  using (
    is_staff()
    or day_id in (
      select pd.id from program_days pd
      join training_programs tp on tp.id = pd.program_id
      where tp.trainer_id = (select auth.uid())
    )
  )
  with check (
    is_staff()
    or day_id in (
      select pd.id from program_days pd
      join training_programs tp on tp.id = pd.program_id
      where tp.trainer_id = (select auth.uid())
    )
  );

-- ---------- diets ----------
create policy diets_select on public.diets
  as permissive for select to authenticated
  using (is_staff() or trainer_id = (select auth.uid()) or trainee_id = (select auth.uid()));
create policy diets_write_trainer on public.diets
  as permissive for insert to authenticated
  with check (is_trainer() and trainer_id = (select auth.uid()));
create policy diets_update on public.diets
  as permissive for update to authenticated
  using (is_staff() or trainer_id = (select auth.uid()))
  with check (is_staff() or trainer_id = (select auth.uid()));
create policy diets_delete on public.diets
  as permissive for delete to authenticated
  using (is_staff() or trainer_id = (select auth.uid()));

create policy dd_select on public.diet_days
  as permissive for select to authenticated
  using (
    is_staff()
    or diet_id in (
      select id from diets
      where trainer_id = (select auth.uid()) or trainee_id = (select auth.uid())
    )
  );
create policy dd_write_trainer on public.diet_days
  as permissive for all to authenticated
  using (is_staff() or diet_id in (select id from diets where trainer_id = (select auth.uid())))
  with check (is_staff() or diet_id in (select id from diets where trainer_id = (select auth.uid())));

create policy dm_select on public.diet_meals
  as permissive for select to authenticated
  using (
    is_staff()
    or day_id in (
      select dd.id from diet_days dd
      join diets d on d.id = dd.diet_id
      where d.trainer_id = (select auth.uid()) or d.trainee_id = (select auth.uid())
    )
  );
create policy dm_write_trainer on public.diet_meals
  as permissive for all to authenticated
  using (
    is_staff()
    or day_id in (
      select dd.id from diet_days dd
      join diets d on d.id = dd.diet_id
      where d.trainer_id = (select auth.uid())
    )
  )
  with check (
    is_staff()
    or day_id in (
      select dd.id from diet_days dd
      join diets d on d.id = dd.diet_id
      where d.trainer_id = (select auth.uid())
    )
  );

-- ---------- notifications ----------
create policy notifications_select on public.notifications
  as permissive for select to authenticated
  using (user_id = (select auth.uid()));
create policy notifications_select_own on public.notifications
  as permissive for select to public
  using (user_id = auth.uid());
create policy notifications_update_own on public.notifications
  as permissive for update to public
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
create policy notifications_delete_own on public.notifications
  as permissive for delete to public
  using (user_id = auth.uid());
create policy notifications_insert on public.notifications
  as permissive for insert to public
  with check (
    user_id = auth.uid()
    or exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = any (array['admin'::user_role, 'reception'::user_role])
    )
  );
