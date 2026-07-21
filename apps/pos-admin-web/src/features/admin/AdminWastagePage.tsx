import { AdminPageShell } from './AdminPageShell';
import './admin.css';

const WASTAGE = [
  { id: 'w1', when: '20 Jul 2026', item: 'Oat milk', qty: '0.5 L', reason: 'Expired', staff: 'Nadia' },
  { id: 'w2', when: '19 Jul 2026', item: 'Butter Croissant', qty: '3 pc', reason: 'End of day', staff: 'Hafiz' },
];

export function AdminWastagePage() {
  return (
    <AdminPageShell pageId="admin-wastage" title="Wastage and spoilage" hint="Adjustments post to inventory when API connects.">
      {WASTAGE.length === 0 ? (
        <div className="empty-state">
          <h2 className="admin-section-title">No wastage logged</h2>
        </div>
      ) : (
        <table className="data-table admin-table">
          <thead>
            <tr>
              <th>Date</th>
              <th>Item</th>
              <th>Quantity</th>
              <th>Reason</th>
              <th>Recorded by</th>
            </tr>
          </thead>
          <tbody>
            {WASTAGE.map((row) => (
              <tr key={row.id}>
                <td>{row.when}</td>
                <td>{row.item}</td>
                <td>{row.qty}</td>
                <td>{row.reason}</td>
                <td>{row.staff}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </AdminPageShell>
  );
}
