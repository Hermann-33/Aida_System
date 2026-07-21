import { AdminPageShell } from './AdminPageShell';
import './admin.css';

const EVENTS = [
  { id: 'a1', when: '21 Jul 2026 09:12', actor: 'Siti Manager', action: 'Approved variance', entity: 'Shift s3' },
  { id: 'a2', when: '21 Jul 2026 08:05', actor: 'Nadia Rahman', action: 'Applied reward', entity: 'Order A-10513' },
  { id: 'a3', when: '20 Jul 2026 22:10', actor: 'Siti Manager', action: 'Revoked terminal', entity: 'POS-LEGACY-01' },
  { id: 'a4', when: '20 Jul 2026 14:00', actor: 'Hafiz Ali', action: 'Refund issued', entity: 'Order A-10509' },
];

export function AdminAuditPage() {
  return (
    <AdminPageShell pageId="admin-audit" title="Audit log" hint="Immutable server audit stream — preview sample rows.">
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>When</th>
            <th>Actor</th>
            <th>Action</th>
            <th>Entity</th>
          </tr>
        </thead>
        <tbody>
          {EVENTS.map((e) => (
            <tr key={e.id}>
              <td>{e.when}</td>
              <td>{e.actor}</td>
              <td>{e.action}</td>
              <td>{e.entity}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
