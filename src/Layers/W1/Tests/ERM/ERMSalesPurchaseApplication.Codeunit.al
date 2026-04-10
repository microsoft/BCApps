codeunit 134918 "ERM Sales/Purchase Application"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Application]
        isInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.';
        ApplyAmountErr: Label '%1 must be %2.';
        BatchMsg: Label '%1 - %2-%3';
        ValidationErr: Label 'Journal Card Caption does not match.';
        WrongCustNoErr: Label 'Customer was not found.';
        WrongVendNoErr: Label 'Vendor was not found.';
        PurchaseJournalDefaultsErr: Label 'The default for the Purchase Journal was not correct.  Expected %1, Actual %2';
        AmountLogicErr: Label 'The amount is not correct.  Expected:  %1, Actual:  %2';
        DocumentAmountLogicErr: Label 'The document amount is not correct.  Expected:  %1, Actual:  %2';
        SalesJournalDefaultsErr: Label 'The default for the Sales Journal was not correct.  Expected %1, Actual %2';
        TemplateLogicErrorMsg: Label 'Expected to find SALES1 general journal template but didn''t';
        RemainingAmountErr: Label 'Remaining Amount must be 0.';
        CustLedgerEntryOpenErr: Label 'Cust. Ledger Entry must be Close.';
        SalesPurchErr: Label 'Sales/Purch. (LCY) must be the same as Amount (LCY).';

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler')]
    [Scope('OnPrem')]
    procedure CustPostInvApplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Customer Entries Page Fields with Posting Invoice and Apply Payment without Currency.
        Initialize();
        ApplyCustEntry(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, '', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler')]
    [Scope('OnPrem')]
    procedure CustPostRefundApplyCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Customer Entries Page Fields with Posting Refund and Apply Credit Memo without Currency.
        Initialize();
        ApplyCustEntry(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", '', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler')]
    [Scope('OnPrem')]
    procedure CustPostInvApplyPaymentCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Customer Entries Page Fields with Posting Invoice and Apply Payment with different Currency.
        Initialize();
        ApplyCustEntry(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, CreateCurrency(), CreateCurrency());
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler')]
    [Scope('OnPrem')]
    procedure CustPostRefundApplyCrMemoCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Customer Entries Page Fields with Posting Refund and Apply Credit Memo with different Currency.
        Initialize();
        ApplyCustEntry(
          GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", CreateCurrency(), CreateCurrency());
    end;

    local procedure ApplyCustEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; CurrencyCode2: Code[10]; CurrencyCode3: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Balance: Decimal;
        AppliedAmount: Decimal;
        ApplyingAmount: Decimal;
    begin
        // Setup. Post Customer Invoice and Partial Payment.
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateCustomer(), DocumentType, LibraryRandom.RandDec(100, 2), CurrencyCode2,
          GenJournalLine."Account Type"::Customer);
        Amount := GenJournalLine.Amount;
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", DocumentType2, -GenJournalLine.Amount / 2, CurrencyCode3,
          GenJournalLine."Account Type"::Customer);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        OpenCustLedgerEntryPage(DocumentType, GenJournalLine."Account No.");

        AppliedAmount := LibraryVariableStorage.DequeueDecimal();
        ApplyingAmount := LibraryVariableStorage.DequeueDecimal();
        Balance := LibraryVariableStorage.DequeueDecimal();

        // Verify: Verify Page fields value on Apply Customer Entries Page.
        Assert.AreEqual(GenJournalLine.Amount, AppliedAmount, StrSubstNo(ApplyAmountErr, 'Applied Amount', AppliedAmount));
        Assert.AreEqual(Amount, ApplyingAmount, StrSubstNo(ApplyAmountErr, 'Applying Amount', ApplyingAmount));
        Assert.AreEqual(Amount + GenJournalLine.Amount, Balance, StrSubstNo(ApplyAmountErr, 'Balance', Balance));
        Assert.AreEqual(CurrencyCode2, LibraryVariableStorage.DequeueText(), StrSubstNo(ApplyAmountErr, 'Currency Code', CurrencyCode2));
    end;

    [Test]
    [HandlerFunctions('ApplyPostCustEntryPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustApplyAndPostPaymentInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Customer Ledger Entries for Remaining Amount after Posting and Apply Invoice and Payment through Page.
        Initialize();
        ApplyAndPostCustEntry(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ApplyPostCustEntryPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustApplyAndPostPaymentCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Customer Ledger Entries for Remaining Amount after Posting and Apply Refund and Credit Memo through Page.
        Initialize();
        ApplyAndPostCustEntry(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo");
    end;

    local procedure ApplyAndPostCustEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup. Post Customer Invoice and Partial Payment with Random Amount.
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, CreateCustomer(), DocumentType, LibraryRandom.RandDec(100, 2), '',
          GenJournalLine."Account Type"::Customer);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", DocumentType2, -GenJournalLine.Amount / 2, '',
          GenJournalLine."Account Type"::Customer);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        OpenCustLedgerEntryPage(DocumentType, GenJournalLine."Account No.");

        // Verify: Verify Page fields value on Apply Customer Entries Page.
        GeneralLedgerSetup.Get();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(
          -GenJournalLine.Amount, CustLedgerEntry."Remaining Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption("Remaining Amount"), -GenJournalLine.Amount, CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ApplyPostCustEntryPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustPostAndApplyInvPmtDisc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        OriginalPmtDiscPossible: Decimal;
    begin
        // Check Customer Ledger Entries for Original Payment Discount With Post and Apply Invoice.

        // Setup: Create Customer with Payment Terms and Post and Apply Invoice and Payment.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        CreatePaymentTerms(PaymentTerms, false);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateCustomerWithPaymentTerm(PaymentTerms.Code), GenJournalLine."Document Type"::Invoice,
          LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Customer);
        OriginalPmtDiscPossible := Round(GenJournalLine.Amount * GetPaymentTermsDiscountPercentage(PaymentTerms) / 100);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment,
          -GenJournalLine.Amount / 2, '', GenJournalLine."Account Type"::Customer);
        ModifyGenLinePostingDate(GenJournalLine, CalcDate(PaymentTerms."Discount Date Calculation", GenJournalLine."Posting Date"));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Open Customer Ledger Entry Page, apply and Verify Amount for Customer Entry.
        OpenAndVerifyCustLedgerEntry(
          GenJournalLine, GenJournalLine."Document No.", OriginalPmtDiscPossible, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ApplyPostCustEntryPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustPostAndApplyRefundPmtDisc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        OriginalPmtDiscPossible: Decimal;
    begin
        // Check Customer Ledger Entries for Original Payment Discount With Post and Apply Credit Memo.

        // Setup: Create Customer with Payment Terms and Post and Apply Refund and Credit Memo.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        CreatePaymentTerms(PaymentTerms, true);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateCustomerWithPaymentTerm(PaymentTerms.Code), GenJournalLine."Document Type"::Refund,
          LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Customer);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::"Credit Memo",
          -GenJournalLine.Amount / 2, '', GenJournalLine."Account Type"::Customer);
        ModifyGenLinePostingDate(GenJournalLine, CalcDate(PaymentTerms."Discount Date Calculation", GenJournalLine."Posting Date"));
        OriginalPmtDiscPossible := Round(GenJournalLine.Amount * GetPaymentTermsDiscountPercentage(PaymentTerms) / 100);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Open Customer Ledger Entry Page, apply and Verify Amount for Customer Entry.
        OpenAndVerifyCustLedgerEntry(
          GenJournalLine, GenJournalLine."Document No.", OriginalPmtDiscPossible, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorPageHandler')]
    [Scope('OnPrem')]
    procedure VendPostInvApplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Vendor Entries Page Fields with Posting Invoice and Apply Payment without Currency.
        Initialize();
        ApplyVendorEntry(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, '', '');
    end;

    [Test]
    [HandlerFunctions('ApplyVendorPageHandler')]
    [Scope('OnPrem')]
    procedure VendPostRefundApplyCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Vendor Entries Page Fields with Posting Refund and Apply Credit Memo without Currency.
        Initialize();
        ApplyVendorEntry(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", '', '');
    end;

    [Test]
    [HandlerFunctions('ApplyVendorPageHandler')]
    [Scope('OnPrem')]
    procedure VendPostInvApplyPaymentCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Vendor Entries Page Fields with Posting Invoice and Apply Payment with different Currency.
        Initialize();
        ApplyVendorEntry(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, CreateCurrency(), CreateCurrency());
    end;

    [Test]
    [HandlerFunctions('ApplyVendorPageHandler')]
    [Scope('OnPrem')]
    procedure VendPostRefundApplyCrMemoCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Vendor Entries Page Fields with Posting Refund and Apply Credit Memo with different Currency.
        Initialize();
        ApplyVendorEntry(
          GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", CreateCurrency(), CreateCurrency());
    end;

    local procedure ApplyVendorEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; CurrencyCode3: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Balance: Decimal;
        AppliedAmount: Decimal;
        ApplyingAmount: Decimal;
    begin
        // Setup: Create Vendor, Create and post General Journal  Line.
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateVendor(), DocumentType, -LibraryRandom.RandDec(100, 2),
          CurrencyCode3, GenJournalLine."Account Type"::Vendor);
        Amount := GenJournalLine.Amount;
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", DocumentType2, -GenJournalLine.Amount / 2, CurrencyCode2,
          GenJournalLine."Account Type"::Vendor);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        OpenVendorLedgerEntryPage(DocumentType2, GenJournalLine."Account No.");

        AppliedAmount := LibraryVariableStorage.DequeueDecimal();
        ApplyingAmount := LibraryVariableStorage.DequeueDecimal();
        Balance := LibraryVariableStorage.DequeueDecimal();

        // Verify: Verify Page fields value on Apply Vendor Entries Page.
        Assert.AreEqual(Amount, AppliedAmount, StrSubstNo(ApplyAmountErr, 'Applied Amount', Amount));
        Assert.AreEqual(GenJournalLine.Amount, ApplyingAmount, StrSubstNo(ApplyAmountErr, 'Applying Amount', GenJournalLine.Amount));
        Assert.AreEqual(Amount + GenJournalLine.Amount, Balance, StrSubstNo(ApplyAmountErr, 'Balance', Amount + GenJournalLine.Amount));
        Assert.AreEqual(CurrencyCode2, LibraryVariableStorage.DequeueText(), StrSubstNo(ApplyAmountErr, 'Currency Code', CurrencyCode2));
    end;

    [Test]
    [HandlerFunctions('PostAndApplyVendorPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendApplyAndPostPaymentInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Vendor Ledger Entries for Remaining Amount after Posting and Apply Invoice and Payment through Page.
        Initialize();
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('PostAndApplyVendorPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendApplyAndPostRefundCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Vendor Ledger Entries for Remaining Amount after Posting and Apply Invoice and Payment through Page.
        Initialize();
        ApplyAndPostVendorEntry(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo");
    end;

    local procedure ApplyAndPostVendorEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup. Post Vendor Invoice and Partial Payment with Random Amount.
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateVendor(), DocumentType, -LibraryRandom.RandDec(100, 2), '',
          GenJournalLine."Account Type"::Vendor);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", DocumentType2, -GenJournalLine.Amount / 2, '',
          GenJournalLine."Account Type"::Vendor);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        OpenVendorLedgerEntryPage(DocumentType2, GenJournalLine."Account No.");

        // Verify: Verify Page fields value on Apply Vendor Entries Page.
        GeneralLedgerSetup.Get();
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(
          -GenJournalLine.Amount, VendorLedgerEntry."Remaining Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, VendorLedgerEntry.FieldCaption("Remaining Amount"), -GenJournalLine.Amount,
            VendorLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('PostAndApplyVendorPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendPostAndApplyInvPmtDisc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        OriginalPmtDiscPossible: Decimal;
    begin
        // Check Vendor Ledger Entries for Payment Discount after Posting and Apply Invoice.

        // Setup: Create Customer with Payment Terms, Post Invoice and Apply Payment.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        CreatePaymentTerms(PaymentTerms, false);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateVendorWithPaymentTerm(PaymentTerms.Code), GenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Vendor);
        OriginalPmtDiscPossible := Round(GenJournalLine.Amount * GetPaymentTermsDiscountPercentage(PaymentTerms) / 100);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment,
          -GenJournalLine.Amount / 2, '', GenJournalLine."Account Type"::Vendor);
        ModifyGenLinePostingDate(GenJournalLine, CalcDate(PaymentTerms."Discount Date Calculation", GenJournalLine."Posting Date"));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Open Vendor Ledger Entry Page, Apply Payment and Verify Amount on Vendor Ledger Entry.
        OpenAndVerifyVendorLedgerEntry(
          GenJournalLine, GenJournalLine."Document No.", OriginalPmtDiscPossible, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('PostAndApplyVendorPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendPostAndApplyRefundPmtDisc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        OriginalPmtDiscPossible: Decimal;
    begin
        // Check Vendor Ledger Entries for Payment Discount after Posting and Apply Refund.

        // Setup: Create Vendor with Payment Terms, Post Refund and Apply Credit Memo.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        CreatePaymentTerms(PaymentTerms, true);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateVendorWithPaymentTerm(PaymentTerms.Code), GenJournalLine."Document Type"::Refund,
          -LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Vendor);

        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::"Credit Memo",
          -GenJournalLine.Amount / 2, '', GenJournalLine."Account Type"::Vendor);
        ModifyGenLinePostingDate(GenJournalLine, CalcDate(PaymentTerms."Discount Date Calculation", GenJournalLine."Posting Date"));
        OriginalPmtDiscPossible := Round(GenJournalLine.Amount * GetPaymentTermsDiscountPercentage(PaymentTerms) / 100);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Open Vendor Ledger Entry Page, Apply Refund and Verify Amount on Vendor Ledger Entry.
        OpenAndVerifyVendorLedgerEntry(
          GenJournalLine, GenJournalLine."Document No.", OriginalPmtDiscPossible, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('PostAndApplyVendorPageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendPostAndApplyEqualAmount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Check Vendor Ledger Entries for Amount and Remaining Amount after Applying Invoice and Payment of equal amounts
        // through Page.

        // Setup: Post Vendor Invoice and Payment with Random Amount.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateVendor(), GenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Vendor);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment,
          -GenJournalLine.Amount, '', GenJournalLine."Account Type"::Vendor);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        OpenVendorLedgerEntryPage(GenJournalLine."Document Type", GenJournalLine."Account No.");

        // Verify: Verify Amount and Remaining Amount on Vendor Ledger Entries.
        GeneralLedgerSetup.Get();
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreNearlyEqual(
          GenJournalLine.Amount, VendorLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, VendorLedgerEntry.FieldCaption(Amount), GenJournalLine.Amount,
            VendorLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
          0, VendorLedgerEntry."Remaining Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, VendorLedgerEntry.FieldCaption("Remaining Amount"), 0,
            VendorLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('MatixPageHandler')]
    [Scope('OnPrem')]
    procedure SaleAnalysisMatrixRounding1()
    var
        SalesLine: Record "Sales Line";
        RoundingFactor: Option "None","1","1000","1000000";
        AnalysisViewCode: Code[10];
    begin
        // Check Sales Analysis By Dimension Matrix by Item with Rounding Factor 1.

        // Setup: Create and Post Sales Invoice for Generating the Quantity and Sales Amount in Matrix.
        Initialize();
        AnalysisViewCode := SetupSalesAnalysisMatrix(SalesLine);
        LibraryVariableStorage.Enqueue(SalesLine."No.");
        LibraryVariableStorage.Enqueue(Round(SalesLine.Quantity, 1));
        LibraryVariableStorage.Enqueue(Round(SalesLine."Line Amount", 1));

        // Exercise. Open Sales Analysis Matrix page.
        OpenSalesAnalysisMatrix(RoundingFactor::"1", AnalysisViewCode);

        // Verify: Verification has been handled through Matrix Page Handler.
    end;

    [Test]
    [HandlerFunctions('MatixPageHandler')]
    [Scope('OnPrem')]
    procedure SaleAnalysisMatrixRounding1000()
    var
        SalesLine: Record "Sales Line";
        RoundingFactor: Option "None","1","1000","1000000";
        AnalysisViewCode: Code[10];
    begin
        // Check Sales Analysis By Dimension Matrix by Item with Rounding Factor 1000.

        // Setup: Create and Post Sales Invoice for Generating the Quantity and Sales Amount in Matrix.
        Initialize();
        AnalysisViewCode := SetupSalesAnalysisMatrix(SalesLine);
        LibraryVariableStorage.Enqueue(SalesLine."No.");
        LibraryVariableStorage.Enqueue(Round(SalesLine.Quantity / 1000, 0.1));
        LibraryVariableStorage.Enqueue(Round(SalesLine."Line Amount" / 1000, 0.1));

        // Exercise. Open Sales Analysis Matrix page.
        OpenSalesAnalysisMatrix(RoundingFactor::"1000", AnalysisViewCode);

        // Verify: Verification has been handled through Matrix Page Handler.
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesOKPageHandler')]
    [Scope('OnPrem')]
    procedure CustAppliesToDocTypeBlank()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Customer entries using Applies-to Doc. No. lookup when Applies-to Doc. Type field is blank on Journal line.

        // Setup: Create and post Customer Invoice and Credit Memo and create Customer Payment.
        Initialize();
        CreateAndPostCustomerEntries(GenJournalLine);

        // Exercise: Open Apply Customer Entries page using Applies to Doc. No.
        LibraryVariableStorage.Enqueue(1); // used in ApplyCustEntriesOKPageHandler
        Commit();
        SetJournalLineAppliesToDocNo(GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Journal Batch Name");

        // Verify: Verify filtered Customer Entries on Apply Customer Entries.
        // Verification is done in handler.
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesOKPageHandler')]
    [Scope('OnPrem')]
    procedure CustAppliesToDocTypeNotBlank()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Customer entries using Applies-to Doc. No. lookup when Applies-to Doc. Type field is not blank on Journal line.

        // Setup: Create and post Customer Invoice and Credit Memo and create Customer Payment and fill Applies-to Doc Type field.
        Initialize();
        CreateAndPostCustomerEntries(GenJournalLine);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Modify(true);

        // Exercise: Open Apply Customer Entries page using Applies to Doc. No.
        LibraryVariableStorage.Enqueue(2); // used in ApplyCustEntriesOKPageHandler
        Commit();
        SetJournalLineAppliesToDocNo(GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Journal Batch Name");

        // Verify: Verify filtered Customer Entries on Apply Customer Entries.
        // Verification is done in handler.
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesOKPageHandler')]
    [Scope('OnPrem')]
    procedure CustApplyUsingAppliestoDocNo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Customer Ledger Entries for Amount, Remaining Amount and Open field after Applying Invoice and Payment of equal amounts
        // using Applies-to Doc. No. field lookup.

        // Setup: Create and post Customer Invoice, create Payment and Apply Payment using Applies to Doc. No.
        Initialize();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindCashReceiptTemplate());
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateCustomer(), GenJournalLine."Document Type"::Invoice,
          LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Customer);
        ModifyGenLineBalAccountNo(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalBatch."Journal Template Name");
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment,
          0, '', GenJournalLine."Account Type");
        ModifyGenLineBalAccountNo(GenJournalLine);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Modify(true);
        Commit();
        LibraryVariableStorage.Enqueue(2); // used in ApplyCustEntriesOKPageHandler
        SetJournalLineAppliesToDocNo(GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalBatch.Name);
        GenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
        GenJournalLine.FindFirst();

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Amount, Remaining Amount and Open field on Customer Ledger Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        CustLedgerEntry.TestField(Amount, GenJournalLine.Amount);
        CustLedgerEntry.TestField("Remaining Amount", 0);
        CustLedgerEntry.TestField(Open, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustApplyUsingAppliestoDocNoBlankAccNo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that it is possible to enter an invoice number without having a customer number.
        // Setup: Create and post Customer Invoice, create Payment and Apply Payment using Applies to Doc. No.
        Initialize();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindCashReceiptTemplate());
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateCustomer(), GenJournalLine."Document Type"::Invoice,
          LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Customer);
        ModifyGenLineBalAccountNo(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // Retrieve the new invoice number
        CustLedgerEntry.FindLast();
        CustLedgerEntry.TestField("Document Type", CustLedgerEntry."Document Type"::Invoice);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalBatch."Journal Template Name");
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, '', GenJournalLine."Document Type"::Payment,
          0, '', GenJournalLine."Account Type");
        ModifyGenLineBalAccountNo(GenJournalLine);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.TestField("Applies-to Doc. No.", '');
        GenJournalLine.TestField("Account No.", '');
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        // Verify that the customer number was filled in.
        Assert.AreEqual(CustLedgerEntry."Customer No.", GenJournalLine."Account No.", WrongCustNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendApplyUsingAppliestoDocNoBlankAccNo()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that it is possible to enter an invoice number without having a vendor number.
        // Setup: Create and post Vendor Invoice, create Payment and Apply Payment using Applies to Doc. No.
        Initialize();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindCashReceiptTemplate());
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateVendor(), GenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Vendor);
        ModifyGenLineBalAccountNo(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // Retrieve the new invoice number
        VendLedgerEntry.FindLast();
        VendLedgerEntry.TestField("Document Type", VendLedgerEntry."Document Type"::Invoice);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalBatch."Journal Template Name");
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, '', GenJournalLine."Document Type"::Payment,
          0, '', GenJournalLine."Account Type");
        ModifyGenLineBalAccountNo(GenJournalLine);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.TestField("Applies-to Doc. No.", '');
        GenJournalLine.TestField("Account No.", '');
        GenJournalLine.Validate("Applies-to Doc. No.", VendLedgerEntry."Document No.");
        // Verify that the Vendomer number was filled in.
        Assert.AreEqual(VendLedgerEntry."Vendor No.", GenJournalLine."Account No.", WrongVendNoErr);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AppliesToIDOnApplyCustomerEntriesWithGeneralLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Applies to ID field should be blank on Apply Customer Entries Page.
        // Verify With ApplyCustomerEntriesPageHandler.
        Initialize();
        CreateGeneralLineAndApplyEntries(
          GenJournalLine."Account Type"::Customer, CreateCustomer(), LibraryRandom.RandDec(100, 2));  // Take Random Amount for General Line.
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AppliesToIDOnApplyVendorEntriesWithGeneralLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Applies to ID field should be blank on Apply Vendor Entries Page.
        // Verify with ApplyVendorEntriesPageHandler.
        Initialize();
        CreateGeneralLineAndApplyEntries(GenJournalLine."Account Type"::Vendor, CreateVendor(), -LibraryRandom.RandDec(100, 2)); // Take Random Amount for General Line.
    end;

    local procedure CreateGeneralLineAndApplyEntries(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup: Create and Post General Line for Invoice.
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Create Payment General Line with Zero Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, 0);

        // Verify: Open Apply Entries Page and Check Applies to ID field should be blank.
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Apply Entries".Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalWithNewBatchName()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        SalesJournal: TestPage "Sales Journal";
        BatchName: Code[10];
    begin
        // Check Sales Journal Page's Caption with Created Batch Name.

        // Setup: Create New Sales General Batch and Template.
        Initialize();
        BatchName := CreateGeneralBatchAndTemplate(GenJournalTemplate.Type::Sales);
        Commit(); // commit is required to save the DB State.

        // Exercise: Open Sales Journal page with Created Batch Name.
        SalesJournal.OpenView();
        SalesJournal.CurrentJnlBatchName.SetValue(BatchName);

        // Verify: Verify Sales Journal Page's Caption with Created Batch Name.
        Assert.AreEqual(StrSubstNo(BatchMsg, 'Sales Journals', BatchName, BatchName), SalesJournal.Caption, ValidationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalWithNewBatchName()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        PurchaseJournal: TestPage "Purchase Journal";
        BatchName: Code[10];
    begin
        // Check Purchase Journal Page's Caption with Created Batch Name.

        // Setup: Create New Purchase General Batch and Template.
        Initialize();
        BatchName := CreateGeneralBatchAndTemplate(GenJournalTemplate.Type::Purchases);
        Commit(); // commit is required to save the DB State.

        // Exercise: Open Purchase Journal page with Created Batch Name.
        PurchaseJournal.OpenView();
        PurchaseJournal.CurrentJnlBatchName.SetValue(BatchName);

        // Verify: Verify Purchase Journal Page's Caption with Created Batch Name.
        Assert.AreEqual(StrSubstNo(BatchMsg, 'Purchase Journals', BatchName, BatchName), PurchaseJournal.Caption, ValidationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalDefaults()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] Verify Purchase Journal simple view defaults.

        // [GIVEN] Standard initialization
        Initialize();

        // [WHEN] Purchase Jouranl opened
        PurchaseJournal.OpenView();
        PurchaseJournal.New();

        // [THEN] Purchase Journal simple view "Document Type" and "Account Type" default to the correct values
        Assert.AreEqual(
          Format(GenJournalLine."Document Type"::Invoice), PurchaseJournal."Document Type".Value,
          StrSubstNo(PurchaseJournalDefaultsErr, GenJournalLine."Document Type"::Invoice, PurchaseJournal."Document Type".Value));
        Assert.AreEqual(
          Format(GenJournalLine."Account Type"::Vendor), PurchaseJournal."Account Type".Value,
          StrSubstNo(PurchaseJournalDefaultsErr, GenJournalLine."Account Type"::Vendor, PurchaseJournal."Account Type".Value));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalDocumentAmountLogic()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] Verify Purchase Journal Document Amount logic.

        // [GIVEN] Standard initialization
        Initialize();

        // [WHEN] Purchase Jouranl opened
        PurchaseJournal.OpenView();
        PurchaseJournal.New();

        // [THEN] Purchase Journal Amount is correctly assigned based on Document Type and Document Amount
        PurchaseJournal.DocumentAmount.SetValue(1.23);
        Assert.AreEqual('-1.23', PurchaseJournal.Amount.Value, StrSubstNo(AmountLogicErr, '-1.23',
            PurchaseJournal.Amount.Value));

        PurchaseJournal.DocumentAmount.SetValue(4.56);
        PurchaseJournal."Document Type".SetValue(GenJournalLine."Document Type"::Payment);
        Assert.AreEqual(
          '4.56', PurchaseJournal.Amount.Value, StrSubstNo(AmountLogicErr, '4.56', PurchaseJournal.Amount.Value));

        PurchaseJournal.DocumentAmount.SetValue(7.89);
        PurchaseJournal."Document Type".SetValue(GenJournalLine."Document Type"::"Credit Memo");
        Assert.AreEqual(
          '7.89', PurchaseJournal.Amount.Value, StrSubstNo(AmountLogicErr, '7.89', PurchaseJournal.Amount.Value));

        PurchaseJournal.DocumentAmount.SetValue(12.34);
        PurchaseJournal."Document Type".SetValue(GenJournalLine."Document Type"::"Finance Charge Memo");
        Assert.AreEqual(
          '-12.34', PurchaseJournal.Amount.Value, StrSubstNo(AmountLogicErr, '-12.34', PurchaseJournal.Amount.Value));

        PurchaseJournal.DocumentAmount.SetValue(23.45);
        PurchaseJournal."Document Type".SetValue(GenJournalLine."Document Type"::Invoice);
        Assert.AreEqual(
          '-23.45', PurchaseJournal.Amount.Value, StrSubstNo(AmountLogicErr, '-23.45', PurchaseJournal.Amount.Value));

        PurchaseJournal."Document Type".SetValue(GenJournalLine."Document Type"::"Credit Memo");
        Assert.AreEqual(
          '23.45', PurchaseJournal.Amount.Value, StrSubstNo(AmountLogicErr, '23.45', PurchaseJournal.Amount.Value));

        PurchaseJournal."Document Type".SetValue(GenJournalLine."Document Type"::Refund);
        Assert.AreEqual(
          '-23.45', PurchaseJournal.Amount.Value, StrSubstNo(AmountLogicErr, '-23.45', PurchaseJournal.Amount.Value));

        PurchaseJournal.Amount.SetValue(-6.78);
        Assert.AreEqual(
          '6.78', PurchaseJournal.DocumentAmount.Value,
          StrSubstNo(DocumentAmountLogicErr, '6.78', PurchaseJournal.DocumentAmount.Value));

        PurchaseJournal.Amount.SetValue(7.89);
        Assert.AreEqual(
          '7.89', PurchaseJournal.DocumentAmount.Value,
          StrSubstNo(DocumentAmountLogicErr, '7.89', PurchaseJournal.DocumentAmount.Value));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalDefaults()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] Verify Sales Journal simple view defaults.

        // [GIVEN] Standard initialization
        Initialize();

        // [WHEN] Sales Journal opened
        SalesJournal.OpenView();
        SalesJournal.New();

        // [THEN] Sales Journal simple view "Document Type" and "Account Type" default to the correct values
        Assert.AreEqual(
          Format(GenJournalLine."Document Type"::Invoice), SalesJournal."Document Type".Value,
          StrSubstNo(SalesJournalDefaultsErr, GenJournalLine."Document Type"::Invoice, SalesJournal."Document Type".Value));
        Assert.AreEqual(
          Format(GenJournalLine."Account Type"::Customer), SalesJournal."Account Type".Value,
          StrSubstNo(SalesJournalDefaultsErr, GenJournalLine."Account Type"::Customer, SalesJournal."Account Type".Value));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalTemplateLogic()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] Verify Sales1 General Journal Template is created if Sales already exists but with different type.
        // From ICM 99657780

        // [GIVEN] Standard initialization
        Initialize();

        // Modify Sales General Journal Template to be a different type.  Customer can do this manually in the UI.
        GenJournalTemplate.Init();
        GenJournalTemplate.SetRange(Name, 'SALES');
        GenJournalTemplate.FindFirst();
        GenJournalTemplate.Type := GenJournalTemplate.Type::General;
        GenJournalTemplate.Modify();

        // [WHEN] Sales Journal opens, it will look for a template of type Sales.  Not finding one, it will create Sale1.
        SalesJournal.OpenView();
        SalesJournal.New();
        SalesJournal.Close();

        GenJournalTemplate.Init();
        GenJournalTemplate.SetFilter(Name, 'SALES1');
        Assert.AreEqual(1, GenJournalTemplate.Count, TemplateLogicErrorMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalDocumentAmountLogic()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] Verify Sales Journal Document Amount logic.

        // [GIVEN] Standard initialization
        Initialize();

        // [WHEN] Sales Journal opened
        SalesJournal.OpenView();
        SalesJournal.New();

        // [THEN] Sales Journal Amount is correctly assigned based on Document Type and Document Amount
        SalesJournal.DocumentAmount.SetValue(1.23);
        Assert.AreEqual('1.23', SalesJournal.Amount.Value, StrSubstNo(AmountLogicErr, '1.23',
            SalesJournal.Amount.Value));

        SalesJournal.DocumentAmount.SetValue(4.56);
        SalesJournal."Document Type".SetValue(GenJournalLine."Document Type"::Payment);
        Assert.AreEqual(
          '-4.56', SalesJournal.Amount.Value, StrSubstNo(AmountLogicErr, '-4.56', SalesJournal.Amount.Value));

        SalesJournal.DocumentAmount.SetValue(7.89);
        SalesJournal."Document Type".SetValue(GenJournalLine."Document Type"::"Credit Memo");
        Assert.AreEqual(
          '-7.89', SalesJournal.Amount.Value, StrSubstNo(AmountLogicErr, '-7.89', SalesJournal.Amount.Value));

        SalesJournal.DocumentAmount.SetValue(12.34);
        SalesJournal."Document Type".SetValue(GenJournalLine."Document Type"::"Finance Charge Memo");
        Assert.AreEqual(
          '12.34', SalesJournal.Amount.Value, StrSubstNo(AmountLogicErr, '12.34', SalesJournal.Amount.Value));

        SalesJournal.DocumentAmount.SetValue(23.45);
        SalesJournal."Document Type".SetValue(GenJournalLine."Document Type"::Invoice);
        Assert.AreEqual(
          '23.45', SalesJournal.Amount.Value, StrSubstNo(AmountLogicErr, '23.45', SalesJournal.Amount.Value));

        SalesJournal."Document Type".SetValue(GenJournalLine."Document Type"::"Credit Memo");
        Assert.AreEqual(
          '-23.45', SalesJournal.Amount.Value, StrSubstNo(AmountLogicErr, '-23.45', SalesJournal.Amount.Value));

        SalesJournal."Document Type".SetValue(GenJournalLine."Document Type"::Refund);
        Assert.AreEqual(
          '23.45', SalesJournal.Amount.Value, StrSubstNo(AmountLogicErr, '23.45', SalesJournal.Amount.Value));

        SalesJournal.Amount.SetValue(-6.78);
        Assert.AreEqual(
          '6.78', SalesJournal.DocumentAmount.Value,
          StrSubstNo(DocumentAmountLogicErr, '6.78', SalesJournal.DocumentAmount.Value));

        SalesJournal.Amount.SetValue(7.89);
        Assert.AreEqual(
          '7.89', SalesJournal.DocumentAmount.Value,
          StrSubstNo(DocumentAmountLogicErr, '7.89', SalesJournal.DocumentAmount.Value));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerListChangeFilteredFieldInCard()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        CustomerCard: TestPage "Customer Card";
        NewName: Text;
    begin
        // [FEATURE] [Customer] [UI]
        // [SCENARIO] Change field value in Customer Card invoked from filtered Customer List
        // [GIVEN] Customer "A" with Name "X1"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateGUID());
        Customer.Modify(true);

        // [GIVEN] Customer List filtered by Name = "X1"
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter(Name, Customer.Name);

        // [GIVEN] Customer Card for Customer "A" opened from Customer List
        CustomerList."No.".AssertEquals(Customer."No.");
        CustomerCard.Trap();
        CustomerList.Edit().Invoke();

        // [GIVEN] Name changed to "X2" for Customer "A" in Customer Card
        NewName := LibraryUtility.GenerateGUID();
        CustomerCard.Name.SetValue(NewName);

        // [WHEN] Click OK on  Customer Card
        CustomerCard.OK().Invoke();

        // [THEN] Customer Card closed and Customer List does not contain any record.
        CustomerList."No.".AssertEquals('');
        CustomerList.Close();
        Customer.Get(Customer."No.");
        Assert.AreEqual(NewName, Customer.Name, 'The customer should have the right new name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorListChangeFilteredFieldInCard()
    var
        Vendor: Record Vendor;
        VendorList: TestPage "Vendor List";
        VendorCard: TestPage "Vendor Card";
    begin
        // [FEATURE] [Vendor] [UI]
        // [SCENARIO] Change field value in Vendor Card invoked from filtered Vendor List
        // [GIVEN] Vendor "A" with Name "X1"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateGUID());
        Vendor.Modify(true);

        // [GIVEN] Vendor List filtered by Name = "X1"
        VendorList.OpenView();
        VendorList.FILTER.SetFilter(Name, Vendor.Name);

        // [GIVEN] Vendor Card for Vendor "A" opened from Vendor List
        VendorList."No.".AssertEquals(Vendor."No.");
        VendorCard.Trap();
        VendorList.Edit().Invoke();

        // [GIVEN] Name changed to "X2" for Vendor "A" in Vendor Card
        VendorCard.Name.SetValue(LibraryUtility.GenerateGUID());

        // [WHEN] Click OK on Vendor Card.
        VendorCard.OK().Invoke();

        // [THEN] Vendor Card closed and Vendor List does not contain any record.
        VendorList."No.".AssertEquals('');
        VendorList.Close();
    end;

    [Test]
    [HandlerFunctions('DuplicateContactFoundConfirmHandlerYes,ContactDuplicatesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestChangeFilteredFieldForCustomerWithDuplicateContacts()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContDuplicateSearchString: Record "Cont. Duplicate Search String";
        CustContUpdate: Codeunit "CustCont-Update";
        VendContUpdate: Codeunit "VendCont-Update";
        DuplicateManagement: Codeunit DuplicateManagement;
        CustomerList: TestPage "Customer List";
        CustomerCard: TestPage "Customer Card";
        OriginalName: Text[50];
        NewName: Text;
    begin
        Customer.DeleteAll();
        Contact.DeleteAll();
        ContDuplicateSearchString.DeleteAll();

        // Madeira Bug 155753
        // [FEATURE] [Vendor] [UI]
        // [SCENARIO] Change field value in Customer Card invoked from filtered Customer List
        // [GIVEN] A customer
        OriginalName := LibraryUtility.GenerateGUID();
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := OriginalName;
        Customer.Address := 'Sesamestreet 42';
        Customer."Post Code" := '1234XP';
        Customer.City := 'Denver';
        Customer."Phone No." := '0102573895';
        Customer.Modify(true);
        CustContUpdate.OnModify(Customer);

        // [GIVEN] A vendor with the same name, address etc as the customer
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := OriginalName;
        Vendor.Address := Customer.Address;
        Vendor."Post Code" := Customer."Post Code";
        Vendor.City := Customer.City;
        Vendor."Phone No." := Customer."Phone No.";
        Vendor.Modify(true);
        VendContUpdate.OnModify(Vendor);

        // [THEN] The contact belonging to the customer and vendor are duplicates
        Contact.SetRange(Name, OriginalName);
        Assert.AreEqual(2, Contact.Count, 'There should be two contacts with the same name');

        Contact.FindSet();
        repeat
            DuplicateManagement.MakeContIndex(Contact);
        until Contact.Next() = 0;

        Assert.IsTrue(DuplicateManagement.DuplicateExist(Contact), 'The contacts should be duplicates');

        // [GIVEN] Customer List filtered by the name of the customer
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter(Name, Customer.Name);

        // [GIVEN] Customer Card for the customer opened from the Customer List so it has the same filter
        CustomerList."No.".AssertEquals(Customer."No.");
        CustomerCard.Trap();
        CustomerList.Edit().Invoke();

        // [GIVEN] The customer's name is changed
        NewName := LibraryUtility.GenerateGUID();
        CustomerCard.Name.SetValue(NewName);

        // [WHEN] The customer card is closed
        // Using NEXT instead of OK because in the automated test the pages get focus/closed in such a
        // way that another modify call is done and a deadlock results. Does not repro manually.
        CustomerCard.Next();
        CustomerCard.Close();
        CustomerList.Close();

        // [THEN] The customer is renamed, and all that without errors.
        Customer.Get(Customer."No.");
        Assert.AreEqual(NewName, Customer.Name, 'The customer should have the right new name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustPaymentToInvoiceAndTwoCrMemos()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 376164] When apply Sales Payment to two Credit Memos and Invoice with total zero Amount all Customer Ledger Entries should be closed
        Initialize();

        // [GIVEN] 2 Sales Credit Memos with Amounts = -10, -20, Payment with Amount = -30, Invoice with Amount = 60
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateAndPostCustMultipleJnlLines(PaymentNo, CustomerNo);

        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);

        // [WHEN] Apply Payment to 2 Cr.Memos and Invoice
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // [THEN] All Customer Ledger Entries are closed
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange(Open, true);
        Assert.RecordIsEmpty(CustLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendPaymentToInvoiceAndTwoCrMemos()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376164] When apply Purchase Payment to two Credit Memos and Invoice with total zero Amount all Vendor Ledger Entries should be closed
        Initialize();

        // [GIVEN] 2 Purchase Credit Memos with Amounts = 10, 20, Payment with Amount = 30, Invoice with Amount = -60
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateAndPostVendMultipleJnlLines(PaymentNo, VendorNo);

        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PaymentNo);

        // [WHEN] Apply Payment to two Cr.Memos and Invoice
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // [THEN] All Vendor Ledger Entries are closed
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange(Open, true);
        Assert.RecordIsEmpty(VendorLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler,ApplyVendorEntriesClearsAppliesToIdPageHandler')]
    [Scope('OnPrem')]
    procedure VendAppliesToIdClearedAfterAmountToApplyIsSetToZero()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 206799] "Applies-to ID" is cleared when previously non-zero "Amount to Apply" is set to zero in Apply Vendor Entries Page.
        Initialize();

        // [GIVEN] Vendor with posted purchase invoice and credit memo.
        SetupVendorWithTwoPostedDocuments(Vendor);

        // [GIVEN] Vendor Ledger Entries is opened and "Apply Entries" button is invoked, opening Apply Vendor Entries Page.
        // Handled by VendorLedgerEntriesPageHandler
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);

        // The following sequence is executed by ApplyVendorEntriesClearsAppliesToIdPageHandler
        // [GIVEN] Set "Amount to Apply" = 100. "Applies-to ID" is populated.
        // [WHEN] Set "Amount to Apply" = 0.
        // [THEN] "Applies-to ID" is cleared.
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler,ApplyCustEntriesClearsAppliesToIdPageHandler')]
    [Scope('OnPrem')]
    procedure CustAppliesToIdClearedAfterAmountToApplyIsSetToZero()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 206799] "Applies-to ID" is cleared when previously non-zero "Amount to Apply" is set to zero in Apply Customer Entries Page.
        Initialize();

        // [GIVEN] Customer with posted sales invoice and credit memo.
        SetupCustomerWithTwoPostedDocuments(Customer);

        // [GIVEN] Customer Ledger Entries is opened and "Apply Entries" button is invoked, opening Apply Customer Entries Page.
        // Handled by CustomerLedgerEntriesPageHandler
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);

        // The following sequence is executed by ApplyCustEntriesClearsAppliesToIdPageHandler
        // [GIVEN] Set "Amount to Apply" = 100, "Applies-to ID" is populated.
        // [WHEN] Set "Amount to Apply" = 0.
        // [THEN] "Applies-to ID" is cleared.
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler,ApplyVendorEntriesPageClearsAmountToApplyPageHandler')]
    [Scope('OnPrem')]
    procedure VendAmountToApplyNotClearedAfterBeingSetToZero()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 206799] "Amount to Apply" is not cleared when previously non-zero "Amount to Apply" was set to zero and then again to a value in Apply Vendor Entries Page.
        Initialize();

        // [GIVEN] Vendor with posted purchase invoice and credit memo.
        SetupVendorWithTwoPostedDocuments(Vendor);

        // [GIVEN] Vendor Ledger Entries is opened and "Apply Entries" button is invoked, opening Apply Vendor Entries Page.
        // Handled by VendorLedgerEntriesPageHandler
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);

        // The following sequence is executed by ApplyVendorEntriesPageClearsAmountToApplyPageHandler
        // [GIVEN] Set "Amount to Apply" = 100.
        // [GIVEN] Set "Amount to Apply" = 0.
        // [WHEN] Set "Amount to Apply" = 50.
        // [THEN] "Amount to Apply" is 50.
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler,ApplyCustEntriesPageClearsAmountToApplyPageHandler')]
    [Scope('OnPrem')]
    procedure CustAmountToApplyNotClearedAfterBeingSetToZero()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 206799] "Amount to Apply" is not cleared when previously non-zero "Amount to Apply" was set to zero and then again to a value in Apply Customer Entries Page.
        Initialize();

        // [GIVEN] Customer with posted sales invoice and credit memo.
        SetupCustomerWithTwoPostedDocuments(Customer);

        // [GIVEN] Customer Ledger Entries is opened and "Apply Entries" button is invoked, opening Apply Customer Entries Page.
        // Handled by CustomerLedgerEntriesPageHandler
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);

        // The following sequence is executed by ApplyCustEntriesPageClearsAmountToApplyPageHandler
        // [GIVEN] Set "Amount to Apply" = 100.
        // [GIVEN] Set "Amount to Apply" = 0.
        // [WHEN] Set "Amount to Apply" = 50.
        // [THEN] "Amount to Apply" is 50.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCustomerApplicationAfterPostingTwoReceipt()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        InvoiceAmount: Decimal;
        Payment: Decimal;
        Payment2: Decimal;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 491576] When Posting a Payment with several lines the Apply to Oldest is not applied properly
        Initialize();

        // [GIVEN] Create Customer withh Application method = "Apply to Oldest", Payment Term and Payment Method Code
        CreateCustomerWithApplicationMethod(Customer);

        // [GIVEN] Create and post sales order
        CreateandPostSalesOrder(Customer."No.", InvoiceAmount);

        // [GIVEN] Assume two payment, first will be small amount and second larger than first.
        Payment := 100;
        Payment2 := InvoiceAmount - Payment;

        // [GIVEN] Create General Journal Batch for Cash Receipt Journal
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindCashReceiptTemplate());

        // [GIVEN] Create balancing G/l Account
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Create first Payment without balancing account 
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, Customer."No.", GenJournalLine."Document Type"::Payment, -Payment, '', GenJournalLine."Account Type"::Customer);

        // [GIVEN] Save Document No. of Gen. Journal Line.
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] Create second Payment without balancing account
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, Customer."No.", GenJournalLine."Document Type"::Payment, -Payment2, '', GenJournalLine."Account Type"::Customer);

        // [GIVEN] Update same Document No. on Gen. Journal Line
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine.Modify();

        // [GIVEN] Create third balancing line of Account type G/l Account
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, GLAccount."No.", GenJournalLine."Document Type"::Payment, InvoiceAmount, '', GenJournalLine."Account Type"::"G/L Account");

        // [GIVEN] Update same Document No. on Gen. Journal Line
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine.Modify();

        // [WHEN] Post the payment fron Cash Receipt Journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [VERIFY]: Verify Remaining Amount and Open field on Customer Ledger Entries.
        VerifyCustomerLedgerEntry(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentAmountInPurchJnlAcceptsMaxThreeDecimalPlacesValue()
    var
        Vendor: Record Vendor;
        Currency: Record Currency;
        PurchaseJournal: TestPage "Purchase Journal";
        DocumentAmount: Decimal;
    begin
        // [SCENARIO 534464] Document Amount field in Purchase Journal accepts a value of maximum 3 decimal places.
        // [SCENARIO 544673] Document amount field respects Currency Code Decimal places settings
        Initialize();

        // [GIVEN] Create a Currency with amount rounding precision and decimal places allowing for 3 decimal places.
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(0D, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2)));
        Currency."Amount Decimal Places" := '3:3';
        Currency."Amount Rounding Precision" := 0.001;
        Currency.Modify();

        // [GIVEN] Create a Vendor with the Currency Code.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify();

        // [GIVEN] Open Purchase Journal and enter Vendor No.
        PurchaseJournal.OpenView();
        PurchaseJournal.New();
        PurchaseJournal."Account Type".SetValue("Gen. Journal Account Type"::Vendor);
        PurchaseJournal."Account No.".SetValue(Vendor."No.");

        // [GIVEN] Document Amount for line has 3 decimal places.
        DocumentAmount := LibraryRandom.RandDecInRange(1, 4, 3);

        // [WHEN] Set Document Amount field in Purchase Journal.
        PurchaseJournal.DocumentAmount.SetValue(DocumentAmount);

        // [THEN] Document Amount in Purchase Journal has a value of 3 decimal places.
        Assert.AreEqual(
            DocumentAmount,
            PurchaseJournal.DocumentAmount.AsDecimal(),
            StrSubstNo(
                DocumentAmountLogicErr,
                DocumentAmount,
                PurchaseJournal.DocumentAmount.AsDecimal()));
    end;

    [Test]
    procedure CheckSalesPurchaseLCYWhenlineAmountLessThanVATAmount()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        VatPostingSetup: Record "VAT Posting Setup";
        DocumnetNo: Code[20];
    begin
        // [SCENARIO 575956] Issue preventing General Journal posting when a line amount is less than the VAT amount triggering the error: 'Sales/Purch. (LCY) 
        // must have the same sign as Amount.
        Initialize();

        // [GIVEN] Create a Customer and Find VAT Posting Setup that have VAT 25%.
        LibrarySales.CreateCustomer(Customer);
        FindVATPostingSetup(VatPostingSetup);

        // [GIVEN] Create two G/L Accounts with Direct Posting enabled.
        GLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());
        GLAccount.Validate("VAT Bus. Posting Group", VatPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VatPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        GLAccount2.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [GIVEN] Create document number for General Journal Line and Select General Journal Batch.
        DocumnetNo := LibraryRandom.RandText(20);
        SelectGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create First General Journal Line with Document Type = Invoice, Gen. Posting Type = Sale, Amount = -1000, VAT Bus. Posting Group and VAT Prod. Posting Group.
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, GLAccount."No.", GenJournalLine."Document Type"::Invoice,
            -1000, '', GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Document No.", DocumnetNo);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Sale);
        ValidateGenProdPostingGroup(GenJournalLine, VatPostingSetup);
        GenJournalLine.Validate("VAT Bus. Posting Group", VatPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VatPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Modify(true);

        // [GIVEN] Create Second General Journal Line with Document Type = Invoice, Gen. Posting Type = Sale, Amount = 850, VAT Bus. Posting Group and VAT Prod. Posting Group.
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, GLAccount2."No.", GenJournalLine."Document Type"::Invoice,
            850, '', GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Document No.", DocumnetNo);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Sale);
        ValidateGenProdPostingGroup(GenJournalLine, VatPostingSetup);
        GenJournalLine.Validate("VAT Bus. Posting Group", '');
        GenJournalLine.Validate("VAT Prod. Posting Group", VatPostingSetup."VAT Prod. Posting Group");
        if Not VatPostingSetup.Get(GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group") then
            LibraryERM.CreateVATPostingSetup(VatPostingSetup, GenJournalLine."VAT Bus. Posting Group", GenJournalLine."VAT Prod. Posting Group");
        GenJournalLine.Validate("VAT %", 0);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Modify(true);

        // [WHEN] Create Third General Journal Line with Document Type = Invoice, Gen. Posting Type = Sale, Amount = 150, VAT Bus. Posting Group and VAT Prod. Posting Group.
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, Customer."No.", GenJournalLine."Document Type"::Invoice,
            150, '', GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Document No.", DocumnetNo);
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Modify(true);

        // [THEN] Check that Sales/Purch. (LCY) is the same as Amount (LCY) And Post General journal Lines without error.
        Assert.AreEqual(
            Round(GenJournalLine."Amount (LCY)" - GenJournalLine."VAT Amount (LCY)", 0.01), GenJournalLine."Sales/Purch. (LCY)", SalesPurchErr);
        GenJournalLine2.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine2.FindSet();
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        GenJnlManagement: Codeunit "GenJnlManagement";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales/Purchase Application");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        GenJnlManagement.SetJournalSimplePageModePreference(true, Page::"Sales Journal");
        GenJnlManagement.SetJournalSimplePageModePreference(true, Page::"Purchase Journal");
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales/Purchase Application");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales/Purchase Application");
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        Customer.SetRange("Currency Code", '');
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(5, 2) * 1000);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2) * 1000);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithPaymentTerm(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CurrencyCode: Code[10]; AccountType: Enum "Gen. Journal Account Type")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms"; CalcPmtDiscOnCrMemos: Boolean)
    begin
        // Take Random amount for Discount % and Discount Date Calculation.
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, CalcPmtDiscOnCrMemos);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPaymentTerm(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostCustomerEntries(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApplyCustEntryDocumentType: Enum "Gen. Journal Document Type";
        ApplyCustEntryDocumentType2: Enum "Gen. Journal Document Type";
    begin
        // Create and Post Invoice,Credit Memo and create Payment.
        // Take Random Amount on Gen. Journal Line.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, FindCashReceiptTemplate());
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateCustomer(), GenJournalLine."Document Type"::Invoice,
          LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Customer);
        ModifyGenLineBalAccountNo(GenJournalLine);
        ApplyCustEntryDocumentType := GenJournalLine."Document Type";

        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::"Credit Memo",
          -GenJournalLine.Amount, '', GenJournalLine."Account Type");
        ModifyGenLineBalAccountNo(GenJournalLine);
        ApplyCustEntryDocumentType2 := GenJournalLine."Document Type";

        LibraryVariableStorage.Enqueue(ApplyCustEntryDocumentType2);
        LibraryVariableStorage.Enqueue(ApplyCustEntryDocumentType);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalBatch."Journal Template Name");
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment,
          0, '', GenJournalLine."Account Type");
    end;

    local procedure CreateGeneralBatchAndTemplate(Type: Enum "Gen. Journal Template Type"): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        exit(GenJournalBatch.Name);
    end;

    local procedure CreateAndPostMultipleJnlLinesWithTwoCrMemos(var PaymentNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Sign: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          AccountType, AccountNo, Sign * LibraryRandom.RandDecInRange(100, 200, 2));
        InvAmount += GenJournalLine.Amount;
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::"Credit Memo",
          AccountType, AccountNo, GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.",
          Sign * LibraryRandom.RandDecInRange(100, 200, 2));
        InvAmount += GenJournalLine.Amount;
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.",
          Sign * LibraryRandom.RandDecInRange(100, 200, 2));
        InvAmount += GenJournalLine.Amount;
        PaymentNo := GenJournalLine."Document No.";
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.",
          -InvAmount);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostCustMultipleJnlLines(var PaymentNo: Code[20]; CustomerNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostMultipleJnlLinesWithTwoCrMemos(PaymentNo, GenJournalLine."Account Type"::Customer, CustomerNo, -1);
    end;

    local procedure CreateAndPostVendMultipleJnlLines(var PaymentNo: Code[20]; VendorNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostMultipleJnlLinesWithTwoCrMemos(PaymentNo, GenJournalLine."Account Type"::Vendor, VendorNo, 1);
    end;

    local procedure FindCashReceiptTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Find existing Cash Receipt Templates.
        // Take CASHRCPT as Applies-to Doc. No. field is available on this journal.
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.FindFirst();
        exit(GenJournalTemplate.Name);
    end;

    local procedure ModifyGenLineBalAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure ModifyGenLinePostingDate(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure OpenAndVerifyCustLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; OriginalPmtDiscPossible: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Exercise.
        OpenCustLedgerEntryPage(DocumentType, GenJournalLine."Account No.");

        // Verify: Verify Payment Discount amount on Customer Ledger Entry.
        GeneralLedgerSetup.Get();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType2, DocumentNo);
        Assert.AreNearlyEqual(
          OriginalPmtDiscPossible, CustLedgerEntry."Original Pmt. Disc. Possible", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption("Remaining Amount"), OriginalPmtDiscPossible,
            CustLedgerEntry.TableCaption()));
    end;

    local procedure OpenAndVerifyVendorLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; OriginalPmtDiscPossible: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Exercise.
        OpenVendorLedgerEntryPage(DocumentType, GenJournalLine."Account No.");

        // Verify: Verify Payment Discount amount on Vendor Ledger Entry.
        GeneralLedgerSetup.Get();
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType2, DocumentNo);
        Assert.AreNearlyEqual(
          OriginalPmtDiscPossible, VendorLedgerEntry."Original Pmt. Disc. Possible", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, VendorLedgerEntry.FieldCaption("Remaining Amount"), OriginalPmtDiscPossible,
            VendorLedgerEntry.TableCaption()));
    end;

    local procedure OpenCustLedgerEntryPage(DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20])
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustomerNo);
        CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    local procedure OpenSalesAnalysisMatrix(RoundingFactor: Option; AnalysisViewCode: Code[10])
    var
        Item: Record Item;
        SalesAnalysisByDimensions: TestPage "Sales Analysis by Dimensions";
    begin
        // Exercise. Open Show Matrix page by Sales Analysis by Dimension Page.
        SalesAnalysisByDimensions.OpenEdit();
        SalesAnalysisByDimensions.CurrentItemAnalysisViewCode.SetValue(AnalysisViewCode);
        SalesAnalysisByDimensions.LineDimCode.SetValue(Item.TableCaption());
        SalesAnalysisByDimensions.RoundingFactor.SetValue(RoundingFactor);
        SalesAnalysisByDimensions.ShowMatrix_Process.Invoke();
    end;

    local procedure OpenVendorLedgerEntryPage(DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20])
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        VendorLedgerEntries.OpenView();
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        VendorLedgerEntries.FILTER.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntries.ActionApplyEntries.Invoke();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SetupSalesAnalysisMatrix(var SalesLine: Record "Sales Line"): Code[10]
    var
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisViewListSales: TestPage "Analysis View List Sales";
    begin
        // Create and Post Sales Invoice and Update Item analysis through page.
        ItemAnalysisView.SetRange("Analysis Area", ItemAnalysisView."Analysis Area"::Sales);
        ItemAnalysisView.FindFirst();

        CreateAndPostSalesInvoice(SalesLine);

        AnalysisViewListSales.OpenView();
        AnalysisViewListSales.FILTER.SetFilter(Code, ItemAnalysisView.Code);
        AnalysisViewListSales."&Update".Invoke();
        exit(ItemAnalysisView.Code);
    end;

    local procedure SetJournalLineAppliesToDocNo(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; BatchName: Code[10])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // Open Cash Receipt Journal page for lookup on applies to Doc. no. field.
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue := BatchName;
        CashReceiptJournal.FILTER.SetFilter("Document Type", Format(DocumentType));
        CashReceiptJournal.FILTER.SetFilter("Document No.", DocumentNo);
        CashReceiptJournal."Applies-to Doc. No.".Lookup();
        CashReceiptJournal.OK().Invoke();
    end;

    local procedure GetPaymentTermsDiscountPercentage(PaymentTerms: Record "Payment Terms"): Decimal
    begin
        exit(LibraryERM.GetPaymentTermsDiscountPct(PaymentTerms));
    end;

    local procedure SetupVendorWithTwoPostedDocuments(var Vendor: Record Vendor)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostJournalLine(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          Vendor."No.", -LibraryRandom.RandIntInRange(1000, 5000));
        CreateAndPostJournalLine(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
          Vendor."No.", LibraryRandom.RandIntInRange(100, 500));
    end;

    local procedure SetupCustomerWithTwoPostedDocuments(var Customer: Record Customer)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostJournalLine(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          Customer."No.", LibraryRandom.RandIntInRange(1000, 5000));
        CreateAndPostJournalLine(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
          Customer."No.", -LibraryRandom.RandIntInRange(100, 999));
    end;

    local procedure CreateAndPostJournalLine(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType, AccountType, AccountNo, LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomerWithApplicationMethod(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibrarySales.CreateCustomer(Customer);

        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify();
    end;

    local procedure CreateandPostSalesOrder(CustomerNo: Code[20]; var Amount: Decimal)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);

        Amount := SalesLine.Amount;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields("Remaining Amount");
            Assert.AreEqual(0, CustLedgerEntry."Remaining Amount", RemainingAmountErr);
            Assert.AreEqual(false, CustLedgerEntry.Open, CustLedgerEntryOpenErr);
        until CustLedgerEntry.Next() = 0;
    end;

    procedure FindVATPostingSetup(var VatPostingSetup: Record "VAT Posting Setup")
    begin
        // Find VAT Posting Setup for the test.
        VatPostingSetup.SetRange("VAT %", 25);
        if not VatPostingSetup.FindFirst() then
            LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 25);
    end;

    local procedure ValidateGenProdPostingGroup(var GenJournalLine: Record "Gen. Journal Line"; VatPostingSetup: Record "VAT Posting Setup")
    var
        GenProdPosting: Record "Gen. Product Posting Group";
    begin
        if GenJournalLine."Gen. Prod. Posting Group" = '' then begin
            GenProdPosting.setrange("Def. VAT Prod. Posting Group", VatPostingSetup."VAT Prod. Posting Group");
            if GenProdPosting.FindFirst() then
                GenJournalLine.Validate("Gen. Prod. Posting Group", GenProdPosting.Code)
            else begin
                LibraryERM.CreateGenProdPostingGroup(GenProdPosting);
                GenProdPosting.Validate("Def. VAT Prod. Posting Group", VatPostingSetup."VAT Prod. Posting Group");
                GenProdPosting.Modify(true);
                GenJournalLine.Validate("Gen. Prod. Posting Group", GenProdPosting.Code);
            end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.AppliesToID.AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntriesOKPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        // Modal Page Handler.
        // Using Case to handle consecutive Modal Page Handlers.

        case LibraryVariableStorage.DequeueInteger() of
            1:
                begin
                    ApplyCustomerEntries."Document Type".AssertEquals(LibraryVariableStorage.DequeueInteger());
                    ApplyCustomerEntries.Next();
                    ApplyCustomerEntries."Document Type".AssertEquals(LibraryVariableStorage.DequeueInteger());
                end;
            2:
                asserterror ApplyCustomerEntries."Document Type".AssertEquals(LibraryVariableStorage.DequeueInteger());
        end;
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        LibraryVariableStorage.Enqueue(ApplyCustomerEntries.AppliedAmount.Value);
        LibraryVariableStorage.Enqueue(ApplyCustomerEntries.ApplyingAmount.Value);
        LibraryVariableStorage.Enqueue(ApplyCustomerEntries.ControlBalance.Value);
        LibraryVariableStorage.Enqueue(ApplyCustomerEntries.ApplnCurrencyCode.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.AppliesToID.AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        LibraryVariableStorage.Enqueue(ApplyVendorEntries.AppliedAmount.Value);
        LibraryVariableStorage.Enqueue(ApplyVendorEntries.ApplyingAmount.Value);
        LibraryVariableStorage.Enqueue(ApplyVendorEntries.ControlBalance.Value);
        LibraryVariableStorage.Enqueue(ApplyVendorEntries.ApplnCurrencyCode.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyPostCustEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndApplyVendorPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: Page "Post Application"; var Response: Action)
    begin
        // Modal Page Handler.
        Response := ACTION::OK
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MatixPageHandler(var SalesAnalysisByDimMatrix: TestPage "Sales Analysis by Dim Matrix")
    begin
        SalesAnalysisByDimMatrix.FindFirstField(Code, LibraryVariableStorage.DequeueText());
        SalesAnalysisByDimMatrix.TotalQuantity.AssertEquals(-LibraryVariableStorage.DequeueDecimal());
        SalesAnalysisByDimMatrix.TotalInvtValue.AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactDuplicatesModalPageHandler(var ContactDuplicates: TestPage "Contact Duplicates")
    begin
        ContactDuplicates.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DuplicateContactFoundConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage('Duplicate Contacts were found', Question);
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        VendorLedgerEntries.Last();
        VendorLedgerEntries.ActionApplyEntries.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        CustomerLedgerEntries.Last();
        CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesClearsAppliesToIdPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries."Amount to Apply".SetValue := LibraryRandom.RandDec(100, 2);
        ApplyVendorEntries.AppliesToID.AssertEquals(UserId);

        ApplyVendorEntries."Amount to Apply".SetValue := 0;
        ApplyVendorEntries.AppliesToID.AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntriesClearsAppliesToIdPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Amount to Apply".SetValue := -LibraryRandom.RandDec(100, 2);
        ApplyCustomerEntries.AppliesToID.AssertEquals(UserId);

        ApplyCustomerEntries."Amount to Apply".SetValue := 0;
        ApplyCustomerEntries.AppliesToID.AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageClearsAmountToApplyPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        AmountToApply: Decimal;
    begin
        AmountToApply := LibraryRandom.RandDecInRange(1, 50, 2);
        ApplyVendorEntries."Amount to Apply".SetValue := AmountToApply;
        ApplyVendorEntries."Amount to Apply".AssertEquals(AmountToApply);

        ApplyVendorEntries."Amount to Apply".SetValue := 0;
        ApplyVendorEntries."Amount to Apply".AssertEquals(0);

        AmountToApply := LibraryRandom.RandDecInRange(1, 50, 2);
        ApplyVendorEntries."Amount to Apply".SetValue := AmountToApply;
        ApplyVendorEntries."Amount to Apply".AssertEquals(AmountToApply);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntriesPageClearsAmountToApplyPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AmountToApply: Decimal;
    begin
        AmountToApply := -LibraryRandom.RandDecInRange(100, 200, 2);
        ApplyCustomerEntries."Amount to Apply".SetValue := AmountToApply;
        ApplyCustomerEntries."Amount to Apply".AssertEquals(AmountToApply);

        ApplyCustomerEntries."Amount to Apply".SetValue := 0;
        ApplyCustomerEntries."Amount to Apply".AssertEquals(0);

        AmountToApply := -LibraryRandom.RandDecInRange(1, 50, 2);
        ApplyCustomerEntries."Amount to Apply".SetValue := AmountToApply;
        ApplyCustomerEntries."Amount to Apply".AssertEquals(AmountToApply);
    end;
}

