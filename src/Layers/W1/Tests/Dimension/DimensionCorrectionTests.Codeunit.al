codeunit 134371 "Dimension Correction Tests"
{
    Permissions = TableData "Dimension Set Entry" = rimd, tabledata "G/L Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Dimension Correction]
    end;

    var
        Assert: Codeunit "Library Assert";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";
        Any: Codeunit Any;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        ChangesWereResetMsg: Label 'Changes to the dimensions were reset';
        DimensionCorrectionErr: Label 'Could not find entry in Dimension Correction';

    local procedure Initialize()
    var
        DimensionCorrection: Record "Dimension Correction";
        InvalidatedDimCorrection: Record "Invalidated Dim Correction";
        GLEntry: Record "G/L Entry";
    begin
        DimensionCorrection.DeleteAll(true);
        InvalidatedDimCorrection.DeleteAll();
        GLEntry.ModifyAll("Last Dim. Correction Entry No.", 0);
        LibraryVariableStorage.AssertEmpty();
        if isInitialized then
            exit;

        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestSetDimensionsOnGLEntriesWithoutDimensionSet()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "Set dimensions to the number of G/L Entries that had no dimensions assigned"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithoutDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [WHEN] "User executes the dimension correction on the G/L Entries"
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are successfully updated"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionSuccesfull(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [THEN] "History is updated for the G/L Entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing correct entries"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestAddDimensionOnGLEntries()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "Add a dimension to the G/L Entries that have the dimension set"

        // [GIVEN] "A number of G/L Entries with dimensions"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [WHEN] "User creates dimension correction to add Dimension and executes on the G/L Entries"
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are successfully updated"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionSuccesfull(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [THEN] "History is updated for the G/L Entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing correct entries"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestRemoveDimensionOnGLEntries()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "Remove a dimension from the G/L Entries. Some entries has the dimension that is removed and a part does not."

        // [GIVEN] "A number of G/L Entries with dimension to remove"
        CreateGLEntries(TempGLEntry);
        AddDimensionToGLEntries(TempGLEntry);
        AddDimensionToGLEntries(TempGLEntry);

        // [GIVEN] "Dimension correction to remove Dimension"
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);
        AddRemoveDimensionChange(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();

        // [WHEN] "User creates executes the dimension correction"
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are successfully updated"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionSuccesfull(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [THEN] "History is updated for the G/L Entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing correct entries"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestChangeDimensionOnGLEntries()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "Change a dimension from the G/L Entries. Some entries has the dimension that is changed and a part does not."

        // [GIVEN] "A number of G/L Entries with dimension to change"
        CreateGLEntries(TempGLEntry);
        AddDimensionToGLEntries(TempGLEntry);

        // [GIVEN] "User creates dimension correction to change a Dimension from G/L Entries"
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);
        AddChangeDimensionChange(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();

        // [WHEN] "User creates executes the dimension correction"
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are successfully updated"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionSuccesfull(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [THEN] "History is updated for the G/L Entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing correct entries"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestChangeDimensionOnGLEntriesAddsDimensionWhereItDidNotExist()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "Change a dimension from the G/L Entries. Some entries has the dimension that is changed and a part does not."

        // [GIVEN] "A number of G/L Entries with dimension to change"
        CreateGLEntries(TempGLEntry);
        AddDimensionToGLEntries(TempGLEntry);

        // [GIVEN] "A number of G/L Entries without a dimension to change"
        CreateGLEntries(TempGLEntry);

        // [GIVEN] "User creates dimension correction to change a Dimension from G/L Entries"
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);
        AddChangeDimensionChange(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();

        // [WHEN] "User creates executes the dimension correction"
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are successfully updated"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionSuccesfull(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [THEN] "History is updated for the G/L Entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing correct entries"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestUndoDimensionCorrectionOnGLEntriesToNoDimensionSetID()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionUndo: Codeunit "Dimension Correction Undo";
    begin
        Initialize();

        // [SCENARIO] "Undo a Correction on G/L Entries"

        // [GIVEN] "User has executed dimension correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithoutDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        CopyDimensionChangesToBuffer(DimensionCorrection, TempDimCorrectionSetBuffer);

        // [WHEN] "User executes undo on the dimension correction"
        DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionUndoneSuccesfully(DimensionCorrection, TempGLEntry, TempDimCorrectionSetBuffer);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing all entries and corrected dimensions"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestUndoDimensionCorrectionOnGLEntries()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionUndo: Codeunit "Dimension Correction Undo";
    begin
        Initialize();

        // [SCENARIO] "Undo a Correction on G/L Entries. G/L Entries had no dimension set before."

        // [GIVEN] "User has executed dimension correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        CopyDimensionChangesToBuffer(DimensionCorrection, TempDimCorrectionSetBuffer);

        // [WHEN] "User executes undo on the dimension correction"
        DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionUndoneSuccesfully(DimensionCorrection, TempGLEntry, TempDimCorrectionSetBuffer);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing all entries and corrected dimensions"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestUndoDimensionCorrectionOnGLEntriesIsBlockedByOtherCorrections()
    var
        DimensionCorrection: Record "Dimension Correction";
        NewDimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionUndo: Codeunit "Dimension Correction Undo";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "Undo a Correction on G/L Entries is blocked because other Dimension Corrections were executed afterwards."

        // [GIVEN] "User has executed first dimension correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        TemporaryDimCorrectionChange.DeleteAll();

        // [GIVEN] "User has executed secpnd dimension correction on same G/L Entries"
        CreateDimensionCorrection(NewDimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);
        CreateNewDimensionToAdd(TemporaryDimCorrectionChange);
        AddDimensionToCorrection(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();
        DimCorrectionRun.RunDimensionCorrection(NewDimensionCorrection);
        DimensionCorrection.Find();

        // [WHEN] "User executes undo on the dimension correction"
        // [THEN] "User is prevented to execute this correction because there are other Dimension Corrections on top. Undo would potentionally corrupt the data."
        asserterror DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection);
        Assert.ExpectedError('Cannot undo the dimension correction');
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestUndoDimensionCorrectionIsNotBlockedByUnrelatedCorrection()
    var
        UnrelatedDimensionCorrection: Record "Dimension Correction";
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TempUnrelatedGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TemporaryUnrelatedDimCorrectionChange: Record "Dim Correction Change" temporary;
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionUndo: Codeunit "Dimension Correction Undo";
    begin
        Initialize();

        // [SCENARIO] "Undo a Correction on G/L Entries. G/L Entries had no dimension set before."

        // [GIVEN] "User has executed an unrelated dimension correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(UnrelatedDimensionCorrection, TempUnrelatedGLEntry, TemporaryUnrelatedDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(UnrelatedDimensionCorrection);

        // [GIVEN] "User has executed an dimension correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        CopyDimensionChangesToBuffer(DimensionCorrection, TempDimCorrectionSetBuffer);

        // [WHEN] "User executes undo on the dimension correction"
        DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionUndoneSuccesfully(DimensionCorrection, TempGLEntry, TempDimCorrectionSetBuffer);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing all entries and corrected dimensions"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUserSelectsDimensionSetEntriesByTransaction()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        GLEntry: Record "G/L Entry";
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        Initialize();

        // [SCENARIO] "User is searching all G/L entries that were a part of the same transaction"

        // [GIVEN] "User has posted G/L Entries as part of the same transaction and created the G/L Dimension correction"
        CreateGLEntries(TempGLEntry);
        SetUniqueTransactionNumberToGLEntries(TempGLEntry);
        GeneralLedgerEntries.OpenEdit();
        GLEntry.Get(TempGLEntry."Entry No.");
        GeneralLedgerEntries.GoToRecord(GLEntry);

        DimensionCorrectionDraft.Trap();
        GeneralLedgerEntries.ChangeDimensions.Invoke();

        // [WHEN] "User invokes Select Related Entries"
        GLEntry.SetFilter("Entry No.", GetSelectionFilter(TempGLEntry));
        DimensionCorrectionDraft.SelectedGLEntries.AddByTransaction.Invoke();
        DimensionCorrection.FindLast();

        // [THEN] "All G/L Entries that are a part of the same transaction are selected"
        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectSelectionCriteria.SetRange("Filter Type", DimCorrectSelectionCriteria."Filter Type"::"Related Entries");
        Assert.IsTrue(DimCorrectSelectionCriteria.FindFirst(), 'Could not find the selection criteria');
        VerifyGLEntriesAreIncludedInSelectionCriteria(DimCorrectSelectionCriteria, TempGLEntry);

        // [THEN] "Dimensions part is updated correctly"
        VerifyGLEntriesAreIncludedInSelectedGLEntriesPart(DimensionCorrectionDraft, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('SelectByDimensionHandler')]
    [Scope('OnPrem')]
    procedure TestUserSelectsDimensionSetEntriesByDimension()
    var
        DimensionCorrection: Record "Dimension Correction";
        DimensionSetEntry: Record "Dimension Set Entry";
        TempGLEntry: Record "G/L Entry" temporary;
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "User is searching all G/L entries that have a certain dimension value"

        // [GIVEN] "User wants to correct a specific dimension value on posted G/L Entries"
        CreateGLEntries(TempGLEntry);
        AddDimensionToGLEntries(TempGLEntry);
        AddDimensionToGLEntries(TempGLEntry);
        DimensionSetEntry.SetRange("Dimension Set ID", TempGLEntry."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);

        // [WHEN] "User invokes Select by Dimension"
        LibraryVariableStorage.Enqueue(DimensionSetEntry."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionSetEntry."Dimension Value Code");
        DimensionCorrectionDraft.SelectedGLEntries.AddByDimension.Invoke();

        // [THEN] "All G/L Entries that have same dimension are included"
        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectSelectionCriteria.SetRange("Filter Type", DimCorrectSelectionCriteria."Filter Type"::"By Dimension");
        Assert.IsTrue(DimCorrectSelectionCriteria.FindFirst(), 'Could not find the selection criteria');
        VerifyGLEntriesAreIncludedInSelectionCriteria(DimCorrectSelectionCriteria, TempGLEntry);

        // [THEN] "Dimensions part is updated correctly"
        VerifyGLEntriesAreIncludedInSelectedGLEntriesPart(DimensionCorrectionDraft, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('SelectManuallyHandler')]
    [Scope('OnPrem')]
    procedure TestUserAddsGLEntriesManually()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TempSelectedGLEntry: Record "G/L Entry" temporary;
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "User is selects G/L Entries to correct manually"

        // [GIVEN] "User wants to correct a dimension value on posted G/L Entries and to select them manually"
        CreateGLEntries(TempGLEntry);
        TempSelectedGLEntry.TransferFields(TempGLEntry, true);
        TempSelectedGLEntry.Insert();
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);

        // [WHEN] "User invokes Select Manually"
        LibraryVariableStorage.Enqueue(TempSelectedGLEntry."Entry No.");
        DimensionCorrectionDraft.SelectedGLEntries.SelectManually.Invoke();

        // [THEN] "All G/L Entries that have been selected are included"
        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectSelectionCriteria.SetRange("Filter Type", DimCorrectSelectionCriteria."Filter Type"::Manual);
        Assert.IsTrue(DimCorrectSelectionCriteria.FindFirst(), 'Could not find the selection criteria');
        VerifyGLEntriesAreIncludedInSelectionCriteria(DimCorrectSelectionCriteria, TempSelectedGLEntry);

        // [THEN] "Dimensions part is updated correctly"
        VerifyGLEntriesAreIncludedInSelectedGLEntriesPart(DimensionCorrectionDraft, TempSelectedGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection,VerifyAndCloseMessageHandler')]
    [Scope('OnPrem')]
    procedure TestUserExcludesGLEntries()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TempExcludedGLEntry: Record "G/L Entry" temporary;
        TempSelectedGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "User wants to exclude G/L Entry manually"

        // [GIVEN] "User wants to correct a specific dimension value on posted G/L Entries"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        TempGLEntry.FindFirst();
        TempExcludedGLEntry.TransferFields(TempGLEntry, true);
        TempExcludedGLEntry.Insert();
        DimensionCorrectionDraft.OpenEdit();
        DimensionCorrectionDraft.GoToRecord(DimensionCorrection);

        // [WHEN] "User invokes Exclude entries"
        LibraryVariableStorage.Enqueue(ChangesWereResetMsg);
        DimensionCorrectionDraft.SelectedGLEntries.Filter.SetFilter("Entry No.", Format(TempExcludedGLEntry."Entry No."));
        DimensionCorrectionDraft.SelectedGLEntries.ExcludeEntries.Invoke();
        DimensionCorrectionDraft.SelectedGLEntries.Filter.SetFilter("Entry No.", '');

        // [THEN] "G/L Entries that have been selected are excluded"
        DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectSelectionCriteria.SetRange("Filter Type", DimCorrectSelectionCriteria."Filter Type"::Excluded);
        Assert.IsTrue(DimCorrectSelectionCriteria.FindFirst(), 'Could not find the selection criteria');
        VerifyGLEntriesAreIncludedInSelectionCriteria(DimCorrectSelectionCriteria, TempExcludedGLEntry);

        // [THEN] "Dimensions part is updated correctly"
        VerifyGLEntriesAreIncludedInSelectedGLEntriesPart(DimensionCorrectionDraft, TempSelectedGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestUserRunsCorrectionWithExcludedEntries()
    var
        DimensionCorrection: Record "Dimension Correction";
        GLEntry: Record "G/L Entry";
        TempGLEntry: Record "G/L Entry" temporary;
        TempExcludedGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "User wants to exclude G/L Entry manually"

        // [GIVEN] "User wants to correct a specific dimension value on posted G/L Entries with excluded entries"
        CreateAnyDimensionCorrectionWithExcludedEntries(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange, TempExcludedGLEntry);

        // [WHEN] User invokes run dimension correction
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are successfully updated"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionSuccesfull(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [THEN] "History is updated for the G/L Entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing correct entries"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);

        // [THEN] "Excluded entry is not modified"
        GLEntry.Get(TempExcludedGLEntry."Entry No.");
        Assert.AreEqual(TempExcludedGLEntry."Dimension Set ID", GLEntry."Dimension Set ID", 'Dimension set ID was not supposed to be changed on the excluded G/L Entry');
        Assert.AreEqual(GLEntry."Dimension Changes Count", 0, 'Number of changes should be set to zero');

        // [THEN] "No history is shown for exclueded entry"
        VerifyDimensionCorrectionNotPresentInHistoryForGLEntries(DimensionCorrection, TempExcludedGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestUserRunsUndoCorrectionWithExcludedEntries()
    var
        DimensionCorrection: Record "Dimension Correction";
        GLEntry: Record "G/L Entry";
        TempGLEntry: Record "G/L Entry" temporary;
        TempExcludedGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionUndo: Codeunit "Dimension Correction Undo";
    begin
        Initialize();

        // [SCENARIO] "User wants to undo correction with excluded G/L Entries"

        // [GIVEN] "User has executed the correction with excluded G/L Entries"
        CreateAnyDimensionCorrectionWithExcludedEntries(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange, TempExcludedGLEntry);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        CopyDimensionChangesToBuffer(DimensionCorrection, TempDimCorrectionSetBuffer);

        // [WHEN] "User executes undo on the dimension correction"
        DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionUndoneSuccesfully(DimensionCorrection, TempGLEntry, TempDimCorrectionSetBuffer);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Excluded entry is not modified"
        GLEntry.Get(TempExcludedGLEntry."Entry No.");
        Assert.AreEqual(TempExcludedGLEntry."Dimension Set ID", GLEntry."Dimension Set ID", 'Dimension set ID was not supposed to be changed on the excluded G/L Entry');
        Assert.AreEqual(GLEntry."Dimension Changes Count", 0, 'Number of changes should be set to zero');

        // [THEN] "No history is shown for exclueded entry"
        VerifyDimensionCorrectionNotPresentInHistoryForGLEntries(DimensionCorrection, TempExcludedGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestMultipleLevelUndo()
    var
        DimensionCorrection: Record "Dimension Correction";
        DimensionCorrection2: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TempAfterFirstCorrectionGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TemporaryDimCorrectionChange2: Record "Dim Correction Change" temporary;
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        TempDimCorrectionSetBuffer2: Record "Dim Correction Set Buffer" temporary;
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionUndo: Codeunit "Dimension Correction Undo";
    begin
        Initialize();

        // [SCENARIO] "Undo a Correction on G/L Entries"

        // [GIVEN] "User has executed dimension correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithoutDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        CopyDimensionChangesToBuffer(DimensionCorrection, TempDimCorrectionSetBuffer);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        UpdateTempLedgerEntries(TempGLEntry, TempAfterFirstCorrectionGLEntry);

        // [GIVEN] "User has executed second dimension correction"
        CreateDimensionCorrection(DimensionCorrection2, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);
        CreateNewDimensionToAdd(TemporaryDimCorrectionChange2);
        AddDimensionToCorrection(DimensionCorrectionDraft, TemporaryDimCorrectionChange2);
        DimensionCorrectionDraft.Close();
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection2);
        CopyDimensionChangesToBuffer(DimensionCorrection2, TempDimCorrectionSetBuffer2);

        // [WHEN] "User executes undo on the second dimension correction"
        DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection2);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection2.Find();
        VerifyDimensionCorrectionUndoneSuccesfully(DimensionCorrection2, TempAfterFirstCorrectionGLEntry, TempDimCorrectionSetBuffer2);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection2, TempAfterFirstCorrectionGLEntry);

        // [WHEN] "User executes undo on the first dimension correction"
        DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionUndoneSuccesfully(DimensionCorrection, TempGLEntry, TempDimCorrectionSetBuffer);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestDimCorrectionEntryLogAreGeneratedSingleRange()
    var
        DimensionCorrection: Record "Dimension Correction";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TemporaryDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        Initialize();

        // [SCENARIO] "Verify Log Entries are generated correctly"

        // [GIVEN] "User has created a dimension correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        DimensionCorrectionMgt.GenerateTargetDimensionSetIds(DimensionCorrection);
        DimensionCorrectionMgt.LoadTempDimCorrectionSetBuffer(DimensionCorrection."Entry No.", TemporaryDimCorrectionSetBuffer);

        // [WHEN] We call the function to generate selected entries
        DimensionCorrectionMgt.GenerateSelectedEntries(DimensionCorrection, TemporaryDimCorrectionSetBuffer);

        // [THEN] Single Record is Generated
        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        Assert.AreEqual(1, DimCorrectionEntryLog.Count(), 'Wrong number of generated entries');
        DimCorrectionEntryLog.FindFirst();
        TempGLEntry.FindFirst();
        Assert.AreEqual(TempGLEntry."Entry No.", DimCorrectionEntryLog."Start Entry No.", 'Wrong starting entry');
        TempGLEntry.FindLast();
        Assert.AreEqual(TempGLEntry."Entry No.", DimCorrectionEntryLog."End Entry No.", 'Wrong last entry');

        VerifyDimensionSetLogs(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestDimCorrectionEntryLogAreGeneratedMultipeRanges()
    var
        DimensionCorrection: Record "Dimension Correction";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        TempSourceGLEntry: Record "G/L Entry" temporary;
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TemporaryDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "Verify Log Entries are generated correctly"

        // [GIVEN] "User has created a dimension correction with GL Entries with GAP"
        CreateGLEntries(10, TempSourceGLEntry);
        TempSourceGLEntry.FindFirst();
        TempGLEntry.Copy(TempSourceGLEntry);
        TempGLEntry.Insert();
        TempSourceGLEntry.Next(2);
        TempGLEntry.Copy(TempSourceGLEntry);
        TempGLEntry.Insert();
        TempSourceGLEntry.Next(2);
        TempGLEntry.Copy(TempSourceGLEntry);
        TempGLEntry.Insert();
        TempSourceGLEntry.Next(2);
        TempGLEntry.Copy(TempSourceGLEntry);
        TempGLEntry.Insert();

        AddDimensionToGLEntries(TempGLEntry);
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);
        CreateNewDimensionToAdd(TemporaryDimCorrectionChange);
        AddDimensionToCorrection(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();

        DimensionCorrectionMgt.GenerateTargetDimensionSetIds(DimensionCorrection);
        DimensionCorrectionMgt.LoadTempDimCorrectionSetBuffer(DimensionCorrection."Entry No.", TemporaryDimCorrectionSetBuffer);

        // [WHEN] We call the function to generate selected entries
        DimensionCorrectionMgt.GenerateSelectedEntries(DimensionCorrection, TemporaryDimCorrectionSetBuffer);

        // [THEN] Four Records are Generated
        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        Assert.AreEqual(4, DimCorrectionEntryLog.Count(), 'Wrong number of generated entries');
        DimCorrectionEntryLog.FindFirst();
        TempGLEntry.FindFirst();
        repeat
            Assert.AreEqual(TempGLEntry."Entry No.", DimCorrectionEntryLog."Start Entry No.", 'Wrong starting entry');
            Assert.AreEqual(TempGLEntry."Entry No.", DimCorrectionEntryLog."End Entry No.", 'Wrong last entry');
            DimCorrectionEntryLog.Next();
        until TempGLEntry.Next() = 0;

        VerifyDimensionSetLogs(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestDimCorrectionEntryLogAreGeneratedTwoRanges()
    var
        DimensionCorrection: Record "Dimension Correction";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        TempGLEntry: Record "G/L Entry" temporary;
        TempExcludedGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TemporaryDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        Initialize();

        // [SCENARIO] "Verify Log Entries are generated correctly"

        // [GIVEN] "User has created a dimension correction"
        CreateAnyDimensionCorrectionWithExcludedEntries(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange, TempExcludedGLEntry);
        DimensionCorrectionMgt.GenerateTargetDimensionSetIds(DimensionCorrection);
        DimensionCorrectionMgt.LoadTempDimCorrectionSetBuffer(DimensionCorrection."Entry No.", TemporaryDimCorrectionSetBuffer);

        // [WHEN] We call the function to generate selected entries
        DimensionCorrectionMgt.GenerateSelectedEntries(DimensionCorrection, TemporaryDimCorrectionSetBuffer);

        // [THEN] Two Records are Generated
        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        Assert.AreEqual(2, DimCorrectionEntryLog.Count(), 'Wrong number of generated entries');

        // [THEN] First record includes the range to excluded entry
        DimCorrectionEntryLog.FindFirst();
        TempGLEntry.FindFirst();
        Assert.AreEqual(TempGLEntry."Entry No.", DimCorrectionEntryLog."Start Entry No.", 'Wrong starting entry');
        Assert.AreEqual(TempExcludedGLEntry."Entry No." - 1, DimCorrectionEntryLog."End Entry No.", 'Wrong last entry');

        // [THEN] Second record includes the range from excluded entry to last G/L Entry
        TempGLEntry.FindLast();
        DimCorrectionEntryLog.Next();
        Assert.AreEqual(TempExcludedGLEntry."Entry No." + 1, DimCorrectionEntryLog."Start Entry No.", 'Wrong starting entry');
        Assert.AreEqual(TempGLEntry."Entry No.", DimCorrectionEntryLog."End Entry No.", 'Wrong last entry');

        VerifyDimensionSetLogs(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestDimCorrectionEntryLogMergesRanges()
    var
        DimensionCorrection: Record "Dimension Correction";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        TempGLEntry: Record "G/L Entry" temporary;
        TempAllGLEntry: Record "G/L Entry" temporary;
        TempSecondCriteriaGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TemporaryDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "Verify Log Entries are generated correctly"

        // [GIVEN] "User has created a dimension correction with two selections"
        CreateGLEntries(TempGLEntry);
        AddEntriesToBuffer(TempAllGLEntry, TempGLEntry);
        AddDimensionToGLEntries(TempGLEntry);
        TempGLEntry.FindFirst();
        TempGLEntry.Next(2);

        TempSecondCriteriaGLEntry.TransferFields(TempGLEntry, true);
        TempSecondCriteriaGLEntry.Insert();
        TempGLEntry.Delete();

        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempSecondCriteriaGLEntry);

        CreateNewDimensionToAdd(TemporaryDimCorrectionChange);
        AddDimensionToCorrection(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();

        DimensionCorrectionMgt.GenerateTargetDimensionSetIds(DimensionCorrection);
        DimensionCorrectionMgt.LoadTempDimCorrectionSetBuffer(DimensionCorrection."Entry No.", TemporaryDimCorrectionSetBuffer);

        // [WHEN] We call the function to generate selected entries
        DimensionCorrectionMgt.GenerateSelectedEntries(DimensionCorrection, TemporaryDimCorrectionSetBuffer);

        // [THEN] Single Record is Generated
        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        Assert.AreEqual(1, DimCorrectionEntryLog.Count(), 'Wrong number of generated entries');

        // [THEN] Entry log is including all entries
        DimCorrectionEntryLog.FindFirst();
        TempGLEntry.FindFirst();
        Assert.AreEqual(TempGLEntry."Entry No.", DimCorrectionEntryLog."Start Entry No.", 'Wrong starting entry');
        TempGLEntry.FindLast();
        Assert.AreEqual(TempGLEntry."Entry No.", DimCorrectionEntryLog."End Entry No.", 'Wrong last entry');
        VerifyDimensionSetLogs(DimensionCorrection, TempAllGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestDimCorrectionEntryLogAppendsToEndAndStart()
    var
        DimensionCorrection: Record "Dimension Correction";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        TempGLEntryAppendStart: Record "G/L Entry" temporary;
        TempGLEntryAppendEnd: Record "G/L Entry" temporary;
        TempGLEntry: Record "G/L Entry" temporary;
        TempAllGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TemporaryDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "Verify Log Entries are generated correctly"

        // [GIVEN] "User has created a dimension correction with two selections"
        CreateGLEntries(TempGLEntryAppendStart);
        AddEntriesToBuffer(TempAllGLEntry, TempGLEntryAppendStart);
        AddDimensionToGLEntries(TempGLEntryAppendStart);
        TempGLEntryAppendStart.FindFirst();
        TempGLEntry.TransferFields(TempGLEntryAppendStart, true);
        TempGLEntry.Insert();
        TempGLEntryAppendStart.Delete();
        TempGLEntryAppendStart.FindFirst();
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);

        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntryAppendStart);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);

        // Create end ledger enties
        CreateGLEntries(TempGLEntryAppendEnd);

        // Make a gap between start and end
        TempGLEntryAppendEnd.FindFirst();
        TempGLEntryAppendEnd.Delete();
        AddEntriesToBuffer(TempAllGLEntry, TempGLEntryAppendEnd);

        TempGLEntry.DeleteAll();
        TempGLEntryAppendEnd.FindLast();
        TempGLEntry.TransferFields(TempGLEntryAppendEnd, true);
        TempGLEntry.Insert();
        TempGLEntryAppendEnd.Delete();
        TempGLEntryAppendEnd.FindLast();
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntryAppendEnd);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);

        CreateNewDimensionToAdd(TemporaryDimCorrectionChange);
        AddDimensionToCorrection(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();

        DimensionCorrectionMgt.GenerateTargetDimensionSetIds(DimensionCorrection);
        DimensionCorrectionMgt.LoadTempDimCorrectionSetBuffer(DimensionCorrection."Entry No.", TemporaryDimCorrectionSetBuffer);

        // [WHEN] We call the function to generate selected entries
        DimensionCorrectionMgt.GenerateSelectedEntries(DimensionCorrection, TemporaryDimCorrectionSetBuffer);

        // [THEN] Two Records are Generated
        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        Assert.AreEqual(2, DimCorrectionEntryLog.Count(), 'Wrong number of generated entries');

        // [THEN] First record will append an entry at the start
        DimCorrectionEntryLog.FindFirst();
        TempGLEntryAppendStart.FindFirst();

        Assert.AreEqual(TempGLEntryAppendStart."Entry No." - 1, DimCorrectionEntryLog."Start Entry No.", 'Wrong starting entry');
        TempGLEntryAppendStart.FindLast();
        Assert.AreEqual(TempGLEntryAppendStart."Entry No.", DimCorrectionEntryLog."End Entry No.", 'Wrong ending entry');

        // [THEN] Second record will append an entry to the end
        DimCorrectionEntryLog.Next();
        TempGLEntryAppendEnd.FindFirst();

        Assert.AreEqual(TempGLEntryAppendEnd."Entry No.", DimCorrectionEntryLog."Start Entry No.", 'Wrong starting entry');
        TempGLEntryAppendEnd.FindLast();
        Assert.AreEqual(TempGLEntryAppendEnd."Entry No." + 1, DimCorrectionEntryLog."End Entry No.", 'Wrong ending entry');

        VerifyDimensionSetLogs(DimensionCorrection, TempAllGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestDimCorrectionEntryLogMergesTwoRanges()
    var
        DimensionCorrection: Record "Dimension Correction";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        TempGLEntrySecondrange: Record "G/L Entry" temporary;
        TempGLEntryFirstRange: Record "G/L Entry" temporary;
        TempGLEntryMiddle: Record "G/L Entry" temporary;
        TempAllGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TemporaryDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "Verify Log Entries are generated correctly"

        // [GIVEN] "User has created a dimension correction with three selections Starting, Ending and Middle"
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        CreateGLEntries(TempGLEntryFirstRange);
        AddEntriesToBuffer(TempAllGLEntry, TempGLEntryFirstRange);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntryFirstRange);

        CreateGLEntries(TempGLEntryMiddle);
        AddEntriesToBuffer(TempAllGLEntry, TempGLEntryMiddle);

        CreateGLEntries(TempGLEntrySecondrange);
        AddEntriesToBuffer(TempAllGLEntry, TempGLEntrySecondrange);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntrySecondrange);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntryMiddle);

        CreateNewDimensionToAdd(TemporaryDimCorrectionChange);
        AddDimensionToCorrection(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();

        DimensionCorrectionMgt.GenerateTargetDimensionSetIds(DimensionCorrection);
        DimensionCorrectionMgt.LoadTempDimCorrectionSetBuffer(DimensionCorrection."Entry No.", TemporaryDimCorrectionSetBuffer);

        // [WHEN] We call the function to generate selected entries
        DimensionCorrectionMgt.GenerateSelectedEntries(DimensionCorrection, TemporaryDimCorrectionSetBuffer);

        // [THEN] Single Records is generated
        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        Assert.AreEqual(1, DimCorrectionEntryLog.Count(), 'Wrong number of generated entries');

        // [THEN] All three ranges should be merged
        DimCorrectionEntryLog.FindFirst();
        TempGLEntryFirstRange.FindFirst();
        TempGLEntrySecondrange.FindLast();

        Assert.AreEqual(TempGLEntryFirstRange."Entry No.", DimCorrectionEntryLog."Start Entry No.", 'Wrong starting entry');
        Assert.AreEqual(TempGLEntrySecondrange."Entry No.", DimCorrectionEntryLog."End Entry No.", 'Wrong ending entry');

        VerifyDimensionSetLogs(DimensionCorrection, TempAllGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestDimensionCorrectionEntriesWithSameTargetSet()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempAllSetGLEntry: Record "G/L Entry" temporary;
        TempFirstSetGLEntry: Record "G/L Entry" temporary;
        TempSecondSetGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "User wants to align the ledger entries"

        // [GIVEN] Two sets of ledger entries
        CreateGLEntries(TempFirstSetGLEntry);
        AddDimensionToGLEntries(TempFirstSetGLEntry);

        CreateGLEntries(TempSecondSetGLEntry);
        AddDimensionToGLEntries(TempSecondSetGLEntry);
        AddEntriesToBuffer(TempAllSetGLEntry, TempSecondSetGLEntry);
        AddEntriesToBuffer(TempAllSetGLEntry, TempFirstSetGLEntry);

        // [GIVEN] "User has executed the correction that will result with same target Dimension Set ID - ensuring both sets have both dimensions"
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempSecondSetGLEntry);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempFirstSetGLEntry);

        DimensionCorrectionDraft.DimensionCorrectionsPage.First();
        DimensionCorrectionDraft.DimensionCorrectionsPage.NewValue.SetValue(DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionValueCode);

        DimensionCorrectionDraft.DimensionCorrectionsPage.Next();
        DimensionCorrectionDraft.DimensionCorrectionsPage.NewValue.SetValue(DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionValueCode);
        DimensionCorrectionDraft.Close();
        CopyDimCorrectionChangeToBuffer(DimensionCorrection, TemporaryDimCorrectionChange);

        // [WHEN] "User executes the dimension correction"
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        CopyDimensionChangesToBuffer(DimensionCorrection, TempDimCorrectionSetBuffer);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionSuccesfull(DimensionCorrection, TempAllSetGLEntry, TemporaryDimCorrectionChange);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempAllSetGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestDimensionCorrectionUndoEntriesWithSameTargetSet()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempAllSetGLEntry: Record "G/L Entry" temporary;
        TempFirstSetGLEntry: Record "G/L Entry" temporary;
        TempSecondSetGLEntry: Record "G/L Entry" temporary;
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionUndo: Codeunit "Dimension Correction Undo";
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        Initialize();

        // [SCENARIO] "User wants to align the ledger entries"

        // [GIVEN] Two sets of ledger entries
        CreateGLEntries(TempFirstSetGLEntry);
        AddDimensionToGLEntries(TempFirstSetGLEntry);

        CreateGLEntries(TempSecondSetGLEntry);
        AddDimensionToGLEntries(TempSecondSetGLEntry);
        AddEntriesToBuffer(TempAllSetGLEntry, TempSecondSetGLEntry);
        AddEntriesToBuffer(TempAllSetGLEntry, TempFirstSetGLEntry);

        // [GIVEN] "User has executed the correction that will result with same target Dimension Set ID - ensuring both sets have both dimensions"
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempSecondSetGLEntry);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempFirstSetGLEntry);

        DimensionCorrectionDraft.DimensionCorrectionsPage.First();
        DimensionCorrectionDraft.DimensionCorrectionsPage.NewValue.SetValue(DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionValueCode);
        DimensionCorrectionDraft.DimensionCorrectionsPage.Next();
        DimensionCorrectionDraft.DimensionCorrectionsPage.NewValue.SetValue(DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionValueCode);
        DimensionCorrectionDraft.Close();

        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        CopyDimensionChangesToBuffer(DimensionCorrection, TempDimCorrectionSetBuffer);

        // [WHEN] "User executes undo on the dimension correction"
        DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionUndoneSuccesfully(DimensionCorrection, TempAllSetGLEntry, TempDimCorrectionSetBuffer);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempAllSetGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestVerifyChangesOnDimensionCorrection()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionValidate: Codeunit "Dim Correction Validate";
        DimCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        Initialize();

        // [SCENARIO] "User wants to verify if the dimension correction is correct"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithoutDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [WHEN] "User executes the valdiate to check the dimension correction"
        DimCorrectionValidate.ValidateDraftCorrection(DimensionCorrection);

        // [THEN] "Dimension correction is marked as validated"
        DimensionCorrection.Find();
        ValidationWasSuccessful(DimensionCorrection, TempGLEntry);

        // It should not be possible to validate a draft entry that is validated without reset.
        asserterror DimCorrectionMgt.VerifyCanModifyDraftEntry(DimensionCorrection."Entry No.");
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestRunCorrectionAfterVerifyChangesOnDimensionCorrection()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionValidate: Codeunit "Dim Correction Validate";
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "User wants to verify if the dimension correction is correct"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithoutDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [GIVEN] "User executes the valdiate to check the dimension correction"
        DimCorrectionValidate.ValidateDraftCorrection(DimensionCorrection);

        // [WHEN] "User executes the dimension correction on validated dimension correction"
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are successfully updated"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionSuccesfull(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [THEN] "History is updated for the G/L Entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing correct entries"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestVerifyUndoDimensionCorrection()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionValidate: Codeunit "Dim Correction Validate";
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "User wants to verify if the dimension correction is correct"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithoutDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [WHEN] "User executes the valdiate to check the dimension correction"
        DimCorrectionValidate.ValidateUndoCorrection(DimensionCorrection);

        // [THEN] "Dimension correction is marked as validated"
        DimensionCorrection.Find();
        UndoValidationWasSuccessful(DimensionCorrection);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestVerifyUndoDimensionCorrectionFindsErrors()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionValidate: Codeunit "Dim Correction Validate";
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "User wants to verify if the undoing the dimension correction is correct"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [GIVEN] "User has created a dimension rule that is making undo incorrect"
        TemporaryDimCorrectionChange.FindFirst();
        BlockDimensionPosting(TempGLEntry, TemporaryDimCorrectionChange."Dimension Code", TemporaryDimCorrectionChange."New Value ID");

        // [WHEN] "User executes the valdiate to check the undo of dimension correction"
        Commit();
        asserterror DimCorrectionValidate.ValidateUndoCorrection(DimensionCorrection);

        // [THEN] "Undo Dimension correction is marked as validated"
        DimensionCorrection.Find();
        VerifyUndoValidationFoundErrors(DimensionCorrection);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestVerifyDimensionCorrectionFindsErrors()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionValidate: Codeunit "Dim Correction Validate";
    begin
        Initialize();

        // [SCENARIO] "User wants to verify if the doing the dimension correction is correct"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [GIVEN] "User has created a dimension rule that is making incorrect"
        BlockDimensionPostingDraft(TempGLEntry, DimensionCorrection."Entry No.");

        // [WHEN] "User executes the valdiate to check the dimension correction"
        Commit();
        asserterror DimCorrectionValidate.ValidateDraftCorrection(DimensionCorrection);

        // [THEN] "Undo Dimension correction is marked as validated"
        DimensionCorrection.Find();
        VerifyValidationFoundErrors(DimensionCorrection);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestCorrectionWithErrorsFails()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionValidate: Codeunit "Dim Correction Validate";
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "User is stopped from running wrong dimension correction"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [GIVEN] "User has created a dimension rule that is making incorrect"
        BlockDimensionPostingDraft(TempGLEntry, DimensionCorrection."Entry No.");

        // [GIVEN] "User executes the valdiate to check the dimension correction"
        Commit();
        asserterror DimCorrectionValidate.ValidateDraftCorrection(DimensionCorrection);

        // [WHEN] "User executes the dimension correction"
        // [THEN] "Dimension correction fails"
        asserterror DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestCorrectionWithPassesWithoutReopening()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
    begin
        Initialize();

        // [SCENARIO] "User wants to verify if the doing the dimension correction is correct"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [GIVEN] "User has created a dimension rule that is making incorrect"
        BlockDimensionPostingDraft(TempGLEntry, DimensionCorrection."Entry No.");

        // [GIVEN] "Dimension correction fails"
        Commit();
        asserterror DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [WHEN] "Rule is updated and correction is executed again"
        UnblockBlockDimensionPostingDraft(TempGLEntry);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);

        // [THEN] "Dimension correctoin is executed succesfully"
        // [THEN] "G/L Entries are successfully updated"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionSuccesfull(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);

        // [THEN] "History is updated for the G/L Entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing correct entries"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestVerifyUndoDimensionCorrectionIgnoresValidationErrors()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimCorrectionValidate: Codeunit "Dim Correction Validate";
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionUndo: Codeunit "Dimension Correction Undo";
    begin
        Initialize();

        // [SCENARIO] "Undo of Dimension Correction is possible despite the errors"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        TemporaryDimCorrectionChange.FindFirst();
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        CopyDimensionChangesToBuffer(DimensionCorrection, TempDimCorrectionSetBuffer);

        // [GIVEN] "User has created a dimension rule that is making undo incorrect"
        BlockDimensionPosting(TempGLEntry, TemporaryDimCorrectionChange."Dimension Code", TemporaryDimCorrectionChange."New Value ID");

        // [GIVEN] "User executes the valdiate to check the dimension correction"
        Commit();
        asserterror DimCorrectionValidate.ValidateUndoCorrection(DimensionCorrection);

        // [WHEN] "User executes undo on the dimension correction"
        DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionUndoneSuccesfully(DimensionCorrection, TempGLEntry, TempDimCorrectionSetBuffer);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing all entries and corrected dimensions"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    [Scope('OnPrem')]
    procedure TestVerifyUndoDimensionCorrectionAfterValidation()
    var
        DimensionCorrection: Record "Dimension Correction";
        TempGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary;
        DimCorrectionValidate: Codeunit "Dim Correction Validate";
        DimCorrectionRun: Codeunit "Dim Correction Run";
        DimensionCorrectionUndo: Codeunit "Dimension Correction Undo";
    begin
        Initialize();

        // [SCENARIO] "User wants to verify if the dimension correction is correct"

        // [GIVEN] "A number of G/L Entries without dimensions and user has created a correction"
        CreateAnyDimensionCorrectionOnGLEntriesWithoutDimensions(DimensionCorrection, TempGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(DimensionCorrection);
        CopyDimensionChangesToBuffer(DimensionCorrection, TempDimCorrectionSetBuffer);

        // [GIVEN] "User executes the valdiate to check the dimension correction"
        DimCorrectionValidate.ValidateUndoCorrection(DimensionCorrection);

        // [WHEN] "User executes undo on the dimension correction"
        Commit();
        DimensionCorrectionUndo.RunUndoDimensionCorrection(DimensionCorrection);

        // [THEN] "G/L Entries are moved to the previous state"
        DimensionCorrection.Find();
        VerifyDimensionCorrectionUndoneSuccesfully(DimensionCorrection, TempGLEntry, TempDimCorrectionSetBuffer);

        // [THEN] "Correction is Visible in history for all G/L entries"
        VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection, TempGLEntry);

        // [THEN] "Posted Journal is showing all entries and corrected dimensions"
        VerifyDimensionCorrectionPage(DimensionCorrection, TempGLEntry);
    end;

    [Test]
    [HandlerFunctions('HandleEnterGLEntriesFilterSelection')]
    procedure TestGLEntriesRefreshWhenNavigatingBetweenDimensionCorrections()
    var
        FirstDimensionCorrection: Record "Dimension Correction";
        SecondDimensionCorrection: Record "Dimension Correction";
        TempFirstGLEntry: Record "G/L Entry" temporary;
        TempSecondGLEntry: Record "G/L Entry" temporary;
        TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary;
        DimCorrectionRun: Codeunit "Dim Correction Run";
        TestPageDimensionCorrection: TestPage "Dimension Correction";
    begin
        // [SCENARIO 609696] When navigating between Dimension Correction cards using navigation buttons
        // the G/L entries should refresh to show the correct entries for each correction.
        Initialize();

        // [GIVEN] First dimension correction with a set of G/L entries.
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(FirstDimensionCorrection, TempFirstGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(FirstDimensionCorrection);
        FirstDimensionCorrection.Find();

        // [GIVEN] Second dimension correction with a different set of G/L entries.
        CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(SecondDimensionCorrection, TempSecondGLEntry, TemporaryDimCorrectionChange);
        DimCorrectionRun.RunDimensionCorrection(SecondDimensionCorrection);

        // [WHEN] User opens the first dimension correction page
        TestPageDimensionCorrection.OpenView();
        TestPageDimensionCorrection.GoToRecord(FirstDimensionCorrection);

        // [THEN] The correct G/L entries for the first correction are displayed.
        TempFirstGLEntry.FindSet();
        repeat
            TestPageDimensionCorrection.SelectedGLEntries.Filter.SetFilter("Entry No.", Format(TempFirstGLEntry."Entry No."));
            Assert.AreEqual(TempFirstGLEntry."Entry No.", TestPageDimensionCorrection.SelectedGLEntries."Entry No.".AsInteger(), DimensionCorrectionErr);
        until TempFirstGLEntry.Next() = 0;

        // [WHEN] User navigates to the second dimension correction using Next.
        TestPageDimensionCorrection.Next();

        // [THEN] The correct G/L entries for the second correction are displayed.
        TempSecondGLEntry.FindSet();
        repeat
            TestPageDimensionCorrection.SelectedGLEntries.Filter.SetFilter("Entry No.", Format(TempSecondGLEntry."Entry No."));
            Assert.AreEqual(TempSecondGLEntry."Entry No.", TestPageDimensionCorrection.SelectedGLEntries."Entry No.".AsInteger(), DimensionCorrectionErr);
        until TempSecondGLEntry.Next() = 0;

        TestPageDimensionCorrection.Close();
    end;

    local procedure ValidationWasSuccessful(DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary)
    var
        ValidationText: Text;
    begin
        Assert.AreEqual(DimensionCorrection.Status, DimensionCorrection.Status::Draft, 'Dimension correction should have been reverted to draft.');
        Assert.IsTrue(DimensionCorrection."Validated At" > 0DT, 'Validation was not updated correctly.');
        Assert.IsTrue(DimensionCorrection."Validated Selected Entries", 'Validated Selected Entries was not updated correctly.');
        DimensionCorrection.GetValidateDimensionChangesText(ValidationText);
        Assert.IsTrue(ValidationText.Contains('The dimension correction was validated'), 'Dimension correction should have passed');
        Assert.IsFalse(ValidationText.Contains('error'), 'Dimension correction should have passed');
        TempGLEntry.FindLast();
        Assert.AreEqual(TempGLEntry."Entry No.", DimensionCorrection."Last Validated Entry No.", 'Validated Selected Entries was not updated correctly.');
    end;

    local procedure VerifyUndoValidationFoundErrors(DimensionCorrection: Record "Dimension Correction")
    var
        ValidationText: Text;
    begin
        Assert.AreEqual(DimensionCorrection.Status, DimensionCorrection.Status::Completed, 'Dimension correction should have been reverted to completed.');
        Assert.IsTrue(DimensionCorrection."Validated At" > 0DT, 'Validation was not updated correctly.');
        Assert.IsFalse(DimensionCorrection."Validated Selected Entries", 'Validated Selected Entries was not updated correctly.');
        DimensionCorrection.GetValidateDimensionChangesText(ValidationText);
        Assert.IsTrue(ValidationText.Contains('have validation errors'), 'Dimension correction should have failed');
    end;

    local procedure VerifyValidationFoundErrors(DimensionCorrection: Record "Dimension Correction")
    var
        ValidationText: Text;
    begin
        Assert.AreEqual(DimensionCorrection.Status, DimensionCorrection.Status::Draft, 'Dimension correction should have been reverted to draft.');
        Assert.IsTrue(DimensionCorrection."Validated At" > 0DT, 'Validation was not updated correctly.');
        Assert.IsFalse(DimensionCorrection."Validated Selected Entries", 'Validated Selected Entries was not updated correctly.');
        DimensionCorrection.GetValidateDimensionChangesText(ValidationText);
        Assert.IsTrue(ValidationText.Contains('have validation errors'), 'Dimension correction should have failed');
    end;

    local procedure UndoValidationWasSuccessful(DimensionCorrection: Record "Dimension Correction")
    var
        ValidationText: Text;
    begin
        Assert.AreEqual(DimensionCorrection.Status, DimensionCorrection.Status::Completed, 'Dimension correction should have been reverted to completed.');
        Assert.IsTrue(DimensionCorrection."Validated At" > 0DT, 'Validation was not updated correctly.');
        Assert.IsTrue(DimensionCorrection."Validated Selected Entries", 'Validated Selected Entries was not updated correctly.');
        DimensionCorrection.GetValidateDimensionChangesText(ValidationText);
        Assert.IsTrue(ValidationText.Contains('You can undo the dimension correction.'), 'Dimension correction should have passed');
        Assert.IsFalse(ValidationText.Contains('error'), 'Dimension correction should have passed');
    end;

    local procedure AddDimensionToCorrection(var DimensionCorrectionDraft: TestPage "Dimension Correction Draft"; var TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary)
    begin
        TemporaryDimCorrectionChange.FindSet();
        DimensionCorrectionDraft.DimensionCorrectionsPage.New();
        DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionCode.SetValue(TemporaryDimCorrectionChange."Dimension Code");
        DimensionCorrectionDraft.DimensionCorrectionsPage.NewValue.SetValue(TemporaryDimCorrectionChange."New value");
    end;

    local procedure AddEntriesToBuffer(var TempGLEntry: Record "G/L Entry" temporary; var TempEntriesToAddGLEntry: Record "G/L Entry" temporary)
    begin
        TempEntriesToAddGLEntry.Reset();
        TempEntriesToAddGLEntry.FindSet();
        repeat
            TempGLEntry.TransferFields(TempEntriesToAddGLEntry, true);
            if TempGLEntry.Insert() then;
        until TempEntriesToAddGLEntry.Next() = 0;
    end;

    local procedure BlockDimensionPosting(var TempGLEntry: Record "G/L Entry" temporary; DimensionCode: Code[20]; AllowedValueID: Integer)
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetRange("Dimension Value ID", AllowedValueID);
        DimensionValue.FindFirst();
        BlockDimensionPosting(TempGLEntry, DimensionCode, DimensionValue.Code);
    end;

    local procedure BlockDimensionPosting(var TempGLEntry: Record "G/L Entry" temporary; DimensionCode: Code[20]; AllowedValue: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Validate("Table ID", Database::"G/L Account");
        DefaultDimension."No." := TempGLEntry."G/L Account No.";
        DefaultDimension.Validate("Dimension Code", DimensionCode);
        DefaultDimension.Validate("Dimension Value Code", AllowedValue);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Validate("Allowed Values Filter", AllowedValue);
        DefaultDimension.Insert();
    end;

    local procedure BlockDimensionPostingDraft(var TempGLEntry: Record "G/L Entry" temporary; DimensionCorrectionEntryNo: Integer)
    var
        DefaultDimension: Record "Default Dimension";
        DimCorrectionChange: Record "Dim Correction Change";
        DimensionValue: Record "Dimension Value";
    begin
        DimCorrectionChange.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        DimCorrectionChange.SetFilter("Change Type", '<>%1', DimCorrectionChange."Change Type"::"No Change");
        DimCorrectionChange.FindFirst();
        DimensionValue.SetRange("Dimension Code", DimCorrectionChange."Dimension Code");
        DimensionValue.SetFilter("Dimension Value ID", '<>%1', DimCorrectionChange."New Value ID");
        DimensionValue.FindFirst();

        DefaultDimension.Validate("Table ID", Database::"G/L Account");
        DefaultDimension."No." := TempGLEntry."G/L Account No.";
        DefaultDimension.Validate("Dimension Code", DimCorrectionChange."Dimension Code");
        DefaultDimension.Validate("Dimension Value Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Validate("Allowed Values Filter", DimensionValue.Code);
        DefaultDimension.Insert();
    end;

    local procedure UnblockBlockDimensionPostingDraft(var TempGLEntry: Record "G/L Entry" temporary)
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", Database::"G/L Account");
        DefaultDimension.SetRange("No.", TempGLEntry."G/L Account No.");
        DefaultDimension.DeleteAll();
    end;

    local procedure UpdateTempLedgerEntries(var TempGLEntry: Record "G/L Entry" temporary; var TempUpdatedGLEntry: Record "G/L Entry" temporary)
    var
        GLEntry: Record "G/L Entry";
    begin
        TempGLEntry.Reset();
        TempGLEntry.FindSet();
        repeat
            GLEntry.Get(TempGLEntry."Entry No.");
            TempUpdatedGLEntry.TransferFields(GLEntry, true);
            if TempUpdatedGLEntry.Insert() then;
        until TempGLEntry.Next() = 0;
    end;

    local procedure CreateNewDimensionToAdd(var TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary)
    var
        Dimension: Record "Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        CreateNewDimension(Dimension, 3);
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.FindFirst();

        CLEAR(TemporaryDimCorrectionChange);
        TemporaryDimCorrectionChange."Dimension Code" := DimensionValue."Dimension Code";
        TemporaryDimCorrectionChange."Dimension Value" := '';
        TemporaryDimCorrectionChange."New value" := DimensionValue.Code;
        TemporaryDimCorrectionChange."New Value ID" := DimensionValue."Dimension Value ID";
        TemporaryDimCorrectionChange.Insert();
    end;

    local procedure CreateNewDimension(var Dimension: Record "Dimension"; NumberOfValues: Integer)
    var
        DimensionValue: Record "Dimension Value";
        I: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);

        for I := 1 to NumberOfValues do
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateDimensionCorrection(var DimensionCorrection: Record "Dimension Correction"; var DimensionCorrectionDraft: TestPage "Dimension Correction Draft")
    begin
        DimensionCorrectionDraft.OpenNew();
        DimensionCorrectionDraft.Description.SetValue(Any.AlphabeticText(MaxStrLen(DimensionCorrection.Description)));
        DimensionCorrectionDraft.Close();
        DimensionCorrection.FindLast();
        DimensionCorrectionDraft.OpenEdit();
        DimensionCorrectionDraft.GoToRecord(DimensionCorrection);
    end;

    local procedure AddGLEntriesByFilter(var DimensionCorrectionDraft: TestPage "Dimension Correction Draft"; var TempGLEntry: Record "G/L Entry" temporary)
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        DummyGLEntry.SetFilter("Entry No.", GetSelectionFilter(TempGLEntry));
        LibraryVariableStorage.Enqueue(DummyGLEntry.GetView());
        DimensionCorrectionDraft.SelectedGLEntries.AddByFilter.Invoke();
    end;

    local procedure CreateGLEntries(var TempGLEntry: Record "G/L Entry" temporary)
    begin
        CreateGLEntries(Any.IntegerInRange(5, 10), TempGLEntry);
    end;

    local procedure AddDimensionToGLEntries(var TempGLEntry: Record "G/L Entry" temporary)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionSetID: Integer;
        GLEntry: Record "G/L Entry";
        DimensionManagement: Codeunit DimensionManagement;
    begin
        CreateNewDimension(Dimension, Any.IntegerInRange(3, 10));
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.FindFirst();

        TempGLEntry.FindFirst();
        DimensionManagement.GetDimensionSet(TempDimensionSetEntry, TempGLEntry."Dimension Set ID");
        if TempDimensionSetEntry.FindFirst() then
            repeat
                TempDimensionSetEntry.Rename(0, TempDimensionSetEntry."Dimension Code");
            until TempDimensionSetEntry.Next() = 0;

        TempDimensionSetEntry."Dimension Code" := Dimension.Code;
        TempDimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimensionSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimensionSetEntry.Insert();
        DimensionSetID := DimensionManagement.GetDimensionSetID(TempDimensionSetEntry);

        repeat
            GLEntry.Get(TempGLEntry."Entry No.");
            GLEntry."Dimension Set ID" := DimensionSetID;
            DimensionManagement.UpdateGlobalDimFromDimSetID(
                GLEntry."Dimension Set ID", GLEntry."Global Dimension 1 Code", GLEntry."Global Dimension 2 Code");
            GLEntry.Modify();
            TempGLEntry."Dimension Set ID" := GLEntry."Dimension Set ID";
            TempGLEntry.Modify();
        until TempGLEntry.Next() = 0;
    end;

    local procedure CreateGLEntries(NumberOfGLEntries: Integer; var TempGLEntry: Record "G/L Entry" temporary)
    var
        I: Integer;
    begin
        for I := 1 to NumberOfGLEntries do
            CreateGLEntry(TempGLEntry);
    end;

    local procedure CreateGLEntry(var TempGLEntry: Record "G/L Entry" temporary)
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := LibraryUtility.GenerateGUID();
        GLEntry."Document No." := LibraryUtility.GenerateGUID();
        GLEntry."Transaction No." := GetGLEntryTransactionNo();
        GLEntry.Insert();

        TempGLEntry.TransferFields(GLEntry, true);
        TempGLEntry.Insert();
    end;

    local procedure GetGLEntryTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
        GLEntryTransactionNo: Integer;
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        if GLEntry.FindLast() then
            GLEntryTransactionNo := GLEntry."Transaction No.";

        exit(GLEntryTransactionNo + 1);
    end;

    local procedure GetSelectionFilter(var TempGLEntry: Record "G/L Entry" temporary): Text;
    var
        FilterText: Text;
    begin
        if not TempGLEntry.FindSet() then
            exit(FilterText);

        repeat
            if FilterText = '' then
                FilterText := Format(TempGLEntry."Entry No.")
            else
                FilterText += '|' + Format(TempGLEntry."Entry No.");
        until TempGLEntry.Next() = 0;

        exit(FilterText);
    end;

    local procedure VerifyDimensionCorrectionUndoneSuccesfully(var DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary)
    var
        GLEntry: Record "G/L Entry";
    begin
        Assert.AreEqual(DimensionCorrection.Status::"Undo Completed", DimensionCorrection.Status, 'Status should be set to completed');
        Assert.AreEqual(DimensionCorrection."Total Updated Ledger Entries", TempGLEntry.Count(), 'Wrong number of update entries');
        VerifyDimensionSetLogs(DimensionCorrection, TempGLEntry);

        TempGLEntry.FindFirst();
        repeat
            Assert.IsTrue(GLEntry.Get(TempGLEntry."Entry No."), 'Could not find G/L Entry.');
            Assert.IsTrue(TempDimCorrectionSetBuffer.Get(DimensionCorrection."Entry No.", GLEntry."Dimension Set ID"), 'Could not find the correction set buffer');
            Assert.AreNotEqual(GLEntry."Last Dim. Correction Entry No.", DimensionCorrection."Entry No.", 'Entry No. should be changed.');
            Assert.AreEqual(GLEntry."Dimension Set ID", TempDimCorrectionSetBuffer."Dimension Set ID", 'Dimension set ID was not reverted');
            Assert.AreEqual(GLEntry."Dimension Set ID", TempGLEntry."Dimension Set ID", 'Dimension set ID was not reverted');
        until TempGLEntry.Next() = 0;
    end;

    local procedure VerifyDimensionCorrectionSuccesfull(var DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary; var TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary)
    var
        GLEntry: Record "G/L Entry";
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
    begin
        Assert.AreEqual(DimensionCorrection.Status::Completed, DimensionCorrection.Status, 'Status should be set to completed');
        Assert.AreEqual(DimensionCorrection."Total Updated Ledger Entries", TempGLEntry.Count(), 'Wrong number of update entries');
        Assert.IsFalse(DimensionCorrection.Invalidated, 'Invalidated should not be set');
        GLEntry.SetRange("Last Dim. Correction Entry No.", DimensionCorrection."Entry No.");
        Assert.AreEqual(TempGLEntry.Count(), GLEntry.Count(), 'Wrong number of updated entries.');
        VerifyDimensionSetLogs(DimensionCorrection, TempGLEntry);

        GLEntry.FindSet();
        repeat
            VerifyGLEntryDimensions(GLEntry, TemporaryDimCorrectionChange);
            Assert.IsTrue(TempGLEntry.Get(GLEntry."Entry No."), 'Wrong G/L Entry was updated.');
            DimCorrectionEntryLog.SetFilter("Start Entry No.", '<=%1', GLEntry."Entry No.");
            DimCorrectionEntryLog.SetFilter("End Entry No.", '>=%1', GLEntry."Entry No.");
            Assert.IsTrue(DimCorrectionEntryLog.FindFirst(), 'Could not find Dim Correction Updated Entry');
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyDimensionSetLogs(var DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary)
    var
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        TotalNumberOfEntries: Integer;
    begin
        DimensionCorrection.Find();
        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectionEntryLog.FindSet();
        TotalNumberOfEntries := 0;

        repeat
            TotalNumberOfEntries += DimCorrectionEntryLog."End Entry No." - DimCorrectionEntryLog."Start Entry No." + 1;
        until DimCorrectionEntryLog.Next() = 0;

        Assert.AreEqual(DimensionCorrection."Total Selected Ledger Entries", TotalNumberOfEntries, 'Wrong number of Total Updated Ledger Entries on Dimension Correction');
        Assert.AreEqual(TempGLEntry.Count(), TotalNumberOfEntries, 'Number of G/L entries does not match the Total in Correction Entry Log');

        TempGLEntry.Reset();
        TempGLEntry.FindSet();
        repeat
            DimCorrectionEntryLog.SetFilter("Start Entry No.", '<=%1', TempGLEntry."Entry No.");
            DimCorrectionEntryLog.SetFilter("End Entry No.", '>=%1', TempGLEntry."Entry No.");
            Assert.IsTrue(DimCorrectionEntryLog.FindFirst(), StrSubstNo('Could not find the corrresponding Dimension GLEntry Log for G/L Entry %1', TempGLEntry."Entry No."));
        until TempGLEntry.Next() = 0;
    end;

    local procedure VerifyGLEntryDimensions(GLEntry: Record "G/L Entry"; var TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary)
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        Assert.IsTrue(GLEntry."Dimension Set ID" <> 0, 'Dimension Set was not updated on GL Entry');
        DimensionManagement.GetDimensionSet(TempDimensionSetEntry, GLEntry."Dimension Set ID");

        TemporaryDimCorrectionChange.FindFirst();

        repeat
            case TemporaryDimCorrectionChange."Change Type" of
                TemporaryDimCorrectionChange."Change Type"::Add,
                TemporaryDimCorrectionChange."Change Type"::Change:
                    begin
                        Assert.IsTrue(TempDimensionSetEntry.Get(GLEntry."Dimension Set ID", TemporaryDimCorrectionChange."Dimension Code"), 'Could not find the Dimension Code in the Dimension set');
                        Assert.AreEqual(TemporaryDimCorrectionChange."New Value ID", TempDimensionSetEntry."Dimension Value ID", 'Wrong value was assigned');
                    end;
                TemporaryDimCorrectionChange."Change Type"::Remove:
                    Assert.IsFalse(TempDimensionSetEntry.Get(GLEntry."Dimension Set ID", TemporaryDimCorrectionChange."Dimension Code"), 'Dimension Code was supposed to be removed form the Dimension Set');
                TemporaryDimCorrectionChange."Change Type"::"No Change":
                    begin
                        Assert.IsTrue(TempDimensionSetEntry.Get(GLEntry."Dimension Set ID", TemporaryDimCorrectionChange."Dimension Code"), 'Could not find the Dimension Code in the Dimension set');
                        Assert.AreEqual(TemporaryDimCorrectionChange."Dimension Value", TempDimensionSetEntry."Dimension Value Name", 'Value Code was not supposed to be changed');
                    end;
                else
                    Assert.Fail(StrSubstNo('Unexpected value for Dimension Change %1.', TemporaryDimCorrectionChange."Change Type"));
            end;
        until TemporaryDimCorrectionChange.Next() = 0;
    end;

    local procedure VerifyDimensionCorrectionPresentInHistoryForGLEntries(DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary)
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        DimensionCorrections: TestPage "Dimension Corrections";
    begin
        TempGLEntry.FindFirst();
        GeneralLedgerEntries.OpenView();
        repeat
            GLEntry.Get(TempGLEntry."Entry No.");
            GeneralLedgerEntries.GoToRecord(GLEntry);
            DimensionCorrections.Trap();
            GeneralLedgerEntries.DimensionChangeHistory.Invoke();
            DimensionCorrections.Filter.SetFilter("Entry No.", Format(DimensionCorrection."Entry No."));
            Assert.AreEqual(DimensionCorrection."Entry No.", DimensionCorrections."Entry No.".AsInteger(), 'Dimension correction should be in the list');
            DimensionCorrections.Close();
        until TempGLEntry.Next() = 0;
    end;

    local procedure VerifyDimensionCorrectionNotPresentInHistoryForGLEntries(DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary)
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        DimensionCorrections: TestPage "Dimension Corrections";
    begin
        TempGLEntry.FindFirst();
        GeneralLedgerEntries.OpenView();
        repeat
            GLEntry.Get(TempGLEntry."Entry No.");
            GeneralLedgerEntries.GoToRecord(GLEntry);
            DimensionCorrections.Trap();
            GeneralLedgerEntries.DimensionChangeHistory.Invoke();
            DimensionCorrections.Filter.SetFilter("Entry No.", Format(DimensionCorrection."Entry No."));
            Assert.AreNotEqual(DimensionCorrection."Entry No.", DimensionCorrections."Entry No.".AsInteger(), 'Dimension correction should be in the list');
            DimensionCorrections.Close();
        until TempGLEntry.Next() = 0;
    end;

    local procedure VerifyDimensionCorrectionPage(DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary)
    var
        TestPageDimensionCorrection: TestPage "Dimension Correction";
    begin
        TestPageDimensionCorrection.OpenView();
        TestPageDimensionCorrection.GoToRecord(DimensionCorrection);
        TempGLEntry.FindSet();

        repeat
            TestPageDimensionCorrection.SelectedGLEntries.Filter.SetFilter("Entry No.", Format(TempGLEntry."Entry No."));
            Assert.AreEqual(TempGLEntry."Entry No.", TestPageDimensionCorrection.SelectedGLEntries."Entry No.".AsInteger(), 'Could not find the entry in the corrected entries');
        until TempGLEntry.Next() = 0;
    end;

    local procedure VerifyGLEntriesAreIncludedInSelectionCriteria(DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria"; var TempGLEntry: Record "G/L Entry" temporary)
    var
        GLEntry: Record "G/L Entry";
        SelectionFilter: Text;
    begin
        DimCorrectSelectionCriteria.GetSelectionFilter(SelectionFilter);
        GLEntry.SetView(SelectionFilter);

        Assert.AreEqual(TempGLEntry.Count(), GLEntry.Count(), 'Wrong number of G/L entries selected');
        GLEntry.FindSet();

        repeat
            Assert.IsTrue(GLEntry.Get(TempGLEntry."Entry No."), 'Could not find the G/L Entry in selection criteria');
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyGLEntriesAreIncludedInSelectedGLEntriesPart(var DimensionCorrectionDraft: TestPage "Dimension Correction Draft"; var TempGLEntry: Record "G/L Entry" temporary)
    begin
        repeat
            DimensionCorrectionDraft.SelectedGLEntries.Filter.SetFilter("Entry No.", Format(TempGLEntry."Entry No."));
            Assert.AreEqual(TempGLEntry."Entry No.", DimensionCorrectionDraft.SelectedGLEntries."Entry No.".AsInteger(), 'Could not find the entry in the entries to be corrected');
        until TempGLEntry.Next() = 0;
    end;

    local procedure AddRemoveDimensionChange(var DimensionCorrectionDraft: TestPage "Dimension Correction Draft"; var TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary)
    begin
        DimensionCorrectionDraft.DimensionCorrectionsPage.First();
        DimensionCorrectionDraft.DimensionCorrectionsPage.DeleteRow.Invoke();
        TemporaryDimCorrectionChange."Dimension Code" := DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionCode.Value();
        TemporaryDimCorrectionChange."Dimension Value" := DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionValueCode.Value();
        TemporaryDimCorrectionChange."Change Type" := TemporaryDimCorrectionChange."Change Type"::Remove;
        TemporaryDimCorrectionChange.Insert();
    end;

    local procedure AddChangeDimensionChange(var DimensionCorrectionDraft: TestPage "Dimension Correction Draft"; var TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary)
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionCorrectionDraft.DimensionCorrectionsPage.First();
        DimensionValue.SetRange("Dimension Code", DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionCode.Value());
        DimensionValue.SetFilter("Dimension Value ID", '<>%1', TemporaryDimCorrectionChange."New Value ID");
        DimensionValue.FindLast();
        DimensionCorrectionDraft.DimensionCorrectionsPage.NewValue.SetValue(DimensionValue.Code);
        TemporaryDimCorrectionChange."Dimension Code" := DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionCode.Value();
        TemporaryDimCorrectionChange."Dimension Value" := DimensionCorrectionDraft.DimensionCorrectionsPage.DimensionValueCode.Value();
        TemporaryDimCorrectionChange."New Value ID" := DimensionValue."Dimension Value ID";
        TemporaryDimCorrectionChange."Change Type" := TemporaryDimCorrectionChange."Change Type"::Change;
        TemporaryDimCorrectionChange.Insert();
    end;

    local procedure CopyDimensionChangesToBuffer(DimensionCorrection: Record "Dimension Correction"; var TempDimCorrectionSetBuffer: Record "Dim Correction Set Buffer" temporary)
    var
        DimCorrectionSetBuffer: Record "Dim Correction Set Buffer";
    begin
        DimCorrectionSetBuffer.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectionSetBuffer.FindSet();

        repeat
            TempDimCorrectionSetBuffer.TransferFields(DimCorrectionSetBuffer, true);
            TempDimCorrectionSetBuffer.Insert();
        until DimCorrectionSetBuffer.Next() = 0;
    end;

    local procedure CopyDimCorrectionChangeToBuffer(DimensionCorrection: Record "Dimension Correction"; var TempDimCorrectionChange: Record "Dim Correction Change" temporary)
    var
        DimCorrectionChange: Record "Dim Correction Change";
    begin
        DimCorrectionChange.SetRange("Dimension Correction Entry No.", DimensionCorrection."Entry No.");
        DimCorrectionChange.FindSet();

        repeat
            TempDimCorrectionChange.TransferFields(DimCorrectionChange, true);
            TempDimCorrectionChange.Insert();
        until TempDimCorrectionChange.Next() = 0;
    end;

    local procedure CreateAnyDimensionCorrectionOnGLEntriesWithoutDimensions(var DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary; var TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary)
    var
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        CreateGLEntries(TempGLEntry);
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);
        CreateNewDimensionToAdd(TemporaryDimCorrectionChange);
        AddDimensionToCorrection(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();
    end;

    local procedure CreateAnyDimensionCorrectionOnGLEntriesWithDimensions(var DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary; var TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary)
    var
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        CreateGLEntries(TempGLEntry);
        AddDimensionToGLEntries(TempGLEntry);
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);
        CreateNewDimensionToAdd(TemporaryDimCorrectionChange);
        AddDimensionToCorrection(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();
    end;

    local procedure CreateAnyDimensionCorrectionWithExcludedEntries(var DimensionCorrection: Record "Dimension Correction"; var TempGLEntry: Record "G/L Entry" temporary; var TemporaryDimCorrectionChange: Record "Dim Correction Change" temporary; var TempExcludedGLEntry: Record "G/L Entry" temporary)
    var
        DimensionCorrectionDraft: TestPage "Dimension Correction Draft";
    begin
        CreateGLEntries(TempGLEntry);
        AddDimensionToGLEntries(TempGLEntry);
        CreateDimensionCorrection(DimensionCorrection, DimensionCorrectionDraft);
        AddGLEntriesByFilter(DimensionCorrectionDraft, TempGLEntry);

        TempGLEntry.FindFirst();
        TempGLEntry.Next();
        TempExcludedGLEntry.TransferFields(TempGLEntry, true);
        TempExcludedGLEntry.Insert();
        TempGLEntry.Delete();

        DimensionCorrectionDraft.SelectedGLEntries.Filter.SetFilter("Entry No.", Format(TempExcludedGLEntry."Entry No."));
        DimensionCorrectionDraft.SelectedGLEntries.ExcludeEntries.Invoke();
        DimensionCorrectionDraft.SelectedGLEntries.Filter.SetFilter("Entry No.", '');

        CreateNewDimensionToAdd(TemporaryDimCorrectionChange);
        AddDimensionToCorrection(DimensionCorrectionDraft, TemporaryDimCorrectionChange);
        DimensionCorrectionDraft.Close();
    end;

    local procedure SetUniqueTransactionNumberToGLEntries(var TempGLEntry: Record "G/L Entry" temporary)
    var
        GLEntry: Record "G/L Entry";
        TransactionNumber: Integer;
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.Ascending(false);
        GLEntry.FindFirst();
        TransactionNumber := GLEntry."Transaction No." + 1;

        if TempGLEntry.FindFirst() then
            repeat
                GLEntry.Get(TempGLEntry."Entry No.");
                GLEntry."Transaction No." := TransactionNumber;
                GLEntry.Modify();
            until TempGLEntry.Next() = 0;
    end;

    [FilterPageHandler]
    procedure HandleEnterGLEntriesFilterSelection(var RecRef: RecordRef): Boolean;
    begin
        RecRef.SetView(LibraryVariableStorage.DequeueText());
        exit(true);
    end;

    [ModalPageHandler]
    procedure SelectByDimensionHandler(var DimCorrFindbyDimension: TestPage "Dim Corr Find by Dimension")
    begin
        DimCorrFindbyDimension.New();
        DimCorrFindbyDimension."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        DimCorrFindbyDimension."Dimension Value Code".SetValue(LibraryVariableStorage.DequeueText());
        DimCorrFindbyDimension.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectManuallyHandler(var GeneralLedgerEntries: TestPage "General Ledger Entries")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.GEt(LibraryVariableStorage.DequeueInteger());
        GeneralLedgerEntries.GoToRecord(GLEntry);
        GeneralLedgerEntries.OK().Invoke();
    end;

    [MessageHandler]
    procedure VerifyAndCloseMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(Message.Contains(LibraryVariableStorage.DequeueText()), 'Wrong message was shown');
    end;
}