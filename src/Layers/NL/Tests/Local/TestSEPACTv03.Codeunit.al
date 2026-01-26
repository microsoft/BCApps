codeunit 144101 "Test SEPA CT v03"
{
    //  1. ExportByReport
    //  2. ExportByXMLPort
    //  3. ExportByXMLPortAccountHolder
    //  4. ExportByXMLPortWithError
    //  2. TestSEPAGetEntriesReport
    // 
    // WARNINGS:
    // 1. The test contain XML validation against XSD schema which is currently located in the root folder. In order to enable this
    // codeunit for SNAP execution this dependency must be resolved

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        ProcessProposalLines: Codeunit "Process Proposal Lines";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        XMLReadHelper: Codeunit "NL XML Read Helper";
        IsInitialized: Boolean;
        ExportErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        BlankIBANErr: Label 'Vendor Bank Account %1 must have a value in IBAN.';
        ProposalEntryNotExistErr: Label 'Proposal Entry does not exist.';
        WrongSymbolFoundErr: Label 'Wrong symbol found';
        NoDataExportedMsg: Label 'No BTL91 data has been exported.';
        DataExportedMsg: Label 'BTL91 data has been exported.';
        MustBeEnteredMsg: Label '%1 must be entered in %2.';

    [Test]
    [Scope('OnPrem')]
    procedure GenericSEPAExportProtocolDemodata()
    var
        ExportProtocol: Record "Export Protocol";
    begin
        // [FEATURE] [DEMO]
        // [SCENARIO 294684] There is a "Generic SEPA" Export Protocol in the default Cronus demodata
        ExportProtocol.Get('GENERIC SEPA');
        ExportProtocol.TestField(Description, 'Generic Payment File');
        ExportProtocol.TestField("Check ID", CODEUNIT::"Check BTL91");
        ExportProtocol.TestField("Export Object Type", ExportProtocol."Export Object Type"::Report);
        ExportProtocol.TestField("Export ID", REPORT::"SEPA ISO20022 Pain 01.01.03");
        ExportProtocol.TestField("Docket ID", REPORT::Docket);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure ExportByReport()
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        ExportProtocolCode: Code[20];
        FileName: Text;
        TotalAmount: Decimal;
        NoOfDocuments: Integer;
    begin
        Initialize();

        // setup
        ExportProtocolCode := FindStandardEuroSEPAExportProtocol();
        SetupForExport(BankAccount, VendorBankAccount, ExportProtocolCode, TotalAmount, NoOfDocuments);

        // exercise
        FileName := GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // verify
        VerifySEPACreditTransferFile(FileName, TotalAmount, VendorBankAccount, true, NoOfDocuments, LibraryERM.GetLCYCode());
        VerifyStandardEuroSEPAFields('.' + CopyStr(VendorBankAccount."Account Holder Address", 2), FormatIBAN(VendorBankAccount.IBAN));
        VerifyGrouping();
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure ExportByReportForEmployee()
    var
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
        ExportProtocolCode: Code[20];
        FileName: Text;
        EmployeeName: Text;
        i: Integer;
        TotalAmount: Decimal;
        NoOfDocuments: Integer;
    begin
        Initialize();

        // setup
        EmployeeName := LibraryUtility.GenerateRandomAlphabeticText(10, 0);
        ExportProtocolCode := FindStandardEuroSEPAExportProtocol();
        SetUpTransactionModeForEmployee(CreateSEPABankAccount(BankAccount, ''), ExportProtocolCode);
        NoOfDocuments := GenerateNoOfDocuments();
        for i := 1 to NoOfDocuments do begin
            CreateEmployeeWithBankAccount(Employee, BankAccount, EmployeeName);
            TotalAmount += CreateAndPostEmployeeExpense(Employee);
        end;

        // exercise
        FileName := GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // verify
        VerifySEPACreditTransferFileForEmployee(FileName, TotalAmount, Employee, true, NoOfDocuments);
        VerifyStandardEuroSEPAFields('.' + CopyStr(Employee.Address, 2), FormatIBAN(Employee.IBAN));
        VerifyGrouping();
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure ExportByXMLPort()
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        ExportProtocolCode: Code[20];
        FileName: Text;
        TotalAmount: Decimal;
        NoOfDocuments: Integer;
    begin
        // [SCENARIO 269221] Export SEPA CT using xml port
        Initialize();

        // [GIVEN] Export protocol with "SEPA CT pain.001.001.03" xml port
        ExportProtocolCode := FindXMLPortEuroSEPAExportProtocol();

        // [GIVEN] Vendor entry for export
        SetupForExport(BankAccount, VendorBankAccount, ExportProtocolCode, TotalAmount, NoOfDocuments);

        // [WHEN] Run xml export
        GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // [THEN] Xml file is exported with namespace 'xmlns:xsi=http://www.w3.org/2001/XMLSchemainstance'
        FileName := CreateXMLFileFromCreditTransferRegisterExportedFile(BankAccount."No.");
        VerifySEPACreditTransferFile(FileName, TotalAmount, VendorBankAccount, false, NoOfDocuments, LibraryERM.GetLCYCode());
        VerifyGrouping();
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure ExportByXMLPortForEmployee()
    var
        BankAccount: Record "Bank Account";
        Employee: Record Employee;
        ExportProtocolCode: Code[20];
        EmployeeName: Text;
        FileName: Text;
        i: Integer;
        TotalAmount: Decimal;
        NoOfDocuments: Integer;
    begin
        // [SCENARIO] Export SEPA CT using xml port
        Initialize();

        // [GIVEN]
        ExportProtocolCode := FindXMLPortEuroSEPAExportProtocol();
        EmployeeName := LibraryUtility.GenerateRandomAlphabeticText(10, 0);
        SetUpTransactionModeForEmployee(CreateSEPABankAccount(BankAccount, ''), ExportProtocolCode);
        NoOfDocuments := GenerateNoOfDocuments();
        for i := 1 to NoOfDocuments do begin
            CreateEmployeeWithBankAccount(Employee, BankAccount, EmployeeName);
            TotalAmount += CreateAndPostEmployeeExpense(Employee);
        end;

        // [WHEN]
        GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // [THEN]
        FileName := CreateXMLFileFromCreditTransferRegisterExportedFile(BankAccount."No.");
        VerifySEPACreditTransferFileForEmployee(FileName, TotalAmount, Employee, false, NoOfDocuments);
        VerifyGrouping();
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure ExportByXMLPortAccountHolder()
    var
        BankAccount: Record "Bank Account";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentHistory: Record "Payment History";
        TempPaymentExportData: Record "Payment Export Data" temporary;
        Vendor: Record Vendor;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        ExportProtocolCode: Code[20];
        ExpectedAccountHolderName: Text;
    begin
        Initialize();

        // setup
        ExportProtocolCode := FindXMLPortEuroSEPAExportProtocol();
        SetUpTransactionMode(CreateSEPABankAccount(BankAccount, ''), ExportProtocolCode);
        CreateVendorWithBankAccount(Vendor, BankAccount, '');
        CreateAndPostPurchInvoice(Vendor."No.", false);

        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");

        FindPaymentHistoryToExport(PaymentHistory, BankAccount."No.", ExportProtocolCode);
        ExpectedAccountHolderName := LibraryUtility.GenerateGUID();
        SetAccountHolderName(PaymentHistory, ExpectedAccountHolderName);

        // exercise
        GenJnlLine.SetRange("Document No.", PaymentHistory."Run No.");
        GenJnlLine.SetRange("Bal. Account No.", BankAccount."No.");
        SEPACTFillExportBuffer.FillExportBuffer(GenJnlLine, TempPaymentExportData);

        // verify
        TempPaymentExportData.FindFirst();
        Assert.AreEqual(
          ExpectedAccountHolderName, TempPaymentExportData."Recipient Name", TempPaymentExportData.FieldName("Recipient Name"));
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure ExportByXMLPortWithError()
    var
        BankAccount: Record "Bank Account";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentHistory: Record "Payment History";
        Vendor: Record Vendor;
        ExportProtocolCode: Code[20];
    begin
        Initialize();

        // setup
        ExportProtocolCode := FindXMLPortEuroSEPAExportProtocol();
        SetUpTransactionMode(CreateSEPABankAccount(BankAccount, ''), ExportProtocolCode);
        CreateVendorWithBankAccount(Vendor, BankAccount, '');
        CreateAndPostPurchInvoice(Vendor."No.", false);

        GetEntries(BankAccount."No.");
        ProcessProposals(BankAccount."No.");
        BlankIBANOnVendorBankAccount(Vendor."No.");
        FindPaymentHistoryToExport(PaymentHistory, BankAccount."No.", ExportProtocolCode);

        // Must be a rec with same Document No. and Bal. Account No.
        GenJournalBatch.FindFirst();
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal document Type"::" ",
            "Gen. Journal Account Type"::"G/L Account", '', 0);
        GenJnlLine."Bal. Account No." := PaymentHistory."Our Bank";
        GenJnlLine."Document No." := PaymentHistory."Run No.";
        GenJnlLine.Modify();

        // exercise
        asserterror ExportSEPAFile(BankAccount."No.", ExportProtocolCode);

        // verify
        Assert.ExpectedError(ExportErrorsErr);
        PaymentHistory.Find();
        Assert.IsTrue(PaymentHistory.Export, PaymentHistory.FieldName(Export));
        Assert.AreNotEqual('', PaymentHistory."File on Disk", PaymentHistory.FieldName("File on Disk"));
        VerifyPaymentHistoryCardExportErrorFactBox(PaymentHistory);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    [Scope('OnPrem')]
    procedure TestSEPAGetEntriesReport()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        ExportProtocolCode: Code[20];
    begin
        Initialize();

        // Setup
        ExportProtocolCode := FindStandardEuroSEPAExportProtocol();
        CreateSEPABankAccount(BankAccount, '');
        SetUpTransactionMode(BankAccount."No.", ExportProtocolCode);
        CreateVendorWithBankAccount(Vendor, BankAccount, '');

        // Exercise
        CreateAndPostPurchInvoiceWithMaxInvNo(Vendor."No.");
        GetEntries(BankAccount."No.");

        // Verify
        VerifyEntryExist(Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTAccHolderPstlAddr()
    var
        PaymentHistoryLine: Record "Payment History Line";
        AddrLine: array[3] of Text[70];
        AccHoldCountryRegionCode: Code[10];
        AccountHolderAddress: Text[100];
        AccountHolderPostCode: Code[20];
        AccountHolderCity: Text[30];
    begin
        // [FEATURE] [UT][SEPA]
        // [SCENARIO 401029] "Payment History Line".GetAccHolderPostalAddr must return correct values
        PaymentHistoryLine.Init();
        Assert.IsFalse(PaymentHistoryLine.GetAccHolderPostalAddr(AddrLine), '0');

        PaymentHistoryLine.Init();
        AccHoldCountryRegionCode := LibraryUtility.GenerateRandomCode(
            PaymentHistoryLine.FieldNo("Acc. Hold. Country/Region Code"),
            Database::"Payment History Line");
        PaymentHistoryLine."Acc. Hold. Country/Region Code" := AccHoldCountryRegionCode;
        VerifyAccHolderAddr(PaymentHistoryLine, 1, CopyStr(AccHoldCountryRegionCode, 1, 2));

        PaymentHistoryLine.Init();
        AccountHolderAddress := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(
            MaxStrLen(PaymentHistoryLine."Account Holder Address"), 1),
            1, MaxStrLen(PaymentHistoryLine."Account Holder Address"));
        PaymentHistoryLine."Account Holder Address" := AccountHolderAddress;
        VerifyAccHolderAddr(PaymentHistoryLine, 2, CopyStr(AccountHolderAddress, 1, 70));

        PaymentHistoryLine.Init();
        AccountHolderPostCode := LibraryUtility.GenerateRandomCode20(
            PaymentHistoryLine.FieldNo("Account Holder Post Code"),
            Database::"Payment History Line");
        AccountHolderCity := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(
            MaxStrLen(PaymentHistoryLine."Account Holder City"), 1),
            1, MaxStrLen(PaymentHistoryLine."Account Holder City"));
        PaymentHistoryLine."Account Holder Post Code" := AccountHolderPostCode;
        PaymentHistoryLine."Account Holder City" := AccountHolderCity;
        VerifyAccHolderAddr(PaymentHistoryLine, 3,
            CopyStr(StrSubstNo('%1 %2', AccountHolderPostCode, AccountHolderCity), 1, 70));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTUnstructuredRemitInfo()
    var
        DetailLine: Record "Detail Line";
        PaymentHistoryLine: Record "Payment History Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Addition: Text[70];
        ActualInfo: Text[140];
        ExpectedInfo: Text[140];
        FullInfo: Text[250];
        Delimiter: Text[2];
        Done: Boolean;
    begin
        DetailLine.SetRange("Our Bank", '');
        DetailLine.DeleteAll();
        DetailLine.Reset();
        DetailLine.FindLast();

        VendLedgEntry.SetFilter("External Document No.", '<>%1', '');
        VendLedgEntry.FindSet();
        while not Done do begin
            Addition := Delimiter + VendLedgEntry."External Document No.";
            if StrLen(Addition) + StrLen(ExpectedInfo) < MaxStrLen(ExpectedInfo) then
                ExpectedInfo := ExpectedInfo + Addition
            else begin
                Done := true;
                FullInfo := ExpectedInfo + Addition; // would exceed max length of Ustrd value
            end;
            Delimiter := ', ';

            DetailLine.Init();
            DetailLine."Transaction No." += 1;
            DetailLine."Account Type" := DetailLine."Account Type"::Vendor;
            DetailLine.Status := DetailLine.Status::"In process";
            DetailLine."Serial No. (Entry)" := VendLedgEntry."Entry No.";
            DetailLine.Insert();

            VendLedgEntry.Next();
        end;
        ActualInfo := PaymentHistoryLine.GetUnstrRemitInfo();
        DetailLine.SetRange("Our Bank", '');
        DetailLine.DeleteAll();

        Assert.AreNotEqual(FullInfo, ExpectedInfo, '');
        Assert.AreEqual(ExpectedInfo, ActualInfo, VendLedgEntry.FieldName("External Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTUnstructuredRemitInfoNoDtls()
    var
        DetailLine: Record "Detail Line";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        DetailLine.SetRange("Our Bank", '');
        DetailLine.DeleteAll();

        PaymentHistoryLine."Description 1" := LibraryUtility.GenerateGUID();
        Assert.AreEqual(
          PaymentHistoryLine."Description 1",
          PaymentHistoryLine.GetUnstrRemitInfo(),
          PaymentHistoryLine.FieldName("Description 1"));
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure SepaCreditTransferCtrlSumDecimalFormat()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        ExportProtocolCode: Code[20];
        FileName: Text;
        TotalAmount: Decimal;
    begin
        // Check that Integer value is always exported to CtrlSum and InstdAmt with 2 decimal symbols
        Initialize();

        // setup
        ExportProtocolCode := FindStandardEuroSEPAExportProtocol();
        SetUpTransactionMode(CreateSEPABankAccount(BankAccount, ''), ExportProtocolCode);
        CreateVendorWithBankAccount(Vendor, BankAccount, '');
        TotalAmount := CreateAndPostPurchInvoice(Vendor."No.", true);
        FileName := GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // verify
        VerifySEPACreditTransferFileCtrlSumInstdAmtRound(FileName, TotalAmount, GetEuroCurrencyCode());
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure SepaCreditTransferDoesNotContainBOMSymbol()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        ExportProtocolCode: Code[20];
        FileName: Text;
    begin
        // [SCENARIO 363157]  Report 11000012 SEPA ISO20022 Pain 01.01.03 does not contain BOM symbol in the beginning of file
        Initialize();

        // [GIVEN] Posted Purchase Invoice for Vendor with Vendor Bank Account
        ExportProtocolCode := FindStandardEuroSEPAExportProtocol();
        SetUpTransactionMode(CreateSEPABankAccount(BankAccount, ''), ExportProtocolCode);
        CreateVendorWithBankAccount(Vendor, BankAccount, '');
        CreateAndPostPurchInvoice(Vendor."No.", true);

        // [WHEN] Report 11000012 SEPA ISO20022 Pain 01.01.03 is exported to file
        FileName := GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // [THEN] Exported file starts with '<?xml' not with BOM symbols
        VerifyBeginningOfXMLFile(FileName, '<?xml');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalFunctionalityMgt_GetPmtHistLineCountAndAmt_Zero()
    var
        PaymentHistory: Record "Payment History";
        DummyPaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        TotalAmount: Text[50];
        LineCount: Text[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 210410] COD 11400 "Local Functionality Mgt.".GetPmtHistLineCountAndAmtForSEPAISO20022Pain() in case of zero amount
        MockPaymentHistory(PaymentHistory);

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, DummyPaymentHistoryLine, TotalAmount, LineCount);

        Assert.AreEqual('0.00', TotalAmount, '');
        Assert.AreEqual('0', LineCount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalFunctionalityMgt_GetPmtHistLineCountAndAmt_Integer()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        TotalAmount: Text[50];
        LineCount: Text[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 210410] COD 11400 "Local Functionality Mgt.".GetPmtHistLineCountAndAmtForSEPAISO20022Pain() in case of integer amount
        MockPaymentHistory(PaymentHistory);
        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory, PaymentHistoryLine.Status::New, -1000);

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);

        Assert.AreEqual('1000.00', TotalAmount, '');
        Assert.AreEqual('1', LineCount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalFunctionalityMgt_GetPmtHistLineCountAndAmt_Decimal()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        TotalAmount: Text[50];
        LineCount: Text[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 210410] COD 11400 "Local Functionality Mgt.".GetPmtHistLineCountAndAmtForSEPAISO20022Pain() in case of decimal amount
        MockPaymentHistory(PaymentHistory);
        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory, PaymentHistoryLine.Status::New, 1000.1);

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);

        Assert.AreEqual('1000.10', TotalAmount, '');
        Assert.AreEqual('1', LineCount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalFunctionalityMgt_GetPmtHistLineCountAndAmt_Decimal_RoundingDown()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        TotalAmount: Text[50];
        LineCount: Text[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 210410] COD 11400 "Local Functionality Mgt.".GetPmtHistLineCountAndAmtForSEPAISO20022Pain() in case of decimal with rounded down amount
        MockPaymentHistory(PaymentHistory);
        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory, PaymentHistoryLine.Status::New, 1000.123);

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);

        Assert.AreEqual('1000.12', TotalAmount, '');
        Assert.AreEqual('1', LineCount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalFunctionalityMgt_GetPmtHistLineCountAndAmt_Decimal_RoundingUp()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        TotalAmount: Text[50];
        LineCount: Text[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 210410] COD 11400 "Local Functionality Mgt.".GetPmtHistLineCountAndAmtForSEPAISO20022Pain() in case of decimal with rounded up amount
        MockPaymentHistory(PaymentHistory);
        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory, PaymentHistoryLine.Status::New, 1000.125);

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);

        Assert.AreEqual('1000.13', TotalAmount, '');
        Assert.AreEqual('1', LineCount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalFunctionalityMgt_GetPmtHistLineCountAndAmt_StatusFilter()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        TotalAmount: Text[50];
        LineCount: Text[20];
        Status: Integer;
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 210410] COD 11400 "Local Functionality Mgt.".GetPmtHistLineCountAndAmtForSEPAISO20022Pain() in case of several lines with different Status field value
        MockPaymentHistory(PaymentHistory);
        for Status := PaymentHistoryLine.Status::New to PaymentHistoryLine.Status::Posted do begin
            MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory, Status, LibraryRandom.RandDecInDecimalRange(1000, 2000, 2));
            if Status in [PaymentHistoryLine.Status::New,
                          PaymentHistoryLine.Status::Transmitted,
                          PaymentHistoryLine.Status::"Request for Cancellation"]
            then
                ExpectedAmount += PaymentHistoryLine.Amount;
        end;

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);

        Assert.AreEqual(Format(ExpectedAmount, 0, '<Precision,2:2><Standard Format,9>'), TotalAmount, '');
        Assert.AreEqual('3', LineCount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalFunctionalityMgt_GetPmtHistLineCountAndAmt_LineCount()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        TotalAmount: Text[50];
        LineCount: Text[20];
        i: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 210410] COD 11400 "Local Functionality Mgt.".GetPmtHistLineCountAndAmtForSEPAISO20022Pain() in case of several lines
        MockPaymentHistory(PaymentHistory);
        for i := 1 to LibraryRandom.RandIntInRange(10, 20) do
            MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory, PaymentHistoryLine.Status::New, 1);

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);

        Assert.AreEqual(Format(i), LineCount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalFunctionalityMgt_GetPmtHistLineCountAndAmt_OnlyForeignAmounts()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        TotalAmount: Text[50];
        LineCount: Text[20];
        ForeignCount: Integer;
        Amount: Decimal;
        TotalForeign: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363009] COD 11400 "Local Functionality Mgt.".GetPmtHistLineCountAndAmtForSEPAISO20022Pain() in case of several lines
        // [SCENARIO 363009] with only foreign amounts
        MockPaymentHistory(PaymentHistory);

        for ForeignCount := 1 to LibraryRandom.RandIntInRange(10, 20) do begin
            Amount := LibraryRandom.RandDec(1000, 2);
            TotalForeign += Amount;
            MockPaymentHistoryLineWithAmounts(PaymentHistoryLine, PaymentHistory, LibraryRandom.RandDec(1000, 2), Amount);
        end;

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);

        Assert.AreEqual(Format(ForeignCount), LineCount, '');
        Assert.AreEqual(Format(TotalForeign, 0, '<Precision,2:2><Standard Format,9>'), TotalAmount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalFunctionalityMgt_GetPmtHistLineCountAndAmt_ForeignAndLocalAmounts()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        TotalAmount: Text[50];
        LineCount: Text[20];
        LocalCount: Integer;
        ForeignCount: Integer;
        Amount: Decimal;
        TotalLocal: Decimal;
        TotalForeign: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363009] COD 11400 "Local Functionality Mgt.".GetPmtHistLineCountAndAmtForSEPAISO20022Pain() in case of several lines
        // [SCENARIO 363009] with local and foreign amounts
        MockPaymentHistory(PaymentHistory);

        for LocalCount := 1 to LibraryRandom.RandIntInRange(10, 20) do begin
            Amount := LibraryRandom.RandDec(1000, 2);
            TotalLocal += Amount;
            MockPaymentHistoryLineWithAmounts(PaymentHistoryLine, PaymentHistory, Amount, 0);
        end;

        for ForeignCount := 1 to LibraryRandom.RandIntInRange(10, 20) do begin
            Amount := LibraryRandom.RandDec(1000, 2);
            TotalForeign += Amount;
            MockPaymentHistoryLineWithAmounts(PaymentHistoryLine, PaymentHistory, LibraryRandom.RandDec(1000, 2), Amount);
        end;

        LocalFunctionalityMgt.GetPmtHistLineCountAndAmtForSEPAISO20022Pain(PaymentHistory, PaymentHistoryLine, TotalAmount, LineCount);

        Assert.AreEqual(Format(LocalCount + ForeignCount), LineCount, '');
        Assert.AreEqual(Format(TotalLocal + TotalForeign, 0, '<Precision,2:2><Standard Format,9>'), TotalAmount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SEPA_ISO20022_Pain010103_DecimalAmountFormat()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        // [SCENARIO 210410] REP 11000012 "SEPA ISO20022 Pain 01.01.03" exports decimals with two fraction digits
        Initialize();

        // [GIVEN] Payment History Line with Amount = 1000.1
        CreatePaymentHistory(PaymentHistory, REPORT::"SEPA ISO20022 Pain 01.01.03");
        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory, PaymentHistoryLine.Status::New, 1000.1);

        // [WHEN] Export "SEPA ISO20022 Pain 01.01.03"
        PaymentHistory.SetRecFilter();
        REPORT.RunModal(REPORT::"SEPA ISO20022 Pain 01.01.03", false, false, PaymentHistory);

        // [THEN] Exported XML contains "CtrlSum" = "1000.10"
        PaymentHistory.Find();
        XMLReadHelper.Initialize(PaymentHistory."File on Disk", GetSEPACTNameSpace());
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:GrpHdr/ns:CtrlSum', '1000.10');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SEPA_ISO20022_Pain00800102_DecimalAmountFormat()
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
    begin
        // [SCENARIO 210410] REP 11000013 "SEPA ISO20022 Pain 008.001.02" exports decimals with two fraction digits
        Initialize();

        // [GIVEN] Payment History Line with Amount = 1000.1
        CreatePaymentHistory(PaymentHistory, REPORT::"SEPA ISO20022 Pain 008.001.02");
        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory, PaymentHistoryLine.Status::New, 1000.1);
        PaymentHistoryLine.Validate("Account No.", LibrarySales.CreateCustomerNo());
        PaymentHistoryLine.Validate("Sequence Type", PaymentHistoryLine."Sequence Type"::FNAL);
        PaymentHistoryLine.Modify(true);

        // [WHEN] Export "SEPA ISO20022 Pain 008.001.02"
        PaymentHistory.SetRecFilter();
        REPORT.RunModal(REPORT::"SEPA ISO20022 Pain 008.001.02", false, false, PaymentHistory);

        // [THEN] Exported XML contains "CtrlSum" = "1000.10"
        PaymentHistory.Find();
        XMLReadHelper.Initialize(PaymentHistory."File on Disk", 'urn:iso:std:iso:20022:tech:xsd:pain.008.001.02');
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrDrctDbtInitn/ns:GrpHdr/ns:CtrlSum', '1000.10');
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithEnqueueMessage,BTL91ExportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ModifyRunNoOnRequestPageWhenOtherExportFormat()
    var
        PaymentHistory: Record "Payment History";
        RunNo: Code[20];
        OurBank: Code[20];
    begin
        // [SCENARIO 272451] When Stan exports Payment History with "Export Protocol" = "X" and changes "Run No." = "Y" on request page then export file is not generated
        // [SCENARIO 272451] if Payment History with "Run No." = "Y" has "Export Protocol" <> "X"
        Initialize();

        // [GIVEN] Payment History "H1" with Run No. = 1, Export Protocol = "SEPA"
        MockPaymentHistoryWithLine(PaymentHistory, REPORT::"SEPA ISO20022 Pain 008.001.02");
        RunNo := PaymentHistory."Run No.";
        OurBank := PaymentHistory."Our Bank";

        // [GIVEN] Payment History "H2" with Run No. = 2, Export Protocol = "BTL91" and same Our Bank
        MockPaymentHistoryWithLineAndOurBank(PaymentHistory, OurBank);
        ModifyPaymentHistoryExportProtocol(PaymentHistory, CreateExportProtocolForReport(REPORT::"Export BTL91-ABN AMRO"));

        // [GIVEN] Exported Payment History for "H2"
        LibraryVariableStorage.Enqueue(RunNo);
        Commit();
        PaymentHistory.ExportToPaymentFile();

        // [GIVEN] Stan selected Run No = 1 on report Export BTL91-ABN AMRO request page
        // Selection is done in BTL91ExportRequestPageHandler

        // [WHEN] Stan pushes OK on request page
        // Action is done in BTL91ExportRequestPageHandler

        // [THEN] Message "No BTL91 data has been exported..." appears
        Assert.AreEqual(NoDataExportedMsg, CopyStr(LibraryVariableStorage.DequeueText(), 1, StrLen(NoDataExportedMsg)), '');

        // [THEN] Payment History "H1" has Status = New
        PaymentHistory.Get(OurBank, RunNo);
        PaymentHistory.TestField(Status, PaymentHistory.Status::New);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithEnqueueMessage,BTL91ExportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ModifyRunNoOnRequestPageWhenSameExportFormat()
    var
        PaymentHistory: Record "Payment History";
        RunNo: Code[20];
        OurBank: Code[20];
        ExportProtocolCode: Code[20];
    begin
        // [SCENARIO 272451] When Stan exports Payment History with "Export Protocol" = "X" and changes "Run No." = "Y" on request page then export file is generated
        // [SCENARIO 272451] if Payment History with "Run No." = "Y" has "Export Protocol" = "X"
        Initialize();

        // [GIVEN] Payment History "H1" with Run No. = 1, Export Protocol = "BTL91", having line with Customer "A" and Amount = 500
        MockPaymentHistoryWithLine(PaymentHistory, REPORT::"Export BTL91-ABN AMRO");
        RunNo := PaymentHistory."Run No.";
        OurBank := PaymentHistory."Our Bank";
        ExportProtocolCode := PaymentHistory."Export Protocol";

        // [GIVEN] Payment History "H2" with same Our Bank, Run No. = 2, Export Protocol = "BTL91", having line with other Customer
        MockPaymentHistoryWithLineAndOurBank(PaymentHistory, OurBank);
        ModifyPaymentHistoryExportProtocol(PaymentHistory, ExportProtocolCode);

        // [GIVEN] Exported Payment History for "H2"
        LibraryVariableStorage.Enqueue(RunNo);
        Commit();
        PaymentHistory.ExportToPaymentFile();

        // [GIVEN] Stan selected Run No = 1 on report Export BTL91-ABN AMRO request page
        // Selection is done in BTL91ExportRequestPageHandler

        // [WHEN] Stan pushes OK on request page
        // Action is done in BTL91ExportRequestPageHandler

        // [THEN] Message "BTL91 data has been exported..." appears
        Assert.AreEqual(DataExportedMsg, CopyStr(LibraryVariableStorage.DequeueText(), 1, StrLen(DataExportedMsg)), '');

        // [THEN] Payment History "H1" has Status = Transmitted
        PaymentHistory.Get(OurBank, RunNo);
        PaymentHistory.TestField(Status, PaymentHistory.Status::Transmitted);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure SEPA_ISO20022_Pain010103_MultipleLineNodes()
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        ExportProtocolCode: Code[20];
        FileName: Text;
        TotalAmount: Decimal;
        NoOfDocuments: Integer;
    begin
        // [SCENARIO 297104] "SEPA ISO20022 Pain 01.01.03" exports multiple payment lines with NbOfTxs and CtrlSum in each node

        Initialize();

        // [GIVEN] Export protocol for "SEPA ISO20022 Pain 01.01.03"
        ExportProtocolCode := FindStandardEuroSEPAExportProtocol();

        // [GIVEN] Payment Line "A" with "Transaction Date" = 01.01 and Amount = 100
        // [GIVEN] Payment Line "B" with "Transaction Date" = 01.01 and Amount = 200
        // [GIVEN] Payment Line "C" with "Transaction Date" = 01.02 and Amount = 500
        SetupForExport(BankAccount, VendorBankAccount, ExportProtocolCode, TotalAmount, NoOfDocuments);

        // [WHEN] Export generated payments with "SEPA ISO20022 Pain 01.01.03"
        FileName := GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // [THEN] Multiple XML nodes generated according to "Posting Date"
        // [THEN] //ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf[1] has information about invoices "A" and "B". NbOfTxs is 2, CtrlSum is 300
        // [THEN] //ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf[2] has information about invoice "C". NbOfTxs is 1, CtrlSum is 500
        VerifyMultiplePaymentHistoryLinesInSEPAFile(FileName, BankAccount."No.", ExportProtocolCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupEUR_BankDefault_InvDefault()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Euro", "Currency Euro" = "",
        // [SCENARIO 294684] "LCY Code" = "EUR", bank currency = "", vendor currrency = ""
        Initialize();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Euro", "Currency Euro" = "", "LCY Code" = "EUR"
        // [GIVEN] Vendor bank account with a default currency code = "", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with a default currency code = "", total amount including vat = 1000
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Euro, '', LibraryUtility.GenerateGUID(), '', '');

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SEPA", ChrgBr = "SLEV", DbtrAcct.Ccy = "EUR", CdtTrfTxInf.Amt.InstdAmt<Ccy = "EUR"> = 1000
        // [THEN] PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine = "X"
        // [THEN] Vendor Bank Account's IBAN is exported into CdtrAcct/Id/IBAN (TFS 311461)
        VerifyStandardEuroXML(VendorBankAccount, FileName, TotalAmount, LibraryERM.GetLCYCode());
        // [THEN] Payment History Line has blank Currency Code (TFS 309218)
        VerifyPmtHistoryLineCurrencyCode(BankAccountNo, '');
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupEUR_BankDefault_InvDefault_WorldPaymentMode()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        TransactionMode: Record "Transaction Mode";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Euro", "Currency Euro" = "",
        // [SCENARIO 294684] "LCY Code" = "EUR", bank currency = "", vendor currrency = "", "Transaction Mode".WorldPayment = TRUE
        Initialize();

        // [GIVEN] Generic payment SEPA export protocol setup, "Transaction Mode".WorldPayment = TRUE
        // [GIVEN] GLSetup."Local Curency" = "Euro", "Currency Euro" = "", "LCY Code" = "EUR"
        // [GIVEN] Vendor bank account with a default currency code = "", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with a default currency code = "", total amount including vat = 1000
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Euro, '', LibraryUtility.GenerateGUID(), '', '');
        UpdateTransactionMode(TransactionMode."Account Type"::Vendor, BankAccountNo, true);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] Payment is exported in WorldPayment format
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, GetEuroCurrencyCode(), LibraryERM.GetLCYCode());
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupEUR_BankUSD_InvDefault()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Euro", "Currency Euro" = "",
        // [SCENARIO 294684] "LCY Code" = "EUR", bank currency = "USD", vendor currrency = ""
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Euro", "Currency Euro" = "", "LCY Code" = "EUR"
        // [GIVEN] Vendor bank account with currency code = "USD", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with a default currency code = "", total amount including vat = 1000 EUR (2000 USD)
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Euro, '', LibraryUtility.GenerateGUID(), CurrencyCode, '');

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "EUR", CdtTrfTxInf.Amt.InstdAmt<Ccy = "EUR"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        // [THEN] (TFS 363009) Payment is exported in the original document currency and amount 1000 "EUR" (regardless of bank currency)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, GetEuroCurrencyCode(), CurrencyCode);
        // [THEN] Payment History Line has Currency Code = 'USD' (TFS 309218)
        VerifyPmtHistoryLineCurrencyCode(BankAccountNo, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupEUR_BankDefault_InvUSD()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Euro", "Currency Euro" = "",
        // [SCENARIO 294684] "LCY Code" = "EUR", bank currency = "", vendor currrency = "USD"
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Euro", "Currency Euro" = "", "LCY Code" = "EUR"
        // [GIVEN] Vendor bank account with a default currency code = "", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "USD", total amount including vat = 1000 USD (2000 EUR)
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Euro, '', LibraryUtility.GenerateGUID(), '', CurrencyCode);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "EUR", CdtTrfTxInf.Amt.InstdAmt<Ccy = "USD"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        // [THEN] (TFS 363009) Payment is exported in the original document currency and amount 1000 "USD" (regardless of bank currency)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, CurrencyCode, LibraryERM.GetLCYCode());
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupEUR_BankUSD_InvUSD()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Euro", "Currency Euro" = "",
        // [SCENARIO 294684] "LCY Code" = "EUR", bank currency = "USD", vendor currrency = "USD"
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Euro", "Currency Euro" = "", "LCY Code" = "EUR"
        // [GIVEN] Vendor bank account with currency code = "USD", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "USD", total amount including vat = 1000 USD
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Euro, '', LibraryUtility.GenerateGUID(), CurrencyCode, CurrencyCode);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "EUR", CdtTrfTxInf.Amt.InstdAmt<Ccy = "USD"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupEUR_BankUSD_InvGBP()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        CurrencyCode: Code[10];
        InvCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Euro", "Currency Euro" = "",
        // [SCENARIO 294684] "LCY Code" = "EUR", bank currency = "USD", vendor currrency = "GBP"
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        InvCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Euro", "Currency Euro" = "", "LCY Code" = "EUR"
        // [GIVEN] Vendor bank account with currency code = "USD", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "GBP", total amount including vat = 1000 GBP (2000 USD)
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
        DummyGLSetup."Local Currency"::Euro, '', LibraryUtility.GenerateGUID(), CurrencyCode, InvCurrencyCode);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "EUR", CdtTrfTxInf.Amt.InstdAmt<Ccy = "GBP"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        // [THEN] (TFS 363009) Payment is exported in the original document currency and amount 1000 "GBP" (regardless of bank currency)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, InvCurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankDefault_InvDefault()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "", vendor currrency = ""
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with a default currency code = "", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with a default currency code = "", total amount including vat = 1000
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, '', '');

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "GBP", CdtTrfTxInf.Amt.InstdAmt<Ccy = "GBP"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, LclCurrencyCode, LibraryERM.GetLCYCode());
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankEUR_InvDefault()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "EUR", vendor currrency = ""
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with currency code = "EUR", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with a default currency code = "", total amount including vat = 1000 GBP (2000 EUR)
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, EuroCurrencyCode, '');

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "GBP", CdtTrfTxInf.Amt.InstdAmt<Ccy = "GBP"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        // [THEN] (TFS 363009) Payment is exported in the original document currency and amount 1000 "GBP" (regardless of bank currency)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, LclCurrencyCode, EuroCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankDefault_InvEUR()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "", vendor currrency = "EUR"
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with a default currency code = "", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "EUR", total amount including vat = 1000 EUR (2000 GBP)
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, '', EuroCurrencyCode);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "GBP", CdtTrfTxInf.Amt.InstdAmt<Ccy = "EUR"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        // [THEN] (TFS 363009) Payment is exported in the original document currency and amount 1000 "EUR" (regardless of bank currency)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, EuroCurrencyCode, LibraryERM.GetLCYCode());
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankEUR_InvEUR()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "EUR", vendor currrency = "EUR"
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with currency code = "EUR", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "EUR", total amount including vat = 1000 EUR
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, EuroCurrencyCode, EuroCurrencyCode);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SEPA", ChrgBr = "SLEV", DbtrAcct.Ccy = "GBP", CdtTrfTxInf.Amt.InstdAmt<Ccy = "EUR"> = 1000
        // [THEN] PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine = "X"
        // [THEN] Vendor Bank Account's IBAN is exported into CdtrAcct/Id/IBAN (TFS 311461)
        VerifyStandardEuroXML(VendorBankAccount, FileName, TotalAmount, EuroCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankEUR_InvEUR_WorldPaymentMode()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        TransactionMode: Record "Transaction Mode";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "EUR", vendor currrency = "EUR", "Transaction Mode".WorldPayment = TRUE
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup, "Transaction Mode".WorldPayment = TRUE
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with currency code = "EUR", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "EUR", total amount including vat = 1000 EUR
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, EuroCurrencyCode, EuroCurrencyCode);
        UpdateTransactionMode(TransactionMode."Account Type"::Vendor, BankAccountNo, true);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] Payment is exported in WorldPayment format
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, EuroCurrencyCode, EuroCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankUSD_InvDefault()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
        USDCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "USD", vendor currrency = ""
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        USDCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with currency code = "USD", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with a default currency code = "", total amount including vat = 1000 GBP (2000 USD)
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, USDCurrencyCode, '');

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "GBP", CdtTrfTxInf.Amt.InstdAmt<Ccy = "GBP"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        // [THEN] (TFS 363009) Payment is exported in the original document currency and amount 1000 "GBP" (regardless of bank currency)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, LclCurrencyCode, USDCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankDefault_InvUSD()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
        USDCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "", vendor currrency = "USD"
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        USDCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with a default currency code = "", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "USD", total amount including vat = 1000 USD (2000 GBP)
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, '', USDCurrencyCode);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "GBP", CdtTrfTxInf.Amt.InstdAmt<Ccy = "USD"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        // [THEN] (TFS 363009) Payment is exported in the original document currency and amount 1000 "USD" (regardless of bank currency)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, USDCurrencyCode, LibraryERM.GetLCYCode());
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankUSD_InvUSD()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
        USDCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "USD", vendor currrency = "USD"
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        USDCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with currency code = "USD", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "USD", total amount including vat = 1000 USD
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, USDCurrencyCode, USDCurrencyCode);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "GBP", CdtTrfTxInf.Amt.InstdAmt<Ccy = "USD"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, USDCurrencyCode, USDCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankEUR_InvUSD()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
        USDCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "EUR", vendor currrency = "USD"
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        USDCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with currency code = "EUR", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "USD", total amount including vat = 1000 USD (2000 EUR)
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, EuroCurrencyCode, USDCurrencyCode);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "GBP", CdtTrfTxInf.Amt.InstdAmt<Ccy = "USD"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        // [THEN] (TFS 363009) Payment is exported in the original document currency and amount 1000 "USD" (regardless of bank currency)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, USDCurrencyCode, EuroCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure GenericSEPA_GLSetupGBP_BankUSD_InvEUR()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        EuroCurrencyCode: Code[10];
        LclCurrencyCode: Code[10];
        USDCurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 294684] Generic payment SEPA export in case of GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR",
        // [SCENARIO 294684] "LCY Code" = "GBP", bank currency = "USD", vendor currrency = "EUR"
        Initialize();
        EuroCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        LclCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        USDCurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Other", "Currency Euro" = "EUR", "LCY Code" = "GBP"
        // [GIVEN] Vendor bank account with currency code = "USD", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with currency code = "EUR", total amount including vat = 1000 EUR (2000 USD)
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Other, EuroCurrencyCode, LclCurrencyCode, USDCurrencyCode, EuroCurrencyCode);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML "PmtInf" includes: PmtTpInf.SvcLvl.Cd = "SDVA", ChrgBr = "SHAR", DbtrAcct.Ccy = "GBP", CdtTrfTxInf.Amt.InstdAmt<Ccy = "EUR"> = 1000
        // [THEN] There is no node "PmtInf.CdtTrfTxInf.Cdtr.PstlAdr.AdrLine"
        // [THEN] Vendor Bank Account's "Bank Account No." is exported into CdtrAcct/Id/Othr/Id (TFS 311461)
        // [THEN] (TFS 363009) Payment is exported in the original document currency and amount 1000 "EUR" (regardless of bank currency)
        VerifyGenericPaymentXML(VendorBankAccount, FileName, TotalAmount, EuroCurrencyCode, USDCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure ChargeBearerIsDebtWhenDomesticAndForeignCostIsPrincipal()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        TransactionMode: Record "Transaction Mode";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 351652] Generic payment SEPA export has "ChrgBr" = "DEBT" when "Transfer Cost Domestic" and "Transfer Cost Foreign" is "Principal"

        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Euro", "Currency Euro" = "", "LCY Code" = "EUR"
        // [GIVEN] Vendor bank account with currency code = "USD", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with a default currency code = "", total amount including vat = 1000 EUR (2000 USD)
        PrepareGenericSEPAScenarioWithCustomTransactionCost(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Euro, '', LibraryUtility.GenerateGUID(), CurrencyCode, '',
          TransactionMode."Transfer Cost Domestic"::Principal, TransactionMode."Transfer Cost Foreign"::Principal);

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML has "ChrgBr" = "DEBT"
        XMLReadHelper.Initialize(FileName, GetSEPACTNameSpace());
        VerifyChargeBearerValue('DEBT');
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    [Scope('OnPrem')]
    procedure ChargeBearerIsCredWhenDomesticAndForeignCostIsBalancingAccountHolder()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record "General Ledger Setup";
        TransactionMode: Record "Transaction Mode";
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 351652] Generic payment SEPA export has "ChrgBr" = "CRED" when "Transfer Cost Domestic" and "Transfer Cost Foreign" is "Balancing Account Holder"

        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Euro", "Currency Euro" = "", "LCY Code" = "EUR"
        // [GIVEN] Vendor bank account with currency code = "USD", "Account Holder Address" = "X"
        // [GIVEN] Posted purchase invoice with a default currency code = "", total amount including vat = 1000 EUR (2000 USD)
        PrepareGenericSEPAScenarioWithCustomTransactionCost(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Euro, '', LibraryUtility.GenerateGUID(), CurrencyCode, '',
          TransactionMode."Transfer Cost Domestic"::"Balancing Account Holder",
          TransactionMode."Transfer Cost Foreign"::"Balancing Account Holder");

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] XML has "ChrgBr" = "CRED"
        XMLReadHelper.Initialize(FileName, GetSEPACTNameSpace());
        VerifyChargeBearerValue('CRED');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSEPAISO20022_AnyCurrencyIsAllowed()
    var
        DummyGLSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363009] Codeunit 11000010 "Check SEPA ISO20022" allows any proposal line Currency Code regardless of G\L Setup
        CheckSEPAISO20022_Scenario(DummyGLSetup."Local Currency"::Euro, '', '');
        CheckSEPAISO20022_Scenario(DummyGLSetup."Local Currency"::Euro, '', 'USD');
        CheckSEPAISO20022_Scenario(DummyGLSetup."Local Currency"::Other, '', '');
        CheckSEPAISO20022_Scenario(DummyGLSetup."Local Currency"::Other, 'USD', '');
        CheckSEPAISO20022_Scenario(DummyGLSetup."Local Currency"::Other, '', 'USD');
        CheckSEPAISO20022_Scenario(DummyGLSetup."Local Currency"::Other, 'USD', 'USD');
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure ExportByXMLPortWithNormalPriority()
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        TestSepaCtV03: Codeunit "Test SEPA CT v03";
        ExportProtocolCode: Code[20];
        FileName: Text;
        TotalAmount: Decimal;
        NoOfDocuments: Integer;
    begin
        // [FEATURE] [Normal Instruction Priority]
        // [SCENARIO 365960] Export SEPA CT using xml port with normal instruction priority
        Initialize();
        BindSubscription(TestSepaCtV03);

        // [GIVEN] Export protocol with "SEPA CT pain.001.001.03" xml port
        ExportProtocolCode := FindXMLPortEuroSEPAExportProtocol();

        // [GIVEN] Vendor entry for export
        SetupForExport(BankAccount, VendorBankAccount, ExportProtocolCode, TotalAmount, NoOfDocuments);

        // [WHEN] Run xml export
        GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // [THEN] Xml file is exported with InstrPrty = NORM
        FileName := CreateXMLFileFromCreditTransferRegisterExportedFile(BankAccount."No.");
        XMLReadHelper.Initialize(FileName, GetSEPACTNameSpace());
        XMLReadHelper.VerifyNodeCountWithValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:InstrPrty', 'NORM', 2);

        UnbindSubscription(TestSepaCtV03);
    end;

    local procedure CheckSEPAISO20022_Scenario(GLSetupLocalCurrency: Option; CurrencyEuro: Code[10]; ProposalLineCurrency: Code[10])
    var
        DummyProposalLine: Record "Proposal Line";
    begin
        UpdateGLSetupCurrency(GLSetupLocalCurrency, CurrencyEuro, '');
        DummyProposalLine."Currency Code" := ProposalLineCurrency;
        Codeunit.Run(Codeunit::"Check SEPA ISO20022", DummyProposalLine);
        DummyProposalLine.TestField(
          "Error Message",
          StrSubstNo(MustBeEnteredMsg, DummyProposalLine.FIELDCAPTION(IBAN), DummyProposalLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocalSEPAInstrPrtyIsEnabledByDefaultInGenLedgSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [DEMO]
        // [SCENARIO 381529] The "Local SEPA Instr. Prioririty" option is enabled by default in the General Ledger Setup

        Initialize();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Local SEPA Instr. Priority");
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure InstrPrtyValueWHenLocalSEPAInstrPrtyIsEnabled()
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        ExportProtocolCode: Code[20];
        FileName: Text;
        TotalAmount: Decimal;
    begin
        // [SCENARIO 381529] SEPA CT xml file has InstrPrty equals "HIGH" when when export with "Local SEPA Instr. Prioririty" option is enabled in the General Ledger Setup
        Initialize();

        // [GIVEN] "Local SEPA Instr. Priority" is enabled in General Ledger Setup
        UpdateLocalInstrPrtyInGenLedgSetup(true);

        // [GIVEN] Export protocol with "SEPA CT pain.001.001.03" xml port
        ExportProtocolCode := FindXMLPortEuroSEPAExportProtocol();

        // [GIVEN] Vendor entry for export
        SetupForExportByNumberOfDocuments(BankAccount, VendorBankAccount, ExportProtocolCode, 1, TotalAmount);

        // [WHEN] Run xml export
        GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // [THEN] Xml file is exported with InstrPrty = HIGH
        FileName := CreateXMLFileFromCreditTransferRegisterExportedFile(BankAccount."No.");
        XMLReadHelper.Initialize(FileName, GetSEPACTNameSpace());
        XMLReadHelper.VerifyNodeCountWithValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:InstrPrty', 'HIGH', 1);
        XMLReadHelper.VerifyNodeCountWithValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:InstrPrty', 'NORM', 0);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler')]
    procedure InstrPrtyValueWHenLocalSEPAInstrPrtyIsDisabled()
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        ExportProtocolCode: Code[20];
        FileName: Text;
        TotalAmount: Decimal;
    begin
        // [SCENARIO 381529] SEPA CT xml file has InstrPrty equals "NORM" when when export with "Local SEPA Instr. Prioririty" option is enabled in the General Ledger Setup
        Initialize();

        // [GIVEN] "Local SEPA Instr. Priority" is disabled in General Ledger Setup
        UpdateLocalInstrPrtyInGenLedgSetup(false);

        // [GIVEN] Export protocol with "SEPA CT pain.001.001.03" xml port
        ExportProtocolCode := FindXMLPortEuroSEPAExportProtocol();

        // [GIVEN] Vendor entry for export
        SetupForExportByNumberOfDocuments(BankAccount, VendorBankAccount, ExportProtocolCode, 1, TotalAmount);

        // [WHEN] Run xml export
        GetEntriesAndExportSEPAReport(BankAccount."No.", ExportProtocolCode);

        // [THEN] Xml file is exported with InstrPrty = NORM
        FileName := CreateXMLFileFromCreditTransferRegisterExportedFile(BankAccount."No.");
        XMLReadHelper.Initialize(FileName, GetSEPACTNameSpace());
        XMLReadHelper.VerifyNodeCountWithValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:InstrPrty', 'NORM', 1);
        XMLReadHelper.VerifyNodeCountWithValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:InstrPrty', 'HIGH', 0);
    end;

    [Test]
    [HandlerFunctions('ProposalLineConfirmHandler,ProposalProcessedMsgHandler,SEPAExportReqPageHandler')]
    procedure GenericSEPAExportsIBANWhenBankAccountIsBlanked()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        DummyGLSetup: Record 98;
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        TotalAmount: Decimal;
        FileName: Text;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [XML]
        // [SCENARIO 396808] Generic payment SEPA exports creditor's IBAN in case of blanked bank account No.
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Generic payment SEPA export protocol setup
        // [GIVEN] GLSetup."Local Curency" = "Euro", "Currency Euro" = "", "LCY Code" = "EUR"
        // [GIVEN] Vendor bank account with currency code = "USD", "Account Holder Address" = "X", IBAN = "Y", blanked "Bank Account No."
        // [GIVEN] Posted purchase invoice with a default currency code = ""
        PrepareGenericSEPAScenario(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount,
          DummyGLSetup."Local Currency"::Euro, '', LibraryUtility.GenerateGUID(), CurrencyCode, '');
        VendorBankAccount."Bank Account No." := '';
        VendorBankAccount.Modify();

        // [WHEN] Export payment for the generated proposal for the given vendor
        FileName := GetEntriesAndExportSEPAReport(BankAccountNo, ExportProtocolCode);

        // [THEN] Vendor Bank Account's IBAN is exported into CdtrAcct/Id/IBAN
        XMLReadHelper.Initialize(FileName, GetSEPACTNameSpace());
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:CdtrAcct/ns:Id/ns:IBAN', FormatIBAN(VendorBankAccount.IBAN));
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test SEPA CT v03");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test SEPA CT v03");

        CreateExportProtocols();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test SEPA CT v03");
    end;

    local procedure PrepareGenericSEPAScenario(var VendorBankAccount: Record "Vendor Bank Account"; var BankAccountNo: Code[20]; var ExportProtocolCode: Code[20]; var TotalAmount: Decimal; LocalCurrency: Option; CurrencyEuro: Code[10]; LCYCode: Code[10]; BankCurrencyCode: Code[10]; VendorCurrencyCode: Code[10])
    var
        TransactionMode: Record "Transaction Mode";
    begin
        PrepareGenericSEPAScenarioCustom(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount, LocalCurrency,
          CurrencyEuro, LCYCode, BankCurrencyCode, VendorCurrencyCode,
          TransactionMode."Transfer Cost Domestic"::Principal, TransactionMode."Transfer Cost Foreign"::"Balancing Account Holder");
    end;

    local procedure PrepareGenericSEPAScenarioWithCustomTransactionCost(var VendorBankAccount: Record "Vendor Bank Account"; var BankAccountNo: Code[20]; var ExportProtocolCode: Code[20]; var TotalAmount: Decimal; LocalCurrency: Option; CurrencyEuro: Code[10]; LCYCode: Code[10]; BankCurrencyCode: Code[10]; VendorCurrencyCode: Code[10]; TransactionCostDomestic: Option; TransactionCostForeign: Option)
    begin
        PrepareGenericSEPAScenarioCustom(
          VendorBankAccount, BankAccountNo, ExportProtocolCode, TotalAmount, LocalCurrency,
          CurrencyEuro, LCYCode, BankCurrencyCode, VendorCurrencyCode, TransactionCostDomestic, TransactionCostForeign);
    end;

    local procedure PrepareGenericSEPAScenarioCustom(var VendorBankAccount: Record "Vendor Bank Account"; var BankAccountNo: Code[20]; var ExportProtocolCode: Code[20]; var TotalAmount: Decimal; LocalCurrency: Option; CurrencyEuro: Code[10]; LCYCode: Code[10]; BankCurrencyCode: Code[10]; VendorCurrencyCode: Code[10]; TransactionCostDomestic: Option; TransactionCostForeign: Option)
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
    begin
        ExportProtocolCode := FindGenericPaymentSEPAExportProtocol();
        UpdateGLSetupCurrency(LocalCurrency, CurrencyEuro, LCYCode);
        SetUpTransactionModeDomesticForeign(
          CreateSEPABankAccount(BankAccount, BankCurrencyCode), ExportProtocolCode, TransactionCostDomestic, TransactionCostForeign);
        BankAccountNo := BankAccount."No.";
        CreateVendorWithBankAccount(Vendor, BankAccount, VendorCurrencyCode);
        VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");
        TotalAmount := CreateAndPostPurchInvoice(Vendor."No.", true);
    end;

    local procedure SetupForExport(var BankAccount: Record "Bank Account"; var VendorBankAccount: Record "Vendor Bank Account"; ExportProtocolCode: Code[20]; var TotalAmount: Decimal; var NoOfDocuments: Integer)
    begin
        NoOfDocuments := GenerateNoOfDocuments();
        SetupForExportByNumberOfDocuments(BankAccount, VendorBankAccount, ExportProtocolCode, NoOfDocuments, TotalAmount);
    end;

    local procedure SetupForExportByNumberOfDocuments(var BankAccount: Record "Bank Account"; var VendorBankAccount: Record "Vendor Bank Account"; ExportProtocolCode: Code[20]; NoOfDocuments: Integer; var TotalAmount: Decimal)
    var
        Vendor: Record Vendor;
        i: Integer;
    begin
        SetUpTransactionMode(CreateSEPABankAccount(BankAccount, ''), ExportProtocolCode);
        for i := 1 to NoOfDocuments do begin
            CreateVendorWithBankAccount(Vendor, BankAccount, '');
            TotalAmount += CreateAndPostPurchInvoice(Vendor."No.", false);
            if i = 1 then
                VendorBankAccount.Get(Vendor."No.", Vendor."Preferred Bank Account Code");
        end;
    end;

    local procedure BlankIBANOnVendorBankAccount(VendorNo: Code[20])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        VendorBankAccount.FindFirst();
        VendorBankAccount.IBAN := '';
        VendorBankAccount.Modify();
    end;

    local procedure CreateAndPostPurchInvoice(VendorNo: Code[20]; RoundedTotal: Boolean): Decimal
    begin
        exit(PostPurchInvoice(CreatePurchInvoice(VendorNo, RoundedTotal)));
    end;

    local procedure CreateAndPostEmployeeExpense(Employee: Record Employee): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDecInRange(100, 200, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Employee, Employee."No.", -Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(Amount);
    end;

    local procedure CreatePurchInvoice(VendorNo: Code[20]; RoundedTotal: Boolean): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo);
        PurchHeader.Validate("Posting Date", Today); // "Get Entries" takes all before Today + 1
        PurchHeader.Modify(true);
        Vendor.Get(VendorNo);
        LibraryInventory.CreateItem(Item);
        if RoundedTotal then
            SetItemZeroVAT(Item, Vendor."VAT Bus. Posting Group"); // To make Doc. Amount Incl. VAT values without decimal part
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(GetMaxDocumentAmount() div 10, GetMaxDocumentAmount()) div 2); // -VAT%
        PurchLine.Modify(true);
        PurchHeader.Validate("Doc. Amount Incl. VAT", PurchLine."Outstanding Amount");
        PurchHeader.Modify(true);
        exit(PurchHeader."No.");
    end;

    local procedure PostPurchInvoice(DocumentNo: Code[20]): Decimal
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(PurchHeader."Document Type"::Invoice, DocumentNo);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);
        exit(PurchHeader."Doc. Amount Incl. VAT");
    end;

    local procedure CreateAndPostPurchInvoiceWithMaxInvNo(VendorNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(PurchHeader."Document Type"::Invoice, CreatePurchInvoice(VendorNo, false));
        PurchHeader.Validate(
          "Vendor Invoice No.",
          PadStr(PurchHeader."Vendor Invoice No.", MaxStrLen(PurchHeader."Vendor Invoice No."), Format(LibraryRandom.RandInt(9))));
        PurchHeader.Modify();
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true));
    end;

    local procedure CreateExportProtocols()
    var
        ExportProtocol: Record "Export Protocol";
    begin
        CreateExportProtocol(
          CODEUNIT::"Check SEPA ISO20022", REPORT::Docket, ExportProtocol."Export Object Type"::XMLPort,
          XMLPORT::"SEPA CT pain.001.001.03", TemporaryPath + 'SEPACTxml_%1.xml');

        CreateExportProtocol(
          CODEUNIT::"Check SEPA ISO20022", REPORT::Docket, ExportProtocol."Export Object Type"::Report,
          REPORT::"SEPA ISO20022 Pain 01.01.03", TemporaryPath + 'SEPACTrep_' + LibraryUtility.GenerateGUID() + '.xml');

        ExportProtocol.Get('GENERIC SEPA');
        ExportProtocol.Validate("Default File Names", TemporaryPath + 'GenSEPA_' + LibraryUtility.GenerateGUID() + '.xml');
        ExportProtocol.Modify(true);
    end;

    local procedure CreateExportProtocol(CheckID: Integer; DocketID: Integer; ExportObjectType: Option; ExportID: Integer; DefaultFileNames: Text[250]): Code[20]
    var
        ExportProtocol: Record "Export Protocol";
    begin
        ExportProtocol.Init();
        ExportProtocol.Validate(Code, LibraryUtility.GenerateGUID());
        ExportProtocol.Validate("Check ID", CheckID);
        ExportProtocol.Validate("Docket ID", DocketID);
        ExportProtocol.Validate("Export Object Type", ExportObjectType);
        ExportProtocol.Validate("Export ID", ExportID);
        ExportProtocol.Validate("Default File Names", DefaultFileNames);
        ExportProtocol.Insert(true);
        exit(ExportProtocol.Code);
    end;

    local procedure CreateExportProtocolForReport(ExportProtocolReportID: Integer): Code[20]
    var
        DummyExportProtocol: Record "Export Protocol";
    begin
        exit(CreateExportProtocol(
            0, 0, DummyExportProtocol."Export Object Type"::Report, ExportProtocolReportID,
            TemporaryPath + LibraryUtility.GenerateGUID() + '.xml'));
    end;

    local procedure CreateFreelyTransferableMax(CountryRegionCode: Code[10]; CurrencyCode: Code[10])
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        if not FreelyTransferableMaximum.Get(CountryRegionCode, CurrencyCode) then begin
            FreelyTransferableMaximum.Init();
            FreelyTransferableMaximum.Validate("Country/Region Code", CountryRegionCode);
            FreelyTransferableMaximum.Validate("Currency Code", CurrencyCode);
            FreelyTransferableMaximum.Validate(Amount, GetMaxNoOfDocuments() * GetMaxDocumentAmount());
            FreelyTransferableMaximum.Insert(true);
        end;
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; BankAccount: Record "Bank Account"; VendorCurrencyCode: Code[10])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        PostCode: Record "Post Code";
    begin
        Clear(Vendor);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        Vendor.Validate("Transaction Mode Code", BankAccount."No.");
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Validate("Country/Region Code", BankAccount."Country/Region Code");
        Vendor.Validate("Currency Code", VendorCurrencyCode);
        Vendor.Modify(true);

        VendorBankAccount.Validate(Name, BankAccount.Name);
        VendorBankAccount.Validate("Bank Account No.", BankAccount.Name);
        VendorBankAccount.Validate("Country/Region Code", BankAccount."Country/Region Code");
        VendorBankAccount.Validate("Account Holder Address",
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Account Holder Address"), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate(City, LibraryUtility.GenerateGUID());

        PostCode.FindFirst();
        VendorBankAccount.Validate("Account Holder Post Code", PostCode.Code);
        VendorBankAccount.Validate(IBAN, 'GB 12 CPBK 08929965044991'); // hard coded due to IBAN validation
        VendorBankAccount.Validate("SWIFT Code",
          LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("SWIFT Code"), DATABASE::"Vendor Bank Account"));
        VendorBankAccount.Validate("Acc. Hold. Country/Region Code", BankAccount."Country/Region Code");
        // add chars not allowed by EPC
        VendorBankAccount."Account Holder Name" := '&' + BankAccount."Account Holder Name";
        VendorBankAccount."Account Holder Address" := '@' + BankAccount."Account Holder Address";
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateEmployeeWithBankAccount(var Employee: Record Employee; BankAccount: Record "Bank Account"; EmployeeName: Text)
    var
        PostCode: Record "Post Code";
    begin
        Clear(Employee);
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);

        Employee.Validate("Transaction Mode Code", BankAccount."No.");
        Employee.Validate("Bank Account No.", BankAccount."No.");
        Employee.Validate("Country/Region Code", BankAccount."Country/Region Code");
        Employee.Modify(true);

        PostCode.FindFirst();
        Employee.Validate(IBAN, 'GB 12 CPBK 08929965044991'); // hard coded due to IBAN validation
        Employee.Validate("SWIFT Code",
          LibraryUtility.GenerateRandomCode(Employee.FieldNo("SWIFT Code"), DATABASE::Employee));

        // add chars not allowed by EPC
        Employee."First Name" := CopyStr('&' + EmployeeName, 1, MaxStrLen(Employee."First Name"));
        Employee.Address := '@' + Employee.Address;
        Employee.Modify(true);
    end;

    local procedure CreatePaymentHistory(var PaymentHistory: Record "Payment History"; ExportProtocolReportID: Integer)
    var
        ExportProtocol: Record "Export Protocol";
        ExportProtocolCode: Code[20];
    begin
        MockPaymentHistory(PaymentHistory);
        ExportProtocolCode :=
          CreateExportProtocol(
            0, 0, ExportProtocol."Export Object Type"::Report,
            ExportProtocolReportID, TemporaryPath + LibraryUtility.GenerateGUID() + '.xml');
        PaymentHistory."Export Protocol" := ExportProtocolCode;
        PaymentHistory.Modify();
    end;

    local procedure CreateXMLFileFromCreditTransferRegisterExportedFile(BankAccountNo: Code[20]) FileName: Text
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        FileManagement: Codeunit "File Management";
    begin
        CreditTransferRegister.SetRange("From Bank Account No.", BankAccountNo);
        CreditTransferRegister.FindLast();
        CreditTransferRegister.CalcFields("Exported File");
        FileName := CreditTransferRegister."Exported File".Export(FileManagement.ServerTempFileName('.xml'));
    end;

    local procedure MockPaymentHistoryWithLine(var PaymentHistory: Record "Payment History"; ExportProtocolReportID: Integer)
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        CreatePaymentHistory(PaymentHistory, ExportProtocolReportID);
        MockPaymentHistoryLineWithAccount(PaymentHistoryLine, PaymentHistory);
    end;

    local procedure MockPaymentHistoryWithLineAndOurBank(var PaymentHistory: Record "Payment History"; OurBank: Code[20])
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        MockPaymentHistoryWithOurBank(PaymentHistory, OurBank);
        MockPaymentHistoryLineWithAccount(PaymentHistoryLine, PaymentHistory);
    end;

    local procedure MockPaymentHistory(var PaymentHistory: Record "Payment History")
    begin
        PaymentHistory.Init();
        PaymentHistory."Our Bank" := LibraryERM.CreateBankAccountNo();
        PaymentHistory."Run No." := LibraryUtility.GenerateGUID();
        PaymentHistory.Insert();
    end;

    local procedure MockPaymentHistoryWithOurBank(var PaymentHistory: Record "Payment History"; OurBank: Code[20])
    begin
        PaymentHistory.Init();
        PaymentHistory."Our Bank" := OurBank;
        PaymentHistory."Run No." := LibraryUtility.GenerateGUID();
        PaymentHistory.Insert();
    end;

    local procedure MockPaymentHistoryLine(var PaymentHistoryLine: Record "Payment History Line"; PaymentHistory: Record "Payment History"; NewStatus: Option; NewAmount: Decimal)
    begin
        PaymentHistoryLine.Init();
        PaymentHistoryLine."Our Bank" := PaymentHistory."Our Bank";
        PaymentHistoryLine."Run No." := PaymentHistory."Run No.";
        PaymentHistoryLine."Line No." := LibraryUtility.GetNewRecNo(PaymentHistoryLine, PaymentHistoryLine.FieldNo("Line No."));
        PaymentHistoryLine.Status := NewStatus;
        PaymentHistoryLine.Amount := NewAmount;
        PaymentHistoryLine."Direct Debit Mandate ID" := MockSEPADirectDebitMandate();
        PaymentHistoryLine.Insert();
    end;

    local procedure MockPaymentHistoryLineWithAccount(var PaymentHistoryLine: Record "Payment History Line"; PaymentHistory: Record "Payment History")
    begin
        MockPaymentHistoryLine(
          PaymentHistoryLine, PaymentHistory, PaymentHistoryLine.Status::New, LibraryRandom.RandDecInRange(100, 200, 2));
        PaymentHistoryLine.Validate("Account No.", LibrarySales.CreateCustomerNo());
        PaymentHistoryLine.Modify(true);
    end;

    local procedure MockPaymentHistoryLineWithAmounts(var PaymentHistoryLine: Record "Payment History Line"; PaymentHistory: Record "Payment History"; Amount: Decimal; ForeignAmount: Decimal)
    begin
        MockPaymentHistoryLine(PaymentHistoryLine, PaymentHistory, PaymentHistoryLine.Status::New, Amount);
        PaymentHistoryLine."Foreign Amount" := ForeignAmount;
        PaymentHistoryLine.Modify();
    end;

    local procedure MockSEPADirectDebitMandate(): Code[35]
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate.ID := LibraryUtility.GenerateGUID();
        SEPADirectDebitMandate.Insert();
        exit(SEPADirectDebitMandate.ID);
    end;

    local procedure ModifyPaymentHistoryExportProtocol(var PaymentHistory: Record "Payment History"; ExportProtocol: Code[20])
    begin
        PaymentHistory.Validate("Export Protocol", ExportProtocol);
        PaymentHistory.Modify(true);
    end;

    local procedure GetEntriesAndExportSEPAReport(BankAccountNo: Code[20]; ExportProtocolCode: Code[20]): Text
    begin
        GetEntries(BankAccountNo);
        MixDateAndUrgentValues(BankAccountNo);
        ProcessProposals(BankAccountNo);
        exit(ExportSEPAFile(BankAccountNo, ExportProtocolCode));
    end;

    local procedure ExportSEPAFile(BankAccountNo: Code[20]; ExportProtocolCode: Code[20]): Text
    var
        PaymentHistory: Record "Payment History";
    begin
        Commit();
        PaymentHistory.SetRange("Export Protocol", ExportProtocolCode);
        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.SetRange(Export, true);
        PaymentHistory.FindFirst();
        PaymentHistory.ExportToPaymentFile();

        PaymentHistory.SetRange(Export, false);
        PaymentHistory.Find();
        exit(PaymentHistory."File on Disk");
    end;

    local procedure FindStandardEuroSEPAExportProtocol(): Code[20]
    var
        DummyExportProtocol: Record "Export Protocol";
    begin
        exit(
          FindExportProtocol(
            CODEUNIT::"Check SEPA ISO20022", DummyExportProtocol."Export Object Type"::Report, REPORT::"SEPA ISO20022 Pain 01.01.03"));
    end;

    local procedure FindXMLPortEuroSEPAExportProtocol(): Code[20]
    var
        DummyExportProtocol: Record "Export Protocol";
    begin
        exit(
          FindExportProtocol(
            CODEUNIT::"Check SEPA ISO20022", DummyExportProtocol."Export Object Type"::XMLPort, XMLPORT::"SEPA CT pain.001.001.03"));
    end;

    local procedure FindGenericPaymentSEPAExportProtocol(): Code[20]
    var
        DummyExportProtocol: Record "Export Protocol";
    begin
        exit(
          FindExportProtocol(
            CODEUNIT::"Check BTL91", DummyExportProtocol."Export Object Type"::Report, REPORT::"SEPA ISO20022 Pain 01.01.03"));
    end;

    local procedure FindExportProtocol(CheckID: Integer; ExportObjectType: Option; ExportID: Integer): Code[20]
    var
        ExportProtocol: Record "Export Protocol";
    begin
        ExportProtocol.SetRange("Check ID", CheckID);
        ExportProtocol.SetRange("Export Object Type", ExportObjectType);
        ExportProtocol.SetRange("Export ID", ExportID);
        ExportProtocol.FindFirst();
        exit(ExportProtocol.Code);
    end;

    local procedure FindPaymentHistoryToExport(var PaymentHistory: Record "Payment History"; BankAccountNo: Code[20]; ExportProtocolCode: Code[20])
    begin
        PaymentHistory.SetRange("Our Bank", BankAccountNo);
        PaymentHistory.SetRange("Export Protocol", ExportProtocolCode);
        PaymentHistory.FindLast();
    end;

    local procedure FormatCtrlSumValue(Value: Decimal): Text
    begin
        exit(
          Format(Value, 0, '<Precision,2:2><Standard Format,9>'));
    end;

    local procedure GetEntries(BankAccountNo: Code[20])
    var
        TransactionMode: Record "Transaction Mode";
    begin
        Commit();
        TransactionMode.SetRange("Our Bank", BankAccountNo);
        REPORT.RunModal(REPORT::"Get Proposal Entries", false, true, TransactionMode);
    end;

    local procedure GenerateNoOfDocuments(): Integer
    begin
        exit(LibraryRandom.RandIntInRange(3, GetMaxNoOfDocuments())); // min = 3 for verify grouping
    end;

    local procedure GetMaxNoOfDocuments(): Integer
    begin
        exit(5);
    end;

    local procedure GetMaxDocumentAmount(): Integer
    begin
        exit(2000);
    end;

    local procedure GetEuroCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GLSetup."Local Currency" = GLSetup."Local Currency"::Euro then
            exit(GLSetup."LCY Code");
        exit(GLSetup."Currency Euro");
    end;

    local procedure MixDateAndUrgentValues(BankAccountNo: Code[20])
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine.SetRange("Our Bank No.", BankAccountNo);
        ProposalLine.FindFirst();
        ProposalLine."Transaction Date" := ProposalLine."Transaction Date" - 1;
        ProposalLine.Modify();

        ProposalLine.FindLast();
        ProposalLine.Urgent := true;
        ProposalLine.Modify();
    end;

    local procedure ProcessProposals(BankAccountNo: Code[20])
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine.SetRange("Our Bank No.", BankAccountNo);
        ProposalLine.FindLast();
        ProcessProposalLines.Run(ProposalLine);
        ProcessProposalLines.ProcessProposallines();
    end;

    local procedure CreateSEPABankAccount(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10]): Code[20]
    var
        BankAccPostingGroup: Record "Bank Account Posting Group";
        GLAccount: Record "G/L Account";
        PostCode: Record "Post Code";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        NoSeries: Record "No. Series";
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := SetUpCountrySEPAAllowed();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("SWIFT Code", Format(LibraryRandom.RandInt(1000000000))); // SWIFTCode
        BankAccount.Validate("Country/Region Code", CountryRegionCode);
        BankAccount.Validate("Currency Code", CurrencyCode);
        CreateFreelyTransferableMax(CountryRegionCode, CurrencyCode);
        BankAccount.Validate(Balance, GetMaxNoOfDocuments() * GetMaxDocumentAmount()); // Balance must be positive
        BankAccount.Validate(IBAN, 'GB 12 CPBK 08929965044991'); // hard coded due to IBAN validation
        BankAccount.Validate("Bank Account No.",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Account No."), DATABASE::"Bank Account"));
        BankAccount.Validate("Account Holder Name",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Account Holder Name"), DATABASE::"Bank Account"));
        BankAccount.Validate("Account Holder Address",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Account Holder Address"), DATABASE::"Bank Account"));
        PostCode.Next(LibraryRandom.RandInt(PostCode.Count));
        BankAccount.Validate("Account Holder Post Code", PostCode.Code);
        BankAccPostingGroup.Next(LibraryRandom.RandInt(BankAccPostingGroup.Count));

        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.SetRange("Direct Posting", false);
        GLAccount.FindFirst();
        BankAccPostingGroup.Validate("Acc.No. Pmt./Rcpt. in Process", GLAccount."No.");
        BankAccPostingGroup.Modify(true);
        Commit();
        BankAccount.Validate("Bank Acc. Posting Group", BankAccPostingGroup.Code);
        // W1 SEPA CT export
        BankExportImportSetup.Code := LibraryUtility.GenerateGUID();
        BankExportImportSetup."Check Export Codeunit" := CODEUNIT::"SEPA CT-Check Line";
        BankExportImportSetup."Preserve Non-Latin Characters" := false;
        BankExportImportSetup.Insert();
        BankAccount."Payment Export Format" := BankExportImportSetup.Code; // Not necessary in NL?
        NoSeries.FindFirst();
        BankAccount."Credit Transfer Msg. Nos." := NoSeries.Code;
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateZeroVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20])
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProdPostingGroup.Code);
        VATPostingSetup."VAT %" := 0;
        VATPostingSetup.Modify(true);
    end;

    local procedure GetSEPACTNameSpace(): Text
    begin
        exit('urn:iso:std:iso:20022:tech:xsd:pain.001.001.03');
    end;

    local procedure SetAccountHolderName(PaymentHistory: Record "Payment History"; AccountHolderName: Text)
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistoryLine.SetRange("Our Bank", PaymentHistory."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", PaymentHistory."Run No.");
        PaymentHistoryLine.FindFirst();
        PaymentHistoryLine."Account Holder Name" := AccountHolderName;
        PaymentHistoryLine.Modify();
    end;

    local procedure SetUpCountrySEPAAllowed(): Code[10]
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInfo.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInfo."Country/Region Code");
        CountryRegion.FindFirst();

        CountryRegion.Validate("SEPA Allowed", true);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code)
    end;

    local procedure SetUpTransactionMode(BankAccountCode: Code[20]; ExportProtocolCode: Code[20])
    var
        TransactionMode: Record "Transaction Mode";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        TransactionMode.Init();
        TransactionMode.Validate(Code, BankAccountCode);
        TransactionMode.Validate("Account Type", TransactionMode."Account Type"::Vendor);
        TransactionMode.Validate("Export Protocol", ExportProtocolCode);
        TransactionMode.Validate("Our Bank", BankAccountCode);
        TransactionMode.Validate("Run No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Validate("Identification No. Series", LibraryERM.CreateNoSeriesCode());
        LibraryERM.FindGLAccount(GLAccount);
        TransactionMode.Validate("Acc. No. Pmt./Rcpt. in Process", GLAccount."No.");
        SourceCode.Next(LibraryRandom.RandInt(SourceCode.Count));
        TransactionMode.Validate("Source Code", SourceCode.Code);
        TransactionMode.Validate("Posting No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Insert(true);
    end;

    local procedure SetUpTransactionModeDomesticForeign(BankAccountCode: Code[20]; ExportProtocolCode: Code[20]; TransactionCostDomestic: Option; TransactionCostForeign: Option)
    var
        TransactionMode: Record "Transaction Mode";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        TransactionMode.Init();
        TransactionMode.Validate(Code, BankAccountCode);
        TransactionMode.Validate("Account Type", TransactionMode."Account Type"::Vendor);
        TransactionMode.Validate("Export Protocol", ExportProtocolCode);
        TransactionMode.Validate("Our Bank", BankAccountCode);
        TransactionMode.Validate("Run No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Validate("Identification No. Series", LibraryERM.CreateNoSeriesCode());
        LibraryERM.FindGLAccount(GLAccount);
        TransactionMode.Validate("Acc. No. Pmt./Rcpt. in Process", GLAccount."No.");
        SourceCode.Next(LibraryRandom.RandInt(SourceCode.Count()));
        TransactionMode.Validate("Source Code", SourceCode.Code);
        TransactionMode.Validate("Posting No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Validate("Transfer Cost Domestic", TransactionCostDomestic);
        TransactionMode.Validate("Transfer Cost Foreign", TransactionCostForeign);
        TransactionMode.Insert(true);
    end;

    local procedure SetUpTransactionModeForEmployee(BankAccountCode: Code[20]; ExportProtocolCode: Code[20])
    var
        TransactionMode: Record "Transaction Mode";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        TransactionMode.Init();
        TransactionMode.Validate(Code, BankAccountCode);
        TransactionMode.Validate("Account Type", TransactionMode."Account Type"::Employee);
        TransactionMode.Validate("Export Protocol", ExportProtocolCode);
        TransactionMode.Validate("Our Bank", BankAccountCode);
        TransactionMode.Validate("Run No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Validate("Identification No. Series", LibraryERM.CreateNoSeriesCode());
        LibraryERM.FindGLAccount(GLAccount);
        TransactionMode.Validate("Acc. No. Pmt./Rcpt. in Process", GLAccount."No.");
        SourceCode.Next(LibraryRandom.RandInt(SourceCode.Count));
        TransactionMode.Validate("Source Code", SourceCode.Code);
        TransactionMode.Validate("Posting No. Series", LibraryERM.CreateNoSeriesCode());
        TransactionMode.Insert(true);
    end;

    local procedure SetItemZeroVAT(var Item: Record Item; VATBusPostGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateZeroVATPostingSetup(VATPostingSetup, VATBusPostGroupCode);
        Item."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        Item.Modify(true);
    end;

    local procedure UpdateGLSetupCurrency(LocalCurrency: Option; CurrencyEuro: Code[10]; LCYCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Local Currency", LocalCurrency);
        if LocalCurrency = GeneralLedgerSetup."Local Currency"::Other then
            GeneralLedgerSetup.Validate("Currency Euro", CurrencyEuro);
        GeneralLedgerSetup."LCY Code" := '';        // to avoid error on updating LCY Code
        GeneralLedgerSetup.Validate("LCY Code", LCYCode);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateLocalInstrPrtyInGenLedgSetup(NewLocalInstrPrty: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Local SEPA Instr. Priority", NewLocalInstrPrty);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateTransactionMode(AccountType: Option; BankCode: Code[20]; WorldPayment: Boolean)
    var
        TransactionMode: Record "Transaction Mode";
    begin
        TransactionMode.Get(AccountType, BankCode);
        TransactionMode.Validate(WorldPayment, WorldPayment);
        TransactionMode.Modify(true);
    end;

    local procedure FormatIBAN(IBAN: Text): Text
    begin
        exit(DelChr(IBAN));
    end;

    local procedure VerifyAccHolderAddr(PaymentHistoryLine: Record "Payment History Line"; No: Integer; Value: Text)
    var
        AddrLine: array[3] of Text[70];
        i: Integer;
    begin
        Assert.IsTrue(PaymentHistoryLine.GetAccHolderPostalAddr(AddrLine), '');
        for i := 1 to ArrayLen(AddrLine) do
            if i = No then
                Assert.AreEqual(Value, AddrLine[i], Format(i))
            else
                Assert.AreEqual('', AddrLine[i], Format(i));
    end;

    local procedure VerifySEPACreditTransferFile(ExportFileName: Text; TotalAmount: Decimal; VendorBankAccount: Record "Vendor Bank Account";
    GeneratedByReport: Boolean; NoOfDocuments: Integer; BankAccCurrency: Code[10])
    var
        CompanyInfo: Record "Company Information";
        Node: DotNet XmlNode;
        NameSpace: Text;
    begin
        CompanyInfo.Get();

        // intentionally commented out, since XSD schema must be saved on local hard disk
        // XMLReadHelper.ValidateXMLFileAgainstXSD(ExportFileName,
        // 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03',FORMAT(XSDSchemaPathTxt));

        NameSpace := GetSEPACTNameSpace();
        XMLReadHelper.Initialize(ExportFileName, NameSpace);

        Assert.AreEqual(
          'http://www.w3.org/2001/XMLSchemainstance',
          XMLReadHelper.LookupNamespace('xsi'), 'Missed namespace');

        XMLReadHelper.GetNodeByXPath('//ns:Document', Node);
        XMLReadHelper.VerifyAttributeValue('//ns:Document', 'xmlns', NameSpace);

        XMLReadHelper.GetNodeByXPath('//ns:Document/ns:CstmrCdtTrfInitn', Node);
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:GrpHdr/ns:NbOfTxs', Format(NoOfDocuments));

        XMLReadHelper.GetNodeByXPath('//ns:Document/ns:CstmrCdtTrfInitn', Node);
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:GrpHdr/ns:InitgPty/ns:Id/ns:OrgId/ns:Othr/ns:Id',
          CompanyInfo."VAT Registration No.");
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:GrpHdr/ns:CtrlSum',
          FormatCtrlSumValue(TotalAmount));
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:BtchBookg', 'false');

        if GeneratedByReport then begin
            XMLReadHelper.GetNodeByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:CtgyPurp', Node);
            XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:CtgyPurp/ns:Cd', 'SUPP');
            XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:DbtrAcct/ns:Ccy', BankAccCurrency);
        end;

        // Verify chars conversion
        VendorBankAccount."Account Holder Name" := '+' + CopyStr(VendorBankAccount."Account Holder Name", 2); // '&'
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:Nm', VendorBankAccount."Account Holder Name");
    end;

    local procedure VerifySEPACreditTransferFileForEmployee(ExportFileName: Text; TotalAmount: Decimal; Employee: Record Employee; GeneratedByReport: Boolean; NoOfDocuments: Integer)
    var
        CompanyInfo: Record "Company Information";
        Node: DotNet XmlNode;
        NameSpace: Text;
    begin
        CompanyInfo.Get();

        // intentionally commented out, since XSD schema must be saved on local hard disk
        // XMLReadHelper.ValidateXMLFileAgainstXSD(ExportFileName,
        // 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.03',FORMAT(XSDSchemaPathTxt));

        NameSpace := GetSEPACTNameSpace();
        XMLReadHelper.Initialize(ExportFileName, NameSpace);

        XMLReadHelper.GetNodeByXPath('//ns:Document', Node);
        XMLReadHelper.VerifyAttributeValue('//ns:Document', 'xmlns', NameSpace);

        XMLReadHelper.GetNodeByXPath('//ns:Document/ns:CstmrCdtTrfInitn', Node);
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:GrpHdr/ns:NbOfTxs', Format(NoOfDocuments));

        XMLReadHelper.GetNodeByXPath('//ns:Document/ns:CstmrCdtTrfInitn', Node);
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:GrpHdr/ns:InitgPty/ns:Id/ns:OrgId/ns:Othr/ns:Id',
          CompanyInfo."VAT Registration No.");
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:GrpHdr/ns:CtrlSum',
          FormatCtrlSumValue(TotalAmount));
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:BtchBookg', 'false');

        if GeneratedByReport then begin
            XMLReadHelper.GetNodeByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:CtgyPurp', Node);
            XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:CtgyPurp/ns:Cd', 'SUPP');
            XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:DbtrAcct/ns:Ccy', LibraryERM.GetLCYCode());
        end;

        // Verify chars conversion
        Employee."First Name" := '+' + CopyStr(Employee."First Name", 2); // '&'
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:Nm', Employee.FullName());
    end;

    local procedure VerifySEPACreditTransferFileCtrlSumInstdAmtRound(ExportFileName: Text; CtrlSum: Decimal; PaymentCurrency: Text)
    var
        NameSpace: Text;
    begin
        NameSpace := GetSEPACTNameSpace();
        XMLReadHelper.Initialize(ExportFileName, NameSpace);

        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:GrpHdr/ns:CtrlSum',
          FormatCtrlSumValue(CtrlSum));
        VerifyTransactionAmountWithCurrency(CtrlSum, PaymentCurrency);
    end;

    local procedure VerifyMultiplePaymentHistoryLinesInSEPAFile(ExportFileName: Text; BankAccountNo: Code[20]; ExportProtocolCode: Code[20])
    var
        PaymentHistory: Record "Payment History";
        PaymentHistoryLine: Record "Payment History Line";
        i: Integer;
    begin
        XMLReadHelper.Initialize(ExportFileName, GetSEPACTNameSpace());
        FindPaymentHistoryToExport(PaymentHistory, BankAccountNo, ExportProtocolCode);
        PaymentHistoryLine.SetCurrentKey(Date, "Sequence Type");
        PaymentHistoryLine.SetRange("Our Bank", PaymentHistory."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", PaymentHistory."Run No.");
        PaymentHistoryLine.FindSet();
        repeat
            i += 1;
            PaymentHistoryLine.SetRange(Date, PaymentHistoryLine.Date);
            PaymentHistoryLine.CalcSums(Amount);
            XMLReadHelper.VerifyNodeCountWithValueByXPath(
              StrSubstNo('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf[%1]/ns:NbOfTxs', Format(i)), Format(PaymentHistoryLine.Count), 1);
            XMLReadHelper.VerifyNodeCountWithValueByXPath(
              StrSubstNo('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf[%1]/ns:CtrlSum', Format(i)),
              Format(Abs(PaymentHistoryLine.Amount), 0, '<Precision,2:2><Standard Format,9>'), 1);
            PaymentHistoryLine.FindLast();
            PaymentHistoryLine.SetRange(Date);
        until PaymentHistoryLine.Next() = 0;
    end;

    local procedure VerifyEntryExist(VendorNo: Code[20])
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Vendor);
        ProposalLine.SetRange("Account No.", VendorNo);
        Assert.IsFalse(ProposalLine.IsEmpty, ProposalEntryNotExistErr);
    end;

    local procedure VerifyBeginningOfXMLFile(FileName: Text; CheckString: Text[5])
    var
        InStream: InStream;
        File: File;
        ReadText: Text[5];
    begin
        File.Open(FileName);
        File.CreateInStream(InStream);
        InStream.Read(ReadText, 5);
        File.Close();
        Assert.AreEqual(CheckString, ReadText, WrongSymbolFoundErr);
    end;

    local procedure VerifyStandardEuroSEPAFields(Address: Text; CreditorIBAN: Text)
    begin
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:AdrLine', Address);
        VerifyServiceLevelCode('SEPA');
        VerifyChargeBearerValue('SLEV');
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:CdtrAcct/ns:Id/ns:IBAN', CreditorIBAN);
    end;

    local procedure VerifyGenericPaymentSEPAFields(CreditorBankNo: Text)
    begin
        XMLReadHelper.VerifyNodeCountByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Cdtr/ns:PstlAdr/ns:AdrLine', 0);
        VerifyServiceLevelCode('SDVA');
        VerifyChargeBearerValue('SHAR');
        XMLReadHelper.VerifyNodeValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:CdtrAcct/ns:Id/ns:Othr/ns:Id', CreditorBankNo);
    end;

    local procedure VerifyServiceLevelCode(ExpectedValue: Text)
    begin
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:SvcLvl/ns:Cd', ExpectedValue);
    end;

    local procedure VerifyChargeBearerValue(ExpectedValue: Text)
    begin
        XMLReadHelper.VerifyNodeValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:ChrgBr', ExpectedValue);
    end;

    local procedure VerifyTransactionAmountWithCurrency(ExpectedAmount: Decimal; ExpectedCurrency: Text)
    var
        NodePath: Text;
    begin
        NodePath := '//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:CdtTrfTxInf/ns:Amt/ns:InstdAmt';
        XMLReadHelper.VerifyNodeValueByXPath(NodePath, FormatCtrlSumValue(ExpectedAmount));
        XMLReadHelper.VerifyAttributeValue(NodePath, 'Ccy', ExpectedCurrency);
    end;

    local procedure VerifyGrouping()
    begin
        // Grouping: NORM-Date1;NORM-Date2;HIGH-Date1
        XMLReadHelper.VerifyNodeCountWithValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:InstrPrty', 'NORM', 2);
        XMLReadHelper.VerifyNodeCountWithValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:PmtTpInf/ns:InstrPrty', 'HIGH', 1);
        XMLReadHelper.VerifyNodeCountWithValueByXPath('//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:ReqdExctnDt', Format(Today, 0, 9), 1);
        XMLReadHelper.VerifyNodeCountWithValueByXPath(
          '//ns:Document/ns:CstmrCdtTrfInitn/ns:PmtInf/ns:ReqdExctnDt', Format(Today + 1, 0, 9), 2);
    end;

    local procedure VerifyStandardEuroXML(VendorBankAccount: Record "Vendor Bank Account"; FileName: Text; TotalAmount: Decimal; BankAccCurrency: Code[10])
    begin
        VerifySEPACreditTransferFile(FileName, TotalAmount, VendorBankAccount, TRUE, 1, BankAccCurrency);
        VerifyStandardEuroSEPAFields('.' + COPYSTR(VendorBankAccount."Account Holder Address", 2), FormatIBAN(VendorBankAccount.IBAN));
        VerifySEPACreditTransferFileCtrlSumInstdAmtRound(FileName, TotalAmount, GetEuroCurrencyCode());
    end;

    local procedure VerifyGenericPaymentXML(VendorBankAccount: Record "Vendor Bank Account"; FileName: Text; TotalAmount: Decimal; PmtCurrencyCode: Code[10]; BankAccCurrency: Code[10])
    begin
        VerifySEPACreditTransferFile(FileName, TotalAmount, VendorBankAccount, TRUE, 1, BankAccCurrency);
        VerifyGenericPaymentSEPAFields(VendorBankAccount."Bank Account No.");
        VerifySEPACreditTransferFileCtrlSumInstdAmtRound(FileName, TotalAmount, PmtCurrencyCode);
    end;

    local procedure VerifyPmtHistoryLineCurrencyCode(BankAccountNo: Code[20]; CurrencyCode: Code[10])
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistoryLine.SetRange("Our Bank", BankAccountNo);
        PaymentHistoryLine.FindFirst();
        PaymentHistoryLine.TestField("Currency Code", CurrencyCode);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ProposalLineConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ProposalProcessedMsgHandler(Msg: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithEnqueueMessage(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    local procedure VerifyPaymentHistoryCardExportErrorFactBox(PaymentHistory: Record "Payment History")
    var
        PaymentHistoryLine: Record "Payment History Line";
        PaymentHistoryCard: TestPage "Payment History Card";
    begin
        PaymentHistoryLine.SetRange("Our Bank", PaymentHistory."Our Bank");
        PaymentHistoryLine.SetRange("Run No.", PaymentHistory."Run No.");
        PaymentHistoryLine.FindFirst();

        PaymentHistoryCard.OpenView();
        PaymentHistoryCard.GotoRecord(PaymentHistory);
        PaymentHistoryCard."Payment File Errors"."Error Text".AssertEquals(
          StrSubstNo(BlankIBANErr, PaymentHistoryLine.Bank));
        PaymentHistoryCard.Close();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SEPAExportReqPageHandler(var SEPAISO20022Pain010103: TestRequestPage "SEPA ISO20022 Pain 01.01.03")
    begin
        SEPAISO20022Pain010103.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BTL91ExportRequestPageHandler(var ExportBTL91ABNAMRO: TestRequestPage "Export BTL91-ABN AMRO")
    begin
        ExportBTL91ABNAMRO."Payment History".SetFilter("Run No.", LibraryVariableStorage.DequeueText());
        ExportBTL91ABNAMRO.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEPA CT-Fill Export Buffer", 'OnFillExportBufferOnBeforeValidateNormalSEPAInstructionPriority', '', false, false)]
    local procedure OnFillExportBufferOnBeforeValidateNormalSEPAInstructionPriority(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}

