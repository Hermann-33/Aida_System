-- TASK-OPS-002 / Phase 1 — trusted sales-point and terminal authority.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/.
--
-- Goals:
--   branch -> sales point -> terminal -> employee -> POS order attribution
--   one-time terminal enrolment with HttpOnly-cookie credential at the BFF
--   no client-trusted branch/sales-point/terminal IDs for POS placement
--
-- Non-goals: shifts/cash, inventory, payment-device settlement, printer/KDS health.

create table public.sales_points (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete restrict,
  code text not null unique,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sales_points_code_check
    check (code ~ '^[A-Z0-9][A-Z0-9-]{1,23}$'),
  constraint sales_points_name_check
    check (char_length(btrim(name)) between 1 and 120)
);

create unique index sales_points_id_branch_unique
  on public.sales_points (id, branch_id);
create index sales_points_branch_active_idx
  on public.sales_points (branch_id, is_active, code);

create table public.terminals (
  id uuid primary key default gen_random_uuid(),
  sales_point_id uuid not null references public.sales_points(id) on delete restrict,
  code text not null unique,
  name text not null,
  status text not null default 'pending',
  enrolled_at timestamptz,
  revoked_at timestamptz,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint terminals_code_check
    check (code ~ '^[A-Z0-9][A-Z0-9-]{1,31}$'),
  constraint terminals_name_check
    check (char_length(btrim(name)) between 1 and 120),
  constraint terminals_status_check
    check (status in ('pending', 'active', 'revoked')),
  constraint terminals_status_shape_check check (
    (status = 'pending' and revoked_at is null)
    or (status = 'active' and enrolled_at is not null and revoked_at is null)
    or (status = 'revoked' and revoked_at is not null)
  )
);

create unique index terminals_id_sales_point_unique
  on public.terminals (id, sales_point_id);
create index terminals_sales_point_status_idx
  on public.terminals (sales_point_id, status, code);

create table private.terminal_enrolment_codes (
  id uuid primary key default gen_random_uuid(),
  terminal_id uuid not null references public.terminals(id) on delete cascade,
  code_hash text not null,
  issued_by uuid not null references auth.users(id) on delete restrict,
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null,
  consumed_at timestamptz,
  constraint terminal_enrolment_codes_expiry_check
    check (expires_at > issued_at)
);

create index terminal_enrolment_codes_live_idx
  on private.terminal_enrolment_codes (terminal_id, expires_at desc)
  where consumed_at is null;

create table private.terminal_credentials (
  terminal_id uuid primary key references public.terminals(id) on delete cascade,
  secret_hash text not null unique,
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null,
  last_seen_at timestamptz,
  revoked_at timestamptz,
  constraint terminal_credentials_expiry_check
    check (expires_at > issued_at)
);

alter table public.sales_points enable row level security;
alter table public.sales_points force row level security;
alter table public.terminals enable row level security;
alter table public.terminals force row level security;
alter table private.terminal_enrolment_codes enable row level security;
alter table private.terminal_enrolment_codes force row level security;
alter table private.terminal_credentials enable row level security;
alter table private.terminal_credentials force row level security;

revoke all on table public.sales_points from public, anon, authenticated;
revoke all on table public.terminals from public, anon, authenticated;
revoke all on table private.terminal_enrolment_codes from public, anon, authenticated;
revoke all on table private.terminal_credentials from public, anon, authenticated;

insert into public.sales_points (branch_id, code, name, is_active)
select b.id, 'SP-MAIN', 'Main Counter', true
from public.branches b
where b.is_default and b.is_active
on conflict (code) do nothing;

insert into public.terminals (sales_point_id, code, name, status)
select sp.id, 'POS-MAIN-01', 'Main Counter POS 1', 'pending'
from public.sales_points sp
where sp.code = 'SP-MAIN'
on conflict (code) do nothing;

