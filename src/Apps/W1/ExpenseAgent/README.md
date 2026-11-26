# Todo: Missing documentation of the expense agent module.

# Expense Agent consumption reporting

The `expenseCapabilities` API always advertises `ConsumptionV2` as enabled,
indicating support for `LogAIConsumptionV2` and `CanConsumeV2`.

`userConsumptions` exposes `LogAIConsumptionV2`. The request contains a `model`
object with model usage and a `v1` object with `usage` and `usageType`.
The action calls `Copilot Quota.IsV2ConsumptionActive()` and submits only the
active pipeline. When V2 is inactive, it uses the V1 usage and usage type.
When V2 is active, it uses only model usage; the V2 platform payload retains the
top-level `model` object and excludes the `v1` object.
The four model token counters must be present, whole, and non-negative:
`inputTokenCount`, `outputTokenCount`, `promptCacheReadTokenCount`, and
`promptCacheCreationTokenCount`.
Zero V1 usage, or all four V2 counters being zero, emits skip telemetry and
returns an empty GUID without creating a companion or reporting consumption.
The legacy V1-only action retains its V1 routing regardless of V2 activation.

The legacy `userConsumptions({id})/Microsoft.NAV.canConsume` action retains its
empty request body and evaluates quota using the integration session's principal.
The new `userConsumptions({id})/Microsoft.NAV.canConsumeV2` action requires an
`expenseUserEntraId` GUID in its request body. V2 quota checks and recording use
the API-supplied Entra ID, not the stored ID or the integration session's
principal. A missing or empty supplied ID returns an error. If a nonblank stored
Entra ID differs from the supplied ID, the action emits error-level telemetry
and continues recording with the supplied ID. A blank stored ID doesn't prevent
recording.
The System Application `Copilot Quota.CanConsume(Guid)` overload is scoped to
OnPrem and evaluates paid quota in the active pipeline. The parameterless
overload retains its legacy session-based behavior.
The new production billing methods and the consumption API entry points are
marked `NonDebuggable`. Identity-mismatch telemetry remains publisher-only.

One environment consumption record identifies the event by source type, source
system ID, and operation. V1 uses its text consumption key; V2 uses its
`SystemId`. The record and its trial classification are committed before either
submission because V2 records consumption in a separate system transaction.
A failed submission can leave a pending companion record. Repeating the request
reuses both IDs and the original trial classification. A completion flag records
successful processing, including V1 trials that have no billing-ledger entry.
Completed events aren't submitted again. Existing V1 and V2 ledger entries
also prevent duplicate submission. If a V2 ledger entry exists but its trial
counter failed, the retry finishes the counter using the same consumption ID.
Pending events use the currently active pipeline when retried, including after
a change in activation, without changing their identity or trial classification.

Only `PROCESS` consumes trial allowance, once per consumption ID.
V1 trial events update the trial counter without submitting normal V1
consumption; other V1 trial operations are completed without consuming allowance.
V2 trial events are always recorded with `IsFeatureTrial = true`, then update
the trial counter after the V2 ledger entry is confirmed. Paid events use normal
consumption reporting in the selected pipeline. Failed or ignored V2 recording
doesn't consume trial allowance.

The billing overview reads V2 details from `AI Consumption Log Entry` by
`SystemId`, or V1 details from `User AI Consumption Data` by the text key.
It doesn't combine credits from the two ledgers. Copilot Studio feature fields
are blank for V2 events. The expense user's name must be present to supply the
V2 consumption principal's display name.
V2 Actions stays empty. List rendering doesn't load description blobs from
either ledger. Description drilldown looks up the current V2 entry, or the V1
entry when no V2 entry exists, and loads the full text on demand.
Missing expense sources display "Deleted expense or invalid receipt".

The companion table's V1 lookup FlowFields are obsolete as of 30.0.
Use `GetBillingDetails` to read billing details from the active ledger.

If the user can't read `AI Consumption Log Entry`, the billing overview shows
a message when opened and leaves billing details empty. It doesn't fall back
to V1 when V2 read permission is missing.

# Expense Agent no-receipt API

The `microsoft/expense/beta` API exposes no-receipt support through the
`expenseCapabilities` entry `noReceipt` (capability ordinal 9). It is enabled
only when the current company's **Expense Agent Setup / Allow No Receipt**
setting is enabled.

## Fields and policy

