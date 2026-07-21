import { PREVIEW_TRANSACTIONS } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminVoidsReportPage() {
  const rows = PREVIEW_TRANSACTIONS.filter((t) => t.status === 'Refunded' || t.status === 'Voided' || t.refundSen > 0);

  return (
    <AdminPageShell
      pageId="admin-voids-report"
      title="Voids and refunds"
      hint="Sensitive actions require approver audit when API is connected."
    >
      {rows.length === 0 ? (
        <div className="empty-state">
          <h2 className="admin-section-title">No voids in sample</h2>
          <p>Try widening the date filter when live data is available.</p>
        </div>
      ) : (
        <table className="data-table admin-table">
          <thead>
            <tr>
              <th>Order</th>
              <th>When</th>
              <th>Staff</th>
              <th>Status</th>
              <th>Refund</th>
              <th>Reason (preview)</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((t) => (
              <tr key={t.order}>
                <td>{t.order}</td>
                <td>{t.when}</td>
                <td>{t.staff}</td>
                <td>{t.status}</td>
                <td>{formatRmFromSen(t.refundSen)}</td>
                <td>Customer changed mind — sample</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </AdminPageShell>
  );
}
