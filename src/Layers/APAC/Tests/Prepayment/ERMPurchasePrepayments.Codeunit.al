codeunit 134333 "ERM Purchase Prepayments"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment] [Purchase]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        IsInitialized: Boolean;
        LCYCode: Code[10];
        QuantityMustBeRevertedErr: Label 'Quantity Received and Invoiced must be reverted to 0';
        QuantityMustBeRestoredErr: Label 'Qty. to Receive and Invoice must be restored to original values';
        NoAmtFoundToBePostedErr: Label 'No amount found to be posted.';
        PaymentReferenceNotTransferredErr: Label '%1 was not transferred to the %2.', Comment = '%1 Field Caption,%2 Table Caption';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Prepayments");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Prepayments");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LCYCode := '';
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Prepayments");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorDefaultPrepaymentDisc()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // 1. Setup
        Initialize();

        // Create a vendor with prepayment discount
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Prepayment %", LibraryRandom.RandInt(100));
        Vendor.Modify(true);

        // 2. Exercise - Create a purchase order for the vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // 3. Validation - Check prepayment in the purchase order is the same we defined in the vendor
        PurchaseHeader.TestField("Prepayment %", Vendor."Prepayment %");

        // 4. Clean-up
    end;

    local procedure PostPurchasePrepaymentHelper(CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpectedPrepaymentAmount: Decimal;
    begin
        // 1. Setup
        Initialize();

        PreparePrepaymentsPostingSetup(GLAccount);
        PrepareItemAccordingToSetup(Item, GLAccount);
        PrepareVendorAccordingToSetup(Vendor, GLAccount, LibraryRandom.RandInt(100));
        CreatePurchOrder(PurchaseHeader, Vendor, Item, CurrencyCode);

        // 2. Exercise - Post prepayment invoice in foreign currency order.
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // 3. Validation
        ForceAmountRecalculation(PurchaseHeader);

        // Check vendor only has one ledger entry (the prepayment).
        CheckNumOfVendorLedgerEntries(VendorLedgerEntry, Vendor, 1);

        // And check the prepayment amount is right.
        ExpectedPrepaymentAmount := -CalculatePrepaymentAmount(PurchaseHeader, CurrencyCode);

        VendorLedgerEntry.FindFirst();
        ValidateVendorLedgerEntries(VendorLedgerEntry, ExpectedPrepaymentAmount, CurrencyCode);

        // 4. Clean-up
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchasePrepayment()
    begin
        PostPurchasePrepaymentHelper(LCYCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchasePrepayment()
    var
        ForeignCurrency: Record Currency;
    begin
        FindForeignCurrency(ForeignCurrency);
        PostPurchasePrepaymentHelper(ForeignCurrency.Code);
    end;

    local procedure PostPurchPrepayCrMemoHelper(CurrencyCode: Code[10])
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpectedCreditMemoAmount: Decimal;
    begin
        // 1. Setup
        Initialize();

        PreparePrepaymentsPostingSetup(GLAccount);
        PrepareItemAccordingToSetup(Item, GLAccount);
        PrepareVendorAccordingToSetup(Vendor, GLAccount, LibraryRandom.RandInt(100));
        CreatePurchOrder(PurchaseHeader, Vendor, Item, CurrencyCode);

        // Post the prepayment
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // release the PO, required to update amount fields in the purchase lines, which is required before calculating the
        // Amount including VAT (flow field based on them).
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");

        // Prepare data to post credit memo.
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryPurchase.GegVendorLedgerEntryUniqueExternalDocNo());
        PurchaseHeader.Modify(true);

        // 2. Exercise - Post the credit memo
        PurchasePostPrepayments.CreditMemo(PurchaseHeader);

        // 3. Validation
        // Check vendor only has two ledger entries -  one entry the prepayment, the other one the credit memo.
        CheckNumOfVendorLedgerEntries(VendorLedgerEntry, Vendor, 2);

        // And check the prepayment amount is right.
        ExpectedCreditMemoAmount := CalculatePrepaymentAmount(PurchaseHeader, CurrencyCode);

        VendorLedgerEntry.FindLast();
        ValidateVendorLedgerEntries(VendorLedgerEntry, ExpectedCreditMemoAmount, CurrencyCode);
        // 4. Clean-up
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLCYPurchPrepCreditMemo()
    begin
        PostPurchPrepayCrMemoHelper(LCYCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostFCYPurchPrepCreditMemo()
    var
        ForeignCurrency: Record Currency;
    begin
        FindForeignCurrency(ForeignCurrency);
        PostPurchPrepayCrMemoHelper(ForeignCurrency.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTwoPurchasePrepayments()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ExpectedPrepaymentAmount: Decimal;
        FirstPrepaymentPercentage: Decimal;
        SecondPrepaymentPercentage: Decimal;
        MaximumPrepaymentPercentage: Integer;
        MinimumPrepaymentPercentage: Integer;
    begin
        // 1. Setup
        Initialize();

        MaximumPrepaymentPercentage := 100;

        // First prepayment should can't be the maximum because then there would be no room for the second one.
        FirstPrepaymentPercentage := LibraryRandom.RandInt(MaximumPrepaymentPercentage - 1);

        PreparePrepaymentsPostingSetup(GLAccount);
        PrepareItemAccordingToSetup(Item, GLAccount);
        PrepareVendorAccordingToSetup(Vendor, GLAccount, FirstPrepaymentPercentage);
        CreatePurchOrder(PurchaseHeader, Vendor, Item, LCYCode);

        // Post the prepayment
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // Reopen Doc
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Change prepayment to higher percentage.
        MinimumPrepaymentPercentage := Vendor."Prepayment %" + 1;
        SecondPrepaymentPercentage := LibraryRandom.RandIntInRange(MinimumPrepaymentPercentage, MaximumPrepaymentPercentage);
        PurchaseHeader.Validate("Prepayment %", SecondPrepaymentPercentage);

        // New Vendor Invoice no. otherwise it can't be posted.
        PurchaseHeader.Validate("Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);

        // 2. Exercise - Post the 2nd prepayment
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // 3. Validation
        ForceAmountRecalculation(PurchaseHeader);

        // Check vendor only has two ledger entries (one for each prepayment).
        CheckNumOfVendorLedgerEntries(VendorLedgerEntry, Vendor, 2);

        // And check the 2nd prepayment amount is right.
        PurchaseHeader.CalcFields("Amount Including VAT");
        ExpectedPrepaymentAmount := Round(-SecondPrepaymentPercentage * PurchaseHeader."Amount Including VAT" / 100);
        ExpectedPrepaymentAmount -= Round(-FirstPrepaymentPercentage * PurchaseHeader."Amount Including VAT" / 100);

        VendorLedgerEntry.FindLast();
        ValidateVendorLedgerEntries(VendorLedgerEntry, ExpectedPrepaymentAmount, LCYCode);

        // 4. Clean-up
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSecondPrepaymentInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentType: Option Invoice,"Credit Memo",Statistic;
        TempDecToHaveItEqual: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379850] Prepayment Invoice should be posted if one line of Purchase Invoice has amount to be posted and the last line has not

        Initialize();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        VATPostingSetup.SetRange("VAT Bus. Posting Group", PurchaseHeader."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", '');
        if not VATPostingSetup.FindFirst() then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", '');
        TempDecToHaveItEqual := LibraryRandom.RandDec(100, 2);
        CreatePurchLineWithPrepmtAmts(PurchaseHeader, TempDecToHaveItEqual, TempDecToHaveItEqual);
        CreatePurchLineWithPrepmtAmts(PurchaseHeader, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDecInRange(101, 200, 2));
        TempDecToHaveItEqual := LibraryRandom.RandDec(100, 2);
        CreatePurchLineWithPrepmtAmts(PurchaseHeader, TempDecToHaveItEqual, TempDecToHaveItEqual);

        Assert.IsTrue(PurchasePostPrepayments.CheckOpenPrepaymentLines(PurchaseHeader, DocumentType::Invoice), NoAmtFoundToBePostedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreateCorrectiveCreditMemoForPartialPurchaseInvoiceWithPrepayment()
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PostedInvoiceNo: Code[20];
        PrepaymentPercentage: Decimal;
    begin
        // [FEATURE] [Prepayment] [Purchase] [Corrective Credit Memo]
        // [SCENARIO 615442] Creating corrective credit memo for a partial purchase invoice with prepayment should include prepayment reversal line
        Initialize();

        // [GIVEN] Setup prepayment posting with G/L accounts.
        PrepaymentPercentage := LibraryRandom.RandIntInRange(5, 10);
        PreparePrepaymentsPostingSetup(GLAccount);
        PrepareItemAccordingToSetup(Item, GLAccount);
        PrepareVendorAccordingToSetup(Vendor, GLAccount, PrepaymentPercentage);

        // [GIVEN] Create Purchase Order with Vendor Invoice No.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a Purchase Line.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 2);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 1100));
        PurchaseLine.Modify(true);

        // [GIVEN] Post prepayment invoice.
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // [GIVEN] Partially Receive One Quantity.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", LibraryRandom.RandInt(1));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create and post invoice for partial receipt.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryPurchase.GegVendorLedgerEntryUniqueExternalDocNo());
        PurchaseHeader.Modify(true);
        PurchRcptLine.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchRcptLine.FindLast();
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        PurchaseHeader.CalcFields("Amount Including VAT");
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", PurchaseHeader."Amount Including VAT");
        PurchaseHeader.Modify(true);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Get prepayment account number from posting setup
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");

        // [WHEN] Create corrective credit memo for the posted purchase invoice
        PurchInvHeader.Get(PostedInvoiceNo);
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchaseHeader);

        // [THEN] Credit memo should contain a prepayment line
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        Assert.RecordIsNotEmpty(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelInvoiceFromGetReceiptLinesWithPrepaymentRevertsOrderLineWhenRestoreQtyEnabled()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        Quantity: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 635874] Cancelling a posted purchase invoice created via Get Receipt Lines from a PO with prepayment fully reverts the PO line quantities
        InitializeInvoiceCancellation(LibrarySetupStorage);
        SetRestoreOrderQtyOnReturn(true);

        // [GIVEN] General and VAT Posting Setup with Purch. Prepayments Account configured
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup."Direct Cost Applied Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup."Purch. Credit Memo Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        SetupPrepmtGLAccountPostingGroups(GeneralPostingSetup, VATPostingSetup);

        // [GIVEN] Item "I" with matching posting groups
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Vendor "V" with matching posting groups
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        // [GIVEN] Purchase Order with Prepayment % and one line for Item "I"
        Quantity := LibraryRandom.RandIntInRange(1, 10);
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");
        PurchaseHeaderOrder.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 50));
        PurchaseHeaderOrder.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeaderOrder, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 500, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Posted prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeaderOrder);

        // [GIVEN] Purchase Order posted with Receive only
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Purchase Invoice created via Get Receipt Lines from the receipt
        PurchRcptHeader.SetRange("Order No.", PurchaseHeaderOrder."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [GIVEN] Purchase Invoice posted
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true));

        // [WHEN] Cancel the Posted Purchase Invoice
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // [THEN] Purchase Order line is fully reverted: Qty. Received = 0, Qty. Invoiced = 0
        PurchaseLine.Find();
        Assert.AreEqual(0, PurchaseLine."Quantity Received", QuantityMustBeRevertedErr);
        Assert.AreEqual(0, PurchaseLine."Quantity Invoiced", QuantityMustBeRevertedErr);
        Assert.AreEqual(Quantity, PurchaseLine."Qty. to Receive", QuantityMustBeRestoredErr);
        Assert.AreEqual(Quantity, PurchaseLine."Qty. to Invoice", QuantityMustBeRestoredErr);
        PurchaseLine.TestField("Prepmt Amt Deducted", 0);
        PurchaseLine.TestField("Prepmt Amt to Deduct", PurchaseLine."Prepmt. Amt. Inv.");
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelInvoiceWithPrepaymentReconcilesPrepaymentWhenRestoreQtyDisabled()
    begin
        CancelInvoiceWithPrepaymentAndVerify(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPartialInvoiceRecalculatesPrepaymentWhenRestoreQtyDisabled()
    begin
        CancelInvoiceWithPrepaymentAndVerify(true);
    end;

    local procedure CancelInvoiceWithPrepaymentAndVerify(PartiallyInvoice: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PrepaidPurchaseLine: Record "Purchase Line";
        PurchaseCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchasePrepaymentInvoiceHeader: Record "Purch. Inv. Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        RemainingPurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ExpectedPrepmtToDeduct: Decimal;
        InvoicedQuantity: Decimal;
        OrderQuantity: Decimal;
        PrepaymentCreditMemoNo: Code[20];
        PrepaymentInvoiceNo: Code[20];
    begin
        // [SCENARIO 649626] Cancelling an invoice reconciles its prepayment when order quantity restoration is disabled.
        InitializeInvoiceCancellation(LibrarySetupStorage);
        InvoicedQuantity := 1;
        OrderQuantity := 1;
        if PartiallyInvoice then begin
            InvoicedQuantity := LibraryRandom.RandIntInRange(1, 5);
            // Keep the remaining line amount above the full 50% prepayment.
            OrderQuantity := 2 * InvoicedQuantity + LibraryRandom.RandIntInRange(1, 5);
            ExpectedPrepmtToDeduct := OrderQuantity * 50;
            PurchasesPayablesSetup.Get();
            PurchasesPayablesSetup.Validate("Default Qty. to Receive", PurchasesPayablesSetup."Default Qty. to Receive"::Remainder);
            PurchasesPayablesSetup.Modify(true);
        end;

        // [GIVEN] A Purchase Order with a paid 50% prepayment on the line that will be posted.
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        GeneralPostingSetup."Direct Cost Applied Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup."Purch. Credit Memo Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup.Modify(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20));
        SetupPrepmtGLAccountPostingGroups(GeneralPostingSetup, VATPostingSetup);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Prepayment %", 50);
        PurchaseHeader.Validate("Prepayment Due Date", WorkDate());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PrepaidPurchaseLine, PurchaseHeader, PrepaidPurchaseLine.Type::Item, Item."No.", OrderQuantity);
        PrepaidPurchaseLine.Validate("Direct Unit Cost", 100);
        PrepaidPurchaseLine.Validate("Qty. to Receive", InvoicedQuantity);
        PrepaidPurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(RemainingPurchaseLine, PurchaseHeader, RemainingPurchaseLine.Type::Item, Item."No.", OrderQuantity);
        RemainingPurchaseLine.Validate("Direct Unit Cost", 100);
        RemainingPurchaseLine.Validate("Prepayment %", 0);
        RemainingPurchaseLine.Validate("Qty. to Receive", 0);
        RemainingPurchaseLine.Validate("Qty. to Invoice", 0);
        RemainingPurchaseLine.Modify(true);

        PrepaymentInvoiceNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchasePrepaymentInvoiceHeader.Get(PrepaymentInvoiceNo);
        PurchasePrepaymentInvoiceHeader.CalcFields("Amount Including VAT");
        PostPaymentToInvoice(
            "Gen. Journal Account Type"::Vendor, Vendor."No.", PrepaymentInvoiceNo,
            PurchasePrepaymentInvoiceHeader."Amount Including VAT");

        // [GIVEN] The prepaid line is received and invoiced, and quantity restoration is disabled.
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        PurchaseInvoiceHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        if PartiallyInvoice then begin
            PrepaidPurchaseLine.Find();
            PrepaidPurchaseLine.TestField("Prepmt Amt Deducted", ExpectedPrepmtToDeduct * InvoicedQuantity / OrderQuantity);
            PrepaidPurchaseLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtToDeduct * (OrderQuantity - InvoicedQuantity) / OrderQuantity);
        end;
        SetRestoreOrderQtyOnReturn(false);
        Commit();

        // [WHEN] The posted invoice is cancelled.
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchaseInvoiceHeader);

        // [THEN] The order quantities remain posted, but its deducted prepayment is released.
        PrepaidPurchaseLine.Find();
        PrepaidPurchaseLine.TestField("Quantity Received", InvoicedQuantity);
        PrepaidPurchaseLine.TestField("Quantity Invoiced", InvoicedQuantity);
        PrepaidPurchaseLine.TestField(Quantity, OrderQuantity);
        PrepaidPurchaseLine.TestField("Qty. to Receive", OrderQuantity - InvoicedQuantity);
        PrepaidPurchaseLine.TestField("Qty. to Invoice", OrderQuantity - InvoicedQuantity);
        PrepaidPurchaseLine.TestField("Prepmt Amt Deducted", 0);
        PrepaidPurchaseLine.TestField("Prepmt Amt to Deduct", ExpectedPrepmtToDeduct);

        if PartiallyInvoice then begin
            // [THEN] The remaining quantity consumes the full released prepayment.
            // Posting resets pending quantities on the other line, which must remain unposted.
            RemainingPurchaseLine.Find();
            RemainingPurchaseLine.Validate("Qty. to Receive", 0);
            RemainingPurchaseLine.Validate("Qty. to Invoice", 0);
            RemainingPurchaseLine.Modify(true);
            PurchaseHeader.Find();
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
            PurchaseHeader.Modify(true);
            PurchaseInvoiceHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
            PurchaseInvoiceHeader.CalcFields(Amount);
            PurchaseInvoiceHeader.TestField(Amount, (OrderQuantity - InvoicedQuantity) * PrepaidPurchaseLine."Direct Unit Cost" - ExpectedPrepmtToDeduct);
            PrepaidPurchaseLine.Find();
            PrepaidPurchaseLine.TestField(Quantity, OrderQuantity);
            PrepaidPurchaseLine.TestField("Quantity Received", OrderQuantity);
            PrepaidPurchaseLine.TestField("Quantity Invoiced", OrderQuantity);
            PrepaidPurchaseLine.TestField("Qty. to Receive", 0);
            PrepaidPurchaseLine.TestField("Qty. to Invoice", 0);
            PrepaidPurchaseLine.TestField("Prepmt Amt Deducted", ExpectedPrepmtToDeduct);
            PrepaidPurchaseLine.TestField("Prepmt Amt to Deduct", 0);
            RemainingPurchaseLine.Find();
            RemainingPurchaseLine.TestField("Quantity Received", 0);
            RemainingPurchaseLine.TestField("Quantity Invoiced", 0);
            LibrarySetupStorage.Restore();
            exit;
        end;

        // [THEN] The released prepayment can be credited from the original order.
        PurchaseHeader.Find();
        PrepaymentCreditMemoNo := LibraryPurchase.PostPurchasePrepaymentCreditMemo(PurchaseHeader);
        PurchaseCrMemoHeader.Get(PrepaymentCreditMemoNo);
        PurchaseCrMemoHeader.CalcFields("Amount Including VAT");
        PurchaseCrMemoHeader.TestField("Amount Including VAT", PurchasePrepaymentInvoiceHeader."Amount Including VAT");
        LibrarySetupStorage.Restore();
    end;

    local procedure InitializeInvoiceCancellation(var LibrarySetupStorage: Codeunit "Library - Setup Storage")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Initialize();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasesPayablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Vendor Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure PostPaymentToInvoice(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SetupPrepmtGLAccountPostingGroups(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure SetRestoreOrderQtyOnReturn(RestoreOrderQtyOnReturn: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Restore Order Qty. on Return", RestoreOrderQtyOnReturn);
        PurchasesPayablesSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GetReceiptLinesPageHandler')]
    procedure OrderNoIsPopulatedInPostedPurchInvWhenGetRcptLinesAndPostPIForPOHavingPrePmtInv()
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 566107] "Order No." is populated in Posted Purchase Invoice from Purchase Order,
        // which is having a Prepayment Invoice and a Posted Purchase Receipt, and the Purchase
        // Invoice is created and posted using Get Receipt Lines action.
        Initialize();

        // [GIVEN] Create a GL Account with Prepayment Posting Setup.
        PreparePrepaymentsPostingSetup(GLAccount);

        // [GIVEN] Create an Item with GL Account.
        PrepareItemAccordingToSetup(Item, GLAccount);

        // [GIVEN] Create a Vendor with GL Account.
        PrepareVendorAccordingToSetup(Vendor, GLAccount, LibraryRandom.RandIntInRange(20, 20));

        // [GIVEN] Create Purchase Header [1].
        LibraryPurchase.CreatePurchHeader(PurchaseHeader[1], PurchaseHeader[1]."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create Purchase Line [1] and Validate "Direct Unit Cost".
        LibraryPurchase.CreatePurchaseLine(PurchaseLine[1], PurchaseHeader[1], PurchaseLine[1].Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 10));
        PurchaseLine[1].Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine[1].Modify(true);

        // [GIVEN] Validate "Doc. Amount Incl. VAT" in Purchase Header [1].
        PurchaseHeader[1].Validate("Doc. Amount Incl. VAT", PurchaseLine[1]."Amount Including VAT");
        PurchaseHeader[1].Modify(true);

        // [GIVEN] Post Purchase Prepayment Invoice.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader[1]);

        // [GIVEN] Post Purchase Receipt.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);

        // [GIVEN] Create Purchase Header [2].
        LibraryPurchase.CreatePurchHeader(PurchaseHeader[2], PurchaseHeader[2]."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Open Purchase Invoice page and run Get Receipt Lines action.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GoToRecord(PurchaseHeader[2]);
        LibraryVariableStorage.Enqueue(Format(PurchaseHeader[1]."Buy-from Vendor No."));
        PurchaseInvoice.PurchLines.GetReceiptLines.Invoke();

        // [GIVEN] Find Purchase Header [2] and Validate "Doc. Amount Incl. VAT".
        PurchaseHeader[2].Get(PurchaseHeader[2]."Document Type"::Invoice, PurchaseHeader[2]."No.");
        PurchaseHeader[2].Validate("Doc. Amount Incl. VAT", PurchaseLine[1]."Amount Including VAT");
        PurchaseHeader[2].Modify(true);

        // [GIVEN] Post Purchase Header [2].
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], false, true);

        // [WHEN] Find Purch. Rcpt. Header.
        PurchRcptHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchRcptHeader.FindFirst();

        // [THEN] "Order No." in Purch. Rcpt. Header is equal to "No." of Purchase Header [1].
        Assert.AreEqual(PurchaseHeader[1]."No.", PurchRcptHeader."Order No.", '');

        // [WHEN] Find Purch. Rcpt. Line.
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchRcptLine.FindLast();

        // [THEN] "Order No." in Purch. Rcpt. Line is equal to "No." of Purchase Header [1].
        Assert.AreEqual(PurchaseHeader[1]."No.", PurchRcptLine."Order No.", '');

        // [THEN] "Order Line No." in Purch. Rcpt. Line is equal to "Line No." of Purchase Line [1].
        Assert.AreEqual(PurchaseLine[1]."Line No.", PurchRcptLine."Order Line No.", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PaymentReferenceTransferredToVLEOnPurchasePrepaymentInvoice()
    var
        GLAccount: Record "G/L Account";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 643383] Payment Reference from the Purchase Order is transferred to the Vendor Ledger Entry when posting a prepayment invoice.
        Initialize();

        // [GIVEN] Prepayment posting setup, an item and a vendor with a prepayment %.
        PreparePrepaymentsPostingSetup(GLAccount);
        PrepareItemAccordingToSetup(Item, GLAccount);
        PrepareVendorAccordingToSetup(Vendor, GLAccount, LibraryRandom.RandInt(100));

        // [GIVEN] A Purchase Order with a Payment Reference specified.
        CreatePurchOrder(PurchaseHeader, Vendor, Item, LCYCode);

        PurchaseHeader."Payment Reference" := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Payment Reference"), Database::"Purchase Header");
        PurchaseHeader.Modify(true);

        // [WHEN] Post the prepayment invoice via Purchase order page.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GoToRecord(PurchaseHeader);
        PurchaseOrder.PostPrepaymentInvoice.Invoke();
        Commit();
        PurchaseOrder.Close();

        // [THEN] The Vendor Ledger Entry created for the prepayment carries the Payment Reference from the Purchase Order.
        CheckNumOfVendorLedgerEntries(VendorLedgerEntry, Vendor, 1);
        VendorLedgerEntry.FindFirst();

        // [THEN] The Payment Reference from the Purchase Header should be transferred to the Vendor Ledger Entry table.
        Assert.AreEqual(
            PurchaseHeader."Payment Reference", VendorLedgerEntry."Payment Reference",
            StrSubstNo(
                PaymentReferenceNotTransferredErr, PurchaseHeader.FieldCaption("Payment Reference"), VendorLedgerEntry.TableCaption()));
    end;

    local procedure PreparePrepaymentsPostingSetup(var GLAccount: Record "G/L Account")
    var
        PrepmtGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreatePrepaymentVATSetup(
          GLAccount, PrepmtGLAccount, GLAccount."Gen. Posting Type"::Purchase,
          "Tax Calculation Type"::"Normal VAT", "Tax Calculation Type"::"Normal VAT");
    end;

    local procedure PrepareItemAccordingToSetup(var Item: Record Item; GLAccount: Record "G/L Account")
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // Create an Item that uses this setup (finding was not possible in all cases).
        InventoryPostingGroup.FindFirst();

        Item.Init();
        Item.Insert(true);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, LibraryRandom.RandInt(0));

        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Modify(true);
    end;

    local procedure PrepareVendorAccordingToSetup(var Vendor: Record Vendor; GLAccount: Record "G/L Account"; PrepaymentPercentage: Integer)
    begin
        // Create a vendor with prepayment discount according to the GL Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Vendor.Validate("Prepayment %", PrepaymentPercentage);
        Vendor.Modify();
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; Item: Record Item; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create a purchase order for the vendor with the Item
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineWithPrepmtAmts(var PurchaseHeader: Record "Purchase Header"; PrepmtLineAmount: Decimal; PrepmtAmtInv: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandInt(10));
        PurchaseLine."Prepmt. Line Amount" := PrepmtLineAmount;
        PurchaseLine."Prepmt. Amt. Inv." := PrepmtAmtInv;
        PurchaseLine.Modify();
    end;

    local procedure CheckNumOfVendorLedgerEntries(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Vendor: Record Vendor; NumExpectedLedgerEntries: Integer)
    begin
        VendorLedgerEntry.SetFilter("Vendor No.", Vendor."No.");
        Assert.AreEqual(NumExpectedLedgerEntries, VendorLedgerEntry.Count,
          StrSubstNo('Expected to find exactly %1 Vendor ledger entry.', NumExpectedLedgerEntries));
    end;

    local procedure ForceAmountRecalculation(var PurchaseHeader: Record "Purchase Header")
    begin
        // Release the PO, required to update amount fields in the purchase lines.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        // After that Amount including VAT can be properly recalculated
        PurchaseHeader.CalcFields("Amount Including VAT");
    end;

    local procedure CalculatePrepaymentAmount(PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[20]) PrepaymentAmount: Decimal
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(CurrencyCode);

        PrepaymentAmount := Round(PurchaseHeader."Amount Including VAT" * PurchaseHeader."Prepayment %" / 100,
            Currency."Invoice Rounding Precision", '=');
    end;

    local procedure ValidateVendorLedgerEntries(VendorLedgerEntry: Record "Vendor Ledger Entry"; ExpectedPrepaymentAmount: Decimal; CurrencyCode: Code[20])
    begin
        VendorLedgerEntry.CalcFields(Amount);
        Assert.AreEqual(ExpectedPrepaymentAmount, VendorLedgerEntry.Amount, 'Posted prepayment amount is not the expected one');
        Assert.AreEqual(CurrencyCode, VendorLedgerEntry."Currency Code", 'Currency in posted vendor ledger entry is not the expected one');
    end;

    local procedure FindForeignCurrency(var Currency: Record Currency)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        GeneralLedgerSetup.Get();
        Currency.SetFilter(Code, '<>%1', GeneralLedgerSetup."LCY Code");
        LibraryERM.FindCurrency(Currency);

        // Find if a valid exchange rate exists for the currency
        CurrencyExchangeRate.SetFilter("Currency Code", Currency.Code);
        CurrencyExchangeRate.SetFilter("Starting Date", '<=%1', WorkDate());
        if CurrencyExchangeRate.Count = 0 then
            // Create exchange rate so we're sure there's one
            LibraryERM.CreateRandomExchangeRate(Currency.Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.Filter.SetFilter("Buy-from Vendor No.", LibraryVariableStorage.DequeueText());
        GetReceiptLines.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

