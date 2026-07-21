import { PREVIEW_REWARD_RULES } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminLoyaltyPage() {
  return (
    <AdminPageShell pageId="admin-loyalty" title="Loyalty points rules" hint={PREVIEW_REWARD_RULES.note}>
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Rule</th>
            <th>Value</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Earn rate</td>
            <td>RM 1 = {PREVIEW_REWARD_RULES.pointsPerRm} point</td>
          </tr>
          {PREVIEW_REWARD_RULES.vouchers.map((v) => (
            <tr key={v.label}>
              <td>{v.label}</td>
              <td>{v.points} points</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
