codeunit 139174 "CRM Coupling Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [UI] [CRM Coupling Record]
    end;

    var
        CoupleToCRMAccount: Record "CRM Account";
        SelectCRMAccount: Record "CRM Account";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        SyncAction: Option DoNotSync,PushToCRM,PushToNAV;
        CreateNewValueToSet: Boolean;
        SyncActionToSet: Option;
        CouplingErr: Label 'Wrong coupling.';
        CRMRecordsListErr: Label 'Wrong number of entries in the list.';
        CRMRecordErr: Label 'Wrong record in the list.';
        WrongControlVisibilityErr: Label 'Wrong control visiblity.';

    [Test]
    [Scope('OnPrem')]
    procedure BidirectionalDefaultSynchToCRMIfNotCoupled()
    var
        Customer: Record Customer;
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The Customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Open CRM Coupling Record page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);

        // [THEN] "NAV Name" is not blank, NOT editable; SyncAction is "Push To CRM"
        Assert.AreEqual(Customer.Name, CRMCouplingRecord.NAVName.Value, 'NAV Name should not be blank');
        Assert.IsFalse(CRMCouplingRecord.NAVName.Editable(), 'NAV Name should not be EDITABLE');
        Assert.AreEqual(SyncAction::PushToCRM, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'Different value expected in the synch action control');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDoNotSyncIfCoupled()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The Customer coupled to the CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [WHEN] Open CRM Coupling Record page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);

        // [THEN] SyncAction is "Do Not Sync"
        Assert.AreEqual(SyncAction::DoNotSync, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'Different value expected in the synch action control');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckingCreateNewInCRM()
    var
        Customer: Record Customer;
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The Customer
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Open CRM Coupling Record page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);
        // [GIVEN] SyncAction is set to "Do Not Sync"
        CRMCouplingRecord.SyncActionControl.SetValue(SyncAction::DoNotSync);
        // [WHEN] Set "Create New" to "Yes"
        CRMCouplingRecord.CreateNewControl.SetValue(true);

        // [THEN] SyncAction is "Push To CRM"
        Assert.AreEqual(SyncAction::PushToCRM, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When checking the "Create New in CRM" box, the synchronization action should be changed to "Push to CRM"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckingCreateNewOnCoupledRecords()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The Customer coupled to the CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Open CRM Coupling Record page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);
        // [GIVEN] SyncAction is set to "Do Not Sync"
        CRMCouplingRecord.SyncActionControl.SetValue(SyncAction::DoNotSync);
        // [WHEN] Set "Create New" to "Yes"
        CRMCouplingRecord.CreateNewControl.SetValue(true);

        // [THEN] SyncAction is "Push To CRM"
        Assert.AreEqual(SyncAction::PushToCRM, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When checking the "Create New in CRM" box, the synchronization action should be changed to "Push to CRM"');
        // [THEN] "CRM Name" is blank and NOT editable
        Assert.AreEqual('', CRMCouplingRecord.CRMName.Value, 'CRM Name should be blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UncheckingCreateNewInCRM()
    var
        Customer: Record Customer;
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] Open Coupling Record page for the Customer
        LibrarySales.CreateCustomer(Customer);
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);

        CRMCouplingRecord.SyncActionControl.SetValue(SyncAction::DoNotSync);
        // [WHEN] Set "Create New" to "Yes"
        CRMCouplingRecord.CreateNewControl.SetValue(true);
        // [THEN] Sync Action and CRM Name controls are not enabled
        VerifyControlsEnabledByCreateNew(CRMCouplingRecord);

        // [WHEN] Set "Create New" to "No"
        CRMCouplingRecord.CreateNewControl.SetValue(false);
        // [THEN] Sync Action and CRM Name controls are enabled
        Assert.AreEqual(SyncAction::DoNotSync, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When unchecking the "Create New in CRM" checkbox, the synchronization action should be reverted to what it was before');
        VerifyControlsEnabledByCreateNew(CRMCouplingRecord);

        // [GIVEN] SyncAction is "Push To CRM"
        CRMCouplingRecord.SyncActionControl.SetValue(SyncAction::PushToCRM);
        // [WHEN] Set "Create New" to "Yes" and back to "No"
        CRMCouplingRecord.CreateNewControl.SetValue(true);
        CRMCouplingRecord.CreateNewControl.SetValue(false);

        // [THEN] SyncAction is "Push To CRM"
        Assert.AreEqual(SyncAction::PushToCRM, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When unchecking the "Create New in CRM" checkbox, the synchronization action should be reverted to what it was before');
        VerifyControlsEnabledByCreateNew(CRMCouplingRecord);

        // [GIVEN] SyncAction is "Push To NAV"
        CRMCouplingRecord.SyncActionControl.SetValue(SyncAction::PushToNAV);
        // [WHEN] Set "Create New" to "Yes" and back to "No"
        CRMCouplingRecord.CreateNewControl.SetValue(true);
        CRMCouplingRecord.CreateNewControl.SetValue(false);

        // [THEN] SyncAction is "Push To NAV"
        Assert.AreEqual(SyncAction::PushToNAV, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When unchecking the "Create New in CRM" checkbox, the synchronization action should be reverted to what it was before');
        VerifyControlsEnabledByCreateNew(CRMCouplingRecord);
    end;

    [Test]
    [HandlerFunctions('CRMContactListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordForContact()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        OtherCRMContact: Record "CRM Contact";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The CRM Contact "A"
        LibraryCRMIntegration.CreateCRMContact(OtherCRMContact);
        // [GIVEN] The Contact coupled to the CRM Contact "B"
        LibraryCRMIntegration.CreateCoupledContactAndContact(Contact, CRMContact);
        // [GIVEN] Open Coupling Record page for the Contact
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Contact.RecordId);
        // [GIVEN] Lookup "CRM Name"
        // [GIVEN] CRM Contact List page open, where focus is on CRM Contact "B"
        LibraryVariableStorage.Enqueue(CRMContact.FullName);
        LibraryVariableStorage.Enqueue(OtherCRMContact.FullName);
        CRMCouplingRecord.CRMName.Lookup();
        // [WHEN] Pick CRM Contact "A"
        // by CRMContactListHandler

        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(OtherCRMContact.FullName);
    end;

    [Test]
    [HandlerFunctions('CRMAccountListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordForCustomer()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        OtherCRMAccount: Record "CRM Account";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The CRM Account "A"
        LibraryCRMIntegration.CreateCRMAccount(OtherCRMAccount);
        // [GIVEN] The Customer coupled to the CRM Account "B"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] Open Coupling Record page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);

        // [GIVEN] Lookup "CRM Name"
        // [GIVEN] CRM Account List page open, where focus is on CRM Account "B"
        LibraryVariableStorage.Enqueue(CRMAccount.Name);
        LibraryVariableStorage.Enqueue(OtherCRMAccount.Name);
        CRMCouplingRecord.CRMName.Lookup();
        // [WHEN] Pick CRM Account "A"
        // by CRMAccountListHandler

        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(OtherCRMAccount.Name);
    end;

    [Test]
    [HandlerFunctions('CRMSystemuserListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordForSalesperson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        OtherCRMSystemuser: Record "CRM Systemuser";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The CRM Systemuser "A"
        LibraryCRMIntegration.CreateCRMSystemUser(OtherCRMSystemuser);
        // [GIVEN] The Salesperson coupled to the CRM Systemuser "B"
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        // [GIVEN] Open Coupling Record page for the Salesperson
        OpenCRMCouplingRecordPage(CRMCouplingRecord, SalespersonPurchaser.RecordId);

        // [GIVEN] Lookup "CRM Name"
        // [GIVEN] CRM Systemuser List page open, where focus is on CRM Systemuser "B"
        LibraryVariableStorage.Enqueue(CRMSystemuser.FullName);
        LibraryVariableStorage.Enqueue(OtherCRMSystemuser.FullName);
        CRMCouplingRecord.CRMName.Lookup();
        // [WHEN] Pick CRM Systemuser "A"
        // by CRMSystemuserListHandler

        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(OtherCRMSystemuser.FullName);
    end;

    [Test]
    [HandlerFunctions('CRMCurrencyListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordForCurrency()
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        OtherCRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The CRM Transactioncurrency "A"
        LibraryCRMIntegration.CreateCRMTransactionCurrency(OtherCRMTransactioncurrency, 'AAA');
        // [GIVEN] The Currency coupled to the CRM Transactioncurrency "B"
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        // [GIVEN] Open Coupling Record page for the Currency
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Currency.RecordId);

        // [GIVEN] Lookup "CRM Name"
        // [GIVEN] CRM Transactioncurrency List page open, where focus is on CRM Transactioncurrency "B"
        LibraryVariableStorage.Enqueue(CRMTransactioncurrency.ISOCurrencyCode);
        LibraryVariableStorage.Enqueue(OtherCRMTransactioncurrency.ISOCurrencyCode);
        CRMCouplingRecord.CRMName.Lookup();
        // [WHEN] Pick CRM Transactioncurrency "A"
        // by CRMCurrencyListHandler

        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(OtherCRMTransactioncurrency.ISOCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('CRMPriceListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordForCustomerPriceGroup()
    var
        Currency: Record Currency;
        CustomerPriceGroup: Record "Customer Price Group";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMPricelevel: Record "CRM Pricelevel";
        OtherCRMPricelevel: Record "CRM Pricelevel";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The CRM Pricelevel "A"
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        LibraryCRMIntegration.CreateCRMPriceList(OtherCRMPricelevel, CRMTransactioncurrency);
        // [GIVEN] The Customer Price Group coupled to the CRM Pricelevel "B"
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);
        // [GIVEN] Open Coupling Record page for the Customer Price Group
        OpenCRMCouplingRecordPage(CRMCouplingRecord, CustomerPriceGroup.RecordId);

        // [GIVEN] Lookup "CRM Name"
        // [GIVEN] CRM Pricelevel List page open, where focus is on CRM Pricelevel "B"
        LibraryVariableStorage.Enqueue(CRMPricelevel.Name);
        LibraryVariableStorage.Enqueue(OtherCRMPricelevel.Name);
        CRMCouplingRecord.CRMName.Lookup();
        // [WHEN] Pick CRM Pricelevel "A"
        // by CRMPriceListHandler

        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(OtherCRMPricelevel.Name);
    end;

    [Test]
    [HandlerFunctions('CRMProductListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordForItem()
    var
        Currency: Record Currency;
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMProduct: Record "CRM Product";
        OtherCRMProduct: Record "CRM Product";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The Item coupled to the CRM Product "B"
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        // [GIVEN] The CRM Product "A"
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);
        LibraryCRMIntegration.CreateCRMProduct(OtherCRMProduct, CRMTransactioncurrency, CRMUom);
        // [GIVEN] Open Coupling Record page for the Item
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Item.RecordId);

        // [GIVEN] Lookup "CRM Name"
        // [GIVEN] CRM Product List page open, where focus is on CRM Product "B"
        LibraryVariableStorage.Enqueue(CRMProduct.ProductNumber);
        LibraryVariableStorage.Enqueue(OtherCRMProduct.ProductNumber);
        CRMCouplingRecord.CRMName.Lookup();
        // [WHEN] Pick CRM Product "A"
        // by CRMProductListHandler

        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(OtherCRMProduct.ProductNumber);
    end;

    [Test]
    [HandlerFunctions('CRMProductListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordForResource()
    var
        Currency: Record Currency;
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMProduct: Record "CRM Product";
        OtherCRMProduct: Record "CRM Product";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The Resource coupled to the CRM Product "B"
        LibraryCRMIntegration.CreateCoupledResourceAndProduct(Resource, CRMProduct);
        // [GIVEN] The CRM Product "A"
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);
        LibraryCRMIntegration.CreateCRMProduct(OtherCRMProduct, CRMTransactioncurrency, CRMUom);
        // [GIVEN] Open Coupling Record page for the Resource
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Resource.RecordId);

        // [GIVEN] Lookup "CRM Name"
        // [GIVEN] CRM Product List page open, where focus is on CRM Product "B"
        LibraryVariableStorage.Enqueue(CRMProduct.ProductNumber);
        LibraryVariableStorage.Enqueue(OtherCRMProduct.ProductNumber);
        CRMCouplingRecord.CRMName.Lookup();
        // [WHEN] Pick CRM Product "A"
        // by CRMProductListHandler

        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(OtherCRMProduct.ProductNumber);
    end;

    [Test]
    [HandlerFunctions('CRMUomListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordForUOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        OtherCRMUom: Record "CRM Uom";
        OtherCRMUomschedule: Record "CRM Uomschedule";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The CRM Uomschedule "A"
        OtherCRMUom.Init();
        OtherCRMUom.Name := 'AAA';
        LibraryCRMIntegration.CreateCRMUomAndUomSchedule(OtherCRMUom, OtherCRMUomschedule);
        // [GIVEN] The Unit Of Measure coupled to the CRM Uomschedule "B"
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);

        // [GIVEN] Open Coupling Record page for the Unit Of Measure
        OpenCRMCouplingRecordPage(CRMCouplingRecord, UnitOfMeasure.RecordId);

        // [GIVEN] Lookup "CRM Name"
        // [GIVEN] CRM Product List page open, where focus is on CRM Uomschedule "B"
        LibraryVariableStorage.Enqueue(CRMUomschedule.Name);
        LibraryVariableStorage.Enqueue(OtherCRMUomschedule.Name);
        CRMCouplingRecord.CRMName.Lookup();
        // [WHEN] Pick CRM Product "A"
        // by CRMUomListHandler

        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(OtherCRMUomschedule.Name);
    end;

    [Test]
    [HandlerFunctions('CRMOpportunityListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordForOpportunity()
    var
        OtherCRMOpportunity: Record "CRM Opportunity";
        Opportunity: Record Opportunity;
        CRMOpportunity: Record "CRM Opportunity";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The CRM Opportunity "A"
        LibraryCRMIntegration.CreateCRMOpportunity(OtherCRMOpportunity);
        // [GIVEN] The Opportunity coupled to the CRM Opportunity "B"
        LibraryCRMIntegration.CreateCoupledOpportunityAndOpportunity(Opportunity, CRMOpportunity);
        // [GIVEN] Open Coupling Record page for the Opportunity
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Opportunity.RecordId);
        // [GIVEN] Lookup "CRM Name"
        // [GIVEN] CRM Opportunity List page open, where focus is on CRM Opportunity "B"
        LibraryVariableStorage.Enqueue(CRMOpportunity.Name);
        LibraryVariableStorage.Enqueue(OtherCRMOpportunity.Name);
        CRMCouplingRecord.CRMName.Lookup();
        // [WHEN] Pick CRM Opportunity "A"
        // by CRMContactListHandler

        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(OtherCRMOpportunity.Name);
    end;

    [Test]
    [HandlerFunctions('FilteredCRMAccountListHandler')]
    [Scope('OnPrem')]
    procedure LookupFilteredCRMRecordForAccount()
    var
        Customer: Record Customer;
        CRMAccount: array[3] of Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] Intergration Table Mapping for Customer
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::Customer, DATABASE::"CRM Account",
          CRMAccount[1].FieldNo(AccountId), CRMAccount[1].FieldNo(ModifiedOn),
          Customer.FieldNo(Name), CRMAccount[1].FieldNo(Name));
        // [GIVEN] Customer "C"
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] CRM Account "A"
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount[2]);
        LibraryVariableStorage.Enqueue(CRMAccount[2].Name);
        // [GIVEN] CRM Account "B"
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount[3]);
        // [GIVEN] Integration Table Filter with "A" only
        CRMAccount[1].SetRange(AccountId, CRMAccount[2].AccountId);
        SetIntTableFilter(IntegrationTableMapping, CRMAccount[1].GetView());
        // [GIVEN] Coupling Record page for "C"
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);
        // [WHEN] Lookup "CRM Name"
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] CRM Account list contains only "A"
        // FilteredCRMAccountListHandler
    end;

    [Test]
    [HandlerFunctions('FilteredCRMContactListHandler')]
    [Scope('OnPrem')]
    procedure LookupFilteredCRMRecordForContact()
    var
        Contact: Record Contact;
        CRMContact: array[3] of Record "CRM Contact";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] Intergration Table Mapping for Contact
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::Contact, DATABASE::"CRM Contact",
          CRMContact[1].FieldNo(ContactId), CRMContact[1].FieldNo(ModifiedOn),
          Contact.FieldNo(Name), CRMContact[1].FieldNo(FullName));
        // [GIVEN] Contact "C"
        LibraryMarketing.CreatePersonContact(Contact);
        // [GIVEN] CRM Contact "A"
        LibraryCRMIntegration.CreateCRMContact(CRMContact[2]);
        LibraryVariableStorage.Enqueue(CRMContact[2].FullName);
        // [GIVEN] CRM Contact "B"
        LibraryCRMIntegration.CreateCRMContact(CRMContact[3]);
        // [GIVEN] Integration Table Filter with "A" only
        CRMContact[1].SetRange(ContactId, CRMContact[2].ContactId);
        SetIntTableFilter(IntegrationTableMapping, CRMContact[1].GetView());
        // [GIVEN] Coupling Record page for "C"
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Contact.RecordId);
        // [WHEN] Lookup "CRM Name"
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] CRM Contact list contains only "A"
        // FilteredCRMContactListHandler
    end;

    [Test]
    [HandlerFunctions('FilteredCRMSystemuserListHandler')]
    [Scope('OnPrem')]
    procedure LookupFilteredCRMRecordForSalesperson()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: array[3] of Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] Intergration Table Mapping for Salesperson
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser",
          CRMSystemuser[1].FieldNo(SystemUserId), CRMSystemuser[1].FieldNo(ModifiedOn),
          SalespersonPurchaser.FieldNo(Name), CRMSystemuser[1].FieldNo(FullName));
        // [GIVEN] Salesperson "C"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        // [GIVEN] CRM Systemuser "A"
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser[2]);
        LibraryVariableStorage.Enqueue(CRMSystemuser[2].FullName);
        // [GIVEN] CRM Systemuser "B"
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser[3]);
        // [GIVEN] Integration Table Filter with "A" only
        CRMSystemuser[1].SetRange(SystemUserId, CRMSystemuser[2].SystemUserId);
        SetIntTableFilter(IntegrationTableMapping, CRMSystemuser[1].GetView());
        // [GIVEN] Coupling Record page for "C"
        OpenCRMCouplingRecordPage(CRMCouplingRecord, SalespersonPurchaser.RecordId);
        // [WHEN] Lookup "CRM Name"
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] CRM CRMSystemuser list contains only "A"
        // FilteredCRMSystemuserListHandler
    end;

    [Test]
    [HandlerFunctions('FilteredCRMCurrencyListHandler')]
    [Scope('OnPrem')]
    procedure LookupFilteredCRMRecordForCurrency()
    var
        Currency: Record Currency;
        CRMTransactioncurrency: array[3] of Record "CRM Transactioncurrency";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] Intergration Table Mapping for Currency
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::Currency, DATABASE::"CRM Transactioncurrency",
          CRMTransactioncurrency[1].FieldNo(TransactionCurrencyId), CRMTransactioncurrency[1].FieldNo(ModifiedOn),
          Currency.FieldNo(Code), CRMTransactioncurrency[1].FieldNo(ISOCurrencyCode));
        // [GIVEN] Currency "C"
        LibraryERM.CreateCurrency(Currency);
        // [GIVEN] CRM Transactioncurrency "A"
        LibraryCRMIntegration.CreateCRMTransactionCurrency(
          CRMTransactioncurrency[2],
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(CRMTransactioncurrency[2].ISOCurrencyCode)),
            1, MaxStrLen(CRMTransactioncurrency[2].ISOCurrencyCode)));
        LibraryVariableStorage.Enqueue(CRMTransactioncurrency[2].ISOCurrencyCode);
        // [GIVEN] CRM Transactioncurrency "B"
        LibraryCRMIntegration.CreateCRMTransactionCurrency(
          CRMTransactioncurrency[3],
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(CRMTransactioncurrency[3].ISOCurrencyCode)),
            1, MaxStrLen(CRMTransactioncurrency[3].ISOCurrencyCode)));
        // [GIVEN] Integration Table Filter with "A" only
        CRMTransactioncurrency[1].SetRange(TransactionCurrencyId, CRMTransactioncurrency[2].TransactionCurrencyId);
        SetIntTableFilter(IntegrationTableMapping, CRMTransactioncurrency[1].GetView());
        // [GIVEN] Coupling Record page for "C"
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Currency.RecordId);
        // [WHEN] Lookup "CRM Name"
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] CRM Transactioncurrency list contains only "A"
        // FilteredCRMCurrencyListHandler
    end;

    [Test]
    [HandlerFunctions('FilteredCRMPriceListHandler')]
    [Scope('OnPrem')]
    procedure LookupFilteredCRMRecordForCustomerPriceGroup()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        CRMPricelevel: array[3] of Record "CRM Pricelevel";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] Intergration Table Mapping for Customer Price Group
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::"Customer Price Group", DATABASE::"CRM Pricelevel",
          CRMPricelevel[1].FieldNo(PriceLevelId), CRMPricelevel[1].FieldNo(ModifiedOn),
          CustomerPriceGroup.FieldNo(Code), CRMPricelevel[1].FieldNo(Name));
        // [GIVEN] Customer Price Group "C"
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        // [GIVEN] CRM Pricelevel "A"
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        LibraryCRMIntegration.CreateCRMPriceList(CRMPricelevel[2], CRMTransactioncurrency);
        LibraryVariableStorage.Enqueue(CRMPricelevel[2].Name);
        // [GIVEN] CRM Pricelevel "B"
        LibraryCRMIntegration.CreateCRMPriceList(CRMPricelevel[3], CRMTransactioncurrency);
        // [GIVEN] Integration Table Filter with "A" only
        CRMPricelevel[1].SetRange(PriceLevelId, CRMPricelevel[2].PriceLevelId);
        SetIntTableFilter(IntegrationTableMapping, CRMPricelevel[1].GetView());
        // [GIVEN] Coupling Record page for "C"
        OpenCRMCouplingRecordPage(CRMCouplingRecord, CustomerPriceGroup.RecordId);
        // [WHEN] Lookup "CRM Name"
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] CRM Pricelist list contains only "A"
        // FilteredCRMPriceListHandler
    end;

    [Test]
    [HandlerFunctions('FilteredCRMProductListHandler')]
    [Scope('OnPrem')]
    procedure LookupFilteredCRMRecordForItem()
    var
        Item: Record Item;
        CRMProduct: array[3] of Record "CRM Product";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] Intergration Table Mapping for Item
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::Item, DATABASE::"CRM Product",
          CRMProduct[1].FieldNo(ProductId), CRMProduct[1].FieldNo(ModifiedOn),
          Item.FieldNo(Description), CRMProduct[1].FieldNo(Name));
        // [GIVEN] Item "C"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] CRM Product "A" of SalesInventory type
        // [GIVEN] CRM Product "B" of Services type
        CreateCRMProducts(CRMProduct);
        LibraryVariableStorage.Enqueue(CRMProduct[2].Name);
        // [GIVEN] Integration Table Filter with "A" only
        CRMProduct[1].SetRange(ProductTypeCode, CRMProduct[2].ProductTypeCode);
        SetIntTableFilter(IntegrationTableMapping, CRMProduct[1].GetView());
        // [GIVEN] Coupling Record page for "C"
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Item.RecordId);
        // [WHEN] Lookup "CRM Name"
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] CRM Product list contains only "A"
        // FilteredCRMProductListHandler
    end;

    [Test]
    [HandlerFunctions('FilteredCRMProductListHandler')]
    [Scope('OnPrem')]
    procedure LookupFilteredCRMRecordForResource()
    var
        Resource: Record Resource;
        CRMProduct: array[3] of Record "CRM Product";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] Intergration Table Mapping for Resource
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::Resource, DATABASE::"CRM Product",
          CRMProduct[1].FieldNo(ProductId), CRMProduct[1].FieldNo(ModifiedOn),
          Resource.FieldNo(Name), CRMProduct[1].FieldNo(Name));
        // [GIVEN] Resource "C"
        LibraryResource.CreateResource(Resource, '');
        // [GIVEN] CRM Product "A" of SalesInventory type
        // [GIVEN] CRM Product "B" of Services type
        CreateCRMProducts(CRMProduct);
        LibraryVariableStorage.Enqueue(CRMProduct[3].Name);
        // [GIVEN] Integration Table Filter with "B" only
        CRMProduct[1].SetRange(ProductTypeCode, CRMProduct[3].ProductTypeCode);
        SetIntTableFilter(IntegrationTableMapping, CRMProduct[1].GetView());
        // [GIVEN] Coupling Record page for "C"
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Resource.RecordId);
        // [WHEN] Lookup "CRM Name"
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] CRM Product list contains only "B"
        // FilteredCRMProductListHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypingCRMAccountName()
    var
        Customer: Record Customer;
        OriginallyCoupledCRMAccount: Record "CRM Account";
        OtherCRMAccount: Record "CRM Account";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        ResetDefaultCRMSetupConfiguration();
        // [GIVEN] The Customer coupled to the CRM Account "A"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, OriginallyCoupledCRMAccount);
        // [GIVEN] The CRM Account "B"
        LibraryCRMIntegration.CreateCRMAccount(OtherCRMAccount);

        // [GIVEN] Open CRM Coupling Record page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);

        // [GIVEN] SyncAction is "Push To NAV"
        CRMCouplingRecord.SyncActionControl.SetValue(SyncAction::PushToNAV);

        // [WHEN] Set "CRM Name" to "B"
        CRMCouplingRecord.CRMName.SetValue(OtherCRMAccount.Name);
        // [THEN] SyncAction is "Push To NAV"
        Assert.AreEqual(SyncAction::PushToNAV, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When entering the name of a different CRM Account to couple to, nothing should change');

        // [WHEN] Set "CRM Name" back to "A"
        CRMCouplingRecord.CRMName.SetValue(OriginallyCoupledCRMAccount.Name);
        // [THEN] SyncAction is "Push To NAV"
        Assert.AreEqual(SyncAction::PushToNAV, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When entering the name of the already coupled CRM Account to couple to, nothing should change');

        // [WHEN] Set "CRM Name" to "A"
        CRMCouplingRecord.CRMName.SetValue(OriginallyCoupledCRMAccount.Name);
        // [THEN] SyncAction is "Push To NAV"
        Assert.AreEqual(SyncAction::PushToNAV, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When entering the same CRM Account name that was there before the edit, nothing should change');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypingIncompleteCRMAccountName()
    var
        Customer: Record Customer;
        CRMAccount1: Record "CRM Account";
        CRMAccount2: Record "CRM Account";
        CRMAccount3: Record "CRM Account";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        ResetDefaultCRMSetupConfiguration();
        // [GIVEN] The Customer
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] The CRM Account "A", where Name = 'CCCC'
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount1);
        CRMAccount1.Name := 'CCCC';
        CRMAccount1.Modify();
        // [GIVEN] The CRM Account "B", where Name = 'CC'
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount2);
        CRMAccount2.Name := 'CC';
        CRMAccount2.Modify();
        // [GIVEN] The CRM Account "C", where Name = 'X'
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount3);

        // [GIVEN] Open CRM Coupling Record page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);

        // [WHEN] Type 'C' in "CRM Name"
        CRMCouplingRecord.CRMName.SetValue('C');
        // [THEN] "CRM Name" is auto-completed to 'CC'
        Assert.AreEqual('CC', CRMCouplingRecord.CRMName.Value,
          'The CRM Account Name field should have ordered autocompletion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypingWrongCRMAccountName()
    var
        Customer: Record Customer;
        CRMProductName: Codeunit "CRM Product Name";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Open CRM Coupling Record page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);

        // [WHEN] Type the name of a non existing account
        asserterror CRMCouplingRecord.CRMName.SetValue('WrongName');
        // [THEN] Error message: "does not exist in Dynamics CRM."
        Assert.ExpectedError(StrSubstNo('does not exist in %1.', CRMProductName.CDSServiceName()));
    end;

    [Test]
    [HandlerFunctions('CRMCustomerListPageHandler')]
    [Scope('OnPrem')]
    procedure SelectingCRMAccount()
    var
        Customer: Record Customer;
        OriginallyCoupledCRMAccount: Record "CRM Account";
        LocalCRMAccount: Record "CRM Account";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        Initialize();
        // [GIVEN] The Customer coupled to the CRM Account "A"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, OriginallyCoupledCRMAccount);
        // [GIVEN] The CRM Account "B"
        LibraryCRMIntegration.CreateCRMAccount(LocalCRMAccount);
        CoupleToCRMAccount := LocalCRMAccount;

        // [GIVEN] Open CRM Coupling Record page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);

        // [GIVEN] SyncAction is "Push To NAV"
        CRMCouplingRecord.SyncActionControl.SetValue(SyncAction::PushToNAV);

        // [WHEN] Set "CRM Name" to "B" via lookup
        SelectCRMAccount := CoupleToCRMAccount;
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] "CRM Name" is "B"
        CRMCouplingRecord.CRMName.AssertEquals(SelectCRMAccount.Name);
        // [THEN] SyncAction is "Push To NAV"
        Assert.AreEqual(SyncAction::PushToNAV, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When entering the name of a different CRM Account to couple to, nothing should change');

        // [WHEN] Set "CRM Name" back to "A" via lookup
        SelectCRMAccount := OriginallyCoupledCRMAccount;
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(SelectCRMAccount.Name);
        // [THEN] SyncAction is "Push To NAV"
        Assert.AreEqual(SyncAction::PushToNAV, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When entering the name of the already coupled CRM Account to couple to, nothing should change');

        // [WHEN] Set "CRM Name" to "A" via lookup
        SelectCRMAccount := OriginallyCoupledCRMAccount;
        CRMCouplingRecord.CRMName.Lookup();
        // [THEN] "CRM Name" is "A"
        CRMCouplingRecord.CRMName.AssertEquals(SelectCRMAccount.Name);
        // [THEN] SyncAction is "Push To NAV"
        Assert.AreEqual(SyncAction::PushToNAV, CRMCouplingRecord.SyncActionControl.AsInteger(),
          'When entering the same CRM Account name that was there before the edit, nothing should change');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMCustomerListPageHandler(var CRMAccountList: TestPage "CRM Account List")
    begin
        CRMAccountList.GotoRecord(SelectCRMAccount);
        CRMAccountList.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMTableNameInBufferIsBlankIfNoTableMapping()
    var
        CouplingRecordBuffer: Record "Coupling Record Buffer";
    begin
        Initialize();
        // [GIVEN] No Integration Table Mapping defined
        // [GIVEN] "CRM Table Name" is 'N' in Coupling Record Buffer
        CouplingRecordBuffer."CRM Table Name" := LibraryUtility.GenerateGUID();
        // [WHEN] Set 'NAV Table ID' = 'X' in Coupling Record Buffer
        CouplingRecordBuffer.Validate("NAV Table ID", DATABASE::Customer);
        // [THEN] "CRM Table Name" is <blank> in Coupling Record Buffer
        Assert.AreEqual(
          '', CouplingRecordBuffer."CRM Table Name", CouplingRecordBuffer.FieldName("CRM Table Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMTableNameInBufferDefinedByTableMapping()
    var
        CouplingRecordBuffer: Record "Coupling Record Buffer";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        Initialize();
        // [GIVEN] Integration Table Mapping defines Name = 'A' for Table ID = 'Y'
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Table ID" := DATABASE::Currency;
        IntegrationTableMapping.Insert();
        // [GIVEN] Temporary Integration Table Mapping defines Name = 'T' for Table ID = 'X'
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Table ID" := DATABASE::Customer;
        IntegrationTableMapping."Delete After Synchronization" := true;
        IntegrationTableMapping.Insert();
        // [GIVEN] Integration Table Mapping defines Name = 'N' for Table ID = 'X'
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Table ID" := DATABASE::Customer;
        IntegrationTableMapping."Delete After Synchronization" := false;
        IntegrationTableMapping.Insert();
        // [WHEN] Set 'NAV Table ID' = 'X' in Coupling Record Buffer
        CouplingRecordBuffer.Validate("NAV Table ID", IntegrationTableMapping."Table ID");
        // [THEN] "CRM Table Name" is 'N' in Coupling Record Buffer
        Assert.AreEqual(
          IntegrationTableMapping.Name, CouplingRecordBuffer."CRM Table Name",
          CouplingRecordBuffer.FieldName("CRM Table Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CoupledRecordPageShowsFieldsDefinedByMapping()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
        ActualFieldCount: Integer;
        ExpectedFieldCount: Integer;
    begin
        Initialize();
        // [GIVEN] There are 15 fields defined for the mapping "Customer" - "CRM Account"
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.SetRange("Table ID", DATABASE::Customer);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.FindFirst();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        IntegrationFieldMapping.SetRange(Status, IntegrationFieldMapping.Status::Enabled);
        IntegrationFieldMapping.FindFirst();
        ExpectedFieldCount := IntegrationFieldMapping.Count();
        // [GIVEN] A Customer is coupled to a CRM Account
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [WHEN] Open Coupling Record Page for the Customer
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);

        // [THEN] Fields part is NOT editable
        Assert.IsFalse(CRMCouplingRecord.CouplingFields.Editable(), 'Fields part should be not editable');
        Assert.IsTrue(CRMCouplingRecord.CouplingFields.First(), 'There should be fields in the list part');
        IntegrationFieldMapping.FindFirst();
        ActualFieldCount := 1;
        while CRMCouplingRecord.CouplingFields.Next() do begin
            ActualFieldCount += 1;
            // [THEN] First mapped field values are shown in the list part
            if CRMCouplingRecord.CouplingFields."Field Name".Value = GetFldRefCaption(DATABASE::Customer, IntegrationFieldMapping."Field No.") then
                VerifyFieldValues(Customer, CRMAccount, IntegrationFieldMapping, CRMCouplingRecord);
        end;
        // [THEN] Fields part contains 15 fields
        Assert.AreEqual(ExpectedFieldCount, ActualFieldCount, 'Wrong fields count');
    end;

    local procedure GetFldRefValue(RecRef: RecordRef; FieldID: Integer): Text
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldID);
        exit(Format(FieldRef.Value));
    end;

    local procedure GetFldRefCaption(TableID: Integer; FieldID: Integer): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableID);
        FieldRef := RecRef.Field(FieldID);
        exit(FieldRef.Caption);
    end;

    local procedure VerifyFieldValues(Customer: Record Customer; CRMAccount: Record "CRM Account"; IntegrationFieldMapping: Record "Integration Field Mapping"; CRMCouplingRecord: TestPage "CRM Coupling Record")
    var
        RecRef: RecordRef;
        ExpectedCRMValue: Text;
        ExpectedNAVValue: Text;
        FieldCaption: Text;
    begin
        FieldCaption := GetFldRefCaption(DATABASE::Customer, IntegrationFieldMapping."Field No.");
        RecRef.GetTable(CRMAccount);
        ExpectedCRMValue :=
          GetFldRefValue(RecRef, IntegrationFieldMapping."Integration Table Field No.");
        Assert.AreNotEqual('', ExpectedCRMValue, 'Expected CRM Value should not be blank');
        Assert.AreEqual(
          ExpectedCRMValue, CRMCouplingRecord.CouplingFields."Integration Value".Value,
          StrSubstNo('Incorrect CRM Value for the field %1', FieldCaption));

        RecRef.GetTable(Customer);
        ExpectedNAVValue := GetFldRefValue(RecRef, IntegrationFieldMapping."Field No.");
        Assert.AreNotEqual('', ExpectedNAVValue, 'Expected NAV Value should not be blank');
        Assert.AreEqual(
          ExpectedNAVValue, CRMCouplingRecord.CouplingFields.Value.Value,
          StrSubstNo('Incorrect NAV Value for the field %1', FieldCaption));
    end;

    [Test]
    [HandlerFunctions('TestGetCRMIDAfterOpenPageForCoupledCustomerHandler')]
    [Scope('OnPrem')]
    procedure GetCRMIDAfterOpenPageForCoupledCustomer()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        LocalCRMAccount: Record "CRM Account";
        CouplingRecordBuffer: Record "Coupling Record Buffer";
        CRMCouplingRecord: Page "CRM Coupling Record";
    begin
        Initialize();
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.CreateCRMAccount(LocalCRMAccount);
        CoupleToCRMAccount := LocalCRMAccount;

        Assert.IsTrue(IsNullGuid(CRMCouplingRecord.GetCRMId()),
          'The CRM ID returned by the Customer Coupling page should be null before a record is set');

        CRMCouplingRecord.SetSourceRecordID(Customer.RecordId);
        CRMCouplingRecord.RunModal();
        CRMCouplingRecord.GetRecord(CouplingRecordBuffer);

        Assert.AreEqual(CRMAccount.AccountId, CouplingRecordBuffer."CRM ID", 'CRM ID');
        Assert.AreEqual(CRMAccount.AccountId, CRMCouplingRecord.GetCRMId(),
          'The CRM ID returned by the Customer Coupling page should be that of the record set');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TestGetCRMIDAfterOpenPageForCoupledCustomerHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
    end;

    [Test]
    [HandlerFunctions('TestGetCRMIDAfterSelectingCRMRecordHandler')]
    [Scope('OnPrem')]
    procedure GetCRMIDAfterSelectingCRMRecord()
    var
        Customer: Record Customer;
        LocalCRMAccount: Record "CRM Account";
        CRMCouplingRecord: Page "CRM Coupling Record";
    begin
        Initialize();
        ResetDefaultCRMSetupConfiguration();
        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateCRMAccount(LocalCRMAccount);
        CoupleToCRMAccount := LocalCRMAccount;

        CRMCouplingRecord.SetSourceRecordID(Customer.RecordId);
        CRMCouplingRecord.RunModal();
        Assert.AreEqual(CoupleToCRMAccount.AccountId, CRMCouplingRecord.GetCRMId(),
          'The CRM ID returned by the Customer Coupling page should be that of the record selected');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TestGetCRMIDAfterSelectingCRMRecordHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.CRMName.SetValue(CoupleToCRMAccount.Name);
    end;

    [Test]
    [HandlerFunctions('TestGetCreateNewInCRMHandler')]
    [Scope('OnPrem')]
    procedure GetCreateNewInCRM()
    var
        CouplingRecordBuffer: Record "Coupling Record Buffer";
        Customer: Record Customer;
        CRMCouplingRecord: Page "CRM Coupling Record";
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        CRMCouplingRecord.SetSourceRecordID(Customer.RecordId);
        CreateNewValueToSet := true;
        CRMCouplingRecord.RunModal();
        CRMCouplingRecord.GetRecord(CouplingRecordBuffer);
        Assert.IsTrue(CouplingRecordBuffer."Create New",
          'The value returned by GetCreateNewInCRM should be TRUE if the checkbox is checked');
        Assert.IsTrue(IsNullGuid(CouplingRecordBuffer."CRM ID"), 'CRM ID should be Null');
        Assert.AreEqual('', CouplingRecordBuffer."CRM Name", 'CRM Name should be blank');

        CreateNewValueToSet := false;
        CRMCouplingRecord.RunModal();
        CRMCouplingRecord.GetRecord(CouplingRecordBuffer);
        Assert.IsFalse(CouplingRecordBuffer."Create New",
          'The value returned by GetCreateNewInCRM should be FALSE if the checkbox is unchecked');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TestGetCreateNewInCRMHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.CreateNewControl.SetValue(CreateNewValueToSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPerformInitialSynchronization()
    var
        Customer: Record Customer;
        CouplingRecordBuffer: Record "Coupling Record Buffer";
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CouplingRecordBuffer.Initialize(Customer.RecordId);

        CouplingRecordBuffer."Sync Action" := SyncAction::DoNotSync;
        Assert.IsFalse(CouplingRecordBuffer.GetPerformInitialSynchronization(),
          'When the synch action is set to "Do not synch", GetPerformInitialSynchronization must return FALSE');

        CouplingRecordBuffer."Sync Action" := SyncAction::PushToCRM;
        Assert.IsTrue(CouplingRecordBuffer.GetPerformInitialSynchronization(),
          'When the synch action is set to "Push to CRM", GetPerformInitialSynchronization must return TRUE');

        CouplingRecordBuffer."Sync Action" := SyncAction::PushToNAV;
        Assert.IsTrue(CouplingRecordBuffer.GetPerformInitialSynchronization(),
          'When the synch action is set to "Push to NAV", GetPerformInitialSynchronization must return TRUE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetInitialSynchronizationDirection()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
        CouplingRecordBuffer: Record "Coupling Record Buffer";
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Commit();
        CouplingRecordBuffer.Initialize(Customer.RecordId);

        CouplingRecordBuffer."Sync Action" := SyncAction::DoNotSync;
        asserterror CouplingRecordBuffer.GetInitialSynchronizationDirection();
        Assert.ExpectedError('No initial synchronization direction was specified because initial synchronization was disabled.');

        CouplingRecordBuffer."Sync Action" := SyncAction::PushToCRM;
        Assert.AreEqual(IntegrationTableMapping.Direction::ToIntegrationTable, CouplingRecordBuffer.GetInitialSynchronizationDirection(),
          '"Push to CRM" equals "To integration table"');

        CouplingRecordBuffer."Sync Action" := SyncAction::PushToNAV;
        Assert.AreEqual(IntegrationTableMapping.Direction::FromIntegrationTable, CouplingRecordBuffer.GetInitialSynchronizationDirection(),
          '"Push to NAV" equals "From integration table"');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetSyncActionHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        CRMCouplingRecord.SyncActionControl.SetValue(SyncActionToSet);
    end;

    local procedure VerifyControlsEnabledByCreateNew(CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        // Make sure the synch action dropdown and CRM Name are enabled if create new in CRM is unchecked
        Assert.AreEqual(not CRMCouplingRecord.CreateNewControl.AsBoolean(), CRMCouplingRecord.SyncActionControl.Enabled(),
          'The Enabled setting of the Synch Action Control should be opposite to the value of the Create New in CRM Control');
        Assert.AreEqual(not CRMCouplingRecord.CreateNewControl.AsBoolean(), CRMCouplingRecord.CRMName.Enabled(),
          'The Enabled setting of the CRM Name Control should be opposite to the value of the Create New in CRM Control');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletedCustomerCouplingKeptUndeleted()
    var
        Customer: array[2] of Record Customer;
        CRMAccount: array[2] of Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        // [FEATURE] [Skipped Record]
        // [SCENARIO 171357] NAV records are NOT decoupled from deleted CRM entities on synchronization

        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        LibraryCRMIntegration.EnsureCRMSystemUser();
        ResetDefaultCRMSetupConfiguration();

        // [GIVEN] Two Customers coupled to CRM Accounts
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[1], CRMAccount[1]);
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer[2], CRMAccount[2]);

        // [GIVEN] The first CRM Account is deleted
        CRMAccount[1].Delete();

        // [WHEN] Synchronization is run for Customers
        IntegrationTableMapping.Get('CUSTOMER');
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        // [THEN] The first Customer is coupled, "Last Synch. CRM Result" is 'Failure'
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Customer[1].RecordId), CouplingErr);
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Failure);
        CRMIntegrationRecord.TestField("Last Synch. Result", CRMIntegrationRecord."Last Synch. Result"::" ");
        CRMIntegrationRecord.TestField(Skipped, false);

        // [THEN] The second Customer is coupled, "Last Synch. CRM Result" and "Last Synch. Result" are 'Failure'
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Customer[2].RecordId), CouplingErr);
        CRMIntegrationRecord.TestField("Last Synch. CRM Result", CRMIntegrationRecord."Last Synch. CRM Result"::Failure);
        CRMIntegrationRecord.TestField("Last Synch. Result", CRMIntegrationRecord."Last Synch. Result"::Failure);
        CRMIntegrationRecord.TestField(Skipped, false);

        // [WHEN] Repeat Synchronization
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        // [THEN] Both first and second Customers are still coupled, but Skipped for synchronization
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Customer[1].RecordId), '#1 Should be still coupled after repeated synch');
        CRMIntegrationRecord.TestField(Skipped, true);
        Assert.IsTrue(CRMIntegrationRecord.FindByRecordID(Customer[2].RecordId), '#2 Should be still coupled after repeated synch');
        CRMIntegrationRecord.TestField(Skipped, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetLatestErrorForFailedBidirectJobs()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        Currency: Record Currency;
        JobID: Guid;
        ErrorMsg: Text;
    begin
        Initialize();
        ResetDefaultCRMSetupConfiguration();
        // [FEATURE] [UT]
        // [SCENARIO] GetLatestError() returns error message from the synch. job to CRM if both directions failed.
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(
          Currency, CRMTransactioncurrency);

        ErrorMsg := LibraryUtility.GenerateGUID();
        JobID :=
          LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
            Currency.RecordId, CRMTransactioncurrency.RecordId, ErrorMsg, CurrentDateTime, false);
        LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
          CRMTransactioncurrency.TransactionCurrencyId, CRMTransactioncurrency.RecordId, Currency.RecordId,
          LibraryUtility.GenerateGUID(), CurrentDateTime, false);

        CRMIntegrationRecord.FindByCRMID(CRMTransactioncurrency.TransactionCurrencyId);
        CRMIntegrationRecord.GetLatestError(IntegrationSynchJobErrors);
        Assert.AreEqual(
          ErrorMsg, IntegrationSynchJobErrors.Message, 'GetLatestError fails.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetLatestErrorForFailedToCRMJob()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        Currency: Record Currency;
        JobQueueEntry: Record "Job Queue Entry";
        JobID: Guid;
        ErrorMsg: Text;
    begin
        Initialize();
        ResetDefaultCRMSetupConfiguration();
        // [FEATURE] [UT]
        // [SCENARIO] GetLatestError() returns error message from the synch. job to CRM if 'to CRM' direction failed.
        JobQueueEntry.DeleteAll();
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(
          Currency, CRMTransactioncurrency);

        ErrorMsg := LibraryUtility.GenerateGUID();
        JobID :=
          LibraryCRMIntegration.MockFailedSynchToCRMIntegrationRecord(
            Currency.RecordId, CRMTransactioncurrency.RecordId, ErrorMsg, CurrentDateTime, false);

        CRMIntegrationRecord.FindByCRMID(CRMTransactioncurrency.TransactionCurrencyId);
        CRMIntegrationRecord.GetLatestError(IntegrationSynchJobErrors);
        Assert.AreEqual(
          ErrorMsg, IntegrationSynchJobErrors.Message, 'GetLatestError fails.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetLatestErrorForFailedToNAVJob()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        Currency: Record Currency;
        JobQueueEntry: Record "Job Queue Entry";
        JobID: Guid;
        ErrorMsg: Text;
    begin
        Initialize();
        ResetDefaultCRMSetupConfiguration();
        // [FEATURE] [UT]
        // [SCENARIO] GetLatestError() returns error message from the synch. job to NAV if 'to NAV' direction failed.
        JobQueueEntry.DeleteAll();
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(
          Currency, CRMTransactioncurrency);

        ErrorMsg := LibraryUtility.GenerateGUID();
        JobID :=
          LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
            CRMTransactioncurrency.TransactionCurrencyId, CRMTransactioncurrency.RecordId,
            Currency.RecordId, ErrorMsg, CurrentDateTime, false);

        CRMIntegrationRecord.FindByCRMID(CRMTransactioncurrency.TransactionCurrencyId);
        CRMIntegrationRecord.GetLatestError(IntegrationSynchJobErrors);
        Assert.AreEqual(
          ErrorMsg, IntegrationSynchJobErrors.Message, 'GetLatestError fails.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetSkippedForLastSynchResultFailedToCRM()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        RecRef: RecordRef;
        JobID: Guid;
        ErrorMsg: Text;
    begin
        Initialize();
        ResetDefaultCRMSetupConfiguration();
        // [FEATURE] [UT] [Skipped Record]
        // [SCENARIO] Skipped is set to 'Yes' if sync to NAV failed twice with the same error.
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(
          Currency, CRMTransactioncurrency);

        // [GIVEN] Sync to NAV failed twice with the same error
        ErrorMsg := LibraryUtility.GenerateGUID();
        LibraryCRMIntegration.MockFailedSynchToNAVIntegrationRecord(
          CRMTransactioncurrency.TransactionCurrencyId, CRMTransactioncurrency.RecordId,
          Currency.RecordId, ErrorMsg, CurrentDateTime, false);
        JobID :=
          LibraryCRMIntegration.MockSyncJobError(
            CRMTransactioncurrency.RecordId, Currency.RecordId, ErrorMsg, CurrentDateTime);

        CRMIntegrationRecord.FindByCRMID(CRMTransactioncurrency.TransactionCurrencyId);
        CRMIntegrationRecord.TestField(Skipped, false);

        // [WHEN] CRMIntegrationRecord.SetLastSynchResultFailed()
        RecRef.Get(CRMTransactioncurrency.RecordId);
        CRMIntegrationRecord.SetLastSynchResultFailed(RecRef, false, JobID);

        // [THEN] CRMIntegrationRecord, where Skipped := TRUE
        CRMIntegrationRecord.Find();
        CRMIntegrationRecord.TestField(Skipped, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerListCRMControlsVisibility()
    var
        Customer: Record Customer;
        CustomerListPage: TestPage "Customer List";
    begin
        // [SCENARIO 209341] CRM related controls on Customer List page not visible when CRM Connection not configured

        // [WHEN] CRM Connection is configured
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [THEN] CRM related controls are visible on Customer List page
        CustomerListPage.OpenEdit();
        CustomerListPage.GotoKey(Customer."No.");
        Assert.AreEqual(true, CustomerListPage.CRMSynchronizeNow.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerListPage.CRMGotoAccount.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerListPage.UpdateStatisticsInCRM.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerListPage.ManageCRMCoupling.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerListPage.DeleteCRMCoupling.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerListPage.CreateInCRM.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerListPage.CreateFromCRM.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerListPage.ShowLog.Visible(), WrongControlVisibilityErr);
        CustomerListPage.Close();

        // [WHEN] CRM Connection is not configured
        LibraryCRMIntegration.ResetEnvironment();

        // [THEN] CRM related controls are visible on Customer List page
        CustomerListPage.OpenEdit();
        CustomerListPage.GotoKey(Customer."No.");
        Assert.AreEqual(false, CustomerListPage.CRMSynchronizeNow.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerListPage.CRMGotoAccount.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerListPage.UpdateStatisticsInCRM.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerListPage.ManageCRMCoupling.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerListPage.DeleteCRMCoupling.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerListPage.CreateInCRM.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerListPage.CreateFromCRM.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerListPage.ShowLog.Visible(), WrongControlVisibilityErr);
        CustomerListPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardCRMControlsVisibility()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 209341] CRM related controls on Customer Card page not visible when CRM Connection not configured

        // [WHEN] CRM Connection is configured
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // [THEN] CRM related controls are visible on Customer Card page
        CustomerCard.OpenEdit();
        CustomerCard.GotoKey(Customer."No.");
        Assert.AreEqual(true, CustomerCard.CRMSynchronizeNow.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerCard.CRMGotoAccount.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerCard.UpdateStatisticsInCRM.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerCard.ManageCRMCoupling.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerCard.DeleteCRMCoupling.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(true, CustomerCard.ShowLog.Visible(), WrongControlVisibilityErr);
        CustomerCard.Close();

        // [WHEN] CRM Connection is not configured
        LibraryCRMIntegration.ResetEnvironment();

        // [THEN] CRM related controls are visible on Customer Card page
        CustomerCard.OpenEdit();
        CustomerCard.GotoKey(Customer."No.");
        Assert.AreEqual(false, CustomerCard.CRMSynchronizeNow.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerCard.CRMGotoAccount.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerCard.UpdateStatisticsInCRM.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerCard.ManageCRMCoupling.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerCard.DeleteCRMCoupling.Visible(), WrongControlVisibilityErr);
        Assert.AreEqual(false, CustomerCard.ShowLog.Visible(), WrongControlVisibilityErr);
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('CRMCouplingRecordHandler')]
    [Scope('OnPrem')]
    procedure CRMCouplingRecordCreateNewEnabledForNotCoupledRecord()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [SCENARIO 215218] Create new control is enabled for not-coupled records with ToIntegrationTable default Direction
        Initialize();

        // [GIVEN] Customer
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::Customer, DATABASE::"CRM Account",
          CRMAccount.FieldNo(AccountId), CRMAccount.FieldNo(ModifiedOn),
          Customer.FieldNo(Name), CRMAccount.FieldNo(Name));
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Open CRM Coupling Record page for the Customer
        CRMIntegrationManagement.DefineCoupling(Customer.RecordId);

        // [THEN] "Create new" control is enabled.
        Assert.AreEqual(true, LibraryVariableStorage.DequeueBoolean(), WrongControlVisibilityErr);
    end;

    [Test]
    [HandlerFunctions('CRMCouplingRecordHandler')]
    [Scope('OnPrem')]
    procedure CRMCouplingRecordCreateNewDisabledForCoupledRecord()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [SCENARIO 215218] Create new control is not enabled for coupled records
        Initialize();

        // [GIVEN] The Customer coupled to CRM Account
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::Customer, DATABASE::"CRM Account",
          CRMAccount.FieldNo(AccountId), CRMAccount.FieldNo(ModifiedOn),
          Customer.FieldNo(Name), CRMAccount.FieldNo(Name));
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [WHEN] Open CRM Coupling Record page for the Salesperson
        CRMIntegrationManagement.DefineCoupling(Customer.RecordId);

        // [THEN] "Create new" control not enabled.
        Assert.AreEqual(false, LibraryVariableStorage.DequeueBoolean(), WrongControlVisibilityErr);
    end;

    [Test]
    [HandlerFunctions('CRMCouplingRecordHandler')]
    [Scope('OnPrem')]
    procedure CRMCouplingRecordCreateNewDisabledForFromIntegrationTableDirection()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSystemuser: Record "CRM Systemuser";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        // [SCENARIO 215218] Create new control is not enabled for records with FromIntegrationTable default Direction
        Initialize();

        // [GIVEN] Salesperson
        CreateIntTableMapping(
          IntegrationTableMapping, DATABASE::"Salesperson/Purchaser", DATABASE::"CRM Systemuser",
          CRMSystemuser.FieldNo(SystemUserId), CRMSystemuser.FieldNo(ModifiedOn),
          SalespersonPurchaser.FieldNo(Name), CRMSystemuser.FieldNo(FullName));
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [WHEN] Open CRM Coupling Record page for the Salesperson
        CRMIntegrationManagement.DefineCoupling(SalespersonPurchaser.RecordId);

        // [THEN] "Create new" control not enabled.
        Assert.AreEqual(false, LibraryVariableStorage.DequeueBoolean(), WrongControlVisibilityErr);
    end;

    [Test]
    [HandlerFunctions('CRMAccountListHandler')]
    [Scope('OnPrem')]
    procedure LookupCouplingRecordRefreshesValuesOnPage()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        OtherCRMAccount: Record "CRM Account";
        CRMCouplingRecord: TestPage "CRM Coupling Record";
    begin
        // [SCENARIO 275682] Looking up a CRM contact on Coupling Record Page refreshes the lines on the page
        Initialize();
        ResetDefaultCRMSetupConfiguration();

        // [GIVEN] A Customer was coupled to a CRM Account "A"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        // [GIVEN] The CRM Account "B"
        LibraryCRMIntegration.CreateCRMAccount(OtherCRMAccount);
        // [GIVEN] Coupling Record Page for the Customer was open
        OpenCRMCouplingRecordPage(CRMCouplingRecord, Customer.RecordId);
        // [GIVEN] CRM Account LookUp was performed
        LibraryVariableStorage.Enqueue(CRMAccount.Name);
        LibraryVariableStorage.Enqueue(OtherCRMAccount.Name);
        CRMCouplingRecord.CRMName.Lookup();

        // [WHEN] Pick CRM Account "B"
        // by CRMAccountListHandler

        // [THEN] Values in the page now correspond to new CRM Account "B"
        CRMCouplingRecord.CouplingFields.First();
        CRMCouplingRecord.CouplingFields."Integration Value".AssertEquals(OtherCRMAccount.Name);
    end;

    local procedure Initialize()
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
    end;

    local procedure CreateIntTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; TableId: Integer; CRMTableId: Integer; UIDFldNo: Integer; ModifiedOnFldNo: Integer; FldNo: Integer; IntTableFldNo: Integer)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationTableMapping.DeleteAll();
        IntegrationTableMapping.Init();
        IntegrationTableMapping.Name := LibraryUtility.GenerateGUID();
        IntegrationTableMapping."Table ID" := TableId;
        IntegrationTableMapping."Integration Table ID" := CRMTableId;
        IntegrationTableMapping."Integration Table UID Fld. No." := UIDFldNo;
        IntegrationTableMapping."Int. Tbl. Modified On Fld. No." := ModifiedOnFldNo;
        IntegrationTableMapping."Synch. Codeunit ID" := CODEUNIT::"CRM Integration Table Synch.";
        IntegrationTableMapping.Insert(true);

        IntegrationFieldMapping.DeleteAll();
        IntegrationFieldMapping.Init();
        IntegrationFieldMapping."No." := 0;
        IntegrationFieldMapping."Integration Table Mapping Name" := IntegrationTableMapping.Name;
        IntegrationFieldMapping."Field No." := FldNo;
        IntegrationFieldMapping."Integration Table Field No." := IntTableFldNo;
        IntegrationFieldMapping.Direction := IntegrationFieldMapping.Direction::ToIntegrationTable;
        IntegrationFieldMapping.Insert(true);
    end;

    local procedure SetIntTableFilter(IntegrationTableMapping: Record "Integration Table Mapping"; "Filter": Text)
    begin
        IntegrationTableMapping.SetIntegrationTableFilter(Filter);
        IntegrationTableMapping.Modify(true);
    end;

    local procedure CreateCRMProducts(var CRMProduct: array[3] of Record "CRM Product")
    var
        Currency: Record Currency;
        UnitOfMeasure: Record "Unit of Measure";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        LibraryCRMIntegration.CreateCoupledCurrencyAndTransactionCurrency(Currency, CRMTransactioncurrency);
        LibraryCRMIntegration.CreateCoupledUnitOfMeasureAndUomSchedule(UnitOfMeasure, CRMUom, CRMUomschedule);

        LibraryCRMIntegration.CreateCRMProduct(CRMProduct[2], CRMTransactioncurrency, CRMUom);
        CRMProduct[2].Validate(ProductTypeCode, CRMProduct[2].ProductTypeCode::SalesInventory);
        CRMProduct[2].Modify(true);

        LibraryCRMIntegration.CreateCRMProduct(CRMProduct[3], CRMTransactioncurrency, CRMUom);
        CRMProduct[3].Validate(ProductTypeCode, CRMProduct[3].ProductTypeCode::Services);
        CRMProduct[3].Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMAccountListHandler(var CRMAccountList: TestPage "CRM Account List")
    var
        CRMAccount: Record "CRM Account";
    begin
        CRMAccountList.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMAccount.SetRange(Name, LibraryVariableStorage.DequeueText());
        CRMAccount.FindFirst();
        CRMAccountList.GotoRecord(CRMAccount);
        CRMAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FilteredCRMAccountListHandler(var CRMAccountList: TestPage "CRM Account List")
    begin
        CRMAccountList.First();
        Assert.AreNotEqual('', CRMAccountList.Name.Value, CRMRecordErr);
        CRMAccountList.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(CRMAccountList.Next(), CRMRecordsListErr);
        CRMAccountList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMContactListHandler(var CRMContactList: TestPage "CRM Contact List")
    var
        CRMContact: Record "CRM Contact";
    begin
        CRMContactList.FullName.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMContact.SetRange(FullName, LibraryVariableStorage.DequeueText());
        CRMContact.FindFirst();
        CRMContactList.GotoRecord(CRMContact);
        CRMContactList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FilteredCRMContactListHandler(var CRMContactList: TestPage "CRM Contact List")
    begin
        CRMContactList.First();
        Assert.AreNotEqual('', CRMContactList.FullName.Value, CRMRecordErr);
        CRMContactList.FullName.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(CRMContactList.Next(), CRMRecordsListErr);
        CRMContactList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMSystemuserListHandler(var CRMSystemuserList: TestPage "CRM Systemuser List")
    var
        CRMSystemuser: Record "CRM Systemuser";
    begin
        CRMSystemuserList.FullName.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMSystemuser.SetRange(FullName, LibraryVariableStorage.DequeueText());
        CRMSystemuser.FindFirst();
        CRMSystemuserList.GotoRecord(CRMSystemuser);
        CRMSystemuserList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FilteredCRMSystemuserListHandler(var CRMSystemuserList: TestPage "CRM Systemuser List")
    begin
        CRMSystemuserList.First();
        Assert.AreNotEqual('', CRMSystemuserList.FullName.Value, CRMRecordErr);
        CRMSystemuserList.FullName.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(CRMSystemuserList.Next(), CRMRecordsListErr);
        CRMSystemuserList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMCurrencyListHandler(var CRMTransactionCurrencyList: TestPage "CRM TransactionCurrency List")
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        CRMTransactionCurrencyList.ISOCurrencyCode.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMTransactioncurrency.SetRange(ISOCurrencyCode, LibraryVariableStorage.DequeueText());
        CRMTransactioncurrency.FindFirst();
        CRMTransactionCurrencyList.GotoRecord(CRMTransactioncurrency);
        CRMTransactionCurrencyList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FilteredCRMCurrencyListHandler(var CRMTransactionCurrencyList: TestPage "CRM TransactionCurrency List")
    begin
        CRMTransactionCurrencyList.First();
        Assert.AreNotEqual('', CRMTransactionCurrencyList.ISOCurrencyCode.Value, CRMRecordErr);
        CRMTransactionCurrencyList.ISOCurrencyCode.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(CRMTransactionCurrencyList.Next(), CRMRecordsListErr);
        CRMTransactionCurrencyList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMPriceListHandler(var CRMPricelevelList: TestPage "CRM Pricelevel List")
    var
        CRMPricelevel: Record "CRM Pricelevel";
    begin
        CRMPricelevelList.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMPricelevel.SetRange(Name, LibraryVariableStorage.DequeueText());
        CRMPricelevel.FindFirst();
        CRMPricelevelList.GotoRecord(CRMPricelevel);
        CRMPricelevelList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FilteredCRMPriceListHandler(var CRMPricelevelList: TestPage "CRM Pricelevel List")
    begin
        CRMPricelevelList.First();
        Assert.AreNotEqual('', CRMPricelevelList.Name.Value, CRMRecordErr);
        CRMPricelevelList.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(CRMPricelevelList.Next(), CRMRecordsListErr);
        CRMPricelevelList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMProductListHandler(var CRMProductList: TestPage "CRM Product List")
    var
        CRMProduct: Record "CRM Product";
    begin
        CRMProductList.ProductNumber.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMProduct.SetRange(ProductNumber, LibraryVariableStorage.DequeueText());
        CRMProduct.FindFirst();
        CRMProductList.GotoRecord(CRMProduct);
        CRMProductList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FilteredCRMProductListHandler(var CRMProductList: TestPage "CRM Product List")
    begin
        CRMProductList.First();
        Assert.AreNotEqual('', CRMProductList.Name.Value, CRMRecordErr);
        CRMProductList.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsFalse(CRMProductList.Next(), CRMRecordsListErr);
        CRMProductList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMUomListHandler(var CRMUnitGroupList: TestPage "CRM UnitGroup List")
    var
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        CRMUnitGroupList.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMUomschedule.SetRange(Name, LibraryVariableStorage.DequeueText());
        CRMUomschedule.FindFirst();
        CRMUnitGroupList.GotoRecord(CRMUomschedule);
        CRMUnitGroupList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMOpportunityListHandler(var CRMOpportunityList: TestPage "CRM Opportunity List")
    var
        CRMOpportunity: Record "CRM Opportunity";
    begin
        CRMOpportunityList.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        CRMOpportunity.SetRange(Name, LibraryVariableStorage.DequeueText());
        CRMOpportunity.FindFirst();
        CRMOpportunityList.GotoRecord(CRMOpportunity);
        CRMOpportunityList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CRMCouplingRecordHandler(var CRMCouplingRecord: TestPage "CRM Coupling Record")
    begin
        LibraryVariableStorage.Enqueue(CRMCouplingRecord.CreateNewControl.Enabled());
    end;

    local procedure OpenCRMCouplingRecordPage(var CRMCouplingRecord: TestPage "CRM Coupling Record"; RecordID: RecordID)
    var
        TempCouplingRecordBuffer: Record "Coupling Record Buffer" temporary;
    begin
        InitCouplingRecordBuf(RecordID, TempCouplingRecordBuffer);
        CRMCouplingRecord.Trap();
        PAGE.Run(PAGE::"CRM Coupling Record", TempCouplingRecordBuffer);
    end;

    local procedure InitCouplingRecordBuf(RecordID: RecordID; var CouplingRecordBuffer: Record "Coupling Record Buffer")
    begin
        CouplingRecordBuffer.Initialize(RecordID);
        CouplingRecordBuffer.Insert();
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
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;
}

