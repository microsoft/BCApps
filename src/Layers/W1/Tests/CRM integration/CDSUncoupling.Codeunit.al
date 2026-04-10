codeunit 139198 "CDS Uncoupling"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CDS Integration] [Uncoupling]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        ConfirmUncouplingInBackgroundTxt: Label 'You are about to uncouple the selected mappings, which means data for the records will no longer synchronize.\The uncoupling will run in the background, so you can continue with other tasks.\\Do you want to continue?';
        ConfirmUncouplingInForegroundTxt: Label 'You are about to uncouple the selected mappings, which means data for the records will no longer synchronize.\\Do you want to continue?';
        UncouplingScheduledTxt: Label 'Uncoupling is scheduled for %1 mappings. \Details are available on the Integration Synchronization Jobs page.', Comment = '%1 = mapping name';
        UncouplingCompletedTxt: Label 'Uncoupling completed.';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure IntegarionTableMappingListUncoupleSingleInBackground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CoupledCustomer: array[3] of Record Customer;
        CoupledCRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: Record Customer;
        UncoupledCRMAccount: Record "CRM Account";
        RecordRef: RecordRef;
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
        IntegrationSynchJobList: TestPage "Integration Synch. Job List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected records in background
        Initialize();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CoupledCRMAccount);

        // [GIVEN] The uncoupled Customer
        LibrarySales.CreateCustomer(UncoupledCustomer);

        // [GIVEN] The uncoupled CRM Account with stuck Company ID
        LibraryCRMIntegration.CreateCRMAccount(UncoupledCRMAccount);
        RecordRef.GetTable(UncoupledCRMAccount);
        CDSIntegrationImpl.SetCompanyId(RecordRef);
        RecordRef.Modify();
        UncoupledCRMAccount.Find();
        Assert.IsFalse(IsNullGuid(UncoupledCRMAccount.CompanyId), 'The company ID must be set for the uncoupled record.');

        // [GIVEN] Open "Integration Table Mapping List" page, where 'CUSTOMER' is selected
        IntegrationTableMappingList.OpenEdit();
        IntegrationTableMappingList.FindFirstField(Name, 'CUSTOMER');

        // [WHEN] Invoking the Delete Coupling action
        IntegrationTableMappingList.RemoveCoupling.Invoke();

        // [THEN] User confirmed uncoupling
        Assert.ExpectedMessage(ConfirmUncouplingInBackgroundTxt, LibraryVariableStorage.DequeueText()); // by ConfirmHandler

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed for the coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling is missing for the uncoupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] CompanyId field is reset on just uncoupled CRM Accounts
        CoupledCRMAccount[1].Find();
        CoupledCRMAccount[2].Find();
        CoupledCRMAccount[3].Find();
        Assert.IsTrue(IsNullGuid(CoupledCRMAccount[1].CompanyId), 'The company ID must be empty for record 1.');
        Assert.IsTrue(IsNullGuid(CoupledCRMAccount[2].CompanyId), 'The company ID must be empty for record 2.');
        Assert.IsTrue(IsNullGuid(CoupledCRMAccount[3].CompanyId), 'The company ID must be empty for record 3.');

        // [THEN] Stuck Company ID has been reset on uncoupled CDS entity
        UncoupledCRMAccount.Find();
        Assert.IsTrue(IsNullGuid(UncoupledCRMAccount.CompanyId), 'The company ID must be empty for the uncoupled record.');

        // [THEN] Message is shown that uncoupling is scheduled
        Assert.ExpectedMessage(StrSubstNo(UncouplingScheduledTxt, 1), LibraryVariableStorage.DequeueText()); // by MessageHandler

        // [THEN] 2 uncoupled and 3 modified (+1 with stuck company ID) records are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Modified := 4;
        IntegrationSynchJob.Uncoupled := 3;
        VerifyIntegrationSynchJob(IntegrationSynchJob);

        // [WHEN] Invoking action "Integration Uncouple Job Log"
        IntegrationSynchJobList.Trap();
        IntegrationTableMappingList."View Integration Uncouple Job Log".Invoke();

        // [THEN] "Integration Synch. Job List" page is open and presents correct values in the first line
        Assert.AreEqual(IntegrationSynchJob.Type::Uncoupling, IntegrationSynchJobList."Type".AsInteger(), 'Incorrect count of uncoupled');
        Assert.AreEqual(3, IntegrationSynchJobList.Uncoupled.AsInteger(), 'Incorrect count of uncoupled');

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure IntegarionTableMappingListUncoupleSingleInForeground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        UncoupledSalespersonPurchaser: Record "Salesperson/Purchaser";
        CoupledSalespersonPurchaser: array[3] of Record "Salesperson/Purchaser";
        CRMSystemuser: array[3] of Record "CRM Systemuser";
        IntegrationTableMappingList: TestPage "Integration Table Mapping List";
        IntegrationSynchJobList: TestPage "Integration Synch. Job List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in foreground
        Initialize();

        // [GIVEN] The coupled Salespersons and CRM Systemusers
        CreateCoupledSalespersons(CoupledSalespersonPurchaser, CRMSystemuser);

        // [GIVEN] The uncoupled Salespersons
        LibrarySales.CreateSalesperson(UncoupledSalespersonPurchaser);

        // [GIVEN] Open "Integration Table Mapping List" page, where 'CUSTOMER' is selected
        IntegrationTableMappingList.OpenEdit();
        IntegrationTableMappingList.FindFirstField(Name, 'SALESPEOPLE');

        // [WHEN] Invoking the Delete Coupling action
        IntegrationTableMappingList.RemoveCoupling.Invoke();

        // [THEN] User confirmed uncoupling
        Assert.ExpectedMessage(ConfirmUncouplingInForegroundTxt, LibraryVariableStorage.DequeueText()); // by ConfirmHandler

        // [THEN] Uncoupling was running in foreground
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling is removed for the coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledSalespersonPurchaser[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledSalespersonPurchaser[2].RecordId()), 'The record 2 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledSalespersonPurchaser[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling is missing for the uncoupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledSalespersonPurchaser.RecordId()), 'The record should be uncoupled.');

        // [THEN] Message is shown that uncoupling is completed
        Assert.ExpectedMessage(UncouplingCompletedTxt, LibraryVariableStorage.DequeueText()); // by MessageHandler

        // [THEN] No Integration Synch. Job
        Assert.IsTrue(IntegrationSynchJob.IsEmpty(), 'Unexpected Integration Synch. Job');

        // [WHEN] Invoking action "Integration Uncouple Job Log"
        IntegrationSynchJobList.Trap();
        IntegrationTableMappingList."View Integration Uncouple Job Log".Invoke();

        // [THEN] There is nothing on the Integration Synch. Jobs page
        Assert.IsFalse(IntegrationSynchJobList.First(), 'List must be empty.');

        // [THEN] All handlers processed
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntegarionTableMappingListUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SelectedIntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        Item: array[3] of Record Item;
        CRMProduct: array[3] of Record "CRM Product";
        Currency: Record Currency;
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
        I: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in background
        Initialize();

        // [GIVEN] The coupled records for different mappings
        CreateCoupledCustomer(Customer, CRMAccount);
        CreateCoupledSalesperson(SalespersonPurchaser, CRMSystemuser);
        CreateCoupledItems(Item, CRMProduct);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        CreateCoupledOpportunity(Opportunity, CRMOpportunity);

        // [WHEN] Selected mappings for Customer, Item and Salespeople, and unselecte for Currency and Opportunity
        IntegrationTableMapping.FindMappingForTable(Database::Customer);
        SelectedIds.Add(IntegrationTableMapping.SystemId, true);
        IntegrationTableMapping.FindMappingForTable(Database::Item);
        SelectedIds.Add(IntegrationTableMapping.SystemId, true);
        IntegrationTableMapping.FindMappingForTable(Database::"Salesperson/Purchaser");
        SelectedIds.Add(IntegrationTableMapping.SystemId, true);
        SelectedRecordRef.GetTable(SelectedIntegrationTableMapping);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);

        // [WHEN] Simulate Delete Coupling action
        SelectedRecordRef.FindSet();
        repeat
            SelectedRecordRef.SetTable(SelectedIntegrationTableMapping);
            CRMIntegrationManagement.RemoveCoupling(SelectedIntegrationTableMapping."Table ID", SelectedIntegrationTableMapping."Integration Table ID");
        until SelectedRecordRef.Next() = 0;

        // [THEN] Uncoupling jobs are created for customers and items, no job for salespeople (foreground uncoupling)
        VerifyUncouplingJobQueueEntryCount(2);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] Couplings are removed for the selected mappings
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Customer.RecordId()), 'The Customer should be uncoupled.');
        Customer.Find();
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser.RecordId()), 'The Salesperson should be uncoupled.');
        for I := 1 to 3 do
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item[I].RecordId()), 'The Item should be uncoupled.');

        // [THEN] Couplings are remaining for the non-selected mappings
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Opportunity.RecordId()), 'The Opportunity should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Currency.RecordId()), 'The Currency should be coupled.');

        // [THEN] CompanyId field is reset for the selected mppings
        CRMAccount.Find();
        Assert.IsTrue(IsNullGuid(CRMAccount.CompanyId), 'The company ID must be empty for the CRM Account.');
        for I := 1 to 3 do begin
            CRMProduct[I].Find();
            Assert.IsTrue(IsNullGuid(CRMProduct[I].CompanyId), 'The company ID must be empty for the CRM Product.');
        end;

        // [THEN] CompanyId field is still set on the non-selected mappings
        CRMOpportunity.Find();
        Assert.IsFalse(IsNullGuid(CRMOpportunity.CompanyId), 'The company ID must be set for the CRM Opportunity.');

        // [THEN] Correct counters for uncoupled and modified records are logged in Integration Synch. Job
        Assert.AreEqual(2, IntegrationSynchJob.Count(), 'Unexpected synch job count.');
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
        IntegrationSynchJob."Integration Table Mapping Name" := 'ITEM-PRODUCT';
        IntegrationSynchJob.Modified := 3;
        IntegrationSynchJob.Uncoupled := 3;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSkippedRecordsUncoupleSingleInBackground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Item: array[3] of Record Item;
        CRMProduct: array[3] of Record "CRM Product";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        IntegrationSynchJobList: TestPage "Integration Synch. Job List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in background
        Initialize();

        // [GIVEN] Coupled Items and CRM Products are skipped for synchronization.
        MockSkippedItems(Item, CRMProduct);

        // [GIVEN] Open "CRM Skipped Records" page, where the second Item is selected
        CRMSkippedRecords.OpenEdit();
        CRMSkippedRecords.FindFirstField(Description, Item[2]."No.");

        // [WHEN] Invoking the Delete Coupling action
        CRMSkippedRecords.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed for the selected single record
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The selected record is not in the list of skipped records
        Assert.IsFalse(CRMSkippedRecords.FindFirstField(Description, Item[2]."No."), 'The record 2 should dissapear from the page.');

        // [THEN] The coupling remains for non-selected records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[3].RecordId()), 'The record 3 should be coupled.');

        // [THEN] The non-selected records should still be in the list
        Assert.IsTrue(CRMSkippedRecords.FindFirstField(Description, Item[1]."No."), 'The record 1 should be in the list.');
        Assert.IsTrue(CRMSkippedRecords.FindFirstField(Description, Item[3]."No."), 'The record 3 should be in the list.');

        // [THEN] CompanyId field is reset on the selected record
        CRMProduct[2].Find();
        Assert.IsTrue(IsNullGuid(CRMProduct[2].CompanyId), 'The company ID must be empty for record 2.');

        // [THEN] CompanyId field has a value on the non-selected record
        CRMProduct[1].Find();
        CRMProduct[3].Find();
        Assert.IsFalse(IsNullGuid(CRMProduct[1].CompanyId), 'The company ID must be not empty for record 1.');
        Assert.IsFalse(IsNullGuid(CRMProduct[3].CompanyId), 'The company ID must be not empty for record 3.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'ITEM-PRODUCT';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);

        // [WHEN] Invoking action "Integration Uncouple Job Log"
        IntegrationSynchJobList.Trap();
        CRMSkippedRecords.ShowUncouplingLog.Invoke();

        // [THEN] "Integration Synch. Job List" page is open and presents correct values in the first line
        Assert.AreEqual(IntegrationSynchJob.Type::Uncoupling, IntegrationSynchJobList."Type".AsInteger(), 'Incorrect count of uncoupled');
        Assert.AreEqual(1, IntegrationSynchJobList.Uncoupled.AsInteger(), 'Incorrect count of uncoupled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSkippedRecordsUncoupleSingleInForeground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SalespersonPurchaser: array[3] of Record "Salesperson/Purchaser";
        CRMSystemuser: array[3] of Record "CRM Systemuser";
        CRMSkippedRecords: TestPage "CRM Skipped Records";
        IntegrationSynchJobList: TestPage "Integration Synch. Job List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in foreground
        Initialize();

        // [GIVEN] Coupled Salespersons are skipped for synchronization.
        MockSkippedSalespersons(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] Open "CRM Skipped Records" page, where the second record is selected
        CRMSkippedRecords.OpenEdit();
        CRMSkippedRecords.FindFirstField(Description, SalespersonPurchaser[2].Code);

        // [WHEN] Invoking the Delete Coupling action
        CRMSkippedRecords.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has not been created
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling is removed for the selected single record
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The selected record is not in the list of skipped records
        Assert.IsFalse(CRMSkippedRecords.FindFirstField(Description, SalespersonPurchaser[2].Code), 'The record 2 should dissapear from the page.');

        // [THEN] The coupling remains for non-selected records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[3].RecordId()), 'The record 3 should be coupled.');

        // [THEN] The non-selected records should still be in the list
        Assert.IsTrue(CRMSkippedRecords.FindFirstField(Description, SalespersonPurchaser[1].Code), 'The record 1 should be in the list.');
        Assert.IsTrue(CRMSkippedRecords.FindFirstField(Description, SalespersonPurchaser[3].Code), 'The record 3 should be in the list.');

        // [THEN] No Integration Synch. Job
        Assert.IsTrue(IntegrationSynchJob.IsEmpty(), 'Unexpected Integration Synch. Job');

        // [WHEN] Invoking action "Integration Uncouple Job Log"
        IntegrationSynchJobList.Trap();
        CRMSkippedRecords.ShowUncouplingLog.Invoke();

        // [THEN] There is nothing on the Integration Synch. Jobs page
        Assert.IsFalse(IntegrationSynchJobList.First(), 'List must be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSkippedRecordsUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Item: array[3] of Record Item;
        CRMProduct: array[3] of Record "CRM Product";
        ExtraItem: Record Item;
        ExtraCRMProduct: Record "CRM Product";
        Customer: array[3] of Record Customer;
        CRMAccount: array[3] of Record "CRM Account";
        ExtraCustomer: Record Customer;
        ExtraCRMAccount: Record "CRM Account";
        SalespersonPurchaser: array[3] of Record "Salesperson/Purchaser";
        CRMSystemuser: array[3] of Record "CRM Systemuser";
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        SelectedLocalIds: Dictionary of [Guid, Boolean];
        I: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records from different mappings
        Initialize();

        // [GIVEN] Coupled records are skipped for synchronization.
        MockSkippedItems(Item, CRMProduct);
        MockSkippedCustomers(Customer, CRMAccount);
        MockSkippedSalespersons(SalespersonPurchaser, CRMSystemuser);
        MockSkippedItem(ExtraItem, ExtraCRMProduct);
        MockSkippedCustomer(ExtraCustomer, ExtraCRMAccount);

        // [WHEN] 11 skipped records, among them one is deleted in BC, 1 is deleted in CDS
        for I := 1 to 2 do begin
            SelectedLocalIds.Add(Item[I].SystemId, true);
            SelectedLocalIds.Add(Customer[I].SystemId, true);
            SelectedLocalIds.Add(SalespersonPurchaser[I].SystemId, true);
        end;
        SelectedLocalIds.Add(ExtraItem.SystemId, true);
        SelectedLocalIds.Add(ExtraCustomer.SystemId, true);
        ExtraCustomer.Delete();
        ExtraCRMProduct.Delete();

        // [WHEN] Selected 6 of 11 skipped records, among them one is deleted in BC, 1 is deleted in CDS
        CRMIntegrationRecord.Reset();
        CRMIntegrationRecord.SetRange(Skipped, true);
        Assert.AreEqual(11, TempCRMSynchConflictBuffer.Fill(CRMIntegrationRecord), 'Unexpected number of skipped couplings');
        MockSetSelectionFilter(TempCRMSynchConflictBuffer, SelectedLocalIds);

        // [WHEN] Simulate Delete Coupling action
        TempCRMSynchConflictBuffer.DeleteCouplings();

        // [THEN] Uncoupling jobs are created for customers and items, no job for salespeople (foreground uncoupling)
        VerifyUncouplingJobQueueEntryCount(3);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] Couplings are removed for the selected records
        for I := 1 to 2 do begin
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Customer[I].RecordId()), 'The Customer should be uncoupled.');
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[I].RecordId()), 'The Salesperson should be uncoupled.');
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item[I].RecordId()), 'The Item should be uncoupled.');
        end;
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(ExtraCustomer.RecordId()), 'The Customer should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(ExtraItem.RecordId()), 'The Item should be uncoupled.');

        // [THEN] Couplings are remaining for the non-selected records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Customer[3].RecordId()), 'The Customer should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[3].RecordId()), 'The Salesperson should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[3].RecordId()), 'The Item should be coupled.');

        // [THEN] CompanyId field is reset for the selected records
        for I := 1 to 2 do begin
            CRMAccount[I].Find();
            CRMProduct[I].Find();
            Assert.IsTrue(IsNullGuid(CRMAccount[I].CompanyId), 'The company ID must be empty for the CRM Account.');
            Assert.IsTrue(IsNullGuid(CRMProduct[I].CompanyId), 'The company ID must be empty for the CRM Product.');
        end;
        ExtraCRMAccount.Find();
        Assert.IsTrue(IsNullGuid(ExtraCRMAccount.CompanyId), 'The company ID must be empty for the CRM Account.');

        // [THEN] CompanyId field is set for the non-selected records
        CRMAccount[3].Find();
        CRMProduct[3].Find();
        Assert.IsFalse(IsNullGuid(CRMAccount[3].CompanyId), 'The company ID must be set for the CRM Account.');
        Assert.IsFalse(IsNullGuid(CRMProduct[3].CompanyId), 'The company ID must be set for the CRM Product.');

        // [THEN] Correct counters for uncoupled and modified records are logged in Integration Synch. Job
        Assert.AreEqual(3, IntegrationSynchJob.Count(), 'Unexpected synch job count.');
        IntegrationSynchJob.Init();
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Modified := 3;
        IntegrationSynchJob.Uncoupled := 3;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
        IntegrationSynchJob.Init();
        IntegrationSynchJob."Integration Table Mapping Name" := 'ITEM-PRODUCT';
        IntegrationSynchJob.Modified := 2;
        IntegrationSynchJob.Uncoupled := 3;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerListUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SelectedCustomer: Record Customer;
        CoupledCustomer: array[3] of Record Customer;
        CRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: array[2] of Record Customer;
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in background
        Initialize();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CRMAccount);

        // [GIVEN] The uncoupled Customers
        LibrarySales.CreateCustomer(UncoupledCustomer[1]);
        LibrarySales.CreateCustomer(UncoupledCustomer[2]);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        SelectedRecordRef.GetTable(SelectedCustomer);
        SelectedIds.Add(CoupledCustomer[1].SystemId, true);
        SelectedIds.Add(CoupledCustomer[3].SystemId, true);
        SelectedIds.Add(UncoupledCustomer[2].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMCouplingManagement.RemoveCoupling(SelectedRecordRef);

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed for the selected coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling exists for non-selected coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is missing for the uncoupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[1].RecordId()), 'The record 4 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[2].RecordId()), 'The record 5 should be uncoupled.');

        // [THEN] CompanyId field is reset on the selected records
        CRMAccount[1].Find();
        CRMAccount[3].Find();
        Assert.IsTrue(IsNullGuid(CRMAccount[1].CompanyId), 'The company ID must be empty for record 1.');
        Assert.IsTrue(IsNullGuid(CRMAccount[3].CompanyId), 'The company ID must be empty for record 3.');

        // [THEN] CompanyId field is set on the non-selected records
        CRMAccount[2].Find();
        Assert.IsFalse(IsNullGuid(CRMAccount[2].CompanyId), 'The company ID must be set for record 2.');

        // [THEN] 2 uncoupled and 2 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Modified := 2;
        IntegrationSynchJob.Uncoupled := 2;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerListUncoupleSingle()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CoupledCustomer: array[3] of Record Customer;
        CRMAccount: array[3] of Record "CRM Account";
        UncoupledCustomer: array[2] of Record Customer;
        CustomerList: TestPage "Customer List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in background
        Initialize();

        // [GIVEN] The coupled Customers and CRM Accounts
        CreateCoupledCustomers(CoupledCustomer, CRMAccount);

        // [GIVEN] The uncoupled Customers
        LibrarySales.CreateCustomer(UncoupledCustomer[1]);
        LibrarySales.CreateCustomer(UncoupledCustomer[2]);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        CustomerList.OpenView();
        CustomerList.FindFirstField("No.", CoupledCustomer[2]."No.");
        CustomerList.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledCustomer[3].RecordId()), 'The record 3 should be coupled.');

        // [THEN] The coupling is missing for the uncoupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[1].RecordId()), 'The record 4 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledCustomer[2].RecordId()), 'The record 5 should be uncoupled.');

        // [THEN] CompanyId field is reset on the selected record
        CRMAccount[2].Find();
        Assert.IsTrue(IsNullGuid(CRMAccount[2].CompanyId), 'The company ID must be empty for record 2.');

        // [THEN] CompanyId field is set on the non-selected record
        CRMAccount[1].Find();
        CRMAccount[3].Find();
        Assert.IsFalse(IsNullGuid(CRMAccount[1].CompanyId), 'The company ID must be set for record 1.');
        Assert.IsFalse(IsNullGuid(CRMAccount[3].CompanyId), 'The company ID must be set for record 3.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardUncouple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the record in background
        Initialize();

        // [GIVEN] The coupled Customer and CRM Account
        CreateCoupledCustomer(Customer, CRMAccount);

        // [WHEN] Open the Customer Card page
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Invoking the Delete Coupling action
        CustomerCard.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Customer.RecordId()), 'The record should be uncoupled.');

        // [THEN] CompanyId field is reset on CRM Account
        CRMAccount.Find();
        Assert.IsTrue(IsNullGuid(CRMAccount.CompanyId), 'The company ID must be empty.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalespersonsPurchasersUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SelectedSalespersonPurchaser: Record "Salesperson/Purchaser";
        CoupledSalespersonPurchaser: array[3] of Record "Salesperson/Purchaser";
        CRMSystemuser: array[3] of Record "CRM Systemuser";
        UncoupledSalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in foreground
        Initialize();

        // [GIVEN] The coupled Salespersons and CRM Systemusers
        CreateCoupledSalespersons(CoupledSalespersonPurchaser, CRMSystemuser);

        // [GIVEN] The uncoupled Salespersons
        LibrarySales.CreateSalesperson(UncoupledSalespersonPurchaser[1]);
        LibrarySales.CreateSalesperson(UncoupledSalespersonPurchaser[2]);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        SelectedRecordRef.GetTable(SelectedSalespersonPurchaser);
        SelectedIds.Add(CoupledSalespersonPurchaser[1].SystemId, true);
        SelectedIds.Add(CoupledSalespersonPurchaser[3].SystemId, true);
        SelectedIds.Add(UncoupledSalespersonPurchaser[2].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMCouplingManagement.RemoveCoupling(SelectedRecordRef);

        // [THEN] Uncoupling was running in foreground
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling for the selected records is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledSalespersonPurchaser[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CoupledSalespersonPurchaser[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling for non-selected record is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CoupledSalespersonPurchaser[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] The coupling is missing for the uncoupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledSalespersonPurchaser[1].RecordId()), 'The record 4 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UncoupledSalespersonPurchaser[2].RecordId()), 'The record 5 should be uncoupled.');

        // [THEN] No Integration Synch. Job
        Assert.IsTrue(IntegrationSynchJob.IsEmpty(), 'Unexpected Integration Synch. Job');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalespersonsPurchasersUncoupleSingle()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SalespersonPurchaser: array[5] of Record "Salesperson/Purchaser";
        CRMSystemuser: array[3] of Record "CRM Systemuser";
        SalespersonsPurchasers: TestPage "Salespersons/Purchasers";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in foreground
        Initialize();

        // [GIVEN] The coupled Salesperson and CRM Systemuser
        // [GIVEN] The coupled Salespersons and CRM Systemusers
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[1], CRMSystemuser[1]);
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[2], CRMSystemuser[2]);
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[3], CRMSystemuser[3]);

        // [GIVEN] The uncoupled Salespersons
        LibrarySales.CreateSalesperson(SalespersonPurchaser[4]);
        LibrarySales.CreateSalesperson(SalespersonPurchaser[5]);

        // [WHEN] Open the List page
        SalespersonsPurchasers.OpenView();
        SalespersonsPurchasers.FindFirstField(Code, SalespersonPurchaser[2].Code);

        // [WHEN] Invoking the Delete Coupling action
        SalespersonsPurchasers.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling was running in foreground
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[3].RecordId()), 'The record 3 should be coupled.');

        // [THEN] The coupling is missing for the uncoupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[4].RecordId()), 'The record 4 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[5].RecordId()), 'The record 5 should be uncoupled.');

        // [THEN] No Integration Synch. Job
        Assert.IsTrue(IntegrationSynchJob.IsEmpty(), 'Unexpected Integration Synch. Job');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalespersonsPurchaserCardUncouple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaserCard: TestPage "Salesperson/Purchaser Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the record in foreground
        Initialize();

        // [GIVEN] The coupled Salesperson and CRM Systemuser
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [WHEN] Open the Card page
        SalespersonPurchaserCard.OpenView();
        SalespersonPurchaserCard.GotoRecord(SalespersonPurchaser);

        // [WHEN] Invoking the Delete Coupling action
        SalespersonPurchaserCard.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling was running in foreground
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling was removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser.RecordId()), 'The record should be uncoupled.');

        // [THEN] No Integration Synch. Job
        Assert.IsTrue(IntegrationSynchJob.IsEmpty(), 'Unexpected Integration Synch. Job');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemListUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SelectedItem: Record Item;
        Item: array[3] of Record Item;
        CRMProduct: array[3] of Record "CRM Product";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in background
        Initialize();

        // [GIVEN] The coupled Items
        CreateCoupledItems(Item, CRMProduct);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        SelectedRecordRef.GetTable(SelectedItem);
        SelectedIds.Add(Item[1].SystemId, true);
        SelectedIds.Add(Item[3].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMCouplingManagement.RemoveCoupling(SelectedRecordRef);

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed for the selected coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling exists for non-selected coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] CompanyId field is reset on the selected records
        CRMProduct[1].Find();
        CRMProduct[3].Find();
        Assert.IsTrue(IsNullGuid(CRMProduct[1].CompanyId), 'The company ID must be empty for record 1.');
        Assert.IsTrue(IsNullGuid(CRMProduct[3].CompanyId), 'The company ID must be empty for record 3.');

        // [THEN] CompanyId field is set on the non-selected records
        CRMProduct[2].Find();
        Assert.IsFalse(IsNullGuid(CRMProduct[2].CompanyId), 'The company ID must be set for record 2.');

        // [THEN] 2 uncoupled and 2 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'ITEM-PRODUCT';
        IntegrationSynchJob.Modified := 2;
        IntegrationSynchJob.Uncoupled := 2;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemListUncoupleSingle()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Item: array[3] of Record Item;
        CRMProduct: array[3] of Record "CRM Product";
        ItemList: TestPage "Item List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in background
        Initialize();

        // [GIVEN] The coupled Items
        CreateCoupledItems(Item, CRMProduct);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        ItemList.OpenView();
        ItemList.FindFirstField("No.", Item[2]."No.");
        ItemList.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[3].RecordId()), 'The record 3 should be coupled.');

        // [THEN] CompanyId field is reset on the selected record
        CRMProduct[2].Find();
        Assert.IsTrue(IsNullGuid(CRMProduct[2].CompanyId), 'The company ID must be empty for record 2.');

        // [THEN] CompanyId field is set on the non-selected record
        CRMProduct[1].Find();
        CRMProduct[3].Find();
        Assert.IsFalse(IsNullGuid(CRMProduct[1].CompanyId), 'The company ID must be set for record 1.');
        Assert.IsFalse(IsNullGuid(CRMProduct[3].CompanyId), 'The company ID must be set for record 3.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'ITEM-PRODUCT';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemCardUncouple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the record in background
        Initialize();

        // [GIVEN] The coupled Item
        CreateCoupledItem(Item, CRMProduct);

        // [WHEN] Open the Item Card page
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [WHEN] Invoking the Delete Coupling action
        ItemCard.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item.RecordId()), 'The record should be uncoupled.');

        // [THEN] CompanyId field is reset on CRM Product
        CRMProduct.Find();
        Assert.IsTrue(IsNullGuid(CRMProduct.CompanyId), 'The company ID must be empty.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'ITEM-PRODUCT';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunityListUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SelectedOpportunity: Record Opportunity;
        Opportunity: array[3] of Record Opportunity;
        CRMOpportunity: array[3] of Record "CRM Opportunity";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in background
        Initialize();

        // [GIVEN] The coupled Opportunities
        CreateCoupledOpportunities(Opportunity, CRMOpportunity);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        SelectedRecordRef.GetTable(SelectedOpportunity);
        SelectedIds.Add(Opportunity[1].SystemId, true);
        SelectedIds.Add(Opportunity[3].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMCouplingManagement.RemoveCoupling(SelectedRecordRef);

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed for the selected coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Opportunity[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Opportunity[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling exists for non-selected coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Opportunity[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] CompanyId field is reset on the selected records
        CRMOpportunity[1].Find();
        CRMOpportunity[3].Find();
        Assert.IsTrue(IsNullGuid(CRMOpportunity[1].CompanyId), 'The company ID must be empty for record 1.');
        Assert.IsTrue(IsNullGuid(CRMOpportunity[3].CompanyId), 'The company ID must be empty for record 3.');

        // [THEN] CompanyId field is set on the non-selected records
        CRMOpportunity[2].Find();
        Assert.IsFalse(IsNullGuid(CRMOpportunity[2].CompanyId), 'The company ID must be set for record 2.');

        // [THEN] 2 uncoupled and 2 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'OPPORTUNITY';
        IntegrationSynchJob.Modified := 2;
        IntegrationSynchJob.Uncoupled := 2;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunityListUncoupleSingle()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Opportunity: array[3] of Record Opportunity;
        CRMOpportunity: array[3] of Record "CRM Opportunity";
        OpportunityList: TestPage "Opportunity List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in background
        Initialize();

        // [GIVEN] The coupled Opportunities
        CreateCoupledOpportunities(Opportunity, CRMOpportunity);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        OpportunityList.OpenView();
        OpportunityList.FindFirstField("No.", Opportunity[2]."No.");
        OpportunityList.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Opportunity[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Opportunity[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Opportunity[3].RecordId()), 'The record 3 should be coupled.');

        // [THEN] CompanyId field is reset on the selected record
        CRMOpportunity[2].Find();
        Assert.IsTrue(IsNullGuid(CRMOpportunity[2].CompanyId), 'The company ID must be empty for record 2.');

        // [THEN] CompanyId field is set on the non-selected record
        CRMOpportunity[1].Find();
        CRMOpportunity[3].Find();
        Assert.IsFalse(IsNullGuid(CRMOpportunity[1].CompanyId), 'The company ID must be set for record 1.');
        Assert.IsFalse(IsNullGuid(CRMOpportunity[3].CompanyId), 'The company ID must be set for record 3.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'OPPORTUNITY';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpportunityCardUncouple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the record in background
        Initialize();

        // [GIVEN] The coupled Opportunity
        CreateCoupledOpportunity(Opportunity, CRMOpportunity);

        // [WHEN] Open the Opportunity Card page
        OpportunityCard.OpenEdit();
        OpportunityCard.GotoRecord(Opportunity);

        // [WHEN] Invoking the Delete Coupling action
        OpportunityCard.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Opportunity.RecordId()), 'The record should be uncoupled.');

        // [THEN] CompanyId field is reset on CRM Opportunity
        CRMOpportunity.Find();
        Assert.IsTrue(IsNullGuid(CRMOpportunity.CompanyId), 'The company ID must be empty.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'OPPORTUNITY';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyListUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SelectedCurrency: Record Currency;
        Currency: array[3] of Record Currency;
        CRMTransactioncurrency: array[3] of Record "CRM Transactioncurrency";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in foreground
        Initialize();

        // [GIVEN] The coupled Currencies
        CreateCoupledCurrencies(Currency, CRMTransactioncurrency);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        SelectedRecordRef.GetTable(SelectedCurrency);
        SelectedIds.Add(Currency[1].SystemId, true);
        SelectedIds.Add(Currency[3].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMCouplingManagement.RemoveCoupling(SelectedRecordRef);

        // [THEN] Uncoupling job has not been created
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling is removed for the selected coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Currency[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Currency[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling exists for non-selected coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Currency[2].RecordId()), 'The record 2 should be coupled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyListUncoupleSingle()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Currency: array[3] of Record Currency;
        CRMTransactioncurrency: array[3] of Record "CRM Transactioncurrency";
        Currencies: TestPage Currencies;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in foreground
        Initialize();

        // [GIVEN] The coupled Currencies
        CreateCoupledCurrencies(Currency, CRMTransactioncurrency);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        Currencies.OpenView();
        Currencies.FindFirstField(Code, Currency[2].Code);
        Currencies.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has not been created
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Currency[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Currency[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Currency[3].RecordId()), 'The record 3 should be coupled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCardUncouple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the record in foreground
        Initialize();

        // [GIVEN] The coupled Currency
        CreateCoupledCurrency(Currency, CRMTransactioncurrency);

        // [WHEN] Open the Currency Card page
        CurrencyCard.OpenEdit();
        CurrencyCard.GotoRecord(Currency);

        // [WHEN] Invoking the Delete Coupling action
        CurrencyCard.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has not been created
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Currency.RecordId()), 'The record should be uncoupled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactListUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SelectedContact: Record Contact;
        Contact: array[3] of Record Contact;
        CRMContact: array[3] of Record "CRM Contact";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in background
        Initialize();

        // [GIVEN] The coupled Contacts
        CreateCoupledContacts(Contact, CRMContact);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        SelectedRecordRef.GetTable(SelectedContact);
        SelectedIds.Add(Contact[1].SystemId, true);
        SelectedIds.Add(Contact[3].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMCouplingManagement.RemoveCoupling(SelectedRecordRef);

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed for the selected coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Contact[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Contact[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling exists for non-selected coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Contact[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] CompanyId field is reset on the selected records
        CRMContact[1].Find();
        CRMContact[3].Find();
        Assert.IsTrue(IsNullGuid(CRMContact[1].CompanyId), 'The company ID must be empty for record 1.');
        Assert.IsTrue(IsNullGuid(CRMContact[3].CompanyId), 'The company ID must be empty for record 3.');

        // [THEN] CompanyId field is set on the non-selected records
        CRMContact[2].Find();
        Assert.IsFalse(IsNullGuid(CRMContact[2].CompanyId), 'The company ID must be set for record 2.');

        // [THEN] 2 uncoupled and 2 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'CONTACT';
        IntegrationSynchJob.Modified := 2;
        IntegrationSynchJob.Uncoupled := 2;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactListUncoupleSingle()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Contact: array[3] of Record Contact;
        CRMContact: array[3] of Record "CRM Contact";
        ContactList: TestPage "Contact List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in background
        Initialize();

        // [GIVEN] The coupled Contacts
        CreateCoupledContacts(Contact, CRMContact);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        ContactList.OpenView();
        ContactList.FindFirstField("No.", Contact[2]."No.");
        ContactList.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Contact[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Contact[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Contact[3].RecordId()), 'The record 3 should be coupled.');

        // [THEN] CompanyId field is reset on the selected record
        CRMContact[2].Find();
        Assert.IsTrue(IsNullGuid(CRMContact[2].CompanyId), 'The company ID must be empty for record 2.');

        // [THEN] CompanyId field is set on the non-selected record
        CRMContact[1].Find();
        CRMContact[3].Find();
        Assert.IsFalse(IsNullGuid(CRMContact[1].CompanyId), 'The company ID must be set for record 1.');
        Assert.IsFalse(IsNullGuid(CRMContact[3].CompanyId), 'The company ID must be set for record 3.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'CONTACT';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCardUncouple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the record in background
        Initialize();

        // [GIVEN] The coupled Contact
        CreateCoupledContact(Contact, CRMContact);

        // [WHEN] Open the Contact Card page
        ContactCard.OpenEdit();
        ContactCard.GotoRecord(Contact);

        // [WHEN] Invoking the Delete Coupling action
        ContactCard.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Contact.RecordId()), 'The record should be uncoupled.');

        // [THEN] CompanyId field is reset on CRM Contact
        CRMContact.Find();
        Assert.IsTrue(IsNullGuid(CRMContact.CompanyId), 'The company ID must be empty.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'CONTACT';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceListUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SelectedResource: Record Resource;
        Resource: array[3] of Record Resource;
        CRMProduct: array[3] of Record "CRM Product";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in background
        Initialize();

        // [GIVEN] The coupled Resources
        CreateCoupledResources(Resource, CRMProduct);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        SelectedRecordRef.GetTable(SelectedResource);
        SelectedIds.Add(Resource[1].SystemId, true);
        SelectedIds.Add(Resource[3].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMCouplingManagement.RemoveCoupling(SelectedRecordRef);

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed for the selected coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Resource[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Resource[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling exists for non-selected coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Resource[2].RecordId()), 'The record 2 should be coupled.');

        // [THEN] CompanyId field is reset on the selected records
        CRMProduct[1].Find();
        CRMProduct[3].Find();
        Assert.IsTrue(IsNullGuid(CRMProduct[1].CompanyId), 'The company ID must be empty for record 1.');
        Assert.IsTrue(IsNullGuid(CRMProduct[3].CompanyId), 'The company ID must be empty for record 3.');

        // [THEN] CompanyId field is set on the non-selected records
        CRMProduct[2].Find();
        Assert.IsFalse(IsNullGuid(CRMProduct[2].CompanyId), 'The company ID must be set for record 2.');

        // [THEN] 2 uncoupled and 2 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'RESOURCE-PRODUCT';
        IntegrationSynchJob.Modified := 2;
        IntegrationSynchJob.Uncoupled := 2;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceListUncoupleSingle()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Resource: array[3] of Record Resource;
        CRMProduct: array[3] of Record "CRM Product";
        ResourceList: TestPage "Resource List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in background
        Initialize();

        // [GIVEN] The coupled Resources
        CreateCoupledResources(Resource, CRMProduct);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        ResourceList.OpenView();
        ResourceList.GotoRecord(Resource[2]);
        ResourceList.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Resource[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Resource[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Resource[3].RecordId()), 'The record 3 should be coupled.');

        // [THEN] CompanyId field is reset on the selected record
        CRMProduct[2].Find();
        Assert.IsTrue(IsNullGuid(CRMProduct[2].CompanyId), 'The company ID must be empty for record 2.');

        // [THEN] CompanyId field is set on the non-selected record
        CRMProduct[1].Find();
        CRMProduct[3].Find();
        Assert.IsFalse(IsNullGuid(CRMProduct[1].CompanyId), 'The company ID must be set for record 1.');
        Assert.IsFalse(IsNullGuid(CRMProduct[3].CompanyId), 'The company ID must be set for record 3.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job
        IntegrationSynchJob."Integration Table Mapping Name" := 'RESOURCE-PRODUCT';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceCardUncouple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        ResourceCard: TestPage "Resource Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the record in background
        Initialize();

        // [GIVEN] The coupled Resource
        CreateCoupledResource(Resource, CRMProduct);

        // [WHEN] Open the Resource Card page
        ResourceCard.OpenEdit();
        ResourceCard.GotoRecord(Resource);

        // [WHEN] Invoking the Delete Coupling action
        ResourceCard.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Resource.RecordId()), 'The record should be uncoupled.');

        // [THEN] CompanyId field is reset on CRM Resource
        CRMProduct.Find();
        Assert.IsTrue(IsNullGuid(CRMProduct.CompanyId), 'The company ID must be empty.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'RESOURCE-PRODUCT';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitsOfMeasureUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SelectedUnitofMeasure: Record "Unit of Measure";
        UnitofMeasure: array[3] of Record "Unit of Measure";
        CRMUomschedule: array[3] of Record "CRM Uomschedule";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in foreground
        Initialize();

        // [GIVEN] The coupled Units of Measure
        CreateCoupledUnitsOfMeasure(UnitofMeasure, CRMUomschedule);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        SelectedRecordRef.GetTable(SelectedUnitofMeasure);
        SelectedIds.Add(UnitofMeasure[1].SystemId, true);
        SelectedIds.Add(UnitofMeasure[3].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMCouplingManagement.RemoveCoupling(SelectedRecordRef);

        // [THEN] Uncoupling job has not been created
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling is removed for the selected coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UnitofMeasure[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UnitofMeasure[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling exists for non-selected coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(UnitofMeasure[2].RecordId()), 'The record 2 should be coupled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitsOfMeasureUncoupleSingle()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        UnitofMeasure: array[3] of Record "Unit of Measure";
        CRMUomschedule: array[3] of Record "CRM Uomschedule";
        UnitsofMeasure: TestPage "Units of Measure";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in foreground
        Initialize();

        // [GIVEN] The coupled Units of Measure
        CreateCoupledUnitsOfMeasure(UnitofMeasure, CRMUomschedule);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        UnitsofMeasure.OpenView();
        UnitsofMeasure.GoToRecord(UnitofMeasure[2]);
        UnitsofMeasure.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has not been created
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(UnitofMeasure[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(UnitofMeasure[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(UnitofMeasure[3].RecordId()), 'The record 3 should be coupled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPriceGroupsUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SelectedCustomerPriceGroup: Record "Customer Price Group";
        CustomerPriceGroup: array[3] of Record "Customer Price Group";
        CRMPricelevel: array[3] of Record "CRM Pricelevel";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        SelectedRecordRef: RecordRef;
        SelectedIds: Dictionary of [Guid, Boolean];
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records in foreground
        Initialize();

        // [GIVEN] The coupled Customer Price Groups
        CreateCoupledCustomerPriceGroups(CustomerPriceGroup, CRMPricelevel);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        SelectedRecordRef.GetTable(SelectedCustomerPriceGroup);
        SelectedIds.Add(CustomerPriceGroup[1].SystemId, true);
        SelectedIds.Add(CustomerPriceGroup[3].SystemId, true);
        MockSetSelectionFilter(SelectedRecordRef, SelectedIds);
        CRMCouplingManagement.RemoveCoupling(SelectedRecordRef);

        // [THEN] Uncoupling job has not been created
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling is removed for the selected coupled records
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup[1].RecordId()), 'The record 1 should be uncoupled.');
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup[3].RecordId()), 'The record 3 should be uncoupled.');

        // [THEN] The coupling exists for non-selected coupled records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup[2].RecordId()), 'The record 2 should be coupled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPriceGroupsUncoupleSingle()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CustomerPriceGroup: array[3] of Record "Customer Price Group";
        CRMPricelevel: array[3] of Record "CRM Pricelevel";
        CustomerPriceGroups: TestPage "Customer Price Groups";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in foreground
        Initialize();

        // [GIVEN] The coupled Customer Price Groups
        CreateCoupledCustomerPriceGroups(CustomerPriceGroup, CRMPricelevel);

        // [WHEN] Invoking the Delete Coupling action on the list page when two of three records are selected
        CustomerPriceGroups.OpenView();
        CustomerPriceGroups.GoToRecord(CustomerPriceGroup[2]);
        CustomerPriceGroups.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has not been created
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup[3].RecordId()), 'The record 3 should be coupled.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure IntegrationSynchJobErrorsUncoupleSingleInForeground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMTransactioncurrency: array[3] of Record "CRM Transactioncurrency";
        IntegrationSynchJobErrors: array[3] of Record "Integration Synch. Job Errors";
        Currency: array[3] of Record Currency;
        IntegrationSynchErrorList: TestPage "Integration Synch. Error List";
        I: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in foreground
        Initialize();

        // [GIVEN] The coupled Currencies
        CreateCoupledCurrencies(Currency, CRMTransactioncurrency);

        // [GIVEN] The Synchronization Errors
        for I := 1 to 3 do
            MockSynchError(Currency[I].RecordId(), CRMTransactioncurrency[I].RecordId(), CRMTransactioncurrency[I].TransactionCurrencyId, IntegrationSynchJobErrors[I]);

        // [WHEN] Invoking the Delete Coupling action on the selected single record
        IntegrationSynchErrorList.OpenView();
        IntegrationSynchErrorList.GoToRecord(IntegrationSynchJobErrors[2]);
        IntegrationSynchErrorList.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has not been created
        VerifyUncouplingJobQueueEntryCount(0);

        // [THEN] The coupling for the selected record is removed
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Currency[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling for non-selected records is not removed
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Currency[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Currency[3].RecordId()), 'The record 3 should be coupled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntegrationSynchJobErrorsUncoupleSingleInBackground()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: array[3] of Record "Integration Synch. Job Errors";
        Item: array[3] of Record Item;
        CRMProduct: array[3] of Record "CRM Product";
        IntegrationSynchErrorList: TestPage "Integration Synch. Error List";
        I: integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the single selected record in background
        Initialize();

        // [GIVEN] Coupled Items and CRM Products are skipped for synchronization.
        CreateCoupledItems(Item, CRMProduct);

        // [GIVEN] The Synchronization Errors
        for I := 1 to 3 do
            MockSynchError(Item[I].RecordId(), CRMProduct[I].RecordId(), CRMProduct[I].ProductId, IntegrationSynchJobErrors[I]);

        // [WHEN] Invoking the Delete Coupling action on the selected single record
        IntegrationSynchErrorList.OpenView();
        IntegrationSynchErrorList.GoToRecord(IntegrationSynchJobErrors[2]);
        IntegrationSynchErrorList.DeleteCRMCoupling.Invoke();

        // [THEN] Uncoupling job has been created
        VerifyUncouplingJobQueueEntryCount(1);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling is removed for the selected single record
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item[2].RecordId()), 'The record 2 should be uncoupled.');

        // [THEN] The coupling remains for non-selected records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[1].RecordId()), 'The record 1 should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[3].RecordId()), 'The record 3 should be coupled.');

        // [THEN] CompanyId field is reset on the selected record
        CRMProduct[2].Find();
        Assert.IsTrue(IsNullGuid(CRMProduct[2].CompanyId), 'The company ID must be empty for record 2.');

        // [THEN] CompanyId field has a value on the non-selected record
        CRMProduct[1].Find();
        CRMProduct[3].Find();
        Assert.IsFalse(IsNullGuid(CRMProduct[1].CompanyId), 'The company ID must be not empty for record 1.');
        Assert.IsFalse(IsNullGuid(CRMProduct[3].CompanyId), 'The company ID must be not empty for record 3.');

        // [THEN] 1 uncoupled and 1 modified are logged in Integration Synch. Job record
        IntegrationSynchJob."Integration Table Mapping Name" := 'ITEM-PRODUCT';
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Uncoupled := 1;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntegrationSynchJobErrorsUncoupleMultiple()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: array[12] of Record "Integration Synch. Job Errors";
        Item: array[3] of Record Item;
        CRMProduct: array[3] of Record "CRM Product";
        Customer: array[3] of Record Customer;
        CRMAccount: array[3] of Record "CRM Account";
        SalespersonPurchaser: array[3] of Record "Salesperson/Purchaser";
        CRMSystemuser: array[3] of Record "CRM Systemuser";
        SelectedIntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        SelectedRecordRef: RecordRef;
        SelectedLocalIds: Dictionary of [Guid, Boolean];
        I: integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO] "Delete Coupling" action removes coupling of the multiple selected records from different mappings
        Initialize();

        // [GIVEN] Coupled records
        CreateCoupledItems(Item, CRMProduct);
        CreateCoupledCustomers(Customer, CRMAccount);
        CreateCoupledSalespersons(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] The synchronization errors, one error per customer and salesperson, two errors per item
        for I := 1 to 3 do begin
            MockSynchError(Item[I].RecordId(), CRMProduct[I].RecordId(), CRMProduct[I].ProductId, IntegrationSynchJobErrors[I]);
            MockSynchError(Customer[I].RecordId(), CRMAccount[I].RecordId(), CRMAccount[I].AccountId, IntegrationSynchJobErrors[3 + I]);
            MockSynchError(SalespersonPurchaser[I].RecordId(), CRMSystemuser[I].RecordId(), CRMSystemuser[I].SystemUserId, IntegrationSynchJobErrors[6 + I]);
            MockSynchError(Item[I].RecordId(), CRMProduct[I].RecordId(), CRMProduct[I].ProductId, IntegrationSynchJobErrors[9 + I]);
        end;

        // [WHEN] Selected 9 of 12 records, including 2 errors per item
        for I := 1 to 2 do begin
            SelectedLocalIds.Add(IntegrationSynchJobErrors[I].SystemId, true);
            SelectedLocalIds.Add(IntegrationSynchJobErrors[3 + I].SystemId, true);
            SelectedLocalIds.Add(IntegrationSynchJobErrors[6 + I].SystemId, true);
            SelectedLocalIds.Add(IntegrationSynchJobErrors[9 + I].SystemId, true);
        end;
        SelectedRecordRef.GetTable(SelectedIntegrationSynchJobErrors);
        MockSetSelectionFilter(SelectedRecordRef, SelectedLocalIds);
        SelectedRecordRef.SetTable(SelectedIntegrationSynchJobErrors);

        // [WHEN] Simulate Delete Coupling action
        SelectedIntegrationSynchJobErrors.DeleteCouplings();

        // [THEN] Uncoupling jobs are created for customers and items, no job for salespeople (foreground uncoupling)
        VerifyUncouplingJobQueueEntryCount(2);

        // [WHEN] The job is executed
        SimulateUncouplingJobsExecution();

        // [THEN] Couplings are removed for the selected records
        for I := 1 to 2 do begin
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Customer[I].RecordId()), 'The Customer should be uncoupled.');
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[I].RecordId()), 'The Salesperson should be uncoupled.');
            Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(Item[I].RecordId()), 'The Item should be uncoupled.');
        end;

        // [THEN] Couplings are remaining for the non-selected records
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Customer[3].RecordId()), 'The Customer should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalespersonPurchaser[3].RecordId()), 'The Salesperson should be coupled.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Item[3].RecordId()), 'The Item should be coupled.');

        // [THEN] CompanyId field is reset for the selected records
        for I := 1 to 2 do begin
            CRMAccount[I].Find();
            CRMProduct[I].Find();
            Assert.IsTrue(IsNullGuid(CRMAccount[I].CompanyId), 'The company ID must be empty for the CRM Account.');
            Assert.IsTrue(IsNullGuid(CRMProduct[I].CompanyId), 'The company ID must be empty for the CRM Product.');
        end;

        // [THEN] CompanyId field is set for the non-selected records
        CRMAccount[3].Find();
        CRMProduct[3].Find();
        Assert.IsFalse(IsNullGuid(CRMAccount[3].CompanyId), 'The company ID must be set for the CRM Account.');
        Assert.IsFalse(IsNullGuid(CRMProduct[3].CompanyId), 'The company ID must be set for the CRM Product.');

        // [THEN] Correct counters for uncoupled and modified records are logged in Integration Synch. Job
        IntegrationSynchJob.Init();
        IntegrationSynchJob."Integration Table Mapping Name" := 'CUSTOMER';
        IntegrationSynchJob.Modified := 2;
        IntegrationSynchJob.Uncoupled := 2;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
        IntegrationSynchJob.Init();
        IntegrationSynchJob."Integration Table Mapping Name" := 'ITEM-PRODUCT';
        IntegrationSynchJob.Modified := 2;
        IntegrationSynchJob.Uncoupled := 2;
        VerifyIntegrationSynchJob(IntegrationSynchJob);
    end;

    local procedure Initialize()
    var
        CDSCompany: Record "CDS Company";
        MyNotifications: Record "My Notifications";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
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
        CRMConnectionSetup."Unit Group Mapping Enabled" := false;
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
        RemoveUncouplingJobQueueEntries();
        CDSIntegrationImpl.ResetCache();
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

    local procedure CreateCoupledItems(var Item: array[3] of Record Item; var CRMProduct: array[3] of Record "CRM Product")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            CreateCoupledItem(Item[I], CRMProduct[I]);
    end;

    local procedure CreateCoupledItem(var Item: Record Item; var CRMProduct: Record "CRM Product")
    var
        RecordRef: RecordRef;
    begin
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        RecordRef.GetTable(CRMProduct);
        CDSIntegrationImpl.SetCompanyId(RecordRef);
        RecordRef.Modify();
        CRMProduct.Find();
        Assert.IsFalse(IsNullGuid(CRMProduct.CompanyId), 'The company ID must be set for CRM Product.');
    end;

    local procedure CreateCoupledResources(var Resource: array[3] of Record Resource; var CRMProduct: array[3] of Record "CRM Product")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            CreateCoupledResource(Resource[I], CRMProduct[I]);
    end;

    local procedure CreateCoupledResource(var Resource: Record Resource; var CRMProduct: Record "CRM Product")
    var
        RecordRef: RecordRef;
    begin
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);
        RecordRef.GetTable(CRMProduct);
        CDSIntegrationImpl.SetCompanyId(RecordRef);
        RecordRef.Modify();
        CRMProduct.Find();
        Assert.IsFalse(IsNullGuid(CRMProduct.CompanyId), 'The company ID must be set for CRM Product.');
    end;

    local procedure CreateCoupledUnitsOfMeasure(var UnitofMeasure: array[3] of Record "Unit of Measure"; var CRMUomschedule: array[3] of Record "CRM Uomschedule")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            CreateCoupledUnitOfMeasure(UnitofMeasure[I], CRMUomschedule[I]);
    end;

    local procedure CreateCoupledUnitOfMeasure(var UnitofMeasure: Record "Unit of Measure"; var CRMUomschedule: Record "CRM Uomschedule")
    var
        CRMUom: Record "CRM Uom";
    begin
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitofMeasure, CRMUom, CRMUomschedule);
    end;

    local procedure CreateCoupledCustomerPriceGroups(var CustomerPriceGroup: array[3] of Record "Customer Price Group"; var CRMPricelevel: array[3] of Record "CRM Pricelevel")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            CreateCoupledCustomerPriceGroup(CustomerPriceGroup[I], CRMPricelevel[I]);
    end;

    local procedure CreateCoupledCustomerPriceGroup(var CustomerPriceGroup: Record "Customer Price Group"; var CRMPricelevel: Record "CRM Pricelevel")
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevelWithTransactionCurrency(CustomerPriceGroup, CRMPricelevel, CRMTransactioncurrency);
    end;

    local procedure CreateCoupledOpportunities(var Opportunity: array[3] of Record Opportunity; var CRMOpportunity: array[3] of Record "CRM Opportunity")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            CreateCoupledOpportunity(Opportunity[I], CRMOpportunity[I]);
    end;

    local procedure CreateCoupledOpportunity(var Opportunity: Record Opportunity; var CRMOpportunity: Record "CRM Opportunity")
    var
        RecordRef: RecordRef;
    begin
        LibraryCRMIntegration.CreateCoupledOpportunityAndOpportunity(Opportunity, CRMOpportunity);
        RecordRef.GetTable(CRMOpportunity);
        CDSIntegrationImpl.SetCompanyId(RecordRef);
        RecordRef.Modify();
        CRMOpportunity.Find();
        Assert.IsFalse(IsNullGuid(CRMOpportunity.CompanyId), 'The company ID must be set for CRM Opportunity.');
    end;

    local procedure CreateCoupledContacts(var Contact: array[3] of Record Contact; var CRMContact: array[3] of Record "CRM Contact")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            CreateCoupledContact(Contact[I], CRMContact[I]);
    end;

    local procedure CreateCoupledContact(var Contact: Record Contact; var CRMContact: Record "CRM Contact")
    var
        RecordRef: RecordRef;
    begin
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        RecordRef.GetTable(CRMContact);
        CDSIntegrationImpl.SetCompanyId(RecordRef);
        RecordRef.Modify();
        CRMContact.Find();
        Assert.IsFalse(IsNullGuid(CRMContact.CompanyId), 'The company ID must be set for CRM Contact.');
    end;

    local procedure CreateCoupledCurrencies(var Currency: array[3] of Record Currency; var CRMTranactioncurrency: array[3] of Record "CRM Transactioncurrency")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            CreateCoupledCurrency(Currency[I], CRMTranactioncurrency[I]);
    end;

    local procedure CreateCoupledCurrency(var Currency: Record Currency; var CRMTransactioncurrency: Record "CRM Transactioncurrency")
    begin
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
    end;

    local procedure CreateCoupledSalespersons(var SalespersonPurchaser: array[3] of Record "Salesperson/Purchaser"; var CRMSystemuser: array[3] of Record "CRM Systemuser")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            CreateCoupledSalesperson(SalespersonPurchaser[I], CRMSystemuser[I]);
    end;

    local procedure CreateCoupledSalesperson(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var CRMSystemuser: Record "CRM Systemuser")
    begin
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
    end;

    local procedure MockSkippedCustomers(var Customer: array[3] of Record Customer; var CRMAccount: array[3] of Record "CRM Account")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            MockSkippedCustomer(Customer[I], CRMAccount[I]);
    end;

    local procedure MockSkippedCustomer(var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordRef: RecordRef;
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
        RecordRef.GetTable(CRMAccount);
        CDSIntegrationImpl.SetCompanyId(RecordRef);
        RecordRef.Modify();
        CRMAccount.Find();
        Assert.IsFalse(IsNullGuid(CRMAccount.CompanyId), 'The company ID must be set for CRM Account.');
    end;

    local procedure MockSkippedItems(var Item: array[3] of Record Item; var CRMProduct: array[3] of Record "CRM Product")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            MockSkippedItem(Item[I], CRMProduct[I]);
    end;

    local procedure MockSkippedItem(var Item: Record Item; var CRMProduct: Record "CRM Product")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordRef: RecordRef;
    begin
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        CRMIntegrationRecord.FindByCRMID(CRMProduct.ProductId);
        CRMIntegrationRecord.Skipped := true;
        CRMIntegrationRecord.Modify();
        RecordRef.GetTable(CRMProduct);
        CDSIntegrationImpl.SetCompanyId(RecordRef);
        RecordRef.SetTable(CRMProduct);
        RecordRef.Modify();
        CRMProduct.Find();
        Assert.IsFalse(IsNullGuid(CRMProduct.CompanyId), 'The company ID must be set for CRM Product.');
    end;

    local procedure MockSkippedSalespersons(var SalespersonPurchaser: array[3] of Record "Salesperson/Purchaser"; var CRMSystemuser: array[3] of Record "CRM Systemuser")
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            MockSkippedSalesperson(SalespersonPurchaser[I], CRMSystemuser[I]);
    end;

    local procedure MockSkippedSalesperson(var SalespersonPurchaser: Record "Salesperson/Purchaser"; var CRMSystemuser: Record "CRM Systemuser")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        CRMIntegrationRecord.FindByCRMID(CRMSystemuser.SystemUserId);
        CRMIntegrationRecord.Skipped := true;
        CRMIntegrationRecord."Last Synch. Modified On" := CurrentDateTime - 10000;
        CRMIntegrationRecord.Modify();
        CRMSystemuser.FullName := LibraryUtility.GenerateGUID();
        CRMSystemuser.Modify();
    end;

    local procedure MockSynchError(LocalRecordId: RecordId; CRMRecordId: RecordId; CRMID: Guid; var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ErrorMsg: Text;
        ToIntegrationJobID: Guid;
        FromIntegrationJobID: Guid;
    begin
        ErrorMsg := LibraryUtility.GenerateGUID();
        ToIntegrationJobID := LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
            LocalRecordId, CRMRecordId, ErrorMsg, CurrentDateTime(), false);
        FromIntegrationJobID := LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
            CRMID, CRMRecordId, LocalRecordId,
            LibraryUtility.GenerateGUID(), CurrentDateTime(), false);
        CRMIntegrationRecord.FindByCRMID(CRMID);
        CRMIntegrationRecord.GetLatestError(IntegrationSynchJobErrors);
        Assert.AreEqual(ErrorMsg, IntegrationSynchJobErrors.Message, 'GetLatestError fails.');
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(LocalRecordId), 'The record should be coupled.');
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

    local procedure MockSetSelectionFilter(var TempSelectedCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary; SelectedLocalIds: Dictionary of [Guid, Boolean])
    begin
        TempSelectedCRMSynchConflictBuffer.Reset();
        if TempSelectedCRMSynchConflictBuffer.FindSet() then
            repeat
                if SelectedLocalIds.ContainsKey(TempSelectedCRMSynchConflictBuffer."Integration ID") then
                    TempSelectedCRMSynchConflictBuffer.Mark(true);
            until TempSelectedCRMSynchConflictBuffer.Next() = 0;
        TempSelectedCRMSynchConflictBuffer.MarkedOnly(true);
        Assert.AreEqual(SelectedLocalIds.Count(), TempSelectedCRMSynchConflictBuffer.Count(), 'Unexpected number of selected records');
    end;

    local procedure SimulateUncouplingJobsExecution()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type To Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Int. Uncouple Job Runner");
        JobQueueEntry.FindSet();
        repeat
            Codeunit.Run(Codeunit::"Int. Uncouple Job Runner", JobQueueEntry);
        until JobQueueEntry.Next() = 0;
    end;

    local procedure VerifyUncouplingJobQueueEntryCount(ExpectedCount: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Int. Uncouple Job Runner");
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
        IntegrationSynchJob.SetRange(Type, IntegrationSynchJob.Type::Uncoupling);
        Assert.IsTrue(IntegrationSynchJob.FindSet(), 'Cannot find the integration uncoupling job.');
        repeat
            TempIntegrationSynchJob.Inserted += IntegrationSynchJob.Inserted;
            TempIntegrationSynchJob.Modified += IntegrationSynchJob.Modified;
            TempIntegrationSynchJob.Deleted += IntegrationSynchJob.Deleted;
            TempIntegrationSynchJob.Failed += IntegrationSynchJob.Failed;
            TempIntegrationSynchJob.Skipped += IntegrationSynchJob.Skipped;
            TempIntegrationSynchJob.Unchanged += IntegrationSynchJob.Unchanged;
            TempIntegrationSynchJob.Uncoupled += IntegrationSynchJob.Uncoupled;
            TempIntegrationSynchJob.Modify();
        until IntegrationSynchJob.Next() = 0;
        Assert.AreEqual(TempIntegrationSynchJob.Uncoupled, ExpectedIntegrationSynchJob.Uncoupled, 'Incorrect count of Uncoupled for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Modified, ExpectedIntegrationSynchJob.Modified, 'Incorrect count of Modified for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Inserted, ExpectedIntegrationSynchJob.Inserted, 'Incorrect count of Inserted for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Deleted, ExpectedIntegrationSynchJob.Deleted, 'Incorrect count of Deleted for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Failed, ExpectedIntegrationSynchJob.Failed, 'Incorrect count of Failed for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Skipped, ExpectedIntegrationSynchJob.Skipped, 'Incorrect count of Skipped for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
        Assert.AreEqual(TempIntegrationSynchJob.Unchanged, ExpectedIntegrationSynchJob.Unchanged, 'Incorrect count of Unchanged for ' + ExpectedIntegrationSynchJob."Integration Table Mapping Name");
    end;

    local procedure RemoveUncouplingJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Int. Uncouple Job Runner");
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
}