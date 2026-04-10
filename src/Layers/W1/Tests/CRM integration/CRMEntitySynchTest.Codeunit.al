codeunit 139180 "CRM Entity Synch Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        IntTableSynchSubscriber: Codeunit "Int. Table Synch. Subscriber";
        CRMProductName: Codeunit "CRM Product Name";
        LibraryTemplates: Codeunit "Library - Templates";
        SynchDirection: Option Cancel,ToCRM,ToNAV;
        ConfirmReply: Boolean;
        FieldNotUpdatedErr: Label '%1 is not updated', Comment = '%1 = Field No.';
        SyncStartedMsg: Label 'The synchronization has been scheduled.';
        MultipleSyncStartedMsg: Label 'The synchronization has been scheduled for 2 of 4 records. 0 records failed. 2 records were skipped.';
        ItemMustBeCoupledErr: Label '%1 %2 must be coupled to a record in %3.';
        PriceListMustBeCoupledErr: Label 'Price List Code %1 must be coupled to a record in %2.';
        SalesCodeMustBeCoupledErr: Label 'Sales Code %1 must be coupled to a record in %2.';
        SalespersonMustBeCoupledErr: Label 'Salesperson Code %1 must be coupled to a record in %2.';

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,StrMenuHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncResourceFromResourceListPage()
    var
        Resource: Record Resource;
        CRM_Product: Record "CRM Product";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMConnectionSetup: Record "CRM Connection Setup";
        ResourceList: TestPage "Resource List";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Resource]
        // [SCENARIO] Sync a coupled NAV resource to a CRM product
        Init();

        // [GIVEN] CRM is enabled
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateIntegrationTableMappingResourceProduct();
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Unit Group Mapping Enabled" := false;
        CRMConnectionSetup.Modify();

        // [GIVEN] A NAV Resource is coupled to a CRM product
        LibraryCRMIntegration.CreateCRMOrganization();
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRM_Product);

        // [WHEN] The user clicks on the Synchronize Now action on the Resource List
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        ResourceList.OpenView();
        ResourceList.FILTER.SetFilter("No.", Format(Resource."No."));
        ResourceList.CRMSynchronizeNow.Invoke();

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // execute scheduled job
        Resource.SetRange(SystemId, Resource.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(DATABASE::Resource, Resource.GetView(), IntegrationTableMapping);
        // [THEN] Job resulted in one modified record
        IntegrationSynchJob.Modified := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [Test]
    [HandlerFunctions('TestSyncMultipleCustomersStrMenuHandler,MultipleSyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncMultipleCustomers()
    var
        Customer: Record Customer;
        ScheduledCustomer: array[2] of Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CustomerRecordRef: RecordRef;
        NameFieldRef: FieldRef;
        JobQueueEntryID: Guid;
        SyncJobID: Guid;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing multiple customers
        Init();
        // [GIVEN] A customer previously synced with a CRM account and neither updated since
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Customer.Name := 'TestCust1';
        Customer.Modify();
        ScheduledCustomer[1] := Customer;
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [GIVEN] An uncoupled customer
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := 'TestCust2';
        Customer.Modify();

        // [GIVEN] A customer coupled to a CRM account with newer data (never synced)
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Customer.Name := 'TestCust3';
        Customer.Modify();

        // [GIVEN] A customer with an uncoupled salesperson
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Clear(IntegrationTableMapping);
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Name := 'TestCust4';
        Customer.Modify();
        MockCRMIntegrationRecordsLastSync(Customer.RecordId, 0DT);
        ScheduledCustomer[2] := Customer;

        // [GIVEN] Only base integration table mappings, not child mappings
        IntegrationTableMapping.SetRange("Table ID", Database::Customer);
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        IntegrationTableMapping.DeleteAll();

        // [WHEN] Synchronizing the customers to CRM
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CustomerRecordRef := Customer.RecordId.GetRecord();
        NameFieldRef := CustomerRecordRef.Field(Customer.FieldNo(Name));
        NameFieldRef.SetFilter('TestCust*');
        SynchDirection := SynchDirection::ToCRM;
        CustomerRecordRef.FindFirst();
        CRMIntegrationManagement.UpdateMultipleNow(CustomerRecordRef);
        // Direction selected in TestSyncMultipleCustomersStrMenuHandler

        // [THEN] Notification "The synchronization has been scheduled for 2 of 4 records. 0 records failed. 2 records were skipped." is shown.
        // Handled by MultipleSyncStartedNotificationHandler

        // execute a scheduled job
        IntegrationSynchJob.DeleteAll();
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Job is not found');
        JobQueueEntryID := LibraryCRMIntegration.RunJobQueueEntryForIntTabMapping(IntegrationTableMapping);

        // [THEN] Job for the 1st customer resulted in one modified record
        // [THEN] Job for the 4th customer resulted in failure due to a not coupled salesperson
        IntegrationSynchJob.Modified := 1;
        IntegrationSynchJob.Failed := 1;
        IntegrationSynchJob.Message := StrSubstNo(SalespersonMustBeCoupledErr, SalespersonPurchaser.Code, CRMProductName.CDSServiceName());
        SyncJobID := LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        IntegrationSynchJob.Get(SyncJobID);
        IntegrationSynchJob.Delete();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure TestSyncMultipleCustomersStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Assert.ExpectedMessage('Synchronize data for the selected records', Instruction);
        Choice := SynchDirection;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerCRMOptionFieldMapped()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        ShippingAgent: Record "Shipping Agent";
        CRMOptionMapping: Record "CRM Option Mapping";
        asd: Text;
    begin
        // [FEATURE] [Customer] [Shipping Agent]
        // [SCENARIO] Sync should update the CRM Option field if the chosen record is mapped to an option value.
        Init();

        // [GIVEN] The customer and coupled option
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        IntegrationTableMapping.FindMapping(Database::Customer, Database::"CRM Account");
        ShippingAgent.Code := 'WILLCALL';
        if ShippingAgent.Insert() then;
        CoupleOption(ShippingAgent.RecordId, CRMAccount.Address1_ShippingMethodCodeEnum::WillCall.AsInteger(), ShippingAgent.Code, Database::"Shipping Agent", Database::"CRM Account", CRMAccount.FieldNo(CRMAccount.Address1_ShippingMethodCodeEnum));
        CRMOptionMapping.FindSet();
        repeat
            asd := CRMOptionMapping."Option Value Caption";
        until CRMOptionMapping.Next() = 0;

        // [GIVEN] "Shipping Agent" is changed to 'WillCall' (a record mapped to the CRM option)
        Customer.Validate("Shipping Agent Code", 'WILLCALL');
        Customer.Modify();

        // [WHEN] Synchronizing the customer
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [THEN] CRM Account, where "Address1_ShippingMethodCodeEnum" = 'WILLCALL'
        CRMAccount.Find();
        CRMAccount.TestField(Address1_ShippingMethodCodeEnum, CRMAccount.Address1_ShippingMethodCodeEnum::WILLCALL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncSingleAccountCRMOptionFieldMapped()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        ShippingAgent: Record "Shipping Agent";
    begin
        // [FEATURE] [Customer] [Shipping Agent]
        // [SCENARIO] Sync should update the option field if the chosen record is mapped to an option value.
        Init();

        // [GIVEN] The CRM account and coupled option
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        IntegrationTableMapping.FindMapping(Database::Customer, Database::"CRM Account");
        ShippingAgent.Code := 'TEST';
        if ShippingAgent.Insert() then;
        CoupleOption(ShippingAgent.RecordId, 1000, ShippingAgent.Code, Database::"Shipping Agent", Database::"CRM Account", CRMAccount.FieldNo(CRMAccount.Address1_ShippingMethodCodeEnum));

        // [GIVEN] "Shipping Method" is changed to 'TEST' (a record mapped to the CRM option)
        CRMAccount.Validate("Address1_ShippingMethodCodeEnum", 1000);
        CRMAccount.Modify();

        // [WHEN] Synchronizing the account
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMAccount.AccountId, true, false);

        // [THEN] Customer where "Shipping Agent Code" = 'TEST'
        Customer.Find();
        Customer.TestField("Shipping Agent Code", 'TEST');
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleRecordStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerUnmodified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing a single unmodified customer
        Init();

        // [GIVEN] A customer previously synced with a CRM account and neither updated since
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [WHEN] Synchronizing the customer
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        SynchDirection := SynchDirection::ToCRM;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        // [THEN] The user is asked to select the synchronization direction
        // [WHEN] The user selects synchronization to CRM
        // Happens in TestSyncSingleRecordStrMenuHandler
        Customer.SetRange(SystemId, Customer.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleRecordStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerNAVModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        JobQueueEntryID: Guid;
        OriginalCustomerName: Text;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing a single customer modified in NAV
        Init();

        // [GIVEN] A customer previously synced with a CRM account and since modified in NAV
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        Customer.Name := 'Noon Ame';
        Customer.Modify();
        OriginalCustomerName := Customer.Name;

        // [WHEN] Synchronizing the customer
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        SynchDirection := SynchDirection::ToCRM;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        // [THEN] The user is asked to select the synchronization direction
        // [WHEN] The user selects synchronization to CRM
        // Happens in TestSyncSingleRecordStrMenuHandler
        Customer.SetRange(SystemId, Customer.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in CRM is overwritten with the data from NAV
        CRMAccount.Get(CRMAccount.AccountId);
        Assert.AreEqual(OriginalCustomerName, CRMAccount.Name,
          'The CRM account should have the name the customer had before');
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleRecordStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerCRMModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        OriginalCustomerName: Text;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing a single customer modified in CRM
        Init();

        // [GIVEN] A customer previously synced with a CRM account and since modified in CRM
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMAccount.ModifiedOn := CreateDateTime(
            CalcDate('<-1D>', DT2Date(CRMAccount.ModifiedOn)), DT2Time(CRMAccount.ModifiedOn));
        CRMAccount.Modify();
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        CRMAccount.Name := 'Noon Ame';
        CRMAccount.ModifiedOn := CurrentDateTime;
        CRMAccount.Modify();
        OriginalCustomerName := Customer.Name;

        // [WHEN] Synchronizing the customer
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        SynchDirection := SynchDirection::ToCRM;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        // [THEN] The user is asked to select the synchronization direction
        // [WHEN] The user selects synchronization to CRM
        // Happens in TestSyncSingleRecordStrMenuHandler
        Customer.SetRange(SystemId, Customer.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in CRM is overwritten with the data from NAV
        CRMAccount.Get(CRMAccount.AccountId);
        Assert.AreEqual(OriginalCustomerName, CRMAccount.Name,
          'The CRM account should have the name the customer had before');
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleCustomerBothModifiedMessageHandler,TestSyncSingleRecordStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerBothModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        JobQueueEntryID: Guid;
        OriginalCustomerName: Text;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing a single customer modified in CRM and NAV, leads to forced modify of the destination
        Init();

        // [GIVEN] A coupled unsynced customer
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMAccount.Name := StrSubstNo('Not%1', Customer.Name);
        CRMAccount.Modify();
        OriginalCustomerName := Customer.Name;

        // [WHEN] Synchronizing the customer
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        SynchDirection := SynchDirection::ToCRM;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        // [THEN] The user is asked to select the synchronization direction
        // [WHEN] The user selects synchronization to CRM
        // Happens in TestSyncSingleRecordStrMenuHandler
        Customer.SetRange(SystemId, Customer.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in CRM is overwritten with the data from NAV
        CRMAccount.Get(CRMAccount.AccountId);
        Assert.AreEqual(OriginalCustomerName, CRMAccount.Name,
          'The CRM account should have the name the customer had before');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleCustomerBothModifiedMessageHandler(Message: Text)
    begin
        if StrPos(Message, 'data on one of the records will be lost') <> 0 then
            exit;
        if StrPos(Message, 'Synchronization completed') <> 0 then
            exit;
        Assert.Fail(StrSubstNo('Unexpected message:\%1', Message));
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleRecordStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := SynchDirection;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSalespersonsSequently()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        CRMSystemuser: array[2] of Record "CRM Systemuser";
        ExpectedParentName: array[2] of Text;
    begin
        // [FEATURE] [Salesperson]
        // [SCENARIO 215216] Synchronizing a two salespersons modified in CRM/NAV sequently, so temporary mappings should not conflict
        Init();

        // [GIVEN] A salesperson previously synced with a CRM user and since updated in CRM
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[1], CRMSystemuser[1]);
        GetIntegrationTableMapping(IntegrationTableMapping, CRMSystemuser[1].RecordId);
        ExpectedParentName[1] := IntegrationTableMapping.Name;
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMSystemuser[1].SystemUserId, true, false);
        CRMSystemuser[1].Find();
        CRMSystemuser[1].FullName := LibraryUtility.GenerateGUID();
        CRMSystemuser[1].Modify();
        // Mock CRM user Modified On changed
        MockCRMIntegrationRecordsLastSync(SalespersonPurchaser[1].RecordId, CRMSystemuser[1].ModifiedOn + 100);

        // [GIVEN] A salesperson previously synced with a CRM user and since updated in NAV
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser[2], CRMSystemuser[2]);
        Clear(IntegrationTableMapping);
        GetIntegrationTableMapping(IntegrationTableMapping, CRMSystemuser[2].RecordId);
        ExpectedParentName[2] := IntegrationTableMapping.Name;
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMSystemuser[2].SystemUserId, true, false);
        Sleep(50);
        SalespersonPurchaser[2].Find();
        SalespersonPurchaser[2].Name := LibraryUtility.GenerateGUID();
        SalespersonPurchaser[2].Modify();

        // [GIVEN] Synchronizing the first salesperson
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser[1].RecordId);

        // [WHEN] Synchronizing the second salesperson
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser[2].RecordId);

        // [THEN] Before the actual sync, there are 3 mappings for table "Salesperson/Purchaser":
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
        Assert.RecordCount(IntegrationTableMapping, 3);
        // [THEN] two mappings are temporary, created as copies of the original 'SALESPEOPLE' one,
        // [THEN] where "Parent Name" = 'SALESPEOPLE', "Delete After Synchronization" = Yes
        Assert.AreEqual(ExpectedParentName[1], ExpectedParentName[2], 'Both integration mappings should be the same.');
        IntegrationTableMapping.SetRange("Parent Name", ExpectedParentName[1]);
        IntegrationTableMapping.SetRange("Delete After Synchronization", true);
        Assert.RecordCount(IntegrationTableMapping, 2);
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleSalespersonCRMModifiedConfirmHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    //Reenabled in https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/368425
    [Scope('OnPrem')]
    procedure SyncSingleSalespersonCRMModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Salesperson]
        Init();

        // [SCENARIO] Synchronizing a single salesperson modified in CRM
        // [GIVEN] A salesperson previously synced with a CRM user and since updated in CRM
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        GetIntegrationTableMapping(IntegrationTableMapping, CRMSystemuser.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMSystemuser.SystemUserId, true, false);
        CRMSystemuser.FullName := 'Noon Ame';
        CRMSystemuser.Modify();

        // [WHEN] Synchronizing the salesperson
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId);

        // [THEN] The user is asked to confirm synch
        // [WHEN] The user confirms
        // Happens in TestSyncSingleSalespersonCRMModifiedConfirmHandler
        CRMSystemuser.SetRange(SystemUserId, CRMSystemuser.SystemUserId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Systemuser", CRMSystemuser.GetView(), IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in NAV is overwritten with the data from CRM
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        Assert.AreEqual('Noon Ame', SalespersonPurchaser.Name,
          'The salesperson should have the name the CRM systemuser had before');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleSalespersonCRMModifiedConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(StrSubstNo('Get data update from %1 for', CRMProductName.CDSServiceName()), Question);
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleSalespersonNAVModifiedConfirmHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    //Reenabled in https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/368425
    [Scope('OnPrem')]
    procedure SyncSingleSalespersonNAVModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        JobQueueEntryID: Guid;
        OriginalCRMSystemuserName: Text;
    begin
        // [FEATURE] [Salesperson]
        Init();

        // [SCENARIO] Synchronizing a single salesperson modified in NAV
        // [GIVEN] A salesperson previously synced with a CRM user and since updated in NAV
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        GetIntegrationTableMapping(IntegrationTableMapping, CRMSystemuser.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMSystemuser.SystemUserId, true, false);
        SetLastSyncDateBackOneDayCRM(CRMSystemuser.SystemUserId);
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        SalespersonPurchaser.Name := 'Noon Ame';
        SalespersonPurchaser.Modify();
        OriginalCRMSystemuserName := CRMSystemuser.FullName;

        // [WHEN] Synchronizing the salesperson
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId);

        // [THEN] The user is asked to confirm data replacement
        // [WHEN] The user confirms
        // Happens in TestSyncSingleSalespersonNAVModifiedConfirmHandler
        CRMSystemuser.SetRange(SystemUserId, CRMSystemuser.SystemUserId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Systemuser", CRMSystemuser.GetView(), IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in NAV is overwritten with the data from CRM
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        Assert.AreEqual(OriginalCRMSystemuserName, SalespersonPurchaser.Name,
          'The salesperson should have the name the CRM systemuser had before');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleSalespersonNAVModifiedConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(StrSubstNo('contains newer data than the %1 record. Get data', CRMProductName.CDSServiceName()), Question);
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleSalespersonBothModifiedConfirmHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    //Reenabled in https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/368425
    [Scope('OnPrem')]
    procedure SyncSingleSalespersonBothModified()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        JobQueueEntryID: Guid;
        OriginalCRMSystemuserName: Text;
        OriginalSalespersonName: Text;
    begin
        // [FEATURE] [Salesperson]
        Init();

        // [SCENARIO] Synchronizing a single salesperson modified in both NAV and CRM
        // [GIVEN] A salesperson coupled to a CRM user but never synced
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        GetIntegrationTableMapping(IntegrationTableMapping, SalespersonPurchaser.RecordId);
        OriginalCRMSystemuserName := CRMSystemuser.FullName;
        OriginalSalespersonName := SalespersonPurchaser.Name;

        // [WHEN] Synchronizing the salesperson
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        ConfirmReply := false;
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId);

        // [THEN] The user is warned sync has never taken place and asked to confirm data replacement
        // [WHEN] The user cancels
        // Happens in TestSyncSingleSalespersonBothModifiedConfirmHandler

        // [THEN] The data in NAV is not changed
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        Assert.AreEqual(OriginalSalespersonName, SalespersonPurchaser.Name,
          'The salesperson should have the same name it had before');

        // [WHEN] The user tries again and this time does not cancel
        ConfirmReply := true;
        CRMIntegrationManagement.UpdateOneNow(SalespersonPurchaser.RecordId);

        // [THEN] The user is asked to confirm data replacement
        // [WHEN] The user confirms
        // Happens in TestSyncSingleSalespersonBothModifiedConfirmHandler
        CRMSystemuser.SetRange(SystemUserId, CRMSystemuser.SystemUserId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Systemuser", CRMSystemuser.GetView(), IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in NAV is overwritten with the data from CRM
        SalespersonPurchaser.Get(SalespersonPurchaser.Code);
        Assert.AreEqual(OriginalCRMSystemuserName, SalespersonPurchaser.Name,
          'The salesperson should have the name the CRM systemuser had before');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure TestSyncSingleSalespersonBothModifiedConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage('synchronization has never been performed', Question);
        Reply := ConfirmReply;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchModifiedRecordWithNonMappedFieldToCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        LastSynchModifiedOn: DateTime;
    begin
        // [SCENARIO 380128] The timestamp of Integration Record should be updated when synch modified record with field which does not exist in Table Mapping

        Init();

        // [GIVEN] Customer "X" synced with CRM Account
        SetupCoupledCustomer(IntegrationTableMapping, Customer, CRMAccount);

        // Modify "Last Synch. Modified On" with one day back to make sure that new value is more than latest
        LastSynchModifiedOn := SetCRMIntegrationSyncOneDayBack(CRMIntegrationRecord, CRMAccount, Customer.RecordId);

        // [GIVEN] Modified field "Name 2" in NAV which is not mapped with CRM Account
        Customer.Validate("Name 2", CopyStr(Customer.Name, 1, MaxStrLen(Customer."Name 2")));
        Customer.Modify(true);
        IntegrationSynchJob.DeleteAll(); // make sure that after next synch there will be only one integration synch job

        // [WHEN] Sync Customer "X" to CRM
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, false, false);

        // [THEN] Integration Sync. Job tracked as "Unchanged"
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, 0, 1);

        // [THEN] "Last Synch. Modified On" of CRM Integration Record connected to Customer "X" is updated
        CRMIntegrationRecord.Find();
        Assert.IsTrue(
          CRMIntegrationRecord."Last Synch. Modified On" > LastSynchModifiedOn,
          StrSubstNo(FieldNotUpdatedErr, CRMIntegrationRecord.FieldNo("Last Synch. Modified On")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncModifiedCustomerWithAdditionalNonMappedFieldToCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        LastSynchModifiedOn: DateTime;
    begin
        // [SCENARIO 380128] The timestamp of Integration Record should be updated when synch Customer with updated Currency (not mapped but handled by specific method)

        Init();

        // [GIVEN] Coupled Salesperson "Y" to CRM User
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] Customer "X" synced with CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // Modify "Last Synch. Modified On" with one day back to make sure that new value is more than latest
        LastSynchModifiedOn := SetCRMIntegrationSyncOneDayBack(CRMIntegrationRecord, CRMAccount, Customer.RecordId);

        // [GIVEN] Modified "Salesperson Code" with "Y" in NAV
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);
        IntegrationSynchJob.DeleteAll();

        // [WHEN] Sync Customer "X" to CRM
        Clear(IntegrationTableMapping);
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, false, false);

        // [THEN] Integration Sync. Job tracked as "Modified"
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, 1, 0);

        // [THEN] "Last Synch. Modified On" of CRM Integration Record connected to Customer "X" is updated
        CRMIntegrationRecord.Find();
        Assert.IsTrue(
          CRMIntegrationRecord."Last Synch. Modified On" > LastSynchModifiedOn,
          StrSubstNo(FieldNotUpdatedErr, CRMIntegrationRecord.FieldNo("Last Synch. Modified On")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeNotUpdatedIfNothingToSyncCRMClockSynced()
    begin
        LastSyncTimeNotUpdatedIfNothingToSync(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeNotUpdatedIfNothingToSyncCRMClockBehind()
    begin
        LastSyncTimeNotUpdatedIfNothingToSync(-300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeNotUpdatedIfNothingToSyncCRMClockAhead()
    begin
        LastSyncTimeNotUpdatedIfNothingToSync(300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyWhenSyncFailedCRMClockSynced()
    begin
        LastSyncTimeUpdatedCorrectlyWhenSyncFailed(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyWhenSyncFailedCRMClockBehind()
    begin
        LastSyncTimeUpdatedCorrectlyWhenSyncFailed(-300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyWhenSyncFailedCRMClockAhead()
    begin
        LastSyncTimeUpdatedCorrectlyWhenSyncFailed(300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyWhenSyncSucceedCRMClockSynced()
    begin
        LastSyncTimeUpdatedCorrectlyWhenSyncSucceed(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyWhenSyncSucceedCRMClockBehind()
    begin
        LastSyncTimeUpdatedCorrectlyWhenSyncSucceed(-300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyWhenSyncSucceedCRMClockAhead()
    begin
        LastSyncTimeUpdatedCorrectlyWhenSyncSucceed(300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyAfterFixingCustomerPrimaryContactNoCRMClockSynced()
    begin
        LastSyncTimeUpdatedCorrectlyAfterFixingCustomerPrimaryContactNo(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyAfterFixingCustomerPrimaryContactNoCRMClockBehind()
    begin
        LastSyncTimeUpdatedCorrectlyAfterFixingCustomerPrimaryContactNo(-300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyAfterFixingCustomerPrimaryContactNoCRMClockAhead()
    begin
        LastSyncTimeUpdatedCorrectlyAfterFixingCustomerPrimaryContactNo(300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyAfterFixingAccountPrimaryContactIdCRMClockSynced()
    begin
        LastSyncTimeUpdatedCorrectlyAfterFixingAccountPrimaryContactId(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyAfterFixingAccountPrimaryContactIdCRMClockBehind()
    begin
        LastSyncTimeUpdatedCorrectlyAfterFixingAccountPrimaryContactId(-300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastSyncTimeUpdatedCorrectlyAfterFixingAccountPrimaryContactIdCRMClockAhead()
    begin
        LastSyncTimeUpdatedCorrectlyAfterFixingAccountPrimaryContactId(300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncChangeToCrmTwoTimesWhenCrmClockBehind()
    begin
        SyncChangeToCrmTwoTimes(-300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncChangeToCrmTwoTimesCrmClockAhead()
    begin
        SyncChangeToCrmTwoTimes(300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncChangeFromCrmTwoTimesWhenCrmClockBehind()
    begin
        SyncChangeFromCrmTwoTimes(-300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncChangeFromCrmTwoTimesWhenCrmClockAhead()
    begin
        SyncChangeFromCrmTwoTimes(300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncChangeToCrmThenSyncChangeFromCrmWhenCrmClockBehind()
    begin
        SyncChangeToCrmThenSyncChangeFromCrm(-300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncChangeToCrmThenSyncChangeFromCrmWhenCrmClockAhead()
    begin
        SyncChangeToCrmThenSyncChangeFromCrm(300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncChangeFromCrmThenSyncChangeToCrmWhenCrmClockBehind()
    begin
        SyncChangeFromCrmThenSyncChangeToCrm(-300);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncChangeFromCrmThenSyncChangeToCrmWhenCrmClockAhead()
    begin
        SyncChangeFromCrmThenSyncChangeToCrm(300);
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleCustomerBothModifiedMessageHandler,TestSyncSingleRecordStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncSingleCustomerCRMPrimaryContactEmpty()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        Contact: Record Contact;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        JobQueueEntryID: Guid;
        EmptyGuid: Guid;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO] Synchronizing a single customer modified in CRM by removing primary contact
        Init();

        // [GIVEN] A customer coupled with a CRM account and since modified in CRM by removing primary contact
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        Customer."Primary Contact No." := Contact."No.";
        Customer.Modify();
        CRMAccount.PrimaryContactId := EmptyGuid;
        CRMAccount.Modify();

        // [WHEN] Synchronizing the customer
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        SynchDirection := SynchDirection::ToNAV;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);

        // [THEN] The user is asked to select the synchronization direction
        // [WHEN] The user selects synchronization from CRM
        // Happens in TestSyncSingleRecordStrMenuHandler
        CRMAccount.SetRange(AccountId, CRMAccount.AccountId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            Database::"CRM Account", CRMAccount.GetView(), IntegrationTableMapping);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] The data in is overwritten with the data from CRM
        Customer.GetBySystemId(Customer.SystemId);
        Assert.AreEqual('', Customer."Primary Contact No.", 'Primary contact should be empty');
    end;

    local procedure SyncChangeToCrmTwoTimes(CRMTimeDiffSeconds: Integer)
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SleepDuration: Integer;
        I: Integer;
    begin
        // [SCENARIO 365486] Synchronize two consecutive changes to CRM
        StartCRMTimeDiffMock(CRMTimeDiffSeconds);
        SleepDuration := 20;

        // [GIVEN] Coupled records
        CreateCoupledContactsWithParentCustomerAndAccount(Contact, CRMContact, Customer, CRMAccount);

        // [GIVEN] Records are synced
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Synch. Modified On Filter" := CRMIntegrationRecord."Last Synch. CRM Modified On";
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := CRMIntegrationRecord."Last Synch. Modified On" + 5;
        IntegrationTableMapping.Modify();
        IntegrationTableMapping.GetBySystemId(IntegrationTableMapping.SystemId);

        for I := 1 to 2 do begin
            // [WHEN] Record is modified in BC
            Sleep(SleepDuration);
            Customer.GetBySystemId(Customer.SystemId);
            Customer.Name := 'X' + Format(I);
            Customer.Modify();

            // [WHEN] Run sync
            CRMIntegrationTableSynch.Run(IntegrationTableMapping);

            // [THEN] The sync jobs succeed and modified records in the sync directions
            CRMAccount.Get(CRMAccount.AccountId);
            CRMAccount.TestField(Name, Customer.Name);
            VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::ToIntegrationTable, 0, 1, 0, 0, 0, 0, '#1' + StrSubstNo('.%1', I));
            VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::FromIntegrationTable, 0, 0, 0, 1, 0, 0, '#2' + StrSubstNo('.%1', I));
        end;

        StopCRMTimeDiffMock();
    end;

    local procedure SyncChangeFromCrmTwoTimes(CRMTimeDiffSeconds: Integer)
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SleepDuration: Integer;
        I: Integer;
    begin
        // [SCENARIO 365486] Synchronize two consecutive changes from CRM
        StartCRMTimeDiffMock(CRMTimeDiffSeconds);
        SleepDuration := 20;

        // [GIVEN] Coupled records
        CreateCoupledContactsWithParentCustomerAndAccount(Contact, CRMContact, Customer, CRMAccount);

        // [GIVEN] Records are synced
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Synch. Modified On Filter" := CRMIntegrationRecord."Last Synch. CRM Modified On";
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := CRMIntegrationRecord."Last Synch. Modified On" + 5;
        IntegrationTableMapping.Modify();
        IntegrationTableMapping.GetBySystemId(IntegrationTableMapping.SystemId);

        for I := 1 to 2 do begin
            // [WHEN] Record is modified in CRM
            Sleep(SleepDuration);
            CRMAccount.Get(CRMAccount.AccountId);
            CRMAccount.Name := 'Y' + Format(I);
            CRMAccount.Modify();

            // [WHEN] Run sync
            CRMIntegrationTableSynch.Run(IntegrationTableMapping);

            // [THEN] The sync jobs succeed and modified records in the sync directions
            Customer.GetBySystemId(Customer.SystemId);
            Customer.TestField(Name, CRMAccount.Name);
            VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::ToIntegrationTable, 0, 0, 0, I - 1, 0, 0, '#1' + StrSubstNo('.%1', I));
            VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::FromIntegrationTable, 0, 1, 0, 0, 0, 0, '#2' + StrSubstNo('.%1', I));
        end;

        StopCRMTimeDiffMock();
    end;

    local procedure SyncChangeToCrmThenSyncChangeFromCrm(CRMTimeDiffSeconds: Integer)
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SleepDuration: Integer;
    begin
        // [SCENARIO 365486] Synchronize change to CRM and then change from CRM
        StartCRMTimeDiffMock(CRMTimeDiffSeconds);
        SleepDuration := 20;

        // [GIVEN] Coupled records
        CreateCoupledContactsWithParentCustomerAndAccount(Contact, CRMContact, Customer, CRMAccount);

        // [GIVEN] Records are synced
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Synch. Modified On Filter" := CRMIntegrationRecord."Last Synch. CRM Modified On";
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := CRMIntegrationRecord."Last Synch. Modified On" + 5;
        IntegrationTableMapping.Modify();
        IntegrationTableMapping.GetBySystemId(IntegrationTableMapping.SystemId);

        // [WHEN] Record is modified in BC
        Sleep(SleepDuration);
        Customer.GetBySystemId(Customer.SystemId);
        Customer.Name := 'X1';
        Customer.Modify();

        // [WHEN] Run sync
        CRMIntegrationTableSynch.Run(IntegrationTableMapping);

        // [THEN] The sync jobs succeed and modified records in the sync directions
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.TestField(Name, Customer.Name);
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::ToIntegrationTable, 0, 1, 0, 0, 0, 0, '#1');
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::FromIntegrationTable, 0, 0, 0, 1, 0, 0, '#2');

        // [WHEN] Record is modified in BC
        Sleep(SleepDuration);
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.Name := 'Y1';
        CRMAccount.Modify();

        // [WHEN] Run sync
        CRMIntegrationTableSynch.Run(IntegrationTableMapping);

        // [THEN] The sync jobs succeed and modified records in the sync directions
        Customer.GetBySystemId(Customer.SystemId);
        Customer.TestField(Name, CRMAccount.Name);
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::ToIntegrationTable, 0, 0, 0, 0, 0, 0, '#3');
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::FromIntegrationTable, 0, 1, 0, 0, 0, 0, '#4');

        StopCRMTimeDiffMock();
    end;

    local procedure SyncChangeFromCrmThenSyncChangeToCrm(CRMTimeDiffSeconds: Integer)
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SleepDuration: Integer;
    begin
        // [SCENARIO 365486] Synchronize change from CRM and then change to CRM
        StartCRMTimeDiffMock(CRMTimeDiffSeconds);
        SleepDuration := 20;

        // [GIVEN] Coupled records
        CreateCoupledContactsWithParentCustomerAndAccount(Contact, CRMContact, Customer, CRMAccount);

        // [GIVEN] Records are synced
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Synch. Modified On Filter" := CRMIntegrationRecord."Last Synch. CRM Modified On";
        IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := CRMIntegrationRecord."Last Synch. Modified On" + 5;
        IntegrationTableMapping.Modify();
        IntegrationTableMapping.GetBySystemId(IntegrationTableMapping.SystemId);

        // [WHEN] Record is modified in CRM
        Sleep(SleepDuration);
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.Name := 'Y1';
        CRMAccount.Modify();

        // [WHEN] Run sync
        CRMIntegrationTableSynch.Run(IntegrationTableMapping);

        // [THEN] The sync jobs succeed and modified records in the sync directions
        // Ignore check for count of Unchanged because of one second treshold for CRM records
        Customer.GetBySystemId(Customer.SystemId);
        Customer.TestField(Name, CRMAccount.Name);
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::ToIntegrationTable, 0, 0, 0, 0, 0, 0, '#1');
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::FromIntegrationTable, 0, 1, 0, 0, 0, 0, '#2');

        // [WHEN] Record is modified in BC
        Sleep(SleepDuration);
        Customer.GetBySystemId(Customer.SystemId);
        Customer.Name := 'X1';
        Customer.Modify();

        // [WHEN] Run sync
        CRMIntegrationTableSynch.Run(IntegrationTableMapping);

        // [THEN] The sync jobs succeed and modified records in the sync directions
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.TestField(Name, Customer.Name);
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::ToIntegrationTable, 0, 1, 0, 0, 0, 0, '#3');
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, IntegrationTableMapping.Direction::FromIntegrationTable, 0, 0, 0, 1, 0, 0, '#4');

        StopCRMTimeDiffMock();
    end;

    local procedure LastSyncTimeNotUpdatedIfNothingToSync(CRMTimeDiffSeconds: Integer)
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        ContactCRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        CustomerCRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        ContactIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        CustomerIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
    begin
        // [SCENARIO 365486] The last sync timestamp should not be updated if nothing to sync
        StartCRMTimeDiffMock(CRMTimeDiffSeconds);

        // [GIVEN] Coupled records
        CreateCoupledContactsWithParentCustomerAndAccount(Contact, CRMContact, Customer, CRMAccount);

        // [GIVEN] Records are synced
        CustomerCRMIntegrationRecord[1].FindByCRMID(CRMAccount.AccountId);
        ContactCRMIntegrationRecord[1].FindByCRMID(CRMContact.ContactId);
        CustomerIntegrationTableMapping[1].Get('CUSTOMER');
        ContactIntegrationTableMapping[1].Get('CONTACT');
        CustomerIntegrationTableMapping[1]."Synch. Modified On Filter" := CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On";
        CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := CustomerCRMIntegrationRecord[1]."Last Synch. Modified On" + 5;
        CustomerIntegrationTableMapping[1].Modify();
        ContactIntegrationTableMapping[1]."Synch. Modified On Filter" := ContactCRMIntegrationRecord[1]."Last Synch. CRM Modified On";
        ContactIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := ContactCRMIntegrationRecord[1]."Last Synch. Modified On" + 5;
        ContactIntegrationTableMapping[1].Modify();
        CustomerIntegrationTableMapping[2].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        ContactIntegrationTableMapping[2].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);

        // [WHEN] Run sync
        CRMIntegrationTableSynch.Run(CustomerIntegrationTableMapping[2]);
        CRMIntegrationTableSynch.Run(ContactIntegrationTableMapping[2]);
        StopCRMTimeDiffMock();

        // [THEN] The sync jobs succeed, but nothing was synced
        VerifyIntegrationSynchJob(CustomerIntegrationTableMapping[1].Name, CustomerIntegrationTableMapping[1].Direction::ToIntegrationTable, 0, 0, 0, 0, 0, 0, '#1');
        VerifyIntegrationSynchJob(CustomerIntegrationTableMapping[1].Name, CustomerIntegrationTableMapping[1].Direction::FromIntegrationTable, 0, 0, 0, 1, 0, 0, '#2');
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::ToIntegrationTable, 0, 0, 0, 0, 0, 0, '#3');
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::FromIntegrationTable, 0, 0, 0, 1, 0, 0, '#4');

        // [THEN] Last sync timestamps are unchanged in CRM Integration Record
        CustomerCRMIntegrationRecord[2].GetBySystemId(CustomerCRMIntegrationRecord[1].SystemId);
        ContactCRMIntegrationRecord[2].GetBySystemId(ContactCRMIntegrationRecord[1].SystemId);
        AssertAreEqual(CustomerCRMIntegrationRecord[1]."Last Synch. Modified On", CustomerCRMIntegrationRecord[2]."Last Synch. Modified On", '#1');
        AssertAreEqual(CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On", CustomerCRMIntegrationRecord[2]."Last Synch. CRM Modified On", '#2');
        AssertAreEqual(ContactCRMIntegrationRecord[1]."Last Synch. Modified On", ContactCRMIntegrationRecord[2]."Last Synch. Modified On", '#3');
        AssertAreEqual(ContactCRMIntegrationRecord[1]."Last Synch. CRM Modified On", ContactCRMIntegrationRecord[2]."Last Synch. CRM Modified On", '#4');

        // [THEN] Last sync timestamps are unchanged in Integration Table Mapping
        CustomerIntegrationTableMapping[1].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        ContactIntegrationTableMapping[1].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);
        AssertAreEqual(CustomerIntegrationTableMapping[1]."Synch. Modified On Filter", CustomerIntegrationTableMapping[2]."Synch. Modified On Filter", '#5');
        AssertAreEqual(CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr.", CustomerIntegrationTableMapping[2]."Synch. Int. Tbl. Mod. On Fltr.", '#6');
        AssertAreEqual(ContactIntegrationTableMapping[1]."Synch. Modified On Filter", ContactIntegrationTableMapping[2]."Synch. Modified On Filter", '#7');
        AssertAreEqual(ContactIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr.", ContactIntegrationTableMapping[2]."Synch. Int. Tbl. Mod. On Fltr.", '#8');
    end;

    local procedure LastSyncTimeUpdatedCorrectlyWhenSyncFailed(CRMTimeDiffSeconds: Integer)
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        ContactCRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        CustomerCRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        ContactIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        CustomerIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        SleepDuration: Integer;
    begin
        // [SCENARIO 365486] The last sync timestamp are updated even when sync job failed
        StartCRMTimeDiffMock(CRMTimeDiffSeconds);
        SleepDuration := 20;

        // [GIVEN] Coupled records
        CreateCoupledContactsWithParentCustomerAndAccount(Contact, CRMContact, Customer, CRMAccount);

        // [GIVEN] Records are synced
        CustomerCRMIntegrationRecord[1].FindByCRMID(CRMAccount.AccountId);
        ContactCRMIntegrationRecord[1].FindByCRMID(CRMContact.ContactId);
        CustomerIntegrationTableMapping[1].Get('CUSTOMER');
        ContactIntegrationTableMapping[1].Get('CONTACT');
        CustomerIntegrationTableMapping[1]."Synch. Modified On Filter" := CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On";
        CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := CustomerCRMIntegrationRecord[1]."Last Synch. Modified On" + 5;
        CustomerIntegrationTableMapping[1].Modify();
        ContactIntegrationTableMapping[1]."Synch. Modified On Filter" := ContactCRMIntegrationRecord[1]."Last Synch. CRM Modified On";
        ContactIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := ContactCRMIntegrationRecord[1]."Last Synch. Modified On" + 5;
        ContactIntegrationTableMapping[1].Modify();
        CustomerIntegrationTableMapping[2].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        ContactIntegrationTableMapping[2].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);

        // [WHEN] Bi-directional filed are modified on both sides
        Sleep(SleepDuration);
        Customer.GetBySystemId(Customer.SystemId);
        Customer.Name := 'X';
        Customer.Modify();
        Sleep(SleepDuration);
        Contact.GetBySystemId(Contact.SystemId);
        Contact.Surname := 'X';
        Contact.Modify();
        Sleep(SleepDuration);
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.Name := 'Y';
        CRMAccount.Modify();
        Sleep(SleepDuration);
        CRMContact.Get(CRMContact.ContactId);
        CRMContact.LastName := 'Y';
        CRMContact.Modify();

        // [WHEN] Run sync
        CRMIntegrationTableSynch.Run(CustomerIntegrationTableMapping[2]);
        CRMIntegrationTableSynch.Run(ContactIntegrationTableMapping[2]);
        StopCRMTimeDiffMock();

        // [THEN] The sync jobs failed
        VerifyIntegrationSynchJob(CustomerIntegrationTableMapping[1].Name, CustomerIntegrationTableMapping[1].Direction::ToIntegrationTable, 0, 0, 0, 0, 0, 1, '#1');
        VerifyIntegrationSynchJob(CustomerIntegrationTableMapping[1].Name, CustomerIntegrationTableMapping[1].Direction::FromIntegrationTable, 0, 0, 0, 0, 0, 1, '#2');
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::ToIntegrationTable, 0, 0, 0, 0, 0, 1, '#3');
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::FromIntegrationTable, 0, 0, 0, 0, 0, 1, '#4');

        // [THEN] The records are not synched
        Customer.GetBySystemId(Customer.SystemId);
        CRMAccount.Get(CRMAccount.AccountId);
        Assert.AreNotEqual(CRMAccount.Name, Customer.Name, '');
        Contact.GetBySystemId(Contact.SystemId);
        CRMContact.Get(CRMContact.ContactId);
        Assert.AreNotEqual(Contact.Surname, CRMContact.LastName, '');

        // [THEN] Last sync timestamps are unchanged in CRM Integration Record
        CustomerCRMIntegrationRecord[2].GetBySystemId(CustomerCRMIntegrationRecord[1].SystemId);
        ContactCRMIntegrationRecord[2].GetBySystemId(ContactCRMIntegrationRecord[1].SystemId);
        AssertAreEqual(CustomerCRMIntegrationRecord[1]."Last Synch. Modified On", CustomerCRMIntegrationRecord[2]."Last Synch. Modified On", '#1');
        AssertAreEqual(CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On", CustomerCRMIntegrationRecord[2]."Last Synch. CRM Modified On", '#2');
        AssertAreEqual(ContactCRMIntegrationRecord[1]."Last Synch. Modified On", ContactCRMIntegrationRecord[2]."Last Synch. Modified On", '#3');
        AssertAreEqual(ContactCRMIntegrationRecord[1]."Last Synch. CRM Modified On", ContactCRMIntegrationRecord[2]."Last Synch. CRM Modified On", '#4');

        // [THEN] Last sync timestamps are updated correctly in Integration Table Mapping
        CustomerIntegrationTableMapping[2].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        ContactIntegrationTableMapping[2].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);
        Assert.IsTrue(CustomerIntegrationTableMapping[1]."Synch. Modified On Filter" <= CustomerIntegrationTableMapping[2]."Synch. Modified On Filter", '#5.1');
        Assert.IsTrue(CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." <= CustomerIntegrationTableMapping[2]."Synch. Int. Tbl. Mod. On Fltr.", '#6.1');
        Assert.IsTrue(ContactIntegrationTableMapping[1]."Synch. Modified On Filter" <= ContactIntegrationTableMapping[2]."Synch. Modified On Filter", '#7.1');
        Assert.IsTrue(ContactIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." <= ContactIntegrationTableMapping[2]."Synch. Int. Tbl. Mod. On Fltr.", '#8.1');
    end;

    local procedure LastSyncTimeUpdatedCorrectlyWhenSyncSucceed(CRMTimeDiffSeconds: Integer)
    var
        Contact: array[2] of Record Contact;
        CRMContact: array[2] of Record "CRM Contact";
        Customer: array[2] of Record Customer;
        CRMAccount: array[2] of Record "CRM Account";
        ContactCRMIntegrationRecord: array[2, 2] of Record "CRM Integration Record";
        CustomerCRMIntegrationRecord: array[2, 2] of Record "CRM Integration Record";
        ContactIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        CustomerIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        SleepDuration: Integer;
        I: Integer;
    begin
        // [SCENARIO 365486] The last sync timestamp are updated when sync job succeed
        StartCRMTimeDiffMock(CRMTimeDiffSeconds);
        SleepDuration := 20;

        // [GIVEN] Coupled records
        CreateCoupledContactsWithParentCustomerAndAccount(Contact[1], CRMContact[1], Customer[1], CRMAccount[1]);
        Sleep(SleepDuration);
        CreateCoupledContactsWithParentCustomerAndAccount(Contact[2], CRMContact[2], Customer[2], CRMAccount[2]);

        // [GIVEN] Records are synced
        CustomerCRMIntegrationRecord[2, 1].FindByCRMID(CRMAccount[2].AccountId);
        ContactCRMIntegrationRecord[2, 1].FindByCRMID(CRMContact[2].ContactId);
        CustomerIntegrationTableMapping[1].Get('CUSTOMER');
        ContactIntegrationTableMapping[1].Get('CONTACT');
        CustomerIntegrationTableMapping[1]."Synch. Modified On Filter" := CustomerCRMIntegrationRecord[2, 1]."Last Synch. CRM Modified On";
        CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := CustomerCRMIntegrationRecord[2, 1]."Last Synch. Modified On" + 5;
        CustomerIntegrationTableMapping[1].Modify();
        ContactIntegrationTableMapping[1]."Synch. Modified On Filter" := ContactCRMIntegrationRecord[2, 1]."Last Synch. CRM Modified On";
        ContactIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := ContactCRMIntegrationRecord[2, 1]."Last Synch. Modified On" + 5;
        ContactIntegrationTableMapping[1].Modify();
        CustomerIntegrationTableMapping[2].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        ContactIntegrationTableMapping[2].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);

        // [WHEN] Record is modified on one side
        Sleep(SleepDuration);
        Customer[1].GetBySystemId(Customer[1].SystemId);
        Customer[1].Name := 'X';
        Customer[1].Modify();
        Sleep(SleepDuration);
        CRMAccount[2].Get(CRMAccount[2].AccountId);
        CRMAccount[2].Name := 'Y';
        CRMAccount[2].Modify();
        Sleep(SleepDuration);
        Contact[2].GetBySystemId(Contact[2].SystemId);
        Contact[2].Surname := 'Y';
        Contact[2].Modify();
        Sleep(SleepDuration);
        CRMContact[1].Get(CRMContact[1].ContactId);
        CRMContact[1].LastName := 'X';
        CRMContact[1].Modify();

        // [WHEN] Run sync
        CRMIntegrationTableSynch.Run(CustomerIntegrationTableMapping[2]);
        CRMIntegrationTableSynch.Run(ContactIntegrationTableMapping[2]);
        StopCRMTimeDiffMock();

        // [THEN] The sync jobs succeed and modified records in the sync directions
        VerifyIntegrationSynchJob(CustomerIntegrationTableMapping[1].Name, CustomerIntegrationTableMapping[1].Direction::ToIntegrationTable, 0, 1, 0, 0, 0, 0, '#1');
        VerifyIntegrationSynchJob(CustomerIntegrationTableMapping[1].Name, CustomerIntegrationTableMapping[1].Direction::FromIntegrationTable, 0, 1, 0, 1, 0, 0, '#2');
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::ToIntegrationTable, 0, 1, 0, 0, 0, 0, '#3');
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::FromIntegrationTable, 0, 1, 0, 1, 0, 0, '#4');

        // [THEN] The records are updated correctly
        for I := 1 to 2 do begin
            Customer[I].GetBySystemId(Customer[I].SystemId);
            CRMAccount[I].Get(CRMAccount[I].AccountId);
            CRMAccount[I].TestField(Name, Customer[I].Name);
            Contact[I].GetBySystemId(Contact[I].SystemId);
            CRMContact[I].Get(CRMContact[I].ContactId);
            Contact[I].TestField(Surname, CRMContact[I].LastName);
        end;

        // [THEN] Last sync timestamps are updated correctly in CRM Integration Record
        for I := 1 to 2 do begin
            CustomerCRMIntegrationRecord[I, 2].FindByCRMID(CRMAccount[I].AccountId);
            ContactCRMIntegrationRecord[I, 2].FindByCRMID(CRMContact[I].ContactId);
            AssertAreNotEqual(CustomerCRMIntegrationRecord[I, 1]."Last Synch. Modified On", CustomerCRMIntegrationRecord[I, 2]."Last Synch. Modified On", '#' + StrSubstNo('1.1[%1]', I));
            AssertAreNotEqual(CustomerCRMIntegrationRecord[I, 1]."Last Synch. CRM Modified On", CustomerCRMIntegrationRecord[I, 2]."Last Synch. CRM Modified On", '#' + StrSubstNo('2.1[%1]', I));
            AssertAreNotEqual(ContactCRMIntegrationRecord[I, 1]."Last Synch. Modified On", ContactCRMIntegrationRecord[I, 2]."Last Synch. Modified On", '#' + StrSubstNo('3.1[%1]', I));
            AssertAreNotEqual(ContactCRMIntegrationRecord[I, 1]."Last Synch. CRM Modified On", ContactCRMIntegrationRecord[I, 2]."Last Synch. CRM Modified On", '#' + StrSubstNo('4.1[%1]', I));
            AssertAreEqual(Customer[I].SystemModifiedAt, CustomerCRMIntegrationRecord[I, 2]."Last Synch. Modified On", '#' + StrSubstNo('1.2[%1]', I));
            AssertAreEqual(CRMAccount[I].ModifiedOn, CustomerCRMIntegrationRecord[I, 2]."Last Synch. CRM Modified On", '#' + StrSubstNo('2.2[%1]', I));
            AssertAreEqual(Contact[I].SystemModifiedAt, ContactCRMIntegrationRecord[I, 2]."Last Synch. Modified On", '#' + StrSubstNo('3.2[%1]', I));
            AssertAreEqual(CRMContact[I].ModifiedOn, ContactCRMIntegrationRecord[I, 2]."Last Synch. CRM Modified On", '#' + StrSubstNo('4.2[%1]', I));
        end;

        // [THEN] Last sync timestamps are updated correctly in Integration Table Mapping
        CustomerIntegrationTableMapping[2].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        ContactIntegrationTableMapping[2].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);
        Assert.IsTrue(CustomerIntegrationTableMapping[1]."Synch. Modified On Filter" <= CustomerIntegrationTableMapping[2]."Synch. Modified On Filter", '#5.1');
        Assert.IsTrue(CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." <= CustomerIntegrationTableMapping[2]."Synch. Int. Tbl. Mod. On Fltr.", '#6.1');
        Assert.IsTrue(ContactIntegrationTableMapping[1]."Synch. Modified On Filter" <= ContactIntegrationTableMapping[2]."Synch. Modified On Filter", '#7.1');
        Assert.IsTrue(ContactIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." <= ContactIntegrationTableMapping[2]."Synch. Int. Tbl. Mod. On Fltr.", '#8.1');
    end;

    local procedure LastSyncTimeUpdatedCorrectlyAfterFixingCustomerPrimaryContactNo(CRMTimeDiffSeconds: Integer)
    var
        CompanyContact: Record Contact;
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        ContactCRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        CustomerCRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        SalespersonCRMIntegrationRecord: Record "CRM Integration Record";
        ContactIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        CustomerIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CustomerNo: Code[20];
        SleepDuration: Integer;
    begin
        // [SCENARIO 365486] The last sync timestamp are updated when sync job fixes Primary Contact No. on Customer through trigger
        StartCRMTimeDiffMock(CRMTimeDiffSeconds);
        SleepDuration := 20;

        // [GIVEN] Coupled Customer and Account, Contact only exists in CDS
        LibraryMarketing.CreateCompanyContact(CompanyContact);
        CompanyContact.SetHideValidationDialog(true);
        CustomerNo := CompanyContact.CreateCustomerFromTemplate('');
        Customer.Get(CustomerNo);
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        CustomerCRMIntegrationRecord[1].CoupleRecordIdToCRMID(Customer.RecordId(), CRMAccount.AccountId);
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);
        SalespersonCRMIntegrationRecord.FindByCRMID(CRMAccount.OwnerId);
        SalespersonPurchaser.GetBySystemId(SalespersonCRMIntegrationRecord."Integration ID");
        Customer.GetBySystemId(Customer.SystemId);
        Customer.Name := 'B';
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.Name := 'B';
        CRMAccount.Modify(true);
        CustomerCRMIntegrationRecord[1].FindByCRMID(CRMAccount.AccountId);
        CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On" := CRMAccount.ModifiedOn;
        CustomerCRMIntegrationRecord[1]."Last Synch. Modified On" := Customer.SystemModifiedAt;
        CustomerCRMIntegrationRecord[1].Modify();

        // [GIVEN] Records are synced
        CustomerIntegrationTableMapping[1].Get('CUSTOMER');
        ContactIntegrationTableMapping[1].Get('CONTACT');
        CustomerIntegrationTableMapping[1]."Synch. Modified On Filter" := CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On";
        CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := CustomerCRMIntegrationRecord[1]."Last Synch. Modified On" + 5;
        CustomerIntegrationTableMapping[1].Modify();
        ContactIntegrationTableMapping[1]."Synch. Modified On Filter" := CustomerIntegrationTableMapping[1]."Synch. Modified On Filter";
        ContactIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr.";
        ContactIntegrationTableMapping[1]."Synch. Only Coupled Records" := false;
        ContactIntegrationTableMapping[1].Modify();
        CustomerIntegrationTableMapping[2].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        ContactIntegrationTableMapping[2].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);

        // [WHEN] Contact is modified on CDS side
        Sleep(SleepDuration);
        CRMContact.Get(CRMContact.ContactId);
        CRMContact.LastName := 'X';
        CRMContact.OwnerId := CRMAccount.OwnerId;
        CRMContact.OwnerIdType := CRMAccount.OwnerIdType;
        CRMContact.Modify();

        // [WHEN] Run sync
        CRMIntegrationTableSynch.Run(ContactIntegrationTableMapping[2]);
        StopCRMTimeDiffMock();

        // [THEN] The sync jobs succeed and modified the contact in BC
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::ToIntegrationTable, 0, 0, 0, 0, 0, 0, '#1');
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::FromIntegrationTable, 1, 0, 0, 0, 0, 0, '#2');

        // [THEN] The contact record is updated correctly
        ContactCRMIntegrationRecord[2].FindByCRMID(CRMContact.ContactId);
        Contact.GetBySystemId(ContactCRMIntegrationRecord[2]."Integration ID");
        CRMContact.Get(CRMContact.ContactId);
        CRMContact.TestField(LastName, Contact.Surname);

        // [THEN] The customer record is updated correctly
        CustomerCRMIntegrationRecord[2].FindByCRMID(CRMAccount.AccountId);
        Customer.GetBySystemId(Customer.SystemId);
        CRMAccount.Get(CRMAccount.AccountId);
        Customer.TestField("Primary Contact No.", Contact."No.");

        // [THEN] Last sync timestamps are updated correctly in CRM Integration Record for the contact
        AssertAreEqual(Contact.SystemModifiedAt, ContactCRMIntegrationRecord[2]."Last Synch. Modified On", '#1');
        AssertAreEqual(CRMContact.ModifiedOn, ContactCRMIntegrationRecord[2]."Last Synch. CRM Modified On", '#2');

        // [THEN] Last sync timestamps are updated correctly in CRM Integration Record for the customer
        AssertAreEqual(CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On", CustomerCRMIntegrationRecord[2]."Last Synch. CRM Modified On", '#3');
        AssertAreNotEqual(CustomerCRMIntegrationRecord[1]."Last Synch. Modified On", CustomerCRMIntegrationRecord[2]."Last Synch. Modified On", '#4');
        AssertAreEqual(Customer.SystemModifiedAt, CustomerCRMIntegrationRecord[2]."Last Synch. Modified On", '#5');

        // [THEN] Last sync timestamps are updated correctly in Integration Table Mapping for the contact
        ContactIntegrationTableMapping[2].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);

        // [THEN] Last sync timestamps are not updated in Integration Table Mapping for the customer
        CustomerIntegrationTableMapping[2].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        AssertAreEqual(CustomerIntegrationTableMapping[1]."Synch. Modified On Filter", CustomerIntegrationTableMapping[2]."Synch. Modified On Filter", '#9');
        AssertAreEqual(CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr.", CustomerIntegrationTableMapping[2]."Synch. Int. Tbl. Mod. On Fltr.", '#10');
    end;

    local procedure LastSyncTimeUpdatedCorrectlyAfterFixingAccountPrimaryContactId(CRMTimeDiffSeconds: Integer)
    var
        CompanyContact: Record Contact;
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        ContactCRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        CustomerCRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        SalespersonCRMIntegrationRecord: Record "CRM Integration Record";
        ContactIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        CustomerIntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CustomerNo: Code[20];
        SleepDuration: Integer;
        ContactModifiedAt: DateTime;
    begin
        // [SCENARIO 365486] The last sync timestamp are updated when sync job fixes Account Contact Id on CRM Account through trigger
        StartCRMTimeDiffMock(CRMTimeDiffSeconds);
        SleepDuration := 20;

        // [GIVEN] Coupled Customer and Account, Contact only exists in BC
        LibraryMarketing.CreatePersonContactWithCompanyNo(Contact);
        CompanyContact.Get(Contact."Company No.");
        CompanyContact.SetHideValidationDialog(true);
        CustomerNo := CompanyContact.CreateCustomerFromTemplate('');
        Customer.Get(CustomerNo);
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        CustomerCRMIntegrationRecord[1].CoupleRecordIdToCRMID(Customer.RecordId(), CRMAccount.AccountId);
        SalespersonCRMIntegrationRecord.FindByCRMID(CRMAccount.OwnerId);
        SalespersonPurchaser.GetBySystemId(SalespersonCRMIntegrationRecord."Integration ID");
        Contact.GetBySystemId(Contact.SystemId);
        Contact.Name := 'B';
        Contact."Salesperson Code" := SalespersonPurchaser.Code;
        Contact.Modify();
        Customer.GetBySystemId(Customer.SystemId);
        Customer.Name := 'B';
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.Name := 'B';
        CRMAccount.Modify(true);
        CustomerCRMIntegrationRecord[1].FindByCRMID(CRMAccount.AccountId);
        CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On" := CRMAccount.ModifiedOn;
        CustomerCRMIntegrationRecord[1]."Last Synch. Modified On" := Customer.SystemModifiedAt;
        CustomerCRMIntegrationRecord[1].Modify();

        // [GIVEN] Records are synced
        CustomerIntegrationTableMapping[1].Get('CUSTOMER');
        ContactIntegrationTableMapping[1].Get('CONTACT');
        CustomerIntegrationTableMapping[1]."Synch. Modified On Filter" := CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On";
        CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := CustomerCRMIntegrationRecord[1]."Last Synch. Modified On" + 5;
        CustomerIntegrationTableMapping[1].Modify();
        ContactIntegrationTableMapping[1]."Synch. Modified On Filter" := CustomerIntegrationTableMapping[1]."Synch. Modified On Filter";
        ContactIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr." := CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr.";
        ContactIntegrationTableMapping[1]."Synch. Only Coupled Records" := false;
        ContactIntegrationTableMapping[1].Modify();
        CustomerIntegrationTableMapping[2].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        ContactIntegrationTableMapping[2].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);

        // [WHEN] Contact is modified on BC side
        Sleep(SleepDuration);
        Contact.GetBySystemId(Contact.SystemId);
        Contact.Surname := 'X';
        Contact.Modify();
        ContactModifiedAt := Contact.SystemModifiedAt;

        // [WHEN] Run sync
        CRMIntegrationTableSynch.Run(ContactIntegrationTableMapping[2]);
        StopCRMTimeDiffMock();

        // [THEN] The sync jobs succeed and modified the contact in BC
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::ToIntegrationTable, 1, 0, 0, 0, 0, 0, '#1');
        VerifyIntegrationSynchJob(ContactIntegrationTableMapping[1].Name, ContactIntegrationTableMapping[1].Direction::FromIntegrationTable, 0, 0, 0, 1, 0, 0, '#2');

        // [THEN] The contact record is updated correctly
        ContactCRMIntegrationRecord[2].FindByRecordID(Contact.RecordId());
        Contact.GetBySystemId(Contact.SystemId);
        CRMContact.Get(ContactCRMIntegrationRecord[2]."CRM ID");
        Contact.TestField(Surname, CRMContact.LastName);

        // [THEN] The account record is updated correctly
        CustomerCRMIntegrationRecord[2].FindByCRMID(CRMAccount.AccountId);
        Customer.GetBySystemId(Customer.SystemId);
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.TestField(PrimaryContactId, CRMContact.ContactId);

        // [THEN] Last sync timestamps are updated correctly in CRM Integration Record for the contact
        AssertAreEqual(ContactModifiedAt, ContactCRMIntegrationRecord[2]."Last Synch. Modified On", '#1');
        AssertAreEqual(CRMContact.ModifiedOn, ContactCRMIntegrationRecord[2]."Last Synch. CRM Modified On", '#2');

        // [THEN] Last sync timestamps are updated correctly in CRM Integration Record for the customer
        AssertAreEqual(CustomerCRMIntegrationRecord[1]."Last Synch. Modified On", CustomerCRMIntegrationRecord[2]."Last Synch. Modified On", '#3');
        AssertAreNotEqual(CustomerCRMIntegrationRecord[1]."Last Synch. CRM Modified On", CustomerCRMIntegrationRecord[2]."Last Synch. CRM Modified On", '#4');
        AssertAreEqual(CRMAccount.ModifiedOn, CustomerCRMIntegrationRecord[2]."Last Synch. CRM Modified On", '#5');

        // [THEN] Last sync timestamps are updated correctly in Integration Table Mapping for the contact
        ContactIntegrationTableMapping[2].GetBySystemId(ContactIntegrationTableMapping[1].SystemId);

        // [THEN] Last sync timestamps are not updated in Integration Table Mapping for the customer
        CustomerIntegrationTableMapping[2].GetBySystemId(CustomerIntegrationTableMapping[1].SystemId);
        AssertAreEqual(CustomerIntegrationTableMapping[1]."Synch. Modified On Filter", CustomerIntegrationTableMapping[2]."Synch. Modified On Filter", '#10');
        AssertAreEqual(CustomerIntegrationTableMapping[1]."Synch. Int. Tbl. Mod. On Fltr.", CustomerIntegrationTableMapping[2]."Synch. Int. Tbl. Mod. On Fltr.", '#11');
    end;

    local procedure StartCRMTimeDiffMock(CRMTimeDiffSeconds: Integer)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        Init();
        LibraryCRMIntegration.SetCRMTimeDiff(CRMTimeDiffSeconds);
        IntTableSynchSubscriber.SetUpdateModifiedOn(true, CRMTimeDiffSeconds);
        UnBindSubscription(IntTableSynchSubscriber);
        BindSubscription(IntTableSynchSubscriber);
        IntegrationSynchJob.DeleteAll();
    end;

    local procedure StopCRMTimeDiffMock()
    begin
        LibraryCRMIntegration.SetCRMTimeDiff(0);
        IntTableSynchSubscriber.SetUpdateModifiedOn(false);
        UnBindSubscription(IntTableSynchSubscriber);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreUnchangedWhenNoFieldsWereModifiedButSourceAndDestinationInConflict()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [SCENARIO 380985] Synchronization is finished successfully with result "Ignore unchanged" when no fields were modified but both source and destination are in conflict

        Init();

        // [GIVEN] Customer "X" synced with CRM Account
        SetupCoupledCustomer(IntegrationTableMapping, Customer, CRMAccount);

        // [GIVEN] Modified field "Name 2" in NAV which is not mapped with CRM Account
        Customer.Validate("Name 2", CopyStr(Customer.Name, 1, MaxStrLen(Customer."Name 2")));
        Customer.Modify(true);

        // [GIVEN] Modified field "E-mail address 3" in CRM which is not mapped with NAV Account
        CRMAccount.Find();
        CRMAccount.Validate(EMailAddress3, LibraryUtility.GenerateGUID());
        CRMAccount.Modify(true);

        // Modify "Last Synch. CRM Modified On" and "Modified One" with one day back to make sure that both Source and Destination are changed and in conflict
        SetCRMIntegrationSyncInConflict(CRMIntegrationRecord, CRMAccount, Customer.RecordId);

        IntegrationSynchJob.DeleteAll(); // make sure that after next synch there will be only one integration synch job

        // [WHEN] Sync Customer "X" to CRM
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, false, false);

        // [THEN] Integration Sync. Job tracked as "Unchanged"
        VerifyIntegrationSynchJob(IntegrationTableMapping.Name, 0, 1);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncNewCustPriceGrWithTwoSalesPrices()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        Item: array[2] of Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        SalesPrice: array[2] of Record "Sales Price";
        CRMProduct: array[2] of Record "CRM Product";
        JobQueueEntryID: Guid;
        I: Integer;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] New "Customer Price Group" with two "Sales Price" lines should be synched to CRM as an inserted Pricelist with 2 lines.
        Init();
        // [GIVEN] The Customer Price Group 'A' with two Sales Price lines
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        for I := 1 to 2 do begin
            LibraryCRMIntegration.CreateCoupledItemAndProduct(Item[I], CRMProduct[I]);
            LibrarySales.CreateSalesPrice(
              SalesPrice[I], Item[I]."No.", SalesPrice[I]."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
              0D, '', '', '', 0, LibraryRandom.RandDecInRange(10, 100, 2));
        end;

        // [WHEN] Customer Price Group 'A' is coupled and synched with teh new CRM Price List
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(CustomerPriceGroup.RecordId);
        CustomerPriceGroup.SetRange(SystemId, CustomerPriceGroup.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Customer Price Group", CustomerPriceGroup.GetView(), IntegrationTableMapping[1]);

        // [THEN] CRM Price List is added, where Name = 'A'
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        CRMPricelevel.TestField(Name, CustomerPriceGroup.Code);
        // [THEN] Two CRM Price list lines are inserted, where
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        Assert.RecordCount(CRMProductpricelevel, 2);
        IntegrationTableMapping[2].SetRange("Table ID", DATABASE::"Sales Price");
        IntegrationTableMapping[2].SetRange("Integration Table ID", DATABASE::"CRM Productpricelevel");
        IntegrationTableMapping[2].FindFirst();
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMapping[2].Name);
        IntegrationSynchJob.FindLast();
        IntegrationSynchJob.TestField(Inserted, 2);
        // [THEN] "Product ID" and "Amount" are synched
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMProduct[1].ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst(), 'Missing first price list line.');
        CRMProductpricelevel.TestField(Amount, SalesPrice[1]."Unit Price");
        CRMProductpricelevel.SetRange(ProductId, CRMProduct[2].ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst(), 'Missing second price list line.');
        CRMProductpricelevel.TestField(Amount, SalesPrice[2]."Unit Price");
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncNewPriceListHeaderWithTwoLines()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProduct: array[2] of Record "CRM Product";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CustomerPriceGroup: Record "Customer Price Group";
        Item: array[2] of Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        JobQueueEntryID: Guid;
        I: Integer;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] New "Price List Header" with two lines should be synched to CRM as an inserted Pricelist with 2 lines.
        Init(true, false);
        // [GIVEN] The Price List Header 'A' with two lines
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code);
        for I := 1 to 2 do begin
            LibraryCRMIntegration.CreateCoupledItemAndProduct(Item[I], CRMProduct[I]);
            LibraryPriceCalculation.CreateSalesPriceLine(
                PriceListLine[I], PriceListHeader.Code, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code,
                "Price Asset Type"::Item, Item[I]."No.");
        end;

        // [WHEN] Price List Header 'A' is coupled and synched with teh new CRM Price List
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(PriceListHeader.RecordId);
        PriceListHeader.SetRange(SystemId, PriceListHeader.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Price List Header", PriceListHeader.GetView(), IntegrationTableMapping[1]);

        // [THEN] CRM Price List is added, where Name = 'A'
        CRMIntegrationRecord.FindByRecordID(PriceListHeader.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        CRMPricelevel.TestField(Name, PriceListHeader.Code);
        // [THEN] Two CRM Price list lines are inserted, where
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        Assert.RecordCount(CRMProductpricelevel, 2);
        IntegrationTableMapping[2].SetRange("Integration Table ID", DATABASE::"CRM Productpricelevel");
        IntegrationTableMapping[2].FindFirst();
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMapping[2].Name);
        IntegrationSynchJob.FindLast();
        IntegrationSynchJob.TestField(Inserted, 2);
        // [THEN] "Product ID" and "Amount" are synched
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMProduct[1].ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst(), 'Missing first price list line.');
        CRMProductpricelevel.TestField(Amount, PriceListLine[1]."Unit Price");
        CRMProductpricelevel.SetRange(ProductId, CRMProduct[2].ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst(), 'Missing second price list line.');
        CRMProductpricelevel.TestField(Amount, PriceListLine[2]."Unit Price");
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncNewPriceListHeaderWithTwoLinesWithUnitGroupEnabled()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProduct: array[2] of Record "CRM Product";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CustomerPriceGroup: Record "Customer Price Group";
        UnitGroup: Record "Unit Group";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMUom: array[2] of Record "CRM Uom";
        Item: array[2] of Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: array[2] of Record "Integration Table Mapping";
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        JobQueueEntryID: Guid;
        I: Integer;
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Unit Group enabled. New "Price List Header" with two lines should be synched to CRM as an inserted Pricelist with 2 lines.
        Init(true, true);
        // [GIVEN] The Price List Header 'A' with two lines
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code);
        for I := 1 to 2 do begin
            LibraryCRMIntegration.CreateCoupledItemUnitGroupAndUomSchedule(UnitGroup, CRMUomschedule);
            Item[I].GetBySystemId(UnitGroup."Source Id");
            ItemUnitOfMeasure.Get(Item[I]."No.", Item[I]."Base Unit of Measure");
            LibraryCRMIntegration.CoupleItemUnitOfMeasure(ItemUnitOfMeasure, CRMUomschedule, CRMUom[I]);
            LibraryCRMIntegration.CoupleItem(Item[I], CRMUom[I], CRMProduct[I]);
            LibraryPriceCalculation.CreateSalesPriceLine(
                PriceListLine[I], PriceListHeader.Code, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code,
                "Price Asset Type"::Item, Item[I]."No.");
        end;

        // [WHEN] Price List Header 'A' is coupled and synched with teh new CRM Price List
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(PriceListHeader.RecordId);
        PriceListHeader.SetRange(SystemId, PriceListHeader.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Price List Header", PriceListHeader.GetView(), IntegrationTableMapping[1]);

        // [THEN] CRM Price List is added, where Name = 'A'
        CRMIntegrationRecord.FindByRecordID(PriceListHeader.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        CRMPricelevel.TestField(Name, PriceListHeader.Code);
        // [THEN] Two CRM Price list lines are inserted, where
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        Assert.RecordCount(CRMProductpricelevel, 2);
        IntegrationTableMapping[2].SetRange("Integration Table ID", DATABASE::"CRM Productpricelevel");
        IntegrationTableMapping[2].FindFirst();
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMapping[2].Name);
        IntegrationSynchJob.FindLast();
        IntegrationSynchJob.TestField(Inserted, 2);
        // [THEN] "Product ID" and "Amount" are synched
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPricelevel.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMProduct[1].ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst(), 'Missing first price list line.');
        CRMProductpricelevel.TestField(Amount, PriceListLine[1]."Unit Price");
        CRMProductpricelevel.SetRange(ProductId, CRMProduct[2].ProductId);
        Assert.IsTrue(CRMProductpricelevel.FindFirst(), 'Missing second price list line.');
        CRMProductpricelevel.TestField(Amount, PriceListLine[2]."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncModifiedSalesPriceIfCustPriceGroupIsNotCoupled()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        SalesPrice: Record "Sales Price";
        CRMProduct: Record "CRM Product";
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Synchronization of "Sales Price" should fail if the parent "Customer Price Group" is not coupled
        SalesPrice.DeleteAll();
        Init();
        // [GIVEN] The Customer Price Group 'A' is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);
        // [GIVEN] Added one Sales Price line to 'A'
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', '', 0, LibraryRandom.RandDecInRange(10, 100, 2));
        // [GIVEN] The Customer Price Group 'A' is decoupled
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        CRMIntegrationRecord.Delete();

        // [WHEN] "Synchronize Modified Recrods" on "SALESPRC-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Sales Price");
        // [WHEN] The scheduled jobs is finished
        SimulateIntegrationSyncJobExecution(DATABASE::"Sales Price");

        // [THEN] Synchronization has failed with the error message: "Cannot find the coupled price list."
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.IsTrue(IntegrationSynchJob.FindLast(), 'No IntegrationSynchJob for ' + IntegrationTableMappingName);
        IntegrationSynchJob.TestField(Failed, 1);
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", IntegrationSynchJob.ID);
        IntegrationSynchJobErrors.FindFirst();
        Assert.ExpectedMessage(
          StrSubstNo(SalesCodeMustBeCoupledErr, CustomerPriceGroup.Code, CRMProductName.CDSServiceName()), IntegrationSynchJobErrors.Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncModifiedPriceListLineIfPriceListHeaderIsNotCoupled()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        Item: Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        CRMProduct: Record "CRM Product";
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Synchronization of "Price List Line" should fail if the parent "Price List Header" is not coupled
        PriceListLine.DeleteAll();
        Init(true, false);
        // [GIVEN] The Price List Header for 'All Customers' is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledPriceListHeaderAndPricelevel(PriceListHeader, CRMPricelevel);

        // [GIVEN] Added one PriceListLine line to 'A'
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source type"::"All Customers", '',
            "Price Asset Type"::Item, Item."No.");
        // [GIVEN] The Price List Header is decoupled
        CRMIntegrationRecord.FindByRecordID(PriceListHeader.RecordId);
        CRMIntegrationRecord.Delete();

        // [WHEN] "Synchronize Modified Recrods" on "PLLINE-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Price List Line");
        // [WHEN] The scheduled jobs is finished
        SimulateIntegrationSyncJobExecution(DATABASE::"Price List Line");

        // [THEN] Synchronization has failed with the error message: "Cannot find the coupled price list."
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.IsTrue(IntegrationSynchJob.FindLast(), 'No IntegrationSynchJob for ' + IntegrationTableMappingName);
        IntegrationSynchJob.TestField(Failed, 1);
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", IntegrationSynchJob.ID);
        IntegrationSynchJobErrors.FindFirst();
        Assert.ExpectedMessage(
            StrSubstNo(PriceListMustBeCoupledErr, PriceListHeader.Code, CRMProductName.CDSServiceName()), IntegrationSynchJobErrors.Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncDuplicateSalesPriceShouldCoupleRecords()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        IntegrationSynchJob: Record "Integration Synch. Job";
        SalesPrice: Record "Sales Price";
        CRMProduct: Record "CRM Product";
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Synchronization of "Sales Price" that has a duplicate CRM Price List line should couple them.
        Init();
        // [GIVEN] The Customer Price Group 'A' is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);
        // [GIVEN] CRMPricelevel has a line 'B', where 'Item No.' = '1001', "Unit Of Measure" = 'PCS', Amount = 100.00
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibraryCRMIntegration.CreateCRMPricelistLine(CRMProductpricelevel, CRMPricelevel, CRMProduct);
        // [GIVEN] Added Sales Price line 'C' for 'A', where 'Item No.' = '1001', "Unit Of Measure" = 'PCS', "Unit Price" = 150.00
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', Item."Base Unit of Measure", 0, LibraryRandom.RandDecInRange(10, 100, 2));

        // [WHEN] "Synchronize Modified Recrods" on "SALESPRC-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Sales Price");
        // [WHEN] The scheduled jobs is finished
        SimulateIntegrationSyncJobExecution(DATABASE::"Sales Price");

        // [THEN] Sales Price "C" is coupled to CRMPricelevel line "B"
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(SalesPrice.RecordId), 'the new sales price is not coupled');
        Assert.AreEqual(
          CRMProductpricelevel.ProductPriceLevelId, CRMIntegrationRecord."CRM ID", 'the sales price is coupled to a wrong line');
        // [THEN] Synchronization has completed, where "Modified" = 1
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.IsTrue(IntegrationSynchJob.FindLast(), 'No IntegrationSynchJob for ' + IntegrationTableMappingName);
        IntegrationSynchJob.TestField(Modified, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncDuplicatePriceListLineShouldCoupleRecords()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        Item: Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        CRMProduct: Record "CRM Product";
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Synchronization of "Price List Line" that has a duplicate CRM Price List line should couple them.
        Init(true, false);
        // [GIVEN] The PriceListHeader is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledPriceListHeaderAndPricelevel(PriceListHeader, CRMPricelevel);
        // [GIVEN] CRMPricelevel has a line 'B', where 'Item No.' = '1001', "Unit Of Measure" = 'PCS', Amount = 100.00
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibraryCRMIntegration.CreateCRMPricelistLine(CRMProductpricelevel, CRMPricelevel, CRMProduct);
        // [GIVEN] Added Price List Line line 'C' for 'A', where 'Item No.' = '1001', "Unit Of Measure" = 'PCS', "Unit Price" = 150.00
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");

        // [WHEN] "Synchronize Modified Recrods" on "SALESPRC-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Price List Line");
        // [WHEN] The scheduled jobs is finished
        SimulateIntegrationSyncJobExecution(DATABASE::"Price List Line");

        // [THEN] Price List Line "C" is coupled to CRMPricelevel line "B"
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(PriceListLine.RecordId), 'the new Price List Line is not coupled');
        Assert.AreEqual(
          CRMProductpricelevel.ProductPriceLevelId, CRMIntegrationRecord."CRM ID", 'the Price List Line is coupled to a wrong line');
        // [THEN] Synchronization has completed, where "Modified" = 1
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.IsTrue(IntegrationSynchJob.FindLast(), 'No IntegrationSynchJob for ' + IntegrationTableMappingName);
        IntegrationSynchJob.TestField(Modified, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncPriceListForDecoupledItemShouldFail()
    var
        CRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: array[2] of Record "CRM Productpricelevel";
        Item: array[2] of Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        SalesPrice: array[2] of Record "Sales Price";
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Synchronization of "Sales Price", where Item is decoupled, should fail.
        SalesPrice[1].DeleteAll();
        Init();

        // [GIVEN] The Customer Price Group 'A' is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);
        // [GIVEN] One price line is coupled
        LibraryCRMIntegration.CreateCoupledSalesPriceAndPricelistLine(CustomerPriceGroup, SalesPrice[1], CRMProductpricelevel[1]);
        // [GIVEN] Second price line coupled and
        LibraryCRMIntegration.CreateCoupledSalesPriceAndPricelistLine(CustomerPriceGroup, SalesPrice[2], CRMProductpricelevel[2]);
        // [GIVEN] Item '1' is coupled
        Item[1].Get(SalesPrice[1]."Item No.");
        Assert.IsTrue(CRMIntegrationRecord[1].FindByRecordID(Item[1].RecordId), 'Item is not coupled.');
        // [GIVEN] Item '2' is decoupled
        Item[2].Get(SalesPrice[2]."Item No.");
        Assert.IsTrue(CRMIntegrationRecord[2].FindByRecordID(Item[2].RecordId), 'Item is not coupled.');
        CRMIntegrationRecord[2].Delete();

        // [WHEN] "Synchronize Modified Records" on "SALESPRC-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Sales Price");
        // [WHEN] The scheduled jobs is finished
        SimulateIntegrationSyncJobExecution(DATABASE::"Sales Price");

        // [THEN] Synchronization has completed, where "Failed" = 2
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.IsTrue(IntegrationSynchJob.FindLast(), 'No IntegrationSynchJob for ' + IntegrationTableMappingName);
        IntegrationSynchJob.TestField(Failed, 1);
        // [THEN] Second line failed with error "Item '2' is not coupled."
        IntegrationSynchJobErrors.SetRange("Source Record ID", SalesPrice[2].RecordId);
        IntegrationSynchJobErrors.FindFirst();
        Assert.ExpectedMessage(
          StrSubstNo(ItemMustBeCoupledErr, SalesPrice[2].FieldCaption("Item No."), SalesPrice[2]."Item No.", CRMProductName.CDSServiceName()), IntegrationSynchJobErrors.Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SyncPriceListLineForDecoupledItemShouldFail()
    var
        CRMIntegrationRecord: array[2] of Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductpricelevel: array[2] of Record "CRM Productpricelevel";
        Item: array[2] of Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        IntegrationTableMappingName: Code[20];
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Synchronization of "Price List Line", where Item is decoupled, should fail.
        PriceListLine[1].DeleteAll();
        Init(true, false);

        // [GIVEN] The PriceListHeader is coupled and synched with CRM
        LibraryCRMIntegration.CreateCoupledPriceListHeaderAndPricelevel(PriceListHeader, CRMPricelevel);
        // [GIVEN] One price line is coupled
        LibraryCRMIntegration.CreateCoupledPriceListLineAndCRMPricelistLine(PriceListHeader, PriceListLine[1], CRMProductpricelevel[1]);
        // [GIVEN] Second price line coupled and
        LibraryCRMIntegration.CreateCoupledPriceListLineAndCRMPricelistLine(PriceListHeader, PriceListLine[2], CRMProductpricelevel[2]);
        // [GIVEN] Item '1' is coupled
        Item[1].Get(PriceListLine[1]."Asset No.");
        Assert.IsTrue(CRMIntegrationRecord[1].FindByRecordID(Item[1].RecordId), 'Item1 is not coupled.');
        // [GIVEN] Item '2' is decoupled
        Item[2].Get(PriceListLine[2]."Asset No.");
        Assert.IsTrue(CRMIntegrationRecord[2].FindByRecordID(Item[2].RecordId), 'Item2 is not coupled.');
        CRMIntegrationRecord[2].Delete();

        // [WHEN] "Synchronize Modified Records" on "PLLINE-PRODPRICE" mapping
        IntegrationTableMappingName := LibraryCRMIntegration.SynchronizeNowForTable(DATABASE::"Price List Line");
        // [WHEN] The scheduled jobs is finished
        SimulateIntegrationSyncJobExecution(DATABASE::"Price List Line");

        // [THEN] Synchronization has completed, where "Failed" = 2
        IntegrationSynchJob.SetCurrentKey("Start Date/Time", ID);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        Assert.IsTrue(IntegrationSynchJob.FindLast(), 'No IntegrationSynchJob for ' + IntegrationTableMappingName);
        IntegrationSynchJob.TestField(Failed, 1);
        // [THEN] Second line failed with error "Item '2' is not coupled."
        IntegrationSynchJobErrors.SetRange("Source Record ID", PriceListLine[2].RecordId);
        IntegrationSynchJobErrors.FindFirst();
        Assert.ExpectedMessage(
          StrSubstNo(ItemMustBeCoupledErr, PriceListLine[2].FieldCaption("Asset No."), PriceListLine[2]."Asset No.", CRMProductName.CDSServiceName()), IntegrationSynchJobErrors.Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSetupDefaultMakesCustomerCountryCodeMappingDirectionBidirectional()
    var
        RefCustomer: Record Customer;
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 223988] CRM Setup Defaults makes direction=Bidirectional for Customer.Country\Region Code field mapping
        Init();

        // [WHEN] CRM Setup Defaults is being run
        ResetDefaultCRMSetupConfiguration();

        // [THEN] Customer.Country\Region Code field mapping direction=Bidirectional
        FindIntegrationFieldMapping(DATABASE::Customer, RefCustomer.FieldNo("Country/Region Code"), IntegrationFieldMapping);
        IntegrationFieldMapping.TestField(Direction, IntegrationFieldMapping.Direction::Bidirectional);
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleRecordStrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SyncItemUnitPriceIfCustPriceGroupExists()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesPrice: Record "Sales Price";
        CRMProduct: Record "CRM Product";
        IntegrationTableMapping: array[2] of Record "Integration Table Mapping";
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Changed "Unit Price" on the Item with defined Customer Price Group should not update the coupled Product Price Level.
        Init();
        SynchDirection := SynchDirection::ToCRM;

        // [GIVEN] Customer Price Group.
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        GetIntegrationTableMapping(IntegrationTableMapping[1], CustomerPriceGroup.RecordId);

        // [GIVEN] Item coupled with CRM Product.
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        GetIntegrationTableMapping(IntegrationTableMapping[2], Item.RecordId);

        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        // [GIVEN] Sales Price for the Item and the Customer Price Group.
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', '', 0, LibraryRandom.RandDec(100, 2));

        // [GIVEN] Customer Price Group is coupled with CRM Price Level and synched.
        LibraryCRMIntegration.CreatePricelevelAndCoupleWithPriceGroup(CustomerPriceGroup, CRMPricelevel, SalesPrice."Currency Code");
        CRMIntegrationManagement.UpdateOneNow(CustomerPriceGroup.RecordId);

        CustomerPriceGroup.SetRange(SystemId, CustomerPriceGroup.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::"Customer Price Group", CustomerPriceGroup.GetView(), IntegrationTableMapping[1]);

        // [GIVEN] Item Unit Price is set.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        // [WHEN] Item is synched with CRM.
        CRMIntegrationManagement.UpdateOneNow(Item.RecordId);

        Item.SetRange(SystemId, Item.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Item, Item.GetView(), IntegrationTableMapping[2]);

        // [THEN] Product Price Level for the Customer Price Group exist and its Amount is unchanged.
        CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        VerifyCRMProductPriceLevelAmount(CRMProduct.ProductId, CRMPricelevel.PriceLevelId, SalesPrice."Unit Price");
    end;

    [Test]
    [HandlerFunctions('TestSyncSingleRecordStrMenuHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SyncItemUnitPriceIfPriceListHeaderExists()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        CRMProduct: Record "CRM Product";
        IntegrationTableMapping: array[2] of Record "Integration Table Mapping";
    begin
        // [FEATURE] [Price List]
        // [SCENARIO] Changed "Unit Price" on the Item with defined Price List Header should not update the coupled Product Price Level.
        Init(true, false);
        SynchDirection := SynchDirection::ToCRM;

        // [GIVEN] PriceListHeader for 'All Customers'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        GetIntegrationTableMapping(IntegrationTableMapping[2], PriceListHeader.RecordId);

        // [GIVEN] Item coupled with CRM Product.
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        GetIntegrationTableMapping(IntegrationTableMapping[2], Item.RecordId);

        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        // [GIVEN] PriceListLine for the Item and the 'All Customers'.
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");

        // [GIVEN] Customer Price Group is coupled with CRM Price Level and synched.
        LibraryCRMIntegration.CreatePricelevelAndCoupleWithPriceListHeader(
            PriceListHeader, CRMPricelevel, PriceListHeader."Currency Code");
        CRMIntegrationManagement.UpdateOneNow(PriceListHeader.RecordId);

        PriceListHeader.SetRange(SystemId, PriceListHeader.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Price List Header", PriceListHeader.GetView(), IntegrationTableMapping[1]);

        // [GIVEN] Item Unit Price is set.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);

        // [WHEN] Item is synched with CRM.
        CRMIntegrationManagement.UpdateOneNow(Item.RecordId);

        Item.SetRange(SystemId, Item.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Item, Item.GetView(), IntegrationTableMapping[2]);

        // [THEN] Product Price Level for the PriceListHeader exist and its Amount is unchanged.
        CRMIntegrationRecord.FindByRecordID(PriceListHeader.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        VerifyCRMProductPriceLevelAmount(CRMProduct.ProductId, CRMPricelevel.PriceLevelId, PriceListLine."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitTableFilterUnexpectedChar()
    var
        TempItem: Record Item temporary;
        FieldNo: Integer;
        TableFilterList: List of [Text];
    begin
        FieldNo := TempItem.FieldNo(SystemId);
        Assert.IsFalse(IntegrationRecordSynch.SplitTableFilter(Database::Item, FieldNo,
            'VERSION(1) SORTING(Field1) WHERE(Field' + Format(FieldNo) + '=FILTER(' + CreateGuid() + '&' + CreateGuid() + '))',
            TableFilterList), 'SplitTableFilter should return false.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitTableFilterNothingToSplit()
    var
        TempItem: Record Item temporary;
        FieldNo: Integer;
        FieldFilter: Text;
        TableFilterList: List of [Text];
        I: Integer;
        N: Integer;
    begin
        N := IntegrationRecordSynch.GetMaxNumberOfConditions();
        for I := 1 to N do
            FieldFilter += '|' + Format(CreateGuid());
        FieldFilter := FieldFilter.TrimStart('|');
        FieldNo := TempItem.FieldNo(SystemId);
        Assert.IsTrue(IntegrationRecordSynch.SplitTableFilter(Database::Item, FieldNo,
            'VERSION(1) SORTING(Field1) WHERE(Field' + Format(FieldNo) + '=FILTER(' + FieldFilter + '))', TableFilterList),
            'SplitTableFilter should return true.');
        Assert.AreEqual(1, TableFilterList.Count(), 'SplitTableFilter should return 1 filter in the list.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitTableFilterIntoChunks()
    var
        TempItem: Record Item temporary;
        FieldNo: Integer;
        FieldFilter: Text;
        TableFilterList: List of [Text];
        I: Integer;
        N: Integer;
    begin
        N := 3 * IntegrationRecordSynch.GetMaxNumberOfConditions();
        for I := 1 to N do
            FieldFilter += '|' + Format(CreateGuid());
        FieldFilter := FieldFilter.TrimStart('|');
        FieldNo := TempItem.FieldNo(SystemId);
        Assert.IsTrue(IntegrationRecordSynch.SplitTableFilter(Database::Item, FieldNo,
            'VERSION(1) SORTING(Field1) WHERE(Field' + Format(FieldNo) + '=FILTER(' + FieldFilter + '))', TableFilterList),
            'SplitTableFilter should return true.');
        Assert.AreEqual(3, TableFilterList.Count(), 'SplitTableFilter should return 3 filters in the list.');
    end;

    local procedure Init()
    begin
        Init(false, false);
    end;

    local procedure Init(EnableExtendedPrice: Boolean; EnableUnitGroupMapping: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        MyNotifications: Record "My Notifications";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
    begin
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        if EnableExtendedPrice then
            LibraryPriceCalculation.EnableExtendedPriceCalculation();

        UnBindSubscription(IntTableSynchSubscriber);
        LibraryCRMIntegration.SetCRMTimeDiff(0);
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMConnectionSetup.Get();
        CRMConnectionSetup.RefreshDataFromCRM();
        CRMConnectionSetup."Unit Group Mapping Enabled" := EnableUnitGroupMapping;
        CRMConnectionSetup.Modify();
        ResetDefaultCRMSetupConfiguration();
        LibraryTemplates.EnableTemplatesFeature();

        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID(), '', '', false);
    end;

    local procedure CreateCoupledContactsWithParentCustomerAndAccount(var Contact: Record Contact; var CRMContact: Record "CRM Contact"; var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CompanyContact: Record Contact;
        CRMIntegrationRecord: Record "CRM Integration Record";
        CustomerNo: Code[20];
    begin
        LibraryMarketing.CreatePersonContactWithCompanyNo(Contact);
        CompanyContact.Get(Contact."Company No.");
        CompanyContact.SetHideValidationDialog(true);
        CustomerNo := CompanyContact.CreateCustomerFromTemplate('');
        Customer.Get(CustomerNo);
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Customer.RecordId(), CRMAccount.AccountId);
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Contact.RecordId(), CRMContact.ContactId);

        CRMIntegrationRecord.FindByCRMID(CRMAccount.OwnerId);
        SalespersonPurchaser.GetBySystemId(CRMIntegrationRecord."Integration ID");

        Customer.GetBySystemId(Customer.SystemId);
        Customer.Name := 'A';
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();

        Contact.GetBySystemId(Contact.SystemId);
        Contact.Surname := 'A';
        Contact."Salesperson Code" := SalespersonPurchaser.Code;
        Contact.Modify();

        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.Name := 'B';
        CRMAccount.Modify(true);

        CRMContact.Get(CRMContact.ContactId);
        CRMContact.LastName := 'B';
        CRMContact.OwnerId := CRMAccount.OwnerId;
        CRMContact.OwnerIdType := CRMAccount.OwnerIdType;
        CRMContact.Modify(true);

        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        CRMIntegrationRecord."Last Synch. CRM Modified On" := CRMAccount.ModifiedOn;
        CRMIntegrationRecord."Last Synch. Modified On" := Customer.SystemModifiedAt;
        CRMIntegrationRecord.Modify();

        CRMIntegrationRecord.FindByCRMID(CRMContact.ContactId);
        CRMIntegrationRecord."Last Synch. CRM Modified On" := CRMContact.ModifiedOn;
        CRMIntegrationRecord."Last Synch. Modified On" := Contact.SystemModifiedAt;
        CRMIntegrationRecord.Modify();
    end;

    local procedure AssertAreEqual(DateTimeA: DateTime; DateTimeB: DateTime; Context: Text)
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeA, DateTimeB) = 0,
            StrSubstNo('%1. Expected: %2. Actual: %3.', Context, DateTimeToString(DateTimeA), DateTimeToString(DateTimeB)));
    end;

    local procedure AssertAreNotEqual(DateTimeA: DateTime; DateTimeB: DateTime; Context: Text)
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.IsFalse(TypeHelper.CompareDateTime(DateTimeA, DateTimeB) = 0,
            StrSubstNo('%1. Expected: %2. Actual: %3.', Context, DateTimeToString(DateTimeA), DateTimeToString(DateTimeB)));
    end;

    local procedure DateTimeToString(Value: DateTime): Text
    begin
        exit(Format(Value, 0, '<Year4>-<Month,2>-<Day,2> <Hours24>:<Minutes,2>:<Seconds,2><Second dec.><Comma,.>'));
    end;

    local procedure FindIntegrationFieldMapping(TableID: Integer; FieldID: Integer; var IntegrationFieldMapping: Record "Integration Field Mapping")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, TableID);
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange("Field No.", FieldID);
        IntegrationFieldMapping.FindFirst();
    end;

    local procedure GetIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; RecordId: RecordId)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.GetIntegrationTableMapping(IntegrationTableMapping, RecordId);
        IntegrationTableMapping.Reset();
    end;

    local procedure GetIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; TableNo: Integer)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.GetIntegrationTableMapping(IntegrationTableMapping, TableNo);
        IntegrationTableMapping.Reset();
    end;

    local procedure MockCRMIntegrationRecordsLastSync(RecID: RecordID; NewDateTime: DateTime)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(RecID), 'Source record is not coupled.');
        CRMIntegrationRecord."Last Synch. Modified On" := NewDateTime;
        CRMIntegrationRecord.Modify();
    end;

    local procedure SetLastSyncDateBackOneDayCRM(CRMID: Guid)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.SetRange("CRM ID", CRMID);
        CRMIntegrationRecord.FindFirst();
        CRMIntegrationRecord."Last Synch. Modified On" := OneDayBefore(CRMIntegrationRecord."Last Synch. Modified On");
        CRMIntegrationRecord.Modify();
    end;

    local procedure SetupCoupledCustomer(var IntegrationTableMapping: Record "Integration Table Mapping"; var Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        LibraryCRMIntegration.CreateIntegrationTableMappingCustomer(IntegrationTableMapping);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
    end;

    local procedure SetCRMIntegrationSyncOneDayBack(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMAccount: Record "CRM Account"; CustomerID: RecordID): DateTime
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerID);
        CRMIntegrationRecord.Get(CRMAccount.AccountId, Customer.SystemId);
        CRMAccount.Find(); // get latest version after sync

        CRMIntegrationRecord."Last Synch. Modified On" := OneDayBefore(CRMIntegrationRecord."Last Synch. Modified On");
        CRMIntegrationRecord.Modify();
        CRMAccount.ModifiedOn := OneDayBefore(CRMAccount.ModifiedOn);
        CRMAccount.Modify();
        exit(CRMIntegrationRecord."Last Synch. Modified On");
    end;

    local procedure SetCRMIntegrationSyncInConflict(var CRMIntegrationRecord: Record "CRM Integration Record"; var CRMAccount: Record "CRM Account"; CustomerID: RecordID)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerID);
        CRMIntegrationRecord.Get(CRMAccount.AccountId, Customer.SystemId);
        CRMAccount.Find();

        CRMAccount.ModifiedOn := OneDayBefore(CRMAccount.ModifiedOn);
        CRMAccount.Modify();
        CRMIntegrationRecord."Last Synch. CRM Modified On" := OneDayBefore(CRMAccount.ModifiedOn);
        CRMIntegrationRecord.Modify();
    end;

    local procedure VerifyCRMProductPriceLevelAmount(CRMProductId: Guid; CRMPriceLevelId: Guid; ExpectedAmount: Decimal)
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
    begin
        CRMProductpricelevel.SetRange(ProductId, CRMProductId);
        CRMProductpricelevel.SetRange(PriceLevelId, CRMPriceLevelId);
        CRMProductpricelevel.FindFirst();
        CRMProductpricelevel.TestField(Amount, ExpectedAmount);
    end;

    local procedure OneDayBefore(DateTime: DateTime): DateTime
    begin
        exit(CreateDateTime(CalcDate('<-1D>', DT2Date(DateTime)), DT2Time(DateTime)));
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

    local procedure VerifyIntegrationSynchJob(IntegrationTableMappingName: Code[20]; Direction: Option; Inserted: Integer; Modified: Integer; Deleted: Integer; Unchanged: Integer; Skipped: Integer; Failed: Integer; Context: Text)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationSynchJob.SetRange("Synch. Direction", Direction);
        IntegrationSynchJob.SetCurrentKey(SystemModifiedAt);
        IntegrationSynchJob.FindLast();
        Assert.AreEqual(Inserted, IntegrationSynchJob.Inserted, StrSubstNo('%1. Inserted', Context));
        Assert.AreEqual(Modified, IntegrationSynchJob.Modified, StrSubstNo('%1. Modified', Context));
        Assert.AreEqual(Deleted, IntegrationSynchJob.Deleted, StrSubstNo('%1. Deleted', Context));
        Assert.AreEqual(Unchanged, IntegrationSynchJob.Unchanged, StrSubstNo('%1. Unchanged', Context));
        Assert.AreEqual(Skipped, IntegrationSynchJob.Skipped, StrSubstNo('%1. Skipped', Context));
        Assert.AreEqual(Failed, IntegrationSynchJob.Failed, StrSubstNo('%1. Failed', Context));
    end;

    local procedure VerifyIntegrationSynchJob(IntegrationTableMappingName: Code[20]; Modified: Integer; Unchanged: Integer)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", IntegrationTableMappingName);
        IntegrationSynchJob.FindFirst();
        IntegrationSynchJob.TestField(Modified, Modified);
        IntegrationSynchJob.TestField(Unchanged, Unchanged);
    end;

    local procedure SimulateIntegrationSyncJobExecution(TableNo: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        IntegrationTableMapping.SetRange("Table ID", TableNo);
        IntegrationTableMapping.FindFirst();
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
        JobQueueEntry.FindFirst();
        Codeunit.Run(Codeunit::"Integration Synch. Job Runner", JobQueueEntry);
    end;

    local procedure CoupleOption(RecId: RecordId; OptionValue: Integer; OptionValueCaption: Text[250]; TableId: Integer; IntegrationTableId: Integer; IntegrationFieldId: Integer)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        CRMOptionMapping."Record ID" := RecId;
        CRMOptionMapping."Option Value" := OptionValue;
        CRMOptionMapping."Option Value Caption" := OptionValueCaption;
        CRMOptionMapping."Table ID" := TableId;
        CRMOptionMapping."Integration Table ID" := IntegrationTableId;
        CRMOptionMapping."Integration Field ID" := IntegrationFieldId;
        if CRMOptionMapping.Insert() then;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(SyncStartedMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure MultipleSyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(MultipleSyncStartedMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}