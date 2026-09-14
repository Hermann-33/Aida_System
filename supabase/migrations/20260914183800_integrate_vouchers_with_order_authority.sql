-- TASK-OPS-006 / Phase 6 — authoritative voucher quote/application/consumption.
-- Client voucher/member inputs remain intent. Supabase validates ownership,
-- reward eligibility, discount value, terminal/shift context and atomic use.

alter table public.orders
  add column discount_sen bigint not null default 0;

alter table public.orders
  drop constraint orders_total_consistency_check;

alter table public.orders
  add constraint orders_discount_sen_check check (discount_sen >= 0 and discount_sen <= subtotal_sen),
  add constraint orders_total_consistency_check check (total_sen = subtotal_sen - discount_sen);

comment on column public.orders.discount_sen is
  'Immutable server-derived accepted discount. Phase 6 value is backed by voucher_order_applications; Phase 7 will extend discount authority.';

-- Existing order creation helpers insert authoritative subtotal/total from quote
-- but predate the discount column. Derive the persisted discount from those
-- server-owned values before constraints are checked.
create or replace function private.derive_order_discount_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.total_sen > new.subtotal_sen then
    raise exception 'order total cannot exceed subtotal' using errcode='22023', detail='ORDER_TOTAL_INVALID';
  end if;
  new.discount_sen := new.subtotal_sen - new.total_sen;
  return new;
end;
$$;
revoke all on function private.derive_order_discount_insert() from public, anon, authenticated;
create trigger orders_derive_discount before insert on public.orders for each row execute function private.derive_order_discount_insert();

-- Preserve Phase 2 immutability while adding discount_sen to the immutable
-- commercial snapshot. Shift/tender finalization remains the only controlled
-- post-insert commercial-adjacent mutation.
create or replace function private.protect_order_commercial_fields()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_internal_finalize boolean := coalesce(current_setting('aida.internal_order_shift_finalize', true), '') = 'on';
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
     or new.discount_sen is distinct from old.discount_sen
     or new.total_sen is distinct from old.total_sen
     or new.created_at is distinct from old.created_at then
    raise exception 'persisted order commercial fields are immutable' using errcode='42501';
  end if;

  if new.shift_id is distinct from old.shift_id
     or new.tender_type is distinct from old.tender_type
     or new.payment_state is distinct from old.payment_state
     or new.paid_at is distinct from old.paid_at then
    if not v_internal_finalize
       or old.source <> 'pos'
       or old.shift_id is not null
       or new.shift_id is null
       or old.tender_type <> 'unpaid'
       or old.payment_state <> 'unpaid'
       or old.paid_at is not null then
      raise exception 'persisted order shift/payment fields are immutable' using errcode='42501';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function private.protect_order_commercial_fields() from public, anon, authenticated;

-- Freeze the Phase 5 quote implementation behind the Phase 6 wrapper.
alter function public.quote_order(jsonb) set schema private;
alter function private.quote_order(jsonb) rename to quote_order_phase5;
revoke all on function private.quote_order_phase5(jsonb) from public, anon, authenticated;
grant execute on function private.quote_order_phase5(jsonb) to anon, authenticated;

create or replace function private.resolve_loyalty_member_for_order(
  p_payload jsonb,
  p_actor_user_id uuid
)
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_role text; v_member_id uuid; v_member_code text;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode='42501';
  end if;
  select private.current_app_role()::text into v_role;
  if v_role = 'customer' then
    if p_payload ? 'memberCode' then
      raise exception 'customer order cannot select another member' using errcode='22023', detail='LOYALTY_MEMBER_INTENT_FORBIDDEN';
    end if;
    select id into v_member_id from public.members where user_id=p_actor_user_id and active limit 1;
    if v_member_id is null then raise exception 'active member is required' using errcode='42501', detail='LOYALTY_MEMBER_REQUIRED'; end if;
    return v_member_id;
  end if;
  if v_role in ('staff','admin','owner') then
    v_member_code := nullif(upper(btrim(coalesce(p_payload->>'memberCode',''))),'');
    if v_member_code is null then return null; end if;
    select id into v_member_id from public.members where member_code=v_member_code and active limit 1;
    if v_member_id is null then raise exception 'member code is unavailable' using errcode='22023', detail='LOYALTY_MEMBER_NOT_FOUND'; end if;
    return v_member_id;
  end if;
  raise exception 'loyalty member resolution is unavailable' using errcode='42501';
