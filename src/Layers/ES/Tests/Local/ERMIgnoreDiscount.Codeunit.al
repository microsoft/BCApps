codeunit 144053 "ERM Ignore Discount"
{
    // 1. Test to verify values on Sales Statistics page with Ignore Discounts True on G/L Account.
    // 2. Test to verify values on Sales Statistics page with Ignore Discounts False on G/L Account.
    // 3. Test to verify values on Purchase Statistics page with Ignore Discounts True on G/L Account.
    // 4. Test to verify values on Purchase Statistics page with Ignore Discounts False on G/L Account.
    // 
    // Covers Test Cases for WI - 351288
    // --------------------------------------------------------------------
    // Test Function Name                                            TFS ID
    // --------------------------------------------------------------------
    // InvoiceDiscOnSalesStatisticsWithIgnoreDiscounts               151482
    // InvDiscOnSalesStatisticsWithoutIgnoreDiscounts                151483
    // InvoiceDiscOnPurchStatisticsWithIgnoreDiscounts               151713
    // InvDiscOnPurchStatisticsWithoutIgnoreDiscounts                151714

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscOnStatisticsWithIgnoreDiscounts()
    begin
        // Test to verify values on Sales Statistics page with Ignore Discounts True on G/L Account.
        Initialize();
        InvoiceDiscountAmountOnStatisticsPage(true, LibraryRandom.RandDec(10, 2), 0);  // True used for Ignore Discounts, Random value used for Customer Invoice Discount Percent and 0 used for Discount Percent.
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure InvDiscOnStatisticsWithoutIgnoreDiscounts()
    var
        DiscountPct: Decimal;
    begin
        // Test to verify values on Sales Statistics page with Ignore Discounts False on G/L Account.
        Initialize();
        DiscountPct := LibraryRandom.RandDec(10, 2);
        InvoiceDiscountAmountOnStatisticsPage(false, DiscountPct, DiscountPct);  // False used for Ignore Discounts.
    end;

    local procedure InvoiceDiscountAmountOnStatisticsPage(IgnoreDiscounts: Boolean; CustInvDiscountPct: Decimal; DiscountPct: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        OldCalcInvDiscount: Boolean;
    begin
        // Setup: Create Sales Invoice with Customer Invoice Discount. Open Sales Invoice page.
        OldCalcInvDiscount := UpdateCalcInvDiscountOnSalesReceivablesSetup(true);  // True used for Calculate Invoice Discount.
        CreateSalesInvoice(SalesLine, IgnoreDiscounts, CustInvDiscountPct);
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesLine."Document No.");
        EnqueueValuesForModalPageHandler(
          SalesLine.Amount, SalesLine.Amount * DiscountPct / 100, SalesLine.Amount - SalesLine.Amount * DiscountPct / 100);  // Enqueue values for SalesStatisticsModalPageHandler.

        // Exercise.
        SalesInvoice.Statistics.Invoke();  // Opens SalesStatisticsModalPageHandler.

        // Verify: Verification is done in SalesStatisticsModalPageHandler.

        // Tear Down.
        SalesInvoice.Close();
        UpdateCalcInvDiscountOnSalesReceivablesSetup(OldCalcInvDiscount);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscOnSalesStatisticsWithIgnoreDiscounts()
    begin
        // Test to verify values on Sales Statistics page with Ignore Discounts True on G/L Account.
        Initialize();
        InvoiceDiscountAmountOnSalesStatisticsPage(true, LibraryRandom.RandDec(10, 2), 0);  // True used for Ignore Discounts, Random value used for Customer Invoice Discount Percent and 0 used for Discount Percent.
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvDiscOnSalesStatisticsWithoutIgnoreDiscounts()
    var
        DiscountPct: Decimal;
    begin
        // Test to verify values on Sales Statistics page with Ignore Discounts False on G/L Account.
        Initialize();
        DiscountPct := LibraryRandom.RandDec(10, 2);
        InvoiceDiscountAmountOnSalesStatisticsPage(false, DiscountPct, DiscountPct);  // False used for Ignore Discounts.
    end;

    local procedure InvoiceDiscountAmountOnSalesStatisticsPage(IgnoreDiscounts: Boolean; CustInvDiscountPct: Decimal; DiscountPct: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        OldCalcInvDiscount: Boolean;
    begin
        // Setup: Create Sales Invoice with Customer Invoice Discount. Open Sales Invoice page.
        OldCalcInvDiscount := UpdateCalcInvDiscountOnSalesReceivablesSetup(true);  // True used for Calculate Invoice Discount.
        CreateSalesInvoice(SalesLine, IgnoreDiscounts, CustInvDiscountPct);
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesLine."Document No.");
        EnqueueValuesForModalPageHandler(SalesLine.Amount, SalesLine.Amount * DiscountPct / 100, SalesLine.Amount - SalesLine.Amount * DiscountPct / 100);  // Enqueue values for SalesStatisticsModalPageHandler.

        // Exercise.
        SalesInvoice.SalesStatistics.Invoke();  // Opens SalesStatisticsModalPageHandler.

        // Verify: Verification is done in SalesStatisticsModalPageHandler.

        // Tear Down.
        SalesInvoice.Close();
        UpdateCalcInvDiscountOnSalesReceivablesSetup(OldCalcInvDiscount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscOnPurchStatisticsWithIgnoreDiscounts()
    begin
        // Test to verify values on Purchase Statistics page with Ignore Discounts True on G/L Account.
        Initialize();
        InvoiceDiscountAmountOnPurchaseStatisticsPage(true, LibraryRandom.RandDec(10, 2), 0);  // True used for Ignore Discounts, Random value used for Vendor Invoice Discount Percent and 0 used for Discount Percent.
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure InvDiscOnPurchStatisticsWithoutIgnoreDiscounts()
    var
        DiscountPct: Decimal;
    begin
        // Test to verify values on Purchase Statistics page with Ignore Discounts False on G/L Account.
        Initialize();
        DiscountPct := LibraryRandom.RandDec(10, 2);
        InvoiceDiscountAmountOnPurchaseStatisticsPage(false, DiscountPct, DiscountPct);  // False used for Ignore Discounts.
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscOnPurchPageStatisticsWithIgnoreDiscounts()
    begin
        // Test to verify values on Purchase Statistics page with Ignore Discounts True on G/L Account.
        Initialize();
        InvoiceDiscountAmountOnPurchStatisticsPage(true, LibraryRandom.RandDec(10, 2), 0);  // True used for Ignore Discounts, Random value used for Vendor Invoice Discount Percent and 0 used for Discount Percent.
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvDiscOnPurchPageStatisticsWithoutIgnoreDiscounts()
    var
        DiscountPct: Decimal;
    begin
        // Test to verify values on Purchase Statistics page with Ignore Discounts False on G/L Account.
        Initialize();
        DiscountPct := LibraryRandom.RandDec(10, 2);
        InvoiceDiscountAmountOnPurchStatisticsPage(false, DiscountPct, DiscountPct);  // False used for Ignore Discounts.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure InvoiceDiscountAmountOnPurchaseStatisticsPage(IgnoreDiscounts: Boolean; VendInvDiscountPct: Decimal; DiscountPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        OldCalcInvDiscount: Boolean;
    begin
        // Setup: Create Purchase Invoice with Vendor Invoice Discount. Open Purchase Invoice page.
        OldCalcInvDiscount := UpdateCalcInvDiscountOnPurchasesPayablesSetup(true);  // True used for Calculate Invoice Discount.
        CreatePurchaseInvoice(PurchaseLine, IgnoreDiscounts, VendInvDiscountPct);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        EnqueueValuesForModalPageHandler(
          PurchaseLine.Amount, PurchaseLine.Amount * DiscountPct / 100,
          PurchaseLine.Amount - PurchaseLine.Amount * DiscountPct / 100);  // Enqueue values for PurchaseStatisticsModalPageHandler.

        // Exercise.
        PurchaseInvoice.Statistics.Invoke();  // Opens PurchaseStatisticsModalPageHandler.

        // Verify: Verification is done in PurchaseStatisticsModalPageHandler.

        // Tear Down.
        PurchaseInvoice.Close();
        UpdateCalcInvDiscountOnPurchasesPayablesSetup(OldCalcInvDiscount);
    end;
#endif

    local procedure InvoiceDiscountAmountOnPurchStatisticsPage(IgnoreDiscounts: Boolean; VendInvDiscountPct: Decimal; DiscountPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        OldCalcInvDiscount: Boolean;
    begin
        // Setup: Create Purchase Invoice with Vendor Invoice Discount. Open Purchase Invoice page.
        OldCalcInvDiscount := UpdateCalcInvDiscountOnPurchasesPayablesSetup(true);  // True used for Calculate Invoice Discount.
        CreatePurchaseInvoice(PurchaseLine, IgnoreDiscounts, VendInvDiscountPct);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseLine."Document No.");
        EnqueueValuesForModalPageHandler(
          PurchaseLine.Amount, PurchaseLine.Amount * DiscountPct / 100,
          PurchaseLine.Amount - PurchaseLine.Amount * DiscountPct / 100);  // Enqueue values for PurchaseStatisticsPageHandler.

        // Exercise.
        PurchaseInvoice.PurchaseStatistics.Invoke();  // Opens PurchaseStatisticsPageHandler.

        // Verify: Verification is done in PurchaseStatisticsPageHandler.

        // Tear Down.
        PurchaseInvoice.Close();
        UpdateCalcInvDiscountOnPurchasesPayablesSetup(OldCalcInvDiscount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomerWithInvoiceDiscount(DiscountPct: Decimal): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', 0);  // Blank used for Currency Code and 0 used for Minimum Amount.
        CustInvoiceDisc.Validate("Discount %", DiscountPct);
        CustInvoiceDisc.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(IgnoreDiscounts: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.FindVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Validate("Ignore Discounts", IgnoreDiscounts);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseInvoice(var PurchaseLine: Record "Purchase Line"; IgnoreDiscounts: Boolean; DiscountPct: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendorWithInvoiceDiscount(DiscountPct));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(IgnoreDiscounts),
          LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesLine: Record "Sales Line"; IgnoreDiscounts: Boolean; DiscountPct: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithInvoiceDiscount(DiscountPct));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(IgnoreDiscounts), LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVendorWithInvoiceDiscount(DiscountPct: Decimal): Code[20]
    var
        Vendor: Record Vendor;
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", '', 0);  // Blank used for Currency Code and 0 used for Minimum Amount.
        VendorInvoiceDisc.Validate("Discount %", DiscountPct);
        VendorInvoiceDisc.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure EnqueueValuesForModalPageHandler(Amount: Decimal; InvoiceDiscountAmount: Decimal; TotalAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);
        LibraryVariableStorage.Enqueue(TotalAmount);
    end;

    local procedure UpdateCalcInvDiscountOnPurchasesPayablesSetup(CalcInvDiscount: Boolean) OldCalcInvDiscount: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldCalcInvDiscount := PurchasesPayablesSetup."Calc. Inv. Discount";
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateCalcInvDiscountOnSalesReceivablesSetup(CalcInvDiscount: Boolean) OldCalcInvDiscount: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldCalcInvDiscount := SalesReceivablesSetup."Calc. Inv. Discount";
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsModalPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        Amount: Variant;
        InvDiscountAmount: Variant;
        TotalAmountOne: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(InvDiscountAmount);
        LibraryVariableStorage.Dequeue(TotalAmountOne);
        PurchaseStatistics.Amount.AssertEquals(Amount);
        PurchaseStatistics.InvDiscountAmount.AssertEquals(InvDiscountAmount);
        PurchaseStatistics.TotalAmount1.AssertEquals(TotalAmountOne);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        Amount: Variant;
        InvDiscountAmount: Variant;
        TotalAmountOne: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(InvDiscountAmount);
        LibraryVariableStorage.Dequeue(TotalAmountOne);
        PurchaseStatistics.Amount.AssertEquals(Amount);
        PurchaseStatistics.InvDiscountAmount.AssertEquals(InvDiscountAmount);
        PurchaseStatistics.TotalAmount1.AssertEquals(TotalAmountOne);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsModalPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        Amount: Variant;
        InvDiscountAmount: Variant;
        TotalAmountOne: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(InvDiscountAmount);
        LibraryVariableStorage.Dequeue(TotalAmountOne);
        SalesStatistics.Amount.AssertEquals(Amount);
        SalesStatistics.InvDiscountAmount.AssertEquals(InvDiscountAmount);
        SalesStatistics.TotalAmount1.AssertEquals(TotalAmountOne);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        Amount: Variant;
        InvDiscountAmount: Variant;
        TotalAmountOne: Variant;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(InvDiscountAmount);
        LibraryVariableStorage.Dequeue(TotalAmountOne);
        SalesStatistics.Amount.AssertEquals(Amount);
        SalesStatistics.InvDiscountAmount.AssertEquals(InvDiscountAmount);
        SalesStatistics.TotalAmount1.AssertEquals(TotalAmountOne);
    end;
}

