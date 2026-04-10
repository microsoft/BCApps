codeunit 134828 "Dimension Filter Scenario Test"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension Filter] [Chart of Accounts]
    end;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        DimSetupArray: array[2, 4] of Code[20];
        NewGLAccountNo: Code[20];
        IsInitialized: Boolean;
        Dim3ValueCount: Integer;
        Dim4ValueCount: Integer;
        NotificationMsg: Label 'The view is filtered by dimensions:';

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerSingle,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterSingleDimValue()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code", DimSetupArray[1] [1]);
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(4000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 1, 3
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerSingle,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterWithOr()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code",
          StrSubstNo('%1|%2', DimSetupArray[1] [2], DimSetupArray[1] [3]));
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(12000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 2, 4, 6
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerSingle,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterWithOrDifferent()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code",
          StrSubstNo('%1|<>%2', DimSetupArray[1] [2], DimSetupArray[1] [3]));
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(51000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 1, 2, 3, 5, 6, 7, 8, 9, 10
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerSingle,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterWithOrDifferentAndNotBlank()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code",
          StrSubstNo('%1|<>%2&<>%3', DimSetupArray[1] [2], DimSetupArray[1] [3], ''''''));
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(30000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 1, 2, 3, 6, 8, 10
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerSingle,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterRangeDimValue()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code",
          StrSubstNo('%1..%2', DimSetupArray[1] [2], DimSetupArray[1] [4]));
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(30000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 2, 4, 6, 8, 10
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerSingle,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterSingleDimAnyDimValue()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        // '<>''''' behaves the same as ''
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code", '<>''''');
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(34000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 1, 2, 3, 4, 6, 8, 10
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerMultiple,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterMultipleDimSingleValuesNoMatch()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code", DimSetupArray[1] [1]);
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 4 Code", DimSetupArray[2] [1]);
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Assert.AreEqual('', ChartofAccounts."Net Change".Value, 'Net Change does not match the sum of the entries within the filter'); // no lines
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerMultiple,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterMultipleDimSingleValuesOneMatch()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code", DimSetupArray[1] [2]);
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 4 Code", DimSetupArray[2] [1]);
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(6000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 6
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerMultiple,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterMultipleDimMultipleMatch()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code", DimSetupArray[1] [4]);
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 4 Code",
          StrSubstNo('%1|%2', DimSetupArray[2] [2], DimSetupArray[2] [3]));
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(18000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 8, 10
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerMultiple,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterWithDim1AnyValueAndNoDim2()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code", '<>''''');
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 4 Code", '''''');
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(10000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 1, 2, 3, 4
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerMultiple,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterWithNoDim1AndDim2AnyValue()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code", '''''');
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 4 Code", '<>''''');
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(21000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 5, 7, 9
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerMultiple,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterWithDim1AnyValueAndDim2AnyValue()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code", '<>''''');
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 4 Code", '<>''''');
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(24000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 6, 8, 10
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerMultiple,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterWithDim1AnyValueOrDim2AnyValue()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code", '''''|<>''''');
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 4 Code", '''''|<>''''');
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(55000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerMultiple,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterWithDim1AndDim2()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code",
          StrSubstNo('%1..%2&<>%3|%4', DimSetupArray[1] [1], DimSetupArray[1] [3],
            DimSetupArray[1] [2], DimSetupArray[1] [4]));
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 4 Code",
          StrSubstNo('%1|%2|%3', DimSetupArray[2] [1], DimSetupArray[2] [3], DimSetupArray[2] [2]));
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(18000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 8, 10
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerRerun,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterIsMaintainedAfterCloseAndReopenPage()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();
        EnqueueDimensionCodeAndValueFilter('', '');
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code",
          StrSubstNo('%1|<>%2', DimSetupArray[1] [2], DimSetupArray[1] [3]));
        ChartofAccounts.SetDimensionFilter.Invoke();

        // Exercise
        LibraryVariableStorage.AssertEmpty();
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 3 Code",
          StrSubstNo('%1|<>%2', DimSetupArray[1] [2], DimSetupArray[1] [3]));
        EnqueueDimensionCodeAndValueFilter(GeneralLedgerSetup."Shortcut Dimension 4 Code",
          StrSubstNo('%1|<>%2', DimSetupArray[2] [1], DimSetupArray[2] [2]));
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(36000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 1, 2, 3, 5, 6, 9, 10
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerSingle')]
    [Scope('OnPrem')]
    procedure TestDimFilterSingleNonExistingDim()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DummyDimension: Record Dimension;
        ChartofAccounts: TestPage "Chart of Accounts";
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(LibraryUtility.GenerateRandomCode(DummyDimension.FieldNo(Code), DATABASE::Dimension), '');
        asserterror ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        Assert.ExpectedErrorCannotFind(Database::Dimension);
    end;

    [Test]
    [HandlerFunctions('DimSetFilterModalPageHandlerSingle,SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestDimFilterSingleAutoComplete()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
        NetChange: Decimal;
    begin
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // Setup
        GeneralLedgerSetup.Get();
        ChartofAccounts.OpenView();

        // Exercise
        EnqueueDimensionCodeAndValueFilter(
          CopyStr(GeneralLedgerSetup."Shortcut Dimension 3 Code", 1, StrLen(GeneralLedgerSetup."Shortcut Dimension 3 Code") - 2),
          DimSetupArray[1] [1]);
        ChartofAccounts.SetDimensionFilter.Invoke();
        // modal page handler

        // Verify
        ChartofAccounts.GotoKey(NewGLAccountNo);
        Evaluate(NetChange, ChartofAccounts."Net Change".Value);
        Assert.AreEqual(4000, NetChange, 'Net Change does not match the sum of the entries within the filter'); // line 1, 3
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Dimension Filter Scenario Test");
        LibraryVariableStorage.AssertEmpty();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Dimension Filter Scenario Test");

        NewGLAccountNo := CreateAndPostGenJnlLinesWithDimData();
        SetShowAmountsOnly();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Dimension Filter Scenario Test");
    end;

    local procedure EnqueueDimensionCodeAndValueFilter(DimCode: Text; DimensionValueFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(DimCode);
        LibraryVariableStorage.Enqueue(DimensionValueFilter);
    end;

    local procedure CreateAndPostGenJnlLinesWithDimData() GLAccountNo: Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GeneralLedgerSetup.Get();
        Dim3ValueCount := 4;
        Dim4ValueCount := 2;
        CreateDimensionWithDimensionValues(GeneralLedgerSetup."Shortcut Dimension 3 Code", Dim3ValueCount);
        CreateDimensionWithDimensionValues(GeneralLedgerSetup."Shortcut Dimension 4 Code", Dim4ValueCount);
        GeneralLedgerSetup.Modify();
        FillDimSetupArray(GeneralLedgerSetup."Shortcut Dimension 3 Code", 1);
        FillDimSetupArray(GeneralLedgerSetup."Shortcut Dimension 4 Code", 2);
        CreateDuplicateDimValues();

        CreateGenJnlTemplateAndBatch(GenJournalBatch);
        GLAccountNo := CreateAndPostGenJnlLines(GenJournalBatch);
    end;

    local procedure CreateDimensionWithDimensionValues(var DimensionCode: Code[20]; "Count": Integer)
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionCode := DimensionValue."Dimension Code";
        for i := 2 to Count do
            LibraryDimension.CreateDimensionValue(DimensionValue, DimensionCode);
    end;

    local procedure FillDimSetupArray(DimensionCode: Code[20]; i: Integer)
    var
        DimensionValue: Record "Dimension Value";
        j: Integer;
    begin
        j := 1;
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.FindSet();
        repeat
            DimSetupArray[i] [j] := DimensionValue.Code;
            j += 1;
        until DimensionValue.Next() = 0;
    end;

    local procedure CreateDuplicateDimValues()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        // duplicate value code in Dim3 and Dim4
        GeneralLedgerSetup.Get();
        DimensionValue.Get(GeneralLedgerSetup."Shortcut Dimension 3 Code", DimSetupArray[1] [Dim3ValueCount]);
        DimensionValue."Dimension Code" := GeneralLedgerSetup."Shortcut Dimension 4 Code";
        DimensionValue."Dimension Value ID" := 0;
        DimensionValue.Insert();
        Dim4ValueCount += 1;
        DimSetupArray[2] [Dim4ValueCount] := DimSetupArray[1] [Dim3ValueCount]
    end;

    local procedure CreateGenJnlTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := LibraryERM.CreateGLAccountNoWithDirectPosting();
        GenJournalBatch.Modify();
    end;

    local procedure CreateAndPostGenJnlLines(GenJournalBatch: Record "Gen. Journal Batch") GLAccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // Line1: DimCode3,Value1 Amount = 1000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 1000, 3, DimSetupArray[1] [1], 4, '');

        // Line2: DimCode3,Value2 Amount = 2000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 2000, 3, DimSetupArray[1] [2], 4, '');

        // Line3: DimCode3,Value1 Amount = 3000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 3000, 3, DimSetupArray[1] [1], 4, '');

        // Line4: DimCode3,Value3 Amount = 4000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 4000, 3, DimSetupArray[1] [3], 4, '');

        // Line5: DimCode4,Value1 Amount = 5000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 5000, 3, '', 4, DimSetupArray[2] [1]);

        // Line6: DimCode3,Value4,DimCode4,Value1 Amount = 6000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 6000, 3, DimSetupArray[1] [2], 4, DimSetupArray[2] [1]);

        // Line7: DimCode4,Value2 Amount = 7000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 7000, 3, '', 4, DimSetupArray[2] [2]);

        // Line8: DimCode3,Value4,DimCode4,Value2 Amount = 8000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 8000, 3, DimSetupArray[1] [4], 4, DimSetupArray[2] [2]);

        // Line9: DimCode4,Value3 Amount = 9000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 9000, 3, '', 4, DimSetupArray[2] [3]);

        // Line10: DimCode3,Value4,DimCode4,Value3 Amount = 10000
        CreateGenJnlLineWithDimInfo(GenJournalBatch, GLAccountNo, 10000, 3, DimSetupArray[1] [4], 4, DimSetupArray[2] [3]);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindLast();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJnlLineWithDimInfo(GenJournalBatch: Record "Gen. Journal Batch"; GLAccountNo: Code[20]; Amount: Decimal; DimShortCutId: Integer; DimValueCode: Code[20]; DimShortCutId2: Integer; DimValueCode2: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGeneralJnlLine2(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountNo, Amount);
        GenJournalLine.ValidateShortcutDimCode(DimShortCutId, DimValueCode);
        GenJournalLine.ValidateShortcutDimCode(DimShortCutId2, DimValueCode2);
        GenJournalLine.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimSetFilterModalPageHandlerSingle(var DimensionSetIDFilter: TestPage "Dimension Set ID Filter")
    begin
        SetDimCodeAndFilterOnDimFilterPage(DimensionSetIDFilter, LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText());
        DimensionSetIDFilter.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimSetFilterModalPageHandlerMultiple(var DimensionSetIDFilter: TestPage "Dimension Set ID Filter")
    begin
        SetDimCodeAndFilterOnDimFilterPage(DimensionSetIDFilter, LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText());
        SetDimCodeAndFilterOnDimFilterPage(DimensionSetIDFilter, LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText());
        DimensionSetIDFilter.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimSetFilterModalPageHandlerRerun(var DimensionSetIDFilter: TestPage "Dimension Set ID Filter")
    begin
        DimensionSetIDFilter.GotoKey(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), DimensionSetIDFilter.DimensionValueFilter.Value,
          'The page opened with an unexpected dimension value filter');

        SetDimCodeAndFilterOnDimFilterPage(DimensionSetIDFilter, LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText());
        DimensionSetIDFilter.OK().Invoke();
    end;

    local procedure SetDimCodeAndFilterOnDimFilterPage(var DimensionSetIDFilter: TestPage "Dimension Set ID Filter"; DimCode: Text; DimValueFilter: Text)
    begin
        DimensionSetIDFilter.New();
        DimensionSetIDFilter.Code.SetValue(DimCode);
        DimensionSetIDFilter.DimensionValueFilter.SetValue(DimValueFilter);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.AreNotEqual(0, StrPos(Notification.Message, NotificationMsg), 'expected a different notification message');
        exit(true);
    end;

    local procedure SetShowAmountsOnly()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Show Amounts", GeneralLedgerSetup."Show Amounts"::"Amount Only");
        GeneralLedgerSetup.Modify();
    end;
}