create or replace function private.terminal_context_impl(
  p_credential text,
  p_touch boolean,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_terminal_id uuid;
  v_terminal_code text;
  v_sales_point_id uuid;
  v_sales_point_code text;
  v_sales_point_name text;
  v_branch_id uuid;
  v_branch_code text;
  v_branch_name text;
  v_timezone text;
  v_credential_expires_at timestamptz;
  v_now timestamptz := now();
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'employee authentication required for terminal access'
      using errcode = '42501';
  end if;

  if p_credential is null or char_length(p_credential) < 40 then
    raise exception 'terminal credential is invalid' using errcode = '42501';
  end if;

  select
    t.id,
    t.code,
    sp.id,
    sp.code,
    sp.name,
    b.id,
    b.code,
    b.name,
    b.timezone,
    c.expires_at
  into
    v_terminal_id,
    v_terminal_code,
    v_sales_point_id,
    v_sales_point_code,
    v_sales_point_name,
    v_branch_id,
    v_branch_code,
    v_branch_name,
    v_timezone,
    v_credential_expires_at
  from private.terminal_credentials c
  join public.terminals t on t.id = c.terminal_id
  join public.sales_points sp on sp.id = t.sales_point_id
  join public.branches b on b.id = sp.branch_id
  where c.secret_hash = encode(extensions.digest(p_credential, 'sha256'), 'hex')
    and c.revoked_at is null
    and c.expires_at > v_now
    and t.status = 'active'
    and t.revoked_at is null
    and sp.is_active
    and b.is_active
  limit 1;

  if v_terminal_id is null then
    raise exception 'terminal credential is invalid or expired'
      using errcode = '42501';
  end if;

  if p_touch then
    update private.terminal_credentials
    set last_seen_at = v_now
    where terminal_id = v_terminal_id;

    update public.terminals
    set last_seen_at = v_now
    where id = v_terminal_id;
  end if;

  return jsonb_build_object(
    'terminalId', v_terminal_id,
    'terminalCode', v_terminal_code,
    'salesPointId', v_sales_point_id,
    'salesPointCode', v_sales_point_code,
    'salesPointName', v_sales_point_name,
    'branchId', v_branch_id,
    'branchCode', v_branch_code,
    'branchName', v_branch_name,
    'timezone', v_timezone,
    'credentialExpiresAt', v_credential_expires_at
  );
end;
$$;

create or replace function private.enrol_terminal_impl(
  p_code text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code_id uuid;
  v_terminal_id uuid;
  v_terminal_code text;
  v_sales_point_id uuid;
  v_sales_point_code text;
  v_sales_point_name text;
  v_branch_id uuid;
  v_branch_code text;
  v_branch_name text;
  v_timezone text;
  v_secret text;
  v_secret_hash text;
  v_expires_at timestamptz := now() + interval '180 days';
  v_now timestamptz := now();
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'employee authentication required for terminal enrolment'
      using errcode = '42501';
  end if;

  p_code := upper(btrim(coalesce(p_code, '')));
  if char_length(p_code) < 8 or char_length(p_code) > 64 then
    raise exception 'enrolment code is invalid or expired'
      using errcode = '22023';
  end if;

  select c.id, c.terminal_id
  into v_code_id, v_terminal_id
  from private.terminal_enrolment_codes c
  where c.consumed_at is null
    and c.expires_at > v_now
    and extensions.crypt(p_code, c.code_hash) = c.code_hash
  order by c.issued_at desc
  limit 1
  for update of c;

  if v_code_id is null then
    raise exception 'enrolment code is invalid or expired'
      using errcode = '22023';
  end if;

  select
    t.code,
    sp.id,
    sp.code,
    sp.name,
    b.id,
    b.code,
    b.name,
    b.timezone
  into
    v_terminal_code,
    v_sales_point_id,
    v_sales_point_code,
    v_sales_point_name,
    v_branch_id,
    v_branch_code,
    v_branch_name,
    v_timezone
  from public.terminals t
  join public.sales_points sp on sp.id = t.sales_point_id
  join public.branches b on b.id = sp.branch_id
  where t.id = v_terminal_id
    and t.status in ('pending', 'active')
    and sp.is_active
    and b.is_active;

  if v_terminal_code is null then
    raise exception 'terminal is unavailable for enrolment'
      using errcode = '42501';
  end if;

  if not (select private.can_operate_branch(v_branch_id)) then
    raise exception 'employee is not authorized for the terminal branch'
      using errcode = '42501';
  end if;

  v_secret := encode(extensions.gen_random_bytes(32), 'hex');
  v_secret_hash := encode(extensions.digest(v_secret, 'sha256'), 'hex');

  insert into private.terminal_credentials (
    terminal_id,
    secret_hash,
    issued_at,
    expires_at,
    last_seen_at,
    revoked_at
  ) values (
    v_terminal_id,
    v_secret_hash,
    v_now,
    v_expires_at,
    v_now,
    null
  )
  on conflict (terminal_id) do update
  set secret_hash = excluded.secret_hash,
      issued_at = excluded.issued_at,
      expires_at = excluded.expires_at,
      last_seen_at = excluded.last_seen_at,
      revoked_at = null;

  update private.terminal_enrolment_codes
  set consumed_at = v_now
  where id = v_code_id;

  update public.terminals
  set status = 'active',
      enrolled_at = v_now,
      revoked_at = null,
      last_seen_at = v_now,
      updated_at = v_now
  where id = v_terminal_id;

  return jsonb_build_object(
    'credential', v_secret,
    'credentialExpiresAt', v_expires_at,
    'location', jsonb_build_object(
      'terminalId', v_terminal_id,
      'terminalCode', v_terminal_code,
      'salesPointId', v_sales_point_id,
      'salesPointCode', v_sales_point_code,
      'salesPointName', v_sales_point_name,
      'branchId', v_branch_id,
      'branchCode', v_branch_code,
      'branchName', v_branch_name,
      'timezone', v_timezone
    )
  );
end;
$$;

create or replace function private.issue_terminal_enrolment_code_impl(
  p_terminal_id uuid,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_terminal public.terminals%rowtype;
  v_code text;
  v_expires_at timestamptz := now() + interval '15 minutes';
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;

  select t.*
  into v_terminal
  from public.terminals t
  join public.sales_points sp on sp.id = t.sales_point_id
  join public.branches b on b.id = sp.branch_id
  where t.id = p_terminal_id
    and sp.is_active
    and b.is_active
  for update of t;

  if not found then
    raise exception 'terminal not found or location is inactive'
      using errcode = 'P0002';
  end if;

  if v_terminal.status = 'revoked' then
    update public.terminals
    set status = 'pending',
        enrolled_at = null,
        revoked_at = null,
        updated_at = now()
    where id = p_terminal_id;
  end if;

  update private.terminal_enrolment_codes
  set consumed_at = now()
  where terminal_id = p_terminal_id
    and consumed_at is null;

  v_code := 'AIDA-' || upper(encode(extensions.gen_random_bytes(6), 'hex'));

  insert into private.terminal_enrolment_codes (
    terminal_id,
    code_hash,
    issued_by,
    expires_at
  ) values (
    p_terminal_id,
    extensions.crypt(v_code, extensions.gen_salt('bf', 10)),
    p_actor_user_id,
    v_expires_at
  );

  return jsonb_build_object(
    'terminalId', p_terminal_id,
    'code', v_code,
    'expiresAt', v_expires_at
  );
end;
$$;

create or replace function private.save_sales_point_impl(
  p_payload jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_existing public.sales_points%rowtype;
  v_branch_id uuid;
  v_code text;
  v_name text;
  v_is_active boolean;
  v_saved public.sales_points%rowtype;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'sales point payload must be a JSON object'
      using errcode = '22023';
  end if;

  begin
    v_id := nullif(p_payload ->> 'id', '')::uuid;
  exception when invalid_text_representation then
    raise exception 'sales point id must be a valid UUID'
      using errcode = '22023';
  end;

  if v_id is not null then
    select * into v_existing
    from public.sales_points
    where id = v_id
    for update;
    if not found then
      raise exception 'sales point not found' using errcode = 'P0002';
    end if;
  end if;

  begin
    v_branch_id := coalesce(
      nullif(p_payload ->> 'branchId', '')::uuid,
      v_existing.branch_id
    );
  exception when invalid_text_representation then
    raise exception 'branchId must be a valid UUID' using errcode = '22023';
  end;

  v_code := upper(btrim(coalesce(p_payload ->> 'code', v_existing.code)));
  v_name := btrim(coalesce(p_payload ->> 'name', v_existing.name));
  v_is_active := coalesce(
    (p_payload ->> 'isActive')::boolean,
    v_existing.is_active,
    true
  );

  if v_branch_id is null or not exists (
    select 1 from public.branches b
    where b.id = v_branch_id
  ) then
    raise exception 'branch not found' using errcode = '22023';
  end if;

  if v_is_active and not exists (
    select 1 from public.branches b
    where b.id = v_branch_id and b.is_active
  ) then
    raise exception 'active sales point requires an active branch'
      using errcode = '22023';
  end if;

  if v_code is null or v_code !~ '^[A-Z0-9][A-Z0-9-]{1,23}$' then
    raise exception 'sales point code is invalid' using errcode = '22023';
  end if;
  if v_name is null or char_length(v_name) not between 1 and 120 then
    raise exception 'sales point name is invalid' using errcode = '22023';
  end if;

  if v_id is null then
    insert into public.sales_points (
      branch_id, code, name, is_active
    ) values (
      v_branch_id, v_code, v_name, v_is_active
    )
    returning * into v_saved;
  else
    update public.sales_points
    set branch_id = v_branch_id,
        code = v_code,
        name = v_name,
        is_active = v_is_active,
        updated_at = now()
    where id = v_id
    returning * into v_saved;
  end if;

  return jsonb_build_object(
    'id', v_saved.id,
    'branchId', v_saved.branch_id,
    'code', v_saved.code,
    'name', v_saved.name,
    'isActive', v_saved.is_active,
    'createdAt', v_saved.created_at,
    'updatedAt', v_saved.updated_at
  );
end;
$$;

create or replace function private.save_terminal_impl(
  p_payload jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_existing public.terminals%rowtype;
  v_sales_point_id uuid;
  v_code text;
  v_name text;
  v_saved public.terminals%rowtype;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'terminal payload must be a JSON object'
      using errcode = '22023';
  end if;

  begin
    v_id := nullif(p_payload ->> 'id', '')::uuid;
  exception when invalid_text_representation then
    raise exception 'terminal id must be a valid UUID' using errcode = '22023';
  end;

  if v_id is not null then
    select * into v_existing
    from public.terminals
    where id = v_id
    for update;
    if not found then
      raise exception 'terminal not found' using errcode = 'P0002';
    end if;
  end if;

  begin
    v_sales_point_id := coalesce(
      nullif(p_payload ->> 'salesPointId', '')::uuid,
      v_existing.sales_point_id
    );
  exception when invalid_text_representation then
    raise exception 'salesPointId must be a valid UUID' using errcode = '22023';
  end;

  v_code := upper(btrim(coalesce(p_payload ->> 'code', v_existing.code)));
  v_name := btrim(coalesce(p_payload ->> 'name', v_existing.name));

  if v_sales_point_id is null or not exists (
    select 1
    from public.sales_points sp
    join public.branches b on b.id = sp.branch_id
    where sp.id = v_sales_point_id
      and sp.is_active
      and b.is_active
  ) then
    raise exception 'active sales point is required' using errcode = '22023';
  end if;

  if v_code is null or v_code !~ '^[A-Z0-9][A-Z0-9-]{1,31}$' then
    raise exception 'terminal code is invalid' using errcode = '22023';
  end if;
  if v_name is null or char_length(v_name) not between 1 and 120 then
    raise exception 'terminal name is invalid' using errcode = '22023';
  end if;

  if v_id is not null
     and v_existing.status = 'active'
     and (
       v_existing.sales_point_id is distinct from v_sales_point_id
       or v_existing.code is distinct from v_code
     ) then
    raise exception 'revoke the terminal before changing its code or sales point'
      using errcode = '22023';
  end if;

  if v_id is null then
    insert into public.terminals (
      sales_point_id, code, name, status
    ) values (
      v_sales_point_id, v_code, v_name, 'pending'
    )
    returning * into v_saved;
  else
    update public.terminals
    set sales_point_id = v_sales_point_id,
        code = v_code,
        name = v_name,
        updated_at = now()
    where id = v_id
    returning * into v_saved;
  end if;

  return jsonb_build_object(
    'id', v_saved.id,
    'salesPointId', v_saved.sales_point_id,
    'code', v_saved.code,
    'name', v_saved.name,
    'status', v_saved.status,
    'enrolledAt', v_saved.enrolled_at,
    'revokedAt', v_saved.revoked_at,
    'lastSeenAt', v_saved.last_seen_at,
    'createdAt', v_saved.created_at,
    'updatedAt', v_saved.updated_at
  );
end;
$$;

create or replace function private.revoke_terminal_impl(
  p_terminal_id uuid,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_saved public.terminals%rowtype;
  v_now timestamptz := now();
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;

  update public.terminals
  set status = 'revoked',
      revoked_at = v_now,
      updated_at = v_now
  where id = p_terminal_id
  returning * into v_saved;

  if not found then
    raise exception 'terminal not found' using errcode = 'P0002';
  end if;

  update private.terminal_credentials
  set revoked_at = v_now
  where terminal_id = p_terminal_id
    and revoked_at is null;

  update private.terminal_enrolment_codes
  set consumed_at = v_now
  where terminal_id = p_terminal_id
    and consumed_at is null;

  return jsonb_build_object(
    'id', v_saved.id,
    'salesPointId', v_saved.sales_point_id,
    'code', v_saved.code,
    'name', v_saved.name,
    'status', v_saved.status,
    'enrolledAt', v_saved.enrolled_at,
    'revokedAt', v_saved.revoked_at,
    'lastSeenAt', v_saved.last_seen_at
  );
end;
$$;

create or replace function public.list_admin_operational_locations()
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_result jsonb;
begin
  if (select auth.uid()) is null
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', b.id,
      'code', b.code,
      'name', b.name,
      'timezone', b.timezone,
      'addressText', b.address_text,
      'phone', b.phone,
      'isActive', b.is_active,
      'isDefault', b.is_default,
      'salesPoints', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'id', sp.id,
            'branchId', sp.branch_id,
            'code', sp.code,
            'name', sp.name,
            'isActive', sp.is_active,
            'terminals', coalesce((
              select jsonb_agg(
                jsonb_build_object(
                  'id', t.id,
                  'salesPointId', t.sales_point_id,
                  'code', t.code,
                  'name', t.name,
                  'status', t.status,
                  'enrolledAt', t.enrolled_at,
                  'revokedAt', t.revoked_at,
                  'lastSeenAt', t.last_seen_at
                )
                order by t.code
              )
              from public.terminals t
              where t.sales_point_id = sp.id
            ), '[]'::jsonb)
          )
          order by sp.code
        )
        from public.sales_points sp
        where sp.branch_id = b.id
      ), '[]'::jsonb)
    )
    order by b.is_default desc, b.code
  ), '[]'::jsonb)
  into v_result
  from public.branches b;

  return v_result;
