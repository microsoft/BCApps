codeunit 139182 "CRM Coupling Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration]
    end;

    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProductName: Codeunit "CRM Product Name";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        Assert: Codeunit Assert;
        LibraryTemplates: Codeunit "Library - Templates";
        SyncAction: Option DoNotSynch,PushToCRM,PushToNAV;
        BaseUoMErr: Label 'Base Unit of Measure must have a value in %1';
        SyncStartedMsg: Label 'The synchronization has been scheduled.';
        UoMErr: Label 'Item has wrong Base Unit of Measure.';
        CurrencyExchangeRateMissingErr: Label 'Cannot create or update the currency %1 in %2, because there is no exchange rate defined for it.', Comment = '%1 - currency code, %2 - CRM product name';

    [Test]
    //Reenabled in https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/368425
    [HandlerFunctions('SetCouplingRecordPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleSalesperson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalespersonPurchaserCard: TestPage "Salesperson/Purchaser Card";
        CRMID: Guid;
        JobQueueEntryID: Guid;
        ExpectedCRMName: Text;
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO] Coupling a Salesperson to a CRM Systemuser
        TestInit();

        // [GIVEN] A Salesperson and CRM Systemuser with different data
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser);
        ExpectedCRMName := CRMSystemuser.FullName;

        // [GIVEN] The Salesperson Card page
        SalespersonPurchaserCard.OpenView();
        SalespersonPurchaserCard.GotoRecord(SalespersonPurchaser);

        // [WHEN] Invoking the Set Up Coupling action
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(ExpectedCRMName);
        SalespersonPurchaserCard.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Salesperson to the CRM Systemuser with synch (from CRM)
        // This is done in SetCouplingRecordPageHandler
        CRMSystemuser.SetRange(SystemUserId, CRMSystemuser.SystemUserId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Systemuser", CRMSystemuser.GetView(), IntegrationTableMapping);

        // [THEN] The Salesperson and CRM Systemuser are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(SalespersonPurchaser.RecordId),
          'The Salesperson must be coupled');
        CRMIntegrationRecord.FindIDFromRecordID(SalespersonPurchaser.RecordId, CRMID);
        Assert.AreEqual(CRMSystemuser.SystemUserId, CRMID,
          'The Salesperson must be coupled to the correct CRM Systemuser');

        // [THEN] The Salesperson data was overwritten with the CRM Systemuser data
        SalespersonPurchaser.Find();
        CRMSystemuser.Find();
        Assert.AreEqual(ExpectedCRMName, CRMSystemuser.FullName,
          'The CRM Systemuser must have the same name as it had before syncing after syncing');
        Assert.AreEqual(CRMSystemuser.FullName, SalespersonPurchaser.Name,
          'The Salesperson must have the same name as the CRM Systemuser after syncing');
    end;

    [Test]
    [HandlerFunctions('SetCouplingRecordPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleCustomer()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CustomerCard: TestPage "Customer Card";
        CRMID: Guid;
        JobQueueEntryID: Guid;
        OriginalCustomerName: Text;
    begin
        // [FEATURE] [UI] [Customer]
        // [SCENARIO] Coupling a Customer to a CRM Account
        TestInit();

        // [GIVEN] A Customer and a CRM Account with different data
        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        LibraryCRMIntegration.CouplePaymentTerms(Customer);
        OriginalCustomerName := Customer.Name;

        // [GIVEN] The Mini Customer Card page
        CustomerCard.OpenView();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Invoking the Set Up Coupling action
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(CRMAccount.Name);
        CustomerCard.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Customer to the CRM Account with synch from NAV
        // This is done in SetCouplingRecordPageHandler
        Customer.SetRange(SystemId, Customer.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);

        // [THEN] The Customer and CRM Account are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(Customer.RecordId),
          'The Customer must be coupled');
        CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId, CRMID);
        Assert.AreEqual(CRMAccount.AccountId, CRMID,
          'The Customer must be coupled to the correct CRM Account');

        // [THEN] The CRM Account data was overwritten with the Customer data
        CRMAccount.Find();
        Customer.Find();
        Assert.AreEqual(OriginalCustomerName, Customer.Name,
          'The Customer must have the same name as it had before syncing');
        Assert.AreEqual(Customer.Name, CRMAccount.Name,
          'The CRM Account must have the same name as the Customer after syncing');
    end;

    [Test]
    [HandlerFunctions('DoNotSyncCouplingRecordPageHandler')]
    [Scope('OnPrem')]
    procedure CoupleContact()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMAccount: Record "CRM Account";
        ContactList: TestPage "Contact List";
        CRMID: Guid;
        OriginalContactName: Text;
        OriginalCRMContactName: Text;
    begin
        // [FEATURE] [UI] [Contact]
        // [SCENARIO] Coupling a Contact to a CRM Contact
        TestInit();

        // [GIVEN] A Person type Contact and a CRM Contact with different data
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Type := Contact.Type::Person;
        Contact.Modify();
        CreateCRMAccountCoupledToCustomerWithContact(CRMAccount);
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);
        OriginalContactName := Contact.Name;
        OriginalCRMContactName := CRMContact.FullName;
        Assert.AreNotEqual(OriginalContactName, OriginalCRMContactName,
          'Please make sure the library functions creating Contacts and CRM Contacts generate unique names');

        // [GIVEN] The Contact List page
        ContactList.OpenView();
        ContactList.GotoRecord(Contact);

        // [WHEN] Invoking the Set Up Coupling action
        LibraryVariableStorage.Enqueue(OriginalCRMContactName);
        ContactList.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Contact to the CRM Contact without synch
        // This is done in DoNotSyncCouplingRecordPageHandler

        // [THEN] The Contact and CRM Contact are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(Contact.RecordId),
          'The Contact must be coupled');
        CRMIntegrationRecord.FindIDFromRecordID(Contact.RecordId, CRMID);
        Assert.AreEqual(CRMContact.ContactId, CRMID,
          'The Contact must be coupled to the correct CRM Contact');

        // [THEN] The Contact and CRM Contact still contain their original data
        Contact.Find();
        CRMContact.Find();
        Assert.AreEqual(OriginalCRMContactName, CRMContact.FullName,
          'The CRM Contact name should still be the original name');
        Assert.AreEqual(OriginalContactName, Contact.Name,
          'The Contact name should still be the original name');
    end;

    [Test]
    [HandlerFunctions('CRMAccountListModalHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromCRM()
    var
        CRMAccount: Record "CRM Account";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CustomerListPage: TestPage "Customer List";
        CustomerRecID: RecordID;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Customer]
        // [SCENARIO] Create new Customer from CRM Account list page
        TestInit();
        // [GIVEN] new CRM Account
        CRMAccount.DeleteAll();
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);

        // [WHEN] Run "Create Customer from CRM" action on "Customer List" page
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CustomerListPage.OpenView();
        LibraryVariableStorage.Enqueue(CRMAccount.Name);
        CustomerListPage.CreateFromCRM.Invoke();
        // handled by CRMAccountListModalHandler
        CRMAccount.SetRange(AccountId, CRMAccount.AccountId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Account", CRMAccount.GetView(), IntegrationTableMapping);

        // [THEN] CRM Account is coupled to a Customer
        Assert.IsTrue(
          CRMIntegrationRecord.FindRecordIDFromID(CRMAccount.AccountId, DATABASE::Customer, CustomerRecID),
          'CRM Account should be coupled.');
        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('CRMContactListModalHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateContactFromCRM()
    var
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        ContactListPage: TestPage "Contact List";
        ContactRecID: RecordID;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Contact]
        // [SCENARIO] Create new Contact from CRM Contact list page
        TestInit();
        // [GIVEN] CRM Account 'A', coupled to a Customer that has link to a Company Contact
        CreateCRMAccountCoupledToCustomerWithContact(CRMAccount);

        // [GIVEN] new CRM Contact, where Parent Company is 'A'
        CRMContact.DeleteAll();
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);
        CRMContact.TestField(ParentCustomerIdType, CRMContact.ParentCustomerIdType::account);

        // [WHEN] Run "Create Contact from CRM" action on "Contact List" page
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        ContactListPage.OpenView();
        LibraryVariableStorage.Enqueue(CRMContact.EMailAddress1);
        ContactListPage.CreateFromCRM.Invoke();
        // handled by CRMContactListModalHandler
        CRMContact.SetRange(ContactId, CRMContact.ContactId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"CRM Contact", CRMContact.GetView(), IntegrationTableMapping);

        // [THEN] CRM Contact is coupled to a Contact
        Assert.IsTrue(
          CRMIntegrationRecord.FindRecordIDFromID(CRMContact.ContactId, DATABASE::Contact, ContactRecID),
          'CRM Contact should be coupled.');
        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DoNotSyncCouplingRecordPageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.CRMName.SetValue(LibraryVariableStorage.DequeueText());
        CRMCouplingRecord.SyncActionControl.SetValue(SyncAction::DoNotSynch);
        CRMCouplingRecord.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleCurrency()
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CurrencyCard: TestPage "Currency Card";
        JobQueueEntryID: Guid;
        OriginalNumberOfCRMTransactioncurrencies: Integer;
        CRMID: Guid;
        CurrencyCode: Text;
    begin
        // [FEATURE] [UI] [Currency]
        // [SCENARIO] Creating a CRM Transactioncurrency using a Currency and the CRM Coupling Currency page
        TestInit();
        EnableConnection();
        // Make sure the LCY is already present in CRM
        CRMSynchHelper.FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
        Clear(CRMTransactioncurrency);
        OriginalNumberOfCRMTransactioncurrencies := CRMTransactioncurrency.Count();

        // [GIVEN] A Currency with non-zero exchange rate
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        CurrencyCode := LibraryUtility.GenerateRandomCodeWithLength(Currency.FieldNo(Code), DATABASE::Currency, 5);
        Currency.Rename(CurrencyCode); // Renaming explicitly because CRM can't handle more than 5 chars

        // [GIVEN] The Currency Card page
        CurrencyCard.OpenView();
        CurrencyCard.GotoRecord(Currency);

        // [WHEN] Invoking the Synchronize Now action
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CurrencyCard.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Currency using Create New
        // This is done in CreateNewCouplingRecordPageHandler
        Currency.SetRange(SystemId, Currency.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::Currency, Currency.GetView(), IntegrationTableMapping);

        // [THEN] The Currency is coupled to a new CRM Transactioncurrency
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(Currency.RecordId),
          'The Currency must be coupled');
        Assert.AreEqual(OriginalNumberOfCRMTransactioncurrencies + 1, CRMTransactioncurrency.Count,
          'One new CRM Transactioncurrency should be created');

        // [THEN] The Currency and CRM Transactioncurrency contain the same data
        CRMIntegrationRecord.FindIDFromRecordID(Currency.RecordId, CRMID);
        CRMTransactioncurrency.Get(CRMID);
        Assert.IsTrue(Currency.Find(), 'The Currency was renamed');
        Assert.AreEqual(CurrencyCode, CRMTransactioncurrency.ISOCurrencyCode,
          'The CRM Transactioncurrency must have the same ISO currency code as the Currency');
        // [THEN] CurrencyPrecision is not zero
        CRMTransactioncurrency.TestField(CurrencyPrecision);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
        // [THEN] "My Notifications" part does not get new records
        Assert.TableIsEmpty(DATABASE::"Record Link");
        // [THEN] CRM Integration Record marked as "Success".
        CRMIntegrationRecord.FindByRecordID(Currency.RecordId);
        CRMIntegrationRecord.TestField(
          "Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Success);
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleCurrencyFailsIfNoExchangeRate()
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CurrencyCard: TestPage "Currency Card";
        OriginalNumberOfCRMTransactioncurrencies: Integer;
        CurrencyCode: Text;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Currency]
        // [SCENARIO] Creating a CRM Transactioncurrency using a Currency and the CRM Coupling Currency page should fail
        // [SCENARIO] if no exchange rate are defined
        TestInit();
        EnableConnection();
        // Make sure the LCY is already present in CRM
        CRMSynchHelper.FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
        Clear(CRMTransactioncurrency);
        OriginalNumberOfCRMTransactioncurrencies := CRMTransactioncurrency.Count();

        // [GIVEN] A Currency with zero exchange rate
        LibraryERM.CreateCurrency(Currency);
        CurrencyCode := LibraryUtility.GenerateRandomCodeWithLength(Currency.FieldNo(Code), DATABASE::Currency, 5);
        Currency.Rename(CurrencyCode); // Renaming explicitly because CRM can't handle more than 5 chars

        // [GIVEN] The Currency Card page
        CurrencyCard.OpenView();
        CurrencyCard.GotoRecord(Currency);

        // [WHEN] Invoking the Synchronize Now action
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CurrencyCard.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Currency using Create New
        // This is done in CreateNewCouplingRecordPageHandler
        Currency.SetRange(SystemId, Currency.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(DATABASE::Currency, Currency.GetView(), IntegrationTableMapping);

        // [THEN] The Currency is NOT coupled to a new CRM Transactioncurrency
        Assert.IsFalse(CRMIntegrationRecord.IsRecordCoupled(Currency.RecordId),
          'The Currency must not be coupled');
        Assert.AreEqual(OriginalNumberOfCRMTransactioncurrencies, CRMTransactioncurrency.Count,
          'No new CRM Transactioncurrency should be created');

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Failed" = 1, Error message is 'Exchange Rate must have a value'
        LibraryCRMIntegration.VerifySyncJobFailedOneRecord(
          JobQueueEntryID, IntegrationTableMapping, StrSubstNo(CurrencyExchangeRateMissingErr, Currency.Code, CRMProductName.CDSServiceName()));
        // [THEN] "My Notifications" part does not get new records
        Assert.TableIsEmpty(DATABASE::"Record Link");
        // [THEN] Job Queue Log Entry, where Status is "Success".
        JobQueueLogEntry.FindLast();
        JobQueueLogEntry.TestField(Status, JobQueueLogEntry.Status::Success);
    end;

    [Test]
    [HandlerFunctions('SetCouplingRecordPageHandler,SyncStartedNotificationHandler,CoupleYesConfirmHandler,TestCoupleItemHyperlinkHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleItem()
    var
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMUom: Record "CRM Uom";
        IntegrationTableMapping: Record "Integration Table Mapping";
        InStream: InStream;
        CRMID: Guid;
        JobQueueEntryID: Guid;
        TextContent: Text;
    begin
        // [FEATURE] [UI] [Item]
        // [SCENARIO] Coupling an Item to a CRM Product

        TestInit();

        // [GIVEN] An Item and a CRM Product with different data
        PrepareItemForCoupling(Item, Item."Replenishment System"::Assembly, CRMUom);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        LibraryCRMIntegration.CreateCRMProduct(CRMProduct, CRMTransactioncurrency, CRMUom);
        LibraryVariableStorage.Enqueue(CRMProduct.ProductNumber);

        // [GIVEN] Invoking the Go To CRM Product action in the Item List page
        // [WHEN] Coupling the Item to the CRM Product with synch from NAV
        // Happens in SetCouplingRecordPageHandler
        JobQueueEntryID := RunGoToProductActionOnItemList(Item, IntegrationTableMapping);

        // [THEN] The Item and CRM Product are coupled
        // [THEN] The CRM Product data was overwritten with the Item data
        // [THEN] The coupled CRM Product page opens in CRM
        // [THEN] Item "Description 2" value does not overwrite Product "Description"
        // This is handled in TestCoupleItemHyperlinkHandler
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(Item.RecordId),
          'The Item must be coupled');
        CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId, CRMID);
        Assert.AreEqual(CRMProduct.ProductId, CRMID,
          'The Item must be coupled to the correct CRM Product');

        CRMProduct.Find();
        Assert.AreEqual(Item."No.", CRMProduct.ProductNumber,
          'The CRM Product must have the same number as the Item after syncing');
        CRMProduct.CalcFields(Description);
        CRMProduct.Description.CreateInStream(InStream, TEXTENCODING::UTF16);
        InStream.Read(TextContent);
        Assert.AreEqual(
          '',
          TextContent,
          'CRM Product Description field should be empty');
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestCoupleItemToNewProduct()
    var
        CRMProduct: Record "CRM Product";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMId: Guid;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Item]
        // [SCENARIO] Coupling an Item to a new CRM Product
        TestInit();
        // [GIVEN] An Item, where "Unit Price" is 'X'
        PrepareItemForCoupling(Item, Item."Replenishment System"::Purchase, CRMUom);
        Item."Unit Price" := LibraryRandom.RandDec(100, 2);
        Item.Modify();

        // [WHEN] Couple to a new CRM Product
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(Item.RecordId);
        // JobQueueEntry is inserted and executed
        Item.SetRange(SystemId, Item.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(DATABASE::Item, Item.GetView(), IntegrationTableMapping);

        // [THEN] The Item and CRM Product are coupled
        Assert.IsTrue(CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId, CRMId), 'The Item should be coupled');
        // [THEN] The coupled CRM Product, where State is "Active", "PriceLevelID" is not blank
        CRMProduct.Get(CRMId);
        CRMProduct.TestField(StateCode, CRMProduct.StateCode::Active);
        CRMProduct.TestField(PriceLevelId);
        // [THEN] a Price list line related to the Item, where Amount = 'X'
        CRMProductpricelevel.SetRange(ProductId, CRMId);
        CRMProductpricelevel.SetRange(PriceLevelId, CRMProduct.PriceLevelId);
        CRMProductpricelevel.FindFirst();
        CRMProductpricelevel.TestField(Amount, CRMProduct.Price);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleItemWithBlankBaseUoM()
    var
        CRMUom: Record "CRM Uom";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Item] [Unit Of Measure]
        // [SCENARIO] An error should be thrown if coupling an Item, where "Base Unit Of Measure" is blank, to a CRM Product
        TestInit();

        // [GIVEN] An Item, where "Base Unit Of Measure" is blank
        PrepareItemForCoupling(Item, Item."Replenishment System"::Purchase, CRMUom);
        Item."Base Unit of Measure" := '';
        Item.Modify();

        // [WHEN] Couple to a new CRM Product
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(Item.RecordId);
        // JobQueueEntry is inserted and executed
        Item.SetRange(SystemId, Item.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(DATABASE::Item, Item.GetView(), IntegrationTableMapping);

        // [THEN] The Item and CRM Product are not coupled
        Assert.IsFalse(CRMIntegrationRecord.IsRecordCoupled(Item.RecordId), 'The Item should not be coupled');

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Failed" = 1, Error message is 'Base Unit Of Measure must have a value'
        LibraryCRMIntegration.VerifySyncJobFailedOneRecord(
          JobQueueEntryID, IntegrationTableMapping, StrSubstNo(BaseUoMErr, Item.TableName));
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordPageHandler,CoupleYesConfirmHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleAssemblyItem()
    var
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMUom: Record "CRM Uom";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMID: Guid;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Item] [Assembly]
        // [SCENARIO] Coupling an Assembled Item to a CRM Product
        TestInit();
        // [GIVEN] Assembled Item with "Unit Price" = 0
        PrepareItemForCoupling(Item, Item."Replenishment System"::Assembly, CRMUom);
        Item.TestField("Unit Price", 0);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);

        // [GIVEN] Invoking the Go To CRM Product action in the Item List page
        // [WHEN] Coupling the Item to new CRM Product with synch from NAV
        // Happens in CreateNewCouplingRecordPageHandler
        JobQueueEntryID := RunGoToProductActionOnItemList(Item, IntegrationTableMapping);

        // [THEN] CRM Product hyperlink is not open, because Sync is just scheduled
        // [THEN] The Item and CRM Product are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(Item.RecordId),
          'The Item must be coupled');
        CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId, CRMID);

        // [THEN] The CRM Productpricelevel for new CRM Product Amount = 0
        CRMProduct.Get(CRMID);
        CRMProductpricelevel.SetRange(PriceLevelId, CRMProduct.PriceLevelId);
        CRMProductpricelevel.SetRange(ProductId, CRMProduct.ProductId);
        CRMProductpricelevel.FindFirst();
        CRMProductpricelevel.TestField(Amount, Item."Unit Price");

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    local procedure PrepareItemForCoupling(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; var CRMUom: Record "CRM Uom")
    var
        UnitOfMeasure: Record "Unit of Measure";
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Validate(
          "Description 2",
          LibraryUtility.GenerateRandomText(MaxStrLen(Item."Description 2")));
        Item.Modify(true);
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure TestCoupleItemHyperlinkHandler(Link: Text)
    begin
        Assert.ExpectedMessage('etn=product', Link);
    end;

    [Test]
    [HandlerFunctions('SyncToCRMCouplingRecordPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleUnitOfMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
        CRMUomschedule1: Record "CRM Uomschedule";
        CRMUomschedule2: Record "CRM Uomschedule";
        CRMUom1: Record "CRM Uom";
        CRMUom2: Record "CRM Uom";
        IntegrationTableMapping: Record "Integration Table Mapping";
        UnitsOfMeasure: TestPage "Units of Measure";
        Unused: RecordID;
        CRMID: Guid;
        OriginalUoMCode: Text;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Unit Of Measure]
        // [SCENARIO] Coupling a Unit of Measure to another CRM Uomschedule
        TestInit();

        // [GIVEN] A Unit of Measure and two CRM Uomschedules, all with different data
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CRMUom1.Init();
        CRMUom1.Name := 'BOX';
        CRMUom1.Insert();
        LibraryCRMIntegration.CreateCRMUomAndUomSchedule(CRMUom1, CRMUomschedule1);
        CRMUom2.Init();
        CRMUom2.Name := 'KG';
        CRMUom2.Insert();
        LibraryCRMIntegration.CreateCRMUomAndUomSchedule(CRMUom2, CRMUomschedule2);
        OriginalUoMCode := UnitOfMeasure.Code;

        // [GIVEN] The Unit of Measure is coupled to one of the CRM Uomschedules
        CRMIntegrationRecord.CoupleRecordIdToCRMID(UnitOfMeasure.RecordId, CRMUomschedule1.UoMScheduleId);

        // [GIVEN] The Unit of Measure List page
        UnitsOfMeasure.OpenView();
        UnitsOfMeasure.GotoRecord(UnitOfMeasure);

        // [WHEN] Invoking the Set Up Coupling action
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(CRMUomschedule2.Name);
        UnitsOfMeasure.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Unit of Measure to the other CRM Uomschedule with synch from NAV
        // Happens in SyncToCRMCouplingRecordPageHandler
        UnitOfMeasure.SetRange(SystemId, UnitOfMeasure.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Unit of Measure", UnitOfMeasure.GetView(), IntegrationTableMapping);

        // [THEN] The Unit of Measure and the previously uncoupled CRM Uomschedule are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(UnitOfMeasure.RecordId),
          'The Unit of Measure must be coupled');
        CRMIntegrationRecord.FindIDFromRecordID(UnitOfMeasure.RecordId, CRMID);
        Assert.AreEqual(CRMUomschedule2.UoMScheduleId, CRMID,
          'The Unit of Measure must be coupled to the second CRM Uomschedule');

        // [THEN] The previously coupled CRM Uomschedule is not coupled
        Assert.IsFalse(
          CRMIntegrationRecord.FindRecordIDFromID(CRMUomschedule1.UoMScheduleId,
            DATABASE::"Unit of Measure", Unused),
          'The first CRM Uomschedule should no longer be coupled');

        // [THEN] The previously uncoupled CRM Uomschedule data was overwritten with the Unit of Measure data
        CRMUomschedule2.Find();
        Assert.IsTrue(UnitOfMeasure.Find(), 'The Unit of Measure was renamed');
        Assert.AreEqual(OriginalUoMCode, CRMUomschedule2.BaseUoMName,
          'The second CRM Uomschedule should have the same Base UoM Name as the Code of the Unit of Measure');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SyncToCRMCouplingRecordPageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.CRMName.SetValue(LibraryVariableStorage.DequeueText());
        CRMCouplingRecord.SyncActionControl.SetValue(SyncAction::PushToCRM);
        CRMCouplingRecord.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('SetCouplingRecordPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleCustPriceGroup()
    var
        Currency: Record Currency;
        CustomerPriceGroup: Record "Customer Price Group";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CustomerPriceGroups: TestPage "Customer Price Groups";
        OriginalPriceGroupCode: Code[10];
        CRMID: Guid;
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Price List]
        // [SCENARIO] Coupling a Customer Price Group to a CRM PriceLevel
        TestInit();
        EnableConnection();

        // [GIVEN] A Customer Price Group and a CRM PriceLevel with different data
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryCRMIntegration.CreateCurrencyCoupledToTransactionBaseCurrency(Currency, CRMTransactioncurrency);
        LibraryCRMIntegration.CreateCRMPriceList(CRMPricelevel, CRMTransactioncurrency);
        OriginalPriceGroupCode := CustomerPriceGroup.Code;

        // [GIVEN] The Customer Price Groups list page
        CustomerPriceGroups.OpenView();
        CustomerPriceGroups.GotoRecord(CustomerPriceGroup);

        // [WHEN] Invoking the Set Up Coupling action
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(CRMPricelevel.Name);
        CustomerPriceGroups.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Customer Price Group to the CRM Pricelevel with synch from NAV
        // This is done in SetCouplingRecordPageHandler
        CustomerPriceGroup.SetRange(SystemId, CustomerPriceGroup.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Customer Price Group", CustomerPriceGroup.GetView(), IntegrationTableMapping);

        // [THEN] The Customer and CRM Account are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(CustomerPriceGroup.RecordId),
          'The Customer Price Group must be coupled');
        CRMIntegrationRecord.FindIDFromRecordID(CustomerPriceGroup.RecordId, CRMID);
        Assert.AreEqual(CRMPricelevel.PriceLevelId, CRMID,
          'The Customer Price Group must be coupled to the correct CRM Pricelevel');

        // [THEN] The CRM Pricelevel data was overwritten with the Customer Price Group data
        CRMPricelevel.Find();
        CustomerPriceGroup.Find();
        Assert.AreEqual(OriginalPriceGroupCode, CustomerPriceGroup.Code,
          'The Customer Price Group must have the same name as it had before syncing');
        Assert.AreEqual(CustomerPriceGroup.Code, CRMPricelevel.Name,
          'The CRM Pricelevel must have the same name as the Customer Price Group after syncing');
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleCustPriceGroupWithSalesPrice()
    var
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesPrice: Record "Sales Price";
        CRMProduct: Record "CRM Product";
        CustomerPriceGroups: TestPage "Customer Price Groups";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Price List]
        // [SCENARIO] Coupling a Customer Price Group with child Sales Line, create new Pricelevel in CRM
        TestInit();

        // [GIVEN] A Customer Price Group with child Sales Line
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          0D, '', '', '', 0, LibraryRandom.RandDecInRange(10, 100, 2));

        // [GIVEN] The Customer Price Groups list page
        CustomerPriceGroups.OpenView();
        CustomerPriceGroups.GotoRecord(CustomerPriceGroup);

        // [WHEN] Invoking the Set Up Coupling action, Create New
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CustomerPriceGroups.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Customer Price Group to newly created CRM Pricelevel
        // This is done in CreateNewCouplingRecordPageHandler
        CustomerPriceGroup.SetRange(SystemId, CustomerPriceGroup.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Customer Price Group", CustomerPriceGroup.GetView(), IntegrationTableMapping);

        // [THEN] The Customer Price Group and CRM Pricelist are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(CustomerPriceGroup.RecordId),
          'The Customer Price Group must be coupled');
        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    procedure CoupleInactivePriceListHeaderWithCRMPriceLevel()
    var
        CRMProduct: Record "CRM Product";
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [UI] [Price List]
        // [SCENARIO] Coupling is not enabled for inactive Price List Header
        TestInit(true, false);
        // [GIVEN] Extended Price is on

        // [GIVEN] Draft Price List Header for Customer Price Group 'CPR' with one Line for Item 'I'
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code);
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code,
            "Price Asset Type"::Item, Item."No.");
        PriceListHeader.Status := PriceListHeader.Status::Draft;
        PriceListHeader.Modify();

        // [GIVEN] Open "Sales Price List" page
        SalesPriceList.OpenView();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] CRM action group is not enabled
        Assert.IsFalse(SalesPriceList.ManageCRMCoupling.Enabled(), 'ManageCRMCoupling.Enabled');
    end;

    [Test]
    procedure CouplePriceListHeaderAllowUpdatingDefaultsWithCRMPriceLevel()
    var
        CRMProduct: Record "CRM Product";
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [FEATURE] [UI] [Price List]
        // [SCENARIO] Coupling is not enabled for Price List Header, where "Allow Updating Defaults" is Yes.
        TestInit(true, false);
        // [GIVEN] Extended Price is on

        // [GIVEN] Active Price List Header for Customer Price Group 'CPR' with one Line for Item 'I',
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code);
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code,
            "Price Asset Type"::Item, Item."No.");
        // [GIVEN] "Allow Updating Defaults" is Yes.
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Modify();

        // [GIVEN] Open "Sales Price List" page
        SalesPriceList.OpenView();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [THEN] CRM action group is not enabled
        Assert.IsFalse(SalesPriceList.ManageCRMCoupling.Enabled(), 'ManageCRMCoupling.Enabled');
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordNavNamePageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CouplePriceListHeaderWithCRMPriceLevel()
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProduct: Record "CRM Product";
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Price List]
        // [SCENARIO] Coupling a Price List Header with child Line, create new Pricelevel in CRM
        TestInit(true, false);
        // [GIVEN] Extended Price is on

        // [GIVEN] Active Price List Header 'PLH001' for Customer Price Group 'CPR' with one Line for Item 'I'
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, "Price Type"::Sale, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code);
        PriceListHeader.TestField(Status, PriceListHeader.Status::Draft);
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"Customer Price Group", CustomerPriceGroup.Code,
            "Price Asset Type"::Item, Item."No.");
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Modify();

        // [GIVEN] The "Sales Price List" page
        SalesPriceList.OpenView();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);
        Assert.IsTrue(SalesPriceList.ManageCRMCoupling.Enabled(), 'ManageCRMCoupling.Enabled');

        // [WHEN] Invoking the Set Up Coupling action, Create New
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        SalesPriceList.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Price List Header to newly created CRM Pricelevel
        // This is done in CreateNewCouplingRecordPageHandler
        PriceListHeader.SetRange(SystemId, PriceListHeader.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Price List Header", PriceListHeader.GetView(), IntegrationTableMapping);

        // NAVName is 'PLH001' on the Coupling page (from CreateNewCouplingRecordNavNamePageHandler)
        Assert.AreEqual(PriceListHeader.Code, LibraryVariableStorage.DequeueText(), 'NAVName');
        // [THEN] The Price List Header and CRM Pricelist are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(PriceListHeader.RecordId),
          'The PriceListHeader must be coupled');
        // [THEN] CRM Price List, where State is Active
        CRMIntegrationRecord.FindByRecordID(PriceListHeader.RecordId);
        CRMPricelevel.Get(CRMIntegrationRecord."CRM ID");
        CRMPricelevel.TestField(StateCode, CRMPricelevel.StateCode::Active);
        // [THEN] The Price List Line and CRM PricelistLine are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(PriceListLine.RecordId),
          'The PriceListLine must be coupled');
        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordNavNamePageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleItemUnitGroupWithCRMUomschedule()
    var
        CRMUomschedule: Record "CRM Uomschedule";
        UnitGroup: Record "Unit Group";
        Item: Record Item;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        ItemUnitGroupList: TestPage "Item Unit Group List";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Unit Group]
        // [SCENARIO] Coupling a Unit Group, create new Unit Group in CRM
        // [GIVEN] Unit group mapping is on
        TestInit(false, true);

        // [GIVEN] Unit Group for Item
        LibraryInventory.CreateItem(Item);
        UnitGroup.Get(UnitGroup."Source Type"::Item, Item.SystemId);

        // [GIVEN] The "Item Unit Group List" page
        ItemUnitGroupList.OpenView();
        ItemUnitGroupList.Filter.SetFilter("Source No.", UnitGroup."Source No.");
        Assert.IsTrue(ItemUnitGroupList.ManageCRMCoupling.Enabled(), 'ManageCRMCoupling.Enabled');

        // [WHEN] Invoking the Set Up Coupling action, Create New
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        ItemUnitGroupList.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Unit Group to newly created CRM Uomschedule
        // This is done in CreateNewCouplingRecordPageHandler
        UnitGroup.SetRange(SystemId, UnitGroup.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Unit Group", UnitGroup.GetView(), IntegrationTableMapping);

        // [THEN] The Unit Group and CRM Uomschedule are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(UnitGroup.RecordId),
          'The Unit Group must be coupled');

        // [THEN] CRM Uomschedule, where State is Active
        CRMIntegrationRecord.FindByRecordID(UnitGroup.RecordId);
        CRMUomschedule.Get(CRMIntegrationRecord."CRM ID");
        CRMUomschedule.TestField(StateCode, CRMUomschedule.StateCode::Active);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordNavNamePageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleResourceUnitGroupWithCRMUomschedule()
    var
        CRMUomschedule: Record "CRM Uomschedule";
        UnitGroup: Record "Unit Group";
        Resource: Record Resource;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        ResourceUnitGroupList: TestPage "Resource Unit Group List";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Unit Group]
        // [SCENARIO] Coupling a Unit Group, create new Unit Group in CRM
        // [GIVEN] Unit group mapping is on
        TestInit(false, true);

        // [GIVEN] Unit Group for Resource
        LibraryResource.CreateResourceNew(Resource);
        UnitGroup.Get(UnitGroup."Source Type"::Resource, Resource.SystemId);

        // [GIVEN] The "Item Unit Group List" page
        ResourceUnitGroupList.OpenView();
        ResourceUnitGroupList.Filter.SetFilter("Source No.", UnitGroup."Source No.");
        Assert.IsTrue(ResourceUnitGroupList.ManageCRMCoupling.Enabled(), 'ManageCRMCoupling.Enabled');

        // [WHEN] Invoking the Set Up Coupling action, Create New
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        ResourceUnitGroupList.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Unit Group to newly created CRM Uomschedule
        // This is done in CreateNewCouplingRecordPageHandler
        UnitGroup.SetRange(SystemId, UnitGroup.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Unit Group", UnitGroup.GetView(), IntegrationTableMapping);

        // [THEN] The Unit Group and CRM Uomschedule are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(UnitGroup.RecordId),
          'The Unit Group must be coupled');

        // [THEN] CRM Uomschedule, where State is Active
        CRMIntegrationRecord.FindByRecordID(UnitGroup.RecordId);
        CRMUomschedule.Get(CRMIntegrationRecord."CRM ID");
        CRMUomschedule.TestField(StateCode, CRMUomschedule.StateCode::Active);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordNavNamePageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleItemUnitOfMeasureWithCRMUom()
    var
        CRMUomschedule: Record "CRM Uomschedule";
        CRMUom: Record "CRM Uom";
        UnitGroup: Record "Unit Group";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        ItemUnitsOfMeasure: TestPage "Item Units of Measure";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Item Unit of Measure]
        // [SCENARIO] Coupling a Item Unit of Measure, create new Unit in CRM
        // [GIVEN] Unit group mapping is on
        TestInit(false, true);

        // [GIVEN] Unit of Measure for Item
        LibraryCRMIntegration.CreateCoupledItemUnitGroupAndUomSchedule(UnitGroup, CRMUomschedule);
        Item.GetBySystemId(UnitGroup."Source Id");
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");

        // [GIVEN] The "Item Units of Measure" page
        ItemUnitsOfMeasure.OpenView();
        ItemUnitsOfMeasure.Filter.SetFilter(SystemId, ItemUnitOfMeasure.SystemId);
        Assert.IsTrue(ItemUnitsOfMeasure.ManageCRMCoupling.Enabled(), 'ManageCRMCoupling.Enabled');

        // [WHEN] Invoking the Set Up Coupling action, Create New
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        ItemUnitsOfMeasure.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Unit of Measure to newly created CRM Uom
        // This is done in CreateNewCouplingRecordPageHandler
        ItemUnitOfMeasure.SetRange(SystemId, ItemUnitOfMeasure.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Item Unit of Measure", ItemUnitOfMeasure.GetView(), IntegrationTableMapping);

        // [THEN] The Unit Group and CRM Uomschedule are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(ItemUnitOfMeasure.RecordId),
          'The Item Unit of Measure must be coupled');

        // [THEN] CRM Uom, where Name is Item Unit of Measure Code
        CRMIntegrationRecord.FindByRecordID(ItemUnitOfMeasure.RecordId);
        CRMUom.Get(CRMIntegrationRecord."CRM ID");
        CRMUom.TestField(Name, ItemUnitOfMeasure.Code);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordNavNamePageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleResourceUnitOfMeasureWithCRMUom()
    var
        CRMUomschedule: Record "CRM Uomschedule";
        CRMUom: Record "CRM Uom";
        UnitGroup: Record "Unit Group";
        Resource: Record Resource;
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
        ResourceUnitsOfMeasure: TestPage "Resource Units of Measure";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [UI] [Resource Unit of Measure]
        // [SCENARIO] Coupling a Resource Unit of Measure, create new Unit in CRM
        // [GIVEN] Unit group mapping is on
        TestInit(false, true);

        // [GIVEN] Unit of Measure for Resource
        LibraryCRMIntegration.CreateCoupledResourceUnitGroupAndUomSchedule(UnitGroup, CRMUomschedule);
        Resource.GetBySystemId(UnitGroup."Source Id");
        ResourceUnitOfMeasure.Get(Resource."No.", Resource."Base Unit of Measure");

        // [GIVEN] The "Resource Units of Measure" page
        ResourceUnitsOfMeasure.OpenView();
        ResourceUnitsOfMeasure.Filter.SetFilter(SystemId, ResourceUnitOfMeasure.SystemId);
        Assert.IsTrue(ResourceUnitsOfMeasure.ManageCRMCoupling.Enabled(), 'ManageCRMCoupling.Enabled');

        // [WHEN] Invoking the Set Up Coupling action, Create New
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        ResourceUnitsOfMeasure.ManageCRMCoupling.Invoke();

        // [WHEN] Coupling the Unit of Measure to newly created CRM Uom
        // This is done in CreateNewCouplingRecordPageHandler
        ResourceUnitOfMeasure.SetRange(SystemId, ResourceUnitOfMeasure.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Resource Unit of Measure", ResourceUnitOfMeasure.GetView(), IntegrationTableMapping);

        // [THEN] The Unit Group and CRM Uomschedule are coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(ResourceUnitOfMeasure.RecordId),
          'The Resource Unit of Measure must be coupled');

        // [THEN] CRM Uom, where Name is Resource Unit of Measure Code
        CRMIntegrationRecord.FindByRecordID(ResourceUnitOfMeasure.RecordId);
        CRMUom.Get(CRMIntegrationRecord."CRM ID");
        CRMUom.TestField(Name, ResourceUnitOfMeasure.Code);

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Inserted" = 1, no errors.
        IntegrationSynchJob.Inserted := 1;
        LibraryCRMIntegration.VerifySyncJob(JobQueueEntryID, IntegrationTableMapping, IntegrationSynchJob);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateNewCouplingRecordPageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.CreateNewControl.SetValue(true);
        CRMCouplingRecord.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CreateNewCouplingRecordNavNamePageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        LibraryVariableStorage.Enqueue(CRMCouplingRecord.NAVName.Value());
        CRMCouplingRecord.CreateNewControl.SetValue(true);
        CRMCouplingRecord.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CancelCouplingRecordPageHandler')]
    [Scope('OnPrem')]
    procedure CoupleResource()
    var
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
        Currency: Record Currency;
        CRMUom: Record "CRM Uom";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMProduct: Record "CRM Product";
        CRMUomschedule: Record "CRM Uomschedule";
        ResourceList: TestPage "Resource List";
        OriginalResourceName: Text;
        OriginalCRMProductName: Text;
    begin
        // [FEATURE] [UI] [Resource]
        // [SCENARIO] Canceling the coupling of a Resource to a CRM Product
        TestInit();

        // [GIVEN] A Resource and a CRM Product with different data
        LibraryResource.CreateResourceNew(Resource);
        CRMUom.Name := Resource."Base Unit of Measure";
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        LibraryCRMIntegration.CreateCRMProduct(CRMProduct, CRMTransactioncurrency, CRMUom);
        CRMProduct.ProductTypeCode := CRMProduct.ProductTypeCode::Services;
        CRMProduct.Modify();
        OriginalResourceName := Resource.Name;
        OriginalCRMProductName := CRMProduct.Name;

        // [GIVEN] The Resource List page
        ResourceList.OpenView();
        ResourceList.GotoRecord(Resource);

        // [WHEN] Invoking the Set Up Coupling action
        LibraryVariableStorage.Enqueue(CRMProduct.ProductNumber);
        ResourceList.ManageCRMCoupling.Invoke();

        // [WHEN] Selecting the CRM Product to couple to but then closing the page using Cancel
        // This happens in CancelCouplingRecordPageHandler

        // [THEN] The Resource is not coupled
        Assert.IsFalse(CRMIntegrationRecord.IsRecordCoupled(Resource.RecordId),
          'The Resource should not be coupled');

        // [THEN] The CRM Product is not coupled
        Assert.IsFalse(CRMCouplingManagement.IsRecordCoupledToNAV(CRMProduct.ProductId, DATABASE::Resource),
          'The CRM Product should not be coupled');

        // [THEN] The Resource and CRM Product contain their original data
        Assert.AreEqual(OriginalResourceName, Resource.Name, 'The resource name should not have changed');
        Assert.AreEqual(OriginalCRMProductName, CRMProduct.Name, 'The CRM Product name should not have changed');
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleResourceWithBlankBaseUoM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Resource: Record Resource;
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Resource] [Unit Of Measure]
        // [SCENARIO] An error should be thrown if coupling a Resource, where "Base Unit Of Measure" is blank, to a CRM Product
        TestInit();

        // [GIVEN] A Resource, where "Base Unit Of Measure" is blank
        LibraryResource.CreateResourceNew(Resource);
        Resource."Base Unit of Measure" := '';
        Resource.Modify();

        // [WHEN] Couple to a new CRM Product
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(Resource.RecordId);
        Resource.SetRange(SystemId, Resource.SystemId);
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(DATABASE::Resource, Resource.GetView(), IntegrationTableMapping);

        // [THEN] The Resource and CRM Product are not coupled
        Assert.IsFalse(CRMIntegrationRecord.IsRecordCoupled(Resource.RecordId), 'The Resource should not be coupled');

        // [THEN] Notification "Syncronization has been scheduled." is shown.
        // Handled by SyncStartedNotificationHandler
        // [THEN] Job Queue Entry and Integration Table Mapping records are removed
        // [THEN] IntegrationSynchJob is created, where "Failed" = 1, Error message is 'Base Unit Of Measure must have a value'
        LibraryCRMIntegration.VerifySyncJobFailedOneRecord(
          JobQueueEntryID, IntegrationTableMapping, StrSubstNo(BaseUoMErr, Resource.TableName));
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleToNewUoMAfterMapIsSynched()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        UnitOfMeasure: Record "Unit of Measure";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Job Queue]
        // [SCENARIO] Coupling a NAV record to a new CRM record should not depend on previous synchronization time.
        TestInit();
        // [GIVEN] new Unit of Measure is created at 10:53:17
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Integration Table Mapping, has been synced, "Synch. Modified On Filter" is 10:53:18.
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Unit of Measure");
        IntegrationTableMapping.ModifyAll("Synch. Modified On Filter", CurrentDateTime + 1);

        // [WHEN] Couple the UoM using Create New
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        UnitOfMeasure.SetRange(SystemId, UnitOfMeasure.SystemId);
        CRMIntegrationManagement.CreateNewRecordsInCRM(UnitOfMeasure);
        // execute the job
        JobQueueEntryID :=
          LibraryCRMIntegration.RunJobQueueEntry(
            DATABASE::"Unit of Measure", UnitOfMeasure.GetView(), IntegrationTableMapping);

        // [THEN] The Unit of Measure is coupled
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(UnitOfMeasure.RecordId),
          'The Unit of Measure must be coupled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveCouplingForCustomerWithContacts()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        A_CRMContact: Record "CRM Contact";
        B_CRMContact: Record "CRM Contact";
        P_CRMContact: Record "CRM Contact";
        Q_CRMContact: Record "CRM Contact";
        A_Contact: Record Contact;
        B_Contact: Record Contact;
        C_Contact: Record Contact;
        D_Contact: Record Contact;
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO] Removing the coupling for a customer with complicated contact relations
        TestInit();

        // [GIVEN] A customer coupled to a CRM account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] A contact related to the customer coupled to a CRM contact related to the CRM account
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(A_CRMContact, CRMAccount);
        LibraryCRMIntegration.CreateContactForCustomer(A_Contact, Customer);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(A_Contact.RecordId, A_CRMContact.ContactId);

        // [GIVEN] One more contact related to the customer coupled to a CRM contact related to the CRM account
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(B_CRMContact, CRMAccount);
        LibraryCRMIntegration.CreateContactForCustomer(B_Contact, Customer);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(B_Contact.RecordId, B_CRMContact.ContactId);

        // [GIVEN] A contact related to the customer coupled to a CRM contact not related to the CRM account
        LibraryCRMIntegration.CreateContactForCustomer(C_Contact, Customer);
        LibraryCRMIntegration.CreateCRMContact(P_CRMContact);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(C_Contact.RecordId, P_CRMContact.ContactId);

        // [GIVEN] A CRM contact related to the CRM account coupled to a contact not related to the customer
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(Q_CRMContact, CRMAccount);
        LibraryCRMIntegration.CreateContact(D_Contact);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(D_Contact.RecordId, Q_CRMContact.ContactId);

        // [WHEN] Deleting the coupling of the customer
        CRMCouplingManagement.RemoveCouplingWithTracking(Customer.RecordId, TempCRMIntegrationRecord);
        VerifyUncouplingJobQueueEntryExists();
        SimulateUncouplingJobsExecution();

        // [THEN] The coupling between the contact and CRM contact related to the customer and CRM account should be deleted
        // This is tested in OnAfterUncoupleRecord

        // [THEN] Only the couplings between the customer and CRM account and their related (CRM) contacts which are coupled to one another are removed
        Assert.IsFalse(CRMIntegrationRecord.IsRecordCoupled(Customer.RecordId),
          'The customer should no longer be coupled');
        Assert.IsFalse(CRMIntegrationRecord.IsRecordCoupled(A_Contact.RecordId),
          'The 1st contact that was coupled to the CRM contact under the CRM account the customer was coupled to should be uncoupled');
        Assert.IsFalse(CRMIntegrationRecord.IsRecordCoupled(B_Contact.RecordId),
          'The 2nd contact that was coupled to the CRM contact under the CRM account the customer was coupled to should be uncoupled');
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(C_Contact.RecordId),
          'The contact under the customer that is coupled to an unrelated CRM contact should still be coupled');
        Assert.IsTrue(CRMIntegrationRecord.IsRecordCoupled(D_Contact.RecordId),
          'The unrelated contact coupled to the CRM contact under the CRM account the customer was coupled to should still be coupled');
        // [THEN] List of deleted CRM Integration Records contains CRM Account
        Assert.AreEqual(1, TempCRMIntegrationRecord.Count, 'wrong humber of deleted CRM Integration Records');
        Assert.IsTrue(TempCRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId), 'Customer');
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleOpportunityToNew()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Opportunity: Record Opportunity;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [FEATURE] [Opportunity]
        // [SCENARIO] Coupling Opportunity to new CRM Opportunity
        TestInit();

        // [GIVEN] Opportunity
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        Contact.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Contact.Modify(true);
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");

        // [WHEN] Couple Opportunity using Create New
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        Opportunity.SetRange(SystemId, Opportunity.SystemId);
        CRMIntegrationManagement.CreateNewRecordsInCRM(Opportunity);
        // execute the job
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Opportunity, Opportunity.GetView(), IntegrationTableMapping);

        // [THEN] Opportunity is coupled
        Assert.IsTrue(
          CRMIntegrationRecord.IsRecordCoupled(Opportunity.RecordId),
          'The Opportunity must be coupled');
    end;

    [Test]
    [HandlerFunctions('SetCouplingRecordPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleOpportunity()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        IntegrationTableMapping: Record "Integration Table Mapping";
        OpportunityCard: TestPage "Opportunity Card";
        ExpectedCRMName: Text;
    begin
        // [FEATURE] [UI] [Opportunity]
        // [SCENARIO] Coupling Opportunity to CRM Opportunity
        TestInit();

        // [GIVEN] Salesperson coupled to CRM Systemuser
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        // [GIVEN] Contact coupled to CRM Contact
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        Contact.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Contact.Modify(true);
        // [GIVEN] Opportunity and CRM Opportunity
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");
        LibraryCRMIntegration.CreateCRMOpportunity(CRMOpportunity);
        ExpectedCRMName := CRMOpportunity.Name;
        // [GIVEN] Opportunity Card page
        OpportunityCard.OpenView();
        OpportunityCard.GotoRecord(Opportunity);

        // [WHEN] Couple Opportunity to CRM Opportunity
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        LibraryVariableStorage.Enqueue(ExpectedCRMName);
        OpportunityCard.ManageCRMCoupling.Invoke();
        // execute the job
        Opportunity.SetRange(SystemId, Opportunity.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Opportunity, Opportunity.GetView(), IntegrationTableMapping);

        // [THEN] Opportunity is coupled
        Assert.IsTrue(
          CRMIntegrationRecord.IsRecordCoupled(Opportunity.RecordId),
          'The Opportunity must be coupled');
        CRMOpportunity.Find();
        // [THEN] "CRM Opportunity"."Name" = "Opportunity"."Description"
        Assert.AreEqual(
          Opportunity.Description, CRMOpportunity.Name,
          'CRM Opportunity must have the same name as the Opportunity description');
        // [THEN] "CRM Opportunity"."OwnerId" = "CRMSystemuser"."SystemUserId"
        Assert.AreEqual(
          CRMSystemuser.SystemUserId, CRMOpportunity.OwnerId,
          'CRM Opportunity must have OwnerId the same as the created CRM Systemuser');
        // [THEN] "CRM Opportunity"."ParentContactId" = "CRMContact"."ContactId"
        Assert.AreEqual(
          CRMContact.ContactId, CRMOpportunity.ParentContactId,
          'CRM Opportunity must have ParentContactId the same as the created CRM Contact');
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleOpportunityToNewEmptySalespersonCode()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        Opportunity: Record Opportunity;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMOpportunity: Record "CRM Opportunity";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        NULLGUID: Guid;
    begin
        // [FEATURE] [Opportunity]
        // [SCENARIO] Coupling Opportunity to new CRM Opportunity with empty Salesperson Code
        TestInit();

        // [GIVEN] Opportunity with Salesperson Code = ''
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");
        Opportunity."Salesperson Code" := '';
        Opportunity.Modify();

        // [WHEN] Couple Opportunity using Create New
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        Opportunity.SetRange(SystemId, Opportunity.SystemId);
        CRMIntegrationManagement.CreateNewRecordsInCRM(Opportunity);
        // execute the job
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Opportunity, Opportunity.GetView(), IntegrationTableMapping);

        // [THEN] Opportunity is coupled
        Assert.IsTrue(
          CRMIntegrationRecord.IsRecordCoupled(Opportunity.RecordId),
          'The Opportunity must be coupled');

        // [THEN] Owner Id is empty
        CRMOpportunity.FindFirst();
        CRMOpportunity.TestField(OwnerId, NULLGUID);
    end;

    [Test]
    [HandlerFunctions('SalespersonPurchaserModalPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CRMSystemUserPageCoupletoSalesperson()
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuserList: TestPage "CRM Systemuser List";
        Coupled: Option Yes,No,Current;
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO 208299] Coupling of CRM users to Salesperson in CRM SystemUser page.
        TestInit();

        // [GIVEN] Salesperson "SP" and CRM User "CU"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryVariableStorage.Enqueue(SalespersonPurchaser.Code);
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser);

        // [WHEN] CRM Systemuser List page is opened
        CRMSystemuserList.OpenEdit();

        // [THEN] CRM User "CU" has "Coupled" = No and no coupled Salesperson defined
        CRMSystemuserList.GotoKey(CRMSystemuser.SystemUserId);
        CRMSystemuserList.Coupled.AssertEquals(Coupled::No);
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals('');

        // [WHEN] Lookup is made and "SP" Salesperson selected
        CRMSystemuserList.SalespersonPurchaserCode.Lookup();

        // [THEN] CRM User "CU" has Salesperson = "SP" in CRM Systemuser List page
        CRMSystemuserList.Coupled.AssertEquals(Coupled::No);
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals(SalespersonPurchaser.Code);

        // [WHEN] Action Couple is invoked
        CRMSystemuserList.Couple.Invoke();

        // [THEN] CRM User "CU" has "Coupled" = Yes and Salesperson = "SP"
        CRMSystemuserList.Coupled.AssertEquals(Coupled::Yes);
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals(SalespersonPurchaser.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSystemUserPageShowsCoupledSalesperson()
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuserList: TestPage "CRM Systemuser List";
        Coupled: Option Yes,No,Current;
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO 208299] Coupled CRM User has Coupled = Yes and defined Salesperson
        TestInit();

        // [GIVEN] Salesperson "SP" and CRM User "CU" are coupled
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [WHEN] CRM Systemuser List page is opened
        CRMSystemuserList.OpenEdit();

        // [THEN] CRM Systemuser "CU" has "Coupled" = Yes, Salesperson Code = "SP"
        CRMSystemuserList.GotoKey(CRMSystemuser.SystemUserId);
        CRMSystemuserList.Coupled.AssertEquals(Coupled::Yes);
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals(SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('SalespersonPurchaserModalPageHandler')]
    [Scope('OnPrem')]
    procedure CRMSystemUserPageCoupleSalespersonToOtherCRMUser()
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser2: Record "CRM Systemuser";
        CRMSystemuserList: TestPage "CRM Systemuser List";
        Coupled: Option Yes,No,Current;
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO 208299] Change coupling of Salesperson from one CRM User to other CRM User
        TestInit();

        // [GIVEN] Salesperson "SP" coupled to CRM User "CU1"
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        LibraryVariableStorage.Enqueue(SalespersonPurchaser.Code);

        // [GIVEN] CRM User "CU2"
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser2);

        // [WHEN] CRM Systemuser List page is opened
        CRMSystemuserList.OpenEdit();

        // [WHEN] Salesperson "SP" is selected for CRM User "CU2"
        CRMSystemuserList.GotoKey(CRMSystemuser2.SystemUserId);
        LibraryVariableStorage.Enqueue(SalespersonPurchaser.Code);
        CRMSystemuserList.SalespersonPurchaserCode.Lookup();

        // [THEN] CRM User "CU1" has Coupled = "Yes" and no coupled Salesperson defined
        CRMSystemuserList.GotoKey(CRMSystemuser.SystemUserId);
        CRMSystemuserList.Coupled.AssertEquals(Coupled::Yes);
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals('');

        // [WHEN] Couple is invoked
        CRMSystemuserList.Couple.Invoke();

        // [THEN] CRM User "CU1" has Coupled = "No" and no coupled Salesperson defined
        CRMSystemuserList.Coupled.AssertEquals(Coupled::No);
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals('');

        // [THEN] CRM User "CU2" has Coupled = "Yes" and Salesperson = "SP"
        CRMSystemuserList.GotoKey(CRMSystemuser2.SystemUserId);
        CRMSystemuserList.Coupled.AssertEquals(Coupled::Yes);
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals(SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestProductToNewItem()
    var
        Currency: Record Currency;
        CRMProduct: Record "CRM Product";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        CDSCompany: Record "CDS Company";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [SCENARIO] Synchronize CRM Product to Item
        TestInit();
        Item.DeleteAll(false);
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [GIVEN] Unit of Measure coupled to CRM UoM "CRMUOM"
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        // [GIVEN] CRM Product
        LibraryCRMIntegration.CreateCRMProduct(CRMProduct, CRMTransactioncurrency, CRMUom);
        CRMProduct.StateCode := CRMProduct.StateCode::Active;
        CRMProduct.ProductTypeCode := CRMProduct.ProductTypeCode::SalesInventory;
        CRMProduct.Modify();

        // [WHEN] Synchronize CRM Product to Item
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMProduct.SetRange(ProductId, CRMProduct.ProductId);
        CRMIntegrationManagement.CreateNewRecordsFromCRM(CRMProduct);
        LibraryCRMIntegration.RunJobQueueEntry(DATABASE::"CRM Product", CRMProduct.GetView(), IntegrationTableMapping);

        // [THEN] "Item"."Base Unit of Measure" = "CRMUOM"
        Item.FindFirst();
        Assert.AreEqual(UnitOfMeasure.Code, Item."Base Unit of Measure", UoMErr);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestProductToNewItemResourceNotPickedUp()
    var
        Currency: Record Currency;
        CRMProduct: Record "CRM Product";
        CRMProductService: Record "CRM Product";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMUom: Record "CRM Uom";
        CRMUomService: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMUomscheduleService: Record "CRM Uomschedule";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        UnitOfMeasureService: Record "Unit of Measure";
        CDSCompany: Record "CDS Company";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [SCENARIO] Synchronize CRM Product to Item
        TestInit();
        Item.DeleteAll(false);
        LibraryCRMIntegration.EnsureCDSCompany(CDSCompany);

        // [GIVEN] Unit of Measure coupled to CRM UoM "CRMUOM"
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasureService, CRMUomService, CRMUomscheduleService);
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        // [GIVEN] CRM Product of type Sales inventory
        LibraryCRMIntegration.CreateCRMProduct(CRMProduct, CRMTransactioncurrency, CRMUom);
        // [GIVEN] CRM Product of type Service
        LibraryCRMIntegration.CreateCRMProduct(CRMProductService, CRMTransactioncurrency, CRMUomService);
        CRMProductService.ProductTypeCode := CRMProductService.ProductTypeCode::Services;
        CRMProductService.Modify();

        // [WHEN] Synchronize CRM Product to Item
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMProduct.SetRange(ProductId, CRMProduct.ProductId);
        CRMIntegrationManagement.CreateNewRecordsFromCRM(CRMProduct);
        LibraryCRMIntegration.RunJobQueueEntry(DATABASE::"CRM Product", CRMProduct.GetView(), IntegrationTableMapping);

        // [THEN] "Item"."Base Unit of Measure" = "CRMUOM"
        Assert.AreEqual(1, Item.Count(), 'Only one Item should have been created. The CRM Product of type Services should not have been picked up.');
        Item.FindFirst();
        Assert.AreEqual(UnitOfMeasure.Code, Item."Base Unit of Measure", UoMErr);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncAccountModifiedByIntegrationUserToNewCustomer()
    var
        CRMAccount: Record "CRM Account";
        CRMConnectionSetup: Record "CRM Connection Setup";
        Customer: array[2] of Record Customer;
    begin
        // [FEATURE] [Integration User]
        // [SCENARIO] Synchronize CRM Account, modified by Integration User, to new Customer
        TestInit();

        // [GIVEN] Customer coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[1], CRMAccount);
        // [GIVEN] CRM Account's last modification was done by the integration user.
        CRMAccount.ModifiedBy := CRMConnectionSetup.GetIntegrationUserID();
        CRMAccount.Modify();
        // [GIVEN] Coupling is removed
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        CRMIntegrationRecord.Delete();
        // [GIVEN] Customer is deleted
        Customer[1].Delete(true);

        // [WHEN] Synchronize CRM Account to new Customer
        CreateNewCustomerFromCRMAccount(CRMAccount);

        // [THEN] new Customer is created, coupled to CRM Account
        Assert.IsTrue(FindCoupledCustomer(CRMAccount.AccountId, Customer[2]), 'Account should be coupled.');
        Assert.AreNotEqual(Customer[1]."No.", Customer[2]."No.", 'New customer No. should be different');
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncAccountWithCorruptCouplingToNewCustomer()
    var
        CRMAccount: Record "CRM Account";
        Customer: array[2] of Record Customer;
    begin
        // [SCENARIO] Synchronize CRM Account, coupled to a deleted Customer, to new Customer
        TestInit();
        // [GIVEN] Customer coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[1], CRMAccount);
        // [GIVEN] Customer is deleted,
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        CRMIntegrationRecord.Delete();
        Customer[1].Delete(true);
        // [GIVEN] but coupling exists.
        CRMIntegrationRecord.Insert();

        // [WHEN] Synchronize CRM Account to new Customer
        CreateNewCustomerFromCRMAccount(CRMAccount);

        // [THEN] new Customer is created, coupled to CRM Account
        Assert.IsTrue(FindCoupledCustomer(CRMAccount.AccountId, Customer[2]), 'Account should be coupled.');
        Assert.AreNotEqual(Customer[1]."No.", Customer[2]."No.", 'New customer No. should be different');
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SyncCustomerWithCorruptCouplingToNewCRMAccount()
    var
        CRMAccount: array[2] of Record "CRM Account";
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [SCENARIO] Synchronize Customer, coupled to a deleted CRM Account, to new CRM Account
        TestInit();
        // [GIVEN] Customer coupled to CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount[1]);
        // [GIVEN] CRM Account is deleted
        CRMAccount[1].Delete(true);

        // [WHEN] Synchronize Customer to new CRM Account
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        Customer.SetRange(SystemId, Customer.SystemId);
        CRMIntegrationManagement.CreateNewRecordsInCRM(Customer);
        LibraryCRMIntegration.RunJobQueueEntry(DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);

        // [THEN] new CRM Account is created, coupled to Customer
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Customer.RecordId), 'Customer should be coupled.');
        CRMAccount[2].Get(CRMIntegrationRecord."CRM ID");
        Assert.AreNotEqual(CRMAccount[1].AccountId, CRMAccount[2].AccountId, 'New account id should be different');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSystemUserPageRemoveCoupling()
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuserList: TestPage "CRM Systemuser List";
        Coupled: Option Yes,No,Coupled;
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO 215918] User can remove coupling for CRM User on CRM SystemUser List page
        TestInit();

        // [GIVEN] Salesperson "SP" and CRM User "CU" are coupled
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        CRMSystemuserList.OpenEdit();
        CRMSystemuserList.GotoKey(CRMSystemuser.SystemUserId);
        CRMSystemuserList.Coupled.AssertEquals(Coupled::Yes);

        // [WHEN] Salesperson/Purchaser value is changed to '' for coupled CRM User and Couple action called
        CRMSystemuserList.SalespersonPurchaserCode.SetValue('');
        CRMSystemuserList.Couple.Invoke();

        // [THEN] CRM Systemuser "CU" has "Coupled" = No, Salesperson Code = ""
        CRMSystemuserList.Coupled.AssertEquals(Coupled::No);
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSystemUserClearSalespersonCodeWhenSelectedForOther()
    var
        CRMSystemuser1: Record "CRM Systemuser";
        CRMSystemuser2: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuserList: TestPage "CRM Systemuser List";
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO 215918] Selection of Salesperson already defined for other user clears old user Salesperson code
        TestInit();

        // [GIVEN] Salesperson "SP" and CRM User "CU1", "CU2"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser1);
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser2);
        CRMSystemuserList.OpenEdit();
        CRMSystemuserList.GotoKey(CRMSystemuser1.SystemUserId);

        // [GIVEN] Salesperson/Purchaser value is changed to 'SP' for CRM User "CU1"
        CRMSystemuserList.SalespersonPurchaserCode.SetValue(SalespersonPurchaser.Code);

        // [WHEN] Salesperson/Purchaser value is changed to 'SP' for CRM User "CU2"
        CRMSystemuserList.GotoKey(CRMSystemuser2.SystemUserId);
        CRMSystemuserList.SalespersonPurchaserCode.SetValue(SalespersonPurchaser.Code);

        // [THEN] CRM User "CU2" has Salesperson/Purchaser = "SP"
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals(SalespersonPurchaser.Code);

        // [THEN] CRM User "CU1" has Salesperson/Purchaser = ""
        CRMSystemuserList.GotoKey(CRMSystemuser1.SystemUserId);
        CRMSystemuserList.SalespersonPurchaserCode.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('CRMCouplingRecordModalPageHandler,CRMSystemuserCouplingControlModalPageHandler')]
    [Scope('OnPrem')]
    procedure CRMSystemUserPageCoupleControlsVisibility()
    var
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonPurchaserCard: TestPage "Salesperson/Purchaser Card";
    begin
        // [FEATURE] [UI] [Salesperson]
        // [SCENARIO 215918] When CRM SystemUser List page opened from Salesperson/Purchaser page coupling controls are not shown
        TestInit();
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser);

        // [WHEN] CRM Systemuser List page opened from Salesperson card
        SalespersonPurchaserCard.OpenEdit();
        SalespersonPurchaserCard.GotoRecord(SalespersonPurchaser);
        SalespersonPurchaserCard.ManageCRMCoupling.Invoke();

        // [THEN] "Couple" and "Uncouple" controls are not VISIBLE
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Couple control should not be visible');
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Uncouple control should not be visible');

        // [THEN] "Create Salesperson" control is VISIBLE
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Create Salesperson control should be visible');

        // [THEN] Salesperson/Purchaser Code column field should be disabled
        Assert.IsFalse(LibraryVariableStorage.DequeueBoolean(), 'Salesperson/Purchaser Code column field should be disabled');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CancelCouplingRecordPageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.CRMName.SetValue(LibraryVariableStorage.DequeueText());
        CRMCouplingRecord.Cancel().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CoupleYesConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage('create a coupling?', Question);
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('SynchCustomerStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UpdateCRMAccountPrimaryContactCodeFromCustomer()
    var
        Contact: Record Contact;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Customer] [Contact]
        // [SCENARIO 225428] Primary Contact in CRM Account is updated from Customer when synchronize
        TestInit();

        // [GIVEN] Customer "CUST" is coupled with CRM Account "CRMACC"
        GetIntegrationTableMapping(IntegrationTableMapping, Database::Customer);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        // [GIVEN] Contact "CONT" is coupled with CRM Contact "CRMCONT"
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);

        // [GIVEN] "CONT" is set as Primary Contact for "CUST"
        SetCustomerPrimaryContact(Customer, Contact);

        // [WHEN] Synchronize "CUST" with "CRMACC"
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        SyncAction := SyncAction::PushToCRM;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);
        Customer.SetRange(SystemId, Customer.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);

        // [THEN] "CRMACC"."PrimaryContactId" = "CRMACC"
        CRMAccount.Get(CRMAccount.AccountId);
        CRMAccount.TestField(PrimaryContactId);
        CRMAccount.TestField(PrimaryContactId, CRMContact.ContactId);
    end;

    [Test]
    //Reenabled in https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/368425
    [HandlerFunctions('SynchCustomerStrMenuHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure UpdateCustomerPrimaryContactCodeFromCRMAccount()
    var
        Contact: Record Contact;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Customer] [Contact]
        // [SCENARIO 225428] Primary Contact in Customer is updated from CRM Account when synchronize
        TestInit();

        // [GIVEN] Customer "CUST" is coupled with CRM Account "CRMACC"
        GetIntegrationTableMapping(IntegrationTableMapping, Database::Customer);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        // [GIVEN] Contact "CONT" is coupled with CRM Contact "CRMCONT"
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        Contact.Validate("Company No.", FindCompanyContact(Customer."No."));
        Contact.Modify();

        // [GIVEN] "CRMCONT" is set as Primary Contact for "CRMACC"
        SetCRMAccountPrimaryContact(CRMAccount, CRMContact.ContactId);

        // [WHEN] Synchronize "CUST" with "CRMACC"
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        SyncAction := SyncAction::PushToNAV;
        CRMIntegrationManagement.UpdateOneNow(Customer.RecordId);
        CRMAccount.SetRange(AccountId, CRMAccount.AccountId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::"CRM Account", CRMAccount.GetView(), IntegrationTableMapping);

        // [THEN] "CUST"."Primary Contact No." = "CONT"
        Customer.Get(Customer."No.");
        Customer.TestField("Primary Contact No.");
        Customer.TestField("Primary Contact No.", Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NAVtoCRMSyncClearValueOnFailedSyncYes()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        NullGuid: Guid;
    begin
        // [FEATURE] [Customer-Contact Link] [Clear Value on Failed Sync]
        // [SCENARIO 230754] NAV to CRM sync field with "Clear Value on Failed Sync"=Yes makes field empty and does not cause error
        TestInit();

        // [GIVEN] Integration Field Mapping for "Primary Contact No." with "Clear on Fail"=Yes
        SetupPrimaryContactIntegrationFieldMapping(true);

        // [GIVEN] Customer 'CUST' coupled to 'CRMACC'
        // [GIVEN] Contact "CONT" not coupled
        // [GIVEN] Customer 'CUST' has Primary Contact No. = CONT
        CreateCoupledCustomerAndNotCoupledPrimaryContact(Customer, CRMAccount, Contact);

        // [GIVEN] Mock some value PrimaryContactId in 'CRMACC'
        CRMAccount.PrimaryContactId := CreateGuid();
        CRMAccount.Modify();

        // [WHEN] Customer is being synched
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [THEN] 'CRMACC' PrimaryContactId became empty
        Clear(NullGuid);
        CRMAccount.Find();
        CRMAccount.TestField(PrimaryContactId, NullGuid);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NAVtoCRMSyncClearValueOnFailedSyncNo()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        JobQueueEntryID: Guid;
        SavedPrimaryContactId: Guid;
    begin
        // [FEATURE] [Customer-Contact Link]
        // [SCENARIO 230754] NAV to CRM sync field with "Clear Value on Failed Sync"=No causes error and does not change field value
        TestInit();

        // [GIVEN] Integration Field Mapping for "Primary Contact No." with "Clear on Fail"=Yes
        SetupPrimaryContactIntegrationFieldMapping(false);

        // [GIVEN] Customer 'CUST' coupled to 'CRMACC'
        // [GIVEN] Contact "CONT" not coupled
        // [GIVEN] Customer 'CUST' has Primary Contact No. = CONT
        CreateCoupledCustomerAndNotCoupledPrimaryContact(Customer, CRMAccount, Contact);

        // [GIVEN] Mock some PrimaryContactId value in 'CRMACC'
        CRMAccount.PrimaryContactId := CreateGuid();
        CRMAccount.Modify();
        SavedPrimaryContactId := CRMAccount.PrimaryContactId;

        // [WHEN] Customer is being synched
        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        JobQueueEntryID :=
          CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);

        // [THEN] Job queue entry failed
        VerifyIntegrationSynchJobError(
          JobQueueEntryID,
          StrSubstNo('%1 %2 must be coupled', Customer.FieldName("Primary Contact No."), Customer."Primary Contact No."));

        // [THEN] CRM Integration Record, where "Last Synch. CRM Result" is 'Failure'
        CRMIntegrationRecord.FindByRecordID(Customer.RecordId);
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Failure);
        CRMIntegrationRecord.TestField("Last Synch. CRM Job ID", JobQueueEntryID);
        CRMIntegrationRecord.TestField("Last Synch. Result", CRMIntegrationRecord."Last Synch. Result"::" ");
        // [THEN] 'CRMACC' PrimaryContactId is not changed
        CRMAccount.Find();
        CRMAccount.TestField(PrimaryContactId, SavedPrimaryContactId);
    end;

    [Scope('OnPrem')]
    procedure CRMtoNAVSyncClearValueOnFailedSyncYes()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [FEATURE] [Customer-Contact Link] [Clear Value on Failed Sync]
        // [SCENARIO 230754] CRM to NAV sync field with "Clear Value on Failed Sync"=Yes makes field empty and does not cause error
        TestInit();

        // [GIVEN] Integration Field Mapping for "Primary Contact No." with "Clear on Fail"=Yes
        SetupPrimaryContactIntegrationFieldMapping(true);

        // [GIVEN] Customer 'CUST' coupled to 'CRMACC'
        // [GIVEN] Contact 'CONT' coupled TO "CRMCONT1"
        // [GIVEN] Contact 'CONT' defined as primary 'CUST' contact
        // [GIVEN] Customer and contact syncronized
        CreateCoupledCustomerAndCoupledPrimaryContact(Customer, CRMAccount, Contact);

        // [GIVEN] Not coupled CRM Contact 'CRMCONT2' defined as primary contact in CRM Account
        LibraryCRMIntegration.CreateCRMContact(CRMContact);
        CRMAccount.Validate(PrimaryContactId, CRMContact.ContactId);
        CRMAccount.ModifiedOn += 1000;
        CRMAccount.Modify();

        // [WHEN] CRM Account is being synched
        GetIntegrationTableMapping(IntegrationTableMapping, CRMAccount.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMAccount.AccountId, false, false);

        // [THEN] 'CUST' "Primary Contact No." became empty
        Customer.Find();
        Customer.TestField("Primary Contact No.", '');
    end;

    [Test]
    //Reenabled in https://dev.azure.com/dynamicssmb2/Dynamics%20SMB/_workitems/edit/368425
    [Scope('OnPrem')]
    procedure CRMtoNAVSyncClearValueOnFailedSyncNo()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        JobQueueEntryID: Guid;
    begin
        // [FEATURE] [Customer-Contact Link]
        // [SCENARIO 230754] CRM to NAV sync field with "Clear Value on Failed Sync"=No causes error and does not change field value
        TestInit();

        // [GIVEN] Integration Field Mapping for "Primary Contact No." with "Clear on Fail"=No
        SetupPrimaryContactIntegrationFieldMapping(false);

        // [GIVEN] Customer 'CUST' coupled to 'CRMACC'
        // [GIVEN] Contact 'CONT' coupled TO "CRMCONT1"
        // [GIVEN] Contact 'CONT' defined as primary 'CUST' contact
        // [GIVEN] Customer and contact syncronized
        CreateCoupledCustomerAndCoupledPrimaryContact(Customer, CRMAccount, Contact);
        // [GIVEN] CRM Integration Record, where "Last Synch. CRM Result" is 'Success'
        CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId);
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Success);

        // [GIVEN] Not coupled CRM Contact 'CRMCONT2' defined as primary contact in CRM Account
        LibraryCRMIntegration.CreateCRMContact(CRMContact);
        CRMAccount.Validate(PrimaryContactId, CRMContact.ContactId);
        CRMAccount.ModifiedOn += 1000;
        CRMAccount.Modify();

        // [WHEN] CRM Account is being synched
        GetIntegrationTableMapping(IntegrationTableMapping, CRMAccount.RecordId);
        JobQueueEntryID :=
          CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMAccount.AccountId, false, false);

        // [THEN] Job queue entry failed
        VerifyIntegrationSynchJobError(
          JobQueueEntryID,
          StrSubstNo('%1 %2 must be coupled', CRMAccount.FieldCaption(PrimaryContactId), CRMAccount.PrimaryContactId));
        // [THEN] CRM Integration Record, where "Last Synch. Result" is 'Failure', "Last Synch. CRM Result" is 'Success'
        CRMIntegrationRecord.Find();
        CRMIntegrationRecord.TestField("Last Synch. Result", CRMIntegrationRecord."Last Synch. Result"::Failure);
        CRMIntegrationRecord.TestField("Last Synch. Job ID", JobQueueEntryID);
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Success);

        // [THEN] 'CUST' "Primary Contact No." is not changed
        Customer.Find();
        Customer.TestField("Primary Contact No.", Contact."No.");
    end;

    [Test]
    [HandlerFunctions('CreateNewCouplingRecordPageHandler,SyncStartedNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CoupleContactAndCustomerWithPrimaryContactBothAsCreateNew()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
    begin
        // [FEATURE] [Customer-Contact Link] [UI]
        // [SCENARIO 230754] User is able to couple not coupled customer and its primary contact in sequence: first contact, second customer
        TestInit();
        EnableConnection();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();

        // [GIVEN] Contact 'CONT'
        LibraryCRMIntegration.CreateContact(Contact);

        // [GIVEN] Customer 'CUST' with Primary Contact No = 'CONT'
        LibrarySales.CreateCustomer(Customer);
        SetCustomerPrimaryContact(Customer, Contact);

        // [GIVEN] Couple 'CONT' with "Create New" to CRM Contact 'CRMCONT'
        CoupleContactWithNewCRMContact(Contact, CRMContact);

        // [WHEN] 'CUST' is being coupled with "Create New" to CRM Account 'CRMACC'
        CoupleCustomerWithNewCRMAccount(Customer, CRMAccount);

        // [THEN] 'CRMACC' has PrimaryContactId = ContactId of 'CRMCONT'
        CRMAccount.TestField(PrimaryContactId, CRMContact.ContactId);
    end;

    local procedure TestInit()
    begin
        TestInit(false, false);
    end;

    local procedure TestInit(EnableExtendedPrice: Boolean; EnableUnitGroupMapping: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        RecordLink: Record "Record Link";
        MyNotifications: Record "My Notifications";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
    begin
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        if EnableExtendedPrice then
            LibraryPriceCalculation.EnableExtendedPriceCalculation();

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibraryTemplates.EnableTemplatesFeature();

        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID(), '', '', false);

        // Enable CRM Integration with Integration Table Mappings
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Unit Group Mapping Enabled" := EnableUnitGroupMapping;
        CRMConnectionSetup.Modify();
        ResetDefaultCRMSetupConfiguration();

        RecordLink.DeleteAll();
    end;

    local procedure EnableConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        CRMConnectionSetup.Get();
        CRMConnectionSetup.Validate("Is Enabled", true);
        CRMConnectionSetup.Modify();
    end;

    local procedure CoupleContactWithNewCRMContact(Contact: Record Contact; var CRMContact: Record "CRM Contact")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        ContactCard: TestPage "Contact Card";
        CRMID: Guid;
    begin
        ContactCard.OpenEdit();
        ContactCard.GotoRecord(Contact);
        ContactCard.ManageCRMCoupling.Invoke();

        Contact.SetRange(SystemId, Contact.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Contact, Contact.GetView(), IntegrationTableMapping);

        CRMIntegrationRecord.FindIDFromRecordID(Contact.RecordId, CRMID);
        CRMContact.Get(CRMID);
    end;

    local procedure CoupleCustomerWithNewCRMAccount(Customer: Record Customer; var CRMAccount: Record "CRM Account")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMID: Guid;
    begin
        CRMIntegrationManagement.CreateNewRecordsInCRM(Customer.RecordId);
        Customer.SetRange(SystemId, Customer.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::Customer, Customer.GetView(), IntegrationTableMapping);

        CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId, CRMID);
        CRMAccount.Get(CRMID);
    end;

    [Scope('OnPrem')]
    procedure CreateCRMAccountCoupledToCustomerWithContact(var CRMAccount: Record "CRM Account")
    var
        CompanyContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
    begin
        LibraryMarketing.CreateCompanyContact(CompanyContact);
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateCustomerFromTemplate('');
        ContactBusinessRelation.SetRange("Contact No.", CompanyContact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.FindFirst();
        Customer.Get(ContactBusinessRelation."No.");
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Customer.RecordId, CRMAccount.AccountId);
    end;

    local procedure CreateCoupledCustomerAndNotCoupledPrimaryContact(var Customer: Record Customer; var CRMAccount: Record "CRM Account"; var Contact: Record Contact)
    begin
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        LibraryCRMIntegration.CreateContact(Contact);
        SetCustomerPrimaryContact(Customer, Contact);
    end;

    local procedure CreateCoupledCustomerAndCoupledPrimaryContact(var Customer: Record Customer; var CRMAccount: Record "CRM Account"; var Contact: Record Contact)
    var
        CRMContact: Record "CRM Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);

        SetCustomerPrimaryContact(Customer, Contact);

        GetIntegrationTableMapping(IntegrationTableMapping, Customer.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Customer.RecordId, true, false);
        GetIntegrationTableMapping(IntegrationTableMapping, Contact.RecordId);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Contact.RecordId, true, false);
    end;

    local procedure CreateNewCustomerFromCRMAccount(CRMAccount: Record "CRM Account")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMAccount.SetRange(AccountId, CRMAccount.AccountId);
        CRMIntegrationManagement.CreateNewRecordsFromCRM(CRMAccount);
        LibraryCRMIntegration.RunJobQueueEntry(DATABASE::"CRM Account", CRMAccount.GetView(), IntegrationTableMapping);
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

    local procedure RunGoToProductActionOnItemList(Item: Record Item; var IntegrationTableMapping: Record "Integration Table Mapping"): Guid
    var
        ItemList: TestPage "Item List";
    begin
        ItemList.OpenView();
        ItemList.GotoRecord(Item);

        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        ItemList.CRMGoToProduct.Invoke();
        Item.SetRange(SystemId, Item.SystemId);
        exit(LibraryCRMIntegration.RunJobQueueEntry(DATABASE::Item, Item.GetView(), IntegrationTableMapping));
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

    local procedure FindCompanyContact(CustomerNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, CustomerNo);
        exit(ContactBusinessRelation."Contact No.");
    end;

    local procedure FindCoupledCustomer(CRMAccountID: Guid; var Customer: Record Customer) IsCoupled: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecID: RecordID;
        RecRef: RecordRef;
    begin
        IsCoupled := CRMIntegrationRecord.FindRecordIDFromID(CRMAccountID, DATABASE::Customer, RecID);
        RecRef.Get(RecID);
        RecRef.SetTable(Customer);
    end;

    local procedure GetCustomerTableMappingName(): Code[20]
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, Database::Customer);
        exit(IntegrationTableMapping.Name);
    end;

    local procedure FindPrimaryContactIntegrationFieldMapping(var IntegrationFieldMapping: Record "Integration Field Mapping"): Boolean
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", GetCustomerTableMappingName());
        IntegrationFieldMapping.SetRange("Field No.", Customer.FieldNo("Primary Contact No."));
        IntegrationFieldMapping.SetRange("Integration Table Field No.", CRMAccount.FieldNo(PrimaryContactId));
        exit(IntegrationFieldMapping.FindFirst())
    end;

    local procedure SetCustomerPrimaryContact(var Customer: Record Customer; var Contact: Record Contact)
    begin
        Contact.Validate("Company No.", FindCompanyContact(Customer."No."));
        Contact.Modify();

        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify();
    end;

    local procedure SetCRMAccountPrimaryContact(var CRMAccount: Record "CRM Account"; CRMContactNo: Guid)
    begin
        CRMAccount.Validate(PrimaryContactId, CRMContactNo);
        CRMAccount.ModifiedOn += 1000;
        CRMAccount.Modify();
    end;

    local procedure SetupPrimaryContactIntegrationFieldMapping(ClearValueOnFailedSync: Boolean)
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        if not FindPrimaryContactIntegrationFieldMapping(IntegrationFieldMapping) then
            IntegrationFieldMapping.CreateRecord(
              GetCustomerTableMappingName(),
              Customer.FieldNo("Primary Contact No."),
              CRMAccount.FieldNo(PrimaryContactId),
              IntegrationFieldMapping.Direction::Bidirectional,
              '', true, false);
        IntegrationFieldMapping."Clear Value on Failed Sync" := ClearValueOnFailedSync;
        IntegrationFieldMapping.Modify();
    end;

    local procedure VerifyIntegrationSynchJobError(IntegrationSynchJobID: Guid; ExpectedErrorMessage: Text)
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", IntegrationSynchJobID);
        IntegrationSynchJobErrors.FindFirst();
        Assert.ExpectedMessage(ExpectedErrorMessage, IntegrationSynchJobErrors.Message);
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMAccountListModalHandler(var CRMAccountListPage: TestPage "CRM Account List")
    begin
        Assert.IsTrue(
          CRMAccountListPage.FindFirstField(Name, LibraryVariableStorage.DequeueText()),
          'CRM Account is not found in the list page');
        CRMAccountListPage.CreateFromCRM.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMContactListModalHandler(var CRMContactListPage: TestPage "CRM Contact List")
    begin
        Assert.IsTrue(
          CRMContactListPage.FindFirstField(EMailAddress1, LibraryVariableStorage.DequeueText()),
          'CRM Contact is not found in the list page');
        CRMContactListPage.CreateFromCRM.Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(SyncStartedMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalespersonPurchaserModalPageHandler(var SalespersonsPurchasers: TestPage "Salespersons/Purchasers")
    var
        SalespersonCodeVAR: Variant;
        SalespersonCode: Code[20];
    begin
        LibraryVariableStorage.Dequeue(SalespersonCodeVAR);
        SalespersonCode := SalespersonCodeVAR;
        SalespersonsPurchasers.GotoKey(SalespersonCode);
        SalespersonsPurchasers.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMCouplingRecordModalPageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.CRMName.Lookup();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMSystemuserCouplingControlModalPageHandler(var CRMSystemuserList: TestPage "CRM Systemuser List")
    begin
        LibraryVariableStorage.Enqueue(CRMSystemuserList.Couple.Visible());
        LibraryVariableStorage.Enqueue(CRMSystemuserList.DeleteCDSCoupling.Visible());
        LibraryVariableStorage.Enqueue(CRMSystemuserList.CreateFromCRM.Visible());
        LibraryVariableStorage.Enqueue(CRMSystemuserList.SalespersonPurchaserCode.Editable());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetCouplingRecordPageHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.CRMName.SetValue(LibraryVariableStorage.DequeueText());
        CRMCouplingRecord.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SynchCustomerStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := SyncAction;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}
