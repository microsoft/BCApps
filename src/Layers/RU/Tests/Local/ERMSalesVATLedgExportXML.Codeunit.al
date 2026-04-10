codeunit 147142 "ERM Sales VAT Ledg. Export XML"
{
    // // [FEATURE] [VAT Ledger] [Sales] [Export XML]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRUReports: Codeunit "Library RU Reports";
        LocalReportMgt: Codeunit "Local Report Management";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        IsInitialized: Boolean;
        DocType: Option " ",Revision,Correction,RevOfCorrection;
        CustomerType: Option Person,Company;
        CompanyType: Option Person,Organization;
        DocumentTxt: Label 'Document';
        IndexTxt: Label 'Index';
        PriznSvedTxt: Label 'PriznSved';
        NomCorrTxt: Label 'NomCorr';
        FileTxt: Label 'File';
        FileIDTxt: Label 'FileID';
        VersProgTxt: Label 'VersProg';
        VersFormTxt: Label 'VersForm';
        SvProdTxt: Label 'SvProd', Locked = true;
        SvPokupTxt: Label 'SvPokup', Locked = true;
        SvedULTxt: Label 'SvedUL';
        SvedIPTxt: Label 'SvedIP';
        INNULTxt: Label 'INNUL', Locked = true;
        INNFLTxt: Label 'INNFL', Locked = true;
        KPPTxt: Label 'KPP', Locked = true;
        KnigaProdTxt: Label 'KnigaProd';
        KnigaProdDLTxt: Label 'KnigaProdDL';
        KnProdDLStrTxt: Label 'KnProdDLStr';
        KnProdStrTxt: Label 'KnProdStr';
        ItStProdKPrTxt: Label 'ItStProdKPr';
        SumNDSItKPrTxt: Label 'SumNDSItKPr';
        ItStProdOsvKPrTxt: Label 'ItStProdOsvKPr';
        StProdVsP1R9Txt: Label 'StProdVsP1R9';
        SumNDSVsP1R9Txt: Label 'SumNDSVsP1R9';
        StProdOsvP1R9VsTxt: Label 'StProdOsvP1R9Vs';
        StProdBezNDSTxt: Label 'StProdBezNDS';
        SumNDSVsKPrTxt: Label 'SumNDSVsKPr';
        StProdOsvVsKPrTxt: Label 'StProdOsvVsKPr';
        NomerPorTxt: Label 'NomerPor';
        NomScFProdTxt: Label 'NomScFProd';
        DataScFProdTxt: Label 'DataScFProd';
        NomIsprScFTxt: Label 'NomIsprScF';
        DataIsprScFTxt: Label 'DataIsprScF';
        NomKScFProdTxt: Label 'NomKScFProd';
        DataKScFProdTxt: Label 'DataKScFProd';
        NomIsprKScFTxt: Label 'NomIsprKScF';
        DataIsprKScFTxt: Label 'DataIsprKScF';
        OKVTxt: Label 'OKV';
        StoimProdSFVTxt: Label 'StoimProdSFV';
        StoimProdSFTxt: Label 'StoimProdSF';
        SumNDSSFTxt: Label 'SumNDSSF';
        KodVidOperTxt: Label 'KodVidOper';
        DocPdtvOplTxt: Label 'DocPdtvOpl';
        NomDocPdtvOplTxt: Label 'NomDocPdtvOpl';
        DataDocPdtvOplTxt: Label 'DataDocPdtvOpl';
        KodVidTovarTxt: Label 'KodVidTovar';

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic18()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.1] Verify report data when sales invoice is posted with VAT=18%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo('', '');
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted sales invoice with customer with VAT 18%
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2018, false, CustomerType::Company);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.9_AAAA_KKKK_"X"_20160401_N.xml" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        // [THEN] XML contains node "SvPokup" (TFSID 381008)
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic20()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Verify report data when sales invoice is posted with VAT=20%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo('', '');
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted sales invoice with customer with VAT 20%
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019, false, CustomerType::Company);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.9_AAAA_KKKK_"X"_20160401_N.xml" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        // [THEN] XML contains node "SvPokup" (TFSID 381008)
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic10()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.2] Verify report data when sales invoice is posted with VAT=10%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '1234', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo(Format(LibraryRandom.RandIntInRange(1000, 9999)), '');
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted sales invoice with customer with VAT 10%
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', 10, false, CustomerType::Company);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.9_1234_KKKK_"X"_20160401_N.xml" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic18_10_0()
    var
        CustomerNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.3] Verify report data when sales invoice is posted with multiple sales lines with VAT respectively set to 18%, 10% and 0%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = '5678'
        UpdateCompanySONOInfo('', Format(LibraryRandom.RandIntInRange(1000, 9999)));
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted sales invoice with customer with 3 lines VAT 18%, 10% and 0%
        InvNo := CreateAndPostSalesInvoiceMultiLines(CustomerNo, '', CustomerType::Company, VATLedgerMgt.GetVATPctRate2018);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(CustomerNo, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.9_AAAA_5678_"X"_20160401_N.xml" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic20_10_0()
    var
        CustomerNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Verify report data when sales invoice is posted with multiple sales lines with VAT respectively set to 20%, 10% and 0%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = '5678'
        UpdateCompanySONOInfo('', Format(LibraryRandom.RandIntInRange(1000, 9999)));
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted sales invoice with customer with 3 lines VAT 20%, 10% and 0%
        InvNo := CreateAndPostSalesInvoiceMultiLines(CustomerNo, '', CustomerType::Company, VATLedgerMgt.GetVATPctRate2019);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(CustomerNo, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.9_AAAA_5678_"X"_20160401_N.xml" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic18FCY()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.4] Verify report data when sales invoice is posted in FCY
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '1234', "Recipient Tax Authority SONO" = '5678'
        UpdateCompanySONOInfo(Format(LibraryRandom.RandIntInRange(1000, 9999)), Format(LibraryRandom.RandIntInRange(1000, 9999)));
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Create and post sales invoice for a customer with FCY currency
        InvNo := CreateAndPostSalesInvoice(SalesHeader, CreateCurrency(false), VATLedgerMgt.GetVATPctRate2018, false, CustomerType::Company);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.9_1234_5678_"X"_20160401_N.xml" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema // XML contains the Sale amount incl. VAT values in FCY created
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportBasic18FCYConventional()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.5] Verify report data when sales invoice is posted in Conventional Currency
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Create and post sales invoice for a customer with conventional currency
        // [GIVEN] where "Amount Including VAT (LCY)" = "A", "Amount (LCY)" = "B".
        InvNo := CreateAndPostSalesInvoice(SalesHeader, CreateCurrency(true), VATLedgerMgt.GetVATPctRate2018, false, CustomerType::Company);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains the Sale amount incl. VAT values in Conventional FCY created
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportAdvance()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GenJnlLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO TFS=124828.6] Verify report data when advance payment (prepayment) is posted
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Posted advance payment
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019);
        CustomerNo := CreateCustomer(VATPostingSetup, CustomerType::Company);
        LibraryRUReports.UpdateCustomerPrepmtAccountVATRate(CustomerNo, VATLedgerMgt.GetVATPctRate2019);

        DocNo := CreateAndReleaseSalesInvoice(VATPostingSetup, CustomerNo, '');
        CreatePrepaymentJournalLine(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustomerNo, DocNo, -LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(CustomerNo, false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains information about PaymentDocument
        // [THEN] "StProdBezNDS18" XML element is absence (TFS 379280)
        SalesInvoiceHeader.SetRange("Order No.", DocNo);
        SalesInvoiceHeader.FindFirst();

        VerifyVATLedgExportXML(SalesInvoiceHeader."No.", 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportAdvancePostInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GenJnlLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 379308] Verify report data after post Sales Invoice when advance payment (prepayment) is posted
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Released Sales Invoice (VAT Base = "A")
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019);
        CustomerNo := CreateCustomer(VATPostingSetup, CustomerType::Company);
        LibraryRUReports.UpdateCustomerPrepmtAccountVATRate(CustomerNo, VATLedgerMgt.GetVATPctRate2019);

        SalesHeader.Get(
          SalesHeader."Document Type"::Invoice,
          CreateAndReleaseSalesInvoice(VATPostingSetup, CustomerNo, ''));
        // [GIVEN] Posted advance payment
        CreatePrepaymentJournalLine(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustomerNo, SalesHeader."No.", -LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        // [GIVEN] Post Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(CustomerNo, false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains information about PaymentDocument
        // [THEN] "StProdBezNDS18" XML element value  = "A" (TFS 379308)
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();
        VerifyVATLedgExportXML(SalesInvoiceHeader."No.", 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,PHVATSalesLedgerCard,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportAddSheet()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        VATRate: Decimal;
    begin
        // [SCENARIO TFS=124829.7] Verify VAT Additional Sheet report when sales invoice with VAT = 20% is posted where Aditional Sheet is report in different accounting period
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '1234', "Recipient Tax Authority SONO" = '5678'
        UpdateCompanySONOInfo(Format(LibraryRandom.RandIntInRange(1000, 9999)), Format(LibraryRandom.RandIntInRange(1000, 9999)));

        VATRate := VATLedgerMgt.GetVATPctRate2019;
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1000, 2)); // Total Base 20
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1000, 2)); // Total Base 18
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1000, 2)); // Total Base 10
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1000, 2)); // Total Base 0
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1000, 2)); // Total Amount 20
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1000, 2)); // Total Amount 18
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1000, 2)); // Total Amount 10
        LibraryVariableStorage.Enqueue(LibraryRandom.RandDec(1000, 2)); // Total Amount 0

        // [GIVEN] Posted sales invoice with new customer with VAT 20%
        // [GIVEN] AddSheet = TRUE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(true, 0, false);

        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATRate, true, CustomerType::Company);

        // [WHEN] Sales Additional Sheet VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", true);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.91_1234_5678_"X".xml" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains VAT amounts from other reporting periods in the specific Total values
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, true, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportCorrection()
    var
        CorSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        CorrectionNo: Integer;
    begin
        // [SCENARIO TFS=124828.8] Verify VAT Export report when corrective sales invoice is posted
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo <> 0, IsPrevDataRelevant = FALSE
        CorrectionNo := LibraryRandom.RandIntInRange(1, 999);
        EnqueueReportParameters(false, CorrectionNo, false);

        // [GIVEN] posted corrective sales invoice
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019, false, CustomerType::Company);
        CreatePostCorrSalesInvoice(CorSalesHeader, SalesHeader, InvNo);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(CorSalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains two Sale Ledger Lines related to the original invoice and correction of the original invoice
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, CorrectionNo, false);
        VerifyVATLedgExportXML(InvNo, 2, DocType::Correction, CustomerType::Company, false, CorrectionNo, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportRevision()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RevSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        RevInvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.9] Verify VAT Export report when revision sales invoice is posted
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] posted revision sales invoice
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019, false, CustomerType::Company);
        RevInvNo := CreatePostRevisionSalesInvoice(RevSalesHeader, SalesHeader, InvNo);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains two Sale Ledger Lines related to the original invoice and the revision of the original invoice
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
        SalesInvoiceHeader.Get(RevInvNo);
        VerifyVATLedgExportXML(SalesInvoiceHeader."Revision No.", 2, DocType::Revision, CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportRevCorr()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        CorSalesHeader: Record "Sales Header";
        RevSalesHeader: Record "Sales Header";
        InvNo: Code[20];
        CorInvNo: Code[20];
        RevInvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.10] Verify VAT Export report when revision sales invoice for correction is posted
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Posted revision sales invoice for correction
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019, false, CustomerType::Company);
        CorInvNo := CreatePostCorrSalesInvoice(CorSalesHeader, SalesHeader, InvNo);
        RevInvNo := CreatePostRevisionSalesInvoice(RevSalesHeader, CorSalesHeader, CorInvNo);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] XML contains Sale Ledger Line related to the original invoice
        // [THEN] XML contains Sale Ledger Line related to the correction of the original invoice
        // [THEN] XML contains Sale Ledger Line related to the revision of the correction of the original invoice
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
        VerifyVATLedgExportXML(InvNo, 2, DocType::Correction, CustomerType::Company, false, 0, false);
        SalesInvoiceHeader.Get(RevInvNo);
        VerifyVATLedgExportXML(
          SalesInvoiceHeader."Revision No.", 3, DocType::RevOfCorrection, CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportActCriteria9IrrelevantChanges()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        CorrectionNo: Integer;
    begin
        // [SCENARIO TFS=124828.11] Verify VAT Export report when document Corrective Submission = TRUE
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo <> 0, IsPrevDataRelevant = FALSE
        CorrectionNo := LibraryRandom.RandIntInRange(1, 999);
        EnqueueReportParameters(false, CorrectionNo, false);

        // [GIVEN] Posted Sales Invoice
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019, false, CustomerType::Company);

        // [GIVEN] User enter Corrective Submission = TRUE
        // [GIVEN] Number of Correction and Last sent report contains 0 - Irrelevant Changes
        // [WHEN] Export VAT Ledger into XML
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] XML has element CorrNo set to Number of correction
        // [THEN] XML has element ActCriteria9 set to 0
        // [THEN] XML contains at least one SaleLedger node
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, CorrectionNo, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportActCriteria9RelevantChanges()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        CorrectionNo: Integer;
    begin
        // [SCENARIO TFS=124829.12] Verify VAT Export report when last sent report contains Relevant Changes and ActCriteria8 set to 1 - Relevant Changes
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo <> 0, IsPrevDataRelevant = TRUE
        CorrectionNo := LibraryRandom.RandIntInRange(1, 999);
        EnqueueReportParameters(false, CorrectionNo, true);

        // [GIVEN] Posted Sales Invoice
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019, false, CustomerType::Company);

        // [GIVEN] User enters Corrective Submission = TRUE
        // [GIVEN] Number of Correction and Last sent report contains 1 - Relevant Changes
        // [WHEN] Export VAT Ledger into XML

        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] XML has element ActCriteria9 set to 1
        // [THEN] XML doesn't contain any SalesLedger nodes
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, CorrectionNo, true);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportCompanyAsPerson()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.66] Verify report data when the NAV user is a person
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted sales invoice with customer with VAT 18%
        LibraryRUReports.UpdateCompanyTypeInfo(CompanyType::Person);
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019, false, CustomerType::Company);

        // [WHEN] Sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] Proposed File Name contains only VAT Reg.No
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportCustomerAsPerson()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.67] Verify report data when the customer of a sales invoice is a person
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted sales invoice with customer with VAT 18%
        // [GIVEN] The customer is a person, not a company
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2019, false, CustomerType::Person);

        // [WHEN] sales VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] The node containing the information about the Customer doesn't have the attribute for the KPP value
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Person, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportCustomerVATRegNo()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
    begin
        // [SCENARIO 378448] Customer XML export without VAT Registration No.
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Sales invoice
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019);
        CustomerNo := CreateCustomer(VATPostingSetup, CustomerType::Company);
        LibraryVariableStorage.Enqueue(CustomerNo);
        Customer.Get(CustomerNo);
        Customer."VAT Registration No." := '';
        Customer.Modify(true);
        CreateSalesHeader(SalesHeader, CustomerNo, '');
        CreateSalesLine(SalesHeader, VATPostingSetup);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Sales VAT Ledger Export XML
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false);

        // [THEN] There is no "SvProd" node in exported file
        InitializeXMLFile(GetFileName(false));
        LibraryXPathXMLReader.VerifyNodeAbsence(
          GetXPathSalesLedger(false) + GetXPathSalesLedgerLine(false) + '[1]/' + SvProdTxt);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportVendorPrpmt()
    var
        PurchaseHeader: Record "Purchase Header";
        CompanyInformation: Record "Company Information";
        VATLedgerLine: Record "VAT Ledger Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Prepayment] [FCY]
        // [SCENARIO 374734] Export Sales VAT Ledger for posted prepayment from foreign non-resident Vendor as VAT Agent
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);
        LibraryRUReports.UpdateCompanyTypeInfo(CompanyType::Organization);

        // [GIVEN] Foreign Non-Resident Vendor as VAT Agent "V"
        // [GIVEN] Released Purchase Invoice "I" from Vendor "V"
        CreatePurchaseInvoiceVendorVATAgent(PurchaseHeader);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        // [GIVEN] Posted Prepayment for the invoice "I" from Vendor "V"
        PostPurchasePrepayment(PurchaseHeader);
        InvoiceNo := FindPostedPurchaseInvoice(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Export Sales VAT Ledger to XML
        RunVATLedgerExportReportXML(PurchaseHeader."Buy-from Vendor No.", false);

        // [THEN] Exported CV "KPP Code" = CompanyInformation."KPP Code"
        // [THEN] Exported CV "VAT Registration No." = CompanyInformation."VAT Registration No."
        InitializeXMLFile(GetFileName(false));
        CompanyInformation.Get();
        VerifyVATRegNoAndKPP_UL(1, CompanyInformation."VAT Registration No.", CompanyInformation."KPP Code", false);
        // [THEN] Exported node "DocPdtvOpl" has following attributes: "NomDocPdtvOpl" = "X", "DataDocPdtvOpl" = "Y" (TFS 378466)
        GetVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."Document Type"::Invoice, InvoiceNo);
        VerifySalesLedger(VATLedgerLine, false);
        VerifySalesLedgerLine(VATLedgerLine, 1, false);
        VerifyPaymentDocument(VATLedgerLine, 1, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesVATLedgerReportVendorPayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        CompanyInformation: Record "Company Information";
        VATLedgerLine: Record "VAT Ledger Line";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchases] [FCY]
        // [SCENARIO 378466] Export Sales VAT Ledger for posted payment from foreign non-resident Vendor as VAT Agent
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);
        LibraryRUReports.UpdateCompanyTypeInfo(CompanyType::Organization);

        // [GIVEN] Foreign Non-Resident Vendor as VAT Agent
        // [GIVEN] Posted Purchase Invoice
        CreatePurchaseInvoiceVendorVATAgent(PurchaseHeader);
        LibraryRUReports.GetVATAgentPostingSetup(VATPostingSetup, PurchaseHeader."Buy-from Vendor No.");
        LibraryRUReports.UpdateVATPostingSetupWithManualVATSettlement(VATPostingSetup);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [GIVEN] Posted Payment with "External Document No." = "X", "Posting Date" = "Y"
        PostPurchasePayment(PurchaseHeader, InvoiceNo);
        InvoiceNo := FindPostedPurchaseInvoice(PurchaseHeader."Buy-from Vendor No.");
        // [GIVEN] Suggest and post VAT Settlement
        LibraryRUReports.SuggestPostManualVATSettlement(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Export Sales VAT Ledger to XML
        RunVATLedgerExportReportXML(PurchaseHeader."Buy-from Vendor No.", false);

        // [THEN] Exported CV "KPP Code" = CompanyInformation."KPP Code"
        // [THEN] Exported CV "VAT Registration No." = CompanyInformation."VAT Registration No."
        InitializeXMLFile(GetFileName(false));
        CompanyInformation.Get();
        VerifyVATRegNoAndKPP_UL(2, CompanyInformation."VAT Registration No.", CompanyInformation."KPP Code", false);
        // [THEN] Exported node "DocPdtvOpl" has following attributes: "NomDocPdtvOpl" = "X", "DataDocPdtvOpl" = "Y" (TFS 378466)
        GetVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."Document Type"::Invoice, InvoiceNo);
        VerifySalesLedger(VATLedgerLine, false);
        VerifySalesLedgerLine(VATLedgerLine, 2, false);
        VerifyPaymentDocument(VATLedgerLine, 2, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesKodVidTovarXmlNodeGeneratesWhenTariffNoSpecified()
    var
        SalesHeader: Record "Sales Header";
        VATLedger: Record "VAT Ledger";
        TariffNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 373650] KodVidTovar xml node generates when "Tariff No." is specified in sales VAT ledger line

        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo('', '');

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted sales invoice with customer with VAT 18%
        InvNo := CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2018(), false, CustomerType::Company);
        TariffNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create VAT Ledger with Tariff No. assigned to the line
        CreateVATLedger(VATLedger, SalesHeader."Sell-to Customer No.", false);
        UpdateTariffNoToVATLedgerLine(VATLedger, TariffNo);
        Commit();

        // [WHEN] Export sales VAT Ledger to XML
        RunVATLedgerExportXML(VATLedger, false);

        // [THEN] KodVidTovar xml node does exist in the XML file
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", CustomerType::Company, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHSalesVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure SalesKodVidTovarXmlNodeDoesNotGenerateWhenTariffNoNotSpecified()
    var
        SalesHeader: Record "Sales Header";
        VATLedger: Record "VAT Ledger";
        TariffNo: Code[20];
    begin
        // [SCENARIO 373650] KodVidTovar xml node does not generated when "Tariff No." is not specified in sales VAT ledger line

        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo('', '');

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted sales invoice with vendor with VAT 18%
        CreateAndPostSalesInvoice(SalesHeader, '', VATLedgerMgt.GetVATPctRate2018(), false, CustomerType::Company);

        // [GIVEN] Create VAT Ledger with no Tariff No. assigned to the line
        CreateVATLedger(VATLedger, SalesHeader."Sell-to Customer No.", false);
        Commit();

        // [WHEN] Export sales VAT Ledger to XML
        RunVATLedgerExportXML(VATLedger, false);

        // [THEN] KodVidTovar xml node does not exist in the XML file
        InitializeXMLFile(GetFileName(false));
        LibraryXPathXMLReader.VerifyNodeAbsence(
          GetXPathSalesLedger(false) + GetXPathSalesLedgerLine(false) + '[1]/' + KodVidTovarTxt);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdateStockOutAndCreditWarnings;
        UpdatePostedVATAgentNoSeriesPurchSetup(LibraryERM.CreateNoSeriesCode());
        IsInitialized := true;

        LibraryRUReports.UpdateCompanyTypeInfo(CompanyType::Organization);
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure CreateCustomer(VATPostingSetup: Record "VAT Posting Setup"; Type: Option): Code[20]
    var
        Customer: Record Customer;
    begin
        with Customer do begin
            Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
            LibraryRUReports.UpdateCustomerType("No.", Type);
            exit("No.");
        end;
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryRUReports.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, CurrencyCode);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryRUReports.CreateSalesLine(SalesLine, SalesHeader, VATPostingSetup);
    end;

    local procedure CreateCurrency(IsConventional: Boolean): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        Currency.Validate(Conventional, IsConventional);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure RunVATLedgerExportReportXML(CustomerNo: Code[20]; AddSheet: Boolean)
    var
        VATLedger: Record "VAT Ledger";
    begin
        CreateVATLedger(VATLedger, CustomerNo, AddSheet);
        Commit();
        RunVATLedgerExportXML(VATLedger, AddSheet);
    end;

    local procedure RunVATLedgerExportXML(var VATLedger: Record "VAT Ledger"; AddSheet: Boolean)
    var
        VATLedgerExportXML: Report "VAT Ledger Export XML";
    begin
        VATLedgerExportXML.InitializeReport(VATLedger.Type::Sales, VATLedger.Code, AddSheet);
        VATLedgerExportXML.SetTableView(VATLedger);
        VATLedgerExportXML.UseRequestPage(true);
        VATLedgerExportXML.Run();
    end;

    local procedure CreateVATLedger(var VATLedger: Record "VAT Ledger"; CustomerNo: Code[20]; AddSheet: Boolean)
    var
        VATLedgerCode: Code[20];
    begin
        VATLedgerCode :=
          LibrarySales.CreateSalesVATLedger(WorkDate() - 1, LibraryRandom.RandDateFromInRange(WorkDate(), 5, 10), CustomerNo);
        if AddSheet then
            LibrarySales.CreateSalesVATLedgerAddSheet(VATLedgerCode);
        VATLedger.Get(VATLedger.Type::Sales, VATLedgerCode);
        UpdateVATEntryType(VATLedger);
    end;

    local procedure UpdateTariffNoToVATLedgerLine(var VATLedger: Record "VAT Ledger"; TariffNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.FindFirst();
        VATLedgerLine.Validate("Tariff No.", TariffNo);
        VATLedgerLine.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; VATRate: Decimal; AddSheet: Boolean; CustomerType: Option) DocumentNo: Code[20]
    begin
        if AddSheet then
            DocumentNo := LibraryRUReports.CreatePostSalesInvoiceAddSheet(SalesHeader, CurrencyCode, VATRate)
        else
            DocumentNo := LibraryRUReports.CreatePostSalesInvoice(SalesHeader, CurrencyCode, VATRate);
        LibraryRUReports.UpdateCustomerType(SalesHeader."Sell-to Customer No.", CustomerType);
    end;

    local procedure CreateAndPostSalesInvoiceMultiLines(var CustomerNo: Code[20]; CurrencyCode: Code[10]; CustomerType: Option; NormalVATRate: Decimal) DocumentNo: Code[20]
    begin
        DocumentNo := LibraryRUReports.CreatePostSalesInvoiceMultiLines(CustomerNo, CurrencyCode, NormalVATRate);
        LibraryRUReports.UpdateCustomerType(CustomerNo, CustomerType);
    end;

    local procedure CreateAndReleaseSalesInvoice(VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryRUReports.CreateReleaseSalesInvoice(SalesHeader, VATPostingSetup, CustomerNo, CurrencyCode);
        exit(SalesHeader."No.");
    end;

    local procedure CreatePostCorrSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Correction, CalcDate('<1D>', SalesHeader."Posting Date"));
        FindSalesLine(SalesLine, CorrSalesHeader);
        UpdateQuantityInSalesLine(SalesLine, LibraryRandom.RandIntInRange(3, 5));
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreatePostRevisionSalesInvoice(var CorrSalesHeader: Record "Sales Header"; SalesHeader: Record "Sales Header"; InvNo: Code[20]): Code[20]
    begin
        LibrarySales.CreateCorrectiveSalesInvoice(
          CorrSalesHeader, SalesHeader."Bill-to Customer No.", InvNo,
          CorrSalesHeader."Corrective Doc. Type"::Revision, SalesHeader."Posting Date" + 1);
        exit(LibrarySales.PostSalesDocument(CorrSalesHeader, true, true));
    end;

    local procedure CreatePurchaseInvoiceVendorVATAgent(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorVATAgent);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandIntInRange(5, 10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 2000));
        PurchaseLine.Modify(true);
        PurchaseHeader.CalcFields("Amount Including VAT");
    end;

    local procedure PostPurchasePrepayment(var PurchaseHeader: Record "Purchase Header")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreatePrepaymentJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."No.", PurchaseHeader."Amount Including VAT");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPurchasePayment(PurchaseHeader: Record "Purchase Header"; PostedInvoiceNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreatePaymentJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          PostedInvoiceNo, PurchaseHeader."Amount Including VAT");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            FindSet();
        end;
    end;

    local procedure FindPostedPurchaseInvoice(VendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("Posting Date", WorkDate() - 1);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure FormatValue(Value: Decimal): Text
    begin
        exit(LibraryRUReports.FormatAmountXML(Value));
    end;

    local procedure GetVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; Type: Option; DocumentType: Option; DocumentNo: Code[30])
    begin
        VATLedgerLine.SetRange(Type, Type);
        VATLedgerLine.SetRange("Document Type", DocumentType);
        VATLedgerLine.SetRange("Document No.", DocumentNo);
        VATLedgerLine.FindFirst();
    end;

    local procedure GetCorrectionVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; Type: Option; DocumentType: Option; DocumentNo: Code[30]; CorrectionType: Option ,Revision,Correction,RevOfCorrection)
    begin
        VATLedgerLine.SetRange(Type, Type);
        VATLedgerLine.SetRange("Document Type", DocumentType);
        VATLedgerLine.SetRange(Correction, true);
        case CorrectionType of
            CorrectionType::Correction:
                VATLedgerLine.SetRange("Document No.", DocumentNo);
            CorrectionType::Revision:
                VATLedgerLine.SetRange("Revision No.", DocumentNo);
            CorrectionType::RevOfCorrection:
                VATLedgerLine.SetRange("Revision of Corr. No.", DocumentNo);
        end;
        VATLedgerLine.FindFirst();
    end;

    local procedure GetFormattedDate(InputDate: Date): Text
    begin
        if InputDate <> 0D then
            exit(Format(InputDate, 10, '<Day,2>.<Month,2>.<Year4>'));
        exit
    end;

    local procedure CreatePrepaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; PrepDocNo: Code[20]; PrepaymentAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, PrepaymentAmount);
        GenJournalLine.Validate("Posting Date", WorkDate() - 1);
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Validate("Prepayment Document No.", PrepDocNo);
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; InitDocNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", WorkDate() - 1);
        GenJournalLine.Validate("Initial Document No.", InitDocNo);
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateQuantityInSalesLine(var SalesLine: Record "Sales Line"; Multiplier: Decimal)
    begin
        with SalesLine do begin
            Validate("Quantity (After)", Round("Quantity (After)" * Multiplier, 1));
            Modify(true);
        end;
    end;

    local procedure UpdateStockOutAndCreditWarnings()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesReceivablesSetup do begin
            Get();
            Validate("Credit Warnings", "Credit Warnings"::"No Warning");
            "Stockout Warning" := false;
            Modify(true);
        end;
    end;

    local procedure UpdateCompanySONOInfo(SONOAdmin: Code[4]; SONOReceipt: Code[4])
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get();
            "Admin. Tax Authority SONO" := SONOAdmin;
            "Recipient Tax Authority SONO" := SONOReceipt;
            Modify();
        end;
    end;

    local procedure UpdatePostedVATAgentNoSeriesPurchSetup(NoSeriesCode: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted VAT Agent Invoice Nos.", NoSeriesCode);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure EnqueueReportParameters(AddSheet: Boolean; CorrectionNo: Integer; IsPrevDataRelevant: Boolean)
    begin
        LibraryVariableStorage.Enqueue(CorrectionNo);
        LibraryVariableStorage.Enqueue(IsPrevDataRelevant);
        LibraryVariableStorage.Enqueue(AddSheet);
    end;

    local procedure UpdateVATEntryType(var VATLedger: Record "VAT Ledger")
    var
        VATLedgerLine: Record "VAT Ledger Line";
        VATEntryType: Record "VAT Entry Type";
        EntryCounter: Integer;
        RandomIndex: Integer;
    begin
        RandomIndex := LibraryRandom.RandInt(3);
        repeat
            VATEntryType.Next();
            EntryCounter += 1;
        until EntryCounter = RandomIndex;

        with VATLedgerLine do begin
            SetRange(Type, VATLedger.Type);
            SetRange(Code, VATLedger.Code);
            ModifyAll("VAT Entry Type", VATEntryType.Code, true)
        end;
    end;

    local procedure GetActCriteria(IsPrevDataRelevant: Boolean): Text[1]
    begin
        if IsPrevDataRelevant then
            exit('1');
        exit('0')
    end;

    local procedure GetFullFileName(FileName: Text): Text
    var
        FullFileName: Text;
    begin
        FullFileName := TemporaryPath;
        if CopyStr(FullFileName, StrLen(FullFileName), 1) <> '\' then
            FullFileName += '\';
        FullFileName += FileName + '.xml';

        exit(FullFileName);
    end;

    local procedure GetFileName(AddSheet: Boolean): Text
    var
        VATLedger: Record "VAT Ledger";
    begin
        exit(LocalReportMgt.GetVATLedgerXMLFileName(VATLedger.Type::Sales, AddSheet));
    end;

    local procedure GetXPathSalesLedger(AddSheet: Boolean): Text
    begin
        if AddSheet then
            exit('/' + FileTxt + '/' + DocumentTxt + '/' + KnigaProdDLTxt);

        exit('/' + FileTxt + '/' + DocumentTxt + '/' + KnigaProdTxt);
    end;

    local procedure GetXPathSalesLedgerLine(AddSheet: Boolean): Text
    begin
        if AddSheet then
            exit('/' + KnProdDLStrTxt);

        exit('/' + KnProdStrTxt);
    end;

    local procedure FormatBaseValue(VATBase: Decimal; Prepayment: Boolean): Text
    begin
        if VATBase <> 0 then begin
            if Prepayment then
                exit('');
            exit(LibraryRUReports.FormatAmountXML(VATBase));
        end;
        exit('');
    end;

    local procedure VerifyVATLedgExportXML(InvNo: Code[20]; LineIndex: Integer; DocumentType: Option ,Revision,Correction,RevOfCorrection; CustomerType: Option; AddSheet: Boolean; CorrectionNo: Integer; IsPrevDataRelevant: Boolean)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        if DocumentType = DocType::" " then
            GetVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."Document Type"::Invoice, InvNo)
        else
            GetCorrectionVATLedgerLine(
              VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."Document Type"::Invoice,
              InvNo, DocumentType);

        if LineIndex = 1 then begin
            InitializeXMLFile(GetFileName(AddSheet));
            VerifyFileElement(AddSheet);
            VerifyDocument(IsPrevDataRelevant, CorrectionNo, AddSheet);
            if not IsPrevDataRelevant then
                VerifySalesLedger(VATLedgerLine, AddSheet);
        end;

        if not IsPrevDataRelevant then begin
            VerifySalesLedgerLine(VATLedgerLine, LineIndex, AddSheet);
            VerifyPaymentDocument(VATLedgerLine, LineIndex, AddSheet);
            VerifyCustomerInformation(VATLedgerLine."C/V No.", LineIndex, CustomerType, AddSheet);
        end;
    end;

    local procedure InitializeXMLFile(FileName: Text)
    begin
        LibraryXPathXMLReader.Initialize(GetFullFileName(FileName), '');
    end;

    local procedure VerifyFileElement(AddSheet: Boolean)
    var
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath('/' + FileTxt, XMLNode);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, FileIDTxt, GetFileName(AddSheet));
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, VersProgTxt, '1.0'); // program version hardcoded
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, VersFormTxt, '5.08');  // format version hardcoded
    end;

    local procedure VerifyDocument(IsPrevDataRelevant: Boolean; CorrectionNo: Integer; AddSheet: Boolean)
    var
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath('/' + FileTxt + '/' + DocumentTxt, XMLNode);
        if AddSheet then begin
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, IndexTxt, '0000091'); // Hardcoded value: 0000091
            if CorrectionNo > 0 then
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, PriznSvedTxt + '91', GetActCriteria(IsPrevDataRelevant));
        end else begin
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, IndexTxt, '0000090'); // Hardcoded value: 0000090
            if CorrectionNo > 0 then
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, PriznSvedTxt + '9', GetActCriteria(IsPrevDataRelevant));
        end;
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, NomCorrTxt, Format(CorrectionNo));
    end;

    local procedure VerifySalesLedger(VATLedgerLine: Record "VAT Ledger Line"; AddSheet: Boolean)
    var
        VATLedger: Record "VAT Ledger";
        VATLedgerLineSum: Record "VAT Ledger Line";
        XMLNode: DotNet XmlNode;
        LinesTotalBase20: Decimal;
        LinesTotalBase18: Decimal;
        LinesTotalBase10: Decimal;
        LinesTotalBase0: Decimal;
        LinesTotalAmount20: Decimal;
        LinesTotalAmount18: Decimal;
        LinesTotalAmount10: Decimal;
        LinesTotalAmount0: Decimal;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(GetXPathSalesLedger(AddSheet), XMLNode);

        with VATLedgerLineSum do begin
            SetRange(Type, VATLedgerLine.Type);
            SetRange(Code, VATLedgerLine.Code);
            SetRange("Additional Sheet", AddSheet);
            FindSet();
            repeat
                if not Prepayment then begin
                    // TFS 379280, 379308: prepayments should not be included in total Base
                    LinesTotalBase20 += Base20;
                    LinesTotalBase18 += Base18;
                    LinesTotalBase10 += Base10;
                    LinesTotalBase0 += Base0;
                end;
                LinesTotalAmount20 += Amount20;
                LinesTotalAmount18 += Amount18;
                LinesTotalAmount10 += Amount10;
                LinesTotalAmount0 += "Base VAT Exempt";
            until Next() = 0;
        end;
        if AddSheet then begin
            VATLedger.Get(VATLedgerLine.Type, VATLedgerLine.Code);
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, ItStProdKPrTxt + '20', FormatValue(VATLedger."Tot Base20 Amt VAT Sales Ledg"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, ItStProdKPrTxt + '18', FormatValue(VATLedger."Tot Base18 Amt VAT Sales Ledg"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, ItStProdKPrTxt + '10', FormatValue(VATLedger."Tot Base 10 Amt VAT Sales Ledg"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, ItStProdKPrTxt + '0', FormatValue(VATLedger."Tot Base 0 Amt VAT Sales Ledg"));

            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, SumNDSItKPrTxt + '20', FormatValue(VATLedger."Total VAT20 Amt VAT Sales Ledg"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, SumNDSItKPrTxt + '18', FormatValue(VATLedger."Total VAT18 Amt VAT Sales Ledg"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, SumNDSItKPrTxt + '10', FormatValue(VATLedger."Total VAT10 Amt VAT Sales Ledg"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, ItStProdOsvKPrTxt, FormatValue(VATLedger."Total VATExempt Amt VAT S Ledg"));

            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, StProdVsP1R9Txt + '_20', FormatValue(VATLedger."Tot Base20 Amt VAT Sales Ledg" + LinesTotalBase20));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, StProdVsP1R9Txt + '_18', FormatValue(VATLedger."Tot Base18 Amt VAT Sales Ledg" + LinesTotalBase18));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, StProdVsP1R9Txt + '_10', FormatValue(VATLedger."Tot Base 10 Amt VAT Sales Ledg" + LinesTotalBase10));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, StProdVsP1R9Txt + '_0', FormatValue(VATLedger."Tot Base 0 Amt VAT Sales Ledg" + LinesTotalBase0));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, SumNDSVsP1R9Txt + '_20', FormatValue(VATLedger."Total VAT20 Amt VAT Sales Ledg" + LinesTotalAmount20));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, SumNDSVsP1R9Txt + '_18', FormatValue(VATLedger."Total VAT18 Amt VAT Sales Ledg" + LinesTotalAmount18));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, SumNDSVsP1R9Txt + '_10', FormatValue(VATLedger."Total VAT10 Amt VAT Sales Ledg" + LinesTotalAmount10));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, StProdOsvP1R9VsTxt, FormatValue(VATLedger."Total VATExempt Amt VAT S Ledg" + LinesTotalAmount0));
        end else begin
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StProdBezNDSTxt + '20', FormatValue(LinesTotalBase20));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StProdBezNDSTxt + '18', FormatValue(LinesTotalBase18));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StProdBezNDSTxt + '10', FormatValue(LinesTotalBase10));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StProdBezNDSTxt + '0', FormatValue(LinesTotalBase0));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, SumNDSVsKPrTxt + '20', FormatValue(LinesTotalAmount20));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, SumNDSVsKPrTxt + '18', FormatValue(LinesTotalAmount18));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, SumNDSVsKPrTxt + '10', FormatValue(LinesTotalAmount10));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StProdOsvVsKPrTxt, FormatValue(LinesTotalAmount0));
        end;
    end;

    local procedure VerifySalesLedgerLine(VATLedgerLine: Record "VAT Ledger Line"; LineIndex: Integer; AddSheet: Boolean)
    var
        XMLNode: DotNet XmlNode;
        SalesLedgerLinexPath: Text;
    begin
        SalesLedgerLinexPath := GetXPathSalesLedger(AddSheet) + GetXPathSalesLedgerLine(AddSheet) + '[' + Format(LineIndex) + ']';

        LibraryXPathXMLReader.GetNodeByXPath(SalesLedgerLinexPath, XMLNode);
        with VATLedgerLine do begin
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, NomerPorTxt, Format(LineIndex));
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, NomScFProdTxt, Format("Document No."));
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, DataScFProdTxt, GetFormattedDate("Document Date"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, NomIsprScFTxt, Format("Revision No."));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, DataIsprScFTxt, GetFormattedDate("Revision Date"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, NomKScFProdTxt, Format("Correction No."));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, DataKScFProdTxt, GetFormattedDate("Correction Date"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, NomIsprKScFTxt, Format("Revision of Corr. No."));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, DataIsprKScFTxt, GetFormattedDate("Revision of Corr. Date"));

            // TFS 378442, 378457: "OKV", "StoimProdSFV"
            if LocalReportMgt.IsForeignCurrency("Currency Code") and
               not LocalReportMgt.IsConventionalCurrency("Currency Code") and
               not LocalReportMgt.HasRelationalCurrCode("Currency Code", "Document Date")
            then begin
                LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
                  XMLNode, OKVTxt, Format(LibraryRUReports.GetCurrencyCode("Currency Code")));
                LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StoimProdSFVTxt, FormatValue(Abs(Amount)));
            end else begin
                LibraryXPathXMLReader.VerifyAttributeAbsenceFromNode(XMLNode, OKVTxt);
                LibraryXPathXMLReader.VerifyAttributeAbsenceFromNode(XMLNode, StoimProdSFVTxt);
            end;

            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, StoimProdSFTxt, LocalReportMgt.GetVATLedgerAmounInclVATFCY(VATLedgerLine));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StoimProdSFTxt + '20', FormatBaseValue(Base20, Prepayment));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StoimProdSFTxt + '18', FormatBaseValue(Base18, Prepayment));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StoimProdSFTxt + '10', FormatBaseValue(Base10, Prepayment));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, StoimProdSFTxt + '0', FormatBaseValue(Base0, Prepayment));

            if Base18 <> 0 then
                LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, SumNDSSFTxt + '18', FormatValue(Amount18));

            if Base10 <> 0 then
                LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, SumNDSSFTxt + '10', FormatValue(Amount10));

            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
              XMLNode, 'æÔ«¿¼ÅÓ«ñÄßó', FormatValue("Base VAT Exempt"));
            LibraryXPathXMLReader.VerifyNodeValueByXPath(SalesLedgerLinexPath + '/' + KodVidOperTxt, "VAT Entry Type");
            if "Tariff No." <> '' then
                LibraryXPathXMLReader.VerifyNodeValueByXPath(SalesLedgerLinexPath + '/' + KodVidTovarTxt, "Tariff No.");
        end;
    end;

    local procedure VerifyPaymentDocument(VATLedgerLine: Record "VAT Ledger Line"; LineIndex: Integer; AddSheet: Boolean)
    var
        XMLNode: DotNet XmlNode;
    begin
        with VATLedgerLine do
            if Prepayment or LocalReportMgt.IsVATAgentVendor("C/V No.", "C/V Type") then begin
                LibraryXPathXMLReader.GetNodeByXPath(
                  GetXPathSalesLedger(AddSheet) + GetXPathSalesLedgerLine(AddSheet) +
                  '[' + Format(LineIndex) + ']/' + DocPdtvOplTxt, XMLNode);
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, NomDocPdtvOplTxt, "External Document No.");
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, DataDocPdtvOplTxt, GetFormattedDate("Payment Date"));
            end;
    end;

    local procedure VerifyCustomerInformation(CustomerNo: Code[20]; LineIndex: Integer; Type: Option; AddSheet: Boolean)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        if Type = CustomerType::Person then
            VerifyVATRegNoAndKPP_IP(LineIndex, Customer."VAT Registration No.", AddSheet)
        else
            VerifyVATRegNoAndKPP_UL(LineIndex, Customer."VAT Registration No.", Customer."KPP Code", AddSheet);
    end;

    local procedure VerifyVATRegNoAndKPP_UL(LineIndex: Integer; ExpectedVATRegNo: Text; ExpectedKPP: Text; AddSheet: Boolean)
    var
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          GetXPathSalesLedger(AddSheet) + GetXPathSalesLedgerLine(AddSheet) +
          '[' + Format(LineIndex) + ']/' + SvPokupTxt + '/' + SvedULTxt, XMLNode);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, INNULTxt, ExpectedVATRegNo);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, KPPTxt, ExpectedKPP);
    end;

    local procedure VerifyVATRegNoAndKPP_IP(LineIndex: Integer; ExpectedVATRegNo: Text; AddSheet: Boolean)
    var
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          GetXPathSalesLedger(AddSheet) + GetXPathSalesLedgerLine(AddSheet) +
          '[' + Format(LineIndex) + ']/' + SvPokupTxt + '/' + SvedIPTxt, XMLNode);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, INNFLTxt, ExpectedVATRegNo);
        LibraryXPathXMLReader.VerifyAttributeAbsenceFromNode(XMLNode, KPPTxt);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHSalesVATLedgerExpXML(var VATLedgerExportXML: TestRequestPage "VAT Ledger Export XML")
    var
        CorrectionNo: Integer;
    begin
        CorrectionNo := LibraryVariableStorage.DequeueInteger();
        if CorrectionNo <> 0 then begin
            VATLedgerExportXML.CorrectiveSubmission.SetValue(true);
            VATLedgerExportXML.CorrectionNo.SetValue(CorrectionNo);
        end else
            VATLedgerExportXML.CorrectiveSubmission.SetValue(false);

        VATLedgerExportXML.ActCriteria.SetValue(LibraryVariableStorage.DequeueBoolean());
        VATLedgerExportXML.FileName.AssertEquals(GetFileName(LibraryVariableStorage.DequeueBoolean()));  // Suggested filename field
        VATLedgerExportXML.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PHVATSalesLedgerCard(var VATSalesLedgerCard: TestPage "VAT Sales Ledger Card")
    begin
        VATSalesLedgerCard."Tot Base20 Amt VAT Sales Ledg".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATSalesLedgerCard."Tot Base18 Amt VAT Sales Ledg".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATSalesLedgerCard."Tot Base 10 Amt VAT Sales Ledg".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATSalesLedgerCard."Tot Base 0 Amt VAT Sales Ledg".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATSalesLedgerCard."Total VAT20 Amt VAT Sales Ledg".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATSalesLedgerCard."Total VAT18 Amt VAT Sales Ledg".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATSalesLedgerCard."Total VAT10 Amt VAT Sales Ledg".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATSalesLedgerCard."Total VATExempt Amt VAT S Ledg".SetValue(LibraryVariableStorage.DequeueDecimal());
        VATSalesLedgerCard.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MHConfirmMessage(Message: Text[1024])
    begin
    end;
}

