# Expense interim approval setting

Last updated: 2026-10-09 16:10 UTC+2

## Overview

Add a company-level setting that controls whether users can assign interim approvers to expense reports. Expose the setting through the Expense Agent setup wizard and the Expense Capabilities API.

## Goals

- Let administrators enable or disable new interim approver assignments.
- Preserve interim approval behavior for companies upgrading from Business Central 29.x.
- Let the Expense app discover the setting through a Boolean capability.
- Avoid stranding reports that are already waiting for interim approval.

## User stories

- As an administrator, I can control whether submitters may assign interim approvers.
- As the Expense app, I can determine whether to offer interim approval features.
- As an interim approver with an existing assignment, I can complete approval after the setting is disabled.

## Functional requirements

1. Add `"Allow Interim Approvers"` to `"Expense Agent Setup"`.
2. Default the setting to `true` for new and existing companies because interim approval was released in Business Central 29.x.
3. Show the setting in the setup wizard under **Who can access**.
4. Add the `InterimApproval` expense capability.
5. Return the setup value as the capability's `isEnabled` value.
6. Reject new interim approver assignments when the setting is disabled.
7. Hide the assignment action when the setting is disabled.
8. Allow reports already assigned to an interim approver to complete interim and final approval.
9. When a rejected or reopened report is resubmitted while the setting is disabled, clear its stale interim assignment and route it to the final approver.

## Non-goals

- Bulk-rerouting reports when the setting is disabled.
- Preventing an already assigned interim approver from acting.
- Changing final approver selection or approval limits.

## Technical considerations

- Enforce the setting in `"Expense Report Approval Mgmt"` so API, UI, and record calls behave consistently.
- Use the existing `"Expense Capability"` enum and `"Expense Capabilities Provider"` dispatch pattern.
- Use an upgrade tag to set the field to `true` for existing companies.
- Keep the capability API schema unchanged because it dynamically emits enum values.

## Implementation notes

- The setting uses field 123 and `InitValue = true`.
- Upgrade tag `MS-ExpenseAgent-AllowInterimApproversDefault-20261009` enables it for existing companies.
- Capability `InterimApproval` mirrors the stored setting.
- Disabling the setting blocks assignment and prevents resubmission from reusing an old interim approver. It doesn't interrupt an active interim approval.

## Success criteria

- New assignments fail while the setting is off.
- Existing assignments continue through final approval.
- Resubmitted reports don't reactivate interim approval while the setting is off.
- The wizard and capability API reflect the stored setting.
- Targeted interim approval and capability tests pass.

## Open questions

None.

## Verification

- The Expense Agent app builds successfully with CodeCop.
- Focused capability and interim approval regression tests were added.
- Local test execution is blocked by missing standard test-library symbols in the test package cache.
