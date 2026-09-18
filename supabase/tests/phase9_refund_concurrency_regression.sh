#!/usr/bin/env bash
set -euo pipefail

DB_URL="${SUPABASE_DB_URL:-postgresql://postgres:postgres@127.0.0.1:54322/postgres}"
PSQL=(psql "$DB_URL" -X -v ON_ERROR_STOP=1 -q)
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  echo "Phase 9 refund contention regression failed: $*" >&2
  for log in "$TMP_DIR"/*.log; do
    [[ -f "$log" ]] || continue
    echo "--- $log ---" >&2
    cat "$log" >&2
  done
  exit 1
}

"${PSQL[@]}" -f supabase/tests/phase9_refund_concurrency_setup.sql

FIRST=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"99300000-0000-0000-0000-000000000002","role":"authenticated"}',true);
select public.request_external_refund(jsonb_build_object(
  'orderId','99310000-0000-0000-0000-000000000001',
  'idempotencyKey','99313000-0000-0000-0000-000000000001',
  'amountSen',600,
  'reason','concurrent refund A'
));
select pg_sleep(2);
commit;
SQL
)

SECOND=$(cat <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"99300000-0000-0000-0000-000000000002","role":"authenticated"}',true);
select public.request_external_refund(jsonb_build_object(
  'orderId','99310000-0000-0000-0000-000000000001',
  'idempotencyKey','99313000-0000-0000-0000-000000000002',
  'amountSen',600,
  'reason','concurrent refund B'
));
commit;
SQL
)

set +e
"${PSQL[@]}" >"$TMP_DIR/first.log" 2>&1 <<<"$FIRST" &
first_pid=$!
sleep 0.35
"${PSQL[@]}" >"$TMP_DIR/second.log" 2>&1 <<<"$SECOND" &
second_pid=$!
wait "$first_pid"; first_status=$?
wait "$second_pid"; second_status=$?
set -e

successes=0
[[ "$first_status" -eq 0 ]] && successes=$((successes + 1))
[[ "$second_status" -eq 0 ]] && successes=$((successes + 1))
[[ "$successes" -eq 1 ]] || fail "expected exactly one refund reservation to succeed; statuses were $first_status/$second_status"

if [[ "$first_status" -ne 0 ]]; then
  grep -qi "exceeds refundable" "$TMP_DIR/first.log" || fail "first loser did not fail on refundable balance"
fi
if [[ "$second_status" -ne 0 ]]; then
  grep -qi "exceeds refundable" "$TMP_DIR/second.log" || fail "second loser did not fail on refundable balance"
fi

refund_count=$("${PSQL[@]}" -Atc "select count(*) from public.payment_refunds where order_id='99310000-0000-0000-0000-000000000001'::uuid and state in ('requested','processing','succeeded');")
reserved_sen=$("${PSQL[@]}" -Atc "select coalesce(sum(amount_sen),0) from public.payment_refunds where order_id='99310000-0000-0000-0000-000000000001'::uuid and state in ('requested','processing','succeeded');")
payment_projection=$("${PSQL[@]}" -Atc "select payment_state||':'||refunded_sen::text from public.orders where id='99310000-0000-0000-0000-000000000001'::uuid;")

[[ "$refund_count" == "1" ]] || fail "expected one reserved refund, got $refund_count"
[[ "$reserved_sen" == "600" ]] || fail "expected exactly 600 sen reserved, got $reserved_sen"
[[ "$payment_projection" == "paid:0" ]] || fail "requested refund changed succeeded-refund projection: $payment_projection"

echo "Phase 9 true refund contention: PASS"
