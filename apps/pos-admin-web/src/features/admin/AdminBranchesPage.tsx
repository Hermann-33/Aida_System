import { PREVIEW_ORG } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminBranchesPage() {
  return (
    <AdminPageShell
      pageId="admin-branches"
      title="Branches and sales points"
      hint={`Organisation ${PREVIEW_ORG.organisation} · inventory code ${PREVIEW_ORG.inventoryCode} shared.`}
    >
      <article className="org-card">
        <h2 className="admin-section-title">{PREVIEW_ORG.organisation}</h2>
        <p className="form-hint">Master inventory relationship: {PREVIEW_ORG.inventoryCode}</p>
      </article>

      {PREVIEW_ORG.branches.map((b) => (
        <article key={b.id} className="branch-card">
          <header>
            <h2 className="admin-section-title">
              {b.name} <span className="branch-code">{b.code}</span>
            </h2>
            <span className={`status-pill status-pill--${b.status === 'open' ? 'ok' : 'info'}`}>{b.status}</span>
          </header>
          <p>Hours {b.hours}</p>
          <p>Order types: {b.orderTypes.join(', ')}</p>
          <table className="data-table admin-table">
            <thead>
              <tr>
                <th>Sales point</th>
                <th>Code</th>
                <th>Terminals</th>
                <th>Inventory</th>
              </tr>
            </thead>
            <tbody>
              {b.salesPoints.map((sp) => (
                <tr key={sp.id}>
                  <td>{sp.name}</td>
                  <td>{sp.code}</td>
                  <td>{sp.terminals.join(', ')}</td>
                  <td>{sp.inventory}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </article>
      ))}

    </AdminPageShell>
  );
}
