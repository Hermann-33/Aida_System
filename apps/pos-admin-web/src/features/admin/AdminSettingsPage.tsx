import { AdminPageShell } from './AdminPageShell';
import './admin.css';

const SETTINGS = [
  { id: 'timezone', label: 'Timezone', value: 'Asia/Kuala_Lumpur (MYT)' },
  { id: 'receipt', label: 'Receipt footer', value: 'Thank you — Aida Café Rewards' },
  { id: 'variance', label: 'Cash variance threshold', value: 'RM 20.00 (sample)' },
  { id: 'student', label: 'Student verification', value: 'Manual review — API pending' },
];

export function AdminSettingsPage() {
  return (
    <AdminPageShell pageId="admin-settings" title="Settings" hint="Organisation defaults — save disabled until settings API exists.">
      <form className="admin-form" onSubmit={(e) => e.preventDefault()}>
        {SETTINGS.map((s) => (
          <label key={s.id}>
            {s.label}
            <input defaultValue={s.value} readOnly />
          </label>
        ))}
        <button type="submit" className="btn-primary" disabled title="Team 2 API pending">
          Save settings
        </button>
      </form>
    </AdminPageShell>
  );
}