end;
$$;

create or replace function public.save_sales_point(p_payload jsonb)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.save_sales_point_impl(p_payload, (select auth.uid()));
$$;

create or replace function public.save_terminal(p_payload jsonb)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.save_terminal_impl(p_payload, (select auth.uid()));
$$;

create or replace function public.issue_terminal_enrolment_code(p_terminal_id uuid)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.issue_terminal_enrolment_code_impl(
    p_terminal_id,
    (select auth.uid())
  );
$$;

create or replace function public.revoke_terminal(p_terminal_id uuid)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.revoke_terminal_impl(
    p_terminal_id,
    (select auth.uid())
  );
$$;

create or replace function public.enrol_terminal(p_code text)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.enrol_terminal_impl(
    p_code,
    (select auth.uid())
  );
$$;

create or replace function public.resolve_terminal_credential(p_credential text)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $
  select private.terminal_context_impl(
    p_credential,
    true,
    (select auth.uid())
  );
$;

revoke all on function private.terminal_context_impl(text, boolean, uuid)
from public, anon, authenticated;
revoke all on function private.enrol_terminal_impl(text, uuid)
from public, anon, authenticated;
revoke all on function private.issue_terminal_enrolment_code_impl(uuid, uuid)
from public, anon, authenticated;
revoke all on function private.save_sales_point_impl(jsonb, uuid)
from public, anon, authenticated;
revoke all on function private.save_terminal_impl(jsonb, uuid)
from public, anon, authenticated;
revoke all on function private.revoke_terminal_impl(uuid, uuid)
from public, anon, authenticated;

