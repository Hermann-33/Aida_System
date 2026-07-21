import { useState } from 'react';
import type { EmployeeIdentity, ShiftSummary, TerminalLocation } from '../../auth/types';
import type { OrderType, PreviewMember } from '../../preview/fixtures/catalog';
import { PREVIEW_REWARD_RULES } from '../../preview/fixtures/catalog';
import { isUiPreviewMode } from '../../preview/uiPreviewMode';
import type { CartLine } from './cartTypes';
import { formatRmFromSen } from '../../shared/formatting/money';
import { formatKlDateTime } from '../../shared/formatting/datetime';
import {
  buildPreviewReceipt,
  type PaymentMethod,
  type PreviewSaleReceipt,
} from './paymentReceipt';

interface Props {
  lines: CartLine[];
  orderType: OrderType;
  member: PreviewMember | null;
  employee: EmployeeIdentity;
  location: TerminalLocation;
  shift: ShiftSummary;
  discountSen: number;
  rewardLabel?: string;
  onPaid: (receipt: PreviewSaleReceipt) => void;
  onCancel: () => void;
}

type NonCashPhase =
  | 'idle'
  | 'awaiting'
  | 'processing'
  | 'approved'
  | 'declined'
  | 'timeout'
  | 'unknown';

const METHOD_LABELS: Record<PaymentMethod, string> = {
  cash: 'Cash',
  card: 'Card',
  ewallet: 'E-wallet',
  student_wallet: 'Student wallet',
};

const ORDER_TYPE_LABEL: Record<OrderType, string> = {
  dine_in: 'Dine-in',
  takeaway: 'Takeaway',
  pickup: 'Pickup',
};

const QUICK_TENDERS_SEN = [1000, 2000, 5000, 10000];

