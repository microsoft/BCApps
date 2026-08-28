namespace Microsoft.Integration.MDM;

using Microsoft.Integration.SyncEngine;

/// <summary>
/// Reads source master data from another ENVIRONMENT (same tenant) over the ODataV4 source API and materializes
/// results into temporary records, so the existing synchronization engine processes them unchanged. Selected by
/// GetDataSource() when a Source Environment Name is configured. Wire calls go through IMDM Source Transport,
/// which tests swap for an in-process transport (source and subsidiary run in the same environment there).
/// </summary>
codeunit 7249 "MDM Cross-Env Data Source" implements "IMDM Data Source"
{
    Access = Internal;

    var
        SourceResponse: Codeunit "MDM Source Response";
        SourceCapabilities: Codeunit "MDM Source Capabilities";
        InlineMedia: Codeunit "MDM Inline Media";
        InvalidResponseErr: Label 'The source environment returned an unexpected response for table %1.', Comment = '%1 = table caption';
        TableUnavailableErr: Label 'Table %1 is not available on the source environment. Expose it there or remove it from Synchronization Tables.', Comment = '%1 = table caption';
        NotIndexedErr: Label 'Table %1 on the source has too many same-timestamp changes to synchronize without an index. Add a key on SystemModifiedAt and SystemId to that table on the source environment.', Comment = '%1 = table caption';
        FieldsUnavailableErr: Label 'One or more fields set up for synchronization do not exist on table %1 on the source environment.', Comment = '%1 = table caption';
        SourceProbeFailedErr: Label 'Could not read the change probe from the source environment for table %1.', Comment = '%1 = table caption';
        RecordsFeatureTok: Label 'records', Locked = true;
        LastModifiedFeatureTok: Label 'lastModifiedPerTable', Locked = true;

    procedure GetModifiedSet(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean
    var
        EndCursor: Text;
        HasMore: Boolean;
    begin
        // Interface entry point: unbounded (fetch the whole delta). The scheduled cross-env synch uses the
        // bounded GetModifiedBatch instead, so a large initial load is drained across several job runs.
        exit(GetModifiedBatch(IntegrationTableMapping, TableFilter, CursorSelector(IntegrationTableMapping."Synch. Modified On Filter"), 0, SourceRecordRef, EndCursor, HasMore));
    end;

    procedure GetByFilter(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean
    var
        EndCursor: Text;
        HasMore: Boolean;
    begin
        // Full read from the start (selector '{}' = no watermark), then apply the row filter - for coupling/uncoupling.
        exit(GetModifiedBatch(IntegrationTableMapping, TableFilter, '{}', 0, SourceRecordRef, EndCursor, HasMore));
    end;

    /// <summary>
    /// Fetches at most MaxPages pages of changed source records starting from StartCursor (a cursor selector).
    /// MaxPages = 0 means unbounded. On return EndCursor holds the resume point and HasMore tells the caller
    /// whether more pages remain past the cap, so the next job run can continue from where this one stopped.
    /// </summary>
    internal procedure GetModifiedBatch(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; StartCursor: Text; MaxPages: Integer; var SourceRecordRef: RecordRef; var EndCursor: Text; var HasMore: Boolean): Boolean
    var
        Transport: Interface "IMDM Source Transport";
        Response: JsonObject;
        FieldIds: Text;
        Selector: Text;
        PagesFetched: Integer;
    begin
        SourceRecordRef.Close();
        SourceRecordRef.Open(IntegrationTableMapping."Integration Table ID", true);
        InlineMedia.Reset(); // fresh batch: drop the previous page's inline media bytes
        Transport := GetTransport();
        SourceCapabilities.EnsureSupported(Transport, RecordsFeatureTok);
        FieldIds := BuildFieldIds(IntegrationTableMapping);
        if StartCursor <> '' then
            Selector := StartCursor
        else
            Selector := CursorSelector(IntegrationTableMapping."Synch. Modified On Filter");
        EndCursor := '';
        HasMore := false;
        repeat
            ParseOrError(
                IntegrationTableMapping."Integration Table ID",
                Transport.GetRecords(IntegrationTableMapping."Integration Table ID", FieldIds, Selector, PageSize()),
                Response);
            SourceResponse.InsertRecords(Response, SourceRecordRef);
            PagesFetched += 1;
            HasMore := SourceResponse.HasMore(Response);
            if HasMore then begin
                EndCursor := SourceResponse.GetNextCursor(Response);
                Selector := EndCursor;
            end;
        until (not HasMore) or ((MaxPages > 0) and (PagesFetched >= MaxPages));
        // Apply only the mapping's row filter. The source already filtered by the watermark cursor server-side;
        // re-applying the modified-on filter here would drop every record, since the materialized temp rows
        // carry no SystemModifiedAt.
        if TableFilter <> '' then
            SourceRecordRef.SetView(TableFilter);
        exit(SourceRecordRef.FindSet());
    end;

    /// <summary>
    /// Cheap existence probe for the full-synch review: the source reports an empty lastModifiedAt for an empty
    /// table, so this avoids counting the whole table over the wire.
    /// </summary>
    internal procedure SourceHasRecords(IntegrationTableId: Integer): Boolean
    var
        Transport: Interface "IMDM Source Transport";
        Response: JsonObject;
        Entry: JsonObject;
        Tables: JsonArray;
        Token: JsonToken;
        TableIds: JsonArray;
        TableIdsText: Text;
        LastModifiedAtText: Text;
    begin
        TableIds.Add(IntegrationTableId);
        TableIds.WriteTo(TableIdsText);
        Transport := GetTransport();
        SourceCapabilities.EnsureSupported(Transport, LastModifiedFeatureTok);
        // A transport/parse failure is not an empty source; surface it so the full-synch review isn't misled.
        if not SourceResponse.TryParse(Transport.LastModifiedAtPerTable(TableIdsText), Response) then
            Error(SourceProbeFailedErr, TableCaption(IntegrationTableId));
        if not Response.Get('tables', Token) then
            Error(SourceProbeFailedErr, TableCaption(IntegrationTableId));
        Tables := Token.AsArray();
        if Tables.Count() = 0 then
            Error(SourceProbeFailedErr, TableCaption(IntegrationTableId));
        Tables.Get(0, Token);
        Entry := Token.AsObject();
        if Entry.Get('tableAvailable', Token) then
            if not Token.AsValue().AsBoolean() then
                exit(false);
        // Unindexed source table: LastModifiedAtPerTable reports indexed:false and no timestamp, so we can't prove
        // emptiness cheaply - assume records may exist so the full-synch review isn't wrongly suppressed.
        if Entry.Get('indexed', Token) then
            if Token.IsValue() and (not Token.AsValue().AsBoolean()) then
                exit(true);
        if Entry.Get('lastModifiedAt', Token) then
            if Token.IsValue() then
                LastModifiedAtText := Token.AsValue().AsText();
        exit(LastModifiedAtText <> '');
    end;

    procedure GetBySystemId(IntegrationTableId: Integer; SystemId: Guid; var SourceRecordRef: RecordRef): Boolean
    var
        SystemIds: List of [Guid];
    begin
        SystemIds.Add(SystemId);
        FetchBySystemIds(IntegrationTableId, BuildFieldIdsForTable(IntegrationTableId), SystemIds, SourceRecordRef);
        exit(SourceRecordRef.FindFirst());
    end;

    procedure GetById(IntegrationTableMapping: Record "Integration Table Mapping"; ID: Variant; var SourceRecordRef: RecordRef): Boolean
    var
        SystemIds: List of [Guid];
        SystemIdValue: Guid;
        TextKey: Text;
    begin
        if ID.IsGuid then
            SystemIdValue := ID
        else
            if ID.IsText then begin
                TextKey := ID;
                if not Evaluate(SystemIdValue, TextKey) then
                    exit(false);
            end else
                // RecordId is environment-specific; the cross-env feed keys on SystemId only.
                exit(false);
        SystemIds.Add(SystemIdValue);
        FetchBySystemIds(IntegrationTableMapping."Integration Table ID", BuildFieldIds(IntegrationTableMapping), SystemIds, SourceRecordRef);
        exit(SourceRecordRef.FindFirst());
    end;

    procedure GetByUidFilter(IntegrationTableMapping: Record "Integration Table Mapping"; UidFilter: Text; var SourceRecordRef: RecordRef): Boolean
    begin
        // MDM's UID field is SystemId, so a UID filter is a set of SystemIds.
        FetchBySystemIds(IntegrationTableMapping."Integration Table ID", BuildFieldIds(IntegrationTableMapping), ParseSystemIds(UidFilter), SourceRecordRef);
        exit(SourceRecordRef.FindSet());
    end;

    local procedure FetchBySystemIds(IntegrationTableId: Integer; FieldIds: Text; SystemIds: List of [Guid]; var SourceRecordRef: RecordRef)
    var
        Transport: Interface "IMDM Source Transport";
        Response: JsonObject;
    begin
        SourceRecordRef.Close();
        SourceRecordRef.Open(IntegrationTableId, true);
        InlineMedia.Reset(); // fresh fetch: drop any prior inline media bytes
        if SystemIds.Count() = 0 then
            exit;
        Transport := GetTransport();
        SourceCapabilities.EnsureSupported(Transport, RecordsFeatureTok);
        ParseOrError(
            IntegrationTableId,
            Transport.GetRecords(IntegrationTableId, FieldIds, SystemIdsSelector(SystemIds), PageSize()),
            Response);
        SourceResponse.InsertRecords(Response, SourceRecordRef);
    end;

    // A malformed wire response is an internal integration defect, not something the user can act on.
    local procedure InternalError(MessageText: Text): ErrorInfo
    var
        ErrInfo: ErrorInfo;
    begin
        ErrInfo.Message := MessageText;
        ErrInfo.ErrorType := ErrorType::Internal;
        exit(ErrInfo);
    end;

    local procedure ParseOrError(IntegrationTableId: Integer; ResponseText: Text; var Response: JsonObject)
    var
        UnavailableFields: JsonArray;
    begin
        Clear(Response);
        if not SourceResponse.TryParse(ResponseText, Response) then
            Error(InternalError(StrSubstNo(InvalidResponseErr, TableCaption(IntegrationTableId))));
        if not SourceResponse.TableAvailable(Response) then
            Error(TableUnavailableErr, TableCaption(IntegrationTableId));
        if not SourceResponse.Indexed(Response) then
            Error(NotIndexedErr, TableCaption(IntegrationTableId));
        if SourceResponse.GetUnavailableFields(Response, UnavailableFields) then
            Error(FieldsUnavailableErr, TableCaption(IntegrationTableId));
    end;

    // FieldIds = the mapping's integration-side fields + the table's primary-key fields (so temp inserts don't collide).
    local procedure BuildFieldIds(IntegrationTableMapping: Record "Integration Table Mapping"): Text
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        FieldIds: JsonArray;
        AddedFields: List of [Integer];
    begin
        AddPrimaryKeyFields(IntegrationTableMapping."Integration Table ID", FieldIds, AddedFields);
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetLoadFields("Integration Table Field No.");
        if IntegrationFieldMapping.FindSet() then
            repeat
                if IntegrationFieldMapping."Integration Table Field No." <> 0 then
                    AddFieldId(FieldIds, AddedFields, IntegrationFieldMapping."Integration Table Field No.");
            until IntegrationFieldMapping.Next() = 0;
        exit(WriteArray(FieldIds));
    end;

    local procedure BuildFieldIdsForTable(IntegrationTableId: Integer): Text
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if GetMappingByIntegrationTableId(IntegrationTableId, IntegrationTableMapping) then
            exit(BuildFieldIds(IntegrationTableMapping));
        exit(AllNormalFields(IntegrationTableId));
    end;

    local procedure GetMappingByIntegrationTableId(IntegrationTableId: Integer; var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        IntegrationTableMapping.SetRange("Integration Table ID", IntegrationTableId);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        exit(IntegrationTableMapping.FindFirst());
    end;

    local procedure AddPrimaryKeyFields(IntegrationTableId: Integer; var FieldIds: JsonArray; var AddedFields: List of [Integer])
    var
        RecRef: RecordRef;
        PrimaryKeyRef: KeyRef;
        Index: Integer;
    begin
        RecRef.Open(IntegrationTableId, true);
        PrimaryKeyRef := RecRef.KeyIndex(1);
        for Index := 1 to PrimaryKeyRef.FieldCount() do
            AddFieldId(FieldIds, AddedFields, PrimaryKeyRef.FieldIndex(Index).Number());
        RecRef.Close();
    end;

    local procedure AllNormalFields(IntegrationTableId: Integer): Text
    var
        RecRef: RecordRef;
        FieldIds: JsonArray;
        AddedFields: List of [Integer];
        CurrentField: FieldRef;
        Index: Integer;
    begin
        RecRef.Open(IntegrationTableId, true);
        for Index := 1 to RecRef.FieldCount() do begin
            CurrentField := RecRef.FieldIndex(Index);
            if CurrentField.Class() = FieldClass::Normal then
                if not (CurrentField.Type() in [FieldType::MediaSet, FieldType::TableFilter]) then
                    AddFieldId(FieldIds, AddedFields, CurrentField.Number());
        end;
        RecRef.Close();
        exit(WriteArray(FieldIds));
    end;

    local procedure AddFieldId(var FieldIds: JsonArray; var AddedFields: List of [Integer]; FieldNo: Integer)
    begin
        if AddedFields.Contains(FieldNo) then
            exit;
        AddedFields.Add(FieldNo);
        FieldIds.Add(FieldNo);
    end;

    local procedure ParseSystemIds(UidFilter: Text) SystemIds: List of [Guid]
    var
        Token: Text;
        SystemIdValue: Guid;
    begin
        foreach Token in UidFilter.Split('|') do
            if Evaluate(SystemIdValue, Token) then
                SystemIds.Add(SystemIdValue);
    end;

    local procedure SystemIdsSelector(SystemIds: List of [Guid]): Text
    var
        Selector: JsonObject;
        SystemIdArray: JsonArray;
        SystemIdValue: Guid;
        SelectorText: Text;
    begin
        foreach SystemIdValue in SystemIds do
            SystemIdArray.Add(Format(SystemIdValue));
        Selector.Add('systemIds', SystemIdArray);
        Selector.WriteTo(SelectorText);
        exit(SelectorText);
    end;

    local procedure CursorSelector(Watermark: DateTime): Text
    var
        Selector: JsonObject;
        SelectorText: Text;
    begin
        if Watermark = 0DT then
            exit('{}');
        Selector.Add('modifiedAt', Format(Watermark, 0, 9));
        Selector.WriteTo(SelectorText);
        exit(SelectorText);
    end;

    local procedure WriteArray(JsonArrayValue: JsonArray) ResultText: Text
    begin
        JsonArrayValue.WriteTo(ResultText);
    end;

    local procedure TableCaption(IntegrationTableId: Integer) Caption: Text
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(IntegrationTableId, true);
        Caption := RecRef.Caption();
        RecRef.Close();
    end;

    local procedure PageSize(): Integer
    var
        Size: Integer;
    begin
        Size := 1000;
        OnGetCrossEnvPageSize(Size);
        exit(Size);
    end;

    [InternalEvent(false)]
    local procedure OnGetCrossEnvPageSize(var PageSize: Integer)
    begin
    end;

    local procedure GetTransport(): Interface "IMDM Source Transport"
    var
        SourceConnection: Codeunit "MDM Source Connection";
    begin
        exit(SourceConnection.GetTransport());
    end;
}
