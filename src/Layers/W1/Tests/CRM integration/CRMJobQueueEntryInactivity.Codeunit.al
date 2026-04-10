codeunit 139189 "CRM Job Queue Entry Inactivity"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Job Queue] [Inactivity Detection]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure T105_ActiveJobStateOnHoldWithInactivityTimeoutNonzeroPeriodIfNoRecordChangedBySync()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Active job becomes inactive for a period if the sync didn't change anything
        Initialize();
        LibraryCRMIntegration.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        // [GIVEN] the Item is coupled to the CRM Product, but unchanged.
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        // [GIVEN] Active recurring job 'ITEM-PRODUCT' is executed, "Inactivity Timeout Period" > 0
        FindJobQueueEntryForMapping(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready, 1);

        // [WHEN] Job is done and no record were modified
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job gets status "On Hold with Inactivity period"
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        // [THEN] Job gets scheduled
        JobQueueEntry.TestField("System Task ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T105b_ActiveJobStateOnHoldWithInactivityTimeoutZeroPeriodIfNoRecordChangedBySync()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        JobQueueEntry: Record "Job Queue Entry";
        NullGuid: Guid;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Active job becomes inactive if the sync didn't change anything
        Initialize();
        LibraryCRMIntegration.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        // [GIVEN] the Item is coupled to the CRM Product, but unchanged.
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        // [GIVEN] Active recurring job 'ITEM-PRODUCT' is executed, "Inactivity Timeout Period" = 0
        FindJobQueueEntryForMapping(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready, 0);

        // [WHEN] Job is done and no record were modified
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job gets status "On Hold with Inactivity Timeout"
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");

        // [THEN] Job should not be scheduled
        Clear(NullGuid);
        JobQueueEntry.TestField("System Task ID", NullGuid);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T106_ActiveJobsStaysActiveIfRecordIsChangedBySync()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Active job stays active if the run resulted in some activity.
        Initialize();
        // [GIVEN] the Item is coupled to the CRM Product.
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        // [GIVEN] the CRM product got new "Name"
        Item.Description := LibraryUtility.GenerateGUID();
        Item.Modify();
        MockRecordNeedsSync(Item.RecordId); // to avoid adding SLEEP
        // [GIVEN] Active recurring job 'ITEM-PRODUCT' is executed
        FindJobQueueEntryForMapping(JobQueueEntry, DATABASE::Item, JobQueueEntry.Status::Ready, 1);

        // [WHEN] Job is done and changes were done
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] Job stays active, Status is Ready
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Ready);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T111_InactiveJobsBecomesActiveIfRecIsChangedManually()
    var
        Item: Record Item;
        JobQueueEntry: array[2] of Record "Job Queue Entry";
        CurrDT: DateTime;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Inactive job becomes active on manual record modification.
        Initialize();
        // [GIVEN] The Item
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();
        // [GIVEN] Job 'ITEM', where Status "On Hold with Inactivity period"
        FindJobQueueEntryForMapping(JobQueueEntry[1], DATABASE::Item, JobQueueEntry[1].Status::"On Hold with Inactivity Timeout", 5);
        JobQueueEntry[1]."Last Ready State" := CurrentDateTime - 60000 * JobQueueEntry[1]."No. of Minutes between Runs";
        JobQueueEntry[1].Modify();
        // [GIVEN] Job 'CUSTOMER', where Status "On Hold with Inactivity period"
        FindJobQueueEntryForMapping(JobQueueEntry[2], DATABASE::Customer, JobQueueEntry[2].Status::"On Hold with Inactivity Timeout", 5);

        // [WHEN] Item is modified.
        CurrDT := CurrentDateTime;
        Item.Modify(); // calls COD1.OnDatabaseInsert -> COD5150.InsertUpdateIntegrationRecord

        // [THEN] Job 'ITEM' gets Status "Ready", new "Earliest Start Date/Time" is about 1 second from now
        if TaskScheduler.CanCreateTask() then begin
            JobQueueEntry[1].Find();
            JobQueueEntry[1].TestField(Status, JobQueueEntry[1].Status::Ready);
            Assert.IsTrue(
                JobQueueEntry[1]."Earliest Start Date/Time" > CurrDT, 'Start time should be shifted to future');
            VerifyDateTimeDifference(CurrentDateTime, JobQueueEntry[1]."Earliest Start Date/Time", 1);
        end;
        // [THEN] Job 'CUSTOMER' is not changed, Status is "On Hold with Inactivity period"
        JobQueueEntry[2].Find();
        JobQueueEntry[2].TestField(Status, JobQueueEntry[2].Status::"On Hold with Inactivity Timeout");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_InactiveCRMStatsJobBecomesActiveOnCompanyOpen()
    var
        CRMSynchStatus: Record "CRM Synch Status";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [UT] [CRM Account Statistics]
        // [SCENARIO] Inactive CRM Statistics job becomes active on insert of a new Dtld. Customer Ledger Entry
        Initialize();
        // [GIVEN] 'CRM Statistics' Job, with Status "On Hold with Inactivity period"
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Statistics Job");
        JobQueueEntry.FindFirst();
        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold with Inactivity Timeout";
        JobQueueEntry."System Task ID" := CreateGuid(); // As if TASKSCHEDULER defined it
        JobQueueEntry.Modify();

        // [GIVEN] "Last Update Invoice Entry No." is 72 in CRM Connection Setup, while the last detailed entry is 73
        CRMSynchStatus.UpdateLastUpdateInvoiceEntryNo();
        CRMSynchStatus."Last Update Invoice Entry No." -= 1;
        CRMSynchStatus.Modify();

        // [WHEN] Open company (run codeunit "Job Queue User Handler")
        CODEUNIT.Run(CODEUNIT::"Job Queue User Handler");

        // [THEN] 'CRM Statistics' Job gets status "Ready"
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Ready);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T122_ActiveCRMStatsJobBecomesInactiveIfNoChangesToStats()
    var
        CRMAccount: Record "CRM Account";
        CRMSynchStatus: Record "CRM Synch Status";
        Customer: Record Customer;
        IntegrationSynchJob: array[2] of Record "Integration Synch. Job";
        JobQueueEntry: Record "Job Queue Entry";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
    begin
        // [FEATURE] [UT] [CRM Account Statistics]
        // [SCENARIO] Active CRM Statistics Job becomes inactive if no statistics updated
        Initialize();
        // [GIVEN] Customer 'A' is coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] 'CRM Statistics' Job, where Status "Ready",
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Statistics Job");
        JobQueueEntry.FindFirst();
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
        JobQueueEntry.Validate("Inactivity Timeout Period", 10);
        JobQueueEntry.Modify();
        // [GIVEN] CRM Statistics job is executed once
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);
        // [GIVEN] "Last Update Invoice Entry No." is set to the last detailed entry
        CRMSynchStatus.UpdateLastUpdateInvoiceEntryNo();

        // [WHEN] Run CRM Statistics job again
        IntegrationSynchJob[1].DeleteAll();
        JobQueueEntry."System Task ID" := CreateGuid();
        JobQueueEntry.Modify();
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] the Job is updated: Status is "On Hold with Inactivity period"
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        // [THEN] CRM Synch. Log Entry for Account Statistics update, where "Unchanged" = 1
        Assert.RecordCount(IntegrationSynchJob[1], 2);
        IntegrationSynchJob[1].SetRange(Message, CRMStatisticsJob.GetAccStatsUpdateFinalMessage());
        IntegrationSynchJob[1].FindFirst();
        IntegrationSynchJob[1].TestField(Unchanged, 0);
        IntegrationSynchJob[1].TestField(Inserted, 0);
        // [THEN] CRM Synch. Log Entry for Invoice Status update, where "Modified" = 0
        IntegrationSynchJob[2].SetRange(Message, CRMStatisticsJob.GetInvStatusUpdateFinalMessage());
        IntegrationSynchJob[2].FindFirst();
        IntegrationSynchJob[2].TestField(Modified, 0);
        IntegrationSynchJob[2].TestField(Inserted, 0);
    end;

    local procedure Initialize()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMOrganization: Record "CRM Organization";
        User: Record User;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        LibraryPermissions: Codeunit "Library - Permissions";
        ClientSecret: Text;
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.InitializeCRMSynchStatus();
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMOrganization.FindFirst();
        CRMConnectionSetup.BaseCurrencyId := CRMOrganization.BaseCurrencyId;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CRMConnectionSetup."Unit Group Mapping Enabled" := false;
        CRMConnectionSetup.Modify();
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        User.SetRange("User Name", UserId());
        if User.IsEmpty() then
            LibraryPermissions.CreateUser(User, CopyStr(UserId(), 1, 50), true);
    end;

    local procedure FindJobQueueEntryForMapping(var JobQueueEntry: Record "Job Queue Entry"; TableNo: Integer; JobStatus: Option; InactivityPeriod: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableNo);
        IntegrationTableMapping.FindFirst();
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := CurrentDateTime - 10000L;
        IntegrationTableMapping.Modify();
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
        JobQueueEntry.FindFirst();
        JobQueueEntry.Status := JobStatus;
        JobQueueEntry."Inactivity Timeout Period" := InactivityPeriod;
        JobQueueEntry."System Task ID" := CreateGuid(); // As if TASKSCHEDULER defined it
        JobQueueEntry.Modify();
    end;

    local procedure MockRecordNeedsSync(RecID: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(RecID);
        Clear(CRMIntegrationRecord."Last Synch. Modified On");
        Clear(CRMIntegrationRecord."Last Synch. CRM Modified On");
        CRMIntegrationRecord.Modify();
    end;

    local procedure VerifyDateTimeDifference(DateTime1: DateTime; DateTime2: DateTime; ExpectedDiffInSeconds: Integer)
    var
        DiffInMilliseconds: Integer;
    begin
        DiffInMilliseconds := DateTime2 - DateTime1;
        Assert.AreEqual(ExpectedDiffInSeconds, Round(DiffInMilliseconds / 1000, 1), 'Expected shift in time.');
    end;
}
