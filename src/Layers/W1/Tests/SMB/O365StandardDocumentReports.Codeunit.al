codeunit 138043 "O365 Standard Document Reports"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [SMB]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        RowNotFoundErr: Label 'Not found: %1 %2.', Locked = true;
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        LineCommentTxt: Label 'Line Comment';

    [Test]
    [HandlerFunctions('StandardSalesQuoteReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesQuoteMissingFilter()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Prepare
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote);

        // Execute
        asserterror CommitAndRunReportOnSalesDocument(REPORT::"Standard Sales - Quote", SalesHeader);
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        // [SCENARIO 258773] Print report 'Standard Sales - Quote' with one item line and one comment line
        Initialize();

        // [GIVEN] Sales Quote with item line and comment line
        ItemNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Quote);
        SalesHeader.SetRecFilter();

        // [WHEN] Run "Standard Sales - Quote" report
        CommitAndRunReportOnSalesDocument(REPORT::"Standard Sales - Quote", SalesHeader);

        // [THEN] Dataset for item has values for Unit Price, Quantity, VAT, Line Amount
        // [THEN] Dataset for comment line has blank values for Unit Price, Quantity, VAT, Line Amount
        SalesHeader.Find();
        Assert.AreEqual(1, SalesHeader."No. Printed", '');
        VerifyPrintedReport(SalesHeader."No.", ItemNo);
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesQuoteWithWorkDescr()
    var
        SalesHeader: Record "Sales Header";
        WorkDescription: Text;
    begin
        Initialize();
        WorkDescription := 'Hello World!';

        // Prepare
        CreateSalesHeaderWithWorkDescription(SalesHeader, SalesHeader."Document Type"::Quote, WorkDescription);

        // Execute
        CommitAndRunReportOnSalesDocument(REPORT::"Standard Sales - Quote", SalesHeader);

        // Verify
        SalesHeader.Find();
        Assert.AreEqual(1, SalesHeader."No. Printed", '');
        VerifyPrintedReportWithWorkDescription(WorkDescription);
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesOrderConfWithWorkDescr()
    var
        SalesHeader: Record "Sales Header";
        WorkDescription: Text;
    begin
        // [FEATURE] [Standard Sales - Order Conf.]
        // [SCENARIO 215434] Report "Standard Sales - Order Conf." have to contain value of field "Work Description" from Sales Order
        Initialize();

        // [GIVEN] Sales Order with "Work Description" = 'Hello World!'
        WorkDescription := 'Hello World!';
        CreateSalesHeaderWithWorkDescription(SalesHeader, SalesHeader."Document Type"::Order, WorkDescription);

        // [WHEN] Run report "Standard Sales - Order Conf."
        CommitAndRunReportOnSalesDocument(REPORT::"Standard Sales - Order Conf.", SalesHeader);

        // [THEN] Value of WorkDescriptionLine = 'Hello World!'
        SalesHeader.Find();
        Assert.AreEqual(1, SalesHeader."No. Printed", '');
        VerifyPrintedReportWithWorkDescription(WorkDescription);
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        // [SCENARIO 258773] Print report 'Standard Sales - Order Conf.' with one item line and one comment line
        Initialize();

        // [GIVEN] Sales Order with item line and comment line
        ItemNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeader.SetRecFilter();

        // [WHEN] Run "Standard Sales - Order Conf." report
        CommitAndRunReportOnSalesDocument(REPORT::"Standard Sales - Order Conf.", SalesHeader);

        // [THEN] Dataset for item has values for Unit Price, Quantity, VAT, Line Amount
        // [THEN] Dataset for comment line has blank values for Unit Price, Quantity, VAT, Line Amount
        SalesHeader.Find();
        Assert.AreEqual(1, SalesHeader."No. Printed", '');
        VerifyPrintedReport(SalesHeader."No.", ItemNo);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 258773] Print report 'Standard Sales - Invoice' with one item line and one comment line
        Initialize();

        // [GIVEN] Sales Invoice with item line and comment line
        PostedDocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader.Get(PostedDocNo);
        SalesInvoiceHeader.SetRecFilter();

        // [WHEN] Run "Standard Sales - Invoice" report
        CommitAndRunReportOnPostedSalesInvoice(REPORT::"Standard Sales - Invoice", SalesInvoiceHeader);

        // [THEN] Dataset for item has values for Unit Price, Quantity, VAT, Line Amount
        // [THEN] Dataset for comment line has blank values for Unit Price, Quantity, VAT, Line Amount
        SalesInvoiceHeader.Find();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(1, SalesInvoiceHeader."No. Printed", '');
        VerifyPrintedReport(SalesInvoiceHeader."No.", SalesInvoiceLine."No.");
    end;

    [Test]
    [HandlerFunctions('StandardSalesCrMemoReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 258773] Print report 'Standard Sales - Credit Memo' with one item line and one comment line
        Initialize();

        // [GIVEN] Sales Credit Memo with item line and comment line
        PostedDocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader.Get(PostedDocNo);
        SalesCrMemoHeader.SetRecFilter();

        // [WHEN] Run "Standard Sales - Credit Memo" report
        CommitAndRunReportOnPostedSalesCreditMemo(REPORT::"Standard Sales - Credit Memo", SalesCrMemoHeader);

        // [THEN] Dataset for item has values for Unit Price, Quantity, VAT, Line Amount
        // [THEN] Dataset for comment line has blank values for Unit Price, Quantity, VAT, Line Amount
        SalesCrMemoHeader.Find();
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.FindFirst();
        Assert.AreEqual(1, SalesCrMemoHeader."No. Printed", '');
        VerifyPrintedReport(SalesCrMemoHeader."No.", SalesCrMemoLine."No.");
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceDraftReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesInvoiceDraft()
    var
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        // [SCENARIO 258773] Print report 'Standard Sales - Draft Invoice' with one item line and one comment line
        Initialize();

        // [GIVEN] Sales Invoice with item line and comment line
        ItemNo := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRecFilter();

        // [WHEN] Run "Standard Sales - Draft Invoice" report
        CommitAndRunReportOnSalesDocument(REPORT::"Standard Sales - Draft Invoice", SalesHeader);

        // [THEN] Dataset for item has values for Unit Price, Quantity, VAT, Line Amount
        // [THEN] Dataset for comment line has blank values for Unit Price, Quantity, VAT, Line Amount
        SalesHeader.Find();
        VerifyPrintedReport(SalesHeader."No.", ItemNo);
    end;

    [Test]
    [HandlerFunctions('StandardSalesInvoiceDraftReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardSalesInvoiceDraftFromPage()
    var
        ReportSelections: Record "Report Selections";
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Works differently in RU.
        Initialize();
        LibraryERM.SetEnableDataCheck(false);
        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"S.Invoice Draft";
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := REPORT::"Standard Sales - Draft Invoice";
        if ReportSelections.Insert() then;

        // Prepare
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRecFilter();
        Commit();

        // Execute
        SalesInvoice.OpenView();
        SalesInvoice.GotoKey(SalesHeader."Document Type", SalesHeader."No.");
        SalesInvoice.DraftInvoice.Invoke();
        SalesInvoice.Close();
        // Verify - see report request handler
        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderReqHandler')]
    [Scope('OnPrem')]
    procedure TestReportStandardPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        ItemNo: Code[20];
    begin
        Initialize();

        // Prepare
        ItemNo := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRecFilter();

        // Execute
        CommitAndRunReportOnPurchaseDocument(REPORT::"Standard Purchase - Order", PurchaseHeader);

        // Verify
        PurchaseHeader.Find();
        Assert.AreEqual(1, PurchaseHeader."No. Printed", '');
        VerifyPrintedPurchaseReport(PurchaseHeader."No.", ItemNo);
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Standard Document Reports");
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Standard Document Reports");

        ClearTable(DATABASE::Resource);

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();

        CompanyInformation.Get();
        if CompanyInformation."Giro No." = '' then
            CompanyInformation."Giro No." := '1234567';
        if CompanyInformation.IBAN = '' then
            CompanyInformation.IBAN := 'GB213 2342 34';
        if CompanyInformation."Bank Name" = '' then
            CompanyInformation."Bank Name" := 'My Bank';
        if CompanyInformation."Bank Account No." = '' then
            CompanyInformation."Bank Account No." := '12431243';
        if CompanyInformation."SWIFT Code" = '' then
            CompanyInformation."SWIFT Code" := 'GBBAKKXX';
        CompanyInformation.Modify();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Standard Document Reports");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        Resource: Record Resource;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::Resource:
                Resource.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[20]
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true)); // Post as Ship and Invoice.
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type") ItemNo: Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Tax Area Code", '');  // Required for CA.
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandDec(10, 2));
        ItemNo := SalesLine."No.";
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", '', 0);
        SalesLine.Validate(Description, LineCommentTxt);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type") ItemNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, '', '', LibraryRandom.RandDec(10, 2), '', WorkDate());
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Tax Area Code", '');  // Required for CA.
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandDec(10, 2));
        ItemNo := PurchaseLine."No.";
        PurchaseLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::" ", '', 0);
        PurchaseLine.Validate(Description, LineCommentTxt);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesHeaderWithWorkDescription(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; WorkDescription: Text)
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        SalesHeader.SetWorkDescription(WorkDescription);
        SalesHeader.Modify();
        SalesHeader.SetRecFilter();
    end;

    local procedure CommitAndRunReportOnSalesDocument(ReportNumber: Integer; var SalesHeader: Record "Sales Header")
    begin
        Commit(); // Necessary for running the report
        REPORT.RunModal(ReportNumber, true, true, SalesHeader);
    end;

    local procedure CommitAndRunReportOnPurchaseDocument(ReportNumber: Integer; var PurchaseHeader: Record "Purchase Header")
    begin
        Commit(); // Necessary for running the report
        REPORT.RunModal(ReportNumber, true, true, PurchaseHeader);
    end;

    local procedure CommitAndRunReportOnPostedSalesInvoice(ReportNumber: Integer; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        Commit(); // Necessary for running the report
        REPORT.RunModal(ReportNumber, true, true, SalesInvoiceHeader);
    end;

    local procedure CommitAndRunReportOnPostedSalesCreditMemo(ReportNumber: Integer; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        Commit(); // Necessary for running the report
        REPORT.RunModal(ReportNumber, true, true, SalesCrMemoHeader);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesQuoteReqHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.LogInteraction.SetValue(true);
        StandardSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesOrderReqHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        StandardSalesOrderConf.LogInteraction.SetValue(true);
        StandardSalesOrderConf.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceReqHandler(var StandardSalesInvoice: TestRequestPage "Standard Sales - Invoice")
    begin
        StandardSalesInvoice.LogInteraction.SetValue(true);
        StandardSalesInvoice.DisplayShipmentInformation.SetValue(true);
        StandardSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesCrMemoReqHandler(var StandardSalesCreditMemo: TestRequestPage "Standard Sales - Credit Memo")
    begin
        StandardSalesCreditMemo.LogInteraction.SetValue(true);
        StandardSalesCreditMemo.DisplayShipmentInformation.SetValue(true);
        StandardSalesCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesInvoiceDraftReqHandler(var StandardSalesDraftInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        StandardSalesDraftInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardPurchaseOrderReqHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        StandardPurchaseOrder.LogInteraction.SetValue(true);
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure VerifyPrintedReport(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        Row: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo', DocumentNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'DocumentNo', DocumentNo);

        LibraryReportDataset.Reset();
        Row := LibraryReportDataset.FindRow('ItemNo_Line', ItemNo);
        LibraryReportDataset.MoveToRow(Row + 1);
        LibraryReportDataset.AssertCurrentRowValueNotEquals('UnitPrice', '');
        LibraryReportDataset.AssertCurrentRowValueNotEquals('Quantity_Line', '');
        LibraryReportDataset.AssertCurrentRowValueNotEquals('VATPct_Line', '');
        LibraryReportDataset.AssertCurrentRowValueNotEquals('LineAmount_Line', '');

        LibraryReportDataset.Reset();
        Row := LibraryReportDataset.FindRow('Description_Line', LineCommentTxt);
        LibraryReportDataset.MoveToRow(Row + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_Line', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('VATPct_Line', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('LineAmount_Line', '');
    end;

    local procedure VerifyPrintedPurchaseReport(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        Row: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_PurchHeader', DocumentNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'No_PurchHeader', DocumentNo);

        LibraryReportDataset.Reset();
        Row := LibraryReportDataset.FindRow('No_PurchLine', ItemNo);
        LibraryReportDataset.MoveToRow(Row + 1);
        LibraryReportDataset.AssertCurrentRowValueNotEquals('DirUnitCost_PurchLine', '');
        LibraryReportDataset.AssertCurrentRowValueNotEquals('Qty_PurchLine', '');

        LibraryReportDataset.Reset();
        Row := LibraryReportDataset.FindRow('Desc_PurchLine', LineCommentTxt);
        LibraryReportDataset.MoveToRow(Row + 1);
        LibraryReportDataset.AssertCurrentRowValueEquals('DirUnitCost_PurchLine', '');
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_PurchLine', '');
    end;

    local procedure VerifyPrintedReportWithWorkDescription(WorkDescription: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('WorkDescriptionLine', WorkDescription);
    end;
}

