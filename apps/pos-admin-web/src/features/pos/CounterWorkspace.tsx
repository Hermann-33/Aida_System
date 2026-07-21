import { useMemo, useState } from 'react';
import type { EmployeeIdentity, ShiftSummary, TerminalLocation } from '../../auth/types';
import {
  PREVIEW_CATEGORIES,
  PREVIEW_MENU,
  PREVIEW_MODIFIER_GROUPS,
  PREVIEW_TERMINALS,
  PREVIEW_TRANSACTIONS,
  PREVIEW_VARIANCE_THRESHOLD_SEN,
  type ConnectionState,
  type OrderType,
  type PreviewCategory,
  type PreviewMember,
  type PreviewMenuItem,
  type PreviewRewardOption,
  type PreviewTxn,
} from '../../preview/fixtures/catalog';
import { ConfirmDialog } from '../../shared/components/ConfirmDialog';
import { formatRmFromSen, formatRm } from '../../shared/formatting/money';
import { formatKlDateTime } from '../../shared/formatting/datetime';
import { EmptyState } from '../../shared/components/EmptyState';
import { MemberPanel } from './MemberPanel';
import { ModifierSheet } from './ModifierSheet';
import { CompletedSaleReceipt, PaymentPanel } from './PaymentPanel';
import type { PreviewSaleReceipt } from './paymentReceipt';
import {
  cartTotalSen,
  newCartLineId,
  type CartLine,
} from './cartTypes';
import './pos.css';

type RailId = 'sale' | 'orders' | 'member' | 'shift' | 'terminal' | 'help';

interface Props {
  employee: EmployeeIdentity;
  location: TerminalLocation;
  shift: ShiftSummary;
  onLock: () => void;
  onCloseRequest: () => void;
  onLogout: () => void;
  busy?: boolean;
  connectionState: ConnectionState;
  onConnectionStateChange: (state: ConnectionState) => void;
}

const RAIL_ITEMS: { id: RailId; label: string }[] = [
  { id: 'sale', label: 'New Sale' },
  { id: 'orders', label: 'Orders' },
  { id: 'member', label: 'Member' },
  { id: 'shift', label: 'Shift' },
  { id: 'terminal', label: 'Terminal' },
  { id: 'help', label: 'Help' },
];

const ORDER_TYPE_LABELS: Record<OrderType, string> = {
  dine_in: 'Dine-in',
  takeaway: 'Takeaway',
  pickup: 'Pickup',
};

function RailIcon({ id }: { id: RailId }) {
  const paths: Record<RailId, string> = {
    sale: 'M4 4h16v4H4zm0 6h10v4H4zm0 6h14v4H4',
    orders: 'M6 4h12v16H6zm2 2v12h8V6',
    member: 'M12 12a4 4 0 1 0-4-4 4 4 0 0 0 4 4zm-8 10a8 8 0 0 1 16 0',
    shift: 'M12 2v4l4 2-4 2v4l-4-2 4-2V2',
    terminal: 'M4 6h16v10H4zm4 14h8',
    help: 'M12 2a10 10 0 1 0 10 10A10 10 0 0 0 12 2zm1 15h-2v-2h2zm0-4h-2a3 3 0 1 1 3-3',
  };
  return (
    <svg className="aida-rail__icon" viewBox="0 0 24 24" aria-hidden="true">
      <path d={paths[id]} fill="currentColor" />
    </svg>
  );
}

function rewardDiscountSen(reward: PreviewRewardOption | null): number {
  if (!reward?.eligible) return 0;
  if (reward.kind === 'offer' && reward.label.includes('RM2')) return 200;
  if (reward.kind === 'voucher' && reward.label.includes('RM 5')) return 500;
  if (reward.kind === 'voucher' && reward.label.includes('RM 10')) return 1000;
  if (reward.kind === 'free_pastry') return 750;
  if (reward.kind === 'free_drink') return 1200;
  return 0;
}

