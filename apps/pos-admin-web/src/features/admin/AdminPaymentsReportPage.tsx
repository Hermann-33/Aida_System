import { useMemo } from 'react';
import { PREVIEW_TRANSACTIONS } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminPaymentsReportPage() {
  const byMethod = useMemo(() => {
    const methods = ['Cash', 'Card', 'E-wallet'] as const;
    return methods.map((method) => {
      const rows = PREVIEW_TRANSACTIONS.filter((t) => t.status === 'Completed' && t.method === method);
      const totalSen = rows.reduce((s, t) => s + t.totalSen, 0);
      return { method, count: rows.length, totalSen };
    });
  }, []);

  const refunded = PREVIEW_TRANSACTIONS.filter((t) => t.refundSen > 0);

  return (
    <AdminPageShell
      pageId="admin-payments-report"
      title="Payment reconciliation"
      hint="Method totals from completed preview transactions."
    >
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Method</th>
            <th>Completed orders</th>
            <th>Net captured</th>
          </tr>
        </thead>
        <tbody>
          {byMethod.map((row) => (
            <tr key={row.method}>
              <td>{row.method}</td>
              <td>{row.count}</td>
              <td>{formatRmFromSen(row.totalSen)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <h2 className="admin-section-title admin-section-title--spaced">Refunds pending settlement</h2>
      {refunded.length === 0 ? (
        <p className="empty-state">No refunds in sample period.</p>
      ) : (
        <table className="data-table admin-table">
          <thead>
            <tr>
              <th>Order</th>
              <th>Method</th>
              <th>Refund amount</th>
            </tr>
          </thead>
          <tbody>
            {refunded.map((t) => (
              <tr key={t.order}>
                <td>{t.order}</td>
                <td>{t.method}</td>
                <td>{formatRmFromSen(t.refundSen)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </AdminPageShell>
  );
}
