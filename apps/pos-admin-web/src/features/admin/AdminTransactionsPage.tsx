import { useMemo, useState } from 'react';
import { PREVIEW_TRANSACTIONS, type PreviewTxn } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminTransactionsPage() {
  const [selected, setSelected] = useState<PreviewTxn | null>(null);
  const rows = useMemo(() => PREVIEW_TRANSACTIONS, []);

  return (
    <AdminPageShell
      pageId="admin-transactions-report"
      title="Transaction report"
      hint="Order-level detail — select a row for breakdown."
    >
      <div className="admin-filters">
        <label>
          From
          <input type="date" defaultValue="2026-07-21" />
        </label>
        <label>
          Sales point
          <select defaultValue="all">
            <option value="all">All</option>
            <option value="main">Main Counter</option>
            <option value="snack">Snack Station</option>
          </select>
        </label>
      </div>

      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Order</th>
            <th>When</th>
            <th>Staff</th>
            <th>Sales point</th>
            <th>Method</th>
            <th>Total</th>
            <th>Status</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.order}>
              <td>{row.order}</td>
              <td>{row.when}</td>
              <td>{row.staff}</td>
              <td>{row.salesPoint}</td>
              <td>{row.method}</td>
              <td>{formatRmFromSen(row.totalSen)}</td>
              <td>{row.status}</td>
              <td>
                <button type="button" className="btn-secondary btn-sm" onClick={() => setSelected(row)}>
                  Detail
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {selected && (
        <>
          <button type="button" className="admin-drawer-backdrop" aria-label="Close detail" onClick={() => setSelected(null)} />
          <aside className="admin-drawer" aria-labelledby="txn-detail-title">
            <h2 id="txn-detail-title" className="admin-section-title">
              Order {selected.order}
            </h2>
            <dl className="admin-dl">
              <dt>When</dt>
              <dd>{selected.when}</dd>
              <dt>Staff</dt>
              <dd>{selected.staff}</dd>
              <dt>Member</dt>
              <dd>{selected.member ?? 'Guest'}</dd>
              <dt>Payment</dt>
              <dd>{selected.method}</dd>
              <dt>Discount</dt>
              <dd>{formatRmFromSen(selected.discountSen)}</dd>
              <dt>Refund</dt>
              <dd>{formatRmFromSen(selected.refundSen)}</dd>
              <dt>Net total</dt>
              <dd>{formatRmFromSen(selected.totalSen)}</dd>
              <dt>Status</dt>
              <dd>{selected.status}</dd>
            </dl>
            <div className="admin-drawer__actions">
              <button type="button" className="btn-primary" onClick={() => setSelected(null)}>
                Close
              </button>
            </div>
          </aside>
        </>
      )}
    </AdminPageShell>
  );
}
