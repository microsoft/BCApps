#pragma warning disable AA0247
codeunit 139757 "Library - Master Data Mgt."
{
    Access = Public;

    /// <summary>Invokes the field-transfer subscriber logic that resolves the value to synchronize for a field.</summary>
    /// <param name="SourceFieldRef">The source field being transferred.</param>
    /// <param name="DestinationFieldRef">The destination field receiving the value.</param>
    /// <param name="NewValue">Returns the value to apply to the destination field.</param>
    /// <param name="IsValueFound">Returns true when the subscriber resolved the value.</param>
    /// <param name="NeedsConversion">Returns whether the resolved value still needs type conversion.</param>
    procedure HandleOnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    begin
        MasterDataMgtSubscribers.HandleOnTransferFieldData(SourceFieldRef, DestinationFieldRef, NewValue, IsValueFound, NeedsConversion);
    end;

    /// <summary>Renames the destination record before modification when the source primary key has changed.</summary>
    /// <param name="IntegrationTableMapping">The integration table mapping being synchronized.</param>
    /// <param name="SourceRecordRef">The source record providing the new primary key.</param>
    /// <param name="DestinationRecordRef">The destination record to rename in place.</param>
    procedure RenameIfNeededOnBeforeModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        MasterDataMgtSubscribers.RenameIfNeededOnBeforeModifyRecord(IntegrationTableMapping, SourceRecordRef, DestinationRecordRef);
    end;

    /// <summary>Determines whether the source record was modified after the last synchronization.</summary>
    /// <param name="IntegrationTableConnectionType">The connection type of the integration table.</param>
    /// <param name="IntegrationTableMapping">The integration table mapping being synchronized.</param>
    /// <param name="SourceRecordRef">The source record to evaluate.</param>
    /// <param name="SourceWasChanged">Returns true when the source record changed since the last synch.</param>
    /// <param name="IsHandled">Returns true when the subscriber handled the evaluation.</param>
    procedure HandleOnWasModifiedAfterLastSynch(IntegrationTableConnectionType: TableConnectionType; IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var SourceWasChanged: Boolean; var IsHandled: Boolean)
    begin
        MasterDataMgtSubscribers.HandleOnWasModifiedAfterLastSynch(IntegrationTableConnectionType, IntegrationTableMapping, SourceRecordRef, SourceWasChanged, IsHandled);
    end;

    /// <summary>Resolves the local record ID coupled to an integration SystemId, synchronizing it first if needed.</summary>
    /// <param name="IntegrationSystemId">The SystemId of the integration record.</param>
    /// <param name="TableId">The table ID to resolve against.</param>
    /// <param name="LocalRecordID">Returns the coupled local record ID.</param>
    /// <param name="IsHandled">Returns true when the subscriber handled the resolution.</param>
    procedure HandleOnFindAndSynchRecordIDFromIntegrationSystemId(IntegrationSystemId: Guid; TableId: Integer; var LocalRecordID: RecordID; var IsHandled: Boolean)
    begin
        MasterDataMgtSubscribers.HandleOnFindAndSynchRecordIDFromIntegrationSystemId(IntegrationSystemId, TableId, LocalRecordID, IsHandled);
    end;

    /// <summary>Evaluates whether a data-synchronization job queue entry needs to run.</summary>
    /// <param name="Sender">The job queue entry being evaluated.</param>
    /// <param name="Result">Returns true when the job needs to run.</param>
    procedure HandleOnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    begin
        MasterDataMgtSubscribers.HandleOnFindingIfJobNeedsToBeRun(Sender, Result);
    end;

    /// <summary>Runs the post-run handling for a data-synchronization job queue entry.</summary>
    /// <param name="JobQueueEntry">The job queue entry that finished running.</param>
    procedure HandleOnAfterJobQueueEntryRun(var JobQueueEntry: Record "Job Queue Entry")
    begin
        MasterDataMgtSubscribers.HandleOnAfterJobQueueEntryRun(JobQueueEntry);
    end;

    /// <summary>Finds the tables related to a synchronization table, as offered when adding it to the setup.</summary>
    /// <param name="ExistingSynchTableNos">The tables already in the synchronization setup.</param>
    /// <param name="RelatedTablesToAdd">Returns the related table IDs proposed for adding.</param>
    /// <param name="RelatedTablesToAddText">Returns the display text for the proposed related tables.</param>
    /// <param name="TableId">The table whose related tables are resolved.</param>
    procedure FindRelatedTables(var ExistingSynchTableNos: List of [Integer]; var RelatedTablesToAdd: List of [Integer]; var RelatedTablesToAddText: Text; TableId: Integer)
    var
        MasterDataSynchTables: Page "Master Data Synch. Tables";
    begin
        MasterDataSynchTables.FindRelatedTables(ExistingSynchTableNos, RelatedTablesToAdd, RelatedTablesToAddText, TableId);
    end;

    /// <summary>Sets the source company on Master Data Management Setup to the current company.</summary>
    procedure SetSourceCompanyToCurrent()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        MasterDataManagementSetup."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(MasterDataManagementSetup."Company Name"));
        MasterDataManagementSetup.Modify(false);
    end;

    /// <summary>Gets the integration record reference for a coupling.</summary>
    /// <param name="IntegrationTableID">The integration table ID to resolve.</param>
    /// <param name="MasterDataMgtCoupling">The coupling whose integration record is requested.</param>
    /// <param name="RecRef">Returns the resolved integration record reference.</param>
    /// <returns>True if the integration record was found; otherwise false.</returns>
    procedure GetIntegrationRecordRefByCoupling(IntegrationTableID: Integer; var MasterDataMgtCoupling: Record "Master Data Mgt. Coupling"; var RecRef: RecordRef): Boolean
    begin
        exit(MasterDataManagement.GetIntegrationRecordRef(IntegrationTableID, MasterDataMgtCoupling, RecRef));
    end;

    /// <summary>Gets the integration record reference identified by a coupling ID.</summary>
    /// <param name="IntegrationTableMapping">The integration table mapping to resolve against.</param>
    /// <param name="ID">The coupling ID to resolve.</param>
    /// <param name="RecRef">Returns the resolved integration record reference.</param>
    /// <returns>True if the integration record was found; otherwise false.</returns>
    procedure GetIntegrationRecordRefById(var IntegrationTableMapping: Record "Integration Table Mapping"; ID: Variant; var RecRef: RecordRef): Boolean
    begin
        exit(MasterDataManagement.GetIntegrationRecordRef(IntegrationTableMapping, ID, RecRef));
    end;

    /// <summary>Gets the set of modified source records for a table mapping from the configured data source.</summary>
    /// <param name="IntegrationTableMapping">The integration table mapping to read.</param>
    /// <param name="TableFilter">The source table filter to apply.</param>
    /// <param name="SourceRecordRef">Returns the record reference positioned on the modified set.</param>
    /// <returns>True if any modified records were found; otherwise false.</returns>
    procedure DataSourceGetModifiedSet(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        exit(MasterDataManagementSetup.GetDataSource().GetModifiedSet(IntegrationTableMapping, TableFilter, SourceRecordRef));
    end;

    /// <summary>Gets source records matching a UID filter from the configured data source.</summary>
    /// <param name="IntegrationTableMapping">The integration table mapping to read.</param>
    /// <param name="UidFilter">The UID filter to apply.</param>
    /// <param name="SourceRecordRef">Returns the record reference positioned on the matching set.</param>
    /// <returns>True if any matching records were found; otherwise false.</returns>
    procedure DataSourceGetByUidFilter(IntegrationTableMapping: Record "Integration Table Mapping"; UidFilter: Text; var SourceRecordRef: RecordRef): Boolean
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        exit(MasterDataManagementSetup.GetDataSource().GetByUidFilter(IntegrationTableMapping, UidFilter, SourceRecordRef));
    end;

    /// <summary>Gets a single source record by its coupling ID (SystemId as GUID or text) from the configured data source.</summary>
    /// <param name="IntegrationTableMapping">The integration table mapping to read.</param>
    /// <param name="ID">The record ID (SystemId as a GUID or its text form).</param>
    /// <param name="SourceRecordRef">Returns the record reference positioned on the found record.</param>
    /// <returns>True if the record was found; otherwise false.</returns>
    procedure DataSourceGetById(IntegrationTableMapping: Record "Integration Table Mapping"; ID: Variant; var SourceRecordRef: RecordRef): Boolean
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        exit(MasterDataManagementSetup.GetDataSource().GetById(IntegrationTableMapping, ID, SourceRecordRef));
    end;

    /// <summary>Gets source records matching a table filter from the configured data source.</summary>
    /// <param name="IntegrationTableMapping">The integration table mapping to read.</param>
    /// <param name="TableFilter">The source table filter to apply.</param>
    /// <param name="SourceRecordRef">Returns the record reference positioned on the matching set.</param>
    /// <returns>True if any matching records were found; otherwise false.</returns>
    procedure DataSourceGetByFilter(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; var SourceRecordRef: RecordRef): Boolean
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        exit(MasterDataManagementSetup.GetDataSource().GetByFilter(IntegrationTableMapping, TableFilter, SourceRecordRef));
    end;

    /// <summary>Gets the count of integration records for a table mapping.</summary>
    /// <param name="IntegrationTableMapping">The integration table mapping to count.</param>
    /// <returns>The number of integration records.</returns>
    procedure GetIntegrationRecRefCount(IntegrationTableMapping: Record "Integration Table Mapping"): Integer
    begin
        exit(MasterDataManagement.GetIntegrationRecRefCount(IntegrationTableMapping));
    end;

    /// <summary>Gets a single source record by its SystemId from the configured data source.</summary>
    /// <param name="IntegrationTableId">The integration table ID to read.</param>
    /// <param name="SystemId">The SystemId of the source record.</param>
    /// <param name="SourceRecordRef">Returns the record reference positioned on the found record.</param>
    /// <returns>True if the record was found; otherwise false.</returns>
    procedure DataSourceGetBySystemId(IntegrationTableId: Integer; SystemId: Guid; var SourceRecordRef: RecordRef): Boolean
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        exit(MasterDataManagementSetup.GetDataSource().GetBySystemId(IntegrationTableId, SystemId, SourceRecordRef));
    end;

    /// <summary>Gets a cursor-paged batch of modified source records from the cross-environment data source.</summary>
    /// <param name="IntegrationTableMapping">The integration table mapping to read.</param>
    /// <param name="TableFilter">The source table filter to apply.</param>
    /// <param name="StartCursor">The cursor to resume from; empty starts a new scan.</param>
    /// <param name="MaxPages">The maximum number of pages to fetch in this call.</param>
    /// <param name="SourceRecordRef">Returns the record reference positioned on the fetched batch.</param>
    /// <param name="EndCursor">Returns the cursor to resume from on the next call.</param>
    /// <param name="HasMore">Returns true if more records remain beyond this batch.</param>
    /// <returns>True if any records were fetched; otherwise false.</returns>
    procedure DataSourceGetModifiedBatch(IntegrationTableMapping: Record "Integration Table Mapping"; TableFilter: Text; StartCursor: Text; MaxPages: Integer; var SourceRecordRef: RecordRef; var EndCursor: Text; var HasMore: Boolean): Boolean
    var
        CrossEnvDataSource: Codeunit "MDM Cross-Env Data Source";
    begin
        exit(CrossEnvDataSource.GetModifiedBatch(IntegrationTableMapping, TableFilter, StartCursor, MaxPages, SourceRecordRef, EndCursor, HasMore));
    end;

    // Setting a Source Environment Name routes GetDataSource() to the cross-environment implementation.
    /// <summary>Sets the source environment name, routing the data source to the cross-environment implementation.</summary>
    /// <param name="EnvironmentName">The source environment name to set.</param>
    procedure SetSourceEnvironmentName(EnvironmentName: Text)
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
    begin
        MasterDataManagementSetup.Get();
        MasterDataManagementSetup."Source Environment Name" := CopyStr(EnvironmentName, 1, MaxStrLen(MasterDataManagementSetup."Source Environment Name"));
        MasterDataManagementSetup.Modify(false);
    end;

    /// <summary>Runs the cross-environment change detector once.</summary>
    procedure RunChangeDetector()
    var
        MDMCrossEnvChangeDetector: Codeunit "MDM Cross-Env Change Detector";
    begin
        MDMCrossEnvChangeDetector.DetectChanges();
    end;

    /// <summary>Validates a source environment URL against the HTTP transport's host allow-list; errors if it is not a valid Business Central endpoint.</summary>
    /// <param name="BaseUrl">The source environment base URL to validate.</param>
    procedure ValidateHttpTransportSourceHost(BaseUrl: Text)
    var
        MDMHttpSourceTransport: Codeunit "MDM Http Source Transport";
    begin
        MDMHttpSourceTransport.ValidateSourceHostUrl(BaseUrl);
    end;

    /// <summary>Unwraps the ODataV4 action envelope the HTTP transport receives, returning the inner value (or the raw body).</summary>
    /// <param name="ResponseBody">The raw response body to unwrap.</param>
    /// <returns>The inner OData value, or the body unchanged if it is not a value-envelope.</returns>
    procedure UnwrapHttpTransportODataValue(ResponseBody: Text): Text
    var
        MDMHttpSourceTransport: Codeunit "MDM Http Source Transport";
    begin
        exit(MDMHttpSourceTransport.UnwrapODataValueForTest(ResponseBody));
    end;

    /// <summary>Checks whether the inline media cache holds an entry for a record field.</summary>
    /// <param name="SystemId">The SystemId of the source record.</param>
    /// <param name="FieldNo">The field number of the media/blob field.</param>
    /// <returns>True if the cache contains the entry; otherwise false.</returns>
    procedure InlineMediaCacheContains(SystemId: Guid; FieldNo: Integer): Boolean
    var
        InlineMedia: Codeunit "MDM Inline Media";
    begin
        exit(InlineMedia.Contains(SystemId, FieldNo));
    end;

    /// <summary>Checks whether an inline media field was marked cleared (empty on the source) for destination removal.</summary>
    /// <param name="SystemId">The SystemId of the source record.</param>
    /// <param name="FieldNo">The field number of the media field.</param>
    /// <returns>True if the field was marked cleared; otherwise false.</returns>
    procedure InlineMediaIsCleared(SystemId: Guid; FieldNo: Integer): Boolean
    var
        InlineMedia: Codeunit "MDM Inline Media";
    begin
        exit(InlineMedia.IsCleared(SystemId, FieldNo));
    end;

    /// <summary>Reads the source SystemModifiedAt watermark cached during cross-environment materialization.</summary>
    /// <param name="SystemId">The SystemId of the source record.</param>
    /// <param name="ModifiedAt">Returns the cached source SystemModifiedAt.</param>
    /// <returns>True if the watermark was cached; otherwise false.</returns>
    procedure TryGetSourceWatermark(SystemId: Guid; var ModifiedAt: DateTime): Boolean
    var
        SourceWatermark: Codeunit "MDM Source Watermark";
    begin
        exit(SourceWatermark.TryGet(SystemId, ModifiedAt));
    end;

    /// <summary>Returns the registered privacy-notice ID that gates cross-environment synchronization.</summary>
    /// <returns>The privacy-notice ID code.</returns>
    procedure PrivacyNoticeId(): Code[50]
    var
        MDMPrivacyNotice: Codeunit "MDM Privacy Notice";
    begin
        exit(MDMPrivacyNotice.GetPrivacyNoticeId());
    end;

    /// <summary>Returns whether the cross-environment privacy notice is currently approved.</summary>
    /// <returns>True if the notice is approved; otherwise false.</returns>
    procedure PrivacyNoticeIsApproved(): Boolean
    var
        MDMPrivacyNotice: Codeunit "MDM Privacy Notice";
    begin
        exit(MDMPrivacyNotice.IsApproved());
    end;

    /// <summary>Runs the fail-closed transport gate; errors when the privacy notice is not approved.</summary>
    procedure PrivacyNoticeCheckApproved()
    var
        MDMPrivacyNotice: Codeunit "MDM Privacy Notice";
    begin
        MDMPrivacyNotice.CheckApproved();
    end;

    /// <summary>Removes any recorded approval for the cross-env privacy notice, resetting it to Not set.</summary>
    procedure PrivacyNoticeResetApproval()
    var
        PrivacyNoticeApproval: Record "Privacy Notice Approval";
        MDMPrivacyNotice: Codeunit "MDM Privacy Notice";
    begin
        PrivacyNoticeApproval.SetRange(ID, MDMPrivacyNotice.GetPrivacyNoticeId());
        PrivacyNoticeApproval.DeleteAll();
    end;

    /// <summary>Records approval for the cross-env privacy notice (for tests exercising the consent-gated source API).</summary>
    procedure ApproveCrossEnvPrivacyNotice()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        MDMPrivacyNotice: Codeunit "MDM Privacy Notice";
    begin
        PrivacyNotice.SetApprovalState(MDMPrivacyNotice.GetPrivacyNoticeId(), "Privacy Notice Approval State"::Agreed);
    end;

    var
        MasterDataMgtSubscribers: Codeunit "Master Data Mgt. Subscribers";
        MasterDataManagement: Codeunit "Master Data Management";
}
