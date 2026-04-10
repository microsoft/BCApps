codeunit 134134 "ERM Reverse Bank Ledger"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Bank Ledger]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ReverseErr: Label 'You cannot reverse Bank Account Ledger Entry No. %1 because the entry is closed.', Locked = true;
        CheckLedgerEntryErr: Label 'You cannot reverse %1 No. %2 because the entry has a related check ledger entry.', Locked = true;
        VoidCheckErr: Label 'You cannot reverse %1 No. %2 because the entry has a related check ledger entry.', Locked = true;
        ReconciliationErr: Label 'You cannot reverse %1 No. %2 because the entry is included in a bank account reconciliation line. The bank reconciliation has not yet been posted.', Locked = true;
        CompressErr: Label 'The transaction cannot be reversed, because the %1 has been compressed.', Locked = true;
        VerifyErr: Label 'Error must match.', Locked = true;
        isInitialized: Boolean;
        VoidType: Option "Unapply and void check","Void check only";

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseBlockedBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccount: Record "Bank Account";
    begin
        // Check Reverse Error on Bank Account is Blocked.

        // Setup: Create General Journal Line With Bank Account and Post it and Modify Bank Account for Blocked.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        BlockBankAccount(GenJournalLine."Bal. Account No.");
        // Exercise: Reverse Modify Bank Account.
        ReverseBankAccountLedgerEntry(BankAccountLedgerEntry, GenJournalLine."Document No.");
        // Verify: Verify Reversal Process for Blocked Bank Account Ledger Entry.

        Assert.ExpectedTestFieldError(BankAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseManualCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        // Check Reverse Error on Bank Account posted with Manual Check.

        // Setup: Create General Journal Line With Bank Account with Manual Check and Post it.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bank Payment Type"::"Manual Check", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        // Exercise: Reverse Bank Account Ledger Entry.
        ReverseBankAccountLedgerEntry(BankAccountLedgerEntry, GenJournalLine."Document No.");
        // Verify: Verify Reversing Error.
        Assert.AreEqual(
          StrSubstNo(CheckLedgerEntryErr, BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No."),
          GetLastErrorText, VerifyErr);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseVoidCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        // Check Reverse Error on Bank Account Posted with Void Check.

        // Setup: Create General Journal Line Post it With Bank Account and Run Void Check.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bank Payment Type"::"Manual Check", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');

        VoidCheck(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", VoidType::"Void check only");
        // Exercise: Reverse Bank Account Ledger Entry.
        ReverseBankAccountLedgerEntry(BankAccountLedgerEntry, GenJournalLine."Document No.");
        // Verify: Verify Reversing Error on Bank Account Ledger Entry.
        Assert.AreEqual(
          StrSubstNo(VoidCheckErr, BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No."),
          GetLastErrorText, VerifyErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseAdjustExchangeRate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
        EntryNo: Integer;
    begin
        // Check Reverse Error After Modify and Run Adjust Exchange Rate Batch Job for Customer.

        // Setup: Create General Journal Line With Customer and with Currency and Post it and Modify, Run Adjust Exchange Rate Batch Job.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bank Payment Type"::" ", CreateCurrency(), CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        ModifyCurrencyAndExchangeRate(GenJournalLine."Currency Code");
        LibraryERM.RunExchRateAdjustmentSimple(GenJournalLine."Currency Code", WorkDate(), WorkDate());
        // Exercise: Reverse Customer Ledger Entry.
        EntryNo := ReverseCustomerLedgerEntry(GenJournalLine."Document No.");
        // Verify: Verify Reversing Error for Customer Ledger Entry After Updation of Currency.
        Assert.AreEqual(
          ReversalEntry.ReversalErrorForChangedEntry(CustLedgerEntry.TableCaption(), EntryNo),
          GetLastErrorText, VerifyErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseBankReconcltn()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        // Check Reverse Error After Suggest Bank Reconciliation.

        // Setup: Create General Journal Line With Customer and Post it and Create, Suggest Bank Reconciliation.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        CreateAndSuggestBankReconcltn(BankAccReconciliation, GenJournalLine."Bal. Account No.", GenJournalLine."Posting Date");
        // Exercise: Reverse Bank Account Ledger Entry.
        ReverseBankAccountLedgerEntry(BankAccountLedgerEntry, GenJournalLine."Document No.");
        // Verify: Verify Reversing Error for Bank Account Ledger Entry After creating Bank Reconciliation.
        Assert.AreEqual(
          StrSubstNo(ReconciliationErr, BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No."),
          GetLastErrorText, VerifyErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReversePostBankReconcltn()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        // Check Reverse Error After Suggest and Modify Bank Reconciliation and Post.

        // Setup: Create General Journal Line With Customer and Post it.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');

        CreateAndSuggestBankReconcltn(BankAccReconciliation, GenJournalLine."Bal. Account No.", GenJournalLine."Posting Date");
        ModifyBankReconcltn(BankAccReconciliation);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        // Exercise: Create and Suggest Bank Reconciliation, Modify and Post it.
        ReverseBankAccountLedgerEntry(BankAccountLedgerEntry, GenJournalLine."Document No.");
        // Verify: Verify Reversing Error for Bank Account Ledger Entry After Modify and Post Bank Reconciliation.
        Assert.AreEqual(StrSubstNo(ReverseErr, BankAccountLedgerEntry."Entry No."), GetLastErrorText, VerifyErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseComprBankReconcltn()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Check Reverse Error After Suggest and Modify Bank Reconciliation for Bank Post and Run Date Compress.

        // Setup: Create and Post General Journal Line. Create, Suggest and Modify Bank Reconciliation and Run Date Compress for Bank.
        Initialize();
        DocumentNo := ReversAndCompressBankReconcltn(GenJournalLine."Account Type"::"Bank Account", CreateBankAccount());

        // Exercise: Reverse Bank Account Ledger Entry.
        ReverseBankAccountLedgerEntry(BankAccountLedgerEntry, DocumentNo);

        // Verify: Verify Reverse Error on Bank Account Ledger Entry After Run Data Compress.
        Assert.AreEqual(StrSubstNo(CompressErr, BankAccountLedgerEntry.TableCaption()), GetLastErrorText, VerifyErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseComprBankReconcltnCust()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Check Reverse Error After Suggest and Modify Bank Reconciliation for Customer Post and Run Date Compress.

        // Setup: Create and Post General Journal Line. Create, Suggest and Modify Bank Reconciliation and Run Date Compress for Customer.
        Initialize();
        DocumentNo := ReversAndCompressBankReconcltn(GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo());

        // Exercise: Reverse Customer Ledger Entry.
        ReverseCustomerLedgerEntry(DocumentNo);

        // Verify: Verify Reverse Error on Customer Ledger Entry After Run Data Compress.
        Assert.AreEqual(StrSubstNo(CompressErr, BankAccountLedgerEntry.TableCaption()), GetLastErrorText, VerifyErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseComprBankReconcltnVend()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Check Reverse Error After Suggest and Modify Bank Reconciliation for Vendor Post and Run Date Compress.

        // Setup: Create and Post General Journal Line. Create, Suggest and Modify Bank Reconciliation and Run Date Compress for Vendor.
        Initialize();
        DocumentNo := ReversAndCompressBankReconcltn(GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());

        // Exercise: Reverse Vendor Ledger Entry.
        ReverseVendorLedgerEntry(DocumentNo);

        // Verify: Verify Reverse Error on Vendor Ledger Entry After Run Data Compress.
        Assert.AreEqual(StrSubstNo(CompressErr, BankAccountLedgerEntry.TableCaption()), GetLastErrorText, VerifyErr);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure VoidGLAccountCheckLedgerEnrty()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that system correctly void the check ledger entry for GL Account.
        VoidCheckLedgerEntry(GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure VoidVendorCheckLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that system correctly void the check ledger entry for Vendor.
        VoidCheckLedgerEntry(GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure VoidCustomerCheckLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that system correctly void the check ledger entry for Customer.
        VoidCheckLedgerEntry(GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo());
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure VoidCustomerBankAccLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create and Post General Journal line with non-empty Document type.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bank Payment Type"::"Manual Check", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        // Exercise: Void the created the check ledger entry.
        VoidCheck(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", VoidType::"Void check only");
        // Verify: Verify that Document type is not empty in the bank account ledger entry.
        VerifyRefundBankAccLedgerEntry(GenJournalLine."Bal. Account No.", GenJournalLine."Posting Date", GenJournalLine."Document No.", -GenJournalLine.Amount, GetGenJnlSourceCode());
        VerifyRefundBankAccLedgerEntry(GenJournalLine."Bal. Account No.", WorkDate(), GenJournalLine."Document No.", GenJournalLine.Amount, GetFinVoidedSourceCode());
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure VoidBankCheckLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that system correctly void the check ledger entry for Bank.
        VoidCheckLedgerEntry(GenJournalLine."Account Type"::"Bank Account", CreateBankAccount());
    end;

    local procedure VoidCheckLedgerEntry(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create and Post General Journal line with bank Payment Type Manual Check.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", AccountType, AccountNo,
          GenJournalLine."Bank Payment Type"::"Manual Check", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        // Exercise: Void the created the check ledger entry.
        VoidCheck(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", VoidType::"Void check only");
        // Verify: Verify that system correctly voided the check ledger entry.
        VerifyCheckLedgerEntry(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure VoidAndUnapplyVendorCheckLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Test that sytem correctly void the check ledger entry and unapply the vendor ledger entry.

        // Setup: Create and apply the general journal line for vendor and then post it.
        Initialize();
        DocumentNo := ApplyGenJournalLineForBankPaymentType(GenJournalLine, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());
        // Exercise: Void and unapply the check ledger entry.
        VoidCheck(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", VoidType::"Unapply and void check");
        // Verify: Verify that system correctly voided the check ledger entry and unappy the vendor ledger entry.
        VerifyCheckLedgerEntry(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", GenJournalLine.Amount);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure VoidAndUnapplyCustomerCheckLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Test that sytem correctly void the check ledger entry and unapply the customer ledger entry.

        // Setup: Create and apply the general journal line for customer and then post it.
        Initialize();
        DocumentNo := ApplyGenJournalLineForBankPaymentType(GenJournalLine, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo());
        // Exercise: Void and unapply the check ledger entry.
        VoidCheck(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", VoidType::"Unapply and void check");
        // Verify: Verify that system correctly voided the check ledger entry and unappy the customer ledger entry.
        VerifyCheckLedgerEntry(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", GenJournalLine.Amount);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", -GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VoidCheckNotPrintedNotPosted()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CheckManagement: Codeunit CheckManagement;
    begin
        // Test that system does not allow to void the computer check that has not been printed and posted.

        // Setup: Create General Journal line with Bank Payment Type Computer check.
        Initialize();
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bank Payment Type"::"Computer Check", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        // Exercise: Void thec check which has not been printed and posted.
        asserterror CheckManagement.VoidCheck(GenJournalLine);
        // Verify: Verify that system throws the error while performing void check.
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Check Printed"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendorBankAccLedgerEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
    begin
        // Test that system correctly apply and unapply the Bank Account ledger entries for Vendor.
        // Setup: Post Payment Journal for Vendor
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bank Payment Type"::"Manual Check", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        CreateAndSuggestBankReconcltn(BankAccReconciliation, GenJournalLine."Bal. Account No.", GenJournalLine."Posting Date");
        // Exercise: Apply entries by invoking Match Manually
        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.FILTER.SetFilter("Bank Account No.", GenJournalLine."Bal. Account No.");
        BankAccReconciliationPage.MatchManually.Invoke();

        // Verify:
        BankAccReconciliationPage.ApplyBankLedgerEntries.LineApplied.AssertEquals(true);
        BankAccReconciliationPage.StmtLine."Applied Amount".AssertEquals(-GenJournalLine.Amount);
        // Also Verifies no error message appears when apply or unapply Ledger Entry.
        BankAccReconciliationPage.RemoveMatch.Invoke();
        BankAccReconciliationPage.ApplyBankLedgerEntries.LineApplied.AssertEquals(false);
        BankAccReconciliationPage.StmtLine."Applied Amount".AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendorCheckLedgerEntries()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
    begin
        // Test that system correctly apply and unapply the Check ledger entries for Vendor.
        // Setup: Post Payment Journal for Vendor and modify Bank Account Reconciliation Line with type "Check Ledger Entry".
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bank Payment Type"::"Manual Check", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        CreateAndSuggestBankReconcltn(BankAccReconciliation, GenJournalLine."Bal. Account No.", GenJournalLine."Posting Date");
        // Exercise: Open Apply Entries from Bank Acc. Reconciliation Page.
        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.FILTER.SetFilter("Bank Account No.", GenJournalLine."Bal. Account No.");
        BankAccReconciliationPage.MatchManually.Invoke();

        // Verify:
        BankAccReconciliationPage.StmtLine."Applied Amount".ASSERTEQUALS(-GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReversedBankLedgerEntriesAreClosed()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PostingDate: Date;
        BankAccountNo: Code[20];
        ReversedDocumentNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Bank Account Reconcilation]
        // [SCENARIO 379442] On reversal, Bank Account Ledger entry is closed along with reversal entry
        Initialize();
        PostingDate := WorkDate();

        // [GIVEN] Posted payment "P1" to vendor "V" from bank "X" with amount 100
        // [GIVEN] Payment "P1" reversed
        // [GIVEN] Posted payment "P2" to the vendor "V" from bank "X" with amount 50
        CreatePostTwoPmtWithOneReversed(BankAccountNo, ReversedDocumentNo, DocumentNo, PostingDate);

        // [GIVEN] Bank account reconcilation lines for posted bank account ledger entries created by "P1" and "P2"
        // [GIVEN] "Statement Amount" in lines for P1 = 0;
        // [GIVEN] "Statement Amount" in line for P2 = -50;
        CreateAndSuggestBankReconcltn(BankAccReconciliation, BankAccountNo, PostingDate);
        FindBankAccReconciliationLines(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.SetRange("Document No.", ReversedDocumentNo);
        repeat
            BankAccReconciliationLine.Validate("Statement Amount", 0);
            BankAccReconciliationLine.Modify(true);
        until BankAccReconciliationLine.Next() = 0;
        BankAccReconciliationLine.SetRange("Document No.");
        BankAccReconciliationLine.CalcSums("Statement Amount");
        BankAccReconciliation.Validate("Statement Ending Balance", BankAccReconciliationLine."Statement Amount");
        BankAccReconciliation.Modify(true);
        Commit();

        // [WHEN] Post Bank Account Reconcilation for "X"
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] All Bank Account Ledger Entries of "X" are closed
        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange(Open, true);
        Assert.RecordIsEmpty(BankAccountLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure TwoVoidedVLEAfterVoidCheckOfTwoPmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
        DocumentNo: Code[20];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Vendor] [Payment] [Check] [Void]
        // [SCENARIO 380591] Two voided Vendor Ledger Entries with empty Document Type after Void Check of two payments applied to Invoice and Credit Memo
        Initialize();

        VendorNo := LibraryPurchase.CreateVendorNo();
        BankAccountNo := CreateBankAccount();
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CrMemoAmount := InvoiceAmount - LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Vendor Invoice with Amount = 1000
        CreateAndPostVendorGenJournalLine(GenJournalLine."Document Type"::Invoice, VendorNo, -InvoiceAmount);
        // [GIVEN] Vendor Credit Memo with Amount = 900
        CreateAndPostVendorGenJournalLine(GenJournalLine."Document Type"::"Credit Memo", VendorNo, CrMemoAmount);
        // [GIVEN] Suggest Vendor Payments. Use Bank Account as "Bal. Account Type", "Bank Payment Type" = "Computer Check".
        // [GIVEN] Two payment lines have been suggested: for Invoice (Amount = 1000) and for Credit Memo (Amount = 900).
        CreatePaymentJournal(GenJournalLine);
        SuggestVendorPayments(GenJournalLine, VendorNo, BankAccountNo);
        // [GIVEN] Print Check. New payment line (Computer Check) has been added to the journal with Amount = 100.
        PrintCheck(GenJournalLine, BankAccountNo);
        GenJournalLine.FindFirst();
        DocumentNo := GenJournalLine."Document No.";
        // [GIVEN] Post payment journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Void (Unapply and void check) bank check ledger entry.
        VoidCheck(BankAccountNo, DocumentNo, VoidType::"Unapply and void check");

        // [THEN] Bank check has been voided: "Entry Status" = "Financially Voided", Amount = 100.
        VerifyCheckLedgerEntry(BankAccountNo, DocumentNo, InvoiceAmount - CrMemoAmount);
        // [THEN] Bank account has two ledger entries: "Dcoument Type" = "Payment" with Amount = -100; "Document Type" = "" with Amount = 100.
        VerifyPaymentBankAccLedgerEntry(
          BankAccountNo, GenJournalLine."Posting Date", DocumentNo, -(InvoiceAmount - CrMemoAmount), GetPmtJnlSourceCode());
        VerifyPaymentBankAccLedgerEntry(
          BankAccountNo, WorkDate(), DocumentNo, InvoiceAmount - CrMemoAmount, GetFinVoidedSourceCode());
        // [THEN] There are two voided Vendor Ledger Entries with empty "Document Type" related to Void Check
        VerifyVoidedVendorLedgerEntries(VendorNo, Enum::"Gen. Journal Document Type"::Payment, DocumentNo, 2);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintLCYCheckAppliedToFCYInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Currency: Record Currency;
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccountNo: Code[20];
        InvoiceAmount: Decimal;
        ExchangeRate: array[2] of Decimal;
        StartDate: Date;
    begin
        // [FEATURE] [FCY] [Check]
        // [SCENARIO 215422] Print check at diffent date for invoice posted in FCY.
        Initialize();

        // [GIVEN] Currency "C" having exchange Rate[1] = 2 at Date[1] = 01/01/2017 and Rate[2] = 3 at Date[2] = 01/02/2017
        StartDate := WorkDate();
        ExchangeRate[1] := LibraryRandom.RandDecInRange(30, 40, 2);
        ExchangeRate[2] := LibraryRandom.RandDecInRange(10, 20, 2);
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(StartDate, ExchangeRate[1], 1));
        LibraryERM.CreateExchangeRate(Currency.Code, StartDate + 1, ExchangeRate[2], 1);

        // [GIVEN] Posted vendor invoice with Amount = 100, "Currency Code" = "C" and "Posting Date" = 01/01/2017
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);
        BankAccountNo := CreateBankAccount();
        InvoiceAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", -InvoiceAmount);
        GenJournalLine.Validate("Posting Date", StartDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Suggested vendor payment with amount 300, "Currency Code" = <blank> and "Posting Date" = 01/02/2017 (payment applied to invoice)
        Clear(GenJournalLine);
        CreatePaymentJournal(GenJournalLine);
        GenJournalLine.Validate("Posting Date", StartDate + 1);
        GenJournalLine.Insert();
        SuggestVendorPayments(GenJournalLine, Vendor."No.", BankAccountNo);
        GenJournalLine.SetRange("Account No.", Vendor."No.");
        GenJournalLine.FindFirst();
        GenJournalLine.Validate("Currency Code", '');
        GenJournalLine.Validate(Amount, InvoiceAmount / ExchangeRate[2]);
        GenJournalLine.Modify(true);
        Commit();
        // [WHEN] Print Check
        PrintCheck(GenJournalLine, BankAccountNo);

        // [THEN] Check Ledger Entry created with Amount = 100 * Rate[2] = 300
        Currency.Initialize('');
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.FindFirst();
        CheckLedgerEntry.TestField(Amount, Round(InvoiceAmount / ExchangeRate[2], Currency."Amount Rounding Precision"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReversedBankAccRecLineNotVisibleOnBankAccRecPage()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.Reset();
        BankAccReconciliation.DeleteAll();
        // [SCENARIO 227412] Reversed Bank Account Ledger Entries are not visible on Bank Reconciliation
        Initialize();
        // [GIVEN] Gen Journal Line with Document No = "X" for Bank Account is posted and reversed
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDateFrom(GetLastCompressDateOfBankAccLegdEntry(), 10));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        BankAccountLedgerEntry.SetRange("Bank Account No.", GenJournalLine."Bal. Account No.");
        BankAccountLedgerEntry.FindFirst();
        ReverseBankAccountLedgerEntryNoErr(BankAccountLedgerEntry, GenJournalLine."Document No.");

        // [GIVEN] Second Gen Journal Line with Document No = "Y" for Bank Account is created (not reversed)
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bank Payment Type"::" ", '', GenJournalLine."Bal. Account No.", LibraryRandom.RandDec(100, 2), '');

        // [GIVEN] Bank Account Reconciliation for the Bank Account
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, GenJournalLine."Bal. Account No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);

        // [GIVEN] Bank Account Reconciliation is opened for the Bank Account
        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.BankAccountNo.SetValue(GenJournalLine."Bal. Account No.");
        BankAccReconciliationPage.FILTER.SetFilter("Bank Account No.", GenJournalLine."Bal. Account No.");

        // [THEN] Only not reversed Bank Account Ledger Entry with Document No = "Y" is displayed.
        BankAccReconciliationPage.ApplyBankLedgerEntries.First();
        BankAccReconciliationPage.ApplyBankLedgerEntries."Document No.".AssertEquals(GenJournalLine."Document No.");
        BankAccReconciliationPage.ApplyBankLedgerEntries.Amount.AssertEquals(-GenJournalLine.Amount);
        Assert.IsFalse(BankAccReconciliationPage.ApplyBankLedgerEntries.Next(), '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure RemoveRecordIDToPrintFromCgeckLedgerEntryAfterPostPayment()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [Check] [Record Restriction]
        // [SCENARIO 228089] Check Ledger Entry does not have reference to Gen. Journal Line when payment is posted.
        Initialize();

        VendorNo := LibraryPurchase.CreateVendorNo();
        BankAccountNo := CreateBankAccount();

        // [GIVEN] Posted Invoice "I" for Vendor "V"
        CreateAndPostVendorGenJournalLine(GenJournalLine."Document Type"::Invoice, VendorNo, -LibraryRandom.RandIntInRange(100, 200));
        CreatePaymentJournal(GenJournalLine);

        // [GIVEN] Suggested payment "P" for invoice "I" with type "Computer Check"
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        SuggestVendorPayments(GenJournalLine, VendorNo, BankAccountNo);

        // [GIVEN] Printed check "C" for payment "P"
        PrintCheck(GenJournalLine, BankAccountNo);
        GenJournalLine.FindFirst();

        // [GIVEN] Created "Check Ledger Entry" "ChLE" for check "C" with "Print Gen Jnl Line SystemId" = "P"
        CheckLedgerEntry.SetRange("Print Gen Jnl Line SystemId", GenJournalLine.SystemId);
        Assert.RecordIsNotEmpty(CheckLedgerEntry);

        // [WHEN] Post payment "P"
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] "ChLE"."Record ID To Print" = <blank>
        Assert.RecordIsEmpty(CheckLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('SuggestBankAccReconLinesRPH')]
    [Scope('OnPrem')]
    procedure SuggestBankAccReconLines_UI()
    var
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [UI] [UT] [Report] [Suggest Bank Acc. Recon. Lines]
        // [SCENARIO 235885] REP 1496 "Suggest Bank Acc. Recon. Lines" has request option "Exclude Reversed Entries"
        Initialize();

        LibraryERM.CreateBankAccount(BankAccount);
        Commit();
        REPORT.Run(REPORT::"Suggest Bank Acc. Recon. Lines", true, false, BankAccount);

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), ''); // visible
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), ''); // enabled
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestBankAccReconLines_IncludeReversed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountNo: Code[20];
        ReversedDocumentNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Report] [Suggest Bank Acc. Recon. Lines]
        // [SCENARIO 235885] REP 1496 "Suggest Bank Acc. Recon. Lines" using "Exclude Reversed Entries" = FALSE
        Initialize();

        // [GIVEN] Bank account with 3 ledger entries: two reversed and one normal
        CreatePostTwoPmtWithOneReversed(BankAccountNo, ReversedDocumentNo, DocumentNo, WorkDate());

        // [WHEN] Run REP 1496 "Suggest Bank Acc. Recon. Lines" for the given bank account using "Exclude Reversed Entries" = FALSE
        CreateAndSuggestBankReconcltn(BankAccReconciliation, BankAccountNo, WorkDate());

        // [THEN] Three lines have been suggested
        FindBankAccReconciliationLines(BankAccReconciliationLine, BankAccReconciliation);
        Assert.RecordCount(BankAccReconciliationLine, 3);

        BankAccReconciliationLine.SetRange("Document No.", ReversedDocumentNo);
        Assert.RecordCount(BankAccReconciliationLine, 2);

        BankAccReconciliationLine.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(BankAccReconciliationLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestBankAccReconLines_ExcludeReversed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        ERMReverseBankLedger: Codeunit "ERM Reverse Bank Ledger";
        BankAccountNo: Code[20];
        ReversedDocumentNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Report] [Suggest Bank Acc. Recon. Lines]
        // [SCENARIO 235885] REP 1496 "Suggest Bank Acc. Recon. Lines" using "Exclude Reversed Entries" = TRUE
        Initialize();

        // [GIVEN] Bank account with 3 ledger entries: two reversed and one normal
        CreatePostTwoPmtWithOneReversed(BankAccountNo, ReversedDocumentNo, DocumentNo, WorkDate());

        // [WHEN] Run REP 1496 "Suggest Bank Acc. Recon. Lines" for the given bank account using "Exclude Reversed Entries" = TRUE
        BindSubscription(ERMReverseBankLedger);
        CreateAndSuggestBankReconcltn(BankAccReconciliation, BankAccountNo, WorkDate());

        // [THEN] One line ("normal") has been suggested
        FindBankAccReconciliationLines(BankAccReconciliationLine, BankAccReconciliation);
        Assert.RecordCount(BankAccReconciliationLine, 1);
        BankAccReconciliationLine.TestField("Document No.", DocumentNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reverse Bank Ledger");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reverse Bank Ledger");
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        LibraryERMCountryData.DisableActivateChequeNoOnGeneralLedgerSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        isInitialized := true;
        Commit();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reverse Bank Ledger");
    end;

    local procedure PostPaymentToVendor(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; PostingDate: Date; BankAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendorNo, GenJournalLine."Account Type"::"Bank Account",
          BankAccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyGenJournalLineForBankPaymentType(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]) DocumentNo: Code[20]
    begin
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", AccountType, AccountNo,
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(), -1 * LibraryRandom.RandDec(100, 2), '');
        DocumentNo := GenJournalLine."Document No.";

        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", AccountType, GenJournalLine."Account No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", '', CreateBankAccount(), -1 * GenJournalLine.Amount,
          GenJournalLine."Document No.");
        exit(DocumentNo);
    end;

    local procedure ReversAndCompressBankReconcltn(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        CreateAndPostGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ", AccountType, AccountNo,
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(), LibraryRandom.RandDec(100, 2), '');

        CreateAndSuggestBankReconcltn(BankAccReconciliation, GenJournalLine."Bal. Account No.", GenJournalLine."Posting Date");
        ModifyBankReconcltn(BankAccReconciliation);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        DateCompressBankLedgerEntry(GenJournalLine."Posting Date", GenJournalLine."Document No.");
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; CurrencyCode: Code[10]; BalAccountNo: Code[20]; LineAmount: Decimal; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", BalAccountNo, LineAmount);
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(true));
        // Get Posting Date for Closed Financial Year.
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; CurrencyCode: Code[10]; BalAccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    begin
        CreateGenJournalLine(
          GenJournalLine, DocumentType, AccountType, AccountNo, BankPaymentType, CurrencyCode, BalAccountNo, Amount, AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostVendorGenJournalLine(DocumentType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::Vendor, AccountNo,
          GenJournalLine."Bank Payment Type"::" ", '', LibraryERM.CreateBankAccountNo(), Amount, '');
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(10)));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateAndSuggestBankReconcltn(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; StatementDate: Date)
    begin
        // Take Random Statement No. Value.
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", StatementDate);
        BankAccReconciliation.Modify(true);
        SuggestBankReconcltn(BankAccReconciliation);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreatePaymentJournalTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreatePaymentJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, CreatePaymentJournalTemplate());
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
    end;

    local procedure CreatePostTwoPmtWithOneReversed(var BankAccountNo: Code[20]; var ReversedDocumentNo: Code[20]; var DocumentNo: Code[20]; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        VendorNo: Code[20];
    begin
        BankAccountNo := CreateBankAccount();
        VendorNo := LibraryPurchase.CreateVendorNo();

        PostPaymentToVendor(GenJournalLine, VendorNo, PostingDate, BankAccountNo);
        ReversedDocumentNo := GenJournalLine."Document No.";
        ReverseBankAccountLedgerEntryNoErr(BankAccountLedgerEntry, ReversedDocumentNo);

        PostPaymentToVendor(GenJournalLine, VendorNo, PostingDate, BankAccountNo);
        DocumentNo := GenJournalLine."Document No.";
    end;

    local procedure DateCompressBankLedgerEntry(PostingDate: Date; DocumentNo: Code[20])
    var
        DateComprRegister: Record "Date Compr. Register";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressBankAccLedger: Report "Date Compress Bank Acc. Ledger";
    begin
        // Run Date Compress VAT Entry Report with a closed Accounting Period.
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        DateCompressBankAccLedger.SetTableView(BankAccountLedgerEntry);
        DateComprRetainFields."Retain Document No." := true;
        DateComprRetainFields."Retain Contact Code" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressBankAccLedger.InitializeRequest(
          PostingDate, PostingDate, DateComprRegister."Period Length"::Day, DocumentNo, DateComprRetainFields, '', false);
        DateCompressBankAccLedger.UseRequestPage(false);
        DateCompressBankAccLedger.Run();
    end;

    local procedure FindBankAccReconciliationLines(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        BankAccReconciliationLine.LinesExist(BankAccReconciliation);
    end;

    local procedure FindBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; BankAccountNo: Code[20]; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Posting Date", PostingDate);
        BankAccountLedgerEntry.SetRange("Document Type", DocumentType);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst();
    end;

    local procedure FindBankCheckLedgerEntry(var CheckLedgerEntry: Record "Check Ledger Entry"; BankAccountNo: Code[20]; DocumentNo: Code[20])
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
    end;

    local procedure GetBankAccountLastCheckNo(BankAccountNo: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        exit(BankAccount."Last Check No.");
    end;

    local procedure GetGenJnlSourceCode(): Code[10]
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        exit(SourceCodeSetup."General Journal");
    end;

    local procedure GetPmtJnlSourceCode(): Code[10]
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        exit(SourceCodeSetup."Payment Journal");
    end;

    local procedure GetFinVoidedSourceCode(): Code[10]
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        exit(SourceCodeSetup."Financially Voided Check");
    end;

    local procedure GetLastCompressDateOfBankAccLegdEntry(): Date
    var
        DateComprRegister: Record "Date Compr. Register";
    begin
        DateComprRegister.SetCurrentKey("Table ID", "Ending Date");
        DateComprRegister.SetRange("Table ID", DATABASE::"Bank Account Ledger Entry");
        if DateComprRegister.FindLast() then
            exit(DateComprRegister."Ending Date");
        exit(WorkDate());
    end;

    local procedure ModifyCurrencyAndExchangeRate("Code": Code[10]): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(Code);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        ModifyExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure ModifyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst(); // Modify Relational Exch. Rate with Less Random Amount.
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" - LibraryRandom.RandInt(10));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure ModifyBankReconcltn(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        FindBankAccReconciliationLines(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.CalcSums("Statement Amount");
        BankAccReconciliation.Validate("Statement Ending Balance", BankAccReconciliationLine."Statement Amount");
        BankAccReconciliation.Modify(true);
    end;

    local procedure BlockBankAccount(No: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(No);
        BankAccount.Validate(Blocked, true);
        BankAccount.Modify(true);
    end;

    local procedure ReverseBankAccountLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; DocumentNo: Code[20])
    begin
        asserterror ReverseBankAccountLedgerEntryNoErr(BankAccountLedgerEntry, DocumentNo);
    end;

    local procedure ReverseBankAccountLedgerEntryNoErr(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; DocumentNo: Code[20])
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(BankAccountLedgerEntry."Transaction No.");
        BankAccountLedgerEntry.Find();
    end;

    local procedure ReverseCustomerLedgerEntry(DocumentNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure ReverseVendorLedgerEntry(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ReversalEntry: Record "Reversal Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(VendorLedgerEntry."Transaction No.");
    end;

    local procedure SuggestBankReconcltn(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.InitializeRequest(BankAccReconciliation."Statement Date", BankAccReconciliation."Statement Date", false);
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.Run();
    end;

    local procedure SuggestVendorPayments(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        Clear(SuggestVendorPayments);
        Vendor.SetRange("No.", VendorNo);
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.InitializeRequest(
          CalcDate('<2M>', WorkDate()), false, 0, false, CalcDate('<2M>', WorkDate()), LibraryUtility.GenerateGUID(), false,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo, GenJournalLine."Bank Payment Type"::"Computer Check");
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.RunModal();
    end;

    local procedure PrintCheck(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20])
    var
        Check: Report Check;
    begin
        Clear(Check);
        Check.SetTableView(GenJournalLine);
        Check.InitializeRequest(BankAccountNo, GetBankAccountLastCheckNo(BankAccountNo), true, false, false, false);
        Check.UseRequestPage(false);
        Check.SaveAsXml(LibraryReportDataset.GetParametersFileName());
    end;

    local procedure VoidCheck(BankAccountNo: Code[20]; DocumentNo: Code[20]; NewVoidType: Option)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckManagement: Codeunit CheckManagement;
    begin
        LibraryVariableStorage.Enqueue(NewVoidType);
        FindBankCheckLedgerEntry(CheckLedgerEntry, BankAccountNo, DocumentNo);
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
    end;

    local procedure VerifyPaymentBankAccLedgerEntry(BankAccountNo: Code[20]; PostingDate: Date; DocumentNo: Code[20]; ExpectedAmount: Decimal; ExpectedSourceCode: Code[10])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        FindBankAccountLedgerEntry(BankAccountLedgerEntry, BankAccountNo, PostingDate, BankAccountLedgerEntry."Document Type"::Payment, DocumentNo);
        Assert.AreEqual(ExpectedAmount, BankAccountLedgerEntry.Amount, BankAccountLedgerEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedSourceCode, BankAccountLedgerEntry."Source Code", BankAccountLedgerEntry.FieldCaption("Source Code"));
    end;

    local procedure VerifyRefundBankAccLedgerEntry(BankAccountNo: Code[20]; PostingDate: Date; DocumentNo: Code[20]; ExpectedAmount: Decimal; ExpectedSourceCode: Code[10])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        FindBankAccountLedgerEntry(BankAccountLedgerEntry, BankAccountNo, PostingDate, BankAccountLedgerEntry."Document Type"::Refund, DocumentNo);
        Assert.AreEqual(ExpectedAmount, BankAccountLedgerEntry.Amount, BankAccountLedgerEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedSourceCode, BankAccountLedgerEntry."Source Code", BankAccountLedgerEntry.FieldCaption("Source Code"));
    end;

    local procedure VerifyCheckLedgerEntry(BankAccountNo: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        FindBankCheckLedgerEntry(CheckLedgerEntry, BankAccountNo, DocumentNo);
        CheckLedgerEntry.TestField(Amount, ExpectedAmount);
        CheckLedgerEntry.TestField("Entry Status", CheckLedgerEntry."Entry Status"::"Financially Voided");
        CheckLedgerEntry.TestField("Original Entry Status", CheckLedgerEntry."Original Entry Status"::Posted);
    end;

    local procedure VerifyVoidedVendorLedgerEntries(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        DummyVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        DummyVendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        DummyVendorLedgerEntry.SetRange("Posting Date", WorkDate());
        DummyVendorLedgerEntry.SetRange("Document Type", DocumentType);
        DummyVendorLedgerEntry.SetRange("Document No.", DocumentNo);
        DummyVendorLedgerEntry.SetRange("Source Code", GetFinVoidedSourceCode());
        Assert.RecordCount(DummyVendorLedgerEntry, ExpectedCount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VoidCheckPageHandler(var ConfirmFinancialVoid: Page "Confirm Financial Void"; var Response: Action)
    begin
        ConfirmFinancialVoid.InitializeRequest(WorkDate(), LibraryVariableStorage.DequeueInteger());
        Response := ACTION::Yes;
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestBankAccReconLinesRPH(var SuggestBankAccReconLines: TestRequestPage "Suggest Bank Acc. Recon. Lines")
    begin
        LibraryVariableStorage.Enqueue(SuggestBankAccReconLines.ExcludeReversedEntries.Visible());
        LibraryVariableStorage.Enqueue(SuggestBankAccReconLines.ExcludeReversedEntries.Enabled());
        SuggestBankAccReconLines.Cancel().Invoke();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Suggest Bank Acc. Recon. Lines", 'OnPreDataItemBankAccount', '', false, false)]
    local procedure SuggestBankAccRecLinesOnPreDataItem(var ExcludeReversedEntries: Boolean)
    begin
        ExcludeReversedEntries := true;
    end;
}
