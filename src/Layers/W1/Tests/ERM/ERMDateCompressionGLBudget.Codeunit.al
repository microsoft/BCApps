codeunit 134037 "ERM Date Compression GL Budget"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Date Compression] [Period Length] [Budget]
    end;

    var
        DateComprRegister: Record "Date Compr. Register";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        IsInitialized: Boolean;
        CopyFromBudgetName: Code[10];
        FromBudgetEntryCount: Integer;
        FromBudgetEntryAmountSum: Decimal;

    [Test]
    [HandlerFunctions('HandleConfirm,HandleMessage')]
    [Scope('OnPrem')]
    procedure DateCompressionByDay()
    begin
        Initialize();
        DateCompressionScenario(DateComprRegister."Period Length"::Day);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm,HandleMessage')]
    [Scope('OnPrem')]
    procedure DateCompressionByWeek()
    begin
        Initialize();
        DateCompressionScenario(DateComprRegister."Period Length"::Week);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm,HandleMessage')]
    [Scope('OnPrem')]
    procedure DateCompressionByMonth()
    begin
        Initialize();
        DateCompressionScenario(DateComprRegister."Period Length"::Month);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm,HandleMessage')]
    [Scope('OnPrem')]
    procedure DateCompressionByYear()
    begin
        Initialize();
        DateCompressionScenario(DateComprRegister."Period Length"::Year);
    end;

    [Test]
    [HandlerFunctions('HandleConfirm,HandleMessage')]
    [Scope('OnPrem')]
    procedure DateCompressionByPeriod()
    begin
        Initialize();
        DateCompressionScenario(DateComprRegister."Period Length"::Period);
    end;

    local procedure AgeGLBudget(GLBudgetName: Code[10]; Year: Integer);
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName);
        if GLBudgetEntry.FindSet() then
            repeat
                GLBudgetEntry.Date := DMY2Date(Date2DMY(GLBudgetEntry.Date, 1), Date2DMY(GLBudgetEntry.Date, 2), Year);
                GLBudgetEntry.Modify();
            until GLBudgetEntry.Next() = 0;
    end;

    local procedure DateCompressionScenario(PeriodLength: Option)
    var
        GLBudgetName: Record "G/L Budget Name";
        BudgetYear: Integer;
    begin
        // Create a new budget and run copy budget batch to copy budget entry
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        CopyGLBudget(CopyFromBudgetName, GLBudgetName.Name, FromBudgetEntryCount, BudgetYear);

        // Run Date compression GL Budget for the newly created budget
        RunDateCompressBudget(GLBudgetName.Name, BudgetYear, PeriodLength);

        // Validate budget entry after compression
        ValidateBudgetEntry(GLBudgetName.Name, FromBudgetEntryCount, FromBudgetEntryAmountSum);
    end;

    local procedure CopyGLBudget(FromBudget: Code[10]; ToBudget: Code[10]; ExpectBudgetEntryCount: Integer; var BudgetYear: Integer)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        RunCopyGLBudget(FromBudget, ToBudget, '', 1);

        AgeGLBudget(ToBudget, Date2DMY(LibraryFiscalYear.GetFirstPostingDate(true), 3));

        GLBudgetEntry.SetRange("Budget Name", ToBudget);
        GLBudgetEntry.FindFirst();
        // Extract budget year
        BudgetYear := Date2DMY(GLBudgetEntry.Date, 3);

        // Test should not continue if the budget is not copied correctly.
        Assert.AreEqual(ExpectBudgetEntryCount, GLBudgetEntry.Count, 'Budget is not copied correctly');
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
        DimensionSelectionBuffer.SetDimSelection(3, REPORT::"Date Compr. G/L Budget Entries", '', RetainDimText, DimensionSelectionBuffer);
    end;

    local procedure RunCopyGLBudget(FromGLBudgetName: Code[10]; ToGlBudgetName: Code[10]; DateChange: Text; AdjFactor: Decimal)
    var
        CopyGLBudget: Report "Copy G/L Budget";
        FromSource: Option "G/L Entry","G/L Budget Entry";
        FromClosingEntryFilter: Option Include,Exclude;
        ToDateCompression: Option "None",Day,Week,Month,Quarter,Year,Period;
        DateChangeFormula: DateFormula;
    begin
        Evaluate(DateChangeFormula, DateChange);
        Clear(CopyGLBudget);
        CopyGLBudget.InitializeRequest(FromSource::"G/L Budget Entry", FromGLBudgetName, '', '', FromClosingEntryFilter::Include, '',
          ToGlBudgetName, '', AdjFactor, '', DateChangeFormula, ToDateCompression::None);
        CopyGLBudget.UseRequestPage(false);
        CopyGLBudget.Run();
    end;

    local procedure RunDateCompressBudget(BudgetName: Code[10]; Year: Integer; PeriodLength: Option)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        DateComprGLBudgetEntries: Report "Date Compr. G/L Budget Entries";
        StartingDate: Date;
        EndingDate: Date;
    begin
        Clear(DateComprGLBudgetEntries);
        GLBudgetEntry.SetRange("Budget Name", BudgetName);
        DateComprGLBudgetEntries.SetTableView(GLBudgetEntry);
        StartingDate := DMY2Date(1, 1, Year);
        EndingDate := DMY2Date(31, 12, Year);
        DateComprGLBudgetEntries.InitializeRequest(StartingDate, EndingDate, PeriodLength, '', false, InsertDimSelectionBuffer());
        DateComprGLBudgetEntries.UseRequestPage(false);
        DateComprGLBudgetEntries.Run();
    end;

    local procedure ValidateBudgetEntry(BudgetName: Code[10]; BeforeCompressEntryCount: Integer; ExpectedEntrySum: Decimal)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", Date);
        GLBudgetEntry.SetRange("Budget Name", BudgetName);

        Assert.IsTrue(BeforeCompressEntryCount > GLBudgetEntry.Count, 'No of compressed budget entry is not smaller than the original');

        GLBudgetEntry.CalcSums(Amount);
        Assert.AreEqual(ExpectedEntrySum, GLBudgetEntry.Amount, 'Sum of compressed Budget entry is not the same as the original');
    end;

    [Test]
    [HandlerFunctions('HandleConfirm,HandleMessage')]
    [Scope('OnPrem')]
    procedure CopyGLBudgetToItselfWithTimeShift()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        BudgetDate: Date;
        GLAccountNo: Code[20];
        I: Integer;
        NumOfPeriods: Integer;
        BudgetAmount: Decimal;
        AdjFactor: Decimal;
    begin
        // [FEATURE] [G/L Budget Entry]
        // [SCENARIO 262033] It is possible to copy G/L Budget to itself with time shift
        Initialize();

        // [GIVEN] G/L Budget with 5 entries of 1000
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        BudgetDate := WorkDate();
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        NumOfPeriods := LibraryRandom.RandIntInRange(3, 10);
        BudgetAmount := LibraryRandom.RandDecInRange(100, 1000, 1);
        AdjFactor := LibraryRandom.RandDecInRange(1, 3, 1);

        for I := 1 to NumOfPeriods do begin
            BudgetDate := CalcDate('<1M>', BudgetDate);
            LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, BudgetDate, GLAccountNo, GLBudgetName.Name);
            GLBudgetEntry.Amount := BudgetAmount;
            GLBudgetEntry.Modify();
        end;

        // [WHEN] Copy G/L Budget to itself with time shift and adjustment factor of 1.5
        RunCopyGLBudget(GLBudgetName.Name, GLBudgetName.Name, '<2M>', AdjFactor);

        // [THEN] 10 G/L entries in budget
        GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", Date);
        GLBudgetEntry.SetRange("Budget Name", GLBudgetName.Name);
        Assert.RecordCount(GLBudgetEntry, NumOfPeriods * 2);

        // [THEN] Sum of G/L Budget Entries is 12500
        GLBudgetEntry.CalcSums(Amount);
        GLBudgetEntry.TestField(Amount, Round(BudgetAmount * NumOfPeriods * (1 + AdjFactor)));
    end;

    local procedure Initialize()
    var
        GLBudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Date Compression GL Budget");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Date Compression GL Budget");
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        LibraryERMCountryData.CreateVATData();

        // Find a budget
        GLBudgetName.FindFirst();
        CopyFromBudgetName := GLBudgetName.Name;

        GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", Date);
        GLBudgetEntry.SetRange("Budget Name", CopyFromBudgetName);

        FromBudgetEntryCount := GLBudgetEntry.Count();
        GLBudgetEntry.CalcSums(Amount);
        FromBudgetEntryAmountSum := GLBudgetEntry.Amount;

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Date Compression GL Budget");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure HandleMessage(Message: Text[1024])
    begin
        // For handle message
    end;
}

