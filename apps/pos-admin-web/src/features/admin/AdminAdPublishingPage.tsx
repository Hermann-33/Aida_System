import { useState } from 'react';
import { AdminPageShell } from './AdminPageShell';
import './admin.css';

/**
 * Advertisement / home-banner publishing preview for the customer app surface.
 * Distinct from App campaigns — this page is home-rail creatives only.
 */
export function AdminAdPublishingPage() {
  const [headline, setHeadline] = useState('Welcome back, City U');
  const [cta, setCta] = useState('Order ahead · earn stamps');
  const [slot, setSlot] = useState<'home-hero' | 'offers-rail'>('home-hero');
  const [live, setLive] = useState(false);

  return (
    <AdminPageShell
      pageId="admin-ad-publishing"
      title="Ad and banner publishing"
      hint="Customer-app home creatives. Publish is simulated — no customer feed is updated."
    >
      <div className="admin-page--split admin-page--split-inline">
        <form
          className="admin-form"
          onSubmit={(e) => {
            e.preventDefault();
            setLive(true);
          }}
        >
          <label>
            Placement
            <select value={slot} onChange={(e) => setSlot(e.target.value as typeof slot)}>
              <option value="home-hero">Home hero</option>
              <option value="offers-rail">Offers rail</option>
            </select>
          </label>
          <label>
            Headline
            <input value={headline} onChange={(e) => setHeadline(e.target.value)} />
          </label>
          <label>
            Call to action
            <input value={cta} onChange={(e) => setCta(e.target.value)} />
          </label>
          <button type="submit" className="btn-primary">
            Simulate publish
          </button>
          <p className="form-hint" role="status">
            {live
              ? 'Simulated publish recorded in UI only — customer app not contacted.'
              : 'Draft creative — not live on any device.'}
          </p>
        </form>

        <aside className="mobile-preview" aria-label="Ad placement preview">
          <h2 className="admin-section-title">Placement preview ({slot})</h2>
          <div className="mobile-preview__frame">
            <div className="mobile-preview__status" />
            <div className={`mobile-preview__banner ${live ? '' : 'mobile-preview__banner--inactive'}`}>
              <strong>{headline}</strong>
              <p>{cta}</p>
            </div>
            <div className="mobile-preview__content" />
          </div>
        </aside>
      </div>
    </AdminPageShell>
  );
}
