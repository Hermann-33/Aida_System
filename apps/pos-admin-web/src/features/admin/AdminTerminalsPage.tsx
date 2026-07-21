import { useState } from 'react';
import { PREVIEW_SAMPLE_ENROLMENT_CODE } from '../../preview/demoAccounts';
import { PREVIEW_TERMINALS } from '../../preview/fixtures/catalog';
import { previewTerminalRepository } from '../../preview/repositories/previewTerminalRepository';
import { ConfirmDialog } from '../../shared/components/ConfirmDialog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminTerminalsPage() {
  const [terminals, setTerminals] = useState(PREVIEW_TERMINALS);
  const [enrolOpen, setEnrolOpen] = useState(false);
  const [enrolCode, setEnrolCode] = useState<string | null>(null);
  const [revokeId, setRevokeId] = useState<string | null>(null);

  function issueCode() {
    previewTerminalRepository.clearLocalPreview();
    setEnrolCode(PREVIEW_SAMPLE_ENROLMENT_CODE);
    setEnrolOpen(true);
  }

  function confirmRevoke() {
    if (!revokeId) return;
    setTerminals((prev) =>
      prev.map((t) => (t.id === revokeId ? { ...t, status: 'revoked' as const } : t)),
    );
    setRevokeId(null);
  }

  return (
    <AdminPageShell
      pageId="admin-terminals"
      title="Terminals"
      hint={`Preview enrolment sample ${PREVIEW_SAMPLE_ENROLMENT_CODE} for POS-MAIN-01.`}
      actions={
        <button type="button" className="btn-primary" onClick={issueCode}>
          Issue enrolment code
        </button>
      }
    >
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Code</th>
            <th>Branch</th>
            <th>Sales point</th>
            <th>Status</th>
            <th>Last seen</th>
            <th>Heartbeat</th>
            <th>Printer</th>
            <th>KDS</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {terminals.map((t) => (
            <tr key={t.id}>
              <td>{t.code}</td>
              <td>{t.branch}</td>
              <td>{t.salesPoint}</td>
              <td>
                <span className={`status-pill status-pill--${t.status === 'active' ? 'ok' : t.status === 'pending' ? 'info' : 'err'}`}>
                  {t.status}
                </span>
              </td>
              <td>{t.lastSeen ?? '—'}</td>
              <td>{t.heartbeat ?? '—'}</td>
              <td>{t.printer ?? '—'}</td>
              <td>{t.kds ?? '—'}</td>
              <td>
                {t.status === 'active' && (
                  <button type="button" className="btn-secondary btn-sm" onClick={() => setRevokeId(t.id)}>
                    Revoke
                  </button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {enrolOpen && enrolCode && (
        <div className="confirm-dialog-overlay" role="presentation" onClick={() => setEnrolOpen(false)}>
          <div className="confirm-dialog" role="dialog" onClick={(e) => e.stopPropagation()}>
            <h2 className="admin-section-title">Enrolment code</h2>
            <p className="enrol-code">{enrolCode}</p>
            <p className="form-hint">Copy now — preview only.</p>
            <button type="button" className="btn-primary" onClick={() => setEnrolOpen(false)}>
              Done
            </button>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={revokeId !== null}
        title="Revoke terminal"
        message="This will disable the terminal credential. Continue?"
        confirmLabel="Revoke"
        onConfirm={confirmRevoke}
        onCancel={() => setRevokeId(null)}
      />
    </AdminPageShell>
  );
}
