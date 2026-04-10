codeunit 139199 "CDS Match Based Coupling"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CDS Integration] [Match Based Coupling]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConfirmCouplingInBackgroundTxt: Label 'You are about to couple records in Business Central table with records in the integration table from the selected mapping, based on the matching criteria that you must define.\The coupling will run in the background, so you can continue with other tasks.\\Do you want to continue?';
        CouplingScheduledTxt: Label 'Match-based coupling is scheduled. \Details are available on the Integration Synchronization Jobs page.', Comment = '%1 = mapping name';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,MatchBasedCouplingModalPageDefaultHandler')]
    [Scope('OnPrem')]
    procedure IntegarionTableMappingListCoupleSingleInBackground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CoupledCustomer: array[3] of Record Customer;
        CoupledCRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: Record Customer;
        UncoupledCRMAccount: Record "CRM Account";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
        IntegrationSynchJobList: TestPage "Integration Synch. Job List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected records in background
        Initialize();
        UncoupledCustomer.Reset();
        UncoupledCustomer.DeleteAll();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CoupledCRMAccount);

        // [GIVEN] The uncoupled Customer
        LibrarySales.CreateCustomer(UncoupledCustomer);
        UncoupledCustomer."Phone No." := LibraryUtility.GenerateRandomNumericText(8);
        UncoupledCustomer.Modify();

        // [GIVEN] The uncoupled CRM Account, make the phone number match with BC customer phone no.
        LibraryCRMIntegration.CreateCRMAccount(UncoupledCRMAccount);
        UncoupledCRMAccount.Telephone1 := UncoupledCustomer."Phone No.";
        UncoupledCRMAccount.Modify();

        // [GIVEN] Open "Integration Table Mapping List" page, where 'CUSTOMER' is selected
        IntegrationTableMappingList.OpenEdit();
        IntegrationTableMappingList.FindFirstField(Name, 'CUSTOMER');

        // [WHEN] Invoking the Match-Based Coupling action
        IntegrationTableMappingList.MatchBasedCoupling.Invoke();

        // [THEN] User confirmed coupling
        Assert.ExpectedMessage(ConfirmCouplingInBackgroundTxt, LibraryVariableStorage.DequeueText()); // by ConfirmHandler

        // [THEN] Coupling job has been created
        VerifyCouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateCouplingJobsExecution();

        // [THEN] The coupling is retained for the coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is created for the previously uncoupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer.RecordId()), 'The record should be coupled.');

        // [THEN] Message is shown that coupling is scheduled
        Assert.ExpectedMessage(StrSubstNo(CouplingScheduledTxt, 1), LibraryVariableStorage.DequeueText()); // by MessageHandler

        // [THEN] 1 coupled records are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Coupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);

        // [WHEN] Invoking action "Integration Coupling Job Log"
        IntegrationSynchJobList.Trap();
        IntegrationTableMappingList."View Integration Coupling Job Log".Invoke();

        // [THEN] "Integration Synch. Job List" page is open and presents correct values in the first line
        Assert.AreEqual(IntegrationSynchJob.Type::Coupling, IntegrationSynchJobList."Type".AsInteger(), 'Incorrect job type');
        Assert.AreEqual(1, IntegrationSynchJobList.Coupled.AsInteger(), 'Incorrect count of coupled');

        // [WHEN] The synch job is executed
        SimulateSynchJobsExecution();

        // [THEN] The post-coupling synch job resolved the name conflict in favor of BC value
        UncoupledCRMAccount.Get(UncoupledCRMAccount.AccountId);
        Assert.AreEqual(UncoupledCustomer.Name, UncoupledCRMAccount.Name, 'The coupled customers names must be equal.');

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,MatchBasedCouplingModalPageDefaultHandler')]
    [Scope('OnPrem')]
    procedure IntegarionTableMappingListCoupleMultipleInBackground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CoupledCustomer: array[3] of Record Customer;
        CoupledCRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: array[5] of Record Customer;
        UncoupledCRMAccount: array[5] of Record "CRM Account";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
        IntegrationSynchJobList: TestPage "Integration Synch. Job List";
        i: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected records in background
        Initialize();
        UncoupledCustomer[1].Reset();
        UncoupledCustomer[1].DeleteAll();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CoupledCRMAccount);

        // [GIVEN] The uncoupled Customers
        for i := 1 to 5 do begin
            LibrarySales.CreateCustomer(UncoupledCustomer[i]);
            UncoupledCustomer[i]."Phone No." := LibraryUtility.GenerateRandomNumericText(8);
            UncoupledCustomer[i].Modify();

            // [GIVEN] The uncoupled CRM Accounts and make the phone number match with BC customer phone no.
            LibraryCRMIntegration.CreateCRMAccount(UncoupledCRMAccount[i]);
            UncoupledCRMAccount[i].Telephone1 := UncoupledCustomer[i]."Phone No.";
            UncoupledCRMAccount[i].Modify();
        end;

        // [GIVEN] Open "Integration Table Mapping List" page, where 'CUSTOMER' is selected
        IntegrationTableMappingList.OpenEdit();
        IntegrationTableMappingList.FindFirstField(Name, 'CUSTOMER');

        // [WHEN] Invoking the Match-Based Coupling action
        IntegrationTableMappingList.MatchBasedCoupling.Invoke();

        // [THEN] User confirmed coupling
        Assert.ExpectedMessage(ConfirmCouplingInBackgroundTxt, LibraryVariableStorage.DequeueText()); // by ConfirmHandler

        // [THEN] Coupling job has been created
        VerifyCouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateCouplingJobsExecution();

        // [THEN] The coupling is retained for the coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is created for the previously uncoupled records
        for i := 1 to 5 do
            Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[i].RecordId()), 'The record should be coupled.');

        // [THEN] Message is shown that coupling is scheduled
        Assert.ExpectedMessage(StrSubstNo(CouplingScheduledTxt, 1), LibraryVariableStorage.DequeueText()); // by MessageHandler

        // [THEN] 1 coupled records are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Coupled := 5;
        VerifyIntegrationSynchJob(IntegrationSynchJob);

        // [WHEN] Invoking action "Integration Coupling Job Log"
        IntegrationSynchJobList.Trap();
        IntegrationTableMappingList."View Integration Coupling Job Log".Invoke();

        // [THEN] "Integration Synch. Job List" page is open and presents correct values in the first line
        Assert.AreEqual(IntegrationSynchJob.Type::Coupling, IntegrationSynchJobList."Type".AsInteger(), 'Incorrect job type');
        Assert.AreEqual(5, IntegrationSynchJobList.Coupled.AsInteger(), 'Incorrect count of coupled');

        // [WHEN] The synch job is executed
        SimulateSynchJobsExecution();

        // [THEN] The post-coupling synch job resolved the name conflict in favor of BC value
        for i := 1 to 5 do begin
            UncoupledCRMAccount[i].Get(UncoupledCRMAccount[i].AccountId);
            Assert.AreEqual(UncoupledCustomer[i].Name, UncoupledCRMAccount[i].Name, 'The coupled customers names must be equal.');
        end;

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MatchBasedCouplingModalPageDefaultHandler')]
    [Scope('OnPrem')]
    procedure MasterDataListCoupleSingleInBackground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CoupledCustomer: array[3] of Record Customer;
        CoupledCRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: array[5] of Record Customer;
        UncoupledCRMAccount: array[5] of Record "CRM Account";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        SelectedCustomer: Record Customer;
        SelectedRecordRef: RecordRef;
        i: Integer;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected records in background
        Initialize();
        UncoupledCustomer[1].Reset();
        UncoupledCustomer[1].DeleteAll();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CoupledCRMAccount);

        // [GIVEN] The uncoupled Customers
        for i := 1 to 5 do begin
            LibrarySales.CreateCustomer(UncoupledCustomer[i]);
            UncoupledCustomer[i]."Phone No." := LibraryUtility.GenerateRandomNumericText(8);
            UncoupledCustomer[i].Modify();

            // [GIVEN] The uncoupled CRM Accounts and make the phone number match with BC customer phone no.
            LibraryCRMIntegration.CreateCRMAccount(UncoupledCRMAccount[i]);
            UncoupledCRMAccount[i].Telephone1 := UncoupledCustomer[i]."Phone No.";
            UncoupledCRMAccount[i].Modify();
        end;

        // [WHEN] Invoking the Match-Based Coupling action on the list page when the coupled and uncoupled records are selected
        SelectedRecordRef.GetTable(SelectedCustomer);
        SelectedIds.Add(UncoupledCustomer[2].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMIntegrationManagement.MatchBasedCoupling(SelectedRecordRef);

        // [THEN] Coupling job has been created
        VerifyCouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateCouplingJobsExecution();

        // [THEN] The coupling is retained for the coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is created for the previously uncoupled records
        for i := 1 to 5 do
            if i = 2 then
                Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[i].RecordId()), 'The record should be coupled.')
            else
                Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[i].RecordId()), 'The record should be uncoupled.');

        // [THEN] 1 coupled records are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Coupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);

        // [WHEN] The synch job is executed
        SimulateSynchJobsExecution();

        // [THEN] The post-coupling synch job resolved the name conflict in favor of BC value
        for i := 1 to 5 do begin
            UncoupledCRMAccount[i].Get(UncoupledCRMAccount[i].AccountId);
            if i = 2 then
                Assert.AreEqual(UncoupledCustomer[i].Name, UncoupledCRMAccount[i].Name, 'The coupled customers names must be equal.')
            else
                Assert.AreNotEqual(UncoupledCustomer[i].Name, UncoupledCRMAccount[i].Name, 'The uncoupled customers names must not be equal.')
        end;

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MatchBasedCouplingModalPageDefaultHandler')]
    [Scope('OnPrem')]
    procedure MasterDataListCoupleMultipleInBackground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CoupledCustomer: array[3] of Record Customer;
        CoupledCRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: array[5] of Record Customer;
        UncoupledCRMAccount: array[5] of Record "CRM Account";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        SelectedCustomer: Record Customer;
        SelectedRecordRef: RecordRef;
        i: Integer;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected records in background
        Initialize();
        UncoupledCustomer[1].Reset();
        UncoupledCustomer[1].DeleteAll();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CoupledCRMAccount);

        // [GIVEN] The uncoupled Customers
        for i := 1 to 5 do begin
            LibrarySales.CreateCustomer(UncoupledCustomer[i]);
            UncoupledCustomer[i]."Phone No." := LibraryUtility.GenerateRandomNumericText(8);
            UncoupledCustomer[i].Modify();

            // [GIVEN] The uncoupled CRM Accounts and make the phone number match with BC customer phone no.
            LibraryCRMIntegration.CreateCRMAccount(UncoupledCRMAccount[i]);
            UncoupledCRMAccount[i].Telephone1 := UncoupledCustomer[i]."Phone No.";
            UncoupledCRMAccount[i].Modify();
        end;

        // [WHEN] Invoking the Match-Based Coupling action on the list page when the coupled and uncoupled records are selected
        SelectedRecordRef.GetTable(SelectedCustomer);
        SelectedIds.Add(CoupledCustomer[1].SystemId, true);
        SelectedIds.Add(CoupledCustomer[3].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[1].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[2].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[3].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[4].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[5].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMIntegrationManagement.MatchBasedCoupling(SelectedRecordRef);

        // [THEN] Coupling job has been created
        VerifyCouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateCouplingJobsExecution();

        // [THEN] The coupling is retained for the coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is created for the previously uncoupled records
        for i := 1 to 5 do
            Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[i].RecordId()), 'The record should be coupled.');

        // [THEN] 1 coupled records are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Coupled := 5;
        VerifyIntegrationSynchJob(IntegrationSynchJob);

        // [WHEN] The synch job is executed
        SimulateSynchJobsExecution();

        // [THEN] The post-coupling synch job resolved the name conflict in favor of BC value
        for i := 1 to 5 do begin
            UncoupledCRMAccount[i].Get(UncoupledCRMAccount[i].AccountId);
            Assert.AreEqual(UncoupledCustomer[i].Name, UncoupledCRMAccount[i].Name, 'The coupled customers names must be equal.');
        end;

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MatchBasedCouplingModalPageDefaultHandler')]
    [Scope('OnPrem')]
    procedure MasterDataListCoupleMultipleErrorNoMatch()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CoupledCustomer: array[3] of Record Customer;
        CoupledCRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: array[5] of Record Customer;
        UncoupledCRMAccount: array[5] of Record "CRM Account";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        SelectedCustomer: Record Customer;
        SelectedRecordRef: RecordRef;
        i: Integer;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected records in background
        Initialize();
        UncoupledCustomer[1].Reset();
        UncoupledCustomer[1].DeleteAll();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CoupledCRMAccount);

        // [GIVEN] The uncoupled Customers
        for i := 1 to 5 do begin
            LibrarySales.CreateCustomer(UncoupledCustomer[i]);
            UncoupledCustomer[i]."Phone No." := LibraryUtility.GenerateRandomNumericText(8);
            UncoupledCustomer[i].Modify();

            // [GIVEN] The uncoupled CRM Accounts and make the phone number match with BC customer phone no. on two of them, but not on three of them
            LibraryCRMIntegration.CreateCRMAccount(UncoupledCRMAccount[i]);
            if i <= 2 then begin
                UncoupledCRMAccount[i].Telephone1 := UncoupledCustomer[i]."Phone No.";
                UncoupledCRMAccount[i].Modify();
            end
        end;

        // [WHEN] Invoking the Match-Based Coupling action on the list page when the coupled and uncoupled records are selected
        SelectedRecordRef.GetTable(SelectedCustomer);
        SelectedIds.Add(UncoupledCustomer[1].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[2].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[3].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[4].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[5].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMIntegrationManagement.MatchBasedCoupling(SelectedRecordRef);

        // [THEN] Coupling job has been created
        VerifyCouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateCouplingJobsExecution();

        // [THEN] The coupling is retained for the coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is created for the previously uncoupled records with a match
        for i := 1 to 2 do
            Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[i].RecordId()), 'The record should be coupled.');

        // [THEN] The coupling is not created for the previously uncoupled records with no match
        for i := 3 to 5 do
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[i].RecordId()), 'The record should not be coupled.');

        // [THEN] 1 coupled records are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Coupled := 2;
        IntegrationSynchJob.Failed := 3;
        VerifyIntegrationSynchJob(IntegrationSynchJob);

        // [WHEN] The synch job is executed
        SimulateSynchJobsExecution();

        // [THEN] The post-coupling synch job resolved the name conflict in favor of BC value
        for i := 1 to 2 do begin
            UncoupledCRMAccount[i].Get(UncoupledCRMAccount[i].AccountId);
            Assert.AreEqual(UncoupledCustomer[i].Name, UncoupledCRMAccount[i].Name, 'The coupled customers names must be equal.');
        end;

        for i := 3 to 5 do begin
            UncoupledCRMAccount[i].Get(UncoupledCRMAccount[i].AccountId);
            Assert.AreNotEqual(UncoupledCustomer[i].Name, UncoupledCRMAccount[i].Name, 'The uncoupled customers names must not be equal.');
        end;

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MatchBasedCouplingModalPageDefaultHandler')]
    [Scope('OnPrem')]
    procedure MasterDataListCoupleMultipleErrorInconclusiveMatch()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CoupledCustomer: array[3] of Record Customer;
        CoupledCRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: array[5] of Record Customer;
        UncoupledCRMAccount: array[5] of Record "CRM Account";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        SelectedCustomer: Record Customer;
        SelectedRecordRef: RecordRef;
        i: Integer;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected records in background
        Initialize();
        UncoupledCustomer[1].Reset();
        UncoupledCustomer[1].DeleteAll();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CoupledCRMAccount);

        // [GIVEN] The uncoupled Customers
        for i := 1 to 5 do begin
            LibrarySales.CreateCustomer(UncoupledCustomer[i]);
            UncoupledCustomer[i]."Phone No." := LibraryUtility.GenerateRandomNumericText(8);
            UncoupledCustomer[i].Modify();

            // [GIVEN] The uncoupled CRM Accounts and make the phone number be equal to first uncoupled BC customer's phone on all of them
            LibraryCRMIntegration.CreateCRMAccount(UncoupledCRMAccount[i]);
            UncoupledCRMAccount[i].Telephone1 := UncoupledCustomer[1]."Phone No.";
            UncoupledCRMAccount[i].Modify();
        end;

        // [WHEN] Invoking the Match-Based Coupling action on the list page when the coupled and uncoupled records are selected
        SelectedRecordRef.GetTable(SelectedCustomer);
        SelectedIds.Add(UncoupledCustomer[1].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[2].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[3].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[4].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[5].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMIntegrationManagement.MatchBasedCoupling(SelectedRecordRef);

        // [THEN] Coupling job has been created
        VerifyCouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateCouplingJobsExecution();

        // [THEN] The coupling is retained for the coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is not created for the previously uncoupled records with no match or with inconclusive match (multiple matches for first uncoupled BC customer)
        for i := 1 to 5 do
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[i].RecordId()), 'The record should not be coupled.');

        // [THEN] 1 coupled records are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Failed := 5;
        VerifyIntegrationSynchJob(IntegrationSynchJob);

        // [WHEN] The synch job is executed
        SimulateSynchJobsExecution();

        // [THEN] The post-coupling synch job didn't run because no records were coupled.
        for i := 1 to 5 do begin
            UncoupledCRMAccount[i].Get(UncoupledCRMAccount[i].AccountId);
            Assert.AreNotEqual(UncoupledCustomer[i].Name, UncoupledCRMAccount[i].Name, 'The uncoupled customers names must not be equal.');
        end;

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MatchBasedCouplingModalPageCancelHandler')]
    [Scope('OnPrem')]
    procedure MasterDataListNoCouplingRunsIfUserCancels()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CoupledCustomer: array[3] of Record Customer;
        CoupledCRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: array[5] of Record Customer;
        UncoupledCRMAccount: array[5] of Record "CRM Account";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        SelectedCustomer: Record Customer;
        SelectedRecordRef: RecordRef;
        i: Integer;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected records in background
        Initialize();
        UncoupledCustomer[1].Reset();
        UncoupledCustomer[1].DeleteAll();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CoupledCRMAccount);

        // [GIVEN] The uncoupled Customers
        for i := 1 to 5 do begin
            LibrarySales.CreateCustomer(UncoupledCustomer[i]);
            UncoupledCustomer[i]."Phone No." := LibraryUtility.GenerateRandomNumericText(8);
            UncoupledCustomer[i].Modify();

            // [GIVEN] The uncoupled CRM Accounts and make the phone number be equal to first uncoupled BC customer's phone on all of them
            LibraryCRMIntegration.CreateCRMAccount(UncoupledCRMAccount[i]);
            UncoupledCRMAccount[i].Telephone1 := UncoupledCustomer[i]."Phone No.";
            UncoupledCRMAccount[i].Modify();
        end;

        // [WHEN] Invoking the Match-Based Coupling action on the list page when the coupled and uncoupled records are selected
        SelectedRecordRef.GetTable(SelectedCustomer);
        SelectedIds.Add(UncoupledCustomer[1].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[2].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[3].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[4].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[5].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMIntegrationManagement.MatchBasedCoupling(SelectedRecordRef);

        // [THEN] Coupling job has not been created
        VerifyCouplingJobQueueEntryCount(0);

        // [WHEN] The job is attempted executed, but it wasn't executed
        SimulateCouplingJobsExecution();

        // [THEN] The coupling is retained for the coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is not created for the previously uncoupled records, because user canceled
        for i := 1 to 5 do
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[i].RecordId()), 'The record should not be coupled.');

        // [WHEN] The synch job is attempted executed (but there is none)
        SimulateSynchJobsExecution();

        // [THEN] The post-coupling synch job didn't run because no records were coupled.
        for i := 1 to 5 do begin
            UncoupledCRMAccount[i].Get(UncoupledCRMAccount[i].AccountId);
            Assert.AreNotEqual(UncoupledCustomer[i].Name, UncoupledCRMAccount[i].Name, 'The uncoupled customers names must not be equal.');
        end;

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MatchBasedCouplingModalPageDefaultHandler')]
    [Scope('OnPrem')]
    procedure MasterDataListCouplingRunsButNoSynchByUserChoice()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CoupledCustomer: array[3] of Record Customer;
        CoupledCRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: array[5] of Record Customer;
        UncoupledCRMAccount: array[5] of Record "CRM Account";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        SelectedCustomer: Record Customer;
        SelectedRecordRef: RecordRef;
        i: Integer;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected records in background
        Initialize();
        UncoupledCustomer[1].Reset();
        UncoupledCustomer[1].DeleteAll();
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Synch. After Bulk Coupling" := false;
        IntegrationTableMapping.Modify();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CoupledCRMAccount);

        // [GIVEN] The uncoupled Customers
        for i := 1 to 5 do begin
            LibrarySales.CreateCustomer(UncoupledCustomer[i]);
            UncoupledCustomer[i]."Phone No." := LibraryUtility.GenerateRandomNumericText(8);
            UncoupledCustomer[i].Modify();

            // [GIVEN] The uncoupled CRM Accounts and make the phone number be equal to first uncoupled BC customer's phone on all of them
            LibraryCRMIntegration.CreateCRMAccount(UncoupledCRMAccount[i]);
            UncoupledCRMAccount[i].Telephone1 := UncoupledCustomer[i]."Phone No.";
            UncoupledCRMAccount[i].Modify();
        end;

        // [WHEN] Invoking the Match-Based Coupling action on the list page when the coupled and uncoupled records are selected
        SelectedRecordRef.GetTable(SelectedCustomer);
        SelectedIds.Add(UncoupledCustomer[1].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[2].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[3].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[4].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[5].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMIntegrationManagement.MatchBasedCoupling(SelectedRecordRef);

        // [THEN] Coupling job has been created
        VerifyCouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateCouplingJobsExecution();

        // [THEN] The coupling is retained for the coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is created for the previously uncoupled records
        for i := 1 to 5 do
            Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[i].RecordId()), 'The record should not be coupled.');

        // [WHEN] The synch job is executed (but it actually doesn't exist because the user chose so)
        SimulateSynchJobsExecution();

        // [THEN] The post-coupling synch job didn't run because user chose so
        for i := 1 to 5 do begin
            UncoupledCRMAccount[i].Get(UncoupledCRMAccount[i].AccountId);
            Assert.AreNotEqual(UncoupledCustomer[i].Name, UncoupledCRMAccount[i].Name, 'The uncoupled customers names must not be equal.');
        end;

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        CDSCompany: Record "CDS Company";
        MyNotifications: Record "My Notifications";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Customer: Record Customer;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is Enabled" := false;
        CRMConnectionSetup.Modify();
        InitializeCDSConnectionSetup();
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup.Modify();
        CDSConnectionSetup.Get();
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID(), '', '', false);
        RemoveCouplingJobQueueEntries();
        CDSIntegrationImpl.ResetCache();
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Update-Conflict Resolution" := IntegrationTableMapping."Update-Conflict Resolution"::"Send Update to Integration";
        IntegrationTableMapping."Synch. After Bulk Coupling" := true;
        IntegrationTableMapping.Modify();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.ModifyAll("Use For Match-Based Coupling", false);
        IntegrationFieldMapping.ModifyAll("Case-Sensitive Matching", false);
        IntegrationFieldMapping.SetRange("Field No.", Customer.FieldNo("Phone No."));
        IntegrationFieldMapping.FindFirst();
        IntegrationFieldMapping."Use For Match-Based Coupling" := true;
        IntegrationFieldMapping.Modify();
    end;

    local procedure InitializeCDSConnectionSetup()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        ClientSecret: Text;
    begin
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
    end;

    local procedure CreateCoupledCustomers(var Customer: array[3] of Record Customer; var CRMAccount: array[3] of Record "CRM Account")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            CreateCoupledCustomer(Customer[I], CRMAccount[I]);
    end;

    local procedure CreateCoupledCustomer(var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        RecordRef: RecordRef;
    begin
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        RecordRef.GetTable(CRMAccount);
        CDSIntegrationImpl.SetCompanyId(RecordRef);
        RecordRef.Modify();
        CRMAccount.Find();
        Assert.IsFalse(IsNullGuid(CRMAccount.CompanyId), 'The company ID must be set for CRM Account.');
    end;

    local procedure MockSetSelectionFilter(var SelectedRecordRef: RecordRef; SelectedSystemIds: Dictionary of [Guid, Boolean])
    var
        RecordSystemId: Guid;
    begin
        SelectedRecordRef.Reset();
        if SelectedRecordRef.FindSet() then
            repeat
                RecordSystemId := SelectedRecordRef.Field(SelectedRecordRef.SystemIdNo).Value();
                if SelectedSystemIds.ContainsKey(RecordSystemId) then
                    SelectedRecordRef.Mark(true);
            until SelectedRecordRef.Next() = 0;
        SelectedRecordRef.MarkedOnly(true);
        Assert.AreEqual(SelectedSystemIds.Count(), SelectedRecordRef.Count(), 'Unexpected number of selected records');
    end;

    local procedure SimulateCouplingJobsExecution()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type To Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Int. Coupling Job Runner");
        JobQueueEntry.SetCurrentKey(SystemCreatedAt);
        JobQueueEntry.Ascending();
        if JobQueueEntry.FindLast() then
            Codeunit.Run(Codeunit::"Int. Coupling Job Runner", JobQueueEntry);
    end;

    local procedure SimulateSynchJobsExecution()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type To Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetCurrentKey(SystemCreatedAt);
        JobQueueEntry.Ascending();
        if JobQueueEntry.FindLast() then
            Codeunit.Run(Codeunit::"Integration Synch. Job Runner", JobQueueEntry);
    end;

    local procedure VerifyCouplingJobQueueEntryCount(ExpectedCount: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Int. Coupling Job Runner");
        Assert.AreEqual(ExpectedCount, JobQueueEntry.Count(), 'Unexpected job count');
    end;

    local procedure VerifyIntegrationSynchJob(var ExpectedIntegrationSynchJob: Record "Integration Synch. Job")
    var
        TempIntegrationSynchJob: Record "Integration Synch. Job" temporary;
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        TempIntegrationSynchJob."Integration Table Mapping Name" := ExpectedIntegrationSynchJob."Integration Table Mapping Name";
        TempIntegrationSynchJob.Insert();
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        IntegrationSynchJob.SetRange(Type, IntegrationSynchJob.Type::Coupling);
        Assert.IsTrue(IntegrationSynchJob.FindSet(), 'Cannot find the integration coupling job.');
        repeat
            TempIntegrationSynchJob.Inserted += IntegrationSynchJob.Inserted;
            TempIntegrationSynchJob.Modified += IntegrationSynchJob.Modified;
            TempIntegrationSynchJob.Deleted += IntegrationSynchJob.Deleted;
            TempIntegrationSynchJob.Failed += IntegrationSynchJob.Failed;
            TempIntegrationSynchJob.Skipped += IntegrationSynchJob.Skipped;
            TempIntegrationSynchJob.Unchanged += IntegrationSynchJob.Unchanged;
            TempIntegrationSynchJob.Uncoupled += IntegrationSynchJob.Uncoupled;
            TempIntegrationSynchJob.Coupled += IntegrationSynchJob.Coupled;
            TempIntegrationSynchJob.Modify();
        until IntegrationSynchJob.Next() = 0;
        Assert.AreEqual(TempIntegrationSynchJob.Uncoupled, ExpectedIntegrationSynchJob.Uncoupled, 'Incorrect count of Uncoupled for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Coupled, ExpectedIntegrationSynchJob.Coupled, 'Incorrect count of Coupled for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Modified, ExpectedIntegrationSynchJob.Modified, 'Incorrect count of Modified for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Inserted, ExpectedIntegrationSynchJob.Inserted, 'Incorrect count of Inserted for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Deleted, ExpectedIntegrationSynchJob.Deleted, 'Incorrect count of Deleted for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Failed, ExpectedIntegrationSynchJob.Failed, 'Incorrect count of Failed for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Skipped, ExpectedIntegrationSynchJob.Skipped, 'Incorrect count of Skipped for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Unchanged, ExpectedIntegrationSynchJob.Unchanged, 'Incorrect count of Unchanged for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
    end;

    local procedure RemoveCouplingJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Int. Coupling Job Runner");
        JobQueueEntry.DeleteTasks();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
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
    procedure MatchBasedCouplingModalPageDefaultHandler(var MatchBasedCouplingCriteria: TestPage "Match Based Coupling Criteria")
    begin
        MatchBasedCouplingCriteria.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MatchBasedCouplingModalPageCancelHandler(var MatchBasedCouplingCriteria: TestPage "Match Based Coupling Criteria")
    begin
        MatchBasedCouplingCriteria.Cancel().Invoke();
    end;
}