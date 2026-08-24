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
        OpenSourceRecordRef(IntegrationTableMapping, SourceRecordRef);
        IntegrationTableMapping.SetIntRecordRefFilter(SourceRecordRef, TableFilter);
        exit(SourceRecordRef.FindSet());
    end;

    procedure GetBySystemId(IntegrationTableMapping: Record "Integration Table Mapping"; SystemId: Guid; var SourceRecordRef: RecordRef): Boolean
    begin
        OpenSourceRecordRef(IntegrationTableMapping, SourceRecordRef);
        exit(SourceRecordRef.GetBySystemId(SystemId));
    end;

    local procedure OpenSourceRecordRef(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef)
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        MasterDataManagement: Codeunit "Master Data Management";
        SourceCompanyName: Text[30];
    begin
        MasterDataManagementSetup.Get();
        SourceRecordRef.Open(IntegrationTableMapping."Integration Table ID");
        MasterDataManagement.OnSetSourceCompanyName(SourceCompanyName, IntegrationTableMapping."Integration Table ID");
        if SourceCompanyName = '' then
            SourceCompanyName := MasterDataManagementSetup."Company Name";
        SourceRecordRef.ChangeCompany(SourceCompanyName);
    end;
}
