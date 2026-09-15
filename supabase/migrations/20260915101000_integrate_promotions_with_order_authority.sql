-- TASK-OPS-007 / Phase 7 — integrate generalized promotions with authoritative
-- quote/place while preserving Phase 6 voucher authority as a distinct snapshot.
--
-- Rules:
--   * customers/POS never submit authoritative promotion IDs or discount amounts;
--   * active promotions are resolved automatically from server configuration;
--   * quote is advisory/read-only; placement re-evaluates under promotion row locks;
--   * voucher discount remains distinct from promotion discount;
--   * accepted promotion/voucher applications are immutable server snapshots;
--   * usage limits serialize on promotion rows and idempotent order retries do not
--     consume usage twice.

alter table public.promotions
  add constraint promotions_member_limit_requires_member_check
  check (per_member_usage_limit is null or requires_member);

create or replace function private.promotion_discount_value(
  p_discount_type text,
  p_fixed_amount_sen bigint,
  p_percent_basis_points integer,
  p_maximum_discount_sen bigint,
  p_eligible_subtotal_sen bigint,
  p_remaining_sen bigint
)
returns bigint
language sql
immutable
set search_path = ''
as $$
  select greatest(
    0,
    least(
      greatest(p_remaining_sen,0),
      greatest(p_eligible_subtotal_sen,0),
      case
        when p_discount_type='fixed' then coalesce(p_fixed_amount_sen,0)
        when p_discount_type='percent' then
          least(
            floor(greatest(p_eligible_subtotal_sen,0)::numeric * coalesce(p_percent_basis_points,0)::numeric / 10000)::bigint,
            coalesce(p_maximum_discount_sen,9223372036854775807::bigint)
          )
        else 0
      end
    )
  );
$$;
revoke all on function private.promotion_discount_value(text,bigint,integer,bigint,bigint,bigint)
from public, anon, authenticated;

create or replace function private.promotion_eligible_subtotal(
  p_promotion_id uuid,
  p_base_quote jsonb
)
returns bigint
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_has_item_scope boolean;
  v_has_variant_scope boolean;
  v_has_addon_scope boolean;
  v_line jsonb;
  v_addon jsonb;
  v_item_id uuid;
  v_variant_id uuid;
  v_quantity integer;
  v_line_total bigint;
  v_eligible bigint := 0;
  v_line_matched boolean;
