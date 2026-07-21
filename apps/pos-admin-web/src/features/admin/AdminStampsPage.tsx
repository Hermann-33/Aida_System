import { PREVIEW_MEMBERS, PREVIEW_REWARD_RULES } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminStampsPage() {
  return (
    <AdminPageShell
      pageId="admin-stamps"
      title="Stamp cards"
      hint={`${PREVIEW_REWARD_RULES.stampsForFreeDrink} stamps = free drink · ${PREVIEW_REWARD_RULES.stampsPerPurchase} stamp per purchase.`}
    >
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Member</th>
            <th>Progress</th>
            <th>Free drink</th>
          </tr>
        </thead>
        <tbody>
          {PREVIEW_MEMBERS.filter((m) => m.active).map((m) => (
            <tr key={m.id}>
              <td>{m.displayName}</td>
              <td>
                {m.stamps}/{m.stampGoal} stamps
              </td>
              <td>{m.stamps >= PREVIEW_REWARD_RULES.stampsForFreeDrink ? 'Unlocked' : 'In progress'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
