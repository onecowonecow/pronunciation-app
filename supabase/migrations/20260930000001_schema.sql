-- Cadence core schema. Free tier: 20 scored words/day (enforced in edge functions via daily_word_usage).

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) between 1 and 40),
  country text check (country ~ '^[A-Z]{2}$'),
  target_accent text not null default 'en-US',
  daily_goal int not null default 20 check (daily_goal between 1 and 500),
  is_public boolean not null default false,
  timezone text not null default 'UTC',
  created_at timestamptz not null default now()
);

create table public.attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  mode text not null check (mode in ('scripted','free')),
  reference_text text,
  word_count int not null default 0 check (word_count >= 0),
  overall numeric(5,2) not null check (overall between 0 and 100),
  accuracy numeric(5,2) check (accuracy between 0 and 100),
  fluency numeric(5,2) check (fluency between 0 and 100),
  completeness numeric(5,2) check (completeness between 0 and 100),
  prosody numeric(5,2) check (prosody between 0 and 100),
  result_json jsonb not null,
  created_at timestamptz not null default now()
);
create index attempts_user_created_idx on public.attempts (user_id, created_at desc);

create table public.word_bank (
  user_id uuid not null references auth.users(id) on delete cascade,
  word text not null check (word = lower(word)),
  ipa text,
  mastery int not null default 0 check (mastery between 0 and 5),
  last_score numeric(5,2) check (last_score between 0 and 100),
  next_review_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (user_id, word)
);

create table public.xp_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount int not null check (amount > 0),
  reason text not null,
  week date not null, -- Monday of the ISO week (UTC)
  created_at timestamptz not null default now()
);
create index xp_events_week_idx on public.xp_events (week, user_id);

create table public.entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  premium boolean not null default false,
  expires_at timestamptz,
  source text not null default 'revenuecat',
  updated_at timestamptz not null default now()
);

create table public.insights (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  period text not null check (period in ('7d','30d')),
  json jsonb not null,
  created_at timestamptz not null default now()
);
create index insights_user_idx on public.insights (user_id, period, created_at desc);

-- Free-tier metering: scored words per local day, written only by service role.
create table public.daily_word_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  words int not null default 0 check (words >= 0),
  primary key (user_id, day)
);

-- Auto-create profile + entitlement row on signup.
create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id) values (new.id);
  insert into public.entitlements (user_id) values (new.id);
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Atomically consume free-tier words; returns words actually allowed (0..requested).
create function public.consume_daily_words(p_user uuid, p_day date, p_requested int, p_cap int)
returns int language plpgsql security definer set search_path = public as $$
declare used int; allowed int;
begin
  insert into daily_word_usage (user_id, day, words) values (p_user, p_day, 0)
    on conflict do nothing;
  select words into used from daily_word_usage where user_id = p_user and day = p_day for update;
  allowed := greatest(0, least(p_requested, p_cap - used));
  update daily_word_usage set words = used + allowed where user_id = p_user and day = p_day;
  return allowed;
end $$;
revoke all on function public.consume_daily_words from public, anon, authenticated;

-- Weekly leaderboard: opt-in profiles only.
create view public.weekly_leaderboard with (security_invoker = false) as
select x.week, p.id as user_id, p.display_name, p.country, sum(x.amount)::int as xp,
       rank() over (partition by x.week order by sum(x.amount) desc) as rank
from public.xp_events x join public.profiles p on p.id = x.user_id
where p.is_public and p.display_name is not null
group by x.week, p.id, p.display_name, p.country;

-- Row level security
alter table public.profiles enable row level security;
alter table public.attempts enable row level security;
alter table public.word_bank enable row level security;
alter table public.xp_events enable row level security;
alter table public.entitlements enable row level security;
alter table public.insights enable row level security;
alter table public.daily_word_usage enable row level security;

create policy profiles_select on public.profiles for select using (auth.uid() = id);
create policy profiles_update on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);
create policy attempts_select on public.attempts for select using (auth.uid() = user_id);
create policy word_bank_all on public.word_bank for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy xp_select on public.xp_events for select using (auth.uid() = user_id);
create policy entitlements_select on public.entitlements for select using (auth.uid() = user_id);
create policy insights_select on public.insights for select using (auth.uid() = user_id);
create policy usage_select on public.daily_word_usage for select using (auth.uid() = user_id);
-- No insert/update/delete policies on attempts, xp_events, entitlements, insights, usage:
-- only the service role (edge functions) writes them, so scores/XP/premium can't be forged.

grant select on public.weekly_leaderboard to authenticated;
