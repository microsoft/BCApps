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
        IDFieldRef: FieldRef;
        RecId: RecordID;
        TextKey: Text;
    begin
        SourceRecordRef.Close();
        if ID.IsGuid then begin
            OpenSourceRecordRef(IntegrationTableMapping."Integration Table ID", SourceRecordRef);
            IDFieldRef := SourceRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
            IDFieldRef.SetFilter(ID);
            exit(SourceRecordRef.FindFirst());
        end;

        if ID.IsRecordId then begin
            OpenSourceRecordRef(IntegrationTableMapping."Integration Table ID", SourceRecordRef);
            RecId := ID;
            if RecId.TableNo = IntegrationTableMapping."Table ID" then
                exit(SourceRecordRef.Get(ID));
        end;

        if ID.IsText then begin
            OpenSourceRecordRef(IntegrationTableMapping."Integration Table ID", SourceRecordRef);
            IDFieldRef := SourceRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.");
            TextKey := ID;
            IDFieldRef.SetFilter('%1', TextKey);
            exit(SourceRecordRef.FindFirst());
        end;
    end;

    local procedure OpenSourceRecordRef(IntegrationTableId: Integer; var SourceRecordRef: RecordRef)
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataManagement: Codeunit "Master Data Management";
        SourceCompanyName: Text[30];
    begin
        MasterDataManagementSetup.Get();
        SourceRecordRef.Open(IntegrationTableId);
        MasterDataManagement.OnSetSourceCompanyName(SourceCompanyName, IntegrationTableId);
        if SourceCompanyName = '' then
            SourceCompanyName := MasterDataManagementSetup."Company Name";
        SourceRecordRef.ChangeCompany(SourceCompanyName);
    end;
}
