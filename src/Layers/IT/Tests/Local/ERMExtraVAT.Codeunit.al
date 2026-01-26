codeunit 144078 "ERM Extra VAT"
{
    // // [FEATURE] [VAT]
    //  1. Verify VAT Entry and VAT Book Entry, Post Sales Invoice and fully apply.
    //  2. Verify VAT Entry and VAT Book Entry, Post Sales Invoice and Partial apply.
    //  3. Verify VAT Entry and VAT Book Entry, Post Sales Credit Memo and Partial apply.
    //  4. Verify VAT Entry and VAT Book Entry, Post Sales Credit Memo and Partial apply.
    //  5. Verify error while posting Sales Invoice in closed VAT Period with Unrealized VAT.
    //  6. Verify error while posting Purchase Invoice in closed VAT Period with Unrealized VAT.
    //  7. Verify error while posting Journal with in closed VAT Period with Unrealized VAT.
    //  8. Verify error while reversing transaction in closed VAT Period with Unrealized VAT.
    //  9. Verify error while posting application transaction in closed VAT Period with Unrealized VAT.
    // 10. Verify error while posting unapplication transaction in closed VAT Period with Unrealized VAT.
    // 11. Verify VAT entry after applying Payment to one Installment of Purchase Invoice with FCY.
    // 12. Verify VAT entry after applying Payment to one Installment of Purchase Invoice with LCY.
    // 13. Verify VAT entry after applying Payment to one Installment of Sales Invoice with FCY.
    // 14. Verify VAT entry after applying Payment to one Installment of Sales Invoice with LCY.
    // 15. Verify VAT entry after applying Payment to one Installment of Service Invoice with FCY.
    // 16. Verify VAT entry after applying Payment to one Installment of Service Invoice with LCY.
    // 17. Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be split into two different accounts that are Reverse Charge VAT Account and Nondeductible VAT Account with Random Deductible Pct.
    // 18. Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be split into two different accounts that are Reverse Charge VAT Account and Nondeductible VAT Account with 100 Deductible Pct.
    // 19. Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be posted to the Account which is entered in the invoice when Nondeductible VAT Account =<blank> with Random Deductible Pct.
    // 20. Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be posted to the Account which is entered in the invoice when Nondeductible VAT Account =<blank> with 100 Deductible Pct.
    // 21. Verify VAT Percentage, VAT Identifier and Deductible Percentage after posting Purchase Invoice of multiple line with different VAT Product Posting Group.
    // 22. Verify Prepayment VAT Fields and Your Reference Field on Order Confirmation Report.
    // 23. Verify VAT entries with when Credit memo applied to Invoice and Unrealized VAT Type = FIRST
    // 24. Verify VAT entries for sales invoice partially applied with Credit Memo.
    //
    // Covers Test Cases for WI - 346928
    // --------------------------------------------------------------------------------------
    // Test Function Name                                                              TFS ID
    // --------------------------------------------------------------------------------------
    // SalesInvoiceFullApplyAndUnapply,SalesInvoicePartialApplyAndUnapply       156505,156506
    // SalesCreditMemoFullApplyAndUnapply,SalesCreditMemoPartialApplyAndUnapply 156507,156508
    //
    // Covers Test Cases for WI - 346863
    // ------------------------------------------------------------------------
    // Test Function Name                                                TFS ID
    // ------------------------------------------------------------------------
    // SalesDocumentWithVATPeriodClosedError                             157126
    // PurchaseDocumentWithVATPeriodClosedError                          157127
    // GeneralJournalWithVATPeriodClosedError                            157128
    // ReverseTransactionWithVATPeriodClosedError                        157131
    // ApplicationWithVATPeriodClosedError                               157129
    //
    // Covers Test Cases for WI - 346862
    // ------------------------------------------------------------------------
    // Test Function Name                                                TFS ID
    // ------------------------------------------------------------------------
    // ApplyPaymentToOnePurchInvInstallmentWithFCY                       156073
    // ApplyPaymentToOnePurchInvInstallmentWithLCY                       156070
    // ApplyPaymentToOneSalesInvInstallmentWithFCY                       156074
    // ApplyPaymentToOneSalesInvInstallmentWithLCY                       156071
    // ApplyPaymentToOneServiceInvInstallmentWithFCY                     156075
    // ApplyPaymentToOneServiceInvInstallmentWithLCY                     156072
    //
    // Covers Test Cases for WI - 346437
    // ------------------------------------------------------------------------
    // Test Function Name                                                TFS ID
    // ------------------------------------------------------------------------
    // PurchInvDeductiblePctRandomWithNondeductibleAcc                   244534
    // PurchInvDeductiblePcthundredWithNondeductibleAcc           244535,244536
    // PurchInvDeductiblePctRandomWithoutNondeductibleAcc                244533
    // PurchInvDeductiblePcthundredWithoutNondeductibleAcc        244538,244537
    //
    // Covers Test Cases for WI - 347101
    // ------------------------------------------------------------------------
    // Test Function Name                                                TFS ID
    // ------------------------------------------------------------------------
    // PurchaseInvoiceWithDifferentVATProductPostingGroup         155713,155714
    // VATPrepmtAmtAndYourReferenceOnOrderConfirmationRpt                155495
    //
    // Covers Test Cases for WI - 349791
    // ------------------------------------------------------------------------
    // Test Function Name                                                TFS ID
    // ------------------------------------------------------------------------
    // UnapplicationWithVATPeriodClosedError                             157130
    //
    // Test Function Name                                                TFS ID
    // ------------------------------------------------------------------------
    // ApplyCreditMemoToInvoiceVATypeFirst                               89342
    // ApplySalesInvoiceWithNegativeLineOnCreditMemo                     93934
    //
    // VerifyVATDocNosOnPurchPrepmtWithReverseChargeVAT                  359764
    // VerifyVATDocNosOnPurchMultiPrepmtWithReverseChargeVAT             360225

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.';
        VATPeriodTxt: Label '%1/%2', Comment = '%1=Field Value,%2=Field Value';
#if not CLEAN27
        VATPeriodClosedErr: Label 'VAT Period Closed must be equal to ''No''  in Periodic Settlement VAT Entry: VAT Period=%1/%2. Current value is ''Yes''.', Comment = '%1=Field Value,%2=Field Value';
#else
        VATPeriodActivityCodeClosedErr: Label 'VAT Period Closed must be equal to ''No''  in Periodic VAT Settlement Entry: VAT Period=%1/%2, Activity Code=%3. Current value is ''Yes''.', Comment = '%1=Field Value,%2=Field Value,%3=Field Value';
#endif
        VATFieldErr: Label 'Field %1 contains wrong value';
        LibraryJournals: Codeunit "Library - Journals";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceFullApplyAndUnapply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Verify VAT Entry and VAT Book Entry, Post Sales Invoice and fully apply.

        // Setup: Set Unrealized VAT true, Post Sales Invoice and General Journal Line fully apply.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesLine, VATPostingSetup, SalesLine."Document Type"::Invoice, '', '', false);  // Using blank value for Payment Terms Code and Currency Code. False for Prices Including VAT.
        DocumentNo := PostSalesDocument(SalesLine);

        // Exercise and Verify.
        SalesDocumentApplyAndUnApply(
          SalesLine."Sell-to Customer No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          -SalesLine."Amount Including VAT", -SalesLine.Amount, -SalesLine.Amount * VATPostingSetup."VAT %" / 100, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePartialApplyAndUnapply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Verify VAT Entry and VAT Book Entry, Post Sales Invoice and Partial apply.

        // Setup: SetUnrealizedVAT true, Post Sales Invoice and General Journal Line partially apply.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesLine, VATPostingSetup, SalesLine."Document Type"::Invoice, '', '', false);  // Using blank value for Payment Terms Code and Currency Code. False for Prices Including VAT.
        DocumentNo := PostSalesDocument(SalesLine);

        // Exercise and Verify.
        SalesDocumentApplyAndUnApply(
          SalesLine."Sell-to Customer No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          -SalesLine."Amount Including VAT" / 2, -SalesLine.Amount / 2, -SalesLine.Amount * VATPostingSetup."VAT %" / 200, DocumentNo);  // Partial value required for test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoFullApplyAndUnapply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Verify VAT Entry and VAT Book Entry, Post Sales Credit Memo and Fully apply.

        // Setup: SetUnrealizedVAT true, Post Sales Credit Memo and General Journal Line fully apply.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesLine, VATPostingSetup, SalesLine."Document Type"::"Credit Memo", '', '', false);  // Using blank value for Payment Terms Code and Currency Code. False for Prices Including VAT.
        DocumentNo := PostSalesDocument(SalesLine);

        // Exercise and Verify.
        SalesDocumentApplyAndUnApply(
          SalesLine."Sell-to Customer No.", GenJournalLine."Document Type"::Refund, GenJournalLine."Applies-to Doc. Type"::"Credit Memo",
          SalesLine."Amount Including VAT", SalesLine.Amount, SalesLine.Amount * VATPostingSetup."VAT %" / 100, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoPartialApplyAndUnapply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Verify VAT Entry and VAT Book Entry, Post Sales Credit Memo and Partial apply.

        // Setup: SetUnrealizedVAT true, Post Sales Credit Memo and General Journal Line partially apply.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesLine, VATPostingSetup, SalesLine."Document Type"::"Credit Memo", '', '', false);  // Using blank value for Payment Terms Code and Currency Code. False for Prices Including VAT.
        DocumentNo := PostSalesDocument(SalesLine);

        // Exercise and Verify.
        SalesDocumentApplyAndUnApply(
          SalesLine."Sell-to Customer No.", GenJournalLine."Document Type"::Refund, GenJournalLine."Applies-to Doc. Type"::"Credit Memo",
          SalesLine."Amount Including VAT" / 2, SalesLine.Amount / 2, SalesLine.Amount * VATPostingSetup."VAT %" / 200, DocumentNo);  // Partial value required for test.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentWithVATPeriodClosedError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify error while posting Sales Invoice in closed VAT Period with Unrealized VAT.

        // Setup: Set Unrealized VAT true, Unrealized VAT Type as Percentage, Create Periodic VAT Settlement Entry and Sales Invoice.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreatePeriodicVATSettlementEntry();
        CreateSalesDocument(SalesLine, VATPostingSetup, SalesLine."Document Type"::Invoice, '', '', false);  // Using blank for Payment Terms Code and Currency Code. False for Prices Including VAT.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
#if not CLEAN27
        Assert.ExpectedError(
          StrSubstNo(VATPeriodClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0')));  // Value Zero required for VAT Period.
#else
        Assert.ExpectedError(
          StrSubstNo(VATPeriodActivityCodeClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0'), ''));  // Value Zero required for VAT Period.
#endif
        // Tear Down.
        DeletePeriodicSettlementVATEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocumentWithVATPeriodClosedError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify error while posting Purchase Invoice in closed VAT Period with Unrealized VAT.

        // Setup: Set Unrealized VAT true, Unrealized VAT Type as Percentage, Create Periodic VAT Settlement Entry and Purchase Invoice.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreatePeriodicVATSettlementEntry();
        CreatePurchaseInvoice(
          PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", '', '', PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"));  // Blank value used for Payment Terms Code and Currency Code.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
#if not CLEAN27
        Assert.ExpectedError(
          StrSubstNo(VATPeriodClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0')));  // Value Zero required for VAT Period.
#else
        Assert.ExpectedError(
          StrSubstNo(VATPeriodActivityCodeClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0'), ''));  // Value Zero required for VAT Period.
#endif
        // Tear Down.
        DeletePeriodicSettlementVATEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalWithVATPeriodClosedError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify error while posting Journal with in closed VAT Period with Unrealized VAT.

        // Setup: Set Unrealized VAT true, Unrealized VAT Type as Percentage, Create Periodic VAT Settlement Entry and Gen. Journal Line.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreatePeriodicVATSettlementEntry();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), -LibraryRandom.RandDec(100, 2),
          GenJournalLine."Applies-to Doc. Type"::" ", '');  // Using random for Amount and blank for Applies-to Doc. No.

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
#if not CLEAN27
        Assert.ExpectedError(
          StrSubstNo(VATPeriodClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0')));  // Value Zero required for VAT Period.
#else
        Assert.ExpectedError(
          StrSubstNo(VATPeriodActivityCodeClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0'), ''));  // Value Zero required for VAT Period.
#endif
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReverseEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ReverseTransactionWithVATPeriodClosedError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify error while reversing transaction in closed VAT Period with Unrealized VAT.

        // Setup: Set Unrealized VAT true, Unrealized VAT Type as Percentage, Create and post Journal and Create Periodic VAT Settlement Entry.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
          CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", '', '', false), -LibraryRandom.RandDec(100, 2),
          GenJournalLine."Document Type"::" ", '');  // Using random for Amount and blank for Payment Terms Code, Currency Code,Applies-to Doc. No and False for Price Including VAT.
        UpdateBalAccountNoInGenJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreatePeriodicVATSettlementEntry();

        // Exercise.
        asserterror ReversalEntry.ReverseRegister(FindGLRegister(GenJournalLine."Journal Batch Name"));

        // Verify.
#if not CLEAN27
        Assert.ExpectedError(
          StrSubstNo(VATPeriodClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0')));  // Value Zero required for VAT Period.
#else
        Assert.ExpectedError(
          StrSubstNo(VATPeriodActivityCodeClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0'), ''));  // Value Zero required for VAT Period.
#endif
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplicationWithVATPeriodClosedError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
        AppliesToDocNo: Code[20];
    begin
        // Verify error while posting application transaction in closed VAT Period with Unrealized VAT.

        // Setup: Set Unrealized VAT true, Unrealized VAT Type as Percentage, Post Sales Invoice and apply Payment to it.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesLine, VATPostingSetup, SalesLine."Document Type"::Invoice, '', '', false);  // Using blank value for Payment Terms Code and Currency Code. False for Prices Including VAT.
        AppliesToDocNo := PostSalesDocument(SalesLine);
        CreatePeriodicVATSettlementEntry();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
          SalesLine."Sell-to Customer No.", -SalesLine."Amount Including VAT", GenJournalLine."Applies-to Doc. Type"::Invoice,
          AppliesToDocNo);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        Assert.ExpectedTestFieldError(PeriodicSettlementVATEntry.FieldCaption("VAT Period Closed"), Format(false));

        // Tear Down.
        DeletePeriodicSettlementVATEntry();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,UnapplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UnapplicationWithVATPeriodClosedError()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        AppliesToDocNo: Code[20];
    begin
        // Verify error while posting unapplication transaction in closed VAT Period with Unrealized VAT.

        // Setup: Set UnrealizedVAT true, Unrealized VAT Type as Percentage, Post Sales Invoice, apply and unapply Payment to it.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesLine, VATPostingSetup, SalesLine."Document Type"::Invoice, '', '', false);  // Using blank value for Payment Terms Code and Currency Code. False for Prices Including VAT.
        AppliesToDocNo := PostSalesDocument(SalesLine);
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", -SalesLine."Amount Including VAT", AppliesToDocNo,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);
        CreatePeriodicVATSettlementEntry();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, SalesLine."Document Type"::Invoice, AppliesToDocNo);

        // Exercise.
        asserterror CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");

        // Verify.
#if not CLEAN27
        Assert.ExpectedError(
          StrSubstNo(VATPeriodClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0')));  // Value Zero required for VAT Period.
#else
        Assert.ExpectedError(
          StrSubstNo(VATPeriodActivityCodeClosedErr, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0'), ''));  // Value Zero required for VAT Period.
#endif
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToOnePurchInvInstallmentWithLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        Amount: Decimal;
        Base: Decimal;
    begin
        // Verify VAT entry after applying Payment to one Installment of Purchase Invoice with LCY.

        // Setup: Set Unrealized VAT True on General Ledger Setup. Find and Update VAT Posting Setup. Post Purchase Invoice and Post Payment applied to One Installment of Invoice.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreatePurchaseInvoice(
          PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", FindPaymentTermsCode(), '', PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"));  // Blank value used for Currency.
        AppliesToDocNo := PostPurchaseInvoice(PurchaseLine."Document No.");
        DocumentNo :=
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.",
            PurchaseLine."Amount Including VAT" / GetPaymentNosFromPaymentTerms(), AppliesToDocNo,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);
        Base := PurchaseLine.Amount / GetPaymentNosFromPaymentTerms();
        Amount := (PurchaseLine.Amount * VATPostingSetup."VAT %") / (GetPaymentNosFromPaymentTerms() * 100);

        // Exercise.
        CurrencyCode := RunAddReportingCurrencyReport();

        // Verify.
        VerifyVATEntry(
          DocumentNo, Base, Amount, LibraryERM.ConvertCurrency(Base, '', CurrencyCode, WorkDate()),
          LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()));  // Blank value used for To Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToOnePurchInvInstallmentWithFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify VAT entry after applying Payment to one Installment of Purchase Invoice with FCY.

        // Setup: Set Unrealized VAT True on General Ledger Setup and Invoice Rounding False on Purchases Payables Setup. Find and Update VAT Posting Setup. Post Purchase Invoice.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        LibraryPurchase.SetInvoiceRounding(false);  // Set False for Invoice Rounding to avoid creating Rounding entry on Posting Invoice.
        CreatePurchaseInvoice(
          PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", FindPaymentTermsCode(), CreateCurrencyWithExchangeRate(),
          PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        AppliesToDocNo := PostPurchaseInvoice(PurchaseLine."Document No.");

        // Exercise: Post Payment applied to One Installment of Invoice.
        DocumentNo :=
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.",
            PurchaseLine."Amount Including VAT" / GetPaymentNosFromPaymentTerms(), AppliesToDocNo,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Verify.
        VerifyVATEntry(
          DocumentNo,
          LibraryERM.ConvertCurrency(PurchaseLine.Amount / GetPaymentNosFromPaymentTerms(), PurchaseLine."Currency Code", '', WorkDate()),
          LibraryERM.ConvertCurrency(
            PurchaseLine.Amount * VATPostingSetup."VAT %" / (100 * GetPaymentNosFromPaymentTerms()), PurchaseLine."Currency Code", '',
            WorkDate()), 0, 0);  // Value 0 used for Additional Currency Base and Additional Currency Amount, Blank value used for To Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToOneSalesInvInstallmentWithFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify VAT entry after applying Payment to one Installment of Sales Invoice with FCY.

        // Setup: Set Unrealized VAT True on General Ledger Setup and Invoice Rounding False on Sales Receivables Setup. Find and Update VAT Posting Setup. Post Sales Invoice.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        LibrarySales.SetInvoiceRounding(false);  // Set False for Invoice Rounding to avoid creating Rounding entry on Posting Invoice.
        CreateSalesDocument(SalesLine, VATPostingSetup, SalesLine."Document Type"::Invoice, FindPaymentTermsCode(),
          CreateCurrencyWithExchangeRate(), false);  // Using False for Prices Including VAT.
        AppliesToDocNo := PostSalesDocument(SalesLine);

        // Exercise: Post Payment applied to One Installment of Invoice.
        DocumentNo :=
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.",
            -SalesLine."Amount Including VAT" / GetPaymentNosFromPaymentTerms(), AppliesToDocNo,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Verify.
        VerifyVATEntry(
          DocumentNo, LibraryERM.ConvertCurrency(-SalesLine.Amount / GetPaymentNosFromPaymentTerms(), SalesLine."Currency Code", '', WorkDate()),
          LibraryERM.ConvertCurrency(
            -(SalesLine.Amount * VATPostingSetup."VAT %") / (GetPaymentNosFromPaymentTerms() * 100), SalesLine."Currency Code", '', WorkDate()),
          0, 0);  // Value 0 used for Additional Currency Base and Additional Currency Amount, Blank value used for To Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToOneSalesInvInstallmentWithLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        AppliesToDocNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        Base: Decimal;
    begin
        // Verify VAT entry after applying Payment to one Installment of Sales Invoice with LCY.

        // Setup: Set Unrealized VAT True on General Ledger Setup. Find and Update VAT Posting Setup. Post Sales Invoice and Post Payment applied to One Installment of Invoice.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesLine, VATPostingSetup, SalesLine."Document Type"::Invoice, FindPaymentTermsCode(), '', false);  // Using blank value for Currency Code and False for Prices Including VAT.
        AppliesToDocNo := PostSalesDocument(SalesLine);
        DocumentNo :=
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.",
            -SalesLine."Amount Including VAT" / GetPaymentNosFromPaymentTerms(), AppliesToDocNo,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);
        Base := -SalesLine.Amount / GetPaymentNosFromPaymentTerms();
        Amount := -SalesLine.Amount * VATPostingSetup."VAT %" / (GetPaymentNosFromPaymentTerms() * 100);

        // Exercise.
        CurrencyCode := RunAddReportingCurrencyReport();

        // Verify.
        VerifyVATEntry(
          DocumentNo, Base, Amount, LibraryERM.ConvertCurrency(Base, '', CurrencyCode, WorkDate()),
          LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()));  // Blank value used for To Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToOneServiceInvInstallmentWithFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Verify VAT entry after applying Payment to one Installment of Service Invoice with FCY.

        // Setup: Set Unrealized VAT True on General Ledger Setup and Invoice Rounding False on Sales Receivables Setup. Find and Update VAT Posting Setup. Post Service Invoice.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        LibrarySales.SetInvoiceRounding(false);  // Set False for Invoice Rounding to avoid creating Rounding entry on Posting Invoice.
        CreateAndPostServiceInvoice(ServiceLine, VATPostingSetup, CreateCurrencyWithExchangeRate());

        // Exercise: Post Payment applied to One Installment of Invoice.
        DocumentNo :=
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Customer, ServiceLine."Customer No.",
            -ServiceLine."Amount Including VAT" / GetPaymentNosFromPaymentTerms(), GetPostedServiceDocumentNo(ServiceLine."Document No."),
            GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Verify.
        VerifyVATEntry(
          DocumentNo, LibraryERM.ConvertCurrency(
            -ServiceLine.Amount / GetPaymentNosFromPaymentTerms(), ServiceLine."Currency Code", '', WorkDate()), LibraryERM.ConvertCurrency(
            -ServiceLine.Amount * VATPostingSetup."VAT %" / (GetPaymentNosFromPaymentTerms() * 100), ServiceLine."Currency Code", '',
            WorkDate()), 0, 0);  // Value 0 used for Additional Currency Base and Additional Currency Amount, Blank value used for To Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToOneServiceInvInstallmentWithLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        Amount: Decimal;
        Base: Decimal;
    begin
        // Verify VAT entry after applying Payment to one Installment of Service Invoice with LCY.

        // Setup: Set Unrealized VAT True on General Ledger Setup. Find and Update VAT Posting Setup. Post Service Invoice and Post Payment applied to One Installment of Invoice.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CreateAndPostServiceInvoice(ServiceLine, VATPostingSetup, '');  // Blank value used for Currency.
        DocumentNo :=
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Customer, ServiceLine."Customer No.",
            -ServiceLine."Amount Including VAT" / GetPaymentNosFromPaymentTerms(), GetPostedServiceDocumentNo(ServiceLine."Document No."),
            GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);
        Base := -ServiceLine.Amount / GetPaymentNosFromPaymentTerms();
        Amount := -(ServiceLine.Amount * VATPostingSetup."VAT %") / (GetPaymentNosFromPaymentTerms() * 100);

        // Exercise.
        CurrencyCode := RunAddReportingCurrencyReport();

        // Verify.
        VerifyVATEntry(
          DocumentNo, Base, Amount, LibraryERM.ConvertCurrency(Base, '', CurrencyCode, WorkDate()),
          LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()));  // Blank value used for To Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentSerialNoCheckOnReverseChargeVATWithMultiLineGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchOperationNoSeries: Record "No. Series";
        ExpectedDocumentNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 379762] "Document No." in VAT Entry schould be getting from "Reversal Sales VAT No." for purchase invoice
        // [SCENARIO 379762] posted from 2 lines in general journal with "VAT Calculation Type" = "Reverse Charge VAT"
        Initialize();

        // [GIVEN] G/L Account = "GLA" with Reverse Charge VAT Posting Setup
        CreateGLAccountWithReverseChargeVATAndPurchasePostingType(GLAccount, VATPostingSetup);
        // [GIVEN] Gen. Journal Batch with "No. Series" = "N"
        CreateGenJournalBatch(GenJournalBatch, PurchOperationNoSeries, VATPostingSetup, '');

        // [GIVEN] Purchase Invoice of 2 Gen. Journal Lines:
        // [GIVEN] Gen. Journal Line for vendor with Amount = "-100"
        // [GIVEN] Balance Gen. Journal Line for G/L Account = "GLA" with Amount = "100", "VAT Calculation Type" = "Reverse Charge VAT"
        // [WHEN] Post Journal Lines
        VendorNo := LibraryPurchase.CreateVendorNo();
        ExpectedDocumentNo := NoSeriesBatch.GetNextNo(PurchOperationNoSeries."Reverse Sales VAT No. Series");
        CreateAndPostMultiGenJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice,
          LibraryRandom.RandDec(1000, 2), GLAccount."No.", VendorNo);

        // [THEN] VAT Entry is created for Invoice Document No.
        VerifyVATEntryExists(GenJournalLine."Document No.", VendorNo);

        // [THEN] VAT Entry is created with Reverse Sales Document No. taken from No. Series = "N".
        VerifyVATEntryExists(ExpectedDocumentNo, VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentSerialNoCheckNotReverseChargeVAT()
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchOperationNoSeries: Record "No. Series";
        ReverseSalesNo: Code[10];
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 379248] Document No. in VAT Entry should be getting from Reverse Sales VAT No. Series for purchase invoice posted from general journal if "VAT Calculation Type" = "Reverse Charge VAT".
        Initialize();

        // [GIVEN] G/L Account with Reverse Charge VAT Posting Setup.
        CreateGLAccountWithReverseChargeVATAndPurchasePostingType(GLAccount, VATPostingSetup);

        // [GIVEN] General Journal Batch with "No. Series" = "No.1".
        CreateGenJournalBatch(GenJournalBatch, PurchOperationNoSeries, VATPostingSetup, GLAccount."No.");

        // [GIVEN]  Purchase Invoice Gen. Journal Line
        // [WHEN] Post Gen. Journal Line
        CreateAndPostGenJournalLineWithSavingLastNoUsed(
          GenJnlLine, GenJournalBatch,
          PurchOperationNoSeries, ReverseSalesNo, GenJnlLine."Document Type"::Invoice, -LibraryRandom.RandDec(1000, 2));

        // [THEN] VAT Entry is created for Invoice Document No.
        VerifyVATEntryExists(GenJnlLine."Document No.", GenJnlLine."Bill-to/Pay-to No.");

        // [THEN] VAT Entry is created with Reverse Sales Document No. taken from No. Series = "No.1".
        VerifyVATEntryExists(ReverseSalesNo, GenJnlLine."Bill-to/Pay-to No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentSerialNoCheckOnReverseChargeVAT()
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PurchOperationNoSeries: Record "No. Series";
        ReverseSalesNo: Code[10];
    begin
        // [FEATURE] [Reverse Charge VAT]
        // [SCENARIO 379248] Document No. in VAT Entry should be getting from Default Purch. Operation Type for payment posted from general journal if "VAT Calculation Type" = "Reverse Charge VAT".
        Initialize();

        // [GIVEN] G/L Account with Reverse Charge VAT Posting Setup.
        CreateGLAccountWithReverseChargeVATAndPurchasePostingType(GLAccount, VATPostingSetup);

        // [GIVEN] General Journal Batch
        CreateGenJournalBatch(GenJournalBatch, PurchOperationNoSeries, VATPostingSetup, GLAccount."No.");

        // [GIVEN]  Payment Gen. Journal Line
        // [WHEN] Post Gen. Journal Line
        CreateAndPostGenJournalLineWithSavingLastNoUsed(
          GenJnlLine,
          GenJournalBatch, PurchOperationNoSeries, ReverseSalesNo, GenJnlLine."Document Type"::Payment, LibraryRandom.RandDec(1000, 2));

        // [THEN] VAT Entry is created for Invoice Document No.
        VerifyVATEntryExists(GenJnlLine."Document No.", GenJnlLine."Bill-to/Pay-to No.");

        // [THEN] VAT Entry is not created for Reverse Sales Document No.
        VerifyVATEntryNotExists(ReverseSalesNo, GenJnlLine."Bill-to/Pay-to No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDeductiblePctRandomWithNondeductibleAcc()
    begin
        // Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be split into two different accounts that are Reverse Charge VAT Account and Nondeductible VAT Account with Random Deductible Pct.
        Initialize();
        PurchaseInvoiceWithDeductiblePct(
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandDecInRange(10, 50, 2));  // Using Random value.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDeductiblePcthundredWithNondeductibleAcc()
    begin
        // Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be split into two different accounts that are Reverse Charge VAT Account and Nondeductible VAT Account with 100 Deductible Pct.
        Initialize();
        PurchaseInvoiceWithDeductiblePct(LibraryERM.CreateGLAccountWithSalesSetup(), 100);  // Using 100 for Deductible Percent.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDeductiblePctRandomWithoutNondeductibleAcc()
    begin
        // Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be posted to the Account which is entered in the invoice when Nondeductible VAT Account =<blank> with Random Deductible Pct.
        Initialize();
        PurchaseInvoiceWithDeductiblePct('', LibraryRandom.RandDecInRange(10, 50, 2));  // Using blank value for Nondeductible Account.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDeductiblePcthundredWithoutNondeductibleAcc()
    begin
        // Verify that Reverse Charge VAT and Non-deductible reverse charge vat should be posted to the Account which is entered in the invoice when Nondeductible VAT Account =<blank> with 100 Deductible Pct.
        Initialize();
        PurchaseInvoiceWithDeductiblePct('', 100);  // Using blank value for Nondeductible Account and 100 for Deductible Percent.
    end;

    local procedure PurchaseInvoiceWithDeductiblePct(GLAccountNo: Code[20]; DeductiblePct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Setup: Update VAT Posting Setup, Create Purchase Invoice.
        UpdateNondeductibleVATAccOnVATPostingSetup(VATPostingSetup, GLAccountNo, DeductiblePct);
        CreatePurchaseInvoice(
          PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", '', '', PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup));  // Blank value used for Payment Terms Code and Currency Code.
        Amount :=
          (PurchaseLine."Amount Including VAT" * VATPostingSetup."VAT %") / 100 -
          (PurchaseLine."Amount Including VAT" * VATPostingSetup."VAT %") * (100 - VATPostingSetup."Deductible %") / 10000;

        // Exercise.
        PostedDocumentNo := PostPurchaseInvoice(PurchaseLine."Document No.");

        // Verify: Verify GL Entry and VAT for VAT Posting Setup Account.
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VerifyGLEntry(PostedDocumentNo, VATPostingSetup."Purchase VAT Account", Amount);
        VerifyGLEntry(PostedDocumentNo, VATPostingSetup."Reverse Chrg. VAT Acc.", -Amount);
        VerifyVATEntryWithVATPostingSetup(VATEntry,
          PostedDocumentNo, ((PurchaseLine."Amount Including VAT" * VATPostingSetup."Deductible %") * VATPostingSetup."VAT %") / 10000,
          (PurchaseLine."Amount Including VAT" * VATPostingSetup."Deductible %") / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithDifferentVATProductPostingGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify VAT Percentage, VAT Identifier and Deductible Percentage after posting Purchase Invoice of multiple line with different VAT Product Posting Group.

        // Setup: Update Unrealized VAT on General Ledger Setup. Create two VAT Posting Setup with different VAT Product Posting Group. Create and Post Purchase Invoice.
        Initialize();
        CreateUnrealVATPostingSetup(VATPostingSetup);

        CreateRelatedVATPostingSetup(VATPostingSetup2, VATPostingSetup);
        CreatePurchaseInvoiceWithMultipleLine(PurchaseHeader, VATPostingSetup, VATPostingSetup2."VAT Prod. Posting Group");
        AppliesToDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Recieve and Invoice.

        // Exercise: Post Payment on General Journal after applying Purchase Invoice.
        DocumentNo := CreateAndPostPaymentJournal(AppliesToDocNo, PurchaseHeader."Buy-from Vendor No.");

        // Verify: VAT fields on VAT Entry.
        VerifyVATFieldsOnVATEntry(VATPostingSetup2, DocumentNo);
        VerifyVATFieldsOnVATEntry(VATPostingSetup, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        DocAmount: Decimal;
    begin
        // Verify VAT entries for sales invoice fully applied with Cash payment
        // when Unrealized VAT is turned on

        // Setup.
        Initialize();
        CreateCustomUnrealVATPostingSetup(VATPostingSetup, 20);
        DocAmount := CreateSalesDocumentWithTwoLines(SalesLine, VATPostingSetup);

        // Excercise.
        DocumentNo := PostSalesDocument(SalesLine);
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.", -DocAmount,
          DocumentNo, GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Verify.
        VerifyVATEntryPayments(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCreditMemoToInvoiceVATypeFirst()
    var
        SalesLineInvoice: Record "Sales Line";
        SalesLineCreditMemo: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // Verify VAT entries with when
        // Credit memo applied to Invoice and Unrealized VAT Type = FIRST

        // Setup
        Initialize();
        CreateVATPostingSetupWithVATType(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::First);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // Exercise
        CreateSimpleSalesDocument(SalesLineInvoice, VATPostingSetup, SalesLineInvoice."Document Type"::Invoice, CustomerNo);
        UpdateSalesLine(SalesLineInvoice, LibraryRandom.RandDecInRange(1000, 2000, 2), VATPostingSetup);
        DocumentNo := PostSalesDocument(SalesLineInvoice);

        CreateSimpleSalesDocument(SalesLineCreditMemo, VATPostingSetup, SalesLineCreditMemo."Document Type"::"Credit Memo", CustomerNo);
        UpdateSalesLine(SalesLineCreditMemo, LibraryRandom.RandDecInRange(100, 200, 2), VATPostingSetup);
        SetupDocumentApplication(SalesLineCreditMemo, SalesLineInvoice."Document Type", DocumentNo);
        PostSalesDocument(SalesLineCreditMemo);

        // Verify.
        VerifyVATEntryPayments(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplySalesInvoiceWithNegativeLineOnCreditMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        LineAmount: Decimal;
        CustNo: Code[20];
    begin
        // Verify VAT entries for sales invoice partially applied with Credit Memo

        // Setup:
        Initialize();
        CreateCustomUnrealVATPostingSetup(VATPostingSetup, 20);
        CustNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", '', '', false);
        LineAmount := LibraryRandom.RandDec(1000, 2);
        CreateSalesDocumentWithMultipleLines(SalesLine, VATPostingSetup, SalesHeader."Document Type"::Invoice, CustNo, LineAmount);
        DocumentNo := PostSalesDocument(SalesLine);
        CreateSalesDocumentWithMultipleLines(SalesLine, VATPostingSetup, SalesHeader."Document Type"::"Credit Memo", CustNo, LineAmount / 2);

        // Excercise:
        DocumentNo := ApplyAndPostDocument(SalesLine, DocumentNo);

        // Verify:Verify VAT Entries of Credit Memo After applying Sales Invoice.
        VerifyVATEntryForCreditMemo(DocumentNo, (LineAmount / 2 * VATPostingSetup."VAT %") / 100, LineAmount / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATDocNosOnPurchPrepmtWithReverseChargeVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchDocNo: Code[20];
        ReverseSalesDocNo: Code[20];
    begin
        // [SCENARIO] Verify Document Nos on VAT Entries for Purchase Prepayment with Reverse Charge VAT
        Initialize();

        // [GIVEN] Prepare Purchase Prepayment Order with Reverse Charge VAT
        CreatePrepmtPurchOrder(PurchaseHeader);
        GetExpectedRevChargeVATDocNos(PurchDocNo, ReverseSalesDocNo, PurchaseHeader."Prepayment No. Series");

        // [WHEN] Post Prepayment Invoice
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);

        // [THEN] Verify VAT Entry with type Purchase has Prepayment No Series and type Sales has Reverse Sales VAT No. Series
        VerifyPurchRevChargeDocNoOnVATEntry(
          PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Vendor Invoice No.", PurchDocNo, ReverseSalesDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATDocNosOnPurchMultiPrepmtWithReverseChargeVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchDocNo: Code[20];
        ReverseSalesDocNo: Code[20];
    begin
        // [SCENARIO] Verify Document Nos on VAT Entries for Next Purchase Prepayment with Reverse Charge VAT
        Initialize();

        // [GIVEN] Prepare Purchase Prepayment Order with Reverse Charge VAT
        CreatePrepmtPurchOrder(PurchaseHeader);
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);
        UpdatePrepmtOnPurchaseDoc(PurchaseHeader);
        GetExpectedRevChargeVATDocNos(PurchDocNo, ReverseSalesDocNo, PurchaseHeader."Prepayment No. Series");

        // [WHEN] Post Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Verify VAT Entry with type Purchase has Prepayment No Series and type Sales has Reverse Sales VAT No. Series
        VerifyPurchRevChargeDocNoOnVATEntry(
          PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Vendor Invoice No.", PurchDocNo, ReverseSalesDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateNewVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        // [FEATURE] [UT] [UI] [VAT Posting Setup]
        // [SCENARIO] It should be possible to open VAT Posting Setup Card from VAT Posting Setup page

        VATPostingSetup."VAT Bus. Posting Group" := LibraryUtility.GenerateGUID();
        VATPostingSetup."VAT Prod. Posting Group" := LibraryUtility.GenerateGUID();
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Full VAT";
        VATPostingSetup.Insert();

        VATPostingSetupCard.Trap();
        PAGE.Run(PAGE::"VAT Posting Setup Card", VATPostingSetup);

        VATPostingSetupCard."VAT Calculation Type".AssertEquals(VATPostingSetup."VAT Calculation Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SevPartPmtsPerEachDocOccurOfUnrealVATSalesInvoiceWithSevLines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        FirstPartPaymentNo: array[3] of Code[20];
        SecondPartPaymentNo: array[3] of Code[20];
        ThirdPartPaymentNo: array[3] of Code[20];
        "Part": array[3] of Decimal;
        TotalAmount: Decimal;
        PaymentAmount: array[3] of Decimal;
    begin
        // [FEATURE] [Unrealized VAT] [Installment] [Sales]
        // [SCENARIO 380404] Several partial payments per each document occurrences for Sales Invoice with Unrealized VAT and several sales lines
        Initialize();

        // [GIVEN] Unrealized VAT Posting Setup with VAT% = 20
        CreateUnrealVATPostingSetup(VATPostingSetup);
        // [GIVEN] Customer with Payment Terms with three Payment Lines: "Payment %" = 10%, 60%, 30%
        Part[1] := 0.1;
        Part[2] := 0.6;
        Part[3] := 0.3;
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", CreatePaymentTermsWithThreeLines(Part), '', false);
        // [GIVEN] Sales Invoice with three different G/l Account's lines:
        // [GIVEN] Line1: Amount = 30000, Amount Including VAT = 36000
        // [GIVEN] Line2: Amount = 20000, Amount Including VAT = 24000
        // [GIVEN] Line3: Amount = 10000, Amount Including VAT = 12000
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        CreateSalesLineWithGLAccount(
          SalesLine[1], SalesHeader, VATPostingSetup, 1, LibraryRandom.RandDecInRange(50000, 60000, 2));
        CreateSalesLineWithGLAccount(
          SalesLine[2], SalesHeader, VATPostingSetup, 1, SalesLine[1].Amount - LibraryRandom.RandDecInRange(10000, 20000, 2));
        CreateSalesLineWithGLAccount(
          SalesLine[3], SalesHeader, VATPostingSetup, 1, SalesLine[2].Amount - LibraryRandom.RandDecInRange(10000, 20000, 2));
        // [GIVEN] Post Sales Invoice. Three document occurrences have been created with amounts: 7200 (10%), 43200 (60%), 21600 (30%). Total Amount Including VAT = 72000
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        TotalAmount := SalesLine[1]."Amount Including VAT" + SalesLine[2]."Amount Including VAT" + SalesLine[3]."Amount Including VAT";

        // [GIVEN] Create apply and post payment "Pay1Part1" with Amount = 72000 * 0.1 * 0.1 = 720 (10% of Document Occurence 1)
        // [GIVEN] Create apply and post payment "Pay1Part2" with Amount = 72000 * 0.1 * 0.6 = 4320 (60% of Document Occurence 1)
        // [GIVEN] Create apply and post payment "Pay1Part3" with Amount = 72000 * 0.1 * 0.3 = 2160 (30% of Document Occurence 1)
        PaymentAmount[1] := Round(TotalAmount * Part[1]);
        CreateApplyAndPostThreeCustomerPayments(FirstPartPaymentNo, CustomerNo, InvoiceNo, PaymentAmount[1], Part[1], Part[2]);
        // [GIVEN] Create apply and post payment "Pay2Part1" with Amount = 72000 * 0.6 * 0.1 = 4320 (10% of Document Occurence 2)
        // [GIVEN] Create apply and post payment "Pay2Part2" with Amount = 72000 * 0.6 * 0.6 = 25920 (60% of Document Occurence 2)
        // [GIVEN] Create apply and post payment "Pay2Part3" with Amount = 72000 * 0.6 * 0.3 = 12960 (30% of Document Occurence 2)
        PaymentAmount[2] := Round(TotalAmount * Part[2]);
        CreateApplyAndPostThreeCustomerPayments(SecondPartPaymentNo, CustomerNo, InvoiceNo, PaymentAmount[2], Part[1], Part[2]);
        // [GIVEN] Create apply and post payment "Pay3Part1" with Amount = 72000 * 0.3 * 0.1 = 2160 (10% of Document Occurence 3)
        // [GIVEN] Create apply and post payment "Pay3Part2" with Amount = 72000 * 0.3 * 0.6 = 12960 (60% of Document Occurence 3)
        // [WHEN] Create apply and post payment (final) "Pay3Part3" with Amount = 72000 * 0.3 * 0.3 = 6480 (30% of Document Occurence 3)
        PaymentAmount[3] := TotalAmount - PaymentAmount[1] - PaymentAmount[2];
        CreateApplyAndPostThreeCustomerPayments(ThirdPartPaymentNo, CustomerNo, InvoiceNo, PaymentAmount[3], Part[1], Part[2]);

        // [THEN] There are 3 closed Invoice Ledger Entries (three Document Occurrences per posted Invoice)
        // [THEN] There are 9 closed Payment Ledger Entries (three per each Document Occurrence)
        // [THEN] There are 3 closed Invoice Unrealized VAT Entries
        // [THEN] There are 27 Realized VAT Entries
        VerifySevPartPmtsPerEachDocOccurOfUnrealVATSalesInvoiceWithSevLines(
          SalesLine, CustomerNo, InvoiceNo, PaymentAmount, Part, FirstPartPaymentNo, SecondPartPaymentNo, ThirdPartPaymentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SevPartPmtsPerEachDocOccurOfUnrealVATPurchInvoiceWithSevLines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[3] of Record "Purchase Line";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        FirstPartPaymentNo: array[3] of Code[20];
        SecondPartPaymentNo: array[3] of Code[20];
        ThirdPartPaymentNo: array[3] of Code[20];
        "Part": array[3] of Decimal;
        TotalAmount: Decimal;
        PaymentAmount: array[3] of Decimal;
    begin
        // [FEATURE] [Unrealized VAT] [Installment] [Purchase]
        // [SCENARIO 380404] Several partial payments per each document occurrences for Purchase Invoice with Unrealized VAT and several purchase lines
        Initialize();

        // [GIVEN] Unrealized VAT Posting Setup with VAT% = 20
        CreateUnrealVATPostingSetup(VATPostingSetup);
        // [GIVEN] Vendor with Payment Terms with three Payment Lines: "Payment %" = 10%, 60%, 30%
        Part[1] := 0.1;
        Part[2] := 0.6;
        Part[3] := 0.3;
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group", CreatePaymentTermsWithThreeLines(Part), '');
        // [GIVEN] Purchase Invoice with three different G/l Account's lines:
        // [GIVEN] Line1: Amount = 30000, Amount Including VAT = 36000
        // [GIVEN] Line2: Amount = 20000, Amount Including VAT = 24000
        // [GIVEN] Line3: Amount = 10000, Amount Including VAT = 12000
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchLineWithGLAccount(
          PurchaseLine[1], PurchaseHeader, VATPostingSetup, 1, LibraryRandom.RandDecInRange(50000, 60000, 2));
        CreatePurchLineWithGLAccount(
          PurchaseLine[2], PurchaseHeader, VATPostingSetup, 1, PurchaseLine[1].Amount - LibraryRandom.RandDecInRange(10000, 20000, 2));
        CreatePurchLineWithGLAccount(
          PurchaseLine[3], PurchaseHeader, VATPostingSetup, 1, PurchaseLine[2].Amount - LibraryRandom.RandDecInRange(10000, 20000, 2));
        // [GIVEN] Post Purchase Invoice. Three document occurrences have been created with amounts: 7200 (10%), 43200 (60%), 21600 (30%). Total Amount Including VAT = 72000
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        TotalAmount :=
          PurchaseLine[1]."Amount Including VAT" + PurchaseLine[2]."Amount Including VAT" + PurchaseLine[3]."Amount Including VAT";

        // [GIVEN] Create apply and post payment "Pay1Part1" with Amount = 72000 * 0.1 * 0.1 = 720 (10% of Document Occurence 1)
        // [GIVEN] Create apply and post payment "Pay1Part2" with Amount = 72000 * 0.1 * 0.6 = 4320 (60% of Document Occurence 1)
        // [GIVEN] Create apply and post payment "Pay1Part3" with Amount = 72000 * 0.1 * 0.3 = 2160 (30% of Document Occurence 1)
        PaymentAmount[1] := Round(TotalAmount * Part[1]);
        CreateApplyAndPostThreeVendorPayments(FirstPartPaymentNo, VendorNo, InvoiceNo, PaymentAmount[1], Part[1], Part[2]);
        // [GIVEN] Create apply and post payment "Pay2Part1" with Amount = 72000 * 0.6 * 0.1 = 4320 (10% of Document Occurence 2)
        // [GIVEN] Create apply and post payment "Pay2Part2" with Amount = 72000 * 0.6 * 0.6 = 25920 (60% of Document Occurence 2)
        // [GIVEN] Create apply and post payment "Pay2Part3" with Amount = 72000 * 0.6 * 0.3 = 12960 (30% of Document Occurence 2)
        PaymentAmount[2] := Round(TotalAmount * Part[2]);
        CreateApplyAndPostThreeVendorPayments(SecondPartPaymentNo, VendorNo, InvoiceNo, PaymentAmount[2], Part[1], Part[2]);
        // [GIVEN] Create apply and post payment "Pay3Part1" with Amount = 72000 * 0.3 * 0.1 = 2160 (10% of Document Occurence 3)
        // [GIVEN] Create apply and post payment "Pay3Part2" with Amount = 72000 * 0.3 * 0.6 = 12960 (60% of Document Occurence 3)
        // [WHEN] Create apply and post payment (final) "Pay3Part3" with Amount = 72000 * 0.3 * 0.3 = 6480 (30% of Document Occurence 3)
        PaymentAmount[3] := TotalAmount - PaymentAmount[1] - PaymentAmount[2];
        CreateApplyAndPostThreeVendorPayments(ThirdPartPaymentNo, VendorNo, InvoiceNo, PaymentAmount[3], Part[1], Part[2]);

        // [THEN] There are 3 closed Invoice Ledger Entries (three Document Occurrences per posted Invoice)
        // [THEN] There are 9 closed Payment Ledger Entries (three per each Document Occurrence)
        // [THEN] There are 3 closed Invoice Unrealized VAT Entries
        // [THEN] There are 27 Realized VAT Entries
        VerifySevPartPmtsPerEachDocOccurOfUnrealVATPurchInvoiceWithSevLines(
          PurchaseLine, VendorNo, InvoiceNo, PaymentAmount, Part, FirstPartPaymentNo, SecondPartPaymentNo, ThirdPartPaymentNo);
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewHandler')]
    [Scope('OnPrem')]
    procedure DocumentSerialNoCheckNotReverseChargeVATPurchaseInvoiceDocument()
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Reverse Charge VAT] [Posting Preview] [UI]
        // [SCENARIO ] Stan can preview posted purchase invoice when Reverse Charge VAT and Reversal Series are involved
        Initialize();

        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] No. series "N" with "Reverse Sales VAT No. Series" = "R"
        // [GIVEN] VAT Business Posting Group "B" with "Default Purch. Operation Type" = "N"
        // [GIVEN] VAT Posting Setup with Reverse Charge VAT calculation type and VAT Business Posting Group "B"
        // [GIVEN] Vendor "V" with VAT Business Posting Group = "B"
        CreateGLAccountWithReverseChargeVATAndPurchasePostingType(GLAccount, VATPostingSetup);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Purchase invoice for vendor "V"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandIntInRange(10, 20));

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        Commit();

        // [WHEN] Preview document posting
        LibraryVariableStorage.Enqueue(1);
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);

        // [THEN] Document posting preview page with the single entry has been shown
        Assert.ExpectedError('');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SevPmtTermLinesWithUnrealVATAndSevPmtJnlLinesPurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: array[3] of Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentPart: array[3] of Decimal;
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[3] of Code[20];
        Amount: array[3] of Decimal;
        TotalAmount: Decimal;
        UnrealVATEntryNo: Integer;
        i: Integer;
    begin
        // [FEATURE] [Unrealized VAT] [Payment Terms] [Purchase]
        // [SCENARIO 366842] Several payments to several document occurrences (1-to-1) for purchase invoice with Unrealized VAT and single purchase line
        Initialize();
        PaymentPart[1] := 0.5;
        PaymentPart[2] := 0.3;
        PaymentPart[3] := 0.2;

        // [GIVEN] Unrealized VAT Posting setup with VAT % = 20
        // [GIVEN] Payment Terms with 3 lines: "Payment %" = 50, 30, 20 (with zero discount for all lines)
        CreateUnrealVATPostingSetup(VATPostingSetup);
        // [GIVEN] Posted purchase invoice with one line and total amount including VAT = 1000 + 200 = 1200
        InvoiceNo := CreatePostPurchaseInvoice(VendorNo, VATPostingSetup, CreatePaymentTermsWithThreeLines(PaymentPart));
        // [GIVEN] 3 invoice vendor ledger entries are created, with amount 600, 360, 240 (50%, 30%, 20%)
        CollectVendorInvoiceLedgerEntries(VendorLedgerEntry, TotalAmount, Amount, InvoiceNo);
        // [GIVEN] Payment journal with 3 payment lines, each applied to correspondent invoice vendor ledger entry
        CreateSevPaymentsWithAppliesToId(GenJournalLine, PaymentNo, GenJournalLine."Account Type"::Vendor, VendorNo, Amount, 1);
        SetGivenAppliestoIdVendor(VendorLedgerEntry, PaymentNo);

        // [WHEN] Post the journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] 3 invoice vendor ledger entries are closed (zero remaining amount)
        VerifyThreeVendorInvoiceLedgerEntryAmounts(VendorNo, InvoiceNo, Amount);
        // [THEN] 3 payment vendor ledger entry are closed (zero remaining amount)
        VerifyThreeVednorPaymentLedgerEntryAmounts(VendorNo, PaymentNo, TotalAmount, PaymentPart[1], PaymentPart[2]);
        // [THEN] Unrealized invoice VAT Entry is fully realized (remaining amounts are zero)
        UnrealVATEntryNo := FindAndAssertUnrealVATEntryIsFullyRealized(VATEntry.Type::Purchase, VendorNo, InvoiceNo);
        // [THEN] 3 Realized VAT Entries are created with base+amount = 600, 360, 240
        for i := 1 to ArrayLen(Amount) do begin
            FindVATEntry(
              VATEntry, VATEntry.Type::Purchase, VendorNo, VATEntry."Document Type"::Payment, PaymentNo[i]);
            VATEntry.TestField("Unrealized VAT Entry No.", UnrealVATEntryNo);
            Assert.AreNearlyEqual(Amount[i], VATEntry.Amount + VATEntry.Base, 0.01, '');
        end;
    end;

    [Test]
    procedure SevPmtTermLinesWithUnrealVATAndSinglePmtJnlLinePurchase()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: array[3] of Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        PaymentPart: array[3] of Decimal;
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        Amount: array[3] of Decimal;
        TotalAmount: Decimal;
        UnrealVATEntryNo: Integer;
    begin
        // [FEATURE] [Unrealized VAT] [Payment Terms] [Purchase]
        // [SCENARIO 366842] Single payment to several document occurrences (1-to-many) for purchase invoice with Unrealized VAT and single purchase line
        Initialize();
        PaymentPart[1] := 0.5;
        PaymentPart[2] := 0.3;
        PaymentPart[3] := 0.2;

        // [GIVEN] Unrealized VAT Posting setup with VAT % = 20
        // [GIVEN] Payment Terms with 3 lines: "Payment %" = 50, 30, 20 (with zero discount for all lines)
        CreateUnrealVATPostingSetup(VATPostingSetup);
        // [GIVEN] Posted purchase invoice with one line and total amount including VAT = 1000 + 200 = 1200
        InvoiceNo := CreatePostPurchaseInvoice(VendorNo, VATPostingSetup, CreatePaymentTermsWithThreeLines(PaymentPart));
        // [GIVEN] 3 invoice vendor ledger entries are created, with amount 600, 360, 240 (50%, 30%, 20%)
        CollectVendorInvoiceLedgerEntries(VendorLedgerEntry, TotalAmount, Amount, InvoiceNo);
        // [GIVEN] Payment journal with one payment line applied to 3 invoice vendor ledger entries with full amount
        CreatePaymentWithAppliesToId(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, TotalAmount);
        SetAppliestoIdVendor(InvoiceNo);

        // [WHEN] Post the journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentNo := GenJournalLine."Document No.";

        // [THEN] 3 invoice vendor ledger entries are closed (zero remaining amount)
        VerifyThreeVendorInvoiceLedgerEntryAmounts(VendorNo, InvoiceNo, Amount);
        // [THEN] Payment vendor ledger entry is closed (zero remaining amount)
        VerifyVendorLedgerEntryAmounts(VendorNo, PaymentNo, 1, TotalAmount, 0);
        // [THEN] Unrealized invoice VAT Entry is fully realized (remaining amounts are zero)
        UnrealVATEntryNo := FindAndAssertUnrealVATEntryIsFullyRealized(VATEntry.Type::Purchase, VendorNo, InvoiceNo);
        // [THEN] 3 Realized VAT Entries are created with base+amount = 600, 360, 240
        FindVATEntry(
          VATEntry, VATEntry.Type::Purchase, VendorNo, VATEntry."Document Type"::Payment, PaymentNo);
        VerifySeveralRealizedVATEntries(VATEntry, UnrealVATEntryNo, Amount, 1);
    end;

    [Test]
    procedure SevPmtTermLinesWithUnrealVATAndSevPmtJnlLinesSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: array[3] of Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentPart: array[3] of Decimal;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[3] of Code[20];
        Amount: array[3] of Decimal;
        TotalAmount: Decimal;
        UnrealVATEntryNo: Integer;
        i: Integer;
    begin
        // [FEATURE] [Unrealized VAT] [Payment Terms] [Sales]
        // [SCENARIO 366842] Several payments to several document occurrences (1-to-1) for sales invoice with Unrealized VAT and single sales line
        Initialize();
        PaymentPart[1] := 0.5;
        PaymentPart[2] := 0.3;
        PaymentPart[3] := 0.2;

        // [GIVEN] Unrealized VAT Posting setup with VAT % = 20
        // [GIVEN] Payment Terms with 3 lines: "Payment %" = 50, 30, 20 (with zero discount for all lines)
        CreateUnrealVATPostingSetup(VATPostingSetup);
        // [GIVEN] Posted sales invoice with one line and total amount including VAT = 1000 + 200 = 1200
        InvoiceNo := CreatePostSalesInvoice(CustomerNo, VATPostingSetup, CreatePaymentTermsWithThreeLines(PaymentPart));
        // [GIVEN] 3 invoice customer ledger entries are created, with amount 600, 360, 240 (50%, 30%, 20%)
        CollectCustomerInvoiceLedgerEntries(CustLedgerEntry, TotalAmount, Amount, InvoiceNo);
        // [GIVEN] Payment journal with 3 payment lines, each applied to correspondent invoice customer ledger entry
        CreateSevPaymentsWithAppliesToId(GenJournalLine, PaymentNo, GenJournalLine."Account Type"::Customer, CustomerNo, Amount, -1);
        SetGivenAppliestoIdCustomer(CustLedgerEntry, PaymentNo);

        // [WHEN] Post the journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] 3 invoice customer ledger entries are closed (zero remaining amount)
        VerifyThreeCustomerInvoiceLedgerEntryAmounts(CustomerNo, InvoiceNo, Amount);
        // [THEN] 3 payment customer ledger entry are closed (zero remaining amount)
        VerifyThreeCustomerPaymentLedgerEntryAmounts(CustomerNo, PaymentNo, -TotalAmount, PaymentPart[1], PaymentPart[2]);
        // [THEN] Unrealized invoice VAT Entry is fully realized (remaining amounts are zero)
        UnrealVATEntryNo := FindAndAssertUnrealVATEntryIsFullyRealized(VATEntry.Type::Sale, CustomerNo, InvoiceNo);
        // [THEN] 3 Realized VAT Entries are created with base+amount = 600, 360, 240
        for i := 1 to ArrayLen(Amount) do begin
            FindVATEntry(
              VATEntry, VATEntry.Type::Sale, CustomerNo, VATEntry."Document Type"::Payment, PaymentNo[i]);
            VATEntry.TestField("Unrealized VAT Entry No.", UnrealVATEntryNo);
            Assert.AreNearlyEqual(-Amount[i], VATEntry.Amount + VATEntry.Base, 0.01, '');
        end;
    end;

    [Test]
    procedure SevPmtTermLinesWithUnrealVATAndSinglePmtJnlLineSales()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: array[3] of Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        PaymentPart: array[3] of Decimal;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        Amount: array[3] of Decimal;
        TotalAmount: Decimal;
        UnrealVATEntryNo: Integer;
    begin
        // [FEATURE] [Unrealized VAT] [Payment Terms] [Sales]
        // [SCENARIO 366842] Single payment to several document occurrences (1-to-many) for sales invoice with Unrealized VAT and single sales line
        Initialize();
        PaymentPart[1] := 0.5;
        PaymentPart[2] := 0.3;
        PaymentPart[3] := 0.2;

        // [GIVEN] Unrealized VAT Posting setup with VAT % = 20
        // [GIVEN] Payment Terms with 3 lines: "Payment %" = 50, 30, 20 (with zero discount for all lines)
        CreateUnrealVATPostingSetup(VATPostingSetup);
        // [GIVEN] Posted sales invoice with one line and total amount including VAT = 1000 + 200 = 1200
        InvoiceNo := CreatePostSalesInvoice(CustomerNo, VATPostingSetup, CreatePaymentTermsWithThreeLines(PaymentPart));
        // [GIVEN] 3 invoice customer ledger entries are created, with amount 600, 360, 240 (50%, 30%, 20%)
        CollectCustomerInvoiceLedgerEntries(CustLedgerEntry, TotalAmount, Amount, InvoiceNo);
        // [GIVEN] Payment journal with one payment line applied to 3 invoice customer ledger entries with full amount
        CreatePaymentWithAppliesToId(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, TotalAmount);
        SetAppliestoIdCustomer(InvoiceNo);

        // [WHEN] Post the journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentNo := GenJournalLine."Document No.";

        // [THEN] 3 invoice customer ledger entries are closed (zero remaining amount)
        VerifyThreeCustomerInvoiceLedgerEntryAmounts(CustomerNo, InvoiceNo, Amount);
        // [THEN] Payment customer ledger entry is closed (zero remaining amount)
        VerifyCustomerLedgerEntryAmounts(CustomerNo, PaymentNo, 1, TotalAmount, 0);
        // [THEN] Unrealized invoice VAT Entry is fully realized (remaining amounts are zero)
        UnrealVATEntryNo := FindAndAssertUnrealVATEntryIsFullyRealized(VATEntry.Type::Sale, CustomerNo, InvoiceNo);
        // [THEN] 3 Realized VAT Entries are created with base+amount = 600, 360, 240
        FindVATEntry(
          VATEntry, VATEntry.Type::Sale, CustomerNo, VATEntry."Document Type"::Payment, PaymentNo);
        VerifySeveralRealizedVATEntries(VATEntry, UnrealVATEntryNo, Amount, -1);
    end;

    [Test]
    [HandlerFunctions('PurchaseStatisticsChangeVATAmountPageHandler')]
    procedure DeductibleVATDetailOnPurchaseStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        NonDeductibleBase: Decimal;
        NonDeductibleAmount: Decimal;
    begin
        // [SCENARIO 580117] “Deductible %”, “Nondeductible Base” and “Nondeductible Amount” are correctly filled in “Purchase Invoice Statistics” page.
        Initialize();

        // [GIVEN] Unrealized deductible VAT Posting Setup with "Deductible %" = 50
        UpdateDeductibleVATPostingSetup(VATPostingSetup, 50);

        // [GIVEN] Purchase invoice with one G/L Account line with "Amount Including VAT" = 1000, "VAT Base Amount" = 800
        CreatePurchaseInvoice(
         PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", '', '', PurchaseLine.Type::"G/L Account",
         CreateGLAccount(VATPostingSetup));

        // [GIVEN] Save NonDeductibleBase and NonDeductibleAmount
        NonDeductibleBase := PurchaseLine."VAT Base Amount" * (VATPostingSetup."Deductible %" / 100);
        NonDeductibleAmount := (PurchaseLine."Amount Including VAT" - PurchaseLine.Amount) * (VATPostingSetup."Deductible %" / 100);

        // [GIVEN] Get Purchase Header
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Save "Deductible %" to LibraryVariableStorage
        LibraryVariableStorage.Enqueue(VATPostingSetup."Deductible %");

        // [WHEN] Open purchase invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Open statistics of the invoice and verify the "Deductible %"
        PurchaseInvoicePage.PurchaseStatistics.Invoke();

        // [WHEN] Calculate VatAmountLines
        PurchaseLine.CalcVATAmountLines(0, PurchaseHeader, PurchaseLine, VATAmountLine);

        // [THEN] Check Deductible % and NonDeductible Base and Amount are correct in VATAmountLine
        Assert.AreEqual(VATPostingSetup."Deductible %", VATAmountLine."Deductible %", StrSubstNo(VATFieldErr, VATAmountLine.FieldCaption("Deductible %")));
        Assert.AreNearlyEqual(NonDeductibleBase, VATAmountLine."Nondeductible Base", 0.01, StrSubstNo(VATFieldErr, VATAmountLine.FieldCaption("Nondeductible Base")));
        Assert.AreNearlyEqual(NonDeductibleAmount, VATAmountLine."Nondeductible Amount", 0.01, StrSubstNo(VATFieldErr, VATAmountLine.FieldCaption("Nondeductible Amount")));

        // [THEN] Check that LibraryVariableStorage is empty
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure ApplyAndPostDocument(SalesLine: Record "Sales Line"; DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader."Applies-to Doc. Type" := SalesHeader."Applies-to Doc. Type"::Invoice;
        SalesHeader."Applies-to Doc. No." := DocumentNo;
        SalesHeader.Modify(true);
        exit(PostSalesDocument(SalesLine));
    end;

    local procedure CreateApplyAndPostThreeCustomerPayments(var PaymentNo: array[3] of Code[20]; CustomerNo: Code[20]; InvoiceNo: Code[20]; TotalPaymentAmount: Decimal; FirstPart: Decimal; SecondPart: Decimal)
    var
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        Amount[1] := Round(TotalPaymentAmount * FirstPart);
        Amount[2] := Round(TotalPaymentAmount * SecondPart);
        Amount[3] := TotalPaymentAmount - Amount[1] - Amount[2];
        for i := 1 to ArrayLen(Amount) do
            PaymentNo[i] := CreateApplyAndPostCustomerPayment(CustomerNo, InvoiceNo, -Amount[i]);
    end;

    local procedure CreateApplyAndPostThreeVendorPayments(var PaymentNo: array[3] of Code[20]; CustomerNo: Code[20]; InvoiceNo: Code[20]; TotalPaymentAmount: Decimal; FirstPart: Decimal; SecondPart: Decimal)
    var
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        Amount[1] := Round(TotalPaymentAmount * FirstPart);
        Amount[2] := Round(TotalPaymentAmount * SecondPart);
        Amount[3] := TotalPaymentAmount - Amount[1] - Amount[2];
        for i := 1 to ArrayLen(Amount) do
            PaymentNo[i] := CreateApplyAndPostVendorPayment(CustomerNo, InvoiceNo, Amount[i]);
    end;

    local procedure CreateApplyAndPostCustomerPayment(CustomerNo: Code[20]; AppliesToInvoiceNo: Code[20]; PmtAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Customer, CustomerNo, PmtAmount,
            AppliesToInvoiceNo, GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice));
    end;

    local procedure CreateApplyAndPostVendorPayment(VendorNo: Code[20]; AppliesToInvoiceNo: Code[20]; PmtAmount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Vendor, VendorNo, PmtAmount,
            AppliesToInvoiceNo, GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice));
    end;

    local procedure CreateAndPostPaymentJournal(AppliesToDocNo: Code[20]; VendorNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Vendor, VendorNo, LibraryRandom.RandDec(10, 2),
            AppliesToDocNo, GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice));
    end;

    local procedure CreateAndPostGenJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, DocumentType, AccountType, AccountNo, Amount, AppliesToDocType, AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostGenJournalLineWithSavingLastNoUsed(var GeneralJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PurchOperationNoSeries: Record "No. Series"; var ExpectedReverseSalesNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Quantity: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(GeneralJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GeneralJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), Quantity);
        ExpectedReverseSalesNo := NoSeriesBatch.GetNextNo(PurchOperationNoSeries."Reverse Sales VAT No. Series");
        LibraryERM.PostGeneralJnlLine(GeneralJournalLine);
    end;

    local procedure CreateAndPostMultiGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; LineAmount: Decimal; GLAccountNo: Code[20]; VendorNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::Vendor, VendorNo, -LineAmount);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateSevPaymentsWithAppliesToId(var GenJournalLine: Record "Gen. Journal Line"; var PaymentNo: array[3] of Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: array[3] of Decimal; Sign: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());
        GenJournalBatch.Modify(true);
        for i := 1 to ArrayLen(Amount) do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount[i] * Sign);
            GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
            GenJournalLine.Modify(true);
            PaymentNo[i] := GenJournalLine."Document No.";
        end;
    end;

    local procedure CreatePaymentWithAppliesToId(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to ID", UserId());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostServiceInvoice(var ServiceLine: Record "Service Line"; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice,
          CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", FindPaymentTermsCode(), CurrencyCode, false));  // Using False for Prices Including VAT.
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as Ship and Invoice.
    end;

    local procedure CreateSimpleSalesDocument(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", LibraryERM.CreateGLAccountWithSalesSetup());
        Currency.Validate("Residual Losses Account", LibraryERM.CreateGLAccountWithSalesSetup());
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]; PaymentTermsCode: Code[10]; CurrencyCode: Code[10]; PricesIncludingVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostingGroup));
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Prices Including VAT", PricesIncludingVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; var PurchOperationNoSeries: Record "No. Series"; VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20])
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
    begin
        VATBusPostingGroup.Get(VATPostingSetup."VAT Bus. Posting Group");
        CreatingGeneralJournalBatch(GenJournalBatch, GLAccountNo, VATBusPostingGroup."Default Purch. Operation Type");
        PurchOperationNoSeries.Get(VATBusPostingGroup."Default Purch. Operation Type");
    end;

    local procedure CreateGLAccount(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
    end;

    local procedure CreateGLAccountWithReverseChargeVATAndPurchasePostingType(var GLAccount: Record "G/L Account"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        GLAccount.Get(CreateGLAccount(VATPostingSetup));
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePeriodicVATSettlementEntry()
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
#if not CLEAN27
        LibraryITLocalization.CreatePeriodicVATSettlementEntry(PeriodicSettlementVATEntry, WorkDate());
#else
        LibraryITLocalization.CreatePeriodicSettlementVATEntry(PeriodicSettlementVATEntry, WorkDate());
#endif
        PeriodicSettlementVATEntry.Validate("VAT Period Closed", true);
        PeriodicSettlementVATEntry.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceWithMultipleLine(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; VATProductPostingGroup: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        CreatePurchaseInvoice(
          PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", '', '', PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"));  // Use blank value for payment terms and currency code.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, CreateItem(VATProductPostingGroup));
    end;

    local procedure CreatePurchaseInvoice(var PurchaseLine: Record "Purchase Line"; VATBusinessPostingGroup: Code[20]; PaymentTermsCode: Code[10]; CurrencyCode: Code[10]; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATBusinessPostingGroup, PaymentTermsCode, CurrencyCode));
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Use Random Decimal Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineWithGLAccount(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; UnitPrice: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitPrice);
        PurchaseLine.Modify();
    end;

    local procedure CreatePostPurchaseInvoice(var VendorNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; PaymentTermsCode: Code[10]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          CreateVendor(VATPostingSetup."VAT Bus. Posting Group", PaymentTermsCode, ''));
        CreatePurchLineWithGLAccount(
          PurchaseLine, PurchaseHeader, VATPostingSetup, 1, LibraryRandom.RandDecInRange(1000, 2000, 2));
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Line Type"; PaymentTermsCode: Code[10]; CurrencyCode: Code[10]; PricesIncludingVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType, CreateCustomer(
            VATPostingSetup."VAT Bus. Posting Group", PaymentTermsCode, CurrencyCode, PricesIncludingVAT));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(
            VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithTwoLines(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        SalesHeader: Record "Sales Header";
        LineAmount1: Decimal;
        LineAmount2: Decimal;
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", '', '', false));

        // 1st line
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), 1);
        // amount of first line must be greater than amount of second line
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(200, 1000, 2));
        LineAmount1 := SalesLine."Amount Including VAT";
        SalesLine.Modify(true);

        // 2nd line
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup), -1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        LineAmount2 := SalesLine."Amount Including VAT";
        SalesLine.Modify(true);
        exit(LineAmount1 + LineAmount2);
    end;

    local procedure CreateSalesDocumentWithMultipleLines(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type"; CustNo: Code[20]; LineAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustNo);
        CreateSalesLine(SalesHeader, SalesLine, VATPostingSetup, LineAmount, 1);
        CreateSalesLine(SalesHeader, SalesLine, VATPostingSetup, LineAmount, -1);
        CreateSalesLine(SalesHeader, SalesLine, VATPostingSetup, LineAmount, 1);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; LineAmount: Decimal; Qty: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(VATPostingSetup), Qty);
        SalesLine.Validate("Unit Price", LineAmount);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithGLAccount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; UnitPrice: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify();
    end;

    local procedure CreatePostSalesInvoice(var CustomerNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; PaymentTermsCode: Code[10]): Code[20];
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          CreateCustomer(VATPostingSetup."VAT Bus. Posting Group", PaymentTermsCode, '', false));
        CreateSalesLineWithGLAccount(
          SalesLine, SalesHeader, VATPostingSetup, 1, LibraryRandom.RandDecInRange(1000, 2000, 2));
        CustomerNo := SalesHeader."Sell-to Customer No.";
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateUnrealVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateCustomUnrealVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercent: Decimal)
    begin
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPercent);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupWithVATType(var VATPostingSetup: Record "VAT Posting Setup"; VATType: Option)
    begin
        LibraryERM.SetUnrealizedVAT(true);
        CreateUnrealVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Unrealized VAT Type", VATType);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateRelatedVATPostingSetup(var NewVATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        DummyGLAccount: Record "G/L Account";
    begin
        DummyGLAccount."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        DummyGLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        NewVATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", LibraryERM.CreateRelatedVATPostingSetup(DummyGLAccount));
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]; PaymentTermsCode: Code[10]; CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostingGroup));
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePrepmtPurchOrder(var PurchaseHeader: Record "Purchase Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        UpdatePrepmtOnReverseChargeVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", '', ''));
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 50));
        PurchaseHeader.Validate("Prepayment Due Date", WorkDate());
        PurchaseHeader.Modify();
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::"G/L Account", CreateGLAccount(VATPostingSetup));
    end;

    local procedure CreatePaymentTermsWithThreeLines("Part": array[3] of Decimal): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        PaymentLines: Record "Payment Lines";
        i: Integer;
    begin
        LibraryERM.CreatePaymentTermsIT(PaymentTerms);
        for i := 1 to ArrayLen(Part) do begin
            LibraryERM.CreatePaymentLines(
              PaymentLines, PaymentLines."Sales/Purchase"::" ", PaymentLines.Type::"Payment Terms", PaymentTerms.Code, '', 0);
            PaymentLines.Validate("Payment %", Part[i] * 100);
            PaymentLines.Modify(true);
        end;
        exit(PaymentTerms.Code);
    end;

    local procedure DeletePeriodicSettlementVATEntry()
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        PeriodicSettlementVATEntry.SetRange(
          "VAT Period", StrSubstNo(VATPeriodTxt, Date2DMY(WorkDate(), 3), ConvertStr(Format(Date2DMY(WorkDate(), 2), 2), ' ', '0')));  // Value Zero required for VAT Period.
        PeriodicSettlementVATEntry.FindFirst();
        PeriodicSettlementVATEntry.Delete(true);
    end;

    local procedure FindGLRegister(JournalBatchName: Code[10]): Integer
    var
        GLRegister: Record "G/L Register";
    begin
        GLRegister.SetRange("Journal Batch Name", JournalBatchName);
        GLRegister.FindFirst();
        exit(GLRegister."No.");
    end;

    local procedure FindPaymentTermsCode(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.SetFilter("Payment Nos.", '>1');  // Payment Terms Code with multiple Payment Nos. is required for the tests.
        PaymentTerms.FindFirst();
        exit(PaymentTerms.Code);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; VATEntryType: Enum "General Posting Type"; CVNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange(Type, VATEntryType);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure FindAndAssertUnrealVATEntryIsFullyRealized(VATEntryType: Enum "General Posting Type"; CVNo: Code[20]; InvoiceNo: Code[20]): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, VATEntryType, CVNo, VATEntry."Document Type"::Invoice, InvoiceNo);
        VATEntry.TestField("Remaining Unrealized Amount", 0);
        VATEntry.TestField("Remaining Unrealized Base", 0);
        exit(VATEntry."Entry No.");
    end;

    local procedure FilterVATEntriesOnSalesDocument(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.Reset();
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
    end;

    local procedure GetPaymentNosFromPaymentTerms(): Integer
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(FindPaymentTermsCode());
        PaymentTerms.CalcFields("Payment Nos.");
        exit(PaymentTerms."Payment Nos.");
    end;

    local procedure GetPostedServiceDocumentNo(PreAssignedNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure GetExpectedRevChargeVATDocNos(var PurchDocNo: Code[20]; var ReverseSalesDocNo: Code[20]; PrepmtNoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesBatch: Codeunit "No. Series - Batch";
    begin
        NoSeries.Get(PrepmtNoSeriesCode);
        PurchDocNo := NoSeriesBatch.GetNextNo(NoSeries.Code);
        ReverseSalesDocNo := NoSeriesBatch.GetNextNo(NoSeries."Reverse Sales VAT No. Series");
    end;

    local procedure CreatingGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GLAccountNo: Code[20]; NoSeriesCode: Code[20])
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account No.", GLAccountNo);
        GenJournalBatch.Validate("No. Series", NoSeriesCode);
        GenJournalBatch.Modify(true);
    end;

    local procedure PostPurchaseInvoice(No: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, No);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Invoice.
    end;

    local procedure PostSalesDocument(SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Invoice.
    end;

    local procedure RunAddReportingCurrencyReport() CurrencyCode: Code[10]
    begin
        CurrencyCode := CreateCurrencyWithExchangeRate();
        LibraryERM.RunAddnlReportingCurrency(
          CurrencyCode, Format(LibraryRandom.RandInt(100)), LibraryERM.CreateGLAccountWithSalesSetup());
    end;

    local procedure SalesDocumentApplyAndUnApply(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; AmountIncludingVAT: Decimal; Base: Decimal; Amount: Decimal; AppliesToDocNo: Code[20])
    var
        DocumentNo: Code[20];
    begin
        // Exercise.
        DocumentNo := UnapplyCustLedgerEntry(DocumentType, CustomerNo, AmountIncludingVAT, AppliesToDocNo, AppliesToDocType);

        // Verify.
        VerifyVATEntry(DocumentNo, Base, Amount, 0, 0);  // Value 0 used for Additional Currency Base and Additional Currency Amount.
        VerifyVATBookEntry(DocumentNo, Base);
    end;

    local procedure SetupDocumentApplication(SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Applies-to Doc. Type", DocumentType);
        SalesHeader.Validate("Applies-to Doc. No.", DocumentNo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateBalAccountNoInGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        GenJournalLine.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; AmountIncludingVAT: Decimal; AppliesToDocNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        DocumentNo :=
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Customer, CustomerNo, AmountIncludingVAT, AppliesToDocNo, DocumentType, AppliesToDocType);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        exit(DocumentNo);
    end;

    local procedure UpdateNondeductibleVATAccOnVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; GLAccountNo: Code[20]; DeductiblePct: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Nondeductible VAT Account", GLAccountNo);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Deductible %", DeductiblePct);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateDeductibleVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; DeductiblePct: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Deductible %", DeductiblePct);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesLine(var SalesLine: Record "Sales Line"; NewUnitPrice: Decimal; VATPostingSetup: Record "VAT Posting Setup")
    begin
        SalesLine.Validate("Unit Price", NewUnitPrice);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);
    end;

    local procedure UpdatePrepmtOnReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Purch. Prepayments Account", GLAccount."No.");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdatePrepmtOnPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    var
        PrepmtPct: Decimal;
    begin
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        PrepmtPct := PurchaseHeader."Prepayment %" + LibraryRandom.RandIntInRange(10, 20);
        PurchaseHeader.Validate("Prepayment %", PrepmtPct);
        PurchaseHeader.Validate("Vendor Invoice No.", IncStr(PurchaseHeader."Vendor Invoice No."));
        PurchaseHeader.Validate("Check Total", UpdatePrepmtOnPurchLine(PurchaseHeader, PrepmtPct));
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePrepmtOnPurchLine(PurchaseHeader: Record "Purchase Header"; PrepmtPct: Decimal): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Prepayment %", PrepmtPct);
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Prepmt. Line Amount" - PurchaseLine."Prepmt. Amount Inv. Incl. VAT");
    end;

    local procedure SetAppliestoIdVendor(InvoiceNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", InvoiceNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
    end;

    local procedure SetAppliestoIdCustomer(InvoiceNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", InvoiceNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure SetGivenAppliestoIdVendor(var VendorLedgerEntry: array[3] of Record "Vendor Ledger Entry"; AppliesToId: array[3] of Code[50])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VendorLedgerEntry) do begin
            VendorLedgerEntry[i].Find();
            VendorLedgerEntry[i].CalcFields("Remaining Amount");
            VendorLedgerEntry[i].Validate("Applies-to ID", AppliesToId[i]);
            VendorLedgerEntry[i].Validate("Amount to Apply", VendorLedgerEntry[i]."Remaining Amount");
            VendorLedgerEntry[i].Modify(true);
        end;
    end;

    local procedure SetGivenAppliestoIdCustomer(var CustLedgerEntry: array[3] of Record "Cust. Ledger Entry"; AppliesToId: array[3] of Code[50])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(CustLedgerEntry) do begin
            CustLedgerEntry[i].Find();
            CustLedgerEntry[i].CalcFields("Remaining Amount");
            CustLedgerEntry[i].Validate("Applies-to ID", AppliesToId[i]);
            CustLedgerEntry[i].Validate("Amount to Apply", CustLedgerEntry[i]."Remaining Amount");
            CustLedgerEntry[i].Modify(true);
        end;
    end;

    local procedure CollectVendorInvoiceLedgerEntries(var VendorLedgerEntry: array[3] of Record "Vendor Ledger Entry"; var TotalAmount: Decimal; var Amount: array[3] of Decimal; InvoiceNo: Code[20])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VendorLedgerEntry) do begin
            VendorLedgerEntry[i].SetRange("Document Occurrence", i);
            LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry[i], VendorLedgerEntry[i]."Document Type"::Invoice, InvoiceNo);
            VendorLedgerEntry[i].CalcFields(Amount);
            Amount[i] := -VendorLedgerEntry[i].Amount;
            TotalAmount += Amount[i];
        end;
    end;

    local procedure CollectCustomerInvoiceLedgerEntries(var CustLedgerEntry: array[3] of Record "Cust. Ledger Entry"; var TotalAmount: Decimal; var Amount: array[3] of Decimal; InvoiceNo: Code[20])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(CustLedgerEntry) do begin
            CustLedgerEntry[i].SetRange("Document Occurrence", i);
            LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry[i], CustLedgerEntry[i]."Document Type"::Invoice, InvoiceNo);
            CustLedgerEntry[i].CalcFields(Amount);
            Amount[i] := CustLedgerEntry[i].Amount;
            TotalAmount -= Amount[i];
        end;
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount2: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount2, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount2, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Base: Decimal; Amount: Decimal; AdditionalCurrencyBase: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VerifyVATEntryWithVATPostingSetup(VATEntry, DocumentNo, Amount, Base);
        Assert.AreNearlyEqual(
          AdditionalCurrencyBase, VATEntry."Additional-Currency Base", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption("Additional-Currency Base"), AdditionalCurrencyBase, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, VATEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption("Additional-Currency Amount"), AdditionalCurrencyAmount, VATEntry.TableCaption()));
        VATEntry.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure VerifyVATEntryExists(ExpectedDocumentNo: Code[20]; VendorNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATEntry.SetRange("Document No.", ExpectedDocumentNo);
        Assert.RecordIsNotEmpty(VATEntry);
    end;

    local procedure VerifyVATEntryNotExists(ExcludingDocumentNo: Code[20]; VendorNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATEntry.SetRange("Document No.", ExcludingDocumentNo);
        Assert.RecordIsEmpty(VATEntry)
    end;

    local procedure VerifyVATEntryWithVATPostingSetup(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; Amount: Decimal; Amount2: Decimal)
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount2, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), Amount2, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATBookEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VATBookEntry: Record "VAT Book Entry";
    begin
        VATBookEntry.SetRange("Document No.", DocumentNo);
        VATBookEntry.FindFirst();
        VATBookEntry.CalcFields(Base);
        Assert.AreNearlyEqual(
          Amount, VATBookEntry.Base, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VATBookEntry.FieldCaption(Base), Amount, VATBookEntry.TableCaption()));
        VATBookEntry.TestField("VAT Calculation Type", VATBookEntry."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure VerifyVATFieldsOnVATEntry(VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.FindFirst();
        VATEntry.TestField("VAT %", VATPostingSetup."VAT %");
        VATEntry.TestField("VAT Identifier", VATPostingSetup."VAT Identifier");
        VATEntry.TestField("Deductible %", VATPostingSetup."Deductible %");
    end;

    local procedure VerifyVATEntryPayments(DocumentNo: Code[20])
    var
        VATEntryInvoice: Record "VAT Entry";
        VATEntryPayment: Record "VAT Entry";
    begin
        FilterVATEntriesOnSalesDocument(VATEntryInvoice, VATEntryInvoice."Document Type"::Invoice, DocumentNo);
        VATEntryInvoice.FindSet();
        repeat
            VATEntryPayment.Reset();
            VATEntryPayment.SetRange("Unrealized VAT Entry No.", VATEntryInvoice."Entry No.");
            VATEntryPayment.FindFirst();
            Assert.AreEqual(VATEntryInvoice."Unrealized Amount", VATEntryPayment.Amount, StrSubstNo(VATFieldErr, VATEntryPayment.FieldCaption(Amount)));
            Assert.AreEqual(VATEntryInvoice."Unrealized Base", VATEntryPayment.Base, StrSubstNo(VATFieldErr, VATEntryPayment.FieldCaption(Base)));
        until VATEntryInvoice.Next() = 0;
    end;

    local procedure VerifyVATEntryForCreditMemo(DocumentNo: Code[20]; VATAmt: Decimal; BaseAmt: Decimal)
    var
        VATEntryInvoice: Record "VAT Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        FilterVATEntriesOnSalesDocument(VATEntryInvoice, VATEntryInvoice."Document Type"::"Credit Memo", DocumentNo);
        VATEntryInvoice.SetFilter(Base, '<>0');
        VATEntryInvoice.FindSet();
        repeat
            Assert.AreNearlyEqual(
              Abs(VATEntryInvoice.Amount), VATAmt, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(VATFieldErr, VATEntryInvoice.FieldCaption(Amount)));
            Assert.AreNearlyEqual(
              Abs(VATEntryInvoice.Base), BaseAmt, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(VATFieldErr, VATEntryInvoice.FieldCaption(Base)));
        until VATEntryInvoice.Next() = 0;
    end;

    local procedure VerifyPurchRevChargeDocNoOnVATEntry(VendorNo: Code[20]; ExtDocNo: Code[35]; PurchDocNo: Code[20]; ReverseSalesDocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", VendorNo);
        VATEntry.SetRange("External Document No.", ExtDocNo);
        VATEntry.FindSet();
        Assert.AreEqual(PurchDocNo, VATEntry."Document No.", StrSubstNo(VATFieldErr, VATEntry.FieldCaption("Document No.")));
        Assert.AreEqual(VATEntry.Type::Purchase, VATEntry.Type, StrSubstNo(VATFieldErr, VATEntry.FieldCaption(Type)));
        VATEntry.Next();
        Assert.AreEqual(ReverseSalesDocNo, VATEntry."Document No.", StrSubstNo(VATFieldErr, VATEntry.FieldCaption("Document No.")));
        Assert.AreEqual(VATEntry.Type::Sale, VATEntry.Type, StrSubstNo(VATFieldErr, VATEntry.FieldCaption(Type)));
    end;

    local procedure VerifyCustomerLedgerEntryAmounts(CustomerNo: Code[20]; DocumentNo: Code[20]; DocumentOccurrenceNo: Integer; ExpectedAmount: Decimal; ExpectedRemAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Occurrence", DocumentOccurrenceNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreEqual(ExpectedAmount, CustLedgerEntry.Amount, CustLedgerEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedRemAmount, CustLedgerEntry."Remaining Amount", CustLedgerEntry.FieldCaption("Remaining Amount"));
    end;

    local procedure VerifyVendorLedgerEntryAmounts(VendorNo: Code[20]; DocumentNo: Code[20]; DocumentOccurrenceNo: Integer; ExpectedAmount: Decimal; ExpectedRemAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Occurrence", DocumentOccurrenceNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreEqual(ExpectedAmount, VendorLedgerEntry.Amount, VendorLedgerEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedRemAmount, VendorLedgerEntry."Remaining Amount", VendorLedgerEntry.FieldCaption("Remaining Amount"));
    end;

    local procedure VerifyThreeCustomerInvoiceLedgerEntryAmounts(CustomerNo: Code[20]; InvoiceNo: Code[20]; Amount: array[3] of Decimal)
    begin
        VerifyCustomerLedgerEntryAmounts(CustomerNo, InvoiceNo, 1, Amount[1], 0);
        VerifyCustomerLedgerEntryAmounts(CustomerNo, InvoiceNo, 2, Amount[2], 0);
        VerifyCustomerLedgerEntryAmounts(CustomerNo, InvoiceNo, 3, Amount[3], 0);
    end;

    local procedure VerifyThreeCustomerPaymentLedgerEntryAmounts(CustomerNo: Code[20]; PaymentNo: array[3] of Code[20]; PaymentAmount: Decimal; Part1: Decimal; Part2: Decimal)
    begin
        VerifyCustomerLedgerEntryAmounts(CustomerNo, PaymentNo[1], 1, -Round(PaymentAmount * Part1), 0);
        VerifyCustomerLedgerEntryAmounts(CustomerNo, PaymentNo[2], 1, -Round(PaymentAmount * Part2), 0);
        VerifyCustomerLedgerEntryAmounts(CustomerNo, PaymentNo[3], 1,
          -(PaymentAmount - Round(PaymentAmount * Part1) - Round(PaymentAmount * Part2)), 0);
    end;

    local procedure VerifyThreeVendorInvoiceLedgerEntryAmounts(VendorNo: Code[20]; InvoiceNo: Code[20]; Amount: array[3] of Decimal)
    begin
        VerifyVendorLedgerEntryAmounts(VendorNo, InvoiceNo, 1, -Amount[1], 0);
        VerifyVendorLedgerEntryAmounts(VendorNo, InvoiceNo, 2, -Amount[2], 0);
        VerifyVendorLedgerEntryAmounts(VendorNo, InvoiceNo, 3, -Amount[3], 0);
    end;

    local procedure VerifyThreeVednorPaymentLedgerEntryAmounts(VendorNo: Code[20]; PaymentNo: array[3] of Code[20]; PaymentAmount: Decimal; Part1: Decimal; Part2: Decimal)
    begin
        VerifyVendorLedgerEntryAmounts(VendorNo, PaymentNo[1], 1, Round(PaymentAmount * Part1), 0);
        VerifyVendorLedgerEntryAmounts(VendorNo, PaymentNo[2], 1, Round(PaymentAmount * Part2), 0);
        VerifyVendorLedgerEntryAmounts(VendorNo, PaymentNo[3], 1,
          PaymentAmount - Round(PaymentAmount * Part1) - Round(PaymentAmount * Part2), 0);
    end;

    local procedure VerifyUnrealizedVATEntryAmounts(VATEntry: Record "VAT Entry"; ExpectedBase: Decimal; ExpectedAmount: Decimal; ExpectedRemBase: Decimal; ExpectedRemAmount: Decimal)
    var
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
        Assert.AreNearlyEqual(
          ExpectedBase, VATEntry."Unrealized Base", AmountRoundingPrecision,
          VATEntry.FieldCaption("Unrealized Base"));
        Assert.AreNearlyEqual(
          ExpectedAmount, VATEntry."Unrealized Amount", AmountRoundingPrecision,
          VATEntry.FieldCaption("Unrealized Amount"));
        Assert.AreNearlyEqual(
          ExpectedRemBase, VATEntry."Remaining Unrealized Base", AmountRoundingPrecision,
          VATEntry.FieldCaption("Remaining Unrealized Base"));
        Assert.AreNearlyEqual(
          ExpectedRemAmount, VATEntry."Remaining Unrealized Amount", AmountRoundingPrecision,
          VATEntry.FieldCaption("Remaining Unrealized Amount"));
    end;

    local procedure VerifyRealizedVATEntryAmounts(VATEntry: Record "VAT Entry"; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    var
        AmountRoundingPrecision: Decimal;
    begin
        AmountRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
        Assert.AreNearlyEqual(
          ExpectedBase, VATEntry.Base, AmountRoundingPrecision, VATEntry.FieldCaption(Base));
        Assert.AreNearlyEqual(
          ExpectedAmount, VATEntry.Amount, AmountRoundingPrecision, VATEntry.FieldCaption(Amount));
    end;

    local procedure VerifyThreeCustUnrealizedVATEntry(var VATEntryNo: array[3] of Integer; CVNo: Code[20]; InvoiceNo: Code[20]; SalesLine: array[3] of Record "Sales Line")
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", InvoiceNo);
        VATEntry.FindSet();
        for i := ArrayLen(SalesLine) downto 1 do begin
            VerifyUnrealizedVATEntryAmounts(
              VATEntry, -SalesLine[i].Amount, -(SalesLine[i]."Amount Including VAT" - SalesLine[i].Amount), 0, 0);
            VATEntryNo[ArrayLen(SalesLine) - i + 1] := VATEntry."Entry No.";
            VATEntry.Next();
        end;
    end;

    local procedure VerifyThreeCustRealizedVATEntry(UnrealVATEntryNo: array[3] of Integer; CVNo: Code[20]; PaymentNo: Code[20]; SalesLine: array[3] of Record "Sales Line"; VATPart: Decimal)
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", PaymentNo);
        VATEntry.FindSet();
        for i := ArrayLen(SalesLine) downto 1 do begin
            Assert.AreEqual(
              UnrealVATEntryNo[ArrayLen(SalesLine) - i + 1],
              VATEntry."Unrealized VAT Entry No.",
              VATEntry.FieldCaption("Unrealized VAT Entry No."));
            VerifyRealizedVATEntryAmounts(
              VATEntry,
              -SalesLine[i].Amount * VATPart,
              -(SalesLine[i]."Amount Including VAT" - SalesLine[i].Amount) * VATPart);
            VATEntry.Next();
        end;
    end;

    local procedure VerifyThreeVendUnrealizedVATEntry(var VATEntryNo: array[3] of Integer; CVNo: Code[20]; InvoiceNo: Code[20]; PurchaseLine: array[3] of Record "Purchase Line")
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", InvoiceNo);
        VATEntry.FindSet();
        for i := ArrayLen(PurchaseLine) downto 1 do begin
            VerifyUnrealizedVATEntryAmounts(
              VATEntry, PurchaseLine[i].Amount, PurchaseLine[i]."Amount Including VAT" - PurchaseLine[i].Amount, 0, 0);
            VATEntryNo[ArrayLen(PurchaseLine) - i + 1] := VATEntry."Entry No.";
            VATEntry.Next();
        end;
    end;

    local procedure VerifyThreeVendRealizedVATEntry(UnrealVATEntryNo: array[3] of Integer; CVNo: Code[20]; PaymentNo: Code[20]; PurchaseLine: array[3] of Record "Purchase Line"; VATPart: Decimal)
    var
        VATEntry: Record "VAT Entry";
        i: Integer;
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", PaymentNo);
        VATEntry.FindSet();
        for i := ArrayLen(PurchaseLine) downto 1 do begin
            Assert.AreEqual(
              UnrealVATEntryNo[ArrayLen(PurchaseLine) - i + 1],
              VATEntry."Unrealized VAT Entry No.",
              VATEntry.FieldCaption("Unrealized VAT Entry No."));
            VerifyRealizedVATEntryAmounts(
              VATEntry,
              PurchaseLine[i].Amount * VATPart,
              (PurchaseLine[i]."Amount Including VAT" - PurchaseLine[i].Amount) * VATPart);
            VATEntry.Next();
        end;
    end;

    local procedure VerifySeveralRealizedVATEntries(var VATEntry: Record "VAT Entry"; UnrealVATEntryNo: Integer; Amount: array[3] of Decimal; Sign: Integer)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Amount) do begin
            VATEntry.TestField("Unrealized VAT Entry No.", UnrealVATEntryNo);
            Assert.AreNearlyEqual(Amount[i] * Sign, VATEntry.Amount + VATEntry.Base, 0.01, 'VAT Entry Base+Amount');
            VATEntry.Next();
        end;
    end;

    local procedure VerifySevPartPmtsPerEachDocOccurOfUnrealVATSalesInvoiceWithSevLines(SalesLine: array[3] of Record "Sales Line"; CustomerNo: Code[20]; InvoiceNo: Code[20]; PaymentAmount: array[3] of Decimal; "Part": array[3] of Decimal; FirstPartPaymentNo: array[3] of Code[20]; SecondPartPaymentNo: array[3] of Code[20]; ThirdPartPaymentNo: array[3] of Code[20])
    var
        UnrealizedVATEntryNo: array[3] of Integer;
    begin
        // There are three closed Customer Invoice Ledger Entries:
        // "Document Type" = Invoice, "Document No." = "SI", "Document Occurrence" = 1, Amount = 7200, "Remaining Amount" = 0
        // "Document Type" = Invoice, "Document No." = "SI", "Document Occurrence" = 2, Amount = 43200, "Remaining Amount" = 0
        // "Document Type" = Invoice, "Document No." = "SI", "Document Occurrence" = 3, Amount = 21600, "Remaining Amount" = 0
        VerifyThreeCustomerInvoiceLedgerEntryAmounts(CustomerNo, InvoiceNo, PaymentAmount);
        // There are three closed Customer Payment Ledger Entries:
        // "Document Type" = Payment, "Document No." = "Pay1Part1", Amount = 720, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay1Part2", Amount = 4320, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay1Part3", Amount = 2160, "Remaining Amount" = 0
        VerifyThreeCustomerPaymentLedgerEntryAmounts(CustomerNo, FirstPartPaymentNo, PaymentAmount[1], Part[1], Part[2]);
        // There are three closed Customer Payment Ledger Entries:
        // "Document Type" = Payment, "Document No." = "Pay2Part1", Amount = 4320, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay2Part2", Amount = 25920, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay2Part3", Amount = 12960, "Remaining Amount" = 0
        VerifyThreeCustomerPaymentLedgerEntryAmounts(CustomerNo, SecondPartPaymentNo, PaymentAmount[2], Part[1], Part[2]);
        // There are three closed Customer Payment Ledger Entries:
        // "Document Type" = Payment, "Document No." = "Pay3Part1", Amount = 2160, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay3Part2", Amount = 12960, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay3Part3", Amount = 6480, "Remaining Amount" = 0
        VerifyThreeCustomerPaymentLedgerEntryAmounts(CustomerNo, ThirdPartPaymentNo, PaymentAmount[3], Part[1], Part[2]);
        // There are 3 closed Invoice Unrealized VAT Entries ("Remaining Unrealized Base" = "Remaining Unrealized Amount" = 0):
        // "Entry No." = 1, "Unrealized Base" = 10000, "Unrealized Amount" = 2000
        // "Entry No." = 2, "Unrealized Base" = 20000, "Unrealized Amount" = 4000
        // "Entry No." = 3, "Unrealized Base" = 30000, "Unrealized Amount" = 6000
        VerifyThreeCustUnrealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, InvoiceNo, SalesLine);
        // There are 3 realized VAT Entries related to payment "Pay1Part1" :
        // "Document No." = "Pay1Part1", "Base" = 100, "Amount" = 20, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay1Part1", "Base" = 200, "Amount" = 40, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay1Part1", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 3
        VerifyThreeCustRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, FirstPartPaymentNo[1], SalesLine, Part[1] * Part[1]);
        // There are 3 realized VAT Entries related to payment "Pay1Part2" :
        // "Document No." = "Pay1Part2", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay1Part2", "Base" = 1200, "Amount" = 240, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay1Part2", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 3
        VerifyThreeCustRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, FirstPartPaymentNo[2], SalesLine, Part[1] * Part[2]);
        // There are 3 realized VAT Entries related to payment "Pay1Part3" :
        // "Document No." = "Pay1Part3", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay1Part3", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay1Part3", "Base" = 900, "Amount" = 180, "Unrealized VAT Entry No." = 3
        VerifyThreeCustRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, FirstPartPaymentNo[3], SalesLine, Part[1] * Part[3]);
        // There are 3 realized VAT Entries related to payment "Pay2Part1" :
        // "Document No." = "Pay2Part1", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay2Part1", "Base" = 1200, "Amount" = 240, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay2Part1", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 3
        VerifyThreeCustRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, SecondPartPaymentNo[1], SalesLine, Part[2] * Part[1]);
        // There are 3 realized VAT Entries related to payment "Pay2Part2" :
        // "Document No." = "Pay2Part2", "Base" = 3600, "Amount" = 720, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay2Part2", "Base" = 7200, "Amount" = 1440, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay2Part2", "Base" = 10800, "Amount" = 2160, "Unrealized VAT Entry No." = 3
        VerifyThreeCustRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, SecondPartPaymentNo[2], SalesLine, Part[2] * Part[2]);
        // There are 3 realized VAT Entries related to payment "Pay2Part3" :
        // "Document No." = "Pay2Part3", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay2Part3", "Base" = 3600, "Amount" = 720, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay2Part3", "Base" = 5400, "Amount" = 1080, "Unrealized VAT Entry No." = 3
        VerifyThreeCustRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, SecondPartPaymentNo[3], SalesLine, Part[2] * Part[3]);
        // There are 3 realized VAT Entries related to payment "Pay3Part1" :
        // "Document No." = "Pay3Part1", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay3Part1", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay3Part1", "Base" = 900, "Amount" = 180, "Unrealized VAT Entry No." = 3
        VerifyThreeCustRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, ThirdPartPaymentNo[1], SalesLine, Part[3] * Part[1]);
        // There are 3 realized VAT Entries related to payment "Pay3Part2" :
        // "Document No." = "Pay3Part2", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay3Part2", "Base" = 3600, "Amount" = 720, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay3Part2", "Base" = 5400, "Amount" = 1080, "Unrealized VAT Entry No." = 3
        VerifyThreeCustRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, ThirdPartPaymentNo[2], SalesLine, Part[3] * Part[2]);
        // There are 3 realized VAT Entries related to payment "Pay3Part3" :
        // "Document No." = "Pay3Part3", "Base" = 900, "Amount" = 180, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay3Part3", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay3Part3", "Base" = 2700, "Amount" = 540, "Unrealized VAT Entry No." = 3
        VerifyThreeCustRealizedVATEntry(UnrealizedVATEntryNo, CustomerNo, ThirdPartPaymentNo[3], SalesLine, Part[3] * Part[3]);
    end;

    local procedure VerifySevPartPmtsPerEachDocOccurOfUnrealVATPurchInvoiceWithSevLines(PurchaseLine: array[3] of Record "Purchase Line"; VendorNo: Code[20]; InvoiceNo: Code[20]; PaymentAmount: array[3] of Decimal; "Part": array[3] of Decimal; FirstPartPaymentNo: array[3] of Code[20]; SecondPartPaymentNo: array[3] of Code[20]; ThirdPartPaymentNo: array[3] of Code[20])
    var
        UnrealizedVATEntryNo: array[3] of Integer;
    begin
        // There are three closed Customer Invoice Ledger Entries:
        // "Document Type" = Invoice, "Document No." = "SI", "Document Occurrence" = 1, Amount = 7200, "Remaining Amount" = 0
        // "Document Type" = Invoice, "Document No." = "SI", "Document Occurrence" = 2, Amount = 43200, "Remaining Amount" = 0
        // "Document Type" = Invoice, "Document No." = "SI", "Document Occurrence" = 3, Amount = 21600, "Remaining Amount" = 0
        VerifyThreeVendorInvoiceLedgerEntryAmounts(VendorNo, InvoiceNo, PaymentAmount);
        // There are three closed Customer Payment Ledger Entries:
        // "Document Type" = Payment, "Document No." = "Pay1Part1", Amount = 720, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay1Part2", Amount = 4320, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay1Part3", Amount = 2160, "Remaining Amount" = 0
        VerifyThreeVednorPaymentLedgerEntryAmounts(VendorNo, FirstPartPaymentNo, PaymentAmount[1], Part[1], Part[2]);
        // There are three closed Customer Payment Ledger Entries:
        // "Document Type" = Payment, "Document No." = "Pay2Part1", Amount = 4320, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay2Part2", Amount = 25920, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay2Part3", Amount = 12960, "Remaining Amount" = 0
        VerifyThreeVednorPaymentLedgerEntryAmounts(VendorNo, SecondPartPaymentNo, PaymentAmount[2], Part[1], Part[2]);
        // There are three closed Customer Payment Ledger Entries:
        // "Document Type" = Payment, "Document No." = "Pay3Part1", Amount = 2160, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay3Part2", Amount = 12960, "Remaining Amount" = 0
        // "Document Type" = Payment, "Document No." = "Pay3Part3", Amount = 6480, "Remaining Amount" = 0
        VerifyThreeVednorPaymentLedgerEntryAmounts(VendorNo, ThirdPartPaymentNo, PaymentAmount[3], Part[1], Part[2]);
        // There are 3 closed Invoice Unrealized VAT Entries ("Remaining Unrealized Base" = "Remaining Unrealized Amount" = 0):
        // "Entry No." = 1, "Unrealized Base" = 10000, "Unrealized Amount" = 2000
        // "Entry No." = 2, "Unrealized Base" = 20000, "Unrealized Amount" = 4000
        // "Entry No." = 3, "Unrealized Base" = 30000, "Unrealized Amount" = 6000
        VerifyThreeVendUnrealizedVATEntry(UnrealizedVATEntryNo, VendorNo, InvoiceNo, PurchaseLine);
        // There are 3 realized VAT Entries related to payment "Pay1Part1" :
        // "Document No." = "Pay1Part1", "Base" = 100, "Amount" = 20, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay1Part1", "Base" = 200, "Amount" = 40, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay1Part1", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 3
        VerifyThreeVendRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, FirstPartPaymentNo[1], PurchaseLine, Part[1] * Part[1]);
        // There are 3 realized VAT Entries related to payment "Pay1Part2" :
        // "Document No." = "Pay1Part2", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay1Part2", "Base" = 1200, "Amount" = 240, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay1Part2", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 3
        VerifyThreeVendRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, FirstPartPaymentNo[2], PurchaseLine, Part[1] * Part[2]);
        // There are 3 realized VAT Entries related to payment "Pay1Part3" :
        // "Document No." = "Pay1Part3", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay1Part3", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay1Part3", "Base" = 900, "Amount" = 180, "Unrealized VAT Entry No." = 3
        VerifyThreeVendRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, FirstPartPaymentNo[3], PurchaseLine, Part[1] * Part[3]);
        // There are 3 realized VAT Entries related to payment "Pay2Part1" :
        // "Document No." = "Pay2Part1", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay2Part1", "Base" = 1200, "Amount" = 240, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay2Part1", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 3
        VerifyThreeVendRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, SecondPartPaymentNo[1], PurchaseLine, Part[2] * Part[1]);
        // There are 3 realized VAT Entries related to payment "Pay2Part2" :
        // "Document No." = "Pay2Part2", "Base" = 3600, "Amount" = 720, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay2Part2", "Base" = 7200, "Amount" = 1440, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay2Part2", "Base" = 10800, "Amount" = 2160, "Unrealized VAT Entry No." = 3
        VerifyThreeVendRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, SecondPartPaymentNo[2], PurchaseLine, Part[2] * Part[2]);
        // There are 3 realized VAT Entries related to payment "Pay2Part3" :
        // "Document No." = "Pay2Part3", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay2Part3", "Base" = 3600, "Amount" = 720, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay2Part3", "Base" = 5400, "Amount" = 1080, "Unrealized VAT Entry No." = 3
        VerifyThreeVendRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, SecondPartPaymentNo[3], PurchaseLine, Part[2] * Part[3]);
        // There are 3 realized VAT Entries related to payment "Pay3Part1" :
        // "Document No." = "Pay3Part1", "Base" = 300, "Amount" = 60, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay3Part1", "Base" = 600, "Amount" = 120, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay3Part1", "Base" = 900, "Amount" = 180, "Unrealized VAT Entry No." = 3
        VerifyThreeVendRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, ThirdPartPaymentNo[1], PurchaseLine, Part[3] * Part[1]);
        // There are 3 realized VAT Entries related to payment "Pay3Part2" :
        // "Document No." = "Pay3Part2", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay3Part2", "Base" = 3600, "Amount" = 720, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay3Part2", "Base" = 5400, "Amount" = 1080, "Unrealized VAT Entry No." = 3
        VerifyThreeVendRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, ThirdPartPaymentNo[2], PurchaseLine, Part[3] * Part[2]);
        // There are 3 realized VAT Entries related to payment "Pay3Part3" :
        // "Document No." = "Pay3Part3", "Base" = 900, "Amount" = 180, "Unrealized VAT Entry No." = 1
        // "Document No." = "Pay3Part3", "Base" = 1800, "Amount" = 360, "Unrealized VAT Entry No." = 2
        // "Document No." = "Pay3Part3", "Base" = 2700, "Amount" = 540, "Unrealized VAT Entry No." = 3
        VerifyThreeVendRealizedVATEntry(UnrealizedVATEntryNo, VendorNo, ThirdPartPaymentNo[3], PurchaseLine, Part[3] * Part[3]);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReverseEntriesModalPageHandler(var ReverseTransactionEntries: TestPage "Reverse Transaction Entries")
    begin
        ReverseTransactionEntries.Reverse.Invoke();
        ReverseTransactionEntries.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesModalPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
        UnapplyCustomerEntries.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview."No. of Records".AssertEquals(LibraryVariableStorage.DequeueInteger());
        GLPostingPreview.OK().Invoke();
    end;

    [PageHandler]
    procedure PurchaseStatisticsChangeVATAmountPageHandler(var PurchaseStatisticsPage: TestPage "Purchase Statistics")
    var
        DeductiblePer: Decimal;
    begin
        DeductiblePer := LibraryVariableStorage.DequeueDecimal();
        PurchaseStatisticsPage.SubForm."Deductible %".AssertEquals(DeductiblePer);
        PurchaseStatisticsPage.Close();
    end;

}
