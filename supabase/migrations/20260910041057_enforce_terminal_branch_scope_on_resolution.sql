-- TASK-OPS-002 / Phase 1 terminal branch-scope hardening.
-- Live migration: 20260910041057 enforce_terminal_branch_scope_on_resolution.

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

  if not (select private.can_operate_branch(v_branch_id)) then
    raise exception 'employee is not authorized for the terminal branch'
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
