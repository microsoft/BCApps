codeunit 144514 "ERM FacturaInvoiceGovReg451"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRUReports: Codeunit "Library RU Reports";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        WrongFacturaFieldValErr: Label 'Report has wrong field value';
        DashTxt: Label '-';

    [Test]
    [Scope('OnPrem')]
    procedure FacturaPrepaymentDashPrint()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        Initialize();

        // Verify Dash fields filling if Factura printed from Prepayment Invoice
        CreateReleaseInvoice(
          SalesHeader, "Sales Line Type"::Item, LibraryInventory.CreateItemNo(), 1, true);
        CreatePrepaymentJournalLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", SalesHeader."No.", SalesHeader."Amount Including VAT");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        SalesInvHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvHeader.FindFirst();
        PostedFacturaInvoiceExcelExport(SalesInvHeader."No.");
        VerifyAddress(DashTxt, DashTxt);
        VerifyPrepFacturaLineValues(SalesInvHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemZeroQtyFacturaDashPrint()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Verify Dash Address filling if Invoice Item line Qty = 0
        CreateReleaseInvoice(
          SalesHeader, "Sales Line Type"::Item, LibraryInventory.CreateItemNo(), 0, false);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, "Sales Line Type"::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        FacturaInvoiceExcelExport(SalesHeader."No.");
        VerifyAddress(DashTxt, DashTxt);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PostedFacturaInvoiceExcelExport(DocumentNo);
        VerifyAddress(DashTxt, DashTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyResourceFacturaDashPrint()
    begin
        // Verify Resource line only Factura Dash address printing
        ResourceGLOrderFacturaDashPrint("Sales Line Type"::Resource, LibraryResource.CreateResourceNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyGLAccountFacturaDashPrint()
    begin
        // Verify G/L line only Factura Dash address printing
        ResourceGLOrderFacturaDashPrint("Sales Line Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
    end;


    [Test]
    [Scope('OnPrem')]
    procedure MixedResourceFacturaDashPrint()
    begin
        // Check Item line presence cancels Dash printing (Resource case)
        ResourceGLMixedOrderFacturaDashPrint("Sales Line Type"::Resource, LibraryResource.CreateResourceNo());
    end;


    [Test]
    [Scope('OnPrem')]
    procedure MixedGLAccFacturaDashPrint()
    begin
        // Check Item line presence cancels Dash printing (G/L Account case)
        ResourceGLMixedOrderFacturaDashPrint("Sales Line Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdateStockOutWarning();

        IsInitialized := true;
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
    end;

    local procedure CreateReleaseInvoice(var SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; Release: Boolean)
    var
        Item: Record Item;
        Customer: Record Customer;
    begin
        CreateInvoice(SalesHeader, Customer, Item);
        CreateSalesLine(SalesHeader, Type, No, Qty);
        if Release then
            LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateInvoice(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var Item: Record Item)
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
        LibraryRandom: Codeunit "Library - Random";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Qty);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(5));
        SalesLine.Modify(true);
    end;

    local procedure CreatePrepaymentJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; PrepDocNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateCustomerPrepmtGenJnlLine(GenJournalLine, CustomerNo, WorkDate(), PrepDocNo, Amount);
    end;

    local procedure UpdateStockOutWarning()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Stockout Warning" := false;
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifyAddress(ShipToAddress1: Text[50]; ShipToAddress2: Text[50])
    begin
        VerifyCellValue(10, 34, ShipToAddress1);
        VerifyCellValue(11, 34, ShipToAddress2);
    end;

    local procedure VerifyPrepFacturaLineValues(DocNo: Text)
    var
        FileName: Text;
    begin
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyFactura_DocNo(FileName, DocNo);
        LibraryRUReports.VerifyFactura_Unit(FileName, DashTxt, 0);
        LibraryRUReports.VerifyFactura_UnitName(FileName, DashTxt, 0);
        LibraryRUReports.VerifyFactura_Qty(FileName, DashTxt, 0);
        LibraryRUReports.VerifyFactura_Price(FileName, DashTxt, 0);
        LibraryRUReports.VerifyFactura_Amount(FileName, DashTxt, 0);
        LibraryRUReports.VerifyFactura_CountryCode(FileName, DashTxt, 0);
        LibraryRUReports.VerifyFactura_CountryName(FileName, DashTxt, 0);
        LibraryRUReports.VerifyFactura_GTD(FileName, DashTxt, 0);
    end;

    local procedure VerifyAddressNotDash(ShipToAddress1: Text[50]; ShipToAddress2: Text[50])
    var
        FoundValue: Boolean;
    begin
        Assert.AreNotEqual(
          ShipToAddress1,
          LibraryReportValidation.GetValueAt(FoundValue, 10, 34),
          WrongFacturaFieldValErr);
        Assert.AreNotEqual(
          ShipToAddress2,
          LibraryReportValidation.GetValueAt(FoundValue, 11, 34),
          WrongFacturaFieldValErr);
    end;

    local procedure VerifyCellValue(RowId: Integer; ColumnId: Integer; Value: Text)
    var
        FoundValue: Boolean;
    begin
        Assert.AreEqual(
          Value,
          LibraryReportValidation.GetValueAt(FoundValue, RowId, ColumnId),
          WrongFacturaFieldValErr);
    end;

    local procedure FacturaInvoiceExcelExport(DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        OrderFacturaInvoice: Report "Order Factura-Invoice (A)";
        FileName: Text;
    begin
        LibraryReportValidation.SetFileName(DocumentNo);
        FileName := LibraryReportValidation.GetFileName();
        SalesHeader.SetRange("No.", DocumentNo);
        OrderFacturaInvoice.SetTableView(SalesHeader);
        OrderFacturaInvoice.InitializeRequest(1, 1, false, true, false);
        OrderFacturaInvoice.SetFileNameSilent(FileName);
        OrderFacturaInvoice.UseRequestPage(false);
        OrderFacturaInvoice.Run();
    end;

    local procedure PostedFacturaInvoiceExcelExport(DocumentNo: Code[20])
    var
        SalesInvHeader: Record "Sales Invoice Header";
        PostedFacturaInvoice: Report "Posted Factura-Invoice (A)";
        FileName: Text;
    begin
        LibraryReportValidation.SetFileName(DocumentNo);
        FileName := LibraryReportValidation.GetFileName();
        SalesInvHeader.SetRange("No.", DocumentNo);
        PostedFacturaInvoice.SetTableView(SalesInvHeader);
        PostedFacturaInvoice.SetFileNameSilent(FileName);
        PostedFacturaInvoice.UseRequestPage(false);
        PostedFacturaInvoice.Run();
    end;

    local procedure ResourceGLMixedOrderFacturaDashPrint(SalesLine1Type: Enum "Sales Line Type"; ResourceFANo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();

        CreateReleaseInvoice(SalesHeader, SalesLine1Type, ResourceFANo, 1, false);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, LibraryInventory.CreateItemNo(), 1);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        FacturaInvoiceExcelExport(SalesHeader."No.");
        VerifyAddressNotDash(DashTxt, DashTxt);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PostedFacturaInvoiceExcelExport(DocumentNo);
        VerifyAddressNotDash(DashTxt, DashTxt);
    end;

    local procedure ResourceGLOrderFacturaDashPrint(SalesLine1Type: Enum "Sales Line Type"; ResourceFANo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        Initialize();

        CreateReleaseInvoice(
          SalesHeader, SalesLine1Type, ResourceFANo, 1, true);
        FacturaInvoiceExcelExport(SalesHeader."No.");
        VerifyAddress(DashTxt, DashTxt);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PostedFacturaInvoiceExcelExport(DocumentNo);
        VerifyAddress(DashTxt, DashTxt);
    end;
}

