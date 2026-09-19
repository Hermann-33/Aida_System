-- Phase 9 RPC boundary repair.
-- Public SECURITY INVOKER wrappers may only reach explicitly granted private
-- implementation functions when the caller also has USAGE on schema private.
-- USAGE does not grant table access or function execution by itself.

grant usage on schema private to authenticated, service_role;
