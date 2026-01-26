codeunit 147554 "SII Collection In Cash"
{
    // // [FEATURE] [SII] [Collection In Cash] [Sales]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySII: Codeunit "Library - SII";
        IsInitialized: Boolean;
        SIINotEnabledToSendCollInCashErr: Label 'The SII setup is not enabled to send collections in cash. Specify end points in the SII Setup window and import the certificate.';
        UploadType: Option Regular,Intracommunity,RetryAccepted,"Collection In Cash";
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathCollInCashBasicTok: Label '//soapenv:Body/siiLR:SuministroLRCobrosMetalico/', Locked = true;
        XPathCollInCashTok: Label '//soapenv:Body/siiLR:SuministroLRCobrosMetalico/siiLR:RegistroLRCobrosMetalico/', Locked = true;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure NotPossibleToGenerateCollectionsInCashWhenSIIIsDisabled()
    var
        EntryAmount: Decimal;
        CustNo: Code[20];
        GLAccNo: Code[20];
    begin
        // [FEATURE] [UT] [Generate Collections In Cash]
        // [SCENARIO 251866] Stan cannot generate collections in cash when SII is disabled in SII Setup.

        Initialize(false);

        // [GIVEN] SII Setup is not enabled
        // [GIVEN] Post Payment applied to Sales Invoice
        CreateAndPostPmtAppliedToSalesInvWithVATPostingSetupAndAmount(CustNo, GLAccNo, EntryAmount);

        asserterror RunGenerateCollectionsInCash(GLAccNo, EntryAmount - 1);
        Assert.ExpectedError(SIINotEnabledToSendCollInCashErr);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SIIHistoryGeneratedWhenSIICollInCashEnabledAndPmtAmountExceedMinAmount()
    var
        EntryAmount: Decimal;
        CustNo: Code[20];
        GLAccNo: Code[20];
    begin
        // [FEATURE] [UT] [Generate Collections In Cash]
        // [SCENARIO 251866] SII History entry generates when payment amount not exceeds the "Minimum Amount" on the request page of the "Generate Collections In Cash" report

        Initialize(true);

        // [GIVEN] SII Setup is enabled
        // [GIVEN] Post Payment applied to Sales Invoice with Amount = 150 for cash G/L Account "X"
        CreateAndPostPmtAppliedToSalesInvWithVATPostingSetupAndAmount(CustNo, GLAccNo, EntryAmount);

        // [WHEN] Run "Generate Collections In Cash" with cash G/L Account = "X", "Minimum Amount Cash" = 100
        RunGenerateCollectionsInCash(GLAccNo, EntryAmount - 1);

        // [THEN] SII Doc. Upload State for Collection In Cash is created with "Total Amount In Cash" = 150
        // [THEN] SII History for Collection In Cash is created
        VerifySIIDocUploadStateAndHistory(DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), CustNo, EntryAmount, false);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoNewSIIHistoryGeneratedWhenSIICollInCashSentSecondTimeWithSameAmount()
    var
        EntryAmount: Decimal;
        CustNo: Code[20];
        GLAccNo: Code[20];
    begin
        // [FEATURE] [UT] [Generate Collections In Cash]
        // [SCENARIO 251866] No new SII History entry generates when SII Collection In Cash sent through "Generate Collections In Cash" report second time with same amount

        Initialize(true);

        // [GIVEN] SII Setup is enabled
        // [GIVEN] Post Payment applied to Sales Invoice with Amount = 150 for cash G/L Account "X"
        CreateAndPostPmtAppliedToSalesInvWithVATPostingSetupAndAmount(CustNo, GLAccNo, EntryAmount);

        // [GIVEN] "Generate Collections In Cash" report ran with cash G/L Account = "X", "Minimum Amount Cash" = 100. New SII History Entry created
        RunGenerateCollectionsInCash(GLAccNo, EntryAmount - 1);

        // [WHEN] Run "Generate Collections In Cash" with same parameters
        RunGenerateCollectionsInCash(GLAccNo, EntryAmount - 1);

        // [THEN] SII Doc. Upload State for Collection In Cash is created with "Total Amount In Cash" = 150
        // [THEN] SII History for Collection In Cash is created
        VerifySIIDocUploadStateAndHistory(DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), CustNo, EntryAmount, false);

        // [THEN] SII Doc. Upload State has one record with Collection In Cash
        // [THEN] SII History has one records with Collection In Cash
        VerifySIIDocUploadStateAndHistoryCount(1, 1);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NewSIIHistoryCreatedWhenSIICollInCashSentSecondTimeWithNewAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        EntryAmount: array[2] of Decimal;
        CustNo: Code[20];
        GLAccNo: Code[20];
    begin
        // [FEATURE] [UT] [Generate Collections In Cash]
        // [SCENARIO 251866] New SII History entry creates when SII Collection In Cash sent through "Generate Collections In Cash" report second time with new amount

        Initialize(true);

        // [GIVEN] SII Setup is enabled
        // [GIVEN] Post Payment applied to Sales Invoice with Amount = 150 for cash G/L Account "X"
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, false, false);
        CreateAndPostPmtAppliedToSalesInvWithAmount(CustNo, GLAccNo, EntryAmount[1], VATPostingSetup);

        // [GIVEN] "Generate Collections In Cash" report ran with cash G/L Account = "X", "Minimum Amount Cash" = 100". New SII History Entry created
        RunGenerateCollectionsInCash(GLAccNo, EntryAmount[1] - 1);

        // [GIVEN] Post Payment applied to Sales Invoice with Amount = 200 for cash G/L Account "X"
        PostPmtAppliedToSalesInvWithAmount(EntryAmount[2], CustNo, GLAccNo, VATPostingSetup);

        // [WHEN] Run "Generate Collections In Cash" with same parameters
        RunGenerateCollectionsInCash(GLAccNo, EntryAmount[1] - 1);

        // [THEN] SII Doc. Upload State for Collection In Cash is created with "Total Amount In Cash" = 350 (first payment and second payment amount)
        // [THEN] SII History for Collection In Cash is created
        VerifySIIDocUploadStateAndHistory(DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), CustNo, EntryAmount[1] + EntryAmount[2], false);

        // [THEN] SII Doc. Upload State has one record with Collection In Cash
        // [THEN] SII History has two records with Collection In Cash
        VerifySIIDocUploadStateAndHistoryCount(1, 2);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SIIHistoryRetryAcceptedWhenSIICollInCashSentSecondTimeWithNewAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        EntryAmount: array[2] of Decimal;
        CustNo: Code[20];
        GLAccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [UT] [Generate Collections In Cash]
        // [SCENARIO 251866] SII History entry updates with "Retry Accepted" option when SII Collection In Cash sent through "Generate Collections In Cash" report second time with new amount and accepted SII Doc. Upload State

        Initialize(true);

        // [GIVEN] SII Setup is enabled
        // [GIVEN] Post Payment applied to Sales Invoice with Amount = 150 for cash G/L Account "X"
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, false, false);
        CreateAndPostPmtAppliedToSalesInvWithAmount(CustNo, GLAccNo, EntryAmount[1], VATPostingSetup);

        // [GIVEN] "Generate Collections In Cash" report ran with cash G/L Account = "X", "Minimum Amount Cash" = 100. New SII History Entry created
        RunGenerateCollectionsInCash(GLAccNo, EntryAmount[1] - 1);

        // [GIVEN] Post Payment applied to Sales Invoice with Amount = 200 for cash G/L Account "X"
        PostPmtAppliedToSalesInvWithAmount(EntryAmount[2], CustNo, GLAccNo, VATPostingSetup);

        // [GIVEN] SII Doc. Upload State and SII History have state "Accepted"
        PostingDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        UpdateStateAcceptedOfSIIDocUploadStateAndHistory(PostingDate, CustNo);
        Commit();

        // [WHEN] Run "Generate Collections In Cash" with same parameters
        RunGenerateCollectionsInCash(GLAccNo, EntryAmount[1] - 1);

        // [THEN] SII Doc. Upload State for Collection In Cash is created with "Total Amount In Cash" = 150 and "Retry Accepted"
        // [THEN] SII History for Collection In Cash is created with "Retry Accepted"
        VerifySIIDocUploadStateAndHistory(PostingDate, CustNo, EntryAmount[1] + EntryAmount[2], true);

        // [THEN] SII Doc. Upload State has one record with Collection In Cash
        // [THEN] SII History has one record with Collection In Cash
        VerifySIIDocUploadStateAndHistoryCount(1, 2);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeCustomerDataForCollectionInCashSent()
    var
        CountryRegion: Record "Country/Region";
        Customer: Record Customer;
        SIIHistory: Record "SII History";
        SIIDocUploadState: Record "SII Doc. Upload State";
        EntryAmount: Decimal;
        CustNo: Code[20];
        GLAccNo: Code[20];
    begin
        // [FEATURE] [UT] [Generate Collections In Cash]
        // [SCENARIO 251866] Customer Data updates in SII Doc. Upload State when existing SII History retries to send

        Initialize(true);

        // [GIVEN] SII Setup is enabled
        // [GIVEN] Post Payment applied to Sales Invoice with Customer (Name = "Barcelona", "VAT Registration No." = "Y", "Country/Region Code" = "ES")
        CreateAndPostPmtAppliedToSalesInvWithVATPostingSetupAndAmount(CustNo, GLAccNo, EntryAmount);

        // [GIVEN] Collections In Cash generated
        RunGenerateCollectionsInCash(GLAccNo, EntryAmount - 1);

        // [GIVEN] SII Doc. Upload State with Customer Data and SII History for Collection In Cash
        GetSIIDocUploadState(SIIDocUploadState, DMY2Date(1, 1, Date2DMY(WorkDate(), 3)), CustNo);
        GetSIIHistory(SIIHistory, SIIDocUploadState.Id);

        // [GIVEN] Changed customer's name to "PSG", "VAT Registration No." to "Z", "Country/Region Code" = "FR"
        Customer.Get(CustNo);
        Customer.Name := LibraryUtility.GenerateGUID();
        Customer."VAT Registration No." := LibraryUtility.GenerateGUID();
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();

        // [WHEN] Send new request for Collection In Cash
        SIIHistory.CreateNewRequest(SIIDocUploadState.Id, SIIHistory."Upload Type", 1, true, false);

        // [THEN] SII Doc. Upload State has "CV Name" = "PSG", "VAT Registration No." = "Z", "Country/Region Code" = "FR"
        SIIDocUploadState.Find();
        SIIDocUploadState.TestField("CV Name", Customer.Name);
        SIIDocUploadState.TestField("VAT Registration No.", Customer."VAT Registration No.");
        SIIDocUploadState.TestField("Country/Region Code", Customer."Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegularCollectionInCashXML()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        PostingDate: Date;
        TotalAmountInCash: Decimal;
    begin
        // [FEATURE] [UT] [XML]
        // [SCENARIO 221621] The structure of XML file of Collection In Cash is correct

        Initialize(false);

        // [GIVEN] Collection in cash
        PostingDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        Library340347Declaration.CreateCustomer(Customer, '');
        TotalAmountInCash := LibraryRandom.RandDec(100, 2);
        MockCustLedgEntryWithCollectionInCash(CustLedgerEntry, PostingDate, Customer."No.", TotalAmountInCash);

        // [WHEN] Create xml for Collection in cash
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::"Collection In Cash", false), IncorrectXMLDocErr);

        // [THEN] XML file has correct structure for Collection In Cash entry. TipoComunicacion is 'A0'
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashBasicTok, 'sii:Cabecera/sii:TipoComunicacion', 'A0');
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'sii:PeriodoLiquidacion/sii:Ejercicio', Format(Date2DMY(WorkDate(), 3)));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'sii:PeriodoLiquidacion/sii:Periodo', '0A');
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'siiLR:Contraparte/sii:NombreRazon', Customer.Name);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'siiLR:Contraparte/sii:NIF', Customer."VAT Registration No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'siiLR:ImporteTotal', SIIXMLCreator.FormatNumber(TotalAmountInCash));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RetryAcceptedCollectionInCashXML()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        PostingDate: Date;
        TotalAmountInCash: Decimal;
    begin
        // [FEATURE] [UT] [XML]
        // [SCENARIO 221621] The structure of XML file of Collection In Cash which is send second time is correct

        Initialize(false);

        // [GIVEN] Collection in cash
        PostingDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        Library340347Declaration.CreateCustomer(Customer, '');
        TotalAmountInCash := LibraryRandom.RandDec(100, 2);
        MockCustLedgEntryWithCollectionInCash(CustLedgerEntry, PostingDate, Customer."No.", TotalAmountInCash);

        // [GIVEN] Set "Retry Accepted" for collection in cash
        SIIXMLCreator.SetIsRetryAccepted(true);

        // [WHEN] Create xml for Collection in cash
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::"Collection In Cash", false), IncorrectXMLDocErr);

        // [THEN] XML file has correct structure for Collection In Cash entry. TipoComunicacion is 'A1'
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashBasicTok, 'sii:Cabecera/sii:TipoComunicacion', 'A1');
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'sii:PeriodoLiquidacion/sii:Ejercicio', Format(Date2DMY(WorkDate(), 3)));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'sii:PeriodoLiquidacion/sii:Periodo', '0A');
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'siiLR:Contraparte/sii:NombreRazon', Customer.Name);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'siiLR:Contraparte/sii:NIF', Customer."VAT Registration No.");
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathCollInCashTok, 'siiLR:ImporteTotal', SIIXMLCreator.FormatNumber(TotalAmountInCash));
    end;

    local procedure Initialize(EnableSII: Boolean)
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        SIIDocUploadState.DeleteAll();
        SIIHistory.DeleteAll();
        LibrarySII.InitSetup(EnableSII, false);
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibrarySII.BindSubscriptionJobQueue();
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateAndPostPaymentJnlLineWithGLAcc(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PostingDate: Date; PmtAmount: Decimal; BalGLAccNo: Code[20]; ApplToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          AccountType,
          AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account",
          BalGLAccNo,
          PmtAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", ApplToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPmtAppliedToSalesInvWithVATPostingSetupAndAmount(var CustNo: Code[20]; var GLAccNo: Code[20]; var EntryAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, false, false);
        CreateAndPostPmtAppliedToSalesInvWithAmount(CustNo, GLAccNo, EntryAmount, VATPostingSetup);
    end;

    local procedure CreateAndPostPmtAppliedToSalesInvWithAmount(var CustNo: Code[20]; var GLAccNo: Code[20]; var EntryAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup")
    var
        Customer: Record Customer;
    begin
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        CustNo := Customer."No.";
        GLAccNo := LibraryERM.CreateGLAccountNo();
        PostPmtAppliedToSalesInvWithAmount(EntryAmount, CustNo, GLAccNo, VATPostingSetup);
    end;

    local procedure PostPmtAppliedToSalesInvWithAmount(var EntryAmount: Decimal; CustNo: Code[20]; GLAccNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustNo, WorkDate(), EntryAmount));
        CustLedgerEntry.CalcFields("Amount (LCY)");
        EntryAmount := CustLedgerEntry."Amount (LCY)";
        CreateAndPostPaymentJnlLineWithGLAcc(
          GenJournalLine."Account Type"::Customer, CustNo, WorkDate(), -EntryAmount, GLAccNo, GetSalesInvoiceNo(CustNo));
    end;

    local procedure MockCustLedgEntryWithCollectionInCash(var CustLedgerEntry: Record "Cust. Ledger Entry"; PostingDate: Date; CustNo: Code[20]; TotalAmount: Decimal)
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."VAT Reporting Date" := PostingDate;
        CustLedgerEntry."Customer No." := CustNo;
        CustLedgerEntry."Sales (LCY)" := TotalAmount;
        CustLedgerEntry.Insert();
    end;

    local procedure GetSalesInvoiceNo(CustomerNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", CustomerNo);
        SalesInvoiceHeader.FindLast();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure RunGenerateCollectionsInCash(CashGLAccNo: Code[20]; MinAmountCash: Decimal)
    var
        Make347Declaration: Report "Make 347 Declaration";
    begin
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 3));
        LibraryVariableStorage.Enqueue(MinAmountCash);
        LibraryVariableStorage.Enqueue(CashGLAccNo);
        Make347Declaration.SetCollectionInCashMode(true);
        Make347Declaration.RunModal();
    end;

    local procedure GetSIIDocUploadState(var SIIDocUploadState: Record "SII Doc. Upload State"; PostingDate: Date; CustomerNo: Code[20])
    begin
        SIIDocUploadState.SetRange("Transaction Type", SIIDocUploadState."Transaction Type"::"Collection In Cash");
        SIIDocUploadState.SetRange("Posting Date", PostingDate);
        SIIDocUploadState.SetRange("CV No.", CustomerNo);
        SIIDocUploadState.FindFirst();
    end;

    local procedure GetSIIHistory(var SIIHistory: Record "SII History"; DocUploadStateID: Integer)
    begin
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::"Collection In Cash");
        SIIHistory.SetRange("Document State Id", DocUploadStateID);
        SIIHistory.FindLast(); // there could be multiple entries and "Retry Accepted" will be in the last one
    end;

    local procedure UpdateStateAcceptedOfSIIDocUploadStateAndHistory(PostingDate: Date; CustomerNo: Code[20])
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        GetSIIDocUploadState(SIIDocUploadState, PostingDate, CustomerNo);
        SIIDocUploadState.Validate(Status, SIIDocUploadState.Status::Accepted);
        SIIDocUploadState.Modify(true);
        GetSIIHistory(SIIHistory, SIIDocUploadState.Id);
        SIIHistory.Validate(Status, SIIHistory.Status::Accepted);
        SIIHistory.Modify(true);
    end;

    local procedure VerifySIIDocUploadStateAndHistory(PostingDate: Date; CustomerNo: Code[20]; TotalCashAmount: Decimal; RetryAccepted: Boolean)
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        GetSIIDocUploadState(SIIDocUploadState, PostingDate, CustomerNo);
        SIIDocUploadState.TestField("Total Amount In Cash", TotalCashAmount);
        SIIDocUploadState.TestField("Retry Accepted", RetryAccepted);
        GetSIIHistory(SIIHistory, SIIDocUploadState.Id);
        SIIHistory.TestField("Retry Accepted", RetryAccepted);
    end;

    local procedure VerifySIIDocUploadStateAndHistoryCount(ExpectedDocUploadStateCount: Integer; ExpectedSIIHistoryCount: Integer)
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        SIIDocUploadState.SetRange("Transaction Type", SIIDocUploadState."Transaction Type"::"Collection In Cash");
        Assert.RecordCount(SIIDocUploadState, ExpectedDocUploadStateCount);
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::"Collection In Cash");
        Assert.RecordCount(SIIHistory, ExpectedSIIHistoryCount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make347DeclarationReportHandler(var Make347Declaration: TestRequestPage "Make 347 Declaration")
    var
        FiscalYear: Variant;
        MinAmountInCash: Variant;
        GLAccForPaymentsInCash: Variant;
    begin
        LibraryVariableStorage.Dequeue(FiscalYear);
        LibraryVariableStorage.Dequeue(MinAmountInCash);
        LibraryVariableStorage.Dequeue(GLAccForPaymentsInCash);
        Make347Declaration.FiscalYear.SetValue(FiscalYear);
        Make347Declaration.MinAmountInCash.SetValue(MinAmountInCash);
        Make347Declaration.GLAccForPaymentsInCash.SetValue(GLAccForPaymentsInCash);
        Make347Declaration.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

