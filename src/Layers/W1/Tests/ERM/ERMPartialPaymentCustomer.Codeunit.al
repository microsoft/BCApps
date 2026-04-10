codeunit 134002 "ERM Partial Payment Customer"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Application] [Sales]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        AmountToApplyError: Label '%1 must not be larger than %2 in %3 %4=''%5''.', Comment = '%1 = FIELD Caption, %2 = FIELD Caption,%3 =  Table Caption,%4 = Field Caption ,%5 =  FIELD Value';
        ErrorMessage: Label 'Error Message must be same.';
        AmountToApplySignError: Label '%1 must have the same sign as %2 in %3 %4=''%5''.', Comment = '%1 = FIELD Caption, %2 = FIELD Caption,%3 =  Table Caption,%4 = Field Caption ,%5 =  FIELD Value';
        NumberOfLineErrorMessage: Label 'Number Of Line Must be %1 in %2';

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyPmtToInvToAllClose()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Make multiple Invoices and a Payment entry for a New Customer from General Journal Line and verify Remaining Amount
        // and Open status value.
        Initialize();
        ApplyAmountToAllClose(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyRefndToCrMemoToAllCls()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Make multiple Credit Memos and a Refund entry for a New Customer from General Journal Line and Verify all customer
        // entries close.
        Initialize();
        ApplyAmountToAllClose(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -1);
    end;

    local procedure ApplyAmountToAllClose(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AmountSign: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        NoOfLines: Integer;
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Setup: Calculate Invoice/Credit Memo using RANDOM, it can be anything between .5 and 1000.
        // To close all entries take Payment/Refund Amount, multiplication of No. of Lines.
        // Create 2 to 10 Invoices/Credit Memo Boundary 2 is important and 1 Payment/Refund Line.
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        Amount2 := -Amount * NoOfLines;
        CreatePostMultipleGenJnlLine(TempGenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount * AmountSign, Amount2 * AmountSign);

        // Exercise: Application equally of Payment/Refund Amount on all Invoices/Credit Memo to close all Customer Ledger Entries.
        ApplyCustomerLedgerEntry(
          CustLedgerEntry, TempGenJournalLine."Document Type", TempGenJournalLine."Document No.", -Amount * AmountSign);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // Verify: Verify all entries are Closed.
        VerifyAllCustEntriesOpened(TempGenJournalLine, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyPmtToInvToAllOpen()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Make multiple Invoices and a Payment entry for a New Customer from General Journal Line and verify Remaining Amount
        // for all Customer entries.
        Initialize();
        ApplyAmountToAllOpen(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyRefndToCrMemoToAllOpn()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Make multiple Credit Memos and a Refund entry for a New Customer from General Journal Line verify Remaining Amount for
        // all Customer entries.
        Initialize();
        ApplyAmountToAllOpen(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -1);
    end;

    local procedure ApplyAmountToAllOpen(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AmountSign: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        DeltaAssert: Codeunit "Delta Assert";
        NoOfLines: Integer;
        Amount: Decimal;
        ApplAmount: Decimal;
    begin
        // Setup: Calculate Invoice/Credit Memo using RANDOM, it can be anything between .5 and 1000.
        // Application Amount can be anything between 1 and 99 % of the Payment/Refund to keep all entries are open.
        // Create 2 to 10 Invoices/Credit Memo Boundary 2 is important and 1 Payment/Refund Line.
        // Using Delta Assert to watch Remaining Amount expected value should be change after Delta amount application.
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        ApplAmount := (-Amount * LibraryRandom.RandInt(99) / 100) / NoOfLines;
        CreatePostMultipleGenJnlLine(TempGenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount * AmountSign, -Amount * AmountSign);

        TempGenJournalLine.SetRange("Document Type", DocumentType);
        DeltaAssert.Init();
        CalcRmngAmtForSameDirection(DeltaAssert, TempGenJournalLine, ApplAmount * AmountSign);
        TempGenJournalLine.SetRange("Document Type", DocumentType2);
        CalcRmngAmtForApplngEntry(DeltaAssert, TempGenJournalLine, NoOfLines, ApplAmount * AmountSign);

        // Exercise: Application Amount can be anything between 1 and 99% of the Payment/Refund Amount to keep all entries are open.
        ApplyCustomerLedgerEntry(
          CustLedgerEntry, TempGenJournalLine."Document Type", TempGenJournalLine."Document No.", ApplAmount * AmountSign);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // Verify: Verify Remaining Amount using Delta Assert.
        DeltaAssert.Assert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyPmtToInvToPmtClose()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Make multiple Invoices and a Payment entry for a New Customer from General Journal Line and verify all Invoice open
        // and only Payment entry close.
        Initialize();
        ApplyAmoutToPartialClose(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyRefndToCrMemoToRefCls()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Make multiple Credit Memos and a Refund entry for a New Customer from General Journal Line and Verify Refund entry close
        // and all Credit Memos Open.
        Initialize();
        ApplyAmoutToPartialClose(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -1);
    end;

    local procedure ApplyAmoutToPartialClose(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AmountSign: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        NoOfLines: Integer;
        Amount: Decimal;
        ApplAmount: Decimal;
    begin
        // Setup: Calculate Invoice/Credit Memo using RANDOM, it can be anything between .5 and 1000.
        // Create 2 to 10 Invoices/Credit Memo Boundary 2 is important and 1 Payment/Refund Line.
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        ApplAmount := -Amount / NoOfLines;
        CreatePostMultipleGenJnlLine(TempGenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount * AmountSign, -Amount * AmountSign);

        // Exercise: Apply Payment/Refund Amount Equally on all Invoices/Credit Memo.
        ApplyCustomerLedgerEntry(
          CustLedgerEntry, TempGenJournalLine."Document Type", TempGenJournalLine."Document No.", ApplAmount * AmountSign);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // Verify: Verify Invoices/Credit memo are open after partial application and only Payment/Refund entry close.
        TempGenJournalLine.SetRange("Document Type", DocumentType);
        VerifyAllCustEntriesOpened(TempGenJournalLine, true);
        TempGenJournalLine.SetRange("Document Type", DocumentType2);
        VerifyAllCustEntriesOpened(TempGenJournalLine, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyPmtToInvAndPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Make an Invoice and multiple Payments entry for a New Customer from General Journal Line and verify Payment line
        // Remaining Amount.
        Initialize();
        ApplyAmoutToSameDocumentType(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyRefndToCrMemoAndRefnd()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Make a Credit Memo and multiple Refunds entry for half of Credit Memo value for a New Customer from General Journal Line
        // Verify Refund line Remaining Amount.
        Initialize();
        ApplyAmoutToSameDocumentType(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -1);
    end;

    local procedure ApplyAmoutToSameDocumentType(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AmountSign: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        DeltaAssert: Codeunit "Delta Assert";
        NoOfLines: Integer;
        Amount: Decimal;
        ApplAmount: Decimal;
    begin
        // Setup: Calculate Invoice/Credit Memo using RANDOM, it can be anything between .5 and 1000.
        // Application can be anything between 1 and 49 percent of Payment/Refund amount.
        // Create 2 to 10 Payments/Refunds Boundary 2 is important and 1 Invoice/Credit Memo Line.
        // Using Delta Assert to watch Original Amount and Remaining Amount difference should zero in case of application for same entry.
        // Remaining Amount should be change only for Applying entry after Delta amount application.
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(2000) / 2;
        ApplAmount := -Amount * (LibraryRandom.RandInt(49) / 100) / NoOfLines;
        CreatePostMultipleGenJnlLine(TempGenJournalLine, DocumentType2, DocumentType, NoOfLines, -Amount * AmountSign, Amount * AmountSign);

        TempGenJournalLine.SetRange("Document Type", DocumentType2);
        DeltaAssert.Init();
        CalcRmngAmtForApplOnSameEntry(DeltaAssert, TempGenJournalLine);
        CustLedgerEntry.SetRange("Document No.", TempGenJournalLine."Document No.");  // Filter applying entry.
        CustLedgerEntry.FindFirst();
        DeltaAssert.AddWatch(
          DATABASE::"Cust. Ledger Entry", CustLedgerEntry.GetPosition(), CustLedgerEntry.FieldNo("Remaining Amount"),
          CustLedgerEntry.Amount - (ApplAmount * AmountSign));

        // Exercise: Application Amount between 1 to 49 % to Apply equally on all lines.
        ApplyCustomerLedgerEntry(
          CustLedgerEntry, TempGenJournalLine."Document Type", TempGenJournalLine."Document No.", ApplAmount * AmountSign);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // Verify: Payment/Refund Line Remaining Amount.
        DeltaAssert.Assert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyPaymentToInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Apply Payment to Invoice and validate Amount to Apply field.

        // Setup.
        Initialize();
        SetAppliesIDOnCustomerEntry(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(1000, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Apply Refund to Credit Memo and validate Amount to Apply field.

        // Setup.
        Initialize();
        SetAppliesIDOnCustomerEntry(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(1000, 2));
    end;

    local procedure SetAppliesIDOnCustomerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Create and post General Journal Line.
        DocumentNo :=
          CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, Amount, Amount);

        // Exercise: Set Apply To ID.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // Verify: Verify Amount to Apply field in Customer Ledger Entry.
        VerifyCustomerLedgerEntry(CustLedgerEntry, Amount);

        // Tear Down: Delete the General Journal Line.
        DeleteGeneralJournalLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyOnInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PmtAmount: Decimal;
    begin
        // Apply Payment to Invoice and change Amount to Apply and validate Amount To Apply field.
        // Use Random Number Generator for Payment Amount, Invoice Amount will always greater than Payment Amount and
        // Application Amount must be equal to Payment Amount.

        // Setup.
        Initialize();
        PmtAmount := LibraryRandom.RandDec(1000, 2);  // Use Random Number Generator to generate payment Amount.
        ChangeAmountToApply(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, PmtAmount * 2, PmtAmount, PmtAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyGreaterThanPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
    begin
        // Apply Payment to Invoice and change Amount to Apply greater than Payment Amount and validate Amount To Apply field.
        // Use Random Number Generator for Invoice Amount, Payment Amount must be less than Invoice Amount and Application
        // Amount must be greater than Payment Amount and less than Invoice Amount.

        // Setup.
        Initialize();
        InvAmount := 100 * LibraryRandom.RandInt(10);  // Use Random Number Generator to generate Invoice Amount.
        ChangeAmountToApply(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, LibraryRandom.RandInt(50),
          InvAmount - LibraryRandom.RandInt(10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyLessThanPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
    begin
        // Apply Payment to Invoice and change Amount to Apply less than Payment Amount and validate Amount To Apply field.
        // Use Random Number Generator for Invoice Amount and Application Amount must be less than Payment Amount.

        // Setup.
        Initialize();
        InvAmount := LibraryRandom.RandDec(100, 2);  // Use Random Number Generator to generate Invoice Amount.
        ChangeAmountToApply(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvAmount, InvAmount, InvAmount - InvAmount / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyOnCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RefundAmount: Decimal;
    begin
        // Apply Refund to Credit Memo and change Amount to Apply and validate Amount To Apply field.
        // Use Random Number Generator for Refund Amount, Credit Memo Amount greater than Refund Amount, Application Amount must be less
        // than Credit Memo Amount.

        // Setup.
        Initialize();
        RefundAmount := -LibraryRandom.RandDec(1000, 2);
        ChangeAmountToApply(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, RefundAmount * 2, RefundAmount,
          RefundAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyMoreThanRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreditMemoAmount: Decimal;
    begin
        // Apply Refund to Credit Memo and change Amount to Apply greater than Refund Amount and validate Amount To Apply field.
        // Use Random Number Generator for Credit Memo Amount, Refund Amount must be less than Credit Memo Amount, Application Amount
        // must be greater than Refund Amount and less than Credit Memo Amount.

        // Setup.
        Initialize();
        CreditMemoAmount := -100 * LibraryRandom.RandDec(10, 2);  // Use Random Number Generator to generate Credit Memo Amount.
        ChangeAmountToApply(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CreditMemoAmount,
          LibraryRandom.RandDec(50, 2), CreditMemoAmount + LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyLessThanRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreditMemoAmount: Decimal;
    begin
        // Apply Refund to Credit Memo and change Amount to Apply less than Refund Amount and validate Amount To Apply field.
        // Use Random Number Generator for Credit Memo Amount, Application Amount must be less than Refund Amount.

        // Setup.
        Initialize();
        CreditMemoAmount := -(100 * LibraryRandom.RandDec(100, 2));  // Use Random Number Generator to generate Credit Memo Amount.
        ChangeAmountToApply(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CreditMemoAmount, CreditMemoAmount,
          -LibraryRandom.RandDec(50, 2));
    end;

    local procedure ChangeAmountToApply(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; InvAmount: Decimal; PmtAmount: Decimal; AmountToApply: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        DocumentNo :=
          CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, InvAmount, PmtAmount);

        // Exercise: Find Customer Ledger Entry and change Amount to Apply field in Customer Ledger Entry.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.Validate("Amount to Apply", AmountToApply);

        // Verify: Verify Amount to Apply field in Customer Ledger Entry.
        Assert.IsTrue(CustLedgerEntry.Modify(true), 'Cust. Ledger Entry must modify');

        // Tear Down: Delete the General Journal Line.
        DeleteGeneralJournalLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyGreaterThanInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
    begin
        // Apply Payment to Invoice and change Amount to Apply greater than Invoice Amount and validate Error Message.
        // Use Random Number Generator for Invoice Amount, Application Amount must be greater than Invoice Amount.

        // Setup.
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        LargeAmountApplicationError(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvoiceAmount, InvoiceAmount * 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyMoreThanCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreditMemoAmount: Decimal;
    begin
        // Apply Refund to Credit Memo and change Amount to Apply greater than Credit Memo Amount and validate Error Message.
        // Use Random Number Generator for Credit Memo Amount, Application Amount must be greater than Credit Memo Amount.

        // Setup.
        Initialize();
        CreditMemoAmount := LibraryRandom.RandDec(100, 2);
        LargeAmountApplicationError(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -CreditMemoAmount, -CreditMemoAmount * 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyInvTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
        ApplyAmount: Decimal;
    begin
        // Apply Payment to Invoice and change Amount to Apply More than Invoice but within Tolerance and validate Error Message.
        // Use Random Number Generator for Invoice Amount, Application Amount must be greater than Invoice Amount but within Tolerance.
        // To find Application Amount using Payment Tolerance % from General Ledger Setup fix the Seed value till 499.

        // Setup: Update General Ledger Setup.
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(499, 2);
        UpdateGeneralLedgerSetup(1, 5);
        ApplyAmount := InvoiceAmount + InvoiceAmount * 1 / 100;

        // Verify
        LargeAmountApplicationError(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, InvoiceAmount, ApplyAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyCrMemoTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CreditMemoAmount: Decimal;
    begin
        // Apply Refund to Credit Memo and change Amount to Apply More than Credit Memo but within Tolerance and validate Error Message.
        // Use Random Number Generator for Credit Memo Amount, Application Amount must be greater than Credit Memo Amount but within
        // Tolerance.
        // To find Application Amount using Maximum Payment Tolerance Amount from General Ledger Setup fix the Seed value above 500.

        // Setup: Update General Ledger Setup.
        Initialize();
        CreditMemoAmount := -500 * LibraryRandom.RandDec(100, 2);
        UpdateGeneralLedgerSetup(1, 5);

        // Verify
        LargeAmountApplicationError(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CreditMemoAmount,
          CreditMemoAmount - 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyNegative()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Apply Payment to Invoice and change Amount to Apply to negative Amount and validate Error Message.
        Initialize();
        SameSignApplicationError(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountToApplyToPositive()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Apply Refund to Credit Memo and change Amount to Apply to Positive Amount and validate Error Message.
        Initialize();
        SameSignApplicationError(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure SameSignApplicationError(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post General Journal Line.
        DocumentNo := CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, Amount, -Amount);

        // Exercise: Find Customer Ledger Entry and change Amount to Apply in Customer Ledger Entry.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        asserterror CustLedgerEntry.Validate("Amount to Apply", -Amount);

        // Verify: Verify Error Message in Customer Ledger Entry.
        Assert.AreEqual(
          StrSubstNo(AmountToApplySignError, CustLedgerEntry.FieldCaption("Amount to Apply"),
            CustLedgerEntry.FieldCaption("Remaining Amount"), CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."),
            CustLedgerEntry."Entry No."), GetLastErrorText, ErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentToInvoiceWithApplyEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Apply Payment against the Invoices and show Only Applied Entries for Customer.
        Initialize();
        SetApplyIdToDocument(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefundCreditMemoWithApplyEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Apply Refund against the Credit Memo and Show Only Applied Entries for Customer.
        Initialize();
        SetApplyIdToDocument(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, -1);
    end;

    local procedure SetApplyIdToDocument(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AmountSign: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NumberOfLines: Integer;
    begin
        // Setup: Create Customer, Create and post General Journal Lines.
        NumberOfLines := 1 + LibraryRandom.RandInt(5);  // Use Random Number to generate more than one line.
        SelectGenJournalBatch(GenJournalBatch);
        CreateDocumentLine(
          GenJournalLine, GenJournalBatch, NumberOfLines, DocumentType, CreateCustomer(), LibraryRandom.RandDec(100, 2) * AmountSign);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, 1, DocumentType2, GenJournalLine."Account No.", -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Set Applies to ID to all Invoices/Credit Memos.
        ApplyPaymentToCustomer(GenJournalLine."Account No.", NumberOfLines, DocumentType, DocumentType2);

        // Verify: Count Customer Ledger Entry for which Applies To Id is not Blank.
        CountCustomerLedgerEntry(GenJournalLine."Account No.", NumberOfLines);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndPostPaymentToInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Customer Application of Payment to Invoice during posting of Payment.

        // Setup: Set CreditWarnings to No Warning on Sales Receivable Setup.
        // Create and Post General Journal Line with Document Type as Invoice.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Create, Apply and Post General Journal with Document Type as Payment by General Journal Page.
        ApplyAndPostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::Payment);

        // Verify: Verify Remaining Amount on Customer Ledger Entry.
        VerifyRemainingAmountOnLedger(GenJournalLine."Document Type"::Invoice, GenJournalLine."Account No.", 0);
        VerifyRemainingAmountOnLedger(GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", 0);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndPostRefundToCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Customer Application of Refund to Credit Memo during posting of Refund.

        // Setup: Set CreditWarnings to No Warning on Sales Receivable Setup.
        // Create and Post General Journal Line with Document Type as Credit Memo.
        Initialize();
        LibrarySales.SetCreditWarningsToNoWarnings();
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Create, Apply and Post General Journal with Document Type as Refund by General Journal Page.
        ApplyAndPostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::Refund);

        // Verify: Verify Remaining Amount on Customer Ledger Entry.
        VerifyRemainingAmountOnLedger(GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account No.", 0);
        VerifyRemainingAmountOnLedger(GenJournalLine."Document Type"::Refund, GenJournalLine."Account No.", 0);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesWithCustomAmountHandler,ConfirmHandlerVerify,MessageHandler')]
    [Scope('OnPrem')]
    procedure RefundAppliedToPaymentPartialFCY()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentAmount: Decimal;
        RefundAmount: Decimal;
    begin
        Initialize();

        PaymentAmount := -2369.05;
        RefundAmount := 2369.04;

        ScenarioRefundAppliedToPayment(Customer, PaymentAmount, RefundAmount);

        VerifyAmountRemainingAmountOpenOnLedger(
          CustLedgerEntry."Document Type"::Payment, Customer."No.", PaymentAmount, -0.01, true);

        VerifyAmountRemainingAmountOpenOnLedger(
          CustLedgerEntry."Document Type"::Refund, Customer."No.", RefundAmount, 0, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesWithCustomAmountHandler,ConfirmHandlerVerify,MessageHandler')]
    [Scope('OnPrem')]
    procedure RefundAppliedToPaymentPartialFCYCustomApplRounding()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentAmount: Decimal;
        RefundAmount: Decimal;
    begin
        Initialize();

        LibraryERM.SetApplnRoundingPrecision(5);

        PaymentAmount := -2369.05;
        RefundAmount := 2369.04;

        ScenarioRefundAppliedToPayment(Customer, PaymentAmount, RefundAmount);

        VerifyAmountRemainingAmountOpenOnLedger(
          CustLedgerEntry."Document Type"::Payment, Customer."No.", PaymentAmount, -0.01, true);

        VerifyAmountRemainingAmountOpenOnLedger(
          CustLedgerEntry."Document Type"::Refund, Customer."No.", RefundAmount, 0, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
    end;

    local procedure ApplyAndPostGeneralJournal(GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine2: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine2, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.", -GenJournalLine.Amount);
        GenJournalLine2.Validate("Bal. Account No.", GenJournalLine."Bal. Account No.");
        GenJournalLine2.Modify(true);

        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Apply Entries".Invoke();  // Apply Entries.
        GeneralJournal.Post.Invoke();  // Post General Journal.
    end;

    local procedure ApplyPaymentToCustomer(CustomerNo: Code[20]; NumberOfLines: Integer; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, DocumentType2);
        CustLedgerEntry.CalcFields(Amount);
        FindCustomerLedgerEntry(CustLedgerEntry2, CustomerNo, DocumentType);
        repeat
            CustLedgerEntry2.Validate("Amount to Apply", -CustLedgerEntry.Amount / NumberOfLines);
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
    end;

    local procedure ApplyCustomerLedgerEntry(var ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLRegister: Record "G/L Register";
    begin
        LibraryERM.FindCustomerLedgerEntry(ApplyingCustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(ApplyingCustLedgerEntry, AmountToApply);

        // Find Posted Customer Ledger Entries.
        GLRegister.FindLast();
        CustLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        CustLedgerEntry.SetRange("Applying Entry", false);
        CustLedgerEntry.FindSet();
        repeat
            if (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice) or
               (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::"Credit Memo")
            then
                CustLedgerEntry.Validate("Amount to Apply", -AmountToApply);

            // Case of Applying Amount on same Document Type.
            if (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Payment) or
               (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Refund)
            then
                CustLedgerEntry.Validate("Amount to Apply", AmountToApply);
            CustLedgerEntry.Modify(true);
        until CustLedgerEntry.Next() = 0;

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
    end;

    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; NumberOfLines: Integer; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; Amount: Decimal)
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfLines do
            CreateGenJnlLine(GenJournalLine, GenJournalBatch, DocumentType, Amount, CustomerNo, IncStr(GenJournalLine."Document No."));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; InvoiceAmount: Decimal; PaymentAmount: Decimal) DocumentNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Select Journal Batch Name and Template Name.
        SelectGenJournalBatch(GenJournalBatch);
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, DocumentType, InvoiceAmount, CreateCustomer(), IncStr(GenJournalLine."Document No."));
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJnlLine(
          GenJournalLine, GenJournalBatch, DocumentType2, -PaymentAmount, GenJournalLine."Account No.",
          IncStr(GenJournalLine."Document No."));
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CustomerNo: Code[20]; DocumentNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        if DocumentNo <> '' then begin
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Modify(true);
        end;
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        Amount: Decimal;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJournalBatch(GenJournalBatch);

        case DocumentType of
            GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Refund:
                Amount := LibraryRandom.RandDec(100, 2);
            GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Payment:
                Amount := -LibraryRandom.RandDec(100, 2);
        end;

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, Customer."No.", Amount);

        // Value of Document No. is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    local procedure CalcRmngAmtForSameDirection(var DeltaAssert: Codeunit "Delta Assert"; var TempGenJournalLine: Record "Gen. Journal Line" temporary; ApplAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Watch Remaining Amount expected value should be change after Delta amount application.
        TempGenJournalLine.FindSet();
        repeat
            CustLedgerEntry.SetRange("Document No.", TempGenJournalLine."Document No.");
            CustLedgerEntry.FindFirst();
            DeltaAssert.AddWatch(
              DATABASE::"Cust. Ledger Entry", CustLedgerEntry.GetPosition(), CustLedgerEntry.FieldNo("Remaining Amount"),
              CustLedgerEntry.Amount + ApplAmount);
        until TempGenJournalLine.Next() = 0;
    end;

    local procedure CalcRmngAmtForApplngEntry(var DeltaAssert: Codeunit "Delta Assert"; var TempGenJournalLine: Record "Gen. Journal Line" temporary; NoOfLines: Integer; ApplAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Watch Remaining Amount expected value should be change after Delta amount application.
        TempGenJournalLine.FindFirst();
        CustLedgerEntry.SetRange("Document No.", TempGenJournalLine."Document No.");
        CustLedgerEntry.FindFirst();
        DeltaAssert.AddWatch(
          DATABASE::"Cust. Ledger Entry", CustLedgerEntry.GetPosition(), CustLedgerEntry.FieldNo("Remaining Amount"),
          CustLedgerEntry.Amount - ApplAmount * NoOfLines);
    end;

    local procedure CalcRmngAmtForApplOnSameEntry(var DeltaAssert: Codeunit "Delta Assert"; var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Watch Remaining Amount expected value should remain same after Delta amount application on same entry.
        TempGenJournalLine.FindSet();
        repeat
            CustLedgerEntry.SetRange("Document No.", TempGenJournalLine."Document No.");
            CustLedgerEntry.FindFirst();
            DeltaAssert.AddWatch(
              DATABASE::"Cust. Ledger Entry", CustLedgerEntry.GetPosition(), CustLedgerEntry.FieldNo("Remaining Amount"), 0);
        until TempGenJournalLine.Next() = 1;
    end;

    local procedure ScenarioRefundAppliedToPayment(var Customer: Record Customer; PaymentAmount: Decimal; RefundAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Customer.Modify(true);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", PaymentAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        Clear(GenJournalLine);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, Customer."No.", RefundAmount);

        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        LibraryVariableStorage.Enqueue(-RefundAmount);
        LibraryVariableStorage.Enqueue('Do you want to post the journal lines?');
        LibraryVariableStorage.Enqueue(true);
        GeneralJournal."Apply Entries".Invoke();
        GeneralJournal.Post.Invoke();
        GeneralJournal.Close();
    end;

    local procedure CreatePostMultipleGenJnlLine(var TempGenJournalLine: Record "Gen. Journal Line" temporary; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; NoOfLines: Integer; Amount: Decimal; Amount2: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create multiple General Journal Lines for Invoice/Credit Memo and single for Payment/Refund.
        SelectGenJournalBatch(GenJournalBatch);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, NoOfLines, DocumentType, CreateCustomer(), Amount);
        CreateDocumentLine(GenJournalLine, GenJournalBatch, 1, DocumentType2, GenJournalLine."Account No.", Amount2);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CountCustomerLedgerEntry(CustomerNo: Code[20]; CustLedgerEntryCount: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetFilter("Applies-to ID", '<>''''');
        Assert.AreEqual(
          CustLedgerEntryCount, CustLedgerEntry.Count, StrSubstNo(NumberOfLineErrorMessage, CustLedgerEntry.Count,
            CustLedgerEntry.TableCaption()));
    end;

    local procedure DeleteGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure LargeAmountApplicationError(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; AmountToApply: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Create and post General Journal Line.
        DocumentNo := CreateAndPostGenJournalLine(GenJournalLine, DocumentType, DocumentType2, Amount, Amount);

        // Exercise: Find Customer Ledger Entry and change Amount to Apply in Customer Ledger Entry.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        asserterror CustLedgerEntry.Validate("Amount to Apply", AmountToApply);

        // Verify: Verify Error Message in Customer Ledger Entry.
        Assert.AreEqual(
          StrSubstNo(
            AmountToApplyError, CustLedgerEntry.FieldCaption("Amount to Apply"), CustLedgerEntry.FieldCaption("Remaining Amount"),
            CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."),
          GetLastErrorText, ErrorMessage);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select Journal Batch Name and Template Name.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdateGeneralLedgerSetup(PaymentTolerancePercent: Decimal; MaxPaymentToleranceAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", PaymentTolerancePercent);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", MaxPaymentToleranceAmount);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure SaveGenJnlLineInTempTable(var TempGenJournalLine: Record "Gen. Journal Line" temporary; GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
        repeat
            TempGenJournalLine := GenJournalLine;
            TempGenJournalLine.Insert();
        until GenJournalLine.Next() = 0;
    end;

    local procedure VerifyAllCustEntriesOpened(var TempGenJournalLine: Record "Gen. Journal Line" temporary; Open: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify all Customer Entries are Close/Open.
        TempGenJournalLine.FindSet();
        repeat
            CustLedgerEntry.SetRange("Document No.", TempGenJournalLine."Document No.");
            CustLedgerEntry.FindFirst();
            CustLedgerEntry.TestField(Open, Open);
        until TempGenJournalLine.Next() = 0;
    end;

    local procedure VerifyCustomerLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; AmountToApply: Decimal)
    begin
        CustLedgerEntry.TestField("Amount to Apply", AmountToApply);
    end;

    local procedure VerifyRemainingAmountOnLedger(DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; RemainingAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, DocumentType);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", RemainingAmount);
    end;

    local procedure VerifyAmountRemainingAmountOpenOnLedger(DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; ExpectedAmount: Decimal; ExpectedRemainingAmount: Decimal; ExpectedOpen: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, DocumentType);
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        CustLedgerEntry.TestField(Amount, ExpectedAmount);
        CustLedgerEntry.TestField("Remaining Amount", ExpectedRemainingAmount);
        CustLedgerEntry.TestField(Open, ExpectedOpen);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesWithCustomAmountHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Amount to Apply".SetValue(LibraryVariableStorage.DequeueDecimal());
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerVerify(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

