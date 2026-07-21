import { useState } from 'react';
import { PREVIEW_SALES_ROWS } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminSalesReportPage() {
  const [from, setFrom] = useState('2026-07-21');
  const [to, setTo] = useState('2026-07-21');
  const [point, setPoint] = useState('all');
  const pointLabel =
    point === 'main' ? 'Main Counter' : point === 'snack' ? 'Snack Station' : 'All sales points';

  return (
    <AdminPageShell
      pageId="admin-sales-report"
      title="Sales report"
      hint={`Sample transactions · ${from} → ${to} · ${pointLabel} — export API pending.`}
      actions={
        <button type="button" className="btn-secondary" disabled title="Team 2 API pending">
          Export CSV
        </button>
      }
    >
      <div className="admin-filters">
        <label>
          From
          <input type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
        </label>
        <label>
          To
          <input type="date" value={to} onChange={(e) => setTo(e.target.value)} />
        </label>
        <label>
          Sales point
          <select value={point} onChange={(e) => setPoint(e.target.value)}>
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
          </tr>
        </thead>
        <tbody>
          {PREVIEW_SALES_ROWS.map((row) => (
            <tr key={row.order}>
              <td>{row.order}</td>
              <td>{row.when}</td>
              <td>{row.staff}</td>
              <td>{row.salesPoint}</td>
              <td>{row.method}</td>
              <td>{formatRmFromSen(row.totalSen)}</td>
              <td>{row.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
