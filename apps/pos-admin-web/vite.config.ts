/// <reference types="vitest/config" />
import { defineConfig, loadEnv, type Plugin } from 'vite';
import react from '@vitejs/plugin-react';

/**
 * Fail production builds if employee-auth bypass is enabled.
 */
function failClosedAuthPlugin(mode: string): Plugin {
  return {
    name: 'aida-fail-closed-employee-auth',
    configResolved() {
      if (mode !== 'production') return;
      const env = loadEnv(mode, process.cwd(), '');
      if (env.VITE_ALLOW_AUTH_BYPASS === 'true') {
        throw new Error(
          'FATAL: VITE_ALLOW_AUTH_BYPASS=true is not allowed for production builds. '
          + 'Employee authentication must fail closed.',
        );
      }
      if (env.VITE_UI_PREVIEW_MODE === 'true') {
        throw new Error(
          'FATAL: VITE_UI_PREVIEW_MODE=true is not allowed for production builds. '
          + 'UI preview fixtures must fail closed.',
        );
      }
    },
  };
}

export default defineConfig(({ mode }) => ({
  plugins: [react(), failClosedAuthPlugin(mode)],
  test: {
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    globals: true,
    exclude: ['**/node_modules/**', '**/e2e/**', '**/dist/**'],
  },
  server: {
    port: 5173,
    // Frontend-only migration: do not proxy to a production/local API.
    // Preview mode uses in-app fixtures; enable a proxy later only when Team 2 adapters land.
  },
}));
