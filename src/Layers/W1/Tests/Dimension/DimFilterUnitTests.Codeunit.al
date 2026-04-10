codeunit 134822 "DimFilter Unit Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDim: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        DimensionMgt: Codeunit DimensionManagement;
        LibraryRandom: Codeunit "Library - Random";
        TestDataSetUp: Boolean;
        DimCode1: Code[20];
        DimCode2: Code[20];
        Text000: Label '%1 is not empty';
        DimCode3: Code[20];
        Text001: Label 'More than 1 entry exists in %1';
        Text002: Label '%1''s are not equal';
        Text003: Label '# of iterations are not equal';
        DimCode4: Code[20];
        Text004: Label '# of records is not 2 in %1';
        Text005: Label '%1 is empty';
        Text006: Label 'Number of records is not same in expected and actual table variables.';
        Text007: Label 'DimFilterChunk length should be 0 for invalid dimension value.';
        DimCode5: Code[20];
        DimCode6: Code[20];
        WrongCaptionErr: Label 'The caption for column %1 is wrong.';

    [Test]
    [Scope('OnPrem')]
    procedure TestClearDimSetFilter()
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        SetupTestData();
        DimensionMgt.GetDimSetIDsForFilter('', '');
        DimensionMgt.GetTempDimSetEntry(TempDimSetEntry);
        Assert.IsFalse(TempDimSetEntry.IsEmpty, StrSubstNo(Text005, TempDimSetEntry.TableCaption()));
        DimensionMgt.ClearDimSetFilter();
        DimensionMgt.GetTempDimSetEntry(TempDimSetEntry);
        Assert.IsTrue(TempDimSetEntry.IsEmpty, StrSubstNo(Text005, TempDimSetEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTempDimSetEntryEmpty()
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        // See if returns 0 records if none were added.
        DimensionMgt.ClearDimSetFilter();
        DimensionMgt.GetTempDimSetEntry(TempDimSetEntry);
        Assert.IsTrue(TempDimSetEntry.IsEmpty, StrSubstNo(Text000, TempDimSetEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTempDimSetEntryNonExist()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        // Try to add a nonexisting dimvalue
        DimensionMgt.ClearDimSetFilter();
        DimensionMgt.GetDimSetIDsForFilter(
          CopyStr(LibraryUtility.GenerateRandomCode(Dimension.FieldNo(Code), DATABASE::Dimension), 1, 20),
          LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value"));
        DimensionMgt.GetTempDimSetEntry(TempDimSetEntry);
        Assert.IsTrue(TempDimSetEntry.IsEmpty, StrSubstNo(Text000, TempDimSetEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTempDimSetEntrySingle()
    var
        DimensionValue: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        "Count": Integer;
    begin
        // Try to add a single DimSetID
        SetupTestData();
        Count := 1;
        AddDimSetIDsToTemp(DimensionValue, DimSetEntry, TempDimSetEntry, DimCode3, Count);
        Assert.AreEqual(0, TempDimSetEntry.Next(), StrSubstNo(Text001, TempDimSetEntry.TableCaption()));
        DimSetEntry.TestField("Dimension Code", DimCode3);
        DimSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
        Assert.AreEqual(Count, TempDimSetEntry."Dimension Value ID", Text003);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTempDimSetEntryDuplicat()
    var
        DimensionValue: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        "count": Integer;
    begin
        // Try to add the same DimSetID multiple times (between 2 and 10)
        SetupTestData();
        count := 1 + LibraryRandom.RandInt(9);
        AddDimSetIDsToTemp(DimensionValue, DimSetEntry, TempDimSetEntry, DimCode3, count);
        Assert.AreEqual(0, TempDimSetEntry.Next(), StrSubstNo(Text001, TempDimSetEntry.TableCaption()));
        DimSetEntry.TestField("Dimension Code", DimCode3);
        DimSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
        Assert.AreEqual(count, TempDimSetEntry."Dimension Value ID", Text003);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTempDimSetEntryMultiple()
    var
        DimensionValue: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimValueCode1: Code[20];
        DimValueCode2: Code[20];
        count1: Integer;
        count2: Integer;
    begin
        // Try to add different DimSetID's
        SetupTestData();
        count1 := 1 + LibraryRandom.RandInt(9);
        AddDimSetIDsToTemp(DimensionValue, DimSetEntry, TempDimSetEntry, DimCode3, count1);
        DimValueCode1 := DimensionValue.Code;

        count2 := 1 + LibraryRandom.RandInt(9);
        AddDimSetIDsToTemp(DimensionValue, DimSetEntry, TempDimSetEntry, DimCode4, count2);
        DimValueCode2 := DimensionValue.Code;

        Assert.AreEqual(2, TempDimSetEntry.Count, StrSubstNo(Text004, TempDimSetEntry.TableCaption()));

        TempDimSetEntry.FindFirst();
        repeat
            LibraryDim.FindDimensionSetEntry(DimSetEntry, TempDimSetEntry."Dimension Set ID");
            case DimSetEntry."Dimension Code" of
                DimCode3:
                    begin
                        DimSetEntry.TestField("Dimension Value Code", DimValueCode1);
                        Assert.AreEqual(count1, TempDimSetEntry."Dimension Value ID", Text003);
                    end;
                DimCode4:
                    begin
                        DimSetEntry.TestField("Dimension Value Code", DimValueCode2);
                        Assert.AreEqual(count2, TempDimSetEntry."Dimension Value ID", Text003);
                    end;
            end;
        until TempDimSetEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyFilter()
    var
        ExpectedDimSetEntry: Record "Dimension Set Entry";
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        ExpectedLastDimSetID: Integer;
        ActualFirstDimSetID: Integer;
        ActualLastDimSetID: Integer;
    begin
        // Empty filter includes all DimSetIDs in Table
        // Compare first and last DimSetIDs from expected and actualcreated by function
        SetupTestData();
        ExpectedDimSetEntry.FindLast();
        ExpectedLastDimSetID := ExpectedDimSetEntry."Dimension Set ID";

        CreateTempActualTable(TempActualDimSetEntry, '', '');

        TempActualDimSetEntry.FindFirst();
        ActualFirstDimSetID := TempActualDimSetEntry."Dimension Set ID";
        TempActualDimSetEntry.FindLast();
        ActualLastDimSetID := TempActualDimSetEntry."Dimension Set ID";

        Assert.AreEqual(0, ActualFirstDimSetID, StrSubstNo(Text002, ExpectedDimSetEntry.FieldCaption("Dimension Set ID")));
        Assert.AreEqual(
          ExpectedLastDimSetID, ActualLastDimSetID, StrSubstNo(Text002, ExpectedDimSetEntry.FieldCaption("Dimension Set ID")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimCodeEmptyValueFilter()
    var
        ExpectedDimSetEntry: Record "Dimension Set Entry";
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
    begin
        SetupTestData();
        CreateExpectedTable(ExpectedDimSetEntry, DimCode1, '');
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimCodeValueFilter()
    var
        ExpectedDimSetEntry: Record "Dimension Set Entry";
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        RandomDimValue: Code[20];
    begin
        SetupTestData();
        RandomDimValue := GetRandomDimValue(DimCode1);
        CreateExpectedTable(ExpectedDimSetEntry, DimCode1, RandomDimValue);
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, RandomDimValue);
        Assert.AreEqual(ExpectedDimSetEntry.Count, TempActualDimSetEntry.Count, Text006);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimCodeInvalidValueFilter()
    var
        ExpectedDimSetEntry: Record "Dimension Set Entry";
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValue: Record "Dimension Value";
        InvalidDimValue: Code[250];
    begin
        SetupTestData();
        InvalidDimValue := LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value");
        CreateExpectedTable(ExpectedDimSetEntry, DimCode1, InvalidDimValue);
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, InvalidDimValue);
        Assert.AreEqual(ExpectedDimSetEntry.Count, TempActualDimSetEntry.Count, Text006);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimCodeSmallerRangeValueF()
    var
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        RandomDimValue: Code[20];
    begin
        // Filter '..X' behaves as it has blank filter in string
        // so the result is all DimSetIDs without DimCode1 + smaller values than X for DimCode1
        SetupTestData();
        RandomDimValue := GetRandomDimValue(DimCode1);
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, RandomDimValue);
        Assert.IsFalse(CheckTempActualTable(TempActualDimSetEntry, DimCode1, RandomDimValue + '..'), Text006);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimCodeBiggerRangeValueF()
    var
        ExpectedDimSetEntry: Record "Dimension Set Entry";
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        RandomDimValue: Code[20];
    begin
        SetupTestData();
        RandomDimValue := GetRandomDimValue(DimCode1);
        CreateExpectedTable(ExpectedDimSetEntry, DimCode1, RandomDimValue + '..');
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, RandomDimValue + '..');
        Assert.AreEqual(ExpectedDimSetEntry.Count, TempActualDimSetEntry.Count, Text006);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimCodeValueOrBlankFilter()
    var
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        RandomDimValue: Code[20];
    begin
        // Filter 'X|''' behaves as it has blank filter in string
        // so the result is all DimSetIDs without DimCode1 + X for DimCode1
        SetupTestData();
        RandomDimValue := GetRandomDimValue(DimCode1);
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, RandomDimValue + '|''''');
        Assert.IsFalse(CheckTempActualTable(TempActualDimSetEntry, DimCode1, '<>' + RandomDimValue), Text006);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimCodeRangeValueFilter()
    var
        ExpectedDimSetEntry: Record "Dimension Set Entry";
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        MultipleDimValueFilter: Text[250];
    begin
        // A..C
        SetupTestData();
        CreateMultipleDimValueFilter(DimCode1, MultipleDimValueFilter, '..');
        CreateExpectedTable(ExpectedDimSetEntry, DimCode1, MultipleDimValueFilter);
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, MultipleDimValueFilter);
        Assert.AreEqual(ExpectedDimSetEntry.Count, TempActualDimSetEntry.Count, Text006);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDimCodeOrValueFilter()
    var
        ExpectedDimSetEntry: Record "Dimension Set Entry";
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        MultipleDimValueFilter: Text[250];
    begin
        // A|B
        SetupTestData();
        CreateMultipleDimValueFilter(DimCode1, MultipleDimValueFilter, '|');
        CreateExpectedTable(ExpectedDimSetEntry, DimCode1, MultipleDimValueFilter);
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, MultipleDimValueFilter);
        Assert.AreEqual(ExpectedDimSetEntry.Count, TempActualDimSetEntry.Count, Text006);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFilterInvalidDim()
    var
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValue: Record "Dimension Value";
        DimFilter: Text;
        InvalidDimValue: Code[250];
    begin
        // Invalid Dimension value should return an empty string
        SetupTestData();
        InvalidDimValue := LibraryUtility.GenerateRandomCode(DimensionValue.FieldNo(Code), DATABASE::"Dimension Value");
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, InvalidDimValue);
        DimFilter := DimensionMgt.GetDimSetFilter();
        Assert.AreEqual(0, StrLen(DimFilter), Text007);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFilterOneDimValue()
    var
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        DimFilter: Text;
    begin
        // FilterChunk with one Dimension Set ID.
        // DimCode4 has one dimension value
        // DimFiterChunk should not have a '|'
        SetupTestData();
        CreateTempActualTable(TempActualDimSetEntry, DimCode4, GetRandomDimValue(DimCode4));
        DimFilter := DimensionMgt.GetDimSetFilter();
        Assert.AreEqual(0, StrPos(DimFilter, '|'), StrSubstNo(Text001, TempActualDimSetEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFilterTwoDimValue()
    var
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        DimFilter: Text;
    begin
        // Filter Chunk with two Dimension Set ID
        // DimFilterChunk should have one '|'
        SetupTestData();
        CreateTempActualTable(TempActualDimSetEntry, DimCode5, GetRandomDimValue(DimCode5));
        DimFilter := DimensionMgt.GetDimSetFilter();
        Assert.AreEqual(0, StrPos(CopyStr(DimFilter, StrPos(DimFilter, '|') + 1), '|'),
          StrSubstNo(Text001, TempActualDimSetEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFilterMultiDimValue()
    var
        TempActualDimSetEntry: Record "Dimension Set Entry" temporary;
        DimFilter: Text;
    begin
        // DimCode1 has multiple dimension combinations
        // Compare the values in Temp table with FilterChunk
        SetupTestData();
        CreateTempActualTable(TempActualDimSetEntry, DimCode1, GetRandomDimValue(DimCode1));
        DimFilter := DimensionMgt.GetDimSetFilter();
        CompareTempTableAndFilter(TempActualDimSetEntry, DimFilter);
        Assert.AreEqual(0, TempActualDimSetEntry.Count, StrSubstNo(Text000, TempActualDimSetEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDimensionCombinationsCaptionName()
    var
        Dimension: Record Dimension;
        DimensionCombinations: TestPage "Dimension Combinations";
    begin
        // Test Column Name on Page Dimension Combinations

        // Setup : Create the Dimension Values.
        SetupTestData();

        // Exercise: Open Dimension Combinations Page and set Show Column Name.
        DimensionCombinations.OpenEdit();
        DimensionCombinations.ShowColumnName.SetValue(true);
        DimensionCombinations.MatrixForm.Next();
        Dimension.Get(DimensionCombinations.MatrixForm.Code.Value);
        // Verify : Verify the Value of Field.
        Assert.AreEqual(
          Dimension.Name, DimensionCombinations.MatrixForm.Field2.Caption,
          StrSubstNo(WrongCaptionErr, DimensionCombinations.MatrixForm.Name));
    end;

    [Test]
    [HandlerFunctions('MyDimValueCombinationsPageHandler')]
    [Scope('OnPrem')]
    procedure CheckMyDimValueCombinationCaptionName()
    var
        MyDimValueCombinations: Page "MyDim Value Combinations";
        FirstDimCode: Code[20];
        SecondDimCode: Code[20];
    begin
        // Test Column Name on My DimValue Combinations

        // Setup : Create the Dimension Values.
        FirstDimCode := CreateDimension();
        SecondDimCode := CreateDimension();
        CreateDimensionValues(FirstDimCode, 2);
        CreateDimensionValues(SecondDimCode, 2);

        // Exercise and Verify : Open Page and verify the Value of Field.
        MyDimValueCombinations.Load(FirstDimCode, SecondDimCode, false);
        MyDimValueCombinations.RunModal();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoDimErrOnDimensionCombinations()
    var
        Dimension: Record Dimension;
        DimensionCombinations: TestPage "Dimension Combinations";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 213937] If there is no Dimension for Company, error should appear on openning "Dimension Combination" page

        // [GIVEN] Delete the Dimension Values.
        Dimension.DeleteAll();

        // [WHEN] Open "Dimension Combinations" page
        asserterror DimensionCombinations.OpenEdit();

        // [THEN] "No dimensions are available in the database." error appears
        Assert.ExpectedError('No dimensions are available in the database.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialCharactersInDimFilterForAccScheduleOverview()
    var
        AccScheduleOverview: TestPage "Acc. Schedule Overview";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 312912] Set Dimension Value with dot in the value as Department Filter on page "Acc. Schedule Overview".

        // [GIVEN] Dimension Value with Code "=A<B>.C@ &D(E)F"|" for Department Dimension.
        // [WHEN] Set this Dimension Value as Department Filter on page "Acc. Schedule Overview" using Lookup.
        AccScheduleOverview.OpenEdit();
        AccScheduleOverview.Dim1Filter.SetValue('''=A<B>.C@ &D(E)F"|''');

        // [THEN] Department Filter value is '=A<B>.C@ &D(E)F"|'.
        Assert.AreEqual('''=A<B>.C@ &D(E)F"|''', AccScheduleOverview.Dim1Filter.Value, '');
    end;

    local procedure SetupTestData()
    begin
        DimensionMgt.ClearDimSetFilter();
        if TestDataSetUp then
            exit;

        DimCode1 := CreateDimension();
        DimCode2 := CreateDimension();
        DimCode3 := CreateDimension();
        DimCode4 := CreateDimension();
        DimCode5 := CreateDimension();
        DimCode6 := CreateDimension();
        CreateDimensionValues(DimCode1, 26);
        CreateDimensionValues(DimCode2, 26);
        CreateDimensionValues(DimCode3, 1);
        CreateDimensionValues(DimCode4, 1);
        CreateDimensionValues(DimCode5, 1);
        CreateDimensionValues(DimCode6, 2);
        CreateDimensionSetIDs(DimCode1);
        CreateDimensionSetIDs(DimCode2);
        CreateDimensionSetIDs(DimCode3);
        CreateDimensionSetIDs(DimCode4);
        CreateDimensionSetIDs(DimCode6);
        CreateCombDimensionSetIDs(DimCode1, DimCode2);
        CreateCombDimensionSetIDs(DimCode6, DimCode5);

        TestDataSetUp := true;
    end;

    local procedure CreateDimension(): Code[20]
    var
        Dimension: Record Dimension;
    begin
        LibraryDim.CreateDimension(Dimension);
        exit(Dimension.Code);
    end;

    local procedure CreateDimensionValues(DimCode: Code[20]; NumberOfDimValues: Integer)
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        for i := 1 to NumberOfDimValues do
            LibraryDim.CreateDimensionValue(DimensionValue, DimCode);
    end;

    local procedure CreateDimensionSetIDs(DimCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetFilter("Dimension Code", '%1', DimCode);
        if DimensionValue.FindSet() then
            repeat
                LibraryDim.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code)
            until DimensionValue.Next() = 0;
    end;

    local procedure CreateCombDimensionSetIDs(BaseDimCode: Code[20]; AddDimCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
        LastDimSetID: Integer;
    begin
        DimensionSetEntry.FindLast();
        LastDimSetID := DimensionSetEntry."Dimension Set ID";

        DimensionValue.SetFilter("Dimension Code", '%1', AddDimCode);
        if DimensionValue.FindSet() then
            repeat
                DimensionSetEntry.SetFilter("Dimension Code", '%1', BaseDimCode);
                DimensionSetEntry.SetRange("Dimension Set ID", 0, LastDimSetID);
                if DimensionSetEntry.FindSet() then
                    repeat
                        LibraryDim.CreateDimSet(DimensionSetEntry."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
                    until DimensionSetEntry.Next() = 0;
            until DimensionValue.Next() = 0;
    end;

    local procedure GetRandomDimValue(DimCode: Code[20]): Text[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDim.FindDimensionValue(DimensionValue, DimCode);
        DimensionValue.Next(LibraryRandom.RandInt(DimensionValue.Count));
        exit(DimensionValue.Code);
    end;

    local procedure CreateMultipleDimValueFilter(DimCode: Code[20]; var MultipleDimValueFilter: Text[250]; FilterChoice: Text[30])
    var
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        FirstDimValue: Code[20];
        LastDimValue: Code[20];
    begin
        LibraryDim.FindDimensionValue(DimensionValue, DimCode);
        DimensionValue2.Copy(DimensionValue);

        DimensionValue.Next(LibraryRandom.RandInt(DimensionValue.Count));
        FirstDimValue := DimensionValue.Code;
        DimensionValue2.Next(LibraryRandom.RandInt(DimensionValue2.Count));
        LastDimValue := DimensionValue2.Code;

        if FirstDimValue < LastDimValue then
            MultipleDimValueFilter := FirstDimValue + FilterChoice + LastDimValue
        else
            MultipleDimValueFilter := LastDimValue + FilterChoice + FirstDimValue;
    end;

    local procedure AddDimSetIDsToTemp(var DimensionValue: Record "Dimension Value"; var DimSetEntry: Record "Dimension Set Entry"; var TempDimSetEntry: Record "Dimension Set Entry" temporary; DimCode: Code[20]; "Count": Integer)
    var
        i: Integer;
    begin
        LibraryDim.FindDimensionValue(DimensionValue, DimCode);
        for i := 1 to Count do
            DimensionMgt.GetDimSetIDsForFilter(DimCode, DimensionValue.Code);
        DimensionMgt.GetTempDimSetEntry(TempDimSetEntry);
        LibraryDim.FindDimensionSetEntry(DimSetEntry, TempDimSetEntry."Dimension Set ID");
    end;

    local procedure CreateExpectedTable(var ExpectedDimSetEntry: Record "Dimension Set Entry"; DimCode: Code[20]; DimValueFilter: Text[1024])
    begin
        if DimCode <> '' then
            ExpectedDimSetEntry.SetFilter("Dimension Code", '%1', DimCode);
        if DimValueFilter <> '' then
            ExpectedDimSetEntry.SetFilter("Dimension Value Code", DimValueFilter);
    end;

    local procedure CheckTempActualTable(var ExpectedDimSetEntry: Record "Dimension Set Entry"; DimCode: Code[20]; DimValueFilter: Text[1024]): Boolean
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if ExpectedDimSetEntry.FindSet() then
            repeat
                DimSetEntry.SetRange("Dimension Set ID", ExpectedDimSetEntry."Dimension Set ID");
                DimSetEntry.SetRange("Dimension Code", DimCode);
                if not DimSetEntry.IsEmpty() then
                    DimSetEntry.SetRange("Dimension Value Code", DimValueFilter);
                if DimSetEntry.FindFirst() then
                    exit(true);
            until ExpectedDimSetEntry.Next() = 0;
        exit(false);
    end;

    local procedure CreateTempActualTable(var TempActualDimSetEntry: Record "Dimension Set Entry" temporary; DimCode: Code[20]; DimValueFilter: Text[250])
    begin
        DimensionMgt.ClearDimSetFilter();
        DimensionMgt.GetDimSetIDsForFilter(DimCode, DimValueFilter);
        DimensionMgt.GetTempDimSetEntry(TempActualDimSetEntry);
    end;

    local procedure CompareTempTableAndFilter(var TempActualDimSetEntry: Record "Dimension Set Entry" temporary; DimFilter: Text)
    var
        DimSetID: Integer;
    begin
        // Get values from string one by one
        // Get record from temp table and delete it
        while StrPos(DimFilter, '|') <> 0 do begin
            Evaluate(DimSetID, CopyStr(DimFilter, 1, StrPos(DimFilter, '|') - 1));
            if TempActualDimSetEntry.Get(DimSetID) then
                TempActualDimSetEntry.Delete();
            DimFilter := CopyStr(DimFilter, StrPos(DimFilter, '|') + 1);
        end;
        // Delete the last value in string
        Evaluate(DimSetID, DimFilter);
        if TempActualDimSetEntry.Get(DimSetID) then
            TempActualDimSetEntry.Delete();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MyDimValueCombinationsPageHandler(var MyDimValueCombinations: TestPage "MyDim Value Combinations")
    begin
        MyDimValueCombinations.ShowColumnName.SetValue(true);
        Assert.AreEqual(
          Format(MyDimValueCombinations.MatrixForm.Name), MyDimValueCombinations.MatrixForm.Field1.Caption,
          StrSubstNo(WrongCaptionErr, MyDimValueCombinations.MatrixForm.Name));
    end;
}

