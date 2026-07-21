import { PREVIEW_SHIFT_ROWS, PREVIEW_TERMINALS } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

const LIVE_POINTS = [
  { key: 'cafe', title: 'Main Café', subtitle: 'Branch BR-MAIN · shared INV-MAIN' },
  { key: 'main', title: 'Main Counter', subtitle: 'SP-MAIN' },
  { key: 'snack', title: 'Snack Station', subtitle: 'SP-SNACK' },
] as const;

export function AdminLiveOpsPage() {
  const mainTerminals = PREVIEW_TERMINALS.filter((t) => t.salesPoint === 'Main Counter');
  const snackTerminals = PREVIEW_TERMINALS.filter((t) => t.salesPoint === 'Snack Station');
  const mainShifts = PREVIEW_SHIFT_ROWS.filter((s) => s.salesPoint === 'Main Counter');
  const snackShifts = PREVIEW_SHIFT_ROWS.filter((s) => s.salesPoint === 'Snack Station');

  return (
    <AdminPageShell
      pageId="admin-live-ops"
      title="Live Operations"
      hint="Real-time health cards — heartbeat and peripheral status from preview fixtures."
    >
      <div className="live-ops-grid">
        {LIVE_POINTS.map((card) => {
          const terminals = card.key === 'snack' ? snackTerminals : card.key === 'main' ? mainTerminals : PREVIEW_TERMINALS;
          const shifts = card.key === 'snack' ? snackShifts : card.key === 'main' ? mainShifts : PREVIEW_SHIFT_ROWS;
          return (
            <article key={card.key} className="live-ops-card">
              <header>
                <h2 className="admin-section-title">{card.title}</h2>
                <p className="form-hint">{card.subtitle}</p>
              </header>
              <section>
                <h3 className="live-ops-card__label">Open shifts</h3>
                {shifts.length === 0 ? (
                  <p className="empty-state">No shifts in sample.</p>
                ) : (
                  <ul className="live-ops-list">
                    {shifts.map((s) => (
                      <li key={s.id}>
                        <strong>{s.staff}</strong> · {s.terminal} ·{' '}
                        <span className={`status-pill status-pill--${s.status === 'open' ? 'ok' : s.status === 'locked' ? 'warn' : 'info'}`}>
                          {s.status}
                        </span>
                      </li>
                    ))}
                  </ul>
                )}
              </section>
              {card.key !== 'cafe' && (
                <section>
                  <h3 className="live-ops-card__label">Terminals</h3>
                  <ul className="live-ops-list">
                    {terminals.map((t) => (
                      <li key={t.id}>
                        <strong>{t.code}</strong>
                        <span className="live-ops-meta">Heartbeat {t.heartbeat ?? '—'}</span>
                        <span className="live-ops-meta">Printer {t.printer ?? '—'}</span>
                        <span className="live-ops-meta">KDS {t.kds ?? '—'}</span>
                      </li>
                    ))}
                  </ul>
                </section>
              )}
              {card.key === 'cafe' && (
                <p className="form-hint">Organisation rollup — drill into sales points for device detail.</p>
              )}
            </article>
          );
        })}
      </div>
    </AdminPageShell>
  );
}
