# Privacy Notice

Consent management layer for Business Central integrations that access external
services (Teams, Power Automate, Bing, Microsoft Learn, Microsoft Copilot).
Handles the full lifecycle: creating notices, prompting users for consent,
storing approval state, and enforcing admin-level decisions that override
individual user choices.

*Updated: 2026-07-29 -- Microsoft Copilot privacy notice registered*

## Quick reference

- **Namespace**: System.Privacy
- **Public API**: Codeunit 1563 "Privacy Notice"
- **Approval enum**: Enum 1563 "Privacy Notice Approval State" (Not set / Agreed / Disagreed)

## How it works

The module uses a **two-tier approval model**: admin decisions (stored against an
empty GUID user SID) always override individual user approvals. When code calls
`ConfirmPrivacyNoticeApproval`, the decision tree is:

1. If admin agreed -- return true immediately
2. If admin disagreed -- block non-admins with a message; show the notice again
   to admins so they can re-approve
3. If no admin decision and this is an **evaluation company** -- auto-agree
   (controlled by `SkipCheckInEval` parameter, defaults to true)
4. If the current user previously agreed -- return true
5. Otherwise -- show the modal privacy notice page

The `SetApprovalState` procedure routes by permission: users with write access to
the `Privacy Notice Approval` table are treated as admins and their decision is
stored org-wide (empty GUID). Regular users can only agree (disagreements from
non-admins are not stored -- they just keep getting prompted).

Privacy notices are registered via the `OnRegisterPrivacyNotices` event. All
subscribers contribute to a temp table, and the module bulk-inserts any that don't
already exist. The `ShouldApproveByDefault` mechanism auto-approves specific
integrations on first creation. It is region-conditional, and each case is a
separate DotNet probe wrapped in a `[TryFunction]` so a platform failure degrades
to "not approved" rather than erroring:

- **Microsoft Learn** -- approved when in-geo support is detected.
- **Microsoft Copilot** -- approved when the environment is *not* within the EU
  Data Boundary (`not ALCopilotFunctions.IsWithinEUDB()`). EEA environments
  therefore start unapproved and require an explicit admin decision.

Default approval only applies at registration time. An admin can change it
afterwards on the Privacy Notices page, and that stored decision wins.

*Updated: 2026-07-29 -- Microsoft Copilot default approval keyed to EU Data Boundary*

## Structure

- `src/` -- Core logic: public facade, impl codeunit, approval storage, pages
- `src/PowerAutomate/` -- Custom privacy notice wizard for Power Automate (multi-step NavigatePage with banner image)
- `src/MicrosoftLearn/` -- Custom privacy notice for Microsoft Learn (simpler "allow data movement" toggle)
- `permissions/` -- Four permission sets (Objects, Read, View, Admin)

## Extension points

Two integration events on codeunit 1563:

- **OnBeforeShowPrivacyNotice** -- Override the default approval page for a
  specific integration. Subscribers check the `PrivacyNotice.ID`, show their own
  page, and set `Handled := true`. Used by Power Automate and Microsoft Learn
  subfolders.
- **OnRegisterPrivacyNotices** -- Register new privacy notices by inserting into
  the temp record parameter. Called during upgrade, demotool, and the "Refresh"
  action on the Privacy Notices list page.

## Things to know

- The module owns no table definitions -- `"Privacy Notice"` and `"Privacy Notice
  Approval"` are platform tables. The code reads/writes them but doesn't define
  their schema.
- `ConfirmPrivacyNoticeApproval` **must run outside a write transaction** -- it
  opens a modal dialog. The platform subscriber `ConfirmSystemPrivacyNoticeApproval`
  issues an explicit `Commit()` before calling it for exactly this reason.
- The `ShowOneTimePrivacyNotice` procedure is a fire-and-forget UI -- it creates a
  temp record, shows the page, and returns the state without persisting anything.
  Callers handle storage themselves.
- Power Automate approval changes trigger a "Sign out and sign in again"
  notification via table event subscribers on `Privacy Notice Approval`. This is
  because the Power Automate integration state is cached in the user's session.
- Admin detection is purely permission-based: `PrivacyNoticeApproval.WritePermission()`.
  The "Priv. Notice - Admin" permission set grants this.
- The Privacy Notices list page (1565) filters to `User SID = '00000000-...'`
  (empty GUID) so it only shows org-wide decisions, not per-user ones.
- `CreateDefaultPrivacyNoticesInSeparateThread` wraps `Codeunit.Run` to isolate
  registration failures -- if any subscriber errors, the calling flow isn't blocked.
- Every codeunit in the module declares `InherentEntitlements = X` and
  `InherentPermissions = X`, including the public facade (1563). This is what lets
  service-invoked callers reach the facade without the caller holding Privacy
  Notice permissions. It does not weaken the admin check, which still comes from
  `PrivacyNoticeApproval.WritePermission()`.

*Updated: 2026-07-29 -- inherent permissions on the facade for service-invoked callers*
