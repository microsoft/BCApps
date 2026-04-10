codeunit 144003 "ERM Curr. Adjmt. Prepmt. Sales"
{
    // // [FEATURE] [Prepayment] [Sales]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        EntryType: Option ,Invoice,Prepayment,Correction;
        IsInitialized: Boolean;
        WrongValueErr: Label 'Wrong value in %1.%2, Entry No.= %3.', Comment = '%1=table caption,%2=field caption';
        EntryDoesNotExistErr: Label 'Cannot find entry in table %1 with filters %2.';
        NothingToAdjustTxt: Label 'There is nothing to adjust.';
        ItemTrackingLinesOption: Option NewLot,SetLot;

    [Test]
    [Scope('OnPrem')]
    procedure InvToCancelPrepmtCurrRaise()
    begin
        ApplyInvCurrToPrepmt(true, true); // pass true for Cancel Prepmt and Currency Exchange Rate raise
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvToCancelPrepmtCurrFail()
    begin
        ApplyInvCurrToPrepmt(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapInvToCancelPrepmtCurrRaise()
    begin
        UnapplyInvCurrToPrepmt(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapInvToCancelPrepmtCurrFail()
    begin
        UnapplyInvCurrToPrepmt(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvToNormalPrepmtCurrRaise()
    begin
        UnapplyInvCurrToPrepmt(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvToNormalPrepmtCurrFail()
    begin
        ApplyInvCurrToPrepmt(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapInvToNormalPrepmtCurrRaise()
    begin
        ApplyInvCurrToPrepmt(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapInvToNormalPrepmtCurrFail()
    begin
        UnapplyInvCurrToPrepmt(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefundToCancelPrepmtRaise()
    begin
        ApplyInvAndRefundToPrepmt(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefundToNormalPrepmtRaise()
    begin
        ApplyInvAndRefundToPrepmt(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefundToCancelPrepmtFail()
    begin
        ApplyInvAndRefundToPrepmt(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefundToNormalPrepmtFail()
    begin
        ApplyInvAndRefundToPrepmt(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefToCancelPrepmtRaise()
    begin
        UnapplyInvAndRefundToPrepmt(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefToNormalPrepmtRaise()
    begin
        UnapplyInvAndRefundToPrepmt(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefToCancelPrepmtFail()
    begin
        UnapplyInvAndRefundToPrepmt(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefToNormalPrepmtFail()
    begin
        UnapplyInvAndRefundToPrepmt(false, false);
    end;

    [Test]
    [HandlerFunctions('NothingAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjInvToCancelPrepmtRaise()
    begin
        PostAdjustInvAndPrepmtWithCurr(true, true);
    end;

    [Test]
    [HandlerFunctions('NothingAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjInvToCancelPrepmtFail()
    begin
        PostAdjustInvAndPrepmtWithCurr(false, true);
    end;

    [Test]
    [HandlerFunctions('NothingAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjInvToNormalPrepmtRaise()
    begin
        PostAdjustInvAndPrepmtWithCurr(true, false);
    end;

    [Test]
    [HandlerFunctions('NothingAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure AdjInvToNormalPrepmtFail()
    begin
        PostAdjustInvAndPrepmtWithCurr(false, false);
    end;

    [Test]
    [HandlerFunctions('NothingAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure NoEntryIfCancelPrepmtAdjmtInTA()
    var
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PmtNo: Code[20];
        ExpectedDocNo: Code[20];
        AdjPostingDate: Date;
        EntryAmount: array[3] of Decimal;
    begin
        Initialize();
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        ExpectedDocNo := GetGenJnlTemplateNextNo(AdjPostingDate);
        PostInvAndPrepmtWithCurrency(
          InvNo, PmtNo, EntryAmount, CurrencyCode, true, true);
        AdjPostingDate := CalcDate('<1M+CM>', WorkDate());
        RunAdjExchRates(CurrencyCode, AdjPostingDate, GetCustNoFromCustLedgEntry(InvNo));
        VerifyEmptyGLEntries(ExpectedDocNo, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPrepmtToInvWithCancelPrepmtAdjmt()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PmtNo: Code[20];
        EntryAmount: array[3] of Decimal;
    begin
        // [FEATURE] [Cancel Curr. Prepmt. Adjmt.] [Unapply]
        // [SCENARIO 362788] Prepayment Difference G/L Entry is created when unapplying prepayment with "Cancel Curr. Prepmt. Adjmt" option

        Initialize();
        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        // [GIVEN] Posted Prepayment and invoice in FCY with different exchange rates
        PostInvAndPrepmtWithCurrency(
          InvNo, PmtNo, EntryAmount, CurrencyCode, true, true);
        // [GIVEN] Apply Prepayment to Invoice
        ApplyCustomerPaymentToInvoice(PmtNo, InvNo);

        // [WHEN] Unapply entries
        UnApplyCustomerPayment(PmtNo);

        // [THEN] Unapplied Detailed Customer Ledg. Entry with "Prepmt. Diff." = Yes has a related G/L Entry with same Amount (LCY).
        VerifyPrepmtDiffGLEntry(CustLedgEntry."Document Type"::Invoice, InvNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnrealPrepmtToInvWithCancelPrepmtAdjmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
        InvNo: Code[20];
        PmtNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Cancel Curr. Prepmt. Adjmt.] [Application] [Unrealized VAT]
        // [SCENARIO 363394] Prepayment G/L VAT Entry is created when apply prepayment with unrealized VAT to Invoice

        Initialize();
        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        // [GIVEN] Posted Prepayment with unrealized VAT Amount = "X" and invoice
        VATAmount := PostInvAndUnrealPrepmt(InvNo, PmtNo, VATPostingSetup);

        // [WHEN] Apply Prepayment to Invoice
        ApplyCustomerPaymentToInvoice(PmtNo, InvNo);

        // [THEN] Prepayment G/L VAT Entry is created with realized VAT Amount = "X"
        VerifyGLEntry(GLEntry."Document Type"::Payment, PmtNo, VATPostingSetup."Sales VAT Account", -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyUnrealPrepmtToInvWithCancelPrepmtAdjmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        InvNo: Code[20];
        PmtNo: Code[20];
        PrepmtDocNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Cancel Curr. Prepmt. Adjmt.] [Unapply] [Unrealized VAT]
        // [SCENARIO 371855] Negative Debit G/L Entry with "Sales VAT. Unreal Account" is created when unapply prepayment with unrealized VAT

        Initialize();
        SetCreatePrepmtInvInSalesSetup();
        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        // [GIVEN] Posted Prepayment with unrealized VAT Amount = "X" and invoice
        PrepmtDocNo := GetNextPrepmtInvNo();
        VATAmount := PostInvAndUnrealPrepmt(InvNo, PmtNo, VATPostingSetup);
        // [GIVEN] Application between Prepayment and Invoice
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgEntry."Document Type"::Payment, PmtNo, CustLedgEntry."Document Type"::Invoice, InvNo);

        // [WHEN] Unapply Prepayment
        UnapplyLedgerEntries(CustLedgEntry."Document Type"::Payment, PmtNo);

        // [THEN] G/L Entry with "Sales VAT. Unreal Account" and "Debit Amount" = -"X" is created
        VerifyDebitCreditGLEntry(
          GenJnlLine."Document Type"::Invoice, PrepmtDocNo, VATPostingSetup."Sales VAT Unreal. Account", -VATAmount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMemoItemChrgAssgntPostPmtToInvApplWithPrepmtDiffFCYExchUp()
    var
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        ItemChrgCrMemoNo: Code[20];
        InvoiceILENo: Integer;
        ItemChrgAmountExclVAT: Decimal;
        ItemChrgAmountInclVAT: Decimal;
        PrepmtDiffAmountLCY: Decimal;
    begin
        // [FEATURE] [Item Charge] [Prepayment Difference] [FCY]
        // [SCENARIO 377194] Sales Credit Memo's Item Charge Assignment has Prepayment Difference Amount Excl. VAT for Prepayment to Invoice application with different exch. rates (up) and Cancel Prepmt. Adjmt.
        Initialize();

        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on.
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        // [GIVEN] Released Item Invoice "I" with FCY = 1000$ = 800$ + 200$ (VAT25%) = 60000 LCY = 48000 + 12000 (1$ = 60 LCY).
        // [GIVEN] Posted Prepayment FCY = 500$ = 400$ + 100$ = 25000 LCY = 20000 + 5000 (1$ = 50 LCY).
        // [GIVEN] Post Invoice.
        PrepmtDiffAmountLCY := PostPartItemInvAndPrepmtWithCurrency(InvoiceNo, PaymentNo, CustomerNo, ItemNo, true, true);

        // [WHEN] Apply Prepayment to Invoice. Prepayment Difference LCY = 5000 = 4000 + 1000
        ApplyCustomerPaymentToInvoice(PaymentNo, InvoiceNo);

        // [THEN] Sales Credit Memo with Item Charge is created with "Amount Including VAT" = 5000.
        ItemChrgCrMemoNo := GetItemChrgCrMemoDocNo(CustomerNo, ItemChrgAmountExclVAT, ItemChrgAmountInclVAT);
        Assert.AreEqual(PrepmtDiffAmountLCY, ItemChrgAmountInclVAT, '');

        // [THEN] Value Entry is created for Sales Credit Memo's Item Charge and has "Item Ledger Entry No." = <SalesInvoiceILE>, "Sales Amount (Actual)" = -4000.
        InvoiceILENo := GetSaleILENo(ItemNo, GetShipmentDocNo(CustomerNo, ItemNo));
        VerifyValueEntrySalesAmountActual(ItemNo, ItemChrgCrMemoNo, InvoiceILENo, -ItemChrgAmountExclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvItemChrgAssgntPostPmtToInvApplWithPrepmtDiffFCYExchDown()
    var
        CustomerNo: Code[20];
        ItemNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        ItemChrgInvNo: Code[20];
        InvoiceILENo: Integer;
        ItemChrgAmountExclVAT: Decimal;
        ItemChrgAmountInclVAT: Decimal;
        PrepmtDiffAmountLCY: Decimal;
    begin
        // [FEATURE] [Item Charge] [Prepayment Difference] [FCY]
        // [SCENARIO 377194] Sales Invoice's Item Charge Assignment has Prepayment Difference Amount Excl. VAT for Prepayment to Invoice application with different exch. rates (down) and Cancel Prepmt. Adjmt.
        Initialize();

        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        // [GIVEN] Released Item Invoice "I" with FCY = 1000$ = 800$ + 200$ (VAT25%) = 60000 LCY = 48000 + 12000 (1$ = 60 LCY).
        // [GIVEN] Posted Prepayment FCY = 500$ = 400$ + 100$ = 35000 LCY = 28000 + 7000 (1$ = 70 LCY).
        // [GIVEN] Post Invoice.
        PrepmtDiffAmountLCY := PostPartItemInvAndPrepmtWithCurrency(InvoiceNo, PaymentNo, CustomerNo, ItemNo, false, true);

        // [WHEN] Apply Prepayment to Invoice. Prepayment Difference LCY = 5000 = 4000 + 1000
        ApplyCustomerPaymentToInvoice(PaymentNo, InvoiceNo);

        // [THEN] Sales Invoice with Item Charge is created with "Amount Including VAT" = 5000.
        ItemChrgInvNo := GetItemChrgInvDocNo(CustomerNo, ItemChrgAmountExclVAT, ItemChrgAmountInclVAT);
        Assert.AreEqual(PrepmtDiffAmountLCY, ItemChrgAmountInclVAT, '');

        // [THEN] Value Entry is created for Sales Invoice's Item Charge and has "Item Ledger Entry No." = <SalesInvoiceILE>, "Sales Amount (Actual)" = 4000.
        InvoiceILENo := GetSaleILENo(ItemNo, GetShipmentDocNo(CustomerNo, ItemNo));
        VerifyValueEntrySalesAmountActual(ItemNo, ItemChrgInvNo, InvoiceILENo, ItemChrgAmountExclVAT);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,ItemTrackingSummaryModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplicationOfCustomerPrepaymentToIinvoiceForTrackedIitem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExchRateAmount: array[3] of Decimal;
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [FCY] [Item tracking] [Application]
        // [SCENARIO 273345] When "Cancel Curr. Prepmt. Adjmt." in "General Ledger Setup" is on the application of customer prepayment to invoice for tracked item is successful.
        Initialize();

        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);

        // [GIVEN] Sales order "S" with item line and specified currency
        CreateSalesOrderWithTrackedItem(
          SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), CreateLotItemInventory(LibraryRandom.RandIntInRange(20, 100)),
          LibraryRandom.RandIntInRange(2, 10), CalcDate('<1M>', WorkDate()),
          PrepareSetup(true, ExchRateAmount, false));
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Post prepayment "P" for the sales order "S"
        PaymentNo := CreatePostPrepayment(WorkDate(), SalesLine, SalesHeader."Currency Code", -SalesLine."Amount Including VAT");

        // [GIVEN] Post "S",  posted invoice "N" is created
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Apply Prepayment "P" to Invoice "N"
        ApplyCustomerPaymentToInvoice(PaymentNo, InvoiceNo);

        // [THEN] There are both "Detailed Cust. Ledg. Entry" of type Application - with "Document Type" = Payment and "Document No." = "P" and "Document Type" = Invoice and "Document No." = "N"
        VerifyPrepmtApplication(SalesHeader."Sell-to Customer No.", SalesLine."No.", PaymentNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,ItemTrackingSummaryModalPageHandler,GetShipmentLinesModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplicationOfCustomerPrepaymentToIinvoiceBySeparateDocumentForTrackedItem()
    var
        OrderSalesHeader: Record "Sales Header";
        OrderSalesLine: Record "Sales Line";
        InvoiceSalesHeader: Record "Sales Header";
        ExchRateAmount: array[3] of Decimal;
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [FCY] [Item tracking] [Application]
        // [SCENARIO 277017] When "Cancel Curr. Prepmt. Adjmt." in "General Ledger Setup" is on the application of customer prepayment to invoice for tracked item made as separate document is successful.
        Initialize();

        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);

        // [GIVEN] Sales order "S" with item line and specified currency
        CreateSalesOrderWithTrackedItem(
          OrderSalesHeader, OrderSalesLine, LibrarySales.CreateCustomerNo(), CreateLotItemInventory(LibraryRandom.RandIntInRange(20, 100)),
          LibraryRandom.RandIntInRange(2, 10), WorkDate(), PrepareSetup(true, ExchRateAmount, false));

        // [GIVEN] Post "S" shipment
        LibrarySales.PostSalesDocument(OrderSalesHeader, true, false);

        // [GIVEN] Create and post invoice "N" from "S"
        CreateSalesInvoice(
          InvoiceSalesHeader, OrderSalesHeader."Sell-to Customer No.", OrderSalesHeader."Currency Code", CalcDate('<1M>', WorkDate()));
        InvoiceNo := LibrarySales.PostSalesDocument(InvoiceSalesHeader, false, true);

        // [GIVEN] Post prepayment "P" for the sales order "S"
        PaymentNo :=
          CreatePostPrepayment(
            WorkDate(), OrderSalesLine, OrderSalesHeader."Currency Code", -OrderSalesLine."Amount Including VAT");

        // [WHEN] Apply Prepayment "P" to Invoice "N"
        ApplyCustomerPaymentToInvoice(PaymentNo, InvoiceNo);

        // [THEN] There are both "Detailed Cust. Ledg. Entry" of type Application - with "Document Type" = Payment and "Document No." = "P" and "Document Type" = Invoice and "Document No." = "N"
        VerifyPrepmtApplication(OrderSalesHeader."Sell-to Customer No.", OrderSalesLine."No.", PaymentNo);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerPrepmtAppliedExchRateGainLossPostedAsItemChargeWithCancelPrepmtAdjmtInTA()
    var
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        OrderSalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SourceCurrencyCode: Code[10];
        ExchRateAmount: array[3] of Decimal;
        PostedInvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Currency] [Exchange Rates] [Cancel Prepmt. Adjmt. in TA]
        // [SCENARIO 281292] When applying customer prepayment to invoice with option "Cancel Prepmt. Adjmt. in TA", exchange rate gain/loss is posted as item charge

        Initialize();

        // [GIVEN] Enable "Cancel Prepmt. Adjmt. in TA" in general ledger setup
        SetCancelPrepmtAdjmtInGLSetup(true, true);

        // [GIVEN] Setup exchange rates for EUR: 1.5 on 16.02.2020, 2.1 on 16.03.2020, 2.8 on 16.04.2020
        SourceCurrencyCode := PrepareSetup(true, ExchRateAmount, true);

        // [GIVEN] Sales order for 10 pcs of item "I" with "Direct Unit Cost" = 100 EUR on 16.03. Post shipment.
        CreateItemSalesDocWithCurrency(
          SalesHeader, OrderSalesLine, SalesHeader."Document Type"::Order, CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, OrderSalesLine."No.", '', '', OrderSalesLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Create a separate invoice on 16.04 and get lines from the posted shipment. Post invoice.
        CreateSalesHeaderWithCurrency(
          SalesHeader, SalesHeader."Document Type"::Invoice, CalcDate('<2M>', WorkDate()),
          SourceCurrencyCode, SalesHeader."Sell-to Customer No.");
        GetShipmentLines(SalesHeader);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Post customer prepayment on 16.02
        PaymentNo := CreatePostPrepayment(WorkDate(), OrderSalesLine, SourceCurrencyCode, -OrderSalesLine."Amount Including VAT");

        // [WHEN] Apply prepayment to invoice
        ApplyCustomerPaymentToInvoice(PaymentNo, PostedInvoiceNo);

        // [THEN] No item ledger entries are posted
        ItemLedgerEntry.SetRange("Item No.", OrderSalesLine."No.");
        ItemLedgerEntry.SetRange(Open, true);
        Assert.RecordIsEmpty(ItemLedgerEntry);

        // [THEN] Value Entry with item charge "EXCLTACOST" is created
        // [THEN] "Cost Amount (Actual)" in value entry is 10 * 100 * (2.8 - 1.5) = 1300
        VerifyPrepaymentAdjmtValueEntry(OrderSalesLine, ExchRateAmount[1], ExchRateAmount[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPrepmtToInvWithCancelPrepmtAdjmtAndGLCorresp()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        EntryAmount: array[3] of Decimal;
    begin
        // [FEATURE] [Prepayment Difference] [Cancel Curr. Prepmt. Adjmt.] [G/L Correspondence] [Unapply]
        // [SCENARIO 390954] Unapply Prepayment from invoice with "Cancel Curr. Prepmt. Adjmt" and "Automatic G/L Correspondence"
        Initialize();

        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option = Yes, "Automatic G/L Correspondence" = Yes in G/L Setup
        SetCancelPrepmtAdjmtInGLSetup(true, false);
        SetAutomaticGLCorrInGLSetup();

        // [GIVEN] Posted Prepayment on 15/01/2021 and invoice for "GLAcc" on 15/02/2021 in FCY with diff. exch. rates and prepmt. diff. = 120, VAT % = 20
        PostInvAndPrepmtWithCurrency(InvoiceNo, PaymentNo, EntryAmount, CurrencyCode, true, true);

        SalesInvoiceHeader.Get(InvoiceNo);
        SalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        SalesInvoiceLine.FindFirst();
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetRange("G/L Account No.", SalesInvoiceLine."No.");
        Assert.RecordCount(GLEntry, 1);
        GLCorrespondenceEntry.SetRange("Credit Source No.", SalesInvoiceHeader."Sell-to Customer No.");
        GLCorrespondenceEntry.SetRange("Credit Account No.", SalesInvoiceLine."No.");
        Assert.RecordCount(GLCorrespondenceEntry, 1);

        // [GIVEN] Apply Prepayment to Invoice
        ApplyCustomerPaymentToInvoice(PaymentNo, InvoiceNo);

        VATEntry.SetRange("Document No.", InvoiceNo);
        VATEntry.SetRange("Prepmt. Diff.", true);
        VATEntry.FindFirst();
        Assert.RecordCount(VATEntry, 1);
        Assert.RecordCount(GLEntry, 2);
        Assert.RecordCount(GLCorrespondenceEntry, 2);

        // [WHEN] Unapply entries
        UnApplyCustomerPayment(PaymentNo);

        // [THEN] G/L Entry and G/L correspondence entries unapplied for "GLAcc" account with Amount = 120
        Assert.RecordCount(VATEntry, 2);
        Assert.RecordCount(GLEntry, 3);
        Assert.RecordCount(GLCorrespondenceEntry, 3);
        GLEntry.FindLast();
        GLEntry.TestField(Amount, -VATEntry.Base - VATEntry.Amount);
        GLCorrespondenceEntry.FindLast();
        GLCorrespondenceEntry.TestField(Amount, VATEntry.Base + VATEntry.Amount);

        // [THEN] Sales Invoice for prepmt. difference created with Amount Incl. VAT = 120
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", VATEntry."Bill-to/Pay-to No.");
        SalesInvoiceHeader.SetRange(Closed, true);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        SalesInvoiceHeader.TestField("Amount Including VAT", VATEntry.Base + VATEntry.Amount);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        UpdateSalesSetup();

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure PrepareSetup(IsCancelPrepmt: Boolean; var ExchRateAmount: array[3] of Decimal; IsRaise: Boolean): Code[10]
    begin
        UpdateGLSetup(IsCancelPrepmt);
        SetupExchRateAmount(ExchRateAmount, IsRaise);
        exit(CreateCurrencyWithExchRates(WorkDate(), ExchRateAmount));
    end;

    local procedure UpdateGLSetup(NewCancelCurrAdjmtPrepmt: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable Russian Tax Accounting", true);
        GLSetup.Validate("Cancel Curr. Prepmt. Adjmt.", NewCancelCurrAdjmtPrepmt);
        GLSetup.Validate("Currency Adjmt with Correction", false);
        GLSetup.Modify(true);
    end;

    local procedure UpdateSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Create Prepayment Invoice", false);
        SalesSetup.Modify(true);
    end;

    local procedure SetupExchRateAmount(var ExchRateAmount: array[3] of Decimal; IsRaise: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
        Factor: Decimal;
        i: Integer;
    begin
        GLSetup.Get();
        ExchRateAmount[1] := 1 + LibraryRandom.RandDec(10, 2);
        if IsRaise then
            Factor := 1.3
        else
            Factor := 0.7;
        for i := 2 to ArrayLen(ExchRateAmount) do
            ExchRateAmount[i] :=
              Round(ExchRateAmount[i - 1] * Factor, GLSetup."Amount Rounding Precision");
    end;

    local procedure SetUnrealVATSetupOnSalesPrepmtAccount(CustNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustNo);
        CustPostingGroup.Get(Customer."Customer Posting Group");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        CustPostingGroup.Validate("Prepayment Account", GLAccount."No.");
        CustPostingGroup.Modify(true);
    end;

    local procedure SetCancelPrepmtAdjmtInGLSetup(CancelCurrPrepmtAdjmt: Boolean; CancelPrepmtAdjmtInTA: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Cancel Curr. Prepmt. Adjmt." := CancelCurrPrepmtAdjmt;
        GLSetup."Cancel Prepmt. Adjmt. in TA" := CancelPrepmtAdjmtInTA;
        GLSetup.Modify(true);
    end;

    local procedure SetCreatePrepmtInvInSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Create Prepayment Invoice", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetAutomaticGLCorrInGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Automatic G/L Correspondence", true);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure ApplyInvCurrToPrepmt(IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PmtNo: Code[20];
        EntryAmount: array[3] of Decimal;
    begin
        PostInvCurrAndPrepmt(
          InvNo, PmtNo, EntryAmount, CurrencyCode, IsRaise, IsCancelPrepmt);
        ApplyCustomerPaymentToInvoice(PmtNo, InvNo);
        VerifyZeroRemAmtOnLedgEntry(CustLedgEntry."Document Type"::Invoice, InvNo);
        VerifyZeroRemAmtOnLedgEntry(CustLedgEntry."Document Type"::Payment, PmtNo);
        if IsCancelPrepmt then
            VerifyPrepmtDiffApplication(InvNo, EntryAmount[EntryType::Invoice] - EntryAmount[EntryType::Prepayment])
        else
            VerifyGainLossEntries(
              CustLedgEntry."Document Type"::Invoice, InvNo, CurrencyCode,
              not IsRaise, EntryAmount[EntryType::Invoice] - EntryAmount[EntryType::Prepayment]);
    end;

    local procedure ApplyInvAndRefundToPrepmt(IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PmtNo: Code[20];
        RefundNo: Code[20];
        PostingDate: Date;
        EntryAmount: array[3] of Decimal;
        RefundAmount: Decimal;
    begin
        Initialize();
        PostPartInvCurrAndPrepmt(
          InvNo, PmtNo, EntryAmount, CurrencyCode, IsRaise, IsCancelPrepmt);
        ApplyCustomerPaymentToInvoice(PmtNo, InvNo);
        RefundAmount := -Round(EntryAmount[EntryType::Prepayment] / 3, 1);
        PostingDate := CalcDate('<2M>', WorkDate());
        RefundNo := PostApplyRefundToPrepayment(PostingDate, PmtNo, CurrencyCode, RefundAmount);
        CalcAndVerifyCorrEntries(
          CurrencyCode, PostingDate, IsRaise, IsCancelPrepmt, PmtNo, RefundNo, RefundAmount, 1);
    end;

    local procedure ApplyCustomerPaymentToInvoice(PaymentDocNo: Code[20]; InvoiceDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgerEntry."Document Type"::Payment, PaymentDocNo,
          CustLedgerEntry."Document Type"::Invoice, InvoiceDocNo);
    end;

    local procedure ApplyCustomerPaymentToRefund(PaymentDocNo: Code[20]; RefundDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgerEntry."Document Type"::Payment, PaymentDocNo,
          CustLedgerEntry."Document Type"::Refund, RefundDocNo);
    end;

    local procedure GetShipmentLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);
    end;

    local procedure UnApplyCustomerPayment(PaymentDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentDocNo);
        UnapplyCustLedgerEntries(CustLedgerEntry."Entry No.", PaymentDocNo);
    end;

    local procedure UnApplyCustomerRefund(RefundDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Refund, RefundDocNo);
        UnapplyCustLedgerEntries(CustLedgerEntry."Entry No.", RefundDocNo);
    end;

    local procedure UnapplyLedgerEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, DocType, DocNo);
        UnapplyCustLedgerEntries(CustLedgEntry."Entry No.", DocNo);
    end;

    local procedure UnapplyCustLedgerEntries(CustEntryNo: Integer; DocumentNo: Code[20])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustEntryNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.FindFirst();
        ApplyUnapplyParameters."Document No." := DocumentNo;
        ApplyUnapplyParameters."Posting Date" := DetailedCustLedgEntry."Posting Date";
        CustEntryApplyPostedEntries.PostUnApplyCustomer(DetailedCustLedgEntry, ApplyUnapplyParameters);
    end;

    local procedure UnapplyInvAndRefundToPrepmt(IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PmtNo: Code[20];
        RefundNo: Code[20];
        PostingDate: Date;
        EntryAmount: array[3] of Decimal;
        RefundAmount: Decimal;
    begin
        Initialize();
        PostPartInvCurrAndPrepmt(
          InvNo, PmtNo, EntryAmount, CurrencyCode, IsRaise, IsCancelPrepmt);
        ApplyCustomerPaymentToInvoice(PmtNo, InvNo);
        RefundAmount := -Round(EntryAmount[EntryType::Prepayment] / 3, 1);
        PostingDate := CalcDate('<2M>', WorkDate());
        RefundNo := PostApplyRefundToPrepayment(PostingDate, PmtNo, CurrencyCode, RefundAmount);
        UnApplyCustomerRefund(RefundNo);
        VerifyUnappliedLedgerEntry(CustLedgEntry."Document Type"::Refund, RefundNo);
        CalcAndVerifyCorrEntries(
          CurrencyCode, PostingDate, IsRaise, IsCancelPrepmt, PmtNo, RefundNo, RefundAmount, -1);
    end;

    local procedure UnapplyInvCurrToPrepmt(IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PmtNo: Code[20];
        EntryAmount: array[3] of Decimal;
    begin
        Initialize();
        PostInvCurrAndPrepmt(
          InvNo, PmtNo, EntryAmount, CurrencyCode, IsRaise, IsCancelPrepmt);
        ApplyCustomerPaymentToInvoice(PmtNo, InvNo);
        UnApplyCustomerPayment(PmtNo);
        VerifyUnappliedLedgerEntry(CustLedgEntry."Document Type"::Invoice, InvNo);
        VerifyUnappliedLedgerEntry(CustLedgEntry."Document Type"::Payment, PmtNo);
        if IsCancelPrepmt then
            VerifyPrepmtDiffApplication(InvNo, EntryAmount[EntryType::Prepayment] - EntryAmount[EntryType::Invoice])
        else
            VerifyGainLossEntries(
              CustLedgEntry."Document Type"::Invoice, InvNo, CurrencyCode,
              not IsRaise, EntryAmount[EntryType::Invoice] - EntryAmount[EntryType::Prepayment]);
    end;

    local procedure PostAdjustInvAndPrepmtWithCurr(IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PmtNo: Code[20];
        ExpectedDocNo: Code[20];
        AdjPostingDate: Date;
        EntryAmount: array[3] of Decimal;
    begin
        Initialize();
        ExpectedDocNo := GetGenJnlTemplateNextNo(AdjPostingDate);
        PostInvAndPrepmtWithCurrency(
          InvNo, PmtNo, EntryAmount, CurrencyCode, IsRaise, IsCancelPrepmt);
        AdjPostingDate := CalcDate('<1M+CM>', WorkDate());
        RunAdjExchRates(CurrencyCode, AdjPostingDate, GetCustNoFromCustLedgEntry(InvNo));
        VerifyAdjGLEntries(
          ExpectedDocNo, CurrencyCode, IsRaise, IsCancelPrepmt, EntryAmount[EntryType::Prepayment] - EntryAmount[EntryType::Invoice]);
    end;

    local procedure PostInvCurrAndPrepmt(var InvNo: Code[20]; var PmtNo: Code[20]; var EntryAmount: array[3] of Decimal; var SourceCurrencyCode: Code[10]; IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExchRateAmount: array[3] of Decimal;
    begin
        Initialize();
        SourceCurrencyCode := PrepareSetup(IsCancelPrepmt, ExchRateAmount, IsRaise);
        LibrarySales.CreateFCYSalesInvoiceWithGLAcc(SalesHeader, SalesLine, '', '', CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CalculateEntryAmount(EntryAmount, ExchRateAmount, SalesLine."Amount Including VAT");
        PmtNo :=
          CreatePostPrepayment(WorkDate(), SalesLine, '', -EntryAmount[EntryType::Invoice]);
        InvNo := PostInvoice(SalesLine);
    end;

    local procedure PostInvAndPrepmtWithCurrency(var InvNo: Code[20]; var PmtNo: Code[20]; var EntryAmount: array[3] of Decimal; var SourceCurrencyCode: Code[10]; IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExchRateAmount: array[3] of Decimal;
    begin
        SourceCurrencyCode := PrepareSetup(IsCancelPrepmt, ExchRateAmount, IsRaise);
        LibrarySales.CreateFCYSalesInvoiceWithGLAcc(SalesHeader, SalesLine, '', '', CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CalculateEntryAmount(EntryAmount, ExchRateAmount, SalesLine."Amount Including VAT");
        PmtNo :=
          CreatePostPrepayment(WorkDate(), SalesLine, SourceCurrencyCode, -SalesLine."Amount Including VAT");
        InvNo := PostInvoice(SalesLine);
    end;

    local procedure PostPartItemInvAndPrepmtWithCurrency(var InvNo: Code[20]; var PmtNo: Code[20]; var CustomerNo: Code[20]; var ItemNo: Code[20]; IsRaise: Boolean; IsCancelPrepmt: Boolean): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SourceCurrencyCode: Code[10];
        ExchRateAmount: array[3] of Decimal;
        PmtAmount: Decimal;
    begin
        SourceCurrencyCode := PrepareSetup(IsCancelPrepmt, ExchRateAmount, IsRaise);
        CreateItemSalesDocWithCurrency(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        PmtAmount := Round(SalesLine."Amount Including VAT" / 3, 1);
        PmtNo := CreatePostPrepayment(WorkDate(), SalesLine, SourceCurrencyCode, -PmtAmount);
        InvNo := PostInvoice(SalesLine);
        CustomerNo := SalesHeader."Sell-to Customer No.";
        ItemNo := SalesLine."No.";
        exit(PmtAmount * Abs(ExchRateAmount[1] - ExchRateAmount[2]));
    end;

    local procedure PostInvAndUnrealPrepmt(var InvNo: Code[20]; var PmtNo: Code[20]; var VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesInvoiceWithGLAcc(SalesHeader, SalesLine, '', '');
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Posting Date", CalcDate('<1M>', WorkDate()));
        SalesHeader.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT %");
        SetUnrealVATSetupOnSalesPrepmtAccount(SalesLine."Bill-to Customer No.", VATPostingSetup);
        PmtNo :=
          CreatePostPrepayment(WorkDate(), SalesLine, '', -SalesLine."Amount Including VAT");
        InvNo := PostInvoice(SalesLine);
        exit(
          Round(SalesLine."Amount Including VAT" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
            LibraryERM.GetCurrencyAmountRoundingPrecision('')));
    end;

    local procedure PostPartInvCurrAndPrepmt(var InvNo: Code[20]; var PmtNo: Code[20]; var EntryAmount: array[3] of Decimal; var SourceCurrencyCode: Code[10]; IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExchRateAmount: array[3] of Decimal;
    begin
        Initialize();
        SourceCurrencyCode := PrepareSetup(IsCancelPrepmt, ExchRateAmount, IsRaise);
        LibrarySales.CreateFCYSalesInvoiceWithGLAcc(SalesHeader, SalesLine, '', '', CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CalculateEntryAmount(EntryAmount, ExchRateAmount, SalesLine."Amount Including VAT");
        EntryAmount[EntryType::Invoice] := Round(EntryAmount[EntryType::Invoice] * 3, 1);
        PmtNo :=
          CreatePostPrepayment(WorkDate(), SalesLine, SourceCurrencyCode, -EntryAmount[EntryType::Invoice]);
        InvNo := PostInvoice(SalesLine);
    end;

    local procedure PostInvoice(SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostApplyRefundToPrepayment(PostingDate: Date; PmtNo: Code[20]; CurrencyCode: Code[10]; EntryAmount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        InitGenJnlLine(GenJnlLine);
        CreateGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::Refund, PostingDate, GetCustNoFromCustLedgEntry(PmtNo), CurrencyCode, false, -EntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        ApplyCustomerPaymentToRefund(PmtNo, GenJnlLine."Document No.");
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreateCurrencyWithExchRates(StartingDate: Date; ExchRateAmount: array[3] of Decimal) CurrencyCode: Code[10]
    var
        i: Integer;
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        for i := 1 to ArrayLen(ExchRateAmount) do begin
            CreateCurrExchRates(CurrencyCode, StartingDate, '', ExchRateAmount[i]);
            StartingDate := CalcDate('<1M>', StartingDate);
        end;
        exit(CurrencyCode);
    end;

    local procedure CreateCurrExchRates(CurrencyCode: Code[10]; StartingDate: Date; RelationalCurrencyCode: Code[10]; RelationalAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Currency Code", RelationalCurrencyCode);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalAmount);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateUnrealVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATRate: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateItemNo(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItemCost(Item);
        exit(Item."No.");
    end;

    local procedure CreateLotItemNo(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryItemTracking.CreateLotItem(Item);
        UpdateItemCost(Item);
        exit(Item."No.");
    end;

    local procedure UpdateItemCost(var Item: Record Item)
    begin
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Item.Validate("Unit Price", Item."Unit Cost");
        Item.Modify(true);
    end;

    local procedure CreatePostPrepayment(PostingDate: Date; SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; PmtAmount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        InitGenJnlLine(GenJnlLine);
        CreateGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::Payment, PostingDate, SalesLine."Sell-to Customer No.", CurrencyCode, true, PmtAmount);
        GenJnlLine.Validate("Prepayment Document No.", SalesLine."Document No.");
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure InitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        GenJnlBatch.SetRange(Recurring, false);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; AccountNo: Code[20]; CurrencyCode: Code[10]; IsPrepayment: Boolean; EntryAmount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", DocType,
            GenJnlLine."Account Type"::Customer, AccountNo, EntryAmount);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate(Prepayment, IsPrepayment);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlLine.Modify(true);
    end;

    local procedure CreateItemSalesDocWithCurrency(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; PostingDate: Date; CurrencyCode: Code[10])
    begin
        CreateSalesHeaderWithCurrency(SalesHeader, DocumentType, PostingDate, CurrencyCode, LibrarySales.CreateCustomerNo());

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemNo(), LibraryRandom.RandIntInRange(2, 10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesHeaderWithCurrency(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; PostingDate: Date; CurrencyCode: Code[10]; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateLotItemInventory(Quantity: Decimal) ItemNo: Code[20]
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemNo := CreateLotItemNo();
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingLinesOption::NewLot);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateSalesOrderWithTrackedItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; Date: Date; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Posting Date", Date);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingLinesOption::SetLot);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CurrencyCode: Code[10]; PostingDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", '', 0);
        LibrarySales.GetShipmentLines(SalesLine);
    end;

    local procedure GetEntryType(IsRaise: Boolean): Enum "Detailed CV Ledger Entry Type"
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if IsRaise then
            exit(DtldCustLedgEntry."Entry Type"::"Realized Gain");
        exit(DtldCustLedgEntry."Entry Type"::"Realized Loss");
    end;

    local procedure GetGainLossAccount(CurrencyCode: Code[10]; IsRaise: Boolean): Code[20]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        if IsRaise then
            exit(Currency."Realized Gains Acc.");
        exit(Currency."Realized Losses Acc.");
    end;

    local procedure GetPDGainLossAccount(Currency: Record Currency; IsRaise: Boolean; IsCancelPrepmt: Boolean): Code[20]
    begin
        if IsCancelPrepmt then begin
            if IsRaise then
                exit(Currency."Sales PD Losses Acc. (TA)");
            exit(Currency."Sales PD Gains Acc. (TA)");
        end;
        if IsRaise then
            exit(Currency."Unrealized Losses Acc.");
        exit(Currency."Unrealized Gains Acc.");
    end;

    local procedure GetPDBalAccount(Currency: Record Currency; DocNo: Code[20]; IsCancelPrepmt: Boolean): Code[20]
    var
        CustPostGroup: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if IsCancelPrepmt then
            exit(Currency."PD Bal. Gain/Loss Acc. (TA)");
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast();
        CustPostGroup.Get(CustLedgEntry."Customer Posting Group");
        exit(CustPostGroup."Prepayment Account");
    end;

    local procedure GetCustNoFromCustLedgEntry(DocNo: Code[20]): Code[20]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast();
        exit(CustLedgEntry."Customer No.");
    end;

    local procedure GetExchRateDiff(CurrencyCode: Code[10]; PostingDateFrom: Date; PostingDateTo: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
        ExchRateAmount: Decimal;
    begin
        CurrExchRate.FindCurrency(PostingDateFrom, CurrencyCode, 1);
        ExchRateAmount := CurrExchRate."Relational Exch. Rate Amount";
        CurrExchRate.FindCurrency(PostingDateTo, CurrencyCode, 1);
        exit(CurrExchRate."Relational Exch. Rate Amount" - ExchRateAmount);
    end;

    local procedure GetGenJnlTemplateNextNo(PostingDate: Date): Code[20]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        NoSeries: Codeunit "No. Series";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
        GenJnlTemplate.SetRange(Recurring, false);
        GenJnlTemplate.FindFirst();
        exit(NoSeries.PeekNextNo(GenJnlTemplate."No. Series", PostingDate));
    end;

    local procedure GetNextPrepmtInvNo(): Code[20]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Codeunit "No. Series";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Posted Prepayment Nos.");
        exit(NoSeries.PeekNextNo(SalesReceivablesSetup."Posted Prepayment Nos."));
    end;

    local procedure GetShipmentDocNo(CustomerNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindFirst();
        exit(SalesShipmentLine."Document No.");
    end;

    local procedure GetSaleILENo(ItemNo: Code[20]; DocumentNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure GetItemChrgInvDocNo(CustomerNo: Code[20]; var AmountExclVAT: Decimal; var AmountInclVAT: Decimal): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"Charge (Item)");
        SalesInvoiceLine.FindFirst();

        SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.");
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        AmountExclVAT := SalesInvoiceHeader.Amount;
        AmountInclVAT := SalesInvoiceHeader."Amount Including VAT";
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure GetItemChrgCrMemoDocNo(CustomerNo: Code[20]; var AmountExclVAT: Decimal; var AmountInclVAT: Decimal): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Sell-to Customer No.", CustomerNo);
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::"Charge (Item)");
        SalesCrMemoLine.FindFirst();

        SalesCrMemoHeader.Get(SalesCrMemoLine."Document No.");
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        AmountExclVAT := SalesCrMemoHeader.Amount;
        AmountInclVAT := SalesCrMemoHeader."Amount Including VAT";
        exit(SalesCrMemoHeader."No.");
    end;

    local procedure CalcAndVerifyCorrEntries(CurrencyCode: Code[10]; PostingDate: Date; IsRaise: Boolean; IsCancelPrepmt: Boolean; PmtNo: Code[20]; RefundNo: Code[20]; CorrAmount: Decimal; Sign: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        ExpectedDocNo: Code[20];
        ExpectedDocType: Enum "Gen. Journal Document Type";
        ExpectedAmount: Decimal;
    begin
        ExpectedAmount :=
          Round(CorrAmount * GetExchRateDiff(CurrencyCode, WorkDate(), PostingDate));
        if IsCancelPrepmt then begin
            ExpectedDocType := CustLedgEntry."Document Type"::Refund;
            ExpectedDocNo := RefundNo;
        end else begin
            ExpectedDocType := CustLedgEntry."Document Type"::Payment;
            ExpectedDocNo := PmtNo;
        end;
        VerifyCorrGainLossEntries(
          ExpectedDocType, ExpectedDocNo, CurrencyCode, not IsRaise, ExpectedAmount * Sign);
    end;

    local procedure CalculateEntryAmount(var EntryAmount: array[3] of Decimal; ExchRateAmount: array[3] of Decimal; BaseAmount: Decimal)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(EntryAmount) do
            EntryAmount[i] := Round(BaseAmount * ExchRateAmount[i]);
    end;

    local procedure RunAdjExchRates(CurrencyCode: Code[10]; PostingDate: Date; CustNo: Code[20])
    var
        Currency: Record Currency;
        Customer: Record Customer;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        Currency.SetRange(Code, CurrencyCode);
        Customer.SetRange("No.", CustNo);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.SetTableView(Customer);
        ExchRateAdjustment.InitializeRequest2(
          0D, PostingDate, '', PostingDate, LibraryUtility.GenerateGUID(), true, false);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.SetHideUI(true);
        ExchRateAdjustment.Run();
    end;

    local procedure FindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        CustLedgEntry.SetRange("Document Type", DocType);
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast();
    end;

    local procedure FindDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type")
    begin
        DtldCustLedgEntry.SetRange("Document Type", DocType);
        DtldCustLedgEntry.SetRange("Document No.", DocNo);
        DtldCustLedgEntry.SetRange("Entry Type", EntryType);
        Assert.IsTrue(
          DtldCustLedgEntry.FindLast(), StrSubstNo(EntryDoesNotExistErr, DtldCustLedgEntry.TableCaption(), DtldCustLedgEntry.GetFilters));
    end;

    local procedure FindSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; ItemNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("No.", ItemNo);
        SalesInvoiceLine.FindFirst();
    end;

    local procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
    end;

    local procedure VerifyZeroRemAmtOnLedgEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgEntry(CustLedgEntry, DocType, DocNo);
        CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        Assert.AreEqual(
          0, CustLedgEntry."Remaining Amount", StrSubstNo(WrongValueErr, CustLedgEntry.TableCaption(), CustLedgEntry.FieldCaption("Remaining Amount"), CustLedgEntry."Entry No."));
        Assert.AreEqual(
          0, CustLedgEntry."Remaining Amt. (LCY)", StrSubstNo(WrongValueErr, CustLedgEntry.TableCaption(), CustLedgEntry.FieldCaption("Remaining Amt. (LCY)"), CustLedgEntry."Entry No."));
    end;

    local procedure VerifyUnappliedLedgerEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgEntry(CustLedgEntry, DocType, DocNo);
        CustLedgEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)");
        Assert.AreEqual(
          CustLedgEntry."Remaining Amount", CustLedgEntry.Amount, StrSubstNo(WrongValueErr, CustLedgEntry.TableCaption(), CustLedgEntry.FieldCaption(Amount), CustLedgEntry."Entry No."));
        Assert.AreEqual(
          CustLedgEntry."Remaining Amt. (LCY)", CustLedgEntry."Amount (LCY)", StrSubstNo(WrongValueErr, CustLedgEntry.TableCaption(), CustLedgEntry.FieldCaption("Amount (LCY)"), CustLedgEntry."Entry No."));
    end;

    local procedure VerifyGainLossEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; CurrencyCode: Code[10]; IsRaise: Boolean; ExpectedAmount: Decimal)
    begin
        VerifyDtldCustLedgEntry(DocType, DocNo, IsRaise, ExpectedAmount);
        VerifyGLEntry(
          DocType, DocNo, GetGainLossAccount(CurrencyCode, IsRaise), -ExpectedAmount);
    end;

    local procedure VerifyCorrGainLossEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; CurrencyCode: Code[10]; IsRaise: Boolean; ExpectedAmount: Decimal)
    begin
        VerifyDtldCustLedgEntry(DocType, DocNo, IsRaise, ExpectedAmount);
        VerifyGLEntry(
          DocType, DocNo, GetGainLossAccount(CurrencyCode, IsRaise), -ExpectedAmount);
    end;

    local procedure VerifyDtldCustLedgEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; IsRaise: Boolean; ExpectedAmount: Decimal)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        FindDtldCustLedgEntry(DtldCustLedgEntry, DocType, DocNo, GetEntryType(IsRaise));
        Assert.AreEqual(
          0, DtldCustLedgEntry.Amount, StrSubstNo(WrongValueErr, DtldCustLedgEntry.TableCaption(), DtldCustLedgEntry.FieldCaption(Amount), DtldCustLedgEntry."Entry No."));
        Assert.AreEqual(
          ExpectedAmount, DtldCustLedgEntry."Amount (LCY)", StrSubstNo(WrongValueErr, DtldCustLedgEntry.TableCaption(), DtldCustLedgEntry.FieldCaption("Amount (LCY)"), DtldCustLedgEntry."Entry No."));
    end;

    local procedure VerifyPrepmtDiffApplication(DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast();
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DtldCustLedgEntry.SetRange("Prepmt. Diff.", true);
        Assert.IsTrue(
          DtldCustLedgEntry.FindLast(), StrSubstNo(EntryDoesNotExistErr, DtldCustLedgEntry.TableCaption(), DtldCustLedgEntry.GetFilters));
        Assert.AreEqual(
          ExpectedAmount, DtldCustLedgEntry."Amount (LCY)",
          StrSubstNo(WrongValueErr, DtldCustLedgEntry.TableCaption(), DtldCustLedgEntry.FieldCaption("Amount (LCY)"), DtldCustLedgEntry."Entry No."));
    end;

    local procedure VerifyPrepmtDiffGLEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        CustPostingGroup: Record "Customer Posting Group";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        FindCustLedgEntry(CustLedgEntry, DocType, DocNo);
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
        DtldCustLedgEntry.SetRange("Prepmt. Diff.", true);
        DtldCustLedgEntry.SetRange(Unapplied, true);
        Assert.IsTrue(
          DtldCustLedgEntry.FindLast(), StrSubstNo(EntryDoesNotExistErr, DtldCustLedgEntry.TableCaption(), DtldCustLedgEntry.GetFilters));
        CustPostingGroup.Get(CustLedgEntry."Customer Posting Group");
        VerifyGLEntry(
          DocType, DocNo, CustPostingGroup."Receivables Account", DtldCustLedgEntry."Amount (LCY)");
    end;

    local procedure VerifyAdjGLEntries(DocNo: Code[20]; CurrencyCode: Code[10]; IsRaise: Boolean; IsCancelPrepmt: Boolean; ExpectedAmount: Decimal)
    var
        Currency: Record Currency;
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Currency.Get(CurrencyCode);
        VerifyGLEntry(
          CustLedgEntry."Document Type"::Payment, DocNo, GetPDGainLossAccount(Currency, IsRaise, IsCancelPrepmt), ExpectedAmount);
        VerifyGLEntry(
          CustLedgEntry."Document Type"::Payment, DocNo, GetPDBalAccount(Currency, DocNo, IsCancelPrepmt), -ExpectedAmount);
    end;

    local procedure VerifyEmptyGLEntries(DocNo: Code[20]; CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Currency.Get(CurrencyCode);
        VerifyGLEntryDoesNotExist(
          CustLedgEntry."Document Type"::Payment, DocNo, GetPDGainLossAccount(Currency, true, true));
        VerifyGLEntryDoesNotExist(
          CustLedgEntry."Document Type"::Payment, DocNo, GetPDBalAccount(Currency, DocNo, true));
    end;

    local procedure VerifyGLEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(GLEntry, DocType, DocNo, GLAccNo);
        GLEntry.FindLast();
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyDebitCreditGLEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20]; ExpectedDebitAmount: Decimal; ExpectedCreditAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(GLEntry, DocType, DocNo, GLAccNo);
        GLEntry.FindLast();
        GLEntry.TestField("Debit Amount", ExpectedDebitAmount);
        GLEntry.TestField("Credit Amount", ExpectedCreditAmount);
    end;

    local procedure VerifyGLEntryDoesNotExist(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntry(GLEntry, DocType, DocNo, GLAccNo);
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyPrepaymentAdjmtValueEntry(SalesLine: Record "Sales Line"; PrepmtExchRate: Decimal; InvoiceExchRate: Decimal)
    var
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        ValueEntry: Record "Value Entry";
    begin
        Item.Get(SalesLine."No.");
        InventoryPostingGroup.Get(Item."Inventory Posting Group");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Charge No.", InventoryPostingGroup."Sales PD Charge FCY (Item)");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo");
        ValueEntry.FindFirst();

        ValueEntry.TestField(
          "Sales Amount (Actual)",
          Round(SalesLine.Amount * PrepmtExchRate) - Round(SalesLine.Amount * InvoiceExchRate));
    end;

    local procedure VerifyValueEntrySalesAmountActual(ItemNo: Code[20]; DocumentNo: Code[20]; ILENo: Integer; ExpectedAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Ledger Entry No.", ILENo);
        ValueEntry.FindFirst();
        Assert.AreEqual(ExpectedAmount, ValueEntry."Sales Amount (Actual)", ValueEntry.FieldCaption("Sales Amount (Actual)"));
    end;

    local procedure VerifyDetailedCustLedgEntry(CustomerNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(DetailedCustLedgEntry);
    end;

    local procedure VerifyPrepmtApplication(CustomerNo: Code[20]; ItemNo: Code[20]; PaymentNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        FindSalesInvoiceLine(SalesInvoiceLine, ItemNo);
        VerifyDetailedCustLedgEntry(
          CustomerNo, DetailedCustLedgEntry."Entry Type"::Application,
          DetailedCustLedgEntry."Document Type"::Payment, PaymentNo);
        VerifyDetailedCustLedgEntry(
          CustomerNo, DetailedCustLedgEntry."Entry Type"::Application,
          DetailedCustLedgEntry."Document Type"::Invoice,
          SalesInvoiceLine."Document No.");
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingAdjustedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToAdjustTxt, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingLinesOption::NewLot:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingLinesOption::SetLot:
                ItemTrackingLines."Lot No.".AssistEdit();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesModalPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

