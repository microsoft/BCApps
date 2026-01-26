codeunit 144122 "ERM Purchase VAT EC Calculate"
{
    // // [FEATURE] [Purchase] [VAT] [EC]
    // Test for feature VAT EC Calculate.
    //  1. Verify VAT Amount calculated correctly without Currency and Reverse charge VAT for posting General Journal.
    //  2. Verify VAT Amount calculated correctly with Currency and Reverse charge VAT for posting General Journal.
    //  3. Verify VAT Amount calculated correctly without Currency and Normal VAT for posting General Journal.
    //  4. Verify VAT Amount calculated correctly with Currency and Normal VAT for posting General Journal.
    //  5. Verify VAT Amount calculated correctly with Currency and Normal VAT when Purchase Credit Memo Created.
    //  6. Verify VAT Amount calculated correctly with Currency and Reverse charge VAT when Purchase Credit Memo Created.
    //  7. Verify VAT Amount calculated correctly without Currency and Normal VAT when Purchase Credit Memo Created.
    //  8. Verify VAT Amount calculated correctly without Currency and Reverse charge VAT when Purchase Credit Memo Created.
    //  9. Verify VAT Amount calculated correctly with Currency and Normal VAT when Purchase Credit Memo Posted.
    // 10. Verify VAT Amount calculated correctly with Currency and Reverse charge VAT when Purchase Credit Memo Posted.
    // 11. Verify VAT Amount calculated correctly without Currency and Normal VAT when Purchase Credit Memo Posted.
    // 12. Verify VAT Amount calculated correctly without Currency and Reverse charge VAT when Purchase Credit Memo Posted.
    // 13. Verify VAT Amount Line after posting Purchase Order.
    // 14. Verify VAT Amount Line after posting Purchase Credit Memo.
    // 15. Verify G/L Entry and VAT Entry Amount after posting Purchase Return Order.
    // 16. Verify G/L Entry and VAT Entry Amount after posting Purchase Order.
    // 17. Test to verify that VAT Amount gets successfully updated on Purchase Invoice Statistics - First Line.
    // 18. Test to verify that VAT Amount gets successfully updated on Purchase Invoice Statistics - Second Line.
    // 19. Test to verify the correct G/L and VAT entries when Purchase Invoice created when Unrealized VAT is true.
    // 20. Test to verify the correct G/L and VAT entries when payment is applied to created invoice when Unrealized VAT is true.
    //
    // Covers Test Cases for WI - 352246.
    // ------------------------------------------------------------------------------------------
    // Test Function Name                                                                  TFS ID
    // ------------------------------------------------------------------------------------------
    // GeneralJournalReverseChargeVATWithoutCurrency                                      158905
    // GeneralJournalReverseChargeVATWithCurrency                                         158906
    // GeneralJournalNormalVATWithoutCurrency                                             158907
    // GeneralJournalNormalVATWithCurrency                                                158908
    // PurchCrMemoNormalVATWithCurrency                                                   282942
    // PurchCrMemoReverseChargeVATWithCurrency                                            282944
    // PurchCrMemoNormalVATWithoutCurrency                                                282943
    // PurchCrMemoReverseChargeVATWithoutCurrency                                         282945
    // PostedPurchCrMemoNormalVATWithCurrency                                             282942
    // PostedPurchCrMemoReverseChargeVATWithCurrency                                      282944
    // PostedPurchCrMemoNormalVATWithoutCurrency                                          282943
    // PostedPurchCrMemoReverseChargeVATWithoutCurrency                                   282945
    //
    // Covers Test Cases for WI - 352245.
    // ------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------
    // VATAmountOnPurchaseOrder                                                           219964
    // VATAmountOnPurchaseCreditMemo                                                      219963
    // PostedPurchaseReturnOrderVATAmount                                                 217455
    // PostedPurchaseOrderVATAmount                                                       217454
    //
    // Covers Test Cases for WI - 352352.
    // ------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------
    // PurchaseInvoiceStatisticsFirstVATLine                                              157296
    // PurchaseInvoiceStatisticsSecondVATLine                                             157297
    // PurchaseInvoiceUnrealizedVAT, PurchaseInvoicePaymentUnrealizedVAT                  283280

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        ValueMustBeSameMsg: Label 'Value must be same.';
        TotalFromSevPrepmtAmtErr: Label 'Total amount from several prepayments must be equal to original document amount';

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalReverseChargeVATWithoutCurrency()
    begin
        // Verify VAT Amount calculated correctly without Currency and Reverse charge VAT for posting General Journal.

        // Setup.
        Initialize();
        GeneralJournalReverseChargeVAT('');  // Currency - blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalReverseChargeVATWithCurrency()
    begin
        // Verify VAT Amount calculated correctly with Currency and Reverse charge VAT for posting General Journal.

        // Setup.
        Initialize();
        GeneralJournalReverseChargeVAT(CreateCurrencyAndExchangeRate());
    end;

    local procedure GeneralJournalReverseChargeVAT(CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldAdditionalReportingCurrency: Code[10];
        CurrencyFactor: Decimal;
        VATAmount: Decimal;
    begin
        // Update General Ledger Setup Additional Reporting Currency.
        OldAdditionalReportingCurrency := UpdateGeneralLedgerSetupAdditionalReportingCurrency(CurrencyCode);
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // Exercise: Create and Post General Journal Line with Reverse Charge VAT.
        CreateAndPostGeneralJournalLine(
              GenJournalLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CurrencyCode);

        // Verify: Verify General Ledger Entry - Debit Amount, VAT Amount and VAT Entry - Amount and Additional-Currency Amount.
        VATAmount := -GenJournalLine."VAT Base Amount" * VATPostingSetup."VAT+EC %" / 100;
        CurrencyFactor := FindCurrencyFactor(CurrencyCode, GenJournalLine."Currency Factor");
        VerifyGLEntryAmountAndVATAmount(
          GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", -GenJournalLine."Amount (LCY)", 0, VATAmount / CurrencyFactor);  // Credit Amount - 0.
        VerifyVATEntryAmountAndAdditionalCurrencyAmount(
              GenJournalLine."Document Type"::Invoice, GenJournalLine."Account No.", Round(VATAmount) / CurrencyFactor,
              FindAdditionalCurrencyAmount(CurrencyCode, Round(VATAmount)));

        // TearDown.
        UpdateGeneralLedgerSetupAdditionalReportingCurrency(OldAdditionalReportingCurrency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalNormalVATWithoutCurrency()
    begin
        // Verify VAT Amount calculated correctly without Currency and Normal VAT for posting General Journal.

        // Setup.
        Initialize();
        GeneralJournalNormalVAT('');  // Currency - blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalNormalVATWithCurrency()
    begin
        // Verify VAT Amount calculated correctly with Currency and Normal VAT for posting General Journal.

        // Setup.
        Initialize();
        GeneralJournalNormalVAT(CreateCurrencyAndExchangeRate());
    end;

    local procedure GeneralJournalNormalVAT(CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldAdditionalReportingCurrency: Code[10];
        CurrencyFactor: Decimal;
        VATAmount: Decimal;
    begin
        // Update General Ledger Setup Additional Reporting Currency and Create General Journal.
        OldAdditionalReportingCurrency := UpdateGeneralLedgerSetupAdditionalReportingCurrency(CurrencyCode);
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Exercise: Create and Post General Journal Line with Normal VAT.
        CreateAndPostGeneralJournalLine(
              GenJournalLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CurrencyCode);

        // Verify: Verify General Ledger Entry - Debit Amount, VAT Amount and VAT Entry - Amount and Additional-Currency Amount.
        VATAmount := GenJournalLine."Bal. VAT Base Amount" * VATPostingSetup."VAT+EC %" / 100;
        CurrencyFactor := FindCurrencyFactor(CurrencyCode, GenJournalLine."Currency Factor");
        VerifyGLEntryAmountAndVATAmount(
          GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", GenJournalLine."Bal. VAT Base Amount" / CurrencyFactor, 0,
          VATAmount / CurrencyFactor);  // Credit Amount - 0.
        VerifyVATEntryAmountAndAdditionalCurrencyAmount(
              GenJournalLine."Document Type"::Invoice, GenJournalLine."Account No.", Round(VATAmount) / CurrencyFactor,
              FindAdditionalCurrencyAmount(CurrencyCode, Round(VATAmount)));

        // TearDown.
        UpdateGeneralLedgerSetupAdditionalReportingCurrency(OldAdditionalReportingCurrency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoNormalVATWithCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify VAT Amount calculated correctly with Currency and Normal VAT when Purchase Credit Memo Created.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Normal VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PurchCrMemoVATCalculationType(VATPostingSetup, CreateCurrencyAndExchangeRate(), VATPostingSetup."VAT %", VATPostingSetup."EC %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoReverseChargeVATWithCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify VAT Amount calculated correctly with Currency and Reverse charge VAT when Purchase Credit Memo Created.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Reverse Charge VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        PurchCrMemoVATCalculationType(VATPostingSetup, CreateCurrencyAndExchangeRate(), 0, 0);  // VAT % and EC % - 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoNormalVATWithoutCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify VAT Amount calculated correctly without Currency and Normal VAT when Purchase Credit Memo Created.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Normal VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PurchCrMemoVATCalculationType(VATPostingSetup, '', VATPostingSetup."VAT %", VATPostingSetup."EC %");  // Currency - blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoReverseChargeVATWithoutCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify VAT Amount calculated correctly without Currency and Reverse charge VAT when Purchase Credit Memo Created.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Reverse Charge VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        PurchCrMemoVATCalculationType(VATPostingSetup, '', 0, 0);  // Currency - blank, VAT % and EC % - 0.
    end;

    local procedure PurchCrMemoVATCalculationType(VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; VATPct: Decimal; ECPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        OldAdditionalReportingCurrency: Code[10];
    begin
        // Update General Ledger Setup - Additional Reporting Currency.
        OldAdditionalReportingCurrency := UpdateGeneralLedgerSetupAdditionalReportingCurrency(CurrencyCode);

        // Exercise.
        CreatePurchaseDocument(
              PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", PurchaseLine.Type::"G/L Account",
              CreateGLAccountWithPostingGroup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"),
              VATPostingSetup."VAT Bus. Posting Group", CurrencyCode);

        // Verify: Verify VAT Amount Line - VAT Percentage EC Percentage, Line Amount, VAT Base and VAT Amount.
        VerifyVATAmountLinePurchaseCreditMemo(PurchaseLine."Buy-from Vendor No.", VATPct, ECPct, PurchaseLine.Amount);

        // TearDown.
        UpdateGeneralLedgerSetupAdditionalReportingCurrency(OldAdditionalReportingCurrency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoNormalVATWithCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify VAT Amount calculated correctly with Currency and Normal VAT when Purchase Credit Memo Posted.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Normal VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PostedPurchCrMemoVATCalculationType(
          VATPostingSetup, CreateCurrencyAndExchangeRate(), VATPostingSetup."VAT %", VATPostingSetup."EC %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoReverseChargeVATWithCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify VAT Amount calculated correctly with Currency and Reverse charge VAT when Purchase Credit Memo Posted.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Reverse Charge VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        PostedPurchCrMemoVATCalculationType(VATPostingSetup, CreateCurrencyAndExchangeRate(), 0, 0);  // VAT % and EC % - 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoNormalVATWithoutCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify VAT Amount calculated correctly without Currency and Normal VAT when Purchase Credit Memo Posted.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Normal VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        PostedPurchCrMemoVATCalculationType(VATPostingSetup, '', VATPostingSetup."VAT %", VATPostingSetup."EC %");  // Currency - blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoReverseChargeVATWithoutCurrency()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify VAT Amount calculated correctly without Currency and Reverse charge VAT when Purchase Credit Memo Posted.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Reverse Charge VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        PostedPurchCrMemoVATCalculationType(VATPostingSetup, '', 0, 0);  // Currency - blank, VAT % and EC % - 0.
    end;

    local procedure PostedPurchCrMemoVATCalculationType(VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; VATPct: Decimal; ECPct: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OldAdditionalReportingCurrency: Code[10];
        VATAmount: Decimal;
        CurrencyFactor: Decimal;
        OldCalcInvDiscount: Boolean;
        OldInvoiceRounding: Boolean;
        PostedDocumentNo: Code[20];
    begin
        // Update General Ledger Setup - Additional Reporting Currency and Purchases Payables Setup - Invoice Rounding. Create Purchase Credit Memo.
        OldAdditionalReportingCurrency := UpdateGeneralLedgerSetupAdditionalReportingCurrency(CurrencyCode);
        OldInvoiceRounding := UpdatePurchasesPayablesSetupInvRoundingAndDiscount(OldCalcInvDiscount, false, false);  // Calculate Invoice Discount and Invoice Rounding - False.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine.Type::"G/L Account",
          CreateGLAccountWithPostingGroup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", CurrencyCode);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CurrencyFactor := FindCurrencyFactor(CurrencyCode, PurchaseHeader."Currency Factor");
        VATAmount := -PurchaseLine.Amount / CurrencyFactor * VATPostingSetup."VAT+EC %" / 100;

        // Exercise.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Amount Line - VAT Percentage EC Percentage, Line Amount, VAT Base and VAT Amount and G/L Entry - Amount And VAT Amount.
        VerifyVATAmountLinePostedPurchaseCreditMemo(PurchaseHeader."Buy-from Vendor No.", VATPct, ECPct, PurchaseLine.Amount);
        VerifyGLEntryAmountAndVATAmount(PostedDocumentNo, PurchaseLine."No.", 0, PurchaseLine.Amount / CurrencyFactor, VATAmount);  // Debit Amount - 0.

        // TearDown.
        UpdateGeneralLedgerSetupAdditionalReportingCurrency(OldAdditionalReportingCurrency);
        UpdatePurchasesPayablesSetupInvRoundingAndDiscount(OldCalcInvDiscount, OldCalcInvDiscount, OldInvoiceRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
    begin
        // Verify VAT Amount Line after posting Purchase Order.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Normal VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Exercise: Create and post Purchase Order with multiple Purchase Line.
        Amount :=
          CreateAndPostPurchaseDocumentWithMultipleLines(
            PurchaseLine, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item,
            LibraryInventory.CreateItem(Item), VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // Verify: Verify VAT Amount Line after posting Purchase Order.
        VerifyVATAmountLinePostedPurchaseInvoice(
          PurchaseLine."Buy-from Vendor No.", VATPostingSetup."VAT %", VATPostingSetup."EC %", PurchaseLine.Amount + Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPurchaseCreditMemo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
    begin
        // Verify VAT Amount Line after posting Purchase Credit Memo.

        // Setup: Update VAT Posting Setup VAT Calculation Type - Normal VAT.
        Initialize();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Exercise: Create and post Purchase Credit Memo with multiple Purchase Line.
        Amount :=
          CreateAndPostPurchaseDocumentWithMultipleLines(
            PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine.Type::Item,
            LibraryInventory.CreateItem(Item), VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // Verify: Verify VAT Amount Line after posting Purchase Credit Memo.
        VerifyVATAmountLinePostedPurchaseCreditMemo(
          PurchaseLine."Buy-from Vendor No.", VATPostingSetup."VAT %", VATPostingSetup."EC %", PurchaseLine.Amount + Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseReturnOrderVATAmount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        OldCalcInvDiscount: Boolean;
        OldInvoiceRounding: Boolean;
        VATAmount: Decimal;
    begin
        // Verify G/L Entry and VAT Entry Amount after posting Purchase Return Order.

        // Setup: Update Purchases Payables Setup, VAT Posting Setup VAT Calculation Type - Normal VAT. Create Purchase Return Order with Line Discount.
        Initialize();
        OldInvoiceRounding := UpdatePurchasesPayablesSetupInvRoundingAndDiscount(OldCalcInvDiscount, false, false);  // Calculate Invoice Discount and Invoice Rounding - False.
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::"Return Order", PurchaseLine.Type::Item,
          LibraryInventory.CreateItem(Item), VATPostingSetup."VAT Bus. Posting Group", '');  // Currency - blank.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        VATAmount := -PurchaseLine.Amount * VATPostingSetup."VAT+EC %" / 100;

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify G/L Entry Amount And VAT Amount after posting Purchase Return Order.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntryAmountAndVATAmount(DocumentNo, GeneralPostingSetup."Purch. Account", 0, PurchaseLine.Amount, VATAmount);  // Debit Amount - 0.

        // Tear Down.
        UpdatePurchasesPayablesSetupInvRoundingAndDiscount(OldCalcInvDiscount, OldCalcInvDiscount, OldInvoiceRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseOrderVATAmount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        OldPostLineDiscount: Boolean;
        OldInvoiceRounding: Boolean;
        VATAmount: Decimal;
    begin
        // Verify G/L Entry and VAT Entry Amount after posting Purchase Order.

        // Setup: Update Purchases Payables Setup, VAT Posting Setup VAT Calculation Type - Normal VAT. Create Purchase Order with Line Discount.
        Initialize();
        OldInvoiceRounding := UpdatePurchasesPayablesSetupInvRoundingAndDiscount(OldPostLineDiscount, false, false);  // Calculate Invoice Discount and Invoice Rounding - False.
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item,
          LibraryInventory.CreateItem(Item), VATPostingSetup."VAT Bus. Posting Group", '');  // Currency - blank.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        VATAmount := PurchaseLine.Amount * VATPostingSetup."VAT+EC %" / 100;

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify G/L Entry Amount And VAT Amount after posting Purchase Order.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntryAmountAndVATAmount(DocumentNo, GeneralPostingSetup."Purch. Account", PurchaseLine.Amount, 0, VATAmount);  // Credit Amount - 0.

        // Tear Down.
        UpdatePurchasesPayablesSetupInvRoundingAndDiscount(OldPostLineDiscount, OldPostLineDiscount, OldInvoiceRounding);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsFirstVATLine()
    var
        LineNumber: Option First,Second;
    begin
        // Test to verify that VAT Amount gets successfully updated on Purchase Invoice Statistics - First Line.

        PurchaseInvoiceStatisticsVATLine(LineNumber::First);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsSecondVATLine()
    var
        LineNumber: Option First,Second;
    begin
        // Test to verify that VAT Amount gets successfully updated on Purchase Invoice Statistics - Second Line.

        PurchaseInvoiceStatisticsVATLine(LineNumber::Second);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceStatisticsFirstVATLine()
    var
        LineNumber: Option First,Second;
    begin
        // Test to verify that VAT Amount gets successfully updated on Purchase Invoice Statistics - First Line.

        PurchInvoiceStatisticsVATLine(LineNumber::First);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceStatisticsSecondVATLine()
    var
        LineNumber: Option First,Second;
    begin
        // Test to verify that VAT Amount gets successfully updated on Purchase Invoice Statistics - Second Line.

        PurchInvoiceStatisticsVATLine(LineNumber::Second);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure PurchaseInvoiceStatisticsVATLine(PurchaseLineNumber: Option)
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATAmount: Variant;
        OldAllowVATDifference: Boolean;
        OldVATDifferenceAllowed: Decimal;
        MaxVATDifferenceAllowed: Decimal;
        VATPct: Decimal;
        PurchaseStatisticsOption: Option Update,Verify;
    begin
        // Setup: PurchasesPayables Setup - Allow VAT Difference and General Ledger - Max. VAT Difference Allowed, Create Purchase Invoice with multiple lines having different VAT Prod. Posting Group.
        Initialize();
        OldAllowVATDifference := UpdatePurchasesPayablesSetupAllowVATDifference(true);  // TRUE for Allow VAT Difference.
        MaxVATDifferenceAllowed := LibraryRandom.RandDec(0, 1);
        OldVATDifferenceAllowed := UpdateGeneralLedgerSetupMaxVATDifferenceAllowed(MaxVATDifferenceAllowed);  // Using Random value for Max. VAT Difference Allowed.
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        FindVATPostingSetup(VATPostingSetup2, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchaseLine.Type::"G/L Account",
          CreateGLAccountWithPostingGroup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", '');  // Blank Currency.
        CreatePurchaseLine(
          PurchaseLine, PurchaseLine."Document Type", PurchaseLine."Document No.", VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group");
        VATPct := FindVATPostingSetupVATPct(PurchaseLineNumber, VATPostingSetup."VAT %", VATPostingSetup2."VAT %");

        // Exercise: Update VAT Amount on Purchase Statistics page in handler - PurchaseStatisticsModalPageHandler.
        OpenPurchaseInvoiceStatisticsPage(PurchaseStatisticsOption::Update, MaxVATDifferenceAllowed, VATPct, PurchaseLine."Document No.");

        // Verify: Verify the updated VAT Amount in handler - PurchaseStatisticsModalPageHandler.
        LibraryVariableStorage.Dequeue(VATAmount);
        OpenPurchaseInvoiceStatisticsPage(PurchaseStatisticsOption::Verify, VATAmount, VATPct, PurchaseLine."Document No.");

        // Tear Down.
        UpdateGeneralLedgerSetupMaxVATDifferenceAllowed(OldVATDifferenceAllowed);
        UpdatePurchasesPayablesSetupAllowVATDifference(OldAllowVATDifference);
    end;
#endif

    local procedure PurchInvoiceStatisticsVATLine(PurchaseLineNumber: Option)
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATAmount: Variant;
        OldAllowVATDifference: Boolean;
        OldVATDifferenceAllowed: Decimal;
        MaxVATDifferenceAllowed: Decimal;
        VATPct: Decimal;
        PurchaseStatisticsOption: Option Update,Verify;
    begin
        // Setup: PurchasesPayables Setup - Allow VAT Difference and General Ledger - Max. VAT Difference Allowed, Create Purchase Invoice with multiple lines having different VAT Prod. Posting Group.
        Initialize();
        OldAllowVATDifference := UpdatePurchasesPayablesSetupAllowVATDifference(true);  // TRUE for Allow VAT Difference.
        MaxVATDifferenceAllowed := LibraryRandom.RandDec(0, 1);
        OldVATDifferenceAllowed := UpdateGeneralLedgerSetupMaxVATDifferenceAllowed(MaxVATDifferenceAllowed);  // Using Random value for Max. VAT Difference Allowed.
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        FindVATPostingSetup(VATPostingSetup2, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, PurchaseLine.Type::"G/L Account",
          CreateGLAccountWithPostingGroup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", '');  // Blank Currency.
        CreatePurchaseLine(
          PurchaseLine, PurchaseLine."Document Type", PurchaseLine."Document No.", VATPostingSetup2."VAT Bus. Posting Group",
          VATPostingSetup2."VAT Prod. Posting Group");
        VATPct := FindVATPostingSetupVATPct(PurchaseLineNumber, VATPostingSetup."VAT %", VATPostingSetup2."VAT %");

        // Exercise: Update VAT Amount on Purchase Statistics page in handler - PurchaseStatisticsPageHandler.
        OpenPurchInvoiceStatisticsPage(PurchaseStatisticsOption::Update, MaxVATDifferenceAllowed, VATPct, PurchaseLine."Document No.");

        // Verify: Verify the updated VAT Amount in handler - PurchaseStatisticsPageHandler.
        LibraryVariableStorage.Dequeue(VATAmount);
        OpenPurchInvoiceStatisticsPage(PurchaseStatisticsOption::Verify, VATAmount, VATPct, PurchaseLine."Document No.");

        // Tear Down.
        UpdateGeneralLedgerSetupMaxVATDifferenceAllowed(OldVATDifferenceAllowed);
        UpdatePurchasesPayablesSetupAllowVATDifference(OldAllowVATDifference);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceUnrealizedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
        VATAmount: Decimal;
    begin
        // Test to verify the correct G/L and VAT entries when Purchase Invoice created with Unrealized VAT is true.

        // Setup: Update General ledger setup - Unrealized VAT and VAT Posting Setup - Purch. VAT Unreal. Account.
        Initialize();
        OldUnrealizedVAT := UpdateGeneralLedgerSetupUnrealizedVAT(true);  // Unrealized VAT - True.
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetupPurchVATUnrealAccount(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage,
          CreateGLAccountWithPostingGroup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));

        // Exercise: Create and Post General Journal Line.
        CreateAndPostGeneralJournalLine(
          GenJournalLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '');  // Currency - blank.

        // Verify: Verify General Ledger Entry - Debit Amount, VAT Amount and VAT Entry - Amount and Additional-Currency Amount.
        VATAmount := GenJournalLine."Bal. VAT Base Amount" * VATPostingSetup."VAT+EC %" / 100;
        VerifyGLEntryAmountAndVATAmount(
          GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", GenJournalLine."Bal. VAT Base Amount", 0, VATAmount);  // Credit Amount - 0.
        VerifyVATEntryAmountAndAdditionalCurrencyAmount(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account No.", 0, 0);  // VAT Amount and Additional Currency Amount - 0.

        // Tear Down.
        UpdateVATPostingSetupPurchVATUnrealAccount(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ", VATPostingSetup."Purch. VAT Unreal. Account");
        UpdateGeneralLedgerSetupUnrealizedVAT(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePaymentUnrealizedVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldUnrealizedVAT: Boolean;
        VATAmount: Decimal;
    begin
        // Test to verify the correct G/L and VAT entries when payment is applied to created invoice when Unrealized VAT is true.

        // Setup: Update General ledger setup - Unrealized VAT and VAT Posting Setup - Purch. VAT Unreal. Account. Create and Post General Journal Line Document Type - Invoice.
        Initialize();
        OldUnrealizedVAT := UpdateGeneralLedgerSetupUnrealizedVAT(true);  // Unrealized VAT - True.
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetupPurchVATUnrealAccount(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage,
          CreateGLAccountWithPostingGroup(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
        CreateAndPostGeneralJournalLine(
          GenJournalLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '');  // Currency - blank.

        // Exercise: Create and Post General Journal Line Document Type - Payment.
        CreateAndPostGeneralJournalLineAppliesToDocNo(GenJournalLine, GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");

        // Verify: Verify General Ledger Entry - Credit Amount, VAT Amount and VAT Entry - Amount and Additional-Currency Amount.
        VATAmount := GenJournalLine."Bal. VAT Base Amount" * VATPostingSetup."VAT+EC %" / 100;
        VerifyGLEntryAmountAndVATAmount(
          GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", 0, -GenJournalLine."Bal. VAT Base Amount", VATAmount);  // Debit Amount - 0.
        VerifyVATEntryAmountAndAdditionalCurrencyAmount(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", VATAmount, 0);  // Additional Currency Amount - 0.

        // Tear Down.
        UpdateVATPostingSetupPurchVATUnrealAccount(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::" ", VATPostingSetup."Purch. VAT Unreal. Account");
        UpdateGeneralLedgerSetupUnrealizedVAT(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnePurchDocWithSeveralPrepaymentsGiving100Pct()
    var
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        DocAmount: Decimal;
        PrepmtInvoicesCnt: Integer;
        i: Integer;
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 123180] Several prepayments from one purchase document gives full document amount
        Initialize();

        // [GIVEN] Purchase document with 50% prepayment
        PrepmtInvoicesCnt := LibraryRandom.RandIntInRange(3, 5);
        DocAmount := CreatePurchaseDocWithPostingSetup(PurchaseHeader);

        // [GIVEN] Post first prepayment invoice
        for i := 1 to PrepmtInvoicesCnt - 1 do begin
            UpdatePurchaseDocPrepaymentPct(
              PurchaseHeader, PurchaseHeader."Prepayment %" + LibraryRandom.RandIntInRange(10, 20));
            PostPurchasePrepaymentInvoice(PurchaseHeader);
            ReleasePurchaseDocument.Reopen(PurchaseHeader);
        end;

        // [GIVEN] Modify purchase document prepayment to 100%
        UpdatePurchaseDocPrepaymentPct(PurchaseHeader, 100);

        // [WHEN] Post second prepayment invoice
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Total amount from two posted prepayment invoices = document amount
        Assert.AreEqual(
          DocAmount,
          GetPrepaymentInvoicesAmt(PurchaseHeader."Buy-from Vendor No."),
          TotalFromSevPrepmtAmtErr);
    end;

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestRPH')]
    [Scope('OnPrem')]
    procedure ECAmountOnPurchasePrepmtDocTestReportForSecondPrepayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        FirstPrepmtPct: Decimal;
        ExpectedECAmount: Decimal;
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 123350] "Purchase Prepmt. Doc. - Test" EC Amount = prepayment EC amount for second prepayment
        Initialize();

        // [GIVEN] Purchase document with Amount = "A", Prepayment % = "P", "EC %" = "E"
        CreatePurchaseDocWithPostingSetup(PurchaseHeader);
        UpdatePurchaseDocPrepaymentPct(PurchaseHeader, LibraryRandom.RandIntInRange(10, 90));
        FirstPrepmtPct := PurchaseHeader."Prepayment %";

        // [GIVEN] Post prepayment invoice
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Modify purchase document prepayment to 100%
        ReleasePurchaseDocument.Reopen(PurchaseHeader);
        UpdatePurchaseDocPrepaymentPct(PurchaseHeader, 100);

        // [WHEN] Run "Purchase Prepmt. Doc. - Test" report
        RunPurchasePrepmtDocTestReport(PurchaseHeader."No.");

        // [THEN] "EC Amount" = "A" * (100 - "P") * "E"
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        ExpectedECAmount := Round(PurchaseLine."VAT Base Amount" * (100 - FirstPrepmtPct) * PurchaseLine."EC %" / 10000);
        VerifyPurchPrepmtDocTestReportECAmount(ExpectedECAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryGLEntryAmountsOnPostedPurchaseInvoicePriceInclVAT()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: Code[20];
        DocumentNo: Code[20];
        PurchasePrice: Decimal;
    begin
        // [SCENARIO 363582] Purchase Document Posting with EC % and Prices Incl. VAT = TRUE
        Initialize();

        // [GIVEN] VAT Posting Setup with EC % = 4 and VAT % = 18 specified
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup);
        VendorNo :=
          CreateVendorWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Item with Purchase Price = 100
        PurchasePrice := LibraryRandom.RandDec(100, 2);
        ItemNo :=
          CreateItemWithPurchasePrice(
            PurchasePrice, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VendorNo);

        // [GIVEN] Purchase Invoice with Item Quantity = 1, Unit Price = 100, Prices Including VAT = TRUE
        CreatePurchaseDocumentWithPriceInclVAT(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendorNo, PurchaseLine.Type::Item, ItemNo, true, 0);

        // [WHEN] Post Purchase Document
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Account G/L Entry Amount = 100, VAT G/L Entry Amount = 22.
        VerifyGLEntry(
          DocumentNo, GeneralPostingSetup."Purch. Account", PurchasePrice * PurchaseLine.Quantity);
        VerifyGLEntry(
          DocumentNo, VATPostingSetup."Purchase VAT Account",
          PurchasePrice * PurchaseLine.Quantity * (VATPostingSetup."VAT %" + VATPostingSetup."EC %") / 100);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsECModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePriceInclVATECStatistics()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchasePrice: Decimal;
    begin
        // [SCENARIO 363582] Purchase Statistics with EC % and Prices Incl. VAT = TRUE
        Initialize();

        // [GIVEN] VAT Posting Setup with EC % = 4 and VAT % = 18 specified
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup);
        VendorNo :=
          CreateVendorWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Item with Purchase Price = 100
        PurchasePrice := LibraryRandom.RandDec(100, 2);
        ItemNo :=
          CreateItemWithPurchasePrice(
            PurchasePrice, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VendorNo);

        // [GIVEN] Purchase Invoice with Item Quantity = 1, Unit Price = 100, Prices Including VAT = TRUE
        CreatePurchaseDocumentWithPriceInclVAT(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendorNo, PurchaseLine.Type::Item, ItemNo, true, 0);

        // [WHEN] Open Purchase Statistics Page
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] "Line Amount" = 122, "VAT Amount" = 18, "EC Amount" = 4
        LibraryVariableStorage.Enqueue(
          PurchasePrice * PurchaseLine.Quantity * (1 + (VATPostingSetup."VAT %" + VATPostingSetup."EC %") / 100));
        LibraryVariableStorage.Enqueue(
          PurchasePrice * PurchaseLine.Quantity * (VATPostingSetup."VAT %" / 100));
        LibraryVariableStorage.Enqueue(
          PurchasePrice * PurchaseLine.Quantity * (VATPostingSetup."EC %" / 100));

        PurchaseInvoice.Statistics.Invoke();
        PurchaseInvoice.Close();
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatisticsECPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoicePriceInclVATECPageStatistics()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
        ItemNo: Code[20];
        PurchasePrice: Decimal;
    begin
        // [SCENARIO 363582] Purchase Statistics with EC % and Prices Incl. VAT = TRUE
        Initialize();

        // [GIVEN] VAT Posting Setup with EC % = 4 and VAT % = 18 specified
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup);
        VendorNo :=
          CreateVendorWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Item with Purchase Price = 100
        PurchasePrice := LibraryRandom.RandDec(100, 2);
        ItemNo :=
          CreateItemWithPurchasePrice(
            PurchasePrice, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VendorNo);

        // [GIVEN] Purchase Invoice with Item Quantity = 1, Unit Price = 100, Prices Including VAT = TRUE
        CreatePurchaseDocumentWithPriceInclVAT(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendorNo, PurchaseLine.Type::Item, ItemNo, true, 0);

        // [WHEN] Open Purchase Statistics Page
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] "Line Amount" = 122, "VAT Amount" = 18, "EC Amount" = 4
        LibraryVariableStorage.Enqueue(
          PurchasePrice * PurchaseLine.Quantity * (1 + (VATPostingSetup."VAT %" + VATPostingSetup."EC %") / 100));
        LibraryVariableStorage.Enqueue(
          PurchasePrice * PurchaseLine.Quantity * (VATPostingSetup."VAT %" / 100));
        LibraryVariableStorage.Enqueue(
          PurchasePrice * PurchaseLine.Quantity * (VATPostingSetup."EC %" / 100));

        PurchaseInvoice.PurchaseStatistics.Invoke();
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoicePriceInclVATWithPrepayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        PrepmtGLAccNo: Code[20];
    begin
        // [FEATURE] [Prepayment]
        // [SCENARIO 375571] Purchase Document Posting with EC %; Prices Incl. VAT = TRUE and Prepayment
        Initialize();

        // [GIVEN] VAT Posting Setup with EC % = 4 and VAT % = 18 specified
        PrepmtGLAccNo := LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("EC %", LibraryRandom.RandDecInRange(5, 10, 2));
        VATPostingSetup.Modify(true);
        VendorNo := CreateVendorWithPostingGroup(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");

        // [GIVEN] Purchase Order with Prices Including VAT = TRUE, "Amount Including VAT" = 100, Prepayment = 50%
        CreatePurchaseDocumentWithPriceInclVAT(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, VendorNo, PurchaseLine.Type::"G/L Account", LineGLAccount."No.", true, LibraryRandom.RandIntInRange(20, 50));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);

        // [GIVEN] Posted Prepayment Invoice
        PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post Purchase Order
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Account GL Entry Amount = 100
        VerifyGLEntry(DocumentNo, LineGLAccount."No.", PurchaseLine.Amount);
        // [THEN] VAT GL Entry Amount = 22 (= 100 * (18 + 4) / 100)
        VerifyGLEntry(DocumentNo, VATPostingSetup."Purchase VAT Account",
          PurchaseLine.Amount * (VATPostingSetup."VAT %" + VATPostingSetup."EC %") / 100);
        // [THEN] Prepayment GL Entry Amount = -50 (= -100 * 50%)
        VerifyGLEntry(DocumentNo, PrepmtGLAccNo, -PurchaseLine.Amount * PurchaseHeader."Prepayment %" / 100);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("EC %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateGLAccountWithPostingSetup(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; CurrencyCode: Code[10])
    begin
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, CreateVendor(VATBusPostingGroup, CurrencyCode),
          CreateGLAccountWithPostingGroup(VATBusPostingGroup, VATProdPostingGroup), -LibraryRandom.RandDec(10, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGeneralJournalLineAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; BalAccountNo: Code[20]; AppliesToDocNo: Code[20])
    begin
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", BalAccountNo, -GenJournalLine.Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocumentWithMultipleLines(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; No: Code[20]; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseLine, DocumentType, Type, No, VATBusPostingGroup, '');  // Currency - blank.
        CreatePurchaseLine(
          PurchaseLine2, PurchaseLine."Document Type", PurchaseLine."Document No.", VATBusPostingGroup, VATProdPostingGroup);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseLine2.Amount);
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", GLAccount."No.");
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGLAccountWithPostingGroup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItemWithPurchasePrice(UnitCost: Decimal; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VendorNo: Code[20]): Code[20]
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::Vendor, VendorNo, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Starting Date", WorkDate());
        PriceListLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PriceListLine.Validate("Direct Unit Cost", UnitCost);
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocWithPostingSetup(var PurchaseHeader: Record "Purchase Header"): Decimal
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup);
        UpdatePrepmtAccGenPostingSetup(GeneralPostingSetup, VATPostingSetup);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          CreateVendorWithPostingGroup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccountWithPostingSetup(GeneralPostingSetup, VATPostingSetup),
          LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);

        exit(PurchaseLine."Amount Including VAT");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; No: Code[20]; VATBusPostingGroup: Code[20]; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType, CreateVendor(VATBusPostingGroup, CurrencyCode));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));
        UpdatePurchaseLine(PurchaseLine);
    end;

    local procedure CreatePurchaseDocumentWithPriceInclVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineType: Enum "Purchase Line Type"; LineNo: Code[20]; PricesInclVAT: Boolean; PrepmtPct: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchaseHeader.Validate("Prepayment %", PrepmtPct);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, LineNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, DocumentNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccountWithPostingGroup(VATBusPostingGroup, VATProdPostingGroup), LibraryRandom.RandDec(10, 2));
        UpdatePurchaseLine(PurchaseLine);
    end;

    local procedure CreateVendorWithPostingGroup(GenBusPostingGroup: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure PostPurchasePrepaymentInvoice(PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify();
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
    end;

    local procedure FindAdditionalCurrencyAmount(CurrencyCode: Code[10]; AdditionalCurrencyAmount: Decimal): Decimal
    begin
        if CurrencyCode = '' then
            exit(0);
        exit(AdditionalCurrencyAmount);
    end;

    local procedure FindCurrencyFactor(CurrencyCode: Code[10]; CurrencyFactor: Decimal): Decimal
    begin
        if CurrencyCode = '' then
            exit(1);
        exit(CurrencyFactor);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        VATPostingSetup.SetFilter("VAT %", '>%1', 0);
        VATPostingSetup.FindFirst();
    end;

    local procedure FindVATPostingSetupVATPct(PurchaseLineNumber: Option; VATPct: Decimal; VATPct2: Decimal): Decimal
    var
        PurchaseLineNumberOption: Option First,Second;
    begin
        if PurchaseLineNumber = PurchaseLineNumberOption::First then
            exit(VATPct);
        exit(VATPct2);
    end;

    local procedure FindPurchaseCrMemoHeader(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; VendorNo: Code[20])
    begin
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", VendorNo);
        PurchCrMemoHdr.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure GetPrepaymentInvoicesAmt(VendorNo: Code[20]) Result: Decimal
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("Prepayment Invoice", true);
        PurchInvHeader.FindSet();
        repeat
            Result += GetPrepaymentInvoiceAmt(PurchInvHeader."No.");
        until PurchInvHeader.Next() = 0;
    end;

    local procedure GetPrepaymentInvoiceAmt(DocumentNo: Code[20]) Result: Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindSet();
        repeat
            Result += PurchInvLine."Amount Including VAT";
        until PurchInvLine.Next() = 0;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenPurchaseInvoiceStatisticsPage(PurchaseStatisticsOption: Option; MaxVATDifferenceAllowed: Decimal; VATPct: Decimal; No: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        LibraryVariableStorage.Enqueue(PurchaseStatisticsOption);
        LibraryVariableStorage.Enqueue(MaxVATDifferenceAllowed);
        LibraryVariableStorage.Enqueue(VATPct);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
        PurchaseInvoice.Statistics.Invoke();  // Opens PurchaseStatisticsModalPageHandler.
        PurchaseInvoice.Close();
    end;
#endif

    local procedure OpenPurchInvoiceStatisticsPage(PurchaseStatisticsOption: Option; MaxVATDifferenceAllowed: Decimal; VATPct: Decimal; No: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        LibraryVariableStorage.Enqueue(PurchaseStatisticsOption);
        LibraryVariableStorage.Enqueue(MaxVATDifferenceAllowed);
        LibraryVariableStorage.Enqueue(VATPct);
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
        PurchaseInvoice.PurchaseStatistics.Invoke();  // Opens PurchaseStatisticsPageHandler.
        PurchaseInvoice.Close();
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATCalculationType);
        VATPostingSetup.Validate("EC %", LibraryRandom.RandInt(10));
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdatePurchaseDocPrepaymentPct(var PurchaseHeader: Record "Purchase Header"; NewPrepaymentPct: Decimal)
    begin
        PurchaseHeader.Validate("Prepayment %", NewPrepaymentPct);
        PurchaseHeader.Modify();
    end;

    local procedure UpdatePrepmtAccGenPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.UpdateGLAccountWithPostingSetup(
          GLAccount, GLAccount."Gen. Posting Type"::Purchase, GeneralPostingSetup, VATPostingSetup);
        GeneralPostingSetup.Validate("Purch. Prepayments Account", GLAccount."No.");
        GeneralPostingSetup.Modify();
    end;

    local procedure RunPurchasePrepmtDocTestReport(PurchaseHeaderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("No.", PurchaseHeaderNo);
        Commit();
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test", true, false, PurchaseHeader);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
    end;

    local procedure VerifyGLEntryAmountAndVATAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(DebitAmount, GLEntry."Debit Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(CreditAmount, GLEntry."Credit Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(VATAmount, GLEntry."VAT Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(), ValueMustBeSameMsg);
    end;

    local procedure VerifyVATAmountLine(VATAmountLine: Record "VAT Amount Line"; VATPct: Decimal; ECPct: Decimal; Amount: Decimal)
    begin
        VATAmountLine.TestField("VAT %", VATPct);
        VATAmountLine.TestField("EC %", ECPct);
        Assert.AreNearlyEqual(Amount, VATAmountLine."Line Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(Amount, VATAmountLine."VAT Base", LibraryERM.GetInvoiceRoundingPrecisionLCY(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(VATPct / 100 * Amount, VATAmountLine."VAT Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          ValueMustBeSameMsg);
        Assert.AreNearlyEqual(ECPct / 100 * Amount, VATAmountLine."EC Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          ValueMustBeSameMsg);
    end;

    local procedure VerifyVATAmountLinePostedPurchaseCreditMemo(BuyFromVendorNo: Code[20]; VATPct: Decimal; ECPct: Decimal; Amount: Decimal)
    var
        VATAmountLine: Record "VAT Amount Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        FindPurchaseCrMemoHeader(PurchCrMemoHdr, BuyFromVendorNo);
        PurchCrMemoLine.CalcVATAmountLines(PurchCrMemoHdr, VATAmountLine);
        VerifyVATAmountLine(VATAmountLine, VATPct, ECPct, Amount);
    end;

    local procedure VerifyVATAmountLinePurchaseCreditMemo(BuyFromVendorNo: Code[20]; VATPct: Decimal; ECPct: Decimal; Amount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General;
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.FindFirst();
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        VerifyVATAmountLine(VATAmountLine, VATPct, ECPct, Amount);
    end;

    local procedure VerifyVATAmountLinePostedPurchaseInvoice(BuyFromVendorNo: Code[20]; VATPct: Decimal; ECPct: Decimal; Amount: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchInvHeader.FindFirst();
        PurchInvLine.CalcVATAmountLines(PurchInvHeader, VATAmountLine);
        VerifyVATAmountLine(VATAmountLine, VATPct, ECPct, Amount);
    end;

    local procedure VerifyVATEntryAmountAndAdditionalCurrencyAmount(DocumentType: Enum "Gen. Journal Document Type"; BillToPayToNo: Code[20]; VATAmount: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(VATAmount, VATEntry.Amount, LibraryERM.GetInvoiceRoundingPrecisionLCY(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VATEntry."Additional-Currency Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(), ValueMustBeSameMsg);
    end;

    local procedure VerifyPurchPrepmtDocTestReportECAmount(ExpectedECAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('VATAmountLine__EC_Amount__Control1100007', ExpectedECAmount)
    end;

    local procedure UpdateGeneralLedgerSetupAdditionalReportingCurrency(AdditionalReportingCurrency: Code[10]) OldAdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetupInvRoundingAndDiscount(var OldInvoiceRounding: Boolean; CalcInvDiscount: Boolean; InvoiceRounding: Boolean) OldCalcInvDiscount: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldInvoiceRounding := PurchasesPayablesSetup."Invoice Rounding";
        OldCalcInvDiscount := PurchasesPayablesSetup."Calc. Inv. Discount";
        PurchasesPayablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasesPayablesSetupAllowVATDifference(AllowVATDifference: Boolean) OldAllowVATDifference: Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldAllowVATDifference := PurchasesPayablesSetup."Allow VAT Difference";
        PurchasesPayablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetupMaxVATDifferenceAllowed(MaxVATDifferenceAllowed: Decimal) OldVATDifferenceAllowed: Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldVATDifferenceAllowed := GeneralLedgerSetup."Max. VAT Difference Allowed";
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", MaxVATDifferenceAllowed);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetupUnrealizedVAT(UnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetupPurchVATUnrealAccount(var VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; PurchVATUnrealAccount: Code[20])
    begin
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", PurchVATUnrealAccount);
        VATPostingSetup.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsModalPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        VATAmount: Variant;
        PurchaseStatisticsOption: Variant;
        VATPct: Variant;
        PurchaseStatisticsOptionValues: Option Update,Verify;
        VATAmountValue: Decimal;
    begin
        LibraryVariableStorage.Dequeue(PurchaseStatisticsOption);
        PurchaseStatisticsOptionValues := PurchaseStatisticsOption;
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(VATPct);
        PurchaseStatistics.SubForm.FindFirstField("VAT %", VATPct);

        // Update VAT Amount on Purchase Statistics page.
        if PurchaseStatisticsOptionValues = PurchaseStatisticsOptionValues::Update then begin
            VATAmountValue := VATAmount;
            PurchaseStatistics.SubForm."VAT Amount".SetValue(PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + VATAmountValue);
            LibraryVariableStorage.Enqueue(PurchaseStatistics.SubForm."VAT Amount".AsDecimal());
        end else  // Verify Updated VAT Amount on Purchase Statistics page.
            PurchaseStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchaseStatistics.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        VATAmount: Variant;
        PurchaseStatisticsOption: Variant;
        VATPct: Variant;
        PurchaseStatisticsOptionValues: Option Update,Verify;
        VATAmountValue: Decimal;
    begin
        LibraryVariableStorage.Dequeue(PurchaseStatisticsOption);
        PurchaseStatisticsOptionValues := PurchaseStatisticsOption;
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(VATPct);
        PurchaseStatistics.SubForm.FindFirstField("VAT %", VATPct);

        // Update VAT Amount on Purchase Statistics page.
        if PurchaseStatisticsOptionValues = PurchaseStatisticsOptionValues::Update then begin
            VATAmountValue := VATAmount;
            PurchaseStatistics.SubForm."VAT Amount".SetValue(PurchaseStatistics.SubForm."VAT Amount".AsDecimal() + VATAmountValue);
            LibraryVariableStorage.Enqueue(PurchaseStatistics.SubForm."VAT Amount".AsDecimal());
        end else  // Verify Updated VAT Amount on Purchase Statistics page.
            PurchaseStatistics.SubForm."VAT Amount".AssertEquals(VATAmount);
        PurchaseStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsECModalPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        LineAmount: Variant;
        VATAmount: Variant;
        ECAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(LineAmount);
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(ECAmount);
        Assert.AreNearlyEqual(
          LineAmount, PurchaseStatistics.SubForm."Line Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          VATAmount, PurchaseStatistics.SubForm."VAT Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          ECAmount, PurchaseStatistics.SubForm."EC Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsECPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        LineAmount: Variant;
        VATAmount: Variant;
        ECAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(LineAmount);
        LibraryVariableStorage.Dequeue(VATAmount);
        LibraryVariableStorage.Dequeue(ECAmount);
        Assert.AreNearlyEqual(
          LineAmount, PurchaseStatistics.SubForm."Line Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          VATAmount, PurchaseStatistics.SubForm."VAT Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          ECAmount, PurchaseStatistics.SubForm."EC Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustBeSameMsg);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasePrepmtDocTestRPH(var PurchasePrepmtDocTest: TestRequestPage "Purchase Prepmt. Doc. - Test")
    begin
        PurchasePrepmtDocTest.ShowDimensions.SetValue(true);
        PurchasePrepmtDocTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}