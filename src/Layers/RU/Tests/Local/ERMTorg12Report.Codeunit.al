codeunit 144702 "ERM Torg-12 Report"
{
    // // [FEATURE] [Reports]

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
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;
        NoSeriesNotChangedErr: Label 'No Series was not changed after 1T report run without preview.';
        NoSeriesChangedErr: Label 'No Series changed after 1T report run with preview.';

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintSalesOrder_NextDocumentNoSeriesChanged()
    var
        SalesHeader: Record "Sales Header";
        NoSeries: Codeunit "No. Series";
        ExpectedDocumentNo: Text;
    begin
        ExpectedDocumentNo := CreateSalesOrderAndPrintTorg12Report(SalesHeader, 1, false, 1);

        Assert.AreNotEqual(ExpectedDocumentNo, NoSeries.PeekNextNo(SalesHeader."Shipping No. Series", SalesHeader."Posting Date"), NoSeriesNotChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PreviewSalesOrder_NextDocumentNoSeriesNotChanged()
    var
        SalesHeader: Record "Sales Header";
        NoSeries: Codeunit "No. Series";
        ExpectedDocumentNo: Text;
    begin
        ExpectedDocumentNo := CreateSalesOrderAndPrintTorg12Report(SalesHeader, 1, true, 1);

        Assert.AreEqual(ExpectedDocumentNo, NoSeries.PeekNextNo(SalesHeader."Shipping No. Series", SalesHeader."Posting Date"), NoSeriesChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintSalesOrder_DocumentNoFilled()
    var
        SalesHeader: Record "Sales Header";
        ExpectedDocumentNo: Text;
    begin
        ExpectedDocumentNo := CreateSalesOrderAndPrintTorg12Report(SalesHeader, 1, false, 1);

        LibraryReportValidation.VerifyCellValue(19, 26, ExpectedDocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintSalesOrderMultipleLines_TotalAmoutCorrect()
    var
        SalesHeader: Record "Sales Header";
        LineQty: Integer;
    begin
        LineQty := LibraryRandom.RandInt(10);
        CreateSalesOrderAndPrintTorg12Report(SalesHeader, LineQty, false, 1);

        LibraryReportValidation.VerifyCellValue(26 + LineQty - 1, 54, Format(LibraryRUReports.GetSalesLinesAmountIncVAT(SalesHeader)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintShipmentWithMultipleLines_TotalAmoutCorrect()
    var
        LineQty: Integer;
        DocumentNo: Code[20];
    begin
        LineQty := LibraryRandom.RandInt(10);
        DocumentNo := CreateSalesShipmentAndPrintTorg12Report(LineQty, 1);

        LibraryReportValidation.VerifyCellValue(26 + LineQty - 1, 44, Format(GetShipmentLinesAmount(DocumentNo)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintInvoiceWithMultipleLines_TotalAmoutCorrect()
    var
        LineQty: Integer;
        DocumentNo: Code[20];
    begin
        LineQty := LibraryRandom.RandInt(10);
        DocumentNo := CreateSalesInvoiceAndPrintTorg12Report(LineQty, 1);

        LibraryReportValidation.VerifyCellValue(26 + LineQty - 1, 54, Format(LibraryRUReports.GetInvoiceLinesAmountIncVAT(DocumentNo)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintCrMemoWithMultipleLines_TotalAmoutCorrect()
    var
        LineQty: Integer;
        DocumentNo: Code[20];
    begin
        LineQty := LibraryRandom.RandInt(10);
        DocumentNo := CreateSalesCrMemoAndPrintTorg12Report(LineQty, 1);

        LibraryReportValidation.VerifyCellValue(26 + LineQty - 1, 44, Format(GetCrMemoLinesAmount(DocumentNo)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintSalesOrder_CheckSignature()
    var
        SalesHeader: Record "Sales Header";
        ReleasedByEmployeeName: Text[100];
        AccountantEmployeeName: Text[100];
        PassedByEmployeeName: Text[100];
    begin
        // [FEATURE] [Order Item Shipment TORG-12] [Signature]
        // [SCENARIO 371887] Report "Order Item Shipment TORG-12" should contain correct signature

        Initialize();
        // [GIVEN] Sales Order with signature: Released By = "X", Accountant = "Y", Passed By = "Z"
        CreateSalesOrderWithSignature(SalesHeader, ReleasedByEmployeeName, AccountantEmployeeName, PassedByEmployeeName);

        // [WHEN] Print report "Order Item Shipment TORG-12"
        PrintTorg12ToExcel(SalesHeader, false);

        // [THEN] Fields of reports should contain correct values:
        // [THEN] "Released By" in report = "X"
        LibraryReportValidation.VerifyCellValue(40, 24, ReleasedByEmployeeName);
        // [THEN] "Accountant" in report = "Y"
        LibraryReportValidation.VerifyCellValue(42, 24, AccountantEmployeeName);
        // [THEN] "Passed By" in report = "Z"
        LibraryReportValidation.VerifyCellValue(44, 24, PassedByEmployeeName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintSalesOrder_CheckHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Order Item Shipment TORG-12]
        // [SCENARIO 379462] Report "Order Item Shipment TORG-12" should print header if "Qty. to Ship" = 0 in the first line

        // [GIVEN] Sales Order with 2 lines
        // [GIVEN] "Qty. to Ship" = 0 in the first line

        // [WHEN] Printing report "Order Item Shipment TORG-12"
        CreateSalesOrderAndPrintTorg12Report(SalesHeader, 2, false, 0);

        // [THEN] Report header field "OKUD code" = 0330212
        LibraryReportValidation.VerifyCellValue(3, 50, '0330212');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintSalesShipment_CheckHeader()
    begin
        // [FEATURE] [Posted Ship. Shipment TORG-12]
        // [SCENARIO 379462] Report "Posted Ship. Shipment TORG-12" should print header if Quantity = 0 in the first line

        // [GIVEN] Posted Sales Shipment with 2 lines
        // [GIVEN] Quantity = 0 in the first line

        // [WHEN] Printing report "Posted Ship. Shipment TORG-12"
        CreateSalesShipmentAndPrintTorg12Report(2, 0);

        // [THEN] Report header field "OKUD code" = 0330212
        LibraryReportValidation.VerifyCellValue(3, 50, '0330212');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintSalesInvoice_CheckHeader()
    begin
        // [FEATURE] [Posted Inv. Shipment TORG-12]
        // [SCENARIO 379462] Report "Posted Inv. Shipment TORG-12" should print header if Quantity = 0 in the first line

        // [GIVEN] Posted Sales Invoice with 2 lines
        // [GIVEN] Quantity = 0 in the first line

        // [WHEN] Printing report "Posted Inv. Shipment TORG-12"
        CreateSalesInvoiceAndPrintTorg12Report(2, 0);

        // [THEN] Report header field "OKUD code"  = 0330212
        LibraryReportValidation.VerifyCellValue(3, 50, '0330212');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Torg12_PrintSalesCrMemo_CheckHeader()
    begin
        // [FEATURE] [Posted Cr. M. Shipment TORG-12]
        // [SCENARIO 379462] Report "Posted Cr. M. Shipment TORG-12" should print header if Quantity = 0 in the first line

        // [GIVEN] Posted Sales Credit Memo with 2 lines
        // [GIVEN] Quantity = 0 in the first line

        // [WHEN] Printing report "Posted Cr. M. Shipment TORG-12"
        CreateSalesCrMemoAndPrintTorg12Report(2, 0);

        // [THEN] Report header field "OKUD code" = 0330212
        LibraryReportValidation.VerifyCellValue(3, 50, '0330212');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure PrintTorg12ToExcel(SalesHeader: Record "Sales Header"; Preview: Boolean)
    var
        SalesHeaderWithFilters: Record "Sales Header";
        OrderItemShipmentTORG12: Report "Order Item Shipment TORG-12";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        OrderItemShipmentTORG12.InitializeRequest(LibraryReportValidation.GetFileName(), Preview);

        OrderItemShipmentTORG12.UseRequestPage(false);
        SalesHeaderWithFilters.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderWithFilters.SetRange("No.", SalesHeader."No.");
        OrderItemShipmentTORG12.SetTableView(SalesHeaderWithFilters);
        OrderItemShipmentTORG12.Run();
    end;

    local procedure GetShipmentLinesAmount(DocumentNo: Code[20]) TotalAmount: Decimal
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        TotalAmount := 0;
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        if SalesShipmentLine.FindSet() then
            repeat
                TotalAmount += SalesShipmentLine.Amount;
            until SalesShipmentLine.Next() = 0;
    end;

    local procedure GetCrMemoLinesAmount(DocumentNo: Code[20]): Decimal
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.CalcFields(Amount);
        exit(SalesCrMemoHeader.Amount);
    end;

    local procedure ChangeQtyInFirstLine(SalesHeader: Record "Sales Header"; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        ReleaseSalesDoc.Reopen(SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, QtyToShip);
        SalesLine.Modify(true);
        ReleaseSalesDoc.Run(SalesHeader);
    end;

    local procedure CreateSalesOrderAndPrintTorg12Report(var SalesHeader: Record "Sales Header"; LineQty: Integer; Preview: Boolean; QtyToShip: Decimal) DocumentNo: Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();

        LibraryRUReports.CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, LineQty);
        ChangeQtyInFirstLine(SalesHeader, QtyToShip);

        DocumentNo := NoSeries.PeekNextNo(SalesHeader."Shipping No. Series", SalesHeader."Posting Date");

        PrintTorg12ToExcel(SalesHeader, Preview);
    end;

    local procedure CreateSalesShipmentAndPrintTorg12Report(QuantityOfLines: Integer; QtyToShip: Decimal) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedShipShipmentTORG12: Report "Posted Ship. Shipment TORG-12";
    begin
        Initialize();

        LibraryRUReports.CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, QuantityOfLines);
        ChangeQtyInFirstLine(SalesHeader, QtyToShip);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesShipmentHeader.SetRange("No.", DocumentNo);

        LibraryReportValidation.SetFileName(DocumentNo);

        PostedShipShipmentTORG12.InitializeRequest(LibraryReportValidation.GetFileName(), false);
        PostedShipShipmentTORG12.SetTableView(SalesShipmentHeader);
        PostedShipShipmentTORG12.UseRequestPage(false);
        PostedShipShipmentTORG12.Run();
    end;

    local procedure CreateSalesInvoiceAndPrintTorg12Report(QuantityOfLines: Integer; QtyToShip: Decimal) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedInvShipmentTORG12: Report "Posted Inv. Shipment TORG-12";
    begin
        Initialize();

        LibraryRUReports.CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order, QuantityOfLines);
        ChangeQtyInFirstLine(SalesHeader, QtyToShip);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        LibraryReportValidation.SetFileName(DocumentNo);

        PostedInvShipmentTORG12.InitializeRequest(LibraryReportValidation.GetFileName(), false);
        PostedInvShipmentTORG12.SetTableView(SalesInvoiceHeader);
        PostedInvShipmentTORG12.UseRequestPage(false);
        PostedInvShipmentTORG12.Run();
    end;

    local procedure CreateSalesCrMemoAndPrintTorg12Report(QuantityOfLines: Integer; QtyToShip: Decimal) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedCrMShipmentTORG12: Report "Posted Cr. M. Shipment TORG-12";
    begin
        Initialize();

        LibraryRUReports.CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::"Credit Memo", QuantityOfLines);
        ChangeQtyInFirstLine(SalesHeader, QtyToShip);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesCrMemoHeader.SetRange("No.", DocumentNo);

        LibraryReportValidation.SetFileName(DocumentNo);

        PostedCrMShipmentTORG12.InitializeRequest(LibraryReportValidation.GetFileName(), false);
        PostedCrMShipmentTORG12.SetTableView(SalesCrMemoHeader);
        PostedCrMShipmentTORG12.UseRequestPage(false);
        PostedCrMShipmentTORG12.Run();
    end;

    local procedure CreateSalesOrderWithSignature(var SalesHeader: Record "Sales Header"; var ReleasedByEmployeeName: Text[100]; var AccountantEmployeeName: Text[100]; var PassedByEmployeeName: Text[100])
    var
        SalesLine: Record "Sales Line";
        DocSignature: Record "Document Signature";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        ClearSignaturesForSalesHeader(SalesHeader."No.");
        ReleasedByEmployeeName := AddDocSignatureEmployee(SalesHeader."No.", DocSignature."Employee Type"::ReleasedBy);
        AccountantEmployeeName := AddDocSignatureEmployee(SalesHeader."No.", DocSignature."Employee Type"::Accountant);
        PassedByEmployeeName := AddDocSignatureEmployee(SalesHeader."No.", DocSignature."Employee Type"::PassedBy);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure ClearSignaturesForSalesHeader(DocumentNo: Code[20])
    var
        DocSignature: Record "Document Signature";
    begin
        DocSignature.SetRange("Table ID", DATABASE::"Sales Header");
        DocSignature.SetRange("Document Type", 1);
        DocSignature.SetRange("Document No.", DocumentNo);
        DocSignature.DeleteAll();
    end;

    local procedure CreateSimpleEmployee(var Employee: Record Employee)
    var
        Option: Option Capitalized,Literal;
    begin
        Employee.Init();
        Employee."No." := LibraryUtility.GenerateRandomCode(Employee.FieldNo("No."), DATABASE::Employee);
        Employee."First Name" :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Employee."First Name"), Option::Literal), 1, MaxStrLen(Employee."First Name"));
        Employee."Last Name" :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Employee."Last Name"), Option::Literal), 1, MaxStrLen(Employee."Last Name"));
        Employee."Middle Name" :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Employee."Middle Name"), Option::Literal), 1, MaxStrLen(Employee."Middle Name"));
        Employee.Insert();
    end;

    local procedure AddDocSignatureEmployee(DocumentNo: Code[20]; EmployeeType: Option) EmployeeFullName: Text[100]
    var
        DocSignature: Record "Document Signature";
        Employee: Record Employee;
    begin
        CreateSimpleEmployee(Employee);
        EmployeeFullName := Employee.GetFullName();
        DocSignature.Init();
        DocSignature."Table ID" := DATABASE::"Sales Header";
        DocSignature."Document Type" := 1;
        DocSignature."Document No." := DocumentNo;
        DocSignature."Employee No." := Employee."No.";
        DocSignature."Employee Type" := EmployeeType;
        DocSignature."Employee Job Title" := Employee.GetJobTitleName();
        DocSignature."Employee Name" := EmployeeFullName;
        DocSignature.Insert();
    end;
}

