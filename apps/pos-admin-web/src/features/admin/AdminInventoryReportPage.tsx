import { PREVIEW_MENU, PREVIEW_ORG } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

const STOCK_ROWS = PREVIEW_MENU.map((item) => ({
  sku: item.sku,
  name: item.name,
  onHand: item.available ? 24 - item.id.length : 0,
  par: 12,
  inventory: PREVIEW_ORG.inventoryCode,
}));

export function AdminInventoryReportPage() {
  const low = STOCK_ROWS.filter((r) => r.onHand > 0 && r.onHand <= r.par);

  return (
    <AdminPageShell
      pageId="admin-inventory-report"
      title="Inventory report"
      hint={`Shared inventory ${PREVIEW_ORG.inventoryCode} across Main Counter and Snack Station.`}
    >
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>SKU</th>
            <th>Item</th>
            <th>On hand (sample)</th>
            <th>Par</th>
            <th>Inventory pool</th>
          </tr>
        </thead>
        <tbody>
          {STOCK_ROWS.map((row) => (
            <tr key={row.sku}>
              <td>{row.sku}</td>
              <td>{row.name}</td>
              <td>{row.onHand}</td>
              <td>{row.par}</td>
              <td>{row.inventory}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <h2 className="admin-section-title admin-section-title--spaced">Low stock alerts</h2>
      {low.length === 0 ? (
        <p className="form-hint">No low-stock rows in sample.</p>
      ) : (
        <ul className="admin-alerts admin-alerts--inline">
          {low.map((r) => (
            <li key={r.sku}>
              {r.name} ({r.onHand} left)
            </li>
          ))}
        </ul>
      )}
    </AdminPageShell>
  );
}
