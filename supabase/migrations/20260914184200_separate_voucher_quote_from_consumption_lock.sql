-- TASK-OPS-006 / Phase 6 — voucher quote is read-only. Placement atomicity is
-- enforced by the AFTER INSERT consumption trigger, which locks the voucher.
-- Keeping quote validation STABLE avoids mixing row-lock behavior into quote RPCs.

create or replace function private.voucher_quote_adjustment_impl(
  p_member_id uuid,
  p_voucher_id uuid,
  p_base_quote jsonb,
  p_actor_user_id uuid,
  p_lock boolean default false
)
returns jsonb
language plpgsql
stable
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
  -- p_lock remains in the signature for migration compatibility. Quote validation
  -- never locks; the internal consumption trigger is the single locking authority.
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode='42501';
  end if;
  select private.current_app_role()::text into v_role;
  select * into v_member from public.members where id=p_member_id and active;
  if not found then raise exception 'active member is required' using errcode='42501', detail='LOYALTY_MEMBER_REQUIRED'; end if;
  if v_role='customer' and v_member.user_id is distinct from p_actor_user_id then raise exception 'voucher ownership required' using errcode='42501', detail='VOUCHER_FORBIDDEN'; end if;
  if v_role not in ('customer','staff','admin','owner') then raise exception 'voucher access denied' using errcode='42501'; end if;

  select * into v_voucher from public.member_vouchers where id=p_voucher_id;
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
        if v_best_price is null or v_unit_price < v_best_price then
          v_best_price:=v_unit_price;
          v_best_line:=v_line_number;
        end if;
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