export function PaymentPanel({
  lines,
  orderType,
  member,
  employee,
  location,
  shift,
  discountSen,
  rewardLabel,
  onPaid,
  onCancel,
}: Props) {
  const [method, setMethod] = useState<PaymentMethod>('cash');
  const [cashReceived, setCashReceived] = useState('');
  const [phase, setPhase] = useState<NonCashPhase>('idle');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const previewMode = isUiPreviewMode();

  const draft = buildPreviewReceipt({
    lines,
    orderType,
    method,
    employee,
    location,
    shift,
    member,
    discountSen,
    rewardLabel,
  });
  const totalSen = draft.totalSen;
  const cashSen = Math.round(Number(cashReceived) * 100) || 0;
  const changeSen = cashSen - totalSen;
  const insufficient = method === 'cash' && cashSen > 0 && cashSen < totalSen;

  function pay(extra: Partial<PreviewSaleReceipt>) {
    if (submitting) return;
    setSubmitting(true);
    onPaid({
      ...buildPreviewReceipt({
        lines,
        orderType,
        method,
        employee,
        location,
        shift,
        member,
        discountSen,
        rewardLabel,
        tenderSen: extra.tenderSen,
        changeSen: extra.changeSen,
        providerRef: extra.providerRef,
      }),
      printStatus: 'printed',
      ...extra,
    });
  }

  function completeCash() {
    setError('');
    if (cashSen < totalSen) {
      setError('Cash received is less than total due.');
      return;
    }
    pay({ tenderSen: cashSen, changeSen });
  }

  function startNonCash() {
    if (submitting || phase === 'processing' || phase === 'awaiting') return;
    setError('');
    setPhase('awaiting');
    window.setTimeout(() => setPhase('processing'), 500);
    window.setTimeout(() => {
      const ref = `PREV-${Date.now().toString(36).toUpperCase()}`;
      setPhase('approved');
      pay({ providerRef: ref });
    }, 1500);
  }

  return (
    <section className="payment-panel" aria-labelledby="payment-title" data-page="pos-payment">
      <h3 id="payment-title">Payment</h3>
      <p className="payment-preview-notice" role="status">
        {previewMode
          ? 'UI PREVIEW — SAMPLE DATA · sales API not called'
          : 'UI Preview — POS sales API disabled'}
      </p>

      <fieldset className="payment-methods">
        <legend>Method</legend>
        {(['cash', 'card', 'ewallet'] as PaymentMethod[]).map((key) => (
          <label key={key} className={`payment-method ${method === key ? 'payment-method--active' : ''}`}>
            <input
              type="radio"
              name="payment-method"
              value={key}
              checked={method === key}
              disabled={submitting}
              onChange={() => {
                setMethod(key);
                setPhase('idle');
              }}
            />
            {METHOD_LABELS[key]}
          </label>
        ))}
        <label className="payment-method payment-method--disabled">
          <input type="radio" name="payment-method" disabled />
          Student wallet — pending integration decision
        </label>
      </fieldset>

      <p className="payment-total">Total due: {formatRmFromSen(totalSen)}</p>
      {discountSen > 0 && (
        <p className="form-hint">Reward discount: −{formatRmFromSen(discountSen)}</p>
      )}

      {method === 'cash' && (
        <div className="cash-tender">
          <label htmlFor="cash-received">Cash received (RM)</label>
          <input
            id="cash-received"
            type="number"
            min="0"
            step="0.01"
            value={cashReceived}
            disabled={submitting}
            onChange={(e) => setCashReceived(e.target.value)}
          />
          <div className="cash-tender__quick">
            <button
              type="button"
              className="btn-secondary"
              disabled={submitting}
              onClick={() => setCashReceived((totalSen / 100).toFixed(2))}
            >
              Exact
            </button>
            {QUICK_TENDERS_SEN.map((sen) => (
              <button
                key={sen}
                type="button"
                className="btn-secondary"
                disabled={submitting}
                onClick={() => setCashReceived((sen / 100).toFixed(2))}
              >
                {formatRmFromSen(sen)}
              </button>
            ))}
          </div>
          {cashSen > 0 && (
            <p className={insufficient ? 'form-error' : 'form-hint'} role={insufficient ? 'alert' : undefined}>
              {insufficient
                ? `Insufficient cash — short ${formatRmFromSen(totalSen - cashSen)}`
                : `Change due: ${formatRmFromSen(changeSen)}`}
            </p>
          )}
        </div>
      )}

      {(method === 'card' || method === 'ewallet') && (
        <div className="noncash-panel" role="status">
          <p>
            External terminal:{' '}
            <strong>{phase === 'idle' ? 'Ready' : phase}</strong>
          </p>
          <p className="form-hint">No card number or CVV is collected.</p>
          <div className="payment-actions">
            <button type="button" className="btn-secondary" disabled={submitting} onClick={() => setPhase('declined')}>
              Simulate decline
            </button>
            <button type="button" className="btn-secondary" disabled={submitting} onClick={() => setPhase('timeout')}>
              Simulate timeout
            </button>
            <button type="button" className="btn-secondary" disabled={submitting} onClick={() => setPhase('unknown')}>
              Simulate unknown
            </button>
          </div>
          {(phase === 'declined' || phase === 'timeout' || phase === 'unknown') && (
            <p className="form-error" role="alert">
              {phase === 'unknown'
                ? 'Unknown result — check status before retry (Team 2).'
                : `${phase} — resolve before safe retry.`}
            </p>
          )}
        </div>
      )}

      {error && <p className="form-error" role="alert">{error}</p>}

      <div className="payment-actions">
        <button type="button" className="btn-secondary" onClick={onCancel} disabled={phase === 'processing'}>
          Back
        </button>
        {method === 'cash' ? (
          <button
            type="button"
            className="btn-primary"
            disabled={lines.length === 0 || submitting || cashSen < totalSen}
            onClick={completeCash}
          >
            Confirm payment
          </button>
        ) : phase === 'declined' || phase === 'timeout' || phase === 'unknown' ? (
          <button type="button" className="btn-primary" onClick={() => setPhase('idle')}>
            Check status / allow retry
          </button>
        ) : (
          <button
            type="button"
            className="btn-primary"
            disabled={lines.length === 0 || submitting || phase === 'processing' || phase === 'awaiting'}
            onClick={startNonCash}
          >
            {phase === 'processing' || phase === 'awaiting' ? 'Processing…' : 'Charge terminal (preview)'}
          </button>
        )}
      </div>
    </section>
  );
}

