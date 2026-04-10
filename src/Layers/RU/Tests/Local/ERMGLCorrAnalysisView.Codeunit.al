codeunit 144100 "ERM G/L Corr. Analysis View"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        IncorrectValueErr: Label 'Incorrect Value of %1';
        IncorrectEntryCountErr: Label 'Incorrect count of entries';
        RoundingFactorOptionTxt: Label 'None';
        StartPeriodErr: Label 'Start period wrong.';
        EndPeriodErr: Label 'End period wrong.';
        DimensionCategory: Option "Dimension 1","Dimension 2","Dimension 3";
        ClosingDateOptions: Option Include,Exclude;
        ShowAmounts: Option "Actual Amounts","Budgeted Amounts",Variance,"Variance%","Index%",Amounts;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionRoundingFactorNone()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // Check Analysis By Dimension Matrix with Rounding Factor None.

        // Setup: Create General Line and Analysis View with Dimension.
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(-GenJournalLine.Amount);
        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Analysis View Dimension Matrix for Rounding Factor None with AnalysisByDimensionMatrixPageHandler.
        OpenAnalysisByDimension(AnalysisViewCode, RoundingFactorOptionTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionRoundingFactor1()
    begin
        // Check Analysis By Dimension Matrix with Rounding Factor 1 with Rounding Value 1.
        // Rounding Value is required as per Page.
        Initialize();
        OpenAndVerifyAnalysisByDimension(1, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionRoundingFactor1000()
    begin
        // Check Analysis By Dimension Matrix with Rounding Factor 1000 with Rounding Value 0.1.
        // Rounding Value is required as per Page.
        Initialize();
        OpenAndVerifyAnalysisByDimension(1000, 0.1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionRoundingFactor1000000()
    begin
        // Check Analysis By Dimension Matrix with Rounding Factor 1000000 with Rounding Value 0.1.
        // Rounding Value is required as per Page.
        Initialize();
        OpenAndVerifyAnalysisByDimension(1000000, 0.1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionByPeriodTotalAmountCorrect()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        Initialize();
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(-GenJournalLine.Amount);

        AnalysisViewCode :=
          CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        OpenAnalysisByDimensionWithLineDimCode(
          AnalysisViewCode, RoundingFactorOptionTxt, ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionExcludeClosingEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        Initialize();

        CreateGeneralLineWithGLAccount(GenJournalLine);
        GenJournalLine.Validate("Posting Date", FindLastFYClosingDate());
        GenJournalLine.Modify();
        LibraryVariableStorage.Enqueue(0);

        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        OpenAnalysisByDimensionWithLineDimCode(
          AnalysisViewCode, RoundingFactorOptionTxt, ClosingDateOptions::Exclude, ShowAmounts::"Actual Amounts", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionShowsAmountLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // [SCENARIO 122162] Analysis By Dimension Matrix shows Amounts in LCY after Gen. Journal posting with Currency
        Initialize();

        // [GIVEN] Create and post general journal line with Currency and AmountLCY = "A"
        CreateGeneralLineWithGLAccount(GenJournalLine);
        GenJournalLine.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        GenJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(-GenJournalLine."Amount (LCY)");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create new Analysis View
        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        // [WHEN] Open Analysis By Dimension Matrix
        OpenAnalysisByDimension(AnalysisViewCode, RoundingFactorOptionTxt);

        // [THEN] Analysis By Dimension Matrix Amount = "A"
        // Verify amount in AnalysisByDimensionMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnalysisByDimensionFilterDimTotaling()
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        DimensionValueTotal: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Analysis by Dimensions] [UI]
        // [SCENARIO 372110] Filter Dimension Value with type End-Total in the Analysis by Dimension Matrix page
        Initialize();

        // [GIVEN] Analysis View for G/L Account = "G" and "Dimension 1 Code" = new Dimension "Dim"
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        GLCorrAnalysisView.Get(
          CreateAnalysisViewWithCertainDimension(GLAccountNo, DimensionCategory::"Dimension 1"));

        // [GIVEN] Dimension Values "D1", "D2" Dimension "Dim"
        LibraryDimension.CreateDimensionValue(DimensionValue1, GLCorrAnalysisView."Debit Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue2, GLCorrAnalysisView."Debit Dimension 1 Code");

        // [GIVEN] Dimension Value with type End-Total and Totaling = "D1".."D2"
        LibraryDimension.CreateDimensionValue(DimensionValueTotal, GLCorrAnalysisView."Debit Dimension 1 Code");
        DimensionValueTotal.Validate("Dimension Value Type", DimensionValueTotal."Dimension Value Type"::"End-Total");
        DimensionValueTotal.Validate(Totaling, StrSubstNo('%1..%2', DimensionValue1.Code, DimensionValue2.Code));
        DimensionValueTotal.Modify(true);

        // [GIVEN] Posted Entries for G/L Account = "G" with Amounts = "X1" for "D1" dimension, "X2" for "D2" dimension
        TotalAmount :=
          CreateAndPostJournalLineWithDimension(DimensionValue1, GLAccountNo, GenJournalLine."Account Type"::"G/L Account");
        TotalAmount +=
          CreateAndPostJournalLineWithDimension(DimensionValue2, GLAccountNo, GenJournalLine."Account Type"::"G/L Account");
        LibraryVariableStorage.Enqueue(TotalAmount);

        // [WHEN] Open Analysis by Dimension Matrix page
        OpenAnalysisByDimensionWithLineDimCode(
          GLCorrAnalysisView.Code, RoundingFactorOptionTxt, ClosingDateOptions::Include,
          ShowAmounts::"Actual Amounts", DimensionValueTotal.Code);

        // [THEN] Analysis By Dimension Matrix Amount = Total Amount = "X1" + "X2"
        // Verification is done in AnalysisByDimensionMatrixPageHandler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateGLCorrViewEntries()
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
    begin
        // Verify Last Entry No updated with Update G/L Corr. Analysis View
        Initialize();
        InitGLCorrView(GLCorrAnalysisView);

        Assert.AreNotEqual(
          0, GLCorrAnalysisView."Last Entry No.",
          StrSubstNo(IncorrectValueErr, GLCorrAnalysisView.FieldCaption("Last Entry No.")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateGLCorrViewEntriesForGlAcc()
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        EntryCount: Integer;
    begin
        // Check GLCorrAnalysisViewEntry descreased after filtering by G/L Account
        Initialize();
        InitGLCorrView(GLCorrAnalysisView);
        EntryCount := GLCorrAnalysisViewEntry.Count();

        UpdateCorrViewGLAcc(GLCorrAnalysisView);

        Assert.IsTrue(EntryCount > GLCorrAnalysisViewEntry.Count, IncorrectEntryCountErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateGLCorrViewEntriesForBusUnit()
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
    begin
        // Check GLCorrAnalysisViewEntry is empty after filtering with new Business Unit
        Initialize();
        InitGLCorrView(GLCorrAnalysisView);

        UpdateCorrViewBusUnit(GLCorrAnalysisView);

        Assert.IsTrue(GLCorrAnalysisViewEntry.IsEmpty, IncorrectEntryCountErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateGLCorrViewEntriesForDebitDimension()
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        EntryCount: Integer;
    begin
        // Check GLCorrAnalysisViewEntry has different count after changing "Debit Dimension 1 Code"
        Initialize();
        InitGLCorrView(GLCorrAnalysisView);
        EntryCount := GLCorrAnalysisViewEntry.Count();

        UpdateCorrViewDebitDimension(GLCorrAnalysisView);

        Assert.AreNotEqual(EntryCount, GLCorrAnalysisViewEntry.Count, IncorrectEntryCountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckAnalysisViewWithInternalDateFilter()
    var
        ItemAnalysisView: Record "Item Analysis View";
        DimCodeBuf: Record "Dimension Code Buffer";
        Item: Record Item;
        ItemAnalysisMgt: Codeunit "Item Analysis Management";
        DateFilter: Text[30];
        InternalDateFilter: Text[30];
        DimOption: Enum "Item Analysis Dimension Type";
        PeriodType: Enum "Analysis Period Type";
        PeriodStart: Date;
        PeriodEnd: Date;
        PeriodInitialized: Boolean;
    begin
        // Check that 'FindRec' function in 'Item Analysis Management' returns right period in DimCodeBuf

        // Setup
        ItemAnalysisView.Init();
        PeriodInitialized := true;
        DimOption := DimOption::Period;
        PeriodType := PeriodType::Month;
        PeriodStart := CalcDate('<-CM>', WorkDate());
        PeriodEnd := CalcDate('<+1Y-1D>', PeriodStart);

        DateFilter := '';
        Item.SetRange("Date Filter", PeriodStart, PeriodEnd);
        InternalDateFilter := CopyStr(Item.GetFilter("Date Filter"), 1, MaxStrLen(InternalDateFilter));

        // Exercize
        ItemAnalysisMgt.FindRecord(
          ItemAnalysisView, DimOption, DimCodeBuf, '', '', '',
          PeriodType, DateFilter, PeriodInitialized, InternalDateFilter, '', '', '');

        // Verify
        Assert.AreEqual(PeriodStart, DimCodeBuf."Period Start", StartPeriodErr);
        Assert.AreEqual(CalcDate('<+1M-1D>', PeriodStart), DimCodeBuf."Period End", EndPeriodErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VerifyAnalysisViewEntry()
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
        GLCorrEntry: Record "G/L Correspondence Entry" temporary;
        GLCorrAnViewEntrToGLCorrEntr: Codeunit GLCorrAnViewEntrToGLCorrEntr;
    begin
        // Unit test to verify Amount in GLCorrAnalysisViewEntry matches GLCorrEntry.Amount
        InitGLCorrView(GLCorrAnalysisView);
        GLCorrAnalysisViewEntry.FindFirst();
        GLCorrAnViewEntrToGLCorrEntr.GetGLCorrEntries(GLCorrAnalysisViewEntry, GLCorrEntry);

        GLCorrEntry.SetCurrentKey("Debit Account No.", "Credit Account No.", "Posting Date");
        GLCorrEntry.CalcSums(Amount);
        Assert.AreEqual(
          GLCorrEntry.Amount, GLCorrAnalysisViewEntry.Amount,
          StrSubstNo(IncorrectValueErr, GLCorrAnalysisViewEntry.FieldCaption(Amount)));
    end;

    local procedure Initialize()
    var
        GLCorrAnalysisViewEntry: Record "G/L Corr. Analysis View Entry";
    begin
        GLCorrAnalysisViewEntry.DeleteAll();

        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateAnalysisView(var GLCorrAnalysisView: Record "G/L Corr. Analysis View")
    begin
        GLCorrAnalysisView.Init();
        GLCorrAnalysisView.Code := LibraryUtility.GenerateGUID();
        GLCorrAnalysisView.Insert(true);
    end;

    local procedure CreateAnalysisViewWithDimension(AccountFilter: Code[250]): Code[10]
    begin
        exit(CreateAnalysisViewWithCertainDimension(AccountFilter, 1));
    end;

    local procedure CreateAnalysisViewWithCertainDimension(AccountFilter: Code[250]; DimensionOption: Option): Code[10]
    var
        GLCorrAnalysisView: Record "G/L Corr. Analysis View";
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        CreateAnalysisView(GLCorrAnalysisView);
        GLCorrAnalysisView.Validate("Debit Account Filter", AccountFilter);
        case DimensionOption of
            DimensionCategory::"Dimension 1":
                GLCorrAnalysisView.Validate("Debit Dimension 1 Code", Dimension.Code);
            DimensionCategory::"Dimension 2":
                GLCorrAnalysisView.Validate("Debit Dimension 2 Code", Dimension.Code);
            DimensionCategory::"Dimension 3":
                GLCorrAnalysisView.Validate("Debit Dimension 3 Code", Dimension.Code);
        end;
        GLCorrAnalysisView.Modify(true);
        exit(GLCorrAnalysisView.Code);
    end;

    local procedure CreateGeneralLineWithGLAccount(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        // Using Random Number Generator for Amount.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJournalLineWithDimension(var GenJournalLine: Record "Gen. Journal Line"; DimensionValue: Record "Dimension Value"; AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindJournalBatchAndTemplate(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, AccountType, AccountNo);
        GenJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostJournalLineWithDimension(DimensionValue: Record "Dimension Value"; AccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateJournalLineWithDimension(GenJournalLine, DimensionValue, AccountNo, AccountType);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine.Amount);
    end;

    local procedure FindJournalBatchAndTemplate(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure OpenAnalysisByDimension("Code": Code[10]; RoundingFactor: Text[30])
    begin
        OpenAnalysisByDimensionWithLineDimCode(
          Code, RoundingFactor, ClosingDateOptions::Include, ShowAmounts::"Actual Amounts", '');
    end;

    local procedure OpenAnalysisByDimensionWithLineDimCode("Code": Code[10]; RoundingFactor: Text[30]; ClosingDates: Option; AmountType: Option; Dim1Filter: Code[250])
    var
        GLCorrAnalysisViewList: TestPage "G/L Corr. Analysis View List";
        GLCorrAnalysisByDim: TestPage "G/L Corr. Analysis by Dim.";
    begin
        GLCorrAnalysisViewList.OpenView();
        GLCorrAnalysisViewList.FILTER.SetFilter(Code, Code);
        GLCorrAnalysisViewList."&Update".Invoke();
        GLCorrAnalysisByDim.Trap();
        GLCorrAnalysisViewList.EditAnalysis.Invoke();
        GLCorrAnalysisByDim.RoundingFactor.SetValue(RoundingFactor);
        GLCorrAnalysisByDim.AmountType.SetValue(AmountType);
        GLCorrAnalysisByDim.DebitDim1Filter.SetValue(Dim1Filter);
        GLCorrAnalysisByDim.ClosingEntryFilter.SetValue(ClosingDates);
        // GLCorrAnalysisByDim.ShowMatrix.Invoke();
    end;

    local procedure OpenAndVerifyAnalysisByDimension(RoundingFactor: Integer; Precision: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        AnalysisViewCode: Code[10];
    begin
        // Setup: Create General Line and Analysis View with Dimension.
        CreateGeneralLineWithGLAccount(GenJournalLine);
        LibraryVariableStorage.Enqueue(Round(-GenJournalLine.Amount / RoundingFactor, Precision));
        AnalysisViewCode := CreateAnalysisViewWithDimension(GenJournalLine."Bal. Account No.");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Analysis View Dimension Matrix for different Rounding Factor with AnalysisByDimensionMatrixPageHandler.
        OpenAnalysisByDimension(AnalysisViewCode, Format(RoundingFactor));
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure FindLastFYClosingDate(): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetCurrentKey("New Fiscal Year");
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindLast();
        exit(ClosingDate(AccountingPeriod."Starting Date" - 1));
    end;

    local procedure InitGLCorrView(var GLCorrAnalysisView: Record "G/L Corr. Analysis View")
    begin
        CreateGLCorrView(GLCorrAnalysisView);
        CODEUNIT.Run(CODEUNIT::"Update G/L Corr. Analysis View", GLCorrAnalysisView);
        GLCorrAnalysisView.Find();
    end;

    local procedure CreateGLCorrView(var GLCorrAnalysisView: Record "G/L Corr. Analysis View")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.FindDimension(Dimension);

        GLCorrAnalysisView.Code := LibraryUtility.GenerateGUID();
        GLCorrAnalysisView.Insert(true);
        GLCorrAnalysisView.Validate("Debit Dimension 1 Code", Dimension.Code);
        GLCorrAnalysisView.Modify(true);
    end;

    local procedure UpdateCorrViewGLAcc(var GLCorrAnalysisView: Record "G/L Corr. Analysis View")
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
    begin
        GLCorrEntry.FindFirst();
        GLCorrAnalysisView.Validate("Debit Account Filter", GLCorrEntry."Debit Account No.");
        GLCorrAnalysisView.Modify(true);
    end;

    local procedure UpdateCorrViewBusUnit(var GLCorrAnalysisView: Record "G/L Corr. Analysis View")
    var
        BusinessUnit: Record "Business Unit";
    begin
        LibraryERM.CreateBusinessUnit(BusinessUnit);
        GLCorrAnalysisView.Validate("Business Unit Filter", BusinessUnit.Code);
        GLCorrAnalysisView.Modify(true);
    end;

    local procedure UpdateCorrViewDebitDimension(var GLCorrAnalysisView: Record "G/L Corr. Analysis View")
    var
        Dimension: Record Dimension;
    begin
        Dimension.SetFilter(Code, '<>%1', GLCorrAnalysisView."Debit Dimension 1 Code");
        Dimension.FindFirst();
        GLCorrAnalysisView.Validate("Debit Dimension 1 Code", Dimension.Code);
        GLCorrAnalysisView.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Text: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

