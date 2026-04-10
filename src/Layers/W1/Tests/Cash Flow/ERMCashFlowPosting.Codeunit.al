codeunit 134554 "ERM Cash Flow - Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cash Flow]
    end;

    var
        CFHelper: Codeunit "Library - Cash Flow Helper";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryCF: Codeunit "Library - Cash Flow";
        LibraryERM: Codeunit "Library - ERM";
        RecordNotDeleted: Label 'Records in table %1 was not deleted.';
        BeforeAndAfterCounter: Label 'Counters dosn''t match: before: %1 and after: %2.';
        WrongAmounta: Label 'Amounts before and after posting dosn''t match.';

    [Test]
    [Scope('OnPrem')]
    procedure Test_CFJnlPostBatch()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CounterBefore: Integer;
        CounterAfter: Integer;
        AmountBefore: Decimal;
        AmountAfter: Decimal;
        ConsiderSource: array[16] of Boolean;
    begin
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        ConsiderAllSources(ConsiderSource);
        CFHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", false);

        CFWorksheetLine.SetCurrentKey("Cash Flow Forecast No.");
        CFWorksheetLine.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CounterBefore := CFWorksheetLine.Count();
        CFWorksheetLine.CalcSums("Amount (LCY)");
        AmountBefore := CFWorksheetLine."Amount (LCY)";

        PostBatch(CFWorksheetLine);
        // Validate results
        CFForecastEntry.SetCurrentKey("Cash Flow Forecast No.");
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CounterAfter := CFForecastEntry.Count();
        CFForecastEntry.CalcSums("Amount (LCY)");
        AmountAfter := CFForecastEntry."Amount (LCY)";

        Assert.AreEqual(CounterBefore, CounterAfter, StrSubstNo(BeforeAndAfterCounter, CounterBefore, CounterAfter));
        Assert.AreEqual(AmountBefore, AmountAfter, WrongAmounta);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_CF_OnDelete()
    var
        CFAccountComment: Record "Cash Flow Account Comment";
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        ConsiderSource: array[16] of Boolean;
    begin
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);

        CFAccountComment."Table Name" := CFAccountComment."Table Name"::"Cash Flow Forecast";
        CFAccountComment."No." := CashFlowForecast."No.";
        CFAccountComment."Line No." := 1;
        CFAccountComment.Comment := CashFlowForecast."No.";
        CFAccountComment.Insert();

        ConsiderAllSources(ConsiderSource);
        CFHelper.FillJournal(ConsiderSource, CashFlowForecast."No.", false);

        CFWorksheetLine.SetCurrentKey("Cash Flow Forecast No.");
        CFWorksheetLine.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        PostBatch(CFWorksheetLine);

        CashFlowForecast.Delete(true);
        // Validate results
        CFAccountComment.Reset();
        CFAccountComment.SetRange("Table Name", CFAccountComment."Table Name"::"Cash Flow Forecast");
        CFAccountComment.SetRange("No.", CashFlowForecast."No.");
        Assert.AreEqual(0, CFAccountComment.Count, StrSubstNo(RecordNotDeleted, CFAccountComment.TableCaption()));

        CFForecastEntry.SetCurrentKey("Cash Flow Forecast No.");
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        Assert.AreEqual(0, CFForecastEntry.Count, StrSubstNo(RecordNotDeleted, CFForecastEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingWithEmptyBudgetName()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        // Setup
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CreateGLBudgetCFWorksheetLine(GLBudgetEntry, CFWorksheetLine, CashFlowForecast, LibraryRandom.RandDec(100, 2));

        // Exercise
        CFWorksheetLine.Validate("G/L Budget Name", '');
        CFWorksheetLine.Modify();

        // Verify
        asserterror LibraryCF.PostJournalLines(CFWorksheetLine);
        Assert.ExpectedError(StrSubstNo('%1 must have a value in', CFWorksheetLine."G/L Budget Name"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostingBudgetNameForNotBudgetSourceType()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        GLBudgetEntry: Record "G/L Budget Entry";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
    begin
        // Setup
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        CreateGLBudgetCFWorksheetLine(GLBudgetEntry, CFWorksheetLine, CashFlowForecast, LibraryRandom.RandDec(100, 2));

        // Exercise
        CFWorksheetLine.Validate("Source Type", LibraryRandom.RandIntInRange(1, CFWorksheetLine."Source Type"::"G/L Budget".AsInteger() - 1));
        CFWorksheetLine.Modify();
        LibraryCF.PostJournalLines(CFWorksheetLine);

        // Verify
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.FindFirst();
        CFForecastEntry.TestField("G/L Budget Name", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateGLBudgetEntries()
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        GLBudgetEntry: Record "G/L Budget Entry";
        ExpectedAmount: Decimal;
    begin
        // Setup
        CFHelper.CreateCashFlowForecastDefault(CashFlowForecast);
        ExpectedAmount := LibraryRandom.RandDec(100, 2);
        CreateGLBudgetCFWorksheetLine(GLBudgetEntry, CFWorksheetLine, CashFlowForecast, -ExpectedAmount);

        // Exercise
        LibraryCF.PostJournalLines(CFWorksheetLine);

        // Verify
        CFForecastEntry.SetRange("Cash Flow Forecast No.", CashFlowForecast."No.");
        CFForecastEntry.FindFirst();
        CFForecastEntry.TestField("Source Type", CFForecastEntry."Source Type"::"G/L Budget");
        CFForecastEntry.TestField("G/L Budget Name", GLBudgetEntry."Budget Name");
        CFHelper.VerifyExpectedCFAmount(-ExpectedAmount, CFForecastEntry."Amount (LCY)");
    end;

    local procedure CreateGLBudgetCFWorksheetLine(var GLBudgetEntry: Record "G/L Budget Entry"; var CFWorksheetLine: Record "Cash Flow Worksheet Line"; var CashFlowForecast: Record "Cash Flow Forecast"; CashFlowAmount: Decimal)
    var
        CFAccount: Record "Cash Flow Account";
        GLAccount: Record "G/L Account";
        GLBudgetName: Record "G/L Budget Name";
    begin
        CFHelper.FindCFBudgetAccount(CFAccount);
        CFHelper.FindFirstGLAccFromCFAcc(GLAccount, CFAccount);
        LibraryERM.CreateGLBudgetName(GLBudgetName);
        LibraryERM.CreateGLBudgetEntry(GLBudgetEntry, CashFlowForecast."G/L Budget From", GLAccount."No.", GLBudgetName.Name);
        GLBudgetEntry.Validate(Amount, LibraryRandom.RandDec(100, 2));
        GLBudgetEntry.Modify(true);

        CFWorksheetLine.Init();
        CFWorksheetLine."Cash Flow Date" := WorkDate();
        CFWorksheetLine."Document No." := Format(LibraryRandom.RandInt(50));
        CFWorksheetLine."Cash Flow Forecast No." := CashFlowForecast."No.";
        CFWorksheetLine.Description := CFWorksheetLine."Document No.";
        CFWorksheetLine."Cash Flow Account No." := CFAccount."No.";
        CFWorksheetLine."Amount (LCY)" := CashFlowAmount;
        CFWorksheetLine."Source Type" := CFWorksheetLine."Source Type"::"G/L Budget";
        CFWorksheetLine."Source No." := GLAccount."No.";
        CFWorksheetLine."G/L Budget Name" := GLBudgetName.Name;
        CFWorksheetLine.Insert(true);
    end;

    local procedure ConsiderAllSources(var ConsiderSource: array[16] of Boolean)
    var
        SourceType: Integer;
    begin
        for SourceType := 1 to ArrayLen(ConsiderSource) do
            ConsiderSource[SourceType] := true;
    end;

    local procedure PostBatch(var CFWorksheetLine: Record "Cash Flow Worksheet Line")
    begin
        CFWorksheetLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Cash Flow Wksh.-Register Batch", CFWorksheetLine);
    end;
}

