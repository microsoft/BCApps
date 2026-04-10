codeunit 139179 "CRM Statistics Job Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [CRM Account Statistics]
    end;

    var
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.';
        WasNotFoundErr: Label 'was not found.';

    [Test]
    [Scope('OnPrem')]
    procedure AccountStatisticsCalculatesFlowFields()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMAccountStatistics: Record "CRM Account Statistics";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
    begin
        // [FEATURE] [FlowField]
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] The Customer has some non-zero FlowField values in the statistics, which have not been calculated
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", '', 2, '', WorkDate());

        // Verify that the Outstanding Invoices value is zero because it has not been calculated
        Assert.AreEqual(0, Customer."Outstanding Invoices (LCY)",
          'Expected the Outstanding Invoices (LCY) field to not yet be calculated and return zero');

        // [WHEN] The update job is performed
        CRMStatisticsJob.CreateOrUpdateCRMAccountStatistics(Customer, CRMAccount);

        // [THEN] The FlowField value is correctly set on the Account Statistics record
        CRMAccount.Get(CRMAccount.RecordId);
        CRMAccountStatistics.SetRange(AccountStatisticsId, CRMAccount.AccountStatiticsId);
        CRMAccountStatistics.FindFirst();
        Assert.AreEqual(SalesLine."Amount Including VAT", CRMAccountStatistics."Outstanding Invoices (LCY)",
          'Expected the Outstanding Invoices (LCY) field to be set on the Account Statistics');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountStatisticsUpdatesFlowFields()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMAccountStatistics: Record "CRM Account Statistics";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
        OldValue: Decimal;
    begin
        // [FEATURE] [FlowField]
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] The Customer has some field values in the statistics, different from the ones in the Account Statistics
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", '', 2, '', WorkDate());

        // Create and verify
        CRMStatisticsJob.CreateOrUpdateCRMAccountStatistics(Customer, CRMAccount);
        CRMAccount.Get(CRMAccount.RecordId);
        CRMAccountStatistics.SetRange(AccountStatisticsId, CRMAccount.AccountStatiticsId);
        CRMAccountStatistics.FindFirst();
        Assert.AreEqual(SalesLine."Amount Including VAT", CRMAccountStatistics."Outstanding Invoices (LCY)",
          'The Outstanding Invoices (LCY) field must be set after creating the Account Statistics');

        // Update sales line only and verify
        OldValue := SalesLine."Amount Including VAT";
        SalesLine.Quantity := 3;
        SalesLine.Modify();
        Assert.AreEqual(OldValue, CRMAccountStatistics."Outstanding Invoices (LCY)",
          'The Outstanding Invoices (LCY) field must not be updated on Account Statistics without running the update job');

        // [WHEN] The update job is performed
        CRMStatisticsJob.CreateOrUpdateCRMAccountStatistics(Customer, CRMAccount);

        // [THEN] The field value is correctly updated on the Account Statistics record
        CRMAccount.Get(CRMAccount.RecordId);
        CRMAccountStatistics.SetRange(AccountStatisticsId, CRMAccount.AccountStatiticsId);
        CRMAccountStatistics.FindFirst();
        Assert.AreEqual(SalesLine."Amount Including VAT", CRMAccountStatistics."Outstanding Invoices (LCY)",
          'The Outstanding Invoices (LCY) field must be updated on the Account Statistics');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountStatisticsCreationDoesNotChangeCRMAccountSynchStatus()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] A coupled and synchronized Customer and CRM Account
        CreateCRMAccountSynchedToCustomer(Customer, CRMAccount);

        Assert.IsFalse(CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(
            CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn),
          'The Customer and CRM Account were just synchronized; their Integration Record should not be marked as CRM modified');

        // [WHEN] An Account Statistics update is first pushed
        CRMStatisticsJob.CreateOrUpdateCRMAccountStatistics(Customer, CRMAccount);

        // [THEN] The CRM Account is not marked as modified since last synch by its Integration Record
        Assert.IsFalse(CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(
            CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn),
          'Modifying CRM Account to relate it to CRM Account Statistics should not be reflected in its Integration Record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountStatisticsCreationDoesNotChangeCRMAccountSynchStatusIfModified()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
    begin
        // [FEATURE] [Modified On]
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        // [GIVEN] A coupled and synchronized Customer and CRM Account
        CreateCRMAccountSynchedToCustomer(Customer, CRMAccount);

        // [GIVEN] The CRM Account has been modified since last synch
        CRMAccount.ModifiedOn := CurrentDateTime + 5000L;

        Assert.IsTrue(CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(
            CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn),
          'The CRM Account was modified more than a second since after synch; its Integration Record should know this fact');

        // [WHEN] An Account Statistics update is first pushed
        CRMStatisticsJob.CreateOrUpdateCRMAccountStatistics(Customer, CRMAccount);

        // [THEN] The CRM Account is still marked as modified since last synch by its Integration Record
        Assert.IsTrue(CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(
            CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn),
          'Modifying CRM Account to relate it to CRM Account Statistics should not change the CRM modified state in its Integration Record');
    end;

    [Test]
    [HandlerFunctions('IntegrationSynchJobListModalHandler')]
    [Scope('OnPrem')]
    procedure AccountStatisticsJobFailsOnDeletedCustomerCRMAccount()
    var
        CRMAccount: array[2] of Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: array[2] of Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        Customer: array[2] of Record Customer;
        JobQueueLogEntriesPage: TestPage "Job Queue Log Entries";
        DummyRecID: RecordID;
        ActualFailed: Integer;
        ActualFinishDateTime: DateTime;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Statistics Job is shown as failed in the synch job if the Customer was deleted
        Initialize();
        CRMIntegrationRecord.DeleteAll();
        // [GIVEN] Customer 'A' is coupled to CRM Account 'B', but Customer 'A' is deleted
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[1], CRMAccount[1]);
        // [GIVEN] Customer 'C' is coupled to CRM Account 'D', but CRM Account 'D' is deleted
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[2], CRMAccount[2]);

        CRMIntegrationRecord.SetRange("Table ID", DATABASE::Customer);
        CRMIntegrationRecord.FindFirst(); // Sorting of CRMIntegrationRecord affects results
        FindRecsFromCRMIntegrationRec(CRMIntegrationRecord, Customer[1], CRMAccount[1]);
        CRMIntegrationRecord.Delete();
        Customer[1].Delete();
        CRMIntegrationRecord.Insert();

        CRMIntegrationRecord.FindLast();
        FindRecsFromCRMIntegrationRec(CRMIntegrationRecord, Customer[2], CRMAccount[2]);
        CRMIntegrationRecord.Delete();
        CRMAccount[2].Delete();
        CRMIntegrationRecord.Insert();

        // [WHEN] Run Account Statistics update
        IntegrationSynchJob[1].DeleteAll();
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Statistics Job");
        JobQueueEntry.FindFirst();
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] CRM Synch. Log Entry 'L' for Account Statistics update, where "Failed" = 2
        IntegrationSynchJob[1].Failed := 2;
        // [THEN] CRM Synch. Log Entry for Invoice Status update, where "Modified" = 0
        IntegrationSynchJob[2].Modified := 0;
        VerifyIntegrationSynchJobs(CODEUNIT::"CRM Statistics Job", IntegrationSynchJob);
        // [THEN] Integration Synch. Log Error, where "Source Record ID" is empty, "Destination Record ID" = CRM Account 'B'
        IntegrationSynchJobErrors.TestField("Source Record ID", DummyRecID);
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", IntegrationSynchJob[1].ID);
        IntegrationSynchJobErrors.FindFirst();
        IntegrationSynchJobErrors.TestField("Destination Record ID", CRMAccount[1].RecordId);
        // [THEN] Integration Synch. Log Error, where "Source Record ID" = Customer 'C', "Destination Record ID" is empty
        IntegrationSynchJobErrors.FindLast();
        IntegrationSynchJobErrors.TestField("Source Record ID", Customer[2].RecordId);
        IntegrationSynchJobErrors.TestField("Destination Record ID", DummyRecID);
        // [THEN] Job Queue Log Entry, where "Status" is 'Success', "Error Message" is <blank>
        JobQueueLogEntry.Get(IntegrationSynchJob[1]."Job Queue Log Entry No.");
        JobQueueLogEntry.TestField(Status, JobQueueLogEntry.Status::Success);
        JobQueueLogEntry.TestField("Error Message", '');

        // [WHEN] run action "Details" on page "Job Queue Log Entries"
        JobQueueLogEntriesPage.OpenView();
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.FindLast();
        JobQueueLogEntriesPage.GotoRecord(JobQueueLogEntry);
        JobQueueLogEntriesPage.Details.Invoke();

        // [THEN] Open modal "Integration Synch. Job List" page showing the synch. log entry 'L'
        ActualFailed := LibraryVariableStorage.DequeueInteger(); // returned by IntegrationSynchJobListModalHandler
        Assert.AreEqual(IntegrationSynchJob[1].Failed, ActualFailed, 'Failed in IntegrationSynchJobList');
        ActualFinishDateTime := LibraryVariableStorage.DequeueDateTime();
        Assert.AreEqual(IntegrationSynchJob[1]."Finish Date/Time", ActualFinishDateTime, 'Finish Date-Time in IntegrationSynchJobList');
    end;

    [Test]
    [HandlerFunctions('NotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AccountStatisticsJobUpdatesInvoiceStatusFullyPaid()
    var
        CRMSynchStatus: Record "CRM Synch Status";
        CRMInvoice: Record "CRM Invoice";
        CRMAccount: Record "CRM Account";
        IntegrationSynchJob: array[2] of Record "Integration Synch. Job";
        JobQueueEntry: Record "Job Queue Entry";
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        RemainingAmount: Decimal;
    begin
        // [FEATURE] [Invoice] [Status]
        Initialize();

        // [GIVEN] Posted Sales Invoice '1032' is synchronized with CRM Invoice, where StateCode is 'Active', StatusCode is 'Billed'
        CreateBilledCRMInvoice(Customer, SalesInvHeader, CRMAccount, CRMInvoice);
        DtldCustLedgEntry.FindLast();

        // [GIVEN] Apply a full payment to Invoice '1032', so Invoice is closed
        RemainingAmount := PayForInvoice(SalesInvHeader, 1);
        Assert.AreEqual(0, RemainingAmount, 'Remaining Amount should be 0');

        // [WHEN] Run Account Statistics update
        IntegrationSynchJob[1].DeleteAll();
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Statistics Job");
        JobQueueEntry.FindFirst();
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] CRM Invoice, where StateCode is 'Paid', StatusCode is 'Complete'
        CRMInvoice.Find('=');
        CRMInvoice.TestField(StateCode, CRMInvoice.StateCode::Paid);
        CRMInvoice.TestField(StatusCode, CRMInvoice.StatusCode::Complete);
        // [THEN] "Last Update Invoice Entry No." is set to the last detailed cust. ledger entry
        DtldCustLedgEntry.FindLast();
        CRMSynchStatus.Get();
        CRMSynchStatus.TestField("Last Update Invoice Entry No.", DtldCustLedgEntry."Entry No.");
        // [THEN] CRM Synch. Log Entry for Account Statistics update, where "Inserted" = 1
        IntegrationSynchJob[1].Inserted := 1;
        // [THEN] CRM Synch. Log Entry for Invoice Status update, where "Modified" = 1
        IntegrationSynchJob[2].Modified := 1;
        VerifyIntegrationSynchJobs(CODEUNIT::"CRM Statistics Job", IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('NotificationHandler,MessageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AccountStatisticsJobUpdatesInvoiceStatusPartiallyPaid()
    var
        CRMSynchStatus: Record "CRM Synch Status";
        CRMInvoice: Record "CRM Invoice";
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        CustomerCard: TestPage "Customer Card";
        RemainingAmount: Decimal;
        LastEntryNo: Integer;
    begin
        // [FEATURE] [Invoice] [Status] [UI]
        Initialize();
        CRMSynchStatus.Get();
        LastEntryNo := CRMSynchStatus."Last Update Invoice Entry No.";

        // [GIVEN] Posted Sales Invoice '1032' is synchronized with CRM Invoice, where StateCode is 'Active', StatusCode is 'Billed'
        CreateBilledCRMInvoice(Customer, SalesInvHeader, CRMAccount, CRMInvoice);
        DtldCustLedgEntry.FindLast();

        // [GIVEN] Apply a partial payment to Invoice '1032', so Invoice is not closed
        RemainingAmount := PayForInvoice(SalesInvHeader, 0.33);
        Assert.AreNotEqual(0, RemainingAmount, 'Remaining Amount should NOT be 0');

        // [WHEN] Run 'Update Statistics In CRM' action on Customer Card page
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.UpdateStatisticsInCRM.Invoke();

        // [THEN] CRM Invoice, where StateCode is 'Active', StatusCode is 'Partial'
        CRMInvoice.Find('=');
        CRMInvoice.TestField(StateCode, CRMInvoice.StateCode::Paid);
        CRMInvoice.TestField(StatusCode, CRMInvoice.StatusCode::Partial);
        // [THEN] "Last Update Invoice Entry No." is NOT updated
        CRMSynchStatus.Get();
        CRMSynchStatus.TestField("Last Update Invoice Entry No.", LastEntryNo);
    end;

    [Test]
    [HandlerFunctions('NotificationHandler,MessageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AccountStatisticsJobUpdatesInvoiceStatusPartiallyThenFullyPaid()
    var
        CRMSynchStatus: Record "CRM Synch Status";
        CRMInvoice: Record "CRM Invoice";
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        CustomerList: TestPage "Customer List";
        RemainingAmount: Decimal;
        LastEntryNo: Integer;
    begin
        // [FEATURE] [Invoice] [Status] [UI]
        Initialize();
        CRMSynchStatus.Get();
        LastEntryNo := CRMSynchStatus."Last Update Invoice Entry No.";

        // [GIVEN] Posted Sales Invoice '1032' is synchronized with CRM Invoice, where StateCode is 'Active', StatusCode is 'Billed'
        CreateBilledCRMInvoice(Customer, SalesInvHeader, CRMAccount, CRMInvoice);
        DtldCustLedgEntry.FindLast();

        // [GIVEN] Apply a partial payment to Invoice '1032'
        RemainingAmount := PayForInvoice(SalesInvHeader, 0.33);
        Assert.AreNotEqual(0, RemainingAmount, 'Remaining Amount should NOT be 0');
        // [WHEN] Run 'Update Statistics In CRM' action on Customer List page
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);
        CustomerList.UpdateStatisticsInCRM.Invoke();

        // [GIVEN] Apply a full payment to Invoice '1032'
        RemainingAmount := PayForInvoice(SalesInvHeader, 1);
        Assert.AreEqual(0, RemainingAmount, 'Remaining Amount should be 0');

        // [WHEN] Run 'Update Statistics In CRM' action on Customer List page
        CustomerList.UpdateStatisticsInCRM.Invoke();

        // [THEN] CRM Invoice, where StateCode is 'Paid', StatusCode is 'Complete'
        CRMInvoice.Find('=');
        CRMInvoice.TestField(StateCode, CRMInvoice.StateCode::Paid);
        CRMInvoice.TestField(StatusCode, CRMInvoice.StatusCode::Complete);
        // [THEN] "Last Update Invoice Entry No." is NOT updated
        CRMSynchStatus.Get();
        CRMSynchStatus.TestField("Last Update Invoice Entry No.", LastEntryNo);
    end;

    [Test]
    [HandlerFunctions('NotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AccountStatisticsJobUpdatesInvoiceStatusFullyPaidThenUnapplied()
    var
        CRMInvoice: Record "CRM Invoice";
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
        RemainingAmount: Decimal;
    begin
        // [FEATURE] [Invoice] [Status]
        Initialize();

        // [GIVEN] Posted Sales Invoice '1032' is synchronized with CRM Invoice, where StateCode is 'Active', StatusCode is 'Billed'
        CreateBilledCRMInvoice(Customer, SalesInvHeader, CRMAccount, CRMInvoice);
        DtldCustLedgEntry.FindLast();

        // [GIVEN] Apply a full payment to Invoice '1032', so Invoice is closed
        RemainingAmount := PayForInvoice(SalesInvHeader, 1);
        Assert.AreEqual(0, RemainingAmount, 'Remaining Amount should be 0');
        // [GIVEN] Run Account Statistics update
        CRMStatisticsJob.UpdateStatusOfPaidInvoices('');

        // [GIVEN] Unapply the payment and invoice
        DtldCustLedgEntry.FindLast();
        CustLedgerEntry.Get(DtldCustLedgEntry."Cust. Ledger Entry No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // [WHEN] Run Account Statistics update
        CRMStatisticsJob.UpdateStatusOfPaidInvoices('');

        // [THEN] CRM Invoice, where StateCode is 'Active', StatusCode is 'Billed'
        CRMInvoice.Find('=');
        CRMInvoice.TestField(StateCode, CRMInvoice.StateCode::Active);
        CRMInvoice.TestField(StatusCode, CRMInvoice.StatusCode::Billed);
    end;

    [Test]
    [HandlerFunctions('NotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure AccountStatisticsJobUpdatesCanceledInvoice()
    var
        CRMInvoice: Record "CRM Invoice";
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
        RemainingAmount: Decimal;
    begin
        // [FEATURE] [Invoice] [Status]
        Initialize();

        // [GIVEN] Posted Sales Invoice '1032' is synchronized with CRM Invoice, where StateCode is 'Canceled', StatusCode is 'Canceled'
        CreateBilledCRMInvoice(Customer, SalesInvHeader, CRMAccount, CRMInvoice);
        CRMInvoice.StateCode := CRMInvoice.StateCode::Canceled;
        CRMInvoice.StatusCode := CRMInvoice.StatusCode::Canceled;
        CRMInvoice.Modify();

        // [GIVEN] Apply a full payment to Invoice '1032', so Invoice is closed
        RemainingAmount := PayForInvoice(SalesInvHeader, 1);
        Assert.AreEqual(0, RemainingAmount, 'Remaining Amount should be 0');

        // [WHEN] Run Account Statistics update
        CRMStatisticsJob.UpdateStatusOfPaidInvoices(Customer."No.");

        // [THEN] CRM Invoice, where StateCode is 'Paid', StatusCode is 'Complete'
        CRMInvoice.Find('=');
        CRMInvoice.TestField(StateCode, CRMInvoice.StateCode::Paid);
        CRMInvoice.TestField(StatusCode, CRMInvoice.StatusCode::Complete);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CouplingGetsSkippedIfCRMAccountRemoved()
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Customer: Record Customer;
        JobQueueEntry: Record "Job Queue Entry";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        // [FEATURE] [UT] [Skipped Record] [Deleted Couplings]
        // [SCENARIO] CRM Statistics Job marks the deleted coupling as skipped if CRM Account is deleted
        Initialize();
        // [GIVEN] Customer coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] CRM Account is deleted
        CRMAccount.Delete();

        // [WHEN] Account Statistics Job is running
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Statistics Job");
        JobQueueEntry.FindFirst();
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] The coupling marked as "Skipped", error message is 'CRM Account is not found'
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord.TestField(Skipped, true);
        Assert.IsTrue(CRMIntegrationRecord.GetLatestError(IntegrationSynchJobErrors), 'sync error should be found');
        Assert.ExpectedMessage(WasNotFoundErr, IntegrationSynchJobErrors.Message);
    end;

    [Test]
    [HandlerFunctions('BlankIntegrationSynchJobListModalHandler')]
    [Scope('OnPrem')]
    procedure JobQueueFailsIfCRMConnectionDisabled()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        CRMProductName: Codeunit "CRM Product Name";
        JobQueueLogEntriesPage: TestPage "Job Queue Log Entries";
        IsSynchLogEntryFound: Boolean;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] CRM Statistics Job is shown as failed in the synch job if the CRM connection is not enabled
        Initialize();
        // [GIVEN] CRM Connection setup is disabled
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is Enabled" := false;
        CRMConnectionSetup.Modify();
        // [GIVEN] JOb Queue Entry for CRM Statistics is ready, "Maximum No. of Attempts to Run" = 0
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"CRM Statistics Job");
        JobQueueEntry.FindFirst();
        JobQueueEntry."Maximum No. of Attempts to Run" := 0;
        JobQueueEntry.Modify();
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);

        // [WHEN] Run Account Statistics update
        CODEUNIT.Run(CODEUNIT::"Job Queue Dispatcher", JobQueueEntry);

        // [THEN] the Job Queue Entry, where Status is 'Error', "Error Message" is 'CRM connection is not enabled'
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::Error);
        Assert.ExpectedMessage(StrSubstNo(ConnectionNotEnabledErr, CRMProductName.FULL()), JobQueueEntry."Error Message");

        // [WHEN] run action "Details" on page "Job Queue Log Entries"
        JobQueueLogEntriesPage.OpenView();
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.FindLast();
        JobQueueLogEntriesPage.GotoRecord(JobQueueLogEntry);
        JobQueueLogEntriesPage.Details.Invoke();

        // [THEN] Open modal "Integration Synch. Job List" page showing no log entries
        IsSynchLogEntryFound := LibraryVariableStorage.DequeueBoolean(); // returned by BlankIntegrationSynchJobListModalHandler
        Assert.IsFalse(IsSynchLogEntryFound, 'IntegrationSynchJobList should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonCRMJobQueueLogDetailsShowsNoCRMSyncLog()
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueLogEntriesPage: TestPage "Job Queue Log Entries";
    begin
        // [FEATURE] [Job Queue Log Entry] [UI] [UT]
        // [SCENARIO] "Details" action on "Job Queue Log Entries page" should not show CRM Synch. log,
        // [SCENARIO] if the job is not CRM related.
        Initialize();
        // [GIVEN] JobQueueLogEntry, where "Entry No" = 'X', "Object To Run" = CODEUNIT::"Sales Post via Job Queue"
        JobQueueLogEntry.DeleteAll();
        JobQueueLogEntry."Entry No." := 0; // to autoincrement
        JobQueueLogEntry."Object Type to Run" := JobQueueLogEntry."Object Type to Run"::Codeunit;
        JobQueueLogEntry."Object ID to Run" := CODEUNIT::"Sales Post via Job Queue";
        JobQueueLogEntry.Insert();

        // [GIVEN] Integration Synch. Job, where "Job Queue Log Entry No." = 'X'
        IntegrationSynchJob.ID := CreateGuid();
        IntegrationSynchJob."Job Queue Log Entry No." := JobQueueLogEntry."Entry No.";
        IntegrationSynchJob.Insert();

        // [WHEN] run action "Details" on page "Job Queue Log Entries"
        JobQueueLogEntriesPage.OpenView();
        JobQueueLogEntriesPage.Details.Invoke();

        // [THEN] "Integration Synch. Job List" page is not open
        // verified by lack of ModalHandler
    end;

    local procedure Initialize()
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.InitializeCRMSynchStatus();
        ResetDefaultCRMSetupConfiguration();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
    end;

    local procedure CreateBilledCRMInvoice(var Customer: Record Customer; var SalesInvHeader: Record "Sales Invoice Header"; var CRMAccount: Record "CRM Account"; var CRMInvoice: Record "CRM Invoice")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        PostSalesInvoice(SalesInvHeader, Customer."No.");
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        SalesInvHeader.SetRange(SystemId, SalesInvHeader.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::"Sales Invoice Header", SalesInvHeader.GetView(), IntegrationTableMapping);

        CRMIntegrationRecord.FindByRecordID(SalesInvHeader.RecordId);
        CRMInvoice.Get(CRMIntegrationRecord."CRM ID");
        CRMInvoice.TestField(StateCode, CRMInvoice.StateCode::Active);
        CRMInvoice.TestField(StatusCode, CRMInvoice.StatusCode::Billed);
    end;

    local procedure CreateCRMAccountSynchedToCustomer(var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CUSTOMER');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMAccount.AccountId, true, false);
    end;

    local procedure FindRecsFromCRMIntegrationRec(CRMIntegrationRecord: Record "CRM Integration Record"; var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        RecRef: RecordRef;
        RecID: RecordID;
    begin
        CRMIntegrationRecord.FindRecordIDFromID(CRMIntegrationRecord."CRM ID", DATABASE::Customer, RecID);
        RecRef.Get(RecID);
        RecRef.SetTable(Customer);
        RecRef.Close();
        CRMAccount.Get(CRMIntegrationRecord."CRM ID");
    end;

    local procedure ResetDefaultCRMSetupConfiguration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ClientSecret: Text;
    begin
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    local procedure PayForInvoice(SalesInvHeader: Record "Sales Invoice Header"; PaymentPart: Decimal): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CustLedgerEntry.SetRange("Document No.", SalesInvHeader."No.");
        CustLedgerEntry.FindLast();
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibrarySales.CreatePaymentAndApplytoInvoice(
          GenJournalLine, CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.",
          -CustLedgerEntry."Remaining Amount" * PaymentPart);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CustLedgerEntry.Find('=');
        CustLedgerEntry.CalcFields("Remaining Amount");
        exit(CustLedgerEntry."Remaining Amount");
    end;

    local procedure PostSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
        AddGLAccSalesLine(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure AddGLAccSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure VerifyIntegrationSynchJobs(ObjectIDtoRun: Integer; var ExpectedIntegrationSynchJob: array[2] of Record "Integration Synch. Job")
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
    begin
        JobQueueLogEntry.SetRange("Object ID to Run", ObjectIDtoRun);
        JobQueueLogEntry.FindLast();
        IntegrationSynchJob.SetCurrentKey("Start Date/Time");
        IntegrationSynchJob.SetRange("Job Queue Log Entry No.", JobQueueLogEntry."Entry No.");
        IntegrationSynchJob.SetRange(Message, CRMStatisticsJob.GetAccStatsUpdateFinalMessage());
        IntegrationSynchJob.FindFirst();
        VerifyIntegrationSynchJob(IntegrationSynchJob, ExpectedIntegrationSynchJob[1], Format(JobQueueLogEntry."Object ID to Run"));
        IntegrationSynchJob.SetRange(Message, CRMStatisticsJob.GetInvStatusUpdateFinalMessage());
        IntegrationSynchJob.FindFirst();
        VerifyIntegrationSynchJob(IntegrationSynchJob, ExpectedIntegrationSynchJob[2], Format(JobQueueLogEntry."Object ID to Run"));
    end;

    local procedure VerifyIntegrationSynchJob(IntegrationSynchJob: Record "Integration Synch. Job"; var ExpectedIntegrationSynchJob: Record "Integration Synch. Job"; MappingName: Text)
    begin
        IntegrationSynchJob.TestField("Integration Table Mapping Name", MappingName);
        IntegrationSynchJob.TestField("Synch. Direction", IntegrationSynchJob."Synch. Direction"::ToIntegrationTable);
        IntegrationSynchJob.TestField(Modified, ExpectedIntegrationSynchJob.Modified);
        IntegrationSynchJob.TestField(Inserted, ExpectedIntegrationSynchJob.Inserted);
        IntegrationSynchJob.TestField(Failed, ExpectedIntegrationSynchJob.Failed);
        ExpectedIntegrationSynchJob := IntegrationSynchJob;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure NotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BlankIntegrationSynchJobListModalHandler(var IntegrationSynchJobListPage: TestPage "Integration Synch. Job List")
    begin
        LibraryVariableStorage.Enqueue(IntegrationSynchJobListPage.First());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IntegrationSynchJobListModalHandler(var IntegrationSynchJobListPage: TestPage "Integration Synch. Job List")
    begin
        Assert.IsTrue(IntegrationSynchJobListPage.Last(), 'Most earlier record in IntegrationSynchJobList');
        LibraryVariableStorage.Enqueue(IntegrationSynchJobListPage.Failed.AsInteger());
        LibraryVariableStorage.Enqueue(IntegrationSynchJobListPage."Finish Date/Time".AsDateTime());
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

