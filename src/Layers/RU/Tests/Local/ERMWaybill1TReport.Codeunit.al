codeunit 144701 "ERM Waybill 1-T Report"
{
    // // [FEATURE] [Reports]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PrintWaybill1T_SalesOrderWithOneLine_ExcelValuesValid()
    begin
        CreateSalesOrderAndVerify1TReport(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintWaybill1T_SalesOrderWithMultipleLines_ExcelValuesValid()
    begin
        CreateSalesOrderAndVerify1TReport(1 + LibraryRandom.RandInt(5));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintWaybill1T_PostedShipmentWithOneLine_ExcelValuesValid()
    begin
        CreateSalesShipmentAndVerify1TReport(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintWaybill1T_PostedShipmentWithMultipleLines_ExcelValuesValid()
    begin
        CreateSalesShipmentAndVerify1TReport(1 + LibraryRandom.RandInt(5));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintWaybill1T_PostedInvoiceWithOneLine_ExcelValuesValid()
    begin
        CreateSalesInvoiceAndVerify1TReport(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintWaybill1T_PostedInvoiceWithMultipleLines_ExcelValuesValid()
    begin
        CreateSalesInvoiceAndVerify1TReport(1 + LibraryRandom.RandInt(5));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintWaybill1T_SalesOrder_CheckSignatures()
    var
        SalesHeader: Record "Sales Header";
        ResponsibleEmployeeName: Text[100];
        AccountantEmployeeName: Text[100];
        ReleasedByEmployeeName: Text[100];
    begin
        // [FEATURE] [Order Item Waybill 1-T] [Signature]
        // [SCENARIO 371887] Report "Order Item Waybill 1-T" should contain correct signature

        Initialize();
        // [GIVEN] Sales Order with signatures: Responsible = "X", Accountant = "Y", Released By = "Z"
        CreateSalesOrderWithSignatures(SalesHeader, ResponsibleEmployeeName, AccountantEmployeeName, ReleasedByEmployeeName);

        // [WHEN] Print report "Order Item Waybill 1-T"
        PrintOrderItemWaybill1TToExcel(SalesHeader);

        // [THEN] Fields of reports should contain correct values:
        // [THEN] "Responsible" in report = "X"
        LibraryReportValidation.VerifyCellValue(36, 13, ResponsibleEmployeeName);
        // [THEN] "Accountant" in report = "Y"
        LibraryReportValidation.VerifyCellValue(36, 27, AccountantEmployeeName);
        // [THEN] "Released By" in report = "Z"
        LibraryReportValidation.VerifyCellValue(38, 13, ReleasedByEmployeeName);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);

        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
    end;

    local procedure CreateReleasedSalesOrder(var SalesHeader: Record "Sales Header"; SalesLineQuantity: Integer)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        LibraryInventory: Codeunit "Library - Inventory";
        I: Integer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        LibraryInventory.CreateItem(Item);
        for I := 1 to SalesLineQuantity do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
            SalesLine.Validate("Unit Price", 1 + LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;

        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesOrderAndVerify1TReport(QuantityOfLines: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        CreateReleasedSalesOrder(SalesHeader, QuantityOfLines);

        LibraryReportValidation.SetFileName(SalesHeader."No.");

        PrintOrderItemWaybill1TToExcel(SalesHeader);

        SalesHeader.Find();
        VerifyWaybill1TReport(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesShipmentAndVerify1TReport(QuantityOfLines: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedShipItemWaybill1T: Report "Posted Ship. Item Waybill 1-T";
        DocumentNo: Code[20];
    begin
        Initialize();

        CreateReleasedSalesOrder(SalesHeader, QuantityOfLines);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesShipmentHeader.SetRange("No.", DocumentNo);

        LibraryReportValidation.SetFileName(DocumentNo);

        PostedShipItemWaybill1T.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedShipItemWaybill1T.SetTableView(SalesShipmentHeader);
        PostedShipItemWaybill1T.UseRequestPage(false);
        PostedShipItemWaybill1T.Run();

        SalesShipmentHeader.Get(DocumentNo);
        VerifyShipmentWaybill1TReport(SalesShipmentHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesInvoiceAndVerify1TReport(QuantityOfLines: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedInvoiceItemWaybill1T: Report "Posted Inv. Item Waybill 1-T";
        DocumentNo: Code[20];
    begin
        Initialize();

        CreateReleasedSalesOrder(SalesHeader, QuantityOfLines);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        LibraryReportValidation.SetFileName(DocumentNo);

        PostedInvoiceItemWaybill1T.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedInvoiceItemWaybill1T.SetTableView(SalesInvoiceHeader);
        PostedInvoiceItemWaybill1T.UseRequestPage(false);
        PostedInvoiceItemWaybill1T.Run();

        SalesInvoiceHeader.Get(DocumentNo);
        VerifyInvoiceWaybill1TReport(SalesInvoiceHeader);
    end;

    local procedure CreateSalesOrderWithSignatures(var SalesHeader: Record "Sales Header"; var ResponsibleEmployeeName: Text[100]; var AccountantEmployeeName: Text[100]; var ReleasedByEmployeeName: Text[100])
    var
        DocSignature: Record "Document Signature";
    begin
        CreateReleasedSalesOrder(SalesHeader, 1);
        ClearSignaturesForSalesHeader(SalesHeader."No.");
        ResponsibleEmployeeName := AddDocSignatureEmployee(SalesHeader."No.", DocSignature."Employee Type"::Responsible);
        AccountantEmployeeName := AddDocSignatureEmployee(SalesHeader."No.", DocSignature."Employee Type"::Accountant);
        ReleasedByEmployeeName := AddDocSignatureEmployee(SalesHeader."No.", DocSignature."Employee Type"::ReleasedBy);
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

    local procedure PrintOrderItemWaybill1TToExcel(SalesHeader: Record "Sales Header")
    var
        OrderItemWaybill1T: Report "Order Item Waybill 1-T";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        SalesHeader.SetRange("No.", SalesHeader."No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");

        OrderItemWaybill1T.SetFileNameSilent(LibraryReportValidation.GetFileName());
        OrderItemWaybill1T.SetTableView(SalesHeader);
        OrderItemWaybill1T.UseRequestPage(false);
        OrderItemWaybill1T.Run();
    end;

    local procedure VerifyWaybillHeaderValues(DocumentNo: Code[20]; PostingDate: Date; ShipToAddress: Text; BillToAddress: Text)
    var
        CompInfo: Record "Company Information";
    begin
        CompInfo.Get();

        LibraryReportValidation.VerifyCellValue(6, 42, DocumentNo);
        LibraryReportValidation.VerifyCellValue(7, 42, LocMgt.Date2Text(PostingDate));
        LibraryReportValidation.VerifyCellValue(9, 42, CompInfo."OKPO Code");
        LibraryReportValidation.VerifyCellValue(9, 8, StdRepMgt.GetCompanyName() + '. ' + StdRepMgt.GetLegalAddress());
        LibraryReportValidation.VerifyCellValue(11, 8, ShipToAddress);
        LibraryReportValidation.VerifyCellValue(13, 8, BillToAddress);
    end;

    local procedure VerifyWaybillLineValues(RowShift: Integer; LineNo: Code[20]; QtyToInvoice: Decimal; Description: Text; UnitOfMeasure: Text; Amount: Decimal)
    var
        Currency: Record Currency;
        LineRowId: Integer;
    begin
        Currency.InitRoundingPrecision();
        LineRowId := 23 + RowShift;
        LibraryReportValidation.VerifyCellValue(LineRowId, 1, LineNo);
        LibraryReportValidation.VerifyCellValue(LineRowId, 13, StdRepMgt.FormatReportValue(QtyToInvoice, 2));
        LibraryReportValidation.VerifyCellValue(LineRowId, 18, StdRepMgt.FormatReportValue(
          Round(Amount / QtyToInvoice, Currency."Unit-Amount Rounding Precision"), 2));
        LibraryReportValidation.VerifyCellValue(LineRowId, 21, Description);
        LibraryReportValidation.VerifyCellValue(LineRowId, 29, StdRepMgt.FormatTextValue(UnitOfMeasure));
        LibraryReportValidation.VerifyCellValue(LineRowId, 39, StdRepMgt.FormatReportValue(Amount, 2));
    end;

    local procedure VerifyWaybillFooterValues(TotalAmount: Decimal; PostingDate: Date; RowShift: Integer)
    begin
        LibraryReportValidation.VerifyCellValue(26 + RowShift, 4, LocMgt.Integer2Text(RowShift + 1, 1, '', '', ''));
        LibraryReportValidation.VerifyCellValue(28 + RowShift, 7, LocMgt.Integer2Text(RowShift + 1, 2, '', '', ''));
        LibraryReportValidation.VerifyCellValue(30 + RowShift, 39, StdRepMgt.FormatReportValue(TotalAmount, 2));
        LibraryReportValidation.VerifyCellValue(32 + RowShift, 14, '');
        LibraryReportValidation.VerifyCellValue(34 + RowShift, 8, LocMgt.Amount2Text('', TotalAmount));
        LibraryReportValidation.VerifyCellValue(40 + RowShift, 13, LocMgt.Date2Text(PostingDate));
    end;

    local procedure VerifyWaybill1TReport(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        RowShift: Integer;
    begin
        VerifyWaybillHeaderValues(
          SalesHeader."Shipping No.",
          SalesHeader."Posting Date",
          StdRepMgt.GetShipToAddrName(
            SalesHeader."Sell-to Customer No.", SalesHeader."Ship-to Code", SalesHeader."Ship-to Name", SalesHeader."Ship-to Name 2") +
            '  ' + SalesHeader."Ship-to City" + ' ' + SalesHeader."Ship-to Address" + ' ' + SalesHeader."Ship-to Address 2",
          StdRepMgt.GetCustName(SalesHeader."Bill-to Customer No.") + '  ' +
            SalesHeader."Bill-to City" + ' ' + SalesHeader."Bill-to Address" + ' ' + SalesHeader."Bill-to Address 2");

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();

        RowShift := 0;
        repeat
            VerifyWaybillLineValues(
              RowShift,
              SalesLine."No.",
              SalesLine."Qty. to Invoice",
              SalesLine.Description,
              SalesLine."Unit of Measure",
              SalesLine."Amount Including VAT");
            RowShift += 1;
        until SalesLine.Next() = 0;
        RowShift -= 1;

        SalesHeader.CalcFields("Amount Including VAT");
        VerifyWaybillFooterValues(SalesHeader."Amount Including VAT", SalesHeader."Posting Date", RowShift);
    end;

    local procedure VerifyShipmentWaybill1TReport(SalesShipmentHeader: Record "Sales Shipment Header")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        RowShift: Integer;
        Amount: Decimal;
    begin
        VerifyWaybillHeaderValues(
          SalesShipmentHeader."No.",
          SalesShipmentHeader."Posting Date",
          StdRepMgt.GetShipToAddrName(
            SalesShipmentHeader."Sell-to Customer No.", SalesShipmentHeader."Ship-to Code",
            SalesShipmentHeader."Ship-to Name", SalesShipmentHeader."Ship-to Name 2") +
          '  ' +
          SalesShipmentHeader."Ship-to City" +
          ' ' + SalesShipmentHeader."Ship-to Address" + ' ' + SalesShipmentHeader."Ship-to Address 2",
          StdRepMgt.GetCustName(SalesShipmentHeader."Bill-to Customer No.") + '  ' +
          SalesShipmentHeader."Bill-to City" +
          ' ' + SalesShipmentHeader."Bill-to Address" + ' ' + SalesShipmentHeader."Bill-to Address 2");

        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.FindSet();

        RowShift := 0;
        Amount := 0;
        repeat
            VerifyWaybillLineValues(
              RowShift,
              SalesShipmentLine."No.",
              SalesShipmentLine.Quantity,
              SalesShipmentLine.Description,
              SalesShipmentLine."Unit of Measure",
              SalesShipmentLine."Amount Including VAT");
            Amount += SalesShipmentLine."Amount Including VAT";
            RowShift += 1;
        until SalesShipmentLine.Next() = 0;
        RowShift -= 1;

        VerifyWaybillFooterValues(Amount, SalesShipmentHeader."Posting Date", RowShift);
    end;

    local procedure VerifyInvoiceWaybill1TReport(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        RowShift: Integer;
        Amount: Decimal;
    begin
        VerifyWaybillHeaderValues(
          SalesInvoiceHeader."No.",
          SalesInvoiceHeader."Posting Date",
          StdRepMgt.GetShipToAddrName(
            SalesInvoiceHeader."Sell-to Customer No.", SalesInvoiceHeader."Ship-to Code",
            SalesInvoiceHeader."Ship-to Name", SalesInvoiceHeader."Ship-to Name 2") +
          '  ' +
          SalesInvoiceHeader."Ship-to City" + ' ' + SalesInvoiceHeader."Ship-to Address" + ' ' + SalesInvoiceHeader."Ship-to Address 2",
          StdRepMgt.GetCustName(SalesInvoiceHeader."Bill-to Customer No.") + '  ' +
            SalesInvoiceHeader."Bill-to City" + ' ' + SalesInvoiceHeader."Bill-to Address" + ' ' + SalesInvoiceHeader."Bill-to Address 2");

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindSet();

        RowShift := 0;
        Amount := 0;
        repeat
            VerifyWaybillLineValues(
              RowShift,
              SalesInvoiceLine."No.",
              SalesInvoiceLine.Quantity,
              SalesInvoiceLine.Description,
              SalesInvoiceLine."Unit of Measure",
              SalesInvoiceLine."Amount Including VAT");
            Amount += SalesInvoiceLine."Amount Including VAT";
            RowShift += 1;
        until SalesInvoiceLine.Next() = 0;
        RowShift -= 1;

        VerifyWaybillFooterValues(Amount, SalesInvoiceHeader."Posting Date", RowShift);
    end;
}

