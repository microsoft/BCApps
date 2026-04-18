# Extensibility

All integration events are defined in `DataSearchEvents.codeunit.al` (codeunit 2682), which is a `SingleInstance` codeunit with `Access = Public` (implicit). There is also one event in `DataSearchDefaults.Codeunit.al`, though it is `local` and used for internal extensibility.

## Add custom tables to search

To include your own tables in the default search setup for a role center, subscribe to `OnAfterGetRolecCenterTableList`.

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnAfterGetRolecCenterTableList', '', false, false)]
local procedure AddMyTable(RoleCenterID: Integer; var ListOfTableNumbers: List of [Integer])
begin
    if RoleCenterID = Page::"My Custom Role Center" then
        ListOfTableNumbers.Add(Database::"My Custom Table");
end;
```

This event fires during `DataSearchDefaults.InitSetupForProfile`, after the hardcoded table list is built. The list is pre-populated with the standard tables for that role center, so you can both add and remove entries. Note that this only affects the *initial* setup -- if the user has already searched (triggering auto-init), re-initialization requires deleting existing setup rows first.

If your table has a document-type-like subtype field, also subscribe to `OnGetFieldNoForTableType` so the system knows which field drives subtypes:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnGetFieldNoForTableType', '', false, false)]
local procedure SetMyDocTypeField(TableNo: Integer; var FieldNo: Integer)
begin
    if TableNo = Database::"My Custom Table" then
        FieldNo := MyCustomTable.FieldNo("Document Type");
end;
```

## Define header/line relationships

If your extension has a header/line table pair and you want search results from the line table to navigate to the header card, subscribe to three events:

**Parent table lookup** -- tells the system which header table owns a given line table:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnGetParentTable', '', false, false)]
local procedure MapMyLineToHeader(SubTableNo: Integer; var ParentTableNo: Integer)
begin
    if SubTableNo = Database::"My Line Table" then
        ParentTableNo := Database::"My Header Table";
end;
```

**Sub-table lookup** -- the inverse, used for setup cascading (adding the header automatically adds its lines):

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnGetSubTable', '', false, false)]
local procedure MapMyHeaderToLine(ParentTableNo: Integer; var SubTableNo: Integer)
begin
    if ParentTableNo = Database::"My Header Table" then
        SubTableNo := Database::"My Line Table";
end;
```

**Record-level mapping** -- the actual navigation logic that converts a line RecordRef to a header RecordRef:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnMapLineRecToHeaderRec', '', false, false)]
local procedure NavigateMyLineToHeader(var LineRecRef: RecordRef; var HeaderRecRef: RecordRef)
var
    MyHeader: Record "My Header Table";
    MyLine: Record "My Line Table";
begin
    if LineRecRef.Number <> Database::"My Line Table" then
        exit;
    LineRecRef.SetTable(MyLine);
    MyHeader.Get(MyLine."Document No.");
    HeaderRecRef.GetTable(MyHeader);
end;
```

Note that `LineRecRef` and `HeaderRecRef` are the *same* var parameter in the event signature. The subscriber must replace the RecordRef content in-place. The system detects whether mapping occurred by checking if `RecRef.Number` changed.

## Override page resolution

By default, the system resolves list and card pages using hardcoded case statements (for document subtypes) and then `TableMetadata.LookupPageID`. To override:

**List page** -- controls what opens when a user clicks the header row:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnGetListPageNo', '', false, false)]
local procedure UseMyListPage(TableNo: Integer; TableType: Integer; var PageNo: Integer)
begin
    if (TableNo = Database::"My Table") and (TableType = 0) then
        PageNo := Page::"My Custom List";
end;
```

**Card page** -- controls what opens when a user clicks a specific result row:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnGetCardPageNo', '', false, false)]
local procedure UseMyCardPage(TableNo: Integer; TableType: Integer; var PageNo: Integer)
begin
    if TableNo = Database::"My Table" then
        PageNo := Page::"My Custom Card";
end;
```

The card page event fires in `ShowPage` in `DataSearchResult.table.al` *only* when `PageManagement.PageRun` fails to find a page on its own. So it is a fallback, not an override of successfully-resolved pages.

**Page-to-subtype** -- when the setup UI needs to determine which document subtype corresponds to a page:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnGetTableSubTypeFromPage', '', false, false)]
local procedure MapMyPageToSubtype(PageNo: Integer; var TableSubtype: Integer)
begin
    if PageNo = Page::"My Custom Quotes Page" then
        TableSubtype := 1; // Quote subtype ordinal
end;
```

## Replace search logic for a table

To completely replace how a specific table is searched (e.g., to use a custom index or external service), subscribe to `OnBeforeSearchTableProcedure`:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnBeforeSearchTableProcedure', '', false, false)]
local procedure CustomSearchForMyTable(
    TableNo: Integer;
    TableType: Integer;
    var FieldList: List of [Integer];
    var SearchStrings: List of [Text];
    var Results: Dictionary of [Text, Text];
    var IsHandled: Boolean)
begin
    if TableNo <> Database::"My Table" then
        exit;
    // Populate Results: key = SystemId as text, value = description string
    IsHandled := true;
end;
```

This event is `internal` (only accessible to apps with `internalsVisibleTo` access), so it is not available to third-party extensions. It fires at the very start of `SearchTable` in `DataSearchInTable.codeunit.al`. Setting `IsHandled := true` skips the entire default search logic for that table.

## Extend default field selection

To add custom fields to the search setup when a table is first initialized:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnAfterGetFieldListForTable', '', false, false)]
local procedure AddMyFieldsToSearch(TableNo: Integer; var ListOfFieldNumbers: List of [Integer])
begin
    if TableNo = Database::Customer then
        ListOfFieldNumbers.Add(Customer.FieldNo("My Custom Field"));
end;
```

This fires during `AddDefaultFields` in `DataSearchDefaults.Codeunit.al`, after the three-tier automatic field selection (full-text-indexed, text fields, indexed code/text fields). You can both add and remove field numbers.

To *exclude* indexed fields that have a table relation to a particular table (e.g., your custom setup table that should not be searchable):

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnGetExcludedRelatedTableField', '', false, false)]
local procedure ExcludeMySetupTable(RelatedTableNo: Integer; var IsExcluded: Boolean)
begin
    if RelatedTableNo = Database::"My Setup Table" then
        IsExcluded := true;
end;
```

This fires during the indexed-fields tier, for each code/text key field that has a non-zero `Relation` property. The base app already excludes about 25 standard setup tables (Dimension Value, No. Series, Posting Groups, etc.).

## Filter search results

To add custom filters before a table is searched (e.g., to restrict results to a specific company, date range, or status):

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Search Events",
    'OnBeforeSearchTable', '', false, false)]
local procedure FilterMySearchResults(var RecordRef: RecordRef)
begin
    if RecordRef.Number = Database::"Sales Header" then begin
        // Add date filter, status filter, etc.
    end;
end;
```

This fires in `SearchTable` in `DataSearchInTable.codeunit.al`, after the OR-group field filters are applied but before `RecRef.Find('-')` executes the query. The RecordRef is in filter group 0 (the normal AND group) at this point, so any filters you add will be ANDed with the field-level OR filters.
