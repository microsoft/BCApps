codeunit 134006 "ERM Apply Unapply Customer"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Apply] [Unapply] [Sales]
        isInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMUnapply: Codeunit "Library - ERM Unapply";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        AdditionalCurrencyErr: Label 'Additional Currency Amount must be %1.', Locked = true;
        TotalAmountErr: Label 'Total Amount must be %1 in %2 table for %3 field : %4.', Locked = true;
        UnappliedErr: Label '%1 %2 field must be true after Unapply entries.', Locked = true;
        ApplicationEntryErr: Label '%1 No. %2 does not have an application entry.', Locked = true;
        AmountErr: Label '%1 must be %2 in %3.', Locked = true;
        UapplyExchangeRateErr: Label 'You cannot unapply the entry with the posting date %1, because the exchange rate for the additional reporting currency has been changed.', Locked = true;
        WrongFieldErr: Label 'Wrong value of field %1 in table %2.', Locked = true;
        UnnecessaryVATEntriesFoundErr: Label 'Unnecessary VAT Entries found.', Locked = true;
        NonzeroACYErr: Label 'Non-zero Additional Currency Amount in G/L Entry.', Locked = true;
        GLEntryCntErr: Label 'Wrong count of created G/L Entries.';
        DimBalanceErr: Label 'Wrong balance by Dimension.';
        SelectionFilterErr: Label 'Problem with selection filter: Original selection: %1. Returned selection: %2.', Comment = '%1: original selection filter;%2: returned selection filter';
        NoEntriesAppliedErr: Label 'Cannot post because you did not specify which entry to apply. You must specify an entry in the Applies-to ID field for one or more open entries.';
        VATEntryCntLbl: Label 'Wrong count of VAT Entries created.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Detailed Ledger Unapplied field is set to TRUE and Customer Ledger Entry and G/L entry have correct
        // Remaining Amount and Additional Currency amount after Apply and Unapply Ledger Entry as well.
        Initialize();
        ApplyUnapplyCustEntries(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Detailed Ledger Unapplied field is set to TRUE and Customer Ledger Entry and G/L entry have correct
        // Remaining Amount and Additional Currency amount for Credit Memo and Refund after Apply and Unapply Ledger Entry as well.
        Initialize();
        ApplyUnapplyCustEntries(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandInt(500));
    end;

    local procedure ApplyUnapplyCustEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup.
        LibraryERM.SetAddReportingCurrency(CreateCurrency());

        // Create, Post, Apply and Unapply General journal Lines.
        PostApplyUnapplyGenJournalLine(GenJournalLine, DocumentType, DocumentType2, Amount);

        // Verify: Detailed Ledger Unapplied field is set to TRUE, Customer Ledger Entry for Remaining amount
        // after Unapply applied entries and Additional Currency Amount on G/L Entry.
        VerifyUnappliedDtldLedgEntry(GenJournalLine."Document No.", DocumentType);
        VerifyCustLedgerEntryForRemAmt(GenJournalLine."Document Type", GenJournalLine."Document No.");
        VerifyAddCurrencyAmount(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyAndApplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Detailed Customer Ledger Entry and G/L entry have Amount Zero and Additional Currency amount after
        // Apply, Unapply and again Apply Unapplied Ledger Entry as well.
        Initialize();
        ApplyUnapplyApplyCustEntries(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyApplyRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that Detailed Customer Ledger Entry and G/L entry have Amount Zero and Additional Currency amount for Credit Memo
        // and Refund Entries after Apply, Unapply and again Apply Unapplied Ledger Entry as well.
        Initialize();
        ApplyUnapplyApplyCustEntries(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandInt(500));
    end;

    local procedure ApplyUnapplyApplyCustEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup.
        LibraryERM.SetAddReportingCurrency(CreateCurrency());

        // Create, Post, Apply, Unapply and again Apply Unapplied General journal Lines.
        PostApplyUnapplyGenJournalLine(GenJournalLine, DocumentType, DocumentType2, Amount);
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);

        // Verify: Detailed Customer Ledger Entry for Total Amount and Additional Currency Amount on G/L Entry.
        VerifyDetailedLedgerEntry(GenJournalLine."Document No.", DocumentType);
        VerifyAddCurrencyAmount(GenJournalLine."Document No.");
    end;

    local procedure PostApplyUnapplyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        NoOfLines: Integer;
    begin
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount);

        // Exercise: Apply and Unapply Posted General Lines for Customer Ledger Entry.
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);
        UnapplyCustLedgerEntry(DocumentType2, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyInvFromCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Invoice from Customer Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromCustLedgerEntry(GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentFromCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Payment from Customer Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromCustLedgerEntry(GenJournalLine."Document Type"::Payment, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCrMemoFromCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Credit Memo from Customer Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromCustLedgerEntry(GenJournalLine."Document Type"::"Credit Memo", -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefundFromCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Refund from Customer Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromCustLedgerEntry(GenJournalLine."Document Type"::Refund, LibraryRandom.RandDec(100, 2));
    end;

    local procedure UnapplyFromCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        // Setup: Create Customer,create and post General Journal Line,find Customer Ledger Entry.
        // Using 1 to create single General Journal Line.
        LibrarySales.CreateCustomer(Customer);
        SelectGenJournalBatch(GenJournalBatch, false);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, 1, Customer."No.", DocumentType, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, GenJournalLine."Document No.");

        // Exercise: Unapply Invoice/Payment/Credit Memo/Refund from Customer Ledger Entry.
        asserterror CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");

        // Verify: verify error message on Customer Ledger Entry.
        Assert.ExpectedError(StrSubstNo(ApplicationEntryErr, CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyInvFromDtldCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Invoice from Detailed Customer Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromDtldCustLedgerEntry(GenJournalLine."Document Type"::Invoice, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentDtldCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Payment from Detailed Customer Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromDtldCustLedgerEntry(GenJournalLine."Document Type"::Payment, -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCrMemoDtldCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Credit Memo from Detailed Customer Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromDtldCustLedgerEntry(GenJournalLine."Document Type"::"Credit Memo", -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefundDtldCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Refund from Detailed Customer Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        UnapplyFromDtldCustLedgerEntry(GenJournalLine."Document Type"::Refund, LibraryRandom.RandDec(100, 2));
    end;

    local procedure UnapplyFromDtldCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        // Setup: Create Customer, create and post General Journal Line,find Detailed Customer Ledger Entry.
        // Using 1 to create single General Journal Line.
        LibrarySales.CreateCustomer(Customer);
        SelectGenJournalBatch(GenJournalBatch, false);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, 1, Customer."No.", DocumentType, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindDetailedCustLedgerEntry(
          DetailedCustLedgEntry, GenJournalLine."Document No.", DocumentType, DetailedCustLedgEntry."Entry Type"::"Initial Entry");

        // Exercise: Unapply Invoice/Payment/Credit Memo/Refund from Detailed Customer Ledger Entry.
        asserterror CustEntryApplyPostedEntries.UnApplyDtldCustLedgEntry(DetailedCustLedgEntry);

        // Verify: verify error message on Detailed Customer Ledger Entry.
        Assert.ExpectedTestFieldError(DetailedCustLedgEntry.FieldCaption("Entry Type"), Format(DetailedCustLedgEntry."Entry Type"::Application));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyInvoiceCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Invoice from Customer Ledger Entry and Check that Detailed Ledger Unapplied field is set to TRUE and G/L entry have
        // correct Additional Currency amount.
        Initialize();
        UnapplyCustEntries(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandInt(500));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCreditMemoCustLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Credit Memo from Customer Ledger Entry and Check that Detailed Ledger Unapplied field is set to TRUE and G/L entry have
        // correct Additional Currency amount.
        Initialize();
        UnapplyCustEntries(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandInt(500));
    end;

    local procedure UnapplyCustEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
    begin
        // Setup.
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        LibraryERM.SetAddReportingCurrency(CreateCurrency());
        CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount);

        // Exercise: Apply and Unapply Posted General Lines for Customer Ledger Entry.
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);
        UnapplyCustLedgerEntry(DocumentType, GenJournalLine."Document No.");

        // Verify: Detailed Ledger Unapplied field is set to TRUE after Unapply applied entries and Additional Currency Amount on G/L Entry.
        VerifyUnappliedDtldLedgEntry(GenJournalLine."Document No.", DocumentType);
        VerifyAddCurrencyAmount(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LedgerEntryInvoiceUnapplyError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Unapply Error on Customer Ledger Entry when do the Unapply again on Unapplied Entries.
        Initialize();
        ApplyAndUnapplyLedgerEntry(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LedgerEntryCrMemoUnapplyError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Unapply Error on Customer Ledger Entry when do the Unapply again on Unapplied Entries for Credit Memo.
        Initialize();
        ApplyAndUnapplyLedgerEntry(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure ApplyAndUnapplyLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        DocumentNo: Code[20];
    begin
        // Setup: Apply and Unapply Posted General Lines.
        DocumentNo := CreateLinesApplyAndUnapply(DocumentType, DocumentType2, Amount);

        // Exercise: Find Customer Ledger Entry and Try to Unapply Again.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        asserterror CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");

        // Verify: Verify Unapply Error on Customer Ledger Entry.
        Assert.ExpectedError(StrSubstNo(ApplicationEntryErr, CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetldEntryInvoiceUnapplyError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Unapply Error on Detailed Customer Ledger Entry when do the Unapply again on Unapplied Entries.
        Initialize();
        ApplyAndUnapplyDetldEntry(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetldEntryCrMemoUnapplyError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Unapply Error on Detailed Customer Ledger Entry when do the Unapply again on Unapplied Entries for Credit Memo.
        Initialize();
        ApplyAndUnapplyDetldEntry(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure ApplyAndUnapplyDetldEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        DocumentNo: Code[20];
    begin
        // Setup: Apply and Unapply Posted General Lines.
        DocumentNo := CreateLinesApplyAndUnapply(DocumentType, DocumentType2, Amount);

        // Exercise: Find Detailed Ledger Entry and Try to Unapply.
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst();
        asserterror CustEntryApplyPostedEntries.UnApplyDtldCustLedgEntry(DetailedCustLedgEntry);

        // Verify: Verify Unapply Error on Detailed Customer Ledger Entry.
        Assert.ExpectedTestFieldError(DetailedCustLedgEntry.FieldCaption(Unapplied), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplySalesInvoice()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Detailed Customer Ledger Entry after Creating and Post Sales Invoice and Apply with Payment.
        Initialize();
        CreateAndApplySales(
          SalesLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplySalesCreditMemo()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Detailed Customer Ledger Entry after Creating and Post Sales Credit Memo and Apply with Refund.
        Initialize();
        CreateAndApplySales(
          SalesLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateAndApplySales(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; UnitPrice: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Create and Post Sales Document with Apply Payment.
        CreatePostSalesAndGenLine(GenJournalLine, DocumentType, DocumentType2, UnitPrice);

        // Verify: Verify Detailed Ledger Entry after Apply.
        VerifyInvDetailedLedgerEntry(
          GenJournalLine."Document No.", DocumentType2, GenJournalLine.Amount, DetailedCustLedgEntry."Entry Type"::Application);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplySalesInvoice()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Detailed Customer Ledger Entry after Creating and Post Sales Invoice and Apply then Unapply with Payment.
        Initialize();
        CreateAndApplyUnapplySales(
          SalesLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplySalesCreditMemo()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Detailed Customer Ledger Entry after Creating and Post Sales Credit Memo and Apply then Unapply with Refund.
        Initialize();
        CreateAndApplyUnapplySales(
          SalesLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateAndApplyUnapplySales(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; UnitPrice: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and Post Sales Document with Apply Payment.
        CreatePostSalesAndGenLine(GenJournalLine, DocumentType, DocumentType2, UnitPrice);

        // Exericse: Unapply Applied Entries.
        UnapplyCustLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify Detailed Ledger Entry after Apply and Unapply.
        VerifyDetailedLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Document Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentCheckSourceCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that correct Source Code updated on Detailed Customer Ledger Entry after Unapply Payment from Customer Ledger Entry.
        // Use Random Number Generator for Amount.
        Initialize();
        ApplyUnapplyAndCheckSourceCode(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefundCheckSourceCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that correct Source Code updated on Detailed Customer Ledger Entry after Unapply Refund from Customer Ledger Entry.
        // Use Random Number Generator for Amount.
        Initialize();
        ApplyUnapplyAndCheckSourceCode(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure ApplyUnapplyAndCheckSourceCode(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        SourceCode: Record "Source Code";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create Source Code, update Source Code Setup, create and post General Journal Lines.
        LibraryERM.CreateSourceCode(SourceCode);
        CreateAndUpdateSourceCodeSetup(SourceCode.Code);
        CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, 1, Amount);
        // Using 1 to create one line for Payment/Refund.

        // Exercise: Apply and Unapply Payment/Refund from Customer Ledger Entry.
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);
        UnapplyCustLedgerEntry(GenJournalLine."Document Type", GenJournalLine."Document No.");

        // Verify: Verify that correct Source Code updated on Detailed Customer Ledger Entry.
        VerifySourceCodeDtldCustLedger(DocumentType, GenJournalLine."Document No.", SourceCode.Code);
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
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandInt(500));
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
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandInt(500));
    end;

    local procedure ChangeExchRateUnapply(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        PostingDate: Date;
    begin
        // Setup: Update General Ledger Setup, Create and post General Journal Lines, Apply Payment/Refund from Customer Ledger Entry.
        LibraryERM.SetAddReportingCurrency(CreateCurrency());
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'M>', WorkDate());
        CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, 1, Amount);  // Using 1 to create single Payment/Refund line.
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);
        CreateNewExchangeRate(PostingDate);
        FindDetailedCustLedgerEntry(
          DetailedCustLedgEntry, GenJournalLine."Document No.", DocumentType, DetailedCustLedgEntry."Entry Type"::Application);

        // Exercise: Unapply Payment/Refund from Customer Ledger Entry.
        ApplyUnapplyParameters."Document No." := GenJournalLine."Document No.";
        ApplyUnapplyParameters."Posting Date" := PostingDate;
        asserterror CustEntryApplyPostedEntries.PostUnApplyCustomer(DetailedCustLedgEntry, ApplyUnapplyParameters);

        // Verify: Verify error on Unapply after Exchange Rate has been changed.
        Assert.ExpectedError(StrSubstNo(UapplyExchangeRateErr, WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentDiscApplyInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Payment Discount Entry for Customer after Apply Payment with Invoice.
        Initialize();
        ApplyPaymentDiscount(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentDiscApplyCM()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Payment Discount Entry for Customer after Apply Refund with Credit Memo.
        Initialize();
        ApplyPaymentDiscount(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure ApplyPaymentDiscount(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DocumentNo: Code[20];
    begin
        // Check Payment Discount Entry for Customer after Apply Payment with Invoice.
        Amount := CreateAndApplyGenLines(DocumentNo, DocumentType, DocumentType2, Amount);

        // Verify: Verify Detailed Customer Ledger Entry for Payment Discount Amount after Apply.
        VerifyInvDetailedLedgerEntry(DocumentNo, DocumentType2, -Amount, DetailedCustLedgEntry."Entry Type"::"Payment Discount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentDiscApplyUnapplyInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Payment Discount Entry for Customer after Apply and Unapply Payment with Invoice.
        Initialize();
        ApplyUnapplyPaymentDiscount(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentDiscApplyUnapplyCM()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Payment Discount Entry for Customer after Apply and Unapply Refund with Credit Memo.
        Initialize();
        ApplyUnapplyPaymentDiscount(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure ApplyUnapplyPaymentDiscount(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DocumentNo: Code[20];
    begin
        // Check Payment Discount Entry for Customer after Apply and Unapply Payment with Invoice.
        Amount := CreateAndApplyGenLines(DocumentNo, DocumentType, DocumentType2, Amount);

        // Exercise.
        UnapplyCustLedgerEntry(DocumentType2, DocumentNo);

        // Verify: Verify Detailed Customer Ledger Entry for Payment Discount Amount after Apply and Unapply.
        VerifyInvDetailedLedgerEntry(DocumentNo, DocumentType2, -Amount, DetailedCustLedgEntry."Entry Type"::"Payment Discount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDocumentNoUnapplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Document No can be change when Unapply Payment from Customer Ledger Entry.
        // Use Random Number Generator for Amount.
        Initialize();
        ChangeDocumentNoAndUnapply(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDocumentNoUnapplyRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Document No can be change when Unapply Refund from Customer Ledger Entry.
        // Use Random Number Generator for Amount.
        Initialize();
        ChangeDocumentNoAndUnapply(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure ChangeDocumentNoAndUnapply(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post General Journal Lines, Apply Payment/Refund from Customer Ledger Entry.
        CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, 1, Amount);  // Using 1 to create single Payment/Refund line.
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);
        FindDetailedCustLedgerEntry(
          DetailedCustLedgEntry, GenJournalLine."Document No.", DocumentType, DetailedCustLedgEntry."Entry Type"::Application);
        DocumentNo := GenJournalLine."Account No.";

        // Exercise: Change Document No and Unapply Payment/Refund from Customer Ledger Entry.
        ApplyUnapplyParameters."Document No." := GenJournalLine."Account No.";
        ApplyUnapplyParameters."Posting Date" := GenJournalLine."Posting Date";
        CustEntryApplyPostedEntries.PostUnApplyCustomer(DetailedCustLedgEntry, ApplyUnapplyParameters);

        // Verify: Verify Detailed Customer Ledger Entry with updated Document No exist after Unapply.
        Assert.IsTrue(
          FindDetailedCustLedgerEntry(DetailedCustLedgEntry, DocumentNo, DocumentType, DetailedCustLedgEntry."Entry Type"::Application),
          'Not found Application entry with updated Document No.');
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure RemainingAmountOnCustLedgerEntryWithoutCurrency()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Check Remaining Amount on Customer Ledger Entry after Creating and Posting Sales Invoice without Currency and Apply with Partial Payment.

        // Setup: Create and Post Sales Invoice, Create a Customer Payment and apply it to posted Invoice.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateAndModifySalesLine(SalesHeader, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SelectGenJournalBatch(GenJournalBatch, false);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, 1, SalesHeader."Sell-to Customer No.", GenJournalLine."Document Type"::Payment, 0);  // Taken 1 and 0 to create only one General Journal line with zero amount.
        Amount := OpenGeneralJournalPage(GenJournalLine."Document No.", GenJournalLine."Document Type");
        GenJournalLine.Find();
        GenJournalLine.Validate(Amount, GenJournalLine.Amount + Amount);
        GenJournalLine.Modify(true);

        // Exericse.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Remaining Amount on Customer Ledger Entry.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, SalesHeader."Document Type", PostedDocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountOnCustLedgerEntryWithCurrency()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Check Remaining Amount on Customer Ledger Entry after Creating and Posting Sales Invoice with Currency and Apply with Partial Payment.

        // Setup: Create and Post Sales Invoice with Currency, Create a Customer Payment without Currency and apply it to posted Invoice after modifying Payment Amount.
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithCurrency(CreateCurrency()));
        ModifyCurrency(SalesHeader."Currency Code", LibraryRandom.RandDec(10, 2));  // Taken Random value for Rounding Precision.
        Amount := CreateAndModifySalesLine(SalesHeader, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        Amount := LibraryERM.ConvertCurrency(Amount, SalesHeader."Currency Code", '', WorkDate());
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SelectGenJournalBatch(GenJournalBatch, false);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, 1, SalesHeader."Sell-to Customer No.", GenJournalLine."Document Type"::Payment, 0);  // Taken 1 and 0 to create only one General Journal line with zero amount.
        UpdateGenJournalLine(GenJournalLine, '', '', -Amount);

        // Exericse.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::Payment,
          PostedDocumentNo, GenJournalLine."Document No.");

        // Verify: Verify Remaining Amount on Customer Ledger Entry.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", 0);  // Taken 0 for Remaining Amount as after application it must be zero due to Currency's Appln. Rounding Precision.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderUsingPaymentMethodWithBalanceAccount()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Check General Ledger, Customer Ledger and Detailed Customer ledger entries after Posting Sales Order with Currency and Payment method with a balance account.

        // Setup: Modify General Ledger setup for Appln. Rounding Precision and Create Customer with Currency and with Payment method with a balance account.
        Initialize();
        LibraryERM.SetApplnRoundingPrecision(LibraryRandom.RandDec(10, 2));  // Taken Random value for Rounding Precision.
        CreateAndModifyCustomer(Customer, Customer."Application Method"::Manual, FindPaymentMethodWithBalanceAccount());  // Taken Zero value for Currency Application Rounding Precision.

        // Exercise: Create and post Sales Order with Random Quantity and Unit Price.
        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), Customer."No.", LibraryInventory.CreateItemNo(), SalesHeader."Document Type"::Order,
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));

        // Verify: Verify GL, Customer and Detailed Customer ledger entries.
        VerifyEntriesAfterPostingSalesDocument(CustLedgerEntry."Document Type"::Payment, DocumentNo, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyPaymentMethodCodeInCustLedgEntryClosed()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        CreateAndModifyCustomer(Customer, Customer."Application Method"::Manual, FindPaymentMethodWithBalanceAccount());

        // Exercise: Create and post Sales Order.
        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), Customer."No.", LibraryInventory.CreateItemNo(), SalesHeader."Document Type"::Order,
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));

        // Verify: Try to modify Payment Method Code in Customer Ledger Entry.
        VerifyErrorAfterModifyPaymentMethod(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocumentUsingApplicationMethodApplyToOldest()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Item: Record Item;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Check General Ledger, Customer Ledger and Detailed Customer ledger entries after posting Sales documents with Currency and Apply to Oldest Application Method.

        // Setup: Modify General Ledger setup for Appln. Rounding Precision and Create Customer with Currency and with Apply to Oldest Application Method, Create and post Sales Invoice with Random Quantity and Unit Price.
        Initialize();
        LibraryERM.SetApplnRoundingPrecision(LibraryRandom.RandDec(10, 2));  // Taken Random value for Rounding Precision.
        LibraryERM.FindPaymentMethod(PaymentMethod);
        CreateAndModifyCustomer(Customer, Customer."Application Method"::"Apply to Oldest", PaymentMethod.Code);
        ModifyCurrency(Customer."Currency Code", LibraryRandom.RandDec(10, 2));  // Taken Random value for Rounding Precision.
        LibraryInventory.CreateItem(Item);
        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), Customer."No.", Item."No.", SalesHeader."Document Type"::Invoice,
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));

        // Exercise: Create and post Sales Credit Memo.
        DocumentNo2 :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), Customer."No.", Item."No.", SalesHeader."Document Type"::"Credit Memo",
            SalesLine.Quantity, SalesLine."Unit Price");

        // Verify: Verify GL, Customer and Detailed Customer ledger entries.
        VerifyEntriesAfterPostingSalesDocument(CustLedgerEntry."Document Type"::"Credit Memo", DocumentNo, DocumentNo2);
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler,ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AmountToApplyAfterApplyToEntryForInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Verify Amount To Apply on Customer Ledger Entries after Invoking Apply Customer Entries for Invoice.

        // Setup: Post Invoice and Payment for Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        DocumentNo := CreateAndPostSalesInvoiceAndPayment(Customer."No.", GenJournalLine); // Do not invoke set applies to ID action

        // Exercise: Run Page Customer Ledger Entries to invoke Apply Customer Entries.
        RunCustomerLedgerEntries(Customer."No.", DocumentNo);

        // Verify: Verify Amount To Apply on Customer Ledger Entries for Document Type Invoice.
        VerifyAmountToApplyOnCustomerLedgerEntries(DocumentNo, SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler,ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AmountToApplyAfterApplyToEntryForPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // Verify Amount To Apply on Customer Ledger Entries after Invoking Apply Customer Entries for Payment.

        // Setup: Post Invoice and Payment for Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesInvoiceAndPayment(Customer."No.", GenJournalLine); // Do not invoke set applies to ID action

        // Exercise: Run Page Customer Ledger Entries to invoke Apply Customer Entries.
        RunCustomerLedgerEntries(Customer."No.", GenJournalLine."Document No.");

        // Verify: Verify Amount To Apply on Customer Ledger Entries for Document Type Payment.
        VerifyAmountToApplyOnCustomerLedgerEntries(GenJournalLine."Document No.", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler,ApplyAndVerifyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AppliedAmountDifferentCurrencies()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CurrencyCode: Code[10];
        ExchangeRateAmount: Decimal;
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // Verify Applied Amount on Apply Entries Page when applying entries in different currencies

        // Setup
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        SelectGenJournalBatch(GenJournalBatch, false);
        ExchangeRateAmount := LibraryRandom.RandDecInRange(10, 50, 2);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount);
        PaymentAmount := LibraryRandom.RandDecInRange(100, 1000, 2);
        InvoiceAmount := PaymentAmount * LibraryRandom.RandIntInRange(3, 5);

        // Exercise
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, WorkDate(), GenJournalLine."Document Type"::Invoice,
          Customer."No.", '', InvoiceAmount);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, WorkDate(), GenJournalLine."Document Type"::"Credit Memo",
          Customer."No.", '', -PaymentAmount);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, WorkDate(), GenJournalLine."Document Type"::Payment,
          Customer."No.", CurrencyCode, -PaymentAmount);

        LibraryVariableStorage.Enqueue(PaymentAmount);
        LibraryVariableStorage.Enqueue(InvoiceAmount);
        LibraryVariableStorage.Enqueue(ExchangeRateAmount);

        // Verify: verification in page handler
        RunCustomerLedgerEntries(Customer."No.", GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithPmtDiscExclVATWithBalAccTypeVAT()
    begin
        // To verify that program calculate correct payment discount value in customer ledger entry when Pmt. Disc. Excl. VAT is true while Bal Account Type having VAT.
        Initialize();
        CreateAndPostGenJournalLineWithPmtDiscExclVAT(true, LibraryERM.CreateGLAccountWithSalesSetup());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithPmtDiscExclVATWithOutBalAccTypeVAT()
    begin
        // To verify that program calculate correct payment discount value in customer ledger entry when Pmt. Disc. Excl. VAT is true while Bal Account Type does not having VAT.
        Initialize();
        CreateAndPostGenJournalLineWithPmtDiscExclVAT(true, LibraryERM.CreateGLAccountNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithOutPmtDiscExclVATWithBalAccTypeVAT()
    begin
        // To verify that program calculate correct payment discount value in customer ledger entry when Pmt. Disc. Excl. VAT is false while Bal Account Type having VAT.
        Initialize();
        CreateAndPostGenJournalLineWithPmtDiscExclVAT(false, LibraryERM.CreateGLAccountWithSalesSetup());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithOutPmtDiscExclVATWithOutBalAccTypeVAT()
    begin
        // To verify that program calculate correct payment discount value in customer ledger entry when Pmt. Disc. Excl. VAT is false while Bal Account Type does not having VAT.
        Initialize();
        CreateAndPostGenJournalLineWithPmtDiscExclVAT(false, LibraryERM.CreateGLAccountNo());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDiscountValueWithPmtDiscExclVatWithBalVATAmount()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        PmtDiscAmount: Decimal;
    begin
        // To verify that program calculate correct payment discount value in customer ledger entry when Pmt. Disc. Excl. VAT is true while Bal VAT. Amount is not equal to zero.

        // Setup: Create customer and Create Gen Journal Line with Bal Account No.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(true);
        CreateCustomerWithPaymentTerm(Customer);

        // Exercise:Create - Post Gen. Journal Line.
        CreatePostGenJnlLineWithBalAccount(GenJournalLine, Customer."No.");

        // Verify: Verify Customer Ledger Entry.
        PaymentTerms.Get(Customer."Payment Terms Code");
        PmtDiscAmount :=
          Round((GenJournalLine.Amount + Abs(GenJournalLine."Bal. VAT Amount (LCY)")) * PaymentTerms."Discount %" / 100);
        VerifyDiscountValueInCustomerLedger(GenJournalLine, PmtDiscAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplySalesInvoicesWithDimVals()
    begin
        // Verify that Dimension Set ID and Global Dimension values are correct after unapply of Customer Ledger Entries with different Dimension Set IDs.
        Initialize();
        ApplyUnapplyCustEntriesWithMiscDimSetIDs(LibraryRandom.RandIntInRange(3, 10));
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPHAndPageControlValuesVerification')]
    [Scope('OnPrem')]
    procedure RoundingAndBalanceAmountsOnInvoiceApplication()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Item: Record Item;
        LineAmount: Decimal;
        CurrencyFactor: Decimal;
        ApplicationRoundingPrecision: Decimal;
    begin
        // Verify Application Rounding and Balance amounts
        // Setup.
        ApplicationRoundingPrecision := 1;
        LineAmount := 99;
        // prime numbers are required to obtain non-whole number after currency conversion
        CurrencyFactor := 7 / 3;
        LibraryERM.SetApplnRoundingPrecision(ApplicationRoundingPrecision);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Invoice Rounding Precision", 0.01);
        Currency.Modify(true);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), CurrencyFactor, CurrencyFactor);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);
        SelectGenJournalBatch(GenJournalBatch, false);

        // Excercise
        CreateAndPostSalesDocument(
          SalesLine, WorkDate(), Customer."No.", LibraryInventory.CreateItem(Item), SalesHeader."Document Type"::Invoice,
          1, LineAmount);
        LineAmount := SalesLine."Amount Including VAT";
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, 1, Customer."No.", GenJournalLine."Document Type"::Payment,
          -1 * Round(LineAmount / CurrencyFactor, ApplicationRoundingPrecision, '<'));
        GenJournalLine.Validate("Currency Code", '');
        GenJournalLine.Modify(true);

        // Verify is done in page handler
        LibraryVariableStorage.Enqueue(Round(LineAmount / CurrencyFactor, Currency."Invoice Rounding Precision"));
        LibraryVariableStorage.Enqueue(GenJournalLine.Amount);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAppliesToCrMemoDocNoForRefund()
    var
        Customer: Record Customer;
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // Verify that "Applies To Doc. No." can be validated with "Credit Memo" for Refund journal line.

        // Setup: Post credit memo and create empty refund line without customer and amount.
        Initialize();
        SelectGenJournalBatch(GenJnlBatch, false);
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJournalLines(
          GenJnlLine, GenJnlBatch, 1, Customer."No.", GenJnlLine."Document Type"::"Credit Memo", -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgEntry, CustLedgEntry."Document Type"::"Credit Memo", GenJnlLine."Document No.");

        CreateGeneralJournalLines(GenJnlLine, GenJnlBatch, 1, '', GenJnlLine."Document Type"::Refund, 0);

        // Exercise: Set open Credit Memo No. for "Applies To Doc. No".
        GenJnlLine.Validate("Applies-to Doc. No.", CustLedgEntry."Document No.");
        GenJnlLine.Modify(true);

        // Verify: Customer No. and "Applies To Doc. Type" are filled correctly.
        Assert.AreEqual(
          CustLedgEntry."Customer No.", GenJnlLine."Account No.",
          StrSubstNo(WrongFieldErr, GenJnlLine.FieldCaption("Account No."), GenJnlLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoVATEntriesWhenUnapplyZeroDiscEntryWithAdjForPmtDisc()
    var
        SalesLine: Record "Sales Line";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        PostedDocumentNo: Code[20];
        EmptyDocumentType: Enum "Gen. Journal Document Type";
    begin
        // [FEATURE] [Reverse Charge VAT] [Adjust For Payment Discount]
        // [SCENARIO 229786] There are no VAT and G/L Entries created when unapplies the entry without discount but with Reverse Charge and "Adjust For Payment Discount"
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        EmptyDocumentType := GenJnlLine."Document Type"::" ";

        // [GIVEN] Posted invoice with Reverse Charge VAT setup with "Adjust For Payment Discount"
        PostedDocumentNo :=
          CreatePostSalesInvWithReverseChargeVATAdjForPmtDisc(SalesLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, PostedDocumentNo);
        CustLedgEntry.CalcFields("Amount (LCY)");

        // [GIVEN] Post and apply document with empty document type
        CreateGenJnlLineWithPostingGroups(GenJnlLine, SalesLine."Sell-to Customer No.",
          EmptyDocumentType, -CustLedgEntry."Amount (LCY)", SalesLine);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", PostedDocumentNo);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [WHEN] Unapply the empty document application
        GLEntry.FindLast();
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, EmptyDocumentType, GenJnlLine."Document No.");
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgEntry);

        // [THEN] There is no VAT and G/L Entries have been created on unapplication
        VerifyNoVATEntriesOnUnapplication(EmptyDocumentType, GenJnlLine."Document No.");
        GLEntry.SetFilter("Entry No.", '>%1', GLEntry."Entry No.");
        Assert.RecordIsEmpty(GLEntry);

        // Cleanup: Return back the old value of "Adjust For Payment Discount".
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('UnapplyCustomerEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ConsistentUnapplyInvoiceToPayment()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CustomerNo: Code[20];
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
        CreateCustomerAndItem(CustomerNo, ItemNo, ForeignCurrencyCode);
        LibraryERM.SetAddReportingCurrency(AdditionalCurrencyCode);

        // [GIVEN] Posted Sales Invoice for Customer with foreigh currency
        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine, InvoiceDate, CustomerNo, ItemNo, SalesLine."Document Type"::Invoice, 1, 5000);
        // [GIVEN] Payment in ACY applied to Sales Invoice
        PostApplyPaymentForeignCurrency(
          GenJournalLine, CustomerNo, AdditionalCurrencyCode, -4132.91,
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo);

        // [WHEN] Invoice unapplied from payment
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No."); // cannot repro via LibraryERM.UnapplyCustomerLedgerEntry

        // [THEN] Reversal G/L Entries have zero ACY Amounts
        VerifyACYInGLEntriesOnUnapplication(0, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('UnapplyCustomerEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyUnapplySeveralInvAndPmtWithDifferentDimValues()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
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

        // [GIVEN] Customer with possible discount
        DiscountPercent := LibraryRandom.RandIntInRange(1, 10);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        CreateCustomerWithGivenPaymentTerm(Customer, CreatePaymentTermsWithDiscount(DiscountPercent));

        NoOfDocuments := LibraryRandom.RandIntInRange(3, 10);
        for i := 1 to NoOfDocuments do begin
            Amounts[i] := 100 * LibraryRandom.RandIntInRange(1, 100);
            DiscountedAmounts[i] := Amounts[i] * (100 - DiscountPercent) / 100;
        end;

        // [GIVEN] Post "N" Invoices with different dimensions "InvDims[i]" and amounts "Amounts[i]"
        SelectGenJournalBatch(GenJournalBatch, false);
        CreatePostGenJnlLinesWithDimSetIDs(
          GenJournalLine, GenJournalBatch, InvDimSetIDs, NoOfDocuments,
          Customer."No.", GenJournalLine."Document Type"::Invoice, Amounts, 1);

        // [GIVEN] Create "N" Gen. Journal Lines with different dimensions "PmtDims[i]" and "Document Type" = Payment
        CreateGenJnlLinesWithDimSetIDs(
          GenJournalLine, GenJournalBatch, PmtDimSetIDs, NoOfDocuments,
          Customer."No.", GenJournalLine."Document Type"::Payment, DiscountedAmounts, -1);

        // [GIVEN] Set Gen. Journal Lines "Applies-to ID" and select customer Invoices Ledger Entries
        ApplyCustLedgerEntriesToID(Customer."No.", GenJournalLine."Document No.", DiscountedAmounts);

        // [GIVEN] Post Gen. Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Unapply "N" Invoices Ledger Entries
        for i := 1 to NoOfDocuments do begin
            FindClosedInvLedgerEntry(CustLedgEntry, Customer."No.");
            CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgEntry."Entry No.");
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
    procedure GetSelectionFilterForCustomerWithSortDescending()
    var
        Customer: Record Customer;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        OriginalSelection: Text;
        ReturnedSelection: Text;
    begin
        // [FEATURE] [UT] [Selection Filter Management]
        // [SCENARIO 379971] When select filter for customers with sort descending, filter must shows selection result
        Initialize();

        // [GIVEN] Customer record with descending order
        Customer.Ascending(false);

        // [GIVEN] Customer's filter on "No." field = "1000..1001"
        OriginalSelection := SetFilterForCustomerWithSortDescending(Customer);

        // [WHEN] Call SelectionFilterManagement.GetSelectionFilterForCustomer
        ReturnedSelection := SelectionFilterManagement.GetSelectionFilterForCustomer(Customer);

        // [THEN] Return filter = "1000..1001"
        Assert.AreEqual(OriginalSelection, ReturnedSelection, StrSubstNo(SelectionFilterErr, OriginalSelection, ReturnedSelection));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSelectionFilterForCustomerWithSortAscending()
    var
        Customer: Record Customer;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        OriginalSelection: Text;
        ReturnedSelection: Text;
    begin
        // [FEATURE] [UT] [Selection Filter Management]
        // [SCENARIO 379971] When select filter for customers with sort ascending, filter must shows selection result
        Initialize();

        // [GIVEN] Customer record with ascending order

        // [GIVEN] Customer's filter on "No." field = "1000..1001"
        OriginalSelection := SetFilterForCustomerWithSortDescending(Customer);

        // [WHEN] Call SelectionFilterManagement.GetSelectionFilterForCustomer
        ReturnedSelection := SelectionFilterManagement.GetSelectionFilterForCustomer(Customer);

        // [THEN] Return filter = "1000..1001"
        Assert.AreEqual(OriginalSelection, ReturnedSelection, StrSubstNo(SelectionFilterErr, OriginalSelection, ReturnedSelection));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageOnApplyWithoutAplliesToID()
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DummyGenJournalLine: Record "Gen. Journal Line";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        Amount: Decimal;
        DocNo: Code[20];
    begin
        // [SCENARIO 380040] During application, if there is no "Applies-to ID", then "The application could not be posted, because no entry
        // [SCENARIO] has been selected to be applied / for none of the open entries the "Applies-to ID" has been specfied." error message should appear

        Initialize();

        // [GIVEN] Customer CCC
        // [GIVEN] Gen. Journal Batch GJB with two lines
        // [GIVEN] Gen. Journal Line JL1: an invoice for Customer CCC with "Document No" = 123 and "Amount" = -1000
        // [GIVEN] Gen. Journal Line JL2: a payment for Customer CCC with "Document No" = 123 (same as JL1) and "Amount" = 1000
        // [GIVEN] Batch GJB posted
        Amount := LibraryRandom.RandDec(1000, 2);
        DocNo := LibraryERM.CreateAndPostTwoGenJourLinesWithSameBalAccAndDocNo(
            DummyGenJournalLine, DummyGenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo(), -Amount);

        // [GIVEN] Openned Customer Ledger Entries for Customer CCC, selected Payment JL2 and called action "Apply Entries"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocNo);

        // [WHEN] Apply Payment to Invoice
        ApplyUnapplyParameters."Document No." := DocNo;
        ApplyUnapplyParameters."Posting Date" := WorkDate();
        asserterror CustEntryApplyPostedEntries.Apply(CustLedgerEntry, ApplyUnapplyParameters);

        // [THEN] The following message appears: Cannot post because you did not specify which entry to apply. You must specify an entry in the Applies-to ID field for one or more open entries.
        Assert.ExpectedError(NoEntriesAppliedErr);
    end;

    [Test]
    [HandlerFunctions('UnapplyCustomerEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyEntryWithLaterExchRateAdjustment()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        ERMApplyUnapplyCustomer: Codeunit "ERM Apply Unapply Customer";
        Amount: array[2] of Decimal;
        PostingDate: array[3] of Date;
        CurrencyCode: Code[10];
        Rate: Decimal;
    begin
        // [FEATURE] [FCY] [Adjust Exchange Rate]
        // [SCENARIO 304391] "Remaining Amt. (LCY)" should match "Adjusted Currency Factor" after Unapply of the entry being adjusted on the later date.
        Initialize();
        BindSubscription(ERMApplyUnapplyCustomer);

        // [GIVEN] USD has different exchange rates on 01.01, 15.01, 31.01.
        PostingDate[1] := WorkDate();
        PostingDate[2] := PostingDate[1] + 1;
        PostingDate[3] := PostingDate[2] + 1;
        Rate := LibraryRandom.RandDec(10, 2);
        CurrencyCode := CreateCurrencyAndExchangeRate(Rate, 1, PostingDate[1]);
        CreateExchangeRate(CurrencyCode, Rate * 1.2, 1, PostingDate[2]);
        CreateExchangeRate(CurrencyCode, Rate * 0.85, 1, PostingDate[3]);

        // [GIVEN] Invoice of 100 USD posted on 01.01, where "Document No." is 'INV001'
        LibrarySales.CreateCustomer(Customer);
        SelectGenJournalBatch(GenJournalBatch, false);
        Amount[1] := LibraryRandom.RandDecInRange(10000, 20000, 2);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine[1], GenJournalBatch, PostingDate[1],
          GenJournalLine[1]."Document Type"::Invoice, Customer."No.", CurrencyCode, Amount[1]);

        // [GIVEN] Payment of 150 USD posted on 15.01, applied to Invoice
        Amount[2] := Round(-Amount[1] * 1.5, 0.01);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine[2], GenJournalBatch, PostingDate[2],
          GenJournalLine[2]."Document Type"::Payment, Customer."No.", CurrencyCode, Amount[2]);
        ApplyAndPostCustomerEntry(
          GenJournalLine[1]."Document No.", GenJournalLine[2]."Document No.", Amount[1],
          GenJournalLine[1]."Document Type", GenJournalLine[2]."Document Type");

        // [GIVEN] Payment has been adjusted by "Adjust Exchange Rate" on 31.01
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, PostingDate[3], PostingDate[3]);

        // [WHEN] Unapply Invoice and Payment on 15.01
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine[1]."Document Type", GenJournalLine[1]."Document No.");
        CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");
        UnbindSubscription(ERMApplyUnapplyCustomer);

        // [THEN] This Payment is balanced to its adjusted exchange rate
        VerifyCustLedgerEntryRemAmtLCYisBalanced(GenJournalLine[1]."Document No.", GenJournalLine[1]."Document Type");

        // [THEN] This invoice is balanced to its adjusted exchange rate
        VerifyCustLedgerEntryRemAmtLCYisBalanced(GenJournalLine[2]."Document No.", GenJournalLine[2]."Document Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingACYWhenPaymentAppliedToInvoiceWithRevChargeVAT()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        TaxCalculationType: Enum "Tax Calculation Type";
        PaymentDate: Date;
        InvoiceNo: Code[20];
        CurrencyCode: Code[10];
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
        InvoiceNo :=
          CreatePostSalesInvVATAdjForPmtDiscSetValues(SalesLine, CurrencyCode, 1, 678, 3.5, 25, TaxCalculationType::"Reverse Charge VAT");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.CalcFields(Amount);

        // [GIVEN] Payment of amount 654,27 on 02.01
        CreateGenJnlLineWithPostingGroups(
          GenJournalLine, SalesLine."Sell-to Customer No.", GenJournalLine."Document Type"::Payment,
          -CustLedgerEntry.Amount + CustLedgerEntry."Remaining Pmt. Disc. Possible", SalesLine);
        GenJournalLine.Validate("Posting Date", PaymentDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Payment is applied to the invoice
        ApplyAndPostCustomerEntry(
          InvoiceNo, GenJournalLine."Document No.",
          CustLedgerEntry.Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible",
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::Payment);

        // [THEN] Amount and "Additional-Currency Amount" = 0 in reverse charge VAT Entry created for the payment
        VATEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.FindLast();
        VATEntry.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        VATEntry.TestField(Amount, 0);
        VATEntry.TestField("Additional-Currency Amount", 0);
    end;

    [Test]
    [HandlerFunctions('UnapplyCustomerEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyMultipleEntrisAfterExchRateAdjustment()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        ERMApplyUnapplyCustomer: Codeunit "ERM Apply Unapply Customer";
        Amount: array[3] of Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [FCY] [Adjust Exchange Rate]
        // [SCENARIO 360284] Two Invoices are correctly unapplied from the Payment after running Currency Adjustment for the later date
        Initialize();
        BindSubscription(ERMApplyUnapplyCustomer);

        // [GIVEN] Create Currency Code with Exchange Rate "ER1" for 01.01
        CurrencyCode := CreateCurrencyAndExchangeRate(LibraryRandom.RandDec(10, 2), 1, WorkDate());

        // [GIVEN] Invoice "INV001" of 100 USD posted on 01.01
        LibrarySales.CreateCustomer(Customer);
        SelectGenJournalBatch(GenJournalBatch, false);
        Amount[1] := LibraryRandom.RandDecInRange(10000, 20000, 2);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine[1], GenJournalBatch, WorkDate(),
          GenJournalLine[1]."Document Type"::Invoice, Customer."No.", CurrencyCode, Amount[1]);

        // [GIVEN] Invoice "INV001" of 200 USD posted on 02.01
        Amount[2] := LibraryRandom.RandDecInRange(10000, 20000, 2);
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine[2], GenJournalBatch, WorkDate() + 1,
          GenJournalLine[2]."Document Type"::Invoice, Customer."No.", CurrencyCode, Amount[2]);

        // [GIVEN] Payment of 300 USD posted on 05.01
        Amount[3] := -Amount[1] - Amount[2];
        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine[3], GenJournalBatch, WorkDate() + 4,
          GenJournalLine[3]."Document Type"::Payment, Customer."No.", CurrencyCode, Amount[3]);

        // [GIVEN] Payment applied to Invoices
        ApplyAndPostCustomerEntry(
          GenJournalLine[1]."Document No.", GenJournalLine[3]."Document No.", Amount[1],
          GenJournalLine[1]."Document Type", GenJournalLine[3]."Document Type");
        ApplyAndPostCustomerEntry(
          GenJournalLine[2]."Document No.", GenJournalLine[3]."Document No.", Amount[2],
          GenJournalLine[2]."Document Type", GenJournalLine[3]."Document Type");

        // [GIVEN] Created Exchange Rate "ER2" for 03.01
        CreateExchangeRate(CurrencyCode, LibraryRandom.RandDec(10, 2), 1, WorkDate() + 2);

        // [GIVEN] Payment has been adjusted by "ER2"
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate() + 3, WorkDate() + 3);

        // [WHEN] Unapply Invoices from Payment
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine[1]."Document Type", GenJournalLine[1]."Document No.");
        CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine[2]."Document Type", GenJournalLine[2]."Document No.");
        CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");
        UnbindSubscription(ERMApplyUnapplyCustomer);

        // [THEN] Invoices and Payment are balanced to its adjusted exchange rate
        VerifyCustLedgerEntryRemAmtLCYisBalanced(GenJournalLine[1]."Document No.", GenJournalLine[1]."Document Type");
        VerifyCustLedgerEntryRemAmtLCYisBalanced(GenJournalLine[2]."Document No.", GenJournalLine[2]."Document Type");
        VerifyCustLedgerEntryRemAmtLCYisBalanced(GenJournalLine[3]."Document No.", GenJournalLine[3]."Document Type");
    end;

    [Test]
    procedure GetAppliedCustLedgerEntriesForInvoiceWithPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CustomerNo: Code[20];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391947] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries on Sales Invoice with applied Payment.
        Initialize();

        // [GIVEN] Posted Sales Invoice.
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostedDocNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, LibraryInventory.CreateItemNo(), SalesLine."Document Type"::Invoice,
            LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Payment that is applied to Posted Sales Invoice.
        LibrarySales.CreatePaymentAndApplytoInvoice(GenJournalLine, CustomerNo, PostedDocNo, -SalesLine.Amount);

        // [WHEN] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries codeunit on Customer Ledger Entry linked to Sales Invoice.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostedDocNo);
        CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempCustLedgerEntry, CustLedgerEntry."Entry No.");

        // [THEN] Function returned temporary Customer Ledger Entry table with Payment.
        VerifyTempCustLedgerEntry(TempCustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        TempCustLedgerEntry.Reset();
        Assert.RecordCount(TempCustLedgerEntry, 1);
    end;

    [Test]
    procedure GetAppliedCustLedgerEntriesForPaymentWithInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CustomerNo: Code[20];
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391947] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries on Payment with applied Sales Invoice.
        Initialize();

        // [GIVEN] Posted Sales Invoice.
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostedDocNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, LibraryInventory.CreateItemNo(), SalesLine."Document Type"::Invoice,
            LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Payment that is applied to Posted Sales Invoice.
        LibrarySales.CreatePaymentAndApplytoInvoice(GenJournalLine, CustomerNo, PostedDocNo, -SalesLine.Amount);

        // [WHEN] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries codeunit on Customer Ledger Entry linked to Payment.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempCustLedgerEntry, CustLedgerEntry."Entry No.");

        // [THEN] Function returned temporary Customer Ledger Entry table with Posted Sales Invoice.
        VerifyTempCustLedgerEntry(TempCustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Invoice, PostedDocNo);
        TempCustLedgerEntry.Reset();
        Assert.RecordCount(TempCustLedgerEntry, 1);
    end;

    [Test]
    procedure GetAppliedCustLedgerEntriesForInvoiceWithCrMemo()
    var
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391947] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries on Sales Invoice with applied Sales Credit Memo.
        Initialize();

        // [GIVEN] Posted Sales Invoice.
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostedInvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, LibraryInventory.CreateItemNo(), SalesLine."Document Type"::Invoice,
            LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Posted Sales Credit Memo that is applied to Posted Sales Invoice.
        PostedCrMemoNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, SalesLine."No.", SalesLine."Document Type"::"Credit Memo",
            LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        ApplyAndPostCustomerEntry(PostedInvoiceNo, PostedCrMemoNo, SalesLine.Amount, SalesLine."Document Type"::Invoice, SalesLine."Document Type"::"Credit Memo");

        // [WHEN] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries codeunit on Customer Ledger Entry linked to Sales Invoice.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostedInvoiceNo);
        CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempCustLedgerEntry, CustLedgerEntry."Entry No.");

        // [THEN] Function returned temporary Customer Ledger Entry table with Sales Credit Memo.
        VerifyTempCustLedgerEntry(TempCustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::"Credit Memo", PostedCrMemoNo);
        TempCustLedgerEntry.Reset();
        Assert.RecordCount(TempCustLedgerEntry, 1);
    end;

    [Test]
    procedure GetAppliedCustLedgerEntriesForCrMemoWithInvoice()
    var
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391947] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries on Sales Credit Memo with applied Sales Invoice.
        Initialize();

        // [GIVEN] Posted Sales Invoice.
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostedInvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, LibraryInventory.CreateItemNo(), SalesLine."Document Type"::Invoice,
            LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Posted Sales Credit Memo that is applied to Posted Sales Invoice.
        PostedCrMemoNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, SalesLine."No.", SalesLine."Document Type"::"Credit Memo",
            LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        ApplyAndPostCustomerEntry(PostedInvoiceNo, PostedCrMemoNo, SalesLine.Amount, SalesLine."Document Type"::Invoice, SalesLine."Document Type"::"Credit Memo");

        // [WHEN] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries codeunit on Customer Ledger Entry linked to Sales Credit Memo.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", PostedCrMemoNo);
        CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempCustLedgerEntry, CustLedgerEntry."Entry No.");

        // [THEN] Function returned temporary Customer Ledger Entry table with Sales Invoice.
        VerifyTempCustLedgerEntry(TempCustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Invoice, PostedInvoiceNo);
        TempCustLedgerEntry.Reset();
        Assert.RecordCount(TempCustLedgerEntry, 1);
    end;

    [Test]
    procedure GetAppliedCustLedgerEntriesForInvoiceWithMultipleCrMemos()
    var
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo1: Code[20];
        PostedCrMemoNo2: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391947] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries on Sales Invoice with multiple applied Sales Credit Memos.
        Initialize();

        // [GIVEN] Posted Sales Invoice.
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostedInvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, LibraryInventory.CreateItemNo(), SalesLine."Document Type"::Invoice,
            LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Two Posted Sales Credit Memos that are applied to Posted Sales Invoice.
        PostedCrMemoNo1 :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, SalesLine."No.", SalesLine."Document Type"::"Credit Memo",
            LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        ApplyAndPostCustomerEntry(PostedInvoiceNo, PostedCrMemoNo1, SalesLine.Amount, SalesLine."Document Type"::Invoice, SalesLine."Document Type"::"Credit Memo");

        PostedCrMemoNo2 :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, SalesLine."No.", SalesLine."Document Type"::"Credit Memo",
            LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        ApplyAndPostCustomerEntry(PostedInvoiceNo, PostedCrMemoNo2, SalesLine.Amount, SalesLine."Document Type"::Invoice, SalesLine."Document Type"::"Credit Memo");

        // [WHEN] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries codeunit on Customer Ledger Entry linked to Sales Invoice.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostedInvoiceNo);
        CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempCustLedgerEntry, CustLedgerEntry."Entry No.");

        // [THEN] Function returned temporary Customer Ledger Entry table with Sales Credit Memo.
        VerifyTempCustLedgerEntry(TempCustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::"Credit Memo", PostedCrMemoNo1);
        VerifyTempCustLedgerEntry(TempCustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::"Credit Memo", PostedCrMemoNo2);
        TempCustLedgerEntry.Reset();
        Assert.RecordCount(TempCustLedgerEntry, 2);
    end;

    [Test]
    procedure GetAppliedCustLedgerEntriesForCrMemoWhenInvoiceWithMultCrMemos()
    var
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo1: Code[20];
        PostedCrMemoNo2: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391947] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries on Sales Credit Memo when multiple Credit Memos applied to Sales Invoice.
        Initialize();

        // [GIVEN] Posted Sales Invoice.
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostedInvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, LibraryInventory.CreateItemNo(), SalesLine."Document Type"::Invoice,
            LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Two Posted Sales Credit Memos that are applied to Posted Sales Invoice.
        PostedCrMemoNo1 :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, SalesLine."No.", SalesLine."Document Type"::"Credit Memo",
            LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        ApplyAndPostCustomerEntry(PostedInvoiceNo, PostedCrMemoNo1, SalesLine.Amount, SalesLine."Document Type"::Invoice, SalesLine."Document Type"::"Credit Memo");

        PostedCrMemoNo2 :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, SalesLine."No.", SalesLine."Document Type"::"Credit Memo",
            LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        ApplyAndPostCustomerEntry(PostedInvoiceNo, PostedCrMemoNo2, SalesLine.Amount, SalesLine."Document Type"::Invoice, SalesLine."Document Type"::"Credit Memo");

        // [WHEN] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries codeunit on Customer Ledger Entry linked to Sales Credit Memo.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", PostedCrMemoNo1);
        CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempCustLedgerEntry, CustLedgerEntry."Entry No.");

        // [THEN] Function returned temporary Customer Ledger Entry table with Sales Credit Memo.
        VerifyTempCustLedgerEntry(TempCustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Invoice, PostedInvoiceNo);
        TempCustLedgerEntry.Reset();
        Assert.RecordCount(TempCustLedgerEntry, 1);
    end;

    [Test]
    procedure GetAppliedCustLedgerEntriesForInvoiceWithCrMemoAppliedTwice()
    var
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CustomerNo: Code[20];
        PostedInvoiceNo: Code[20];
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391947] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries on Sales Invoice when Sales Credit Memo applied to Sales Invoice twice.
        Initialize();

        // [GIVEN] Posted Sales Invoice.
        CustomerNo := LibrarySales.CreateCustomerNo();
        PostedInvoiceNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, LibraryInventory.CreateItemNo(), SalesLine."Document Type"::Invoice,
            LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Posted Sales Credit Memo that is applied to Posted Sales Invoice two times.
        PostedCrMemoNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), CustomerNo, SalesLine."No.", SalesLine."Document Type"::"Credit Memo",
            LibraryRandom.RandDecInRange(1, 2, 2), LibraryRandom.RandDecInRange(10, 20, 2));
        ApplyPartiallyAndPostCustomerEntry(PostedInvoiceNo, PostedCrMemoNo, SalesLine.Amount / 4, SalesLine."Document Type"::Invoice, SalesLine."Document Type"::"Credit Memo");
        ApplyPartiallyAndPostCustomerEntry(PostedInvoiceNo, PostedCrMemoNo, SalesLine.Amount / 4, SalesLine."Document Type"::Invoice, SalesLine."Document Type"::"Credit Memo");

        // [WHEN] Run GetAppliedCustLedgerEntries function of CustEntryApplyPostedEntries codeunit on Customer Ledger Entry linked to Sales Invoice.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostedInvoiceNo);
        CustEntryApplyPostedEntries.GetAppliedCustLedgerEntries(TempCustLedgerEntry, CustLedgerEntry."Entry No.");

        // [THEN] Function returned temporary Customer Ledger Entry table with Sales Credit Memo.
        VerifyTempCustLedgerEntry(TempCustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::"Credit Memo", PostedCrMemoNo);
        TempCustLedgerEntry.Reset();
        Assert.RecordCount(TempCustLedgerEntry, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentAppliedToMultipleInvoicesWithDifferentExchRates()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryPayment: Record "Cust. Ledger Entry";
        CustLedgerEntryInvoice: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        ERMApplyUnapplyCustomer: Codeunit "ERM Apply Unapply Customer";
    begin
        // [FEATURE] [Adjust Exchange Rate] [FCY] [Unapply] [Apply]
        // [SCENARIO 399430] Stan can Unapply customer's payment that is applied to multiple invoices with different currency rates and multiple currency rate adjustment.
        Initialize();
        BindSubscription(ERMApplyUnapplyCustomer);

        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 8, 2020), 0.12901, 0.12901);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 9, 2020), 0.12903, 0.12903);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 10, 2020), 0.12903, 0.12903);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 11, 2020), 0.12905, 0.12905);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 12, 2020), 0.12903, 0.12903);
        LibraryERM.CreateExchangeRate(Currency.Code, DMY2Date(1, 1, 2021), 0.12903, 0.12903);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);

        SelectGenJournalBatch(GenJournalBatch, false);

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(19, 8, 2020),
          GenJournalLine."Document Type"::Invoice, Customer."No.", Currency.Code, 400);

        LibraryERM.RunExchRateAdjustmentSimple(Currency.Code, DMY2Date(30, 9, 2020), DMY2Date(30, 9, 2020));

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(12, 11, 2020),
          GenJournalLine."Document Type"::Invoice, Customer."No.", Currency.Code, 850);

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(12, 11, 2020),
          GenJournalLine."Document Type"::Invoice, Customer."No.", Currency.Code, 250);

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(17, 11, 2020),
          GenJournalLine."Document Type"::Invoice, Customer."No.", Currency.Code, 244140);

        LibraryERM.RunExchRateAdjustmentSimple(Currency.Code, DMY2Date(30, 11, 2020), DMY2Date(30, 11, 2020));

        CreateAndPostGenJnlLineWithCurrency(
          GenJournalLine, GenJournalBatch, DMY2Date(7, 1, 2021),
          GenJournalLine."Document Type"::Payment, Customer."No.", Currency.Code, -77280);

        CustLedgerEntryPayment.SetRange("Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntryPayment, CustLedgerEntryPayment."Document Type"::Payment, GenJournalLine."Document No.");

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryPayment);

        CustLedgerEntryInvoice.SetRange("Customer No.", Customer."No.");
        CustLedgerEntryInvoice.SetRange("Document Type", CustLedgerEntryInvoice."Document Type"::Invoice);

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryInvoice);

        LibraryERM.PostCustLedgerApplication(CustLedgerEntryPayment);

        LibraryERM.RunExchRateAdjustmentSimple(Currency.Code, DMY2Date(31, 12, 2020), DMY2Date(31, 12, 2020));

        Commit();

        CustLedgerEntryPayment.Find();
        CustLedgerEntryPayment.TestField(Open, false);

        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Payment);
        DetailedCustLedgEntry.SetRange("Document No.", CustLedgerEntryPayment."Document No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.FindLast();

        ApplyUnapplyParameters."Document No." := CustLedgerEntryPayment."Document No.";
        ApplyUnapplyParameters."Posting Date" := CustLedgerEntryPayment."Posting Date";
        CustEntryApplyPostedEntries.PostUnApplyCustomer(DetailedCustLedgEntry, ApplyUnapplyParameters);

        UnbindSubscription(ERMApplyUnapplyCustomer);

        CustLedgerEntryPayment.Find();
        CustLedgerEntryPayment.TestField(Open, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyCLEWithPaymentDiscVATEntryDocumentDate()
    var
        SalesLine: Record "Sales Line";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        PaymentDocumentType: Enum "Gen. Journal Document Type";
        PostedDocumentNo: Code[20];
        UnapplyDate: Date;
    begin
        // [FEATURE] [Adjust For Payment Discount] [Unapply]
        // [SCENARIO 403999] VAT Entry "Document Date" after unapply should be equal to Posting Date
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        PaymentDocumentType := GenJnlLine."Document Type"::"Payment";

        // [GIVEN] Posted invoice with "Adjust For Payment Discount" and Payment Discount with Posting Date = Document Date = WORKDATE;
        PostedDocumentNo :=
            CreatePostSalesInvWithNormalVATAdjForPmtDisc(SalesLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, PostedDocumentNo);
        CustLedgEntry.CalcFields(Amount);

        // [GIVEN] Post and apply payment document within Posting Date = WORKDATE
        CreateGenJnlLineWithPostingGroups(GenJnlLine, SalesLine."Sell-to Customer No.",
          PaymentDocumentType, -CustLedgEntry.Amount, SalesLine);
        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", PostedDocumentNo);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [WHEN] Unapply payment and invoice with Posting Date = WorkDate() + 1;
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, PaymentDocumentType, GenJnlLine."Document No.");
        UnapplyDate := WorkDate() + 1;
        LibraryERMUnapply.UnapplyCustomerLedgerEntryBase(CustLedgEntry, UnapplyDate);

        // [THEN] VAT Entry created with Document Date = Posting Date = WORKDATE
        VATEntry.SetRange("Document Type", PaymentDocumentType);
        VATEntry.SetRange("Document No.", GenJnlLine."Document No.");
        VATEntry.SetRange("Transaction No.", GetTransactionNoFromUnappliedDtldEntry(PaymentDocumentType, GenJnlLine."Document No."));
        VATEntry.SetRange("Posting Date", UnapplyDate);
        VATEntry.SetRange("Document Date", UnapplyDate);
        Assert.RecordIsNotEmpty(VATEntry);

        // Cleanup: Return back the old value of "Adjust For Payment Discount".
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandlerWithDocumentNo,GenJnlTemplateModalPageHandler')]
    [Scope('OnPrem')]
    procedure VATEntriesAreSameUnppliedWhenUnapplicationWithPayment()
    var
        Customer: Record Customer;
        GeneralJournalLine: array[9] of Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentTerms: Record "Payment Terms";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: array[8] of Decimal;
        DocumentNo: array[8] of Code[20];
        PaymentDocumentNo: Code[20];
        PostingDate: array[2] of Date;
        VATEntryCountAtPmtApplication: Integer;
        VATEntryCountAtPmtUnApplication: Integer;
        TaxCalculationType: Enum "Tax Calculation Type";
    begin
        // [SCENARIO 554723] VAT Entry Lines gets completely unapplied as same they were during applied. 
        Initialize();

        // [GIVEN] Setup payment tolerance on payment discount.
        SetAdjustForPaymentDiscAndPmtTolerancePostings();

        // [GIVEN] Create General Posting Setup.
        CreateGeneralPostingSetupWithPmtDiscount(GeneralPostingSetup);

        // [GIVEN] Create VAT Posting Setup.
        CreateVATPostingSetupWithPmtDiscount(VATPostingSetup, TaxCalculationType::"Normal VAT");

        // [GIVEN] Create Payment Terms Discount.
        CreatePaymentTermsDiscount(PaymentTerms, LibraryRandom.RandIntInRange(2, 2));

        // [GIVEN] Create Customer with Posting Setup.
        Customer.Get(
            CreateCustomerWithPostingSetup(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Generate Amount.
        GenerateAmounts(Amount);

        // [GIVEN] Generate Posting Date.
        GeneratePostingDate(PostingDate);

        // [GIVEN] Select General Journal Batch and delete General Journal Lines before creating new General Journal Lines.
        SelectGenJournalBatch(GenJournalBatch, false);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");

        // [GIVEN] Create Sales Journal with Eight Invoices.
        CreateSalesJournal(
            GeneralJournalLine, GenJournalBatch, Customer."No.", GeneralPostingSetup."Sales Account",
            GeneralPostingSetup, VATPostingSetup, PostingDate, Amount, DocumentNo, PaymentTerms.Code);

        // [GIVEN] Create Payment Line.
        CreatePayment(GeneralJournalLine[9], GenJournalBatch, Customer."No.", PostingDate[2], PaymentDocumentNo);

        // [GIVEN] Choice is Set to applies id.
        IsSetAppliesToID(true, DocumentNo);

        // [GIVEN] Open Apply Entries Page for Application.
        OpenGeneralJournalPage(GeneralJournalLine[9]."Document No.", GeneralJournalLine[9]."Document Type");

        // [GIVEN] Post General Journal Line for Payment.
        LibraryERM.PostGeneralJnlLine(GeneralJournalLine[9]);

        // [GIVEN] Get VAT Entries Count Post Payment Application.       
        VATEntryCountAtPmtApplication := GetVATEntry(GeneralJournalLine[9]."Document Type"::Payment, PaymentDocumentNo, PostingDate[2], false);

        // [WHEN] Unapply Payment.
        UnapplyCustLedgerEntry(GeneralJournalLine[9]."Document Type"::Payment, PaymentDocumentNo);

        // [THEN] Get VAT Entries Count after Unapplication of Payment.
        VATEntryCountAtPmtUnApplication := GetVATEntry(
            GeneralJournalLine[9]."Document Type"::Payment,
            PaymentDocumentNo, PostingDate[2], true);

        // [THEN] Verify VAT Entries counts are same after Unapplication.
        Assert.AreEqual(VATEntryCountAtPmtApplication, VATEntryCountAtPmtUnApplication, VATEntryCntLbl);
    end;

    [Test]
    procedure CheckAdditionalCurrencyInGLEntryPostingCashReceiptWithAlternatePostingGroupWithCurrencyCode()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerPostingGroup: array[2] of Record "Customer Posting Group";
        GenJournalLine, GenJournalLine2 : Record "Gen. Journal Line";
        GlEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        PaymentDocNo: Code[20];
        VATCalculationType: Enum "Tax Calculation Type";
    begin
        // [SCENARIO 575520] Check Additional Reporting Currency not working when posting through alternate posting group.
        Initialize();

        // [GIVEN] Currency with specific exchange rates and set as Additional Reporting Currency.
        GlEntry.SetCurrentKey("Posting Date");
        GlEntry.FindFirst();
        CurrencyCode := CreateCurrencyAndExchangeRate(1, 1.1302, WorkDate());
        CreateExchangeRate(CurrencyCode, 100, 101.7599, GlEntry."Posting Date");
        UpdateRunAddnReportingCurrency(CurrencyCode, LibraryRandom.RandText(10));

        // [GIVEN] Set Allow Multiple Posting Groups in Sales & Receivables Setup.
        SetSalesAllowMultiplePostingGroups(true);

        // [GIVEN] Create Customer Posting Group One And Alternative Customer Posting Group.
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[1]);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[2]);
        LibrarySales.CreateAltCustomerPostingGroup(CustomerPostingGroup[1].Code, CustomerPostingGroup[2].Code);

        // [GIVEN] Create VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType::"Normal VAT", 25);

        // [GIVEN Create Customer With Allow Multiple Posting Groups.
        CreateCustomerWithAllowMultiplePostingGroups(Customer, CustomerPostingGroup[1].Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create Cash Receipt Journal Invoice Line for the customer And Post.
        CreateCashReceiptJnlLine(GenJournalLine, Customer."No.");
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Find Openned Customer Ledger Entries for New Customer Created For "Apply Entries".
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, Customer."No.");

        // [WHEN] Payment is applied to the invoice.
        CreateCashReceiptJnlLinePayment(GenJournalLine2, Customer."No.", CustLedgerEntry, CustomerPostingGroup[2].Code, CurrencyCode);
        PaymentDocNo := GenJournalLine2."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // [THEN] Check General Ledger Entry All Lines Must have Value in "Additional-Currency Amount" Field.
        GlEntry.Reset();
        GlEntry.SetRange("Document No.", PaymentDocNo);
        GlEntry.SetRange("Additional-Currency Amount", 0);
        Assert.RecordCount(GlEntry, 2); // new line for source currency only
    end;

    [Test]
    procedure CheckAdditionalCurrencyInGLEntryPostingCashReceiptWithAlternatePostingGroupWithOutCurrencyCode()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerPostingGroup: array[2] of Record "Customer Posting Group";
        GenJournalLine, GenJournalLine2 : Record "Gen. Journal Line";
        GlEntry: Record "G/L Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        PaymentDocNo: Code[20];
        VATCalculationType: Enum "Tax Calculation Type";
    begin
        // [SCENARIO 575520] Check Additional Reporting Currency not working when posting through alternate posting group.
        Initialize();

        // [GIVEN] Currency with specific exchange rates and set as Additional Reporting Currency.
        GlEntry.SetCurrentKey("Posting Date");
        GlEntry.FindFirst();
        CurrencyCode := CreateCurrencyAndExchangeRate(1, 1.1302, WorkDate());
        CreateExchangeRate(CurrencyCode, 100, 101.7599, GlEntry."Posting Date");
        UpdateRunAddnReportingCurrency(CurrencyCode, LibraryRandom.RandText(10));

        // [GIVEN] Set Allow Multiple Posting Groups in Sales & Receivables Setup.
        SetSalesAllowMultiplePostingGroups(true);

        // [GIVEN] Create Customer Posting Group One And Alternative Customer Posting Group.
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[1]);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[2]);
        LibrarySales.CreateAltCustomerPostingGroup(CustomerPostingGroup[1].Code, CustomerPostingGroup[2].Code);

        // [GIVEN] Create VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType::"Normal VAT", 25);

        // [GIVEN Create Customer With Allow Multiple Posting Groups.
        CreateCustomerWithAllowMultiplePostingGroups(Customer, CustomerPostingGroup[1].Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create Cash Receipt Journal Invoice Line for the customer And Post.
        CreateCashReceiptJnlLine(GenJournalLine, Customer."No.");
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Find Openned Customer Ledger Entries for New Customer Created For "Apply Entries".
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, Customer."No.");

        // [WHEN] Payment is applied to the invoice.
        CreateCashReceiptJnlLinePayment(GenJournalLine2, Customer."No.", CustLedgerEntry, CustomerPostingGroup[2].Code, '');
        PaymentDocNo := GenJournalLine2."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // [THEN] Check General Ledger Entry All Lines Must have Value in "Additional-Currency Amount" Field.
        GlEntry.Reset();
        GlEntry.SetRange("Document No.", PaymentDocNo);
        GlEntry.SetRange("Additional-Currency Amount", 0);
        Assert.RecordCount(GlEntry, 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Apply Unapply Customer");
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Apply Unapply Customer");

        LibrarySales.SetInvoiceRounding(false);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Source Code Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Apply Unapply Customer");
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyPartiallyAndPostCustomerEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.FindFirst();
        CustLedgerEntry2.Validate("Amount to Apply", -AmountToApply);
        CustLedgerEntry2.Modify(true);

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateAndModifyCustomer(var Customer: Record Customer; ApplicationMethod: Enum "Application Method"; PaymentMethodCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Validate("Application Method", ApplicationMethod);
        Customer.Validate("Currency Code", CreateCurrency());
        Customer.Modify(true);
    end;

    local procedure CreateAndApplyGenLines(var DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup: Create 1 Invoice General Line and Post it.
        SelectGenJournalBatch(GenJournalBatch, false);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, 1, CreateCustomer(), DocumentType, Amount);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Find Discount Amount and Post 1 Payment General Line.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, GenJournalLine."Document No.");
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, 1, GenJournalLine."Account No.", DocumentType2,
          -GenJournalLine.Amount + CustLedgerEntry."Original Pmt. Disc. Possible");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply Posted Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", DocumentNo, GenJournalLine.Amount, DocumentType2, DocumentType);
        DocumentNo := GenJournalLine."Document No.";
        exit(CustLedgerEntry."Original Pmt. Disc. Possible");
    end;

    local procedure CreateAndPostGenJournalLineWithPmtDiscExclVAT(PmtDiscExclVAT: Boolean; GLAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
    begin
        // Setup:Update Pmt. Disc. Excl. VAT in General Ledger & Create Customer with Payment Terms & Create Gen. Journal Line.
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(false);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(PmtDiscExclVAT);
        CreateCustomerWithPaymentTerm(Customer);

        // Exercise:Create - Post Gen. Journal Line.
        CreatePostBalancedGenJnlLines(GenJournalLine, Customer."No.", GLAccountNo);

        // Verify: Verify Customer Ledger Entry.
        VerifyDiscountValueInCustomerLedger(
          GenJournalLine, GetPaymentDiscountAmount(GenJournalLine, GetPaymentTermsDiscount(Customer."Payment Terms Code"), PmtDiscExclVAT));
    end;

    local procedure CreatePostSalesAndGenLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; UnitPrice: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Document and done 1 Payment with Posted Document.
        SelectGenJournalBatch(GenJournalBatch, false);
        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(), LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo(), DocumentType,
            LibraryRandom.RandInt(100), Abs(UnitPrice));
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, 1, SalesLine."Sell-to Customer No.", DocumentType2, -UnitPrice);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exericse.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", DocumentNo, GenJournalLine.Amount, DocumentType2, DocumentType);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; PostingDate: Date; CustomerNo: Code[20]; ItemNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Quantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostGenJnlLineWithBalAccount(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch, false);
        CreateGenJnlLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        GenJournalLine.Validate("Sales/Purch. (LCY)", 0);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostBalancedGenJnlLines(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; GLAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGenJnlLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandInt(100));
        DocumentNo := GenJournalLine."Document No.";
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccountNo, -GenJournalLine.Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostSalesInvWithReverseChargeVATAdjForPmtDisc(var SalesLine: Record "Sales Line"): Code[20]
    var
        TaxCalculationType: Enum "Tax Calculation Type";
    begin
        exit(
          CreatePostSalesInvVATAdjForPmtDiscSetValues(
            SalesLine, '', LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2), LibraryRandom.RandIntInRange(10, 20), 0,
            TaxCalculationType::"Reverse Charge VAT"));
    end;

    local procedure CreatePostSalesInvWithNormalVATAdjForPmtDisc(var SalesLine: Record "Sales Line"): Code[20]
    var
        TaxCalculationType: Enum "Tax Calculation Type";
    begin
        exit(
          CreatePostSalesInvVATAdjForPmtDiscSetValues(
            SalesLine, '', LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2), LibraryRandom.RandIntInRange(10, 20), 2,
            TaxCalculationType::"Normal VAT"));
    end;

    local procedure CreatePostSalesInvVATAdjForPmtDiscSetValues(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; Quantity: Integer; UnitPrice: Decimal; VATPct: Decimal; DiscountPct: Decimal; TaxCalculationType: Enum "Tax Calculation Type"): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        ItemNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        UpdateGenPostSetupWithSalesPmtDiscAccount(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, TaxCalculationType, VATPct);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
        Customer.Get(
          CreateCustomerWithPostingSetup(GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Payment Terms Code", CreatePaymentTermsWithDiscount(DiscountPct));
        Customer.Modify(true);
        ItemNo :=
          CreateItemWithPostingSetup(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
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

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyAndExchangeRate(Rate: Decimal; RelationalRate: Decimal; FromDate: Date): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        CreateExchangeRate(Currency.Code, Rate, RelationalRate, FromDate);
        exit(Currency.Code);
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

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", CreatePaymentTerms());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithPostingSetup(GenBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
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

    local procedure CreateCustomerWithPaymentTerm(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", CreatePaymentTermCode());
        Customer.Modify(true);
    end;

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; NoofLines: Integer; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        Counter: Integer;
    begin
        for Counter := 1 to NoofLines do
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
              GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);
    end;

    local procedure CreateAndPostGenJnlLineWithCurrency(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoiceAndPayment(CustomerNo: Code[20]; var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine, WorkDate(),
            CustomerNo, LibraryInventory.CreateItemNo(), SalesHeader."Document Type"::Invoice,
            LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        SelectGenJournalBatch(GenJournalBatch, false);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, 1, CustomerNo, GenJournalLine."Document Type"::Payment,
          -1 * LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(false); // Do not invoke set applies to ID action

        exit(DocumentNo);
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Take Random Values for Payment Terms.
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; NoOfLines: Integer; Amount: Decimal)
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create Customer, General Journal Line for 1 Invoice, Credit Memo and more than 1 for Payment, Refund
        // and Random Amount for General Journal Line.
        SelectGenJournalBatch(GenJournalBatch, false);
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch, 1, Customer."No.", DocumentType, Amount);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, NoOfLines, GenJournalLine."Account No.", DocumentType2, -GenJournalLine.Amount / NoOfLines);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndModifySalesLine(SalesHeader: Record "Sales Header"; LineQuantity: Decimal; LinePrice: Decimal): Decimal
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        // Create Sales line using Random Quantity and Amount.
        Customer.Get(SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader,
          SalesLine.Type::"G/L Account", CreateNoVATPostingGLAccount(Customer."VAT Bus. Posting Group"),
          LineQuantity);
        SalesLine.Validate("Unit Price", LinePrice);
        SalesLine.Modify(true);
        exit(SalesLine."Line Amount");
    end;

    local procedure CreateLinesApplyAndUnapply(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
    begin
        // Setup: Apply and Unapply Posted General Lines for Customer Ledger Entry.
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount);
        ApplyAndPostCustomerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document No.", -GenJournalLine.Amount, DocumentType, DocumentType2);
        UnapplyCustLedgerEntry(DocumentType, GenJournalLine."Document No.");
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndUpdateSourceCodeSetup(UnappliedSalesEntryAppln: Code[10])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.Validate("Unapplied Sales Entry Appln.", UnappliedSalesEntryAppln);
        SourceCodeSetup.Modify(true);
    end;

    local procedure CreateNewExchangeRate(PostingDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Use Random Number Generator for Exchange Rate.
        CurrencyExchangeRate.SetRange("Currency Code", LibraryERM.GetAddReportingCurrency());
        CurrencyExchangeRate.FindFirst();
        LibraryERM.CreateExchRate(CurrencyExchangeRate, LibraryERM.GetAddReportingCurrency(), PostingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandInt(100));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateNoVATPostingGLAccount(VATBusPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATPostingSetup."VAT Prod. Posting Group" := FindNoVATPostingSetup(VATBusPostingGroup);
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
    end;

    local procedure CreateCustomerAndItem(var CustomerNo: Code[20]; var ItemNo: Code[20]; ForeignCurrencyCode: Code[10])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        ItemNo :=
          CreateItemWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        CustomerNo :=
          CreateCustomerWithPostingSetup(
            GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Get(CustomerNo);
        Customer.Validate("Currency Code", ForeignCurrencyCode);
        Customer.Modify(true);
    end;

    local procedure SetupSpecificExchRates(var ForeignCurrencyCode: Code[10]; var AdditionalCurrencyCode: Code[10]; var DocumentDate: Date)
    begin
        DocumentDate := CalcDate('<-' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', WorkDate());
        ForeignCurrencyCode := CreateCurrencyAndExchangeRate(100, 46.0862, DocumentDate);
        AdditionalCurrencyCode := CreateCurrencyAndExchangeRate(100, 55.7551, DocumentDate);
        CreateExchangeRate(AdditionalCurrencyCode, 100, 50, WorkDate());
    end;

    local procedure CreatePaymentTermCode(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Discount %", LibraryRandom.RandDec(5, 2));
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure FindDetailedCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type"): Boolean
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        exit(DetailedCustLedgEntry.FindSet());
    end;

    local procedure FindNoVATPostingSetup(VATBusPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindFirst();
        if VATPostingSetup."Sales VAT Account" = '' then
            VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        if VATPostingSetup."Purchase VAT Account" = '' then
            VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindPaymentMethodWithBalanceAccount(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetFilter("Bal. Account No.", '<>''''');
        PaymentMethod.FindFirst();
        exit(PaymentMethod.Code);
    end;

    local procedure FindClosedInvLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange(Open, false);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure GetPaymentDiscountAmount(GenJournalLine: Record "Gen. Journal Line"; DiscountPercentage: Decimal; PmtDiscExclVAT: Boolean): Decimal
    begin
        if PmtDiscExclVAT then
            exit(Round(-GenJournalLine."VAT Base Amount" * DiscountPercentage / 100));
        exit(Round(-GenJournalLine.Amount * DiscountPercentage / 100))
    end;

    local procedure GetPaymentTermsDiscount(PaymentTermsCode: Code[10]): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        exit(PaymentTerms."Discount %");
    end;

    local procedure ModifyCurrency("Code": Code[10]; ApplnRoundingPrecision: Decimal)
    var
        Currency: Record Currency;
    begin
        Currency.Get(Code);
        Currency.Validate("Appln. Rounding Precision", ApplnRoundingPrecision);
        Currency.Modify(true);
    end;

    local procedure OpenGeneralJournalPage(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type") Amount: Decimal
    var
        GeneralJournal: TestPage "General Journal";
    begin
        GeneralJournal.OpenEdit();
        GeneralJournal.FILTER.SetFilter("Document No.", DocumentNo);
        GeneralJournal.FILTER.SetFilter("Document Type", Format(DocumentType));
        LibraryVariableStorage.Enqueue(true); // Invoke set applies to ID action
        GeneralJournal."Apply Entries".Invoke();
        Amount := LibraryRandom.RandDec(10, 2);  // Used Random value to make difference in General Journal line Amount.
        GeneralJournal.OK().Invoke();
    end;

    local procedure PostApplyPaymentForeignCurrency(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; CurrencyCode: Code[10]; PaymentAmount: Decimal; AppliedDocumentType: Enum "Gen. Journal Document Type"; AppliedDocumentNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch, false);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, 1, CustomerNo, GenJournalLine."Document Type"::Payment, 0);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Amount, PaymentAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliedDocumentType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedDocumentNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccountWithCurrency(CurrencyCode));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure RunCustomerLedgerEntries(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgerEntry);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; SetNoSeries: Boolean)
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exits before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        if SetNoSeries then begin
            GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
            GenJournalBatch.Modify(true);
        end;
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SetFilterForCustomerWithSortDescending(var Customer: Record Customer): Text
    var
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        SelectionString: Text;
    begin
        SelectionString :=
          SelectionFilterManagement.AddQuotes(LibrarySales.CreateCustomerNo()) + '..' +
          SelectionFilterManagement.AddQuotes(LibrarySales.CreateCustomerNo());
        Customer.SetFilter("No.", SelectionString);
        exit(SelectionString);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; AppliestoDocNo: Code[20]; Amount: Decimal)
    begin
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Validate(Amount, Amount + LibraryRandom.RandDec(5, 2));  // Modify Amount using Random value.
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGenPostSetupWithSalesPmtDiscAccount(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        LibraryERM.SetGeneralPostingSetupSalesPmtDiscAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
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

    local procedure VerifyAmountToApplyOnCustomerLedgerEntries(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.TestField("Amount to Apply", 0);
    end;

    local procedure VerifyEntriesAfterPostingSalesDocument(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.TestField(Open, false);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo2);
        CustLedgerEntry.TestField(Open, false);
        VerifyGLEntries(DocumentNo2);
        VerifyDetailedLedgerEntry(DocumentNo2, DocumentType);
    end;

    local procedure VerifyErrorAfterModifyPaymentMethod(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        asserterror CustLedgerEntry.Validate("Payment Method Code", '');
        Assert.ExpectedTestFieldError(CustLedgerEntry.FieldCaption(Open), Format(true));
    end;

    local procedure VerifyInvDetailedLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; EntryType: Enum "Detailed CV Ledger Entry Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        FindDetailedCustLedgerEntry(DetailedCustLedgEntry, DocumentNo, DocumentType, EntryType);
        Assert.AreEqual(
          Amount, DetailedCustLedgEntry.Amount,
          StrSubstNo(AmountErr, DetailedCustLedgEntry.FieldCaption(Amount), Amount, DetailedCustLedgEntry.TableCaption()));
    end;

    local procedure VerifyDetailedLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TotalAmount: Decimal;
    begin
        FindDetailedCustLedgerEntry(DetailedCustLedgEntry, DocumentNo, DocumentType, DetailedCustLedgEntry."Entry Type"::Application);
        repeat
            TotalAmount += DetailedCustLedgEntry.Amount;
        until DetailedCustLedgEntry.Next() = 0;
        Assert.AreEqual(
          0, TotalAmount,
          StrSubstNo(
            TotalAmountErr, 0, DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry Type"),
            DetailedCustLedgEntry."Entry Type"));
    end;

    local procedure VerifyDiscountValueInCustomerLedger(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document No.");
        CustLedgerEntry.TestField("Original Pmt. Disc. Possible", Round(Amount));
        CustLedgerEntry.TestField("Remaining Pmt. Disc. Possible", CustLedgerEntry."Original Pmt. Disc. Possible");
    end;

    local procedure VerifyUnappliedDtldLedgEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        FindDetailedCustLedgerEntry(DetailedCustLedgEntry, DocumentNo, DocumentType, DetailedCustLedgEntry."Entry Type"::Application);
        repeat
            Assert.IsTrue(
              DetailedCustLedgEntry.Unapplied, StrSubstNo(UnappliedErr, DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.Unapplied));
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure VerifyCustLedgerEntryForRemAmt(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        repeat
            CustLedgerEntry.CalcFields("Remaining Amount", Amount);
            CustLedgerEntry.TestField("Remaining Amount", CustLedgerEntry.Amount);
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyCustLedgerEntryRemAmtLCYisBalanced(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        CustLedgerEntry.TestField("Remaining Amt. (LCY)", Round(CustLedgerEntry."Remaining Amount" / CustLedgerEntry."Adjusted Currency Factor", 0.01));
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        TotalAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreEqual(
          0, TotalAmount, StrSubstNo(TotalAmountErr, 0, GLEntry.TableCaption(), GLEntry.FieldCaption("Document No."), GLEntry."Document No."));
    end;

    local procedure VerifyAddCurrencyAmount(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        AddCurrAmt: Decimal;
    begin
        Currency.Get(LibraryERM.GetAddReportingCurrency());
        Currency.InitRoundingPrecision();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            AddCurrAmt := LibraryERM.ConvertCurrency(GLEntry.Amount, '', Currency.Code, WorkDate());
            Assert.AreNearlyEqual(
              AddCurrAmt, GLEntry."Additional-Currency Amount", Currency."Amount Rounding Precision",
              StrSubstNo(AdditionalCurrencyErr, AddCurrAmt));
        until GLEntry.Next() = 0;
    end;

    local procedure VerifySourceCodeDtldCustLedger(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; SourceCode: Code[10])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.SetRange("Source Code", SourceCode);
        Assert.IsTrue(DetailedCustLedgEntry.FindFirst(), 'Detailed Customer Ledger Entry must found.');
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

    local procedure VerifyTempCustLedgerEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        TempCustLedgerEntry.SetRange("Customer No.", CustomerNo);
        TempCustLedgerEntry.SetRange("Document Type", DocumentType);
        TempCustLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(TempCustLedgerEntry);
    end;

    local procedure ApplyUnapplyCustEntriesWithMiscDimSetIDs(NoOfLines: Integer)
    var
        Customer: Record Customer;
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
        CreateCustomerWithGivenPaymentTerm(Customer, CreatePaymentTermsWithDiscount(DiscountPercent));

        for i := 1 to NoOfLines do begin
            Amounts[i] := 100 * LibraryRandom.RandIntInRange(1, 100);
            DiscountedAmounts[i] := Amounts[i] * (100 - DiscountPercent) / 100;
        end;

        // Exercise
        DocNo := ApplyUnapplyWithDimSetIDs(NoOfLines, Customer."No.", DimSetIDs, Amounts, DiscountedAmounts);

        // Exercise and Verify
        for i := 1 to NoOfLines do
            Amounts[i] -= DiscountedAmounts[i];
        VerifyGLEntriesWithDimSetIDs(DocNo, Amounts, DimSetIDs, NoOfLines);
    end;

    local procedure CreateGenJnlLinesWithDimSetIDs(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; var DimSetIDs: array[10] of Integer; NoOfDocuments: Integer; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amounts: array[10] of Decimal; SignFactor: Integer)
    var
        i: Integer;
    begin
        for i := 1 to NoOfDocuments do
            CreateGenJnlLineWithDimSetID(GenJournalLine, GenJournalBatch, DimSetIDs[i], CustomerNo, DocumentType, Amounts[i] * SignFactor);
    end;

    local procedure CreatePostGenJnlLinesWithDimSetIDs(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; var DimSetIDs: array[10] of Integer; NoOfDocuments: Integer; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amounts: array[10] of Decimal; SignFactor: Integer)
    var
        i: Integer;
    begin
        for i := 1 to NoOfDocuments do begin
            CreateGenJnlLineWithDimSetID(GenJournalLine, GenJournalBatch, DimSetIDs[i], CustomerNo, DocumentType, Amounts[i] * SignFactor);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;
    end;

    local procedure CreateGenJnlLineWithDimSetID(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; var DimSetID: Integer; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        DimVal: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        LibraryDimension.CreateDimensionValue(DimVal, LibraryERM.GetGlobalDimensionCode(1));
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimVal.Code);
        GenJournalLine.Modify(true);
        DimSetID := GenJournalLine."Dimension Set ID";
    end;

    local procedure CreateGenJnlLinesWithGivenDimSetIDs(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DimSetIDs: array[10] of Integer; NoOfLines: Integer; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amounts: array[10] of Decimal)
    var
        DimMgt: Codeunit DimensionManagement;
        Counter: Integer;
    begin
        for Counter := 1 to NoOfLines do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
              GenJournalLine."Account Type"::Customer, CustomerNo, -Amounts[Counter]);
            GenJournalLine.Validate("Bal. Account No.", '');
            GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
            GenJournalLine.Validate("Dimension Set ID", DimSetIDs[Counter]);
            DimMgt.UpdateGlobalDimFromDimSetID(
              GenJournalLine."Dimension Set ID", GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
            GenJournalLine.Modify(true);
        end;
    end;

    local procedure CreateGenJnlLineWithPostingGroups(var GenJnlLine: Record "Gen. Journal Line"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; SalesLine: Record "Sales Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch, false);
        CreateGeneralJournalLines(GenJnlLine, GenJournalBatch, 1, VendorNo, DocumentType, Amount);
        GenJnlLine.Validate("Bal. Gen. Posting Type", GenJnlLine."Bal. Gen. Posting Type"::Sale);
        GenJnlLine.Validate("Bal. Gen. Bus. Posting Group", SalesLine."Gen. Bus. Posting Group");
        GenJnlLine.Validate("Bal. Gen. Prod. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GenJnlLine.Validate("Bal. VAT Bus. Posting Group", SalesLine."VAT Bus. Posting Group");
        GenJnlLine.Validate("Bal. VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        GenJnlLine.Modify(true);
    end;

    local procedure ApplyCustLedgerEntriesToID(CustomerNo: Code[20]; AppliesToID: Code[50]; AmountsToApply: array[10] of Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        i: Integer;
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        if CustLedgerEntry.FindSet() then
            repeat
                i += 1;
                CustLedgerEntry.Validate("Applying Entry", true);
                CustLedgerEntry.Validate("Applies-to ID", AppliesToID);
                CustLedgerEntry.Validate("Amount to Apply", AmountsToApply[i]);
                CustLedgerEntry.Modify(true);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure CreatePaymentTermsWithDiscount(DiscountPercent: Decimal): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        PaymentTerms.Validate("Discount %", DiscountPercent);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateCustomerWithGivenPaymentTerm(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
    end;

    local procedure VerifyGLEntriesWithDimSetIDs(DocumentNo: Code[20]; Amounts: array[10] of Decimal; DimSetIDs: array[10] of Integer; DimSetArrLen: Integer)
    var
        GLEntry: Record "G/L Entry";
        Index: Integer;
        TotalAmount: Decimal;
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindLast();
        GLEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        Assert.RecordCount(GLEntry, DimSetArrLen + 1);
        GLEntry.FindSet();
        for Index := 1 to DimSetArrLen do begin
            GLEntry.TestField("Dimension Set ID", DimSetIDs[1]);
            GLEntry.TestField(Amount, -Amounts[Index]);
            TotalAmount += Amounts[Index];
            GLEntry.Next();
        end;
        GLEntry.TestField("Dimension Set ID", DimSetIDs[1]);
        GLEntry.TestField(Amount, TotalAmount);
    end;

    local procedure GetTransactionNoFromUnappliedDtldEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetRange("Document Type", DocType);
        DtldCustLedgEntry.SetRange("Document No.", DocNo);
        DtldCustLedgEntry.SetRange(Unapplied, true);
        DtldCustLedgEntry.FindLast();
        exit(DtldCustLedgEntry."Transaction No.");
    end;

    local procedure ApplyUnapplyWithDimSetIDs(NoOfLines: Integer; CustomerNo: Code[20]; var DimSetIDs: array[10] of Integer; Amounts: array[10] of Decimal; DiscountedAmounts: array[10] of Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        TotalDiscountedAmount: Decimal;
        i: Integer;
    begin
        SelectGenJournalBatch(GenJournalBatch, true);
        CreatePostGenJnlLinesWithDimSetIDs(
          GenJournalLine, GenJournalBatch, DimSetIDs, NoOfLines,
          CustomerNo, GenJournalLine."Document Type"::Invoice, Amounts, 1);

        CreateGenJnlLinesWithGivenDimSetIDs(
          GenJournalLine, GenJournalBatch, DimSetIDs, NoOfLines,
          CustomerNo, GenJournalLine."Document Type"::Payment, DiscountedAmounts);
        ApplyCustLedgerEntriesToID(CustomerNo, GenJournalLine."Document No.", DiscountedAmounts);

        for i := 1 to NoOfLines do
            TotalDiscountedAmount += DiscountedAmounts[i];

        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, 1, CustomerNo,
          GenJournalLine."Document Type"::Payment, TotalDiscountedAmount);
        BankAccount.SetRange(Blocked, false);
        BankAccount.FindFirst();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.Validate("Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        exit(GenJournalLine."Document No.");
    end;

    local procedure SetAdjustForPaymentDiscAndPmtTolerancePostings()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Adjust for Payment Disc.", true);
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts");
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateGeneralPostingSetupWithPmtDiscount(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesPmtDiscAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupWithPmtDiscount(var VATPostingSetup: Record "VAT Posting Setup"; TaxCalculationType: Enum "Tax Calculation Type")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, TaxCalculationType::"Normal VAT", LibraryRandom.RandIntInRange(20, 20));
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePaymentTermsDiscount(var PaymentTerms: Record "Payment Terms"; DiscountPct: Decimal)
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
    end;

    local procedure GenerateAmounts(var Amount: array[8] of Decimal)
    var
        i: Integer;
        InitialAmount: Decimal;
    begin
        for i := 1 to ArrayLen(Amount) do begin
            Amount[i] := InitialAmount + LibraryRandom.RandIntInRange(100, 100);
            InitialAmount := Amount[i]
        end;
    end;

    local procedure GeneratePostingDate(var PostingDate: array[2] of Date)
    begin
        PostingDate[1] := WorkDate();
        PostingDate[2] := CalcDate('<+10D>', PostingDate[1]);
    end;

    local procedure CreateSalesJournal(
        GeneralJournalLine: array[8] of Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch";
        CustomerNo: Code[20]; GLAccountNo: Code[20];
        GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup";
        PostingDate: array[2] of Date; Amount: array[8] of Decimal;
        var DocumentNo: array[8] of Code[20]; PaymentTermsCode: Code[20])
    var
        i: Integer;
        DocumentNoCode: Code[20];
    begin
        for i := 1 to 4 do begin
            CreateSalesJournalLines(
                GeneralJournalLine[i], GenJournalBatch, CustomerNo, GLAccountNo, GeneralPostingSetup,
                VATPostingSetup, PostingDate[1], Amount[i], PaymentTermsCode, DocumentNoCode);
            DocumentNo[i] := DocumentNoCode;
        end;

        for i := 5 to 8 do begin
            CreateSalesJournalLines(
                GeneralJournalLine[i], GenJournalBatch, CustomerNo, GLAccountNo,
                GeneralPostingSetup, VATPostingSetup, PostingDate[2], Amount[i], PaymentTermsCode, DocumentNoCode);
            DocumentNo[i] := DocumentNoCode;
        end;

        PostJournalBatch(GenJournalBatch);
    end;

    local procedure CreateSalesJournalLines(
        var GeneralJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch";
        CustomerNo: Code[20]; GLAccountNo: Code[20];
        GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup";
        PostingDate: Date; Amount: Decimal;
        PaymentTermsCode: Code[20]; var DocumentNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GeneralJournalLine, GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name, GeneralJournalLine."Document Type"::Invoice,
            GeneralJournalLine."Account Type"::Customer, CustomerNo,
            GeneralJournalLine."Bal. Account Type"::"G/L Account", GLAccountNo, Amount);
        if DocumentNo <> '' then
            GeneralJournalLine.Validate("Document No.", IncStr(DocumentNo));
        GeneralJournalLine.Validate("Posting Date", PostingDate);
        GeneralJournalLine.Validate("Payment Terms Code", PaymentTermsCode);
        GeneralJournalLine.Validate("Bal. Gen. Posting Type", GeneralJournalLine."Bal. Gen. Posting Type"::Sale);
        GeneralJournalLine.Validate("Bal. Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GeneralJournalLine.Validate("Bal. Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GeneralJournalLine.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GeneralJournalLine.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GeneralJournalLine.Modify(true);
        DocumentNo := GeneralJournalLine."Document No.";
    end;

    local procedure PostJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePayment(
        var GeneralJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustomerNo: Code[20];
        PostingDate: Date;
        var PaymentDocumentNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GeneralJournalLine, GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name, GeneralJournalLine."Document Type"::Payment,
            GeneralJournalLine."Account Type"::Customer, CustomerNo,
            GeneralJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", -LibraryRandom.RandIntInRange(3528, 3528));
        GeneralJournalLine.Validate("Posting Date", PostingDate);
        GeneralJournalLine.Modify(true);
        PaymentDocumentNo := GeneralJournalLine."Document No.";
    end;

    local procedure IsSetAppliesToID(SetAppliesToIDValue: Boolean; DocumentNo: array[8] of Code[20])
    var
        i: Integer;
    begin
        LibraryVariableStorage.Enqueue(SetAppliesToIDValue);
        for i := 1 to 8 do
            LibraryVariableStorage.Enqueue(DocumentNo[i]);
    end;

    local procedure GetVATEntry(
        DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; UnapplyDate: Date; CheckForUnapp: Boolean): Integer;
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        if CheckForUnapp then begin
            VATEntry.SetRange("Transaction No.", GetTransactionNoFromUnappliedDtldEntry(DocumentType, DocumentNo));
            VATEntry.SetRange("Posting Date", UnapplyDate);
        end;
        exit(VATEntry.Count());
    end;

    procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; CustNo: Code[20])
    begin
        // Finds the matching Customer Ledger Entry from a General Journal Line.
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(CustLedgerEntry."Remaining Amount");
    end;

    local procedure CreateCashReceiptJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, AccountNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 100);
    end;

    local procedure CreateCashReceiptJnlLinePayment(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerPostingGroup: Code[20]; CurrencyCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 100);

        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Group", CustomerPostingGroup);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        GenJournalLine.Validate(Amount, -(CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible"));
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateRunAddnReportingCurrency(CurrencyCode: Code[10]; DocumentNo: Code[20])
    begin
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        RunAdditionalReportingCurrency(CurrencyCode, DocumentNo);
    end;

    local procedure RunAdditionalReportingCurrency(CurrencyCode: Code[10]; DocumentNo: Code[20])
    var
        AdjustAddReportingCurrency: Report "Adjust Add. Reporting Currency";
    begin
        AdjustAddReportingCurrency.SetAddCurr(CurrencyCode);
        AdjustAddReportingCurrency.InitializeRequest(DocumentNo, LibraryERM.CreateGLAccountNo());
        AdjustAddReportingCurrency.UseRequestPage(false);
        AdjustAddReportingCurrency.Run();
    end;

    local procedure CreateCustomerWithAllowMultiplePostingGroups(var Customer: Record Customer; CustomerPostingGroupCode: Code[20]; VATBusPostGroupCode: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Customer.Validate("Customer Posting Group", CustomerPostingGroupCode);
        Customer.Modify(true);
    end;

    local procedure SetSalesAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        SalesReceivablesSetup.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        SetAppliesToIDValue: Variant;
        SetAppliesToID: Boolean;
    begin
        LibraryVariableStorage.Dequeue(SetAppliesToIDValue);
        SetAppliesToID := SetAppliesToIDValue;  // Assign Variant to Boolean.
        if SetAppliesToID then
            ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJnlTemplateModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandlerWithDocumentNo(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        SetAppliesToIDValue: Variant;
        SetAppliesToID: Boolean;
        DocumentNo: array[8] of Variant;
        i: Integer;
    begin
        LibraryVariableStorage.Dequeue(SetAppliesToIDValue);
        SetAppliesToID := SetAppliesToIDValue;
        if SetAppliesToID then
            for i := 1 to 8 do begin
                LibraryVariableStorage.Dequeue(DocumentNo[i]);
                ApplyCustomerEntries.Filter.SetFilter("Document No.", DocumentNo[i]);
                ApplyCustomerEntries."Set Applies-to ID".Invoke();
            end;
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyAndVerifyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
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

        // verify cr. memo entry
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        // apply entry
        ApplyCustomerEntries.AppliedAmount.AssertEquals(Round(-PaymentAmount * ExchangeRate, LibraryERM.GetAmountRoundingPrecision()));
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        // unapply
        // verify invoice entry
        ApplyCustomerEntries.Next();
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        // apply next entry
        ApplyCustomerEntries.AppliedAmount.AssertEquals(Round(InvoiceAmount * ExchangeRate, LibraryERM.GetAmountRoundingPrecision()));

        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPHAndPageControlValuesVerification(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        Value: Variant;
        SalesLineAmountLCY: Decimal;
        JournalLineAmount: Decimal;
        PageControlValue: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Value);
        SalesLineAmountLCY := Value;
        LibraryVariableStorage.Dequeue(Value);
        JournalLineAmount := Value;
        ApplyCustomerEntries."Set Applies-to ID".Invoke();

        Evaluate(PageControlValue, ApplyCustomerEntries.ApplnRounding.Value);
        Assert.AreEqual(
          SalesLineAmountLCY + JournalLineAmount, -PageControlValue, ApplyCustomerEntries.ApplnRounding.Caption);

        Evaluate(PageControlValue, ApplyCustomerEntries.ControlBalance.Value);
        Assert.AreEqual(
          0, PageControlValue, ApplyCustomerEntries.ControlBalance.Caption);

        ApplyCustomerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        CustomerLedgerEntries."Apply Entries".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesModalPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
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
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Run Handler", 'OnBeforeRunCustExchRateAdjustment', '', false, false)]
    local procedure RunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var IsHandled: Boolean)
    var
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
    begin
        ExchRateAdjmtProcess.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);
        IsHandled := true;
    end;
}

