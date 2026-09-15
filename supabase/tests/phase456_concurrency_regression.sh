#!/usr/bin/env bash
set -euo pipefail

DB_URL="${SUPABASE_DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
PSQL=(psql "$DB_URL" -X -v ON_ERROR_STOP=1 -q)
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "Phase 4-6 concurrency regression failed: $*" >&2
  for log in "$TMP_DIR"/*.log; do
    [[ -f "$log" ]] || continue
    echo "--- $log ---" >&2
    cat "$log" >&2
  done
  exit 1
}

run_competing_sessions() {
  local name="$1"
  local first_sql="$2"
  local second_sql="$3"
  local expected_error_regex="$4"
  local first_log="$TMP_DIR/${name}-first.log"
  local second_log="$TMP_DIR/${name}-second.log"

  set +e
  "${PSQL[@]}" >"$first_log" 2>&1 <<<"$first_sql" &
  local first_pid=$!
  sleep 0.4
  "${PSQL[@]}" >"$second_log" 2>&1 <<<"$second_sql"
  local second_status=$?
  wait "$first_pid"
  local first_status=$?
  set -e

  [[ "$first_status" -eq 0 ]] || fail "$name first transaction did not succeed"
  [[ "$second_status" -ne 0 ]] || fail "$name competing transaction unexpectedly succeeded"
  grep -Eiq "$expected_error_regex" "$second_log" || fail "$name failed for an unexpected reason"
}

"${PSQL[@]}" -f supabase/tests/phase456_concurrency_setup.sql

# Phase 4: one scheduled slot remains. The winning transaction deliberately
# stays open after insertion so the second session must contend on the advisory
# xact lock before rechecking committed slot usage. Use a catalogue item that is
# not controlled by the Phase 5 inventory fixture so this test isolates capacity.
SCHEDULE_FIRST=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
select public.place_customer_order(jsonb_build_object(
  'clientRequestId','77100000-0000-0000-0000-000000000001',
  'branchId',(select id from public.branches where code='BR-P16-CONC'),
  'fulfillmentType','scheduled',
  'requestedPickupAt',(((now() at time zone 'Asia/Kuala_Lumpur')::date + 1 + time '12:00') at time zone 'Asia/Kuala_Lumpur'),
  'items',jsonb_build_array(jsonb_build_object(
    'itemId',(select id from public.catalogue_items where sku='CF-LAT'),
    'variantId',(select v.id from public.catalogue_item_variants v join public.catalogue_items i on i.id=v.item_id where i.sku='CF-LAT' and v.code='medium'),
    'addOnIds','[]'::jsonb,
    'quantity',1
  ))
));
select pg_sleep(2);
commit;
SQL
)
SCHEDULE_SECOND=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77000000-0000-0000-0000-000000000003","role":"authenticated"}',true);
select public.place_customer_order(jsonb_build_object(
  'clientRequestId','77100000-0000-0000-0000-000000000002',
  'branchId',(select id from public.branches where code='BR-P16-CONC'),
  'fulfillmentType','scheduled',
  'requestedPickupAt',(((now() at time zone 'Asia/Kuala_Lumpur')::date + 1 + time '12:00') at time zone 'Asia/Kuala_Lumpur'),
  'items',jsonb_build_array(jsonb_build_object(
    'itemId',(select id from public.catalogue_items where sku='CF-LAT'),
    'variantId',(select v.id from public.catalogue_item_variants v join public.catalogue_items i on i.id=v.item_id where i.sku='CF-LAT' and v.code='medium'),
    'addOnIds','[]'::jsonb,
    'quantity',1
  ))
));
commit;
SQL
)
run_competing_sessions "phase4-slot" "$SCHEDULE_FIRST" "$SCHEDULE_SECOND" 'pickup|slot|capacity|unavailable|full'

slot_count=$("${PSQL[@]}" -Atc "select count(*) from public.orders where client_request_id in ('77100000-0000-0000-0000-000000000001','77100000-0000-0000-0000-000000000002') and status <> 'cancelled';")
[[ "$slot_count" == "1" ]] || fail "Phase 4 final slot produced $slot_count accepted orders"

# Phase 5: stock is exactly one recipe unit. The first transaction consumes the
# row and remains open; the second must wait for the row lock and then fail the
# non-negative conditional balance update.
INVENTORY_FIRST=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77000000-0000-0000-0000-000000000004","role":"authenticated"}',true);
select public.place_customer_order(jsonb_build_object(
  'clientRequestId','77200000-0000-0000-0000-000000000001',
  'branchId',(select id from public.branches where is_default and is_active limit 1),
  'fulfillmentType','asap',
  'items',jsonb_build_array(jsonb_build_object(
    'itemId',(select catalogue_item_id from public.recipes where name='Phase 1-6 concurrency recipe' and is_active limit 1),
    'addOnIds','[]'::jsonb,
    'quantity',1
  ))
));
select pg_sleep(2);
commit;
SQL
)
INVENTORY_SECOND=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77000000-0000-0000-0000-000000000005","role":"authenticated"}',true);
select public.place_customer_order(jsonb_build_object(
  'clientRequestId','77200000-0000-0000-0000-000000000002',
  'branchId',(select id from public.branches where is_default and is_active limit 1),
  'fulfillmentType','asap',
  'items',jsonb_build_array(jsonb_build_object(
    'itemId',(select catalogue_item_id from public.recipes where name='Phase 1-6 concurrency recipe' and is_active limit 1),
    'addOnIds','[]'::jsonb,
    'quantity',1
  ))
));
commit;
SQL
)
run_competing_sessions "phase5-stock" "$INVENTORY_FIRST" "$INVENTORY_SECOND" 'inventory unavailable|insufficient inventory|stock'

inventory_orders=$("${PSQL[@]}" -Atc "select count(*) from public.orders where client_request_id in ('77200000-0000-0000-0000-000000000001','77200000-0000-0000-0000-000000000002');")
inventory_balance=$("${PSQL[@]}" -Atc "select bi.on_hand_milli from public.branch_inventory bi join public.inventory_items ii on ii.id=bi.inventory_item_id where ii.sku='P16-CONC-STOCK' and bi.branch_id=(select id from public.branches where is_default and is_active limit 1);")
[[ "$inventory_orders" == "1" ]] || fail "Phase 5 final stock produced $inventory_orders accepted orders"
[[ "$inventory_balance" == "0" ]] || fail "Phase 5 final stock balance is $inventory_balance instead of zero"

# Phase 6a: exactly ten points and a ten-point reward. Both sessions redeem the
# same member balance; FOR UPDATE must serialize them so only one can spend it.
REDEEM_FIRST=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77000000-0000-0000-0000-000000000006","role":"authenticated"}',true);
select public.redeem_my_reward((select id from public.reward_catalogue where code='P16_CONC_RM1'));
select pg_sleep(2);
commit;
SQL
)
REDEEM_SECOND=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77000000-0000-0000-0000-000000000006","role":"authenticated"}',true);
select public.redeem_my_reward((select id from public.reward_catalogue where code='P16_CONC_RM1'));
commit;
SQL
)
run_competing_sessions "phase6-points" "$REDEEM_FIRST" "$REDEEM_SECOND" 'insufficient loyalty points'

redeem_count=$("${PSQL[@]}" -Atc "select count(*) from public.loyalty_point_ledger l join public.members m on m.id=l.member_id where m.user_id='77000000-0000-0000-0000-000000000006' and l.event_kind='redeem';")
voucher_count=$("${PSQL[@]}" -Atc "select count(*) from public.member_vouchers mv join public.reward_catalogue r on r.id=mv.reward_id join public.members m on m.id=mv.member_id where r.code='P16_CONC_RM1' and m.user_id='77000000-0000-0000-0000-000000000006' and mv.status='active';")
[[ "$redeem_count" == "1" ]] || fail "Phase 6 concurrent redemption wrote $redeem_count redemption ledger rows"
[[ "$voucher_count" == "1" ]] || fail "Phase 6 concurrent redemption issued $voucher_count active vouchers"

# Phase 6b: two orders compete to consume that one voucher. The winning
# transaction holds the voucher row lock until after placement; the loser must
# revalidate against the committed used state and fail.
VOUCHER_FIRST=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77000000-0000-0000-0000-000000000006","role":"authenticated"}',true);
select public.place_customer_order(jsonb_build_object(
  'clientRequestId','77400000-0000-0000-0000-000000000001',
  'branchId',(select id from public.branches where is_default and is_active limit 1),
  'fulfillmentType','asap',
  'voucherId',(select mv.id from public.member_vouchers mv join public.reward_catalogue r on r.id=mv.reward_id join public.members m on m.id=mv.member_id where r.code='P16_CONC_RM1' and m.user_id='77000000-0000-0000-0000-000000000006' and mv.status='active' limit 1),
  'items',jsonb_build_array(jsonb_build_object(
    'itemId',(select id from public.catalogue_items where sku='CF-LAT'),
    'variantId',(select v.id from public.catalogue_item_variants v join public.catalogue_items i on i.id=v.item_id where i.sku='CF-LAT' and v.code='medium'),
    'addOnIds','[]'::jsonb,
    'quantity',1
  ))
));
select pg_sleep(2);
commit;
SQL
)
VOUCHER_SECOND=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77000000-0000-0000-0000-000000000006","role":"authenticated"}',true);
select public.place_customer_order(jsonb_build_object(
  'clientRequestId','77400000-0000-0000-0000-000000000002',
  'branchId',(select id from public.branches where is_default and is_active limit 1),
  'fulfillmentType','asap',
  'voucherId',(select mv.id from public.member_vouchers mv join public.reward_catalogue r on r.id=mv.reward_id join public.members m on m.id=mv.member_id where r.code='P16_CONC_RM1' and m.user_id='77000000-0000-0000-0000-000000000006' limit 1),
  'items',jsonb_build_array(jsonb_build_object(
    'itemId',(select id from public.catalogue_items where sku='CF-LAT'),
    'variantId',(select v.id from public.catalogue_item_variants v join public.catalogue_items i on i.id=v.item_id where i.sku='CF-LAT' and v.code='medium'),
    'addOnIds','[]'::jsonb,
    'quantity',1
  ))
));
commit;
SQL
)
run_competing_sessions "phase6-voucher" "$VOUCHER_FIRST" "$VOUCHER_SECOND" 'voucher is not active|voucher is no longer available|voucher.*used'

voucher_orders=$("${PSQL[@]}" -Atc "select count(*) from public.orders where client_request_id in ('77400000-0000-0000-0000-000000000001','77400000-0000-0000-0000-000000000002');")
voucher_apps=$("${PSQL[@]}" -Atc "select count(*) from public.voucher_order_applications va join public.orders o on o.id=va.order_id where o.client_request_id in ('77400000-0000-0000-0000-000000000001','77400000-0000-0000-0000-000000000002');")
[[ "$voucher_orders" == "1" ]] || fail "Phase 6 voucher contention produced $voucher_orders accepted orders"
[[ "$voucher_apps" == "1" ]] || fail "Phase 6 voucher contention produced $voucher_apps application snapshots"

echo "Phase 4-6 true concurrency regressions: PASS"