grant usage on schema private to authenticated;
grant execute on function private.terminal_context_impl(text, boolean, uuid)
to authenticated;
grant execute on function private.enrol_terminal_impl(text, uuid)
to authenticated;
grant execute on function private.issue_terminal_enrolment_code_impl(uuid, uuid)
to authenticated;
grant execute on function private.save_sales_point_impl(jsonb, uuid)
to authenticated;
grant execute on function private.save_terminal_impl(jsonb, uuid)
to authenticated;
grant execute on function private.revoke_terminal_impl(uuid, uuid)
to authenticated;

revoke all on function public.list_admin_operational_locations()
from public, anon, authenticated;
revoke all on function public.save_sales_point(jsonb)
from public, anon, authenticated;
revoke all on function public.save_terminal(jsonb)
from public, anon, authenticated;
revoke all on function public.issue_terminal_enrolment_code(uuid)
from public, anon, authenticated;
revoke all on function public.revoke_terminal(uuid)
from public, anon, authenticated;
revoke all on function public.enrol_terminal(text)
from public, anon, authenticated;
revoke all on function public.resolve_terminal_credential(text)
from public, anon, authenticated;

grant execute on function public.list_admin_operational_locations()
to authenticated;
grant execute on function public.save_sales_point(jsonb)
to authenticated;
grant execute on function public.save_terminal(jsonb)
to authenticated;
grant execute on function public.issue_terminal_enrolment_code(uuid)
to authenticated;
grant execute on function public.revoke_terminal(uuid)
to authenticated;
grant execute on function public.enrol_terminal(text)
to authenticated;
grant execute on function public.resolve_terminal_credential(text)
to authenticated;

