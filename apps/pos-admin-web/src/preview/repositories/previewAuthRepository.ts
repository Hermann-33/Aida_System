/**
 * Preview-only employee session persistence.
 * Survives full page reloads for screenshot automation / SPA remounts.
 * NEVER used outside UI preview mode. Stores identity fields only — no passwords, PINs, or tokens.
 */
import type { EmployeeIdentity } from '../../auth/types';
import { PREVIEW_DEMO_ACCOUNTS } from '../demoAccounts';

const BRANCH_MAIN = 'preview-branch-main';
const STORAGE_KEY = 'aida.uiPreview.employeeIdentity';

function staffIdentity(): EmployeeIdentity {
  return {
    id: 'preview-staff-01',
    username: PREVIEW_DEMO_ACCOUNTS.staff.username,
    role: 'staff',
    fullName: 'Preview Staff',
    isGlobalManager: false,
    dualRolePosEnabled: false,
    selectedProduct: 'pos',
    assignedBranchIds: [BRANCH_MAIN],
    authMethod: 'password',
  };
}

function adminIdentity(): EmployeeIdentity {
  return {
    id: 'preview-admin-01',
    username: PREVIEW_DEMO_ACCOUNTS.admin.username,
    role: 'admin',
    fullName: 'Preview Admin',
    isGlobalManager: true,
    dualRolePosEnabled: false,
    selectedProduct: 'admin',
    assignedBranchIds: [BRANCH_MAIN],
    authMethod: 'password',
  };
}

function dualIdentity(selected: 'pos' | 'admin' | null = null): EmployeeIdentity {
  return {
    id: 'preview-dual-01',
    username: PREVIEW_DEMO_ACCOUNTS.dual.username,
    role: 'admin',
    fullName: 'Preview Dual Role',
    isGlobalManager: false,
    dualRolePosEnabled: true,
    selectedProduct: selected,
    assignedBranchIds: [BRANCH_MAIN],
    requiresProductSelection: !selected,
    authMethod: 'password',
  };
}

function readStored(): EmployeeIdentity | null {
  if (typeof sessionStorage === 'undefined') return null;
  try {
    const raw = sessionStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as EmployeeIdentity;
  } catch {
    return null;
  }
}

function writeStored(identity: EmployeeIdentity | null) {
  if (typeof sessionStorage === 'undefined') return;
  if (!identity) {
    sessionStorage.removeItem(STORAGE_KEY);
    return;
  }
  sessionStorage.setItem(STORAGE_KEY, JSON.stringify(identity));
}

let previewSession: EmployeeIdentity | null = readStored();

export const previewAuthRepository = {
  getSession(): EmployeeIdentity | null {
    if (!previewSession) previewSession = readStored();
    return previewSession;
  },

  loginWithPassword(username: string, password: string): EmployeeIdentity {
    const u = username.trim().toLowerCase();
    const p = password;
    if (u === PREVIEW_DEMO_ACCOUNTS.staff.username && p === PREVIEW_DEMO_ACCOUNTS.staff.password) {
      previewSession = staffIdentity();
      writeStored(previewSession);
      return previewSession;
    }
    if (u === PREVIEW_DEMO_ACCOUNTS.admin.username && p === PREVIEW_DEMO_ACCOUNTS.admin.password) {
      previewSession = adminIdentity();
      writeStored(previewSession);
      return previewSession;
    }
    if (u === PREVIEW_DEMO_ACCOUNTS.dual.username && p === PREVIEW_DEMO_ACCOUNTS.dual.password) {
      previewSession = dualIdentity(null);
      writeStored(previewSession);
      return previewSession;
    }
    const err = new Error('Invalid demonstration credentials') as Error & { code?: string };
    err.code = 'INVALID_CREDENTIALS';
    throw err;
  },

  loginWithBadge(badgeValue: string, pin: string): EmployeeIdentity {
    if (badgeValue.trim() === 'PREVIEW-BADGE' && pin === '4821') {
      previewSession = staffIdentity();
      writeStored(previewSession);
      return previewSession;
    }
    const err = new Error('Invalid demonstration badge/PIN') as Error & { code?: string };
    err.code = 'INVALID_CREDENTIALS';
    throw err;
  },

  selectProduct(product: 'pos' | 'admin'): EmployeeIdentity {
    if (!previewSession?.dualRolePosEnabled) {
      const err = new Error('Product selection not allowed') as Error & { code?: string };
      err.code = 'FORBIDDEN';
      throw err;
    }
    previewSession = dualIdentity(product);
    writeStored(previewSession);
    return previewSession;
  },

  logout() {
    previewSession = null;
    writeStored(null);
  },
};
