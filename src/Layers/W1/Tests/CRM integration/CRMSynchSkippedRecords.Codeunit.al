codeunit 139186 "CRM Synch. Skipped Records"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Skipped Record]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        SyncStartedMsg: Label 'The synchronization has been scheduled';
        SyncRestoredMsg: Label 'The record has been restored for synchronization.';
        SyncMultipleRestoredMsg: Label '2 records have been restored for synchronization.';
        SyncRestoredAllMsg: Label '3 records have been restored for synchronization.';
        MustBeCoupledErr: Label 'Salesperson Code %1 must be coupled to a record in Dataverse.', Comment = '%1 - salespersom code';
        NotFoundErr: Label 'could not be found in Salesperson/Purchaser.';
        SkippedRecMsg: Label 'The record will be skipped for further synchronization';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SyncNowSkippedMsg: Label 'The synchronization has been skipped. The Customer record is marked as skipped.';
        LibraryUtility: Codeunit "Library - Utility";
        WantToSynchronizeQst: Label 'Are you sure you want to synchronize?';
        DataWillBeOverriddenMsg: Label 'data on one of the records will be lost and replaced with data from the other record';
        UnexpectedNotificationIdErr: Label 'Unexected notification Id.';
        DeleteAccountPrivilegeErr: Label 'Principal user is missing prvDeleteAccount privilege.';
        NoPermissionToDeleteInCRMErr: Label 'You do not have permission to delete entities in Dynamics 365 Sales.';
        IntTableMappingNotFoundErr: Label 'No Integration Table Mapping was found for table';

    [Test]
    [HandlerFunctions('PickDirectionToCRMHandler,SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T100_SynchFailedOnceDoesNotMakeSkippedRec()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
    begin
        // [SCENARIO] After synch of a coupled record has failed 1 time the job continues to sync the record
        Init();
        // [GIVEN] The Job runs sync for Customer '10000'
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        DecoupleSalesperson(Customer."Salesperson Code", CRMIntegrationRecord);
        MockLastCRMSyncDT(Customer.RecordId);
        // [GIVEN] Synch has failed due to not coupled Salesperson "PS"
        FailedSynchCustomer(Customer, StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"));

        // [GIVEN] Salesperson "PS" is coupled to a CRM User
        CRMIntegrationRecord.Insert();

        // [WHEN] Run the synch Job for Customer '10000'
        GoodSynchCustomer(Customer);
        VerifyNotificationMessage(SyncStartedMsg);

        // [THEN] The job log, where "Failed" = 0, "Modified" = 1
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Success);
        // [THEN] Customer '10000' is not in the "CRM Skipped Records" list
        CRMIntegrationRecord.TestField(Skipped, false);
    end;

    [Test]
    [HandlerFunctions('PickDirectionToCRMHandler,SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T101_SynchFailedDiffDoesNotMakeSkippedRec()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
    begin
        // [SCENARIO] After synch of a coupled record has failed 2 times in a row for different reason, the record is not skipped
        Init();
        // [GIVEN] The Customer '10000' synchronization has failed, because the Salesperson "PS" is not coupled.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        DecoupleSalesperson(Customer."Salesperson Code", CRMIntegrationRecord);
        MockLastCRMSyncDT(Customer.RecordId);
        FailedSynchCustomer(Customer, StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"));
        VerifyNotificationMessage(SyncStartedMsg);

        // [GIVEN] The Customer '10000' gets "Salesperson Code" = 'XX', not coupled to CRM System User.
        Customer."Salesperson Code" := LibraryUtility.GenerateGUID();
        Customer.Modify();

        // [WHEN] The Customer '10000' synchronization has failed, because the Salesperson "XX" is not coupled.
        FailedSynchCustomer(Customer, StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"));
        VerifyNotificationMessage(SyncStartedMsg);

        // [THEN] The job log, where "Skipped" = 0, "Failed" = 1, "Modified" = 0
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Failure);
        // [THEN] The Customer '10000' is NOT in the skipped record list
        CRMIntegrationRecord.TestField(Skipped, false);
    end;

    [Test]
    [HandlerFunctions('PickDirectionToCRMHandler,SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T105_SynchFailedTwiceMakesSkippedRec()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
    begin
        // [SCENARIO] After synch of a coupled record has failed 2 times in a row for the same reason:
        // [SCENARIO] the coupled record is added to skipped records list
        Init();
        // [GIVEN] The Job runs sync for Customer '10000' twice:
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        DecoupleSalesperson(Customer."Salesperson Code", CRMIntegrationRecord);
        MockLastCRMSyncDT(Customer.RecordId);
        // [GIVEN] Synch has failed the first time due to not coupled Salesperson "PS"
        FailedSynchCustomer(Customer, StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"));
        VerifyNotificationMessage(SyncStartedMsg);

        // [WHEN] Synch has failed the second time due to not coupled Salesperson "PS" and then skipped
        FailedSkippedSkippedSynchCustomer(Customer, StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"));
        VerifyNotificationMessage(SyncStartedMsg);

        // [THEN] The job log, where "Failed" = 1, "Modified" = 0
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Failure);
        // [THEN] Customer '10000' is in the "CRM Skipped Records" list
        CRMIntegrationRecord.TestField(Skipped, true);
    end;

    [Test]
    [HandlerFunctions('PickDirectionToCRMHandler,SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T106_SkippedRecIsSkippedByNormaljob()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
    begin
        // [SCENARIO] The skipped record is not handled by a synch job if ran normally
        Init();
        // [GIVEN] The Customer '10000' is coupled, but is in the skipped record list.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Customer.RecordId, CRMAccount.RecordId,
          StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"), CurrentDateTime, true);

        // [GIVEN] The Salesperson "PS" is still not coupled
        DecoupleSalesperson(Customer."Salesperson Code", CRMIntegrationRecord);

        // [WHEN] Run the "Synchronize" action on Customer
        SkippedSynchCustomer(Customer);

        // [THEN] Notification: "The synchronization has been skipped."
        VerifyNotificationMessage(SyncNowSkippedMsg);
        // [THEN] The Customer '10000' is in the skipped record list
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord.TestField(Skipped, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T107_FailedOnceRecordShouldBePickedForSyncUnchanged()
    var
        CRMAccount: array[2] of Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: array[2] of Record Customer;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntryID: Guid;
    begin
        // [SCENARIO] The record failed once, even unchanged after the first sync, should be picked up for the second sync, making it "Skipped"
        Init();
        // [GIVEN] The Customers '10000', '20000' are coupled
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[1], CRMAccount[1]);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[2], CRMAccount[2]);
        // [GIVEN] IntegrationTableMapping 'CUSTOMER' has Modified On Filters set
        Sleep(500);
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := CurrentDateTime();
        Sleep(500);
        IntegrationTableMapping."Synch. Modified On Filter" := CurrentDateTime();
        IntegrationTableMapping.Modify();

        // [GIVEN] Both Customer 10000 and CRM Account 10000 are modified after the last synch. job.
        Sleep(1000);
        Customer[1]."E-Mail" := 'test@test.com';
        Customer[1].Modify();
        CRMAccount[1].ModifiedOn := CurrentDateTime();
        CRMAccount[1].Modify();
        // [GIVEN] Customer 20000 is modified on CRM side only
        LibraryCRMIntegration.MockLastSyncModifiedOn(Customer[2].RecordId, IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." - 250);
        CRMAccount[2].ModifiedOn := IntegrationTableMapping."Synch. Modified On Filter" + 1500;
        CRMAccount[2].Modify();

        // [GIVEN] Run sync job for customers
        JobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);
        // [GIVEN] Sync Job: one record is failed in both directions, one record is modified.
        Clear(IntegrationSynchJob);
        IntegrationSynchJob.Failed := 2;
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Unchanged := 0;
        VerifyIntSynchJobs(JobQueueEntryID, IntegrationSynchJob);

        // [GIVEN] Customer 10000 is not skipped
        CRMIntegrationRecord.FindByRecordID(Customer[1].RecordId);
        CRMIntegrationRecord.TestField(Skipped, false);

        // [WHEN] Run sync job for customers, again
        IntegrationTableMapping.Get('CUSTOMER');
        JobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);

        // [THEN] Customer 10000 is skipped now
        CRMIntegrationRecord.FindByRecordID(Customer[1].RecordId);
        CRMIntegrationRecord.TestField(Skipped, true);
        // [THEN] Customer 20000 is NOT skipped
        CRMIntegrationRecord.FindByRecordID(Customer[2].RecordId);
        CRMIntegrationRecord.TestField(Skipped, false);

        // [THEN] Sync Job: one record is skipped, the second - unchanged
        Clear(IntegrationSynchJob);
        IntegrationSynchJob.Skipped := 2;
        IntegrationSynchJob.Failed := 0;
        IntegrationSynchJob.Unchanged := 2;
        VerifyIntSynchJobs(JobQueueEntryID, IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T108_SkippedRecDoesNotGetRestoredByNewFailure()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecRef: RecordRef;
        JobID: array[3] of Guid;
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Record that gets Skipped in one direction should not be restored by a new failure in other direction
        // [GIVEN] Sync failed in both directions once
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        JobID[1] :=
          LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
            Customer.RecordId, CRMAccount.RecordId, '1', CurrentDateTime, false);
        // [GIVEN] CRM Integration Record is getting skipped in direction NAV-to-CRM
        JobID[2] :=
          LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
            CRMAccount.AccountId, CRMAccount.RecordId, Customer.RecordId, '2', CurrentDateTime, true);
        // [WHEN] A unique failure happens during Syncronization in direction CRM-to-NAV
        JobID[3] :=
          LibraryCRMIntegration.MockSyncJobError(
            Customer.RecordId, CRMAccount.RecordId, '3', CurrentDateTime);
        RecRef.GetTable(Customer);
        CRMIntegrationRecord.SetLastSynchResultFailed(RecRef, true, JobID[3]);
        // [THEN] CRM Integration Record, where "Skipped" is 'Yes'
        CRMIntegrationRecord.TestField(Skipped, true);
    end;

    [Test]
    [HandlerFunctions('SyncNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T110_RestoreOfOneSkippedRecRemovesSkippedMarker()
    var
        CRMAccount: array[2] of Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: array[2] of Record Customer;
        i: Integer;
    begin
        // [SCENARIO] Action "Restore" should remove "Skipped" marker from one selected skipped record
        Init();
        // [GIVEN] The Customers '10000' and '20000' are coupled, but are in the skipped records list.
        for i := 1 to 2 do begin
            LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[i], CRMAccount[i]);
            LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
              Customer[i].RecordId, CRMAccount[i].RecordId,
              StrSubstNo(MustBeCoupledErr, Customer[i]."Salesperson Code"), CurrentDateTime, true);
        end;
        // [WHEN] Run the "Restore" action on the Customer '10000'
        RestoreSkippedCustomer(Customer[1]);

        // [THEN] Notification: 'The record has been restored for synchronization.'
        VerifyNotificationMessage(SyncRestoredMsg);
        // [THEN] The Customer '10000' is NOT in the skipped record list
        CRMIntegrationRecord.FindByRecordID(Customer[1].RecordId);
        CRMIntegrationRecord.TestField(Skipped, false);
        // [THEN] The Customer '20000' is in the skipped record list
        CRMIntegrationRecord.FindByRecordID(Customer[2].RecordId);
        CRMIntegrationRecord.TestField(Skipped, true);
    end;

    [Test]
    [HandlerFunctions('SyncNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T111_RestoreOfTwoSelectedLinesRestoresTwoRecs()
    var
        CRMAccount: array[3] of Record "CRM Account";
        Customer: array[3] of Record Customer;
        SelectedCRMIntegrationRecord: Record "CRM Integration Record";
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Restore" should remove "Skipped" marker from multiple selected skipped records
        Init();
        // [GIVEN] Three Customers 'A', 'B', and 'C' are in the list
        for i := 1 to 3 do begin
            LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[i], CRMAccount[i]);
            LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
              Customer[i].RecordId, CRMAccount[i].RecordId,
              StrSubstNo(MustBeCoupledErr, Customer[i]."Salesperson Code"), CurrentDateTime, true);
            if i in [1, 3] then
                MarkSelectedRecord(SelectedCRMIntegrationRecord, Customer[i].RecordId);
        end;
        // [GIVEN] Selected Customers 'A' and 'C'
        SelectedCRMIntegrationRecord.MarkedOnly(true);

        // [WHEN] "Restore" action
        RestoreSkippedRecords(SelectedCRMIntegrationRecord);

        // [THEN] Notification: '2 records have been restored for synchronization.'
        VerifyNotificationMessage(SyncMultipleRestoredMsg);
    end;

    [Test]
    [HandlerFunctions('SyncNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T112_RestoreOfOneSkippedRecDisablesActions()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Actions should become disabled after "Restore" removes the last skipped record
        Init();
        // [GIVEN] The Customer '10000' is coupled, but is in the skipped records list.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Customer.RecordId, CRMAccount.RecordId,
          StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"), CurrentDateTime, true);
        // [GIVEN] Open "CRM Skipped Records" page, where all actions are enabled
        CRMSkippedRecords.OpenEdit();
        Assert.IsTrue(CRMSkippedRecords.First(), 'the lines must be in the list');
        VerifyPagesActions(CRMSkippedRecords, true);
        // [WHEN] Run the "Restore" action on the Customer '10000'
        CRMSkippedRecords.Restore.Invoke();

        // [THEN] Notification: 'The record has been restored for synchronization.'
        VerifyNotificationMessage(SyncRestoredMsg);
        // [THEN] No records in the page, all actions are disabled
        Assert.IsFalse(CRMSkippedRecords.First(), 'the list must be blank');
        VerifyPagesActions(CRMSkippedRecords, false);
    end;

    [Test]
    [HandlerFunctions('PickDirectionToCRMHandler,SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T115_RestoredRecIsNotSkippedIfSynchSuccessful()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
    begin
        // [SCENARIO] The restored skipped record should not get skipped if synchronized successfully
        Init();
        // [GIVEN] The Customer '10000' is coupled, but is in the skipped records list.
        // [GIVEN] The Salesperson "PS" is coupled
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Customer.RecordId, CRMAccount.RecordId,
          StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"), CurrentDateTime, true);

        // [GIVEN] Run the "Restore" action on the "CRM Skipped Records" list
        RestoreSkippedCustomer(Customer);
        // [GIVEN] Notification: 'The record has been restored for synchronization.'
        VerifyNotificationMessage(SyncRestoredMsg);

        // [WHEN] Run the synch Job for Customer '10000'
        GoodSynchCustomer(Customer);
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'wrong direction.'); // by PickDirectionToCRMHandler
        VerifyNotificationMessage(SyncStartedMsg);

        // [THEN] The job log, where "Failed" = 0, "Modified" = 1
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Success);
        // [THEN] Customer '10000' is not in the "CRM Skipped Records" list
        CRMIntegrationRecord.TestField(Skipped, false);
    end;

    [Test]
    [HandlerFunctions('SyncNotificationHandler,RecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T116_RestoreAllRestoresAllRecs()
    var
        CRMAccount: array[3] of Record "CRM Account";
        Customer: array[3] of Record Customer;
        SelectedCRMIntegrationRecord: Record "CRM Integration Record";
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Retry all" should remove "Skipped" marker from all skipped records
        Init();
        // [GIVEN] Three Customers 'A', 'B', and 'C' are in the list
        for i := 1 to 3 do begin
            LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[i], CRMAccount[i]);
            LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
              Customer[i].RecordId, CRMAccount[i].RecordId,
              StrSubstNo(MustBeCoupledErr, Customer[i]."Salesperson Code"), CurrentDateTime, true);
            if i in [1, 3] then
                MarkSelectedRecord(SelectedCRMIntegrationRecord, Customer[i].RecordId);
        end;

        // [WHEN] "Retry All" action
        RestoreSkippedRecords();

        // [THEN] Notification: '3 records have been restored for synchronization.'
        VerifyNotificationMessage(SyncRestoredAllMsg);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T120_SynchronizeForcesSyncOfSelectedSkippedRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSystemuser: array[2] of Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Synchronize" action schedules synch. jobs for a selected record.
        Init();
        // [GIVEN] Coupled Salespersons 'X' and 'Y' are skipped for synchronization.
        MockSkippedSalespersons(SalespersonPurchaser, CRMSystemuser);
        // [GIVEN] Open "CRM Skipped Records" page on Salesperson 'X'
        CRMSkippedRecords.OpenEdit();
        CRMSkippedRecords.FindFirstField(Description, SalespersonPurchaser[1].Name);

        // [WHEN] run action "Synchronize"
        CRMSkippedRecords.CRMSynchronizeNow.Invoke();
        // execute the job
        CRMSystemuser[1].SetRange(SystemUserId, CRMSystemuser[1].SystemUserId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::"CRM Systemuser", CRMSystemuser[1].GetView(), IntegrationTableMapping);

        // [THEN] Confirmation asked: "Do you want to synchronize?"
        Assert.ExpectedMessage(WantToSynchronizeQst, LibraryVariableStorage.DequeueText());
        // [THEN] Notification "Synchronization has been scheduled"
        VerifyNotificationMessage(SyncStartedMsg);
        // [THEN] The synchronization job is executed and Salesperson 'X' became not skipped.
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMSystemuser[1].SystemUserId), 'should be coupled.');
        CRMIntegrationRecord.TestField(Skipped, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PickDirectionToCRMHandler,SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T121_SynchronizeOfBidirectionalTableRequestsDirection()
    var
        Customer: array[2] of Record Customer;
        CRMAccount: array[2] of Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Synchronize" action requests direction and schedules synch. job for the selected record.
        Init();
        // [GIVEN] Coupled Customers '10000' and '20000' are skipped for synchronization.
        MockSkippedCustomers(Customer, CRMAccount, 2);
        // [GIVEN] Open "CRM Skipped Records" page
        CRMSkippedRecords.OpenEdit();
        CRMSkippedRecords.FindFirstField(Description, Customer[1]."No.");

        // [WHEN] run action "Synchronize"
        CRMSkippedRecords.CRMSynchronizeNow.Invoke();
        // execute the job
        Customer[1].SetRange(SystemId, Customer[1].SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Customer, Customer[1].GetView(), IntegrationTableMapping);

        // [THEN] Message is shown: "data... will be lost and replaced..."
        Assert.ExpectedMessage(DataWillBeOverriddenMsg, LibraryVariableStorage.DequeueText()); // by MessageHandler
        // [THEN] Menu for picking direction, where Direction "To Integration Table" is picked
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'wrong direction.'); // by PickDirectionToCRMHandler
        // [THEN] Notification "Synchronization has been scheduled"
        VerifyNotificationMessage(SyncStartedMsg);
        // [THEN] CRM Account '10000' gets overridden by Customer '10000'
        CRMAccount[1].Find();
        CRMAccount[1].TestField(Name, Customer[1].Name);
        // [THEN] Customer '10000' is not skipped
        CRMIntegrationRecord.FindByRecordID(Customer[1].RecordId);
        CRMIntegrationRecord.TestField(Skipped, false);
        // [THEN] CRM Account '20000' and Customer '20000' are not synched
        CRMIntegrationRecord.FindByRecordID(Customer[2].RecordId);
        CRMIntegrationRecord.TestField(Skipped, true);
        Assert.AreNotEqual(CRMAccount[2].Name, Customer[2].Name, 'Names should be different');
    end;

    [Test]
    [HandlerFunctions('PickDirectionToCRMHandler,SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T122_SynchronizeMultipleBidirectionalRecords()
    var
        Customer: array[2] of Record Customer;
        CRMAccount: array[2] of Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSystemuser: array[2] of Record "CRM Systemuser";
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        SelectedCRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] "Synchronize" action requests direction once and schedules synch. job for the selected records.
        Init();
        // [GIVEN] Coupled Salespersons 'X' and 'Y' are skipped for synchronization.
        MockSkippedSalespersons(SalespersonPurchaser, CRMSystemuser);
        // [GIVEN] Coupled Customers '10000' and '20000' are skipped for synchronization.
        MockSkippedCustomers(Customer, CRMAccount, 2);
        // [GIVEN] Select both customers and Salesperson 'X'
        MarkSelectedRecord(SelectedCRMIntegrationRecord, Customer[1].RecordId);
        MarkSelectedRecord(SelectedCRMIntegrationRecord, Customer[2].RecordId);
        MarkSelectedRecord(SelectedCRMIntegrationRecord, SalespersonPurchaser[2].RecordId);
        SelectedCRMIntegrationRecord.MarkedOnly(true);
        Assert.AreEqual(3, SelectedCRMIntegrationRecord.Count, 'number of selected records');
        // [GIVEN] Only base integration table mappings, not child mappings
        IntegrationTableMapping.SetFilter("Table ID", '%1|%2', Database::Customer, Database::"Salesperson/Purchaser");
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        IntegrationTableMapping.DeleteAll();

        // [WHEN] run action "Synchronize"
        CRMIntegrationManagement.UpdateMultipleNow(SelectedCRMIntegrationRecord);

        // [THEN] Menu for picking direction, where Direction "To Integration Table" is picked
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'wrong direction.'); // by PickDirectionToCRMHandler

        // [THEN] Notification "Synchronization has been scheduled"
        VerifyNotificationMessage(SyncStartedMsg);

        // [THEN] 1 job is created and executed for Customer table with Direction "To Integration Table"
        IntegrationTableMapping.SetRange("Table ID", Database::Customer);
        IntegrationTableMapping.SetRange(Direction, IntegrationTableMapping.Direction::ToIntegrationTable);
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Table mapping #1 is not found');
        LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);

        // [THEN] Both Customers are not skipped anymore
        CRMIntegrationRecord.FindByRecordID(Customer[1].RecordId);
        Assert.IsFalse(CRMIntegrationRecord.Skipped, 'Customer #1 should not be skipped');
        CRMIntegrationRecord.FindByRecordID(Customer[2].RecordId);
        Assert.IsFalse(CRMIntegrationRecord.Skipped, 'Customer #2 should not be skipped');

        // [THEN] 1 job is created and executed for Salesperson 'X' with Direction "From Integration Table"
        IntegrationTableMapping.SetRange("Table ID", Database::"Salesperson/Purchaser");
        IntegrationTableMapping.SetRange(Direction, IntegrationTableMapping.Direction::FromIntegrationTable);
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Table mapping #2 is not found');
        LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);

        // [THEN] Salesperson 'X' is not skipped, Salesperson 'Y' is skipped
        CRMIntegrationRecord.FindByCRMID(CRMSystemuser[1].SystemUserId);
        Assert.IsTrue(CRMIntegrationRecord.Skipped, 'CRMSystemuser #1 should be skipped');
        CRMIntegrationRecord.FindByCRMID(CRMSystemuser[2].SystemUserId);
        Assert.IsFalse(CRMIntegrationRecord.Skipped, 'CRMSystemuser #2 should not be skipped');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T123_SetSelectionFilterShouldExcludeDeletedCouplings()
    var
        Customer: array[3] of Record Customer;
        CRMAccount: array[3] of Record "CRM Account";
        CRMSystemuser: array[2] of Record "CRM Systemuser";
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        SelectedCRMIntegrationRecord: Record "CRM Integration Record";
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        // [FEATURE] [UT] [Deleted Couplings]
        // [SCENARIO] SetSelectionFilter() should skip buffer records with broken couples.
        Init();
        // [GIVEN] Coupled Salespersons 'X' and 'Y' are skipped for synchronization.
        MockSkippedSalespersons(SalespersonPurchaser, CRMSystemuser);
        // [GIVEN] Coupled Customers '10000' and '20000' are skipped for synchronization
        MockSkippedCustomers(Customer, CRMAccount, 3);
        // [GIVEN] Customer '30000' is deleted.
        Customer[3].Delete();
        // [GIVEN] Select all 3 Customers and 2 Salespersons
        MockSelectingAllSkippedLines(TempCRMSynchConflictBuffer, 5);

        // [WHEN] run SetSelectionFilter()
        TempCRMSynchConflictBuffer.SetSelectionFilter(SelectedCRMIntegrationRecord); // mock "Synchronize" action behavior

        // [THEN] 4 records are selected, deleted Customer '30000' is excluded
        Assert.AreEqual(4, SelectedCRMIntegrationRecord.Count, 'number of selected records');
        SelectedCRMIntegrationRecord.SetRange("CRM ID", CRMAccount[3].AccountId);
        Assert.IsTrue(SelectedCRMIntegrationRecord.IsEmpty, 'deleted customer should not be seletced');
    end;

    [Test]
    [HandlerFunctions('CRMCouplingRecordModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T125_CoupleActionOpensCouplingRecordPage()
    var
        CRMSystemuser: array[2] of Record "CRM Systemuser";
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Couple" action opens "CRM Coupling Record" page.
        Init();
        // [GIVEN] Coupled Salespersons 'X' and 'Y' are skipped for synchronization.
        MockSkippedSalespersons(SalespersonPurchaser, CRMSystemuser);
        // [GIVEN] Open "CRM Skipped Records" page, where Salesperson 'Y' is selected
        CRMSkippedRecords.OpenEdit();
        CRMSkippedRecords.FindFirstField(Description, SalespersonPurchaser[2].Name);

        // [WHEN] Run action "Set Up Coupling"
        CRMSkippedRecords.ManageCRMCoupling.Invoke();
        // [THEN] "CRM Coupling Record" page is open on Salesperson 'Y'
        Assert.AreEqual(SalespersonPurchaser[2].Name, LibraryVariableStorage.DequeueText(), 'wrong NAV name for coupling.'); // by CRMCouplingRecordModalPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T126_DeleteCouplingActionDeletesCouplingRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: array[2] of Record "CRM Product";
        Item: array[2] of Record Item;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the selected record
        Init();
        // [GIVEN] Coupled Items 'X' and 'Y' are skipped for synchronization.
        MockSkippedItem(Item[1], CRMProduct[1]);
        MockSkippedItem(Item[2], CRMProduct[2]);
        // [GIVEN] Open "CRM Skipped Records" page, where 'X' is selected
        CRMSkippedRecords.OpenEdit();
        CRMSkippedRecords.FindFirstField(Description, Item[1]."No.");

        // [WHEN] run action "Delete Coupling"
        CRMSkippedRecords.DeleteCRMCoupling.Invoke();
        VerifyUncouplingJobQueueEntryExists();
        SimulateUncouplingJobsExecution();
        // [THEN] the Item 'X' is not coupled and not in the list of skipped records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item[1].RecordId), 'the coupling should be removed.');
        Assert.IsFalse(
          CRMSkippedRecords.FindFirstField(Description, Item[1]."No."), 'the record should dissapear from the page');
        // [THEN] the remaining Item 'Y' is still in the list
        Assert.IsTrue(
          CRMSkippedRecords.FindFirstField(Description, Item[2]."No."), 'the second record should be in the list');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T127_DeleteCouplingActionDeletesCouplingForRemovedNAVRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: array[2] of Record "CRM Product";
        Item: array[2] of Record Item;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [Deleted Couplings]
        // [SCENARIO] "Delete Coupling" action removes coupling of the deleted NAV record
        Init();
        // [GIVEN] Coupled Items 'X' and 'Y' are skipped for synchronization.
        MockSkippedItem(Item[1], CRMProduct[1]);
        MockSkippedItem(Item[2], CRMProduct[2]);
        // [GIVEN] Item 'X' has been deleted
        Item[1].Delete();

        // [GIVEN] Open "CRM Skipped Records" page, where 'X' is selected
        CRMSkippedRecords.OpenEdit();
        CRMSkippedRecords.FindFirstField("Int. Description", CRMProduct[1].ProductNumber);

        // [WHEN] run action "Delete Coupling"
        CRMSkippedRecords.DeleteCRMCoupling.Invoke();
        VerifyUncouplingJobQueueEntryExists();
        SimulateUncouplingJobsExecution();
        // [THEN] the Salesperson 'X' is not coupled and not in the list of skipped records
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMProduct[1].ProductId), 'the coupling should be removed.');
        Assert.IsFalse(
        CRMSkippedRecords.FindFirstField(Description, Item[1]."No."), 'the record should dissapear from the page');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T130_SkippedRecsListOpenFromCRMConnectionSetup()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        DummyEmptyRecID: RecordID;
        FailedOn: array[2] of DateTime;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] User can open the list of "CRM Skipped Records" by clicking on action on CRM Connection Setup page
        Init();

        // [GIVEN] Customer 'Cannon' is skipped with Error message 'Y', failed on 'T1'
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        FailedOn[1] := CurrentDateTime - 1000;
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Customer.RecordId, CRMAccount.RecordId,
          StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"), FailedOn[1], true);
        // [GIVEN] Salesperson 'RS' is skipped with Error message 'X', failed on 'T2'
        SalespersonPurchaser.Get(Customer."Salesperson Code");
        FailedOn[2] := CurrentDateTime;
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          SalespersonPurchaser.RecordId, DummyEmptyRecID, NotFoundErr, FailedOn[2], true);

        // [GIVEN] Open CRM Connection Setup page
        CRMConnectionSetupPage.OpenView();

        // [WHEN] Run the promoted action "Skipped Records"
        Assert.IsTrue(CRMConnectionSetupPage.SkippedSynchRecords.Enabled(), 'SkippedSynchRecords is disabled');
        CRMSkippedRecords.Trap();
        CRMConnectionSetupPage.SkippedSynchRecords.Invoke();

        // [THEN] The modal "CRM Skipped Records" list page is open, where are two records:
        // [THEN] Salesperson 'RS' has error message 'X', "Failed On" is 'T2'
        CRMSkippedRecords.First();
        CRMSkippedRecords."Table Name".AssertEquals(SalespersonPurchaser.TableCaption());
        CRMSkippedRecords.Description.AssertEquals(Customer."Salesperson Code");
        CRMSkippedRecords."Error Message".AssertEquals(NotFoundErr);
        CRMSkippedRecords."Failed On".AssertEquals(FailedOn[2]);
        CRMSkippedRecords.Next();
        // [THEN]  Customer 'Canon' has error message 'Y', "Failed On" is 'T1'
        CRMSkippedRecords."Table Name".AssertEquals(Customer.TableCaption());
        CRMSkippedRecords.Description.AssertEquals(Customer."No.");
        CRMSkippedRecords."Error Message".AssertEquals(StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"));
        CRMSkippedRecords."Failed On".AssertEquals(FailedOn[1]);
        Assert.IsFalse(CRMSkippedRecords.Next(), 'Customer record should be the last.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T131_ShowSynchLogOpensLogForCurrentRec()
    var
        CRMAccount: array[3] of Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer";
        Customer: array[3] of Record Customer;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        IntegrationSynchJobListPage: TestPage "Integration Synch. Job List";
        JobID: array[3] of Guid;
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Action "Show Synchronization Log" should open the log page for the current skipped record
        Init();
        // [GIVEN] Three Customers 'A', 'B', and 'C' are in the list
        for i := 1 to 3 do begin
            LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[i], CRMAccount[i]);
            JobID[i] :=
              LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
                Customer[i].RecordId, CRMAccount[i].RecordId,
                StrSubstNo(MustBeCoupledErr, Customer[i]."Salesperson Code"), CurrentDateTime, true);
            if i = 2 then
                CRMIntegrationRecord.FindByRecordID(Customer[i].RecordId);
        end;
        // [GIVEN] Cursor points to Customer 'B'
        CRMSkippedRecords.OpenView();
        CRMSynchConflictBuffer.InitFromCRMIntegrationRecord(CRMIntegrationRecord);
        CRMSkippedRecords.FindFirstField(Description, CRMSynchConflictBuffer.Description);

        // [WHEN] "Show Synchronization Log" action
        IntegrationSynchJobListPage.Trap();
        CRMSkippedRecords.ShowLog.Invoke();
        // [THEN] Open page "Synchronization Log" for Customer 'B'
        Assert.IsTrue(IntegrationSynchJobListPage.GotoKey(JobID[2]), 'Expected job is not in the list.');
        Assert.IsFalse(IntegrationSynchJobListPage.Previous(), 'Expected job is not the first rec.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T132_ShowSynchLogIsNotOpenLogIfIntegrationRecNotFound()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        DummyRecID: RecordID;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 261734] ShowLog() should not open the log page if the record is not initialized
        Init();
        Clear(DummyRecID);
        // [WHEN] ShowLog() for RecordID, where TableNo = 0
        asserterror CRMIntegrationManagement.ShowLog(DummyRecID);
        // [THEN] Error: 'No Integration Table Mapping was found for table .'
        Assert.ExpectedError(IntTableMappingNotFoundErr);
    end;

    [Test]
    [HandlerFunctions('ItemCardHandler,SkippedNotificationHandler,SkippedRecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T135_DrillDownOnDescriptionOpensCardPage()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Drill down on skipped Item "Description" opens Item Card page.
        Init();
        // [GIVEN] Item 'A' coupled to CRM Product, skipped for synchronization
        MockSkippedItem(Item, CRMProduct);
        // [GIVEN] Open "CRM Skipped Records" page
        CRMSkippedRecords.OpenEdit();

        // [WHEN] Drill down on "Description" value
        CRMSkippedRecords.Description.DrillDown();

        // [THEN] Item card is open on Item 'A'
        Assert.AreEqual(Item."No.", LibraryVariableStorage.DequeueText(), 'Item No. on the card');
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure T136_DrillDownOnIntDescriptionOpensHyperlink()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        Link: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Drill down on skipped Item "Int. Description" opens Product's hyperlink.
        Init();
        // [GIVEN] Item 'A' coupled to CRM Product, skipped for synchronization
        MockSkippedItem(Item, CRMProduct);
        // [GIVEN] Open "CRM Skipped Records" page
        CRMSkippedRecords.OpenEdit();

        // [WHEN] Drill down on "Int. Description" value
        CRMSkippedRecords."Int. Description".DrillDown();

        // [THEN] Product 'A' link is open
        Link := LibraryVariableStorage.DequeueText(); // from HyperlinkHandler
        Assert.ExpectedMessage(Format(CRMProduct.ProductId), Link);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T137_ErrorIsBlankIfJobEntryDoesNotExist()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 278479] "Error Message" is blank in "CRM Skipped Records" page, if the failed job is removed.
        Init();
        // [GIVEN] Item 'A' coupled to CRM Product, skipped for synchronization
        MockSkippedItem(Item, CRMProduct);
        IntegrationSynchJob.Get(
          LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
            Item.RecordId, CRMProduct.RecordId, 'Error', CurrentDateTime, true));
        // [GIVEN] Failed Job Entry is deleted
        IntegrationSynchJob.DeleteAll(true);
        // [WHEN] Open "CRM Skipped Records" page
        CRMSkippedRecords.OpenEdit();

        // [THEN] Page is open, "Error Message" is <blank>
        CRMSkippedRecords."Error Message".AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure T138_CannotRemoveReferencedJobEntry()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        JobID: Guid;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 278479] referenced Integration Synch. Job Entry cannot be removed
        Init();
        // [GIVEN] CRM Integration record, where "Last Synch. Job ID" = 'A', "Last Synch. CRM Job ID" = 'B'
        CRMIntegrationRecord."Last Synch. Job ID" := CreateGuid();
        CRMIntegrationRecord."Last Synch. CRM Job ID" := CreateGuid();
        CRMIntegrationRecord.Skipped := true;
        CRMIntegrationRecord.Insert();

        // [GIVEN] 3 IntegrationSynchJobs, where "ID" = 'A', 'B', and 'C'
        IntegrationSynchJob.ID := CRMIntegrationRecord."Last Synch. Job ID";
        IntegrationSynchJob.Failed := 1;
        IntegrationSynchJob.Insert();
        IntegrationSynchJobErrors."No." := 0;
        IntegrationSynchJobErrors."Integration Synch. Job ID" := IntegrationSynchJob.ID;
        IntegrationSynchJobErrors.Insert();

        IntegrationSynchJob.ID := CRMIntegrationRecord."Last Synch. CRM Job ID";
        IntegrationSynchJob.Failed := 1;
        IntegrationSynchJob.Insert();
        IntegrationSynchJobErrors."No." := 0;
        IntegrationSynchJobErrors."Integration Synch. Job ID" := IntegrationSynchJob.ID;
        IntegrationSynchJobErrors.Insert();

        JobID := CreateGuid();
        IntegrationSynchJob.ID := JobID;
        IntegrationSynchJob.Failed := 1;
        IntegrationSynchJob.Insert();
        IntegrationSynchJobErrors."No." := 0;
        IntegrationSynchJobErrors."Integration Synch. Job ID" := IntegrationSynchJob.ID;
        IntegrationSynchJobErrors.Insert();

        // [WHEN] run "Delete All Entries"
        IntegrationSynchJob.DeleteEntries(0);

        // [THEN] IntegrationSynchJob, where "ID" = 'C', is deleted
        Assert.IsFalse(IntegrationSynchJob.Get(JobID), 'Job C should not exist');
        // [THEN] IntegrationSynchJobErrors, where "Integration Synch. Job ID" = 'C', are deleted
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", JobID);
        Assert.RecordIsEmpty(IntegrationSynchJobErrors);
        // [THEN] IntegrationSynchJobs, where "ID" = 'A' and 'B', are not deleted
        Assert.IsTrue(IntegrationSynchJob.Get(CRMIntegrationRecord."Last Synch. Job ID"), 'Job A should exist');
        Assert.IsTrue(IntegrationSynchJob.Get(CRMIntegrationRecord."Last Synch. CRM Job ID"), 'Job B should exist');
        // [THEN] IntegrationSynchJobErrors, where "Integration Synch. Job ID" = 'A' and 'B', are not deleted
        IntegrationSynchJobErrors.SetFilter(
          "Integration Synch. Job ID", '%1|%2',
          CRMIntegrationRecord."Last Synch. Job ID", CRMIntegrationRecord."Last Synch. CRM Job ID");
        Assert.RecordCount(IntegrationSynchJobErrors, 2);
    end;

    [Test]
    [HandlerFunctions('SkippedDetailsNotificationHandler,SkippedRecallNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T140_NotificationOnSkippedRecord()
    var
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        Customer: Record Customer;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        CustomerCardPage: TestPage "Customer Card";
    begin
        // [FEATURE] [UI] [Notification]
        // [SCENARIO] User should get a notification that the record is skipped
        // [SCENARIO] with the "Details" action opening "CRM Skipped Records" page
        Init();
        // [GIVEN] The Customer '10000' and Currency "EUR" are in the skipped record list.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Customer.RecordId, CRMAccount.RecordId,
          StrSubstNo(MustBeCoupledErr, Customer."Salesperson Code"), CurrentDateTime, true);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(
          Currency, CRMTransactioncurrency);
        LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
          Currency.RecordId, CRMAccount.RecordId, '', CurrentDateTime, true);

        // [GIVEN] Open Customer Card
        CustomerCardPage.Trap();
        CRMSkippedRecords.Trap();
        PAGE.Run(PAGE::"Customer Card", Customer);

        // [GIVEN] Notification: 'The record will be skipped for further synchronization. Details.'
        // [WHEN] Click on 'Details.' action
        // Handled by SkippedRecNotificationHandler

        // [THEN] "CRM Skipped Records" list is open with one record, Customer '10000'
        CRMSkippedRecords."Table Name".AssertEquals(Customer.TableCaption());
        Assert.IsFalse(CRMSkippedRecords.Next(), 'Should be one skipped record shown.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T150_GetRecDescriptionForComplexPK()
    var
        CRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [GIVEN] CRMSynchConflictBuffer for Sales Line, where primary key: 'Invoice','1003','20000'
        SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
        SalesLine."Document No." := LibraryUtility.GenerateRandomCode20(SalesLine.FieldNo("Document No."), DATABASE::"Sales Line");
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Insert();
        CRMSynchConflictBuffer."Record ID" := SalesLine.RecordId;

        // [WHEN] run CRMIntegrationRecord.GetRecDescription()
        Assert.AreEqual(
          'Invoice,' + Format(SalesLine."Document No.") + ',' + Format(SalesLine."Line No."), CRMSynchConflictBuffer.GetRecDescription(),
          'GetRecDescription fails.');
        // [THEN] result is 'Invoice,1003,20000'
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T160_RemoveDeletedCoupledRecordInNAV()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] "Delete Coupled Record" action should remove the CRM record coupled to the deleted NAV Record.
        Init();
        // [GIVEN] Customer, coupled to CRM Account, is deleted
        MockSkippedCouplingByDeletedNAVRec(Customer, CRMAccount);
        // [GIVEN] Open CRM Skipped Records page
        CRMSkippedRecords.OpenEdit();
        // [GIVEN] One line is in the list, where Description is <blank>, "Int. Description" is Customer Name
        CRMSkippedRecords.Description.AssertEquals('');
        CRMSkippedRecords."Int. Description".AssertEquals(CRMAccount.Name);
        CRMSkippedRecords."Record Exists".AssertEquals(false);
        CRMSkippedRecords."Int. Record Exists".AssertEquals(true);
        Assert.IsTrue(CRMSkippedRecords.DeleteCoupledRec.Enabled(), 'DeleteCoupledRec actions to be enabled');

        // [WHEN] Run action "Delete Coupled Record"
        CRMSkippedRecords.DeleteCoupledRec.Invoke();

        // [THEN] There is no lines on the page
        Assert.IsFalse(CRMSkippedRecords.First(), 'The list should be empty');
        // [THEN] coupling is deleted
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId), 'coupling should be deleted');
        // [THEN] the coupled CRM Account is removed
        Assert.IsFalse(CRMAccount.Find(), 'CRM Account should be deleted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T161_RemoveDeletedCoupledRecordInCRM()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] "Delete Coupled Record" action should remove the NAV record coupled to the deleted CRM Record.
        Init();
        // [GIVEN] CRMAccount, coupled to Customer, is deleted
        MockSkippedCouplingByDeletedCRMRec(Customer, CRMAccount);
        // [GIVEN] Open CRM Skipped Records page
        CRMSkippedRecords.OpenEdit();
        // [GIVEN] One line is in the list, where Description is <blank>, "Int. Description" is Customer Name
        CRMSkippedRecords.Description.AssertEquals(Customer."No.");
        CRMSkippedRecords."Int. Description".AssertEquals('');
        CRMSkippedRecords."Record Exists".AssertEquals(true);
        CRMSkippedRecords."Int. Record Exists".AssertEquals(false);
        Assert.IsTrue(CRMSkippedRecords.DeleteCoupledRec.Enabled(), 'DeleteCoupledRec actions to be enabled');

        // [WHEN] Run action "Delete Coupled Record"
        CRMSkippedRecords.DeleteCoupledRec.Invoke();

        // [THEN] There is no lines on the page
        Assert.IsFalse(CRMSkippedRecords.First(), 'The list should be empty');
        // [THEN] coupling is deleted
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Customer.RecordId), 'coupling should be deleted');
        // [THEN] the coupled Customer is removed
        Assert.IsFalse(Customer.Find(), 'Customer should be deleted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T162_RemoveDeletedCoupledRecords()
    var
        CRMAccount: array[3] of Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: array[3] of Record Customer;
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        // [FEATURE] [UT] [Deleted Couplings]
        // [SCENARIO] "Delete Coupled Records" action should remove the records coupled to the deleted record.
        Init();
        // [GIVEN] Customer 'B', coupled to CRM Account 'B', is skipped, both exist
        MockSkippedCustomers(Customer, CRMAccount, 3);
        // [GIVEN] CRMAccount 'A', coupled to Customer 'A', is deleted
        CRMAccount[1].Delete();
        // [GIVEN] Customer 'C', coupled to CRM Account 'C', is deleted
        Customer[3].Delete();
        // [GIVEN] Open CRM Skipped Records page, where are 3 lines, and selected all lines
        MockSelectingAllSkippedLines(TempCRMSynchConflictBuffer, 3);

        // [WHEN] Run action "Delete Coupled Records"
        TempCRMSynchConflictBuffer.DeleteCoupledRecords();

        // [THEN] There is one line for Customer 'B', where both coupled records exist
        VerifyLineSkippedRecordInBuffer(TempCRMSynchConflictBuffer, Customer[2].RecordId);
        // [THEN] the coupled Customer 'A' is removed, its coupling deleted
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Customer[1].RecordId), 'coupling A should be deleted');
        Assert.IsFalse(Customer[1].Find(), 'Customer should be deleted');
        // [THEN] the coupled CRM Account 'C' is deleted, its coupling deleted
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMAccount[3].AccountId), 'coupling C should be deleted');
        Assert.IsFalse(CRMAccount[3].Find(), 'CRM Account should be deleted');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T163_RemoveDeletedCoupledCRMRecordWithNoDeletePermission()
    var
        CRMAccount: array[3] of Record "CRM Account";
        Customer: array[3] of Record Customer;
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        CRMSynchSkippedRecords: Codeunit "CRM Synch. Skipped Records";
    begin
        // [FEATURE] [UT] [Deleted Couplings] [Permission]
        // [SCENARIO] "Delete Coupled Records" action should throw and error if there is no permission to delete CRM record.
        Init();
        // [GIVEN] Sync user has no permission to delete entities
        BindSubscription(CRMSynchSkippedRecords); // will call OnBeforeDeleteCRMAccount

        // [GIVEN] Customer, coupled to CRM Account, is skipped, both exist
        MockSkippedCustomers(Customer, CRMAccount, 1);
        // [GIVEN] Customer is deleted
        Customer[1].Delete();
        // [GIVEN] Open CRM Skipped Records page, where is 1 line
        MockSelectingAllSkippedLines(TempCRMSynchConflictBuffer, 1);

        // [WHEN] Run action "Delete Coupled Records"
        asserterror TempCRMSynchConflictBuffer.DeleteCoupledRecords();

        // [THEN] Error message: "You do not have permission to delete entities..."
        Assert.ExpectedError(NoPermissionToDeleteInCRMErr);
        // [THEN] There is still one line for CRM Account
        TempCRMSynchConflictBuffer.Reset();
        TempCRMSynchConflictBuffer.FindFirst();
        Assert.IsTrue(TempCRMSynchConflictBuffer.IsOneRecordDeleted(), 'One rec should be deleted in buffer');
        Assert.IsTrue(CRMAccount[1].Find(), 'CRM Account does not exist');
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Account", 'OnBeforeDeleteEvent', '', false, false)]
    procedure OnBeforeDeleteCRMAccount(var Rec: Record "CRM Account"; RunTrigger: Boolean)
    begin
        Error(DeleteAccountPrivilegeErr);
    end;

    [Test]
    [HandlerFunctions('SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T165_RestoreDeletedRecordInNAV()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: array[2] of Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        RecID: RecordID;
        RecRef: RecordRef;
        JobID: Guid;
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] "Restore Coupled Record" action should restore the deleted NAV record by synchronization from CRM.
        Init();
        // [GIVEN] Customer, coupled to CRM Account, is deleted
        MockSkippedCouplingByDeletedNAVRec(Customer[1], CRMAccount);
        // [GIVEN] Open CRM Skipped Records page
        CRMSkippedRecords.OpenEdit();
        // [GIVEN] One line is in the list, where Description is <blank>, "Int. Description" is Customer Name
        CRMSkippedRecords.Description.AssertEquals('');
        CRMSkippedRecords."Int. Description".AssertEquals(CRMAccount.Name);

        // [WHEN] Run action "Restore Deleted Records"
        CRMSkippedRecords.RestoreDeletedRec.Invoke();

        // [THEN] the synchronization job is scheduled and executed
        CRMAccount.SetRange(AccountId, CRMAccount.AccountId);
        JobID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Account", CRMAccount.GetView(), IntegrationTableMapping);
        VerifyNotificationMessage(SyncStartedMsg);

        // [THEN] There is no lines on the page
        Assert.IsFalse(CRMSkippedRecords.First(), 'The list should be empty');
        // [THEN] CRM Account is not deleted
        Assert.IsTrue(CRMAccount.Find(), 'CRM Account should not be deleted');
        // [THEN] Customer is restored with a new "No." and "Name" copied from CRM Account
        CRMIntegrationRecord.FindRecordIDFromID(CRMAccount.AccountId, DATABASE::Customer, RecID);
        RecRef.Get(RecID);
        RecRef.SetTable(Customer[2]);
        Assert.AreNotEqual(Customer[1]."No.", Customer[2]."No.", 'Should be a new Customer No.');
        Assert.AreEqual(CopyStr(CRMAccount.Name, 1, MaxStrLen(Customer[2].Name)), Customer[2].Name, 'new Customer Name');
    end;

    [Test]
    [HandlerFunctions('SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T166_RestoreDeletedRecordInCRM()
    var
        CRMAccount: array[2] of Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        JobID: Guid;
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] "Restore Coupled Record" action should restore the deleted CRM record by synchronization from NAV.
        Init();
        // [GIVEN] CRMAccount, coupled to Customer, is deleted
        MockSkippedCouplingByDeletedCRMRec(Customer, CRMAccount[1]);
        // [GIVEN] Open CRM Skipped Records page
        CRMSkippedRecords.OpenEdit();

        // [WHEN] Run action "Restore Deleted Records"
        CRMSkippedRecords.RestoreDeletedRec.Invoke();

        // [THEN] the synchronization job is scheduled and executed
        Customer.SetRange(Systemid, Customer.SystemId);
        JobID :=
          LibraryCRMIntegration.RunJobQueueEntry(DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);
        VerifyNotificationMessage(SyncStartedMsg);
        // [THEN] There is no lines on the page
        Assert.IsFalse(CRMSkippedRecords.First(), 'The list should be empty');
        // [THEN] Customer is not deleted
        Assert.IsTrue(Customer.Find(), 'Customer should not be deleted');
        // [THEN] CRM Account is restored with a new "AccountId" and "Name" copied from Customer
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMAccount[2].Get(CRMIntegrationRecord."CRM ID");
        Assert.AreNotEqual(CRMAccount[1].AccountId, CRMAccount[2].AccountId, 'Should be a new AccountId');
        Assert.AreEqual(Customer.Name, CRMAccount[2].Name, 'new CRM Account Name');
    end;

    [Test]
    [HandlerFunctions('SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T167_RestoreDeletedRecords()
    var
        CRMAccount: array[3] of Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: array[3] of Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        IntegrationSynchJob: Record "Integration Synch. Job";
        RecID: RecordID;
        RecRef: RecordRef;
        JobID: Guid;
    begin
        // [FEATURE] [UT] [Deleted Couplings]
        // [SCENARIO] "Restore Coupled Records" action should restore the deleted records by synchronization from existing couple.
        Init();
        // [GIVEN] Customer 'B', coupled to CRM Account 'B', is skipped, both exist
        MockSkippedCustomers(Customer, CRMAccount, 3);
        // [GIVEN] CRMAccount 'A', coupled to Customer 'A', is deleted
        CRMAccount[1].Delete();
        // [GIVEN] Customer 'C', coupled to CRM Account 'C', is deleted
        Customer[3].Delete();
        // [GIVEN] Open CRM Skipped Records page, where are 3 lines, and selected all lines
        MockSelectingAllSkippedLines(TempCRMSynchConflictBuffer, 3);
        // [GIVEN] Only base integration table mappings, not child mappings
        IntegrationTableMapping.SetRange("Table ID", Database::Customer);
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        IntegrationTableMapping.DeleteAll();

        // [WHEN] Run action "Restore Deleted Records"
        TempCRMSynchConflictBuffer.RestoreDeletedRecords();

        // [THEN] The notification is sent
        VerifyNotificationMessage(SyncStartedMsg);

        // [THEN] the synchronization job is scheduled and executed
        IntegrationTableMapping.SetRange(Direction, IntegrationTableMapping.Direction::Bidirectional);
        Assert.AreEqual(1, IntegrationTableMapping.Count(), 'Count of table mappings is incorrect');
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(1, IntegrationTableMapping.GetTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');
        Assert.AreEqual(1, IntegrationTableMapping.GetIntegrationTableFilter().Split('|').Count(), 'Integration table mapping has incorrect table filter');
        JobID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);
        IntegrationSynchJob.Inserted := 1;
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        LibraryCRMIntegration.VerifySyncJob(JobID, IntegrationTableMapping, IntegrationSynchJob);
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        LibraryCRMIntegration.VerifySyncJob(JobID, IntegrationTableMapping, IntegrationSynchJob);

        // [THEN] There is one line for Customer 'B', where both coupled records exist
        VerifyLineSkippedRecordInBuffer(TempCRMSynchConflictBuffer, Customer[2].RecordId);
        // [THEN] Customer 'A' is not deleted
        Assert.IsTrue(Customer[1].Find(), 'Customer should not be deleted');
        // [THEN] CRM Account is restored with a new "AccountId" and "Name" copied from Customer
        CRMIntegrationRecord.FindByRecordID(Customer[1].RecordId());
        CRMAccount[1].Get(CRMIntegrationRecord."CRM ID");
        Assert.AreEqual(Customer[1].Name, CRMAccount[1].Name, 'new CRM Account Name');

        // [THEN] CRM Account 'C' is not deleted
        Assert.IsTrue(CRMAccount[3].Find(), 'CRM Account should not be deleted');
        // [THEN] Customer 'C' is restored with a new "No." and "Name" copied from CRM Account 'C'
        CRMIntegrationRecord.FindRecordIDFromID(CRMAccount[3].AccountId, Database::Customer, RecID);
        RecRef.Get(RecID);
        RecRef.SetTable(Customer[3]);
        Assert.AreEqual(CopyStr(CRMAccount[3].Name, 1, MaxStrLen(Customer[3].Name)), Customer[3].Name, 'new Customer Name');

        // [THEN] Variable storage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T170_RestoreSyncLogActionsDisabledIfNAVRecordDeleted()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] Action "Delete Coupling" is only that is enabled if the coupled NAV record is deleted
        Init();
        // [GIVEN] Customer, coupled to CRM Account, is skipped, customer is deleted
        MockSkippedCustomer(Customer, CRMAccount);
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        Customer.Delete();

        // [WHEN] Open "CRM Skipped Records" page
        CRMSkippedRecords.OpenEdit();

        // [THEN] Action "Delete Coupling" is enabled
        Assert.IsTrue(CRMSkippedRecords.DeleteCRMCoupling.Enabled(), 'action Delete Coupling');
        // [THEN] Actions "Restore", "Synchronize", "Sync. Log", "Set up coupling" are disabled
        Assert.IsFalse(CRMSkippedRecords.Restore.Enabled(), 'Restore action to be enabled');
        Assert.IsFalse(CRMSkippedRecords.CRMSynchronizeNow.Enabled(), 'Synchronize action to be enabled');
        Assert.IsFalse(CRMSkippedRecords.ShowLog.Enabled(), 'ShowLog action to be disabled');
        Assert.IsFalse(CRMSkippedRecords.ManageCRMCoupling.Enabled(), 'action Manage Coupling');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T171_RestoreSyncActionsDisabledIfCRMRecordDeleted()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] Actions "Restore", "Synchronize" are disabled if coupled CRM record is deleted
        Init();
        // [GIVEN] The Customer '10000' is coupled, but CRM Account was deleted.
        MockSkippedCouplingByDeletedCRMRec(Customer, CRMAccount);

        // [WHEN] Open "CRM Skipped Records" page
        CRMSkippedRecords.OpenEdit();

        // [THEN] Actions "Restore", "Synchronize" are disabled
        Assert.IsFalse(CRMSkippedRecords.Restore.Enabled(), 'Restore action to be disabled');
        Assert.IsFalse(CRMSkippedRecords.CRMSynchronizeNow.Enabled(), 'Synchronize action to be disabled');
        // [THEN] Action "Sync. Log", "Set up coupling", "Delete Coupling" are enabled
        Assert.IsTrue(CRMSkippedRecords.DeleteCRMCoupling.Enabled(), 'action Delete Coupling');
        Assert.IsTrue(CRMSkippedRecords.ShowLog.Enabled(), 'ShowLog action to be enabled');
        Assert.IsTrue(CRMSkippedRecords.ManageCRMCoupling.Enabled(), 'action Manage Coupling');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T172_RemoveRestoreDeletedActionDisabledIfBothRecsExist()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] "Delete Coupled Record" and "Restore Deleted Records" actions should be disabled if both coupled records exist.
        JobQueueEntry.DeleteAll();
        CRMIntegrationRecord.DeleteAll();
        // [GIVEN] Customer, coupled to CRM Account, skipped for synchronization.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        CRMIntegrationRecord.Skipped := true;
        CRMIntegrationRecord.Modify();

        // [WHEN] Open CRM Skipped Records page
        CRMSkippedRecords.OpenEdit();

        // [THEN] both "Record Exists" and "Int. Record Exists" are 'Yes'
        CRMSkippedRecords."Record Exists".AssertEquals(true);
        CRMSkippedRecords."Int. Record Exists".AssertEquals(true);
        // [THEN] "Delete Coupled Rec" action is disabled
        Assert.IsFalse(CRMSkippedRecords.DeleteCoupledRec.Enabled(), 'DeleteCoupledRec actions to be disabled');
        // [THEN] "Restore Deleted Records"action is disabled
        Assert.IsFalse(CRMSkippedRecords.RestoreDeletedRec.Enabled(), 'RestoreDeletedRec action to be disabled');
        // [THEN] Actions "Restore", "Synch. Log", "Synchronize", "Set up coupling", "Delete coupling" are enabled
        Assert.IsTrue(CRMSkippedRecords.Restore.Enabled(), 'Restore action to be enabled');
        Assert.IsTrue(CRMSkippedRecords.ShowLog.Enabled(), 'ShowLog action to be enabled');
        Assert.IsTrue(CRMSkippedRecords.CRMSynchronizeNow.Enabled(), 'Synchronize action to be enabled');
        Assert.IsTrue(CRMSkippedRecords.ManageCRMCoupling.Enabled(), 'SetupCoupling action to be enabled');
        Assert.IsTrue(CRMSkippedRecords.DeleteCRMCoupling.Enabled(), 'DeleteCRMCoupling action to be enabled');
    end;

    [Test]
    [HandlerFunctions('CRMCouplingRecordConfirmedModalPageHandler,SyncNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure T175_SetupCouplingConfirmedForDeletedCRMRec()
    var
        Item: Record Item;
        CRMProduct: array[2] of Record "CRM Product";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        CRMId: Guid;
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] Skipped record due to deleted CRM couple should dissapear from the page after new coupling is set
        Init();
        // [GIVEN] Item 'A' coupled to deleted CRM Product 'A', skipped for synchronization
        MockSkippedItem(Item, CRMProduct[1]);
        CRMProduct[1].Delete();
        // [GIVEN] CRM Product 'B', not coupled
        CRMProduct[2].Init();
        CRMProduct[2].ProductId := CreateGuid();
        CRMProduct[2].ProductNumber := LibraryUtility.GenerateGUID();
        CRMProduct[2].Insert(true);
        // [GIVEN] Open CRM Skipped Records page
        CRMSkippedRecords.OpenEdit();
        // [GIVEN] Run action "Set Up Coupling"
        // [WHEN] Set "CRM Name" as 'B' and push 'OK'
        LibraryVariableStorage.Enqueue(CRMProduct[2].ProductNumber);
        CRMSkippedRecords.ManageCRMCoupling.Invoke();
        // by CRMCouplingRecordConfirmedModalPageHandler

        // [THEN] Notification 'The synchronization has been scheduled'
        VerifyNotificationMessage(SyncStartedMsg);
        // [THEN] Item 'A' is coupled to Product 'B' and not skipped
        Assert.IsTrue(CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId, CRMId), 'Item should be coupled');
        Assert.AreEqual(CRMId, CRMProduct[2].ProductId, 'Should be coupled to Product B');
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMId), 'Product B should be coupled');
        CRMIntegrationRecord.TestField(Skipped, false);
        // [THEN] Record is not in the list
        Assert.IsFalse(CRMSkippedRecords.First(), 'The page should be empty');
    end;

    [Test]
    [HandlerFunctions('CRMCouplingRecordCancelledModalPageHandler')]
    [Scope('OnPrem')]
    procedure T176_SetupCouplingCancelledForDeletedCRMRec()
    var
        Item: Record Item;
        CRMProduct: array[2] of Record "CRM Product";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        CRMId: Guid;
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] Skipped record due to deleted CRM couple should left on the page after new coupling is cancelled
        Init();
        // [GIVEN] Item 'A' coupled to deleted CRM Product 'A', skipped for synchronization
        MockSkippedItem(Item, CRMProduct[1]);
        CRMProduct[1].Delete();
        // [GIVEN] CRM Product 'B', not coupled
        CRMProduct[2].Init();
        CRMProduct[2].ProductId := CreateGuid();
        CRMProduct[2].ProductNumber := LibraryUtility.GenerateGUID();
        CRMProduct[2].Insert(true);
        // [GIVEN] Open CRM Skipped Records page
        CRMSkippedRecords.OpenEdit();
        // [GIVEN] Run action "Set Up Coupling"
        CRMSkippedRecords.ManageCRMCoupling.Invoke();
        // [WHEN] Push 'Cancel'
        // by CRMCouplingRecordCancelledModalPageHandler

        // [THEN] Item 'A' is coupled to Product 'A' and still skipped
        Assert.IsTrue(CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId, CRMId), 'Item should be coupled');
        Assert.AreEqual(CRMId, CRMProduct[1].ProductId, 'Should be coupled to Product A');
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMId), 'Product A should be coupled');
        CRMIntegrationRecord.TestField(Skipped, true);
        // [THEN] Record is in the list
        Assert.IsTrue(CRMSkippedRecords.First(), 'The page should not be empty');
        CRMSkippedRecords.Description.AssertEquals(Item."No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T180_CouplingDeletedOnOpenIfBothRecsDeleted()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        // [FEATURE] [UI] [Deleted Couplings]
        // [SCENARIO] "Delete Coupled Record" and "Restore Deleted Records" actions should be disabled if both coupled records were deleted.
        Init();
        CRMIntegrationRecord.DeleteAll();
        // [GIVEN] Customer, coupled to CRM Account, is skipped, both deleted
        MockSkippedCustomer(Customer, CRMAccount);
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        Customer.Delete();
        CRMAccount.Delete();

        // [WHEN] Open CRM Skipped Records page
        CRMSkippedRecords.OpenEdit();

        // [THEN]  No lines in the page, the couplng should be deleted
        Assert.IsFalse(CRMSkippedRecords.First(), 'Page should be empty');
        Assert.IsFalse(CRMIntegrationRecord.Find(), 'CRMIntegrationRecord should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T190_UpdateSourceTableRemovesNotSkippedRecords()
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        CRMID: Guid;
    begin
        // [FEATURE] [UT]
        Init();
        // [GIVEN] Two skipped couplings are in SynchConflictBuffer
        MockTempSkippedCouplings(TempCRMIntegrationRecord);
        Assert.AreEqual(2, TempCRMSynchConflictBuffer.Fill(TempCRMIntegrationRecord), 'initial number of records');
        // [GIVEN] one coupling got "Skipped" = No
        TempCRMIntegrationRecord.FindFirst();
        TempCRMIntegrationRecord.Skipped := false;
        TempCRMIntegrationRecord.Modify();
        CRMID := TempCRMIntegrationRecord."CRM ID";

        // [WHEN] run UpdateSourceTable()
        Assert.AreEqual(1, TempCRMSynchConflictBuffer.UpdateSourceTable(TempCRMIntegrationRecord), 'numer of remaining records');
        // [THEN] UpdateSourceTable() removes the record, which source is not skipped
        TempCRMSynchConflictBuffer.FindFirst();
        Assert.AreNotEqual(CRMID, TempCRMSynchConflictBuffer."CRM ID", 'this record should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T191_UpdateSourceTableRemovesNotExistingCouplings()
    var
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        CRMID: Guid;
    begin
        // [FEATURE] [UT]
        Init();
        // [GIVEN] Two skipped couplings are in SynchConflictBuffer
        MockTempSkippedCouplings(TempCRMIntegrationRecord);
        Assert.AreEqual(2, TempCRMSynchConflictBuffer.Fill(TempCRMIntegrationRecord), 'initial number of records');
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] One coupling was deleted and replaced by not skipped one
        TempCRMIntegrationRecord.FindFirst();
        CRMID := TempCRMIntegrationRecord."CRM ID";
        TempCRMIntegrationRecord.Delete();
        TempCRMIntegrationRecord."CRM ID" := CRMSystemuser.SystemUserId;
        TempCRMIntegrationRecord.Skipped := false;
        TempCRMIntegrationRecord.Insert();
        // [GIVEN] SynchConflictBuffer points to the deleted coupling
        TempCRMSynchConflictBuffer.SetRange("CRM ID", CRMID);
        TempCRMSynchConflictBuffer.FindFirst();
        TempCRMSynchConflictBuffer.Reset();

        // [WHEN] run UpdateSourceTable()
        // [THEN] UpdateSourceTable() removes the record, which source coupling was deleted
        Assert.AreEqual(1, TempCRMSynchConflictBuffer.UpdateSourceTable(TempCRMIntegrationRecord), 'numer of remaining records');
        TempCRMSynchConflictBuffer.FindFirst();
        Assert.AreNotEqual(CRMID, TempCRMSynchConflictBuffer."CRM ID", 'this record should be deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure T200_FindMoreMarksBrokenCouplingsAsSkipped()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        PrevDirection: Option;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Find More" action marks broken couplings as skipped.
        Init();

        // [GIVEN] The CUSTOMER mapping is unidirectional
        IntegrationTableMapping.Get('CUSTOMER');
        PrevDirection := IntegrationTableMapping.Direction;
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping.Modify();

        // [GIVEN] The coupled customer and account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] The customer is deleted
        Customer.Delete();

        // [WHEN] Open Coupled Data Synchronization Errors page
        CRMSkippedRecords.OpenEdit();

        // [THEN] The coupling for the deleted customer is not listed
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        Assert.IsFalse(CRMSkippedRecords.FindFirstField("Int. Description", CRMAccount.Name), 'Coupling is listed');

        // [THEN] Invoke the action Find More
        CRMSkippedRecords.FindMore.Invoke();

        // [THEN] The coupling for the deleted customer is listed
        Assert.IsTrue(CRMSkippedRecords.FindFirstField("Int. Description", CRMAccount.Name), 'Coupling is not listed');

        // [THEN] The coupling is marked as skipped
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        CRMIntegrationRecord.TestField(Skipped, true);

        IntegrationTableMapping.Direction := PrevDirection;
        IntegrationTableMapping.Modify();
    end;

    local procedure Init()
    var
        MyNotifications: Record "My Notifications";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        ClientSecret: Text;
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID(), '', '', false);
    end;

    local procedure DecoupleSalesperson("Code": Code[20]; var CRMIntegrationRecord: Record "CRM Integration Record")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.Get(Code);
        CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser.RecordId);
        CRMIntegrationRecord.Delete();
    end;

    local procedure FailedSynchCustomer(Customer: Record Customer; ErrorMsg: Text)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationSynchJob.Failed := 1;
        IntegrationSynchJob.Message := CopyStr(ErrorMsg, 1, MaxStrLen(IntegrationSynchJob.Message));
        LibraryCRMIntegration.VerifySyncJob(
          SynchCustomer(Customer, IntegrationTableMapping), IntegrationTableMapping, IntegrationSynchJob);
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'wrong direction.'); // by PickDirectionToCRMHandler
    end;

    local procedure FailedSkippedSkippedSynchCustomer(Customer: Record Customer; ErrorMsg: Text)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationSynchJob.Skipped := 1;
        IntegrationSynchJob.Message := CopyStr(ErrorMsg, 1, MaxStrLen(IntegrationSynchJob.Message));
        LibraryCRMIntegration.VerifySyncJob(
          SynchCustomer(Customer, IntegrationTableMapping), IntegrationTableMapping, IntegrationSynchJob);
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'wrong direction.'); // by PickDirectionToCRMHandler
    end;

    local procedure GoodSynchCustomer(Customer: Record Customer)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationSynchJob.Modified := 1;
        LibraryCRMIntegration.VerifySyncJob(
          SynchCustomer(Customer, IntegrationTableMapping), IntegrationTableMapping, IntegrationSynchJob);
    end;

    local procedure SkippedSynchCustomer(Customer: Record Customer)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'wrong direction.'); // by PickDirectionToCRMHandler
    end;

    local procedure SynchCustomer(Customer: Record Customer; var IntegrationTableMapping: Record "Integration Table Mapping") JobID: Guid
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId());
        // Executing the Sync Job
        Customer.SetRange(SystemId, Customer.SystemId);
        JobID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);
    end;

    local procedure RestoreSkippedCustomer(Customer: Record Customer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
    begin
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMSkippedRecords.OpenEdit();
        CRMSkippedRecords.FindFirstField(Description, Customer."No.");
        CRMSkippedRecords."Table Name".AssertEquals(Customer.TableCaption());
        CRMSkippedRecords.Restore.Invoke();
    end;

    local procedure RestoreSkippedRecords(var CRMIntegrationRecord: Record "CRM Integration Record")
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // Simulating CRMSkippedRecords.Restore.INVOKE
        CRMIntegrationManagement.UpdateSkippedNow(CRMIntegrationRecord);
    end;

    local procedure RestoreSkippedRecords()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // Simulating CRMSkippedRecords.Restore.INVOKE
        CRMIntegrationManagement.UpdateAllSkippedNow();
    end;

    local procedure MarkSelectedRecord(var SelectedCRMIntegrationRecord: Record "CRM Integration Record"; RecID: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(RecID);
        SelectedCRMIntegrationRecord := CRMIntegrationRecord;
        SelectedCRMIntegrationRecord.Mark(true);
    end;

    local procedure MockLastCRMSyncDT(RecId: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.FindByRecordID(RecId);
        CRMIntegrationRecord."Last Synch. CRM Modified On" := CurrentDateTime;
        CRMIntegrationRecord.Modify();
    end;

    local procedure MockTempSkippedCouplings(var CRMIntegrationRecord: Record "CRM Integration Record")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        i: Integer;
    begin
        for i := 1 to 2 do begin
            LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

            CRMIntegrationRecord.Init();
            CRMIntegrationRecord."CRM ID" := CRMSystemuser.SystemUserId;
            CRMIntegrationRecord."Table ID" := DATABASE::"Salesperson/Purchaser";
            CRMIntegrationRecord.Skipped := true;
            CRMIntegrationRecord.Insert();
        end;
    end;

    local procedure MockSelectingAllSkippedLines(var TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary; Counter: Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.Reset();
        CRMIntegrationRecord.SetRange(Skipped, true);
        Assert.AreEqual(Counter, TempCRMSynchConflictBuffer.Fill(CRMIntegrationRecord), 'number of skipped couplings');
        TempCRMSynchConflictBuffer.FindSet();
        repeat
            TempCRMSynchConflictBuffer.Mark(true);
        until TempCRMSynchConflictBuffer.Next() = 0;
        TempCRMSynchConflictBuffer.MarkedOnly(true);
        Assert.AreEqual(Counter, TempCRMSynchConflictBuffer.Count, 'number of selected couplings');
    end;

    local procedure MockSkippedCouplingByDeletedNAVRec(var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    begin
        MockSkippedCustomer(Customer, CRMAccount);
        Customer.Delete();
    end;

    local procedure MockSkippedCouplingByDeletedCRMRec(var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    begin
        MockSkippedCustomer(Customer, CRMAccount);
        CRMAccount.Delete();
    end;

    local procedure MockSkippedCustomers(var Customer: array[3] of Record Customer; var CRMAccount: array[3] of Record "CRM Account"; Counter: Integer)
    var
        I: Integer;
    begin
        for I := 1 to Counter do
            MockSkippedCustomer(Customer[I], CRMAccount[I])
    end;

    local procedure MockSkippedCustomer(var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        CRMIntegrationRecord.Skipped := true;
        CRMIntegrationRecord."Last Synch. Modified On" := CurrentDateTime - 10000;
        CRMIntegrationRecord."Last Synch. CRM Modified On" := CurrentDateTime - 15000;
        CRMIntegrationRecord.Modify();
        Customer.Name := LibraryUtility.GenerateGUID();
        Customer.Modify();
        CRMAccount.Name := LibraryUtility.GenerateGUID();
        CRMAccount.Modify();
    end;

    local procedure MockSkippedItem(var Item: Record Item; var CRMProduct: Record "CRM Product")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        CRMIntegrationRecord.FindByCRMID(CRMProduct.ProductId);
        CRMIntegrationRecord.Skipped := true;
        CRMIntegrationRecord.Modify();
    end;

    local procedure MockSkippedSalespersons(var SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser"; var CRMSystemuser: array[2] of Record "CRM Systemuser")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        I: Integer;
    begin
        for I := 1 to 2 do begin
            LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[I], CRMSystemuser[I]);
            CRMIntegrationRecord.FindByCRMID(CRMSystemuser[I].SystemUserId);
            CRMIntegrationRecord.Skipped := true;
            CRMIntegrationRecord."Last Synch. Modified On" := CurrentDateTime - 10000;
            CRMIntegrationRecord.Modify();
            CRMSystemuser[I].FullName := LibraryUtility.GenerateGUID();
            CRMSystemuser[I].Modify();
        end;
    end;

    local procedure VerifyIntSynchJobs(JobQueueEntryID: Guid; ExpectedIntegrationSynchJob: Record "Integration Synch. Job")
    var
        IntegrationSynchJob: array[2] of Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.SetRange(ID, JobQueueEntryID);
        JobQueueLogEntry.FindLast();
        IntegrationSynchJob[1].SetRange("Job Queue Log Entry No.", JobQueueLogEntry."Entry No.");
        IntegrationSynchJob[1].SetRange("Synch. Direction", IntegrationTableMapping.Direction::FromIntegrationTable);
        Assert.IsTrue(IntegrationSynchJob[1].FindLast(), 'IntegrationSynchJob.FromIntTable should be found.');
        IntegrationSynchJob[2].SetRange("Job Queue Log Entry No.", JobQueueLogEntry."Entry No.");
        IntegrationSynchJob[2].SetRange("Synch. Direction", IntegrationTableMapping.Direction::ToIntegrationTable);
        Assert.IsTrue(IntegrationSynchJob[2].FindLast(), 'IntegrationSynchJob.ToIntTable should be found.');

        Assert.AreEqual(
          ExpectedIntegrationSynchJob.Failed,
          IntegrationSynchJob[1].Failed + IntegrationSynchJob[2].Failed, 'Field: "Failed"');
        Assert.AreEqual(
          ExpectedIntegrationSynchJob.Inserted,
          IntegrationSynchJob[1].Inserted + IntegrationSynchJob[2].Inserted, 'Field: "Inserted"');
        Assert.AreEqual(
          ExpectedIntegrationSynchJob.Deleted,
          IntegrationSynchJob[1].Deleted + IntegrationSynchJob[2].Deleted, 'Field: "Deleted"');
        Assert.AreEqual(
          ExpectedIntegrationSynchJob.Modified,
          IntegrationSynchJob[1].Modified + IntegrationSynchJob[2].Modified, 'Field: "Modified"');
        Assert.AreEqual(
          ExpectedIntegrationSynchJob.Unchanged,
          IntegrationSynchJob[1].Unchanged + IntegrationSynchJob[2].Unchanged, 'Field: "Unchanged"');
        Assert.AreEqual(
          ExpectedIntegrationSynchJob.Skipped,
          IntegrationSynchJob[1].Skipped + IntegrationSynchJob[2].Skipped, 'Field: "Skipped"');
    end;

    local procedure VerifyLineSkippedRecordInBuffer(var TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary; RecID: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        TempCRMSynchConflictBuffer.Reset();
        Assert.AreEqual(1, TempCRMSynchConflictBuffer.Count, 'should be one line in the buffer');
        TempCRMSynchConflictBuffer.FindFirst();
        Assert.IsTrue(TempCRMSynchConflictBuffer.DoBothRecordsExist(), 'both coupled records should exist');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(RecID), 'coupling should exist');
        CRMIntegrationRecord.TestField(Skipped, true);
    end;

    local procedure VerifyNotificationMessage(ExpectedErrorMsg: Text)
    begin
        // Expect that LibraryVariableStorage contains a message filled by SyncNotificationHandler handler
        Assert.ExpectedMessage(ExpectedErrorMsg, LibraryVariableStorage.DequeueText());
    end;

    local procedure VerifyPagesActions(CRMSkippedRecords: TestPage "CRM Skipped Records"; ActionsAreEnabled: Boolean)
    begin
        Assert.AreEqual(ActionsAreEnabled, CRMSkippedRecords.Restore.Enabled(), 'action Restore');
        Assert.AreEqual(ActionsAreEnabled, CRMSkippedRecords.CRMSynchronizeNow.Enabled(), 'action Synchronize');
        Assert.AreEqual(ActionsAreEnabled, CRMSkippedRecords.ShowLog.Enabled(), 'action Show Log');
        Assert.AreEqual(ActionsAreEnabled, CRMSkippedRecords.DeleteCRMCoupling.Enabled(), 'action Delete Coupling');
        Assert.AreEqual(ActionsAreEnabled, CRMSkippedRecords.ManageCRMCoupling.Enabled(), 'action Manage Coupling');
    end;

    local procedure SimulateUncouplingJobsExecution()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Int. Uncouple Job Runner");
        JobQueueEntry.FindSet();
        repeat
            Codeunit.Run(Codeunit::"Int. Uncouple Job Runner", JobQueueEntry);
        until JobQueueEntry.Next() = 0;
    end;

    local procedure VerifyUncouplingJobQueueEntryExists()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Int. Uncouple Job Runner");
        Assert.RecordIsNotEmpty(JobQueueEntry);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PickDirectionToCRMHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Assert.ExpectedMessage('Synchronize data for', Instruction);
        Choice := 1;
        LibraryVariableStorage.Enqueue(Choice);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(SyncCompleteNotification.Message);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SkippedDetailsNotificationHandler(var SkippedRecNotification: Notification): Boolean
    var
        CRMIntegrationMgt: Codeunit "CRM Integration Management";
    begin
        Assert.ExpectedMessage(SkippedRecMsg, SkippedRecNotification.Message);
        // simulate click on notification's 'Details' action
        CRMIntegrationMgt.ShowSkippedRecords(SkippedRecNotification);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SkippedNotificationHandler(var SkippedRecNotification: Notification): Boolean
    begin
        Assert.ExpectedMessage(SkippedRecMsg, SkippedRecNotification.Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text)
    begin
        LibraryVariableStorage.Enqueue(Msg);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMCouplingRecordModalPageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        LibraryVariableStorage.Enqueue(CRMCouplingRecord.NAVName.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMCouplingRecordCancelledModalPageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        // simulate an attempt of coupling that was cancelled for some reason
        CRMCouplingRecord.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMCouplingRecordConfirmedModalPageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.CRMName.Value(LibraryVariableStorage.DequeueText()); // set by the test
        CRMCouplingRecord.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemCardHandler(var ItemCard: TestPage "Item Card")
    begin
        LibraryVariableStorage.Enqueue(ItemCard."No.".Value);
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure HyperlinkHandler(Link: Text)
    begin
        LibraryVariableStorage.Enqueue(Link);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    var
        CRMIntegrationMgt: Codeunit "CRM Integration Management";
    begin
        Assert.AreEqual(Format(CRMIntegrationMgt.GetCommonNotificationID()), Format(Notification.Id), UnexpectedNotificationIdErr);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure SkippedRecallNotificationHandler(var Notification: Notification): Boolean
    var
        CRMIntegrationMgt: Codeunit "CRM Integration Management";
    begin
        Assert.AreEqual(
          Format(CRMIntegrationMgt.GetSkippedNotificationID()), Format(Notification.Id), UnexpectedNotificationIdErr);
    end;
}
