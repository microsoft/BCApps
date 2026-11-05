# Expense Agent company-bound Gateway requests

## Activation and identity

Enable `MULTI_COMPANY_SELECTION_ENABLED` in the target Gateway fleet **before**
deploying this caller change. A scoped request currently receives HTTP 404 when
that Gateway feature is disabled. Never work around this by removing the header.
Company activation and ERP registration remain required.

The BC caller calculates `X-ERP-Scope` on every company-bound request using UUIDv5
with namespace `7d8f2d5b-0e56-5f2d-9b39-6ce7f2f54844`. The inputs are the same
Entra tenant ID, actual environment name, and actual company GUID used during
registration. ASCII-only normalization and UTF-8 byte-length prefixes are
implemented in [EA Company Scope](app/src/Integration/EACompanyScope.Codeunit.al).
Display names, mailbox addresses, routing region, and delegated user identity
are not inputs.

This supersedes guidance to store the registration response's `scopeId`: do not
persist or cache it, add a setup field, or introduce an upgrade migration.
Registration input and authentication are unchanged. The scope is a selector,
not an authorization credential, and calculating it does not register a company.

## Request inventory and asynchronous context

[EA Http Client](app/src/Integration/EAHttpClient.Codeunit.al) adds exactly one
request-local header to:

| Endpoint | Origin |
| --- | --- |
| `/api/v1.0/expenses/process` | Incoming EA Email record's company; includes receipt attachments in the existing multipart body |
| `/api/v1.0/notifications/open-reports-reminder` | Expense User record's company |
| `/api/v1.0/notifications/reimbursement` | Posted Expense Report Header record's company |
| `/api/v1.0/notifications/welcome` | Queued Expense User record's company |

ERP registration/unregistration and canary discovery are intentionally unscoped.
There are no separate Gateway status/polling or attachment-download requests in
this integration. Outbox delivery uses BC email facilities, not these endpoints.

The scheduler explicitly supplies the company to `TaskScheduler.CreateTask`.
Dispatcher, recovery, pending email, and welcome queues are company-local.
Each HTTP entry point requires the originating record's company, resolves its
actual company GUID, and reads endpoint setup in that company using
`ChangeCompany`. It never uses a reused HttpClient default-header collection.
Each subsequent call recalculates the scope; there is no derived scope state to
copy. New work in a company/environment copy uses the target identity. Retries
of existing work must remain in their originating company and environment.

## Failure handling and diagnostics

There is no unscoped retry, first-company selection, or automatic re-registration.
Missing identity raises an actionable error before sending. HTTP 409 raises an
actionable registration error for the originating company. Other non-success
statuses retain the existing failure handling and telemetry. Notification
telemetry includes HTTP status, not the scope or response body.

| Gateway response | Support action |
| --- | --- |
| 400 `VALIDATION_FAILED` | Check canonical UUID format and caller/server vector parity. |
| 400 `ERP_SELECTION_REQUIRED` | Check that the request has exactly one nonempty request header. |
| 409 `ERP_SELECTION_STALE` | Refresh/re-register the same originating company through setup; do not select another company. |
| 403 | Check the existing user permission/delegation configuration. Scope does not grant access. |
| 503 `ERP_SELECTION_UNAVAILABLE` | Preserve origin and observe `Retry-After` before an explicitly safe retry. |
| 404 after deployment | Check fleet feature activation before investigating routing. |

The HTTP client has no existing bounded HTTP retry policy. This change does not
introduce one or replay mutation POSTs: neither a 503 nor a transport failure
proves that a submission was not accepted. Existing scheduled processing remains
unchanged. Do not add a blanket POST retry without an idempotency contract.
Use existing correlation IDs and status telemetry for diagnostics; do not emit
scope values as unclassified telemetry.

## Validation

[EA Company Scope Test](test/src/EACompanyScopeTest.Codeunit.al) covers both
published cross-language vectors, UTF-8 byte lengths, ASCII normalization,
nonbreaking spaces, GUID forms, blank rejection, delimiter safety, copy
identities, and request-local header replacement without changing delegation.
Build both the app and test projects on BC 30 and run codeunit 148332 using the
repository's BC test environment.

Before rollout, run these live integration checks against a Gateway with
multi-company selection enabled (unit tests do not establish Gateway behavior):

1. Register two companies in each of two environments for the same eligible
   user. Compare each registration response's `scopeId` with the AL calculation
   as a test assertion only; do not store it in setup.
2. Exercise all four endpoints, including receipt attachments and scheduled
   welcome/reminder processing. Reverse registration order and change the
   interactive session company before scheduled execution. Verify the resulting
   work belongs only to its originating company/environment.
3. Inject absent, empty, malformed, stale, and unauthorized scopes. Assert the
   documented 400/409/403 failures, no work in another company, and no retry
   without the same header. A stale response must identify setup remediation.
4. Inject a 503 with `Retry-After` and a transport failure. Assert no immediate
   automatic POST replay. For any explicitly safe retry, retain origin, recompute
   scope, and verify that no duplicate mutation was created.
5. Copy a company and an environment, register the targets, and verify new work
   uses the target scopes. Rename only a company display name or change routing
   region and verify the calculated scope remains unchanged.

Local environment setup and test prerequisites are documented in
[Local Development Environment](../../../../LOCAL_DEV_ENV.md).
