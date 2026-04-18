# Patterns

## Active patterns

### Inverted hit counting

The app needs to display search results sorted by popularity (most-clicked tables first) but the temporary result table's key only supports ascending order. Rather than using a descending sort at the page level (which would break the multi-field key ordering), the code stores `2000000000 - actualHits` in the `No. of Hits` field of each result row. This appears in `DataSearchLines.page.al` in `AddResults`:

```al
Rec."No. of Hits" := 2000000000 - DataSearchSetupTable."No. of Hits";
```

The magic number 2000000000 is close to the max value of a 32-bit signed integer. A table with 100 user clicks stores `1999999900`, while a table with 0 clicks stores `2000000000`. Ascending sort then puts the 100-click table above the 0-click table. This is a well-known pattern in BC temporary tables where you cannot control sort direction per key field.

### Manual background task queue

BC pages support `EnqueueBackgroundTask` but have no built-in queue or concurrency limit. `DataSearch.page.al` implements its own with two data structures:

- `QueuedSearches: List of [Integer]` -- tables waiting to be searched
- `ActiveSearches: Dictionary of [Integer, Integer]` -- maps `TaskID` to `TableTypeID` for in-flight tasks

The `NoOfParallelTasks` variable (set to 6 in `OnInit`) caps concurrency. `DeQueueSearchInBackground` pops from the queue into active slots. When a task completes (`OnPageBackgroundTaskCompleted`) or errors (`OnPageBackgroundTaskError`), the callback removes it from `ActiveSearches` and calls `DeQueueSearchInBackground` again to fill the freed slot. If all tasks are done and the queue is empty, search is marked complete and the display string reverts from "Searching for ..." back to the plain search term.

This pattern is worth understanding because the error handler swallows all errors -- it adds an error indicator to the result set but otherwise treats the task as successfully completed. This means a table with permission issues or corrupt data will not block the search; it just shows an error row the user can click for details.

### Metadata-driven field inclusion

Rather than hardcoding which fields to search per table, `DataSearchDefaults.AddDefaultFields` uses BC's metadata system to auto-discover searchable fields in a tiered strategy:

1. Query the `Field` system table for fields where `OptimizeForTextSearch = true`. If any exist, use only those and skip the remaining tiers. This tier leverages SQL Server's full-text index for best performance.
2. Query the `Field` system table for all fields with `Type = Text` and `Class = Normal`.
3. Iterate all keys via `RecordRef.KeyIndex`, examining each key field. Include those that are `Text` or `Code` type, `Normal` class, and whose `Relation` target is not in the exclusion set.

The exclusion set in `DataSearchDefaults.ExcludedField` is a hardcoded list of about 25 table IDs (Dimension Value, No. Series, Gen. Business Posting Group, VAT Product Posting Group, etc.) plus the `OnGetExcludedRelatedTableField` event. This prevents searching on fields like "Gen. Bus. Posting Group" which are codes but not meaningful search targets.

### Enum introspection for subtypes

To generate subtype rows for document tables (so Sales Header gets separate setup entries for Quote, Order, Invoice, etc.), the app discovers enum values at runtime in `DataSearchObjectMapping.GetSubtypesForField`:

```al
RecRef.Open(TableNo);
FldRef := RecRef.Field(FieldNo);
for i := 1 to FldRef.EnumValueCount() do
    SubtypeList.Add(FldRef.GetEnumValueOrdinal(i));
```

This opens the table, gets a field reference for the document type field, and iterates all enum ordinals. The technique means that if a new enum value is added to `Sales Document Type` by an extension, it will automatically get its own search setup row on next initialization. Gen. Journal Line is special-cased: instead of reading the line table's field, it reads the `Type` field from `Gen. Journal Template` (table `Database::"Gen. Journal Template"`, field 9), because the journal line's "subtype" semantics are template-based rather than enum-based.

### Role center tier-1 organization

Setup initialization in `DataSearchDefaults.InitSetupForProfile` uses a two-stage approach:

1. A `case` statement on `RoleCenterID` selects one of 11 specific `GetTableListFor*` procedures, or falls back to `GetDefaultTableList`.
2. After the hardcoded list is built, both `OnAfterGetTableList` (internal event on the defaults codeunit) and `OnAfterGetRolecCenterTableList` (public event on the events codeunit) fire, allowing extensions to modify the list.

This pattern means the base behavior is code-driven (fast, no database reads) but the final result is extensible. The downside is that adding a new role center requires modifying the defaults codeunit, unless the extension subscribes to the event.

## Legacy patterns

### Hardcoded line-to-header mappings

`DataSearchObjectMapping.Codeunit.al` contains three parallel case statements that must be kept in sync:

- `GetParentTableNo` -- maps line table number to header table number (30+ entries)
- `GetSubTableNos` -- maps header table number to line table numbers (30+ entries, inverse of above)
- `MapLinesRecToHeaderRec` -- contains the actual record-level navigation procedures (30+ entries)

Each mapping is a standalone local procedure (e.g., `SalesLineToHeader`, `PurchaseLineToHeader`). Adding a new header/line pair requires touching all three case statements and writing a new local procedure. Forgetting any of the three creates subtle bugs -- setup cascading might work but navigation might not, or vice versa.

The event-based alternative (`OnGetParentTable`, `OnGetSubTable`, `OnMapLineRecToHeaderRec`) only fires when the case statement does not match, so the hardcoded entries cannot be overridden, only supplemented.

### Magic number 2000000000

The inverted sort value `2000000000` appears 5 times across `DataSearchLines.page.al` with no named constant. It is always written as the literal number. If the maximum `No. of Hits` ever exceeds 2 billion (unlikely but technically possible with the Integer type), the inversion would underflow and break sort order. A named constant would make the intent clearer and the risk more visible.

### Massive case statements for page/table resolution

`DataSearchObjectMapping.GetListPageNo` is a nested case statement: first switching on `TableNo`, then on `TableSubType` within each table. It handles Sales Header (6 subtypes), Purchase Header (6 subtypes), Service Header (4 subtypes), and Service Contract Header (3 subtypes) -- 19 explicit page mappings. `GetTableSubTypeFromPage` is the inverse: a 19-entry case statement mapping page IDs back to subtype integers.

These two procedures must stay synchronized. If a new document subtype or page is added to one but not the other, the system can navigate to a page but not reverse-lookup the subtype from it (or vice versa).

### Hardcoded table IDs for optional modules

Manufacturing tables are referenced by raw integer IDs in `DataSearchDefaults.GetTableListForManufacturingManager`:

```al
if TableExist(5405) then
    TableList.Add(5405); // Database::"Production Order"
if TableExist(99000771) then
    TableList.Add(99000771); // Database::"Production BOM Header"
```

This avoids a compile-time dependency on the Manufacturing module, but makes the code fragile to table renumbering and harder to navigate. The same pattern appears in `DataSearchObjectMapping` where Manufacturing tables are referenced via `Database::"Production Order"` (which resolves at compile time because that module is a dependency there) but are guarded with `#pragma warning disable AL0801` to suppress the deprecated-reference warning.

### Gen. Journal Line special casing

Gen. Journal Line appears as a special case in at least four places: `GetTypeNoField`, `SetTypeFilterOnRecRef`, `GetSubtypesForField`, and `GetGenJournalPageNo`. Its "subtype" is the journal template type, but filtering requires looking up template *names* (not just the integer type) because the line's key field is the template name string, not the type enum. The filter construction in `SetTypeFilterOnRecRef` builds a dynamic pipe-delimited filter of all template names for the given type, wrapped in single quotes. If no templates exist for a type, it generates a random GUID-based filter string designed to match nothing.
