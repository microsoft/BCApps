codeunit 144145 "UT TAB Fiscal Code"
{
    // [FEATURE] [Fiscal Code] [UT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        VATRegistrationNoMsg: Label 'Value is not correct';
        VATRegistrationNoValidationMsg: Label 'Value %1 is not correct';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateVATRegistrationNoCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate VAT Registration No. - OnValidate trigger of Table ID - 79 Company Information.
        // Setup.
        Initialize();
        LibraryITLocalization.SetValidateLocVATRegNo(true); // Update Validate loc.VAT Reg. No. TRUE on General Ledger Setup.
        CompanyInformation.Get();

        // Exercise & Verify: Value not correct and Value of VAT Registration Number not correct message, verification done in MessageHandler.
        CompanyInformation.Validate("VAT Registration No.", CreateVATRegistrationNumber());
    end;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateVATRegistrationNoVendor()
    var
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate VAT Registration No. - OnValidate trigger of Table ID - 23 Vendor.

        // Setup: Update General Ledger Setup and create Vendor.
        Initialize();
        LibraryITLocalization.SetValidateLocVATRegNo(true); // Update Validate loc.VAT Reg. No. TRUE on General Ledger Setup.
        CreateVendor(Vendor, true, '');

        // Exercise & Verify: Value not correct and Value of VAT Registration Number not correct message, verification done in MessageHandler.
        Vendor.Validate("VAT Registration No.", CreateVATRegistrationNumber());
    end;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateVATRegistrationNoCustomer()
    var
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate VAT Registration No. - OnValidate trigger of Table ID - 18 Customer.

        // Setup: Update General Ledger Setup and create Customer.
        Initialize();
        LibraryITLocalization.SetValidateLocVATRegNo(true); // Update Validate loc.VAT Reg. No. TRUE on General Ledger Setup.
        CreateCustomer(Customer, true, '');

        // Exercise & Verify: Value not correct and Value of VAT Registration Number not correct message, verification done in MessageHandler.
        Customer.Validate("VAT Registration No.", CreateVATRegistrationNumber());
    end;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateVATRegistrationNoContact()
    var
        Contact: Record Contact;
    begin
        // Purpose of the test is to validate VAT Registration No. - OnValidate Trigger of Table ID - 5050 Contact.

        // Setup: Update General Ledger Setup and create Contact.
        Initialize();
        LibraryITLocalization.SetValidateLocVATRegNo(true); // Update Validate loc.VAT Reg. No. TRUE on General Ledger Setup.
        CreateContact(Contact, Contact.Type::Person);

        // Exercise & Verify: Value not correct and Value of VAT Registration Number not correct message, verification done in MessageHandler.
        Contact.Validate("VAT Registration No.", CreateVATRegistrationNumber());
    end;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeCompanyInformationNegative()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 376053] Validate Company Information "Fiscal Code" with wrong value
        Initialize();
        CompanyInformation.Get();
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);

        // [WHEN] Validate "Company Information"."Fiscal Code" = '100'
        CompanyInformation.Validate("Fiscal Code", Format(LibraryRandom.RandInt(100)));

        // [THEN] Message is displayed: "Value is not correct"
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeCompanyInformationPositive()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 376053] Validate Company Information "Fiscal Code" with correct Fiscal Code 16-chars value
        Initialize();
        CompanyInformation.Get();
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);

        // [WHEN] Validate "Company Information"."Fiscal Code" = 'MRTMTT25D09F205Z'
        CompanyInformation.Validate("Fiscal Code", LibraryITLocalization.GetFiscalCode());

        // [THEN] No error/warning message is displayed
        Assert.AreEqual(
          LibraryITLocalization.GetFiscalCode(), CompanyInformation."Fiscal Code", CompanyInformation.FieldCaption("Fiscal Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalVATCodeCompanyInformationPositive()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 376053] Validate Company Information "Fiscal Code" with correct VAT Code 11-chars value
        Initialize();
        CompanyInformation.Get();
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);

        // [WHEN] Validate "Company Information"."Fiscal Code" = '12345670124'
        CompanyInformation.Validate("Fiscal Code", LibraryITLocalization.GetVATCode());

        // [THEN] No error/warning message is displayed
        Assert.AreEqual(
          LibraryITLocalization.GetVATCode(), CompanyInformation."Fiscal Code", CompanyInformation.FieldCaption("Fiscal Code"));
    end;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeVendorNegative()
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 376053] Validate Vendor "Fiscal Code" with wrong value
        // [WHEN] Validate Vendor."Fiscal Code" = '100'
        // [THEN] Message is displayed: "Value is not correct"
        OnValidateFiscalCodeVendorNegativeScenario(false);
    end;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeVendorIndividualNegative()
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 376053] Validate Vendor (Individual Person) "Fiscal Code" with wrong value
        // [WHEN] Validate Vendor."Fiscal Code" = '100'
        // [THEN] Message is displayed: "Value is not correct"
        OnValidateFiscalCodeVendorNegativeScenario(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeVendorPositive()
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 376053] Validate Vendor "Fiscal Code" with correct Fiscal Code 16-chars value
        // [WHEN] Validate Vendor."Fiscal Code" = 'MRTMTT25D09F205Z'
        // [THEN] No error/warning message is displayed
        OnValidateFiscalCodeVendorPositiveScenario(false, LibraryITLocalization.GetFiscalCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeVendorIndividualPositive()
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 376053] Validate Vendor (Individual Person) "Fiscal Code" with correct Fiscal Code 16-chars value
        // [WHEN] Validate Vendor."Fiscal Code" = 'MRTMTT25D09F205Z'
        // [THEN] No error/warning message is displayed
        OnValidateFiscalCodeVendorPositiveScenario(true, LibraryITLocalization.GetFiscalCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalVATCodeVendorPositive()
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 376053] Validate Vendor "Fiscal Code" with correct VAT Code 11-chars value
        // [WHEN] Validate Vendor."Fiscal Code" = '12345670124'
        // [THEN] No error/warning message is displayed
        OnValidateFiscalCodeVendorPositiveScenario(false, LibraryITLocalization.GetVATCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalVATCodeVendorIndividualPositive()
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 376053] Validate Vendor (Individual Person) "Fiscal Code" with correct VAT Code 11-chars value
        // [WHEN] Validate Vendor."Fiscal Code" = '12345670124'
        // [THEN] No error/warning message is displayed
        OnValidateFiscalCodeVendorPositiveScenario(true, LibraryITLocalization.GetVATCode());
    end;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeCustomerNegative()
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 376053] Validate Customer "Fiscal Code" with wrong Fiscal Code value
        // [WHEN] Validate Customer."Fiscal Code" = '100'
        // [THEN] Message is displayed: "Value is not correct"
        OnValidateFiscalCodeCustomerNegativeScenario(false);
    end;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeCustomerIndividualNegative()
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 376053] Validate Customer (Individual Person) "Fiscal Code" with wrong Fiscal Code value
        // [WHEN] Validate Customer."Fiscal Code" = '100'
        // [THEN] Message is displayed: "Value is not correct"
        OnValidateFiscalCodeCustomerNegativeScenario(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeCustomerPositive()
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 376053] Validate Customer "Fiscal Code" with correct Fiscal Code 16-chars value
        // [WHEN] Validate Customer."Fiscal Code" = 'MRTMTT25D09F205Z'
        // [THEN] No error/warning message is displayed
        OnValidateFiscalCodeCustomerPositiveScenario(false, LibraryITLocalization.GetFiscalCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeCustomerIndividualPositive()
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 376053] Validate Customer (Individual Person) "Fiscal Code" with correct Fiscal Code 16-chars value
        // [WHEN] Validate Customer."Fiscal Code" = 'MRTMTT25D09F205Z'
        // [THEN] No error/warning message is displayed
        OnValidateFiscalCodeCustomerPositiveScenario(true, LibraryITLocalization.GetFiscalCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalVATCodeCustomerPositive()
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 376053] Validate Customer "Fiscal Code" with correct VAT Code 11-chars value
        // [WHEN] Validate Customer."Fiscal Code" = '12345670124'
        // [THEN] No error/warning message is displayed
        OnValidateFiscalCodeCustomerPositiveScenario(false, LibraryITLocalization.GetVATCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalVATCodeCustomerIndividualPositive()
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 376053] Validate Customer (Individual Person) "Fiscal Code" with correct VAT Code 11-chars value
        // [WHEN] Validate Customer."Fiscal Code" = '12345670124'
        // [THEN] No error/warning message is displayed
        OnValidateFiscalCodeCustomerPositiveScenario(true, LibraryITLocalization.GetVATCode());
    end;

    [Test]
    [HandlerFunctions('VATRegistrationNumberMessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeContactNegative()
    var
        Contact: Record Contact;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 376053] Validate Contact "Fiscal Code" with  wrong Fiscal Code value
        Initialize();
        CreateContact(Contact, Contact.Type::Person);
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);

        // [WHEN] Validate Contact."Fiscal Code" = '100'
        Contact.Validate("Fiscal Code", Format(LibraryRandom.RandInt(100)));

        // [THEN] Message is displayed: "Value is not correct"
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalCodeContactPositive()
    var
        Contact: Record Contact;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 376053] Validate Contact "Fiscal Code" with correct Fiscal Code 16-chars value
        Initialize();
        CreateContact(Contact, Contact.Type::Person);
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);

        // [WHEN] Validate Contact."Fiscal Code" = 'MRTMTT25D09F205Z'
        Contact.Validate("Fiscal Code", LibraryITLocalization.GetFiscalCode());

        // [THEN] No error/warning message is displayed
        Assert.AreEqual(LibraryITLocalization.GetFiscalCode(), Contact."Fiscal Code", Contact.FieldCaption("Fiscal Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateFiscalVATCodeContactPositive()
    var
        Contact: Record Contact;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 376053] Validate Contact "Fiscal Code" with correct VAT Code 11-chars value
        Initialize();
        CreateContact(Contact, Contact.Type::Person);
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);

        // [WHEN] Validate Contact."Fiscal Code" = '12345670124'
        Contact.Validate("Fiscal Code", LibraryITLocalization.GetVATCode());

        // [THEN] No error/warning message is displayed
        Assert.AreEqual(LibraryITLocalization.GetVATCode(), Contact."Fiscal Code", Contact.FieldCaption("Fiscal Code"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateVendorOnContactTypePerson()
    var
        Contact: Record Contact;
    begin
        // Purpose of the test is to validate Fiscal Code - OnValidate Trigger of Table ID - 5050 Contact.
        OnValidateVendorOnContactType(Contact.Type::Person, true);  // Individual Person - True.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OnValidateVendorOnContactTypeCompany()
    var
        Contact: Record Contact;
        VendorTempl: Record "Vendor Templ.";
    begin
        // Purpose of the test is to validate Fiscal Code - OnValidate Trigger of Table ID - 5050 Contact.
        VendorTempl.DeleteAll(true);
        LibraryTemplates.CreateVendorTemplateWithData(VendorTempl);
        OnValidateVendorOnContactType(Contact.Type::Company, false);  // Individual Person - False.
    end;

    local procedure OnValidateVendorOnContactType(Type: Enum "Contact Type"; IndividualPerson: Boolean)
    var
        Contact: Record Contact;
        ContactList: TestPage "Contact List";
    begin
        // Setup: Create Contact and open Contact List page.
        Initialize();
        CreateContact(Contact, Type);
        OpenContactListPage(ContactList, Contact."No.");

        // Exercise.
        ContactList.Vendor.Invoke();

        // Verify: Verify Fiscal Code, Individual Person and Vendor Name.
        VerifyFiscalCodeIndividualPersonAndVendorName(Contact, IndividualPerson);
        ContactList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FiscalCodeIsValidatedFromBillToCustomerNo()
    var
        SellToCustomer: Record Customer;
        BillToCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Bill-to Customer]
        // [SCENARIO 270797] Fiscal code in sales order should be populated from bill-to customer.
        Initialize();

        // [GIVEN] Customer "Bill" with "Fiscal Code" = "X".
        LibrarySales.CreateCustomer(BillToCustomer);
        BillToCustomer.Validate("Fiscal Code", LibraryITLocalization.GetVATCode());
        BillToCustomer.Modify(true);

        // [GIVEN] Customer "Sell" with "Fiscal Code" = "Y" and "Bill-to Customer No." = "Bill".
        LibrarySales.CreateCustomer(SellToCustomer);
        SellToCustomer.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SellToCustomer.Validate("Fiscal Code", LibraryITLocalization.GetFiscalCode());
        SellToCustomer.Modify(true);

        // [WHEN] Create sales order for customer "Sell".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");

        // [THEN] "Fiscal Code" on the sales order = "X".
        SalesHeader.TestField("Fiscal Code", BillToCustomer."Fiscal Code");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTemplates.EnableTemplatesFeature();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
    end;

    local procedure OnValidateFiscalCodeVendorNegativeScenario(Individual: Boolean)
    var
        Vendor: Record Vendor;
    begin
        Initialize();
        CreateVendor(Vendor, Individual, CreateVATRegNoFormat());
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);
        Vendor.Validate("Fiscal Code", Format(LibraryRandom.RandInt(100)));
    end;

    local procedure OnValidateFiscalCodeVendorPositiveScenario(Individual: Boolean; FiscalCode: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Initialize();
        CreateVendor(Vendor, Individual, CreateVATRegNoFormat());
        Vendor.Validate("Fiscal Code", FiscalCode);
        Assert.AreEqual(FiscalCode, Vendor."Fiscal Code", Vendor.FieldCaption("Fiscal Code"));
    end;

    local procedure OnValidateFiscalCodeCustomerNegativeScenario(Individual: Boolean)
    var
        Customer: Record Customer;
    begin
        Initialize();
        CreateCustomer(Customer, Individual, CreateVATRegNoFormat());
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);
        Customer.Validate("Fiscal Code", Format(LibraryRandom.RandInt(100)));
    end;

    local procedure OnValidateFiscalCodeCustomerPositiveScenario(Individual: Boolean; FiscalCode: Code[20])
    var
        Customer: Record Customer;
    begin
        Initialize();
        CreateCustomer(Customer, Individual, CreateVATRegNoFormat());
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);
        Customer.Validate("Fiscal Code", FiscalCode);
        Assert.AreEqual(FiscalCode, Customer."Fiscal Code", Customer.FieldCaption("Fiscal Code"));
    end;

    local procedure CreateCustomer(var Customer: Record Customer; Individual: Boolean; CountryRegionCode: Code[10])
    begin
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer."Individual Person" := Individual;
        Customer."Country/Region Code" := CountryRegionCode;
        Customer.Insert();
    end;

    local procedure CreateContact(var Contact: Record Contact; ContactType: Enum "Contact Type")
    begin
        Contact."No." := LibraryUTUtility.GetNewCode();
        Contact."Company No." := Contact."No.";
        Contact."Company Name" := Contact."Company No.";
        Contact.Name := Contact."No.";
        Contact.Type := ContactType;
        Contact.Insert();
    end;

    local procedure CreateVATRegistrationNumber() VATRegistrationNo: Text[20]
    begin
        VATRegistrationNo := Format(LibraryRandom.RandIntInRange(100000000, 1000000000));  // VAT Registration Number 9 or 10 digit's required.

        // Required inside VATRegistrationNumberMessageHandler.
        LibraryVariableStorage.Enqueue(VATRegistrationNoMsg);
        LibraryVariableStorage.Enqueue(StrSubstNo(VATRegistrationNoValidationMsg, CopyStr(VATRegistrationNo, StrLen(VATRegistrationNo))));
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; Individual: Boolean; CountryRegionCode: Code[10])
    begin
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor."Individual Person" := Individual;
        Vendor."Country/Region Code" := CountryRegionCode;
        Vendor.Insert();
    end;

    local procedure CreateVATRegNoFormat(): Code[10]
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegion.Code);
        VATRegistrationNoFormat.Validate(Format, '#');
        VATRegistrationNoFormat.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure OpenContactListPage(var ContactList: TestPage "Contact List"; ContactNo: Code[20])
    begin
        ContactList.OpenEdit();
        ContactList.FILTER.SetFilter("No.", ContactNo);
    end;

    local procedure VerifyFiscalCodeIndividualPersonAndVendorName(Contact: Record Contact; IndividualPerson: Boolean)
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetRange(Name, Contact."No.");
        Vendor.FindFirst();
        Vendor.TestField("Fiscal Code", Contact."Fiscal Code");
        Vendor.TestField("Individual Person", IndividualPerson);
        Vendor.TestField(Name, Contact.Name);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VATRegistrationNumberMessageHandler(Message: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMsg);
        Assert.IsTrue(StrPos(Message, ExpectedMsg) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