export function CounterWorkspace({
  employee,
  location,
  shift,
  onLock,
  onCloseRequest,
  onLogout,
  busy = false,
  connectionState,
  onConnectionStateChange,
}: Props) {
  const [rail, setRail] = useState<RailId>('sale');
  const [category, setCategory] = useState<PreviewCategory>('All');
  const [search, setSearch] = useState('');
  const [compactMenu, setCompactMenu] = useState(false);
  const [orderType, setOrderType] = useState<OrderType>('dine_in');
  const [cart, setCart] = useState<CartLine[]>([]);
  const [member, setMember] = useState<PreviewMember | null>(null);
  const [selectedReward, setSelectedReward] = useState<PreviewRewardOption | null>(null);
  const [modifierItem, setModifierItem] = useState<PreviewMenuItem | null>(null);
  const [showPayment, setShowPayment] = useState(false);
  const [completedSale, setCompletedSale] = useState<PreviewSaleReceipt | null>(null);
  const [orderDrawerOpen, setOrderDrawerOpen] = useState(false);
  const [clearConfirmOpen, setClearConfirmOpen] = useState(false);
  const [showKdsPreview, setShowKdsPreview] = useState(false);

  const [ordersQuery, setOrdersQuery] = useState('');
  const [ordersStatus, setOrdersStatus] = useState<'all' | PreviewTxn['status']>('all');
  const [selectedOrder, setSelectedOrder] = useState<PreviewTxn | null>(null);
  const [orderAction, setOrderAction] = useState<'void' | 'refund' | 'cancel' | null>(null);
  const [orderActionReason, setOrderActionReason] = useState('');

  const [shiftPaidIn, setShiftPaidIn] = useState('');
  const [shiftPaidOut, setShiftPaidOut] = useState('');
  const [shiftDrop, setShiftDrop] = useState('');
  const [shiftMoveReason, setShiftMoveReason] = useState('');
  const [shiftMoveLog, setShiftMoveLog] = useState<string[]>([]);

  const discountSen = rewardDiscountSen(selectedReward);
  const totalSen = Math.max(0, cartTotalSen(cart) - discountSen);

  const filteredMenu = useMemo(() => {
    let items = PREVIEW_MENU;
    if (category !== 'All') {
      items = items.filter((i) => i.category === category || (category === 'Favourites' && i.bestSeller));
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      items = items.filter((i) => i.name.toLowerCase().includes(q) || i.sku.toLowerCase().includes(q));
    }
    return items;
  }, [category, search]);

  const filteredOrders = useMemo(() => {
    let rows = PREVIEW_TRANSACTIONS;
    if (ordersStatus !== 'all') {
      rows = rows.filter((t) => t.status === ordersStatus);
    }
    if (ordersQuery.trim()) {
      const q = ordersQuery.toLowerCase();
      rows = rows.filter(
        (t) =>
          t.order.toLowerCase().includes(q)
          || t.staff.toLowerCase().includes(q)
          || (t.member?.toLowerCase().includes(q) ?? false),
      );
    }
    return rows;
  }, [ordersQuery, ordersStatus]);

  const terminalFixture = PREVIEW_TERMINALS.find((t) => t.code === location.terminalCode)
    ?? PREVIEW_TERMINALS[0];

  function addToCart(item: PreviewMenuItem) {
    if (!item.available || completedSale) return;
    setModifierItem(item);
  }

  function confirmModifier(
    selections: Record<string, string[]>,
    unitPriceSen: number,
    summary: string,
  ) {
    if (!modifierItem) return;
    const modifiers = Object.entries(selections).map(([groupId, optionIds]) => ({ groupId, optionIds }));
    setCart((prev) => [
      ...prev,
      {
        id: newCartLineId(),
        menuItemId: modifierItem.id,
        name: modifierItem.name,
        unitPriceSen,
        qty: 1,
        modifiers,
        modifierSummary: summary || undefined,
      },
    ]);
    setModifierItem(null);
    setRail('sale');
  }

  function updateQty(lineId: string, delta: number) {
    setCart((prev) =>
      prev
        .map((l) => (l.id === lineId ? { ...l, qty: l.qty + delta } : l))
        .filter((l) => l.qty > 0),
    );
  }

  function updateNote(lineId: string, note: string) {
    setCart((prev) => prev.map((l) => (l.id === lineId ? { ...l, note: note || undefined } : l)));
  }

  function removeLine(lineId: string) {
    setCart((prev) => prev.filter((l) => l.id !== lineId));
  }

  function requestClearSale() {
    if (cart.length === 0) {
      resetSaleState();
      return;
    }
    setClearConfirmOpen(true);
  }

  function resetSaleState() {
    setCart([]);
    setMember(null);
    setSelectedReward(null);
    setShowPayment(false);
    setCompletedSale(null);
    setRail('sale');
  }

  function handlePaid(receipt: PreviewSaleReceipt) {
    setCompletedSale(receipt);
    setCart([]);
    setShowPayment(false);
  }

  function startNewSale() {
    resetSaleState();
  }

  function logShiftMove(label: string, amountRm: string) {
    const amt = Number(amountRm);
    if (!amt || !shiftMoveReason.trim()) return;
    setShiftMoveLog((prev) => [
      `${label} RM ${amt.toFixed(2)} — ${shiftMoveReason.trim()} (preview; Team 2 audit)`,
      ...prev,
    ]);
    setShiftMoveReason('');
    if (label === 'Paid in') setShiftPaidIn('');
    if (label === 'Paid out') setShiftPaidOut('');
    if (label === 'Safe drop') setShiftDrop('');
  }

  const saleLocked = completedSale !== null;

  return (
    <div className="counter-workspace">
      <nav className="aida-rail" aria-label="POS navigation">
        <p className="aida-rail__brand">Aida</p>
        <ul>
          {RAIL_ITEMS.map((item) => (
            <li key={item.id}>
              <button
                type="button"
                className={`aida-rail__btn ${rail === item.id ? 'aida-rail__btn--active' : ''}`}
                onClick={() => {
                  setRail(item.id);
                  if (item.id !== 'sale') setShowPayment(false);
                }}
              >
                <RailIcon id={item.id} />
                <span>{item.label}</span>
              </button>
            </li>
          ))}
        </ul>
      </nav>

      <main className="menu-gallery">
        {rail === 'sale' && !showPayment && !completedSale && (
          <>
            <header className="menu-gallery__header">
              <h2>Menu</h2>
              <div className="order-type-select" role="group" aria-label="Order type">
                {(Object.keys(ORDER_TYPE_LABELS) as OrderType[]).map((ot) => (
                  <button
                    key={ot}
                    type="button"
                    className={`order-type-btn ${orderType === ot ? 'order-type-btn--active' : ''}`}
                    onClick={() => setOrderType(ot)}
                  >
                    {ORDER_TYPE_LABELS[ot]}
                  </button>
                ))}
              </div>
              <label htmlFor="menu-search" className="visually-hidden">Search menu</label>
              <input
                id="menu-search"
                type="search"
                placeholder="Search products…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              <label className="menu-compact-toggle">
                <input
                  type="checkbox"
                  checked={compactMenu}
                  onChange={(e) => setCompactMenu(e.target.checked)}
                />
                Compact cards
              </label>
            </header>
            <div className="menu-gallery__tabs" role="tablist" aria-label="Categories">
              {PREVIEW_CATEGORIES.map((cat) => (
                <button
                  key={cat}
                  type="button"
                  role="tab"
                  aria-selected={category === cat}
                  className={`menu-tab ${category === cat ? 'menu-tab--active' : ''}`}
                  onClick={() => setCategory(cat)}
                >
                  {cat}
                </button>
              ))}
            </div>
            <p className="form-hint menu-category-hint" aria-live="polite">
              Showing {filteredMenu.length} item{filteredMenu.length === 1 ? '' : 's'} · {category === 'All' ? 'all categories' : category}
            </p>
            <div
              className={`menu-gallery__grid ${compactMenu ? 'menu-gallery__grid--compact' : ''}`}
              data-category={category}
            >
              {filteredMenu.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  className={`product-card ${!item.available ? 'product-card--sold-out' : ''} ${compactMenu ? 'product-card--compact' : ''}`}
                  disabled={!item.available}
                  onClick={() => addToCart(item)}
                >
                  <span
                    className="product-card__swatch"
                    style={{ backgroundColor: item.imageTone }}
                    aria-hidden="true"
                    title={`Tone ${item.imageTone}`}
                  />
                  {item.bestSeller && <span className="product-card__badge">Best seller</span>}
                  <span className="product-card__name">
                    {compactMenu ? item.compactLabel : item.name}
                  </span>
                  {!compactMenu && (
                    <span className="product-card__sku">{item.sku}</span>
                  )}
                  <span className="product-card__price">{formatRmFromSen(item.priceSen)}</span>
                  {!item.available && <span className="product-card__sold-out">Sold out</span>}
                </button>
              ))}
            </div>
            <label className="kds-preview-toggle">
              <input
                type="checkbox"
                checked={showKdsPreview}
                onChange={(e) => setShowKdsPreview(e.target.checked)}
              />
              Show KDS ticket preview
            </label>
            {showKdsPreview && cart.length > 0 && (
              <aside className="kds-preview-rail" aria-label="KDS ticket preview">
                <h3>KDS preview</h3>
                <ul>
                  {cart.map((line) => (
                    <li key={line.id}>
                      {line.qty}× {line.name} → {PREVIEW_MENU.find((m) => m.id === line.menuItemId)?.route ?? 'bar'}
                      {line.note && ` · Note: ${line.note}`}
                    </li>
                  ))}
                </ul>
              </aside>
            )}
          </>
        )}

        {rail === 'sale' && completedSale && (
          <CompletedSaleReceipt receipt={completedSale} />
        )}

        {rail === 'orders' && (
          <section className="orders-preview" aria-labelledby="orders-preview-title">
            <h2 id="orders-preview-title">Orders</h2>
            <p className="form-hint">Preview history — void/refund/cancel write Team 2 audit records when live.</p>
            <div className="orders-filters">
              <label htmlFor="orders-search" className="visually-hidden">Search orders</label>
              <input
                id="orders-search"
                type="search"
                placeholder="Order #, staff, member…"
                value={ordersQuery}
                onChange={(e) => setOrdersQuery(e.target.value)}
              />
              <select
                aria-label="Filter by status"
                value={ordersStatus}
                onChange={(e) => setOrdersStatus(e.target.value as typeof ordersStatus)}
              >
                <option value="all">All statuses</option>
                <option value="Completed">Completed</option>
                <option value="Refunded">Refunded</option>
                <option value="Voided">Voided</option>
              </select>
            </div>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Order</th>
                  <th>When</th>
                  <th>Staff</th>
                  <th>Status</th>
                  <th>Total</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {filteredOrders.map((row) => (
                  <tr key={row.order}>
                    <td>{row.order}</td>
                    <td>{row.when}</td>
                    <td>{row.staff}</td>
                    <td>{row.status}</td>
                    <td>{formatRmFromSen(row.totalSen)}</td>
                    <td>
                      <button type="button" className="btn-secondary btn-inline" onClick={() => setSelectedOrder(row)}>
                        Detail
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {selectedOrder && (
              <div className="order-detail-panel" role="region" aria-label="Order detail">
                <h3>{selectedOrder.order}</h3>
                <dl className="shift-details">
                  <div><dt>When</dt><dd>{selectedOrder.when}</dd></div>
                  <div><dt>Staff</dt><dd>{selectedOrder.staff}</dd></div>
                  <div><dt>Point</dt><dd>{selectedOrder.salesPoint}</dd></div>
                  <div><dt>Method</dt><dd>{selectedOrder.method}</dd></div>
                  <div><dt>Status</dt><dd>{selectedOrder.status}</dd></div>
                  {selectedOrder.member && <div><dt>Member</dt><dd>{selectedOrder.member}</dd></div>}
                  <div><dt>Total</dt><dd>{formatRmFromSen(selectedOrder.totalSen)}</dd></div>
                </dl>
                {orderAction && (
                  <div className="order-action-form">
                    <label htmlFor="order-action-reason">
                      Reason for {orderAction} (Team 2 audit when live)
                    </label>
                    <textarea
                      id="order-action-reason"
                      value={orderActionReason}
                      onChange={(e) => setOrderActionReason(e.target.value)}
                      rows={3}
                    />
                  </div>
                )}
                <div className="order-detail-actions">
                  <button type="button" className="btn-secondary" onClick={() => setOrderAction('void')}>Void preview</button>
                  <button type="button" className="btn-secondary" onClick={() => setOrderAction('refund')}>Refund preview</button>
                  <button type="button" className="btn-secondary" onClick={() => setOrderAction('cancel')}>Cancel preview</button>
                  {orderAction && (
                    <button
                      type="button"
                      className="btn-primary btn-inline"
                      disabled={!orderActionReason.trim()}
                      onClick={() => {
                        setOrderAction(null);
                        setOrderActionReason('');
                      }}
                    >
                      Submit {orderAction} preview
                    </button>
                  )}
                  <button type="button" className="btn-secondary" onClick={() => { setSelectedOrder(null); setOrderAction(null); }}>Close</button>
                </div>
              </div>
            )}
          </section>
        )}

        {rail === 'member' && (
          <MemberPanel
            member={member}
            selectedRewardId={selectedReward?.id ?? null}
            onSelectMember={setMember}
            onApplyReward={setSelectedReward}
          />
        )}

        {rail === 'shift' && (
          <section className="shift-workspace-panel" aria-labelledby="shift-panel-title">
            <h2 id="shift-panel-title">Shift controls</h2>
            <dl className="shift-details">
              <div><dt>Status</dt><dd>{shift.status}</dd></div>
              <div><dt>Opening float</dt><dd>{formatRm(shift.openingFloat)}</dd></div>
              {shift.openedAt && (
                <div><dt>Opened</dt><dd>{formatKlDateTime(shift.openedAt)}</dd></div>
              )}
              <div>
                <dt>Variance threshold</dt>
                <dd>{formatRmFromSen(PREVIEW_VARIANCE_THRESHOLD_SEN)} (preview)</dd>
              </div>
            </dl>

            <fieldset className="shift-cash-moves">
              <legend>Cash drawer moves (preview)</legend>
              <label htmlFor="shift-reason">Reason (required)</label>
              <input
                id="shift-reason"
                value={shiftMoveReason}
                onChange={(e) => setShiftMoveReason(e.target.value)}
                placeholder="Manager-approved reason"
              />
              <div className="shift-move-row">
                <label htmlFor="paid-in">Paid in (RM)</label>
                <input id="paid-in" type="number" min="0" step="0.01" value={shiftPaidIn} onChange={(e) => setShiftPaidIn(e.target.value)} />
                <button type="button" className="btn-secondary btn-inline" onClick={() => logShiftMove('Paid in', shiftPaidIn)}>Record</button>
              </div>
              <div className="shift-move-row">
                <label htmlFor="paid-out">Paid out (RM)</label>
                <input id="paid-out" type="number" min="0" step="0.01" value={shiftPaidOut} onChange={(e) => setShiftPaidOut(e.target.value)} />
                <button type="button" className="btn-secondary btn-inline" onClick={() => logShiftMove('Paid out', shiftPaidOut)}>Record</button>
              </div>
              <div className="shift-move-row">
                <label htmlFor="safe-drop">Safe drop (RM)</label>
                <input id="safe-drop" type="number" min="0" step="0.01" value={shiftDrop} onChange={(e) => setShiftDrop(e.target.value)} />
                <button type="button" className="btn-secondary btn-inline" onClick={() => logShiftMove('Safe drop', shiftDrop)}>Record</button>
              </div>
            </fieldset>
            {shiftMoveLog.length > 0 && (
              <ul className="shift-move-log">
                {shiftMoveLog.map((entry, i) => (
                  <li key={i}>{entry}</li>
                ))}
              </ul>
            )}

            <div className="shift-actions">
              <button type="button" className="btn-secondary" onClick={onLock} disabled={busy}>
                Lock shift
              </button>
              <button type="button" className="btn-secondary" onClick={onCloseRequest} disabled={busy}>
                Close shift
              </button>
              <button type="button" className="btn-secondary" onClick={onLogout}>
                Log out
              </button>
            </div>
          </section>
        )}

        {rail === 'terminal' && (
          <section className="terminal-panel" aria-labelledby="terminal-info-title">
            <h2 id="terminal-info-title">Terminal</h2>
            <div className="terminal-connection">
              <label htmlFor="connection-state">Connection (preview)</label>
              <select
                id="connection-state"
                value={connectionState}
                onChange={(e) => onConnectionStateChange(e.target.value as ConnectionState)}
              >
                <option value="online">Online</option>
                <option value="degraded">Degraded</option>
                <option value="offline">Offline</option>
                <option value="syncing">Syncing</option>
              </select>
            </div>
            <dl className="shift-details">
              <div><dt>Code</dt><dd>{location.terminalCode}</dd></div>
              <div><dt>Branch</dt><dd>{location.branchName || location.branchCode}</dd></div>
              <div><dt>Sales point</dt><dd>{location.salesPointName || location.salesPointCode}</dd></div>
              <div><dt>Heartbeat</dt><dd>{terminalFixture?.heartbeat ?? '—'}</dd></div>
              <div><dt>Last seen</dt><dd>{terminalFixture?.lastSeen ?? '—'}</dd></div>
              <div><dt>Receipt printer</dt><dd>{terminalFixture?.printer ?? 'Unknown'}</dd></div>
              <div><dt>KDS</dt><dd>{terminalFixture?.kds ?? 'Unknown'}</dd></div>
              <div><dt>Payment device</dt><dd>{terminalFixture?.paymentDevice ?? 'Unknown'}</dd></div>
            </dl>
          </section>
        )}

        {rail === 'help' && (
          <section className="help-panel" aria-labelledby="help-title">
            <h2 id="help-title">Help & recovery</h2>
            <ul className="help-recovery-list">
              <li>If connection shows <strong>Offline</strong>, continue cash sales and sync when back online (Team 2).</li>
              <li>If payment shows <strong>Unknown</strong>, use Check status on the terminal before retrying charge.</li>
              <li>If printer fails, reprint from Orders after sale completes (permission required).</li>
              <li>Lock shift before leaving the counter; manager closes with counted cash.</li>
              <li>Contact branch manager for enrolment codes and variance approval.</li>
            </ul>
          </section>
        )}

        {showPayment && !completedSale && (
          <PaymentPanel
            lines={cart}
            orderType={orderType}
            member={member}
            employee={employee}
            location={location}
            shift={shift}
            discountSen={discountSen}
            rewardLabel={selectedReward?.label}
            onPaid={handlePaid}
            onCancel={() => setShowPayment(false)}
          />
        )}
      </main>

      <aside className={`order-ribbon ${orderDrawerOpen ? 'order-ribbon--open' : ''}`}>
        <header className="order-ribbon__header">
          <h2>{saleLocked ? 'Completed sale' : 'Current order'}</h2>
          <button
            type="button"
            className="order-ribbon__toggle"
            aria-expanded={orderDrawerOpen}
            onClick={() => setOrderDrawerOpen((v) => !v)}
          >
            {orderDrawerOpen ? 'Close' : 'Open'}
          </button>
        </header>

        <p className="order-ribbon__type">
          {ORDER_TYPE_LABELS[orderType]}
        </p>

        {saleLocked && completedSale ? (
          <div className="order-ribbon__completed">
            <p className="order-ribbon__total">Total paid: {formatRmFromSen(completedSale.totalSen)}</p>
            <p className="form-hint">Order {completedSale.orderNumber} · {METHOD_SHORT[completedSale.method]}</p>
          </div>
        ) : cart.length === 0 ? (
          <EmptyState title="No items yet" description="Select products from the menu." />
        ) : (
          <ul className="order-lines">
            {cart.map((line) => (
              <li key={line.id} className="order-line">
                <div className="order-line__info">
                  <span className="order-line__name">{line.name}</span>
                  {line.modifierSummary && (
                    <span className="order-line__mods">{line.modifierSummary}</span>
                  )}
                  <label className="order-line__note-label">
                    Note
                    <input
                      type="text"
                      value={line.note ?? ''}
                      onChange={(e) => updateNote(line.id, e.target.value)}
                      placeholder="Item note"
                    />
                  </label>
                  <span className="order-line__price">{formatRmFromSen(line.unitPriceSen * line.qty)}</span>
                </div>
                <div className="order-line__actions">
                  <div className="order-line__qty">
                    <button type="button" aria-label="Decrease quantity" onClick={() => updateQty(line.id, -1)}>−</button>
                    <span>{line.qty}</span>
                    <button type="button" aria-label="Increase quantity" onClick={() => updateQty(line.id, 1)}>+</button>
                  </div>
                  <button type="button" className="btn-secondary btn-inline order-line__remove" onClick={() => removeLine(line.id)}>
                    Remove
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}

        {member && (
          <div className="order-ribbon__member">
            <span className="status-pill status-pill--info">{member.displayName}</span>
            {selectedReward && (
              <span className="status-pill status-pill--ok">Reward: {selectedReward.label}</span>
            )}
          </div>
        )}

        <footer className="order-ribbon__footer">
          {!saleLocked && (
            <>
              <p className="order-ribbon__total">
                Subtotal: {formatRmFromSen(cartTotalSen(cart))}
                {discountSen > 0 && (
                  <span className="order-ribbon__discount"> · −{formatRmFromSen(discountSen)} reward</span>
                )}
              </p>
              <p className="order-ribbon__total">Total: {formatRmFromSen(totalSen)}</p>
            </>
          )}
          {saleLocked ? (
            <button type="button" className="btn-primary order-ribbon__pay" onClick={startNewSale}>
              New sale
            </button>
          ) : (
            <>
              <button
                type="button"
                className="btn-primary order-ribbon__pay"
                disabled={cart.length === 0 || showPayment}
                onClick={() => setShowPayment(true)}
              >
                Pay
              </button>
              {cart.length > 0 && (
                <button type="button" className="btn-secondary" onClick={requestClearSale}>Clear</button>
              )}
            </>
          )}
        </footer>
      </aside>

      <ModifierSheet
        open={modifierItem !== null}
        itemName={modifierItem?.name ?? ''}
        basePriceSen={modifierItem?.priceSen ?? 0}
        groups={PREVIEW_MODIFIER_GROUPS}
        onConfirm={confirmModifier}
        onClose={() => setModifierItem(null)}
      />

      <ConfirmDialog
        open={clearConfirmOpen}
        title="Clear current sale?"
        message="This removes all items from the cart. This cannot be undone in preview."
        confirmLabel="Clear sale"
        onConfirm={() => {
          setClearConfirmOpen(false);
          resetSaleState();
        }}
        onCancel={() => setClearConfirmOpen(false)}
      />
    </div>
  );
}

const METHOD_SHORT: Record<PreviewSaleReceipt['method'], string> = {
  cash: 'Cash',
  card: 'Card',
  ewallet: 'E-wallet',
  student_wallet: 'Student wallet',
};
