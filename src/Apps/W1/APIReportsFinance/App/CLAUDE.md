# API Reports - Finance

Read-only API layer that exposes raw financial data (GL entries, customer/vendor
ledger entries, budgets, dimensions) through OData/REST endpoints. Unlike the
standard BC API v2.0 financial endpoints (trialBalance, balanceSheet, etc.) which
return pre-aggregated report data, this app exposes granular transactional records
that consumers aggregate themselves -- a "data warehouse" approach for building
custom financial reports.

## Quick reference

- **ID range**: 30300--30399
- **Namespace**: Microsoft.API.FinancialManagement
- **API route**: `api/microsoft/reportsFinance/beta/`
- **API version**: beta (not GA -- endpoints may change)

## How it works

The app defines 9 API Pages and 6 API Queries, all read-only. Pages expose
master/reference data (chart of accounts, customers, vendors, dimensions,
budgets, accounting periods, business units, global settings). Queries expose
transactional data (GL entries, GL budget entries, customer ledger entries,
detailed customer ledger entries, vendor ledger entries, detailed vendor ledger
entries).

Every object follows the same template: `PageType = API` or `QueryType = API`,
`DataAccessIntent = ReadOnly`, all insert/modify/delete disabled, `ODataKeyFields
= SystemId`. The app defines no tables of its own -- it reads directly from base
app tables (G/L Entry, Cust. Ledger Entry, etc.).

The only procedural logic lives in two page triggers:

- **Accounting Periods** (`APIFinanceAccPeriods.Page.al`): computes
  `FiscalYearStartDate`, `FiscalYearEndDate`, and `EndingDate` on each record
  fetch. The ending date is derived by peeking at the next period's start date
  and subtracting one day.

- **GL Accounts** (`APIFinanceGLAccount.Page.al`): reconstructs the chart of
  accounts parent-child hierarchy at runtime using a `Dictionary<Integer,
  Code[20]>` keyed by indentation level. This is order-dependent -- it relies on
  records arriving sorted by account number with ascending indentation.

## Things to know

- All 15 data endpoints are completely read-only. There is zero write logic, zero
  events, zero extensibility hooks, and zero codeunits.
- The GL Account parent tracking via dictionary is fragile. It works because API
  pages iterate records in sort order, but the pattern wouldn't survive
  re-sorting or filtering that breaks indentation sequencing.
- `globalSettings` is a virtual page -- it reads from both the Company record and
  General Ledger Setup in `OnOpenPage`, exposing just company name, LCY code, and
  additional reporting currency.
- The app has several caption typos in the query objects: `entryType` is captioned
  as `'Entry Number'` in both detailed ledger entry queries, and
  `initialEntryGlobalDim2` is captioned as `'...Dimension 1'` instead of
  `'...Dimension 2'`.
- The `reveresd` column name in `APIFinanceGLEntry.Query.al` is a typo for
  `reversed`.
- GL Budget Entry query has a duplicate column: both `accountNo` and
  `generalLedgerAccountNumber` map to the same `G/L Account No.` field.
- Permissions follow the standard stacking pattern: one base permission set
  (`API Reports Finance - Objects`) extended into 6 D365 roles.
