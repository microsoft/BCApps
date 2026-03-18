codeunit 134626 "Person and Company Contacts"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Contact] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryUtility: Codeunit "Library - Utility";
        RelatedRecordIsCreatedMsg: Label 'The %1 record has been created.', Comment = 'The Customer record has been created.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTemplates: Codeunit "Library - Templates";

    [Test]
    [Scope('OnPrem')]
    procedure CreatePersonContactNotCreateCustomerAutomatically()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // Setup
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Exercise
        CreateContactUsingContactCard(Contact);

        // Verify
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        Assert.RecordIsEmpty(ContactBusinessRelation);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateListModalPageHandler,DismissMessageAboutCreatingCustomer')]
    [Scope('OnPrem')]
    procedure CreateCustomerForPersonContactWithSameDetails()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        CustomerTempl: Record "Customer Templ.";
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);
        CustomerTempl."Contact Type" := CustomerTempl."Contact Type"::Person;
        CustomerTempl.Modify(true);

        // Setup
        CreateContactUsingContactCard(Contact);

        // Exercise
        CreateCustomerFromContactUsingContactCard(Contact);

        // Verify
        AssertContactBusinessRelationExists(ContactBusinessRelation, Contact."No.");
        AssertCustomerDeailsAreEqualToContactDetails(ContactBusinessRelation);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateVendorForPersonContactFails()
    var
        Contact: Record Contact;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        CreateContactUsingContactCard(Contact);

        // Exercise
        asserterror CreateVendorFromContactUsingContactCard(Contact);

        // Verify
        Assert.ExpectedTestFieldError(Contact.FieldCaption("Company No."), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateBankForPersonContactFails()
    var
        Contact: Record Contact;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        CreateContactUsingContactCard(Contact);

        // Exercise
        asserterror CreateBankAccountFromContactUsingContactCard(Contact);

        // Verify
        Assert.ExpectedTestFieldError(Contact.FieldCaption("Company No."), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetCompanyWithSameNameAsContactToCompanyName()
    var
        PersContact: Record Contact;
        CompContact: Record Contact;
    begin
        // [SCENARIO 382416] If there are Personal and Company Contact with the same name, it should be possible to set this name as Company Name in Personal Contact
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Personal Contact with the name "Stan"
        LibraryMarketing.CreatePersonContact(PersContact);
        PersContact.Validate(Name, CopyStr(PersContact.Name, 1, 1));
        PersContact.Modify(true);

        // [GIVEN] Company Contact with the name "Stan"
        LibraryMarketing.CreateCompanyContact(CompContact);
        CompContact.Validate(Name, CopyStr(CompContact.Name, 1, 1));
        CompContact.Modify(true);

        // [WHEN] "Stan" is specified as "Company Name" in Personal Contact
        PersContact.Validate("Company Name", CompContact.Name);

        // [THEN] "Stan" Company is set as Company Name in Personal Contact
        PersContact.TestField("Company Name", CompContact.Name);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DismissMessageAboutCreatingCustomer,CustomerTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateQuotesOnlyUpdatesForCorrectContact()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
        Customer: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 221218] When creating a Customer from a Contact not tied to a company, only that contact's quotes should be updated
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        // [GIVEN] A Quote for a Customer created from a person Contact not linked to a Company
        SetUpCustomerTemplate();
        CreateContactAndCustomer(Contact, Customer);
        Contact.TestField("Company No.", '');
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader, Customer."No.");

        // Exercise
        // [WHEN] A second Customer is created from a person Contact not linked to a Company
        CreateContactAndCustomer(Contact2, Customer2);
        Contact2.TestField("Company No.", '');

        // Verify
        // [THEN] The Quote is still assigned to the first Customer
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.TestField("Sell-to Customer No.", Customer."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CompanyContactOfCustomerCreatedFromTepmplate()
    var
        CustomerTempl: Record "Customer Templ.";
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
    begin
        // [FEATURE] [Rapid Start]
        // [SCENARIO 287941] Customer's Contact field "Type" is equal to Company when Customer created from template
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Customer template with field's "Contact Type" Default Value set to Person
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTempl);
        CustomerTempl."Contact Type" := CustomerTempl."Contact Type"::Person;
        CustomerTempl.Modify(true);

        // [WHEN] Customer with contact "C" created from template
        LibraryVariableStorage.Enqueue(CustomerTempl.Code);
        CustomerTemplMgt.InsertCustomerFromTemplate(Customer);

        // [THEN] Contact's "C" field "Type" is equal to Company
        ContactBusinessRelation.FindByRelation(ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
        Contact.Get(ContactBusinessRelation."Contact No.");
        Contact.TestField(Type, Contact.Type::Person);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CutomerCreatedFromContactWitNoEqualToNoOfExistingCustomer()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
        CustomerTemplate: Record "Customer Templ.";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 285903] Stan creates new Customer from Contact with "No." equal to existing Customer "No."
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Customer and Contact with No. "X"
        CustomerNo := LibrarySales.CreateCustomerNo();
        Contact.Init();
        Contact."No." := CustomerNo;
        Contact.Insert(true);

        // [WHEN] Stan tries to create Customer from Contact
        Contact.SetHideValidationDialog(true);
        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTemplate);
        Contact.CreateCustomerFromTemplate(CustomerTemplate.Code);

        // [THEN] Customer is created
        ContactBusinessRelation.FindByContact(ContactBusinessRelation."Link to Table"::Customer, Contact."No.");
        Customer.Get(ContactBusinessRelation."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('NameDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PersonNameAssistEditForNewContact()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        FirstName: Text;
        MiddleName: Text;
        Surname: Text;
    begin
        // [SCENARIO 285982] Name fields are populated on Name details page when opened from newly created Contact
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] New Contact Card page opened with "Type" set to 'Person' and "Name" field set to 'X Y Z'
        FirstName := LibraryUtility.GenerateGUID();
        MiddleName := LibraryUtility.GenerateGUID();
        Surname := LibraryUtility.GenerateGUID();

        ContactCard.OpenNew();
        ContactCard.Type.SetValue(Contact.Type::Person);
        ContactCard.Name.SetValue(StrSubstNo('%1 %2 %3', FirstName, MiddleName, Surname));

        // [WHEN] Name details page opened by pressing AssitEdit near "Name" field
        ContactCard.Name.AssistEdit();

        // [THEN] Name details page Name fields are equal to X, Y, Z respectively
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), FirstName, '');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), MiddleName, '');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Surname, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure CompanyNameAssistEditForNewContact()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        CompanyName: Text;
    begin
        // [SCENARIO 285982] Name field is populated on Company details page when opened from newly created Contact
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] New Contact Card page opened with "Type" set to 'Company' and "Name" field set to 'X'
        CompanyName := LibraryUtility.GenerateGUID();

        ContactCard.OpenNew();
        ContactCard.Type.SetValue(Contact.Type::Company);
        ContactCard.Name.SetValue(CompanyName);

        // [WHEN] Company details page opened by pressing AssitEdit near "Name" field
        ContactCard.Name.AssistEdit();
        ContactCard.Close();

        // [THEN] Company details page Name field is equal to X
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), CompanyName, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('NameDetailsErrorModalPageHandler')]
    [Scope('OnPrem')]
    procedure PersonNameAssistEditForNewContactWithError()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        FirstName: Text;
        MiddleName: Text;
        Surname: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 356053] Stan can close name details and contact card after validation error on name details page
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        FirstName := LibraryUtility.GenerateGUID();
        MiddleName := LibraryUtility.GenerateGUID();
        Surname := LibraryUtility.GenerateGUID();

        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(1);

        ContactCard.OpenNew();
        ContactCard.Type.SetValue(Contact.Type::Person);
        Contact.Get(ContactCard."No.".Value);
        ContactCard.Name.SetValue(StrSubstNo('%1 %2 %3', FirstName, MiddleName, Surname));

        ContactCard.Name.AssistEdit();
        ContactCard.Close();

        Contact.Find();
        Contact.TestField("First Name", FirstName);
        Contact.TestField(Surname, Surname);
        Contact.TestField("Middle Name", MiddleName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsErrorModalPageHandler')]
    [Scope('OnPrem')]
    procedure CompanyNameAssistEditForNewContactWithError()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        CompanyName: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 356053] Stan can close company details and contact card after validation error on company details page
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        CompanyName := LibraryUtility.GenerateGUID();

        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(1);

        ContactCard.OpenNew();
        ContactCard.Type.SetValue(Contact.Type::Company);
        Contact.Get(ContactCard."No.".Value);
        ContactCard.Name.SetValue(CompanyName);

        ContactCard.Name.AssistEdit();
        ContactCard.Close();

        Contact.Find();
        Contact.TestField("Company Name", CompanyName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeTypeOfNewContactLinkedToCustomer()
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 288436] Error is raised when trying to change Contact Type to Person, when Contact has Business relation with Customer
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Newly inserted Contact, Customer and BusinessRelation between them
        CustomerNo := LibrarySales.CreateCustomerNo();

        Contact.Init();
        Contact.Validate(Name, CustomerNo);
        Contact.Insert(true);

        LibraryMarketing.CreateBusinessRelationBetweenContactAndCustomer(ContactBusinessRelation, Contact."No.", CustomerNo);

        // [WHEN] Type of Contact changed to Person
        Contact.Type := Contact.Type::Person;
        asserterror Contact.TypeChange();

        // [THEN] Error is raised
        Assert.ExpectedTestFieldError(Contact.FieldCaption("No. of Business Relations"), Format(0));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyCompanyNameAssistEditDoesntOpen()
    var
        PersonContact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 299595] After invoking Assist Edit on an empty Company Name field, Company Details page doesn't open
        // [GIVEN] Created Person Contact without associating it to any Company No., and opened its Card
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        LibraryMarketing.CreatePersonContact(PersonContact);
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", PersonContact."No.");

        // [WHEN] Invoke Assist Edit on a 'Company Name' field
        ContactCard."Company Name".AssistEdit();

        LibraryVariableStorage.AssertEmpty();
        // [THEN] Company Details page hasn't been opened
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure ExistingCompanyNameAssistEditShowsProperly()
    var
        CompanyContact: Record Contact;
        PersonContact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 299595] After invoking Assist Edit on a filled Company Name field, proper Company Details page is shown
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Created Person Contact with associated Company, and opened its Card
        LibraryMarketing.CreateCompanyContact(CompanyContact);
        LibraryMarketing.CreatePersonContact(PersonContact);
        PersonContact.Validate("Company No.", CompanyContact."No.");
        PersonContact.Modify();
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", PersonContact."No.");

        // [WHEN] Invoke Assist Edit on a 'Company Name' field
        ContactCard."Company Name".AssistEdit();

        // [THEN] 'Name' field on Company Details page equals Company's Name
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), CompanyContact.Name, '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('NameDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure NameAssistEditOnPersonContactCardWithoutModifyPermissions()
    var
        Contact: Record Contact;
        ContactBackup: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [Permission] [Permission Set] [UI]
        // [SCENARIO 349009] Stan can't update person contact's name on name details page when Stan hasn't modify permissions
        Initialize();

        LibraryMarketing.CreatePersonContact(Contact);
        ContactBackup := Contact;

        LibraryLowerPermissions.SetOppMGT();

        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", Contact."No.");
        ContactCard.Name.AssistEdit();
        ContactCard.Name.AssertEquals(Contact.Name);
        ContactCard.Close();

        ContactBackup.TestField("First Name", LibraryVariableStorage.DequeueText());
        ContactBackup.TestField("Middle Name", LibraryVariableStorage.DequeueText());
        ContactBackup.TestField(Surname, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('NameDetailsOnChangeModalPageHandler')]
    [Scope('OnPrem')]
    procedure NameAssistEditOnPersonContactCardWithModifyPermissions()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        FirstName: Text;
        MiddleName: Text;
        Surname: Text;
    begin
        // [FEATURE] [Permissions] [Permission Set] [UI]
        // [SCENARIO 349009] Stan can update person contact's name on name details page when Stan has modify permissions
        Initialize();

        FirstName := LibraryUtility.GenerateGUID();
        MiddleName := LibraryUtility.GenerateGUID();
        Surname := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(FirstName);
        LibraryVariableStorage.Enqueue(MiddleName);
        LibraryVariableStorage.Enqueue(Surname);

        LibraryMarketing.CreatePersonContact(Contact);

        LibraryLowerPermissions.SetOppMGT();

        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", Contact."No.");
        ContactCard.Name.AssertEquals(Contact.Name);
        ContactCard.Name.AssistEdit();
        ContactCard.Name.AssertEquals(FirstName + ' ' + MiddleName + ' ' + Surname);
        ContactCard.Close();

        Contact.Find();
        Contact.TestField("First Name", FirstName);
        Contact.TestField("Middle Name", MiddleName);
        Contact.TestField(Surname, Surname);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure NameAssistEditOnCompanyContactCardWithoutModifyPermissions()
    var
        Contact: Record Contact;
        ContactBackup: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [Permission] [Permission Set] [UI]
        // [SCENARIO 349009] Stan can't update company contact's name on company details page when Stan hasn't modify permissions
        Initialize();

        LibraryMarketing.CreateCompanyContact(Contact);
        ContactBackup := Contact;

        LibraryLowerPermissions.SetOppMGT();

        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", Contact."No.");
        ContactCard.Name.AssistEdit();
        ContactCard."Company Name".AssertEquals(ContactBackup."Company Name");
        ContactCard.Close();

        Contact.Find();
        Contact.TestField("Company Name", ContactBackup."Company Name");
        ContactBackup.TestField("Company Name", LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsOnChangeModalPageHandler')]
    [Scope('OnPrem')]
    procedure NameAssistEditOnCompanyContactCardWithModifyPermissions()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        CompanyName: Text;
    begin
        // [FEATURE] [Permission] [Permission Set] [UI]
        // [SCENARIO 349009] Stan can update company contact's name on company details page when Stan has modify permissions
        Initialize();

        CompanyName := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(CompanyName);

        LibraryMarketing.CreateCompanyContact(Contact);

        LibraryLowerPermissions.SetOppMGT();

        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", Contact."No.");
        ContactCard.Name.AssistEdit();
        ContactCard."Company Name".AssertEquals(CompanyName);
        ContactCard.Close();

        Contact.Find();
        Contact.TestField("Company Name", CompanyName);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure CompanyNameAssistEditOnPersonContactCardWithoutPermissions()
    var
        ContactPerson: Record Contact;
        ContactCompany: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [Permission] [Permission Set] [UI]
        // [SCENARIO 349009] Stan can view person contact's company name on company details page when Stan hasn't modify permissions
        Initialize();

        // [GIVEN] New contact with "Company Name" = "Name"
        LibraryMarketing.CreatePersonContact(ContactPerson);
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        ContactPerson.Validate("Company No.", ContactCompany."No.");
        ContactPerson.Modify(true);

        // [GIVEN] User without Contact editing permisions
        LibraryLowerPermissions.SetOppMGT();

        // [GIVEN] Open its Card
        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", ContactPerson."No.");

        // [WHEN] User open Name Details assist edit dialog
        ContactCard."Company Name".AssistEdit();
        ContactCard.Close();

        ContactPerson.TestField("Company Name", ContactCompany.Name);
        ContactPerson.TestField("Company Name", LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CompanyDetailsModalPageHandler')]
    [Scope('OnPrem')]
    procedure CompanyNameAssistEditOnPersonContactCardWithPermissions()
    var
        ContactPerson: Record Contact;
        ContactCompany: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [Permission] [Permission Set] [UI]
        // [SCENARIO 349009] Stan can view person contact's company name on company details page when Stan hasn't modify permissions
        Initialize();

        LibraryMarketing.CreatePersonContact(ContactPerson);
        LibraryMarketing.CreateCompanyContact(ContactCompany);
        ContactPerson.Validate("Company No.", ContactCompany."No.");
        ContactPerson.Modify(true);

        LibraryLowerPermissions.SetOppMGT();

        ContactCard.OpenEdit();
        ContactCard.FILTER.SetFilter("No.", ContactPerson."No.");
        ContactCard."Company Name".AssertEquals(ContactPerson."Company Name");
        ContactCard."Company Name".AssistEdit();
        ContactCard."Company Name".AssertEquals(ContactPerson."Company Name");
        ContactCard.Close();

        ContactPerson.Find();
        ContactPerson.TestField("Company Name", ContactCompany."Company Name");
        ContactPerson.TestField("Company Name", LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PersonCustomerCreationSetsDefaultContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        // [FEATURE] [Contact] [Customer] [Person]
        // [SCENARIO 597848] When Customer of type Person is created, the default contact created is set as the 'Primary Contact No.'
        // on the Customer.
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [WHEN] Customer "C" of type Person is created
        LibrarySales.CreateCustomer(Customer, Customer."Contact Type"::Person);

        // [THEN] Contact and Business Relation are created for Customer
        AssertContactBusinessRelationExists(ContactBusinessRelation, Customer."Primary Contact No.");

        // [WHEN] Name on the Customer is set or modified
        Contact.Get(ContactBusinessRelation."Contact No.");
        Customer.Validate("Contact Type", Customer."Contact Type"::Person);
        Customer.Validate(Name, LibraryUtility.GenerateRandomText(50));
        Customer.Modify(true);

        // [GIVEN] A Contact "CONT1" is automatically updated with the same Name as the Customer
        Customer.TestField("Primary Contact No.");
        Customer.TestField(Contact, Customer.Name);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Person and Company Contacts");
        LibraryVariableStorage.Clear();
        LibraryTemplates.EnableTemplatesFeature();
    end;

    local procedure SetUpCustomerTemplate()
    var
        PaymentTerms: Record "Payment Terms";
        CustomerTemplate: Record "Customer Templ.";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PaymentTerms.FindFirst();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerTemplate.SetRange("Contact Type", CustomerTemplate."Contact Type"::Person);
        CustomerTemplate.FindFirst();
        CustomerTemplate."Payment Terms Code" := PaymentTerms.Code;
        CustomerTemplate."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        CustomerTemplate.Modify();

        LibraryTemplates.CreateCustomerTemplateWithData(CustomerTemplate);
        CustomerTemplate."Contact Type" := CustomerTemplate."Contact Type"::Person;
        CustomerTemplate.Modify();
    end;

    local procedure CreateContactUsingContactCard(var Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
        ContactName: Text[50];
    begin
        ContactName := LibraryUtility.GenerateGUID();

        ContactCard.OpenNew();
        ContactCard.Type.SetValue(Contact.Type::Person);
        ContactCard.Name.SetValue(ContactName);
        ContactCard.Close();

        Contact.SetRange(Name, ContactName);
        Contact.FindFirst();
    end;

    local procedure CreateCustomerFromContactUsingContactCard(Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");
        ContactCard.CreateCustomer.Invoke();
        ContactCard.Close();
    end;

    local procedure CreateVendorFromContactUsingContactCard(Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");
        ContactCard.CreateVendor.Invoke();
        ContactCard.Close();
    end;

    local procedure CreateBankAccountFromContactUsingContactCard(Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");
        ContactCard.CreateBank.Invoke();
        ContactCard.Close();
    end;

    local procedure CreateContactAndCustomer(var Contact: Record Contact; var Customer: Record Customer)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        MarketingSetup.Get();
        Contact.CreateCustomer();//(MarketingSetup."Cust. Template Person Code");
        GetCustomerFromContact(Contact, Customer);
    end;

    local procedure GetCustomerFromContact(Contact: Record Contact; var Customer: Record Customer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        ContactBusinessRelation.Get(Contact."No.", MarketingSetup."Bus. Rel. Code for Customers");
        Customer.Get(ContactBusinessRelation."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateListModalPageHandler(var CustomerTemplateList: TestPage "Select Customer Templ. List")
    begin
        CustomerTemplateList.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DismissMessageAboutCreatingCustomer(Message: Text[1024])
    var
        Customer: Record Customer;
    begin
        Assert.ExpectedMessage(StrSubstNo(RelatedRecordIsCreatedMsg, Customer.TableCaption()), Message);
    end;

    local procedure AssertContactBusinessRelationExists(var ContactBusinessRelation: Record "Contact Business Relation"; ContactNo: Code[20])
    begin
        ContactBusinessRelation.SetCurrentKey("Link to Table", "Contact No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        ContactBusinessRelation.FindFirst();
    end;

    local procedure AssertCustomerDeailsAreEqualToContactDetails(ContactBusinessRelation: Record "Contact Business Relation")
    var
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        Contact.Get(ContactBusinessRelation."Contact No.");
        Customer.Get(ContactBusinessRelation."No.");
        AssertCustomerBasicDetailsAreEqualToContactBasicDetails(Customer, Contact);
        AssertCustomerAddressDetailsAreEqualToContactAddressDetails(Customer, Contact);
    end;

    local procedure AssertCustomerBasicDetailsAreEqualToContactBasicDetails(Customer: Record Customer; Contact: Record Contact)
    begin
        Customer.TestField(Name, Contact.Name);
        Customer.TestField("Name 2", Contact."Name 2");
        Customer.TestField("E-Mail", Contact."E-Mail");
        Customer.TestField("Home Page", Contact."Home Page");
    end;

    local procedure AssertCustomerAddressDetailsAreEqualToContactAddressDetails(Customer: Record Customer; Contact: Record Contact)
    begin
        Customer.TestField(Address, Contact.Address);
        Customer.TestField("Address 2", Contact."Address 2");
        Customer.TestField("Post Code", Contact."Post Code");
        Customer.TestField("Phone No.", Contact."Phone No.");
        Customer.TestField("Fax No.", Contact."Fax No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListModalPageHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.GotoKey(LibraryVariableStorage.DequeueText());
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NameDetailsModalPageHandler(var NameDetails: TestPage "Name Details")
    begin
        LibraryVariableStorage.Enqueue(NameDetails."First Name".Value);
        LibraryVariableStorage.Enqueue(NameDetails."Middle Name".Value);
        LibraryVariableStorage.Enqueue(NameDetails.Surname.Value);
        NameDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CompanyDetailsModalPageHandler(var CompanyDetails: TestPage "Company Details")
    begin
        LibraryVariableStorage.Enqueue(CompanyDetails.Name.Value);
        CompanyDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NameDetailsErrorModalPageHandler(var NameDetails: TestPage "Name Details")
    begin
        asserterror NameDetails."Language Code".SetValue(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(LibraryVariableStorage.DequeueInteger(), NameDetails.ValidationErrorCount(), '');
        NameDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CompanyDetailsErrorModalPageHandler(var CompanyDetails: TestPage "Company Details")
    begin
        asserterror CompanyDetails."Country/Region Code".SetValue(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(LibraryVariableStorage.DequeueInteger(), CompanyDetails.ValidationErrorCount(), '');
        CompanyDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NameDetailsOnChangeModalPageHandler(var NameDetails: TestPage "Name Details")
    begin
        NameDetails."First Name".SetValue(LibraryVariableStorage.DequeueText());
        NameDetails."Middle Name".SetValue(LibraryVariableStorage.DequeueText());
        NameDetails.Surname.SetValue(LibraryVariableStorage.DequeueText());
        NameDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CompanyDetailsOnChangeModalPageHandler(var CompanyDetails: TestPage "Company Details")
    begin
        CompanyDetails.Name.SetValue(LibraryVariableStorage.DequeueText());
        CompanyDetails.OK().Invoke();
    end;
}
