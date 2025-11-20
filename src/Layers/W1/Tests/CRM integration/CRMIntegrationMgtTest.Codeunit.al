codeunit 139162 "CRM Integration Mgt Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        SynchDirection: Option Cancel,ToCRM,ToNAV;
        ConfirmStartCouplingReply: Boolean;
        CRMCouplingPageDoCancel: Boolean;
        IsInitialized: Boolean;
        BlockedMustBeNoErr: Label 'Blocked must be equal to ''No''';
        SyncNowScheduledMsg: Label 'The synchronization has been scheduled.';
        SyncNowSkippedMsg: Label 'The synchronization has been skipped. The record is already coupled.';
        MultipleSyncStartedMsg: Label 'The synchronization has been scheduled for %1 of %2 records. %3 records failed. %4 records were skipped.';
        CurrencyPriceListNameTxt: Label 'Price List in %1', Comment = '%1 - currency code';
        RecordMustBeCoupledErr: Label '%1 %2 must be coupled to a %3 record.', Comment = '%1 = table caption, %2 = primary key value, %3 = CRM Table caption';

    [Test]
    [HandlerFunctions('ConfirmStartCoupling')]
    [Scope('OnPrem')]
    procedure ShowCoupleCRMEntityAsksIfNotCoupled()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] ShowCRMEntityFromRecordID() asks the user to create missing customer coupling
        // [GIVEN] A customer not coupled to a CRM account
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        ConfirmStartCouplingReply := false;

        // [WHEN] Show CRM Entity is invoked
        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);

        // [THEN] NAV asks Susan if she wants to create the missing NAVcustomer/CRMAccount coupling
        // handled by ConfirmStartCoupling
    end;

    [Test]
    [HandlerFunctions('ConfirmStartCoupling,CoupleCustomerPage')]
    [Scope('OnPrem')]
    procedure ShowCoupledCRMEntityStartsCouplingIfNotCoupled()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] ShowCRMEntityFromRecordID() starts coupling if not coupled
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        LibraryCRMIntegration.RegisterTestTableConnection();

        LibrarySales.CreateCustomer(Customer);

        ConfirmStartCouplingReply := true;
        CRMCouplingPageDoCancel := false;
        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmStartCoupling,CoupleCustomerPage')]
    [Scope('OnPrem')]
    procedure ShowCoupledCRMEntityReturnsIfCouplingIsCancelled()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] ShowCRMEntityFromRecordID() exits if coupling is cancelled
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        LibraryCRMIntegration.RegisterTestTableConnection();

        LibrarySales.CreateCustomer(Customer);

        ConfirmStartCouplingReply := true;
        CRMCouplingPageDoCancel := true;
        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);
    end;

    [Test]
    [HandlerFunctions('CRMHyperlinkHandler')]
    [Scope('OnPrem')]
    procedure ShowCoupledCRMEntityOpensHyperlinkIfCoupled()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [CRM Integration Management] [Customer]
        // [SCENARIO] ShowCRMEntityFromRecordID() opens a hyperlink if coupled
        Initialize();

        LibraryCRMIntegration.CreateCRMConnectionSetup('', 'host', true);

        LibraryCRMIntegration.CreateIntegrationTableMappingCustomer(IntegrationTableMapping);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);
    end;

    [Test]
    [HandlerFunctions('ConfirmStartCoupling')]
    [Scope('OnPrem')]
    procedure DontShowCoupledCRMEntityIfTableNotMapped()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] ShowCRMEntityFromRecordID() starts coupling but throws an error if a table is not mapped
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();

        LibrarySales.CreateCustomer(Customer);

        ConfirmStartCouplingReply := true;
        asserterror CRMIntegrationManagement.ShowCRMEntityFromRecordID(Customer.RecordId);
        Assert.ExpectedError('There is no Integration Table Mapping within the filter.');
    end;

    [Test]
    [HandlerFunctions('SyncStartedSkippedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateNewRecordInCRM()
    var
        Customer: Record Customer;
        FilteredCustomer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMAccount: Record "CRM Account";
        CoupledCRMIDBefore: Guid;
        NumIntegrationRecordsBefore: Integer;
        NumAccountsBefore: Integer;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [CRM Integration Management] [Customer]
        // [SCENARIO] CreateNewRecordsInCRM() creates a new record in CRM but skips the already coupled NAV record.
        Initialize();
        LibraryVariableStorage.Clear();
        SetupCRM();

        // [GIVEN] A valid CRM integration setup
        // [GIVEN] A Customer coupled to an Account
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        LibrarySales.CreateCustomer(Customer);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();
        NumIntegrationRecordsBefore := CRMIntegrationRecord.Count();
        NumAccountsBefore := CRMAccount.Count();

        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(SyncNowScheduledMsg);
        CRMIntegrationManagement.CreateNewRecordsInCRM(Customer.RecordId);
        // Executing the Sync Job
        FilteredCustomer.SetRange(SystemId, Customer.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, FilteredCustomer.GetView(), IntegrationTableMapping);

        Assert.AreEqual(NumIntegrationRecordsBefore + 1, CRMIntegrationRecord.Count,
          'When creating a CRM Account using an uncoupled Customer, an integration record should be created.');
        Assert.AreEqual(NumAccountsBefore + 1, CRMAccount.Count,
          'When creating a CRM Account from an uncoupled Customer, a new CRM Account should be created');

        // [WHEN] The coupled Customer is used to create another new Account in CRM
        NumIntegrationRecordsBefore := CRMIntegrationRecord.Count();
        NumAccountsBefore := CRMAccount.Count();
        CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId, CoupledCRMIDBefore);
        LibraryVariableStorage.Enqueue(SyncNowSkippedMsg);
        CRMIntegrationManagement.CreateNewRecordsInCRM(Customer.RecordId);

        // [THEN] Notification: "Sync is skipped"
        // handled by SyncStartedSkippedNotificationHandler
        // [THEN] Scheduling did not happen, temporary mapping record is not created
        asserterror
          JobQueueEntryID :=
            LibraryCRMIntegration.RunJobQueueEntry(
              DATABASE::Customer, FilteredCustomer.GetView(), IntegrationTableMapping);
        Assert.ExpectedError('Table Mapping is not found');
        // [THEN] A new Account should not be created
        Assert.AreEqual(NumAccountsBefore, CRMAccount.Count,
          'When creating a CRM Account using an already coupled Customer, a new CRM Account should not be created');
        // [THEN] The old coupling should not be changed
        Assert.AreEqual(NumIntegrationRecordsBefore, CRMIntegrationRecord.Count,
          'When creating a CRM Account using an already coupled Customer, the old integration record should not be changed.');
        Assert.IsTrue(
          CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId, CoupledCRMIDBefore),
          'When creating a CRM Account using an already coupled Customer, an integration record should not be chnaged.');
    end;

    [Test]
    [HandlerFunctions('MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateNewRecordsInCRMForMany()
    var
        Customer: array[5] of Record Customer;
        CRMAccount: Record "CRM Account";
        FilteredCustomer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationMgtTest: Codeunit "CRM Integration Mgt Test";
        CouplingCount: Integer;
        AccountCount: Integer;
        JobQueueEntryID: Guid;
        IdFilter: Text;
        I: Integer;
        N: Integer;
    begin
        // [FEATURE] [CRM Integration Management] [CreateNewRecordsInCRM for many]
        // [SCENARIO] CreateNewRecordsInCRM() creates new records in CRM for many selected BC records.
        Initialize();
        LibraryVariableStorage.Clear();
        SetupCRM();

        // [GIVEN] A valid CRM integration setup
        // [GIVEN] Many not coupled customers
        N := 5;
        for I := 1 to N do begin
            LibrarySales.CreateCustomer(Customer[I]);
            IdFilter += '|' + Customer[I].SystemId;
        end;
        IdFilter := IdFilter.TrimStart('|');
        CouplingCount := CRMIntegrationRecord.Count();
        AccountCount := CRMAccount.Count();
        // [GIVEN] Only base integration table mappings, no child mappings
        IntegrationTableMapping.SetRange("Table ID", Database::Customer);
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        IntegrationTableMapping.DeleteAll();

        // [WHEN] Calling CreateNewRecordsInCRM for many customers
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(N);
        FilteredCustomer.SetFilter(SystemId, IdFilter);
        CRMIntegrationManagement.CreateNewRecordsInCRM(FilteredCustomer);

        // [THEN] Only one table mapping for all of the selected customers is created
        Assert.AreEqual(1, IntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N, IntegrationTableMapping.GetTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');

        // [WHEN] Executing the sync job when allowed max 3 conditions in the filter
        BindSubscription(CRMIntegrationMgtTest);
        JobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);
        UnbindSubscription(CRMIntegrationMgtTest);

        // [THEN] Synch Job is created, where Inserted = N
        IntegrationSynchJob.Inserted := N;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);

        // [THEN] Coupling is created for all of the selected customers
        Assert.AreEqual(CouplingCount + N, CRMIntegrationRecord.Count(), 'CRMIntegrationRecord.Count()');
        // [THEN] Accounts are created for all of the selected customers
        Assert.AreEqual(AccountCount + N, CRMAccount.Count(), 'CRMAccount.Count()');
        // [THEN] Variable storage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateNewRecordsFromCRMForMany()
    var
        CRMAccount: array[5] of Record "CRM Account";
        Customer: Record Customer;
        FilteredCRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationMgtTest: Codeunit "CRM Integration Mgt Test";
        CouplingCount: Integer;
        CustomerCount: Integer;
        JobQueueEntryID: Guid;
        IdFilter: Text;
        I: Integer;
        N: Integer;
    begin
        // [FEATURE] [CRM Integration Management] [CreateNewRecordsFromCRM for many]
        // [SCENARIO] CreateNewRecordsFromCRM() creates new records in BC for many selected CRM records.
        Initialize();
        LibraryVariableStorage.Clear();
        SetupCRM();

        // [GIVEN] A valid CRM integration setup
        // [GIVEN] Many not coupled accounts
        N := 5;
        for I := 1 to N do begin
            LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount[I]);
            IdFilter += '|' + CRMAccount[I].AccountId;
        end;
        IdFilter := IdFilter.TrimStart('|');
        CouplingCount := CRMIntegrationRecord.Count();
        CustomerCount := Customer.Count();
        // [GIVEN] Only base integration table mappings, no child mappings
        IntegrationTableMapping.SetRange("Table ID", Database::Customer);
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        IntegrationTableMapping.DeleteAll();

        // [WHEN] Calling CreateNewRecordsInCRM for many accounts
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(N);
        FilteredCRMAccount.SetFilter(AccountId, IdFilter);
        CRMIntegrationManagement.CreateNewRecordsFromCRM(FilteredCRMAccount);

        // [THEN] Only one table mapping for all of the selected accounts is created
        Assert.AreEqual(1, IntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N, IntegrationTableMapping.GetIntegrationTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');

        // [WHEN] Executing the sync job when allowed max 3 conditions in the filter
        BindSubscription(CRMIntegrationMgtTest);
        JobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);
        UnbindSubscription(CRMIntegrationMgtTest);

        // [THEN] Synch Job is created, where Inserted = N
        IntegrationSynchJob.Inserted := N;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);

        // [THEN] Coupling is created for all of the selected accounts
        Assert.AreEqual(CouplingCount + N, CRMIntegrationRecord.Count(), 'CRMIntegrationRecord.Count()');
        // [THEN] Customers are created for all of the selected accounts
        Assert.AreEqual(CustomerCount + N, Customer.Count(), 'Customer.Count()');
        // [THEN] Variable storage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateNewRecordsInCRMMixedForMany()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMOrganization: Record "CRM Organization";
        Customer: array[5] of Record Customer;
        Currency: array[5] of Record Currency;
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CustomerIntegrationTableMapping: Record "Integration Table Mapping";
        CurrencyIntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CustomerIntegrationSynchJob: Record "Integration Synch. Job";
        CurrencyIntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationMgtTest: Codeunit "CRM Integration Mgt Test";
        LocalIdListDictionary: Dictionary of [Code[20], List of [Guid]];
        CustomerIdList: List of [Guid];
        CurrencyIdList: List of [Guid];
        CouplingCount: Integer;
        AccountCount: Integer;
        TransactioncurrencyCount: Integer;
        CustomerJobQueueEntryID: Guid;
        CurrencyJobQueueEntryID: Guid;
        I: Integer;
        N: Integer;
        CurrExchRateAmount: Decimal;
    begin
        // [FEATURE] [CRM Integration Management] [CreateNewRecordsInCRM for many]
        // [SCENARIO] CreateNewRecordsInCRM() creates new records in CRM for many selected BC records from different tables.
        Initialize();
        LibraryVariableStorage.Clear();
        SetupCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMOrganization.FindFirst();
        CRMConnectionSetup.Get();
        CRMConnectionSetup.BaseCurrencyId := CRMOrganization.BaseCurrencyId;
        CRMConnectionSetup.Modify();

        // [GIVEN] A valid CRM integration setup
        // [GIVEN] Many not coupled customers and currencies
        N := 5;
        CustomerIntegrationTableMapping.SetRange("Table ID", Database::Customer);
        CustomerIntegrationTableMapping.SetRange("Delete After Synchronization", false);
        CustomerIntegrationTableMapping.FindFirst();
        CurrencyIntegrationTableMapping.SetRange("Table ID", Database::Currency);
        CurrencyIntegrationTableMapping.SetRange("Delete After Synchronization", false);
        CurrencyIntegrationTableMapping.FindFirst();
        LocalIdListDictionary.Add(CustomerIntegrationTableMapping.Name, CustomerIdList);
        LocalIdListDictionary.Add(CurrencyIntegrationTableMapping.Name, CurrencyIdList);
        for I := 1 to N do begin
            LibrarySales.CreateCustomer(Customer[I]);
            LibraryCRMIntegration.CreateCurrency(Currency[I]);
            CurrExchRateAmount := LibraryRandom.RandDec(100, 2);
            LibraryERM.CreateExchangeRate(Currency[I].Code, WorkDate(), CurrExchRateAmount, CurrExchRateAmount);
            CustomerIdList.Add(Customer[I].SystemId);
            CurrencyIdList.Add(Currency[I].SystemId);
        end;
        CustomerIdList.Add(CreateGuid()); // customer with this id does not exist
        CurrencyIdList.Add(CreateGuid()); // currency with this id does not exist
        CouplingCount := CRMIntegrationRecord.Count();
        AccountCount := CRMAccount.Count();
        TransactioncurrencyCount := CRMTransactioncurrency.Count();

        // [GIVEN] Only base integration table mappings, no child mappings
        CustomerIntegrationTableMapping.SetRange("Delete After Synchronization", true);
        CurrencyIntegrationTableMapping.SetRange("Delete After Synchronization", true);
        CustomerIntegrationTableMapping.DeleteAll();
        CurrencyIntegrationTableMapping.DeleteAll();

        // [WHEN] Calling CreateNewRecordsInCRM for many records from different tables
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(2 * N + 2);
        CRMIntegrationManagement.CreateNewRecordsInCRM(LocalIdListDictionary);

        // [THEN] Only one table mapping for all of the selected customers is created
        Assert.AreEqual(1, CustomerIntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(CustomerIntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N + 1, CustomerIntegrationTableMapping.GetTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');
        // [THEN] Only one table mapping for all of the selected currencies is created
        Assert.AreEqual(1, CurrencyIntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(CurrencyIntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N + 1, CurrencyIntegrationTableMapping.GetTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');

        // [WHEN] Executing the sync jobs when allowed max 3 conditions in the filter
        BindSubscription(CRMIntegrationMgtTest);
        CustomerJobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(CustomerIntegrationTableMapping);
        CurrencyJobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(CurrencyIntegrationTableMapping);
        UnbindSubscription(CRMIntegrationMgtTest);
        // [THEN] Synch Jobs are created, where Inserted = N in each
        CustomerIntegrationSynchJob.Inserted := N;
        CurrencyIntegrationSynchJob.Inserted := N;
        LibraryCRMIntegration.VerifySyncJob(CustomerJobQueueEntryID, CustomerIntegrationTableMapping, CustomerIntegrationSynchJob);
        LibraryCRMIntegration.VerifySyncJob(CurrencyJobQueueEntryID, CurrencyIntegrationTableMapping, CurrencyIntegrationSynchJob);

        // [THEN] Coupling is created for all of the selected customers and currencies
        Assert.AreEqual(CouplingCount + 2 * N, CRMIntegrationRecord.Count(), 'CRMIntegrationRecord.Count()');
        // [THEN] Accounts are created for all of the selected customers
        Assert.AreEqual(AccountCount + N, CRMAccount.Count(), 'CRMAccount.Count()');
        // [THEN] Accounts are created for all of the selected currencies
        Assert.AreEqual(TransactioncurrencyCount + N, CRMTransactioncurrency.Count(), 'CRMTransactioncurrency.Count()');
        // [THEN] Variable storage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateNewRecordsFromCRMMixedForMany()
    var
        CRMAccount: array[5] of Record "CRM Account";
        CRMSystemuser: array[5] of Record "CRM Systemuser";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        AccountIntegrationTableMapping: Record "Integration Table Mapping";
        SystemuserIntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        AccountIntegrationSynchJob: Record "Integration Synch. Job";
        SystemuserIntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationMgtTest: Codeunit "CRM Integration Mgt Test";
        CRMIdListDictionary: Dictionary of [Code[20], List of [Guid]];
        AccountIdList: List of [Guid];
        SystemuserIdList: List of [Guid];
        CouplingCount: Integer;
        CustomerCount: Integer;
        SalespersonCount: Integer;
        AccountJobQueueEntryID: Guid;
        SystemuserJobQueueEntryID: Guid;
        I: Integer;
        N: Integer;
    begin
        // [FEATURE] [CRM Integration Management] [CreateNewRecordsInCRM for many]
        // [SCENARIO] CreateNewRecordsInCRM() creates new records in CRM for many selected CRM records from different tables.
        Initialize();
        LibraryVariableStorage.Clear();
        SetupCRM();

        // [GIVEN] A valid CRM integration setup
        // [GIVEN] Many not coupled accounts and systemusers
        N := 5;
        AccountIntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Account");
        AccountIntegrationTableMapping.SetRange("Delete After Synchronization", false);
        AccountIntegrationTableMapping.FindFirst();
        SystemuserIntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Systemuser");
        SystemuserIntegrationTableMapping.SetRange("Delete After Synchronization", false);
        SystemuserIntegrationTableMapping.FindFirst();
        CRMIdListDictionary.Add(AccountIntegrationTableMapping.Name, AccountIdList);
        CRMIdListDictionary.Add(SystemuserIntegrationTableMapping.Name, SystemuserIdList);
        for I := 1 to N do begin
            LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount[I]);
            LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser[I]);
            AccountIdList.Add(CRMAccount[I].AccountId);
            SystemuserIdList.Add(CRMSystemuser[I].SystemUserId);
        end;
        AccountIdList.Add(CreateGuid()); // account with this id does not exist
        SystemuserIdList.Add(CreateGuid()); // systemuser with this id does not exist
        CouplingCount := CRMIntegrationRecord.Count();
        CustomerCount := Customer.Count();
        SalespersonCount := SalespersonPurchaser.Count();

        // [GIVEN] Only base integration table mappings, no child mappings
        AccountIntegrationTableMapping.SetRange("Delete After Synchronization", true);
        SystemuserIntegrationTableMapping.SetRange("Delete After Synchronization", true);
        AccountIntegrationTableMapping.DeleteAll();
        SystemuserIntegrationTableMapping.DeleteAll();

        // [WHEN] Calling CreateNewRecordsfromCRM for many records from different tables
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(2 * N + 2);
        CRMIntegrationManagement.CreateNewRecordsFromCRM(CRMIdListDictionary);

        // [THEN] Only one table mapping for all of the selected accounts is created
        Assert.AreEqual(1, AccountIntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(AccountIntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N + 1, AccountIntegrationTableMapping.GetIntegrationTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');
        // [THEN] Only one table mapping for all of the selected systemusers is created
        Assert.AreEqual(1, SystemuserIntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(SystemuserIntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N + 1, SystemuserIntegrationTableMapping.GetIntegrationTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');

        // [WHEN] Executing the sync jobs when allowed max 3 conditions in the filter
        BindSubscription(CRMIntegrationMgtTest);
        AccountJobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(AccountIntegrationTableMapping);
        SystemuserJobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(SystemuserIntegrationTableMapping);
        UnbindSubscription(CRMIntegrationMgtTest);
        // [THEN] Synch Jobs are created, where Inserted = N in each
        AccountIntegrationSynchJob.Inserted := N;
        SystemuserIntegrationSynchJob.Inserted := N;
        LibraryCRMIntegration.VerifySyncJob(AccountJobQueueEntryID, AccountIntegrationTableMapping, AccountIntegrationSynchJob);
        LibraryCRMIntegration.VerifySyncJob(SystemuserJobQueueEntryID, systemuserIntegrationTableMapping, SystemuserIntegrationSynchJob);

        // [THEN] Coupling is created for all of the selected customers and currencies
        Assert.AreEqual(CouplingCount + 2 * N, CRMIntegrationRecord.Count(), 'CRMIntegrationRecord.Count()');
        // [THEN] Accounts are created for all of the selected customers
        Assert.AreEqual(CustomerCount + N, Customer.Count(), 'Customer.Count()');
        // [THEN] Accounts are created for all of the selected currencies
        Assert.AreEqual(SalespersonCount + N, SalespersonPurchaser.Count(), 'SalespersonPurchaser.Count()');
        // [THEN] Variable storage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SynchDirectionStrMenuHandler,MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UpdateMultipleNowToCRMForMany()
    var
        Customer: array[5] of Record Customer;
        CRMAccount: array[5] of Record "CRM Account";
        FilteredCustomer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationMgtTest: Codeunit "CRM Integration Mgt Test";
        JobQueueEntryID: Guid;
        IdFilter: Text;
        I: Integer;
        N: Integer;
    begin
        // [FEATURE] [CRM Integration Management] [UpdateMultipleNow for many]
        // [SCENARIO] UpdateMultipleNow() updates records in CRM for many selected records.
        Initialize();
        LibraryVariableStorage.Clear();
        SetupCRM();

        // [GIVEN] A valid CRM integration setup
        // [GIVEN] Many coupled and synched customers and accounts
        IntegrationTableMapping.SetRange("Table ID", Database::Customer);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.FindFirst();
        N := 5;
        for I := 1 to N do begin
            LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[I], CRMAccount[I]);
            CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer[I].RecordId(), true, false);
            IdFilter += '|' + Customer[I].SystemId;
        end;
        IdFilter := IdFilter.TrimStart('|');

        // [GIVEN] Only base integration table mappings, no child mappings
        IntegrationTableMapping.SetRange("Table ID", Database::Customer);
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        IntegrationTableMapping.DeleteAll();

        // [WHEN] Calling UpdateMultipleNow for many customers with direction to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(SynchDirection::ToCRM);
        LibraryVariableStorage.Enqueue(N);
        FilteredCustomer.SetFilter(SystemId, IdFilter);
        CRMIntegrationManagement.UpdateMultipleNow(FilteredCustomer);

        // [THEN] Only one table mapping for all of the selected customers is created
        Assert.AreEqual(1, IntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N, IntegrationTableMapping.GetTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');

        // [WHEN] Executing the sync job when allowed max 3 conditions in the filter
        BindSubscription(CRMIntegrationMgtTest);
        JobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);
        UnbindSubscription(CRMIntegrationMgtTest);

        // [THEN] Synch Job is created, where Modified = N
        IntegrationSynchJob.Modified := N;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        // [THEN] Variable storage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SynchDirectionStrMenuHandler,MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UpdateMultipleNowFromCRMForMany()
    var
        Customer: array[5] of Record Customer;
        CRMAccount: array[5] of Record "CRM Account";
        FilteredCustomer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationMgtTest: Codeunit "CRM Integration Mgt Test";
        JobQueueEntryID: Guid;
        IdFilter: Text;
        I: Integer;
        N: Integer;
    begin
        // [FEATURE] [CRM Integration Management] [UpdateMultipleNow for many]
        // [SCENARIO] UpdateMultipleNow() updates records in BC for many selected records.
        Initialize();
        LibraryVariableStorage.Clear();
        SetupCRM();

        // [GIVEN] A valid CRM integration setup
        // [GIVEN] Many coupled and synched customers and accounts
        IntegrationTableMapping.SetRange("Table ID", Database::Customer);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.FindFirst();
        N := 5;
        for I := 1 to N do begin
            LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[I], CRMAccount[I]);
            CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer[I].RecordId(), true, false);
            IdFilter += '|' + Customer[I].SystemId;
        end;
        IdFilter := IdFilter.TrimStart('|');

        // [GIVEN] Only base integration table mappings, no child mappings
        IntegrationTableMapping.SetRange("Table ID", Database::Customer);
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        IntegrationTableMapping.DeleteAll();

        // [WHEN] Calling UpdateMultipleNow for many customers with direction from CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(SynchDirection::ToNAV);
        LibraryVariableStorage.Enqueue(N);
        FilteredCustomer.SetFilter(SystemId, IdFilter);
        CRMIntegrationManagement.UpdateMultipleNow(FilteredCustomer);

        // [THEN] Only one table mapping for all of the selected customer is created
        Assert.AreEqual(1, IntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N, IntegrationTableMapping.GetIntegrationTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');

        // [WHEN] Executing the sync job when allowed max 3 conditions in the filter
        BindSubscription(CRMIntegrationMgtTest);
        JobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);
        UnbindSubscription(CRMIntegrationMgtTest);

        // [THEN] Synch Job is created, where Modified = N
        IntegrationSynchJob.Modified := N;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        // [THEN] Variable storage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SynchDirectionStrMenuHandler,MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UpdateMultipleNowMixedToCRMForMany()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMOrganization: Record "CRM Organization";
        Customer: array[5] of Record Customer;
        CRMAccount: array[5] of Record "CRM Account";
        Currency: array[5] of Record Currency;
        CRMTransactioncurrency: array[5] of Record "CRM Transactioncurrency";
        CustomerIntegrationTableMapping: Record "Integration Table Mapping";
        CurrencyIntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CustomerIntegrationSynchJob: Record "Integration Synch. Job";
        CurrencyIntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationMgtTest: Codeunit "CRM Integration Mgt Test";
        CustomerJobQueueEntryID: Guid;
        CurrencyJobQueueEntryID: Guid;
        IdFilter: Text;
        I: Integer;
        N: Integer;
    begin
        // [FEATURE] [CRM Integration Management] [UpdateMultipleNow for many]
        // [SCENARIO] UpdateMultipleNow() updates records in CRM for many selected records.
        Initialize();
        LibraryVariableStorage.Clear();
        SetupCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMOrganization.FindFirst();
        CRMConnectionSetup.Get();
        CRMConnectionSetup.BaseCurrencyId := CRMOrganization.BaseCurrencyId;
        CRMConnectionSetup.Modify();
        // [GIVEN] A valid CRM integration setup

        // [GIVEN] Many coupled and synched customers and accounts
        // [GIVEN] Many coupled and synched currencies and transactioncurrencies
        CustomerIntegrationTableMapping.SetRange("Table ID", Database::Customer);
        CustomerIntegrationTableMapping.SetRange("Delete After Synchronization", false);
        CustomerIntegrationTableMapping.FindFirst();
        CurrencyIntegrationTableMapping.SetRange("Table ID", Database::Currency);
        CurrencyIntegrationTableMapping.SetRange("Delete After Synchronization", false);
        CurrencyIntegrationTableMapping.FindFirst();
        N := 5;
        for I := 1 to N do begin
            LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[I], CRMAccount[I]);
            CreateCoupledAndTransactionCurrencies(Currency[I], CRMTransactioncurrency[I]);
            CRMIntegrationTableSynch.SynchRecord(CustomerIntegrationTableMapping, Customer[I].RecordId(), true, false);
            CRMIntegrationTableSynch.SynchRecord(CurrencyIntegrationTableMapping, Currency[I].RecordId(), true, false);
            IdFilter += '|' + Customer[I].SystemId;
            IdFilter += '|' + Currency[I].SystemId;
        end;
        IdFilter := IdFilter.TrimStart('|');

        // [GIVEN] Only base integration table mappings, no child mappings
        CustomerIntegrationTableMapping.SetRange("Delete After Synchronization", true);
        CurrencyIntegrationTableMapping.SetRange("Delete After Synchronization", true);
        CustomerIntegrationTableMapping.DeleteAll();
        CurrencyIntegrationTableMapping.DeleteAll();

        // [WHEN] Calling UpdateMultipleNow for many records from different tables with direction to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(SynchDirection::ToCRM);
        LibraryVariableStorage.Enqueue(2 * N);
        CRMIntegrationRecord.SetFilter("Integration ID", IdFilter);
        CRMIntegrationManagement.UpdateMultipleNow(CRMIntegrationRecord);

        // [THEN] Only one table mapping for all of the selected customers is created
        Assert.AreEqual(1, CustomerIntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(CustomerIntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N, CustomerIntegrationTableMapping.GetTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');
        // [THEN] Only one table mapping for all of the selected currencies is created
        Assert.AreEqual(1, CurrencyIntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(CurrencyIntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N, CurrencyIntegrationTableMapping.GetTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');

        // [WHEN] Executing the sync jobs when allowed max 3 conditions in the filter
        BindSubscription(CRMIntegrationMgtTest);
        CustomerJobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(CustomerIntegrationTableMapping);
        CurrencyJobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(CurrencyIntegrationTableMapping);
        UnbindSubscription(CRMIntegrationMgtTest);
        // [THEN] Synch Jobs are created, where Modified = N in each
        CustomerIntegrationSynchJob.Modified := N;
        CurrencyIntegrationSynchJob.Modified := N;
        LibraryCRMIntegration.VerifySyncJob(CustomerJobQueueEntryID, CustomerIntegrationTableMapping, CustomerIntegrationSynchJob);
        LibraryCRMIntegration.VerifySyncJob(CurrencyJobQueueEntryID, CurrencyIntegrationTableMapping, CurrencyIntegrationSynchJob);

        // [THEN] Variable storage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SynchDirectionStrMenuHandler,MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UpdateMultipleNowNixedFromCRMForMany()
    var
        Customer: array[5] of Record Customer;
        CRMAccount: array[5] of Record "CRM Account";
        SalespersonPurchaser: array[5] of Record "Salesperson/Purchaser";
        CRMSystemuser: array[5] of Record "CRM Systemuser";
        CustomerIntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonIntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CustomerIntegrationSynchJob: Record "Integration Synch. Job";
        SalespersonIntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationMgtTest: Codeunit "CRM Integration Mgt Test";
        CustomerJobQueueEntryID: Guid;
        SalespersonJobQueueEntryID: Guid;
        IdFilter: Text;
        I: Integer;
        N: Integer;
    begin
        // [FEATURE] [CRM Integration Management] [UpdateMultipleNow for many]
        // [SCENARIO] UpdateMultipleNow() updates records in BC for many selected records.
        Initialize();
        LibraryVariableStorage.Clear();
        SetupCRM();

        // [GIVEN] A valid CRM integration setup

        // [GIVEN] Many coupled and synched customers and accounts
        // [GIVEN] Many coupled and synched salespersons and users
        CustomerIntegrationTableMapping.SetRange("Table ID", Database::Customer);
        CustomerIntegrationTableMapping.SetRange("Delete After Synchronization", false);
        CustomerIntegrationTableMapping.FindFirst();
        SalespersonIntegrationTableMapping.SetRange("Table ID", Database::"Salesperson/Purchaser");
        SalespersonIntegrationTableMapping.SetRange("Delete After Synchronization", false);
        SalespersonIntegrationTableMapping.FindFirst();
        N := 5;
        for I := 1 to N do begin
            LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[I], CRMAccount[I]);
            LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[I], CRMSystemuser[I]);
            CRMIntegrationTableSynch.SynchRecord(CustomerIntegrationTableMapping, Customer[I].RecordId(), true, false);
            CRMIntegrationTableSynch.SynchRecord(SalespersonIntegrationTableMapping, SalespersonPurchaser[I].RecordId(), true, false);
            IdFilter += '|' + Customer[I].SystemId;
            IdFilter += '|' + SalespersonPurchaser[I].SystemId;
        end;
        IdFilter := IdFilter.TrimStart('|');

        // [GIVEN] Only base integration table mappings, no child mappings
        CustomerIntegrationTableMapping.SetRange("Delete After Synchronization", true);
        SalespersonIntegrationTableMapping.SetRange("Delete After Synchronization", true);
        CustomerIntegrationTableMapping.DeleteAll();
        SalespersonIntegrationTableMapping.DeleteAll();

        // [WHEN] Calling UpdateMultipleNow for many records from different tables with direction to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(SynchDirection::ToNAV);
        LibraryVariableStorage.Enqueue(2 * N);
        CRMIntegrationRecord.SetFilter("Integration ID", IdFilter);
        CRMIntegrationManagement.UpdateMultipleNow(CRMIntegrationRecord);

        // [THEN] Only one table mapping for all of the selected customers is created
        Assert.AreEqual(1, CustomerIntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(CustomerIntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N, CustomerIntegrationTableMapping.GetIntegrationTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');
        // [THEN] Only one table mapping for all of the selected salesperson is created
        Assert.AreEqual(1, SalespersonIntegrationTableMapping.Count(), 'Only one table mapping should be created for all records');
        Assert.IsTrue(SalespersonIntegrationTableMapping.FindFirst(), 'Table mapping is not found');
        Assert.AreEqual(N, SalespersonIntegrationTableMapping.GetIntegrationTableFilter().Split('|').Count(), 'Table mapping has incorrect table filter');

        // [WHEN] Executing the sync jobs when allowed max 3 conditions in the filter
        BindSubscription(CRMIntegrationMgtTest);
        CustomerJobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(CustomerIntegrationTableMapping);
        SalespersonJobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(SalespersonIntegrationTableMapping);
        UnbindSubscription(CRMIntegrationMgtTest);
        // [THEN] Synch Jobs are created, where Modified = N in each
        CustomerIntegrationSynchJob.Modified := N;
        SalespersonIntegrationSynchJob.Modified := N;
        LibraryCRMIntegration.VerifySyncJob(CustomerJobQueueEntryID, CustomerIntegrationTableMapping, CustomerIntegrationSynchJob);
        LibraryCRMIntegration.VerifySyncJob(SalespersonJobQueueEntryID, SalespersonIntegrationTableMapping, SalespersonIntegrationSynchJob);

        // [THEN] Variable storage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNoOfCRMCases()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [CRM Integration Management] [Case]
        // [SCENARIO] GetNoOfCRMCases() returns a number of cases coupled to a CRM account
        // [GIVEN] A valid CRM integration setup
        // [GIVEN] A CRM customer having a number of related CRM cases
        Initialize();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMCaseToCRMAccount(CRMAccount);

        // [WHEN] GetNoOfCRMCases is invoked
        // [THEN] The correct number of associated CRM cases is returned
        Assert.AreEqual(4, CRMIntegrationManagement.GetNoOfCRMCases(Customer), 'Incorrect number of CRM cases');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNoOfCRMOpportunities()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [CRM Integration Management] [Opportunity]
        // [SCENARIO] GetNoOfCRMOpportunities() returns a number of opportunities coupled to a CRM account
        // [GIVEN] A valid CRM integration setup
        // [GIVEN] A CRM customer having a number of related CRM opportunities
        Initialize();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.AddCRMOpportunityToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMOpportunityToCRMAccount(CRMAccount);

        // [WHEN] GetNoOfCRMOpportunities is invoked
        // [THEN] The correct number of associated CRM opportunities is returned
        Assert.AreEqual(2, CRMIntegrationManagement.GetNoOfCRMOpportunities(Customer), 'Incorrect number of CRM opportunities');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNoOfCRMQuotes()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        // [FEATURE] [CRM Integration Management] [Quote]
        // [SCENARIO] GetNoOfCRMQuotes() return a number of quotes coupled to a CRM account
        // [GIVEN] A valid CRM integration setup
        // [GIVEN] A CRM customer having a number of related CRM quotes
        Initialize();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.AddCRMQuoteToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMQuoteToCRMAccount(CRMAccount);
        LibraryCRMIntegration.AddCRMQuoteToCRMAccount(CRMAccount);

        // [WHEN] GetNoOfCRMQuotes is invoked
        // [THEN] The correct number of associated CRM quotes is returned
        Assert.AreEqual(3, CRMIntegrationManagement.GetNoOfCRMQuotes(Customer), 'Incorrect number of CRM quotes');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingCurrency()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Currency] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Currency"
        // [THEN] Mapped to "CRM Transactioncurrency", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::Currency, DATABASE::"CRM Transactioncurrency", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', '', true)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingCustomer()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Customer] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Customer"
        // [THEN] Mapped to "CRM Account", Direction is "Bidirectional",
        // [THEN] "Table Filter" is 'Blocked' is ' ', "Integration Table Filter" is 'Active Customer', "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field6=1(3),Field54=1(0),Field202=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Customer, DATABASE::"CRM Account", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field39=1(0))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingContact()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Contact] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Contact"
        // [THEN] Mapped to "CRM Contact", Direction is "Bidirectional",
        // [THEN] "Table Filter" is 'Type' is 'Person', "Integration Table Filter" is 'Active Contact', "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field71=1(0),Field134=1(<>{00000000-0000-0000-0000-000000000000}),Field140=1(1),Field192=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Contact, DATABASE::"CRM Contact", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field5050=1(1),Field5051=1(<>''''))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingVendor()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Customer] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Vendor"
        // [THEN] Mapped to "CRM Account", Direction is "Bidirectional",
        // [THEN] "Table Filter" is 'Blocked' is ' ', "Integration Table Filter" is 'Active Vendor', "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field6=1(11),Field54=1(0),Field202=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Vendor, DATABASE::"CRM Account", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field39=1(0))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingItem()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Customer] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Item"
        // [THEN] Mapped to "CRM Account", Direction is "Bidirectional",
        // [THEN] "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field8=1(0),Field27=1(0),Field62=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Item, DATABASE::"CRM Product", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field54=1(0))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingResource()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Customer] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Item"
        // [THEN] Mapped to "CRM Account", Direction is "Bidirectional",
        // [THEN] "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field8=1(2),Field27=1(0),Field62=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Resource, DATABASE::"CRM Product", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field38=1(0))', ExpectedIntTableFilter, true);
    end;

#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingCustPriceGroup()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Price List] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Customer Price Group"
        // [THEN] Mapped to "CRM Pricelevel", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field31=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::"Customer Price Group", DATABASE::"CRM Pricelevel", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingSalesPrice()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Price List] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Sales Price"
        // [THEN] Mapped to "CRM Productpricelevel", Direction is "To Integration Table",
        // [THEN] "Table Filter" is ("Sales Type"=Customer Price Group,"Sales Code"<>''),
        // [THEN] no "Integration Table Filter", "Synch. Only Coupled Records" is 'No'
        VerifyTableMapping(
          DATABASE::"Sales Price", DATABASE::"CRM Productpricelevel", IntegrationTableMapping.Direction::ToIntegrationTable,
          'VERSION(1) SORTING(Field1,Field13,Field2,Field4,Field3,Field5700,Field5400,Field14) WHERE(Field13=1(1),Field2=1(<>''''))', '', false);
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingPriceListHeader()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Price List] [Direction]
        Initialize(true);
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Price List Header"
        // [THEN] Mapped to "CRM Pricelevel", Direction is "To Integration Table",
        // [THEN] "Table Filter" is "Price Type" is 'Sale', "Amount Type" is 'Price', "Allow Editing Defaults" is 'Yes'
        // [THEN] no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field31=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::"Price List Header", DATABASE::"CRM Pricelevel", IntegrationTableMapping.Direction::ToIntegrationTable,
          'VERSION(1) SORTING(Field1) WHERE(Field8=1(1),Field9=1(17),Field20=1(1))', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingPriceListLine()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Price List] [Direction]
        Initialize(true);
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Price List Line"
        // [THEN] Mapped to "CRM Productpricelevel", Direction is "To Integration Table",
        // [THEN] "Table Filter" is ("Price Type" is 'Sale', "Amount Type" is 'Price', "Asset Type" is 'Item'),
        // [THEN] no "Integration Table Filter", "Synch. Only Coupled Records" is 'No'
        VerifyTableMapping(
          DATABASE::"Price List Line", DATABASE::"CRM Productpricelevel", IntegrationTableMapping.Direction::ToIntegrationTable,
          'VERSION(1) SORTING(Field1,Field2) WHERE(Field7=1(10|30),Field14=1(0),Field16=1(17),Field28=1(1))', '', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingUnitGroup()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Unit Group] [Direction]
        Initialize(false);
        ResetDefaultCRMSetupConfiguration(true);
        // [WHEN] Find Integration Table Mapping for "Unit Group"
        // [THEN] Mapped to "CRM Uomschedule", Direction is "To Integration Table",
        // [THEN] no "Table Filter"
        // [THEN] no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::"Unit Group", DATABASE::"CRM Uomschedule", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', '', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingItemUnitOfMeasure()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Item Unit of Measure] [Direction]
        Initialize(false);
        ResetDefaultCRMSetupConfiguration(true);
        // [WHEN] Find Integration Table Mapping for "Item Unit of Measure"
        // [THEN] Mapped to "CRM Uom", Direction is "To Integration Table",
        // [THEN] no "Table Filter"
        // [THEN] no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::"Item Unit of Measure", DATABASE::"CRM Uom", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', '', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingResourceUnitOfMeasure()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Resource Unit of Measure] [Direction]
        Initialize(false);
        ResetDefaultCRMSetupConfiguration(true);
        // [WHEN] Find Integration Table Mapping for "Resource Unit of Measure"
        // [THEN] Mapped to "CRM Uom", Direction is "To Integration Table",
        // [THEN] no "Table Filter"
        // [THEN] no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::"Resource Unit of Measure", DATABASE::"CRM Uom", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', '', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingSalesInvoice()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Invoice] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Sales Invoice Header"
        // [THEN] Mapped to "CRM Invoice", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field95=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::"Sales Invoice Header", DATABASE::"CRM Invoice", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', ExpectedIntTableFilter, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingSalesInvoiceLine()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Invoice] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Sales Invoice Line"
        // [THEN] Mapped to "CRM Invoicedetail", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is No
        VerifyTableMapping(
          DATABASE::"Sales Invoice Line", DATABASE::"CRM Invoicedetail", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', '', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingSalesPerson()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Salesperson] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Salesperson/Purchaser"
        // [THEN] Mapped to "CRM Systemuser", Direction is "From Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", not "Integration user mode", is "Lisenced User", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser", IntegrationTableMapping.Direction::FromIntegrationTable,
          '', 'VERSION(1) SORTING(Field1) WHERE(Field31=1(0),Field96=1(0),Field107=1(1))', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingUnitOfMeasure()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        // [FEATURE] [Table Mapping] [Unit Of Measure] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Unit Of Measure"
        // [THEN] Mapped to "CRM Uomschedule", Direction is "To Integration Table",
        // [THEN] no "Table Filter", no "Integration Table Filter", "Synch. Only Coupled Records" is Yes
        VerifyTableMapping(
          DATABASE::"Unit of Measure", DATABASE::"CRM Uomschedule", IntegrationTableMapping.Direction::ToIntegrationTable,
          '', '', true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultTableMappingOpportunity()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSCompany: Record "CDS Company";
        ExpectedIntTableFilter: Text;
    begin
        // [FEATURE] [Table Mapping] [Opportunity] [Direction]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        // [WHEN] Find Integration Table Mapping for "Opportunity"
        // [THEN] Mapped to "CRM Opportunity", Direction is "Bidirectional",
        // [THEN] "Table Filter" is correct, "Integration Table Filter" is correct, "Synch. Only Coupled Records" is No
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        ExpectedIntTableFilter := StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field111=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId));
        VerifyTableMapping(
          DATABASE::Opportunity, DATABASE::"CRM Opportunity", IntegrationTableMapping.Direction::Bidirectional,
          'VERSION(1) SORTING(Field1) WHERE(Field10=1(0|1))', ExpectedIntTableFilter, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkForUnsupportedEntity()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [CRM Integration Management]
        // [SCENARIO] IsRecordCoupledToCRM() fails if entity is not supported
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        asserterror RunHyperlinkTest(CustomerBankAccount.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkForCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [CRM Integration Management] [Customer]
        // [SCENARIO] IsRecordCoupledToCRM() returns TRUE if Customers are coupled
        LibrarySales.CreateCustomer(Customer);
        RunHyperlinkTest(Customer.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkForSalesPerson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // [FEATURE] [CRM Integration Management] [Salesperson]
        // [SCENARIO] IsRecordCoupledToCRM() returns TRUE if Salespersons are coupled
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        RunHyperlinkTest(SalespersonPurchaser.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HyperlinkForContact()
    var
        Contact: Record Contact;
    begin
        // [FEATURE] [CRM Integration Management] [Contact]
        // [SCENARIO] IsRecordCoupledToCRM() returns TRUE if Contacts are coupled
        Contact.Init();
        Contact.Insert();
        RunHyperlinkTest(Contact.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenContactCardPageForCoupledCRMContact()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [CRM Integration Management] [Contact] [UI]
        Initialize();
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);

        ContactCard.Trap();
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMContact.ContactId, 'contact');

        Assert.AreEqual(Contact."No.", ContactCard."No.".Value, 'The contact card should open for the correct record');
        ContactCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenCurrencyCardPageForCoupledCRMCurrency()
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CurrencyCard: TestPage "Currency Card";
    begin
        // [FEATURE] [CRM Integration Management] [Currency] [UI]
        Initialize();
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);

        CurrencyCard.Trap();
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMTransactioncurrency.TransactionCurrencyId, 'transactioncurrency');

        Assert.AreEqual(Currency.Code, CurrencyCard.Code.Value, 'The currency card should open for the correct record');
        CurrencyCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenCustomerCardPageForCoupledCRMAccount()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [CRM Integration Management] [Customer] [UI]
        Initialize();
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        CustomerCard.Trap();
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMAccount.AccountId, 'account');

        Assert.AreEqual(Customer."No.", CustomerCard."No.".Value, 'The customer card should open for the correct record');
        CustomerCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenCustPriceGroupListPageForCoupledCRMPricelevel()
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerPriceGroups: TestPage "Customer Price Groups";
    begin
        // [FEATURE] [CRM Integration Management] [Price List] [UI]
        Initialize();
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);

        CustomerPriceGroups.Trap();
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMPricelevel.PriceLevelId, 'pricelevel');

        Assert.AreEqual(
          CustomerPriceGroup.Code, CustomerPriceGroups.Code.Value,
          'The customer price group list should open for the correct record');
        CustomerPriceGroups.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenItemCardPageForCoupledCRMProduct()
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [UI]
        Initialize();
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);

        ItemCard.Trap();
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMProduct.ProductId, 'product');

        Assert.AreEqual(Item."No.", ItemCard."No.".Value, 'The item card should open for the correct record');
        ItemCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenResourceCardPageForCoupledCRMProduct()
    var
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
        ResourceCard: TestPage "Resource Card";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [UI]
        Initialize();
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);

        ResourceCard.Trap();
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMProduct.ProductId, 'product');

        Assert.AreEqual(Resource."No.", ResourceCard."No.".Value, 'The resource card should open for the correct record');
        ResourceCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpeSalesPersonCardPageForCoupledCRMSysuser()
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonPurchaserCard: TestPage "Salesperson/Purchaser Card";
    begin
        // [FEATURE] [CRM Integration Management] [Salesperson] [UI]
        Initialize();
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        SalespersonPurchaserCard.Trap();
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMSystemuser.SystemUserId, 'sYsTeMuSeR');

        Assert.AreEqual(
          SalespersonPurchaser.Code, SalespersonPurchaserCard.Code.Value,
          'The salesperson card should open for the correct record');
        SalespersonPurchaserCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenUOMListPageForCoupledCRMUOM()
    var
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        UnitOfMeasure: Record "Unit of Measure";
        UnitsOfMeasure: TestPage "Units of Measure";
    begin
        // [FEATURE] [CRM Integration Management] [Unit Of Measure] [UI]
        Initialize();
        ResetDefaultCRMSetupConfiguration(false);
        CRMUom.Name := 'BOX';
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);

        UnitsOfMeasure.Trap();
        CRMIntegrationManagement.OpenCoupledNavRecordPage(CRMUomschedule.UoMScheduleId, 'uomschedule');

        Assert.AreEqual(UnitOfMeasure.Code, UnitsOfMeasure.Code.Value, 'The units of measure list should open showing the correct record');
        UnitsOfMeasure.Close();
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SendCoupledAndPostedFCYSalesOrderToCRM()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        IntegrationSynchJob: Record "Integration Synch. Job";
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSalesorder: Record "CRM Salesorder";
        CRMInvoice: Record "CRM Invoice";
        CRMInvoicedetail: Record "CRM Invoicedetail";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 380219] Posted Sales Invoice in FCY can be coupled to CRM Invoice if the CRM Order exists.
        Initialize();

        // [GIVEN] CRM integration setup
        SetupCRM();

        // [GIVEN] Coupled Customer "X"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Coupled Currency "USD"
        CreateCoupledAndTransactionCurrencies(Currency, CRMTransactioncurrency);

        // [GIVEN] Posted Sales Invoice generated in NAV with Customer "X" and Currency "USD"
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", Currency.Code);

        // [GIVEN] CRM Order, where OrderNumber = Invoice."Your Reference"
        LibraryCRMIntegration.CreateCRMSalesOrderWithCustomerFCY(
          CRMSalesorder, CRMAccount.AccountId, CRMTransactioncurrency.TransactionCurrencyId);
        CRMSalesorder.OrderNumber := SalesInvHeader."Your Reference";
        CRMSalesorder.Modify();

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange(SystemId, SalesInvHeader.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView(), IntegrationTableMapping);

        // [THEN] The notification: "Synchronization has been scheduled."
        // [THEN] Synch Job is created, where Inserted = 1
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        // [THEN] CRM Invoice is created, where TransactionCurrencyId is "USD"
        CRMInvoice.SetRange(InvoiceNumber, SalesInvHeader."No.");
        CRMInvoice.FindFirst();
        CRMInvoice.TestField(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);
        // [THEN] CRM Invoice Line is created, where TransactionCurrencyId is "USD"
        CRMInvoicedetail.SetRange(InvoiceId, CRMInvoice.InvoiceId);
        CRMInvoicedetail.SetRange(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);
        // CRMInvoicedetail.SETRANGE(ExchangeRate,SalesInvHeader."Currency Factor");
        Assert.RecordIsNotEmpty(CRMInvoicedetail);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotPossibleToCoupleCRMSalesOrderInFCYToNAV()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 380219] It is possible to couple CRM Sales Order in FCY to NAV
        Initialize();

        SetupCRM();
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is S.Order Integration Enabled" := true;
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup.Modify();

        // [GIVEN] CRM Sales Order with "Currency Code" = "USD"
        CreateCRMSalesOrderInFCY(CRMSalesorder);

        // [WHEN] Couple CRM Sales Order to NAV
        CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order with "Currency Code" = "USD" created
        CRMTransactioncurrency.Get(CRMSalesorder.TransactionCurrencyId);
        SalesHeader.TestField("Currency Code", CRMTransactioncurrency.ISOCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ExtendedAmountIsCopiedToCRMInvoiceLine()
    var
        Customer: Record Customer;
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMAccount: Record "CRM Account";
        CRMInvoice: Record "CRM Invoice";
        CRMInvoicedetail: Record "CRM Invoicedetail";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Invoice Line]
        // [SCENARIO 173456] Invoice Line's "Amount Incl. VAT" is copied to CRM Invoice Line's "Extended Amount"
        Initialize();
        SetupCRM();
        // [GIVEN] Posted Sales Invoice generated in NAV, with one line,
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');
        // [GIVEN] where Quantity = 4, Amount = 1000, "Amount Including VAT" = 1050
        SalesInvoiceLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvoiceLine.FindFirst();

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange(SystemId, SalesInvHeader.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView(), IntegrationTableMapping);

        // [THEN] The notification: "Synchronization has been scheduled."
        // [THEN] Synch Job is created, where Inserted = 1
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        // [THEN] CRM Invoice Line is created,
        CRMInvoice.SetRange(InvoiceNumber, SalesInvHeader."No.");
        CRMInvoice.FindFirst();
        CRMInvoicedetail.SetRange(InvoiceId, CRMInvoice.InvoiceId);
        CRMInvoicedetail.SetRange(LineItemNumber, SalesInvoiceLine."Line No.");
        CRMInvoicedetail.FindFirst();
        // [THEN] where Quantity = 4, BaseAmount = 1000, ExtendedAmount = 1050, Tax = 50
        CRMInvoicedetail.TestField(Quantity, SalesInvoiceLine.Quantity);
        CRMInvoicedetail.TestField(BaseAmount, SalesInvoiceLine.Amount);
        CRMInvoicedetail.TestField(ExtendedAmount, SalesInvoiceLine."Amount Including VAT");
        CRMInvoicedetail.TestField(Tax, SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockingItemDeactivatesProductIfBlockedFilterIsRemoved()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Blocking Item makes coupled CRM Product State 'Retired' if 'Blocked' filter is removed from integration table mapping
        Initialize();
        SetupCRM();

        // [GIVEN] Coupled Item and CRM Product
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);

        // [GIVEN] Block Item
        BlockItem(Item);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        Clear(IntegrationTableMapping."Table Filter");
        IntegrationTableMapping.Modify();
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId, true, false);

        // [THEN] Coupled CRM Product State is set to 'Retired'
        CRMProduct.Find();
        CRMProduct.TestField(StateCode, CRMProduct.StateCode::Retired);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockingResourceDeactivatesProductIfBlockedFilterIsRemoved()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Blocking Resource makes coupled CRM Product State 'Retired' if 'Blocked' filter is removed from integration table mapping
        Initialize();
        SetupCRM();

        // [GIVEN] Coupled Resource and CRM Product
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);

        // [GIVEN] Block Resource
        BlockResource(Resource);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('RESOURCE-PRODUCT');
        Clear(IntegrationTableMapping."Table Filter");
        IntegrationTableMapping.Modify();
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Resource.RecordId, true, false);

        // [THEN] Coupled CRM Product State is set to 'Retired'
        CRMProduct.Find();
        CRMProduct.TestField(StateCode, CRMProduct.StateCode::Retired);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnblockingItemActivatesProduct()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Unblocking Item makes coupled CRM Product State 'Active'
        Initialize();
        SetupCRM();

        // [GIVEN] Coupled Item and CRM Product, Item is blocked and Product State is 'Retired'
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        BlockItem(Item);
        CRMSynchHelper.SetCRMProductStateToRetired(CRMProduct);
        CRMProduct.Modify(true);

        // [GIVEN]  Unblock Item
        Item.Validate(Blocked, false);
        Item.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Item.RecordId, true, false);

        // [THEN] Coupled CRM Product State is set to 'Active'
        CRMProduct.Find();
        CRMProduct.TestField(StateCode, CRMProduct.StateCode::Active);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnblockingResourceActivatesProduct()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Unblocking Resource makes coupled CRM Product State 'Active'
        Initialize();
        SetupCRM();

        // [GIVEN] Coupled Resource and CRM Product, Resource is blocked and Product State is 'Retired'
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);
        BlockResource(Resource);
        CRMSynchHelper.SetCRMProductStateToRetired(CRMProduct);
        CRMProduct.Modify(true);

        // [GIVEN] Unblock Resource
        Resource.Validate(Blocked, false);
        Resource.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('RESOURCE-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Resource.RecordId, true, false);

        // [THEN] Coupled CRM Product State is set to 'Active'
        CRMProduct.Find();
        CRMProduct.TestField(StateCode, CRMProduct.StateCode::Active);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeactivatingProductBlocksItemIfActiveFilterIsRemoved()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CDSCompany: Record "CDS Company";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Setting CRM Product State to 'Retired' makes coupled Item Blocked if 'Active' filter is removed from integration table mapping
        Initialize();
        SetupCRM();

        // [GIVEN] Coupled Item and CRM Product, Item is not blocked and Product State is 'Active'
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);

        // [GIVEN] Set CRM Product State to 'Retired'
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        IntegrationTableMapping.SetIntegrationTableFilter(StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field8=1(0),Field62=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId)));
        IntegrationTableMapping.Modify();
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled Item is blocked
        Item.Find();
        Item.TestField(Blocked, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeactivatingProductBlocksResourceIfActiveFilterIsRemoved()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        CDSCompany: Record "CDS Company";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Setting CRM Product State to 'Retired' makes coupled Resource Blocked if 'Active' filter is removed from integration table mapping
        Initialize();
        SetupCRM();

        // [GIVEN] Coupled Resource and CRM Product, Resource is not blocked and Product State is 'Active'
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);

        // [GIVEN] Set CRM Product State to 'Retired'
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('RESOURCE-PRODUCT');
        CDSIntegrationMgt.GetCDSCompany(CDSCompany);
        IntegrationTableMapping.SetIntegrationTableFilter(StrSubstNo('VERSION(1) SORTING(Field1) WHERE(Field8=1(2),Field62=1(%1|{00000000-0000-0000-0000-000000000000}))', Format(CDSCompany.CompanyId)));
        IntegrationTableMapping.Modify();
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled Resource is blocked
        Resource.Find();
        Resource.TestField(Blocked, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActivatingProductUnblocksItem()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Setting CRM Product State to 'Active' unblocks coupled Item
        Initialize();
        SetupCRM();

        // [GIVEN] Coupled Item and CRM Product, Item is blocked and Product State is 'Retired'
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);
        BlockItem(Item);

        // [GIVEN] Set CRM Product State to 'Active'
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('ITEM-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled Item is unblocked
        Item.Find();
        Item.TestField(Blocked, false);
    end;

    [Test]
    //Reenabled in https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/368425
    [Scope('OnPrem')]
    procedure ActivatingProductUnblocksResource()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Setting CRM Product State to 'Active' unblocks coupled Resource
        Initialize();
        SetupCRM();

        // [GIVEN] Coupled Resource and CRM Product, Resource is blocked and Product State is 'Retired'
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);
        BlockResource(Resource);

        // [GIVEN] Set CRM Product State to 'Active'
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.Modify(true);

        // [WHEN] Sync record
        IntegrationTableMapping.Get('RESOURCE-PRODUCT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMProduct.ProductId, true, false);

        // [THEN] Coupled Resource is unblocked
        Resource.Find();
        Resource.TestField(Blocked, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncCRMSalesOrderWithInactiveCRMProduct()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMProduct: Record "CRM Product";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Unable to sync CRM Salesorder to NAV if CRM Product is of 'Retired' state.
        Initialize();

        // [GIVEN] CRM integration setup
        SetupCRM();
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is S.Order Integration Enabled" := true;
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup.Modify();

        // [GIVEN] CRM Salesorder with a line of CRM Product
        PrepareCRMSalesOrder(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] Set CRM Product State to 'Retired'
        CRMProduct.Get(CRMSalesorderdetail.ProductId);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);

        // [WHEN] Couple CRM Salesorder to NAV Sales Order
        asserterror CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Error message because CRM Product is is of state 'Retired'
        Assert.ExpectedTestFieldError(CRMProduct.FieldCaption(StateCode), Format(CRMProduct.StatusCode::Active));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncCRMSalesOrderWithInactiveCRMProductResource()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMProduct: Record "CRM Product";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Unable to sync CRM Salesorder to NAV if CRM Product (resource) is of 'Retired' state.
        Initialize();

        // [GIVEN] CRM integration setup
        SetupCRM();
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is S.Order Integration Enabled" := true;
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup.Modify();

        // [GIVEN] CRM Salesorder with a line of CRM Product (resource)
        PrepareCRMSalesOrder(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLineWithResource(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] Set CRM Product State to 'Retired'
        CRMProduct.Get(CRMSalesorderdetail.ProductId);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Retired);
        CRMProduct.Modify(true);

        // [WHEN] Couple CRM Salesorder to NAV Sales Order
        asserterror CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Error message because CRM Product is of state 'Retired'
        Assert.ExpectedTestFieldError(CRMProduct.FieldCaption(StateCode), Format(CRMProduct.StatusCode::Active));
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncNAVInvoiceWithBlockedItem()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [CRM Integration Management] [Item] [CRM Product]
        // [SCENARIO 175051] Unable to sync NAV Sales Invoice to CRM if it contains Item which is blocked.
        Initialize();

        // [GIVEN] CRM integration setup
        SetupCRM();

        // [GIVEN] Posted Sales Invoice
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);
        CreatePostSalesInvoiceLCY(SalesInvHeader, Customer."No.", SalesLine.Type::Item, Item."No.");

        // [GIVEN] Block Posted Sales Invoice Item
        Item.Find();
        BlockItem(Item);

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange(SystemId, SalesInvHeader.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView(), IntegrationTableMapping);

        // [THEN] Error message because Item is blocked
        LibraryCRMIntegration.VerifySyncJobFailedOneRecord(JobQueueEntryID, IntegrationTableMapping, BlockedMustBeNoErr);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncNAVInvoiceWithBlockedResource()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [CRM Integration Management] [Resource] [CRM Product]
        // [SCENARIO 175051] Unable to sync NAV Sales Invoice to CRM if it contains Resource which is blocked.
        Initialize();

        // [GIVEN] CRM integration setup
        SetupCRM();

        // [GIVEN] Posted Sales Invoice
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreateCoupledAndActiveResourceAndProduct(Resource, CRMProduct);
        CreatePostSalesInvoiceLCY(SalesInvHeader, Customer."No.", SalesLine.Type::Resource, Resource."No.");

        // [GIVEN] Block Posted Sales Invoice Resource
        Resource.Find();
        BlockResource(Resource);

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange(SystemId, SalesInvHeader.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView(), IntegrationTableMapping);

        // [THEN] Error message because Item is blocked
        LibraryCRMIntegration.VerifySyncJobFailedOneRecord(JobQueueEntryID, IntegrationTableMapping, BlockedMustBeNoErr);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CouplePostedSalesInvoiceCreatedInNAVToCRM()
    var
        Customer: Record Customer;
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMAccount: Record "CRM Account";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI]

        // [SCENARIO 380575] Posted Sales Invoice couples to CRM when press "Create Invoice in Dynamics CRM" on page "Posted Sales Invoice"
        Initialize();

        // [GIVEN] CRM integration setup
        SetupCRM();

        // [GIVEN] Coupled Customer
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Posted Sales Invoice generated in NAV
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');

        // [GIVEN] Opened "Posted Sales Invoice" page
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvHeader);

        // [WHEN] Press "Create Invoice in Dynamics CRM" on page "Posted Sales Invoice"
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        PostedSalesInvoice.CreateInCRM.Invoke();
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange(SystemId, SalesInvHeader.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView(), IntegrationTableMapping);

        // [THEN] The notification: "Synchronization has been scheduled."
        // [THEN] Synch Job is created, where Inserted = 1
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleMultiplePostedSalesInvoicesToCRM()
    var
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMAccount: Record "CRM Account";
        JobQueueEntryID: Guid;
    begin
        // [SCENARIO 380575] Two Posted Sales Invoices coupled to CRM
        Initialize();

        // [GIVEN] CRM integration setup
        SetupCRM();

        // [GIVEN] Coupled Customer
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Three Posted Sales Invoices generated in NAV
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');
        CreatePostSalesInvoiceWithGLAccount(SalesInvHeader, Customer."No.", '');

        // [GIVEN] Marked the second and third invoice, while positioned on the first one
        SalesInvHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvHeader.FindLast();
        SalesInvHeader.Mark(true); // mark the third invoice
        SalesInvHeader.Next(-1);
        SalesInvHeader.Mark(true); // mark the second invoice
        SalesInvHeader.FindFirst(); // rec positioned on the first, that is out of marked invoices
        SalesInvHeader.SetRange("Sell-to Customer No.");
        SalesInvHeader.MarkedOnly(true);

        // [GIVEN] Only base integration table mappings, not child mappings
        IntegrationTableMapping.SetRange("Table ID", Database::"Sales Invoice Header");
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        IntegrationTableMapping.DeleteAll();

        // [WHEN] "Create New Account In CRM" for two invoices: second and third.
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(2);
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader);

        // [THEN] Notification: '2 of 2 records are scheduled'
        // handled by MultipleSyncStartedNotificationHandler
        // Executing the Sync Job
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Job is not found');
        JobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [Scope('OnPrem')]
    procedure CheckOrEnableCRMConnectionNotEnabled()
    begin
        // [SCENARIO 204194] CRM Connection Setup Wizard page is shown if CRM setup is not enabled and user tries to access CRM items from NAV.
        Initialize();
        LibraryCRMIntegration.CreateCRMConnectionSetup('', 'host', false);
        asserterror CRMIntegrationManagement.CheckOrEnableCRMConnection();
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CouplePostedSalesInvoiceInFCYCreatedInNAVToCRM()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        FilteredSalesInvHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvHeader: Record "Sales Invoice Header";
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: Record "CRM Product";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 186713] It is possible to couple Posted Sales Invoice in FCY that was created in NAV to CRM
        Initialize();

        // [GIVEN] CRM integration setup
        SetupCRM();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] Coupled Customer "X"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Coupled Currency "USD"
        CreateCoupledAndTransactionCurrencies(Currency, CRMTransactioncurrency);

        // [GIVEN] Coupled Item "ITEM" with UoM "PCS"
        CreateCoupledAndActiveItemAndProduct(Item, CRMProduct);

        // [GIVEN] Posted Sales Invoice generated in NAV with Customer "X", Currency "USD" and Item "ITEM", unit price 100
        CreatePostSalesInvoiceFCY(SalesInvHeader, Customer."No.", SalesLine.Type::Item, Item."No.", Currency.Code);

        // [WHEN] Couple Posted Sales Invoice to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvHeader.RecordId);
        // Executing the Sync Job
        FilteredSalesInvHeader.SetRange(SystemId, SalesInvHeader.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::"Sales Invoice Header", FilteredSalesInvHeader.GetView(), IntegrationTableMapping);

        // [THEN] Posted Sales Invoice is coupled to a CRM Invoice
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalesInvHeader.RecordId), 'Should be coupled.');

        // [THEN] New CRM Productpricelevel created for item "ITEM", currency "USD", UoM "PCS" and amount 100
        FindCRMProductpricelevelByItem(CRMProductpricelevel, Item);
        FindCRMPricelevelByCurrency(CRMPricelevel, Currency);
        FindCRMUoMBySalesInvoicLineItem(CRMUom, CRMIntegrationRecord."CRM ID", CRMProduct.ProductId);
        FindSalesInvoiceLine(SalesInvoiceLine, Item."No.");
        VerifyCRMProductpricelevel(
          CRMProductpricelevel, CRMPricelevel.PriceLevelId,
          CRMUom.UoMId, CRMUom.UoMScheduleId, SalesInvoiceLine."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCRMPricelevelInCurrencySunshine()
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMPricelevel: Record "CRM Pricelevel";
    begin
        // [FEATURE] [FCY] [UT]
        // [SCENARIO 186713] New CRM pricelevel in currency could be created with CRMSynchHelper.CreateCRMPricelevelInCurrency
        Initialize();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] Coupled Currency "USD"
        CreateCoupledAndTransactionCurrencies(Currency, CRMTransactioncurrency);

        // [WHEN] Function CRMSynchHelper.CreateCRMPricelevelInCurrency is being run
        CRMSynchHelper.CreateCRMPricelevelInCurrency(CRMPricelevel, Currency.Code, GetExchangeRate(Currency.Code, WorkDate()));

        // [THEN] New CRM Pricelevel created for currency "USD" created
        FindCRMPricelevelByCurrency(CRMPricelevel, Currency);
        VerifyCRMPriceLevel(CRMPricelevel, Currency.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCRMPricelevelInCurrencyWhenCurrencyNotCoupled()
    var
        Currency: Record Currency;
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [FCY] [UT]
        // [SCENARIO 186713] If currency is not mapped then function CRMSynchHelper.CreateCRMPricelevelInCurrency causes error
        Initialize();
        LibraryCRMIntegration.CreateCRMOrganization();

        // [GIVEN] Currency "USD" which is not coupled with CRM Transactioncurrency
        LibraryERM.CreateCurrency(Currency);

        // [WHEN] Function CRMSynchHelper.CreateCRMPricelevelInCurrency is being run
        asserterror
          CRMSynchHelper.CreateCRMPricelevelInCurrency(CRMPricelevel, Currency.Code, LibraryRandom.RandDec(100, 2));

        // [THEN] Error message "The integration record for Currency: USD was not found."
        Assert.ExpectedError(
          StrSubstNo(
            RecordMustBeCoupledErr,
            Currency.TableCaption(),
            Currency.Code,
            CRMTransactioncurrency.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultInactivityTimeoutPeriod()
    begin
        // [FEATURE] [Inactivity Timeout Period]
        // [SCENARIO 266711] Inactivity Timeout Period has value on Reset Default CRM Setup Configuration
        Initialize();
        // [WHEN] Reset Default CRM Setup Configuration
        ResetDefaultCRMSetupConfiguration(false);

        // [THEN] Job queue entries with respective No. of Minutes between Runs & Inactivity Timeout Period
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' CUSTOMER - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' VENDOR - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' CONTACT - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' CURRENCY - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' RESOURCE-PRODUCT - Dynamics 365 Sales synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 720,
          ' UNIT OF MEASURE - Dynamics 365 Sales synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' SALESPEOPLE - Dataverse synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' ITEM-PRODUCT - Dynamics 365 Sales synchronization job.');
#if not CLEAN25
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' CUSTPRCGRP-PRICE - Dynamics 365 Sales synchronization job.');
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' SALESPRC-PRODPRICE - Dynamics 365 Sales synchronization job.');
#endif
        VerifyJobQueueEntriesInactivityTimeoutPeriod(30, 1440,
          ' POSTEDSALESINV-INV - Dynamics 365 Sales synchronization job.');
    end;

    local procedure Initialize()
    begin
        Initialize(false);
    end;

    local procedure Initialize(EnableExtendedPrice: Boolean)
    var
        MyNotifications: Record "My Notifications";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CRM Integration Mgt Test");

        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        if EnableExtendedPrice then begin
            LibraryPriceCalculation.EnableExtendedPriceCalculation();
            SalesReceivablesSetup.Get();
            SalesReceivablesSetup."Default Price List Code" := LibraryUtility.GenerateGUID();
            SalesReceivablesSetup.Modify();
        end;

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID(), '', '', false);
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();

        IsInitialized := true;
    end;

    local procedure SetupCRM()
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        ResetDefaultCRMSetupConfiguration(false);
        LibraryCRMIntegration.GetGLSetupCRMTransactionCurrencyID();
    end;

    local procedure RunHyperlinkTest(RecordID: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        // Getting URL for CRM entities
        // [GIVEN] An coupled SalesPerson/Purchaser
        // [WHEN] Getting CRM Entity Url From RecordId
        // [THEN] An url is returned
        CRMIntegrationRecord.CoupleRecordIdToCRMID(RecordID, CreateGuid());
        Assert.IsTrue(CRMCouplingManagement.IsRecordCoupledToCRM(RecordID), 'Expected the record to be coupled');
        Assert.AreNotEqual(
          '', CRMIntegrationManagement.GetCRMEntityUrlFromRecordID(RecordID),
          'Expected to get a valid url');

        // [GIVEN] An decoupled entity
        // [WHEN] Getting CRM Entity Url From RecordId
        // [THEN] An error is thrown
        CRMIntegrationRecord.FindByRecordID(RecordID);
        CRMIntegrationRecord.Delete();
        Assert.IsFalse(CRMCouplingManagement.IsRecordCoupledToCRM(RecordID), 'Did not expect the record to be coupled');
        asserterror CRMIntegrationManagement.GetCRMEntityUrlFromRecordID(RecordID);
    end;

    local procedure CreatePostSalesInvoiceWithGLAccount(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreatePostSalesInvoiceFCY(
          SalesInvoiceHeader, CustNo, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), CurrencyCode);
    end;

    local procedure CreatePostSalesInvoiceLCY(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        CreatePostSalesInvoiceFCY(SalesInvoiceHeader, CustNo, Type, No, '');
    end;

    local procedure CreatePostSalesInvoiceFCY(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustNo: Code[20]; Type: eNUM "Sales Line Type"; No: Code[20]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        if CurrencyCode <> '' then
            SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, Type, No, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCoupledAndActiveItemAndProduct(var Item: Record Item; var CRMProduct: Record "CRM Product")
    begin
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.Modify(true);
    end;

    local procedure CreateCoupledAndActiveResourceAndProduct(var Resource: Record Resource; var CRMProduct: Record "CRM Product")
    begin
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);
        CRMProduct.Validate(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.Modify(true);
    end;

    local procedure CreateCoupledAndTransactionCurrencies(var Currency: Record Currency; var CRMTransactioncurrency: Record "CRM Transactioncurrency")
    var
        CurrExchRateAmount: Decimal;
    begin
        LibraryCRMIntegration.CreateCoupledCurrencyAndNotLCYTransactionCurrency(Currency, CRMTransactioncurrency);
        CurrExchRateAmount := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), CurrExchRateAmount, CurrExchRateAmount);
    end;

    local procedure FindCRMPricelevelByCurrency(var CRMPricelevel: Record "CRM Pricelevel"; Currency: Record Currency)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        CRMIntegrationRecord.FindByRecordID(Currency.RecordId);
        CRMTransactioncurrency.Get(CRMIntegrationRecord."CRM ID");
        CRMPricelevel.SetRange(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);
        CRMPricelevel.FindFirst();
    end;

    local procedure FindCRMProductpricelevelByItem(var CRMProductpricelevel: Record "CRM Productpricelevel"; Item: Record Item)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: Record "CRM Product";
    begin
        CRMIntegrationRecord.FindByRecordID(Item.RecordId);
        CRMProduct.Get(CRMIntegrationRecord."CRM ID");
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        CRMProductpricelevel.FindFirst();
    end;

    local procedure FindCRMUoMBySalesInvoicLineItem(var CRMUom: Record "CRM Uom"; InvoiceId: Guid; ProductId: Guid)
    var
        CRMInvoicedetail: Record "CRM Invoicedetail";
    begin
        CRMInvoicedetail.SetRange(InvoiceId, InvoiceId);
        CRMInvoicedetail.SetRange(ProductId, ProductId);
        CRMInvoicedetail.FindFirst();
        CRMUom.Get(CRMInvoicedetail.UoMId);
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; ItemNo: Code[20])
    begin
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetRange("No.", ItemNo);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure GetExchangeRate(CurrencyCode: Code[10]; ConversionDate: Date): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        exit(CurrencyExchangeRate.ExchangeRate(ConversionDate, CurrencyCode));
    end;

    local procedure PrepareCRMSalesOrder(var CRMSalesorder: Record "CRM Salesorder")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        GeneralLedgerSetup.Get();
        LibraryCRMIntegration.CreateCRMTransactionCurrency(
          CRMTransactioncurrency, CopyStr(GeneralLedgerSetup."LCY Code", 1, MaxStrLen(CRMTransactioncurrency.ISOCurrencyCode)));
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.CreateCRMSalesOrderWithCustomerFCY(
          CRMSalesorder, CRMAccount.AccountId, CRMTransactioncurrency.TransactionCurrencyId);
    end;

    local procedure CreateCRMSalesOrderInFCY(var CRMSalesorder: Record "CRM Salesorder")
    var
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Customer: Record Customer;
        Currency: Record Currency;
    begin
        LibraryCRMIntegration.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), 1, LibraryRandom.RandDec(100, 2));
        LibraryCRMIntegration.CreateCRMTransactionCurrency(
          CRMTransactioncurrency,
          CopyStr(Currency.Code, 1, MaxStrLen(CRMTransactioncurrency.ISOCurrencyCode)));
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.CreateCRMSalesOrderWithCustomerFCY(
          CRMSalesorder, CRMAccount.AccountId, CRMTransactioncurrency.TransactionCurrencyId);
    end;

    local procedure ResetDefaultCRMSetupConfiguration(EnableUnitGroupMapping: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSCompany: Record "CDS Company";
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
        CRMConnectionSetup."Unit Group Mapping Enabled" := EnableUnitGroupMapping;
        CRMConnectionSetup.Modify();
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    local procedure BlockItem(var Item: Record Item)
    begin
        Item.Validate(Blocked, true);
        Item.Modify(true);
    end;

    local procedure BlockResource(var Resource: Record Resource)
    begin
        Resource.Validate(Blocked, true);
        Resource.Modify(true);
    end;

    local procedure VerifyTableMapping(TableID: Integer; IntegrationTableID: Integer; IntegrationDirection: Option; TableFilter: Text; IntegrationTableFilter: Text; SynchOnlyCoupledRecords: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.FindFirst();
        Assert.AreEqual(IntegrationDirection, IntegrationTableMapping.Direction, IntegrationTableMapping.FieldName(Direction));
        Assert.AreEqual(IntegrationTableID, IntegrationTableMapping."Integration Table ID", IntegrationTableMapping.FieldName("Integration Table ID"));
        Assert.AreEqual(TableFilter, IntegrationTableMapping.GetTableFilter(), IntegrationTableMapping.FieldName("Table Filter"));
        Assert.AreEqual(IntegrationTableFilter, IntegrationTableMapping.GetIntegrationTableFilter(), IntegrationTableMapping.FieldName("Integration Table Filter"));
        Assert.AreEqual(SynchOnlyCoupledRecords, IntegrationTableMapping."Synch. Only Coupled Records", IntegrationTableMapping.FieldName("Synch. Only Coupled Records"));
    end;

    local procedure VerifyCRMPriceLevel(CRMPricelevel: Record "CRM Pricelevel"; CurrencyCode: Code[10])
    begin
        CRMPricelevel.TestField(ExchangeRate, GetExchangeRate(CurrencyCode, WorkDate()));
        CRMPricelevel.TestField(Name, StrSubstNo(CurrencyPriceListNameTxt, CurrencyCode));
    end;

    local procedure VerifyCRMProductpricelevel(CRMProductpricelevel: Record "CRM Productpricelevel"; ExpectedPriceLevelId: Guid; ExpectedUoMId: Guid; ExpectedUoMScheduleId: Guid; ExpectedAmount: Decimal)
    begin
        CRMProductpricelevel.TestField(PriceLevelId, ExpectedPriceLevelId);
        CRMProductpricelevel.TestField(UoMId, ExpectedUoMId);
        CRMProductpricelevel.TestField(UoMScheduleId, ExpectedUoMScheduleId);
        CRMProductpricelevel.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyJobQueueEntriesInactivityTimeoutPeriod(NoOfMinutesBetweenRuns: Integer; ExpectedInactivityTimeoutPeriod: Integer; JobDescription: Text[250])
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("No. of Minutes between Runs", NoOfMinutesBetweenRuns);
        JobQueueEntry.SetRange(Description, JobDescription);
        JobQueueEntry.FindFirst();
        Assert.AreEqual(ExpectedInactivityTimeoutPeriod, JobQueueEntry."Inactivity Timeout Period",
          'Inactivity time out period different from default.');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnGetMaxNumberOfConditions', '', false, false)]
    local procedure UpdateMaxNumberOfConditions(var Handled: Boolean; var Value: Integer)
    begin
        Value := 3;
        Handled := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SynchDirectionStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Assert.ExpectedMessage('Synchronize data for the selected records', Instruction);
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmStartCoupling(Question: Text; var Reply: Boolean)
    begin
        Reply := ConfirmStartCouplingReply;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CoupleCustomerPage(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        if CRMCouplingPageDoCancel then begin
            CRMCouplingRecord.Cancel().Invoke();
            exit;
        end;

        CRMCouplingRecord.OK().Invoke();
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure CRMHyperlinkHandler(LinkAddress: Text)
    begin
        Assert.AreNotEqual('', LinkAddress, 'Did not expect the hyperlink to be empty');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(SyncNowScheduledMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedSkippedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    var
        ExpectedMessage: Text;
    begin
        ExpectedMessage := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(ExpectedMessage, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure MultipleSyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    var
        Count: Integer;
    begin
        Count := LibraryVariableStorage.DequeueInteger();
        Assert.AreEqual(StrSubstNo(MultipleSyncStartedMsg, Count, Count, 0, 0), SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
