codeunit 134146 "ERM Reverse Recurring Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Recurring General Journal]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reverse Recurring Journal");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reverse Recurring Journal");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reverse Recurring Journal");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseFixedRecurringJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Recurring Journal for Fixed Recurring Method and Post it and Check GL Entry.

        ReverseRecurringJournal(GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseVariableRecurringJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Recurring Journal for Variable Recurring Method and Post it and Check GL Entry.

        ReverseRecurringJournal(GenJournalLine."Recurring Method"::"V  Variable", GenJournalLine."Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseRFFixedRecurringJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Recurring Journal for RF Reversing Fixed Recurring Method and Post it and Check GL Entry.

        ReverseRecurringJournal(GenJournalLine."Recurring Method"::"RF Reversing Fixed", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseRVVariabeRecurringJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Recurring Journal for RV Reversing Variable Recurring Method and Post it and Check GL Entry.

        ReverseRecurringJournal(GenJournalLine."Recurring Method"::"RV Reversing Variable", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseFixedRecurringJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Reverse the lines for Recurring Method as Fixed in Recurring General Journal and Verify G/L Entry.
        // Verify whether correct entries have been reversed when the Recurring Method is Fixed.

        ReverseRecurringJournal(GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseVariableJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Reverse the lines for Recurring Method as Variable in Recurring General Journal and Verify G/L Entry.
        // Verify whether correct entries have been reversed when the Recurring Method is Variable.

        ReverseRecurringJournal(GenJournalLine."Recurring Method"::"V  Variable", GenJournalLine."Document Type"::Payment);
    end;

    local procedure ReverseRecurringJournal(RecurringMethod: Enum "Gen. Journal Recurring Method"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLAccount: Record "G/L Account";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // 1. Setup: Create Recurring Journal, Allocation Line and Post it with Random Amount.
        Initialize();
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateRecurringJournalLine(
          GenJournalLine, GenJournalBatch, RecurringMethod, DocumentType,
          CreateGLAccount(GLAccount."Income/Balance"::"Balance Sheet"), LibraryRandom.RandInt(100));
        CreateAllocationLine(GenJnlAllocation, GenJournalLine, GenJournalLine."Account No.", 100); // Required for 100 % allocation.
        SaveGenJournalLineInTemp(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Reverse GL Register for Recurring Journal.
        ReverseGLRegister();

        // 3. Verify: Verify Reversed GL Entry for Recurring Journal.
        VerifyGLEntry(GenJnlAllocation."Account No.", -(GenJournalLine.Amount + GenJnlAllocation."VAT Amount"));
        VerifyReversal(TempGenJournalLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseBalanceJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check the Functionality of Recurring Method as "Balance" in Recurring General Journal.Reverse the lines having
        // Recurring Method as "Balance"and verify Posted G/L Entries.

        ReversingBalanceJournal(GenJournalLine."Recurring Method"::"B  Balance");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseReversingBalanceJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check the Functionality of Recurring Method as "Reversing Balance" in Recurring General Journal.Reverse the lines having
        // Recurring Method as "Reversing Balance" and verify Posted G/L Entries.

        ReversingBalanceJournal(GenJournalLine."Recurring Method"::"RB Reversing Balance")
    end;

    local procedure ReversingBalanceJournal(RecurringMethod: Enum "Gen. Journal Recurring Method")
    var
        GLAccount: Record "G/L Account";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Setup: Create General Journal, Recurring Journal with Amount 0, Define Allocation and Post it.
        Initialize();
        CreateRecurringGenJournalBatch(GenJournalBatch);

        CreateAndPostGenJournalLine(GenJournalLine);
        CreateRecurringJournalLine(
          GenJournalLine2, GenJournalBatch, RecurringMethod, GenJournalLine2."Document Type"::Payment, GenJournalLine."Account No.", 0);

        // Required for 20 and 80 % allocation.
        CreateAllocationLine(GenJnlAllocation, GenJournalLine2, CreateGLAccount(GLAccount."Income/Balance"::"Balance Sheet"), 20);
        CreateAllocationLine(GenJnlAllocation, GenJournalLine2, GenJournalLine."Bal. Account No.", 80);
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // Exercise: Reverse GL Register for Recurring Journal.
        ReverseGLRegister();

        // Verify: Verify GL Entry after Reversal.
        VerifyGLEntry(GenJournalLine."Bal. Account No.", -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseBalanceRecurringJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Recurring Journal for Balance Recurring Method and Post it and Check GL Entry.

        ReversingBalanceRecurringJnl(GenJournalLine."Recurring Method"::"B  Balance");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseRBBalanceRecurringJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Recurring Journal for RB Reversing Balance Recurring Method and Post it and Check GL Entry.

        ReversingBalanceRecurringJnl(GenJournalLine."Recurring Method"::"RB Reversing Balance")
    end;

    local procedure ReversingBalanceRecurringJnl(RecurringMethod: Enum "Gen. Journal Recurring Method")
    var
        GLAccount: Record "G/L Account";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // 1. Setup: Create General Journal, Recurring Journal with Amount 0, Define Allocation and Post it.
        Initialize();
        CreateRecurringGenJournalBatch(GenJournalBatch);

        CreateAndPostGenJournalLine(GenJournalLine);
        CreateRecurringJournalLine(
          GenJournalLine2, GenJournalBatch, RecurringMethod, GenJournalLine2."Document Type"::Payment, GenJournalLine."Account No.", 0);

        // Required for 80 and 20 % allocation.
        CreateAllocationLine(GenJnlAllocation, GenJournalLine2, CreateGLAccount(GLAccount."Income/Balance"::"Balance Sheet"), 80);
        CreateAllocationLine(GenJnlAllocation, GenJournalLine2, GenJournalLine."Bal. Account No.", 20);
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // 2. Exercise: Reverse GL Register for Recurring Journal.
        ReverseGLRegister();

        // 3. Verify: Verify GL Entry after Reversal.
        VerifyGLEntry(GenJournalLine."Bal. Account No.", -GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentWithAllocationCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GLEntry: Record "G/L Entry";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        GLAccountNo: array[2] of Code[20];
    begin
        // Check the Receive a Payment with Allocation from the Recurring Journal for Customer.

        // 1. Setup: Create Customer,create and post General Journal Line, create Recurring Journal with Applies to Document No.
        LibrarySales.CreateCustomer(Customer);
        GLAccountNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.",
          LibraryRandom.RandInt(1000));  // Using Random Number Generator for Amount, Integer value for Allocation.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateApplyRecurringJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", -GenJournalLine.Amount, GenJournalLine."Document No.");

        // 2. Exercise: Define Allocation in Recurring Journal and Post it.
        CreateAllocationLine(GenJnlAllocation, GenJournalLine, GLAccountNo[1], 50);  // Required for 50 % allocation.
        CreateAllocationLine(GenJnlAllocation, GenJournalLine, GLAccountNo[2], 50);  // Required for 50 % allocation.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Customer Ledger Entry and GL Entry for allocation.
        VerifyCustomerLedgerEntry(Customer."No.");
        VerifyGLEntryAllocation(GLEntry, GLAccountNo[1], -(GenJournalLine.Amount / 2));  // Verify 50 % allocation of amount.
        VerifyGLEntryAllocation(GLEntry, GLAccountNo[2], -(GenJournalLine.Amount / 2)); // Verify 50 % allocation of amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentWithAllocationVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        Vendor: Record Vendor;
        GLEntry: Record "G/L Entry";
        LibraryPurchase: Codeunit "Library - Purchase";
        GLAccountNo: array[2] of Code[20];
    begin
        // Check the Receive a Payment with Allocation from the Recurring Journal for Vendor.

        // 1. Setup: Create Vendor,Create and post General Journal Line, create Recurring Journal with Applies to Document No.
        LibraryPurchase.CreateVendor(Vendor);
        GLAccountNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccountNo[2] := LibraryERM.CreateGLAccountNo();
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.",
          -LibraryRandom.RandInt(1000));  // Using Random Number Generator for Amount, Integer value for Allocation.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateApplyRecurringJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", -GenJournalLine.Amount, GenJournalLine."Document No.");

        // 2. Exercise: Define Allocation in Recurring Journal and Post it.
        CreateAllocationLine(GenJnlAllocation, GenJournalLine, GLAccountNo[1], 50);  // Required for 50 % allocation.
        CreateAllocationLine(GenJnlAllocation, GenJournalLine, GLAccountNo[2], 50);  // Required for 50 % allocation.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Vendor Ledger Entry and GL Entry for allocation.
        VerifyVendorLedgerEntry(Vendor."No.");
        VerifyGLEntryAllocation(GLEntry, GLAccountNo[1], -(GenJournalLine.Amount / 2));  // Verify 50 % allocation of amount.
        VerifyGLEntryAllocation(GLEntry, GLAccountNo[2], -(GenJournalLine.Amount / 2));  // Verify 50 % allocation of amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRecurringReversedGenJnlLinesNotSortedByDocNoWithForceDocBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: array[2] of Code[20];
        PostedDocumentNo: array[4] of Code[20];
        Amount: array[2] of Decimal;
    begin
        // [FEATURE] [Force Doc. Balance]
        // [SCENARIO 345070] Post recurring Reversing Variable Gen. Journal Lines, that are not sorted in Document No order in case "Force Doc. Balance" and "Posting No. Series" are set.

        // [GIVEN] Gen. Journal Template with "Force Doc. Balance" = true; Gen. Journal Batch with non-empty "Posting No. Series".
        CreateRecurringGenJournalBatch(GenJournalBatch);
        UpdatePostingNoSeriesOnGenJnlBatch(GenJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        UpdateForceDocBalanceOnGenJnlTemplate(GenJournalBatch."Journal Template Name", true);

        // [GIVEN] Four recurring Gen. Journal lines with Reversing Variable method and created with Document No. in order TEST1, TEST2, TEST1, TEST2.
        DocumentNo[1] := LibraryUtility.GenerateGUID();
        DocumentNo[2] := LibraryUtility.GenerateGUID();
        Amount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        Amount[2] := LibraryRandom.RandDecInRange(100, 200, 2);
        GetPostedDocumentNos(PostedDocumentNo, GenJournalBatch."Posting No. Series");

        CreateGenJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          LibraryERM.CreateGLAccountNo(), Amount[1], DocumentNo[1]);
        CreateGenJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          LibraryERM.CreateGLAccountNo(), Amount[2], DocumentNo[2]);
        CreateGenJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          LibraryERM.CreateGLAccountNo(), -Amount[1], DocumentNo[1]);
        CreateGenJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          LibraryERM.CreateGLAccountNo(), -Amount[2], DocumentNo[2]);

        // [WHEN] Post recurring Gen. Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posted Gen. Journal Lines are balanced by Document No.
        // [THEN] Reversed Posted Gen. Journal Lines are balanced by Document No.
        VerifyReversedGLEntries(GenJournalBatch.Name, PostedDocumentNo, Amount);
    end;

    local procedure CreateApplyRecurringJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; AppliestoDocNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"F  Fixed");
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);

        // Take Random Recurring Frequency.
        Evaluate(GenJournalLine."Recurring Frequency", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateRecurringJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        GenJournalLine.Validate("Recurring Method", RecurringMethod);
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name");

        // Take Random Recurring Frequency.
        Evaluate(GenJournalLine."Recurring Frequency", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAllocationLine(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AllocationPercent: Decimal)
    begin
        LibraryERM.CreateGenJnlAllocation(
          GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", AccountNo);
        GenJnlAllocation.Validate("Allocation %", AllocationPercent);
        GenJnlAllocation.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Take Random Amount for General Journal Line.
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(GLAccount."Income/Balance"::"Income Statement"),
          LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount(GLAccount."Income/Balance"::"Balance Sheet"));
        GenJournalLine.Validate("Document No.", GenJournalBatch.Name + Format(GenJournalLine."Line No."));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccount(IncomeBalance: Enum "G/L Account Report Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", IncomeBalance);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount(GLAccount."Income/Balance"::"Balance Sheet"));
        GenJournalLine.Validate("Document No.", GenJournalBatch.Name + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalLineWithDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; AccountNo: Code[20]; Amount: Decimal; DocumentNo: Code[20])
    begin
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, RecurringMethod, GenJournalLine."Document Type"::" ", AccountNo, Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateRecurringGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure GetPostedDocumentNos(var PostedDocumentNo: array[4] of Code[20]; NoSeriesCode: Code[20])
    var
        NextDocumentNo: Code[20];
        i: Integer;
    begin
        NextDocumentNo := NoSeriesBatch.GetNextNo(NoSeriesCode);
        for i := 1 to ArrayLen(PostedDocumentNo) do begin
            PostedDocumentNo[i] := NextDocumentNo;
            NextDocumentNo := IncStr(NextDocumentNo);
        end;
    end;

    local procedure ReverseGLRegister()
    var
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
    begin
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");
    end;

    local procedure SaveGenJournalLineInTemp(var TempGenJournalLine: Record "Gen. Journal Line" temporary; GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Account No.", GenJournalLine."Account No.");
        GenJournalLine.FindSet();
        repeat
            TempGenJournalLine.Init();
            TempGenJournalLine := GenJournalLine;
            TempGenJournalLine.Insert();
        until GenJournalLine.Next() = 0;
    end;

    local procedure UpdateForceDocBalanceOnGenJnlTemplate(GenJnlTemplateName: Code[20]; ForceDocBalance: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJnlTemplateName);
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
    end;

    local procedure UpdatePostingNoSeriesOnGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch"; PostingNoSeries: Code[20])
    begin
        GenJournalBatch.Validate("Posting No. Series", PostingNoSeries);
        GenJournalBatch.Modify(true);
    end;

    local procedure VerifyReversal(GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Reversed, true);
    end;

    local procedure VerifyReversedGLEntries(GenJournalBatchName: Code[10]; PostedDocumentNo: array[4] of Code[20]; Amount: array[2] of Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLAmount: Decimal;
        i: Integer;
    begin
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Journal Batch Name", GenJournalBatchName);
        Assert.RecordCount(GLEntry, 8);

        GLEntry.SetRange("Posting Date", WorkDate());
        for i := 1 to ArrayLen(Amount) do begin
            GLEntry.SetRange("Document No.", PostedDocumentNo[i]);
            Assert.RecordCount(GLEntry, 2);
            GLEntry.FindFirst();
            GLAmount := GLEntry.Amount;
            Assert.AreEqual(Amount[i], Abs(GLAmount), '');
            GLEntry.Next();
            GLEntry.TestField(Amount, -GLAmount);
        end;

        // reversed G/L Entries
        GLEntry.SetRange("Posting Date", WorkDate() + 1);
        for i := 1 to ArrayLen(Amount) do begin
            GLEntry.SetRange("Document No.", PostedDocumentNo[i + 2]);
            Assert.RecordCount(GLEntry, 2);
            GLEntry.FindFirst();
            GLAmount := GLEntry.Amount;
            Assert.AreEqual(Amount[i], Abs(GLAmount), '');
            GLEntry.Next();
            GLEntry.TestField(Amount, -GLAmount);
        end;
    end;

    local procedure VerifyGLEntry(GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter(Amount, '<0');
        VerifyGLEntryAllocation(GLEntry, GLAccountNo, Amount);
    end;

    local procedure VerifyGLEntryAllocation(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Appln. Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount));
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField("Remaining Amount", 0);
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
        // dummy message handler
    end;
}

