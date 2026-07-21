import { PREVIEW_CATEGORIES, PREVIEW_MENU } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminCategoriesPage() {
  const counts = PREVIEW_CATEGORIES.filter((c) => c !== 'All').map((cat) => ({
    category: cat,
    count: PREVIEW_MENU.filter((m) => m.category === cat).length,
  }));

  return (
    <AdminPageShell pageId="admin-categories" title="Categories" hint="POS category rail order — preview only.">
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Category</th>
            <th>Items</th>
            <th>Visible on POS</th>
          </tr>
        </thead>
        <tbody>
          {counts.map((row) => (
            <tr key={row.category}>
              <td>{row.category}</td>
              <td>{row.count}</td>
              <td>Yes</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
