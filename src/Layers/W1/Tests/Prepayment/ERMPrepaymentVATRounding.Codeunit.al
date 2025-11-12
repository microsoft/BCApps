codeunit 134104 "ERM Prepayment - VAT Rounding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment] [Rounding]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        isInitialized: Boolean;
        WrongPrepmtVATAmountBalance: Label 'Prepayment VAT Amount balance should be zero.';
        UnbalancedAccountErr: Label 'Balance is wrong for G/L Account: %1 filterd on document no.: %2.';

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtCrMemoOnSalesOrderWith2PrepmtInvTFS283693()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPrepmtAccNo: Code[20];
        LastGLRegisterNo: Integer;
        PostedPrepmtVATAmount: Decimal;
    begin
        Initialize();

        LastGLRegisterNo := GetLastGLRegisterNo();

        CreateVATPostingSetupWithVATPct(VATPostingSetup, GetSpecificVATPct());

        CreateSalesOrder(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", '', false);
        PrepareSalesOrderLine(SalesLine, SalesHeader."No.", VATPostingSetup."VAT Prod. Posting Group");
        SalesPrepmtAccNo := SetSalesPrepmtAccount(SalesLine);

        AddSalesOrderLine100PctPrepmt(SalesLine, GetLineAmountTFS283693(1));
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        LibrarySales.ReopenSalesDocument(SalesHeader);

        AddSalesOrderLine100PctPrepmt(SalesLine, GetLineAmountTFS283693(2));
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        PostedPrepmtVATAmount := SumNegativeVATAmount(LastGLRegisterNo);

        PostSalesPrepmtCrMemo(SalesHeader);

        PostedPrepmtVATAmount += SumPositiveVATAmount(LastGLRegisterNo);
        Assert.AreEqual(0, PostedPrepmtVATAmount, WrongPrepmtVATAmountBalance);

        VerifyZeroBalanceOnGLAcc(SalesPrepmtAccNo, LastGLRegisterNo);
        VerifyZeroBalanceOnGLAcc(VATPostingSetup."Sales VAT Account", LastGLRegisterNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtCrMemoOnPurchOrderWith2PrepmtInvTFS283693()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchPrepmtAccNo: Code[20];
        LastGLRegisterNo: Integer;
        PostedPrepmtVATAmount: Decimal;
    begin
        Initialize();

        LastGLRegisterNo := GetLastGLRegisterNo();

        CreateVATPostingSetupWithVATPct(VATPostingSetup, GetSpecificVATPct());
        CreatePurchOrder(PurchHeader, VATPostingSetup."VAT Bus. Posting Group", '', false);
        PreparePurchOrderLine(PurchLine, PurchHeader."No.", VATPostingSetup."VAT Prod. Posting Group");
        PurchPrepmtAccNo := SetPurchPrepmtAccount(PurchLine);

        AddPurchOrderLine100PctPrepmt(PurchLine, GetLineAmountTFS283693(1));
        PostPurchPrepmtInvoice(PurchHeader);

        LibraryPurchase.ReopenPurchaseDocument(PurchHeader);

        AddPurchOrderLine100PctPrepmt(PurchLine, GetLineAmountTFS283693(2));
        PostPurchPrepmtInvoice(PurchHeader);
        PostedPrepmtVATAmount := SumPositiveVATAmount(LastGLRegisterNo);

        PostPurchPrepmtCrMemo(PurchHeader);

        PostedPrepmtVATAmount += SumNegativeVATAmount(LastGLRegisterNo);
        Assert.AreEqual(0, PostedPrepmtVATAmount, WrongPrepmtVATAmountBalance);

        VerifyZeroBalanceOnGLAcc(PurchPrepmtAccNo, LastGLRegisterNo);
        VerifyZeroBalanceOnGLAcc(VATPostingSetup."Purchase VAT Account", LastGLRegisterNo);
    end;

    local procedure GetLineAmountTFS283693(LineNo: Integer): Decimal
    begin
        case LineNo of
            1:
                exit(17.02);
            2:
                exit(15.16);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtVATAmountOnInvoicedSalesOrderTFS258679()
    var
        SalesHeader: Record "Sales Header";
        LastGLRegisterNo: Integer;
        PostedPrepmtVATAmount: Decimal;
    begin
        Initialize();
        LastGLRegisterNo := GetLastGLRegisterNo();

        PostPrepmtInvForSalesOrderCase258679(SalesHeader);
        PostedPrepmtVATAmount := SumNegativeVATAmount(LastGLRegisterNo);

        InvoiceSalesOrder(SalesHeader);
        PostedPrepmtVATAmount += SumPositiveVATAmount(LastGLRegisterNo);

        Assert.AreEqual(0, PostedPrepmtVATAmount, WrongPrepmtVATAmountBalance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtVATAmountOnInvoicedPurchOrderTFS258679()
    var
        PurchHeader: Record "Purchase Header";
        LastGLRegisterNo: Integer;
        PostedPrepmtVATAmount: Decimal;
    begin
        Initialize();
        LastGLRegisterNo := GetLastGLRegisterNo();

        PostPrepmtInvForPurchOrderCase258679(PurchHeader);
        PostedPrepmtVATAmount := SumPositiveVATAmount(LastGLRegisterNo);

        InvoicePurchOrder(PurchHeader);
        PostedPrepmtVATAmount += SumNegativeVATAmount(LastGLRegisterNo);

        Assert.AreEqual(0, PostedPrepmtVATAmount, WrongPrepmtVATAmountBalance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtVATAmountOnInvoicedShipmentTFS258679()
    var
        SalesHeader: Record "Sales Header";
        ShipmentNo: Code[20];
        LastGLRegisterNo: Integer;
        PostedPrepmtVATAmount: Decimal;
    begin
        Initialize();
        LastGLRegisterNo := GetLastGLRegisterNo();

        PostPrepmtInvForSalesOrderCase258679(SalesHeader);
        PostedPrepmtVATAmount := SumNegativeVATAmount(LastGLRegisterNo);

        ShipmentNo := ShipSalesOrder(SalesHeader);
        PostSalesInvoiceForOrder(SalesHeader, ShipmentNo);
        PostedPrepmtVATAmount += SumPositiveVATAmount(LastGLRegisterNo);

        Assert.AreEqual(0, PostedPrepmtVATAmount, WrongPrepmtVATAmountBalance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtVATAmountOnInvoicedReceiptTFS258679()
    var
        PurchHeader: Record "Purchase Header";
        ReceiptNo: Code[20];
        LastGLRegisterNo: Integer;
        PostedPrepmtVATAmount: Decimal;
    begin
        Initialize();
        LastGLRegisterNo := GetLastGLRegisterNo();

        PostPrepmtInvForPurchOrderCase258679(PurchHeader);
        PostedPrepmtVATAmount := SumPositiveVATAmount(LastGLRegisterNo);

        ReceiptNo := ReceivePurchOrder(PurchHeader);
        PostPurchInvoiceForOrder(PurchHeader, ReceiptNo);
        PostedPrepmtVATAmount += SumNegativeVATAmount(LastGLRegisterNo);

        Assert.AreEqual(0, PostedPrepmtVATAmount, WrongPrepmtVATAmountBalance);
    end;

    local procedure PostPrepmtInvForSalesOrderCase258679(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
    begin
        PrepareSetupCase258679(VATPostingSetup, CurrencyCode);

        CreateSalesOrder(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", CurrencyCode, true);
        PrepareSalesOrderLine(SalesLine, SalesHeader."No.", VATPostingSetup."VAT Prod. Posting Group");
        SetSalesPrepmtAccount(SalesLine);

        AddThreeSalesOrderLinesCase258679(SalesLine);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure PostPrepmtInvForPurchOrderCase258679(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
    begin
        PrepareSetupCase258679(VATPostingSetup, CurrencyCode);

        CreatePurchOrder(PurchHeader, VATPostingSetup."VAT Bus. Posting Group", CurrencyCode, true);
        PreparePurchOrderLine(PurchLine, PurchHeader."No.", VATPostingSetup."VAT Prod. Posting Group");
        SetPurchPrepmtAccount(PurchLine);

        AddThreePurchOrderLinesCase258679(PurchLine);
        PostPurchPrepmtInvoice(PurchHeader);
    end;

    local procedure PrepareSetupCase258679(var VATPostingSetup: Record "VAT Posting Setup"; var CurrencyCode: Code[10])
    begin
        CreateVATPostingSetupWithVATPct(VATPostingSetup, GetSpecificVATPct());
        CurrencyCode := CreateCurrencyExchRate(1.34);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPrepmtAndPartShipTFS346807()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccNo: Code[20];
        LastGLRegisterNo: Integer;
    begin
        // Verify the Final Invoice is posted successfully for a Sales Order with 100% Prepayment and
        // partial Shipment.
        InitializeSetVATPostingSetup(VATPostingSetup, LastGLRegisterNo);

        CreateSalesOrder(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", '', false);
        PrepareSalesOrderLine(SalesLine, SalesHeader."No.", VATPostingSetup."VAT Prod. Posting Group");
        SalesPrepmtAccNo := SetSalesPrepmtAccount(SalesLine);

        AddSalesOrderLineCase346807(SalesLine);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        ChangeQtyToShipOnSalesLine(SalesLine, 1);
        InvoiceSalesOrder(SalesHeader);

        LibrarySales.ReopenSalesDocument(SalesHeader);
        ChangeQtyOnSalesLine(SalesHeader, 5);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        ChangeQtyToShipOnSalesLine(SalesLine, 3);
        InvoiceSalesOrder(SalesHeader);

        InvoiceSalesOrder(SalesHeader);

        VerifyZeroBalanceOnGLAcc(SalesPrepmtAccNo, LastGLRegisterNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithPrepmtAndPartReceiceTFS346807()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchPrepmtAccNo: Code[20];
        LastGLRegisterNo: Integer;
    begin
        // Verify the Final Invoice is posted successfully for a Purchase Order with 100% Prepayment and
        // partial Receipt.
        InitializeSetVATPostingSetup(VATPostingSetup, LastGLRegisterNo);

        CreatePurchOrder(PurchHeader, VATPostingSetup."VAT Bus. Posting Group", '', false);
        PreparePurchOrderLine(PurchLine, PurchHeader."No.", VATPostingSetup."VAT Prod. Posting Group");
        PurchPrepmtAccNo := SetPurchPrepmtAccount(PurchLine);

        AddPurchOrderLineCase346807(PurchLine);
        PostPurchPrepmtInvoice(PurchHeader);

        ChangeQtyToReceiveOnPurchLine(PurchLine, 1);
        InvoicePurchOrder(PurchHeader);

        LibraryPurchase.ReopenPurchaseDocument(PurchHeader);
        ChangeQtyOnPurchLine(PurchHeader, 5);
        PostPurchPrepmtInvoice(PurchHeader);

        ChangeQtyToReceiveOnPurchLine(PurchLine, 3);
        InvoicePurchOrder(PurchHeader);

        InvoicePurchOrder(PurchHeader);

        VerifyZeroBalanceOnGLAcc(PurchPrepmtAccNo, LastGLRegisterNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtVATAmountSalesOrderPriceIncVATTFS356880()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesPrepmtAccNo: Code[20];
        LastGLRegisterNo: Integer;
    begin
        // [SCENARIO 356880] Zero balance on Sales Prepayment Account after Sales order post with prices inclided VAT and specific VAT%
        InitializeSetVATPostingSetup(VATPostingSetup, LastGLRegisterNo);

        // [GIVEN] VAT posting setup with 19% VAT, customer and sales order with two lines with specific cost
        SalesPrepmtAccNo := CreateSalesOrderPriceInclVAT356880(SalesHeader, VATPostingSetup);

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post sales order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Balance on Sales Prepayment Account = 0
        VerifyZeroBalanceOnGLAcc(SalesPrepmtAccNo, LastGLRegisterNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtVATAmountPurchOrderPriceIncVATTFS356880()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchPrepmtAccNo: Code[20];
        LastGLRegisterNo: Integer;
    begin
        // [SCENARIO 356880] Zero balance on Purchase Prepayment Account after Purchase order post with prices inclided VAT and specific VAT%
        InitializeSetVATPostingSetup(VATPostingSetup, LastGLRegisterNo);

        // [GIVEN] VAT posting setup with 19% VAT, customer and sales order with two lines with specific cost
        PurchPrepmtAccNo := CreatePurchOrderPriceInclVAT356880(PurchaseHeader, VATPostingSetup);

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post sales order
        InvoicePurchOrder(PurchaseHeader);

        // [THEN] Balance on Purchase Prepayment Account = 0
        VerifyZeroBalanceOnGLAcc(PurchPrepmtAccNo, LastGLRegisterNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyCLERemainingAmtLCYAfterPostPrepmtInvAndExchRateChanging()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        AmountInclVAT: Decimal;
        NewDate: Date;
    begin
        // [FEATURE] [Sales] [Currency] [Prices Incl. VAT]
        // [SCENARIO 356261] 100% prepayment Sales Order (in FCY) invoiced twice on different dates produces zero GLEntry "Sales VAT Account" balance.
        Initialize();
        SetGeneralLedgerSetup(true);
        CreateVATPostingSetupWithVATPct(VATPostingSetup, GetSpecificVAT19Pct());
        AmountInclVAT := 733.73;
        NewDate := CalcDate('<1M>', WorkDate());

        // [GIVEN] Currency with different Exch. Rates on dates "D1", "D2"
        CurrencyCode := CreateCurrency();
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), 4.180095, 4.180095);
        LibraryERM.CreateExchangeRate(CurrencyCode, NewDate, 4.178296, 4.178296);

        // [GIVEN] Create Sales Order with "Posting Date" = "D1", post prepayment Invoice
        DocumentNo := CreateSalesOrderPostPrepmtInvoice(SalesHeader, VATPostingSetup, CurrencyCode, AmountInclVAT);

        // [GIVEN] Create and post Payment applied to the Invoice
        CreateAndApplyPaymentToInvoice(
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.", DocumentNo, CurrencyCode, -AmountInclVAT);

        // [GIVEN] Change Sales Order's "Posting Date" = "D2"
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Validate("Posting Date", NewDate);

        // [WHEN] Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GLEntry's "Sales VAT Account" has zero balance
        VerifyGLAccountBalance(VATPostingSetup."Sales VAT Account", DocumentNo, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyVLERemainingAmtLCYAfterPostPrepmtInvAndExchRateChanging()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        AmountInclVAT: Decimal;
        NewDate: Date;
    begin
        // [FEATURE] [Sales] [Currency] [Prices Incl. VAT]
        // [SCENARIO 356261] 100% prepayment Purchase Order (in FCY) invoiced twice on different dates produces zero GLEntry "Purchase VAT Account" balance.
        Initialize();
        SetGeneralLedgerSetup(true);
        CreateVATPostingSetupWithVATPct(VATPostingSetup, GetSpecificVAT19Pct());
        AmountInclVAT := 733.73;
        NewDate := CalcDate('<1M>', WorkDate());

        // [GIVEN] Currency with different Exch. Rates on dates "D1", "D2"
        CurrencyCode := CreateCurrency();
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), 4.180095, 4.180095);
        LibraryERM.CreateExchangeRate(CurrencyCode, NewDate, 4.178296, 4.178296);

        // [GIVEN] Create Purchase Order with "Posting Date" = "D1", post prepayment Invoice
        DocumentNo := CreatePurchOrderPostPrepmtInvoice(PurchaseHeader, VATPostingSetup, CurrencyCode, AmountInclVAT);

        // [GIVEN] Create and post Payment applied to the Invoice
        CreateAndApplyPaymentToInvoice(
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", DocumentNo, CurrencyCode, AmountInclVAT);

        // [GIVEN] Change Purchase Order's "Posting Date" = "D2"
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Posting Date", NewDate);
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();

        // [WHEN] Post Purchase Order
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GLEntry's "Purchase VAT Account" = 0
        VerifyGLAccountBalance(VATPostingSetup."Purchase VAT Account", DocumentNo, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscEqualsTo100Pct_ExclVAT()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvDiscountExclVAT: Decimal;
        InvDiscountInclVAT: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Prices Excl. VAT] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment (prepayment vat % = 0), invoice discount (order prepayment % + invoice discount % = 100),
        // [SCENARIO 229419] several lines with different vat setup (vat % <> 0), "Prices Including VAT" = FALSE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvDiscountExclVAT, InvDiscountInclVAT, VATAmount);

        // [GIVEN] Sales order with prepayment (85%), invoice discount (15%), "Prices Including VAT" = FALSE, several lines with different vat setup
        CreateSalesOrder_TFS229419_ExclVAT(SalesHeader, 15, 85);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvDiscountExclVAT, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 412.25, Amount Including VAT = 412.25
        // [THEN] Posted final invoice has Amount = 0, Amount Including VAT = 31.02
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscEqualsTo100Pct_InclVAT()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvDiscountExclVAT: Decimal;
        InvDiscountInclVAT: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Prices Incl. VAT] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment (prepayment vat % = 0), invoice discount (order prepayment % + invoice discount % = 100),
        // [SCENARIO 229419] several lines with different vat setup (vat % <> 0), "Prices Including VAT" = TRUE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvDiscountExclVAT, InvDiscountInclVAT, VATAmount);

        // [GIVEN] Sales order with prepayment (85%), invoice discount (15%), "Prices Including VAT" = TRUE, several lines with different vat setup
        CreateSalesOrder_TFS229419_InclVAT(SalesHeader, 15, 85);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvDiscountInclVAT, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 412.25, Amount Including VAT = 412.25
        // [THEN] Posted final invoice has Amount = 0, Amount Including VAT = 31.02
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscMoreThan100Pct_ExclVAT()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvDiscountExclVAT: Decimal;
        InvDiscountInclVAT: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Prices Excl. VAT] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment (prepayment vat % = 0), invoice discount (order prepayment % + invoice discount % > 100),
        // [SCENARIO 229419] several lines with different vat setup (vat % <> 0), "Prices Including VAT" = FALSE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvDiscountExclVAT, InvDiscountInclVAT, VATAmount);

        // [GIVEN] Sales order with prepayment (85.01%), invoice discount (15%), "Prices Including VAT" = FALSE, several lines with different vat setup
        CreateSalesOrder_TFS229419_ExclVAT(SalesHeader, 15, 85.01);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvDiscountExclVAT, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 412.25, Amount Including VAT = 412.25
        // [THEN] Posted final invoice has Amount = 0, Amount Including VAT = 31.02
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscMoreThan100Pct_InclVAT()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvDiscountExclVAT: Decimal;
        InvDiscountInclVAT: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Prices Incl. VAT] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment (prepayment vat % = 0), invoice discount (order prepayment % + invoice discount % > 100),
        // [SCENARIO 229419] several lines with different vat setup (vat % <> 0), "Prices Including VAT" = TRUE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvDiscountExclVAT, InvDiscountInclVAT, VATAmount);

        // [GIVEN] Sales order with prepayment (85.01%), invoice discount (15%), "Prices Including VAT" = TRUE, several lines with different vat setup
        CreateSalesOrder_TFS229419_InclVAT(SalesHeader, 15, 85.01);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvDiscountInclVAT, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 412.25, Amount Including VAT = 412.25
        // [THEN] Posted final invoice has Amount = 0, Amount Including VAT = 31.02
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscEqualsTo100Pct_ExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvDiscountExclVAT: Decimal;
        InvDiscountInclVAT: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Prices Excl. VAT] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment (prepayment vat % = 0), invoice discount (order prepayment % + invoice discount % = 100),
        // [SCENARIO 229419] several lines with different vat setup (vat % <> 0), "Prices Including VAT" = FALSE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvDiscountExclVAT, InvDiscountInclVAT, VATAmount);

        // [GIVEN] Purchase order with prepayment (85%), invoice discount (15%), "Prices Including VAT" = FALSE, several lines with different vat setup
        CreatePurchaseOrder_TFS229419_ExclVAT(PurchaseHeader, 15, 85);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvDiscountExclVAT, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := InvoicePurchOrder(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 412.25, Amount Including VAT = 412.25
        // [THEN] Posted final invoice has Amount = 0, Amount Including VAT = 31.02
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscEqualsTo100Pct_InclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvDiscountExclVAT: Decimal;
        InvDiscountInclVAT: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Prices Excl. VAT] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment (prepayment vat % = 0), invoice discount (order prepayment % + invoice discount % = 100),
        // [SCENARIO 229419] several lines with different vat setup (vat % <> 0), "Prices Including VAT" = TRUE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvDiscountExclVAT, InvDiscountInclVAT, VATAmount);

        // [GIVEN] Purchase order with prepayment (85%), invoice discount (15%), "Prices Including VAT" = TRUE, several lines with different vat setup
        CreatePurchaseOrder_TFS229419_InclVAT(PurchaseHeader, 15, 85);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvDiscountInclVAT, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := InvoicePurchOrder(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 412.25, Amount Including VAT = 412.25
        // [THEN] Posted final invoice has Amount = 0, Amount Including VAT = 31.02
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscMoreThan100Pct_ExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvDiscountExclVAT: Decimal;
        InvDiscountInclVAT: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Prices Excl. VAT] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment (prepayment vat % = 0), invoice discount (order prepayment % + invoice discount % > 100),
        // [SCENARIO 229419] several lines with different vat setup (vat % <> 0), "Prices Including VAT" = FALSE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvDiscountExclVAT, InvDiscountInclVAT, VATAmount);

        // [GIVEN] Purchase order with prepayment (85.01%), invoice discount (15%), "Prices Including VAT" = FALSE, several lines with different vat setup
        CreatePurchaseOrder_TFS229419_ExclVAT(PurchaseHeader, 15, 85.01);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvDiscountExclVAT, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := InvoicePurchOrder(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 412.25, Amount Including VAT = 412.25
        // [THEN] Posted final invoice has Amount = 0, Amount Including VAT = 31.02
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscMoreThan100Pct_InclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvDiscountExclVAT: Decimal;
        InvDiscountInclVAT: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Invoice Discount] [Prices Excl. VAT] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment (prepayment vat % = 0), invoice discount (order prepayment % + invoice discount % > 100),
        // [SCENARIO 229419] several lines with different vat setup (vat % <> 0), "Prices Including VAT" = TRUE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvDiscountExclVAT, InvDiscountInclVAT, VATAmount);

        // [GIVEN] Purchase order with prepayment (85.01%), invoice discount (15%), "Prices Including VAT" = TRUE, several lines with different vat setup
        CreatePurchaseOrder_TFS229419_InclVAT(PurchaseHeader, 15, 85.01);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvDiscountInclVAT, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := InvoicePurchOrder(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 412.25, Amount Including VAT = 412.25
        // [THEN] Posted final invoice has Amount = 0, Amount Including VAT = 31.02
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtWithLineDiscountAndAmountRountingPrecision()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        PrepmtGLAccount: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Currency] [Prices Incl. VAT] [Line Discount]
        // [SCENARIO 358986] Post partial sales invoice with Line discount and specific Amount Rounding Precision
        Initialize();

        // [GIVEN] VAT Posting Setup with 5% VAT
        CreateVATPostingSetupWithVATPct(VATPostingSetup, 5);
        // [GIVEN] Amount Rounding Precision = 0.01 in G/L Setup is more sharp than in Currency (0.1)
        GeneralLedgerSetup.Get();
        Currency.Get(CreateCurrencyExchRate(1));
        Currency.Validate("Amount Rounding Precision", GeneralLedgerSetup."Amount Rounding Precision" * 10);
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)" * 10);
        Currency.Modify(true);

        // [GIVEN] Sales Order with Prices Including VAT and Prepayment = 50%
        CreateSalesOrderSetCompressPrepmt(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", Currency.Code, true, true);
        SalesHeader.Validate("Prepayment %", 50);
        SalesHeader.Modify(true);

        Item.Get(CreateItemWithVATProdPostGroup(VATPostingSetup."VAT Prod. Posting Group"));
        PrepmtGLAccount := CreateGLAccount(Item."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateSalesPrepmtAccount(PrepmtGLAccount, SalesHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        // [GIVEN] Three Sales lines: 1st with Unit Price = 120, Quantity = 7, Line Discount % = 20.5, Qty. to Ship = 1
        // [GIVEN] 2nd line has Unit Price = 56, Quantity = 6, Line Discount % = 16.071, Qty. to Ship = 6
        // [GIVEN] 3rd line has Unit Price = 135, Quantity = 1, Line Discount % = 37.48148, Qty. to Ship = 1
        // [GIVEN] Total Amount Including VAT for partial invoice = 461.8 = 95.4 + 282 + 84.4
        // [GIVEN] VAT Amount = 11
        CreateSalesLineWithQtyPriceLineDiscount(SalesHeader, Item."No.", 120, 7, 1, 20.5); // Line Amount = 667.8 (95.4 per 1)
        CreateSalesLineWithQtyPriceLineDiscount(SalesHeader, Item."No.", 56, 6, 6, 16.071); // Line Amount = 282
        CreateSalesLineWithQtyPriceLineDiscount(SalesHeader, Item."No.", 135, 1, 1, 37.48148); // Line Amount = 84.4

        // [GIVEN] Prepayment invoice is posted for the sales order
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post the sales invoice
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] All G/L entries are balanced with rounding amount posted as realized gain = -0.03
        // [THEN] Amount 461.8 consists of amounts posted on prepayment G/l Account, payables account, VAT Amount and rounding gain amount
        Customer.Get(SalesHeader."Bill-to Customer No.");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyGLAccountBalance(PrepmtGLAccount, InvoiceNo, 219.93);
        VerifyGLAccountBalance(CustomerPostingGroup."Receivables Account", InvoiceNo, 230.9);
        VerifyGLAccountBalance(Currency."Realized Gains Acc.", InvoiceNo, -0.03);
        Assert.AreEqual(461.8, 219.93 + 230.9 + 11 - 0.03, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtWithLineDiscountAndAmountRountingPrecision()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PrepmtGLAccount: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Currency] [Prices Incl. VAT] [Line Discount]
        // [SCENARIO 358986] Post partial purchase invoice with Line discount and specific Amount Rounding Precision
        Initialize();

        // [GIVEN] VAT Posting Setup with 5% VAT
        CreateVATPostingSetupWithVATPct(VATPostingSetup, 5);
        // [GIVEN] Amount Rounding Precision = 0.01 in G/L Setup is more sharp than in Currency (0.1)
        GeneralLedgerSetup.Get();
        Currency.Get(CreateCurrencyExchRate(1));
        Currency.Validate("Amount Rounding Precision", GeneralLedgerSetup."Amount Rounding Precision" * 10);
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)" * 10);
        Currency.Modify(true);

        // [GIVEN] Purchase Order with Prices Including VAT and Prepayment = 50%
        CreatePurchOrderSetCompressPrepmt(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", Currency.Code, true, true);
        PurchaseHeader.Validate("Prepayment %", 50);
        PurchaseHeader.Modify(true);

        Item.Get(CreateItemWithVATProdPostGroup(VATPostingSetup."VAT Prod. Posting Group"));
        PrepmtGLAccount := CreateGLAccount(Item."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdatePurchasePrepmtAccount(PrepmtGLAccount, PurchaseHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        // [GIVEN] Three purchase lines: 1st with Unit Price = 120, Quantity = 7, Line Discount % = 20.5, Qty. to Ship = 1
        // [GIVEN] 2nd line has Unit Price = 56, Quantity = 6, Line Discount % = 16.071, Qty. to Ship = 6
        // [GIVEN] 3rd line has Unit Price = 135, Quantity = 1, Line Discount % = 37.48148, Qty. to Ship = 1
        // [GIVEN] Total Amount Including VAT for partial invoice = 461.8 = 95.4 + 282 + 84.4
        // [GIVEN] VAT Amount = 11
        CreatePurchLineWithQtyPriceLineDiscount(PurchaseHeader, Item."No.", 120, 7, 1, 20.5); // Line Amount = 667.8 (95.4 per 1)
        CreatePurchLineWithQtyPriceLineDiscount(PurchaseHeader, Item."No.", 56, 6, 6, 16.071); // Line Amount = 282
        CreatePurchLineWithQtyPriceLineDiscount(PurchaseHeader, Item."No.", 135, 1, 1, 37.48148); // Line Amount = 84.4

        // [GIVEN] Prepayment invoice is posted for the purchase order
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post the purchase invoice
        InvoiceNo := InvoicePurchOrder(PurchaseHeader);

        // [THEN] All G/L entries are balanced with rounding amount posted as realized loss = 0.03
        // [THEN] Amount 461.8 consists of amounts posted on prepayment G/l Account, payables account, VAT Amount and rounding losses amount
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VerifyGLAccountBalance(PrepmtGLAccount, InvoiceNo, -219.93);
        VerifyGLAccountBalance(VendorPostingGroup."Payables Account", InvoiceNo, -230.9);
        VerifyGLAccountBalance(Currency."Realized Losses Acc.", InvoiceNo, 0.03);
        Assert.AreEqual(461.8, 219.93 + 230.9 + 11 - 0.03, '');
    end;

    [Test]
    procedure SalesOrder100PctPrepmtWithInvDiscPartShip()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        ShipmentNo: Code[20];
        PartialInvoiceNo: Code[20];
        FinalInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice Discount] [Sales]
        // [SCENARIO 378205] Sales order post with 100% prepayment, invoice discount, line discount, several custom lines, partial shipment invoice
        Initialize();

        // [GIVEN] Sales order with 100% prepayment, several custom lines, invoice doscount, line discounts
        // [GIVEN] Post prepayment
        PrepmtDocNo := PostPrepmtInvForSalesOrderCase378205(SalesHeader);
        // [GIVEN] Post partial shipment
        ShipmentNo := ShipSalesOrder(SalesHeader);
        // [GIVEN] Post invoice from get shipment lines from posted shipment
        PartialInvoiceNo := PostSalesInvoiceForOrder(SalesHeader, ShipmentNo);

        // [WHEN]  Post final invoice
        FinalInvoiceNo := InvoiceSalesOrder(SalesHeader);

        // [THEN] Sales order is posted with zero Amount
        VerifyPostedSalesInvoiceAmounts(PrepmtDocNo, 4716.81, 5754.51);
        VerifyPostedSalesInvoiceAmounts(PartialInvoiceNo, 0, 0);
        VerifyPostedSalesInvoiceAmounts(FinalInvoiceNo, 0, 0);
    end;

    [Test]
    procedure PurchaseOrder100PctPrepmtWithInvDiscPartReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        ReceiptNo: Code[20];
        PartialInvoiceNo: Code[20];
        FinalInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice Discount] [Purchase]
        // [SCENARIO 378205] Purchase order post with 100% prepayment, invoice discount, line discount, several custom lines, partial receipt invoice
        Initialize();

        // [GIVEN] Purchase order with 100% prepayment, several custom lines, invoice doscount, line discounts
        // [GIVEN] Post prepayment
        PrepmtDocNo := PostPrepmtInvForPurchOrderCase378205(PurchaseHeader);
        // [GIVEN] Post partial receipt
        ReceiptNo := ReceivePurchOrder(PurchaseHeader);
        // [GIVEN] Post invoice from get receipt lines from posted receipt
        PartialInvoiceNo := PostPurchInvoiceForOrder(PurchaseHeader, ReceiptNo);

        // [WHEN]  Post final invoice
        FinalInvoiceNo := InvoicePurchOrder(PurchaseHeader);

        // [THEN] Purchase order is posted with zero Amount
        VerifyPostedPurchaseInvoiceAmounts(PrepmtDocNo, 4716.81, 5754.51);
        VerifyPostedPurchaseInvoiceAmounts(PartialInvoiceNo, 0, 0);
        VerifyPostedPurchaseInvoiceAmounts(FinalInvoiceNo, 0, 0);
    end;

    [Test]
    procedure SalesOrder100PctPrepmtDimsTwoPartialShipAndOneFinalInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        DimensionValue: array[4] of Record "Dimension Value";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        InvoiceNo: Code[20];
        ShipmentNo: array[2] of Code[20];
        GeneralPostingType: Enum "General Posting Type";
    begin
        // [FEATURE] [Sales] [Prices Incl. VAT] [Dimensions] [Compress Prepayment]
        // [SCENARIO 389323] Sales order with 100% prepayment, prices including VAT, compress prepayment, several custom lines,
        // [SCENARIO 389323] different dimensions and one full final invoice from get shipment lines after 2 partial shipments
        Initialize();

        // [GIVEN] Sales order with 100% prepayment, prices including VAT, compress prepayment, several custom lines and different dimensions
        CreateVATPostingSetupWithVATPct(VATPostingSetup, 10);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GeneralPostingType::Sale);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, '', true, true, 100);
        CreateFourDimensionValues(DimensionValue);
        UpdateSalesPrepmtAccountForGLLine(SalesHeader, VATPostingSetup, GLAccountNo);
        CreateSalesLineGLWithDim(SalesHeader, GLAccountNo, DimensionValue[1], 1, 1, 502.99997);
        CreateSalesLineGLWithDim(SalesHeader, GLAccountNo, DimensionValue[2], 1, 1, 303.99998);
        CreateSalesLineGLWithDim(SalesHeader, GLAccountNo, DimensionValue[3], 1, 1, 668.00028);
        CreateSalesLineGLWithDim(SalesHeader, GLAccountNo, DimensionValue[4], 2, 1, 17.99875);
        CreateSalesLineGLWithDim(SalesHeader, GLAccountNo, DimensionValue[2], 1, 0, 569.99997);
        CreateSalesLineGLWithDim(SalesHeader, GLAccountNo, DimensionValue[4], 1, 1, 42.9913);
        VerifySalesHeaderTotals(SalesHeader, 1930.9, 2123.99, 0, 2123.99);

        // [GIVEN] Post prepayment invoice
        VerifyPostedSalesInvoiceAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 1930.9, 2123.99);

        // [GIVEN] Post partial shipment
        ShipmentNo[1] := ShipSalesOrder(SalesHeader);
        // [GIVEN] Post partial (final) shipment
        ShipmentNo[2] := ShipSalesOrder(SalesHeader);

        // [GIVEN] Invoke get shipment lines from a new sales invoice and select two posted shipments
        // [WHEN] Post the invoice
        InvoiceNo := PostSalesInvoiceForOrder(SalesHeader, ShipmentNo[1] + '|' + ShipmentNo[2]);

        // [THEN] Final invoice has been posted with zero "Amount" and "Amount Including VAT"
        VerifyPostedSalesInvoiceAmounts(InvoiceNo, 0, 0);
        // [THEN] VAT Entry for the final invoice has zero balance by "Amount" value and by "Base" value
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
    end;

    [Test]
    procedure PurchaseOrder100PctPrepmtDimsTwoPartialReceiptAndOneFinalInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        DimensionValue: array[4] of Record "Dimension Value";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        InvoiceNo: Code[20];
        ReceiptNo: array[2] of Code[20];
        GeneralPostingType: Enum "General Posting Type";
    begin
        // [FEATURE] [Purchase] [Prices Incl. VAT] [Dimensions] [Compress Prepayment]
        // [SCENARIO 389323] Purchase order with 100% prepayment, prices including VAT, compress prepayment, several custom lines,
        // [SCENARIO 389323] different dimensions and one full final invoice from get receipt lines after 2 partial receipts
        Initialize();

        // [GIVEN] Purchase order with 100% prepayment, prices including VAT, compress prepayment, several custom lines and different dimensions
        CreateVATPostingSetupWithVATPct(VATPostingSetup, 10);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GeneralPostingType::Purchase);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, '', true, true, 100);
        CreateFourDimensionValues(DimensionValue);
        UpdatePurchasePrepmtAccountForGLLine(PurchaseHeader, VATPostingSetup, GLAccountNo);
        CreatePurchaseLineGLWithDim(PurchaseHeader, GLAccountNo, DimensionValue[1], 1, 1, 502.99997);
        CreatePurchaseLineGLWithDim(PurchaseHeader, GLAccountNo, DimensionValue[2], 1, 1, 303.99998);
        CreatePurchaseLineGLWithDim(PurchaseHeader, GLAccountNo, DimensionValue[3], 1, 1, 668.00028);
        CreatePurchaseLineGLWithDim(PurchaseHeader, GLAccountNo, DimensionValue[4], 2, 1, 17.99875);
        CreatePurchaseLineGLWithDim(PurchaseHeader, GLAccountNo, DimensionValue[2], 1, 0, 569.99997);
        CreatePurchaseLineGLWithDim(PurchaseHeader, GLAccountNo, DimensionValue[4], 1, 1, 42.9913);
        VerifyPurchaseHeaderTotals(PurchaseHeader, 1930.9, 2123.99, 0, 2123.99);

        // [GIVEN] Post prepayment invoice
        VerifyPostedPurchaseInvoiceAmounts(LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader), 1930.9, 2123.99);

        // [GIVEN] Post partial receipt
        ReceiptNo[1] := ReceivePurchOrder(PurchaseHeader);
        // [GIVEN] Post partial (final) receipt
        ReceiptNo[2] := ReceivePurchOrder(PurchaseHeader);

        // [GIVEN] Invoke get receipt lines from a new purchase invoice and select two posted receipts
        // [WHEN] Post the invoice
        InvoiceNo := PostPurchInvoiceForOrder(PurchaseHeader, ReceiptNo[1] + '|' + ReceiptNo[2]);

        // [THEN] Final invoice has been posted with zero "Amount" and "Amount Including VAT"
        VerifyPostedPurchaseInvoiceAmounts(InvoiceNo, 0, 0);
        // [THEN] VAT Entry for the final invoice has zero balance by "Amount" value and by "Base" value
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prepayment - VAT Rounding");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prepayment - VAT Rounding");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prepayment - VAT Rounding");
    end;

    local procedure InitializeSetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var LastGLRegisterNo: Integer)
    begin
        Initialize();
        SetGeneralLedgerSetup(true);
        CreateVATPostingSetupWithVATPct(VATPostingSetup, GetSpecificVAT19Pct());
        LastGLRegisterNo := GetLastGLRegisterNo();
    end;

    local procedure PrepareExpectedAmounts_TFS229419(var Amount: Decimal; var AmountIncludingVAT: Decimal; var InvDiscountExclVAT: Decimal; var InvDiscountInclVAT: Decimal; var VATAmount: Decimal)
    begin
        Amount := 412.25;
        AmountIncludingVAT := 443.27;
        InvDiscountExclVAT := 72.75;
        InvDiscountInclVAT := 78.23;
        VATAmount := 31.02;
    end;

    local procedure PrepareUnitPrices_TFS229419_ExclVAT(var UnitPrice: array[5] of Decimal)
    begin
        UnitPrice[1] := 99;
        UnitPrice[2] := 116.5;
        UnitPrice[3] := 86.5;
        UnitPrice[4] := 66.5;
        UnitPrice[5] := 116.5;
    end;

    local procedure PrepareUnitPrices_TFS229419_InclVAT(var UnitPrice: array[5] of Decimal)
    begin
        UnitPrice[1] := 103.95;
        UnitPrice[2] := 122.33;
        UnitPrice[3] := 97.75;
        UnitPrice[4] := 75.15;
        UnitPrice[5] := 122.32;
    end;

    local procedure PostPrepmtInvForSalesOrderCase378205(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
    begin
        CreateVATPostingSetupWithVATPct(VATPostingSetup, 22);
        CustomerNo :=
          CreateCustomerWithInvDiscount(
            LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"), 3);

        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, '', FALSE, TRUE, 0);
        PrepareSalesOrderLine(SalesLine, SalesHeader."No.", VATPostingSetup."VAT Prod. Posting Group");
        SetSalesPrepmtAccount(SalesLine);
        AddSalesOrderLinesCase378205(SalesLine);
        LibrarySales.CalcSalesDiscount(SalesHeader);

        VerifySalesHeaderTotals(SalesHeader, 4716.81, 5754.51, 145.88, 4716.81);
        EXIT(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader));
    end;

    local procedure PostPrepmtInvForPurchOrderCase378205(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
    begin
        CreateVATPostingSetupWithVATPct(VATPostingSetup, 22);
        VendorNo :=
          CreateVendorWithInvDiscount(
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"), 3);

        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, '', FALSE, TRUE, 0);
        PreparePurchOrderLine(PurchaseLine, PurchaseHeader."No.", VATPostingSetup."VAT Prod. Posting Group");
        SetPurchPrepmtAccount(PurchaseLine);
        AddPurchOrderLinesCase378205(PurchaseLine);
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);

        VerifyPurchaseHeaderTotals(PurchaseHeader, 4716.81, 5754.51, 145.88, 4716.81);
        EXIT(LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader));
    end;

    local procedure GetLastGLRegisterNo(): Integer
    var
        GLRegister: Record "G/L Register";
    begin
        if GLRegister.FindLast() then
            exit(GLRegister."No.");
        exit(0);
    end;

    local procedure CreateVATPostingSetupWithVATPct(var VATPostingSetup: Record "VAT Posting Setup"; VATPct: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPct);
    end;

    local procedure GetSpecificVAT19Pct(): Decimal
    begin
        exit(19);
    end;

    local procedure GetSpecificVATPct(): Decimal
    begin
        exit(20);
    end;

    local procedure GetSpecificUnitCost356880(LineNo: Integer): Decimal
    begin
        case LineNo of
            1:
                exit(19);
            2:
                exit(5.9);
        end;
    end;

    local procedure SetGeneralLedgerSetup(PrepmtUnrealVAT: Boolean)
    var
        GenLedgerSetup: Record "General Ledger Setup";
    begin
        GenLedgerSetup.Get();
        if not GenLedgerSetup."Prepayment Unrealized VAT" then
            GenLedgerSetup.Validate("Prepayment Unrealized VAT", PrepmtUnrealVAT);
        GenLedgerSetup.Modify(true);
    end;

    local procedure SetSalesPrepmtAccount(SalesLine: Record "Sales Line"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        if GenPostingSetup."Sales Prepayments Account" = '' then begin
            GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
            GenPostingSetup."Sales Prepayments Account" := GLAccount."No.";
            GenPostingSetup.Modify();
        end else
            GLAccount.Get(GenPostingSetup."Sales Prepayments Account");
        if GLAccount."Gen. Prod. Posting Group" = '' then
            GLAccount."Gen. Prod. Posting Group" := SalesLine."Gen. Prod. Posting Group";
        GLAccount."VAT Prod. Posting Group" := SalesLine."VAT Prod. Posting Group";
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure SetPurchPrepmtAccount(PurchLine: Record "Purchase Line"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        if GenPostingSetup."Purch. Prepayments Account" = '' then begin
            GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
            GenPostingSetup."Purch. Prepayments Account" := GLAccount."No.";
            GenPostingSetup.Modify();
        end else
            GLAccount.Get(GenPostingSetup."Purch. Prepayments Account");
        if GLAccount."Gen. Prod. Posting Group" = '' then
            GLAccount."Gen. Prod. Posting Group" := PurchLine."Gen. Prod. Posting Group";
        GLAccount."VAT Prod. Posting Group" := PurchLine."VAT Prod. Posting Group";
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateItemWithVATProdPostGroup(VATProdPostGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; VATBusPostingGroupCode: Code[20]; CurrencyCode: Code[10]; PricesInclVAT: Boolean)
    begin
        CreateSalesOrderSetCompressPrepmt(SalesHeader, VATBusPostingGroupCode, CurrencyCode, PricesInclVAT, true);
    end;

    local procedure CreateSalesOrderSetCompressPrepmt(var SalesHeader: Record "Sales Header"; VATBusPostingGroupCode: Code[20]; CurrencyCode: Code[10]; PricesInclVAT: Boolean; CompressPrepmt: Boolean)
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode);
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, CurrencyCode, PricesInclVAT, CompressPrepmt, 0);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20];
                                                                                                CurrencyCode: Code[10];
                                                                                                PricesIncludingVAT: Boolean;
                                                                                                CompressPrepmt: Boolean;
                                                                                                PrepmtPct: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Validate("Compress Prepayment", CompressPrepmt);
        SalesHeader.Validate("Prepayment %", PrepmtPct);
        SalesHeader.Modify();
    end;

    local procedure CreateSalesOrderPriceInclVAT356880(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup") SalesPrepAccountNo: Code[20]
    var
        Item: Record Item;
        i: Integer;
    begin
        CreateSalesOrderSetCompressPrepmt(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", '', true, false);

        Item.Get(CreateItemWithVATProdPostGroup(VATPostingSetup."VAT Prod. Posting Group"));

        SalesPrepAccountNo := CreateGLAccount(Item."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateSalesPrepmtAccount(SalesPrepAccountNo, SalesHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        for i := 1 to 2 do
            CreateSalesLineWithSpecificPrice356880(SalesHeader, Item."No.", GetSpecificUnitCost356880(i));
    end;

    local procedure CreateSalesOrderPostPrepmtInvoice(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; UnitPriceInclVAT: Decimal): Code[20]
    begin
        CreateSalesOrder(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", CurrencyCode, true);
        CreateSalesOrderLine(SalesHeader."No.", VATPostingSetup."VAT Prod. Posting Group", UnitPriceInclVAT);
        exit(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader));
    end;

    local procedure CreateSalesOrderLine(SalesHeaderNo: Code[20]; VATProdPostingGroup: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        PrepareSalesOrderLine(SalesLine, SalesHeaderNo, VATProdPostingGroup);
        SetSalesPrepmtAccount(SalesLine);
        AddSalesOrderLine100PctPrepmt(SalesLine, UnitPrice);
    end;

    local procedure CreateSalesLineWithSpecificPrice356880(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Prepayment %", 100);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithQtyPriceLineDiscount(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; UnitPrice: Decimal; Qty: Decimal; QtyToShip: Decimal; LineDiscount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Line Discount %", LineDiscount);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineGLWithDim(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; DimensionValue: Record "Dimension Value"; Quantity: Decimal; QtyToShip: Decimal; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(SalesLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder_TFS229419_ExclVAT(var SalesHeader: Record "Sales Header"; DiscountPct: Decimal; PrepaymentPct: Decimal)
    var
        ItemNo: array[3] of Code[20];
        UnitPrices: array[5] of Decimal;
    begin
        PrepareUnitPrices_TFS229419_ExclVAT(UnitPrices);
        CreateSalesOrder_TFS229419(SalesHeader, ItemNo, false, DiscountPct, PrepaymentPct);
        CreateSalesOrderLines_TFS229419(SalesHeader, ItemNo, UnitPrices);
        LibrarySales.CalcSalesDiscount(SalesHeader);
    end;

    local procedure CreateSalesOrder_TFS229419_InclVAT(var SalesHeader: Record "Sales Header"; DiscountPct: Decimal; PrepaymentPct: Decimal)
    var
        ItemNo: array[3] of Code[20];
        UnitPrices: array[5] of Decimal;
    begin
        PrepareUnitPrices_TFS229419_InclVAT(UnitPrices);
        CreateSalesOrder_TFS229419(SalesHeader, ItemNo, true, DiscountPct, PrepaymentPct);
        CreateSalesOrderLines_TFS229419(SalesHeader, ItemNo, UnitPrices);
        LibrarySales.CalcSalesDiscount(SalesHeader);
    end;

    local procedure CreateSalesOrder_TFS229419(var SalesHeader: Record "Sales Header"; var ItemNo: array[3] of Code[20]; PricesIncludingVAT: Boolean; DiscountPct: Decimal; PrepaymentPct: Decimal)
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CustomerNo: Code[20];
        i: Integer;
    begin
        LibrarySales.SetInvoiceRounding(false);
        CreateThreeVATPostingSetups(VATPostingSetup, 13, 5, 5);
        CreateGeneralPostingSetupWithZeroPrepmtVATPct(GeneralPostingSetup, VATPostingSetup[1]."VAT Bus. Posting Group");
        CustomerNo :=
            CreateCustomerWithInvDiscount(
                LibrarySales.CreateCustomerWithBusPostingGroups(
                    GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup[1]."VAT Bus. Posting Group"),
                DiscountPct);
        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] :=
              CreateItemWithPostingSetup(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup[i]."VAT Prod. Posting Group");
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, '', PricesIncludingVAT, true, PrepaymentPct);
    end;

    local procedure CreateSalesOrderLines_TFS229419(SalesHeader: Record "Sales Header"; ItemNo: array[3] of Code[20]; UnitPrices: array[5] of Decimal)
    begin
        CreateSalesLineItem(SalesHeader, ItemNo[2], UnitPrices[1]);
        CreateSalesLineItem(SalesHeader, ItemNo[2], UnitPrices[2]);
        CreateSalesLineItem(SalesHeader, ItemNo[1], UnitPrices[3]);
        CreateSalesLineItem(SalesHeader, ItemNo[1], UnitPrices[4]);
        CreateSalesLineItem(SalesHeader, ItemNo[3], UnitPrices[5]);
    end;

    local procedure CreateSalesLineItem(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchOrderPriceInclVAT356880(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup") PurchPrepAccountNo: Code[20]
    var
        Item: Record Item;
        i: Integer;
    begin
        CreatePurchOrderSetCompressPrepmt(PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", '', true, false);

        Item.Get(CreateItemWithVATProdPostGroup(VATPostingSetup."VAT Prod. Posting Group"));

        PurchPrepAccountNo := CreateGLAccount(Item."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdatePurchasePrepmtAccount(PurchPrepAccountNo, PurchaseHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        for i := 1 to 2 do
            CreatePurchLineWithSpecificCost356880(PurchaseHeader, Item."No.", GetSpecificUnitCost356880(i));
    end;

    local procedure CreatePurchOrderPostPrepmtInvoice(var PurchHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; UnitPriceInclVAT: Decimal): Code[20]
    begin
        CreatePurchOrder(PurchHeader, VATPostingSetup."VAT Bus. Posting Group", CurrencyCode, true);
        CreatePurchOrderLine(PurchHeader."No.", VATPostingSetup."VAT Prod. Posting Group", UnitPriceInclVAT);
        exit(PostPurchPrepmtInvoice(PurchHeader));
    end;

    local procedure CreatePurchOrderLine(PurchHeaderNo: Code[20]; VATProdPostingGroup: Code[20]; UnitPrice: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        PreparePurchOrderLine(PurchLine, PurchHeaderNo, VATProdPostingGroup);
        SetPurchPrepmtAccount(PurchLine);
        AddPurchOrderLine100PctPrepmt(PurchLine, UnitPrice);
    end;

    local procedure CreatePurchLineWithSpecificCost356880(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; UnitPrice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", UnitPrice);
        PurchaseLine.Validate("Prepayment %", 100);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineWithQtyPriceLineDiscount(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; UnitCost: Decimal; Qty: Decimal; QtyToReceive: Decimal; LineDiscount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Validate("Line Discount %", LineDiscount);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineGLWithDim(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; DimensionValue: Record "Dimension Value"; Quantity: Decimal; QtyToReceive: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(PurchaseLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        PurchaseLine.Validate("Qty. to Receive", QtyToReceive);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder_TFS229419_ExclVAT(var PurchaseHeader: Record "Purchase Header"; DiscountPct: Decimal; PrepaymentPct: Decimal)
    var
        ItemNo: array[3] of Code[20];
        UnitPrices: array[5] of Decimal;
    begin
        PrepareUnitPrices_TFS229419_ExclVAT(UnitPrices);
        CreatePurchaseOrder_TFS229419(PurchaseHeader, ItemNo, false, DiscountPct, PrepaymentPct);
        CreatePurchaseOrderLines_TFS229419(PurchaseHeader, ItemNo, UnitPrices);
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);
    end;

    local procedure CreatePurchaseOrder_TFS229419_InclVAT(var PurchaseHeader: Record "Purchase Header"; DiscountPct: Decimal; PrepaymentPct: Decimal)
    var
        ItemNo: array[3] of Code[20];
        UnitPrices: array[5] of Decimal;
    begin
        PrepareUnitPrices_TFS229419_InclVAT(UnitPrices);
        CreatePurchaseOrder_TFS229419(PurchaseHeader, ItemNo, true, DiscountPct, PrepaymentPct);
        CreatePurchaseOrderLines_TFS229419(PurchaseHeader, ItemNo, UnitPrices);
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);
    end;

    local procedure CreatePurchaseOrder_TFS229419(var PurchaseHeader: Record "Purchase Header"; var ItemNo: array[3] of Code[20]; PricesIncludingVAT: Boolean; DiscountPct: Decimal; PrepaymentPct: Decimal)
    var
        VATPostingSetup: array[3] of Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        VendorNo: Code[20];
        i: Integer;
    begin
        LibraryPurchase.SetInvoiceRounding(false);
        CreateThreeVATPostingSetups(VATPostingSetup, 13, 5, 5);
        CreateGeneralPostingSetupWithZeroPrepmtVATPct(GeneralPostingSetup, VATPostingSetup[1]."VAT Bus. Posting Group");
        VendorNo :=
            CreateVendorWithInvDiscount(
                LibraryPurchase.CreateVendorWithBusPostingGroups(
                    GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup[1]."VAT Bus. Posting Group"),
                DiscountPct);
        for i := 1 to ArrayLen(ItemNo) do
            ItemNo[i] :=
              CreateItemWithPostingSetup(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup[i]."VAT Prod. Posting Group");
        CreatePurchaseHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, '', PricesIncludingVAT, true, PrepaymentPct);
    end;

    local procedure CreatePurchaseOrderLines_TFS229419(PurchaseHeader: Record "Purchase Header"; ItemNo: array[3] of Code[20]; UnitPrices: array[5] of Decimal)
    begin
        CreatePurchaseLineItem(PurchaseHeader, ItemNo[2], UnitPrices[1]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo[2], UnitPrices[2]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo[1], UnitPrices[3]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo[1], UnitPrices[4]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo[3], UnitPrices[5]);
    end;

    local procedure CreatePurchaseLineItem(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndApplyPaymentToInvoice(AccountType: Enum "Gen. Journal Account Type"; CVNo: Code[20];
                                                                    AppliestoDocNo: Code[20];
                                                                    CurrencyCode: Code[10];
                                                                    PaymentAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            AccountType, CVNo, GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), PaymentAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateThreeVATPostingSetups(var VATPostingSetup: array[3] of Record "VAT Posting Setup"; VATRate1: Decimal; VATRate2: Decimal; VATRate3: Decimal)
    var
        ZeroVATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", VATRate1);
        CreateRelatedVATPostingSetup(VATPostingSetup[2], VATPostingSetup[1], VATRate2);
        CreateRelatedVATPostingSetup(VATPostingSetup[3], VATPostingSetup[1], VATRate3);
        LibraryERM.CreateVATPostingSetup(ZeroVATPostingSetup, VATPostingSetup[1]."VAT Bus. Posting Group", '');
    end;

    local procedure CreateRelatedVATPostingSetup(var NewVATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; VATRate: Decimal)
    var
        DummyGLAccount: Record "G/L Account";
    begin
        DummyGLAccount."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        DummyGLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        NewVATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", LibraryERM.CreateRelatedVATPostingSetup(DummyGLAccount));
        NewVATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        NewVATPostingSetup.Validate("VAT %", VATRate);
        NewVATPostingSetup.Modify(true);
    end;

    local procedure CreateRelatedZeroVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);
    end;

    local procedure CreateGeneralPostingSetupWithZeroPrepmtVATPct(var GeneralPostingSetup: Record "General Posting Setup"; VATBusPostingGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
        CreateRelatedZeroVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode);
        UpdateGLAccountWithVATAndGenSetup(GeneralPostingSetup."Sales Prepayments Account", VATPostingSetup, GeneralPostingSetup);
        UpdateGLAccountWithVATAndGenSetup(GeneralPostingSetup."Purch. Prepayments Account", VATPostingSetup, GeneralPostingSetup);
    end;

    local procedure CreateCustomerWithInvDiscount(CustomerNo: Code[20]; DiscountPct: Decimal): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);
        CustInvoiceDisc.Validate("Discount %", DiscountPct);
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure CreateVendorWithInvDiscount(VendorNo: Code[20]; DiscountPct: Decimal): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0);
        VendorInvoiceDisc.Validate("Discount %", DiscountPct);
        VendorInvoiceDisc.Modify(true);
        exit(VendorInvoiceDisc.Code);
    end;

    local procedure CreateItemWithPostingSetup(GenProdPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithPostingSetup(Item, GenProdPostingGroupCode, VATProdPostingGroupCode);
        exit(Item."No.");
    end;

    local procedure PostSalesInvoiceForOrder(var SalesOrderHeader: Record "Sales Header"; ShipmentNoFilter: Text): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Invoice, SalesOrderHeader."Sell-to Customer No.",
            SalesOrderHeader."Currency Code", SalesOrderHeader."Prices Including VAT", SalesOrderHeader."Compress Prepayment", 0);
        GetShipmentLines(SalesHeader, ShipmentNoFilter);
        LibrarySales.CalcSalesDiscount(SalesHeader);
        exit(InvoiceSalesOrder(SalesHeader));
    end;

    local procedure GetShipmentLines(SalesHeader: Record "Sales Header"; ShipmentNoFilter: Text)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentLine.SetFilter("Document No.", ShipmentNoFilter);
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure CreatePurchOrder(var PurchHeader: Record "Purchase Header"; VATBusPostingGroupCode: Code[20]; CurrencyCode: Code[10]; PricesInclVAT: Boolean)
    begin
        CreatePurchOrderSetCompressPrepmt(PurchHeader, VATBusPostingGroupCode, CurrencyCode, PricesInclVAT, true);
    end;

    local procedure CreatePurchOrderSetCompressPrepmt(var PurchHeader: Record "Purchase Header"; VATBusPostingGroupCode: Code[20]; CurrencyCode: Code[10]; PricesInclVAT: Boolean; CompressPrepmt: Boolean)
    var
        VendorNo: Code[20];
    begin
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroupCode);
        CreatePurchaseHeader(
          PurchHeader, PurchHeader."Document Type"::Order, VendorNo, CurrencyCode, PricesInclVAT, CompressPrepmt, 0);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20];
                                                                                                         CurrencyCode: Code[10];
                                                                                                         PricesIncludingVAT: Boolean;
                                                                                                         CompressPrepmt: Boolean;
                                                                                                         PrepmtPct: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Validate("Compress Prepayment", CompressPrepmt);
        PurchaseHeader.Validate("Prepayment %", PrepmtPct);
        PurchaseHeader.Modify();
    end;

    local procedure PostPurchInvoiceForOrder(var PurchOrderHeader: Record "Purchase Header"; ReceiptNoFilter: Text): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice, PurchOrderHeader."Buy-from Vendor No.",
            PurchOrderHeader."Currency Code", PurchOrderHeader."Prices Including VAT", PurchOrderHeader."Compress Prepayment", 0);
        GetReceiptLines(PurchHeader, ReceiptNoFilter);
        LibraryPurchase.CalcPurchaseDiscount(PurchHeader);
        exit(InvoicePurchOrder(PurchHeader));
    end;

    local procedure GetReceiptLines(PurchHeader: Record "Purchase Header"; ReceiptNoFilter: Text)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptLine.SetFilter("Document No.", ReceiptNoFilter);
        PurchGetReceipt.SetPurchHeader(PurchHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure PrepareSalesOrderLine(var SalesLine: Record "Sales Line"; SalesOrderNo: Code[20]; VATProdPostingGroupCode: Code[20])
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := SalesOrderNo;
        SalesLine."Line No." := 0;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", CreateItemWithVATProdPostGroup(VATProdPostingGroupCode));
    end;

    local procedure PreparePurchOrderLine(var PurchLine: Record "Purchase Line"; PurchOrderNo: Code[20]; VATProdPostingGroupCode: Code[20])
    begin
        PurchLine."Document Type" := PurchLine."Document Type"::Order;
        PurchLine."Document No." := PurchOrderNo;
        PurchLine."Line No." := 0;
        PurchLine.Type := PurchLine.Type::Item;
        PurchLine.Validate("No.", CreateItemWithVATProdPostGroup(VATProdPostingGroupCode));
    end;

    local procedure ChangeQtyOnSalesLine(var SalesHeader: Record "Sales Header"; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Modify(true);
    end;

    local procedure ChangeQtyOnPurchLine(var PurchHeader: Record "Purchase Header"; Qty: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindFirst();
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Modify(true);
    end;

    local procedure ChangeQtyToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtyToShip: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure ChangeQtyToReceiveOnPurchLine(var PurchLine: Record "Purchase Line"; QtyToReceive: Decimal)
    begin
        PurchLine.Find();
        PurchLine.Validate("Qty. to Receive", QtyToReceive);
        PurchLine.Modify(true);
    end;

    local procedure AddSalesOrderLine100PctPrepmt(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        AddSalesOrderLine(SalesLine, 1, UnitPrice, 100);
    end;

    local procedure AddSalesOrderLine(var SalesLine: Record "Sales Line"; Qty: Decimal; UnitPrice: Decimal; PrepmtPct: Decimal)
    begin
        SalesLine."Line No." += 10000;
        SalesLine.Validate("No.");
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Prepayment %", PrepmtPct);
        SalesLine.Insert(true);
    end;

    local procedure AddSalesOrderLineWithDetails(var SalesLine: Record "Sales Line"; Qty: Decimal; UnitPrice: Decimal; PrepmtPct: Decimal; LineDiscountAmount: Decimal; QtyToShip: Integer)
    begin
        SalesLine."Line No." += 10000;
        SalesLine.Validate("No.");
        SalesLine.Validate(Quantity, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Prepayment %", PrepmtPct);
        SalesLine.Validate("Line Discount Amount", LineDiscountAmount);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Insert(true);
    end;

    local procedure AddPurchOrderLine100PctPrepmt(var PurchLine: Record "Purchase Line"; UnitPrice: Decimal)
    begin
        AddPurchOrderLine(PurchLine, 1, UnitPrice, 100);
    end;

    local procedure AddPurchOrderLine(var PurchLine: Record "Purchase Line"; Qty: Decimal; UnitCost: Decimal; PrepmtPct: Decimal)
    begin
        PurchLine."Line No." += 10000;
        PurchLine.Validate("No.");
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Direct Unit Cost", UnitCost);
        PurchLine.Validate("Prepayment %", PrepmtPct);
        PurchLine.Insert(true);
    end;

    local procedure AddPurchOrderLineWithDetails(var PurchLine: Record "Purchase Line"; Qty: Decimal; UnitCost: Decimal; PrepmtPct: Decimal; LineDiscountAmount: Decimal; QtyToReceive: Integer)
    begin
        PurchLine."Line No." += 10000;
        PurchLine.Validate("No.");
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Direct Unit Cost", UnitCost);
        PurchLine.Validate("Prepayment %", PrepmtPct);
        PurchLine.Validate("Line Discount Amount", LineDiscountAmount);
        PurchLine.Validate("Qty. to Receive", QtyToReceive);
        PurchLine.Insert(true);
    end;

    local procedure AddThreeSalesOrderLinesCase258679(SalesLine: Record "Sales Line")
    begin
        AddSalesOrderLine(SalesLine, 65, 53.911, 30);
        AddSalesOrderLine(SalesLine, 25, 1.382, 45);
        AddSalesOrderLine(SalesLine, 10, 1.658, 35);
    end;

    local procedure AddThreePurchOrderLinesCase258679(PurchLine: Record "Purchase Line")
    begin
        AddPurchOrderLine(PurchLine, 65, 53.911, 30);
        AddPurchOrderLine(PurchLine, 25, 1.382, 45);
        AddPurchOrderLine(PurchLine, 10, 1.658, 35);
    end;

    local procedure AddSalesOrderLineCase346807(var SalesLine: Record "Sales Line")
    begin
        AddSalesOrderLine(SalesLine, 2, 47.6, 100);
    end;

    local procedure AddPurchOrderLineCase346807(var PurchLine: Record "Purchase Line")
    begin
        AddPurchOrderLine(PurchLine, 2, 47.6, 100);
    end;

    local procedure AddSalesOrderLinesCase378205(SalesLine: Record "Sales Line")
    begin
        AddSalesOrderLineWithDetails(SalesLine, 250, 4.92, 100, 721.89, 250);
        AddSalesOrderLineWithDetails(SalesLine, 180, 2.15, 100, 0, 0);
        AddSalesOrderLineWithDetails(SalesLine, 48, 3.12, 100, 0, 0);
        AddSalesOrderLineWithDetails(SalesLine, 80, 4.49, 100, 0, 0);
        AddSalesOrderLineWithDetails(SalesLine, 24, 11.32, 100, 0, 0);
        AddSalesOrderLineWithDetails(SalesLine, 16, 18.15, 100, 0, 16);
        AddSalesOrderLineWithDetails(SalesLine, 4, 63.11, 100, 148.16, 0);
        AddSalesOrderLineWithDetails(SalesLine, 612, 2.31, 100, 0, 0);
        AddSalesOrderLineWithDetails(SalesLine, 180, 3.33, 100, 0, 0);
        AddSalesOrderLineWithDetails(SalesLine, 163, 4.78, 100, 0, 0);
    end;

    local procedure AddPurchOrderLinesCase378205(PurchaseLine: Record "Purchase Line")
    begin
        AddPurchOrderLineWithDetails(PurchaseLine, 250, 4.92, 100, 721.89, 250);
        AddPurchOrderLineWithDetails(PurchaseLine, 180, 2.15, 100, 0, 0);
        AddPurchOrderLineWithDetails(PurchaseLine, 48, 3.12, 100, 0, 0);
        AddPurchOrderLineWithDetails(PurchaseLine, 80, 4.49, 100, 0, 0);
        AddPurchOrderLineWithDetails(PurchaseLine, 24, 11.32, 100, 0, 0);
        AddPurchOrderLineWithDetails(PurchaseLine, 16, 18.15, 100, 0, 16);
        AddPurchOrderLineWithDetails(PurchaseLine, 4, 63.11, 100, 148.16, 0);
        AddPurchOrderLineWithDetails(PurchaseLine, 612, 2.31, 100, 0, 0);
        AddPurchOrderLineWithDetails(PurchaseLine, 180, 3.33, 100, 0, 0);
        AddPurchOrderLineWithDetails(PurchaseLine, 163, 4.78, 100, 0, 0);
    end;

    local procedure PostPurchPrepmtInvoice(var PurchHeader: Record "Purchase Header"): Code[20]
    begin
        PurchHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        exit(LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader));
    end;

    local procedure PostSalesPrepmtCrMemo(var SalesHeader: Record "Sales Header")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.CreditMemo(SalesHeader);
    end;

    local procedure PostPurchPrepmtCrMemo(var PurchHeader: Record "Purchase Header")
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchHeader."Vendor Cr. Memo No." := LibraryUtility.GenerateGUID();
        PurchPostPrepayments.CreditMemo(PurchHeader);
    end;

    local procedure InvoiceSalesOrder(var SalesHeader: Record "Sales Header"): Code[20]
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        SalesHeader.Find();
        Assert.IsFalse(PrepaymentMgt.TestSalesPrepayment(SalesHeader), 'PrepaymentMgt.TestSalesPrepayment()');
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure ShipSalesOrder(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure InvoicePurchOrder(var PurchHeader: Record "Purchase Header"): Code[20]
    var
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        PurchHeader.Find();
        Assert.IsFalse(PrepaymentMgt.TestPurchasePrepayment(PurchHeader), 'PrepaymentMgt.TestPurchasePrepayment()');
        PurchHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure ReceivePurchOrder(var PurchHeader: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false));
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Invoice Rounding Precision", Currency."Amount Rounding Precision");
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchRate(ExchRateAmount: Decimal): Code[10]
    var
        CurrencyExchRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchRate, CreateCurrency(), WorkDate());
        CurrencyExchRate.Validate("Exchange Rate Amount", ExchRateAmount);
        CurrencyExchRate.Validate("Adjustment Exch. Rate Amount", ExchRateAmount);
        CurrencyExchRate.Validate("Relational Exch. Rate Amount", 1);
        CurrencyExchRate.Validate("Relational Adjmt Exch Rate Amt", 1);
        CurrencyExchRate.Modify();
        exit(CurrencyExchRate."Currency Code");
    end;

    local procedure CreateFourDimensionValues(var DimensionValue: array[4] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
        i: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        for i := 1 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[i], Dimension.Code);
    end;

    local procedure UpdateSalesPrepmtAccount(SalesPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup."Sales Prepayments Account" := SalesPrepaymentsAccount;
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdatePurchasePrepmtAccount(PurchPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup."Purch. Prepayments Account" := PurchPrepaymentsAccount;
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateGLAccountWithVATAndGenSetup(GLAccountNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; GeneralPostingSetup: Record "General Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure UpdateSalesPrepmtAccountForGLLine(SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
    begin
        GLAccount.Get(GLAccountNo);
        SalesLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        SalesLine."Gen. Bus. Posting Group" := SalesHeader."Gen. Bus. Posting Group";
        SalesLine."Gen. Prod. Posting Group" := GLAccount."Gen. Prod. Posting Group";
        SetSalesPrepmtAccount(SalesLine);
    end;

    local procedure UpdatePurchasePrepmtAccountForGLLine(PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
    begin
        GLAccount.Get(GLAccountNo);
        PurchaseLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        PurchaseLine."Gen. Bus. Posting Group" := PurchaseHeader."Gen. Bus. Posting Group";
        PurchaseLine."Gen. Prod. Posting Group" := GLAccount."Gen. Prod. Posting Group";
        SetPurchPrepmtAccount(PurchaseLine);
    end;

    local procedure FindPostedGLEntries(LastGLRegNo: Integer; var GLEntry: Record "G/L Entry")
    var
        GLRegister: Record "G/L Register";
        FromEntryNo: Integer;
        ToEntryNo: Integer;
    begin
        GLRegister.SetFilter("No.", '>%1', LastGLRegNo);
        GLRegister.FindFirst();
        FromEntryNo := GLRegister."From Entry No.";
        GLRegister.FindLast();
        ToEntryNo := GLRegister."To Entry No.";
        GLEntry.SetRange("Entry No.", FromEntryNo, ToEntryNo);
    end;

    local procedure VerifyZeroBalanceOnGLAcc(GLAccountNo: Code[20]; LastGLRegNo: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindPostedGLEntries(LastGLRegNo, GLEntry);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0, GLEntry.Amount, 'Expected zero balance on G/L Account ' + GLAccountNo);
    end;

    local procedure FindPostedVATEntries(LastGLRegNo: Integer; var VATEntry: Record "VAT Entry")
    var
        GLRegister: Record "G/L Register";
        FromEntryNo: Integer;
        ToEntryNo: Integer;
    begin
        GLRegister.SetFilter("No.", '>%1', LastGLRegNo);
        GLRegister.FindFirst();
        FromEntryNo := GLRegister."From VAT Entry No.";
        GLRegister.FindLast();
        ToEntryNo := GLRegister."To VAT Entry No.";
        VATEntry.SetRange("Entry No.", FromEntryNo, ToEntryNo);
    end;

    local procedure SumPositiveVATAmount(LastGLRegisterNo: Integer): Decimal
    begin
        exit(SumVATAmount(LastGLRegisterNo, true));
    end;

    local procedure SumNegativeVATAmount(LastGLRegisterNo: Integer): Decimal
    begin
        exit(SumVATAmount(LastGLRegisterNo, false));
    end;

    local procedure SumVATAmount(LastGLRegisterNo: Integer; IsPositiveAmount: Boolean) Balance: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        FindPostedVATEntries(LastGLRegisterNo, VATEntry);
        if IsPositiveAmount then
            VATEntry.SetFilter(Amount, '>0')
        else
            VATEntry.SetFilter(Amount, '<0');
        VATEntry.FindSet();
        repeat
            Balance += VATEntry.Amount;
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyGLAccountBalance(GLAccountNo: Code[20]; DocumentNo: Code[20]; ExpectedBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(ExpectedBalance, GLEntry.Amount, StrSubstNo(UnbalancedAccountErr, GLAccountNo, DocumentNo));
    end;

    local procedure VerifySalesHeaderTotals(SalesHeader: Record "Sales Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal; ExpectedInvDiscAmount: Decimal; ExpectedPrepmtLineAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        SalesHeader.TestField(Amount, ExpectedAmount);
        SalesHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
        SalesHeader.TestField("Invoice Discount Amount", ExpectedInvDiscAmount);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Incl. VAT");
        SalesLine.TestField("Prepmt. Line Amount", ExpectedPrepmtLineAmount);
    end;

    local procedure VerifyPurchaseHeaderTotals(PurchaseHeader: Record "Purchase Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal; ExpectedInvDiscAmount: Decimal; ExpectedPrepmtLineAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        PurchaseHeader.TestField(Amount, ExpectedAmount);
        PurchaseHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
        PurchaseHeader.TestField("Invoice Discount Amount", ExpectedInvDiscAmount);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Incl. VAT");
        PurchaseLine.TestField("Prepmt. Line Amount", ExpectedPrepmtLineAmount);
    end;

    local procedure VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader: Record "Sales Invoice Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvoiceHeader.TestField(Amount, ExpectedAmount);
        SalesInvoiceHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
    end;

    local procedure VerifyPostedPurchaseInvoiceTotals(PurchInvHeader: Record "Purch. Inv. Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        PurchInvHeader.TestField(Amount, ExpectedAmount);
        PurchInvHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
    end;

    local procedure VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo: Code[20]; InvoiceDocNo: Code[20]; PrepmtAmount: Decimal; InvoiceAmount: Decimal; InvoiceAmountInclVAT: Decimal)
    begin
        VerifyPostedSalesInvoiceAmounts(PrepmtDocNo, PrepmtAmount, PrepmtAmount);
        VerifyPostedSalesInvoiceAmounts(InvoiceDocNo, InvoiceAmount, InvoiceAmountInclVAT);
    end;

    local procedure VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo: Code[20]; InvoiceDocNo: Code[20]; PrepmtAmount: Decimal; InvoiceAmount: Decimal; InvoiceAmountInclVAT: Decimal)
    begin
        VerifyPostedPurchaseInvoiceAmounts(PrepmtDocNo, PrepmtAmount, PrepmtAmount);
        VerifyPostedPurchaseInvoiceAmounts(InvoiceDocNo, InvoiceAmount, InvoiceAmountInclVAT);
    end;

    local procedure VerifyPostedSalesInvoiceAmounts(InvoiceDocNo: Code[20]; Amount: Decimal; AmountInclVAT: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceDocNo);
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, Amount, AmountInclVAT);
    end;

    local procedure VerifyPostedPurchaseInvoiceAmounts(InvoiceDocNo: Code[20]; Amount: Decimal; AmountInclVAT: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(InvoiceDocNo);
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, Amount, AmountInclVAT);
    end;

    local procedure VerifyVATEntryBalance(DocumentNo: Code[20]; ExpectedAmountBalance: Decimal; ExpectedBaseBalance: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Amount, Base);
        VATEntry.TestField(Amount, ExpectedAmountBalance);
        VATEntry.TestField(Base, ExpectedBaseBalance);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

