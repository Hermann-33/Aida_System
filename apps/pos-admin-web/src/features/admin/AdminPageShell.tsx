import type { ReactNode } from 'react';
import './admin.css';

type Props = {
  pageId: string;
  title: string;
  hint?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
};

export function AdminPageShell({ pageId, title, hint, actions, children }: Props) {
  const titleId = `${pageId}-title`;
  return (
    <section className="admin-page" data-page={pageId} aria-labelledby={titleId}>
      <header className={`admin-page__header${actions ? ' admin-page__header--row' : ''}`}>
        <div>
          <h1 id={titleId}>{title}</h1>
          <p className="admin-preview-note" role="note">
            UI PREVIEW capability — sample fixture data only. Production API integration pending (Team 2).
          </p>
          {hint ? <p className="form-hint">{hint}</p> : null}
        </div>
        {actions}
      </header>
      {children}
    </section>
  );
}