export function CompletedSaleReceipt({ receipt }: { receipt: PreviewSaleReceipt }) {
  return (
    <section className="payment-panel payment-panel--receipt" aria-labelledby="receipt-title" data-page="pos-receipt">
      <h3 id="receipt-title">Sale complete</h3>
      <p className="form-hint">Preview receipt — cart locked · Pay disabled · no second payment.</p>
      <dl className="receipt-details">
        <div><dt>Order</dt><dd>{receipt.orderNumber}</dd></div>
        <div><dt>When</dt><dd>{formatKlDateTime(receipt.dateTime)}</dd></div>
        <div><dt>Employee</dt><dd>{receipt.employeeName} ({receipt.employeeRole})</dd></div>
        <div><dt>Branch</dt><dd>{receipt.branchCode}</dd></div>
        <div><dt>Sales point</dt><dd>{receipt.salesPointCode}</dd></div>
        <div><dt>Terminal</dt><dd>{receipt.terminalCode}</dd></div>
        <div><dt>Shift</dt><dd>{receipt.shiftId} · {receipt.shiftStatus}</dd></div>
        <div><dt>Order type</dt><dd>{ORDER_TYPE_LABEL[receipt.orderType]}</dd></div>
        <div><dt>Method</dt><dd>{METHOD_LABELS[receipt.method]}</dd></div>
        {receipt.tenderSen != null && (
          <>
            <div><dt>Tendered</dt><dd>{formatRmFromSen(receipt.tenderSen)}</dd></div>
            <div><dt>Change</dt><dd>{formatRmFromSen(receipt.changeSen || 0)}</dd></div>
          </>
        )}
        {receipt.providerRef && <div><dt>Provider ref</dt><dd>{receipt.providerRef}</dd></div>}
        {receipt.memberName && <div><dt>Member</dt><dd>{receipt.memberName}</dd></div>}
        {receipt.rewardLabel && <div><dt>Reward</dt><dd>{receipt.rewardLabel}</dd></div>}
        {receipt.pointsBefore != null && (
          <div>
            <dt>Aida Points</dt>
            <dd>
              {receipt.pointsBefore} → {receipt.pointsAfter}
              {receipt.pointsEarned != null ? ` (+${receipt.pointsEarned}, RM 1 = 1 pt)` : ''}
            </dd>
          </div>
        )}
        {receipt.stampsBefore != null && (
          <div>
            <dt>Stamps</dt>
            <dd>
              {receipt.stampsBefore} → {receipt.stampsAfter} / {PREVIEW_REWARD_RULES.stampsForFreeDrink}
            </dd>
          </div>
        )}
        <div><dt>Print</dt><dd>{receipt.printStatus}</dd></div>
      </dl>
      <ul className="receipt-lines">
        {receipt.lines.map((line) => (
          <li key={line.id}>
            {line.qty}× {line.name}
            {line.modifierSummary && <span className="receipt-mod"> ({line.modifierSummary})</span>}
            {line.note && <span className="receipt-mod"> — {line.note}</span>}
            <span className="receipt-line-price">{formatRmFromSen(line.unitPriceSen * line.qty)}</span>
          </li>
        ))}
      </ul>
      <p>Subtotal: {formatRmFromSen(receipt.subtotalSen)}</p>
      {receipt.discountSen > 0 && <p>Discounts/rewards: −{formatRmFromSen(receipt.discountSen)}</p>}
      <p className="receipt-total">Total: {formatRmFromSen(receipt.totalSen)}</p>
    </section>
  );
}
