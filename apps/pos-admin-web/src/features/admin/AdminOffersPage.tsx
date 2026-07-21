import { PREVIEW_MEMBERS } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminOffersPage() {
  const offers = PREVIEW_MEMBERS.flatMap((m) =>
    m.rewards.filter((r) => r.kind === 'offer' || r.kind === 'voucher').map((r) => ({ member: m.displayName, ...r })),
  );

  return (
    <AdminPageShell pageId="admin-offers" title="Offers and student deals" hint="Eligibility enforced at POS when member is attached.">
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Offer</th>
            <th>Member</th>
            <th>Expires</th>
            <th>Eligible</th>
            <th>Notes</th>
          </tr>
        </thead>
        <tbody>
          {offers.map((o) => (
            <tr key={`${o.member}-${o.id}`}>
              <td>{o.label}</td>
              <td>{o.member}</td>
              <td>{o.expiresOn}</td>
              <td>{o.eligible ? 'Yes' : 'No'}</td>
              <td>{o.rejectReason ?? '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
