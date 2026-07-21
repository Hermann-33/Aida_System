import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminIntegrationsPage() {
  return (
    <AdminPageShell pageId="admin-integrations" title="Integrations" hint="Third-party connectors — credentials stored server-side only.">
      <article className="integration-card">
        <header>
          <h2 className="admin-section-title">MyInvois e-Invoice</h2>
          <span className="status-pill status-pill--warn">Pending</span>
        </header>
        <p>MyInvois pending business and API decision</p>
        <p className="form-hint">
          LHDN MyInvois integration requires business registration details and API credentials. No connection
          configured in this preview.
        </p>
        <button type="button" className="btn-secondary" disabled>
          Configure (blocked)
        </button>
      </article>
    </AdminPageShell>
  );
}
