codeunit 144008 "EB - Payment Journal Export"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [EB Payment Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryRandom: Codeunit "Library - Random";
        FileMgt: Codeunit "File Management";
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;
        NodeQuantityDoesNotMatchErr: Label 'The quantity of nodes does not match quantity of payments';
        IncorrectNodeNameErr: Label 'Incorrect node name';
        IncorrectNodeValueErr: Label 'Incorrect node value';
        UseCheckPaymentLine: Boolean;
        BlankPaymentJournalBankAccount: Boolean;
        ErrorMessage: Text;
        IncorrectErr: Label 'Incorrect error message.';
        LastBankAccount: Code[20];
        BlankVendorSwiftErr: Label 'The SWIFT Code field cannot be blank in payment journal line number 10000.';
        BlankSwiftErr: Label 'The SWIFT Code field cannot be blank for bank account number %1 in payment journal line number 10000.';
        BlankVendorIbanErr: Label 'The Beneficiary IBAN field cannot be blank in payment journal line number 10000.';
        BlankIbanErr: Label 'The IBAN field cannot be blank for bank account number %1 in payment journal line number 10000.';
        BlankVendorCurrencyCodeErr: Label 'The Bank Country/Region Code field cannot be blank in payment journal line number 10000.';
        BlankCurrencyCodeErr: Label 'The Country/Region Code field cannot be blank for bank account number %1 in payment journal line number 10000.';
        BlankSepaCodeunitErr: Label 'Check Object ID must have a value in Export Protocol: Code=%1. It cannot be zero or empty.';
        BlankSepaReportErr: Label 'Export Object ID must have a value in Export Protocol: Code=%1. It cannot be zero or empty.';
        SepaNotAllowedErr: Label 'The SEPA Allowed field cannot be No for country/region code DK in payment journal line number 10000.';
        BlankNoSeriesErr: Label 'The export number series cannot be blank in export protocol %1.';
        CurrencyMustBeEuroErr: Label 'The currency must be euro in payment journal line number 10000.';
        CurrencyCannotBeEuroErr: Label 'The currency cannot be euro in payment journal line number 10000.';
        ForeignCurrencyCode: Code[10];
        ShouldHaveBeenPostedErr: Label 'Should have been Posted';
        ForeignCurrencyIso: Code[3];
        AmountMustBePositiveErr: Label 'Amount must be positive in Gen. Journal Line Journal Template Name';
        OnlyOneBankAccountErr: Label 'Only one valid bank account should appear within the filter for this export protocol. ';
        PaymentLineBlankBankAccountErr: Label 'The Bank Account field cannot be blank in payment journal line number 10000.';
        NoPaymentInJournalErr: Label 'There is no Payment Journal Line within the filter.';
        DimensionCode: Code[20];
        VendorIbanTxt: Label 'BE68 5390 0754 7034';
        BankIbanTxt: Label 'BE55 4501 1574 8944';
        NotPositiveAmountErr: Label 'The amount must be positive for Vendor %1 and beneficiary bank account %2.', Comment = '%1 - Vendor No.; %2 - Bank Account;';
        DialogTok: Label 'Dialog';
        ErrorLogNotShownErr: Label 'Error Log was not shown.';
        YouCannotCreateDocumentVendorErr: Label 'You cannot create this type of document when Vendor %1 is blocked with type %2', Comment = '%1 - Vendor No; %2 - Blocked field';
        YouCannotCreateDocumentCustomerErr: Label 'You cannot create this type of document when Customer %1 is blocked with type %2', Comment = '%1 - Customer No; %2 - Blocked field';
        YouCannotCreateDocumentVendorPrivacyBlockedErr: Label 'You cannot create this type of document when Vendor %1 is blocked for privacy.', Comment = '%1 - Vendor No';
        YouCannotCreateDocumentCustomerPrivacyBlockedErr: Label 'You cannot create this type of document when Customer %1 is blocked for privacy.', Comment = '%1 - Customer No';
        InterbankClearingCodeOptionRef: Option " ",Normal,Urgent;
        PaymentMessageTxt: Label '011397265378';

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodes()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        PaymentCount: Integer;
        i: Integer;
        Swift: Code[20];
        VendorSwift: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        PaymentCount := LibraryRandom.RandIntInRange(2, 5);
        for i := 1 to PaymentCount do
            TotalAmount += CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        PostPaymentLines(VendorNo);

        // Verification
        VerifyXMLPaymentNodes(FileName, GetProtocolLastNoUsed(ExportProtocol), PaymentCount, TotalAmount);
        VerifyXMLBicNodes(FileName, Swift, VendorSwift);
        VerifyXMLIbanNodes(FileName, BankIbanTxt, VendorIbanTxt);
        VerifyXmlPaymentLinesPosted(VendorNo);
        VerifyVendLedgEntriesClosed(VendorNo, VendorLedgerEntry."Document Type"::Payment);
        VerifyXMLEndToEndIdNodes(FileName, PaymentCount);
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandlerNonEuro')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesPaymentsOnSeparateLine()
    var
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        PaymentCount: Integer;
        i: Integer;
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(false);

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        PaymentCount := LibraryRandom.RandIntInRange(2, 5);
        for i := 1 to PaymentCount do
            CreateAndPostPurchInv(VendorNo, false);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, true, InterbankClearingCodeOptionRef::" ");

        // Verification
        VerifyXmlSeparateLines(FileName);

        FileMgt.DeleteServerFile(FileName);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandlerNonEuro')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesCheckChrgBr()
    var
        ExportProtocol: Record "Export Protocol";
    begin
        VerifyPaymentInformationXMLNodesCheckChrgBrHelper(ExportProtocol."Code Expenses"::OUR, 'DEBT');
        VerifyPaymentInformationXMLNodesCheckChrgBrHelper(ExportProtocol."Code Expenses"::BEN, 'CRED');
        VerifyPaymentInformationXMLNodesCheckChrgBrHelper(ExportProtocol."Code Expenses"::SHA, 'SHAR');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifyPaymentInformationXMLNodesCheckChrgBrHelper(CodeExp: Option; ExpectedValue: Code[20])
    var
        ExportProtocol: Record "Export Protocol";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();

        ExportProtocol.Validate(Code, LibraryUtility.GenerateRandomCode(ExportProtocol.FieldNo(Code), DATABASE::"Export Protocol"));
        ExportProtocol.Validate("Code Expenses", CodeExp);
        ExportProtocol.Validate("Check Object ID", CODEUNIT::"Check Non Euro SEPA Payments");
        ExportProtocol.Validate("Export Object ID", REPORT::"File Non Euro SEPA Payments");
        ExportProtocol.Validate("Export No. Series", CreateNoSeries());
        ExportProtocol.Insert(true);

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol.Code, VendorSwift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, false);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol.Code, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");

        // Verification
        VerifyXMLChrgBrNodes(FileName, ExpectedValue);

        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesCurrencyCodes()
    begin
        VerifyPaymentInformationXMLNodesVendorVendorBankAndBankTemplate(
          '', '', '', '');
        VerifyPaymentInformationXMLNodesVendorVendorBankAndBankTemplate(
          '', ForeignCurrencyCode, ForeignCurrencyCode, '');
        VerifyPaymentInformationXMLNodesVendorVendorBankAndBankTemplate(
          '', '', ForeignCurrencyCode, '');
        VerifyPaymentInformationXMLNodesVendorVendorBankAndBankTemplate(
          '', ForeignCurrencyCode, '', '');
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesCurrencyCodesMustFail()
    begin
        VerifyPaymentInformationXMLNodesVendorVendorBankAndBankTemplate(
          ForeignCurrencyCode, '', '', Format(CurrencyMustBeEuroErr));
        VerifyPaymentInformationXMLNodesVendorVendorBankAndBankTemplate(
          ForeignCurrencyCode, ForeignCurrencyCode, '', Format(CurrencyMustBeEuroErr));
        VerifyPaymentInformationXMLNodesVendorVendorBankAndBankTemplate(
          ForeignCurrencyCode, ForeignCurrencyCode, ForeignCurrencyCode, Format(CurrencyMustBeEuroErr));
    end;

    local procedure VerifyPaymentInformationXMLNodesVendorVendorBankAndBankTemplate(VendorCurrency: Code[10]; VendorBankCurrency: Code[10]; BankCurrency: Code[10]; ExpectedError: Text[250])
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendorWithCurrency(CountryCode, ExportProtocol, Swift, VendorIbanTxt, VendorCurrency, VendorBankCurrency);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, BankCurrency, true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(ExpectedError, ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesNonEuroPurchaseHeaderInEuroSepa()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        CountryRegion: Record "Country/Region";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);
        CountryRegion.Get('DK');
        CountryRegion."SEPA Allowed" := true;
        CountryRegion.Modify();

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryRegion.Code, ExportProtocol, VendorSwift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, false);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");

        // Verification
        Assert.AreEqual(Format(CurrencyMustBeEuroErr), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesEuroPurchaseHeaderInNonEuroSepa()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        CountryRegion: Record "Country/Region";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(false);
        CountryRegion.Get('DK');
        CountryRegion."SEPA Allowed" := true;
        CountryRegion.Modify();

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryRegion.Code, ExportProtocol, VendorSwift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, ForeignCurrencyCode,
          true, false, InterbankClearingCodeOptionRef::" ");

        // Verification
        Assert.AreEqual(Format(CurrencyCannotBeEuroErr), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesNonEuroInEuroSepa()
    var
        CountryRegion: Record "Country/Region";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        PaymentCount: Integer;
        i: Integer;
        Swift: Code[20];
        VendorSwift: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        CountryRegion.Get('DK');
        CountryRegion."SEPA Allowed" := true;
        CountryRegion.Modify();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryRegion.Code, ExportProtocol, VendorSwift, VendorIbanTxt);
        PaymentCount := LibraryRandom.RandIntInRange(2, 5);
        for i := 1 to PaymentCount do
            TotalAmount += CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");

        // Verification
        VerifyXMLPaymentNodes(FileName, GetProtocolLastNoUsed(ExportProtocol), PaymentCount, TotalAmount);
        VerifyXMLBicNodes(FileName, Swift, VendorSwift);
        VerifyXMLIbanNodes(FileName, BankIbanTxt, VendorIbanTxt);
        VerifyXMLCountryNodes(FileName);
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankVendorCurrencyCode()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor('', ExportProtocol, VendorSwift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(Format(BlankVendorCurrencyCodeErr), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesPaymentJournalBlankBankAccount()
    begin
        VerifyPaymentInformationXMLNodesPaymentJournalBlankBankAccountTemplate(true);
        VerifyPaymentInformationXMLNodesPaymentJournalBlankBankAccountTemplate(false);
    end;

    local procedure VerifyPaymentInformationXMLNodesPaymentJournalBlankBankAccountTemplate(UseEuro: Boolean)
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(UseEuro);
        BlankPaymentJournalBankAccount := true;

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, UseEuro);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        asserterror ExportSuggestedPayment(
            FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(Format(OnlyOneBankAccountErr), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesPaymentJournalBlankBankAccountCheckLines()
    begin
        VerifyPaymentInformationXMLNodesPaymentJournalBlankBankAccountCheckLinesTemplate(true);
        VerifyPaymentInformationXMLNodesPaymentJournalBlankBankAccountCheckLinesTemplate(false);
    end;

    local procedure VerifyPaymentInformationXMLNodesPaymentJournalBlankBankAccountCheckLinesTemplate(UseEuro: Boolean)
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        VendorSwift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(UseEuro);
        BlankPaymentJournalBankAccount := true;

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, UseEuro);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        CheckPaymentLines(VendorNo, ExportProtocol);
        Assert.AreEqual(Format(PaymentLineBlankBankAccountErr), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankCurrencyCode()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, '', VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(StrSubstNo(BlankCurrencyCodeErr, LastBankAccount), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankVendorSwift()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        VendorNo := CreateVendor(CountryCode, ExportProtocol, '', VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(Format(BlankVendorSwiftErr), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankSwift()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, '', BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(StrSubstNo(BlankSwiftErr, LastBankAccount), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesMultiPaymentCheckNegativeAmountErr()
    begin
        VerifyPaymentInformationXMLNodesMultiPaymentCheckNegativeAmountErrTemplate(false);
        VerifyPaymentInformationXMLNodesMultiPaymentCheckNegativeAmountErrTemplate(true);
    end;

    local procedure VerifyPaymentInformationXMLNodesMultiPaymentCheckNegativeAmountErrTemplate(UseEuro: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        ExportCheckErrorLog: Record "Export Check Error Log";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(UseEuro);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, Swift, VendorIbanTxt);

        CreateAndPostPurchInv(VendorNo, UseEuro);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        if not UseEuro then begin
            PurchaseHeader.Validate("Currency Code", ForeignCurrencyCode);
            PurchaseHeader.Modify();
        end;
        PurchaseHeader.Modify();
        LibraryERM.FindGLAccount(GLAccount);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(5, 2));
        PurchaseLine.Validate("Direct Unit Cost", 2000);
        PurchaseLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);

        // [WHEN] Check Payment Lines
        Swift := GenerateBankAccSwiftCode();
        UseCheckPaymentLine := true;
        asserterror ExportSuggestedPayment(
            FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(Format(NoPaymentInJournalErr), CopyStr(GetLastErrorText, 1, 51), IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesCheckNegativeAmountErrNonEuro()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        ExportCheckErrorLog: Record "Export Check Error Log";
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(false);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, Swift, VendorIbanTxt);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Currency Code", ForeignCurrencyCode);
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        PurchaseHeader.Modify();
        LibraryERM.FindGLAccount(GLAccount);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(5, 2));
        PurchaseLine.Validate("Direct Unit Cost", -10);
        PurchaseLine.Modify(true);

        PurchaseHeader.Receive := true;
        PurchaseHeader.Invoice := true;

        // [WHEN] Check Payment Lines
        asserterror CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);
        Assert.IsTrue(StrPos(GetLastErrorText, Format(AmountMustBePositiveErr)) <> 0, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesCheckNegativeAmountErr()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        ExportCheckErrorLog: Record "Export Check Error Log";
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, Swift, VendorIbanTxt);

        CreateAndPostPurchInv(VendorNo, true);
        CreateAndPostPurchInv(VendorNo, true);
        CreateAndPostPurchInv(VendorNo, true);
        CreateAndPostPurchInv(VendorNo, true);
        CreateAndPostPurchInv(VendorNo, true);
        CreateAndPostPurchInv(VendorNo, true);
        CreateAndPostPurchInv(VendorNo, true);
        CreateAndPostPurchInv(VendorNo, true);
        CreateAndPostPurchInv(VendorNo, true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        PurchaseHeader.Modify();
        LibraryERM.FindGLAccount(GLAccount);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(5, 2));
        PurchaseLine.Validate("Direct Unit Cost", -10);

        PurchaseLine.Modify(true);

        PurchaseHeader.Receive := true;
        PurchaseHeader.Invoice := true;

        // [WHEN] Check Payment Lines
        asserterror CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);
        Assert.IsTrue(StrPos(GetLastErrorText, Format(AmountMustBePositiveErr)) <> 0, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesSepaNotAllowed()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        CountryRegion: Record "Country/Region";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);
        CountryRegion.Get('DK');
        CountryRegion."SEPA Allowed" := false;
        CountryRegion.Modify();

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        ExportSuggestedPayment(
          FileName, CountryRegion.Code, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(Format(SepaNotAllowedErr), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesVendorSepaNotAllowed()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        CountryRegion: Record "Country/Region";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);
        CountryRegion.Get('DK');
        CountryRegion."SEPA Allowed" := false;
        CountryRegion.Modify();

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryRegion.Code, ExportProtocol, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(Format(SepaNotAllowedErr), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankNoExportCodeunit()
    var
        ExportProtocol: Record "Export Protocol";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateRandomCode(ExportProtocol.FieldNo(Code), DATABASE::"Export Protocol"));
        ExportProtocol.Validate("Code Expenses", ExportProtocol."Code Expenses"::BEN);
        ExportProtocol.Validate("Export Object ID", REPORT::"File SEPA Payments");
        ExportProtocol.Validate("Export No. Series", CreateNoSeries());
        ExportProtocol.Insert(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol.Code, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        asserterror ExportSuggestedPayment(
            FileName, CountryCode, VendorNo, ExportProtocol.Code, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(StrSubstNo(BlankSepaCodeunitErr, ExportProtocol.Code), GetLastErrorText, IncorrectErr);

        // Cleanup
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankNoExportReport()
    var
        ExportProtocol: Record "Export Protocol";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateRandomCode(ExportProtocol.FieldNo(Code), DATABASE::"Export Protocol"));
        ExportProtocol.Validate("Code Expenses", ExportProtocol."Code Expenses"::BEN);
        ExportProtocol.Validate("Check Object ID", CODEUNIT::"Check SEPA Payments");
        ExportProtocol.Validate("Export No. Series", CreateNoSeries());
        ExportProtocol.Insert(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol.Code, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        asserterror ExportSuggestedPayment(
            FileName, CountryCode, VendorNo, ExportProtocol.Code, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(StrSubstNo(BlankSepaReportErr, ExportProtocol.Code), GetLastErrorText, IncorrectErr);

        // Cleanup
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankNoExportNoSeries()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        ExportProtocol: Record "Export Protocol";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateRandomCode(ExportProtocol.FieldNo(Code), DATABASE::"Export Protocol"));
        ExportProtocol.Validate("Code Expenses", ExportProtocol."Code Expenses"::BEN);
        ExportProtocol.Validate("Check Object ID", CODEUNIT::"Check SEPA Payments");
        ExportProtocol.Validate("Export Object ID", REPORT::"File SEPA Payments");
        ExportProtocol.Insert(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol.Code, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol.Code, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(StrSubstNo(BlankNoSeriesErr, ExportProtocol.Code), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankNoExportCodeunitNonEuro()
    var
        ExportProtocol: Record "Export Protocol";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateRandomCode(ExportProtocol.FieldNo(Code), DATABASE::"Export Protocol"));
        ExportProtocol.Validate("Code Expenses", ExportProtocol."Code Expenses"::BEN);
        ExportProtocol.Validate("Export Object ID", REPORT::"File Non Euro SEPA Payments");
        ExportProtocol.Validate("Export No. Series", CreateNoSeries());
        ExportProtocol.Insert(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol.Code, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, false);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        asserterror
          ExportSuggestedPayment(
            FileName, CountryCode, VendorNo, ExportProtocol.Code, Swift, BankIbanTxt, ForeignCurrencyCode,
            true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(StrSubstNo(BlankSepaCodeunitErr, ExportProtocol.Code), GetLastErrorText, IncorrectErr);

        // Cleanup
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankNoExportReportNonEuro()
    var
        ExportProtocol: Record "Export Protocol";
        CountryCode: Code[10];
        FileName: Text;
        VendorNo: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateRandomCode(ExportProtocol.FieldNo(Code), DATABASE::"Export Protocol"));
        ExportProtocol.Validate("Code Expenses", ExportProtocol."Code Expenses"::BEN);
        ExportProtocol.Validate("Check Object ID", CODEUNIT::"Check Non Euro SEPA Payments");
        ExportProtocol.Validate("Export No. Series", CreateNoSeries());
        ExportProtocol.Insert(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol.Code, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, false);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        asserterror
          ExportSuggestedPayment(
            FileName, CountryCode, VendorNo, ExportProtocol.Code, Swift, BankIbanTxt, ForeignCurrencyCode,
            true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(StrSubstNo(BlankSepaReportErr, ExportProtocol.Code), GetLastErrorText, IncorrectErr);

        // Cleanup
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankNoExportNoSeriesNonEuro()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        ExportProtocol: Record "Export Protocol";
        CountryCode: Code[10];
        FileName: Text;
        VendorNo: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateRandomCode(ExportProtocol.FieldNo(Code), DATABASE::"Export Protocol"));
        ExportProtocol.Validate("Code Expenses", ExportProtocol."Code Expenses"::BEN);
        ExportProtocol.Validate("Check Object ID", CODEUNIT::"Check Non Euro SEPA Payments");
        ExportProtocol.Validate("Export Object ID", REPORT::"File Non Euro SEPA Payments");
        ExportProtocol.Insert(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol.Code, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, false);

        // [WHEN] Suggest and Export Payments error on missing SWIFT
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol.Code, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(StrSubstNo(BlankNoSeriesErr, ExportProtocol.Code), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankVendorIban()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, '');
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing IBAN
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(Format(BlankVendorIbanErr), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,ErrorPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesBlankIban()
    var
        ExportCheckErrorLog: Record "Export Check Error Log";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        // Create payments
        Swift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, Swift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payments error on missing IBAN
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, '', '', true, false, InterbankClearingCodeOptionRef::" ");
        Assert.AreEqual(StrSubstNo(BlankIbanErr, LastBankAccount), ErrorMessage, IncorrectErr);

        // Cleanup
        ExportCheckErrorLog.DeleteAll();
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyCountryCodeInformationXMLNodes()
    var
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        VendorNo2: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
        ISOCountryCode: Code[2];
    begin
        // [FEATURE] [Country] [ISO Code]
        // [SCENARIO] Country's "ISO Code" is in exported XML file.

        // [GIVEN] Create setup and post Purchase Invoice for two Vendors.
        Initialize();
        CountryCode := FindCountryRegionISO(ISOCountryCode);
        ExportProtocol := CreateSEPAExportProtocol(true);
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateAndUpdateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        VendorNo2 := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);
        CreateAndPostPurchInv(VendorNo2, true);

        // [WHEN] Suggest and Export Payments.
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, StrSubstNo('%1|%2', VendorNo, VendorNo2), ExportProtocol, Swift, BankIbanTxt, '',
          true, false, InterbankClearingCodeOptionRef::" ");

        // [THEN] Verify Country Code in exported XML file.
        VerifyXMLCountryCodeNodeValue(FileName, VendorNo, VendorNo2, ISOCountryCode);

        // Tear Down.
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandlerNonEuro')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesNonEuro()
    var
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        PaymentCount: Integer;
        i: Integer;
        Swift: Code[20];
        VendorSwift: Code[20];
        TotalAmount: Decimal;
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(false);

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        PaymentCount := LibraryRandom.RandIntInRange(2, 5);
        for i := 1 to PaymentCount do
            TotalAmount += CreateAndPostPurchInv(VendorNo, false);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, ForeignCurrencyCode,
          true, false, InterbankClearingCodeOptionRef::" ");

        // Verify structure for exported payments
        VerifyXMLPaymentNodes(FileName, GetProtocolLastNoUsed(ExportProtocol), PaymentCount, TotalAmount);

        FileMgt.DeleteServerFile(FileName);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandlerNonEuro')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesMultiCurrencyNonEuro()
    var
        FileName: Text;
        FirstForeignCurrencyCodeIso: Code[3];
        SecondForeignCurrencyCode: Code[10];
        SecondForeignCurrencyCodeIso: Code[3];
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
        InvAmount1: Decimal;
        InvAmount2: Decimal;
    begin
        Initialize();

        // Preparation: create settings
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(false);

        // Create payments
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        InvAmount1 := CreateAndPostPurchInv(VendorNo, false);
        FirstForeignCurrencyCodeIso := ForeignCurrencyIso;
        CreateForeignCurrency(SecondForeignCurrencyCode, SecondForeignCurrencyCodeIso);
        ForeignCurrencyCode := SecondForeignCurrencyCode;
        ForeignCurrencyIso := SecondForeignCurrencyCodeIso;
        InvAmount2 := CreateAndPostPurchInv(VendorNo, false);

        // [WHEN] Suggest and Export Payments with mod97 Payment Message
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, ForeignCurrencyCode,
          true, false, InterbankClearingCodeOptionRef::" ");

        // Verify structure for exported payments
        VerifyXMLAmountCurrency(FileName, FirstForeignCurrencyCodeIso, SecondForeignCurrencyCodeIso, InvAmount1, InvAmount2);

        FileMgt.DeleteServerFile(FileName);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandlerNonEuro')]
    [Scope('OnPrem')]
    procedure VerifyCountryCodeInformationXMLNodesNonEuro()
    var
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        VendorNo2: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
        ISOCountryCode: Code[2];
    begin
        // [FEATURE] [Country] [ISO Code]
        // [SCENARIO] Non-Euro Country's "ISO Code" is in exported XML file.

        // [GIVEN] Create setup and post Purchase Invoice for two Vendors.
        Initialize();
        CountryCode := FindCountryRegionISO(ISOCountryCode);
        ExportProtocol := CreateSEPAExportProtocol(false);
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateAndUpdateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        VendorNo2 := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, false);
        CreateAndPostPurchInv(VendorNo2, false);

        // [WHEN] Suggest and Export Payments.
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, StrSubstNo('%1|%2', VendorNo, VendorNo2),
          ExportProtocol, Swift, BankIbanTxt, ForeignCurrencyCode, true, false, InterbankClearingCodeOptionRef::" ");

        // [THEN] Verify Country's "ISO Code" in exported XML file.
        VerifyXMLCountryCodeNodeValue(FileName, VendorNo, VendorNo2, ISOCountryCode);

        // Tear Down.
        FileMgt.DeleteServerFile(FileName);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyVendorLedgerEntryForCreditMemoAfterPostPayment()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        // Verify Purchase invoices and Credit Memo should be closed after posting General Journal with "Export Payment Lines"

        // [GIVEN] Create a new Export Protocol and Vendor, post Purchase Invoice for Vendor.
        Initialize();
        VendorNo := CreateVendorForExportSuggestedPayment(CountryCode, ExportProtocol);

        // Create a Puchase Invoice and Purchase Credit Memo
        CreateAndPostPurchInv(VendorNo, true);
        FindVendLedgEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.CalcFields(Amount);
        CreateAndPostPurchCreditMemo(VendorNo, true, -VendorLedgerEntry.Amount / LibraryRandom.RandIntInRange(2, 5)); // Make sure Credit Line Amount is less than Invoice Amount

        // Suggest and Export Payments.
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, StrSubstNo('%1', VendorNo), ExportProtocol, Swift, BankIbanTxt, '',
          false, false, InterbankClearingCodeOptionRef::" ");

        // [WHEN] Post Payment in General Journal
        PostPaymentLines(VendorNo);

        // [THEN] Verify Vendor Ledger Entry is Closed for Credit Memo
        VerifyVendLedgEntriesClosed(VendorNo, VendorLedgerEntry."Document Type"::"Credit Memo");

        // Tear Down.
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPaymentLinesActionsWithSeparateLineTrueFirst()
    var
        PaymJournalBatch: Record "Paym. Journal Batch";
        PaymentJournalLine: array[2] of Record "Payment Journal Line";
        ExportCheckErrorLogs: TestPage "Export Check Error Logs";
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        VendorSwift: Code[20];
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 375473] Result of EB Payment Journal entries check should not depend on sorting by "Separate Line" (1st line has "Separate Line" TRUE)

        Initialize();

        // [GIVEN] Prerequisites for Payment Journal Lines creation: Payment Journal Template and Batch, Country Code, Export protocol, Vendor created
        CreatePaymentJnlBatch(PaymJournalBatch);

        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);

        PaymentJournalLine[1].SetRange("Journal Template Name", PaymJournalBatch."Journal Template Name");
        PaymentJournalLine[1].SetRange("Journal Batch Name", PaymJournalBatch.Name);
        PaymentJournalLine[1].DeleteAll();

        // [GIVEN] 1st Payment Journal Line with positive Amount and "Separate Line" = TRUE
        CreatePaymentJournalLine(
          PaymentJournalLine[1], PaymJournalBatch, VendorNo,
          CreateBankAccount(
            CountryCode, VendorSwift, VendorIbanTxt, LibraryERM.CreateCurrencyWithRounding(), InterbankClearingCodeOptionRef::" "),
          LibraryRandom.RandDecInRange(1000, 2000, 2), true);

        // [GIVEN] 2nd Payment Journal Line with negative Amount and "Separate Line" = FALSE
        CreatePaymentJournalLine(
          PaymentJournalLine[2], PaymJournalBatch, VendorNo, PaymentJournalLine[1]."Bank Account", -LibraryRandom.RandDec(100, 2), false);

        // [WHEN] Calling "Check Payment Lines" action on "EB Payment Journal" page
        PaymentJournalLine[1].Get(
          PaymJournalBatch."Journal Template Name", PaymJournalBatch.Name, PaymentJournalLine[1]."Line No.");
        ExportCheckErrorLogs.Trap();
        asserterror CODEUNIT.Run(CODEUNIT::"Check SEPA Payments", PaymentJournalLine[1]);

        // [THEN] "The amount must be positive..." error caused by the 2nd Payment Journal Line appears
        Assert.AreEqual('', GetLastErrorText, ErrorLogNotShownErr);
        Assert.ExpectedErrorCode(DialogTok);
        ExportCheckErrorLogs."Error Message".AssertEquals(
          StrSubstNo(NotPositiveAmountErr, VendorNo, PaymentJournalLine[1]."Beneficiary Bank Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPaymentLinesActionsWithSeparateLineFalseFirst()
    var
        BankAccount: Record "Bank Account";
        PaymJournalBatch: Record "Paym. Journal Batch";
        PaymentJournalLine: array[2] of Record "Payment Journal Line";
        ExportCheckErrorLogs: TestPage "Export Check Error Logs";
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        VendorSwift: Code[20];
    begin
        // [FEATURE] [Payment Journal]
        // [SCENARIO 375473] Result of EB Payment Journal entries check should not depend on sorting by "Separate Line" (1st Payment Line has "Separate Line" FALSE)

        Initialize();

        // [GIVEN] Prerequisites for Payment Journal Lines creation: Payment Journal Template and Batch, Country Code, Export protocol, Vendor created
        CreatePaymentJnlBatch(PaymJournalBatch);

        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);

        LibraryERM.CreateBankAccount(BankAccount);

        PaymentJournalLine[1].SetRange("Journal Template Name", PaymJournalBatch."Journal Template Name");
        PaymentJournalLine[1].SetRange("Journal Batch Name", PaymJournalBatch.Name);
        PaymentJournalLine[1].DeleteAll();

        // [GIVEN] 1st Payment Journal Line with negative Amount and "Separate Line" = FALSE
        CreatePaymentJournalLine(
          PaymentJournalLine[1], PaymJournalBatch, VendorNo,
          CreateBankAccount(
            CountryCode, VendorSwift, VendorIbanTxt, LibraryERM.CreateCurrencyWithRounding(), InterbankClearingCodeOptionRef::" "),
          -LibraryRandom.RandDec(100, 2), false);

        // [GIVEN] 2nd Payment Journal Line with positive Amount and "Separate Line" = TRUE
        CreatePaymentJournalLine(
          PaymentJournalLine[2], PaymJournalBatch, VendorNo, PaymentJournalLine[1]."Bank Account",
          LibraryRandom.RandDecInRange(1000, 2000, 2), true);

        // [WHEN] Calling "Check Payment Lines" action on "EB Payment Journal" page
        PaymentJournalLine[1].Get(
          PaymJournalBatch."Journal Template Name", PaymJournalBatch.Name, PaymentJournalLine[1]."Line No.");
        ExportCheckErrorLogs.Trap();
        asserterror CODEUNIT.Run(CODEUNIT::"Check SEPA Payments", PaymentJournalLine[1]);

        // [THEN] "The amount must be positive..." error caused by the 1st Payment Journal Line appears
        Assert.AreEqual('', GetLastErrorText, ErrorLogNotShownErr);
        Assert.ExpectedErrorCode(DialogTok);
        ExportCheckErrorLogs."Error Message".AssertEquals(
          StrSubstNo(NotPositiveAmountErr, VendorNo, PaymentJournalLine[1]."Beneficiary Bank Account"));
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure ExportThreePaymentsAfterModifyTheSecondOneWithoutAutomaticPosting()
    var
        PaymJournalBatch: Record "Paym. Journal Batch";
        PaymentJournalLine: Record "Payment Journal Line";
        GenJournalLine: Record "Gen. Journal Line";
        CountryCode: Code[10];
        ExportProtocol: Code[20];
        VendorNo: Code[20];
        FileName: Text;
        Amounts: array[3] of Decimal;
    begin
        // [SCENARIO 379902] Export several payments after modifying one line amount in case of "Post General Journal Lines" = FALSE
        Initialize();

        // [GIVEN] Three purchase invoices, each with Amount = 1000.
        CreatePostThreePurchaseInvoices(VendorNo, CountryCode, ExportProtocol, Amounts);
        // [GIVEN] EB Payment Journal with "Batch Name" = "X1".
        CreatePaymentJnlBatch(PaymJournalBatch);
        // [GIVEN] Suggest vendor payments. As result 3 lines have been suggested, each with Amount = 1000.
        SuggestPayments(PaymJournalBatch, VendorNo);
        // [GIVEN] Modify Amount on second payment journal line: Amount = 700
        Amounts[2] := ModifySecondPaymentJournalLine(PaymJournalBatch);

        // [WHEN] Run "Export Payment Lines" with "Post General Journal Lines" = FALSE
        ExportPaymentLines(FileName, PaymJournalBatch, CountryCode, ExportProtocol, false, InterbankClearingCodeOptionRef::" ");

        // [THEN] There are two vendor payments have been created in General Journal
        FilterGenJnlLine(GenJournalLine, VendorNo);
        Assert.RecordCount(GenJournalLine, 2);
        // [THEN] There are three EB Payment Journal Lines in "Batch Name" = "X1", each with Status = "Posted"
        FilterPmtJnlLine(PaymentJournalLine, PaymJournalBatch, PaymentJournalLine.Status::Posted);
        Assert.RecordCount(PaymentJournalLine, 3);
        // [THEN] Generated XML file contains two payments: with Amount = 2000, 700
        VerifyXMLAmountCurrency(FileName, 'EUR', 'EUR', Amounts[1] + Amounts[3], Amounts[2]);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportThreePaymentsAfterModifyTheSecondOneWithAutomaticPosting()
    var
        PaymJournalBatch: Record "Paym. Journal Batch";
        PaymentJournalLine: Record "Payment Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CountryCode: Code[10];
        ExportProtocol: Code[20];
        VendorNo: Code[20];
        FileName: Text;
        Amounts: array[3] of Decimal;
    begin
        // [SCENARIO 379902] Export several payments after modifying one line amount in case of "Post General Journal Lines" = TRUE
        Initialize();

        // [GIVEN] Three purchase invoices, each with Amount = 1000.
        CreatePostThreePurchaseInvoices(VendorNo, CountryCode, ExportProtocol, Amounts);
        // [GIVEN] EB Payment Journal with "Batch Name" = "X1".
        CreatePaymentJnlBatch(PaymJournalBatch);
        // [GIVEN] Suggest vendor payments. As result 3 lines have been suggested, each with Amount = 1000.
        SuggestPayments(PaymJournalBatch, VendorNo);
        // [GIVEN] Modify Amount on second payment journal line: Amount = 700
        Amounts[2] := ModifySecondPaymentJournalLine(PaymJournalBatch);

        // [WHEN] Run "Export Payment Lines" with "Post General Journal Lines" = TRUE
        ExportPaymentLines(FileName, PaymJournalBatch, CountryCode, ExportProtocol, true, InterbankClearingCodeOptionRef::" ");

        // [THEN] There are two vendor payments have been posted
        FilterVendorLedgerEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Payment);
        Assert.RecordCount(VendorLedgerEntry, 2);
        // [THEN] There are three EB Payment Journal Lines in "Batch Name" = "X1", each with Status = "Posted"
        FilterPmtJnlLine(PaymentJournalLine, PaymJournalBatch, PaymentJournalLine.Status::Posted);
        Assert.RecordCount(PaymentJournalLine, 3);
        // [THEN] Generated XML file contains two payments with Amount = 2000, 700
        VerifyXMLAmountCurrency(FileName, 'EUR', 'EUR', Amounts[1] + Amounts[3], Amounts[2]);
    end;

    [Test]
    [HandlerFunctions('FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnExportBlockedVendor()
    var
        PaymentJournalLine: Record "Payment Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [SEPA] [Purchase]
        // [SCENARIO 382058] File SEPA Payments export should generate an error when vendor is blocked
        Initialize();

        // [GIVEN] Payment Journal Line for blocked Vendor
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Blocked := Vendor.Blocked::All;
        Vendor.Modify();
        MockPaymentJnlLine(
          PaymentJournalLine, PaymentJournalLine."Account Type"::Vendor, Vendor."No.", CreateSEPAExportProtocol(false));

        // [WHEN] Run File SEPA Payments report
        asserterror RunFileSEPAPaymentReport(PaymentJournalLine, GenerateFileName());

        // [THEN] Error thrown that You cannot create this type of document when Vendor is blocked
        Assert.ExpectedError(StrSubstNo(YouCannotCreateDocumentVendorErr, Vendor."No.", Vendor.Blocked));
    end;

    [Test]
    [HandlerFunctions('FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnExportBlockedCustomer()
    var
        PaymentJournalLine: Record "Payment Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [SEPA] [Sales]
        // [SCENARIO 382058] File SEPA Payments export should generate an error when customer is blocked
        Initialize();

        // [GIVEN] Payment Journal Line for blocked Customer
        LibrarySales.CreateCustomer(Customer);
        Customer.Blocked := Customer.Blocked::All;
        Customer.Modify();
        MockPaymentJnlLine(
          PaymentJournalLine, PaymentJournalLine."Account Type"::Customer, Customer."No.", CreateSEPAExportProtocol(false));

        // [WHEN] Run File SEPA Payments report
        asserterror RunFileSEPAPaymentReport(PaymentJournalLine, GenerateFileName());

        // [THEN] Error thrown that You cannot create this type of document when Customer is blocked
        Assert.ExpectedError(StrSubstNo(YouCannotCreateDocumentCustomerErr, Customer."No.", Customer.Blocked));
    end;

    [Test]
    [HandlerFunctions('FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnExportPrivacyBlockedVendor()
    var
        PaymentJournalLine: Record "Payment Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [SEPA] [Purchase]
        // [SCENARIO 382058] File SEPA Payments export should generate an error when vendor is blocked
        Initialize();

        // [GIVEN] Payment Journal Line for blocked Vendor
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Privacy Blocked" := true;
        Vendor.Modify();
        MockPaymentJnlLine(
          PaymentJournalLine, PaymentJournalLine."Account Type"::Vendor, Vendor."No.", CreateSEPAExportProtocol(false));

        // [WHEN] Run File SEPA Payments report
        asserterror RunFileSEPAPaymentReport(PaymentJournalLine, GenerateFileName());

        // [THEN] Error thrown that You cannot create this type of document when Vendor is blocked
        Assert.ExpectedError(StrSubstNo(YouCannotCreateDocumentVendorPrivacyBlockedErr, Vendor."No."));
    end;

    [Test]
    [HandlerFunctions('FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnExportPrivacyBlockedCustomer()
    var
        PaymentJournalLine: Record "Payment Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [SEPA] [Sales]
        // [SCENARIO 382058] File SEPA Payments export should generate an error when customer is blocked
        Initialize();

        // [GIVEN] Payment Journal Line for blocked Customer
        LibrarySales.CreateCustomer(Customer);
        Customer."Privacy Blocked" := true;
        Customer.Modify();
        MockPaymentJnlLine(
          PaymentJournalLine, PaymentJournalLine."Account Type"::Customer, Customer."No.", CreateSEPAExportProtocol(false));

        // [WHEN] Run File SEPA Payments report
        asserterror RunFileSEPAPaymentReport(PaymentJournalLine, GenerateFileName());

        // [THEN] Error thrown that You cannot create this type of document when Customer is blocked
        Assert.ExpectedError(StrSubstNo(YouCannotCreateDocumentCustomerPrivacyBlockedErr, Customer."No."));
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentWithAutomaticPosting()
    var
        PaymJournalBatch: Record "Paym. Journal Batch";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExportProtocol: Code[20];
        VendorNo: Code[20];
        CountryCode: Code[10];
        FileName: Text;
    begin
        // [FEATURE] [SEPA] [Export] [Purchase] [Suggest Vendor Payments]
        // [SCENARIO 211167] Fields "Bal. Account Type" and "Bal. Account No." of Vendor Ledger Entry should be blank after exporting payments with automatic posting
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PostPurchaseInvoice(CountryCode, ExportProtocol, VendorNo, true);

        // [GIVEN] EB Payment Journal.
        CreatePaymentJnlBatch(PaymJournalBatch);

        // [GIVEN] Gen. Journal Template and Gen. Journal Batch with "Bal. Account Type" = "G/L Account" and "Bal. Account No." = "GL0001"

        // [GIVEN] Suggest vendor payments.
        SuggestPayments(PaymJournalBatch, VendorNo);

        // [WHEN] Run "Export Payment Lines" with "Post General Journal Lines" = TRUE and using Gen. Journal Template and Gen. Journal Batch
        ExportPaymentLines(FileName, PaymJournalBatch, CountryCode, ExportProtocol, true, InterbankClearingCodeOptionRef::" ");

        // [THEN] "Gen. Journal Line"."Bal. Account No." = ''
        FilterVendorLedgerEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Bal. Account No.", '');

        // [THEN] "Gen. Journal Line"."Bal. Account Type" = "G/L Account"
        VendorLedgerEntry.TestField("Bal. Account Type", VendorLedgerEntry."Bal. Account Type"::"G/L Account");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentWithoutAutomaticPosting()
    var
        PaymJournalBatch: Record "Paym. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ExportProtocol: Code[20];
        VendorNo: Code[20];
        CountryCode: Code[10];
        FileName: Text;
    begin
        // [FEATURE] [SEPA] [Export] [Purchase] [Suggest Vendor Payments]
        // [SCENARIO 211167] Fields "Bal. Account Type" and "Bal. Account No." of Gen. Journal Line should be empty after exporting payments without automatic posting
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        PostPurchaseInvoice(CountryCode, ExportProtocol, VendorNo, true);

        // [GIVEN] EB Payment Journal.
        CreatePaymentJnlBatch(PaymJournalBatch);

        // [GIVEN] Gen. Journal Template and Gen. Journal Batch with "Bal. Account Type" = "G/L Account" and "Bal. Account No." = "GL0001"

        // [GIVEN] Suggest vendor payments.
        SuggestPayments(PaymJournalBatch, VendorNo);

        // [WHEN] Run "Export Payment Lines" with "Post General Journal Lines" = FALSE and using Gen. Journal Template and Gen. Journal Batch
        ExportPaymentLines(FileName, PaymJournalBatch, CountryCode, ExportProtocol, false, InterbankClearingCodeOptionRef::" ");

        // [THEN] "Gen. Journal Line"."Bal. Account No." = ''
        FilterGenJnlLine(GenJournalLine, VendorNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Bal. Account No.", '');

        // [THEN] "Gen. Journal Line"."Bal. Account Type" = ''
        GenJournalLine.TestField("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure ExportPaymentsForAccountsWithSameNo()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        PaymJournalBatch: Record "Paym. Journal Batch";
        ExportProtocol: Code[20];
        CustomerVendorNo: Code[20];
        CountryCode: Code[10];
        FileName: Text;
        DocNo: Code[20];
    begin
        // [FEATURE] [Export] [Purchase] [Sales]
        // [SCENARIO 221119] Exporting of Payment Journal create correct Gen. Journal Lines if Payment Lines have different "Account Type" and same "Account No."
        Initialize();

        // [GIVEN] Vendor with No. = "CVNo"
        // [GIVEN] Vendor Bank Account with "Code" = "CVBACode" and "Bank Account No." = "BA"
        // [GIVEN] "SWIFT" = "SWIFTCode", "IBAN" = "IBANNumber"
        // [GIVEN] Posted Purchase Invoice for Vendor "CVNo"
        PostPurchaseInvoice(CountryCode, ExportProtocol, CustomerVendorNo, true);

        // [GIVEN] Customer with No. = "CVNo"
        // [GIVEN] Customer Bank Account with "Code" = "CVBACode" and "Bank Account No." = "BA"
        // [GIVEN] "SWIFT" = "SWIFTCode", "IBAN" = "IBANNumber"
        CreateCustomerWithNoAndCountry(Customer, CustomerVendorNo, CountryCode);
        Customer.Validate(
          "Preferred Bank Account Code", CreateCustomerBankAccountWithCodeAndBankAccNo(CustomerVendorNo, CountryCode, ExportProtocol));
        Customer.Modify(true);

        // [GIVEN] Posted Credit Memo for Customer "CVNo"
        DocNo := CreatePostSalesCrMemo(CustomerVendorNo);

        // [GIVEN] EB Payment Journal.
        // [GIVEN] Gen. Journal Template and Gen. Journal Batch with "Bal. Account Type" = "G/L Account" and "Bal. Account No." = "GL0001"
        CreatePaymentJnlBatch(PaymJournalBatch);

        // [GIVEN] Suggested vendor payments for Vendor "CVNo"
        SuggestPayments(PaymJournalBatch, CustomerVendorNo);

        // [GIVEN] Payment line for Customer "CVNo"
        CreatePmtJournalLine(PaymJournalBatch, CustomerVendorNo, DocNo);
        Commit();

        // [WHEN] Run "Export Payment Line" using Gen. Journal Line and Gen. Journal Batch
        ExportPaymentLines(FileName, PaymJournalBatch, CountryCode, ExportProtocol, false, InterbankClearingCodeOptionRef::" ");

        // [THEN] General Journal contains 4 lines:
        // [THEN] Refund for Customer and Refund for G/L Account
        VerifyGenJnlLine(GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, CustomerVendorNo, 1);

        // [THEN] Payment for Vendor and Payment for G/L Account
        VerifyGenJnlLine(GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, CustomerVendorNo, 20000);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandlerNonEuro')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesPmtTpInfWithInstrPrtyNORM()
    var
        FileName: Text;
        ExportProtocol: Code[20];
        CountryCode: Code[10];
        VendorNo: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        // [FEATURE] [Export] [Purchase] [UT]
        // [SCENARIO 288144] PmtTpInf tag and InstrPrty tag with NORM value are included in Payment Export file
        Initialize();

        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(false);
        Swift := GenerateBankAccSwiftCode();
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        InterbankClearingCodeOptionRef := InterbankClearingCodeOptionRef::Normal;

        CreateAndPostPurchInv(VendorNo, false);
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, ForeignCurrencyCode,
          true, false, InterbankClearingCodeOptionRef);
        VerifyXMLPaymentNodesWithPmtTpInf(FileName, 'NORM');

        FileMgt.DeleteServerFile(FileName);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandlerNonEuro')]
    [Scope('OnPrem')]
    procedure VerifyPaymentInformationXMLNodesPmtTpInfWithInstrPrtyHIGH()
    var
        FileName: Text;
        ExportProtocol: Code[20];
        CountryCode: Code[10];
        VendorNo: Code[20];
        Swift: Code[20];
        VendorSwift: Code[20];
    begin
        // [FEATURE] [Export] [Purchase] [UT]
        // [SCENARIO 288144] PmtTpInf tag and InstrPrty tag with HIGH value are included in Payment Export file
        Initialize();

        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(false);
        Swift := GenerateBankAccSwiftCode();
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        InterbankClearingCodeOptionRef := InterbankClearingCodeOptionRef::Urgent;

        CreateAndPostPurchInv(VendorNo, false);
        ExportSuggestedPayment(
          FileName, CountryCode, VendorNo, ExportProtocol, Swift, BankIbanTxt, ForeignCurrencyCode,
          true, false, InterbankClearingCodeOptionRef);
        VerifyXMLPaymentNodesWithPmtTpInf(FileName, 'HIGH');

        FileMgt.DeleteServerFile(FileName);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsRequestPageHandlerWithGlobalDim1Code')]
    [Scope('OnPrem')]
    procedure ExportPaymentLinesWithModifiedDimensionValue()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        // [SCENARIO 338020] "Export Payment Lines" must consider modified dimension values in paymenyt journal line
        Initialize();

        VendorNo := CreateVendorForExportSuggestedPayment(CountryCode, ExportProtocol);
        CreateDimensionValueForGlobalDim1Code(DimensionValue);

        CreateAndPostPurchInv(VendorNo, true);
        FindVendLedgEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.CalcFields(Amount);
        CreateAndPostPurchCreditMemo(
            VendorNo, true, -VendorLedgerEntry.Amount / LibraryRandom.RandIntInRange(2, 5));

        Swift := GenerateBankAccSwiftCode();

        MockSelectedDimensionFileSEPAPaymentsReport();

        ExportSuggestedPaymentWithGlobalDim1ValueCode(
           FileName, CountryCode, StrSubstNo('%1', VendorNo), ExportProtocol, Swift, BankIbanTxt, '',
           false, false, InterbankClearingCodeOptionRef::" ", DimensionValue.Code);

        GenJournalLine.SetRange("Account No.", VendorNo);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue.Code);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsReportHandler,FileSEPAPaymentsReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyMessageToRecipientAndExportedToPaymentFileAfterExportPaymentLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text;
        CountryCode: Code[10];
        VendorNo: Code[20];
        ExportProtocol: Code[20];
        Swift: Code[20];
    begin
        // [FEATURE] [Export] [UT]
        // [SCENARIO 343110] Exporting payment line sets "Message to Recipient" and "Exported to Payment File" for created Gen. Journal line.
        Initialize();

        // [GIVEN] Export Protocol and Vendor.
        VendorNo := CreateVendorForExportSuggestedPayment(CountryCode, ExportProtocol);

        // [GIVEN] Purchase Invoice for Vendor.
        CreateAndPostPurchInv(VendorNo, true);

        // [WHEN] Suggest and Export Payment with Payment Message "X".
        Swift := GenerateBankAccSwiftCode();
        ExportSuggestedPayment(
          FileName, CountryCode, Format(VendorNo), ExportProtocol, Swift, BankIbanTxt, '',
          true, true, InterbankClearingCodeOptionRef::" ");

        // [THEN] Resulting Gen. Journal line has "Exported to Payment File" set to True and "Message to Recipient" is equal to "X"
        VerifyGenJnlLinePaymentInfo(GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo);

        // Tear Down.
        FileMgt.DeleteServerFile(FileName);
    end;

    [Test]
    [HandlerFunctions('FileSEPAPaymentsReportHandler')]
    procedure FileSEPAPaymentsTempBlobExport()
    var
        PaymentJournalLine: Record "Payment Journal Line";
        EBPaymentJournalExport: Codeunit "EB - Payment Journal Export";
    begin
        // [FEATURE] [SEPA] [File SEPA Payments]
        // [SCENARIO 393148] BE REP 2000005 "File SEPA Payments" report provides an event with TempBlob xml result
        Initialize();

        // [GIVEN] Payment Journal Line
        MockPaymentJnlLine(
          PaymentJournalLine, PaymentJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), CreateSEPAExportProtocol(false));

        // [WHEN] Run File SEPA Payments report
        BindSubscription(EBPaymentJournalExport);
        RunFileSEPAPaymentReport(PaymentJournalLine, GenerateFileName());

        // [THEN] Event "OnBeforeDownloadXmlFile" has been invoked including TempBlod with xml content
        // Verify in OnBeforeDownloadXmlFile()
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"EB - Payment Journal Export");
        LibraryVariableStorage.Clear();
        Clear(LastBankAccount);
        Clear(ErrorMessage);
        CreateForeignCurrency(ForeignCurrencyCode, ForeignCurrencyIso);
        BlankPaymentJournalBankAccount := false;
        UseCheckPaymentLine := false;
        InterbankClearingCodeOptionRef := InterbankClearingCodeOptionRef::" ";

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"EB - Payment Journal Export");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"EB - Payment Journal Export");
    end;

    local procedure CreatePostThreePurchaseInvoices(var VendorNo: Code[20]; var CountryCode: Code[10]; var ExportProtocol: Code[20]; var Amounts: array[3] of Decimal)
    var
        i: Integer;
    begin
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);

        VendorNo :=
          CreateVendor(CountryCode, ExportProtocol, GenerateBankAccSwiftCode(), VendorIbanTxt);
        for i := 1 to ArrayLen(Amounts) do
            Amounts[i] := CreateAndPostPurchInv(VendorNo, true);
    end;

    local procedure CreateForeignCurrency(var CurrencyCode: Code[10]; var CurrencyIso: Code[3])
    var
        ForeignCurrency: Record Currency;
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(Today, 10, 10);
        ForeignCurrency.Get(CurrencyCode);
        CurrencyIso := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(3, 0), 1, 3);
        ForeignCurrency.Validate("ISO Code", CurrencyIso);
        ForeignCurrency.Modify(true);
    end;

    local procedure CreateSEPAExportProtocol(UseEuro: Boolean): Code[20]
    var
        ExportProtocol: Record "Export Protocol";
    begin
        ExportProtocol.Validate(Code, LibraryUtility.GenerateRandomCode(ExportProtocol.FieldNo(Code), DATABASE::"Export Protocol"));
        ExportProtocol.Validate("Code Expenses", ExportProtocol."Code Expenses"::BEN);
        if UseEuro then begin
            ExportProtocol.Validate("Check Object ID", CODEUNIT::"Check SEPA Payments");
            ExportProtocol.Validate("Export Object ID", REPORT::"File SEPA Payments")
        end else begin
            ExportProtocol.Validate("Check Object ID", CODEUNIT::"Check Non Euro SEPA Payments");
            ExportProtocol.Validate("Export Object ID", REPORT::"File Non Euro SEPA Payments");
        end;
        ExportProtocol.Validate("Export No. Series", CreateNoSeries());
        ExportProtocol.Insert(true);
        exit(ExportProtocol.Code);
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(
          NoSeriesLine, NoSeries.Code,
          LibraryUtility.GenerateRandomCode(NoSeriesLine.FieldNo("Series Code"), DATABASE::"No. Series Line"), '');
        exit(NoSeries.Code);
    end;

    local procedure CreateBankAccount(CountryCode: Code[10]; Swift: Code[20]; BankIban: Code[50]; Currency: Code[10]; InterbankClearingCodeOption: Option): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);

        BankAccount.Validate("Country/Region Code", CountryCode);
        BankAccount.Validate("Currency Code", Currency);
        BankAccount.Validate("Bank Branch No.", '974');
        BankAccount.Validate("Bank Account No.", '974-1907060-53');
        // Test Bank Account on ISABEL-Beta server
        BankAccount.Validate(IBAN, BankIban);
        BankAccount.Validate("SWIFT Code", Swift);
        BankAccount.Validate("Interbank Clearing Code", InterbankClearingCodeOption);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure ExportSuggestedPayment(var FileName: Text; CountryCode: Code[10]; VendorNoFilter: Text; ExportProtocol: Code[20]; Swift: Code[20]; Iban: Code[50]; BankCurrency: Code[10]; PaymentMsg: Boolean; SeparateLine: Boolean; InterbankClearingCodeOption: Option DimensionValue)
    begin
        LastBankAccount := CreateBankAccount(CountryCode, Swift, Iban, BankCurrency, InterbankClearingCodeOption);
        SuggestAndExportPayments(VendorNoFilter, LastBankAccount, ExportProtocol, FileName, PaymentMsg, SeparateLine, '');
    end;

    local procedure ExportSuggestedPaymentWithGlobalDim1ValueCode(var FileName: Text; CountryCode: Code[10]; VendorNoFilter: Text; ExportProtocol: Code[20]; Swift: Code[20]; Iban: Code[50]; BankCurrency: Code[10]; PaymentMsg: Boolean; SeparateLine: Boolean; InterbankClearingCodeOption: Option DimensionValue; GlobalDim1ValueCode: Code[20])
    begin
        LastBankAccount := CreateBankAccount(CountryCode, Swift, Iban, BankCurrency, InterbankClearingCodeOption);
        SuggestAndExportPayments(VendorNoFilter, LastBankAccount, ExportProtocol, FileName, PaymentMsg, SeparateLine, GlobalDim1ValueCode);
    end;

    local procedure FindCountryRegion(): Code[10]
    var
        ISOCountryCode: Code[2];
    begin
        exit(FindCountryRegionISO(ISOCountryCode));
    end;

    local procedure FindCountryRegionISO(var ISOCountryCode: Code[2]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.FindCountryRegion(CountryRegion);
        CountryRegion."SEPA Allowed" := true;
        ISOCountryCode := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(2, 0), 1, 2);
        CountryRegion.Validate("ISO Code", ISOCountryCode);
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure CreateVendor(CountryCode: Code[10]; ExportProtocolCode: Code[20]; VendorSwift: Code[20]; VendorIban: Code[50]): Code[20]
    var
        Vendor: Record Vendor;
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Vendor, Vendor."No.",
          Dimension.Code, DimensionValue.Code);
        Clear(DimensionCode);
        DimensionCode := Dimension.Code;
        Vendor.Validate("Country/Region Code", CountryCode);
        Vendor.Validate("Preferred Bank Account Code",
          CreateVendorBankAccount(Vendor."No.", CountryCode, ExportProtocolCode, VendorSwift, VendorIban, ''));

        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerWithNoAndCountry(var Customer: Record Customer; CustomerNo: Code[20]; CountryCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Rename(CustomerNo);
        Customer.Validate("Country/Region Code", CountryCode);
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithCurrency(CountryCode: Code[10]; ExportProtocolCode: Code[20]; VendorSwift: Code[20]; VendorIban: Code[50]; VendorCurrency: Code[10]; BankAccountCurrency: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);

        Vendor.Validate("Country/Region Code", CountryCode);
        Vendor.Validate("Preferred Bank Account Code",
          CreateVendorBankAccount(Vendor."No.", CountryCode, ExportProtocolCode, VendorSwift, VendorIban, BankAccountCurrency));
        Vendor.Validate("Currency Code", VendorCurrency);
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorForExportSuggestedPayment(var CountryCode: Code[10]; var ExportProtocol: Code[20]) VendorNo: Code[20]
    var
        VendorSwift: Code[20];
    begin
        CountryCode := FindCountryRegion();
        ExportProtocol := CreateSEPAExportProtocol(true);
        VendorSwift := GenerateBankAccSwiftCode();
        VendorNo := CreateAndUpdateVendor(CountryCode, ExportProtocol, VendorSwift, VendorIbanTxt);
        exit(VendorNo);
    end;

    local procedure CreateAndUpdateVendor(CountryCode: Code[10]; ExportProtocolCode: Code[20]; VendorSwift: Code[20]; VendorIban: Code[50]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor(CountryCode, ExportProtocolCode, VendorSwift, VendorIban));
        Vendor.Validate("Country/Region Code", '');
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]; CountryCode: Code[10]; ExportProtocolCode: Code[20]; VendorSwift: Code[20]; VendorIban: Code[50]; CurrencyCode: Code[10]): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate("Country/Region Code", CountryCode);
        VendorBankAccount.Validate("Bank Account No.", LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Bank Account No."), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("Bank Branch No.", CopyStr(VendorBankAccount."Bank Account No.", 1, LibraryRandom.RandIntInRange(3, 5)));
        VendorBankAccount."Export Protocol Code" := ExportProtocolCode;
        VendorBankAccount.Validate(IBAN, VendorIban);
        VendorBankAccount.Validate("SWIFT Code", VendorSwift);
        VendorBankAccount.Validate("Currency Code", CurrencyCode);
        VendorBankAccount.Modify(true);
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateCustomerBankAccountWithCodeAndBankAccNo(CustomerNo: Code[20]; CountryCode: Code[10]; ExportProtocolCode: Code[20]): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.SetRange("Vendor No.", CustomerNo);
        VendorBankAccount.FindFirst();
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.Rename(CustomerNo, VendorBankAccount.Code);
        CustomerBankAccount.Validate("Country/Region Code", CountryCode);
        CustomerBankAccount.Validate("Bank Account No.", VendorBankAccount."Bank Account No.");
        CustomerBankAccount.Validate(
          "Bank Branch No.", CopyStr(CustomerBankAccount."Bank Account No.", 1, LibraryRandom.RandIntInRange(3, 5)));
        CustomerBankAccount."Export Protocol Code" := ExportProtocolCode;
        CustomerBankAccount.Validate(IBAN, VendorBankAccount.IBAN);
        CustomerBankAccount.Validate("SWIFT Code", VendorBankAccount."SWIFT Code");
        CustomerBankAccount.Modify(true);
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateAndPostPurchInv(VendorNo: Code[20]; UseEuro: Boolean): Decimal
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, VendorNo, UseEuro);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        PurchInvHeader.CalcFields("Amount Including VAT");
        exit(PurchInvHeader."Amount Including VAT");
    end;

    local procedure CreateAndPostPurchCreditMemo(VendorNo: Code[20]; UseEuro: Boolean; LineAmount: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, UseEuro);
        PurchaseLine.Validate("Line Amount", LineAmount);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; UseEuro: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        if not UseEuro then begin
            PurchaseHeader.Validate("Currency Code", ForeignCurrencyCode);
            PurchaseHeader.Modify();
        end;
        LibraryERM.FindGLAccount(GLAccount);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(5, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePmtJournalLine(var PaymJournalBatch: Record "Paym. Journal Batch"; CustomerNo: Code[20]; DocNo: Code[20])
    var
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        PaymentJournalLine.SetRange("Journal Batch Name", PaymJournalBatch.Name);
        PaymentJournalLine.SetRange("Journal Template Name", PaymJournalBatch."Journal Template Name");
        PaymentJournalLine.FindFirst();
        PaymentJournalLine.Validate("Line No.", PaymentJournalLine."Line No." + 1);
        PaymentJournalLine.Validate("Account Type", PaymentJournalLine."Account Type"::Customer);
        PaymentJournalLine.Validate("Account No.", CustomerNo);
        PaymentJournalLine.Validate("Applies-to Doc. Type", PaymentJournalLine."Applies-to Doc. Type"::"Credit Memo");
        PaymentJournalLine.Validate("Applies-to Doc. No.", DocNo);
        PaymentJournalLine.Insert(true);
    end;

    local procedure CreatePostSalesCrMemo(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure SuggestAndExportPayments(VendorNo: Text; BankAccountCode: Code[20]; ExportProtocol: Code[20]; var FileName: Text; PaymentMsg: Boolean; SeparateLine: Boolean; GlobalDim1ValueCode: Code[20])
    var
        PaymJnlBatch: Record "Paym. Journal Batch";
    begin
        CreatePaymentJnlBatch(PaymJnlBatch);
        SuggestPayments(PaymJnlBatch, VendorNo);
        ExportPayments(
            FileName, PaymJnlBatch, BankAccountCode, ExportProtocol, PaymentMsg, SeparateLine, false, GlobalDim1ValueCode);
    end;

    local procedure SuggestPayments(PaymJnlBatch: Record "Paym. Journal Batch"; VendorNo: Text)
    var
        EBPaymentJournalPage: TestPage "EB Payment Journal";
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        EBPaymentJournalPage.OpenEdit();
        Commit();
        EBPaymentJournalPage.CurrentJnlBatchName.Value(PaymJnlBatch.Name);
        EBPaymentJournalPage.SuggestVendorPayments.Invoke();
    end;

    local procedure ExportPayments(var FileName: Text; PaymJournalBatch: Record "Paym. Journal Batch"; BankAccountCode: Code[20]; ExportProtocol: Code[20]; PaymentMsg: Boolean; SeparateLine: Boolean; AutomaticPosting: Boolean; GlobalDim1ValueCode: Code[20])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        EBPaymentJournalPage: TestPage "EB Payment Journal";
    begin
        UpdatePaymenJnlLines(
            PaymJournalBatch."Journal Template Name", PaymJournalBatch.Name, BankAccountCode, PaymentMsg, SeparateLine, GlobalDim1ValueCode);

        CreateGenJnlBatch(GenJnlBatch);
        LibraryVariableStorage.Enqueue(GenJnlBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJnlBatch.Name);
        FileName := GenerateFileName();
        LibraryVariableStorage.Enqueue(FileName);
        LibraryVariableStorage.Enqueue(AutomaticPosting);

        Commit();
        EBPaymentJournalPage.OpenEdit();
        EBPaymentJournalPage.CurrentJnlBatchName.Value(PaymJournalBatch.Name);
        EBPaymentJournalPage.ExportProtocolCode.Value(ExportProtocol);
        if UseCheckPaymentLine then
            EBPaymentJournalPage.CheckPaymentLines.Invoke();
        EBPaymentJournalPage.ExportPaymentLines.Invoke();
        EBPaymentJournalPage.Close();
    end;

    local procedure ExportPaymentLines(var FileName: Text; PaymJournalBatch: Record "Paym. Journal Batch"; CountryCode: Code[10]; ExportProtocol: Code[20]; AutomaticPosting: Boolean; InterbankClearingCodeOption: Option)
    begin
        ExportPayments(
          FileName, PaymJournalBatch,
          CreateBankAccount(CountryCode, GenerateBankAccSwiftCode(), BankIbanTxt, '', InterbankClearingCodeOption),
          ExportProtocol, false, false, AutomaticPosting, '');
    end;

    local procedure CheckPaymentLines(VendorNo: Text; ExportProtocol: Code[20])
    var
        PaymJournalBatch: Record "Paym. Journal Batch";
        PaymentJournalLine: Record "Payment Journal Line";
        EBPaymentJournalPage: TestPage "EB Payment Journal";
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        EBPaymentJournalPage.OpenEdit();
        CreatePaymentJnlBatch(PaymJournalBatch);
        Commit();
        EBPaymentJournalPage.ExportProtocolCode.Value(ExportProtocol);
        EBPaymentJournalPage.CurrentJnlBatchName.Value(PaymJournalBatch.Name);
        EBPaymentJournalPage.SuggestVendorPayments.Invoke();

        if BlankPaymentJournalBankAccount then begin
            PaymentJournalLine.SetRange("Journal Template Name", PaymJournalBatch."Journal Template Name");
            PaymentJournalLine.SetRange("Journal Batch Name", PaymJournalBatch.Name);
            PaymentJournalLine.FindSet();
            repeat
                PaymentJournalLine.Validate("Bank Account", '');
                PaymentJournalLine.Modify(true);
            until PaymentJournalLine.Next() = 0;
        end;
        Commit();
        EBPaymentJournalPage.CheckPaymentLines.Invoke();
    end;

    local procedure CreatePaymentJnlBatch(var PaymJournalBatch: Record "Paym. Journal Batch")
    var
        PaymentJournalTemplate: Record "Payment Journal Template";
    begin
        if not PaymentJournalTemplate.FindLast() then
            LibraryBEHelper.CreatePaymentJournalTemplate(PaymentJournalTemplate);
        LibraryBEHelper.CreatePaymentJournalBatch(PaymJournalBatch, PaymentJournalTemplate.Name);
    end;

    local procedure UpdatePaymenJnlLines(PaymJnlTemplateName: Code[10]; PaymJnlBatchName: Code[10]; BankAccountNo: Code[20]; PaymentMsg: Boolean; SeparateLine: Boolean; GlobalDim1Code: Code[20])
    var
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        PaymentJournalLine.SetRange("Journal Template Name", PaymJnlTemplateName);
        PaymentJournalLine.SetRange("Journal Batch Name", PaymJnlBatchName);
        PaymentJournalLine.FindSet();
        repeat
            PaymentJournalLine.Validate("Bank Account", BankAccountNo);
            if PaymentMsg then
                PaymentJournalLine.Validate("Payment Message", PaymentMessageTxt);
            if SeparateLine then
                PaymentJournalLine.Validate("Separate Line", true);
            if BlankPaymentJournalBankAccount then
                PaymentJournalLine.Validate("Bank Account", '');
            if GlobalDim1Code <> '' then
                PaymentJournalLine.Validate("Shortcut Dimension 1 Code", GlobalDim1Code);
            PaymentJournalLine.Modify(true);
        until PaymentJournalLine.Next() = 0;

        CODEUNIT.Run(CODEUNIT::"Check International Payments", PaymentJournalLine);
    end;

    local procedure PostPaymentLines(VendorNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FilterGenJnlLine(GenJournalLine, VendorNo);
        GenJournalLine.FindFirst();
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.ModifyAll("Posting Date", GenJournalLine."Posting Date");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPurchaseInvoice(var CountryCode: Code[10]; var ExportProtocol: Code[20]; var VendorNo: Code[20]; UseEuro: Boolean)
    begin
        ExportProtocol := CreateSEPAExportProtocol(UseEuro);
        CountryCode := FindCountryRegion();
        VendorNo := CreateVendor(CountryCode, ExportProtocol, GenerateBankAccSwiftCode(), VendorIbanTxt);
        CreateAndPostPurchInv(VendorNo, true);
    end;

    local procedure CreateGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
        GenJnlTemplate.FindFirst();
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.FindGLAccount(GLAccount);
        GenJnlBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJnlBatch.Validate("No. Series", CreateNoSeries());
        GenJnlBatch.Modify();
    end;

    local procedure ModifySecondPaymentJournalLine(PaymJournalBatch: Record "Paym. Journal Batch"): Decimal
    var
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        FilterPmtJnlLine(PaymentJournalLine, PaymJournalBatch, PaymentJournalLine.Status::Created);
        PaymentJournalLine.FindFirst();
        PaymentJournalLine.Next();
        PaymentJournalLine.Validate(Amount, Round(PaymentJournalLine.Amount / 3));
        PaymentJournalLine.Modify(true);
        exit(PaymentJournalLine.Amount);
    end;

    local procedure CreateDimensionValueForGlobalDim1Code(var DimensionValue: Record "Dimension Value")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
    end;

    local procedure FindVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        FilterVendorLedgerEntry(VendorLedgerEntry, VendorNo, DocumentType);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FilterPmtJnlLine(var PaymentJournalLine: Record "Payment Journal Line"; PaymJournalBatch: Record "Paym. Journal Batch"; StatusValue: Option)
    begin
        PaymentJournalLine.SetRange("Journal Template Name", PaymJournalBatch."Journal Template Name");
        PaymentJournalLine.SetRange("Journal Batch Name", PaymJournalBatch.Name);
        PaymentJournalLine.SetRange(Status, StatusValue);
    end;

    local procedure FilterGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    begin
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Vendor);
        GenJournalLine.SetRange("Account No.", VendorNo);
    end;

    local procedure FilterVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
    end;

    local procedure GetProtocolLastNoUsed(ExportProtocolCode: Code[20]): Code[20]
    var
        ExportProtocol: Record "Export Protocol";
        NoSeriesLine: Record "No. Series Line";
    begin
        ExportProtocol.Get(ExportProtocolCode);
        NoSeriesLine.SetRange("Series Code", ExportProtocol."Export No. Series");
        NoSeriesLine.FindFirst();
        exit(NoSeriesLine."Last No. Used");
    end;

    local procedure CreatePaymentJournalLine(var PaymentJournalLine: Record "Payment Journal Line"; PaymJournalBatch: Record "Paym. Journal Batch"; VendorNo: Code[20]; BankAccountNo: Code[20]; PaymAmount: Decimal; SeparateLine: Boolean)
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        Vendor.Get(VendorNo);
        VendorBankAccount.Get(VendorNo, Vendor."Preferred Bank Account Code");
        PaymentJournalLine.Init();
        PaymentJournalLine.Validate("Journal Template Name", PaymJournalBatch."Journal Template Name");
        PaymentJournalLine.Validate("Journal Batch Name", PaymJournalBatch.Name);
        PaymentJournalLine.Validate("Line No.", LibraryUtility.GetNewRecNo(PaymentJournalLine, PaymentJournalLine.FieldNo("Line No.")));
        PaymentJournalLine.Validate("Account Type", PaymentJournalLine."Account Type"::Vendor);
        PaymentJournalLine.Validate("Account No.", VendorNo);
        PaymentJournalLine.Validate(Amount, PaymAmount);
        PaymentJournalLine.Validate("Separate Line", SeparateLine);
        PaymentJournalLine.Validate("Bank Country/Region Code", Vendor."Country/Region Code");
        PaymentJournalLine.Validate("SWIFT Code", VendorBankAccount."SWIFT Code");
        PaymentJournalLine.Validate("Beneficiary IBAN", VendorIbanTxt);
        PaymentJournalLine.Validate("Export Protocol Code", VendorBankAccount."Export Protocol Code");
        PaymentJournalLine.Validate("Bank Account", BankAccountNo);
        PaymentJournalLine.Insert(true);
    end;

    local procedure GenerateBankAccSwiftCode(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        exit(LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account"));
    end;

    local procedure GenerateFileName() FileName: Text
    begin
        FileName := TemporaryPath + LibraryUtility.GenerateGUID() + '.xml';
        if FileMgt.ServerFileExists(FileName) then
            FileMgt.DeleteServerFile(FileName);
    end;

    local procedure MockPaymentJnlLine(var PaymentJournalLine: Record "Payment Journal Line"; AccountType: Option; AccountNo: Code[20]; ExportProtocol: Code[20])
    var
        PaymJournalBatch: Record "Paym. Journal Batch";
    begin
        CreatePaymentJnlBatch(PaymJournalBatch);
        PaymentJournalLine.Init();
        PaymentJournalLine."Journal Template Name" := PaymJournalBatch."Journal Template Name";
        PaymentJournalLine."Journal Batch Name" := PaymJournalBatch.Name;
        PaymentJournalLine."Account Type" := AccountType;
        PaymentJournalLine."Account No." := AccountNo;
        PaymentJournalLine."Export Protocol Code" := ExportProtocol;
        PaymentJournalLine."Payment Message" := LibraryUtility.GenerateGUID();
        PaymentJournalLine.Amount := LibraryRandom.RandDec(10, 2);
        PaymentJournalLine."Beneficiary Bank Account No." := LibraryUtility.GenerateGUID();
        PaymentJournalLine."Beneficiary IBAN" := LibraryUtility.GenerateGUID();
        PaymentJournalLine."SWIFT Code" := LibraryUtility.GenerateGUID();
        PaymentJournalLine."Bank Country/Region Code" := PaymentJournalLine."Journal Batch Name";
        PaymentJournalLine."Bank Account" := LibraryUtility.GenerateGUID();
        PaymentJournalLine.Insert();
        PaymentJournalLine.SetFilter("Export Protocol Code", ExportProtocol);
    end;

    local procedure MockSelectedDimensionFileSEPAPaymentsReport()
    var
        GLSetup: Record "General Ledger Setup";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
        TempDimensionSelectionBuffer: Record "Dimension Selection Buffer" temporary;
        IncludeDimText: Text[250];
    begin
        GLSetup.Get();
        IncludeDimText := GLSetup."Global Dimension 1 Code";

        TempDimensionSelectionBuffer.Init();
        TempDimensionSelectionBuffer.Code := GLSetup."Global Dimension 1 Code";
        TempDimensionSelectionBuffer.Selected := true;
        TempDimensionSelectionBuffer.Insert();

        DimensionSelectionBuffer.SetDimSelection(3, REPORT::"File SEPA Payments", '', IncludeDimText, TempDimensionSelectionBuffer);
    end;


    local procedure RunFileSEPAPaymentReport(var PaymentJournalLine: Record "Payment Journal Line"; FileName: Text)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatch(GenJournalBatch);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(FileName);
        LibraryVariableStorage.Enqueue(false);
        Commit();

        REPORT.Run(REPORT::"File SEPA Payments", true, false, PaymentJournalLine);
    end;

    local procedure VerifyXMLBicNodes(FileName: Text; Swift: Code[20]; VendorSwift: Code[20])
    var
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
        [RunOnClient]
        XmlNode: DotNet XmlNode;
    begin
        LibraryXMLRead.Initialize(FileName);

        LibraryXMLRead.GetNodeListByElementName('FinInstnId', XmlNodeList);

        Assert.AreEqual(8, XmlNodeList.Count, NodeQuantityDoesNotMatchErr);

        XmlNode := XmlNodeList.Item(0).FirstChild;
        Assert.AreEqual('BIC', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(Swift, XmlNode.InnerText, IncorrectNodeNameErr);

        XmlNode := XmlNodeList.Item(1).FirstChild;
        Assert.AreEqual('BIC', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(VendorSwift, XmlNode.InnerText, IncorrectNodeNameErr);
    end;

    local procedure VerifyXMLIbanNodes(FileName: Text; Iban: Code[20]; VendorIban: Code[20])
    var
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
        [RunOnClient]
        XmlNode: DotNet XmlNode;
    begin
        LibraryXMLRead.Initialize(FileName);

        LibraryXMLRead.GetNodeListByElementName('IBAN', XmlNodeList);

        Assert.AreEqual(8, XmlNodeList.Count, NodeQuantityDoesNotMatchErr);

        XmlNode := XmlNodeList.Item(0);
        Assert.AreEqual('IBAN', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(DelChr(Iban, '='), XmlNode.InnerText, IncorrectNodeNameErr);

        XmlNode := XmlNodeList.Item(1);
        Assert.AreEqual('IBAN', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(DelChr(VendorIban, '='), XmlNode.InnerText, IncorrectNodeNameErr);
    end;

    local procedure VerifyXMLCountryNodes(FileName: Text)
    var
        CompanyInformation: Record "Company Information";
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
        [RunOnClient]
        XmlNode: DotNet XmlNode;
    begin
        LibraryXMLRead.Initialize(FileName);
        CompanyInformation.Get();
        LibraryXMLRead.GetNodeListByElementName('Ctry', XmlNodeList);

        Assert.AreEqual(12, XmlNodeList.Count, NodeQuantityDoesNotMatchErr);

        XmlNode := XmlNodeList.Item(0);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(CompanyInformation."Country/Region Code", XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(1);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual('DK', XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(2);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual('DK', XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(3);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(CompanyInformation."Country/Region Code", XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(4);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual('DK', XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(5);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual('DK', XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(6);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(CompanyInformation."Country/Region Code", XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(7);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual('DK', XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(8);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual('DK', XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(9);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(CompanyInformation."Country/Region Code", XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(10);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual('DK', XmlNode.InnerText, IncorrectNodeNameErr);
        XmlNode := XmlNodeList.Item(11);
        Assert.AreEqual('Ctry', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual('DK', XmlNode.InnerText, IncorrectNodeNameErr);
    end;

    local procedure VerifyXmlPaymentLinesPosted(VendorNo: Text)
    var
        PaymentJournalLine: Record "Payment Journal Line";
    begin
        PaymentJournalLine.SetFilter("Account No.", VendorNo);
        PaymentJournalLine.FindSet();
        repeat
            Assert.AreEqual(PaymentJournalLine.Status::Posted, PaymentJournalLine.Status, ShouldHaveBeenPostedErr);
        until PaymentJournalLine.Next() = 0;
    end;

    local procedure VerifyXmlSeparateLines(Filename: Text)
    var
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
    begin
        LibraryXMLRead.Initialize(Filename);
        LibraryXMLRead.GetNodeListByElementName('CdtTrfTxInf', XmlNodeList);

        Assert.AreEqual(4, XmlNodeList.Count, NodeQuantityDoesNotMatchErr);
    end;

    local procedure VerifyXMLChrgBrNodes(FileName: Text; value: Code[20])
    var
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
        [RunOnClient]
        XmlNode: DotNet XmlNode;
    begin
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName('ChrgBr', XmlNodeList);

        Assert.AreEqual(1, XmlNodeList.Count, NodeQuantityDoesNotMatchErr);

        XmlNode := XmlNodeList.Item(0);
        Assert.AreEqual('ChrgBr', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(value, XmlNode.InnerText, IncorrectNodeNameErr);
    end;

    local procedure VerifyXMLAmountCurrency(FileName: Text; FirstForeignCurrencyCodeIso: Code[3]; SecondForeignCurrencyCodeIso: Code[3]; ExpectedAmount1: Decimal; ExpectedAmount2: Decimal)
    var
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
        [RunOnClient]
        XmlNode: DotNet XmlNode;
    begin
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName('InstdAmt', XmlNodeList);

        Assert.AreEqual(2, XmlNodeList.Count, NodeQuantityDoesNotMatchErr);
        XmlNode := XmlNodeList.Item(0);
        VerifyXMLAmountCurrencyValues(XmlNode, FirstForeignCurrencyCodeIso, ExpectedAmount1);
        XmlNode := XmlNodeList.Item(1);
        VerifyXMLAmountCurrencyValues(XmlNode, SecondForeignCurrencyCodeIso, ExpectedAmount2);
    end;

    local procedure VerifyXMLAmountCurrencyValues(var XmlNode: DotNet XmlNode; CurrencyCodeIso: Code[3]; ExpectedAmount: Decimal)
    begin
        Assert.AreEqual('InstdAmt', XmlNode.Name, IncorrectNodeNameErr);
        Assert.AreEqual(CurrencyCodeIso, XmlNode.Attributes.ItemOf('Ccy').Value, IncorrectNodeNameErr);
        Assert.AreEqual(Format(ExpectedAmount, 0, '<Precision,2:2><Standard Format,9>'), XmlNode.InnerText, '');
    end;

    local procedure VerifyXMLEndToEndIdNodes(FileName: Text; PaymentCount: Integer)
    var
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
        [RunOnClient]
        XmlNode: DotNet XmlNode;
        i: Integer;
    begin
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName('EndToEndId', XmlNodeList);

        Assert.AreEqual(PaymentCount, XmlNodeList.Count, NodeQuantityDoesNotMatchErr);

        for i := 0 to (PaymentCount - 1) do begin
            XmlNode := XmlNodeList.Item(i);
            Assert.AreEqual('EndToEndId', XmlNode.Name, IncorrectNodeNameErr);
            Assert.AreEqual(PaymentMessageTxt, XmlNode.InnerText, IncorrectNodeNameErr);
        end;
    end;

    local procedure VerifyXMLPaymentNodes(FileName: Text; MessageId: Code[20]; PaymentCount: Integer; TotalAmount: Decimal)
    var
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
        [RunOnClient]
        XmlNode: DotNet XmlNode;
        [RunOnClient]
        XmlNodeListPmtInf: DotNet XmlNodeList;
        [RunOnClient]
        XmlNodePmtInfID: DotNet XmlNode;
        i: Integer;
    begin
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName('CstmrCdtTrfInitn', XmlNodeList);
        XmlNode := XmlNodeList.Item(0);
        XmlNodeList := XmlNode.ChildNodes;

        Assert.AreEqual(PaymentCount + 1, XmlNodeList.Count, NodeQuantityDoesNotMatchErr);

        XmlNode := XmlNodeList.Item(0);
        Assert.AreEqual('GrpHdr', XmlNode.Name, IncorrectNodeNameErr);
        LibraryXMLRead.VerifyNodeValueInSubtree('GrpHdr', 'CtrlSum', Format(TotalAmount, 0, 9));

        for i := 1 to PaymentCount do begin
            XmlNode := XmlNodeList.Item(i);
            Assert.AreEqual('PmtInf', XmlNode.Name, IncorrectNodeNameErr);
            XmlNodeListPmtInf := XmlNode.ChildNodes;
            XmlNodePmtInfID := XmlNodeListPmtInf.Item(0);
            Assert.AreEqual(MessageId + '-' + Format(i), XmlNodePmtInfID.InnerText, IncorrectNodeValueErr);
        end;
    end;

    local procedure VerifyXMLPaymentNodesWithPmtTpInf(FileName: Text; ExpectedValue: Text[10])
    var
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
        [RunOnClient]
        XmlNode: DotNet XmlNode;
    begin
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName('PmtTpInf', XmlNodeList);
        XmlNode := XmlNodeList.Item(0);
        Assert.AreEqual(ExpectedValue, XmlNode.InnerText, IncorrectNodeValueErr);
    end;

    local procedure VerifyVendLedgEntriesClosed(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendLedgEntry(VendorLedgerEntry, VendorNo, DocumentType);
        Assert.IsFalse(VendorLedgerEntry.Open, '');
    end;

    local procedure VerifyGenJnlLine(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; GLAccDeltaLineNo: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Document Type", DocumentType);
        GenJournalLine.SetRange("Account Type", AccountType);
        GenJournalLine.SetRange("Account No.", AccountNo);
        Assert.RecordCount(GenJournalLine, 1);
        GenJournalLine.FindFirst();
        GenJournalLine.Get(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No." + GLAccDeltaLineNo);
        GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.TestField("Document Type", DocumentType);
    end;

    local procedure VerifyGenJnlLinePaymentInfo(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Document Type", DocumentType);
        GenJournalLine.SetRange("Account Type", AccountType);
        GenJournalLine.SetRange("Account No.", AccountNo);
        Assert.RecordCount(GenJournalLine, 1);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Message to Recipient", PaymentMessageTxt);
        GenJournalLine.TestField("Exported to Payment File", true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsReportHandler(var SuggestVendorPaymentsEB: TestRequestPage "Suggest Vendor Payments EB")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        SuggestVendorPaymentsEB.Vend.SetFilter("No.", VendorNo);
        SuggestVendorPaymentsEB.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FileSEPAPaymentsReportHandler(var FileSEPAPayments: TestRequestPage "File SEPA Payments")
    begin
        FileSEPAPayments.JournalTemplateName.SetValue(LibraryVariableStorage.DequeueText());
        FileSEPAPayments.JournalBatch.SetValue(LibraryVariableStorage.DequeueText());
        FileSEPAPayments.FileName.SetValue(LibraryVariableStorage.DequeueText());
        FileSEPAPayments.AutomaticPosting.SetValue(LibraryVariableStorage.DequeueBoolean());
        FileSEPAPayments.IncludeDimText.SetValue(DimensionCode);
        FileSEPAPayments.ExecutionDate.SetValue(WorkDate());
        FileSEPAPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FileSEPAPaymentsReportHandlerNonEuro(var FileSEPAPayments: TestRequestPage "File Non Euro SEPA Payments")
    begin
        FileSEPAPayments."GenJnlLine.""Journal Template Name""".Value(LibraryVariableStorage.DequeueText());
        FileSEPAPayments."GenJnlLine.""Journal Batch Name""".Value(LibraryVariableStorage.DequeueText());
        FileSEPAPayments.FileName.Value(LibraryVariableStorage.DequeueText());
        FileSEPAPayments.AutomaticPosting.SetValue(LibraryVariableStorage.DequeueBoolean());
        FileSEPAPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FileSEPAPaymentsRequestPageHandlerWithGlobalDim1Code(var FileSEPAPayments: TestRequestPage "File SEPA Payments")
    begin
        FileSEPAPayments.JournalTemplateName.SetValue(LibraryVariableStorage.DequeueText());
        FileSEPAPayments.JournalBatch.SetValue(LibraryVariableStorage.DequeueText());
        FileSEPAPayments.FileName.SetValue(LibraryVariableStorage.DequeueText());
        FileSEPAPayments.AutomaticPosting.SetValue(LibraryVariableStorage.DequeueBoolean());
        FileSEPAPayments.ExecutionDate.SetValue(WorkDate());
        FileSEPAPayments.OK().Invoke();
    end;

    local procedure VerifyXMLCountryCodeNodeValue(FileName: Text; VendorNo: Code[20]; VendorNo2: Code[20]; City: Code[10])
    var
        [RunOnClient]
        XmlNodeList: DotNet XmlNodeList;
    begin
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName('CstmrCdtTrfInitn', XmlNodeList);
        LibraryXMLRead.VerifyNodeValueInSubtree('Cdtr', 'Nm', VendorNo);
        LibraryXMLRead.VerifyNodeValueInSubtree('Cdtr', 'Nm', VendorNo2);
        LibraryXMLRead.VerifyNodeValueInSubtree('Cdtr', 'Ctry', City);
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAgt', 'Ctry', City);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorPageHandler(var ExportCheckErrorLogs: TestPage "Export Check Error Logs")
    begin
        ErrorMessage := ExportCheckErrorLogs."Error Message".Value();
        ExportCheckErrorLogs.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [EventSubscriber(ObjectType::Report, Report::"File SEPA Payments", 'OnBeforeDownloadXmlFile', '', false, false)]
    local procedure OnBeforeDownloadXmlFile(var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    var
        InStream: InStream;
        Content: Text;
    begin
        Assert.IsTrue(TempBlob.HasValue(), 'OnBeforeDownloadXmlFile');
        TempBlob.CreateInStream(InStream);
        InStream.ReadText(Content);
        Assert.ExpectedMessage('<?xml version="1.0" encoding="UTF-8"?>', Content);
        IsHandled := true;
    end;
}