`expenseCategories` exposes `amountLimitForNoReceipt` as a decimal in local
currency (LCY), alongside the existing `attachmentEnforcement` field.
An expense is automatically classified as **Receipt not needed** only when
no-receipt support is enabled and its `amountLCY` is strictly below the
category's threshold. Equality requires receipt proof. The **Not needed under
limit** enforcement policy requires an original receipt or a current declaration
at or above the limit.

`expenses` retains the existing read-only `amountLCY` field; `currencyLCY`
identifies that currency. There is no `amountInLocalCurrency` alias. Its
read-only no-receipt fields are:

- `noReceiptType`
- `noReceiptReason`
- `noReceiptDeclarationId`
- `noReceiptDeclarationCurrent`

Default-schema enum names use Business Central's XML name encoding:

| AL member | Ordinal | API enum name |
| --- | --- | --- |
| ` ` | 0 | `_x0020_` |
| `Lost Receipt` | 1 | `Lost_x0020_Receipt` |
| `Receipt not needed` | 2 | `Receipt_x0020_not_x0020_needed` |

The existing attachment-enforcement members remain unchanged:
`_x0020_` (0), `Warning` (1), `Error` (2), and
`Not_x0020_needed_x0020_under_x0020_limit` (3). These identifiers are not
localized captions.

## Draft, edit, then declare

An Open expense may be saved before merchant, description, category, currency,
and amount are finalized. Existing expense-user scoping and number-series
configuration still apply. Creating or editing a draft does not attest or
generate a document.

For scoped insertion, POST to `expenseUsers({id})/expenses` without
`expenseUserNumber` or `expenseUserSystemId`. The Expenses API enables
`PopulateAllFields` so the navigation's single-value filter fills the non-key
**Expense User No.** field. `currencyCode: ""` selects LCY. The top-level
`expenses` endpoint continues to accept an explicit expense user.

Save the selected category and other core fields before checking
`noReceiptType`. The server recomputes the automatic exemption even when the
LCY amount has not changed, including category switches and threshold changes.
Date changes recalculate exchange rates; currency-only API edits also validate
the currency and recalculate LCY.

When proof is required and the original receipt is unavailable, obtain a
nonblank reason and explicit confirmation from the user, then POST:

```text
expenses({id})/Microsoft.NAV.createNoReceiptDeclaration
```

```json
{"reason": "The original receipt was lost.", "attestationConfirmed": true}
```

The bound action invokes **No Receipt Declaration Mgt. / CreateDeclaration**.
It requires an Open expense that is not associated with a report, the existing
expense prerequisites, company permission, a nonblank reason, and explicit
attestation. It rejects expenses with an original receipt. It creates a
system-generated PDF attachment and updates the declaration fields. It never
infers confirmation from saving an expense.

To cancel, POST `{}` to:

```text
expenses({id})/Microsoft.NAV.cancelNoReceiptDeclaration
```

Cancellation also requires an Open, unreported expense. It removes only the
generated declaration, clears its metadata, and recomputes the automatic
exemption. Both actions use the existing updated-entity action result.

Changing category, currency, date, amount, description, or reason makes a
declaration stale. If proof is still required, the **Lost Receipt** type and
old PDF remain until the user regenerates with fresh confirmation or cancels.
An edit that makes a nonzero expense exempt removes the obsolete generated
declaration and its attestation metadata and selects **Receipt not needed**.
A temporary zero amount during category validation does not discard an
existing declaration. Returning an exempt expense to the threshold or above
requires new proof; an old declaration is never restored automatically.

Release still rejects stale/missing declarations and the combination of an
original receipt and a lost-receipt declaration. Existing report approval
safeguards remain in force.

## Regression coverage

`Expense No Receipt API Test` covers top-level and scoped blank drafts, additive fields, default
enum serialization, currency-only PATCH, and explicit-attestation action
parameters. `Expense No Rule Test` covers strict LCY thresholds, category and
setup changes, stale declarations, generation/regeneration/cancellation,
original-receipt and Open-only guards, and the automatic transition from lost
receipt to exemption. `Expense Capabilities API Test` verifies the company
setting in both states.

These AL tests require the existing Business Central test environment.

# Reserved codeunit IDs

Do not use codeunit IDs 6913-6921 or 6977 in the Expense Agent apps. They belong to the
deprecated `Expense Agent (<country>)` apps in `src/Apps/<country>/ExpenseAgent_<country>`,
which are no longer built but can still be installed on tenants. Reusing one of these IDs
makes installs, upgrades and hotfixes fail with "The application object of type 'CodeUnit'
with the ID '<id>' is defined in multiple apps". The compiler does not catch this.
