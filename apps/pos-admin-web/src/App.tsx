import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ProtectedRoute } from './auth/ProtectedRoute';
import { EmployeeLayout } from './layouts/EmployeeLayout';
import { PosLayout } from './layouts/PosLayout';
import { AdminLayout } from './layouts/AdminLayout';
import { EmployeeWelcomePage } from './pages/EmployeeWelcomePage';
import { RoleSelectPage } from './pages/RoleSelectPage';
import { PosShellPage } from './pages/PosShellPage';
import { UnauthorizedPage } from './pages/UnauthorizedPage';
import { AdminOverviewPage } from './features/admin/AdminOverviewPage';
import { AdminLiveOpsPage } from './features/admin/AdminLiveOpsPage';
import { AdminSalesReportPage } from './features/admin/AdminSalesReportPage';
import { AdminBranchComparePage } from './features/admin/AdminBranchComparePage';
import { AdminTransactionsPage } from './features/admin/AdminTransactionsPage';
import { AdminProductsReportPage } from './features/admin/AdminProductsReportPage';
import { AdminPaymentsReportPage } from './features/admin/AdminPaymentsReportPage';
import { AdminShiftCashReportPage } from './features/admin/AdminShiftCashReportPage';
import { AdminRewardsReportPage } from './features/admin/AdminRewardsReportPage';
import { AdminMembersReportPage } from './features/admin/AdminMembersReportPage';
import { AdminVoidsReportPage } from './features/admin/AdminVoidsReportPage';
import { AdminInventoryReportPage } from './features/admin/AdminInventoryReportPage';
import { AdminExportsPage } from './features/admin/AdminExportsPage';
import { AdminBranchesPage } from './features/admin/AdminBranchesPage';
import { AdminTerminalsPage } from './features/admin/AdminTerminalsPage';
import { AdminShiftsPage } from './features/admin/AdminShiftsPage';
import { AdminEmployeesPage } from './features/admin/AdminEmployeesPage';
import { AdminMenuPage } from './features/admin/AdminMenuPage';
import { AdminMenuEditorPage } from './features/admin/AdminMenuEditorPage';
import { AdminCategoriesPage } from './features/admin/AdminCategoriesPage';
import { AdminVariantsPage } from './features/admin/AdminVariantsPage';
import { AdminInventoryStockPage } from './features/admin/AdminInventoryStockPage';
import { AdminRecipesPage } from './features/admin/AdminRecipesPage';
import { AdminWastagePage } from './features/admin/AdminWastagePage';
import { AdminLoyaltyPage } from './features/admin/AdminLoyaltyPage';
import { AdminStampsPage } from './features/admin/AdminStampsPage';
import { AdminOffersPage } from './features/admin/AdminOffersPage';
import { AdminCampaignsPage } from './features/admin/AdminCampaignsPage';
import { AdminAdPublishingPage } from './features/admin/AdminAdPublishingPage';
import { AdminSalesPointsPage } from './features/admin/AdminSalesPointsPage';
import { AdminAuditPage } from './features/admin/AdminAuditPage';
import { AdminIntegrationsPage } from './features/admin/AdminIntegrationsPage';
import { AdminSettingsPage } from './features/admin/AdminSettingsPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Navigate to="/employee" replace />} />

          <Route element={<ProtectedRoute product="employee" allowAnonymous />}>
            <Route element={<EmployeeLayout />}>
              <Route path="/employee" element={<EmployeeWelcomePage />} />
            </Route>
          </Route>

          <Route element={<ProtectedRoute product="employee" />}>
            <Route element={<EmployeeLayout />}>
              <Route path="/employee/select-role" element={<RoleSelectPage />} />
            </Route>
          </Route>

          <Route element={<ProtectedRoute product="pos" />}>
            <Route element={<PosLayout />}>
              <Route path="/pos" element={<PosShellPage />} />
            </Route>
          </Route>

          <Route element={<ProtectedRoute product="admin" />}>
            <Route element={<AdminLayout />}>
              <Route path="/admin" element={<AdminOverviewPage />} />
              <Route path="/admin/live" element={<AdminLiveOpsPage />} />
              <Route path="/admin/reports/sales" element={<AdminSalesReportPage />} />
              <Route path="/admin/reports/branches" element={<AdminBranchComparePage />} />
              <Route path="/admin/reports/transactions" element={<AdminTransactionsPage />} />
              <Route path="/admin/reports/products" element={<AdminProductsReportPage />} />
              <Route path="/admin/reports/payments" element={<AdminPaymentsReportPage />} />
              <Route path="/admin/reports/shifts" element={<AdminShiftCashReportPage />} />
              <Route path="/admin/reports/rewards" element={<AdminRewardsReportPage />} />
              <Route path="/admin/reports/members" element={<AdminMembersReportPage />} />
              <Route path="/admin/reports/voids" element={<AdminVoidsReportPage />} />
              <Route path="/admin/reports/inventory" element={<AdminInventoryReportPage />} />
              <Route path="/admin/reports/exports" element={<AdminExportsPage />} />
              <Route path="/admin/operations/branches" element={<AdminBranchesPage />} />
              <Route path="/admin/operations/sales-points" element={<AdminSalesPointsPage />} />
              <Route path="/admin/operations/terminals" element={<AdminTerminalsPage />} />
              <Route path="/admin/operations/shifts" element={<AdminShiftsPage />} />
              <Route path="/admin/operations/employees" element={<AdminEmployeesPage />} />
              <Route path="/admin/catalogue/menu" element={<AdminMenuPage />} />
              <Route path="/admin/catalogue/menu/:id" element={<AdminMenuEditorPage />} />
              <Route path="/admin/catalogue/categories" element={<AdminCategoriesPage />} />
              <Route path="/admin/catalogue/variants" element={<AdminVariantsPage />} />
              <Route path="/admin/inventory/stock" element={<AdminInventoryStockPage />} />
              <Route path="/admin/inventory/recipes" element={<AdminRecipesPage />} />
              <Route path="/admin/inventory/wastage" element={<AdminWastagePage />} />
              <Route path="/admin/rewards/loyalty" element={<AdminLoyaltyPage />} />
              <Route path="/admin/rewards/stamps" element={<AdminStampsPage />} />
              <Route path="/admin/rewards/offers" element={<AdminOffersPage />} />
              <Route path="/admin/rewards/campaigns" element={<AdminCampaignsPage />} />
              <Route path="/admin/rewards/ads" element={<AdminAdPublishingPage />} />
              <Route path="/admin/system/audit" element={<AdminAuditPage />} />
              <Route path="/admin/system/integrations" element={<AdminIntegrationsPage />} />
              <Route path="/admin/system/settings" element={<AdminSettingsPage />} />
            </Route>
          </Route>

          <Route path="/unauthorized" element={<UnauthorizedPage />} />
          <Route path="*" element={<Navigate to="/employee" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
