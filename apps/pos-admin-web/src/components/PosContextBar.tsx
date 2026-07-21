import { useState } from 'react';
import type { ConnectionState } from '../preview/fixtures/catalog';
import type { EmployeeIdentity, ShiftSummary, TerminalLocation } from '../auth/types';
import { formatKlTime } from '../shared/formatting/datetime';

interface Props {
  employee: EmployeeIdentity | null;
  location: TerminalLocation | null;
  shift: ShiftSummary | null;
  connection?: ConnectionState;
}

const CONNECTION_LABEL: Record<ConnectionState, string> = {
  online: 'Online',
  degraded: 'Degraded',
  offline: 'Offline',
  syncing: 'Syncing',
};

const CONNECTION_CLASS: Record<ConnectionState, string> = {
  online: 'status-pill--ok',
  degraded: 'status-pill--warn',
  offline: 'status-pill--err',
  syncing: 'status-pill--info',
};

export function PosContextBar({ employee, location, shift, connection = 'online' }: Props) {
  const [detailsOpen, setDetailsOpen] = useState(false);
  const shiftStarted = shift?.openedAt ? formatKlTime(shift.openedAt) : null;

  return (
    <aside className="pos-context-bar" aria-label="POS context">
      <div className="pos-context-bar__groups">
        <span className="pos-context-bar__group">
          <strong>Employee</strong> {employee?.fullName || '—'}
          <span className="pos-context-bar__sep">·</span>
          <strong>Role</strong> {employee?.role || '—'}
        </span>
        <span className="pos-context-bar__group">
          <strong>Branch</strong> {location?.branchCode || '—'}
          <span className="pos-context-bar__sep">·</span>
          <strong>SP</strong> {location?.salesPointCode || '—'}
          <span className="pos-context-bar__sep">·</span>
          <strong>Terminal</strong> {location?.terminalCode || '—'}
        </span>
        <span className="pos-context-bar__group pos-context-bar__status">
          <strong>Shift</strong> {shift?.status || 'none'}
          <span className="pos-context-bar__sep">·</span>
          <strong>Connection</strong>
          <span className={`status-pill ${CONNECTION_CLASS[connection]}`}>
            {CONNECTION_LABEL[connection]}
          </span>
        </span>
      </div>

      <button
        type="button"
        className="pos-context-bar__disclosure"
        aria-expanded={detailsOpen}
        onClick={() => setDetailsOpen((v) => !v)}
      >
        {detailsOpen ? 'Hide details' : 'Details'}
      </button>

      {detailsOpen && (
        <div className="pos-context-bar__details">
          <span className="pos-context-bar__product">
            <strong>Product</strong> Aida Counter
          </span>
          {location?.branchName && (
            <span><strong>Branch name</strong> {location.branchName}</span>
          )}
          {location?.salesPointName && (
            <span><strong>Sales point name</strong> {location.salesPointName}</span>
          )}
          {shiftStarted && (
            <span><strong>Shift started</strong> {shiftStarted}</span>
          )}
          {shift?.id && (
            <span><strong>Shift ID</strong> {shift.id}</span>
          )}
        </div>
      )}
    </aside>
  );
}
