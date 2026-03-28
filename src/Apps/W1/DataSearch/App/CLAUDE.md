# Data Search

Data Search provides company-wide cross-table search in Business Central, accessible via Tell Me (Alt+Q) as "Search in company data". Users type 3+ characters and get results from multiple tables, searched in parallel using background page tasks. The feature is role-center-aware -- each profile gets its own curated set of searchable tables.

## Quick reference

- **ID range**: 2680--2699
- **Namespace**: `Microsoft.Foundation.DataSearch`
- **Entry point**: `DataSearch.page.al` (page 2680), invoked by system action triggers in `DataSearchInvocation.Codeunit.al`

## How it works

When a user opens "Search in company data" and types at least three characters, the page validates the input as a legal filter expression, then launches a search. The launch procedure loads the user's role center, fetches all registered tables from `Data Search Setup (Table)`, sorts them by descending hit count (most-clicked tables first), and queues each table as a background task. A manual task queue in the page manages up to 6 concurrent `EnqueueBackgroundTask` calls, feeding new tasks from the queue as earlier ones complete.

Each background task runs `DataSearchInTable.codeunit.al` (codeunit 2680). It opens the target table via RecordRef, checks read permissions and emptiness, splits the search string into words, loads the enabled field list from `Data Search Setup (Field)`, then applies OR-group filters across all enabled fields. Full-text-indexed fields use prefix matching (`&&term*`), text fields use case-insensitive wildcard matching (`@*term*`), and Code fields use uppercased matching. After the initial filter returns candidates (sorted by `SystemModifiedAt` descending), each record is verified with an AND-across-words full-match check. Only the first 4 matching records are returned per table.

Results flow back through `OnPageBackgroundTaskCompleted` into `DataSearchLines.page.al`, which builds a hierarchical temporary record set using four line types: Header (bold table name), Data (individual result rows), MoreHeader (link to "show all results"), and MoreData (hidden overflow). The display is sorted by an inverted hit counter -- `2000000000 - actualHits` -- so that frequently-clicked tables appear first without needing a descending key.

Setup initialization is handled by `DataSearchDefaults.Codeunit.al`, which has hardcoded table lists for 11 specific role centers plus a general default list. When no setup exists for the user's role center, it is auto-created on first search. For each table, the defaults codeunit populates field-level setup using a three-tier strategy: prefer full-text-indexed fields, then fall back to all text fields, then add key fields with code/text types (excluding fields that point to posting groups, dimension values, and similar setup tables).

Navigation from search results goes through `DataSearchObjectMapping.Codeunit.al`, which contains 30+ hardcoded line-to-header mappings (e.g., Sales Line to Sales Header, Job Task to Job) and document-subtype-aware page resolution.

## Structure

The app is flat -- all files live directly in the `App/` folder. The conceptual grouping is:

- **Tables** (2680--2682): Result, Setup Table, Setup Field
- **Core logic**: `DataSearchInTable` (background search), `DataSearchDefaults` (initialization), `DataSearchObjectMapping` (navigation/mapping)
- **Orchestration**: `DataSearch.page.al` (task queue), `DataSearchLines.page.al` (result display)
- **Glue**: `DataSearchInvocation` (system trigger hooks), `DataSearchEvents` (integration events), `DataSearchSetupChanges` (delta tracking)

## Documentation

- [docs/data-model.md](docs/data-model.md) -- How the data fits together
- [docs/business-logic.md](docs/business-logic.md) -- Processing flows and gotchas
- [docs/extensibility.md](docs/extensibility.md) -- Extension points and how to customize
- [docs/patterns.md](docs/patterns.md) -- Recurring code patterns (and legacy ones to avoid)

## Things to know

- The minimum search length is 3 characters, enforced at the page level in `DataSearch.page.al`. The first word must also be at least 3 characters.
- Multi-word search is AND-across-words: the SQL filter finds records matching any word in any field (OR), then `IsFullMatch` verifies all words are present somewhere (AND). This means the SQL step over-fetches and the AL code narrows.
- The `2000000000` magic number in `DataSearchLines.page.al` line 137 is the inverted sort trick. If you see `"No. of Hits" := 2000000000 - ...`, that is intentional -- it turns an ascending key into effectively descending order.
- Background tasks have a 120-second timeout (hardcoded in `StartSearchInBackground`). Tasks that time out are silently swallowed by `OnPageBackgroundTaskError`.
- The `DataSearchSetupChanges` codeunit uses `BindSubscription`/`UnbindSubscription` to track setup modifications during the setup page modal. It only lives while the setup page is open.
- `InsertRec(true)` on the setup table cascades to create subtypes (e.g., Sales Header generates rows for Quote, Order, Invoice, Credit Memo, Blanket Order, Return Order) and sub-tables (e.g., adding Sales Header also adds Sales Line). This is driven by `GetSubtypes` and `GetSubTableNos` in `DataSearchObjectMapping`.
- The `Contact` table gets a hardcoded `"No. of Hits" := 1` bump during initialization so it sorts to the top by default.
- Page resolution uses a fallback chain: hardcoded case statement, then `OnGetListPageNo` event, then `TableMetadata.LookupPageID`.
- Gen. Journal Line is special-cased throughout -- its "subtype" is the journal template type, and filtering requires looking up template names rather than a simple integer filter.
- The app has no compile-time dependencies on Manufacturing or Service modules. Those table references use hardcoded integer IDs with `TableExist` guards (e.g., `5405` for Production Order).
