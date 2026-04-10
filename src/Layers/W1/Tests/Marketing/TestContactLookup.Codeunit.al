codeunit 134837 "Test Contact Lookup"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Contact] [UI]
        IsInitialized := false;
    end;

    var
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ConfirmStubQst: Label 'Confirm Stub';
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        ChangeQst: Label 'Do you want to change';

    [Test]
    [HandlerFunctions('ContactListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SellToContactLookupOnSalesDocTest()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup - Initialize
        Initialize();

        // Setup - Create a Customer with a Contact
        LibrarySmallBusiness.CreateCustomer(Customer);
        Customer.Validate(Contact, StrSubstNo('%1 %2', LibraryUtility.GenerateRandomText(10), LibraryUtility.GenerateRandomText(10)));

        // Setup - Create a Sales Order for the created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // Execute - Lookup the Contact field
        LibraryVariableStorage.Enqueue(Customer."Primary Contact No.");
        SalesOrder."Sell-to Contact".Lookup();

        // Verify - Modal page handler does the verification
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ContactListModalPageHandler')]
    [Scope('OnPrem')]
    procedure BillToContactLookupOnSalesDocTest()
    var
        SellToCustomer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup - Initialize
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // Setup - Create a Sell-to Customer amd a Bill-to Customer with a Contact each
        LibrarySmallBusiness.CreateCustomer(SellToCustomer);
        SellToCustomer.Validate(Contact, StrSubstNo('%1 %2', LibraryUtility.GenerateRandomText(10), LibraryUtility.GenerateRandomText(10)));
        LibrarySmallBusiness.CreateCustomer(BillToCustomer);
        BillToCustomer.Validate(Contact, StrSubstNo('%1 %2', LibraryUtility.GenerateRandomText(10), LibraryUtility.GenerateRandomText(10)));

        // Setup - Create a Sales Order for the created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Modify(true);

        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // Execute - Lookup the Contact field
        LibraryVariableStorage.Enqueue(BillToCustomer."Primary Contact No.");
        SalesOrder."Bill-to Contact".Lookup();

        // Verify - Modal page handler does the verification
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromContactLookupOnPurchaseDocTest()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Setup - Initialize
        Initialize();

        // Setup - Create a Vendor with a Contact
        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Validate(Contact, StrSubstNo('%1 %2', LibraryUtility.GenerateRandomText(10), LibraryUtility.GenerateRandomText(10)));

        // Setup - Create a Purchase Invoice for the created vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Execute - Lookup the Contact field
        LibraryVariableStorage.Enqueue(Vendor."Primary Contact No.");
        PurchaseInvoice."Buy-from Contact".Lookup();

        // Verify - Modal page handler does the verification
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ContactListModalPageHandler')]
    [Scope('OnPrem')]
    procedure PayToContactLookupOnPurchaseDocTest()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Setup - Initialize
        Initialize();

        // Setup - Create a Buy-From Vendor amd a Pay-to Vendor with a Contact each
        LibrarySmallBusiness.CreateVendor(BuyFromVendor);
        BuyFromVendor.Validate(Contact, StrSubstNo('%1 %2', LibraryUtility.GenerateRandomText(10), LibraryUtility.GenerateRandomText(10)));
        LibrarySmallBusiness.CreateVendor(PayToVendor);
        PayToVendor.Validate(Contact, StrSubstNo('%1 %2', LibraryUtility.GenerateRandomText(10), LibraryUtility.GenerateRandomText(10)));

        // Setup - Create a Purchase Invoice for the created vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, BuyFromVendor."No.");
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendor."No.");
        PurchaseHeader.Modify(true);

        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);

        // Execute - Lookup the Contact field
        LibraryVariableStorage.Enqueue(PayToVendor."Primary Contact No.");
        PurchaseInvoice."Pay-to Contact".Lookup();

        // Verify - Modal page handler does the verification
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ContactLookupOnCustomerCardTest()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // Setup - Initialize
        Initialize();

        // Setup - Create a Customer with a Contact
        LibrarySmallBusiness.CreateCustomer(Customer);
        Customer.Validate(Contact, StrSubstNo('%1 %2', LibraryUtility.GenerateRandomText(10), LibraryUtility.GenerateRandomText(10)));

        // Setup - Open a Customer Card
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // Execute - Lookup the Contact field
        LibraryVariableStorage.Enqueue(Customer."Primary Contact No.");
        CustomerCard.ContactName.Lookup();

        // Verify - Modal page handler does the verification
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ContactLookupOnVendorCardTest()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // Setup - Initialize
        Initialize();

        // Setup - Create Vendor with a Contact
        LibrarySmallBusiness.CreateVendor(Vendor);
        Vendor.Validate(Contact, StrSubstNo('%1 %2', LibraryUtility.GenerateRandomText(10), LibraryUtility.GenerateRandomText(10)));

        // Setup - Open a Vendor Card
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // Execute - Lookup the Contact field
        LibraryVariableStorage.Enqueue(Vendor."Primary Contact No.");
        VendorCard.Control16.Lookup();

        // Verify - Modal page handler does the verification
    end;

    [Test]
    [HandlerFunctions('ContactListCheckFilterModalPageHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure BlankCustomerSellToContactLookupOnSalesQuoteTest()
    var
        Contact: Record Contact;
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 234080] When Customer No. is blank in Sales Quote then on contact look up the contact list is filtered by Company No. of the contact no. populated in the quote
        Initialize();

        if Confirm(ConfirmStubQst) then;

        // [GIVEN] Contact "C" with "Company No."
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] "Sales Quote" with blank "Sell-to Customer No." and "Bill-to Customer No." but "Sell-to Contact No." is equal to "C"
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Contact No.".SetValue(Contact."No.");

        // [WHEN] Look up contact list from "Sell-to Contact"
        LibraryVariableStorage.Enqueue(Contact."No.");
        SalesQuote."Sell-to Contact".Lookup();

        // [THEN] Filter of the field "Company No." of the contact list is equal to the "Company No." of "C"
        // Verification in ContactListCheckFilterModalPageHandler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckBillToContactWhenUpdateBillToContactToAnotherContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactNew: Record Contact;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 272585] In table Sales Header field Bill-to Contact is updated when it changed to another Contact.Name. (Cont.Type = Cont.Type::Person)
        Initialize();

        // [GIVEN] Customer with two  person contacts "C1" and "C2"
        CreateCustomerWithTwoPersonContacts(Customer, Contact, ContactNew);
        // [GIVEN] Sales Header with Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [WHEN] Sales Header's Bill-to contact updated to C2.Name
        SalesHeader."Bill-to Contact" := ContactNew.Name;
        SalesHeader.Validate("Bill-to Contact No.", ContactNew."No.");

        // [THEN] Sales Header has "Bill-to Contact" = C2.Name
        SalesHeader.TestField("Bill-to Contact", ContactNew.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckBillToContactWhenUpdateBillToContactToCompanyContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactNew: Record Contact;
        SalesHeader: Record "Sales Header";
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactCompany: Record Contact;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 272585]  In table Sales Header field Bill-to Contact is updated to Customer Primary Contact when it changed to Customer Contact Name
        Initialize();

        // [GIVEN] Customer with two contacts "C1" and "C2"
        CreateCustomerWithTwoPersonContacts(Customer, Contact, ContactNew);
        // [GIVEN] Sales Header with Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [WHEN] Sales Header's Bill-to contact updated to company contact name
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.FindFirst();
        ContactCompany.Get(ContactBusinessRelation."Contact No.");
        SalesHeader."Bill-to Contact" := ContactCompany.Name;
        SalesHeader.Validate("Bill-to Contact No.", ContactCompany."No.");

        // [THEN] Sales Header has "Bill-to Contact" = C1.Name
        SalesHeader.TestField("Bill-to Contact", Contact.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckSelllToContactWhenUpdateSellToContactToAnotherContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactNew: Record Contact;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 272585] In table Sales Header field Sell-to Contact is updated when it changed to another Contact.Name. (Cont.Type = Cont.Type::Person)
        Initialize();

        // [GIVEN] Customer with two contacts "C1" and "C2"
        CreateCustomerWithTwoPersonContacts(Customer, Contact, ContactNew);
        // [GIVEN] Sales Header with Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [WHEN] Sales Header's Sell-to contact updated to C2.Name
        SalesHeader."Sell-to Contact" := ContactNew.Name;
        SalesHeader.Validate("Sell-to Contact No.", ContactNew."No.");

        // [THEN] Sales Header has "Sell-to Contact" = C2.Name
        SalesHeader.TestField("Sell-to Contact", ContactNew.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckSelllToContactWhenUpdateSellToContactToCompanyContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactNew: Record Contact;
        SalesHeader: Record "Sales Header";
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactCompany: Record Contact;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 272585]  In table Sales Header field Sell-to Contact is updated to Customer Primary Contact when it changed to Customer Contact Name
        Initialize();

        // [GIVEN] Customer with two contacts "C1" and "C2"
        CreateCustomerWithTwoPersonContacts(Customer, Contact, ContactNew);
        // [GIVEN] Sales Header with Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [WHEN] Sales Header's Sell-to contact updated to company contact name
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.FindFirst();
        ContactCompany.Get(ContactBusinessRelation."Contact No.");
        SalesHeader."Sell-to Contact" := ContactCompany.Name;
        SalesHeader.Validate("Sell-to Contact No.", ContactCompany."No.");

        // [THEN] Sales Header has "Sell-to Contact" = C1.Name
        SalesHeader.TestField("Sell-to Contact", Contact.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckPayToContactWhenUpdatePayToContactToAnotherContact()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContactNew: Record Contact;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 272585] In table Purchase Header field Pay-to Contact is updated when it changed to another Contact.Name. (Cont.Type = Cont.Type::Person)
        Initialize();

        // [GIVEN] Vendor with two person contacts "C1" and "C2"
        CreateVendorWithTwoPersonContacts(Vendor, Contact, ContactNew);
        // [GIVEN] Purchase Header with Vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, Vendor."No.");

        // [WHEN] Purchase Header's Pay-to contact updated to C2.Name
        PurchaseHeader."Pay-to Contact" := ContactNew.Name;
        PurchaseHeader.Validate("Pay-to Contact No.", ContactNew."No.");

        // [THEN] Purchase Header has "Pay-to Contact" = C2.Name
        PurchaseHeader.TestField("Pay-to Contact", ContactNew.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckPayToContactWhenUpdatePayToContactToCompanyContact()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContactNew: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactCompany: Record Contact;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 272585]  In table Purchase Header field Pay-to Contact is updated to Vendor Primary Contact when it changed to Vendor Contact Name
        Initialize();

        // [GIVEN] Vendor with two  person contacts "C1" and "C2"
        CreateVendorWithTwoPersonContacts(Vendor, Contact, ContactNew);
        // [GIVEN] Purchase Header with Vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, Vendor."No.");

        // [WHEN] Purchase Header's Pay-to contact updated to company contact name
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", Vendor."No.");
        ContactBusinessRelation.FindFirst();
        ContactCompany.Get(ContactBusinessRelation."Contact No.");
        PurchaseHeader."Pay-to Contact" := ContactCompany.Name;
        PurchaseHeader.Validate("Pay-to Contact No.", ContactCompany."No.");

        // [THEN] Purchase Header has "Pay-to Contact" = C1.Name
        PurchaseHeader.TestField("Pay-to Contact", Contact.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckBuyFromContactWhenUpdateBuyFromContactToAnotherContact()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContactNew: Record Contact;
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 272585] In table Purchase Header field Buy-from Contact is updated when it changed to another Contact.Name. (Cont.Type = Cont.Type::Person)
        Initialize();

        // [GIVEN] Vendor with two person contacts "C1" and "C2"
        CreateVendorWithTwoPersonContacts(Vendor, Contact, ContactNew);
        // [GIVEN] Purchase Header with Vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, Vendor."No.");

        // [WHEN] Purchase Header's Buy-from contact updated to C2.Name
        PurchaseHeader."Buy-from Contact" := ContactNew.Name;
        PurchaseHeader.Validate("Buy-from Contact No.", ContactNew."No.");

        // [THEN] Purchase Header has "Buy-from Contact" = C2.Name
        PurchaseHeader.TestField("Buy-from Contact", ContactNew.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckBuyFromContactWhenUpdateBuyFromContactToCompanyContact()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContactNew: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactCompany: Record Contact;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 272585]  In table Purchase Header field Buy-from Contact is updated to Vendor Primary Contact when it changed to Vendor Contact Name
        Initialize();

        // [GIVEN] Vendor with two  person contacts "C1" and "C2"
        CreateVendorWithTwoPersonContacts(Vendor, Contact, ContactNew);
        // [GIVEN] Purchase Header with Vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, Vendor."No.");

        // [WHEN] Purchase Header's Buy-from contact updated to company contact name
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", Vendor."No.");
        ContactBusinessRelation.FindFirst();
        ContactCompany.Get(ContactBusinessRelation."Contact No.");
        PurchaseHeader."Buy-from Contact" := ContactCompany.Name;
        PurchaseHeader.Validate("Buy-from Contact No.", ContactCompany."No.");

        // [THEN] Purchase Header has "Buy-from Contact" = C1.Name
        PurchaseHeader.TestField("Buy-from Contact", Contact.Name);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesEnqueueQuestion')]
    procedure ShipToAddressWhenSetBlankSellToContactOnSalesDocument()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactNew: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        ShippingOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";
    begin
        // [SCENARIO 403724] "Ship-to" option value when update field "Contact" of General fasttab with blank value on Sales Quote card.
        Initialize();

        // [GIVEN] Customer with two contacts "C1" and "C2". "C1" is a primary contact for Customer.
        CreateCustomerWithTwoPersonContacts(Customer, Contact, ContactNew);

        // [GIVEN] Sales Quote for Customer.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [GIVEN] Opened Sales Quote card. "Contact" field of General fasttab filled with "C1" Name.
        // [GIVEN] Ship-to = "Default (Sell-to Address)". Ship-to Contact = "C1" Name.
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");
        SalesQuote."Sell-to Contact".AssertEquals(Contact.Name);
        SalesQuote."Ship-to Contact".AssertEquals(Contact.Name);
        SalesQuote.ShippingOptions.AssertEquals(ShippingOptions::"Default (Sell-to Address)");

        // [WHEN] Set blank value to "Contact" field of General fasttab. Reply Yes to confirm question. Reopen Sales Quote card.
        SalesQuote."Sell-to Contact".SetValue('');
        SalesQuote.Close();
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] Confirm dialog with question "Do you want to change Sell-to Contact No.?" was shown.
        Assert.ExpectedMessage(ChangeQst, LibraryVariableStorage.DequeueText());

        // [THEN] Ship-to Contact value was set to blank. Ship-to value was not updated, it is "Default (Sell-to Address)".
        SalesQuote.ShippingOptions.AssertEquals(ShippingOptions::"Default (Sell-to Address)");
        SalesQuote."Ship-to Contact".AssertEquals('');

        // [THEN] Sell-to Contact and Sell-to Contact No. values were set to blank.
        SalesQuote."Sell-to Contact".AssertEquals('');
        SalesQuote."Sell-to Contact No.".AssertEquals('');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ShipToAddressWhenSetNonBlankSellToContactOnSalesDocument()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        DummyContact: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        ShippingOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";
        SellToContactName: Text[100];
    begin
        // [SCENARIO 403724] "Ship-to" option value when update field "Contact" of General fasttab with nonblank value on Sales Quote card.
        Initialize();

        // [GIVEN] Customer with person contact "C1" which is a primary contact for Customer.
        CreateCustomerWithTwoPersonContacts(Customer, Contact, DummyContact);

        // [GIVEN] Sales Quote for Customer.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [GIVEN] Opened Sales Quote card. "Contact" field of General fasttab filled with "C1" Name.
        // [GIVEN] Ship-to = "Default (Sell-to Address)". Ship-to Contact = "C1" Name.
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");
        SalesQuote."Sell-to Contact".AssertEquals(Contact.Name);
        SalesQuote."Ship-to Contact".AssertEquals(Contact.Name);
        SalesQuote.ShippingOptions.AssertEquals(ShippingOptions::"Default (Sell-to Address)");

        // [WHEN] Set random nonblank value to "Contact" field of General fasttab. Reopen Sales Quote card.
        SellToContactName := LibraryUtility.GenerateGUID();
        SalesQuote."Sell-to Contact".SetValue(SellToContactName);
        SalesQuote.Close();
        SalesQuote.OpenEdit();
        SalesQuote.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] Ship-to Contact value was not upadated, it is equal to "C1" Name. Ship-to value was changed "Custom Address".
        SalesQuote.ShippingOptions.AssertEquals(ShippingOptions::"Custom Address");
        SalesQuote."Ship-to Contact".AssertEquals(Contact.Name);

        // [THEN] Sell-to Contact value was set to blank. Sell-to Contact No. value was not updated, it is "C1" No.
        SalesQuote."Sell-to Contact".AssertEquals(SellToContactName);
        SalesQuote."Sell-to Contact No.".AssertEquals(Contact."No.");
    end;

    local procedure Initialize()
    var
        ObjectOptions: Record "Object Options";
        PurchaseHeader: Record "Purchase Header";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Contact Lookup");
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();
        ObjectOptions.DeleteAll();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Contact Lookup");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Contact Lookup");
    end;

    local procedure CreateCustomerWithTwoPersonContacts(var Customer: Record Customer; var ContactPersonOne: Record Contact; var ContactPersonTwo: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibrarySales.CreateCustomer(Customer);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.FindFirst();
        LibraryMarketing.CreatePersonContact(ContactPersonOne);
        ContactPersonOne.Validate("Company No.", ContactBusinessRelation."Contact No.");
        ContactPersonOne.Modify(true);
        LibraryMarketing.CreatePersonContact(ContactPersonTwo);
        ContactPersonTwo.Validate("Company No.", ContactBusinessRelation."Contact No.");
        ContactPersonTwo.Modify(true);

        Customer.Validate("Primary Contact No.", ContactPersonOne."No.");
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithTwoPersonContacts(var Vendor: Record Vendor; var ContactPersonOne: Record Contact; var ContactPersonTwo: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.SetRange("No.", Vendor."No.");
        ContactBusinessRelation.FindFirst();
        LibraryMarketing.CreatePersonContact(ContactPersonOne);
        ContactPersonOne.Validate("Company No.", ContactBusinessRelation."Contact No.");
        ContactPersonOne.Modify(true);
        LibraryMarketing.CreatePersonContact(ContactPersonTwo);
        ContactPersonTwo.Validate("Company No.", ContactBusinessRelation."Contact No.");
        ContactPersonTwo.Modify(true);

        Vendor.Validate("Primary Contact No.", ContactPersonOne."No.");
        Vendor.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYesEnqueueQuestion(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListModalPageHandler(var ContactList: TestPage "Contact List")
    var
        Contact: Record Contact;
    begin
        Contact.Get(LibraryVariableStorage.DequeueText());
        ContactList."No.".AssertEquals(Contact."No.");
        Contact.TestField("Company No.", ContactList.FILTER.GetFilter("Company No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListCheckFilterModalPageHandler(var ContactList: TestPage "Contact List")
    var
        Contact: Record Contact;
    begin
        Contact.Get(LibraryVariableStorage.DequeueText());
        Contact.TestField("Company No.", ContactList.FILTER.GetFilter("Company No."));
    end;
}

