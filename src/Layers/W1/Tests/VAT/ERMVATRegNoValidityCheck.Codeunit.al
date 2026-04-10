codeunit 134060 "ERM VAT Reg. No Validity Check"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Registration No.] [VAT Registration Log]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTemplates: Codeunit "Library - Templates";
        WrongLogEntryOnPageErr: Label 'Unexpected entry in VAT Registration Log page.';
        NamespaceTxt: Label 'urn:ec.europa.eu:taxud:vies:services:checkVat:types', Locked = true;
        VATTxt: Label 'vat';
        ValidTxt: Label 'valid';
        NameTxt: Label 'traderName';
        AddressTxt: Label 'traderAddress';
        LibraryERM: Codeunit "Library - ERM";
        WrongLogEntryCountErr: Label 'Unexpected entry count in VAT Registration Log table.';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        GetVATRegNoErr: Label 'Unexpected output of GetVATRegNo method';
        GetCountryCodeErr: Label 'Not expected country code.';
        DisclaimerTxt: Label 'You are accessing a third-party website and service. Review the disclaimer before you continue.';
        VATRegNoVIESSettingIsNotEnabledErr: Label 'VAT Reg. No. Validation Setup is not enabled.';
        NoVATNoToValidateErr: Label 'Specify the VAT registration number that you want to verify.';
        EmptyCountryCodeErr: Label 'You must specify the country that issued the VAT registration number. Choose the country in the Country/Region Code field.';
        EmptyEUCountryCodeErr: Label 'You must specify the EU Country/Region Code for the country that issued the VAT registration number. You can specify that on the Country/Regions page.';
        CannotInsertMultipleSettingsErr: Label 'You cannot insert multiple settings.';

    [Test]
    [Scope('OnPrem')]
    procedure TestVATRegistrationLogEntryCreation()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        // When you modify the VAT Registration No. field on Customer, Vendor or Contact
        // A new entry in VAT Registration Log is added, and marked as "Not Verified"
        Initialize();
        CreateCustomer(Customer);
        CreateVendor(Vendor);
        CreateContact(Contact);

        VATRegistrationLog.Ascending(false);
        VATRegistrationLog.FindSet();
        VerifyVATRegLogEntry(
          VATRegistrationLog, VATRegistrationLog."Account Type"::Contact, Contact."No.",
          Contact."VAT Registration No.", VATRegistrationLog.Status::"Not Verified");
        VATRegistrationLog.Next();
        VerifyVATRegLogEntry(
          VATRegistrationLog, VATRegistrationLog."Account Type"::Vendor, Vendor."No.",
          Vendor."VAT Registration No.", VATRegistrationLog.Status::"Not Verified");
        VATRegistrationLog.Next();
        VerifyVATRegLogEntry(
          VATRegistrationLog, VATRegistrationLog."Account Type"::Customer, Customer."No.",
          Customer."VAT Registration No.", VATRegistrationLog.Status::"Not Verified");

        // Tear Down
        Customer.Delete();
        Vendor.Delete();
        Contact.Delete();
    end;

    [Test]
    [HandlerFunctions('VATRegistrationLogHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchingVatRegistrationLogCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [UI] [Customer]
        // [SCENARIO] When you click assist edit on "VAT Registration No." field on Customer page VAT Registration Log page is launched, and you can see the entire log
        Initialize();

        // [GIVEN] Create Customer "C" with "VAT Registration No." = "X"
        CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer."VAT Registration No.");

        // [GIVEN] Modify Customer "VAT Registration No." = "Y"
        ModifyCustomerVATRegNo(Customer);
        LibraryVariableStorage.Enqueue(Customer."VAT Registration No.");

        // [WHEN] Assist edit on "VAT Registration No." field on Costomer page
        OpenCustomerVATRegLog(Customer);

        // [THEN] VAT Registration Log page is launched and there are two Customer's entries:
        // [THEN] "Account Type" = "Customer", "Account No." = "C", "VAT Registration No." = "X"
        // [THEN] "Account Type" = "Customer", "Account No." = "C", "VAT Registration No." = "Y"

        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerCountryCodeChangeCausesVATValidation()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer] [VAT]
        // [SCENARIO] When user add country code and VAT number for a customer then decides to change country code again, VAT should be revalidated
        Initialize();

        // [GIVEN] Create Customer with country code 'DK' and correspondant VAT code
        CreateCustomer(Customer);

        // [When] User changes country code, VAT registration number should be revalidated, hence giving an error for old VAT number
        asserterror Customer.Validate("Country/Region Code", 'GB');

        // Tear Down
        asserterror Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorCountryCodeChangeCausesVATValidation()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor] [VAT]
        // [SCENARIO] When user add country code and VAT number for a vendor then decides to change country code again, VAT should be revalidated
        Initialize();

        // [GIVEN] Create Customer with country code 'DK' and correspondant VAT code
        CreateVendor(Vendor);

        // [WHEN] User changes country code, VAT registration number should be revalidated, hence giving an error for old VAT number
        asserterror Vendor.Validate("Country/Region Code", 'GB');

        // Tear Down
        asserterror Vendor.Delete();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VATRegistrationLogHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchingVatRegistrationLogCustomerCreatedFromContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
    begin
        // [FEATURE] [UI] [Customer] [Contact]
        // [SCENARIO 375488] When you click assist edit on "VAT Registration No." field on Customer (created from Contact) page VAT Registration Log page is launched, and you can see the entire log
        Initialize();

        // [GIVEN] Create Contact "A" with "VAT Registration No." = "X"
        CreateContact(Contact);
        LibraryVariableStorage.Enqueue(Contact."VAT Registration No.");

        // [GIVEN] Create Customer "C" from Contact "A"
        CreateCustomerFromContact(Customer, Contact);

        // [GIVEN] Modify Customer "VAT Registration No." = "Y"
        ModifyCustomerVATRegNo(Customer);
        LibraryVariableStorage.Enqueue(Customer."VAT Registration No.");

        // [WHEN] Assist edit on "VAT Registration No." field on Costomer page
        OpenCustomerVATRegLog(Customer);

        // [THEN] VAT Registration Log page is launched and there are two Customer's entries:
        // [THEN] "Account Type" = "Customer", "Account No." = "C", "VAT Registration No." = "X"
        // [THEN] "Account Type" = "Customer", "Account No." = "C", "VAT Registration No." = "Y"

        // Tear Down
        Contact.Delete();
        Customer.Delete();
    end;

    [Test]
    [HandlerFunctions('VATRegistrationLogHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchingVatRegistrationLogVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [UI] [Vendor]
        // [SCENARIO] When you click assist edit on "VAT Registration No." field on Vendor page VAT Registration Log page is launched, and you can see the entire log
        Initialize();

        // [GIVEN] Create Vendor "V" with "VAT Registration No." = "X"
        CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."VAT Registration No.");

        // [GIVEN] Modify Vendor "VAT Registration No." = "Y"
        ModifyVendorVATRegNo(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."VAT Registration No.");

        // [WHEN] Assist edit on "VAT Registration No." field on Vendor page
        OpenVendorVATRegLog(Vendor);

        // [THEN] VAT Registration Log page is launched and there are two Vendor's entries:
        // [THEN] "Account Type" = "Vendor", "Account No." = "V", "VAT Registration No." = "X"
        // [THEN] "Account Type" = "Vendor", "Account No." = "V", "VAT Registration No." = "Y"

        // Tear Down
        Vendor.Delete();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VATRegistrationLogHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchingVatRegistrationLogVendorCreatedFromContact()
    var
        Contact: Record Contact;
        Vendor: Record Vendor;
    begin
        // [FEATURE] [UI] [Vendor] [Contact]
        // [SCENARIO 375488] When you click assist edit on "VAT Registration No." field on Vendor (created from Contact) page VAT Registration Log page is launched, and you can see the entire log
        Initialize();

        // [GIVEN] Create Contact "A" with "VAT Registration No." = "X"
        CreateContact(Contact);
        LibraryVariableStorage.Enqueue(Contact."VAT Registration No.");

        // [GIVEN] Create Vendor "V" from Contact "A"
        CreateVendorFromContact(Vendor, Contact);

        // [GIVEN] Modify Vendor "VAT Registration No." = "Y"
        ModifyVendorVATRegNo(Vendor);
        LibraryVariableStorage.Enqueue(Vendor."VAT Registration No.");

        // [WHEN] Assist edit on "VAT Registration No." field on Vendor page
        OpenVendorVATRegLog(Vendor);

        // [THEN] VAT Registration Log page is launched and there are two Vendor's entries:
        // [THEN] "Account Type" = "Vendor", "Account No." = "V", "VAT Registration No." = "X"
        // [THEN] "Account Type" = "Vendor", "Account No." = "V", "VAT Registration No." = "Y"

        // Tear Down
        Contact.Delete();
        Vendor.Delete();
    end;

    [Test]
    [HandlerFunctions('VATRegistrationLogHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchingVatRegistrationLogContact()
    var
        Contact: Record Contact;
    begin
        // [FEATURE] [UI] [Contact]
        // [SCENARIO] When you click assist edit on "VAT Registration No." field on Contact page VAT Registration Log page is launched, and you can see the entire log
        Initialize();

        // [GIVEN] Create Contact "A" with "VAT Registration No." = "X"
        CreateContact(Contact);
        LibraryVariableStorage.Enqueue(Contact."VAT Registration No.");

        // [GIVEN] Modify Contact "VAT Registration No." = "Y"
        Contact.Validate("VAT Registration No.", Format(LibraryRandom.RandIntInRange(50000000, 59999999)));
        Contact.Modify();
        LibraryVariableStorage.Enqueue(Contact."VAT Registration No.");

        // [WHEN] Assist edit on "VAT Registration No." field on Contact page
        OpenContactVATRegLog(Contact);

        // [THEN] VAT Registration Log page is launched and there are two Contact's entries:
        // [THEN] "Account Type" = "Contact", "Account No." = "A", "VAT Registration No." = "X"
        // [THEN] "Account Type" = "Contact", "Account No." = "A", "VAT Registration No." = "Y"

        // Tear Down
        Contact.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletingEntityDeletesVATRegistrationLogEntries()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        Vendor: Record Vendor;
        VATRegistrationLog: Record "VAT Registration Log";
        CustomerNo: Code[20];
        VendorNo: Code[20];
        ContactNo: Code[20];
    begin
        // [FEATURE] [Customer] [Vendor] [Contact]
        // [SCENARIO] When you delete a Customer, Vendor or Contact then all corresponding VAT Registration Log Entries are deleted
        Initialize();

        CreateCustomer(Customer);
        CustomerNo := Customer."No.";
        Customer.Delete(true);
        VATRegistrationLog.SetRange("Account Type", VATRegistrationLog."Account Type"::Customer);
        VATRegistrationLog.SetRange("Account No.", CustomerNo);
        Assert.RecordIsEmpty(VATRegistrationLog);

        CreateVendor(Vendor);
        VendorNo := Vendor."No.";
        Vendor.Delete(true);
        VATRegistrationLog.SetRange("Account Type", VATRegistrationLog."Account Type"::Vendor);
        VATRegistrationLog.SetRange("Account No.", VendorNo);
        Assert.RecordIsEmpty(VATRegistrationLog);

        CreateContact(Contact);
        ContactNo := Contact."No.";
        Contact.Delete(true);
        VATRegistrationLog.SetRange("Account Type", VATRegistrationLog."Account Type"::Contact);
        VATRegistrationLog.SetRange("Account No.", ContactNo);
        Assert.RecordIsEmpty(VATRegistrationLog);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidVATRegistrationNo()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        ValidVATResponseDoc: DotNet XmlDocument;
        ValidatedName: Text;
        ValidatedAddress: Text;
        VATRegistrationLogCount: Integer;
    begin
        // When you invoke "Verify Registration No." on VAT Registration Log line, and the VAT Registration No. happens to be valid
        // You get the Status set to valid, and Verified Name and Verified Address populated by the input from the web service
        // NOTE: Do not test by calling the actual service (invoking the action). Test by constructing a mock response (XML File) and invoking the internal method.
        Initialize();
        CreateCustomer(Customer);

        VATRegistrationLogCount := VATRegistrationLog.Count();
        VATRegistrationLog.Ascending(false);
        VATRegistrationLog.FindFirst();
        ValidatedName := LibraryUtility.GenerateGUID();
        ValidatedAddress := LibraryUtility.GenerateGUID();
        CreateValidVATCheckResponse(ValidVATResponseDoc, ValidatedName, ValidatedAddress);
        VATRegistrationLogMgt.LogVerification(VATRegistrationLog, ValidVATResponseDoc, NamespaceTxt);
        VATRegistrationLog.TestField(Status, VATRegistrationLog.Status::Valid);
        VATRegistrationLog.TestField("Verified Name", ValidatedName);
        VATRegistrationLog.TestField("Verified Address", ValidatedAddress);
        Assert.RecordCount(VATRegistrationLog, VATRegistrationLogCount + 1);

        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidVATRegistrationNo()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        InvalidVATResponseDoc: DotNet XmlDocument;
        VATRegistrationLogCount: Integer;
    begin
        // When you invoke "Verify Registration No." on VAT Registration Log line, and the VAT Registration No. happens to be invalid
        // You get the Status set to invalid
        // NOTE: Do not test by calling the actual service (invoking the action). Test by constructing a mock response (XML File) and invoking the internal method.
        Initialize();
        CreateCustomer(Customer);

        VATRegistrationLogCount := VATRegistrationLog.Count();
        VATRegistrationLog.Ascending(false);
        VATRegistrationLog.FindFirst();
        CreateInvalidVATCheckResponse(InvalidVATResponseDoc);
        VATRegistrationLogMgt.LogVerification(VATRegistrationLog, InvalidVATResponseDoc, NamespaceTxt);
        VATRegistrationLog.TestField(Status, VATRegistrationLog.Status::Invalid);
        VATRegistrationLog.TestField("Verified Name", '');
        VATRegistrationLog.TestField("Verified Address", '');
        Assert.RecordCount(VATRegistrationLog, VATRegistrationLogCount + 1);

        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMaliciousResponseWithManyTags()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        ValidVATResponseDoc: DotNet XmlDocument;
        ValidatedName: Text;
        ValidatedAddress: Text;
        VATRegistrationLogCount: Integer;
    begin
        // When you invoke "Verify Registration No." on VAT Registration Log line, and you get a tampered response XML file with many tags
        // only the first tag will be processed and no more than one record will be added in the VAT Registration Log table
        Initialize();
        CreateCustomer(Customer);

        VATRegistrationLogCount := VATRegistrationLog.Count();
        VATRegistrationLog.Ascending(false);
        VATRegistrationLog.FindFirst();
        ValidatedName := LibraryUtility.GenerateGUID();
        ValidatedAddress := LibraryUtility.GenerateGUID();
        CreateVATCheckResponseWithManyTags(ValidVATResponseDoc, ValidatedName, ValidatedAddress);
        VATRegistrationLogMgt.LogVerification(VATRegistrationLog, ValidVATResponseDoc, NamespaceTxt);
        VATRegistrationLog.TestField(Status, VATRegistrationLog.Status::Valid);
        VATRegistrationLog.TestField("Verified Name", ValidatedName);
        VATRegistrationLog.TestField("Verified Address", ValidatedAddress);
        Assert.RecordCount(VATRegistrationLog, VATRegistrationLogCount + 1);

        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure TestMaliciousResponseWithEmptyResponseFile()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        EmptyVATResponseDoc: DotNet XmlDocument;
        VATRegistrationLogCount: Integer;
    begin
        // [SCENARIO 330015] VAT Registrion No. verification throws when it receives Xml Document with unexpected content or blank document.
        Initialize();
        CreateCustomer(Customer);

        VATRegistrationLogCount := VATRegistrationLog.Count();
        VATRegistrationLog.Ascending(false);
        VATRegistrationLog.FindFirst();
        EmptyVATResponseDoc := EmptyVATResponseDoc.XmlDocument();
        Commit();

        asserterror VATRegistrationLogMgt.LogVerification(VATRegistrationLog, EmptyVATResponseDoc, NamespaceTxt);
        Assert.ExpectedError('');

        // document empty - no line was logged
        Assert.RecordCount(VATRegistrationLog, VATRegistrationLogCount);

        // Tear Down
        Customer.Delete();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMaliciousResponseWithHugeNameAndAddress()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        ValidVATResponseDoc: DotNet XmlDocument;
        ValidatedName: Text;
        ValidatedAddress: Text;
        VATRegistrationLogCount: Integer;
        I: Integer;
    begin
        // When you invoke "Verify Registration No." on VAT Registration Log line, and you get a tampered response XML file with
        // huge values in name and address, which exceed 250 (MAXSTRLEN("Verified Name")) characters, only the first 250 characters
        // will be stored. No more than one record will be added in the VAT Registration Log table.
        Initialize();
        CreateCustomer(Customer);

        VATRegistrationLogCount := VATRegistrationLog.Count();
        VATRegistrationLog.Ascending(false);
        VATRegistrationLog.FindFirst();
        for I := 1 to 100 do begin
            ValidatedName += LibraryUtility.GenerateGUID();
            ValidatedAddress += LibraryUtility.GenerateGUID();
        end;
        CreateValidVATCheckResponse(ValidVATResponseDoc, ValidatedName, ValidatedAddress);
        VATRegistrationLogMgt.LogVerification(VATRegistrationLog, ValidVATResponseDoc, NamespaceTxt);
        VATRegistrationLog.TestField(Status, VATRegistrationLog.Status::Valid);
        VATRegistrationLog.TestField("Verified Name", CopyStr(ValidatedName, 1, MaxStrLen(VATRegistrationLog."Verified Name")));
        VATRegistrationLog.TestField("Verified Address", CopyStr(ValidatedAddress, 1, MaxStrLen(VATRegistrationLog."Verified Address")));
        Assert.RecordCount(VATRegistrationLog, VATRegistrationLogCount + 1);

        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVATRegNo()
    begin
        Initialize();
        VerifyGetVATRegNoOutput('be123.456.789', 'BE', '123456789');
        VerifyGetVATRegNoOutput('eS00000000K', 'es', '00000000K');
        VerifyGetVATRegNoOutput('ATU47584875', 'AT', 'U47584875');
        VerifyGetVATRegNoOutput('376473637', 'GB', '376473637');
        VerifyGetVATRegNoOutput('', 'DK', '');
        VerifyGetVATRegNoOutput('gb376-4736-37', 'GB', '376473637');
        VerifyGetVATRegNoOutput('GB376 4736 37', 'GB', '376473637');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCustomerVATRegNoWhenBlankCountryCode()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        CountryCode: Code[10];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 375310] New VAT Registration No. must be logged when Customer has blank Country/Region code
        Initialize();

        // [GIVEN] Country "DE" with "EU Country/Region Code" = "DE"
        CountryCode := CreateCountryCodeWithEUCode();

        // [GIVEN] "Company Information"."Country/Region Code" = "DE"
        UpdateCountryRegionInCompanyInformation(CountryCode);

        // [GIVEN] Customer with blank "Country/Region Code"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] "VAT Registration Log" with 1 entry
        InitializeVATRegistrationLog(VATRegistrationLog, VATRegistrationLog."Account Type"::Customer, Customer."No.");
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryCode));
        VerifyVATRegNoAndCountryCodeInLog(VATRegistrationLog, Customer."VAT Registration No.", CountryCode, 1);

        // [WHEN] Validate Customer."VAT Registration No." with new valid value "DE123456789"
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryCode));

        // [THEN] New "VAT Registration Log" entry added
        // [THEN] "VAT Registration Log"."Country/Region Code" = "DE"
        // [THEN] "VAT Registration Log"."VAT Registration No." = "DE123456789"
        VerifyVATRegNoAndCountryCodeInLog(VATRegistrationLog, Customer."VAT Registration No.", CountryCode, 2);

        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVendorVATRegNoWhenBlankCountryCode()
    var
        Vendor: Record Vendor;
        VATRegistrationLog: Record "VAT Registration Log";
        CountryCode: Code[10];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 375310] New VAT Registration No. must be logged when Vendor has blank Country/Region code
        Initialize();

        // [GIVEN] Country "DE" with "EU Country/Region Code" = "DE"
        CountryCode := CreateCountryCodeWithEUCode();

        // [GIVEN] "Company Information"."Country/Region Code" = "DE"
        UpdateCountryRegionInCompanyInformation(CountryCode);

        // [GIVEN] Vendor with blank "Country/Region Code"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] "VAT Registration Log" with 1 entry
        InitializeVATRegistrationLog(VATRegistrationLog, VATRegistrationLog."Account Type"::Vendor, Vendor."No.");
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryCode));
        VerifyVATRegNoAndCountryCodeInLog(VATRegistrationLog, Vendor."VAT Registration No.", CountryCode, 1);

        // [WHEN] Validate Vendor."VAT Registration No." with new valid value "DE123456789"
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryCode));

        // [THEN] New "VAT Registration Log" entry added
        // [THEN] "VAT Registration Log"."Country/Region Code" = "DE"
        // [THEN] "VAT Registration Log"."VAT Registration No." = "DE123456789"
        VerifyVATRegNoAndCountryCodeInLog(VATRegistrationLog, Vendor."VAT Registration No.", CountryCode, 2);

        // Tear Down
        Vendor.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateContactVATRegNoWhenBlankCountryCode()
    var
        Contact: Record Contact;
        VATRegistrationLog: Record "VAT Registration Log";
        CountryCode: Code[10];
    begin
        // [FEATURE] [UT] [Contact]
        // [SCENARIO 375310] New VAT Registration No. must be logged when Contact has blank Country/Region code
        Initialize();

        // [GIVEN] Country "DE" with "EU Country/Region Code" = "DE"
        CountryCode := CreateCountryCodeWithEUCode();

        // [GIVEN] "Company Information"."Country/Region Code" = "DE"
        UpdateCountryRegionInCompanyInformation(CountryCode);

        // [GIVEN] Contact with blank "Country/Region Code"
        Contact.Init();
        Contact.Validate("No.", LibraryUtility.GenerateGUID());
        Contact.Insert();

        // [GIVEN] "VAT Registration Log" with 1 entry.
        InitializeVATRegistrationLog(VATRegistrationLog, VATRegistrationLog."Account Type"::Contact, Contact."No.");
        Contact.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryCode));
        VerifyVATRegNoAndCountryCodeInLog(VATRegistrationLog, Contact."VAT Registration No.", CountryCode, 1);

        // [WHEN] Validate Contact."VAT Registration No." with new valid value "DE123456789"
        Contact.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryCode));

        // [THEN] New "VAT Registration Log" entry added
        // [THEN] "VAT Registration Log"."Country/Region Code" = "DE"
        // [THEN] "VAT Registration Log"."VAT Registration No." = "DE123456789"
        VerifyVATRegNoAndCountryCodeInLog(VATRegistrationLog, Contact."VAT Registration No.", CountryCode, 2);

        // Tear Down
        Contact.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCustomerVATRegNoWhenAllBlankCountryCode()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        CountryCode: Code[10];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 375310] New VAT Registration No. must not be logged when Customer and Company have blank Country/Region codes
        Initialize();

        // [GIVEN] Country "DE" with "EU Country/Region Code" = "DE"
        CountryCode := CreateCountryCodeWithEUCode();

        // [GIVEN] "Company Information"."Country/Region Code" = "" (blank)
        UpdateCountryRegionInCompanyInformation('');

        // [GIVEN] Customer with blank "Country/Region Code"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] "VAT Registration Log" without entries
        InitializeVATRegistrationLog(VATRegistrationLog, VATRegistrationLog."Account Type"::Customer, Customer."No.");

        // [WHEN] Validate Customer."VAT Registration No." with new valid value "DE123456789"
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryCode));

        // [THEN] "VAT Registration Log".COUNT = 0 (entry wasn't added)
        Assert.RecordIsEmpty(VATRegistrationLog);

        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCustomerVATRegNoWhenNonEUCountryCode()
    var
        Customer: Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 375310] New VAT Registration No. must not be logged when Customer's Country/Region has blank EU code
        Initialize();

        // [GIVEN] Country "DE" with "EU Country/Region Code" = "" (blank)
        LibraryERM.CreateCountryRegion(CountryRegion);

        // [GIVEN] Customer with"Country/Region Code" = "DE"
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();

        // [GIVEN] "VAT Registration Log" without entries
        InitializeVATRegistrationLog(VATRegistrationLog, VATRegistrationLog."Account Type"::Customer, Customer."No.");

        // [WHEN] Validate Customer."VAT Registration No." with new valid value "DE123456789"
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code));

        // [THEN] "VAT Registration Log".COUNT = 0 (entry wasn't added)
        Assert.RecordIsEmpty(VATRegistrationLog);

        // Tear Down
        Customer.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVendorVATRegNoWhenNonEUCountryCode()
    var
        Vendor: Record Vendor;
        VATRegistrationLog: Record "VAT Registration Log";
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 375310] New VAT Registration No. must not be logged when Vendor's Country/Region has blank EU code
        Initialize();

        // [GIVEN] Country "DE" with "EU Country/Region Code" = "" (blank)
        LibraryERM.CreateCountryRegion(CountryRegion);

        // [GIVEN] Vendor with "Country/Region Code" = "DE"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := CountryRegion.Code;
        Vendor.Modify();

        // [GIVEN] "VAT Registration Log" without entries
        InitializeVATRegistrationLog(VATRegistrationLog, VATRegistrationLog."Account Type"::Vendor, Vendor."No.");

        // [WHEN] Validate Vendor."VAT Registration No." with new valid value "DE123456789"
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code));

        // [THEN] "VAT Registration Log".COUNT = 0 (entry wasn't added)
        Assert.RecordIsEmpty(VATRegistrationLog);

        // Tear Down
        Vendor.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateContactVATRegNoWhenNonEUCountryCode()
    var
        Contact: Record Contact;
        VATRegistrationLog: Record "VAT Registration Log";
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [UT] [Contact]
        // [SCENARIO 375310] New VAT Registration No. must not be logged when Contact's Country/Region has blank EU code
        Initialize();

        // [GIVEN] Country "DE" with "EU Country/Region Code" = "" (blank)
        LibraryERM.CreateCountryRegion(CountryRegion);

        // [GIVEN] Contact with "Country/Region Code" = "DE"
        Contact.Init();
        Contact.Validate("No.", LibraryUtility.GenerateGUID());
        Contact."Country/Region Code" := CountryRegion.Code;
        Contact.Insert();

        // [GIVEN] "VAT Registration Log" with 1 entry.
        InitializeVATRegistrationLog(VATRegistrationLog, VATRegistrationLog."Account Type"::Contact, Contact."No.");

        // [WHEN] Validate Contact."VAT Registration No." with new valid value "DE123456789"
        Contact.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code));

        // [THEN] "VAT Registration Log".COUNT = 0 (entry wasn't added)
        Assert.RecordIsEmpty(VATRegistrationLog);

        // Tear Down
        Contact.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCountryCodeIfCodeDiffersFromEUCode()
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382504] "EU Country/Region Code" should be used for VAT Registration No. validation if it is set

        Initialize();

        // [GIVEN] Country/Region having "Code" = "CCC" and "EU Country/Region Code" = "EUC"
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate(
          "EU Country/Region Code",
          LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo("EU Country/Region Code"), DATABASE::"Country/Region"));
        CountryRegion.Modify(true);

        // [GIVEN] VAT Registration Log line having "CCC" "Country/Region Code"
        VATRegistrationLog.Init();
        VATRegistrationLog."Country/Region Code" := CountryRegion.Code;

        // [WHEN] Call GetCountryCode procedure for VAT Registration Log line
        // [THEN] Procedure returns code "EUC"
        Assert.AreEqual(CountryRegion."EU Country/Region Code", VATRegistrationLog.GetCountryCode(), GetCountryCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCountryCodeIfCountryRegionCodeIsEmptyAndCompInfoExists()
    var
        CompanyInformation: Record "Company Information";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382504] If "Country/Region Code" of VAT Registration Log is blank, then GetCountryCode procedure should return "Country/Region Code" from Company Information

        Initialize();

        // [GIVEN] VAT Registration Log line having blank "Country/Region Code"
        VATRegistrationLog.Init();
        VATRegistrationLog."Country/Region Code" := '';

        // [WHEN] Call GetCountryCode procedure for VAT Registration Log line
        // [THEN] Procedure returns "Country/Region Code" from Company Information
        CompanyInformation.Get();
        Assert.AreEqual(CompanyInformation."Country/Region Code", VATRegistrationLog.GetCountryCode(), GetCountryCodeErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCountryCodeIfCountryRegionCodeIsEmptyAndCompInfoDoesNotExist()
    var
        DummyCompanyInformation: Record "Company Information";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382504] If "Country/Region Code" of VAT Registration Log is blank and there is no Company information, then GetCountryCode procedure should return blank code

        Initialize();

        // [GIVEN] VAT Registration Log line having blank "Country/Region Code"
        VATRegistrationLog.Init();
        VATRegistrationLog."Country/Region Code" := '';

        // [WHEN] Call GetCountryCode procedure for VAT Registration Log line
        // [THEN] Procedure returns "Country/Region Code" from Company Information
        DummyCompanyInformation.Get();
        DummyCompanyInformation.Delete();
        Assert.AreEqual('', VATRegistrationLog.GetCountryCode(), GetCountryCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetNotExistingCountryCode()
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382504] If VAT Registration Log line has not existing Country/Region Code then "Country/Region does not exist" error appears

        Initialize();

        // [GIVEN] VAT Registration Log line having "CCC" "Country/Region Code" which does not refer to any existing Country/Region
        VATRegistrationLog.Init();
        VATRegistrationLog."Country/Region Code" :=
          LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), DATABASE::"Country/Region");

        // [WHEN] Call GetCountryCode procedure for VAT Registration Log line
        asserterror VATRegistrationLog.GetCountryCode();

        // [THEN] "Country/Region does not exist" error appears
        Assert.ExpectedErrorCannotFind(Database::"Country/Region");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCountryCodeIfEUCodeIsBlank()
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382504] If "EU Country/Region Code" is blank, then Country/Region Code should be used for VAT Registration No. validation

        Initialize();

        // [GIVEN] Country/Region having "Code" = "CCC" and blank "EU Country/Region Code"
        LibraryERM.CreateCountryRegion(CountryRegion);

        // [GIVEN] VAT Registration Log line having "CCC" "Country/Region Code"
        VATRegistrationLog.Init();
        VATRegistrationLog."Country/Region Code" := CountryRegion.Code;

        // [WHEN] Call GetCountryCode procedure for VAT Registration Log line
        // [THEN] Procedure returns code "CCC"
        Assert.AreEqual(CountryRegion.Code, VATRegistrationLog.GetCountryCode(), GetCountryCodeErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UI_VIESSettingInsertEmtryIfSettingEmpty()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        VATLookupExtDataHndl: Codeunit "VAT Lookup Ext. Data Hndl";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        VATRegistrationConfig: TestPage "VAT Registration Config";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 254093] System insert entry into empty "VAT Reg. No. Srv Config" table when Cassie opens "VAT Registration Config" page
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        VATRegNoSrvConfig.DeleteAll();

        VATRegistrationConfig.OpenEdit();

        VATRegNoSrvConfig.FindFirst();
        VATRegNoSrvConfig.TestField("Service Endpoint", VATLookupExtDataHndl.GetVATRegNrValidationWebServiceURL());
        VATRegNoSrvConfig.TestField(Enabled, false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UI_VIESSettingSetDefaultService()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        VATLookupExtDataHndl: Codeunit "VAT Lookup Ext. Data Hndl";
        VATRegistrationConfig: TestPage "VAT Registration Config";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 254093] System fills "Service Endpoint" with 'http://ec.europa.eu/taxation_customs/vies/services/checkVatService' url
        // [SCENARIO 254093] when Cassie calls "Set to Default" action
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        VATRegNoSrvConfig.DeleteAll();

        VATRegistrationConfig.OpenEdit();

        VATRegistrationConfig.ServiceEndpoint.SetValue('');
        VATRegistrationConfig.SettoDefault.Invoke();

        VATRegistrationConfig.ServiceEndpoint.AssertEquals(VATLookupExtDataHndl.GetVATRegNrValidationWebServiceURL());
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_VIESSettingCannotEnableWithBlankUrl()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        VATRegistrationConfig: TestPage "VAT Registration Config";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 254093] System throw error 'Validation error field: Enabled' when Cassie tries to enable setting with blank "Service Endpoint"
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        VATRegNoSrvConfig.DeleteAll();

        VATRegistrationConfig.OpenEdit();

        VATRegistrationConfig.ServiceEndpoint.SetValue('');
        asserterror VATRegistrationConfig.Enabled.SetValue(true);

        Assert.ExpectedError('Validation error for Field: Enabled');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('StoreMessageMessageHandler,CustomerConsentConfirmationPageChooseYesModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UI_VIESSettingDisclaimerMessageOnEnable()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        VATRegistrationConfig: TestPage "VAT Registration Config";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 254093] System shows disclaimer message when Cassie enabled setting
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        VATRegNoSrvConfig.DeleteAll();

        VATRegistrationConfig.OpenEdit();

        VATRegistrationConfig.Enabled.SetValue(true);

        Assert.ExpectedMessage(DisclaimerTxt, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_VATRegNoSrvIsEnabledReturnsFalseOnEmptyTable()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254093] TAB248.VATRegNoSrvIsEnabled return FALSE for empty table
        VATRegNoSrvConfig.DeleteAll();

        Assert.IsFalse(VATRegNoSrvConfig.VATRegNoSrvIsEnabled(), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_VATRegNoSrvIsEnabledReturnsFalseWhenSettingIsNotEnabled()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254093] TAB248.VATRegNoSrvIsEnabled returns FALSE when "Enabled" = FALSE
        VATRegNoSrvConfig.DeleteAll();
        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig.Insert();

        Assert.IsFalse(VATRegNoSrvConfig.VATRegNoSrvIsEnabled(), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_VATRegNoSrvIsEnabledReturnsTrueWhenSettingIsEnabled()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254093] TAB248.VATRegNoSrvIsEnabled returns TRUE when "Enabled" = TRUE
        VATRegNoSrvConfig.DeleteAll();
        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig.Enabled := true;
        VATRegNoSrvConfig.Insert();

        Assert.IsTrue(VATRegNoSrvConfig.VATRegNoSrvIsEnabled(), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_VATRegNoSrvConfigCanHaveOnlySingleLine()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254093] TAB248.INSERT(TRUE) throws error on attemption to insert second entry
        VATRegNoSrvConfig.DeleteAll();
        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig.Insert();
        VATRegNoSrvConfig."Entry No." += 1;

        asserterror VATRegNoSrvConfig.Insert(true);
        Assert.ExpectedError(CannotInsertMultipleSettingsErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_GetVATRegNoURLThrowErrorIfTableIsEmpty()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254093] TAB248.GetVATRegNoURL throws error 'VAT Reg. No. Validation Setup is not enabled.' when table is empty
        VATRegNoSrvConfig.DeleteAll();

        asserterror VATRegNoSrvConfig.GetVATRegNoURL();
        Assert.ExpectedError(VATRegNoVIESSettingIsNotEnabledErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_GetVATRegNoURLThrowErrorIfSettingIsNotEnabled()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254093] TAB248.GetVATRegNoURL throws error 'VAT Reg. No. Validation Setup is not enabled.' when "Enabled" = FALSE
        VATRegNoSrvConfig.DeleteAll();
        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig.Insert();

        asserterror VATRegNoSrvConfig.GetVATRegNoURL();
        Assert.ExpectedError(VATRegNoVIESSettingIsNotEnabledErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_GetVATRegNoURLThrowErrorSettingIsEnabledAndUrlIsBlank()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254093] TAB248.GetVATRegNoURL throws error 'Service Endpoint must have a value in VAT Reg. No. Srv Config: Entry No.=0.'
        // [SCENARIO 254093] when "Enabled" = TRUE (somehow) and "Service Endpoint" = <blank>
        VATRegNoSrvConfig.DeleteAll();
        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig.Enabled := true;
        VATRegNoSrvConfig.Insert();

        asserterror VATRegNoSrvConfig.GetVATRegNoURL();
        Assert.ExpectedTestFieldError(VATRegNoSrvConfig.FieldCaption("Service Endpoint"), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_GetVATRegNoURLReturnsUrlIsSettingIsEnabled()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        ServiceUrl: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254093] TAB248.GetVATRegNoURL returns 'A' when "Enabled" = TRUE (somehow) and "Service Endpoint" = 'A'
        ServiceUrl := LibraryUtility.GenerateGUID();

        VATRegNoSrvConfig.DeleteAll();
        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig.Enabled := true;
        VATRegNoSrvConfig."Service Endpoint" := ServiceUrl;
        VATRegNoSrvConfig.Insert();

        Assert.AreEqual(ServiceUrl, VATRegNoSrvConfig.GetVATRegNoURL(), '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_COD248_Run_ThrowErrorWhatVATRegNoSerbDisabled()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 254093] COD248.RUN throws error 'VAT Reg. No. Validation Setup is not enabled.'
        VATRegistrationLog.DeleteAll();
        VATRegNoSrvConfig.DeleteAll();

        asserterror CODEUNIT.Run(CODEUNIT::"VAT Lookup Ext. Data Hndl");
        Assert.ExpectedError(VATRegNoVIESSettingIsNotEnabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowErrorWhenCountryCodeIsNotSet()
    var
        CustomerCard: TestPage "Customer Card";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        // [SCENARIO] 
        // An error is thrown when a user try to validate a VAT number
        // and no country/region code is specified

        // [WHEN] the VAT validation service is enabled
        VATRegNoSrvConfig.DeleteAll();
        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig.Enabled := true;
        VATRegNoSrvConfig.Insert();

        VATRegistrationNoFormat.DeleteAll();

        // [GIVEN] 
        // a customer with no country/region code 
        CustomerCard.OpenEdit();
        CustomerCard."Country/Region Code".SetValue('');
        // [THEN] 
        // an error is expected when the user try to validate the VAT number
        asserterror CustomerCard."VAT Registration No.".Drilldown();
        Assert.ExpectedError(EmptyCountryCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowErrorWhenEUCountryCodeIsNotSet()
    var
        CustomerCard: TestPage "Customer Card";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO] 
        // An error is thrown when a user try to validate a VAT number
        // and no EU country/region code is specified

        // [WHEN] the VAT validation service is enabled
        VATRegNoSrvConfig.DeleteAll();
        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig.Enabled := true;
        VATRegNoSrvConfig.Insert();

        // insert test country code
        CountryRegion.Code := 'TEST';
        CountryRegion.Insert();

        // [GIVEN] 
        // a customer with no country/region code 
        CustomerCard.OpenEdit();
        CustomerCard."Country/Region Code".SetValue('TE');
        // [THEN] 
        // an error is expected when the user try to validate the VAT number
        asserterror CustomerCard."VAT Registration No.".Drilldown();
        Assert.ExpectedError(EmptyEUCountryCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowErrorWhenVATRegNoIsNotSet()
    var
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        // [SCENARIO] 
        // When there is no VAT to validate an error is thrown
        VATRegistrationLog.DeleteAll();

        VATRegNoSrvConfig.DeleteAll();
        VATRegNoSrvConfig.Init();
        VATRegNoSrvConfig.Enabled := true;
        VATRegNoSrvConfig."Service Endpoint" := LibraryUtility.GenerateGUID();
        VATRegNoSrvConfig.Insert();

        asserterror CODEUNIT.Run(CODEUNIT::"VAT Lookup Ext. Data Hndl");
        Assert.ExpectedError(NoVATNoToValidateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateHeaderVATRegistrationNoRespectsSellToCustomerSetting()
    var
        Customer: array[2] of Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        VATRegistrationNo: array[2] of Text[20];
    begin
        // [FEATURE] [UT] [Customer] [Sales] [Header]
        // [SCENARIO 375310] Header VAT Registration No. validation uses Sell-to Customer No when GL Setup has Sell-to customer option enabled
        Initialize();

        // [GIVEN] Bill-to/Sell-to VAT Calc. is Sell-to in General Ledger Setup
        SetGLSetupBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Customer "C1" with VAT Registration No. "AAA"
        CreateCustomerWithVATRegNoWithValidFormat(Customer[1], VATRegistrationNo[1]);

        // [GIVEN] Customer "C2" with VAT Registration No. "BBB"
        CreateCustomerWithVATRegNoWithValidFormat(Customer[2], VATRegistrationNo[2]);

        // [GIVEN] Customer "C1" has Bill-to Customer No. = "C2".No
        UpdateBillToCustomerNoOnCustomer(Customer[1], Customer[2]."No.");

        // [GIVEN] Sales invoice is created for Customer "C1"
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer[1]."No.");

        // [WHEN] New VAT Registration No "CCC" is validated in Sales invoice
        SalesHeader.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Customer[1]."Country/Region Code"));

        // [THEN] Customer "C1" has old VAT Registration No. "AAA"
        // Work item 525644: "VAT Registration No." only updates in the customer card if it is blank there
        Customer[1].Find();
        Customer[1].TestField("VAT Registration No.", VATRegistrationNo[1]);

        // [THEN] Customer "C2" has old VAT Registration No. "BBB"
        Customer[2].Find();
        Customer[2].TestField("VAT Registration No.", VATRegistrationNo[2]);

        // Tear Down
        Customer[1].Delete();
        Customer[2].Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateHeaderVATRegistrationNoRespectsBillToCustomerSetting()
    var
        Customer: array[2] of Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        VATRegistrationNo: array[2] of Text[20];
    begin
        // [FEATURE] [UT] [Customer] [Sales] [Header]
        // [SCENARIO 375310] Header VAT Registration No. validation uses Bill-to Customer No when GL Setup has Bill-to customer option enabled
        Initialize();

        // [GIVEN] Bill-to/Sell-to VAT Calc. is Bill-to/Pay-to No. in General Ledger Setup
        SetGLSetupBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] Customer "C1" with VAT Registration No. "AAA"
        CreateCustomerWithVATRegNoWithValidFormat(Customer[1], VATRegistrationNo[1]);

        // [GIVEN] Customer "C2" with VAT Registration No. "BBB"
        CreateCustomerWithVATRegNoWithValidFormat(Customer[2], VATRegistrationNo[2]);

        // [GIVEN] Customer "C1" has Bill-to Customer No. = "C2".No
        UpdateBillToCustomerNoOnCustomer(Customer[1], Customer[2]."No.");

        // [GIVEN] Sales invoice is created for Customer "C1"
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer[1]."No.");

        // [WHEN] New VAT Registration No "CCC" is validated in Sales invoice
        SalesHeader.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Customer[2]."Country/Region Code"));

        // [THEN] Customer "C1" has old VAT Registration No. "AAA"
        Customer[1].Find();
        Customer[1].TestField("VAT Registration No.", VATRegistrationNo[1]);

        // [THEN] Customer "C2" has old VAT Registration No. "BBB"
        // Work item 525644: "VAT Registration No." only updates in the customer card if it is blank there
        Customer[2].Find();
        Customer[2].TestField("VAT Registration No.", VATRegistrationNo[2]);

        // Tear Down
        Customer[1].Delete();
        Customer[2].Delete();
    end;

    [Test]
    [HandlerFunctions('VATRegLogHandler')]
    [Scope('OnPrem')]
    procedure TestLaunchingVatRegistrationLogSelectLastValidatedVATRegistrationNo()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 330051] When you click assist edit on "VAT Registration No." field on Customer Card page VAT Registration Log page is launched, and last validated "VAT Registration No." line is selected.
        Initialize();

        // [GIVEN] Customer with VAT Registration No. = "A".
        CreateCustomer(Customer);

        // [GIVEN] On Customer Card Customer's VAT Registration No. is set to "B".
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard."VAT Registration No.".SetValue(LibraryRandom.RandIntInRange(10000000, 99999999));

        // [WHEN] VAT Registration Log page is opened from Customer Card's field "VAT Registration No." Assist Edit.
        LibraryVariableStorage.Enqueue(CustomerCard."VAT Registration No.".Value);
        CustomerCard."VAT Registration No.".DrillDown();

        // [THEN] On opened page selected line has VAT Registration No. = "B".
    end;

    [Test]
    procedure VATCountryRegionCodeIsUsedForVATRegNoValidationInSalesHeader()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        SalesHeader: Record "Sales Header";
        VATRegistrationNo: Text[20];
    begin
        // [SCENARIO 525644] "VAT Country/Region Code" of the sales header is used for the "VAT Registration No." validation

        Initialize();
        // [GIVEN] Customer with Country/Region Code = "DK" and VAT Registration = "DK123456789"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        // [GIVEN] VAT Registration No. Format with Country/Region Code = "DK" and Format = "DK#########""
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, Customer."Country/Region Code");
        VATRegistrationNoFormat.Validate(Format, Customer."Country/Region Code" + '#########');
        VATRegistrationNoFormat.Modify();
        // [GIVEN] VAT Registration No. Format with Country/Region Code = "ES" and Format = "ES#########""
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegion.Code);
        VATRegistrationNoFormat.Validate(Format, CountryRegion.Code + '#########');
        VATRegistrationNoFormat.Modify();

        // [GIVEN] Sales invoice is created for Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] "VAT Country/Region Code" = "ES"
        SalesHeader.Validate("VAT Country/Region Code", CountryRegion.Code);

        VATRegistrationNo := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);

        // [WHEN] Set "VAT Registration No." to "ES123456789"
        SalesHeader.Validate("VAT Registration No.", VATRegistrationNo);

        // [THEN] "VAT Registration No." has passed the validation
        SalesHeader.TestField("VAT Registration No.", VATRegistrationNo);
    end;

    [Test]
    procedure VATRegistrationNoIsSavedInCustomerFromSalesHeaderIfItIsBlank()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        VATRegistrationNo: Text[20];
    begin
        // [SCENARIO 525644] "VAT Registration No." is saved in the customer card from the sales header if it is blank

        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", LibraryERM.CreateCountryRegion());
        Customer.Modify(true);
        // [GIVEN] Sales invoice is created for Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        VATRegistrationNo := LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code");
        // [WHEN] Set "VAT Registration No." to "X"
        SalesHeader.Validate("VAT Registration No.", VATRegistrationNo);
        SalesHeader.Modify(true);
        // [THEN] "VAT Registration No." is "X" for the customer
        Customer.Find();
        Customer.TestField("VAT Registration No.", VATRegistrationNo);
    end;

    [Test]
    procedure VATRegistrationNoIsNotSavedInCustomerFromSalesHeaderIfItIsNotBlank()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerVATRegistrationNo: Text[20];
        VATRegistrationNo: Text[20];
    begin
        // [SCENARIO 525644] "VAT Registration No." is not saved in the customer card from the sales header if it is not blank

        Initialize();
        // [GIVEN] Customer with Country/Region Code = "DK" and VAT Registration = "X"
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        CustomerVATRegistrationNo := Customer."VAT Registration No.";
        // [GIVEN] Sales invoice is created for Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        VATRegistrationNo := LibraryERM.GenerateVATRegistrationNo('');
        // [WHEN] Set "VAT Registration No." to "Y"
        SalesHeader.Validate("VAT Registration No.", VATRegistrationNo);
        SalesHeader.Modify(true);
        // [THEN] "VAT Registration No." is "X" for the customer
        Customer.Find();
        Customer.TestField("VAT Registration No.", CustomerVATRegistrationNo);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT Reg. No Validity Check");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryApplicationArea.EnableVATSetup();
        SetVATRegSrvStatus(false, '');

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT Reg. No Validity Check");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibraryTemplates.EnableTemplatesFeature();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT Reg. No Validity Check");
    end;

    local procedure InitializeVATRegistrationLog(var VATRegistrationLog: Record "VAT Registration Log"; AccountType: Enum "VAT Registration Log Account Type"; AccountNo: Code[20])
    begin
        VATRegistrationLog.SetRange("Account Type", AccountType);
        VATRegistrationLog.SetRange("Account No.", AccountNo);
        Assert.RecordIsEmpty(VATRegistrationLog);
    end;

    local procedure CreateInvalidVATCheckResponse(var XMLDoc: DotNet XmlDocument)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        VATNode: DotNet XmlNode;
        InvalidNode: DotNet XmlNode;
    begin
        XMLDoc := XMLDoc.XmlDocument();
        XMLDOMMgt.AddRootElementWithPrefix(XMLDoc, VATTxt, '', NamespaceTxt, VATNode);
        XMLDOMMgt.AddElement(VATNode, ValidTxt, 'false', NamespaceTxt, InvalidNode);
    end;

    local procedure CreateValidVATCheckResponse(var XMLDoc: DotNet XmlDocument; ValidatedName: Text; ValidatedAddress: Text)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        VATNode: DotNet XmlNode;
        InvalidNode: DotNet XmlNode;
    begin
        XMLDoc := XMLDoc.XmlDocument();
        XMLDOMMgt.AddRootElementWithPrefix(XMLDoc, VATTxt, '', NamespaceTxt, VATNode);
        XMLDOMMgt.AddElement(VATNode, ValidTxt, 'true', NamespaceTxt, InvalidNode);
        XMLDOMMgt.AddElement(VATNode, NameTxt, ValidatedName, NamespaceTxt, InvalidNode);
        XMLDOMMgt.AddElement(VATNode, AddressTxt, ValidatedAddress, NamespaceTxt, InvalidNode);
    end;

    local procedure CreateVATCheckResponseWithManyTags(var XMLDoc: DotNet XmlDocument; ValidatedName: Text; ValidatedAddress: Text)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        VATNode: DotNet XmlNode;
        InvalidNode: DotNet XmlNode;
        I: Integer;
    begin
        XMLDoc := XMLDoc.XmlDocument();
        XMLDOMMgt.AddRootElementWithPrefix(XMLDoc, VATTxt, '', NamespaceTxt, VATNode);
        for I := 1 to 500 do begin
            XMLDOMMgt.AddElement(VATNode, ValidTxt, 'true', NamespaceTxt, InvalidNode);
            XMLDOMMgt.AddElement(VATNode, NameTxt, ValidatedName, NamespaceTxt, InvalidNode);
            XMLDOMMgt.AddElement(VATNode, AddressTxt, ValidatedAddress, NamespaceTxt, InvalidNode);
        end;
    end;

    local procedure CreateCountryCodeWithEUCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."EU Country/Region Code" := CountryRegion.Code;
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure CreateContact(var Contact: Record Contact)
    begin
        Contact.Init();
        Contact.Validate("No.", LibraryUtility.GenerateGUID());
        Contact.Type := Contact.Type::Company;
        Contact."Company No." := Contact."No.";
        Contact.Validate("Country/Region Code", 'DK');
        Contact.Validate("VAT Registration No.", Format(LibraryRandom.RandIntInRange(10000000, 99999999)));
        Contact.Insert();
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", 'DK');
        Customer.Validate("VAT Registration No.", Format(LibraryRandom.RandIntInRange(10000000, 99999999)));
        Customer.Modify();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", 'DK');
        Vendor.Validate("VAT Registration No.", Format(LibraryRandom.RandIntInRange(10000000, 99999999)));
        Vendor.Modify();
    end;

    local procedure CreateCustomerWithVATRegNoWithValidFormat(var Customer: Record Customer; var VATRegistrationNo: Text[20])
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegion.Code);
        VATRegistrationNoFormat.Validate(Format, '123######');
        VATRegistrationNoFormat.Modify();
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        VATRegistrationNo := Customer."VAT Registration No.";
        Customer.Modify(true);
    end;

    local procedure CreateCustomerFromContact(var Customer: Record Customer; Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        Contact.CreateCustomerFromTemplate('');
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.FindFirst();
        Customer.Get(ContactBusinessRelation."No.");
    end;

    local procedure CreateVendorFromContact(var Vendor: Record Vendor; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        Contact.CreateVendorFromTemplate('');
        Contact.Find(); // to refresh "Business Relation"
        ContactBusinessRelation.SetRange("Contact No.", Contact."No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.FindFirst();
        Vendor.Get(ContactBusinessRelation."No.");
    end;

    local procedure ModifyCustomerVATRegNo(var Customer: Record Customer)
    begin
        Customer.Validate("VAT Registration No.", Format(LibraryRandom.RandIntInRange(10000000, 99999999)));
        Customer.Modify();
    end;

    local procedure ModifyVendorVATRegNo(var Vendor: Record Vendor)
    begin
        Vendor.Validate("VAT Registration No.", Format(LibraryRandom.RandIntInRange(10000000, 99999999)));
        Vendor.Modify();
    end;

    local procedure OpenCustomerVATRegLog(Customer: Record Customer)
    var
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard."VAT Registration No.".DrillDown();
        CustomerCard.Close();
    end;

    local procedure OpenVendorVATRegLog(Vendor: Record Vendor)
    var
        VendorCard: TestPage "Vendor Card";
    begin
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard."VAT Registration No.".DrillDown();
        VendorCard.Close();
    end;

    local procedure OpenContactVATRegLog(Contact: Record Contact)
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenEdit();
        ContactCard.GotoRecord(Contact);
        ContactCard."VAT Registration No.".DrillDown();
        ContactCard.Close();
    end;

    local procedure UpdateCountryRegionInCompanyInformation(CountryRegionCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := CountryRegionCode;
        CompanyInformation.Modify();
    end;

    local procedure UpdateBillToCustomerNoOnCustomer(var Customer: Record Customer; BillToCustomerNo: Code[20])
    begin
        Customer.Validate("Bill-to Customer No.", BillToCustomerNo);
        Customer.Modify(true);
    end;

    local procedure VerifyGetVATRegNoOutput(InputVATRegNo: Text[20]; InputCountryCode: Code[10]; ExpectedOutput: Code[20])
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        VATRegistrationLog.Init();
        VATRegistrationLog."VAT Registration No." := InputVATRegNo;
        VATRegistrationLog."Country/Region Code" := InputCountryCode;
        VATRegistrationLog.Insert();
        Assert.AreEqual(ExpectedOutput, VATRegistrationLog.GetVATRegNo(), GetVATRegNoErr);
    end;

    local procedure VerifyVATRegLogEntry(VATRegistrationLog: Record "VAT Registration Log"; AccountType: Enum "VAT Registration Log Account Type"; AccountNo: Code[20]; VATRegistrationNo: Text[20]; ExpectedStatus: Option)
    begin
        VATRegistrationLog.TestField("Account Type", AccountType);
        VATRegistrationLog.TestField("Account No.", AccountNo);
        VATRegistrationLog.TestField("VAT Registration No.", VATRegistrationNo);
        VATRegistrationLog.TestField(Status, ExpectedStatus);
        VATRegistrationLog.TestField("User ID", UserId);
    end;

    local procedure VerifyVATRegNoAndCountryCodeInLog(var VATRegistrationLog: Record "VAT Registration Log"; VATRegNo: Text[20]; CountryCode: Code[10]; ExpectedCount: Integer)
    begin
        VATRegistrationLog.FindLast();
        VATRegistrationLog.TestField("VAT Registration No.", VATRegNo);
        VATRegistrationLog.TestField("Country/Region Code", CountryCode);
        Assert.AreEqual(ExpectedCount, VATRegistrationLog.Count, WrongLogEntryCountErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATRegistrationLogHandler(var VATRegistrationLog: TestPage "VAT Registration Log")
    var
        VATRegistrationNo1: Variant;
        VATRegistrationNo2: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATRegistrationNo1);
        LibraryVariableStorage.Dequeue(VATRegistrationNo2);
        VATRegistrationLog.First();
        Assert.AreEqual(VATRegistrationNo2, VATRegistrationLog."VAT Registration No.".Value, WrongLogEntryOnPageErr);
        VATRegistrationLog.Next();
        Assert.AreEqual(VATRegistrationNo1, VATRegistrationLog."VAT Registration No.".Value, WrongLogEntryOnPageErr);
        VATRegistrationLog.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATRegLogHandler(var VATRegistrationLog: TestPage "VAT Registration Log")
    begin
        VATRegistrationLog."VAT Registration No.".AssertEquals(LibraryVariableStorage.DequeueText());
        VATRegistrationLog.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    local procedure SetVATRegSrvStatus(Status: Boolean; EndpointURL: Text[250])
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        if not VATRegNoSrvConfig.FindFirst() then begin
            VATRegNoSrvConfig.Init();
            VATRegNoSrvConfig.Insert();
        end;
        VATRegNoSrvConfig.Enabled := Status;
        VATRegNoSrvConfig."Service Endpoint" := EndpointURL;
        VATRegNoSrvConfig.Modify(true);
    end;

    local procedure SetGLSetupBillToSellToVATCalc(NewBillToSellToVATCalc: Enum "G/L Setup VAT Calculation")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", NewBillToSellToVATCalc);
        GeneralLedgerSetup.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StoreMessageMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerConsentConfirmationPageChooseYesModalPageHandler(var CustConsentConfPage: TestPage "Cust. Consent Confirmation")
    begin
        CustConsentConfPage.Accept.Invoke();
    end;
}

