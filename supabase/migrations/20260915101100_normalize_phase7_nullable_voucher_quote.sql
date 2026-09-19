-- TASK-OPS-007 / Phase 7 — normalize absent voucher state.
-- jsonb_build_object('voucher', NULL) yields JSON null rather than SQL NULL.
-- Omitting only the voucher key when there is no voucher intent preserves the
-- existing client-visible null semantics (`json['voucher']` remains null) while
-- letting placement distinguish absence from a trusted voucher snapshot.

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
  v_result jsonb;
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

  v_result := v_base || jsonb_build_object(
    'voucherDiscountSen',v_voucher_discount,
    'promotionDiscountSen',v_promotion_discount,
    'discountSen',v_total_discount,
    'totalSen',v_subtotal-v_total_discount,
    'promotions',coalesce(v_promotion_adjustment->'promotions','[]'::jsonb)
  );

  if v_voucher is not null then
    v_result := v_result || jsonb_build_object('voucher',v_voucher);
  end if;

  return v_result;
end;
$$;

revoke all on function private.quote_order_phase7_impl(jsonb,uuid)
from public, anon, authenticated;
grant execute on function private.quote_order_phase7_impl(jsonb,uuid)
to anon, authenticated;
