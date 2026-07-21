import { PREVIEW_SHIFT_ROWS, PREVIEW_VARIANCE_THRESHOLD_SEN } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminShiftCashReportPage() {
  return (
    <AdminPageShell
      pageId="admin-shift-cash-report"
      title="Shift and cash variance"
      hint={`Variance threshold sample: ${formatRmFromSen(PREVIEW_VARIANCE_THRESHOLD_SEN)}`}
    >
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Staff</th>
            <th>Terminal</th>
            <th>Sales point</th>
            <th>Status</th>
            <th>Float</th>
            <th>Cash sales</th>
            <th>Expected</th>
            <th>Actual</th>
            <th>Variance</th>
          </tr>
        </thead>
        <tbody>
          {PREVIEW_SHIFT_ROWS.map((row) => (
            <tr key={row.id}>
              <td>{row.staff}</td>
              <td>{row.terminal}</td>
              <td>{row.salesPoint}</td>
              <td>{row.status}</td>
              <td>{formatRmFromSen(row.openingFloatSen)}</td>
              <td>{formatRmFromSen(row.cashSalesSen)}</td>
              <td>{row.expectedSen !== null ? formatRmFromSen(row.expectedSen) : '—'}</td>
              <td>{row.actualSen !== null ? formatRmFromSen(row.actualSen) : '—'}</td>
              <td>
                {row.varianceSen !== null ? (
                  <span className={row.varianceSen < 0 ? 'variance-neg' : 'variance-pos'}>
                    {formatRmFromSen(row.varianceSen)}
                  </span>
                ) : (
                  '—'
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
