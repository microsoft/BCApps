codeunit 136201 "Marketing Contacts"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Contact] [Marketing]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryNotificationMgt: codeunit "Library - Notification Mgt.";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        IsInitialized: Boolean;
        ValidationError: Label '%1: %2 must exist.';
        ErrorMessage: Label '%1: %2 must not exist.';
        ExpectedMessage: Label 'The field IBAN is mandatory. You will not be able to use the account in a payment file until the IBAN is correctly filled in.\\Are you sure you want to continue?';
        BusinessRelationError: Label '%1 %2 already has a Contact Business Relation with %3 %4.', Comment = '%1: Table Caption;%2: Field Value,%3: Table Caption2; %4: Field Value2';
        WrongDescriptionFieldLengthErr: Label 'Wrong description field length in table %1.';
        EmptyAttachmentErr: Label 'The attachment is empty';
        ExtensionTxt: Label 'txt';
        WrongCalcdCurValueErr: Label '%1 should be updated with "Sales (LCY)" value.';
        BusRelContactValidationErr: Label '%1 %2 is used when a %3 is linked with a %4.', Comment = '.';
        WrongValueErr: Label 'Function returned wrong value';
        SelectCustomerTemplateQst: Label 'Do you want to select the customer template?';
        CustTemplateListErr: Label 'Customer Template List contains wrong data.';
        YouCanGetContactFromCustTxt: Label 'You can create contacts automatically from newly created customers.';
        YouCanGetContactFromVendTxt: Label 'You can create contacts automatically from newly created vendors.';
        CustomerContNotifTok: Label '351199d7-6c9b-40f1-8e78-ff9e67c546c9';
        VendorContNotifTok: Label '08db77db-1f41-4379-8615-1b581a0225fa';
        RelationAlreadyExistWithVendorErr: Label 'Contact %1 already has a %2 with Vendor %3.', Comment = '%1=Contact table caption;%2=Contact number;%3=Contact Business Relation table caption;%4=Contact Business Relation Link to Table value;%5=Contact Business Relation number';
        RelationAlreadyExistWithCustomerErr: Label 'Contact %1 already has a %2 with Customer %3.', Comment = '%1=Contact table caption;%2=Contact number;%3=Contact Business Relation table caption;%4=Contact Business Relation Link to Table value;%5=Contact Business Relation number';
        ContactNotRelatedToVendorErr: Label 'Contact %1 %2 is not related to vendor %3 %4.';
        ContactNotRelatedToCustomerErr: Label 'Contact %1 %2 is not related to customer %3 %4.';
        ExpectedToFindRecErr: Label 'Expected to find Contact Business Relation record.';
        DuplicateContactsMsg: Label 'There are duplicate contacts.';
        ItemDimensionAllowedFilter: Label 'Allowed Dimension filter must match in both Item template and Item.';
        ValueMustMatch: Label 'Value must match.';
        SelectVendorTemplateQst: Label 'Do you want to select the vendor template?';

    [Test]
    procedure ContactBusinessRelationCompatibility()
    var
        ContactBusinessRelation: Enum "Contact Business Relation";
        ContactBusinessRelationLinkToTable: Enum "Contact Business Relation Link To Table";
        EnumValue: Integer;
        Index: Integer;
        ValueExist: Boolean;
    begin
        // [SCENARIO] Enum "Contact Business Relation Link To Table" is a subset of Enum "Contact Business Relation"
        foreach EnumValue in ContactBusinessRelationLinkToTable.Ordinals() do begin
            Index += 1;
            ValueExist := ContactBusinessRelation.Ordinals().Get(Index, EnumValue);
            Assert.IsTrue(ValueExist, StrSubstNo('%1 - %2', Index, EnumValue));
            Assert.AreEqual(
                ContactBusinessRelationLinkToTable.Names().Get(Index),
                ContactBusinessRelation.Names().Get(Index), 'Different enum values');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AlternativeAddressForContact()
    var
        Contact: Record Contact;
        ContactAltAddress: Record "Contact Alt. Address";
        ContactAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        // Covers document number TC0054 - refer to TFS ID 21740.
        // Test assignment and activation of Alternative Address linked to a Contact.

        // 1. Setup: Create a new Contact, Contact Alternative Address and Contact Alternative Address Date Range.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(
          Address,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Contact.FieldNo(Address), DATABASE::Contact),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Contact, Contact.FieldNo(Address))));
        Contact.Modify(true);

        LibraryMarketing.CreateContactAltAddress(ContactAltAddress, Contact."No.");
        LibraryMarketing.CreateContactAltAddrDateRange(ContactAltAddrDateRange, Contact."No.", WorkDate());
        ContactAltAddrDateRange.Validate("Contact Alt. Address Code", ContactAltAddress.Code);
        ContactAltAddrDateRange.Modify(true);

        // 2. Exercise: Create a new Segment Header for the date range in which alternative address is activated, Segment Line and link the
        // Contact to the Segment Line.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);

        // 3. Verify: Check that the Contact Alternative Address Code on the Segment Line is the same as that created earlier.
        SegmentLine.TestField("Contact Alt. Address Code", ContactAltAddress.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IndustryGroupForContact()
    var
        Contact: Record Contact;
        ContactIndustryGroup: Record "Contact Industry Group";
        IndustryGroup: Record "Industry Group";
    begin
        // Covers document number TC0054 - refer to TFS ID 21740.
        // Test creation and linking of Industry Group for Contact.

        // 1. Setup: Create a new Contact. Find an Industry Group.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        IndustryGroup.FindFirst();

        // 2. Exercise: Create a Contact Industry Group for the Contact created earlier.
        LibraryMarketing.CreateContactIndustryGroup(ContactIndustryGroup, Contact."No.", IndustryGroup.Code);

        // 3. Verify: Check that the field No. of Industry Groups on Contact is updated.
        Contact.CalcFields("No. of Industry Groups");
        Contact.TestField("No. of Industry Groups", 1);  // Value 1 is important to test case since one Industry Group has been linked.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BusinessRelationForContact()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // Covers document number TC0054 - refer to TFS ID 21740.
        // Test creation and linking of Business Relation for Contact.

        // 1. Setup: Create a new Contact, Business Relation.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);

        // 2. Exercise: Create a new Contact Business Relation for the Contact and Business Relation created earlier.
        LibraryMarketing.CreateContactBusinessRelation(ContactBusinessRelation, Contact."No.", BusinessRelation.Code);

        // 3. Verify: Check that the field No. of Business Relations on Contact is updated.
        Contact.CalcFields("No. of Business Relations");
        // Value 1 is important to test case since one Business Relation has been linked.
        Contact.TestField("No. of Business Relations", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailingGroupForContact()
    var
        Contact: Record Contact;
        MailingGroup: Record "Mailing Group";
        ContactMailingGroup: Record "Contact Mailing Group";
    begin
        // Covers document number TC0054 - refer to TFS ID 21740.
        // Test creation and linking of Mailing Group for Contact.

        // 1. Setup: Create a new Contact, Mailing Group.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateMailingGroup(MailingGroup);

        // 2. Exercise: Create a new Contact Mailing Group for the Contact and Mailing Group created earlier.
        LibraryMarketing.CreateContactMailingGroup(ContactMailingGroup, Contact."No.", MailingGroup.Code);

        // 3. Verify: Check that the field No. of Mailing Groups on Contact is updated.
        Contact.CalcFields("No. of Mailing Groups");
        Contact.TestField("No. of Mailing Groups", 1);  // Value 1 is important to test case since one Mailing Group has been linked.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactBusinessRelationDescription()
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        Initialize();
        Assert.AreEqual(
          LibraryUtility.GetFieldLength(DATABASE::"Business Relation", BusinessRelation.FieldNo(Description)),
          LibraryUtility.GetFieldLength(DATABASE::"Contact Business Relation",
            ContactBusinessRelation.FieldNo("Business Relation Description")),
          StrSubstNo(WrongDescriptionFieldLengthErr, ContactBusinessRelation.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactIndustryGroupDescription()
    var
        IndustryGroup: Record "Industry Group";
        ContactIndustryGroup: Record "Contact Industry Group";
    begin
        Initialize();
        Assert.AreEqual(
          LibraryUtility.GetFieldLength(DATABASE::"Industry Group", IndustryGroup.FieldNo(Description)),
          LibraryUtility.GetFieldLength(DATABASE::"Contact Industry Group",
            ContactIndustryGroup.FieldNo("Industry Group Description")),
          StrSubstNo(WrongDescriptionFieldLengthErr, ContactIndustryGroup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactWebSourceDescription()
    var
        WebSource: Record "Web Source";
        ContactWebSource: Record "Contact Web Source";
    begin
        Initialize();
        Assert.AreEqual(
          LibraryUtility.GetFieldLength(DATABASE::"Web Source", WebSource.FieldNo(Description)),
          LibraryUtility.GetFieldLength(DATABASE::"Contact Web Source",
            ContactWebSource.FieldNo("Web Source Description")),
          StrSubstNo(WrongDescriptionFieldLengthErr, ContactWebSource.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactJobResponsibilityDescription()
    var
        JobResponsibility: Record "Job Responsibility";
        ContactJobResponsibility: Record "Contact Job Responsibility";
    begin
        Initialize();
        Assert.AreEqual(
          LibraryUtility.GetFieldLength(DATABASE::"Job Responsibility", JobResponsibility.FieldNo(Description)),
          LibraryUtility.GetFieldLength(DATABASE::"Contact Job Responsibility",
            ContactJobResponsibility.FieldNo("Job Responsibility Description")),
          StrSubstNo(WrongDescriptionFieldLengthErr, ContactJobResponsibility.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentForContact()
    var
        Contact: Record Contact;
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        Comment: Text[80];
    begin
        // Covers document number TC0054 - refer to TFS ID 21740.
        // Test creation and linking of Comment for Contact.

        // 1. Setup: Create a new Contact.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Create Comment for Contact.
        LibraryMarketing.CreateRlshpMgtCommentContact(RlshpMgtCommentLine, Contact."No.");
        Comment :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(RlshpMgtCommentLine.FieldNo(Comment), DATABASE::"Rlshp. Mgt. Comment Line"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Rlshp. Mgt. Comment Line", RlshpMgtCommentLine.FieldNo(Comment)));
        RlshpMgtCommentLine.Validate(Comment, Comment);
        RlshpMgtCommentLine.Modify(true);

        // 3. Verify: Verify that the Comment has been linked correctly with Contact.
        RlshpMgtCommentLine.SetRange("Table Name", RlshpMgtCommentLine."Table Name"::Contact);
        RlshpMgtCommentLine.SetRange("No.", Contact."No.");
        RlshpMgtCommentLine.FindFirst();
        RlshpMgtCommentLine.TestField(Comment, Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactOfTypePerson()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
    begin
        // Covers document number TC0055 - refer to TFS ID 21740.
        // Test creation of an independent Contact of the Person type and linking it with the existing Contact of the Company type.

        // 1. Setup: Create a new Contact and input Type as Person.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(Type, Contact.Type::Person);

        // 2. Exercise: Search for another Contact of Type as Company and link it to the Contact created earlier.
        Contact2.SetRange(Type, Contact2.Type::Company);
        Contact2.FindFirst();
        Contact.Validate("Company No.", Contact2."No.");
        Contact.Modify(true);

        // Verify: Check that the values populated on the new Contact are the same as those on Contact of Type as Company.
        Contact.TestField(Address, Contact2.Address);
        Contact.TestField("Address 2", Contact2."Address 2");
        Contact.TestField(City, Contact2.City);
        Contact.TestField("Post Code", Contact2."Post Code");
        Contact.TestField("Salesperson Code", Contact2."Salesperson Code");
    end;

    [Test]
    [HandlerFunctions('NameDetailsModalFormHandler')]
    [Scope('OnPrem')]
    procedure ContactAfterUpdateNameDetails()
    var
        Contact: Record Contact;
        Salutation: Record Salutation;
        Language: Record Language;
    begin
        // Covers document number TC0055, TC0062 - refer to TFS ID 21740.
        // Test updating of Contact after updation of Name Details associated with the Contact.
        Initialize();

        // 1. Setup: Create a new Contact and input Type as Person. Find Salutation and Language.
        CreateContactAsPerson(Contact);
        Salutation.FindFirst();
        Language.FindFirst();

        // 2. Exercise: Open the Name Details form and fill in the details.
        LibraryVariableStorage.Enqueue(Salutation.Code);
        LibraryVariableStorage.Enqueue(Language.Code);
        RunNameDetails(Contact);

        // 3. Verify: Check that the Contact has been updated with the details filled earlier.
        Contact.Get(Contact."No.");  // Get refreshed instance.
        VerifyContactNameDetails(Contact, Salutation.Code, Language.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobResponsibilityForContact()
    var
        Contact: Record Contact;
        JobResponsibility: Record "Job Responsibility";
        ContactJobResponsibility: Record "Contact Job Responsibility";
    begin
        // Covers document number TC0055 - refer to TFS ID 21740.
        // Test creation and linking of Job Responsibility for Contact.
        Initialize();

        // 1. Setup: Create a new Contact and input Type as Person. Create a new Job Responsibility.
        CreateContactAsPerson(Contact);
        LibraryMarketing.CreateJobResponsibility(JobResponsibility);

        // 2. Exercise: Create Contact Job Responsibility for Contact and Job Responsibility created earlier.
        LibraryMarketing.CreateContactJobResponsibility(ContactJobResponsibility, Contact."No.", JobResponsibility.Code);

        // 3. Verify: Check that the field No. of Job Responsibilities on Contact is updated.
        Contact.CalcFields("No. of Job Responsibilities");
        // Value 1 is important to test case since one Job Responsibility has been linked.
        Contact.TestField("No. of Job Responsibilities", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkContactWithCustomerError()
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
    begin
        // Covers document number TC0058 - refer to TFS ID 21740.
        // Test error generated on linking Contact with an existing Customer if Bus. Rel. Code for Customers field in Marketing
        // Setup is blank.

        // 1. Setup: Input the field Bus. Rel. Code for Customers of Marketing Setup as blank. Create a new Contact.
        Initialize();
        ChangeBusinessRelationCodeForCustomers('');
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Try to link Contact with an existing Customer.
        asserterror Contact.CreateCustomerLink();

        // 3. Verify: Check that the application generates an error on linking Contact with an existing Customer if Bus. Rel.
        // Code for Customers field in Marketing Setup is blank.
        VerifyContactErrorMessage(MarketingSetup.FieldCaption("Bus. Rel. Code for Customers"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkContactWithVendorError()
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
    begin
        // Covers document number TC0058 - refer to TFS ID 21740.
        // Test error generated on linking Contact with an existing Vendor if Bus. Rel. Code for Vendors field in Marketing
        // Setup is blank.

        // 1. Setup: Input the field Bus. Rel. Code for Vendors of Marketing Setup as blank. Create a new Contact.
        Initialize();
        ChangeBusinessRelationCodeForVendors('');
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Try to link Contact with an existing Vendor.
        asserterror Contact.CreateVendorLink();

        // 3. Verify: Check that the application generates an error on linking Contact with an existing Vendor if Bus. Rel.
        // Code for Vendors field in Marketing Setup is blank.
        VerifyContactErrorMessage(MarketingSetup.FieldCaption("Bus. Rel. Code for Vendors"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LinkContactWithBankAccError()
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
        BusRelCodeForBankAccs: Code[10];
    begin
        // Covers document number TC0058 - refer to TFS ID 21740.
        // Test error generated on linking Contact with an existing Bank Account if Bus. Rel. Code for Bank Accs. field in Marketing
        // Setup is blank.

        // 1. Setup: Input the field Bus. Rel. Code for Bank Accs. of Marketing Setup as blank. Create a new Contact.
        Initialize();
        BusRelCodeForBankAccs := ChangeBusinessRelationCodeForBankAccount('');
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Try to link Contact with an existing Bank Account.
        asserterror Contact.CreateBankAccountLink();

        // 3. Verify: Check that the application generates an error on linking Contact with an existing Bank Account if Bus. Rel.
        // Code for Bank Accs. field in Marketing Setup is blank.
        VerifyContactErrorMessage(MarketingSetup.FieldCaption("Bus. Rel. Code for Bank Accs."));

        // 4. Cleanup: Input the original value of the field Bus. Rel. Code for Bank Accs. in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccs);
    end;

    [Test]
    //[HandlerFunctions('ConfirmHandlerTrue,CustomerTempModalFormHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromCustTemplateWithDefaultDimensions()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerTemplate: Record "Customer Templ.";
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
    begin
        // [FEATURE] [Customer] [Customer Template] [Default Dimensions]
        // [SCENARIO 475121] Using template when creating Custmer -> all default dimension setups should be copied also                  
        Initialize();

        // [GIVEN] Create a new Customer Price Group and link it with a new Customer Template.
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateCustomerTemplate(CustomerTemplate, CustomerPriceGroup.Code);

        // [GIVEN] Customer Template is created with default dimensions.
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Customer Templ.", CustomerTemplate.Code, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.TestField("Allowed Values Filter", '');
        DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
        DefaultDimension."Allowed Values Filter" := DimensionValue.Code;
        DefaultDimension.Modify();

        // [WHEN] Create a new Customer from the Customer Template.
        Customer.Init();
        Customer.Insert(true);
        CustomerTemplMgt.ApplyCustomerTemplate(Customer, CustomerTemplate);

        // [THEN] Check that the default dimensions are copied to the new Customer.
        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", DATABASE::Customer);
        DefaultDimension.SetRange("No.", Customer."No.");
        DefaultDimension.SetRange("Dimension Code", Dimension.Code);
        DefaultDimension.FindFirst();
        Assert.AreEqual(DefaultDimension."Allowed Values Filter", DefaultDimension."Dimension Value Code", 'Issue with the customer default dimension - field Allowed Values Filter');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,CustomerTempModalFormHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreationOfCustomerFromContact()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerTemplate: Record "Customer Templ.";
    begin
        // Covers document number TC0059 - refer to TFS ID 21740.
        // [FEATURE] [Customer]
        // [SCENARIO 378041] Test creation of a Customer from Customer using the Customer Template from Demodata.
        // "Invoice Disc. Code" should not be set to blank on the Customer page if create a new Customer from a Contact using a template where this field was not informed

        // [GIVEN] Create a new Business Relation and input it in the field Bus. Rel. Code for Customers of Marketing Setup. Create a
        // new Customer Price Group and link it with a new Customer Template. Create a new Contact.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);

        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateCustomerTemplate(CustomerTemplate, CustomerPriceGroup.Code);
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Blank "Invoice Disc. Code" in the Customer Template
        CustomerTemplate.Validate("Invoice Disc. Code", '');
        CustomerTemplate.Modify(true);

        // [WHEN] Create Customer from Contact (the Customer Template created earlier is being chosen through Modal Form Handler).
        Contact.CreateCustomerFromTemplate(Contact.ChooseNewCustomerTemplate());

        // [THEN] Check that the values in the Customer created match the values in the Customer Template and Customer Price Group.
        // [THEN] "Invoice Disc. Code" is not blank in Customer card
        // [THEN] "Territory Code", "Currency Code" and "Country/Region Code" in the Customer created match the values in the Customer Template and Customer Price Group - TFS 380269
        VerifyCustomerCreatedByContact(CustomerTemplate, Contact."No.", CustomerPriceGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,CustomerTempModalFormHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromContactError()
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerTemplate: Record "Customer Templ.";
    begin
        // Covers document number TC0059 - refer to TFS ID 21740.
        // Test error generated on creation of a Customer from Contact if Bus. Rel. Code for Customers field in Marketing Setup is blank.

        // 1. Setup: Input the field Bus. Rel. Code for Customers of Marketing Setup as blank. Create a new Contact.
        Initialize();
        ChangeBusinessRelationCodeForCustomers('');
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateCustomerTemplate(CustomerTemplate, CustomerPriceGroup.Code);
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Try to create Customer from Contact.
        asserterror Contact.CreateCustomerFromTemplate(Contact.ChooseNewCustomerTemplate());

        // 3. Verify: Check that the application generates an error on creation of a Customer from Contact if Bus. Rel. Code for Customers
        // field in Marketing Setup is blank.
        VerifyContactErrorMessage(MarketingSetup.FieldCaption("Bus. Rel. Code for Customers"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,CustomerTemplateListPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustFromCompanyContWithTemplateUI()
    var
        Contact: Record Contact;
        CustomerTemplate: array[2] of Record "Customer Templ.";
    begin
        // [SCENARIO 211037] Customer Template List contains only "company" templates when create customer from "Company" contact
        Initialize();
        DeleteCustomerTemplates();
        // [GIVEN] Customer template "CT1" with "Contact Type" = "Company"
        // [GIVEN] Customer template "CT2" with "Contact Type" = "Person"
        CreateCustomerTemplates(CustomerTemplate);
        LibraryVariableStorage.Enqueue(CustomerTemplate[1].Code);
        CreateCustomerTemplates(CustomerTemplate);
        // [GIVEN] Contact "C" of Company type
        LibraryMarketing.CreateCompanyContact(Contact);
        // [WHEN] Create customer from contact using template
        Contact.CreateCustomerFromTemplate(Contact.ChooseNewCustomerTemplate());
        // [THEN] Customer Template List page contains only "CT1"
        // Verification in CustomerTemplateListPageHandler
        DeleteCustomerTemplates();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,CustomerTemplateListPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustFromPersonContWithTemplateUI()
    var
        Contact: Record Contact;
        CustomerTemplate: array[2] of Record "Customer Templ.";
    begin
        // [SCENARIO 211037] Customer Template List contains only "person" templates when create customer from "Person" contact
        Initialize();
        DeleteCustomerTemplates();
        // [GIVEN] Customer template "CT1" with "Contact Type" = "Company"
        // [GIVEN] Customer template "CT2" with "Contact Type" = "Person"
        CreateCustomerTemplates(CustomerTemplate);
        LibraryVariableStorage.Enqueue(CustomerTemplate[2].Code);
        CreateCustomerTemplates(CustomerTemplate);
        // [GIVEN] Contact "C" of Person type
        LibraryMarketing.CreatePersonContact(Contact);
        // [WHEN] Create customer from contact using template
        Contact.CreateCustomerFromTemplate(Contact.ChooseNewCustomerTemplate());
        // [THEN] Customer Template List page contains only "CT2"
        // Verification in CustomerTemplateListPageHandler
        DeleteCustomerTemplates();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateCustFromCompanyContactWithVATRegNumber()
    var
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        // [SCENARIO 466353] Create customer from "Company" contact with 'Registration Number'
        Initialize();

        // [GIVEN] Contact of Company type with 'Registration Number' = '1234567890'
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact."Registration Number" := LibraryUtility.GenerateGUID();
        Contact.Modify();

        // [WHEN] Create customer from the contact 
        Contact.CreateCustomerFromTemplate('');

        // [THEN] "Registration Number" = '1234567890' from Contact is assigned to the new customer
        Customer.Get(GetCustFromContact(Contact."No."));
        Customer.TestField("Registration Number", Contact."Registration Number");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SyncCustomerOnModifyContactWithVATRegNumber()
    var
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        // [SCENARIO 473423] 'Registration Number' is syncronized for customer when contact is modified
        Initialize();

        // [GIVEN] Customer is created for contact of Company type
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateCustomerFromTemplate('');
        Customer.Get(GetCustFromContact(Contact."No."));
        Customer.TestField("Registration Number", '');

        // [WHEN] Set "Registration Number" = '1234567890' to Contact 
        Contact.Find();
        Contact.Validate("Registration Number", LibraryUtility.GenerateGUID());
        Contact.Modify(true);

        // [THEN] "Registration Number" = '1234567890' from contact is assigned to the customer
        Customer.Find();
        Customer.TestField("Registration Number", Contact."Registration Number");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorFromContactError()
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
    begin
        // Covers document number TC0059 - refer to TFS ID 21740.
        // Test error generated on creation of Vendor from Contact if Bus. Rel. Code for Vendors field in Marketing Setup is blank.

        // 1. Setup: Input the field Bus. Rel. Code for Vendors of Marketing Setup as blank. Create a new Contact.
        Initialize();
        ChangeBusinessRelationCodeForVendors('');
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Try to create Vendor from Contact.
        asserterror Contact.CreateVendorFromTemplate('');

        // 3. Verify: Check that the application generates an error on creation of a Vendor from Contact if Bus. Rel. Code for Vendors
        // field in Marketing Setup is blank.
        VerifyContactErrorMessage(MarketingSetup.FieldCaption("Bus. Rel. Code for Vendors"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorFromCompanyContactWithRegNumber()
    var
        Vendor: Record Vendor;
        CompanyContact: Record Contact;
    begin
        // [SCENARIO 466353] When Vendor is created for the Contact, fields "Primary Contact No."", "Contact" should not be updated
        Initialize();

        // [GIVEN] Contact of Company type with 'Registration Number' = '1234567890'
        LibraryMarketing.CreateCompanyContact(CompanyContact);
        CompanyContact."Registration Number" := LibraryUtility.GenerateGUID();
        CompanyContact.Modify();

        // [WHEN] Vendor is created from the Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateVendorFromTemplate('');

        // [THEN] "Registration Number" = '1234567890' in Vendor
        Vendor.SetRange(Name, CompanyContact.Name);
        Vendor.FindFirst();
        Vendor.TestField("Registration Number", CompanyContact."Registration Number");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SyncVendorOnModifyContactWithVATRegNumber()
    var
        Contact: Record Contact;
        Vendor: Record Vendor;
    begin
        // [SCENARIO 473423] 'Registration Number' is syncronized for vendor when contact is modified
        Initialize();

        // [GIVEN] Vendor is created for contact of Company type
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateVendorFromTemplate('');
        Vendor.SetRange(Name, Contact.Name);
        Vendor.FindFirst();
        Vendor.TestField("Registration Number", '');

        // [WHEN] Set "Registration Number" = '1234567890' to Contact 
        Contact.Find();
        Contact.Validate("Registration Number", LibraryUtility.GenerateGUID());
        Contact.Modify(true);

        // [THEN] "Registration Number" = '1234567890' from contact is assigned to the vendor
        Vendor.Find();
        Vendor.TestField("Registration Number", Contact."Registration Number");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateBankAccFromContactError()
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
        BusRelCodeForBankAccs: Code[10];
    begin
        // Covers document number TC0059 - refer to TFS ID 21740.
        // Test error generated on creation of a Bank Account from Contact if Bus. Rel. Code for Bank Accs. field in Marketing Setup
        // is blank.

        // 1. Setup: Input the field Bus. Rel. Code for Bank Accs. of Marketing Setup as blank. Create a new Contact.
        Initialize();
        BusRelCodeForBankAccs := ChangeBusinessRelationCodeForBankAccount('');
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Try to create Bank Account from Contact.
        asserterror Contact.CreateBankAccount();

        // 3. Verify: Check that the application generates an error on creation of a Bank Account from Contact if Bus. Rel. Code for
        // Bank Accs. field in Marketing Setup is blank.
        VerifyContactErrorMessage(MarketingSetup.FieldCaption("Bus. Rel. Code for Bank Accs."));

        // 4. Cleanup: Input the original value of the field Bus. Rel. Code for Bank Accs. in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccs);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateContactFromCustomerError()
    var
        Customer: Record Customer;
        MarketingSetup: Record "Marketing Setup";
    begin
        // Covers document number TC0058, TC0060 - refer to TFS ID 21740.
        // Test error generated on creation of a Contact from Customer if Bus. Rel. Code for Customers field in Marketing Setup is blank.

        // 1. Setup: Input the field Bus. Rel. Code for Customers of Marketing Setup as blank. Create a new Customer.
        Initialize();
        ChangeBusinessRelationCodeForCustomers('');
        LibrarySales.CreateCustomer(Customer);

        // 2. Exercise: Try to create Contact from Customer.
        asserterror Customer.ShowContact();

        // 3. Verify: Check that the application generates an error on creation of a Contact from Customer if Bus. Rel. Code for Customers
        // field in Marketing Setup is blank.
        VerifyContactErrorMessage(MarketingSetup.FieldCaption("Bus. Rel. Code for Customers"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateContactFromVendorError()
    var
        Vendor: Record Vendor;
        MarketingSetup: Record "Marketing Setup";
    begin
        // Covers document number TC0058, TC0060 - refer to TFS ID 21740.
        // Test error generated on creation of a Contact from Vendor if Bus. Rel. Code for Vendors field in Marketing Setup is blank.

        // 1. Setup: Input the field Bus. Rel. Code for Vendors of Marketing Setup as blank. Create a new Vendor.
        Initialize();
        ChangeBusinessRelationCodeForVendors('');
        LibraryPurchase.CreateVendor(Vendor);

        // 2. Exercise: Try to create Contact from Vendor.
        asserterror Vendor.ShowContact();

        // 3. Verify: Check that the application generates an error on creation of a Contact from Vendor if Bus. Rel. Code for Vendors
        // field in Marketing Setup is blank.
        VerifyContactErrorMessage(MarketingSetup.FieldCaption("Bus. Rel. Code for Vendors"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateContactFromBankAccError()
    var
        BankAccount: Record "Bank Account";
        MarketingSetup: Record "Marketing Setup";
        BusRelCodeForBankAccs: Code[10];
    begin
        // Covers document number TC0058, TC0060 - refer to TFS ID 21740.
        // Test error generated on creation of a Contact from Bank Account if Bus. Rel. Code for Bank Accs. field in Marketing Setup
        // is blank.

        // 1. Setup: Input the field Bus. Rel. Code for Bank Accs. of Marketing Setup as blank. Create a new Bank Account.
        Initialize();
        BusRelCodeForBankAccs := ChangeBusinessRelationCodeForBankAccount('');
        LibraryERM.CreateBankAccount(BankAccount);

        // 2. Exercise: Try to create Contact from Bank Account.
        asserterror BankAccount.ShowContact();

        // 3. Verify: Check that the application generates an error on creation of a Contact from Bank Account if Bus. Rel. Code
        // for Bank Accs. field in Marketing Setup is blank.
        VerifyContactErrorMessage(MarketingSetup.FieldCaption("Bus. Rel. Code for Bank Accs."));

        // 4. Cleanup: Input the original value of the field Bus. Rel. Code for Bank Accs. in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccs);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateContactFromCustomer()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // Covers document number TC0060 - refer to TFS ID 21740.
        // Test creation of a Contact from Customer.

        // 1. Setup: Create a new Business Relation and input it in the field Bus. Rel. Code for Customers of Marketing Setup. Create a
        // new Customer.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);
        LibrarySales.CreateCustomer(Customer);

        // 2. Exercise: Create Contact from Customer by running the report Create Conts. from Customers.
        Customer.SetRange("No.", Customer."No.");
        RunCreateContsFromCustomersReport(Customer);

        // 3. Verify: Check that the Contact has been created from the Customer.
        ContactBusinessRelation.SetRange("Business Relation Code", BusinessRelation.Code);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.FindFirst();
        Contact.Get(ContactBusinessRelation."Contact No.");
    end;

    [Test]
    [HandlerFunctions('DuplicateContactsNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateDuplicateContactFromCustomer()
    var
        Customer: Array[2] of Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
        DummyRecID: RecordId;
    begin
        // [SCENARIO] Report "Create Conts. from Customers" shows notification if there are duplicate contacts
        Initialize();
        // [GIVEN] Two new Customers that share the same Name, Address, Phone No.
        LibrarySales.CreateCustomer(Customer[1]);
        Customer[1].Name := LibraryUtility.GenerateGUID();
        Customer[1].Address := LibraryUtility.GenerateGUID();
        Customer[1]."Address 2" := LibraryUtility.GenerateGUID();
        Customer[1]."Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        Customer[1].Modify();
        LibrarySales.CreateCustomer(Customer[2]);
        Customer[2].TransferFields(Customer[1], false);
        Customer[2].Modify();
        // [GIVEN] Both customers have none linked contacts
        ContactBusinessRelation.SetRange("No.", Customer[1]."No.", Customer[2]."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.DeleteAll();

        // [GIVEN] "Autosearch for Duplicates" is on.
        MaximizeDuplicateAutosearch();

        // [WHEN] Running the report "Create Conts. from Customers".
        Customer[1].SetFilter("No.", '%1|%2', Customer[1]."No.", Customer[2]."No.");
        RunCreateContsFromCustomersReport(Customer[1]);

        // [THEN] Notification is shown: "There are duplicate contacts"
        Assert.ExpectedMessage(DuplicateContactsMsg, LibraryVariableStorage.DequeueText()); // Notification message from DuplicateContactsNotificationHandler
        LibraryNotificationMgt.RecallNotificationsForRecordID(DummyRecID);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure MaximizeDuplicateAutosearch()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup."Autosearch for Duplicates" := true;
        MarketingSetup."Search Hit %" := 10;
        MarketingSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateContactFromVendor()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // Covers document number TC0060 - refer to TFS ID 21740.
        // Test creation of a Contact from Vendor.

        // 1. Setup: Create a new Business Relation and input it in the field Bus. Rel. Code for Vendors of Marketing Setup. Create a
        // new Vendor.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        LibraryPurchase.CreateVendor(Vendor);

        // 2. Exercise: Create Contact from Vendor by running the report Create Conts. from Vendors.
        Vendor.SetRange("No.", Vendor."No.");
        RunCreateContsFromVendorsReport(Vendor);

        // 3. Verify: Check that the Contact has been created from the Vendor.
        ContactBusinessRelation.SetRange("Business Relation Code", BusinessRelation.Code);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", Vendor."No.");
        ContactBusinessRelation.FindFirst();
        Contact.Get(ContactBusinessRelation."Contact No.");
    end;

    [Test]
    [HandlerFunctions('DuplicateContactsNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateDuplicateContactFromVendor()
    var
        Vendor: Array[2] of Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
        DummyRecID: RecordId;
    begin
        // [SCENARIO] Report "Create Conts. from Vendors" shows notification if there are duplicate contacts
        Initialize();
        // [GIVEN] Two new Vendors that share the same Name, Address, Phone No.
        LibraryPurchase.CreateVendor(Vendor[1]);
        Vendor[1].Name := LibraryUtility.GenerateGUID();
        Vendor[1].Address := LibraryUtility.GenerateGUID();
        Vendor[1]."Address 2" := LibraryUtility.GenerateGUID();
        Vendor[1]."Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        Vendor[1].Modify();
        LibraryPurchase.CreateVendor(Vendor[2]);
        Vendor[2].TransferFields(Vendor[1], false);
        Vendor[2].Modify();
        // [GIVEN] Both Vendors have none linked contacts
        ContactBusinessRelation.SetRange("No.", Vendor[1]."No.", Vendor[2]."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.DeleteAll();

        // [GIVEN] "Autosearch for Duplicates" is on.
        MaximizeDuplicateAutosearch();

        // [WHEN] Running the report "Create Conts. from Vendors".
        Vendor[1].SetFilter("No.", '%1|%2', Vendor[1]."No.", Vendor[2]."No.");
        RunCreateContsFromVendorsReport(Vendor[1]);

        // [THEN] Notification is shown: "There are duplicate contacts"
        Assert.ExpectedMessage(DuplicateContactsMsg, LibraryVariableStorage.DequeueText()); // Notification message from DuplicateContactsNotificationHandler
        LibraryNotificationMgt.RecallNotificationsForRecordID(DummyRecID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateContactFromBankAcc()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        BusRelCodeForBankAccs: Code[10];
    begin
        // Covers document number TC0060 - refer to TFS ID 21740.
        // Test creation of a Contact from Bank Account.

        // 1. Setup: Create a new Business Relation and input it in the field Bus. Rel. Code for Bank Accs. of Marketing Setup. Create a
        // new Bank Account.
        Initialize();
        ExecuteUIHandler();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForBankAccs := ChangeBusinessRelationCodeForBankAccount(BusinessRelation.Code);
        LibraryERM.CreateBankAccount(BankAccount);

        // 2. Exercise: Create Contact from Bank Account by running the report Create Conts. from Bank Account.
        BankAccount.SetRange("No.", BankAccount."No.");
        RunCreateContsFromBankAccountsReport(BankAccount);

        // 3. Verify: Check that the Contact has been created from the Bank Account.
        ContactBusinessRelation.SetRange("Business Relation Code", BusinessRelation.Code);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::"Bank Account");
        ContactBusinessRelation.SetRange("No.", BankAccount."No.");
        ContactBusinessRelation.FindFirst();
        Contact.Get(ContactBusinessRelation."Contact No.");

        // 4. Cleanup: Input the original value of the field Bus. Rel. Code for Bank Accs. in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccs);
    end;

    local procedure RunCreateContsFromBankAccountsReport(var BankAccount: Record "Bank Account")
    var
        CreateContsFromBankAccs: Report "Create Conts. from Bank Accs.";
    begin
        CreateContsFromBankAccs.UseRequestPage(false);
        CreateContsFromBankAccs.SetTableView(BankAccount);
        CreateContsFromBankAccs.Run();
    end;

    [Test]
    [HandlerFunctions('DuplicateContactsNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateDuplicateContactFromBankAcc()
    var
        BankAccount: Array[2] of Record "Bank Account";
        ContactBusinessRelation: Record "Contact Business Relation";
        DummyRecID: RecordId;
    begin
        // [SCENARIO] Report "Create Conts. from Bank Accounts" shows notification if there are duplicate contacts
        Initialize();
        // [GIVEN] Two new BankAccounts that share the same Name, Address, Phone No.
        LibraryERM.CreateBankAccount(BankAccount[1]);
        BankAccount[1].Name := LibraryUtility.GenerateGUID();
        BankAccount[1].Address := LibraryUtility.GenerateGUID();
        BankAccount[1]."Address 2" := LibraryUtility.GenerateGUID();
        BankAccount[1]."Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        BankAccount[1].Modify();
        LibraryERM.CreateBankAccount(BankAccount[2]);
        BankAccount[2].TransferFields(BankAccount[1], false);
        BankAccount[2].Modify();
        // [GIVEN] Both BankAccounts have none linked contacts
        ContactBusinessRelation.SetRange("No.", BankAccount[1]."No.", BankAccount[2]."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::"Bank Account");
        ContactBusinessRelation.DeleteAll();

        // [GIVEN] "Autosearch for Duplicates" is on.
        MaximizeDuplicateAutosearch();

        // [WHEN] Running the report "Create Conts. from BankAccounts".
        BankAccount[1].SetFilter("No.", '%1|%2', BankAccount[1]."No.", BankAccount[2]."No.");
        RunCreateContsFromBankAccountsReport(BankAccount[1]);

        // [THEN] Notification is shown: "There are duplicate contacts"
        Assert.ExpectedMessage(DuplicateContactsMsg, LibraryVariableStorage.DequeueText()); // Notification message from DuplicateContactsNotificationHandler
        LibraryNotificationMgt.RecallNotificationsForRecordID(DummyRecID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreateInteractModalFormHandler')]
    [Scope('OnPrem')]
    procedure InteractionStatisticsOnContact()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        CostLCY: Decimal;
        DurationMin: Decimal;
    begin
        // Covers document number TC0061 - refer to TFS ID 21740.
        // Test the Interaction statistics information on the Contact card.

        // 1. Setup: Create a new Contact, Interaction Template.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        // Set global variables for form handler with any random decimal value.
        CostLCY := LibraryRandom.RandDec(100, 2);
        DurationMin := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(InteractionTemplate.Code);
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(DurationMin);

        // 2. Exercise: Create a new Interaction for Contact.
        Contact.CreateInteraction();

        // 3. Verify: Check that the Statistics for Interaction has been updated on Contact.
        Contact.CalcFields("Cost (LCY)", "Duration (Min.)", "No. of Interactions");
        Contact.TestField("No. of Interactions", 1);
        Contact.TestField("Cost (LCY)", CostLCY);
        Contact.TestField("Duration (Min.)", DurationMin);
    end;

    [Test]
    [HandlerFunctions('CreateInteractModalFormHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CancelInteractionOnContact()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
        CostLCY: Decimal;
        DurationMin: Decimal;
    begin
        // Covers document number TC0061 - refer to TFS ID 21740.
        // Test the Interaction statistics information on the Contact card.

        // 1. Setup: Create a new Contact, Interaction Template. Create a new Interaction for Contact.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        // Set global variables for form handler with any random decimal value.
        CostLCY := LibraryRandom.RandDec(100, 2);
        DurationMin := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(InteractionTemplate.Code);
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(DurationMin);
        Contact.CreateInteraction();

        // 2. Exercise: Cancel the Interaction.
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        InteractionLogEntry.SetRange("Interaction Template Code", InteractionTemplate.Code);
        InteractionLogEntry.ToggleCanceledCheckmark();

        // 3. Verify: Check that the Statistics for Interaction has been updated on Contact.
        Contact.CalcFields("Cost (LCY)", "Duration (Min.)", "No. of Interactions");
        Contact.TestField("No. of Interactions", 0);
        Contact.TestField("Cost (LCY)", 0);
        Contact.TestField("Duration (Min.)", 0);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler')]
    [Scope('OnPrem')]
    procedure OpportunityStatisticsOnContact()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycle: Record "Sales Cycle";
        TempOpportunity: Record Opportunity temporary;
        WizardEstimatedValueLCY: Decimal;
        WizardChancesofSuccessPercent: Decimal;
    begin
        // Covers document number TC0061 - refer to TFS ID 21740.
        // Test the Opportunity statistics information on the Contact card.

        // 1. Setup: Create a new Contact and Sales Cycle.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // 2. Exercise: Create a new Opportunity for Contact. Set global variables for Form Handler with any random decimal values.
        WizardEstimatedValueLCY := LibraryRandom.RandDec(100, 2);
        WizardChancesofSuccessPercent := LibraryRandom.RandDec(100, 2);
        Opportunity.SetRange("Contact No.", Contact."No.");
        LibraryVariableStorage.Enqueue(SalesCycle.Code);
        LibraryVariableStorage.Enqueue(WizardEstimatedValueLCY);
        LibraryVariableStorage.Enqueue(WizardChancesofSuccessPercent);
        TempOpportunity.CreateOppFromOpp(Opportunity);

        // 3. Verify: Check that the Statistics for Opportunity has been updated on Contact.
        Contact.CalcFields("Estimated Value (LCY)", "Calcd. Current Value (LCY)", "No. of Opportunities");
        Contact.TestField("No. of Opportunities", 1);  // Since one opportunity has been created and linked.
        Contact.TestField("Estimated Value (LCY)", WizardEstimatedValueLCY);
        TempOpportunity.TestField(
          "Calcd. Current Value (LCY)", TempOpportunity."Estimated Value (LCY)" * TempOpportunity."Probability %" / 100);
    end;

    [Test]
    [HandlerFunctions('CreateOpportModalFormHandler,CloseOpportModalFormHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CloseOpportunityOnContact()
    var
        Contact: Record Contact;
        Opportunity: Record Opportunity;
        SalesCycle: Record "Sales Cycle";
        CloseOpportunityCode: Record "Close Opportunity Code";
        TempOpportunity: Record Opportunity temporary;
        WizardEstimatedValueLCY: Decimal;
        WizardChancesofSuccessPercent: Decimal;
        CalcCurrentValueLCY: Decimal;
    begin
        // Covers document number TC0061 - refer to TFS ID 21740.
        // Test the Opportunity statistics information on the Contact card after Closing the Opportunity.

        // 1. Setup: Create a new Contact and Sales Cycle. Create a new Opportunity for Contact. Set global variables for Form Handler with
        // any random decimal values. Create a new Close Opportunity Code.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateSalesCycle(SalesCycle);

        // Set global variables for form handler with any random decimal values.
        WizardEstimatedValueLCY := LibraryRandom.RandDec(100, 2);
        WizardChancesofSuccessPercent := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(SalesCycle.Code);
        LibraryVariableStorage.Enqueue(WizardEstimatedValueLCY);
        LibraryVariableStorage.Enqueue(WizardChancesofSuccessPercent);

        Opportunity.SetRange("Contact No.", Contact."No.");
        TempOpportunity.CreateOppFromOpp(Opportunity);
        LibraryMarketing.CreateCloseOpportunityCode(CloseOpportunityCode);

        // Set global variable for form handler with any random decimal value.
        CalcCurrentValueLCY := LibraryRandom.RandDec(100, 2);
        LibraryVariableStorage.Enqueue(CloseOpportunityCode.Code);
        LibraryVariableStorage.Enqueue(CalcCurrentValueLCY);

        // 2. Exercise: Close the Opportunity.
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.FindFirst();
        Opportunity.CloseOpportunity();

        // 3. Verify: Check that the Statistics for Opportunity has been updated on Contact.
        Contact.CalcFields("Estimated Value (LCY)", "Calcd. Current Value (LCY)", "No. of Opportunities");
        Contact.TestField("No. of Opportunities", 1);  // Since one opportunity has been closed as Won.
        TempOpportunity.TestField("Calcd. Current Value (LCY)", TempOpportunity."Estimated Value (LCY)");
        // Verify: Check that the Opportunity Entry field "Calcd. Current Value" was updated with (Sales (LCY)) value.
        VerifyOpportunityEntry(Opportunity."No.", CalcCurrentValueLCY);
    end;

    [Test]
    [HandlerFunctions('VerifyNameModalFormHandler')]
    [Scope('OnPrem')]
    procedure NameDetailsAfterUpdateContact()
    var
        Contact: Record Contact;
        Salutation: Record Salutation;
        Language: Record Language;
    begin
        // Covers document number TC0062 - refer to TFS ID 21740.
        // Test updation of Name Details after updation of Contact associated with the Name Details.
        Initialize();

        // 1. Setup: Create a new Contact and input Type as Person. Find Salutation and Language.
        CreateContactAsPerson(Contact);
        Salutation.FindFirst();
        Language.FindFirst();

        // 2. Exercise: Fill in the details in the Contact.
        LibraryVariableStorage.Enqueue(Salutation.Code);
        LibraryVariableStorage.Enqueue(Language.Code);
        UpdateContactNameDetails(Contact, Salutation.Code, Language.Code);

        // 3. Verify: Open the Name Details form and check that the Name Details has been updated with the details filled earlier. This
        // will be done within the form Handler.
        RunNameDetails(Contact);
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsModalFormHandler')]
    [Scope('OnPrem')]
    procedure ContactUpdateCompanyDetails()
    var
        Contact: Record Contact;
        PostCode: Record "Post Code";
        PhoneNumber: Text[30];
    begin
        // Covers document number TC0062 - refer to TFS ID 21740.
        // Test updation of Contact after updation of Company Details associated with the Contact.

        // 1. Setup: Create a new Contact. Find a Post Code and Country/Region.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);

        PostCode.FindFirst();
        PhoneNumber := Format(LibraryRandom.RandIntInRange(1000000, 9999999));

        // 2. Exercise: Open the Company Details form and fill in the details.
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode."Country/Region Code");
        LibraryVariableStorage.Enqueue(PhoneNumber);
        RunCompanyDetails(Contact);

        // 3. Verify: Check that the Contact has been updated with the details filled earlier.
        Contact.Get(Contact."No.");  // Get refreshed instance.
        VerifyContactCompanyDetails(Contact, PostCode.Code, PostCode."Country/Region Code", PhoneNumber);
    end;

    [Test]
    [HandlerFunctions('VerifyCompanyModalFormHandler')]
    [Scope('OnPrem')]
    procedure CompanyDetailsAfterContact()
    var
        Contact: Record Contact;
        PostCode: Record "Post Code";
        PhoneNumber: Text[30];
    begin
        // Covers document number TC0062 - refer to TFS ID 21740.
        // Test updation of Company Details after updation of Contact associated with the Company Details.

        // 1. Setup: Create a new Contact. Find a Post Code and Country/Region.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        PostCode.FindFirst();
        PhoneNumber := Format(LibraryRandom.RandIntInRange(1000000, 9999999));

        // 2. Exercise: Fill in the details in the Contact.
        LibraryVariableStorage.Enqueue(PostCode.Code);
        LibraryVariableStorage.Enqueue(PostCode."Country/Region Code");
        LibraryVariableStorage.Enqueue(PhoneNumber);
        UpdateContactCompanyDetails(Contact, PostCode.Code, PostCode."Country/Region Code", PhoneNumber);

        // 3. Verify: Open the Company Details form and check that the Company Details have been updated with the details
        // filled earlier. This will be done within the form Handler.
        RunCompanyDetails(Contact);
    end;

    [Test]
    [HandlerFunctions('ModalFormMarketingSetup,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RelocateAttachments()
    var
        Attachment: Record Attachment;
        MarketingSetup2: Record "Marketing Setup";
        MarketingSetup: Page "Marketing Setup";
    begin
        // Covers document number TC0001 - refer to TFS ID 160766.
        // Test Relocation of Attachment.

        // 1. Setup:
        Initialize();
        MarketingSetup2.Get();

        // 2. Exercise: Change the Location for the Attachments.
        Clear(MarketingSetup);
        MarketingSetup.SetRecord(MarketingSetup2);
        MarketingSetup.RunModal();

        // 3. Verify: Check that location has been changed for attachments.
        Attachment.FindSet();
        repeat
            LibraryUtilityOnPrem.CheckFileNotEmpty(TemporaryPath + Format(Attachment."No."))
        until Attachment.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactFromCustomerCurrency()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // Covers document number TC0001 - refer to TFS ID 160766.
        // Test creation of a Contact from Customer With Currency.

        // 1. Setup: Create a new Business Relation and input it in the field Bus. Rel. Code for Customers of Marketing Setup. Create a
        // new Customer. Update Currency on Customer.
        Initialize();
        LibraryERM.CreateCurrency(Currency);
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);
        CreateCustomerWithCurrency(Customer, Currency.Code);

        // 2. Exercise: Create Contact from Customer by running the report Create Conts. from Customer report with Customer Currency Filter.
        Customer.SetRange("No.", Customer."No.");
        Customer.SetRange("Currency Code", Currency.Code);
        RunCreateContsFromCustomersReport(Customer);

        // 3. Verify: Check that the Contact has been created from the Customer.
        FindContactBusinessRelation(
          ContactBusinessRelation, BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
        Contact.Get(ContactBusinessRelation."Contact No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactFromVendorCurrency()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        Currency: Record Currency;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // Covers document number TC0001 - refer to TFS ID 160766.
        // Test creation of a Contact from Vendor With Currency.

        // 1. Setup: Create a new Business Relation and input it in the field Bus. Rel. Code for Vendor of Marketing Setup. Create a
        // new Vendor. Update Currency on Vendor.
        Initialize();
        LibraryERM.CreateCurrency(Currency);
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        CreateVendorWithCurrency(Vendor, Currency.Code);

        // 2. Exercise: Create Contact from Vendor by running the report Create Conts. from Vendors report with Vendor Currency Filter.
        Vendor.SetRange("No.", Vendor."No.");
        Vendor.SetRange("Currency Code", Currency.Code);
        RunCreateContsFromVendorsReport(Vendor);

        // 3. Verify: Check that the Contact has been created from the Vendor.
        FindContactBusinessRelation(
          ContactBusinessRelation, BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");
        Contact.Get(ContactBusinessRelation."Contact No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ContactFromBankAccountCurrency()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        Currency: Record Currency;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        CreateContsFromBankAccs: Report "Create Conts. from Bank Accs.";
        BusRelCodeForBankAccs: Code[10];
    begin
        // Covers document number TC0001 - refer to TFS ID 160766.
        // Test creation of a Contact from Bank Account With Currency.

        // 1. Setup: Create a new Business Relation and input it in the field Bus. Rel. Code for Bank Accs. of Marketing Setup. Create a
        // new Bank Account. Update Currency on Bank Account.
        Initialize();
        ExecuteUIHandler();
        LibraryERM.CreateCurrency(Currency);
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForBankAccs := ChangeBusinessRelationCodeForBankAccount(BusinessRelation.Code);
        LibraryERM.CreateBankAccount(BankAccount);
        CreateBankAccountWithCurrency(BankAccount, Currency.Code);

        // 2. Exercise: Create Contact from Bank Account by running the report Create Conts. from Bank report
        // with Bank Account Currency Filter.
        BankAccount.SetRange("No.", BankAccount."No.");
        BankAccount.SetRange("Currency Code", Currency.Code);
        CreateContsFromBankAccs.UseRequestPage(false);
        CreateContsFromBankAccs.SetTableView(BankAccount);
        CreateContsFromBankAccs.Run();

        // 3. Verify: Check that the Contact has been created from the Bank Account.
        FindContactBusinessRelation(
          ContactBusinessRelation, BusinessRelation.Code, ContactBusinessRelation."Link to Table"::"Bank Account", BankAccount."No.");
        Contact.Get(ContactBusinessRelation."Contact No.");

        // 4. Cleanup: Input the original value of the field Bus. Rel. Code for Bank Accs. in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccs);
    end;

    [Test]
    [HandlerFunctions('CustomerLinkPageHandler')]
    [Scope('OnPrem')]
    procedure LinkContactWithCustomerAsContact()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        BusinessRelation: Record "Business Relation";
        Name: Text[100];
        CurrMasterFields: Option Contact,Customer;
    begin
        // Check that Contact Name has not been changed after linking Customer to a Contact as Contact.

        // 1. Setup: Blank the Business Relation code for Customer to create Customer without Contact, Again update it with some value, Create a new Contact.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers('');
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CurrMasterFields::Contact);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Name := Contact.Name;  // Store contact name into a variable to use it for verification.

        // 2. Exercise: Link Contact with an existing Customer.
        Contact.CreateCustomerLink();

        // 3. Verify: Verify that Contact still has same name as it has prior to linking with Customer.
        Contact.Get(Contact."No.");
        Contact.TestField(Name, Name);
    end;

    [Test]
    [HandlerFunctions('CustomerLinkPageHandler')]
    [Scope('OnPrem')]
    procedure LinkContactWithCustomer()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        CurrMasterFields: Option Contact,Customer;
    begin
        // Check that Contact Name has changed to Customer Name after linking Customer to a Company Contact as Customer.

        // 1. Setup: Blank the Business Relation code for Customer to create Customer without Contact, Again update it with some value, Create a new Contact.
        Initialize();
        CreateCustomerWithSetupBusinessRelation(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CurrMasterFields::Customer);
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Link Contact with an existing Customer.
        Contact.CreateCustomerLink();

        // 3. Verify: Verify that Contact Name updated with Customer Name after Linking with Customer.
        Contact.Get(Contact."No.");
        Contact.TestField(Name, Customer.Name);
    end;

    [Test]
    [HandlerFunctions('CustomerLinkPageHandler')]
    [Scope('OnPrem')]
    procedure LinkPersonContactWithCustomer()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        CurrMasterFields: Option Contact,Customer;
    begin
        // Check that Contact Name has changed to Customer Name after linking Customer to a Person Contact as Customer.

        // 1. Setup: Blank the Business Relation code for Customer to create Customer without Contact, Again update it with some value, Create a new Contact.
        Initialize();
        CreateCustomerWithSetupBusinessRelation(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CurrMasterFields::Customer);
        LibraryMarketing.CreatePersonContact(Contact);

        // 2. Exercise: Link Contact with an existing Customer.
        Contact.CreateCustomerLink();

        // 3. Verify: Verify that Contact Name updated with Customer Name after Linking with Customer.
        Contact.Get(Contact."No.");
        Contact.TestField(Name, Customer.Name);
    end;

    [Test]
    [HandlerFunctions('VendorLinkPageHandler')]
    [Scope('OnPrem')]
    procedure LinkContactWithVendor()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        Vendor: Record Vendor;
    begin
        // Check that Contact Name has changed to Vendor Name after linking Vendor to a Contact as Vendor.

        // 1. Setup: Blank the Business Relation code for Vendor to create Vendor without Contact, Again update it with some value, Create a new Contact.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors('');
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");

        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Link Contact with an existing Vendor.
        Contact.CreateVendorLink();

        // 3. Verify: Verify that Contact Name updated with Vendor Name after Linking with Vendor.
        Contact.Get(Contact."No.");
        Contact.TestField(Name, Vendor.Name);
    end;

    [Test]
    [HandlerFunctions('BankAccountLinkPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure LinkContactWithBankAccount()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        BusRelCodeForBankAccount: Code[10];
    begin
        // Check that Contact Name has changed to Bank Account Name after linking Bank Account to a Contact as Bank.

        // 1. Setup: Blank the Business Relation code for Bank Account to create Bank Account without Contact, Again update it with some value, Create a new Contact.
        Initialize();
        ExecuteUIHandler();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForBankAccount := ChangeBusinessRelationCodeForBankAccount('');
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        ChangeBusinessRelationCodeForBankAccount(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Link Contact with Bank Account.
        Contact.CreateBankAccountLink();

        // 3. Verify: Verify that Contact Name updated with Bank Account Name after Linking with Bank Account.
        Contact.Get(Contact."No.");
        Contact.TestField(Name, BankAccount.Name);

        // 4. Tear Down: Input the original value of the field Bus. Rel. Code for Bank Account in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccount);
    end;

    [Test]
    [HandlerFunctions('CustomerLinkPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerLinkedContact()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        ContactList: TestPage "Contact List";
        CurrMasterFields: Option Contact,Customer;
    begin
        // Check that Correct Contact No and Name appears on Contact List Page after Linking Contact to Customer.

        // 1. Setup: Blank the Business Relation code for Customer to create Customer without Contact, Again update it with some value, Create a new Contact.
        // Link Contact with an existing Customer.
        Initialize();
        CreateCustomerWithSetupBusinessRelation(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CurrMasterFields::Customer);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateCustomerLink();

        // 2. Exercise: Open Contact List Page for Customer.
        ContactList.Trap();
        Customer.ShowContact();

        // 3. Verify: Verify Contact No. and Name in Contact List Page.
        ContactList."No.".AssertEquals(Contact."No.");
        ContactList.Name.AssertEquals(Customer.Name);
    end;

    [Test]
    [HandlerFunctions('VendorLinkPageHandler')]
    [Scope('OnPrem')]
    procedure VendorLinkedContact()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        Vendor: Record Vendor;
        ContactList: TestPage "Contact List";
    begin
        // Check that Correct Contact No and Name appears on Contact List Page after Linking Contact to Vendor.

        // 1. Setup: Blank the Business Relation code for Vendor to create Vendor without Contact, Again update it with some value, Create a new Contact.
        // Link Contact with an existing Vendor.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors('');
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateVendorLink();

        // 2. Exercise: Open Contact List Page for Vendor.
        ContactList.Trap();
        Vendor.ShowContact();

        // 3. Verify: Verify correct Contact No. and Name appearing in Contact List Page.
        ContactList."No.".AssertEquals(Contact."No.");
        ContactList.Name.AssertEquals(Vendor.Name);
    end;

    [Test]
    [HandlerFunctions('BankAccountLinkPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BankAccountLinkedContact()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactList: TestPage "Contact List";
        BusRelCodeForBankAccount: Code[10];
    begin
        // Check that Correct Contact No and Name appears on Contact List Page after Linking Contact to Bank Account.

        // 1. Setup: Blank the Business Relation code for Bank Account to create Bank Account without Contact, Again update it with some value, Create a new Contact.
        // Link Contact with an existing Bank Account.
        Initialize();
        ExecuteUIHandler();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForBankAccount := ChangeBusinessRelationCodeForBankAccount('');
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        ChangeBusinessRelationCodeForBankAccount(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateBankAccountLink();

        // 2. Exercise: Open Contact List Page for Bank Account.
        ContactList.Trap();
        BankAccount.ShowContact();

        // 3. Verify: Verify correct Contact No. and Name appearing in Contact List Page.
        ContactList."No.".AssertEquals(Contact."No.");
        ContactList.Name.AssertEquals(BankAccount.Name);

        // 4. Tear Down: Input the original value of the field Bus. Rel. Code for Bank Account in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccount);
    end;

    [Test]
    [HandlerFunctions('CustomerLinkPageHandler')]
    [Scope('OnPrem')]
    procedure ContactWithUpdatedCustomer()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        NewName: Text[100];
        CurrMasterFields: Option Contact,Customer;
        RegistrationNumber: Text[50];
    begin
        // Check that Contact Name gets updated after updating Customer Name for a Customer linked with Contact.

        // 1. Setup: Blank the Business Relation code for Customer to create Customer without Contact, Again update it with some value, Create a new Contact.
        // Link Contact with an existing Customer.
        Initialize();
        NewName := LibraryUtility.GenerateGUID();
        RegistrationNumber := LibraryUtility.GenerateGUID();
        CreateCustomerWithSetupBusinessRelation(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CurrMasterFields::Customer);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateCustomerLink();

        // 2. Exercise: Update Customer Name with some new name.
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard.Name.SetValue(NewName);
        CustomerCard."Registration Number".SETVALUE(RegistrationNumber);
        CustomerCard.OK().Invoke();

        // 3. Verify: Verify that Contact Name gets updated with the new Customer Name.
        Contact.Get(Contact."No.");
        Contact.TestField(Name, NewName);
        Contact.TESTFIELD("Registration Number", RegistrationNumber); // TFS 473423 "Registration Number" is synced from the customer
    end;

    [Test]
    [HandlerFunctions('VendorLinkPageHandler')]
    [Scope('OnPrem')]
    procedure ContactWithUpdatedVendor()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        NewName: Text[100];
        RegistrationNumber: Text[50];
    begin
        // Check that Contact Name gets updated after updating Vendor Name for a Vendor linked with Contact.

        // 1. Setup: Blank the Business Relation code for Vendor to create Vendor without Contact, Again update it with some value, Create a new Contact.
        // Link Contact with an existing Vendor.
        Initialize();
        NewName := LibraryUtility.GenerateGUID();
        RegistrationNumber := LibraryUtility.GenerateGUID();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors('');
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateVendorLink();

        // 2. Exercise: Update Vendor Name.
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", Vendor."No.");
        VendorCard.Name.SetValue(NewName);
        VendorCard."Registration Number".SETVALUE(RegistrationNumber);
        VendorCard.OK().Invoke();

        // 3. Verify: Verify that updated Vendor Name reflected in Contact Name.
        Contact.Get(Contact."No.");
        Contact.TestField(Name, NewName);
        Contact.TESTFIELD("Registration Number", RegistrationNumber); // TFS 473423 "Registration Number" is synced from the vendor
    end;

    [Test]
    [HandlerFunctions('BankAccountLinkPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ContactWithUpdatedBankAccount()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        BankAccountCard: TestPage "Bank Account Card";
        BusRelCodeForBankAccount: Code[10];
        NewName: Text[100];
    begin
        // Check that Contact Name gets updated after updating Bank Account Name for a Bank Account linked with Contact.

        // 1. Setup: Blank the Business Relation code for Bank Account to create Bank Account without Contact, Again update it with some value, Create a new Contact.
        // Link Contact with an existing Bank Account.
        Initialize();
        ExecuteUIHandler();
        NewName := LibraryUtility.GenerateGUID();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForBankAccount := ChangeBusinessRelationCodeForBankAccount('');
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        ChangeBusinessRelationCodeForBankAccount(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateBankAccountLink();

        // 2. Exercise: Update Bank Account Name on Bank Account Card.
        BankAccountCard.OpenEdit();
        BankAccountCard.FILTER.SetFilter("No.", BankAccount."No.");
        BankAccountCard.Name.SetValue(NewName);
        BankAccountCard.OK().Invoke();

        // 3. Verify: Verify that updated Bank Account Name reflects on Contact.
        Contact.Get(Contact."No.");
        Contact.TestField(Name, NewName);

        // 4. Tear Down: Input the original value of the field Bus. Rel. Code for Bank Account in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccount);
    end;

    [Test]
    [HandlerFunctions('CustomerLinkPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateContactLinkedToCustomer()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        NewName: Text[100];
        CurrMasterFields: Option Contact,Customer;
    begin
        // Check that Customer Name updated after Linking Contact to Customer and updating Contact Name on Contact Card.

        // 1. Setup: Blank the Business Relation code for Customer to create Customer without Contact, Again update it with some value, Create a new Contact.
        Initialize();
        CreateCustomerWithSetupBusinessRelation(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CurrMasterFields::Customer);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateCustomerLink();
        NewName := LibraryUtility.GenerateGUID();

        // 2. Exercise.
        UpdateNameOnContactCard(Contact."No.", NewName);

        // 3. Verify: Verify that updated Contact Name reflected on Customer.
        Customer.Get(Customer."No.");
        Customer.TestField(Name, NewName);
    end;

    [Test]
    [HandlerFunctions('VendorLinkPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateContactLinkedToVendor()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        Vendor: Record Vendor;
        NewName: Text[100];
    begin
        // Check that Vendor Name updated after Linking Contact to Vendor and updating Contact Name on Contact Card.

        // 1. Setup: Blank the Business Relation code for Vendor to create Vendor without Contact, Again update it with some value, Create a new Contact.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors('');
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");

        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateVendorLink();
        NewName := LibraryUtility.GenerateGUID();

        // 2. Exercise.
        UpdateNameOnContactCard(Contact."No.", NewName);

        // 3. Verify: Verify that updated Contact Name reflected on Vendor.
        Vendor.Get(Vendor."No.");
        Vendor.TestField(Name, NewName);
    end;

    [Test]
    [HandlerFunctions('BankAccountLinkPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UpdateContactLinkedToBankAccount()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        NewName: Text[100];
        BusRelCodeForBankAccount: Code[10];
    begin
        // Check that Bank Account Name updated after Linking Contact to Bank Account and updating Contact Name on Contact Card.

        // 1. Setup: Blank the Business Relation code for Bank Account to create Bank Account without Contact, Again update it with some value, Create a new Contact.
        Initialize();
        ExecuteUIHandler();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForBankAccount := ChangeBusinessRelationCodeForBankAccount('');
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        ChangeBusinessRelationCodeForBankAccount(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateBankAccountLink();
        NewName := LibraryUtility.GenerateGUID();

        // 2. Exercise.
        UpdateNameOnContactCard(Contact."No.", NewName);

        // 3. Verify: Verify that updated Contact Name reflected on Bank Account.
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField(Name, NewName);

        // 4. Cleanup: Input the original value of the field Bus. Rel. Code for Bank Account in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactDeletion()
    var
        Contact: Record Contact;
    begin
        // Check Deletion of Contact Created.

        // 1. Setup.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Delete the contact created earlier.
        Contact.Delete(true);

        // 3. Verify: Verify that Contact not exist after deletion.
        Contact.SetRange("No.", Contact."No.");
        Assert.IsFalse(Contact.FindFirst(), StrSubstNo(ErrorMessage, Contact.TableCaption(), Contact."No."));
    end;

    [Test]
    [HandlerFunctions('CustomerLinkPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteContactLinkedToCustomer()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        CurrMasterFields: Option Contact,Customer;
    begin
        // Check that Customer still exists after deleting Contact linked with Customer.

        // 1. Setup: Blank the Business Relation code for Customer to create Customer without Contact, Again update it with some value, Create a new Contact.
        // Create Contact Link for Customer.
        Initialize();
        CreateCustomerWithSetupBusinessRelation(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CurrMasterFields::Customer);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateCustomerLink();

        // 2. Exercise.
        Contact.Delete(true);

        // 3. Verify: Verify that Customer linked to Contact still exists.
        Customer.SetRange("No.", Customer."No.");
        Assert.IsTrue(Customer.FindFirst(), StrSubstNo(ValidationError, Customer.TableCaption(), Customer."No."));
    end;

    [Test]
    [HandlerFunctions('VendorLinkPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteContactLinkedToVendor()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        Vendor: Record Vendor;
    begin
        // Check that Vendor still exists after deleting Contact linked with Vendor.

        // 1. Setup: Blank the Business Relation code for Vendor to create Vendor without Contact, Again update it with some value, Create a new Contact.
        // Create Contact Link for Vendor.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors('');
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateVendorLink();

        // 2. Exercise.
        Contact.Delete(true);

        // 3. Verify: Verify that Vendor linked to Contact still exists.
        Assert.IsTrue(Vendor.Get(Vendor."No."), StrSubstNo(ValidationError, Vendor.TableCaption(), Vendor."No."));
    end;

    [Test]
    [HandlerFunctions('BankAccountLinkPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeleteContactLinkedToBankAccount()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        BusRelCodeForBankAccount: Code[10];
    begin
        // Check that Bank Account still exists after deleting Contact linked with Bank Account.

        // 1. Setup: Blank the Business Relation code for Bank Account to create Bank Account without Contact, Again update it with some value, Create a new Contact.
        // Create Contact Link for Bank Account.
        Initialize();
        ExecuteUIHandler();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForBankAccount := ChangeBusinessRelationCodeForBankAccount('');
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryVariableStorage.Enqueue(BankAccount."No.");

        ChangeBusinessRelationCodeForBankAccount(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateBankAccountLink();

        // 2. Exercise.
        Contact.Delete(true);

        // 3. Verify: Verify that Bank Account linked to Contact still exists.
        Assert.IsTrue(BankAccount.Get(BankAccount."No."), StrSubstNo(ValidationError, BankAccount.TableCaption(), BankAccount."No."));

        // 4. Tear Down: Input the original value of the field Bus. Rel. Code for Bank Account in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccount);
    end;

    [Test]
    [HandlerFunctions('CustomerLinkPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeleteCustomerLinkedToContact()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactList: TestPage "Contact List";
        ContactNo: Code[20];
        CurrMasterFields: Option Contact,Customer;
    begin
        // Check that new Contact exists after deleting Contact and then its linked Customer.

        // 1. Setup: Blank the Business Relation code for Customer to create Customer without Contact, Again update it with some value, Create a new Contact.
        // Create Customer link for Contact. Delete the Contact and then open Contact List Page for Customer.
        Initialize();
        CreateCustomerWithSetupBusinessRelation(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(CurrMasterFields::Customer);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateCustomerLink();  // Create Customer Link for Contact.

        // 2. Exercise.
        Contact.Delete(true);

        // 3. Verify
        Assert.IsFalse(ContactBusinessRelation.Get(Contact."No.", BusinessRelation.Code), '');

        // 2. Exercise
        ContactList.Trap();
        Customer.ShowContact();  // Show contact for Customer.
        ContactNo := ContactList."No.".Value();
        Customer.Get(Customer."No.");
        Customer.Delete(true);

        // 3. Verify: Verify that Contact still exists after deleting linked Customer.
        Assert.IsTrue(Contact.Get(ContactNo), StrSubstNo(ValidationError, Contact.TableCaption(), ContactNo));
    end;

    [Test]
    [HandlerFunctions('VendorLinkPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeleteVendorLinkedToContact()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        Vendor: Record Vendor;
        ContactList: TestPage "Contact List";
        ContactNo: Code[20];
    begin
        // Check that new Contact exists after deleting Contact and then its linked Vendor.

        // 1. Setup: Blank the Business Relation code for Vendor to create Vendor without Contact, Again update it with some value, Create a new Contact.
        // Create Vendor link for Contact. Delete the Contact and then open Contact List Page for Vendor.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors('');
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateVendorLink();

        // 2. Exercise
        Contact.Delete(true);

        // 3. Verify
        Assert.IsFalse(ContactBusinessRelation.Get(Contact."No.", BusinessRelation.Code), '');

        // 2. Exercise.
        ContactList.Trap();
        Vendor.ShowContact();  // Show contact for Customer.
        ContactNo := ContactList."No.".Value();
        Vendor.Get(Vendor."No.");
        Vendor.Delete(true);

        // 3. Verify: Verify that Contact still exists after deleting linked Vendor.
        Assert.IsTrue(Contact.Get(ContactNo), StrSubstNo(ValidationError, Contact.TableCaption(), ContactNo));
    end;

    [Test]
    [HandlerFunctions('BankAccountLinkPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DeleteBankAccountLinkedToContact()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactList: TestPage "Contact List";
        ContactNo: Code[20];
        BusRelCodeForBankAccount: Code[10];
    begin
        // Check that new Contact exists after deleting Contact and then its linked Bank Account.

        // 1. Setup: Blank the Business Relation code for Bank Account to create Bank Account without Contact, Again update it with some value, Create a new Contact.
        // Create Bank Account link for Contact. Delete the Contact and then open Contact List Page for Bank Account.
        Initialize();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForBankAccount := ChangeBusinessRelationCodeForBankAccount('');
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        ChangeBusinessRelationCodeForBankAccount(BusinessRelation.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.CreateBankAccountLink();
        Contact.Delete(true);

        ContactList.Trap();
        BankAccount.ShowContact();  // Show contact for Customer.
        ContactNo := ContactList."No.".Value();

        // 2. Exercise.
        BankAccount.Find();
        BankAccount.Delete(true);

        // 3. Verify: Verify that Contact still exists after deleting linked Bank Account.
        Assert.IsTrue(Contact.Get(ContactNo), StrSubstNo(ValidationError, Contact.TableCaption(), ContactNo));

        // 4. Tear Down: Input the original value of the field Bus. Rel. Code for Bank Account in Marketing Setup.
        ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactLinkErrorForCustomer()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
        CurrMasterFields: Option Contact,Customer;
    begin
        // Check Error Message while trying to create a new Customer Link for Contact that is already having Customer Link.
        Initialize();

        // 1. Setup: Find a Contact that is having Customer as Business Relation.
        MarketingSetup.Get();
        FindContactBusinessRelation(
          ContactBusinessRelation, MarketingSetup."Bus. Rel. Code for Customers", ContactBusinessRelation."Link to Table"::Customer,
          '<>''''');
        Contact.Get(ContactBusinessRelation."Contact No.");
        LibraryVariableStorage.Enqueue(ContactBusinessRelation."No.");
        LibraryVariableStorage.Enqueue(CurrMasterFields::Customer);

        // 2. Exercise: Try to create Customer Link for Contact, Verify Error Message.
        asserterror Contact.CreateCustomerLink();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactLinkErrorForVendor()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        // Check Error Message while trying to create a new Vendor Link for Contact that is already having Vendor Link.
        Initialize();

        // 1. Setup: Find a Contact that is having Vendor as Business Relation.
        MarketingSetup.Get();
        FindContactBusinessRelation(
          ContactBusinessRelation, MarketingSetup."Bus. Rel. Code for Vendors", ContactBusinessRelation."Link to Table"::Vendor, '<>''''');
        Contact.Get(ContactBusinessRelation."Contact No.");
        LibraryVariableStorage.Enqueue(ContactBusinessRelation."No.");

        // 2. Exercise and Verify: Try to create Vendor Link for Contact, Verify Error Message.
        asserterror Contact.CreateVendorLink();
    end;

    [Test]
    [HandlerFunctions('BankAccountLinkPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContactLinkErrorForBank()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        // Check Error Message while trying to create a new Bank Account Link for Contact that is already having Bank Account Link.
        Initialize();

        // 1. Setup: Find a Contact that is having Bank Account as Business Relation.
        MarketingSetup.Get();
        FindContactBusinessRelation(
          ContactBusinessRelation, MarketingSetup."Bus. Rel. Code for Bank Accs.",
          ContactBusinessRelation."Link to Table"::"Bank Account", '<>''''');
        Contact.Get(ContactBusinessRelation."Contact No.");
        LibraryVariableStorage.Enqueue(ContactBusinessRelation."No.");

        // 2. Exercise: Try to create Bank Account Link for Contact.
        Contact.CreateBankAccountLink();

        // 3. Verify: Verify Error Message.
        Assert.ExpectedError(
          StrSubstNo(
            BusinessRelationError, Contact.TableCaption(), Contact."No.", ContactBusinessRelation."Link to Table",
            ContactBusinessRelation."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyAttachmentOnContactInteraction()
    var
        SegmentLine: Record "Segment Line";
        Attachment: Record Attachment;
        TempNewAttachment: Record Attachment temporary;
        TempInterLogEntryCommentLine: Record "Inter. Log Entry Comment Line" temporary;
        SegMgt: Codeunit SegManagement;
    begin
        // create new interaction with attachment
        Initialize();

        CreateWriteAttachment(Attachment);
        CreateSegmentLine(SegmentLine, Attachment."No.");
        CreateInteractLogEntry(SegmentLine."Line No.");

        // create new attachment
        CreateWriteAttachment(TempNewAttachment);

        // update current interaction with new attachment
        SegMgt.LogInteraction(SegmentLine, TempNewAttachment, TempInterLogEntryCommentLine, false, true);

        // verify that attachment is exist
        Attachment.Find();
        Assert.IsTrue(Attachment."Attachment File".HasValue, EmptyAttachmentErr);

        SegmentLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactBracketsOpenContactCard()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO] Check Contact with brackets in 'No.' can be opened without errors
        Initialize();
        // [GIVEN] Contact with Brackets symbols in 'No.' field
        CreateSimpleContact(Contact, CreateContactNameWithBrackets());
        // [WHEN] Contact Card for Contact with brackets in 'No.' is opened
        OpenContactCard(ContactCard, Contact);
        // [THEN] Contact Card successfully opened with no Errors
        ContactCard.OK().Invoke();

        // Tear Down
        Contact.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactBracketsOpenTaskList()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        TaskList: TestPage "Task List";
    begin
        // [SCENARIO] Check Task List page can be opened without errors for Contact with brackets in 'No.'
        Initialize();
        // [GIVEN] Contact with Brackets symbols in 'No.' field
        CreateSimpleContact(Contact, CreateContactNameWithBrackets());
        // [WHEN] To-do List page opened from Contact with Brackets symbols in 'No.' field
        OpenContactCard(ContactCard, Contact);
        TaskList.Trap();
        ContactCard."T&asks".Invoke();
        // [THEN] Page Task List successfully opened
        TaskList.Close();

        // Tear Down
        Contact.Delete();
    end;

    [Test]
    procedure InsertContactWithCompanyFilter()
    var
        ContactCard: TestPage "Contact Card";
        CompanyFilter: Code[20];
    begin
        // [SCENARIO 375315] New Contact for the Company should be of Type Person linked to the Company
        Initialize();

        // [GIVEN] Filter "X" on field "Company No." of Contact Page
        CompanyFilter := LibraryUtility.GenerateGUID();
        CreateCompanyContact(CompanyFilter);

        ContactCard.OpenView();
        ContactCard.Filter.SetFilter("Company No.", CompanyFilter);

        // [WHEN] Insert Contact
        ContactCard.New();

        // [THEN] Contact is created where "Company No." is "X", Type = "Person"
        ContactCard."Company No.".AssertEquals(CompanyFilter);
        ContactCard.Type.AssertEquals("Contact Type"::Person);
    end;

    [Test]
    procedure InsertContactWithoutCompanyFilter()
    var
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 375315] New Contact should be of Type Company not linked to a Company
        Initialize();

        // [GIVEN] No filters applied on field "Company No." of Contact Page
        ContactCard.OpenView();

        // [WHEN] Insert Contact
        ContactCard.New();

        // [THEN] Contact is created where "Company No." is blank, Type = "Company"
        ContactCard."Company Name".AssertEquals('');
        ContactCard.Type.AssertEquals("Contact Type"::Company);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactBusinessRelationIsCreatedWithoutValidationCheckWhenNonUIRun()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [Contact Business Relation]
        // [SCENARIO 375531] Contact Business Relation record is created without "Business Relation Code" field validation check in case of non-UI running
        Initialize();

        // [GIVEN] Create new Business Relation Code "X".
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);

        // [GIVEN] Modify MarketingSetup."Bus. Rel. Code for Customers" = "X".
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);

        // [GIVEN] Create Contact "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create Contact Business Relation without UI validation: "Contact No." = "C", "Business Relation Code" = "X"
        LibraryMarketing.CreateContactBusinessRelation(ContactBusinessRelation, Contact."No.", BusinessRelation.Code);

        // [THEN] New Contact Business Relation record is created without "Business Relation Code" field validation check
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        Assert.RecordIsNotEmpty(ContactBusinessRelation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactBusinessRelationIsCreatedWithValidationCheckWhenUIRun()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        BusinessRelationContacts: TestPage "Business Relation Contacts";
    begin
        // [FEATURE] [Contact Business Relation]
        // [SCENARIO 375531] Contact Business Relation record is created with "Business Relation Code" field validation check in case of UI running
        Initialize();

        // [GIVEN] Create new Business Relation Code "X".
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);

        // [GIVEN] Modify MarketingSetup."Bus. Rel. Code for Customers" = "X".
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);

        // [GIVEN] Create Contact "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create Contact Business Relation with through UI page: "Contact No." = "C"
        BusinessRelationContacts.OpenEdit();
        BusinessRelationContacts.FILTER.SetFilter("Business Relation Code", BusinessRelation.Code);
        BusinessRelationContacts.New();
        asserterror BusinessRelationContacts."Contact No.".SetValue(Contact."No.");

        // [THEN] Error occurs: "Business Relation Code" field validation check
        Assert.ExpectedErrorCode('TestValidation');
        Assert.ExpectedError(
          StrSubstNo(
            BusRelContactValidationErr,
            ContactBusinessRelation.FieldCaption("Business Relation Code"),
            BusinessRelation.Code,
            Contact.TableCaption(), Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageContactBusinessRelationsShowsDetailsFields()
    var
        Customer: Record Customer;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactBusinessRelations: TestPage "Contact Business Relations";
    begin
        // [SCENARIO 375706] Check "Contact Business Relations" page 5061 shows "Link to Table" and "No." fields
        Initialize();

        // [GIVEN] Business Relation "X". Set "X" as default Business Relation Code for Customers.
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);

        // [GIVEN] Customer "A" linked to Contact "B".
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Open "Contact Business Relations" page for Contact "B".
        FindContactBusinessRelation(
          ContactBusinessRelation, BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
        ContactBusinessRelations.OpenView();
        ContactBusinessRelations.GotoRecord(ContactBusinessRelation);

        // [THEN] Contact Business Relation "B" is shown, where "Business Relation Code" = "X", "Link to Table" = Customer, "No."= "A"
        ContactBusinessRelations."Business Relation Code".AssertEquals(BusinessRelation.Code);
        ContactBusinessRelations."Link to Table".AssertEquals(ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelations."No.".AssertEquals(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageBusinessRelationContactsShowsDetailsFields()
    var
        Customer: Record Customer;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        BusinessRelationContacts: TestPage "Business Relation Contacts";
    begin
        // [SCENARIO 375706] Check "Business Relation Contacts" page 5062 shows "Link to Table" and "No." fields
        Initialize();

        // [GIVEN] Business Relation "X". Set "X" as default Business Relation Code for Customers.
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);

        // [GIVEN] Customer "A" linked to Contact "B".
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Open "Business Relation Contacts" page for "X" code.
        FindContactBusinessRelation(
          ContactBusinessRelation, BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
        BusinessRelationContacts.OpenView();
        BusinessRelationContacts.GotoRecord(ContactBusinessRelation);

        // [THEN] Business Relation Contact "X" is shown, where "Contact No." = "B", "Link to Table" = Customer, "No."= "A"
        BusinessRelationContacts."Contact No.".AssertEquals(ContactBusinessRelation."Contact No.");
        BusinessRelationContacts."Link to Table".AssertEquals(ContactBusinessRelation."Link to Table"::Customer);
        BusinessRelationContacts."No.".AssertEquals(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactWithBlankAddressGetsUpdatedWhenAssignToCompany()
    var
        Contact: Record Contact;
        CompanyContact: Record Contact;
    begin
        // Check that empty contact address fields get updated after linking contact to company.

        // [GIVEN] Person contact with blank address and company contact with address exist
        Initialize();
        CreateContactAsPerson(Contact);
        Contact.Validate("Company No.", '');
        Contact.Modify();
        CompanyContact.Get(CreateCompanyContact(LibraryUtility.GenerateGUID()));
        SetAddress(CompanyContact);
        CompanyContact.Modify();

        // [WHEN] Person contact is assigned to the company contact
        Contact.Validate("Company No.", CompanyContact."No.");

        // [THEN] Person contact address fields are updated to the company contact address fields
        VerifySameAddress(CompanyContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactWithNonBlankAddressNotUpdatedWhenAssignToCompany()
    var
        OldContact: Record Contact;
        Contact: Record Contact;
        CompanyContact: Record Contact;
    begin
        // Check that non empty contact address fields don't get updated after linking contact to company.

        // [GIVEN] Person contact and company contact exist, each with nonempty address fields
        Initialize();
        CreateContactAsPerson(Contact);
        CompanyContact.Get(CreateCompanyContact(LibraryUtility.GenerateGUID()));
        SetAddress(CompanyContact);
        CompanyContact.Modify();
        SetAddress(Contact);
        Contact.Validate("Company No.", '');
        Contact.Modify();
        OldContact.TransferFields(Contact);

        // [WHEN] Person contact is assigned to the company contact
        Contact.Validate("Company No.", CompanyContact."No.");

        // [THEN] Address fields of person contact did not change
        VerifySameAddress(OldContact, Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactWithCompanyAddressGetsUpdatedWhenAssignToNewCompany()
    var
        Contact: Record Contact;
        CompanyContact1: Record Contact;
        CompanyContact2: Record Contact;
    begin
        // Check that contact address fields get updated after linking contact to a new company.

        // [GIVEN] Person contact and two company contacts exist
        Initialize();
        CreateContactAsPerson(Contact);
        Contact.Validate("Company No.", '');
        Contact.Modify();
        CompanyContact1.Get(CreateCompanyContact(LibraryUtility.GenerateGUID()));
        CompanyContact2.Get(CreateCompanyContact(LibraryUtility.GenerateGUID()));

        // [WHEN] Company contacts are given different addresses
        SetAddress(CompanyContact1);
        SetAddress(CompanyContact2);
        CompanyContact1.Modify();
        CompanyContact2.Modify();

        // [WHEN] Person contact is assigned to a company
        Contact.Validate("Company No.", CompanyContact1."No.");

        // [WHEN] Person contact is assigned to a different company
        Contact.Validate("Company No.", CompanyContact2."No.");

        // [THEN] Person contact address gets changed to the company address
        VerifySameAddress(CompanyContact2, Contact);
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler,ConfirmHandlerTrue,CustomerTempModalFormHandler,StandardQuoteReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteForContactCustomerTemplate()
    var
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplateCode: Code[20];
    begin
        // [SCENARIO 180155] Create Sales Quote for Contact with Customer Template selection
        Initialize();
        UpdateCompanyInformationPaymentInfo(true);

        // [GIVEN] Customer Template "CT", Contact "C" with type Company
        CreateVATPostingSetup(VATPostingSetup);
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryVariableStorage.Enqueue(Contact."No.");
        CustomerTemplateCode := CreateCustomerTemplateForContact(VATPostingSetup."VAT Bus. Posting Group");
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);

        // [GIVEN] New Sales Quote "SQ"
        CreateSalesQuote(SalesHeader);

        // [WHEN] User looks up in Sell-to Contact field, selects Contact "C" and selects Customer Template "CT"
        SalesQuoteContactNoLookup(SalesHeader);

        // [THEN] Sales Document "SQ" has Customer Template = "CT"
        SalesHeader.TestField("Sell-to Customer Templ. Code", CustomerTemplateCode);

        // [WHEN] Sales Line with Item added
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNoWithPostingSetup(GenProductPostingGroup.Code, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));

        // [THEN] Sales Quote Report can be printed
        PrintSalesQuoteReport(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler,ConfirmHandlerTrue,CustomerTempModalFormHandler,StandardQuoteReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteForContactPersonCustomerTemplate()
    var
        ContactPerson: Record Contact;
        ContactCompany: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        CustomerTemplateCode: Code[20];
    begin
        // [SCENARIO 180155] Create Sales Quote for Contact which is a contact for Company Contact
        Initialize();
        UpdateCompanyInformationPaymentInfo(true);

        // [GIVEN] Contact "C1" with type Company
        ContactCompany.Get(CreateCompanyContact(LibraryUtility.GenerateGUID()));

        // [GIVEN] Contact "C2" with type Person and Company No = "C1"
        CreateContactAsPerson(ContactPerson);
        ContactPerson."Company No." := ContactCompany."No.";
        ContactPerson.Modify();
        LibraryVariableStorage.Enqueue(ContactPerson."No.");

        // [GIVEN] Customer Template "CT"
        CreateVATPostingSetup(VATPostingSetup);
        CustomerTemplateCode := CreateCustomerTemplateForContact(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] New Sales Quote "SQ"
        CreateSalesQuote(SalesHeader);

        // [WHEN] User looks up in Sell-to Contact field, selects Contact "C2" and selects Customer Template "CT"
        SalesQuoteContactNoLookup(SalesHeader);

        // [THEN] Sales Document "SQ" has Customer Template = "CT"
        SalesHeader.TestField("Sell-to Customer Templ. Code", CustomerTemplateCode);

        // [WHEN] Sales Line with Item added
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNoWithPostingSetup(GenProductPostingGroup.Code, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));

        // [THEN] Sales Quote Report can be printed
        PrintSalesQuoteReport(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteForContactWithBusinessRelation()
    var
        ContactCompany: Record Contact;
        SalesHeader: Record "Sales Header";
        CustomerTemplateCode: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 180155] Customer Template is not asked for Contact with Contact Business Relation
        Initialize();

        // [GIVEN] Contact "C1" with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryVariableStorage.Enqueue(ContactCompany."No.");

        // [GIVEN] Customer Template "CT"
        CustomerTemplateCode := CreateCustomerTemplateForContact('');

        // [GIVEN] Customer "CU1" with relation to Contact "C1"
        CustomerNo := CreateCustomerForContact(ContactCompany, CustomerTemplateCode);

        // [GIVEN] New Sales Quote "SQ"
        CreateSalesQuote(SalesHeader);

        // [WHEN] User looks up in Sell-to Contact field, selects Contact "C1"
        SalesQuoteContactNoLookup(SalesHeader);
        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesHeader."No.");

        // [THEN] Customer Template is not asked, Sell-to Customer No. = "CU1"
        SalesHeader.TestField("Sell-to Customer Templ. Code", '');
        SalesHeader.TestField("Sell-to Customer No.", CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,CustomerTempModalFormHandler')]
    [Scope('OnPrem')]
    procedure ContactListNewSalesQuoteForContactCompanyCustomerTemplate()
    var
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        ContactList: TestPage "Contact List";
        SalesQuote: TestPage "Sales Quote";
        CustomerTemplateCode: Code[20];
    begin
        // [SCENARIO 198367] Create Sales Quote from Contact List page for Contact with Customer Template selection
        Initialize();

        // [GIVEN] Customer Template "CT", Contact "C" with type Company
        LibraryMarketing.CreateCompanyContact(Contact);
        CustomerTemplateCode := CreateCustomerTemplateForContact('');

        // [GIVEN] Contact List page is opened and focus is set on Contact "C"
        ContactList.OpenView();
        ContactList.GotoRecord(Contact);

        // [WHEN] "New Sales Quote" Action is pressed
        SalesQuote.Trap();

        ContactList.NewSalesQuote.Invoke();

        SalesQuote.Close();
        // [THEN] User is asked for Customer Template selection
        // [THEN] After user selected Customer Template "CT" - new Sales Quote with Customer opens
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.SetRange("Sell-to Contact No.", Contact."No.");
        SalesHeader.SetRange("Sell-to Customer Templ. Code", CustomerTemplateCode);
        Assert.RecordIsNotEmpty(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalseWithTextVerification')]
    [Scope('OnPrem')]
    procedure ContactListSalesQuoteForContactPerson()
    var
        Contact: Record Contact;
        ContactList: TestPage "Contact List";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 198367] Create Sales Quote from Contact List for Customer with Person Type
        Initialize();

        // [GIVEN] Contact with Type = Person
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] Contact List page is opened and focus is set on Contact "C"
        ContactList.OpenView();
        ContactList.GotoRecord(Contact);

        // [WHEN] "New Sales Quote" Action is pressed
        LibraryVariableStorage.Enqueue(SelectCustomerTemplateQst);
        SalesQuote.Trap();

        ContactList.NewSalesQuote.Invoke();

        SalesQuote.Close();
        // [THEN] SalesQuote Page opens (handled in ModalPageHandler)
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler,ConfirmHandlerTrue,CustomerTempModalFormHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteEmailDialogForContact()
    begin
        SalesQuoteEmailDialogForContactInternal();
    end;

    procedure SalesQuoteEmailDialogForContactInternal()
    var
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        LibraryEmail: Codeunit "Library - Email";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 199641] Email Dialog shows Contact Email when Sales Quote created for Contact
        Initialize();
        LibraryEmail.SetUpEmailAccount();
        UpdateCompanyInformationPaymentInfo(true);

        // [GIVEN] Customer Template "CT", Contact "C" with type Company and Email "Email"
        CreateVATPostingSetup(VATPostingSetup);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Contact.Modify();
        LibraryVariableStorage.Enqueue(Contact."No.");
        CreateCustomerTemplateForContact(VATPostingSetup."VAT Bus. Posting Group");
        LibraryVariableStorage.Enqueue(Contact."E-Mail");

        // [GIVEN] Sales Quote with selected Contact and Customer Template
        CreateSalesQuote(SalesHeader);

        SalesQuoteContactNoLookup(SalesHeader);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNoWithPostingSetup(GenProductPostingGroup.Code, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));

        // [WHEN] "Send by Email" action invoked
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.Email.Invoke();

        // [THEN] Email Dialog opened and "To:" = "Email"
        // Checked in EmailVerifyModalPageHandler handler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SalesHeaderGetBillToNoForContCust()
    var
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        CustomerTemplateCode: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 199641] Unit Test for function GetBillToNo of Sales Header table

        Initialize();
        // [GIVEN] Contact "C", Customer Template "CT" for Contact "C" and Customer "CUST"
        LibraryMarketing.CreateCompanyContact(Contact);
        CustomerTemplateCode := CreateCustomerTemplateForContact('');
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Sales Quote "SQ" with Bill-to Contact No. = "C" and Bill-to Customer Template Code = "CT"
        CreateSalesQuote(SalesHeader);
        SalesHeader.Validate("Bill-to Contact No.", Contact."No.");
        SalesHeader.Validate("Bill-to Customer Templ. Code", CustomerTemplateCode);
        SalesHeader.Modify();

        // [WHEN] GetBillToNo run
        // [THEN] Return value = "C"
        Assert.AreEqual(Contact."No.", SalesHeader.GetBillToNo(), WrongValueErr);

        // [WHEN] Bill-to Customer Template Code = '' and GetBillToNo run
        // [THEN] Return value = ""
        SalesHeader.Validate("Bill-to Customer Templ. Code", '');
        SalesHeader.Modify();
        Assert.AreEqual('', SalesHeader.GetBillToNo(), WrongValueErr);

        // [WHEN] Bill-to Customer Template Code = "CT", "Bill-to Contact No." = '' and GetBillToNo run
        // [THEN] Return value = ""
        SalesHeader.Validate("Bill-to Customer Templ. Code", CustomerTemplateCode);
        SalesHeader.Validate("Bill-to Contact No.", '');
        SalesHeader.Modify();
        Assert.AreEqual('', SalesHeader.GetBillToNo(), WrongValueErr);

        // [WHEN] Bill-to Customer No. = "CUST" and GetBillToNo run
        // [THEN] Return value = "CUST"
        SalesHeader.Validate("Bill-to Customer No.", CustomerNo);
        SalesHeader.Modify();

        Assert.AreEqual(CustomerNo, SalesHeader.GetBillToNo(), WrongValueErr);
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactCoverSheetReportLog()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplateSetup: Record "Interaction Template Setup";
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [Cover Sheet]
        // [SCENARIO 180159] Verify Contact Cover Sheet report print Company and Contact Information
        Initialize();

        // [GIVEN] Contact with filled Address fields
        CreateContactWithAddress(Contact);

        // [WHEN] Report is printed from Contact Card Page, Log Interaction = TRUE
        OpenContactCard(ContactCard, Contact);
        LibraryVariableStorage.Enqueue(true);
        Commit();
        ContactCard.ContactCoverSheet.Invoke();
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Contact address and Company Information fields are filled
        VerifyContactCoverSheetCompanyInfoReport();
        VerifyContactCoverSheetContactInfoReport(Contact);

        // [THEN] Interation Log Entries created for "C1" Contact
        InteractionTemplateSetup.Get();
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        InteractionLogEntry.SetRange("Interaction Template Code", InteractionTemplateSetup."Cover Sheets");
        Assert.RecordIsNotEmpty(InteractionLogEntry);
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactCoverSheetReportNoLog()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplateSetup: Record "Interaction Template Setup";
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [Cover Sheet]
        // [SCENARIO 180159] Verify no interaction log entry created when Log Interaction = FALSE on report request form
        Initialize();

        // [GIVEN] Contact with filled Address fields
        CreateContactAsPerson(Contact);

        // [WHEN] Report is printed from Contact Card Page, Log Interaction = FALSE
        OpenContactCard(ContactCard, Contact);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        ContactCard.ContactCoverSheet.Invoke();
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] No Interation Log Entries created for "C1" Contact
        VerifyContactCoverSheetCompanyInfoReport();
        InteractionTemplateSetup.Get();
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        InteractionLogEntry.SetRange("Interaction Template Code", InteractionTemplateSetup."Cover Sheets");
        Assert.RecordIsEmpty(InteractionLogEntry);
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ContactCoverSheetReportMultipleContacts()
    var
        Contact: Record Contact;
        Contact1: Record Contact;
        Contact2: Record Contact;
    begin
        // [FEATURE] [Cover Sheet]
        // [SCENARIO 180159] Verify Contact Cover Sheet printed for 2 Contacts
        Initialize();

        // [GIVEN] Contacts "C1" and "C2" with filled Address fields
        CreateContactWithAddress(Contact1);
        CreateContactWithAddress(Contact2);

        // [WHEN] Report Contact Cover Sheet is printed for Contacts "C1" and "C2"
        Contact.SetFilter("No.", '%1|%2', Contact1."No.", Contact2."No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();
        REPORT.Run(REPORT::"Contact Cover Sheet", true, false, Contact);
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Report is printed for Contacts "C1" and "C2"
        VerifyContactCoverSheetContactInfoReport(Contact1);
        VerifyContactCoverSheetContactInfoReport(Contact2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonalContactPhoneEmailShouldNotTransferToCustomer()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        Customer: Record Customer;
    begin
        // [SCENARIO 202046] Customer Email and Phone No. is not updated when the Primary Contact field is referring to a personal contact.
        Initialize();

        // [GIVEN] Company Contact "CC"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Person Contact "PC" related to "CC" with E-Mail = "EMAIL" and Phone No. = "PHONENO"
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."Company No.");
        PersonContact.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        PersonContact.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        PersonContact.Modify(true);

        // [GIVEN] Customer created from "CC" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateCustomerFromTemplate('');
        Customer.SetRange(Name, CompanyContact.Name);
        Customer.FindFirst();

        // [WHEN] Customer Primary Contact No. changed to "PC"
        Customer.Validate("Primary Contact No.", PersonContact."No.");
        Customer.Modify();

        // [THEN] Customer E-Mail and Phone No. stays unchanged.
        Customer.TestField("E-Mail", CompanyContact."E-Mail");
        Customer.TestField("Phone No.", CompanyContact."Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonalContactPhoneEmailShouldNotTransferToVendor()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        Vendor: Record Vendor;
    begin
        // [SCENARIO 202046] Vendor Email and Phone No.is not updated when the Primary Contact field is referring to a personal contact.
        Initialize();

        // [GIVEN] Company Contact "CC"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Person Contact "PC" related to "CC" with E-Mail = "EMAIL" and Phone No. = "PHONENO"
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."Company No.");
        PersonContact.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        PersonContact.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        PersonContact.Modify(true);

        // [GIVEN] Vendor created from "CC" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateVendorFromTemplate('');
        Vendor.SetRange(Name, CompanyContact.Name);
        Vendor.FindFirst();

        // [WHEN] Vendor Primary Contact No. changed to "PC"
        Vendor.Validate("Primary Contact No.", PersonContact."No.");
        Vendor.Modify();

        // [THEN] Vendor E-Mail and Phone No. stays unchanged.
        Vendor.TestField("E-Mail", CompanyContact."E-Mail");
        Vendor.TestField("Phone No.", CompanyContact."Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCountryRegionToCustTemplateEmptyCountryRegion()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 202044] Customer creation from Contact with Country/Region Code using Template with empty Country/Region Code
        Initialize();

        // [GIVEN] Contact "C" with Country/Region Code = "CRC"
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", CountryRegion.Code);
        Contact.Modify();

        // [GIVEN] Customer Template "CT" with Country/Region Code = ''
        CustomerTemplate.Get(CreateCustomerTemplateForContact(''));
        CustomerTemplate.Validate("Country/Region Code", '');
        CustomerTemplate.Modify();

        // [WHEN] Create Customer "CU" from Contact "C" with Customer Template "CT"
        CreateCustomerFromContact(Contact, CustomerTemplate.Code, Customer);

        // [THEN] Customer "CU" created with Country/Region Code = "CRC"
        Customer.TestField("Country/Region Code", Contact."Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactEmptyCountryRegionToCustTemplateCountryRegion()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 202044] Customer creation from Contact without Country/Region Code using Template with Country/Region Code
        Initialize();

        // [GIVEN] Contact "C" with Country/Region Code = ''
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", '');
        Contact.Modify();

        // [GIVEN] Customer Template "CT" with Country/Region Code = "CRC"
        LibraryERM.CreateCountryRegion(CountryRegion);
        CustomerTemplate.Get(CreateCustomerTemplateForContact(''));
        CustomerTemplate.Validate("Country/Region Code", CountryRegion.Code);
        CustomerTemplate.Modify();

        // [WHEN] Create Customer "CU" from Contact "C" with Customer Template "CT"
        CreateCustomerFromContact(Contact, CustomerTemplate.Code, Customer);

        // [THEN] Customer "CU" created with Country/Region Code = "CRC"
        Customer.TestField("Country/Region Code", CustomerTemplate."Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCountryRegionToCustTemplateCountryRegion()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Customer: Record Customer;
        ContactCountryRegion: Record "Country/Region";
        TemplateCountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 202044] Customer creation from Contact with Country/Region Code using Template with Country/Region Code
        Initialize();

        // [GIVEN] Contact "C" with Country/Region Code = "CRC1"
        LibraryERM.CreateCountryRegion(ContactCountryRegion);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", ContactCountryRegion.Code);
        Contact.Modify();

        // [GIVEN] Customer Template "CT" with Country/Region Code = "CRC2"
        LibraryERM.CreateCountryRegion(TemplateCountryRegion);
        CustomerTemplate.Get(CreateCustomerTemplateForContact(''));
        CustomerTemplate.Validate("Country/Region Code", TemplateCountryRegion.Code);
        CustomerTemplate.Modify();

        // [WHEN] Create Customer "CU" from Contact "C" with Customer Template "CT"
        CreateCustomerFromContact(Contact, CustomerTemplate.Code, Customer);

        // [THEN] Customer "CU" created with Country/Region Code = "CRC1"
        Customer.TestField("Country/Region Code", Contact."Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactEmptyCountryRegionToCustTemplateEmptyCountryRegion()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Customer: Record Customer;
    begin
        // [SCENARIO 202044] Customer creation from Contact with empty Country/Region Code using Template with empty Country/Region Code
        Initialize();

        // [GIVEN] Contact "C" with Country/Region Code = ''
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", '');
        Contact.Modify();

        // [GIVEN] Customer Template "CT" with Country/Region Code = ''
        CustomerTemplate.Get(CreateCustomerTemplateForContact(''));
        CustomerTemplate.Validate("Country/Region Code", '');
        CustomerTemplate.Modify();

        // [WHEN] Create Customer "CU" from Contact "C" with Customer Template "CT"
        CreateCustomerFromContact(Contact, CustomerTemplate.Code, Customer);

        // [THEN] Customer "CU" created with Country/Region Code = ''
        Customer.TestField("Country/Region Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCityCountyToCustTemplateEmptyCountryRegion()
    var
        Contact: Record Contact;
        CustomerTemplate: Record "Customer Templ.";
        Customer: Record Customer;
        PostCode: Record "Post Code";
        ContactCountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 282816] Customer creation from Contact using Template in case of two Post Codes with the same Code, Country/Region, but with different City, County.
        Initialize();

        // [GIVEN] Two Post Codes with the same Code and "Country/Region Code", but with different City and County.
        // [GIVEN] "Post Code" = "PC2" for the second Post Code.
        LibraryERM.CreateCountryRegion(ContactCountryRegion);
        CreatePostCode(
          PostCode, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(),
          ContactCountryRegion.Code, LibraryUtility.GenerateGUID());
        CreatePostCode(
          PostCode, PostCode.Code, LibraryUtility.GenerateGUID(),
          ContactCountryRegion.Code, LibraryUtility.GenerateGUID());

        // [GIVEN] Contact with "Post Code" = "PC2". City, "Country/Region Code", County are from "PC2".
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate(City, PostCode.City);
        Contact.Modify(true);

        // [GIVEN] Customer Template with empty "Country/Region Code".
        CustomerTemplate.Get(CreateCustomerTemplateForContact(''));
        CustomerTemplate.Validate("Country/Region Code", '');
        CustomerTemplate.Modify();

        // [WHEN] Create Customer from Contact with Customer Template.
        CreateCustomerFromContact(Contact, CustomerTemplate.Code, Customer);

        // [THEN] Customer is created. "Post Code", City, "Country/Region Code", County are from Contact.
        Customer.TestField("Post Code", Contact."Post Code");
        Customer.TestField(City, Contact.City);
        Customer.TestField("Country/Region Code", Contact."Country/Region Code");
        Customer.TestField(County, Contact.County);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,CustomerTempModalPageHandlerWithEnqueue')]
    [Scope('OnPrem')]
    procedure CreateSalesQuoteFromContactListAndCustTemplateConfirmation()
    var
        Contact: Record Contact;
        CustomerTempl: Record "Customer Templ.";
        ContactList: TestPage "Contact List";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI] [Sales Quote]
        // [SCENARIO 205513] Stan can create sales quote from "Contact List" when press action "New Sales Quote", confirm and select "Customer Template"

        Initialize();

        // [GIVEN] Contact
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryTemplates.CreateCustomerTemplate(CustomerTempl);

        // [GIVEN] "Contact list" page is opened
        ContactList.OpenView();
        ContactList.GotoRecord(Contact);

        // [GIVEN] Press action "New Sales Quote", confirm message "Do you want to select the customer template?" and select template "X"
        // The CustomerTempModalPageHandlerWithEnqueue gets the expected customer template into LibraryVariableStorage
        SalesQuote.Trap();

        // [WHEN] Move cursor to the next field in "Sales Quote" page to create new record
        ContactList.NewSalesQuote.Invoke();

        // [THEN] Sales Quote is populated with "Sell-To Customer Template Code" = "X"
        SalesQuote."Sell-to Address".SetValue('');
        SalesQuote."Sell-to Customer Templ. Code".AssertEquals(LibraryVariableStorage.DequeueText());
        SalesQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalseWithTextVerification')]
    [Scope('OnPrem')]
    procedure UT_CustTemplateConfirmationWhenContactPersonHasNoBusRelation()
    var
        ContactPerson: Record Contact;
        ContactCompany: Record Contact;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 205513] Confirmation is raised when Sales Quote validates with Contact (Type = Person) which does not have business relation with customer

        Initialize();

        // [GIVEN] New Sales Quote
        CreateSalesQuote(SalesHeader);

        // [GIVEN] Contact "X" with Type = Company without business relation with Customer
        LibraryMarketing.CreateCompanyContact(ContactCompany);

        // [GIVEN] Contact "Y" with Type = Person and "Company No." = "X"
        LibraryMarketing.CreatePersonContact(ContactPerson);
        ContactPerson.Validate("Company No.", ContactCompany."No.");
        ContactPerson.Modify(true);
        LibraryVariableStorage.Enqueue(SelectCustomerTemplateQst);

        // [WHEN] Validate "Sell-to Contact No." with "Y"
        SalesHeader.Validate("Sell-to Contact No.", ContactPerson."No.");

        // [THEN] Confirmation "Do you want to select the customer template?" is thrown
        // Verification done by ConfirmHandlerFalseWithTextVerification
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateContsFromCustomersPersonContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
    begin
        // [FEATURE] [Create Contacts from Customers]
        // [SCENARIO 215237] Create Contacts from Customers report create Person Contact for Customer imported using Data Migration
        Initialize();

        // [GIVEN] Customer "CUST" with no Contacts created using Data Migration, Contact = "C", PhoneNo = "PN"
        Customer.SetInsertFromContact(true);  // avoid creation on Contact in OnInsert trigger
        Customer.Contact := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(Customer.Contact));
        Customer."Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        Customer.Insert(true);

        // [WHEN] Run report Create Contact for Customers for Customer "CUST"
        Customer.SetRange("No.", Customer."No.");
        RunCreateContsFromCustomersReport(Customer);
        Customer.Find();

        // [THEN] Contact "C" created with Type = Person, Name = "C", Phone No. = "PN"
        // [THEN] Contact "C" is Primary Contact for Customer "CUST"
        VerifyContact(Customer."Primary Contact No.", Contact.Type::Person, Customer.Contact, Customer."Phone No.")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateContsFromVendorsPersonContact()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        // [FEATURE] [Create Contacts from Vendors]
        // [SCENARIO 215237] Create Contacts from Vendors report create Person Contact for Vendor imported using Data Migration
        Initialize();

        // [GIVEN] Vendor "VEND" with no Contacts created using Data Migration, Contact = "C", PhoneNo = "PN"
        Vendor.SetInsertFromContact(true); // avoid creation on Contact in OnInsert trigger
        Vendor.Contact := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(Vendor.Contact));
        Vendor."Phone No." := LibraryUtility.GenerateRandomPhoneNo();
        Vendor.Insert(true);

        // [WHEN] Run report Create Contact for Vendors for Vendor "VEND"
        Vendor.SetRange("No.", Vendor."No.");
        RunCreateContsFromVendorsReport(Vendor);
        Vendor.Find();

        // [THEN] Contact "C" created with Type = Person, Name = "C", Phone No. = "PN"
        // [THEN] Contact "C" is Primary Contact for Vendor "VEND"
        VerifyContact(Vendor."Primary Contact No.", Contact.Type::Person, Vendor.Contact, Vendor."Phone No.")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOnToDosContactName()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        TaskList: TestPage "Task List";
        TaskCard: TestPage "Task Card";
        ContactList: TestPage "Contact List";
    begin
        // [FEATURE] [To-Do] [UI]
        // [SCENARIO 379509] DrillDown on To-Do's field "Contact Name" should open Contact List page

        Initialize();

        CreateContactWithToDos(Contact);

        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", Contact."No.");
        TaskList.Trap();
        ContactCard."T&asks".Invoke();
        TaskCard.Trap();
        TaskList."Edit Organizer Task".Invoke();
        ContactList.Trap();
        TaskCard."Contact Name".DrillDown();

        ContactList."No.".AssertEquals(Contact."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,CustomerTempModalFormHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PredefinedDataInContactAssignsToCustomer()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerTemplate: Record "Customer Templ.";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 216960] The predefined data from Contact assigns to Customer when create Customer from Contact

        Initialize();

        // [GIVEN] Business Relation and input it in the field Bus. Rel. Code for Customers of Marketing Setup.
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);

        // [GIVEN] Customer Template with "Currency Code" = EUR, "Country/Region" = DE, "Territory" = "FOREIGN"
        CreateCustomerTemplate(CustomerTemplate, CustomerPriceGroup.Code);
        CustomerTemplate."Contact Type" := CustomerTemplate."Contact Type"::Person;
        CustomerTemplate.Modify(true);

        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate."Contact Type" := CustomerTemplate."Contact Type"::Person;
        CustomerTemplate.Modify(true);

        // [GIVEN] Contact with "Currency Code" = GBP, "Country/Region" = GB, "Territory" = "LONDON"
        CreateContactWithData(Contact);

        // [WHEN] Create Customer from Contact with selected Customer Template
        Contact.CreateCustomerFromTemplate(Contact.ChooseNewCustomerTemplate());

        // [THEN] Contact is created with "Currency Code" = GBP, "Country/Region" = GB, "Territory" = "LONDON"
        VerifyCustomerInheritsDataFromContact(Contact);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,CustomerTempModalFormHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCreatedFromContactWithNoData()
    var
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        CustomerTemplate: Record "Customer Templ.";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 216960] Customer creates from Contact with no data assigned if no data specified in Contact

        Initialize();

        // [GIVEN] Business Relation and input it in the field Bus. Rel. Code for Customers of Marketing Setup.
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);

        // [GIVEN] Customer Template with "blank Currency Code", "Country/Region" and "Territory"
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate."Contact Type" := CustomerTemplate."Contact Type"::Person;
        CustomerTemplate.Modify(true);
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code);

        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate."Contact Type" := CustomerTemplate."Contact Type"::Person;
        CustomerTemplate.Modify(true);

        // [GIVEN] Contact with blank "Currency Code", "Country/Region" and "Territory"
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Create Customer from Contact with selected Customer Template
        Contact.CreateCustomerFromTemplate(Contact.ChooseNewCustomerTemplate());

        // [THEN] Contact is created with blank "Currency Code", "Country/Region" and "Territory"
        VerifyCustomerInheritsDataFromContact(Contact);
    end;

    [Test]
    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure ShowSuggestCreateContactForCustomerNotification()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Notification] [Customer]
        // [SCENARIO 216150] Notifications suggesting to create Contacts appear in Customer List page
        Initialize();

        // [GIVEN] Customer "C" exist with no Contact assigned (no business relations)
        CreateCustomer(Customer);

        // [WHEN] Customer List page is opened
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [THEN] Notification is shown
        Assert.ExpectedMessage(YouCanGetContactFromCustTxt, LibraryVariableStorage.DequeueText());

        // [WHEN] Customer List page is opened
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [THEN] Notification is shown
        Assert.ExpectedMessage(YouCanGetContactFromCustTxt, LibraryVariableStorage.DequeueText());
        Customer.Delete();
    end;

    [Test]
    [HandlerFunctions('NotificationHandler')]
    [Scope('OnPrem')]
    procedure ShowSuggestCreateContactForVendorNotification()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Notification] [Vendor]
        // [SCENARIO 216150] Notifications suggesting to create Contacts appear in Vendor List page
        Initialize();

        // [GIVEN] Vendor "V" exist with no Contact assigned (no business relations)
        CreateVendor(Vendor);

        // [WHEN] Vendor List page is opened
        VendorList.OpenEdit();
        VendorList.GotoRecord(Vendor);

        // [THEN] Notification is shown
        Assert.ExpectedMessage(YouCanGetContactFromVendTxt, LibraryVariableStorage.DequeueText());

        // [WHEN] Vendor List page is opened
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [THEN] Notification is shown
        Assert.ExpectedMessage(YouCanGetContactFromVendTxt, LibraryVariableStorage.DequeueText());
        Vendor.Delete();
    end;

    [Test]
    [HandlerFunctions('MyNotificationsModalPageHandler')]
    [Scope('OnPrem')]
    procedure DisabledContactNotificationsDontAppear()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        SalesRelationshipMgrAct: TestPage "Sales & Relationship Mgr. Act.";
        VendorList: TestPage "Vendor List";
        CustomerList: TestPage "Customer List";
    begin
        // [FEATURE] [Notification] [Customer] [Vendor]
        // [SCENARIO 216150] Notifications suggesting to create Contacts don't appear if Disabled
        Initialize();

        // [GIVEN] Notifications for Contacts creation from Customers are off
        LibraryVariableStorage.Enqueue(false);

        // [GIVEN] Notifications for Contacts creation from Vendors are off
        LibraryVariableStorage.Enqueue(false);
        OpenMyNotificationsFromSettings();

        // [GIVEN] Customer "C" and Vendor "B" exist without Contacts assigned
        CreateCustomer(Customer);
        CreateVendor(Vendor);

        // [WHEN] Sales & Relationship Manager role center is opened
        SalesRelationshipMgrAct.OpenView();
        // [THEN] No notifications suggesting to create Contacts appear
        SalesRelationshipMgrAct.Close();

        // [WHEN] Customer List is opened
        CustomerList.OpenEdit();
        // [THEN] No notifications suggesting to create Contacts appear
        CustomerList.Close();

        // [WHEN] Vendor List is opened
        VendorList.OpenEdit();
        // [THEN] No notifications suggesting to create Contacts appear
        VendorList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableNotInitializedCustomerNotification()
    var
        Customer: Record Customer;
        MyNotifications: Record "My Notifications";
        DataMigrationNotifier: Codeunit "Data Migration Notifier";
        DummyNotification: Notification;
    begin
        // [FEATURE] [Notification] [UT] [Customer]
        // [SCENARIO 216150] Not initialized notification for customer can be disabled
        Initialize();

        // [GIVEN] Customer "C"
        CreateCustomer(Customer);

        // [GIVEN] Customer Notification entry does not exist in MyNotification table
        // [WHEN] Disabling action is invoked from notification
        DataMigrationNotifier.RemoveCustomerContactNotification(DummyNotification);

        // [THEN] Customer notification is disabled
        Assert.IsFalse(MyNotifications.IsEnabled(CustomerContNotifTok), 'Wrong notification state');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableNotInitializedVendorNotification()
    var
        Vendor: Record Vendor;
        MyNotifications: Record "My Notifications";
        DataMigrationNotifier: Codeunit "Data Migration Notifier";
        DummyNotification: Notification;
    begin
        // [FEATURE] [Notification] [UT] [Vendor]
        // [SCENARIO 216150] Not initialized notification for vendor can be disabled
        Initialize();

        // [GIVEN] Vendor "V"
        CreateVendor(Vendor);

        // [GIVEN] Vendor Notification entry does not exist in MyNotification table

        // [WHEN] Disabling action is invoked from vendor notification
        DataMigrationNotifier.RemoveCustomerContactNotification(DummyNotification);

        // [THEN] Vendor notification is disabled
        Assert.IsFalse(MyNotifications.IsEnabled(CustomerContNotifTok), 'Wrong notification state');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignUnlinkedContact_ToUnlinkedVendorPrimaryContactNo()
    var
        Vendor: Record Vendor;
        ContactPerson: Record Contact;
        ContactCompany: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] Assign standalone unlinked Contact with Type::Person to a unlinked Vendor as a Primary Contact No.
        Initialize();

        // [GIVEN] Vendor "V" without ContactBusinessRelation record.
        CreateVendorWithSetupBusinessRelation(Vendor);

        // [GIVEN] Contact "C" with Type::Person.
        LibraryMarketing.CreatePersonContact(ContactPerson);

        // [WHEN] Assign "C" to "V" as "Primary Contact No.".
        Vendor.Validate("Primary Contact No.", ContactPerson."No.");
        Vendor.Modify(true);

        // [THEN] Contact with Type::Company created for "C"
        ContactPerson.Find();
        ContactCompany.Get(ContactPerson."Company No.");

        // [THEN] ContactBusinessRelation record created for "V" and "C".CompanyNo.
        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactCompany."No.", Vendor."No.", ContactBusinessRelation."Link to Table"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignUnlinkedContact_ToUnlinkedCustomerPrimaryContactNo()
    var
        Customer: Record Customer;
        ContactPerson: Record Contact;
        ContactCompany: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] Assign standalone unlinked Contact with Type::Person to a unlinked Customer as a Primary Contact No.
        Initialize();

        // [GIVEN] Customer "Cus" without ContactBusinessRelation record.
        CreateCustomerWithSetupBusinessRelation(Customer);

        // [GIVEN] Contact "C" with Type::Person.
        LibraryMarketing.CreatePersonContact(ContactPerson);

        // [WHEN] Assign "C" to "Cus" as "Primary Contact No.".
        Customer.Validate("Primary Contact No.", ContactPerson."No.");
        Customer.Modify(true);

        // [THEN] Contact with Type::Company created for "C"
        ContactPerson.Find();
        ContactCompany.Get(ContactPerson."Company No.");

        // [THEN] ContactBusinessRelation record created for "Cus" and "C".CompanyNo.
        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactCompany."No.", Customer."No.", ContactBusinessRelation."Link to Table"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignUnlinkedContactWithCompany_ToUnlinkedVendorPrimaryContactNo()
    var
        Vendor: Record Vendor;
        ContactPerson: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] Assign unlinked Contact with Type::Person and with Company No. to a unlinked Vendor as a Primary Contact No.
        Initialize();

        // [GIVEN] Vendor "V" without ContactBusinessRelation record.
        CreateVendorWithSetupBusinessRelation(Vendor);

        // [GIVEN] Contact "C" with Type::Person linked to another Contact with Type::Company via "Company No." field.
        LibraryMarketing.CreatePersonContactWithCompanyNo(ContactPerson);

        // [WHEN] Assign "C" to "V" as "Primary Contact No.".
        Vendor.Validate("Primary Contact No.", ContactPerson."No.");
        Vendor.Modify(true);

        // [THEN] ContactBusinessRelation record created for "V" and "C"."Company No." Contact.
        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactPerson."Company No.", Vendor."No.", ContactBusinessRelation."Link to Table"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignUnlinkedContactWithCompany_ToUnlinkedCustomerPrimaryContactNo()
    var
        Customer: Record Customer;
        ContactPerson: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] Assign unlinked Contact with Type::Person and with Company No. to a unlinked Customer as a Primary Contact No.
        Initialize();

        // [GIVEN] Customer "Cus" without ContactBusinessRelation record.
        CreateCustomerWithSetupBusinessRelation(Customer);

        // [GIVEN] Contact "C" with Type::Person linked to another Contact with Type::Company via "Company No." field.
        LibraryMarketing.CreatePersonContactWithCompanyNo(ContactPerson);

        // [WHEN] Assign "C" to "Cus" as "Primary Contact No.".
        Customer.Validate("Primary Contact No.", ContactPerson."No.");
        Customer.Modify(true);

        // [THEN] ContactBusinessRelation record created for "Cus" and "C"."Company No." Contact.
        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactPerson."Company No.", Customer."No.", ContactBusinessRelation."Link to Table"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignUnlinkedContact_ToLinkedVendorPrimaryContactNo()
    var
        Vendor: Record Vendor;
        ContactPerson: Record Contact;
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] User cannot assign unlinked Contact with Type::Person to a linked Vendor as a Primary Contact No.
        Initialize();

        // [GIVEN] Vendor "V" linked to Contact "CompCont" with Type::Company.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Contact "C" with Type::Person which has no relations.
        LibraryMarketing.CreatePersonContact(ContactPerson);

        // [WHEN] Assign "C" to "V" as "Primary Contact No.".
        asserterror Vendor.Validate("Primary Contact No.", ContactPerson."No.");

        // [THEN] Error is invoked: Contact "C" is not related to vendor "V".
        Assert.ExpectedError(
          StrSubstNo(ContactNotRelatedToVendorErr, ContactPerson."No.", ContactPerson.Name, Vendor."No.", Vendor.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignUnlinkedContact_ToLinkedCustomerPrimaryContactNo()
    var
        Customer: Record Customer;
        ContactPerson: Record Contact;
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] User cannot assign unlinked Contact with Type::Person to a linked Customer as a Primary Contact No.
        Initialize();

        // [GIVEN] Customer "Cus" linked to Contact "CompCont" with Type::Company.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Contact "C" with Type::Person which has no relations.
        LibraryMarketing.CreatePersonContact(ContactPerson);

        // [WHEN] Assign "C" to "Cus" as "Primary Contact No.".
        asserterror Customer.Validate("Primary Contact No.", ContactPerson."No.");

        // [THEN] Error is invoked: Contact "C" is not related to customer "Cus".
        Assert.ExpectedError(
          StrSubstNo(ContactNotRelatedToCustomerErr, ContactPerson."No.", ContactPerson.Name, Customer."No.", Customer.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignLinkedContact_ToUnlinkedVendorPrimaryContactNo()
    var
        Vendor: array[2] of Record Vendor;
        ContactPerson: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] User cannot assign linked Contact with Type::Person to a unlinked Vendor as a Primary Contact No.
        Initialize();

        // [GIVEN] Vendor "V1" linked to Contact "Comp" with Type::Company which is linked to a Contact "C" with Type::Person via "Company No." field.
        CreateVendorWithContactPerson(Vendor[1], ContactPerson, ContBusRel);

        // [GIVEN] Vendor "V2" without ContactBusinessRelation record.
        CreateVendorWithSetupBusinessRelation(Vendor[2]);

        // [WHEN] Assign "C" to "V2" as "Primary Contact No.".
        asserterror Vendor[2].Validate("Primary Contact No.", ContactPerson."No.");

        // [THEN] Error is invoked: Contact "C" already has a Contact Business Relation with Vendor "V".
        Assert.ExpectedError(
          StrSubstNo(RelationAlreadyExistWithVendorErr, ContBusRel."Contact No.", ContBusRel.TableCaption(), Vendor[1]."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignLinkedContact_ToUnlinkedCustomerPrimaryContactNo()
    var
        Customer: array[2] of Record Customer;
        ContactPerson: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] User cannot assign linked Contact with Type::Person to a unlinked Customer as a Primary Contact No.
        Initialize();

        // [GIVEN] Customer "Cus1" linked to Contact "Comp" with Type::Company which is linked to a Contact "C" with Type::Person via "Company No." field.
        CreateCustomerWithContactPerson(Customer[1], ContactPerson, ContBusRel);

        // [GIVEN] Customer "Cus2" without ContactBusinessRelation record.
        CreateCustomerWithSetupBusinessRelation(Customer[2]);

        // [WHEN] Assign "C" to "Cus2" as "Primary Contact No.".
        asserterror Customer[2].Validate("Primary Contact No.", ContactPerson."No.");

        // [THEN] Error is invoked: Contact "C" already has a Contact Business Relation with Customer "Cus1".
        Assert.ExpectedError(
          StrSubstNo(RelationAlreadyExistWithCustomerErr, ContBusRel."Contact No.", ContBusRel.TableCaption(), Customer[1]."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignLinkedContact_ToLinkedVendorPrimaryContactNo()
    var
        Vendor: array[2] of Record Vendor;
        ContactPerson: array[2] of Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] User cannot assign linked Contact with Type::Person to a linked Vendor as a Primary Contact No.
        Initialize();

        // [GIVEN] Vendor "V1" linked to Contact "Comp1" with Type::Company which is linked to a Contact "C1" with Type::Person via "Company No." field.
        CreateVendorWithContactPerson(Vendor[1], ContactPerson[1], ContBusRel);

        // [GIVEN] Vendor "V2" linked to Contact "Comp2" with Type::Company which is linked to a Contact "C2" with Type::Person via "Company No." field.
        CreateVendorWithContactPerson(Vendor[2], ContactPerson[2], ContBusRel);

        // [WHEN] Assign "C1" to "V2" as "Primary Contact No.".
        asserterror Vendor[2].Validate("Primary Contact No.", ContactPerson[1]."No.");

        // [THEN] Error is invoked: Contact "C1" is not related to vendor "V2".
        Assert.ExpectedError(
          StrSubstNo(ContactNotRelatedToVendorErr, ContactPerson[1]."No.", ContactPerson[1].Name, Vendor[2]."No.", Vendor[2].Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignLinkedContact_ToLinkedCustomerPrimaryContactNo()
    var
        Customer: array[2] of Record Customer;
        ContactPerson: array[2] of Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] User cannot assign linked Contact with Type::Person to a linked Customer as a Primary Contact No.
        Initialize();

        // [GIVEN] Customer "Cus1" linked to Contact "Comp1" with Type::Company which is linked to a Contact "C1" with Type::Person via "Company No." field.
        CreateCustomerWithContactPerson(Customer[1], ContactPerson[1], ContBusRel);

        // [GIVEN] Customer "Cus2" linked to Contact "Comp2" with Type::Company which is linked to a Contact "C2" with Type::Person via "Company No." field.
        CreateCustomerWithContactPerson(Customer[2], ContactPerson[2], ContBusRel);

        // [WHEN] Assign "C1" to "Cus2" as "Primary Contact No.".
        asserterror Customer[2].Validate("Primary Contact No.", ContactPerson[1]."No.");

        // [THEN] Error is invoked: Contact "C1" is not related to customer "Cus2".
        Assert.ExpectedError(
          StrSubstNo(ContactNotRelatedToCustomerErr, ContactPerson[1]."No.", ContactPerson[1].Name, Customer[2]."No.", Customer[2].Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelCreateRelation_ForVendor()
    var
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactCompanyNo: Code[20];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] UT ContactBusinessRelation.CreateRelation for Vendor side
        Initialize();

        CreateVendorWithSetupBusinessRelation(Vendor);
        ContactCompanyNo := LibraryMarketing.CreateCompanyContactNo();

        ContactBusinessRelation.CreateRelation(ContactCompanyNo, Vendor."No.", ContactBusinessRelation."Link to Table"::Vendor);

        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactCompanyNo, Vendor."No.", ContactBusinessRelation."Link to Table"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelCreateRelation_ForCustomer()
    var
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactCompanyNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] UT ContactBusinessRelation.CreateRelation for Customer side
        Initialize();

        CreateCustomerWithSetupBusinessRelation(Customer);
        ContactCompanyNo := LibraryMarketing.CreateCompanyContactNo();

        ContactBusinessRelation.CreateRelation(ContactCompanyNo, Customer."No.", ContactBusinessRelation."Link to Table"::Customer);

        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactCompanyNo, Customer."No.", ContactBusinessRelation."Link to Table"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelCreateRelation_WithNoBusRelCodeSetupForVendor()
    var
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactCompanyNo: Code[20];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] UT ContactBusinessRelation.CreateRelation for Vendor side when MarketingSetup."Bus. Rel. Code for Vendors" is empty.
        Initialize();

        CreateVendorWithSetupBusinessRelation(Vendor);
        ContactCompanyNo := LibraryMarketing.CreateCompanyContactNo();

        ChangeBusinessRelationCodeForVendors('');
        asserterror
          ContactBusinessRelation.CreateRelation(
            ContactCompanyNo, Vendor."No.", ContactBusinessRelation."Link to Table"::Vendor);

        Assert.ExpectedError('Bus. Rel. Code for Vendors must have a value in Marketing Setup');
        VerifyNoContactBusinessRelationForLinkTableAndContact(
          ContactCompanyNo, Vendor."No.", ContactBusinessRelation."Link to Table"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelCreateRelation_WithNoBusRelCodeSetupForCustomer()
    var
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactCompanyNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] UT ContactBusinessRelation.CreateRelation for Customer side when MarketingSetup."Bus. Rel. Code for Customers" is empty.
        Initialize();

        CreateCustomerWithSetupBusinessRelation(Customer);
        ContactCompanyNo := LibraryMarketing.CreateCompanyContactNo();

        ChangeBusinessRelationCodeForCustomers('');
        asserterror
          ContactBusinessRelation.CreateRelation(
            ContactCompanyNo, Customer."No.", ContactBusinessRelation."Link to Table"::Customer);

        Assert.ExpectedError('Bus. Rel. Code for Customers must have a value in Marketing Setup');
        VerifyNoContactBusinessRelationForLinkTableAndContact(
          ContactCompanyNo, Customer."No.", ContactBusinessRelation."Link to Table"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelFindOrRestoreContactBusinessRelation_FindForVendor()
    var
        Vendor: Record Vendor;
        ContactPerson: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] UT ContactBusinessRelation.FindOrRestoreContactBusinessRelation for Vendor, find existing ContactBusinessRelation record by relation.
        Initialize();

        CreateVendorWithContactPerson(Vendor, ContactPerson, ContactBusinessRelation);

        ContactBusinessRelation.FindOrRestoreContactBusinessRelation(
          ContactPerson, Vendor, ContactBusinessRelation."Link to Table"::Vendor);

        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactPerson."Company No.", Vendor."No.", ContactBusinessRelation."Link to Table"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelFindOrRestoreContactBusinessRelation_FindForCustomer()
    var
        Customer: Record Customer;
        ContactPerson: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] UT ContactBusinessRelation.FindOrRestoreContactBusinessRelation for Customer, find existing ContactBusinessRelation record by relation.
        Initialize();

        CreateCustomerWithContactPerson(Customer, ContactPerson, ContactBusinessRelation);

        ContactBusinessRelation.FindOrRestoreContactBusinessRelation(
          ContactPerson, Customer, ContactBusinessRelation."Link to Table"::Customer);

        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactPerson."Company No.", Customer."No.", ContactBusinessRelation."Link to Table"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelFindOrRestoreContactBusinessRelation_RestoreForStandaloneContactForVendor()
    var
        Vendor: Record Vendor;
        ContactPerson: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] UT ContactBusinessRelation.FindOrRestoreContactBusinessRelation for Vendor, create ContactBusinessRelation for Contact without "Company No." link.
        Initialize();

        CreateVendorWithSetupBusinessRelation(Vendor);
        LibraryMarketing.CreatePersonContact(ContactPerson);

        ContactBusinessRelation.FindOrRestoreContactBusinessRelation(
          ContactPerson, Vendor, ContactBusinessRelation."Link to Table"::Vendor);

        ContactPerson.Find();
        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactPerson."Company No.", Vendor."No.", ContactBusinessRelation."Link to Table"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelFindOrRestoreContactBusinessRelation_RestoreForStandaloneContactForCustomer()
    var
        Customer: Record Customer;
        ContactPerson: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] UT ContactBusinessRelation.FindOrRestoreContactBusinessRelation for Customer, create ContactBusinessRelation for Contact without "Company No." link.
        Initialize();

        CreateCustomerWithSetupBusinessRelation(Customer);
        LibraryMarketing.CreatePersonContact(ContactPerson);

        ContactBusinessRelation.FindOrRestoreContactBusinessRelation(
          ContactPerson, Customer, ContactBusinessRelation."Link to Table"::Customer);

        ContactPerson.Find();
        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactPerson."Company No.", Customer."No.", ContactBusinessRelation."Link to Table"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelFindOrRestoreContactBusinessRelation_RestoreForContactWithCompanyForVendor()
    var
        Vendor: Record Vendor;
        ContactPerson: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] UT ContactBusinessRelation.FindOrRestoreContactBusinessRelation for Vendor, create ContactBusinessRelation for Contact with "Company No." link.
        Initialize();

        CreateVendorWithContactPerson(Vendor, ContactPerson, ContactBusinessRelation);
        ContactBusinessRelation.Delete();

        ContactBusinessRelation.FindOrRestoreContactBusinessRelation(
          ContactPerson, Vendor, ContactBusinessRelation."Link to Table"::Vendor);

        ContactPerson.Find();
        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactPerson."Company No.", Vendor."No.", ContactBusinessRelation."Link to Table"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelFindOrRestoreContactBusinessRelation_RestoreForContactWithCompanyForCustomer()
    var
        Customer: Record Customer;
        ContactPerson: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] UT ContactBusinessRelation.FindOrRestoreContactBusinessRelation for Customer, create ContactBusinessRelation for Contact with "Company No." link.
        Initialize();

        CreateCustomerWithContactPerson(Customer, ContactPerson, ContactBusinessRelation);
        ContactBusinessRelation.Delete();

        ContactBusinessRelation.FindOrRestoreContactBusinessRelation(
          ContactPerson, Customer, ContactBusinessRelation."Link to Table"::Customer);

        ContactPerson.Find();
        VerifyContactBusinessRelationForLinkTableAndContact(
          ContactPerson."Company No.", Customer."No.", ContactBusinessRelation."Link to Table"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelFindOrRestoreContactBusinessRelation_ForContactWithCompanyTypeForVendor()
    var
        Vendor: Record Vendor;
        ContactCompany: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 257273] UT ContactBusinessRelation.FindOrRestoreContactBusinessRelation for Vendor, Contact with Type::Company is not validated.
        Initialize();

        LibraryMarketing.CreateCompanyContact(ContactCompany);
        CreateVendorWithSetupBusinessRelation(Vendor);

        ContactBusinessRelation.FindOrRestoreContactBusinessRelation(
          ContactCompany, Vendor, ContactBusinessRelation."Link to Table"::Vendor);

        Vendor.Find();
        Vendor.TestField(Contact, '');
        Assert.AreNotEqual(Vendor.Contact, ContactCompany.Name, 'Contact with Type::Company must not be validated for Vendor');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRelFindOrRestoreContactBusinessRelation_ForContactWithCompanyTypeForCustomer()
    var
        Customer: Record Customer;
        ContactCompany: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 257273] UT ContactBusinessRelation.FindOrRestoreContactBusinessRelation for Customer, Contact with Type::Company is not validated.
        Initialize();

        LibraryMarketing.CreateCompanyContact(ContactCompany);
        CreateCustomerWithSetupBusinessRelation(Customer);

        ContactBusinessRelation.FindOrRestoreContactBusinessRelation(
          ContactCompany, Customer, ContactBusinessRelation."Link to Table"::Customer);

        Customer.Find();
        Customer.TestField(Contact, '');
        Assert.AreNotEqual(Customer.Contact, ContactCompany.Name, 'Contact with Type::Company must not be validated for Customer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateContsFromCustomersDoNotCreatePersonContactForCustWithBlankContact()
    var
        Customer: Record Customer;
        ContactType: Enum "Contact Type";
    begin
        // [FEATURE] [Create Contacts from Customers]
        // [SCENARIO 287705] Report "Create Contacts from Customers" doesn't create Person Contact in case Customer has <blank> Contact field
        Initialize();

        // [GIVEN] Customer with <blank> Contact field and no contacts created using Data Migration,
        Customer.SetInsertFromContact(true);  // avoid creation of Contact in OnInsert trigger
        Customer.Contact := '';
        Customer.Insert(true);
        Customer.SetRange("No.", Customer."No.");

        // [WHEN] Run report Create Contact for Customers
        RunCreateContsFromCustomersReport(Customer);

        // [THEN] Company Contact is created for Customer
        // [THEN] Customer has Primary Contact No. = Company Contact No.
        Customer.Find();
        VerifyContact(Customer."Primary Contact No.", ContactType::Company, '', '');

        // [THEN] Person Contact is not created for Company Contact
        VerifyContactNotExistWithCompanyNo(Customer."Primary Contact No.", ContactType::Person);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateContsFromVendorsDoNotCreatePersonContactForVendWithBlankContact()
    var
        Vendor: Record Vendor;
        ContactType: Enum "Contact Type";
    begin
        // [FEATURE] [Create Contacts from Vendors]
        // [SCENARIO 287705] Report "Create Contacts from Vendors" doesn't create Person Contact in case Vendor has <blank> Contact field
        Initialize();

        // [GIVEN] Vendor with <blank> Contact field and no contacts created using Data Migration,
        Vendor.SetInsertFromContact(true);  // avoid creation of Contact in OnInsert trigger
        Vendor.Contact := '';
        Vendor.Insert(true);
        Vendor.SetRange("No.", Vendor."No.");

        // [WHEN] Run report Create Contact for Vendors
        RunCreateContsFromVendorsReport(Vendor);

        // [THEN] Company Contact is created for Vendor
        // [THEN] Vendor has Primary Contact No. = Company Contact No.
        Vendor.Find();
        VerifyContact(Vendor."Primary Contact No.", ContactType::Company, '', '');

        // [THEN] Person Contact is not created for Company Contact
        VerifyContactNotExistWithCompanyNo(Vendor."Primary Contact No.", ContactType::Person);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRel_UpdateEmptyNoForCustomerPrimaryContact()
    var
        PersonContact: Record Contact;
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Customer] [Contact Business Relation]
        // [SCENARIO 309527] ContactBusinessRelations with a blank "No." is populated with Customer No. when the Customer is inserted
        Initialize();

        // [GIVEN] Person Contact created
        LibraryMarketing.CreatePersonContact(PersonContact);

        // [GIVEN] Customer is initialized and "Primary Contact No." validated
        Customer.Init();
        Customer.Validate("Primary Contact No.", PersonContact."No.");

        // [GIVEN] Company Contact created for initialized Customer with Company Contact and with Contact Business Relations with blank "No."
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, '');

        // [WHEN] Customer record is inserted
        Customer.Insert(true);

        // [THEN] Contact Business Relation "No." has been updated with Customer "No."
        Assert.IsTrue(
          ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Customer."No."),
          ExpectedToFindRecErr);

        // [THEN] There are no Contact Business Relation entries with blank "No."
        VerifyContactBusinessRelationHasNoBlankValue(ContactBusinessRelation."Link to Table"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ContBusRel_UpdateEmptyNoForVendorPrimaryContact()
    var
        PersonContact: Record Contact;
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Vendor] [Contact Business Relation]
        // [SCENARIO 309527] ContactBusinessRelations with a blank "No." is populated with Vendor No. when the Vendor is inserted
        Initialize();

        // [GIVEN] Person Contact created
        LibraryMarketing.CreatePersonContact(PersonContact);

        // [GIVEN] Vendor is initialized and "Primary Contact No." validated
        Vendor.Init();
        Vendor.Validate("Primary Contact No.", PersonContact."No.");

        // [GIVEN] Company Contact created for initialized Vendor with Company Contact and with Contact Business Relations with blank "No."
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Vendor, '');

        // [WHEN] Vendor record is inserted
        Vendor.Insert(true);

        // [THEN] Contact Business Relation "No." has been updated with Vendor "No."
        Assert.IsTrue(
          ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Vendor, Vendor."No."),
          ExpectedToFindRecErr);

        // [THEN] There are no Contact Business Relation entries with blank "No."
        VerifyContactBusinessRelationHasNoBlankValue(ContactBusinessRelation."Link to Table"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_UpdateEmptyNoForContact_NoEntity()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Contact Business Relation]
        Initialize();

        Assert.IsFalse(
          ContactBusinessRelation.UpdateEmptyNoForContact(
            '', LibraryUtility.GenerateGUID(), ContactBusinessRelation."Link to Table"::Customer),
          WrongValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_UpdateEmptyNoForContact_NoContact()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Contact Business Relation]
        Initialize();

        Assert.IsFalse(
          ContactBusinessRelation.UpdateEmptyNoForContact(
            LibraryUtility.GenerateGUID(), '', ContactBusinessRelation."Link to Table"::Customer),
          WrongValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_UpdateEmptyNoForContact_NoPersonContact()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Contact Business Relation]
        Initialize();

        Assert.IsFalse(
          ContactBusinessRelation.UpdateEmptyNoForContact(
            LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), ContactBusinessRelation."Link to Table"::Customer),
          WrongValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_UpdateEmptyNoForContact_NoCompanyContact()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Contact Business Relation]
        Initialize();

        Assert.IsFalse(
          ContactBusinessRelation.UpdateEmptyNoForContact(
            LibraryUtility.GenerateGUID(), LibraryMarketing.CreatePersonContactNo(), ContactBusinessRelation."Link to Table"::Customer),
          WrongValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_UpdateEmptyNoForContact_NotFoundByCompanyContact()
    var
        PersonContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Contact Business Relation]
        Initialize();

        LibraryMarketing.CreatePersonContactWithCompanyNo(PersonContact);

        Assert.IsFalse(
          ContactBusinessRelation.UpdateEmptyNoForContact(
            LibraryUtility.GenerateGUID(), PersonContact."No.", ContactBusinessRelation."Link to Table"::Customer),
          WrongValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_UpdateEmptyNoForContact_IsNotBlankNo()
    var
        PersonContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Contact Business Relation]
        Initialize();

        LibraryMarketing.CreatePersonContactWithCompanyNo(PersonContact);
        LibraryMarketing.CreateContactBusinessRelation(
          ContactBusinessRelation, PersonContact."Company No.",
          GetBusinessRelationCodeFromSetup(ContactBusinessRelation."Link to Table"::Customer));
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Customer;
        ContactBusinessRelation."No." := LibrarySales.CreateCustomerNo();
        ContactBusinessRelation.Modify();

        Assert.IsFalse(
          ContactBusinessRelation.UpdateEmptyNoForContact(
            LibraryUtility.GenerateGUID(), PersonContact."No.", ContactBusinessRelation."Link to Table"::Customer),
          WrongValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_UpdateEmptyNoForContact_BlankNo()
    var
        Customer: Record Customer;
        PersonContact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [UT] [Contact Business Relation]
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryMarketing.CreatePersonContactWithCompanyNo(PersonContact);
        LibraryMarketing.CreateContactBusinessRelation(
          ContactBusinessRelation, PersonContact."Company No.",
          GetBusinessRelationCodeFromSetup(ContactBusinessRelation."Link to Table"::Customer));
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Customer;
        ContactBusinessRelation.Modify();

        Assert.IsTrue(
          ContactBusinessRelation.UpdateEmptyNoForContact(
            Customer."No.", PersonContact."No.", ContactBusinessRelation."Link to Table"::Customer),
          WrongValueErr);

        ContactBusinessRelation.Find();
        ContactBusinessRelation.TestField("No.", Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ContactListLookupModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_ContactCard_CompanyName_Lookup()
    var
        ContactCompany: Record Contact;
        ContactPerson: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 345031] Stan can select Contact with type "Company" via lookup of "Company Name" field. "Company No." is validated after selection.
        Initialize();

        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryMarketing.CreatePersonContact(ContactPerson);

        ContactCompany.TestField(Name);
        ContactPerson.TestField("Company No.", '');
        ContactPerson.TestField("Company Name", '');

        LibraryVariableStorage.Enqueue(ContactCompany."No.");

        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", ContactPerson."No.");
        ContactCard."Company No.".AssertEquals('');
        ContactCard."Company Name".AssertEquals('');
        ContactCard."Company Name".Lookup();
        ContactCard.Close();

        ContactPerson.Find();
        ContactPerson.TestField("Company No.", ContactCompany."No.");
        ContactPerson.TestField("Company Name", ContactCompany.Name);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_Contact_CompanyName_Relation()
    var
        Contact: Record Contact;
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 345031] Contact."Company Name" field's relation is Contact.Name
        Initialize();

        TableRelationsMetadata.SetRange("Table ID", DATABASE::Contact);
        TableRelationsMetadata.SetRange("Field No.", Contact.FieldNo("Company Name"));
        TableRelationsMetadata.FindFirst();
        TableRelationsMetadata.TestField("Related Table ID", DATABASE::Contact);
        TableRelationsMetadata.TestField("Related Field No.", Contact.FieldNo(Name));
        TableRelationsMetadata.TestField("Condition Type", TableRelationsMetadata."Condition Type"::CONST);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateContactMobilePhoneNoFromCustomer()
    var
        Customer: Record Customer;
        PersonContact: Record Contact;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO 365063] Contact."Mobile Phone No." field updated when "Mobile Phone No." is changed on related customer
        Initialize();

        // [GIVEN] Customer "C" with Contact "CONT"
        CreateCustomerWithSetupBusinessRelation(Customer);
        LibraryMarketing.CreatePersonContactWithCompanyNo(PersonContact);
        Customer.Validate("Primary Contact No.", PersonContact."No.");
        Customer.Modify();

        // [WHEN] Customer "C" mobile phone number is being changed to "111" in the customer card page
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer."No.");
        CustomerCard.MobilePhoneNo.SetValue(CopyStr(LibraryUtility.GenerateRandomNumericText(20), 1, MaxStrLen(Customer."Mobile Phone No.")));
        CustomerCard.OK().Invoke();

        // [THEN] Contact "CONT" has same phone number "111"
        PersonContact.Find();
        Customer.Find();
        PersonContact.TestField("Mobile Phone No.", Customer."Mobile Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateContactMobilePhoneNoFromVendor()
    var
        Vendor: Record Vendor;
        PersonContact: Record Contact;
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Vendor] [UI]
        // [SCENARIO 365063] Contact."Mobile Phone No." field updated when "Mobile Phone No." is changed on related vendor
        Initialize();

        // [GIVEN] Vendor "V" with Contact "CONT"
        CreateVendorWithSetupBusinessRelation(Vendor);
        LibraryMarketing.CreatePersonContactWithCompanyNo(PersonContact);
        Vendor.Validate("Primary Contact No.", PersonContact."No.");
        Vendor.Modify();

        // [WHEN] Vendor "V" mobile phone number is being changed to "111" in the vendor card page
        VendorCard.OpenEdit();
        VendorCard.Filter.SetFilter("No.", Vendor."No.");
        VendorCard.MobilePhoneNo.SetValue(CopyStr(LibraryUtility.GenerateRandomNumericText(20), 1, MaxStrLen(Vendor."Mobile Phone No.")));
        VendorCard.OK().Invoke();

        // [THEN] Contact "CONT" has same phone number "111"
        PersonContact.Find();
        Vendor.Find();
        PersonContact.TestField("Mobile Phone No.", Vendor."Mobile Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateContactMobilePhoneNoFromBankAccount()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        BankAccountCard: TestPage "Bank Account Card";
    begin
        // [FEATURE] [Bank Account] [UI]
        // [SCENARIO 365063] Contact."Mobile Phone No." field updated when "Mobile Phone No." is changed on related bank account
        Initialize();

        // [GIVEN] BankAccount "B" with Contact "CONT"
        CreateBankAccountWithSetupBusinessRelation(BankAccount, Contact);

        // [WHEN] Bank account "B" mobile phone number is being changed to "111" in the bank account card page
        BankAccountCard.OpenEdit();
        BankAccountCard.Filter.SetFilter("No.", BankAccount."No.");
        BankAccountCard.MobilePhoneNo.SetValue(CopyStr(LibraryUtility.GenerateRandomNumericText(20), 1, MaxStrLen(BankAccount."Mobile Phone No.")));
        BankAccountCard.OK().Invoke();

        // [THEN] Contact "CONT" has same phone number "111"
        Contact.Find();
        BankAccount.Find();
        Contact.TestField("Mobile Phone No.", BankAccount."Mobile Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastModifiedDateTimeValidatedCorrectlyInCustomerTableWhenTheNameOfRelatedContactChanged()
    var
        ContactCompany: Record Contact;
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactCard: TestPage "Contact Card";
        LastModifiedDateTime: DateTime;
    begin
        // [SCENARIO 371001] "Last Modified Date Time" in table Customer updated when the Name in related Contact was changed
        Initialize();

        // [GIVEN] Created Contact with type Company and Customer related to it
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibrarySales.CreateCustomer(Customer);
        LibraryMarketing.CreateBusinessRelationBetweenContactAndCustomer(ContactBusinessRelation, ContactCompany."No.", Customer."No.");

        // [GIVEN] Update "Last Modified Date Time" and "Last Date Modified"
        Customer."Last Modified Date Time" := CreateDateTime(WorkDate() - 1, 0T);
        Customer."Last Date Modified" := WorkDate() - 1;
        Customer.Modify();

        // [GIVEN] Memorize of the "Last Modified Date Time"
        LastModifiedDateTime := Customer."Last Modified Date Time";

        // [WHEN] Change the Name of Contact usin ContactCard
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", ContactCompany."No.");
        ContactCard.First();
        ContactCard.Name.SetValue(LibraryRandom.RandText(20));
        ContactCard.Close();
        Customer.Get(Customer."No.");

        // [THEN] The "Last Modified Date Time" and "Last Date Modified" were changed
        Assert.AreNotEqual(Customer."Last Modified Date Time", LastModifiedDateTime, '');
        Assert.AreNotEqual(Customer."Last Date Modified", DT2Date(LastModifiedDateTime), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastModifiedDateTimeValidatedCorrectlyInVendorTableWhenTheNameOfRelatedContactChanged()
    var
        ContactCompany: Record Contact;
        Vendor: Record Vendor;
        ContactCard: TestPage "Contact Card";
        LastModifiedDateTime: DateTime;
    begin
        // [SCENARIO 371001] "Last Modified Date Time" in table Vendor updated when the Name in related Contact was changed
        Initialize();

        // [GIVEN] Created Contact with type Company and Vendor related to it
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryPurchase.CreateVendor(Vendor);
        CreateBusinessRelationBetweenContactAndVendor(ContactCompany."No.", Vendor."No.");

        // [GIVEN] Update "Last Modified Date Time" and "Last Date Modified"
        Vendor."Last Modified Date Time" := CreateDateTime(WorkDate() - 1, 0T);
        Vendor."Last Date Modified" := WorkDate() - 1;
        Vendor.Modify();

        // [GIVEN] Memorize of the "Last Modified Date Time"
        LastModifiedDateTime := Vendor."Last Modified Date Time";

        // [WHEN] Change the Name of Contact usin ContactCard
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", ContactCompany."No.");
        ContactCard.First();
        ContactCard.Name.SetValue(LibraryRandom.RandText(20));
        ContactCard.Close();
        Vendor.Get(Vendor."No.");

        // [THEN] The "Last Modified Date Time" and "Last Date Modified" were changed
        Assert.AreNotEqual(Vendor."Last Modified Date Time", LastModifiedDateTime, '');
        Assert.AreNotEqual(Vendor."Last Date Modified", DT2Date(LastModifiedDateTime), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastModifiedDateTimeValidatedCorrectlyInBankAccountTableWhenTheNameOfRelatedContactChanged()
    var
        ContactCompany: Record Contact;
        BankAccount: Record "Bank Account";
        ContactCard: TestPage "Contact Card";
        LastModifiedDate: Date;
    begin
        // [SCENARIO 371001] "Last Modified Date Time" in table Bank Account updated when the Name in related Contact was changed
        Initialize();

        // [GIVEN] Created Contact with type Company and Bank Account related to it
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryERM.CreateBankAccount(BankAccount);
        CreateBusinessRelationBetweenContactAndBankAccount(ContactCompany."No.", BankAccount."No.");

        // [GIVEN] Update "Last Modified Date Time" and "Last Date Modified"
        BankAccount."Last Date Modified" := WorkDate() - 1;
        BankAccount.Modify();

        // [GIVEN] Memorize of the "Last Modified Date Time"
        LastModifiedDate := BankAccount."Last Date Modified";

        // [WHEN] Change the Name of Contact usin ContactCard
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", ContactCompany."No.");
        ContactCard.First();
        ContactCard.Name.SetValue(LibraryRandom.RandText(20));
        ContactCard.Close();
        BankAccount.Get(BankAccount."No.");

        // [THEN] The "Last Date Modified" was changed
        Assert.AreNotEqual(BankAccount."Last Date Modified", LastModifiedDate, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastModifiedDateTimeValidatedCorrectlyInEmployeeTableWhenTheNameOfRelatedContactChanged()
    var
        ContactCompany: Record Contact;
        Employee: Record Employee;
        ContactCard: TestPage "Contact Card";
        LastModifiedDateTime: DateTime;
    begin
        // [SCENARIO 371001] "Last Modified Date Time" in table Employee updated when the Name in related Contact was changed
        Initialize();

        // [GIVEN] Created Contact with type Company and Employee related to it
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryHumanResource.CreateEmployee(Employee);
        CreateBusinessRelationBetweenContactAndEmployee(ContactCompany."No.", Employee."No.");

        // [GIVEN] Update "Last Modified Date Time" and "Last Date Modified"
        Employee."Last Modified Date Time" := CreateDateTime(WorkDate() - 1, 0T);
        Employee."Last Date Modified" := WorkDate() - 1;
        Employee.Modify();

        // [GIVEN] Memorize of the "Last Modified Date Time"
        LastModifiedDateTime := Employee."Last Modified Date Time";

        // [WHEN] Change the Name of Contact usin ContactCard
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", ContactCompany."No.");
        ContactCard.First();
        ContactCard.Name.SetValue(LibraryRandom.RandText(20));
        ContactCard.Close();
        Employee.Get(Employee."No.");

        // [THEN] The "Last Modified Date Time" and "Last Date Modified" were changed
        Assert.AreNotEqual(Employee."Last Modified Date Time", LastModifiedDateTime, '');
        Assert.AreNotEqual(Employee."Last Date Modified", DT2Date(LastModifiedDateTime), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportContactShouldOnlyBeEnabledWhenContactSelected()
    var
        Contact: Record Contact;
        ContactList: TestPage "Contact List";
    begin
        // [SCENARIO] The Export Contact action should only be enabled if a contact is selected in the contact list.
        Initialize();
        Contact.Init();
        Contact.DeleteAll();

        // [GIVEN] An empty contact list.
        ContactList.OpenEdit();

        // [THEN] Export contact action is disabled.
        Assert.IsFalse(ContactList."Export Contact".Enabled(), 'Expected Export Contact action to be disabled.');
        ContactList.Close();

        // [GIVEN] A non-empty contact list with a selected contact.
        LibraryMarketing.CreateCompanyContact(Contact);
        ContactList.OpenEdit();

        // [THEN] Export contact action is enabled.
        Assert.IsTrue(ContactList."Export Contact".Enabled(), 'Expected Export Contact action to be enabled.');
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCustomerForPersonContactWithCompanyContactWithoutCustomer()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Customer: Record Customer;
        CustomerTemplate: Record "Customer Templ.";
    begin
        // [SCENARIO 383926] Contact function CreateCusomer creates Customer for Person's Company Contact.
        Initialize();

        // [GIVEN] Company Contact with No. = "Company" not linked to any Customer.
        // [GIVEN] Person Contact with Company No. = "Company".
        LibraryMarketing.CreatePersonContactWithCompanyNo(Contact);

        // [WHEN] CreateCustomer is called for Person Contact.
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        Contact.SetHideValidationDialog(true);
        Contact.CreateCustomerFromTemplate(CustomerTemplate.Code);

        // [THEN] Customer is created and linked to Company Contact.
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("Contact No.", Contact."Company No.");
        ContBusRel.FindFirst();
        Customer.Get(ContBusRel."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorForPersonContactWithCompanyContactWithVendor()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 383926] Contact function CreateVendor throws error when trying to create Customer for Person Contact with Company having Customer.
        Initialize();

        // [GIVEN] Company Contact with No. = "Company" linked to Customer.
        // [GIVEN] Person Contact with Company No. = "Company".
        CreateVendorWithContactPerson(Vendor, Contact, ContBusRel);

        // [WHEN] CreateVendor is called for Person Contact.
        Contact.SetHideValidationDialog(true);
        asserterror Contact.CreateVendorFromTemplate('');

        // [THEN] Error about relation already existing between Company Contact and Vendor.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
            StrSubstNo(RelationAlreadyExistWithVendorErr, ContBusRel."Contact No.", ContBusRel.TableCaption(), Vendor."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorForPersonContactWithCompanyContactWithoutVendor()
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 383926] Contact function CreateVendor creates Vendor for Person's Company Contact.
        Initialize();

        // [GIVEN] Company Contact with No. = "Company" not linked to any Vendor.
        // [GIVEN] Person Contact with Company No. = "Company".
        LibraryMarketing.CreatePersonContactWithCompanyNo(Contact);

        // [WHEN] CreateVendor is called for Person Contact.
        Contact.SetHideValidationDialog(true);
        Contact.CreateVendorFromTemplate('');

        // [THEN] Vendor is created and linked to Company Contact.
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
        ContBusRel.SetRange("Contact No.", Contact."Company No.");
        ContBusRel.FindFirst();
        Vendor.Get(ContBusRel."No.");
    end;

    [Test]
    [HandlerFunctions('ModalSelectCustomerTemplListHandler')]
    procedure T200_ContactLinkedWithCustomerHasBusinessRelationCustomer()
    var
        ContactCompany: Record Contact;
        MarketingContacts: Codeunit "Marketing Contacts";
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO 383899] Contact linked with customer has "Business Relation" 'Customer'
        Initialize();
        BindSubscription(MarketingContacts); // to subscribe OnAfterIsEnabledCustTemplate

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        // [WHEN] Link the contact with the customer
        ContactCompany.SetHideValidationDialog(true);
        ContactCompany.CreateCustomer();

        // [THEN] "Business Relation" is 'Customer'
        ContactCompany.Find();
        ContactCompany.TestField("Contact Business Relation", "Contact Business Relation"::Customer);
    end;

    [Test]
    procedure T201_ContactLinkedWithVendorHasBusinessRelationVendor()
    var
        ContactCompany: Record Contact;
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO 383899] Contact linked with Vendor has "Business Relation" 'Vendor'
        Initialize();

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        // [WHEN] Link the contact with the Vendor
        ContactCompany.SetHideValidationDialog(true);
        ContactCompany.CreateVendorFromTemplate('');

        // [WHEN] "Business Relation" is 'Vendor'
        ContactCompany.Find();
        ContactCompany.TestField("Contact Business Relation", "Contact Business Relation"::Vendor);
    end;

    [Test]
    procedure T202_ContactLinkedWithBankHasBusinessRelationBank()
    var
        ContactCompany: Record Contact;
        MarketingContacts: Codeunit "Marketing Contacts";
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO 383899] Contact linked with Vendor has "Business Relation" 'Bank Account'
        Initialize();
        BindSubscription(MarketingContacts); // to subscribe OnAfterIsEnabledCustTemplate

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        // [WHEN] Link the contact with the Bank Account
        ContactCompany.SetHideValidationDialog(true);
        ContactCompany.CreateBankAccount();

        // [WHEN] "Business Relation" is 'Bank Account'
        ContactCompany.Find();
        ContactCompany.TestField("Contact Business Relation", "Contact Business Relation"::"Bank Account");
    end;

    [Test]
    [HandlerFunctions('ModalSelectCustomerTemplListHandler')]
    procedure T203_ContactLinkedWithCustomerandVendorHasBusinessRelationMultiple()
    var
        ContactCompany: Record Contact;
        MarketingContacts: Codeunit "Marketing Contacts";
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO 383899] Contact linked with customer and vendor has "Business Relation" 'Multiple'
        Initialize();
        BindSubscription(MarketingContacts); // to subscribe OnAfterIsEnabledCustTemplate

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        // [WHEN] Link the contact with the customer and the vendor
        ContactCompany.SetHideValidationDialog(true);
        ContactCompany.CreateCustomer();
        ContactCompany.CreateVendorFromTemplate('');

        // [WHEN] "Business Relation" is 'Multiple'
        ContactCompany.Find();
        ContactCompany.TestField("Contact Business Relation", "Contact Business Relation"::Multiple);
    end;

    [Test]
    [HandlerFunctions('ModalSelectCustomerTemplListHandler')]
    procedure T204_ContactLinkedWithAlternateCustomerandVendorHasBusinessRelationMultiple()
    var
        ContactCompany: Record Contact;
        MarketingContacts: Codeunit "Marketing Contacts";
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO 383899] Contact linked with customer (alternate code) and vendor has "Business Relation" 'Multiple'
        Initialize();
        BindSubscription(MarketingContacts); // to subscribe OnAfterIsEnabledCustTemplate

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        // [WHEN] Link the contact with the customer and the vendor
        ContactCompany.SetHideValidationDialog(true);
        ContactCompany.CreateCustomer();
        ReplaceBusRelationCode(ContactCompany."No.");
        ContactCompany.CreateVendorFromTemplate('');

        // [WHEN] "Business Relation" is 'Multiple'
        ContactCompany.Find();
        ContactCompany.TestField("Contact Business Relation", "Contact Business Relation"::Multiple);
    end;

    [Test]
    procedure T205_ContactLinkedWithBankWithAlternateCodeHasBusinessRelationOther()
    var
        ContactCompany: Record Contact;
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO 383899] Contact linked with bank using  alternate relation code has "Business Relation" 'Other'
        Initialize();

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        LibraryERM.CreateBankAccount(BankAccount);

        // [WHEN] Link the contact with the bank using relation code 'X' (not 'BANK' from Marketing Setup)
        CreateBusinessRelationBetweenContactAndBankAccount(ContactCompany."No.", BankAccount."No.");

        // [THEN] "Business Relation" is 'Other'
        ContactCompany.Find();
        ContactCompany.TestField("Contact Business Relation", "Contact Business Relation"::Other);
    end;

    [Test]
    procedure T206_ContactWithoutRelationsHasBusinessRelationNone()
    var
        ContactCompany: Record Contact;
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO 383899] Contact without relations has "Business Relation" 'None'
        Initialize();

        // [WHEN] Created Contact with type Company, has no business relations
        LibraryMarketing.CreateCompanyContact(ContactCompany);

        // [THEN] "Business Relation" is 'None'
        ContactCompany.TestField("Contact Business Relation", "Contact Business Relation"::None);
    end;

    [Test]
    [HandlerFunctions('ModalSelectCustomerTemplListHandler')]
    procedure T210_ContactCardLinkedWithCustomerOpensCustomerCard()
    var
        ContactCompany: Record Contact;
        MarketingContacts: Codeunit "Marketing Contacts";
        ContactCard: TestPage "Contact Card";
        CustomerCard: TestPage "Customer Card";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Business Relation] [UI]
        // [SCENARIO 383899] Contact linked with customer opens Customer Card on "Business Relation" assist edit.
        Initialize();
        BindSubscription(MarketingContacts); // to subscribe OnAfterIsEnabledCustTemplate

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        // [GIVEN] Link the contact with the customer 'X'
        ContactCompany.SetHideValidationDialog(true);
        CustomerNo := ContactCompany.CreateCustomer();

        // [GIVEN] Open Contact card
        ContactCard.OpenView();
        ContactCard.Filter.SetFilter("No.", ContactCompany."No.");

        // [WHEN] Assit edit on "Business Relation"
        CustomerCard.Trap();
        ContactCard."Contact Business Relation".DrillDown();
        // [THEN] Customer Card is open on customer 'X'
        CustomerCard."No.".AssertEquals(CustomerNo);
        CustomerCard.Close();

        // [THEN] "No. of Business Relations" in the factbox is 1
        ContactCard.Control31."No. of Business Relations".AssertEquals(1);
        // [WHEN] Drilldown on "No. of Business Relations"
        CustomerCard.Trap();
        ContactCard.Control31."No. of Business Relations".Drilldown();
        // [THEN] Customer Card is open on Customer 'X'
        CustomerCard."No.".AssertEquals(CustomerNo);
        CustomerCard.Close();
    end;

    [Test]
    procedure T211_ContactCardLinkedWithVendorOpensVendorCard()
    var
        ContactCompany: Record Contact;
        ContactCard: TestPage "Contact Card";
        VendorCard: TestPage "Vendor Card";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Business Relation] [UI]
        // [SCENARIO 383899] Contact linked with Vendor opens Vendor Card on "Business Relation" assist edit.
        Initialize();

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        // [GIVEN] Link the contact with the Vendor 'X'
        ContactCompany.SetHideValidationDialog(true);
        VendorNo := ContactCompany.CreateVendorFromTemplate('');

        // [GIVEN] Open Contact card
        ContactCard.OpenView();
        ContactCard.Filter.SetFilter("No.", ContactCompany."No.");

        // [WHEN] Assit edit on "Business Relation"
        VendorCard.Trap();
        ContactCard."Contact Business Relation".DrillDown();
        // [THEN] Vendor Card is open on Vendor 'X'
        VendorCard."No.".AssertEquals(VendorNo);
        VendorCard.Close();

        // [THEN] "No. of Business Relations" in the factbox is 1
        ContactCard.Control31."No. of Business Relations".AssertEquals(1);
        // [WHEN] Drilldown on "No. of Business Relations"
        VendorCard.Trap();
        ContactCard.Control31."No. of Business Relations".Drilldown();
        // [THEN] Vendor Card is open on Vendor 'X'
        VendorCard."No.".AssertEquals(VendorNo);
        VendorCard.Close();
    end;

    [Test]
    procedure T212_ContactCardLinkedWithBankAccountOpensBankAccountCard()
    var
        ContactCompany: Record Contact;
        ContactCard: TestPage "Contact Card";
        BankAccountCard: TestPage "Bank Account Card";
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Business Relation] [UI]
        // [SCENARIO 383899] Contact linked with Bank Account opens Bank Account Card on "Business Relation" assist edit.
        Initialize();

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        // [GIVEN] Link the contact with the Bank Account 'X'
        ContactCompany.SetHideValidationDialog(true);
        BankAccountNo := ContactCompany.CreateBankAccount();

        // [GIVEN] Open Contact card
        ContactCard.OpenView();
        ContactCard.Filter.SetFilter("No.", ContactCompany."No.");

        // [WHEN] Assit edit on "Business Relation"
        BankAccountCard.Trap();
        ContactCard."Contact Business Relation".DrillDown();
        // [THEN] Bank Account Card is open on Bank Account 'X'
        BankAccountCard."No.".AssertEquals(BankAccountNo);
        BankAccountCard.Close();

        // [THEN] "No. of Business Relations" in the factbox is 1
        ContactCard.Control31."No. of Business Relations".AssertEquals(1);
        // [WHEN] Drilldown on "No. of Business Relations"
        BankAccountCard.Trap();
        ContactCard.Control31."No. of Business Relations".Drilldown();
        // [THEN] Bank Account Card is open on Bank Account 'X'
        BankAccountCard."No.".AssertEquals(BankAccountNo);
        BankAccountCard.Close();
    end;

    [Test]
    procedure T213_ContactCardLinkedWithVendorOpensContactBusRelationsList()
    var
        ContactCompany: Record Contact;
        ContactCard: TestPage "Contact Card";
        ContactBusinessRelations: TestPage "Contact Business Relations";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Business Relation] [UI]
        // [SCENARIO 383899] Contact linked with Vendor and Bank opens "Contact Business Relations" on assist edit.
        Initialize();

        // [GIVEN] Created Contact with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        // [GIVEN] Link the contact with the Vendor 'V', Bank 'B'
        ContactCompany.SetHideValidationDialog(true);
        VendorNo := ContactCompany.CreateVendorFromTemplate('');
        BankAccountNo := ContactCompany.CreateBankAccount();

        // [GIVEN] Open Contact card
        ContactCard.OpenView();
        ContactCard.Filter.SetFilter("No.", ContactCompany."No.");

        // [WHEN] Assit edit on "Business Relation"
        ContactBusinessRelations.Trap();
        ContactCard."Contact Business Relation".DrillDown();
        // [THEN] "Contact Business Relations" is open, where are two records: bank 'B' and vendor 'V' 
        ContactBusinessRelations."No.".AssertEquals(BankAccountNo);
        ContactBusinessRelations.Next();
        ContactBusinessRelations."No.".AssertEquals(VendorNo);
        ContactBusinessRelations.Close();

        // [THEN] "No. of Business Relations" in the factbox is 2
        ContactCard.Control31."No. of Business Relations".AssertEquals(2);
        // [WHEN] Drilldown on "No. of Business Relations"
        ContactBusinessRelations.Trap();
        ContactCard.Control31."No. of Business Relations".Drilldown();
        // [THEN] "Contact Business Relations" is open, where are two records: bank 'B' and vendor 'V' 
        ContactBusinessRelations."No.".AssertEquals(BankAccountNo);
        ContactBusinessRelations.Next();
        ContactBusinessRelations."No.".AssertEquals(VendorNo);
        ContactBusinessRelations.Close();
    end;

    [Test]
    procedure T214_ContactCardWithoutRelationsOpensContactBusRelationsList()
    var
        ContactCompany: Record Contact;
        ContactCard: TestPage "Contact Card";
        ContactBusinessRelations: TestPage "Contact Business Relations";
    begin
        // [FEATURE] [Business Relation] [UI]
        // [SCENARIO 383899] Contact linked with Vendor and Bank opens "Contact Business Relations" on assist edit.
        Initialize();

        // [GIVEN] Created Contact with type Company, no relations
        LibraryMarketing.CreateCompanyContact(ContactCompany);

        // [GIVEN] Open Contact card
        ContactCard.OpenView();
        ContactCard.Filter.SetFilter("No.", ContactCompany."No.");

        // [WHEN] Assit edit on "Business Relation"
        ContactBusinessRelations.Trap();
        ContactCard."Contact Business Relation".DrillDown();
        // [THEN] Empty "Contact Business Relations" is open 
        Assert.IsFalse(ContactBusinessRelations.First(), 'Contact Business Relations is not empty');
    end;

    [Test]
    procedure T215_ContactPersonWithCompanyLinkedToCustomerHasBusRelationCustomer()
    var
        ContactCompany: Record Contact;
        ContactPerson: Record Contact;
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO 388067] Contact (person) of the company contact related to a customer, has "Business Relation" 'Customer'.
        Initialize();

        // [GIVEN] Contact(company) 'C', where "Business Relation" is 'Customer'
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        CreateBusRelationCustomer(ContactCompany);
        // [GIVEN] Contact(person) 'P', where "Company No." is 'C'
        LibraryMarketing.CreatePersonContact(ContactPerson);

        // [WHEN] Set "Company No." to 'C' in contact 'P'
        ContactPerson.Validate("Company No.", ContactCompany."No.");

        // [THEN] Contact 'P', where "Business Relation" is 'Customer' 
        ContactPerson.TestField("Contact Business Relation", ContactCompany."Contact Business Relation");
    end;

    [Test]
    procedure T216_ContactPersonsGotUpdatedBusRelationOnRemovedCompanyRelation()
    var
        BusinessRelation: Record "Business Relation";
        ContactCompany: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactPerson: array[2] of Record Contact;
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO 388067] Contacts (person) of the company contact related to a customer, got updated "Business Relation" on the relation removal.
        Initialize();

        // [GIVEN] Contact(company) 'C', where "Business Relation" is 'Customer'
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        CreateBusRelationCustomer(ContactCompany);
        // [GIVEN] Contact(person) 'P1', where Business Relation" is 'None'
        LibraryMarketing.CreatePersonContact(ContactPerson[1]);
        ContactPerson[1].TestField("Contact Business Relation", "Contact Business Relation"::None);
        // [GIVEN] Contact(person) 'P2', where Business Relation" is 'Other'
        LibraryMarketing.CreatePersonContact(ContactPerson[2]);
        ContactBusinessRelation."Contact No." := ContactPerson[2]."No.";
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ContactBusinessRelation."Business Relation Code" := BusinessRelation.Code;
        ContactBusinessRelation.Insert();
        ContactPerson[2].Find();
        ContactPerson[2].TestField("Contact Business Relation", "Contact Business Relation"::Other);
        // [GIVEN] Contact 'P1' got "Company No." as 'C', so "Business Relation" is 'Customer'
        ContactPerson[1].Validate("Company No.", ContactCompany."No.");
        ContactPerson[1].Modify();
        ContactPerson[1].TestField("Contact Business Relation", "Contact Business Relation"::Customer);
        // [GIVEN] Contact 'P2' got "Company No." as 'C', so "Business Relation" is 'Multiple'
        ContactPerson[2].Validate("Company No.", ContactCompany."No.");
        ContactPerson[2].Modify();
        ContactPerson[2].TestField("Contact Business Relation", "Contact Business Relation"::Multiple);

        // [WHEN] Remove business relation for contact 'C'
        ContactBusinessRelation.SetRange("Contact No.", ContactCompany."No.");
        ContactBusinessRelation.FindFirst();
        ContactBusinessRelation.Delete(true);

        // [THEN] Contact 'P', where "Business Relation" is 'None' and 'Other' in person contacts 
        ContactPerson[1].Find();
        ContactPerson[1].TestField("Contact Business Relation", "Contact Business Relation"::None);
        ContactPerson[2].Find();
        ContactPerson[2].TestField("Contact Business Relation", "Contact Business Relation"::Other);
    end;

    [Test]
    procedure T217_PersonContactOnCustomerGetsBusRelationCustomer()
    var
        Customer: Record Customer;
        ContactPerson: Record Contact;
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO] Contact (person) automatically created for the customer has "Business Relation" 'Customer'
        Initialize();
        // [GIVEN] Customer 'X'
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Set 'Contact' as 'C' on Customer 'X'
        ContactPerson.Name := LibraryUtility.GenerateGUID();
        Customer.Validate(Contact, ContactPerson.Name);

        // [THEN] Contact (person) 'C', where "Business Relation" is 'Customer'
        ContactPerson.SetRange(Name, ContactPerson.Name);
        ContactPerson.FindFirst();
        ContactPerson.TestField("Contact Business Relation", "Contact Business Relation"::Customer);
    end;

    [Test]
    procedure T218_PersonContactOnVendorGetsBusRelationVendor()
    var
        Vendor: Record Vendor;
        ContactPerson: Record Contact;
    begin
        // [FEATURE] [Business Relation] [UT]
        // [SCENARIO] Contact (person) automatically created for the Vendor has "Business Relation" 'Vendor'
        Initialize();
        // [GIVEN] Vendor 'X'
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Set 'Contact' as 'C' on Vendor 'X'
        ContactPerson.Name := LibraryUtility.GenerateGUID();
        Vendor.Validate(Contact, ContactPerson.Name);

        // [THEN] Contact (person) 'C', where "Business Relation" is 'Vendor'
        ContactPerson.SetRange(Name, ContactPerson.Name);
        ContactPerson.FindFirst();
        ContactPerson.TestField("Contact Business Relation", "Contact Business Relation"::Vendor);
    end;

    [Test]
    procedure T220_UpdateContactBusinessRelationShouldChangeContact()
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
    begin
        // [FEATURE] [Business Relation] [UT]
        // [GIVEN] Contact 'X', where "Business Relation" is <blank>
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact."Contact Business Relation" := Contact."Contact Business Relation"::" ";
        Contact.Modify();
        // [GIVEN] ContactBusinessRelation, where "Contact No." is 'X'
        ContactBusinessRelation."Contact No." := Contact."No.";
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ContactBusinessRelation."Business Relation Code" := BusinessRelation.Code;

        // [WHEN] Insert (runs UpdateContactBusinessRelation())
        ContactBusinessRelation.Insert();

        // [THEN] Contact 'X' is not changed, "Business Relation" is 'Other'
        Contact.Find();
        Contact.TestField("Contact Business Relation", "Contact Business Relation"::Other);
    end;

    [Test]
    procedure T221_UpdateTemporaryContactBusinessRelationShouldNotChangeContact()
    var
        BusinessRelation: Record "Business Relation";
        TempContactBusinessRelation: Record "Contact Business Relation" temporary;
        Contact: Record Contact;
    begin
        // [FEATURE] [Business Relation] [UT]
        // [GIVEN] Contact 'X', where "Business Relation" is <blank>
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact."Contact Business Relation" := Contact."Contact Business Relation"::" ";
        Contact.Modify();
        // [GIVEN] temporary ContactBusinessRelation, where "Contact No." is 'X'
        TempContactBusinessRelation."Contact No." := Contact."No.";
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        TempContactBusinessRelation."Business Relation Code" := BusinessRelation.Code;

        // [WHEN] Insert (runs UpdateContactBusinessRelation())
        TempContactBusinessRelation.Insert();

        // [THEN] Contact 'X' is not changed, "Business Relation" is still <blank>
        Contact.Find();
        Contact.TestField("Contact Business Relation", "Contact Business Relation"::" ");
    end;

    [Test]
    [HandlerFunctions('CreateInteractModalPageHandler')]
    [Scope('OnPrem')]
    procedure CreateInterationDefaultSPFromUserSetup()
    var
        Contact: Record Contact;
        UserSetup: Record "User Setup";
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
    begin
        // [SCENARIO 395676] Interaction created from Contact should take SalesPerson from User setup first
        Initialize();

        // [GIVEN] Current user setup with SalesPerson1 defined in "Salespers./Purch. Code" field
        LibrarySales.CreateSalesperson(SalespersonPurchaser[1]);
        LibraryDocumentApprovals.CreateOrFindUserSetup(UserSetup, UserId);
        UserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser[1].Code);
        UserSetup.Modify(true);
        LibraryVariableStorage.Enqueue(SalespersonPurchaser[1].Code);

        // [GIVEN] Contact "C" with "Salesperson Code" = SalesPerson2.
        LibrarySales.CreateSalesperson(SalespersonPurchaser[2]);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.VALIDATE("Salesperson Code", SalespersonPurchaser[2].Code);
        Contact.Modify(true);

        // [WHEN] Create Interaction for Contact "C"
        // [THEN] "Create Interaction" page is opened with "Salesperson Code" = SalesPerson1
        Contact.CreateInteraction();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerMobilePhoneNoUpdateFromContact()
    var
        Customer: Record Customer;
        CompanyContact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO 402793] Customer."Mobile Phone No." field updated when "Mobile Phone No." is changed on related contact
        Initialize();

        // [GIVEN]  Company Contact "CC"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Customer "C" created from "CC" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateCustomerFromTemplate('');
        Customer.SetRange(Name, CompanyContact.Name);
        Customer.FindFirst();

        // [WHEN] Contact "CC" mobile phone number is being changed to "111" in the contact card page
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", CompanyContact."No.");
        ContactCard."Mobile Phone No.".SetValue(CopyStr(LibraryUtility.GenerateRandomNumericText(20), 1, MaxStrLen(CompanyContact."Mobile Phone No.")));
        ContactCard.OK().Invoke();

        // [THEN] Customer "C" has same mobile phone number "111"
        CompanyContact.Find();
        Customer.Find();
        Customer.TestField("Mobile Phone No.", CompanyContact."Mobile Phone No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPersonContactShouldNotUpdateCustomerFields()
    var
        Customer: Record Customer;
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
    begin
        // [SCENARIO 421379] When Person Contact is created for related Customer, fields "Primary Contact No."", "Contact" should not be updated
        Initialize();

        // [GIVEN]  Company Contact "CC"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Customer "C" created from "CC" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateCustomerFromTemplate('');
        Customer.SetRange(Name, CompanyContact.Name);
        Customer.FindFirst();

        // [GIVEN] Customer "C" has "Primary Contact No." and "Contact" fields empty
        Customer.Validate("Primary Contact No.", '');
        Customer.Validate(Contact, '');
        Customer.Modify();

        // [WHEN] New Person Contact created for Customer "C"
        PersonContact.Init();
        PersonContact.Validate(Type, PersonContact.Type::Person);
        PersonContact.Validate("Company No.", CompanyContact."No.");
        PersonContact.Validate(Name, CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(PersonContact.Name)));

        // [THEN] Customer fields "Primary Contact No." and "Contact" are empty
        Customer.Find();
        Customer.TestField("Primary Contact No.", '');
        Customer.TestField(Contact, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPersonContactShouldNotUpdateVendorFields()
    var
        Vendor: Record Vendor;
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
    begin
        // [SCENARIO 421379] When Person Contact is created for related Vendor, fields "Primary Contact No."", "Contact" should not be updated
        Initialize();

        // [GIVEN]  Company Vendor "VV"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Vendor "V" created from "VV" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateVendorFromTemplate('');
        Vendor.SetRange(Name, CompanyContact.Name);
        Vendor.FindFirst();

        // [GIVEN] Vendor "V" has "Primary Contact No." and "Contact" fields empty
        Vendor.Validate("Primary Contact No.", '');
        Vendor.Validate(Contact, '');
        Vendor.Modify();

        // [WHEN] New Person Contact created for Vendor "V"
        PersonContact.Init();
        PersonContact.Validate(Type, PersonContact.Type::Person);
        PersonContact.Validate("Company No.", CompanyContact."No.");
        PersonContact.Validate(Name, CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(PersonContact.Name)));

        // [THEN] Vendor fields "Primary Contact No." and "Contact" are empty
        Vendor.Find();
        Vendor.TestField("Primary Contact No.", '');
        Vendor.TestField(Contact, '');
    end;

    [Test]
    [HandlerFunctions('ModalSelectCustomerTemplListHandler,ConfirmHandlerTrue')]
    procedure ContactBusinessRelationAfterContactMerge()
    var
        ContactCompany: array[2] of Record Contact;
        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingContacts: Codeunit "Marketing Contacts";
        ContactList: TestPage "Contact List";
    begin
        // [SCENARIO 431320] "Business Relation" on Contact List should be updated if initial value = None, but Business Relation exists
        Initialize();
        BindSubscription(MarketingContacts); // to subscribe OnAfterIsEnabledCustTemplate

        // [GIVEN] Created Contact 'A' with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany[1]);
        ContactCompany[1].SetHideValidationDialog(true);
        ContactCompany[1].CreateCustomer();

        // [GIVEN] Created Contact 'B' with type Company
        LibraryMarketing.CreateCompanyContact(ContactCompany[2]);
        ContactCompany[2].SetHideValidationDialog(true);
        ContactCompany[2].CreateCustomer();

        // [GIVEN] Remove Contact Business Relation for Contact 'B' (simulation of removing duplicate on Contact Merge page), 
        ContactBusinessRelation.SetRange("Contact No.", ContactCompany[2]."No.");
        ContactBusinessRelation.FindFirst();
        ContactBusinessRelation.Delete(true);
        ContactCompany[2].UpdateBusinessRelation();

        // [WHEN] Merge Contact 'B' to 'A'     
        TempMergeDuplicatesBuffer."Table ID" := DATABASE::Contact;
        TempMergeDuplicatesBuffer.Duplicate := ContactCompany[2]."No.";
        TempMergeDuplicatesBuffer.Current := ContactCompany[1]."No.";
        TempMergeDuplicatesBuffer.Insert();
        TempMergeDuplicatesBuffer.Merge();

        // [WHEN] Open Contact List
        ContactList.OpenView();
        ContactList.Filter.SetFilter("No.", ContactCompany[1]."No.");

        // [THEN] "Business Relation" for Contact "A" = Customer
        ContactList."Business Relation".AssertEquals(ContactCompany[1]."Contact Business Relation"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobCustomerContBusinessRelation()
    var
        Customer: Record Customer;
        CompanyContact: Record Contact;
        Job: Record Job;
    begin
        // [SCENARIO 433844] When Job is created for Customer with related Contact, Contact No. should be populated from this Contact
        Initialize();

        // [GIVEN] Company Contact "Cont"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Customer "C" created from "Cont" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateCustomerFromTemplate('');
        Customer.SetRange(Name, CompanyContact.Name);
        Customer.FindFirst();

        // [WHEN] Job created for Customer "C"
        LibraryJob.CreateJob(Job, Customer."No.");

        // [THEN] Sell-to Contact No. = Bill-to Contact No. = Cont
        Job.TestField("Sell-to Contact No.", CompanyContact."No.");
        Job.TestField("Bill-to Contact No.", CompanyContact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPrimaryContactDeletion()
    var
        Customer: Record Customer;
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
    begin
        // [SCENARIO 433957] 'Primary Contact No.' and 'Contact' fields should be cleared when the Contact is deleted
        Initialize();

        // [GIVEN] Company Contact "CC"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Person Contact "PC" related to "CC" 
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."Company No.");
        PersonContact.Modify(true);

        // [GIVEN] Customer created from "CC" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateCustomerFromTemplate('');
        Customer.SetRange(Name, CompanyContact.Name);
        Customer.FindFirst();

        // [GIVEN] Customer Primary Contact No. = "PC", Customer Contact = PC.Name
        Customer.Validate("Primary Contact No.", PersonContact."No.");
        Customer.Modify();
        Customer.TestField("Primary Contact No.", PersonContact."No.");
        Customer.TestField(Contact, PersonContact.Name);

        // [WHEN] Contact "PC" is deleted
        PersonContact.Delete(true);

        // [THEN] Customer 'Primary Contact No.' and 'Contact' are cleared
        Customer.Find();
        Customer.TestField("Primary Contact No.", '');
        Customer.TestField(Contact, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPrimaryContactDeletion()
    var
        Vendor: Record Vendor;
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
    begin
        // [SCENARIO 433957] 'Primary Contact No.' and 'Contact' fields should be cleared when the Contact is deleted
        Initialize();

        // [GIVEN] Company Contact "CC"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Person Contact "PC" related to "CC" 
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."Company No.");
        PersonContact.Modify(true);

        // [GIVEN] Customer created from "CC" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateVendorFromTemplate('');
        Vendor.SetRange(Name, CompanyContact.Name);
        Vendor.FindFirst();

        // [GIVEN] Vendor Primary Contact No. = "PC", Customer Contact = PC.Name
        Vendor.Validate("Primary Contact No.", PersonContact."No.");
        Vendor.Modify();
        Vendor.TestField("Primary Contact No.", PersonContact."No.");
        Vendor.TestField(Contact, PersonContact.Name);

        // [WHEN] Contact "PC" is deleted
        PersonContact.Delete(true);

        // [THEN] Vendor 'Primary Contact No.' and 'Contact' are cleared
        Vendor.Find();
        Vendor.TestField("Primary Contact No.", '');
        Vendor.TestField(Contact, '');
    end;

    [Test]
    procedure ContactUpdateBusinessRelationNoneEmpty()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactList: TestPage "Contact List";
    begin
        // [SCENARIO 431320] "Business Relation" on Contact List should be updated if initial value = None, but Business Relation exists
        Initialize();

        // [GIVEN] Customer with Contact "C" and contact business relation.
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);
        LibrarySales.CreateCustomer(Customer);

        Customer.SetRange("No.", Customer."No.");
        RunCreateContsFromCustomersReport(Customer);

        FindContactBusinessRelation(
            ContactBusinessRelation, BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
        Contact.Get(ContactBusinessRelation."Contact No.");

        // [GIVEN] Contact "C" has "Contact Business Relation" = Bank Account (setting wrong business relation which should not be changed)
        Contact."Contact Business Relation" := Contact."Contact Business Relation"::"Bank Account";
        Contact.Modify();
        Commit();

        // [WHEN] Open Contact List
        ContactList.OpenView();
        ContactList.Filter.SetFilter("No.", Contact."No.");

        // [THEN] "Business Relation" for Contact "C" = Bank Account
        ContactList."Business Relation".AssertEquals(Contact."Contact Business Relation"::"Bank Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobCardChangeSellToContact()
    var
        Customer: Record Customer;
        CompanyContact: Record Contact;
        PersonContact: array[2] of Record Contact;
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        // [SCENARIO 439583] When Contact is changed on Job card, Contact related fields should also be populated
        Initialize();

        // [GIVEN] Company Contact "Cont"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Customer "C" created from "Cont" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateCustomerFromTemplate('');
        Customer.SetRange(Name, CompanyContact.Name);
        Customer.FindFirst();

        // [GIVEN] Person Contact #1 and Person Contact #2
        CreateContactWithPhoneEmail(PersonContact[1], CompanyContact."Company No.");
        CreateContactWithPhoneEmail(PersonContact[2], CompanyContact."Company No.");

        // [GIVEN] Person Contact #1 is set as 'Primary Contact No.' for Customer "C"
        Customer.Validate("Primary Contact No.", PersonContact[1]."No.");
        Customer.Modify();

        // [GIVEN] Job created for Customer "C"
        LibraryJob.CreateJob(Job, Customer."No.");

        // [GIVEN] Job Card opened
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job."No.");

        // [WHEN] "Sell-to Contact No." is changed from Contact #1 to Contact #2
        JobCard."Sell-to Contact No.".SetValue(PersonContact[2]."No.");

        // [THEN] 'Phone No.', 'Mobile Phone No.' and Email fields values are equal to same fields in Contact #2
        JobCard.SellToPhoneNo.AssertEquals(PersonContact[2]."Phone No.");
        JobCard.SellToMobilePhoneNo.AssertEquals(PersonContact[2]."Mobile Phone No.");
        JobCard.SellToEmail.AssertEquals(PersonContact[2]."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ContactListLookupModalPageHandler')]
    [Scope('OnPrem')]
    procedure JobCardChangeLookUpSellToContact()
    var
        Customer: Record Customer;
        CompanyContact: Record Contact;
        PersonContact: array[2] of Record Contact;
        Job: Record Job;
        JobCard: TestPage "Job Card";
    begin
        // [SCENARIO 439583] When Contact is changed using lookup on Job card, Contact related fields should also be populated
        Initialize();

        // [GIVEN] Company Contact "Cont"
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Customer "C" created from "Cont" Company Contact
        CompanyContact.SetHideValidationDialog(true);
        CompanyContact.CreateCustomerFromTemplate('');
        Customer.SetRange(Name, CompanyContact.Name);
        Customer.FindFirst();

        // [GIVEN] Person Contact #1 and Person Contact #2
        CreateContactWithPhoneEmail(PersonContact[1], CompanyContact."Company No.");
        CreateContactWithPhoneEmail(PersonContact[2], CompanyContact."Company No.");

        // [GIVEN] Person Contact #1 is set as 'Primary Contact No.' for Customer "C"
        Customer.Validate("Primary Contact No.", PersonContact[1]."No.");
        Customer.Modify();

        // [GIVEN] Job created for Customer "C"
        LibraryJob.CreateJob(Job, Customer."No.");
        Job.TestField("Sell-to Contact No.", PersonContact[1]."No.");

        // [GIVEN] Job Card opened
        JobCard.OpenEdit();
        JobCard.Filter.SetFilter("No.", Job."No.");

        // [WHEN] "Sell-to Contact No." is changed from Contact #1 to Contact #2 using lookup
        LibraryVariableStorage.Enqueue(PersonContact[2]."No.");
        JobCard."Sell-to Contact No.".Lookup();

        // [THEN] 'Phone No.', 'Mobile Phone No.' and Email fields values are equal to same fields in Contact #2
        JobCard.SellToPhoneNo.AssertEquals(PersonContact[2]."Phone No.");
        JobCard.SellToMobilePhoneNo.AssertEquals(PersonContact[2]."Mobile Phone No.");
        JobCard.SellToEmail.AssertEquals(PersonContact[2]."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask')]
    procedure VerifyOneRecordIsCreatedForNonMeetingTaskCreatedFromTaskListForContact()
    var
        Contact: Record Contact;
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
    begin
        // [SCENARIO 455599] Verify one record is created for Non Meeting Task created from Task List for Contact
        Initialize();

        // [GIVEN] Create Contact
        LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Create Task for Contact
        Task.SetRange("Contact No.", Contact."No.");
        TempTask.CreateTaskFromTask(Task);

        // [THEN] Verify Organize To Do values
        Task.Reset();
        Task.SetRange("Contact No.", Contact."No.");
        Assert.RecordCount(Task, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S469700_OpenRelatedContactsFromContactList()
    var
        Contact: Record Contact;
        ContactList: TestPage "Contact List";
    begin
        // [FEATURE] [Contact List]
        // [SCENARIO 469700] Related Contacts action is enabled in Contact List.
        Initialize();

        // [GIVEN] Create at least one Contact.
        if Contact.IsEmpty() then
            LibraryMarketing.CreateCompanyContact(Contact);

        // [WHEN] Open contact list.
        ContactList.OpenView();

        // [WHEN] Related Contacts action is enabled.
        Assert.IsTrue(ContactList."Relate&d Contacts".Enabled(), 'Expected Related Contacts action to be enabled.');

        ContactList.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,CustomerTemplateHandler,MessageHandler')]
    procedure VerifyItemIsAutoReservedWhenSalesOrderIsCreatedFromSalesQuoteCreateFromContactRelatedForCustomerTemplate()
    var
        Item: Record Item;
        CustomerTempl: Record "Customer Templ.";
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        SalesQuote: TestPage "Sales Quote";
        SalesOrder: TestPage "Sales Order";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [SCENARIO 470483] Verify Item is auto reserved when Sales Order is created from Sales Quote create from Contact Related for Customer Template
        Initialize();

        // [GIVEN] Create Customer Template
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);
        CustomerTempl."Contact Type" := CustomerTempl."Contact Type"::Person;
        CustomerTempl.Reserve := CustomerTempl.Reserve::Always;
        CustomerTempl.Modify(true);

        LibraryVariableStorage.Enqueue(CustomerTempl.Code);

        // [GIVEN] Create Item and Post Inventory
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournal(Item."No.");

        // [GIVEN]  Create Person Contact
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] "Contact Card" page is opened
        ContactCard.OpenView();
        ContactCard.GotoRecord(Contact);

        // [GIVEN] Press action "New Sales Quote", confirm message "Do you want to select the customer template?" and select template "X"
        SalesQuote.Trap();

        // [GIVEN] Move cursor to the next field in "Sales Quote" page to create new record
        ContactCard.NewSalesQuote.Invoke();

        // [GIVEN] Create Sales Quote Line with Item
        SalesQuote.SalesLines."No.".SetValue(Item."No.");
        SalesQuote.SalesLines.Quantity.SetValue(1);
        SalesQuote.SalesLines."Unit Price".SetValue(10);

        // [GIVEN] Katch Sales Order
        SalesOrder.Trap();

        // [WHEN] Create Order from Quote
        SalesQuote.MakeOrder.Invoke();

        // [THEN] Verify Item is reserved        
        ReservationEntry.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ReservationEntry, 2);
    end;

    [Test]
    procedure CreateItemFromItemTemplateWithDefaultDimensions()
    var
        ItemTempl: Record "Item Templ.";
        Item: Record Item;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        // [SCENARIO 525355] Value filters of dimensions in a Item Template are being transferred to new Item created using the template.
        Initialize();

        // [GIVEN] Create Item Template to set Dimension.
        LibraryTemplates.CreateItemTemplate(ItemTempl);

        // [GIVEN] Create a Dimension.
        LibraryDimension.CreateDimension(Dimension);

        // [GIVEN] Create Dimension Value with the Dimension.
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        // [GIVEN] Create Default Dimension for Item Template.
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension,
            DATABASE::"Item Templ.",
            ItemTempl.Code,
            DimensionValue."Dimension Code",
            DimensionValue.Code);

        // [GIVEN] Validate Value Posting and Allowed Values Filter in Default Dimension.
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue.Code);
        DefaultDimension.Modify();

        // [WHEN] Create a new Item from the Item Template.
        Item.Init();
        Item.Insert(true);
        ItemTemplMgt.ApplyItemTemplate(Item, ItemTempl);

        // [THEN] Find and check Default Dimensions are copied to the new Item with Allowed Value Filter.
        DefaultDimension.Reset();
        DefaultDimension.SetRange("Table ID", DATABASE::Item);
        DefaultDimension.SetRange("No.", Item."No.");
        DefaultDimension.SetRange("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.FindFirst();
        Assert.AreEqual(
            DefaultDimension."Allowed Values Filter",
            DefaultDimension."Dimension Value Code",
            ItemDimensionAllowedFilter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameBusinessRelationShouldNotUpdateContactBusinessRelation()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
        PrevContactCount: Integer;
    begin
        // [SCENARIO 538469] A problem with renaming the "Contact Business Relation" field in the Contacts page in BC
        Initialize();

        // [GIVEN] Setup: Create a new Business Relation and Modify MarketingSetup."Bus. Rel. Code for Customers" = "X".
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);

        // [THEN] Create a new Customer and Create Contact from Customer by running the report Create Conts. from Customers.
        LibrarySales.CreateCustomer(Customer);
        Customer.SetRange("No.", Customer."No.");
        RunCreateContsFromCustomersReport(Customer);

        // [WHEN] Rename the Business Relation Code to a random text
        BusinessRelation.CalcFields("No. of Contacts");
        PrevContactCount := BusinessRelation."No. of Contacts";
        BusinessRelation.Rename(LibraryRandom.RandText(5));

        // [THEN] Verify: Bus. Rec. Code for Customer is updated on Marketing Setup
        MarketingSetup.Get();
        Assert.AreEqual(MarketingSetup."Bus. Rel. Code for Customers", BusinessRelation.Code, ValueMustMatch);

        // [THEN] Verify: No. of Contacts on Business Relation is equal to previosu
        BusinessRelation.Get(BusinessRelation.Code);
        BusinessRelation.CalcFields("No. of Contacts");
        Assert.AreEqual(PrevContactCount, BusinessRelation."No. of Contacts", ValueMustMatch);

        // [THEN] Verify: Check that the Contact Business Relation is Customer.
        ContactBusinessRelation.SetRange("Business Relation Code", BusinessRelation.Code);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.FindFirst();
        Contact.Get(ContactBusinessRelation."Contact No.");
        Assert.AreEqual(Contact."Contact Business Relation", Contact."Contact Business Relation"::Customer, ValueMustMatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameBusinessRelationOnAllMarketingBusinessRelationFields()
    var
        BusinessRelation: Record "Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        // [SCENARIO 538469] A problem with renaming the "Contact Business Relation" field in the Contacts page in BC
        Initialize();

        // [GIVEN] Setup: Create a new Business Relation and Modify all Business Relation related fields on MarketingSetup
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        UpdateSameBusinessRelationCodeOnMarketingSetup(BusinessRelation.Code);

        // [WHEN] Rename the Business Relation Code to a random text
        BusinessRelation.Rename(LibraryRandom.RandText(5));

        // [THEN] Verify: Business Relation related fields on Marketing Setup
        MarketingSetup.Get();
        Assert.AreEqual(MarketingSetup."Bus. Rel. Code for Customers", BusinessRelation.Code, ValueMustMatch);
        Assert.AreEqual(MarketingSetup."Bus. Rel. Code for Vendors", BusinessRelation.Code, ValueMustMatch);
        Assert.AreEqual(MarketingSetup."Bus. Rel. Code for Employees", BusinessRelation.Code, ValueMustMatch);
        Assert.AreEqual(MarketingSetup."Bus. Rel. Code for Bank Accs.", BusinessRelation.Code, ValueMustMatch);
    end;

    [Test]
    [HandlerFunctions('CreateInteractFinishModalFormHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ResumePostponedInteraction()
    var
        Contact: Record Contact;
        InteractionTemplate: array[2] of Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
        VerifyInteractionLogEntry: Record "Interaction Log Entry";
        PostponedInteraction: TestPage "Postponed Interactions";
        CostLCY: Decimal;
        DurationMin: Decimal;
        FinishInteraction: Boolean;
    begin
        // [SCENARIO 554707] If you Resume a Postponed Interaction with Contact the information entered go to a different Postponed Interaction.
        Initialize();

        // [GIVEN] Create a new Contact, 2 new Interaction Template. Create 2 new Postponed Interaction for Contact.
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate[1]);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate[2]);

        // [GIVEN] Create first Postponed Interaction
        LibraryVariableStorage.Enqueue(InteractionTemplate[1].Code);
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(DurationMin);
        LibraryVariableStorage.Enqueue(FinishInteraction);
        Contact.CreateInteraction();

        // [GIVEN] Create second Postponed Interaction
        LibraryVariableStorage.Enqueue(InteractionTemplate[2].Code);
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(DurationMin);
        LibraryVariableStorage.Enqueue(FinishInteraction);
        Contact.CreateInteraction();

        // [GIVEN] Find first postponed inetraction entry
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        InteractionLogEntry.SetRange("Interaction Template Code", InteractionTemplate[1].Code);
        InteractionLogEntry.FindFirst();
        FinishInteraction := true;

        // [WHEN] For Postponed interaction resume interaction considering random decimal value
        CostLCY := LibraryRandom.RandDec(100, 2);
        DurationMin := LibraryRandom.RandDec(100, 2);

        LibraryVariableStorage.Enqueue(InteractionTemplate[1].Code);
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(DurationMin);
        LibraryVariableStorage.Enqueue(FinishInteraction);
        PostponedInteraction.OpenView();
        PostponedInteraction.GoToRecord(InteractionLogEntry);
        PostponedInteraction.Resume.Invoke();

        // [THEN] Verify Cost(LCY) and Duration(Min.) field updated on correct interaction log entry
        VerifyInteractionLogEntry.Get(InteractionLogEntry."Entry No.");
        Assert.AreEqual(VerifyInteractionLogEntry."Cost (LCY)", CostLCY, ValueMustMatch);
        Assert.AreEqual(VerifyInteractionLogEntry."Duration (Min.)", DurationMin, ValueMustMatch);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerForTask')]
    procedure TaskListPageHasFixedSystemTaskTypeFilterAsOrganiserOrContactAttendee()
    var
        Contact: Record Contact;
        Task: Record "To-do";
        TempTask: Record "To-do" temporary;
        ContactCard: TestPage "Contact Card";
        TaskList: TestPage "Task List";
    begin
        // [SCENARIO 568324] Task List page has a fixed System Task Type filter as 'Organizer|Contact Attendee' when Next Task Date Drilldown on Contact card
        Initialize();

        // [GIVEN] Create Contact
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Create Task for Contact
        Task.SetRange("Contact No.", Contact."No.");
        TempTask.CreateTaskFromTask(Task);

        // [WHEN] Open Contact Card and Drilldonw 'Next Task Date' also Trap Task List
        ContactCard.OpenView();
        ContactCard.GoToRecord(Contact);
        TaskList.Trap();
        ContactCard."Next Task Date".Drilldown();

        // [THEN] Verify Correct filter has been set on the page
        TaskList."Contact No.".AssertEquals(Contact."No.");
        Assert.AreEqual(
            StrSubstNo('%1|%2', Task."System To-do Type"::Organizer, Task."System To-do Type"::"Contact Attendee"),
            TaskList.Filter.GetFilter("System To-do Type"), 'Wrong filter was set');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,VendorTempModalFormHandler')]
    procedure TestContactListNewPurchaseQuoteForContactCompanyVendorTemplate()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        ContactList: TestPage "Contact List";
        PurchaseQuote: TestPage "Purchase Quote";
        VendorTemplateCode: Code[20];
    begin
        // [SCENARIO 391449] Verify that the Purchase Quote is created from Contact List page for Contact with Vendor Template selection.
        Initialize();

        // [GIVEN] Create Vendor Template "CT", Contact "C" with type Company.
        LibraryMarketing.CreateCompanyContact(Contact);
        VendorTemplateCode := CreateVendorTemplateForContact('');

        // [GIVEN] Create another Vendor Template.
        CreateVendorTemplateForContact('');

        // [GIVEN] Contact List page is opened and focus is set on Contact "C".
        ContactList.OpenView();
        ContactList.GotoRecord(Contact);

        // [WHEN] Invoke "New Purchase Quote" action.
        PurchaseQuote.Trap();
        ContactList.NewPurchaseQuote.Invoke();

        // [THEN] Verify that the Purchase Quote is created from Contact List page.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        PurchaseHeader.SetRange("Buy-from Contact No.", Contact."No.");
        PurchaseHeader.SetRange("Buy-from Vendor Templ. Code", VendorTemplateCode);
        Assert.RecordIsNotEmpty(PurchaseHeader);
        PurchaseQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalseWithTextVerification')]
    procedure TestContactListPurchaseQuoteForContactPerson()
    var
        Contact: Record Contact;
        ContactList: TestPage "Contact List";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 391449] Verify that the Purchase Quote is created from Contact List for Vendor with Type Person.
        Initialize();

        // [GIVEN] Create Contact with Type = Person.
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] Contact List page is opened and focus is set on Contact "C".
        ContactList.OpenView();
        ContactList.GotoRecord(Contact);

        // [WHEN] Invoke "New Purchase Quote" action.
        LibraryVariableStorage.Enqueue(SelectVendorTemplateQst);
        PurchaseQuote.Trap();
        ContactList.NewPurchaseQuote.Invoke();

        // [THEN] PurchaseQuote Page opens (handled in ModalPageHandler)
        PurchaseQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,VendorTempModalPageHandlerWithEnqueue')]
    procedure TestCreatePurchaseQuoteFromContactListAndVendorTemplateConfirmation()
    var
        Contact: Record Contact;
        VendorTempl: Record "Vendor Templ.";
        ContactList: TestPage "Contact List";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 391449] Verify that the Stan can create purchase quote from "Contact List" when "New Purchase Quote" action is invoked.
        Initialize();

        // [GIVEN] Create Company Contact.
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Create a Vendor Template.
        LibraryTemplates.CreateVendorTemplate(VendorTempl);

        // [GIVEN] Create another Vendor Template.
        LibraryTemplates.CreateVendorTemplate(VendorTempl);

        // [GIVEN] "Contact list" page is opened.
        ContactList.OpenView();
        ContactList.GotoRecord(Contact);

        // [WHEN] Create New Purchase Quote.
        PurchaseQuote.Trap();
        ContactList.NewPurchaseQuote.Invoke();

        // [THEN] Verify that the Purchase Quote is populated with "Buy-from Vendor Template Code" = "X".
        PurchaseQuote."Buy-from Address".SetValue('');
        PurchaseQuote."Buy-from Vendor Templ. Code".AssertEquals(LibraryVariableStorage.DequeueText());
        PurchaseQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,VendorTemplateHandler,MessageHandler')]
    procedure TestPurchaseOrderIsCreatedFromPurchaseQuoteCreateFromContactRelatedForVendorTemplate()
    var
        Item: Record Item;
        Contact: Record Contact;
        CompanyContact: Record Contact;
        VendorTempl: Record "Vendor Templ.";
        VendorTempl1: Record "Vendor Templ.";
        ContactCard: TestPage "Contact Card";
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseOrder: TestPage "Purchase Order";
        QuoteNo: Code[20];
    begin
        // [SCENARIO 391449] Verify that the Purchase Order is created from Purchase Quote for Vendor Template.
        Initialize();

        // [GIVEN] Create Company Contact.
        LibraryMarketing.CreateCompanyContact(CompanyContact);

        // [GIVEN] Create and update Vendor Template.
        LibraryTemplates.CreateVendorTemplateWithData(VendorTempl);
        VendorTempl."Contact Type" := VendorTempl."Contact Type"::Person;
        VendorTempl.Modify(true);

        // [GIVEN] Enqueue Vendor Template.
        LibraryVariableStorage.Enqueue(VendorTempl.Code);

        // [GIVEN] Create and another update Vendor Template.
        LibraryTemplates.CreateVendorTemplateWithData(VendorTempl1);
        VendorTempl1."Contact Type" := VendorTempl."Contact Type"::Person;
        VendorTempl1.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Post Item Journal.
        CreateAndPostItemJournal(Item."No.");

        // [GIVEN] Create Person Contact.
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Company No.", CompanyContact."No.");
        Contact.Modify();

        // [GIVEN] Open "Contact Card" page.
        ContactCard.OpenView();
        ContactCard.GotoRecord(Contact);
        PurchaseQuote.Trap();

        // [GIVEN] NewPurchaseQuote action is invoked.
        ContactCard.NewPurchaseQuote.Invoke();

        // [GIVEN] Create Purchase Quote Line with Item.
        QuoteNo := CopyStr(PurchaseQuote."No.".Value(), 1, 20);
        PurchaseQuote.PurchLines."No.".SetValue(Item."No.");
        PurchaseQuote.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(10));
        PurchaseQuote.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Make Order from Quote.
        PurchaseOrder.Trap();
        PurchaseQuote.MakeOrder.Invoke();

        // [THEN] Verify Purchae Order is created from purchase quote.     
        PurchaseOrder."Quote No.".AssertEquals(QuoteNo);
    end;

    local procedure Initialize()
    var
        MarketingSetup: Record "Marketing Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Contacts");
        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Contacts");

        LibraryTemplates.EnableTemplatesFeature();
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        MarketingSetup.Get();
        MarketingSetup.Validate("Maintain Dupl. Search Strings", false);
        MarketingSetup.Modify(true);

        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Contacts");
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;

    local procedure ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers: Code[10])
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Bus. Rel. Code for Customers", BusRelCodeForCustomers);
        MarketingSetup.Modify(true);
    end;

    local procedure ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors: Code[10])
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", BusRelCodeForVendors);
        MarketingSetup.Modify(true);
    end;

    local procedure ChangeBusinessRelationCodeForBankAccount(BusRelCodeForBankAccs: Code[10]) OriginalBusRelCodeForBankAccs: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        OriginalBusRelCodeForBankAccs := MarketingSetup."Bus. Rel. Code for Bank Accs.";
        MarketingSetup.Validate("Bus. Rel. Code for Bank Accs.", BusRelCodeForBankAccs);
        MarketingSetup.Modify(true);
    end;

    local procedure CreateBankAccountWithCurrency(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
    end;

    local procedure CreateBusRelationCustomer(var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.TestField("Bus. Rel. Code for Customers");
        LibraryMarketing.CreateContactBusinessRelation(
            ContactBusinessRelation, Contact."No.", MarketingSetup."Bus. Rel. Code for Customers");
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Customer;
        ContactBusinessRelation."No." := LibrarySales.CreateCustomerNo();
        ContactBusinessRelation.Modify(true);
        Contact.Find();
        Contact.TestField("Contact Business Relation", "Contact Business Relation"::Customer);
    end;

    local procedure CreateContactAsPerson(var Contact: Record Contact)
    begin
        LibraryMarketing.CreatePersonContact(Contact);
    end;

    local procedure CreateContactWithAddress(var Contact: Record Contact)
    begin
        CreateContactAsPerson(Contact);
        LibraryMarketing.UpdateContactAddress(Contact);
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.Insert(true);
    end;

    local procedure CreateSimpleContact(var Contact: Record Contact; ContactNo: Code[20])
    begin
        Contact.Init();
        Contact.Validate("No.", ContactNo);
        Contact.Insert(true);
    end;

    local procedure CreateCompanyContact(CompanyNo: Code[20]): Code[20]
    var
        Contact: Record Contact;
    begin
        Contact.Init();
        Contact."No." := CompanyNo;
        Contact.Type := Contact.Type::Company;
        Contact.Insert();
        exit(Contact."No.");
    end;

    local procedure CreateCustomerForContact(Contact: Record Contact; CustomerTemplateCode: Code[20]): Code[20]
    var
        ContBusRel: Record "Contact Business Relation";
        Customer: Record Customer;
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        PaymentTerms: Record "Payment Terms";
    begin
        Contact.CreateCustomerFromTemplate(CustomerTemplateCode);
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("Contact No.", Contact."No.");
        ContBusRel.FindFirst();
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Customer.Get(ContBusRel."No.");
        Customer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerFromContact(Contact: Record Contact; CustomerTemplateCode: Code[20]; var Customer: Record Customer)
    begin
        Contact.SetHideValidationDialog(true);
        Contact.CreateCustomerFromTemplate(CustomerTemplateCode);
        FindCustomerByCompanyName(Customer, Contact.Name);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer.Name := CopyStr(CreateGuid(), 1, 50);
        Customer.Insert();
    end;

    local procedure CreateCustomerTemplate(var CustomerTemplate: Record "Customer Templ."; CustomerPriceGroupCode: Code[10])
    var
        Customer2: Record Customer;
        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        Territory: Record Territory;
    begin
        LibrarySales.CreateCustomer(Customer2);
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate.Validate("Customer Price Group", CustomerPriceGroupCode);
        CustomerTemplate.Validate("Gen. Bus. Posting Group", Customer2."Gen. Bus. Posting Group");
        CustomerTemplate.Validate("VAT Bus. Posting Group", Customer2."VAT Bus. Posting Group");
        CustomerTemplate.Validate("Customer Posting Group", Customer2."Customer Posting Group");
        CustomerTemplate.Validate("Allow Line Disc.", true);
        CustomerTemplate.Validate("Payment Terms Code", Customer2."Payment Terms Code");
        CustomerTemplate.Validate("Payment Method Code", Customer2."Payment Method Code");
        CustomerTemplate.Validate("Shipment Method Code", Customer2."Shipment Method Code");
        LibraryERM.CreateCountryRegion(CountryRegion);
        CustomerTemplate.Validate("Country/Region Code", CountryRegion.Code);
        LibraryERM.CreateCurrency(Currency);
        CustomerTemplate.Validate("Currency Code", Currency.Code);
        Territory.FindFirst();
        CustomerTemplate.Validate("Territory Code", Territory.Code);
        CustomerTemplate.Modify(true);
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code);
    end;

    local procedure CreateCustomerTemplates(var CustomerTemplate: array[2] of Record "Customer Templ.")
    begin
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate[1]);
        CustomerTemplate[1].Validate("Contact Type", CustomerTemplate[1]."Contact Type"::Company);
        CustomerTemplate[1].Modify(true);

        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate[2]);
        CustomerTemplate[2].Validate("Contact Type", CustomerTemplate[2]."Contact Type"::Person);
        CustomerTemplate[2].Modify(true);
    end;

    local procedure CreateCustomerTemplateForContact(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        CustomerTemplate: Record "Customer Templ.";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerTemplate.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
        CustomerTemplate.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        CustomerTemplate.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        CustomerTemplate.Modify();
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code);
        exit(CustomerTemplate.Code);
    end;

    local procedure CreateCustomerWithCurrency(var Customer: Record Customer; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithContactPerson(var Customer: Record Customer; var Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
        LibrarySales.CreateCustomer(Customer);
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("No.", Customer."No.");
        ContBusRel.FindFirst();
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Company No.", ContBusRel."Contact No.");
        Contact.Modify(true);
    end;

    local procedure CreateCustomerWithSetupBusinessRelation(var Customer: Record Customer)
    var
        BusinessRelation: Record "Business Relation";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForCustomers('');
        LibrarySales.CreateCustomer(Customer);
        ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor.Name := CopyStr(CreateGuid(), 1, 50);
        Vendor.Insert();
    end;

    local procedure CreateVendorWithCurrency(var Vendor: Record Vendor; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithContactPerson(var Vendor: Record Vendor; var Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
        ContBusRel.SetRange("No.", Vendor."No.");
        ContBusRel.FindFirst();
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Company No.", ContBusRel."Contact No.");
        Contact.Modify(true);
    end;

    local procedure CreateVendorWithSetupBusinessRelation(var Vendor: Record Vendor)
    var
        BusinessRelation: Record "Business Relation";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors('');
        LibraryPurchase.CreateVendor(Vendor);
        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
    end;

    local procedure CreateBankAccountWithSetupBusinessRelation(var BankAccount: Record "Bank Account"; var Contact: Record Contact)
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForBankAccount(BusinessRelation.Code);
        LibraryERM.CreateBankAccount(BankAccount);
        FindContactBusinessRelation(
            ContactBusinessRelation, BusinessRelation.Code, "Contact Business Relation Link To Table"::"Bank Account", BankAccount."No.");
        Contact.Get(ContactBusinessRelation."Contact No.");
    end;

    local procedure CreateSegmentLine(var SegmentLine: Record "Segment Line"; AttachmentNo: Integer)
    begin
        SegmentLine.Init();
        SegmentLine."Segment No." := LibraryUtility.GenerateRandomCode(SegmentLine.FieldNo("Segment No."), DATABASE::"Segment Line");
        SegmentLine."Line No." := 10000;
        SegmentLine."Attachment No." := AttachmentNo;
        SegmentLine.Insert();
    end;

    local procedure CreateInteractLogEntry(SegmentLineNo: Integer)
    var
        InteractLogEntry: Record "Interaction Log Entry";
    begin
        InteractLogEntry.Init();
        InteractLogEntry."Entry No." := SegmentLineNo;
        InteractLogEntry.Insert();
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
    end;

    local procedure CreateWriteAttachment(var Attachment: Record Attachment)
    var
        LastNo: Integer;
    begin
        if Attachment.FindLast() then
            LastNo := Attachment."No.";
        Attachment.Init();
        Attachment."No." := LastNo + 1;
        Attachment."Attachment File".Import(CreateWriteTempFile());
        Attachment.Insert();
    end;

    local procedure CreateWriteTempFile() FileName: Text
    var
        FileMgt: Codeunit "File Management";
        TempFile: File;
    begin
        FileName := FileMgt.ServerTempFileName(ExtensionTxt);
        TempFile.TextMode(true);
        TempFile.WriteMode(true);
        if not Exists(FileName) then
            TempFile.Create(FileName)
        else
            TempFile.Open(FileName);
        TempFile.Write(TempFile.Name);
        // write FileName into file
        TempFile.Close();
    end;

    local procedure CreateContactWithData(var Contact: Record Contact)
    var
        CountryRegion: Record "Country/Region";
        Currency: Record Currency;
        Territory: Record Territory;
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Contact.Validate("Country/Region Code", CountryRegion.Code);
        LibraryERM.CreateCurrency(Currency);
        Contact.Validate("Currency Code", Currency.Code);
        LibraryERM.CreateTerritory(Territory);
        Contact.Validate("Territory Code", Territory.Code);
        Contact.Modify(true);
    end;

    local procedure CreateContactWithToDos(var Contact: Record Contact)
    var
        Task: array[2] of Record "To-do";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateAndUpdateTask(Task[1], Contact);
        CreateAndUpdateTask(Task[2], Contact);
        Task[2].Validate("Organizer To-do No.", Task[1]."Organizer To-do No.");
        Task[2].Modify(true);
    end;

    local procedure CreateAndUpdateTask(var Task: Record "To-do"; Contact: Record Contact)
    begin
        LibraryMarketing.CreateTask(Task);
        Task.Validate(Date, WorkDate());
        Task.Validate("Contact No.", Contact."No.");
        Task.Validate("Salesperson Code", Contact."Salesperson Code");
        Task.Modify(true);
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code"; "Code": Code[20]; City: Text[30]; CountryCode: Code[10]; County: Text[30])
    begin
        PostCode.Init();
        PostCode.Code := Code;
        PostCode.City := City;
        PostCode."Search City" := City;
        PostCode."Country/Region Code" := CountryCode;
        PostCode.County := County;
        PostCode.Insert();
    end;

    local procedure DeleteCustomerTemplates()
    var
        CustomerTemplate: Record "Customer Templ.";
    begin
        CustomerTemplate.DeleteAll();
    end;

    local procedure FindContactBusinessRelation(var ContactBusinessRelation: Record "Contact Business Relation"; BusinessRelationCode: Code[20]; LinkToTable: Enum "Contact Business Relation Link To Table"; No: Code[20])
    begin
        ContactBusinessRelation.SetRange("Business Relation Code", BusinessRelationCode);
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetFilter("No.", No);
        ContactBusinessRelation.FindFirst();
    end;

    local procedure GetCustFromContact(ContactNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.FindFirst();
        exit(ContactBusinessRelation."No.");
    end;

    local procedure GetBusinessRelationCodeFromSetup(LinkToTable: Enum "Contact Business Relation Link To Table"): Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
        ContactBusinessRelation: Record "Contact Business Relation";
        BusinessRelation: Record "Business Relation";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        case LinkToTable of
            ContactBusinessRelation."Link to Table"::Customer:
                begin
                    ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);
                    MarketingSetup.Get();
                    exit(MarketingSetup."Bus. Rel. Code for Customers");
                end;
            ContactBusinessRelation."Link to Table"::Vendor:
                begin
                    ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
                    MarketingSetup.Get();
                    exit(MarketingSetup."Bus. Rel. Code for Vendors");
                end;
        end;
    end;

    local procedure FindCustomerByCompanyName(var Customer: Record Customer; CompanyName: Text[100])
    begin
        Customer.SetRange(Name, CompanyName);
        Customer.FindFirst();
    end;

    local procedure NextStepMakePhoneCallWizard(var TempSegmentLine: Record "Segment Line" temporary)
    begin
        TempSegmentLine.Modify();
        TempSegmentLine.CheckPhoneCallStatus();
    end;

    local procedure OpenContactCard(var ContactCard: TestPage "Contact Card"; Contact: Record Contact)
    begin
        ContactCard.OpenView();
        ContactCard.GotoRecord(Contact);
    end;

    [HandlerFunctions('MyNotificationsModalPageHandler')]
    local procedure OpenMyNotificationsFromSettings()
    var
        UserSettings: TestPage "User Settings";
    begin
        UserSettings.OpenEdit();
        UserSettings.MyNotificationsLbl.DrillDown();
        UserSettings.Close();
    end;

    local procedure PrintSalesQuoteReport(SalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        Commit();
        SalesQuote.Print.Invoke();
    end;

    local procedure ReplaceBusRelationCode(ContactNo: Code[20])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        BusinessRelation: Record "Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.FindFirst();
        ContactBusinessRelation.Delete();
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ContactBusinessRelation."Business Relation Code" := BusinessRelation.Code;
        ContactBusinessRelation.Insert();
    end;

    local procedure RunCompanyDetails(Contact: Record Contact)
    var
        CompanyDetails: Page "Company Details";
    begin
        Clear(CompanyDetails);
        Contact.SetRange("No.", Contact."No.");
        CompanyDetails.SetTableView(Contact);
        CompanyDetails.SetRecord(Contact);
        CompanyDetails.RunModal();
    end;

    local procedure RunNameDetails(Contact: Record Contact)
    var
        NameDetails: Page "Name Details";
    begin
        Clear(NameDetails);
        Contact.SetRange("No.", Contact."No.");
        NameDetails.SetTableView(Contact);
        NameDetails.SetRecord(Contact);
        NameDetails.RunModal();
    end;

    local procedure RunCreateContsFromCustomersReport(var Customer: Record Customer)
    var
        CreateContsFromCustomers: Report "Create Conts. from Customers";
    begin
        CreateContsFromCustomers.UseRequestPage(false);
        CreateContsFromCustomers.SetTableView(Customer);
        CreateContsFromCustomers.Run();
    end;

    local procedure RunCreateContsFromVendorsReport(var Vendor: Record Vendor)
    var
        CreateContsFromVendors: Report "Create Conts. from Vendors";
    begin
        CreateContsFromVendors.UseRequestPage(false);
        CreateContsFromVendors.SetTableView(Vendor);
        CreateContsFromVendors.Run();
    end;

    local procedure SalesQuoteContactNoLookup(var SalesHeader: Record "Sales Header")
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote."Sell-to Contact No.".Lookup();
        SalesQuote.Close();
        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesHeader."No.");
    end;

    local procedure SetAddress(var Contact: Record Contact)
    begin
        Contact.Address := CopyStr(CreateGuid(), 2, 30);
        Contact."Address 2" := CopyStr(CreateGuid(), 2, 30);
        Contact.City := CopyStr(CreateGuid(), 2, 30);
        Contact.County := CopyStr(CreateGuid(), 2, 30);
        Contact."Post Code" := CopyStr(CreateGuid(), 2, 20);
    end;

    local procedure UpdateContactCompanyDetails(var Contact: Record Contact; ContactPostCode: Code[20]; ContactCountryRegionCode: Code[10]; ContactPhoneNumber: Text[30])
    begin
        Contact.Validate("Country/Region Code", ContactCountryRegionCode);
        Contact.Validate("Post Code", ContactPostCode);
        Contact.Validate(Name, ContactPostCode);  // Input the same value as value is not important.
        Contact.Validate(Address, ContactPostCode);  // Input the same value as value is not important.
        Contact.Validate("Phone No.", ContactPhoneNumber);
        Contact.Validate("Fax No.", ContactPhoneNumber);
        Contact.Modify(true);
    end;

    local procedure UpdateContactNameDetails(var Contact: Record Contact; ContactSalutationCode: Code[10]; ContactLanguageCode: Code[10])
    begin
        Contact.Validate("Salutation Code", ContactSalutationCode);
        Contact.Validate(Name, ContactSalutationCode);  // Input the same value as value is not important.
        Contact.Validate("Job Title", ContactSalutationCode);  // Input the same value as value is not important.
        Contact.Validate(Initials, CopyStr(ContactSalutationCode, 1, 2));  // Input first two characters of Salutation Code as Initials.
        Contact.Validate("Language Code", ContactLanguageCode);
        Contact.Modify(true);
    end;

    local procedure UpdateNameOnContactCard(No: Code[20]; Name: Text[100])
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", No);
        ContactCard.Name.SetValue(Name);
        ContactCard.OK().Invoke();
    end;

    local procedure VerifySameAddress(ExpectedContact: Record Contact; ActualContact: Record Contact)
    begin
        Assert.AreEqual(ExpectedContact.Address, ActualContact.Address, 'Field value didn''t get updated.');
        Assert.AreEqual(ExpectedContact."Address 2", ActualContact."Address 2", 'Field value didn''t get updated.');
        Assert.AreEqual(ExpectedContact.City, ActualContact.City, 'Field value didn''t get updated.');
        Assert.AreEqual(ExpectedContact.County, ActualContact.County, 'Field value didn''t get updated.');
        Assert.AreEqual(ExpectedContact."Post Code", ActualContact."Post Code", 'Field value didn''t get updated.');
    end;

    local procedure VerifyContactCompanyDetails(var Contact: Record Contact; ContactPostCode: Code[20]; ContactCountryRegionCode: Code[10]; ContactPhoneNumber: Text[30])
    begin
        Contact.TestField("Post Code", ContactPostCode);
        Contact.TestField(Name, ContactPostCode);
        Contact.TestField(Address, ContactPostCode);
        Contact.TestField("Country/Region Code", ContactCountryRegionCode);
        Contact.TestField("Phone No.", ContactPhoneNumber);
        Contact.TestField("Fax No.", ContactPhoneNumber);
    end;

    local procedure VerifyContactNameDetails(var Contact: Record Contact; ContactSalutationCode: Code[10]; ContactLanguageCode: Code[10])
    begin
        Contact.TestField("Salutation Code", ContactSalutationCode);
        Contact.TestField(Name, ContactSalutationCode);
        Contact.TestField("Job Title", ContactSalutationCode);
        Contact.TestField(Initials, CopyStr(ContactSalutationCode, 1, 2));  // Since first two characters were input as Initials.
        Contact.TestField("Language Code", ContactLanguageCode);
    end;

    local procedure VerifyContact(ContactNo: Code[20]; ContactType: Enum "Contact Type"; ContactName: Text[100]; ContactPhoneNo: Text[30])
    var
        Contact: Record Contact;
    begin
        Contact.Get(ContactNo);
        Contact.TestField(Type, ContactType);
        Contact.TestField(Name, ContactName);
        Contact.TestField("Phone No.", ContactPhoneNo);
    end;

    local procedure VerifyCustomerCreatedByContact(CustomerTemplate: Record "Customer Templ."; ContactNo: Code[20]; CustomerPriceGroupCode: Code[10])
    var
        Customer: Record Customer;
    begin
        Customer.Get(GetCustFromContact(ContactNo));

        Customer.TestField("Customer Price Group", CustomerPriceGroupCode);
        Customer.TestField("Gen. Bus. Posting Group", CustomerTemplate."Gen. Bus. Posting Group");
        Customer.TestField("VAT Bus. Posting Group", CustomerTemplate."VAT Bus. Posting Group");
        Customer.TestField("Customer Posting Group", CustomerTemplate."Customer Posting Group");
        Customer.TestField("Allow Line Disc.", CustomerTemplate."Allow Line Disc.");
        Customer.TestField("Payment Method Code", CustomerTemplate."Payment Method Code");
        Customer.TestField("Payment Terms Code", CustomerTemplate."Payment Terms Code");
        Customer.TestField("Shipment Method Code", CustomerTemplate."Shipment Method Code");
        Customer.TestField("Invoice Disc. Code");
        Customer.TestField("Territory Code", CustomerTemplate."Territory Code");
        Customer.TestField("Country/Region Code", CustomerTemplate."Country/Region Code");
        Customer.TestField("Currency Code", CustomerTemplate."Currency Code");
    end;

    local procedure VerifyCustomerInheritsDataFromContact(Contact: Record Contact)
    var
        Customer: Record Customer;
    begin
        Customer.Get(GetCustFromContact(Contact."No."));
        Customer.TestField("Currency Code", Contact."Currency Code");
        Customer.TestField("Country/Region Code", Contact."Country/Region Code");
        Customer.TestField("Territory Code", Contact."Territory Code");
    end;

    local procedure VerifyContactErrorMessage(FieldCaptionOfMarketingField: Text[30])
    begin
        Assert.ExpectedTestFieldError(FieldCaptionOfMarketingField, '');
    end;

    local procedure VerifyContactBusinessRelationForLinkTableAndContact(ContactNo: Code[20]; LinkNo: Code[20]; LinkToTable: Enum "Contact Business Relation Link To Table")
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.SetRange("No.", LinkNo);
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        Assert.RecordIsNotEmpty(ContactBusinessRelation);
    end;

    local procedure VerifyNoContactBusinessRelationForLinkTableAndContact(ContactNo: Code[20]; LinkNo: Code[20]; LinkToTable: Enum "Contact Business Relation Link To Table")
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.SetRange("No.", LinkNo);
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        Assert.RecordIsEmpty(ContactBusinessRelation);
    end;

    local procedure VerifyContactBusinessRelationHasNoBlankValue(LinkToTable: Enum "Contact Business Relation Link To Table")
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("No.", '');
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        Assert.RecordIsEmpty(ContactBusinessRelation);
    end;

    local procedure VerifyContactNotExistWithCompanyNo(CompanyNo: Code[20]; ContactType: Enum "Contact Type")
    var
        Contact: Record Contact;
    begin
        Contact.SetRange("Company No.", CompanyNo);
        Contact.SetRange(Type, ContactType);
        Assert.RecordIsEmpty(Contact);
    end;

    local procedure CreateContactNameWithBrackets() "Code": Code[20]
    begin
        Code := LibraryUtility.GenerateGUID();
        Code[StrLen(Code) + 1] := ')';
        Code[StrLen(Code) div 2] := '(';
        exit(Code);
    end;

    local procedure UpdateCompanyInformationPaymentInfo(AllowBlankPaymentInfo: Boolean)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Allow Blank Payment Info.", AllowBlankPaymentInfo);
        CompanyInformation.Modify();
    end;

    local procedure VerifyContactCoverSheetCompanyInfoReport()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryReportDataset.AssertElementWithValueExists('CompanyAddress1', CompanyInformation.Name);
        LibraryReportDataset.AssertElementWithValueExists('CompanyAddress2', CompanyInformation.Address);
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationPhoneNo', CompanyInformation."Phone No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationGiroNo', CompanyInformation."Giro No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationVATRegNo', CompanyInformation."VAT Registration No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationBankName', CompanyInformation."Bank Name");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationBankAccountNo', CompanyInformation."Bank Account No.");
        LibraryReportDataset.AssertElementWithValueExists('Document_Date', Format(WorkDate(), 0, 4));
    end;

    local procedure VerifyContactCoverSheetContactInfoReport(Contact: Record Contact)
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(Contact."Country/Region Code");
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress1', Contact.Name);
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress2', Contact.Address);
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress3', Contact."Address 2");
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress4', Contact.City + ', ' + Contact."Post Code");
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress5', Contact.County);
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress6', CountryRegion.Name);
    end;

    local procedure CreateBusinessRelationBetweenContactAndVendor(ContactNo: Code[20]; VendorNo: Code[20])
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        LibraryMarketing.CreateContactBusinessRelation(ContactBusinessRelation, ContactNo, BusinessRelation.Code);
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Vendor;
        ContactBusinessRelation."No." := VendorNo;
        ContactBusinessRelation.Modify(true);
    end;

    local procedure CreateBusinessRelationBetweenContactAndBankAccount(ContactNo: Code[20]; BankAccountNo: Code[20])
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        LibraryMarketing.CreateContactBusinessRelation(ContactBusinessRelation, ContactNo, BusinessRelation.Code);
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::"Bank Account";
        ContactBusinessRelation."No." := BankAccountNo;
        ContactBusinessRelation.Modify(true);
    end;

    local procedure CreateBusinessRelationBetweenContactAndEmployee(ContactNo: Code[20]; EmployeeNo: Code[20])
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        LibraryMarketing.CreateContactBusinessRelation(ContactBusinessRelation, ContactNo, BusinessRelation.Code);
        ContactBusinessRelation."Link to Table" := ContactBusinessRelation."Link to Table"::Employee;
        ContactBusinessRelation."No." := EmployeeNo;
        ContactBusinessRelation.Modify(true);
    end;

    local procedure CreateContactWithPhoneEmail(var Contact: Record Contact; CompanyContactCompanyNo: Code[20])
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Company No.", CompanyContactCompanyNo);
        Contact.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        Contact.Validate("Mobile Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        Contact.Validate("E-mail", LibraryUtility.GenerateRandomEmail());
        Contact.Modify(true);
    end;

    local procedure CreateAndPostItemJournal(ItemNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        ClearJournal(ItemJournalBatch);  // Clear Item Journal Template and Journal Batch.
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(10) + 10);  // Value important for test.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate: Record "Item Journal Template"; var ItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure ClearJournal(ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure CreateVendorTemplateForContact(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        VendorTemplate: Record "Vendor Templ.";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LibraryTemplates.CreateVendorTemplate(VendorTemplate);
        LibraryVariableStorage.Enqueue(VendorTemplate.Code);

        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);

        VendorTemplate.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
        VendorTemplate.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        VendorTemplate.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        VendorTemplate.Modify();

        exit(VendorTemplate.Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NameDetailsModalFormHandler(var NameDetails: Page "Name Details"; var Reply: Action)
    var
        Contact: Record Contact;
    begin
        Contact.Init();  // Required to initialize the variable.
        NameDetails.GetRecord(Contact);
        UpdateContactNameDetails(Contact,
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Salutation Code")),
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Language Code")));
        Reply := ACTION::OK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyNameModalFormHandler(var NameDetails: Page "Name Details"; var Reply: Action)
    var
        Contact: Record Contact;
    begin
        Contact.Init();  // Required to initialize the variable.
        NameDetails.GetRecord(Contact);
        VerifyContactNameDetails(Contact,
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Salutation Code")),
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Language Code")));
        Reply := ACTION::OK;
    end;

    local procedure VerifyOpportunityEntry(OppNo: Code[20]; ExpectedValue: Decimal)
    var
        OpportunityEntry: Record "Opportunity Entry";
    begin
        OpportunityEntry.SetRange("Opportunity No.", OppNo);
        OpportunityEntry.SetRange(Active, true);
        OpportunityEntry.FindFirst();
        Assert.AreEqual(
          ExpectedValue, OpportunityEntry."Calcd. Current Value (LCY)",
          StrSubstNo(WrongCalcdCurValueErr, OpportunityEntry.FieldCaption("Calcd. Current Value (LCY)")));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CompanyDetailsModalFormHandler(var CompanyDetails: Page "Company Details"; var Reply: Action)
    var
        Contact: Record Contact;
    begin
        Contact.Init();  // Required to initialize the variable.
        CompanyDetails.GetRecord(Contact);
        UpdateContactCompanyDetails(
          Contact,
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Post Code")),
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Country/Region Code")),
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Phone No.")));
        Reply := ACTION::OK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyCompanyModalFormHandler(var CompanyDetails: Page "Company Details"; var Reply: Action)
    var
        Contact: Record Contact;
    begin
        Contact.Init();  // Required to initialize the variable.
        CompanyDetails.GetRecord(Contact);
        VerifyContactCompanyDetails(
          Contact,
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Post Code")),
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Country/Region Code")),
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(Contact."Phone No.")));
        Reply := ACTION::OK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTempModalFormHandler(var CustomerTemplateList: Page "Select Customer Templ. List"; var Reply: Action)
    var
        CustomerTemplate: Record "Customer Templ.";
    begin
        CustomerTemplate.Init();  // Required to initialize the variable.
        CustomerTemplate.Get(LibraryVariableStorage.DequeueText());
        CustomerTemplateList.SetRecord(CustomerTemplate);
        Reply := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractModalFormHandler(var CreateInteraction: Page "Create Interaction"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
        InteractionTemplateCode: Code[10];
    begin
        TempSegmentLine.Init();  // Required to initialize the variable.
        CreateInteraction.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();  // Insert temporary Segment Line to modify fields later.
        InteractionTemplateCode :=
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TempSegmentLine."Interaction Template Code"));
        TempSegmentLine.Validate("Interaction Template Code", InteractionTemplateCode);
        TempSegmentLine.Validate(Description, InteractionTemplateCode);
        NextStepMakePhoneCallWizard(TempSegmentLine);
        NextStepMakePhoneCallWizard(TempSegmentLine);

        TempSegmentLine."Cost (LCY)" := LibraryVariableStorage.DequeueDecimal();
        TempSegmentLine."Duration (Min.)" := LibraryVariableStorage.DequeueDecimal();
        TempSegmentLine.Modify(true);
        TempSegmentLine.FinishSegLineWizard(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractFinishModalFormHandler(var CreateInteraction: Page "Create Interaction"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
        InteractionTemplateCode: Code[10];
        FinishInteraction: Boolean;
    begin
        TempSegmentLine.Init();  // Required to initialize the variable.
        CreateInteraction.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();  // Insert temporary Segment Line to modify fields later.
        InteractionTemplateCode :=
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TempSegmentLine."Interaction Template Code"));
        TempSegmentLine.Validate("Interaction Template Code", InteractionTemplateCode);
        TempSegmentLine.Validate(Description, InteractionTemplateCode);

        TempSegmentLine."Cost (LCY)" := LibraryVariableStorage.DequeueDecimal();
        TempSegmentLine."Duration (Min.)" := LibraryVariableStorage.DequeueDecimal();
        FinishInteraction := LibraryVariableStorage.DequeueBoolean();
        TempSegmentLine.Modify(true);
        if FinishInteraction then
            TempSegmentLine.FinishSegLineWizard(true)
        else
            TempSegmentLine.FinishSegLineWizard(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractModalPageHandler(var CreateInteraction: TestPage "Create Interaction")
    begin
        CreateInteraction."Salesperson Code".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateOpportModalFormHandler(var CreateOpportunity: Page "Create Opportunity"; var Reply: Action)
    var
        TempOpportunity: Record Opportunity temporary;
        SalesCycleCode: Code[10];
    begin
        TempOpportunity.Init();  // Required to initialize the variable.
        CreateOpportunity.GetRecord(TempOpportunity);
        TempOpportunity.Insert();  // Insert temporary Opportunity to modify fields later.
        SalesCycleCode :=
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TempOpportunity."Sales Cycle Code"));
        TempOpportunity.Validate(Description, SalesCycleCode);
        TempOpportunity.Validate("Sales Cycle Code", SalesCycleCode);
        TempOpportunity.Validate("Activate First Stage", true);
        TempOpportunity.Validate("Wizard Estimated Value (LCY)", LibraryVariableStorage.DequeueDecimal());
        TempOpportunity.Validate("Wizard Chances of Success %", LibraryVariableStorage.DequeueDecimal());
        TempOpportunity.Modify();
        TempOpportunity.FinishWizard();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CloseOpportModalFormHandler(var CloseOpportunity: Page "Close Opportunity"; var Reply: Action)
    var
        TempOpportunityEntry: Record "Opportunity Entry" temporary;
    begin
        TempOpportunityEntry.Init();  // Required to initialize the variable.
        CloseOpportunity.GetRecord(TempOpportunityEntry);
        TempOpportunityEntry.Insert();
        TempOpportunityEntry.Validate("Action Taken", TempOpportunityEntry."Action Taken"::Won);
        TempOpportunityEntry.Validate("Close Opportunity Code",
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TempOpportunityEntry."Close Opportunity Code")));
        TempOpportunityEntry.Validate("Calcd. Current Value (LCY)", LibraryVariableStorage.DequeueDecimal());
        TempOpportunityEntry.Modify();
        TempOpportunityEntry.CheckStatus();
        TempOpportunityEntry.FinishWizard();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListModalPageHandler(var ContactList: TestPage "Contact List")
    var
        Contact: Record Contact;
    begin
        Contact.Get(LibraryVariableStorage.DequeueText());
        ContactList.GotoRecord(Contact);
        ContactList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.ToField.AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTempModalPageHandlerWithEnqueue(var CustomerTemplateList: Page "Select Customer Templ. List"; var Reply: Action)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerTemplate: Record "Customer Templ.";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerTemplate.Get(CreateCustomerTemplateForContact(VATPostingSetup."VAT Bus. Posting Group"));
        CustomerTemplateList.SetRecord(CustomerTemplate);
        LibraryVariableStorage.Enqueue(CustomerTemplate.Code);
        Reply := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    procedure CustomerTemplateHandler(var CustomerTemplateList: Page "Select Customer Templ. List"; var Reply: Action)
    var
        CustomerTemplate: Record "Customer Templ.";
    begin
        CustomerTemplate.Get(LibraryVariableStorage.DequeueText());
        CustomerTemplateList.SetRecord(CustomerTemplate);
        Reply := ACTION::LookupOK;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalseWithTextVerification(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, 'Unexpected confirmation message');
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormMarketingSetup(var MarketingSetup: Page "Marketing Setup"; var Response: Action)
    var
        MarketingSetup2: Record "Marketing Setup";
    begin
        MarketingSetup.GetRecord(MarketingSetup2);
        MarketingSetup2."Attachment Storage Type" := MarketingSetup2."Attachment Storage Type"::"Disk File";
        MarketingSetup.SetRecord(MarketingSetup2);
        MarketingSetup.SetAttachmentStorageType();

        MarketingSetup2.Get();
        MarketingSetup2."Attachment Storage Location" := TemporaryPath;
        MarketingSetup.SetRecord(MarketingSetup2);
        MarketingSetup.SetAttachmentStorageLocation();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountLinkPageHandler(var BankAccountLink: TestPage "Bank Account Link")
    var
        CurrMasterFields: Option Contact,Bank;
    begin
        BankAccountLink."No.".SetValue(LibraryVariableStorage.DequeueText());
        BankAccountLink.CurrMasterFields.SetValue(CurrMasterFields::Bank);  // Taking Value from Base Page's Option.
        BankAccountLink.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLinkPageHandler(var CustomerLink: TestPage "Customer Link")
    begin
        CustomerLink."No.".SetValue(LibraryVariableStorage.DequeueText());
        CustomerLink.CurrMasterFields.SetValue(LibraryVariableStorage.DequeueInteger());  // Taking Value from Base Page's Option from test case.
        CustomerLink.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLinkPageHandler(var VendorLink: TestPage "Vendor Link")
    var
        CurrMasterFields: Option Contact,Vendor;
    begin
        VendorLink."No.".SetValue(LibraryVariableStorage.DequeueText());
        VendorLink.CurrMasterFields.SetValue(CurrMasterFields::Vendor);  // Taking Value from Base Page's Option.
        VendorLink.OK().Invoke();
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    local procedure UpdateSameBusinessRelationCodeOnMarketingSetup(BusRelCode: Code[10])
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Bus. Rel. Code for Customers", BusRelCode);
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", BusRelCode);
        MarketingSetup.Validate("Bus. Rel. Code for Employees", BusRelCode);
        MarketingSetup.Validate("Bus. Rel. Code for Bank Accs.", BusRelCode);
        MarketingSetup.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardQuoteReportRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContactCoverSheetReportRequestPageHandler(var CoverSheet: TestRequestPage "Contact Cover Sheet")
    begin
        CoverSheet.LogInteraction.SetValue(LibraryVariableStorage.DequeueBoolean());
        CoverSheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateListPageHandler(var CustomerTemplateList: TestPage "Select Customer Templ. List")
    begin
        CustomerTemplateList.First();
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), CustomerTemplateList.Code.Value, CustTemplateListErr);
        CustomerTemplateList.Next();
        Assert.IsFalse(CustomerTemplateList.Next(), CustTemplateListErr);
        CustomerTemplateList.First();
        CustomerTemplateList.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure NotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MyNotificationsModalPageHandler(var MyNotifications: TestPage "My Notifications")
    begin
        MyNotifications.FILTER.SetFilter("Notification Id", CustomerContNotifTok);
        MyNotifications.Enabled.SetValue(LibraryVariableStorage.DequeueBoolean());
        MyNotifications.FILTER.SetFilter("Notification Id", VendorContNotifTok);
        MyNotifications.Enabled.SetValue(LibraryVariableStorage.DequeueBoolean());
    end;

    [ModalPageHandler]
    procedure ModalPageHandlerForTask(var CreateTask: Page "Create Task"; var Response: Action)
    var
        TempTask: Record "To-do" temporary;
    begin
        TempTask.Init();
        CreateTask.GetRecord(TempTask);
        TempTask.Insert();
        TempTask.Validate(Type, TempTask.Type::"Phone Call");
        TempTask.Validate(
          Description,
          CopyStr(
            LibraryUtility.GenerateRandomCode(TempTask.FieldNo(Description), DATABASE::"To-do"),
            1, LibraryUtility.GetFieldLength(DATABASE::"To-do", TempTask.FieldNo(Description))));
        TempTask.Validate(Date, WorkDate());

        TempTask.Modify();
        TempTask.CheckStatus();
        TempTask.FinishWizard(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListLookupModalPageHandler(var ContactList: TestPage "Contact List")
    begin
        ContactList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ContactList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ModalSelectCustomerTemplListHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VendorTempModalFormHandler(var VendorTemplateList: Page "Select Vendor Templ. List"; var Reply: Action)
    var
        VendorTemplate: Record "Vendor Templ.";
    begin
        VendorTemplate.Init();  // Required to initialize the variable.
        VendorTemplate.Get(LibraryVariableStorage.DequeueText());
        VendorTemplateList.SetRecord(VendorTemplate);
        Reply := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure VendorTempModalPageHandlerWithEnqueue(var VendorTemplateList: Page "Select Vendor Templ. List"; var Reply: Action)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorTemplate: Record "Vendor Templ.";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        VendorTemplate.Get(CreateVendorTemplateForContact(VATPostingSetup."VAT Bus. Posting Group"));
        VendorTemplateList.SetRecord(VendorTemplate);
        LibraryVariableStorage.Enqueue(VendorTemplate.Code);

        Reply := Action::LookupOK;
    end;

    [ModalPageHandler]
    procedure VendorTemplateHandler(var VendorTemplateList: Page "Select Vendor Templ. List"; var Reply: Action)
    var
        VendorTemplate: Record "Vendor Templ.";
    begin
        VendorTemplate.Get(LibraryVariableStorage.DequeueText());
        VendorTemplateList.SetRecord(VendorTemplate);
        Reply := Action::LookupOK;
    end;

    [SendNotificationHandler]
    procedure DuplicateContactsNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Customer Templ. Mgt.", 'OnAfterIsEnabled', '', false, false)]
    local procedure OnAfterIsEnabledCustTemplate(var Result: Boolean)
    begin
        Result := true;
    end;
}

