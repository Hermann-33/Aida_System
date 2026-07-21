import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { PREVIEW_MODIFIER_GROUPS } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { findPreviewMenuItem } from './AdminMenuPage';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminMenuEditorPage() {
  const { id = '' } = useParams();
  const item = findPreviewMenuItem(id);
  const [priceSen, setPriceSen] = useState(item?.priceSen ?? 0);
  const [available, setAvailable] = useState(item?.available ?? true);

  if (!item) {
    return (
      <AdminPageShell pageId="admin-menu-editor" title="Menu item editor" hint="Item not found in preview catalogue.">
        <div className="empty-state">
          <p>Unknown item id: {id}</p>
          <Link to="/admin/catalogue/menu" className="btn-secondary">
            Back to menu
          </Link>
        </div>
      </AdminPageShell>
    );
  }

  return (
    <AdminPageShell
      pageId="admin-menu-editor"
      title="Menu item editor"
      hint={`Editing ${item.name} (${item.sku})`}
      actions={
        <Link to="/admin/catalogue/menu" className="btn-secondary">
          Back to list
        </Link>
      }
    >
      <form className="admin-form" onSubmit={(e) => e.preventDefault()}>
        <label>
          Display name
          <input value={item.name} readOnly />
        </label>
        <label>
          Base price (sen)
          <input type="number" value={priceSen} onChange={(e) => setPriceSen(Number(e.target.value))} />
        </label>
        <p className="form-hint">Preview price: {formatRmFromSen(priceSen)}</p>
        <label className="admin-checkbox">
          <input type="checkbox" checked={available} onChange={(e) => setAvailable(e.target.checked)} />
          Available on POS
        </label>
        <button type="submit" className="btn-primary" disabled title="Team 2 publish API pending">
          Save (preview only)
        </button>
      </form>

      <h2 className="admin-section-title admin-section-title--spaced">Modifier groups (read-only sample)</h2>
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Group</th>
            <th>Required</th>
            <th>Options</th>
          </tr>
        </thead>
        <tbody>
          {PREVIEW_MODIFIER_GROUPS.map((g) => (
            <tr key={g.id}>
              <td>{g.name}</td>
              <td>{g.required ? 'Yes' : 'No'}</td>
              <td>{g.options.map((o) => o.label).join(', ')}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
