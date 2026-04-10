codeunit 139187 "CRM Full Synchronization"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Full Synchronization]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T100_Wave1TablesHaveBlankDependencyFilter()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        AllLinesCount: Integer;
    begin
        // [FEATURE] [Processing Order] [Status]
        // [SCENARIO] "SALESPEOPLE","CURRENCY","UNIT OF MEASURE" mapping records (Wave1) have blank Dependency filter
        Initialize();
        LibraryLowerPermissions.SetO365Full();

        // [GIVEN] 'SALESPEOPLE' has "Dependency Filter" = 'CURRENCY', "Job Queue Entry Status" = ' '
        CRMFullSynchReviewLine.Init();
        CRMFullSynchReviewLine.Name := 'SALESPEOPLE';
        CRMFullSynchReviewLine."Dependency Filter" := 'CURRENCY';
        CRMFullSynchReviewLine.Insert();

        // [WHEN] Generate CRM Full Synch Review Lines
        CRMFullSynchReviewLine.Generate();

        // [THEN] All lines have "Job Queue Entry Status" = ' '
        AllLinesCount := CRMFullSynchReviewLine.Count();
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::" ");
        Assert.RecordCount(CRMFullSynchReviewLine, AllLinesCount);
        // [THEN] "SALESPEOPLE","CURRENCY","UNIT OF MEASURE" have blank "Dependency Filter"
        CRMFullSynchReviewLine.SetFilter(Name, 'SALESPEOPLE|CURRENCY|UNIT OF MEASURE');
        CRMFullSynchReviewLine.SetRange("Dependency Filter", '');
        Assert.RecordCount(CRMFullSynchReviewLine, 3);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T101_Wave1PlusHaveNotBlankDependencyFilter()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        // [FEATURE] [Processing Order]
        Initialize();
        LibraryLowerPermissions.SetO365Full();

        // [WHEN] Generate CRM Full Synch Review Lines
        CRMFullSynchReviewLine.Generate();

        // [THEN] 'CUSTOMER' line, where "Dependency Filter" = 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT'
        VerifyDependencyFilter('CUSTOMER', 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT');
        // [THEN] 'CONTACT' line, where "Dependency Filter" = 'CUSTOMER'
        VerifyDependencyFilter('CONTACT', 'CUSTOMER|VENDOR');
        // [THEN] 'OPPORTUNITY' line, where "Dependency Filter" = 'CONTACT'
        VerifyDependencyFilter('OPPORTUNITY', 'CONTACT');
        // [THEN] 'POSTEDSALESINV-INV' line, where "Dependency Filter" = 'ITEM-PRODUCT|RESOURCE-PRODUCT|OPPORTUNITY'
        VerifyDependencyFilter('POSTEDSALESINV-INV', 'ITEM-PRODUCT|RESOURCE-PRODUCT|OPPORTUNITY');
        // [THEN] 'ITEM-PRODUCT' line, where "Dependency Filter" = 'UNIT OF MEASURE'
        VerifyDependencyFilter('ITEM-PRODUCT', 'UNIT OF MEASURE');
        // [THEN] 'RESOURCE-PRODUCT' line, where "Dependency Filter" = 'UNIT OF MEASURE'
        VerifyDependencyFilter('RESOURCE-PRODUCT', 'UNIT OF MEASURE');
        // [THEN] 'CUSTPRCGRP-PRICE' line, where "Dependency Filter" = 'CURRENCY|ITEM-PRODUCT'
        VerifyDependencyFilter('CUSTPRCGRP-PRICE', 'CURRENCY|ITEM-PRODUCT');
        // [THEN] 'SALESPRC-PRODPRICE' line, where "Dependency Filter" = 'CUSTPRCGRP-PRICE|ITEM-PRODUCT'
        VerifyDependencyFilter('SALESPRC-PRODPRICE', 'CUSTPRCGRP-PRICE|ITEM-PRODUCT');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure T102_Wave1PlusHaveNotBlankDependencyFilterExtendePrices()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        // [FEATURE] [Processing Order]
        // [GIVEN] Extended Prices are on.
        Initialize(true, false);
        LibraryLowerPermissions.SetO365Full();

        // [WHEN] Generate CRM Full Synch Review Lines
        CRMFullSynchReviewLine.Generate();

        // [THEN] 'CUSTOMER' line, where "Dependency Filter" = 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT'
        VerifyDependencyFilter('CUSTOMER', 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT');
        // [THEN] 'CONTACT' line, where "Dependency Filter" = 'CUSTOMER'
        VerifyDependencyFilter('CONTACT', 'CUSTOMER|VENDOR');
        // [THEN] 'OPPORTUNITY' line, where "Dependency Filter" = 'CONTACT'
        VerifyDependencyFilter('OPPORTUNITY', 'CONTACT');
        // [THEN] 'POSTEDSALESINV-INV' line, where "Dependency Filter" = 'ITEM-PRODUCT|RESOURCE-PRODUCT|OPPORTUNITY'
        VerifyDependencyFilter('POSTEDSALESINV-INV', 'ITEM-PRODUCT|RESOURCE-PRODUCT|OPPORTUNITY');
        // [THEN] 'ITEM-PRODUCT' line, where "Dependency Filter" = 'UNIT OF MEASURE'
        VerifyDependencyFilter('ITEM-PRODUCT', 'UNIT OF MEASURE');
        // [THEN] 'RESOURCE-PRODUCT' line, where "Dependency Filter" = 'UNIT OF MEASURE'
        VerifyDependencyFilter('RESOURCE-PRODUCT', 'UNIT OF MEASURE');
        // [THEN] 'PLHEADER-PRICE' line, where "Dependency Filter" = 'CURRENCY|ITEM-PRODUCT'
        VerifyDependencyFilter('PLHEADER-PRICE', 'CURRENCY|ITEM-PRODUCT');
        // [THEN] 'PLLINE-PRODPRICE' line, where "Dependency Filter" = 'PLHEADER-PRICE|ITEM-PRODUCT'
        VerifyDependencyFilter('PLLINE-PRODPRICE', 'PLHEADER-PRICE|ITEM-PRODUCT');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure T103_Wave1PlusHaveNotBlankDependencyFilterUnitGroup()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        // [FEATURE] [Processing Order]
        // [GIVEN] Unit group mapping is on
        Initialize(false, true);
        LibraryLowerPermissions.SetO365Full();

        // [WHEN] Generate CRM Full Synch Review Lines
        CRMFullSynchReviewLine.Generate();

        // [THEN] 'CUSTOMER' line, where "Dependency Filter" = 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT'
        VerifyDependencyFilter('CUSTOMER', 'SALESPEOPLE|CURRENCY|PAYMENT TERMS|SHIPMENT METHOD|SHIPPING AGENT');
        // [THEN] 'CONTACT' line, where "Dependency Filter" = 'CUSTOMER'
        VerifyDependencyFilter('CONTACT', 'CUSTOMER|VENDOR');
        // [THEN] 'OPPORTUNITY' line, where "Dependency Filter" = 'CONTACT'
        VerifyDependencyFilter('OPPORTUNITY', 'CONTACT');
        // [THEN] 'POSTEDSALESINV-INV' line, where "Dependency Filter" = 'ITEM-PRODUCT|RESOURCE-PRODUCT|OPPORTUNITY'
        VerifyDependencyFilter('POSTEDSALESINV-INV', 'ITEM-PRODUCT|RESOURCE-PRODUCT|OPPORTUNITY');
        // [THEN] 'ITEM-PRODUCT' line, where "Dependency Filter" = 'ITEM UOM'
        VerifyDependencyFilter('ITEM-PRODUCT', 'ITEM UOM');
        // [THEN] 'RESOURCE-PRODUCT' line, where "Dependency Filter" = 'RESOURCE UOM'
        VerifyDependencyFilter('RESOURCE-PRODUCT', 'RESOURCE UOM');
        // [THEN] 'CUSTPRCGRP-PRICE' line, where "Dependency Filter" = 'CURRENCY|ITEM-PRODUCT'
        VerifyDependencyFilter('CUSTPRCGRP-PRICE', 'CURRENCY|ITEM-PRODUCT');
        // [THEN] 'SALESPRC-PRODPRICE' line, where "Dependency Filter" = 'CUSTPRCGRP-PRICE|ITEM-PRODUCT'
        VerifyDependencyFilter('SALESPRC-PRODPRICE', 'CUSTPRCGRP-PRICE|ITEM-PRODUCT');
        // [THEN] 'ITEM UOM' line, where "Dependency Filter" = 'UNIT GROUP'
        VerifyDependencyFilter('ITEM UOM', 'UNIT GROUP');
        // [THEN] 'RESOURCE UOM' line, where "Dependency Filter" = 'UNIT GROUP'
        VerifyDependencyFilter('RESOURCE UOM', 'UNIT GROUP');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T105_NotOnHoldStatusBlocksLineUpdate()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        AllLinesCount: Integer;
    begin
        // [FEATURE] [Status]
        // [SCENARIO] "SALESPEOPLE" line in Status 'Ready' should not be updated
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] 'SALESPEOPLE' has "Dependency Filter" = 'CURRENCY', "Job Queue Entry Status" = 'Ready'
        CRMFullSynchReviewLine.Init();
        CRMFullSynchReviewLine.Name := 'SALESPEOPLE';
        CRMFullSynchReviewLine."Dependency Filter" := 'CURRENCY';
        CRMFullSynchReviewLine."Job Queue Entry Status" :=
          CRMFullSynchReviewLine."Job Queue Entry Status"::Ready;
        CRMFullSynchReviewLine.Insert();

        // [WHEN] Generate CRM Full Synch Review Lines
        CRMFullSynchReviewLine.Generate();

        // [THEN] 'SALESPEOPLE' line is not changed, "Job Queue Entry Status" = 'Ready'
        CRMFullSynchReviewLine.Get('SALESPEOPLE');
        CRMFullSynchReviewLine.TestField(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::Ready);
        CRMFullSynchReviewLine.TestField("Dependency Filter", 'CURRENCY');
        // [THEN] All other lines have "Job Queue Entry Status" = ' '
        AllLinesCount := CRMFullSynchReviewLine.Count();
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::" ");
        Assert.RecordCount(CRMFullSynchReviewLine, AllLinesCount - 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_ReadyLineSchedulesJob()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        // [FEATURE] [Integration Synch. Job]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] 'CURRENCY' line, where "Job Queue Entry Status" is ' '
        CRMFullSynchReviewLine.Init();
        CRMFullSynchReviewLine.Name := 'CURRENCY';
        CRMFullSynchReviewLine.Insert(true);

        // [WHEN] Start the full synchronization
        CRMFullSynchReviewLine.Start();

        // [THEN] Full Synch. Job Entry for 'CURRENCY' is created, "Job Queue Entry Status" = 'On Hold'
        CRMFullSynchReviewLine.TestField("Job Queue Entry ID", VerifyFullRunJobEntry('CURRENCY'));
        CRMFullSynchReviewLine.TestField("Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::"On Hold");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T121_FinishedLineSchedulesDependentJob()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        Currency: Record Currency;
        Customer: Record Customer;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMFullSynchronization: Codeunit "CRM Full Synchronization";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Integration Synch. Job]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] New currency 'X' and Customer 'A'
        Currency.DeleteAll();
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 3, 3));
        Customer.DeleteAll();
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] 'CURRENCY' and 'CUSTOMER' lines, where  "Job Queue Entry Status" is ' '
        CRMFullSynchReviewLine.Init();
        CRMFullSynchReviewLine.Name := 'CURRENCY';
        CRMFullSynchReviewLine.Insert(true);
        // [GIVEN] 'CUSTOMER' line depends on 'CURRENCY'
        CRMFullSynchReviewLine.Name := 'CUSTOMER';
        CRMFullSynchReviewLine."Dependency Filter" := 'CURRENCY';
        CRMFullSynchReviewLine.Insert(true);

        // [WHEN] Start the full synchronization
        CRMFullSynchReviewLine.Start();

        // [THEN] The 'CURRENCY' synch job is scheduled and executed
        Assert.IsTrue(FindFullSyncIntTableMapping('CURRENCY', IntegrationTableMapping), 'Full Synch. mapping is not created');
        BindSubscription(CRMFullSynchronization); // to catch "In Process" Status by OnQueryPostFilterIgnoreRecordCurrencyHandler
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);
        // [THEN] 'CURRENCY' line gets "Job Queue Entry Status" = 'Ready'
        // [THEN] "To Int. Table Job ID" = 'J1', "To Int. Table Job Status" = 'In Process'
        // [THEN] "From Int. Table Job ID" = <null>, "From Int. Table Job Status" = ' '
        // verification in OnQueryPostFilterIgnoreRecordCurrencyHandler

        // [THEN] The synch. job 'J1' has inserted 1 record
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        // [THEN] 'CURRENCY' line gets "Job Queue Entry Status" = 'Finished', "To Int. Table Job Status" = 'Success'
        CRMFullSynchReviewLine.Get('CURRENCY');
        CRMFullSynchReviewLine.TestField("Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        CRMFullSynchReviewLine.TestField(
          "To Int. Table Job Status", CRMFullSynchReviewLine."To Int. Table Job Status"::Success);
        // [THEN] Full Synch. Job Entry for 'CUSTOMER' is created
        VerifyFullRunJobEntry('CUSTOMER');
        // [THEN] "Full Synch." Integration Table Mapping for 'CURRENCY' has been deleted
        Assert.IsFalse(IntegrationTableMapping.Find(), 'Integration Table Mapping for CURRENCY should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T122_BidirectionalSynchUpdatesTwoSynchJobStatuses()
    var
        CRMAccount: Record "CRM Account";
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMFullSynchronization: Codeunit "CRM Full Synchronization";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Integration Synch. Job]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        BlankTableConfigTemplateCodes('CUSTOMER'); // to avoid cross country issues with currencies

        // [GIVEN] New Customer 'A'
        Customer.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] new CRM Account 'B'
        CRMAccount.DeleteAll();
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        // [GIVEN] Payment terms is coupled
        CouplePaymentTerms(Customer);

        // [GIVEN] 'CUSTOMER' line, where "Dependency Filter" is blank
        CRMFullSynchReviewLine.Name := 'CUSTOMER';
        CRMFullSynchReviewLine.Insert(true);

        // [WHEN] Start the full synchronization
        CRMFullSynchReviewLine.Start();

        // [THEN] The 'CUSTOMER' synch job is scheduled and executed
        Assert.IsTrue(FindFullSyncIntTableMapping('CUSTOMER', IntegrationTableMapping), 'Full Synch. mapping is not created');
        BindSubscription(CRMFullSynchronization); // to catch "In Process" Status
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);
        // [THEN] 'CUSTOMER' line gets "Job Queue Entry Status" = 'In Process'
        // [THEN] "To Int. Table Job ID" = 'J1', "To Int. Table Job Status" = 'In Process'
        // [THEN] "From Int. Table Job ID" = '<null>', "From Int. Table Job Status" = ' '
        // verification in OnQueryPostFilterIgnoreRecordCustomerHandler
        // [THEN] "To Int. Table Job ID" = 'J1', "To Int. Table Job Status" = 'Success'
        // [THEN] "From Int. Table Job ID" = 'J2', "From Int. Table Job Status" = 'In Process'
        // verification in OnQueryPostFilterIgnoreRecordCRMAccountHandler

        // [THEN] 'CUSTOMER' line gets "Job Queue Entry Status" = 'Finished',
        CRMFullSynchReviewLine.Get('CUSTOMER');
        CRMFullSynchReviewLine.TestField("Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        // [THEN] "To Int. Table Job Status" = 'Success', "From Int. Table Job Status" = 'Success'
        CRMFullSynchReviewLine.TestField(
          "To Int. Table Job Status", CRMFullSynchReviewLine."To Int. Table Job Status"::Success);
        CRMFullSynchReviewLine.TestField(
          "From Int. Table Job Status", CRMFullSynchReviewLine."From Int. Table Job Status"::Success);
        // [THEN] Customer "A" is coupled, CRM Account "B" is coupled.
        VerifyNAVRecIsCoupled(Customer.RecordId);
        VerifyCRMRecIsCoupled(CRMAccount.AccountId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T123_AllRecsFailedSynchJobStatusError()
    var
        CRMAccount: Record "CRM Account";
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        Customer: Record Customer;
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        // [FEATURE] [Integration Synch. Job]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] 2 New Customers, where "Salesperson Code" is not coupled
        Customer.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer);
        Customer.ModifyAll("Salesperson Code", 'FAIL'); // to make both fail during synchronization
        // [GIVEN] 2 new CRM Accounts, where "PrimaryContactId" is not coupled
        CRMAccount.DeleteAll();
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        CRMAccount.ModifyAll(Name, 'FAIL');
        CRMAccount.ModifyAll(PrimaryContactId, CreateGuid()); // to make both fail during synchronization
        IntegrationFieldMapping.ModifyAll("Clear Value on Failed Sync", false);
        // [GIVEN] 'CUSTOMER' line, where "Dependency Filter" is blank
        CRMFullSynchReviewLine.Name := 'CUSTOMER';
        CRMFullSynchReviewLine.Insert(true);

        // [WHEN] Start the full synchronization
        CRMFullSynchReviewLine.Start();

        // [THEN] The 'CUSTOMER' synch job is scheduled and executed
        // [THEN] 'CUSTOMER' line gets "Job Queue Entry Status" = 'Finished', "Session ID" = 0, "Active Session" = 'No'
        // [THEN] "To Int. Table Job Status" = 'Error', "From Int. Table Job Status" = 'Error'
        VerifyCustomerJobIsFinished(CRMFullSynchReviewLine."To Int. Table Job Status"::Error);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T124_NotAllRecsFailedSynchJobStatusSuccess()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        Customer: array[2] of Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMFullSynchronization: Codeunit "CRM Full Synchronization";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Integration Synch. Job]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] 2 New Customers: "A" and
        Customer[1].DeleteAll();
        Customer[2].DeleteAll();
        LibrarySales.CreateCustomer(Customer[1]);
        // [GIVEN] "B", where "Salesperson Code" is not coupled
        LibrarySales.CreateCustomer(Customer[2]);
        Customer[2]."Salesperson Code" := 'FAIL'; // to it fail during synchronization
        Customer[2].Modify();
        // [GIVEN] Payment terms is coupled
        CouplePaymentTerms(Customer[1]);
        CouplePaymentTerms(Customer[2]);

        // [GIVEN] 'CUSTOMER' line, where "Dependency Filter" is blank
        CRMFullSynchReviewLine.Name := 'CUSTOMER';
        CRMFullSynchReviewLine.Insert(true);

        // [WHEN] Start the full synchronization
        CRMFullSynchReviewLine.Start();

        // [THEN] The 'CUSTOMER' synch job is scheduled and executed
        // [THEN] 'CUSTOMER' line gets "Session ID" = 0, "Active Session" = 'No'
        // [THEN] "To Int. Table Job Status" = 'Error'
        Assert.IsTrue(FindFullSyncIntTableMapping('CUSTOMER', IntegrationTableMapping), 'Full Synch. mapping is not created');
        BindSubscription(CRMFullSynchronization); // to catch "In Process" Status
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping, true);

        CRMFullSynchReviewLine.Get('CUSTOMER');
        CRMFullSynchReviewLine.TestField("Session ID", 0);
        Assert.IsFalse(CRMFullSynchReviewLine.IsActiveSession(), 'Session should be inactive');

        CRMFullSynchReviewLine.TestField("To Int. Table Job Status", CRMFullSynchReviewLine."To Int. Table Job Status"::Error);

        // [THEN] Customer "A" is coupled, Customer "B" is NOT coupled.
        VerifyNAVRecIsCoupled(Customer[1].RecordId);
        VerifyNAVRecIsNotCoupled(Customer[2].RecordId);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T125_ModifyNonCRMJobQueueEntry()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [UT] [Event]
        // [GIVEN] Job Queue Entry, where Status is 'In Process', "Record ID to Process" is empty
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        Clear(JobQueueEntry."Record ID to Process");
        JobQueueEntry.Insert();

        // [WHEN] Modify Status to 'Finished'
        JobQueueEntry.Status := JobQueueEntry.Status::Finished;
        CRMFullSynchReviewLine.OnBeforeModifyJobQueueEntry(JobQueueEntry);

        // [THEN] CRMFullSynchReviewLine is not updated
        CRMFullSynchReviewLine.TestField("Job Queue Entry Status", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T127_FullSynchJobInheritsFiltersAndProcessesNotCoupledRecs()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        FullIntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [UT] [Integration Synch. Job]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] 'SALESPEOPLE' mapping includes filters and is set to process coupled recs only
        IntegrationTableMapping.Get('SALESPEOPLE');
        IntegrationTableMapping.TestField("Synch. Only Coupled Records");
        Assert.AreNotEqual('', IntegrationTableMapping.GetIntegrationTableFilter(), 'IntegrationTableFilter should not be blank.');
        SalespersonPurchaser.SetFilter("E-Mail", '<>%1', '');
        IntegrationTableMapping.SetTableFilter(SalespersonPurchaser.GetView());
        IntegrationTableMapping.Modify();
        Assert.AreNotEqual('', IntegrationTableMapping.GetTableFilter(), 'TableFilter should not be blank.');

        // [WHEN] EnqueueFullSyncJob() for 'SALESPEOPLE'
        JobQueueEntry.Get(CRMIntegrationManagement.EnqueueFullSyncJob(IntegrationTableMapping.Name));

        // [THEN] Full synch. IntegrationTableMapping is a copy of 'SALESPEOPLE', where "Parent Name" = 'SALESPEOPLE'
        FullIntegrationTableMapping.Get(JobQueueEntry."Record ID to Process");
        FullIntegrationTableMapping.TestField("Parent Name", IntegrationTableMapping.Name);
        // [THEN] "Full Sync is Running" = 'Yes', "Synch. Only Coupled Records" = 'No'
        FullIntegrationTableMapping.TestField("Full Sync is Running");
        FullIntegrationTableMapping.TestField("Synch. Only Coupled Records", false);
        // [THEN] Table filters are equal
        Assert.AreEqual(IntegrationTableMapping.GetTableFilter(), FullIntegrationTableMapping.GetTableFilter(), 'Table Filter');
        Assert.AreEqual(
          IntegrationTableMapping.GetIntegrationTableFilter(),
          FullIntegrationTableMapping.GetIntegrationTableFilter(), 'Integration Table Filter');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T130_CRMJobQueueEntryIsOnHoldDuringFullSynchronization()
    var
        Contact: Record Contact;
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMFullSynchronization: Codeunit "CRM Full Synchronization";
        JobQueueEntryID: Guid;
        PrevStatus: Option;
    begin
        // [FEATURE] [Integration Synch. Job]
        // [SCENARIO] Original CRM Job Queue Entry gets 'On Hold' while the full synch. job is being executed
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        LibraryCRMIntegration.CreateContact(Contact);

        // [GIVEN] Original 'CONTACT' Job Queue Entry
        Assert.IsTrue(FindJobQueueEntryForMapping('CONTACT', JobQueueEntry), 'cannot find CONTACT job queue entry');
        PrevStatus := JobQueueEntry.Status;

        CRMFullSynchReviewLine.Name := 'CONTACT';
        CRMFullSynchReviewLine.Insert();
        // [WHEN] Run 'CUSTOMER' full synch. job
        CRMFullSynchReviewLine.Start();
        FindFullSyncIntTableMapping('CONTACT', IntegrationTableMapping);
        BindSubscription(CRMFullSynchronization); // to catch "In Process" Status
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);

        // [THEN] Original 'CUSTOMER' Job Queue Entry is 'On Hold'
        // verify by OnQueryPostFilterIgnoreRecordContactHandler

        // [THEN] 'CUSTOMER' full synch. job is finished
        CRMFullSynchReviewLine.Find();
        CRMFullSynchReviewLine.TestField(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        // [THEN] Original 'CUSTOMER' Job Queue Entry has the same status as before
        JobQueueEntry.Find();
        JobQueueEntry.TestField(Status, PrevStatus);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T150_CRMFullSynchReviewPageOpenOnFullSyncActionInCRMConnSetup()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
        CRMFullSynchReview: TestPage "CRM Full Synch. Review";
    begin
        // [FEATURE] [UI] [Suite]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] Application Area is 'Suite'
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Open "CRM Connection Setup" page
        CRMConnectionSetupPage.OpenEdit();
        // [WHEN] Run action "Full Sync."
        CRMFullSynchReview.Trap();
        CRMConnectionSetupPage.StartInitialSynchAction.Invoke();
        // [THEN] "CRM Full Synch Review" page is open, not editable, "Dependency Filter" is hidden.
        Assert.IsFalse(CRMFullSynchReview.Name.Editable(), 'Name should be not editable');
        Assert.IsFalse(CRMFullSynchReview.Direction.Editable(), 'Direction should be not editable');
        Assert.IsFalse(CRMFullSynchReview."Job Queue Entry Status".Editable(), 'Job Queue Entry Status should be not editable');
        Assert.IsFalse(
          CRMFullSynchReview."To Int. Table Job Status".Editable(), 'To Int. Table Job Status should be not editable');
        Assert.IsFalse(
          CRMFullSynchReview."From Int. Table Job Status".Editable(), 'From Int. Table Job Status should be not editable');
        asserterror Assert.IsFalse(CRMFullSynchReview."Dependency Filter".Visible(), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T151_CRMFullSynchReviewPageShowsAllCRMIntegrMappingRecs()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMFullSynchReview: TestPage "CRM Full Synch. Review";
        MapCount: Integer;
        I: Integer;
        LastMapName: Code[20];
    begin
        // [FEATURE] [UI]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] There are 15 CRM Itegration table mappings
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetFilter(Name, '<>POSTEDSALESLINE-INV&<>SALESORDER-ORDER');
        MapCount := IntegrationTableMapping.Count();
        Assert.AreNotEqual(0, MapCount, 'Expected the nonzero number of table mapping records.');
        Assert.TableIsEmpty(DATABASE::"CRM Full Synch. Review Line");
        // [GIVEN] There is 1 temporary CRM Itegration table mapping
        IntegrationTableMapping.Get('CURRENCY');
        IntegrationTableMapping.Name := 'TEMPCURRENCY';
        IntegrationTableMapping."Delete After Synchronization" := true;
        IntegrationTableMapping.Insert();

        // [WHEN] Open "CRM Full Synch Review"
        CRMFullSynchReview.OpenEdit();
        Assert.RecordCount(CRMFullSynchReviewLine, MapCount);
        // [THEN] "CRM Full Synch Review" page contains 15 Integartion Mapping data: Name, Direction.
        CRMFullSynchReview.Last();
        LastMapName := CRMFullSynchReview.Name.Value();
        CRMFullSynchReview.First();
        // [THEN] Job Status controls are blank
        Assert.AreEqual(' ', CRMFullSynchReview."Job Queue Entry Status".Value, 'Job Queue Entry Status');
        Assert.AreEqual(' ', CRMFullSynchReview."To Int. Table Job Status".Value, 'To Int. Table Job Status');
        Assert.AreEqual(' ', CRMFullSynchReview."From Int. Table Job Status".Value, 'From Int. Table Job Status');
        I := 1;
        repeat
            Assert.IsTrue(
              IntegrationTableMapping.Get(CRMFullSynchReview.Name.Value()),
              StrSubstNo('Failed to find a (%1) map: %2', I, CRMFullSynchReview.Name));
            Assert.AreEqual(
              IntegrationTableMapping.Direction, CRMFullSynchReview.Direction.AsInteger(),
              StrSubstNo('Wrong Direction for %1', CRMFullSynchReview.Name));
            I += 1;
            CRMFullSynchReview.Next();
        until I > MapCount;
        CRMFullSynchReview.Name.AssertEquals(LastMapName);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T152_CRMFullSynchReviewPageOpenedTwice()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CRMFullSynchReview: TestPage "CRM Full Synch. Review";
        MapCount: Integer;
    begin
        // [FEATURE] [UI]
        // [GIVEN] "CRM Full Synch Review Line" table is empty.
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] There are 12 CRM Itegration table mappings
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
        // [GIVEN] Open and close "CRM Full Synch Review"
        CRMFullSynchReview.OpenEdit();
        CRMFullSynchReview.Close();
        // [GIVEN] "CRM Full Synch Review Line" table contains 12 records.
        Assert.TableIsNotEmpty(DATABASE::"CRM Full Synch. Review Line");
        MapCount := CRMFullSynchReviewLine.Count();
        // [GIVEN] Removed one of "CRM Full Synch Review Line"
        CRMFullSynchReviewLine.FindFirst();
        CRMFullSynchReviewLine.Delete();

        // [WHEN] Open "CRM Full Synch Review" again
        CRMFullSynchReview.OpenEdit();
        // [THEN] "CRM Full Synch Review Line" table contains 12 records.
        Assert.RecordCount(CRMFullSynchReviewLine, MapCount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T153_GetStatusStyleExpressionUT()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        // [FEATURE] [UT] [Status] [Style]
        CRMFullSynchReviewLine."Job Queue Entry Status" := CRMFullSynchReviewLine."Job Queue Entry Status"::Error;
        Assert.AreEqual('Unfavorable', CRMFullSynchReviewLine.GetStatusStyleExpression(Format(CRMFullSynchReviewLine."Job Queue Entry Status")), 'Job Queue Entry Status::Error');

        CRMFullSynchReviewLine."Job Queue Entry Status" := CRMFullSynchReviewLine."Job Queue Entry Status"::Finished;
        Assert.AreEqual('Favorable', CRMFullSynchReviewLine.GetStatusStyleExpression(Format(CRMFullSynchReviewLine."Job Queue Entry Status")), 'Job Queue Entry Status::Finished');

        CRMFullSynchReviewLine."Job Queue Entry Status" := CRMFullSynchReviewLine."Job Queue Entry Status"::"In Process";
        Assert.AreEqual('Ambiguous', CRMFullSynchReviewLine.GetStatusStyleExpression(Format(CRMFullSynchReviewLine."Job Queue Entry Status")), 'Job Queue Entry Status::In Process');

        CRMFullSynchReviewLine."Job Queue Entry Status" := CRMFullSynchReviewLine."Job Queue Entry Status"::"On Hold";
        Assert.AreEqual('Subordinate', CRMFullSynchReviewLine.GetStatusStyleExpression(Format(CRMFullSynchReviewLine."Job Queue Entry Status")), 'Job Queue Entry Status::On Hold');

        CRMFullSynchReviewLine."Job Queue Entry Status" := CRMFullSynchReviewLine."Job Queue Entry Status"::Ready;
        Assert.AreEqual('Subordinate', CRMFullSynchReviewLine.GetStatusStyleExpression(Format(CRMFullSynchReviewLine."Job Queue Entry Status")), 'Job Queue Entry Status::Ready');

        CRMFullSynchReviewLine."To Int. Table Job Status" := CRMFullSynchReviewLine."To Int. Table Job Status"::Error;
        Assert.AreEqual('Unfavorable', CRMFullSynchReviewLine.GetStatusStyleExpression(Format(CRMFullSynchReviewLine."To Int. Table Job Status")), 'To Int. Table Job Status::Error');

        CRMFullSynchReviewLine."To Int. Table Job Status" := CRMFullSynchReviewLine."To Int. Table Job Status"::"In Process";
        Assert.AreEqual(
          'Ambiguous', CRMFullSynchReviewLine.GetStatusStyleExpression(Format(CRMFullSynchReviewLine."To Int. Table Job Status")), 'To Int. Table Job Status::In Process');

        CRMFullSynchReviewLine."To Int. Table Job Status" := CRMFullSynchReviewLine."To Int. Table Job Status"::Success;
        Assert.AreEqual('Favorable', CRMFullSynchReviewLine.GetStatusStyleExpression(Format(CRMFullSynchReviewLine."To Int. Table Job Status")), 'To Int. Table Job Status::Success');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T154_StartSyncWhenWave1And2ParentsAreFinishedExtendedPrices()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        Counter: Integer;
    begin
        // [FEATURE] [Status] [UT]
        // [GIVEN] Extended Prices are on
        Initialize(true, false);
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] 'UNIT OF MEASURE','CURRENCY','ITEM-PRODUCT','PLHEADER-PRICE', 'PAYMENT TERMS', 'SHIPMENT METHOD', 'SHIPPING AGENT' are 'Finished'
        CRMFullSynchReviewLine.Generate();
        SetStatus('CURRENCY', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('PLHEADER-PRICE', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('ITEM-PRODUCT', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('UNIT OF MEASURE', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('PAYMENT TERMS', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('SHIPMENT METHOD', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('SHIPPING AGENT', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);

        // [WHEN] Run "Start"
        CRMFullSynchReviewLine.Start();

        // [THEN] Lines 'PLLINE-PRODPRICE','RESOURCE-PRODUCT','SALESPEOPLE' get "Job Queue Entry Status" = 'On Hold'
        CRMFullSynchReviewLine.SetFilter(Name, 'PLLINE-PRODPRICE|RESOURCE-PRODUCT|SALESPEOPLE');
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::"On Hold");
        Assert.RecordCount(CRMFullSynchReviewLine, 2);
        // [THEN] Other lines, where "Job Queue Entry Status" is ' '
        CRMFullSynchReviewLine.Reset();
        Counter := CRMFullSynchReviewLine.Count();
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::" ");
        Assert.RecordCount(CRMFullSynchReviewLine, Counter - 9); // 4 - Finished, 4 - Ready
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure T155_StartSyncWhenAllOnHold()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
        AllCounter: Integer;
        Counter: Integer;
    begin
        // [FEATURE] [UI] [Status]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] Open "CRM Full Synch Review"
        CRMFullSynchReviewPage.OpenEdit();

        // [WHEN] Run "Start" and confirm
        CRMFullSynchReviewPage.Start.Invoke();

        // [THEN] Lines, where is blank "Dependency Filter", get "Job Queue Entry Status" = 'On Hold'
        AllCounter := CRMFullSynchReviewLine.Count();
        CRMFullSynchReviewLine.SetRange("Dependency Filter", '');
        Counter := CRMFullSynchReviewLine.Count();
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::"On Hold");
        Assert.RecordCount(CRMFullSynchReviewLine, Counter);
        // [THEN] Other lines, where "Job Queue Entry Status" is ' '
        CRMFullSynchReviewLine.SetRange("Dependency Filter");
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::" ");
        Assert.RecordCount(CRMFullSynchReviewLine, AllCounter - Counter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T157_StartSyncWhenBothParentsAreFinished()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        Counter: Integer;
        Finished: Integer;
        OnHold: Integer;
    begin
        // [FEATURE] [Status] [UT]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] 'SALESPEOPLE' and 'CURRENCY' are 'Finished', 'UNIT OF MEASURE' is 'In Process'
        CRMFullSynchReviewLine.Generate();
        SetStatus('CURRENCY', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('ITEM-PRODUCT', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('SALESPEOPLE', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('PAYMENT TERMS', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('SHIPMENT METHOD', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('SHIPPING AGENT', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('UNIT OF MEASURE', CRMFullSynchReviewLine."Job Queue Entry Status"::"In Process");
        Finished := 2;

        // [WHEN] Run "Start"
        CRMFullSynchReviewLine.Start();

        // [THEN] Lines 'CUSTPRCGRP-PRICE' and 'CUSTOMER' get "Status" = 'On Hold'
        OnHold := 3;
        CRMFullSynchReviewLine.SetFilter(Name, 'CUSTPRCGRP-PRICE|CUSTOMER|VENDOR');
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::"On Hold");
        Assert.RecordCount(CRMFullSynchReviewLine, OnHold);
        // [THEN] Other lines, where "Job Queue Entry Status" is ' '
        CRMFullSynchReviewLine.Reset();
        CRMFullSynchReviewLine.SetFilter("Dependency Filter", '<>%1', '');
        Counter := CRMFullSynchReviewLine.Count();
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::" ");
        Assert.RecordCount(CRMFullSynchReviewLine, Counter - Finished - OnHold);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T158_StartSyncWhenWave1And2ParentsAreFinished()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        Counter: Integer;
        Finished: Integer;
        OnHold: Integer;
    begin
        // [FEATURE] [Status] [UT]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] 'UNIT OF MEASURE','CURRENCY','ITEM-PRODUCT','CUSTPRCGRP-PRICE' are 'Finished'
        CRMFullSynchReviewLine.Generate();
        SetStatus('CURRENCY', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('ITEM-PRODUCT', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('UNIT OF MEASURE', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('PAYMENT TERMS', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('SHIPMENT METHOD', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('SHIPPING AGENT', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('CUSTPRCGRP-PRICE', CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        Finished := 7;

        // [WHEN] Run "Start"
        CRMFullSynchReviewLine.Start();

        // [THEN] Lines 'CUSTPRCGRP-PRICE','RESOURCE-PRODUCT','SALESPEOPLE' get "Job Queue Entry Status" = 'On Hold'
        OnHold := 3;
        CRMFullSynchReviewLine.SetFilter(Name, 'SALESPRC-PRODPRICE|RESOURCE-PRODUCT|SALESPEOPLE');
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::"On Hold");
        Assert.RecordCount(CRMFullSynchReviewLine, OnHold);
        // [THEN] Other lines, where "Job Queue Entry Status" is ' '
        CRMFullSynchReviewLine.Reset();
        Counter := CRMFullSynchReviewLine.Count();
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::" ");
        Assert.RecordCount(CRMFullSynchReviewLine, Counter - Finished - OnHold);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure T159_StartSyncWhenAllOnHoldNotConfirmed()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
        AllCounter: Integer;
    begin
        // [FEATURE] [UI] [Status]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] Open "CRM Full Synch Review"
        CRMFullSynchReviewPage.OpenEdit();

        // [WHEN] Run "Start" and do NOT confirm
        CRMFullSynchReviewPage.Start.Invoke();

        // [THEN] All lines still have <blank> "Job Queue Entry Status"
        AllCounter := CRMFullSynchReviewLine.Count();
        CRMFullSynchReviewLine.SetRange(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::" ");
        Assert.RecordCount(CRMFullSynchReviewLine, AllCounter);
    end;

    [Test]
    [HandlerFunctions('JobQueueLogEntriesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T160_LookupJobQueueEntryStatusShowsLog()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Status] [UI]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] Application Area is 'Suite'
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Job Queue Entries: "A", "B", "C"
        JobQueueEntryID := MockJobQueueLogEntries(2);

        // [GIVEN] 'CUSTOMER' line, where "Job Queue Entry ID" = "B"
        CRMFullSynchReviewLine.Name := 'CUSTOMER';
        CRMFullSynchReviewLine.Validate("Job Queue Entry ID", JobQueueEntryID);
        CRMFullSynchReviewLine.Insert(true);

        // [GIVEN] Open "CRM Full Synch Review"
        CRMFullSynchReviewPage.OpenEdit();
        CRMFullSynchReviewPage.GotoRecord(CRMFullSynchReviewLine);
        // [WHEN] Drilldown on "Job Queue Entry Status"
        CRMFullSynchReviewPage."Job Queue Entry Status".DrillDown();

        // [THEN] Job Queue Log Entries Page is open, where "B" is the only record
        // verified by JobQueueLogEntriesHandler
    end;

    [Test]
    [HandlerFunctions('IntegrationSynchJobListHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T161_LookupToIntTableStatusShowsSynchLog()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
        IntegrationSynchJobID: Guid;
    begin
        // [FEATURE] [Status] [UI]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] Application Area is 'Suite'
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Three Integration Synch. Jobs: "A", "B", "C"
        IntegrationSynchJobID := MockIntegrationSynchJobs(2);

        // [GIVEN] 'CUSTOMER' line, where "To Int. Table Job ID" = "B"
        CRMFullSynchReviewLine.Name := 'CUSTOMER';
        CRMFullSynchReviewLine.Validate("To Int. Table Job ID", IntegrationSynchJobID);
        CRMFullSynchReviewLine.Insert(true);

        // [GIVEN] Open "CRM Full Synch Review"
        CRMFullSynchReviewPage.OpenEdit();
        CRMFullSynchReviewPage.GotoRecord(CRMFullSynchReviewLine);
        // [WHEN] Drilldown on "To Int. Table Job Status"
        CRMFullSynchReviewPage."To Int. Table Job Status".DrillDown();

        // [THEN] Job Queue Log Entries Page is open, where "B" is the only record
        // verified by IntegrationSynchJobListHandler
    end;

    [Test]
    [HandlerFunctions('IntegrationSynchJobListHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T162_LookupFromIntTableStatusShowsSynchLog()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
        IntegrationSynchJobID: Guid;
    begin
        // [FEATURE] [Status] [UI]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] Application Area is 'Suite'
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Three Integration Synch. Jobs: "A", "B", "C"
        IntegrationSynchJobID := MockIntegrationSynchJobs(2);

        // [GIVEN] 'CUSTOMER' line, where "From Int. Table Job ID" = "B"
        CRMFullSynchReviewLine.Name := 'CUSTOMER';
        CRMFullSynchReviewLine.Validate("From Int. Table Job ID", IntegrationSynchJobID);
        CRMFullSynchReviewLine.Insert(true);

        // [GIVEN] Open "CRM Full Synch Review"
        CRMFullSynchReviewPage.OpenEdit();
        CRMFullSynchReviewPage.GotoRecord(CRMFullSynchReviewLine);
        // [WHEN] Drilldown on "From Int. Table Job Status"
        CRMFullSynchReviewPage."From Int. Table Job Status".DrillDown();

        // [THEN] Job Queue Log Entries Page is open, where "B" is the only record
        // verified by IntegrationSynchJobListHandler
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T165_AnyActiveSessionDisablesStartAction()
    var
        CRMFullSynchReviewLine: array[2] of Record "CRM Full Synch. Review Line";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
    begin
        // [FEATURE] [Session] [UI]
        // [SCENARIO] Action Start is disabled if any "In Process" line has an active session
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] 'CUSTOMER' line is "In Process" and "Session ID" points to an active session
        CRMFullSynchReviewLine[1].Name := 'CUSTOMER';
        CRMFullSynchReviewLine[1]."Session ID" := SessionId();
        CRMFullSynchReviewLine[1]."Job Queue Entry Status" :=
          CRMFullSynchReviewLine[1]."Job Queue Entry Status"::"In Process";
        CRMFullSynchReviewLine[1].Insert();
        // [GIVEN] 'CURRENCY' line is "Error" and "Session ID" points to an inactive session
        CRMFullSynchReviewLine[2].Name := 'CURRENCY';
        CRMFullSynchReviewLine[2]."Session ID" := -21;
        CRMFullSynchReviewLine[2]."Job Queue Entry Status" :=
          CRMFullSynchReviewLine[2]."Job Queue Entry Status"::Error;
        CRMFullSynchReviewLine[2].Insert();

        // [WHEN] Open "CRM Full Synch Review"
        CRMFullSynchReviewPage.OpenEdit();
        // [THEN] "Start" action is disabled
        Assert.IsFalse(CRMFullSynchReviewPage.Start.Enabled(), 'Start action should be disabled');
        // [THEN] 'CUSTOMER' line, where "Active Session" is 'Yes'
        CRMFullSynchReviewPage.GotoRecord(CRMFullSynchReviewLine[1]);
        Assert.IsTrue(CRMFullSynchReviewPage.ActiveSession.AsBoolean(), 'Active Session for CUSTOMER');
        // [THEN] 'CURRENCY' line, where "Active Session" is 'No'
        CRMFullSynchReviewPage.GotoRecord(CRMFullSynchReviewLine[2]);
        Assert.IsFalse(CRMFullSynchReviewPage.ActiveSession.AsBoolean(), 'Active Session for CURRENCY');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T166_AllInactiveSessionsEnablesStartAction()
    var
        CRMFullSynchReviewLine: array[3] of Record "CRM Full Synch. Review Line";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
    begin
        // [FEATURE] [Session] [UI]
        // [SCENARIO] Action Start is enabled if no "In Process" lines have an active session
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] 'CUSTOMER' line is "In Process", but "Session ID" points to an inactive session
        CRMFullSynchReviewLine[1].Name := 'CUSTOMER';
        CRMFullSynchReviewLine[1]."Session ID" := -11;
        CRMFullSynchReviewLine[1]."Job Queue Entry Status" :=
          CRMFullSynchReviewLine[1]."Job Queue Entry Status"::"In Process";
        CRMFullSynchReviewLine[1].Insert();
        // [GIVEN] 'CURRENCY' line is "Finished" and "Session ID" points to an active session
        CRMFullSynchReviewLine[2].Name := 'CURRENCY';
        CRMFullSynchReviewLine[2]."Session ID" := SessionId();
        CRMFullSynchReviewLine[2]."Job Queue Entry Status" :=
          CRMFullSynchReviewLine[2]."Job Queue Entry Status"::Finished;
        CRMFullSynchReviewLine[2].Insert();
        // [GIVEN] 'CONTACT' line is not started, "Status" is <blank>
        CRMFullSynchReviewLine[3].Name := 'CONTACT';
        CRMFullSynchReviewLine[3]."Session ID" := 0;
        CRMFullSynchReviewLine[3]."Job Queue Entry Status" :=
          CRMFullSynchReviewLine[3]."Job Queue Entry Status"::" ";
        CRMFullSynchReviewLine[3].Insert();

        // [WHEN] Open "CRM Full Synch Review"
        CRMFullSynchReviewPage.OpenEdit();

        // [THEN] "Start" action is enabled
        Assert.IsTrue(CRMFullSynchReviewPage.Start.Enabled(), 'Start action should be enabled');
        // [THEN] 'CUSTOMER' line, where "Active Session" is 'No'
        CRMFullSynchReviewPage.GotoRecord(CRMFullSynchReviewLine[1]);
        Assert.IsFalse(CRMFullSynchReviewPage.ActiveSession.AsBoolean(), 'Active Session for CUSTOMER');
        // [THEN] 'CURRENCY' line, where "Active Session" is 'Yes'
        CRMFullSynchReviewPage.GotoRecord(CRMFullSynchReviewLine[2]);
        Assert.IsTrue(CRMFullSynchReviewPage.ActiveSession.AsBoolean(), 'Active Session for CURRENCY');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure T167_NoBlankStatusLinesDisableStartAction()
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMFullSynchReviewPage: TestPage "CRM Full Synch. Review";
    begin
        // [FEATURE] [Status] [UI]
        // [SCENARIO] Action Start is disabled if no lines in initial <blank> status
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] All lines are in different states, but no one, where "Status" = <blank>
        CRMFullSynchReviewLine.Generate();
        CRMFullSynchReviewLine.ModifyAll(
          "Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        SetStatus('CURRENCY', CRMFullSynchReviewLine."Job Queue Entry Status"::Ready);
        SetStatus('CUSTOMER', CRMFullSynchReviewLine."Job Queue Entry Status"::Error);
        SetStatus('CONTACT', CRMFullSynchReviewLine."Job Queue Entry Status"::"In Process");
        SetStatus('SALESPEOPLE', CRMFullSynchReviewLine."Job Queue Entry Status"::"On Hold");

        // [WHEN] Open "CRM Full Synch Review"
        CRMFullSynchReviewPage.OpenEdit();

        // [THEN] "Start" action is disabled
        Assert.IsFalse(CRMFullSynchReviewPage.Start.Enabled(), 'Start action should be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T170_ParentMappingGetsSyncModifiedOnFilters()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Integration Table Mapping]
        Initialize();
        LibraryLowerPermissions.SetO365Full();
        // [GIVEN] New Customer "A", where "Modified On" = 'X'
        Customer.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] 'CUSTOMER' line, where "Dependency Filter" is blank
        CRMFullSynchReviewLine.Name := 'CUSTOMER';
        CRMFullSynchReviewLine.Insert(true);
        // [GIVEN] Integration Table Mapping "CUSTOMER",
        IntegrationTableMapping.Get(CRMFullSynchReviewLine.Name);
        // [GIVEN] where "Synch. Modified On Filter" and "Synch. Int. Tbl. Mod. On Fltr." are blank
        IntegrationTableMapping.TestField("Synch. Int. Tbl. Mod. On Fltr.", 0DT);
        IntegrationTableMapping.TestField("Synch. Modified On Filter", 0DT);

        // [WHEN] Start the full synchronization
        CRMFullSynchReviewLine.Start();

        // [THEN] The 'CUSTOMER' synch job is scheduled and executed
        VerifyCustomerJobIsFinished(CRMFullSynchReviewLine."To Int. Table Job Status"::Success);
        // [THEN] Customer 'A' is coupled, "Last Synch. CRM Modified On" = 'Y'
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        // [THEN] Integration Table Mapping "CUSTOMER",
        IntegrationTableMapping.Find();
        // [THEN] where "Synch. Modified On Filter" = 'Y' and "Synch. Int. Tbl. Mod. On Fltr." = 'X'
        IntegrationTableMapping.TestField("Synch. Int. Tbl. Mod. On Fltr.", Customer.SystemModifiedAt);
        IntegrationTableMapping.TestField("Synch. Modified On Filter", CRMIntegrationRecord."Last Synch. CRM Modified On");
    end;

    local procedure Initialize()
    begin
        Initialize(false, false);
    end;

    local procedure Initialize(EnableExtendedPrice: Boolean; EnableUnitGroupMapping: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMOrganization: Record "CRM Organization";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ClientSecret: Text;
    begin
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        if EnableExtendedPrice then
            LibraryPriceCalculation.EnableExtendedPriceCalculation();

        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        CRMFullSynchReviewLine.DeleteAll();
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CRMConnectionSetup."Unit Group Mapping Enabled" := EnableUnitGroupMapping;
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMOrganization.FindFirst();
        CRMConnectionSetup.BaseCurrencyId := CRMOrganization.BaseCurrencyId;
        CRMConnectionSetup.Modify();
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
    end;

    local procedure BlankTableConfigTemplateCodes(MapName: Code[20])
    var
        TableConfigTemplate: Record "Table Config Template";
        IntTableConfigTemplate: Record "Int. Table Config Template";
    begin
        TableConfigTemplate.SetRange("Integration Table Mapping Name", MapName);
        TableConfigTemplate.DeleteAll();
        IntTableConfigTemplate.SetRange("Integration Table Mapping Name", MapName);
        IntTableConfigTemplate.DeleteAll();
    end;

    local procedure SetStatus(Name: Code[20]; NewStatus: Option)
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMFullSynchReviewLine.Get(Name);
        CRMFullSynchReviewLine."Job Queue Entry Status" := NewStatus;
        CRMFullSynchReviewLine.Modify();
    end;

    local procedure FindFullSyncIntTableMapping(Name: Code[20]; var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        ParentIntegrationTableMapping: Record "Integration Table Mapping";
    begin
        ParentIntegrationTableMapping.Get(Name);
        IntegrationTableMapping.SetRange("Table ID", ParentIntegrationTableMapping."Table ID");
        IntegrationTableMapping.SetRange("Integration Table ID", ParentIntegrationTableMapping."Integration Table ID");
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        IntegrationTableMapping.SetRange("Full Sync is Running", true);
        exit(IntegrationTableMapping.FindFirst())
    end;

    local procedure FindJobQueueEntryForMapping(MapName: Code[20]; var JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.Get(MapName);
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
        exit(JobQueueEntry.FindFirst())
    end;

    local procedure MockIntegrationSynchJobs(ExpectedNo: Integer) ID: Guid
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        I: Integer;
    begin
        IntegrationTableMapping.DeleteAll();
        IntegrationTableMapping.Name := 'X';
        IntegrationTableMapping."Table ID" := DATABASE::Customer;
        IntegrationTableMapping.Insert();

        IntegrationSynchJob.DeleteAll();
        for I := 1 to 3 do begin
            IntegrationSynchJob.ID := CreateGuid();
            IntegrationSynchJob.Modified := I;
            IntegrationSynchJob."Integration Table Mapping Name" := IntegrationTableMapping.Name;
            IntegrationSynchJob.Insert();
            if ExpectedNo = I then
                ID := IntegrationSynchJob.ID;
        end;
    end;

    local procedure MockJobQueueLogEntries(ExpectedNo: Integer) ID: Guid
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        I: Integer;
    begin
        JobQueueLogEntry.DeleteAll();
        for I := 1 to 3 do begin
            JobQueueLogEntry."Entry No." := I;
            JobQueueLogEntry.ID := CreateGuid();
            JobQueueLogEntry.Description := Format(I);
            JobQueueLogEntry.Insert();
            if ExpectedNo = I then
                ID := JobQueueLogEntry.ID;
        end;
    end;

    local procedure VerifyCustomerJobIsFinished(ExpectedJobStatus: Option)
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMFullSynchronization: Codeunit "CRM Full Synchronization";
        JobQueueEntryID: Guid;
    begin
        Assert.IsTrue(FindFullSyncIntTableMapping('CUSTOMER', IntegrationTableMapping), 'Full Synch. mapping is not created');
        BindSubscription(CRMFullSynchronization); // to catch "In Process" Status
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);

        CRMFullSynchReviewLine.Get('CUSTOMER');
        CRMFullSynchReviewLine.TestField("Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::Finished);
        CRMFullSynchReviewLine.TestField("Session ID", 0);
        Assert.IsFalse(CRMFullSynchReviewLine.IsActiveSession(), 'Session should be inactive');

        CRMFullSynchReviewLine.TestField("To Int. Table Job Status", ExpectedJobStatus);
        CRMFullSynchReviewLine.TestField("From Int. Table Job Status", ExpectedJobStatus);
    end;

    local procedure VerifyDependencyFilter(Name: Code[20]; "Filter": Text[250])
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMFullSynchReviewLine.Get(Name);
        CRMFullSynchReviewLine.TestField("Dependency Filter", Filter);
    end;

    local procedure VerifyFullRunJobEntry(Name: Code[20]): Guid
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Assert.IsTrue(FindFullSyncIntTableMapping(Name, IntegrationTableMapping), 'Full synch. mapping is not found.');
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
        JobQueueEntry.FindFirst();
        exit(JobQueueEntry.ID);
    end;

    local procedure VerifyFullSyncRevieLineDuringSynch(MapName: Code[20])
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
    begin
        CRMFullSynchReviewLine.Get(MapName);
        Assert.IsFalse(IsNullGuid(CRMFullSynchReviewLine."Job Queue Entry ID"), 'Job Queue Entry ID should not be null');
        CRMFullSynchReviewLine.TestField("Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::"In Process");
        Assert.IsTrue(CRMFullSynchReviewLine.IsActiveSession(), 'Session should be active');

        Assert.IsFalse(IsNullGuid(CRMFullSynchReviewLine."To Int. Table Job ID"), 'To Int. Table Job ID is null.');
        CRMFullSynchReviewLine.TestField("To Int. Table Job Status", CRMFullSynchReviewLine."To Int. Table Job Status"::"In Process");

        Assert.IsTrue(IsNullGuid(CRMFullSynchReviewLine."From Int. Table Job ID"), 'From Int. Table Job ID is not null.');
        CRMFullSynchReviewLine.TestField("From Int. Table Job Status", CRMFullSynchReviewLine."From Int. Table Job Status"::" ");
    end;

    local procedure VerifyNAVRecIsCoupled(RecID: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(RecID), Format(RecID) + ' should be coupled');
    end;

    local procedure VerifyNAVRecIsNotCoupled(RecID: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        Assert.IsFalse(CRMIntegrationRecord.FindByRecordID(RecID), Format(RecID) + ' should not be coupled');
    end;

    local procedure VerifyCRMRecIsCoupled(CRMId: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMId), Format(CRMId) + ' should be coupled');
    end;

    local procedure CouplePaymentTerms(Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMAccount: Record "CRM Account";
    begin
        PaymentTerms.Get(Customer."Payment Terms Code");
        CRMOptionMapping."Record ID" := PaymentTerms.RecordId;
        CRMOptionMapping."Option Value" := 1;
        CRMOptionMapping."Option Value Caption" := PaymentTerms.Code;
        CRMOptionMapping."Table ID" := Database::"Payment Terms";
        CRMOptionMapping."Integration Table ID" := Database::"CRM Account";
        CRMOptionMapping."Integration Field ID" := CRMAccount.FieldNo(CRMAccount.PaymentTermsCodeEnum);
        if CRMOptionMapping.Insert() then;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IntegrationSynchJobListHandler(var IntegrationSynchJobList: TestPage "Integration Synch. Job List")
    begin
        Assert.IsTrue(IntegrationSynchJobList.First(), 'IntegrationSynchJobList.FIRST');
        IntegrationSynchJobList.Modified.AssertEquals('2');
        Assert.IsTrue(IntegrationSynchJobList.Last(), 'IntegrationSynchJobList.LAST');
        IntegrationSynchJobList.Modified.AssertEquals('2');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure JobQueueLogEntriesHandler(var JobQueueLogEntriesPage: TestPage "Job Queue Log Entries")
    begin
        Assert.IsTrue(JobQueueLogEntriesPage.First(), 'JobQueueLogEntriesPage.FIRST');
        JobQueueLogEntriesPage.Description.AssertEquals('2');
        Assert.IsTrue(JobQueueLogEntriesPage.Last(), 'JobQueueLogEntriesPage.LAST');
        JobQueueLogEntriesPage.Description.AssertEquals('2');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    procedure OnQueryPostFilterIgnoreRecordCurrencyHandler(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        if SourceRecordRef.Number <> DATABASE::Currency then
            exit;
        VerifyFullSyncRevieLineDuringSynch('CURRENCY');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    procedure OnQueryPostFilterIgnoreRecordCustomerHandler(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        if SourceRecordRef.Number <> DATABASE::Customer then
            exit;
        VerifyFullSyncRevieLineDuringSynch('CUSTOMER');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    procedure OnQueryPostFilterIgnoreRecordCRMAccountHandler(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
        CRMAccount: Record "CRM Account";
    begin
        if SourceRecordRef.Number <> DATABASE::"CRM Account" then
            exit;
        SourceRecordRef.SetTable(CRMAccount);
        CRMFullSynchReviewLine.Get('CUSTOMER');
        Assert.IsFalse(IsNullGuid(CRMFullSynchReviewLine."Job Queue Entry ID"), 'Job Queue Entry ID should not be null');
        CRMFullSynchReviewLine.TestField("Job Queue Entry Status", CRMFullSynchReviewLine."Job Queue Entry Status"::"In Process");
        Assert.IsTrue(CRMFullSynchReviewLine.IsActiveSession(), 'Session should be active');

        Assert.IsFalse(IsNullGuid(CRMFullSynchReviewLine."To Int. Table Job ID"), 'To Int. Table Job ID is null.');
        if CRMAccount.Name = 'FAIL' then
            CRMFullSynchReviewLine.TestField("To Int. Table Job Status", CRMFullSynchReviewLine."To Int. Table Job Status"::Error)
        else
            CRMFullSynchReviewLine.TestField("To Int. Table Job Status", CRMFullSynchReviewLine."To Int. Table Job Status"::Success);

        Assert.IsFalse(IsNullGuid(CRMFullSynchReviewLine."From Int. Table Job ID"), 'From Int. Table Job ID is null.');
        CRMFullSynchReviewLine.TestField("From Int. Table Job Status", CRMFullSynchReviewLine."From Int. Table Job Status"::"In Process");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    procedure OnQueryPostFilterIgnoreRecordContactHandler(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if SourceRecordRef.Number <> DATABASE::Contact then
            exit;
        Assert.IsTrue(FindJobQueueEntryForMapping('CONTACT', JobQueueEntry), 'Cannot find a job in onQueryPostFilter handler');
        JobQueueEntry.TestField(Status, JobQueueEntry.Status::"On Hold");
    end;
}

