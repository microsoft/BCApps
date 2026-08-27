#pragma warning disable AA0247
codeunit 139757 "Library - Master Data Mgt."
{
    Access = Public;

    procedure HandleOnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    begin
        MasterDataMgtSubscribers.HandleOnTransferFieldData(SourceFieldRef, DestinationFieldRef, NewValue, IsValueFound, NeedsConversion);
    end;

    procedure RenameIfNeededOnBeforeModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        MasterDataMgtSubscribers.RenameIfNeededOnBeforeModifyRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
    end;

    procedure HandleOnWasModifiedAfterLastSynch(IntegrationTableConnectionType: TableConnectionType; IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var SourceWasChanged: Boolean; var IsHandled: Boolean)
    begin
        MasterDataMgtSubscribers.HandleOnWasModifiedAfterLastSynch(IntegrationTableConnectionType, IntegrationTableMapping, SourceRecordRef, SourceWasChanged, IsHandled);
    end;

    procedure HandleOnFindAndSynchRecordIDFromIntegrationSystemId(IntegrationSystemId: Guid; TableId: Integer; var LocalRecordID: RecordID; var IsHandled: Boolean)
    begin
        MasterDataMgtSubscribers.HandleOnFindAndSynchRecordIDFromIntegrationSystemId(IntegrationSystemId, TableId, LocalRecordID, IsHandled);
    end;

    procedure HandleOnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    begin
        MasterDataMgtSubscribers.HandleOnFindingIfJobNeedsToBeRun(Sender, Result);
    end;

    procedure HandleOnAfterJobQueueEntryRun(var JobQueueEntry: Record "Job Queue Entry")
    begin
        MasterDataMgtSubscribers.HandleOnAfterJobQueueEntryRun(JobQueueEntry);
    end;

    procedure FindRelatedTables(var ExistingSynchTableNos: List of [Integer]; var RelatedTablesToAdd: List of [Integer]; var RelatedTablesToAddText: Text; TableId: Integer)
    var
        MasterDataSynchTables: Page "Master Data Synch. Tables";
    begin
        MasterDataSynchTables.FindRelatedTables(ExistingSynchTableNos, RelatedTablesToAdd, RelatedTablesToAddText, TableId);
    end;

    procedure SetSourceCompanyToCurrent()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        MasterDataManagementSetup."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Modify(false);
    end;

    procedure GetIntegrationRecordRefByCoupling(IntegrationTableID: Integer; var MasterDataMgtCoupling: Record "Master Data Mgt. Coupling"; var RecRef: RecordRef): Boolean
    begin
        exit(MasterDataManagement.GetIntegrationRecordRef(IntegrationTableID, MasterDataMgtCoupling, RecRef));
    end;

    procedure GetIntegrationRecordRefById(var IntegrationTableMapping: Record "Integration Table Mapping"; ID: Variant; var RecRef: RecordRef): Boolean
    begin
        exit(MasterDataManagement.GetIntegrationRecordRef(IntegrationTableMapping, ID, RecRef));
    end;

    procedure DataSourceGetModifiedSet(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        exit(MasterDataManagementSetup.GetDataSource().GetModifiedSet(IntegrationTableMapping, TableFilter, SourceRecordRef));
    end;

    procedure DataSourceGetByUidFilter(IntegrationTableMapping: Record "Integration Table Mapping"; UidFilter: Text; var SourceRecordRef: RecordRef): Boolean
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        exit(MasterDataManagementSetup.GetDataSource().GetByUidFilter(IntegrationTableMapping, UidFilter, SourceRecordRef));
    end;

    procedure DataSourceGetByFilter(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        exit(MasterDataManagementSetup.GetDataSource().GetByFilter(IntegrationTableMapping, TableFilter, SourceRecordRef));
    end;

    procedure GetIntegrationRecRefCount(IntegrationTableMapping: Record "Integration Table Mapping"): Integer
    var
        MasterDataManagement: Codeunit "Master Data Management";
    begin
        exit(MasterDataManagement.GetIntegrationRecRefCount(IntegrationTableMapping));
    end;

    procedure DataSourceGetBySystemId(IntegrationTableId: Integer; SystemId: Guid; var SourceRecordRef: RecordRef): Boolean
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        exit(MasterDataManagementSetup.GetDataSource().GetBySystemId(IntegrationTableId, SystemId, SourceRecordRef));
    end;

    procedure DataSourceGetModifiedBatch(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; StartCursor: Text; MaxPages: Integer; var SourceRecordRef: RecordRef; var EndCursor: Text; var HasMore: Boolean): Boolean
    var
        CrossEnvDataSource: Codeunit "MDM Cross-Env Data Source";
    begin
        exit(CrossEnvDataSource.GetModifiedBatch(IntegrationTableMapping, TableFilter, StartCursor, MaxPages, SourceRecordRef, EndCursor, HasMore));
    end;

    // Setting a Source Environment Name routes GetDataSource() to the cross-environment implementation.
    procedure SetSourceEnvironmentName(EnvironmentName: Text)
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        MasterDataManagementSetup."Source Environment Name" := CopyStr(EnvironmentName, 1, MaxStrLen(MasterDataManagementSetup."Source Environment Name"));
        MasterDataManagementSetup.Modify(false);
    end;

    procedure RunChangeDetector()
    var
        MDMCrossEnvChangeDetector: Codeunit "MDM Cross-Env Change Detector";
    begin
        MDMCrossEnvChangeDetector.DetectChanges();
    end;

    var
        MasterDataMgtSubscribers: Codeunit "Master Data Mgt. Subscribers";
        MasterDataManagement: Codeunit "Master Data Management";
}
