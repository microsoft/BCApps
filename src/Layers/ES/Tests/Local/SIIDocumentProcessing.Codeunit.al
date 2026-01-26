codeunit 147522 "SII Document Processing"
{
    // // [FEATURE] [SII]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryService: Codeunit "Library - Service";
        IsInitialized: Boolean;
        TagMustNotExistErr: Label '%1 must not exist';
        FieldMustNotBeErr: Label '%1 must not be %2', Locked = true;
        SiiRLUrlTok: Label 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroLR.xsd';
        SiiUrlTok: Label 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroInformacion.xsd';
        SoapenvUrlTok: Label 'http://schemas.xmlsoap.org/soap/envelope/';
        XPathPrestacionServiciosTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/sii:PrestacionServicios';
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        XPathSalesFacturaExpedidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/';
        XPathPurchFacturaRecibidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/';
        MarkAsNotAcceptedErr: Label 'Marked as not accepted';
        MarkAsAcceptedErr: Label 'Marked as accepted';
        CertificateUsedInSIISetupQst: Label 'A certificate is used in the SII Setup. Do you really want to delete the certificate?';
        FieldMustHaveValueInSIISetupErr: Label '%1 must have a value in SII VAT Setup', Comment = '%1 = field caption';
        StatusErr: Label 'Valor o tipo incorrecto del campo: IDType';
        DifferentValueErr: Label 'Expected Value are different than the actual value.';

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithTypeF5()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Purchase]
        // [SCENARIO 220620] Cassie can post purchase invoice with "Invoice Type" = "F5 Imports (DUA)" without sending to web service
        // [SCENARIO 233508] Purchase Invoice with "Invoice Type" = "F5 Imports (DUA)" is supported
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase invoice with "Invoice Type" = "F5 Imports (DUA)"
        CreatePurchInvoiceWithType(PurchaseHeader, PurchaseHeader."Invoice Type"::"F5 Imports (DUA)");

        // [GIVEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Journal] [Sales] [Invoice]
        // [SCENARIO] Posting customer's invoice generates SII Doc. Upload State entry when SII Setup is enabled
        // [SCENARIO 375398] SII Version is 1.1bis in SII Doc. Upload State generated from sales invoice

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Invoice" for customer
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandIntInRange(100, 200));
        // [GIVEN] ID Type is "02"
        // BUG 408435: ID Type must be copied from General Journal Line to SII Doc. Upload State
        GenJournalLine.Validate("ID Type", GenJournalLine."ID Type"::"02-VAT Registration No.");
        GenJournalLine.Modify(true);

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [THEN] SII Doc. Upload State in state "Pending" is created
        LibrarySII.FindSIIDocUploadState(
            SIIDocUploadState, SIIDocUploadState."Document Source"::"Customer Ledger", SIIDocUploadState."Document Type"::Invoice, GenJournalLine."Document No.");
        SIIDocUploadState.TestField(Status, SIIDocUploadState.Status::Pending);

        // [THEN] Version of SII Doc. Upload State is 1.1bis
        SIIDocUploadState.TestField("Version No.", SIIDocUploadState."Version No."::"2.1");

        // [THEN] ID Type of SII Doc. Upload State is "02"
        SIIDocUploadState.TestField(IDType, SIIDocUploadState.IDType::"02-VAT Registration No.");

        // [THEN] The SII job queue entry has been created
        // TFS ID 402592: Job Queue Entry triggers on general journal line posting with "Document Type" = Invoice
        VerifySIIJobQueueEntryCount(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceFromJournalVersion11()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        OldWorkDate: Date;
    begin
        // [FEATURE] [Journal] [Sales] [Invoice]
        // [SCENARIO] Posting customer's invoice generates SII Doc. Upload State entry when SII Setup is enabled
        // [SCENARIO 375398] SII Version is 1.1 in SII Doc. Upload State generated from sales invoice when work date is before year 2021

        Initialize();

        // [GIVEN] Work date is 31.12.2020
        OldWorkDate := WorkDate();
        WorkDate := 20201231D;

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Invoice" for customer
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [THEN] SII Doc. Upload State in state "Pending" is created
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Customer Ledger", SIIDocUploadState."Document Type"::Invoice, GenJournalLine."Document No.");
        SIIDocUploadState.TestField(Status, SIIDocUploadState.Status::Pending);

        // [THEN] Version of SII Doc. Upload State is 1.1
        SIIDocUploadState.TestField("Version No.", SIIDocUploadState."Version No."::"1.1");

        // Tear down
        WorkDate := OldWorkDate;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Journal] [Purchae] [Invoice]
        // [SCENARIO] Posting vendor's invoice generates SII Doc. Upload State entry when SII Setup is enabled
        // [SCENARIO 375398] SII Version is 1.1bis in SII Doc. Upload State generated from purchase invoice
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Invoice" for vendor
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandIntInRange(100, 200));
        // [GIVEN] ID Type is "02"
        // BUG 408435: ID Type must be copied from General Journal Line to SII Doc. Upload State
        GenJournalLine.Validate("ID Type", GenJournalLine."ID Type"::"02-VAT Registration No.");
        GenJournalLine.Modify(true);

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [THEN] SII Doc. Upload State in state "Pending" is created
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Vendor Ledger", SIIDocUploadState."Document Type"::Invoice, GenJournalLine."Document No.");
        SIIDocUploadState.TestField(Status, SIIDocUploadState.Status::Pending);

        // [THEN] Version of SII Doc. Upload State is 1.1bis
        SIIDocUploadState.TestField("Version No.", SIIDocUploadState."Version No."::"2.1");

        // [THEN] ID Type of SII Doc. Upload State is "02"
        SIIDocUploadState.TestField(IDType, SIIDocUploadState.IDType::"02-VAT Registration No.");

        // [THEN] The SII job queue entry has been created
        // TFS ID 402592: Job Queue Entry triggers on general journal line posting with "Document Type" = Invoice
        VerifySIIJobQueueEntryCount(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Journal] [Sales] [Credit Memo]
        // [SCENARIO] Posting customer's credit memo generates SII Doc. Upload State entry when SII Setup is enabled
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Credit Memo" for customer
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Customer Ledger", SIIDocUploadState."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        SIIDocUploadState.TestField(Status, SIIDocUploadState.Status::Pending);

        // [THEN] The SII job queue entry has been created
        // TFS ID 402592: Job Queue Entry triggers on general journal line posting with "Document Type" = Invoice
        VerifySIIJobQueueEntryCount(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCreditMemoFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Journal] [Purchase] [Credit Memo]
        // [SCENARIO] Posting vendor's credit memo generates SII Doc. Upload State entry when SII Setup is enabled
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Journal line with type "Credit Memo" for vendor
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Vendor Ledger", SIIDocUploadState."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        SIIDocUploadState.TestField(Status, SIIDocUploadState.Status::Pending);

        // [THEN] The SII job queue entry has been created
        // TFS ID 402592: Job Queue Entry triggers on general journal line posting with "Document Type" = Invoice
        VerifySIIJobQueueEntryCount(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoFromJournalXml()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Journal] [Sales] [Credit Memo]
        // [SCENARIO 221933] Stan can generte SII XML file for Posted Sales Credit Memo created from Journal

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Posted Credit Memo from Journal
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), -LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");

        // [WHEN] Generated XML file for Posted Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] XML File contains "Document No." and type of correction "I"
        ValidateElementByName(XMLDoc, 'sii:TipoRectificativa', 'I');
        ValidateElementByName(XMLDoc, 'sii:NumSerieFacturaEmisor', CustLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoFromJournalXml()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Journal] [Purchase] [Credit Memo]
        // [SCENARIO 221933] Stan can generate SII XML file for Posted Purch Credit Memo created from Journal

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Posted Credit Memo from Journal
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");

        // [WHEN] Generated XML file for Posted Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] XML File contains "Document No." and type of correction "I"
        ValidateElementByName(XMLDoc, 'sii:TipoRectificativa', 'I');
        ValidateElementByName(XMLDoc, 'sii:NumSerieFacturaEmisor', VendorLedgerEntry."External Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyRegularSIIHistoryEntryCreatesWhenPostIntracommunitySalesDoc()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        // [FEATURE] [Intracommunity] [UT] [Sales]
        // [SCENARIO] Only SII History with "Upload Type" equals "Intracommunity" creates when create request for document with Intracommunity customer

        Initialize();

        // [GIVEN] Customer Ledger Entry with Intracommunity Customer
        MockCustLedgEntryWithIntracommunityCust(CustLedgerEntry);

        // [WHEN] Create new SII request for Customer Ledger Entry
        SIIDocUploadState.CreateNewRequest(
          CustLedgerEntry."Entry No.", SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(), CustLedgerEntry."Document Type".AsInteger(),
          CustLedgerEntry."Document No.", CustLedgerEntry."External Document No.", CustLedgerEntry."Posting Date");

        FilterSIIHistory(
          SIIHistory, "SII Doc. Upload State Document Type"::Invoice,
          CustLedgerEntry."Document No.", SIIDocUploadState."Document Source"::"Customer Ledger");

        // [THEN] SII History Entry with type "Regular" is created
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Regular);
        Assert.RecordIsNotEmpty(SIIHistory);

        // [THEN] SII History Entry with type "Intracommunity" is not created
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Intracommunity);
        Assert.RecordIsEmpty(SIIHistory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyRegularSIIHistoryEntryCreatesWhenPostIntracommunityPurchDoc()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        // [FEATURE] [Intracommunity] [UT] [Purchase]
        // [SCENARIO] Only SII History with "Upload Type" equals "Intracommunity" creates when create request for document with Intracommunity vendor

        Initialize();

        // [GIVEN] Vendor Ledger Entry with Intracommunity Vendor
        MockVendLedgEntryWithIntracommunityVend(VendorLedgerEntry);

        // [WHEN] Create new SII request for Vendor Ledger Entry
        SIIDocUploadState.CreateNewRequest(
          VendorLedgerEntry."Entry No.", SIIDocUploadState."Document Source"::"Vendor Ledger".AsInteger(), VendorLedgerEntry."Document Type".AsInteger(),
          VendorLedgerEntry."Document No.", VendorLedgerEntry."External Document No.", VendorLedgerEntry."Posting Date");

        FilterSIIHistory(
          SIIHistory, "SII Doc. Upload State Document Type"::Invoice, VendorLedgerEntry."Document No.",
          SIIDocUploadState."Document Source"::"Vendor Ledger");

        // [THEN] SII History Entry with type "Regular" is created
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Regular);
        Assert.RecordIsNotEmpty(SIIHistory);

        // [THEN] SII History Entry with type "Intracommunity" is not created
        SIIHistory.SetRange("Upload Type", SIIHistory."Upload Type"::Intracommunity);
        Assert.RecordIsEmpty(SIIHistory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithTypeF3()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 220620] It must be possible to post Sales Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        // [SCENARIO 233508] Sales Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices" is supported

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        CreateSalesInvoiceWithType(SalesHeader, SalesHeader."Invoice Type"::"F3 Invoice issued to replace simplified invoices");

        // [GIVEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithTypeF4()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 220620] It must be possible to post Sales Invoice with "Invoice Type" = "F4 Invoice summary entry"
        // [SCENARIO 233508] Sales Invoice with "Invoice Type" = "F4 Invoice summary entry" is supported

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales invoice with "Invoice Type" = "F4 Invoice summary entry"
        CreateSalesInvoiceWithType(SalesHeader, SalesHeader."Invoice Type"::"F4 Invoice summary entry");

        // [GIVEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithTypeF3()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Purchase]
        // [SCENARIO 220620] Cassie can post purchase invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices" without sending to web service
        // [SCENARIO 233508] Purchase Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices" is supported
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        CreatePurchInvoiceWithType(PurchaseHeader, PurchaseHeader."Invoice Type"::"F3 Invoice issued to replace simplified invoices");

        // [GIVEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithTypeF4()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Purchase]
        // [SCENARIO 220620] Cassie can post purchase invoice with "Invoice Type" = "F4 Invoice summary entry" without sending to web service
        // [SCENARIO 233508] Purchase Invoice with "Invoice Type" = "F4 Invoice summary entry" is supported
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase invoice with "Invoice Type" = "F4 Invoice summary entry"
        CreatePurchInvoiceWithType(
          PurchaseHeader, PurchaseHeader."Invoice Type"::"F4 Invoice summary entry");

        // [GIVEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithTypeF6()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Purchase]
        // [SCENARIO 220620] Cassie can post purchase invoice with "Invoice Type" = "F6 Accounting support material" without sending to web service
        // [SCENARIO 233508] Purchase Invoice with "Invoice Type" = "F6 Accounting support material" is supported
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase invoice with "Invoice Type" = "F6 Accounting support material"
        CreatePurchInvoiceWithType(
          PurchaseHeader, PurchaseHeader."Invoice Type"::"F6 Accounting support material");

        // [GIVEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCrMemoWithTypeR2()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 220620] It must be possible to post Sales Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [SCENARIO 233508] Sales Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)" is supported

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        CreateSalesCrMemoWithType(
          SalesHeader, SalesHeader."Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCrMemoWithTypeR3()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 220620] It must be possible to post Sales Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        // [SCENARIO 233508] Sales Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)" is supported

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        CreateSalesCrMemoWithType(
          SalesHeader, SalesHeader."Cr. Memo Type"::"R3 Corrected Invoice (Art. 80.4)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCrMemoWithTypeR4()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 220620] It must be possible to post Sales Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        // [SCENARIO 233508] Sales Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)" is supported

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Sales Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        CreateSalesCrMemoWithType(
          SalesHeader, SalesHeader."Cr. Memo Type"::"R4 Corrected Invoice (Other)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCrMemoWithTypeR2()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 220620] Cassie can post purchase Credit Memo with "Invoice Type" = "R2 Corrected Invoice (Art. 80.3)" without sending to web service
        // [SCENARIO 233508] Purchase Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)" is supported

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase Credit Memo with "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        CreatePurchCrMemoWithType(PurchaseHeader, PurchaseHeader."Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCrMemoWithTypeR3()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 220620] Cassie can post purchase Credit Memo with "Invoice Type" = "R3 Corrected Invoice (Art. 80.4)" without sending to web service
        // [SCENARIO 233508] Purchase Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)" is supported
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase Credit Memo with "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        CreatePurchCrMemoWithType(PurchaseHeader, PurchaseHeader."Cr. Memo Type"::"R3 Corrected Invoice (Art. 80.4)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseCrMemoWithTypeR4()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 220620] Cassie can post purchase Credit Memo with "Invoice Type" = "R4 Corrected Invoice (Other)" without sending to web service
        // [SCENARIO 233508] Purchase Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)" is supported

        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] Purchase Credit Memo with "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        CreatePurchCrMemoWithType(PurchaseHeader, PurchaseHeader."Cr. Memo Type"::"R4 Corrected Invoice (Other)");

        // [GIVEN] Post Credit Memo
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] Generated "SII Doc. Upload State" entry for posted document has "Status" is not "Not supported"
        VerifySIIHistoryByStateIdIsSupported(
          SIIHistory, SIIDocUploadState."Document Type"::"Credit Memo", DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedPurchInvoiceoRefersToSIIDocUploadState()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Purchase Invoice refers to status of related "SII Doc. Upload State" record

        Initialize();

        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchInvHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Vendor Ledger",
          SIIDocUploadState."Document Type"::Invoice, PurchInvHeader."No.");

        PurchInvHeader.CalcFields("SII Status", "Sent to SII");
        PurchInvHeader.TestField("SII Status", PurchInvHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        PurchInvHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedSalesInvoiceRefersToSIIDocUploadState()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Sales Invoice refers to status of related "SII Doc. Upload State" record

        Initialize();

        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::Invoice, SalesInvoiceHeader."No.");

        SalesInvoiceHeader.CalcFields("SII Status", "Sent to SII");
        SalesInvoiceHeader.TestField("SII Status", SalesInvoiceHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        SalesInvoiceHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedServInvoiceRefersToSIIDocUploadState()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Service] [Invoice] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Service Invoice refers to status of related "SII Doc. Upload State" record

        Initialize();

        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::Invoice, ServiceInvoiceHeader."No.");

        ServiceInvoiceHeader.CalcFields("SII Status", "Sent to SII");
        ServiceInvoiceHeader.TestField("SII Status", ServiceInvoiceHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        ServiceInvoiceHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedPurchCreditMemoRefersToSIIDocUploadState()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Purchase Credit Memo refers to status of related "SII Doc. Upload State" record

        Initialize();

        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."No." := LibraryUtility.GenerateGUID();
        PurchCrMemoHdr.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Vendor Ledger",
          SIIDocUploadState."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");

        PurchCrMemoHdr.CalcFields("SII Status", "Sent to SII");
        PurchCrMemoHdr.TestField("SII Status", PurchCrMemoHdr."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        PurchCrMemoHdr.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedSalesCreditMemoRefersToSIIDocUploadState()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Credit Memo] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Sales Credit Memo refers to status of related "SII Doc. Upload State" record

        Initialize();

        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::"Credit Memo", SalesCrMemoHeader."No.");

        SalesCrMemoHeader.CalcFields("SII Status", "Sent to SII");
        SalesCrMemoHeader.TestField("SII Status", SalesCrMemoHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        SalesCrMemoHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIStatusOfPostedServCreditMemoRefersToSIIDocUploadState()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Service] [Credit Memo] [UT]
        // [SCENARIO 224053] "SII Status" of Posted Service Credit Memo refers to status of related "SII Doc. Upload State" record

        Initialize();

        ServiceCrMemoHeader.Init();
        ServiceCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        ServiceCrMemoHeader.Insert();

        MockSIIDocUploadStateWithIncorrectStatus(
          SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");

        ServiceCrMemoHeader.CalcFields("SII Status", "Sent to SII");
        ServiceCrMemoHeader.TestField("SII Status", ServiceCrMemoHeader."SII Status"::Incorrect);

        // TFS ID 351319: A document sent to sii has value "Sent to SII"
        ServiceCrMemoHeader.TestField("Sent to SII");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLRequestEUServiceReverseChargeVATSalesInvoice()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [EU Service] [Reverse Charge VAT]
        // [SCENARIO 225529] SII XML request does not contain tag 'sii:Entrega' for EU Service intracommunity sales invoice with Reverse Charge VAT
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] EU Service reverse charge VAT Posting Setup "V"
        // [GIVEN] Intracommunity customer "C"
        CreateReverseChargeVATIntracommunityCustoemerAndGLAccount(Customer, GLAccount, true);

        // [GIVEN] Sales invoice for customer "C" with VAT groups from "V"
        CreateSalesDocumentWithGLAccount(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", GLAccount."No.");

        // [WHEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        // [THEN] System generates SII XML request
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] XML request does not contain "sii:Entrega" tag
        VerifyTagAbsence(XMLDoc, 'sii:Entrega');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure XMLRequestEUServiceReverseChargeVATCreditMemo()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [EU Service] [Reverse Charge VAT]
        // [SCENARIO 225529] SII XML request does not contain tag 'sii:Entrega' for EU Service intracommunity sales invoice with Reverse Charge VAT
        Initialize();

        // [GIVEN] Enabled SII Setup
        // [GIVEN] EU Service reverse charge VAT Posting Setup "V"
        // [GIVEN] Intracommunity customer "C"
        CreateReverseChargeVATIntracommunityCustoemerAndGLAccount(Customer, GLAccount, true);

        // [GIVEN] Sales invoice for customer "C" with VAT groups from "V"
        CreateSalesDocumentWithGLAccount(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.", GLAccount."No.");

        // [WHEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] System generated SII XML request
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", DocumentNo);
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] XML request does not contain "sii:Entrega" tag
        VerifyTagAbsence(XMLDoc, 'sii:Entrega');

        // [THEN] XML node by XPath '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/sii:PrestacionServicios' generated
        LibraryXPathXMLReader.InitializeWithText(XMLDoc.OuterXml, '');
        SetupXMLNamespaces();
        LibraryXPathXMLReader.VerifyNodeCountByXPath(XPathPrestacionServiciosTok, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NotifyOnSuccessIsDisabledInSIIJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        SIIJobManagement: Codeunit "SII Job Management";
        JobType: Option HandlePending,HandleCommError,InitialUpload;
    begin
        // [FEATURE] [UT] [Job Queue]
        // [SCENARIO 251642] Job Queue Entry created via SII Job Management codeunit has disabled "Notify on Success"

        Initialize();

        JobQueueEntry.DeleteAll();
        SIIJobManagement.RenewJobQueueEntry(JobType::HandlePending);
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField("Notify On Success", false);
        JobQueueEntry.TestField("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.TestField("Object ID to Run", CODEUNIT::"SII Job Upload Pending Docs.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIISetupShowAdvancedActions()
    var
        SIIHistory: TestPage "SII History";
        SIISetup: TestPage "SII Setup";
    begin
        // [FEATURE] [Advanced Mark] [UI] [UT]
        // [SCENARIO 253910] There is a checkbox "Show Advanced Actions" on SII Setup page which enables additional actions on SII History page
        LibrarySII.InitSetup(false, false);
        LibrarySII.ShowAdvancedActions(false);

        // There is a "Show Advanced Actions" checkbox on SII Setup page
        SIISetup.OpenEdit();
        Assert.IsTrue(SIISetup."Show Advanced Actions".Visible(), '');
        Assert.IsTrue(SIISetup."Show Advanced Actions".Enabled(), '');
        SIISetup."Show Advanced Actions".AssertEquals(false);
        SIISetup.Close();

        // SII History advanced actions are hidden in case of SIISetup."Show Advanced Actions" = FALSE
        SIIHistory.OpenEdit();
        Assert.IsFalse(SIIHistory."Mark As Accepted".Visible(), '');
        Assert.IsFalse(SIIHistory."Mark As Accepted".Enabled(), '');
        SIIHistory.Close();

        // SII History advanced actions are visible but not enabled in case of SIISetup."Enabled" = FALSE, "Show Advanced Actions" = TRUE
        LibrarySII.ShowAdvancedActions(true);
        SIIHistory.OpenEdit();
        Assert.IsTrue(SIIHistory."Mark As Accepted".Visible(), '');
        Assert.IsFalse(SIIHistory."Mark As Accepted".Enabled(), '');
        SIIHistory.Close();

        // SII History advanced actions are visible and enabled in case of SIISetup."Enabled" = TRUE, "Show Advanced Actions" = TRUE
        LibrarySII.InitSetup(true, false);
        SIIHistory.OpenEdit();
        Assert.IsTrue(SIIHistory."Mark As Accepted".Visible(), '');
        Assert.IsTrue(SIIHistory."Mark As Accepted".Enabled(), '');
        SIIHistory.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIHistoryMarkAsAccepted_Negative()
    var
        SIIHistory: Record "SII History";
        SIIManagement: Codeunit "SII Management";
        StatusCollection: array[2] of Enum "SII Document Status";
        i: Integer;
    begin
        // [FEATURE] [Advanced Mark] [UT]
        // [SCENARIO 253910] There is a fielderror when try "Mark As Accepted" history entry with status "Accepted"\"Accepted With Errors"
        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);
        Commit();

        StatusCollection[1] := SIIHistory.Status::Accepted;
        StatusCollection[2] := SIIHistory.Status::"Accepted With Errors";

        for i := 1 to ArrayLen(StatusCollection) do begin
            Clear(SIIHistory);
            LibrarySII.MockHistoryEntry(SIIHistory, StatusCollection[i]);
            SIIHistory.SetRecFilter();
            asserterror SIIManagement.MarkAsAccepted(SIIHistory);
            Assert.ExpectedErrorCode('TableError');
            Assert.ExpectedError(StrSubstNo(FieldMustNotBeErr, SIIHistory.FieldCaption(Status), SIIHistory.Status));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIHistoryMarkAsNotAccepted_Negative()
    var
        SIIHistory: Record "SII History";
        SIIManagement: Codeunit "SII Management";
        StatusCollection: array[5] of Enum "SII Document Status";
        i: Integer;
    begin
        // [FEATURE] [Advanced Mark] [UT]
        // [SCENARIO 253910] There is a fielderror when try "Mark As Not Accepted" history entry with status "Communication Error"\"Failed"\"Incorrect"\"Not Supported"\"Pending"
        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);
        Commit();

        StatusCollection[1] := SIIHistory.Status::"Communication Error";
        StatusCollection[2] := SIIHistory.Status::Failed;
        StatusCollection[3] := SIIHistory.Status::Incorrect;
        StatusCollection[4] := SIIHistory.Status::"Not Supported";
        StatusCollection[5] := SIIHistory.Status::Pending;

        for i := 1 to ArrayLen(StatusCollection) do begin
            Clear(SIIHistory);
            LibrarySII.MockHistoryEntry(SIIHistory, StatusCollection[i]);
            SIIHistory.SetRecFilter();
            asserterror SIIManagement.MarkAsNotAccepted(SIIHistory);
            Assert.ExpectedErrorCode('TableError');
            Assert.ExpectedError(StrSubstNo(FieldMustNotBeErr, SIIHistory.FieldCaption(Status), SIIHistory.Status));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIHistoryMarkAsAccepted()
    var
        SIIHistory: Record "SII History";
        SIIManagement: Codeunit "SII Management";
    begin
        // [FEATURE] [Advanced Mark]
        // [SCENARIO 253910] "Mark As Accepted" history "Failed" entry
        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);

        // [GIVEN] History "Failed" entry
        LibrarySII.MockHistoryEntry(SIIHistory, SIIHistory.Status::Failed);
        SIIHistory.SetRecFilter();

        // [WHEN] Mark As Accepted
        SIIManagement.MarkAsAccepted(SIIHistory);

        // [THEN] An existing history entry has status "Accepted With Errors"
        // TFS 292525: SII Entry marked as accepted does not different from accepted by system
        VerifyHistoryAndDocUploadValuesAfterMark(
          SIIHistory."Document State Id", SIIHistory.Status::"Accepted With Errors", MarkAsAcceptedErr,
          SIIHistory."Upload Type"::Regular, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIHistoryMarkAsNotAccepted()
    var
        SIIHistory: Record "SII History";
        SIIManagement: Codeunit "SII Management";
    begin
        // [FEATURE] [Advanced Mark]
        // [SCENARIO 253910] "Mark As Not Accepted" history "Accepted" entry
        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);

        // [GIVEN] History "Accepted" entry
        LibrarySII.MockHistoryEntry(SIIHistory, SIIHistory.Status::Accepted);

        // [WHEN] Mark As Not Accepted
        SIIHistory.SetRecFilter();
        SIIManagement.MarkAsNotAccepted(SIIHistory);

        // [THEN] An existing history entry has status "Accepted With Errors"
        // TFS 292525: SII Entry marked as accepted does not different from accepted by system
        VerifyHistoryAndDocUploadValuesAfterMark(
          SIIHistory."Document State Id", SIIHistory.Status::Failed, MarkAsNotAcceptedErr, SIIHistory."Upload Type"::Regular, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTypeAndSpecialSchemeCodeInJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 261095] Stan can specify "Invoice Type" and "Special Scheme" code in General Journal Line for Sales Invoice

        // [GIVEN] Enabled SII Setup
        LibrarySII.InitSetup(true, false);

        // [GIVEN] Posted journal line for Sales Invoice with "Invoice Type" = "F2 Simplified Invoice" and "Sales Special Scheme Code" = "04 Gold")
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Sales Invoice Type", GenJournalLine."Sales Invoice Type"::"F2 Simplified Invoice");
        GenJournalLine.Validate("Sales Special Scheme Code", GenJournalLine."Sales Special Scheme Code"::"04 Gold");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] System generated SII XML request
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '04');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoTypeAndSpecialSchemeCodeInJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        CustNo: Code[20];
        DocNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 261095] Stan can specify "Invoice Type" and "Special Scheme" code in General Journal Line for Sales Credit Memo
        // [SCENARIO 269110] SII Doc. Upload State has "Corrected Doc. No." and "Corr. Posting Date" of corrected sales 2invoice

        // [GIVEN] Enabled SII Setup
        LibrarySII.InitSetup(true, false);

        // [GIVEN] Posted Sales Invoice "X" and "Posting Date" = "Y"
        CustNo := LibrarySales.CreateCustomerNo();
        PostingDate := LibraryRandom.RandDate(10);
        DocNo := MockSalesInvoiceDocWithEntry(CustNo, PostingDate);

        // [GIVEN] Posted journal line for Replacement Sales Credit Memo with "Invoice Type" = "F2 Simplified Invoice", "Sales Special Scheme Code" = "04 Gold" and "Corrected Invoice No." = "X"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, CustNo, -LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Sales Cr. Memo Type", GenJournalLine."Sales Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        GenJournalLine.Validate("Sales Special Scheme Code", GenJournalLine."Sales Special Scheme Code"::"04 Gold");
        GenJournalLine.Validate("Correction Type", GenJournalLine."Correction Type"::Replacement);
        GenJournalLine.Validate("Corrected Invoice No.", DocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] System generated SII XML request
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '04');

        // [THEN] NumSerieFacturaEmisor under node FacturasRectificadas is "X1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:FacturasRectificadas/sii:IDFacturaRectificada/sii:NumSerieFacturaEmisor', DocNo);

        // [THEN] SII Doc. Upload State for Credit Memo exists with "Corrected Doc. No." = "X" and "Corr. Posting Date" = "Y"
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Customer Ledger", SIIDocUploadState."Document Type"::"Credit Memo",
          CustLedgerEntry."Document No.");
        SIIDocUploadState.TestField("Corrected Doc. No.", DocNo);
        SIIDocUploadState.TestField("Corr. Posting Date", PostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceTypeAndSpecialSchemeCodeInJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 261095] Stan can specify "Invoice Type" and "Special Scheme" code in General Journal Line for Purchase Invoice

        // [GIVEN] Enabled SII Setup
        LibrarySII.InitSetup(true, false);

        // [GIVEN] Posted journal line for Purchase Invoice with "Invoice Type" = "F2 Simplified Invoice" and "Purch. Special Scheme Code" = "04 Gold")
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Purch. Invoice Type", GenJournalLine."Purch. Invoice Type"::"F2 Simplified Invoice");
        GenJournalLine.Validate("Purch. Special Scheme Code", GenJournalLine."Purch. Special Scheme Code"::"04 Gold");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] System generated SII XML request
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '04');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoTypeAndSpecialSchemeCodeInJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        VendNo: Code[20];
        DocNo: Code[20];
        DocDate: Date;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 261095] Stan can specify "Invoice Type" and "Special Scheme" code in General Journal Line for Purchase Credit Memo
        // [SCENARIO 269110] SII Doc. Upload State has "Corrected Doc. No." and "Corr. Posting Date" of corrected purchase invoice

        // [GIVEN] Enabled SII Setup
        LibrarySII.InitSetup(true, false);

        // [GIVEN] Posted Purchase Invoice "X" and "Document Date" = "Y"
        VendNo := LibraryPurchase.CreateVendorNo();
        DocDate := LibraryRandom.RandDate(10);
        DocNo := MockPurchInvoiceDocWithEntry(VendNo, DocDate);

        // [GIVEN] Posted journal line for Purchase Credit Memo with "Invoice Type" = "F2 Simplified Invoice", "Purch. Special Scheme Code" = "04 Gold" and "Corrected Invoice No." = "X"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, VendNo, LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Purch. Cr. Memo Type", GenJournalLine."Purch. Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");
        GenJournalLine.Validate("Purch. Special Scheme Code", GenJournalLine."Purch. Special Scheme Code"::"04 Gold");
        GenJournalLine.Validate("Correction Type", GenJournalLine."Correction Type"::Replacement);
        GenJournalLine.Validate("Corrected Invoice No.", DocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] System generated SII XML request
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] ClaveRegimenEspecialOTrascendencia is "2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '04');

        // [THEN] NumSerieFacturaEmisor under node FacturasRectificadas is "X1" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:FacturasRectificadas/sii:IDFacturaRectificada/sii:NumSerieFacturaEmisor', DocNo);

        // [THEN] SII Doc. Upload State for Credit Memo exists with "Corrected Doc. No." = "X" and "Corr. Posting Date" = "Y"
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Vendor Ledger", SIIDocUploadState."Document Type"::"Credit Memo",
          VendorLedgerEntry."Document No.");
        SIIDocUploadState.TestField("Corrected Doc. No.", DocNo);
        SIIDocUploadState.TestField("Corr. Posting Date", DocDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDVersionTakesFromSIIDocUploadState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 263060] It is possible to set specific version for IDVersionSii node through function SetSIIVersionNo of codeunit SII XML Creator

        Initialize();

        // [GIVEN] Posted invoice
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [GIVEN] "Version No." is changed to "1.0" in SII Doc. Upload State related to posted invoice
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"1.0");

        // [WHEN] Generated XML file for Posted invoice
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] XML File contains IDVersionSii with value "1.0"
        ValidateElementByName(XMLDoc, 'sii:IDVersionSii', '1.0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToProcessDocumentWithoutSchemeReference()
    var
        SIISetup: Record "SII Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 341899] Stan cannot submit the document to SII if the SuministroInformacion Schema or SuministroLR Schema is not specified

        Initialize();

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        SIISetup.Get();
        SIISetup."SuministroInformacion Schema" := '';
        SIISetup.Modify();

        asserterror SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueInSIISetupErr, SIISetup.FieldCaption("SuministroInformacion Schema")));

        SIISetup."SuministroInformacion Schema" := SIISetup."SuministroLR Schema";
        SIISetup."SuministroLR Schema" := '';
        SIISetup.Modify();

        asserterror SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo(FieldMustHaveValueInSIISetupErr, SIISetup.FieldCaption("SuministroLR Schema")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NotPossibleToDeleteCertificateUsedInSIISetupIfUserNotConfirm()
    var
        IsolatedCertificate: Record "Isolated Certificate";
        SIISetup: Record "SII Setup";
    begin
        // [SCENARIO 316847] An isolated certificate not removes if it is used in the SII Setup and user cancels the confirmation

        Initialize();

        // [GIVEN] Isolated certificate "A"
        IsolatedCertificate.Init();
        IsolatedCertificate.Insert(true);

        // [GIVEN] SII setup with "Certificate Code" = "A"
        SIISetup.Get();
        SIISetup."Certificate Code" := IsolatedCertificate.Code;
        SIISetup.Modify();
        Commit();

        LibraryVariableStorage.Enqueue(CertificateUsedInSIISetupQst);
        LibraryVariableStorage.Enqueue(false); // say no in confirmation window

        // [WHEN] Delete isolated certificate "A" and cancel confirmation
        asserterror IsolatedCertificate.Delete(true);

        // [THEN] Error thrown with no text
        Assert.ExpectedError('');

        // [THEN] Isolated certificate not removed
        IsolatedCertificate.Find();

        // [THEN] "Certificate Code" still has value "A" in the SII Setup
        SIISetup.Find();
        SIISetup.TestField("Certificate Code", IsolatedCertificate.Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CertificateCodeBlanksInSIISetupIfUserConfirmCertificateDeletion()
    var
        IsolatedCertificate: Record "Isolated Certificate";
        SIISetup: Record "SII Setup";
    begin
        // [SCENARIO 316847] An isolated certificate removes if it is used in the SII Setup and user confirms

        Initialize();

        // [GIVEN] Isolated certificate "A"
        IsolatedCertificate.Init();
        IsolatedCertificate.Insert(true);

        // [GIVEN] SII setup with "Certificate Code" = "A"
        SIISetup.Get();
        SIISetup."Certificate Code" := IsolatedCertificate.Code;
        SIISetup.Modify();
        Commit();

        LibraryVariableStorage.Enqueue(CertificateUsedInSIISetupQst);
        LibraryVariableStorage.Enqueue(true); // say yes in confirmation window

        // [WHEN] Delete isolated certificate "A" and confirm this
        IsolatedCertificate.Delete(true);

        // [THEN] Isolated certificate not removed
        Assert.IsFalse(IsolatedCertificate.Find(), 'Isolated certificate was not removed');

        // [THEN] "Certificate Code" does not have in the SII Setup
        SIISetup.Find();
        SIISetup.TestField("Certificate Code", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryTriggeresOnSalesInvoicePosting()
    var
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Sales] [Invoice] [Job Queue]
        // [SCENARIO 388578] Job Queue Entry triggers on sales invoice posting

        Initialize();
        JobQueueEntry.DeleteAll();
        PostSalesDocument(SalesHeader."Document Type"::Invoice, true, true);
        VerifySIIJobQueueEntryCount(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryTriggeresOnSalesCrMemoPosting()
    var
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Sales] [Credit Memo] [Job Queue]
        // [SCENARIO 388578] Job Queue Entry triggers on sales credit memo posting

        Initialize();
        JobQueueEntry.DeleteAll();
        PostSalesDocument(SalesHeader."Document Type"::"Credit Memo", true, true);
        VerifySIIJobQueueEntryCount(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryNotTriggeresOnSalesInvoiceShipment()
    var
        SalesHeader: Record "Sales Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Sales] [Invoice] [Job Queue]
        // [SCENARIO 388578] Job Queue Entry not triggers on sales invoice shipment

        Initialize();
        JobQueueEntry.DeleteAll();
        PostSalesDocument(SalesHeader."Document Type"::Order, true, false);
        VerifySIIJobQueueEntryCount(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryTriggeresOnPurchInvoicePosting()
    var
        PurchaseHeader: Record "Purchase Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Purchase] [Invoice] [Job Queue]
        // [SCENARIO 388578] Job Queue Entry triggers on purchase invoice posting

        Initialize();
        JobQueueEntry.DeleteAll();
        PostPurchaseDocument(PurchaseHeader."Document Type"::Invoice, true, true);
        VerifySIIJobQueueEntryCount(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryTriggeresOnPurchCrMemoPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Job Queue]
        // [SCENARIO 388578] Job Queue Entry triggers on purchase credit memo posting

        Initialize();
        JobQueueEntry.DeleteAll();
        PostPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo", true, true);
        VerifySIIJobQueueEntryCount(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobQueueEntryNotTriggeresOnPurchInvoiceReceive()
    var
        PurchaseHeader: Record "Purchase Header";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Purchase] [Invoice] [Job Queue]
        // [SCENARIO 388578] Job Queue Entry not triggers on purchase invoice receive

        Initialize();
        JobQueueEntry.DeleteAll();
        PostPurchaseDocument(PurchaseHeader."Document Type"::Order, true, false);
        VerifySIIJobQueueEntryCount(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialSchemeCodeOfSalesInvWithE2ExemptionCode()
    var
        SalesHeader: Record "Sales Header";
        VATClause: Record "VAT Clause";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Exemption]
        // [SCENARIO 395354] "Special Scheme Codes" automatically changes to "02 export" when posting sales invoice with exemption code "E2"

        Initialize();
        // [GIVEN] Sales invoice with default "Special Scheme Code" equals "01" and "Exemptio Code" = "E2"
        LibrarySII.CreateSalesWithSpecificVATClause(
          SalesHeader, SalesHeader."Document Type"::Invoice, WorkDate(), 0,
          VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21");

        // [WHEN] Post sales invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] Posted Sales invoice has "Special Scheme Code" = "02"
        SalesInvoiceHeader.TestField("Special Scheme Code", SalesInvoiceHeader."Special Scheme Code"::"02 Export");

        // [THEN] SII Doc. Upload State for posted Sales invoice has "Special Scheme Code" = "02"
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::Invoice, SalesInvoiceHeader."No.");
        SIIDocUploadState.TestField("Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialSchemeCodeOfSalesInvWithE3ExemptionCode()
    var
        SalesHeader: Record "Sales Header";
        VATClause: Record "VAT Clause";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [Exemption]
        // [SCENARIO 395354] "Special Scheme Codes" automatically changes to "02 export" when posting sales invoice with exemption code "E3"

        Initialize();
        // [GIVEN] Sales invoice with default "Special Scheme Code" equals "01" and "Exemptio Code" = "E3"
        LibrarySII.CreateSalesWithSpecificVATClause(
          SalesHeader, SalesHeader."Document Type"::Invoice, WorkDate(), 0,
          VATClause."SII Exemption Code"::"E3 Exempt on account of Article 22");

        // [WHEN] Post sales invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] Posted Sales invoice has "Special Scheme Code" = "02"
        SalesInvoiceHeader.TestField("Special Scheme Code", SalesInvoiceHeader."Special Scheme Code"::"02 Export");

        // [THEN] SII Doc. Upload State for posted Sales invoice has "Special Scheme Code" = "02"
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Customer Ledger",
          SIIDocUploadState."Document Type"::Invoice, SalesInvoiceHeader."No.");
        SIIDocUploadState.TestField("Sales Special Scheme Code", SIIDocUploadState."Sales Special Scheme Code"::"02 Export");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostRemovalSalesCreditMemoWithoutCorrectedInvNo()
    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 405655] Stan cannot post sales credit memo with "Removal" correction type and blank "Corrected Invoice No."

        Initialize();
        CreateSalesCrMemoWithType(SalesHeader, "SII Sales Credit Memo Type"::"R1 Corrected Invoice");
        SalesHeader.Validate("Correction Type", SalesHeader."Correction Type"::Removal);
        SalesHeader.Validate("Corrected Invoice No.", '');
        SalesHeader.Modify(true);

        asserterror SalesPost.Run(SalesHeader);

        Assert.ExpectedError('Corrected Invoice No. must have a value in Sales Header');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostRemovalPurchCreditMemoWithoutCorrectedInvNo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchPost: Codeunit "Purch.-Post";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 405655] Stan cannot post purchase credit memo with "Removal" correction type and blank "Corrected Invoice No."

        Initialize();
        CreatePurchCrMemoWithType(PurchaseHeader, "SII Sales Credit Memo Type"::"R1 Corrected Invoice");
        PurchaseHeader.Validate("Correction Type", PurchaseHeader."Correction Type"::Removal);
        PurchaseHeader.Validate("Corrected Invoice No.", '');
        PurchaseHeader.Modify(true);

        asserterror PurchPost.Run(PurchaseHeader);

        Assert.ExpectedError('Corrected Invoice No. must have a value in Purchase Header');
    end;

    [Test]
    procedure NoSIIDocUploadStateCreatesForSalesDocMarkedToNotSendToSII()
    var
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 433352] No "SII Doc. Upload State" creates when sales document marked with "Dot Not Send To SII"

        Initialize();

        // [GIVEN] Sales invoice with "Dot Not Send To SII" option enabled
        CreateSalesDocumentWithGLAccount(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), LibraryERM.CreateGLAccountWithSalesSetup());
        SalesHeader.Validate("Do Not Send To SII", true);
        SalesHeader.Modify(true);

        // [GIVEN] Post invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] No "SII Doc. Upload State" has been created
        VerifyNoSIIDocUploadState(
          SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    procedure NoSIIDocUploadStateCreatesForPurchDocMarkedToNotSendToSII()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 433352] No "SII Doc. Upload State" creates when purchase document marked with "Dot Not Send To SII"

        Initialize();

        // [GIVEN] Purchase invoice with "Dot Not Send To SII" option enabled
        CreatePurchInvoiceWithType(PurchaseHeader, "SII Purch. Invoice Type"::"F1 Invoice");
        PurchaseHeader.Validate("Do Not Send To SII", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Post invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] No "SII Doc. Upload State" has been created
        VerifyNoSIIDocUploadState(
          SIIDocUploadState."Document Type"::Invoice, DocumentNo, SIIDocUploadState."Document Source"::"Vendor Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSIIDocUploadStateCreatesForServDocMarkedToNotSendToSII()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
    begin
        // [FEATURE] [Service] [UT]
        // [SCENARIO 433352] No "SII Doc. Upload State" creates when service document marked with "Dot Not Send To SII"

        Initialize();

        // [GIVEN] Service invoice with "Dot Not Send To SII" option enabled
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        ServiceHeader.Validate("Do Not Send To SII", true);
        ServiceHeader.Modify(true);

        // [GIVEN] Post invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        CustLedgerEntry.SetRange("Customer No.", ServiceHeader."Bill-to Customer No.");
        CustLedgerEntry.FindFirst();

        // [WHEN] Pending document is uploaded
        SIIDocUploadManagement.UploadPendingDocuments();

        // [GIVEN] No "SII Doc. Upload State" has been created
        VerifyNoSIIDocUploadState(
          SIIDocUploadState."Document Type"::Invoice, CustLedgerEntry."Document No.",
          SIIDocUploadState."Document Source"::"Customer Ledger");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleSIIHistoryMarkAsAccepted()
    var
        SIIHistory: array[2] of Record "SII History";
        SIIHistoryToMark: Record "SII History";
        SIIManagement: Codeunit "SII Management";
    begin
        // [FEATURE] [Advanced Mark]
        // [SCENARIO 476403] Stan can "Mark As Accepted" multiple SII history entries

        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);

        // [GIVEN] SII History Entry "A" with "Failed status
        LibrarySII.MockHistoryEntry(SIIHistory[1], SIIHistory[1].Status::Failed);
        // [GIVEN] SII History Entry "B" with "Failed status
        LibrarySII.MockHistoryEntry(SIIHistory[2], SIIHistory[2].Status::Failed);
        SIIHistoryToMark.SetFilter(Id, '%1|%2', SIIHistory[1].Id, SIIHistory[2].Id);

        // [WHEN] Mark As Accepted both
        SIIManagement.MarkAsAccepted(SIIHistoryToMark);

        // [THEN] The SII History Entry "A" has status "Accepted With Errors"
        VerifyHistoryAndDocUploadValuesAfterMark(
          SIIHistory[1]."Document State Id", SIIHistory[1].Status::"Accepted With Errors", MarkAsAcceptedErr,
          SIIHistory[1]."Upload Type"::Regular, false);
        // [THEN] The SII History Entry "B" has status "Accepted With Errors"
        VerifyHistoryAndDocUploadValuesAfterMark(
          SIIHistory[2]."Document State Id", SIIHistory[2].Status::"Accepted With Errors", MarkAsAcceptedErr,
          SIIHistory[2]."Upload Type"::Regular, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleSIIHistoryMarkAsNotAccepted()
    var
        SIIHistory: array[2] of Record "SII History";
        SIIHistoryToMark: Record "SII History";
        SIIManagement: Codeunit "SII Management";
    begin
        // [FEATURE] [Advanced Mark]
        // [SCENARIO 476403] Stan can "Mark As Not Accepted" multiple SII history entries

        LibrarySII.InitSetup(true, false);
        LibrarySII.ShowAdvancedActions(true);

        // [GIVEN] SII History Entry "A" with "Accepted status
        LibrarySII.MockHistoryEntry(SIIHistory[1], SIIHistory[1].Status::Accepted);
        // [GIVEN] SII History Entry "B" with "Accepted status
        LibrarySII.MockHistoryEntry(SIIHistory[2], SIIHistory[2].Status::Accepted);
        SIIHistoryToMark.SetFilter(Id, '%1|%2', SIIHistory[1].Id, SIIHistory[2].Id);

        // [WHEN] Mark As Not Accepted
        SIIManagement.MarkAsNotAccepted(SIIHistoryToMark);

        // [THEN] The SII History Entry "A" has status "Failed"
        VerifyHistoryAndDocUploadValuesAfterMark(
          SIIHistory[1]."Document State Id", SIIHistory[1].Status::Failed, MarkAsNotAcceptedErr, SIIHistory[1]."Upload Type"::Regular, false);
        // [THEN] The SII History Entry "B" has status "Failed"
        VerifyHistoryAndDocUploadValuesAfterMark(
          SIIHistory[2]."Document State Id", SIIHistory[2].Status::Failed, MarkAsNotAcceptedErr, SIIHistory[1]."Upload Type"::Regular, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderPostedWithShipAndInvoiceWithIDType06()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SIIHistory: TestPage "SII History";
        SIIDocumentStatus: Enum "SII Document Status";
    begin
        // [SCENARIO 523982] "Valor o tipo incorrecto del campo: IDType" error message in SII History if you Ship & Invoice a Service Order for a foreign customer in the Spanish version.
        Initialize();

        // [GIVEN] Service Order with Export Customer
        CreateServiceDocWithExportCustomer(ServiceHeader, ServiceHeader."Document Type"::Order);

        // [THEN] Post Service Order Document with Ship and Invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Opened "SII History" page and Verify Status
        SIIHistory.OpenView();
        SIIHistory.Status.AssertEquals(Format(SIIDocumentStatus::Pending));
        SIIHistory.Retry.Invoke();
        Assert.AreNotEqual(SIIHistory.Status.Value, StatusErr, DifferentValueErr);

        // [THEN] Verify: ID Type is on Posted Service Invoice document
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        Assert.AreEqual(ServiceHeader."ID Type", ServiceInvoiceHeader."ID Type", DifferentValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotQueueJobQueueEntryOnPostingSalesInvoice()
    var
        SIISetup: Record "SII Setup";
        GenJournalLine: Record "Gen. Journal Line";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Journal] [Sales] [Invoice]
        // [SCENARIO 527369] Posting customer's invoice does not trigger the job queue entry

        Initialize();

        JobQueueEntry.DeleteAll();
        // [GIVEN] Enabled SII Setup with "Dot No Schedule JQ Entry" option enabled
        SIISetup.Get();
        SIISetup.Validate("Do Not Schedule JQ Entry", true);
        SIISetup.Modify(true);
        // [GIVEN] Journal line with type "Invoice" for customer
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Post journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The SII job queue entry has not been created
        VerifySIIJobQueueEntryCount(0);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        IsInitialized := true;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        LibrarySetupStorage.Save(DATABASE::"SII Setup");
    end;

    local procedure PostSalesDocument(DocType: Enum "Sales Document Type"; ShipReceive: Boolean; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocType,
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, ShipReceive, Invoice);
    end;

    local procedure PostPurchaseDocument(DocType: Enum "Purchase Document Type"; ShipReceive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocType,
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ShipReceive, Invoice);
    end;

    local procedure CreateSalesInvoiceWithType(var SalesHeader: Record "Sales Header"; SIIDocType: Enum "SII Sales Invoice Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate());
        SalesHeader.Validate("Invoice Type", SIIDocType);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesCrMemoWithType(var SalesHeader: Record "Sales Header"; SIIDocType: Enum "SII Sales Credit Memo Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo",
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate());
        SalesHeader.Validate("Cr. Memo Type", SIIDocType);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithGLAccount(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; GLAccountNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDecInRange(100, 200, 2));

        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchInvoiceWithType(var PurchaseHeader: Record "Purchase Header"; SIIDocType: Enum "SII Purch. Invoice Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate());
        PurchaseHeader.Validate("Invoice Type", SIIDocType);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchCrMemoWithType(var PurchaseHeader: Record "Purchase Header"; SIIDocType: Enum "SII Purch. Credit Memo Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo",
          '', '', LibraryRandom.RandDecInRange(100, 200, 2), '', WorkDate());
        PurchaseHeader.Validate("Cr. Memo Type", SIIDocType);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateServiceDoc(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibrarySII.CreateServiceHeader(ServiceHeader, DocType, LibrarySales.CreateCustomerNo(), '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateIntraCommunityCustomer(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        CreateIntracommunityCountryRegion(CountryRegion);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
    end;

    local procedure CreateIntraCommunityVendor(var Vendor: Record Vendor)
    var
        CountryRegion: Record "Country/Region";
    begin
        CreateIntracommunityCountryRegion(CountryRegion);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateReverseChargeVATIntracommunityCustoemerAndGLAccount(var Customer: Record Customer; var GLAccount: Record "G/L Account"; EUService: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(5, 10));
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Modify(true);

        CreateIntraCommunityCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure CreateIntracommunityCountryRegion(var CountryRegion: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
    end;

    local procedure FilterSIIHistory(var SIIHistory: Record "SII History"; DocType: Enum "SII Doc. Upload State Document Type"; DocNo: Code[20]; DocSource: Enum "SII Doc. Upload State Document Source")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        LibrarySII.FindSIIDocUploadState(SIIDocUploadState, DocSource, DocType, DocNo);
        SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
    end;

    local procedure MockCustLedgEntryWithIntracommunityCust(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Posting Date" := WorkDate();
        CreateIntraCommunityCustomer(Customer);
        CustLedgerEntry."Sell-to Customer No." := Customer."No.";
        CustLedgerEntry."Customer No." := Customer."No.";
        CustLedgerEntry.Insert();
    end;

    local procedure MockVendLedgEntryWithIntracommunityVend(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        Vendor: Record Vendor;
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        VendorLedgerEntry."Posting Date" := WorkDate();
        CreateIntraCommunityVendor(Vendor);
        VendorLedgerEntry."Buy-from Vendor No." := Vendor."No.";
        VendorLedgerEntry."Vendor No." := Vendor."No.";
        VendorLedgerEntry.Insert();
    end;

    local procedure MockSIIDocUploadStateWithIncorrectStatus(DocSource: enum "SII Doc. Upload State Document Source"; DocType: Enum "SII Doc. Upload State Document Type"; DocNo: Code[20])
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIDocUploadState.Init();
        SIIDocUploadState.Id := LibraryUtility.GetNewRecNo(SIIDocUploadState, SIIDocUploadState.FieldNo(Id));
        SIIDocUploadState."Document Source" := DocSource;
        SIIDocUploadState."Document Type" := DocType;
        SIIDocUploadState."Document No." := DocNo;
        SIIDocUploadState.Status := SIIDocUploadState.Status::Incorrect;
        SIIDocUploadState.Insert();
    end;

    local procedure MockSalesInvoiceDocWithEntry(CustNo: Code[20]; PostingDate: Date): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Bill-to Customer No." := CustNo;
        SalesInvoiceHeader."Posting Date" := PostingDate;
        SalesInvoiceHeader.Insert();
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := SalesInvoiceHeader."No.";
        CustLedgerEntry."Posting Date" := SalesInvoiceHeader."Posting Date";
        CustLedgerEntry.Insert();

        exit(SalesInvoiceHeader."No.");
    end;

    local procedure MockPurchInvoiceDocWithEntry(VendNo: Code[20]; DocDate: Date): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchInvHeader."Pay-to Vendor No." := VendNo;
        PurchInvHeader."Document Date" := DocDate;
        PurchInvHeader.Insert();
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Document No." := PurchInvHeader."No.";
        VendorLedgerEntry."External Document No." := PurchInvHeader."No.";
        VendorLedgerEntry."Document Date" := PurchInvHeader."Document Date";
        VendorLedgerEntry.Insert();
        exit(PurchInvHeader."No.");
    end;

    local procedure ValidateElementByName(XMLDoc: DotNet XmlDocument; ElementName: Text; ExpectedValue: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
        AssertMsg: Text;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(ElementName);
        for i := 0 to XMLNodeList.Count - 1 do begin
            XMLNode := XMLNodeList.Item(i);
            AssertMsg := StrSubstNo('Value is invalid for element : %1', ElementName);
            Assert.AreEqual(ExpectedValue, Format(XMLNode.InnerText), AssertMsg);
        end;
    end;

    local procedure SetupXMLNamespaces()
    begin
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('soapenv', SoapenvUrlTok);
        LibraryXPathXMLReader.AddAdditionalNamespace('siiRL', SiiRLUrlTok);
        LibraryXPathXMLReader.AddAdditionalNamespace('sii', SiiUrlTok);
    end;

    local procedure VerifySIIHistoryByStateIdIsSupported(var SIIHistory: Record "SII History"; DocType: Enum "SII Doc. Upload State Document Type"; DocNo: Code[20]; DocSource: Enum "SII Doc. Upload State Document Source")
    begin
        FilterSIIHistory(SIIHistory, DocType, DocNo, DocSource);
        SIIHistory.FindFirst();
        Assert.IsFalse(SIIHistory.Status = SIIHistory.Status::"Not Supported", 'Document is not supported');
    end;

    local procedure VerifyTagAbsence(XMLDoc: DotNet XmlDocument; TagName: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(TagName);
        Assert.AreEqual(0, XMLNodeList.Count, StrSubstNo(TagMustNotExistErr, TagName));
    end;

    local procedure VerifyHistoryAndDocUploadValuesAfterMark(DocumentStateId: Integer; ExpectedStatus: Enum "SII Document Status"; ExpectedErrorMessage: Text[250]; ExpectedUploadType: Option; ExpectedRetryAccepted: Boolean)
    var
        SIIHistory: Record "SII History";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIHistory.SetRange("Document State Id", DocumentStateId);
        Assert.RecordCount(SIIHistory, 1);
        SIIHistory.FindLast();
        SIIHistory.TestField(Status, ExpectedStatus);
        Assert.ExpectedMessage(ExpectedErrorMessage, SIIHistory."Error Message");
        SIIHistory.TestField("Upload Type", ExpectedUploadType);
        SIIHistory.TestField("Is Accepted With Errors Retry", false);
        SIIHistory.TestField("Retry Accepted", ExpectedRetryAccepted);

        SIIDocUploadState.Get(DocumentStateId);
        SIIDocUploadState.TestField(Status, ExpectedStatus);
        SIIDocUploadState.TestField("Transaction Type", ExpectedUploadType);
        SIIDocUploadState.TestField("Retry Accepted", ExpectedRetryAccepted);
    end;

    local procedure VerifyNoSIIDocUploadState(DocType: Enum "SII Doc. Upload State Document Type"; DocNo: Code[20]; DocSource: Enum "SII Doc. Upload State Document Source")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIDocUploadState.SetRange("Document Source", DocSource);
        SIIDocUploadState.SetRange("Document Type", DocType);
        SIIDocUploadState.SetRange("Document No.", DocNo);
        Assert.RecordCount(SIIDocUploadState, 0);
    end;

    local procedure VerifySIIJobQueueEntryCount(ExpectedCount: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Job Upload Pending Docs.");
        Assert.RecordCount(JobQueueEntry, ExpectedCount);
    end;

    local procedure CreateServiceDocWithExportCustomer(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        CreateCustWithVATSetup(Customer);
        CreateVATPostingSetupWithClause(Customer, VATProductPostingGroup);

        LibrarySII.CreateServiceHeader(ServiceHeader, DocType, Customer."No.", '');
        ServiceHeader.Validate("ID Type", ServiceHeader."ID Type"::"06-Other Probative Document");
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        ServiceItem.Validate("Item No.", LibrarySII.CreateItemNoWithSpecificVATSetup(VATProductPostingGroup.Code));
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
            ServiceLine,
            ServiceHeader,
            ServiceLine.Type::Item,
            LibrarySII.CreateItemNoWithSpecificVATSetup(VATProductPostingGroup.Code),
            LibraryRandom.RandIntInRange(1, 1));
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        ServiceLine.Modify(true);
    end;

    procedure CreateCustWithVATSetup(var Customer: Record Customer)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, CreateCountryRegionEU(), LibrarySII.GetLocalVATRegNo());
        Customer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCountryRegionEU(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateVATPostingSetupWithClause(Customer: Record Customer; var VATProductPostingGroup: Record "VAT Product Posting Group")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(21, 21));
        VATPostingSetup.Validate("VAT Clause Code", LibrarySII.CreateVATClauseWithSIIExemptionCode(VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21"));
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Insert(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

