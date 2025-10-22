begin;

drop table if exists public.images cascade;
drop table if exists public.problems cascade;

create extension if not exists "pgcrypto";

create table public.problems (
    id uuid primary key default gen_random_uuid(),
    owner_id uuid not null,
    title text not null,
    description text,
    difficulty text,
    category text,
  geometry_data text,
  solution text,
  scalar_constraints text,
  object_constraints text,
  scalar_proof text,
  object_proof text,
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
    thumbnail_id text,
    created_at timestamptz not null default timezone('utc', now()),
    updated_at timestamptz not null default timezone('utc', now())
);

create index idx_problems_owner on public.problems (owner_id);
create index idx_problems_status on public.problems (status);
create index idx_problems_created_at on public.problems (created_at desc);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

create or replace function public.problems_set_defaults()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    if new.owner_id is null then
      raise exception 'Authentication required to create problems.';
    end if;
  else
    new.owner_id := auth.uid();
  end if;
  new.status := 'draft';

  if new.created_at is null then
    new.created_at := timezone('utc', now());
  end if;

  new.updated_at := timezone('utc', now());

  return new;
end;
$$;

create trigger problems_set_defaults_trg
before insert on public.problems
for each row execute function public.problems_set_defaults();

create trigger problems_touch_updated_trg
before update on public.problems
for each row execute function public.touch_updated_at();

alter table public.problems enable row level security;

drop policy if exists "Problems select own or published" on public.problems;
drop policy if exists "Problems insert own" on public.problems;
drop policy if exists "Problems update own" on public.problems;
drop policy if exists "Problems delete own" on public.problems;

create policy "Problems select own or published"
on public.problems
for select
using (
  owner_id = auth.uid()
  or status = 'published'
);

create policy "Problems insert own"
on public.problems
for insert
with check (owner_id = auth.uid());

create policy "Problems update own"
on public.problems
for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "Problems delete own"
on public.problems
for delete
using (owner_id = auth.uid());

revoke all on table public.problems from authenticated;
revoke all on table public.problems from anon;

grant usage on schema public to authenticated;
grant usage on schema public to anon;

grant select on table public.problems to authenticated;
grant insert (title, description, difficulty, category, geometry_data, solution, scalar_constraints, object_constraints, scalar_proof, object_proof, thumbnail_id)
  on public.problems to authenticated;
grant update (title, description, difficulty, category, geometry_data, solution, scalar_constraints, object_constraints, scalar_proof, object_proof, status, thumbnail_id)
  on public.problems to authenticated;
grant delete on table public.problems to authenticated;

grant select on table public.problems to anon;

grant usage, select on all sequences in schema public to authenticated;

grant usage, select on all sequences in schema public to anon;

commit;
