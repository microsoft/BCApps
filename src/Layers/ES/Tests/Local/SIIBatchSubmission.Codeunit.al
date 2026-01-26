codeunit 147553 "SII Batch Submission"
{
    // // [FEATURE] [SII] [Batch Submission]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySII: Codeunit "Library - SII";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        RetryAcceptedQst: Label 'Accepted entries have been selected. Do you want to resend them?';
        UploadTypeGlb: Option Regular,Intracommunity,RetryAccepted;
        DocumentSourceGlb: Option "Customer Ledger","Vendor Ledger","Detailed Customer Ledger","Detailed Vendor Ledger";
        SIIDocumentTypeGlb: Option ,Payment,Invoice,"Credit Memo";

    [Test]
    [Scope('OnPrem')]
    procedure Session_StoreRequest()
    var
        SIISession: Record "SII Session";
        InStream: InStream;
        OriginalText: Text;
        ActualText: Text;
        ElementValueText: Text;
        ExpectedText: Text;
        CRLF: Text[2];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232557] TAB 10753 "SII Session".StoreRequestXml()
        // [SCENARIO 253954]
        SIISession.Init();
        SIISession.Insert();

        ElementValueText := LibraryUtility.GenerateRandomXMLText(LibraryRandom.RandIntInRange(100, 200));
        OriginalText := '<?xml version="1.0" encoding="utf-8"?><Element>' + ElementValueText + '</Element>';
        CRLF[1] := 13;
        CRLF[2] := 10;
        ExpectedText := '<?xml version="1.0" encoding="utf-8"?>' + CRLF + '<Element>' + ElementValueText + '</Element>';
        SIISession.StoreRequestXml(OriginalText);

        SIISession."Request XML".CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(ActualText);
        Assert.AreEqual(ExpectedText, ActualText, SIISession.FieldCaption("Request XML"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Session_StoreResponse()
    var
        SIISession: Record "SII Session";
        InStream: InStream;
        OriginalText: Text;
        ActualText: Text;
        ElementValueText: Text;
        ExpectedText: Text;
        CRLF: Text[2];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232557] TAB 10753 "SII Session".StoreResponseXml()
        // [SCENARIO 253954]
        SIISession.Init();
        SIISession.Insert();

        ElementValueText := LibraryUtility.GenerateRandomXMLText(LibraryRandom.RandIntInRange(100, 200));
        OriginalText := '<?xml version="1.0" encoding="utf-8"?><Element>' + ElementValueText + '</Element>';
        CRLF[1] := 13;
        CRLF[2] := 10;
        ExpectedText := '<?xml version="1.0" encoding="utf-8"?>' + CRLF + '<Element>' + ElementValueText + '</Element>';
        SIISession.StoreResponseXml(OriginalText);

        SIISession."Response XML".CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(ActualText);
        Assert.AreEqual(ExpectedText, ActualText, SIISession.FieldCaption("Response XML"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocUploadState_IsCreditMemoRemoval()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232557] TAB 10752 "SII Doc. Upload State".IsCreditMemoRemoval()
        SIIDocUploadState.Init();
        SIIDocUploadState.Insert();
        Assert.IsFalse(SIIDocUploadState.IsCreditMemoRemoval(), '');

        SIIDocUploadState."Document Source" := SIIDocUploadState."Document Source"::"Customer Ledger";
        SIIDocUploadState."Document Type" := SIIDocUploadState."Document Type"::"Credit Memo";
        SIIDocUploadState."Entry No" := LibrarySII.MockCLE(LibrarySII.MockSalesCrMemo(SalesCrMemoHeader."Correction Type"::Removal));
        Assert.IsTrue(SIIDocUploadState.IsCreditMemoRemoval(), '');

        SIIDocUploadState."Entry No" := LibrarySII.MockCLE(LibrarySII.MockSalesCrMemo(SalesCrMemoHeader."Correction Type"::" "));
        Assert.IsFalse(SIIDocUploadState.IsCreditMemoRemoval(), '');

        SIIDocUploadState."Entry No" := LibrarySII.MockCLE(LibrarySII.MockServiceCrMemo(ServiceCrMemoHeader."Correction Type"::Removal));
        Assert.IsTrue(SIIDocUploadState.IsCreditMemoRemoval(), '');

        SIIDocUploadState."Entry No" := LibrarySII.MockCLE(LibrarySII.MockServiceCrMemo(ServiceCrMemoHeader."Correction Type"::" "));
        Assert.IsFalse(SIIDocUploadState.IsCreditMemoRemoval(), '');

        SIIDocUploadState."Document Source" := SIIDocUploadState."Document Source"::"Vendor Ledger";
        SIIDocUploadState."Entry No" := LibrarySII.MockVLE(LibrarySII.MockPurchaseCrMemo(PurchCrMemoHdr."Correction Type"::Removal));
        Assert.IsTrue(SIIDocUploadState.IsCreditMemoRemoval(), '');

        SIIDocUploadState."Entry No" := LibrarySII.MockVLE(LibrarySII.MockPurchaseCrMemo(PurchCrMemoHdr."Correction Type"::" "));
        Assert.IsFalse(SIIDocUploadState.IsCreditMemoRemoval(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocUploadState_CreateNewRequest()
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
        DocumentNo: Code[20];
        ExternalDocumentNo: Code[35];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232557] TAB 10752 "SII Doc. Upload State".CreateNewRequest()
        LibrarySII.InitSetup(true, false);

        ExternalDocumentNo := LibraryUtility.GenerateGUID();
        DocumentNo := LibrarySII.MockSalesInvoice(ExternalDocumentNo);

        SIIDocUploadState.CreateNewRequest(
          LibrarySII.MockCLE(DocumentNo), SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(),
          SIIDocUploadState."Document Type"::Invoice.AsInteger(), DocumentNo, ExternalDocumentNo, WorkDate());

        SIIDocUploadState.SetRange("Document No.", DocumentNo);
        SIIDocUploadState.FindFirst();
        SIIDocUploadState.TestField("External Document No.", ExternalDocumentNo);
        SIIDocUploadState.TestField("Is Manual", false);
        SIIDocUploadState.TestField("Transaction Type", SIIDocUploadState."Transaction Type"::Regular);
        SIIDocUploadState.TestField("Is Credit Memo Removal", false);

        SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
        SIIHistory.FindFirst();
        SIIHistory.TestField("Is Manual", false);
        SIIHistory.TestField(Status, SIIHistory.Status::Pending);
        SIIHistory.TestField("Upload Type", SIIHistory."Upload Type"::Regular);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure History_UI_RetryActions()
    var
        SIIHistory: TestPage "SII History";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 232557] PAG 10752 "SII History" has several actions: "Retry", "Retry All", "Retry Accepted"

        Initialize();

        // All "Retry" actions are disabled in case of SIISetup.Enabled = FALSE
        LibrarySII.InitSetup(false, false);
        SIIHistory.OpenEdit();
        Assert.IsFalse(SIIHistory.Retry.Enabled(), '');
        Assert.IsFalse(SIIHistory."Retry All".Enabled(), '');
        Assert.IsFalse(SIIHistory."Retry Accepted".Enabled(), '');
        SIIHistory.Close();

        // "Retry", "Retry Accepted" actions are enabled, "Retry All" is disabled in case of SIISetup.Enabled = TRUE, SIISetup."Enable Batch Submissions" = FALSE
        LibrarySII.InitSetup(true, false);
        SIIHistory.OpenEdit();
        Assert.IsTrue(SIIHistory.Retry.Enabled(), '');
        Assert.IsFalse(SIIHistory."Retry All".Enabled(), '');
        Assert.IsTrue(SIIHistory."Retry Accepted".Enabled(), '');
        SIIHistory.Close();

        // All "Retry" actions are enabled in case of SIISetup.Enabled = TRUE, SIISetup."Enable Batch Submissions" = TRUE
        LibrarySII.InitSetup(true, true);
        SIIHistory.OpenEdit();
        Assert.IsTrue(SIIHistory.Retry.Enabled(), '');
        Assert.IsTrue(SIIHistory."Retry All".Enabled(), '');
        Assert.IsTrue(SIIHistory."Retry Accepted".Enabled(), '');
        SIIHistory.Close();
    end;

    [Test]
    [HandlerFunctions('RetryAcceptedConfirmHandler')]
    [Scope('OnPrem')]
    procedure History_UI_RetryAcceptedConfirmQst()
    var
        SIIHistory: TestPage "SII History";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 232557] There is a confirm question ("Accepted entries have been selected. Do you want to resend them?") when User invokes "Retry Accepted" action
        Initialize();
        LibrarySII.InitSetup(true, false);

        SIIHistory.OpenEdit();
        LibraryVariableStorage.Enqueue(false);
        SIIHistory."Retry Accepted".Invoke();
        SIIHistory.Close();

        Assert.AreEqual(RetryAcceptedQst, LibraryVariableStorage.DequeueText(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure History_Retry()
    var
        SIIHistory: array[2] of Record "SII History";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 232557] "Retry" action sends only current selected record in case of batch submission
        LibrarySII.InitSetup(true, true);

        LibrarySII.MockPendingHistoryEntry(SIIHistory[1]);
        LibrarySII.MockPendingHistoryEntry(SIIHistory[2]);

        LibrarySII.PageSIIHistory_Retry(SIIHistory[1]);

        VerifyLastHistoryRecord(SIIHistory[1], SIIHistory[1].Status::"Communication Error", 1);
        VerifyLastHistoryRecord(SIIHistory[2], SIIHistory[2].Status::Pending, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure History_Retry_Negative()
    var
        SIIHistory: Record "SII History";
        Status: Enum "SII Document Status";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 232557] "Retry" action sends only not-"Accepted" record
        LibrarySII.InitSetup(true, true);

        // "Incorrect"
        LibrarySII.MockHistoryEntry(SIIHistory, SIIHistory.Status::Incorrect);
        LibrarySII.PageSIIHistory_Retry(SIIHistory);
        VerifyLastHistoryRecord(SIIHistory, SIIHistory.Status::"Communication Error", 2);

        // "Accepted With Errors", "Communication Error", "Failed"
        for Status := SIIHistory.Status::"Accepted With Errors" to SIIHistory.Status::"Communication Error" do begin
            LibrarySII.MockHistoryEntry(SIIHistory, Status);
            LibrarySII.PageSIIHistory_Retry(SIIHistory);
            VerifyLastHistoryRecord(SIIHistory, SIIHistory.Status::"Communication Error", 2);
        end;

        // "Not Supported"
        LibrarySII.MockHistoryEntry(SIIHistory, SIIHistory.Status::"Not Supported");
        LibrarySII.PageSIIHistory_Retry(SIIHistory);
        VerifyLastHistoryRecord(SIIHistory, SIIHistory.Status::"Not Supported", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure History_RetryAll()
    var
        SIIHistory: array[3] of Record "SII History";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 232557] "Retry All" action sends all "Pending" records in case of batch submission
        LibrarySII.InitSetup(true, true);

        LibrarySII.MockPendingHistoryEntry(SIIHistory[1]);
        LibrarySII.MockPendingHistoryEntry(SIIHistory[2]);
        LibrarySII.MockAcceptedHistoryEntry(SIIHistory[3]);

        LibrarySII.PageSIIHistory_RetryAll(SIIHistory[1]);

        VerifyLastHistoryRecord(SIIHistory[1], SIIHistory[1].Status::"Communication Error", 1);
        VerifyLastHistoryRecord(SIIHistory[2], SIIHistory[2].Status::"Communication Error", 1);
        VerifyLastHistoryRecord(SIIHistory[3], SIIHistory[3].Status::Accepted, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure History_RetryAccepted()
    var
        SIIHistory: array[2] of Record "SII History";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 232557] "Retry Accepted" action sends only current selected "Accepted" record in case of batch submission
        LibrarySII.InitSetup(true, true);

        LibrarySII.MockPendingHistoryEntry(SIIHistory[1]);
        LibrarySII.MockAcceptedHistoryEntry(SIIHistory[2]);

        LibrarySII.PageSIIHistory_RetryAccepted(SIIHistory[2]);

        VerifyLastHistoryRecord(SIIHistory[1], SIIHistory[1].Status::Pending, 1);
        VerifyLastHistoryRecord(SIIHistory[2], SIIHistory[2].Status::"Communication Error", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateXML_TwoSalesInvoices()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 232557] Two sales invoice documents are combined in one XML
        Initialize();

        CreatePostSalesDoc(CustLedgerEntry, "Sales Document Type"::Invoice, false);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');

        LibrarySII.VerifyXMLSalesDocHeaderCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLSalesDocCnt(XMLDoc, 2);
        LibrarySII.VerifyXMLTipoComunicacionValue(XMLDoc, 1, 'A0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateXML_TwoSalesCrMemos()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 232557] Two sales credit memo documents are combined in one XML
        Initialize();

        CreatePostSalesDoc(CustLedgerEntry, "Sales Document Type"::"Credit Memo", false);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');

        LibrarySII.VerifyXMLSalesDocHeaderCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLSalesDocCnt(XMLDoc, 2);
        LibrarySII.VerifyXMLTipoComunicacionValue(XMLDoc, 1, 'A0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateXML_TwoSalesCrMemosRemoval()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 232557] Two sales credit memo removal documents are combined in one XML
        Initialize();

        CreatePostSalesDoc(CustLedgerEntry, "Sales Document Type"::"Credit Memo", true);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, true), '');
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, true), '');

        LibrarySII.VerifyXMLSalesCrMemoRemovalHeaderCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLSalesDocCnt(XMLDoc, 2);
        LibrarySII.VerifyXMLTipoComunicacionValue(XMLDoc, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateXML_TwoPurchaseInvoices()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 232557] Two purchase invoice documents are combined in one XML
        Initialize();

        CreatePostPurchaseDoc(VendorLedgerEntry, "Purchase Document Type"::Invoice, false);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');

        LibrarySII.VerifyXMLPurchDocHeaderCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLPurchDocCnt(XMLDoc, 2);
        LibrarySII.VerifyXMLTipoComunicacionValue(XMLDoc, 1, 'A0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateXML_TwoPurchaseCrMemos()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 232557] Two purchase credit memo documents are combined in one XML
        Initialize();

        CreatePostPurchaseDoc(VendorLedgerEntry, "Purchase Document Type"::"Credit Memo", false);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');

        LibrarySII.VerifyXMLPurchDocHeaderCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLPurchDocCnt(XMLDoc, 2);
        LibrarySII.VerifyXMLTipoComunicacionValue(XMLDoc, 1, 'A0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateXML_TwoPurchaseCrMemosRemoval()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 232557] Two purchase credit memo removal documents are combined in one XML
        Initialize();

        CreatePostPurchaseDoc(VendorLedgerEntry, "Purchase Document Type"::"Credit Memo", true);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, true), '');
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadTypeGlb::Regular, true), '');

        LibrarySII.VerifyXMLPurchCrMemoRemovalHeaderCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLPurchDocCnt(XMLDoc, 2);
        LibrarySII.VerifyXMLTipoComunicacionValue(XMLDoc, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateXML_TwoSalesInvoices_ResetInBetween()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 232557] Two sales invoice documents are splitted when SIIXMLCreator.Reset() is invoked
        Initialize();

        CreatePostSalesDoc(CustLedgerEntry, "Sales Document Type"::Invoice, false);

        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');
        LibrarySII.VerifyXMLSalesDocHeaderCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLSalesDocCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLTipoComunicacionValue(XMLDoc, 1, 'A0');

        SIIXMLCreator.Reset();

        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadTypeGlb::Regular, false), '');
        LibrarySII.VerifyXMLSalesDocHeaderCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLSalesDocCnt(XMLDoc, 1);
        LibrarySII.VerifyXMLTipoComunicacionValue(XMLDoc, 1, 'A0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Upload_SeveralDocuments_BatchMode()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        SalesInvoiceDocNo: array[2] of Code[20];
        SalesCrMemoDocNo: array[2] of Code[20];
        SalesCrMemoRemovalDocNo: array[2] of Code[20];
        PurchaseInvoiceDocNo: array[2] of Code[20];
        PurchaseCrMemoDocNo: array[2] of Code[20];
        PurchaseCrMemoRemovalDocNo: array[2] of Code[20];
        SessionId: array[6] of Integer;
        i: Integer;
    begin
        // [SCENARIO 232557] Upload documents (several per each document type) in case of batch submission
        Initialize();
        LibrarySII.InitSetup(true, true);

        // [GIVEN] Several posted documents per each type (Sales\Purchase, Invoice\CreditMemo\CreditMemoRemoval)
        for i := 1 to 2 do begin
            SalesInvoiceDocNo[i] := CreatePostSalesDoc(CustLedgerEntry, "Sales Document Type"::Invoice, false);
            SalesCrMemoDocNo[i] := CreatePostSalesDoc(CustLedgerEntry, "Sales Document Type"::"Credit Memo", false);
            SalesCrMemoRemovalDocNo[i] := CreatePostSalesDoc(CustLedgerEntry, "Sales Document Type"::"Credit Memo", true);
            PurchaseInvoiceDocNo[i] := CreatePostPurchaseDoc(VendorLedgerEntry, "Purchase Document Type"::Invoice, false);
            PurchaseCrMemoDocNo[i] := CreatePostPurchaseDoc(VendorLedgerEntry, "Purchase Document Type"::"Credit Memo", false);
            PurchaseCrMemoRemovalDocNo[i] := CreatePostPurchaseDoc(VendorLedgerEntry, "Purchase Document Type"::"Credit Memo", true);
        end;

        // [WHEN] Upload pending documents (SIISetup."Enable Batch Submissions" := TRUE)
        SIIDocUploadManagement.UploadPendingDocuments();

        // [THEN] Documents with the same Source\Type are combined into one session. Different - are splitted into different session.
        SessionId[1] :=
          VerifyTwoHistoryInOneSession(DocumentSourceGlb::"Customer Ledger", SIIDocumentTypeGlb::Invoice, SalesInvoiceDocNo);
        SessionId[2] :=
          VerifyTwoHistoryInOneSession(DocumentSourceGlb::"Customer Ledger", SIIDocumentTypeGlb::"Credit Memo", SalesCrMemoDocNo);
        SessionId[3] :=
          VerifyTwoHistoryInOneSession(DocumentSourceGlb::"Customer Ledger", SIIDocumentTypeGlb::"Credit Memo", SalesCrMemoRemovalDocNo);
        SessionId[4] :=
          VerifyTwoHistoryInOneSession(DocumentSourceGlb::"Vendor Ledger", SIIDocumentTypeGlb::Invoice, PurchaseInvoiceDocNo);
        SessionId[5] :=
          VerifyTwoHistoryInOneSession(DocumentSourceGlb::"Vendor Ledger", SIIDocumentTypeGlb::"Credit Memo", PurchaseCrMemoDocNo);
        SessionId[6] :=
          VerifyTwoHistoryInOneSession(DocumentSourceGlb::"Vendor Ledger", SIIDocumentTypeGlb::"Credit Memo", PurchaseCrMemoRemovalDocNo);

        VerifyArrayHasDifferentValues(SessionId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Upload_SeveralDocuments_SingleMode()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIDocUploadManagement: Codeunit "SII Doc. Upload Management";
        SalesInvoiceDocNo: array[2] of Code[20];
        SessionId: array[6] of Integer;
    begin
        // [SCENARIO 232557] Upload documents (several per each document type) in case of single mode submission
        Initialize();
        LibrarySII.InitSetup(true, false);

        // [GIVEN] Several posted documents sales invoices
        SalesInvoiceDocNo[1] := CreatePostSalesDoc(CustLedgerEntry, "Sales Document Type"::Invoice, false);
        SalesInvoiceDocNo[2] := CreatePostSalesDoc(CustLedgerEntry, "Sales Document Type"::Invoice, false);

        // [WHEN] Upload pending documents (SIISetup."Enable Batch Submissions" := FALSE)
        SIIDocUploadManagement.UploadPendingDocuments();

        // [THEN] Documents with the same Source\Type are are splitted per different session
        SessionId[1] := GetHistorySessionId(DocumentSourceGlb::"Customer Ledger", SIIDocumentTypeGlb::Invoice, SalesInvoiceDocNo[1]);
        SessionId[2] := GetHistorySessionId(DocumentSourceGlb::"Customer Ledger", SIIDocumentTypeGlb::Invoice, SalesInvoiceDocNo[2]);
        Assert.AreNotEqual(SessionId[1], SessionId[2], '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
    end;

    local procedure CreatePostSalesDoc(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Sales Document Type"; IsCrMemoRemoval: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySII.CreateCustomer(''));
        if IsCrMemoRemoval then begin
            SalesHeader."Correction Type" := SalesHeader."Correction Type"::Removal;
            SalesHeader.Modify();
        end;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        CustLedgerEntry.SetRange("Document No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgerEntry.FindFirst();
        exit(CustLedgerEntry."Document No.");
    end;

    local procedure CreatePostPurchaseDoc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Purchase Document Type"; IsCrMemoRemoval: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibrarySII.CreateVendor(''));
        if IsCrMemoRemoval then begin
            PurchaseHeader."Correction Type" := PurchaseHeader."Correction Type"::Removal;
            PurchaseHeader.Modify();
        end;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        VendorLedgerEntry.SetRange("Document No.", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VendorLedgerEntry.FindFirst();
        exit(VendorLedgerEntry."Document No.");
    end;

    local procedure FindDocUploadState(var SIIDocUploadState: Record "SII Doc. Upload State"; DocumentSource: Option; DocumentType: Option; DocumentNo: Code[20])
    begin
        SIIDocUploadState.SetRange("Document Source", DocumentSource);
        SIIDocUploadState.SetRange("Document Type", DocumentType);
        SIIDocUploadState.SetRange("Document No.", DocumentNo);
        SIIDocUploadState.FindFirst();
    end;

    local procedure FindHistory(var SIIHistory: Record "SII History"; DocumentSource: Option; DocumentType: Option; DocumentNo: Code[20])
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        FindDocUploadState(SIIDocUploadState, DocumentSource, DocumentType, DocumentNo);
        SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
        SIIHistory.FindFirst();
    end;

    local procedure GetHistorySessionId(DocumentSource: Option; DocumentType: Option; DocumentNo: Code[20]): Integer
    var
        SIIHistory: Record "SII History";
    begin
        FindHistory(SIIHistory, DocumentSource, DocumentType, DocumentNo);
        exit(SIIHistory."Session Id");
    end;

    local procedure VerifyLastHistoryRecord(var SIIHistory: Record "SII History"; ExpectedStatus: Enum "SII Document Status"; ExpectedCount: Integer)
    begin
        Assert.RecordCount(SIIHistory, ExpectedCount);
        SIIHistory.FindLast();
        SIIHistory.TestField(Status, ExpectedStatus);
    end;

    local procedure VerifyTwoHistoryInOneSession(DocumentSource: Option; DocumentType: Option; DocumentNo: array[2] of Code[20]): Integer
    var
        SIIHistory: array[2] of Record "SII History";
    begin
        FindHistory(SIIHistory[1], DocumentSource, DocumentType, DocumentNo[1]);
        FindHistory(SIIHistory[2], DocumentSource, DocumentType, DocumentNo[2]);
        SIIHistory[2].TestField("Session Id", SIIHistory[1]."Session Id");
        exit(SIIHistory[1]."Session Id");
    end;

    local procedure VerifyArrayHasDifferentValues(IntArray: array[6] of Integer)
    var
        i: Integer;
        j: Integer;
    begin
        for i := 1 to ArrayLen(IntArray) - 1 do
            for j := i + 1 to ArrayLen(IntArray) do
                Assert.AreNotEqual(IntArray[i], IntArray[j], '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure RetryAcceptedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;
}

