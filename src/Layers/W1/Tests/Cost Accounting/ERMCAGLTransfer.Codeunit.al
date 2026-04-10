codeunit 134812 "ERM CA GL Transfer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting] [G/L Integration]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        isInitialized: Boolean;
        CostRegisterEntriesError: Label 'The number of expected Cost Register entries is different than the actual one';
        ExpectedValueIsDifferentError: Label 'Expected value of %1 field is different than the actual one.';
        NoEntriesToTransferError: Label 'There are no G/L entries that meet the criteria for transfer to cost accounting.';
        UnexpectedErrorMessage: Label 'Unexpected error message: %1.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM CA GL Transfer");
        LibraryCostAccounting.InitializeCASetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM CA GL Transfer");

        LibraryERMCountryData.UpdateLocalData();
        LibraryFiscalYear.UpdateAllowGAccDeletionBeforeDateOnGLSetup(LibraryFiscalYear.GetPastNewYearDate(5));
        LibraryERM.SetBlockDeleteGLAccount(false);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM CA GL Transfer");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLTransferWithCCDimension()
    begin
        // Post a Gen. Journal Line for an account which has a default dimension corresponding to Cost Centers and
        // verify that the G/L entry gets transferred

        TransferGLEntry(true, true, false, false, LibraryRandom.RandDec(1000, 2));

        // Verify:
        ValidateEntriesTransfered();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLTransferWithCODimension()
    begin
        // Post a Gen. Journal Line for an account which has a default dimension corresponding to Cost Objects and
        // verify that the G/L entry gets transferred

        TransferGLEntry(true, false, true, false, LibraryRandom.RandDec(1000, 2));

        // Verify:
        ValidateEntriesTransfered();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLTransferWithCCAndCODimension()
    var
        CostEntryNo: Integer;
    begin
        // Post a Gen. Journal Line for an account which has default dimensions corresponding to Cost Centers and Cost Objects and
        // verify that the cost center code takes precedence during the transfer

        TransferGLEntry(true, true, true, false, LibraryRandom.RandDec(1000, 2));

        // Verify:
        CostEntryNo := ValidateEntriesTransfered();
        ValidateCostEntryFields(CostEntryNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLTransferWithNoCostTypeLink()
    var
        CostRegister: Record "Cost Register";
        ExpectedCostRegisterEntries: Integer;
    begin
        // Post a Gen. Journal Line for an account which does not have a valid Cost Type associated and
        // verify that no Cost Register entries are created (no G/L entries are transferred).

        ExpectedCostRegisterEntries := CostRegister.Count();
        TransferGLEntry(false, true, false, false, LibraryRandom.RandDec(1000, 2));

        // Verify:
        Assert.AreEqual(ExpectedCostRegisterEntries, CostRegister.Count, CostRegisterEntriesError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLTransferWithNoDimensions()
    var
        CostRegister: Record "Cost Register";
        ExpectedCostRegisterEntries: Integer;
    begin
        // Post a Gen. Journal Line for an account which does not have dimensions set corresponding to a Cost Center or a Cost Object and
        // verify that no Cost Register entries are created (no G/L entries are transferred).

        ExpectedCostRegisterEntries := CostRegister.Count();
        TransferGLEntry(true, false, false, false, LibraryRandom.RandDec(1000, 2));

        // Verify:
        Assert.AreEqual(ExpectedCostRegisterEntries, CostRegister.Count, CostRegisterEntriesError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLTransferWithClosingDate()
    var
        CostRegister: Record "Cost Register";
        ExpectedCostRegisterEntries: Integer;
    begin
        // Post a Gen. Journal Line with a closing date and verify that the G/L entry does not get transferred

        ExpectedCostRegisterEntries := CostRegister.Count();
        TransferGLEntry(true, true, false, true, LibraryRandom.RandDec(1000, 2));

        // Verify:
        Assert.AreEqual(ExpectedCostRegisterEntries, CostRegister.Count, CostRegisterEntriesError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLTransferWithAmountZero()
    var
        CostRegister: Record "Cost Register";
        ExpectedCostRegisterEntries: Integer;
    begin
        // Post a Gen. Journal Line with an Amount =0 and verify that the G/L entry does not get transferred

        ExpectedCostRegisterEntries := CostRegister.Count();
        TransferGLEntry(true, false, true, false, 0);

        // Verify:
        Assert.AreEqual(ExpectedCostRegisterEntries, CostRegister.Count, CostRegisterEntriesError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure GLTransferForNonIncomeAccount()
    var
        GLAccount: Record "G/L Account";
        CostRegister: Record "Cost Register";
        CostType: Record "Cost Type";
        ExpectedCostRegisterEntries: Integer;
    begin
        // Post a Gen. Journal Line for a BalanceSheet account type and verify that the G/L entry does not get transferred

        Initialize();

        // Cost Accounting Setup with Autotransfer = TRUE
        CostAccountingSetup(true);
        CreateBalanceSheetAccount(GLAccount);
        SetAccWithDefaultDimensions(GLAccount."No.", true, false);
        ExpectedCostRegisterEntries := CostRegister.Count();

        // Excercise:
        PostGenJournalLine(GLAccount."No.", LibraryRandom.RandDec(1000, 2), false);

        // Verify:
        Assert.AreEqual(ExpectedCostRegisterEntries, CostRegister.Count, CostRegisterEntriesError);

        // Clean-up:
        CostType.Get(GLAccount."No.");
        CostType.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLTransferForDeletedAccount()
    var
        GLAccount: Record "G/L Account";
        CostRegister: Record "Cost Register";
        ExpectedCostRegisterEntries: Integer;
        LastErrorText: Text[1024];
    begin
        // Post a Gen. Journal Line and delete the corresponding account afterwards
        // Run the Transfer G/L Entries batch job and verify that the G/L entries whose G/L account got deleted do not get transferred

        Initialize();

        // Setup:
        CostAccountingSetup(false);
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        SetAccWithDefaultDimensions(GLAccount."No.", true, false);

        PostJournalLines(GLAccount."No.");

        // Delete GL Account
        GLAccount.Find();
        GLAccount.Delete(true);
        ExpectedCostRegisterEntries := CostRegister.Count();

        // Exercise:
        asserterror LibraryCostAccounting.TransferGLEntries();

        // Verify:
        LastErrorText := GetLastErrorText;
        Assert.IsTrue(StrPos(LastErrorText, NoEntriesToTransferError) > 0, StrSubstNo(UnexpectedErrorMessage, LastErrorText));
        Assert.AreEqual(ExpectedCostRegisterEntries, CostRegister.Count, CostRegisterEntriesError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferMultipleGLEntries()
    var
        GLAccount: Record "G/L Account";
        NoOfJnlPostings: Integer;
        I: Integer;
    begin
        Initialize();

        // Setup:
        CostAccountingSetup(true); // set Autotransfer to TRUE so that all previously untransferred entries get transferred
        CostAccountingSetup(false);
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        SetAccWithDefaultDimensions(GLAccount."No.", true, false);

        // Create multiple G/L entries
        NoOfJnlPostings := 3;
        for I := 1 to NoOfJnlPostings do
            PostGenJournalLine(GLAccount."No.", LibraryRandom.RandDec(1000, 2), false);

        // Exercise:
        LibraryCostAccounting.TransferGLEntries();

        // Verify:
        ValidateTransfer(NoOfJnlPostings);
    end;

    [Normal]
    local procedure CheckBlockedDimensionValues(AccountNo: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // Un-block any blocked default dimension values for an account

        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"G/L Account", AccountNo);
        if DefaultDimension.FindSet() then
            repeat
                DimensionValue.Get(DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
                if DimensionValue.Blocked then begin
                    DimensionValue.Validate(Blocked, false);
                    DimensionValue.Modify(true);
                end;
            until DefaultDimension.Next() = 0;
    end;

    [Normal]
    local procedure CheckBlockedDimCombination()
    var
        DimensionCombination: Record "Dimension Combination";
    begin
        DimensionCombination.SetFilter("Dimension 1 Code", '%1|%2', CostCenterDimension(), CostObjectDimension());
        DeleteBlockedDimCombinations(DimensionCombination);

        Clear(DimensionCombination);
        DimensionCombination.SetFilter("Dimension 2 Code", '%1|%2', CostCenterDimension(), CostObjectDimension());
        DeleteBlockedDimCombinations(DimensionCombination);
    end;

    [Normal]
    local procedure CostAccountingSetup(Autotransfer: Boolean)
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        LibraryCostAccounting.SetAlignment(CostAccountingSetup.FieldNo("Align G/L Account"),
          CostAccountingSetup."Align G/L Account"::Automatic);
        LibraryCostAccounting.SetAutotransferFromGL(Autotransfer);
    end;

    [Normal]
    local procedure CostCenterDimension(): Code[20]
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        exit(CostAccountingSetup."Cost Center Dimension");
    end;

    [Normal]
    local procedure CostObjectDimension(): Code[20]
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        exit(CostAccountingSetup."Cost Object Dimension");
    end;

    [Normal]
    local procedure CreateBalanceSheetAccount(var GLAccount: Record "G/L Account")
    begin
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
    end;

    [Normal]
    local procedure CreateJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; AccountNo: Code[20]; Amount: Decimal)
    begin
        // Create General Journal Line.
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);

        // Update journal line to avoid Posting errors
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::" ");
        GenJournalLine.Validate("Gen. Bus. Posting Group", '');
        GenJournalLine.Validate("Gen. Prod. Posting Group", '');
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Allow Zero-Amount Posting", true);
        GenJournalLine.Modify(true);
    end;

    [Normal]
    local procedure DeleteBlockedDimCombinations(var DimensionCombination: Record "Dimension Combination")
    begin
        if DimensionCombination.FindSet() then
            repeat
                if DimensionCombination."Combination Restriction" = DimensionCombination."Combination Restriction"::Blocked then
                    DimensionCombination.Delete(true);
            until DimensionCombination.Next() = 0;
    end;

    [Normal]
    local procedure DeleteDefaultDimension(AccountNo: Code[20]; DimensionCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        if DefaultDimension.Get(DATABASE::"G/L Account", AccountNo, DimensionCode) then
            DefaultDimension.Delete(true);
    end;

    [Normal]
    local procedure PostGenJournalLine(AccountNo: Code[20]; Amount: Decimal; WithClosingDate: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SetupGeneralJnlBatch(GenJournalBatch);
        CreateJnlLine(GenJournalLine, GenJournalBatch, WorkDate(), AccountNo, Amount);
        if WithClosingDate then begin
            GenJournalLine.Validate("Posting Date", ClosingDate(CalcDate('<-1D>', LibraryFiscalYear.GetFirstPostingDate(false))));
            GenJournalLine.Modify(true);
        end;

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Normal]
    local procedure PostJournalLines(AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        // Select Gen Journal Batch and clear existing journal entries
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Post Journal Lines which set the Account Balance to 0
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateJnlLine(GenJournalLine, GenJournalBatch, LibraryFiscalYear.GetLastPostingDate(true), AccountNo, Amount);
        CreateJnlLine(GenJournalLine, GenJournalBatch, LibraryFiscalYear.GetLastPostingDate(true), AccountNo, -Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Normal]
    local procedure SetAccWithDefaultDimensions(AccountNo: Code[20]; HasCostCenterDimension: Boolean; HasCostObjectDimension: Boolean)
    begin
        if HasCostCenterDimension then begin
            SetDefaultDimension(AccountNo, CostCenterDimension());
            if not HasCostObjectDimension then
                DeleteDefaultDimension(AccountNo, CostObjectDimension());
        end;

        if HasCostObjectDimension then begin
            SetDefaultDimension(AccountNo, CostObjectDimension());
            if not HasCostCenterDimension then
                DeleteDefaultDimension(AccountNo, CostCenterDimension());
        end;

        CheckBlockedDimensionValues(AccountNo); // check for blocked default dimension values, which prevent posting
        CheckBlockedDimCombination(); // check for blocked dimension combinations, which prevent posting
    end;

    [Normal]
    local procedure SetDefaultDimension(GLAccountNo: Code[20]; DimensionCode: Code[20])
    var
        DimValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        if not DefaultDimension.Get(DATABASE::"G/L Account", GLAccountNo, DimensionCode) then begin
            LibraryDimension.FindDimensionValue(DimValue, DimensionCode);
            LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, DimValue."Dimension Code", DimValue.Code);
        end;
    end;

    [Normal]
    local procedure SetupGeneralJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryCostAccounting.CreateBalanceSheetGLAccount(GLAccount);
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);

        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    [Normal]
    local procedure TransferGLEntry(EntryHasCostTypeLink: Boolean; EntryHasCostCenterDimension: Boolean; EntryHasCostObjectDimension: Boolean; EntryHasClosingDate: Boolean; Amount: Decimal)
    var
        GLAccount: Record "G/L Account";
        CostType: Record "Cost Type";
    begin
        Initialize();

        // Setup:
        CostAccountingSetup(true);
        LibraryCostAccounting.CreateIncomeStmtGLAccount(GLAccount);
        SetAccWithDefaultDimensions(GLAccount."No.", EntryHasCostCenterDimension, EntryHasCostObjectDimension);

        if not EntryHasCostTypeLink then begin
            // Delete the Cost Type -> the GL Account has no valid Cost Type associated
            CostType.Get(GLAccount."No.");
            CostType.Delete(true);
        end;

        // Exercise:
        PostGenJournalLine(GLAccount."No.", Amount, EntryHasClosingDate);
    end;

    [Normal]
    local procedure ValidateEntriesTransfered(): Integer
    var
        GLRegister: Record "G/L Register";
        CostRegister: Record "Cost Register";
        GLEntry: Record "G/L Entry";
        CostEntry: Record "Cost Entry";
    begin
        GLRegister.FindLast();

        // Find transferred G/L Entry
        GLEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        GLEntry.FindFirst();

        // Find corresponfing Cost Register entry
        CostRegister.SetFilter(Source, Format(CostRegister.Source::"Transfer from G/L"));
        CostRegister.FindLast();

        // Find corresponding Cost Entry
        CostEntry.SetRange("G/L Entry No.", GLEntry."Entry No.");
        CostEntry.FindFirst();

        Assert.AreEqual(GLEntry.Description, CostEntry.Description,
          StrSubstNo(ExpectedValueIsDifferentError, CostEntry.FieldName(Description)));

        exit(CostEntry."Entry No.");
    end;

    [Normal]
    local procedure ValidateTransfer(NoOfGLRegisters: Integer)
    var
        GLRegister: Record "G/L Register";
        CostRegister: Record "Cost Register";
        GLEntry: Record "G/L Entry";
        CostEntry: Record "Cost Entry";
        TotalAmount: Decimal;
    begin
        // Find G/L registers
        GLRegister.Find('+');
        GLRegister.Next(-NoOfGLRegisters + 1);

        // Find transferred G/L Entries
        GLEntry.SetFilter("Entry No.", '>=%1', GLRegister."From Entry No.");
        GLEntry.FindSet();

        // Find corresponfing Cost Register entry
        CostRegister.SetFilter(Source, Format(CostRegister.Source::"Transfer from G/L"));
        CostRegister.FindLast();

        // Find corresponding Cost Entries
        CostEntry.SetRange("Entry No.", CostRegister."From Cost Entry No.", CostRegister."To Cost Entry No.");
        CostEntry.FindSet();

        // Validate Cost Entries fields
        repeat
            Assert.AreEqual(GLEntry."Entry No.", CostEntry."G/L Entry No.",
              StrSubstNo(ExpectedValueIsDifferentError, CostEntry.FieldName("G/L Entry No.")));
            Assert.AreEqual(GLEntry.Amount, CostEntry.Amount,
              StrSubstNo(ExpectedValueIsDifferentError, CostEntry.FieldName(Amount)));
            TotalAmount := TotalAmount + CostEntry.Amount;
            GLEntry.Next(2);
        until CostEntry.Next() = 0;

        // Validate Cost Register fields
        Assert.AreEqual(CostRegister."To Cost Entry No." - CostRegister."From Cost Entry No." + 1, CostRegister."No. of Entries",
          StrSubstNo(ExpectedValueIsDifferentError, CostRegister.FieldName("No. of Entries")));
        Assert.AreEqual(TotalAmount, CostRegister."Debit Amount",
          StrSubstNo(ExpectedValueIsDifferentError, CostRegister.FieldName("Debit Amount")));
    end;

    [Normal]
    local procedure ValidateCostEntryFields(CostEntryNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        CostCenter: Record "Cost Center";
        CostEntry: Record "Cost Entry";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        CostEntry.Get(CostEntryNo);
        GLEntry.Get(CostEntry."G/L Entry No.");
        DimensionSetEntry.Get(GLEntry."Dimension Set ID", CostCenterDimension());

        // check if corresponding cost center exists first
        CostCenter.SetFilter(Code, DimensionSetEntry."Dimension Value Code");
        if CostCenter.FindFirst() then
            Assert.AreEqual(DimensionSetEntry."Dimension Value Code", CostEntry."Cost Center Code",
              StrSubstNo(ExpectedValueIsDifferentError, CostEntry.FieldName("Cost Center Code")));

        Assert.AreEqual('', CostEntry."Cost Object Code",
          StrSubstNo(ExpectedValueIsDifferentError, CostEntry.FieldName("Cost Object Code")));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
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