alter table public.orders
  add column sales_point_id uuid,
  add column terminal_id uuid,
  add column sales_point_code_snapshot text,
  add column sales_point_name_snapshot text,
  add column terminal_code_snapshot text;

alter table public.orders
  add constraint orders_sales_point_branch_fk
    foreign key (sales_point_id, branch_id)
    references public.sales_points(id, branch_id)
    on delete restrict,
  add constraint orders_terminal_sales_point_fk
    foreign key (terminal_id, sales_point_id)
    references public.terminals(id, sales_point_id)
    on delete restrict,
  add constraint orders_operational_context_shape_check check (
    (
      sales_point_id is null
      and terminal_id is null
      and sales_point_code_snapshot is null
      and sales_point_name_snapshot is null
      and terminal_code_snapshot is null
    )
    or
    (
      sales_point_id is not null
      and terminal_id is not null
      and sales_point_code_snapshot is not null
      and sales_point_name_snapshot is not null
      and terminal_code_snapshot is not null
    )
  ),
  add constraint orders_customer_terminal_context_check check (
    source <> 'customer'
    or (
      sales_point_id is null
      and terminal_id is null
      and sales_point_code_snapshot is null
      and sales_point_name_snapshot is null
      and terminal_code_snapshot is null
    )
  );

create index orders_sales_point_created_idx
  on public.orders (sales_point_id, created_at desc)
  where sales_point_id is not null;
create index orders_terminal_created_idx
  on public.orders (terminal_id, created_at desc)
  where terminal_id is not null;

