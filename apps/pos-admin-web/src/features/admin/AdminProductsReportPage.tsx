import { PREVIEW_MENU, PREVIEW_TRANSACTIONS } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

/** Sample product mix — revenue estimated from menu list prices × synthetic qty. */
const PRODUCT_ROWS = PREVIEW_MENU.map((item, i) => ({
  ...item,
  qty: 12 - i,
  revenueSen: item.priceSen * (12 - i),
}));

export function AdminProductsReportPage() {
  const categoryTotals = PREVIEW_MENU.reduce<Record<string, number>>((acc, item) => {
    acc[item.category] = (acc[item.category] ?? 0) + item.priceSen;
    return acc;
  }, {});

  return (
    <AdminPageShell
      pageId="admin-products-report"
      title="Product performance"
      hint={`${PREVIEW_TRANSACTIONS.length} orders in transaction fixture — product ranks are illustrative.`}
    >
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Product</th>
            <th>Category</th>
            <th>SKU</th>
            <th>Qty (sample)</th>
            <th>Revenue (sample)</th>
            <th>Available</th>
          </tr>
        </thead>
        <tbody>
          {PRODUCT_ROWS.map((row) => (
            <tr key={row.id}>
              <td>{row.name}</td>
              <td>{row.category}</td>
              <td>{row.sku}</td>
              <td>{row.qty}</td>
              <td>{formatRmFromSen(row.revenueSen)}</td>
              <td>{row.available ? 'Yes' : 'Sold out'}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <h2 className="admin-section-title admin-section-title--spaced">Category mix (list price basis)</h2>
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Category</th>
            <th>Sample value</th>
          </tr>
        </thead>
        <tbody>
          {Object.entries(categoryTotals).map(([cat, sen]) => (
            <tr key={cat}>
              <td>{cat}</td>
              <td>{formatRmFromSen(sen)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
