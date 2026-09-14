-- Phase 1–3 Codex audit remediation / Phase 6 cumulative compatibility.
-- Keep the generic order writer owner-internal, and make POS idempotent retries
-- resolvable after a shift is locked/closed without weakening the open-shift
-- requirement for genuinely new orders.

revoke all on function private.create_order_impl_v2(
  jsonb, text, uuid, uuid, uuid, text
) from public, anon, authenticated;

create or replace function private.place_pos_order_authority_impl(
  p_payload jsonb,
  p_terminal_credential text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_terminal jsonb;
  v_shift jsonb;
  v_order jsonb;
  v_order_id uuid;
  v_tender text := lower(btrim(coalesce(p_payload->>'tenderType','unpaid')));
  v_member_id uuid;
  v_voucher_id uuid;
  v_client_request_id uuid;
  v_existing public.orders%rowtype;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode='42501';
  end if;

  if v_tender not in ('unpaid','cash') then
    raise exception 'tenderType must be unpaid or cash'
      using errcode='22023', detail='ORDER_TENDER_INVALID';
  end if;

  begin
    v_client_request_id := nullif(p_payload->>'clientRequestId','')::uuid;
  exception when invalid_text_representation then
    raise exception 'clientRequestId must be a valid UUID' using errcode='22023';
  end;
  if v_client_request_id is null then
    raise exception 'clientRequestId is required for idempotent placement'
      using errcode='22023';
  end if;

  -- Resolve the current physical terminal/caller authority before any retry is
  -- returned. A locked/closed shift does not invalidate an already-persisted
  -- order, but a revoked/foreign terminal credential still fails closed.
  v_terminal := private.terminal_context_impl(
    p_terminal_credential,
    false,
    p_actor_user_id
  );

  select * into v_existing
  from public.orders
  where created_by_user_id = p_actor_user_id
    and client_request_id = v_client_request_id;

  if found then
    if v_existing.request_hash <> md5(p_payload::text)
       or v_existing.source <> 'pos'
       or v_existing.branch_id is distinct from (v_terminal->>'branchId')::uuid
       or v_existing.sales_point_id is distinct from (v_terminal->>'salesPointId')::uuid
       or v_existing.terminal_id is distinct from (v_terminal->>'terminalId')::uuid
       or v_existing.shift_id is null
       or v_existing.tender_type is distinct from v_tender
       or (v_tender = 'cash' and (
         v_existing.payment_state <> 'paid' or v_existing.paid_at is null
       ))
       or (v_tender = 'unpaid' and (
         v_existing.payment_state <> 'unpaid' or v_existing.paid_at is not null
       )) then
      raise exception 'clientRequestId was already used with a different POS context'
        using errcode='23505', detail='ORDER_SHIFT_IDEMPOTENCY_CONFLICT';
    end if;
    return private.order_snapshot(v_existing.id);
  end if;

  -- Only a new POS order requires a currently open shift.
  v_shift := private.require_open_shift_impl(
    p_terminal_credential,
    p_actor_user_id
  );

  v_member_id := private.resolve_loyalty_member_for_order(
    p_payload,
    p_actor_user_id
  );

  begin
    v_voucher_id := nullif(p_payload->>'voucherId','')::uuid;
  exception when invalid_text_representation then
    raise exception 'voucherId must be a valid UUID' using errcode='22023';
  end;

  if v_voucher_id is not null and v_member_id is null then
    raise exception 'memberCode is required for POS voucher use'
      using errcode='22023', detail='LOYALTY_MEMBER_REQUIRED';
  end if;

  if v_voucher_id is not null then
    perform private.voucher_quote_adjustment_impl(
      v_member_id,
      v_voucher_id,
      private.quote_order_phase5(p_payload),
      p_actor_user_id,
      true
    );
  end if;

  perform set_config('aida.trusted_order_branch_id',v_shift->>'branchId',true);
  v_order := private.create_order_impl_v2(
    p_payload,
    'pos',
    null,
    v_member_id,
    p_actor_user_id,
    p_terminal_credential
  );
  perform set_config('aida.trusted_order_branch_id','',true);

  v_order_id := (v_order->>'id')::uuid;
  perform private.finalize_pos_order_shift_impl(
    v_order_id,
    (v_shift->>'id')::uuid,
    v_tender,
    p_terminal_credential,
    p_actor_user_id
  );

  if v_voucher_id is not null then
    perform private.consume_voucher_for_order(
      v_member_id,
      v_voucher_id,
      v_order_id,
      p_actor_user_id
    );
  end if;

  return private.order_snapshot(v_order_id);
end;
$$;

revoke all on function private.place_pos_order_authority_impl(jsonb,text,uuid)
from public, anon, authenticated;
grant execute on function private.place_pos_order_authority_impl(jsonb,text,uuid)
to authenticated;

create or replace function public.place_pos_order(
  p_payload jsonb,
  p_terminal_credential text
)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.place_pos_order_authority_impl(
    p_payload,
    p_terminal_credential,
    (select auth.uid())
  );
$$;

revoke all on function public.place_pos_order(jsonb,text)
from public, anon, authenticated;
grant execute on function public.place_pos_order(jsonb,text)
to authenticated;

comment on function public.place_pos_order(jsonb,text) is
  'Trusted POS placement boundary. Existing matching retries resolve under current terminal/caller authority even after shift lock/close; genuinely new orders require an open shift.';
