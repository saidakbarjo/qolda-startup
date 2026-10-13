-- =====================================================================
-- Qoʻlda — Supabase schema
-- Run once: Supabase Dashboard → SQL Editor → New query → paste → Run
-- =====================================================================

-- 1. Tables -------------------------------------------------------------

create table if not exists public.leads (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  role        text not null check (role in ('client','worker')),
  name        text not null check (char_length(name) between 2 and 80),
  phone       text not null check (phone ~ '^\+998 \d{2} \d{3} \d{2} \d{2}$'),
  district    text not null check (char_length(district) between 2 and 40),
  skills      text[] not null default '{}'
              check (skills <@ array['furniture','repair','queue','garden','moving','cleaning']::text[]),
  lang        text not null default 'uz' check (lang in ('uz','ru')),
  status      text not null default 'new' check (status in ('new','contacted','verified','rejected')),
  note        text not null default '' check (char_length(note) <= 300)
);
create index if not exists leads_created_at_idx on public.leads (created_at desc);

create table if not exists public.messages (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  name        text not null check (char_length(name) between 2 and 80),
  contact     text not null check (char_length(contact) between 3 and 80),
  text        text not null check (char_length(text) between 2 and 2000),
  read        boolean not null default false
);
create index if not exists messages_created_at_idx on public.messages (created_at desc);

create table if not exists public.settings (
  id          int primary key default 1 check (id = 1),
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);
insert into public.settings (id, data) values (1, '{}'::jsonb) on conflict (id) do nothing;

create table if not exists public.admins (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now()
);

-- 2. Helper: is the current user an admin? -----------------------------

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- 3. Row Level Security -------------------------------------------------

alter table public.leads    enable row level security;
alter table public.messages enable row level security;
alter table public.settings enable row level security;
alter table public.admins   enable row level security;

-- leads: anyone may submit a NEW lead; only admins read / change / delete
drop policy if exists "leads insert public" on public.leads;
create policy "leads insert public" on public.leads
  for insert to anon, authenticated
  with check (status = 'new' and note = '');

drop policy if exists "leads admin select" on public.leads;
create policy "leads admin select" on public.leads
  for select to authenticated using (public.is_admin());

drop policy if exists "leads admin update" on public.leads;
create policy "leads admin update" on public.leads
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "leads admin delete" on public.leads;
create policy "leads admin delete" on public.leads
  for delete to authenticated using (public.is_admin());

-- messages: anyone may send; only admins read / change / delete
drop policy if exists "messages insert public" on public.messages;
create policy "messages insert public" on public.messages
  for insert to anon, authenticated
  with check (read = false);

drop policy if exists "messages admin select" on public.messages;
create policy "messages admin select" on public.messages
  for select to authenticated using (public.is_admin());

drop policy if exists "messages admin update" on public.messages;
create policy "messages admin update" on public.messages
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "messages admin delete" on public.messages;
create policy "messages admin delete" on public.messages
  for delete to authenticated using (public.is_admin());

-- settings: everyone reads (banner, phone, goal); only admins write
drop policy if exists "settings read public" on public.settings;
create policy "settings read public" on public.settings
  for select to anon, authenticated using (true);

drop policy if exists "settings admin insert" on public.settings;
create policy "settings admin insert" on public.settings
  for insert to authenticated with check (public.is_admin());

drop policy if exists "settings admin update" on public.settings;
create policy "settings admin update" on public.settings
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- admins: a signed-in user can only see whether THEY are an admin
drop policy if exists "admins self read" on public.admins;
create policy "admins self read" on public.admins
  for select to authenticated using (user_id = auth.uid());

-- 4. Make yourself an admin --------------------------------------------
-- First create a user: Authentication → Users → Add user (email + password).
-- Then run (replace the email):
--
--   insert into public.admins (user_id)
--   select id from auth.users where email = 'you@example.com';
