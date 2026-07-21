import { Link } from 'react-router-dom';
import { useState } from 'react';
import { PREVIEW_MENU, type PreviewMenuItem } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminMenuPage() {
  const [items] = useState(PREVIEW_MENU);

  return (
    <AdminPageShell
      pageId="admin-menu"
      title="Menu management"
      hint="Open an item to edit base price and availability."
    >
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>SKU</th>
            <th>Category</th>
            <th>Price</th>
            <th>Route</th>
            <th>Available</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {items.map((item) => (
            <tr key={item.id}>
              <td>{item.name}</td>
              <td>{item.sku}</td>
              <td>{item.category}</td>
              <td>{formatRmFromSen(item.priceSen)}</td>
              <td>{item.route}</td>
              <td>{item.available ? 'Yes' : 'No'}</td>
              <td>
                <Link to={`/admin/catalogue/menu/${item.id}`} className="btn-secondary btn-sm">
                  Edit
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {items.length === 0 && (
        <div className="empty-state">
          <h2 className="admin-section-title">No menu items</h2>
          <p>Publish a menu when catalogue API is ready.</p>
        </div>
      )}
    </AdminPageShell>
  );
}

export function findPreviewMenuItem(id: string): PreviewMenuItem | undefined {
  return PREVIEW_MENU.find((i) => i.id === id);
}
