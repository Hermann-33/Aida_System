import type { EmployeeIdentity, ShiftSummary, TerminalLocation } from '../../auth/types';
import type { OrderType, PreviewMember } from '../../preview/fixtures/catalog';
import { PREVIEW_REWARD_RULES } from '../../preview/fixtures/catalog';
import type { CartLine } from './cartTypes';
import { cartTotalSen } from './cartTypes';

export type PaymentMethod = 'cash' | 'card' | 'ewallet' | 'student_wallet';

export interface PreviewSaleReceipt {
  orderNumber: string;
  dateTime: string;
  employeeName: string;
  employeeRole: string;
  branchCode: string;
  branchName?: string;
  salesPointCode: string;
  salesPointName?: string;
  terminalCode: string;
  shiftId: string;
  shiftStatus: string;
  orderType: OrderType;
  lines: CartLine[];
  subtotalSen: number;
  discountSen: number;
  rewardLabel?: string;
  totalSen: number;
  method: PaymentMethod;
  tenderSen?: number;
  changeSen?: number;
  providerRef?: string;
  memberName?: string;
  pointsBefore?: number;
  pointsEarned?: number;
  pointsAfter?: number;
  stampsBefore?: number;
  stampsEarned?: number;
  stampsAfter?: number;
  printStatus: 'pending' | 'printed' | 'failed';
}

let previewOrderSeq = 10522;

export function nextPreviewOrderNumber(): string {
  previewOrderSeq += 1;
  return `A-${previewOrderSeq}`;
}

/** Test helper */
export function resetPreviewOrderSequence(forTest = 10521) {
  previewOrderSeq = forTest;
}

export function buildPreviewReceipt(params: {
  lines: CartLine[];
  orderType: OrderType;
  method: PaymentMethod;
  employee: EmployeeIdentity;
  location: TerminalLocation;
  shift: ShiftSummary;
  member: PreviewMember | null;
  discountSen: number;
  rewardLabel?: string;
  tenderSen?: number;
  changeSen?: number;
  providerRef?: string;
  orderNumber?: string;
  dateTime?: string;
}): PreviewSaleReceipt {
  const subtotalSen = cartTotalSen(params.lines);
  const totalSen = Math.max(0, subtotalSen - params.discountSen);
  const totalRm = Math.floor(totalSen / 100);
  const pointsEarned = params.member ? totalRm * PREVIEW_REWARD_RULES.pointsPerRm : 0;
  const stampsEarned = params.member ? PREVIEW_REWARD_RULES.stampsPerPurchase : 0;
  const pointsBefore = params.member?.points;
  const stampsBefore = params.member?.stamps;
  let stampsAfter = stampsBefore;
  if (stampsBefore !== undefined && stampsEarned) {
    stampsAfter = stampsBefore + stampsEarned;
    if (stampsAfter >= PREVIEW_REWARD_RULES.stampsForFreeDrink) {
      stampsAfter -= PREVIEW_REWARD_RULES.stampsForFreeDrink;
    }
  }

  return {
    orderNumber: params.orderNumber ?? nextPreviewOrderNumber(),
    dateTime: params.dateTime ?? new Date().toISOString(),
    employeeName: params.employee.fullName,
    employeeRole: params.employee.role,
    branchCode: params.location.branchCode,
    branchName: params.location.branchName,
    salesPointCode: params.location.salesPointCode,
    salesPointName: params.location.salesPointName,
    terminalCode: params.location.terminalCode,
    shiftId: params.shift.id,
    shiftStatus: params.shift.status,
    orderType: params.orderType,
    lines: params.lines.map((l) => ({ ...l })),
    subtotalSen,
    discountSen: params.discountSen,
    rewardLabel: params.rewardLabel,
    totalSen,
    method: params.method,
    tenderSen: params.tenderSen,
    changeSen: params.changeSen,
    providerRef: params.providerRef,
    memberName: params.member?.displayName,
    pointsBefore,
    pointsEarned: pointsEarned || undefined,
    pointsAfter: pointsBefore !== undefined ? pointsBefore + pointsEarned : undefined,
    stampsBefore,
    stampsEarned: stampsEarned || undefined,
    stampsAfter,
    printStatus: 'pending',
  };
}
