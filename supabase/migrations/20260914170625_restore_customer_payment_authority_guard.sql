-- Phase 4 rewired customer placement for branch intent and must preserve the
-- Phase 2 prohibition on client-claimed shift/payment authority.

create or replace function public.place_customer_order(p_payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_member_id uuid;
  v_branch_id uuid;
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_payload ?| array['shiftId','tenderType','paymentState','paidAt'] then
    raise exception 'customer orders cannot claim shift or payment authority'
      using errcode = '22023', detail = 'CUSTOMER_PAYMENT_AUTHORITY_FORBIDDEN';
  end if;
  if (select private.current_app_role()) <> 'customer'::public.app_user_role then
    raise exception 'customer identity required' using errcode = '42501';
  end if;
  select m.id into v_member_id
  from public.members m
  where m.user_id = v_user_id and m.active
  limit 1;
  if v_member_id is null then
    raise exception 'active member record is required for customer ordering' using errcode = '42501';
  end if;
  begin
    v_branch_id := nullif(p_payload ->> 'branchId', '')::uuid;
  exception when invalid_text_representation then
    raise exception 'branchId must be a valid UUID' using errcode = '22023';
  end;
  if v_branch_id is null then
    select private.default_branch_id() into v_branch_id;
  end if;
  if not exists (select 1 from public.branches where id = v_branch_id and is_active) then
    raise exception 'branch is unavailable for ordering'
      using errcode = '22023', detail = 'BRANCH_UNAVAILABLE';
  end if;
  perform set_config('aida.customer_order_branch_id', v_branch_id::text, true);
  v_result := private.create_order_impl(p_payload, 'customer', v_user_id, v_member_id, v_user_id);
  perform set_config('aida.customer_order_branch_id', '', true);
  return v_result;
end;
$$;

revoke all on function public.place_customer_order(jsonb) from public, anon, authenticated;
grant execute on function public.place_customer_order(jsonb) to authenticated;