create or replace function private.protect_order_commercial_fields()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.order_number is distinct from old.order_number
     or new.source is distinct from old.source
     or new.customer_user_id is distinct from old.customer_user_id
     or new.member_id is distinct from old.member_id
     or new.created_by_user_id is distinct from old.created_by_user_id
     or new.branch_id is distinct from old.branch_id
     or new.sales_point_id is distinct from old.sales_point_id
     or new.terminal_id is distinct from old.terminal_id
     or new.sales_point_code_snapshot is distinct from old.sales_point_code_snapshot
     or new.sales_point_name_snapshot is distinct from old.sales_point_name_snapshot
     or new.terminal_code_snapshot is distinct from old.terminal_code_snapshot
     or new.client_request_id is distinct from old.client_request_id
     or new.request_hash is distinct from old.request_hash
     or new.fulfillment_type is distinct from old.fulfillment_type
     or new.requested_pickup_at is distinct from old.requested_pickup_at
     or new.prepare_at is distinct from old.prepare_at
     or new.currency is distinct from old.currency
     or new.pricing_version is distinct from old.pricing_version
     or new.subtotal_sen is distinct from old.subtotal_sen
     or new.total_sen is distinct from old.total_sen
     or new.created_at is distinct from old.created_at then
    raise exception 'persisted order commercial fields are immutable'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create or replace function private.create_order_impl_v2(
  p_payload jsonb,
  p_source text,
  p_customer_user_id uuid,
  p_member_id uuid,
  p_actor_user_id uuid,
  p_terminal_credential text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_client_request_id uuid;
  v_request_hash text := md5(p_payload::text);
  v_existing public.orders%rowtype;
  v_quote jsonb;
  v_order_id uuid;
  v_status text;
  v_prepare_at timestamptz;
  v_preparation_lead integer;
  v_line jsonb;
  v_line_id uuid;
  v_addon jsonb;
  v_option jsonb;
  v_terminal_context jsonb;
  v_branch_id uuid;
  v_sales_point_id uuid;
  v_terminal_id uuid;
  v_sales_point_code text;
  v_sales_point_name text;
  v_terminal_code text;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode = '42501';
  end if;

  begin
    v_client_request_id := nullif(p_payload ->> 'clientRequestId', '')::uuid;
  exception when invalid_text_representation then
    raise exception 'clientRequestId must be a valid UUID' using errcode = '22023';
  end;
  if v_client_request_id is null then
    raise exception 'clientRequestId is required for idempotent placement'
      using errcode = '22023';
  end if;

  if p_source = 'customer' then
    if p_terminal_credential is not null then
      raise exception 'customer order cannot include terminal authority'
        using errcode = '22023';
    end if;
    if p_customer_user_id is null
       or p_customer_user_id is distinct from p_actor_user_id
       or p_member_id is null then
      raise exception 'customer order ownership is invalid' using errcode = '42501';
    end if;
    if not exists (
      select 1
      from public.members m
      where m.id = p_member_id
        and m.user_id = p_customer_user_id
        and m.active
    ) then
      raise exception 'active member record is required for customer ordering'
        using errcode = '42501';
    end if;

    select private.default_branch_id() into v_branch_id;
    if v_branch_id is null then
      raise exception 'default branch is unavailable' using errcode = '55000';
    end if;
  elsif p_source = 'pos' then
    if not (select private.is_staff_or_above()) then
      raise exception 'staff access required for POS order creation'
        using errcode = '42501';
    end if;
    if p_terminal_credential is null then
      raise exception 'active terminal enrolment is required'
        using errcode = '42501';
    end if;

    v_terminal_context := private.terminal_context_impl(
      p_terminal_credential,
      true,
      p_actor_user_id
    );

    v_branch_id := (v_terminal_context ->> 'branchId')::uuid;
    v_sales_point_id := (v_terminal_context ->> 'salesPointId')::uuid;
    v_terminal_id := (v_terminal_context ->> 'terminalId')::uuid;
    v_sales_point_code := v_terminal_context ->> 'salesPointCode';
    v_sales_point_name := v_terminal_context ->> 'salesPointName';
    v_terminal_code := v_terminal_context ->> 'terminalCode';

    if not (select private.can_operate_branch(v_branch_id)) then
      raise exception 'employee is not authorized for the terminal branch'
        using errcode = '42501';
    end if;
  else
    raise exception 'invalid order source' using errcode = '22023';
  end if;

  select *
  into v_existing
  from public.orders
  where created_by_user_id = p_actor_user_id
    and client_request_id = v_client_request_id;

  if found then
    if v_existing.request_hash <> v_request_hash
       or v_existing.source <> p_source then
      raise exception
        'clientRequestId was already used with a different order payload'
        using errcode = '23505';
    end if;
    if p_source = 'pos'
       and (
         v_existing.terminal_id is distinct from v_terminal_id
         or v_existing.sales_point_id is distinct from v_sales_point_id
         or v_existing.branch_id is distinct from v_branch_id
       ) then
      raise exception
        'clientRequestId was already used from a different terminal context'
        using errcode = '23505';
    end if;
    return private.order_snapshot(v_existing.id);
  end if;

  v_quote := public.quote_order(p_payload);
  v_status := case v_quote ->> 'fulfillmentType'
    when 'scheduled' then 'scheduled'
    else 'confirmed'
  end;

  if v_status = 'scheduled' then
    select s.preparation_lead_minutes
    into strict v_preparation_lead
    from public.order_schedule_settings s
    where s.id = 1;

    v_prepare_at :=
      nullif(v_quote ->> 'requestedPickupAt', '')::timestamptz
      - make_interval(mins => v_preparation_lead);
  end if;

  insert into public.orders (
    source,
    customer_user_id,
    member_id,
    created_by_user_id,
    branch_id,
    sales_point_id,
    terminal_id,
    sales_point_code_snapshot,
    sales_point_name_snapshot,
    terminal_code_snapshot,
    client_request_id,
    request_hash,
    fulfillment_type,
    requested_pickup_at,
    prepare_at,
    status,
    currency,
    pricing_version,
    subtotal_sen,
    total_sen
  ) values (
    p_source,
    p_customer_user_id,
    p_member_id,
    p_actor_user_id,
    v_branch_id,
    v_sales_point_id,
    v_terminal_id,
    v_sales_point_code,
    v_sales_point_name,
    v_terminal_code,
    v_client_request_id,
    v_request_hash,
    v_quote ->> 'fulfillmentType',
    nullif(v_quote ->> 'requestedPickupAt', '')::timestamptz,
    v_prepare_at,
    v_status,
    v_quote ->> 'currency',
    (v_quote ->> 'pricingVersion')::integer,
    (v_quote ->> 'subtotalSen')::bigint,
    (v_quote ->> 'totalSen')::bigint
  )
  returning id into v_order_id;

  for v_line in
    select value from jsonb_array_elements(v_quote -> 'lines')
  loop
    insert into public.order_lines (
      order_id,
      line_number,
      catalogue_item_id,
      sku_snapshot,
      name_snapshot,
      prep_route_snapshot,
      base_price_sen,
      variant_id,
      variant_code_snapshot,
      variant_label_snapshot,
      variant_price_delta_sen,
      addon_total_sen,
      option_total_sen,
      unit_price_sen,
      quantity,
      line_total_sen,
      note
    ) values (
      v_order_id,
      (v_line ->> 'lineNumber')::integer,
      (v_line ->> 'itemId')::uuid,
      v_line ->> 'sku',
      v_line ->> 'name',
      v_line ->> 'prepRoute',
      (v_line ->> 'basePriceSen')::integer,
      nullif(v_line #>> '{variant,id}', '')::uuid,
      nullif(v_line #>> '{variant,code}', ''),
      nullif(v_line #>> '{variant,label}', ''),
      coalesce((v_line #>> '{variant,priceDeltaSen}')::integer, 0),
      (v_line ->> 'addOnTotalSen')::integer,
      coalesce((v_line ->> 'optionTotalSen')::integer, 0),
      (v_line ->> 'unitPriceSen')::integer,
      (v_line ->> 'quantity')::integer,
      (v_line ->> 'lineTotalSen')::bigint,
      nullif(v_line ->> 'note', '')
    )
    returning id into v_line_id;

    for v_addon in
      select value from jsonb_array_elements(v_line -> 'addOns')
    loop
      insert into public.order_line_addons (
        order_line_id,
        catalogue_addon_item_id,
        sku_snapshot,
        name_snapshot,
        price_sen
      ) values (
        v_line_id,
        (v_addon ->> 'itemId')::uuid,
        v_addon ->> 'sku',
        v_addon ->> 'name',
        (v_addon ->> 'priceSen')::integer
      );
    end loop;

    for v_option in
      select value
      from jsonb_array_elements(coalesce(v_line -> 'options', '[]'::jsonb))
    loop
      insert into public.order_line_options (
        order_line_id,
        catalogue_option_group_id,
        catalogue_option_value_id,
        group_code_snapshot,
        group_name_snapshot,
        option_code_snapshot,
        option_label_snapshot,
        price_delta_sen
      ) values (
        v_line_id,
        (v_option ->> 'groupId')::uuid,
        (v_option ->> 'optionValueId')::uuid,
        v_option ->> 'groupCode',
        v_option ->> 'groupName',
        v_option ->> 'optionCode',
        v_option ->> 'optionLabel',
        (v_option ->> 'priceDeltaSen')::integer
      );
    end loop;
  end loop;

  insert into public.order_events (
    order_id,
    event_type,
    actor_user_id,
    from_status,
    to_status,
    details
  ) values (
    v_order_id,
    'created',
    p_actor_user_id,
    null,
    v_status,
    jsonb_build_object(
      'source', p_source,
      'branchId', v_branch_id,
      'salesPointId', v_sales_point_id,
      'terminalId', v_terminal_id,
      'fulfillmentType', v_quote ->> 'fulfillmentType',
      'requestedPickupAt', v_quote -> 'requestedPickupAt',
      'prepareAt', v_prepare_at,
      'totalSen', (v_quote ->> 'totalSen')::bigint
    )
  );

  return private.order_snapshot(v_order_id);
end;
$$;

create or replace function private.create_order_impl(
  p_payload jsonb,
  p_source text,
  p_customer_user_id uuid,
  p_member_id uuid,
  p_actor_user_id uuid
)
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select private.create_order_impl_v2(
    p_payload,
    p_source,
    p_customer_user_id,
    p_member_id,
    p_actor_user_id,
    null
  );
$$;

revoke all on function private.create_order_impl_v2(
  jsonb, text, uuid, uuid, uuid, text
) from public, anon, authenticated;
grant execute on function private.create_order_impl_v2(
  jsonb, text, uuid, uuid, uuid, text
) to authenticated;

create or replace function private.order_snapshot(p_order_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id,
    'orderNumber', o.order_number,
    'source', o.source,
    'customerUserId', o.customer_user_id,
    'memberId', o.member_id,
    'branchId', o.branch_id,
    'branch', jsonb_build_object(
      'id', b.id,
      'code', b.code,
      'name', b.name,
      'timezone', b.timezone
    ),
    'salesPointId', o.sales_point_id,
    'salesPoint', case
      when o.sales_point_id is null then null
      else jsonb_build_object(
        'id', o.sales_point_id,
        'code', o.sales_point_code_snapshot,
        'name', o.sales_point_name_snapshot
      )
    end,
    'terminalId', o.terminal_id,
    'terminal', case
      when o.terminal_id is null then null
      else jsonb_build_object(
        'id', o.terminal_id,
        'code', o.terminal_code_snapshot
      )
    end,
    'fulfillmentType', o.fulfillment_type,
    'requestedPickupAt', o.requested_pickup_at,
    'prepareAt', o.prepare_at,
    'serverNow', now(),
    'scheduleState', case
      when o.fulfillment_type = 'scheduled' and o.status = 'scheduled' then
        case
          when o.requested_pickup_at < now() then 'overdue'
          when o.prepare_at <= now() then 'due'
          else 'future'
        end
      else null
    end,
    'status', o.status,
    'statusVersion', o.status_version,
    'currency', o.currency,
    'pricingVersion', o.pricing_version,
    'subtotalSen', o.subtotal_sen,
    'totalSen', o.total_sen,
    'createdAt', o.created_at,
    'updatedAt', o.updated_at,
    'statusUpdatedAt', o.status_updated_at,
    'preparingAt', o.preparing_at,
    'readyAt', o.ready_at,
    'completedAt', o.completed_at,
    'cancelledAt', o.cancelled_at,
    'lines', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', l.id,
          'lineNumber', l.line_number,
          'itemId', l.catalogue_item_id,
          'sku', l.sku_snapshot,
          'name', l.name_snapshot,
          'prepRoute', l.prep_route_snapshot,
          'basePriceSen', l.base_price_sen,
          'variant', case
            when l.variant_id is null then null
            else jsonb_build_object(
              'id', l.variant_id,
              'code', l.variant_code_snapshot,
              'label', l.variant_label_snapshot,
              'priceDeltaSen', l.variant_price_delta_sen
            )
          end,
          'addOns', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'itemId', a.catalogue_addon_item_id,
                'sku', a.sku_snapshot,
                'name', a.name_snapshot,
                'priceSen', a.price_sen
              )
              order by a.created_at, a.id
            )
            from public.order_line_addons a
            where a.order_line_id = l.id
          ), '[]'::jsonb),
          'addOnTotalSen', l.addon_total_sen,
          'options', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'groupId', x.catalogue_option_group_id,
                'groupCode', x.group_code_snapshot,
                'groupName', x.group_name_snapshot,
                'optionValueId', x.catalogue_option_value_id,
                'optionCode', x.option_code_snapshot,
                'optionLabel', x.option_label_snapshot,
                'priceDeltaSen', x.price_delta_sen
              )
              order by x.created_at, x.id
            )
            from public.order_line_options x
            where x.order_line_id = l.id
          ), '[]'::jsonb),
          'optionTotalSen', l.option_total_sen,
          'unitPriceSen', l.unit_price_sen,
          'quantity', l.quantity,
          'lineTotalSen', l.line_total_sen,
          'note', l.note
        )
        order by l.line_number
      )
      from public.order_lines l
      where l.order_id = o.id
    ), '[]'::jsonb)
  )
  from public.orders o
  join public.branches b on b.id = o.branch_id
  where o.id = p_order_id
    and (
      o.customer_user_id = (select auth.uid())
      or (select private.can_operate_branch(o.branch_id))
    );
