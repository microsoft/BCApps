codeunit 139168 "CRM Int. Tbl. Map Helper Tests"
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
        LibrarySales: Codeunit "Library - Sales";
        CRMIntTableSubscriber: Codeunit "CRM Int. Table. Subscriber";
        ContactMissingCompanyErr: Label 'The contact cannot be synchronized because the company does not exist.';

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCustomerAfterTransferRecordFields()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        CoupledSalespersonPurchaser: Record "Salesperson/Purchaser";
        DecoupledSalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        AdditionalFieldsWereModified: Boolean;
    begin
        // [FEATURE] [Table Subscriber] [Customer]
        Initialize();
        ResetDefaultCRMSetupConfiguration();

        SourceRecordRef.Open(DATABASE::"CRM Account");
        DestinationRecordRef.Open(DATABASE::Customer);
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] A Source CRMAccount with StatusCode::Inactive
        CRMAccount.StatusCode := CRMAccount.StatusCode::Inactive;
        SourceRecordRef.GetTable(CRMAccount);
        // [GIVEN] The Destination Customer has Blocked = " "
        Customer.Blocked := Customer.Blocked::" ";
        Assert.AreEqual(Customer.Blocked::" ", Customer.Blocked, 'Expected blank status');
        DestinationRecordRef.GetTable(Customer);
        AdditionalFieldsWereModified := false;

        // [WHEN] Updating the customer after transfer fields
        CRMIntTableSubscriber.OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);

        // [THEN] The Destination record is updated to blocked
        DestinationRecordRef.SetTable(Customer);
        Assert.AreEqual(Customer.Blocked::All, Customer.Blocked, 'Expected blocked status');
        // [THEN] The AdditionalFieldsWereModified flag is set to true
        Assert.IsTrue(AdditionalFieldsWereModified, 'Expected the AdditionalFieldsWereModified flag to be set');

        // [GIVEN] A Source CRMAccount with StatusCode::Inactive
        CRMAccount.StatusCode := CRMAccount.StatusCode::Inactive;
        SourceRecordRef.GetTable(CRMAccount);
        // [GIVEN] The Destination Customer has Blocked <> " "
        Customer.Blocked := Customer.Blocked::All;
        Assert.AreEqual(Customer.Blocked::All, Customer.Blocked, 'Expected blocked all');
        DestinationRecordRef.GetTable(Customer);
        AdditionalFieldsWereModified := false;

        // [WHEN] Updating the customer after transfer fields
        CRMIntTableSubscriber.OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);

        // [THEN] The Destination record is not updated
        DestinationRecordRef.SetTable(Customer);
        Assert.AreEqual(Customer.Blocked::All, Customer.Blocked, 'Expected no change status');
        // [THEN] The AdditionalFieldsWereModified flag is not set
        Assert.IsFalse(AdditionalFieldsWereModified, 'Did not expect the AdditionalFieldsWereModified flag to be set');

        // [GIVEN] A Source CRMAccount with StatusCode::Active
        Clear(CRMAccount);
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        CRMAccount.StatusCode := CRMAccount.StatusCode::Active;
        SourceRecordRef.GetTable(CRMAccount);
        // [GIVEN] The Destination Customer has Blocked::All
        Customer.Blocked := Customer.Blocked::All;
        Assert.AreEqual(Customer.Blocked::All, Customer.Blocked, 'Expected blocked all');
        DestinationRecordRef.GetTable(Customer);
        AdditionalFieldsWereModified := false;

        // [WHEN] Updating the customer after transfer fields
        CRMIntTableSubscriber.OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);

        // [THEN] The Destination record is not updated
        DestinationRecordRef.SetTable(Customer);
        Assert.AreEqual(Customer.Blocked::All, Customer.Blocked, 'Expected no change status');
        // [THEN] The AdditionalFieldsWereModified flag is not set
        Assert.IsFalse(AdditionalFieldsWereModified, 'Did not expect the AdditionalFieldsWereModified flag to be set');

        Customer.Blocked := Customer.Blocked::" ";
        CRMAccount.StatusCode := CRMAccount.StatusCode::Active;

        // [GIVEN] A Source CRMAccount with Owner set
        // [GIVEN] The Destination Customer with no salesperson code set
        // [GIVEN] CRM OwnerID is coupled to CoupledSalesPerson
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(CoupledSalespersonPurchaser, CRMSystemuser);
        CRMAccount.OwnerId := CRMSystemuser.SystemUserId;
        Customer."Salesperson Code" := '';

        SourceRecordRef.GetTable(CRMAccount);
        DestinationRecordRef.GetTable(Customer);
        AdditionalFieldsWereModified := false;

        // [WHEN] Updating the customer after transfer fields
        CRMIntTableSubscriber.OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);

        // [THEN] The Destination record is updated
        // [THEN] The AdditionalFieldsWereModified flag is NOT set
        DestinationRecordRef.SetTable(Customer);
        Assert.IsFalse(AdditionalFieldsWereModified, 'Expected the AdditionalFieldsWereModified flag not to be set');
        Assert.AreEqual('', Customer."Salesperson Code", 'Expected the salesperson code not to be updated');

        // [GIVEN] A Source CRMAccount with Owner set
        // [GIVEN] CRM OwnerID is NOT coupled salesperson
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser);
        CRMAccount.OwnerId := CRMSystemuser.SystemUserId;
        // [GIVEN] The Destination Customer with salesperson code set
        LibrarySales.CreateSalesperson(DecoupledSalespersonPurchaser);
        Customer."Salesperson Code" := DecoupledSalespersonPurchaser.Code;

        SourceRecordRef.GetTable(CRMAccount);
        DestinationRecordRef.GetTable(Customer);
        AdditionalFieldsWereModified := false;

        // [WHEN] Updating the customer after transfer fields
        CRMIntTableSubscriber.OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);

        // [THEN] The AdditionalFieldsWereModified flag is not set
        DestinationRecordRef.SetTable(Customer);
        Assert.IsFalse(AdditionalFieldsWereModified, 'Expected the AdditionalFieldsWereModified flag not to be set');
        Assert.AreEqual(DecoupledSalespersonPurchaser.Code, Customer."Salesperson Code",
          'Expected the salesperson code to remain the decoupledsalesperson');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateContactAfterTransferRecordFields()
    var
        CRMContact: Record "CRM Contact";
        Contact: Record Contact;
        CoupledSalespersonPurchaser: Record "Salesperson/Purchaser";
        DecoupledSalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        AdditionalFieldsWereModified: Boolean;
    begin
        // [FEATURE] [Table Subscriber] [Contact]
        Initialize();
        ResetDefaultCRMSetupConfiguration();

        SourceRecordRef.Open(DATABASE::"CRM Contact");
        DestinationRecordRef.Open(DATABASE::Contact);
        CRMContact.Init();
        Contact.Init();

        // [GIVEN] A Source CRMContact with Owner set
        // [GIVEN] CRM OwnerId is coupled to CoupledSalesPerson
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(CoupledSalespersonPurchaser, CRMSystemuser);
        CRMContact.OwnerId := CRMSystemuser.SystemUserId;
        // [GIVEN] The Destination Contact with no salesperson code set
        Contact."Salesperson Code" := '';

        SourceRecordRef.GetTable(CRMContact);
        DestinationRecordRef.GetTable(Contact);
        AdditionalFieldsWereModified := false;

        CRMIntTableSubscriber.OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);

        // [THEN] The Destination record is updated
        // [THEN] The AdditionalFieldsWereModified flag is NOT set
        DestinationRecordRef.SetTable(Contact);
        Assert.IsFalse(AdditionalFieldsWereModified, 'Expected the AdditionalFieldsWereModified flag not to be set');
        Assert.AreEqual('', Contact."Salesperson Code", 'Expected the salesperson code not to be updated');

        // [GIVEN] A Source CRMAccount with Owner set
        // [GIVEN] The Destination Contact with salesperson code set
        // [GIVEN] CRM OwnerId is NOT coupled salesperson
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser);
        CRMContact.OwnerId := CRMSystemuser.SystemUserId;
        LibrarySales.CreateSalesperson(DecoupledSalespersonPurchaser);
        Contact."Salesperson Code" := DecoupledSalespersonPurchaser.Code;

        SourceRecordRef.GetTable(CRMContact);
        DestinationRecordRef.GetTable(Contact);
        AdditionalFieldsWereModified := false;

        CRMIntTableSubscriber.OnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);

        // [THEN] The Destination record is updated
        // [THEN] The AdditionalFieldsWereModified flag is not set
        DestinationRecordRef.SetTable(Contact);
        Assert.IsFalse(AdditionalFieldsWereModified, 'Expected the AdditionalFieldsWereModified flag not to be set');
        Assert.AreEqual(DecoupledSalespersonPurchaser.Code, Contact."Salesperson Code",
          'Expected the salesperson code to remain the decoupledsalesperson');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateContactBeforeInsertRecord()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        Contact: Record Contact;
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [FEATURE] [Table Subscriber] [Contact]
        Initialize();

        SourceRecordRef.Open(DATABASE::"CRM Contact");
        DestinationRecordRef.Open(DATABASE::Contact);

        // [GIVEN] Valid setup
        // [GIVEN] A new Contact record
        // [WHEN] Executing before insert step
        // [THEN] Error: 'Contact missing Company'.
        Contact.Init();

        DestinationRecordRef.GetTable(Contact);

        asserterror CRMIntTableSubscriber.OnBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);
        Assert.ExpectedError(ContactMissingCompanyErr);

        // [GIVEN] Valid setup
        // [GIVEN] A new Contact record
        // [GIVEN] Source has Parent Customer coupled to NAV customer
        // [WHEN] Executing before insert step
        // [THEN] Contact, where "Company No." is not blank.
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CRMContact.Init();
        CRMContact.ParentCustomerId := CRMAccount.AccountId;
        SourceRecordRef.GetTable(CRMContact);

        Contact.Init();
        DestinationRecordRef.GetTable(Contact);
        CRMIntTableSubscriber.OnBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);

        DestinationRecordRef.SetTable(Contact);
        Assert.AreNotEqual('', Contact."Company No.", 'Expected the Company No. to be set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalespersonOnBeforeInsertRecord()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SecondSalespersonPurchaser: Record "Salesperson/Purchaser";
        DestinationRecordRef: RecordRef;
        SourceRecordRef: RecordRef;
        SkipItem: Boolean;
    begin
        // [FEATURE] [Table Subscriber] [Salesperson]
        Initialize();

        LibraryCRMIntegration.RegisterTestTableConnection();
        // [GIVEN] Valid setup
        // [GIVEN] A new SalesPerson record
        // [WHEN] Executing before insert step
        // [THEN] The code field should be set and be unique
        SalespersonPurchaser.Init();
        DestinationRecordRef.GetTable(SalespersonPurchaser);
        SkipItem := false;
        CRMIntTableSubscriber.OnBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);

        DestinationRecordRef.SetTable(SalespersonPurchaser);
        Assert.IsFalse(SkipItem, 'Did not expect the ShipItem flag to be set');
        Assert.AreNotEqual('', SalespersonPurchaser.Code, 'Expected the code field to be set');
        SalespersonPurchaser.Insert();

        SecondSalespersonPurchaser.Init();
        DestinationRecordRef.GetTable(SecondSalespersonPurchaser);
        SkipItem := false;
        CRMIntTableSubscriber.OnBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);

        DestinationRecordRef.SetTable(SecondSalespersonPurchaser);
        Assert.IsFalse(SkipItem, 'Did not expect the ShipItem flag to be set');
        Assert.AreNotEqual('', SecondSalespersonPurchaser.Code, 'Expected the code field to be set');

        Assert.AreNotEqual(SalespersonPurchaser.Code, SecondSalespersonPurchaser.Code, 'Expected a unique code');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCRMAccountAfterTransferRecordFields()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        NewSalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        NewCRMSystemuser: Record "CRM Systemuser";
        CRMIntTableSubscriber: Codeunit "CRM Int. Table. Subscriber";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        DefaultCRMTransactionCurrencyId: Guid;
        AdditionalFieldsWereModified: Boolean;
    begin
        // [FEATURE] [Table Subscriber] [Salesperson]
        Initialize();

        LibraryCRMIntegration.RegisterTestTableConnection();
        DefaultCRMTransactionCurrencyId := LibraryCRMIntegration.GetGLSetupCRMTransactionCurrencyID();
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] Valid setup
        // [GIVEN] Source different from Customer or Destination different from CRMAccount
        // [WHEN] Executing after transfer
        // [THEN] No change is expected.
        AdditionalFieldsWereModified := false;
        CRMIntTableSubscriber.OnAfterTransferRecordFields(
          SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);

        // [GIVEN] Valid setup
        // [GIVEN] CRMSystemUser to Salespeople Map
        // [GIVEN] Valid source and Destination
        // [GIVEN] A change in the owner
        // [WHEN] Executing after transfer
        // [THEN] The owner is updated
        ResetDefaultCRMSetupConfiguration(); // Create all maps including the salespeople map
        AdditionalFieldsWereModified := false;
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify();
        CRMAccount.OwnerId := CRMSystemuser.SystemUserId;
        CRMAccount.TransactionCurrencyId := DefaultCRMTransactionCurrencyId;
        CRMAccount.Modify();

        SourceRecordRef.GetTable(Customer);
        DestinationRecordRef.GetTable(CRMAccount);
        // [WHEN] Executing after transfer
        CRMIntTableSubscriber.OnAfterTransferRecordFields(
          SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);
        // [THEN] The AdditionalFieldsWereModified flag is not set
        Assert.IsFalse(AdditionalFieldsWereModified, 'Did not expect the flag to be set when all fields are as expected.');

        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(NewSalespersonPurchaser, NewCRMSystemuser);
        Customer."Salesperson Code" := NewSalespersonPurchaser.Code;
        Customer.Modify();
        SourceRecordRef.GetTable(Customer);

        Assert.AreNotEqual(Format(NewCRMSystemuser.SystemUserId),
          Format(DestinationRecordRef.Field(CRMAccount.FieldNo(OwnerId)).Value),
          'Did not expect the current owner to match the new owner yet');

        // [WHEN] Executing after transfer
        AdditionalFieldsWereModified := false;
        CRMIntTableSubscriber.OnAfterTransferRecordFields(
          SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, true);
        // [THEN] The AdditionalFieldsWereModified flag is not set
        Assert.IsFalse(AdditionalFieldsWereModified, 'Expected the flag not to be set when changing the owner');

        Assert.AreNotEqual(Format(NewCRMSystemuser.SystemUserId),
          Format(DestinationRecordRef.Field(CRMAccount.FieldNo(OwnerId)).Value),
          'Expected the current owner not to match the new owner');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCallUpdateSalespersonCodeIfChangedIfOwnerIsOfTypeTeam()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [FEATURE] [CRM Synch. Helper] [Salesperson]
        Initialize();
        ResetDefaultCRMSetupConfiguration();
        // [GIVEN] A mapping exists for salespeople - CRM systemusers
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
        IntegrationTableMapping.SetRange("Integration Table ID", DATABASE::"CRM Systemuser");
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Expected a mapping between salespeople and CRM Systemusers');

        // [GIVEN] CRM User coupled to Salesperson
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] CRM Account with new OwnerID set
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        CRMAccount.OwnerId := CRMSystemuser.SystemUserId;
        // [GIVEN] CRM Account OwnerType is set to Team
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::team;

        SourceRecordRef.GetTable(CRMAccount);
        DestinationRecordRef.Open(DATABASE::Customer, true);

        // [WHEN] Calling UpdateSalesPersonCodeIfChanged
        // [THEN] Error occurs
        asserterror CRMSynchHelper.UpdateSalesPersonCodeIfChanged(
            SourceRecordRef, DestinationRecordRef, CRMAccount.FieldNo(OwnerId), CRMAccount.FieldNo(OwnerIdType),
            CRMAccount.OwnerIdType::systemuser, Customer.FieldNo("Salesperson Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCallUpdateSalespersonCodeIfChangedIfOwnerIsOfTypeTeamAndMappingDoesNotExist()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [FEATURE] [CRM Synch. Helper] [Salesperson]
        Initialize();
        ResetDefaultCRMSetupConfiguration();
        // [GIVEN] No mapping exists for salespeople - CRM systemusers
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
        IntegrationTableMapping.SetRange("Integration Table ID", DATABASE::"CRM Systemuser");
        IntegrationTableMapping.DeleteAll(true);
        Assert.IsFalse(IntegrationTableMapping.FindFirst(), 'Did not expect a mapping between salespeople and CRM Systemusers');

        // [GIVEN] CRM User coupled to Salesperson
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] CRM Account with new OwnerID set
        LibraryCRMIntegration.CreateCRMAccount(CRMAccount);
        CRMAccount.OwnerId := CRMSystemuser.SystemUserId;
        // [GIVEN] CRM Account OwnerType is set to Team
        CRMAccount.OwnerIdType := CRMAccount.OwnerIdType::team;

        SourceRecordRef.GetTable(CRMAccount);
        DestinationRecordRef.Open(DATABASE::Customer, true);

        // [WHEN] Calling UpdateSalesPersonCodeIfChanged
        // [THEN] No error occurs and salesperson code is not updated
        Assert.IsFalse(
          CRMSynchHelper.UpdateSalesPersonCodeIfChanged(
            SourceRecordRef, DestinationRecordRef, CRMAccount.FieldNo(OwnerId), CRMAccount.FieldNo(OwnerIdType),
            CRMAccount.OwnerIdType::systemuser, Customer.FieldNo("Salesperson Code")),
          'Did not exect the UpdateSalesPersonCodeIfChanged to return true.');
        DestinationRecordRef.SetTable(Customer);
        Assert.AreNotEqual(
          SalespersonPurchaser.Code, Customer."Salesperson Code",
          'Did not expect the Customer Salesperson Code to be updated when there is no map.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotCallUpdateOwnerIfChangedIfSalespersonIsNotCoupled()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [FEATURE] [CRM Synch. Helper] [Salesperson]
        Initialize();
        ResetDefaultCRMSetupConfiguration();

        // [GIVEN] A mapping exists for salespeople - CRM systemusers
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
        IntegrationTableMapping.SetRange("Integration Table ID", DATABASE::"CRM Systemuser");
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Expected a mapping between salespeople and CRM Systemusers');

        // [GIVEN] CRM User coupled to Salesperson
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] Customer with new salesperson code
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;

        SourceRecordRef.GetTable(Customer);
        DestinationRecordRef.GetTable(CRMAccount);

        // [WHEN] Calling UpdateSalesPersonCodeIfChanged
        // [THEN] Error occurs
        asserterror CRMSynchHelper.UpdateOwnerIfChanged(
            SourceRecordRef, DestinationRecordRef, CRMAccount.FieldNo(OwnerId), CRMAccount.FieldNo(OwnerIdType),
            CRMAccount.OwnerIdType::systemuser, Customer.FieldNo("Salesperson Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCallUpdateOwnerIfChangedIfSalespersonIsNotCoupledIfMappingDoesNotExist()
    var
        CRMAccount: Record "CRM Account";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
    begin
        // [FEATURE] [CRM Synch. Helper] [Salesperson]
        Initialize();
        ResetDefaultCRMSetupConfiguration();

        // [GIVEN] No mapping exists for salespeople - CRM systemusers
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Salesperson/Purchaser");
        IntegrationTableMapping.SetRange("Integration Table ID", DATABASE::"CRM Systemuser");
        IntegrationTableMapping.DeleteAll(true);

        // [GIVEN] CRM User coupled to Salesperson
        LibraryCRMIntegration.CreateCoupledSalespersonAndSystemUser(SalespersonPurchaser, CRMSystemuser);

        // [GIVEN] Customer with new salesperson code
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;

        SourceRecordRef.GetTable(Customer);
        DestinationRecordRef.GetTable(CRMAccount);

        // [WHEN] Calling UpdateSalesPersonCodeIfChanged
        // [THEN] Error does not occur
        CRMSynchHelper.UpdateOwnerIfChanged(
          SourceRecordRef, DestinationRecordRef, CRMAccount.FieldNo(OwnerId), CRMAccount.FieldNo(OwnerIdType),
          CRMAccount.OwnerIdType::systemuser, Customer.FieldNo("Salesperson Code"));
    end;

    local procedure Initialize()
    begin
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
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

