import { Link } from 'react-router-dom';
import { UiPreviewBanner } from '../shared/components/UiPreviewBanner';

export function UnauthorizedPage() {
  return (
    <div className="shell-unauthorized">
      <UiPreviewBanner />
      <section className="shell-card" aria-labelledby="unauthorized-title">
        <h1 id="unauthorized-title">Unauthorized</h1>
        <p>You do not have access to this employee product surface.</p>
        <p>
          <Link to="/employee">Return to employee welcome</Link>
        </p>
      </section>
    </div>
  );
}
