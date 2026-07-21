import { PREVIEW_ORG } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

/**
 * Dedicated sales-point directory for closure-gate evidence.
 * Fixture-only — no API writes.
 */
export function AdminSalesPointsPage() {
  const rows = PREVIEW_ORG.branches.flatMap((b) =>
    b.salesPoints.map((sp) => ({
      branch: b.name,
      branchCode: b.code,
      ...sp,
    })),
  );

  return (
    <AdminPageShell
      pageId="admin-sales-points"
      title="Sales points"
      hint="Directory of counters and kiosks per branch. Sample fixture — Team 2 persists sales-point records."
    >
      <table className="data-table admin-table">
        <caption className="visually-hidden">Sales points by branch</caption>
        <thead>
          <tr>
            <th>Branch</th>
            <th>Sales point</th>
            <th>Code</th>
            <th>Terminals</th>
            <th>Inventory pool</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id}>
              <td>
                {row.branch} <span className="branch-code">{row.branchCode}</span>
              </td>
              <td>{row.name}</td>
              <td>{row.code}</td>
              <td>{row.terminals.join(', ')}</td>
              <td>{row.inventory}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <p className="form-hint" role="note">
        Simulated view only — create/edit/delete requires Team 2 API.
      </p>
    </AdminPageShell>
  );
}