begin
  select exists(select 1 from public.promotion_items where promotion_id=p_promotion_id)
    into v_has_item_scope;
  select exists(select 1 from public.promotion_variants where promotion_id=p_promotion_id)
    into v_has_variant_scope;
  select exists(select 1 from public.promotion_addons where promotion_id=p_promotion_id)
    into v_has_addon_scope;

  if not v_has_item_scope and not v_has_variant_scope and not v_has_addon_scope then
    return coalesce((p_base_quote->>'subtotalSen')::bigint,0);
  end if;

  for v_line in select value from jsonb_array_elements(coalesce(p_base_quote->'lines','[]'::jsonb)) loop
    v_item_id := nullif(v_line->>'itemId','')::uuid;
    v_variant_id := nullif(v_line#>>'{variant,id}','')::uuid;
    v_quantity := greatest(coalesce((v_line->>'quantity')::integer,1),1);
    v_line_total := greatest(coalesce((v_line->>'lineTotalSen')::bigint,0),0);
    v_line_matched := false;

    if v_has_item_scope and exists(
      select 1 from public.promotion_items pi
      where pi.promotion_id=p_promotion_id and pi.catalogue_item_id=v_item_id
    ) then
      v_line_matched := true;
    end if;

    if not v_line_matched and v_has_variant_scope and v_variant_id is not null and exists(
      select 1 from public.promotion_variants pv
      where pv.promotion_id=p_promotion_id and pv.variant_id=v_variant_id
    ) then
      v_line_matched := true;
    end if;

    if v_line_matched then
      v_eligible := v_eligible + v_line_total;
    elsif v_has_addon_scope then
      for v_addon in select value from jsonb_array_elements(coalesce(v_line->'addOns','[]'::jsonb)) loop
        if exists(
          select 1 from public.promotion_addons pa
          where pa.promotion_id=p_promotion_id
            and pa.addon_item_id=nullif(v_addon->>'itemId','')::uuid
        ) then
          v_eligible := v_eligible
            + greatest(coalesce((v_addon->>'priceSen')::bigint,0),0) * v_quantity::bigint;
        end if;
      end loop;
    end if;
  end loop;

  return v_eligible;
end;
$$;
revoke all on function private.promotion_eligible_subtotal(uuid,jsonb)
from public, anon, authenticated;

create or replace function private.evaluate_promotions_impl(
  p_base_quote jsonb,
  p_member_id uuid,
  p_has_voucher boolean,
  p_voucher_discount_sen bigint
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_branch_id uuid := nullif(p_base_quote->>'branchId','')::uuid;
  v_subtotal bigint := coalesce((p_base_quote->>'subtotalSen')::bigint,0);
  v_remaining bigint := greatest(v_subtotal-coalesce(p_voucher_discount_sen,0),0);
  v_total_discount bigint := 0;
  v_promotions jsonb := '[]'::jsonb;
  v_started_stack boolean := false;
  v_p public.promotions%rowtype;
  v_eligible bigint;
  v_discount bigint;
  v_value bigint;
  v_global_count bigint;
  v_member_count bigint;
begin
  if v_branch_id is null then
    raise exception 'promotion evaluation requires authoritative branch' using errcode='55000';
  end if;

  for v_p in
    select p.*
    from public.promotions p
    where p.is_active
      and (p.starts_at is null or p.starts_at <= now())
      and (p.ends_at is null or p.ends_at > now())
      and p.minimum_subtotal_sen <= v_subtotal
      and (not p.requires_member or p_member_id is not null)
      and (not p_has_voucher or p.allow_with_voucher)
      and (
        not exists(select 1 from public.promotion_branches pb where pb.promotion_id=p.id)
        or exists(select 1 from public.promotion_branches pb where pb.promotion_id=p.id and pb.branch_id=v_branch_id)
      )
    order by p.priority,p.code,p.id
  loop
    if v_remaining <= 0 then exit; end if;

    if v_p.global_usage_limit is not null then
      select count(*) into v_global_count
      from public.promotion_order_applications a
      where a.promotion_id=v_p.id;
      if v_global_count >= v_p.global_usage_limit then continue; end if;
    end if;

    if v_p.per_member_usage_limit is not null then
      if p_member_id is null then continue; end if;
      select count(*) into v_member_count
      from public.promotion_order_applications a
      where a.promotion_id=v_p.id and a.member_id=p_member_id;
      if v_member_count >= v_p.per_member_usage_limit then continue; end if;
    end if;

    v_eligible := private.promotion_eligible_subtotal(v_p.id,p_base_quote);
    if v_eligible <= 0 then continue; end if;

    if v_started_stack and v_p.stacking_mode <> 'stackable' then
      continue;
    end if;

    v_value := case when v_p.discount_type='fixed'
      then v_p.fixed_amount_sen
      else v_p.percent_basis_points::bigint end;
    v_discount := private.promotion_discount_value(
      v_p.discount_type,
      v_p.fixed_amount_sen,
      v_p.percent_basis_points,
      v_p.maximum_discount_sen,
      v_eligible,
      v_remaining
    );
    if v_discount <= 0 then continue; end if;

    v_promotions := v_promotions || jsonb_build_array(jsonb_build_object(
      'id',v_p.id,
      'code',v_p.code,
      'name',v_p.name,
      'discountType',v_p.discount_type,
      'discountValue',v_value,
      'discountSen',v_discount,
      'priority',v_p.priority,
      'stackingMode',v_p.stacking_mode,
      'allowWithVoucher',v_p.allow_with_voucher
    ));
    v_total_discount := v_total_discount + v_discount;
    v_remaining := v_remaining - v_discount;

    if v_p.stacking_mode='exclusive' then
      exit;
    end if;
    v_started_stack := true;
  end loop;

  return jsonb_build_object(
    'promotionDiscountSen',v_total_discount,
    'promotions',v_promotions
  );
end;
$$;
revoke all on function private.evaluate_promotions_impl(jsonb,uuid,boolean,bigint)
from public, anon, authenticated;

create or replace function private.lock_promotion_candidates_impl(
  p_branch_id uuid,
  p_member_id uuid,
  p_has_voucher boolean,
  p_subtotal_sen bigint
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_id uuid;
begin
  -- Lock all configuration rows that could possibly participate in this order,
  -- in UUID order. This is intentionally broader than final item eligibility:
  -- it makes global/member usage counts stable through placement and provides a
  -- deterministic lock order for concurrent orders and Admin edits.
  for v_id in
    select p.id
    from public.promotions p
    where p.is_active
      and (p.starts_at is null or p.starts_at <= now())
      and (p.ends_at is null or p.ends_at > now())
      and p.minimum_subtotal_sen <= p_subtotal_sen
      and (not p.requires_member or p_member_id is not null)
      and (not p_has_voucher or p.allow_with_voucher)
      and (
        not exists(select 1 from public.promotion_branches pb where pb.promotion_id=p.id)
        or exists(select 1 from public.promotion_branches pb where pb.promotion_id=p.id and pb.branch_id=p_branch_id)
      )
    order by p.id
  loop
    perform 1 from public.promotions p where p.id=v_id for update;
  end loop;
end;
$$;
revoke all on function private.lock_promotion_candidates_impl(uuid,uuid,boolean,bigint)
from public, anon, authenticated;

create or replace function private.quote_order_phase7_impl(
  p_payload jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_base jsonb;
  v_member_id uuid;
  v_voucher_id uuid;
  v_voucher_adjustment jsonb;
  v_voucher jsonb := null;
  v_voucher_discount bigint := 0;
  v_promotion_adjustment jsonb;
  v_promotion_discount bigint := 0;
  v_subtotal bigint;
  v_total_discount bigint;
begin
  if p_actor_user_id is not null and p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode='42501';
  end if;

  v_base := private.quote_order_phase5(p_payload);
  v_subtotal := coalesce((v_base->>'subtotalSen')::bigint,0);

  if p_actor_user_id is not null then
    v_member_id := private.resolve_loyalty_member_for_order(p_payload,p_actor_user_id);
  end if;

  begin
    v_voucher_id := nullif(p_payload->>'voucherId','')::uuid;
  exception when invalid_text_representation then
    raise exception 'voucherId must be a valid UUID' using errcode='22023';
  end;

  if v_voucher_id is not null then
    if p_actor_user_id is null then
      raise exception 'authentication required for voucher use' using errcode='42501';
    end if;
    if v_member_id is null then
      raise exception 'memberCode is required for POS voucher use'
        using errcode='22023', detail='LOYALTY_MEMBER_REQUIRED';
    end if;
    v_voucher_adjustment := private.voucher_quote_adjustment_impl(
      v_member_id,v_voucher_id,v_base,p_actor_user_id,false
    );
    v_voucher_discount := coalesce((v_voucher_adjustment->>'discountSen')::bigint,0);
    v_voucher := v_voucher_adjustment->'voucher';
  end if;

  v_promotion_adjustment := private.evaluate_promotions_impl(
    v_base,v_member_id,v_voucher_id is not null,v_voucher_discount
  );
  v_promotion_discount := coalesce((v_promotion_adjustment->>'promotionDiscountSen')::bigint,0);
  v_total_discount := v_voucher_discount + v_promotion_discount;

  if v_total_discount < 0 or v_total_discount > v_subtotal then
    raise exception 'authoritative discount exceeds subtotal' using errcode='55000';
  end if;

  return v_base || jsonb_build_object(
    'voucherDiscountSen',v_voucher_discount,
    'promotionDiscountSen',v_promotion_discount,
    'discountSen',v_total_discount,
    'totalSen',v_subtotal-v_total_discount,
    'voucher',v_voucher,
    'promotions',coalesce(v_promotion_adjustment->'promotions','[]'::jsonb)
  );
end;
$$;
revoke all on function private.quote_order_phase7_impl(jsonb,uuid) from public, anon, authenticated;
grant execute on function private.quote_order_phase7_impl(jsonb,uuid) to anon, authenticated;

create or replace function public.quote_order(p_payload jsonb)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select private.quote_order_phase7_impl(p_payload,(select auth.uid()));
$$;
revoke all on function public.quote_order(jsonb) from public, anon, authenticated;
grant execute on function public.quote_order(jsonb) to anon, authenticated;

-- Phase 7 no longer uses the Phase 6 pending-voucher insert trigger because the
-- total order discount can now contain both voucher and promotion amounts. The
-- voucher is finalized after order creation using its own authoritative amount.
drop trigger if exists orders_consume_pending_voucher on public.orders;
revoke all on function private.consume_pending_order_voucher() from public, anon, authenticated;

create or replace function private.finalize_order_discount_applications_impl(
  p_order_id uuid,
  p_member_id uuid,
  p_voucher_id uuid,
  p_quote jsonb,
  p_actor_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_voucher public.member_vouchers%rowtype;
  v_voucher_discount bigint := coalesce((p_quote->>'voucherDiscountSen')::bigint,0);
  v_promotion_discount bigint := coalesce((p_quote->>'promotionDiscountSen')::bigint,0);
  v_total_discount bigint := coalesce((p_quote->>'discountSen')::bigint,0);
  v_promotions jsonb := coalesce(p_quote->'promotions','[]'::jsonb);
  v_snapshot jsonb;
  v_p public.promotions%rowtype;
  v_snapshot_value bigint;
  v_global_count bigint;
  v_member_count bigint;
  v_persisted_promotion_total bigint := 0;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode='42501';
  end if;

  select * into strict v_order from public.orders where id=p_order_id for update;
  if v_order.member_id is distinct from p_member_id
     or v_order.subtotal_sen is distinct from (p_quote->>'subtotalSen')::bigint
     or v_order.discount_sen is distinct from v_total_discount
     or v_order.total_sen is distinct from (p_quote->>'totalSen')::bigint then
    raise exception 'order discount finalization does not match authoritative quote'
      using errcode='55000', detail='ORDER_DISCOUNT_SNAPSHOT_MISMATCH';
  end if;

  if p_voucher_id is null then
    if v_voucher_discount <> 0 or p_quote->'voucher' is not null then
      raise exception 'voucher quote snapshot exists without voucher intent' using errcode='55000';
    end if;
  else
    if v_voucher_discount <= 0 or p_quote->'voucher' is null then
      raise exception 'voucher intent has no authoritative voucher discount' using errcode='55000';
    end if;
    select * into v_voucher from public.member_vouchers where id=p_voucher_id for update;
    if not found or v_voucher.member_id is distinct from p_member_id then
      raise exception 'voucher is unavailable' using errcode='22023', detail='VOUCHER_UNAVAILABLE';
    end if;
    if v_voucher.status<>'active' or v_voucher.expires_at<=now() then
      raise exception 'voucher is no longer available' using errcode='22023', detail='VOUCHER_NOT_ACTIVE';
    end if;

    update public.member_vouchers
    set status='used',used_order_id=v_order.id,used_at=now(),updated_at=now()
    where id=v_voucher.id;

    insert into public.voucher_order_applications(
      order_id,member_voucher_id,voucher_code_snapshot,reward_code_snapshot,
      reward_name_snapshot,reward_type_snapshot,discount_sen
    ) values (
      v_order.id,v_voucher.id,v_voucher.code,v_voucher.reward_code_snapshot,
      v_voucher.reward_name_snapshot,v_voucher.reward_type_snapshot,v_voucher_discount
    );
  end if;

  for v_snapshot in select value from jsonb_array_elements(v_promotions) loop
    select * into v_p
    from public.promotions p
    where p.id=(v_snapshot->>'id')::uuid
    for update;
    if not found then
      raise exception 'selected promotion disappeared during placement' using errcode='55000';
    end if;

    v_snapshot_value := (v_snapshot->>'discountValue')::bigint;
    if v_p.code is distinct from v_snapshot->>'code'
       or v_p.name is distinct from v_snapshot->>'name'
       or v_p.discount_type is distinct from v_snapshot->>'discountType'
       or (case when v_p.discount_type='fixed' then v_p.fixed_amount_sen else v_p.percent_basis_points::bigint end) is distinct from v_snapshot_value
       or v_p.priority is distinct from (v_snapshot->>'priority')::integer
       or v_p.stacking_mode is distinct from v_snapshot->>'stackingMode'
       or v_p.allow_with_voucher is distinct from (v_snapshot->>'allowWithVoucher')::boolean then
      raise exception 'promotion configuration changed during placement'
        using errcode='40001', detail='PROMOTION_CHANGED';
    end if;

    if v_p.global_usage_limit is not null then
      select count(*) into v_global_count from public.promotion_order_applications a where a.promotion_id=v_p.id;
      if v_global_count >= v_p.global_usage_limit then
        raise exception 'promotion usage limit reached' using errcode='22023', detail='PROMOTION_USAGE_LIMIT';
      end if;
    end if;
    if v_p.per_member_usage_limit is not null then
      if p_member_id is null then
        raise exception 'promotion requires member usage identity' using errcode='22023', detail='PROMOTION_MEMBER_REQUIRED';
      end if;
      select count(*) into v_member_count
      from public.promotion_order_applications a
      where a.promotion_id=v_p.id and a.member_id=p_member_id;
      if v_member_count >= v_p.per_member_usage_limit then
        raise exception 'member promotion usage limit reached' using errcode='22023', detail='PROMOTION_MEMBER_USAGE_LIMIT';
      end if;
    end if;

    insert into public.promotion_order_applications(
      order_id,promotion_id,member_id,promotion_code_snapshot,promotion_name_snapshot,
      discount_type_snapshot,discount_value_snapshot,discount_sen,priority_snapshot,
      stacking_mode_snapshot,allow_with_voucher_snapshot
    ) values (
      v_order.id,v_p.id,p_member_id,v_p.code,v_p.name,v_p.discount_type,v_snapshot_value,
      (v_snapshot->>'discountSen')::bigint,v_p.priority,v_p.stacking_mode,v_p.allow_with_voucher
    );
    v_persisted_promotion_total := v_persisted_promotion_total + (v_snapshot->>'discountSen')::bigint;
  end loop;

  if v_persisted_promotion_total is distinct from v_promotion_discount
     or v_voucher_discount + v_persisted_promotion_total is distinct from v_order.discount_sen then
    raise exception 'discount application snapshots do not reconcile to order discount'
      using errcode='55000', detail='ORDER_DISCOUNT_RECONCILIATION_FAILED';
  end if;
end;
$$;
revoke all on function private.finalize_order_discount_applications_impl(uuid,uuid,uuid,jsonb,uuid)
from public, anon, authenticated;

-- Extend the Phase 6 trusted order snapshot with immutable promotion facts while
-- retaining the existing voucher contract.
do $$
begin
  if to_regprocedure('private.order_snapshot_phase6(uuid)') is null then
    alter function private.order_snapshot(uuid) rename to order_snapshot_phase6;
  end if;
end;
$$;
revoke all on function private.order_snapshot_phase6(uuid) from public, anon, authenticated;
grant execute on function private.order_snapshot_phase6(uuid) to authenticated;

create or replace function private.order_snapshot(p_order_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when base.snapshot is null then null else
    base.snapshot || jsonb_build_object(
      'voucherDiscountSen',coalesce((base.snapshot#>>'{voucher,discountSen}')::bigint,0),
      'promotionDiscountSen',coalesce((
        select sum(a.discount_sen) from public.promotion_order_applications a where a.order_id=o.id
      ),0),
      'promotions',coalesce((
        select jsonb_agg(jsonb_build_object(
          'code',a.promotion_code_snapshot,
          'name',a.promotion_name_snapshot,
          'discountType',a.discount_type_snapshot,
          'discountValue',a.discount_value_snapshot,
          'discountSen',a.discount_sen,
          'priority',a.priority_snapshot,
          'stackingMode',a.stacking_mode_snapshot,
          'allowWithVoucher',a.allow_with_voucher_snapshot,
          'appliedAt',a.applied_at
        ) order by a.priority_snapshot,a.promotion_code_snapshot)
        from public.promotion_order_applications a where a.order_id=o.id
      ),'[]'::jsonb)
    ) end
  from public.orders o
  cross join lateral (select private.order_snapshot_phase6(o.id) as snapshot) base
  where o.id=p_order_id;
$$;
revoke all on function private.order_snapshot(uuid) from public, anon, authenticated;
grant execute on function private.order_snapshot(uuid) to authenticated;

create or replace function private.place_customer_order_phase7_impl(
  p_payload jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_id uuid;
  v_branch_id uuid;
  v_client_request_id uuid;
  v_existing public.orders%rowtype;
  v_voucher_id uuid;
  v_base jsonb;
  v_locked_quote jsonb;
  v_result jsonb;
  v_order_id uuid;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authentication required' using errcode='42501';
  end if;
  if p_payload ?| array['shiftId','tenderType','paymentState','paidAt','memberCode'] then
    raise exception 'customer orders cannot claim staff/payment/member authority'
      using errcode='22023', detail='CUSTOMER_PAYMENT_AUTHORITY_FORBIDDEN';
  end if;
  if (select private.current_app_role()) <> 'customer'::public.app_user_role then
    raise exception 'customer identity required' using errcode='42501';
  end if;
  select id into v_member_id from public.members where user_id=p_actor_user_id and active limit 1;
  if v_member_id is null then
    raise exception 'active member record is required for customer ordering' using errcode='42501';
  end if;

  begin v_client_request_id:=nullif(p_payload->>'clientRequestId','')::uuid;
  exception when invalid_text_representation then raise exception 'clientRequestId must be a valid UUID' using errcode='22023'; end;
  if v_client_request_id is null then raise exception 'clientRequestId is required for idempotent placement' using errcode='22023'; end if;
  select * into v_existing from public.orders
  where created_by_user_id=p_actor_user_id and client_request_id=v_client_request_id;
  if found then
    if v_existing.request_hash<>md5(p_payload::text) or v_existing.source<>'customer' then
      raise exception 'clientRequestId was already used with a different order payload' using errcode='23505';
    end if;
    return private.order_snapshot(v_existing.id);
  end if;

  begin v_voucher_id:=nullif(p_payload->>'voucherId','')::uuid;
  exception when invalid_text_representation then raise exception 'voucherId must be a valid UUID' using errcode='22023'; end;

  v_base := private.quote_order_phase5(p_payload);
  v_branch_id := (v_base->>'branchId')::uuid;
  perform private.lock_promotion_candidates_impl(
    v_branch_id,v_member_id,v_voucher_id is not null,(v_base->>'subtotalSen')::bigint
  );
  v_locked_quote := private.quote_order_phase7_impl(p_payload,p_actor_user_id);

  -- Ensure the retired Phase 6 trigger context cannot be inherited accidentally.
  perform set_config('aida.pending_voucher_id','',true);
  perform set_config('aida.customer_order_branch_id',v_branch_id::text,true);
  v_result := private.create_order_impl(p_payload,'customer',p_actor_user_id,v_member_id,p_actor_user_id);
  perform set_config('aida.customer_order_branch_id','',true);
  v_order_id := (v_result->>'id')::uuid;

  perform private.finalize_order_discount_applications_impl(
    v_order_id,v_member_id,v_voucher_id,v_locked_quote,p_actor_user_id
  );
  return private.order_snapshot(v_order_id);
end;
$$;
revoke all on function private.place_customer_order_phase7_impl(jsonb,uuid) from public, anon, authenticated;
grant execute on function private.place_customer_order_phase7_impl(jsonb,uuid) to authenticated;

create or replace function public.place_customer_order(p_payload jsonb)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.place_customer_order_phase7_impl(p_payload,(select auth.uid()));
$$;
revoke all on function public.place_customer_order(jsonb) from public, anon, authenticated;
grant execute on function public.place_customer_order(jsonb) to authenticated;

-- Preserve the final Phase 1–6 POS retry/open-shift/terminal authority while
-- adding locked Phase 7 promotion evaluation and separate voucher finalization.
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
  v_base jsonb;
  v_locked_quote jsonb;
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

  begin v_client_request_id:=nullif(p_payload->>'clientRequestId','')::uuid;
  exception when invalid_text_representation then raise exception 'clientRequestId must be a valid UUID' using errcode='22023'; end;
  if v_client_request_id is null then raise exception 'clientRequestId is required for idempotent placement' using errcode='22023'; end if;

  v_terminal := private.terminal_context_impl(p_terminal_credential,false,p_actor_user_id);
  select * into v_existing from public.orders
  where created_by_user_id=p_actor_user_id and client_request_id=v_client_request_id;
  if found then
    if v_existing.request_hash<>md5(p_payload::text)
       or v_existing.source<>'pos'
       or v_existing.branch_id is distinct from (v_terminal->>'branchId')::uuid
       or v_existing.sales_point_id is distinct from (v_terminal->>'salesPointId')::uuid
       or v_existing.terminal_id is distinct from (v_terminal->>'terminalId')::uuid
       or v_existing.shift_id is null
       or v_existing.tender_type is distinct from v_tender
       or (v_tender='cash' and (v_existing.payment_state<>'paid' or v_existing.paid_at is null))
       or (v_tender='unpaid' and (v_existing.payment_state<>'unpaid' or v_existing.paid_at is not null)) then
      raise exception 'clientRequestId was already used with a different POS context'
        using errcode='23505', detail='ORDER_SHIFT_IDEMPOTENCY_CONFLICT';
    end if;
    return private.order_snapshot(v_existing.id);
  end if;

  v_shift := private.require_open_shift_impl(p_terminal_credential,p_actor_user_id);
  v_member_id := private.resolve_loyalty_member_for_order(p_payload,p_actor_user_id);
  begin v_voucher_id:=nullif(p_payload->>'voucherId','')::uuid;
  exception when invalid_text_representation then raise exception 'voucherId must be a valid UUID' using errcode='22023'; end;
  if v_voucher_id is not null and v_member_id is null then
    raise exception 'memberCode is required for POS voucher use'
      using errcode='22023', detail='LOYALTY_MEMBER_REQUIRED';
  end if;

  -- Quote using the same trusted branch that the terminal/shift authorizes.
  perform set_config('aida.trusted_order_branch_id',v_shift->>'branchId',true);
  v_base := private.quote_order_phase5(p_payload);
  perform private.lock_promotion_candidates_impl(
    (v_shift->>'branchId')::uuid,v_member_id,v_voucher_id is not null,(v_base->>'subtotalSen')::bigint
  );
  v_locked_quote := private.quote_order_phase7_impl(p_payload,p_actor_user_id);
  perform set_config('aida.pending_voucher_id','',true);

  v_order := private.create_order_impl_v2(
    p_payload,'pos',null,v_member_id,p_actor_user_id,p_terminal_credential
  );
  perform set_config('aida.trusted_order_branch_id','',true);
  v_order_id := (v_order->>'id')::uuid;

  perform private.finalize_pos_order_shift_impl(
    v_order_id,(v_shift->>'id')::uuid,v_tender,p_terminal_credential,p_actor_user_id
  );
  perform private.finalize_order_discount_applications_impl(
    v_order_id,v_member_id,v_voucher_id,v_locked_quote,p_actor_user_id
  );
  return private.order_snapshot(v_order_id);
end;
$$;
revoke all on function private.place_pos_order_authority_impl(jsonb,text,uuid)
from public, anon, authenticated;
grant execute on function private.place_pos_order_authority_impl(jsonb,text,uuid) to authenticated;

create or replace function public.place_pos_order(p_payload jsonb,p_terminal_credential text)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.place_pos_order_authority_impl(
    p_payload,p_terminal_credential,(select auth.uid())
  );
$$;
revoke all on function public.place_pos_order(jsonb,text) from public, anon, authenticated;
grant execute on function public.place_pos_order(jsonb,text) to authenticated;

comment on function public.quote_order(jsonb) is
  'Phase 7 authoritative quote. Voucher and promotion discounts are independently server-derived; quote does not reserve promotion usage.';
comment on function public.place_customer_order(jsonb) is
  'Phase 7 customer placement: re-evaluates promotions under usage locks and persists immutable voucher/promotion discount applications.';
comment on function public.place_pos_order(jsonb,text) is
  'Phase 7 POS placement: preserves terminal/open-shift authority, re-evaluates promotions under usage locks, and persists immutable discount applications.';
