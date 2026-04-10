codeunit 134007 "ERM Apply Unapply Vendor"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Apply] [Unapply] [Purchase]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AdditionalCurrencyErr: Label 'Additional Currency Amount must be %1.', Locked = true;
        TotalAmountErr: Label 'Total Amount must be %1 in %2 table for %3 field : %4.', Locked = true;
        UnappliedErr: Label '%1 must be %2 in %3.', Locked = true;
        AmountErr: Label '%1 must be %2 in %3.', Locked = true;
        UnapplyExchangeRateErr: Label 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.', Locked = true;
        MessageDoNotMatchErr: Label 'Error Message must be same.';
        DateCompressUnapplyErr: Label 'The entry cannot be unapplied, because the %1 has been compressed.', Locked = true;
        ApplicationEntryErr: Label '%1 %2 does not have an application entry.', Comment = '%1 = FIELD Caption, %2 = FIELD Value';
        DetailedVendorLedgerErr: Label 'Detailed Vendor Ledger Entry Must Found.';
        GeneralJournalErr: Label 'General Journal Line Must Exist.';
        NegativeAmountErr: Label 'Amount must be positive in General Journal Line.';
        WrongFieldErr: Label 'Wrong value of field %1 in table %2.', Locked = true;
        UnnecessaryVATEntriesFoundErr: Label 'Unnecessary VAT Entries found.';
        NonzeroACYErr: Label 'Non-zero Additional-Currency Amount in G/L Entry.';
        GLEntryCntErr: Label 'Wrong count of created G/L Entries.';
        DimBalanceErr: Label 'Wrong balance by Dimension.';
        OptionValue: Integer;
        AppliesToExtDocNoErr: Label 'Applies to Ext. Doc No. must be empty.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendorPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
        Amount: Decimal;
    begin
        // Verify Additional Currency, Remaining Amount and Entries unapplied after Applying and then Unapplying Payment Entries for Vendor.

        // Setup: Update General Ledger Setup and take Random Amount greater than 100 (Standard Value)
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        Amount := -100 * LibraryRandom.RandInt(10);
        LibraryERM.SetAddReportingCurrency(CreateCurrency(0));

        ApplyUnapplyVendorEntries(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, NoOfLines, Amount,
          -Amount / NoOfLines);

        // Verify: Verify Remaining Amount, Unapplied Entries and Additional Currency Amount after unapplying entries.
        VerifyRemainingAmount(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyUnappliedEntries(GenJournalLine."Document No.", GenJournalLine."Account No.");
        VerifyAdditionalCurrencyAmount(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyApplyVendorPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Additional Currency Amount, Detailed Vendor Ledger Entry after Unapplying, Applying Payment Entries Again for Vendor.

        // Setup: Update General Ledger Setup and take Random Amount greater than 100 (Standard Value)
        Initialize();
        ApplyUnapplySeveralVendorEntries(
          -1, GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment);

        // Verify: Verify Detailed Ledger Entries and Additional Currency Amount after Re-applying Entries.
        VerifyDetailedLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Account No.");
        VerifyAdditionalCurrencyAmount(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyVendorRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Additional Currency, Remaining Amount and Entries unapplied after Applying and then Unapplying Payment Entries for Vendor.

        // Setup: Update General Ledger Setup and take Random Amount greater than 100 (Standard Value)
        Initialize();
        ApplyUnapplySeveralVendorEntries(
          1, GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund);

        // Verify: Verify Remaining Amount, Unapplied Entries and Additional Currency Amount after unapplying entries.
        VerifyRemainingAmount(GenJournalLine."Document Type"::Refund, GenJournalLine."Document No.");
        VerifyUnappliedEntries(GenJournalLine."Document No.", GenJournalLine."Account No.");
        VerifyAdditionalCurrencyAmount(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyApplyVendorRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
        Amount: Decimal;
    begin
        // Verify Additional Currency Amount, Detailed Vendor Ledger Entry after Unapplying, Applying Payment Entries Again for Vendor.

        // Setup: Update General Ledger Setup and take Random Amount greater than 100 (Standard Value)
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        Amount := 100 * LibraryRandom.RandInt(10);
        LibraryERM.SetAddReportingCurrency(CreateCurrency(0));
        ApplyUnapplyVendorEntries(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, NoOfLines, Amount,
          -Amount / NoOfLines);

        // Verify: Verify Detailed Ledger Entries and Additional Currency Amount after Re-applying Entries.
        VerifyDetailedLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Account No.");
        VerifyAdditionalCurrencyAmount(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingAmtOnInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Amount on Vendor Ledger Entry After Posting Invoice and Payment with Different
        // Currency before Unapply.
        RoundingAmtOnVendorEntries(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -LibraryRandom.RandDecInRange(100, 200, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingAmtOnCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Amount on Vendor Ledger Entry After Posting Credit Memo and Refund with Different
        // Currency before Unapply.
        RoundingAmtOnVendorEntries(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, LibraryRandom.RandDec(100, 2));
    end;

    local procedure RoundingAmtOnVendorEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        AppRounding: Decimal;
    begin
        // Setup: Create Invoice and Payment General Line with Different Currency.
        Initialize();
        AppRounding := LibraryRandom.RandDec(10, 2);
        CreateGenLineAndApply(GenJournalLine, DocumentType, DocumentType2, AppRounding, Amount);

        // Verify: Verify Vendor Ledger Entry for Application Rounding Amount before Unapply.
        VerifyApplnRoundingVendLedger(
          DetailedVendorLedgEntry."Entry Type"::"Appln. Rounding", GenJournalLine."Document No.", AppRounding,
          GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingAmtOnUnappliedInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Amount and Unapplied Entries on Detailed Vendor Ledger Entry After Posting Invoice
        // and Payment with Different Currency After Unapply.
        RoundingAmtOnUnappliedEntries(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -LibraryRandom.RandDecInRange(100, 200, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingAmtOnUnappliedCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Amount on Vendor Ledger Entry After Posting Credit Memo and Refund with Different
        // Currency After Unapply.
        RoundingAmtOnUnappliedEntries(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, LibraryRandom.RandDec(100, 2));
    end;

    local procedure RoundingAmtOnUnappliedEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        AppRounding: Decimal;
    begin
        // Setup: Create Invoice and Payment General Line with Different Currency.
        Initialize();
        AppRounding := LibraryRandom.RandDec(10, 2);
        CreateGenLineAndApply(GenJournalLine, DocumentType, DocumentType2, AppRounding, Amount);
        UnapplyVendorLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify Vendor Ledger Entry for Application Roudning And Unapplied Entries after Unapply.
        VerifyApplnRoundingVendLedger(
          DetailedVendorLedgEntry."Entry Type"::"Appln. Rounding", GenJournalLine."Document No.", AppRounding,
          GenJournalLine."Account No.");
        VerifyUnappliedEntries(GenJournalLine."Document No.", GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentCheckSourceCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that correct Source Code updated on Detailed Vendor Ledger Entry after Unapply Payment from Vendor Ledger Entry.
        // Use Random Number Generator for Amount.
        Initialize();
        ApplyUnapplyAndCheckSourceCode(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefundCheckSourceCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that correct Source Code updated on Detailed Vendor Ledger Entry after Unapply Refund from Vendor Ledger Entry.
        // Use Random Number Generator for Amount.
        Initialize();
        ApplyUnapplyAndCheckSourceCode(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, LibraryRandom.RandDec(100, 2));
    end;

    local procedure ApplyUnapplyAndCheckSourceCode(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        SourceCode: Record "Source Code";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create Source Code, update Source Code Setup, create and post General Journal Lines.
        LibraryERM.CreateSourceCode(SourceCode);
        SetUnapplPurchEntryApplnSourceCode(SourceCode.Code);
        ApplyUnapplyVendorEntries(GenJournalLine, DocumentType, DocumentType2, 1, Amount, -Amount);

        // Verify: Verify correct Source Code updated on Detailed Vendor Ledger Entry.
        VerifySourceCodeDtldCustLedger(DocumentType2, GenJournalLine."Document No.", SourceCode.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPmtAfterUnapply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        Amount: Decimal;
    begin
        // Test that the Suggest Vendor Payment Batch Job works the same way with unapplied entries.

        // Setup: Create Bank Account, create and post General Journal Lines.
        // Use Random Number Generator for Amount.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateBankAccount(BankAccount);

        ApplyUnapplyVendorEntries(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, 1, -Amount, Amount / 2);

        // Exercise.
        SuggestVendorPayment(GenJournalLine, BankAccount."No.");

        // Verify: Verify correct Amount updated on General Journal Line after running Suggest Vendor Payment Batch Job.
        VerifyGenJournalEntry(GenJournalLine, Amount - GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeExchRateUnapplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Payment cannot be Unapplied after Exchange Rate has been changed.
        // Use Random Nunber Generator for Amount.
        Initialize();

        ChangeExchRateUnapply(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeExchRateUnapplyRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Refund cannot be Unapplied after Exchange Rate has been changed.
        // Use Random Nunber Generator for Amount.
        Initialize();
        ChangeExchRateUnapply(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, LibraryRandom.RandInt(500));
    end;

    local procedure ChangeExchRateUnapply(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        PostingDate: Date;
    begin
        // Setup: Update General Ledger Setup, Create and post General Journal Lines.
        LibraryERM.SetAddReportingCurrency(CreateCurrency(0));
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'M>', WorkDate());
        CreatePostApplyGenJournalLine(GenJournalLine, DocumentType, DocumentType2, Amount, WorkDate());
        CreateNewExchangeRate(PostingDate);
        FindDetailedLedgerEntry(
          DetailedVendorLedgEntry, DetailedVendorLedgEntry."Entry Type"::Application, GenJournalLine."Document No.",
          GenJournalLine."Account No.");

        // Exercise: Unapply Payment/Refund from Vendor Ledger Entry.
        ApplyUnapplyParameters."Document No." := GenJournalLine."Document No.";
        ApplyUnapplyParameters."Posting Date" := PostingDate;
        asserterror VendEntryApplyPostedEntries.PostUnApplyVendor(DetailedVendorLedgEntry, ApplyUnapplyParameters);

        // Verify: Verify error on Unapply after Exchange Rate has been changed.
        Assert.AreEqual(StrSubstNo(UnapplyExchangeRateErr, WorkDate()), GetLastErrorText, MessageDoNotMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDocumentNoUnapplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Document No can be change when Unapply Payment from Vendor Ledger Entry.
        // Use Random Nunber Generator for Amount.
        Initialize();
        ChangeDocumentNoAndUnapply(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDocumentNoUnapplyRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Document No can be change when Unapply Refund from Vendor Ledger Entry.
        // Use Random Nunber Generator for Amount.
        Initialize();
        ChangeDocumentNoAndUnapply(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, LibraryRandom.RandInt(500));
    end;

    local procedure ChangeDocumentNoAndUnapply(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        GenJournalLine: Record "Gen. Journal Line";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post General Journal Lines.
        CreatePostApplyGenJournalLine(GenJournalLine, DocumentType, DocumentType2, Amount, WorkDate());
        FindDetailedLedgerEntry(
          DetailedVendorLedgEntry, DetailedVendorLedgEntry."Entry Type"::Application, GenJournalLine."Document No.",
          GenJournalLine."Account No.");
        DocumentNo := GenJournalLine."Account No.";

        // Exercise: Change Document No and Unapply Payment/Refund from Vendor Ledger Entry.
        ApplyUnapplyParameters."Document No." := GenJournalLine."Account No.";
        ApplyUnapplyParameters."Posting Date" := GenJournalLine."Posting Date";
        VendEntryApplyPostedEntries.PostUnApplyVendor(DetailedVendorLedgEntry, ApplyUnapplyParameters);

        // Verify: Check Detailed Vendor Ledger Entry with updated Document No exist after Unapply.
        FindDetailedLedgerEntry(DetailedVendorLedgEntry, DetailedVendorLedgEntry."Entry Type"::Application, DocumentNo, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyDateCompressVendLedger()
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DateComprRegister: Record "Date Compr. Register";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        FirstPostingDate: Date;
    begin
        // Check error when Unapplying Vendor Ledger entry which have been Date Compressed.

        // Setup: Create and post General Journal Lines, find Closed Fiscal Year, Date Compress the Vendor Ledger Entry.
        Initialize();
        FirstPostingDate := LibraryFiscalYear.GetFirstPostingDate(true);
        LibraryFiscalYear.CheckPostingDate(FirstPostingDate);
        CreatePostApplyGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          -LibraryRandom.RandDec(100, 2), FirstPostingDate);
        DateCompressForVendor(GenJournalLine, FirstPostingDate, DateComprRegister."Period Length"::Day);
        FindDetailedLedgerEntry(
          DetailedVendorLedgEntry, DetailedVendorLedgEntry."Entry Type"::Application, '', GenJournalLine."Account No.");

        // Exercise: Unapply Vendor Ledger Entry Which have been Date Compress.
        ApplyUnapplyParameters."Document No." := GenJournalLine."Account No.";
        ApplyUnapplyParameters."Posting Date" := GenJournalLine."Posting Date";
        asserterror VendEntryApplyPostedEntries.PostUnApplyVendor(DetailedVendorLedgEntry, ApplyUnapplyParameters);

        // Verify: Verify error when Unapplying Vendor Ledger entry which have been Date Compress.
        Assert.AreEqual(StrSubstNo(DateCompressUnapplyErr, VendorLedgerEntry.TableCaption()), GetLastErrorText, MessageDoNotMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyInvFromVendorLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Invoice from Vendor Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromVendorLedger(GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentVendorLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Payment from Vendor Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromVendorLedger(GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCrMemoVendorLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Credit Memo from Vendor Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromVendorLedger(GenJournalLine."Document Type"::"Credit Memo", LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefundVendorLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Refund from Vendor Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromVendorLedger(GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure UnapplyFromVendorLedger(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        // Setup: Create Vendor, Create and post General Journal  Line.
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGenJournalLine(GenJournalLine, Vendor."No.", DocumentType, Amount, '', WorkDate());
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, GenJournalLine."Document No.");

        // Exercise: Unapply Document from Vendor Ledger Entry.
        asserterror VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendorLedgerEntry."Entry No.");

        // Verify: Verify error when Unapplying Document from Vendor Ledger Entry.
        Assert.AreEqual(
          StrSubstNo(ApplicationEntryErr, DetailedVendorLedgEntry.FieldCaption("Vendor Ledger Entry No."),
            VendorLedgerEntry."Entry No."), GetLastErrorText, MessageDoNotMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyInvDtldVendorLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Invoice from Detailed Vendor Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromDtldVendorLedger(GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentDtldVendorLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Payment from Detailed Vendor Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromDtldVendorLedger(GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCrMemoDtVendorLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Credit Memo from Detailed Vendor Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromDtldVendorLedger(GenJournalLine."Document Type"::"Credit Memo", LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefundDtldVendorLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Refund from Detailed Vendor Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromDtldVendorLedger(GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure UnapplyFromDtldVendorLedger(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
    begin
        // Setup: Create Vendor, Create and post General Journal  Line.
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGenJournalLine(GenJournalLine, Vendor."No.", DocumentType, Amount, '', WorkDate());
        FindDetailedLedgerEntry(
          DetailedVendorLedgEntry, DetailedVendorLedgEntry."Entry Type"::"Initial Entry", GenJournalLine."Document No.",
          GenJournalLine."Account No.");

        // Exercise: Unapply Document from Detailed Vendor Ledger Entry.
        asserterror VendEntryApplyPostedEntries.UnApplyDtldVendLedgEntry(DetailedVendorLedgEntry);

        // Verify: Verify error when Unapplying Document from Detailed Vendor Ledger Entry.
        Assert.ExpectedTestFieldError(DetailedVendorLedgEntry.FieldCaption("Entry Type"), Format(DetailedVendorLedgEntry."Entry Type"::Application));
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure RemainingAmtOnVendorLedgerEntryWithoutCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
        PaymentTolerance: Decimal;
    begin
        // Check Remaining Amount on Vendor Ledger Entry after Creating and Posting Purchase Invoice without Currency and Apply with Partial Payment.

        // Setup: Create and Post Purchase Invoice, Create a Vendor Payment and apply it to posted Invoice.
        Initialize();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        PaymentTolerance := LibraryRandom.RandDec(10, 2);  // Using Random value for Payment Tolerance.
        SetPaymentTolerancePct(PaymentTolerance);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreateAndModifyPurchaseLine(PurchaseHeader);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGeneralJournalLine(GenJournalLine, 1, Vendor."No.", GenJournalLine."Document Type"::Payment, 0);  // Taken 1 and 0 to create only one General Journal line with zero amount.
        Amount := OpenGeneralJournalPage(GenJournalLine."Document No.", GenJournalLine."Document Type");

        // Exericse.
        LibraryLowerPermissions.SetAccountPayables();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Remaining Amount on Vendor Ledger Entry.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, PurchaseHeader."Document Type", PostedDocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmtOnVendorLedgerEntryWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
        PaymentTolerance: Decimal;
    begin
        // Check Remaining Amount on Vendor Ledger Entry after Creating and Posting Purchase Invoice with Currency and Apply with Partial Payment.

        // Setup: Create and Post Purchase Invoice with Currency, Create a Vendor Payment without Currency and apply it to posted Invoice after modifying Payment Amount.
        Initialize();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        PaymentTolerance := LibraryRandom.RandDec(10, 2);  // Using Random value for Payment Tolerance.
        SetPaymentTolerancePct(PaymentTolerance);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency(LibraryRandom.RandDec(10, 2)));
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        Amount := CreateAndModifyPurchaseLine(PurchaseHeader);
        Amount := LibraryERM.ConvertCurrency(Amount, PurchaseHeader."Currency Code", '', WorkDate());
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGeneralJournalLine(GenJournalLine, 1, Vendor."No.", GenJournalLine."Document Type"::Payment, 0);  // Taken 1 and 0 to create only one General Journal line with zero amount.
        UpdateGenJournalLine(GenJournalLine, '', PostedDocumentNo, Amount);

        // Exericse.
        LibraryLowerPermissions.SetAccountPayables();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Remaining Amount on Vendor Ledger Entry.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, PurchaseHeader."Document Type", PostedDocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);  // Taken 0 for Remaining Amount as after application it must be zero due to Currency's Appln. Rounding Precision.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderUsingPaymentMethodWithBalanceAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Check General Ledger, Vendor Ledger and Detailed Vendor ledger entries after Posting Purchase Order with Currency and Payment method with a balance account.

        // Setup: Modify General Ledger setup for Appln. Rounding Precision and Create Vendor with Currency and with Payment method with a balance account.
        Initialize();
        SetApplnRoundingPrecision(LibraryRandom.RandDec(10, 2));  // Taken Random value for Rounding Precision.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency(0));  // Taken 0 value for Rounding Precision.
        Vendor.Validate("Payment Method Code", FindPaymentMethodWithBalanceAccount());
        Vendor.Modify(true);

        // Exercise: Create and post Purchase Order with Random Quantity and Direct Unit Cost.
        LibraryLowerPermissions.AddAccountPayables();
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, WorkDate(), Vendor."No.", LibraryInventory.CreateItemNo(), PurchaseHeader."Document Type"::Order,
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));

        // Verify: Verify GL, Vendor and Detailed Vendor ledger entries.
        VerifyEntriesAfterPostingPurchaseDocument(VendorLedgerEntry."Document Type"::Payment, DocumentNo, DocumentNo, Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyPaymentMethodCodeInVendLedgEntryClosed()
    var
        Vendor: Record Vendor;
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", FindPaymentMethodWithBalanceAccount());
        Vendor.Modify(true);

        // Exercise: Create and post Sales Order.
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchLine, WorkDate(), Vendor."No.", LibraryInventory.CreateItemNo(), PurchHeader."Document Type"::Order,
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));

        // Verify: Try to modify Payment Method Code in Vendor Ledger Entry.
        VerifyErrorAfterModifyPaymentMethod(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocumentUsingApplicationMethodApplyToOldest()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Check General Ledger, Vendor Ledger and Detailed Vendor ledger entries after posting Purchase documents with Currency and Apply to Oldest Application Method.

        // Setup: Modify General Ledger setup for Appln. Rounding Precision and Create Vendor with Currency and with Apply to Oldest Application Method, Create and post Purchase Invoice with Random Quantity and Direct Unit Cost.
        Initialize();
        SetApplnRoundingPrecision(LibraryRandom.RandDec(10, 2));  // Taken Random value for Rounding Precision.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency(LibraryRandom.RandDec(10, 2)));  // Taken Random value for Rounding Precision.
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Modify(true);
        LibraryInventory.CreateItem(Item);
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, WorkDate(), Vendor."No.", Item."No.", PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandDec(10, 2),
            LibraryRandom.RandDec(100, 2));

        // Exercise: Create and post Purchase Credit Memo.
        DocumentNo2 :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, WorkDate(), Vendor."No.", Item."No.", PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine.Quantity,
            PurchaseLine."Direct Unit Cost");

        // Verify: Verify GL, Vendor and Detailed Vendor ledger entries.
        VerifyEntriesAfterPostingPurchaseDocument(VendorLedgerEntry."Document Type"::"Credit Memo", DocumentNo, DocumentNo2, Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler,PaymentToleranceWarning')]
    [Scope('OnPrem')]
    procedure ApplyAndUnapplyPaymentJournal()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldAdjustforPaymentDiscount: Boolean;
    begin
        // Verify VAT Amount on G/L Entry after Unappling Payment from Vendor Ledger Entry.

        // Setup: Modify General Ledger Setup,VAT Posting Setup and Create Vendor With Payment Terms.Post Purchase Invoice and Payment Line.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryPmtDiscSetup.SetPmtTolerance(LibraryRandom.RandDec(100, 2));
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        OldAdjustforPaymentDiscount := SetAdjustForPaymentDiscInVATPostingSetup(VATPostingSetup, true);
        CreateAndPostPurchaseOrder(PurchaseHeader, VATPostingSetup);
        CreateGeneralJournalLine(GenJournalLine, 1, PurchaseHeader."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, 0);  // Taken 1 and 0 to create only one General Journal line with zero amount.
        OpenGeneralJournalPage(GenJournalLine."Document No.", GenJournalLine."Document Type");  // Open General Journal Page and apply to above Posted Purchase Invoice.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Unapply Vendor Entries.
        LibraryLowerPermissions.SetAccountPayables();
        UnapplyVendorLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify VAT Amount on G/L Entry.
        VerifyVATAmountOnGLEntry(GenJournalLine);

        LibraryLowerPermissions.SetOutsideO365Scope();
        // TearDown: Cleanup of setup done.
        SetAdjustForPaymentDiscInVATPostingSetup(VATPostingSetup, OldAdjustforPaymentDiscount);
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler,ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AmountToApplyAfterApplyToEntryForInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Verify Amount To Apply on Vendor Ledger Entries after Invoking Apply Vendor Entries for Invoice.

        // Setup: Post Invoice and Payment for Vendor.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        DocumentNo := CreateAndPostPurchDocAndPayment(GenJournalLine, Vendor."No.", PurchaseHeader."Document Type"::Order);

        // Exercise: Run Page Vendor Ledger Entries to invoke Apply Vendor Entries.
        LibraryLowerPermissions.SetAccountPayables();
        RunVendorLedgerEntries(Vendor."No.", DocumentNo);

        // Verify: Verify Amount To Apply on Vendor Ledger Entries for Document Type Invoice.
        VerifyAmountToApplyOnVendorLedgerEntries(DocumentNo, PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler,ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AmountToApplyAfterApplyToEntryForPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // Verify Amount To Apply on Vendor Ledger Entries after Invoking Apply Vendor Entries for Payment.

        // Setup: Post Invoice and Payment for Vendor.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchDocAndPayment(GenJournalLine, Vendor."No.", PurchaseHeader."Document Type"::Invoice);

        // Exercise: Run Page Vendor Ledger Entries to invoke Apply Vendor Entries.
        LibraryLowerPermissions.SetAccountPayables();
        RunVendorLedgerEntries(Vendor."No.", GenJournalLine."Document No.");

        // Verify: Verify Amount To Apply on Vendor Ledger Entries for Document Type Payment.
        VerifyAmountToApplyOnVendorLedgerEntries(GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ApplyingVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure CheckAmountOnApplyVendorEntriesPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DummyGeneralJournal: TestPage "General Journal";
    begin
        // Verify that Apply Vendor Entry Page Shows Correct value when payment is applied under due date.

        // Setup: Create and post Gen journal line for two Invoice and two Credit Memo. and Create One Payment Line.
        Initialize();
        CreateGeneralJournalLine(
          GenJournalLine, 2, CreateVendor(), GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandIntInRange(100, 200));
        ModifyGenJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJnlLineWithDoctTypeCreditMemo(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(GenJournalLine, 1, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment,
          GetTotalAppliedAmount(GenJournalLine."Account No.", GenJournalLine."Posting Date"));
        ModifyGenJournalLine(GenJournalLine);

        // Exercise: Apply Set Applies To ID and Amount Apply.
        LibraryLowerPermissions.SetAccountPayables();
        SetAppliesToIDAndAmountToApply(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Verify: Verification done in ApplyingVendorEntriesPageHandler.
        OpenGenJournalPage(DummyGeneralJournal, GenJournalLine."Document No.", GenJournalLine."Document Type");
        DummyGeneralJournal."Apply Entries".Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyPurchInvoicesWithDimVals()
    begin
        // Verify that Dimension Set ID and Global Dimension values are correct after unapply of Vendor Ledger Entries with different Dimension Set IDs.
        Initialize();
        ApplyUnapplyVendEntriesWithMiscDimSetIDs(
          LibraryRandom.RandIntInRange(3, 10));
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandlerControlValuesVerification')]
    [Scope('OnPrem')]
    procedure RoundingAndBalanceAmountOnPaymentApplication()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Application Rounding and Balance amounts on Payment application
        RunRoundingAndBalanceAmountOnApplicationTest(GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandlerControlValuesVerification')]
    [Scope('OnPrem')]
    procedure RoundingAndBalanceAmountOnRefundApplication()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Application Rounding and Balance amounts on Refund application
        RunRoundingAndBalanceAmountOnApplicationTest(GenJournalLine."Document Type"::Refund);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAppliesToCrMemoDocNoForRefund()
    var
        Vendor: Record Vendor;
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // Verify that "Applies To Doc. No." can be validated with "Credit Memo" for Refund journal line.

        // Setup: Post credit memo and create empty refund line without vendor and amount.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalLine(
          GenJnlLine, 1, Vendor."No.", GenJnlLine."Document Type"::"Credit Memo", LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::"Credit Memo", GenJnlLine."Document No.");

        CreateGeneralJournalLine(GenJnlLine, 1, '', GenJnlLine."Document Type"::Refund, 0);

        // Exercise: Set open Credit Memo No. for "Applies To Doc. No".
        LibraryLowerPermissions.SetAccountPayables();
        GenJnlLine.Validate("Applies-to Doc. No.", VendLedgEntry."Document No.");
        GenJnlLine.Modify(true);

        // Verify: Vendor No. and "Applies To Doc. Type" are filled correctly.
        Assert.AreEqual(
          VendLedgEntry."Vendor No.", GenJnlLine."Account No.",
          StrSubstNo(WrongFieldErr, GenJnlLine.FieldCaption("Account No."), GenJnlLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler,ApplyAndVerifyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmountDifferentCurrencies()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        CurrencyCode: Code[10];
        ExchangeRateAmount: Decimal;
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Verify Applied Amount on Apply Entries Page when applying entries in different currencies

        // Setup
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        SelectGenJournalBatch(GenJournalBatch);
        ExchangeRateAmount := LibraryRandom.RandDecInRange(10, 50, 2);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount);
        PaymentAmount := LibraryRandom.RandDecInRange(100, 1000, 2);
        InvoiceAmount := PaymentAmount * LibraryRandom.RandIntInRange(3, 5);

        // Exercise
        LibraryLowerPermissions.SetAccountPayables();
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, WorkDate(), GenJournalLine."Document Type"::Invoice,
          Vendor."No.", '', -InvoiceAmount);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, WorkDate(), GenJournalLine."Document Type"::"Credit Memo",
          Vendor."No.", '', PaymentAmount);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, WorkDate(), GenJournalLine."Document Type"::Payment,
          Vendor."No.", CurrencyCode, PaymentAmount);

        LibraryVariableStorage.Enqueue(PaymentAmount);
        LibraryVariableStorage.Enqueue(InvoiceAmount);
        LibraryVariableStorage.Enqueue(ExchangeRateAmount);

        // Verify: verification in page handler
        RunVendorLedgerEntries(Vendor."No.", GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('UnapplyVendorEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ConsistentUnapplyInvoiceToPayment()
    var
        PurchLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        VendorNo: Code[20];
        ItemNo: Code[20];
        AdditionalCurrencyCode: Code[10];
        ForeignCurrencyCode: Code[10];
        DocumentNo: Code[20];
        InvoiceDate: Date;
    begin
        // [SCENARIO] Apply / Unapply Payment in additional currency to Invoice in foreigh currency with certain exchange rates

        // [GIVEN] No VAT setup, Foreign Currency and Additional Currency.
        Initialize();
        SetupSpecificExchRates(ForeignCurrencyCode, AdditionalCurrencyCode, InvoiceDate);
        CreateVendorAndItem(VendorNo, ItemNo, ForeignCurrencyCode);
        LibraryERM.SetAddReportingCurrency(AdditionalCurrencyCode);

        // [GIVEN] Posted Purchase Invoice for Vendor with foreigh currency
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchLine, InvoiceDate, VendorNo, ItemNo, PurchLine."Document Type"::Invoice, 1, 5000);
        // [GIVEN] Payment in ACY applied to Purchase Invoice
        PostApplyPaymentForeignCurrency(
          GenJournalLine, VendorNo, AdditionalCurrencyCode, 4132.91,
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo);

        // [WHEN] Invoice unapplied from payment
        LibraryLowerPermissions.SetAccountPayables();
        LibraryERM.FindVendorLedgerEntry(
          VendLedgerEntry, VendLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendLedgerEntry."Entry No.");

        // [THEN] Reversal G/L Entries have zero ACY Amounts
        VerifyACYInGLEntriesOnUnapplication(0, VendLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('UnapplyVendorEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnapplySeveralInvAndPmtWithDifferentDimValues()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        InvDimSetIDs: array[10] of Integer;
        PmtDimSetIDs: array[10] of Integer;
        Amounts: array[10] of Decimal;
        DiscountedAmounts: array[10] of Decimal;
        DiscountPercent: Integer;
        NoOfDocuments: Integer;
        LastGLEntryNo: Integer;
        i: Integer;
    begin
        // [SCENARIO 121881] Verify balance by dimensions = 0 after Apply/Unapply several Payments to Invoices with different dimensions
        Initialize();

        // [GIVEN] Last "G/L Entry" = LastGLEntryNo
        GLEntry.FindLast();
        LastGLEntryNo := GLEntry."Entry No.";

        // [GIVEN] Vendor with possible discount
        DiscountPercent := LibraryRandom.RandIntInRange(1, 10);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        CreateVendorWithGivenPaymentTerm(Vendor, CreatePaymentTermsWithGivenDiscount(DiscountPercent));

        NoOfDocuments := LibraryRandom.RandIntInRange(3, 10);
        for i := 1 to NoOfDocuments do begin
            Amounts[i] := 100 * LibraryRandom.RandIntInRange(1, 100);
            DiscountedAmounts[i] := Amounts[i] * (100 - DiscountPercent) / 100;
        end;

        // [GIVEN] Post "N" Invoices with different dimensions "InvDims[i]" and amounts "Amounts[i]"
        SelectGenJournalBatch(GenJournalBatch);
        CreatePostGenJnlLinesWithDimSetIDs(
          GenJournalLine, GenJournalBatch, InvDimSetIDs, NoOfDocuments,
          Vendor."No.", GenJournalLine."Document Type"::Invoice, Amounts, -1);

        // [GIVEN] Create "N" Gen. Journal Lines with different dimensions "PmtDims[i]" and "Document Type" = Payment
        CreateGenJnlLinesWithDimSetIDs(
          GenJournalLine, GenJournalBatch, PmtDimSetIDs, NoOfDocuments,
          Vendor."No.", GenJournalLine."Document Type"::Payment, DiscountedAmounts, 1);

        // [GIVEN] Set Gen. Journal Lines "Applies-to ID" and select Vendor Invoices Ledger Entries
        ApplyVendLedgerEntriesToID(Vendor."No.", GenJournalLine."Document No.", DiscountedAmounts);

        // [GIVEN] Post Gen. Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Unapply "N" Invoices Ledger Entries
        LibraryLowerPermissions.SetAccountPayables();
        for i := 1 to NoOfDocuments do begin
            FindClosedInvLedgerEntry(VendLedgEntry, Vendor."No.");
            VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendLedgEntry."Entry No.");
        end;

        // [THEN] Count of created "G/L Entries" with "Entry No." > LastGLEntryNo is "N" * (2 (Inv) + 3 (Apply) + 2 (UnApply))
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntryNo);
        Assert.AreEqual(NoOfDocuments * (2 + 3 + 2), GLEntry.Count, GLEntryCntErr);

        // [THEN] Balance by "InvDims[i]" and "PmtDims[i]" = 0 for the "Entry No." > LastGLEntryNo
        for i := 1 to NoOfDocuments do begin
            Assert.AreEqual(0, CalcBalanceByDimension(GLEntry, InvDimSetIDs[i]), DimBalanceErr);
            Assert.AreEqual(0, CalcBalanceByDimension(GLEntry, PmtDimSetIDs[i]), DimBalanceErr);
        end;

        // [THEN] Balance by "InvDims[i]" = 0 for the Invoice "G/L Entries" with "Entry No." in [LastGLEntryNo + 1,LastGLEntryNo + 2 * "N"]
        GLEntry.SetRange("Entry No.", LastGLEntryNo + 1, LastGLEntryNo + 2 * NoOfDocuments);
        for i := 1 to NoOfDocuments do
            Assert.AreEqual(0, CalcBalanceByDimension(GLEntry, InvDimSetIDs[i]), DimBalanceErr);

        // [THEN] Balance by "InvDims[i]" = 0, by "PmtDims[i]" = 0 for the Apply "G/L Entries" with "Entry No." in [LastGLEntryNo + 2 * "N" + 1,LastGLEntryNo + (2 + 3) * "N"]
        GLEntry.SetRange("Entry No.", LastGLEntryNo + 2 * NoOfDocuments + 1, LastGLEntryNo + (2 + 3) * NoOfDocuments);
        for i := 1 to NoOfDocuments do begin
            Assert.AreEqual(0, CalcBalanceByDimension(GLEntry, InvDimSetIDs[i]), DimBalanceErr);
            Assert.AreEqual(0, CalcBalanceByDimension(GLEntry, PmtDimSetIDs[i]), DimBalanceErr);
        end;

        // [THEN] Balance by "InvDims[i]" = 0, by "PmtDims[i]" = 0 for the UnApply "G/L Entries" with "Entry No." in [LastGLEntryNo + (2 + 3) * "N" + 1,LastGLEntryNo + (2 + 3 + 2) * "N"]
        GLEntry.SetRange("Entry No.", LastGLEntryNo + (2 + 3) * NoOfDocuments + 1, LastGLEntryNo + (2 + 3 + 2) * NoOfDocuments);
        for i := 1 to NoOfDocuments do begin
            Assert.AreEqual(0, CalcBalanceByDimension(GLEntry, InvDimSetIDs[i]), DimBalanceErr);
            Assert.AreEqual(0, CalcBalanceByDimension(GLEntry, PmtDimSetIDs[i]), DimBalanceErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoVATEntriesWhenUnapplyZeroDiscEntryWithAdjForPmtDisc()
    var
        PurchLine: Record "Purchase Line";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Reverse Charge VAT] [Adjust For Payment Discount]
        // [SCENARIO 229786] There are no VAT and G/L Entries created when unapplies the entry without discount but with Reverse Charge and "Adjust For Payment Discount"
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] Posted invoice with Reverse Charge VAT setup with "Adjust For Payment Discount"
        PostedDocumentNo :=
          CreatePostPurchInvWithReverseChargeVATAdjForPmtDisc(PurchLine);
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, PostedDocumentNo);
        VendLedgEntry.CalcFields("Amount (LCY)");

        // [GIVEN] Post and apply document with empty document type
        CreateGenJnlLineWithPostingGroups(GenJnlLine, PurchLine."Pay-to Vendor No.", "Gen. Journal Document Type"::" ",
          -VendLedgEntry."Amount (LCY)", PurchLine);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", PostedDocumentNo);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [WHEN] Unapply the empty document application
        GLEntry.FindLast();
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, "Gen. Journal Document Type"::" ", GenJnlLine."Document No.");
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);

        // [THEN] There is no VAT and G/L Entries have been created on unapplication
        VerifyNoVATEntriesOnUnapplication("Gen. Journal Document Type"::" ", GenJnlLine."Document No.");
        GLEntry.SetFilter("Entry No.", '>%1', GLEntry."Entry No.");
        Assert.RecordIsEmpty(GLEntry);

        // Tear Down: Return back the old value of "Adjust For Payment Discount".
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoIsNotFullyAppliedByPaymentWithLessAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        DocumentNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
    begin
        // [SCENARIO 233340] Credit-memo does not become closed when it is applied to Payment with less amount (by absolute value).
        Initialize();

        // [GIVEN] Vendor.
        Amount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        Amount[2] := LibraryRandom.RandDecInRange(10, 20, 2);
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Credit memo with Amount = 100 LCY is posted in the purchase journal.
        CreateAndPostGenJournalLine(
          GenJournalLine, VendorNo, GenJournalLine."Document Type"::"Credit Memo", Amount[1], '', WorkDate());
        DocumentNo[1] := GenJournalLine."Document No.";

        // [WHEN] Payment with negative Amount = -10 LCY is set applied to the credit-memo and posted in the payment journal.
        CreateAndPostPaymentJournalLineAppliedToDoc(
          GenJournalLine, VendorNo, -Amount[2], GenJournalLine."Applies-to Doc. Type"::"Credit Memo", DocumentNo[1]);
        DocumentNo[2] := GenJournalLine."Document No.";

        // [THEN] The credit-memo is not fully applied by the payment. Remaining amount = 100 - 10 = 90 LCY.
        VerifyVendorLedgEntryRemAmount(
          VendorLedgerEntry."Document Type"::"Credit Memo", DocumentNo[1], Amount[1] - Amount[2]);

        // [THEN] The payment vendor ledger entry is closed.
        VerifyVendorLedgEntryRemAmount(
          VendorLedgerEntry."Document Type"::Payment, DocumentNo[2], 0);
    end;

    [Test]
    [HandlerFunctions('UnapplyVendorEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyEntryWithLaterExchRateAdjustment()
    var
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        ERMApplyUnapplyVendor: Codeunit "ERM Apply Unapply Vendor";
        Amount: array[2] of Decimal;
        PostingDate: array[3] of Date;
        CurrencyCode: Code[10];
        Rate: Decimal;
    begin
        // [FEATURE] [FCY] [Adjust Exchange Rate]
        // [SCENARIO 304391] "Remaining Amt. (LCY)" should match "Adjusted Currency Factor" after Unapply of the entry being adjusted on the later date.
        Initialize();
        BindSubscription(ERMApplyUnapplyVendor);

        // [GIVEN] USD has different exchange rates on 01.01, 15.01, 31.01.
        PostingDate[1] := WorkDate();
        PostingDate[2] := PostingDate[1] + 1;
        PostingDate[3] := PostingDate[2] + 1;
        Rate := LibraryRandom.RandDec(10, 2);
        CurrencyCode := CreateCurrencyAndExchangeRate(Rate, 1, PostingDate[1]);
        CreateExchangeRate(CurrencyCode, Rate * 1.2, 1, PostingDate[2]);
        CreateExchangeRate(CurrencyCode, Rate * 0.85, 1, PostingDate[3]);

        // [GIVEN] Invoice of 100 USD posted on 01.01, where "Document No." is 'INV001'
        LibraryPurchase.CreateVendor(Vendor);
        SelectGenJournalBatch(GenJournalBatch);
        Amount[1] := -LibraryRandom.RandDecInRange(10000, 20000, 2);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine[1], GenJournalBatch, PostingDate[1],
          GenJournalLine[1]."Document Type"::Invoice, Vendor."No.", CurrencyCode, Amount[1]);

        // [GIVEN] Payment of 150 USD posted on 15.01, applied to Invoice
        Amount[2] := Round(-Amount[1] * 1.5, 0.01);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine[2], GenJournalBatch, PostingDate[2],
          GenJournalLine[2]."Document Type"::Payment, Vendor."No.", CurrencyCode, Amount[2]);
        ApplyVendorLedgerEntryWithAmount(GenJournalLine[1]."Document Type", GenJournalLine[2]."Document Type", Amount[1],
          GenJournalLine[1]."Document No.", GenJournalLine[2]."Document No.");

        // [GIVEN] Payment has been adjusted by "Adjust Exchange Rate" on 31.01
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, PostingDate[3], PostingDate[3]);

        // [WHEN] Unapply Invoice and Payment on 15.01
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine[1]."Document Type", GenJournalLine[1]."Document No.");
        VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendorLedgerEntry."Entry No.");
        UnbindSubscription(ERMApplyUnapplyVendor);

        // [THEN] This Payment is balanced to its adjusted exchange rate
        VerifyVendLedgerEntryRemAmtLCYisBalanced(GenJournalLine[1]."Document No.", GenJournalLine[1]."Document Type");

        // [THEN] This invoice is balanced to its adjusted exchange rate
        VerifyVendLedgerEntryRemAmtLCYisBalanced(GenJournalLine[2]."Document No.", GenJournalLine[2]."Document Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingACYWhenPaymentAppliedToInvoiceWithRevChargeVAT()
    var
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        PaymentDate: Date;
        InvoiceNo: Code[20];
        CurrencyCode: Code[10];
        VATPct: Integer;
        DiscountPct: Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [Adjust For Payment Discount] [ACY]
        // [SCENARIO 348963] Payment applied to the invoice with reverse charge VAT and payment discount gives zero Add.Curr Amount
        Initialize();

        // [GIVEN] Adjustment for Payment Discount is turned on
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // [GIVEN] Currency with specific exchange rates on 01.01 and 02.01, set as Additional Reporting Currency
        PaymentDate := LibraryRandom.RandDate(3);
        CurrencyCode := CreateCurrencyAndExchangeRate(1, 1.1302, WorkDate());
        CreateExchangeRate(CurrencyCode, 1, 1.1208, PaymentDate);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);

        // [GIVEN] Posted invoice of amount 678 posted on 01.01 with Reverse Charge VAT setup with "Adjust For Payment Discount"
        // [GIVEN] Payment Discount % = 3.5
        VATPct := 25;
        DiscountPct := 3.5;
        InvoiceNo :=
          CreatePostPurchInvWithReverseChargeVATAdjForPmtDiscSetValues(PurchaseLine, CurrencyCode, 1, 678, VATPct, DiscountPct);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.CalcFields(Amount);

        // [WHEN] Payment of amount 654,27 on 02.01
        CreateGenJnlLineWithPostingGroups(
          GenJournalLine, PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment,
          -VendorLedgerEntry.Amount + VendorLedgerEntry."Remaining Pmt. Disc. Possible", PurchaseLine);
        GenJournalLine.Validate("Posting Date", PaymentDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Payment is applied to the invoice
        ApplyVendorLedgerEntry(
          VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Document Type"::Invoice,
          GenJournalLine."Document No.", InvoiceNo);

        // [THEN] Amount and "Additional-Currency Amount" not equal to 0 in reverse charge VAT Entry created for the payment
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.FindLast();
        VATEntry.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        VATEntry.TestField(Amount);
        VATEntry.TestField("Additional-Currency Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentAppliedToMultipleInvoicesWithDifferentExchRates()
    var
        Currency: Record Currency;
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntryPayment: Record "Vendor Ledger Entry";
        VendorLedgerEntryInvoice: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        ERMApplyUnapplyVendor: Codeunit "ERM Apply Unapply Vendor";
    begin
        // [FEATURE] [Adjust Exchange Rate] [FCY] [Unapply] [Apply]
        // [SCENARIO 399430] Stan can Unapply vendor's payment that is applied to multiple invoices with different currency rates and multiple currency rate adjustment.
        Initialize();
        BindSubscription(ERMApplyUnapplyVendor);

        PrepareCurrency(Currency, 0);

        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 8, 2020), 0.12901, 0.12901);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 9, 2020), 0.12903, 0.12903);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 10, 2020), 0.12903, 0.12903);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 11, 2020), 0.12905, 0.12905);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 12, 2020), 0.12903, 0.12903);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 1, 2021), 0.12903, 0.12903);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);

        SelectGenJournalBatch(GenJournalBatch);

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(19, 8, 2020),
          GenJournalLine."Document Type"::Invoice, Vendor."No.", Currency.Code, -400);

        LibraryERM.RunExchRateAdjustmentSimple(Currency.Code, DMY2Date(30, 9, 2020), DMY2Date(30, 9, 2020));

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(12, 11, 2020),
          GenJournalLine."Document Type"::Invoice, Vendor."No.", Currency.Code, -850);

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(12, 11, 2020),
          GenJournalLine."Document Type"::Invoice, Vendor."No.", Currency.Code, -250);

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(17, 11, 2020),
          GenJournalLine."Document Type"::Invoice, Vendor."No.", Currency.Code, -244140);

        LibraryERM.RunExchRateAdjustmentSimple(Currency.Code, DMY2Date(30, 11, 2020), DMY2Date(30, 11, 2020));

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(7, 1, 2021),
          GenJournalLine."Document Type"::Payment, Vendor."No.", Currency.Code, 77280);

        VendorLedgerEntryPayment.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntryPayment, VendorLedgerEntryPayment."Document Type"::Payment, GenJournalLine."Document No.");

        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntryPayment);

        VendorLedgerEntryInvoice.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntryInvoice.SetRange("Document Type", VendorLedgerEntryInvoice."Document Type"::Invoice);

        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntryInvoice);

        LibraryERM.PostVendLedgerApplication(VendorLedgerEntryPayment);

        LibraryERM.RunExchRateAdjustmentSimple(Currency.Code, DMY2Date(31, 12, 2020), DMY2Date(31, 12, 2020));

        Commit();

        VendorLedgerEntryPayment.Find();
        VendorLedgerEntryPayment.TestField(Open, false);

        DetailedVendorLedgEntry.SetRange("Document Type", DetailedVendorLedgEntry."Document Type"::Payment);
        DetailedVendorLedgEntry.SetRange("Document No.", VendorLedgerEntryPayment."Document No.");
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.FindLast();

        ApplyUnapplyParameters."Document No." := VendorLedgerEntryPayment."Document No.";
        ApplyUnapplyParameters."Posting Date" := VendorLedgerEntryPayment."Posting Date";
        VendEntryApplyPostedEntries.PostUnApplyVendor(DetailedVendorLedgEntry, ApplyUnapplyParameters);

        UnbindSubscription(ERMApplyUnapplyVendor);

        VendorLedgerEntryPayment.Find();
        VendorLedgerEntryPayment.TestField(Open, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountIsZeorBeforeAndAfterRunningExchRateAdjustmentReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ERMApplyUnapplyVendor: Codeunit "ERM Apply Unapply Vendor";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
        PaymentTolerance: Decimal;
        PostingDate: array[3] of Date;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 535548] Issue with Adjust Currency Exchange Rate using the new feature Report 596
        Initialize();

        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        PaymentTolerance := LibraryRandom.RandDec(10, 2);  // Using Random value for Payment Tolerance.
        SetPaymentTolerancePct(PaymentTolerance);

        // [GIVEN] Create new currenct with different exchange rates on 01.01, 15.01, 31.01.
        PostingDate[1] := Today();
        PostingDate[2] := PostingDate[1] + 30;
        PostingDate[3] := WorkDate();
        CurrencyCode := CreateCurrencyAndExchangeRate(1, LibraryRandom.RandDecInDecimalRange(11.5575, 11.5575, 4), PostingDate[1]);
        CreateExchangeRate(CurrencyCode, 1, LibraryRandom.RandDecInDecimalRange(11.753, 11.753, 3), PostingDate[2]);
        CreateExchangeRate(CurrencyCode, 1, LibraryRandom.RandDecInDecimalRange(11.6398, 11.6398, 4), PostingDate[3]);

        // [GIVEN] Create vendor with currency
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CreateCurrency(LibraryRandom.RandDec(10, 2)));
        Vendor.Modify(true);

        // [GIVEN] Create Purchase Invoice and post
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        Amount := CreateAndModifyPurchaseLine(PurchaseHeader);
        Amount := LibraryERM.ConvertCurrency(Amount, PurchaseHeader."Currency Code", '', WorkDate());
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Payment and post for Posted Invoice
        CreateGeneralJournalLine(GenJournalLine, 1, Vendor."No.", GenJournalLine."Document Type"::Payment, 0);
        GenJournalLine.Validate("Posting Date", PostingDate[3]);
        UpdateGenJournalLine(GenJournalLine, '', PostedDocumentNo, Amount);
        LibraryLowerPermissions.SetAccountPayables();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify: Verify Remaining Amount is zero on Vendor Ledger Entry before running Exchange Rate report
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, PurchaseHeader."Document Type", PostedDocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);

        // [WHEN] Run Adjustment for Vendor by "Adjust Exchange Rate" on 31.01
        BindSubscription(ERMApplyUnapplyVendor);
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, PostingDate[3], PostingDate[3]);
        UnbindSubscription(ERMApplyUnapplyVendor);

        // [THEN] Verify: Verify Remaining Amount is zero on Vendor Ledger Entry after running Exchange Rate report
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, PurchaseHeader."Document Type", PostedDocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler,PaymentToleranceWarning')]
    procedure AppliesToExtDocNoIsClearedOnUnApplyEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 573180] The Applies-to Ext. Doc. No. field is cleaned up after Un Apply Entries.
        Initialize();

        // [GIVEN] Setup Adjust For Payment Setups.
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryPmtDiscSetup.SetPmtTolerance(LibraryRandom.RandDec(100, 2));

        // [GIVEN] Find VAT Posting Setup.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] Set Adjustment Payment in VAT Posting setup.
        SetAdjustForPaymentDiscInVATPostingSetup(VATPostingSetup, true);

        // [GIVEN] Create and Post Purchase Order.
        CreateAndPostPurchaseOrder(PurchaseHeader, VATPostingSetup);

        // [GIVEN] Create Payment Journal
        CreateGeneralJournalLine(GenJournalLine, 1, PurchaseHeader."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, 0);

        // [GIVEN] Apply the Purchase Order.
        OpenGeneralJournalPage(GenJournalLine."Document No.", GenJournalLine."Document Type");

        // [GIVEN] Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Unapply Vendor Ledger Entry.
        UnapplyVendorLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // [THEN] "Applies-to Ext. Doc. No." in Vendor Ledger Entry is cleared.
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual('', VendorLedgerEntry."Applies-to Ext. Doc. No.", AppliesToExtDocNoErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Apply Unapply Vendor");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Apply Unapply Vendor");
        LibraryPurchase.SetInvoiceRounding(false);
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Source Code Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Apply Unapply Vendor");
    end;

    local procedure SetupSpecificExchRates(var ForeignCurrencyCode: Code[10]; var AdditionalCurrencyCode: Code[10]; var DocumentDate: Date)
    begin
        DocumentDate := CalcDate('<-' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', WorkDate());
        ForeignCurrencyCode := CreateCurrencyAndExchangeRate(100, 46.0862, DocumentDate);
        AdditionalCurrencyCode := CreateCurrencyAndExchangeRate(100, 55.7551, DocumentDate);
        CreateExchangeRate(AdditionalCurrencyCode, 100, 50, WorkDate());
    end;

    local procedure PostApplyPaymentForeignCurrency(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; CurrencyCode: Code[10]; PaymentAmount: Decimal; AppliedDocumentType: Enum "Gen. Journal Document Type"; AppliedDocumentNo: Code[20])
    begin
        CreateGeneralJournalLine(GenJournalLine, 1, VendorNo, GenJournalLine."Document Type"::Payment, 0);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Amount, PaymentAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliedDocumentType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedDocumentNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccountWithCurrency(CurrencyCode));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunRoundingAndBalanceAmountOnApplicationTest(DocumentType: Enum "Gen. Journal Document Type")
    var
        Currency: Record Currency;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        Item: Record Item;
        LineAmount: Decimal;
        CurrencyFactor: Decimal;
        ApplicationRoundingPrecision: Decimal;
    begin
        // Verify Application Rounding and Balance amounts
        // Setup.
        LibraryLowerPermissions.SetOutsideO365Scope();
        ApplicationRoundingPrecision := 1;
        LineAmount := 99;
        // prime numbers are required to obtain non-whole number after currency conversion
        CurrencyFactor := 7 / 3;
        SetApplnRoundingPrecision(ApplicationRoundingPrecision);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Invoice Rounding Precision", 0.01);
        Currency.Modify(true);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), CurrencyFactor, CurrencyFactor);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);

        // Excercise
        CreateAndPostPurchaseDocument(
          PurchaseLine, WorkDate(), Vendor."No.", LibraryInventory.CreateItem(Item), PurchaseHeader."Document Type"::Invoice,
          1, LineAmount);
        LineAmount := PurchaseLine."Amount Including VAT";

        CreateGeneralJournalLine(
          GenJournalLine, 1, Vendor."No.", DocumentType,
          1 * Round(LineAmount / CurrencyFactor, ApplicationRoundingPrecision, '<'));
        GenJournalLine.Validate("Currency Code", '');
        GenJournalLine.Modify(true);

        // Verify is done in page handler
        LibraryVariableStorage.Enqueue(Round(LineAmount / CurrencyFactor, Currency."Invoice Rounding Precision"));
        LibraryVariableStorage.Enqueue(-GenJournalLine.Amount);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);
    end;

    local procedure ApplyUnapplyVendorEntries(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; NoOfLines: Integer; Amount: Decimal; Amount2: Decimal) DocumentNo: Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);

        // Create Journal Lines according to the options selected and post them.
        CreateGeneralJournalLine(GenJournalLine, 1, Vendor."No.", DocumentType, Amount);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateGeneralJournalLine(GenJournalLine, NoOfLines, GenJournalLine."Account No.", DocumentType2, Amount2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply and Unapply Vendor Entries as per the option selected.
        ApplyVendorLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", DocumentNo);
        UnapplyVendorLedgerEntry(DocumentType2, GenJournalLine."Document No.");
    end;

    local procedure ApplyUnapplySeveralVendorEntries(Sign: Integer; var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        NoOfLines: Integer;
        Amount: Integer;
    begin
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        Amount := Sign * 100 * LibraryRandom.RandInt(10);
        LibraryERM.SetAddReportingCurrency(CreateCurrency(0));

        ApplyUnapplyVendorEntries(GenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount, -Amount / NoOfLines);
    end;

    local procedure ApplyVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, DocumentType2, DocumentNo2);
        VendorLedgerEntry2.FindSet();
        repeat
            VendorLedgerEntry2.CalcFields("Remaining Amount");
            VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
            VendorLedgerEntry2.Modify(true);
        until VendorLedgerEntry2.Next() = 0;
        SetAppliesToIDAndPostEntry(VendorLedgerEntry2, VendorLedgerEntry);
    end;

    local procedure ApplyVendorLedgerEntryWithAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, Amount);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, DocumentType2, DocumentNo2);
        VendorLedgerEntry2.FindSet();
        repeat
            VendorLedgerEntry2.CalcFields("Remaining Amount");
            VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
            VendorLedgerEntry2.Modify(true);
        until VendorLedgerEntry2.Next() = 0;
        SetAppliesToIDAndPostEntry(VendorLedgerEntry2, VendorLedgerEntry);
    end;

    local procedure ApplyUnapplyVendEntriesWithMiscDimSetIDs(NoOfLines: Integer)
    var
        Vendor: Record Vendor;
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        DimSetIDs: array[10] of Integer;
        DiscountPercent: Integer;
        Amounts: array[10] of Decimal;
        DiscountedAmounts: array[10] of Decimal;
        DocNo: Code[20];
        i: Integer;
    begin
        // Setup
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        DiscountPercent := LibraryRandom.RandIntInRange(1, 10);
        CreateVendorWithGivenPaymentTerm(Vendor, CreatePaymentTermsWithGivenDiscount(DiscountPercent));

        for i := 1 to NoOfLines do begin
            Amounts[i] := 100 * LibraryRandom.RandIntInRange(1, 100);
            DiscountedAmounts[i] := Amounts[i] * (100 - DiscountPercent) / 100;
        end;

        // Exercise
        DocNo := ApplyUnapplyWithDimSetIDs(NoOfLines, Vendor."No.", DimSetIDs, Amounts, DiscountedAmounts);

        // Exercise and Verify
        for i := 1 to NoOfLines do
            Amounts[i] -= DiscountedAmounts[i];

        VerifyGLEntriesWithDimSetIDs(DocNo, Amounts, DimSetIDs, NoOfLines);
    end;

    local procedure ApplyUnapplyWithDimSetIDs(NoOfLines: Integer; VendorNo: Code[20]; var DimSetIDs: array[10] of Integer; Amounts: array[10] of Decimal; DiscountedAmounts: array[10] of Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TotalDiscountedAmount: Decimal;
        i: Integer;
    begin
        SelectGenJournalBatch(GenJournalBatch);
        CreatePostGenJnlLinesWithDimSetIDs(
          GenJournalLine, GenJournalBatch, DimSetIDs, NoOfLines,
          VendorNo, GenJournalLine."Document Type"::Invoice, Amounts, -1);

        CreateGenJnlLinesWithGivenDimSetIDs(
          GenJournalLine, GenJournalBatch, DimSetIDs, NoOfLines,
          VendorNo, GenJournalLine."Document Type"::Payment, DiscountedAmounts);

        ApplyVendLedgerEntriesToID(VendorNo, GenJournalLine."Document No.", DiscountedAmounts);

        for i := 1 to NoOfLines do
            TotalDiscountedAmount += DiscountedAmounts[i];

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          VendorNo, -TotalDiscountedAmount);
        BankAccount.SetRange(Blocked, false);
        BankAccount.SetRange("Currency Code", '');
        BankAccount.FindFirst();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        UnapplyVendLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        exit(GenJournalLine."Document No.");
    end;

    local procedure ApplyVendLedgerEntriesToID(VendorNo: Code[20]; AppliesToID: Code[50]; AmountsToApply: array[10] of Decimal)
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        i: Integer;
    begin
        VendLedgerEntry.SetRange("Vendor No.", VendorNo);
        if VendLedgerEntry.FindSet() then
            repeat
                i += 1;
                VendLedgerEntry.Validate("Applying Entry", true);
                VendLedgerEntry.Validate("Applies-to ID", AppliesToID);
                VendLedgerEntry.Validate("Amount to Apply", -AmountsToApply[i]);
                VendLedgerEntry.Modify(true);
            until VendLedgerEntry.Next() = 0;
    end;

    local procedure CalcBalanceByDimension(var GLEntry: Record "G/L Entry"; DimSetID: Integer) Result: Integer
    begin
        Result := 0;
        GLEntry.SetRange("Dimension Set ID", DimSetID);
        if GLEntry.FindSet() then
            repeat
                Result += GLEntry.Amount;
            until GLEntry.Next() = 0;
    end;

    local procedure CreateGenLineAndApply(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AppRounding: Decimal; Amount: Decimal)
    var
        Vendor: Record Vendor;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        DocumentNo: Code[20];
    begin
        // Setup: Create Invoice and Payment General Line with Different Currency without Rounding Precision.
        UpdatePurchaseAndPayableSetup(PurchasesPayablesSetup."Appln. between Currencies"::All);
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGenJournalLine(GenJournalLine, Vendor."No.", DocumentType, Amount, CreateCurrency(0), WorkDate());
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJournalLine(
          GenJournalLine, Vendor."No.", DocumentType2, -GenJournalLine.Amount - AppRounding, CreateCurrency(AppRounding), WorkDate());

        // Exericse.
        ApplyVendorLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", DocumentNo);
    end;

    local procedure CreateCurrency(ApplnRoundingPrecision: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        PrepareCurrency(Currency, ApplnRoundingPrecision);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyAndExchangeRate(Rate: Decimal; RelationalRate: Decimal; FromDate: Date): Code[10]
    var
        Currency: Record Currency;
    begin
        PrepareCurrency(Currency, 0);
        CreateExchangeRate(Currency.Code, Rate, RelationalRate, FromDate);
        exit(Currency.Code);
    end;

    local procedure PrepareCurrency(var Currency: Record Currency; ApplnRoundingPrecision: Decimal)
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Validate("Appln. Rounding Precision", ApplnRoundingPrecision);
        Currency.Modify(true);
    end;

    local procedure CreatePaymentsJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; NoOfLine: Integer; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
    begin
        SelectGenJournalBatch(GenJournalBatch);
        for Counter := 1 to NoOfLine do
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
              GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
    end;

    local procedure CreateGenJnlLineWithDoctTypeCreditMemo(var GenJournalLine: Record "Gen. Journal Line")
    var
        Counter: Integer;
    begin
        for Counter := 1 to 2 do
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
              GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.",
              LibraryRandom.RandIntInRange(50, 80));
        ModifyGenJournalLine(GenJournalLine);
    end;

    local procedure CreatePostGenJnlLinesWithDimSetIDs(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; var DimSetIDs: array[10] of Integer; NumOfDocuments: Integer; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amounts: array[10] of Decimal; SignFactor: Integer)
    var
        i: Integer;
    begin
        for i := 1 to NumOfDocuments do begin
            CreateGenJnlLineWithDimSetID(GenJournalLine, GenJournalBatch, DimSetIDs[i], VendorNo, DocumentType, Amounts[i] * SignFactor);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;
    end;

    local procedure CreateGenJnlLinesWithDimSetIDs(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; var DimSetIDs: array[10] of Integer; NumOfDocuments: Integer; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amounts: array[10] of Decimal; SignFactor: Integer)
    var
        i: Integer;
    begin
        for i := 1 to NumOfDocuments do
            CreateGenJnlLineWithDimSetID(GenJournalLine, GenJournalBatch, DimSetIDs[i], VendorNo, DocumentType, Amounts[i] * SignFactor);
    end;

    local procedure CreateGenJnlLineWithDimSetID(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; var DimSetID: Integer; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        DimVal: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        LibraryDimension.CreateDimensionValue(DimVal, LibraryERM.GetGlobalDimensionCode(1));
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimVal.Code);
        GenJournalLine.Modify(true);
        DimSetID := GenJournalLine."Dimension Set ID";
    end;

    local procedure CreateGenJnlLinesWithGivenDimSetIDs(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DimSetIDs: array[10] of Integer; NoOfLines: Integer; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amounts: array[10] of Decimal)
    var
        DimMgt: Codeunit DimensionManagement;
        Counter: Integer;
    begin
        for Counter := 1 to NoOfLines do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
              GenJournalLine."Account Type"::Vendor, VendorNo, Amounts[Counter]);
            GenJournalLine.Validate("Bal. Account No.", '');
            GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
            GenJournalLine.Validate("Dimension Set ID", DimSetIDs[Counter]);
            DimMgt.UpdateGlobalDimFromDimSetID(
              GenJournalLine."Dimension Set ID", GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
            GenJournalLine.Modify(true);
        end;
    end;

    local procedure CreateGenJnlLineWithPostingGroups(var GenJnlLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PurchLine: Record "Purchase Line")
    begin
        CreateGeneralJournalLine(GenJnlLine, 1, VendorNo, DocumentType, Amount);
        GenJnlLine.Validate("Bal. Gen. Posting Type", "General Posting Type"::Purchase);
        GenJnlLine.Validate("Bal. Gen. Bus. Posting Group", PurchLine."Gen. Bus. Posting Group");
        GenJnlLine.Validate("Bal. Gen. Prod. Posting Group", PurchLine."Gen. Prod. Posting Group");
        GenJnlLine.Validate("Bal. VAT Bus. Posting Group", PurchLine."VAT Bus. Posting Group");
        GenJnlLine.Validate("Bal. VAT Prod. Posting Group", PurchLine."VAT Prod. Posting Group");
        GenJnlLine.Modify(true);
    end;

    local procedure CreateItem(VATProductPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithPostingSetup(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    begin
        // Apply and Unapply General Journal Lines for Payment and Invoice. Take a Random Amount greater than 100 (Standard Value).
        CreateGeneralJournalLine(GenJournalLine, 1, VendorNo, DocumentType, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPaymentJournalLineAppliedToDoc(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; Amount: Decimal; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePaymentsJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; PostingDate: Date; VendorNo: Code[20]; ItemNo: Code[20]; DocumentType: Enum "Purchase Document Type"; Quantity: Decimal; DirectUnitCost: Decimal) PostedDocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        UpdateDirectUnitCostOnPurchaseLine(PurchaseLine, DirectUnitCost);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchDocAndPayment(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DocType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, WorkDate(), VendorNo, LibraryInventory.CreateItemNo(), DocType,
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(1000, 2));
        CreateGeneralJournalLine(GenJournalLine, 1, VendorNo, GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(false); // Do not invoke set applies to ID action

        exit(DocumentNo);
    end;

    local procedure SetUnapplPurchEntryApplnSourceCode(UnappliedPurchEntryAppln: Code[10])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.Validate("Unapplied Purch. Entry Appln.", UnappliedPurchEntryAppln);
        SourceCodeSetup.Modify(true);
    end;

    local procedure CreateNewExchangeRate(PostingDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Use Random Number Generator for Exchange Rate.
        GeneralLedgerSetup.Get();
        CurrencyExchangeRate.SetRange("Currency Code", GeneralLedgerSetup."Additional Reporting Currency");
        CurrencyExchangeRate.FindFirst();
        LibraryERM.CreateExchRate(CurrencyExchangeRate, GeneralLedgerSetup."Additional Reporting Currency", PostingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandInt(100));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; Rate: Decimal; RelationalRate: Decimal; FromDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, FromDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", Rate);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", Rate);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalRate);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalRate);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreatePostApplyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date)
    var
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGenJournalLine(GenJournalLine, Vendor."No.", DocumentType, Amount, '', PostingDate);
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJournalLine(GenJournalLine, Vendor."No.", DocumentType2, -Amount, '', PostingDate);
        ApplyVendorLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", DocumentNo);
    end;

    local procedure CreateAndPostGenJnlLineWithCurrency(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndModifyPurchaseLine(PurchaseHeader: Record "Purchase Header"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase line using Random Quantity and Amount.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateZeroVATPostingGLAccount(),
          LibraryRandom.RandDec(10, 2));
        UpdateDirectUnitCostOnPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));
        UpdateGeneralPostingSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", GetPaymentTerms());
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithPostingSetup(GenBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithGivenPaymentTerm(var Vendor: Record Vendor; PaymentTermsCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithPaymentTerms(VATBusinessPostingGroup: Code[20]): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        CreatePaymentTermsWithDiscount(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorAndItem(var VendorNo: Code[20]; var ItemNo: Code[20]; ForeignCurrencyCode: Code[10])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        ItemNo :=
          CreateItemWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VendorNo :=
          CreateVendorWithPostingSetup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Get(VendorNo);
        Vendor.Validate("Currency Code", ForeignCurrencyCode);
        Vendor.Modify(true);
    end;

    local procedure CreatePaymentTermsWithDiscount(var PaymentTerms: Record "Payment Terms")
    var
        LibraryERM: Codeunit "Library - ERM";
    begin
        // Input any random Due Date and Discount Date Calculation.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", StrSubstNo('<%1M>', LibraryRandom.RandInt(10)));
        Evaluate(PaymentTerms."Discount Date Calculation", StrSubstNo('<%1D>', Format(LibraryRandom.RandInt(10))));
        PaymentTerms.Validate("Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation");
        PaymentTerms.Validate("Discount %", LibraryRandom.RandInt(10));
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
    end;

    local procedure CreatePaymentTermsWithGivenDiscount(DiscountPercent: Decimal): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        PaymentTerms.Validate("Discount %", DiscountPercent);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateBankAccountWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify();
        exit(BankAccount."No.");
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithPaymentTerms(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(5));
        UpdateGeneralPostingSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        UpdateDirectUnitCostOnPurchaseLine(PurchaseLine, LibraryRandom.RandDecInRange(10, 1000, 2));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostPurchInvWithReverseChargeVATAdjForPmtDisc(var PurchLine: Record "Purchase Line"): Code[20]
    begin
        exit(
          CreatePostPurchInvWithReverseChargeVATAdjForPmtDiscSetValues(
            PurchLine, '', LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2), LibraryRandom.RandIntInRange(10, 20), 0));
    end;

    local procedure CreatePostPurchInvWithReverseChargeVATAdjForPmtDiscSetValues(var PurchLine: Record "Purchase Line"; CurrencyCode: Code[10]; Quantity: Integer; DirectCost: Decimal; VATPct: Decimal; DiscountPct: Decimal): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        ItemNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        UpdateGenPostSetupWithPurchPmtDiscAccount(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", VATPct);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
        Vendor.Get(
          CreateVendorWithPostingSetup(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Validate("Payment Terms Code", CreatePaymentTermsWithGivenDiscount(DiscountPct));
        Vendor.Modify(true);
        ItemNo :=
          CreateItemWithPostingSetup(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, Quantity);
        UpdateDirectUnitCostOnPurchaseLine(PurchLine, DirectCost);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure DateCompressForVendor(GenJournalLine: Record "Gen. Journal Line"; StartingDate: Date; PeriodLength: Option)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressVendorLedger: Report "Date Compress Vendor Ledger";
    begin
        // Run the Date Compress Vendor Ledger Report with a closed Accounting Period.
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        DateCompressVendorLedger.SetTableView(VendorLedgerEntry);
        DateComprRetainFields."Retain Document No." := false;
        DateComprRetainFields."Retain Buy-from Vendor No." := false;
        DateComprRetainFields."Retain Purchaser Code" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressVendorLedger.InitializeRequest(StartingDate, GenJournalLine."Posting Date", PeriodLength, '', DateComprRetainFields, '', false);
        DateCompressVendorLedger.UseRequestPage(false);
        DateCompressVendorLedger.Run();
    end;

    local procedure CreateZeroVATPostingGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
    end;

    local procedure FindDetailedLedgerEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentNo: Code[20]; VendorNo: Code[20])
    begin
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.FindSet();
    end;

    local procedure FindGLEntries(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
    end;

    local procedure FindPaymentMethodWithBalanceAccount(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetFilter("Bal. Account No.", '<>''''');
        PaymentMethod.FindFirst();
        exit(PaymentMethod.Code);
    end;

    local procedure FindClosedInvLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange(Open, false);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure GetPaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure GetTotalAppliedAmount(VendorNo: Code[20]; PostingDate: Date): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        DiscountAmount: Decimal;
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Posting Date", PostingDate);
        VendorLedgerEntry.FindSet();
        repeat
            DiscountAmount += VendorLedgerEntry."Original Pmt. Disc. Possible";
        until VendorLedgerEntry.Next() = 0;
        Vendor.Get(VendorNo);
        Vendor.CalcFields("Balance (LCY)");
        exit(Vendor."Balance (LCY)" + DiscountAmount);
    end;

    local procedure GetTransactionNoFromUnappliedDtldEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetRange("Document Type", DocType);
        DtldVendLedgEntry.SetRange("Document No.", DocNo);
        DtldVendLedgEntry.SetRange(Unapplied, true);
        DtldVendLedgEntry.FindLast();
        exit(DtldVendLedgEntry."Transaction No.");
    end;

    local procedure ModifyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate("Document No.", IncStr(GenJournalLine."Document No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate("Posting Date", CalcDate('<1Y>', WorkDate()));
        GenJournalLine.Modify(true);
    end;

    local procedure OpenGeneralJournalPage(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type") Amount: Decimal
    var
        DummyGeneralJournal: TestPage "General Journal";
    begin
        OpenGenJournalPage(DummyGeneralJournal, DocumentNo, DocumentType);
        LibraryVariableStorage.Enqueue(true); // Invoke set applies to ID action.
        DummyGeneralJournal."Apply Entries".Invoke();
        Amount := LibraryRandom.RandDec(10, 2);  // Used Random value to make difference in General Journal line Amount.
        DummyGeneralJournal.Amount.SetValue(DummyGeneralJournal.Amount.AsDecimal() - Amount);
        DummyGeneralJournal.OK().Invoke();
    end;

    local procedure OpenGenJournalPage(DummyGeneralJournal: TestPage "General Journal"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        DummyGeneralJournal.OpenEdit();
        DummyGeneralJournal.FILTER.SetFilter("Document No.", DocumentNo);
        DummyGeneralJournal.FILTER.SetFilter("Document Type", Format(DocumentType));
    end;

    local procedure RunVendorLedgerEntries(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);
    end;

    local procedure SetAdjustForPaymentDiscInVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; AdjustForPaymentDiscount: Boolean): Boolean
    var
        OldAdjustForPaymentDiscount: Boolean;
    begin
        OldAdjustForPaymentDiscount := VATPostingSetup."Adjust for Payment Discount";
        VATPostingSetup.Validate("Adjust for Payment Discount", AdjustForPaymentDiscount);
        VATPostingSetup.Modify(true);
        exit(OldAdjustForPaymentDiscount);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SetAppliesToIDAndPostEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry2: Record "Vendor Ledger Entry")
    begin
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry2);
    end;

    local procedure SetAppliesToIDAndAmountToApply(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Applying Entry", false);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.Validate("Applies-to ID", DocumentNo);
            VendorLedgerEntry.CalcFields("Remaining Amount");
            VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
            VendorLedgerEntry.Modify(true);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure SetPaymentTolerancePct(PaymentTolerance: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", PaymentTolerance);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SetApplnRoundingPrecision(ApplnRoundingPrecision: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Appln. Rounding Precision", ApplnRoundingPrecision);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SuggestVendorPayment(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20])
    var
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        Vendor.SetRange("No.", GenJournalLine."Account No.");
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.InitializeRequest(
          WorkDate(), false, 0, false, WorkDate(), GenJournalLine."Account No.", true, "Gen. Journal Account Type"::"Bank Account", BankAccountNo,
          GenJournalLine."Bank Payment Type"::"Manual Check");
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.RunModal();
    end;

    local procedure UpdateDirectUnitCostOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal)
    begin
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchaseAndPayableSetup(ApplnbetweenCurrencies: Option)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Appln. between Currencies", ApplnbetweenCurrencies);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UnapplyVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.SetRange(Open, false);
        VendorLedgerEntry.FindLast();
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure UnapplyVendLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgerEntry);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; AppliestoDocNo: Code[20]; Amount: Decimal)
    begin
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Validate(Amount, Amount + LibraryRandom.RandDec(5, 2));  // Modify Amount using Random value.
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        LibraryERM.SetGeneralPostingSetupPurchPmtDiscAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesPmtDiscAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateGenPostSetupWithPurchPmtDiscAccount(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        LibraryERM.SetGeneralPostingSetupPurchPmtDiscAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure VerifyAdditionalCurrencyAmount(DocumentNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        AdditionalCurrencyAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");
        FindGLEntries(GLEntry, DocumentNo);
        repeat
            AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(GLEntry.Amount, '', Currency.Code, WorkDate());
            Assert.AreNearlyEqual(
              AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", Currency."Amount Rounding Precision",
              StrSubstNo(AdditionalCurrencyErr, AdditionalCurrencyAmount));
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyEntriesAfterPostingPurchaseDocument(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20]; VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.TestField(Open, false);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo2);
        VendorLedgerEntry.TestField(Open, false);
        VerifyGLEntries(DocumentNo2);
        VerifyDetailedLedgerEntry(DocumentNo2, VendorNo);
    end;

    local procedure VerifyErrorAfterModifyPaymentMethod(DocumentNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, DocumentNo);
        asserterror VendLedgerEntry.Validate("Payment Method Code", '');
        Assert.ExpectedTestFieldError(VendLedgerEntry.FieldCaption(Open), Format(true));
    end;

    local procedure VerifyRemainingAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount", Amount);
            VendorLedgerEntry.TestField("Remaining Amount", VendorLedgerEntry.Amount);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyDetailedLedgerEntry(DocumentNo: Code[20]; VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TotalAmount: Decimal;
    begin
        FindDetailedLedgerEntry(DetailedVendorLedgEntry, DetailedVendorLedgEntry."Entry Type"::Application, DocumentNo, VendorNo);
        repeat
            TotalAmount += DetailedVendorLedgEntry.Amount;
        until DetailedVendorLedgEntry.Next() = 0;
        Assert.AreEqual(
          0, TotalAmount,
          StrSubstNo(
            TotalAmountErr, 0, DetailedVendorLedgEntry.TableCaption(), DetailedVendorLedgEntry.FieldCaption("Entry Type"),
            DetailedVendorLedgEntry."Entry Type"));
    end;

    local procedure VerifyApplnRoundingVendLedger(EntryType: Enum "Detailed CV Ledger Entry Type"; DocumentNo: Code[20]; Amount: Decimal; VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        FindDetailedLedgerEntry(DetailedVendorLedgEntry, EntryType, DocumentNo, VendorNo);
        Assert.AreEqual(
          Amount, DetailedVendorLedgEntry.Amount,
          StrSubstNo(AmountErr, DetailedVendorLedgEntry.FieldCaption(Amount), Amount, DetailedVendorLedgEntry.TableCaption()));
    end;

    local procedure VerifyUnappliedEntries(DocumentNo: Code[20]; VendorNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        FindDetailedLedgerEntry(DetailedVendorLedgEntry, DetailedVendorLedgEntry."Entry Type"::Application, DocumentNo, VendorNo);
        repeat
            Assert.IsTrue(
              DetailedVendorLedgEntry.Unapplied,
              StrSubstNo(
                UnappliedErr, DetailedVendorLedgEntry.FieldCaption(Unapplied), DetailedVendorLedgEntry.Unapplied,
                DetailedVendorLedgEntry.TableCaption()));
        until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure VerifySourceCodeDtldCustLedger(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; SourceCode: Code[10])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Document Type", DocumentType);
        DetailedVendorLedgEntry.SetRange("Source Code", SourceCode);
        Assert.IsTrue(DetailedVendorLedgEntry.FindFirst(), DetailedVendorLedgerErr);
    end;

    local procedure VerifyGenJournalEntry(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine2.SetRange("Account No.", GenJournalLine."Account No.");
        Assert.IsTrue(GenJournalLine2.FindFirst(), GeneralJournalErr);
        Assert.IsTrue(Amount > 0, NegativeAmountErr);
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        TotalAmount: Decimal;
    begin
        FindGLEntries(GLEntry, DocumentNo);
        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreEqual(
          0, TotalAmount, StrSubstNo(TotalAmountErr, 0, GLEntry.TableCaption(), GLEntry.FieldCaption("Document No."), GLEntry."Document No."));
    end;

    local procedure VerifyVATAmountOnGLEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntries(GLEntry, GenJournalLine."Document No.");
        Assert.AreNearlyEqual(
          GenJournalLine."VAT Amount", GLEntry."VAT Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmountErr, GLEntry."VAT Amount"));
    end;

    local procedure VerifyAmountToApplyOnVendorLedgerEntries(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.TestField("Amount to Apply", 0);
    end;

    local procedure VerifyGLEntriesWithDimSetIDs(DocumentNo: Code[20]; Amounts: array[10] of Decimal; DimSetIDs: array[10] of Integer; DimSetArrLen: Integer)
    var
        GLEntry: Record "G/L Entry";
        Index: Integer;
        "Sum": Decimal;
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindLast();
        GLEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        Assert.RecordCount(GLEntry, DimSetArrLen + 1);
        GLEntry.FindSet();
        for Index := 1 to DimSetArrLen do begin
            Assert.AreEqual(DimSetIDs[1], GLEntry."Dimension Set ID", GLEntry.FieldCaption("Dimension Set ID"));
            Assert.AreEqual(Amounts[Index], GLEntry.Amount, GLEntry.FieldCaption(Amount));
            Sum += Amounts[Index];
            GLEntry.Next();
        end;
        Assert.AreEqual(DimSetIDs[1], GLEntry."Dimension Set ID", GLEntry.FieldCaption("Dimension Set ID"));
        Assert.AreEqual(-Sum, GLEntry.Amount, GLEntry.FieldCaption(Amount));
    end;

    local procedure VerifyNoVATEntriesOnUnapplication(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Transaction No.", GetTransactionNoFromUnappliedDtldEntry(DocType, DocNo));
        Assert.IsTrue(VATEntry.IsEmpty, UnnecessaryVATEntriesFoundErr);
    end;

    local procedure VerifyACYInGLEntriesOnUnapplication(ExpectedACY: Decimal; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Transaction No.", GetTransactionNoFromUnappliedDtldEntry(DocType, DocNo));
        GLEntry.FindSet();
        repeat
            Assert.AreEqual(ExpectedACY, GLEntry."Additional-Currency Amount", NonzeroACYErr);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyVendorLedgEntryRemAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; RemAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", RemAmount);
    end;

    local procedure VerifyVendLedgerEntryRemAmtLCYisBalanced(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetRange("Document No.", DocumentNo);
        VendLedgerEntry.SetRange("Document Type", DocumentType);
        VendLedgerEntry.FindFirst();
        VendLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        VendLedgerEntry.TestField("Remaining Amt. (LCY)", Round(VendLedgerEntry."Remaining Amount" / VendLedgerEntry."Adjusted Currency Factor", 0.01));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        SetAppliesToIDValue: Variant;
        SetAppliesToID: Boolean;
    begin
        LibraryVariableStorage.Dequeue(SetAppliesToIDValue);
        SetAppliesToID := SetAppliesToIDValue;  // Assign Variant to Boolean.
        if SetAppliesToID then
            ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntriesPageHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        VendorLedgerEntries.ActionApplyEntries.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyingVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ControlBalance.AssertEquals(0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyAndVerifyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        QueueValue: Variant;
        PaymentAmount: Decimal;
        InvoiceAmount: Decimal;
        ExchangeRate: Decimal;
    begin
        LibraryVariableStorage.Dequeue(QueueValue);
        PaymentAmount := QueueValue;
        LibraryVariableStorage.Dequeue(QueueValue);
        InvoiceAmount := QueueValue;
        LibraryVariableStorage.Dequeue(QueueValue);
        ExchangeRate := QueueValue;

        // verify invoice entry
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        // apply entry
        ApplyVendorEntries.AppliedAmount.AssertEquals(Round(-InvoiceAmount * ExchangeRate, LibraryERM.GetAmountRoundingPrecision()));
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        // unapply
        // verify cr. memo entry
        ApplyVendorEntries.Next();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        // apply next entry
        ApplyVendorEntries.AppliedAmount.AssertEquals(Round(PaymentAmount * ExchangeRate, LibraryERM.GetAmountRoundingPrecision()));

        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandlerControlValuesVerification(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        Value: Variant;
        PurchaseLineAmountLCY: Decimal;
        JournalLineAmount: Decimal;
        PageControlValue: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Value);
        PurchaseLineAmountLCY := Value;
        LibraryVariableStorage.Dequeue(Value);
        JournalLineAmount := Value;
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();

        Evaluate(PageControlValue, ApplyVendorEntries.ApplnRounding.Value);
        Assert.AreEqual(
          PurchaseLineAmountLCY + JournalLineAmount, PageControlValue, ApplyVendorEntries.ApplnRounding.Caption);

        Evaluate(PageControlValue, ApplyVendorEntries.ControlBalance.Value);
        Assert.AreEqual(
          0, PageControlValue, ApplyVendorEntries.ControlBalance.Caption);

        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentToleranceWarning(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        // Modal Page Handler for Payment Tolerance Warning.
        PaymentToleranceWarning.InitializeOption(OptionValue);
        Response := ACTION::Yes
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Run Handler", 'OnBeforeRunVendExchRateAdjustment', '', false, false)]
    local procedure RunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var IsHandled: Boolean)
    var
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
    begin
        ExchRateAdjmtProcess.AdjustExchRateVend(GenJnlLine, TempVendorLedgerEntry);
        IsHandled := true;
    end;
}

