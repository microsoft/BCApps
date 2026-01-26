codeunit 144117 "ERM Make 349 Declaration"
{
    // // [FEATURE] [Make 349 Declaration]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        NoTaxableMgt: Codeunit "No Taxable Mgt.";
        FileManagement: Codeunit "File Management";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVariableStorageForMessages: Codeunit "Library - Variable Storage";
        LibraryVariableStorageForSpecifyCorrectionsConfirmHandler: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        DeliveryOperationCode: Option " ","E - General","M - Imported Tax Exempt","H - Imported Tax Exempt (Representative)";
        FileNotfoundErr: Label 'Could not find file';
        OriginalDeclaredAmountErr: Label '"Original declared Amount" cannot be high than "Previous Declared Amount"';
        ValueNotFoundMsg: Label 'Value not found.';
        ContactNameTxt: Label 'Contact Name';
        TelephoneNumberTxt: Label '123456789';
        MissingContactNameErr: Label 'Contact name must be entered.';
        MissingFiscalYearErr: Label 'Incorrect Fiscal Year.';
        MissingTelephoneNumberErr: Label 'Telephone Number must be 9 digits without spaces or special characters.';
        MissingDeclarationNumberErr: Label 'Lenght should be 13 digits for Declaration Number';
        MissingCountryRegionErr: Label 'Company Country/Region must be entered.';
        ESTxt: Label 'ES';
        EUCountryCodeTxt: Label 'DE';
        ReportIsEmptyMsg: Label 'The report is empty. File generation has been cancelled.';
        ReportExportedSuccessfullyMsg: Label '349 Declaration has been exported successfully under';
        CustomerVendorMsg: Label 'Please be aware that this file will contain posted entries of services transactions of EU Customers/Vendors if you did not fill ';
        IsInitialized: Boolean;
        SpecifyCorrectionsMsg: Label 'One or more Credit Memos were found for the specified period. \You can select the ones that require a correction entry in current declaration and specify the correction amount for them. \Would you like to specify these corrections?';
        NoCorrectionsWillBeIncludedMsg: Label 'No correction will be included in this declaration.';
        InvalidAccountNameErr: Label 'Account Name is invalide.';
        SecondLineNotFoundErr: Label 'Failed to find the second line';
        UnexpectedSecondLineErr: Label 'Line should not be exported';
        ExportedValueErr: Label 'Wrong exported value for %1';
        LineNotFoundErr: Label 'File line is not found';
        IncorrectValueErr: Label 'Incorrect value';
        ProcessAbortedErr: Label 'The process has been aborted. No file will be generated.';

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepWithVendVATRegistrationNoErr()
    var
        PostingDate: Date;
    begin
        // Test to verify error after run Make 349 Declaration Report for vendor with VAT Registration No. as blank.
        Initialize();
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate());
        Make349DeclarationReportWithVendorError(PostingDate, PostingDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepWithVendorPostingDateError()
    begin
        // Test to verify error after run Make 349 Declaration Report for vendor with different Posting Dates.
        Initialize();
        Make349DeclarationReportWithVendorError(
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()),
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));
    end;

    local procedure Make349DeclarationReportWithVendorError(PostingDate: Date; PostingDate2: Date)
    var
        Amount: Decimal;
    begin
        // Setup and Exercise.
        Amount := 0;
        asserterror Make349DeclarationReportWithPurchaseDocument(
            true, '', FileManagement.ServerTempFileName('.txt'), CreateCountryRegion(),
            PostingDate, PostingDate2, Amount);  // VATRegistrationNo as blank. Take random Dates. EU Service as True and EU 3 Party Trade as False.

        // Verify.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationReportWithCustPostingDateError()
    var
        CountryRegionCode: Code[10];
        Amount: Decimal;
    begin
        // Test to verify error after run Make 349 Declaration Report for Customer with different Posting Dates.

        // Setup and Exercise.
        Initialize();
        Amount := 0;
        CountryRegionCode := CreateCountryRegion();
        asserterror Make349DeclarationReportWithSalesDocument(
            true, false, LibraryERM.GenerateVATRegistrationNo(CountryRegionCode),
            FileManagement.ServerTempFileName('.txt'), CountryRegionCode,
            CalcDate('<' + Format(LibraryRandom.RandInt(2)) + 'M>', WorkDate()),
            CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()), Amount);  // Take random Dates. EU Service as True and EU 3 Party Trade as False.

        // Verify.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepWithCustVATRegistrationNoError()
    begin
        // Test to verify error after run Make 349 Declaration Report for Customer with VAT Registration No. as blank.
        Make349DeclarationReportWithCustomerError('', FileNotfoundErr, CreateCountryRegion());  // VATRegistrationNo as blank.
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349PageHandler,Make349DeclarationRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepWithCustOrigDeclaredAmtError()
    var
        CountryRegionCode: Code[10];
    begin
        // Test to verify error after run Make 349 Declaration Report for Customer with Original Declared Amount.
        CountryRegionCode := CreateCountryRegion();
        Make349DeclarationReportWithCustomerError(
          LibraryERM.GenerateVATRegistrationNo(CountryRegionCode), OriginalDeclaredAmountErr, CountryRegionCode);
    end;

    local procedure Make349DeclarationReportWithCustomerError(VATRegistrationNo: Text[20]; ErrorTxt: Text; CountryRegionCode: Code[10])
    var
        PostingDate: Date;
        Amount: Decimal;
    begin
        // Setup and Exercise.
        Initialize();
        Amount := 0;
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate());
        asserterror Make349DeclarationReportWithSalesDocument(
            true, false, VATRegistrationNo, FileManagement.ServerTempFileName('.txt'),
            CountryRegionCode, PostingDate, PostingDate, Amount);  // EU Service as True and EU 3 Party Trade as False.

        // Verify.
        Assert.ExpectedError(ErrorTxt);
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepWithVendorEUServiceAsTrue()
    begin
        // Test to verify error after run Make 349 Declaration Report for Vendor with EU Service as True.
        Make349DeclarationRepWithVendorEUService(true, 'I');  // I is explicitly used for Operation Code in Report 10710. EU Service as True.
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepWithVendorEUServiceAsFalse()
    begin
        // Test to verify error after run Make 349 Declaration Report for Vendor with EU Service as False.
        Make349DeclarationRepWithVendorEUService(false, 'A');  // A is explicitly used for Operation Code in Report 10710. EU Service as False.
    end;

    local procedure Make349DeclarationRepWithVendorEUService(EUService: Boolean; OperationCode: Text[1])
    var
        Vendor: Record Vendor;
        FileName: Text[1024];
        VendorNo: Code[20];
        CountryRegionCode: Code[10];
        PostingDate: Date;
        Amount: Decimal;
    begin
        // Test to verify error after run Make 349 Declaration Report for vendor with different Posting Dates.

        // Setup and Exercise.
        Initialize();

        SetRandomCompanyName();
        CountryRegionCode := CreateCountryRegion();
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate());
        FileName := FileManagement.ServerTempFileName('.txt');
        Amount := 0;
        VendorNo :=
          Make349DeclarationReportWithPurchaseDocument(
            EUService, LibraryERM.GenerateVATRegistrationNo(CountryRegionCode), FileName, CountryRegionCode, PostingDate, PostingDate, Amount);
        Vendor.Get(VendorNo);

        // Verify.
        VerifyValuesOnGeneratedTextFile(FileName, 133, OperationCode);  // Starting Position is 133.
        VerifyValuesOnGeneratedTextFile(FileName, 93, VendorNo);  // Starting Position is 93.

        // Verify: that the produced file gives the expected format.
        ValidateFormat349FileHeader(FileName, PostingDate, '', TelephoneNumberTxt, ContactNameTxt, true, ' ', '01');
        ValidateFormat349FileRecord(FileName, PostingDate, Vendor."No.", Vendor.Name, OperationCode, Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationReportWithMultipleEUCustomers()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        Customer: Record Customer;
        FileName: Text[1024];
        CountryRegionCode: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        Amount: Decimal;
    begin
        // Test to verify Make 349 Declaration Report with multiple EU Customers.

        // Setup: Create and post Sales Order with EU and Non-EU Customers.
        Initialize();
        SetRandomCompanyName();
        CreateVATPostingSetup(VATPostingSetup, false);  // EUService as False.
        CreateVATPostingSetup(VATPostingSetup2, true);  // EUService as True.
        CountryRegionCode := CreateCountryRegion();
        CustomerNo :=
          CreateCustomer(
            CountryRegionCode, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(CountryRegionCode));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        CreateAndPostSalesDocument(SalesLine."Document Type"::Invoice, CustomerNo, ItemNo, WorkDate(), true);  // EUThirdPartyTrade as True.
        Amount := CreateAndPostSalesDocument(SalesLine."Document Type"::Invoice, CustomerNo, ItemNo, WorkDate(), false);  // EUThirdPartyTrade as False.

        CustomerNo :=
          CreateCustomer(CountryRegionCode, VATPostingSetup2."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(CountryRegionCode));
        Customer.Get(CustomerNo);
        CreateAndPostSalesDocument(SalesLine."Document Type"::Invoice, CustomerNo,
          CreateItem(VATPostingSetup2."VAT Prod. Posting Group"), WorkDate(), false);  // EUThirdPartyTrade as False.

        // Exercise.
        FileName := RunMake349DeclarationWithDate(WorkDate());  // Opens Make349DeclarationRequestPageHandler.

        // Verify.
        VerifyValuesOnGeneratedTextFile(FileName, 133, 'E');  // E is explicitly used for Operation Code in Report 10710. Starting Position is 133.
        VerifyValuesOnGeneratedTextFile(FileName, 133, 'T');  // T is explicitly used for Operation Code in Report 10710. Starting Position is 133.
        VerifyValuesOnGeneratedTextFile(FileName, 133, 'S');  // S is explicitly used for Operation Code in Report 10710. Starting Position is 133.

        // Verify: that the produced file gives the expected format.
        ValidateFormat349FileHeader(FileName, WorkDate(), '', TelephoneNumberTxt, ContactNameTxt, true, ' ', '01');
        ValidateFormat349FileRecord(FileName, WorkDate(), Customer."No.", Customer.Name, 'E', Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationReportWithMultipleEUVendors()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        FileName: Text[1024];
        CountryRegionCode: Code[10];
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        // Test to verify Make 349 Declaration Report with multiple EU Vendors.

        // Setup: Create and post Purchase Order with EU and Non-EU Vendors.
        Initialize();

        SetRandomCompanyName();
        CreateVATPostingSetup(VATPostingSetup, true);   // EUService as True.
        FileName := FileManagement.ServerTempFileName('.txt');
        CreateVATPostingSetup(VATPostingSetup2, false);  // EUService as False.
        CountryRegionCode := CreateCountryRegion();
        CreateAndPostPurchaseDocument(
          PurchaseLine."Document Type"::Invoice, CreateVendor(CountryRegionCode, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(CountryRegionCode)), CreateItem(VATPostingSetup."VAT Prod. Posting Group"), WorkDate());
        VendorNo :=
          CreateVendor(CountryRegionCode, VATPostingSetup2."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(CountryRegionCode));
        Vendor.Get(VendorNo);
        Amount :=
          CreateAndPostPurchaseDocument(
            PurchaseLine."Document Type"::Invoice, VendorNo, CreateItem(VATPostingSetup2."VAT Prod. Posting Group"), WorkDate());

        // Exercise.
        FileName := RunMake349DeclarationWithDate(WorkDate());

        // Verify.
        VerifyValuesOnGeneratedTextFile(FileName, 133, 'A');  // A is explicitly used for Operation Code in Report 10710. Starting Position is 133.
        VerifyValuesOnGeneratedTextFile(FileName, 133, 'I');  // I is explicitly used for Operation Code in Report 10710. Starting Position is 133.

        // Verify: that the produced file gives the expected format.
        ValidateFormat349FileHeader(FileName, WorkDate(), '', TelephoneNumberTxt, ContactNameTxt, true, ' ', '01');
        ValidateFormat349FileRecord(FileName, WorkDate(), Vendor."No.", Vendor.Name, 'A', Amount);
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationReportWithCustomerEUThirdParty()
    begin
        // Test to verify Make 349 Declaration Report for Customer with EU3PartyTrade as True.
        Make349DeclarationReportWithCustomerEUService(false, true, 'T');  // T is explicitly used for Operation Code in Report 10710. EUService as False and EUThirdPartyTrade as True.
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationReportWithCustEUServiceAsFalse()
    begin
        // Test to verify Make 349 Declaration Report for Customer with EU Service as False.
        Make349DeclarationReportWithCustomerEUService(false, false, 'E');  // E is explicitly used for Operation Code in Report 10710. EUService and EUThirdPartyTrade as False.
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationReportWithCustEUServiceAsTrue()
    begin
        // Test to verify Make 349 Declaration Report for Customer with EU Service as True.
        Make349DeclarationReportWithCustomerEUService(true, false, 'S');  // S is explicitly used for Operation Code in Report 10710. EUService as True and EUThirdPartyTrade as False.
    end;

    local procedure Make349DeclarationReportWithCustomerEUService(EUService: Boolean; EUThirdPartyTrade: Boolean; ExpectedValue: Text[20])
    var
        Customer: Record Customer;
        FileName: Text[1024];
        CountryRegionCode: Code[10];
        PostingDate: Date;
        Amount: Decimal;
        CustomerNo: Code[20];
    begin
        // Setup and Exercise.
        Initialize();
        Amount := 0;
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate());
        FileName := FileManagement.ServerTempFileName('.txt');
        CountryRegionCode := CreateCountryRegion();
        CustomerNo :=
          Make349DeclarationReportWithSalesDocument(
            EUService, EUThirdPartyTrade, LibraryERM.GenerateVATRegistrationNo(CountryRegionCode),
            FileName, CountryRegionCode, PostingDate, PostingDate, Amount);
        Customer.Get(CustomerNo);

        // Verify.
        ValidateFormat349FileRecord(FileName, PostingDate, Customer."No.", Customer.Name, ExpectedValue, Amount);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithoutContactName()
    begin
        // Verify whether system throws error message when Contact Name is not filled in.
        RunMake349DeclarationReportWithoutMandatoryFilters(ESTxt, '', TelephoneNumberTxt, GenerateRandomCode(13),
          Date2DMY(WorkDate(), 3), MissingContactNameErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithoutFiscalYear()
    begin
        // Verify whether system throws error message when Fiscal Year is not filled in.
        RunMake349DeclarationReportWithoutMandatoryFilters(ESTxt, ContactNameTxt, TelephoneNumberTxt,
          GenerateRandomCode(13), '', MissingFiscalYearErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithoutTelephoneNumber()
    begin
        // Verify whether system throws error message when Telephone Number is not filled in.
        RunMake349DeclarationReportWithoutMandatoryFilters(ESTxt, ContactNameTxt, '', GenerateRandomCode(13),
          Date2DMY(WorkDate(), 3), MissingTelephoneNumberErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithoutDeclarationNumber()
    begin
        // Verify whether system throws error message when Declaration Number is not filled in.
        RunMake349DeclarationReportWithoutMandatoryFilters(ESTxt, ContactNameTxt, TelephoneNumberTxt, '             ',
          Date2DMY(WorkDate(), 3), MissingDeclarationNumberErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithoutCountryRegionCode()
    begin
        // Verify whether system throws error message when Declaration Number is not filled in.
        RunMake349DeclarationReportWithoutMandatoryFilters('', ContactNameTxt, TelephoneNumberTxt, GenerateRandomCode(13),
          Date2DMY(WorkDate(), 3), MissingCountryRegionErr);
    end;

    local procedure RunMake349DeclarationReportWithoutMandatoryFilters(CountryRegionCode: Code[10]; ContactName: Text[20]; TelephoneNumber: Text[9]; DeclarationNumber: Text; PostingDate: Variant; ExpectedError: Text[1024])
    begin
        // Setup: Setup Demo Data.
        Initialize();

        // Excercise: Run Make 349 declaration report.
        asserterror RunMake349DeclarationReport2('', CountryRegionCode, ContactName, TelephoneNumber, DeclarationNumber, PostingDate);

        // Verify: Program throws error.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationReportWithCustomersValidation()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        FileName: Text[1024];
        CountryRegionCode: Code[10];
        ItemNo: Code[20];
        DeclarationNumber: Text[1024];
        PostingDate: Date;
        CustomerNo: Code[20];
    begin
        // Test to verify Make 349 Declaration Report with multiple EU Customers.

        // Setup: Create and post Sales Order with EU and Non-EU Customers.
        Initialize();
        SetRandomCompanyName();

        CreateVATPostingSetup(VATPostingSetup, false);  // EUService as False.
        CreateVATPostingSetup(VATPostingSetup2, true);  // EUService as True.
        CountryRegionCode := CreateCountryRegion();
        CustomerNo :=
          CreateCustomer(
            CountryRegionCode, VATPostingSetup."VAT Bus. Posting Group", LibraryERM.GenerateVATRegistrationNo(CountryRegionCode));

        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        CreateAndPostSalesDocument(SalesLine."Document Type"::Invoice, CustomerNo, ItemNo, WorkDate(), true);  // EUThirdPartyTrade as True.
        CreateAndPostSalesDocument(SalesLine."Document Type"::Invoice, CustomerNo, ItemNo, WorkDate(), false);  // EUThirdPartyTrade as False.
        CustomerNo :=
          CreateCustomer(CountryRegionCode, VATPostingSetup2."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(CountryRegionCode));
        CreateAndPostSalesDocument(
          SalesLine."Document Type"::Invoice, CustomerNo,
          CreateItem(VATPostingSetup2."VAT Prod. Posting Group"), WorkDate(), false);  // EUThirdPartyTrade as False.

        FileName := FileManagement.ServerTempFileName('.txt');

        // Exercise.
        DeclarationNumber := GenerateRandomCode(13);
        PostingDate := WorkDate();
        RunMake349DeclarationReport2(FileName, CountryRegionCode, ContactNameTxt, TelephoneNumberTxt,
          DeclarationNumber, Date2DMY(PostingDate, 3));

        // Verify: that the produced file gives the expected Hearder format.
        ValidateFormat349FileHeader(FileName, PostingDate, DeclarationNumber, TelephoneNumberTxt, ContactNameTxt, false, 'T', '01');
    end;

    local procedure ValidateFormat349FileHeader(FileName: Text[1024]; PostingDate: Date; DeclarationNum: Text; TelephoneNumber: Text; ContactName: Text[50]; SkipRandomData: Boolean; Medium: Text; PeriodText: Text)
    var
        CompanyInfo: Record "Company Information";
        FiscalYear: Text;
        VatRegNo: Text[20];
        Line: Text[1024];
        CompanyName: Text[50];
        NoOfOperations: Integer;
        CorrectionAmount: Integer;
    begin
        // Read Header line
        Line := CopyStr(LibraryTextFileValidation.ReadLineWithEncoding(FileName, TextEncoding::Windows, 1), 1, MaxStrLen(Line));

        // Setup expected data
        CompanyInfo.Get();
        FiscalYear := Format(Date2DMY(PostingDate, 3));
        VatRegNo := PadStr(CompanyInfo."VAT Registration No.", 9, ' ');
        CompanyName := PadStr(UpperCase(CompanyInfo.Name), 40, ' ');
        ContactName := PadStr(UpperCase(ContactName), 40, ' ');

        // Validate header data
        Assert.AreEqual(StrLen(Line), 500, 'Header record has wrong length');
        Assert.AreEqual(ReadRecordFormat(Line), '1349', 'Header record has wrong format');
        Assert.AreEqual(ReadFiscalYear(Line), FiscalYear, 'Header record has wrong fiscal year');
        Assert.AreEqual(ReadVATRegNo(Line), VatRegNo, 'Header record has wrong VatRegNo');
        Assert.IsTrue(CompareFormattedText(ReadCompanyName(Line), CompanyName), 'Wrong Company Name');
        Assert.AreEqual(ReadMediumType(Line), Medium, 'Header record has wrong Medium');

        if not SkipRandomData then begin
            Assert.AreEqual(ReadTelephoneNumber(Line), TelephoneNumber, 'Header record has wrong Phone number');
            Assert.AreEqual(ReadContactName(Line), ContactName, 'Wrong Contact name');
            Assert.AreEqual(ReadDeclarationNumber(Line), PadStr(DeclarationNum, 13, '0'), 'Wrong Declaration number');
        end;
        Assert.AreEqual(ReadRecordPadding1(Line), PadStr('', 13, '0'), 'expected 13 zeros');
        Assert.AreEqual(ReadPeriodText(Line), PeriodText, 'Wrong period text');

        NoOfOperations := ReadNumberOfCompanies(Line);
        Assert.IsTrue(NoOfOperations >= 1, 'Wrong number of operations');
        CorrectionAmount := ReadTotalAmount(Line);
        Assert.IsTrue(CorrectionAmount >= 0, 'Total CorrectionAmount is wrong');
        Assert.AreEqual(ReadNoOfCorrections(Line), 0, 'Wrong number of corrections');
        Assert.AreEqual(ReadCorrectionAmount(Line), 0, 'Wrong number of correction amount');
    end;

    local procedure ValidateFormat349FileRecord(FileName: Text[1024]; PostingDate: Date; CustOrVendNo: Code[20]; ExpectedName: Text[100]; OperationsCode: Text; Amount: Decimal)
    var
        CompanyInfo: Record "Company Information";
        FiscalYear: Text;
        VatRegNo: Text[20];
        Line: Text[1024];
        EntryAmount: Integer;
    begin
        CompanyInfo.Get();
        FiscalYear := Format(Date2DMY(PostingDate, 3));
        VatRegNo := PadStr(CompanyInfo."VAT Registration No.", 9, ' ');

        // Validate Customer/Vendor Record
        Line := ReadLineWithCustomerOrVendor(FileName, CustOrVendNo, 0);
        Assert.AreNotEqual('', Line, 'Expected line was not found in report');
        Assert.AreEqual(StrLen(Line), 500, 'Record has wrong length');
        Assert.AreEqual(ReadRecordFormat(Line), '2349', 'Record has wrong format');
        Assert.AreEqual(ReadFiscalYear(Line), FiscalYear, 'Header record has wrong fiscal year');
        Assert.AreEqual(ReadVATRegNo(Line), VatRegNo, 'Header record has wrong VatRegNo');
        Assert.AreEqual(ReadRecordPadding2(Line), PadStr('', 58, ' '), 'expected 58 blanks');
        ExpectedName := CopyStr(PadStr(UpperCase(ExpectedName), 40, ' '), 1, MaxStrLen(ExpectedName));
        Assert.AreEqual(ReadEntryName(Line), ExpectedName, 'Wrong customer/vendor name');
        Assert.AreEqual(ReadOperationsCode(Line), OperationsCode, 'Wrong operations code');
        EntryAmount := ReadEntryAmount(Line);
        if Amount < 0 then
            Assert.IsTrue(EntryAmount > 0, 'Entry Amount shoule be greater than 0')
        else
            Assert.AreEqual(Amount * 100, EntryAmount, 'Amount is wrong');
    end;

    local procedure ReadLineWithCustomerOrVendor(FileName: Text[1024]; CustOrVendNo: Text[1024]; ShiftLine: Integer): Text[500]
    var
        LineNo: Integer;
        PaddedCustOrVendNo: Text[1024];
    begin
        // Search in the file
        PaddedCustOrVendNo := PadCustVendNo(CustOrVendNo);
        LineNo := LibraryTextFileValidation.FindLineNoWithValue(FileName, 93, 40, PaddedCustOrVendNo, 1);
        if LineNo = 0 then
            exit('');
        LineNo += ShiftLine;

        exit(LibraryTextFileValidation.ReadLine(FileName, LineNo));
    end;

    local procedure PadCustVendNo(CustOrVendNo: Code[1024]): Text[1024]
    begin
        exit(PadStr(UpperCase(CustOrVendNo), 40, ' '));
    end;

    local procedure ReadRecordFormat(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 1, 4));
    end;

    local procedure ReadFiscalYear(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 5, 4));
    end;

    local procedure ReadVATRegNo(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 9, 9));
    end;

    local procedure ReadCompanyName(Line: Text[1024]): Text[50]
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 18, 40));
    end;

    local procedure ReadMediumType(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 58, 1));
    end;

    local procedure ReadTelephoneNumber(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 59, 9));
    end;

    local procedure ReadContactName(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 68, 40));
    end;

    local procedure ReadDeclarationNumber(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 108, 13));
    end;

    local procedure ReadPeriodText(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 136, 2));
    end;

    local procedure ReadNumberOfCompanies(Line: Text[1024]): Integer
    var
        NoOfCompanies: Integer;
    begin
        Evaluate(NoOfCompanies, LibraryTextFileValidation.ReadValue(Line, 138, 9));
        exit(NoOfCompanies);
    end;

    local procedure ReadTotalAmount(Line: Text[1024]): Integer
    var
        TotalAmount: Integer;
    begin
        Evaluate(TotalAmount, LibraryTextFileValidation.ReadValue(Line, 147, 15));
        exit(TotalAmount);
    end;

    local procedure ReadNoOfCorrections(Line: Text[1024]): Integer
    var
        TotalAmount: Integer;
    begin
        Evaluate(TotalAmount, LibraryTextFileValidation.ReadValue(Line, 162, 9));
        exit(TotalAmount);
    end;

    local procedure ReadCorrectionAmount(Line: Text[1024]): Integer
    var
        TotalAmount: Integer;
    begin
        Evaluate(TotalAmount, LibraryTextFileValidation.ReadValue(Line, 171, 15));
        exit(TotalAmount);
    end;

    local procedure ReadRecordPadding1(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 123, 13));
    end;

    local procedure ReadEntryName(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 93, 40));
    end;

    local procedure ReadOperationsCode(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 133, 1));
    end;

    local procedure ReadEntryAmount(Line: Text[1024]): Integer
    var
        EntryAmount: Integer;
    begin
        Evaluate(EntryAmount, LibraryTextFileValidation.ReadValue(Line, 134, 13));
        exit(EntryAmount);
    end;

    local procedure ReadEntryAmountCustomPosition(Line: Text[1024]; Position: Integer): Integer
    var
        EntryAmount: Integer;
    begin
        Evaluate(EntryAmount, LibraryTextFileValidation.ReadValue(Line, Position, 13));
        exit(EntryAmount);
    end;

    local procedure ReadRecordPadding2(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 18, 58));
    end;

    [Test]
    [HandlerFunctions('GLAccSelectionHandler')]
    [Scope('OnPrem')]
    procedure VerifyGLAccountMaxNameSelection()
    var
        GLAccSelection: Page "G/L Account Selection";
        AccountNo: Code[20];
        AccountName: Text[50];
    begin
        // SETUP
        Initialize();
        AccountNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(AccountNo));
        AccountName := PadStr('', MaxStrLen(AccountName), 'X');
        LibraryVariableStorage.Enqueue(AccountName);

        // EXERSIZE & VERIFY (verification inside the handler)
        GLAccSelection.InsertGLAccSelBuf(false, AccountNo, AccountName);
        GLAccSelection.RunModal();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationNationalPurchNoVAT()
    var
        CompanyInformation: Record "Company Information";
        VendorNo: Code[20];
        PostingDate: Date;
        Amount: Decimal;
    begin
        // [SCENARIO 120669] National Purchase Invoices with Non-Taxable VAT should not be exported
        Initialize();

        // [GIVEN] Create and Post Purchase Invoce for National Vendor with No Taxable VAT Posting Setup
        CompanyInformation.Get();
        CreateAndPostPurchInvoiceNoTax(CompanyInformation."Country/Region Code", VendorNo, Amount, PostingDate);

        // [WHEN] Run 349 Declaration
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [THEN] No any records should be exported.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationNationalSalesNoVAT()
    var
        CustomerNo: Code[20];
        PostingDate: Date;
        SalesAmount: Decimal;
    begin
        // [SCENARIO 121704] National Sales Invoice with Non-Taxable VAT not exported
        Initialize();

        // [GIVEN] Sales Document for National Customer with "No Taxable VAT" and "EU Service" = FALSE
        CreateAndPostSalesInvoiceNoTaxForNationalCustomer(false, CustomerNo, SalesAmount, PostingDate);

        // [WHEN] Run 349 Declaration
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Report has not generated the file.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationNationalSalesNoVATEUService()
    var
        CustomerNo: Code[20];
        PostingDate: Date;
        SalesAmount: Decimal;
    begin
        // [SCENARIO 121704] National Sales Invoice with Non-Taxable VAT not exported for EU Service
        Initialize();

        // [GIVEN] Sales Document for National Customer with "No Taxable VAT" and "EU Service" = TRUE
        CreateAndPostSalesInvoiceNoTaxForNationalCustomer(true, CustomerNo, SalesAmount, PostingDate);

        // [WHEN] Run 349 Declaration
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Report has not generated the file.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationForeignSalesNoVAT()
    var
        CustomerNo: Code[20];
        PostingDate: Date;
        FileName: Text[1024];
        SalesAmount: Decimal;
    begin
        // [SCENARIO 121704] Foreign Sales Invoice with Non-Taxable VAT is exported
        Initialize();

        // [GIVEN] Sales Document for Foreing Customer with NoTaxable Amount = "X"  and "EU Service" = FALSE
        CreateAndPostSalesInvoiceNoTax(CreateCountryRegion(), false, CustomerNo, SalesAmount, PostingDate);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Invoice's data is exported with NoTaxable Amount = "X"
        ValidateFormat349FileRecord(FileName, PostingDate, CustomerNo, CustomerNo, 'E', SalesAmount);

        TearDownSalesInvLine(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationForeignSalesNoVATSameVatRegNo()
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
        PostingDate: Date;
        FileName: Text[1024];
        SalesAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT]
        // [SCENARIO 448833] Foreign Sales Invoice with Non-Taxable VAT when two customers have same VAT Registration No.
        Initialize();

        // [GIVEN] Sales Document for Foreing Customer with NoTaxable Amount = "X"  and "EU Service" = FALSE
        CreateAndPostSalesInvoiceNoTax(CreateCountryRegion(), false, CustomerNo, SalesAmount, PostingDate);
        // [GIVEN] One more customer with same VAT Registration No. exists
        Customer.GET(CustomerNo);
        Customer.GET(
          CreateCustomer(
            Customer."Country/Region Code", Customer."VAT Bus. Posting Group",
            Customer."VAT Registration No."));

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Invoice's data is exported with NoTaxable Amount = "X"
        ValidateFormat349FileRecord(FileName, PostingDate, Customer."No.", Customer."No.", 'E', SalesAmount);

        TearDownSalesInvLine(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationForeignSalesNormalVAT_LocalNonEUContry()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
        CountryRegionOld: Record "Country/Region";
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // [SCENARIO 432910] "Make 349 Declaration" report does not export VAT Entries when the report runs for Country without "EU Country/Region Code"
        Initialize();

        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        CountryRegionOld.Copy(CountryRegion);
        CountryRegion."EU Country/Region Code" := '';
        CountryRegion.Modify();

        Customer.Get(CreateForeignCustomerWithVATRegNo(CreateCountryWithSpecificVATRegNoFormat(true)));

        CreateAndPostSalesInvoice(Customer."No.");

        asserterror RunMake349DeclarationWithDate(WorkDate());

        Assert.ExpectedError(FileNotfoundErr);

        CountryRegion.Find();
        CountryRegion."EU Country/Region Code" := CountryRegionOld."EU Country/Region Code";
        CountryRegion.Modify();
        TearDownSalesInvLine(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationForeignSalesNoVAT_LocalNonEUContry()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
        CountryRegionOld: Record "Country/Region";
        CustomerNo: Code[20];
        PostingDate: Date;
        SalesAmount: Decimal;
    begin
        // [SCENARIO 432910] "Make 349 Declaration" report does not export Non Taxable Entries when the report runs for Country without "EU Country/Region Code"
        Initialize();

        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        CountryRegionOld.Copy(CountryRegion);
        CountryRegion."EU Country/Region Code" := '';
        CountryRegion.Modify();

        CreateAndPostSalesInvoiceNoTax(CreateCountryRegion(), false, CustomerNo, SalesAmount, PostingDate);

        asserterror RunMake349DeclarationWithDate(PostingDate);

        Assert.ExpectedError(FileNotfoundErr);

        CountryRegion.Find();
        CountryRegion."EU Country/Region Code" := CountryRegionOld."EU Country/Region Code";
        CountryRegion.Modify();
        TearDownSalesInvLine(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationForeignSalesNoVATEUService()
    var
        CustomerNo: Code[20];
        PostingDate: Date;
        FileName: Text[1024];
        SalesAmount: Decimal;
    begin
        // [SCENARIO 121704] Foreign Sales Invoice with Non-Taxable VAT is exported with EU Service is TRUE
        Initialize();

        // [GIVEN] Sales Document for Foreing Customer with NoTaxable Amount = "X" and "EU Service" = TRUE
        CreateAndPostSalesInvoiceNoTax(CreateCountryRegion(), true, CustomerNo, SalesAmount, PostingDate);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Invoice's data is exported with NoTaxable Amount = "X"
        ValidateFormat349FileRecord(FileName, PostingDate, CustomerNo, CustomerNo, 'S', SalesAmount);

        TearDownSalesInvLine(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationForeignSalesNoVATEUServiceSameVATRegNo()
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
        PostingDate: Date;
        FileName: Text[1024];
        SalesAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT]
        // [SCENARIO 448833] Foreign Sales Invoice with Non-Taxable VAT and EU Service is TRUE when two customers have same VAT Registration No.
        Initialize();

        // [GIVEN] Sales Document for Foreing Customer with NoTaxable Amount = "X" and "EU Service" = TRUE
        CreateAndPostSalesInvoiceNoTax(CreateCountryRegion(), true, CustomerNo, SalesAmount, PostingDate);
        // [GIVEN] One more customer with same VAT Registration No. exists
        Customer.GET(CustomerNo);
        Customer.GET(
          CreateCustomer(
            Customer."Country/Region Code", Customer."VAT Bus. Posting Group",
            Customer."VAT Registration No."));

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Invoice's data is exported with NoTaxable Amount = "X"
        ValidateFormat349FileRecord(FileName, PostingDate, Customer."No.", Customer."No.", 'S', SalesAmount);

        TearDownSalesInvLine(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LineCustVATRegNoWithCountryCodePrefix()
    var
        Customer: Record Customer;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378817] Customer's VAT Registration number part of file does not contain extra country code prefix in case VAT Registration number has country prefix
        Initialize();

        // [GIVEN] Country with EU Country/Region Code and VAT Registration number of XX######### format
        // [GIVEN] Foreign customer with VAT Registration number of created format
        Customer.Get(CreateForeignCustomerWithVATRegNo(CreateCountryWithSpecificVATRegNoFormat(true)));

        // [GIVEN] Sales invoice posted
        CreateAndPostSalesInvoice(Customer."No.");

        // [WHEN] Run Make 349 Declaration
        ExportFileName := RunMake349DeclarationWithDate(WorkDate());

        // [THEN] VAT Registration field part = country prefix + digital part of Customer."VAT Registration No."
        VerifyCounterpartyLineVATRegNo(
          Customer.Name,
          Customer."VAT Registration No.",
          Customer."Country/Region Code",
          true,
          ExportFileName);
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LineCustVATRegNoWithoutCountryCodePrefix()
    var
        Customer: Record Customer;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378817] Customer's VAT Registration number part of file does not contain extra country code prefix in case VAT Registration number does not have country prefix
        Initialize();

        // [GIVEN] Country with EU Country/Region Code and VAT Registration number of ######### format
        // [GIVEN] Foreign customer with VAT Registration number of created format
        Customer.Get(CreateForeignCustomerWithVATRegNo(CreateCountryWithSpecificVATRegNoFormat(false)));

        // [GIVEN] Sales invoice posted
        CreateAndPostSalesInvoice(Customer."No.");

        // [WHEN] Run Make 349 Declaration
        ExportFileName := RunMake349DeclarationWithDate(WorkDate());

        // [THEN] VAT Registration field part = country prefix + digital part of Customer."VAT Registration No."
        VerifyCounterpartyLineVATRegNo(
          Customer.Name,
          Customer."VAT Registration No.",
          Customer."Country/Region Code",
          false,
          ExportFileName);
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LineVendVATRegNoWithCountryCodePrefix()
    var
        Vendor: Record Vendor;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378817] Vendor's VAT Registration number part of file does not contain extra country code prefix in case VAT Registration number has country prefix
        Initialize();

        // [GIVEN] Country with EU Country/Region Code and VAT Registration number of XX######### format
        // [GIVEN] Foreign vendor with VAT Registration number of created format
        Vendor.Get(
          CreateForeignVendorWithVATRegNo(
            CreateCountryWithSpecificVATRegNoFormat(true)));

        // [GIVEN] Purchase invoice posted
        CreateAndPostPurchaseInvoice(Vendor."No.");

        // [WHEN] Run Make 349 Declaration
        ExportFileName := RunMake349DeclarationWithDate(WorkDate());

        // [THEN] VAT Registration field part = country prefix + digital part of Vendor."VAT Registration No."
        VerifyCounterpartyLineVATRegNo(
          Vendor.Name,
          Vendor."VAT Registration No.",
          Vendor."Country/Region Code",
          true,
          ExportFileName);
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LineVendVATRegNoWithoutCountryCodePrefix()
    var
        Vendor: Record Vendor;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378817] Vendor's VAT Registration number part of file does not contain extra country code prefix in case VAT Registration number does not have country prefix
        Initialize();

        // [GIVEN] Country with EU Country/Region Code and VAT Registration number of ######### format
        // [GIVEN] Foreign vendor with VAT Registration number of created format
        Vendor.Get(
          CreateForeignVendorWithVATRegNo(
            CreateCountryWithSpecificVATRegNoFormat(false)));

        // [GIVEN] Purchase invoice posted
        CreateAndPostPurchaseInvoice(Vendor."No.");

        // [WHEN] Run Make 349 Declaration
        ExportFileName := RunMake349DeclarationWithDate(WorkDate());

        // [THEN] VAT Registration field part = country prefix + digital part of Vendor."VAT Registration No."
        VerifyCounterpartyLineVATRegNo(
          Vendor.Name,
          Vendor."VAT Registration No.",
          Vendor."Country/Region Code",
          false,
          ExportFileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLimitedLongVATRegNoWithoutCountryCodePrefix()
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378817] Unit test for CountryRegion.GetVATRegistrationNoLimitedBySetup when VATRegNo is longer than CountryRegion."VAT Registration No. digits" and no country prefix
        Initialize();

        // [GIVEN] Country with EU Country/Region Code and "VAT Registration No. digits" = 9
        MockEUCountry(CountryRegion, 9);

        // [GIVEN] VAT Registration No. 11 digits "12345678901"
        VATRegistrationNo := '12345678901';

        // [WHEN] Run function CountryRegion.GetVATRegistrationNoLimitedBySetup
        // [THEN] It returns "123456789"
        Assert.AreEqual('123456789', CountryRegion.GetVATRegistrationNoLimitedBySetup(VATRegistrationNo), IncorrectValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLimitedLongVATRegNoWithCountryCodePrefix()
    var
        CountryRegion: Record "Country/Region";
        VATRegistrationNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378817] Unit test for CountryRegion.GetVATRegistrationNoLimitedBySetup when VATRegNo is longer than CountryRegion."VAT Registration No. digits" and has country prefix
        Initialize();

        // [GIVEN] Country with EU Country/Region Code and "VAT Registration No. digits" = 9
        MockEUCountry(CountryRegion, 9);

        // [GIVEN] VAT Registration No. 11 digits and country prefix "GU12345678901"
        VATRegistrationNo := 'GU12345678901';

        // [WHEN] Run function CountryRegion.GetVATRegistrationNoLimitedBySetup
        // [THEN] It returns "GU123456789"
        Assert.AreEqual('GU123456789', CountryRegion.GetVATRegistrationNoLimitedBySetup(VATRegistrationNo), IncorrectValueErr);
    end;

    local procedure RunReportForCustomerAndWithDifferentAddresses(CustomerCode: Code[10]; ShipToCountryRegionCode: Code[10]; LocationCode: Code[10]; GeneratesReport: Boolean)
    var
        Location: Record Location;
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        FiscalYear: Date;
        ShipToAddressCode: Code[10];
        FileName: Text[1024];
    begin
        // Setup
        Initialize();

        // Setup new location
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Country/Region Code", LocationCode);
        Location.Modify();

        // Create GL account
        LibraryERM.CreateGLAccount(GLAccount);

        // Setup inventory posting setup
        InventoryPostingGroup.FindLast();
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);
        InventoryPostingSetup.Validate("Inventory Account", GLAccount."No.");
        InventoryPostingSetup.Modify(true);

        // Create new customer with given code
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CustomerCode);
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CustomerCode));
        Customer.Modify(true);
        AssignPaymentTermsToCustomer(Customer."No.");

        // Add Ship-To Address for the customer
        ShipToAddressCode := '';
        if ShipToCountryRegionCode <> '' then begin
            LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
            ShipToAddress.Validate("Country/Region Code", ShipToCountryRegionCode);
            ShipToAddress.Modify(true);
            ShipToAddressCode := ShipToAddress.Code;
        end;

        // Create and post sales invoice
        FiscalYear := GetNewWorkDate();
        CreateAndPostSalesInvoiceWithShippingAndLocationCode(Customer."No.", InventoryPostingGroup.Code,
          FiscalYear, Location.Code, ShipToAddressCode, false);
        FileName := '';

        // Exercise: run the report
        if not GeneratesReport then begin
            LibraryVariableStorageForMessages.Enqueue(CustomerVendorMsg);
            LibraryVariableStorageForMessages.Enqueue(ReportIsEmptyMsg);
        end else begin
            LibraryVariableStorageForMessages.Enqueue(CustomerVendorMsg);
            LibraryVariableStorageForMessages.Enqueue(ReportExportedSuccessfullyMsg);
            FileName := FileManagement.ServerTempFileName('.txt');
        end;

        RunMake349DeclarationReport2(FileName, 'ES', ContactNameTxt, TelephoneNumberTxt,
          '3490000000000', Date2DMY(FiscalYear, 3));

        // Validate: Check that we got the right no of messages
        Assert.AreEqual(0, LibraryVariableStorageForMessages.Length(), 'We expected messages, but did not get them all.');
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESCustomerShippingAddressBlankLocationCodeNonEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('ES', '', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESCustomerShippingAddressBlankLocationCodeES()
    begin
        RunReportForCustomerAndWithDifferentAddresses('ES', '', 'ES', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESCustomerShippingAddressEULocationCodeNonEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('ES', 'DE', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESCustomerShippingAddressNonEULocationCodeES()
    begin
        RunReportForCustomerAndWithDifferentAddresses('ES', 'JP', 'ES', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESCustomerShippingAddressNonEULocationCodeEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('ES', 'JP', 'DE', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESCustomerShippingAddressIsESLocationCodeEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('ES', 'ES', 'DE', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESCustomerShippingAddressNonEULocationCodeNonEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('ES', 'JP', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestDECustomerShippingAddressIsESLocationCodeES()
    begin
        // TFS ID 403106: Foreign customer with shipping address in Spain must be reported in the 349 Declaration for Spain
        RunReportForCustomerAndWithDifferentAddresses('DE', 'ES', 'ES', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestDECustomerShippingAddressIsEULocationCodeES()
    begin
        RunReportForCustomerAndWithDifferentAddresses('DE', 'DE', 'ES', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestDECustomerShippingAddressIsESLocationCodeNonEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('DE', 'ES', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestDECustomerShippingAddressBlankLocationCodeNonEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('DE', '', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestDECustomerShippingAddressNonEULocationCodeNonEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('DE', 'JP', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestDECustomerShippingAddressNonEULocationCodeES()
    begin
        RunReportForCustomerAndWithDifferentAddresses('DE', 'JP', 'ES', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestDECustomerShippingAddressNonEULocationCodeEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('DE', 'JP', 'DE', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestDECustomerShippingAddressIsEULocationCodeEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('DE', 'DE', 'DE', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestFRCustomerShippingAddressIsESLocationCodeES()
    begin
        // TFS ID 403106: Foreign customer with shipping address in Spain must be reported in the 349 Declaration for Spain
        // TFS ID 454631: Only european union countries must be reported in the 349 Declaration for Spain
        RunReportForCustomerAndWithDifferentAddresses('FR', 'ES', 'ES', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestMACustomerShippingAddressIsESLocationCodeES()
    begin
        // TFS ID 454631: Only european union countries must be reported in the 349 Declaration for Spain
        RunReportForCustomerAndWithDifferentAddresses('MA', 'ES', 'ES', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestMACustomerShippingAddressIsEULocationCodeES()
    begin
        RunReportForCustomerAndWithDifferentAddresses('MA', 'DE', 'ES', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestMACustomerShippingAddressNonEULocationCodeES()
    begin
        RunReportForCustomerAndWithDifferentAddresses('MA', 'MA', 'ES', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestMACustomerShippingAddressIsEULocationCodeNonEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('MA', 'DE', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestMACustomerShippingAddressIsBlankLocationCodeES()
    begin
        RunReportForCustomerAndWithDifferentAddresses('MA', '', 'ES', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestMACustomerShippingAddressIsBlankLocationCodeEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('MA', '', 'DE', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestMACustomerShippingAddressIsBlankLocationCodeNonEU()
    begin
        RunReportForCustomerAndWithDifferentAddresses('MA', 'ES', 'JP', false);
    end;

    local procedure RunReporForVendorAndtWithDifferentAddresses(VendorCountryCode: Code[10]; OrderAddressCountryRegionCode: Code[10]; LocationCode: Code[10]; GeneratesReport: Boolean)
    var
        Location: Record Location;
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
        Vendor: Record Vendor;
        OrderAddress: Record "Order Address";
        FiscalYear: Date;
        OrderAddressCode: Code[10];
        FileName: Text[1024];
    begin
        // Setup
        Initialize();

        // Setup new location
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Country/Region Code", LocationCode);
        Location.Modify();

        // Create GL account
        LibraryERM.CreateGLAccount(GLAccount);

        // Setup inventory posting setup
        InventoryPostingGroup.FindLast();
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);
        InventoryPostingSetup.Validate("Inventory Account", GLAccount."No.");
        InventoryPostingSetup.Modify(true);

        // Create new vendor with given code
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", VendorCountryCode);
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(VendorCountryCode));
        Vendor.Modify(true);
        AssignPaymentTermsToVendor(Vendor."No.");

        // Add Order Address for the vendor
        OrderAddressCode := '';
        if OrderAddressCountryRegionCode <> '' then begin
            LibraryPurchase.CreateOrderAddress(OrderAddress, Vendor."No.");
            OrderAddress.Validate("Country/Region Code", OrderAddressCountryRegionCode);
            OrderAddress.Modify(true);
            OrderAddressCode := OrderAddress.Code;
        end;

        // Create and post purchase invoice
        FiscalYear := GetNewWorkDate();
        CreateAndPostPurchaseInvoiceWithOrderAddressAndLocationCode(Vendor."No.", InventoryPostingGroup.Code,
          FiscalYear, Location.Code, OrderAddressCode);

        FileName := '';

        // Exercise: run the report
        if not GeneratesReport then begin
            LibraryVariableStorageForMessages.Enqueue(CustomerVendorMsg);
            LibraryVariableStorageForMessages.Enqueue(ReportIsEmptyMsg);
        end else begin
            LibraryVariableStorageForMessages.Enqueue(CustomerVendorMsg);
            LibraryVariableStorageForMessages.Enqueue(ReportExportedSuccessfullyMsg);
            FileName := FileManagement.ServerTempFileName('.txt');
        end;

        RunMake349DeclarationReport2(FileName, 'ES', ContactNameTxt, TelephoneNumberTxt,
          '3490000000000', Date2DMY(FiscalYear, 3));

        // Validate: Check that we got the right no of messages
        Assert.AreEqual(0, LibraryVariableStorageForMessages.Length(), 'We expected messages, but did not get them all.');
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESVendorOrderAddressBlankLocationCodeES()
    begin
        RunReporForVendorAndtWithDifferentAddresses('ES', '', 'ES', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESVendorOrderAddressBlankLocationCodeDE()
    begin
        RunReporForVendorAndtWithDifferentAddresses('ES', '', 'DE', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESVendorOrderAddressBlankLocationCodeJP()
    begin
        RunReporForVendorAndtWithDifferentAddresses('ES', '', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESVendorOrderAddressDELocationCodeES()
    begin
        RunReporForVendorAndtWithDifferentAddresses('ES', 'DE', 'ES', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESVendorOrderAddressDELocationCodeDE()
    begin
        RunReporForVendorAndtWithDifferentAddresses('ES', 'DE', 'DE', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESVendorOrderAddressDELocationCodeJP()
    begin
        RunReporForVendorAndtWithDifferentAddresses('ES', 'DE', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESVendorOrderAddressESLocationCodeES()
    begin
        RunReporForVendorAndtWithDifferentAddresses('ES', 'ES', 'ES', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESVendorOrderAddressNonEULocationCodeDE()
    begin
        RunReporForVendorAndtWithDifferentAddresses('ES', 'JP', 'DE', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestESVendorOrderAddressNonEULocationCodeJP()
    begin
        RunReporForVendorAndtWithDifferentAddresses('ES', 'JP', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestEUVendorOrderAddressESLocationCodeDE()
    begin
        // TFS ID 403106: Foreign customer with shipping address in Spain must be reported in the 349 Declaration for Spain
        RunReporForVendorAndtWithDifferentAddresses('DE', 'ES', 'DE', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestEUVendorOrderAddressESLocationCodeES()
    begin
        // TFS ID 403106: Foreign customer with shipping address in Spain must be reported in the 349 Declaration for Spain
        RunReporForVendorAndtWithDifferentAddresses('DE', 'ES', 'ES', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestEUVendorOrderAddressESLocationCodeJP()
    begin
        RunReporForVendorAndtWithDifferentAddresses('DE', 'ES', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestEUVendorOrderAddressBlankLocationCodeES()
    begin
        RunReporForVendorAndtWithDifferentAddresses('DE', '', 'ES', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestEUVendorOrderAddressBlankLocationCodeDE()
    begin
        RunReporForVendorAndtWithDifferentAddresses('DE', '', 'DE', true);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestEUVendorOrderAddressBlankLocationCodeJP()
    begin
        RunReporForVendorAndtWithDifferentAddresses('DE', '', 'JP', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestEUVendorOrderAddressNotESLocationCodeDE()
    begin
        RunReporForVendorAndtWithDifferentAddresses('DE', 'JP', 'DE', false);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler')]
    [Scope('OnPrem')]
    procedure TestEUVendorOrderAddressJPLocationCodeJP()
    begin
        RunReporForVendorAndtWithDifferentAddresses('DE', 'JP', 'JP', false);
    end;

    local procedure RunReportForCustomerWithCreditMemoCorrection(var FileName: Text[1024]; var LineNo: array[2] of Integer; var SalesInvoiceAmt: Decimal; var SalesCrMemoAmt: Decimal; OriginalDeclarationFYDelta: Integer; EUThirdPartyTrade: Boolean)
    var
        Location: Record Location;
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
        Customer: Record Customer;
        InvoicePostingDate: Date;
        CrMemoPostingDate: Date;
        SalesDocNo: Code[20];
        OriginalDeclarationFY: Code[4];
    begin
        Initialize();

        // Setup new location
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Country/Region Code", ESTxt);
        Location.Modify();

        // Create GL account
        LibraryERM.CreateGLAccount(GLAccount);

        // Setup inventory posting setup
        InventoryPostingGroup.FindLast();
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);
        InventoryPostingSetup.Validate("Inventory Account", GLAccount."No.");
        InventoryPostingSetup.Modify(true);

        // Create new customer with given country
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", EUCountryCodeTxt);
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        Customer.Modify(true);
        AssignPaymentTermsToCustomer(Customer."No.");

        CrMemoPostingDate := GetNewWorkDate();
        InvoicePostingDate := CalcDate(StrSubstNo('<%1Y>', OriginalDeclarationFYDelta), CrMemoPostingDate);

        // Create and post sales invoice
        SalesDocNo := CreateAndPostSalesInvoiceWithShippingAndLocationCode(Customer."No.", InventoryPostingGroup.Code,
            InvoicePostingDate, Location.Code, '', EUThirdPartyTrade);
        SalesInvoiceAmt := GetSalesInvoiceDocAmount(SalesDocNo);

        // Create and post credit memo for the sales invoice
        SalesDocNo := CreateAndPostSalesCreditMemo(Customer."No.", SalesDocNo, CrMemoPostingDate, EUThirdPartyTrade);
        SalesCrMemoAmt := GetSalesCrMemoDocAmount(SalesDocNo);

        // Specify how corrections should be specified
        OriginalDeclarationFY := Format(Date2DMY(InvoicePostingDate, 3));
        LibraryVariableStorageForSpecifyCorrectionsConfirmHandler.Enqueue(OriginalDeclarationFY);

        // Exercise: run report
        LibraryVariableStorageForMessages.Enqueue(CustomerVendorMsg);
        LibraryVariableStorageForMessages.Enqueue(NoCorrectionsWillBeIncludedMsg);
        LibraryVariableStorageForMessages.Enqueue(ReportExportedSuccessfullyMsg);
        FileName := FileManagement.ServerTempFileName('.txt');
        RunMake349DeclarationReport2(FileName, 'ES', ContactNameTxt, TelephoneNumberTxt,
          '3490000000000', Date2DMY(CrMemoPostingDate, 3));

        // Validate: Check that we got the right no of messages
        Assert.AreEqual(0, LibraryVariableStorageForMessages.Length(), 'We expected messages, but did not get them all.');

        // One customer line is created
        // If credit memo corrects invoice from the preivous period, rectification line is created
        // If credit memo corrects invoice from the same period, normal line is created.
        LineNo[1] := LibraryTextFileValidation.FindLineNoWithValue(FileName, 93, 40, PadCustVendNo(Customer."No."), 1);
        LineNo[2] := LibraryTextFileValidation.FindLineNoWithValue(FileName, 93, 40, PadCustVendNo(Customer."No."), 2);
        Assert.AreEqual(2, LineNo[1], 'Failed to find even the first line');
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler,SpecifyCorrectionsConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerWithCreditMemoWithSameOriginalDeclarationFY()
    var
        FileName: Text[1024];
        LineNo: array[2] of Integer;
        SalesCrMemoAmt: Decimal;
        SalesInvoiceAmt: Decimal;
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 362501] One customer line in case of "EU 3-Party Trade" = FALSE and "Original Declaration FY" = current FY

        // [GIVEN] Sales Invoice with "EU 3-Party Trade" = FALSE
        // [GIVEN] Sales Credit Memo
        // [WHEN] Run "Make 349 Declaration" report with "Original Declaration FY" = current FY
        RunReportForCustomerWithCreditMemoCorrection(FileName, LineNo, SalesInvoiceAmt, SalesCrMemoAmt, 0, false);

        // [THEN] There is only one customer line of normal type in the exported file
        Assert.AreEqual(0, LineNo[2], UnexpectedSecondLineErr);

        // [THEN] First customer line has Amount = 1000 - 200 = 800.
        Evaluate(ActualAmount, LibraryTextFileValidation.ReadValueFromLine(FileName, LineNo[1], 134, 13));
        Assert.AreEqual(SalesInvoiceAmt - SalesCrMemoAmt, ActualAmount / 100, '');
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler,SpecifyCorrectionsConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerWithCreditMemoWithDifferentOriginalDeclarationFY()
    var
        FileName: Text[1024];
        LineNo: array[2] of Integer;
        SalesCrMemoAmt: Decimal;
        SalesInvoiceAmt: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 362501] One customer line in case of "EU 3-Party Trade" = FALSE and "Original Declaration FY" = current FY - 1

        // [GIVEN] Sales Invoice with "EU 3-Party Trade" = FALSE and Amount 1000.
        // [GIVEN] Sales Credit Memo with Amount 200.
        // [WHEN] Run "Make 349 Declaration" report with "Original Declaration FY" = current FY - 1
        RunReportForCustomerWithCreditMemoCorrection(FileName, LineNo, SalesInvoiceAmt, SalesCrMemoAmt, -1, false);

        // [THEN] There is only one customer line of rectification type in the exported file
        Assert.AreEqual(0, LineNo[2], SecondLineNotFoundErr);

        // [THEN] Customer line "Original Declared Amount" = 0
        // [THEN] Customer line "Previous Declared Amount" = 1000.
        VerifyRectificationLineOrigAndPrevDeclAmounts(FileName, LineNo[1], 0, SalesCrMemoAmt);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler,SpecifyCorrectionsConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerWithCreditMemoWithSameOriginalDeclarationFYAndEUThirdPartyTrade()
    var
        FileName: Text[1024];
        LineNo: array[2] of Integer;
        SalesCrMemoAmt: Decimal;
        SalesInvoiceAmt: Decimal;
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 362501] One customer line in case of "EU 3-Party Trade" = TRUE and "Original Declaration FY" = current FY

        // [GIVEN] Sales Invoice with "EU 3-Party Trade" = TRUE and Amount 1000.
        // [GIVEN] Sales Credit Memo with "EU 3-Party Trade" = TRUE and Amount 200.
        // [WHEN] Run "Make 349 Declaration" report with "Original Declaration FY" = current FY
        RunReportForCustomerWithCreditMemoCorrection(FileName, LineNo, SalesInvoiceAmt, SalesCrMemoAmt, 0, true);

        // [THEN] There is only one customer line of normal type in the exported file
        Assert.AreEqual(0, LineNo[2], UnexpectedSecondLineErr);

        // [THEN] Customer line has Amount = 1000.
        Evaluate(ActualAmount, LibraryTextFileValidation.ReadValueFromLine(FileName, LineNo[1], 134, 13));
        Assert.AreEqual(SalesInvoiceAmt, ActualAmount / 100, '');
    end;

    local procedure RunReportForVendorWithCreditMemoCorrection(OriginalDeclarationFYDelta: Integer)
    var
        Location: Record Location;
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
        Vendor: Record Vendor;
        InvoicePostingDate: Date;
        CrMemoPostingDate: Date;
        FileName: Text[1024];
        PurchaseInvoiceNo: Code[20];
        PostedDocNo: Code[20];
        OriginalDeclarationFY: Code[4];
        LineNo1: Integer;
        LineNo2: Integer;
        PurchaseCrMemoAmt: Decimal;
    begin
        Initialize();

        // Setup new location
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Country/Region Code", ESTxt);
        Location.Modify();

        // Create GL account
        LibraryERM.CreateGLAccount(GLAccount);

        // Setup inventory posting setup
        InventoryPostingGroup.FindLast();
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);
        InventoryPostingSetup.Validate("Inventory Account", GLAccount."No.");
        InventoryPostingSetup.Modify(true);

        // Create new vendor with given country
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", EUCountryCodeTxt);
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        Vendor.Modify(true);
        AssignPaymentTermsToVendor(Vendor."No.");

        CrMemoPostingDate := GetNewWorkDate();
        InvoicePostingDate := CalcDate(StrSubstNo('<%1Y>', OriginalDeclarationFYDelta), CrMemoPostingDate);

        // Create and post purchase invoice
        PurchaseInvoiceNo := CreateAndPostPurchaseInvoiceWithOrderAddressAndLocationCode(Vendor."No.", InventoryPostingGroup.Code,
            InvoicePostingDate, Location.Code, '');

        // Create and post credit memo for the purchase invoice
        PostedDocNo := CreateAndPostPurchaseCreditMemo(Vendor."No.", PurchaseInvoiceNo, CrMemoPostingDate);
        PurchaseCrMemoAmt := GetPurchaseCrMemoDocAmount(PostedDocNo);

        // Specify how corrections should be specified
        OriginalDeclarationFY := Format(Date2DMY(InvoicePostingDate, 3));
        LibraryVariableStorageForSpecifyCorrectionsConfirmHandler.Enqueue(OriginalDeclarationFY);

        // Exercise: run report
        LibraryVariableStorageForMessages.Enqueue(CustomerVendorMsg);
        LibraryVariableStorageForMessages.Enqueue(NoCorrectionsWillBeIncludedMsg);
        LibraryVariableStorageForMessages.Enqueue(ReportExportedSuccessfullyMsg);
        FileName := FileManagement.ServerTempFileName('.txt');
        RunMake349DeclarationReport2(FileName, 'ES', ContactNameTxt, TelephoneNumberTxt,
          '3490000000000', Date2DMY(CrMemoPostingDate, 3));

        // Validate: Check that we got the right no of messages
        Assert.AreEqual(0, LibraryVariableStorageForMessages.Length(), 'We expected messages, but did not get them all.');

        // One customer line is created
        // If credit memo corrects invoice from the preivous period, rectification line is created
        // If credit memo corrects invoice from the same period, normal line is created.
        LineNo1 := LibraryTextFileValidation.FindLineNoWithValue(FileName, 93, 40, PadCustVendNo(Vendor."No."), 1);
        LineNo2 := LibraryTextFileValidation.FindLineNoWithValue(FileName, 93, 40, PadCustVendNo(Vendor."No."), 2);
        Assert.AreEqual(2, LineNo1, 'Failed to find even the first line');
        Assert.AreEqual(0, LineNo2, 'Found a second line, but it should not be there');
        if OriginalDeclarationFYDelta <> 0 then
            VerifyRectificationLineOrigAndPrevDeclAmounts(FileName, LineNo1, 0, PurchaseCrMemoAmt);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler,SpecifyCorrectionsConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestVendorWithCreditMemoWithSameOriginalDeclarationFY()
    begin
        RunReportForVendorWithCreditMemoCorrection(0);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationReportHandler,GenericMessageHandler,SpecifyCorrectionsConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestVendorWithCreditMemoWithDifferentOriginalDeclarationFY()
    begin
        RunReportForVendorWithCreditMemoCorrection(-1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationForeignPurchNoVATEUCountry()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        FileName: Text[1024];
        VendorNo: Code[20];
        PostingDate: Date;
        InvAmount: Decimal;
    begin
        // [SCENARIO 378275] Foreign Purchase Invoice with Non-Taxable VAT and EU Country is exported
        Initialize();

        // [GIVEN] Create and Post Purchase Invoice for Foreign EU Vendor with No Taxable VAT Posting Setup with Amount = "X"
        CreateAndPostPurchInvoiceNoTax(CreateCountryRegion(), VendorNo, InvAmount, PostingDate);

        // [WHEN] Run Make 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Purchase Invoice's data is exported with NoTaxable Amount = "X"
        ValidateFormat349FileRecord(FileName, PostingDate, VendorNo, VendorNo, 'A', InvAmount);

        // tear down
        PurchInvLine.SetRange("Pay-to Vendor No.", VendorNo);
        PurchInvLine.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationForeignPurchNoVATEUCountrySameVATRegNo()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        Vendor: Record Vendor;
        FileName: Text[1024];
        VendorNo: Code[20];
        PostingDate: Date;
        InvAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT]
        // [SCENARIO 448833] Foreign Purchase Invoice with Non-Taxable VAT and EU Country when two vendors have same VAT Registration No.
        Initialize();

        // [GIVEN] Create and Post Purchase Invoice for Foreign EU Vendor with No Taxable VAT Posting Setup with Amount = "X"
        CreateAndPostPurchInvoiceNoTax(CreateCountryRegion(), VendorNo, InvAmount, PostingDate);
        // [GIVEN] One more vendor with same VAT Registration No. exists
        Vendor.GET(VendorNo);
        Vendor.GET(
          CreateVendor(Vendor."Country/Region Code", Vendor."VAT Bus. Posting Group", Vendor."VAT Registration No."));

        // [WHEN] Run Make 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Purchase Invoice's data is exported with NoTaxable Amount = "X"
        ValidateFormat349FileRecord(FileName, PostingDate, Vendor."No.", Vendor."No.", 'A', InvAmount);

        // tear down
        PurchInvLine.SetRange("Pay-to Vendor No.", VendorNo);
        PurchInvLine.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationForeignPurchNoVATNotEUCountry()
    var
        VendorNo: Code[20];
        PostingDate: Date;
        InvAmount: Decimal;
    begin
        // [SCENARIO 378275] Foreign Purchase Invoice with Non-Taxable VAT and not EU Country is not exported
        Initialize();

        // [GIVEN] Create and Post Purchase Invoice for Foreign Non-EU Vendor with No Taxable VAT Posting Setup
        CreateAndPostPurchInvoiceNoTax(CreateCountryRegionNotEU(), VendorNo, InvAmount, PostingDate);

        // [WHEN] Run Make 349 Declaration
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Error thrown: 'Could not find file'.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithNoTaxableVATSameFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT]
        // [SCENARIO 380389] Purchase Credit Memo with "No Taxable" VAT with 'Original Declared Amount' in correction entry
        // [SCENARIO 380389] is substructed from Invoice's amount when running declaration 349
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        VendorNo :=
          CreateVendor(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Purchase Invoice with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        InvAmount :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);

        // [GIVEN] Purchase Credit Memo with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostPurchaseCrMemoWithCustomAmount(
          VendorNo, ItemNo, FindLastPurchInvNo(VendorNo), PostingDate, CrMemoAmount);

        // [GIVEN] 'Original Declared Amount' = 30 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, VendorNo, CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, VendorNo, 0);
        EntryAmount := ReadEntryAmount(Line);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithNoTaxableEUServiceVATSameFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT] [EU Service]
        // [SCENARIO 380389] Purchase Credit Memo with "No Taxable" and "EU Service" VAT with 'Original Declared Amount' in correction entry
        // [SCENARIO 380389] is substructed from Invoice's amount when running declaration 349
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT" and "EU Service"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, true);
        VendorNo :=
          CreateVendor(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Purchase Invoice with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        InvAmount :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);

        // [GIVEN] Purchase Credit Memo with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostPurchaseCrMemoWithCustomAmount(
          VendorNo, ItemNo, FindLastPurchInvNo(VendorNo), PostingDate, CrMemoAmount);

        // [GIVEN] 'Original Declared Amount' = 30 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, VendorNo, CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, VendorNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 142);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349DiffPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithNoTaxableVATDiffFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        ItemNo: Code[20];
        CorrectedInvNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PrevInvAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
        PreviousPostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT]
        // [SCENARIO 380389] Purchase Credit Memo with "No Taxable" VAT exports separately from Invoice in different period when running declaration 349 and confirm Credit Memo as Correction Entry

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        VendorNo :=
          CreateVendor(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Purchase Invoice "A" with "No Taxable VAT", "Posting Date" = 01.01.15 and Amount = 100
        PreviousPostingDate := GetNewWorkDate();
        PrevInvAmount :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, PreviousPostingDate);
        CorrectedInvNo := FindLastPurchInvNo(VendorNo);

        // [GIVEN] Purchase Invoice "B" with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 50
        PostingDate := CalcDate('<1Y>', PreviousPostingDate);
        InvAmount :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);

        // [GIVEN] Purchase Credit Memo "C" with "No Taxable VAT", "Posting Date" = 01.01.16, "Corrected Invoice No." = "A" and Amount = 30
        CrMemoAmount := Round(PrevInvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostPurchaseCrMemoWithCustomAmount(
          VendorNo, ItemNo, CorrectedInvNo, PostingDate, CrMemoAmount);

        SetCustVendWarningsPrevDataForHandler(PostingDate, PreviousPostingDate, VendorNo, PrevInvAmount, CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 30 for Purchase Credit Memo "C" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, VendorNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 153);
        Assert.AreEqual(CrMemoAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 100 for Purchase Invoice "A" exist in output file
        EntryAmount := ReadEntryAmountCustomPosition(Line, 166);
        Assert.AreEqual(PrevInvAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 50 for Purchase Invoice "B" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, VendorNo, 1);
        EntryAmount := ReadEntryAmount(Line);
        Assert.AreEqual(InvAmount * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349DiffPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithNoTaxableEUServiceVATDiffFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        ItemNo: Code[20];
        CorrectedInvNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PrevInvAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
        PreviousPostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT] [EU Service]
        // [SCENARIO 380389] Purchase Credit Memo with "No Taxable" and "EU Service" VAT exports separately from Invoice in different period when running declaration 349 and confirm Credit Memo as Correction Entry

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT" and "EU Service"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, true);

        VendorNo :=
          CreateVendor(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Purchase Invoice "A" with "No Taxable VAT", "Posting Date" = 01.01.15 and Amount = 100
        PreviousPostingDate := GetNewWorkDate();
        PrevInvAmount :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, PreviousPostingDate);
        CorrectedInvNo := FindLastPurchInvNo(VendorNo);

        // [GIVEN] Purchase Invoice "B" with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 50
        PostingDate := CalcDate('<1Y>', PreviousPostingDate);
        InvAmount :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);

        // [GIVEN] Purchase Credit Memo "C" with "No Taxable VAT", "Posting Date" = 01.01.16, "Corrected Invoice No." = "A" and Amount = 30
        CrMemoAmount := Round(PrevInvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostPurchaseCrMemoWithCustomAmount(
          VendorNo, ItemNo, CorrectedInvNo, PostingDate, CrMemoAmount);

        SetCustVendWarningsPrevDataForHandler(PostingDate, PreviousPostingDate, VendorNo, PrevInvAmount, CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 30 for Purchase Credit Memo "C" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, VendorNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 153);
        Assert.AreEqual(CrMemoAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 100 for Purchase Invoice "A" exist in output file
        EntryAmount := ReadEntryAmountCustomPosition(Line, 166);
        Assert.AreEqual(PrevInvAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 50 for Purchase Invoice "B" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, VendorNo, 1);
        EntryAmount := ReadEntryAmount(Line);
        Assert.AreEqual(InvAmount * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoTaxableVATSameFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT]
        // [SCENARIO 380389] Sales Credit Memo with "No Taxable" VAT with 'Original Declared Amount' in correction entry
        // [SCENARIO 380389] is substructed from Invoice's amount when running declaration 349

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Sales Invoice with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        InvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);

        // [GIVEN] Sales Credit Memo with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, FindLastSalesInvNo(CustomerNo), PostingDate, false, CrMemoAmount);

        // [GIVEN] 'Original Declared Amount' = 30 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, CustomerNo, -CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmount(Line);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoTaxableEUServiceVATSameFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT] [EU Service]
        // [SCENARIO 380389] Sales Credit Memo with "No Taxable" and "EU Service" VAT with 'Original Declared Amount' in correction entry
        // [SCENARIO 380389] is substructed from Invoice's amount when running declaration 349

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT" and "EU Service"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, true);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Sales Invoice with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        InvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);

        // [GIVEN] Sales Credit Memo with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, FindLastSalesInvNo(CustomerNo), PostingDate, false, CrMemoAmount);

        // [GIVEN] 'Original Declared Amount' = 30 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, CustomerNo, -CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 142);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoTaxableEUThirdPartyTradeVATSameFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT] [EU 3-Party Trade]
        // [SCENARIO 380389] Sales Credit Memo with "No Taxable" and "EU 3-Party Trade" with 'Original Declared Amount' in correction entry
        // [SCENARIO 380389] is substructed from Invoice's amount when running declaration 349

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, true);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Sales Invoice with "No Taxable VAT", "EU 3-Party Trade", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        InvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, true);

        // [GIVEN] Sales Credit Memo with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, FindLastSalesInvNo(CustomerNo), PostingDate, false, CrMemoAmount);

        // [GIVEN] 'Original Declared Amount' = 30 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, CustomerNo, -CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 142);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349DiffPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoTaxableVATDiffFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        CorrectedInvNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PrevInvAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
        PreviousPostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT]
        // [SCENARIO 380389] Sales Credit Memo with "No Taxable" VAT exports separately from Invoice in different period when running declaration 349 and confirm Credit Memo as Correction Entry

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Sales Invoice "A" with "No Taxable VAT", "Posting Date" = 01.01.15 and Amount = 100
        PreviousPostingDate := GetNewWorkDate();
        PrevInvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PreviousPostingDate, false);
        CorrectedInvNo := FindLastSalesInvNo(CustomerNo);

        // [GIVEN] Sales Invoice "B" with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 50
        PostingDate := CalcDate('<1Y>', PreviousPostingDate);
        InvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);

        // [GIVEN] Sales Credit Memo "C" with "No Taxable VAT", "Posting Date" = 01.01.16, "Corrected Invoice No." = "A" and Amount = 30
        CrMemoAmount := Round(PrevInvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, CorrectedInvNo, PostingDate, false, CrMemoAmount);

        SetCustVendWarningsPrevDataForHandler(PostingDate, PreviousPostingDate, CustomerNo, PrevInvAmount, CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 30 for Sales Credit Memo "C" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 153);
        Assert.AreEqual(CrMemoAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 100 for Sales Invoice "A" exist in output file
        EntryAmount := ReadEntryAmountCustomPosition(Line, 166);
        Assert.AreEqual(PrevInvAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 50 for Sales Invoice "B" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 1);
        EntryAmount := ReadEntryAmount(Line);
        Assert.AreEqual(InvAmount * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349DiffPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoTaxableEUServiceVATDiffFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        CorrectedInvNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PrevInvAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
        PreviousPostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT] [EU Service]
        // [SCENARIO 380389] Sales Credit Memo with "No Taxable" and "EU Service" VAT exports separately from Invoice in different period when running declaration 349 and confirm Credit Memo as Correction Entry

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT" and "EU Service"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, true);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Sales Invoice "A" with "No Taxable VAT", "Posting Date" = 01.01.15 and Amount = 100
        PreviousPostingDate := GetNewWorkDate();
        PrevInvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PreviousPostingDate, false);
        CorrectedInvNo := FindLastSalesInvNo(CustomerNo);

        // [GIVEN] Sales Invoice "B" with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 50
        PostingDate := CalcDate('<1Y>', PreviousPostingDate);
        InvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);

        // [GIVEN] Sales Credit Memo "C" with "No Taxable VAT", "Posting Date" = 01.01.16, "Corrected Invoice No." = "A" and Amount = 30
        CrMemoAmount := Round(PrevInvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, CorrectedInvNo, PostingDate, false, CrMemoAmount);

        SetCustVendWarningsPrevDataForHandler(PostingDate, PreviousPostingDate, CustomerNo, PrevInvAmount, CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 30 for Sales Credit Memo "C" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 153);
        Assert.AreEqual(CrMemoAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 100 for Sales Invoice "A" exist in output file
        EntryAmount := ReadEntryAmountCustomPosition(Line, 166);
        Assert.AreEqual(PrevInvAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 50 for Sales Invoice "B" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 1);
        EntryAmount := ReadEntryAmount(Line);
        Assert.AreEqual(InvAmount * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349DiffPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoTaxableEUThirdPartyTradeVATDiffFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        CorrectedInvNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PrevInvAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
        PreviousPostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT] [EU 3-Party Trade]
        // [SCENARIO 380389] Sales Credit Memo with "No Taxable" and "EU Service" VAT exports separately from Invoice in different period when running declaration 349 and confirm Credit Memo as Correction Entry

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Sales Invoice "A" with "No Taxable VAT", "EU 3-Party Trade", "Posting Date" = 01.01.15 and Amount = 100
        PreviousPostingDate := GetNewWorkDate();
        PrevInvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PreviousPostingDate, true);
        CorrectedInvNo := FindLastSalesInvNo(CustomerNo);

        // [GIVEN] Sales Invoice "B" with "No Taxable VAT", "EU 3-Party Trade","Posting Date" = 01.01.16 and Amount = 50
        PostingDate := CalcDate('<1Y>', PreviousPostingDate);
        InvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, true);

        // [GIVEN] Sales Credit Memo "C" with "No Taxable VAT", "Posting Date" = 01.01.16, "Corrected Invoice No." = "A" and Amount = 30
        CrMemoAmount := Round(PrevInvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, CorrectedInvNo, PostingDate, true, CrMemoAmount);

        SetCustVendWarningsPrevDataForHandler(PostingDate, PreviousPostingDate, CustomerNo, PrevInvAmount, CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 30 for Sales Credit Memo "C" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 153);
        Assert.AreEqual(CrMemoAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 100 for Sales Invoice "A" exist in output file
        EntryAmount := ReadEntryAmountCustomPosition(Line, 166);
        Assert.AreEqual(PrevInvAmount * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 50 for Sales Invoice "B" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 1);
        EntryAmount := ReadEntryAmount(Line);
        Assert.AreEqual(InvAmount * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349MultipleDiffPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleSalesCreditMemosWithNoTaxableVATDiffFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: array[2] of Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
        PreviousPostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT]
        // [SCENARIO 380841] Multiple Sales Credit Memos with "No Taxable" VAT exports separately from Invoice in different period when running declaration 349 and confirm both Credit Memos as Correction Entry

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Sales Invoice "A" with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PreviousPostingDate := GetNewWorkDate();
        InvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PreviousPostingDate, false);

        // [GIVEN] Sales Credit Memo "C1" with "No Taxable VAT", "Posting Date" = 01.02.16 and Amount = 50
        // [GIVEN] Sales Credit Memo "C2" with "No Taxable VAT", "Posting Date" = 01.02.16 and Amount = 30
        PostingDate := CalcDate('<1Y>', PreviousPostingDate);
        CrMemoAmount[1] := Round(InvAmount / LibraryRandom.RandIntInRange(3, 5));
        CrMemoAmount[2] := Round(CrMemoAmount[1] / LibraryRandom.RandIntInRange(3, 5));
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, FindLastSalesInvNo(CustomerNo), PostingDate, false, CrMemoAmount[1]);
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, FindLastSalesInvNo(CustomerNo), PostingDate, false, CrMemoAmount[2]);

        // [GIVEN] Sales Credit Memo "C" with "No Taxable VAT", "Posting Date" = 01.02.16 and Amount = 30
        SetCustVendWarningsPrevDataMultipleForHandler(PostingDate, PreviousPostingDate, CustomerNo, InvAmount, CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 80 for Sales Credit Memo "C1" and "C2" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 153);
        Assert.AreEqual((CrMemoAmount[1] + CrMemoAmount[2]) * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 100 for Sales Invoice "A" exist in output file
        EntryAmount := ReadEntryAmountCustomPosition(Line, 166);
        Assert.AreEqual(InvAmount * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349MultipleDiffPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure MultiplePurchCreditMemosWithNoTaxableVATDiffFY()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: array[2] of Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
        PreviousPostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT]
        // [SCENARIO 380841] Multiple Purchase Credit Memos with "No Taxable" VAT exports separately from Invoice in different period when running declaration 349 and confirm both Credit Memos as Correction Entry

        Initialize();
        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        VendorNo :=
          CreateVendor(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Purchase Invoice "A" with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PreviousPostingDate := GetNewWorkDate();
        InvAmount :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, PreviousPostingDate);

        // [GIVEN] Purchase Credit Memo "C1" with "No Taxable VAT", "Posting Date" = 01.02.16 and Amount = 50
        // [GIVEN] Purchase Credit Memo "C2" with "No Taxable VAT", "Posting Date" = 01.02.16 and Amount = 30
        PostingDate := CalcDate('<1Y>', PreviousPostingDate);
        CrMemoAmount[1] := Round(InvAmount / LibraryRandom.RandIntInRange(3, 5));
        CrMemoAmount[2] := Round(CrMemoAmount[1] / LibraryRandom.RandIntInRange(3, 5));
        CreateAndPostPurchaseCrMemoWithCustomAmount(
          VendorNo, ItemNo, FindLastPurchInvNo(VendorNo), PostingDate, CrMemoAmount[1]);
        CreateAndPostPurchaseCrMemoWithCustomAmount(
          VendorNo, ItemNo, FindLastPurchInvNo(VendorNo), PostingDate, CrMemoAmount[2]);

        // [GIVEN] Purchase Credit Memo "C" with "No Taxable VAT", "Posting Date" = 01.02.16 and Amount = 30
        SetCustVendWarningsPrevDataMultipleForHandler(PostingDate, PreviousPostingDate, VendorNo, InvAmount, CrMemoAmount);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 80 for Purchase Credit Memo "C1" and "C2" exist in output file
        Line := ReadLineWithCustomerOrVendor(FileName, VendorNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 153);
        Assert.AreEqual((CrMemoAmount[1] + CrMemoAmount[2]) * 100, EntryAmount, IncorrectValueErr);

        // [THEN] Entry Amount = 100 for Purchase Invoice "A" exist in output file
        EntryAmount := ReadEntryAmountCustomPosition(Line, 166);
        Assert.AreEqual(InvAmount * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandlerMultiple')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithNoTaxableVATSameFYCorrection()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ItemNo1: Code[20];
        ItemNo2: Code[20];
        VendorNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT]
        // [SCENARIO 398163] Purchase Credit Memo with "No Taxable" VAT in correction entry
        // [SCENARIO 398163] is substructed from Invoice's amount when running declaration 349
        Initialize();

        // [GIVEN] Two different VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup1, false);
        CreateVATPostingSetupForBusGroup(VATPostingSetup2, VATPostingSetup1."VAT Bus. Posting Group");
        VATPostingSetup2.Validate("VAT Calculation Type", VATPostingSetup2."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup2.Modify(true);
        VendorNo :=
          CreateVendor(EUCountryCodeTxt, VATPostingSetup1."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Purchase Invoice has two lines with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo1 := CreateItem(VATPostingSetup1."VAT Prod. Posting Group");
        ItemNo2 := CreateItem(VATPostingSetup2."VAT Prod. Posting Group");
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, PostingDate);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item,
          CreateItem(VATPostingSetup1."VAT Prod. Posting Group"), LibraryRandom.RandIntInRange(10, 20));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, ItemNo2, LibraryRandom.RandIntInRange(10, 20));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        InvAmount := PurchaseLine1."Amount Including VAT" + PurchaseLine2."Amount Including VAT";

        // [GIVEN] Purchase Credit Memo has two lines with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, PostingDate);
        PurchaseHeader.Validate("Corrected Invoice No.", FindLastPurchInvNo(VendorNo));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine1, PurchaseHeader, PurchaseLine1.Type::Item, ItemNo1, LibraryRandom.RandIntInRange(1, 5));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, ItemNo2, LibraryRandom.RandIntInRange(1, 5));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CrMemoAmount := PurchaseLine1."Amount Including VAT" + PurchaseLine2."Amount Including VAT";

        // [GIVEN] 'Original Declared Amount' = 0 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, VendorNo, 0);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exists in output file
        Line := ReadLineWithCustomerOrVendor(FileName, VendorNo, 0);
        EntryAmount := ReadEntryAmount(Line);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoWithNoTaxableEUServiceVATSameFYCorrection()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT] [EU Service]
        // [SCENARIO 398163] Purchase Credit Memo with "No Taxable" VAT and "EU Service"
        // [SCENARIO 398163] is substructed from Invoice's amount when running declaration 349
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT" and "EU Service"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, true);
        VendorNo :=
          CreateVendor(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Purchase Invoice with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        InvAmount :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);

        // [GIVEN] Purchase Credit Memo with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostPurchaseCrMemoWithCustomAmount(
          VendorNo, ItemNo, FindLastPurchInvNo(VendorNo), PostingDate, CrMemoAmount);

        // [GIVEN] 'Original Declared Amount' = 0 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, VendorNo, 0);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exists in output file
        Line := ReadLineWithCustomerOrVendor(FileName, VendorNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 142);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandlerMultiple')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoTaxableVATSameFYCorrection()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo1: Code[20];
        ItemNo2: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT]
        // [SCENARIO 398163] Sales Credit Memo with "No Taxable" VAT in correction entry
        // [SCENARIO 398163] is substructed from Invoice's amount when running declaration 349
        Initialize();

        // [GIVEN] Two different VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup1, false);
        CreateVATPostingSetupForBusGroup(VATPostingSetup2, VATPostingSetup1."VAT Bus. Posting Group");
        VATPostingSetup2.Validate("VAT Calculation Type", VATPostingSetup2."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup2.Modify(true);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup1."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Sales Invoice has two lines with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo1 := CreateItem(VATPostingSetup1."VAT Prod. Posting Group");
        ItemNo2 := CreateItem(VATPostingSetup2."VAT Prod. Posting Group");
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, PostingDate, false);
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, ItemNo1, LibraryRandom.RandIntInRange(10, 20));
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, ItemNo2, LibraryRandom.RandIntInRange(10, 20));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        InvAmount := SalesLine1."Amount Including VAT" + SalesLine2."Amount Including VAT";

        // [GIVEN] Sales Credit Memo has two lines with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, PostingDate, false);
        SalesHeader.Validate("Corrected Invoice No.", FindLastSalesInvNo(CustomerNo));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine1, SalesHeader, SalesLine1.Type::Item, ItemNo1, LibraryRandom.RandIntInRange(1, 5));
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine2.Type::Item, ItemNo2, LibraryRandom.RandIntInRange(1, 5));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CrMemoAmount := SalesLine1."Amount Including VAT" + SalesLine2."Amount Including VAT";

        // [GIVEN] 'Original Declared Amount' = 0 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, CustomerNo, 0);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exists in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmount(Line);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoTaxableEUServiceVATSameFYCorrection()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT] [EU Service]
        // [SCENARIO 398163] Sales Credit Memo with "No Taxable" VAT and "EU Service"
        // [SCENARIO 398163] is substructed from Invoice's amount when running declaration 349
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT" and "EU Service" in correction entry
        CreateNoTaxableVATPostingSetup(VATPostingSetup, true);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Sales Invoice with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        InvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);

        // [GIVEN] Sales Credit Memo with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, FindLastSalesInvNo(CustomerNo), PostingDate, false, CrMemoAmount);

        // [GIVEN] 'Original Declared Amount' = 0 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, CustomerNo, 0);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exists in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 142);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoTaxableEUThirdPartyTradeVATSameFYCorrection()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        FileName: Text[1024];
        Line: Text[1024];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT] [EU 3-Party Trade]
        // [SCENARIO 398163] Sales Credit Memo with "No Taxable" VAT and "EU 3-Party Trade" in correction entry
        // [SCENARIO 398163] is substructed from Invoice's amount when running declaration 349
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "No Taxable VAT"
        CreateNoTaxableVATPostingSetup(VATPostingSetup, true);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));

        // [GIVEN] Sales Invoice with "No Taxable VAT", "EU 3-Party Trade", "Posting Date" = 01.01.16 and Amount = 100
        PostingDate := GetNewWorkDate();
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        InvAmount :=
          CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, true);

        // [GIVEN] Sales Credit Memo with "No Taxable VAT", "Posting Date" = 01.01.16 and Amount = 30
        CrMemoAmount := Round(InvAmount / LibraryRandom.RandIntInRange(3, 10));
        CreateAndPostSalesCrMemoWithCustomAmount(
          CustomerNo, ItemNo, FindLastSalesInvNo(CustomerNo), PostingDate, false, CrMemoAmount);

        // [GIVEN] 'Original Declared Amount' = 0 in Customer/Vendor Warnings 349
        SetCustVendWarningsDataForHandler(PostingDate, CustomerNo, 0);

        // [WHEN] Run 349 Declaration
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Entry Amount = 70 (Invoice Amount - Cr. Memo Amount) exists in output file
        Line := ReadLineWithCustomerOrVendor(FileName, CustomerNo, 0);
        EntryAmount := ReadEntryAmountCustomPosition(Line, 142);
        Assert.AreEqual((InvAmount - CrMemoAmount) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349ChangeOrigDeclarPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure UI_CorrectiveSalesCreditMemoDoesNotConsiderWhenPrevDeclarationAmtCalcInDiffPeriod()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InvNo: Code[20];
        InvAmount: Decimal;
        PostingDate: Date;
        PrevPostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT] [UI]
        // [SCENARIO 208313] "Previous Declaration Amount" does not include Sales Corrective Credit Memo which makes correction in different period when "Original Declaration Period" is changed on "Customer/Vendor Warnings 349" page

        Initialize();

        CreateVATPostingSetup(VATPostingSetup, false);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Sales Invoice "INV1" with "Posting Date" = 01.01.16
        PostingDate := CalcDate('<CY+1D>', GetNewWorkDate());
        CreateAndPostSalesDocument(
          SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);
        InvNo := FindLastSalesInvNo(CustomerNo);

        // [GIVEN] Sales Credit Memo "CR1" with "Corrected Invoice No." = "INV1", "Posting Date" = 01.02.16 and Amount = -30
        PostingDate := CalcDate('<1M>', PostingDate);
        PrevPostingDate := PostingDate;
        CreateAndPostCorrectiveSalesCrMemo(CustomerNo, ItemNo, PostingDate, InvNo);

        // [GIVEN] Sales Invoice "INV2" with "Posting Date" = 01.02.16 and Amount = 100
        InvAmount :=
          CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);
        InvNo := FindLastSalesInvNo(CustomerNo);

        // [GIVEN] Sales Credit Memo "CR2" with "Corrected Invoice No." = "INV2", "Posting Date" = 01.03.16 and Amount = -50
        PostingDate := CalcDate('<1M>', PostingDate);
        CreateAndPostCorrectiveSalesCrMemo(CustomerNo, ItemNo, PostingDate, InvNo);

        SetCustVendWarningsOrigDeclarPeriodChangeForHandler(PostingDate, PrevPostingDate, CustomerNo, InvAmount);

        // [GIVEN] 349 Declaration report on period "03" (March) is invoked and page "Customer/Vendor Warnings 349" with "CR2" included into correction is shown
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [WHEN] Change "Original Declaration Period" on page "Customer/Vendor Warnings 349" to "02" (February)
        // Execution done in CustomerVendorWarnings349ChangeOrigDeclarPeriodPageHandler

        // [THEN] "Previous Declaration Amount" is 100 on page "Customer/Vendor Warnings 349"
        // Verification done in VerifyCustVendWarning349PrevDeclarAmountAfterChangeOrigDeclarPeriod. After verification is done, processing stops which throws an error
        Assert.ExpectedError(ProcessAbortedErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349ChangeOrigDeclarPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure UI_CorrectivePurchCreditMemoDoesNotConsiderWhenPrevDeclarationAmtCalcInDiffPeriod()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: Code[20];
        InvNo: Code[20];
        InvAmount: Decimal;
        PostingDate: Date;
        PrevPostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT]  [UI]
        // [SCENARIO 208313] "Previous Declaration Amount" does not include Purchase Corrective Credit Memo which makes correction in different period when "Original Declaration Period" is changed on "Customer/Vendor Warnings 349" page

        Initialize();

        CreateVATPostingSetup(VATPostingSetup, false);
        VendorNo :=
          CreateVendor(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Purchase Invoice "INV1" with "Posting Date" = 01.01.16
        PostingDate := CalcDate('<CY+1D>', GetNewWorkDate());
        CreateAndPostPurchaseDocument(PurchLine."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);
        InvNo := FindLastPurchInvNo(VendorNo);

        // [GIVEN] Purchase Credit Memo "CR1" with "Corrected Invoice No." = "INV1", "Posting Date" = 01.02.16 and Amount = -30
        PostingDate := CalcDate('<1M>', PostingDate);
        PrevPostingDate := PostingDate;
        CreateAndPostCorrectivePurchCrMemo(VendorNo, ItemNo, PostingDate, InvNo);

        // [GIVEN] Purchase Invoice "INV2" with "Posting Date" = 01.02.16 and Amount = 100
        InvAmount :=
          CreateAndPostPurchaseDocument(PurchLine."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);
        InvNo := FindLastPurchInvNo(VendorNo);

        // [GIVEN] Purchase Credit Memo "CR2" with "Corrected Invoice No." = "INV2", "Posting Date" = 01.03.16 and Amount = -50
        PostingDate := CalcDate('<1M>', PostingDate);
        CreateAndPostCorrectivePurchCrMemo(VendorNo, ItemNo, PostingDate, InvNo);

        SetCustVendWarningsOrigDeclarPeriodChangeForHandler(PostingDate, PrevPostingDate, VendorNo, InvAmount);

        // [GIVEN] 349 Declaration report on period "03" (March) is invoked and page "Customer/Vendor Warnings 349" with "CR2" included into correction is shown
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [WHEN] Change "Original Declaration Period" on page "Customer/Vendor Warnings 349" to "02" (February)
        // Execution done in CustomerVendorWarnings349ChangeOrigDeclarPeriodPageHandler

        // [THEN] "Previous Declaration Amount" is 100 on page "Customer/Vendor Warnings 349"
        // Verification done in VerifyCustVendWarning349PrevDeclarAmountAfterChangeOrigDeclarPeriod. After verification is done, processing stops which throws an error
        Assert.ExpectedError(ProcessAbortedErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349ChangeOrigDeclarPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure UI_CorrectiveSalesCreditMemoConsidersWhenPrevDeclarationAmtCalcInSamePeriod()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InvNo: Code[20];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PostingDate: Date;
        PrevPostingDate: Date;
    begin
        // [FEATURE] [Sales] [Non Taxable VAT] [UI]
        // [SCENARIO 208313] "Previous Declaration Amount" includes Sales Corrective Credit Memo which makes correction in same period when "Original Declaration Period" is changed on "Customer/Vendor Warnings 349" page

        Initialize();

        CreateVATPostingSetup(VATPostingSetup, false);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Sales Invoice "INV1" with "Posting Date" = 01.01.16
        PostingDate := CalcDate('<CY+1D>', GetNewWorkDate());
        CreateAndPostSalesDocument(
          SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);

        // [GIVEN] Sales Invoice "INV2" with "Posting Date" = 01.02.16 and Amount = 100
        PostingDate := CalcDate('<1M>', PostingDate);
        PrevPostingDate := PostingDate;
        InvAmount :=
          CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);
        InvNo := FindLastSalesInvNo(CustomerNo);

        // [GIVEN] Sales Credit Memo "CR1" with "Corrected Invoice No." = "INV2", "Posting Date" = 01.02.16 and Amount = -30
        CrMemoAmount := CreateAndPostCorrectiveSalesCrMemo(CustomerNo, ItemNo, PostingDate, InvNo);

        // [GIVEN] Sales Credit Memo "CR2" with "Corrected Invoice No." = "INV2", "Posting Date" = 01.03.16 and Amount = -50
        PostingDate := CalcDate('<1M>', PostingDate);
        CreateAndPostCorrectiveSalesCrMemo(CustomerNo, ItemNo, PostingDate, InvNo);

        SetCustVendWarningsOrigDeclarPeriodChangeForHandler(PostingDate, PrevPostingDate, CustomerNo, InvAmount - CrMemoAmount);

        // [GIVEN] 349 Declaration report on period "03" (March) is invoked and page "Customer/Vendor Warnings 349" with "CR2" included into correction is shown
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [WHEN] Change "Original Declaration Period" on page "Customer/Vendor Warnings 349" to "02" (February)
        // Execution done in CustomerVendorWarnings349ChangeOrigDeclarPeriodPageHandler

        // [THEN] "Previous Declaration Amount" is 70 on page "Customer/Vendor Warnings 349"
        // Verification done in VerifyCustVendWarning349PrevDeclarAmountAfterChangeOrigDeclarPeriod. After verification is done, processing stops which throws an error
        Assert.ExpectedError(ProcessAbortedErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349ChangeOrigDeclarPeriodPageHandler')]
    [Scope('OnPrem')]
    procedure UI_CorrectivePurchCreditMemoConsidersWhenPrevDeclarationAmtCalcInSamePeriod()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: Code[20];
        InvNo: Code[20];
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
        PostingDate: Date;
        PrevPostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Non Taxable VAT]  [UI]
        // [SCENARIO 208313] "Previous Declaration Amount" includes Purchase Corrective Credit Memo which makes correction in same period when "Original Declaration Period" is changed on "Customer/Vendor Warnings 349" page

        Initialize();

        CreateVATPostingSetup(VATPostingSetup, false);
        VendorNo :=
          CreateVendor(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Purchase Invoice "INV1" with "Posting Date" = 01.01.16
        PostingDate := CalcDate('<CY+1D>', GetNewWorkDate());
        CreateAndPostPurchaseDocument(PurchLine."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);

        // [GIVEN] Purchase Invoice "INV2" with "Posting Date" = 01.02.16 and Amount = 100
        PostingDate := CalcDate('<1M>', PostingDate);
        PrevPostingDate := PostingDate;
        InvAmount :=
          CreateAndPostPurchaseDocument(PurchLine."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);
        InvNo := FindLastPurchInvNo(VendorNo);

        // [GIVEN] Purchase Credit Memo "CR1" with "Corrected Invoice No." = "INV2", "Posting Date" = 01.02.16 and Amount = -30
        CrMemoAmount := CreateAndPostCorrectivePurchCrMemo(VendorNo, ItemNo, PostingDate, InvNo);

        // [GIVEN] Purchase Credit Memo "CR2" with "Corrected Invoice No." = "INV2", "Posting Date" = 01.03.16 and Amount = -50
        PostingDate := CalcDate('<1M>', PostingDate);
        CreateAndPostCorrectivePurchCrMemo(VendorNo, ItemNo, PostingDate, InvNo);

        SetCustVendWarningsOrigDeclarPeriodChangeForHandler(PostingDate, PrevPostingDate, VendorNo, CrMemoAmount - InvAmount);

        // [GIVEN] 349 Declaration report on period "03" (March) is invoked and page "Customer/Vendor Warnings 349" with "CR2" included into correction is shown
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [WHEN] Change "Original Declaration Period" on page "Customer/Vendor Warnings 349" to "02" (February)
        // Execution done in CustomerVendorWarnings349ChangeOrigDeclarPeriodPageHandler

        // [THEN] "Previous Declaration Amount" is 70 on page "Customer/Vendor Warnings 349"
        // Verification done in VerifyCustVendWarning349PrevDeclarAmountAfterChangeOrigDeclarPeriod. After verification is done, processing stops which throws an error
        Assert.ExpectedError(ProcessAbortedErr);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,GenericMessageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure CorrectiveSalesCreditMemosDiffPeriodExcludedFromTotalAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InvNo: Code[20];
        InvAmount: array[2] of Decimal;
        CrMemoAmount: array[2] of Decimal;
        EntryAmount: Decimal;
        PostingDate: Date;
        PrevPostingDate: Date;
        FileName: Text[1024];
        Line: Text[1024];
    begin
        // [FEATURE] [Sales] [Non Taxable VAT] [UI]
        // [SCENARIO 208313] Corrective Credit Memo for different period is excluded from calculation of Total Amount

        Initialize();

        CreateVATPostingSetup(VATPostingSetup, false);
        CustomerNo :=
          CreateCustomer(EUCountryCodeTxt, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Sales Invoice "INV1" with "Posting Date" = 01.01.16
        PostingDate := CalcDate('<CY+1D>', GetNewWorkDate());
        PrevPostingDate := PostingDate;
        InvAmount[1] :=
          CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, false);
        InvNo := FindLastSalesInvNo(CustomerNo);

        // [GIVEN] Sales Credit Memo "CR1" with "Corrected Invoice No." = "INV1", "Posting Date" = 01.02.16 and Amount = 60
        PostingDate := CalcDate('<1M>', PostingDate);
        CrMemoAmount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        CrMemoAmount[2] := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateAndPostCorrectiveSalesCrMemoCustomAmount(CustomerNo, ItemNo, PostingDate, InvNo, CrMemoAmount[1]);

        // [GIVEN] Sales Invoice "INV2" with "Posting Date" = 01.02.16 and Amount = 90
        InvAmount[2] := CrMemoAmount[1] + CrMemoAmount[2] - LibraryRandom.RandDecInRange(1, 50, 2);
        CreateAndPostSalesDocumentFixedAmount(SalesHeader."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, InvAmount[2]);
        InvNo := FindLastSalesInvNo(CustomerNo);

        // [GIVEN] Sales Credit Memo "CR2" with "Corrected Invoice No." = "INV2", "Posting Date" = 01.02.16 and Amount = 40
        CreateAndPostCorrectiveSalesCrMemoCustomAmount(CustomerNo, ItemNo, PostingDate, InvNo, CrMemoAmount[2]);
        SetCustVendWarningsOrigDeclarPeriodChangeForHandler(PostingDate, PrevPostingDate, CustomerNo, InvAmount[1] - CrMemoAmount[1]);

        // [WHEN] Run 349 Declaration report on period "02" (February) is invoked and include Credit Memo "CR1" for period "01" amd Credit Memo "CR2" for period "02"
        // Execution done in CustomerVendorWarnings349IncludeAllEntriesPageHandler
        FileName := RunMake349DeclarationWithDate(PostingDate);

        // [THEN] Total Entry Amount for Sales Invoice "INV2" - Sales Credit Memo "CR2" = 90 - 40 = 50 (wthout Amount of "CR2")
        Line := CopyStr(LibraryTextFileValidation.ReadLine(FileName, 3), 1, MaxStrLen(Line));
        EntryAmount := ReadEntryAmountCustomPosition(Line, 142);
        Assert.AreEqual((InvAmount[2] - CrMemoAmount[2]) * 100, EntryAmount, IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationNationalPurchCrMemoNoTaxableVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PostingDate: Date;
    begin
        // [SCENARIO 216654] National Purchase Credit Memo with No Taxable VAT is not exported
        Initialize();

        // [GIVEN] Posted Purchase Credit Memo for National Vendor with "No Taxable VAT"
        PostingDate := GetNewWorkDate();
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        CreateAndPostPurchaseDocument(
          PurchaseHeader."Document Type"::"Credit Memo", CreateNationalVendorWithVATRegNo(VATPostingSetup."VAT Bus. Posting Group"),
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), PostingDate);

        // [WHEN] Run 349 Declaration
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [THEN] No any records were exported.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationNationalPurchCrMemoNormalAndNoTaxableVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupNoTax: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PostingDate: Date;
    begin
        // [SCENARIO 216654] National Purchase Credit Memo with Normal and No Taxable VAT is not exported
        Initialize();

        // [GIVEN] Posted Purchase Credit Memo for National Vendor with one line of normal VAT and second with "No Taxable VAT"
        PostingDate := GetNewWorkDate();
        CreateNoTaxableVATPostingSetup(VATPostingSetupNoTax, false);
        CreateVATPostingSetupForBusGroup(VATPostingSetup, VATPostingSetupNoTax."VAT Bus. Posting Group");
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo",
          CreateNationalVendorWithVATRegNo(VATPostingSetup."VAT Bus. Posting Group"), PostingDate);
        CreatePurchaseLineWithVAT(PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchaseLineWithVAT(PurchaseHeader, VATPostingSetupNoTax."VAT Prod. Posting Group");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run 349 Declaration
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [THEN] No any records were exported.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationNationalSalesCrMemoNoTaxableVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        PostingDate: Date;
    begin
        // [SCENARIO 216654] National Sales Credit Memo with No Taxable VAT is not exported
        Initialize();

        // [GIVEN] Posted Sales Credit Memo for National Customer with "No Taxable VAT"
        PostingDate := GetNewWorkDate();
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false);
        CreateAndPostSalesDocument(
          SalesHeader."Document Type"::"Credit Memo", CreateNationalCustomerWithVATRegNo(VATPostingSetup."VAT Bus. Posting Group"),
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), PostingDate, false);

        // [WHEN] Run 349 Declaration
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [THEN] No any records were exported.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Test349DeclarationNationalSalesCrMemoNormalAndNoTaxableVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupNoTax: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        PostingDate: Date;
    begin
        // [SCENARIO 216654] National Sales Credit Memo with Normal and Non-Taxable VAT is not exported
        Initialize();

        // [GIVEN] Posted Sales Credit Memo for National Customer with one line of normal VAT and second with "No Taxable VAT"
        PostingDate := GetNewWorkDate();
        CreateNoTaxableVATPostingSetup(VATPostingSetupNoTax, false);
        CreateVATPostingSetupForBusGroup(VATPostingSetup, VATPostingSetupNoTax."VAT Bus. Posting Group");
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo",
          CreateNationalCustomerWithVATRegNo(VATPostingSetup."VAT Bus. Posting Group"), PostingDate, false);
        CreateSalesLineWithVAT(SalesHeader, VATPostingSetup."VAT Prod. Posting Group");
        CreateSalesLineWithVAT(SalesHeader, VATPostingSetupNoTax."VAT Prod. Posting Group");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run 349 Declaration
        asserterror RunMake349DeclarationWithDate(PostingDate);

        // [THEN] No any records were exported.
        Assert.ExpectedError(FileNotfoundErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepPurchInvoiceWithInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 264298] Report "Make 349 Declaration" displays correct Amount for Posted Purchase Invoice with Invoice Discount, Normal VAT and blank Location
        Initialize();

        // [GIVEN] VAT Posting Setup with Normal VAT
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);

        // [GIVEN] Purchase Invoice with Amount = 1000.0 and <non-blank> "Location Code"
        // [GIVEN] "Invoice Discount Value" was set to 250.0 in Purchase Invoice
        LibraryVariableStorage.Enqueue(true);
        CreatePurchInvoiceWithLocationAndApplyInvoiceDisc(
          PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CreateLocation());

        // [GIVEN] Purchase Invoice was posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportWithoutCorrection(FileName, PurchaseHeader."Posting Date");

        // [THEN] Amount is exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(PurchaseHeader.Amount), 3, 13));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepPurchInvoiceWithInvDiscAndBlankLocationCode()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 264298] Report "Make 349 Declaration" displays correct Amount for Posted Purchase Invoice with Invoice Discount, Normal VAT and blank Location
        Initialize();

        // [GIVEN] VAT Posting Setup with Normal VAT
        LibraryVariableStorage.Enqueue(true);
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);

        // [GIVEN] Purchase Invoice with Amount = 1000.0 and <blank> "Location Code"
        // [GIVEN] "Invoice Discount Value" was set to 250.0 in Purchase Invoice
        CreatePurchInvoiceWithLocationAndApplyInvoiceDisc(
          PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '');

        // [GIVEN] Purchase Invoice was posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportWithoutCorrection(FileName, PurchaseHeader."Posting Date");

        // [THEN] Amount is exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(PurchaseHeader.Amount), 3, 13));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepPurchInvoiceWithInvDiscNoTaxableEUService()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        // [FEATURE] [Purchase] [Invoice Discount] [No Taxable VAT] [EU Service]
        // [SCENARIO 264298] Report "Make 349 Declaration" displays correct Amount for Posted Purchase Invoice with No Taxable VAT, EU Service and Invoice Discount
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT and "EU Service" = TRUE
        LibraryVariableStorage.Enqueue(true);
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", true);

        // [GIVEN] Purchase Invoice with Amount = 1000.0
        // [GIVEN] "Invoice Discount Value" was set to 250.0 in Purchase Invoice
        CreatePurchInvoiceWithLocationAndApplyInvoiceDisc(
          PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CreateLocation());

        // [GIVEN] Purchase Invoice was posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportWithoutCorrection(FileName, PurchaseHeader."Posting Date");

        // [THEN] Amount is exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(PurchaseHeader.Amount), 3, 13));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepPurchInvoiceWithInvDiscNoTaxable()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        // [FEATURE] [Purchase] [Invoice Discount] [No Taxable VAT]
        // [SCENARIO 264298] Report "Make 349 Declaration" displays correct Amount for Posted Purchase Invoice with No Taxable VAT, EU Service and Invoice Discount
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT and "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", false);

        // [GIVEN] Purchase Invoice with Amount = 1000.0
        // [GIVEN] "Invoice Discount Value" was set to 250.0 in Purchase Invoice
        LibraryVariableStorage.Enqueue(true);
        CreatePurchInvoiceWithLocationAndApplyInvoiceDisc(
          PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CreateLocation());

        // [GIVEN] Purchase Invoice was posted
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportWithoutCorrection(FileName, PurchaseHeader."Posting Date");

        // [THEN] Amount is exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(PurchaseHeader.Amount), 3, 13));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepSalesInvoiceWithInvDisc()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 264298] Report "Make 349 Declaration" displays correct Amount for Posted Sales Invoice with Invoice Discount, Normal VAT and non-blank Location
        Initialize();

        // [GIVEN] VAT Posting Setup with Normal VAT
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);

        // [GIVEN] Sales Invoice with Amount = 1000.0 and <non-blank> "Location Code"
        // [GIVEN] "Invoice Discount Value" was set to 250.0 in Sales Invoice
        LibraryVariableStorage.Enqueue(true);
        CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(
          SalesHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CreateLocation(), false);

        // [GIVEN] Sales Invoice was posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportWithoutCorrection(FileName, SalesHeader."Posting Date");

        // [THEN] Amount is exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(SalesHeader.Amount), 3, 13));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepSalesInvoiceWithInvDiscAndBlankLocationCode()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 264298] Report "Make 349 Declaration" displays correct Amount for Posted Sales Invoice with Invoice Discount, Normal VAT and blank Location
        Initialize();

        // [GIVEN] VAT Posting Setup with Normal VAT
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);

        // [GIVEN] Sales Invoice with Amount = 1000.0 and <blank> "Location Code"
        // [GIVEN] "Invoice Discount Value" was set to 250.0 in Sales Invoice
        LibraryVariableStorage.Enqueue(true);
        CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(
          SalesHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', false);

        // [GIVEN] Purchase Invoice was posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportWithoutCorrection(FileName, SalesHeader."Posting Date");

        // [THEN] Amount is exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(SalesHeader.Amount), 3, 13));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepSalesInvoiceWithInvDiscNoTaxableEUService()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Invoice Discount] [No Taxable VAT] [EU Service]
        // [SCENARIO 264298] Report "Make 349 Declaration" displays correct Amount for Posted Sales Invoice with No Taxable VAT, EU Service, Invoice Discount and non-blank Location
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT and "EU Service" = TRUE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", true);

        // [GIVEN] Sales Invoice with Amount = 1000.0 and <non-blank> "Location Code"
        // [GIVEN] "Invoice Discount Value" was set to 250.0 in Sales Invoice
        LibraryVariableStorage.Enqueue(true);
        CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(
          SalesHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CreateLocation(), false);

        // [GIVEN] Sales Invoice was posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportWithoutCorrection(FileName, SalesHeader."Posting Date");

        // [THEN] Amount is exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(SalesHeader.Amount), 3, 13));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepSalesInvoiceWithInvDiscNoTaxableEU3PartyTrade()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Invoice Discount] [No Taxable VAT] [EU-3 Party Trade]
        // [SCENARIO 264298] Report "Make 349 Declaration" displays correct Amount for Posted Sales Invoice with No Taxable VAT, EU-3 Party Trade, Invoice Discount and non-blank Location when "EU Service" = FALSE
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT and "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", false);

        // [GIVEN] Sales Invoice with Amount = 1000.0 and <non-blank> "Location Code" and "EU-3 Party Trade" = TRUE
        // [GIVEN] "Invoice Discount Value" was set to 250.0 in Sales Invoice
        LibraryVariableStorage.Enqueue(true);
        CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(
          SalesHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CreateLocation(), true);

        // [GIVEN] Sales Invoice was posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportWithoutCorrection(FileName, SalesHeader."Posting Date");

        // [THEN] Amount is exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(SalesHeader.Amount), 3, 13));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure Make349DeclarationRepSalesInvoiceWithInvDiscNoTaxable()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Invoice Discount] [No Taxable VAT]
        // [SCENARIO 264298] Report "Make 349 Declaration" displays correct Amount for Posted Sales Invoice with No Taxable VAT, Invoice Discount and non-blank Location when "EU Service" = FALSE
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT and "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", false);

        // [GIVEN] Sales Invoice with Amount = 1000.0 and <non-blank> "Location Code" and "EU-3 Party Trade" = FALSE
        // [GIVEN] "Invoice Discount Value" was set to 250.0 in Sales Invoice
        LibraryVariableStorage.Enqueue(true);
        CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(
          SalesHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CreateLocation(), false);

        // [GIVEN] Sales Invoice was posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportWithoutCorrection(FileName, SalesHeader."Posting Date");

        // [THEN] Amount is exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(SalesHeader.Amount), 3, 13));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationWithCorrectionPurchNoEUNoTaxable()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        Make349Declaration: Report "Make 349 Declaration";
        ItemNo: Code[20];
        PostedInvNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Purchase] [Customer/Vendor Warning] [No Taxable VAT]
        // [SCENARIO 266198] Report "Make 349 Declaration" displays correct Amount for Corrected Posted Purchase Invoice with No Taxable VAT when "EU Service" is FALSE
        Initialize();

        // [GIVEN] VAT Posting Setup with "No Taxable VAT" and "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", false);

        // [GIVEN] Posted Purchase Invoice "I" with Amount = 1000.0 and "EU-3 Party Trade" = FALSE
        CreatePurchInvoiceWithLocationAndApplyInvoiceDisc(
          PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '');
        ItemNo := GetItemFromPurchDoc(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PostedInvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted Purchase Credit Memo with Amount <> 0 and "Corrected Invoice No." = "I"
        CreateAndPostCorrectivePurchCrMemo(PurchaseHeader."Buy-from Vendor No.", ItemNo, PurchaseHeader."Posting Date", PostedInvNo);

        // [GIVEN] Stan ran report "Make 349 Declaration", confirmed Correction and marked Include Correction = "Yes" for Customer/Vendor Warning on page Customer/Vendor Warnings 349
        RunMake349DeclarationReportWithCorrection(FileName, PurchaseHeader."Posting Date", PurchaseHeader."Buy-from Vendor No.", 0);

        // [WHEN] Stan pushes "Process" on page ribbon and opens generated file

        // [THEN] File has Amount exported to position 134 as formatted value of 1000.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(PurchaseHeader.Amount), 3, 13));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationWithCorrectionPurchNoEU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        Make349Declaration: Report "Make 349 Declaration";
        ItemNo: Code[20];
        PostedInvNo: Code[20];
        FileName: Text;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Customer/Vendor Warning]
        // [SCENARIO 266198] Report "Make 349 Declaration" displays correct Amount for Corrected Posted Purchase Invoice when "EU Service" is FALSE
        Initialize();

        // [GIVEN] VAT Posting Setup with "Normal VAT" and "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);

        // [GIVEN] Posted Purchase Invoice "I" with Amount = 1000.0
        CreatePurchInvoiceWithLocationAndApplyInvoiceDisc(
          PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '');
        ItemNo := GetItemFromPurchDoc(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PostedInvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Amount := PurchaseHeader.Amount;

        // [GIVEN] Posted Purchase Credit Memo with Amount = 250.0 and "Corrected Invoice No." = "I"
        Amount -=
          CreateAndPostCorrectivePurchCrMemo(PurchaseHeader."Buy-from Vendor No.", ItemNo, PurchaseHeader."Posting Date", PostedInvNo);

        // [GIVEN] Stan ran report "Make 349 Declaration", confirmed Correction and marked Include Correction = "Yes" for Customer/Vendor Warning on page Customer/Vendor Warnings 349
        RunMake349DeclarationReportWithCorrection(FileName, PurchaseHeader."Posting Date", PurchaseHeader."Buy-from Vendor No.", 0);

        // [WHEN] Stan pushes "Process" on page ribbon and opens generated file

        // [THEN] File has Amount exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(Amount), 3, 13));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationWithCorrectionPurchNoEUWithManualCorrection()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        Make349Declaration: Report "Make 349 Declaration";
        ItemNo: Code[20];
        PostedInvNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Purchase] [Customer/Vendor Warning] [Original Declared Amount]
        // [SCENARIO 266198] Report "Make 349 Declaration" displays correct Amount for Corrected Posted Purchase Invoice when "EU Service" is FALSE
        // [SCENARIO 266198] when Stan changed Original Declared Amount on page Customer/Vendor Warnings 349
        Initialize();

        // [GIVEN] VAT Posting Setup with "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);

        // [GIVEN] Posted Purchase Invoice "I" with Amount = 1000.0
        CreatePurchInvoiceWithLocationAndApplyInvoiceDisc(
          PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '');
        ItemNo := GetItemFromPurchDoc(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PostedInvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted Purchase Credit Memo with Amount = 666.6 and "Corrected Invoice No." = "I"
        CreateAndPostCorrectivePurchCrMemo(PurchaseHeader."Buy-from Vendor No.", ItemNo, PurchaseHeader."Posting Date", PostedInvNo);

        // [GIVEN] Stan ran report "Make 349 Declaration", confirmed Correction, set Original Declared Amount = 300 and Include Correction = "Yes" on page Customer/Vendor Warnings 349
        RunMake349DeclarationReportWithCorrection(
          FileName, PurchaseHeader."Posting Date", PurchaseHeader."Buy-from Vendor No.", PurchaseHeader.Amount / 4);

        // [WHEN] Stan pushes "Process" on page ribbon and opens generated file

        // [THEN] File has Amount exported to position 134 as formatted value of 700.00 = 1000.0 - 300.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000070000')
        VerifyValuesOnGeneratedTextFile(
          FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(PurchaseHeader.Amount - Round(PurchaseHeader.Amount / 4)), 3, 13));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationWithCorrectionSalesNoEUNoTaxable()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        Make349Declaration: Report "Make 349 Declaration";
        ItemNo: Code[20];
        PostedInvNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Customer/Vendor Warning] [No Taxable VAT]
        // [SCENARIO 266198] Report "Make 349 Declaration" displays correct Amount for Corrected Posted Sales Invoice with No Taxable VAT when EU-3 Party Trade and "EU Service" are both FALSE
        Initialize();

        // [GIVEN] VAT Posting Setup with "No Taxable VAT" and "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", false);

        // [GIVEN] Posted Sales Invoice "I" with Amount = 1000.0 and "EU-3 Party Trade" = FALSE
        CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(
          SalesHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', false);
        ItemNo := GetItemFromSalesDoc(SalesHeader."Document Type", SalesHeader."No.");
        PostedInvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Sales Credit Memo with Amount <> 0 and "Corrected Invoice No." = "I"
        CreateAndPostCorrectiveSalesCrMemo(SalesHeader."Sell-to Customer No.", ItemNo, SalesHeader."Posting Date", PostedInvNo);

        // [GIVEN] Stan ran report "Make 349 Declaration", confirmed Correction and marked Include Correction = "Yes" for Customer/Vendor Warning on page Customer/Vendor Warnings 349
        RunMake349DeclarationReportWithCorrection(FileName, SalesHeader."Posting Date", SalesHeader."Sell-to Customer No.", 0);

        // [WHEN] Stan pushes "Process" on page ribbon and opens generated file

        // [THEN] File has Amount exported to position 134 as formatted value of 1000.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(SalesHeader.Amount), 3, 13));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationWithCorrectionSalesNoEU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        Make349Declaration: Report "Make 349 Declaration";
        ItemNo: Code[20];
        PostedInvNo: Code[20];
        FileName: Text;
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Customer/Vendor Warning]
        // [SCENARIO 266198] Report "Make 349 Declaration" displays correct Amount for Corrected Posted Sales Invoice when EU-3 Party Trade and "EU Service" are both FALSE
        Initialize();

        // [GIVEN] VAT Posting Setup with "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);

        // [GIVEN] Posted Sales Invoice "I" with Amount = 1000.0 and "EU-3 Party Trade" = FALSE
        CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(
          SalesHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', false);
        ItemNo := GetItemFromSalesDoc(SalesHeader."Document Type", SalesHeader."No.");
        PostedInvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Amount := SalesHeader.Amount;

        // [GIVEN] Posted Sales Credit Memo with Amount = 250.0 and "Corrected Invoice No." = "I"
        Amount -= CreateAndPostCorrectiveSalesCrMemo(SalesHeader."Sell-to Customer No.", ItemNo, SalesHeader."Posting Date", PostedInvNo);

        // [GIVEN] Stan ran report "Make 349 Declaration", confirmed Correction and marked Include Correction = "Yes" for Customer/Vendor Warning on page Customer/Vendor Warnings 349
        RunMake349DeclarationReportWithCorrection(FileName, SalesHeader."Posting Date", SalesHeader."Sell-to Customer No.", 0);

        // [WHEN] Stan pushes "Process" on page ribbon and opens generated file

        // [THEN] File has Amount exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(Amount), 3, 13));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationWithCorrectionSalesNoEUWithManualCorrection()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        Make349Declaration: Report "Make 349 Declaration";
        ItemNo: Code[20];
        PostedInvNo: Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Sales] [Customer/Vendor Warning] [Original Declared Amount]
        // [SCENARIO 266198] Report "Make 349 Declaration" displays correct Amount for Corrected Posted Sales Invoice when EU-3 Party Trade and "EU Service" are both FALSE
        // [SCENARIO 266198] when Stan changed Original Declared Amount on page Customer/Vendor Warnings 349
        Initialize();

        // [GIVEN] VAT Posting Setup with "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);

        // [GIVEN] Posted Sales Invoice "I" with Amount = 1000.0 and "EU-3 Party Trade" = FALSE
        CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(
          SalesHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', false);
        ItemNo := GetItemFromSalesDoc(SalesHeader."Document Type", SalesHeader."No.");
        PostedInvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Sales Credit Memo with Amount = 666.6 and "Corrected Invoice No." = "I"
        CreateAndPostCorrectiveSalesCrMemo(SalesHeader."Sell-to Customer No.", ItemNo, SalesHeader."Posting Date", PostedInvNo);

        // [GIVEN] Stan ran report "Make 349 Declaration", confirmed Correction and set Original Declared Amount = -300 and Include Correction = "Yes" on page Customer/Vendor Warnings 349
        RunMake349DeclarationReportWithCorrection(
          FileName, SalesHeader."Posting Date", SalesHeader."Sell-to Customer No.", -SalesHeader.Amount / 4);

        // [WHEN] Stan pushes "Process" on page ribbon and opens generated file

        // [THEN] File has Amount exported to position 134 as formatted value of 700.00 = 1000.0 - 300.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000070000')
        VerifyValuesOnGeneratedTextFile(
          FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(SalesHeader.Amount - Round(SalesHeader.Amount / 4)), 3, 13));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationWithCorrectionServiceNoEU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        Make349Declaration: Report "Make 349 Declaration";
        ItemNo: Code[20];
        FileName: Text;
        InvAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Service] [Customer/Vendor Warning]
        // [SCENARIO 267007] Report "Make 349 Declaration" displays correct Amount for Corrected Posted Service Invoice when EU-3 Party Trade and "EU Service" are both FALSE and correction is done in the same period
        Initialize();

        // [GIVEN] VAT Posting Setup with "EU Service" = FALSE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);

        // [GIVEN] Posted Service Invoice "I" with Amount = 1000.0 and "EU-3 Party Trade" = FALSE, Posting Date = 04/23/2018
        CreateServiceInvoice(
          ServiceHeader, InvAmount, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", false);
        ItemNo := GetItemFromServiceDoc(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [GIVEN] Posted Service Credit Memo with Amount = 250.0 and "Corrected Invoice No." = "I", Posting Date = 04/30/2018
        CreateCorrectiveServiceCrMemo(
          ServiceHeader, CrMemoAmount, ServiceHeader."Customer No.", ItemNo, CalcDate('<CM>', ServiceHeader."Posting Date"),
          ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [GIVEN] Stan ran report "Make 349 Declaration", confirmed Correction and marked Include Correction = "Yes" for Customer/Vendor Warning on page Customer/Vendor Warnings 349
        RunMake349DeclarationReportWithCorrection(FileName, ServiceHeader."Posting Date", ServiceHeader."Customer No.", 0);

        // [WHEN] Stan pushes "Process" on page ribbon and opens generated file

        // [THEN] File has Amount exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(InvAmount - CrMemoAmount), 3, 13));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationWithCorrectionPurchEU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        Make349Declaration: Report "Make 349 Declaration";
        ItemNo: Code[20];
        PostedInvNo: Code[20];
        FileName: Text;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Customer/Vendor Warning] [EU Service]
        // [SCENARIO 269778] Report "Make 349 Declaration" displays correct Amount for Corrected Posted Purchase Invoice when "EU Service" is TRUE
        Initialize();

        // [GIVEN] VAT Posting Setup with "EU Service" = TRUE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", true);

        // [GIVEN] Posted Purchase Invoice "I" with Amount = 1000.0
        CreatePurchInvoiceWithLocationAndApplyInvoiceDisc(
          PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '');
        ItemNo := GetItemFromPurchDoc(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Amount := PurchaseHeader.Amount;
        PostedInvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted Purchase Credit Memo with Amount = 250.0 and "Corrected Invoice No." = "I"
        Amount -=
          CreateAndPostCorrectivePurchCrMemo(PurchaseHeader."Buy-from Vendor No.", ItemNo, PurchaseHeader."Posting Date", PostedInvNo);

        // [GIVEN] Stan ran report "Make 349 Declaration", confirmed Correction and marked Include Correction = "Yes" for Customer/Vendor Warning on page Customer/Vendor Warnings 349
        RunMake349DeclarationReportWithCorrection(FileName, PurchaseHeader."Posting Date", PurchaseHeader."Buy-from Vendor No.", 0);

        // [WHEN] Stan pushes "Process" on page ribbon and opens generated file

        // [THEN] File has Amount exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(Amount), 3, 13));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationWithCorrectionSalesEU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        Make349Declaration: Report "Make 349 Declaration";
        ItemNo: Code[20];
        PostedInvNo: Code[20];
        FileName: Text;
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Customer/Vendor Warning] [EU Service]
        // [SCENARIO 269778] Report "Make 349 Declaration" displays correct Amount for Corrected Posted Sales Invoice when "EU Service" is TRUE
        Initialize();

        // [GIVEN] VAT Posting Setup with "EU Service" = TRUE
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", true);

        // [GIVEN] Posted Sales Invoice "I" with Amount = 1000.0
        CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(
          SalesHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', false);
        ItemNo := GetItemFromSalesDoc(SalesHeader."Document Type", SalesHeader."No.");
        Amount := SalesHeader.Amount;
        PostedInvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Sales Credit Memo with Amount = 250.0 and "Corrected Invoice No." = "I"
        Amount -= CreateAndPostCorrectiveSalesCrMemo(SalesHeader."Sell-to Customer No.", ItemNo, SalesHeader."Posting Date", PostedInvNo);

        // [GIVEN] Stan ran report "Make 349 Declaration", confirmed Correction and marked Include Correction = "Yes" for Customer/Vendor Warning on page Customer/Vendor Warnings 349
        RunMake349DeclarationReportWithCorrection(FileName, SalesHeader."Posting Date", SalesHeader."Sell-to Customer No.", 0);

        // [WHEN] Stan pushes "Process" on page ribbon and opens generated file

        // [THEN] File has Amount exported to position 134 as formatted value of 750.00 = 1000.0 - 250.0 with separator symbol removed, extended to length 13 and prefixed by zeroes ('0000000075000')
        VerifyValuesOnGeneratedTextFile(FileName, 134, CopyStr(Make349Declaration.FormatTextAmt(Amount), 3, 13));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationPurchInvNoTaxable()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DummyPurchaseHeader: Record "Purchase Header";
        CountryRegionCode: array[2] of Code[10];
        VendorNo: array[2] of Code[20];
        FileName: Text;
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Invoice] [No Taxable VAT] [Country/Region]
        // [SCENARIO 270952] Report "Make 349 Declaration" doesn't include Posted Purchase Invoice when posted with foreign Country having <blank> "EU Country/Region Code"
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Posting Setup with "No Taxable VAT"
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", true);

        // [GIVEN] Post Purchase Invoice for Vendor "V1" with Country/Region having <blank> "EU Country/Region Code"
        // [GIVEN] Post Purchase Invoice for Vendor "V2" with Country/Region having <non-blank> "EU Country/Region Code"
        CountryRegionCode[1] := CreateCountryRegionNotEU();
        CountryRegionCode[2] := CreateCountryRegion();
        PrepareEUAndForeignVendorAndPostPurchDocs(
          VendorNo, VATPostingSetup, DummyPurchaseHeader."Document Type"::Invoice, CountryRegionCode, PostingDate);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportSimple(FileName, PostingDate);

        // [THEN] Vendor "V1" has no entry in export file
        VerifyValueNotPresentInGeneratedTextFile(FileName, 93, VendorNo[1]);

        // [THEN] Vendor "V2" has entry in export file
        VerifyValuesOnGeneratedTextFile(FileName, 93, VendorNo[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationSalesInvNoTaxable()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DummySalesHeader: Record "Sales Header";
        CountryRegionCode: array[2] of Code[10];
        CustNo: array[2] of Code[20];
        FileName: Text;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Invoice] [No Taxable VAT] [Country/Region]
        // [SCENARIO 270952] Report "Make 349 Declaration" doesn't include Posted Sales Invoice when posted with foreign Country having <blank> "EU Country/Region Code"
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Posting Setup with "No Taxable VAT"
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", true);

        // [GIVEN] Post Sales Invoice for Customer "C1" with Country/Region having <blank> "EU Country/Region Code"
        // [GIVEN] Post Sales Invoice for Customer "C2" with Country/Region having <non-blank> "EU Country/Region Code"
        CountryRegionCode[1] := CreateCountryRegionNotEU();
        CountryRegionCode[2] := CreateCountryRegion();
        PrepareEUAndForeignCustomerAndPostSalesDocs(
          CustNo, VATPostingSetup, DummySalesHeader."Document Type"::Invoice, CountryRegionCode, PostingDate);

        // [WHEN] Run report "Make 349 Declaration"
        RunMake349DeclarationReportSimple(FileName, PostingDate);

        // [THEN] Customer "C1" has no entry in export file
        VerifyValueNotPresentInGeneratedTextFile(FileName, 93, CustNo[1]);

        // [THEN] Customer "C2" has entry in export file
        VerifyValuesOnGeneratedTextFile(FileName, 93, CustNo[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349IncludeAllEntriesModalPageHandler,ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationPurchCrMemoNoTaxable()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DummyPurchaseHeader: Record "Purchase Header";
        CountryRegionCode: array[2] of Code[10];
        VendorNo: array[2] of Code[20];
        FileName: Text;
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [No Taxable VAT] [Country/Region]
        // [SCENARIO 270952] Report "Make 349 Declaration" doesn't include Posted Purchase Cr. Memo when posted with foreign Country having <blank> "EU Country/Region Code"
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Posting Setup with "No Taxable VAT"
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", true);

        // [GIVEN] Post Purchase Credit Memo for Vendor "V1" with Country/Region having <blank> "EU Country/Region Code"
        // [GIVEN] Post Purchase Credit Memo for Vendor "V2" with Country/Region having <non-blank> "EU Country/Region Code"
        CountryRegionCode[1] := CreateCountryRegionNotEU();
        CountryRegionCode[2] := CreateCountryRegion();
        PrepareEUAndForeignVendorAndPostPurchDocs(
          VendorNo, VATPostingSetup, DummyPurchaseHeader."Document Type"::"Credit Memo", CountryRegionCode, PostingDate);

        // [WHEN] Run report "Make 349 Declaration" with correction
        RunMake349DeclarationReportSimple(FileName, PostingDate);

        // [THEN] Vendor "V1" has no entry in export file
        VerifyValueNotPresentInGeneratedTextFile(FileName, 93, VendorNo[1]);

        // [THEN] Vendor "V2" has entry in export file
        VerifyValuesOnGeneratedTextFile(FileName, 93, VendorNo[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349IncludeAllEntriesModalPageHandler,ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Make349DeclarationSalesCrMemoNoTaxable()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DummySalesHeader: Record "Sales Header";
        CountryRegionCode: array[2] of Code[10];
        CustNo: array[2] of Code[20];
        FileName: Text;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Credit Memo] [No Taxable VAT] [Country/Region]
        // [SCENARIO 270952] Report "Make 349 Declaration" doesn't include Posted Sales Cr. Memo when posted with foreign Country having <blank> "EU Country/Region Code"
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Posting Setup with "No Taxable VAT"
        CreateVATPostingSetupWithCalculationType(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", true);

        // [GIVEN] Post Sales Credit Memo for Customer "C1" with Country/Region having <blank> "EU Country/Region Code"
        // [GIVEN] Post Sales Credit Memo for Customer "C2" with Country/Region having <non-blank> "EU Country/Region Code"
        CountryRegionCode[1] := CreateCountryRegionNotEU();
        CountryRegionCode[2] := CreateCountryRegion();
        PrepareEUAndForeignCustomerAndPostSalesDocs(
          CustNo, VATPostingSetup, DummySalesHeader."Document Type"::"Credit Memo", CountryRegionCode, PostingDate);

        // [WHEN] Run report "Make 349 Declaration" with correction
        RunMake349DeclarationReportSimple(FileName, PostingDate);

        // [THEN] Customer "C1" has no entry in export file
        VerifyValueNotPresentInGeneratedTextFile(FileName, 93, CustNo[1]);

        // [THEN] Customer "C2" has entry in export file
        VerifyValuesOnGeneratedTextFile(FileName, 93, CustNo[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNoTaxableAmountSalesForeignWithBlankEUCountryRegion()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        NormalAmount: Decimal;
        AmountEUService: Decimal;
        AmountOpTri: Decimal;
    begin
        // [FEATURE] [UT] [Sales] [No Taxable VAT] [Country/Region]
        // [SCENARIO 270952] CalcNoTaxableAmount returns <zero> if Sales Invoice was posted with foreign Country/Region having <blank> "EU Country/Region Code"
        Initialize();

        // [GIVEN] Country/Region "C" with <blank> EU Country/Region Code
        // [GIVEN] Posted Sales Invoice with Bill-to Country/Region Code = "C", VAT Calculation Type = "No Taxable VAT"
        MockPostedSalesInvoiceNoTaxableWithCountry(SalesInvoiceLine, CreateCountryRegionNotEU());

        // [WHEN] Call CalcNoTaxableAmount for Sales Invoice Line with NormalAmount,AmountEUService and AmountOpTri all <zero>
        NoTaxableMgt.CalcNoTaxableAmountCustomerSimple(NormalAmount, AmountEUService, AmountOpTri, '', 0D, 0D, '');

        // [THEN] NormalAmount,AmountEUService and AmountOpTri are all <zero>
        Assert.AreEqual(NormalAmount, 0, '');
        Assert.AreEqual(AmountOpTri, 0, '');
        Assert.AreEqual(AmountEUService, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNoTaxableAmountSalesDomestic()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        NormalAmount: Decimal;
        AmountEUService: Decimal;
        AmountOpTri: Decimal;
    begin
        // [FEATURE] [UT] [Sales] [No Taxable VAT] [Country/Region]
        // [SCENARIO 270952] CalcNoTaxableAmount returns <zero> if Sales Invoice was posted with native Country/Region
        Initialize();

        // [GIVEN] Company Information had Country/Region Code = "C"
        // [GIVEN] Posted Sales Invoice with Bill-to Country/Region Code = "C", VAT Calculation Type = "No Taxable VAT"
        MockPostedSalesInvoiceNoTaxableWithCountry(SalesInvoiceLine, GetCountryRegionFromCompanyInfo());

        // [WHEN] Call CalcNoTaxableAmount for Sales Invoice Line with NormalAmount,AmountEUService and AmountOpTri all <zero>
        NoTaxableMgt.CalcNoTaxableAmountCustomerSimple(NormalAmount, AmountEUService, AmountOpTri, '', 0D, 0D, '');

        // [THEN] NormalAmount,AmountEUService and AmountOpTri are all <zero>
        Assert.AreEqual(NormalAmount, 0, '');
        Assert.AreEqual(AmountOpTri, 0, '');
        Assert.AreEqual(AmountEUService, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNoTaxableAmountPurchForeignWithBlankEUCountryRegion()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        NormalAmount: Decimal;
        AmountEUService: Decimal;
    begin
        // [FEATURE] [UT] [Purchase] [No Taxable VAT] [Country/Region]
        // [SCENARIO 270952] CalcNoTaxableAmount returns <zero> if Purchase Invoice was posted with foreign Country/Region having <blank> "EU Country/Region Code"
        Initialize();

        // [GIVEN] Country/Region "C" with <blank> EU Country/Region Code
        // [GIVEN] Posted Purchase Invoice with Bill-to Country/Region Code = "C", VAT Calculation Type = "No Taxable VAT"
        MockPostedPurchInvoiceNoTaxableWithCountry(PurchInvLine, CreateCountryRegionNotEU());

        // [WHEN] Call CalcNoTaxableAmount for Purch. Inv. Line with NormalAmount and AmountEUService both <zero>
        NoTaxableMgt.CalcNoTaxableAmountVendor(NormalAmount, AmountEUService, '', 0D, 0D, '');

        // [THEN] NormalAmount and AmountEUService are both <zero>
        Assert.AreEqual(NormalAmount, 0, '');
        Assert.AreEqual(AmountEUService, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcNoTaxableAmountPurchDomestic()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        NormalAmount: Decimal;
        AmountEUService: Decimal;
    begin
        // [FEATURE] [UT] [Purchase] [No Taxable VAT] [Country/Region]
        // [SCENARIO 270952] CalcNoTaxableAmount returns <zero> if Purchase Invoice was posted with native Country/Region
        Initialize();

        // [GIVEN] Company Information had Country/Region Code = "C"
        // [GIVEN] Posted Purchase Invoice with Bill-to Country/Region Code = "C", VAT Calculation Type = "No Taxable VAT"
        MockPostedPurchInvoiceNoTaxableWithCountry(PurchInvLine, GetCountryRegionFromCompanyInfo());

        // [WHEN] Call CalcNoTaxableAmount for Purch. Inv. Line with NormalAmount and AmountEUService both <zero>
        NoTaxableMgt.CalcNoTaxableAmountVendor(NormalAmount, AmountEUService, '', 0D, 0D, '');

        // [THEN] NormalAmount and AmountEUService are both <zero>
        Assert.AreEqual(NormalAmount, 0, '');
        Assert.AreEqual(AmountEUService, 0, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    [Scope('OnPrem')]
    procedure CustVendWarn349PrevDeclAmtWhenCorrMultipleInvLinesPurch()
    var
        PurchaseHeader: Record "Purchase Header";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
        PostedInvNo: Code[20];
    begin
        // [FEATURE] [UI] [Customer/Vendor Warnings 349] [Purchase]
        // [SCENARIO 417581] When "Original Declaration FY" is changed on Customer/Vendor Warnings 349 page, then Previous Declared Amount is not changed
        // [SCENARIO 417581] even if Purchase Invoice was posted with several lines having different VAT Prod. Posting Groups
        Initialize();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        // [GIVEN] Posted Purchase Invoice with two lines, having different VAT Prod. Posting Groups; Posting Date = 01/02/2018 and Amount = 1000.0
        CreatePurchaseInvoiceTwoLinesWithDiffVATProdPostingGroups(
          PurchaseHeader, Amount, VATBusinessPostingGroup.Code, LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10));
        PostedInvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted Corrective Purchase Credit Memo with Amount = 100.0 and Posting Date = 01/03/2018 (same year, other period)
        CreateVATPostingSetupForBusGroup(VATPostingSetup, VATBusinessPostingGroup.Code);
        CreateAndPostCorrectivePurchCrMemo(
            PurchaseHeader."Buy-from Vendor No.", CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDateFrom(CalcDate('<1M>', PurchaseHeader."Posting Date"), 10), PostedInvNo);

        // [GIVEN] Posted Corrective Purchase Credit Memo with Posting Date = 01/02/2019 (same period, other year)
        CreateAndPostCorrectivePurchCrMemo(
          PurchaseHeader."Buy-from Vendor No.", CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          CalcDate('<1Y>', PurchaseHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Stan Ran Make 340 Declaration with Year = 2019 and Period = 02 (February)
        RunMake349DeclarationReportWithCorrectOrigDeclFYSimple(
          CalcDate('<1Y>', PurchaseHeader."Posting Date"), Date2DMY(PurchaseHeader."Posting Date", 3));

        // [GIVEN] Stan confirmed correction
        // confirmation is done in ConfirmHandler

        // [WHEN] Stan sets value "Original Declaration FY" = 2018 on Customer/Vendor Warnings 349 page
        // value is set in CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY

        // [THEN] Stan sees "Previous Declared Amount" = 1000.0 on Customer/Vendor Warnings 349 page
        Assert.AreEqual(Amount, LibraryVariableStorage.DequeueDecimal(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    [Scope('OnPrem')]
    procedure CustVendWarn349PrevDeclAmtWhenCorrMultipleInvLinesSales()
    var
        SalesHeader: Record "Sales Header";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
        PostedInvNo: Code[20];
    begin
        // [FEATURE] [UI] [Customer/Vendor Warnings 349] [Sales]
        // [SCENARIO 417581] When "Original Declaration FY" is changed on Customer/Vendor Warnings 349 page, then Previous Declared Amount is not changed
        // [SCENARIO 417581] even if Sales Invoice was posted with several lines having different VAT Prod. Posting Groups
        Initialize();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        // [GIVEN] Posted Sales Invoice with two lines, having different VAT Prod. Posting Groups; Posting Date = 01/02/2018 and Amount = 1000.0
        CreateSalesInvoiceTwoLinesWithDiffVATProdPostingGroups(
          SalesHeader, Amount, VATBusinessPostingGroup.Code, LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10));
        PostedInvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Corrective Sales Credit Memo with Amount = 100.0 and Posting Date = 01/03/2018 (same year, other period)
        CreateVATPostingSetupForBusGroup(VATPostingSetup, VATBusinessPostingGroup.Code);
        CreateAndPostCorrectiveSalesCrMemo(
            SalesHeader."Sell-to Customer No.", CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandDateFrom(CalcDate('<1M>', SalesHeader."Posting Date"), 10), PostedInvNo);

        // [GIVEN] Posted Corrective Sales Credit Memo with Posting Date = 01/02/2019 (same period, other year)
        CreateAndPostCorrectiveSalesCrMemo(
          SalesHeader."Sell-to Customer No.", CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          CalcDate('<1Y>', SalesHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Stan Ran Make 340 Declaration with Year = 2019 and Period = 02 (February)
        RunMake349DeclarationReportWithCorrectOrigDeclFYSimple(
          CalcDate('<1Y>', SalesHeader."Posting Date"), Date2DMY(SalesHeader."Posting Date", 3));

        // [GIVEN] Stan confirmed correction
        // confirmation is done in ConfirmHandler

        // [WHEN] Stan sets value "Original Declaration FY" = 2018 on Customer/Vendor Warnings 349 page
        // value is set in CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY

        // [THEN] Stan sees "Previous Declared Amount" = 1000.0 on Customer/Vendor Warnings 349 page
        Assert.AreEqual(Amount, LibraryVariableStorage.DequeueDecimal(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerWithQuarter,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod')]
    [Scope('OnPrem')]
    procedure CustVendWarn349PrevDeclAmtWhenChangeQuarterSales()
    var
        SalesHeader: Record "Sales Header";
        PostedInvNo: Code[20];
        ItemNo: Code[20];
        Amount: Decimal;
        QuarterNo: Integer;
    begin
        // [FEATURE] [UI] [Customer/Vendor Warnings 349] [Sales]
        // [SCENARIO 277864] Previous Declared Amount is calculated correctly for Sales Documents when Stan runs report Make 349 Declaration with Quarter
        // [SCENARIO 277864] and changes Original Declaration Period on Customer/Vendor Warnings 349 page
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount 1000.0 in January (1st Quarter)
        CreateSalesInvoiceWithPostingDate(SalesHeader, LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10));
        Amount := SalesHeader.Amount;
        ItemNo := GetItemFromSalesDoc(SalesHeader."Document Type", SalesHeader."No.");
        QuarterNo := GetQuarterFromDate(SalesHeader."Posting Date");
        PostedInvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Sales Corrective Credit Memo with Amount 100.0 in February (1st Quarter)
        Amount -= CreateAndPostCorrectiveSalesCrMemo(
            SalesHeader."Sell-to Customer No.", ItemNo, CalcDate('<1M>', SalesHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Posted another Sales Corrective Credit Memo in 2nd Quarter
        CreateAndPostCorrectiveSalesCrMemo(
          SalesHeader."Sell-to Customer No.", ItemNo, CalcDate('<1Q>', SalesHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Posted another Sales Invoice in 2nd Quarter
        CreateSalesInvoiceWithPostingDate(SalesHeader, CalcDate('<1Q>', SalesHeader."Posting Date"));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Stan ran report Make 349 Declaration with Year = 2018 and Period = 2nd Quarter and confirmed correction
        RunMake349DeclarationReportWithCorrectOrigDeclPeriod(SalesHeader."Posting Date", StrSubstNo('%1T', QuarterNo));

        // [WHEN] Stan sets value "Original Declaration Period" = 1T on Customer/Vendor Warnings 349 page
        // value is set in CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod

        // [THEN] Stan sees "Previous Declared Amount" = 900.0 on Customer/Vendor Warnings 349 page
        Assert.AreEqual(Amount, LibraryVariableStorage.DequeueDecimal(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerWithQuarter,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod')]
    [Scope('OnPrem')]
    procedure CustVendWarn349PrevDeclAmtWhenChangeQuarterService()
    var
        ServiceHeader: Record "Service Header";
        Amount: Decimal;
        CrMemoAmount: Decimal;
        QuarterNo: Integer;
        ItemNo: Code[20];
        PostedInvNo: Code[20];
    begin
        // [FEATURE] [UI] [Customer/Vendor Warnings 349] [Service]
        // [SCENARIO 277864] Previous Declared Amount is calculated correctly for Service Documents when Stan runs report Make 349 Declaration with Quarter
        // [SCENARIO 277864] and changes Original Declaration Period on Customer/Vendor Warnings 349 page
        Initialize();

        // [GIVEN] Posted Service Invoice with Amount 1000.0 in January (1st Quarter)
        CreateServiceInvoiceWithPostingDate(ServiceHeader, Amount, LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10));
        ItemNo := GetItemFromServiceDoc(ServiceHeader."Document Type", ServiceHeader."No.");
        QuarterNo := GetQuarterFromDate(ServiceHeader."Posting Date");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        PostedInvNo := FindLastServInvNo(ServiceHeader."Customer No.");

        // [GIVEN] Posted Service Corrective Credit Memo with Amount 100.0 in February (1st Quarter)
        CreateCorrectiveServiceCrMemo(
          ServiceHeader, CrMemoAmount, ServiceHeader."Customer No.", ItemNo, CalcDate('<1M>', ServiceHeader."Posting Date"),
          PostedInvNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Amount -= CrMemoAmount;

        // [GIVEN] Posted another Service Corrective Credit Memo in 2nd Quarter
        CreateCorrectiveServiceCrMemo(
          ServiceHeader, CrMemoAmount, ServiceHeader."Customer No.", ItemNo, CalcDate('<1Q>', ServiceHeader."Posting Date"),
          PostedInvNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [GIVEN] Posted another Service Invoice in 2nd Quarter
        CreateServiceInvoiceWithPostingDate(ServiceHeader, CrMemoAmount, ServiceHeader."Posting Date");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [GIVEN] Stan ran report Make 349 Declaration with Year = 2018 and Period = 2nd Quarter and confirmed correction
        RunMake349DeclarationReportWithCorrectOrigDeclPeriod(ServiceHeader."Posting Date", StrSubstNo('%1T', QuarterNo));

        // [WHEN] Stan sets value "Original Declaration Period" = 1T on Customer/Vendor Warnings 349 page
        // value is set in CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod

        // [THEN] Stan sees "Previous Declared Amount" = 900.0 on Customer/Vendor Warnings 349 page
        Assert.AreEqual(Amount, LibraryVariableStorage.DequeueDecimal(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerWithQuarter,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod')]
    [Scope('OnPrem')]
    procedure CustVendWarn349PrevDeclAmtWhenChangeQuarterPurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvNo: Code[20];
        ItemNo: Code[20];
        Amount: Decimal;
        QuarterNo: Integer;
    begin
        // [FEATURE] [UI] [Customer/Vendor Warnings 349] [Purchase]
        // [SCENARIO 277864] Previous Declared Amount is calculated correctly for Purchase Documents when Stan runs report Make 349 Declaration with Quarter
        // [SCENARIO 277864] and changes Original Declaration Period on Customer/Vendor Warnings 349 page
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Amount 1000.0 in January (1st Quarter)
        CreatePurchaseInvoiceWithPostingDate(PurchaseHeader, LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10));
        Amount := PurchaseHeader.Amount;
        ItemNo := GetItemFromPurchDoc(PurchaseHeader."Document Type", PurchaseHeader."No.");
        QuarterNo := GetQuarterFromDate(PurchaseHeader."Posting Date");
        PostedInvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted Purchase Corrective Credit Memo with Amount 100.0 in February (1st Quarter)
        Amount -= CreateAndPostCorrectivePurchCrMemo(
            PurchaseHeader."Buy-from Vendor No.", ItemNo, CalcDate('<1M>', PurchaseHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Posted another Purchase Corrective Credit Memo in 2nd Quarter
        CreateAndPostCorrectivePurchCrMemo(
          PurchaseHeader."Buy-from Vendor No.", ItemNo, CalcDate('<1Q>', PurchaseHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Posted another Purchase Invoice in 2nd Quarter
        CreatePurchaseInvoiceWithPostingDate(PurchaseHeader, CalcDate('<1Q>', PurchaseHeader."Posting Date"));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Stan ran report Make 349 Declaration with Year = 2018 and Period = 2nd Quarter and confirmed correction
        RunMake349DeclarationReportWithCorrectOrigDeclPeriod(PurchaseHeader."Posting Date", StrSubstNo('%1T', QuarterNo));

        // [WHEN] Stan sets value "Original Declaration Period" = 1T on Customer/Vendor Warnings 349 page
        // value is set in CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod

        // [THEN] Stan sees "Previous Declared Amount" = 900.0 on Customer/Vendor Warnings 349 page
        Assert.AreEqual(Amount, LibraryVariableStorage.DequeueDecimal(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerAnnualPeriod,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    [Scope('OnPrem')]
    procedure CustVendWarn349PrevDeclAmtWhenChangeYearSales()
    var
        SalesHeader: Record "Sales Header";
        PostedInvNo: Code[20];
        ItemNo: Code[20];
        Amount: Decimal;
        Year: Integer;
    begin
        // [FEATURE] [UI] [Customer/Vendor Warnings 349] [Sales]
        // [SCENARIO 277864] Previous Declared Amount is calculated correctly for Sales Documents when Stan runs report Make 349 Declaration for Annual period
        // [SCENARIO 277864] and changes Original Declaration FY on Customer/Vendor Warnings 349 page
        Initialize();

        // [GIVEN] Posted Sales Invoice with Amount 1000.0 in January, 2018
        CreateSalesInvoiceWithPostingDate(SalesHeader, LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10));
        Amount := SalesHeader.Amount;
        ItemNo := GetItemFromSalesDoc(SalesHeader."Document Type", SalesHeader."No.");
        Year := Date2DMY(SalesHeader."Posting Date", 3);
        PostedInvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Sales Corrective Credit Memo with Amount 100.0 in February, 2018
        Amount -= CreateAndPostCorrectiveSalesCrMemo(
            SalesHeader."Sell-to Customer No.", ItemNo, CalcDate('<1M>', SalesHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Posted another Sales Corrective Credit Memo in March, 2019
        CreateAndPostCorrectiveSalesCrMemo(
          SalesHeader."Sell-to Customer No.", ItemNo, CalcDate('<1Y+2M>', SalesHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Posted another Sales Invoice in 2019
        CreateSalesInvoiceWithPostingDate(SalesHeader, CalcDate('<1Y>', SalesHeader."Posting Date"));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Stan ran report Make 349 Declaration with Year = 2019 and Period = Annual and confirmed correction
        RunMake349DeclarationReportWithCorrectOrigDeclFY(SalesHeader."Posting Date", Year);

        // [WHEN] Stan sets value "Original Declaration FY" = 2018 on Customer/Vendor Warnings 349 page
        // value is set in CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod

        // [THEN] Stan sees "Previous Declared Amount" = 900.0 on Customer/Vendor Warnings 349 page
        Assert.AreEqual(Amount, LibraryVariableStorage.DequeueDecimal(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerAnnualPeriod,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    [Scope('OnPrem')]
    procedure CustVendWarn349PrevDeclAmtWhenChangeYearService()
    var
        ServiceHeader: Record "Service Header";
        ItemNo: Code[20];
        Amount: Decimal;
        CrMemoAmount: Decimal;
        Year: Integer;
        PostedInvNo: Code[20];
    begin
        // [FEATURE] [UI] [Customer/Vendor Warnings 349] [Service]
        // [SCENARIO 277864] Previous Declared Amount is calculated correctly for Service Documents when Stan runs report Make 349 Declaration for Annual period
        // [SCENARIO 277864] and changes Original Declaration FY on Customer/Vendor Warnings 349 page
        Initialize();

        // [GIVEN] Posted Service Invoice with Amount 1000.0 in January, 2018
        CreateServiceInvoiceWithPostingDate(ServiceHeader, Amount, LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10));
        ItemNo := GetItemFromServiceDoc(ServiceHeader."Document Type", ServiceHeader."No.");
        Year := Date2DMY(ServiceHeader."Posting Date", 3);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        PostedInvNo := FindLastServInvNo(ServiceHeader."Customer No.");

        // [GIVEN] Posted Service Corrective Credit Memo with Amount 100.0 in February, 2018
        CreateCorrectiveServiceCrMemo(
          ServiceHeader, CrMemoAmount, ServiceHeader."Customer No.", ItemNo, CalcDate('<1M>', ServiceHeader."Posting Date"),
          PostedInvNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Amount -= CrMemoAmount;

        // [GIVEN] Posted another Service Corrective Credit Memo in March, 2019
        CreateCorrectiveServiceCrMemo(
          ServiceHeader, CrMemoAmount, ServiceHeader."Customer No.", ItemNo, CalcDate('<1Y+2M>', ServiceHeader."Posting Date"),
          PostedInvNo);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [GIVEN] Posted another Service Invoice in 2nd Quarter
        CreateServiceInvoiceWithPostingDate(ServiceHeader, CrMemoAmount, ServiceHeader."Posting Date");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [GIVEN] Stan ran report Make 349 Declaration with Year = 2018 and Period = 2nd Quarter and confirmed correction
        RunMake349DeclarationReportWithCorrectOrigDeclFY(ServiceHeader."Posting Date", Year);

        // [WHEN] Stan sets value "Original Declaration Period" = 1T on Customer/Vendor Warnings 349 page
        // value is set in CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod

        // [THEN] Stan sees "Previous Declared Amount" = 900.0 on Customer/Vendor Warnings 349 page
        Assert.AreEqual(Amount, LibraryVariableStorage.DequeueDecimal(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerAnnualPeriod,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    [Scope('OnPrem')]
    procedure CustVendWarn349PrevDeclAmtWhenChangeYearPurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        InsertedPurchaseLine: Record "Purchase Line";
        PostingDate: Date;
        PostedInvNo: Code[20];
        ItemNo: Code[20];
        Amount: Decimal;
        Year: Integer;
    begin
        // [FEATURE] [UI] [Customer/Vendor Warnings 349] [Purchase]
        // [SCENARIO 277864] Previous Declared Amount is calculated correctly for Purchase Documents when Stan runs report Make 349 Declaration for Annual period
        // [SCENARIO 277864] and changes Original Declaration FY on Customer/Vendor Warnings 349 page
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10);

        // [GIVEN] Posted Purchase Invoice with Amount 1000.0 in January, 2018
        CreatePurchaseInvoiceWithPostingDate(PurchaseHeader, PostingDate);
        Amount := PurchaseHeader.Amount;
        ItemNo := GetItemFromPurchDoc(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Year := Date2DMY(PurchaseHeader."Posting Date", 3);

        // Bug: 433917
        InsertPurchaseLineWithDifferentPostingGroups(PurchaseHeader, InsertedPurchaseLine);

        PostedInvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted Purchase Corrective Credit Memo with Amount 100.0 in February, 2018
        Amount -= CreateAndPostCorrectivePurchCrMemo(
            PurchaseHeader."Buy-from Vendor No.", ItemNo, CalcDate('<1M>', PurchaseHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Posted another Purchase Corrective Credit Memo in March, 2019
        CreateAndPostCorrectivePurchCrMemo(
          PurchaseHeader."Buy-from Vendor No.", ItemNo, CalcDate('<1Y+2M>', PurchaseHeader."Posting Date"), PostedInvNo);

        // [GIVEN] Posted another Purchase Invoice in 2019
        CreatePurchaseInvoiceWithPostingDate(PurchaseHeader, CalcDate('<1Y>', PurchaseHeader."Posting Date"));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Stan ran report Make 349 Declaration with Year = 2019 and Period = Annual and confirmed correction
        // [GIVEN] Set "Exclude Gen. Product Posting Group" = "GPPG-1"
        RunMake349DeclarationReportWithCorrectOrigDeclFY(PurchaseHeader."Posting Date", Year, InsertedPurchaseLine."Gen. Prod. Posting Group");

        // [WHEN] Stan sets value "Original Declaration FY" = 2018 on Customer/Vendor Warnings 349 page
        // value is set in CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod

        // [THEN] Stan sees "Previous Declared Amount" = 900.0 on Customer/Vendor Warnings 349 page
        Assert.AreEqual(Amount, LibraryVariableStorage.DequeueDecimal(), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    procedure SalesCreditMemoWithoutCorrectiveInvoiceDeliveryOperationCodeBlank()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
    begin
        // [SCEARIO 439176] Run Make 349 report on Sales Credit Memo with blank Corrected Invoice No. when Delivery Operation Code is blank.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24, Amount 200 and blank "Corrected Invoice No.".
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, '', '', false, PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedSalesCrMemo(SalesCrMemoHeader);
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Date2DMY(PostingDate, 3));
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "E" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'E', PostingDate, 0, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.DequeueDecimal();    // Previous Declared Amount
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    procedure SalesCreditMemoWithoutCorrectiveInvoiceDeliveryOperationCodeH()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCEARIO 439176] Run Make 349 report on Sales Credit Memo with blank Corrected Invoice No. when Delivery Operation Code is "H".
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = "H".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::"H - Imported Tax Exempt (Representative)");

        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24, Amount 200 and blank "Corrected Invoice No.".
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, '', '', false, PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedSalesCrMemo(SalesCrMemoHeader);
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Date2DMY(PostingDate, 3));
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "H" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'H', PostingDate, 0, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.DequeueDecimal();    // Previous Declared Amount
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    procedure SalesCreditMemoWithoutCorrectiveInvoiceEUService()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 439176] Run Make 349 report on Sales Credit Memo with blank Corrected Invoice No. when EU Service is set.
        // [SCENARIO 455095] Previous Declared Amount is not zero for Sales Credit Memo with blank Corrected Invoice No.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with EU Service = true and Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, true);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24, Amount 200 and blank "Corrected Invoice No.".
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, '', '', false, PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedSalesCrMemo(SalesCrMemoHeader);
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Date2DMY(PostingDate, 3));
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "S" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'S', PostingDate, 0, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.DequeueDecimal();    // Previous Declared Amount
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure SalesCreditMemoWithoutCorrectiveInvoiceEUServiceSetOrigDeclaredAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 439176] Run Make 349 report on Sales Credit Memo with blank Corrected Invoice No. when EU Service is set and Original Declared Amount is specified.
        // [SCENARIO 455095] Previous Declared Amount is not zero for Sales Credit Memo with blank Corrected Invoice No.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);
        OriginalDeclaredAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        // [GIVEN] VAT Prod. Posting Group with EU Service = true and Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, true);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24, Amount 200 and blank "Corrected Invoice No.".
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, '', '', false, PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedSalesCrMemo(SalesCrMemoHeader);
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction and Original Declared Amount 1000 for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDate, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "S" + 13 spaces + year(2024) + month(02) + Original Declared Amount(1000) + Previous Declared Amount(0 - 200 = -200).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'S', PostingDate, OriginalDeclaredAmount, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    procedure SalesCreditMemoWithoutCorrectiveInvoiceEU3PartyTrade()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
    begin
        // [FEATURE] [Sales] [EU 3-Party Trade]
        // [SCENARIO 439176] Run Make 349 report on Sales Credit Memo with blank Corrected Invoice No. when EU 3-Party Trade is set.
        // [SCENARIO 455095] Previous Declared Amount is not zero for Sales Credit Memo with blank Corrected Invoice No.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24, Amount 200, "EU 3-Party Trade" set and blank "Corrected Invoice No.".
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, '', '', true, PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedSalesCrMemo(SalesCrMemoHeader);
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Date2DMY(PostingDate, 3));
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "T" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'T', PostingDate, 0, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.DequeueDecimal();    // Previous Declared Amount
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure SalesCreditMemoWithoutCorrectiveInvoiceEU3PartyTradeSetOrigDeclaredAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Sales] [EU 3-Party Trade]
        // [SCENARIO 439176] Run Make 349 report on Sales Credit Memo with blank Corrected Invoice No. when EU 3-Party Trade is set and Original Declared Amount is specified.
        // [SCENARIO 455095] Previous Declared Amount is not zero for Sales Credit Memo with blank Corrected Invoice No.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);
        OriginalDeclaredAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24, Amount 200, "EU 3-Party Trade" set and blank "Corrected Invoice No.".
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, '', '', true, PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedSalesCrMemo(SalesCrMemoHeader);
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction and Original Declared Amount 1000 for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDate, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "T" + 13 spaces + year(2024) + month(02) + Original Declared Amount(1000) + Previous Declared Amount(0 - 200 = -200).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'T', PostingDate, OriginalDeclaredAmount, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure SalesCreditMemoWithCorrectiveInvoiceDeliveryOperationCodeH()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDateInvoice: Date;
        PostingDateCrMemo: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 439176] Run Make 349 report on Sales Credit Memo when it corrects invoice from different period and when Delivery Operation Code is "H".
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10);
        PostingDateCrMemo := CalcDate('<+1M>', PostingDateInvoice);
        OriginalDeclaredAmount := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = "H".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::"H - Imported Tax Exempt (Representative)");

        // [GIVEN] Posted Sales Invoice "SI" with Posting Date 10.01.24 and Amount 10000.
        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24, Amount 1500 and "Corrected Invoice No." = "SI".
        CreateAndPostSalesInvoiceWithVATSetup(SalesInvoiceHeader, VATPostingSetup, false, PostingDateInvoice);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", false, PostingDateCrMemo);
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction, Original Declaration Period 01 and Original Declared Amount 200.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateInvoice, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "H" + 13 spaces + year(2024) + month(01) + Original Declared Amount(200) + Previous Declared Amount(10000).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'H', PostingDateInvoice, OriginalDeclaredAmount, SalesInvoiceHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure SalesCreditMemoWithCorrectiveInvoiceEUServiceSetOrigDeclaredAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDateInvoice: Date;
        PostingDateCrMemo: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 439176] Run Make 349 report on Sales Credit Memo when it corrects invoice from different period and when EU Service is set and Original Declared Amount is specified.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10);
        PostingDateCrMemo := CalcDate('<+1M>', PostingDateInvoice);
        OriginalDeclaredAmount := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] VAT Prod. Posting Group with EU Service = true and Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, true);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Invoice "SI" with Posting Date 10.01.24 and Amount 10000.
        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24, Amount 1500 and "Corrected Invoice No." = "SI".
        CreateAndPostSalesInvoiceWithVATSetup(SalesInvoiceHeader, VATPostingSetup, false, PostingDateInvoice);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", false, PostingDateCrMemo);
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction, Original Declaration Period 01 and Original Declared Amount 200.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateInvoice, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "S" + 13 spaces + year(2024) + month(01) + Original Declared Amount(200) + Previous Declared Amount(10000).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'S', PostingDateInvoice, OriginalDeclaredAmount, SalesInvoiceHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure SalesCreditMemoWithCorrectiveInvoiceEU3PartyTradeSetOrigDeclaredAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDateInvoice: Date;
        PostingDateCrMemo: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Sales] [EU 3-Party Trade]
        // [SCENARIO 439176] Run Make 349 report on Sales Credit Memo when it corrects invoice from different period and when EU 3-Party Trade is set and Original Declared Amount is specified.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10);
        PostingDateCrMemo := CalcDate('<+1M>', PostingDateInvoice);
        OriginalDeclaredAmount := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Invoice "SI" with Posting Date 10.01.24 and Amount 10000.
        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24, Amount 1500, "EU 3-Party Trade" set and "Corrected Invoice No." = "SI".
        CreateAndPostSalesInvoiceWithVATSetup(SalesInvoiceHeader, VATPostingSetup, true, PostingDateInvoice);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", true, PostingDateCrMemo);
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction, Original Declaration Period 01 and Original Declared Amount 200.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateInvoice, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "T" + 13 spaces + year(2024) + month(01) + Original Declared Amount(200) + Previous Declared Amount(10000).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'T', PostingDateInvoice, OriginalDeclaredAmount, SalesInvoiceHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    procedure PurchaseCreditMemoWithoutCorrectiveInvoiceDeliveryOperationCodeBlank()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 439176] Run Make 349 report on Purchase Credit Memo with blank Corrected Invoice No. when Delivery Operation Code is blank.
        // [SCENARIO 455095] Previous Declared Amount is not zero for Purchase Credit Memo with blank Corrected Invoice No.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Credit Memo with Posting Date 10.02.24, Amount 200 and blank "Corrected Invoice No.".
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr, VATPostingSetup, '', '', PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedPurchaseCrMemo(PurchCrMemoHdr);
        Vendor.Get(PurchCrMemoHdr."Buy-from Vendor No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Date2DMY(PostingDate, 3));
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Vendor is exported.
        // [THEN] Format is "A" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyRectificationLine(LineText, 'A', PostingDate, 0, PurchCrMemoHdr.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.DequeueDecimal();    // Previous Declared Amount
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    procedure PurchaseCreditMemoWithoutCorrectiveInvoiceDeliveryOperationCodeH()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 439176] Run Make 349 report on Purchase Credit Memo with blank Corrected Invoice No. when Delivery Operation Code is "H".
        // [SCENARIO 455095] Previous Declared Amount is not zero for Purchase Credit Memo with blank Corrected Invoice No.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = "H".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::"H - Imported Tax Exempt (Representative)");

        // [GIVEN] Posted Purchase Credit Memo with Posting Date 10.02.24, Amount 200 and blank "Corrected Invoice No.".
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr, VATPostingSetup, '', '', PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedPurchaseCrMemo(PurchCrMemoHdr);
        Vendor.Get(PurchCrMemoHdr."Buy-from Vendor No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Date2DMY(PostingDate, 3));
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Vendor is exported.
        // [THEN] Format is "A" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyRectificationLine(LineText, 'A', PostingDate, 0, PurchCrMemoHdr.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.DequeueDecimal();    // Previous Declared Amount
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY')]
    procedure PurchaseCreditMemoWithoutCorrectiveInvoiceEUService()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
    begin
        // [FEATURE] [Purchase] [EU Service]
        // [SCENARIO 439176] Run Make 349 report on Purchase Credit Memo with blank Corrected Invoice No. when EU Service is set.
        // [SCENARIO 455095] Previous Declared Amount is not zero for Purchase Credit Memo with blank Corrected Invoice No.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with EU Service = true and Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, true);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Credit Memo with Posting Date 10.02.24, Amount 200 and blank "Corrected Invoice No.".
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr, VATPostingSetup, '', '', PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedPurchaseCrMemo(PurchCrMemoHdr);
        Vendor.Get(PurchCrMemoHdr."Buy-from Vendor No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Date2DMY(PostingDate, 3));
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Vendor is exported.
        // [THEN] Format is "I" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyRectificationLine(LineText, 'I', PostingDate, 0, PurchCrMemoHdr.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.DequeueDecimal();    // Previous Declared Amount
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure PurchaseCreditMemoWithoutCorrectiveInvoiceEUServiceSetOrigDeclaredAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [EU Service]
        // [SCENARIO 439176] Run Make 349 report on Purchase Credit Memo with blank Corrected Invoice No. when EU Service is set and Original Declared Amount is specified.
        // [SCENARIO 455095] Previous Declared Amount is not zero for Purchase Credit Memo with blank Corrected Invoice No.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);
        OriginalDeclaredAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        // [GIVEN] VAT Prod. Posting Group with EU Service = true and Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, true);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Credit Memo with Posting Date 10.02.24, Amount 200 and blank "Corrected Invoice No.".
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr, VATPostingSetup, '', '', PostingDate);
        UpdateCorrectedInvoiceNoToBlankOnPostedPurchaseCrMemo(PurchCrMemoHdr);
        Vendor.Get(PurchCrMemoHdr."Buy-from Vendor No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction and Original Declared Amount 1000 for Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDate, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Vendor is exported.
        // [THEN] Format is "I" + 13 spaces + year(2024) + month(02) + Original Declared Amount(1000) + Previous Declared Amount(0 - 200 = -200).
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyRectificationLine(LineText, 'I', PostingDate, OriginalDeclaredAmount, PurchCrMemoHdr.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure PurchaseCreditMemoWithCorrectiveInvoiceDeliveryOperationCodeH()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDateInvoice: Date;
        PostingDateCrMemo: Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 439176] Run Make 349 report on Purchase Credit Memo when it corrects invoice from different period and when Delivery Operation Code is "H".
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10);
        PostingDateCrMemo := CalcDate('<+1M>', PostingDateInvoice);
        OriginalDeclaredAmount := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = "H".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(
            VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::"H - Imported Tax Exempt (Representative)");

        // [GIVEN] Posted Purchase Invoice "PI" with Posting Date 10.01.24 and Amount 10000.
        // [GIVEN] Posted Purchase Credit Memo with Posting Date 10.02.24, Amount 1500 and "Corrected Invoice No." = "PI".
        CreateAndPostPurchaseInvoiceWithVATSetup(PurchInvHeader, VATPostingSetup, PostingDateInvoice);
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr, VATPostingSetup, Vendor."No.", PurchInvHeader."No.", PostingDateCrMemo);
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction, Original Declaration Period 01 and Original Declared Amount 200.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateInvoice, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, PostingDateCrMemo);

        // [THEN] One line for Vendor is exported.
        // [THEN] Format is "A" + 13 spaces + year(2024) + month(01) + Original Declared Amount(200) + Previous Declared Amount(10000).
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyRectificationLine(LineText, 'A', PostingDateInvoice, OriginalDeclaredAmount, PurchInvHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure PurchaseCreditMemoWithCorrectiveInvoiceEUServiceSetOrigDeclaredAmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDateInvoice: Date;
        PostingDateCrMemo: Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [EU Service]
        // [SCENARIO 439176] Run Make 349 report on Purchase Credit Memo when it corrects invoice from different period and when EU Service is set.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10);
        PostingDateCrMemo := CalcDate('<+1M>', PostingDateInvoice);
        OriginalDeclaredAmount := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] VAT Prod. Posting Group with EU Service = true and Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, true);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Invoice "PI" with Posting Date 10.01.24 and Amount 10000.
        // [GIVEN] Posted Purchase Credit Memo with Posting Date 10.02.24, Amount 1500 and "Corrected Invoice No." = "PI".
        CreateAndPostPurchaseInvoiceWithVATSetup(PurchInvHeader, VATPostingSetup, PostingDateInvoice);
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr, VATPostingSetup, Vendor."No.", PurchInvHeader."No.", PostingDateCrMemo);
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction, Original Declaration Period 01 and Original Declared Amount 200.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateInvoice, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, PostingDateCrMemo);

        // [THEN] One line for Vendor is exported.
        // [THEN] Format is "I" + 13 spaces + year(2024) + month(01) + Original Declared Amount(200) + Previous Declared Amount(10000).
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyRectificationLine(LineText, 'I', PostingDateInvoice, OriginalDeclaredAmount, PurchInvHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SpecialSymbolsInCustName()
    var
        Customer: Record Customer;
        ExportFileName: Text[1024];
        RandomGUID: Code[10];
        ExpectedName: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378817] Make Declaration 349 changes special Spanish letter characters to basic latin counterparts when exporting
        Initialize();

        // [GIVEN] Foreign customer
        Customer.Get(CreateForeignCustomerWithVATRegNo(CreateCountryWithSpecificVATRegNoFormat(true)));

        // [GIVEN] Customer's name contains special character
        RandomGUID := LibraryUtility.GenerateGUID();
        Customer.Validate(Name, RandomGUID + 'É');
        Customer.Modify(true);

        // [GIVEN] Sales invoice posted
        CreateAndPostSalesInvoice(Customer."No.");

        // [WHEN] Run Make 349 Declaration
        ExportFileName := RunMake349DeclarationWithDate(WorkDate());

        // [THEN] Customer Name was exported with special character changed to basic latin character
        ExpectedName := RandomGUID + 'E';
        Assert.AreNotEqual('', LibraryTextFileValidation.FindLineContainingValue(ExportFileName, 1, 1024, ExpectedName), 'Line was not found');
    end;

    [Test]
    [HandlerFunctions('CustomerVendorWarnings349ModalPageHandler,ConfirmHandler,Make349DeclarationRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceInForeignCurrencyAmountLCYOnDeclaration349()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ExportFileName: Text[1024];
        CurrencyCode: Code[10];
        ExpectedAmount: Decimal;
        FileTxt: Text;
        File: File;
        InStr: InStream;
        Line: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 537264] Declaration 349 must report Amount (LCY) for invoices in foreign currency
        Initialize();

        // [GIVEN] Foreign customer
        Customer.Get(CreateForeignCustomerWithVATRegNo(CreateCountryWithSpecificVATRegNoFormat(true)));

        // [GIVEN] Customer's Currency Code is not LCY
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 0.5, 0.5);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);

        // [GIVEN] Sales invoice posted
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", WorkDate(), false);
        CreateSalesLine(SalesHeader, SalesLine);
        ExpectedAmount := SalesLine."Unit Cost (LCY)" * SalesLine.Quantity;
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Run Make 349 Declaration
        ExportFileName := RunMake349DeclarationWithDate(WorkDate());

        // [THEN] Amount (LCY) is used
        File.TextMode(true);
        File.Open(ExportFileName);
        File.CreateInStream(InStr);
        while not Instr.EOS() do begin
            Instr.ReadText(Line);
            FileTxt += Line;
        end;
        Assert.IsTrue(FileTxt.Contains(Format(ExpectedAmount, 0, 9)), '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure SalesCreditMemoWithCorrectiveInvoiceWhenOrigDeclPeiodNotChanged()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDateInvoice: Date;
        PostingDateCrMemo: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 461387] Run Make 349 report on Sales Credit Memo when it corrects invoice from different period and Original Declaration Period is not changed.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10);
        PostingDateCrMemo := CalcDate('<+1M>', PostingDateInvoice);
        OriginalDeclaredAmount := 0;

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Invoice "SI" with Posting Date 10.01.25 and Amount 10000.
        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.25, Amount 1500 and "Corrected Invoice No." = "SI".
        CreateAndPostSalesInvoiceWithVATSetup(SalesInvoiceHeader, VATPostingSetup, false, PostingDateInvoice);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", false, PostingDateCrMemo);
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction. Original Declaration Period/Amount remains unchanged, these are 02 and 0.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateCrMemo, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One rectification line for Customer is exported.
        // [THEN] Format is "E" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(1500).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'E', PostingDateCrMemo, OriginalDeclaredAmount, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349CustomPeriodPageHandler')]
    procedure PurchaseCreditMemoWithCorrectiveInvoiceWhenOrigDeclPeiodNotChanged()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDateInvoice: Date;
        PostingDateCrMemo: Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 461387] Run Make 349 report on Purchase Credit Memo when it corrects invoice from different period and Original Declaration Period is not changed.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(GetFirstDateInEmptyFY(), 10);
        PostingDateCrMemo := CalcDate('<+1M>', PostingDateInvoice);
        OriginalDeclaredAmount := 0;

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Invoice "PI" with Posting Date 10.01.25 and Amount 10000.
        // [GIVEN] Posted Purchase Credit Memo with Posting Date 10.02.25, Amount 1500 and "Corrected Invoice No." = "PI".
        CreateAndPostPurchaseInvoiceWithVATSetup(PurchInvHeader, VATPostingSetup, PostingDateInvoice);
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr, VATPostingSetup, Vendor."No.", PurchInvHeader."No.", PostingDateCrMemo);
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction. Original Declaration Period/Amount remains unchanged, these are 02 and 0.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateCrMemo, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, PostingDateCrMemo);

        // [THEN] One rectification line for Vendor is exported.
        // [THEN] Format is "A" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(1500).
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyRectificationLine(LineText, 'A', PostingDateCrMemo, OriginalDeclaredAmount, PurchCrMemoHdr.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerGetPostingDate')]
    procedure PostingDateOnCustVendWarningPageForSalesCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostingDate: Date;
        ActualPostingDate: Date;
        FileName: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 461387] Posting Date on Customer/Vendor Warnings 349 page when run Make 349 report on Sales Credit Memo.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Credit Memo with Posting Date 10.02.24.
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader, VATPostingSetup, '', '', false, PostingDate);
        Commit();

        // [WHEN] Run Make 349 Declaration report.
        RunMake349DeclarationReportSimple(FileName, SalesCrMemoHeader."Posting Date");

        // [THEN] Page Customer/Vendor Warnings 349 is opened and Posting Date is specified for Sales Credit Memo.
        Evaluate(ActualPostingDate, LibraryVariableStorage.DequeueText());
        Assert.AreEqual(SalesCrMemoHeader."Posting Date", ActualPostingDate, 'Posting Date must be specified.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349ModalPageHandlerGetPostingDate')]
    procedure PostingDateOnCustVendWarningPageForPurchaseCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostingDate: Date;
        ActualPostingDate: Date;
        FileName: Text;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 461387] Posting Date on Customer/Vendor Warnings 349 page when run Make 349 report on Purchase Credit Memo.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Credit Memo with Posting Date 10.02.24.
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr, VATPostingSetup, '', '', PostingDate);
        Commit();

        // [WHEN] Run Make 349 Declaration report.
        RunMake349DeclarationReportSimple(FileName, PurchCrMemoHdr."Posting Date");

        // [THEN] Page Customer/Vendor Warnings 349 is opened and Posting Date is specified for Purchase Credit Memo.
        Evaluate(ActualPostingDate, LibraryVariableStorage.DequeueText());
        Assert.AreEqual(PurchCrMemoHdr."Posting Date", ActualPostingDate, 'Posting Date must be specified.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerWithQuarter,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    procedure SalesCreditMemosWithCorrectiveInvoiceWhenSamePeriodQuarter()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: array[2] of Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDateInvoice: Date;
        PostingDateCrMemo: array[2] of Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 488756] Run Make 349 report on multiple Sales Credit Memos when they correct invoice from the same Quarter period.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(CalcDate('<CQ + 1D>', GetFirstDateInEmptyFY()), 10);
        PostingDateCrMemo[1] := CalcDate('<+1M>', PostingDateInvoice);
        PostingDateCrMemo[2] := CalcDate('<+2M>', PostingDateInvoice);
        OriginalDeclaredAmount := 0;

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Invoice "SI" with Posting Date 10.01.25 and Amount 10000.
        // [GIVEN] Posted Sales Credit Memo "CM1" with Posting Date 10.02.25, Amount 1500 and "Corrected Invoice No." = "PI".
        // [GIVEN] Posted Sales Credit Memo "CM2" with Posting Date 10.03.25, Amount 1000 and "Corrected Invoice No." = "PI".
        CreateAndPostSalesInvoiceWithVATSetup(SalesInvoiceHeader, VATPostingSetup, false, PostingDateInvoice);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader[1], VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", false, PostingDateCrMemo[1]);
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader[2], VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", false, PostingDateCrMemo[2]);
        Commit();

        // [WHEN] Run Make 349 Declaration report for 1T period (1st quarter), set Include Correction for both Credit Memos. Original Declaration Period/Amount remain unchanged.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo[1]);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateCrMemo[1], 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, PostingDateCrMemo[1]);

        // [THEN] One normal line for Vendor is exported.
        // [THEN] Format is "E" + <Invoice Amount - CM1 Amount - CM2 Amount>, i.e. E0000000750000.
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyNormalLine(LineText, 'E', SalesInvoiceHeader.Amount - SalesCrMemoHeader[1].Amount - SalesCrMemoHeader[2].Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    procedure SalesCreditMemosWithCorrectiveInvoiceWhenSamePeriodMonth()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: array[2] of Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDateInvoice: Date;
        PostingDateCrMemo: array[2] of Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 488756] Run Make 349 report on multiple Sales Credit Memos when they correct invoice from the same Month period.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(CalcDate('<CM + 1D>', GetFirstDateInEmptyFY()), 10);
        PostingDateCrMemo[1] := CalcDate('<+2D>', PostingDateInvoice);
        PostingDateCrMemo[2] := CalcDate('<+4D>', PostingDateInvoice);
        OriginalDeclaredAmount := 0;

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Invoice "SI" with Posting Date 10.01.25 and Amount 10000.
        // [GIVEN] Posted Sales Credit Memo "CM1" with Posting Date 12.01.25, Amount 1500 and "Corrected Invoice No." = "PI".
        // [GIVEN] Posted Sales Credit Memo "CM2" with Posting Date 14.01.25, Amount 1000 and "Corrected Invoice No." = "PI".
        CreateAndPostSalesInvoiceWithVATSetup(SalesInvoiceHeader, VATPostingSetup, false, PostingDateInvoice);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader[1], VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", false, PostingDateCrMemo[1]);
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader[2], VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", false, PostingDateCrMemo[2]);
        Commit();

        // [WHEN] Run Make 349 Declaration report for January period, set Include Correction for both Credit Memos. Original Declaration Period/Amount remain unchanged.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo[1]);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateCrMemo[1], 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, PostingDateCrMemo[1]);

        // [THEN] One normal line for Vendor is exported.
        // [THEN] Format is "E" + <Invoice Amount - CM1 Amount - CM2 Amount>, i.e. E0000000750000.
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyNormalLine(LineText, 'E', SalesInvoiceHeader.Amount - SalesCrMemoHeader[1].Amount - SalesCrMemoHeader[2].Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerAnnualPeriod,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    procedure SalesCreditMemosWithCorrectiveInvoiceWhenSamePeriodYear()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: array[2] of Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDateInvoice: Date;
        PostingDateCrMemo: array[2] of Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 488756] Run Make 349 report on multiple Sales Credit Memos when they correct invoice from the same Year period.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(CalcDate('<CY + 1D>', GetFirstDateInEmptyFY()), 10);
        PostingDateCrMemo[1] := CalcDate('<+3M>', PostingDateInvoice);
        PostingDateCrMemo[2] := CalcDate('<+6M>', PostingDateInvoice);
        OriginalDeclaredAmount := 0;

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Invoice "SI" with Posting Date 10.01.25 and Amount 10000.
        // [GIVEN] Posted Sales Credit Memo "CM1" with Posting Date 10.04.25, Amount 1500 and "Corrected Invoice No." = "PI".
        // [GIVEN] Posted Sales Credit Memo "CM2" with Posting Date 10.07.25, Amount 1000 and "Corrected Invoice No." = "PI".
        CreateAndPostSalesInvoiceWithVATSetup(SalesInvoiceHeader, VATPostingSetup, false, PostingDateInvoice);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader[1], VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", false, PostingDateCrMemo[1]);
        CreateAndPostSalesCreditMemoWithVATSetup(SalesCrMemoHeader[2], VATPostingSetup, Customer."No.", SalesInvoiceHeader."No.", false, PostingDateCrMemo[2]);
        Commit();

        // [WHEN] Run Make 349 Declaration report for 0A period 2025, set Include Correction for both Credit Memos. Original Declaration Period/Amount remain unchanged.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo[1]);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateCrMemo[1], 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, PostingDateCrMemo[1]);

        // [THEN] One normal line for Vendor is exported.
        // [THEN] Format is "E" + <Invoice Amount - CM1 Amount - CM2 Amount>, i.e. E0000000750000.
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyNormalLine(LineText, 'E', SalesInvoiceHeader.Amount - SalesCrMemoHeader[1].Amount - SalesCrMemoHeader[2].Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerWithQuarter,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    procedure PurchaseCreditMemosWithCorrectiveInvoiceWhenSamePeriodQuarter()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: array[2] of Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDateInvoice: Date;
        PostingDateCrMemo: array[2] of Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 488756] Run Make 349 report on multiple Purchase Credit Memos when they correct invoice from the same Quarter period.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(CalcDate('<CQ + 1D>', GetFirstDateInEmptyFY()), 10);
        PostingDateCrMemo[1] := CalcDate('<+1M>', PostingDateInvoice);
        PostingDateCrMemo[2] := CalcDate('<+2M>', PostingDateInvoice);
        OriginalDeclaredAmount := 0;

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Invoice "PI" with Posting Date 10.01.25 and Amount 10000.
        // [GIVEN] Posted Purchase Credit Memo "CM1" with Posting Date 10.02.25, Amount 1500 and "Corrected Invoice No." = "PI".
        // [GIVEN] Posted Purchase Credit Memo "CM2" with Posting Date 10.03.25, Amount 1000 and "Corrected Invoice No." = "PI".
        CreateAndPostPurchaseInvoiceWithVATSetup(PurchInvHeader, VATPostingSetup, PostingDateInvoice);
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr[1], VATPostingSetup, Vendor."No.", PurchInvHeader."No.", PostingDateCrMemo[1]);
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr[2], VATPostingSetup, Vendor."No.", PurchInvHeader."No.", PostingDateCrMemo[2]);
        Commit();

        // [WHEN] Run Make 349 Declaration report for 1T period (1st quarter), set Include Correction for both Credit Memos. Original Declaration Period/Amount remain unchanged.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo[1]);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateCrMemo[1], 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, PostingDateCrMemo[1]);

        // [THEN] One normal line for Vendor is exported.
        // [THEN] Format is "A" + <Invoice Amount - CM1 Amount - CM2 Amount>, i.e. A0000000750000.
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyNormalLine(LineText, 'A', PurchInvHeader.Amount - PurchCrMemoHdr[1].Amount - PurchCrMemoHdr[2].Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    procedure PurchaseCreditMemosWithCorrectiveInvoiceWhenSamePeriodMonth()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: array[2] of Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDateInvoice: Date;
        PostingDateCrMemo: array[2] of Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 488756] Run Make 349 report on multiple Purchase Credit Memos when they correct invoice from the same Month period.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(CalcDate('<CM + 1D>', GetFirstDateInEmptyFY()), 10);
        PostingDateCrMemo[1] := CalcDate('<+2D>', PostingDateInvoice);
        PostingDateCrMemo[2] := CalcDate('<+4D>', PostingDateInvoice);
        OriginalDeclaredAmount := 0;

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Invoice "PI" with Posting Date 10.01.25 and Amount 10000.
        // [GIVEN] Posted Purchase Credit Memo "CM1" with Posting Date 12.01.25, Amount 1500 and "Corrected Invoice No." = "PI".
        // [GIVEN] Posted Purchase Credit Memo "CM2" with Posting Date 14.01.25, Amount 1000 and "Corrected Invoice No." = "PI".
        CreateAndPostPurchaseInvoiceWithVATSetup(PurchInvHeader, VATPostingSetup, PostingDateInvoice);
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr[1], VATPostingSetup, Vendor."No.", PurchInvHeader."No.", PostingDateCrMemo[1]);
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr[2], VATPostingSetup, Vendor."No.", PurchInvHeader."No.", PostingDateCrMemo[2]);
        Commit();

        // [WHEN] Run Make 349 Declaration report for January period, set Include Correction for both Credit Memos. Original Declaration Period/Amount remain unchanged.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo[1]);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateCrMemo[1], 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, PostingDateCrMemo[1]);

        // [THEN] One normal line for Vendor is exported.
        // [THEN] Format is "A" + <Invoice Amount - CM1 Amount - CM2 Amount>, i.e. A0000000750000.
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyNormalLine(LineText, 'A', PurchInvHeader.Amount - PurchCrMemoHdr[1].Amount - PurchCrMemoHdr[2].Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandlerAnnualPeriod,ConfirmHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler')]
    procedure PurchaseCreditMemosWithCorrectiveInvoiceWhenSamePeriodYear()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: array[2] of Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDateInvoice: Date;
        PostingDateCrMemo: array[2] of Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
        OriginalDeclaredAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 488756] Run Make 349 report on multiple Purchase Credit Memos when they correct invoice from the same Year period.
        Initialize();
        PostingDateInvoice := LibraryRandom.RandDateFrom(CalcDate('<CY + 1D>', GetFirstDateInEmptyFY()), 10);
        PostingDateCrMemo[1] := CalcDate('<+3M>', PostingDateInvoice);
        PostingDateCrMemo[2] := CalcDate('<+6M>', PostingDateInvoice);
        OriginalDeclaredAmount := 0;

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Invoice "PI" with Posting Date 10.01.25 and Amount 10000.
        // [GIVEN] Posted Purchase Credit Memo "CM1" with Posting Date 10.04.25, Amount 1500 and "Corrected Invoice No." = "PI".
        // [GIVEN] Posted Purchase Credit Memo "CM2" with Posting Date 10.07.25, Amount 1000 and "Corrected Invoice No." = "PI".
        CreateAndPostPurchaseInvoiceWithVATSetup(PurchInvHeader, VATPostingSetup, PostingDateInvoice);
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr[1], VATPostingSetup, Vendor."No.", PurchInvHeader."No.", PostingDateCrMemo[1]);
        CreateAndPostPurchaseCreditMemoWithVATSetup(PurchCrMemoHdr[2], VATPostingSetup, Vendor."No.", PurchInvHeader."No.", PostingDateCrMemo[2]);
        Commit();

        // [WHEN] Run Make 349 Declaration report for 0A period 2025, set Include Correction for both Credit Memos. Original Declaration Period/Amount remain unchanged.
        LibraryVariableStorage.Enqueue(PostingDateCrMemo[1]);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDateCrMemo[1], 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        RunMake349DeclarationReportSimple(FileName, PostingDateCrMemo[1]);

        // [THEN] One normal line for Vendor is exported.
        // [THEN] Format is "A" + <Invoice Amount - CM1 Amount - CM2 Amount>, i.e. A0000000750000.
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyNormalLine(LineText, 'A', PurchInvHeader.Amount - PurchCrMemoHdr[1].Amount - PurchCrMemoHdr[2].Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustVendWarnings349MultCorrectionsModalPageHandler')]
    procedure SalesCreditMemoMultLinesWithoutCorrectiveInvoiceDeliveryCodeE()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCEARIO 484526] Run Make 349 report on Sales Credit Memo with multiple lines and blank Corrected Invoice No. when Delivery Operation Code is E.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = "E".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::"E - General");

        // [GIVEN] Posted Sales Credit Memo with blank "Corrected Invoice No.".
        // [GIVEN] Credit Memo has two lines with different General Prod. Posting Groups and Amounts 50 and 150.
        CreateAndPostSalesCreditMemoMultLines(SalesCrMemoHeader, VATPostingSetup, false, PostingDate);
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for both lines of Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "E" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'E', PostingDate, 0, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustVendWarnings349MultCorrectionsModalPageHandler')]
    procedure SalesCreditMemoMultLinesWithoutCorrectiveInvoiceEUService()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 484526] Run Make 349 report on Sales Credit Memo with multiple lines and blank Corrected Invoice No. when EU Service is set.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with EU Service = true and Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, true);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Credit Memo with blank "Corrected Invoice No.".
        // [GIVEN] Credit Memo has two lines with different General Prod. Posting Groups and Amounts 50 and 150.
        CreateAndPostSalesCreditMemoMultLines(SalesCrMemoHeader, VATPostingSetup, false, PostingDate);
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for both lines of Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "S" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'S', PostingDate, 0, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustVendWarnings349MultCorrectionsModalPageHandler')]
    procedure SalesCreditMemoMultLinesWithoutCorrectiveInvoiceEU3PartyTrade()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        CustLinesCount: Integer;
    begin
        // [FEATURE] [Sales] [EU 3-Party Trade]
        // [SCENARIO 484526] Run Make 349 report on Sales Credit Memo with multiple lines and blank Corrected Invoice No. when EU 3-Party Trade is set.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Sales Credit Memo with blank "Corrected Invoice No." and "EU 3-Party Trade" set.
        // [GIVEN] Credit Memo has two lines with different General Prod. Posting Groups and Amounts 50 and 150.
        CreateAndPostSalesCreditMemoMultLines(SalesCrMemoHeader, VATPostingSetup, true, PostingDate);
        Customer.Get(SalesCrMemoHeader."Sell-to Customer No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for both lines of Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Customer is exported.
        // [THEN] Format is "T" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        CustLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40);
        Assert.AreEqual(1, CustLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Customer.Name));
        VerifyRectificationLine(LineText, 'T', PostingDate, 0, SalesCrMemoHeader.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustVendWarnings349MultCorrectionsModalPageHandler')]
    procedure PurchaseCreditMemoMultLinesWithoutCorrectiveInvoiceDeliveryCodeH()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 484526] Run Make 349 report on Purchase Credit Memo with multiple lines and blank Corrected Invoice No. when Delivery Operation Code is "H".
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with Delivery Operation Code = "H".
        CreateVATPostingSetup(VATPostingSetup, false);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::"H - Imported Tax Exempt (Representative)");

        // [GIVEN] Posted Purchase Credit Memo with blank "Corrected Invoice No.".
        // [GIVEN] Credit Memo has two lines with different General Prod. Posting Groups and Amounts 50 and 150.
        CreateAndPostPurchaseCreditMemoMultLines(PurchCrMemoHdr, VATPostingSetup, PostingDate);
        Vendor.Get(PurchCrMemoHdr."Buy-from Vendor No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for both lines of Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Vendor is exported.
        // [THEN] Format is "A" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyRectificationLine(LineText, 'A', PostingDate, 0, PurchCrMemoHdr.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,Make349DeclarationRequestPageHandler,ConfirmHandler,CustVendWarnings349MultCorrectionsModalPageHandler')]
    procedure PurchaseCreditMemoMultLinesWithoutCorrectiveInvoiceEUService()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Vendor: Record Vendor;
        PostingDate: Date;
        FileName: Text;
        LineText: Text;
        VendLinesCount: Integer;
    begin
        // [FEATURE] [Purchase] [EU Service]
        // [SCENARIO 484526] Run Make 349 report on Purchase Credit Memo with multiple lines and blank Corrected Invoice No. when EU Service is set.
        Initialize();
        PostingDate := LibraryRandom.RandDateFrom(GetEmptyPeriodDate(), 10);

        // [GIVEN] VAT Prod. Posting Group with EU Service = true and Delivery Operation Code = " ".
        CreateVATPostingSetup(VATPostingSetup, true);
        UpdateDeliveryOperCodeOnVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group", DeliveryOperationCode::" ");

        // [GIVEN] Posted Purchase Credit Memo with blank "Corrected Invoice No.".
        // [GIVEN] Credit Memo has two lines with different General Prod. Posting Groups and Amounts 50 and 150.
        CreateAndPostPurchaseCreditMemoMultLines(PurchCrMemoHdr, VATPostingSetup, PostingDate);
        Vendor.Get(PurchCrMemoHdr."Buy-from Vendor No.");
        Commit();

        // [WHEN] Run Make 349 Declaration report, set Include Correction for both lines of Credit Memo.
        LibraryVariableStorage.Enqueue(PostingDate);
        RunMake349DeclarationReportSimple(FileName, 0D);

        // [THEN] One line for Vendor is exported.
        // [THEN] Format is "I" + 13 spaces + year(2024) + month(02) + Original Declared Amount(0) + Previous Declared Amount(0 - 200 = -200).
        VendLinesCount := LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40);
        Assert.AreEqual(1, VendLinesCount, '');
        LineText := LibraryTextFileValidation.FindLineWithValue(FileName, 93, 40, PadCustVendNo(Vendor.Name));
        VerifyRectificationLine(LineText, 'I', PostingDate, 0, PurchCrMemoHdr.Amount);

        LibraryVariableStorage.DequeueDate();       // Posting Date
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNo,MessageHandler,Make349DeclarationRequestPageHandler2')]
    procedure Make349DeclarationRepWithNonDeductibleVATInPurchaseDocument()
    var
        Item: Record Item;
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Make349Declaration: Report "Make 349 Declaration";
        DocumentNo: Code[20];
        EULocationList: List of [Code[20]];
        EUCountryRegionList: List of [Code[10]];
        FileName: Text;
    begin
        // [SCENARIO 560210] Verify Amount With non-deductible VAT in case not all locations are within the EU.
        Initialize();

        // [GIVEN] Enable Non-Deductible VAT
        ModifyVATSetup();

        // [GIVEN] Create VAT Posting Setup With Non-Deductible VAT & EU Service.
        CreateVATPostingSetup(VATPostingSetup, true);
        ModifyVATPostingSetupWithNonDeductibleVAT(VATPostingSetup);

        // [GIVEN] Set All Locations are EU.
        SetAllLocationAreEU(EULocationList);
        
        // [GIVEN] Set All Country Regions are EU.
        SetAllCountryRegionAreEU(EUCountryRegionList);

        // [GIVEN] Create EU Vendor.
        CreateEUVendorWithPostingGroups(Vendor, VATPostingSetup);

        // [GIVEN] Create New Item.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Item,
            LibraryRandom.RandDec(1000, 2),
            LibraryRandom.RandDec(2000, 2));
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Post Purchase Invoice
        DocumentNo := CreateAndPostNonDeductibleVATPurchaseDocument(Vendor, Item);

        // [GIVEN] Find VAT Entry.
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();

        // [WHEN] Run Make 349 Declaration Report
        FileName := RunMake349DeclarationWithDate(WorkDate());

        // [THEN] Verify the amount.
        VerifyValuesOnGeneratedTextFile(FileName, 134,
            CopyStr(Make349Declaration.FormatTextAmt(VATEntry.Base + VATEntry."Non-Deductible VAT Base"), 3, 13));

        // Restore the Location in Original State.
        RestoreLocations(EULocationList);

        // Restore the Country Region in Original State.
        RestoreEUCountryRegions(EUCountryRegionList);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNo,MessageHandler,Make349DeclarationRequestPageHandler2')]
    procedure Make349DeclarationRepWithNonDeductibleVATInSalesDocument()
    var
        Item: Record Item;
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        Make349Declaration: Report "Make 349 Declaration";
        DocumentNo: Code[20];
        EULocationList: List of [Code[20]];
        EUCountryRegionList: List of [Code[10]];
        FileName: Text;
    begin
        // [SCENARIO 560210] Verify Amount With non-deductible VAT in case not all locations are within the EU.
        Initialize();

        // [GIVEN] Enable Non-Deductible VAT
        ModifyVATSetup();

        // [GIVEN] Create VAT Posting Setup With Non-Deductible VAT & EU Service.
        CreateVATPostingSetup(VATPostingSetup, true);
        ModifyVATPostingSetupWithNonDeductibleVAT(VATPostingSetup);

        // [GIVEN] Set All Locations are EU.
        SetAllLocationAreEU(EULocationList);

        // [GIVEN] Set All Country Regions are EU.
        SetAllCountryRegionAreEU(EUCountryRegionList);

        // [GIVEN] Create EU Customer.
        CreateEUCustomerWithPostingGroups(Customer, VATPostingSetup);

        // [GIVEN] Create New Item.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
            Item,
            LibraryRandom.RandDec(1000, 2),
            LibraryRandom.RandDec(2000, 2));
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Post Sales Invoice
        DocumentNo := CreateAndPostNonDeductibleVATSalesDocument(Customer, Item);

        // [GIVEN] Find VAT Entry.
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();

        // [WHEN] Run Make 349 Declaration Report
        FileName := RunMake349DeclarationWithDate(WorkDate());

        // [THEN] Verify the amount.
        VerifyValuesOnGeneratedTextFile(FileName, 134,
            CopyStr(Make349Declaration.FormatTextAmt(VATEntry.Base + VATEntry."Non-Deductible VAT Base"), 3, 13));

        // Restore the Location in Original State.
        RestoreLocations(EULocationList);

        // Restore the Country Region in Original State.
        RestoreEUCountryRegions(EUCountryRegionList);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler2')]
    procedure Make349DeclExportsWhenIncludePurchaseCreditMemosWithAndWithoutCorrectedInvoiceNo()
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CrMemoNo: array[2] of Code[20];
        InvNo: array[4] of Code[20];
        CrMemoAmt: array[2] of Decimal;
        InvoiceAmount: array[4] of Decimal;
        TotalAmount: Decimal;
        i: Integer;
        LineNo: array[2] of Integer;
        FileName: Text;
        LineText: array[2] of Text;
    begin
        // [SCENARIO 559355] Verify Make 349 declaration exports information when including Credit Memos with and without Corrected Invoice No. 
        Initialize();

        // [GIVEN] Create VAT Posting Setup with GL Accounts.
        CreateVATPostingSetup(VATPostingSetup, true);
        ModifyVATPostingSetupWithGLAccounts(VATPostingSetup);

        // [GIVEN] Create EU Vendor.
        CreateEUVendorWithPostingGroups(Vendor, VATPostingSetup);

        // [GIVEN] Create New Item.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(2000, 2));
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Post Purchase Invoice
        for i := 1 to LibraryRandom.RandIntInRange(4, 4) do begin
            InvNo[i] := CreateAndPostMultiplePurchaseDocument(Vendor, Item, InvoiceAmount[i]);
            TotalAmount += InvoiceAmount[i];
        end;

        // [GIVEN] Create and Post Purchase Credit Memo with Corrective Invoice.
        CrMemoNo[1] := CreateAndPostMultiplePurchaseCreditMemoDocument(Vendor, Item, InvNo[4], CrMemoAmt[1], InvoiceAmount[4]);
        TotalAmount += CrMemoAmt[1];

        // [GIVEN] Create and Post Purchase Credit Memo without Corrective Invoice.
        CrMemoNo[2] := CreateAndPostMultiplePurchaseCreditMemoDocument(Vendor, Item, '', CrMemoAmt[2], InvoiceAmount[4]);

        // [GIVEN] Enqueue the Multiple Values.
        EnqueueMultipleValues(Vendor."No.", InvoiceAmount[4]);

        // [WHEN] Run Make 349 Declaration Report.
        FileName := RunMake349DeclarationWithDate(WorkDate());

        // [WHEN] Store the line Wise Value.
        for i := 1 to LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Vendor.Name), 93, 40) do begin
            LineNo[i] := LibraryTextFileValidation.FindLineNoWithValue(FileName, 93, 40, PadCustVendNo(Vendor."No."), i);
            LineText[i] := LibraryTextFileValidation.ReadLine(FileName, LineNo[i]);
        end;

        // [THEN] Verify the Original Declared Amount when Including Credit Memos with and Without Corrected Invoice No.
        VerifyRectificationLine(LineText[1], 'I', WorkDate(), InvoiceAmount[4], ABS(CrMemoAmt[2]));

        // [THEN] Verify the Total Amount when Including Credit Memos with and Without Corrected Invoice No.
        VerifyNormalLine(LineText[2], 'I', TotalAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,Make349DeclarationRequestPageHandler,CustomerVendorWarnings349IncludeAllEntriesPageHandler2')]
    procedure Make349DeclExportsWhenIncludeSalesCreditMemosWithAndWithoutCorrectedInvoiceNo()
    var
        Customer: Record Customer;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        CrMemoNo: array[2] of Code[20];
        InvNo: array[4] of Code[20];
        CrMemoAmt: array[2] of Decimal;
        InvoiceAmount: array[4] of Decimal;
        TotalAmount: Decimal;
        i: Integer;
        LineNo: array[2] of Integer;
        FileName: Text;
        LineText: array[2] of Text;
    begin
        // [SCENARIO 559355] Verify Make 349 declaration exports information when including Credit Memos with and without Corrected Invoice No. 
        Initialize();

        // [GIVEN] Create VAT Posting Setup with GL Accounts.
        CreateVATPostingSetup(VATPostingSetup, true);
        ModifyVATPostingSetupWithGLAccounts(VATPostingSetup);

        // [GIVEN] Create EU Customer.
        CreateEUCustomerWithPostingGroups(Customer, VATPostingSetup);

        // [GIVEN] Create New Item.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(2000, 2));
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Post Sales Invoice.
        for i := 1 to LibraryRandom.RandIntInRange(4, 4) do begin
            InvNo[i] := CreateAndPostMultipleSalesDocument(Customer, Item, InvoiceAmount[i]);
            TotalAmount += InvoiceAmount[i];
        end;

        // [GIVEN] Create and Post Sales Credit Memo with Corrective Invoice.
        CrMemoNo[1] := CreateAndPostMultipleSalesCreditMemoDocument(Customer, Item, InvNo[4], CrMemoAmt[1], InvoiceAmount[4]);
        TotalAmount += CrMemoAmt[1];

        // [GIVEN] Create and Post Sales Credit Memo without Corrective Invoice.
        CrMemoNo[2] := CreateAndPostMultipleSalesCreditMemoDocument(Customer, Item, '', CrMemoAmt[2], InvoiceAmount[4]);

        // [GIVEN] Enqueue the Multiple Values.
        EnqueueMultipleValues(Customer."No.", InvoiceAmount[4]);

        // [WHEN] Run Make 349 Declaration Report.
        FileName := RunMake349DeclarationWithDate(WorkDate());

        // [WHEN] Store the line Wise Value.
        for i := 1 to LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, PadCustVendNo(Customer.Name), 93, 40) do begin
            LineNo[i] := LibraryTextFileValidation.FindLineNoWithValue(FileName, 93, 40, PadCustVendNo(Customer."No."), i);
            LineText[i] := LibraryTextFileValidation.ReadLine(FileName, LineNo[i]);
        end;

        // [THEN] Verify the Original Declared Amount when Including Credit Memos with and Without Corrected Invoice No.
        VerifyRectificationLine(LineText[1], 'S', WorkDate(), InvoiceAmount[4], ABS(CrMemoAmt[2]));

        // [THEN] Verify the Total Amount when Including Credit Memos with and Without Corrected Invoice No.
        VerifyNormalLine(LineText[2], 'S', TotalAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        Make349DeclarationReportId: Integer;
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.SaveCompanyInformation();
        LibrarySetupStorage.SaveVATSetup();
        InventorySetup.Get();

        Make349DeclarationReportId := Report::"Make 349 Declaration";
        LibraryReportValidation.DeleteObjectOptions(Make349DeclarationReportId);

        IsInitialized := true;
        Commit();
    end;

    local procedure GetEmptyPeriodDate(): Date
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Posting Date");
        GLEntry.FindLast();
        exit(CalcDate('<CM>', GLEntry."Posting Date") + 1);
    end;

    local procedure GetFirstDateInEmptyFY(): Date
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Posting Date");
        GLEntry.FindLast();
        exit(CalcDate('<CY>', GLEntry."Posting Date") + 1);
    end;

    local procedure GetQuarterFromDate(Date: Date): Integer
    begin
        exit((Date2DMY(Date, 2) - 1) div 3 + 1);
    end;

    local procedure PrepareEUAndForeignCustomerAndPostSalesDocs(var CustNo: array[2] of Code[20]; var VATPostingSetup: Record "VAT Posting Setup"; DocType: Enum "Sales Document Type"; CountryRegionCode: array[2] of Code[10]; PostingDate: Date)
    var
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(CustNo) do begin
            CustNo[Index] := CreateCustomer(
                CountryRegionCode[Index], VATPostingSetup."VAT Bus. Posting Group",
                LibraryERM.GenerateVATRegistrationNo(CountryRegionCode[Index]));
            CreateAndPostSalesDocument(DocType, CustNo[Index], CreateItem(VATPostingSetup."VAT Prod. Posting Group"), PostingDate, false);
        end;
    end;

    local procedure PrepareEUAndForeignVendorAndPostPurchDocs(var VendorNo: array[2] of Code[20]; VATPostingSetup: Record "VAT Posting Setup"; DocType: Enum "Purchase Document Type"; CountryRegionCode: array[2] of Code[10]; PostingDate: Date)
    var
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(VendorNo) do begin
            VendorNo[Index] := CreateVendor(
                CountryRegionCode[Index], VATPostingSetup."VAT Bus. Posting Group",
                LibraryERM.GenerateVATRegistrationNo(CountryRegionCode[Index]));
            CreateAndPostPurchaseDocument(DocType, VendorNo[Index], CreateItem(VATPostingSetup."VAT Prod. Posting Group"), PostingDate);
        end;
    end;

    local procedure GetCountryRegionFromCompanyInfo(): Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation."Country/Region Code");
    end;

    local procedure MockPostedSalesInvoiceNoTaxableWithCountry(var SalesInvoiceLine: Record "Sales Invoice Line"; CountryRegionCode: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Bill-to Country/Region Code" := CountryRegionCode;
        SalesInvoiceHeader.Insert();

        SalesInvoiceLine.Init();
        SalesInvoiceLine."Line No." := LibraryUtility.GetNewRecNo(SalesInvoiceLine, SalesInvoiceLine.FieldNo("Line No."));
        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
        SalesInvoiceLine."VAT Calculation Type" := SalesInvoiceLine."VAT Calculation Type"::"No Taxable VAT";
        SalesInvoiceLine."Line Amount" := LibraryRandom.RandDecInRange(1000, 2000, 2);
        SalesInvoiceLine.Insert();
    end;

    local procedure MockPostedPurchInvoiceNoTaxableWithCountry(var PurchInvLine: Record "Purch. Inv. Line"; CountryRegionCode: Code[10])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchInvHeader."Pay-to Country/Region Code" := CountryRegionCode;
        PurchInvHeader.Insert();

        PurchInvLine.Init();
        PurchInvLine."Line No." := LibraryUtility.GetNewRecNo(PurchInvLine, PurchInvLine.FieldNo("Line No."));
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine."VAT Calculation Type" := PurchInvLine."VAT Calculation Type"::"No Taxable VAT";
        PurchInvLine."Line Amount" := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PurchInvLine.Insert();
    end;

    local procedure GetItemFromServiceDoc(DocType: Enum "Service Document Type"; DocNo: Code[20]): Code[20]
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", DocType);
        ServiceLine.SetRange("Document No.", DocNo);
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.FindFirst();
        exit(ServiceLine."No.");
    end;

    local procedure GetItemFromPurchDoc(DocType: Enum "Purchase Document Type"; DocNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocType);
        PurchaseLine.SetRange("Document No.", DocNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        exit(PurchaseLine."No.");
    end;

    local procedure GetItemFromSalesDoc(DocType: Enum "Sales Document Type"; DocNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        exit(SalesLine."No.");
    end;

    local procedure GetNewWorkDate(): Date
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetCurrentKey("Posting Date");
        GLRegister.FindLast();
        exit(CalcDate('<1Y>', GLRegister."Posting Date"));
    end;

    local procedure CreateVATPostingSetupWithCalculationType(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; EUService: Boolean)
    begin
        CreateVATPostingSetup(VATPostingSetup, EUService);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Country/Region Code", CreateCountryRegion());
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateServiceInvoice(var ServiceHeader: Record "Service Header"; var Amount: Decimal; VATBusPostingGrp: Code[20]; VATProdPostingGrp: Code[20]; EU3PartyTrade: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        CreateServiceHeaderWithVATBusGrp(ServiceHeader, VATBusPostingGrp);
        ModifyServiceHeaderEU3PartyTrade(ServiceHeader, EU3PartyTrade);
        CreateServiceLineWithVATProdGrp(ServiceLine, ServiceHeader, VATProdPostingGrp);
        Amount := ServiceLine."Amount Including VAT";
    end;

    local procedure CreateServiceInvoiceWithPostingDate(var ServiceHeader: Record "Service Header"; var Amount: Decimal; PostingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceLine: Record "Service Line";
    begin
        CreateVATPostingSetup(VATPostingSetup, false);
        CreateServiceHeaderWithVATBusGrp(ServiceHeader, VATPostingSetup."VAT Bus. Posting Group");
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Modify(true);
        CreateServiceLineWithVATProdGrp(ServiceLine, ServiceHeader, VATPostingSetup."VAT Prod. Posting Group");
        Amount := ServiceLine."Amount Including VAT";
    end;

    local procedure CreateSalesInvoiceWithPostingDate(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        CreateVATPostingSetup(VATPostingSetup, false);
        CreateSalesHeaderWithVATBusGrpAndLocation(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", '');
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        CreateSalesLineWithVATProdGrp(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group");
        SalesHeader.CalcFields(Amount);
    end;

    local procedure CreatePurchaseInvoiceWithPostingDate(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateVATPostingSetup(VATPostingSetup, false);
        CreatePurchHeaderWithVATBusGrpAndLocation(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", '');
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        CreatePurchLineWithVATProdGrp(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
        PurchaseHeader.CalcFields(Amount);
    end;

    local procedure CreateAndPostSalesInvoiceWithVATSetup(var SalesInvoiceHeader: Record "Sales Invoice Header"; VATPostingSetup: Record "VAT Posting Setup"; EU3PartyTrade: Boolean; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderWithVATBusGrp(SalesHeader, "Sales Document Type"::Invoice, VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("EU 3-Party Trade", EU3PartyTrade);
        SalesHeader.Modify(true);
        CreateSalesLineWithVATProdGrp(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", SalesLine."Unit Price" * 10);  // invoice amount must be greater than credit memo amount
        SalesLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields(Amount);
    end;

    local procedure CreateAndPostSalesCreditMemoWithVATSetup(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; CorrectedInvoiceNo: Code[20]; EU3PartyTrade: Boolean; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderWithVATBusGrp(SalesHeader, "Sales Document Type"::"Credit Memo", VATPostingSetup."VAT Bus. Posting Group");
        if CustomerNo <> '' then
            SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("EU 3-Party Trade", EU3PartyTrade);
        SalesHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);      // does not work for blank values
        SalesHeader.Modify(true);
        CreateSalesLineWithVATProdGrp(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group");
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.CalcFields(Amount);
    end;

    local procedure CreateAndPostSalesCreditMemoMultLines(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; VATPostingSetup: Record "VAT Posting Setup"; EU3PartyTrade: Boolean; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        CreateSalesHeaderWithVATBusGrp(SalesHeader, "Sales Document Type"::"Credit Memo", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("EU 3-Party Trade", EU3PartyTrade);
        SalesHeader.Modify(true);

        CreateGeneralPostingSetup(GeneralPostingSetup, SalesHeader."Gen. Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreateSalesLineWithVATGenProdGroup(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        CreateGeneralPostingSetup(GeneralPostingSetup, SalesHeader."Gen. Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreateSalesLineWithVATGenProdGroup(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.CalcFields(Amount);
    end;

    local procedure CreateAndPostPurchaseInvoiceWithVATSetup(var PurchInvHeader: Record "Purch. Inv. Header"; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchHeaderWithVATBusGrp(PurchaseHeader, "Purchase Document Type"::Invoice, VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        CreatePurchLineWithVATProdGrp(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" * 10);  // invoice amount must be greater than credit memo amount
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        PurchInvHeader.CalcFields(Amount);
    end;

    local procedure CreateAndPostPurchaseCreditMemoWithVATSetup(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20]; CorrectedInvoiceNo: Code[20]; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchHeaderWithVATBusGrp(PurchaseHeader, "Purchase Document Type"::"Credit Memo", VATPostingSetup."VAT Bus. Posting Group");
        if VendorNo <> '' then
            PurchaseHeader.Validate("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);      // does not work for blank values
        PurchaseHeader.Modify(true);
        CreatePurchLineWithVATProdGrp(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        PurchCrMemoHdr.CalcFields(Amount);
    end;

    local procedure CreateAndPostPurchaseCreditMemoMultLines(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        CreatePurchHeaderWithVATBusGrp(PurchaseHeader, "Purchase Document Type"::"Credit Memo", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        CreateGeneralPostingSetup(GeneralPostingSetup, PurchaseHeader."Gen. Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchLineWithVATGenProdGroup(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        CreateGeneralPostingSetup(GeneralPostingSetup, PurchaseHeader."Gen. Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchLineWithVATGenProdGroup(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");

        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        PurchCrMemoHdr.CalcFields(Amount);
    end;

    local procedure InsertPurchaseLineWithDifferentPostingGroups(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
    begin
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("EU Service", false);
        VATPostingSetup.Modify(true);
        CreateGeneralPostingSetup(GeneralPostingSetup, Vendor."Gen. Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchLineWithVATProdGrp(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithLocationAndApplyInvoiceDisc(var SalesHeader: Record "Sales Header"; VATBusPostingGrp: Code[20]; VATProdPostingGrp: Code[20]; LocationCode: Code[10]; EU3PartyTrade: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderWithVATBusGrpAndLocation(SalesHeader, VATBusPostingGrp, LocationCode);
        ModifySalesHeaderEU3PartyTrade(SalesHeader, EU3PartyTrade);
        CreateSalesLineWithVATProdGrp(SalesLine, SalesHeader, VATProdPostingGrp);
        ApplySalesInvoiceDisc(SalesHeader);
    end;

    local procedure CreatePurchInvoiceWithLocationAndApplyInvoiceDisc(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGrp: Code[20]; VATProdPostingGrp: Code[20]; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchHeaderWithVATBusGrpAndLocation(PurchaseHeader, VATBusPostingGrp, LocationCode);
        CreatePurchLineWithVATProdGrp(PurchaseLine, PurchaseHeader, VATProdPostingGrp);
        ApplyPurchInvoiceDisc(PurchaseHeader);
    end;

    local procedure CreateServiceHeaderWithVATBusGrp(var ServiceHeader: Record "Service Header"; VATBusPostingGroupCode: Code[20])
    var
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := CreateCountryRegion();
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomer(
            CountryRegionCode, VATBusPostingGroupCode, LibraryERM.GenerateVATRegistrationNo(CountryRegionCode)));
    end;

    local procedure CreateSalesHeaderWithVATBusGrp(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; VATBusPostingGroupCode: Code[20])
    var
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := CreateCountryRegion();
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType, CreateCustomer(
            CountryRegionCode, VATBusPostingGroupCode, LibraryERM.GenerateVATRegistrationNo(CountryRegionCode)));
    end;

    local procedure CreateSalesHeaderWithVATBusGrpAndLocation(var SalesHeader: Record "Sales Header"; VATBusPostingGroupCode: Code[20]; LocationCode: Code[10])
    begin
        CreateSalesHeaderWithVATBusGrp(SalesHeader, "Sales Document Type"::Invoice, VATBusPostingGroupCode);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreatePurchHeaderWithVATBusGrp(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Sales Document Type"; VATBusPostingGroupCode: Code[20])
    var
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := CreateCountryRegion();
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType, CreateVendor(
            CountryRegionCode, VATBusPostingGroupCode, LibraryERM.GenerateVATRegistrationNo(CountryRegionCode)));
    end;

    local procedure CreatePurchHeaderWithVATBusGrpAndLocation(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGroupCode: Code[20]; LocationCode: Code[10])
    begin
        CreatePurchHeaderWithVATBusGrp(PurchaseHeader, "Purchase Document Type"::Invoice, VATBusPostingGroupCode);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateServiceLineWithVATProdGrp(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; VATProdPostingGroupCode: Code[20])
    begin
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(VATProdPostingGroupCode), LibraryRandom.RandIntInRange(10, 20));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateSalesLineWithVATProdGrp(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; VATProdPostingGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATProdPostingGroupCode), LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithVATGenProdGroup(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; VATProdPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
    end;

    local procedure CreatePurchLineWithVATProdGrp(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; VATProdPostingGroupCode: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATProdPostingGroupCode), LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineWithVATGenProdGroup(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; VATProdPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        Item.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure ApplySalesInvoiceDisc(var SalesHeader: Record "Sales Header")
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        SalesHeader.CalcFields(Amount);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesHeader.Amount / 4, SalesHeader);
        SalesHeader.CalcFields(Amount);
    end;

    local procedure ApplyPurchInvoiceDisc(var PurchaseHeader: Record "Purchase Header")
    var
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        PurchaseHeader.CalcFields(Amount);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(PurchaseHeader.Amount / 4, PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);
    end;

    local procedure ModifyServiceHeaderEU3PartyTrade(var ServiceHeader: Record "Service Header"; EU3PartyTrade: Boolean)
    begin
        ServiceHeader.Validate("EU 3-Party Trade", EU3PartyTrade);
        ServiceHeader.Modify(true);
    end;

    local procedure ModifySalesHeaderEU3PartyTrade(var SalesHeader: Record "Sales Header"; EU3PartyTrade: Boolean)
    begin
        SalesHeader.Validate("EU 3-Party Trade", EU3PartyTrade);
        SalesHeader.Modify(true);
    end;

    local procedure ModifySalesHeaderPostingDate(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure ModifyPurchHeaderPostingDate(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    begin
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceTwoLinesWithDiffVATProdPostingGroups(var PurchaseHeader: Record "Purchase Header"; var TotalAmount: Decimal; VATBusinessPostingGroupCode: Code[20]; PostingDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LineIndex: Integer;
    begin
        CreatePurchHeaderWithVATBusGrp(PurchaseHeader, "Purchase Document Type"::Invoice, VATBusinessPostingGroupCode);
        ModifyPurchHeaderPostingDate(PurchaseHeader, PostingDate);
        for LineIndex := 1 to 2 do begin
            CreateVATPostingSetupForBusGroup(VATPostingSetup, VATBusinessPostingGroupCode);
            CreatePurchLineWithVATProdGrp(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");
        end;
        PurchaseHeader.CalcFields(Amount);
        TotalAmount := PurchaseHeader.Amount;
    end;

    local procedure CreateSalesInvoiceTwoLinesWithDiffVATProdPostingGroups(var SalesHeader: Record "Sales Header"; var TotalAmount: Decimal; VATBusinessPostingGroupCode: Code[20]; PostingDate: Date)
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        LineIndex: Integer;
    begin
        CreateSalesHeaderWithVATBusGrp(SalesHeader, "Sales Document Type"::Invoice, VATBusinessPostingGroupCode);
        ModifySalesHeaderPostingDate(SalesHeader, PostingDate);
        for LineIndex := 1 to 2 do begin
            CreateVATPostingSetupForBusGroup(VATPostingSetup, VATBusinessPostingGroupCode);
            CreateSalesLineWithVATProdGrp(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group");
        end;
        SalesHeader.CalcFields(Amount);
        TotalAmount := SalesHeader.Amount;
    end;

    local procedure CreateAndPostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; PostingDate: Date): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo, PostingDate);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and invoice.
        exit(PurchaseLine.Amount);
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, WorkDate());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseInvoiceWithOrderAddressAndLocationCode(VendorNo: Code[20]; InventoryPostingGroupCode: Code[20]; PostingDate: Date; LocationCode: Code[10]; OrderAddressCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, PostingDate);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Validate("Order Address Code", OrderAddressCode);
        PurchaseHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Inventory Posting Group", InventoryPostingGroupCode);
        Item.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Receive and invoice.
    end;

    local procedure CreateAndPostPurchaseCreditMemo(VendorNo: Code[20]; PurchaseInvoiceNo: Code[20]; PostingDate: Date) PostedDocNo: Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        PostedDocNo := PostPurchCrMemo(VendorNo, Item."No.", PurchaseInvoiceNo, PostingDate, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateAndPostPurchaseCrMemoWithCustomAmount(VendorNo: Code[20]; ItemNo: Code[20]; PurchaseInvoiceNo: Code[20]; PostingDate: Date; Amount: Decimal)
    begin
        PostPurchCrMemo(VendorNo, ItemNo, PurchaseInvoiceNo, PostingDate, Amount);
    end;

    local procedure CreateAndPostCorrectivePurchCrMemo(VendorNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; CorrectedInvNo: Code[20]): Decimal
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", VendorNo, PostingDate);
        PurchHeader.Validate("Corrected Invoice No.", CorrectedInvNo);
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        exit(PurchLine.Amount);
    end;

    local procedure PostPurchCrMemo(VendorNo: Code[20]; ItemNo: Code[20]; PurchaseInvoiceNo: Code[20]; PostingDate: Date; Amount: Decimal) PostedDocNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Create header
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, PostingDate);
        PurchaseHeader.Validate("Corrected Invoice No.", PurchaseInvoiceNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        // Create line
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        // Post
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseLineWithVAT(PurchaseHeader: Record "Purchase Header"; VATProdPostGroup: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATProdPostGroup), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchInvoiceNoTax(CountryRegionCode: Code[10]; var VendorNo: Code[20]; var Amount: Decimal; var PostingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateNoTaxableVATPostingSetup(VATPostingSetup, false); // "EU Service" is FALSE
        VendorNo :=
          CreateVendor(CountryRegionCode, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(CountryRegionCode));

        PostingDate := CalcDate(StrSubstNo('<%1Y>', LibraryRandom.RandIntInRange(10, 20)), WorkDate());
        Amount :=
          CreateAndPostPurchaseDocument(
            PurchaseHeader."Document Type"::Invoice, VendorNo,
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), PostingDate);
    end;

    local procedure CreateAndPostSalesDocument(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; EUThirdPartyTrade: Boolean): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo, PostingDate, EUThirdPartyTrade);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        exit(SalesLine.Amount);
    end;

    local procedure CreateAndPostSalesDocumentFixedAmount(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; FixedAmount: Decimal): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo, PostingDate, false);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Unit Price", FixedAmount);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine.Amount);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, WorkDate(), false);
        CreateSalesLine(SalesHeader, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoiceWithShippingAndLocationCode(CustomerNo: Code[20]; InventoryPostingGroupCode: Code[20]; PostingDate: Date; LocationCode: Code[10]; ShipToCode: Code[10]; EUThirdPartyTrade: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, PostingDate, EUThirdPartyTrade);
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Ship-to Code", ShipToCode);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Inventory Posting Group", InventoryPostingGroupCode);
        Item.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDecInDecimalRange(20, 30, 2));  // Take random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInDecimalRange(200, 300, 2));
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Ship and Invoice.
    end;

    local procedure CreateAndPostSalesCreditMemo(CustomerNo: Code[20]; SalesInvoiceNo: Code[20]; PostingDate: Date; EUThirdPartyTrade: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(PostSalesCrMemo(CustomerNo, Item."No.", SalesInvoiceNo, PostingDate, EUThirdPartyTrade, LibraryRandom.RandDec(100, 2)));
    end;

    local procedure CreateAndPostSalesCrMemoWithCustomAmount(CustomerNo: Code[20]; ItemNo: Code[20]; SalesInvoiceNo: Code[20]; PostingDate: Date; EUThirdPartyTrade: Boolean; Amount: Decimal)
    begin
        PostSalesCrMemo(CustomerNo, ItemNo, SalesInvoiceNo, PostingDate, EUThirdPartyTrade, Amount);
    end;

    local procedure CreateCorrectiveServiceCrMemo(var ServiceHeader: Record "Service Header"; var Amount: Decimal; CustomerNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; CorrectedInvNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CustomerNo);
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Validate("Corrected Invoice No.", CorrectedInvNo);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(10, 20));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        Amount := ServiceLine."Amount Including VAT";
    end;

    local procedure CreateAndPostCorrectiveSalesCrMemo(CustomerNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; CorrectedInvNo: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, PostingDate, false);
        SalesHeader.Validate("Corrected Invoice No.", CorrectedInvNo);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine.Amount);
    end;

    local procedure CreateAndPostCorrectiveSalesCrMemoCustomAmount(CustomerNo: Code[20]; ItemNo: Code[20]; PostingDate: Date; CorrectedInvNo: Code[20]; Amount: Decimal): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, PostingDate, false);
        SalesHeader.Validate("Corrected Invoice No.", CorrectedInvNo);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine.Amount);
    end;

    local procedure PostSalesCrMemo(CustomerNo: Code[20]; ItemNo: Code[20]; SalesInvoiceNo: Code[20]; PostingDate: Date; EUThirdPartyTrade: Boolean; Amount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Corrected Invoice No.", SalesInvoiceNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("EU 3-Party Trade", EUThirdPartyTrade);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesLineWithVAT(SalesHeader: Record "Sales Header"; VATProdPostGroup: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATProdPostGroup), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoiceNoTax(CountryRegionCode: Code[10]; EUService: Boolean; var CustomerNo: Code[20]; var Amount: Decimal; var PostingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        CreateNoTaxableVATPostingSetup(VATPostingSetup, EUService);
        CustomerNo :=
          CreateCustomer(
            CountryRegionCode, VATPostingSetup."VAT Bus. Posting Group",
            LibraryERM.GenerateVATRegistrationNo(CountryRegionCode));
        PostingDate := CalcDate(StrSubstNo('<%1Y>', LibraryRandom.RandIntInRange(10, 20)), WorkDate());
        Amount := CreateAndPostSalesDocument(
            SalesHeader."Document Type"::Invoice, CustomerNo,
            CreateItem(VATPostingSetup."VAT Prod. Posting Group"), PostingDate, false);
    end;

    local procedure CreateAndPostSalesInvoiceNoTaxForNationalCustomer(EUService: Boolean; var CustomerNo: Code[20]; var Amount: Decimal; var PostingDate: Date)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CreateAndPostSalesInvoiceNoTax(CompanyInformation."Country/Region Code", EUService, CustomerNo, Amount, PostingDate);
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Validate(
          "VAT Registration No. digits",
          CreateUniqueVATRegistrationNoFormat(CountryRegion));
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateCountryWithSpecificVATRegNoFormat(VATRegNoHasCountryPrefix: Boolean): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CopyStr(CountryRegion.Code, 1, 2)); // emulate EU country
        CountryRegion.Validate(
          "VAT Registration No. digits",
          CreateVATRegistrationNoFormat(CountryRegion, VATRegNoHasCountryPrefix));
        CountryRegion.Modify();

        exit(CountryRegion.Code);
    end;

    local procedure CreateCountryRegionNotEU(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CreateVATRegistrationNoFormat(CountryRegion, false);
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomer(CountryRegionCode: Code[10]; VATBusPostingGroup: Code[20]; VATRegistrationNo: Text): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Validate("VAT Registration No.", VATRegistrationNo);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateForeignCustomerWithVATRegNo(CountryRegionCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        // make the unique name to simplify the search of file line
        Customer.Name := LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer);
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegionCode); // to skip validation error
        Customer.Modify(true);

        exit(Customer."No.");
    end;

    local procedure CreateForeignVendorWithVATRegNo(CountryRegionCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        // make the unique name to simplify the search of file line
        Vendor.Name := LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Customer);
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegionCode); // to skip validation error
        Vendor.Modify(true);

        exit(Vendor."No.");
    end;

    local procedure CreateNationalCustomerWithVATRegNo(VATBusGroup: Code[20]): Code[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(
          CreateCustomer(CompanyInformation."Country/Region Code", VATBusGroup,
            LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code")));
    end;

    local procedure CreateNationalVendorWithVATRegNo(VATBusGroup: Code[20]): Code[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(
          CreateVendor(CompanyInformation."Country/Region Code", VATBusGroup,
            LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code")));
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PostingDate: Date; EUThirdPartyTrade: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("EU 3-Party Trade", EUThirdPartyTrade);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(3, 10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; GenBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATProdPostingGroupCode);
        GenProductPostingGroup.Validate("Auto Insert Default", true);
        GenProductPostingGroup.Modify(true);

        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroupCode, GenProductPostingGroup.Code);
        GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GeneralPostingSetup.Validate("Sales Credit Memo Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupForBusGroup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusGroupCode, VATProductPostingGroup.Code);
    end;

    local procedure CreateNoTaxableVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean)
    begin
        CreateVATPostingSetup(VATPostingSetup, EUService);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateUniqueVATRegistrationNoFormat(CountryRegion: Record "Country/Region"): Integer
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegion.Code);
        VATRegistrationNoFormat.Validate(Format, LibraryUtility.GenerateGUID());
        VATRegistrationNoFormat.Modify(true);
        exit(StrLen(VATRegistrationNoFormat.Format));
    end;

    local procedure CreateVATRegistrationNoFormat(CountryRegion: Record "Country/Region"; VATRegNoHasCountryPrefix: Boolean) VATRegistrationNoDigits: Integer
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNoFormat: Text[20];
    begin
        VATRegNoFormat := '#########';
        VATRegistrationNoDigits := StrLen(VATRegNoFormat);
        if VATRegNoHasCountryPrefix then
            VATRegNoFormat := CountryRegion."EU Country/Region Code" + VATRegNoFormat;

        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegion.Code);
        VATRegistrationNoFormat.Validate(Format, VATRegNoFormat);
        VATRegistrationNoFormat.Modify(true);
    end;

    local procedure CreateVendor(CountryRegionCode: Code[10]; VATBusPostingGroup: Code[20]; VATRegistrationNo: Text): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Validate("VAT Registration No.", VATRegistrationNo);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetExpectedVATRegNoPart(VATRegNo: Text; CountryRegionCode: Code[10]; VATRegNoHasCountryPrefix: Boolean): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        // VAT registration number part - country code prefix + digit part of VAT Reg. No.
        if VATRegNoHasCountryPrefix then
            exit(VATRegNo);

        CountryRegion.Get(CountryRegionCode);
        exit(CountryRegion."EU Country/Region Code" + VATRegNo);
    end;

    local procedure GetSalesCrMemoDocAmount(SalesCrMemoNo: Code[20]): Decimal
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoNo);
        SalesCrMemoLine.FindFirst();
        exit(SalesCrMemoLine.Amount);
    end;

    local procedure GetSalesInvoiceDocAmount(SalesInvoiceNo: Code[20]): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceNo);
        SalesInvoiceLine.FindFirst();
        exit(SalesInvoiceLine.Amount);
    end;

    local procedure GetPurchaseCrMemoDocAmount(PurchaseCrMemoNo: Code[20]): Decimal
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", PurchaseCrMemoNo);
        PurchCrMemoLine.FindFirst();
        exit(PurchCrMemoLine.Amount);
    end;

    local procedure GenerateRandomCode(NumberOfDigit: Integer) DeclarationNumber: Text[1024]
    var
        i: Integer;
    begin
        for i := 1 to NumberOfDigit do
            DeclarationNumber := InsStr(DeclarationNumber, Format(LibraryRandom.RandInt(9)), i);
    end;

    local procedure GetPostingPeriodForMake349Declaration(PostingDate: Date; Delta: Integer) Period: Text[2]
    var
        PeriodNumber: Integer;
    begin
        PeriodNumber := Date2DMY(PostingDate, 2);
        PeriodNumber += Delta;
        if PeriodNumber > 12 then
            PeriodNumber := 12;
        Period := Format(PeriodNumber);
        if StrLen(Period) = 1 then
            Period := '0' + Period;
        exit(Period);
    end;

    local procedure FindLastPurchInvNo(VendNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pay-to Vendor No.", VendNo);
        PurchInvHeader.FindLast();
        exit(PurchInvHeader."No.");
    end;

    local procedure FindLastSalesInvNo(CustNo: Code[20]): Code[20]
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.SetRange("Bill-to Customer No.", CustNo);
        SalesInvHeader.FindLast();
        exit(SalesInvHeader."No.");
    end;

    local procedure FindLastServInvNo(CustNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Customer No.", CustNo);
        ServiceInvoiceHeader.FindLast();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure AssignPaymentTermsToCustomer(CustNo: Code[20])
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        Customer.Get(CustNo);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);
    end;

    local procedure AssignPaymentTermsToVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);

        Vendor.Get(VendorNo);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure Make349DeclarationReportWithPurchaseDocument(EUService: Boolean; VATRegistrationNo: Text[20]; FileName: Text; CountryCode: Code[10]; PostingDate: Date; PostingDate2: Date; var Amount: Decimal) VendorNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemNo: Code[20];
    begin
        // Setup: Create and post Purchase Order and Purchase Credit Memo.
        CreateVATPostingSetup(VATPostingSetup, EUService);
        VendorNo := CreateVendor(CountryCode, VATPostingSetup."VAT Bus. Posting Group", VATRegistrationNo);
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        Amount := CreateAndPostPurchaseDocument(PurchaseLine."Document Type"::Invoice, VendorNo, ItemNo, PostingDate);
        CreateAndPostPurchaseDocument(PurchaseLine."Document Type"::"Credit Memo", VendorNo, ItemNo, PostingDate);
        LibraryVariableStorage.Enqueue(PostingDate2);  // Enqueue for Make349DeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(1000, 2000));  // Take random OriginalDeclaredAmount. Enqueue for CustomerVendorWarningsModalPageHandler.

        // Exercise.
        RunMake349DeclarationReport(FileName);
    end;

    local procedure Make349DeclarationReportWithSalesDocument(EUService: Boolean; EUThirdPartyTrade: Boolean; VATRegistrationNo: Text[20]; FileName: Text; CountryCode: Code[10]; PostingDate: Date; PostingDate2: Date; var Amount: Decimal): Code[20]
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        // Setup: Create and post Sales Order and Sales Credit Memo.
        CreateVATPostingSetup(VATPostingSetup, EUService);
        CustomerNo := CreateCustomer(CountryCode, VATPostingSetup."VAT Bus. Posting Group", VATRegistrationNo);
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        Amount := CreateAndPostSalesDocument(SalesLine."Document Type"::Invoice, CustomerNo, ItemNo, PostingDate, EUThirdPartyTrade);
        CreateAndPostSalesDocument(SalesLine."Document Type"::"Credit Memo", CustomerNo, ItemNo, PostingDate, EUThirdPartyTrade);
        LibraryVariableStorage.Enqueue(PostingDate2);  // Enqueue for Make349DeclarationRequestPageHandler.
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(1000, 2000));  // Take random OriginalDeclaredAmount. Enqueue for CustomerVendorWarningsModalPageHandler.

        // Exercise.
        RunMake349DeclarationReport(FileName);  // Opens Make349DeclarationRequestPageHandler.
        exit(CustomerNo);
    end;

    local procedure MockEUCountry(var CountryRegion: Record "Country/Region"; VATRegistrationNoDigits: Integer)
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CopyStr(CountryRegion.Code, 1, 2)); // emulate EU country
        CountryRegion."VAT Registration No. digits" := VATRegistrationNoDigits;
        CountryRegion.Modify();
    end;

    local procedure RunMake349DeclarationReport(FileName: Text)
    var
        Make349Declaration: Report "Make 349 Declaration";
    begin
        Commit(); // Commit Required;
        Make349Declaration.InitializeRequest(FileName);
        Make349Declaration.Run();
    end;

    local procedure RunMake349DeclarationReport2(FileName: Text[1024]; CountryRegionCode: Code[10]; ContactName: Text[20]; TelephoneNumber: Text[9]; DeclarationNumber: Text; FiscalYear: Variant): Text[1024]
    var
        Make349Declaration: Report "Make 349 Declaration";
        DeclarationMediaType: Option "Physical support",Telematic;
    begin
        Commit(); // Commit Required;

        LibraryVariableStorage.Enqueue(FiscalYear);
        LibraryVariableStorage.Enqueue(ContactName);
        LibraryVariableStorage.Enqueue(TelephoneNumber);
        LibraryVariableStorage.Enqueue(DeclarationNumber);
        LibraryVariableStorage.Enqueue(CountryRegionCode);
        LibraryVariableStorage.Enqueue(DeclarationMediaType::Telematic);

        if FileName <> '' then
            Make349Declaration.InitializeRequest(CopyStr(FileName, 1, 250));
        Make349Declaration.RunModal();

        exit(FileName);
    end;

    local procedure RunMake349DeclarationWithDate(PostingDate: Date) FileName: Text[1024]
    begin
        FileName := FileManagement.ServerTempFileName('.txt');
        LibraryVariableStorage.Enqueue(PostingDate);  // Enqueue for Make349DeclarationRequestPageHandler.
        RunMake349DeclarationReport(FileName);
    end;

    local procedure RunMake349DeclarationReportWithoutCorrection(var FileName: Text; PostingDate: Date)
    var
        Make349Declaration: Report "Make 349 Declaration";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(false);
        FileName := FileManagement.ServerTempFileName('.txt');
        Make349Declaration.InitializeRequest(FileName);
        Make349Declaration.Run();
    end;

    local procedure RunMake349DeclarationReportWithCorrection(var FileName: Text; PostingDate: Date; CustomerVendorNo: Code[20]; OriginalDeclaredAmount: Decimal)
    var
        Make349Declaration: Report "Make 349 Declaration";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(CustomerVendorNo);
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDate, 0));
        LibraryVariableStorage.Enqueue(OriginalDeclaredAmount);
        FileName := FileManagement.ServerTempFileName('.txt');
        Make349Declaration.InitializeRequest(FileName);
        Make349Declaration.Run();
    end;

    local procedure RunMake349DeclarationReportSimple(var FileName: Text; PostingDate: Date)
    var
        Make349Declaration: Report "Make 349 Declaration";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        FileName := FileManagement.ServerTempFileName('.txt');
        Make349Declaration.InitializeRequest(FileName);
        Make349Declaration.Run();
    end;

    local procedure RunMake349DeclarationReportWithCorrectOrigDeclFYSimple(PostingDate: Date; InvoicePostingYear: Integer)
    var
        Make349Declaration: Report "Make 349 Declaration";
        FileName: Text;
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(InvoicePostingYear);
        FileName := FileManagement.ServerTempFileName('.txt');
        Make349Declaration.InitializeRequest(FileName);
        Make349Declaration.Run();
    end;

    local procedure RunMake349DeclarationReportWithCorrectOrigDeclFY(PostingDate: Date; InvoicePostingYear: Integer)
    begin
        RunMake349DeclarationReportWithCorrectOrigDeclFY(PostingDate, InvoicePostingYear, '');
    end;

    local procedure RunMake349DeclarationReportWithCorrectOrigDeclFY(PostingDate: Date; InvoicePostingYear: Integer; ExcludedGenProductPostingGroup: Text[1024])
    var
        Make349Declaration: Report "Make 349 Declaration";
        DummyFileName: Text;
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(InvoicePostingYear);
        DummyFileName := FileManagement.ServerTempFileName('.txt');
        Make349Declaration.InitializeRequest(DummyFileName);
        if ExcludedGenProductPostingGroup <> '' then
            Make349Declaration.SetFilterString(StrSubstNo('<>%1', ExcludedGenProductPostingGroup));
        Make349Declaration.Run();
    end;

    local procedure RunMake349DeclarationReportWithCorrectOrigDeclPeriod(PostingDate: Date; PeriodExpression: Text)
    var
        Make349Declaration: Report "Make 349 Declaration";
        DummyFileName: Text;
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(PeriodExpression);
        DummyFileName := FileManagement.ServerTempFileName('.txt');
        Make349Declaration.InitializeRequest(DummyFileName); // required to avoid DOWNLOAD call
        Make349Declaration.Run();
    end;

    local procedure UpdateDeliveryOperCodeOnVATProdPostingGroup(VATProdPostingGroupCode: Code[20]; DeliveryOperationCode: Option)
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProdPostingGroup.Get(VATProdPostingGroupCode);
        VATProdPostingGroup.Validate("Delivery Operation Code", DeliveryOperationCode);
        VATProdPostingGroup.Modify(true);
    end;

    local procedure UpdateCorrectedInvoiceNoToBlankOnPostedSalesCrMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader."Corrected Invoice No." := '';
        SalesCrMemoHeader.Modify();
    end;

    local procedure UpdateCorrectedInvoiceNoToBlankOnPostedPurchaseCrMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
        PurchCrMemoHdr."Corrected Invoice No." := '';
        PurchCrMemoHdr.Modify();
    end;

    local procedure VerifyValuesOnGeneratedTextFile(ExportFileName: Text; StartingPosition: Integer; ExpectedValue: Variant)
    var
        FieldValue: Text[1024];
    begin
        FieldValue :=
          LibraryTextFileValidation.ReadValue(LibraryTextFileValidation.FindLineWithValue(
              ExportFileName, StartingPosition, StrLen(ExpectedValue), ExpectedValue), StartingPosition, StrLen(ExpectedValue));  // Starting Position is 133.
        Assert.AreEqual(ExpectedValue, FieldValue, ValueNotFoundMsg);
    end;

    local procedure VerifyValueNotPresentInGeneratedTextFile(ExportFileName: Text; StartingPosition: Integer; ExpectedValue: Variant)
    var
        FieldValue: Text;
    begin
        // ReadValue returns <blank> Text, if ExpectedValue was not found in any line of export file on specified StartingPosition
        FieldValue :=
          LibraryTextFileValidation.ReadValue(LibraryTextFileValidation.FindLineWithValue(
              ExportFileName, StartingPosition, StrLen(ExpectedValue), ExpectedValue), StartingPosition, StrLen(ExpectedValue));
        Assert.AreEqual('', FieldValue, '');
    end;

    local procedure VerifyNormalLine(LineText: Text; ExpOperationType: Text[1]; ExpAmount: Decimal)
    var
        OperationType: Text[1];
        LineAmount: Decimal;
    begin
        OperationType := CopyStr(LineText, 133, 1);
        Evaluate(LineAmount, CopyStr(LineText, 134, 13));
        LineAmount := LineAmount / 100;

        Assert.AreEqual(ExpOperationType, OperationType, '');
        Assert.AreEqual(ExpAmount, LineAmount, '');
    end;

    local procedure VerifyRectificationLine(LineText: Text; ExpOperationType: Text[1]; PostingDate: Date; ExpOriginalDeclarationAmt: Decimal; ExpPrevDeclarationAmt: Decimal)
    var
        OperationType: Text[1];
        Spaces: Text[13];
        Year: Text[4];
        Month: Text[2];
        OriginalDeclAmt: Decimal;
        PrevDeclAmt: Decimal;
    begin
        OperationType := CopyStr(LineText, 133, 1);
        Spaces := CopyStr(LineText, 134, 13);
        Year := CopyStr(LineText, 147, 4);
        Month := CopyStr(LineText, 151, 2);
        Evaluate(OriginalDeclAmt, CopyStr(LineText, 153, 13));
        Evaluate(PrevDeclAmt, CopyStr(LineText, 166, 13));
        OriginalDeclAmt := OriginalDeclAmt / 100;
        PrevDeclAmt := PrevDeclAmt / 100;

        Assert.AreEqual(ExpOperationType, OperationType, '');
        Assert.AreEqual(PadStr('', 13), Spaces, '');
        Assert.AreEqual(Format(Date2DMY(PostingDate, 3)), Year, '');
        Assert.AreEqual(GetPostingPeriodForMake349Declaration(PostingDate, 0), Month, '');
        Assert.AreEqual(ExpOriginalDeclarationAmt, OriginalDeclAmt, '');
        Assert.AreEqual(ExpPrevDeclarationAmt, PrevDeclAmt, '');
    end;

    local procedure TearDownSalesInvLine(CustomerNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Bill-to Customer No.", CustomerNo);
        SalesInvoiceLine.DeleteAll();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclFY(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declaration FY".SetValue(LibraryVariableStorage.DequeueInteger());
        LibraryVariableStorage.Enqueue(CustomerVendorWarnings349."Previous Declared Amount".Value);
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349ModalPageHandlerWithModifyOrigDeclPeriod(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declaration Period".SetValue(LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(CustomerVendorWarnings349."Previous Declared Amount".Value);
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349ModalPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    procedure CustVendWarnings349MultCorrectionsModalPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        repeat
            CustomerVendorWarnings349."Include Correction".SetValue(true);
        until CustomerVendorWarnings349.Next() = false;
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349PageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    var
        OriginalDeclaredAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(OriginalDeclaredAmount);
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declaration Period".SetValue(LibraryRandom.RandIntInRange(10, 12));
        CustomerVendorWarnings349."Original Declared Amount".SetValue(OriginalDeclaredAmount);
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349CustomPeriodPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349.FILTER.SetFilter("Customer/Vendor No.", LibraryVariableStorage.DequeueText());
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declaration Period".SetValue(LibraryVariableStorage.DequeueText());
        CustomerVendorWarnings349."Original Declared Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349CustomPeriodPageHandlerMultiple(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    var
        CustVenodrNo: Variant;
        OriginalDeclarationPeriod: Variant;
        OriginalDeclaredAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustVenodrNo);
        LibraryVariableStorage.Dequeue(OriginalDeclarationPeriod);
        LibraryVariableStorage.Dequeue(OriginalDeclaredAmount);

        CustomerVendorWarnings349.FILTER.SetFilter("Customer/Vendor No.", CustVenodrNo);
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declaration Period".SetValue(OriginalDeclarationPeriod);
        CustomerVendorWarnings349."Original Declared Amount".SetValue(OriginalDeclaredAmount);
        CustomerVendorWarnings349.Next();
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declaration Period".SetValue(OriginalDeclarationPeriod);
        CustomerVendorWarnings349."Original Declared Amount".SetValue(OriginalDeclaredAmount);

        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349DiffPeriodPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349.FILTER.SetFilter("Customer/Vendor No.", LibraryVariableStorage.DequeueText());
        SetIncludeCustVendWarning349FieldsForPageHandler(CustomerVendorWarnings349);
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349MultipleDiffPeriodPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    var
        i: Integer;
    begin
        CustomerVendorWarnings349.FILTER.SetFilter("Customer/Vendor No.", LibraryVariableStorage.DequeueText());
        for i := 1 to 2 do begin
            SetIncludeCustVendWarning349FieldsForPageHandler(CustomerVendorWarnings349);
            CustomerVendorWarnings349.Next();
        end;
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349ChangeOrigDeclarPeriodPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349.FILTER.SetFilter("Customer/Vendor No.", LibraryVariableStorage.DequeueText());
        VerifyCustVendWarning349PrevDeclarAmountAfterChangeOrigDeclarPeriod(CustomerVendorWarnings349);
        CustomerVendorWarnings349.OK().Invoke(); // do not process entries because verification already done above
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349IncludeAllEntriesPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349.FILTER.SetFilter("Customer/Vendor No.", LibraryVariableStorage.DequeueText());
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declaration Period".SetValue(LibraryVariableStorage.DequeueText());
        CustomerVendorWarnings349."Original Declared Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        CustomerVendorWarnings349.Next();
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349IncludeAllEntriesModalPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        repeat
            CustomerVendorWarnings349."Include Correction".SetValue(true);
            CustomerVendorWarnings349."Original Declared Amount".SetValue(LibraryRandom.RandDecInRange(10, 20, 2));
        until CustomerVendorWarnings349.Next() = false;
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    procedure CustomerVendorWarnings349ModalPageHandlerGetPostingDate(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        LibraryVariableStorage.Enqueue(CustomerVendorWarnings349."Posting Date".Value);
        CustomerVendorWarnings349.Process.Invoke();
    end;

    [ModalPageHandler]
    procedure CustomerVendorWarnings349IncludeAllEntriesPageHandler2(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    var
        VendorNo: Variant;
        Amount: Variant;
        PostingDate: Variant;
    begin
        VendorNo := LibraryVariableStorage.DequeueText();
        Amount := LibraryVariableStorage.DequeueDecimal();
        PostingDate := LibraryVariableStorage.DequeueDate();
        CustomerVendorWarnings349.Filter.SetFilter("Customer/Vendor No.", VendorNo);
        CustomerVendorWarnings349.Filter.SetFilter("Posting Date", Format(PostingDate));
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349.Next();
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declared Amount".SetValue(Amount);
        CustomerVendorWarnings349.Process.Invoke();
    end;

    local procedure SetIncludeCustVendWarning349FieldsForPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declaration FY".SetValue(LibraryVariableStorage.DequeueText());
        CustomerVendorWarnings349."Original Declaration Period".SetValue(LibraryVariableStorage.DequeueText());
        CustomerVendorWarnings349."Previous Declared Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        CustomerVendorWarnings349."Original Declared Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
    end;

    local procedure VerifyCustVendWarning349PrevDeclarAmountAfterChangeOrigDeclarPeriod(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349."Include Correction".SetValue(true);
        CustomerVendorWarnings349."Original Declaration Period".SetValue(LibraryVariableStorage.DequeueText());
        CustomerVendorWarnings349."Previous Declared Amount".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    local procedure Make349DeclarationFillMandatoryFieldsOnReqPage(var Make349Declaration: TestRequestPage "Make 349 Declaration")
    var
        CompanyInformation: Record "Company Information";
        DeclarationMediaType: Option "Physical support",Telematic;
    begin
        CompanyInformation.Get();
        Make349Declaration.ContactName.SetValue(DeclarationMediaType::Telematic);
        Make349Declaration.TelephoneNumber.SetValue(GenerateRandomCode(9));
        Make349Declaration.DeclarationNumber.SetValue(GenerateRandomCode(13));
        Make349Declaration.CompanyCountryRegion.SetValue(CompanyInformation."Country/Region Code");
        Make349Declaration.DeclarationMediaType.SetValue(DeclarationMediaType::"Physical support");
        Make349Declaration.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make349DeclarationRequestPageHandler(var Make349Declaration: TestRequestPage "Make 349 Declaration")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        Make349Declaration.FiscalYear.SetValue(Date2DMY(PostingDate, 3));
        Make349Declaration.Period.SetValue(Date2DMY(PostingDate, 2));
        Make349DeclarationFillMandatoryFieldsOnReqPage(Make349Declaration);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make349DeclarationRequestPageHandlerWithQuarter(var Make349Declaration: TestRequestPage "Make 349 Declaration")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        Make349Declaration.FiscalYear.SetValue(Date2DMY(PostingDate, 3));
        Make349Declaration.Period.SetValue(12 + GetQuarterFromDate(PostingDate));
        Make349DeclarationFillMandatoryFieldsOnReqPage(Make349Declaration);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make349DeclarationRequestPageHandlerAnnualPeriod(var Make349Declaration: TestRequestPage "Make 349 Declaration")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        Make349Declaration.FiscalYear.SetValue(Date2DMY(PostingDate, 3));
        Make349Declaration.Period.SetValue(0);
        Make349DeclarationFillMandatoryFieldsOnReqPage(Make349Declaration);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make349DeclarationReportHandler(var Make349Declaration: TestRequestPage "Make 349 Declaration")
    var
        FiscalYear: Variant;
        ContactName: Variant;
        TelephoneNumber: Variant;
        DeclarationNumber: Variant;
        CountryCode: Variant;
        DeclarationMediaType: Variant;
    begin
        LibraryVariableStorage.Dequeue(FiscalYear);
        LibraryVariableStorage.Dequeue(ContactName);
        LibraryVariableStorage.Dequeue(TelephoneNumber);
        LibraryVariableStorage.Dequeue(DeclarationNumber);
        LibraryVariableStorage.Dequeue(CountryCode);
        LibraryVariableStorage.Dequeue(DeclarationMediaType);
        Make349Declaration.FiscalYear.SetValue(FiscalYear);
        Make349Declaration.ContactName.SetValue(ContactName);
        Make349Declaration.TelephoneNumber.SetValue(TelephoneNumber);
        Make349Declaration.DeclarationNumber.SetValue(DeclarationNumber);
        Make349Declaration.CompanyCountryRegion.SetValue(CountryCode);
        Make349Declaration.DeclarationMediaType.SetValue(DeclarationMediaType);
        Make349Declaration.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make349DeclarationRequestPageHandler2(var Make349Declaration: TestRequestPage "Make 349 Declaration")
    var
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        Make349Declaration.FiscalYear.SetValue(Date2DMY(PostingDate, 3));
        Make349Declaration.Period.SetValue(Date2DMY(PostingDate, 2));
        LibraryVariableStorage.Enqueue(false);
        Make349DeclarationFillMandatoryFieldsOnReqPage(Make349Declaration);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYesNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure SpecifyCorrectionsConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        CustVendWarning349: Record "Customer/Vendor Warning 349";
        OriginalDeclarationFY: Variant;
    begin
        // Check that we're responding to the right confirmation dialog
        Assert.IsTrue(StrPos(Question, SpecifyCorrectionsMsg) > 0, Question);

        // Retrieve parameters from test case
        LibraryVariableStorageForSpecifyCorrectionsConfirmHandler.Dequeue(OriginalDeclarationFY);

        // Auto-include all corrections
        CustVendWarning349.Reset();
        if CustVendWarning349.FindSet() then
            repeat
                CustVendWarning349.Validate("Include Correction", true);
                CustVendWarning349.Validate("Original Declaration FY", OriginalDeclarationFY);
                CustVendWarning349.Modify(true);
            until CustVendWarning349.Next() = 0;

        // Respond that the "user" does NOT want to specify corrections through another page - we
        // just did it programmatically above
        Reply := false;
    end;

    local procedure SetCustVendWarningsDataForHandler(PostingDate: Date; CustVendNo: Code[20]; EntryAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(CustVendNo);
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDate, 0));
        LibraryVariableStorage.Enqueue(EntryAmount);
        LibraryVariableStorageForMessages.Enqueue(CustomerVendorMsg);
        LibraryVariableStorageForSpecifyCorrectionsConfirmHandler.Enqueue(Format(Date2DMY(PostingDate, 3)));
    end;

    local procedure SetCustVendWarningsPrevDataForHandler(PostingDate: Date; PreviousPostingDate: Date; CustVendNo: Code[20]; PrevEntryAmount: Decimal; EntryAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(CustVendNo);
        LibraryVariableStorage.Enqueue(Format(Date2DMY(PreviousPostingDate, 3)));
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PreviousPostingDate, 0));
        LibraryVariableStorage.Enqueue(PrevEntryAmount);
        LibraryVariableStorage.Enqueue(EntryAmount);
        LibraryVariableStorageForMessages.Enqueue(CustomerVendorMsg);
        LibraryVariableStorageForSpecifyCorrectionsConfirmHandler.Enqueue(Format(Date2DMY(PostingDate, 3)));
    end;

    local procedure SetCustVendWarningsPrevDataMultipleForHandler(PostingDate: Date; PreviousPostingDate: Date; CustVendNo: Code[20]; PrevEntryAmount: Decimal; EntryAmount: array[2] of Decimal)
    var
        i: Integer;
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(CustVendNo);
        for i := 1 to ArrayLen(EntryAmount) do begin
            LibraryVariableStorage.Enqueue(Format(Date2DMY(PreviousPostingDate, 3)));
            LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PreviousPostingDate, 0));
            LibraryVariableStorage.Enqueue(PrevEntryAmount);
            LibraryVariableStorage.Enqueue(EntryAmount[i]);
        end;
        LibraryVariableStorageForMessages.Enqueue(CustomerVendorMsg);
        LibraryVariableStorageForSpecifyCorrectionsConfirmHandler.Enqueue(Format(Date2DMY(PostingDate, 3)));
    end;

    local procedure SetCustVendWarningsOrigDeclarPeriodChangeForHandler(PostingDate: Date; PreviousPostingDate: Date; CustVendNo: Code[20]; PrevDeclarAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(CustVendNo);
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PreviousPostingDate, 0));
        LibraryVariableStorage.Enqueue(PrevDeclarAmount);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure GenericMessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        if LibraryVariableStorageForMessages.Length() > 0 then begin
            LibraryVariableStorageForMessages.Dequeue(ExpectedMessage);
            Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
        end
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccSelectionHandler(var GLAccountSelection: TestPage "G/L Account Selection")
    var
        ExpectedAccountName: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAccountName);
        Assert.AreEqual(Format(ExpectedAccountName), GLAccountSelection.Name.Value, InvalidAccountNameErr);
    end;

    local procedure CompareFormattedText(Str1: Text[50]; Str2: Text[50]): Boolean
    var
        Make347Declaration: Report "Make 347 Declaration";
        TempString1: Text[100];
        TempString2: Text[100];
    begin
        if StrLen(Str1) <> StrLen(Str2) then
            exit(false);

        TempString1 := Make347Declaration.FormatTextName(Str1);
        TempString2 := Make347Declaration.FormatTextName(Str2);

        exit(TempString1 = TempString2);
    end;

    local procedure VerifyRectificationLineOrigAndPrevDeclAmounts(FileName: Text[1024]; LineNo: Integer; ExpOrigAmt: Decimal; ExpPrevAmt: Decimal)
    var
        CustomerVendorWarning349: Record "Customer/Vendor Warning 349";
        ActualValue: Decimal;
    begin
        Evaluate(ActualValue, LibraryTextFileValidation.ReadValueFromLine(FileName, LineNo, 153, 13)); // Original Declared Amount
        Assert.AreEqual(
          ExpOrigAmt,
          ActualValue / 100,
          StrSubstNo(ExportedValueErr, CustomerVendorWarning349.FieldCaption("Original Declared Amount")));

        Evaluate(ActualValue, LibraryTextFileValidation.ReadValueFromLine(FileName, LineNo, 166, 13)); // Previous Declared Amount
        Assert.AreEqual(
          ExpPrevAmt,
          ActualValue / 100,
          StrSubstNo(ExportedValueErr, CustomerVendorWarning349.FieldCaption("Previous Declared Amount")));
    end;

    local procedure VerifyCounterpartyLineVATRegNo(Name: Text; VATRegNo: Text; CountryRegionCode: Code[10]; VATRegNoHasCountryPrefix: Boolean; ExportFileName: Text[1024])
    var
        FileLine: Text;
        FieldValue: Text[1024];
    begin
        FileLine := LibraryTextFileValidation.FindLineContainingValue(ExportFileName, 1, 1024, Name);
        Assert.IsTrue(FileLine <> '', LineNotFoundErr);
        // take 17 symbols starting from 76 and remove trailing spaces
        FieldValue := DelChr(CopyStr(FileLine, 76, 17), '>', ' ');

        Assert.AreEqual(
          GetExpectedVATRegNoPart(
            VATRegNo,
            CountryRegionCode,
            VATRegNoHasCountryPrefix),
          FieldValue,
          IncorrectValueErr);
    end;

    local procedure SetRandomCompanyName()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Name := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify();
    end;

    local procedure ModifyVATSetup()
    var
        VATSetup: Record "VAT Setup";
    begin
        VATSetup.Get();
        if VATSetup."Non-Deductible VAT Is Enabled" then
            exit;

        LibraryVariableStorage.Enqueue(true); // To confirm Enable Non Deductible VAT.
        VATSetup.Validate("Enable Non-Deductible VAT", true);
        VATSetup.Validate("Show Non-Ded. VAT In Lines", true);
        VATSetup.Modify(true);
    end;

    local procedure ModifyVATPostingSetupWithNonDeductibleVAT(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(30));
        VATPostingSetup.Validate("VAT Identifier", LibraryRandom.RandText(20));
        VATPostingSetup.Validate("Allow Non-Deductible VAT", VATPostingSetup."Allow Non-Deductible VAT"::Allow);
        VATPostingSetup.Validate("Non-Deductible VAT %", LibraryRandom.RandInt(100));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateEUVendorWithPostingGroups(var Vendor: Record Vendor; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Country/Region Code", EUCountryCodeTxt);
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        Vendor.Modify(true);
    end;

    local procedure SetAllLocationAreEU(var EULocationList: List of [Code[20]])
    var
        Location: Record Location;
    begin
        Location.SetRange("Country/Region Code", '');
        if Location.FindSet() then
            repeat
                Location.Validate("Country/Region Code", EUCountryCodeTxt);
                Location.Modify(true);
                EULocationList.Add(Location.Code);
            Until Location.Next() = 0;
    end;

    local procedure SetAllCountryRegionAreEU(var EUCountryRegionList: List of [Code[10]])
    var
        CountryRegion: Record "Country/Region";
        Location: Record Location;
    begin
        if Location.FindSet() then
            repeat
                CountryRegion.Get(Location."Country/Region Code");
                if CountryRegion."EU Country/Region Code" = '' then begin
                    CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
                    CountryRegion.Modify(true);
                    EUCountryRegionList.Add(CountryRegion.Code);
                end;
            until Location.Next() = 0;
    end;

    local procedure CreateAndPostNonDeductibleVATPurchaseDocument(Vendor: Record Vendor; Item: Record Item): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        exit(DocumentNo);
    end;

    local procedure CreateEUCustomerWithPostingGroups(var Customer: Record Customer; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibrarySales.CreateCustomer(Customer);

        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Country/Region Code", EUCountryCodeTxt);
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(EUCountryCodeTxt));
        Customer.Modify(true);
    end;

    local procedure CreateAndPostNonDeductibleVATSalesDocument(Customer: Record Customer; Item: Record Item): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(1000));
        SalesLine.Validate("Unit Cost", LibraryRandom.RandInt(1000));
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        exit(DocumentNo);
    end;

    local procedure RestoreLocations(EULocationList: List of [Code[20]])
    var
        Location: Record Location;
        LocationCode: Code[20];
    begin
        foreach LocationCode in EULocationList do begin
            Location.Get(LocationCode);
            Location.Validate("Country/Region Code", '');
            Location.Modify(true);
        end;
    end;

    local procedure RestoreEUCountryRegions(EUCountryRegionList: List of [Code[10]])
    var
        CountryRegion: Record "Country/Region";
        CountryRegionCode: Code[10];
    begin
        foreach CountryRegionCode in EUCountryRegionList do begin
            CountryRegion.Get(CountryRegionCode);
            CountryRegion.Validate("EU Country/Region Code", '');
            CountryRegion.Modify(true);
        end;
    end;

    local procedure ModifyVATPostingSetupWithGLAccounts(VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
        VATPostingSetup.Validate("VAT %", 0);

        VATPostingSetup.Modify(true);
    end;

    local procedure CreateAndPostMultiplePurchaseDocument(Vendor: Record Vendor; Item: Record Item; var Amount: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Modify(true);
        Amount := PurchaseLine.Amount;
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        exit(DocumentNo);
    end;

    local procedure CreateAndPostMultipleSalesDocument(Customer: Record Customer; Item: Record Item; var Amount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Cost", LibraryRandom.RandInt(1000));
        SalesLine.Modify(true);
        Amount := SalesLine.Amount;
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        exit(DocumentNo);
    end;

    local procedure CreateAndPostMultiplePurchaseCreditMemoDocument(Vendor: Record Vendor; Item: Record Item; CorrectiveInvNo: Code[20]; var CrMemoAmt: Decimal; Amount: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        if CorrectiveInvNo <> '' then
            PurchaseHeader.Validate("Corrected Invoice No.", CorrectiveInvNo);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
        CrMemoAmt := -PurchaseHeader."Amount Including VAT";
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        exit(DocumentNo);
    end;

    local procedure CreateAndPostMultipleSalesCreditMemoDocument(Customer: Record Customer; Item: Record Item; CorrectiveInvNo: Code[20]; var CrMemoAmt: Decimal; Amount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        if CorrectiveInvNo <> '' then begin
            SalesHeader.Validate("Corrected Invoice No.", CorrectiveInvNo);
            SalesHeader.Modify(true);
        end;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesHeader.CalcFields("Amount Including VAT");
        SalesLine.Validate("Unit Cost", Amount);
        SalesLine.Modify(true);
        CrMemoAmt := -SalesHeader."Amount Including VAT";
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        exit(DocumentNo);
    end;

    local procedure EnqueueMultipleValues(VendorCustomerNo: Code[20]; InvoiceAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(VendorCustomerNo);
        LibraryVariableStorage.Enqueue(InvoiceAmount);
    end;
}

