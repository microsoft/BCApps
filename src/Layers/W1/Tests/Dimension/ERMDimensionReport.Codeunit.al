codeunit 134975 "ERM Dimension Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Value Posting]
        isInitialized := false;
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryCashFlow: Codeunit "Library - Cash Flow";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        CheckValuePostingError: Label 'Dimension Value Code %1 must be %2.';
        CheckItemJnlLineDimIDError: Label 'Dimension Set ID is incorrect in Line No. = %1.';
        AnalysisCodeMissing: Label 'Enter an analysis view code.';
        DateFilterMissing: Label 'Enter a date filter.';
        ColumnLayoutNameMissing: Label 'Enter a column layout name.';
        AccNoGenJnlLineCap: Label 'AccountNo_GenJnlLine';
        DimTextCap: Label 'DimText';
        AllocationDimTextCap: Label 'AllocationDimText';
        AccNoGenJnlAlloCap: Label 'AccountNo_GenJnlAllocation';
        FailureDimValCodeMsg: Label 'Dimension Value Code should match Shortcut Dimension 1 Code';
        DimensionsCantBeUsedConcurrentlyErr: Label 'Dimensions %1 and %2 can''t be used concurrently.';
        DimensionIsBlockedErr: Label 'Dimension %1 is blocked.';

    [Test]
    [HandlerFunctions('RPHandlerCheckValuePosting2')]
    [Scope('OnPrem')]
    procedure ValuePostingReportNoCodeAndSameCodeCombination()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        CheckValuePostingReport(DefaultDimension."Value Posting"::"No Code", DefaultDimension."Value Posting"::"Same Code");
    end;

    [Test]
    [HandlerFunctions('RPHandlerCheckValuePosting2')]
    [Scope('OnPrem')]
    procedure ValuePostingReportNoCodeAndCodeMandatoryCombination()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        CheckValuePostingReport(DefaultDimension."Value Posting"::"No Code", DefaultDimension."Value Posting"::"Code Mandatory");
    end;

    [Test]
    [HandlerFunctions('RPHandlerCheckValuePosting2')]
    [Scope('OnPrem')]
    procedure ValuePostingReportSameCodeAndCodeMandatoryCombination()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        asserterror
          CheckValuePostingReport(DefaultDimension."Value Posting"::"Same Code", DefaultDimension."Value Posting"::"Code Mandatory");
        Assert.ExpectedError('No row found');
    end;

    [Test]
    [HandlerFunctions('RPHandlerCheckValuePosting2')]
    [Scope('OnPrem')]
    procedure ValuePostingReportNoCodeAndEmptyCombination()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        asserterror CheckValuePostingReport(DefaultDimension."Value Posting"::"No Code", DefaultDimension."Value Posting"::" ");
        Assert.ExpectedError('No row found');
    end;

    [Test]
    [HandlerFunctions('RPHandlerCheckValuePosting2')]
    [Scope('OnPrem')]
    procedure ValuePostingReportSameCodeAndEmptyCombination()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        asserterror CheckValuePostingReport(DefaultDimension."Value Posting"::"Same Code", DefaultDimension."Value Posting"::" ");
        Assert.ExpectedError('No row found');
    end;

    [Test]
    [HandlerFunctions('RPHandlerCheckValuePosting2')]
    [Scope('OnPrem')]
    procedure ValuePostingReportCodeMandatoryAndEmptyCombination()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        asserterror CheckValuePostingReport(DefaultDimension."Value Posting"::"Code Mandatory", DefaultDimension."Value Posting"::" ");
        Assert.ExpectedError('No row found');
    end;

    [Test]
    [HandlerFunctions('RPHandlerCheckValuePosting')]
    [Scope('OnPrem')]
    procedure DimensionCheckValuePostingReport()
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        Vendor: Record Vendor;
        DimensionValueCode: Code[20];
    begin
        // Test Check Value Posting report functionality.

        // Setup: Create initial data for Check Value Posting report.
        Initialize();
        DimensionValueCode := CreateDimensionValues(DimensionValue);
        LibraryPurchase.CreateVendor(Vendor);
        CreateDefaultDimensionVendor(
          DefaultDimension, Vendor."No.", DimensionValue."Dimension Code", DimensionValueCode,
          DefaultDimension."Value Posting"::"Code Mandatory");
        LibraryDimension.CreateAccTypeDefaultDimension(
          DefaultDimension, DATABASE::Vendor, DimensionValue."Dimension Code", DimensionValue.Code,
          DefaultDimension."Value Posting"::"Same Code");

        // Exercise: Run Check Value Posting.
        RunCheckValuePosting(DimensionValue."Dimension Code");

        // Verify: Verify conflict dimension error.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorMessage_DefaultDim2',
          StrSubstNo(CheckValuePostingError, DimensionValueCode, DimensionValue.Code));

        // Tear down: Delete Vendor Default Dimension and Account Type Default Dimension.
        ClearDefaultDimensionCodes(DATABASE::Vendor, Vendor."No.");
        ClearDefaultDimensionCodes(DATABASE::Vendor, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionCheckCalcInvtReport()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Dimension: Record Dimension;
        SelectedDimension: Record "Selected Dimension";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        ObjectType: Integer;
        ObjectID: Integer;
        DimensionSetID: array[10] of Integer;
        Counter: Integer;
        MaxCount: Integer;
    begin
        // Test case checks that report Calculate Inventory creates Item Journal Lines with correctly specified Dimension IDs.

        Initialize();
        // 1. Create Item
        LibraryInventory.CreateItem(Item);
        // 2. Find Item Journal Batch of 'Item' type
        FindItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, true);
        // 3. Create Dimension
        LibraryDimension.CreateDimension(Dimension);
        // 4. 1> Random < 10 number of Dimension Set IDs and lines to generate
        MaxCount := LibraryRandom.RandInt(9) + 1;
        // 5. Create MaxCount number of Dimension Set IDs and lines
        for Counter := 1 to MaxCount do begin
            DimensionSetID[Counter] := CreateDimSetID(Dimension);
            CreateItemJnlLineWithDim(
              ItemJournalBatch, ItemJournalLine, WorkDate(), DimensionSetID[Counter], ItemJournalLine."Entry Type"::Purchase,
              Item."No.");
        end;
        // 6. Post Item Journal Lines
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // 7. Set Object Type = Report
        ObjectType := 3;
        // 8. Set Object ID = Calculate Inventory
        ObjectID := REPORT::"Calculate Inventory";

        // 9. Select Dimension to make Calculate Inventory Report include only needed Dimension(s)
        SelectDimension(ObjectType, ObjectID, Dimension.Code);

        // 10. Run Report Calculate Inventory (filtering by Item and Dimension)

        CalculateInventory(ItemJournalLine, Item."No.", '', CalcDate('<+1D>', WorkDate()), false, false);

        // 11. Validate each generated line has correct Dimension SET ID
        for Counter := 1 to MaxCount do begin
            Assert.AreEqual(DimensionSetID[Counter], ItemJournalLine."Dimension Set ID",
              StrSubstNo(CheckItemJnlLineDimIDError, ItemJournalLine."Line No."));
            ItemJournalLine.Next();
        end;

        // 12. TearDown: Delete all lines/Cleare Selected Dimension
        ItemJournalLine.DeleteAll();
        CleanSelectedDimension(SelectedDimension, UserId, ObjectType, ObjectID);
    end;

    [Test]
    [HandlerFunctions('RPHandlerDimensionDetail,PHandlerDimensionSelectionLevel')]
    [Scope('OnPrem')]
    procedure DimensionDetailAnalysisCodeMissingError()
    begin
        Initialize();

        // Setup:
        SetDimensionDetailParameters('', Format(WorkDate()));

        // Exercise & Verify:
        asserterror REPORT.Run(REPORT::"Dimensions - Detail");
        Assert.ExpectedError(AnalysisCodeMissing);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionCheckCalcInvtReportForMultipleLines()
    var
        DefaultDimension: array[2] of Record "Default Dimension";
        ItemJournalLine: Record "Item Journal Line";
        LibraryInventory: Codeunit "Library - Inventory";
        ItemFilter: Text;
        ItemNo: array[2] of Code[20];
    begin
        // Test case checks that report Calculate Inventory creates Item Journal Lines with correctly specified Dimension Value Code.

        Initialize();
        // 1. Create 2 Item Journal Lines with Items and Default Dimension
        CreateTwoJrnlLinesItemsWithDefaultDimension(ItemJournalLine, DefaultDimension, ItemNo);

        // 2. Post 2 Item Journal Lines
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // 3. Select Dimension to make Calculate Inventory Report include only needed Dimensions (3 = Report)
        SelectDimension(3, REPORT::"Calculate Inventory", DefaultDimension[1]."Dimension Code");

        // 4. Run Report Calculate Inventory (filtering by Item and Dimension)
        ItemFilter := StrSubstNo('%1|%2', ItemNo[1], ItemNo[2]);
        CalculateInventory(ItemJournalLine, ItemFilter, '', CalcDate('<+1D>', WorkDate()), false, false);

        // 5. Validate each generated line has correct Dimension Value Code
        VerifyDimValForItemJournalLine(ItemJournalLine, DefaultDimension);
    end;

    [Test]
    [HandlerFunctions('RPHandlerDimensionDetail,PHandlerDimensionSelectionLevel')]
    [Scope('OnPrem')]
    procedure DimensionDetailDateFilterMissingError()
    var
        AnalysisView: Record "Analysis View";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup:
        LibraryERM.CreateGLAccount(GLAccount);
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"G/L Account", GLAccount."No.");
        SetDimensionDetailParameters(AnalysisView.Code, '');

        // Exercise & Verify:
        Commit();
        asserterror REPORT.Run(REPORT::"Dimensions - Detail");
        Assert.ExpectedError(DateFilterMissing);
    end;

    [Test]
    [HandlerFunctions('RPHandlerDimensionDetail,PHandlerDimensionSelectionLevel,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DimensionDetailWithGLAccountSource()
    var
        AnalysisView: Record "Analysis View";
        GLAccount: Record "G/L Account";
        ExpectedAmount: Decimal;
    begin
        Initialize();

        if Confirm('', true) then; // dummy confirm

        // Setup:
        LibraryERM.CreateGLAccount(GLAccount);
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"G/L Account", GLAccount."No.");
        ExpectedAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJnlLine(AnalysisView, ExpectedAmount);
        UpdateAnalysisView(AnalysisView.Code);

        // Exercise:
        SetDimensionDetailParameters(AnalysisView.Code, Format(WorkDate()));
        Commit();
        REPORT.Run(REPORT::"Dimensions - Detail");

        // Verify:
        VerifyDimensionDetailReport(AnalysisView.Code, ExpectedAmount)
    end;

    [Test]
    [HandlerFunctions('RPHandlerDimensionTotal,PHandlerDimensionSelectionLevel')]
    [Scope('OnPrem')]
    procedure DimensionTotalAnalysisCodeMissingError()
    begin
        Initialize();

        // Setup:
        SetDimensionTotalParameters('', CreateColumnLayout(), Format(WorkDate()));

        // Exercise & Verify:
        Commit();
        asserterror REPORT.Run(REPORT::"Dimensions - Total");
        Assert.ExpectedError(AnalysisCodeMissing);
    end;

    [Test]
    [HandlerFunctions('RPHandlerDimensionTotal,PHandlerDimensionSelectionLevel')]
    [Scope('OnPrem')]
    procedure DimensionTotalColumnLayoutMissingError()
    var
        AnalysisView: Record "Analysis View";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup:
        LibraryERM.CreateGLAccount(GLAccount);
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"G/L Account", GLAccount."No.");
        SetDimensionTotalParameters(AnalysisView.Code, '', Format(WorkDate()));

        // Exercise & Verify:
        Commit();
        asserterror REPORT.Run(REPORT::"Dimensions - Total");
        Assert.ExpectedError(ColumnLayoutNameMissing);
    end;

    [Test]
    [HandlerFunctions('RPHandlerDimensionTotal,PHandlerDimensionSelectionLevel')]
    [Scope('OnPrem')]
    procedure DimensionTotallDateFilterMissingError()
    var
        AnalysisView: Record "Analysis View";
        GLAccount: Record "G/L Account";
    begin
        Initialize();

        // Setup:
        LibraryERM.CreateGLAccount(GLAccount);
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"G/L Account", GLAccount."No.");
        SetDimensionTotalParameters(AnalysisView.Code, CreateColumnLayout(), '');

        // Exercise & Verify:
        Commit();
        asserterror REPORT.Run(REPORT::"Dimensions - Total");
        Assert.ExpectedError(DateFilterMissing);
    end;

    [Test]
    [HandlerFunctions('RPHandlerDimensionTotal,PHandlerDimensionSelectionLevel,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DimensionTotalWithGLAccountSource()
    var
        AnalysisView: Record "Analysis View";
        GLAccount: Record "G/L Account";
        ExpectedAmount: Decimal;
    begin
        Initialize();

        if Confirm('', true) then; // dummy confirm

        // Setup:
        LibraryERM.CreateGLAccount(GLAccount);
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"G/L Account", GLAccount."No.");
        ExpectedAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostGenJnlLine(AnalysisView, ExpectedAmount);
        UpdateAnalysisView(AnalysisView.Code);

        // Exercise:
        SetDimensionTotalParameters(AnalysisView.Code, CreateColumnLayout(), Format(WorkDate()));
        Commit();
        REPORT.Run(REPORT::"Dimensions - Total");

        // Verify:
        VerifyDimensionTotalReport(AnalysisView.Code, ExpectedAmount)
    end;

    [Test]
    [HandlerFunctions('RPHandlerDimensionTotal,PHandlerDimensionSelectionLevel,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DimensionTotalWithCashFlowAccountSource()
    var
        AnalysisView: Record "Analysis View";
        CashFlowAccount: Record "Cash Flow Account";
        ExpectedAmount: Decimal;
    begin
        Initialize();

        if Confirm('', true) then; // dummy confirm

        // Setup:
        LibraryCashFlow.CreateCashFlowAccount(CashFlowAccount, CashFlowAccount."Account Type"::Entry);
        CreateAnalysisView(AnalysisView, AnalysisView."Account Source"::"Cash Flow Account", CashFlowAccount."No.");
        ExpectedAmount := LibraryRandom.RandDec(100, 2);
        CreateAndPostCashFlowJnlLine(AnalysisView, ExpectedAmount);
        UpdateAnalysisView(AnalysisView.Code);

        // Exercise:
        SetDimensionTotalParameters(AnalysisView.Code, CreateColumnLayout(), Format(WorkDate()));
        Commit();
        REPORT.Run(REPORT::"Dimensions - Total");

        // Verify:
        VerifyDimensionTotalReport(AnalysisView.Code, ExpectedAmount)
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestHandler')]
    [Scope('OnPrem')]
    procedure SingleDimensionLineShowsInGenJnlTest()
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GLAccount: array[3] of Record "G/L Account";
        Dimension: array[3] of Record Dimension;
        DimensionValue: array[3] of Record "Dimension Value";
        DimSetID: array[3] of Integer;
        i: Integer;
        ExpectedResult: array[3, 2] of Text;
    begin
        // Setup
        for i := 1 to 3 do begin
            LibraryERM.CreateGLAccount(GLAccount[i]);
            CreateDimensionAndValue(Dimension[i], DimensionValue[i]);
        end;

        FindJnlTemplate();

        // Exercise
        SetDifferDimensions(DimSetID, Dimension, DimensionValue, 0);
        PrepareGeneralLine(GenJournalLine, GenJnlAllocation, GLAccount, DimSetID);

        RunReportGeneralJournalTest();

        // Verify single Dimension Line is displayed on the report
        GetExpectResultForSingleDim(Dimension, DimensionValue, ExpectedResult);
        LibraryReportDataset.LoadDataSetFile();

        VerifyDimensionInJournalLine(GLAccount[1]."No.", ExpectedResult[1]);
        VerifyDimensionInAllocationLine(GLAccount[2]."No.", ExpectedResult[2]);
        VerifyDimensionInAllocationLine(GLAccount[3]."No.", ExpectedResult[3]);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTestHandler')]
    [Scope('OnPrem')]
    procedure MultipleDimensionLinesShowInGenJnlTest()
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GLAccount: array[3] of Record "G/L Account";
        Dimension: array[3] of Record Dimension;
        DimensionValue: array[3] of Record "Dimension Value";
        DimSetID: array[6] of Integer;
        i: Integer;
        ExpectedResult: array[3, 2] of Text;
        FirstDimensionLine: array[2] of Text;
    begin
        // Setup
        for i := 1 to 3 do begin
            LibraryERM.CreateGLAccount(GLAccount[i]);
            CreateDimensionAndValue(Dimension[i], DimensionValue[i]);
            if i = 3 then
                FirstDimensionLine[2] := StrSubstNo('%1 - %2;', Dimension[i].Code, DimensionValue[i].Code)
            else
                FirstDimensionLine[1] += StrSubstNo('%1 - %2;', Dimension[i].Code, DimensionValue[i].Code);
        end;

        SetDifferDimensions(DimSetID, Dimension, DimensionValue, 0);

        for i := 1 to 3 do
            CreateDimensionAndValue(Dimension[i], DimensionValue[i]);

        SetDifferDimensions(DimSetID, Dimension, DimensionValue, DimSetID[3]);

        FindJnlTemplate();

        // Exercise
        PrepareGeneralLine(GenJournalLine, GenJnlAllocation, GLAccount, DimSetID);

        RunReportGeneralJournalTest();

        // Verify multiple Dimension Lines are displayed on the report
        // First line of the dimension.
        FirstDimensionLine[1] := CopyStr(FirstDimensionLine[1], 1, StrLen(FirstDimensionLine[1]) - 1);
        // Second line of the dimension.
        GetExpectResultForMultipleDim(Dimension, DimensionValue, FirstDimensionLine[2], ExpectedResult);
        LibraryReportDataset.LoadDataSetFile();

        VerifyDimensionInJournalLine(GLAccount[1]."No.", FirstDimensionLine);
        VerifyDimensionInJournalLine(GLAccount[1]."No.", ExpectedResult[1]);
        VerifyDimensionInAllocationLine(GLAccount[2]."No.", FirstDimensionLine);
        VerifyDimensionInAllocationLine(GLAccount[2]."No.", ExpectedResult[2]);
        VerifyDimensionInAllocationLine(GLAccount[3]."No.", FirstDimensionLine);
        VerifyDimensionInAllocationLine(GLAccount[3]."No.", ExpectedResult[3]);
    end;

    [Test]
    [HandlerFunctions('DimensionSelectionLevelHandler')]
    [Scope('OnPrem')]
    procedure ValidateDimensionSelectionLevel()
    var
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
        AnalysisView: Record "Analysis View";
        SelectedDimText: Text[250];
        DimNo: Integer;
        DimCodes: array[4] of Code[20];
    begin
        // [FEATURE] [Dimension Selection Level]
        // [SCENARIO 271488] Dimension Selection Level shows all of the Dimensions listed for Analysis View
        // [GIVEN] Four Dimensions with codes starting with GLAccount.TABLECAPTION ending with consecutive numbers
        LibraryVariableStorage.Enqueue(ArrayLen(DimCodes) + 1);
        for DimNo := 1 to ArrayLen(DimCodes) do begin
            DimCodes[DimNo] := CreateDimensionGLAccountWithNumber(DimNo);
            LibraryVariableStorage.Enqueue(DimCodes[DimNo]);
        end;

        // [GIVEN] Analysis view with source "G/L Account" and 4 created dimensions listed
        CreateAnalysisViewFullDimensions(AnalysisView, AnalysisView."Account Source"::"G/L Account", '', DimCodes);

        // [WHEN] Call "DimensionSelectionBuffer.SetDimSelectionLevelGLAcc" for created analysis view
        SelectedDimText := '';
        DimensionSelectionBuffer.SetDimSelectionLevelGLAcc(0, 0, AnalysisView.Code, SelectedDimText);

        // [THEN] "Dimension Selection - Level" page shows "GLAccount.TABLECAPTION" first then all of the created dimensions
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionCheckCalcInvtReportNoTran()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Dimension: Record Dimension;
        Location: array[2] of Record Location;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ObjectType: Integer;
        ObjectID: Integer;
        DimensionSetID: Integer;
        LocationFilter: Text;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Physical Inventory] [Calculate Inventory]
        // [SCENARIO 296470] Item Journal Lines posted for Locations without transactions in 'Calculate Inventory' have 'Dimension Set ID' = 0

        Initialize();
        Location[1].DeleteAll();

        // [GIVEN] Locations: L1,L2
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        // [GIVEN] Dimension Set ID: D1
        LibraryDimension.CreateDimension(Dimension);
        DimensionSetID := CreateDimSetID(Dimension);
        // [GIVEN] Posted Item Ledger Entry on L1 with D1
        ItemNo := LibraryInventory.CreateItemNo();
        FindItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, true);
        CreateItemJnlLineWithDim(
          ItemJournalBatch, ItemJournalLine, WorkDate(), DimensionSetID, ItemJournalLine."Entry Type"::Purchase,
          ItemNo);
        ItemJournalLine.Validate("Location Code", Location[1].Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Run 'Calculate Inventory' with Dimension and Location filters
        ObjectType := 3;
        ObjectID := REPORT::"Calculate Inventory";
        SelectDimension(ObjectType, ObjectID, Dimension.Code);
        LocationFilter := StrSubstNo('%1|%2', Location[1].Code, Location[2].Code);
        CalculateInventory(ItemJournalLine, ItemNo, LocationFilter, CalcDate('<+1D>', WorkDate()), true, true);

        // [THEN] Two lines are created: one with 'Dimension Set ID' = D1, another - 0
        Assert.AreEqual(2, ItemJournalLine.Count, '');
        ItemJournalLine.SetRange("Location Code", Location[1].Code);
        ItemJournalLine.FindFirst();
        Assert.AreEqual(DimensionSetID, ItemJournalLine."Dimension Set ID",
          StrSubstNo(CheckItemJnlLineDimIDError, ItemJournalLine."Line No."));
        ItemJournalLine.SetRange("Location Code", Location[2].Code);
        ItemJournalLine.FindFirst();
        Assert.AreEqual(0, ItemJournalLine."Dimension Set ID",
          StrSubstNo(CheckItemJnlLineDimIDError, ItemJournalLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('BankAccReconTestHandler')]
    [Scope('OnPrem')]
    procedure DimensionCheckLineReconciliationJournal()
    var
        Dimension: array[3] of Record Dimension;
        DimensionValue: array[3] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        DimensionCombination: Record "Dimension Combination";
        Vendor: Record Vendor;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        i: Integer;
    begin
        // [FEATURE] [Bank Account Reconciliation]
        // [SCENARIO 300556] 'Bank Acc. Recon. - Test' report shows dimension errors

        // [GIVEN] Vendor with default dimensions "Dim1", "Dim2", "Dim3"
        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to ArrayLen(Dimension) do begin
            CreateDimensionAndValue(Dimension[i], DimensionValue[i]);
            LibraryDimension.CreateDefaultDimensionVendor(
              DefaultDimension, Vendor."No.", DimensionValue[i]."Dimension Code", DimensionValue[i].Code);
        end;

        // [GIVEN] Bank Account Reconciliation line for the vendor
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, LibraryERM.CreateBankAccountNo(), BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::Vendor);
        BankAccReconciliationLine.Validate("Account No.", Vendor."No.");
        BankAccReconciliationLine.Modify(true);

        // [GIVEN] Dimensions "Dim1" and "Dim2" combination is not allowed
        // [GIVEN] Dimension "Dim3" is blocked
        LibraryDimension.CreateDimensionCombination(DimensionCombination, Dimension[1].Code, Dimension[2].Code);
        DimensionCombination."Combination Restriction" := DimensionCombination."Combination Restriction"::Blocked;
        DimensionCombination.Modify();
        LibraryDimension.BlockDimension(Dimension[3]);
        Commit();

        // [WHEN] Run 'Bank Acc. Recon. - Test' report
        BankAccReconciliation.SetRecFilter();
        REPORT.Run(REPORT::"Bank Acc. Recon. - Test", true, false, BankAccReconciliation);

        // [THEN] Error shown that "Dim1" and "Dim2" dimensions cannot be used concurrently
        // [THEN] Error shown that "Dim3" is blocked
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists(
          'ErrorText_Number__Control97', StrSubstNo(DimensionsCantBeUsedConcurrentlyErr, Dimension[1].Code, Dimension[2].Code));
        LibraryReportDataset.AssertElementTagWithValueExists(
          'ErrorText_Number__Control97', StrSubstNo(DimensionIsBlockedErr, Dimension[3].Code));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Report");
        LibraryVariableStorage.Clear();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Report");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        ClearDimensionCombinations();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Report");
    end;

    local procedure CreateDimensionAndValue(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value")
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure FindJnlTemplate()
    begin
        LibraryERM.FindRecurringTemplateName(GenJnlTemplate);
        GenJnlBatch.SetFilter("Journal Template Name", GenJnlTemplate.Name);
        if not GenJnlBatch.FindFirst() then
            LibraryERM.CreateRecurringBatchName(GenJnlBatch, GenJnlTemplate.Name);
    end;

    local procedure CreateRecurringGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, LibraryRandom.RandInt(-2000));
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"V  Variable");
        Evaluate(GenJournalLine."Recurring Frequency", '<CM+1M>');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAllocationLine(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; AccountNo: Code[20]; AllocationPercent: Decimal)
    begin
        LibraryERM.CreateGenJnlAllocation(
          GenJnlAllocation, GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name",
          GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", AccountNo);
        GenJnlAllocation.Validate("Allocation %", AllocationPercent);
        GenJnlAllocation.Modify(true);
    end;

    local procedure RunReportGeneralJournalTest()
    begin
        REPORT.Run(REPORT::"General Journal - Test");
    end;

    local procedure SetDifferDimensions(var DimSetID: array[3] of Integer; Dimension: array[3] of Record Dimension; DimensionValue: array[3] of Record "Dimension Value"; OldDimSetID: Integer)
    var
        i: Integer;
    begin
        for i := 1 to 3 do begin
            DimSetID[i] := LibraryDimension.CreateDimSet(OldDimSetID, Dimension[i].Code, DimensionValue[i].Code);
            OldDimSetID := DimSetID[i];
        end;
    end;

    local procedure PrepareGeneralLine(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlAllocation: Record "Gen. Jnl. Allocation"; GLAccount: array[3] of Record "G/L Account"; DimSetID: array[3] of Integer)
    var
        QtyPercent: Integer;
    begin
        Clear(GenJournalLine);
        GenJournalLine.DeleteAll();

        CreateRecurringGeneralJournal(GenJournalLine, GLAccount[1]."No.");
        GenJournalLine.Validate("Dimension Set ID", DimSetID[1]);
        GenJournalLine.Modify(true);

        Clear(GenJnlAllocation);
        GenJnlAllocation.DeleteAll();

        QtyPercent := LibraryRandom.RandInt(99);

        CreateAllocationLine(GenJnlAllocation, GLAccount[2]."No.", QtyPercent);
        GenJnlAllocation.Validate("Dimension Set ID", DimSetID[2]);
        GenJnlAllocation.Modify(true);

        CreateAllocationLine(GenJnlAllocation, GLAccount[3]."No.", 100 - QtyPercent);
        GenJnlAllocation.Validate("Dimension Set ID", DimSetID[3]);
        GenJnlAllocation.Modify(true);

        Commit();
    end;

    local procedure GetExpectResultForSingleDim(Dimension: array[3] of Record Dimension; DimensionValue: array[3] of Record "Dimension Value"; var ExpectedResult: array[3, 2] of Text)
    begin
        ExpectedResult[1] [1] := StrSubstNo('%1 - %2', Dimension[1].Code, DimensionValue[1].Code);
        ExpectedResult[2] [1] :=
          StrSubstNo('%1 - %2;%3 - %4', Dimension[1].Code, DimensionValue[1].Code, Dimension[2].Code, DimensionValue[2].Code);
        ExpectedResult[3] [1] := ExpectedResult[2] [1];
        ExpectedResult[3] [2] := StrSubstNo('%1 - %2', Dimension[3].Code, DimensionValue[3].Code);
    end;

    local procedure GetExpectResultForMultipleDim(Dimension: array[3] of Record Dimension; DimensionValue: array[3] of Record "Dimension Value"; var FirstLine: Text; var ExpectedResult: array[3, 2] of Text)
    begin
        ExpectedResult[1] [1] := FirstLine + StrSubstNo('%1 - %2', Dimension[1].Code, DimensionValue[1].Code);
        FirstLine := '';
        ExpectedResult[2] [1] := ExpectedResult[1] [1];
        ExpectedResult[2] [2] := StrSubstNo('%1 - %2', Dimension[2].Code, DimensionValue[2].Code);
        ExpectedResult[3] [1] := ExpectedResult[1] [1];
        ExpectedResult[3] [2] :=
          StrSubstNo('%1 - %2;%3 - %4', Dimension[2].Code, DimensionValue[2].Code, Dimension[3].Code, DimensionValue[3].Code);
    end;

    local procedure VerifyDimensionInJournalLine(AccountNo: Code[20]; ExpectedResult: array[2] of Text)
    begin
        LibraryReportDataset.SetRange(AccNoGenJnlLineCap, AccountNo);
        LibraryReportDataset.AssertElementWithValueExists(DimTextCap, ExpectedResult[1]);
        if ExpectedResult[2] <> '' then begin
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertElementWithValueExists(DimTextCap, ExpectedResult[2]);
        end;
    end;

    local procedure VerifyDimensionInAllocationLine(AccountNo: Code[20]; ExpectedResult: array[2] of Text)
    begin
        LibraryReportDataset.SetRange(AccNoGenJnlAlloCap, AccountNo);
        LibraryReportDataset.AssertElementWithValueExists(AllocationDimTextCap, ExpectedResult[1]);
        if ExpectedResult[2] <> '' then begin
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertElementWithValueExists(AllocationDimTextCap, ExpectedResult[2]);
        end;
    end;

    local procedure CheckValuePostingReport(LocalValuePosting: Enum "Default Dimension Value Posting Type"; GlobalValuePosting: Enum "Default Dimension Value Posting Type")
    var
        Dimension: Record Dimension;
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
        LocalValueCode: Code[20];
        GlobalValueCode: Code[20];
    begin
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        LocalValueCode := GetDimensionValueCode(Dimension.Code);
        GlobalValueCode := GetDimensionValueCode(Dimension.Code);
        if LocalValuePosting = DefaultDimension."Value Posting"::"No Code" then
            LocalValueCode := '';
        if GlobalValuePosting = DefaultDimension."Value Posting"::"No Code" then
            GlobalValueCode := '';

        // Exercise
        CreateDefaultDimensionCodes(Customer."No.", Dimension.Code, LocalValueCode, LocalValuePosting);
        CreateDefaultDimensionCodes('', Dimension.Code, GlobalValueCode, GlobalValuePosting);

        // Verify
        VerifyValuePostingReport(Customer);
    end;

    local procedure VerifyValuePostingReport(Customer: Record Customer)
    begin
        LibraryVariableStorage.Enqueue(DATABASE::Customer);
        Commit();
        REPORT.Run(REPORT::"Check Value Posting");

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_DefaultDim2', Customer."No.")
    end;

    local procedure CreateAnalysisView(var AnalysisView: Record "Analysis View"; AccountSource: Enum "Analysis Account Source"; AccountNo: Code[20])
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Account Source", AccountSource);
        AnalysisView.Validate("Account Filter", AccountNo);
        AnalysisView.Validate("Starting Date", WorkDate());
        AnalysisView.Validate("Dimension 1 Code", LibraryERM.GetGlobalDimensionCode(1));
        AnalysisView.Modify(true);
    end;

    local procedure CreateAnalysisViewFullDimensions(var AnalysisView: Record "Analysis View"; AccountSource: Enum "Analysis Account Source"; AccountNo: Code[20]; DimCodes: array[4] of Code[20])
    begin
        CreateAnalysisView(AnalysisView, AccountSource, AccountNo);
        AnalysisView.Validate("Dimension 1 Code", DimCodes[1]);
        AnalysisView.Validate("Dimension 2 Code", DimCodes[2]);
        AnalysisView.Validate("Dimension 3 Code", DimCodes[3]);
        AnalysisView.Validate("Dimension 4 Code", DimCodes[4]);
        AnalysisView.Modify(true);
    end;

    local procedure CreateAndPostGenJnlLine(AnalysisView: Record "Analysis View"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DimensionValue: Record "Dimension Value";
    begin
        SelectAndClearGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", AnalysisView."Account Filter", Amount);

        LibraryDimension.FindDimensionValue(DimensionValue, AnalysisView."Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostCashFlowJnlLine(AnalysisVIew: Record "Analysis View"; Amount: Decimal)
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryCashFlow.ClearJournal();

        LibraryCashFlow.CreateCashFlowCard(CashFlowForecast);
        LibraryCashFlow.CreateJournalLine(CFWorksheetLine, CashFlowForecast."No.", AnalysisVIew."Account Filter");
        LibraryDimension.FindDimensionValue(DimensionValue, AnalysisVIew."Dimension 1 Code");
        CFWorksheetLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        CFWorksheetLine.Validate("Amount (LCY)", Amount);
        CFWorksheetLine.Modify(true);

        LibraryCashFlow.PostJournal();
    end;

    local procedure CreateColumnLayout(): Code[20]
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        LibraryERM.CreateColumnLayoutName(ColumnLayoutName);
        LibraryERM.CreateColumnLayout(ColumnLayout, ColumnLayoutName.Name);
        ColumnLayout.Validate("Column No.", Format(LibraryUtility.GenerateGUID()));
        ColumnLayout.Validate("Column Type", ColumnLayout."Column Type"::"Net Change");
        ColumnLayout.Modify(true);
        exit(ColumnLayout."Column Layout Name")
    end;

    local procedure CreateDimensionGLAccountWithNumber(DimNumber: Integer): Code[20]
    var
        GLAccount: Record "G/L Account";
        Dimension: Record Dimension;
    begin
        Dimension.Init();
        Dimension.Code := GLAccount.TableCaption + Format(DimNumber);
        Dimension.Insert();
        exit(Dimension.Code);
    end;

    local procedure CreateDefaultDimensionCodes(CustomerNo: Code[20]; DimCode: Code[20]; DimValCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // Clear existing dimension setup to make room for our new setup
        ClearDefaultDimensionCodes(DATABASE::Customer, CustomerNo);

        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Customer, CustomerNo, DimCode, DimValCode);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateDefaultDimensionVendor(var DefaultDimension: Record "Default Dimension"; VendorNo: Code[20]; DimCode: Code[20]; DimValue: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type")
    begin
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, VendorNo, DimCode, DimValue);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure ClearDefaultDimensionCodes(TableID: Integer; No: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", No);
        DefaultDimension.DeleteAll(true);
    end;

    local procedure ClearDimensionCombinations()
    var
        DimensionCombination: Record "Dimension Combination";
    begin
        DimensionCombination.DeleteAll(true);
    end;

    local procedure CreateDimensionValues(var DimensionValue: Record "Dimension Value") DimensionValueCode: Code[20]
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimensionValueCode := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure GetDimensionValueCode(DimensionCode: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Dimension Code", DimensionCode);
        DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
        DimensionValue.FindSet();
        DimensionValue.Next(LibraryRandom.RandInt(DimensionValue.Count));
        exit(DimensionValue.Code);
    end;

    local procedure RunCheckValuePosting(DimensionCode: Code[20])
    begin
        Commit();
        LibraryVariableStorage.Enqueue(DimensionCode);
        REPORT.Run(REPORT::"Check Value Posting");
    end;

    local procedure FindItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type"; Clear: Boolean)
    begin
        ItemJournalBatch.Reset();
        ItemJournalBatch.SetRange("Template Type", TemplateType);
        ItemJournalBatch.Next(LibraryRandom.RandInt(ItemJournalBatch.Count));
        if Clear then
            ClearItemJournal(ItemJournalBatch);
    end;

    local procedure CreateDimSetID(Dimension: Record Dimension): Integer
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    local procedure CreateItemJnlLineWithDim(ItemJournalBatch: Record "Item Journal Batch"; var ItemJnlLine: Record "Item Journal Line"; PostingDate: Date; DimSetID: Integer; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    var
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItemJournalLine(ItemJnlLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, EntryType, ItemNo, LibraryRandom.RandInt(10));
        ItemJnlLine."Posting Date" := PostingDate;
        ItemJnlLine."Dimension Set ID" := DimSetID;
        ItemJnlLine.Modify();
    end;

    local procedure CreateTwoJrnlLinesItemsWithDefaultDimension(var ItemJournalLine: Record "Item Journal Line"; var DefaultDimension: array[2] of Record "Default Dimension"; var ItemNo: array[2] of Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        DimensionValue: Record "Dimension Value";
        Item: array[2] of Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        Counter: Integer;
    begin
        FindItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, true);
        DimensionValue.SetRange("Global Dimension No.", 1);
        DimensionValue.FindSet();
        repeat
            Counter += 1;
            LibraryInventory.CreateItem(Item[Counter]);
            ItemNo[Counter] := Item[Counter]."No.";
            LibraryDimension.CreateDefaultDimensionItem(DefaultDimension[Counter], ItemNo[Counter], DimensionValue."Dimension Code", DimensionValue.Code);
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch."Journal Template Name",
              ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo[Counter], LibraryRandom.RandInt(9) + 1);
        until (DimensionValue.Next() = 0) or (Counter = 2)
    end;

    local procedure ClearItemJournal(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll(true);
    end;

    local procedure SelectDimension(ObjectType: Integer; ObjectID: Integer; DimensionCode: Code[20])
    var
        SelectedDimension: Record "Selected Dimension";
    begin
        // Fill Selected Dimension Table
        CleanSelectedDimension(SelectedDimension, UserId, ObjectType, ObjectID);
        SelectedDimension.Init();
        SelectedDimension."User ID" := UserId;
        SelectedDimension."Object Type" := ObjectType;
        SelectedDimension."Object ID" := ObjectID;
        SelectedDimension."Dimension Code" := DimensionCode;
        SelectedDimension.Insert();
    end;

    local procedure CalculateInventory(var ItemJournalLine: Record "Item Journal Line"; ItemFilter: Text; LocationFilter: Text; PostingDate: Date; ItemsNotOnInvt: Boolean; ItemsWithNoTransactions: Boolean)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        // Preparations
        FindItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::"Phys. Inventory", true);

        ItemJournalLine.Reset();
        ItemJournalLine."Journal Template Name" := ItemJournalBatch."Journal Template Name";
        ItemJournalLine."Journal Batch Name" := ItemJournalBatch.Name;

        Item.Reset();
        Item.SetFilter("No.", ItemFilter);
        if LocationFilter <> '' then
            Item.SetFilter("Location Filter", LocationFilter);

        // Run report Calculate Inventory
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, PostingDate, ItemsNotOnInvt, ItemsWithNoTransactions);

        // Restore ItemJournalLine Ranges
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetFilter("Item No.", ItemFilter);
        ItemJournalLine.FindSet();
    end;

    local procedure CleanSelectedDimension(var SelectedDimension: Record "Selected Dimension"; UserID: Code[50]; ObjectType: Integer; ObjectID: Integer)
    begin
        SelectedDimension.SetRange("User ID", UserID);
        SelectedDimension.SetRange("Object Type", ObjectType);
        SelectedDimension.SetRange("Object ID", ObjectID);
        SelectedDimension.DeleteAll(true);
    end;

    local procedure SelectAndClearGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SetDimensionDetailParameters(AnalysisViewCode: Code[20]; DateFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(AnalysisViewCode);
        LibraryVariableStorage.Enqueue(DateFilter);
        LibraryVariableStorage.Enqueue(false);
    end;

    local procedure SetDimensionTotalParameters(AnalysisViewCode: Code[20]; ColumnLayoutName: Code[20]; DateFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(AnalysisViewCode);
        LibraryVariableStorage.Enqueue(ColumnLayoutName);
        LibraryVariableStorage.Enqueue(DateFilter);
        LibraryVariableStorage.Enqueue(false);
    end;

    local procedure UpdateAnalysisView(AnalysisViewCode: Code[20])
    var
        AnalysisView: Record "Analysis View";
    begin
        AnalysisView.Get(AnalysisViewCode);
        LibraryERM.UpdateAnalysisView(AnalysisView);
    end;

    local procedure VerifyDimensionDetailReport(AnalysisViewCode: Code[20]; ExpectedAmount: Decimal)
    var
        AnalysisView: Record "Analysis View";
    begin
        LibraryReportDataset.LoadDataSetFile();
        AnalysisView.Get(AnalysisViewCode);

        LibraryReportDataset.AssertElementWithValueExists('DimValCode_1_', AnalysisView."Account Filter");
        LibraryReportDataset.AssertElementWithValueExists('DimCode_1_', Format(AnalysisView."Account Source"));
        LibraryReportDataset.AssertElementWithValueExists('DebitTotal_1_', ExpectedAmount);
    end;

    local procedure VerifyDimensionTotalReport(AnalysisViewCode: Code[20]; ExpectedAmount: Decimal)
    var
        AnalysisView: Record "Analysis View";
    begin
        LibraryReportDataset.LoadDataSetFile();
        AnalysisView.Get(AnalysisViewCode);

        LibraryReportDataset.AssertElementWithValueExists('DimValCode_1_', AnalysisView."Account Filter");
        LibraryReportDataset.AssertElementWithValueExists('DimCode_1_', Format(AnalysisView."Account Source"));
        LibraryReportDataset.AssertElementWithValueExists('ColumnValuesAsText_1_1_', Format(ExpectedAmount));
    end;

    local procedure VerifyDimValForItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; DefaultDimension: array[2] of Record "Default Dimension")
    begin
        ItemJournalLine.FindSet();
        Assert.AreEqual(DefaultDimension[1]."Dimension Value Code", ItemJournalLine."Shortcut Dimension 1 Code", FailureDimValCodeMsg);
        ItemJournalLine.Next();
        Assert.AreEqual(DefaultDimension[2]."Dimension Value Code", ItemJournalLine."Shortcut Dimension 1 Code", FailureDimValCodeMsg);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerCheckValuePosting(var CheckValuePosting: TestRequestPage "Check Value Posting")
    var
        DimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);
        CheckValuePosting.DefaultDim1.SetFilter("Dimension Code", DimensionCode);
        CheckValuePosting.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerCheckValuePosting2(var CheckValuePosting: TestRequestPage "Check Value Posting")
    var
        TableID: Variant;
    begin
        LibraryVariableStorage.Dequeue(TableID);
        CheckValuePosting.DefaultDim1.SetFilter("Table ID", Format(TableID));
        CheckValuePosting.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerDimensionDetail(var DimensionDetail: TestRequestPage "Dimensions - Detail")
    var
        AnalysisViewCode: Variant;
        DateFilter: Variant;
        ShowInAddCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(AnalysisViewCode);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(ShowInAddCurrency);

        DimensionDetail.AnalysisViewCode.SetValue(AnalysisViewCode);
        DimensionDetail.DtFilter.SetValue(DateFilter);
        DimensionDetail.ShowAmountsInAddRepCurrency.SetValue(ShowInAddCurrency);

        LibraryVariableStorage.Enqueue(AnalysisViewCode);
        DimensionDetail.IncludeDimensions.AssistEdit();

        DimensionDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerDimensionTotal(var DimensionTotal: TestRequestPage "Dimensions - Total")
    var
        AnalysisViewCode: Variant;
        ColumnLayoutName: Variant;
        DateFilter: Variant;
        ShowInAddCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(AnalysisViewCode);
        LibraryVariableStorage.Dequeue(ColumnLayoutName);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(ShowInAddCurrency);

        DimensionTotal.AnalysisViewCode.SetValue(AnalysisViewCode);
        DimensionTotal.ColumnLayoutName.SetValue(ColumnLayoutName);
        DimensionTotal.DtFilter.SetValue(DateFilter);
        DimensionTotal.ShowAmountsInAddRepCurrency.SetValue(ShowInAddCurrency);

        LibraryVariableStorage.Enqueue(AnalysisViewCode);
        DimensionTotal.IncludeDimensions.AssistEdit();

        DimensionTotal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTestHandler(var GeneralJournalTest: TestRequestPage "General Journal - Test")
    begin
        GeneralJournalTest.ShowDim.SetValue(true);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Template Name", GenJnlTemplate.Name);
        GeneralJournalTest."Gen. Journal Line".SetFilter("Journal Batch Name", GenJnlBatch.Name);

        GeneralJournalTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccReconTestHandler(var BankAccReconTest: TestRequestPage "Bank Acc. Recon. - Test")
    begin
        BankAccReconTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PHandlerDimensionSelectionLevel(var DimensionSelectionLevel: TestPage "Dimension Selection-Level")
    var
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
        AnalysisView: Record "Analysis View";
        AnalysisViewCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(AnalysisViewCode);
        if AnalysisView.Get(AnalysisViewCode) then begin
            DimensionSelectionLevel.Level.SetValue(DimensionSelectionBuffer.Level::"Level 1");
            DimensionSelectionLevel.OK().Invoke();
        end
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSelectionLevelHandler(var DimensionSelectionLevel: TestPage "Dimension Selection-Level")
    var
        GLAccount: Record "G/L Account";
        Lines: Integer;
        LinesExpected: Integer;
    begin
        Lines := 1;
        LinesExpected := LibraryVariableStorage.DequeueInteger();
        DimensionSelectionLevel.First();
        DimensionSelectionLevel.Code.AssertEquals(GLAccount.TableCaption());
        while DimensionSelectionLevel.Next() do begin
            DimensionSelectionLevel.Code.AssertEquals(LibraryVariableStorage.DequeueText());
            Lines += 1;
        end;
        Assert.AreEqual(
          LinesExpected,
          Lines,
          '%1 lines in page expected, %2 lines actually shown');
        DimensionSelectionLevel.OK().Invoke();
    end;
}

