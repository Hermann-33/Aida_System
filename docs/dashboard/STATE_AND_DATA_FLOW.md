# POS/Admin State and Data Flow

## Application shell

`ProtectedRoute` and preview roles control navigation/UX only. They are not backend authorization.

## Admin Members path on TASK-AUTH-001 branch

```text
AdminMembersLoyaltyReportPage
  -> fetchAdminMembers()
  -> GET /api/v1/admin/members with credentials: include
  -> [trusted staff/admin BFF/session NOT YET IMPLEMENTED]
  -> public.list_admin_members() as authenticated admin/owner under RLS
  -> member rows
```

The browser layer has no member fixture fallback and no Supabase privileged credential. Loading, authorization and server errors fail visibly instead of reverting to sample members.

The database capability is live, but the missing BFF/session means this remains a planned transport contract rather than an end-to-end production flow.

## Other dashboard state sources

- React component state for most workflows.
- Preview employee/terminal session adapters and session storage.
- Module memory for preview shift state.
- Deterministic fixtures under `src/preview/` for unintegrated domains.
- Rewards Activity, POS, catalogue, orders, payments, loyalty, inventory and reporting remain preview/local.

## Real connection direction

TASK-AUTH-002 must establish the server-side session/API boundary before privileged dashboard reads. Subsequent feature tasks should continue replacing each fixture/local source with capability-specific shared-backend queries/mutations, without broad browser privilege.
