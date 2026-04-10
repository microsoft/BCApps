codeunit 147143 "ERM Purch.VAT Ledg. Export XML"
{
    // // [FEATURE] [VAT Ledger] [Purchase] [Export XML]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRUReports: Codeunit "Library RU Reports";
        LocalReportMgt: Codeunit "Local Report Management";
        VATLedgerMgt: Codeunit "VAT Ledger Management";
        IsInitialized: Boolean;
        DocType: Option " ",Revision,Correction,RevOfCorrection;
        VendorType: Option Person,Company;
        CompanyType: Option Person,Organization;
        NoVATRegNoErr: Label 'The values are not the same.';
        BlankVendorNoErr: Label '''%1'' in ''%2: %3'' must not be blank.', Comment = '%1=Caption of the VAT Registration No. field;%2=Caption of the table Vendor;%3=Vendor Number';
        DocumentTxt: Label 'Document';
        IndexTxt: Label 'Index';
        PriznSvedTxt: Label 'PriznSved';
        NomCorrTxt: Label 'NomCorr';
        FileTxt: Label 'File';
        FileIDTxt: Label 'FileID';
        VersProgTxt: Label 'VersProg';
        VersFormTxt: Label 'VersForm';
        SvProdTxt: Label 'SvProd', Locked = true;
        SvedULTxt: Label 'SvedUL';
        SvedIPTxt: Label 'SvedIP';
        INNULTxt: Label 'INNUL', Locked = true;
        INNFLTxt: Label 'INNFL', Locked = true;
        KPPTxt: Label 'KPP', Locked = true;
        KnigaPokupDLTxt: Label 'KnigaPokupDL';
        KnigaPokupTxt: Label 'KnigaPokup';
        KnPokDLStrTxt: Label 'KnPokDLStr';
        KnPokStrTxt: Label 'KnPokStr';
        SumNDSTxt: Label 'SumNDS';
        SumNDSVicTxt: Label 'SumNDSVic';
        SumNDSItP1R8Txt: Label 'SumNDSItP1R8';
        SumNDSVsKPkTxt: Label 'SumNDSVsKPk';
        NomerPorTxt: Label 'NomerPor';
        NomScFProdTxt: Label 'NomScFProd';
        DataScFProdTxt: Label 'DataScFProd';
        NomIsprScFTxt: Label 'NomIsprScF';
        DataIsprScFTxt: Label 'DataIsprScF';
        NomKScFProdTxt: Label 'NomKScFProd';
        DataKScFProdTxt: Label 'DataKScFProd';
        NomIsprKScFTxt: Label 'NomIsprKScF';
        DataIsprKScFTxt: Label 'DataIsprKScF';
        NomTDTxt: Label 'NomTD';
        OKVTxt: Label 'OKV';
        StoimPokupVTxt: Label 'StoimPokupV';
        KodVidOperTxt: Label 'KodVidOper';
        DocPdtvUplTxt: Label 'DocPdtvUpl';
        NomDocPdtvUplTxt: Label 'NomDocPdtvUpl';
        DataDocPdtvUplTxt: Label 'DataDocPdtvUpl';
        DataUcTovTxt: Label 'DataUcTov';
        SumNDSItKPkTxt: Label 'SumNDSItKPk';
        KodVidTovarTxt: Label 'KodVidTovar';

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic18()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.51] Verify report data when Purchase invoice is posted with VAT=18%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo('', '');
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice with vendor with VAT 18%
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2018, false, VendorType::Company);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.8_AAAA_KKKK_"X"_20160401_N" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        // [THEN] XML doesn't contain "DocPdtvUpl" node (TFS 378410)
        // [THEN] XML contains node "SvProd" (TFSID 381008)
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
        LibraryXPathXMLReader.VerifyNodeAbsence(GetXPathPurchLedger(false) + GetXPathPurchLedgerLine(false) +
          '[' + Format(1) + ']/' + DocPdtvUplTxt);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic20()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Verify report data when Purchase invoice is posted with VAT=20%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo('', '');
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice with vendor with VAT 20%
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019, false, VendorType::Company);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.8_AAAA_KKKK_"X"_20160401_N" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        // [THEN] XML doesn't contain "DocPdtvUpl" node (TFS 378410)
        // [THEN] XML contains node "SvProd" (TFSID 381008)
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
        LibraryXPathXMLReader.VerifyNodeAbsence(GetXPathPurchLedger(false) + GetXPathPurchLedgerLine(false) +
          '[' + Format(1) + ']/' + DocPdtvUplTxt);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic10()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.52] Verify report data when Purchase invoice is posted with VAT=10%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '1234', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo(Format(LibraryRandom.RandIntInRange(1000, 9999)), Format(LibraryRandom.RandIntInRange(1000, 9999)));
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice with vendor with VAT 10%
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', 10, false, VendorType::Company);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.8_1234_KKKK_"X"_20160401_N" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic18_10_0()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.53] Verify report data when Purchase invoice is posted with multiple Purchase lines with VAT respectively set to 18%, 10% and 0%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = '5678'
        UpdateCompanySONOInfo(Format(LibraryRandom.RandIntInRange(1000, 9999)), Format(LibraryRandom.RandIntInRange(1000, 9999)));
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice with vendor with 3 lines VAT 18%, 10% and 0%
        InvNo := CreateAndPostPurchInvoiceMultiLines(VendorNo, '', VendorType::Company, VATLedgerMgt.GetVATPctRate2018);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.8_AAAA_5678_"X"_20160401_N" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic20_10_0()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 303035] Verify report data when Purchase invoice is posted with multiple Purchase lines with VAT respectively set to 20%, 10% and 0%
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = '5678'
        UpdateCompanySONOInfo(Format(LibraryRandom.RandIntInRange(1000, 9999)), Format(LibraryRandom.RandIntInRange(1000, 9999)));
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice with vendor with 3 lines VAT 20%, 10% and 0%
        InvNo := CreateAndPostPurchInvoiceMultiLines(VendorNo, '', VendorType::Company, VATLedgerMgt.GetVATPctRate2019);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.8_AAAA_5678_"X"_20160401_N" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains values defined by spec
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic18FCY()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.54] Verify report data when Purchase invoice is posted in FCY
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '1234', "Recipient Tax Authority SONO" = '5678'
        UpdateCompanySONOInfo(Format(LibraryRandom.RandIntInRange(1000, 9999)), Format(LibraryRandom.RandIntInRange(1000, 9999)));
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Create and post Purchase invoice for a vendor with FCY currency
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrency(false), VATLedgerMgt.GetVATPctRate2018, false, VendorType::Company);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.8_1234_5678_"X"_20160401_N" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains the Purchase amount incl. VAT values in FCY created
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic20FCY()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.54] Verify report data when Purchase invoice is posted in FCY
        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '1234', "Recipient Tax Authority SONO" = '5678'
        UpdateCompanySONOInfo(Format(LibraryRandom.RandIntInRange(1000, 9999)), Format(LibraryRandom.RandIntInRange(1000, 9999)));
        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Create and post Purchase invoice for a vendor with FCY currency
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrency(false), VATLedgerMgt.GetVATPctRate2019, false, VendorType::Company);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.8_1234_5678_"X"_20160401_N" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains the Purchase amount incl. VAT values in FCY created
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic18FCYConventional()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.55] Verify report data when Purchase invoice is posted in Conventional Currency
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Create and post Purchase invoice for a vendor with conventional currency
        // [GIVEN] "Amount Including VAT (LCY)" = "A", "Amount (LCY)" = "B".
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrency(true), VATLedgerMgt.GetVATPctRate2018, false, VendorType::Company);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains the Purchase amount incl. VAT values in Conventional FCY created
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportBasic20FCYConventional()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.55] Verify report data when Purchase invoice is posted in Conventional Currency
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Create and post Purchase invoice for a vendor with conventional currency
        // [GIVEN] "Amount Including VAT (LCY)" = "A", "Amount (LCY)" = "B".
        InvNo := CreateAndPostPurchInvoice(VendorNo, CreateCurrency(true), VATLedgerMgt.GetVATPctRate2019, false, VendorType::Company);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains the Purchase amount incl. VAT values in Conventional FCY created
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportAddSheet()
    var
        InvNo: Code[20];
        VendorNo: Code[20];
        TotalVATFromVATPurchLedg: Decimal;
    begin
        // [SCENARIO TFS=124828.57] Verify VAT Additional Sheet report when Purchase invoice with VAT = 18% is posted where Aditional Sheet is report in different accounting period
        Initialize();
        TotalVATFromVATPurchLedg := LibraryRandom.RandDec(1000, 2);

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '1234', "Recipient Tax Authority SONO" = '5678'
        UpdateCompanySONOInfo(Format(LibraryRandom.RandIntInRange(1000, 9999)), Format(LibraryRandom.RandIntInRange(1000, 9999)));
        // [GIVEN] AddSheet = TRUE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(true, 0, false);

        // [GIVEN] posted Purchase invoice with new vendor with VAT 20%
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019, true, VendorType::Company);

        // [WHEN] Purchase Additional Sheet VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, true, false, TotalVATFromVATPurchLedg, false);

        // [THEN] XML File Name = XML "FileID" attrubute = "NO_NDS.81_1234_5678_"X"_20160401_N" (TFS 166062)
        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains VAT amount from other reporting periods in the Total Purchase Ledger Vat Amount attribute
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, true, 0, false, TotalVATFromVATPurchLedg);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportCorrection()
    var
        InvNo: Code[20];
        VendorNo: Code[20];
        CorrectionNo: Integer;
    begin
        // [SCENARIO TFS=124828.58] Verify VAT Export report when corrective Purchase invoice is posted
        Initialize();
        CorrectionNo := LibraryRandom.RandIntInRange(1, 999);

        // [GIVEN] AddSheet = FALSE, CorrectionNo <> 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, CorrectionNo, false);

        // [GIVEN] posted corrective Purchase invoice
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019, false, VendorType::Company);
        CreatePostCorrRevPurchInvoice(VendorNo, InvNo, true);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains two Purchase Ledger Lines related to the original invoice and correction of the original invoice
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, CorrectionNo, false, 0);
        VerifyVATLedgExportXML(InvNo, 2, DocType::Correction, VendorType::Company, false, CorrectionNo, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportRevision()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        InvNo: Code[20];
        RevInvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.59] Verify VAT Export report when revision Purchase invoice is posted
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] posted revision Purchase invoice
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019, false, VendorType::Company);
        RevInvNo := CreatePostCorrRevPurchInvoice(VendorNo, InvNo, false);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] XML contains two Purchase Ledger Lines related to the original invoice and the revision of the original invoice
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
        PurchInvHeader.Get(RevInvNo);
        VerifyVATLedgExportXML(
          PurchInvHeader."Revision No.", 2, DocType::Revision, VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportRevCorr()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        InvNo: Code[20];
        CorInvNo: Code[20];
        RevInvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.60] Verify VAT Export report when revision Purchase invoice for correction is posted
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] posted revision Purchase invoice for correction
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019, false, VendorType::Company);
        CorInvNo := CreatePostCorrRevPurchInvoice(VendorNo, InvNo, true);
        RevInvNo := CreatePostCorrRevPurchInvoice(VendorNo, CorInvNo, false);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML contains Purchase Ledger Line related to the original invoice,
        // [THEN] XML contains Purchase Ledger Line related to the correction of the original invoice
        // [THEN] XML contains Purchase Ledger Line related to the revision of the correction of the original invoice
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
        VerifyVATLedgExportXML(InvNo, 2, DocType::Correction, VendorType::Company, false, 0, false, 0);
        PurchInvHeader.Get(RevInvNo);
        VerifyVATLedgExportXML(
          PurchInvHeader."Revision No.", 3, DocType::RevOfCorrection, VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportActCriteria8RelevantChanges()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
        CorrectionNo: Integer;
    begin
        // [SCENARIO TFS=124828.61] Verify VAT Export report when last sent report contains Relevant Changes and ActCriteria8 set to 1 - Relevant Changes
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo <> 0, IsPrevDataRelevant = TRUE
        CorrectionNo := LibraryRandom.RandIntInRange(1, 999);
        EnqueueReportParameters(false, CorrectionNo, true);

        // [GIVEN] Posted Purchase Invoice
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019, false, VendorType::Company);

        // [GIVEN] User enters Corrective Submission = TRUE
        // [GIVEN] Number of Correction and Last sent report contains 1 - Relevant Changes
        // [WHEN] Export VAT Ledger into XML
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML has element ActCriteria8 set to 1
        // [THEN] XML doesn't contain any PurchaseLedger nodes
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, CorrectionNo, true, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportActCriteria8IrrelevantChanges()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
        CorrectionNo: Integer;
    begin
        // [SCENARIO TFS=124828.62] Verify VAT Export report when last sent report contains Irrelevant Changes and ActCriteria8 set to 0 - Irrelevant Changes
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo <> 0, IsPrevDataRelevant = FALSE
        CorrectionNo := LibraryRandom.RandIntInRange(1, 999);
        EnqueueReportParameters(false, CorrectionNo, false);

        // [GIVEN] Posted Purchase Invoice
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019, false, VendorType::Company);

        // [GIVEN] User enters Corrective Submission = TRUE
        // [GIVEN] Number of Correction and Last sent report contains 0 - Irrelevant Changes
        // [WHEN] Export VAT Ledger into XML
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] XML has element ActCriteria8 set to 0
        // [THEN] XML contains at least one PurchaseLedger node
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, CorrectionNo, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportImportFullVAT()
    var
        VendorNo: Code[20];
        DocNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO TFS=124828.63] Verify Full VAT on import operation in Purchase VAT Ledger
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Posted Purchase invoice "X" with Full VAT
        DocNo := CreateAndPostPurchInvoiceFullVAT(VendorNo, Amount, '', 0D, VendorType::Company);

        // [GIVEN] Payment "Y" applied to "X"
        PostAppliedPayment(VendorNo, DocNo, Amount, WorkDate());

        // [WHEN] creates VAT Ledger Export XML report
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] Exported Report contains "X"."Amount Incl. VAT (LCY)"
        VerifyVATLedgExportXML(DocNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportImportFullVATExtDocNo()
    var
        VendorNo: Code[20];
        DocNo: Code[20];
        VendVATInvNo: Code[20];
        VendorVATInvDate: Date;
        Amount: Decimal;
    begin
        // [SCENARIO TFS=124828.64] Verify Full VAT on import operation in Purchase VAT Ledger, Use External Doc No.
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Posted Purchase invoice "X" with Full VAT
        // [GIVEN] "Vendor VAT Invoice No." = A, "Vendor VAT Invoice Date" = B
        VendVATInvNo :=
          PadStr(LibraryUtility.GenerateGUID(), 20, '0');
        VendorVATInvDate := LibraryRandom.RandDateFromInRange(WorkDate(), 2, 5);
        DocNo := CreateAndPostPurchInvoiceFullVAT(VendorNo, Amount, VendVATInvNo, VendorVATInvDate, VendorType::Company);

        // [GIVEN] Payment "Y" applied to "X"
        PostAppliedPayment(VendorNo, DocNo, Amount, WorkDate() + 1);

        // [WHEN] creates VAT Ledger Export XML report and "Use External Doc. No." is set to TRUE
        RunVATLedgerExportReportXML(VendorNo, false, true, 0, false);

        // [THEN] Exported Report contains "X"."Amount Incl. VAT (LCY)"
        VerifyVATLedgExportXML(VendVATInvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportImportFullVATTwoPayments()
    var
        VendorNo: Code[20];
        DocNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Full VAT] [Application]
        // [SCENARIO 374725] Export VAT Purchase Ledger with two applied payments involving Full VAT
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Posted Purchase invoice "X" with Full VAT
        DocNo := CreateAndPostPurchInvoiceFullVAT(VendorNo, Amount, '', 0D, VendorType::Company);

        // [GIVEN] Applied Payment "P1" with "External Document No." = "NO1"
        // [GIVEN] Applied Payment "P2" with "External Document No." = "NO2"
        PostTwoAppliedPayments(VendorNo, DocNo, Amount);

        // [WHEN] Export VAT Purchase Ledger in XML format
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] Two payments entry exported
        // [THEN] First payment entry's "Document No." = "NO1"
        // [THEN] Second payment entry's "Document No." = "NO2"
        VerifyAppliedPaymentDocumentsWithFullVAT(VendorNo, false);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportCompanyAsPerson()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.65] Verify report data when the NAV user is a person
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice with vendor with VAT 20%
        LibraryRUReports.UpdateCompanyTypeInfo(CompanyType::Person);
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019, false, VendorType::Company);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] Proposed File Name contains only VAT Reg.No
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportVendorAsPerson()
    var
        VendorNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO TFS=124828.66] Verify report data when the vendor of a purchase invoice is a person
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice with vendor with VAT 20%
        // [GIVEN] The vendor is a person, not a company
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2019, false, VendorType::Person);

        // [WHEN] Purchase VAT Ledger Export XML is created
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);

        // [THEN] Verify XML is created by defined XSD schema
        // [THEN] The node containing the information about the Vendor doesn't have the attribute for the KPP value
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Person, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,PHErrorsPurchVATLedgerExpXML')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportVendorVATRegNo()
    var
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [SCENARIO TFS=124828.67] Verify that an error is reported when Vendor doesn't have VAR Reg. No.
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice
        VendorNo := CreateVendor(VendorType);
        LibraryVariableStorage.Enqueue(VendorNo);
        Vendor.Get(VendorNo);

        // [GIVEN] The vendor does not have a VAT registration no.
        Vendor."VAT Registration No." := '';
        Vendor.Modify(true);

        CreatePurchHeader(PurchHeader, VendorNo, '');
        CreatePurchLine(PurchHeader, VATLedgerMgt.GetVATPctRate2019);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Report cannot be created if the the vendor doesn't have a VAT Reg No
        RunVATLedgerExportReportXML(VendorNo, false, false, 0, false);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportVendorVATAgentNonResident()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PrepmtDocNo: Code[20];
    begin
        // [FEATURE] [Prepayment] [FCY] [VAT Agent]
        // [SCENARIO 374732] Export Purchase VAT Ledger for posted prepayment from foreign non-resident Vendor as VAT Agent with blank KPP Code and VAT Reg. No.
        Initialize();

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Foreign Non-Resident Vendor as VAT Agent "V" with blank
        // [THEN] "V"."KPP Code" = '' (blank)
        // [THEN] "V"."VAT Registration No." = '' (blank)
        Vendor.Get(LibraryPurchase.CreateVendorVATAgent);
        Vendor.Validate("KPP Code", '');
        Vendor.Validate("VAT Registration No.", '');
        Vendor.Modify(true);

        // [GIVEN] Released Purchase Invoice "I" from Vendor "V"
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        // [GIVEN] Posted Prepayment for the invoice "I"
        PrepmtDocNo := PostPurchasePrepayment(PurchaseHeader, 1);

        // [GIVEN] VAT Settled manually for posted prepayment
        PostVATSettlementJournalLine(Vendor."No.");

        // [WHEN] Export Purchase VAT Ledger to XML
        RunVATLedgerExportReportXML(Vendor."No.", false, false, 0, false);

        // [THEN] Exported CV "VAT Registration No." = "V"."VAT Registration No." (blank)
        // [THEN] "KPP Code" is not exported
        // [THEN] "DocPdtvUpl" is exported (TFS 378410)
        InitializeXMLFile(false);
        VerifyVendorInformation(Vendor."No.", 1, VendorType::Person, false);
        VerifyPaymentXmlNode(1, PrepmtDocNo, WorkDate(), false);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerReportCustomerPrpmt()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        PmtDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 374736] Exported sales prepayment via VAT Purchase Ledger has company's VAT Reg No. and KPP Code
        Initialize();
        LibraryERM.SetCancelPrepmtAdjmtinTA(true);

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] "Company Information"."VAT Registration No." = "X"
        // [GIVEN] "Company Information"."KPP Code" = "Y"
        LibraryRUReports.UpdateCompanyTypeInfo(CompanyType::Organization);

        // [GIVEN] Sales Invoice ("Posting Date" = "D1", "Amount Including VAT" = 1000, "VAT Amount" = 180) applied to Prepayment ("Posting Date" = "D2", Amount = 2000)
        CreateSalesInvoice(SalesHeader);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        PrepmtDocNo := PostAndApplySalesPrepayment(SalesHeader, PmtDate);

        // [WHEN] Export Purchase VAT Ledger to XML
        RunVATLedgerExportReportXML(SalesHeader."Sell-to Customer No.", false, false, 0, true);

        // [THEN] Exported CV "VAT Registration No." = "Company Information"."VAT Registration No." = "X"
        // [THEN] Exported CV "KPP Code" = "Company Information"."KPP Code" = "Y"
        // [THEN] "DocPdtvUpl" is exported (TFS 378410)
        // [THEN] "DataUcTov" = "D1" (TFS 378574)
        InitializeXMLFile(false);
        CompanyInformation.Get();
        VerifyVATRegNoAndKPP(1, CompanyInformation."VAT Registration No.", CompanyInformation."KPP Code", false);
        VerifyPaymentXmlNode(1, PrepmtDocNo, PmtDate, false);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          GetXPathPurchLedger(false) + GetXPathPurchLedgerLine(false) + '[1]/' + DataUcTovTxt,
          GetFormattedDate(SalesHeader."Posting Date"));

        // [THEN] "StoimPokupV" = 2000 (TFS 379315)
        // [THEN] "SumNDSVic" = 180 (TFS 379315)
        VerifyCustomerPrepayment(PrepmtDocNo);
    end;

    [Test]
    [HandlerFunctions('MHConfirmMessage,RPHPurchVATLedgerExpXML')]
    [Scope('OnPrem')]
    procedure PurchVATLedgerVATAgentPrpmtInvPmtManualVATSettlement()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
        PrepaymentNo: Code[20];
    begin
        // [FEATURE] [Manual VAT Settlement] [VAT Agent] [FCY]
        // [SCENARIO 372317] VAT Purchase Ledger shows payment entry for VAT Agent when VAT settled manually
        Initialize();
        // [GIVEN] AddSheet = FALSE
        // [GIVEN] CorrectionNo = 0
        // [GIVEN] IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Foreign Non-Resident Vendor as VAT Agent
        // [GIVEN] Released Purchase Invoice "I" with Amount = 3000
        CreatePurchaseInvoice(PurchaseHeader, LibraryPurchase.CreateVendorVATAgent);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        // [GIVEN] Posted partial Prepayment "PP" for the Invoice "I" with Amount = 1000
        PrepaymentNo := PostPurchasePrepayment(PurchaseHeader, 1 / 3);

        // [GIVEN] VAT Settled manually for posted prepayment "PP"
        PostVATSettlementJournalLine(PurchaseHeader."Buy-from Vendor No.");

        // [GIVEN] Posted Invoice "I" at date "D1"
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted Payment "P" at date "D2" ("D2 > "D1") for Invoice "I" with Amount = 2000 (remaining amount)
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);
        CreatePaymentJournalLine(
          GenJournalLine, GenJournalBatch, PurchaseHeader."Buy-from Vendor No.", '',
          PurchaseHeader."Amount Including VAT" * 2 / 3, LibraryRandom.RandDate(5));
        GenJournalLine.Validate("Initial Document No.", InvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] VAT Settled manually for posted payment "P"
        PostVATSettlementJournalLine(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Export Purchase VAT Ledger to XML
        RunVATLedgerExportReportXML(PurchaseHeader."Buy-from Vendor No.", false, false, 0, false);

        InitializeXMLFile(false);

        // [THEN] Line[1]."Payment Doc. No." = "PP"; Line1.Amount = 1000 ("PP".Amount)
        VerifyPaymentXmlNode(1, PrepaymentNo, WorkDate(), false);
        VerifyPaymentAmount(1, PrepaymentNo, false);
        // [THEN] Line[2]."Payment Doc. No." = "P"; Line2.Amount = 2000 ("P".Amount)
        VerifyPaymentXmlNode(2, GenJournalLine."External Document No.", GenJournalLine."Posting Date", false);
        VerifyPaymentAmount(2, GenJournalLine."Document No.", false);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchKodVidTovarXmlNodeGeneratesWhenTariffNoSpecified()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
        TariffNo: Code[20];
        InvNo: Code[20];
    begin
        // [SCENARIO 373650] KodVidTovar xml node generates when "Tariff No." is specified in purchase VAT ledger line

        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo('', '');

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice with vendor with VAT 18%
        InvNo := CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2018(), false, VendorType::Company);
        TariffNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create VAT Ledger with Tariff No. assigned to the line
        CreateVATLedger(VATLedger, VendorNo, false, false, 0, false);
        UpdateTariffNoToVATLedgerLine(VATLedger, TariffNo);
        Commit();

        // [WHEN] Export Purchase VAT Ledger to XML
        RunVATLedgerExportXML(VATLedger, false);

        // [THEN] KodVidTovar xml node does exist in the XML file
        VerifyVATLedgExportXML(InvNo, 1, DocType::" ", VendorType::Company, false, 0, false, 0);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    [Scope('OnPrem')]
    procedure PurchKodVidTovarXmlNodeDoesNotGenerateWhenTariffNoNotSpecified()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
    begin
        // [SCENARIO 373650] KodVidTovar xml node does not generated when "Tariff No." is not specified in purchase VAT ledger line

        Initialize();

        // [GIVEN] CompanyInfo: "VAT Registration No." = "X", "Admin. Tax Authority SONO" = '', "Recipient Tax Authority SONO" = ''
        UpdateCompanySONOInfo('', '');

        // [GIVEN] AddSheet = FALSE, CorrectionNo = 0, IsPrevDataRelevant = FALSE
        EnqueueReportParameters(false, 0, false);

        // [GIVEN] Created and posted Purchase invoice with vendor with VAT 18%
        CreateAndPostPurchInvoice(VendorNo, '', VATLedgerMgt.GetVATPctRate2018(), false, VendorType::Company);

        // [GIVEN] Create VAT Ledger with no Tariff No. assigned to the line
        CreateVATLedger(VATLedger, VendorNo, false, false, 0, false);
        Commit();

        // [WHEN] Export Purchase VAT Ledger to XML
        RunVATLedgerExportXML(VATLedger, false);

        // [THEN] KodVidTovar xml node does not exist in the XML file
        InitializeXMLFile(false);
        LibraryXPathXMLReader.VerifyNodeAbsence(GetXPathPurchLedger(false) + GetXPathPurchLedgerLine(false) +
          '[' + Format(1) + ']/' + KodVidTovarTxt);
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    procedure SvProdIsExportedForBasicVATEntryTypeCodes()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
        Codes: list of [Code[15]];
        CurrCode: Code[15];
    begin
        // [SCENARIO 378777] "SvProd" is exported for basic "VAT Entry Type" codes ("01", "02", "13", "15", "22", "32", ...)
        Initialize();

        // [GIVEN] Purchase VAT Ledger with several lines with basic "VAT Entry Type" values
        VendorNo := CreateVendor(VendorType::Company);
        MockVATLedger(VATLedger);
        GetVATEntryTypeBasicCodes(Codes);
        foreach CurrCode in Codes do
            MockVendorVATLedgerLine(VATLedger, VendorNo, CurrCode);

        // [WHEN] Export Purchase VAT Ledger XML
        Commit();
        EnqueueReportParameters(false, 0, false);
        RunVATLedgerExportXML(VATLedger, false);

        // [THEN] XML contains "SvProd" node per each "KnigaPokup" node
        LibraryXPathXMLReader.Initialize(GetFullFileName(false), '');
        LibraryXPathXMLReader.VerifyNodeCountByXPath(
          GetXPathPurchLedger(false) + GetXPathPurchLedgerLine(false) + '/' + SvProdTxt, Codes.Count());
    end;

    [Test]
    [HandlerFunctions('RPHPurchVATLedgerExpXML,MHConfirmMessage')]
    procedure SvProdIsNotExportedForSpecialVATEntryTypeCodes()
    var
        VATLedger: Record "VAT Ledger";
        VendorNo: Code[20];
        Codes: list of [Code[15]];
        CurrCode: Code[15];
    begin
        // [SCENARIO 378777] "SvProd" is not exported for special "VAT Entry Type" codes ("19", "20", "27", "28")
        Initialize();

        // [GIVEN] Purchase VAT Ledger with several lines with special "VAT Entry Type" values = {"19", "20", "27", "28"}
        VendorNo := CreateVendor(VendorType::Company);
        MockVATLedger(VATLedger);
        GetVATEntryTypeSpecialCodes(Codes);
        foreach CurrCode in Codes do
            MockVendorVATLedgerLine(VATLedger, VendorNo, CurrCode);

        // [WHEN] Export Purchase VAT Ledger XML
        Commit();
        EnqueueReportParameters(false, 0, false);
        RunVATLedgerExportXML(VATLedger, false);

        // [THEN] XML doesn't contain node "SvProd"
        LibraryXPathXMLReader.Initialize(GetFullFileName(false), '');
        LibraryXPathXMLReader.VerifyNodeAbsence(
          GetXPathPurchLedger(false) + GetXPathPurchLedgerLine(false) + '/' + SvProdTxt);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        LibraryRUReports.UpdateCompanyTypeInfo(CompanyType::Organization);
        UpdatePostedVATAgentNoSeriesPurchSetup(LibraryERM.CreateNoSeriesCode());

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure InitializeXMLFile(AddSheet: Boolean)
    begin
        LibraryXPathXMLReader.Initialize(GetFullFileName(AddSheet), '');
    end;

    local procedure CopyDocument(PurchHeader: Record "Purchase Header"; DocNo: Code[20])
    var
        CopyPurchDocument: Report "Copy Purchase Document";
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo";
    begin
        CopyPurchDocument.SetPurchHeader(PurchHeader);
        CopyPurchDocument.InitializeRequest(DocType::"Posted Invoice", DocNo, false, false);
        CopyPurchDocument.UseRequestPage(false);
        CopyPurchDocument.Run();
    end;

    local procedure CreateVendor(Type: Option): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryRUReports.UpdateVendorType(Vendor."No.", Type);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; VendorNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryRUReports.CreatePurchaseHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo, CurrencyCode);
    end;

    local procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; VATRate: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandDec(10, 2));
        PurchLine.Validate("VAT %", VATRate);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATLedgerMgt.GetVATPctRate2019);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryRUReports.UpdateCustomerPrepmtAccountVATRate(CustomerNo, VATLedgerMgt.GetVATPctRate2019);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, 0), LibraryRandom.RandInt(5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchLineWithGLAccount(var PurchHeader: Record "Purchase Header"; GLAccountNo: Code[20]; var Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccountNo,
          LibraryRandom.RandDec(10, 2));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        Amount := PurchLine."Amount Including VAT";
    end;

    local procedure CreateAndPostPurchInvoice(var VendorNo: Code[20]; CurrencyCode: Code[10]; VATRate: Decimal; AddSheet: Boolean; VendorType: Option): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        VendorNo := CreateVendor(VendorType);
        CreatePurchHeader(PurchHeader, VendorNo, CurrencyCode);
        if AddSheet then
            UpdateAddSheetVATInvoiceInfo(PurchHeader);
        CreatePurchLine(PurchHeader, VATRate);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateAndPostPurchInvoiceFullVAT(var VendorNo: Code[20]; var Amount: Decimal; VendVATInvNo: Code[30]; VendorVATInvDate: Date; Type: Option): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        GLAccountNo :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        UpdateVATPostingSetupFullVAT(VATPostingSetup, GLAccountNo);
        VendorNo :=
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibraryRUReports.UpdateVendorType(VendorNo, Type);

        CreatePurchHeader(PurchHeader, VendorNo, '');
        UpdateVATInvoiceInfo(PurchHeader, VendVATInvNo, VendorVATInvDate);
        CreatePurchLineWithGLAccount(PurchHeader, GLAccountNo, Amount);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateAndPostPurchInvoiceMultiLines(var VendorNo: Code[20]; CurrencyCode: Code[10]; VendorType: Option; NormalVATRate: Decimal) DocumentNo: Code[20]
    begin
        DocumentNo := LibraryRUReports.CreatePostPurchaseInvoiceMultiLines(VendorNo, CurrencyCode, NormalVATRate);
        LibraryRUReports.UpdateVendorType(VendorNo, VendorType);
    end;

    local procedure CreatePostCorrRevPurchInvoice(VendorNo: Code[20]; DocNo: Code[20]; Correction: Boolean): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        CreatePurchHeader(PurchHeader, VendorNo, '');
        if Correction then begin
            UpdateCorrectionInfo(
              PurchHeader, PurchHeader."Corrective Doc. Type"::Correction, PurchHeader."Corrected Doc. Type"::Invoice, DocNo);
            CreatePurchLine(PurchHeader, VATLedgerMgt.GetVATPctRate2019);
        end else begin
            UpdateRevisionInfo(PurchHeader, PurchHeader."Corrected Doc. Type"::Invoice, DocNo);
            CopyDocument(PurchHeader, DocNo);
        end;
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreatePaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; AppliedInvoiceNo: Code[20]; AppliedAmount: Decimal; PostingDate: Date)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo, AppliedAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedInvoiceNo);
        GenJournalLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePrepaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; PrepDocNo: Code[20]; PrepaymentAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, PrepaymentAmount);
        GenJournalLine.Validate(Prepayment, true);
        GenJournalLine.Validate("Prepayment Document No.", PrepDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateGenJnlBatchWithBalanceAccount(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := LibraryERM.CreateGLAccountNo();
        GenJournalBatch.Modify();
    end;

    local procedure CreateVATSettlementJournalLine(VATEntry: Record "VAT Entry")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryRUReports.CreateVATSettlementTemplateAndBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, 0, 0, '', 0);
        with GenJournalLine do begin
            Validate("Unrealized VAT Entry No.", VATEntry."Entry No.");
            Validate("Posting Date", VATEntry."Posting Date");
            Validate(Amount, -VATEntry."Remaining Unrealized Amount");
            Validate("External Document No.", VATEntry."External Document No.");
            Modify();
        end;
        LibraryRUReports.PostVATSettlement(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
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

    local procedure MockVATLedger(var VATLedger: Record "VAT Ledger")
    begin
        VATLedger.Init();
        VATLedger.Type := VATLedger.Type::Purchase;
        VATLedger.Code := LibraryUtility.GenerateGUID();
        VATLedger.Insert();
    end;

    local procedure MockVendorVATLedgerLine(VATLedger: Record "VAT Ledger"; VendorNo: Code[20]; VATEntryType: Code[15])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.Init();
        VATLedgerLine.Type := VATLedger.Type;
        VATLedgerLine.Code := VATLedger.Code;
        VATLedgerLine."Line No." := LibraryUtility.GetNewRecNo(VATLedgerLine, VATLedgerLine.FIELDNO("Line No."));
        VATLedgerLine."VAT Entry Type" := VATEntryType;
        VATLedgerLine."C/V Type" := VATLedgerLine."C/V Type"::Vendor;
        VATLedgerLine."C/V No." := VendorNo;
        VATLedgerLine.Insert();
    end;

    local procedure EnqueueReportParameters(AddSheet: Boolean; CorrectionNo: Integer; IsPrevDataRelevant: Boolean)
    begin
        LibraryVariableStorage.Enqueue(CorrectionNo);
        LibraryVariableStorage.Enqueue(IsPrevDataRelevant);
        LibraryVariableStorage.Enqueue(AddSheet);
    end;

    local procedure FormatValue(Value: Decimal): Text
    begin
        exit(LibraryRUReports.FormatAmountXML(Value));
    end;

    local procedure GetActCriteria(IsPrevDataRelevant: Boolean): Text[1]
    begin
        if IsPrevDataRelevant then
            exit('1');
        exit('0')
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
        exit;
    end;

    local procedure GetFileName(AddSheet: Boolean): Text
    var
        VATLedger: Record "VAT Ledger";
    begin
        exit(LocalReportMgt.GetVATLedgerXMLFileName(VATLedger.Type::Purchase, AddSheet));
    end;

    local procedure GetFullFileName(AddSheet: Boolean): Text
    var
        FullFileName: Text;
    begin
        FullFileName := TemporaryPath;
        if CopyStr(FullFileName, StrLen(FullFileName), 1) <> '\' then
            FullFileName += '\';
        FullFileName += GetFileName(AddSheet) + '.xml';

        exit(FullFileName);
    end;

    local procedure GetXPathPurchLedger(AddSheet: Boolean): Text
    begin
        if AddSheet then
            exit('/' + FileTxt + '/' + DocumentTxt + '/' + KnigaPokupDLTxt);

        exit('/' + FileTxt + '/' + DocumentTxt + '/' + KnigaPokupTxt);
    end;

    local procedure GetXPathPurchLedgerLine(AddSheet: Boolean): Text
    begin
        if AddSheet then
            exit('/' + KnPokDLStrTxt);

        exit('/' + KnPokStrTxt);
    end;

    local procedure GetSalesInvHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; CustomerNo: Code[20])
    begin
        with SalesInvoiceHeader do begin
            SetRange("Sell-to Customer No.", CustomerNo);
            SetRange("Prepayment Invoice", false);
            FindFirst();
            CalcFields(Amount, "Amount Including VAT");
        end;
    end;

    local procedure GetVATEntryTypeBasicCodes(var Codes: List of [Code[15]])
    begin
        Codes.Add('01');
        Codes.Add('02');
        Codes.Add('13');
        Codes.Add('15');
        Codes.Add('22');
        Codes.Add('24');
        Codes.Add('32');
        Codes.Add('36');
        Codes.Add('45');
    end;

    local procedure GetVATEntryTypeSpecialCodes(var Codes: List of [Code[15]])
    begin
        Codes.Add('19');
        Codes.Add('20');
        Codes.Add('27');
        Codes.Add('28');
    end;

    local procedure PostPurchasePrepayment(var PurchaseHeader: Record "Purchase Header"; AmountFactor: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        CreatePrepaymentJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.",
          PurchaseHeader."No.", PurchaseHeader."Amount Including VAT" * AmountFactor);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure PostAppliedPayment(AccountNo: Code[20]; AppliedInvoiceNo: Code[20]; AppliedAmount: Decimal; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);

        CreatePaymentJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo, AppliedInvoiceNo, AppliedAmount, PostingDate);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostAndApplySalesPrepayment(var SalesHeader: Record "Sales Header"; var PmtDate: Date): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceNo: Code[20];
    begin
        // create and post prepayment
        SalesHeader.CalcFields("Amount Including VAT");
        CreatePrepaymentJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          SalesHeader."No.", -(SalesHeader."Amount Including VAT" + LibraryRandom.RandDecInRange(1000, 2000, 2)));
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(-1));
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // post invoice
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // post application
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgerEntry."Document Type"::Invoice, InvoiceNo,
          CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");

        PmtDate := GenJournalLine."Posting Date";
        exit(GenJournalLine."Document No.");
    end;

    local procedure PostTwoAppliedPayments(AccountNo: Code[20]; AppliedInvoiceNo: Code[20]; AppliedAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatchWithBalanceAccount(GenJournalBatch);

        CreatePaymentJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo, AppliedInvoiceNo, Round(AppliedAmount / 3), LibraryRandom.RandDate(5));
        CreatePaymentJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo, AppliedInvoiceNo, AppliedAmount - Round(AppliedAmount / 3), LibraryRandom.RandDate(5));

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostVATSettlementJournalLine(VendorNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATEntry.SetFilter("Unrealized Amount", '<>0');
        VATEntry.FindLast();
        CreateVATSettlementJournalLine(VATEntry);
    end;

    local procedure RunVATLedgerExportReportXML(VendorNo: Code[20]; AddSheet: Boolean; UseExternalDocNo: Boolean; TotalVATFromVATPurchLedg: Decimal; ShowCustomerPrepayments: Boolean)
    var
        VATLedger: Record "VAT Ledger";
    begin
        CreateVATLedger(VATLedger, VendorNo, AddSheet, UseExternalDocNo, TotalVATFromVATPurchLedg, ShowCustomerPrepayments);
        Commit();
        RunVATLedgerExportXML(VATLedger, AddSheet);
    end;

    local procedure RunVATLedgerExportXML(var VATLedger: Record "VAT Ledger"; AddSheet: Boolean)
    var
        VATLedgerExportXML: Report "VAT Ledger Export XML";
    begin
        VATLedgerExportXML.InitializeReport(VATLedger.Type::Purchase, VATLedger.Code, AddSheet);
        VATLedgerExportXML.SetTableView(VATLedger);
        VATLedgerExportXML.UseRequestPage(true);
        VATLedgerExportXML.Run();
    end;

    local procedure CreateVATLedger(var VATLedger: Record "VAT Ledger"; VendorNo: Code[20]; AddSheet: Boolean; UseExternalDocNo: Boolean; TotalVATFromVATPurchLedg: Decimal; ShowCustomerPrepayments: Boolean)
    var
        VATLedgerCode: Code[20];
    begin
        VATLedgerCode :=
          LibraryPurchase.CreatePurchaseVATLedger(
            WorkDate(), LibraryRandom.RandDateFromInRange(WorkDate(), 5, 10), VendorNo, UseExternalDocNo, ShowCustomerPrepayments);
        if AddSheet then
            LibraryPurchase.CreatePurchaseVATLedgerAddSheet(VATLedgerCode, TotalVATFromVATPurchLedg);
        VATLedger.Get(VATLedger.Type::Purchase, VATLedgerCode);
        UpdateVATEntryType(VATLedger);
    end;

    local procedure UpdateTariffNoToVATLedgerLine(VATLedger: Record "VAT Ledger"; TariffNo: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.FindFirst();
        VATLedgerLine.Validate("Tariff No.", TariffNo);
        VATLedgerLine.Modify(true);
    end;

    local procedure UpdateVATPostingSetupFullVAT(var VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20])
    begin
        with VATPostingSetup do begin
            Validate("VAT %", VATLedgerMgt.GetVATPctRate2019);
            Validate("Purchase VAT Account", GLAccountNo);
            Validate("VAT Calculation Type", "VAT Calculation Type"::"Full VAT");
            Modify(true);
        end;
    end;

    local procedure UpdateAddSheetVATInvoiceInfo(var PurchHeader: Record "Purchase Header")
    begin
        with PurchHeader do begin
            Validate("Posting Date", CalcDate('<1M>', WorkDate()));
            Validate("Additional VAT Ledger Sheet", true);
            Validate("Corrected Document Date", WorkDate());
            UpdateVATInvoiceInfo(PurchHeader, '', WorkDate());
        end;
    end;

    local procedure UpdateVATInvoiceInfo(var PurchHeader: Record "Purchase Header"; VendVATInvNo: Code[30]; VendorVATInvDate: Date)
    begin
        with PurchHeader do begin
            Validate("Vendor VAT Invoice No.", VendVATInvNo);
            Validate("Vendor VAT Invoice Date", VendorVATInvDate);
            Validate("Vendor VAT Invoice Rcvd Date", VendorVATInvDate);
            Modify(true);
        end;
    end;

    local procedure UpdateCorrectionInfo(var PurchHeader: Record "Purchase Header"; CorrType: Option; CorrDocType: Option; CorrDocNo: Code[20])
    begin
        with PurchHeader do begin
            Validate("Corrective Document", true);
            Validate("Corrective Doc. Type", CorrType);
            Validate("Corrected Doc. Type", CorrDocType);
            Validate("Corrected Doc. No.", CorrDocNo);
            Modify(true);
        end;
    end;

    local procedure UpdateRevisionInfo(var PurchHeader: Record "Purchase Header"; CorrDocType: Option; CorrDocNo: Code[20])
    begin
        with PurchHeader do begin
            UpdateCorrectionInfo(PurchHeader, "Corrective Doc. Type"::Revision, CorrDocType, CorrDocNo);
            Validate("Revision No.", LibraryUtility.GenerateGUID());
            Validate("Posting Date", CalcDate('<1D>', WorkDate()));
            Modify(true);
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

    local procedure VerifyVATLedgExportXML(InvNo: Code[20]; LineIndex: Integer; DocumentType: Option ,Revision,Correction,RevOfCorrection; VendorType: Option; AddSheet: Boolean; CorrectionNo: Integer; IsPrevDataRelevant: Boolean; TotalVATFromVATPurchLedg: Decimal)
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        if DocumentType = DocType::" " then
            GetVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Purchase, VATLedgerLine."Document Type"::Invoice, InvNo)
        else
            GetCorrectionVATLedgerLine(
              VATLedgerLine, VATLedgerLine.Type::Purchase, VATLedgerLine."Document Type"::Invoice,
              InvNo, DocumentType);

        if LineIndex = 1 then begin
            InitializeXMLFile(AddSheet);
            VerifyFileElement(AddSheet);
            VerifyDocument(AddSheet, CorrectionNo, IsPrevDataRelevant);
            if not IsPrevDataRelevant then
                VerifyPurchaseLedger(VATLedgerLine, AddSheet, TotalVATFromVATPurchLedg);
        end;

        if not IsPrevDataRelevant then begin
            VerifyPurchaseLedgerLine(VATLedgerLine, LineIndex, AddSheet);
            VerifyPaymentDocument(VATLedgerLine, LineIndex, AddSheet);
            VerifyVendorInformation(VATLedgerLine."C/V No.", LineIndex, VendorType, AddSheet);
        end;
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

    local procedure VerifyDocument(AddSheet: Boolean; CorrectionNo: Integer; IsPrevDataRelevant: Boolean)
    var
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath('/' + FileTxt + '/' + DocumentTxt, XMLNode);
        if AddSheet then begin
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, IndexTxt, '0000081'); // Hardcoded value: 0000081
            if CorrectionNo > 0 then
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, PriznSvedTxt + '81', GetActCriteria(IsPrevDataRelevant));
        end else begin
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, IndexTxt, '0000080'); // Hardcoded value: 0000080
            if CorrectionNo > 0 then
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, PriznSvedTxt + '8', GetActCriteria(IsPrevDataRelevant));
        end;

        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, NomCorrTxt, Format(CorrectionNo));
    end;

    local procedure VerifyPurchaseLedgerLine(VATLedgerLine: Record "VAT Ledger Line"; LineIndex: Integer; AddSheet: Boolean)
    var
        XMLNode: DotNet XmlNode;
        PurchaseLedgerLinexPath: Text;
    begin
        PurchaseLedgerLinexPath := GetXPathPurchLedger(AddSheet) + GetXPathPurchLedgerLine(AddSheet) + '[' + Format(LineIndex) + ']';

        LibraryXPathXMLReader.GetNodeByXPath(PurchaseLedgerLinexPath, XMLNode);
        with VATLedgerLine do begin
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, NomerPorTxt, Format(LineIndex));
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, NomScFProdTxt, Format("Document No."));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, DataScFProdTxt, GetFormattedDate("Document Date"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, NomIsprScFTxt, Format("Revision No."));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, DataIsprScFTxt, GetFormattedDate("Revision Date"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, NomKScFProdTxt, Format("Correction No."));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, DataKScFProdTxt, GetFormattedDate("Correction Date"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, NomIsprKScFTxt, Format("Revision of Corr. No."));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, DataIsprKScFTxt, GetFormattedDate("Revision of Corr. Date"));
            LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(XMLNode, NomTDTxt, Format("CD No."));

            // TFS 378442: "OKV", "StoimPokupV"
            if LocalReportMgt.IsForeignCurrency("Currency Code") and
               not LocalReportMgt.IsConventionalCurrency("Currency Code") and
               not LocalReportMgt.HasRelationalCurrCode("Currency Code", "Document Date")
            then begin
                LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(
                  XMLNode, OKVTxt, Format(LibraryRUReports.GetCurrencyCode("Currency Code")));
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, StoimPokupVTxt, FormatValue(Amount));
            end else begin
                LibraryXPathXMLReader.VerifyAttributeAbsenceFromNode(XMLNode, OKVTxt);
                LibraryXPathXMLReader.VerifyAttributeFromNode(
                  XMLNode, StoimPokupVTxt, LocalReportMgt.GetVATLedgerAmounInclVATFCY(VATLedgerLine));
            end;

            if AddSheet then
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, SumNDSTxt, FormatValue(Amount10 + Amount18 + Amount20))
            else
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, SumNDSVicTxt, FormatValue(Amount10 + Amount18 + Amount20));

            LibraryXPathXMLReader.VerifyNodeValueByXPath(PurchaseLedgerLinexPath + '/' + KodVidOperTxt, "VAT Entry Type");
            if "Tariff No." <> '' then
                LibraryXPathXMLReader.VerifyNodeValueByXPath(PurchaseLedgerLinexPath + '/' + KodVidTovarTxt, "Tariff No.");
            LibraryXPathXMLReader.VerifyNodeValueByXPath(
              PurchaseLedgerLinexPath + '/' + DataUcTovTxt, GetFormattedDate("Unreal. VAT Entry Date"));
        end;
    end;

    local procedure VerifyPurchaseLedger(VATLedgerLine: Record "VAT Ledger Line"; AddSheet: Boolean; TotalVATFromVATPurchLedg: Decimal)
    var
        VATLedgerLineSum: Record "VAT Ledger Line";
        XMLNode: DotNet XmlNode;
        TotalVATLCY: Decimal;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(GetXPathPurchLedger(AddSheet), XMLNode);
        with VATLedgerLineSum do begin
            SetRange(Type, VATLedgerLine.Type);
            SetRange(Code, VATLedgerLine.Code);
            SetRange("Additional Sheet", AddSheet);
            if FindSet() then
                repeat
                    TotalVATLCY += Amount10 + Amount18 + Amount20;
                until Next() = 0;
        end;

        if AddSheet then begin
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, SumNDSItKPkTxt, FormatValue(TotalVATFromVATPurchLedg));
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, SumNDSItP1R8Txt, FormatValue(TotalVATLCY + TotalVATFromVATPurchLedg))
        end else
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, SumNDSVsKPkTxt, FormatValue(TotalVATLCY + TotalVATFromVATPurchLedg))
    end;

    local procedure VerifyPaymentDocument(VATLedgerLine: Record "VAT Ledger Line"; LineIndex: Integer; AddSheet: Boolean)
    begin
        with VATLedgerLine do
            case true of
                Prepayment:
                    VerifyPaymentXmlNode(LineIndex, "External Document No.", "Payment Date", AddSheet);
                "Full VAT Amount" <> 0:
                    VerifyPaymentXmlNode(LineIndex, "Payment Doc. No.", "Payment Date", AddSheet);
            end;
    end;

    local procedure VerifyPaymentXmlNode(LineIndex: Integer; ExpectedDocNo: Text; ExpectedDocDate: Date; AddSheet: Boolean)
    var
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          GetXPathPurchLedger(AddSheet) + GetXPathPurchLedgerLine(AddSheet) +
          '[' + Format(LineIndex) + ']/' + DocPdtvUplTxt, XMLNode);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, NomDocPdtvUplTxt, ExpectedDocNo);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, DataDocPdtvUplTxt, GetFormattedDate(ExpectedDocDate));
    end;

    local procedure VerifyPaymentAmount(LineIndex: Integer; PaymentNo: Code[20]; AddSheet: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          GetXPathPurchLedger(AddSheet) + GetXPathPurchLedgerLine(AddSheet) + '[' + Format(LineIndex) + ']', XMLNode);

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        VendorLedgerEntry.CalcFields(Amount);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, StoimPokupVTxt, Format(VendorLedgerEntry.Amount));
    end;

    local procedure VerifyAppliedPaymentDocumentsWithFullVAT(VendorNo: Code[20]; AddSheet: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLNode: DotNet XmlNode;
        LineIndex: Integer;
    begin
        InitializeXMLFile(AddSheet);
        LineIndex := 1;
        with VendorLedgerEntry do begin
            SetRange("Vendor No.", VendorNo);
            SetRange("Document Type", "Document Type"::Payment);
            FindSet();
            repeat
                LibraryXPathXMLReader.GetNodeByXPath(
                  GetXPathPurchLedger(AddSheet) + GetXPathPurchLedgerLine(AddSheet) +
                  '/' + DocPdtvUplTxt + '[' + Format(LineIndex) + ']', XMLNode);
                LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, NomDocPdtvUplTxt, "External Document No.");
                LibraryXPathXMLReader.VerifyAttributeFromNode(
                  XMLNode, DataDocPdtvUplTxt, GetFormattedDate("Posting Date"));
                LineIndex += 1;
            until Next() = 0;
        end;
    end;

    local procedure VerifyVendorInformation(VendorNo: Code[20]; LineIndex: Integer; Type: Option; AddSheet: Boolean)
    var
        Vendor: Record Vendor;
        XMLNode: DotNet XmlNode;
    begin
        Vendor.Get(VendorNo);
        if Type = VendorType::Person then begin
            LibraryXPathXMLReader.GetNodeByXPath(
              GetXPathPurchLedger(AddSheet) + GetXPathPurchLedgerLine(AddSheet) +
              '[' + Format(LineIndex) + ']/' + SvProdTxt + '/' + SvedIPTxt, XMLNode);
            LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, INNFLTxt, Vendor."VAT Registration No.");
            LibraryXPathXMLReader.VerifyAttributeAbsenceFromNode(XMLNode, KPPTxt)
        end else
            VerifyVATRegNoAndKPP(LineIndex, Vendor."VAT Registration No.", Vendor."KPP Code", AddSheet);
    end;

    local procedure VerifyVATRegNoAndKPP(LineIndex: Integer; ExpectedVATRegNo: Text; ExpectedKPP: Text; AddSheet: Boolean)
    var
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          GetXPathPurchLedger(AddSheet) + GetXPathPurchLedgerLine(AddSheet) +
          '[' + Format(LineIndex) + ']/' + SvProdTxt + '/' + SvedULTxt, XMLNode);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, INNULTxt, ExpectedVATRegNo);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, KPPTxt, ExpectedKPP);
    end;

    local procedure VerifyCustomerPrepayment(PrepmtDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLNode: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.GetNodeByXPath(
          GetXPathPurchLedger(false) + GetXPathPurchLedgerLine(false) + '[1]', XMLNode);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PrepmtDocNo);
        CustLedgerEntry.CalcFields(Amount);
        LibraryXPathXMLReader.VerifyAttributeFromNode(XMLNode, StoimPokupVTxt, FormatValue(Abs(CustLedgerEntry.Amount)));

        GetSalesInvHeader(SalesInvoiceHeader, CustLedgerEntry."Customer No.");
        LibraryXPathXMLReader.VerifyAttributeFromNode(
          XMLNode, SumNDSVicTxt, FormatValue(SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHPurchVATLedgerExpXML(var VATLedgerExportXML: TestRequestPage "VAT Ledger Export XML")
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
        VATLedgerExportXML.FileName.AssertEquals(GetFileName(LibraryVariableStorage.DequeueBoolean()));

        VATLedgerExportXML.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PHErrorsPurchVATLedgerExpXML(var ErrorMessages: Page "Error Messages")
    var
        Vendor: Record Vendor;
        ErrorMsgRec: Record "Error Message";
        VendorNo: Variant;
    begin
        ErrorMsgRec.Init();
        ErrorMessages.GetRecord(ErrorMsgRec);
        LibraryVariableStorage.Dequeue(VendorNo);
        Assert.AreEqual(
          StrSubstNo(BlankVendorNoErr, Vendor.FieldCaption("VAT Registration No."), Vendor.TableCaption(), VendorNo),
          Format(ErrorMsgRec.Description), NoVATRegNoErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MHConfirmMessage(Message: Text[1024])
    begin
    end;
}

