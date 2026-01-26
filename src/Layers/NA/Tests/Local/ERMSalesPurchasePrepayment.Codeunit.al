codeunit 142075 "ERM Sales/Purchase Prepayment"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label 'Validation error for Field: %1,  Message = ''%2 cannot be', Comment = '%1:FieldName;%2:FieldCaption';
        FieldUpdationErr: Label 'Validation error for Field: %1,  Message = ''%2 must be', Comment = '%1:FieldName;%2:FieldCaption';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepmtPctUpdateErrAfterPostingPurchPrepmtInv()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        No: Code[20];
    begin
        // Purpose of the test is to validate error on Modifying Prepayment % after Posting Prepayment Invoice.

        // Setup: Create and Post Purchase Prepayment Invoice.
        Initialize();
        No := CreateAndPostPurchasePrepaymentInvoice();
        OpenPurchaseOrder(PurchaseOrder, No);

        // Exercise.
        asserterror PurchaseOrder."Prepayment %".SetValue(LibraryRandom.RandDec(9, 2));  // Use Random Value to modify Prepayment %. Using 9 to avoid conflict with 10.

        // Verify: Error will pop up after modifying Prepayment %.
        Assert.ExpectedError(
          StrSubstNo(FieldUpdationErr, PurchaseLine.FieldCaption("Prepayment %"), PurchaseLine.FieldCaption("Prepayment %")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityUpdateErrAfterPostingPurchPrepmtInv()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        No: Code[20];
    begin
        // Purpose of the test is to validate error on Modifying Quantity after Posting Prepayment Invoice.

        // Setup: Create and Post Purchase Prepayment Invoice.
        Initialize();
        No := CreateAndPostPurchasePrepaymentInvoice();
        OpenPurchaseOrder(PurchaseOrder, No);

        // Exercise.
        asserterror PurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(9, 2));  // Use Random Value to modify Quantity. Using 9 to avoid conflict with 10.

        // Verify: Error will pop up after modifying Quantity.
        Assert.ExpectedError(StrSubstNo(AmountErr, PurchaseLine.FieldCaption(Quantity), PurchaseLine.FieldCaption("Prepmt. Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DirectUnitCostUpdateErrAfterPostingPurchPrepmtInv()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        No: Code[20];
    begin
        // Purpose of the test is to validate error on Modifying Direct Unit Cost after Posting Prepayment Invoice.

        // Setup: Create and Post Purchase Prepayment Invoice.
        Initialize();
        No := CreateAndPostPurchasePrepaymentInvoice();
        OpenPurchaseOrder(PurchaseOrder, No);

        // Exercise.
        asserterror PurchaseOrder.PurchLines."Direct Unit Cost".SetValue(LibraryRandom.RandDec(9, 2));  // Use Random Value to modify Direct Unit Cost. Using 9 to avoid conflict with 10.

        // Verify: Error will pop up after modifying Direct Unit Cost.
        Assert.ExpectedError(
          StrSubstNo(FieldUpdationErr, PurchaseLine.FieldName("Direct Unit Cost"), PurchaseLine.FieldCaption("Direct Unit Cost")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountUpdateErrAfterPostingPurchPrepmtInv()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
        No: Code[20];
    begin
        // Purpose of the test is to validate error on Modifying Line Amount after Posting Prepayment Invoice.

        // Setup: Create and Post Purchase Prepayment Invoice.
        Initialize();
        No := CreateAndPostPurchasePrepaymentInvoice();
        OpenPurchaseOrder(PurchaseOrder, No);

        // Exercise.
        asserterror PurchaseOrder.PurchLines."Line Amount".SetValue(LibraryRandom.RandDec(9, 2));  // Use Random Value to modify Line Amount. Using 9 to avoid conflict with 10.

        // Verify: Error will pop up after modifying Line Amount.
        Assert.ExpectedError(
          StrSubstNo(AmountErr, PurchaseLine.FieldName("Line Amount"), PurchaseLine.FieldCaption("Prepmt. Line Amount")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepmtPctUpdateErrAfterPostingSalesPrepmtInv()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        No: Code[20];
    begin
        // Purpose of the test is to validate error on Modifying Prepayment % after Posting Prepayment Invoice.

        // Setup: Create and Post Sales Prepayment Invoice.
        Initialize();
        No := CreateAndPostSalesPrepaymentInvoice();
        OpenSalesOrder(SalesOrder, No);

        // Exercise.
        asserterror SalesOrder."Prepayment %".SetValue(LibraryRandom.RandDec(9, 2));  // Use Random Value to modify Prepayment %. Using 9 to avoid conflict with 10.

        // Verify: Error will pop up after modifying Prepayment %.
        Assert.ExpectedError(StrSubstNo(FieldUpdationErr, SalesLine.FieldCaption("Prepayment %"), SalesLine.FieldCaption("Prepayment %")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityUpdateErrAfterPostingSalesPrepmtInv()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        No: Code[20];
    begin
        // Purpose of the test is to validate error on Modifying Quantity after Posting Prepayment Invoice.

        // Setup: Create and Post Sales Prepayment Invoice.
        Initialize();
        No := CreateAndPostSalesPrepaymentInvoice();
        OpenSalesOrder(SalesOrder, No);

        // Exercise.
        asserterror SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(9, 2));  // Use Random Value to modify Quantity. Using 9 to avoid conflict with 10.

        // Verify: Error will pop up after modifying Quantity.
        Assert.ExpectedError(StrSubstNo(AmountErr, SalesLine.FieldCaption(Quantity), SalesLine.FieldCaption("Prepmt. Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceUpdateErrAfterPostingSalesPrepmtInv()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        No: Code[20];
    begin
        // Purpose of the test is to validate error on Modifying Unit Price after Posting Prepayment Invoice.

        // Setup: Create and Post Sales Prepayment Invoice.
        Initialize();
        No := CreateAndPostSalesPrepaymentInvoice();
        OpenSalesOrder(SalesOrder, No);

        // Exercise.
        asserterror SalesOrder.SalesLines."Unit Price".SetValue(LibraryRandom.RandDec(9, 2));  // Use Random Value to modify Unit Price. Using 9 to avoid conflict with 10.

        // Verify: Error will pop up after modifying Unit Price.
        Assert.ExpectedError(StrSubstNo(FieldUpdationErr, SalesLine.FieldName("Unit Price"), SalesLine.FieldCaption("Unit Price")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmountUpdateErrAfterPostingSalesPrepmtInv()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        No: Code[20];
    begin
        // Purpose of the test is to validate error on Modifying Line Amount after Posting Prepayment Invoice.

        // Setup: Create and Post Sales Prepayment Invoice.
        Initialize();
        No := CreateAndPostSalesPrepaymentInvoice();
        OpenSalesOrder(SalesOrder, No);

        // Exercise.
        asserterror SalesOrder.SalesLines."Line Amount".SetValue(LibraryRandom.RandDec(9, 2));  // Use Random Value to modify Line Amount. Using 9 to avoid conflict with 10.

        // Verify: Error will pop up after modifying Line Amount.
        Assert.ExpectedError(StrSubstNo(AmountErr, SalesLine.FieldName("Line Amount"), SalesLine.FieldCaption("Prepmt. Line Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscPctUpdateErrAfterPostingSalesPrepmtInv()
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        No: Code[20];
    begin
        // Purpose of the test is to validate error on Modifying Line Discount % after Posting Prepayment Invoice.

        // Setup: Create and Post Sales Prepayment Invoice.
        Initialize();
        No := CreateAndPostSalesPrepaymentInvoice();
        OpenSalesOrder(SalesOrder, No);

        // Exercise.
        asserterror SalesOrder.SalesLines."Line Discount %".SetValue(LibraryRandom.RandDec(9, 2));  // Use Random Value to modify Line Discount %. Using 9 to avoid conflict with 10.

        // Verify: Error will pop up after modifying Line Discount %.
        Assert.ExpectedError(
          StrSubstNo(AmountErr, SalesLine.FieldCaption("Line Discount %"), SalesLine.FieldCaption("Prepmt. Line Amount")));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        ModifySalesReceivablesSetup();  // Modify Stock out Warning.
        LibraryPurchase.SetDiscountPostingSilent(0);
        LibrarySales.SetDiscountPostingSilent(0);

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateAndPostPurchasePrepaymentInvoice(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
    begin
        // Using Random for Quantity and Direct Unit and Prepayment %.
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(LineGLAccount));
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateAndPostSalesPrepaymentInvoice(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
    begin
        // Using Random for Quantity and Unit Price and Prepayment %.
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(LineGLAccount));
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccount."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        exit(SalesHeader."No.");
    end;

    local procedure CreateCustomer(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", LineGLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure ModifySalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure OpenPurchaseOrder(var PurchaseOrder: TestPage "Purchase Order"; No: Code[20])
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenSalesOrder(var SalesOrder: TestPage "Sales Order"; No: Code[20])
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

