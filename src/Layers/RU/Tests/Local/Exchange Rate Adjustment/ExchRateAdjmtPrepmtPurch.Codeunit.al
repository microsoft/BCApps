codeunit 144021 "Exch.Rate Adjmt. Prepmt. Purch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment] [Purchase]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        EntryType: Option ,Invoice,Prepayment,Correction;
        IsInitialized: Boolean;
        WrongValueErr: Label 'Wrong value in %1.%2, Entry No.= %3.', Comment = '%1=table caption,%2=field caption';
        EntryDoesNotExistErr: Label 'Cannot find entry in table %1 with filters %2.';
        EntryExistsErr: Label 'The entry exists in table %1 with filters %2.';

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
        ApplyInvCurrToPrepmt(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvToNormalPrepmtCurrFail()
    begin
        ApplyInvCurrToPrepmt(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapInvToNormalPrepmtCurrRaise()
    begin
        UnapplyInvCurrToPrepmt(true, false);
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
    [Scope('OnPrem')]
    procedure AdjInvToCancelPrepmtRaise()
    begin
        PostAdjustInvAndPrepmtWithCurr(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjInvToCancelPrepmtFail()
    begin
        PostAdjustInvAndPrepmtWithCurr(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjInvToNormalPrepmtRaise()
    begin
        PostAdjustInvAndPrepmtWithCurr(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjInvToNormalPrepmtFail()
    begin
        PostAdjustInvAndPrepmtWithCurr(false, false);
    end;

    [Test]
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
        RunExchRateAdjustment(CurrencyCode, AdjPostingDate, GetVendNoFromVendLedgEntry(InvNo));
        VerifyEmptyGLEntries(ExpectedDocNo, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPrepmtToInvWithCancelPrepmtAdjmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
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
        ApplyVendorPaymentToInvoice(PmtNo, InvNo);

        // [WHEN] Unapply entries
        UnApplyVendorPayment(PmtNo);

        // [THEN] Unapplied Detailed Vendor Ledg. Entry with "Prepmt. Diff." = Yes has a related G/L Entry with same Amount (LCY).
        VerifyPrepmtDiffGLEntry(VendLedgEntry."Document Type"::Invoice, InvNo);
    end;

    [Test]
    [HandlerFunctions('ChangeVendorVATInvoiceReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnrealPrepmtToInvWithCancelPrepmtAdjmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        InvNo: Code[20];
        VendVATInvNo: Code[20];
        PmtNo: Code[20];
        InvAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Cancel Curr. Prepmt. Adjmt.] [Application] [Unrealized VAT]
        // [SCENARIO 363394] Prepayment G/L VAT Entry is created when apply prepayment with unrealized VAT to Invoice

        Initialize();
        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        // [GIVEN] Posted Prepayment with unrealized VAT Amount = "X" and invoice
        InvAmount := PostInvAndUnrealPrepmt(PmtNo, InvNo);
        // [GIVEN] Posted Vendor VAT Invoice for Prepayment
        VendVATInvNo := RunChangeVendorVATInvoice(VATPostingSetup, VendLedgEntry."Document Type"::Payment, PmtNo);
        VATAmount :=
          Round(InvAmount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
            LibraryERM.GetCurrencyAmountRoundingPrecision(''));

        // [WHEN] Apply Prepayment to Invoice
        ApplyVendorPaymentToInvoice(PmtNo, InvNo);

        // [THEN] Prepayment G/L VAT Entry is created with realized VAT Amount = "X"
        VerifyGLEntry(GLEntry."Document Type"::Invoice, VendVATInvNo, VATPostingSetup."Purchase VAT Account", VATAmount);
    end;

    [Test]
    [HandlerFunctions('ChangeVendorVATInvoiceReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyUnrealPrepmtToInvWithCancelPrepmtAdjmt()
    var
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        InvNo: Code[20];
        PmtNo: Code[20];
        PrepmtDocNo: Code[20];
        InvAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Cancel Curr. Prepmt. Adjmt.] [Unapply] [Unrealized VAT]
        // [SCENARIO 371855] Negative Credit G/L Entry with "Purch. VAT. Unreal Account" is created when unapply prepayment with unrealized VAT

        Initialize();
        GLSetup.Get();
        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        // [GIVEN] Posted Prepayment with unrealized VAT Amount = "X" and invoice
        InvAmount := PostInvAndUnrealPrepmt(PmtNo, InvNo);
        PrepmtDocNo := GetNextPrepmtInvNo();
        // [GIVEN] Posted Vendor VAT Invoice for Prepayment
        RunChangeVendorVATInvoice(VATPostingSetup, VendLedgEntry."Document Type"::Payment, PmtNo);
        VATAmount :=
          Round(InvAmount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
            LibraryERM.GetCurrencyAmountRoundingPrecision(''));
        // [GIVEN] Application between Prepayment and Invoice
        LibraryERM.ApplyVendorLedgerEntry(
          VendLedgEntry."Document Type"::Payment, PmtNo, VendLedgEntry."Document Type"::Invoice, InvNo);

        // [WHEN] Unapply Prepayment
        UnApplyVendorPayment(PmtNo);

        // [THEN] G/L Entry with "Purch. VAT. Unreal Account" and "Credit Amount" = -"X" is created
        VerifyDebitCreditGLEntry(
          GLEntry."Document Type"::Invoice, PrepmtDocNo, VATPostingSetup."Purch. VAT Unreal. Account", 0, -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMemoItemChrgAssgntPostPmtToInvApplWithPrepmtDiffFCYExchUp()
    var
        GLEntry: Record "G/L Entry";
        VendorNo: Code[20];
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
        // [SCENARIO 377194] Purchase Credit Memo's Item Charge Assignment has Prepayment Difference Amount Excl. VAT for Prepayment to Invoice application with different exch. rates (up) and Cancel Prepmt. Adjmt.
        Initialize();

        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        // [GIVEN] Released Item Invoice "I" with FCY = 1000$ = 800$ + 200$ (VAT25%) = 60000 LCY = 48000 + 12000 (1$ = 60 LCY).
        // [GIVEN] Posted Prepayment FCY = 500$ = 400$ + 100$ = 25000 LCY = 20000 + 5000 (1$ = 50 LCY).
        // [GIVEN] Post Invoice.
        PrepmtDiffAmountLCY := PostPartItemInvAndPrepmtWithCurrency(InvoiceNo, PaymentNo, VendorNo, ItemNo, true, true);

        // [WHEN] Apply Prepayment to Invoice. Prepayment Difference LCY = 5000 = 4000 + 1000
        ApplyVendorPaymentToInvoice(PaymentNo, InvoiceNo);

        // [THEN] Purchase Credit Memo with Item Charge is created with "Amount Including VAT" = 5000.
        ItemChrgCrMemoNo := GetItemChrgCrMemoDocNo(VendorNo, ItemChrgAmountExclVAT, ItemChrgAmountInclVAT);
        Assert.AreEqual(PrepmtDiffAmountLCY, ItemChrgAmountInclVAT, '');

        // [THEN] Value Entry is created for Purchase Credit Memo's Item Charge and has "Item Ledger Entry No." = <PurchaseInvoiceILE>, "Cost Amount (Actual)" = -4000.
        InvoiceILENo := GetPurchaseILENo(ItemNo, GetReceiptDocNo(VendorNo, ItemNo));
        VerifyValueEntryCostAmountActual(ItemNo, ItemChrgCrMemoNo, InvoiceILENo, -ItemChrgAmountExclVAT);

        // [THEN] GL Corresp. Entry is created for Item Charge Inventory To GL posting with Amount = 4000
        VerifyGLAndCorrespPairEntry(
          GLEntry."Document Type"::" ", ItemChrgCrMemoNo,
          GetDirectCostAppliedAccNo(InvoiceNo), GetInventoryAccNo(InvoiceNo),
          ItemChrgAmountExclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvItemChrgAssgntPostPmtToInvApplWithPrepmtDiffFCYExchDown()
    var
        GLEntry: Record "G/L Entry";
        VendorNo: Code[20];
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
        // [SCENARIO 377194] Purchase Invoice's Item Charge Assignment has Prepayment Difference Amount Excl. VAT for Prepayment to Invoice application with different exch. rates (down) and Cancel Prepmt. Adjmt.
        Initialize();

        // [GIVEN] "Cancel Curr. Prepmt. Adjmt." option is on
        SetCancelPrepmtAdjmtInGLSetup(true, true);
        // [GIVEN] Released Item Invoice "I" with FCY = 1000$ = 800$ + 200$ (VAT25%) = 60000 LCY = 48000 + 12000 (1$ = 60 LCY).
        // [GIVEN] Posted Prepayment FCY = 500$ = 400$ + 100$ = 35000 LCY = 28000 + 7000 (1$ = 70 LCY).
        // [GIVEN] Post Invoice.
        PrepmtDiffAmountLCY := PostPartItemInvAndPrepmtWithCurrency(InvoiceNo, PaymentNo, VendorNo, ItemNo, false, true);

        // [WHEN] Apply Prepayment to Invoice. Prepayment Difference LCY = 5000 = 4000 + 1000
        ApplyVendorPaymentToInvoice(PaymentNo, InvoiceNo);

        // [THEN] Purchase Invoice with Item Charge is created with "Amount Including VAT" = 5000.
        ItemChrgCrMemoNo := GetItemChrgInvDocNo(VendorNo, ItemChrgAmountExclVAT, ItemChrgAmountInclVAT);
        Assert.AreEqual(PrepmtDiffAmountLCY, ItemChrgAmountInclVAT, '');

        // [THEN] Value Entry is created for Purchase Invoice's Item Charge and has "Item Ledger Entry No." = <PurchaseInvoiceILE>, "Cost Amount (Actual)" = 4000.
        InvoiceILENo := GetPurchaseILENo(ItemNo, GetReceiptDocNo(VendorNo, ItemNo));
        VerifyValueEntryCostAmountActual(ItemNo, ItemChrgCrMemoNo, InvoiceILENo, ItemChrgAmountExclVAT);

        // [THEN] GL Corresp. Entry is created for Item Charge Inventory To GL posting with Amount = 4000
        VerifyGLAndCorrespPairEntry(
          GLEntry."Document Type"::" ", ItemChrgCrMemoNo,
          GetInventoryAccNo(InvoiceNo), GetDirectCostAppliedAccNo(InvoiceNo),
          ItemChrgAmountExclVAT);
    end;

    [Test]
    [HandlerFunctions('GetReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorPrepmtAppliedExchRateGainLossPostedAsItemChargeWithCancelPrepmtAdjmtInTA()
    var
        PurchaseHeader: Record "Purchase Header";
        OrderPurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SourceCurrencyCode: Code[10];
        ExchRateAmount: array[3] of Decimal;
        PostedInvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Currency] [Exchange Rates] [Cancel Prepmt. Adjmt. in TA]
        // [SCENARIO 281292] When applying vendor prepayment to invoice with option "Cancel Prepmt. Adjmt. in TA", exchange rate gain/loss is posted as item charge
        Initialize();

        // [GIVEN] Enable "Cancel Prepmt. Adjmt. in TA" in general ledger setup
        SetCancelPrepmtAdjmtInGLSetup(true, true);

        // [GIVEN] Setup exchange rates for EUR: 1.5 on 16.02.2020, 2.1 on 16.03.2020, 2.8 on 16.04.2020
        SourceCurrencyCode := PrepareSetup(true, ExchRateAmount, true);

        // [GIVEN] Purchase order for 10 pcs of item "I" with "Direct Unit Cost" = 100 EUR on 16.03. Post receipt.
        CreateItemPurchDocWithCurrency(
          PurchaseHeader, OrderPurchaseLine, PurchaseHeader."Document Type"::Order, CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create a separate invoice on 16.04 and get lines from the posted receipt. Post invoice.
        CreatePurchHeaderWithCurrency(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CalcDate('<2M>', WorkDate()),
          SourceCurrencyCode, PurchaseHeader."Buy-from Vendor No.");
        GetPurchaseReceiptLine(PurchaseHeader);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Post prepayment to vendor on 16.02
        PaymentNo :=
          CreatePostPrepayment(
            WorkDate(), PurchaseHeader."Buy-from Vendor No.", SourceCurrencyCode, OrderPurchaseLine."Amount Including VAT");

        // [WHEN] Apply prepayment to invoice
        ApplyVendorPaymentToInvoice(PaymentNo, PostedInvoiceNo);

        // [THEN] No item ledger entries are posted
        ItemLedgerEntry.SetRange("Item No.", OrderPurchaseLine."No.");
        Assert.RecordCount(ItemLedgerEntry, 1);

        // [THEN] Value Entry with item charge "EXCLTACOST" is created
        // [THEN] "Cost Amount (Actual)" in value entry is 10 * 100 * (2.8 - 1.5) = 1300
        VerifyPrepaymentAdjmtValueEntry(OrderPurchaseLine, ExchRateAmount[1], ExchRateAmount[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPrepmtToInvWithCancelPrepmtAdjmtAndGLCorresp()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
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

        PurchInvHeader.Get(InvoiceNo);
        PurchInvLine.SetRange("Document No.", InvoiceNo);
        PurchInvLine.FindFirst();
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetRange("G/L Account No.", PurchInvLine."No.");
        Assert.RecordCount(GLEntry, 1);
        GLCorrespondenceEntry.SetRange("Debit Source No.", PurchInvHeader."Buy-from Vendor No.");
        GLCorrespondenceEntry.SetRange("Debit Account No.", PurchInvLine."No.");
        Assert.RecordCount(GLCorrespondenceEntry, 1);

        // [GIVEN] Apply Prepayment to Invoice
        ApplyVendorPaymentToInvoice(PaymentNo, InvoiceNo);

        VATEntry.SetRange("Document No.", InvoiceNo);
        VATEntry.SetRange("Prepmt. Diff.", true);
        VATEntry.FindFirst();
        Assert.RecordCount(VATEntry, 1);
        Assert.RecordCount(GLEntry, 2);
        Assert.RecordCount(GLCorrespondenceEntry, 2);

        // [WHEN] Unapply entries
        UnApplyVendorPayment(PaymentNo);

        // [THEN] G/L Entry and G/L correspondence entries unapplied for "GLAcc" account with Amount = 100 as VAT Base
        Assert.RecordCount(VATEntry, 2);
        Assert.RecordCount(GLEntry, 3);
        Assert.RecordCount(GLCorrespondenceEntry, 3);
        GLEntry.FindLast();
        GLEntry.TestField(Amount, -VATEntry.Base);
        GLCorrespondenceEntry.FindLast();
        GLCorrespondenceEntry.TestField(Amount, -VATEntry.Base);

        // [THEN] Purchase Invoice for prepmt. difference created with Amount Incl. VAT = 120
        PurchInvHeader.SetRange("Buy-from Vendor No.", VATEntry."Bill-to/Pay-to No.");
        PurchInvHeader.SetRange(Closed, true);
        PurchInvHeader.FindFirst();
        PurchInvHeader.CalcFields("Amount Including VAT");
        PurchInvHeader.TestField("Amount Including VAT", -VATEntry.Base - VATEntry.Amount);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
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

    local procedure SetUnrealVATSetupOnSalesPrepmtAccount(VendNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        VendPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendNo);
        VendPostingGroup.Get(Vendor."Vendor Posting Group");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        VendPostingGroup.Validate("Prepayment Account", GLAccount."No.");
        VendPostingGroup.Modify(true);
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
        VendLedgEntry: Record "Vendor Ledger Entry";
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PmtNo: Code[20];
        EntryAmount: array[3] of Decimal;
    begin
        PostInvCurrAndPrepmt(
          InvNo, PmtNo, EntryAmount, CurrencyCode, IsRaise, IsCancelPrepmt);
        ApplyVendorPaymentToInvoice(PmtNo, InvNo);
        VerifyZeroRemAmtOnLedgEntry(VendLedgEntry."Document Type"::Invoice, InvNo);
        VerifyZeroRemAmtOnLedgEntry(VendLedgEntry."Document Type"::Payment, PmtNo);
        if IsCancelPrepmt then
            VerifyPrepmtDiffApplication(InvNo, EntryAmount[EntryType::Prepayment] - EntryAmount[EntryType::Invoice])
        else
            VerifyGainLossEntries(
              VendLedgEntry."Document Type"::Invoice, InvNo, CurrencyCode,
              not IsRaise, EntryAmount[EntryType::Prepayment] - EntryAmount[EntryType::Invoice]);
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
        ApplyVendorPaymentToInvoice(PmtNo, InvNo);
        RefundAmount := Round(EntryAmount[EntryType::Prepayment] / 3, 1);
        PostingDate := CalcDate('<2M>', WorkDate());
        RefundNo := PostApplyRefundToPrepayment(PostingDate, PmtNo, CurrencyCode, RefundAmount);
        CalcAndVerifyCorrEntries(
          CurrencyCode, PostingDate, IsRaise, IsCancelPrepmt, PmtNo, RefundNo, RefundAmount, 1);
    end;

    local procedure ApplyVendorPaymentToInvoice(PaymentDocNo: Code[20]; InvoiceDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.ApplyVendorLedgerEntry(
          VendLedgEntry."Document Type"::Payment, PaymentDocNo,
          VendLedgEntry."Document Type"::Invoice, InvoiceDocNo);
    end;

    local procedure ApplyVendorPaymentToRefund(PaymentDocNo: Code[20]; RefundDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.ApplyVendorLedgerEntry(
          VendLedgEntry."Document Type"::Payment, PaymentDocNo,
          VendLedgEntry."Document Type"::Refund, RefundDocNo);
    end;

    local procedure GetPurchaseReceiptLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        LibraryPurchase.GetPurchaseReceiptLine(PurchaseLine);
    end;

    local procedure UnApplyVendorPayment(PaymentDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Payment, PaymentDocNo);
        UnapplyVendLedgerEntries(VendLedgEntry."Entry No.", PaymentDocNo);
    end;

    local procedure UnApplyVendorRefund(RefundDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Refund, RefundDocNo);
        UnapplyVendLedgerEntries(VendLedgEntry."Entry No.", RefundDocNo);
    end;

    local procedure UnapplyVendLedgerEntries(VendEntryNo: Integer; DocumentNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendEntryNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.FindFirst();
        ApplyUnapplyParameters."Document No." := DocumentNo;
        ApplyUnapplyParameters."Posting Date" := DetailedVendorLedgEntry."Posting Date";
        VendEntryApplyPostedEntries.PostUnApplyVendor(DetailedVendorLedgEntry, ApplyUnapplyParameters);
    end;

    local procedure UnapplyInvAndRefundToPrepmt(IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
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
        ApplyVendorPaymentToInvoice(PmtNo, InvNo);
        RefundAmount := Round(EntryAmount[EntryType::Prepayment] / 3, 1);
        PostingDate := CalcDate('<2M>', WorkDate());
        RefundNo := PostApplyRefundToPrepayment(PostingDate, PmtNo, CurrencyCode, RefundAmount);
        UnApplyVendorRefund(RefundNo);
        VerifyUnappliedLedgerEntry(VendLedgEntry."Document Type"::Refund, RefundNo);
        CalcAndVerifyCorrEntries(
          CurrencyCode, PostingDate, IsRaise, IsCancelPrepmt, PmtNo, RefundNo, RefundAmount, -1);
    end;

    local procedure UnapplyInvCurrToPrepmt(IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CurrencyCode: Code[10];
        InvNo: Code[20];
        PmtNo: Code[20];
        EntryAmount: array[3] of Decimal;
    begin
        Initialize();
        PostInvCurrAndPrepmt(
          InvNo, PmtNo, EntryAmount, CurrencyCode, IsRaise, IsCancelPrepmt);
        ApplyVendorPaymentToInvoice(PmtNo, InvNo);
        UnApplyVendorPayment(PmtNo);
        VerifyUnappliedLedgerEntry(VendLedgEntry."Document Type"::Invoice, InvNo);
        VerifyUnappliedLedgerEntry(VendLedgEntry."Document Type"::Payment, PmtNo);
        if IsCancelPrepmt then
            VerifyPrepmtDiffApplication(InvNo, EntryAmount[EntryType::Invoice] - EntryAmount[EntryType::Prepayment])
        else
            VerifyGainLossEntries(
              VendLedgEntry."Document Type"::Invoice, InvNo, CurrencyCode,
              not IsRaise, EntryAmount[EntryType::Prepayment] - EntryAmount[EntryType::Invoice]);
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
        RunExchRateAdjustment(CurrencyCode, AdjPostingDate, GetVendNoFromVendLedgEntry(InvNo));
        VerifyAdjGLEntries(
          ExpectedDocNo, CurrencyCode, IsRaise, IsCancelPrepmt, EntryAmount[EntryType::Invoice] - EntryAmount[EntryType::Prepayment]);
    end;

    local procedure PostInvCurrAndPrepmt(var InvNo: Code[20]; var PmtNo: Code[20]; var EntryAmount: array[3] of Decimal; var SourceCurrencyCode: Code[10]; IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExchRateAmount: array[3] of Decimal;
    begin
        Initialize();
        SourceCurrencyCode := PrepareSetup(IsCancelPrepmt, ExchRateAmount, IsRaise);
        LibraryPurchase.CreateFCYPurchInvoiceWithGLAcc(
          PurchaseHeader, PurchLine, '', '', CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        CalculateEntryAmount(EntryAmount, ExchRateAmount, PurchLine."Amount Including VAT");
        PmtNo :=
          CreatePostPrepayment(WorkDate(), PurchaseHeader."Buy-from Vendor No.", '', EntryAmount[EntryType::Invoice]);
        InvNo := PostInvoice(PurchLine);
    end;

    local procedure PostInvAndPrepmtWithCurrency(var InvNo: Code[20]; var PmtNo: Code[20]; var EntryAmount: array[3] of Decimal; var SourceCurrencyCode: Code[10]; IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExchRateAmount: array[3] of Decimal;
    begin
        SourceCurrencyCode := PrepareSetup(IsCancelPrepmt, ExchRateAmount, IsRaise);
        LibraryPurchase.CreateFCYPurchInvoiceWithGLAcc(
          PurchaseHeader, PurchLine, '', '', CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        CalculateEntryAmount(EntryAmount, ExchRateAmount, PurchLine."Amount Including VAT");
        PmtNo :=
          CreatePostPrepayment(WorkDate(), PurchaseHeader."Buy-from Vendor No.", SourceCurrencyCode, PurchLine."Amount Including VAT");
        InvNo := PostInvoice(PurchLine);
    end;

    local procedure PostPartItemInvAndPrepmtWithCurrency(var InvNo: Code[20]; var PmtNo: Code[20]; var VendorNo: Code[20]; var ItemNo: Code[20]; IsRaise: Boolean; IsCancelPrepmt: Boolean): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        SourceCurrencyCode: Code[10];
        ExchRateAmount: array[3] of Decimal;
        PmtAmount: Decimal;
    begin
        SourceCurrencyCode := PrepareSetup(IsCancelPrepmt, ExchRateAmount, IsRaise);
        CreateItemPurchDocWithCurrency(
          PurchaseHeader, PurchLine, PurchaseHeader."Document Type"::Invoice, CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        PmtAmount := Round(PurchLine."Amount Including VAT" / 3, 1);
        PmtNo := CreatePostPrepayment(WorkDate(), PurchaseHeader."Buy-from Vendor No.", SourceCurrencyCode, PmtAmount);
        InvNo := PostInvoice(PurchLine);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        ItemNo := PurchLine."No.";
        exit(PmtAmount * Abs(ExchRateAmount[1] - ExchRateAmount[2]));
    end;

    local procedure PostPartInvCurrAndPrepmt(var InvNo: Code[20]; var PmtNo: Code[20]; var EntryAmount: array[3] of Decimal; var SourceCurrencyCode: Code[10]; IsRaise: Boolean; IsCancelPrepmt: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExchRateAmount: array[3] of Decimal;
    begin
        Initialize();
        SourceCurrencyCode := PrepareSetup(IsCancelPrepmt, ExchRateAmount, IsRaise);
        LibraryPurchase.CreateFCYPurchInvoiceWithGLAcc(
          PurchaseHeader, PurchLine, '', '', CalcDate('<1M>', WorkDate()), SourceCurrencyCode);
        CalculateEntryAmount(EntryAmount, ExchRateAmount, PurchLine."Amount Including VAT");
        EntryAmount[EntryType::Invoice] := Round(EntryAmount[EntryType::Invoice] * 3, 1);
        PmtNo :=
          CreatePostPrepayment(WorkDate(), PurchaseHeader."Buy-from Vendor No.", SourceCurrencyCode, EntryAmount[EntryType::Invoice]);
        InvNo := PostInvoice(PurchLine);
    end;

    local procedure PostInvAndUnrealPrepmt(var PmtNo: Code[20]; var InvNo: Code[20]): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchaseInvoiceWithGLAcc(PurchaseHeader, PurchaseLine, '', '');
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", CalcDate('<1M>', WorkDate()));
        PurchaseHeader.Modify(true);
        CreateUnrealVATPostingSetup(VATPostingSetup);
        SetUnrealVATSetupOnSalesPrepmtAccount(PurchaseLine."Pay-to Vendor No.", VATPostingSetup);
        PmtNo :=
          CreatePostPrepayment(WorkDate(), PurchaseHeader."Pay-to Vendor No.", '', PurchaseLine."Amount Including VAT");
        InvNo := PostInvoice(PurchaseLine);
        exit(PurchaseLine."Amount Including VAT");
    end;

    local procedure PostInvoice(PurchLine: Record "Purchase Line"): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure PostApplyRefundToPrepayment(PostingDate: Date; PmtNo: Code[20]; CurrencyCode: Code[10]; EntryAmount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: Code[20];
    begin
        InitGenJnlLine(GenJnlLine);
        VendNo :=
          GetVendNoFromVendLedgEntry(PmtNo);
        CreateGenJnlLine(GenJnlLine, GenJnlLine."Document Type"::Refund, PostingDate, VendNo, CurrencyCode, false, -EntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        ApplyVendorPaymentToRefund(PmtNo, GenJnlLine."Document No.");
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

    local procedure CreateUnrealVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateFullVATPostingSetupWithVATBusPostGroupCode(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATIdentifierCode: Code[20];
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);
        VATIdentifierCode := CopyStr(LibraryERM.CreateRandomVATIdentifierAndGetCode(), 1, MaxStrLen(VATIdentifierCode));
        VATPostingSetup.Validate("VAT Identifier", VATIdentifierCode);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePostPrepayment(PostingDate: Date; VendNo: Code[20]; CurrencyCode: Code[10]; PmtAmount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        InitGenJnlLine(GenJnlLine);
        CreateGenJnlLine(GenJnlLine, GenJnlLine."Document Type"::Payment, PostingDate, VendNo, CurrencyCode, true, PmtAmount);
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
            GenJnlLine."Account Type"::Vendor, AccountNo, EntryAmount);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate(Prepayment, IsPrepayment);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlLine.Modify(true);
    end;

    local procedure CreateItemPurchDocWithCurrency(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; PostingDate: Date; CurrencyCode: Code[10])
    begin
        CreatePurchHeaderWithCurrency(PurchaseHeader, DocumentType, PostingDate, CurrencyCode, LibraryPurchase.CreateVendorNo());

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(2, 10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 2000));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchHeaderWithCurrency(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PostingDate: Date; CurrencyCode: Code[10]; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure GetEntryType(IsLoss: Boolean): Enum "Detailed CV Ledger Entry Type"
    begin
        if IsLoss then
            exit("Detailed CV Ledger Entry Type"::"Realized Loss");

        exit("Detailed CV Ledger Entry Type"::"Realized Gain");
    end;

    local procedure GetGainLossAccount(CurrencyCode: Code[10]; IsRaise: Boolean): Code[20]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        if IsRaise then
            exit(Currency."Realized Losses Acc.");
        exit(Currency."Realized Gains Acc.");
    end;

    local procedure GetPDGainLossAccount(Currency: Record Currency; IsRaise: Boolean; IsCancelPrepmt: Boolean): Code[20]
    begin
        if IsCancelPrepmt then begin
            if IsRaise then
                exit(Currency."Purch. PD Gains Acc. (TA)");
            exit(Currency."Purch. PD Losses Acc. (TA)");
        end;
        if IsRaise then
            exit(Currency."Unrealized Gains Acc.");
        exit(Currency."Unrealized Losses Acc.");
    end;

    local procedure GetPDBalAccount(Currency: Record Currency; DocNo: Code[20]; IsCancelPrepmt: Boolean): Code[20]
    var
        VendPostGroup: Record "Vendor Posting Group";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if IsCancelPrepmt then
            exit(Currency."PD Bal. Gain/Loss Acc. (TA)");
        VendLedgEntry.SetRange("Document No.", DocNo);
        VendLedgEntry.FindLast();
        VendPostGroup.Get(VendLedgEntry."Vendor Posting Group");
        exit(VendPostGroup."Prepayment Account");
    end;

    local procedure GetDirectCostAppliedAccNo(PostedInvoiceNo: Code[20]): Code[20]
    var
        PurchInvLine: Record "Purch. Inv. Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        GeneralPostingSetup.Get(PurchInvLine."Gen. Bus. Posting Group", PurchInvLine."Gen. Prod. Posting Group");
        exit(GeneralPostingSetup."Direct Cost Applied Account");
    end;

    local procedure GetInventoryAccNo(PostedInvoiceNo: Code[20]): Code[20]
    var
        PurchInvLine: Record "Purch. Inv. Line";
        Item: Record Item;
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        PurchInvLine.SetRange("Document No.", PostedInvoiceNo);
        PurchInvLine.FindFirst();
        Item.Get(PurchInvLine."No.");
        InventoryPostingSetup.Get(PurchInvLine."Location Code", Item."Inventory Posting Group");
        exit(InventoryPostingSetup."Inventory Account");
    end;

    local procedure GetVendNoFromVendLedgEntry(DocNo: Code[20]): Code[20]
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Document No.", DocNo);
        VendLedgEntry.FindLast();
        exit(VendLedgEntry."Vendor No.");
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
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PurchPayablesSetup.Get();
        PurchPayablesSetup.TestField("Posted Invoice Nos.");
        exit(NoSeries.PeekNextNo(PurchPayablesSetup."Posted Invoice Nos."));
    end;

    local procedure GetReceiptDocNo(VendorNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
        exit(PurchRcptLine."Document No.");
    end;

    local procedure GetPurchaseILENo(ItemNo: Code[20]; DocumentNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure GetItemChrgInvDocNo(VendorNo: Code[20]; var AmountExclVAT: Decimal; var AmountInclVAT: Decimal): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvLine.SetRange(Type, PurchInvLine.Type::"Charge (Item)");
        PurchInvLine.FindFirst();

        PurchInvHeader.Get(PurchInvLine."Document No.");
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        AmountExclVAT := PurchInvHeader.Amount;
        AmountInclVAT := PurchInvHeader."Amount Including VAT";
        exit(PurchInvHeader."No.");
    end;

    local procedure GetItemChrgCrMemoDocNo(VendorNo: Code[20]; var AmountExclVAT: Decimal; var AmountInclVAT: Decimal): Code[20]
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::"Charge (Item)");
        PurchCrMemoLine.FindFirst();

        PurchCrMemoHdr.Get(PurchCrMemoLine."Document No.");
        PurchCrMemoHdr.CalcFields(Amount, "Amount Including VAT");
        AmountExclVAT := PurchCrMemoHdr.Amount;
        AmountInclVAT := PurchCrMemoHdr."Amount Including VAT";
        exit(PurchCrMemoHdr."No.");
    end;

    local procedure CalcAndVerifyCorrEntries(CurrencyCode: Code[10]; PostingDate: Date; IsRaise: Boolean; IsCancelPrepmt: Boolean; PmtNo: Code[20]; RefundNo: Code[20]; CorrAmount: Decimal; Sign: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        ExpectedDocNo: Code[20];
        ExpectedDocType: Enum "Gen. Journal Document Type";
        ExpectedAmount: Decimal;
    begin
        ExpectedAmount :=
          Round(CorrAmount * GetExchRateDiff(CurrencyCode, WorkDate(), PostingDate));
        if IsCancelPrepmt then begin
            ExpectedDocType := VendLedgEntry."Document Type"::Refund;
            ExpectedDocNo := RefundNo;
        end else begin
            ExpectedDocType := VendLedgEntry."Document Type"::Payment;
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

    local procedure RunExchRateAdjustment(CurrencyCode: Code[10]; PostingDate: Date; VendNo: Code[20])
    var
        Currency: Record Currency;
        Vendor: Record Vendor;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        Currency.SetRange(Code, CurrencyCode);
        Vendor.SetRange("No.", VendNo);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.SetTableView(Vendor);
        ExchRateAdjustment.InitializeRequest2(0D, PostingDate, '', PostingDate, LibraryUtility.GenerateGUID(), true, false);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.SetHideUI(true);
        ExchRateAdjustment.Run();
        Clear(ExchRateAdjustment);
    end;

    local procedure RunChangeVendorVATInvoice(var VATPostingSetup: Record "VAT Posting Setup"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]) InvNo: Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        ChangeVendorVATInvoice: Report "Change Vendor VAT Invoice";
        NoSeries: Codeunit "No. Series";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("Posted Invoice Nos.");
        InvNo := NoSeries.PeekNextNo(PurchasesPayablesSetup."Posted Invoice Nos.");

        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, DocType, DocNo);
        Vendor.Get(VendLedgEntry."Vendor No.");
        CreateFullVATPostingSetupWithVATBusPostGroupCode(VATPostingSetup, Vendor."VAT Bus. Posting Group");

        ChangeVendorVATInvoice.SetVendLedgEntry(VendLedgEntry);
        ChangeVendorVATInvoice.SetVATProdGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        Commit();
        ChangeVendorVATInvoice.Run();
        exit(InvNo);
    end;

    local procedure FindVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        VendLedgEntry.SetRange("Document Type", DocType);
        VendLedgEntry.SetRange("Document No.", DocNo);
        VendLedgEntry.FindLast();
    end;

    local procedure FindDtldVendLedgEntry(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; EntryType: Enum "Detailed CV Ledger Entry Type")
    begin
        DtldVendLedgEntry.SetRange("Document Type", DocType);
        DtldVendLedgEntry.SetRange("Document No.", DocNo);
        DtldVendLedgEntry.SetRange("Entry Type", EntryType);
        Assert.IsTrue(
            DtldVendLedgEntry.FindLast(),
            StrSubstNo(EntryDoesNotExistErr, DtldVendLedgEntry.TableCaption(), DtldVendLedgEntry.GetFilters()));
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.IsTrue(
            GLEntry.FindLast(),
            StrSubstNo(EntryDoesNotExistErr, GLEntry.TableCaption(), GLEntry.GetFilters()));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChangeVendorVATInvoiceReportHandler(var VendorVATInvoiceReportHandler: TestRequestPage "Change Vendor VAT Invoice")
    var
        VendVATInvNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendVATInvNo);
        VendorVATInvoiceReportHandler.InvoiceNo.SetValue(VendVATInvNo); // Vendor VAT Invoice No.
        VendorVATInvoiceReportHandler.InvoiceDate.SetValue(WorkDate());  // Vendor VAT Invoice Date
        VendorVATInvoiceReportHandler.InvoiceRcvdDate.SetValue(WorkDate());  // Vendor VAT Invoice Rcvd Date
        VendorVATInvoiceReportHandler.OK().Invoke();
    end;

    local procedure VerifyZeroRemAmtOnLedgEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        FindVendLedgEntry(VendLedgEntry, DocType, DocNo);
        VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        Assert.AreEqual(
          0, VendLedgEntry."Remaining Amount", StrSubstNo(WrongValueErr, VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption("Remaining Amount"), VendLedgEntry."Entry No."));
        Assert.AreEqual(
          0, VendLedgEntry."Remaining Amt. (LCY)", StrSubstNo(WrongValueErr, VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption("Remaining Amt. (LCY)"), VendLedgEntry."Entry No."));
    end;

    local procedure VerifyUnappliedLedgerEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        FindVendLedgEntry(VendLedgEntry, DocType, DocNo);
        VendLedgEntry.CalcFields(Amount, "Amount (LCY)", "Remaining Amount", "Remaining Amt. (LCY)");
        Assert.AreEqual(
          VendLedgEntry."Remaining Amount", VendLedgEntry.Amount, StrSubstNo(WrongValueErr, VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption(Amount), VendLedgEntry."Entry No."));
        Assert.AreEqual(
          VendLedgEntry."Remaining Amt. (LCY)", VendLedgEntry."Amount (LCY)", StrSubstNo(WrongValueErr, VendLedgEntry.TableCaption(), VendLedgEntry.FieldCaption("Amount (LCY)"), VendLedgEntry."Entry No."));
    end;

    local procedure VerifyGainLossEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; CurrencyCode: Code[10]; IsRaise: Boolean; ExpectedAmount: Decimal)
    begin
        VerifyDtldVendLedgEntry(DocType, DocNo, IsRaise, ExpectedAmount);
        VerifyGLEntry(
          DocType, DocNo, GetGainLossAccount(CurrencyCode, IsRaise), -ExpectedAmount);
    end;

    local procedure VerifyCorrGainLossEntries(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; CurrencyCode: Code[10]; IsRaise: Boolean; ExpectedAmount: Decimal)
    begin
        VerifyDtldVendLedgEntry(DocType, DocNo, IsRaise, ExpectedAmount);
        VerifyGLEntry(
          DocType, DocNo, GetGainLossAccount(CurrencyCode, IsRaise), -ExpectedAmount);
    end;

    local procedure VerifyDtldVendLedgEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; IsLoss: Boolean; ExpectedAmount: Decimal)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        FindDtldVendLedgEntry(DtldVendLedgEntry, DocType, DocNo, GetEntryType(IsLoss));
        Assert.AreEqual(
  0, DtldVendLedgEntry.Amount, StrSubstNo(WrongValueErr, DtldVendLedgEntry.TableCaption(), DtldVendLedgEntry.FieldCaption(Amount), DtldVendLedgEntry."Entry No."));
        Assert.AreEqual(
          ExpectedAmount, DtldVendLedgEntry."Amount (LCY)", StrSubstNo(WrongValueErr, DtldVendLedgEntry.TableCaption(), DtldVendLedgEntry.FieldCaption("Amount (LCY)"), DtldVendLedgEntry."Entry No."));
    end;

    local procedure VerifyPrepmtDiffApplication(DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        VendLedgEntry.SetRange("Document No.", DocNo);
        VendLedgEntry.FindLast();
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        DtldVendLedgEntry.SetRange("Prepmt. Diff.", true);
        Assert.IsTrue(
          DtldVendLedgEntry.FindLast(), StrSubstNo(EntryDoesNotExistErr, DtldVendLedgEntry.TableCaption(), DtldVendLedgEntry.GetFilters));
        Assert.AreEqual(
          ExpectedAmount, DtldVendLedgEntry."Amount (LCY)",
          StrSubstNo(WrongValueErr, DtldVendLedgEntry.TableCaption(), DtldVendLedgEntry.FieldCaption("Amount (LCY)"), DtldVendLedgEntry."Entry No."));
    end;

    local procedure VerifyPrepmtDiffGLEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VendPostingGroup: Record "Vendor Posting Group";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        FindVendLedgEntry(VendLedgEntry, DocType, DocNo);
        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
        DtldVendLedgEntry.SetRange("Prepmt. Diff.", true);
        DtldVendLedgEntry.SetRange(Unapplied, true);
        Assert.IsTrue(
          DtldVendLedgEntry.FindLast(), StrSubstNo(EntryDoesNotExistErr, DtldVendLedgEntry.TableCaption(), DtldVendLedgEntry.GetFilters));
        VendPostingGroup.Get(VendLedgEntry."Vendor Posting Group");
        VerifyGLEntry(
          DocType, DocNo, VendPostingGroup."Payables Account", DtldVendLedgEntry."Amount (LCY)");
    end;

    local procedure VerifyAdjGLEntries(DocNo: Code[20]; CurrencyCode: Code[10]; IsRaise: Boolean; IsCancelPrepmt: Boolean; ExpectedAmount: Decimal)
    var
        Currency: Record Currency;
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        Currency.Get(CurrencyCode);
        VerifyGLEntry(
          VendLedgEntry."Document Type"::Payment, DocNo, GetPDGainLossAccount(Currency, IsRaise, IsCancelPrepmt), ExpectedAmount);
        VerifyGLEntry(
          VendLedgEntry."Document Type"::Payment, DocNo, GetPDBalAccount(Currency, DocNo, IsCancelPrepmt), -ExpectedAmount);
    end;

    local procedure VerifyEmptyGLEntries(DocNo: Code[20]; CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        Currency.Get(CurrencyCode);
        VerifyGLEntryDoesNotExist(
          VendLedgEntry."Document Type"::Payment, DocNo, GetPDGainLossAccount(Currency, true, true));
        VerifyGLEntryDoesNotExist(
          VendLedgEntry."Document Type"::Payment, DocNo, GetPDBalAccount(Currency, DocNo, true));
    end;

    local procedure VerifyGLEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocType, DocNo, GLAccNo);
        Assert.AreEqual(
          ExpectedAmount, GLEntry.Amount, StrSubstNo(WrongValueErr, GLEntry.TableCaption(), GLEntry.FieldCaption(Amount), GLEntry."Entry No."));
    end;

    local procedure VerifyDebitCreditGLEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20]; ExpectedDebitAmount: Decimal; ExpectedCreditAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocType, DocNo, GLAccNo);
        GLEntry.TestField("Debit Amount", ExpectedDebitAmount);
        GLEntry.TestField("Credit Amount", ExpectedCreditAmount);
    end;

    local procedure VerifyGLEntryAmounts(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal; ExpectedDebitAmount: Decimal; ExpectedCreditAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocType, DocNo, GLAccNo);
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, GLEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedDebitAmount, GLEntry."Debit Amount", GLEntry.FieldCaption("Debit Amount"));
        Assert.AreEqual(ExpectedCreditAmount, GLEntry."Credit Amount", GLEntry.FieldCaption("Credit Amount"));
    end;

    local procedure VerifyGLEntryDoesNotExist(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.IsTrue(GLEntry.IsEmpty, StrSubstNo(EntryExistsErr, GLEntry.TableCaption(), GLEntry.GetFilters));
    end;

    local procedure VerifyGLCorrespEntry(DocumentNo: Code[20]; DebitAccNo: Code[20]; CreditAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        GLCorrespondenceEntry.SetRange("Document No.", DocumentNo);
        GLCorrespondenceEntry.SetRange("Debit Account No.", DebitAccNo);
        GLCorrespondenceEntry.SetRange("Credit Account No.", CreditAccNo);
        GLCorrespondenceEntry.FindFirst();
        Assert.AreEqual(ExpectedAmount, GLCorrespondenceEntry.Amount, GLCorrespondenceEntry.FieldCaption(Amount));
    end;

    local procedure VerifyGLAndCorrespPairEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DebitAccNo: Code[20]; CreditAccNo: Code[20]; DebitAmount: Decimal)
    begin
        VerifyGLEntryAmounts(DocumentType, DocumentNo, DebitAccNo, DebitAmount, DebitAmount, 0);
        VerifyGLEntryAmounts(DocumentType, DocumentNo, CreditAccNo, -DebitAmount, 0, DebitAmount);
        VerifyGLCorrespEntry(DocumentNo, DebitAccNo, CreditAccNo, DebitAmount);
    end;

    local procedure VerifyPrepaymentAdjmtValueEntry(PurchaseLine: Record "Purchase Line"; PrepmtExchRate: Decimal; InvoiceExchRate: Decimal)
    var
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
        ValueEntry: Record "Value Entry";
    begin
        Item.Get(PurchaseLine."No.");
        InventoryPostingGroup.Get(Item."Inventory Posting Group");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Charge No.", InventoryPostingGroup."Purch. PD Charge FCY (Item)");
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Credit Memo");
        ValueEntry.FindFirst();

        ValueEntry.TestField(
          "Cost Amount (Actual)",
          Round(PurchaseLine."Line Amount" * PrepmtExchRate) - Round(PurchaseLine."Line Amount" * InvoiceExchRate));
    end;

    local procedure VerifyValueEntryCostAmountActual(ItemNo: Code[20]; DocumentNo: Code[20]; ILENo: Integer; ExpectedAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Ledger Entry No.", ILENo);
        ValueEntry.FindFirst();
        Assert.AreEqual(ExpectedAmount, ValueEntry."Cost Amount (Actual)", ValueEntry.FieldCaption("Sales Amount (Actual)"));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesModalPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.OK().Invoke();
    end;
}

