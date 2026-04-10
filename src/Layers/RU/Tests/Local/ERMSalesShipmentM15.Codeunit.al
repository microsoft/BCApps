codeunit 144706 "ERM Sales Shipment M-15"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        NoSeriesNotChangedErr: Label 'No Series was not changed after 1T report run without preview.';
        NoSeriesChangedErr: Label 'No Series changed after 1T report run with preview.';

    [Test]
    [Scope('OnPrem')]
    procedure M15_NoSeriesNotChangedInPreviewMode()
    var
        SalesHeader: Record "Sales Header";
        ExpectedDocumentNo: Code[20];
        LineQty: Integer;
    begin
        // check Series No has the same No before and after printing in Preview Mode
        ExpectedDocumentNo := GetNextShippingNo();

        PrintM15SalesOrder(SalesHeader, LineQty, true);

        Assert.AreEqual(ExpectedDocumentNo, GetNextShippingNo(), NoSeriesChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M15_NoSeriesChangedInPrintMode()
    var
        SalesHeader: Record "Sales Header";
        ExpectedDocumentNo: Code[20];
        LineQty: Integer;
    begin
        // check Document No has the same No as in Series No
        ExpectedDocumentNo := GetNextShippingNo();

        PrintM15SalesOrder(SalesHeader, LineQty, false);

        Assert.AreEqual(IncStr(ExpectedDocumentNo), GetNextShippingNo(), NoSeriesNotChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M15_DocumentNo()
    var
        SalesHeader: Record "Sales Header";
        LineQty: Integer;
    begin
        PrintM15SalesOrder(SalesHeader, LineQty, false);

        LibraryReportValidation.VerifyCellValue(5, 9, SalesHeader."Shipping No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M15_LineAmount()
    var
        SalesHeader: Record "Sales Header";
        LineQty: Integer;
    begin
        PrintM15SalesOrder(SalesHeader, LineQty, false);

        LibraryReportValidation.VerifyCellValue(24 + LineQty, 12, GetLineAmount(SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M15_LineAmountIncVAT()
    var
        SalesHeader: Record "Sales Header";
        LineQty: Integer;
    begin
        PrintM15SalesOrder(SalesHeader, LineQty, false);

        LibraryReportValidation.VerifyCellValue(24 + LineQty, 14, GetLineAmountIncVAT(SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M15_TotalWrittenIntAmount()
    var
        SalesHeader: Record "Sales Header";
        LineQty: Integer;
    begin
        PrintM15SalesOrder(SalesHeader, LineQty, false);

        LibraryReportValidation.VerifyCellValue(28 + LineQty, 2, GetSalesOrderIntWrittenAmount(SalesHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure M15_TotalWrittenDecAmount()
    var
        SalesHeader: Record "Sales Header";
        LineQty: Integer;
    begin
        PrintM15SalesOrder(SalesHeader, LineQty, false);

        LibraryReportValidation.VerifyCellValue(28 + LineQty, 9, GetSalesOrderDecWrittenAmount(SalesHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedM15_DocumentNo()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        DocumentNo := PrintM15SalesShipment(LineQty);

        LibraryReportValidation.VerifyCellValue(5, 9, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedM15_LineAmount()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        DocumentNo := PrintM15SalesShipment(LineQty);

        LibraryReportValidation.VerifyCellValue(24 + LineQty, 12, GetInvoiceLineAmount(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedM15_LineAmountIncVAT()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        DocumentNo := PrintM15SalesShipment(LineQty);

        LibraryReportValidation.VerifyCellValue(24 + LineQty, 14, GetInvoiceLineAmountIncVAT(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedM15_TotalWrittenIntAmount()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        DocumentNo := PrintM15SalesShipment(LineQty);

        LibraryReportValidation.VerifyCellValue(28 + LineQty, 2, GetSalesInvoiceIntWrittenAmount(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedM15_TotalWrittenDecAmount()
    var
        DocumentNo: Code[20];
        LineQty: Integer;
    begin
        DocumentNo := PrintM15SalesShipment(LineQty);

        LibraryReportValidation.VerifyCellValue(28 + LineQty, 9, GetSalesInvoiceDecWrittenAmount(DocumentNo));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure FindLastSalesLine(var SalesLine: Record "Sales Line"; OrderNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderNo);
        SalesLine.FindLast();
    end;

    local procedure FindLastSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; OrderNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("Document No.", OrderNo);
        SalesInvoiceLine.FindLast();
    end;

    local procedure GetLineAmount(OrderNo: Code[20]): Text
    var
        SalesLine: Record "Sales Line";
    begin
        FindLastSalesLine(SalesLine, OrderNo);
        exit(FormatAmount(SalesLine.Amount));
    end;

    local procedure GetLineAmountIncVAT(OrderNo: Code[20]): Text
    var
        SalesLine: Record "Sales Line";
    begin
        FindLastSalesLine(SalesLine, OrderNo);
        exit(FormatAmount(SalesLine."Amount Including VAT"));
    end;

    local procedure GetInvoiceLineAmount(DocumentNo: Code[20]): Text
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        FindLastSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        exit(FormatAmount(SalesInvoiceLine.Amount));
    end;

    local procedure GetInvoiceLineAmountIncVAT(DocumentNo: Code[20]): Text
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        FindLastSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        exit(FormatAmount(SalesInvoiceLine."Amount Including VAT"));
    end;

    local procedure PrintM15SalesOrder(var SalesHeader: Record "Sales Header"; var LineQty: Integer; Preview: Boolean)
    var
        SalesShipmentM15: Report "Sales Shipment M-15";
    begin
        Initialize();

        LineQty := LibraryRandom.RandIntInRange(2, 5);
        LibraryRUReports.CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, LineQty);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");

        SalesShipmentM15.SetTableView(SalesHeader);
        SalesShipmentM15.SetFileNameSilent(LibraryReportValidation.GetFileName(), Preview);
        SalesShipmentM15.UseRequestPage(false);
        SalesShipmentM15.Run();
        SalesHeader.Find(); // re-read record as there is an assignments inside report
    end;

    local procedure PrintM15SalesShipment(var LineQty: Integer) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesShipmentM15: Report "Posted Sales Shipment M-15";
    begin
        Initialize();

        LineQty := LibraryRandom.RandIntInRange(2, 5);
        LibraryRUReports.CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, LineQty);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        PostedSalesShipmentM15.SetTableView(SalesInvoiceHeader);
        PostedSalesShipmentM15.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedSalesShipmentM15.UseRequestPage(false);
        PostedSalesShipmentM15.Run();
    end;

    local procedure GetSalesOrderIntWrittenAmount(var SalesHeader: Record "Sales Header"): Text
    var
        LocMgt: Codeunit "Localisation Management";
        TotalAmount: Decimal;
    begin
        TotalAmount := LibraryRUReports.GetSalesLinesAmountIncVAT(SalesHeader);
        exit(LocMgt.Integer2Text(Round(TotalAmount, 1, '<'), 0, '', '', ''));
    end;

    local procedure GetSalesOrderDecWrittenAmount(var SalesHeader: Record "Sales Header"): Text
    var
        LocMgt: Codeunit "Localisation Management";
        TotalAmount: Decimal;
    begin
        TotalAmount := LibraryRUReports.GetSalesLinesAmountIncVAT(SalesHeader);
        exit(LocMgt.Integer2Text((TotalAmount - Round(TotalAmount, 1, '<')) * 100, 0, '', '', ''));
    end;

    local procedure GetSalesInvoiceIntWrittenAmount(DocumentNo: Code[20]): Text
    var
        LocMgt: Codeunit "Localisation Management";
        TotalAmount: Decimal;
    begin
        TotalAmount := LibraryRUReports.GetInvoiceLinesAmountIncVAT(DocumentNo);
        exit(LocMgt.Integer2Text(Round(TotalAmount, 1, '<'), 0, '', '', ''));
    end;

    local procedure GetSalesInvoiceDecWrittenAmount(DocumentNo: Code[20]): Text
    var
        LocMgt: Codeunit "Localisation Management";
        TotalAmount: Decimal;
    begin
        TotalAmount := LibraryRUReports.GetInvoiceLinesAmountIncVAT(DocumentNo);
        exit(LocMgt.Integer2Text((TotalAmount - Round(TotalAmount, 1, '<')) * 100, 0, '', '', ''));
    end;

    local procedure GetNextShippingNo(): Code[20]
    var
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
    begin
        SalesSetup.Get();
        exit(NoSeries.PeekNextNo(SalesSetup."Posted Shipment Nos."));
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    var
        StdRepMgt: Codeunit "Local Report Management";
    begin
        exit(StdRepMgt.FormatReportValue(Amount, 2));
    end;
}

