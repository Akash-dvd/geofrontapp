begin;

create schema if not exists auth;

-- Ensure uuid-ossp extension for UUID defaults if not already present.
create extension if not exists "uuid-ossp";

create table if not exists public.posts (
    id uuid primary key default uuid_generate_v4(),
    author_id uuid not null,
    visibility text not null default 'private', -- acceptable values: private|public
    title text not null,
    body text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.posts enable row level security;

drop trigger if exists set_post_owner on public.posts;
drop function if exists public.set_post_owner();

create function public.set_post_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.author_id is null then
    new.author_id := auth.uid();
  end if;
  new.updated_at := now();
  return new;
end;
$$;

create trigger set_post_owner
before insert on public.posts
for each row execute function public.set_post_owner();

drop policy if exists "Users read own or public posts" on public.posts;
drop policy if exists "Users insert own posts" on public.posts;
drop policy if exists "Users update own posts" on public.posts;
drop policy if exists "Users delete own posts" on public.posts;

create policy "Users read own or public posts"
on public.posts
for select
using (
  auth.uid() = author_id
  or visibility = 'public'
);

create policy "Users insert own posts"
on public.posts
for insert
with check (auth.uid() = author_id);

create policy "Users update own posts"
on public.posts
for update
using (auth.uid() = author_id)
with check (auth.uid() = author_id);

create policy "Users delete own posts"
on public.posts
for delete
using (auth.uid() = author_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.posts to authenticated;
grant usage, select on all sequences in schema public to authenticated;

commit;
