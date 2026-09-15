-- TASK-OPS-006 / Phase 6 — keep voucher consumption entirely inside trusted
-- order insertion rather than exposing an executable private write helper.

revoke all on function private.consume_voucher_for_order(uuid,uuid,uuid,uuid) from public, anon, authenticated;

create or replace function private.consume_pending_order_voucher()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_pending text := nullif(current_setting('aida.pending_voucher_id',true),'');
  v_voucher_id uuid;
  v_voucher public.member_vouchers%rowtype;
begin
  if v_pending is null then return new; end if;
  begin v_voucher_id:=v_pending::uuid;
  exception when invalid_text_representation then raise exception 'invalid internal voucher context' using errcode='55000'; end;

  if new.member_id is null or new.discount_sen<=0 then
    raise exception 'internal voucher context requires member and discount' using errcode='55000', detail='VOUCHER_ORDER_MISMATCH';
  end if;

  select * into v_voucher from public.member_vouchers where id=v_voucher_id for update;
  if not found or v_voucher.member_id is distinct from new.member_id then
    raise exception 'voucher is unavailable' using errcode='22023', detail='VOUCHER_UNAVAILABLE';
  end if;
  if v_voucher.status<>'active' or v_voucher.expires_at<=now() then
    raise exception 'voucher is no longer available' using errcode='22023', detail='VOUCHER_NOT_ACTIVE';
  end if;

  update public.member_vouchers
  set status='used',used_order_id=new.id,used_at=now(),updated_at=now()
  where id=v_voucher.id;

  insert into public.voucher_order_applications(
    order_id,member_voucher_id,voucher_code_snapshot,reward_code_snapshot,
    reward_name_snapshot,reward_type_snapshot,discount_sen
  ) values (
    new.id,v_voucher.id,v_voucher.code,v_voucher.reward_code_snapshot,
    v_voucher.reward_name_snapshot,v_voucher.reward_type_snapshot,new.discount_sen
  );

  return new;
end;
$$;
revoke all on function private.consume_pending_order_voucher() from public, anon, authenticated;
create trigger orders_consume_pending_voucher
after insert on public.orders
for each row execute function private.consume_pending_order_voucher();

create or replace function public.place_customer_order(p_payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid()); v_member_id uuid; v_branch_id uuid; v_result jsonb;
  v_client_request_id uuid; v_existing public.orders%rowtype; v_voucher_id uuid;
begin
  if v_user_id is null then raise exception 'authentication required' using errcode='42501'; end if;
  if p_payload ?| array['shiftId','tenderType','paymentState','paidAt','memberCode'] then raise exception 'customer orders cannot claim staff/payment/member authority' using errcode='22023', detail='CUSTOMER_PAYMENT_AUTHORITY_FORBIDDEN'; end if;
  if (select private.current_app_role()) <> 'customer'::public.app_user_role then raise exception 'customer identity required' using errcode='42501'; end if;
  select id into v_member_id from public.members where user_id=v_user_id and active limit 1;
  if v_member_id is null then raise exception 'active member record is required for customer ordering' using errcode='42501'; end if;

  begin v_client_request_id:=nullif(p_payload->>'clientRequestId','')::uuid;
  exception when invalid_text_representation then raise exception 'clientRequestId must be a valid UUID' using errcode='22023'; end;
  if v_client_request_id is null then raise exception 'clientRequestId is required for idempotent placement' using errcode='22023'; end if;
  select * into v_existing from public.orders where created_by_user_id=v_user_id and client_request_id=v_client_request_id;
  if found then
    if v_existing.request_hash<>md5(p_payload::text) or v_existing.source<>'customer' then raise exception 'clientRequestId was already used with a different order payload' using errcode='23505'; end if;
    return private.order_snapshot(v_existing.id);
  end if;

  begin v_voucher_id:=nullif(p_payload->>'voucherId','')::uuid;
  exception when invalid_text_representation then raise exception 'voucherId must be a valid UUID' using errcode='22023'; end;
  if v_voucher_id is not null then
    perform private.voucher_quote_adjustment_impl(v_member_id,v_voucher_id,private.quote_order_phase5(p_payload),v_user_id,true);
    perform set_config('aida.pending_voucher_id',v_voucher_id::text,true);
  else
    perform set_config('aida.pending_voucher_id','',true);
  end if;

  begin v_branch_id:=nullif(p_payload->>'branchId','')::uuid;
  exception when invalid_text_representation then raise exception 'branchId must be a valid UUID' using errcode='22023'; end;
  if v_branch_id is null then select private.default_branch_id() into v_branch_id; end if;
  if not exists(select 1 from public.branches where id=v_branch_id and is_active) then raise exception 'branch is unavailable for ordering' using errcode='22023', detail='BRANCH_UNAVAILABLE'; end if;

  perform set_config('aida.customer_order_branch_id',v_branch_id::text,true);
  v_result:=private.create_order_impl(p_payload,'customer',v_user_id,v_member_id,v_user_id);
  perform set_config('aida.customer_order_branch_id','',true);
  perform set_config('aida.pending_voucher_id','',true);
  return v_result;
