#!/usr/bin/env bash
set -euo pipefail

DB_URL="${SUPABASE_DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
PSQL=(psql "$DB_URL" -X -v ON_ERROR_STOP=1 -q)
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "Phase 7 promotion concurrency regression failed: $*" >&2
  for log in "$TMP_DIR"/*.log; do
    [[ -f "$log" ]] || continue
    echo "--- $log ---" >&2
    cat "$log" >&2
  done
  exit 1
}

"${PSQL[@]}" -f supabase/tests/phase7_promotion_concurrency_setup.sql

FIRST=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77700000-0000-0000-0000-000000000001","role":"authenticated"}',true);
select public.place_customer_order(jsonb_build_object(
  'clientRequestId','77710000-0000-0000-0000-000000000001',
  'branchId',(select id from public.branches where is_default and is_active limit 1),
  'fulfillmentType','asap',
  'items',jsonb_build_array(jsonb_build_object(
    'itemId',(select id from public.catalogue_items where sku='FD-MUF'),
    'addOnIds','[]'::jsonb,
    'quantity',1
  ))
));
select pg_sleep(2);
commit;
SQL
)

SECOND=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"77700000-0000-0000-0000-000000000002","role":"authenticated"}',true);
select public.place_customer_order(jsonb_build_object(
  'clientRequestId','77710000-0000-0000-0000-000000000002',
  'branchId',(select id from public.branches where is_default and is_active limit 1),
  'fulfillmentType','asap',
  'items',jsonb_build_array(jsonb_build_object(
    'itemId',(select id from public.catalogue_items where sku='FD-MUF'),
    'addOnIds','[]'::jsonb,
    'quantity',1
  ))
));
commit;
SQL
)

set +e
"${PSQL[@]}" >"$TMP_DIR/first.log" 2>&1 <<<"$FIRST" &
first_pid=$!
sleep 0.4
"${PSQL[@]}" >"$TMP_DIR/second.log" 2>&1 <<<"$SECOND" &
second_pid=$!
wait "$first_pid"; first_status=$?
wait "$second_pid"; second_status=$?
set -e

[[ "$first_status" -eq 0 ]] || fail "first order failed"
[[ "$second_status" -eq 0 ]] || fail "second order failed instead of falling back to undiscounted pricing"

order_count=$("${PSQL[@]}" -Atc "select count(*) from public.orders where client_request_id in ('77710000-0000-0000-0000-000000000001','77710000-0000-0000-0000-000000000002');")
application_count=$("${PSQL[@]}" -Atc "select count(*) from public.promotion_order_applications a join public.promotions p on p.id=a.promotion_id where p.code='P7_CONC_LAST_USE';")
discounted_count=$("${PSQL[@]}" -Atc "select count(*) from public.orders where client_request_id in ('77710000-0000-0000-0000-000000000001','77710000-0000-0000-0000-000000000002') and discount_sen=100;")
undiscounted_count=$("${PSQL[@]}" -Atc "select count(*) from public.orders where client_request_id in ('77710000-0000-0000-0000-000000000001','77710000-0000-0000-0000-000000000002') and discount_sen=0;")

[[ "$order_count" == "2" ]] || fail "expected two accepted orders, got $order_count"
[[ "$application_count" == "1" ]] || fail "global usage limit produced $application_count applications"
[[ "$discounted_count" == "1" ]] || fail "expected exactly one discounted order, got $discounted_count"
[[ "$undiscounted_count" == "1" ]] || fail "expected exactly one undiscounted fallback order, got $undiscounted_count"

echo "Phase 7 final promotion usage contention: PASS"
