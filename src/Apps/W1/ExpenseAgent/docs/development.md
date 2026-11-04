# Expense Agent coding and testing guidelines

Read the [module README](../README.md) and repository
[contribution guidelines](../../../../../CONTRIBUTING.md) first. These guidelines describe specific
Expense Agent contracts, not a second general AL style guide. Preserve the existing contracts unless
a change explicitly requires different behavior and supplies the corresponding regression coverage.

## Durable invariants

### 1. Policy results belong to a particular subject and policy version

**Existing merged safeguard:** [#10031](https://github.com/microsoft/BCApps/pull/10031) introduced
versioned policy evaluation, including protection against a held parent buffer overwriting policy
state updated through a child. This is a designed correctness boundary, not evidence that every
parent/child write path is already correct.

In [Expense Report Line](../app/src/ExpenseReport/Tables/ExpenseReportLine.Table.al), `OnModify`
preserves stored policy fields before applying policy-relevant changes. `InvalidatePolicyEvaluation`
advances the subject version even before the first evaluation or when the line is already stale.
`MarkPoliciesEvaluated` rereads the subject, checks the expected version and outstanding policies, and
preserves the report-before-line locking order. Use these contracts rather than assigning a
"Cleared" state or copying evaluation fields from a stale record.

Preserve `NeutralParentModifyPreservesChildInvalidation`, `AddingParticipantWhileStaleAdvancesVersionAgain`,
`AddingItemizationInvalidatesParent`, `AddingPerDiemInvalidatesParent`, and the changed-subject and
changed-policy rejection scenarios in
[ExpensePolicyEvaluationTest](../test/src/ExpensePolicyEvaluationTest.Codeunit.al).
Policy-neutral changes and changes that remove the last applicable policy also need their intended
status preserved. The deliberate `Modify(false)` calls inside the policy helpers are not a precedent
for bypassing triggers in unrelated callers, nor is `Modify(true)` a universal concurrency fix.

### 2. Keep transaction currency, reimbursement currency, and API display state distinct

**Confirmed merged correction:** [#11004](https://github.com/microsoft/BCApps/pull/11004) removed the
copy of an expense's foreign currency into a newly created report's reimbursement currency.
[Create Expense Report](../app/src/ExpenseReport/Codeunits/CreateExpenseReport.Codeunit.al),
`GetExpenseReportHeader`, leaves the new header's reimbursement defaults intact.
`CreateExpenseReportUsesLocalCurrencyForForeignCurrencyExpense` in
[ExpenseTestII](../test/src/ExpenseTestII.Codeunit.al) checks both the LCY reimbursement header
(stored as blank) and the retained foreign-currency line. This does not forbid supported explicit
reimbursement-currency changes.

**Existing source safeguard, not a newly identified historical regression:** the
[Expense API Currency Helper](../app/src/APIs/ExpenseAPICurrencyHelper.Codeunit.al) translates between
blank internal LCY and the API's LCY code. In
[Expense Report Lines API](../app/src/APIs/ExpenseReportLinesAPI.Page.al), `OnAfterGetRecord` snapshots
`XCurrencyCodeDisplay`; `OnInsertRecord` and `OnModifyRecord` only copy back a changed display value.
Preserve equivalent behavior so an unchanged display value does not overwrite currency selected by
business validation. This guard was already in the [migration](https://github.com/microsoft/BCApps/pull/9859);
the retrospective did not establish a separate merged API-currency fix.

Category and location validation can apply rules, remove incompatible details, and select currency.
Follow the affected table's validation path; do not replace it with unconditional field assignments
or invent a universal validation order. Existing preservation scenarios include
`ExpenseLocationMustBeUpdatedWhenExpenseCategoryIsChangedInExpense` in ExpenseTestII and
`CurrencyIsUpdatedInExpenseBasedOnRulePerDiemWhenApplyRuleIsExecuted` in
[ExpenseRuleTest](../test/src/ExpenseRuleTest.Codeunit.al). These are AL business tests, not proof of
API payload handling. For API changes, add or select coverage for omitted and explicit currency
fields, LCY and FCY, and category/location changes. The display comparison alone is not general
request-field-presence tracking.

### 3. Own test fixtures and make their transaction lifetime explicit

**Merged fixture repairs:** [#11654](https://github.com/microsoft/BCApps/pull/11654) introduced
test-owned posting setup and setup restoration; [#12675](https://github.com/microsoft/BCApps/pull/12675)
also repaired prerequisites and approver-filter coverage while re-enabling APIs.
Incomplete posting setup, reused master data, and stale approval mappings can prevent a scenario
from reaching its assertion or make it depend on another test's state.

Follow `Initialize`, `CreateEmployeePostingSetup`, and `CreateExpenseCategory` in
[SpendRequestTest](../test/src/SpendRequestTest.Codeunit.al): create the required posting groups and
accounts, restore saved setup, and reset per-test data before the `IsInitialized` early exit.
For explicitly backed-up agent setup, reuse
[Library - Expense Agent](../test/src/LibraryExpenseAgent.Codeunit.al)'s backup/restore pair.
Do not treat suite initialization as per-test isolation.

[Library - Expense](../test/src/LibraryExpense.Codeunit.al)'s `CleanUpBeforeTesting` deletes master
data, policies, and evaluations and disables agent setup; `CleanTransactionalData` deletes expenses,
reports, details, and activity history. They are destructive test-company helpers, not safe cleanup
commands for an arbitrary development or shared company. Use the suite's established lifecycle,
scope owned cleanup where appropriate, and identify all committed fixture side effects.

Inspect the actual runner isolation and `TransactionModel` before changing tests that call `Commit`
or make HTTP requests. Do not infer rollback behavior from `TestType` alone, and do not make a blanket
ban on commits from an automated review comment. Preserve real posting/lifecycle coverage rather
than manufacturing records that merely satisfy a FlowField or suppressing a failing test.

### 4. Separate HTTP transport prerequisites from the business assertion

**Confirmed merged test corrections:** [#11862](https://github.com/microsoft/BCApps/pull/11862)
replaced URL concatenation with `Library - Graph Mgt` URL helpers, supplied missing fixture data,
and corrected serialized policy-subject and negative-error assertions.

Use `AppendPathToTargetURL` and `AppendQueryParameterToTargetURL` as shown in
[ExpenseActivityLogAPITest](../test/src/API/ExpenseActivityLogAPITest.Codeunit.al), rather than
assuming the base URL has no company query. In
[PolicyEvaluationsAPITest](../test/src/API/PolicyEvaluationsAPITest.Codeunit.al), the payload uses
the OData enum token `Expense_x0020_Report_x0020_Line`, not a guessed camel-case subject name.
Read the current helper's error contract: these negative tests assert both the response-code error
and the expected business diagnostic with `Assert.ExpectedError`.

Preserve `ActivityLogAPIRejectsWrites`, `UnscopedActivityAPIHidesEntries`,
`PolicyEvaluationAPIRejectsMissingSubjectVersion`, and
`PolicyEvaluationAPIRejectsMissingPolicyVersion`. Distinguish an unavailable endpoint or unauthorized
request from the expected business rejection; neither is a passing business regression test.
Choose authentication, HTTP request policy, commit visibility, and isolation for the actual runner.
These test prerequisites do not authorize bypassing production access checks.

### 5. Preserve company-scoped grants and environment-specific access gates

**Confirmed merged company-scope correction:** [#11290](https://github.com/microsoft/BCApps/pull/11290)
centralized Entra application management. Enabling one company must not substitute a different
company's grant; disabling one must preserve other companies' grants and unrelated permission sets.
Use [Expense Agent Entra App Mgt.](../app/src/Setup/Codeunits/ExpenseAgentEntraAppMgt.Codeunit.al)
rather than duplicating `Access Control` manipulation.

[#11997](https://github.com/microsoft/BCApps/pull/11997) clarified the permission checks; it is not
evidence for removing them. The current management path supports SUPER, or the checked combination
of Expense Mgmt. Admin, SECURITY, Expense Agent, Agent - Admin, and agent-management rights.
[The human review](https://github.com/microsoft/BCApps/pull/11997#discussion_r4132106765) specifically
questioned removing the checks needed to grant an application's permissions.

Preserve `ActivatingWithOtherCompanyPermissionAddsCurrentCompanyPermission`,
`DeactivatingPreservesOtherCompanyPermission`, and `DeactivatingPreservesUnrelatedPermission` in
[ExpenseAgentConfigTest](../test/src/ExpenseAgentConfigTest.Codeunit.al), plus
`SuperCanActivateWithoutAdditionalPermissionSets` in
[ExpensePermissionsTest](../test/src/ExpensePermissionsTest.Codeunit.al).
Global-grant behavior has dedicated tests; do not silently "normalize" or delete those grants.

**Additional current-source boundaries, not all retrospectively reviewed fixes:**
[Expense Agent API Validation](../app/src/Common/ExpenseAgentAPIValidation.Codeunit.al)'s
`VerifyAgentAccess` deliberately distinguishes SaaS from on-premises and checks agent/capability
enablement in SaaS. [Exp. Privacy Notice Reg.](../app/src/Setup/Codeunits/ExpPrivacyNoticeReg.Codeunit.al)
requires the Azure OpenAI and Expense Agent notices and disables the agent when approval is revoked.
Preserve these distinctions and `IsCurrentUserGuestUser` in
[EA Http Client](../app/src/Integration/EAHttpClient.Codeunit.al) and its setup/service callers. Permission
tests alone do not prove guest, privacy-consent, or SaaS capability behavior; select or add dedicated
coverage when changing those paths.

### 6. Keep explicit E2E configuration distinct from transactional reset

**Merged test-support contract, not a production authentication mandate:**
[#12850](https://github.com/microsoft/BCApps/pull/12850) merged on 2026-11-03.
In [Expense Test Handler API](../test/src/Helper/ExpenseTestHandlerAPI.Codeunit.al), `Initialize`
clears transactional test data; `Configure` explicitly provisions/enables setup and returns JSON text
containing `status` and `serviceIdentity` (`userName`, `webServicesKey`). Enabling the application
occurs even when the remaining setup is already complete.

Preserve `ServiceIdentityIsExpenseAgentApplicationUser`, `ServiceIdentityReusesKeyWithoutExpiry`,
and `ServiceIdentityRepairsEnabledApplicationWithoutUser` in
[ExpenseAgentConfigTest](../test/src/ExpenseAgentConfigTest.Codeunit.al).
Repeated configuration must not unnecessarily invalidate the key already used by a running test service.
The handler commits setup and can create an application user and a non-expiring credential; treat it
as an explicitly authorized fixture in a dedicated test environment, not a read-only health check.
Redact returned credentials from logs, attachments, screenshots, and reports.

**Cross-version integration requirement:** older test apps return only `Configure completed`.
Consumers that support those apps must retain their configured BC user/password path; consumers of
the newer response can use its service identity. Do not turn the newer least-privilege fixture into
a ban on supported legacy development setup, silently swap identities, or mistake a source checkout
for proof that the newer test app is installed. Consumer orchestration belongs in its owning tooling,
not this AL module.

## Open proposal: per-diem parent-buffer conflict

At the retrospective snapshot, [#11531](https://github.com/microsoft/BCApps/pull/11531) was **open,
not merged**. Its patch removes per-diem `OnInsert` parent invalidation and increments the held
parent version in auto-population instead. Do not document that patch as a main-branch rule or
recommend removing invalidation globally.

Current [Expense Report Line Per Diem](../app/src/ExpenseReport/Tables/ExpenseReportLinePerDiem.Table.al)
still invalidates the parent from `OnInsert`, `OnModify`, and `OnDelete`.
The [review discussion](https://github.com/microsoft/BCApps/pull/11531#discussion_r4387613046)
identifies direct writable API inserts as a preservation case. Some earlier discussion cited the copy
helper, but a triggerless existing insert is not automatically a regression introduced by this patch.
Treat review comments as hypotheses to verify against the exact path and ref, not as established fixes.

A candidate fix needs the same existing-line category-to-per-diem/location regression before and after
the patch, including generated rows, currency, amount, successful parent save, and persisted policy
versions. Preserve direct API child-insert invalidation, update/delete behavior, repeated invalidation,
and the previous evaluation timestamp/version. `AddingPerDiemInvalidatesParent` is existing coverage;
the proposal's `AutoPopulatingPerDiemInvalidatesParent` test is not on the researched main baseline.
This documentation does not claim that the UI failure was reproduced or fixed.

## Choosing tests and reporting evidence

Start with the tests named beside the changed invariant. For cross-surface changes, include the
corresponding API and permissions tests as well as the AL business test. Include affected
localization/demo-data and release/posting preservation cases when the changed behavior reaches them.
Read the current [Apps W1 AL-Go project](../../../../../build/projects/Apps%20W1/.AL-Go/settings.json)
and [local development guide](../../../../../LOCAL_DEV_ENV.md) for existing execution support rather
than copying environment-specific setup commands into this module.

For a business fix, the evidence should establish:

| Evidence | What it must distinguish |
|---|---|
| Baseline and candidate | Exact main/baseline SHA and candidate SHA; same regression scenario and meaningful inputs before/after when feasible |
| Installed provenance | App/test-app IDs, versions, package/build provenance and localization actually executed, not just repository manifests |
| Business assertions | Changed state and preservation assertions: for example amount, currency, child rows, persisted policy versions, and unchanged approval/posting behavior |
| Result accounting | Selected and executed tests; passed, failed, and skipped/not-run counts; runner/environment and exact invocation or tool arguments |
| Supporting evidence | Redacted reports; UI evidence only for UI-specific behavior; no credentials or private expense/receipt data |
| Limits | Blocked reproduction, missing prerequisites, different installed builds, and tests not run stated explicitly |

A successful API connectivity request establishes that connection and that endpoint's response, not
per-diem or other business-fix correctness. A docs-only change needs documentation/link checks, not
a BC deployment or an invented AL test result. Shared evidence collection mechanics belong in their
owning tooling; this module identifies which assertions matter.

## Evidence provenance and coverage limits

This curated retrospective was taken on **2026-11-04**, for **2026-08-04 through the snapshot on
2026-11-04**, not the remainder of that day. Source and test references above were checked at main
commit `f212d6248609d8f24b2ef76b6177df3c0bcfa727`. Live main was also observed at
`0163e9cfaa525025b7041728ec02551577362692`; its six-commit comparison changed no Expense Agent paths.

Path-filtered, non-shallow, first-parent git history found **109 commits with 109 distinct PR
references** touching `src/Apps/*/ExpenseAgent*`, including app, tests, demo data, and localizations.
Of those, 108 touched the W1 module and one only the localized demo apps. This is a path-touch
inventory, including migrations and repository-wide changes, not 109 deeply reviewed business fixes.
Commit-date filtering is not an exhaustive GitHub merge-date search.

Relevant source/test diff hunks from **eight selected merged PRs** were inspected, then compared with
current source. The immutable commits below are the evidence behind the curated guidelines, not a
ranking of authors or an assertion that every change was a bug fix.

| PR | Exact merged commit | Evidence used |
|---|---|---|
| [#10031](https://github.com/microsoft/BCApps/pull/10031) | [3c2cb4ca91](https://github.com/microsoft/BCApps/commit/3c2cb4ca91a01cdb15a729758c619db54176f09e) | Versioned policy state and stale-parent protection |
| [#11004](https://github.com/microsoft/BCApps/pull/11004) | [23952d0213](https://github.com/microsoft/BCApps/commit/23952d0213b65c2e0a69499b6a8d39f98efb59b5) | Currency correction and its header/line regression test |
| [#11290](https://github.com/microsoft/BCApps/pull/11290) | [38c6e939f9](https://github.com/microsoft/BCApps/commit/38c6e939f9314d2acbbf2c31ef79b3946635820c) | Company-scoped Entra management and API identity delegation |
| [#11654](https://github.com/microsoft/BCApps/pull/11654) | [1714549292](https://github.com/microsoft/BCApps/commit/1714549292ff1339a72e7754523eabd470d31091) | Owned posting fixtures, setup restoration, and real posted-history assertions |
| [#11862](https://github.com/microsoft/BCApps/pull/11862) | [f1399d0d45](https://github.com/microsoft/BCApps/commit/f1399d0d45acb804139d065311151d256cc3689d) | URL helpers, fixture prerequisites, enum payload, and negative diagnostics |
| [#11997](https://github.com/microsoft/BCApps/pull/11997) | [b1c7424270](https://github.com/microsoft/BCApps/commit/b1c742427037e147c35391ba1282d0aa39dcd5b4) | Retained and clarified permission checks |
| [#12675](https://github.com/microsoft/BCApps/pull/12675) | [078b418b0f](https://github.com/microsoft/BCApps/commit/078b418b0f75c826acb10e657e16c58263211e15) | Re-enabled API tests and repaired filter-test prerequisites |
| [#12850](https://github.com/microsoft/BCApps/pull/12850) | [ae8da7fd86](https://github.com/microsoft/BCApps/commit/ae8da7fd86d1202798235c6b9e0ef8504f3568c6) | E2E service-identity producer and three preservation tests |

The open #11531 patch/tests and its discussion were examined separately. Inline-comment endpoints
were read for #11531, #12850, #11862, #11654, and #11997; #11862 had no inline comments. Each used a
100-item page with no next-page link. General discussion was also read for #11531. Not every review
thread, PR, localization diff, or test in the window was inspected. Automated findings are not
accepted solely because they appear in a review.

The re-enablement history includes [#12325](https://github.com/microsoft/BCApps/pull/12325), its
[revert #12514](https://github.com/microsoft/BCApps/pull/12514), and later #12675. Their metadata and
the revert's relevant API-test diff were checked to avoid treating a reverted intermediate state
as current guidance; #12325 was not another deeply reviewed sample.

BCApps history starts with the [Expense Agent migration #9859](https://github.com/microsoft/BCApps/pull/9859)
on 2026-08-04. Earlier NAV history and the pre-migration part of the window were not inspected.
Research used local git history and read-only public GitHub API access.
No AL compilation, publication, test execution, installed-app inspection, or UI reproduction was
performed for this documentation change.

When extending this catalogue, inspect the real diff, relevant tests and discussion, and current
source. Record whether the evidence is a merged correction, an existing safeguard, an inference, or
an unmerged proposal. Update or retire guidance when those contracts change; do not turn one-off
fixes or review preferences into universal bans.
