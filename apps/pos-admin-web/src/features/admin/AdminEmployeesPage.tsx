import { PREVIEW_EMPLOYEES } from '../../preview/fixtures/catalog';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

export function AdminEmployeesPage() {
  return (
    <AdminPageShell pageId="admin-employees" title="Employees and access" hint="Credentials never displayed — permissions are illustrative.">
      <table className="data-table admin-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Username</th>
            <th>Role</th>
            <th>Branches</th>
            <th>Global manager</th>
            <th>Active</th>
            <th>Permissions</th>
          </tr>
        </thead>
        <tbody>
          {PREVIEW_EMPLOYEES.map((emp) => (
            <tr key={emp.id}>
              <td>{emp.name}</td>
              <td>{emp.username}</td>
              <td>{emp.role}</td>
              <td>{emp.branches.join(', ')}</td>
              <td>{emp.isGlobalManager ? 'Yes' : 'No'}</td>
              <td>{emp.active ? 'Yes' : 'No'}</td>
              <td className="admin-permissions-cell">{emp.permissions.join(', ')}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </AdminPageShell>
  );
}
