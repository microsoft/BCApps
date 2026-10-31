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
