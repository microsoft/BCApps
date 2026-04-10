codeunit 136205 "Marketing Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Marketing]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        SalespersonCode: Code[20];
        SalesCycleCodeError: Label 'You must fill in the %1 field.';
        SalutationCode: Code[10];
        ExpectedMessage: Label 'The field IBAN is mandatory. You will not be able to use the account in a payment file until the IBAN is correctly filled in.\\Are you sure you want to continue?';
        ControlVisibilityErr: Label 'Control visibility should be %1.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Setup");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Setup");

        LibraryTemplates.EnableTemplatesFeature();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Setup");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuesWithInheritance()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
    begin
        // Covers document number TC0029 - refer to TFS ID 21737.
        // Test values on Contact of Type Person successfully updated with values on Contact of Type Company on updating Company No. on
        // Contact with Inheritance Setup.

        // 1. Setup: Create Contact of Type Company and Update all values marked on Inheritance Setup on Contact.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        UpdateContact(Contact);

        // 2. Exercise: Create Contact of Type Person and Assign Company No. equal Contact no. of Type Company.
        LibraryMarketing.CreateCompanyContact(Contact2);
        Contact2.Validate(Type, Contact2.Type::Person);
        Contact2.Validate("Company No.", Contact."No.");
        Contact2.Modify(true);

        // 3. Verify: Verify values on Contact of Type Person successfully updated.
        Contact2.TestField("Salesperson Code", Contact."Salesperson Code");
        Contact2.TestField("Territory Code", Contact."Territory Code");
        Contact2.TestField("Country/Region Code", Contact."Country/Region Code");
        Contact2.TestField("Language Code", Contact."Language Code");
        Contact2.TestField(Address, Contact.Address);
        Contact2.TestField("E-Mail", Contact."E-Mail");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuesWOInheritance()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
    begin
        // Covers document number TC0029 - refer to TFS ID 21737.
        // Test values not updated on Contact of Type Person with values Contact of Type Company after updating Company No. on Contact
        // without Inheritance Setup.

        // 1. Setup: Create Contact of Type Company, Update all values marked on Inheritance Setup on Contact and Update all Values to
        // False on Inheritance Tab of Marketing Setup.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        UpdateContact(Contact);
        UpdateInheritanceSetup(false);

        // 2. Exercise: Create Contact of Type Person and Assign Company No. equal Contact no. of Type Company.
        LibraryMarketing.CreateCompanyContact(Contact2);
        Contact2.Validate(Type, Contact2.Type::Person);
        Contact2.Validate("Company No.", Contact."No.");
        Contact2.Modify(true);

        // 3. Verify: Verify No values update on Contact of Type Person.
        Contact2.TestField(Address, '');
        Contact2.TestField("E-Mail", '');

        // 4. Teardown: Update all Values to True on Inheritance Tab of Marketing Setup.
        UpdateInheritanceSetup(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDefaultValuesTypeCompany()
    begin
        // Covers document number TC0030 - refer to TFS ID 21737.
        // Test Default values not Update on Creation Contact of Type Company after clear Default values from Marketing Setup.

        NoDefaultValuesContact(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDefaultValuesTypePerson()
    begin
        // Covers document number TC0030 - refer to TFS ID 21737.
        // Test Default values not Update on Creation Contact of Type Person after clear Default values from Marketing Setup.

        NoDefaultValuesContact(true);
    end;

    local procedure NoDefaultValuesContact(PersonType: Boolean)
    var
        TempMarketingSetup: Record "Marketing Setup" temporary;
        Contact: Record Contact;
    begin
        // Covers document number TC0030 - refer to TFS ID 21737.
        // Test Default values not Update on Creation Contact of Type Person after clear Default values from Marketing Setup.

        // 1. Setup: Update Default values on Marketing Setup.
        Initialize();
        ClearDefaultValueSetup(TempMarketingSetup);

        // 2. Exercise: Create Contact of Type as per parameter.
        LibraryMarketing.CreateCompanyContact(Contact);
        if PersonType then begin
            Contact.Validate(Type, Contact.Type::Person);
            Contact.Modify(true);
        end;

        // 3. Verify: Verify No Default Values update on Contact.
        Contact.TestField("Territory Code", '');
        Contact.TestField("Country/Region Code", '');
        Contact.TestField("Language Code", '');
        Contact.TestField("Salutation Code", '');
        Contact.TestField("Correspondence Type", Contact."Correspondence Type"::" ");

        // 4. Teardown: Set all values to default Values on Marketing Setup.
        RollbackDefaultValueSetup(TempMarketingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultValuesTypeCompany()
    begin
        // Covers document number TC0030 - refer to TFS ID 21737.
        // Test Default values successfully update on Creation Contact of Type Company with Default values on Marketing Setup.

        DefaultValuesContact(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultValuesTypePerson()
    begin
        // Covers document number TC0030 - refer to TFS ID 21737.
        // Test Default values successfully update on Creation Contact of Type Person with Default values on Marketing Setup.

        DefaultValuesContact(true);
    end;

    local procedure DefaultValuesContact(PersonType: Boolean)
    var
        TempMarketingSetup: Record "Marketing Setup" temporary;
        MarketingSetup: Record "Marketing Setup";
        Contact: Record Contact;
    begin
        // Covers document number TC0030 - refer to TFS ID 21737.
        // Test Default values successfully update on Creation Contact of Type Person with Default values on Marketing Setup.

        // 1. Setup: Update Default values on Marketing Setup.
        Initialize();
        UpdateDefaultValueSetup(TempMarketingSetup, MarketingSetup);

        // 2. Exercise: Create Contact of Type as per parameter.
        LibraryMarketing.CreateCompanyContact(Contact);
        if PersonType then begin
            Contact.Validate(Type, Contact.Type::Person);
            Contact.Modify(true);
        end;

        // 3. Verify: Verify Default Values update on Contact.
        VerifyDefaultValueOnContact(Contact, MarketingSetup);

        // 4. Teardown: Set all values to default Values on Marketing Setup.
        RollbackDefaultValueSetup(TempMarketingSetup);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity')]
    [Scope('OnPrem')]
    procedure OpportunityWithSalesCycleCode()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        TempOpportunity: Record Opportunity temporary;
        SalesCycle: Record "Sales Cycle";
        MarketingSetup: Record "Marketing Setup";
        DefaultSalesCycleCode: Code[10];
    begin
        // Covers document number TC0031 - refer to TFS ID 21737.
        // Test Opportunity for contact successfully created with Default Sales Cycle Code on Marketing Setup.

        // 1. Setup: Create Contact and Update Default Sales Cycle Code on Marketing Setup.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);

        SalespersonCode := Contact."Salesperson Code";  // Set Global Variable for Form Handler.
        SalesCycle.FindFirst();
        MarketingSetup.Get();
        DefaultSalesCycleCode := MarketingSetup."Default Sales Cycle Code";
        MarketingSetup.Validate("Default Sales Cycle Code", SalesCycle.Code);
        MarketingSetup.Modify(true);

        // 2. Exercise: Create opportunity for Contact.
        Opportunity.SetRange("Contact No.", Contact."No.");
        TempOpportunity.CreateOppFromOpp(Opportunity);

        // 3. Verify: Verify Opportunity successfully created.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.TestField("Salesperson Code", Contact."Salesperson Code");

        // 4. Teardown: Set Default Sales Cycle Code on Marketing Setup to default value.
        MarketingSetup.Validate("Default Sales Cycle Code", DefaultSalesCycleCode);
        MarketingSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity')]
    [Scope('OnPrem')]
    procedure OpportunityWOSalesCycleCode()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        TempOpportunity: Record Opportunity temporary;
        MarketingSetup: Record "Marketing Setup";
        DefaultSalesCycleCode: Code[10];
    begin
        // Covers document number TC0031 - refer to TFS ID 21737.
        // Test error occurs on creation of Opportunity for Contact without Default Sales Cycle Code on Marketing Setup.

        // 1. Setup: Create Contact and Clear Default Sales Cycle Code on Marketing Setup.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);

        SalespersonCode := Contact."Salesperson Code";  // Set Global Variable for Form Handler.
        MarketingSetup.Get();
        DefaultSalesCycleCode := MarketingSetup."Default Sales Cycle Code";
        MarketingSetup.Validate("Default Sales Cycle Code", '');
        MarketingSetup.Modify(true);

        // 2. Exercise: Create opportunity for Contact.
        Opportunity.SetRange("Contact No.", Contact."No.");
        asserterror TempOpportunity.CreateOppFromOpp(Opportunity);

        // 3. Verify: Verify error Occurs on creation of Opportunity for Contact without Default Sales Cycle Code on Marketing Setup.
        Assert.AreEqual(StrSubstNo(SalesCycleCodeError, Opportunity.FieldCaption("Sales Cycle Code")), GetLastErrorText, '');

        // 4. Teardown: Set Default Sales Cycle Code on Marketing Setup to default value.
        MarketingSetup.Validate("Default Sales Cycle Code", DefaultSalesCycleCode);
        MarketingSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactFromCustomerWithSetup()
    var
        Customer: Record Customer;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        DefaultBusRelCodeforCustomers: Code[10];
    begin
        // Covers document number TC0032 - refer to TFS ID 21737.
        // Test Contact successfully created on creation of Customer with Bus. Relation Code for Customers on Marketing Setup.

        // 1. Setup: Set value of Bus. Relation Code for Customers on Marketing Setup.
        Initialize();
        BusinessRelation.FindFirst();
        DefaultBusRelCodeforCustomers := UpdateBusRelCodeforCustomers(BusinessRelation.Code);

        // 2. Exercise: Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // 3. Verify: Verify Contact Business Relation and Contact successfully created.
        VerifyContact(ContactBusinessRelation."Link to Table"::Customer, Customer."No.");

        // 4. Teardown: Set Default value of Bus. Relation Code for Customers on Marketing Setup.
        UpdateBusRelCodeforCustomers(DefaultBusRelCodeforCustomers);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactFromVendorWithSetup()
    var
        Vendor: Record Vendor;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        LibraryPurchase: Codeunit "Library - Purchase";
        DefaultBusRelCodeforVendors: Code[10];
    begin
        // Covers document number TC0032 - refer to TFS ID 21737.
        // Test Contact successfully created on creation of Vendor with Bus. Relation Code for Vendors on Marketing Setup.

        // 1. Setup: Set value of Bus. Relation Code for Vendors on Marketing Setup.
        Initialize();
        BusinessRelation.FindFirst();
        DefaultBusRelCodeforVendors := UpdateBusRelCodeforVendors(BusinessRelation.Code);

        // 2. Exercise: Create Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // 3. Verify: Verify Contact Business Relation and Contact successfully created.
        VerifyContact(ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");

        // 4. Teardown: Set Default value of Bus. Relation Code for Vendors on Marketing Setup.
        UpdateBusRelCodeforVendors(DefaultBusRelCodeforVendors);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ContactFromBankWithSetup()
    var
        BankAccount: Record "Bank Account";
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        LibraryERM: Codeunit "Library - ERM";
        DefaultBusRelCodeforBankAccs: Code[10];
    begin
        // Covers document number TC0032 - refer to TFS ID 21737.
        // Test Contact successfully created on creation of Bank Account with Bus. Relation Code for Bank Acc. on Marketing Setup.

        // 1. Setup: Set value of Bus. Relation Code for Bank Acc. on Marketing Setup.
        Initialize();
        ExecuteUIHandler();
        BusinessRelation.FindFirst();
        DefaultBusRelCodeforBankAccs := UpdateBusRelCodeforBankAccount(BusinessRelation.Code);

        // 2. Exercise: Create Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // 3. Verify: Verify Contact Business Relation and Contact successfully created.
        VerifyContact(ContactBusinessRelation."Link to Table"::"Bank Account", BankAccount."No.");

        // 4. Teardown: Set Default value of Bus. Relation Code for Bank Acc. on Marketing Setup.
        UpdateBusRelCodeforBankAccount(DefaultBusRelCodeforBankAccs);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorFromContactWithSetup()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        Vendor: Record Vendor;
        BusinessRelation: Record "Business Relation";
        DefaultBusRelCodeforVendors: Code[10];
    begin
        // Covers document number TC0032 - refer to TFS ID 21737.
        // Test Vendor successfully created from Contact with Bus. Relation Code for Vendors on Marketing Setup.

        // 1. Setup: Set value of Bus. Relation Code for Vendors on Marketing Setup and Create Contact.
        Initialize();
        BusinessRelation.FindFirst();
        DefaultBusRelCodeforVendors := UpdateBusRelCodeforVendors(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Create Vendor from Contact.
        Contact.CreateVendorFromTemplate('');

        // 3. Verify: Verify Contact Business Relation and Vendor successfully created.
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.FindFirst();

        Vendor.Get(ContactBusinessRelation."No.");

        // 4. Teardown: Set Default value of Bus. Relation Code for Vendors on Marketing Setup.
        UpdateBusRelCodeforVendors(DefaultBusRelCodeforVendors);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure BankFromContactWithSetup()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        BankAccount: Record "Bank Account";
        BusinessRelation: Record "Business Relation";
        DefaultBusRelCodeforBankAccs: Code[10];
    begin
        // Covers document number TC0032 - refer to TFS ID 21737.
        // Test Bank Account successfully created from Contact with Bus. Relation Code for Bank Acc. on Marketing Setup.

        // 1. Setup: Set value of Bus. Relation Code for Bank Acc. on Marketing Setup and Create Contact.
        Initialize();
        BusinessRelation.FindFirst();
        DefaultBusRelCodeforBankAccs := UpdateBusRelCodeforBankAccount(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Create Bank Account from Contact.
        Contact.CreateBankAccount();

        // 3. Verify: Verify Contact Business Relation and Bank Account successfully created.
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::"Bank Account");
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.FindFirst();

        BankAccount.Get(ContactBusinessRelation."No.");

        // 4. Teardown: Set Default value of Bus. Relation Code for Bank Acc. on Marketing Setup.
        UpdateBusRelCodeforBankAccount(DefaultBusRelCodeforBankAccs);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCampaignWithSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        Campaign: Record Campaign;
    begin
        // Covers document number TC0033 - refer to TFS ID 21737.
        // Test Campaign successfully created with Campaign Nos. on Marketing Setup.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Campaign.
        LibraryMarketing.CreateCampaign(Campaign);

        // 3. Verify: Verify Campaign successfully created.
        MarketingSetup.Get();
        Campaign.Get(Campaign."No.");
        Campaign.TestField("No. Series", MarketingSetup."Campaign Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSegmentWithSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        SegmentHeader: Record "Segment Header";
    begin
        // Covers document number TC0033 - refer to TFS ID 21737.
        // Test Segment Header successfully created with Segment Nos. on Marketing Setup.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Segment Header.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);

        // 3. Verify: Verify Segment Header successfully created.
        MarketingSetup.Get();
        SegmentHeader.Get(SegmentHeader."No.");
        SegmentHeader.TestField("No. Series", MarketingSetup."Segment Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckContactWithSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        Contact: Record Contact;
    begin
        // Covers document number TC0033 - refer to TFS ID 21737.
        // Test Contact successfully created with Contact Nos. on Marketing Setup.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Contact.
        LibraryMarketing.CreateCompanyContact(Contact);

        // 3. Verify: Verify Contact successfully created.
        MarketingSetup.Get();
        Contact.Get(Contact."No.");
        Contact.TestField("No. Series", MarketingSetup."Contact Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCampaignWOSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        Campaign: Record Campaign;
    begin
        // Covers document number TC0033 - refer to TFS ID 21737.
        // Test error occurs on creation of Campaign without Campaign Nos. on Marketing Setup.

        // 1. Setup: Clear Campaign Nos. on Marketing Setup.
        Initialize();
        MarketingSetup.Get();
        MarketingSetup.Validate("Campaign Nos.", '');
        MarketingSetup.Modify(true);

        // 2. Exercise: Create Campaign.
        Campaign.Init();
        asserterror Campaign.Insert(true);

        // 3. Verify: Verify error occurs on creation of Campaign.
        VerifyFieldError(MarketingSetup.FieldCaption("Campaign Nos."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSegmentWOSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        SegmentHeader: Record "Segment Header";
    begin
        // Covers document number TC0033 - refer to TFS ID 21737.
        // Test error occurs on creation of Segment Header without Segment Nos. on Marketing Setup.

        // 1. Setup: Clear Segment Nos. on Marketing Setup.
        Initialize();
        MarketingSetup.Get();
        MarketingSetup.Validate("Segment Nos.", '');
        MarketingSetup.Modify(true);

        // 2. Exercise: Create Segment Header.
        SegmentHeader.Init();
        asserterror SegmentHeader.Insert(true);

        // 3. Verify: Verify error occurs on creation of Segment Header.
        VerifyFieldError(MarketingSetup.FieldCaption("Segment Nos."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckContactWOSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        Contact: Record Contact;
    begin
        // Covers document number TC0033 - refer to TFS ID 21737.
        // Test error occurs on creation of Contact without Contact Nos. on Marketing Setup.

        // 1. Setup: Clear Contact Nos. on Marketing Setup.
        Initialize();
        MarketingSetup.Get();
        MarketingSetup.Validate("Contact Nos.", '');
        MarketingSetup.Modify(true);

        // 2. Exercise: Create Contact.
        Contact.Init();
        asserterror Contact.Insert(true);

        // 3. Verify: Verify error occurs on creation of Contact.
        VerifyFieldError(MarketingSetup.FieldCaption("Contact Nos."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerForTask')]
    [Scope('OnPrem')]
    procedure CheckTaskWOSetup()
    var
        MarketingSetup: Record "Marketing Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // Covers document number TC0033 - refer to TFS ID 21737.
        // Test error occurs on creation of Task for Salesperson without Task Nos. on Marketing Setup.

        // 1. Setup: Clear Task Nos. on Marketing Setup.
        Initialize();
        MarketingSetup.Get();
        MarketingSetup.Validate("To-do Nos.", '');
        MarketingSetup.Modify(true);

        // 2. Exercise: Create Salesperson and Task.
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        Task.SetRange("Salesperson Code", SalespersonPurchaser.Code);
        asserterror TempTask.CreateTaskFromTask(Task);

        // 3. Verify: Verify error occurs on creation of Task.
        VerifyFieldError(MarketingSetup.FieldCaption("To-do Nos."));
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerOpportunity')]
    [Scope('OnPrem')]
    procedure CheckOpportunityWOSetup()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        TempOpportunity: Record Opportunity temporary;
        MarketingSetup: Record "Marketing Setup";
        SalesCycle: Record "Sales Cycle";
    begin
        // Covers document number TC0033 - refer to TFS ID 21737.
        // Test error occurs on creation of Opportunity for Contact without Opportunity Nos. on Marketing Setup.

        // 1. Setup: Create Contact and Clear Opportunity Nos. on Marketing Setup.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);

        SalespersonCode := Contact."Salesperson Code";  // Set Global Variable for Form Handler.
        SalesCycle.FindFirst();
        MarketingSetup.Get();
        MarketingSetup.Validate("Default Sales Cycle Code", SalesCycle.Code);
        MarketingSetup.Validate("Opportunity Nos.", '');
        MarketingSetup.Modify(true);

        // 2. Exercise: Create Opportunity for contact.
        Opportunity.SetRange("Contact No.", Contact."No.");
        asserterror TempOpportunity.CreateOppFromOpp(Opportunity);

        // 3. Verify: Verify error occurs on creation of Opportunity.
        VerifyFieldError(MarketingSetup.FieldCaption("Opportunity Nos."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalutation()
    var
        Salutation: Record Salutation;
    begin
        // Covers document number TC0027 - refer to TFS ID 123227.
        // Test Salutation Successfully Created.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Salutation.
        LibraryMarketing.CreateSalutation(Salutation);

        // 3. Verify: Verify Salutation created.
        Salutation.Get(Salutation.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalutationFormulaFormal()
    var
        SalutationFormula: Record "Salutation Formula";
    begin
        // Covers document number TC0027 - refer to TFS ID 123227.
        // Test Salutation Formula created with Salutation Type Formal.

        CreateSalutationFormula(SalutationFormula."Salutation Type"::Formal, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalutationFormulaInformal()
    var
        SalutationFormula: Record "Salutation Formula";
    begin
        // Covers document number TC0027 - refer to TFS ID 123227.
        // Test Salutation Formula created with Salutation Type InFormal.

        CreateSalutationFormula(SalutationFormula."Salutation Type"::Informal, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalutationFormulaFormalLang()
    var
        SalutationFormula: Record "Salutation Formula";
    begin
        // Covers document number TC0027 - refer to TFS ID 123227.
        // Test Salutation Formula created with Salutation Type Formal with Language.

        CreateSalutationFormula(SalutationFormula."Salutation Type"::Formal, SelectLanguage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalutationFormulaInformalLang()
    var
        SalutationFormula: Record "Salutation Formula";
    begin
        // Covers document number TC0027 - refer to TFS ID 123227.
        // Test Salutation Formula created with Salutation Type InFormal with Language.

        CreateSalutationFormula(SalutationFormula."Salutation Type"::Informal, SelectLanguage());
    end;

    local procedure CreateSalutationFormula(SalutationType: Enum "Salutation Formula Salutation Type"; LanguageCode: Code[10])
    var
        Salutation: Record Salutation;
        SalutationFormula: Record "Salutation Formula";
    begin
        // 1. Setup: Create Salutation.
        Initialize();
        LibraryMarketing.CreateSalutation(Salutation);

        // 2. Exercise: Create and Update Salutation Formula with Specified SalutationType.
        LibraryMarketing.CreateSalutationFormula(SalutationFormula, Salutation.Code, LanguageCode, SalutationType);
        UpdateSalutationFormula(SalutationFormula);

        // 3. Verify: Verify Salutation Formula created with Specified SalutationType.
        SalutationFormula.Get(Salutation.Code, LanguageCode, SalutationType);
    end;

    [Test]
    [HandlerFunctions('ModalFormNameDetails')]
    [Scope('OnPrem')]
    procedure ContactSaluation()
    var
        Contact: Record Contact;
        Salutation: Record Salutation;
        NameDetails: Page "Name Details";
    begin
        // Covers document number TC0027 - refer to TFS ID 123227.
        // Test Salutation Code Successfully updated on Contact.

        // 1. Setup: Create Contact of Type Person and Salutation.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(Type, Contact.Type::Person);
        Contact.Modify(true);

        LibraryMarketing.CreateSalutation(Salutation);
        SalutationCode := Salutation.Code;  // Set Global Variable for Form Handler.

        // 2. Exercise: Run Name Details form and Update Salutation code on it.
        Clear(NameDetails);
        NameDetails.SetRecord(Contact);
        NameDetails.RunModal();

        // 3. Verify: Verify Salutation Code updated on Contact.
        Contact.Get(Contact."No.");
        Contact.TestField("Salutation Code", Salutation.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MarketingSetupGeneralFasstabNotVisibleSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        MarketingSetupPage: TestPage "Marketing Setup";
    begin
        // [SCENARIO 215623] Marketing Setup General fasstab should not be visible in SaaS
        Initialize();

        // [GIVEN] SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Marketing Setup Page is opened
        MarketingSetupPage.OpenEdit();

        // [THEN] Fields of General fasttab are not visible
        Assert.IsFalse(
          MarketingSetupPage."Attachment Storage Type".Visible(),
          StrSubstNo(ControlVisibilityErr, false));
        Assert.IsFalse(
          MarketingSetupPage."Attachment Storage Location".Visible(),
          StrSubstNo(ControlVisibilityErr, false));
        MarketingSetupPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MarketingSetupGeneralFasstabVisiblePaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        MarketingSetupPage: TestPage "Marketing Setup";
    begin
        // [SCENARIO 215623] Marketing Setup General fasstab should be visible in on-prem and in PaaS
        Initialize();

        // [GIVEN] on-prem or PaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] Marketing Setup Page is opened
        MarketingSetupPage.OpenEdit();

        // [THEN] Fields of General fasttab are visible
        Assert.IsTrue(
          MarketingSetupPage."Attachment Storage Type".Visible(),
          StrSubstNo(ControlVisibilityErr, true));
        Assert.IsTrue(
          MarketingSetupPage."Attachment Storage Location".Visible(),
          StrSubstNo(ControlVisibilityErr, true));
        MarketingSetupPage.Close();
    end;

    local procedure ClearDefaultValueSetup(var TempMarketingSetup: Record "Marketing Setup" temporary)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        TempMarketingSetup.Init();
        TempMarketingSetup := MarketingSetup;
        TempMarketingSetup.Insert();
        MarketingSetup.Validate("Default Territory Code", '');
        MarketingSetup.Validate("Default Country/Region Code", '');
        MarketingSetup.Validate("Default Language Code", '');
        MarketingSetup.Validate("Default Person Salutation Code", '');
        MarketingSetup.Validate("Def. Company Salutation Code", '');
        MarketingSetup.Validate("Default Correspondence Type", MarketingSetup."Default Correspondence Type"::" ");
        MarketingSetup.Modify(true);
    end;

    local procedure RollbackDefaultValueSetup(var TempMarketingSetup: Record "Marketing Setup" temporary)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Default Territory Code", TempMarketingSetup."Default Territory Code");
        MarketingSetup.Validate("Default Country/Region Code", TempMarketingSetup."Default Country/Region Code");
        MarketingSetup.Validate("Default Language Code", TempMarketingSetup."Default Language Code");
        MarketingSetup.Validate("Default Person Salutation Code", TempMarketingSetup."Default Person Salutation Code");
        MarketingSetup.Validate("Def. Company Salutation Code", TempMarketingSetup."Def. Company Salutation Code");
        MarketingSetup.Validate("Default Correspondence Type", TempMarketingSetup."Default Correspondence Type");
        MarketingSetup.Modify(true);
    end;

    local procedure SelectLanguage(): Code[10]
    var
        Language: Record Language;
    begin
        Language.FindFirst();
        exit(Language.Code);
    end;

    local procedure UpdateBusRelCodeforBankAccount(BusRelCodeforBankAccs: Code[10]) DefaultBusRelCodeforBankAccs: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        DefaultBusRelCodeforBankAccs := MarketingSetup."Bus. Rel. Code for Bank Accs.";
        MarketingSetup.Validate("Bus. Rel. Code for Bank Accs.", BusRelCodeforBankAccs);
        MarketingSetup.Modify(true);
    end;

    local procedure UpdateBusRelCodeforCustomers(BusRelCodeforCustomers: Code[10]) DefaultBusRelCodeforCustomers: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        DefaultBusRelCodeforCustomers := MarketingSetup."Bus. Rel. Code for Customers";
        MarketingSetup.Validate("Bus. Rel. Code for Customers", BusRelCodeforCustomers);
        MarketingSetup.Modify(true);
    end;

    local procedure UpdateBusRelCodeforVendors(BusRelCodeforVendors: Code[10]) DefaultBusRelCodeforVendors: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        DefaultBusRelCodeforVendors := MarketingSetup."Bus. Rel. Code for Vendors";
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", BusRelCodeforVendors);
        MarketingSetup.Modify(true);
    end;

    local procedure UpdateContact(var Contact: Record Contact)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Territory: Record Territory;
        CountryRegion: Record "Country/Region";
        Language: Record Language;
    begin
        SalespersonPurchaser.FindFirst();
        Territory.FindFirst();
        CountryRegion.FindFirst();
        Language.FindFirst();
        Contact.Validate(Type, Contact.Type::Company);
        Contact.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Contact.Validate("Territory Code", Territory.Code);
        Contact.Validate("Country/Region Code", CountryRegion.Code);
        Contact.Validate("Language Code", Language.Code);
        Contact.Validate(Address, LibraryUtility.GenerateRandomCode(Contact.FieldNo(Address), DATABASE::Contact));
        Contact.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Contact.Modify(true);
    end;

    local procedure UpdateDefaultValueSetup(var TempMarketingSetup: Record "Marketing Setup" temporary; var MarketingSetup: Record "Marketing Setup")
    var
        Territory: Record Territory;
        CountryRegion: Record "Country/Region";
        Language: Record Language;
        Salutation: Record Salutation;
    begin
        Territory.FindFirst();
        CountryRegion.FindFirst();
        Language.FindFirst();
        Salutation.FindSet();

        MarketingSetup.Get();
        TempMarketingSetup.Init();
        TempMarketingSetup := MarketingSetup;
        TempMarketingSetup.Insert();

        MarketingSetup.Validate("Default Territory Code", Territory.Code);
        MarketingSetup.Validate("Default Country/Region Code", CountryRegion.Code);
        MarketingSetup.Validate("Default Language Code", Language.Code);
        MarketingSetup.Validate("Default Person Salutation Code", Salutation.Code);
        Salutation.Next();
        MarketingSetup.Validate("Def. Company Salutation Code", Salutation.Code);
        MarketingSetup.Validate("Default Correspondence Type", MarketingSetup."Default Correspondence Type"::"Hard Copy");
        MarketingSetup.Modify(true);
    end;

    local procedure UpdateInheritanceSetup(Value: Boolean)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Inherit Address Details", Value);
        MarketingSetup.Validate("Inherit Communication Details", Value);
        MarketingSetup.Modify(true);
    end;

    local procedure UpdateSalutationFormula(var SalutationFormula: Record "Salutation Formula")
    begin
        SalutationFormula.Validate("Name 1", SalutationFormula."Name 1"::"Company Name");
        SalutationFormula.Validate("Name 2", SalutationFormula."Name 2"::Initials);
        SalutationFormula.Validate("Name 3", SalutationFormula."Name 3"::Surname);
        SalutationFormula.Validate("Name 4", SalutationFormula."Name 4"::"Middle Name");
        SalutationFormula.Validate("Name 5", SalutationFormula."Name 5"::"First Name");
    end;

    local procedure VerifyContact(LinkToTable: Enum "Contact Business Relation Link To Table"; No: Code[20])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", No);
        ContactBusinessRelation.FindFirst();

        Contact.Get(ContactBusinessRelation."Contact No.");
    end;

    local procedure VerifyDefaultValueOnContact(var Contact: Record Contact; MarketingSetup: Record "Marketing Setup")
    begin
        Contact.TestField("Territory Code", MarketingSetup."Default Territory Code");
        Contact.TestField("Country/Region Code", MarketingSetup."Default Country/Region Code");
        Contact.TestField("Language Code", MarketingSetup."Default Language Code");
        Contact.TestField("Salutation Code", MarketingSetup."Def. Company Salutation Code");
        Contact.TestField("Correspondence Type", MarketingSetup."Default Correspondence Type");
    end;

    local procedure VerifyFieldError(FieldCaption: Text[30])
    begin
        Assert.ExpectedTestFieldError(FieldCaption, '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerForTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate(Type, TempTask.Type::" ");
        TempTask.Validate(Description, TempTask."Salesperson Code");
        TempTask.Validate(Date, WorkDate());

        TempTask.CheckStatus();
        TempTask.FinishWizard(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerOpportunity(var CreateOpportunity: Page "Create Opportunity"; var Response: Action)
    var
        TempOpportunity: Record Opportunity temporary;
    begin
        TempOpportunity.Init();
        CreateOpportunity.GetRecord(TempOpportunity);
        TempOpportunity.Insert();
        TempOpportunity.Validate("Salesperson Code", SalespersonCode);
        TempOpportunity.Validate(
          Description, LibraryUtility.GenerateRandomCode(TempOpportunity.FieldNo(Description), DATABASE::Opportunity));
        TempOpportunity.Modify();

        TempOpportunity.CheckStatus();
        TempOpportunity.FinishWizard();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormNameDetails(var NameDetails: Page "Name Details"; var Response: Action)
    var
        Contact: Record Contact;
    begin
        Contact.Init();
        NameDetails.GetRecord(Contact);
        Contact.Validate("Salutation Code", SalutationCode);
        Contact.Modify(true);
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;
}

