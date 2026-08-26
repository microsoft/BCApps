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
        InvalidResponseErr: Label 'The source environment returned an unexpected response for table %1.', Comment = '%1 = table caption';
        TableUnavailableErr: Label 'Table %1 is not available on the source environment. Expose it there or remove it from Synchronization Tables.', Comment = '%1 = table caption';
        NotIndexedErr: Label 'Table %1 on the source has too many same-timestamp changes to synchronize without an index. Add a key on SystemModifiedAt and SystemId to that table on the source environment.', Comment = '%1 = table caption';
        FieldsUnavailableErr: Label 'One or more fields set up for synchronization do not exist on table %1 on the source environment.', Comment = '%1 = table caption';

    procedure GetModifiedSet(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean
    var
        Transport: Interface "IMDM Source Transport";
        Response: JsonObject;
        FieldIds: Text;
        Selector: Text;
        MoreToFetch: Boolean;
    begin
        SourceRecordRef.Close();
        SourceRecordRef.Open(IntegrationTableMapping."Integration Table ID", true);
        Transport := GetTransport();
        FieldIds := BuildFieldIds(IntegrationTableMapping);
        // Watermark = 'Synchronize Changes Since'; the wire pages the delta, all accumulated into the temp ref.
        Selector := CursorSelector(IntegrationTableMapping."Synch. Modified On Filter");
        repeat
            ParseOrError(
                IntegrationTableMapping."Integration Table ID",
                Transport.GetRecords(IntegrationTableMapping."Integration Table ID", FieldIds, Selector, PageSize()),
                Response);
            SourceResponse.InsertRecords(Response, SourceRecordRef);
            MoreToFetch := SourceResponse.HasMore(Response);
            if MoreToFetch then
                Selector := SourceResponse.GetNextCursor(Response);
        until not MoreToFetch;
        IntegrationTableMapping.SetIntRecordRefFilter(SourceRecordRef, TableFilter);
        exit(SourceRecordRef.FindSet());
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
        if SystemIds.Count() = 0 then
            exit;
        Transport := GetTransport();
        ParseOrError(
            IntegrationTableId,
            Transport.GetRecords(IntegrationTableId, FieldIds, SystemIdsSelector(SystemIds), PageSize()),
            Response);
        SourceResponse.InsertRecords(Response, SourceRecordRef);
    end;

    local procedure ParseOrError(IntegrationTableId: Integer; ResponseText: Text; var Response: JsonObject)
    var
        UnavailableFields: JsonArray;
    begin
        Clear(Response);
        if not SourceResponse.TryParse(ResponseText, Response) then
            Error(InvalidResponseErr, TableCaption(IntegrationTableId));
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
                if not (CurrentField.Type() in [FieldType::Blob, FieldType::Media, FieldType::MediaSet]) then
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
    begin
        exit(1000);
    end;

    local procedure GetTransport() Transport: Interface "IMDM Source Transport"
    var
        HttpTransport: Codeunit "MDM Http Source Transport";
    begin
        Transport := HttpTransport;
        OnResolveSourceTransport(Transport);
    end;

    [InternalEvent(false)]
    local procedure OnResolveSourceTransport(var Transport: Interface "IMDM Source Transport")
    begin
    end;
}
