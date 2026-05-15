# Data Search Tests

Tests for the Data Search app, which provides company-wide cross-table search in Business Central. This test app validates search execution, setup initialization, result mapping, and -- critically -- demonstrates how extensions can integrate new tables into Data Search via event subscribers.

## How it works

The main test codeunit (`TestDataSearch.codeunit.al`) exercises the core search pipeline: initializing setup records, running `Data Search in Table` against a lightweight test table, and verifying that results come back with correct SystemIds and match text. Tests use `AutoRollback` transactions and clear all `Data Search Setup (Table)` and `Data Search Setup (Field)` records at the start of each run to ensure isolation.

The archive extension pattern is the most important thing to understand here. `TestDataSearchOnArchives.codeunit.al` is a manually-bound event subscriber codeunit (`EventSubscriberInstance = Manual`) that hooks six events on `Data Search Events` to register Sales Header/Line Archive tables into the search system. Tests bind it with `BindSubscription` before exercising archive scenarios and unbind afterward. This codeunit is effectively a reference implementation showing every event a new table needs to handle: table type field mapping (`OnGetFieldNoForTableType`), parent-child relationships (`OnGetParentTable`), list/card page resolution (`OnGetListPageNo`, `OnGetCardPageNo`), line-to-header record mapping (`OnMapLineRecToHeaderRec`), role center registration (`OnAfterGetRolecCenterTableList`), and related-table exclusions (`OnGetExcludedRelatedTableField`).

The page extension (`TestDataSearchExtension.PageExt.al`) adds hidden test actions to the Data Search page -- `TestSearchForSalesOrders` and `TestClearResults` -- that let tests invoke search synchronously instead of relying on page background tasks, which are known to cause test hangs (Bug 546705).

## Things to know

- `TestDataSearch.Table.al` is a minimal two-field table (No. + Name) used as a controlled search target. Tests insert GUID-based names so search terms never collide with real data.
- The `FindInTable` codeunit caps results at 4 per table. `TestSearchManyFound` inserts 5 records and asserts exactly 4 come back -- this is by design, not a bug.
- Multi-term search (`TestMultiTermSearch`) works by AND-ing terms across fields: searching "guid1 No1" matches only the record whose Name contains the GUID and whose No. matches.
- Two tests are commented out with a reference to Bug 546705 -- page background tasks make tests hang. The page extension's hidden actions are the workaround for the `TestSearchSalesOrders` test.
- `TestSearchSalesOrders` uses `AutoCommit` (not `AutoRollback`) because it archives a sales order mid-test through a page handler, then searches again to verify the archive appears in results.
- The `TestGetSetup` test validates that `DataSearchObjectMapping.GetDataSearchSetup` returns a JSON array with the expected schema (`tableNo`, `tableSubtype`, `tableSubtypeFieldNo`, `tableSearchFieldNos`).
- To add a new table to Data Search, use `TestDataSearchOnArchives.codeunit.al` as your template -- it covers all six required event subscribers.
