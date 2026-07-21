import { useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useSyncExternalStore } from 'react';
import { getEmployeeSession, logoutEmployee, subscribeEmployeeSession } from '../../auth/employeeSession';
import { hasGlobalManagerCapability } from '../../auth/permissions';
import {
  FIXTURE_TODAY,
  overviewKpis,
  PREVIEW_HOURLY_SALES,
  PREVIEW_SALES_BY_POINT,
} from '../../preview/fixtures/catalog';
import { MetricCard } from '../../shared/components/MetricCard';
import { formatRmFromSen } from '../../shared/formatting/money';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

type Period = 'today' | 'month';

export function AdminOverviewPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const period: Period = searchParams.get('period') === 'month' ? 'month' : 'today';
  const session = useSyncExternalStore(subscribeEmployeeSession, getEmployeeSession, getEmployeeSession);
  const identity = session.identity;
  const global = hasGlobalManagerCapability(identity);
  const kpis = useMemo(() => overviewKpis(period), [period]);
  const maxHourly = Math.max(...PREVIEW_HOURLY_SALES);
  const maxPoint = Math.max(...PREVIEW_SALES_BY_POINT.map((p) => p.sen));

  function setPeriod(next: Period) {
    if (next === 'today') {
      searchParams.delete('period');
      setSearchParams(searchParams, { replace: true });
    } else {
      setSearchParams({ period: 'month' }, { replace: true });
    }
  }

  return (
    <AdminPageShell
      pageId="admin-dashboard"
      title="Executive Dashboard"
      hint={`${identity?.fullName ?? 'Admin'}${global ? ' · Global manager' : ' · Branch-scoped'} · ${period === 'today' ? 'Today' : 'This month (sample scale ×25)'}`}
    >
      <div className="admin-period-toggle" role="group" aria-label="Dashboard period">
        <button
          type="button"
          className={`menu-tab ${period === 'today' ? 'menu-tab--active' : ''}`}
          onClick={() => setPeriod('today')}
        >
          Today
        </button>
        <button
          type="button"
          className={`menu-tab ${period === 'month' ? 'menu-tab--active' : ''}`}
          onClick={() => setPeriod('month')}
        >
          This month
        </button>
      </div>

      <div className="metric-grid">
        {kpis.map((kpi) => (
          <MetricCard key={kpi.label} label={kpi.label} value={kpi.value} hint={kpi.hint} />
        ))}
      </div>

      <div className="admin-charts">
        <article className="chart-card">
          <h2 className="admin-section-title">Hourly sales (sample)</h2>
          <svg className="bar-chart" viewBox="0 0 320 120" role="img" aria-label="Hourly sales bar chart">
            {PREVIEW_HOURLY_SALES.map((val, i) => {
              const h = (val / maxHourly) * 90;
              return (
                <rect
                  key={i}
                  x={10 + i * 36}
                  y={100 - h}
                  width={24}
                  height={h}
                  fill="var(--aida-rose)"
                  rx={4}
                />
              );
            })}
          </svg>
          <table className="data-table admin-chart-table">
            <caption className="visually-hidden">Hourly sales sample values</caption>
            <thead>
              <tr>
                <th>Hour block</th>
                <th>Index value</th>
              </tr>
            </thead>
            <tbody>
              {PREVIEW_HOURLY_SALES.map((val, i) => (
                <tr key={i}>
                  <td>{7 + i}:00</td>
                  <td>{val}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </article>

        <article className="chart-card">
          <h2 className="admin-section-title">Sales by sales point</h2>
          <ul className="point-compare">
            {PREVIEW_SALES_BY_POINT.map((row) => (
              <li key={row.point}>
                <span>{row.point}</span>
                <div className="point-bar">
                  <div
                    className="point-bar__fill"
                    style={{ width: `${(row.sen / maxPoint) * 100}%` }}
                  />
                </div>
                <span>{formatRmFromSen(row.sen)}</span>
              </li>
            ))}
          </ul>
          <table className="data-table admin-chart-table">
            <caption className="visually-hidden">Sales by sales point</caption>
            <thead>
              <tr>
                <th>Sales point</th>
                <th>Net sales</th>
              </tr>
            </thead>
            <tbody>
              {PREVIEW_SALES_BY_POINT.map((row) => (
                <tr key={row.point}>
                  <td>{row.point}</td>
                  <td>{formatRmFromSen(row.sen)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </article>

        <article className="chart-card">
          <h2 className="admin-section-title">Trend (sample)</h2>
          <svg className="line-chart" viewBox="0 0 320 80" role="img" aria-label="Sales trend line chart">
            <polyline
              fill="none"
              stroke="var(--aida-burgundy)"
              strokeWidth="2"
              points={PREVIEW_HOURLY_SALES.map((v, i) => `${10 + i * 36},${70 - (v / maxHourly) * 60}`).join(' ')}
            />
          </svg>
        </article>
      </div>

      <aside className="admin-alerts">
        <h2 className="admin-section-title">Alerts</h2>
        <ul>
          <li>
            <span className="status-pill status-pill--warn">Variance</span> Shift s3 closed with RM 35.00 short
          </li>
          <li>
            <span className="status-pill status-pill--info">Terminal</span> POS-MAIN-02 enrolment pending
          </li>
          <li>
            <span className="status-pill status-pill--warn">Rewards</span>{' '}
            {FIXTURE_TODAY.rewardRedemptions} redemptions today — review discount reasons
          </li>
        </ul>
      </aside>

      <button
        type="button"
        className="btn-secondary admin-logout"
        onClick={() => void logoutEmployee().then(() => { window.location.href = '/employee'; })}
      >
        Log out
      </button>
    </AdminPageShell>
  );
}
