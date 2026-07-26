-- ============================================================
-- 0001_enums.sql
-- ============================================================
-- Enums for the Hajj Operations domain
create type account_status_enum as enum ('incomplete', 'pending', 'approved', 'rejected');
create type gender_enum as enum ('male', 'female');
create type mission_type_enum as enum ('administrative', 'religious', 'medical');
create type participation_status_enum as enum ('active', 'withdrawn');


-- ============================================================
-- 0002_job_titles.sql
-- ============================================================
-- Predefined, admin-managed list of job titles (الوصف الوظيفي)
create table job_titles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create unique index job_titles_name_active_key on job_titles (name) where is_active;


-- ============================================================
-- 0003_profiles.sql
-- ============================================================
-- Employee profile, one row per auth.users, created automatically on signup
create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  first_name text,
  surname text,                 -- الكنية
  father_name text,
  photo_url text,
  job_title_id uuid references job_titles (id) on delete restrict,
  gender gender_enum,
  date_of_birth date,
  mission_type mission_type_enum,
  phone_sy text,                -- Syrian phone, required at profile completion
  phone_sa text,                -- Saudi phone, optional
  passport_image_url text,
  visa_image_url text,
  nusuk_card_image_url text,
  account_status account_status_enum not null default 'incomplete',
  rejection_reason text,
  is_admin boolean not null default false,
  is_external boolean not null default false,
  external_organization text,
  external_title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keep updated_at fresh
create function set_updated_at() returns trigger
  language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on profiles
  for each row execute function set_updated_at();

-- Auto-create an empty profile row when a new auth user signs up
create function handle_new_user() returns trigger
  language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, account_status)
  values (new.id, 'incomplete')
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Guardrail: non-admins may not touch privileged columns.
-- RLS is row-level and cannot protect individual columns, so this is the real boundary.
create function profiles_guard_privileged_columns() returns trigger
  language plpgsql security definer set search_path = public as $$
declare
  caller_is_admin boolean;
begin
  select p.is_admin and p.account_status = 'approved'
    into caller_is_admin
  from public.profiles p
  where p.id = auth.uid();

  caller_is_admin := coalesce(caller_is_admin, false);

  if caller_is_admin then
    return new;
  end if;

  -- Privileged columns can never be changed by a non-admin...
  new.is_admin := old.is_admin;
  new.is_external := old.is_external;
  new.external_organization := old.external_organization;
  new.external_title := old.external_title;
  new.rejection_reason := old.rejection_reason;

  -- ...except a user may submit their own profile for review:
  -- incomplete/rejected -> pending only. Any other status transition is reverted.
  if new.account_status is distinct from old.account_status then
    if old.account_status in ('incomplete', 'rejected')
       and new.account_status = 'pending' then
      -- allowed
    else
      new.account_status := old.account_status;
    end if;
  end if;

  return new;
end;
$$;

create trigger profiles_guard_before_update
  before update on profiles
  for each row execute function profiles_guard_privileged_columns();


-- ============================================================
-- 0004_permissions.sql
-- ============================================================
-- Permission catalog (flexible RBAC — permissions granted directly, no role table)
create table permissions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  description text
);

create table user_permissions (
  user_id uuid not null references profiles (id) on delete cascade,
  permission_id uuid not null references permissions (id) on delete cascade,
  granted_by uuid references profiles (id),
  granted_at timestamptz not null default now(),
  primary key (user_id, permission_id)
);

insert into permissions (code, description) values
  ('view_employees',            'View the employee directory'),
  ('manage_employees',          'Create / edit employee records'),
  ('approve_accounts',          'Approve or reject pending accounts'),
  ('manage_job_titles',         'Manage the job-title list'),
  ('manage_permissions',        'Grant or revoke permissions'),
  ('manage_seasons',            'Create and manage seasons'),
  ('manage_season_participants','Manage who participates in a season'),
  ('view_season_participants',  'View season participant rosters'),
  ('view_documents',            'View sensitive documents (passport/visa/nusuk)'),
  ('view_reports',              'View reports');


-- ============================================================
-- 0005_seasons.sql
-- ============================================================
-- Hajj seasons; exactly one may be "current" at a time
create table seasons (
  id uuid primary key default gen_random_uuid(),
  hijri_year int unique not null,
  gregorian_label text,
  is_current boolean not null default false,
  -- Set when an admin manually picks this season: the Hijri year that was
  -- running at the time. Holds off the yearly auto-advance until the calendar
  -- passes it. Null means "auto-managed".
  pinned_for_hijri_year int,
  start_date date,
  end_date date,
  created_at timestamptz not null default now()
);

-- Enforce single current season at the storage level
create unique index one_current_season on seasons (is_current) where is_current;

create table season_participants (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references seasons (id) on delete cascade,
  profile_id uuid not null references profiles (id) on delete cascade,
  status participation_status_enum not null default 'active',
  joined_at timestamptz not null default now(),
  unique (season_id, profile_id)
);

create index idx_season_participants_profile on season_participants (profile_id);


-- ============================================================
-- 0006_functions.sql
-- ============================================================
-- Authorization helpers. SECURITY DEFINER + explicit search_path to avoid hijacking.

create function is_admin() returns boolean
  language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
      and is_admin
      and account_status = 'approved'
  );
$$;

create function has_permission(p_code text) returns boolean
  language sql stable security definer set search_path = public as $$
  select is_admin() or exists (
    select 1
    from user_permissions up
    join permissions p on p.id = up.permission_id
    where up.user_id = auth.uid()
      and p.code = p_code
  );
$$;

-- The caller's own permission codes (so the UI can gate without reading the whole catalog)
create function my_permissions() returns setof text
  language sql stable security definer set search_path = public as $$
  select p.code
  from user_permissions up
  join permissions p on p.id = up.permission_id
  where up.user_id = auth.uid();
