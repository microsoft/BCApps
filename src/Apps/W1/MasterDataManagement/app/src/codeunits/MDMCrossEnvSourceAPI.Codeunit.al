namespace Microsoft.Integration.MDM;

using System.Environment;
using System.Text;
using System.Utilities;

/// <summary>
/// Source-side generic API, published as an ODataV4 web service. The cross-environment implementation of
/// "IMDM Data Source" (running in a subsidiary) calls these unbound actions to read source master data.
/// Runs under the CALLER's permission set with NO permission elevation, so a read-only, table-scoped
/// permission set assigned to the caller's Entra app is the effective access boundary.
/// </summary>
codeunit 7241 "MDM Cross-Env Source API"
{
    Access = Public;

    var
        SortByChangeFeedKeyTok: Label 'SORTING(Field%1,Field%2)', Locked = true;
        SortByModifiedAtTok: Label 'SORTING(Field%1)', Locked = true;

    /// <summary>
    /// Wire-version negotiation: returns the API contract version and the action/feature names this source
    /// supports, so a newer subsidiary only calls actions an older source actually implements.
    /// </summary>
    /// <returns>A JSON object with the numeric contract 'version' and a 'features' array of supported action names.</returns>
    [ServiceEnabled]
    procedure GetCapabilities(): Text
    var
        Capabilities: JsonObject;
        Features: JsonArray;
        ResultText: Text;
    begin
        Capabilities.Add('version', ApiVersion());
        Features.Add('records');
        Features.Add('lastModifiedPerTable');
        Capabilities.Add('features', Features);
        Capabilities.WriteTo(ResultText);
        exit(ResultText);
    end;

    /// <summary>
    /// Returns a page of changed source records for the given table. FieldIds is a JSON array of field
    /// numbers. Selector is either a change-feed cursor { modifiedAt, systemId } or a targeted
    /// { systemIds } list. Response carries records, hasMore and (cursor mode) nextCursor. The table read
    /// runs under the CALLER's permission set, so table-level access is enforced by permissions, not here.
    /// </summary>
    /// <param name="TableId">The source table ID to read.</param>
    /// <param name="FieldIds">A JSON array of the field numbers to project.</param>
    /// <param name="Selector">A JSON object: a change-feed cursor { modifiedAt, systemId } or a targeted { systemIds } list.</param>
    /// <param name="PageSize">The maximum number of records to return in this page.</param>
    /// <param name="Filter">An optional source row filter (view) restricting which records are returned.</param>
    /// <returns>A JSON object with 'records', 'hasMore', 'unavailableFields' and, in cursor mode, 'nextCursor'.</returns>
    [ServiceEnabled]
    procedure GetRecords(TableId: Integer; FieldIds: Text; Selector: Text; PageSize: Integer; Filter: Text): Text
    var
        RecRef: RecordRef;
        Response: JsonObject;
        Records: JsonArray;
        UnavailableFields: JsonArray;
        SystemIds: JsonArray;
        ProjectedFields: List of [Integer];
        CursorModifiedAt: DateTime;
        NextModifiedAt: DateTime;
        CursorSystemId: Guid;
        NextSystemId: Guid;
        HasCursor: Boolean;
        HasMore: Boolean;
        GroupTooLarge: Boolean;
        Count: Integer;
        ResultText: Text;
    begin
        if not IsSourceConsented() then
            exit(ConsentRequiredResponse());
        Response.Add('tableId', TableId);

        if IsBlockedSourceTable(TableId) then
            exit(WriteResponse(Response, false, Records, false));
        if not TryOpenTable(TableId, RecRef) then
            exit(WriteResponse(Response, false, Records, false));
        Response.Add('tableAvailable', true);

        // Missing field => HALT that table's sync (no partial records); subsidiary logs a synch error.
        // Fields that exist but are media/blob/flow are skipped silently (media sync is deferred).
        ResolveProjection(RecRef, FieldIds, ProjectedFields, UnavailableFields);
        if UnavailableFields.Count() > 0 then begin
            Response.Add('unavailableFields', UnavailableFields);
            exit(WriteResponse(Response, true, Records, false));
        end;

        PageSize := ClampPageSize(PageSize);
        ApplyProjectionLoadFields(RecRef, ProjectedFields);

        // Targeted mode: caller asked for specific SystemIds (no paging). The mapping row filter is not applied here,
        // matching same-env GetById/GetByUidFilter (targeted fetches return the requested records directly).
        if SelectorSystemIds(Selector, SystemIds) then begin
            FillBySystemIds(RecRef, SystemIds, ProjectedFields, Records);
            exit(WriteResponse(Response, true, Records, false));
        end;

        HasCursor := SelectorCursor(Selector, CursorModifiedAt, CursorSystemId);

        if HasCompositeChangeFeedKey(RecRef) then begin
            // Bounded paging: the (SystemModifiedAt, SystemId) key lets us split even a big same-timestamp group.
            RecRef.SetView(StrSubstNo(SortByChangeFeedKeyTok, SystemModifiedAtFieldNo(), SystemIdFieldNo()));
            ApplyRowFilter(RecRef, Filter);
            HasMore := FillCursorPage(RecRef, HasCursor, CursorModifiedAt, CursorSystemId, ProjectedFields, PageSize, Records, Count, NextModifiedAt, NextSystemId);
            if Count > 0 then
                Response.Add('nextCursor', BuildCursor(NextModifiedAt, NextSystemId));
        end else
            if HasModifiedAtLeadingKey(RecRef) then begin
                // Fallback for tables without the SystemId tiebreak (kept off small/setup tables): drain each
                // timestamp group whole so the cursor can advance by SystemModifiedAt alone. Safe while groups
                // are small; a group too large to page keylessly asks for the composite key instead.
                RecRef.SetView(StrSubstNo(SortByModifiedAtTok, SystemModifiedAtFieldNo()));
                ApplyRowFilter(RecRef, Filter);
                HasMore := FillDrainPage(RecRef, HasCursor, CursorModifiedAt, ProjectedFields, PageSize, Records, Count, NextModifiedAt, GroupTooLarge);
                if GroupTooLarge then begin
                    Clear(Records);
                    Response.Add('indexed', false);
                    exit(WriteResponse(Response, true, Records, false));
                end;
                if Count > 0 then
                    Response.Add('nextCursor', BuildModifiedAtCursor(NextModifiedAt));
            end else begin
                // No SystemModifiedAt index at all: no-code scan fallback. Order by primary key (always indexed),
                // filter SystemModifiedAt > watermark, and return the whole changed set in one shot (capped).
                // Over the cap, ask for the composite key (only large unindexed tables need it).
                ApplyRowFilter(RecRef, Filter);
                HasMore := FillScanPage(RecRef, HasCursor, CursorModifiedAt, ProjectedFields, Records, Count, NextModifiedAt, GroupTooLarge);
                if GroupTooLarge then begin
                    Clear(Records);
                    Response.Add('indexed', false);
                    exit(WriteResponse(Response, true, Records, false));
                end;
                if Count > 0 then
                    Response.Add('nextCursor', BuildModifiedAtCursor(NextModifiedAt));
            end;

        Response.Add('records', Records);
        Response.Add('hasMore', HasMore);
        Response.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure WriteResponse(var Response: JsonObject; TableAvailable: Boolean; var Records: JsonArray; HasMore: Boolean): Text
    var
        ResultText: Text;
    begin
        if not Response.Contains('tableAvailable') then
            Response.Add('tableAvailable', TableAvailable);
        Response.Add('records', Records);
        Response.Add('hasMore', HasMore);
        Response.WriteTo(ResultText);
        exit(ResultText);
    end;

    [TryFunction]
    local procedure TryOpenTable(TableId: Integer; var RecRef: RecordRef)
    begin
        RecRef.Open(TableId);
        RecRef.ReadIsolation := IsolationLevel::ReadCommitted;
    end;

    // Media/infrastructure tables are only reachable inline (BuildMediaValue, tied to a record's media field). Never
    // serve them as a top-level read, or a caller holding the Tenant Media read grant could enumerate every blob.
    // The environment serving its data must have consented. If not, return a structured signal (not an error) so the
    // subsidiary surfaces a clear, actionable message instead of a raw HTTP failure.
    local procedure IsSourceConsented(): Boolean
    var
        MDMPrivacyNotice: Codeunit "MDM Privacy Notice";
    begin
        exit(MDMPrivacyNotice.IsApproved());
    end;

    local procedure ConsentRequiredResponse(): Text
    var
        Response: JsonObject;
        ResultText: Text;
    begin
        Response.Add('consentRequired', true);
        Response.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure IsBlockedSourceTable(TableId: Integer): Boolean
    begin
        exit(TableId in [Database::"Tenant Media", Database::"Tenant Media Set", Database::"Tenant Media Thumbnails"]);
    end;

    // Applies the mapping's row filter server-side (parity with same-env, which filters the source record directly).
    // Re-hydrated as field-level filters so it composes with the change-feed SORTING view already set for paging,
    // and works even when the filter references a field outside the projection (which the temp buffer would default).
    local procedure ApplyRowFilter(var RecRef: RecordRef; Filter: Text)
    var
        FilterSource: RecordRef;
        SourceField: FieldRef;
        FieldFilter: Text;
        Index: Integer;
    begin
        if Filter = '' then
            exit;
        FilterSource.Open(RecRef.Number());
        FilterSource.SetView(Filter);
        for Index := 1 to FilterSource.FieldCount() do begin
            SourceField := FilterSource.FieldIndex(Index);
            FieldFilter := SourceField.GetFilter();
            if FieldFilter <> '' then
                RecRef.Field(SourceField.Number()).SetFilter(FieldFilter);
        end;
        FilterSource.Close();
    end;

    local procedure ResolveProjection(var RecRef: RecordRef; FieldIds: Text; var ProjectedFields: List of [Integer]; var UnavailableFields: JsonArray)
    var
        RequestedFields: JsonArray;
        Token: JsonToken;
        FieldNo: Integer;
    begin
        if not TryReadJsonArray(FieldIds, RequestedFields) then
            exit;
        foreach Token in RequestedFields do
            if Token.IsValue() and TryReadInteger(Token, FieldNo) then // a malformed field id is skipped, not served as an error
                if not RecRef.FieldExist(FieldNo) then
                    UnavailableFields.Add(FieldNo)
                else
                    if IsProjectableField(RecRef.Field(FieldNo)) then
                        ProjectedFields.Add(FieldNo);
    end;

    local procedure IsProjectableField(FieldReference: FieldRef): Boolean
    begin
        // Media and Blob are projected inline (base64); MediaSet is deferred and TableFilter carries no data.
        exit((FieldReference.Class() = FieldClass::Normal) and
             not (FieldReference.Type() in [FieldType::MediaSet, FieldType::TableFilter]));
    end;

    // Load only the projected fields (plus the change-feed keys) so wide source tables aren't fully materialized.
    local procedure ApplyProjectionLoadFields(var RecRef: RecordRef; ProjectedFields: List of [Integer])
    var
        FieldNo: Integer;
    begin
        RecRef.SetLoadFields(SystemModifiedAtFieldNo(), SystemIdFieldNo());
        foreach FieldNo in ProjectedFields do
            RecRef.AddLoadFields(FieldNo);
    end;

    local procedure SelectorSystemIds(Selector: Text; var SystemIds: JsonArray): Boolean
    var
        SelectorObject: JsonObject;
        Token: JsonToken;
    begin
        if not TryReadJsonObject(Selector, SelectorObject) then
            exit(false);
        if not SelectorObject.Get('systemIds', Token) then
            exit(false);
        if not Token.IsArray() then
            exit(false);
        SystemIds := Token.AsArray();
        exit(SystemIds.Count() > 0);
    end;

    local procedure SelectorCursor(Selector: Text; var CursorModifiedAt: DateTime; var CursorSystemId: Guid): Boolean
    var
        SelectorObject: JsonObject;
        Token: JsonToken;
    begin
        if not TryReadJsonObject(Selector, SelectorObject) then
            exit(false);
        if not SelectorObject.Get('modifiedAt', Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if not Evaluate(CursorModifiedAt, Token.AsValue().AsText(), 9) then
            exit(false);
        if SelectorObject.Get('systemId', Token) and Token.IsValue() then
            Evaluate(CursorSystemId, Token.AsValue().AsText());
        exit(true);
    end;

    local procedure HasCompositeChangeFeedKey(var RecRef: RecordRef): Boolean
    var
        CurrentKey: KeyRef;
        Index: Integer;
    begin
        for Index := 1 to RecRef.KeyCount() do begin
            CurrentKey := RecRef.KeyIndex(Index);
            if CurrentKey.FieldCount() >= 2 then
                if (CurrentKey.FieldIndex(1).Number() = SystemModifiedAtFieldNo()) and
                   (CurrentKey.FieldIndex(2).Number() = SystemIdFieldNo())
                then
                    exit(true);
        end;
        exit(false);
    end;

    local procedure HasModifiedAtLeadingKey(var RecRef: RecordRef): Boolean
    var
        CurrentKey: KeyRef;
        Index: Integer;
    begin
        for Index := 1 to RecRef.KeyCount() do begin
            CurrentKey := RecRef.KeyIndex(Index);
            if CurrentKey.FieldCount() >= 1 then
                if CurrentKey.FieldIndex(1).Number() = SystemModifiedAtFieldNo() then
                    exit(true);
        end;
        exit(false);
    end;

    // No SystemId tiebreak available, so never split a timestamp group across pages: fill to PageSize, then
    // drain the trailing group whole and advance the cursor by SystemModifiedAt with a strict '>'.
    local procedure FillDrainPage(var RecRef: RecordRef; HasCursor: Boolean; CursorModifiedAt: DateTime; ProjectedFields: List of [Integer]; PageSize: Integer; var Records: JsonArray; var Count: Integer; var NextModifiedAt: DateTime; var GroupTooLarge: Boolean): Boolean
    var
        ModifiedAtRef: FieldRef;
        CurrentModifiedAt: DateTime;
        LastEmittedAt: DateTime;
        IgnoredSystemId: Guid;
        MaxKeylessGroup: Integer;
        PageBytes: Integer;
    begin
        Count := 0;
        PageBytes := 0;
        LastEmittedAt := 0DT;
        GroupTooLarge := false;
        MaxKeylessGroup := 10000;
        ModifiedAtRef := RecRef.Field(SystemModifiedAtFieldNo());
        if HasCursor then
            ModifiedAtRef.SetFilter('>%1', CursorModifiedAt);
        if RecRef.FindSet() then
            repeat
                CurrentModifiedAt := ModifiedAtRef.Value();
                // Stop only at a clean group boundary once the page is full (by count or inline bytes).
                if ((Count >= PageSize) or (PageBytes >= MaxPageInlineBytes())) and (CurrentModifiedAt <> LastEmittedAt) then
                    exit(true);
                // A single same-timestamp group that can't be paged cleanly (too many rows OR too many inline bytes) => ask for a key.
                if (Count >= MaxKeylessGroup) or (PageBytes >= MaxPageInlineBytes()) then begin
                    GroupTooLarge := true;
                    exit(false);
                end;
                AppendRecord(RecRef, ProjectedFields, Records, NextModifiedAt, IgnoredSystemId, PageBytes);
                LastEmittedAt := NextModifiedAt;
                Count += 1;
            until RecRef.Next() = 0;
        exit(false);
    end;

    // No SystemModifiedAt index at all: order by primary key (always indexed) and filter SystemModifiedAt >
    // watermark. Single-shot up to a cap; a bigger changed set trips TooLarge so the caller asks for a key.
    local procedure FillScanPage(var RecRef: RecordRef; HasCursor: Boolean; CursorModifiedAt: DateTime; ProjectedFields: List of [Integer]; var Records: JsonArray; var Count: Integer; var MaxModifiedAt: DateTime; var TooLarge: Boolean): Boolean
    var
        ModifiedAtRef: FieldRef;
        CurrentModifiedAt: DateTime;
        IgnoredModifiedAt: DateTime;
        IgnoredSystemId: Guid;
        MaxUnindexedRecords: Integer;
        PageBytes: Integer;
    begin
        Count := 0;
        PageBytes := 0;
        TooLarge := false;
        MaxUnindexedRecords := 10000;
        ModifiedAtRef := RecRef.Field(SystemModifiedAtFieldNo());
        if HasCursor then
            ModifiedAtRef.SetFilter('>%1', CursorModifiedAt);
        if RecRef.FindSet() then
            repeat
                // Unindexed scan can't resume mid-set, so too many records OR too many inline bytes => ask for a key.
                if (Count >= MaxUnindexedRecords) or (PageBytes >= MaxPageInlineBytes()) then begin
                    TooLarge := true;
                    exit(false);
                end;
                CurrentModifiedAt := ModifiedAtRef.Value();
                if CurrentModifiedAt > MaxModifiedAt then
                    MaxModifiedAt := CurrentModifiedAt;
                AppendRecord(RecRef, ProjectedFields, Records, IgnoredModifiedAt, IgnoredSystemId, PageBytes);
                Count += 1;
            until RecRef.Next() = 0;
        exit(false);
    end;

    local procedure FillCursorPage(var RecRef: RecordRef; HasCursor: Boolean; CursorModifiedAt: DateTime; CursorSystemId: Guid; ProjectedFields: List of [Integer]; PageSize: Integer; var Records: JsonArray; var Count: Integer; var NextModifiedAt: DateTime; var NextSystemId: Guid): Boolean
    var
        ModifiedAtRef: FieldRef;
        SystemIdRef: FieldRef;
        PageBytes: Integer;
    begin
        Count := 0;
        ModifiedAtRef := RecRef.Field(SystemModifiedAtFieldNo());
        SystemIdRef := RecRef.Field(SystemIdFieldNo());

        // Pass 1: records at exactly the cursor timestamp but a later SystemId (DB uniqueidentifier order).
        if HasCursor then begin
            ModifiedAtRef.SetRange(CursorModifiedAt);
            SystemIdRef.SetFilter('>%1', CursorSystemId);
            if RecRef.FindSet() then
                repeat
                    if Count = PageSize then
                        exit(true);
                    AppendRecord(RecRef, ProjectedFields, Records, NextModifiedAt, NextSystemId, PageBytes);
                    Count += 1;
                    if PageBytes >= MaxPageInlineBytes() then
                        exit(true); // inline-byte budget: >=1 record emitted; resume from NextModifiedAt/NextSystemId
                until RecRef.Next() = 0;
            ModifiedAtRef.SetRange();
            SystemIdRef.SetRange();
        end;

        // Pass 2: records strictly after the cursor timestamp (or all records on the first call).
        if HasCursor then
            ModifiedAtRef.SetFilter('>%1', CursorModifiedAt);
        if RecRef.FindSet() then
            repeat
                if Count = PageSize then
                    exit(true);
                AppendRecord(RecRef, ProjectedFields, Records, NextModifiedAt, NextSystemId, PageBytes);
                Count += 1;
                if PageBytes >= MaxPageInlineBytes() then
                    exit(true);
            until RecRef.Next() = 0;

        exit(false);
    end;

    local procedure FillBySystemIds(var RecRef: RecordRef; SystemIds: JsonArray; ProjectedFields: List of [Integer]; var Records: JsonArray)
    var
        SystemIdRef: FieldRef;
        FilterBuilder: TextBuilder;
        Token: JsonToken;
        SystemIdValue: Guid;
        IgnoredModifiedAt: DateTime;
        IgnoredSystemId: Guid;
        IgnoredPageBytes: Integer;
        FilterText: Text;
    begin
        foreach Token in SystemIds do
            if Token.IsValue() and Evaluate(SystemIdValue, Token.AsValue().AsText()) then begin
                if FilterBuilder.Length() > 0 then
                    FilterBuilder.Append('|');
                FilterBuilder.Append(Format(SystemIdValue));
            end;
        FilterText := FilterBuilder.ToText();
        if FilterText = '' then
            exit;

        SystemIdRef := RecRef.Field(SystemIdFieldNo());
        SystemIdRef.SetFilter(FilterText);
        if RecRef.FindSet() then
            repeat
                AppendRecord(RecRef, ProjectedFields, Records, IgnoredModifiedAt, IgnoredSystemId, IgnoredPageBytes);
            until RecRef.Next() = 0;
    end;

    local procedure AppendRecord(var RecRef: RecordRef; ProjectedFields: List of [Integer]; var Records: JsonArray; var LastModifiedAt: DateTime; var LastSystemId: Guid; var PageBytes: Integer)
    var
        CurrentField: FieldRef;
        RecordObject: JsonObject;
        FieldsObject: JsonObject;
        FieldNo: Integer;
    begin
        LastModifiedAt := RecRef.Field(SystemModifiedAtFieldNo()).Value();
        LastSystemId := RecRef.Field(SystemIdFieldNo()).Value();
        RecordObject.Add('systemId', Format(LastSystemId));
        RecordObject.Add('systemModifiedAt', FormatFieldValue(RecRef.Field(SystemModifiedAtFieldNo())));
        foreach FieldNo in ProjectedFields do begin
            CurrentField := RecRef.Field(FieldNo);
            case CurrentField.Type() of
                FieldType::Media:
                    FieldsObject.Add(Format(FieldNo), BuildMediaValue(CurrentField, PageBytes));
                FieldType::Blob:
                    FieldsObject.Add(Format(FieldNo), BuildBlobValue(CurrentField, PageBytes));
                else
                    FieldsObject.Add(Format(FieldNo), FormatFieldValue(CurrentField));
            end;
        end;
        RecordObject.Add('fields', FieldsObject);
        Records.Add(RecordObject);
    end;

    local procedure BuildCursor(ModifiedAt: DateTime; SystemId: Guid): JsonObject
    var
        Cursor: JsonObject;
    begin
        Cursor.Add('modifiedAt', Format(ModifiedAt, 0, 9));
        Cursor.Add('systemId', Format(SystemId));
        exit(Cursor);
    end;

    local procedure BuildModifiedAtCursor(ModifiedAt: DateTime): JsonObject
    var
        Cursor: JsonObject;
    begin
        Cursor.Add('modifiedAt', Format(ModifiedAt, 0, 9));
        exit(Cursor);
    end;

    // Invariant (XML) format so field values round-trip via Evaluate(..., 9) on the subsidiary.
    local procedure FormatFieldValue(FieldReference: FieldRef): Text
    begin
        exit(Format(FieldReference.Value(), 0, 9));
    end;

    // Single Media field: emit { media, name, mimeType, length, content(base64) }, or { media, empty } when the
    // source has no picture, or { media, skipped, length } when it exceeds the inline cap.
    local procedure BuildMediaValue(FieldReference: FieldRef; var PageBytes: Integer): JsonObject
    var
        TenantMedia: Record "Tenant Media";
        Base64Convert: Codeunit "Base64 Convert";
        MediaValue: JsonObject;
        MediaId: Guid;
        ContentInStream: InStream;
    begin
        MediaValue.Add('media', true);
        MediaId := FieldReference.Value();
        if IsNullGuid(MediaId) then begin
            MediaValue.Add('empty', true);
            exit(MediaValue);
        end;
        TenantMedia.SetAutoCalcFields(Content);
        if not TenantMedia.Get(MediaId) then begin
            MediaValue.Add('empty', true);
            exit(MediaValue);
        end;
        if TenantMedia.Content.Length() > MaxInlineContentSize() then begin
            MediaValue.Add('skipped', true);
            MediaValue.Add('length', TenantMedia.Content.Length());
            exit(MediaValue);
        end;
        MediaValue.Add('name', TenantMedia."File Name");
        MediaValue.Add('mimeType', TenantMedia."Mime Type");
        MediaValue.Add('length', TenantMedia.Content.Length());
        TenantMedia.Content.CreateInStream(ContentInStream);
        MediaValue.Add('content', Base64Convert.ToBase64(ContentInStream));
        PageBytes += TenantMedia.Content.Length();
        exit(MediaValue);
    end;

    // Blob field: emit { blob, length, content(base64) }, or { blob, empty }, or { blob, skipped, length }.
    local procedure BuildBlobValue(FieldReference: FieldRef; var PageBytes: Integer): JsonObject
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        BlobValue: JsonObject;
        ContentInStream: InStream;
    begin
        BlobValue.Add('blob', true);
        TempBlob.FromFieldRef(FieldReference);
        if not TempBlob.HasValue() then begin
            BlobValue.Add('empty', true);
            exit(BlobValue);
        end;
        if TempBlob.Length() > MaxInlineContentSize() then begin
            BlobValue.Add('skipped', true);
            BlobValue.Add('length', TempBlob.Length());
            exit(BlobValue);
        end;
        BlobValue.Add('length', TempBlob.Length());
        TempBlob.CreateInStream(ContentInStream);
        BlobValue.Add('content', Base64Convert.ToBase64(ContentInStream));
        PageBytes += TempBlob.Length();
        exit(BlobValue);
    end;

    // 512 KB raw. Its base64 form (~700 KB) stays under BC's 1,000,000-byte single-stream-read limit; do not
    // raise toward 1 MB, where the encoded value would exceed that limit on a single read.
    local procedure MaxInlineContentSize(): Integer
    begin
        exit(512 * 1024);
    end;

    // Cap inline media/blob bytes per page (~3 MB raw, ~4 MB base64) so a media-heavy page stays well under the
    // 8-minute operation timeout and memory; the composite cursor resumes the remaining records on the next page.
    local procedure MaxPageInlineBytes(): Integer
    var
        MaxBytes: Integer;
    begin
        MaxBytes := 3 * 1024 * 1024;
        OnGetMaxPageInlineBytes(MaxBytes);
        exit(MaxBytes);
    end;

    [InternalEvent(false)]
    local procedure OnGetMaxPageInlineBytes(var MaxBytes: Integer)
    begin
    end;

    local procedure TryReadJsonArray(Value: Text; var JsonArrayValue: JsonArray): Boolean
    begin
        exit(JsonArrayValue.ReadFrom(Value));
    end;

    local procedure TryReadJsonObject(Value: Text; var JsonObjectValue: JsonObject): Boolean
    begin
        exit(JsonObjectValue.ReadFrom(Value));
    end;

    [TryFunction]
    local procedure TryReadInteger(Token: JsonToken; var Value: Integer)
    begin
        Value := Token.AsValue().AsInteger();
    end;

    local procedure ClampPageSize(PageSize: Integer): Integer
    begin
        if PageSize <= 0 then
            exit(100);
        if PageSize > 1000 then
            exit(1000);
        exit(PageSize);
    end;

    local procedure SystemIdFieldNo(): Integer
    begin
        exit(2000000000);
    end;

    local procedure SystemModifiedAtFieldNo(): Integer
    begin
        exit(2000000003);
    end;

    /// <summary>
    /// Change detection: for each requested table id, returns its latest source modification timestamp so
    /// the subsidiary detector can decide which per-table sync jobs to reschedule. Read from the change-feed
    /// index tip (FindLast), so no scan and no summary table to maintain.
    /// </summary>
    /// <param name="TableIds">A JSON array of the source table IDs to probe.</param>
    /// <returns>A JSON object with a 'tables' array of { tableId, tableAvailable, indexed, lastModifiedAt } entries.</returns>
    [ServiceEnabled]
    procedure LastModifiedAtPerTable(TableIds: Text): Text
    var
        RequestedTables: JsonArray;
        Tables: JsonArray;
        Response: JsonObject;
        Token: JsonToken;
        ResultText: Text;
        TableId: Integer;
    begin
        if not IsSourceConsented() then
            exit(ConsentRequiredResponse());
        if TryReadJsonArray(TableIds, RequestedTables) then
            foreach Token in RequestedTables do
                if Token.IsValue() and TryReadInteger(Token, TableId) then // a malformed table id is skipped, not served as an error
                    Tables.Add(BuildTableModifiedAt(TableId));
        Response.Add('tables', Tables);
        Response.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure BuildTableModifiedAt(TableId: Integer): JsonObject
    var
        RecRef: RecordRef;
        Entry: JsonObject;
    begin
        Entry.Add('tableId', TableId);
        if IsBlockedSourceTable(TableId) or (not TryOpenTable(TableId, RecRef)) then begin
            Entry.Add('tableAvailable', false);
            exit(Entry);
        end;
        Entry.Add('tableAvailable', true);
        if not HasModifiedAtLeadingKey(RecRef) then begin
            Entry.Add('indexed', false);
            exit(Entry);
        end;
        RecRef.SetView(StrSubstNo(SortByModifiedAtTok, SystemModifiedAtFieldNo()));
        // Detection only needs an approximate max, so read uncommitted: never takes or waits on a lock, even
        // where snapshot isolation is off (OnPrem). Data reads (GetRecords) stay at committed isolation.
        RecRef.ReadIsolation := IsolationLevel::ReadUncommitted;
        RecRef.SetLoadFields(SystemModifiedAtFieldNo());
        if RecRef.FindLast() then
            Entry.Add('lastModifiedAt', Format(RecRef.Field(SystemModifiedAtFieldNo()).Value(), 0, 9))
        else
            Entry.Add('lastModifiedAt', ''); // empty table: no changes to detect
        exit(Entry);
    end;

    local procedure ApiVersion(): Integer
    begin
        exit(1);
    end;
}

