codeunit 134131 "ERM Reverse GL Entries"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        IsInitialized: Boolean;
        OutOfBalanceError: Label 'You cannot reverse the transaction because it is out of balance.';
        ReversalErrorForInvoice: Label 'You can only reverse entries that were posted from a journal.';
        ErrorsMustMatch: Label 'Errors must match.';
        ReversalErrorForPeriod: Label 'You cannot reverse %1 No. %2 because the posting date is not within the allowed posting period.';
        DateCompressError: Label 'The transaction cannot be reversed, because the %1 has been compressed or a %2 has been deleted.';
        UnApplyAndVoidCheckErr: Label 'Cannot find an applied entry within the specified filter.';
        GLEntryVATEntryLinkErr: Label 'Wrong G/L Entry - VAT Entry Link reversal.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseGLEntryVATEntryLink()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
    begin
        Initialize();
        // [GIVEN] Posted Gen. Jnl. Line with VAT. G/L Entry - VAT Entry Link entry exists.
        CreateGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Invoice);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // [WHEN] Reverse posted transaction.
        LibraryLowerPermissions.AddAccountReceivables();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(GetGLEntryTransactionNo(GenJournalLine."Document No.", GenJournalLine."Account No."));

        // [THEN] G/L Entry - VAT Entry Link entry exists for reversed entries.
        VerifyGLEntryVATEntryLinkReversed(GenJournalLine."Document No.", GenJournalLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseForceDocBalanceNo()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        ForceDocBalance: Boolean;
        GLAccountNo: Code[20];
    begin
        // Update "Force Doc. Balance" in Geneal Journal Template and Post General Journal Line for G/L Account.
        // Check Reversal Error for out of Balance Account.

        // Setup: Set "Force Doc. Balance" value FALSE in Geneal Journal Template, Create and Post General Journal Line with
        // blank Balancing Account.
        Initialize();
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        ForceDocBalance := UpdateGenJournalTemplate(GenJournalBatch."Journal Template Name", false);
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGenJournalLineDocNo(
          GenJournalLine, GenJournalBatch, GLAccountNo, GenJournalLine."Document No.", LibraryRandom.RandInt(100));
        CreateGenJournalLineDocNo(
          GenJournalLine, GenJournalBatch, GLAccountNo, IncStr(GenJournalLine."Document No."), -GenJournalLine.Amount);
        UpdateBalanceAccount(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Reverse Posted Entry from G/L Entry.
        LibraryLowerPermissions.AddAccountReceivables();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(GetGLEntryTransactionNo(GenJournalLine."Document No.", GLAccountNo));

        // Verify: Verify Out of Balance Error Message.
        Assert.AreEqual(StrSubstNo(OutOfBalanceError), GetLastErrorText, ErrorsMustMatch);

        // Tear Down: Rollback setup Data.
        UpdateGenJournalTemplate(GenJournalBatch."Journal Template Name", ForceDocBalance);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseBlockedGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Reversal Error after posting Payment from General Journal Line for G/L Account and Blocking G/L Account.

        // Setup: Find a GL Account. Post Payment entry from General Journal Line. Block Account after Posting.
        Initialize();
        CreateGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        BlockGLAccount(GenJournalLine."Account No.", true);

        // Reverse Posted Transaction from G/L Entry and Verify Error message.
        LibraryLowerPermissions.AddAccountReceivables();
        ReverseAccountAndVerifyMsg(GenJournalLine."Account No.", GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseBlockedBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Make and Post General Journal entry for G/L Account also use G/L Account in Balancing Account field.
        // Block G/L Account that is use as Balancing Account and Verify Reversal Error.

        // Setup: Make Payment entry for G/L Account and added G/L Account in Balancing Account. Post General Journal and
        // Blocked the Account that is used as Balancing Account.
        Initialize();
        CreateGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        BlockGLAccount(GenJournalLine."Bal. Account No.", true);

        // Reverse Posted Transaction from G/L Entry and Verify Error message.
        LibraryLowerPermissions.AddAccountReceivables();
        ReverseAccountAndVerifyMsg(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseSalesInvoiceTransaction()
    var
        ReversalEntry: Record "Reversal Entry";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // Create and Post Sales Invoice and and Blocked Sales Account. Verify Reversal Error Message from G/L Entry.

        // Setup: Create a Sales Invoice and Post. Find Sales Account from General Posting Setup and set Block the account.
        Initialize();
        DocumentNo := ReverseSalesEntrySetup(GLAccountNo);

        // Exercise: Reverse Posted Entry from G/L Entry.
        LibraryLowerPermissions.AddAccountReceivables();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(GetGLEntryTransactionNo(DocumentNo, GLAccountNo));

        // Verify: Verify Blocked Error Message.
        Assert.AreEqual(StrSubstNo(ReversalErrorForInvoice), GetLastErrorText, ErrorsMustMatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseSalesEntryFromRegister()
    var
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        GLAccountNo: Code[20];
    begin
        // Create and Post Sales Invoice and and Blocked Sales Account. Verify Reversal Error Message from G/L Register.

        // Setup: Create a Sales Invoice and Post. Find Sales Account from General Posting Setup and set Block the account.
        Initialize();
        ReverseSalesEntrySetup(GLAccountNo);

        // Exercise: Reverse Posted Entry from G/L Register.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verify Blocked Error Message.
        Assert.AreEqual(StrSubstNo(ReversalErrorForInvoice), GetLastErrorText, ErrorsMustMatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReversePurchInvoiceTransaction()
    var
        ReversalEntry: Record "Reversal Entry";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // Setup: Create a Purchase Invoice and Post. Find Purchase Account from General Posting Setup and set Block the account.
        Initialize();
        DocumentNo := ReversePurchEntrySetup(GLAccountNo);

        // Exercise: Reverse Posted Entry from G/L Entry.
        LibraryLowerPermissions.AddAccountReceivables();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(GetGLEntryTransactionNo(DocumentNo, GLAccountNo));

        // Verify: Verify Blocked Error Message.
        Assert.AreEqual(StrSubstNo(ReversalErrorForInvoice), GetLastErrorText, ErrorsMustMatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReversePurchEntryFromRegister()
    var
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        GLAccountNo: Code[20];
    begin
        // Setup: Create a Purchase Invoice and Post. Find Purchase Account from General Posting Setup and set Block the account.
        Initialize();
        ReversePurchEntrySetup(GLAccountNo);

        // Exercise: Reverse Posted Entry from G/L Register.
        LibraryLowerPermissions.AddAccountReceivables();
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify: Verify Blocked Error Message.
        Assert.AreEqual(StrSubstNo(ReversalErrorForInvoice), GetLastErrorText, ErrorsMustMatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BeforeAllowPeriodTransaction()
    begin
        // Create and Post Payment Entry form General Journal Line before Allow Period Date Range, update General Ledger Setup
        // Allow Period. Reverse and Verify Error for before allow Period Date transaction from GL Entry.
        Initialize();

        LibraryLowerPermissions.AddAccountReceivables();
        AllowPeriodTransaction(CalcDate('<-1D>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AfterAllowPeriodTransaction()
    begin
        // Create and Post Payment Entry form General Journal Line after Allow Period Date Range, update General Ledger Setup
        // Allow Period. Reverse and Verify Error for before allow Period Date transaction from GL Entry.
        Initialize();
        LibraryLowerPermissions.AddAccountReceivables();
        AllowPeriodTransaction(CalcDate('<1D>', WorkDate()));
    end;

    local procedure AllowPeriodTransaction(PostingDate: Date)
    var
        ReversalEntry: Record "Reversal Entry";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // Setup: Create Genenral Journal Line and Post. Update Allow Period field in General Ledger Setup.
        Initialize();
        DocumentNo := ReverseAllowPeriodSetup(GLAccountNo, AllowPostingFrom, AllowPostingTo, PostingDate);

        // Exercise: Reverse Posted Entry from G/L Entry.
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(GetGLEntryTransactionNo(DocumentNo, GLAccountNo));

        // Verify Period Error Message and Tear Down.
        VerifyAllowedPeriodAndCleanup(DocumentNo, GLAccountNo, AllowPostingFrom, AllowPostingTo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BeforeAllowPeriodFromRegister()
    begin
        // Create and Post Payment Entry form General Journal Line before Allow Period Date Range, update General Ledger Setup
        // Allow Period. Reverse and Verify Error for before allow Period Date transaction from GL Register.
        Initialize();
        LibraryLowerPermissions.AddAccountReceivables();
        AllowPeriodFromRegister(CalcDate('<-1D>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AfterAllowPeriodFromRegister()
    begin
        // Create and Post Payment Entry form General Journal Line after Allow Period Date Range, update General Ledger Setup
        // Allow Period. Reverse and Verify Error for before allow Period Date transaction from GL Register.
        Initialize();
        AllowPeriodFromRegister(CalcDate('<1D>', WorkDate()));
    end;

    local procedure AllowPeriodFromRegister(PostingDate: Date)
    var
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // Setup: Create Genenral Journal Line and Post. Update Allow Period field in General Ledger Setup.
        Initialize();
        DocumentNo := ReverseAllowPeriodSetup(GLAccountNo, AllowPostingFrom, AllowPostingTo, PostingDate);

        // Exercise: Reverse Posted Entry from G/L Register.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseRegister(GLRegister."No.");

        // Verify Period Error Message and Tear Down.
        VerifyAllowedPeriodAndCleanup(DocumentNo, GLAccountNo, AllowPostingFrom, AllowPostingTo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseCompressGLEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
        SaveWorkDate: Date;
    begin
        // Test Date Compress G/L Entries
        // Setup: Create and Post Line for Customer, Vendor, Bank and Fixed Asset from General Journal Line, Run Date Compress batch job.
        Initialize();
        SaveWorkDate := WorkDate();
        WorkDate(LibraryFiscalYear.GetFirstPostingDate(true));

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), -LibraryRandom.RandInt(100));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(), LibraryRandom.RandInt(100));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Bank Account",
          FindBankAccount(), LibraryRandom.RandInt(100));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Fixed Asset",
          FindFixedAsset(), LibraryRandom.RandInt(100));
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::Maintenance);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DateCompressForGLEntries(GenJournalLine."Document No.");
        WorkDate(SaveWorkDate);

        // Exercise: Reverse Posted Entry from G/L Register.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseRegister(GLRegister."No." - 1);

        // Verify: Verify Blocked Error Message for Date Compress Entries.
        Assert.AreEqual(StrSubstNo(DateCompressError, GLEntry.TableCaption(), GLAccount.TableCaption()), GetLastErrorText, ErrorsMustMatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseCompressCustomerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
        SaveWorkDate: Date;
    begin
        // Setup: Create and Post Line for Customer from General Journal Line, Run Date Compress batch job.
        Initialize();
        SaveWorkDate := WorkDate();
        WorkDate(LibraryFiscalYear.GetFirstPostingDate(true));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), -LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DateCompressForGLEntries(GenJournalLine."Document No.");
        WorkDate(SaveWorkDate);

        // Exercise: Reverse Posted Entry from Customer Ledger Entry.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::" ", GenJournalLine."Document No.");
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // Verify: Verify Blocked Error Message for Date Compress Entry.
        Assert.AreEqual(StrSubstNo(DateCompressError, GLEntry.TableCaption(), GLAccount.TableCaption()), GetLastErrorText, ErrorsMustMatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseCompressVendorEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SaveWorkDate: Date;
    begin
        // Setup: Create and Post Line for Vendor from General Journal Line, Run Date Compress batch job.
        Initialize();
        SaveWorkDate := WorkDate();
        WorkDate(LibraryFiscalYear.GetFirstPostingDate(true));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(), LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DateCompressForGLEntries(GenJournalLine."Document No.");
        WorkDate(SaveWorkDate);

        // Exercise: Reverse Posted Entry from Vendor Ledger Entry.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::" ", GenJournalLine."Document No.");
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(VendorLedgerEntry."Transaction No.");

        // Verify: Verify Blocked Error Message for Date Compress Entry.
        Assert.AreEqual(StrSubstNo(DateCompressError, GLEntry.TableCaption(), GLAccount.TableCaption()), GetLastErrorText, ErrorsMustMatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseCompressBankEntries()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
        SaveWorkDate: Date;
    begin
        // Setup: Create and Post Line for Bank Account from General Journal Line, Run Date Compress batch job.
        Initialize();
        SaveWorkDate := WorkDate();
        WorkDate(LibraryFiscalYear.GetFirstPostingDate(true));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Bank Account",
          FindBankAccount(), LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DateCompressForGLEntries(GenJournalLine."Document No.");
        WorkDate(SaveWorkDate);

        // Exercise: Reverse Posted Entry from Bank Ledger Entry.
        BankAccountLedgerEntry.SetRange("Bank Account No.", GenJournalLine."Account No.");
        BankAccountLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        BankAccountLedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(BankAccountLedgerEntry."Transaction No.");

        // Verify: Verify Blocked Error Message for Date Compress Entry.
        Assert.AreEqual(StrSubstNo(DateCompressError, GLEntry.TableCaption(), GLAccount.TableCaption()), GetLastErrorText, ErrorsMustMatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReverseCompressFAEntries()
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ReversalEntry: Record "Reversal Entry";
        SaveWorkDate: Date;
    begin
        // Setup: Create and Post Line for Fixed Asset from General Journal Line, Run Date Compress batch job.
        Initialize();
        SaveWorkDate := WorkDate();
        WorkDate(LibraryFiscalYear.GetFirstPostingDate(true));
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Fixed Asset",
          FindFixedAsset(), LibraryRandom.RandInt(100));
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::Maintenance);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DateCompressForGLEntries(GenJournalLine."Document No.");
        WorkDate(SaveWorkDate);

        // Exercise: Reverse Posted Entry from Maintenance Ledger Entry.
        MaintenanceLedgerEntry.SetRange("FA No.", GenJournalLine."Account No.");
        MaintenanceLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        MaintenanceLedgerEntry.FindFirst();
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(MaintenanceLedgerEntry."Transaction No.");

        // Verify: Verify Blocked Error Message for Date Compress Entry.
        Assert.AreEqual(StrSubstNo(DateCompressError, GLEntry.TableCaption(), GLAccount.TableCaption()), GetLastErrorText, ErrorsMustMatch);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyAndVoidCheckForAppliedVendorEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // Verify the check ledger entry when we unapply and apply the vendor ledger entries with Unapply and void check value.

        // Setup: Create and post invoice and payment for vendor and then unapply and apply vendor ledger entries.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(''), -LibraryRandom.RandDecInRange(100, 200, 2), '');
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJournalLineWithAppliesToDoc(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Applies-to Doc. Type"::Invoice, GenJournalLine."Account Type"::Vendor, DocumentNo);
        UnApplyVendorLedgerEntries(GenJournalLine."Document Type", GenJournalLine."Document No.");
        ApplyingAndPostApplicationForVendorLedgerEntry(GenJournalLine, DocumentNo);
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");

        // Exercise: Unapply and void check the check ledger entry.
        VoidCheck(GenJournalLine."Document No.");

        // Verify: Verifying the Entry Status Financially Voided on Check Ledger Entry.
        VerifyCheckLedgerEntry(GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyAndVoidCheckForAppliedCustomerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VoidType: Option "Unapply and void check","Void check only";
        DocumentNo: Code[20];
    begin
        // Verify the check ledger entry when we unapply and apply the customer ledger entries with Unapply and void check value.

        // Setup: Create and post credit memo and refund for customer and then Unapply and apply customer ledger entries
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(''), -LibraryRandom.RandDecInRange(100, 200, 2), '');
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJournalLineWithAppliesToDoc(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, GenJournalLine."Applies-to Doc. Type"::"Credit Memo", DocumentNo);
        UnApplyCustomerLedgerEntries(GenJournalLine."Document Type", GenJournalLine."Document No.");
        ApplyingAndPostApplicationForCustomerLedgerEntry(GenJournalLine, DocumentNo);
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");

        // Exercise: Unapply and void check the check ledger entry.
        VoidCheck(GenJournalLine."Document No.");

        // Verify: Verifying the Entry Status Financially Voided on Check Ledger Entry.
        VerifyCheckLedgerEntry(GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyAndVoidCheckForAppliedEmployeeEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // Verify the check ledger entry when we unapply and apply the employee ledger entries with Unapply and void check value.

        // Setup: Create and post invoice and payment for employee and then unapply and apply vendor ledger entries.
        Initialize();

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Employee, LibraryHumanResource.CreateEmployeeNoWithBankAccount(),
          GenJournalLine."Bank Payment Type"::"Computer Check", '', CreateBankAccount(''),
          LibraryRandom.RandDecInRange(100, 200, 2), '');
        GenJournalLine."Check Printed" := true;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine.Modify();
        Commit();

        CreateCheckLedgerForEmployee(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJournalLineWithAppliesToDoc(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Employee, GenJournalLine."Applies-to Doc. Type"::Payment, DocumentNo);
        UnApplyEmployeeLedgerEntries(GenJournalLine."Document Type", GenJournalLine."Document No.");
        ApplyingAndPostApplicationForEmployeeLedgerEntry(GenJournalLine, DocumentNo);
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");

        // Exercise: Unapply and void check the check ledger entry.
        VoidCheck(DocumentNo);// GenJournalLine."Document No.");

        // Verify: Verifying the Entry Status Financially Voided on Check Ledger Entry.
        VerifyCheckLedgerEntry(DocumentNo);// GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyAndVoidCheckForUnAppliedVendorEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // Verify the error message when we void check with option Unapply and void check value in case of vendor

        // Setup: Create and post invoice and payment for vendor and then unapply ledger entries.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(''), -LibraryRandom.RandDecInRange(100, 200, 2), '');
        CreateAndPostGenJournalLineWithAppliesToDoc(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Applies-to Doc. Type"::Invoice, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document No.");
        UnApplyVendorLedgerEntries(GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");

        // Exercise: Unapply and void check the check ledger entry.
        asserterror VoidCheck(GenJournalLine."Document No.");

        // Verify: Verifying error message.
        Assert.ExpectedError(UnApplyAndVoidCheckErr);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyAndVoidCheckForUnAppliedCustomerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // Verify the error message when we void check with option Unapply and void check value in case of customer.

        // Setup: Create and post credit memo and refund for customer and then Unapply customer ledger entries.
        Initialize();
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJournalLine."Bank Payment Type"::" ", '', CreateBankAccount(''), -LibraryRandom.RandDecInRange(100, 200, 2), '');
        CreateAndPostGenJournalLineWithAppliesToDoc(GenJournalLine, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, GenJournalLine."Applies-to Doc. Type"::"Credit Memo", GenJournalLine."Document No.");
        UnApplyCustomerLedgerEntries(GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");

        // Exercise: Unapply and void check the check ledger entry.
        asserterror VoidCheck(GenJournalLine."Document No.");

        // Verify: Verifying error message.
        Assert.ExpectedError(UnApplyAndVoidCheckErr);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyAndVoidCheckForUnAppliedEmployeeEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        VoidType: Option "Unapply and void check","Void check only";
    begin
        // Verify the error message when we void check with option Unapply and void check value in case of employee
        Initialize();

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Employee, LibraryHumanResource.CreateEmployeeNoWithBankAccount(),
          GenJournalLine."Bank Payment Type"::"Computer Check", '', CreateBankAccount(''),
          LibraryRandom.RandDecInRange(100, 200, 2), '');
        GenJournalLine."Check Printed" := true;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine.Modify();
        Commit();

        CreateCheckLedgerForEmployee(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJournalLineWithAppliesToDoc(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Employee, GenJournalLine."Applies-to Doc. Type"::Payment, DocumentNo);
        UnApplyEmployeeLedgerEntries(GenJournalLine."Document Type", GenJournalLine."Document No.");
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");

        // Exercise: Unapply and void check the check ledger entry.
        asserterror VoidCheck(DocumentNo);// GenJournalLine."Document No.");

        // Verify: Verifying error message.
        Assert.ExpectedError(UnApplyAndVoidCheckErr);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyAndVoidCheckForAppliedVendorEntriesWithGainLossAndDimensions()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        PaymentDate: Date;
        VoidType: Option "Unapply and void check","Void check only";
        DimSetID: Integer;
    begin
        // [FEATURE] [Purchase] [FCY]
        // [SCENARIO 213654] Void check of vendor payment applied to purchase invoice with gain/losses and dimensions
        Initialize();

        // [GIVEN] Currency Code with exchange rates on 01 jan and 01 feb
        PaymentDate := LibraryRandom.RandDate(5);
        CurrencyCode := CreateCurrencyWithExchRates(LibraryFiscalYear.GetFirstPostingDate(true), PaymentDate);

        // [GIVEN] Dimension with DimSetID = 123 assigned as default to Vendor
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimSetID := LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Purchase Invoice in FCY is posted on 01 jan for the Vendor
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithDefDim(DimensionValue),
          GenJournalLine."Bank Payment Type"::" ", CurrencyCode, CreateBankAccount(CurrencyCode),
          -LibraryRandom.RandDecInRange(100, 200, 2), '');
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] FCY Purchase Payment with manual check is posted and applied on 02 jan
        CreateAndPostApplyGenJournalLineWithPostingDate(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Applies-to Doc. Type"::Invoice, DocumentNo, CurrencyCode, PaymentDate);

        // [WHEN] Unapply and void check the check ledger entry
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");
        VoidCheck(GenJournalLine."Document No.");

        // [THEN] Dimension Set ID = 123 in all payment G/L Entries for gain/losses
        VerifyGLEntryDimSetID(GenJournalLine."Document No.", CurrencyCode, DimSetID);
    end;

    [Test]
    [HandlerFunctions('VoidCheckPageHandler')]
    [Scope('OnPrem')]
    procedure UnApplyAndVoidCheckForAppliedustomerEntriesWithGainLossAndDimensions()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        PaymentDate: Date;
        VoidType: Option "Unapply and void check","Void check only";
        DimSetID: Integer;
    begin
        // [FEATURE] [Sales] [FCY]
        // [SCENARIO 213654] Void check of customer refund applied to sales credit memo with gain/losses and dimensions
        Initialize();

        // [GIVEN] Currency Code with exchange rates on 01 jan and 01 feb
        PaymentDate := LibraryRandom.RandDate(5);
        CurrencyCode := CreateCurrencyWithExchRates(LibraryFiscalYear.GetFirstPostingDate(true), PaymentDate);

        // [GIVEN] Dimension with DimSetID = 123 assigned as default to Customer
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimSetID := LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code);

        // [GIVEN] Sales Credit Memo in FCY is posted on 01 jan for the Customer
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, CreateCustomerWithDefDim(DimensionValue),
          GenJournalLine."Bank Payment Type"::" ", CurrencyCode, CreateBankAccount(CurrencyCode),
          -LibraryRandom.RandDecInRange(100, 200, 2), '');
        DocumentNo := GenJournalLine."Document No.";

        // [GIVEN] FCY Sales Refund with manual check is posted and applied on 02 jan
        CreateAndPostApplyGenJournalLineWithPostingDate(
          GenJournalLine, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::"Credit Memo", DocumentNo, CurrencyCode, PaymentDate);

        // [WHEN] Unapply and void check the check ledger entry
        LibraryVariableStorage.Enqueue(VoidType::"Unapply and void check");
        VoidCheck(GenJournalLine."Document No.");

        // [THEN] Dimension Set ID = 123 in all payment G/L Entries for gain/losses
        VerifyGLEntryDimSetID(GenJournalLine."Document No.", CurrencyCode, DimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VoidCheckForVendorPayments()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Verify that void checks clears Document No and Document Date

        // [GIVEN] Create a Payment Ledger entry and Check Entry ledger
        Initialize();
        CreatePaymentLedgerEntryWithCheckEntry(GenJournalBatch);

        // [WHEN] Void check ledger entry.
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal."Void Check".Invoke();

        // [THEN] Document No and Document Date are cleared
        VerifyDocNoAndDocDateAreEmpty(GenJournalBatch, PaymentJournal);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseGLRegisterEnabled()
    var
        GLRegister: Record "G/L Register";
        GLRegisters: TestPage "G/L Registers";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 342488] Action "Reverse Register" enabled for register from posted G/L journal line
        Initialize();

        // [GIVEN] G/L register entry from posted G/L journal line
        PrepareGLRegisterEntry(GLRegister);

        // [WHEN] Open G/L Registers page and locate on register XXX
        GLRegisters.OpenView();
        GLRegisters.Filter.SetFilter("No.", format(GLRegister."No."));

        // [THEN] Action "Reverse Register" is enabled
        Assert.IsTrue(GLRegisters.ReverseRegister.Enabled(), 'Reverse Register must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseGLRegisterDisabledForReversedRegister()
    var
        GLRegister: Record "G/L Register";
        GLRegisters: TestPage "G/L Registers";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 342488] Action "Reverse Register" disabled when register already reversed
        Initialize();

        // [GIVEN] G/L register entry XXX with Reversed = true
        PrepareGLRegisterEntry(GLRegister);
        GLRegister.Reversed := true;
        GLRegister.Modify();

        // [WHEN] Open G/L Registers page and locate on register XXX
        GLRegisters.OpenView();
        GLRegisters.Filter.SetFilter("No.", format(GLRegister."No."));

        // [THEN] Action "Reverse Register" is disabled
        Assert.IsFalse(GLRegisters.ReverseRegister.Enabled(), 'Reverse Register must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseGLRegisterDisabledForEmptyBatchName()
    var
        GLRegister: Record "G/L Register";
        GLRegisters: TestPage "G/L Registers";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 342488] Action "Reverse Register" disabled when "Journal Batch Name" is empty
        Initialize();

        // [GIVEN] G/L register entry XXX with empty "Journal Batch Name" 
        PrepareGLRegisterEntry(GLRegister);
        GLRegister."Journal Batch Name" := '';
        GLRegister.Modify();

        // [WHEN] Open G/L Registers page and locate on register XXX
        GLRegisters.OpenView();
        GLRegisters.Filter.SetFilter("No.", format(GLRegister."No."));

        // [THEN] Action "Reverse Register" is disabled
        Assert.IsFalse(GLRegisters.ReverseRegister.Enabled(), 'Reverse Register must be disabled');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reverse GL Entries");
        // Lazy Setup.
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reverse GL Entries");
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reverse GL Entries");
    end;

    local procedure ApplyingAndPostApplicationForCustomerLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::" ", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type"::"Credit Memo", DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
        CustLedgerEntry.Modify(true);

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyingAndPostApplicationForVendorLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
        VendorLedgerEntry.Modify(true);

        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure ApplyingAndPostApplicationForEmployeeLedgerEntry(GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, GenJournalLine."Document Type"::" ", GenJournalLine."Document No.");
        EmployeeLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyEmployeeEntry(EmployeeLedgerEntry, EmployeeLedgerEntry."Remaining Amount");

        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, GenJournalLine."Document Type"::Payment, DocumentNo);
        EmployeeLedgerEntry.CalcFields("Remaining Amount");
        EmployeeLedgerEntry.Validate("Amount to Apply", EmployeeLedgerEntry."Remaining Amount");
        EmployeeLedgerEntry.Modify(true);

        LibraryERM.SetAppliestoIdEmployee(EmployeeLedgerEntry);
        LibraryERM.PostEmplLedgerApplication(EmployeeLedgerEntry);
    end;

    local procedure ReverseAccountAndVerifyMsg(GLAccountNo: Code[20]; DocumentNo: Code[20])
    var
        ReversalEntry: Record "Reversal Entry";
        GLAcc: Record "G/L Account";
    begin
        // Exercise: Reverse Posted Entry from G/L Entry.
        ReversalEntry.SetHideDialog(true);
        asserterror ReversalEntry.ReverseTransaction(GetGLEntryTransactionNo(DocumentNo, GLAccountNo));

        // Verify: Verify Blocked Error Message.
        Assert.ExpectedTestFieldError(GLAcc.FieldCaption(Blocked), Format(false));
    end;

    local procedure ReversePurchEntrySetup(var PurchAccount: Code[20]) DocumentNo: Code[20]
    begin
        DocumentNo := CreateAndPostPurchInvoice(PurchAccount);
        BlockGLAccount(PurchAccount, true);
    end;

    local procedure ReverseSalesEntrySetup(var SalesAccount: Code[20]) DocumentNo: Code[20]
    begin
        DocumentNo := CreateAndPostSalesInvoice(SalesAccount);
        BlockGLAccount(SalesAccount, true);
    end;

    local procedure ReverseAllowPeriodSetup(var GLAccountNo: Code[20]; var AllowPostingFrom: Date; var AllowPostingTo: Date; PostingDate: Date): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GeneralLedgerSetup.Get();
        AllowPostingFrom := GeneralLedgerSetup."Allow Posting From";
        AllowPostingTo := GeneralLedgerSetup."Allow Posting To";
        UpdateGeneralLedgerSetup(0D, 0D); // Update General Ledger Setup Date Range fields with OD value.
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account",
          GLAccountNo, LibraryRandom.RandInt(100)); // Using RANDOM for Amount field.
        UpdateGeneralJournalLine(GenJournalLine, PostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateGeneralLedgerSetup(WorkDate(), WorkDate());
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CreateGeneralJournalLine(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; CurrencyCode: Code[10]; BalAccountNo: Code[20]; Amount: Decimal; AppliesToDocNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Take Random Amount for General Journal Line.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Posting Date", LibraryFiscalYear.GetFirstPostingDate(true));
        // Get Posting Date for Closed Financial Year.
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
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

    local procedure CreateAndPostGenJournalLineWithAppliesToDoc(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        CreateGenJournalLine(
          GenJournalLine, DocumentType, AccountType, GenJournalLine."Account No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", '', GenJournalLine."Bal. Account No.", -GenJournalLine.Amount, DocumentNo);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostApplyGenJournalLineWithPostingDate(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; CurrencyCode: Code[10]; PostingDate: Date)
    begin
        CreateGenJournalLine(
          GenJournalLine, DocumentType, AccountType, GenJournalLine."Account No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", CurrencyCode,
          GenJournalLine."Bal. Account No.", -GenJournalLine.Amount, DocumentNo);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.FindFirst();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));  // Take Random Value.
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateGenJournalLineDocNo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        if DocumentNo <> '' then
            GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesAccount: Code[20]) DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", SalesLine.Quantity);  // Value is not important, Unit Price updating with Quantity.
        SalesLine.Modify(true);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesAccount := GeneralPostingSetup."Sales Account";
    end;

    local procedure CreateAndPostPurchInvoice(var PurchAccount: Code[20]) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchAccount := GeneralPostingSetup."Purch. Account";
    end;

    local procedure CreateCurrencyWithExchRates(Date1: Date; Date2: Date): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(
          LibraryERM.CreateCurrencyWithExchangeRate(Date1, LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(10, 20, 2)));
        LibraryERM.CreateExchangeRate(Currency.Code, Date2, LibraryRandom.RandDecInRange(20, 30, 2), LibraryRandom.RandDecInRange(20, 30, 2));
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithDefDim(DimensionValue: Record "Dimension Value") CustNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        CustNo := LibrarySales.CreateCustomerNo();
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateVendorWithDefDim(DimensionValue: Record "Dimension Value") VendNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        VendNo := LibraryPurchase.CreateVendorNo();
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, VendNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreatePaymentLedgerEntryWithCheckEntry(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.SelectPmtJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, '', LibraryRandom.RandDec(1000, 2));
        GenJournalLine."Check Printed" := true;
        GenJournalLine."Bank Payment Type" := GenJournalLine."Bank Payment Type"::"Computer Check";
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine.Modify();
        Commit();
        CreateCheckLedger(GenJournalLine);
    end;

    local procedure CreateCheckLedger(GenJournalLine: Record "Gen. Journal Line")
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckLedgerEntry2: Record "Check Ledger Entry";
        NextCheckEntryNo: Integer;
    begin
        CheckLedgerEntry2.LockTable();
        CheckLedgerEntry2.Reset();
        if CheckLedgerEntry2.FindLast() then
            NextCheckEntryNo := CheckLedgerEntry2."Entry No." + 1
        else
            NextCheckEntryNo := 1;

        CheckLedgerEntry.Init();
        CheckLedgerEntry."Entry No." := NextCheckEntryNo;
        CheckLedgerEntry."Bank Account No." := GenJournalLine."Bal. Account No.";
        CheckLedgerEntry."Document Type" := CheckLedgerEntry."Document Type"::Payment;
        CheckLedgerEntry.Amount := GenJournalLine.Amount;
        CheckLedgerEntry."Check No." := GenJournalLine."Document No.";
        CheckLedgerEntry."Bank Payment Type" := CheckLedgerEntry."Bank Payment Type"::"Computer Check";
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::Printed;
        CheckLedgerEntry.Insert(true);
        Commit();
    end;

    local procedure CreateCheckLedgerForEmployee(GenJournalLine: Record "Gen. Journal Line")
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckLedgerEntry2: Record "Check Ledger Entry";
        NextCheckEntryNo: Integer;
    begin
        CheckLedgerEntry2.LockTable();
        CheckLedgerEntry2.Reset();
        if CheckLedgerEntry2.FindLast() then
            NextCheckEntryNo := CheckLedgerEntry2."Entry No." + 1
        else
            NextCheckEntryNo := 1;

        CheckLedgerEntry.Init();
        CheckLedgerEntry."Entry No." := NextCheckEntryNo;
        CheckLedgerEntry."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Employee;
        CheckLedgerEntry."Bank Account No." := GenJournalLine."Bal. Account No.";
        CheckLedgerEntry."Document Type" := CheckLedgerEntry."Document Type"::Payment;
        CheckLedgerEntry."Document No." := GenJournalLine."Document No.";
        CheckLedgerEntry.Amount := GenJournalLine.Amount;
        CheckLedgerEntry."Check No." := GenJournalLine."Document No.";
        CheckLedgerEntry."Bal. Account No." := GenJournalLine."Account No.";// ."Bal. Account No.";
        CheckLedgerEntry."Bank Payment Type" := CheckLedgerEntry."Bank Payment Type"::"Computer Check";
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::Printed;
        CheckLedgerEntry.Insert(true);
        Commit();
    end;

    local procedure DateCompressForGLEntries(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        DateComprRegister: Record "Date Compr. Register";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        DateCompressGeneralLedger: Report "Date Compress General Ledger";
    begin
        LibraryFiscalYear.CloseFiscalYear();
        GLEntry.SetRange("Document No.", DocumentNo);
        DateCompressGeneralLedger.SetTableView(GLEntry);
        DateComprRetainFields."Retain Document Type" := false;
        DateComprRetainFields."Retain Document No." := true;
        DateComprRetainFields."Retain Job No." := false;
        DateComprRetainFields."Retain Business Unit Code" := false;
        DateComprRetainFields."Retain Quantity" := false;
        DateComprRetainFields."Retain Journal Template Name" := false;
        DateCompressGeneralLedger.InitializeRequest(
          WorkDate(), WorkDate(), DateComprRegister."Period Length"::Day, '', DateComprRetainFields, InsertDimSelectionBuffer(), false);
        DateCompressGeneralLedger.UseRequestPage(false);
        DateCompressGeneralLedger.Run();
    end;

    local procedure FindBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetRange(Blocked, false);
        BankAccount.SetFilter("Bank Acc. Posting Group", '<>''''');
        BankAccount.FindFirst();
        exit(BankAccount."No.");
    end;

    local procedure BlockGLAccount(GLAccountNo: Code[20]; Blocked: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate(Blocked, Blocked);
        GLAccount.Modify(true);
    end;

    local procedure FindFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetRange(Blocked, false);
        FixedAsset.SetFilter("FA Subclass Code", '<>''''');
        FixedAsset.FindFirst();
        exit(FixedAsset."No.");
    end;

    local procedure GetGLEntryTransactionNo(DocumentNo: Code[20]; AccountNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindFirst();
        exit(GLEntry."Transaction No.");
    end;

    local procedure InsertDimSelectionBuffer() RetainDimText: Text[250]
    var
        DimensionTranslation: Record "Dimension Translation";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        DimensionSelectionBuffer.DeleteAll();
        DimensionTranslation.FindSet();
        if DimensionSelectionBuffer.IsEmpty() then
            repeat
                if not DimensionSelectionBuffer.Get(DimensionTranslation.Code) then begin
                    DimensionSelectionBuffer.Validate(Code, DimensionTranslation.Code);
                    DimensionSelectionBuffer.Validate(Selected, true);
                    DimensionSelectionBuffer.Insert();
                end;
            until DimensionTranslation.Next() = 0;
        DimensionSelectionBuffer.SetDimSelection(3, 98, '', RetainDimText, DimensionSelectionBuffer);
    end;

    local procedure PrepareGLRegisterEntry(var GLRegister: Record "G/L Register")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlLine(GenJournalLine, GenJournalLine."Document Type"::Invoice);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        GLRegister.FindLast();
    end;

    local procedure UnApplyCustomerLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UnApplyVendorLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure UnApplyEmployeeLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyEmployeeLedgerEntry(EmployeeLedgerEntry);
    end;

    local procedure UpdateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(AllowPostingFrom: Date; AllowPostingTo: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Using assignment to avoid validation errors.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := AllowPostingFrom;
        GeneralLedgerSetup."Allow Posting To" := AllowPostingTo;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateBalanceAccount(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.ModifyAll("Bal. Account No.", '', true);
    end;

    local procedure UpdateGenJournalTemplate(Name: Code[10]; ForceDocBalance: Boolean) OriginalForceDocBal: Boolean
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(Name);
        OriginalForceDocBal := GenJournalTemplate."Force Doc. Balance";
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
    end;

    local procedure VoidCheck(DocumentNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
        CheckManagement: Codeunit CheckManagement;
        ConfirmFinancialVoid: Page "Confirm Financial Void";
    begin
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
        CheckManagement.FinancialVoidCheck(CheckLedgerEntry);
        ConfirmFinancialVoid.SetCheckLedgerEntry(CheckLedgerEntry);
    end;

    local procedure VerifyDocNoAndDocDateAreEmpty(GenJournalBatch: Record "Gen. Journal Batch"; PaymentJournal: TestPage "Payment Journal")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.AreEqual('', GenJournalLine."Document No.", 'Document No. must be cleared after Void Check');
        Assert.AreEqual(0D, GenJournalLine."Document Date", 'Document Date must be cleared after Void Check');
        Assert.AreEqual('', PaymentJournal."Document No.".Value, 'Document No. must be cleared after Void Check');
    end;

    local procedure VerifyCheckLedgerEntry(DocumentNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.FindFirst();
        CheckLedgerEntry.TestField("Entry Status", CheckLedgerEntry."Entry Status"::"Financially Voided");
        CheckLedgerEntry.TestField("Original Entry Status", CheckLedgerEntry."Original Entry Status"::Posted);
    end;

    local procedure VerifyAllowedPeriodAndCleanup(DocumentNo: Code[20]; GLAccountNo: Code[20]; AllowPostingFrom: Date; AllowPostingTo: Date)
    begin
        // Verify: Verify Error Message.
        VerifyMsgForAllowedPeriod(DocumentNo, GLAccountNo);

        // Tear Down.
        UpdateGeneralLedgerSetup(AllowPostingFrom, AllowPostingTo);
    end;

    local procedure VerifyMsgForAllowedPeriod(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Transaction No.", GetGLEntryTransactionNo(DocumentNo, GLAccountNo));
        GLEntry.FindFirst();
        Assert.AreEqual(StrSubstNo(ReversalErrorForPeriod, GLEntry.TableCaption(), GLEntry."Entry No."), GetLastErrorText, ErrorsMustMatch);
    end;

    local procedure VerifyGLEntryVATEntryLinkReversed(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange(Reversed, true);
        GLEntry.FindFirst();
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Reversed, true);
        VATEntry.FindFirst();
        Assert.IsTrue(
          GLEntryVATEntryLink.Get(GLEntry."Entry No.", VATEntry."Entry No."), GLEntryVATEntryLinkErr);
    end;

    local procedure VerifyGLEntryDimSetID(DocumentNo: Code[20]; CurrencyCode: Code[10]; DimSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        Currency.Get(CurrencyCode);
        GLEntry.SetRange("G/L Account No.", Currency."Realized Gains Acc.");
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Dimension Set ID", DimSetID);
        until GLEntry.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VoidCheckPageHandler(var ConfirmFinancialVoid: Page "Confirm Financial Void"; var Response: Action)
    var
        VoidTypeVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(VoidTypeVariant);
        ConfirmFinancialVoid.InitializeRequest(WorkDate(), VoidTypeVariant);
        Response := ACTION::Yes
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

