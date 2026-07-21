import { FIXTURE_TODAY, PREVIEW_SALES_BY_POINT } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminBranchComparePage() {
  const totalSen = PREVIEW_SALES_BY_POINT.reduce((s, p) => s + p.sen, 0);

  return (
    <AdminPageShell
      pageId="admin-branch-compare"
      title="Branch comparison"
      hint="Single branch sample — sales-point split for Main Café today."
    >
      <div className="metric-grid metric-grid--compact">
        <article className="metric-card">
          <p className="metric-card__label">Net sales (today)</p>
          <p className="metric-card__value">{formatRmFromSen(FIXTURE_TODAY.netSalesSen)}</p>
        </article>
        <article className="metric-card">
          <p className="metric-card__label">Orders</p>
          <p className="metric-card__value">{FIXTURE_TODAY.orders}</p>
        </article>
        <article className="metric-card">
          <p className="metric-card__label">AOV</p>
          <p className="metric-card__value">{formatRmFromSen(FIXTURE_TODAY.aovSen)}</p>
        </article>
      </div>

      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Branch</th>
            <th>Sales point</th>
            <th>Net sales</th>
            <th>Share</th>
            <th>Orders (sample)</th>
          </tr>
        </thead>
        <tbody>
          {PREVIEW_SALES_BY_POINT.map((row) => (
            <tr key={row.point}>
              <td>Main Café</td>
              <td>{row.point}</td>
              <td>{formatRmFromSen(row.sen)}</td>
              <td>{totalSen ? `${Math.round((row.sen / totalSen) * 100)}%` : '—'}</td>
              <td>{row.point === 'Main Counter' ? 8 : 5}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