$$;

create or replace function public.place_pos_order(
  p_payload jsonb,
  p_terminal_credential text
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid());
begin
  if v_user_id is null or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;

  return private.create_order_impl_v2(
    p_payload,
    'pos',
    null,
    null,
    v_user_id,
    p_terminal_credential
  );
end;
$$;

revoke all on function public.place_pos_order(jsonb)
from public, anon, authenticated;
revoke all on function public.place_pos_order(jsonb, text)
from public, anon, authenticated;
grant execute on function public.place_pos_order(jsonb, text)
to authenticated;

comment on table public.sales_points is
  'Trusted physical/service sales points under branches. Not an inventory or shift authority.';
comment on table public.terminals is
  'Trusted POS terminal identity under a sales point. Credential material is stored only in private schema.';
comment on table private.terminal_enrolment_codes is
  'One-time bcrypt-hashed terminal enrolment codes. Plaintext is returned only at issuance.';
comment on table private.terminal_credentials is
  'Hashed high-entropy terminal credentials. Plaintext exists only in the BFF HttpOnly cookie.';
comment on column public.orders.sales_point_id is
  'Trusted sales-point attribution for terminal-origin POS orders; null for customer and legacy POS orders.';
comment on column public.orders.terminal_id is
  'Trusted terminal attribution for newly enrolled terminal-origin POS orders; null for customer and legacy POS orders.';

do $$
begin
  if not exists (
    select 1
    from public.sales_points sp
    join public.branches b on b.id = sp.branch_id
    where sp.code = 'SP-MAIN'
      and sp.name = 'Main Counter'
      and sp.is_active
      and b.code = 'BR-MAIN'
      and b.is_active
  ) then
    raise exception 'default sales point seed failed';
  end if;

  if not exists (
    select 1
    from public.terminals t
    join public.sales_points sp on sp.id = t.sales_point_id
    where t.code = 'POS-MAIN-01'
      and t.status = 'pending'
      and sp.code = 'SP-MAIN'
  ) then
    raise exception 'default terminal seed failed';
  end if;

  if exists (
    select 1
    from public.orders
    where source = 'customer'
      and (
        sales_point_id is not null
        or terminal_id is not null
        or sales_point_code_snapshot is not null
        or sales_point_name_snapshot is not null
        or terminal_code_snapshot is not null
      )
  ) then
    raise exception 'customer order terminal-context invariant failed';
  end if;
end;
$$;
