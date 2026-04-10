codeunit 134047 "ERM VAT Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Registration No.]
    end;

    var
        VATPostingSetup2: Record "VAT Posting Setup";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        FormatError: Label 'The entered VAT Registration number is not in agreement with the format specified for Country/Region Code %1.\The following formats are acceptable: %2';
        VATFormatError: Label 'VAT Registration No. must be %1 for %2: %3.';
        ErrorMustAppear: Label 'Error message must appear after wrong VAT Registration No. updation.';
        CountryRegionError: Label '%1 must be exist.';
        MultiCustomerMsg: Label 'This VAT registration number has already been entered for the following customers:\ %1';
        MultiVendorMsg: Label 'This VAT registration number has already been entered for the following vendors:\ %1';
        MultiContactMsg: Label 'This VAT registration number has already been entered for the following contacts:\ %1';
        VATPostingSetupHasVATEntriesErr: Label 'You cannot change the VAT posting setup because it has been used to generate VAT entries. Changing the setup now can cause inconsistencies in your financial data.';
        LibraryUtility: Codeunit "Library - Utility";
        VendorNo: Code[20];
        CustomerNo: Code[20];
        ContactNo: Code[20];
        IsInitialized: Boolean;
        UnexpectedMsg: Label 'Unexpected message dialog: %1';
        ExpectedMessage: Label 'The VAT Registration number is not valid.The first character (T Element) of the number is invalid.Do you still want to save it?';
        ExpectedMessage2: Label 'The VAT Registration number is not valid.The length of the number exceeds the maximum limit of 9 characters.Do you still want to save it?';
        Selection: Option "All fields","Selected fields";
        VATetc: Boolean;
        SalesAccounts: Boolean;
        PurchaseAccounts: Boolean;
        VATError: Label '%1 must be %2 in %3.';
        FormatError2: Label 'The entered VAT Registration number for %1 %2 is not in agreement with the format specified for Country/Region Code %3.\The following formats are acceptable: %4', Comment = '%1 - Record Type, %2 - Record No., %3 - Country Region Code, %4 - VAT Format';

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvalidVATFormatOnCompany()
    var
        CompanyInformation: Record "Company Information";
        CountryRegionCode: Code[10];
        VATFormat: Text[20];
    begin
        // Check Error Message after entering wrong VAT Registration No. on Company.

        // Setup: Create new Country/Region. Create VAT Registration No. Format. Change Country/Region in Company Information.
        Initialize();
        VATFormat := CreateCountryVATRegistration(CountryRegionCode);
        ModifyCompanyInformation(CompanyInformation, CountryRegionCode);

        // Exercise: Put an Invalid VAT Registration No in Company Information.
        asserterror CompanyInformation.Validate("VAT Registration No.", 'TestInvalid.' + Format(100 + LibraryRandom.RandInt(899)));

        // Verify: Verify the Error Message appeared while changing VAT Registration No.
        Assert.AreEqual(StrSubstNo(FormatError, CountryRegionCode, VATFormat), GetLastErrorText, ErrorMustAppear);
    end;

    [Test]
    [HandlerFunctions('LengthConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidVATFormatOnCompany()
    var
        CompanyInformation: Record "Company Information";
        CountryRegionCode: Code[10];
        CountryRegionCodeOld: Code[10];
        VATRegistrationNo: Text[20];
    begin
        // Check VAT Registration No. after entering valid VAT Registration No. on Company.

        // Setup: Create new Country/Region. Create VAT Registration No. Format. Change Country/Region in Company Information.
        Initialize();
        CreateCountryVATRegistration(CountryRegionCode);
        CountryRegionCodeOld := ModifyCompanyInformation(CompanyInformation, CountryRegionCode);
        VATRegistrationNo := 'TEST.' + Format(100 + LibraryRandom.RandInt(899));  // Create Valid Random VAT Registration No.

        // Exercise: Enter valid VAT Registration No in Company Information.
        CompanyInformation.Validate("VAT Registration No.", VATRegistrationNo);
        CompanyInformation.Modify(true);

        // Verify: Check that Correct VAT Registration No. updated in Company Information.
        Assert.AreEqual(
          VATRegistrationNo, CompanyInformation."VAT Registration No.", StrSubstNo(VATFormatError, VATRegistrationNo,
            CompanyInformation.TableCaption(), CompanyInformation.Name));

        // Tear Down: Rollback Company Information, Delete Country created during Setup.
        ModifyCompanyInformation(CompanyInformation, CountryRegionCodeOld);
        DeleteCountryRegion(CountryRegionCode);
    end;

    [Test]
    [HandlerFunctions('LengthConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvalidVATFormatOnCustomer()
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        CountryRegionCode: Code[10];
        VATFormat: Text[20];
    begin
        // Verify Error after providing wrong VAT Registration No. for an existing Customer without Country Code.

        // Setup: Create new Country/Region. Create VAT Registration No. Format. Change Country/Region in Company Information.
        // Find a Customer and update its Country/Region Code.
        Initialize();
        VATFormat := CreateCountryVATRegistration(CountryRegionCode);
        ModifyCompanyInformation(CompanyInformation, CountryRegionCode);
        LibrarySales.CreateCustomer(Customer);

        // Exercise: Enter an invalid VAT Registration No for Customer. Taking Random value greater than 999 to produce
        // invalide values for VAT Registration No.
        asserterror Customer.Validate("VAT Registration No.", 'TestInvalid.' + Format(999 + LibraryRandom.RandInt(10)));

        // Verify: Verify the Error Message appeared while changing VAT Registration No.
        Assert.AreEqual(StrSubstNo(FormatError2, Customer.TableCaption, Customer."No.", CountryRegionCode, VATFormat), GetLastErrorText, ErrorMustAppear);
    end;

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidVATFormatOnCustomer()
    var
        Customer: Record Customer;
        CountryRegionCode: Code[10];
        VATRegistrationNo: Text[20];
    begin
        // Verify Valid VAT Registration No. for a new customer, enter Country Code different from the Company's.

        // Setup: Create new Country/Region. Create VAT Registration No. Format and update Company Information. Create a new Country
        // and multiple VAT Registration No. Formats for it. Create Customer and update the later created Country Code on it.
        // Take Random Values to create a Valid VAT Registration Code for Customer.
        Initialize();
        CreateCountryWithMultipleVAT(CountryRegionCode);
        CreateAndUpdateCountryCustomer(Customer, CountryRegionCode);
        VATRegistrationNo := 'TEST1.' + Format(100 + LibraryRandom.RandInt(899)) + '.1';

        // Exercise: Enter a valid VAT Registration No for Customer according to second VAT Registration No. Format.
        Customer.Validate("VAT Registration No.", VATRegistrationNo);
        Customer.Modify(true);

        // Verify: Verify that Correct VAT Registration No. updated on Customer.
        Assert.AreEqual(
          VATRegistrationNo, Customer."VAT Registration No.", StrSubstNo(VATFormatError, VATRegistrationNo, Customer.TableCaption(),
            Customer."No."));

        // Tear Down: Rollback Company Information, Delete Customer and Countries created.
        Customer.Delete(true);
        DeleteCountryRegion(CountryRegionCode);
    end;

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidVATFormatOnVendor()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        CountryRegionCode: Code[10];
        VATRegistrationNo: Text[20];
    begin
        // Verify VAT Registration No. for an existing Vendor, enter Country Code different from the Company's.

        // Setup: Create new Country/Region. Create VAT Registration No. Format and update Company Information. Create a new Country
        // and multiple VAT Registration No. Formats for it. Find a Vendor and update the later created Country Code on it.
        // Take Random Values to create a Valid VAT Registration Code for Vendor.
        Initialize();
        CreateCountryWithMultipleVAT(CountryRegionCode);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor2.Get(Vendor."No.");
        UpdateCountryOnVendor(Vendor, CountryRegionCode);
        VATRegistrationNo := 'TEST1.' + Format(100 + LibraryRandom.RandInt(899)) + '.1';

        // Exercise: Enter a valid VAT Registration No in Vendor Card according to second VAT Registration No. Format.
        UpdateVendorVATRegistration(Vendor, VATRegistrationNo);

        // Verify: Verify that Correct VAT Registration No. updated on vendor.
        Assert.AreEqual(
          VATRegistrationNo, Vendor."VAT Registration No.", StrSubstNo(VATFormatError, VATRegistrationNo, Vendor.TableCaption(), Vendor."No."));

        // Tear Down: Rollback Vendor VAT Registration, Company Information and Delete Countries created.
        UpdateVendorVATRegistration(Vendor, Vendor2."VAT Registration No.");
        UpdateCountryOnVendor(Vendor, Vendor2."Country/Region Code");
        DeleteCountryRegion(CountryRegionCode);
    end;

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvalidVATFormatOnVendor()
    var
        CompanyInformation: Record "Company Information";
        Vendor: Record Vendor;
        CountryRegionCode: Code[10];
        VATFormat: Text[20];
    begin
        // Verify Error Message for a new Vendor without Country Code after entering wrong VAT Registration No.

        // Setup: Create new Country/Region, VAT Registration No. Format. Modify Company Information and Create Vendor.
        Initialize();
        VATFormat := CreateCountryVATRegistration(CountryRegionCode);
        ModifyCompanyInformation(CompanyInformation, CountryRegionCode);
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise: Put an Invalid VAT Registration No. for Vendor. Take Random Value for VAT Registration No.
        asserterror Vendor.Validate("VAT Registration No.", 'TestInvalid.' + Format(100 + LibraryRandom.RandInt(899)) + '.1');

        // Verify: Verify the Error Message appeared while changing VAT Registration No.
        Assert.AreEqual(StrSubstNo(FormatError2, Vendor.TableCaption, Vendor."No.", CountryRegionCode, VATFormat), GetLastErrorText, ErrorMustAppear);
    end;

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure ValidVATFormatOnContact()
    var
        CompanyInformation: Record "Company Information";
        Contact: Record Contact;
        CountryRegionCode: Code[10];
        CountryRegionCodeOld: Code[10];
        VATRegistrationNo: Text[20];
    begin
        // Verify VAT Registration No. for a new contact without Country Code and with Valid VAT Format.

        // Setup: Create new Country/Region, VAT Registration No. Format. Modify Company Information and Create Contact.
        // Take Random Values to create a valid VAT Registration No.
        Initialize();
        CreateCountryVATRegistration(CountryRegionCode);
        CountryRegionCodeOld := ModifyCompanyInformation(CompanyInformation, CountryRegionCode);
        LibraryMarketing.CreateCompanyContact(Contact);
        VATRegistrationNo := 'TEST.' + Format(100 + LibraryRandom.RandInt(899));

        // Exercise: Put a valid VAT Registration No. in Contact Card.
        Contact.Validate("VAT Registration No.", VATRegistrationNo);
        Contact.Modify(true);

        // Verify: Verify that correct VAT Registration No. updated on Contact.
        Assert.AreEqual(
          VATRegistrationNo, Contact."VAT Registration No.", StrSubstNo(VATFormatError, VATRegistrationNo, Contact.TableCaption(),
            Contact."No."));

        // Tear Down: Rollback Company Information, Delete Contact, Country Code.
        Contact.Delete(true);
        ModifyCompanyInformation(CompanyInformation, CountryRegionCodeOld);
        DeleteCountryRegion(CountryRegionCode);
    end;

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvalidVATFormatOnContact()
    var
        Contact: Record Contact;
        CountryRegionCode: Code[10];
        VATFormat: Text[20];
    begin
        // Verify Error Message for a Contact after entering wrong VAT Registration No.

        // Setup: Create new Country/Region, VAT Registration No. Format. Find a Contact and Update Country Code on it.
        Initialize();
        VATFormat := CreateCountryVATRegistration(CountryRegionCode);
        LibraryMarketing.FindContact(Contact);
        UpdateCountryOnContact(Contact, CountryRegionCode);

        // Exercise: Put an invalid VAT Registration No. in Contact Card. Use Random Values to create it.
        asserterror Contact.Validate("VAT Registration No.", 'TestInvalid' + Format(LibraryRandom.RandInt(100)));

        // Verify: Verify the Error Message appeared while changing VAT Registration No.
        Assert.AreEqual(StrSubstNo(FormatError2, Contact.TableCaption, Contact."No.", CountryRegionCode, VATFormat), GetLastErrorText, ErrorMustAppear);
    end;

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure CountryRegionDeletion()
    var
        CountryRegion: Record "Country/Region";
        CountryRegionCode: Code[10];
    begin
        // Check Error Message after entering wrong VAT Registration No. on Company.

        // Setup: Create new Country/Region and VAT Registration No. Format.
        Initialize();
        CreateCountryVATRegistration(CountryRegionCode);

        // Exercise: Delete Created Country Region.
        DeleteCountryRegion(CountryRegionCode);

        // Verify: Verify that Counrtry Region is no more after deletion.
        Assert.IsFalse(CountryRegion.Get(CountryRegionCode), StrSubstNo(CountryRegionError, CountryRegion.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('MessageHandlerVendor,InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure DuplicateVATOnVendor()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        CountryRegionCode: Code[10];
        VATRegistrationNo: Text[20];
    begin
        // Verify Message for VAT Registration No. after entering same VAT Registration No. on two Vendors.

        // Setup: Create Country, VAT Registration. Create Vendor with the newly created Country and VAT Registration.
        Initialize();
        VATRegistrationNo := 'TEST.' + Format(100 + LibraryRandom.RandInt(899));
        CreateCountryVATRegistration(CountryRegionCode);
        CreateVendorWithCountryVAT(Vendor, CountryRegionCode, VATRegistrationNo);
        VendorNo := Vendor."No.";  // Store Vendor No. to use it in Verification.

        // Exercise: Create another Vendor and update the same Country and VAT Registration No. as used on first Vendor.
        CreateVendorWithCountryVAT(Vendor2, CountryRegionCode, VATRegistrationNo);

        // Verify: Verify the message appeared.
        // -------------------------------------------------------------------------------
        // Verification done in Message Handler for Vendor: MessageHandlerVendor.
        // -------------------------------------------------------------------------------

        // Tear Down: Delete Country and Vendors created.
        DeleteCountryRegion(CountryRegionCode);
        Vendor.Delete(true);
        Vendor2.Delete(true);
    end;

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure DuplicateVATOnVendorCustomer()
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        CountryRegionCode: Code[10];
        VATRegistrationNo: Text[20];
    begin
        // Verify VAT Registration No. on Customer after entering same VAT Registration No. on a Vendor and on a Customer.

        // Setup: Create Country, VAT Registration Format. Update the same on Vendor.
        Initialize();
        VATRegistrationNo := 'TEST.' + Format(100 + LibraryRandom.RandInt(899));
        CreateCountryVATRegistration(CountryRegionCode);
        CreateVendorWithCountryVAT(Vendor, CountryRegionCode, VATRegistrationNo);

        // Exercise: Update VAT Registration No. and Country on Customer as used on Vendor.
        CreateCustomerWithCountryVAT(Customer, CountryRegionCode, VATRegistrationNo);

        // Verify: Verify that Correct VAT Registration No. updated on Customer and no warning appears.
        Assert.AreEqual(
          Vendor."VAT Registration No.", Customer."VAT Registration No.", StrSubstNo(VATFormatError, VATRegistrationNo,
            Customer.TableCaption(), Customer."No."));

        // Tear Down: Delete Country, Customer and Vendor created.
        DeleteCountryRegion(CountryRegionCode);
        Customer.Delete(true);
        Vendor.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerCustomer,InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure DuplicateVATOnCustomer()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        CountryRegionCode: Code[10];
        VATRegistrationNo: Text[20];
    begin
        // Verify Message for VAT Registration No. after entering the same VAT Registration No. on two Customers.

        // Setup: Create Country, VAT Registration format, Create Customer and attach the Country and VAT Registration No.
        Initialize();
        VATRegistrationNo := 'TEST.' + Format(100 + LibraryRandom.RandInt(899));
        CreateCountryVATRegistration(CountryRegionCode);
        CreateCustomerWithCountryVAT(Customer, CountryRegionCode, VATRegistrationNo);
        CustomerNo := Customer."No.";

        // Exercise: Create another Customer and attach same Country and VAT Registration No.
        CreateCustomerWithCountryVAT(Customer2, CountryRegionCode, VATRegistrationNo);

        // Verify: Verify the message appeared.
        // --------------------------------------------------------------------------------
        // Verification done in Message Handler for Customer: MessageHandlerCustomer
        // --------------------------------------------------------------------------------

        // Tear Down: Delete Country and Customers created.
        DeleteCountryRegion(CountryRegionCode);
        Customer.Delete(true);
        Customer2.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerCustomer,InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure DuplicateVATOnMultipleCustomer()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        Customer3: Record Customer;
        CountryRegionCode: Code[10];
        VATRegistrationNo: Text[20];
    begin
        // Verify Message for VAT Registration No. after entering the same VAT Registration No. on more than two Customers.

        // Setup: Create Country and VAT Registration Format. Create Customers with same VAT Registration No.
        Initialize();
        VATRegistrationNo := 'TEST.' + Format(100 + LibraryRandom.RandInt(899));
        CreateCountryVATRegistration(CountryRegionCode);
        CreateCustomerWithCountryVAT(Customer, CountryRegionCode, VATRegistrationNo);
        CustomerNo := Customer."No.";
        CreateCustomerWithCountryVAT(Customer2, CountryRegionCode, VATRegistrationNo);

        // Exercise: Update Country and VAT Registration on another new Customer
        CreateCustomerWithCountryVAT(Customer3, CountryRegionCode, VATRegistrationNo);

        // Verify: Verify the message appeared.
        // --------------------------------------------------------------------------------
        // Verification done in Message Handler for Customer: MessageHandlerCustomer.
        // --------------------------------------------------------------------------------

        // Tear Down: Delete Country, Customers created.
        DeleteCountryRegion(CountryRegionCode);
        Customer.Delete(true);
        Customer2.Delete(true);
        Customer3.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerContact,InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure DuplicateVATOnContact()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Contact2: Record Contact;
        CountryRegionCode: Code[10];
        VATRegistrationNo: Text[20];
    begin
        // Verify Message for VAT Registration No. after entering the same VAT Registration No. on Vendor, Customer and Contacts.

        // Setup: Create Country with VAT Registration, Vendor, Customer, Contact and update Country and VAT Registration No.
        Initialize();
        VATRegistrationNo := 'TEST.' + Format(100 + LibraryRandom.RandInt(899));
        CreateCountryVATRegistration(CountryRegionCode);
        CreateVendorWithCountryVAT(Vendor, CountryRegionCode, VATRegistrationNo);
        CreateCustomerWithCountryVAT(Customer, CountryRegionCode, VATRegistrationNo);
        CreateContactWithCountryVAT(Contact, CountryRegionCode, VATRegistrationNo);
        ContactNo := Contact."No.";

        // Exercise: Create a new Contact and update same Country and VAT Registration No. on Contact.
        CreateContactWithCountryVAT(Contact2, CountryRegionCode, VATRegistrationNo);

        // Verify: Verify the message appeared.
        // ---------------------------------------------------------------------------
        // Verification done in Message Handler for Contact: MessageHandlerContact.
        // ---------------------------------------------------------------------------

        // Tear Down: Delete Country, Customer, Vendor and Contacts created.
        DeleteCountryRegion(CountryRegionCode);
        Customer.Delete(true);
        Vendor.Delete(true);
        Contact.Delete(true);
        Contact2.Delete(true);
    end;

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATFormatForBlankCountryCode()
    var
        CountriesRegions: TestPage "Countries/Regions";
    begin
        // Check VAT Reg. No. Format Action is not enable when try to create new VAT Reg. No. Format for a blank Country/Region Code.

        // Setup.
        Initialize();

        // Exercise: Open Country/Regions page with blank Country code.
        CountriesRegions.OpenNew();

        // Verify.
        Assert.IsFalse(
          CountriesRegions."VAT Reg. No. Formats".Enabled(), 'VAT Registration No. Formats button must not be enabled.');
    end;

    [Test]
    [HandlerFunctions('InvalidCharConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteCountryRegionVATFormat()
    var
        VATRegistrationNoFormats: TestPage "VAT Registration No. Formats";
        CountryRegionCode: Code[10];
        VATFormat: Text[20];
    begin
        // Check VAT Reg. No. Format is deleted after deleting Country/Region Code.

        // Setup: Create new Country/Region and Create VAT Registration No. Format for it.
        Initialize();
        VATFormat := CreateCountryVATRegistration(CountryRegionCode);

        // Exercise: Delete Country/Region Code.
        DeleteCountryRegion(CountryRegionCode);

        // Verify: Verify VAT Format does not exist on VAT Registration No. Formats page.
        VATRegistrationNoFormats.OpenView();
        VATRegistrationNoFormats.FILTER.SetFilter("Country/Region Code", CountryRegionCode);
        asserterror VATRegistrationNoFormats.Format.AssertEquals(VATFormat);
    end;

    [Test]
    [HandlerFunctions('CopyFieldHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyVATSetupAllFields()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Copy VAT Posting Setup with all fields and Verify.

        // Setup: Create VAT Posting Setup.
        Initialize();
        Selection := Selection::"All fields";
        VATetc := true;
        SalesAccounts := true;
        PurchaseAccounts := true;
        CreateVATPostingSetup(VATPostingSetup);

        // Exercise: Copy VAT Posting Setup with all fields.
        FindVATPostingSetup();
        Commit();
        CopyVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");  // Use CopyAllFieldHandler here.

        // Verify: Check VAT Posting Setup with copied Setup.
        VerifyVATPostingSetup(VATPostingSetup);
    end;

    [Test]
    [HandlerFunctions('CopyFieldHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyVATSetupSelectedFields()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Copy VAT Posting Setup with selected fields and Verify.

        // Setup: Create VAT Posting Setup.
        Initialize();
        Selection := Selection::"Selected fields";
        VATetc := true;
        SalesAccounts := true;
        PurchaseAccounts := false;
        CreateVATPostingSetup(VATPostingSetup);

        // Exercise: Copy VAT Posting Setup with selected fields.
        FindVATPostingSetup();
        Commit();
        CopyVATPostingSetup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");    // Use CopySelectedFieldHandler here.

        // Verify: Check VAT Posting Setup with copied Setup.
        VerifyVATPostingSetup(VATPostingSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATRegistrationAfterUpdatingBalanceAccount()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Check that VAT Registration No. updated on General Journal Line after updating Balance Account No. with a Customer having VAT Registration No.

        // Setup: Find a Customer, Create General Journal Line for GL Account.
        Initialize();
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          GLAccount."No.");

        // Exercise: Update Balance Account As Customer in General Journal Line.
        UpdateBalanceAccountInGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::Customer, Customer."No.");

        // Verify: Verify that VAT Registration No. updated on General Journal Line after updating Balance Account No.
        VerifyVATRegistrationOnGeneralJournalLine(GenJournalLine, Customer."VAT Registration No.");

        // Tear Down: Clear General Journal Line.
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BlankVATRegistrationAfterUpdatingBalanceAccount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        // Check that VAT Registration No. field is blank on General Journal Line after updating Balance Account with GL Account.

        // Setup: Create General Journal Line for GL Account.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          GLAccount."No.");

        // Exercise: Update Balance Account as GL Account in General Journal Line.
        GLAccount.Next();
        UpdateBalanceAccountInGeneralJournalLine(GenJournalLine, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.");

        // Verify: Verify that VAT Registration No. is blank on General Journal Line after updating Balance Account No.
        VerifyVATRegistrationOnGeneralJournalLine(GenJournalLine, '');

        // Tear Down: Clear General Journal Line.
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VATRegistrationForCustomerOnJournalLine()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check VAT Registration No. on General Journal Line with a Customer having VAT Registration No.

        // Setup.
        Initialize();
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);

        // Exercise: Create General Journal Line for Customer.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, Customer."No.");

        // Verify: Verify that VAT Registration No. field updated on General Journal Line.
        VerifyVATRegistrationOnGeneralJournalLine(GenJournalLine, Customer."VAT Registration No.");

        // Tear Down: Clear the General Journal Line.
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    [Test]
    [HandlerFunctions('CopyVatPostingSetupRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckValueOnVATPostingSetup()
    var
        VATPostingSetupWithAccounts: Record "VAT Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        // Verify that Program Copy New Accounts in Vat Posting Setup Card through Copy Functionality.

        // Setup: Find And Create VAT Posting Setup.
        Initialize();
        FindVATPostingSetupWithAccounts(VATPostingSetupWithAccounts);
        CreateVATPostingSetup(VATPostingSetup);
        LibraryVariableStorage.Enqueue(VATPostingSetupWithAccounts."VAT Bus. Posting Group");
        LibraryVariableStorage.Enqueue(VATPostingSetupWithAccounts."VAT Prod. Posting Group");

        // Exercise: Copy VAT Posting Setup.
        CopyVATPostingSetupCard(VATPostingSetupCard, VATPostingSetup);

        // Verify: Check VAT Posting Setup with copied Setup On Page.
        VerifyVATPostingSetupWithAccounts(VATPostingSetupCard, VATPostingSetupWithAccounts);
    end;

    [Test]
    [HandlerFunctions('CopyGenPostingSetupRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckValueOnGenPostingSetup()
    var
        GenPostingSetupWithAccounts: Record "General Posting Setup";
        GenPostingSetup: Record "General Posting Setup";
        GenPostingSetupCard: TestPage "General Posting Setup Card";
    begin
        // Verify that program copy new values in General Posting Setup card through copy functionality.

        // Setup: Find And Create VAT Posting Setup.
        Initialize();
        FindGenPostingSetupWithAccounts(GenPostingSetupWithAccounts);
        CreateGenPostingSetup(GenPostingSetup);
        LibraryVariableStorage.Enqueue(GenPostingSetupWithAccounts."Gen. Bus. Posting Group");
        LibraryVariableStorage.Enqueue(GenPostingSetupWithAccounts."Gen. Prod. Posting Group");

        // Exercise: Copy General Posting Setup.
        CopyGenPostingSetupCard(GenPostingSetupCard, GenPostingSetup);

        // Verify: Check General Posting Setup with copied Setup On Page.
        VerifyGenPostingSetupWithAccounts(GenPostingSetupCard, GenPostingSetupWithAccounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeTestFormatAgainstSeveralTemplatesWithLongList()
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        FormatTemplate: Text[20];
        VATRegNo: Text[20];
        Length: Integer;
    begin
        // [SCENARIO 253058] There is a check error with format template list (with dots '...' at the end) when enter VAT Registration No. in case of
        // [SCENARIO 253058] several format templates with total length > 250 chars and the typed value is not in agreement with any template
        FormatTemplate := PadStr('', MaxStrLen(VATRegistrationNoFormat.Format), '#');
        VATRegNo := PadStr('', StrLen(FormatTemplate) - 1, '0');

        // [GIVEN] Several vat registration no. format templates ["A1", ... "AK", ... "AN"] with total length > 250 chars for country\region "X"
        LibraryERM.CreateCountryRegion(CountryRegion);
        while Length < 1000 do
            Length += StrLen(CreateVATRegistrationNoFormat(CountryRegion.Code, FormatTemplate));

        // [WHEN] Enter a new vat registration no. which should not pass the check
        asserterror VATRegistrationNoFormat.Test(VATRegNo, CountryRegion.Code, '', 0);

        // [THEN] An error is shown:
        // [THEN] "The entered VAT Registration number is not in agreement with the format specified for Country/Region Code X"
        // [THEN] "The following formats are acceptable: A1, ... AK..."
        Assert.ExpectedErrorCode('Dialog');
        VerifyMessageWithLast3DotChars(StrSubstNo(FormatError, CountryRegion.Code, FormatTemplate), GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestAlreadyEnteredFormatWithLongCustomerList()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
        Length: Integer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 253058] There is a message with a customer list (with dots '...' at the end) typing the same VAT Registration No. in case of
        // [SCENARIO 253058] several customers with the same VAT Registration No. with total Customer."No." length > 250 chars
        VATRegNo := PadStr('', MaxStrLen(VATRegistrationNoFormat.Format), '0');

        // [GIVEN] Several customers ["C1", ... "CK", ... "CN"] with the same vat registration no. with total "No." length > 250 chars
        LibraryERM.CreateCountryRegion(CountryRegion);
        while Length < 1000 do
            Length += StrLen(CreateCustomerWithCountryVATSilent(Customer, CountryRegion.Code, VATRegNo));

        // [WHEN] Enter the same vat registration no. for a new customer
        CreateCustomerWithCountryVAT(Customer, CountryRegion.Code, VATRegNo);

        // [THEN] A message is shown:
        // [THEN] "This VAT registration number has already been entered for the following customers:"
        // [THEN] "C1, ... CK..."
        VerifyMessageWithLast3DotChars(StrSubstNo(MultiCustomerMsg, ''), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestAlreadyEnteredFormatWithLongVendorList()
    var
        CountryRegion: Record "Country/Region";
        Vendor: Record Vendor;
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
        Length: Integer;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 253058] There is a message with a vendor list (with dots '...' at the end) typing the same VAT Registration No. in case of
        // [SCENARIO 253058] several vendors with the same VAT Registration No. with total Vendor."No." length > 250 chars
        VATRegNo := PadStr('', MaxStrLen(VATRegistrationNoFormat.Format), '0');

        // [GIVEN] Several vendors ["V1", ... "VK", ... "VN"] with the same vat registration no. with total "No." length > 250 chars
        LibraryERM.CreateCountryRegion(CountryRegion);
        while Length < 1000 do
            Length += StrLen(CreateVendorWithCountryVATSilent(Vendor, CountryRegion.Code, VATRegNo));

        // [WHEN] Enter the same vat registration no. for a new vendor
        CreateVendorWithCountryVAT(Vendor, CountryRegion.Code, VATRegNo);

        // [THEN] A message is shown:
        // [THEN] "This VAT registration number has already been entered for the following vendors:"
        // [THEN] "V1, ... VK..."
        VerifyMessageWithLast3DotChars(StrSubstNo(MultiVendorMsg, ''), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestAlreadyEnteredFormatWithLongContactList()
    var
        CountryRegion: Record "Country/Region";
        Contact: Record Contact;
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNo: Text[20];
        Length: Integer;
    begin
        // [FEATURE] [Contact]
        // [SCENARIO 253058] There is a message with a contact list (with dots '...' at the end) typing the same VAT Registration No. in case of
        // [SCENARIO 253058] several contacts with the same VAT Registration No. with total Contact."No." length > 250 chars
        VATRegNo := PadStr('', MaxStrLen(VATRegistrationNoFormat.Format), '0');

        // [GIVEN] Several contacts ["C1", ... "CK", ... "CN"] with the same vat registration no. with total "No." length > 250 chars
        LibraryERM.CreateCountryRegion(CountryRegion);
        while Length < 1000 do
            Length += StrLen(CreateContactWithCountryVATSilent(Contact, CountryRegion.Code, VATRegNo));

        // [WHEN] Enter the same vat registration no. for a new contact
        CreateContactWithCountryVAT(Contact, CountryRegion.Code, VATRegNo);

        // [THEN] A message is shown:
        // [THEN] "This VAT registration number has already been entered for the following contacts:"
        // [THEN] "C1, ... CK..."
        VerifyMessageWithLast3DotChars(StrSubstNo(MultiContactMsg, ''), LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VATRegistrationLogHandlerSimple')]
    [Scope('OnPrem')]
    procedure AssistEditCustomerVATRegPopulatesLogIfCustomersVATIsNotThere()
    var
        Customer: array[2] of Record Customer;
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
    begin
        // [FEATURE] [Customer] [VAT Registration Log]
        // [SCENARIO 294327] Running AssistEditCustomerVATReg will fill Log entries for existing customers if current Customer's entry is not there

        // [GIVEN] A Customer[1] with VAT Registration No. and VAT Registration Log entry for this Customer
        CreateCustomer(Customer[1]);

        // [GIVEN] A Customer[2] with VAT Registration No. and VAT Registration Log entry for this Customer
        CreateCustomer(Customer[2]);

        // [GIVEN] There is no entry in VAT Registration Log table for Customer[2]
        VATRegistrationLogMgt.DeleteCustomerLog(Customer[2]);

        // [WHEN] Run VATRegistrationLogMgt.AssistEditCustomerVATReg for this Customer
        VATRegistrationLogMgt.AssistEditCustomerVATReg(Customer[2]);
        // UI Handled by VATRegistrationLogHandlerSimple

        // [THEN] There is entry in VAT Registration Log table for this Customer
        VerifyVATRegistrationLogEntryExists(VATRegistrationLog."Account Type"::Customer, Customer[2]."No.");

        // Cleanup
        VATRegistrationLogMgt.DeleteCustomerLog(Customer[1]);
        VATRegistrationLogMgt.DeleteCustomerLog(Customer[2]);
        Customer[1].Delete();
        Customer[2].Delete();
    end;

    [Test]
    [HandlerFunctions('VATRegistrationLogHandlerSimple')]
    [Scope('OnPrem')]
    procedure AssistEditVendorVATRegPopulatesLogIfVendorsVATIsNotThere()
    var
        Vendor: array[2] of Record Vendor;
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
    begin
        // [FEATURE] [Vendor] [VAT Registration Log]
        // [SCENARIO 294327] Running AssistEditVendorVATReg will fill Log entries for existing Vendors if current Vendor's entry is not there

        // [GIVEN] A Vendor[1] with VAT Registration No. and VAT Registration Log entry for this Vendor
        CreateVendor(Vendor[1]);

        // [GIVEN] A Vendor[2] with VAT Registration No. and VAT Registration Log entry for this Vendor
        CreateVendor(Vendor[2]);

        // [GIVEN] There is no entry in VAT Registration Log table for Vendor[2]
        VATRegistrationLogMgt.DeleteVendorLog(Vendor[2]);

        // [WHEN] Run VATRegistrationLogMgt.AssistEditVendorVATReg for this Vendor
        VATRegistrationLogMgt.AssistEditVendorVATReg(Vendor[2]);
        // UI Handled by VATRegistrationLogHandlerSimple

        // [THEN] There is entry in VAT Registration Log table for this Vendor
        VerifyVATRegistrationLogEntryExists(VATRegistrationLog."Account Type"::Vendor, Vendor[2]."No.");

        // Cleanup
        VATRegistrationLogMgt.DeleteVendorLog(Vendor[1]);
        VATRegistrationLogMgt.DeleteVendorLog(Vendor[2]);
        Vendor[1].Delete();
        Vendor[2].Delete();
    end;

    [Test]
    [HandlerFunctions('VATRegistrationLogHandlerSimple')]
    [Scope('OnPrem')]
    procedure AssistEditContactVATRegPopulatesLogIfContactsVATIsNotThere()
    var
        Contact: array[2] of Record Contact;
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
    begin
        // [FEATURE] [Contact] [VAT Registration Log]
        // [SCENARIO 294327] Running AssistEditContactVATReg will fill Log entries for existing Contacts if current Contact's entry is not there

        // [GIVEN] A Contact[1] with VAT Registration No. and VAT Registration Log entry for this Contact
        CreateContact(Contact[1]);

        // [GIVEN] A Contact[2] with VAT Registration No. and VAT Registration Log entry for this Contact
        CreateContact(Contact[2]);

        // [GIVEN] There is no entry in VAT Registration Log table for Contact[2]
        VATRegistrationLogMgt.DeleteContactLog(Contact[2]);

        // [WHEN] Run VATRegistrationLogMgt.AssistEditContactVATReg for this Contact
        VATRegistrationLogMgt.AssistEditContactVATReg(Contact[2]);
        // UI Handled by VATRegistrationLogHandlerSimple

        // [THEN] There is entry in VAT Registration Log table for this Contact
        VerifyVATRegistrationLogEntryExists(VATRegistrationLog."Account Type"::Contact, Contact[2]."No.");

        // Cleanup
        VATRegistrationLogMgt.DeleteContactLog(Contact[1]);
        VATRegistrationLogMgt.DeleteContactLog(Contact[2]);
        Contact[1].Delete();
        Contact[2].Delete();
    end;

    [Test]
    procedure TestVATPostingSetupChangeVATCalcTypeError()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        VatPostingSetupTestPage: TestPage "VAT Posting Setup";
    begin

        // [GIVEN] A posting setup exists
        // [GIVEN] A sales invoice have been created
        // [GIVEM] The sales invoice is posted

        // Setup.
        LibrarySetupStorage.Restore();
        LibraryRandom.SetSeed(1);  // Generate Random Seed using Random Number Generator.

        // Lazy Setup.
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");


        CreateSalesDocWithPartQtyToShip(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [WHEN] Posting setup page is opened and VAT group is selected
        VatPostingSetupTestPage.OpenEdit();
        VatPostingSetupTestPage.Filter.SetFilter("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VatPostingSetupTestPage.Filter.SetFilter("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [THEN] Fail to modify VAT Calculation Type as VAT entries have been created when posting invoice
        asserterror VatPostingSetupTestPage."VAT Calculation Type".SetValue(Enum::"Tax Calculation Type"::"Reverse Charge VAT");
        Assert.ExpectedError(StrSubstNo(VATPostingSetupHasVATEntriesErr, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateSalesDocWithPartQtyToShip(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; NoOfLine: Integer; DocumentType: Enum "Sales Document Type") TotalAmount: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Counter: Integer;
    begin
        // Take Random Quantity and Unit Price.
        CreateSalesHeader(SalesHeader, VATPostingSetup, DocumentType);
        for Counter := 1 to NoOfLine do begin  // Create Multiple Sales Line.
            CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
            SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);
            SalesLine.Modify(true);
            TotalAmount += SalesLine."Qty. to Ship" * SalesLine."Unit Price";
        end;
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; var VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandInt(10) * 2); // need to have even Quantity
        SalesLine.Validate("Unit Price", (1 + VATPostingSetup."VAT %" / 100) * LibraryRandom.RandIntInRange(100, 200)); // need to prevent rounding issues
        SalesLine.Modify();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        ExecuteUIHandler();
        LibraryVariableStorage.Clear();

        // Clear global variable.
        Selection := Selection::"All fields";
        VATetc := false;
        SalesAccounts := false;
        PurchaseAccounts := false;

        SetVatVlidationSrvStatus(false);

        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
    end;

    [Scope('OnPrem')]
    procedure SetVatVlidationSrvStatus(Status: Boolean)
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        if not VATRegNoSrvConfig.FindFirst() then begin
            VATRegNoSrvConfig.Init();
            VATRegNoSrvConfig.Insert();
        end;
        VATRegNoSrvConfig.Enabled := Status;
        VATRegNoSrvConfig.Modify(true);
    end;

    local procedure CopyVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATPostingSetupPage: TestPage "VAT Posting Setup";
    begin
        VATPostingSetupPage.OpenEdit();
        VATPostingSetupPage.FILTER.SetFilter("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetupPage.FILTER.SetFilter("VAT Prod. Posting Group", VATProdPostingGroup);
        VATPostingSetupPage.Copy.Invoke();
    end;

    local procedure CreateAndUpdateCountryCustomer(var Customer: Record Customer; CountryRegionCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Modify(true);
    end;

    local procedure CreateContactWithCountryVAT(var Contact: Record Contact; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20])
    begin
        Clear(Contact);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", CountryRegionCode);
        Contact.Validate("VAT Registration No.", VATRegistrationNo);
        Contact.Modify(true);
    end;

    local procedure CreateContactWithCountryVATSilent(var Contact: Record Contact; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]): Code[20]
    begin
        Clear(Contact);
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", CountryRegionCode);
        Contact."VAT Registration No." := VATRegistrationNo;
        Contact.Modify(true);
        exit(Contact."No.");
    end;

    local procedure CreateCountryVATRegistration(var CountryRegionCode: Code[10]) VATFormat: Text[20]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegionCode := CountryRegion.Code;
        VATFormat := CreateVATRegistrationNoFormat(CountryRegionCode, 'TEST.###');
    end;

    local procedure CreateCountryWithMultipleVAT(var CountryRegionCode: Code[10])
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        CreateCountryVATRegistration(CountryRegionCode);
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegionCode);
        VATRegistrationNoFormat.Validate(Format, 'TEST1.###.1');  // Taking Hard Coded Value because of Format Restriction.
        VATRegistrationNoFormat.Modify(true);
    end;

    local procedure CreateCustomerWithCountryVAT(var Customer: Record Customer; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20])
    begin
        CreateAndUpdateCountryCustomer(Customer, CountryRegionCode);
        Customer.Validate("VAT Registration No.", VATRegistrationNo);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithCountryVATSilent(var Customer: Record Customer; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]): Code[20]
    begin
        CreateAndUpdateCountryCustomer(Customer, CountryRegionCode);
        Customer."VAT Registration No." := VATRegistrationNo;
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        // Use Random Amount for General Journal Line.
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo,
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateVATRegistrationNoFormat(CountryRegionCode: Code[10]; Format: Text[20]): Text[20]
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegionCode);
        VATRegistrationNoFormat.Validate(Format, Format);
        VATRegistrationNoFormat.Modify(true);
        exit(VATRegistrationNoFormat.Format);
    end;

    local procedure CreateVendorWithCountryVAT(var Vendor: Record Vendor; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        UpdateCountryOnVendor(Vendor, CountryRegionCode);
        UpdateVendorVATRegistration(Vendor, VATRegistrationNo);
    end;

    local procedure CreateVendorWithCountryVATSilent(var Vendor: Record Vendor; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]): Code[20]
    begin
        LibraryPurchase.CreateVendor(Vendor);
        UpdateCountryOnVendor(Vendor, CountryRegionCode);
        Vendor."VAT Registration No." := VATRegistrationNo;
        Vendor.Modify(true);
        exit(Vendor."No.");
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

    local procedure VerifyVATRegistrationLogEntryExists(AccountType: Enum "VAT Registration Log Account Type"; AccountNo: Code[20])
    var
        VATRegistrationLog: Record "VAT Registration Log";
    begin
        VATRegistrationLog.SetRange("Account Type", AccountType);
        VATRegistrationLog.SetRange("Account No.", AccountNo);
        Assert.RecordIsNotEmpty(VATRegistrationLog);
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

    local procedure CreateGenPostingSetup(var GenPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
    end;

    local procedure DeleteCountryRegion(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        CountryRegion.Delete(true);
    end;

    local procedure FindVATPostingSetupWithAccounts(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        VATPostingSetup.SetFilter("Purchase VAT Account", '<>%1', '');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindGenPostingSetupWithAccounts(var GenPostingSetup: Record "General Posting Setup")
    begin
        GenPostingSetup.SetFilter("Sales Account", '<>%1', '');
        GenPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        LibraryERM.FindGeneralPostingSetup(GenPostingSetup);
    end;

    local procedure FindVATPostingSetup()
    begin
        VATPostingSetup2.SetFilter("Sales VAT Account", '<>%1', '');
        VATPostingSetup2.SetFilter("Purchase VAT Account", '<>%1', '');
        LibraryERM.FindVATPostingSetup(VATPostingSetup2, VATPostingSetup2."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure ModifyCompanyInformation(var CompanyInformation: Record "Company Information"; CountryRegionCode: Code[10]) OldCountryCode: Code[10]
    begin
        CompanyInformation.Get();
        OldCountryCode := CompanyInformation."Country/Region Code";
        CompanyInformation.Validate("Country/Region Code", CountryRegionCode);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateBalanceAccountInGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line"; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    begin
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateCountryOnVendor(var Vendor: Record Vendor; CountryRegionCode: Code[10])
    begin
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Modify(true);
    end;

    local procedure UpdateCountryOnContact(var Contact: Record Contact; CountryRegionCode: Code[10])
    begin
        Contact.Validate("Country/Region Code", CountryRegionCode);
        Contact.Modify(true);
    end;

    local procedure UpdateVendorVATRegistration(var Vendor: Record Vendor; VATRegistrationNo: Text[20])
    begin
        Vendor.Validate("VAT Registration No.", VATRegistrationNo);
        Vendor.Modify(true);
    end;

    local procedure VerifyVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        if VATetc then
            VATPostingSetup.TestField("VAT %", VATPostingSetup2."VAT %")
        else
            VATPostingSetup.TestField("VAT %", 0);
        if SalesAccounts then
            VATPostingSetup.TestField("Sales VAT Account", VATPostingSetup2."Sales VAT Account")
        else
            VATPostingSetup.TestField("Sales VAT Account", '');
        if PurchaseAccounts then
            VATPostingSetup.TestField("Purchase VAT Account", VATPostingSetup2."Purchase VAT Account")
        else
            VATPostingSetup.TestField("Purchase VAT Account", '');
    end;

    local procedure VerifyVATRegistrationOnGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line"; VATRegistrationNo: Text[20])
    begin
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        Assert.AreEqual(
          VATRegistrationNo, GenJournalLine."VAT Registration No.",
          StrSubstNo(VATError, GenJournalLine.FieldCaption("VAT Registration No."), VATRegistrationNo, GenJournalLine.TableCaption()));
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) or Confirm(StrSubstNo(ExpectedMessage2)) then;
    end;

    local procedure CopyVATPostingSetupCard(var VATPostingSetupCard: TestPage "VAT Posting Setup Card"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetupCard.OpenEdit();
        VATPostingSetupCard.FILTER.SetFilter("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATPostingSetupCard.FILTER.SetFilter("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Commit();
        VATPostingSetupCard.Copy.Invoke();
    end;

    local procedure CopyGenPostingSetupCard(var GenPostingSetupCard: TestPage "General Posting Setup Card"; GenPostingSetup: Record "General Posting Setup")
    begin
        GenPostingSetupCard.OpenEdit();
        GenPostingSetupCard.FILTER.SetFilter("Gen. Bus. Posting Group", GenPostingSetup."Gen. Bus. Posting Group");
        GenPostingSetupCard.FILTER.SetFilter("Gen. Prod. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
        Commit();
        GenPostingSetupCard.Copy.Invoke();
    end;

    local procedure VerifyVATPostingSetupWithAccounts(VATPostingSetupPageCard: TestPage "VAT Posting Setup Card"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetupPageCard."Sales VAT Account".AssertEquals(VATPostingSetup."Sales VAT Account");
        VATPostingSetupPageCard."Purchase VAT Account".AssertEquals(VATPostingSetup."Purchase VAT Account");
    end;

    local procedure VerifyGenPostingSetupWithAccounts(GenPostingSetupCard: TestPage "General Posting Setup Card"; GenPostingSetup: Record "General Posting Setup")
    begin
        GenPostingSetupCard."Sales Account".AssertEquals(GenPostingSetup."Sales Account");
        GenPostingSetupCard."Purch. Account".AssertEquals(GenPostingSetup."Purch. Account");
    end;

    local procedure VerifyMessageWithLast3DotChars(ExpectedMessage: Text; ActualMessage: Text)
    begin
        Assert.ExpectedMessage(ExpectedMessage, ActualMessage);
        Assert.AreEqual('...', CopyStr(ActualMessage, StrLen(ActualMessage) - 2, 3), '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure LengthConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvalidCharConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyFieldHandler(var CopyVATPostingSetup: TestRequestPage "Copy - VAT Posting Setup")
    begin
        CopyVATPostingSetup.VATBusPostingGroup.SetValue(VATPostingSetup2."VAT Bus. Posting Group");
        CopyVATPostingSetup.VATProdPostingGroup.SetValue(VATPostingSetup2."VAT Prod. Posting Group");
        CopyVATPostingSetup.Copy.SetValue(Selection);
        if Selection in [Selection::"Selected fields"] then begin
            CopyVATPostingSetup.VATetc.SetValue(VATetc);
            CopyVATPostingSetup.SalesAccounts.SetValue(SalesAccounts);
            CopyVATPostingSetup.PurchaseAccounts.SetValue(PurchaseAccounts);
        end;
        CopyVATPostingSetup.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyVatPostingSetupRequestPageHandler(var CopyVatPostingSetup: TestRequestPage "Copy - VAT Posting Setup")
    var
        VATBusinessPostingGroup: Variant;
        VATProdPostingGroup: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATBusinessPostingGroup);
        LibraryVariableStorage.Dequeue(VATProdPostingGroup);
        CopyVatPostingSetup.VATBusPostingGroup.SetValue(VATBusinessPostingGroup);
        CopyVatPostingSetup.VATProdPostingGroup.SetValue(VATProdPostingGroup);
        CopyVatPostingSetup.SalesAccounts.SetValue(true);
        CopyVatPostingSetup.PurchaseAccounts.SetValue(true);
        CopyVatPostingSetup.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyGenPostingSetupRequestPageHandler(var CopyGenPostingSetup: TestRequestPage "Copy - General Posting Setup")
    var
        GenBusinessPostingGroup: Variant;
        GenProdPostingGroup: Variant;
    begin
        LibraryVariableStorage.Dequeue(GenBusinessPostingGroup);
        LibraryVariableStorage.Dequeue(GenProdPostingGroup);
        CopyGenPostingSetup.GenBusPostingGroup.SetValue(GenBusinessPostingGroup);
        CopyGenPostingSetup.GenProdPostingGroup.SetValue(GenProdPostingGroup);
        CopyGenPostingSetup.SalesAccounts.SetValue(true);
        CopyGenPostingSetup.PurchaseAccounts.SetValue(true);
        CopyGenPostingSetup.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerContact(Msg: Text[1024])
    begin
        if StrPos(Msg, StrSubstNo(MultiContactMsg, ContactNo)) = 1 then
            exit;
        Assert.IsTrue(StrPos(Msg, StrSubstNo(MultiContactMsg, ContactNo)) = 1, StrSubstNo(UnexpectedMsg, Msg));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerCustomer(Msg: Text[1024])
    begin
        if StrPos(Msg, StrSubstNo(MultiCustomerMsg, CustomerNo)) = 1 then
            exit;
        Assert.IsTrue(StrPos(Msg, StrSubstNo(MultiCustomerMsg, CustomerNo)) = 1, StrSubstNo(UnexpectedMsg, Msg));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerVendor(Msg: Text[1024])
    begin
        if StrPos(Msg, StrSubstNo(MultiVendorMsg, VendorNo)) = 1 then
            exit;
        Assert.IsTrue(StrPos(Msg, StrSubstNo(MultiVendorMsg, VendorNo)) = 1, StrSubstNo(UnexpectedMsg, Msg));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATRegistrationLogHandlerSimple(var VATRegistrationLog: TestPage "VAT Registration Log")
    begin
        VATRegistrationLog.OK().Invoke();
    end;
}

