namespace Microsoft.Integration.MDM;

using Microsoft.Integration.SyncEngine;

/// <summary>
/// Reads source master data from another company in the same environment via ChangeCompany.
/// This preserves today's behavior; it is the implementation used whenever no source environment is set.
/// </summary>
codeunit 7240 "MDM Local Data Source" implements "IMDM Data Source"
{
    Access = Internal;

    procedure GetModifiedSet(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean
    begin
        OpenSourceRecordRef(IntegrationTableMapping."Integration Table ID", SourceRecordRef);
        IntegrationTableMapping.SetIntRecordRefFilter(SourceRecordRef, TableFilter);
        exit(SourceRecordRef.FindSet());
    end;

    procedure GetBySystemId(IntegrationTableId: Integer; SystemId: Guid; var SourceRecordRef: RecordRef): Boolean
    begin
        OpenSourceRecordRef(IntegrationTableId, SourceRecordRef);
        exit(SourceRecordRef.GetBySystemId(SystemId));
    end;

    procedure GetById(IntegrationTableMapping: Record "Integration Table Mapping"; ID: Variant; var SourceRecordRef: RecordRef): Boolean
    var
        RecId: RecordID;
        SystemId: Guid;
        TextKey: Text;
    begin
        SourceRecordRef.Close();
        // MDM always maps the integration UID to the SystemId field, so exact-key lookups seek by SystemId instead of a filtered find.
        if ID.IsGuid then begin
            OpenSourceRecordRef(IntegrationTableMapping."Integration Table ID", SourceRecordRef);
            SystemId := ID;
            exit(SourceRecordRef.GetBySystemId(SystemId));
        end;

        if ID.IsRecordId then begin
            OpenSourceRecordRef(IntegrationTableMapping."Integration Table ID", SourceRecordRef);
            RecId := ID;
            if RecId.TableNo = IntegrationTableMapping."Table ID" then
                exit(SourceRecordRef.Get(ID));
        end;

        if ID.IsText then begin
            TextKey := ID;
            if not Evaluate(SystemId, TextKey) then
                exit(false);
            OpenSourceRecordRef(IntegrationTableMapping."Integration Table ID", SourceRecordRef);
            exit(SourceRecordRef.GetBySystemId(SystemId));
        end;
    end;

    procedure GetByUidFilter(IntegrationTableMapping: Record "Integration Table Mapping"; UidFilter: Text; var SourceRecordRef: RecordRef): Boolean
    begin
        OpenSourceRecordRef(IntegrationTableMapping."Integration Table ID", SourceRecordRef);
        SourceRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").SetFilter(UidFilter);
        exit(SourceRecordRef.FindSet());
    end;

    procedure GetByFilter(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean
    begin
        OpenSourceRecordRef(IntegrationTableMapping."Integration Table ID", SourceRecordRef);
        if TableFilter <> '' then
            SourceRecordRef.SetView(TableFilter);
        exit(SourceRecordRef.FindSet());
    end;

    local procedure OpenSourceRecordRef(IntegrationTableId: Integer; var SourceRecordRef: RecordRef)
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataManagement: Codeunit "Master Data Management";
        SourceCompanyName: Text[30];
    begin
        MasterDataManagementSetup.Get();
        if SourceRecordRef.Number() <> 0 then
            SourceRecordRef.Close(); // a re-fetch may pass an already-open ref; start from a clean handle
        SourceRecordRef.Open(IntegrationTableId);
        MasterDataManagement.OnSetSourceCompanyName(SourceCompanyName, IntegrationTableId);
        if SourceCompanyName = '' then
            SourceCompanyName := MasterDataManagementSetup."Company Name";
        SourceRecordRef.ChangeCompany(SourceCompanyName);
    end;
}
