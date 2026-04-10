codeunit 139048 "SMB Office Pages"
{
    Permissions = TableData "Sales Invoice Header" = im,
                  TableData "Active Session" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Add-in] [SMB]
    end;

    var
        LibraryMarketing: Codeunit "Library - Marketing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        OfficeHostType: DotNet OfficeHostType;
        CommandType: DotNet OutlookCommand;
        BusRelCodeForVendors: Code[10];
        BusRelCodeForCustomers: Code[10];
        IsInitialized: Boolean;
        AttachAvailableErr: Label 'Unexpected result of AttachAvailable for %1 Office Host Type.', Comment = '%1 = Office host type';

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineShowsWelcomePageForWelcomeMessage()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeWelcomeDlg: TestPage "Office Welcome Dlg";
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 164857] Stan is shown a welcome page if they open the add-in from the welcome email
        Initialize();

        // [GIVEN] Email address of message is donotreply@contoso.com
        TestEmail := 'donotreply@contoso.com';
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] Add-in is opened
        OfficeWelcomeDlg.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] Office Welcome Dlg page is shown to the user
        OfficeWelcomeDlg.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineContactDoesNotExistShowsDialogPage()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Contact: Record Contact;
        OfficeNewContactDlg: TestPage "Office New Contact Dlg";
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 147182] Stan is shown a dialog page that asks to create a new contact
        // Setup
        Initialize();

        // [GIVEN] New email is created but not assigned to contact
        TestEmail := RandomEmail();
        OfficeAddinContext.SetFilter(Email, TestEmail);

        // [WHEN] Outlook Mail Engine gives message to add contact
        OfficeNewContactDlg.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] User doesn't choose an action - handler validates message
        Contact.SetRange("Search E-Mail", TestEmail);
        asserterror Contact.FindFirst();
    end;

    [Test]
    [HandlerFunctions('OfficeContactDlgHandlerCreatePersonContact,ContactPageHandler,ContactDetailsDlgHandler')]
    [Scope('OnPrem')]
    procedure OfficeContactDlgCreateContact()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Contact: Record Contact;
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 147182] Stan creates a new contact when prompted in the add-in
        // Setup
        Initialize();

        // [GIVEN] New email is created but not assigned to contact
        TestEmail := RandomEmail();
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] Outlook Mail Engine shows dialog page
        // User chooses to create contact (OfficeContactDlgHandlerCreateCompanyContact)
        LibraryVariableStorage.Enqueue(TestEmail);
        RunMailEngine(OfficeAddinContext);

        // [THEN] Contact card is opened (page handler) and verify contact was created
        Contact.SetRange("E-Mail", TestEmail);
        Contact.FindFirst();
    end;

    [Test]
    [HandlerFunctions('OfficeContactDlgHandlerCreatePersonContact,ContactPageHandler,ContactDetailsDlgHandler')]
    [Scope('OnPrem')]
    procedure OfficeContactDlgCreateCompanyAndPersonContact()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Contact1: Record Contact;
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 163383] Error - Record of the Contact is not linked with any other table in company association page
        // Setup
        Initialize();

        // [GIVEN] A person contact exists
        CreateContact(Contact1, Contact1.Type::Person);

        // [GIVEN] New email is created but not assigned to contact
        TestEmail := RandomEmail();
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] Outlook Mail Engine shows dialog page
        // User chooses to create contact (OfficeContactDlgHandlerCreatePersonContact)
        LibraryVariableStorage.Enqueue(TestEmail);
        RunMailEngine(OfficeAddinContext);

        // [WHEN] User chooses to link contact to company
        LibraryVariableStorage.Enqueue(TestEmail);
        RunMailEngine(OfficeAddinContext);

        // [THEN] The Office No Company Dlg page opens, and the user can assign a company to the user contact without error
    end;

    [Test]
    [HandlerFunctions('ContactDetailsDlgHandlerAssociateToCompany,SingleCustomerEngineHandler')]
    [Scope('OnPrem')]
    procedure OfficeContactDlgCreateContactWithCustCompany()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CompanyContact: Record Contact;
        OfficeNewContactDlg: TestPage "Office New Contact Dlg";
        TestEmail: Text[80];
        ContactNo: Code[20];
        CustomerNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 147182] Stan creates a new contact and associates a company when prompted in the add-in
        // Setup
        Initialize();

        // [GIVEN] New email is created but not assigned to contact
        TestEmail := RandomEmail();
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [GIVEN] New Customer is created with random email
        CustomerNo := CreateContactFromCustomer(RandomEmail(), ContactNo, NewBusRelCode, false);

        CompanyContact.Get(ContactNo);
        CompanyContact.Validate(Name, CopyStr(CreateGuid(), 2, 20));
        CompanyContact.Modify();
        LibraryVariableStorage.Enqueue(CompanyContact."Company Name");
        LibraryVariableStorage.Enqueue(TestEmail);
        LibraryVariableStorage.Enqueue(CustomerNo);

        // [WHEN] Outlook Mail Engine shows new contact dialog page
        OfficeNewContactDlg.Trap();
        RunMailEngine(OfficeAddinContext);

        // User chooses to create contact (ContactDetailsDlgHandlerAssociateToCompany)
        asserterror OfficeNewContactDlg.NewPersonContact.DrillDown();

        // [THEN] Create New Contact card is opened (ContactDetailsDlgHandlerAssociateToCompany page handler)
        // Verify customer number on customer card (SingleCustomerEngineHandler page handler)
    end;

    [Test]
    [HandlerFunctions('ContactDetailsDlgHandlerAssociateToCompany')]
    [Scope('OnPrem')]
    procedure OfficeContactDlgCreateContactWithCompany()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CompanyContact: Record Contact;
        OfficeNewContactDlg: TestPage "Office New Contact Dlg";
        ContactCard: TestPage "Contact Card";
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 166021] Stan creates a new contact and associates a company when prompted in the add-in
        // Setup
        Initialize();

        // [GIVEN] New email is created but not assigned to contact
        TestEmail := RandomEmail();
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [GIVEN] New company is created with random email
        CreateContact(CompanyContact, CompanyContact.Type::Company);
        CompanyContact.Validate(Name, CopyStr(CreateGuid(), 2, 20));
        CompanyContact.Modify();
        LibraryVariableStorage.Enqueue(CompanyContact."Company Name");

        // [WHEN] Outlook Mail Engine shows new contact dialog page
        OfficeNewContactDlg.Trap();
        RunMailEngine(OfficeAddinContext);

        // User chooses to create contact (ContactDetailsDlgHandlerAssociateToCompany)
        ContactCard.Trap();
        asserterror OfficeNewContactDlg.NewPersonContact.DrillDown();

        // [THEN] Create New Contact card is opened (ContactDetailsDlgHandlerAssociateToCompany page handler)
        ContactCard."E-Mail".AssertEquals(TestEmail);
        ContactCard."Company Name".AssertEquals(CompanyContact.Name);
    end;

    [Test]
    [HandlerFunctions('ContactDetailsDlgHandlerNoAssociateToCompany')]
    [Scope('OnPrem')]
    procedure OfficeContactDlgCreateContactAsCompany()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeNewContactDlg: TestPage "Office New Contact Dlg";
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 147182] Stan creates a new contact and sets the type to person
        // Setup
        Initialize();

        // [GIVEN] New email is created but not assigned to contact
        TestEmail := RandomEmail();
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] Outlook Mail Engine shows new contact dialog page
        OfficeNewContactDlg.Trap();
        RunMailEngine(OfficeAddinContext);

        // User chooses to create contact as company (ContactDetailsDlgHandlerNoAssociateToCompany)
        // [WHEN] User sets the type to company
        asserterror OfficeNewContactDlg.NewPersonContact.DrillDown();

        // [THEN] Associate to company and company name fields are disabled
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OfficeContactDlgDefaultPersonContactWhenEmailExistInCompany()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Contact: Record Contact;
        CompanyContact: Record Contact;
        ContactCard: TestPage "Contact Card";
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO] Stan creates a new contact when prompted in the add-in and associate the contact to a company that has the same email as the contact
        // Setup
        Initialize();

        // [GIVEN] A person contacts and a company contact with the same email as the contact exist
        TestEmail := CreateContact(CompanyContact, CompanyContact.Type::Company);
        CreateContact(Contact, Contact.Type::Person);
        Contact.Validate("E-Mail", TestEmail);
        Contact.Validate("Company No.", CompanyContact."No.");
        Contact.Modify();

        // [WHEN] Outlook add-in is opened for the contact email address
        OfficeAddinContext.SetRange(Email, TestEmail);
        ContactCard.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The a person contact is opened
        ContactCard."No.".AssertEquals(Contact."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactDetailsDlgHandlerAssociateToCompany(var OfficeContactDetailsDlg: TestPage "Office Contact Details Dlg")
    begin
        OfficeContactDetailsDlg."Associate to Company".SetValue(true);
        OfficeContactDetailsDlg."Company Name".SetValue(LibraryVariableStorage.DequeueText());
        OfficeContactDetailsDlg.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactDetailsDlgHandlerNoAssociateToCompany(var OfficeContactDetailsDlg: TestPage "Office Contact Details Dlg")
    var
        DummyContact: Record Contact;
    begin
        OfficeContactDetailsDlg.Type.SetValue(DummyContact.Type::Company);
        OfficeContactDetailsDlg."Associate to Company".SetValue(false);
        Assert.IsFalse(OfficeContactDetailsDlg."Associate to Company".Enabled(), 'Associate to company not allowed for company contact.');
        Assert.IsFalse(OfficeContactDetailsDlg."Company Name".Enabled(), 'A company contact can''t be assigned to another company.');
        OfficeContactDetailsDlg.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('OfficeContactDlgHandlerCreatePersonContact,ContactDetailsDlgHandler')]
    [Scope('OnPrem')]
    procedure OfficeContactDlgCreateContactChangeCompanyRetainsEmail()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Contact: Record Contact;
        Contact1: Record Contact;
        Contact2: Record Contact;
        ContactCard: TestPage "Contact Card";
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 147182] Stan creates a new contact when prompted in the add-in
        // Setup
        Initialize();

        // [GIVEN] New email is created but not assigned to contact
        TestEmail := RandomEmail();
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [GIVEN] Several company contacts exist
        CreateContact(Contact1, Contact1.Type::Company);
        CreateContact(Contact2, Contact2.Type::Company);

        // [WHEN] Outlook Mail Engine shows dialog page
        // User chooses to create contact (OfficeContactDlgHandlerCreateCompanyContact)
        ContactCard.Trap();
        RunMailEngine(OfficeAddinContext);

        // [WHEN] Company No. is changed on the contact
        Contact.SetRange("E-Mail", TestEmail);
        Contact.FindFirst();
        Contact.Validate("Company No.", Contact1."No.");
        Contact.Validate("Company No.", Contact2."No.");

        // [THEN] The email does not get changed to the company email
        ContactCard."E-Mail".AssertEquals(TestEmail);
    end;

    [Test]
    [HandlerFunctions('OfficeContactDlgHandlerShowList')]
    [Scope('OnPrem')]
    procedure OfficeContactDlgShowContactList()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactList: TestPage "Contact List";
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 147182] Stan shows the contact list when prompted in the add-in
        // Setup
        Initialize();

        // [GIVEN] New email is created but not assigned to contact
        TestEmail := RandomEmail();
        OfficeAddinContext.SetRange(Email, TestEmail);
        OfficeAddinContext.SetRange(Name, TestEmail);

        // [WHEN] Outlook Mail Engine shows the OfficeNewContactDlg page
        // [WHEN] User clicks the field to show the contact list (OfficeContactDlgHandlerShowList)
        LibraryVariableStorage.Enqueue(TestEmail);
        ContactList.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] Verify the page was open
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToPersonWhen1PersonContactAndMultipleCompanies()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        PersonContact: Record Contact;
        CompanyContact1: Record Contact;
        CompanyContact2: Record Contact;
        ContactCard: TestPage "Contact Card";
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 199938] Stan is redirected to the person contact when one person contact and 1 to many company contacts have the same email address.
        Initialize();

        // [GIVEN] One person contact and two company contacts exist with the same email address.
        TestEmail := CreateContact(CompanyContact1, CompanyContact1.Type::Company);
        CreateContact(CompanyContact2, CompanyContact2.Type::Company);
        CreateContact(PersonContact, PersonContact.Type::Person);

        PersonContact.Validate("E-Mail", TestEmail);
        CompanyContact2.Validate("E-Mail", TestEmail);
        PersonContact.Modify(true);
        CompanyContact2.Modify(true);

        // [WHEN] Outlook add-in is opened in the context of the given email address.
        OfficeAddinContext.SetRange(Email, TestEmail);
        ContactCard.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] The contact card for the person contact is opened.
        ContactCard.Name.AssertEquals(PersonContact.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToContactPageWhenCompanyNotCustomerOrVendor()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        ContactNo: Code[20];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 147177] Stan can only view contact information in his email when Company not linked
        // Setup
        Initialize();

        // [GIVEN] New Person contact with email is created and assigned to Company contact
        CreateContact(Contact, Contact.Type::Company);
        ContactNo := Contact."No.";
        Clear(Contact);
        TestEmail := CreateContact(Contact, Contact.Type::Person);
        Contact.Validate("Company No.", ContactNo);
        Contact.Modify();
        LibraryVariableStorage.Enqueue(TestEmail);

        // [WHEN] Outlook Mail Engine finds email and contact it is assigned to
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [THEN] Contact card is opened for associated email
        ContactCard.Trap();
        RunMailEngine(OfficeAddinContext);
        ContactCard."E-Mail".AssertEquals(TestEmail);
    end;

    [Test]
    [HandlerFunctions('SingleCustomerEngineHandler')]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToCustomerPageIfOneCustomer()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 147177] Stan can view customer information in his email through with addin
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        LibraryVariableStorage.Enqueue(CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode, true));

        // [WHEN] Outlook Main Engine finds email and contact/customer it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Customer card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Customers in Marketing Setup.
        ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers);
    end;

    [Test]
    [HandlerFunctions('SingleVendorEngineHandler')]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToVendorPageIfOneVendor()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 147178] Stan can view vendor information in his email through with addin
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to vendor
        TestEmail := RandomEmail();
        LibraryVariableStorage.Enqueue(CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true));

        // [WHEN] Outlook Main Engine finds email and contact/vendor it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Vendor card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Vendors in Marketing Setup.
        ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors);
    end;

    [Test]
    [HandlerFunctions('SingleCustomerFBEngineHandler')]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToCustomerPageFactBoxAvail()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 147177] Stan can view customer fact box information on customer
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode, true);
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Outlook Main Engine finds email and contact/customer it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Customer card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Customers in Marketing Setup.
        ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers);
    end;

    [Test]
    [HandlerFunctions('SingleVendorFBEngineHandler')]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToVendorPageFactBoxAvail()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 147178] Stan can view vendor information in his email through with addin
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to vendor
        TestEmail := RandomEmail();
        CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Outlook Main Engine finds email and contact/vendor it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Vendor card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Vendors in Marketing Setup.
        ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors);
    end;

    [Test]
    [HandlerFunctions('SingleCustomerFBEngineHandler')]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToCustomerPageFactBoxNotAvail()
    var
        Customer: Record Customer;
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        CustomerNo: Code[20];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 147177] Stan cannot view customer fact box information on customer in NAV
        // Setup
        Initialize();
        SetOfficeHostUnAvailable();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        CustomerNo := CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode, true);
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Customer is opened on Customer Card
        Customer.Get(CustomerNo);
        PAGE.Run(PAGE::"Customer Card", Customer);

        // [THEN] Customer Card Fact Boxes are not visible - in handler

        // Cleanup: Input the original value of the field Bus. Rel. Code for Customers in Marketing Setup.
        ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers);
    end;

    [Test]
    [HandlerFunctions('SingleVendorFBEngineHandler')]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToVendorPageFactBoxNotAvail()
    var
        Vendor: Record Vendor;
        ContactNo: Code[20];
        VendorNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 147178] Stan cannot view vendor information on Vendor card in NAV
        // Setup
        Initialize();
        SetOfficeHostUnAvailable();

        // [GIVEN] New contact with email is created and assigned to vendor
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        LibraryVariableStorage.Enqueue(false);

        // [WHEN]Vendor is opened on vendor card
        Vendor.Get(VendorNo);
        PAGE.Run(PAGE::"Vendor Card", Vendor);

        // [THEN] Vendor Card Fact Boxes are not visible - in handler

        // Cleanup: Input the original value of the field Bus. Rel. Code for Vendors in Marketing Setup.
        ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors);
    end;

    [Test]
    [HandlerFunctions('MultipleContactsEngineHandler')]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToMultipleAssignmentPage()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustContactNo: Code[20];
        VendContactNo: Code[20];
        NewCustBusRelCode: Code[10];
        NewVendBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Customer] [Vendor]
        // [SCENARIO 147177] Stan can view multiple contacts for an email address
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to customer and vendor
        TestEmail := RandomEmail();
        CreateContactFromCustomer(TestEmail, CustContactNo, NewCustBusRelCode, true);
        CreateContactFromVendor(TestEmail, VendContactNo, NewVendBusRelCode, true);

        // [WHEN] Outlook Main Engine finds email and customer/vendor it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Office Addin Contact Selection is opened for contacts for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Customers/Vendors in Marketing Setup.
        ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers);
        ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors);
    end;

    [Test]
    [HandlerFunctions('MultipleContactsEngineHandlerSelect,SingleCustomerEngineHandler')]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToMultipleAssignmentPageAndCustomer()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustContactNo: Code[20];
        VendContactNo: Code[20];
        CustomerNo: Code[20];
        NewCustBusRelCode: Code[10];
        NewVendBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Customer] [Vendor]
        // [SCENARIO 147177] Stan can view multiple contacts for an email address
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created/assigned to customer and vendor and que customer zoom info
        TestEmail := RandomEmail();
        CustomerNo := CreateContactFromCustomer(TestEmail, CustContactNo, NewCustBusRelCode, true);
        CreateContactFromVendor(TestEmail, VendContactNo, NewVendBusRelCode, true);
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(CustomerNo);

        // [WHEN] Outlook Main Engine finds email and customer/vendor it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Office Addin Contact Selection is opened for contacts for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Customers/Vendors in Marketing Setup.
        ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers);
        ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors);
    end;

    [Test]
    [HandlerFunctions('MultipleContactsEngineHandlerSelect,SingleVendorEngineHandler')]
    [Scope('OnPrem')]
    procedure MailEngineRedirectsToMultipleAssignmentPageAndVendor()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustContactNo: Code[20];
        VendContactNo: Code[20];
        VendorNo: Code[20];
        NewCustBusRelCode: Code[10];
        NewVendBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [FEATURE] [Contact] [Customer] [Vendor]
        // [SCENARIO 147177] Stan can view multiple contacts for an email address
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created/assigned to customer and vendor and que vendor zoom info
        TestEmail := RandomEmail();
        CreateContactFromCustomer(TestEmail, CustContactNo, NewCustBusRelCode, true);
        VendorNo := CreateContactFromVendor(TestEmail, VendContactNo, NewVendBusRelCode, true);
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(VendorNo);
        // [WHEN] Outlook Main Engine finds email and customer/vendor it is assigned to
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        // [THEN] Office Addin Contact Selection is opened for contacts for associated email
        RunMailEngine(OfficeAddinContext);

        // Cleanup: Input the original value of the field Bus. Rel. Code for Customers/Vendors in Marketing Setup.
        ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers);
        ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineParsesAllFilters()
    var
        NewOfficeAddinContext: Record "Office Add-in Context";
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeAddin: Record "Office Add-in";
        OfficeManagement: Codeunit "Office Management";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OfficeNewContactDlg: TestPage "Office New Contact Dlg";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldValue: Text;
        i: Integer;
        OptionValue: Integer;
        OriginalVersion: Text[20];
    begin
        // Setup
        Initialize();
        OfficeAddinContext.Init();
        RecRef.GetTable(OfficeAddinContext);
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            if FieldRef.Type <> FieldType::Option then begin
                FieldValue := CopyStr(CreateGuid(), 1, FieldRef.Length);
                LibraryVariableStorage.Enqueue(FieldValue);
            end else begin
                OptionValue := Random(2);
                FieldValue := Format(OptionValue - 1);
                LibraryVariableStorage.Enqueue(SelectStr(OptionValue, FieldRef.OptionCaption));
            end;
            FieldRef.SetFilter(FieldValue);
        end;
        RecRef.SetTable(OfficeAddinContext);
        AddinManifestManagement.GetAddinByHostType(OfficeAddin, OfficeHostType.OutlookItemRead);
        OriginalVersion := CopyStr(OfficeAddinContext.GetFilter(Version), 1, 20);
        OfficeAddinContext.SetRange(Version, OfficeAddin.Version);

        // Exercise
        OfficeNewContactDlg.Trap();
        RunMailEngine(OfficeAddinContext);
        OfficeManagement.GetContext(NewOfficeAddinContext);

        NewOfficeAddinContext.Version := OriginalVersion;

        // Verify
        RecRef.GetTable(NewOfficeAddinContext);
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            Assert.AreEqual(LibraryVariableStorage.DequeueText(), Format(FieldRef.Value), 'Unexpected value.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineNoEmailShowsContactSelection()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactList: TestPage "Contact List";
    begin
        // [SCENARIO 144958] Stan can select a contact to interact with from the add-in
        // [GIVEN] No contact is selected
        Initialize();
        ContactList.Trap();

        // [WHEN] User launches the add-in
        RunMailEngine(OfficeAddinContext);

        // [THEN] Contact list is shown
        ContactList.FILTER.SetFilter("E-Mail", '');
    end;

    [Test]
    [HandlerFunctions('MailEngineSelectCustContShwCustCardHandler')]
    [Scope('OnPrem')]
    procedure MailEngineSelectCustomerContactShowsCustomerCard()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        SelectedContact: Record Contact;
        ContactList: TestPage "Contact List";
        CustomerCard: TestPage "Customer Card";
        SelectedNo: Code[20];
        CustomerNo: Code[20];
        Email: Text[80];
        NewBusRelCode: Code[10];
    begin
        // [SCENARIO 144958] Stan can select a contact to interact with from the add-in
        // [GIVEN] No contact is passed to the add-in from outlook
        Initialize();

        // [GIVEN] A customer exists with an email address
        Email := RandomEmail();
        CustomerNo := CreateContactFromCustomer(Email, SelectedNo, NewBusRelCode, false);

        // [WHEN] User launches the add-in
        ContactList.Trap();
        RunMailEngine(OfficeAddinContext);

        // [WHEN] User selects the contact from the list
        ContactList.FILTER.SetFilter("No.", SelectedNo);
        ContactList.First();
        SelectedContact.Get(SelectedNo);

        // [THEN] Contact is added to the recipient line in Outlook
        LibraryVariableStorage.Enqueue('addRecipient');
        LibraryVariableStorage.Enqueue(Email);
        LibraryVariableStorage.Enqueue(SelectedContact.Name);
        LibraryVariableStorage.Enqueue('');

        // [THEN] Customer card is opened for the selected contact
        CustomerCard.Trap();
        ContactList.Close();
        CustomerCard."No.".AssertEquals(CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommandShowsCustomerContactList()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactList: TestPage "Contact List";
        VendorContactNo: Code[20];
        CustomerContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [SCENARIO 144958] Stan can select a sales contact to interact with from the add-in
        // [GIVEN] No contact is passed to the add-in from outlook
        Initialize();

        // [GIVEN] Both a customer and vendor company exist
        CreateContactFromCustomer(RandomEmail(), CustomerContactNo, NewBusRelCode, false);
        CreateContactFromVendor(RandomEmail(), VendorContactNo, NewBusRelCode, false);

        // [WHEN] User launches the add-in for a sales command
        ContactList.Trap();
        OfficeAddinContext.SetRange(Command, CommandType.NewSalesInvoice);
        RunMailEngine(OfficeAddinContext);

        // [THEN] The vendor does not appear in the list to choose from
        Assert.IsFalse(ContactList.FindFirstField("No.", VendorContactNo), 'Vendor shouldn''t be in contact list.');

        // [THEN] The customer does appear in the list to choose from
        Assert.IsTrue(ContactList.FindFirstField("No.", CustomerContactNo), 'Customer should be in contact list.');
        SetOfficeHostUnAvailable();
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCommandShowsVendorContactList()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactList: TestPage "Contact List";
        VendorContactNo: Code[20];
        CustomerContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [SCENARIO 144958] Stan can select a purchase contact to interact with from the add-in
        // [GIVEN] No contact is passed to the add-in from outlook
        Initialize();

        // [GIVEN] Both a customer and vendor company exist
        CreateContactFromVendor(RandomEmail(), VendorContactNo, NewBusRelCode, false);
        CreateContactFromCustomer(RandomEmail(), CustomerContactNo, NewBusRelCode, false);

        // [WHEN] User launches the add-in for a purchase command
        ContactList.Trap();
        OfficeAddinContext.SetRange(Command, CommandType.NewPurchaseInvoice);
        RunMailEngine(OfficeAddinContext);

        // [THEN] The vendor does appears in the list to choose from
        Assert.IsTrue(ContactList.FindFirstField("No.", VendorContactNo), 'Vendor should be in contact list.');

        // [THEN] The customer does not appear in the list to choose from
        Assert.IsFalse(ContactList.FindFirstField("No.", CustomerContactNo), 'Customer should not be in contact list.');
        SetOfficeHostUnAvailable();
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppointmentAddinShowsCustomerContactList()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ContactList: TestPage "Contact List";
        VendorContactNo: Code[20];
        CustomerContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [SCENARIO 144958] Stan can select a sales contact to interact with from the add-in
        // [GIVEN] No contact is passed to the add-in from outlook
        Initialize();

        // [GIVEN] Both a customer and vendor company exist
        CreateContactFromVendor(RandomEmail(), VendorContactNo, NewBusRelCode, false);
        CreateContactFromCustomer(RandomEmail(), CustomerContactNo, NewBusRelCode, false);

        // [WHEN] User launches the add-in from an appointment with a duration
        ContactList.Trap();
        OfficeAddinContext.SetRange(Duration, '5');
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);
        RunMailEngine(OfficeAddinContext);

        // [THEN] The vendor does not appear in the list to choose from
        Assert.IsFalse(ContactList.FindFirstField("No.", VendorContactNo), 'Vendor shouldn''t be in contact list.');

        // [THEN] The customer does appear in the list to choose from
        Assert.IsTrue(ContactList.FindFirstField("No.", CustomerContactNo), 'Customer should be in contact list.');
        SetOfficeHostUnAvailable();
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineRemovesPrefixFromFilter()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeNewContactDlg: TestPage "Office New Contact Dlg";
    begin
        // The mail engine should work even with junk in the filters

        // Setup
        Initialize();
        OfficeAddinContext.SetFilter(Email, CreateGuid());
        OfficeAddinContext.SetFilter(Name, '''&Jones123&%5''');

        // Exercise
        OfficeNewContactDlg.Trap();
        RunMailEngine(OfficeAddinContext);

        // Verify
        OfficeManagement.GetContext(OfficeAddinContext);
        Assert.AreEqual('&Jones123&%5', OfficeAddinContext.Name, 'Filter parsed incorrectly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineRemovesSingleQuotesFromFilter()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeNewContactDlg: TestPage "Office New Contact Dlg";
    begin
        // The mail engine should remove single quotes from the filters

        // Setup
        Initialize();
        OfficeAddinContext.SetFilter(Email, CreateGuid());
        OfficeAddinContext.SetFilter(Name, '''John Smith''');

        // Exercise
        OfficeNewContactDlg.Trap();
        RunMailEngine(OfficeAddinContext);

        // Verify
        OfficeManagement.GetContext(OfficeAddinContext);
        Assert.AreEqual('John Smith', OfficeAddinContext.Name, 'Filter parsed incorrectly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineLeavesFilterAloneIfNoQuotes()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeNewContactDlg: TestPage "Office New Contact Dlg";
    begin
        // The mail engine should remove single quotes from the filters

        // Setup
        Initialize();
        OfficeAddinContext.SetFilter(Email, CreateGuid());
        OfficeAddinContext.SetFilter(Name, 'John Smith');

        // Exercise
        OfficeNewContactDlg.Trap();
        RunMailEngine(OfficeAddinContext);

        // Verify
        OfficeManagement.GetContext(OfficeAddinContext);
        Assert.AreEqual('John Smith', OfficeAddinContext.Name, 'Filter parsed incorrectly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineVendorContactButtonAvail()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Vendor: TestPage "Vendor Card";
        TestEmail: Text[80];
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 159886] Stan can click on Contact from the vendor
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to vendor
        TestEmail := RandomEmail();
        CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);

        // [WHEN] Outlook Main Engine finds email and contact/vendor it is assigned to
        OfficeAddinContext.SetRange(Email, TestEmail);

        Vendor.Trap();
        // [THEN] Vendor card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        // [THEN] Contact action is visible
        Assert.IsTrue(Vendor.ContactBtn.Visible(), 'Contact button should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorContactButtonNoOfficeMgmt()
    var
        Vendor: Record Vendor;
        ContactList: TestPage "Contact List";
        VendorCard: TestPage "Vendor Card";
        TestEmail: Text[80];
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 159886] Stan can click on Contact from the vendor with no office managment setup which opens Contact List
        SetOfficeHostUnAvailable();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);

        // [GIVEN] Vendor card is opened
        VendorCard.Trap();
        Vendor.Get(VendorNo);
        PAGE.Run(PAGE::"Vendor Card", Vendor);

        // [WHEN] Contact action is invoked on Vendor card
        ContactList.Trap();
        VendorCard.ContactBtn.Invoke();

        // [THEN] The contact list is opened
        ContactList."No.".AssertEquals(ContactNo);
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineVendorOpenContactListMultipleEmails()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
        OfficeAddinContext: Record "Office Add-in Context";
        VendorCard: TestPage "Vendor Card";
        ContactList: TestPage "Contact List";
        TestEmail: Text[80];
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 159886] Stan can click on Contact from the vendor and it opens the contact list because multiple contacts have the same email
        Initialize();

        // [GIVEN] New contact with email is created
        TestEmail := CreateContact(Contact, Contact.Type::Person);

        // [GIVEN] New vendor is created
        CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);

        // [GIVEN] Another contact exists with the same email and company assignment
        CreateContact(Contact2, Contact2.Type::Person);
        Contact2."E-Mail" := TestEmail;
        Contact2."Company No." := ContactNo;
        Contact2.Modify();

        // [WHEN] Outlook add-in is opened for the contact email address
        OfficeAddinContext.SetRange(Email, TestEmail);
        VendorCard.Trap();
        RunMailEngine(OfficeAddinContext);

        // [WHEN] User invokes the Contact action
        ContactList.Trap();
        VendorCard.ContactBtn.Invoke();

        // [THEN] The contact list is opened
        Assert.IsTrue(ContactList.GotoKey(ContactNo), 'Contact is not present on the list');
        Assert.IsTrue(ContactList.GotoKey(Contact2."No."), 'Contact is not present on the list');
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineVendorOpenSingleContact()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        VendorPage: TestPage "Vendor Card";
        Contact: TestPage "Contact Card";
        TestEmail: Text[80];
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 159886] Stan can click on Contact from the vendor and it opens the contact directly
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to vendor
        TestEmail := RandomEmail();
        CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        OfficeAddinContext.SetRange(Email, TestEmail);

        VendorPage.Trap();
        // [WHEN] Vendor card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        Contact.Trap();
        VendorPage.ContactBtn.Invoke();

        // [THEN] Contact Page is opened
        Contact."No.".AssertEquals(ContactNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineCustomerContactButtonAvail()
    var
        Customer: Record Customer;
        CustomerPage: TestPage "Customer Card";
        TestEmail: Text[80];
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159886] Stan can click on Contact from the customer
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        CustomerNo := CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode, true);

        // [WHEN] Customer is opened on Customer Card
        CustomerPage.Trap();
        Customer.Get(CustomerNo);
        PAGE.Run(PAGE::"Customer Card", Customer);

        // [THEN] Contact action is visible
        Assert.IsTrue(CustomerPage.Contact.Visible(), 'Contact button should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerContactButtonNoOfficeMgmt()
    var
        Customer: Record Customer;
        ContactList: TestPage "Contact List";
        CustomerPage: TestPage "Customer Card";
        TestEmail: Text[80];
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159886] Stan can click on Contact from the customer with no office managment setup which opens Contact List
        SetOfficeHostUnAvailable();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        CustomerNo := CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode, true);
        LibraryVariableStorage.Enqueue(false);

        CustomerPage.Trap();
        Customer.Get(CustomerNo);
        PAGE.Run(PAGE::"Customer Card", Customer);

        ContactList.Trap();
        // [WHEN] Contact List is opened from the Customer Card
        CustomerPage.Contact.Invoke();

        // [THEN] Verify the Contact List was open
        ContactList."No.".AssertEquals(ContactNo);
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineCustomerOpenContactListMultipleEmails()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Contact: Record Contact;
        Contact2: Record Contact;
        CustomerCard: TestPage "Customer Card";
        ContactList: TestPage "Contact List";
        TestEmail: Text[80];
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159886] Stan can click on Contact from the customer and it opens the contact list because multiple contacts have the same email
        // Setup
        InitializeOfficeHostProvider(OfficeHostType.OutlookItemRead);

        // [GIVEN] New contact with email is created
        TestEmail := CreateContact(Contact, Contact.Type::Person);

        // [GIVEN] New Customer is created
        CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode, true);

        // [GIVEN] Another contact exists with the same email and company assignment
        CreateContact(Contact2, Contact2.Type::Person);
        Contact2."E-Mail" := TestEmail;
        Contact2."Company No." := ContactNo;
        Contact2.Modify();

        // [WHEN] Outlook add-in is opened for the contact email address
        OfficeAddinContext.SetRange(Email, TestEmail);
        CustomerCard.Trap();
        RunMailEngine(OfficeAddinContext);

        // [WHEN] User invokes the Contact action
        ContactList.Trap();
        CustomerCard.Contact.Invoke();

        // [THEN] The contact list is opened
        Assert.IsTrue(ContactList.GotoKey(ContactNo), 'Contact is not present on the list');
        Assert.IsTrue(ContactList.GotoKey(Contact2."No."), 'Contact is not present on the list');
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MailEngineCustomerOpenSingleContact()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerPage: TestPage "Customer Card";
        Contact: TestPage "Contact Card";
        TestEmail: Text[80];
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 159886] Stan can click on Contact from the customer and it opens the contact directly
        // Setup
        Initialize();

        // [GIVEN] New contact with email is created and assigned to customer
        TestEmail := RandomEmail();
        CreateContactFromCustomer(TestEmail, ContactNo, NewBusRelCode, true);
        OfficeAddinContext.SetFilter(Email, '=%1', TestEmail);

        CustomerPage.Trap();
        // [WHEN] Customer card is opened for associated email
        RunMailEngine(OfficeAddinContext);

        Contact.Trap();
        CustomerPage.Contact.Invoke();

        // [THEN] Contact Page is opened
        Contact."No.".AssertEquals(ContactNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OfficeMgmtAttachAvailability()
    begin
        VerifyAttachAvailable(OfficeHostType.OutlookItemRead, true);
        VerifyAttachAvailable(OfficeHostType.OutlookItemEdit, true);
        VerifyAttachAvailable(OfficeHostType.OutlookHyperlink, true);
        VerifyAttachAvailable(OfficeHostType.OutlookTaskPane, true);
        VerifyAttachAvailable(OfficeHostType.OutlookPopOut, false);
        VerifyAttachAvailable(OfficeHostType.OutlookMobileApp, false);
        VerifyAttachAvailable('N/A', false);
    end;

    local procedure VerifyAttachAvailable(HostType: Text; Expected: Boolean)
    var
        OfficeManagement: Codeunit "Office Management";
    begin
        InitializeWithHostType(HostType);
        Assert.AreEqual(Expected, OfficeManagement.AttachAvailable(), StrSubstNo(AttachAvailableErr, HostType));
    end;

    [Test]
    [HandlerFunctions('ActionHandler')]
    [Scope('OnPrem')]
    procedure OfficeMgmtAttachDocument()
    begin
        AttachFile(OfficeHostType.OutlookItemRead, false);
        AttachFile(OfficeHostType.OutlookItemEdit, false);
        AttachFile(OfficeHostType.OutlookTaskPane, false);
        AttachFile(OfficeHostType.OutlookHyperlink, false);
    end;

    local procedure AttachFile(HostType: Text; AttachAsUrl: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        OfficeManagement: Codeunit "Office Management";
        InStream: InStream;
        OutStream: OutStream;
        FileName: Text;
        FileContents: Text;
        EmailBody: Text;
        Subject: Text;
    begin
        InitializeWithHostType(HostType);

        // Generate a random file
        FileName := StrSubstNo('%1.txt', CreateGuid());
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(Format(CreateGuid()));
        TempBlob.CreateInStream(InStream);

        if AttachAsUrl then
            FileContents := 'http'
        else
            FileContents := Base64Convert.ToBase64(InStream);

        // Get Stream to attach
        TempBlob.CreateInStream(InStream);

        // Generate email body text
        EmailBody := CreateGuid();
        Subject := 'Testing AttachFile';

        LibraryVariableStorage.Enqueue('sendAttachment');
        LibraryVariableStorage.Enqueue(FileContents);
        LibraryVariableStorage.Enqueue(FileName);
        LibraryVariableStorage.Enqueue(EmailBody);
        LibraryVariableStorage.Enqueue(Subject);
        OfficeManagement.AttachDocument(InStream, FileName, EmailBody, Subject);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OfficeMgmtShowErrorPage()
    var
        OfficeErrorEngine: Codeunit "Office Error Engine";
        OfficeErrorDlg: TestPage "Office Error Dlg";
        ErrorText: Text;
    begin
        // Setup
        ErrorText := CreateGuid();
        OfficeErrorDlg.Trap();

        // Exercise
        OfficeErrorEngine.ShowError(ErrorText);

        // Verify
        OfficeErrorDlg.ErrorText.AssertEquals(ErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentForCustomerSetsContactToOfficeContact()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Customer: Record Customer;
        Contact1: Record Contact;
        Contact2: Record Contact;
        NoSeries: Record "No. Series";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
        Contact2Email: Text[80];
        CustomerNo: Code[20];
        CustomerContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [FEATURE] [Contact] [Customer]
        // [SCENARIO 163053] Creating a new sales document from the customer card sets the sell-to and bill-to contact according to the original contact that came through the add-in.
        Initialize();

        // [GIVEN] A customer exists
        CustomerNo := CreateContactFromCustomer(RandomEmail(), CustomerContactNo, NewBusRelCode, true);
        CreateContact(Contact1, Contact1.Type::Person);
        Contact2Email := CreateContact(Contact2, Contact2.Type::Person);

        // [GIVEN] Two contacts exist and are both linked to the customer
        Contact1."Company No." := CustomerContactNo;
        Contact2."Company No." := CustomerContactNo;
        Contact1.Modify();
        Contact2.Modify();

        SalesReceivablesSetup.Get();
        NoSeries.Get(SalesReceivablesSetup."Quote Nos.");
        NoSeries."Manual Nos." := false;
        NoSeries.Modify();
        DocumentNoVisibility.ClearState();

        // [WHEN] The primary contact for the customer is set to contact1
        Customer.Get(CustomerNo);
        Customer.Validate("Primary Contact No.", Contact1."No.");
        Customer.Modify();

        // [WHEN] Office add-in is ran with the email address of contact2
        OfficeAddinContext.SetRange(Email, Contact2Email);
        CustomerCard.Trap();
        RunMailEngine(OfficeAddinContext);

        // [WHEN] The user chooses to create a new sales quote for the customer
        SalesQuote.Trap();
        CustomerCard.NewSalesQuote.Invoke();

        // [THEN] The sales quote contact information is set to contact2
        SalesQuote."Sell-to Contact".AssertEquals(Contact2.Name);
        SalesQuote."Sell-to Contact No.".AssertEquals(Contact2."No.");
        SalesQuote."Bill-to Contact No.".AssertEquals(Contact2."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocumentForVendorSetsContactToOfficeContact()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Vendor: Record Vendor;
        Contact1: Record Contact;
        Contact2: Record Contact;
        NoSeries: Record "No. Series";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
        Contact2Email: Text[80];
        VendorNo: Code[20];
        VendorContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [FEATURE] [Contact] [Vendor]
        // [SCENARIO 163053] Creating a new purchase document from the customer card sets the buy-from to contact according to the original contact that came through the add-in.
        Initialize();

        // [GIVEN] A vendor exists
        VendorNo := CreateContactFromVendor(RandomEmail(), VendorContactNo, NewBusRelCode, true);
        CreateContact(Contact1, Contact1.Type::Person);
        Contact2Email := CreateContact(Contact2, Contact2.Type::Person);

        // [GIVEN] Two contacts exist and are both linked to the vendor
        Contact1."Company No." := VendorContactNo;
        Contact2."Company No." := VendorContactNo;
        Contact1.Modify();
        Contact2.Modify();

        PurchasesPayablesSetup.Get();
        NoSeries.Get(PurchasesPayablesSetup."Invoice Nos.");
        NoSeries."Manual Nos." := false;
        NoSeries.Modify();
        DocumentNoVisibility.ClearState();

        // [WHEN] The primary contact for the vendor is set to contact1
        Vendor.Get(VendorNo);
        Vendor.Validate("Primary Contact No.", Contact1."No.");
        Vendor.Modify();

        // [WHEN] Office add-in is ran with the email address of contact2
        OfficeAddinContext.SetRange(Email, Contact2Email);
        VendorCard.Trap();
        RunMailEngine(OfficeAddinContext);

        // [WHEN] The user chooses to create a new purchase invoice for the vendor
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // [THEN] The purchase invoice contact information is set to contact2
        PurchaseInvoice."Buy-from Contact".AssertEquals(Contact2.Name);
        PurchaseInvoice."Buy-from Contact No.".AssertEquals(Contact2."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertOfficeInvoiceWhenAppointment()
    var
        OfficeInvoice: Record "Office Invoice";
        CustomerCard: TestPage "Customer Card";
        SalesInvoice: TestPage "Sales Invoice";
        CustEmail: Text[80];
        ItemId: Text[250];
    begin
        // [FEATURE] [Customer] [Invoice]
        // [SCENARIO 166905] Creating a new invoice in the context of an appointment causes an Office Invoice record to be created.
        Initialize();

        // [GIVEN] Customer exists with email address
        // [WHEN] Add-in is launched from an appointment for the customer
        // [WHEN] New invoice is created for the customer
        RunWithCustomerInvoice(CustomerCard, SalesInvoice, ItemId, CustEmail, true);

        // [THEN] Office invoice record is inserted for the invoice and appointment
        OfficeInvoice.Get(ItemId, SalesInvoice."No.".Value, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoInsertOfficeInvoiceWhenNotAppointment()
    var
        OfficeInvoice: Record "Office Invoice";
        CustomerCard: TestPage "Customer Card";
        SalesInvoice: TestPage "Sales Invoice";
        ItemId: Text[250];
        CustEmail: Text[80];
    begin
        // [FEATURE] [Customer] [Invoice]
        // [SCENARIO 166905] Creating a new invoice when not in the context of an appointment does not cause an Office Invoice record to be created.
        Initialize();

        // [GIVEN] Customer exists with email address
        // [WHEN] Add-in is launched for the customer from a message
        // [WHEN] New invoice is created for the customer
        RunWithCustomerInvoice(CustomerCard, SalesInvoice, ItemId, CustEmail, false);

        // [THEN] No Office invoice record for the item is created
        OfficeInvoice.SetRange("Document No.", SalesInvoice."No.".Value);
        Assert.AreEqual(0, OfficeInvoice.Count, 'Office invoice record should not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceExistsPageOpensWhenInvoiceExistsForAppointment()
    var
        SalesHeader: Record "Sales Header";
        CustomerCard: TestPage "Customer Card";
        OfficeInvoiceSelection: TestPage "Office Invoice Selection";
        CustEmail: Text[80];
        ItemId: Text[250];
    begin
        // [FEATURE] [Customer] [Invoice]
        // [SCENARIO 166905] New invoice action prompts user when an invoice has already been created for the appointment.
        Initialize();

        // [GIVEN] Customer exists with email address
        // [WHEN] Add-in is launched for the customer from an appointment
        RunWithCustomer(CustomerCard, ItemId, CustEmail, true);

        // [GIVEN] Office invoice record exists for the appointment
        CreateOfficeInvoiceRecord(CustomerCard."No.".Value, ItemId, SalesHeader);

        // [WHEN] New invoice action is invoked
        OfficeInvoiceSelection.Trap();
        CustomerCard.NewSalesInvoice.Invoke();

        // [THEN] Office invoice selection page is shown
        OfficeInvoiceSelection."No.".AssertEquals(SalesHeader."No.");
        OfficeInvoiceSelection."Sell-to Customer Name".AssertEquals(SalesHeader."Sell-to Customer Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceExistsPageOpensWhenInvoiceExistsForAppointmentCommand()
    var
        SalesHeader: Record "Sales Header";
        OfficeAddinContext: Record "Office Add-in Context";
        CustomerCard: TestPage "Customer Card";
        OfficeInvoiceSelection: TestPage "Office Invoice Selection";
        CustEmail: Text[80];
        ItemId: Text[250];
        CustNo: Code[20];
        CustContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        // [FEATURE] [Customer] [Invoice]
        // [SCENARIO 166905] New invoice add-in command prompts user when an invoice has already been created for the appointment.
        Initialize();

        // [GIVEN] Customer exists with email address
        CustEmail := RandomEmail();
        CustNo := CreateContactFromCustomer(CustEmail, CustContactNo, NewBusRelCode, false);

        // [GIVEN] Office invoice record exists for the appointment
        ItemId := CreateGuid();
        CreateOfficeInvoiceRecord(CustNo, ItemId, SalesHeader);

        // [WHEN] User clicks the New Sales Invoice add-in command for an appointment
        OfficeAddinContext.SetRange("Item ID", ItemId);
        OfficeAddinContext.SetRange(Duration, '3');
        OfficeAddinContext.SetRange(Email, CustEmail);
        OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);
        OfficeAddinContext.SetRange(Command, CommandType.NewSalesInvoice);

        OfficeInvoiceSelection.Trap();
        CustomerCard.Trap();
        RunMailEngine(OfficeAddinContext);

        // [THEN] Office invoice selection page is shown
        OfficeInvoiceSelection."No.".AssertEquals(SalesHeader."No.");
        OfficeInvoiceSelection."Sell-to Customer Name".AssertEquals(SalesHeader."Sell-to Customer Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceExistsPageCreateNewInvoice()
    var
        SalesHeader: Record "Sales Header";
        CustomerCard: TestPage "Customer Card";
        OfficeInvoiceSelection: TestPage "Office Invoice Selection";
        SalesInvoice: TestPage "Sales Invoice";
        CustEmail: Text[80];
        ItemId: Text[250];
    begin
        // [FEATURE] [Customer] [Invoice]
        // [SCENARIO 166905] Invoice exists page allows user to create a new invoice for the customer.
        Initialize();

        // [GIVEN] Customer exists with email address
        // [WHEN] Add-in is launched for the customer from an appointment
        RunWithCustomer(CustomerCard, ItemId, CustEmail, true);

        // [GIVEN] Office invoice record exists for the appointment
        CreateOfficeInvoiceRecord(CustomerCard."No.".Value, ItemId, SalesHeader);

        // [WHEN] New invoice action is invoked
        OfficeInvoiceSelection.Trap();
        CustomerCard.NewSalesInvoice.Invoke();

        // [WHEN] Create new invoice link is clicked on the page
        SalesInvoice.Trap();
        asserterror OfficeInvoiceSelection.NewInvoice.DrillDown(); // Need asserterror because this action causes the page to close.

        // [THEN] New invoice is created for the customer
        SalesInvoice.Control1900316107."No.".AssertEquals(CustomerCard."No.".Value);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceExistsPageShowOngoingInvoice()
    var
        SalesHeader: Record "Sales Header";
        CustomerCard: TestPage "Customer Card";
        OfficeInvoiceSelection: TestPage "Office Invoice Selection";
        SalesInvoice: TestPage "Sales Invoice";
        CustEmail: Text[80];
        ItemId: Text[250];
    begin
        // [FEATURE] [Customer] [Invoice]
        // [SCENARIO 166905] Invoice exists page allows user to view an existing invoice.
        Initialize();

        // [GIVEN] Customer exists with email address
        // [WHEN] Add-in is launched for the customer from an appointment
        RunWithCustomer(CustomerCard, ItemId, CustEmail, true);

        // [GIVEN] Office invoice record exists for the appointment
        CreateOfficeInvoiceRecord(CustomerCard."No.".Value, ItemId, SalesHeader);

        // [WHEN] New invoice action is invoked
        OfficeInvoiceSelection.Trap();
        CustomerCard.NewSalesInvoice.Invoke();

        // [WHEN] "No." field is clicked on the page to drill into that invoice
        SalesInvoice.Trap();
        OfficeInvoiceSelection."No.".DrillDown();

        // [THEN] The correct sales invoice is opened
        SalesInvoice."No.".AssertEquals(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceExistsPageShowPostedInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OfficeInvoice: Record "Office Invoice";
        OfficeInvoiceSelection: TestPage "Office Invoice Selection";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Customer] [Invoice]
        // [SCENARIO 166905] Invoice exists page allows user to navigate to posted invoice.
        Initialize();

        // [GIVEN] Office invoice record exists for the appointment
        SalesInvoiceHeader.FindFirst();
        OfficeInvoice.DeleteAll();
        OfficeInvoice.Init();
        OfficeInvoice."Document No." := SalesInvoiceHeader."No.";
        OfficeInvoice.Posted := true;
        OfficeInvoice.Insert(true);

        // [WHEN] New invoice action is invoked
        OfficeInvoiceSelection.Trap();
        PAGE.Run(PAGE::"Office Invoice Selection", OfficeInvoice);

        // [WHEN] "No." field is clicked on the page to drill into that posted invoice
        PostedSalesInvoice.Trap();
        InvoiceNo := OfficeInvoiceSelection."No.".Value();
        OfficeInvoiceSelection."No.".DrillDown();

        // [THEN] The correct posted sales invoice is opened
        PostedSalesInvoice."No.".AssertEquals(InvoiceNo);
        PostedSalesInvoice."Sell-to Customer Name".AssertEquals(PostedSalesInvoice."Sell-to Customer Name");
    end;

    local procedure CreateOfficeInvoiceRecord(CustNo: Code[20]; ItemId: Text[250]; var SalesHeader: Record "Sales Header")
    var
        OfficeInvoice: Record "Office Invoice";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);

        if ItemId = '' then
            ItemId := CreateGuid();

        OfficeInvoice.DeleteAll();
        OfficeInvoice.Init();
        OfficeInvoice."Item ID" := ItemId;
        OfficeInvoice."Document No." := SalesHeader."No.";
        OfficeInvoice.Insert(true);
    end;

    local procedure RunWithCustomerInvoice(var CustomerCard: TestPage "Customer Card"; var SalesInvoice: TestPage "Sales Invoice"; var ItemId: Text[250]; var CustEmail: Text[80]; IsAppointment: Boolean)
    begin
        RunWithCustomer(CustomerCard, ItemId, CustEmail, IsAppointment);

        SalesInvoice.Trap();
        CustomerCard.NewSalesInvoice.Invoke();
        SalesInvoice.Status.SetValue(0);
    end;

    local procedure RunWithCustomer(var CustomerCard: TestPage "Customer Card"; var ItemId: Text[250]; var CustEmail: Text[80]; IsAppointment: Boolean)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        CustContactNo: Code[20];
        NewBusRelCode: Code[10];
    begin
        CustEmail := RandomEmail();
        CreateContactFromCustomer(CustEmail, CustContactNo, NewBusRelCode, false);

        if ItemId = '' then
            ItemId := CreateGuid();

        OfficeAddinContext.SetRange("Item ID", ItemId);
        if IsAppointment then begin
            OfficeAddinContext.SetRange(Duration, '3');
            OfficeAddinContext.SetRange("Item Type", OfficeAddinContext."Item Type"::Appointment);
        end;
        OfficeAddinContext.SetRange(Email, CustEmail);

        CustomerCard.Trap();
        RunMailEngine(OfficeAddinContext);
    end;

    [Normal]
    local procedure RunMailEngine(var OfficeAddinContext: Record "Office Add-in Context")
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OutlookMailEngine: TestPage "Outlook Mail Engine";
    begin
        AddinManifestManagement.GetAddinByHostType(OfficeAddin, OfficeHostType.OutlookItemRead);
        OfficeAddinContext.SetRange(Version, OfficeAddin.Version);

        OutlookMailEngine.Trap();
        PAGE.Run(PAGE::"Outlook Mail Engine", OfficeAddinContext);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ActionHandler(Message: Text[1024])
    var
        ActualAction: Text;
        ActualFileName: Text;
        ActualEmailBody: Text;
        FileUrl: Text;
        ActualSubject: Text;
    begin
        ExtractComponent(Message, ActualAction);
        ExtractComponent(Message, FileUrl);
        ExtractComponent(Message, ActualFileName);
        ExtractComponent(Message, ActualEmailBody);
        ActualSubject := Message;

        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ActualAction, 'Incorrect JavaScript action called from C/AL.');
        Assert.AreEqual(1, StrPos(FileUrl, LibraryVariableStorage.DequeueText()), 'Unexpected file content passed to JS function.');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ActualFileName, 'Unexpected file name passed to JS function.');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ActualEmailBody, 'Unexpected email body passed to JS function.');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ActualSubject, 'Unexpected subject passed to JS function.');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MailEngineSelectCustContShwCustCardHandler(Message: Text[1024])
    var
        ActualAction: Text;
        Email: Text;
        ContactName: Text;
    begin
        ExtractComponent(Message, ActualAction);
        ExtractComponent(Message, ContactName);
        ExtractComponent(Message, Email);

        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ActualAction, 'Incorrect JavaScript action called from C/AL.');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Email, 'Unexpected email passed to JS function.');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ContactName, 'Unexpected contact name passed to JS function.');
    end;

    [Scope('OnPrem')]
    procedure ExtractComponent(var String: Text; var Component: Text)
    var
        DelimiterPos: Integer;
    begin
        DelimiterPos := StrPos(String, '|');
        Component := CopyStr(String, 1, DelimiterPos - 1);
        String := CopyStr(String, DelimiterPos + 1);
    end;

    [Scope('OnPrem')]
    procedure CheckActionParameter(ExpectedText: Text; ActualText: Text)
    begin
        case LowerCase(ExpectedText) of
            'any':
                Assert.AreNotEqual('', ActualText, 'Blank parameter passed to JavaScript function.');
            else
                Assert.AreEqual(ExpectedText, ActualText, 'Incorrect parameter passed to JavaScript function.');
        end;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SingleCustomerEngineHandler(var CustomerCard: TestPage "Customer Card")
    begin
        CustomerCard."No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SingleVendorEngineHandler(var VendorCard: TestPage "Vendor Card")
    begin
        VendorCard."No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SingleCustomerFBEngineHandler(var CustomerCard: TestPage "Customer Card")
    var
        OfficeManagement: Codeunit "Office Management";
    begin
        Assert.AreEqual(
          LibraryVariableStorage.DequeueBoolean(), OfficeManagement.IsAvailable(), 'Customer Fact Boxes visible property not correct');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SingleVendorFBEngineHandler(var VendorCard: TestPage "Vendor Card")
    var
        OfficeManagement: Codeunit "Office Management";
    begin
        Assert.AreEqual(
          LibraryVariableStorage.DequeueBoolean(), OfficeManagement.IsAvailable(), 'Vendor Fact Boxes visible property not correct');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ContactPageHandler(var ContactCard: TestPage "Contact Card")
    begin
        ContactCard."E-Mail".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure MultipleContactsEngineHandler(var OfficeContactAssociations: TestPage "Office Contact Associations")
    begin
        OfficeContactAssociations.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure MultipleContactsEngineHandlerSelect(var OfficeContactAssociations: TestPage "Office Contact Associations")
    var
        LinkNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(LinkNo);
        OfficeContactAssociations.FindFirstField("No.", LinkNo);
        OfficeContactAssociations."Customer/Vendor".Invoke();
        OfficeContactAssociations.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactDetailsDlgHandler(var OfficeContactDetailsDlg: TestPage "Office Contact Details Dlg")
    begin
        OfficeContactDetailsDlg."Associate to Company".SetValue(false);
        OfficeContactDetailsDlg.OK().Invoke();
    end;

    [Scope('OnPrem')]
    procedure CreateContactFromCustomer(Email: Text[80]; var ContactNo: Code[20]; var NewBusinessRelationCode: Code[10]; SetPerson: Boolean): Code[20]
    var
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        Customer: Record Customer;
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForCustomers := ChangeBusinessRelationCodeForCustomers(BusinessRelation.Code);
        NewBusinessRelationCode := BusinessRelation.Code;
        LibrarySales.CreateCustomer(Customer);

        ContactNo := UpdateContactEmail(BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Customer, Customer."No.", Email,
            SetPerson);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateContactFromVendor(Email: Text[80]; var ContactNo: Code[20]; var NewBusinessRelationCode: Code[10]; SetPerson: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        BusRelCodeForVendors := ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        NewBusinessRelationCode := BusinessRelation.Code;
        LibraryPurchase.CreateVendor(Vendor);

        ContactNo := UpdateContactEmail(BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.", Email,
            SetPerson);
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure UpdateContactEmail(BusinessRelationCode: Code[10]; LinkToTable: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]; Email: Text[80]; SetPerson: Boolean) ContactNo: Code[20]
    var
        Contact: Record Contact;
    begin
        ContactNo := FindContactNo(BusinessRelationCode, LinkToTable, LinkNo);
        Contact.Get(ContactNo);
        Contact."E-Mail" := Email;
        Contact."Search E-Mail" := UpperCase(Email);

        // Need to set the type to person, default of company will cause issues...
        if SetPerson = true then
            Contact.Type := Contact.Type::Person;

        Contact.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure FindContactNo(BusinessRelationCode: Code[10]; LinkToTable: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Business Relation Code", BusinessRelationCode);
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", LinkNo);
        ContactBusinessRelation.FindFirst();
        exit(ContactBusinessRelation."Contact No.");
    end;

    local procedure ChangeBusinessRelationCodeForCustomers(BusRelCodeForCustomers: Code[10]) OriginalBusRelCodeForCustomers: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        OriginalBusRelCodeForCustomers := MarketingSetup."Bus. Rel. Code for Customers";
        MarketingSetup.Validate("Bus. Rel. Code for Customers", BusRelCodeForCustomers);
        MarketingSetup.Modify(true);
    end;

    local procedure ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors: Code[10]) OriginalBusRelCodeForVendors: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        OriginalBusRelCodeForVendors := MarketingSetup."Bus. Rel. Code for Vendors";
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", BusRelCodeForVendors);
        MarketingSetup.Modify(true);
    end;

    local procedure Initialize()
    begin
        InitializeWithHostType(OfficeHostType.OutlookItemRead);
    end;

    local procedure InitializeWithHostType(HostType: Text)
    var
        OfficeAddin: Record "Office Add-in";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        OfficeAttachmentManager: Codeunit "Office Attachment Manager";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SMB Office Pages");

        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.Clear();
        Clear(LibraryOfficeHostProvider);
        BindSubscription(LibraryOfficeHostProvider);
        InitializeOfficeHostProvider(HostType);
        OfficeAttachmentManager.Done();

        // Lazy Setup.
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SMB Office Pages");

        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        SetupSales();
        SetupMarketing();

        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SMB Office Pages");
    end;

    local procedure InitializeOfficeHostProvider(HostType: Text)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeHostUnAvailable();
        SetOfficeHostProvider(CODEUNIT::"Library - Office Host Provider");
        OfficeManagement.InitializeHost(OfficeHost, HostType);
    end;

    local procedure SetOfficeHostUnAvailable()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        // Test Providers checks whether we have registered Host in NameValueBuffer or not
        if NameValueBuffer.Get(SessionId()) then begin
            NameValueBuffer.Delete();
            Commit();
        end;
    end;

    local procedure RandomEmail(): Text[80]
    begin
        exit(StrSubstNo('%1@%2', CreateGuid(), 'example.com'));
    end;

    local procedure CreateContact(var Contact: Record Contact; Type: Enum "Contact Type"): Text[80]
    var
        MarketingSetup: Record "Marketing Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        MarketingSetup.Get();
        SalespersonPurchaser.FindFirst();
        Contact.Init();
        Contact.Type := Type;
        Contact.Insert(true);
        Contact.Validate(Name, Contact."No.");  // Validating Name as No. because value is not important.
        Contact.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Contact.Validate("E-Mail", RandomEmail());
        Contact.Modify(true);
        exit(Contact."E-Mail");
    end;

    [Scope('OnPrem')]
    procedure SetupSales()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Stockout Warning" := false;
        if SalesReceivablesSetup."Blanket Order Nos." = '' then
            SalesReceivablesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesReceivablesSetup."Return Order Nos." = '' then
            SalesReceivablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesReceivablesSetup."Order Nos." = '' then
            SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesReceivablesSetup."Quote Nos." = '' then
            SalesReceivablesSetup.Validate("Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        if SalesReceivablesSetup."Customer Nos." = '' then
            SalesReceivablesSetup.Validate("Customer Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetupMarketing()
    var
        MarketingSetup: Record "Marketing Setup";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        MarketingSetup.Get();
        if MarketingSetup."Contact Nos." = '' then
            MarketingSetup.Validate("Contact Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        MarketingSetup.Modify();
    end;

    local procedure SetOfficeHostProvider(ProviderId: Integer)
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        OfficeAddinSetup.Get();
        OfficeAddinSetup."Office Host Codeunit ID" := ProviderId;
        OfficeAddinSetup.Modify();
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure GetPopOutUrl(PageNo: Integer; DocNo: Code[20]): Text
    var
        BaseURL: Text;
        CompanyQueryPos: Integer;
    begin
        BaseURL := GetUrl(CLIENTTYPE::Web, CompanyName);
        CompanyQueryPos := StrPos(LowerCase(BaseURL), '?');
        BaseURL := InsStr(BaseURL, '/OfficePopOut.aspx', CompanyQueryPos) + '&';
        exit(StrSubstNo('%1mode=edit&page=%2&filter=''No.'' IS ''%3''', BaseURL, PageNo, DocNo));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure OfficeContactDlgHandlerCreatePersonContact(var OfficeNewContactDlg: TestPage "Office New Contact Dlg")
    begin
        // Creating a new contact closes the dlg page, so we expect an error here.
        asserterror OfficeNewContactDlg.NewPersonContact.DrillDown();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure OfficeContactDlgHandlerShowList(var OfficeNewContactDlg: TestPage "Office New Contact Dlg")
    begin
        OfficeNewContactDlg.LinkContact.DrillDown();
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}

