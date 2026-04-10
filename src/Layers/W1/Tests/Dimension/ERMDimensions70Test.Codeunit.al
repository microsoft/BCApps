codeunit 134230 "ERM - Dimensions 7.0 Test"
{
    Permissions = TableData "Dimension Set Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension]
        isInitialized := false;
    end;

    var
        Dim1: Label 'DEPT';
        Dim2: Label 'AREA51';
        Dim3: Label 'PROJ';
        DimX: Label 'X';
        DimY: Label 'Y';
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        DimensionMismatchError: Label 'Value in %1 field in Item Journal Line does not match Dimension Set Entry.';
        WrongConsolidatedDimFilterErr: Label 'Wrong consolidated Dimension filter value';

    [Test]
    [Scope('OnPrem')]
    procedure CreateDimension()
    var
        Dimension: Record Dimension;
        DimensionCount: Integer;
    begin
        // TestCreateDimension
        // Tests the creation of a dimension by using Library - Dimension functionality
        // Verifies that the new dimension exists and that the total amount of dimensions was increased

        // Setup
        DimensionCount := Dimension.Count();

        // Exercise
        LibraryDimension.CreateDimension(Dimension);

        // Verify
        Assert.IsTrue(Dimension.Get(Dimension.Code), 'Expected dimension was not created');
        Assert.AreEqual(DimensionCount + 1, Dimension.Count, 'Expected dimension count to increase');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndAssignDimValue()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionValueCount: Integer;
    begin
        // TestCreateAndAssignDimensionValue
        // Tests adding a new dimension value and assigning it to a dimension by using Library - Dimension functionality
        // Verifies that the new value exists, that the new value belongs to the given dimension code and that the total amount
        // of dimension values was increased

        // Setup
        LibraryDimension.CreateDimension(Dimension);
        DimensionValueCount := DimensionValue.Count();

        // Exercise
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        // Verify
        Assert.IsTrue(DimensionValue.Get(Dimension.Code, DimensionValue.Code), 'Expected dimension value was not found');
        Assert.AreEqual(DimensionValue."Dimension Code", Dimension.Code, 'Expected dimension value was not assigned correctly');
        Assert.AreEqual(DimensionValueCount + 1, DimensionValue.Count, 'Expected dimension value count to increase');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimensionValue()
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        // TestDeleteDimensionValue
        // Tests the deletion of unused dimension values.

        // Setup
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);

        // Exercise & Verify
        Assert.IsTrue(DimensionValue.Delete(true), 'Dimension value was not deleted');
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        Assert.AreEqual(0, DimensionValue.Count, 'Expected dimension value count must be zero');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDimension()
    var
        Dimension: Record Dimension;
    begin
        // TestDeleteDimension
        // Tests the deletion of an unused dimension w/o dimension values

        // Setup
        LibraryDimension.CreateDimension(Dimension);

        // Exercise & Verify
        Assert.IsTrue(Dimension.Delete(true), 'Dimension was not deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteUsedDimension()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccNo: Code[20];
    begin
        // TestDeleteUsedDimension
        // Tests that it is not allowed to delete dimensions and dimension values which are still
        // in use. Verification expects an apropriate exception.

        // Setup
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        GLAccNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // Create a default dimension for GL Account
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccNo,
          Dimension.Code, DimensionValue.Code);

        // Create a general journal line using new default dimension
        CreateGenJournalLine(GenJournalLine,
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account",
          GLAccNo);

        // Exercise & Verify
        asserterror DimensionValue.Delete(true);
        asserterror Dimension.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_InsertDimVal()
    var
        DimVal: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimSetTreeNode: Record "Dimension Set Tree Node";
        Assert: Codeunit Assert;
        NewDimID: Integer;
        NewDimID2: Integer;
    begin
        InitDimSetup();
        DimVal.Get(Dim1, 'B');
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry.Insert(true);

        NewDimID := DimSetEntry.GetDimensionSetID(TempDimSetEntry);
        Assert.AreNotEqual(NewDimID, 0, '1 : No Dimension Set Entry was inserted');

        DimSetEntry.SetRange("Dimension Set ID", NewDimID);
        Assert.AreEqual(DimSetEntry.Count, 1, '2 : Not exactly one Dimension Set Entry was inserted');

        DimSetEntry.FindFirst(); // only one exists
        Assert.AreEqual(DimSetEntry."Dimension Value ID", DimVal."Dimension Value ID", '3 : Dimension Value ID is wrong');

        DimSetTreeNode.SetRange("Dimension Set ID", NewDimID);
        DimSetTreeNode.FindFirst(); // only one exists
        Assert.AreEqual(DimSetTreeNode."Parent Dimension Set ID", 0, '4 : Parent Dimension ID should be zero');
        Assert.AreEqual(DimSetTreeNode."Dimension Value ID", DimVal."Dimension Value ID", '5 : Dimension Value ID in Tree Node is wrong');
        Assert.AreEqual(DimSetTreeNode."Dimension Set ID", DimSetEntry."Dimension Set ID", '6 : Dimension Set ID in Tree Node is wrong');
        Assert.IsTrue(DimSetTreeNode."In Use", '7 : Tree Node must be in use');

        DimVal.Get(Dim3, 'C');
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
        TempDimSetEntry.Insert();

        DimSetEntry.SetRange("Dimension Set ID");

        TempDimSetEntry.DeleteAll();
        NewDimID := DimSetEntry.GetDimensionSetID(TempDimSetEntry);
        Assert.AreEqual(NewDimID, 0, '11 : The empty set should return 0');

        DimVal.Get(Dim2, 'A');
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
        TempDimSetEntry.Insert();

        NewDimID := DimSetEntry.GetDimensionSetID(TempDimSetEntry);
        Assert.AreNotEqual(NewDimID, 0, '12 : No Dimension Set Entry was inserted');
        Assert.AreNotEqual(NewDimID, NewDimID2, '13 : The Dimension Set ID is wrong.');
        DimSetEntry.SetRange("Dimension Set ID", NewDimID);
        Assert.AreEqual(DimSetEntry.Count, 1, '14 : Not exactly one Dimension Set Entry was inserted');

        TempDimSetEntry.DeleteAll();
        DimVal.Get(DimX, 'A');
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
        TempDimSetEntry.Insert();
        DimVal.Get(DimY, 'C');
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
        TempDimSetEntry.Insert();
        NewDimID := DimSetEntry.GetDimensionSetID(TempDimSetEntry);
        TempDimSetEntry.DeleteAll();
        DimVal.Get(DimX, 'A');
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
        TempDimSetEntry.Insert();
        NewDimID2 := DimSetEntry.GetDimensionSetID(TempDimSetEntry);
        Assert.IsTrue(NewDimID2 < NewDimID, '15 : New Dim ID should be less than previous')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_EditDimVal()
    var
        DimVal: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        Assert: Codeunit Assert;
    begin
        InitDimSetup();
        DimVal.Get(Dim1, 'A');
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry.Insert(true); // should trigger assignment of "Dimension Value ID"
        Assert.AreEqual(DimVal."Dimension Value ID", TempDimSetEntry."Dimension Value ID", '1 : Dimension Value ID is wrong.');
        DimVal.Get(Dim1, 'B');
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry.Modify(true); // should trigger new assignment of "Dimension Value ID"
        Assert.AreEqual(DimVal."Dimension Value ID", TempDimSetEntry."Dimension Value ID", '2 : Dimension Value ID is wrong.');

        DimVal.Get(Dim2, 'A');
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Code" := '';
        TempDimSetEntry.Validate("Dimension Code", DimVal."Dimension Code");
        Assert.AreEqual('', TempDimSetEntry."Dimension Value Code", '3: Dimension Value Code must be blank');
        Assert.AreEqual(0, TempDimSetEntry."Dimension Value ID", '4 : Dimension Value ID must be zero.');
        TempDimSetEntry.Validate("Dimension Value Code", DimVal.Code);
        Assert.AreEqual(DimVal."Dimension Value ID", TempDimSetEntry."Dimension Value ID", '5 : Dimension Value ID is wrong.');
        DimVal.Get(Dim2, 'X');
        asserterror TempDimSetEntry.Validate("Dimension Value Code", DimVal.Code);

        DimVal.Get(DimX, 'X');
        TempDimSetEntry.Init();
        TempDimSetEntry."Dimension Code" := '';
        asserterror TempDimSetEntry.Validate("Dimension Code", DimVal."Dimension Code");
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        asserterror TempDimSetEntry.Validate("Dimension Value Code", DimVal.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Test_COD408_Get_Set_DimSetID()
    var
        DimVal: Record "Dimension Value";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        Assert: Codeunit Assert;
        DimMgt: Codeunit DimensionManagement;
        DimSetID: Integer;
    begin
        InitDimSetup();
        DimVal.Get(Dim1, 'B');
        TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimVal.Code;
        TempDimSetEntry.Insert(true);
        DimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        Assert.AreNotEqual(
          DimSetID,
          0, '1 : No Dimension Set Entry was inserted');

        TempDimSetEntry.DeleteAll();
        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        Assert.AreEqual(1, TempDimSetEntry.Count, '2: Only one record was expected.');
        TempDimSetEntry.FindFirst();
        Assert.AreEqual(DimVal."Dimension Code", TempDimSetEntry."Dimension Code", '3: Wrong Dimension Code.');
        Assert.AreEqual(DimVal.Code, TempDimSetEntry."Dimension Value Code", '4: Wrong Dimension Value Code.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDimensionsSorting()
    var
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        ObjectType: Integer;
        ObjectID: Integer;
        AnalysisViewCode: Code[10];
        SelectedDimText: Text[250];
        DimTextFieldName: Text[100];
    begin
        ObjectType := 0;
        ObjectID := 0;
        AnalysisViewCode := '';
        SelectedDimText := '';
        DimTextFieldName := '';

        CreateDimensionSelectionBuffer(TempDimSelectionBuf, TempDimSelectionBuf.Level::" ", 'VERKÄUFER');
        CreateDimensionSelectionBuffer(TempDimSelectionBuf, TempDimSelectionBuf.Level::" ", 'VERKAUFSKAMPAGNE');

        TempDimSelectionBuf.SetDimSelection(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, TempDimSelectionBuf);
        TempDimSelectionBuf.CompareDimText(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, DimTextFieldName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDimensionsSortingLevel()
    var
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        ObjectType: Integer;
        ObjectID: Integer;
        AnalysisViewCode: Code[10];
        SelectedDimText: Text[250];
        DimTextFieldName: Text[100];
    begin
        ObjectType := 0;
        ObjectID := 0;
        AnalysisViewCode := '';
        SelectedDimText := '';
        DimTextFieldName := '';

        CreateDimensionSelectionBuffer(TempDimSelectionBuf, LibraryRandom.RandIntInRange(1, 5) - 1, LibraryUtility.GenerateGUID());
        CreateDimensionSelectionBuffer(TempDimSelectionBuf, LibraryRandom.RandIntInRange(1, 5) - 1, LibraryUtility.GenerateGUID());

        TempDimSelectionBuf.SetDimSelection(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, TempDimSelectionBuf);
        TempDimSelectionBuf.CompareDimText(ObjectType, ObjectID, AnalysisViewCode, SelectedDimText, DimTextFieldName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyDimItemJournal()
    var
        Global1DimVal: Record "Dimension Value";
        Global2DimVal: Record "Dimension Value";
        DimSetEntry: Record "Dimension Set Entry";
        GeneralLedgerSetupOld: Record "General Ledger Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ItemJournalLine: Record "Item Journal Line";
    begin
        InsertDim(Dim1, false);
        InsertDim(Dim2, false);
        Global1DimVal.SetRange("Dimension Code", Dim1);
        Global1DimVal.FindFirst();
        Global2DimVal.SetRange("Dimension Code", Dim2);
        Global2DimVal.FindFirst();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetupOld := GeneralLedgerSetup;
        GeneralLedgerSetup."Global Dimension 1 Code" := Global1DimVal."Dimension Code";
        GeneralLedgerSetup."Global Dimension 2 Code" := Global2DimVal."Dimension Code";
        GeneralLedgerSetup.Modify();
        DimSetEntry.FindLast();
        DimSetEntry."Dimension Set ID" += 1;
        DimSetEntry."Dimension Code" := Global1DimVal."Dimension Code";
        DimSetEntry."Dimension Value Code" := Global1DimVal.Code;
        DimSetEntry.Insert();
        DimSetEntry."Dimension Code" := Global2DimVal."Dimension Code";
        DimSetEntry."Dimension Value Code" := Global2DimVal.Code;
        DimSetEntry.Insert();

        ItemJournalLine.Init();
        ItemJournalLine.CopyDim(DimSetEntry."Dimension Set ID");

        Assert.AreEqual(Global1DimVal.Code, ItemJournalLine."Shortcut Dimension 1 Code",
          StrSubstNo(DimensionMismatchError, ItemJournalLine.FieldCaption("Shortcut Dimension 1 Code")));
        Assert.AreEqual(Global2DimVal.Code, ItemJournalLine."Shortcut Dimension 2 Code",
          StrSubstNo(DimensionMismatchError, ItemJournalLine.FieldCaption("Shortcut Dimension 2 Code")));

        // Tear-Down
        GeneralLedgerSetup."Global Dimension 1 Code" := GeneralLedgerSetupOld."Global Dimension 1 Code";
        GeneralLedgerSetup."Global Dimension 2 Code" := GeneralLedgerSetupOld."Global Dimension 2 Code";
        GeneralLedgerSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsolidatedDimFilter()
    var
        Dimension: Record Dimension;
        DimMgt: Codeunit DimensionManagement;
        DimensionFilter: Text;
        DimConsolidationCodeFilter: Text;
        ConsolidatedFilter: Text;
    begin
        // [FEATURE] [Consolidation]
        // [SCENARIO 363011] GetConsolidatedDimFilterByDimFilter run with Consolidated Codes Filter adds Dimension Codes to Filter
        // [GIVEN] Dimension X with Consolidation Code A, Dimension Y with Consolidation Code B
        CreateDimensionsWithConsolidationCodes(DimensionFilter, DimConsolidationCodeFilter);
        // [WHEN] DimMgt.GetConsolidatedDimFilterByDimFilter run with Filter(Consolidation Code = A|B)
        ConsolidatedFilter := DimMgt.GetConsolidatedDimFilterByDimFilter(Dimension, DimConsolidationCodeFilter);
        // [THEN] Return Value is equal to (A|B|X|Y).
        Assert.AreEqual(
          DimConsolidationCodeFilter + '|' + DimensionFilter,
          ConsolidatedFilter,
          WrongConsolidatedDimFilterErr);
    end;

    local procedure CreateDimensionSelectionBuffer(var TempDimensionSelectionBuffer: Record "Dimension Selection Buffer" temporary; LevelValue: Option; CodeValue: Code[20])
    begin
        TempDimensionSelectionBuffer.Init();
        TempDimensionSelectionBuffer.Level := LevelValue;
        TempDimensionSelectionBuffer.Code := CodeValue;
        TempDimensionSelectionBuffer.Selected := true;
        TempDimensionSelectionBuffer.Insert();
    end;

    local procedure CreateDimensionsWithConsolidationCodes(var DimensionFilter: Text; var DimConsolidationCodeFilter: Text)
    var
        Dimension: Record Dimension;
        I: Integer;
        Separator: Text;
    begin
        Separator := '|';
        for I := 1 to LibraryRandom.RandInt(10) do begin
            LibraryDimension.CreateDimension(Dimension);
            Dimension.Validate(
              "Consolidation Code",
              LibraryUtility.GenerateRandomCode(Dimension.FieldNo("Consolidation Code"), DATABASE::Dimension));
            Dimension.Modify(true);
            DimensionFilter += Dimension.Code + Separator;
            DimConsolidationCodeFilter += Dimension."Consolidation Code" + Separator;
        end;
        DimensionFilter := DelChr(DimensionFilter, '>', Separator);
        DimConsolidationCodeFilter := DelChr(DimConsolidationCodeFilter, '>', Separator);
    end;

    local procedure InsertDim(DimCode: Code[20]; IsBlocked: Boolean)
    var
        Dim: Record Dimension;
        DimVal: Record "Dimension Value";
    begin
        if Dim.Get(DimCode) then
            Dim.Delete();
        Dim.Validate(Code, DimCode);
        Dim.Validate(Blocked, IsBlocked);
        Dim.Insert(true);
        DimVal.SetRange("Dimension Code", Dim.Code);
        DimVal.DeleteAll();
        InsertDimValues(Dim.Code, 'A', false);
        InsertDimValues(Dim.Code, 'B', false);
        InsertDimValues(Dim.Code, 'C', false);
        InsertDimValues(Dim.Code, 'X', true);
    end;

    local procedure InsertDimValues(DimCode: Code[20]; DimValCode: Code[20]; IsBlocked: Boolean)
    var
        DimVal: Record "Dimension Value";
    begin
        DimVal.Init();
        DimVal."Dimension Code" := DimCode;
        DimVal.Validate(Code, DimValCode);
        DimVal.Validate(Blocked, IsBlocked);
        DimVal.Insert();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // CreateGenJournalLine
        // Creates a general journal line based on the given document type, account type and account no.

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          DocumentType,
          AccountType,
          AccountNo,
          LibraryRandom.RandInt(100));
    end;

    local procedure InitDimSetup()
    begin
        if isInitialized then
            exit;

        InsertDim(Dim1, false);
        InsertDim(Dim2, false);
        InsertDim(Dim3, false);
        InsertDim(DimX, true);
        InsertDim(DimY, false);

        isInitialized := true;
        Commit();
    end;
}

