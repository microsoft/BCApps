codeunit 144001 "ERM RU - Base"
{
    // TFS_ID 359661
    // Check field Payment Purpose in Bank Payment Order
    // ----------------------------------------------------------------------------
    // Function Name                                                      TFS ID
    // ----------------------------------------------------------------------------
    // BankPaymentOrderPaymentPurpose                                     359661

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryVATLedger: Codeunit "Library - VAT Ledger";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRUReports: Codeunit "Library RU Reports";
        Assert: Codeunit Assert;
        LocalVATRegNoCheckSumErr: Label 'The entered VAT registration number is incorrect (checksum error).';
        PaymentPurposeErr: Label 'The %1 field should be equal to %2.', Comment = '%1=Payment Purpose field caption;%2=Payment Purpose';
        IsInitialized: Boolean;
        AAAATxt: Label 'AAAA', Locked = true;
        KKKKTxt: Label 'KKKK', Locked = true;
        VendorPostingGroupDescriptionErr: Label 'The Description column is missing in the Vendor Posing Groups window.';
        AddressFormat: Option "Post Code+City","City+Post Code","City+County+Post Code","Blank Line+Post Code+City",,,,,,,,,,Custom;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVendWrongLocalVATRegNo()
    var
        Vendor: Record Vendor;
        VATRegNo: Text[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        VATRegNo := '1234567890'; // use hard-coded wrong VAT Reg. No.

        asserterror Vendor.Validate("VAT Registration No.", VATRegNo);
        Assert.ExpectedError(LocalVATRegNoCheckSumErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCustWrongLocalVATRegNo()
    var
        Customer: Record Customer;
        VATRegNo: Text[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        VATRegNo := '1234567890'; // use hard-coded wrong VAT Reg. No.

        asserterror Customer.Validate("VAT Registration No.", VATRegNo);
        Assert.ExpectedError(LocalVATRegNoCheckSumErr);
    end;

    [Test]
    [HandlerFunctions('BankPaymentOrderHandler')]
    [Scope('OnPrem')]
    procedure BankPaymentOrderPaymentPurpose()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // SETUP
        CreateGenJournalLine(GenJournalLine);
        Clear(LibraryReportValidation);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // EXERCISE
        ExecuteBankPaymentOrderReport(GenJournalLine);

        // VERIFY
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExists(GenJournalLine."Payment Purpose"),
          StrSubstNo(PaymentPurposeErr, GenJournalLine.FieldCaption("Payment Purpose"), GenJournalLine."Payment Purpose"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVendorName_UT_Name()
    var
        Vendor: Record Vendor;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".GetVendorName() returns Vendor.Name in case of Vendor."Name 2" = '', Vendor."Full Name" = ''
        CreateVendor(Vendor, LibraryUtility.GenerateGUID(), '', '');
        Assert.AreEqual(Vendor.Name, LocalReportMgt.GetVendorName(Vendor."No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVendorName_UT_Name2()
    var
        Vendor: Record Vendor;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".GetVendorName() returns Vendor.Name + Vendor."Name 2" in case of Vendor."Full Name" = ''
        CreateVendor(Vendor, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), '');
        Assert.AreEqual(Vendor.Name + ' ' + Vendor."Name 2", LocalReportMgt.GetVendorName(Vendor."No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVendorName_UT_FullName()
    var
        Vendor: Record Vendor;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".GetVendorName() returns Vendor."Full Name" in case of Vendor."Full Name" <> ''
        CreateVendor(Vendor, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        Assert.AreEqual(Vendor."Full Name", LocalReportMgt.GetVendorName(Vendor."No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsConventionalCurrency_Negative_EmptyCode()
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".IsConventionalCurrency() returns FALSE in case of empty currency code
        Assert.IsFalse(LocalReportMgt.IsConventionalCurrency(''), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsConventionalCurrency_Negative()
    var
        Currency: Record Currency;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".IsConventionalCurrency() returns FALSE in case of non-conventional currency
        LibraryERM.CreateCurrency(Currency);
        Assert.IsFalse(LocalReportMgt.IsConventionalCurrency(Currency.Code), Currency.FieldCaption(Conventional));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsConventionalCurrency_Positive()
    var
        Currency: Record Currency;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".IsConventionalCurrency() returns TRUE in case of conventional currency
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate(Conventional, true);
        Currency.Modify();
        Assert.IsTrue(LocalReportMgt.IsConventionalCurrency(Currency.Code), Currency.FieldCaption(Conventional));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsForeignCurrency_Negative_EmptyCode()
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".IsForeignCurrency() returns FALSE in case of empty currency code
        Assert.IsFalse(LocalReportMgt.IsForeignCurrency(''), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsForeignCurrency_Negative()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".IsForeignCurrency() returns FALSE in case of non-foreign currency
        Initialize();
        LibraryERM.CreateCurrency(Currency);

        GLSetup.Get();
        GLSetup."LCY Code" := '';        // to avoid error on updating LCY Code
        GLSetup.Validate("LCY Code", Currency.Code);
        GLSetup.Modify();

        Assert.IsFalse(LocalReportMgt.IsForeignCurrency(Currency.Code), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsForeignCurrency_Positive()
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".IsForeignCurrency() returns TRUE in case of foreign currency
        Initialize();
        LibraryERM.CreateCurrency(Currency);

        GLSetup.Get();
        GLSetup."LCY Code" := '';        // to avoid error on updating LCY Code
        GLSetup.Validate("LCY Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        GLSetup.Modify();

        Assert.IsTrue(LocalReportMgt.IsForeignCurrency(Currency.Code), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_HasRelationalCurrCode_EmptyCode()
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".HasRelationalCurrCode() returns FALSE in case of empty currency code
        Initialize();
        Assert.IsFalse(LocalReportMgt.HasRelationalCurrCode('', WorkDate()), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_HasRelationalCurrCode_Negative_NoExchRate()
    var
        Currency: Record Currency;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".HasRelationalCurrCode() returns FALSE in case of currency without exchange rates
        LibraryERM.CreateCurrency(Currency);
        Assert.IsFalse(LocalReportMgt.HasRelationalCurrCode(Currency.Code, WorkDate()), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_HasRelationalCurrCode_Negative_NoRelCurr()
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".HasRelationalCurrCode() returns FALSE in case of currency without relational currency code
        Assert.IsFalse(
          LocalReportMgt.HasRelationalCurrCode(LibraryERM.CreateCurrencyWithRandomExchRates(), WorkDate()), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_HasRelationalCurrCode_Positive()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".HasRelationalCurrCode() returns TRUE in case of currency with relational currency code
        CurrencyExchangeRate.SetRange("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        CurrencyExchangeRate.Modify();

        Assert.IsTrue(
          LocalReportMgt.HasRelationalCurrCode(CurrencyExchangeRate."Currency Code", WorkDate()), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_FormatAmount()
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".FormatAmount() returns correct RU XML text amount format
        Assert.AreEqual('-12345.46', LocalReportMgt.FormatAmount(-12345.456), '');
        Assert.AreEqual('-12345.46', LibraryRUReports.FormatAmountXML(-12345.456), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVATLedgerAmounInclVATFCY_NotPartial()
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".GetVATLedgerAmounInclVATFCY() returns correct RU XML text amount format in case of "Partial" = FALSE
        DummyVATLedgerLine.Init();
        DummyVATLedgerLine."Amount Including VAT" := -12345.456;
        Assert.AreEqual('-12345.46', LocalReportMgt.GetVATLedgerAmounInclVATFCY(DummyVATLedgerLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVATLedgerAmounInclVATFCY_Partial()
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO] COD 12401 "Local Report Management".GetVATLedgerAmounInclVATFCY() returns correct RU XML text amount format in case of "Partial" = TRUE
        DummyVATLedgerLine.Init();
        DummyVATLedgerLine.Partial := true;
        DummyVATLedgerLine."Amount Including VAT" := -12345.456;
        Assert.AreEqual('-12345.46; partial', LocalReportMgt.GetVATLedgerAmounInclVATFCY(DummyVATLedgerLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVATLedgerDataUcTov_Vendor()
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO 378574] COD 12401 "Local Report Management".GetVATLedgerDataUcTov() returns "Unreal. VAT Entry Date" for vendor entry
        DummyVATLedgerLine.Init();
        DummyVATLedgerLine."C/V Type" := DummyVATLedgerLine."C/V Type"::Vendor;
        DummyVATLedgerLine."Unreal. VAT Entry Date" := LibraryRandom.RandDate(10);
        DummyVATLedgerLine."Real. VAT Entry Date" := LibraryRandom.RandDateFrom(DummyVATLedgerLine."Unreal. VAT Entry Date", 10);
        Assert.AreEqual(
          DummyVATLedgerLine."Unreal. VAT Entry Date",
          LocalReportMgt.GetVATLedgerItemRealizeDate(DummyVATLedgerLine),
          DummyVATLedgerLine.FieldCaption("Unreal. VAT Entry Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVATLedgerDataUcTov_CustomerPrepmtPmt()
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO 378574] COD 12401 "Local Report Management".GetVATLedgerDataUcTov() returns "Unreal. VAT Entry Date" for customer prepayment "Payment" entry
        DummyVATLedgerLine.Init();
        DummyVATLedgerLine."C/V Type" := DummyVATLedgerLine."C/V Type"::Customer;
        DummyVATLedgerLine.Prepayment := true;
        DummyVATLedgerLine."Document Type" := DummyVATLedgerLine."Document Type"::Payment;
        DummyVATLedgerLine."Unreal. VAT Entry Date" := LibraryRandom.RandDate(10);
        DummyVATLedgerLine."Real. VAT Entry Date" := LibraryRandom.RandDateFrom(DummyVATLedgerLine."Unreal. VAT Entry Date", 10);
        Assert.AreEqual(
          DummyVATLedgerLine."Unreal. VAT Entry Date",
          LocalReportMgt.GetVATLedgerItemRealizeDate(DummyVATLedgerLine),
          DummyVATLedgerLine.FieldCaption("Unreal. VAT Entry Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVATLedgerDataUcTov_CustomerPrepmtInv()
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO 378574] COD 12401 "Local Report Management".GetVATLedgerDataUcTov() returns "Real. VAT Entry Date" for customer prepayment "Invoice" entry
        DummyVATLedgerLine.Init();
        DummyVATLedgerLine."C/V Type" := DummyVATLedgerLine."C/V Type"::Customer;
        DummyVATLedgerLine.Prepayment := true;
        DummyVATLedgerLine."Document Type" := DummyVATLedgerLine."Document Type"::Invoice;
        DummyVATLedgerLine."Unreal. VAT Entry Date" := LibraryRandom.RandDate(10);
        DummyVATLedgerLine."Real. VAT Entry Date" := LibraryRandom.RandDateFrom(DummyVATLedgerLine."Unreal. VAT Entry Date", 10);
        Assert.AreEqual(
          DummyVATLedgerLine."Real. VAT Entry Date",
          LocalReportMgt.GetVATLedgerItemRealizeDate(DummyVATLedgerLine),
          DummyVATLedgerLine.FieldCaption("Real. VAT Entry Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVATLedgerXMLFileName()
    var
        VATLedger: Record "VAT Ledger";
        LocalReportManagement: Codeunit "Local Report Management";
        SONOAdmin: array[2] of Code[4];
        SONOReceipt: array[2] of Code[4];
        VATLedgerType: Option;
        AddSheet: Boolean;
        IndividualPerson: Boolean;
        SONOAdminIndex: Integer;
        SONOReceiptIndex: Integer;
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO 166062] COD 12401 "Local Report Management".GetVATLedgerXMLFileName() returns correct VAT Ledger XML File Name
        Initialize();

        SONOAdmin[1] := '';
        SONOAdmin[2] := Format(LibraryRandom.RandIntInRange(1000, 9999));
        SONOReceipt[1] := '';
        SONOReceipt[2] := Format(LibraryRandom.RandIntInRange(1000, 9999));

        for SONOAdminIndex := 1 to ArrayLen(SONOAdmin) do
            for SONOReceiptIndex := 1 to ArrayLen(SONOReceipt) do
                for IndividualPerson := false to true do begin
                    UpdateCompanyInformation(IndividualPerson, SONOAdmin[SONOAdminIndex], SONOReceipt[SONOReceiptIndex]);
                    for VATLedgerType := VATLedger.Type::Purchase to VATLedger.Type::Sales do
                        for AddSheet := false to true do
                            Assert.AreEqual(
                              GenerateVATLedgerXMLFileName(VATLedgerType, AddSheet),
                              LocalReportManagement.GetVATLedgerXMLFileName(VATLedgerType, AddSheet), '');
                end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsCustomerPrepayment_Positive()
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO 379315] COD 12401 "Local Report Management".IsCustomerPrepayment() returns TRUE in case of customer prepayment invoice
        InitVATLedgerLine(DummyVATLedgerLine, DummyVATLedgerLine."C/V Type"::Customer, true, DummyVATLedgerLine."Document Type"::Invoice);
        Assert.IsTrue(LocalReportManagement.IsCustomerPrepayment(DummyVATLedgerLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsCustomerPrepayment_Negative_Vendor()
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO 379315] COD 12401 "Local Report Management".IsCustomerPrepayment() returns FALSE in case of vendor entry
        InitVATLedgerLine(DummyVATLedgerLine, DummyVATLedgerLine."C/V Type"::Vendor, true, DummyVATLedgerLine."Document Type"::Invoice);
        Assert.IsFalse(LocalReportManagement.IsCustomerPrepayment(DummyVATLedgerLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsCustomerPrepayment_Negative_NotPrepayment()
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO 379315] COD 12401 "Local Report Management".IsCustomerPrepayment() returns FALSE in case of not prepayment
        InitVATLedgerLine(DummyVATLedgerLine, DummyVATLedgerLine."C/V Type"::Customer, false, DummyVATLedgerLine."Document Type"::Invoice);
        Assert.IsFalse(LocalReportManagement.IsCustomerPrepayment(DummyVATLedgerLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_IsCustomerPrepayment_Negative_NotInvoice()
    var
        DummyVATLedgerLine: Record "VAT Ledger Line";
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO 379315] COD 12401 "Local Report Management".IsCustomerPrepayment() returns FALSE in case of not Invoice
        InitVATLedgerLine(DummyVATLedgerLine, DummyVATLedgerLine."C/V Type"::Customer, true, DummyVATLedgerLine."Document Type"::Payment);
        Assert.IsFalse(LocalReportManagement.IsCustomerPrepayment(DummyVATLedgerLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionFieldOnVendorPostingGroupsPage()
    var
        VendorPostingGroups: TestPage "Vendor Posting Groups";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 379554] Column Description exists on Page Vendor Posting Groups

        // [WHEN] Open Page Vendor Posting Groups
        VendorPostingGroups.OpenView();

        // [THEN] Column Description appears
        Assert.IsTrue(VendorPostingGroups.Description.Visible(), VendorPostingGroupDescriptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageCountriesRegionsShowsEAEUCountryRegionCodeField()
    var
        CountriesRegions: TestPage "Countries/Regions";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 234588] Page 10 "Countries/Regions" shows "EAEU Country/Region Code" field
        Initialize();
        CountriesRegions.OpenEdit();
        Assert.IsTrue(CountriesRegions."EAEU Country/Region Code".Visible(), '');
        Assert.IsTrue(CountriesRegions."EAEU Country/Region Code".Enabled(), '');
        CountriesRegions.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountryRegion_IsEAEUCountry()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 234588] TAB 9 "Country/Region".IsEAEUCountry() returns TRUE only in case of EAEU Country <> CompanyInformation EAEU Country
        Initialize();
        CompanyInformation.Get();

        // Both EAEU, different
        CountryRegion.Get(LibraryVATLedger.MockCountryEAEU());
        CompanyInformation.Validate("Country/Region Code", LibraryVATLedger.MockCountryEAEU());
        CompanyInformation.Modify();
        Assert.IsTrue(CountryRegion.IsEAEUCountry(), '');

        // Company non EAEU, target - EAEU
        CountryRegion.Get(LibraryVATLedger.MockCountryEAEU());
        CompanyInformation.Validate("Country/Region Code", LibraryVATLedger.MockCountryNonEAEU());
        CompanyInformation.Modify();
        Assert.IsFalse(CountryRegion.IsEAEUCountry(), '');

        // Company EAEU, target - non EAEU
        CountryRegion.Get(LibraryVATLedger.MockCountryNonEAEU());
        CompanyInformation.Validate("Country/Region Code", LibraryVATLedger.MockCountryEAEU());
        CompanyInformation.Modify();
        Assert.IsFalse(CountryRegion.IsEAEUCountry(), '');

        // Both non EAEU
        CountryRegion.Get(LibraryVATLedger.MockCountryNonEAEU());
        CompanyInformation.Validate("Country/Region Code", LibraryVATLedger.MockCountryNonEAEU());
        CompanyInformation.Modify();
        Assert.IsFalse(CountryRegion.IsEAEUCountry(), '');

        // Both EAEU, equals
        CountryRegion.Get(LibraryVATLedger.MockCountryEAEU());
        CompanyInformation.Validate("Country/Region Code", CountryRegion.Code);
        CompanyInformation.Modify();
        Assert.IsFalse(CountryRegion.IsEAEUCountry(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesLine_EAEUCustomer_EAEUShipToAddress()
    var
        SalesLine: array[4] of Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() in case of
        // [SCENARIO 234588] EAEU customer, EAEU ship-to address
        Initialize();

        // [GIVEN] Sales document with EAEU customer, EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddressEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesHeaderWithSevLines(SalesLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = "C"
        // [THEN] Line4 result = "D"
        VerifyEAEUItemTariffNo_FourSalesLines(SalesLine, TariffNo[1], '', TariffNo[3], TariffNo[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesLine_EAEUCustomer_NonEAEUShipToAddress()
    var
        SalesLine: array[4] of Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() in case of
        // [SCENARIO 234588] EAEU customer, Non-EAEU ship-to address
        Initialize();

        // [GIVEN] Sales document with EAEU customer, Non-EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddressNonEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesHeaderWithSevLines(SalesLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = ""
        // [THEN] Line4 result = ""
        VerifyEAEUItemTariffNo_FourSalesLines(SalesLine, TariffNo[1], '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesLine_EAEUCustomer_ShipToAddressWithBlankedCountry()
    var
        SalesLine: array[4] of Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() in case of
        // [SCENARIO 234588] EAEU customer, ship-to address with blanked country\region code
        Initialize();

        // [GIVEN] Sales document with EAEU customer, header's ship-to address with blanked country\region code
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddress(CustomerNo, '');
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesHeaderWithSevLines(SalesLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = "C"
        // [THEN] Line4 result = "D"
        VerifyEAEUItemTariffNo_FourSalesLines(SalesLine, TariffNo[1], '', TariffNo[3], TariffNo[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesLine_NonEAEUCustomer_EAEUShipToAddress()
    var
        SalesLine: array[4] of Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() in case of
        // [SCENARIO 234588] Non-EAEU customer, EAEU ship-to address
        Initialize();

        // [GIVEN] Sales document with Non-EAEU customer, EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryNonEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddressEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesHeaderWithSevLines(SalesLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = "C"
        // [THEN] Line4 result = "D"
        VerifyEAEUItemTariffNo_FourSalesLines(SalesLine, TariffNo[1], '', TariffNo[3], TariffNo[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesLine_NonEAEUCustomer_NonEAEUShipToAddress()
    var
        SalesLine: array[4] of Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() in case of
        // [SCENARIO 234588] Non-EAEU customer, Non-EAEU ship-to address
        Initialize();

        // [GIVEN] Sales document with Non-EAEU customer, Non-EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryNonEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddressNonEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesHeaderWithSevLines(SalesLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = ""
        // [THEN] Line4 result = ""
        VerifyEAEUItemTariffNo_FourSalesLines(SalesLine, TariffNo[1], '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesLine_NonEAEUCustomer_ShipToAddressWithBlankedCountry()
    var
        SalesLine: array[4] of Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() in case of
        // [SCENARIO 234588] Non-EAEU customer, ship-to address with blanked country\region code
        Initialize();

        // [GIVEN] Sales document with Non-EAEU customer, header's ship-to address with blanked country\region code
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryNonEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddress(CustomerNo, '');
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesHeaderWithSevLines(SalesLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = ""
        // [THEN] Line4 result = ""
        VerifyEAEUItemTariffNo_FourSalesLines(SalesLine, TariffNo[1], '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesLine_CustomerWithBlankedCountry_EAEUShipToAddress()
    var
        SalesLine: array[4] of Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() in case of
        // [SCENARIO 234588] customer with blanked country\region code, EAEU ship-to address
        Initialize();

        // [GIVEN] Sales document with Non-EAEU customer, EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo('');
        ShipToAddress := LibraryVATLedger.MockShipToAddressEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesHeaderWithSevLines(SalesLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = "C"
        // [THEN] Line4 result = "D"
        VerifyEAEUItemTariffNo_FourSalesLines(SalesLine, TariffNo[1], '', TariffNo[3], TariffNo[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesLine_CustomerWithBlankedCountry_NonEAEUShipToAddress()
    var
        SalesLine: array[4] of Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() in case of
        // [SCENARIO 234588] customer with blanked country\region code, Non-EAEU ship-to address
        Initialize();

        // [GIVEN] Sales document with Non-EAEU customer, Non-EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo('');
        ShipToAddress := LibraryVATLedger.MockShipToAddressNonEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesHeaderWithSevLines(SalesLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = ""
        // [THEN] Line4 result = ""
        VerifyEAEUItemTariffNo_FourSalesLines(SalesLine, TariffNo[1], '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesLine_CustomerWithBlankedCountry_ShipToAddressWithBlankedCountry()
    var
        SalesLine: array[4] of Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() in case of
        // [SCENARIO 234588] customer with blanked country\region code, ship-to address with blanked country\region code
        Initialize();

        // [GIVEN] Sales document with Non-EAEU customer, header's ship-to address with blanked country\region code
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo('');
        ShipToAddress := LibraryVATLedger.MockShipToAddress(CustomerNo, '');
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesHeaderWithSevLines(SalesLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = ""
        // [THEN] Line4 result = ""
        VerifyEAEUItemTariffNo_FourSalesLines(SalesLine, TariffNo[1], '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesInvLine_EAEUCustomer_EAEUShipToAddress()
    var
        SalesInvoiceLine: array[4] of Record "Sales Invoice Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT] [Invoice]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesInvLine() in case of
        // [SCENARIO 234588] sales invoice, EAEU customer, EAEU ship-to address
        Initialize();

        // [GIVEN] Sales invoice with EAEU customer, EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddressEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesInvWithSevLines(SalesInvoiceLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesInvLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = "C"
        // [THEN] Line4 result = "D"
        VerifyEAEUItemTariffNo_FourSalesInvLines(SalesInvoiceLine, TariffNo[1], '', TariffNo[3], TariffNo[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_SalesCrMemoLine_EAEUCustomer_EAEUShipToAddress()
    var
        SalesCrMemoLine: array[4] of Record "Sales Cr.Memo Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT] [Credit Memo]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesCrMemoLine() in case of
        // [SCENARIO 234588] sales credit memo, EAEU customer, EAEU ship-to address
        Initialize();

        // [GIVEN] Sales credit memo with EAEU customer, EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddressEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesCrMemoWithSevLines(SalesCrMemoLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_SalesCrMemoLine() per each document line
        // [THEN] Line1 result = "A"
        // [THEN] Line2 result = ""
        // [THEN] Line3 result = "C"
        // [THEN] Line4 result = "D"
        VerifyEAEUItemTariffNo_FourSalesCrMemoLines(SalesCrMemoLine, TariffNo[1], '', TariffNo[3], TariffNo[4]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_ValueEntry_SalesInvoice_EAEUCustomer_EAEUShipToAddress()
    var
        SalesInvoiceLine: array[4] of Record "Sales Invoice Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT] [Invoice]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_ValueEntry() in case of
        // [SCENARIO 234588] sales invoice, EAEU customer, EAEU ship-to address
        Initialize();

        // [GIVEN] Sales invoice with EAEU customer, EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddressEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesInvWithSevLines(SalesInvoiceLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_ValueEntry() per each document line
        // [THEN] Line1 result = TRUE
        // [THEN] Line2 result = FALSE
        // [THEN] Line3 result = TRUE
        // [THEN] Line4 result = TRUE
        VerifyEAEUItemTariffNo_FourValueEntries_SalesInvoice(SalesInvoiceLine, true, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetEAEUItemTariffNo_ValueEntry_SalesCrMemo_EAEUCustomer_EAEUShipToAddress()
    var
        SalesCrMemoLine: array[4] of Record "Sales Cr.Memo Line";
        CustomerNo: Code[20];
        ItemNo: array[4] of Code[20];
        TariffNo: array[4] of Code[20];
        LocationCode: array[4] of Code[10];
        ShipToAddress: Code[10];
    begin
        // [FEATURE] [Tariff No.] [UT] [Credit Memo]
        // [SCENARIO 234588] COD 12401 "Local Report Management".GetEAEUItemTariffNo_ValueEntry() in case of
        // [SCENARIO 234588] sales credit memo, EAEU customer, EAEU ship-to address
        Initialize();

        // [GIVEN] Sales credit memo with EAEU customer, EAEU header's ship-to address
        // [GIVEN] Sales line1: item with tariff "A" and EAEU location
        // [GIVEN] Sales line2: item with tariff "B" and Non-EAEU location
        // [GIVEN] Sales line3: item with tariff "C" and location without specified country\region code
        // [GIVEN] Sales line4: item with tariff "D" and blanked location
        CustomerNo := LibraryVATLedger.MockCustomerNo(LibraryVATLedger.MockCountryEAEU());
        ShipToAddress := LibraryVATLedger.MockShipToAddressEAEU(CustomerNo);
        MockSevItemsAndLocations(ItemNo, TariffNo, LocationCode);
        MockSalesCrMemoWithSevLines(SalesCrMemoLine, CustomerNo, ShipToAddress, ItemNo, LocationCode);

        // [WHEN] Invoke COD 12401 "Local Report Management".GetEAEUItemTariffNo_ValueEntry() per each document line
        // [THEN] Line1 result = TRUE
        // [THEN] Line2 result = FALSE
        // [THEN] Line3 result = TRUE
        // [THEN] Line4 result = TRUE
        VerifyEAEUItemTariffNo_FourValueEntries_SalesCrMemo(SalesCrMemoLine, true, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Library_CreatePostCode()
    var
        PostCode: Record "Post Code";
    begin
        // [FEATURE] [Address] [UT] [Post Code]
        // [SCENARIO 251306] COD 140316 "Library RU Reports".CreatePostCode()
        LibraryRUReports.CreatePostCode(PostCode);
        PostCode.TestField("Country/Region Code");
        PostCode.TestField(City);
        PostCode.TestField(County);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Library_CreateVendor()
    var
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Address] [UT] [Vendor]
        // [SCENARIO 251306] COD 140316 "Library RU Reports".CreateVendor()
        LibraryRUReports.CreateVendor(Vendor);
        Vendor.TestField("Country/Region Code");
        Vendor.TestField(City);
        Vendor.TestField(County);
        Vendor.TestField(Address);
        Vendor.TestField("Address 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Library_CreateCustomer()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Address] [UT] [Customer]
        // [SCENARIO 251306] COD 140316 "Library RU Reports".CreateCustomer()
        LibraryRUReports.CreateCustomer(Customer);
        Customer.TestField("Country/Region Code");
        Customer.TestField(City);
        Customer.TestField(County);
        Customer.TestField(Address);
        Customer.TestField("Address 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Library_UpdateCompanyAddress()
    var
        CompanyAddress: Record "Company Address";
    begin
        // [FEATURE] [Address] [UT] [Company Information]
        // [SCENARIO 251306] COD 140316 "Library RU Reports".UpdateCompanyAddress()
        LibraryRUReports.UpdateCompanyAddress();
        CompanyAddress.FindFirst();
        CompanyAddress.TestField("Country/Region Code");
        CompanyAddress.TestField(City);
        CompanyAddress.TestField("Region Name");
        CompanyAddress.TestField(County);
        CompanyAddress.TestField(Address);
        CompanyAddress.TestField("Address 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Library_GetCustomerFullAddress()
    var
        Customer: Record Customer;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Address] [UT] [Customer]
        // [SCENARIO 251306] COD 140316 "Library RU Reports".GetCustomerFullAddress()
        LibraryRUReports.CreateCustomer(Customer);

        Assert.AreEqual(
            LocalReportMgt.GetFullAddr(Customer."Post Code", Customer.City, Customer.Address, Customer."Address 2", '', Customer.County),
            LibraryRUReports.GetCustomerFullAddress(Customer."No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCodeCountyField()
    var
        PostCode: Record "Post Code";
        PostCodes: TestPage "Post Codes";
    begin
        // [FEATURE] [Address] [UT] [UI] [Post Code]
        // [SCENARIO 251306] "County" is visible on "Post Codes" page
        Initialize();
        LibraryRUReports.CreatePostCode(PostCode);

        PostCodes.OpenEdit();
        PostCodes.GotoRecord(PostCode);
        Assert.IsTrue(PostCodes.County.Visible(), '');
        Assert.IsTrue(PostCodes.County.Editable(), '');
        PostCodes.County.AssertEquals(PostCode.County);
        PostCodes.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCountyFieldWhenAddrFormatWithCounty()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        CustomerCard: TestPage "Customer Card";
        NewCountyValue: Text[30];
    begin
        // [FEATURE] [Address] [UT] [UI] [Customer]
        // [SCENARIO 267176] "County" is visible on "Customer Card" page in case Contry/Region has Address Format = "City+County+Post Code".
        // [SCENARIO 251306] "County" is validated after "Post Code" type.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryRUReports.CreatePostCode(PostCode);

        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
        Customer.TestField(County, PostCode.County);

        SetCountryRegionAddressFormat(Customer."Country/Region Code", AddressFormat::"City+County+Post Code");

        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        Assert.IsTrue(CustomerCard.County.Visible(), '');
        Assert.IsTrue(CustomerCard.County.Editable(), '');
        CustomerCard.County.AssertEquals(Customer.County);

        NewCountyValue := LibraryUtility.GenerateGUID();
        CustomerCard.County.SetValue(NewCountyValue);
        CustomerCard.Close();
        Customer.Find();
        Customer.TestField(County, NewCountyValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCountyFieldNotVisibleWhenAddrFormatWithoutCounty()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Address] [UT] [UI] [Customer]
        // [SCENARIO 267176] "County" is not visible on "Customer Card" page in case Contry/Region has Address Format <> "City+County+Post Code".
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryRUReports.CreatePostCode(PostCode);

        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
        SetCountryRegionAddressFormat(Customer."Country/Region Code", AddressFormat::"City+Post Code");

        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        Assert.IsFalse(CustomerCard.County.Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCountyFieldWhenAddrFormatWithCounty()
    var
        Vendor: Record Vendor;
        PostCode: Record "Post Code";
        VendorCard: TestPage "Vendor Card";
        NewCountyValue: Text[30];
    begin
        // [FEATURE] [Address] [UT] [UI] [Vendor]
        // [SCENARIO 251306] "County" is visible on "Vendor Card" page in case Contry/Region has Address Format = "City+County+Post Code".
        // [SCENARIO 251306] "County" is validated after "Post Code" type.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryRUReports.CreatePostCode(PostCode);

        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Modify(true);
        Vendor.TestField(County, PostCode.County);

        SetCountryRegionAddressFormat(Vendor."Country/Region Code", AddressFormat::"City+County+Post Code");

        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        Assert.IsTrue(VendorCard.County.Visible(), '');
        Assert.IsTrue(VendorCard.County.Editable(), '');
        VendorCard.County.AssertEquals(Vendor.County);

        NewCountyValue := LibraryUtility.GenerateGUID();
        VendorCard.County.SetValue(NewCountyValue);
        VendorCard.Close();
        Vendor.Find();
        Vendor.TestField(County, NewCountyValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCountyFieldNotVisibleWhenAddrFormatWithoutCounty()
    var
        Vendor: Record Vendor;
        PostCode: Record "Post Code";
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Address] [UT] [UI] [Vendor]
        // [SCENARIO 267176] "County" is not visible on "Vendor Card" page in case Contry/Region has Address Format <> "City+County+Post Code".
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryRUReports.CreatePostCode(PostCode);

        Vendor.Validate("Post Code", PostCode.Code);
        Vendor.Modify(true);
        SetCountryRegionAddressFormat(Vendor."Country/Region Code", AddressFormat::"City+Post Code");

        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        Assert.IsFalse(VendorCard.County.Visible(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyAdressCountyField()
    var
        CompanyAddress: Record "Company Address";
        CompanyAddressPage: TestPage "Company Address";
    begin
        // [FEATURE] [Address] [UT] [UI] [Company Information]
        // [SCENARIO 251306] "County" is visible on "Company Address" page and validated after "Post Code" type
        Initialize();

        CompanyAddress.FindFirst();
        CompanyAddress.Validate(County, LibraryUtility.GenerateGUID());
        CompanyAddress.Modify(true);

        CompanyAddressPage.OpenEdit();
        CompanyAddressPage.GotoRecord(CompanyAddress);
        Assert.IsTrue(CompanyAddressPage.County.Visible(), '');
        Assert.IsTrue(CompanyAddressPage.County.Editable(), '');
        CompanyAddressPage.County.AssertEquals(CompanyAddress.County);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetFullAddr()
    var
        LocalReportMgt: Codeunit "Local Report Management";
        PostCode: Code[20];
        City: Text[30];
        Address: Text[50];
        Address2: Text[50];
        Region: Text[30];
        County: Text[30];
    begin
        // [FEATURE] [Address] [UT]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetFullAddr()
        Initialize();
        PostCode := LibraryUtility.GenerateGUID();
        City := LibraryUtility.GenerateGUID();
        Address := LibraryUtility.GenerateGUID();
        Address2 := LibraryUtility.GenerateGUID();
        Region := LibraryUtility.GenerateGUID();
        County := LibraryUtility.GenerateGUID();

        Assert.AreEqual(
          PostCode + ', ' + Region + ', ' + County + ', ' + City + ', ' + Address + ', ' + Address2,
          LocalReportMgt.GetFullAddr(PostCode, City, Address, Address2, Region, County), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetVendorAddress()
    var
        Vendor: Record Vendor;
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Address] [UT] [Vendor]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetVendorAddress()
        Initialize();
        LibraryRUReports.CreateVendor(Vendor);

        Assert.AreEqual(
            LocalReportMgt.GetFullAddr(Vendor."Post Code", Vendor.City, Vendor.Address, Vendor."Address 2", '', Vendor.County),
            LocalReportMgt.GetVendorAddress(Vendor."No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetLegalAddress()
    var
        CompanyAddress: Record "Company Address";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        // [FEATURE] [Address] [UT] [Company Information]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetLegalAddress()
        Initialize();
        LibraryRUReports.UpdateCompanyAddress();

        CompanyAddress.FindFirst();
        Assert.AreEqual(
          LocalReportMgt.GetFullAddr(CompanyAddress."Post Code", CompanyAddress.City, CompanyAddress.Address, CompanyAddress."Address 2", CompanyAddress."Region Name", CompanyAddress.County),
          LocalReportMgt.GetLegalAddress(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetCustInfo_Order()
    var
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        ShipToCustomerNo: Code[20];
        BillToCustomerNo: Code[20];
    begin
        // [FEATURE] [Address] [UT] [Sales] [Order]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetCustInfo() in case of Sales Order
        Initialize();
        CreateSalesDocWithDiffSellToShipToBillTo(
          SalesHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo, SalesHeader."Document Type"::Order);
        VerifySalesDocDiffSellToShipToBillToAddress(SalesHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetCustInfo_Invoice()
    var
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        ShipToCustomerNo: Code[20];
        BillToCustomerNo: Code[20];
    begin
        // [FEATURE] [Address] [UT] [Sales] [Invoice]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetCustInfo() in case of Sales Invoice
        Initialize();
        CreateSalesDocWithDiffSellToShipToBillTo(
          SalesHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo, SalesHeader."Document Type"::Invoice);
        VerifySalesDocDiffSellToShipToBillToAddress(SalesHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetCustInfo_CrMemo()
    var
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        ShipToCustomerNo: Code[20];
        BillToCustomerNo: Code[20];
    begin
        // [FEATURE] [Address] [UT] [Sales] [Credit Memo]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetCustInfo() in case of Sales Credit Memo
        Initialize();
        CreateSalesDocWithDiffSellToShipToBillTo(
          SalesHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo, SalesHeader."Document Type"::"Credit Memo");
        VerifySalesDocDiffSellToShipToBillToAddress(SalesHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetCustInfo_InvoiceHeader()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        ShipToCustomerNo: Code[20];
        BillToCustomerNo: Code[20];
    begin
        // [FEATURE] [Address] [UT] [Sales] [Invoice]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetCustInfo() in case of posted Sales Invoice
        Initialize();
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithDiffSellToShipToBillTo(
            SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo, SalesHeader."Document Type"::Invoice));
        VerifySalesDocDiffSellToShipToBillToAddress(SalesInvoiceHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetCustInfo_CrMemoHeader()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        ShipToCustomerNo: Code[20];
        BillToCustomerNo: Code[20];
    begin
        // [FEATURE] [Address] [UT] [Sales] [Credit Memo]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetCustInfo() in case of posted Sales Credit Memo
        Initialize();
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithDiffSellToShipToBillTo(
            SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo, SalesHeader."Document Type"::"Credit Memo"));
        VerifySalesDocDiffSellToShipToBillToAddress(SalesCrMemoHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetCustInfo_ShipmentHeader()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        ShipToCustomerNo: Code[20];
        BillToCustomerNo: Code[20];
    begin
        // [FEATURE] [Address] [UT] [Sales] [Shipment]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetCustInfo() in case of Shipment
        Initialize();
        CreatePostSalesDocWithDiffSellToShipToBillTo(
          SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo, SalesHeader."Document Type"::Invoice);
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesShipmentHeader.FindFirst();
        VerifySalesDocDiffSellToShipToBillToAddress(SalesShipmentHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocRepMgt_GetCustInfo_ReturnReceiptHeader()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesHeader: Record "Sales Header";
        SellToCustomerNo: Code[20];
        ShipToCustomerNo: Code[20];
        BillToCustomerNo: Code[20];
    begin
        // [FEATURE] [Address] [UT] [Sales] [Return Receipt]
        // [SCENARIO 251306] COD 12401 "Local Report Management".GetCustInfo() in case of Return Receipt
        Initialize();
        CreatePostSalesDocWithDiffSellToShipToBillTo(
          SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo, SalesHeader."Document Type"::"Credit Memo");
        ReturnReceiptHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        ReturnReceiptHeader.FindFirst();
        VerifySalesDocDiffSellToShipToBillToAddress(ReturnReceiptHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo);
    end;

    [Test]
    procedure LocRepMgt_GetVATLedgerFormatVersion()
    var
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        // [FEATURE] [VAT Ledger] [Report] [XML] [UT]
        // [SCENARIO 400756] VAT Ledger version is '5.08'
        Assert.AreEqual('5.08', LocalReportManagement.GetVATLedgerFormatVersion(), 'VAT Ledger version');
    end;

    local procedure Initialize()
    var
        DummySalesHeader: Record "Sales Header";
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibraryVATLedger.UpdateCompanyInformationEAEU();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibraryERM.DisableMyNotifications(UserId, DummySalesHeader.GetModifyBillToCustomerAddressNotificationId());
    end;

    local procedure CreateGenJournalBatchWithBalAccount(var GenJournalTemplateName: Code[10]; var GenJournalBatchName: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplateName := GenJournalTemplate.Name;
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateName);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        GenJournalBatch.Modify();
        GenJournalBatchName := GenJournalBatch.Name;
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplateName: Code[10];
        GenJournalBatchName: Code[10];
    begin
        CreateGenJournalBatchWithBalAccount(GenJournalTemplateName, GenJournalBatchName);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplateName, GenJournalBatchName, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Payment Purpose", CreateStandardText());
        GenJournalLine.Modify();
    end;

    local procedure InitVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; CVType: Option; IsPrepayment: Boolean; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VATLedgerLine.Init();
        VATLedgerLine."C/V Type" := CVType;
        VATLedgerLine.Prepayment := IsPrepayment;
        VATLedgerLine."Document Type" := DocumentType;
    end;

    local procedure ExecuteBankPaymentOrderReport(GenJournalLine: Record "Gen. Journal Line")
    var
        BankPaymentOrder: Report "Bank Payment Order";
    begin
        Commit();
        GenJournalLine.SetRecFilter();
        BankPaymentOrder.SetTableView(GenJournalLine);
        BankPaymentOrder.SetFileNameSilent(LibraryReportValidation.GetFileName());
        BankPaymentOrder.RunModal();
    end;

    local procedure CreateStandardText(): Text[250]
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Init();
        StandardText.Code := LibraryUtility.GenerateRandomCode(StandardText.FieldNo(Code), DATABASE::"Standard Text");
        StandardText.Description := LibraryUtility.GenerateGUID();
        StandardText.Insert();
        exit(StandardText.Description);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; NewName: Text[50]; NewName2: Text[50]; NewFullName: Text[50])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, NewName);
        Vendor.Validate("Name 2", NewName2);
        Vendor.Validate("Full Name", NewFullName);
        Vendor.Modify(true);
    end;

    local procedure CreateSalesDocWithDiffSellToShipToBillTo(var SalesHeader: Record "Sales Header"; var SellToCustomerNo: Code[20]; var ShipToCustomerNo: Code[20]; var BillToCustomerNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        ShipToCustomer: Record Customer;
    begin
        SellToCustomerNo := LibraryRUReports.CreateCustomerNo();
        LibraryRUReports.CreateCustomer(ShipToCustomer);
        ShipToCustomerNo := ShipToCustomer."No.";
        BillToCustomerNo := LibraryRUReports.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SellToCustomerNo);
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.Validate("Ship-to Post Code", ShipToCustomer."Post Code");
        SalesHeader.Validate("Ship-to Address", ShipToCustomer.Address);
        SalesHeader.Validate("Ship-to Address 2", ShipToCustomer."Address 2");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
    end;

    local procedure CreatePostSalesDocWithDiffSellToShipToBillTo(var SellToCustomerNo: Code[20]; var ShipToCustomerNo: Code[20]; var BillToCustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocWithDiffSellToShipToBillTo(
          SalesHeader, SellToCustomerNo, ShipToCustomerNo, BillToCustomerNo, DocumentType);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure MockSalesHeaderWithSevLines(var SalesLine: array[4] of Record "Sales Line"; CustomerNo: Code[20]; ShipToAddress: Code[10]; ItemNo: array[4] of Code[20]; LocationCode: array[4] of Code[10])
    var
        DocumentNo: Code[20];
        i: Integer;
    begin
        DocumentNo := LibraryVATLedger.MockSalesHeader(CustomerNo, ShipToAddress);
        for i := 1 to ArrayLen(SalesLine) do
            LibraryVATLedger.MockSalesLine(SalesLine[i], DocumentNo, ItemNo[i], LocationCode[i]);
    end;

    local procedure MockSalesInvWithSevLines(var SalesInvoiceLine: array[4] of Record "Sales Invoice Line"; CustomerNo: Code[20]; ShipToAddress: Code[10]; ItemNo: array[4] of Code[20]; LocationCode: array[4] of Code[10])
    var
        DocumentNo: Code[20];
        i: Integer;
    begin
        DocumentNo := LibraryVATLedger.MockSalesInvHeader(CustomerNo, ShipToAddress);
        for i := 1 to ArrayLen(SalesInvoiceLine) do
            LibraryVATLedger.MockSalesInvLine(SalesInvoiceLine[i], DocumentNo, ItemNo[i], LocationCode[i]);
    end;

    local procedure MockSalesCrMemoWithSevLines(var SalesCrMemoLine: array[4] of Record "Sales Cr.Memo Line"; CustomerNo: Code[20]; ShipToAddress: Code[10]; ItemNo: array[4] of Code[20]; LocationCode: array[4] of Code[10])
    var
        DocumentNo: Code[20];
        i: Integer;
    begin
        DocumentNo := LibraryVATLedger.MockSalesCrMemoHeader(CustomerNo, ShipToAddress);
        for i := 1 to ArrayLen(SalesCrMemoLine) do
            LibraryVATLedger.MockSalesCrMemoLine(SalesCrMemoLine[i], DocumentNo, ItemNo[i], LocationCode[i]);
    end;

    local procedure MockSevItemsAndLocations(var ItemNo: array[4] of Code[20]; var TariffNo: array[4] of Code[20]; var LocationCode: array[4] of Code[10])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(ItemNo) do begin
            TariffNo[i] := LibraryVATLedger.MockTariffNo();
            ItemNo[i] := LibraryVATLedger.MockItemNo(TariffNo[i]);
        end;
        LocationCode[1] := LibraryVATLedger.MockLocationEAEU();
        LocationCode[2] := LibraryVATLedger.MockLocationNonEAEU();
        LocationCode[3] := LibraryVATLedger.MockLocation('');
        LocationCode[4] := '';
    end;

    local procedure GenerateVATLedgerXMLFileName(VATLedgerType: Option; AddSheet: Boolean) Result: Text
    var
        CompanyInformation: Record "Company Information";
        VATLedger: Record "VAT Ledger";
    begin
        CompanyInformation.Get();
        Result := 'NO_NDS.';

        if VATLedgerType = VATLedger.Type::Sales then
            Result += Format(9)
        else
            Result += Format(8);

        if AddSheet then
            Result += Format(1);

        // Add "_AAAA_KKKK_" value, where AAAA - admin SONO, KKKK - recipient SONO
        Result += '_';
        if CompanyInformation."Admin. Tax Authority SONO" <> '' then
            Result += CompanyInformation."Admin. Tax Authority SONO"
        else
            Result += AAAATxt;
        Result += '_';
        if CompanyInformation."Recipient Tax Authority SONO" <> '' then
            Result += CompanyInformation."Recipient Tax Authority SONO"
        else
            Result += KKKKTxt;
        Result += '_';

        Result += Format(CompanyInformation."VAT Registration No."); // INN
        if StrLen(CompanyInformation."VAT Registration No.") = 10 then  // The company is an organization
            Result += Format(CompanyInformation."KPP Code");
        Result += '_' + Format(Today, 8, '<Year4><Month,2><Day,2>'); // Date format YYYYMMDD
        Result += '_05_08';
        Result += '_N'; // Iteration number; added to create unique file names
    end;

    local procedure SetCountryRegionAddressFormat(CountryRegionCode: Code[10]; AddressFormat: Option)
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        CountryRegion.Validate("Address Format", AddressFormat);
        CountryRegion.Modify(true);
    end;

    local procedure UpdateCompanyInformation(IsIndividualPerson: Boolean; SONOAdmin: Code[4]; SONOReceipt: Code[4])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if IsIndividualPerson then begin
            CompanyInformation."VAT Registration No." := CopyStr(LibraryUtility.GenerateRandomXMLText(12), 1, 12);
            CompanyInformation.Validate("KPP Code", '');
        end else begin
            CompanyInformation."VAT Registration No." := CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, 10);
            CompanyInformation.Validate("KPP Code", CopyStr(LibraryUtility.GenerateRandomXMLText(9), 1, 9));
        end;
        CompanyInformation."Admin. Tax Authority SONO" := SONOAdmin;
        CompanyInformation."Recipient Tax Authority SONO" := SONOReceipt;
        CompanyInformation.Modify();
    end;

    local procedure VerifyEAEUItemTariffNo_FourSalesLines(SalesLine: array[4] of Record "Sales Line"; ExpectedTariffNo1: Code[20]; ExpectedTariffNo2: Code[20]; ExpectedTariffNo3: Code[20]; ExpectedTariffNo4: Code[20])
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        Assert.AreEqual(ExpectedTariffNo1, LocalReportMgt.GetEAEUItemTariffNo_SalesLine(SalesLine[1]), '');
        Assert.AreEqual(ExpectedTariffNo2, LocalReportMgt.GetEAEUItemTariffNo_SalesLine(SalesLine[2]), '');
        Assert.AreEqual(ExpectedTariffNo3, LocalReportMgt.GetEAEUItemTariffNo_SalesLine(SalesLine[3]), '');
        Assert.AreEqual(ExpectedTariffNo4, LocalReportMgt.GetEAEUItemTariffNo_SalesLine(SalesLine[4]), '');
    end;

    local procedure VerifyEAEUItemTariffNo_FourSalesInvLines(SalesInvoiceLine: array[4] of Record "Sales Invoice Line"; ExpectedTariffNo1: Code[20]; ExpectedTariffNo2: Code[20]; ExpectedTariffNo3: Code[20]; ExpectedTariffNo4: Code[20])
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        Assert.AreEqual(ExpectedTariffNo1, LocalReportMgt.GetEAEUItemTariffNo_SalesInvLine(SalesInvoiceLine[1]), '');
        Assert.AreEqual(ExpectedTariffNo2, LocalReportMgt.GetEAEUItemTariffNo_SalesInvLine(SalesInvoiceLine[2]), '');
        Assert.AreEqual(ExpectedTariffNo3, LocalReportMgt.GetEAEUItemTariffNo_SalesInvLine(SalesInvoiceLine[3]), '');
        Assert.AreEqual(ExpectedTariffNo4, LocalReportMgt.GetEAEUItemTariffNo_SalesInvLine(SalesInvoiceLine[4]), '');
    end;

    local procedure VerifyEAEUItemTariffNo_FourSalesCrMemoLines(SalesCrMemoLine: array[4] of Record "Sales Cr.Memo Line"; ExpectedTariffNo1: Code[20]; ExpectedTariffNo2: Code[20]; ExpectedTariffNo3: Code[20]; ExpectedTariffNo4: Code[20])
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        Assert.AreEqual(ExpectedTariffNo1, LocalReportMgt.GetEAEUItemTariffNo_SalesCrMemoLine(SalesCrMemoLine[1]), '');
        Assert.AreEqual(ExpectedTariffNo2, LocalReportMgt.GetEAEUItemTariffNo_SalesCrMemoLine(SalesCrMemoLine[2]), '');
        Assert.AreEqual(ExpectedTariffNo3, LocalReportMgt.GetEAEUItemTariffNo_SalesCrMemoLine(SalesCrMemoLine[3]), '');
        Assert.AreEqual(ExpectedTariffNo4, LocalReportMgt.GetEAEUItemTariffNo_SalesCrMemoLine(SalesCrMemoLine[4]), '');
    end;

    local procedure VerifyEAEUItemTariffNo_FourValueEntries_SalesInvoice(SalesInvoiceLine: array[4] of Record "Sales Invoice Line"; IsEAEUItem1: Boolean; IsEAEUItem2: Boolean; IsEAEUItem3: Boolean; IsEAEUItem4: Boolean)
    var
        DummyValueEntry: Record "Value Entry";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        DummyValueEntry."Document Type" := DummyValueEntry."Document Type"::"Sales Invoice";
        Assert.AreEqual(
          IsEAEUItem1,
          LocalReportMgt.IsEAEUItem_ValueEntry(
            DummyValueEntry."Document Type", SalesInvoiceLine[1]."Document No.", SalesInvoiceLine[1]."Line No."),
          '');
        Assert.AreEqual(
          IsEAEUItem2,
          LocalReportMgt.IsEAEUItem_ValueEntry(
            DummyValueEntry."Document Type", SalesInvoiceLine[2]."Document No.", SalesInvoiceLine[2]."Line No."),
          '');
        Assert.AreEqual(
          IsEAEUItem3,
          LocalReportMgt.IsEAEUItem_ValueEntry(
            DummyValueEntry."Document Type", SalesInvoiceLine[3]."Document No.", SalesInvoiceLine[3]."Line No."),
          '');
        Assert.AreEqual(
          IsEAEUItem4,
          LocalReportMgt.IsEAEUItem_ValueEntry(
            DummyValueEntry."Document Type", SalesInvoiceLine[4]."Document No.", SalesInvoiceLine[4]."Line No."),
          '');
    end;

    local procedure VerifyEAEUItemTariffNo_FourValueEntries_SalesCrMemo(SalesCrMemoLine: array[4] of Record "Sales Cr.Memo Line"; IsEAEUItem1: Boolean; IsEAEUItem2: Boolean; IsEAEUItem3: Boolean; IsEAEUItem4: Boolean)
    var
        DummyValueEntry: Record "Value Entry";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        DummyValueEntry."Document Type" := DummyValueEntry."Document Type"::"Sales Credit Memo";
        Assert.AreEqual(
          IsEAEUItem1,
          LocalReportMgt.IsEAEUItem_ValueEntry(
            DummyValueEntry."Document Type", SalesCrMemoLine[1]."Document No.", SalesCrMemoLine[1]."Line No."),
          '');
        Assert.AreEqual(
          IsEAEUItem2,
          LocalReportMgt.IsEAEUItem_ValueEntry(
            DummyValueEntry."Document Type", SalesCrMemoLine[2]."Document No.", SalesCrMemoLine[2]."Line No."),
          '');
        Assert.AreEqual(
          IsEAEUItem3,
          LocalReportMgt.IsEAEUItem_ValueEntry(
            DummyValueEntry."Document Type", SalesCrMemoLine[3]."Document No.", SalesCrMemoLine[3]."Line No."),
          '');
        Assert.AreEqual(
          IsEAEUItem4,
          LocalReportMgt.IsEAEUItem_ValueEntry(
            DummyValueEntry."Document Type", SalesCrMemoLine[4]."Document No.", SalesCrMemoLine[4]."Line No."),
          '');
    end;

    local procedure VerifySalesDocDiffSellToShipToBillToAddress(RecordVariant: Variant; SellToCustomerNo: Code[20]; ShipToCustomerNo: Code[20]; BillToCustomerNo: Code[20])
    var
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        Assert.AreEqual(
          LibraryRUReports.GetCustomerFullAddress(SellToCustomerNo),
          LocalReportMgt.GetCustInfo(RecordVariant, 1, 0), '');
        Assert.AreEqual(
          LibraryRUReports.GetCustomerFullAddress(ShipToCustomerNo),
          LocalReportMgt.GetCustInfo(RecordVariant, 1, 1), '');
        Assert.AreEqual(
          LibraryRUReports.GetCustomerFullAddress(BillToCustomerNo),
          LocalReportMgt.GetCustInfo(RecordVariant, 1, 2), '');

        Assert.AreEqual(
          LocalReportMgt.GetCustInfo(RecordVariant, 0, 2) + ' ' +
          LocalReportMgt.GetCustInfo(RecordVariant, 1, 2) +
          LocalReportMgt.GetCustPhoneFax(SellToCustomerNo) +
          LocalReportMgt.GetCustBankAttrib(SellToCustomerNo, ''),
          LocalReportMgt.GetPayerInfo(RecordVariant, SellToCustomerNo, ''), '');

        Assert.AreEqual(
          LocalReportMgt.GetCustInfo(RecordVariant, 0, 1) + ' ' +
          LocalReportMgt.GetCustInfo(RecordVariant, 1, 1) +
          LocalReportMgt.GetCustPhoneFax(SellToCustomerNo) +
          LocalReportMgt.GetCustBankAttrib(SellToCustomerNo, ''),
          LocalReportMgt.GetConsigneeInfo(RecordVariant, SellToCustomerNo), '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankPaymentOrderHandler(var BankPaymentOrderReqPage: TestRequestPage "Bank Payment Order")
    var
        PaymentDocType: Option "Payment Order","Collection Payment Order","Payment Requisition";
    begin
        BankPaymentOrderReqPage.SetPreview.SetValue(true);
        BankPaymentOrderReqPage.PaymentDocType.SetValue(PaymentDocType::"Payment Order");
        BankPaymentOrderReqPage.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure CopyServerFileToTargetOnBeforeDownloadHandler(ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        FileManagement: Codeunit "File Management";
    begin
        // In containers the client-side Download does not materialize the exported report file at the
        // server session path the test reads, so copy the server-side source file to the target path.
        if (FromFileName = '') or (ToFileName = '') then
            exit;
        if not FileManagement.ServerFileExists(FromFileName) then
            exit;
        FileManagement.CopyServerFile(FromFileName, ToFileName, true);
        IsHandled := true;
    end;
}

