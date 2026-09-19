-- Preserve the pre-Phase-4 API contract: invalid lead-time relationships are
-- reported as invalid_parameter_value instead of leaking a raw check violation.
-- The table CHECK remains as a second line of defense.

create or replace function private.validate_branch_ordering_policy_impl()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.preparation_lead_minutes > new.minimum_lead_minutes then
    raise exception 'preparationLeadMinutes cannot exceed minimumLeadMinutes'
      using errcode = '22023', detail = 'PREPARATION_LEAD_EXCEEDS_MINIMUM';
  end if;
  return new;
end;
$$;

revoke all on function private.validate_branch_ordering_policy_impl() from public, anon, authenticated;

drop trigger if exists branch_ordering_policy_validate on public.branch_ordering_policies;
create trigger branch_ordering_policy_validate
before insert or update on public.branch_ordering_policies
for each row execute function private.validate_branch_ordering_policy_impl();
