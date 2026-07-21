import { describe, expect, it, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { PaymentPanel } from './PaymentPanel';
import { CounterWorkspace } from './CounterWorkspace';
import type { EmployeeIdentity, ShiftSummary, TerminalLocation } from '../../auth/types';
import { resetPreviewOrderSequence } from './paymentReceipt';
import type { CartLine } from './cartTypes';

vi.mock('../../preview/uiPreviewMode', () => ({
  isUiPreviewMode: vi.fn(() => true),
}));

const employee: EmployeeIdentity = {
  id: 'e1',
  username: 'nadia',
  role: 'staff',
  fullName: 'Nadia',
  isGlobalManager: false,
  dualRolePosEnabled: false,
  selectedProduct: 'pos',
  assignedBranchIds: ['b1'],
};

const location: TerminalLocation = {
  terminalId: 't1',
  terminalCode: 'MC-T01',
  branchId: 'b1',
  branchCode: 'MAIN',
  salesPointId: 'sp1',
  salesPointCode: 'COUNTER',
};

const shift: ShiftSummary = {
  id: 's1',
  status: 'open',
  terminalId: 't1',
  salesPointId: 'sp1',
  branchId: 'b1',
  staffUserId: 'e1',
  openingFloat: 100,
  closingExpectedCash: null,
  closingActualCash: null,
  cashVariance: null,
  openedAt: '2026-07-19T08:00:00+08:00',
};

const lines: CartLine[] = [
  {
    id: 'l1',
    menuItemId: 'latte',
    name: 'Latte',
    unitPriceSen: 1050,
    qty: 1,
    modifiers: [],
  },
];

describe('PaymentPanel', () => {
  beforeEach(() => {
    resetPreviewOrderSequence(10521);
  });

  it('shows insufficient cash validation and change due', async () => {
    const user = userEvent.setup();
    render(
      <PaymentPanel
        lines={lines}
        orderType="dine_in"
        member={null}
        employee={employee}
        location={location}
        shift={shift}
        discountSen={0}
        onPaid={() => {}}
        onCancel={() => {}}
      />,
    );

    await user.click(screen.getByRole('button', { name: /^exact$/i }));
    expect(screen.getByText(/change due: rm 0\.00/i)).toBeInTheDocument();

    await user.clear(screen.getByLabelText(/cash received/i));
    await user.type(screen.getByLabelText(/cash received/i), '5');
    expect(screen.getByText(/insufficient cash/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /confirm payment/i })).toBeDisabled();
  });

  it('calls onPaid with receipt on cash confirm', async () => {
    const user = userEvent.setup();
    const onPaid = vi.fn();
    render(
      <PaymentPanel
        lines={lines}
        orderType="takeaway"
        member={null}
        employee={employee}
        location={location}
        shift={shift}
        discountSen={0}
        onPaid={onPaid}
        onCancel={() => {}}
      />,
    );

    await user.click(screen.getByRole('button', { name: /^exact$/i }));
    await user.click(screen.getByRole('button', { name: /confirm payment/i }));
    expect(onPaid).toHaveBeenCalledTimes(1);
    const receipt = onPaid.mock.calls[0]?.[0];
    expect(receipt?.totalSen).toBe(1050);
    expect(receipt?.changeSen).toBe(0);
  });
});

describe('CounterWorkspace completed sale', () => {
  it('hides Pay after successful payment', async () => {
    const user = userEvent.setup();

    render(
      <CounterWorkspace
        employee={employee}
        location={location}
        shift={shift}
        onLock={() => {}}
        onCloseRequest={() => {}}
        onLogout={() => {}}
        connectionState="online"
        onConnectionStateChange={() => {}}
      />,
    );

    await user.click(screen.getByRole('button', { name: /salted caramel latte/i }));
    await user.click(screen.getByRole('button', { name: /add to order/i }));
    await user.click(screen.getByRole('button', { name: /^pay$/i }));
    await user.click(screen.getByRole('button', { name: /^exact$/i }));
    await user.click(screen.getByRole('button', { name: /confirm payment/i }));

    expect(screen.queryByRole('button', { name: /^pay$/i })).not.toBeInTheDocument();
    expect(document.querySelector('.order-ribbon__pay')).toHaveTextContent(/new sale/i);
  });
});
