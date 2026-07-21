import { PREVIEW_MENU, PREVIEW_ORG } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminInventoryStockPage() {
  return (
    <AdminPageShell
      pageId="admin-inventory-stock"
      title="Stock on hand"
      hint={`Pool ${PREVIEW_ORG.inventoryCode} — shared across sales points.`}
    >
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>SKU</th>
            <th>Item</th>
            <th>On hand</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {PREVIEW_MENU.map((item) => (
            <tr key={item.id}>
              <td>{item.sku}</td>
              <td>{item.name}</td>
              <td>{item.available ? 18 : 0}</td>
              <td>
                {item.available ? (
                  <span className="status-pill status-pill--ok">In stock</span>
                ) : (
                  <span className="status-pill status-pill--warn">Sold out</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
