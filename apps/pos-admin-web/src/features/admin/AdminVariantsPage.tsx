import { PREVIEW_MODIFIER_GROUPS } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminVariantsPage() {
  return (
    <AdminPageShell
      pageId="admin-variants"
      title="Variants and modifier groups"
      hint="Master PRD modifier contract — editing pending Team 2 catalogue API."
    >
      {PREVIEW_MODIFIER_GROUPS.map((group) => (
        <article key={group.id} className="modifier-group-card">
          <header>
            <h2 className="admin-section-title">{group.name}</h2>
            <span className="form-hint">
              {group.required ? 'Required' : 'Optional'} · min {group.min} · max {group.max}
            </span>
          </header>
          {group.help ? <p className="form-hint">{group.help}</p> : null}
          <table className="data-table admin-table">
            <thead>
              <tr>
                <th>Option</th>
                <th>Price delta</th>
                <th>Available</th>
              </tr>
            </thead>
            <tbody>
              {group.options.map((opt) => (
                <tr key={opt.id}>
                  <td>{opt.label}</td>
                  <td>{formatRmFromSen(Math.abs(opt.priceDeltaSen))}{opt.priceDeltaSen < 0 ? ' (discount)' : opt.priceDeltaSen > 0 ? ' (add)' : ''}</td>
                  <td>{opt.available === false ? 'No' : 'Yes'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </article>
      ))}
    </AdminPageShell>
  );
}