end;
$$;
revoke all on function private.resolve_loyalty_member_for_order(jsonb,uuid) from public, anon, authenticated;
grant execute on function private.resolve_loyalty_member_for_order(jsonb,uuid) to authenticated;

create or replace function private.voucher_quote_adjustment_impl(
  p_member_id uuid,
  p_voucher_id uuid,
  p_base_quote jsonb,
  p_actor_user_id uuid,
  p_lock boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member public.members%rowtype;
  v_voucher public.member_vouchers%rowtype;
  v_role text;
  v_subtotal bigint;
  v_discount bigint := 0;
  v_line jsonb;
  v_line_number integer;
  v_unit_price bigint;
  v_best_price bigint;
  v_best_line integer;
  v_category_slug text;
  v_sku text;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then raise exception 'authenticated actor mismatch' using errcode='42501'; end if;
  select private.current_app_role()::text into v_role;
  select * into v_member from public.members where id=p_member_id and active;
  if not found then raise exception 'active member is required' using errcode='42501', detail='LOYALTY_MEMBER_REQUIRED'; end if;
  if v_role='customer' and v_member.user_id is distinct from p_actor_user_id then raise exception 'voucher ownership required' using errcode='42501', detail='VOUCHER_FORBIDDEN'; end if;
  if v_role not in ('customer','staff','admin','owner') then raise exception 'voucher access denied' using errcode='42501'; end if;

  if p_lock then
    select * into v_voucher from public.member_vouchers where id=p_voucher_id for update;
  else
    select * into v_voucher from public.member_vouchers where id=p_voucher_id;
  end if;
  if not found or v_voucher.member_id is distinct from p_member_id then raise exception 'voucher is unavailable' using errcode='22023', detail='VOUCHER_UNAVAILABLE'; end if;
  if v_voucher.status <> 'active' then raise exception 'voucher is not active' using errcode='22023', detail='VOUCHER_NOT_ACTIVE'; end if;
  if v_voucher.expires_at <= now() then raise exception 'voucher has expired' using errcode='22023', detail='VOUCHER_EXPIRED'; end if;

  v_subtotal := coalesce((p_base_quote->>'subtotalSen')::bigint,0);
  if v_voucher.reward_type_snapshot='fixed_amount' then
    v_discount := least(coalesce(v_voucher.fixed_amount_sen_snapshot,0),v_subtotal);
  elsif v_voucher.reward_type_snapshot='free_item' then
    for v_line in select value from jsonb_array_elements(coalesce(p_base_quote->'lines','[]'::jsonb)) loop
      v_line_number := (v_line->>'lineNumber')::integer;
      v_unit_price := (v_line->>'unitPriceSen')::bigint;
      select i.sku,c.slug into v_sku,v_category_slug
      from public.catalogue_items i join public.catalogue_categories c on c.id=i.category_id
      where i.id=(v_line->>'itemId')::uuid;
      if v_sku = any(v_voucher.eligible_item_skus_snapshot)
         or v_category_slug = any(v_voucher.eligible_category_slugs_snapshot) then
        if v_best_price is null or v_unit_price < v_best_price then v_best_price:=v_unit_price; v_best_line:=v_line_number; end if;
      end if;
    end loop;
    if v_best_price is null then raise exception 'order has no item eligible for this voucher' using errcode='22023', detail='VOUCHER_ITEM_INELIGIBLE'; end if;
    v_discount := least(v_best_price,v_subtotal);
  else
    raise exception 'unsupported voucher reward type' using errcode='55000';
  end if;

  if v_discount <= 0 then raise exception 'voucher produces no eligible discount' using errcode='22023', detail='VOUCHER_NO_VALUE'; end if;
  return jsonb_build_object(
    'discountSen',v_discount,
    'totalSen',v_subtotal-v_discount,
    'voucher',jsonb_build_object(
      'id',v_voucher.id,'code',v_voucher.code,'rewardCode',v_voucher.reward_code_snapshot,
      'rewardName',v_voucher.reward_name_snapshot,'rewardType',v_voucher.reward_type_snapshot,
      'discountSen',v_discount,'freeItemLineNumber',v_best_line,'expiresAt',v_voucher.expires_at
    )
  );
end;
$$;
revoke all on function private.voucher_quote_adjustment_impl(uuid,uuid,jsonb,uuid,boolean) from public, anon, authenticated;
grant execute on function private.voucher_quote_adjustment_impl(uuid,uuid,jsonb,uuid,boolean) to authenticated;

create or replace function public.quote_order(p_payload jsonb)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare v_quote jsonb; v_voucher_id uuid; v_member_id uuid; v_adjustment jsonb; v_actor uuid := (select auth.uid());
begin
  v_quote := private.quote_order_phase5(p_payload);
  begin v_voucher_id := nullif(p_payload->>'voucherId','')::uuid;
  exception when invalid_text_representation then raise exception 'voucherId must be a valid UUID' using errcode='22023'; end;
  if v_voucher_id is null then return v_quote || jsonb_build_object('discountSen',0,'voucher',null); end if;
  if v_actor is null then raise exception 'authentication required for voucher use' using errcode='42501'; end if;
  v_member_id := private.resolve_loyalty_member_for_order(p_payload,v_actor);
  if v_member_id is null then raise exception 'memberCode is required for POS voucher use' using errcode='22023', detail='LOYALTY_MEMBER_REQUIRED'; end if;
  v_adjustment := private.voucher_quote_adjustment_impl(v_member_id,v_voucher_id,v_quote,v_actor,false);
  return v_quote || v_adjustment;
end;
$$;
revoke all on function public.quote_order(jsonb) from public, anon, authenticated;
grant execute on function public.quote_order(jsonb) to anon, authenticated;

create or replace function private.consume_voucher_for_order(
  p_member_id uuid,
  p_voucher_id uuid,
  p_order_id uuid,
  p_actor_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_voucher public.member_vouchers%rowtype; v_order public.orders%rowtype;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then raise exception 'authenticated actor mismatch' using errcode='42501'; end if;
  select * into v_voucher from public.member_vouchers where id=p_voucher_id for update;
  if not found or v_voucher.member_id is distinct from p_member_id then raise exception 'voucher is unavailable' using errcode='22023', detail='VOUCHER_UNAVAILABLE'; end if;
  if v_voucher.status<>'active' or v_voucher.expires_at<=now() then raise exception 'voucher is no longer available' using errcode='22023', detail='VOUCHER_NOT_ACTIVE'; end if;
  select * into strict v_order from public.orders where id=p_order_id for update;
  if v_order.member_id is distinct from p_member_id or v_order.discount_sen<=0 then raise exception 'order voucher context is invalid' using errcode='42501', detail='VOUCHER_ORDER_MISMATCH'; end if;
  update public.member_vouchers set status='used',used_order_id=v_order.id,used_at=now(),updated_at=now() where id=v_voucher.id;
  insert into public.voucher_order_applications(order_id,member_voucher_id,voucher_code_snapshot,reward_code_snapshot,reward_name_snapshot,reward_type_snapshot,discount_sen)
  values(v_order.id,v_voucher.id,v_voucher.code,v_voucher.reward_code_snapshot,v_voucher.reward_name_snapshot,v_voucher.reward_type_snapshot,v_order.discount_sen);
end;
$$;
revoke all on function private.consume_voucher_for_order(uuid,uuid,uuid,uuid) from public, anon, authenticated;

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
  begin v_client_request_id:=nullif(p_payload->>'clientRequestId','')::uuid; exception when invalid_text_representation then raise exception 'clientRequestId must be a valid UUID' using errcode='22023'; end;
  if v_client_request_id is null then raise exception 'clientRequestId is required for idempotent placement' using errcode='22023'; end if;
  select * into v_existing from public.orders where created_by_user_id=v_user_id and client_request_id=v_client_request_id;
  if found then
    if v_existing.request_hash<>md5(p_payload::text) or v_existing.source<>'customer' then raise exception 'clientRequestId was already used with a different order payload' using errcode='23505'; end if;
    return private.order_snapshot(v_existing.id);
  end if;
  begin v_voucher_id:=nullif(p_payload->>'voucherId','')::uuid; exception when invalid_text_representation then raise exception 'voucherId must be a valid UUID' using errcode='22023'; end;
  if v_voucher_id is not null then perform private.voucher_quote_adjustment_impl(v_member_id,v_voucher_id,private.quote_order_phase5(p_payload),v_user_id,true); end if;
  begin v_branch_id:=nullif(p_payload->>'branchId','')::uuid; exception when invalid_text_representation then raise exception 'branchId must be a valid UUID' using errcode='22023'; end;
  if v_branch_id is null then select private.default_branch_id() into v_branch_id; end if;
  if not exists(select 1 from public.branches where id=v_branch_id and is_active) then raise exception 'branch is unavailable for ordering' using errcode='22023', detail='BRANCH_UNAVAILABLE'; end if;
  perform set_config('aida.customer_order_branch_id',v_branch_id::text,true);
  v_result:=private.create_order_impl(p_payload,'customer',v_user_id,v_member_id,v_user_id);
  perform set_config('aida.customer_order_branch_id','',true);
  if v_voucher_id is not null then perform private.consume_voucher_for_order(v_member_id,v_voucher_id,(v_result->>'id')::uuid,v_user_id); v_result:=private.order_snapshot((v_result->>'id')::uuid); end if;
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
  begin v_client_request_id:=nullif(p_payload->>'clientRequestId','')::uuid; exception when invalid_text_representation then raise exception 'clientRequestId must be a valid UUID' using errcode='22023'; end;
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
  begin v_voucher_id:=nullif(p_payload->>'voucherId','')::uuid; exception when invalid_text_representation then raise exception 'voucherId must be a valid UUID' using errcode='22023'; end;
  if v_voucher_id is not null and v_member_id is null then raise exception 'memberCode is required for POS voucher use' using errcode='22023', detail='LOYALTY_MEMBER_REQUIRED'; end if;
  if v_voucher_id is not null then perform private.voucher_quote_adjustment_impl(v_member_id,v_voucher_id,private.quote_order_phase5(p_payload),v_user_id,true); end if;
  perform set_config('aida.trusted_order_branch_id',v_shift->>'branchId',true);
  v_order:=private.create_order_impl_v2(p_payload,'pos',null,v_member_id,v_user_id,p_terminal_credential);
  perform set_config('aida.trusted_order_branch_id','',true);
  v_order_id:=(v_order->>'id')::uuid;
  perform private.finalize_pos_order_shift_impl(v_order_id,(v_shift->>'id')::uuid,v_tender,p_terminal_credential,v_user_id);
  if v_voucher_id is not null then perform private.consume_voucher_for_order(v_member_id,v_voucher_id,v_order_id,v_user_id); end if;
  return private.order_snapshot(v_order_id);
end;
$$;
revoke all on function public.place_pos_order(jsonb,text) from public, anon, authenticated;
grant execute on function public.place_pos_order(jsonb,text) to authenticated;

-- Guarded helper grants required by SECURITY INVOKER public wrappers. The
-- consumption helper is never directly executable by browser callers.
grant usage on schema private to anon, authenticated;
revoke all on function private.consume_voucher_for_order(uuid,uuid,uuid,uuid) from public, anon, authenticated;

comment on function public.quote_order(jsonb) is 'Authoritative Phase 5 quote plus optional caller/member-bound Phase 6 voucher discount; voucher application remains placement-atomic.';
