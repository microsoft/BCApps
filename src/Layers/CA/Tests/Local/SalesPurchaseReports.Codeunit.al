codeunit 144002 "Sales/Purchase Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [FCY] [Order Status]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ItemNo: Label 'Item__No__';
        InvDiscountAmount: Label 'Purchase_Line__Inv__Discount_Amount_';
        InvDiscountAmountSales: Label 'Sales_Line__Inv__Discount_Amount_';
        LineDiscountAmount: Label 'Purchase_Line__Line_Discount_Amount_';
        LineDiscountAmountSales: Label 'Sales_Line__Line_Discount_Amount_';
        OutstandingAmount: Label 'Purchase_Line___Outstanding_Amount_';
        OutstandingAmountSales: Label 'Sales_Line___Outstanding_Amount_';

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseOrderStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatusReportWithCurrency()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        LineDiscAmt: Decimal;
        InvDiscAmt: Decimal;
    begin
        // Verify Purchase Order Status Report when Purchase Order in foreign Currency.

        // Setup: Create Vendor with Currency and Invoice Discount %. Create Purchase Order and calculate Invoice Discount for it.
        Initialize();
        CreateVendorWithCurrency(Vendor);
        CreateInvDiscForVendor(Vendor."No.", Vendor."Currency Code");
        CreatePurchaseOrder(PurchaseLine, Vendor."No.", LibraryRandom.RandDec(10, 2));  // Taken Random Line Discount.
        CalcInvDiscountForPurchase(PurchaseLine."Document No.");

        // Calculate amounts in base currency.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LineDiscAmt := LibraryERM.ConvertCurrency(PurchaseLine."Line Discount Amount", Vendor."Currency Code", '', WorkDate());
        InvDiscAmt := LibraryERM.ConvertCurrency(PurchaseLine."Inv. Discount Amount", Vendor."Currency Code", '', WorkDate());
        Amount := LibraryERM.ConvertCurrency(PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount", Vendor."Currency Code", '', WorkDate());
        LibraryVariableStorage.Enqueue(PurchaseLine."No.");  // Enqueue value for PurchaseOrderStatusRequestPageHandler.
        Commit();  // Commit is required to run the Report.

        // Exercise: Run Purchase Order Status Report.
        REPORT.Run(REPORT::"Purchase Order Status");

        // Verify: Verify all amounts are in base currency on Purchase Order Status Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ItemNo, PurchaseLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(OutstandingAmount, Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals(LineDiscountAmount, LineDiscAmt);
        LibraryReportDataset.AssertCurrentRowValueEquals(InvDiscountAmount, InvDiscAmt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesOrderStatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStatusReportWithCurrency()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Amount: Decimal;
        LineDiscAmt: Decimal;
        InvDiscAmt: Decimal;
    begin
        // Verify Sales Order Status Report when Sales Order in foreign Currency.

        // Setup: Create Customer with Currency and Invoice Discount %. Create Sales Order and calculate Invoice Discount for it.
        Initialize();
        CreateCustomerWithCurrency(Customer);
        CreateInvDiscForCustomer(Customer."No.", Customer."Currency Code");
        CreateSalesOrder(SalesLine, Customer."No.", LibraryRandom.RandDec(10, 2));  // Taken Random Line Discount.
        CalcInvDiscountForSales(SalesLine."Document No.");

        // Calculate amounts in base currency.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        LineDiscAmt := LibraryERM.ConvertCurrency(SalesLine."Line Discount Amount", Customer."Currency Code", '', WorkDate());
        InvDiscAmt := LibraryERM.ConvertCurrency(SalesLine."Inv. Discount Amount", Customer."Currency Code", '', WorkDate());
        Amount := LibraryERM.ConvertCurrency(SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", Customer."Currency Code", '', WorkDate());
        LibraryVariableStorage.Enqueue(SalesLine."No.");  // Enqueue value for SalesOrderStatusRequestPageHandler.
        Commit();  // Commit is required to run the Report.

        // Exercise: Run Sales Order Status Report.
        REPORT.Run(REPORT::"Sales Order Status");

        // Verify: Verify all amounts are in base currency on Sales Order Status Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ItemNo, SalesLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(OutstandingAmountSales, Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals(LineDiscountAmountSales, LineDiscAmt);
        LibraryReportDataset.AssertCurrentRowValueEquals(InvDiscountAmountSales, InvDiscAmt);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        Clear(LibraryReportDataset);
        LibraryERMCountryData.CreateVATData();
    end;

    local procedure CalcInvDiscountForPurchase(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.CalculateInvoiceDiscount.Invoke();  // Invoke Calculate Invoice Discount.
    end;

    local procedure CalcInvDiscountForSales(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.CalculateInvoiceDiscount.Invoke();
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithCurrency(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CreateCurrency());
        Customer.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Taken Random Unit Price.
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));  // Taken Random Last Direct Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateInvDiscForVendor(VendorNo: Code[20]; CurrencyCode: Code[10])
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, CurrencyCode, LibraryRandom.RandDec(10, 2));  // Taken Random Minimum Amount.
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Taken Random Discount %.
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateInvDiscForCustomer(CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, CurrencyCode, LibraryRandom.RandDec(10, 2));  // Taken Random Minimum Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Taken Random Discount %.
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; LineDiscount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Taken Random Quantity.
        PurchaseLine.Validate("Line Discount %", LineDiscount);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; LineDiscount: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Taken Random Quantity.
        SalesLine.Validate("Line Discount %", LineDiscount);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendorWithCurrency(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency());
        Vendor.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatusRequestPageHandler(var PurchaseOrderStatus: TestRequestPage "Purchase Order Status")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseOrderStatus.Item.SetFilter("No.", No);
        PurchaseOrderStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatusRequestPageHandler(var SalesOrderStatus: TestRequestPage "Sales Order Status")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesOrderStatus.Item.SetFilter("No.", No);
        SalesOrderStatus.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