end;
$$;
revoke all on function public.place_customer_order(jsonb) from public, anon, authenticated;
grant execute on function public.place_customer_order(jsonb) to authenticated;

create or replace function public.place_pos_order(p_payload jsonb,p_terminal_credential text)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid()); v_shift jsonb; v_order jsonb; v_order_id uuid;
  v_tender text := lower(btrim(coalesce(p_payload->>'tenderType','unpaid')));
  v_member_id uuid; v_voucher_id uuid; v_client_request_id uuid; v_existing public.orders%rowtype;
begin
  if v_user_id is null or not (select private.is_staff_or_above()) then raise exception 'staff access required' using errcode='42501'; end if;
  if v_tender not in ('unpaid','cash') then raise exception 'tenderType must be unpaid or cash' using errcode='22023', detail='ORDER_TENDER_INVALID'; end if;
  v_shift:=private.require_open_shift_impl(p_terminal_credential,v_user_id);

  begin v_client_request_id:=nullif(p_payload->>'clientRequestId','')::uuid;
  exception when invalid_text_representation then raise exception 'clientRequestId must be a valid UUID' using errcode='22023'; end;
  if v_client_request_id is null then raise exception 'clientRequestId is required for idempotent placement' using errcode='22023'; end if;
  select * into v_existing from public.orders where created_by_user_id=v_user_id and client_request_id=v_client_request_id;
  if found then
    if v_existing.request_hash<>md5(p_payload::text) or v_existing.source<>'pos'
       or v_existing.shift_id is distinct from (v_shift->>'id')::uuid or v_existing.tender_type is distinct from v_tender then
      raise exception 'clientRequestId was already used with a different POS context' using errcode='23505', detail='ORDER_SHIFT_IDEMPOTENCY_CONFLICT';
    end if;
    return private.order_snapshot(v_existing.id);
  end if;

  v_member_id:=private.resolve_loyalty_member_for_order(p_payload,v_user_id);
  begin v_voucher_id:=nullif(p_payload->>'voucherId','')::uuid;
  exception when invalid_text_representation then raise exception 'voucherId must be a valid UUID' using errcode='22023'; end;
  if v_voucher_id is not null and v_member_id is null then raise exception 'memberCode is required for POS voucher use' using errcode='22023', detail='LOYALTY_MEMBER_REQUIRED'; end if;
  if v_voucher_id is not null then
    perform private.voucher_quote_adjustment_impl(v_member_id,v_voucher_id,private.quote_order_phase5(p_payload),v_user_id,true);
    perform set_config('aida.pending_voucher_id',v_voucher_id::text,true);
  else
    perform set_config('aida.pending_voucher_id','',true);
  end if;

  perform set_config('aida.trusted_order_branch_id',v_shift->>'branchId',true);
  v_order:=private.create_order_impl_v2(p_payload,'pos',null,v_member_id,v_user_id,p_terminal_credential);
  perform set_config('aida.trusted_order_branch_id','',true);
  perform set_config('aida.pending_voucher_id','',true);
  v_order_id:=(v_order->>'id')::uuid;
  perform private.finalize_pos_order_shift_impl(v_order_id,(v_shift->>'id')::uuid,v_tender,p_terminal_credential,v_user_id);
  return private.order_snapshot(v_order_id);
end;
$$;
revoke all on function public.place_pos_order(jsonb,text) from public, anon, authenticated;
grant execute on function public.place_pos_order(jsonb,text) to authenticated;
