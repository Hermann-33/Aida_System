import { PREVIEW_MEMBERS } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminMembersReportPage() {
  const active = PREVIEW_MEMBERS.filter((m) => m.active);
  const guestOrders = 9;
  const memberOrders = 4;

  return (
    <AdminPageShell
      pageId="admin-members-report"
      title="Members report"
      hint="Member vs guest mix from preview transaction sample."
    >
      <div className="metric-grid metric-grid--compact">
        <article className="metric-card">
          <p className="metric-card__label">Active members</p>
          <p className="metric-card__value">{active.length}</p>
        </article>
        <article className="metric-card">
          <p className="metric-card__label">Member orders (sample)</p>
          <p className="metric-card__value">{memberOrders}</p>
        </article>
        <article className="metric-card">
          <p className="metric-card__label">Guest orders (sample)</p>
          <p className="metric-card__value">{guestOrders}</p>
        </article>
      </div>

      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Code</th>
            <th>Kind</th>
            <th>Points</th>
            <th>Stamps</th>
            <th>Student status</th>
            <th>Active</th>
          </tr>
        </thead>
        <tbody>
          {PREVIEW_MEMBERS.map((m) => (
            <tr key={m.id}>
              <td>{m.displayName}</td>
              <td>{m.memberCode}</td>
              <td>{m.kind}</td>
              <td>{m.points}</td>
              <td>
                {m.stamps}/{m.stampGoal}
              </td>
              <td>{m.studentVerification}</td>
              <td>{m.active ? 'Yes' : 'No'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
