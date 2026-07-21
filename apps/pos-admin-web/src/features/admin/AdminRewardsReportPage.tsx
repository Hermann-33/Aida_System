import { FIXTURE_TODAY, PREVIEW_REWARD_RULES, PREVIEW_TRANSACTIONS } from '../../preview/fixtures/catalog';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminRewardsReportPage() {
  const discountRows = PREVIEW_TRANSACTIONS.filter((t) => t.discountSen > 0);

  return (
    <AdminPageShell
      pageId="admin-rewards-report"
      title="Rewards and offers report"
      hint={PREVIEW_REWARD_RULES.note}
    >
      <div className="metric-grid metric-grid--compact">
        <article className="metric-card">
          <p className="metric-card__label">Points issued (today)</p>
          <p className="metric-card__value">{FIXTURE_TODAY.pointsIssued}</p>
        </article>
        <article className="metric-card">
          <p className="metric-card__label">Stamps issued</p>
          <p className="metric-card__value">{FIXTURE_TODAY.stampsIssued}</p>
        </article>
        <article className="metric-card">
          <p className="metric-card__label">Redemptions</p>
          <p className="metric-card__value">{FIXTURE_TODAY.rewardRedemptions}</p>
        </article>
      </div>

      <h2 className="admin-section-title admin-section-title--spaced">Orders with rewards applied</h2>
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Order</th>
            <th>Member</th>
            <th>Discount</th>
            <th>Net</th>
          </tr>
        </thead>
        <tbody>
          {discountRows.map((t) => (
            <tr key={t.order}>
              <td>{t.order}</td>
              <td>{t.member ?? '—'}</td>
              <td>{formatRmFromSen(t.discountSen)}</td>
              <td>{formatRmFromSen(t.totalSen)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
