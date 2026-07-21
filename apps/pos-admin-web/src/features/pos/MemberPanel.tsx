import { useState } from 'react';
import {
  PREVIEW_MEMBERS,
  PREVIEW_REWARD_RULES,
  type PreviewMember,
  type PreviewRewardOption,
} from '../../preview/fixtures/catalog';
import { EmptyState } from '../../shared/components/EmptyState';

interface Props {
  member: PreviewMember | null;
  selectedRewardId: string | null;
  onSelectMember: (member: PreviewMember | null) => void;
  onApplyReward: (reward: PreviewRewardOption | null) => void;
}

export function MemberPanel({
  member,
  selectedRewardId,
  onSelectMember,
  onApplyReward,
}: Props) {
  const [query, setQuery] = useState('');
  const [error, setError] = useState('');
  const [scanBusy, setScanBusy] = useState(false);
  const [rewardMessage, setRewardMessage] = useState('');

  const results = query.trim()
    ? PREVIEW_MEMBERS.filter((m) =>
      m.displayName.toLowerCase().includes(query.toLowerCase())
        || m.memberCode.toLowerCase().includes(query.toLowerCase())
        || m.id.toLowerCase().includes(query.toLowerCase()),
    )
    : [];

  function handleSelect(m: PreviewMember) {
    if (!m.active) {
      setError('Member account is inactive. Use guest sale or contact support.');
      return;
    }
    setError('');
    onSelectMember(m);
    onApplyReward(null);
    setQuery('');
    setRewardMessage('');
  }

  async function handleScan() {
    setScanBusy(true);
    setError('');
    await new Promise((r) => setTimeout(r, 200));
    const scanned = PREVIEW_MEMBERS.find((m) => m.memberCode === 'STU-1042') ?? PREVIEW_MEMBERS[0];
    if (scanned) handleSelect(scanned);
    setScanBusy(false);
  }

  function handleApplyReward(reward: PreviewRewardOption) {
    if (!member) return;
    if (!reward.eligible) {
      setRewardMessage(reward.rejectReason || 'Reward not eligible for this member.');
      onApplyReward(null);
      return;
    }
    setRewardMessage('');
    onApplyReward(reward);
  }

  return (
    <section className="member-panel" aria-labelledby="member-panel-title">
      <h3 id="member-panel-title">Member / Rewards</h3>
      <p className="form-hint">
        Scan member QR or student ID (primary). Manual lookup is fallback only. No purchase history export.
      </p>

      <button
        type="button"
        className="btn-primary member-scan-btn"
        onClick={() => void handleScan()}
        disabled={scanBusy}
      >
        {scanBusy ? 'Scanning…' : 'Scan member'}
      </button>

      <p className="form-hint member-fallback-label">Manual lookup (fallback)</p>
      <label htmlFor="member-search" className="visually-hidden">Search member</label>
      <input
        id="member-search"
        type="search"
        placeholder="Name or member code…"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        autoComplete="off"
      />

      {query.trim() && results.length > 0 && (
        <ul className="member-search-results" role="listbox">
          {results.map((m) => (
            <li key={m.id}>
              <button type="button" role="option" onClick={() => handleSelect(m)}>
                {m.displayName} · {m.memberCode} · {m.kind}
              </button>
            </li>
          ))}
        </ul>
      )}

      {error && <p className="form-error" role="alert">{error}</p>}

      {member ? (
        <div className="member-card">
          <h4>{member.displayName}</h4>
          <p>
            <span className="status-pill status-pill--info">{member.kind}</span>
            <span className="status-pill">{member.memberCode}</span>
          </p>
          <p className="form-hint">
            Student verification: <strong>{member.studentVerification.replace('_', ' ')}</strong>
          </p>
          <dl className="member-stats">
            <div><dt>Points</dt><dd>{member.points}</dd></div>
            <div><dt>Stamps</dt><dd>{member.stamps} / {member.stampGoal}</dd></div>
          </dl>
          <p className="form-hint">
            Earn preview: RM 1 = {PREVIEW_REWARD_RULES.pointsPerRm} pt · +{PREVIEW_REWARD_RULES.stampsPerPurchase} stamp per purchase · free drink at {PREVIEW_REWARD_RULES.stampsForFreeDrink} stamps
          </p>

          <h5 className="member-rewards-heading">Rewards & offers</h5>
          <ul className="member-rewards-list">
            {member.rewards.map((r) => (
              <li key={r.id} className={selectedRewardId === r.id ? 'member-reward--selected' : ''}>
                <div className="member-reward__row">
                  <span>{r.label}</span>
                  <span className="form-hint">Exp {r.expiresOn}</span>
                </div>
                {!r.eligible && r.rejectReason && (
                  <p className="form-error member-reward__reject" role="status">{r.rejectReason}</p>
                )}
                <button
                  type="button"
                  className="btn-secondary"
                  disabled={!r.eligible}
                  onClick={() => handleApplyReward(r)}
                >
                  {selectedRewardId === r.id ? 'Selected' : 'Apply reward'}
                </button>
              </li>
            ))}
          </ul>
          {rewardMessage && <p className="form-error" role="alert">{rewardMessage}</p>}

          <button type="button" className="btn-secondary" onClick={() => { onSelectMember(null); onApplyReward(null); setRewardMessage(''); }}>
            Clear member
          </button>
        </div>
      ) : (
        <EmptyState
          title="Guest sale"
          description="No member attached. Scan or search to link rewards."
        />
      )}

      <button type="button" className="btn-secondary member-guest-btn" onClick={() => { onSelectMember(null); onApplyReward(null); }}>
        Continue as guest
      </button>
    </section>
  );
}
