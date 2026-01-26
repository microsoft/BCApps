codeunit 141054 "ERM Distribution Recurring Amt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Recurring General Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ValueEqualMsg: Label 'Value must be equal.';
        RecurringMethodErr: Label 'Recurring Method must be either B  Balance or RB Reversing Balance.';

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,AmountDistributionPageHandler')]
    [Scope('OnPrem')]
    procedure RecurringJournalWithBalanceRecurringMethod()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        WhatToCalculate: Option "Net Change",Balance;
    begin
        // [SCENARIO] G/L Entry after Calculate Distribution on Recurring General Journal with Recurring Method as "B Balance".

        // Setup: Create Recurring Journal Line and calculate distribution on Recurring General Journal.
        Initialize();
        AccountNo := CreateGLAccount();
        CreateAndPostRecurringJournalLine(
          GenJournalLine."Recurring Method"::"B  Balance", WhatToCalculate::"Net Change",
          CreateAndPostGeneralJournalLine(), AccountNo, AccountNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,AmountDistributionPageHandler')]
    [Scope('OnPrem')]
    procedure RecurringJournalWithReverseBalanceRecurringMethod()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        WhatToCalculate: Option "Net Change",Balance;
    begin
        // [SCENARIO] G/L Entry after Calculate Distribution on Recurring General Journal with Recurring Method as "RB Reversing Balance".

        // Setup: Create Recurring Journal Line and calculate distribution on Recurring General Journal.
        Initialize();
        AccountNo := CreateAndPostGeneralJournalLine();
        CreateAndPostRecurringJournalLine(
          GenJournalLine."Recurring Method"::"RB Reversing Balance", WhatToCalculate::Balance, AccountNo, CreateGLAccount(), AccountNo);
    end;

    local procedure CreateAndPostRecurringJournalLine(RecurringMethod: Enum "Gen. Journal Recurring Method"; WhatToCalculate: Option; GLAccountNo: Code[20]; AllocationAccountNo: Code[20]; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        DimensionCode: Code[20];
    begin
        CreateRecurringJournalLine(GenJournalLine, RecurringMethod, GLAccountNo);
        DimensionCode := CreateGenJnlAllocation(GenJournalLine, AllocationAccountNo);
        LibraryVariableStorage.Enqueue(WhatToCalculate);  // Enqueue for AmountDistributionPageHandler.
        CalculateDistributionOnRecurringGeneralJournal(GenJournalLine."Journal Batch Name");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        GLAccount.Get(AccountNo);
        GLAccount.CalcFields(Balance);
        VerifyGLEntry(GenJournalLine."Account No.", '', -GLAccount.Balance);  // Dimension Code as blank.
        VerifyGLEntry(AllocationAccountNo, DimensionCode, GLAccount.Balance);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateDistributionOnRecurringJournalError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] error after Calculate Distribution on Recurring General Journal with Recurring Method as "F  Fixed".

        // Setup: Create Recurring Journal Line and create Gen. Jnl Allocation.
        Initialize();
        CreateRecurringJournalLine(GenJournalLine, GenJournalLine."Recurring Method"::"F  Fixed", CreateAndPostGeneralJournalLine());
        CreateGenJnlAllocation(GenJournalLine, CreateGLAccount());

        // Exercise.
        asserterror CalculateDistributionOnRecurringGeneralJournal(GenJournalLine."Journal Batch Name");

        // Verify.
        Assert.ExpectedError(StrSubstNo(RecurringMethodErr));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CalculateDistributionOnRecurringGeneralJournal(CurrentJnlBatchName: Code[10])
    var
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        RecurringGeneralJournal.OpenEdit();
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        RecurringGeneralJournal.CalculateDistribution.Invoke();  // Invoke AmountDistributionPageHandler;
        RecurringGeneralJournal.Close();
    end;

    local procedure CreateAndPostGeneralJournalLine(): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(), LibraryRandom.RandDec(100, 2));  // Using random value for Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Account No.");
    end;

    local procedure CreateDimensionValue(): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        exit(DimensionValue.Code);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJnlAllocation(GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]): Code[20]
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        LibraryERM.CreateGenJnlAllocation(
          GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", AccountNo);
        GenJnlAllocation.Validate("Shortcut Dimension 1 Code", CreateDimensionValue());
        GenJnlAllocation.Modify(true);
        exit(GenJnlAllocation."Shortcut Dimension 1 Code");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateRecurringBatchAndTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateRecurringJournalLine(var GenJournalLine: Record "Gen. Journal Line"; RecurringMethod: Enum "Gen. Journal Recurring Method"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        RecurringFrequency: DateFormula;
    begin
        CreateRecurringBatchAndTemplate(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, 0);  // Amount as 0.
        GenJournalLine.Validate("Recurring Method", RecurringMethod);
        Evaluate(RecurringFrequency, '<' + Format(LibraryRandom.RandInt(5)) + 'M >');  // Use Random value for Recurring Frequency.
        GenJournalLine.Validate("Recurring Frequency", RecurringFrequency);
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyGLEntry(GLAccountNo: Code[20]; GlobalDimensionOneCode: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Bal. Account No.", '');
        GLEntry.FindFirst();
        GLEntry.TestField("Global Dimension 1 Code", GlobalDimensionOneCode);
        Assert.AreEqual(Amount, GLEntry.Amount, ValueEqualMsg);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AmountDistributionPageHandler(var AmountDistribution: TestPage "Amount Distribution")
    var
        WhatToCalculate: Variant;
    begin
        LibraryVariableStorage.Dequeue(WhatToCalculate);
        AmountDistribution.FromDate.SetValue(WorkDate());
        AmountDistribution.ToDate.SetValue(WorkDate());
        AmountDistribution.WhatToCalculate.SetValue(WhatToCalculate);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

