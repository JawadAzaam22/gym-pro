-- Short-lived QR tokens. The raw token is returned only to the trainee
-- who requested it; the database stores a SHA-256 digest.

create table if not exists public.trainee_qr_tokens (
  id           uuid primary key default gen_random_uuid(),
  trainee_id   uuid not null references public.profiles(id) on delete cascade,
  token_hash   text not null unique,
  expires_at   timestamptz not null,
  created_at   timestamptz not null default now()
);

create index if not exists idx_trainee_qr_tokens_lookup
  on public.trainee_qr_tokens (token_hash, expires_at);

alter table public.trainee_qr_tokens enable row level security;

create or replace function public.issue_trainee_qr_token()
returns text
language plpgsql
security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare
  raw_token text;
begin
  if not exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'trainee'
      and is_active
  ) then
    raise exception 'Only an active trainee can issue a QR token';
  end if;

  delete from public.trainee_qr_tokens
  where trainee_id = auth.uid()
     or expires_at <= now();

  raw_token := encode(gen_random_bytes(24), 'hex');

  insert into public.trainee_qr_tokens (trainee_id, token_hash, expires_at)
  values (
    auth.uid(),
    encode(digest(raw_token, 'sha256'), 'hex'),
    now() + interval '90 seconds'
  );

  return 'gympro_qr_v1:' || raw_token;
end;
$$;

create or replace function public.resolve_trainee_qr_token(p_token text)
returns setof public.profiles
language plpgsql
security definer
set search_path to 'public', 'extensions', 'pg_temp'
as $$
declare
  raw_token text;
begin
  if not public.is_staff() then
    raise exception 'Only active staff can resolve a QR token';
  end if;

  if p_token is null or p_token not like 'gympro_qr_v1:%' then
    return;
  end if;

  raw_token := substring(p_token from char_length('gympro_qr_v1:') + 1);

  return query
  select p.*
  from public.trainee_qr_tokens t
  join public.profiles p on p.id = t.trainee_id
  where t.token_hash = encode(digest(raw_token, 'sha256'), 'hex')
    and t.expires_at > now()
    and p.role = 'trainee'
    and p.is_active;
end;
$$;

revoke all on function public.issue_trainee_qr_token() from public;
revoke all on function public.resolve_trainee_qr_token(text) from public;
grant execute on function public.issue_trainee_qr_token() to authenticated;
grant execute on function public.resolve_trainee_qr_token(text) to authenticated;
