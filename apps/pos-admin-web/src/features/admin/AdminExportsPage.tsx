import { AdminPageShell } from './AdminPageShell';
import './admin.css';

const EXPORT_TYPES = [
  'Daily sales summary',
  'Transaction detail',
  'Payment reconciliation',
  'Shift variance',
  'Member activity',
  'Inventory movement',
];

export function AdminExportsPage() {
  return (
    <AdminPageShell
      pageId="admin-exports"
      title="Report exports"
      hint="Export jobs will run server-side when Team 2 report APIs are ready."
    >
      <ul className="export-list">
        {EXPORT_TYPES.map((label) => (
          <li key={label}>
            <span>{label}</span>
            <button type="button" className="btn-secondary" disabled title="Team 2 API pending">
              Export CSV
            </button>
          </li>
        ))}
      </ul>
    </AdminPageShell>
  );
}
