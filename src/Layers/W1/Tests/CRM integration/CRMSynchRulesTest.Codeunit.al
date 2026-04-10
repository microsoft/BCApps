codeunit 139181 "CRM Synch. Rules Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Contact]
    end;

    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        LibraryTemplates: Codeunit "Library - Templates";
        Assert: Codeunit Assert;
        ContactMissingCompanyErr: Label 'The contact cannot be synchronized because the company does not exist';

    [Test]
    [Scope('OnPrem')]
    procedure ModifiedCRMContactSyncedToNAVContact()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
    begin
        // [SCENARIO] Modified CRM Contact synchronized to the couped NAV Contact
        Initialize();
        // [GIVEN] NAV Contact, where Name is 'A', is coupled to CRM Contact
        CreateCoupledContactsWithParents(Contact, CRMContact);
        CRMContact.LastName := Contact.Surname;
        CRMContact.Modify(true);
        // [GIVEN] CRM Contact Name is changed to "B"
        Sleep(20);
        CRMContact.LastName := 'NewLastName';
        CRMContact.Modify(true);

        // [WHEN] Sync the CRM contact to NAV
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMContact.ContactId, true, true);

        // [THEN] NAV Contact is modified, Name is "B"
        Contact.Find();
        Contact.TestField(Surname, CRMContact.LastName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifiedNAVContactSyncedToCRMContact()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
    begin
        // [SCENARIO] Modified NAV Contact synchronized to the couped CRM Contact
        Initialize();
        // [GIVEN] CRM Contact, where Name is 'A', is coupled to NAV Contact
        CreateCoupledContactsWithParents(Contact, CRMContact);
        Contact.Surname := CRMContact.LastName;
        Contact.Modify(true);
        // [GIVEN] NAV Contact Name is changed to "B"
        Sleep(20);
        Contact.Surname := 'NewLastName';
        Contact.Modify(true);

        // [WHEN] Sync the NAV contact to CRM
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Contact.RecordId(), true, true);

        // [THEN] CRM Contact is modified, Name is "B"
        CRMContact.Find();
        CRMContact.TestField(LastName, Contact.Surname);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewCRMContactCannotBeSyncedToNewNAVContactWithoutCoupledParent()
    var
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        ContactRecID: RecordID;
        JobID: Guid;
    begin
        // [SCENARIO] New CRM Contact should not create new couped NAV Contact if parent CRM account is not coupled.
        Initialize();
        // [GIVEN] The new CRM Contact, where parent CRM Account is not coupled.
        LibraryCRMIntegration.CreateCRMAccountWithCoupledOwner(CRMAccount);
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);

        // [WHEN] Sync the CRM contact to NAV
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        JobID := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMContact.ContactId, true, true);

        // [THEN] CRM Contact is not coupled.
        Assert.IsFalse(
          CRMIntegrationRecord.FindRecordIDFromID(CRMContact.ContactId, DATABASE::Contact, ContactRecID),
          'CRM Contact should not be coupled.');
        // [THEN] The sync job failed, where error is "The contact cannot be synchronized because the company does not exist"
        IntegrationSynchJob.Get(JobID);
        IntegrationSynchJob.TestField(Failed, 1);
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", JobID);
        IntegrationSynchJobErrors.FindFirst();
        Assert.ExpectedMessage(ContactMissingCompanyErr, IntegrationSynchJobErrors.Message);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewCRMContactSyncedToNewNAVContactIfParentIsCoupled()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        ContactRecID: RecordID;
        ContactRecRef: RecordRef;
    begin
        // [SCENARIO] New CRM Contact should be synched to new couped NAV Contact, if parent CRM account is coupled.
        Initialize();
        // [GIVEN] The new CRM Contact, where parent CRM Account is coupled to the NAV Customer.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);

        // [WHEN] Sync the CRM contact to NAV
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMContact.ContactId, true, true);

        // [THEN] CRM Contact is coupled
        Assert.IsTrue(
          CRMIntegrationRecord.FindRecordIDFromID(CRMContact.ContactId, DATABASE::Contact, ContactRecID),
          'CRM Contact should be coupled.');
        // [THEN] NAV Contact got "No." from the Series No.
        ContactRecRef := ContactRecID.GetRecord();
        ContactRecRef.SetTable(Contact);
        Contact.TestField("No.", GetLastUsedContactNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCoupleCompanyContactThroughUI()
    var
        Contact: Record Contact;
        TestContactCard: TestPage "Contact Card";
        TestContactList: TestPage "Contact List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Coupling a company type Contact from the Contact Card/List pages
        Initialize();
        // [GIVEN] A company type Contact
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Type := Contact.Type::Company;
        Contact.Modify();

        // [WHEN] Running the Contact Card for the Contact
        RunContactCard(Contact, TestContactCard);

        // [THEN] The Dynamics CRM action group is disabled
        AssertCRMActionGroupDisabledContactCard(TestContactCard);

        // [WHEN] Running the Contact List and selecting the Contact
        RunContactList(Contact, TestContactList);

        // [THEN] The Dynamics CRM action group is disabled
        AssertCRMActionGroupDisabledContactList(TestContactList);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCoupleCompanyContactThroughCode()
    var
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMAccount: Record "CRM Account";
    begin
        // [SCENARIO] Coupling a company type Contact
        Initialize();

        // [GIVEN] A company type Contact
        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateContactForCustomer(Contact, Customer);
        Contact.Validate(Type, Contact.Type::Company);
        Contact.Modify(true);

        IntegrationSynchJob.DeleteAll();
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Contact.RecordId, CRMContact.ContactId);
        Assert.IsTrue(CRMIntegrationRecord.IsIntegrationIdCoupled(Contact.SystemId, Database::Contact), '');

        // [WHEN] Synchronize the Contact
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping.Modify(true);
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);

        // [THEN] Integration Sync. Job is created, where Modified = 0, Failed = 0.
        IntegrationSynchJob.FindLast();
        Assert.AreEqual(0, IntegrationSynchJob.Modified, 'A contact of type Company should not be modified');
        Assert.AreEqual(0, IntegrationSynchJob.Failed, ConstructAllFailuresMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeCoupledPersonToCompanyContactAndCoupleThroughCode()
    var
        Customer: Record Customer;
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMAccount: Record "CRM Account";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
    begin
        // [SCENARIO] Synchronizing a Contact of type Company with CRM Contact while parents Customer and CRM Account are not coupled
        Initialize();
        IntegrationTableMapping.DeleteAll();

        // [GIVEN] A synchronized Contact of type Person with a parent Customer coupled with a CRM Contact
        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateContactForCustomer(Contact, Customer);
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Contact.RecordId, CRMContact.ContactId);
        Contact.Find();

        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;
        IntegrationTableMapping.Modify(true);
        CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Contact.RecordId, true, false);

        IntegrationSynchJob.FindLast();
        Assert.AreEqual(1, IntegrationSynchJob.Modified,
          StrSubstNo(
            'Expected one row to be inserted. Modified: %1, Unchanged: %2, Failed: %3\', IntegrationSynchJob.Modified,
            IntegrationSynchJob.Unchanged, ConstructAllFailuresMessage()));

        // [GIVEN] Change Contact's Type to "Company"
        Contact.Validate(Type, Contact.Type::Company);
        Contact.Modify(true);
        IntegrationSynchJob.Reset();
        IntegrationSynchJob.DeleteAll();
        // [WHEN] Synchronize the Contact
        CODEUNIT.Run(CODEUNIT::"CRM Integration Table Synch.", IntegrationTableMapping);
        // [THEN] Integration Sync. Job is created, where Modified = 0 , Failed = 0.
        IntegrationSynchJob.FindLast();
        Assert.AreEqual(0, IntegrationSynchJob.Modified, 'A contact of type Company should not be modified');
        Assert.AreEqual(0, IntegrationSynchJob.Failed, ConstructAllFailuresMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCoupleContactWithoutParentCompanyContact()
    var
        Contact: Record Contact;
        TestContactCard: TestPage "Contact Card";
        TestContactList: TestPage "Contact List";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Coupling a Contact with no parent company Contact
        Initialize();
        // [GIVEN] A Contact with no parent company Contact
        LibraryCRMIntegration.CreateContact(Contact);
        Contact."Company No." := '';
        Contact.Modify();

        // [WHEN] Running the Contact Card for the Contact
        RunContactCard(Contact, TestContactCard);

        // [THEN] The Dynamics CRM action group is disabled
        AssertCRMActionGroupDisabledContactCard(TestContactCard);

        // [WHEN] Running the Contact List and selecting the Contact
        RunContactList(Contact, TestContactList);

        // [THEN] The Dynamics CRM action group is disabled
        AssertCRMActionGroupDisabledContactList(TestContactList);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchContactWithoutParentCompanyContact()
    var
        Contact: Record Contact;
        LogId: Guid;
    begin
        // [SCENARIO] Synchronizing a Contact with no parent company Contact
        Initialize();
        // [GIVEN] A Contact with no parent company Contact
        LibraryCRMIntegration.CreateContact(Contact);
        Contact."Company No." := '';
        Contact.Modify();

        // [WHEN] The Contact is synchronized while allowing insertion
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        LogId := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Contact.RecordId, true, true);

        // [THEN] Synchronization is skipped, Job ID is <null>, OutOfMapFilter is 'Yes'
        Assert.IsTrue(CRMIntegrationTableSynch.GetOutOfMapFilter(), 'OutOfMapFilter');
        Assert.IsTrue(IsNullGuid(LogId), 'Job ID shoul be <null>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchCoupledContactWithoutParentCompanyContact()
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMSystemuser: Record "CRM Systemuser";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LogId: Guid;
    begin
        // [SCENARIO] Coupling a Contact with no parent Customer
        Initialize();
        // [GIVEN] A Contact with no parent Customer (no parent company type Contact, no Company No.)
        LibraryCRMIntegration.CreateContact(Contact);
        Contact."Company No." := '';
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);
        Contact."Salesperson Code" := SalespersonPurchaser.Code;
        Contact.Modify();

        // [GIVEN] A CRM Contact
        LibraryCRMIntegration.CreateCRMContact(CRMContact);

        // [GIVEN] The Contact is coupled
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Contact.RecordId, CRMContact.ContactId);

        // [WHEN] The Contact is synchronized
        LibraryCRMIntegration.CreateCRMOrganization(); // needed for LCY currency creation
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        LogId := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Contact.RecordId, true, false);

        // [THEN] Synchronization is skipped, Job ID is <null>, OutOfMapFilter is 'Yes'
        Assert.IsTrue(CRMIntegrationTableSynch.GetOutOfMapFilter(), 'OutOfMapFilter');
        Assert.IsTrue(IsNullGuid(LogId), 'Job ID shoul be <null>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchContactWithUnCoupledParentCustomer()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        LogId: Guid;
    begin
        // [SCENARIO] Synchronizing a Contact with a parent Customer which is not coupled
        Initialize();

        LibraryCRMIntegration.RegisterTestTableConnection();

        // [GIVEN] A Contact with a parent Customer
        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateContactForCustomer(Contact, Customer);

        // [WHEN] Synchronizing the Contact
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        LogId := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Contact.RecordId, true, false);

        // [THEN] Synchronization skips the record
        IntegrationSynchJob.Get(LogId);
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", LogId);
        if IntegrationSynchJobErrors.FindFirst() then
            Assert.Fail('An unexpected error occured: ' + IntegrationSynchJobErrors.Message);
        Assert.AreEqual(1, IntegrationSynchJob.Skipped,
          StrSubstNo('Expected a synchronization job for a Contact with an uncoupled parent Customer results in a skip action.' +
            ' The results were %1 inserted, %2 modified, %3 unchanged, %4 skipped, %5 failed',
            IntegrationSynchJob.Inserted, IntegrationSynchJob.Modified, IntegrationSynchJob.Unchanged, IntegrationSynchJob.Skipped,
            IntegrationSynchJob.Failed));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchContactCoupledToCRMContactWhileParentsAreNotCoupled()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        IntegrationSynchJob: Record "Integration Synch. Job";
        LogId: Guid;
    begin
        // [SCENARIO] Synchronizing a Contact and CRM Contact whose parent Customer and CRM Account are not coupled to anything
        Initialize();

        LibraryCRMIntegration.RegisterTestTableConnection();

        // [GIVEN] A Contact with a parent Customer
        LibrarySales.CreateCustomer(Customer);
        LibraryCRMIntegration.CreateContactForCustomer(Contact, Customer);

        // [GIVEN] A CRM Contact with a parent CRM Account
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        LibraryCRMIntegration.CreateCRMContactWithParentAccount(CRMContact, CRMAccount);

        // [GIVEN] The Customer and the CRM Account are both not coupled to anything
        // [GIVEN] The Contact is coupled to the CRM Contact
        CRMIntegrationRecord.CoupleRecordIdToCRMID(Contact.RecordId, CRMContact.ContactId);

        // [WHEN] Synchronizing the Contact
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CONTACT');
        LogId := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, Contact.RecordId, true, false);

        // [THEN] Synchronization succeeds with one modification
        IntegrationSynchJob.Get(LogId);
        Assert.AreEqual(1, IntegrationSynchJob.Modified,
          'A modification synchronization job for a Contact with an uncoupled parent Customer should succeed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchCRMContactWithNonCustomerCRMAccountParent()
    var
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Contact: Record Contact;
        RecRef: RecordRef;
        RecID: RecordID;
        LogId: Guid;
    begin
        // [SCENARIO 235867] Synchronizing a CRM Contact with a parent CRM Account, that is not Customer, should not create Customer
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        // [GIVEN] CRM Account 'X', where "Relationship Type" is not 'Customer'
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        CRMAccount.CustomerTypeCode := CRMAccount.CustomerTypeCode::" ";
        CRMAccount.Modify(true);
        // [GIVEN] CRM Contact 'A', where parent is 'X'
        LibraryCRMIntegration.CreateCRMContactWithCoupledOwner(CRMContact);
        CRMContact.ParentCustomerIdType := CRMContact.ParentCustomerIdType::account;
        CRMContact.ParentCustomerId := CRMAccount.AccountId;
        CRMContact.Modify(true);
        // [GIVEN] "Synch. Only Coupled Records" is 'No' in the 'CUSTOMER' mapping (to simulate full sync run)
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CUSTOMER');
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        // [WHEN] Synchronizing the Contact, ignoring "Synch. Only Coupled Records"
        IntegrationTableMapping.Get('CONTACT');
        LogId := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, CRMContact.ContactId, true, true);

        // [THEN] New NAV Contact is created, coupled to CRM Contact 'A'
        Assert.IsTrue(
          CRMIntegrationRecord.FindRecordIDFromID(CRMContact.ContactId, DATABASE::Contact, RecID),
          'CRM Contact should be coupled');
        // [THEN] Company Contact is not defined, "Company No." and "Company Name" are blank
        RecRef.Get(RecID);
        RecRef.SetTable(Contact);
        Contact.TestField("Company No.", '');
        Contact.TestField("Company Name", '');
        // [THEN] New NAV Customer is NOT created, CRM Account 'X' is not coupled
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMAccount.AccountId), 'CRM Account should not be coupled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSynchSalesInvHeaderWithCustomerOutOfMapFilter()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LogId: Guid;
        CRMAccountID: Guid;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 235867] Synchronizing a Sales Invoice Header with a Customer, that is out of CUSTOMER map filter.
        Initialize();
        LibraryCRMIntegration.RegisterTestTableConnection();
        InitCRMBaseCurrency();

        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Sales Invoice Header, where "Sell-to Customer No." is 'A'
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Sell-to Customer No." := Customer."No.";
        SalesInvoiceHeader.Insert();

        // [GIVEN] Customer 'A' is blocked for Invoice
        Customer.Blocked := Customer.Blocked::Invoice;
        Customer.Modify();

        // [GIVEN] 'CUSTOMER' mapping, where "Table Filter" = 'Blocked=FILTER(<>Invoice))'
        ResetDefaultCRMSetupConfiguration();
        IntegrationTableMapping.Get('CUSTOMER');
        Customer.SetFilter(Blocked, '<>%1', Customer.Blocked::Invoice);
        IntegrationTableMapping.SetTableFilter(Customer.GetView());
        // [GIVEN] "Synch. Only Coupled Records" is 'No' in the 'CUSTOMER' mapping (to simulate full sync run)
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping.Modify();

        // [WHEN] Synchronizing the Sales Invoice Header, ignoring "Synch. Only Coupled Records"
        IntegrationTableMapping.Get('POSTEDSALESINV-INV');
        LogId := CRMIntegrationTableSynch.SynchRecord(IntegrationTableMapping, SalesInvoiceHeader.RecordId, true, true);

        // [THEN] Synch. Job has failed.
        IntegrationSynchJob.Get(LogId);
        Assert.AreEqual(1, IntegrationSynchJob.Failed, 'IntegrationSynchJob.Failed is wrong');
        // [THEN] Customer 'A' is not coupled
        Assert.IsFalse(
          CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId, CRMAccountID),
          'Customer should not be coupled');
    end;

    local procedure Initialize()
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        LibraryTemplates.EnableTemplatesFeature();
    end;

    local procedure InitCRMBaseCurrency()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMOrganization: Record "CRM Organization";
    begin
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMOrganization.FindFirst();
        CRMConnectionSetup.BaseCurrencyId := CRMOrganization.BaseCurrencyId;
        CRMConnectionSetup.Modify();
    end;

    local procedure GetLastUsedContactNo(): Code[20]
    var
        MarketingSetup: Record "Marketing Setup";
        NoSeriesLine: Record "No. Series Line";
    begin
        MarketingSetup.Get();
        NoSeriesLine.SetRange("Series Code", MarketingSetup."Contact Nos.");
        NoSeriesLine.SetRange(Open, true);
        NoSeriesLine.FindFirst();
        exit(NoSeriesLine."Last No. Used");
    end;

    local procedure CreateCoupledContactsWithParents(var Contact: Record Contact; var CRMContact: Record "CRM Contact")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CompanyContact: Record Contact;
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
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
        CRMContact.OwnerId := CRMAccount.OwnerId;
        CRMContact.OwnerIdType := CRMAccount.OwnerIdType;
        CRMContact.Modify();
        CRMIntegrationRecord.FindByCRMID(CRMContact.OwnerId);
        CRMIntegrationRecord.FindFirst();
        SalespersonPurchaser.GetBySystemId(CRMIntegrationRecord."Integration ID");
        Contact."Salesperson Code" := SalespersonPurchaser.Code;
        Contact.Modify();
    end;

    [Scope('OnPrem')]
    procedure ConstructAllFailuresMessage() Message: Text
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        if not IntegrationSynchJobErrors.FindSet() then
            exit('');

        repeat
            Message := Message + IntegrationSynchJobErrors.Message + '\';
        until IntegrationSynchJobErrors.Next() = 0;
    end;

    local procedure RunContactCard(Contact: Record Contact; var TestContactCard: TestPage "Contact Card")
    begin
        TestContactCard.Trap();
        PAGE.Run(PAGE::"Contact Card", Contact);
    end;

    local procedure RunContactList(Contact: Record Contact; var TestContactList: TestPage "Contact List")
    begin
        TestContactList.Trap();
        PAGE.Run(PAGE::"Contact List", Contact);
    end;

    local procedure AssertCRMActionGroupDisabledContactCard(TestContactCard: TestPage "Contact Card")
    begin
        Assert.IsFalse(TestContactCard.CRMGotoContact.Enabled(),
          'The Contact button on the Contact Card page should not be enabled');
        Assert.IsFalse(TestContactCard.CRMSynchronizeNow.Enabled(),
          'The Synchronize Now button on the Contact Card page should not be enabled ');
        Assert.IsFalse(TestContactCard.ManageCRMCoupling.Enabled(),
          'The Set Up Coupling button on the Contact Card page should not be enabled ');
        Assert.IsFalse(TestContactCard.DeleteCRMCoupling.Enabled(),
          'The Delete Coupling button on the Contact Card page should not be enabled ');
    end;

    local procedure AssertCRMActionGroupDisabledContactList(TestContactList: TestPage "Contact List")
    begin
        Assert.IsFalse(TestContactList.CRMGotoContact.Enabled(),
          'The Contact button on the Contact List page should not be enabled ');
        Assert.IsFalse(TestContactList.CRMSynchronizeNow.Enabled(),
          'The Synchronize Now button on the Contact List page should not be enabled ');
        Assert.IsFalse(TestContactList.ManageCRMCoupling.Enabled(),
          'The Set Up Coupling button on the Contact List page should not be enabled ');
        Assert.IsFalse(TestContactList.DeleteCRMCoupling.Enabled(),
          'The Delete Coupling button on the Contact List page should not be enabled ');
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
}