$$;

-- Set the current season atomically (admin only), recording it as a manual pin.
-- p_pinned_for_hijri_year is the caller's current Hijri year; null pins forever.
create function set_current_season(
  p_season_id uuid,
  p_pinned_for_hijri_year int default null
) returns void
  language plpgsql security definer set search_path = public as $$
begin
  if not is_admin() then
    raise exception 'not authorized';
  end if;

  if not exists (select 1 from seasons where id = p_season_id) then
    raise exception 'season not found';
  end if;

  update seasons
     set is_current = false,
         pinned_for_hijri_year = null
   where is_current or pinned_for_hijri_year is not null;

  update seasons
     set is_current = true,
         pinned_for_hijri_year = p_pinned_for_hijri_year
   where id = p_season_id;
end;
$$;

-- Ensure a season row exists for the given Hijri year, and make it current only
-- when that is newer than the season in place (guards against a wrong device
-- clock) and the season in place was not manually pinned for this Hijri year.
create function ensure_current_season(p_hijri_year int, p_label text) returns uuid
  language plpgsql security definer set search_path = public as $$
declare
  v_season_id uuid;
  v_current_year int;
  v_pinned_for int;
begin
  if not is_admin() then
    raise exception 'not authorized';
  end if;

  select id into v_season_id from seasons where hijri_year = p_hijri_year;

  if v_season_id is null then
    insert into seasons (hijri_year, gregorian_label)
    values (p_hijri_year, p_label)
    returning id into v_season_id;
  end if;

  select hijri_year, pinned_for_hijri_year
    into v_current_year, v_pinned_for
    from seasons where is_current;

  -- A pin holds until the Hijri year advances past the year it was made in.
  if v_current_year is not null
     and v_pinned_for is not null
     and p_hijri_year <= v_pinned_for then
    return v_season_id;
  end if;

  if v_current_year is null or p_hijri_year > v_current_year then
    update seasons
       set is_current = false,
           pinned_for_hijri_year = null
     where is_current;
    update seasons set is_current = true where id = v_season_id;
  end if;

  return v_season_id;
end;
$$;


-- ============================================================
-- 0007_rls.sql
-- ============================================================
-- Row Level Security

alter table profiles          enable row level security;
alter table job_titles        enable row level security;
alter table permissions       enable row level security;
alter table user_permissions  enable row level security;
alter table seasons           enable row level security;
alter table season_participants enable row level security;

-- ---- profiles ----
create policy profiles_select on profiles for select
  using (id = auth.uid() or is_admin() or has_permission('view_employees'));

create policy profiles_insert_self on profiles for insert
  with check (id = auth.uid());

create policy profiles_update_self on profiles for update
  using (id = auth.uid() or is_admin())
  with check (id = auth.uid() or is_admin());

-- ---- job_titles ----
-- Readable by any authenticated user (needed during profile completion, pre-approval)
create policy job_titles_select on job_titles for select
  to authenticated using (true);

create policy job_titles_write on job_titles for all
  using (is_admin()) with check (is_admin());

-- ---- permissions (catalog) ----
create policy permissions_admin_only on permissions for all
  using (is_admin()) with check (is_admin());

-- ---- user_permissions ----
create policy user_permissions_select on user_permissions for select
  using (user_id = auth.uid() or is_admin());

create policy user_permissions_write on user_permissions for all
  using (is_admin()) with check (is_admin());

-- ---- seasons ----
create policy seasons_select on seasons for select
  using (is_admin() or exists (
    select 1 from profiles
    where id = auth.uid() and account_status = 'approved'
  ));

create policy seasons_write on seasons for all
  using (is_admin()) with check (is_admin());

-- ---- season_participants ----
create policy season_participants_select on season_participants for select
  using (
    profile_id = auth.uid()
    or is_admin()
    or has_permission('view_season_participants')
  );

create policy season_participants_write on season_participants for all
  using (is_admin()) with check (is_admin());


-- ============================================================
-- 0008_storage.sql
-- ============================================================
-- Storage buckets: avatars (profile photos) and documents (sensitive PII, private)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

-- Path convention: {uid}/<file>. The first path segment is the owner's user id.

-- ---- avatars ----
create policy avatars_read on storage.objects for select
  to authenticated using (bucket_id = 'avatars');

create policy avatars_write_own on storage.objects for insert
  to authenticated with check (
    bucket_id = 'avatars'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );

create policy avatars_update_own on storage.objects for update
  to authenticated using (
    bucket_id = 'avatars'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );

create policy avatars_delete_own on storage.objects for delete
  to authenticated using (
    bucket_id = 'avatars'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );

-- ---- documents (private) ----
create policy documents_read on storage.objects for select
  to authenticated using (
    bucket_id = 'documents'
    and (
      public.is_admin()
      or public.has_permission('view_documents')
      or (storage.foldername(name))[1] = auth.uid()::text
    )
  );

create policy documents_write_own on storage.objects for insert
  to authenticated with check (
    bucket_id = 'documents'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );

create policy documents_update_own on storage.objects for update
  to authenticated using (
    bucket_id = 'documents'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );

create policy documents_delete_own on storage.objects for delete
  to authenticated using (
    bucket_id = 'documents'
    and (public.is_admin() or (storage.foldername(name))[1] = auth.uid()::text)
  );


-- ============================================================
-- 0009_views.sql
-- ============================================================
-- Permanent staff = internal, approved employees. Listings/reports use this
-- so the "exclude externals and unapproved" rule lives in one place.
-- security_invoker so the caller's RLS on profiles still applies.
create view permanent_employees
  with (security_invoker = true) as
  select *
  from profiles
  where is_external = false
    and account_status = 'approved';


